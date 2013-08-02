//
//  CVFHough.m
//  CVFunhouse
//
//  Created by John Brewer on 8/1/13.
//  Copyright (c) 2013 Jera Design LLC. All rights reserved.
//

#import "CVFHough.h"

#include "opencv2/imgproc/imgproc.hpp"

using namespace std;
using namespace cv;

@implementation CVFHough

-(void)processMat:(Mat)mat
{
    cvtColor(mat, mat, CV_BGR2RGB);
    Mat grayImage;
    cvtColor(mat, grayImage, CV_RGB2GRAY);
    vector<Vec4i> lines;
    Mat canny;
    Canny(grayImage, canny, 50, 100);
    HoughLinesP(canny, lines, 1, CV_PI/180, 80, 30, 10 );
    for( size_t i = 0; i < lines.size(); i++ )
    {
        line( mat, cv::Point(lines[i][0], lines[i][1]),
             cv::Point(lines[i][2], lines[i][3]), Scalar(0,0,255), 3, 8 );
    }
    [self matReady:mat];
}

@end
