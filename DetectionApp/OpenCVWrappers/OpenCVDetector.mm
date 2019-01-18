//
//  OpenCVWrapper.m
//  DetectionApp
//
//  Created by Anton Bal on 11/22/18.
//  Copyright © 2018 Cleveroad. All rights reserved.
//

#import "OpenCVDetector.h"
#import "UIImage+OpenCV.h"
#import "BodyDetector.h"

#pragma mark - OpenCVDetector

@interface OpenCVDetector() <CvVideoCameraDelegate>

@property (nonatomic, strong) CvVideoCamera* videoCamera;
@property (nonatomic, assign) CGFloat scale;
@property (nonatomic, strong) BodyDetector* detecor;

@end

@implementation OpenCVDetector

- (instancetype)initWithCameraView:(UIImageView *)view scale:(CGFloat)scale type:(OpenCVDetectorType) type {
    self = [super init];
    
    if (self) {
        
        self.videoCamera = [[CvVideoCamera alloc] initWithParentView: view];
        self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset640x480;
        self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
        self.videoCamera.defaultFPS = 30;
        self.videoCamera.delegate = self;
        self.videoCamera.rotateVideo = NO;
        self.scale = scale;
        
        if (type == OpenCVDetectorTypeFront) {
            self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionFront;
        } else {
            self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
        }
        
        self.detecor = [[BodyDetector alloc] init];
    }
    
    return self;
}

#pragma mark - CvVideoCameraDelegate

- (void)processImage:(cv::Mat&)image {
    image = [self.detecor detectAndDraw:image scale:self.scale];
}

#pragma mark - Public

- (void)startCapture {
    [self.videoCamera start];
}

- (void)stopCapture {
    [self.videoCamera stop];
}

@end
