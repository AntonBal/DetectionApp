//
//  TShirtDetector.m
//  DetectionApp
//
//  Created by Anton Bal on 3/28/19.
//  Copyright © 2019 Anton Bal'. All rights reserved.
//

#import "TShirtDetector.h"
#import "UIImage+OpenCV.h"

using namespace cv;
using namespace std;

struct RGBColor {
    double r;
    double g;
    double b;
};

struct HSVColor {
    double h;
    double s;
    double v;
};

@interface TShirtDetector()

@property (nonatomic, assign) float hRangeValue;
@property (nonatomic, assign) float sRangeValue;
@property (nonatomic, assign) float vRangeValue;

@end

@implementation TShirtDetector

#pragma mark - Public

-(void)setHSVRangeValueWithHValue:(float) h sValue:(float) s vValue:(float) v {
    self.hRangeValue = h;
    self.sRangeValue = s;
    self.vRangeValue = v;
}

- (cv::Mat) fillImg:(cv::Mat&) img withDetectingObject:(DetectingObject) obj withAdditionalImage:(cv::Mat) addImage inRect:(CvRect) rect {
    
    Mat mask1, mask2, hsv;
    
    //Converting image from BGR to HSV color space.
    cvtColor(img, hsv, COLOR_BGR2HSV);
    
    vector<HSVColor> detectingColors(obj.detectingColors.size());
    Scalar fillingHSVColor = [self bgrScalarToHLS: obj.fillingColor];
   
    for (int i = 0; i < obj.detectingColors.size(); i++)
        detectingColors[i] = [self bgrScalar2HSVColor: obj.detectingColors[i]];
    
    // Generating the final mask
    HSVColor hsvRange = HSVColor();
    hsvRange.h = self.hRangeValue;
    hsvRange.s = self.sRangeValue;
    hsvRange.v = self.vRangeValue;
    
    mask1 = maskForImage(hsv, detectingColors, hsvRange);
    
    cv::Size blurSize(6,6);
    blur(mask1, mask1, blurSize);
    threshold(mask1, mask1, 50, 255, THRESH_BINARY);
    
    Mat kernel = Mat::ones(3,3, CV_32F);
    morphologyEx(mask1, mask1, cv::MORPH_OPEN, kernel);
    morphologyEx(mask1, mask1, cv::MORPH_DILATE, kernel);
    
    Mat background = Mat(hsv.rows, hsv.cols, hsv.type(), Scalar(fillingHSVColor[0], NAN, NAN));
    
    for (int i = 0; i < background.cols; i++) {
        for (int j = 0; j < background.rows; j++) {
            CvPoint point = cvPoint(i, j);
            background.at<Vec3b>(point).val[1] = MIN(hsv.at<Vec3b>(point).val[1] + 50, 255);
            background.at<Vec3b>(point).val[2] = MIN(hsv.at<Vec3b>(point).val[2] + 50, 255);
        }
    }
    
    cvtColor(background, background, COLOR_HSV2BGR);
    
    // Add extra image to t-shirt
    if (!addImage.size().empty()) {
        if (rect.x + rect.width < background.cols && rect.y + rect.height < background.rows ) {
            addImage.copyTo(background(rect));
        }
    }
    
    // creating an inverted mask to segment out the cloth from the frame
    bitwise_not(mask1, mask2);
     
    Mat res1, res2, final_output;
     
    // Segmenting the cloth out of the frame using bitwise and with the inverted mask
    bitwise_and(img, img, res1, mask2);
    
    // creating image showing static background frame pixels only for the masked region
    bitwise_and(background, background, res2, mask1);
    
    // Generating the final augmented output.
    // addWeighted(res1, 1, res2, 1,  0, final_output);
    cv::add(res1, res2, final_output);

    return final_output;
}

