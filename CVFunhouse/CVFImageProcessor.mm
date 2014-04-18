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

-(NSString*)demoDescription {
    return @"<h2>No Description Provided</h2>";
}

-(void)processImageBuffer:(CVImageBufferRef)imageBuffer withMirroring:(BOOL)shouldMirror
{
    // Lock the base address of the pixel buffer
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // Get the number of bytes per row for the pixel buffer
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    if (!baseAddress) {
        CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
        return;
    }

    // Get the pixel buffer width and height
    int width = (int)CVPixelBufferGetWidth(imageBuffer);
    int height = (int)CVPixelBufferGetHeight(imageBuffer);
    
    //  char *savedImageData = 0;
    // create IplImage
    cv::Mat mat(height, width, CV_8UC4, baseAddress);
    
//    IplImage *flipCopy = cvCloneImage(iplimage);
//    cvFlip(flipCopy, flipCopy, 0);
    cv::Mat workingCopy;

    if (shouldMirror) {
        cv::transpose(mat, workingCopy);
    } else {
        cv::transpose(mat, workingCopy);
        cv::flip(workingCopy, workingCopy, 1);
    }
    
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);

    [self processMat:workingCopy];
}

/* Default implementation of processMat converts Mat        */
/* to IplImage *, and calls -processIplImage:               */
-(void)processMat:(cv::Mat)mat
{
    IplImage tempImage = mat;
    IplImage *outImage = cvCloneImage(&tempImage);
    [self processIplImage:outImage];
}

/* Override this method do your image processing.           */
/* You are responsible for releasing iplImage.              */
/* Return your IplImage by calling imageReady:              */
/* The IplImage you pass back will be disposed of for you.  */
-(void)processIplImage:(IplImage*)iplImage
{
    IplImage *rgbImage = cvCreateImage(cvGetSize(iplImage), IPL_DEPTH_8U, 3);
    cvCvtColor(iplImage, rgbImage, CV_BGR2RGB);
    cvReleaseImage(&iplImage);

    CvFont font = cvFont(1.0);
    cvPutText(rgbImage,
              "override processMat or processIplImage",
              cvPoint(20, 100),
              &font,
              cvScalar(255));
    [self imageReady:rgbImage];
}

-(void)matReady:(cv::Mat)mat
{
    dispatch_async(dispatch_get_main_queue(), ^{
        cv::Mat *tempMat = new cv::Mat(mat);
        UIImage *uiImage = [self UIImageFromMat:tempMat];
        [self.delegate imageProcessor:self didCreateImage:uiImage];
    });
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

-(UIImage*)UIImageFromMat:(cv::Mat *)mat
{
    CGImageRef cgImage = [self CGImageFromMat:mat];
    UIImage *uiImage = [[UIImage alloc] initWithCGImage: cgImage
                                                  scale: 1.0
                                            orientation: UIImageOrientationUp];
    //    [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    return uiImage;
}

static void ReleaseDataCallback(void *info, const void *data, size_t size)
{
#pragma unused(data)
#pragma unused(size)
    IplImage *iplImage = static_cast<IplImage*>(info);
    cvReleaseImage(&iplImage);
}

static void ReleaseMatDataCallback(void *info, const void *data, size_t size)
{
#pragma unused(data)
#pragma unused(size)
    cv::Mat *mat = static_cast<cv::Mat*>(info);
    delete mat;
}

-(CGImageRef)CGImageFromIplImage:(IplImage*)iplImage
{
    size_t bitsPerComponent = 8;
    size_t bytesPerRow = iplImage->widthStep;

    size_t bitsPerPixel;
    CGColorSpaceRef space;
    
    if (iplImage->nChannels == 1) {
        bitsPerPixel = 8;
        space = CGColorSpaceCreateDeviceGray(); // must release after CGImageCreate
    } else if (iplImage->nChannels == 3) {
        bitsPerPixel = 24;
        space = CGColorSpaceCreateDeviceRGB(); // must release after CGImageCreate
    } else if (iplImage->nChannels == 4) {
        bitsPerPixel = 32;
        space = CGColorSpaceCreateDeviceRGB(); // must release after CGImageCreate
    } else {
        abort();
    }

    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaNone;
    CGDataProviderRef provider = CGDataProviderCreateWithData(iplImage,
                                                              iplImage->imageData,
                                                              0,
                                                              ReleaseDataCallback);
    const CGFloat *decode = NULL;
    bool shouldInterpolate = true;
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

-(CGImageRef)CGImageFromMat:(cv::Mat *)mat
{
    size_t bitsPerComponent = 8;
    size_t bytesPerRow = mat->step;
    
    size_t bitsPerPixel;
    CGColorSpaceRef space;
    
    if (mat->channels() == 1) {
        bitsPerPixel = 8;
        space = CGColorSpaceCreateDeviceGray(); // must release after CGImageCreate
    } else if (mat->channels() == 3) {
        bitsPerPixel = 24;
        space = CGColorSpaceCreateDeviceRGB(); // must release after CGImageCreate
    } else if (mat->channels() == 4) {
        bitsPerPixel = 32;
        space = CGColorSpaceCreateDeviceRGB(); // must release after CGImageCreate
    } else {
        abort();
    }
    
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaNone;
    CGDataProviderRef provider = CGDataProviderCreateWithData(mat,
                                                              mat->data,
                                                              0,
                                                              ReleaseMatDataCallback);
    const CGFloat *decode = NULL;
    bool shouldInterpolate = true;
    CGColorRenderingIntent intent = kCGRenderingIntentDefault;
    
    CGImageRef cgImageRef = CGImageCreate(mat->cols,
                                          mat->rows,
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
