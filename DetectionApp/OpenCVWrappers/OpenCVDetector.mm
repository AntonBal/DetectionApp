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
#import "TShirtDetector.h"

#pragma mark - OpenCVDetector

using namespace cv;
using namespace std;

@interface OpenCVDetector() <CvVideoCameraDelegate>

@property (nonatomic, strong) CvVideoCamera* videoCamera;
@property (nonatomic, strong) BodyDetector* bodyDetector;
@property (nonatomic, strong) TShirtDetector* tshirtDetector;
@property (nonatomic, assign) CGFloat scale;
@property (nonatomic, assign) Scalar selectingScalar;
@property (nonatomic, assign) Scalar fillingScalar;
@property (nonatomic, assign) bool selectedPointDidChanged;
@property (nonatomic, assign) CGPoint selectedPoint;
@property (nonatomic, assign) Mat additionalImage;

@end

@implementation OpenCVDetector

- (instancetype)initWithCameraView:(UIView *)view scale:(CGFloat)scale preset:(AVCaptureSessionPreset) preset type:(OpenCVDetectorType) type {
    self = [super init];
    
    if (self) {
        
        self.videoCamera = [[CvVideoCamera alloc] initWithParentView: view];
        self.videoCamera.defaultAVCaptureSessionPreset = preset;
        self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
        self.videoCamera.defaultFPS = 30;
        self.videoCamera.delegate = self;
        self.videoCamera.rotateVideo = NO;
//        self.videoCamera.grayscaleMode = NO;
        self.scale = scale;
        
        if (type == OpenCVDetectorTypeFront) {
            self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionFront;
        } else {
            self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
        }
        
        self.bodyDetector = [[BodyDetector alloc] initWithType: BodyDetectorTypeFace];
        self.tshirtDetector = [[TShirtDetector alloc] init];
        self.fillingScalar = Scalar(NAN, NAN, NAN);
        self.selectingScalar = Scalar(NAN, NAN, NAN);
    }
    
    return self;
}

#pragma mark - CvVideoCameraDelegate

- (void)processImage:(cv::Mat&)image {
    
    auto bodyObject = [self.bodyDetector detecBodyForMat: image];
    
    cv::Rect fullBodyRect = cvRect(0, 0, image.cols, image.rows);
    Mat bodyMat = image;
    
    if (bodyObject != nil) {
        
        CGFloat y = CGRectGetMaxY([bodyObject head]);
        CGFloat height = image.rows;
        
        if (height > y) {
            height -= y;
        } else {
            y = 0;
        }
        
        fullBodyRect = cvRect(0, y, image.cols, height);
        bodyMat = image(fullBodyRect);
        
        //Try to detect tshirtColor automatic, once
        if (isnan(self.selectingScalar[0])) {
            if (bodyMat.cols > 0 && bodyMat.rows > 0) {
                int rows = bodyMat.rows;
                int cols = bodyMat.cols;
                self.selectingScalar = [self averageScalarForImage:bodyMat inPoint: CGPointMake(cols/2 - 7, rows - 7)];
            }
        }
    }
    
    if (self.selectedPointDidChanged) {
        self.selectingScalar = [self averageScalarForImage:image inPoint: self.selectedPoint];
        self.selectedPointDidChanged = false;
    }
    
    cvtColor(image, image, COLOR_BGRA2BGR);
    
    if (!isnan(self.selectingScalar[0]) && !isnan(self.fillingScalar[0])) {
        image = [self.tshirtDetector fillImg: image withColor:[self fillingScalar] byColor:[self selectingScalar]];
        // bodyMat.copyTo(image(bodyRect));
    }
    
    cvtColor(image, image, COLOR_BGR2RGB);

    NSArray* shoulders = bodyObject.shoulders;
    
    if (shoulders.count == 2) {
        CGPoint left = [((NSValue*) [shoulders objectAtIndex:0]) CGPointValue];
        CGPoint right = [((NSValue*) [shoulders objectAtIndex:1]) CGPointValue];
        
        CGFloat shouldersWidth = (right.x + left.x) * 0.6;
        CGFloat x = (left.x + right.x) / 2;
        CGFloat y = (left.y + right.y) / 2;
        
        CGRect cgRect = CGRectMake(x, y, image.cols - x, image.rows - y);
        
        if (self.additionalImage.size().empty() || CGRectGetMinX(cgRect) <= 0 || CGRectGetMinY(cgRect) <= 0) return;
        
        auto scale = shouldersWidth / self.additionalImage.cols;
        auto cols = self.additionalImage.cols * scale;
        auto rows = self.additionalImage.rows * scale;
        
        Mat resizedMat;
        
        resize(self.additionalImage, resizedMat, cvSize(cols, rows));
        cvtColor(resizedMat, resizedMat, COLOR_BGRA2BGR);
        
        CGRect rect = CGRectMake(CGRectGetMinX(cgRect) - resizedMat.cols / 2, CGRectGetMinY(cgRect), resizedMat.cols, resizedMat.rows);
        
        if (CGRectGetMaxX(rect) < image.cols && CGRectGetMaxY(rect) < image.rows ) {
            resizedMat.copyTo(image(cv::Rect(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height)));
        }
    }
}

#pragma mark - Private

-(Scalar)averageScalarForImage:(Mat) image inPoint: (CGPoint) point {
    
    int x = point.x;
    int y = point.y;
    
    Mat hsv;
    cvtColor(image, hsv, CV_BGRA2BGR);
    cvtColor(hsv, hsv, CV_BGR2HSV);
    
    Mat rect = hsv(cvRect(x - 3, y - 3, 6, 6));
    
    Scalar hsvColors[rect.rows];
    
    for (int i = 0; i < rect.rows; i++) {
        for (int j = 0; j < rect.cols; j++) {
            auto pixel = rect.at<Vec3b>(i, j);
            hsvColors[i] = Scalar(pixel[0], pixel[1], pixel[2]);
        }
    }
    
    cv::Mat1b mask(rect.rows, rect.cols);
    cv::Scalar hsvColor = cv::mean(rect, mask);
    
    Mat bgr(1,1, CV_8UC3, hsvColor);
    cvtColor(bgr, bgr, CV_HSV2BGR);
    
    Scalar brgColor = Scalar(bgr.data[0], bgr.data[1], bgr.data[2]);
    
//    UIColor* uiColor1 = [UIColor colorWithRed:brgColor[2]/255 green:brgColor[1]/255 blue:brgColor[0]/255 alpha:1];
    
    return brgColor;
}

#pragma mark - Public

- (void)setImage:(UIImage*) image {
    _additionalImage = [image cvMatRepresentationColor];
}

- (void)startCapture {
    [self.videoCamera start];
}

- (void)stopCapture {
    [self.videoCamera stop];
}

- (void)setDetectingPoint: (CGPoint) point {
    _selectedPoint = point;
    self.selectedPointDidChanged = true;
}

- (void)setFillingColorWithRed:(double) red green:(double) green blue:(double) blue {
    self.fillingScalar = Scalar(blue, green, red);
}

- (void) resetFillingColor {
    self.fillingScalar = Scalar(NAN, NAN, NAN);
}

@end