cv::Mat maskForImage(Mat image, vector<HSVColor> colors, HSVColor hsv) {

    Mat mask;
    //    inRange(hsv, Scalar(0, 120, 70), Scalar(10, 255, 255), mask1);
    //    inRange(hsv, Scalar(170, 120, 70), Scalar(180, 255, 255), mask2);
    
    
    // Creating masks to detect the upper and lower red color.
    ///The Hue values are actually distributed over a circle (range between 0-360 degrees) but in OpenCV to fit into 8bit value the range is from 0-180.
    
    for (int i = 0; i < colors.size(); i++)  {
      
        Mat mask1, mask2;
        HSVColor hlsColor = colors[i];
     
        UIColor* uiColor1 = [UIColor colorWithHue: hlsColor.h / 180 saturation: hlsColor.s / 255 brightness: hlsColor.v / 255 alpha:1];
        
        auto h = hlsColor.h;
        auto s = hlsColor.s;
        auto v = hlsColor.v;
        
        auto hMin = h - hsv.h;
        auto hMax = h + hsv.h;
        auto sMin = s - hsv.s;
        auto sMax = s + hsv.s;
        auto vMin = v - hsv.v;
        auto vMax = v + hsv.v;
        
        if (hMin < 0) {
            hMin = 180 + hMin;
        }
        
        if (hMax > 180) {
            hMax = 0;
        }
        
        if (sMin < 0) {
            sMin = hsv.s + sMin;
        }
        
        if (vMin < 0) {
            vMin = hsv.v + vMin;
        }
        
        auto temp = hMin;
        hMin = MIN(hMin, hMax);
        hMax = MAX(temp, hMax);
        
        inRange(image, Scalar(hMin, sMin, vMin), Scalar(hMin + hsv.h, MIN(sMax + hsv.s, 255), MIN(vMax + hsv.v, 255)), mask1);
        inRange(image, Scalar(hMax, sMin, vMin), Scalar(hMax + hsv.h, MIN(sMax + hsv.s, 255), MIN(vMax + hsv.v, 255)), mask2);
        
        // Generating the final mask
        
        UIImage* imagemask1 = [UIImage imageFromCVMat:mask1];
        UIImage* imagemask2 = [UIImage imageFromCVMat:mask2];
        
        if (mask.size().empty()) {
            mask = mask1 + mask2;
        } else {
            mask = mask + mask1 + mask2;
        }
        
        UIImage* imagemask3 = [UIImage imageFromCVMat:mask];
        
        NSLog(@"");
    }
    
    return mask;
}

-(HSVColor)bgrScalar2HSVColor:(Scalar) bgrScalar
{
    ///https://en.wikipedia.org/wiki/HSL_and_HSV#Use_in_image_analysis
    RGBColor bgr = RGBColor();
    bgr.r = bgrScalar[2];
    bgr.g = bgrScalar[1];
    bgr.b = bgrScalar[0];
    
    HSVColor         hsv;
    double      min, max, delta;
    
    bgr.r = bgr.r / 255;
    bgr.b = bgr.b / 255;
    bgr.g = bgr.g / 255;
    
    min = MIN(bgr.b, MIN(bgr.r, bgr.g));
    max = MAX(bgr.b, MAX(bgr.r, bgr.g));
    delta = max - min;
    
    auto percet60in255 = 30;
    
    if (delta < 0.0001) {
        hsv.h = 0;
    } else if (max == bgr.r) {
        hsv.h = percet60in255 * ((bgr.g - bgr.b) / delta);
    } else if (max == bgr.g) {
        hsv.h = percet60in255 * (2 + (bgr.b - bgr.r) / delta);
    } else if (max == bgr.b) {
        hsv.h = percet60in255 * (4 + (bgr.r - bgr.g) / delta);
    }
    
    if (hsv.h < 0) {
        hsv.h += 180;
    }
    
    if (max == 0) {
        hsv.s = 0;
    } else {
        hsv.s = delta / max;
    }
    
    hsv.s *= 255;
    hsv.v = max * 255;
    
    return hsv;
}

#pragma mark - Private

-(Scalar)bgrScalarToHLS:(Scalar) bgrScalar {
    Mat hsv;
    Mat bgr(1,1, CV_8UC3, bgrScalar);
    cvtColor(bgr, bgr, COLOR_BGRA2BGR);
    cvtColor(bgr, hsv, CV_BGR2HSV);
    return Scalar(hsv.data[0], hsv.data[1], hsv.data[2]);
}

- (Mat) fillBigContourForImage:(Mat) img mask:(Mat) mask color: (Scalar) color {
    
    vector<vector<cv::Point>> contours;
    vector<Vec4i> hierarchy;
    
    //    int value = 5;
    /// Detect edges using canny
    //    Canny(mask, mask, value, value*2, 3);
    
    /// Find contours
    findContours(mask, contours, hierarchy, CV_RETR_EXTERNAL, CV_LINK_RUNS, cv::Point(0, 0));
    
    /*
    int largest_area=0;
    int largest_contour_index=0;
    int largest_contour_index2=0;
    cv::Rect bounding_rect;
     */
    
    if (contours.size() > 0) {
        
        Mat drawing = Mat::zeros(img.size(), CV_8UC1);
        /*
        for( int i = 0; i< contours.size(); i++ ) // iterate through each contour.
        {
            double a=contourArea( contours[i],false);  //  Find the area of contour
            if(a>largest_area){
                largest_area=a;
                largest_contour_index2=largest_contour_index;
                largest_contour_index=i;                //Store the index of largest contour
                bounding_rect = boundingRect(contours[i]);
            }
        }
         */
//        rectangle(img, bounding_rect,  Scalar(0,255,0),1, 8,0);
        drawContours(img, contours, -1, color, CV_FILLED, LINE_AA, hierarchy);
//        fillPoly(img, contours, color);
    }
    
    return img;
}
@end
