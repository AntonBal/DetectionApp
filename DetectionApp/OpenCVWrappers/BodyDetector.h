//
//  BodyDetector.h
//  DetectionApp
//
//  Created by Anton Bal' on 1/17/19.
//  Copyright © 2019 Anton Bal'. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

@interface BodyDetector: NSObject

- (UIImage*) detectAndDraw:(UIImage*) img;

#ifdef __cplusplus
- (cv::Mat) detectAndDraw:(cv::Mat) img scale:(CGFloat) scale;
#endif

@end

NS_ASSUME_NONNULL_END
