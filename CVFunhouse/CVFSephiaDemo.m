//
//  CVFSephiaDemo.m
//  CVFunhouse
//
//  Created by Matthew Shopsin on 7/21/12.
//  Copyright (c) 2012 Jera Design LLC. All rights reserved.
//

#import "CVFSephiaDemo.h"
#include "opencv2/core/core_c.h"
#include "opencv2/imgproc/imgproc_c.h"

@implementation CVFSephiaDemo



-(void)processIplImage:(IplImage*)iplImage
{
    IplImage *output     = cvCreateImage(cvGetSize(iplImage), IPL_DEPTH_8U, 3);
    IplImage *sepiaImage = cvCreateImage(cvGetSize(iplImage), IPL_DEPTH_8U, 4);
    //cvCvtColor(iplImage, output, CV_RGB2BGR);
    float sepia_Array[] = {0.393, 0.769, 0.189,0.0, 0.349, 0.686, 0.168,0.0, 0.272, 0.534, 0.131,0.0, 0.0, 0.0, 0.0, 1.0};
        CvMat m_Sepia = cvMat(3, 3, CV_32F, sepia_Array);
    
    cvFilter2D(iplImage, sepiaImage, &m_Sepia, cvPoint(1, -1));//(iplImage, sepiaImage, &m_Sepia, NULL);
     cvCvtColor(sepiaImage, output, CV_BGRA2RGB);
    //cvCvtColor(output, output2, CV_RGB2BGR);
    //cvReleaseImage(&sepiaImage);
     cvReleaseImage(&sepiaImage);
    cvReleaseImage(&iplImage);
    
   
    
    [self imageReady:output];
}

@end
