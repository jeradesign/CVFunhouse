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
-(void)imageReady:(IplImage*)image;

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
