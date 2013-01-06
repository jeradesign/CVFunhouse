//
//  CVFAugmentedReality.m
//  CVFunhouse
//
//  Created by John Brewer on 1/5/13.
//  Copyright (c) 2013 Jera Design LLC. All rights reserved.
//

#import "CVFAugmentedReality.h"
#import "markerdetector.h"

@implementation CVFAugmentedReality

aruco::MarkerDetector markerDetector;

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
    
    std::vector<aruco::Marker> markers;
    markerDetector.detect(rgbImage, markers);
    
    cv::Mat rgbMat(rgbImage);
    
    for (auto marker : markers) {
        marker.draw(rgbMat, cv::Scalar(0, 255, 0, 0));
    }
    
    // Call imageReady with your new image.
    [self imageReady:rgbImage];
}

@end
