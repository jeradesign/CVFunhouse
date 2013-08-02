//
//  CVFFaceDetect.m
//  CVFunhouse
//
//  Created by John Brewer on 7/22/12.
//  Copyright (c) 2012 Jera Design LLC. All rights reserved.
//

// Based on the OpenCV example: <opencv>/samples/c/facedetect.cpp

#import "CVFFaceDetect.h"

#include "opencv2/objdetect/objdetect.hpp"
#include "opencv2/imgproc/imgproc.hpp"

using namespace std;
using namespace cv;

CascadeClassifier cascade;
double scale = 1;

@interface CVFFaceDetect() {
    bool _inited;
}

@end

@implementation CVFFaceDetect

-(void)processNatMat:(cv::Mat)mat
{
    if (!_inited) {
        NSString* haarDataPath =
        [[NSBundle mainBundle] pathForResource:@"haarcascade_frontalface_alt.xml" ofType:nil];
        
        cascade.load([haarDataPath UTF8String]);
        _inited = true;
    }

    cvtColor(mat, mat, CV_BGR2RGB);
    
    int i = 0;
    vector<cv::Rect> faces;
    const static Scalar colors[] =  { CV_RGB(0,0,255),
        CV_RGB(0,128,255),
        CV_RGB(0,255,255),
        CV_RGB(0,255,0),
        CV_RGB(255,128,0),
        CV_RGB(255,255,0),
        CV_RGB(255,0,0),
        CV_RGB(255,0,255)} ;
    Mat gray, smallImg( cvRound (mat.rows/scale), cvRound(mat.cols/scale), CV_8UC1 );
    
    cvtColor( mat, gray, CV_RGB2GRAY );
    resize( gray, smallImg, smallImg.size(), 0, 0, INTER_LINEAR );
    equalizeHist( smallImg, smallImg );
    
    cascade.detectMultiScale( smallImg, faces,
                             1.2, 2, 0
                             //|CV_HAAR_FIND_BIGGEST_OBJECT
                             //|CV_HAAR_DO_ROUGH_SEARCH
                             |CV_HAAR_SCALE_IMAGE
                             ,
                             cv::Size(75, 75) );
    for( vector<cv::Rect>::const_iterator r = faces.begin(); r != faces.end(); r++, i++ )
    {
        Mat smallImgROI;
        vector<cv::Rect> nestedObjects;
        cv::Point center;
        Scalar color = colors[i%8];
        int radius;
        center.x = cvRound((r->x + r->width*0.5)*scale);
        center.y = cvRound((r->y + r->height*0.5)*scale);
        radius = cvRound((r->width + r->height)*0.25*scale);
        circle( mat, center, radius, color, 3, 8, 0 );
    }
    
    [self matReady:mat];
}

@end
