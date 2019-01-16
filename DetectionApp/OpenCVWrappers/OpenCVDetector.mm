//
//  OpenCVWrapper.m
//  DetectionApp
//
//  Created by Anton Bal on 11/22/18.
//  Copyright © 2018 Cleveroad. All rights reserved.
//

#import "OpenCVDetector.h"
#import "UIImage+OpenCV.h"

using namespace cv;
using namespace std;

#pragma mark - AreaCmp

struct AreaCmp {
    AreaCmp(const vector<float>& _areas) : areas(&_areas) {}
    bool operator()(int a, int b) const {
        float value = (*areas)[b] - (*areas)[a];
        return value; }
    const vector<float>* areas;
};

#pragma mark - OpenCVDetector

@interface OpenCVDetector() <CvVideoCameraDelegate>

@property (nonatomic, strong) CvVideoCamera* videoCamera;
@property (nonatomic, assign) OpenCVDetectorType detectorType;
@property (nonatomic, assign) CGFloat scale;

@end

@implementation OpenCVDetector

- (instancetype)initWithCameraView:(UIImageView *)view scale:(CGFloat)scale {
    self = [super init];
    
    if (self) {
        
//        self.videoCamera = [[CvVideoCamera alloc] initWithParentView: view];
        self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
        //self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset640x480;
        self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
        self.videoCamera.defaultFPS = 30;
        self.videoCamera.grayscaleMode = NO;
        self.videoCamera.delegate = self;
        self.videoCamera.rotateVideo = true;
        self.scale = scale;
        self.detectorType = OpenCVDetectorTypeFace;
    }
    
    return self;
}

#pragma mark - Private detection methods

- (void)detectAndDrawHand:(Mat&) img scale:(double) scale {
    // segmenting by skin color (has to be adjusted)
    
    
    Scalar color = CV_RGB(200, 80, 90);
    Mat thresholded = [self makeHandMaskFor:img];
    vector<cv::Mat> contours;
    
    findContours(thresholded, contours, RETR_EXTERNAL, CHAIN_APPROX_SIMPLE);
    
    int index = [self firstIndex:contours];
    
    if ( index ==  -1) { return; }
    
    for (int i = 0 ; i < contours.size() ; i++) {
        //  drawContours(img, contours, index, color);
        Mat contour = contours[i];
        vector<cv::Point> points;
        
        convexHull(contour, points, true , true);
        
        for (int i = 0; i < points.size(); i++)
            circle( img, points[i], 20, color, 3, 8, 0 );
    }
    
    //    [self getRoundHull:contours[index] forImage:img];
}

- (Mat) makeHandMaskFor:(Mat&) img {
    
    Mat imgHLS;
    Mat rangeMask;
    Mat blurred;
    Mat thresholded;
    cv::Size minSize(10,10);
    
    cvtColor(img, imgHLS, COLOR_BGR2GRAY);
    inRange(imgHLS, 8, 90, rangeMask);
    blur(rangeMask, blurred, minSize);
    threshold(blurred, thresholded, 150, 250, THRESH_BINARY);
    
    return thresholded;
}

- (int) firstIndex:(vector<cv::Mat>) contours {
    
    vector<int> sortIdx(contours.size());
    vector<float> areas(contours.size());
    
    for( int n = 0; n < (int)contours.size(); n++ ) {
        sortIdx[n] = n;
        areas[n] = contourArea(contours[n], false);
    }
    
    sort( sortIdx.begin(), sortIdx.end(), AreaCmp(areas ));
    
    if (sortIdx.empty() || contours.empty()) {
        return -1;
    }
    
    return sortIdx[0];
}

-(void) getRoundHull: (Mat&) contour forImage: (Mat&) img {
    
    Mat hullIndices;
    Mat contourPoints;
    Scalar color = CV_RGB(200, 80, 90);
    
    vector<cv::Point> points;
    vector<int> labels;
    
    convexHull(contour, points, true , true);
    //    partition(&points, labels);
    
    for (int i = 0; i < points.size(); i++)
        circle( img, points[i], 20, color, 3, 8, 0 );
    
    //    for (int x = 0; x < img.cols; x++)
    //        for (int y = 0; y < img.rows; y++)
    //            circle( img, Point(x, y), radius, color, 3, 8, 0 );
    //
    //    cv::Rect rect = boundingRect(contour);
    //
    //    for( int i =0; i < hullIndices.size(); i ++)
    //    {
    //        center.x = cvRound((r->x + nr->x + nr->width*0.5)*scale);
    //        center.y = cvRound((r->y + nr->y + nr->height*0.5)*scale);
    //        int radius = cvRound((nr->width + nr->height)*0.25*scale);
    //
    //    }
}

#pragma mark - CvVideoCameraDelegate

- (void)processImage:(cv::Mat&)image {
    [self detectAndDrawHand:image scale: self.scale];
}

#pragma mark - Public

- (void)startCapture {
    
}

- (void)stopCapture {
    
}

@end
