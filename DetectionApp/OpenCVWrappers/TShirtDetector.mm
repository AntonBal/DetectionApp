//
//  TShirtDetector.m
//  DetectionApp
//
//  Created by Anton Bal on 3/28/19.
//  Copyright © 2019 Anton Bal'. All rights reserved.
//

#import "TShirtDetector.h"

using namespace cv;
using namespace std;

@implementation TShirtDetector

#pragma mark - Public

- (Mat)fillImg:(Mat&) img withColor:(Scalar) fillingColor byColor:(Scalar) detectingColor {
    
    Mat hsv;
    
    //Converting image from BGR to HSV color space.
    cvtColor(img, img, COLOR_BGRA2BGR);
    cvtColor(img, hsv, COLOR_BGR2HSV);
    
    Mat mask1, mask2;
    
    //    inRange(hsv, Scalar(0, 120, 70), Scalar(10, 255, 255), mask1);
    //    inRange(hsv, Scalar(170, 120, 70), Scalar(180, 255, 255), mask2);
    
//    UIColor* uiColor1 = [UIColor colorWithRed:detectingColor[2]/255 green:detectingColor[1]/255 blue:detectingColor[0]/255 alpha:1];
    
    // Creating masks to detect the upper and lower red color.
    ///The Hue values are actually distributed over a circle (range between 0-360 degrees) but in OpenCV to fit into 8bit value the range is from 0-180.
    auto hlsColor = [self bgrScalarToHLS: detectingColor];
    
    auto h = hlsColor[0];
    auto s = hlsColor[1];
    auto v = hlsColor[2];
    auto hMin = h - 10;
    auto hMax = h + 10;
    auto sMin = s - 120;
    auto vMin = v - 180;
    
    if (hMin < 0) {
        hMin = 170;
    }
    
    if (hMax > 180) {
        hMax = 0;
    }
    
    if (sMin < 0) {
        sMin = 10;
    }
    
    if (vMin < 0) {
        vMin = 10;
    }
    
    inRange(hsv, Scalar(hMin, sMin, vMin), Scalar(hMin + 10, 255, 255), mask1);
    inRange(hsv, Scalar(hMax, sMin, vMin), Scalar(hMax + 10, 255, 255), mask2);
    
    // Generating the final mask
    mask1 = mask1 + mask2;
    
    Mat kernel = Mat::ones(3,3, CV_32F);
    morphologyEx(mask1, mask1, cv::MORPH_OPEN, kernel);
    morphologyEx(mask1, mask1, cv::MORPH_DILATE, kernel);
    
    //    cv::Size blurSize(3,3);
    //    blur(mask1, mask1, blurSize);
    //    threshold(mask1, mask1, 25, 255, THRESH_BINARY);
    //
    //    img = [self fillBigContourForImage:img mask: mask1 color: fillingColor];
    //
    //    cvtColor(img, img, COLOR_BGR2RGB);
    //
    //    return img;
    
    Mat background = Mat(img.rows, img.cols, img.type(), fillingColor);
    cvtColor(background, background, COLOR_BGRA2BGR);
    
    // creating an inverted mask to segment out the cloth from the frame
    bitwise_not(mask1, mask2);
    
    Mat res1, res2, final_output;
    
    // Segmenting the cloth out of the frame using bitwise and with the inverted mask
    bitwise_and(img, img, res1, mask2);
    
    // creating image showing static background frame pixels only for the masked region
    bitwise_and(background, background, res2, mask1);
    
    // Generating the final augmented output.
    addWeighted(res1, 1, res2, 1,  0, final_output);
    
    cvtColor(final_output, final_output, COLOR_BGR2RGB);
    
    return final_output;
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
    findContours(mask, contours, hierarchy, CV_RETR_EXTERNAL, CV_CHAIN_APPROX_TC89_L1);
    
//    int largest_area=0;
//    int largest_contour_index=0;
    
    if (contours.size() > 0) {
        /*
        Mat drawing = Mat::zeros(img.size(), CV_8UC1);
        
        for( int i = 0; i< contours.size(); i++ ) // iterate through each contour.
        {
            double a=contourArea( contours[i],false);  //  Find the area of contour
            if(a>largest_area){
                largest_area=a;
                largest_contour_index=i;                //Store the index of largest contour
            }
        }
        */
        drawContours(img, contours, -1, color, CV_FILLED, 8, hierarchy);
    }
    
    return img;
}
@end
