//
//  BodyDetector.m
//  DetectionApp
//
//  Created by Anton Bal' on 1/17/19.
//  Copyright © 2019 Anton Bal'. All rights reserved.
//

#import "BodyDetector.h"
#import "UIImage+OpenCV.h"

using namespace cv;
using namespace std;

typedef cv::Point CVPoint;

@interface BodyDetector()
{
    vector<cv::Rect> objects;
    CascadeClassifier bodyCascade;
    dispatch_queue_global_t background;
}


@end

@implementation BodyDetector


- (instancetype)init
{
    self = [super init];
    if (self) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"haarcascade_frontalface_alt.xml"
                                                         ofType:nil];
        std::string cascade_path = (char *)[path UTF8String];
        if (!bodyCascade.load(cascade_path)) {
            NSLog(@"Couldn't load haar cascade file.");
        }
        
        background = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, DISPATCH_QUEUE_SERIAL);
    }
    
    return self;
}

- (void) detectImageRef:(CVImageBufferRef) pixelBuffer size:(CGSize) size scale:(NSInteger) scale completed:(CompletedBlock)block {
    
    @autoreleasepool {
        
        OSType format = CVPixelBufferGetPixelFormatType(pixelBuffer);
        CGRect videoRect = CGRectMake(0.0f, 0.0f, CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer));
        cv::Mat mat;
        
        CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
        
        if (format == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) {
            // For grayscale mode, the luminance channel of the YUV data is used
            void *baseaddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
            
            mat = Mat(videoRect.size.height, videoRect.size.width, CV_8UC1, baseaddress, 0);
        } else if (format == kCVPixelFormatType_32BGRA) {
            // For color mode a 4-channel cv::Mat is created from the BGRA data
            void *baseaddress = CVPixelBufferGetBaseAddress(pixelBuffer);
            
            mat = Mat(videoRect.size.height, videoRect.size.width, CV_8UC4, baseaddress, 0);
        } else {
            NSLog(@"Unsupported video format");
            return;
        }
        
        cv::resize(mat, mat, cvSize(size.height / scale, size.width / scale));
        BodyObject* body = [self detecBodyForMat:mat];
        
        block(body);
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
    }
}

- (UIImage*) detectAndDrawImage:(UIImage*) img {
    Mat mat = [img cvMatRepresentationColor];
    return [UIImage imageFromCVMat: [self detectAndDraw:mat scale: 1.0]];
}

- (BodyObject*)detecBodyForMat:(cv::Mat)img {
//    cvtColor(img, grayMat, CV_BGR2GRAY);
   
    ///JUST PORTRAIT!!!!!!!!
    
    cv::rotate(img, img, cv::ROTATE_90_CLOCKWISE);
    
    objects.clear();
    
    bodyCascade.detectMultiScale(img, objects);
    
    BodyObject* body;
    if (objects.size() > 0) {
        body = [[BodyObject alloc] init];
        const cv::Rect faceRectangle = objects[0];

        body.head = CGRectMake(faceRectangle.x, faceRectangle.y, faceRectangle.width, faceRectangle.height);

//        rectangle(img, faceRectangle, CV_RGB(255, 50, 50));
//        auto size = img.size();
//        UIImage* image = [UIImage imageFromCVMat: img];
        
        auto y = faceRectangle.y + faceRectangle.height + faceRectangle.width / 2;
        auto point1 = cvPoint(0, y);
        auto point2 = cvPoint(INT_MAX, y);
    
        Mat drawing = [self contoursForImage:img mask:[self makeHandMaskFor:img]];
        
        bool found = false;
        
        NSMutableArray* shoulders = [[NSMutableArray alloc] init];
     //   line(img, point1, point2, color);
        
        LineIterator it(drawing, point1, point2, 8);
        
        //Try to find intersection of a contour and line
        for(int nbPt = 0; nbPt < it.count; nbPt++, ++it) {
            cv::Point pos = it.pos();
            if (drawing.at<uchar>(pos) != 0) {
                [shoulders addObject: [NSValue valueWithCGPoint: CGPointMake(pos.x, pos.y)]];
                found = true;
            }
        }
        
        if (!found) { // If not found to calculate it
            auto middleX = faceRectangle.x + faceRectangle.width / 2;
            auto point1 = cvPoint(middleX - faceRectangle.height, y);
            auto point2 = cvPoint(middleX + faceRectangle.height, y);
            [shoulders addObject: [NSValue valueWithCGPoint: CGPointMake(point1.x, point1.y)]];
            [shoulders addObject: [NSValue valueWithCGPoint: CGPointMake(point2.x, point2.y)]];
        }
        
        body.shoulders = shoulders;
    }
    return body;
}

