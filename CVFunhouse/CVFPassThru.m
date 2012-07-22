//
//  CVFPassThru.m
//  CVFunhouse
//
//  Created by John Brewer on 7/22/12.
//  Copyright (c) 2012 Jera Design LLC. All rights reserved.
//

#import "CVFPassThru.h"

@implementation CVFPassThru

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
    
    // Call imageReady with your new image.
    [self imageReady:rgbImage];
}

@end
