//
//  CVFFarneback.m
//  CVFunhouse
//
//  Created by John Brewer on 7/22/12.
//  Copyright (c) 2012 Jera Design LLC. All rights reserved.
//

// Based on the OpenCV example: <opencv>/samples/c/fback_c.c

#import "CVFFarneback.h"

#include "opencv2/video/tracking.hpp"
#include "opencv2/imgproc/imgproc_c.h"

CvMat* prevgray = 0, *gray = 0, *flow = 0, *cflow = 0;

static void drawOptFlowMap(const CvMat* flow, CvMat* cflowmap, int step,
                           double scale, CvScalar color)
{
    int x, y;
    (void)scale;
    for( y = 0; y < cflowmap->rows; y += step)
        for( x = 0; x < cflowmap->cols; x += step)
        {
            CvPoint2D32f fxy = CV_MAT_ELEM(*flow, CvPoint2D32f, y, x);
            cvLine(cflowmap, cvPoint(x,y), cvPoint(cvRound(x+fxy.x), cvRound(y+fxy.y)),
                   color, 1, 8, 0);
            cvCircle(cflowmap, cvPoint(x,y), 2, color, -1, 8, 0);
        }
}

@implementation CVFFarneback

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
-(void)processIplImage:(IplImage*)frame
{
    int firstFrame = (gray == 0);
    if(!gray)
    {
        gray = cvCreateMat(frame->height, frame->width, CV_8UC1);
        prevgray = cvCreateMat(gray->rows, gray->cols, gray->type);
        flow = cvCreateMat(gray->rows, gray->cols, CV_32FC2);
        cflow = cvCreateMat(gray->rows, gray->cols, CV_8UC3);
    }
    cvCvtColor(frame, gray, CV_BGR2GRAY);
    cvReleaseImage(&frame);
    
    if( !firstFrame )
    {
        cvCalcOpticalFlowFarneback(prevgray, gray, flow, 0.5, 3, 15, 3, 5, 1.2, 0);
        cvCvtColor(prevgray, cflow, CV_GRAY2BGR);
        drawOptFlowMap(flow, cflow, 16, 1.5, CV_RGB(0, 255, 0));
    }
    {
        CvMat* temp;
        CV_SWAP(prevgray, gray, temp);
    }
    
    // Call imageReady with your new image.
    IplImage *tempImage = cvAlloc(sizeof(IplImage));
    IplImage *outImage = cvGetImage(cflow, tempImage);
    [self imageReady: outImage];
}

@end
