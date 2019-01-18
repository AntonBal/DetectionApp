//
//  BodyDetector.m
//  DetectionApp
//
//  Created by Anton Bal' on 1/17/19.
//  Copyright © 2019 Anton Bal'. All rights reserved.
//

#import "BodyDetector.h"
#import "UIImage+OpenCV.h"

using namespace cv;
using namespace std;

typedef cv::Point CVPoint;

@implementation BodyDetector

- (UIImage*) detectAndDraw:(UIImage*) img {
    Mat mat = [img cvMatRepresentationColor];
    return [UIImage imageFromCVMat: [self detectAndDraw:mat scale: 1.0]];
}

- (cv::Mat)detectAndDraw:(cv::Mat)img scale:(CGFloat)scale {
    Mat mask = [self makeHandMaskFor: img];
    return [self contoursForImage: img mask: mask];
}

#pragma mark - Private detection methods

- (Mat) makeHandMaskFor:(Mat&) img {
    
    Mat mask;
    cv::Size blurSize(3,3);
    
    cvtColor(img, mask, COLOR_RGB2HSV);
    
    auto low = Mat(mask.rows, mask.cols, mask.type(), CV_RGB(50, 50, 100));
    auto high = Mat(mask.rows, mask.cols, mask.type(), CV_RGB(255, 255, 200));

    inRange(mask, low, high, mask);
    blur(mask, mask, blurSize);
//    threshold(mask, mask, 90, 255, THRESH_BINARY);
    adaptiveThreshold(mask, mask, 200, ADAPTIVE_THRESH_GAUSSIAN_C, THRESH_BINARY, 15, 7);
    
    return mask;
}

- (Mat) contoursForImage:(Mat) img mask:(Mat) mask {
    
    vector<vector<CVPoint>> contours;
    vector<Vec4i> hierarchy;
    
    int value = 100;
    /// Detect edges using canny
    Canny(mask, mask, value, value*2, 3);
    
    /// Find contours
    findContours(mask, contours, hierarchy, CV_RETR_EXTERNAL, CV_CHAIN_APPROX_SIMPLE);
    
    Scalar color = CV_RGB(50, 50, 150);
    Scalar colorRed = CV_RGB(255, 0, 0);
    int largest_area=0;
    int largest_contour_index=0;
    cv::Rect bounding_rect;
    
    if (contours.size() > 0) {
        
        for( int i = 0; i< contours.size(); i++ ) // iterate through each contour.
        {
            double a=contourArea( contours[i],false);  //  Find the area of contour
            if(a>largest_area){
                largest_area=a;
                largest_contour_index=i;                //Store the index of largest contour
                bounding_rect= boundingRect(contours[i]); // Find the bounding rectangle for biggest contour
            }
            drawContours(img, contours, i, color);
        }
        
        vector<CVPoint> points = contours[largest_contour_index];
        drawContours(img, contours, largest_contour_index, colorRed);
        
        auto extLeft = min_element(points.begin(), points.end(), ^(CVPoint lhs, CVPoint rhs) { return lhs.x < rhs.x; });
        auto extRight = max_element(points.begin(), points.end(), ^(CVPoint lhs, CVPoint rhs) { return lhs.x < rhs.x; });
        auto extTop = min_element(points.begin(), points.end(), ^(CVPoint lhs, CVPoint rhs) { return lhs.y < rhs.y; });
        auto extBot = max_element(points.begin(), points.end(), ^(CVPoint lhs, CVPoint rhs) { return lhs.y < rhs.y; });
      
        int radius = 5;
        
        rectangle(img, bounding_rect, colorRed, 3);
        circle(img, extLeft[0], radius, colorRed);
        circle(img, extRight[1], radius, colorRed);
        circle(img, extTop[0], radius, colorRed);
        circle(img, extBot[1], radius, colorRed);
    }
    
    return img;
}
@end