- (cv::Mat)detectAndDraw:(cv::Mat)img scale:(CGFloat)scale {
    return [self drawBody: [self detecBodyForMat:img] toImage:img];
}

-(cv::Mat) drawBody: (BodyObject*) body toImage:(cv::Mat)img{
    
    auto color = CV_RGB(255, 50, 50);
    auto head = cv::Rect(CGRectGetMinX(body.head), CGRectGetMinY(body.head), CGRectGetWidth(body.head), CGRectGetHeight(body.head));
    
    rectangle(img, head, color);
    
    for (NSUInteger i = 0; i < [body.shoulders count]; i++) {
        CGPoint value = ((NSValue *)body.shoulders[i]).CGPointValue;
        auto point = cvPoint(value.x, value.y);
        circle(img, point, 8, color);
    }
    
    return img;
}

#pragma mark - Private detection methods

- (Mat) makeHandMaskFor:(Mat&) img {
    
    Mat mask = img;
    cv::Size blurSize(3,3);
    
//    cvtColor(img, mask, CV_RGB2GRAY);
    
    /*
    auto low = Mat(mask.rows, mask.cols, mask.type(), CV_RGB(50, 50, 90));
    auto high = Mat(mask.rows, mask.cols, mask.type(), CV_RGB(255, 255, 200));
    inRange(mask, low, high, mask);
    */
    
    blur(mask, mask, blurSize);
    threshold(mask, mask, 90, 255, THRESH_BINARY);
//    adaptiveThreshold(mask, mask, 200, ADAPTIVE_THRESH_GAUSSIAN_C, THRESH_BINARY, 15, 7);
    
    return mask;
}

- (Mat) contoursForImage:(Mat) img mask:(Mat) mask {
    
    vector<vector<CVPoint>> contours;
    vector<Vec4i> hierarchy;
    
    int value = 100;
    /// Detect edges using canny
    Canny(mask, mask, value, value*2, 3);
    
    /// Find contours
    findContours(mask, contours, hierarchy, CV_RETR_EXTERNAL, CV_CHAIN_APPROX_SIMPLE);
    
    Scalar colorRed = CV_RGB(50, 50, 255);
    int largest_area=0;
    int largest_contour_index=0;
    cv::Rect bounding_rect;
    
    if (contours.size() > 0) {
        Mat drawing = Mat::zeros(img.size(), CV_8UC1);
        
        for( int i = 0; i< contours.size(); i++ ) // iterate through each contour.
        {
            double a=contourArea( contours[i],false);  //  Find the area of contour
            if(a>largest_area){
                largest_area=a;
                largest_contour_index=i;                //Store the index of largest contour
                bounding_rect= boundingRect(contours[i]); // Find the bounding rectangle for biggest contour
            }
        }
        
        vector<CVPoint> points = contours[largest_contour_index];
        drawContours(drawing, contours, largest_contour_index, colorRed);
        drawContours(img, contours, largest_contour_index, colorRed);
    
//        auto extLeft = min_element(points.begin(), points.end(), ^(CVPoint lhs, CVPoint rhs) { return lhs.x < rhs.x; });
//        auto extRight = max_element(points.begin(), points.end(), ^(CVPoint lhs, CVPoint rhs) { return lhs.x < rhs.x; });
//        auto extTop = min_element(points.begin(), points.end(), ^(CVPoint lhs, CVPoint rhs) { return lhs.y < rhs.y; });
//        auto extBot = max_element(points.begin(), points.end(), ^(CVPoint lhs, CVPoint rhs) { return lhs.y < rhs.y; });
//
//        int radius = 5;
//
//        rectangle(img, bounding_rect, colorRed, 3);
//        circle(img, extLeft[0], radius, colorRed);
//        circle(img, extRight[1], radius, colorRed);
//        circle(img, extTop[0], radius, colorRed);
//        circle(img, extBot[1], radius, colorRed);
        return drawing;
    }
    
    return Mat();
}
@end
