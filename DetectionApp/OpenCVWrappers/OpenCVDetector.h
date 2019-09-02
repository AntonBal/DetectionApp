//
//  OpenCVWrapper.h
//  DetectionApp
//
//  Created by Anton Bal on 11/22/18.
//  Copyright © 2018 Cleveroad. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSUInteger, OpenCVDetectorType) {
    OpenCVDetectorTypeFront                 = 1 << 0,
    OpenCVDetectorTypeBack                  = 1 << 1
};

@interface OpenCVDetector : NSObject

@property (nonatomic, strong) UIImage* capturedImage;
@property (nonatomic, assign) BOOL isShouldDetectFace;

- (instancetype)initWithCameraView:(UIView *)view scale:(CGFloat)scale preset:(AVCaptureSessionPreset) preset type: (OpenCVDetectorType) type ;

- (void)setOffset:(float) offset;
- (void)setHSVRangeValueWithHValue:(float) h sValue:(float) s vValue:(float) v;
- (void)startCapture;
- (void)stopCapture;
- (void)setCameraType:(OpenCVDetectorType) type;
- (void)setDetectingPoint: (CGPoint) point;
- (void)setFillingColorWithRed:(double) red green:(double) green blue:(double) blue;
- (void)setImage:(UIImage* _Nullable) image;
- (void)resetFillingColor;

@end

NS_ASSUME_NONNULL_END
