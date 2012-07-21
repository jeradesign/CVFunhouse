//
//  CVFCannyDemo.m
//  CVFunhouse
//
//  Created by John Brewer on 7/21/12.
//  Copyright (c) 2012 Jera Design LLC. All rights reserved.
//

#import "CVFCannyDemo.h"
#include "opencv2/core/core_c.h"
#include "opencv2/imgproc/imgproc_c.h"

@implementation CVFCannyDemo
/* Override this method do your image processing.           */
/* You are responsible for releasing ipImage.               */
/* Return your IplImage by calling imageReady:              */
/* The IplImage you pass back will be disposed of for you.  */
-(void)processIplImage:(IplImage*)iplImage
{
    IplImage *grayImage = cvCreateImage(cvGetSize(iplImage), IPL_DEPTH_8U, 1);
    cvCvtColor(iplImage, grayImage, CV_BGRA2GRAY);
    cvReleaseImage(&iplImage);
    
    IplImage* img_blur = cvCreateImage( cvGetSize( grayImage ), grayImage->depth, 1);
    cvSmooth(grayImage, img_blur, CV_BLUR, 3, 0, 0, 0);
    cvReleaseImage(&grayImage);
    
    IplImage* img_canny = cvCreateImage( cvGetSize( img_blur ), img_blur->depth, 1);
    cvCanny( img_blur, img_canny, 10, 100, 3 );
    cvReleaseImage(&img_blur);
    
    cvNot(img_canny, img_canny);
    
    [self imageReady:img_canny];
}

@end
