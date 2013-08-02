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

@implementation CVFLaplace

-(void)processMat:(cv::Mat)mat
{
    Mat smoothed, laplace, result;
    
    cvtColor(mat, mat, CV_BGR2RGB);
    
    int ksize = (sigma*5)|1;
    if(smoothType == CV_GAUSSIAN)
        GaussianBlur(mat, smoothed, cv::Size(ksize, ksize), sigma, sigma);
    else if(smoothType == CV_BLUR)
        blur(mat, smoothed, cv::Size(ksize, ksize));
    else
        medianBlur(mat, smoothed, ksize);
    
    Laplacian(smoothed, laplace, CV_16S, 5);
    convertScaleAbs(laplace, result, (sigma+1)*0.25);
    
    [self matReady:result];
}

@end
