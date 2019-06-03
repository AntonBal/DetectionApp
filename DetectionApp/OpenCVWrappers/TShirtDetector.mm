//
//  TShirtDetector.m
//  DetectionApp
//
//  Created by Anton Bal on 3/28/19.
//  Copyright © 2019 Anton Bal'. All rights reserved.
//

#import "TShirtDetector.h"
#import "UIImage+OpenCV.h"

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

using namespace cv;
using namespace std;

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

- (cv::Mat) fillImg:(cv::Mat&) img withColor:(cv::Scalar) fillingColor byColor:(cv::Scalar) detectingColor withAdditionalImage:(cv::Mat) addImage inRect:(CvRect) rect {
    
    Mat hsv;
    
    //Converting image from BGR to HSV color space.
    cvtColor(img, hsv, COLOR_BGR2HSV);
    
    Scalar fillingHSVColor = [self bgrScalarToHLS: fillingColor];
    
    Mat mask1, mask2;
    
    //    inRange(hsv, Scalar(0, 120, 70), Scalar(10, 255, 255), mask1);
    //    inRange(hsv, Scalar(170, 120, 70), Scalar(180, 255, 255), mask2);
    
//    UIColor* uiColor1 = [UIColor colorWithRed:detectingColor[2]/255 green:detectingColor[1]/255 blue:detectingColor[0]/255 alpha:1];
    
    // Creating masks to detect the upper and lower red color.
    ///The Hue values are actually distributed over a circle (range between 0-360 degrees) but in OpenCV to fit into 8bit value the range is from 0-180.

    RGBColor bgr = RGBColor();
    
    bgr.b = detectingColor[0];
    bgr.g = detectingColor[1];
    bgr.r = detectingColor[2];
    
    auto hlsColor = [self bgr2hsv: bgr];
    
    auto h = hlsColor.h;
    auto s = hlsColor.s;
    auto v = hlsColor.v;
    
    auto hMin = h - self.hRangeValue;
    auto hMax = h + self.hRangeValue;
    auto sMin = s - self.sRangeValue;
    auto sMax = s + self.sRangeValue;
    auto vMin = v - self.vRangeValue;
    auto vMax = v + self.vRangeValue;
    
    if (hMin < 0) {
        hMin = 180 + hMin;
    }
    
    if (hMax > 180) {
        hMax = 0;
    }
    
    if (sMin < 0) {
        sMin = self.sRangeValue + sMin;
    }
    
    if (vMin < 0) {
        vMin = self.vRangeValue + vMin;
    }
    
    auto temp = hMin;
    hMin = MIN(hMin, hMax);
    hMax = MAX(temp, hMax);
    
    inRange(hsv, Scalar(hMin, sMin, vMin), Scalar(hMin + self.hRangeValue, MIN(sMax + self.sRangeValue, 255), MIN(vMax + self.vRangeValue, 255)), mask1);
    inRange(hsv, Scalar(hMax, sMin, vMin), Scalar(hMax + self.hRangeValue, MIN(sMax + self.sRangeValue, 255), MIN(vMax + self.vRangeValue, 255)), mask2);
    
    // Generating the final mask
    mask1 = mask1 + mask2;
    
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
            background.at<Vec3b>(point).val[1] = hsv.at<Vec3b>(point).val[1];
            background.at<Vec3b>(point).val[2] = hsv.at<Vec3b>(point).val[2];
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

-(HSVColor)bgr2hsv:(RGBColor) bgr
{
    ///https://en.wikipedia.org/wiki/HSL_and_HSV#Use_in_image_analysis
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
