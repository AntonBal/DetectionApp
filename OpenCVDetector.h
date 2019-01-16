//
//  OpenCVWrapper.h
//  DetectionApp
//
//  Created by Anton Bal on 11/22/18.
//  Copyright © 2018 Cleveroad. All rights reserved.
//

#import <opencv2/highgui/cap_ios.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSUInteger, OpenCVDetectorType) {
    OpenCVDetectorTypeFace                 = 0,
    OpenCVDetectorTypeHand                 = 1 << 0
};

@interface OpenCVDetector : NSObject <CvVideoCameraDelegate>

@property (nonatomic, strong) CvVideoCamera* videoCamera;
@property (nonatomic, assign) OpenCVDetectorType detectorType;

- (instancetype)initWithCameraView:(UIImageView *)view scale:(CGFloat)scale;

- (void)startCapture;
- (void)stopCapture;

@end

NS_ASSUME_NONNULL_END
