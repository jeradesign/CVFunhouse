//
//  CVFImageProcessor.m
//  CVFunhouse
//
//  Created by John Brewer on 3/7/12.
//  Copyright (c) 2012 Jera Design LLC. All rights reserved.
//

#import "CVFImageProcessor.h"
#include "opencv2/core/core_c.h"
#include "opencv2/imgproc/imgproc_c.h"
#include "CVFImageProcessorDelegate.h"

@interface CVFImageProcessor ()

-(UIImage*)UIImageFromIplImage:(IplImage*)iplImage;
-(CGImageRef)CGImageFromIplImage:(IplImage*)iplImage;

@end

@implementation CVFImageProcessor

@synthesize delegate;

-(void)processImageBuffer:(CVImageBufferRef)imageBuffer
{
    // Lock the base address of the pixel buffer
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // Get the number of bytes per row for the pixel buffer
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    // Get the pixel buffer width and height
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    //  char *savedImageData = 0;
    // create IplImage
    IplImage *iplimage;
    if (baseAddress) {
        iplimage = cvCreateImageHeader(cvSize(width, height), IPL_DEPTH_8U, 4);
        iplimage->imageData = (char*)baseAddress;
    }
    
//    IplImage *flipCopy = cvCloneImage(iplimage);
//    cvFlip(flipCopy, flipCopy, 0);
    IplImage *workingCopy = cvCreateImage(cvSize(height, width), IPL_DEPTH_8U, 4);
    cvTranspose(iplimage, workingCopy);

    cvReleaseImageHeader(&iplimage);
    
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);

    [self processIplImage:workingCopy];
}


/* Override this method do your image processing.           */
/* You are responsible for releasing ipImage.               */
/* Return your IplImage by calling imageReady:              */
/* The IplImage you pass back will be disposed of for you.  */
-(void)processIplImage:(IplImage*)iplImage
{
    IplImage *grayImage = cvCreateImage(cvGetSize(iplImage), IPL_DEPTH_8U, 1);
    cvCvtColor(iplImage, grayImage, CV_BGRA2GRAY);
    cvReleaseImage(&iplImage);
    
    [self imageReady:grayImage];
}


-(void)imageReady:(IplImage *)image
{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIImage *uiImage = [self UIImageFromIplImage:image];
        [self.delegate imageProcessor:self didCreateImage:uiImage];        
    });
}

-(UIImage*)UIImageFromIplImage:(IplImage*)iplImage
{
    CGImageRef cgImage = [self CGImageFromIplImage:iplImage];
    UIImage *uiImage = [[UIImage alloc] initWithCGImage: cgImage
                                                  scale: 1.0
                                            orientation: UIImageOrientationUp];
//    [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    return uiImage;
}

static void ReleaseDataCallback(void *info, const void *data, size_t size)
{
    IplImage *iplImage = info;
    cvReleaseImage(&iplImage);
}

-(CGImageRef)CGImageFromIplImage:(IplImage*)iplImage
{
    size_t bitsPerComponent = 8;
    size_t bitsPerPixel = 8;
    size_t bytesPerRow = iplImage->widthStep;
    CGColorSpaceRef space = CGColorSpaceCreateDeviceGray(); // must release after CGImageCreate
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaNone;
    CGDataProviderRef provider = CGDataProviderCreateWithData(iplImage,
                                                              iplImage->imageData,
                                                              0,
                                                              ReleaseDataCallback);
    const CGFloat *decode = NULL;
    bool shouldInterpolate = false;
    CGColorRenderingIntent intent = kCGRenderingIntentDefault;
    
    CGImageRef cgImageRef = CGImageCreate(iplImage->width,
                                          iplImage->height,
                                          bitsPerComponent,
                                          bitsPerPixel,
                                          bytesPerRow,
                                          space,
                                          bitmapInfo,
                                          provider,
                                          decode,
                                          shouldInterpolate,
                                          intent);
    
    CGColorSpaceRelease(space);
    CGDataProviderRelease(provider);
    return cgImageRef;
}

@end
