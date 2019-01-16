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
        
        self.videoCamera = [[CvVideoCamera alloc] initWithParentView: view];
        self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionFront;
//        self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset640x480;
        self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
        self.videoCamera.defaultFPS = 30;
        self.videoCamera.delegate = self;
        self.videoCamera.rotateVideo = NO;
        self.scale = scale;
        self.detectorType = OpenCVDetectorTypeFace;
    }
    
    return self;
}

#pragma mark - Private detection methods

- (void)detectAndDrawHand:(Mat&) img scale:(double) scale {
    // segmenting by skin color (has to be adjusted)
    
    Scalar color = CV_RGB(200, 80, 90);
    Mat mask = [self makeHandMaskFor:img];
    vector<vector<cv::Point>> contours = [self contours: mask];
    
    Mat drawing = Mat::zeros( mask.size(), CV_8UC3 );
    for(int i = 0; i< contours.size(); i++ )
        drawContours(drawing, contours, i, color, 1, 8, vector<Vec4i>(), 0, cv::Point());
  
    img = drawing;
}

- (Mat) makeHandMaskFor:(Mat&) img {
    
    Mat imgHLS;
    Mat rangeMask;
    Mat blurred;
    Mat thresholded;
    cv::Size blurSize(10,10);
    
    cvtColor(img, imgHLS, COLOR_BGR2GRAY);
    blur(imgHLS, imgHLS, blurSize);
    
    return imgHLS;
}

- (vector<vector<cv::Point>>) contours:(Mat) src_gray {
    
    Mat canny_output;
    vector<vector<cv::Point>> contours;
    vector<cv::Point> points;
    vector<Vec4i> hierarchy;
    
    int value = 60;
    /// Detect edges using canny
    Canny(src_gray, canny_output, value, value*2, 3);
    
    /// Find contours
    findContours(canny_output, contours, hierarchy, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE, cv::Point(0, 0));
    
    return contours;
}

#pragma mark - CvVideoCameraDelegate

- (void)processImage:(cv::Mat&)image {
    [self detectAndDrawHand:image scale: self.scale];
}

#pragma mark - Public

- (void)startCapture {
    [self.videoCamera start];
}

- (void)stopCapture {
    [self.videoCamera stop];
}

@end
