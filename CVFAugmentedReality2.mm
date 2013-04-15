//
//  CVFAugmentedReality2.m
//  CVFunhouse
//
//  Created by John Brewer on 4/11/13.
//  Copyright (c) 2013 Jera Design LLC. All rights reserved.
//

#import "CVFAugmentedReality2.h"

@implementation CVFAugmentedReality2

-(void)processIplImage:(IplImage*)iplImage
{
    // Create a gray cv::Mat
    cv::Mat mat(iplImage);
    cv::Mat grayImage;
    cv::cvtColor(mat, grayImage, CV_BGR2GRAY);
    cvReleaseImage(&iplImage);

    // look for a big square
    cv::Mat outlines;
    cv::threshold(grayImage, outlines, 128, 255, cv::THRESH_BINARY);
    
    std::vector<std::vector<cv::Point> > contours;
    std::vector<cv::Vec4i> hierarchy;
    cv::findContours(outlines, contours, hierarchy, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE);
    
    std::vector<std::vector<cv::Point> > contours_poly;
    for( size_t i = 0; i < contours.size(); i++ ) {
        std::vector<cv::Point> contour_poly;
        approxPolyDP( contours[i], contour_poly, 3, true );
        if (contour_poly.size() == 4) {
            contours_poly.push_back(contour_poly);
        }
    }
    
    NSLog(@"#contours = %ld", contours_poly.size());
    cv::drawContours(grayImage, contours_poly, -1, cv::Scalar(128, 128, 128), 2, 8);

    // Process output
    IplImage grayIplImage = grayImage;
    IplImage *outImage = cvCloneImage(&grayIplImage);
    // Call imageReady with your new image.
    [self imageReady:outImage];
}

@end
