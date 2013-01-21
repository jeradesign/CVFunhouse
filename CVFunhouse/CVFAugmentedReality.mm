//
//  CVFAugmentedReality.m
//  CVFunhouse
//
//  Created by John Brewer on 1/5/13.
//  Copyright (c) 2013 Jera Design LLC. All rights reserved.
//

#import "CVFAugmentedReality.h"
#import "markerdetector.h"
#import <sys/sysctl.h>
#import <stdlib.h>

#define SIZE 1.0

@implementation CVFAugmentedReality

cv::Mat intrinsics;
cv::Mat distortion;
aruco::CameraParameters cameraParams;

aruco::MarkerDetector markerDetector;

-(id)init
{
    if ((self = [super init]) == nil) {
        return nil;
    }
    
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = (char *)malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithUTF8String:machine];
    free(machine);
    NSLog(@"%@", platform);
    
    NSString *cameraFilename = [platform stringByAppendingString:@"-back-camera"];
    
    NSString *cameraPath = [[NSBundle mainBundle] pathForResource:cameraFilename ofType:@"xml"];
    cv::FileStorage cfs([cameraPath UTF8String], cv::FileStorage::READ);
    cfs["Intrinsics"]>>intrinsics;
    cfs["Distortion"]>>distortion;
    cfs.release();
    
    return self;
}

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
    
    NSMutableArray *matrices = [NSMutableArray array];
    
    if (markers.size() > 0) {
        double proj_matrix[16];
        if (!cameraParams.isValid()) {
            cameraParams.setParams(intrinsics, distortion, cvGetSize(rgbImage));
        }
        cameraParams.glGetProjectionMatrix(cvGetSize(rgbImage),
                                           cvGetSize(rgbImage),
                                           proj_matrix,
                                           0.01,
                                           100,
                                           false);
        NSData *projectionData = [NSData dataWithBytes:proj_matrix
                                               length:sizeof(proj_matrix)];
        [matrices addObject:projectionData];
    }
    
    for (auto marker : markers) {
        marker.draw(rgbMat, cv::Scalar(0, 255, 0, 0));
        
        marker.calculateExtrinsics(1.0, intrinsics, distortion, false);
        double modelview_matrix[16] = {
            -0.219635, 0.974761, 0.040022, 0.000000,
            -0.082859, -0.059514, 0.994783, 0.000000,
            -0.972057, -0.215173, -0.093839, 0.000000,
            -0.141297, 1.313161, -5.681901, 1.000000 };
        marker.glGetModelViewMatrix(modelview_matrix);
        
//        modelview_matrix[5] = -4.0;

        NSLog(@"modelview_matrix =\n%f, %f, %f, %f\n%f, %f, %f, %f\n%f, %f, %f, %f\n%f, %f, %f, %f\n",
              modelview_matrix[0],modelview_matrix[1],modelview_matrix[2],modelview_matrix[3],
              modelview_matrix[4],modelview_matrix[5],modelview_matrix[6],modelview_matrix[7],
              modelview_matrix[8],modelview_matrix[9],modelview_matrix[10],modelview_matrix[11],
              modelview_matrix[12],modelview_matrix[13],modelview_matrix[14],modelview_matrix[15]
              );

        NSData *modelviewData = [NSData dataWithBytes:modelview_matrix
                                               length:sizeof(modelview_matrix)];
//        NSLog(@" Adding object with NSData:%@", modelviewData);
        [matrices addObject:modelviewData];
    }
    
    [self dataReady: matrices];
    // Call imageReady with your new image.
    [self imageReady:rgbImage];
}

@end
