//
//  OpenCVWrapper.m
//  DetectionApp
//
//  Created by Anton Bal on 11/22/18.
//  Copyright © 2018 Cleveroad. All rights reserved.
//

#ifdef __cplusplus
#import <opencv2/opencv.hpp>
#import <opencv2/opencv.hpp>
#endif

#import "OpenCVDetector.h"
#import "UIImage+OpenCV.h"
using namespace cv;
using namespace std;

struct AreaCmp {
    AreaCmp(const vector<float>& _areas) : areas(&_areas) {}
    bool operator()(int a, int b) const {
        float value = (*areas)[b] - (*areas)[a];
        return value; }
    const vector<float>* areas;
};

@interface OpenCVDetector () {
    
    CascadeClassifier _faceCascad, eyeCascade;
    
    vector<cv::Rect> _faceRects;
}

@property (nonatomic, assign) CGFloat scale;
@property (nonatomic, assign) NSInteger count;

@end

@implementation OpenCVDetector

- (instancetype)initWithCameraView:(UIImageView *)view scale:(CGFloat)scale {
    self = [super init];
    if (self) {
        self.videoCamera = [[CvVideoCamera alloc] initWithParentView:view];
        self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
        self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset640x480;
        self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
        self.videoCamera.defaultFPS = 30;
        self.videoCamera.grayscaleMode = NO;
        self.videoCamera.delegate = self;
        self.videoCamera.rotateVideo = true;
        self.scale = scale;
        self.detectorType = OpenCVDetectorTypeFace;
        
        NSString *faceCascadePath = [[NSBundle mainBundle] pathForResource:@"haarcascade_frontalface_alt2"
                                                                    ofType:@"xml"];
        
        const CFIndex CASCADE_NAME_LEN = 2048;
        char *CASCADE_NAME = (char *) malloc(CASCADE_NAME_LEN);
        CFStringGetFileSystemRepresentation( (CFStringRef)faceCascadePath, CASCADE_NAME, CASCADE_NAME_LEN);
        
        _faceCascad.load(CASCADE_NAME);
        
        free(CASCADE_NAME);
        
        NSString *eyesCascadePath = [[NSBundle mainBundle] pathForResource:@"haarcascade_eye_tree_eyeglasses"
                                                                    ofType:@"xml"];
        
        CFStringGetFileSystemRepresentation( (CFStringRef)eyesCascadePath, CASCADE_NAME, CASCADE_NAME_LEN);
        
        eyeCascade.load(CASCADE_NAME);
    }
    
    return self;
}


- (void)startCapture {
    [self.videoCamera start];
}

- (void)stopCapture; {
    [self.videoCamera stop];
}

- (NSArray *)detectedFaces {
    NSMutableArray *facesArray = [NSMutableArray array];
    for( vector<cv::Rect>::const_iterator r = _faceRects.begin(); r != _faceRects.end(); r++ )
    {
        CGRect faceRect = CGRectMake(_scale*r->x/480., _scale*r->y/640., _scale*r->width/480., _scale*r->height/640.);
        [facesArray addObject:[NSValue valueWithCGRect:faceRect]];
    }
    return facesArray;
}

- (UIImage *)faceWithIndex:(NSInteger)idx {
    
//    cv::Mat img = self->_faceImgs[idx];
    
//    UIImage *ret = [UIImage imageFromCVMat:img];
    
    return nil;
}

- (void)processImage:(cv::Mat&)image {
    // Do some OpenCV stuff with the image
    [self detectAndDrawHand:image scale:_scale];
}




- (void)detectAndDrawHand:(Mat&) img scale:(double) scale {
    // segmenting by skin color (has to be adjusted)
   
   
    Scalar color = CV_RGB(200, 80, 90);
    Mat thresholded = [self makeHandMaskFor:img];
    vector<cv::Mat> contours;
    
    findContours(thresholded, contours, CV_RETR_EXTERNAL, CV_CHAIN_APPROX_SIMPLE);
  
    int index = [self firstIndex:contours];
    
    if ( index ==  -1) { return; }
    
    for (int i = 0 ; i < contours.size() ; i++) {
        //  drawContours(img, contours, index, color);
        Mat contour = contours[i];
        vector<cv::Point> points;
        
        convexHull(contour, points, true , true);
        
        for (int i = 0; i < points.size(); i++)
            circle( img, points[i], 20, color, 3, 8, 0 );
    }
    
//    [self getRoundHull:contours[index] forImage:img];
    
    
}


/*
 const getRoughHull = (contour, maxDist) => {
 // get hull indices and hull points
 const hullIndices = contour.convexHullIndices();
 const contourPoints = contour.getPoints();
 const hullPointsWithIdx = hullIndices.map(idx => ({
 pt: contourPoints[idx],
 contourIdx: idx
 }));
 const hullPoints = hullPointsWithIdx.map(ptWithIdx => ptWithIdx.pt);
 
 // group all points in local neighborhood
 const ptsBelongToSameCluster = (pt1, pt2) => ptDist(pt1, pt2) < maxDist;
 const { labels } = cv.partition(hullPoints, ptsBelongToSameCluster);
 const pointsByLabel = new Map();
 labels.forEach(l => pointsByLabel.set(l, []));
 hullPointsWithIdx.forEach((ptWithIdx, i) => {
 const label = labels[i];
 pointsByLabel.get(label).push(ptWithIdx);
 });
 
 // map points in local neighborhood to most central point
 const getMostCentralPoint = (pointGroup) => {
 // find center
 const center = getCenterPt(pointGroup.map(ptWithIdx => ptWithIdx.pt));
 // sort ascending by distance to center
 return pointGroup.sort(
 (ptWithIdx1, ptWithIdx2) => ptDist(ptWithIdx1.pt, center) - ptDist(ptWithIdx2.pt, center)
 )[0];
 };
 const pointGroups = Array.from(pointsByLabel.values());
 // return contour indices of most central points
 return pointGroups.map(getMostCentralPoint).map(ptWithIdx => ptWithIdx.contourIdx);
 };
 */

