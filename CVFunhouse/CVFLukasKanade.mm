//
//  CVFLukasKanade.m
//  CVFunhouse
//
//  Created by John Brewer on 7/25/12.
//  Copyright (c) 2012 Jera Design LLC. All rights reserved.
//

// Based on the OpenCV example: <opencv>/samples/cpp/lkdemo.cpp

#import "CVFLukasKanade.h"

#include "opencv2/video/tracking.hpp"
#include "opencv2/imgproc/imgproc.hpp"

using namespace cv;
using namespace std;

TermCriteria termcrit(CV_TERMCRIT_ITER|CV_TERMCRIT_EPS,20,0.03);
cv::Size subPixWinSize(10,10), winSize(31,31);
const int MAX_COUNT = 500;

@interface CVFLukasKanade () {
    bool hasBeenInited;
    Mat gray, prevGray, image;
    vector<Point2f> points[2];
}

@end


@implementation CVFLukasKanade

/*
 *  processIplImage
 *
 *  Inputs:
 *      iplImage: an IplImage in BGRA format, 8 bits per pixel.
 *          YOU ARE RESPONSIBLE FOR CALLING cvReleaseImage on this image.
 *
 *  Outputs:
 *      When you are done, call imageReady: with an RGB, RGBA, or grayscale
 *      IplImage with 8-bits per pixel.
 *
 *      You can call imageReady: from any thread and it will do the right thing.
 *      You can fork as many threads to process the image as you like; just call
 *      imageReady when you are done.
 *
 *      imageReady: will dispose of the IplImage you pass it once the system is
 *      done with it.
 */
-(void)processIplImage:(IplImage*)iplImage
{
    // We get an BGRA image at 8-bits per pixel, but we need an RGB image
    // to pass to imageReady:, so we need to do a brief conversion.
    
    // To do the conversion, first create an IplImage the same size...
    IplImage *rgbImage = cvCreateImage(cvGetSize(iplImage), IPL_DEPTH_8U, 3);

    // Call cvCvtColor to do the conversion
    cvCvtColor(iplImage, rgbImage, CV_BGR2RGB);
    
    // Release the original image or you will run out of memory very fast!
    cvReleaseImage(&iplImage);
    
    Mat frame = Mat(rgbImage);

    frame.copyTo(image);
    cvReleaseImage(&rgbImage);
    
    cvtColor(image, gray, CV_BGR2GRAY);
    
    
    if( !hasBeenInited )
    {
        // automatic initialization
        goodFeaturesToTrack(gray, points[1], MAX_COUNT, 0.01, 10, Mat(), 3, 0, 0.04);
        cornerSubPix(gray, points[1], subPixWinSize, cv::Size(-1,-1), termcrit);
    }
    else if( !points[0].empty() )
    {
        vector<uchar> status;
        vector<float> err;
        if(prevGray.empty())
            gray.copyTo(prevGray);
        calcOpticalFlowPyrLK(prevGray, gray, points[0], points[1], status, err, winSize,
                             3, termcrit, 0, 0.001);
        size_t i, k;
        for( i = k = 0; i < points[1].size(); i++ )
        {
            if( !status[i] )
                continue;
            
            points[1][k++] = points[1][i];
            circle( image, points[1][i], 3, Scalar(0,255,0), -1, 8);
        }
        points[1].resize(k);
    }
    
    hasBeenInited = true;
        
    std::swap(points[1], points[0]);
    swap(prevGray, gray);

    IplImage tempImage = image;
    IplImage *outImage = cvCloneImage(&tempImage);
    
    // Call imageReady with your new image.
    [self imageReady:outImage];
}

@end
