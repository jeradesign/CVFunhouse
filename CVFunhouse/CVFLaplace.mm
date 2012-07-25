//
//  CVFLaplace.m
//  CVFunhouse
//
//  Created by John Brewer on 7/24/12.
//  Copyright (c) 2012 Jera Design LLC. All rights reserved.
//

// Based on the OpenCV example: <opencv>/samples/cpp/laplace.cpp

#import "CVFLaplace.h"

#include "opencv2/core/core.hpp"
#include "opencv2/imgproc/imgproc.hpp"

using namespace cv;
using namespace std;

int sigma = 3;
int smoothType = CV_GAUSSIAN;

Mat smoothed, laplace, result;

@implementation CVFLaplace

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
    
    int ksize = (sigma*5)|1;
    if(smoothType == CV_GAUSSIAN)
        GaussianBlur(frame, smoothed, cv::Size(ksize, ksize), sigma, sigma);
    else if(smoothType == CV_BLUR)
        blur(frame, smoothed, cv::Size(ksize, ksize));
    else
        medianBlur(frame, smoothed, ksize);
    
    Laplacian(smoothed, laplace, CV_16S, 5);
    convertScaleAbs(laplace, result, (sigma+1)*0.25);
    
    IplImage *resultImage = (IplImage*)cvAlloc(sizeof(IplImage));
    *resultImage = result;
    resultImage = cvCloneImage(resultImage);
    // Call imageReady with your new image.
    [self imageReady:resultImage];
}

@end
