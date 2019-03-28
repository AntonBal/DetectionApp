//
//  TShirtDetector.h
//  DetectionApp
//
//  Created by Anton Bal on 3/28/19.
//  Copyright © 2019 Anton Bal'. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TShirtDetector : NSObject

#ifdef __cplusplus
- (cv::Mat) fillImg:(cv::Mat&) img withColor:(cv::Scalar) fillingColor byColor:(cv::Scalar) detectingColor;
#endif

@end

NS_ASSUME_NONNULL_END
