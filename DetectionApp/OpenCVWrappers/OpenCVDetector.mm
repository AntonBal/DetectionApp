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
@property (nonatomic, assign) Scalar fillingScalar;
@property (nonatomic, assign) bool shoulRecreateDetector;
@property (nonatomic, assign) CGPoint selectedPoint;
@property (nonatomic, assign) Mat additionalImage;
@property (nonatomic, assign) DetectingObject detectingObject;

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
        self.selectedPoint = CGPointZero;
    }
    
    return self;
}

#pragma mark - CvVideoCameraDelegate

- (void)processImage:(cv::Mat&)image {
    
    BodyObject* bodyObject = [self.bodyDetector detecBodyForMat: image];
    
    cv::Rect fullBodyRect = cvRect(0, 0, image.cols, image.rows);
    
    cvtColor(image, image, COLOR_BGRA2BGR);
    
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
        if (self.selectedPoint.x == 0 && self.selectedPoint.y == 0) {
            if (bodyMat.cols > 0 && bodyMat.rows > 0) {
                int rows = bodyMat.rows;
                int cols = bodyMat.cols;
                self.selectedPoint = CGPointMake(cols/2 - 7, rows - 7);
                self.shoulRecreateDetector = true;
            }
        }
    }
    
    if (self.shoulRecreateDetector && !isnan(self.fillingScalar[0])) {
        DetectingObject detectingObject = DetectingObject();
        detectingObject.detectingColors = scalarsForimage(image, self.selectedPoint);
        detectingObject.fillingColor = [self fillingScalar];
        self.detectingObject = detectingObject;
        self.shoulRecreateDetector = false;
    }
    
    Mat imageMat = Mat();
    CvRect imageFrame;
    
    NSArray* shoulders = bodyObject.shoulders;
    
    if (shoulders.count == 2) {
        CGPoint left = [((NSValue*) [shoulders objectAtIndex:0]) CGPointValue];
        CGPoint right = [((NSValue*) [shoulders objectAtIndex:1]) CGPointValue];
        
        CGFloat shouldersWidth = (right.x - left.x) * 0.7;
        CGFloat x = (left.x + right.x) / 2;
        CGFloat y = 80;
        
        if (!self.additionalImage.size().empty() && x >= 0 && y >= 0) {
            float imageScale = float(bodyMat.cols) / float(self.additionalImage.cols);
            float scale = shouldersWidth / bodyMat.cols;
            float cols = self.additionalImage.cols * scale * imageScale;
            float rows = self.additionalImage.rows * scale * imageScale;
            
            resize(self.additionalImage, imageMat, cvSize(cols, rows));
            
            imageFrame = CvRect(x - imageMat.cols / 2, y, imageMat.cols, imageMat.rows);
            cvtColor(imageMat, imageMat, COLOR_RGBA2BGR);
        }
    }
    
    cvtColor(image, image, COLOR_BGRA2BGR);
    
    if (self.detectingObject.detectingColors.size() != 0 && !isnan(self.detectingObject.fillingColor[0])) {
        bodyMat = [self.tshirtDetector fillImg:bodyMat withDetectingObject: self.detectingObject withAdditionalImage:imageMat inRect:imageFrame];
        bodyMat.copyTo(image(fullBodyRect));
    }
    
    cvtColor(image, image, COLOR_BGR2RGB);
}

#pragma mark - Private

vector<Scalar> scalarsForimage(Mat image, CGPoint point)  {
    int x = point.x;
    int y = point.y;
    
    Mat hsv;
    cvtColor(image, hsv, CV_BGRA2BGR);
    cvtColor(hsv, hsv, CV_BGR2HSV);
    
    int value = 3;
    if (x <= value || y <= value) {
        return vector<Scalar>(0);
    }
    
    Mat rect = hsv(cvRect(x - value, y - value, value * 2, value * 2));
    
    vector<Scalar> hsvColors(rect.rows);
    
    for (int i = 0; i < rect.rows; i++) {
        for (int j = 0; j < rect.cols; j++) {
            auto pixel = rect.at<Vec3b>(i, j);
            hsvColors[i] = Scalar(pixel[0], pixel[1], pixel[2]);
        }
    }
    
    return hsvColors;
}

-(Scalar)averageScalarForImage:(Mat) image inPoint: (CGPoint) point {
    
    int x = point.x;
    int y = point.y;
    
    Mat hsv;
    cvtColor(image, hsv, CV_BGRA2BGR);
    cvtColor(hsv, hsv, CV_BGR2HSV);
    
    Mat rect = hsv(cvRect(x - 3, y - 3, 6, 6));
    
    vector<Scalar> hsvColors = scalarsForimage(image, point);
    
    cv::Mat1b mask(rect.rows, rect.cols);
    cv::Scalar hsvColor = cv::mean(rect, mask);
    
    Mat bgr(1,1, CV_8UC3, hsvColor);
    cvtColor(bgr, bgr, CV_HSV2BGR);
    
    Scalar brgColor = Scalar(bgr.data[0], bgr.data[1], bgr.data[2]);
    
//    UIColor* uiColor1 = [UIColor colorWithRed:brgColor[2]/255 green:brgColor[1]/255 blue:brgColor[0]/255 alpha:1];
    
    return brgColor;
}

#pragma mark - Public

- (void)setCameraType:(OpenCVDetectorType) type {
    if (type == OpenCVDetectorTypeFront) {
        self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionFront;
    } else {
        self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    }
}

-(void)setHSVRangeValueWithHValue:(float) h sValue:(float) s vValue:(float) v {
    [self.tshirtDetector setHSVRangeValueWithHValue:h sValue:s vValue:v];
}

- (void)setImage:(UIImage*) image {
    
    if (image) {
        _additionalImage = [image cvMatRepresentationColor];
    } else {
        _additionalImage = Mat();
    }
    
}

- (void)startCapture {
    [self.videoCamera start];
}

- (void)stopCapture {
    [self.videoCamera stop];
}

- (void)setDetectingPoint: (CGPoint) point {
    _selectedPoint = point;
    self.shoulRecreateDetector = true;
}

- (void)setFillingColorWithRed:(double) red green:(double) green blue:(double) blue {
    self.fillingScalar = Scalar(blue, green, red);
    self.shoulRecreateDetector = true;
}

- (void) resetFillingColor {
    self.fillingScalar = Scalar(NAN, NAN, NAN);
}

@end
