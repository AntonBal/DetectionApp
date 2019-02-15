//
//  BodyDetector.h
//  DetectionApp
//
//  Created by Anton Bal' on 1/17/19.
//  Copyright © 2019 Anton Bal'. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "BodyObject.h"
#import <CoreVideo/CoreVideo.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^CompletedBlock)(BodyObject* __nullable);

@interface BodyDetector: NSObject

- (UIImage*) detectAndDrawImage:(UIImage*) img;

- (void) detectImageRef:(CVImageBufferRef)imageBuffer completed:(CompletedBlock)block;

#ifdef __cplusplus
- (cv::Mat) detectAndDraw:(cv::Mat) img scale:(CGFloat) scale;
#endif

@end

NS_ASSUME_NONNULL_END
