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

typedef void (^CompletedBlock)(UIImage*);

@interface BodyDetector: NSObject

- (UIImage*) detectAndDrawImage:(UIImage*) img;
- (void) detectAndDrawImage: (UIImage*) img completed: (CompletedBlock) block;

#ifdef __cplusplus
- (cv::Mat) detectAndDraw:(cv::Mat) img scale:(CGFloat) scale;
#endif

@end

NS_ASSUME_NONNULL_END