-(void) getRoundHull: (Mat&) contour forImage: (Mat&) img {
    
    Mat hullIndices;
    Mat contourPoints;
    Scalar color = CV_RGB(200, 80, 90);
    
    vector<cv::Point> points;
    vector<int> labels;
    
    convexHull(contour, points, true , true);
    partition(&points, labels);
    
    for (int i = 0; i < points.size(); i++)
         circle( img, points[i], 20, color, 3, 8, 0 );
    
//    for (int x = 0; x < img.cols; x++)
//        for (int y = 0; y < img.rows; y++)
//            circle( img, Point(x, y), radius, color, 3, 8, 0 );
//
//    cv::Rect rect = boundingRect(contour);
//
//    for( int i =0; i < hullIndices.size(); i ++)
//    {
//        center.x = cvRound((r->x + nr->x + nr->width*0.5)*scale);
//        center.y = cvRound((r->y + nr->y + nr->height*0.5)*scale);
//        int radius = cvRound((nr->width + nr->height)*0.25*scale);
//
//    }
    
    
}

- (Mat) makeHandMaskFor:(Mat&) img {
    
    Mat imgHLS;
    Mat rangeMask;
    Mat blurred;
    Mat thresholded;
    cv::Size minSize(10,10);
    
    cvtColor(img, imgHLS, COLOR_BGR2GRAY);
    inRange(imgHLS, 8, 90, rangeMask);
    blur(rangeMask, blurred, minSize);
    threshold(blurred, thresholded, 150, 250, THRESH_BINARY);
    
    return thresholded;
}

- (int) firstIndex:(vector<cv::Mat>) contours {
    
    vector<int> sortIdx(contours.size());
    vector<float> areas(contours.size());
    
    for( int n = 0; n < (int)contours.size(); n++ ) {
        sortIdx[n] = n;
        areas[n] = contourArea(contours[n], false);
    }
    
    sort( sortIdx.begin(), sortIdx.end(), AreaCmp(areas ));
    
    if (sortIdx.empty() || contours.empty()) {
        return -1;
    }
    
    return sortIdx[0];
}


- (void)detectAndDrawFacesOn:(Mat&) img scale:(double) scale
{
    int i = 0;
    double t = 0;
    
    const static Scalar colors[] =  { CV_RGB(0,0,255),
        CV_RGB(0,128,255),
        CV_RGB(0,255,255),
        CV_RGB(0,255,0),
        CV_RGB(255,128,0),
        CV_RGB(255,255,0),
        CV_RGB(255,0,0),
        CV_RGB(255,0,255)} ;
    Mat gray, smallImg( cvRound (img.rows/scale), cvRound(img.cols/scale), CV_8UC1 );
    
    cvtColor( img, gray, COLOR_BGR2GRAY );
    resize( gray, smallImg, smallImg.size(), 0, 0, INTER_LINEAR );
    equalizeHist( smallImg, smallImg );
    
    
    
    t = (double)cvGetTickCount();
    double scalingFactor = 1.1;
    int minRects = 2;
    cv::Size minSize(30,30);
    
    self->_faceCascad.detectMultiScale( smallImg, self->_faceRects,
                                         scalingFactor, minRects, 0,
                                         minSize );
    
    t = (double)cvGetTickCount() - t;
    //    printf( "detection time = %g ms\n", t/((double)cvGetTickFrequency()*1000.) );
    vector<cv::Mat> faceImages;
    
    for( vector<cv::Rect>::const_iterator r = _faceRects.begin(); r != _faceRects.end(); r++, i++ )
    {
        cv::Mat smallImgROI;
        cv::Point center;
        Scalar color = colors[i%8];
        vector<cv::Rect> nestedObjects;
        rectangle(img,
                  cvPoint(cvRound(r->x*scale), cvRound(r->y*scale)),
                  cvPoint(cvRound((r->x + r->width-1)*scale), cvRound((r->y + r->height-1)*scale)),
                  color, 1, 8, 0);
        
        //eye detection is pretty low accuracy
                if( self->eyeCascade.empty() )
                    continue;
        
        smallImgROI = smallImg(*r);
        
        faceImages.push_back(smallImgROI.clone());
        
        
        
        self->eyeCascade.detectMultiScale( smallImgROI, nestedObjects,
                                            1.1, 2, 0,
                                            cv::Size(5, 5) );
        for( vector<cv::Rect>::const_iterator nr = nestedObjects.begin(); nr != nestedObjects.end(); nr++ )
        {
            center.x = cvRound((r->x + nr->x + nr->width*0.5)*scale);
            center.y = cvRound((r->y + nr->y + nr->height*0.5)*scale);
            int radius = cvRound((nr->width + nr->height)*0.25*scale);
            circle( img, center, radius, color, 3, 8, 0 );
        }
        
        
    }
    
//    @synchronized(self) {
//        self->_faceImgs = faceImages;
//    }
    
}
@end
