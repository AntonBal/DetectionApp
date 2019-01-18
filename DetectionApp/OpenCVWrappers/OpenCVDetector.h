//
//  OpenCVWrapper.h
//  DetectionApp
//
//  Created by Anton Bal on 11/22/18.
//  Copyright © 2018 Cleveroad. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSUInteger, OpenCVDetectorType) {
    OpenCVDetectorTypeFront                 = 1 << 0,
    OpenCVDetectorTypeBack                  = 1 << 1
};

@interface OpenCVDetector : NSObject

- (instancetype)initWithCameraView:(UIImageView *)view scale:(CGFloat)scale type: (OpenCVDetectorType) type ;

- (void)startCapture;
- (void)stopCapture;

@end

NS_ASSUME_NONNULL_END
