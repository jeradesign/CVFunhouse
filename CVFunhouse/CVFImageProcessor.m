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

-(void)processIplImage:(IplImage*)image;
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
    
    IplImage *workingCopy = cvCloneImage(iplimage);

    cvReleaseImageHeader(&iplimage);
    
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);

    [self processIplImage:workingCopy];
}


-(void)processIplImage:(IplImage*)iplImage
{
//    IplImage *grayImage = cvCreateImage(cvGetSize(image), IPL_DEPTH_8U, 1);
//    cvCvtColor(image, grayImage, CV_BGRA2GRAY);
//    cvReleaseImage(&image);
    
    UIImage *uiImage = [self UIImageFromIplImage:iplImage];
    [self.delegate imageProcessor:self didCreateImage:uiImage];
}

-(UIImage*)UIImageFromIplImage:(IplImage*)iplImage
{
    CGImageRef cgImage = [self CGImageFromIplImage:iplImage];
    UIImage *uiImage = [[UIImage alloc] initWithCGImage: cgImage
                                                  scale: 1.0
                                            orientation: UIImageOrientationRight];
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
    size_t bitsPerPixel = 32;
    size_t bytesPerRow = iplImage->widthStep;
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB(); // must release after CGImageCreate
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipFirst;
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
