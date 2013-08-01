//
//  CVFFreak.mm
//  CVFunhouse
//
//  Created by John Brewer on 7/28/13.
//  Copyright (c) 2013 Jera Design LLC. All rights reserved.
//

#import "CVFFreak.h"

@implementation CVFFreak

cv::Mat targetImage;
std::vector<cv::KeyPoint> targetKeyPoints;
cv::Mat targetDescriptors;

-(id)init
{
    self = [super init];
    if (self == nil) { return nil; }

    cv::OrbFeatureDetector detector(400);
    
    cv::FREAK extractor;
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"IMG_2721" ofType:@"jpg"];
    const char * cpath = [path cStringUsingEncoding:NSUTF8StringEncoding];
    targetImage = cv::imread(cpath, CV_LOAD_IMAGE_GRAYSCALE);
    
    detector.detect(targetImage, targetKeyPoints);
    extractor.compute(targetImage, targetKeyPoints, targetDescriptors);

    return self;
}

-(void)processIplImage:(IplImage*)iplImage
{
    // We get an BGRA image at 8-bits per pixel, but we need an RGB image
    // to pass to imageReady:, so we need to do a brief conversion.
    
    // To do the conversion, first create an IplImage the same size...
    IplImage *grayImage = cvCreateImage(cvGetSize(iplImage), IPL_DEPTH_8U, 1);
    
    // Call cvCvtColor to do the conversion
    cvCvtColor(iplImage, grayImage, CV_BGR2GRAY);

    // Release the original image or you will run out of memory very fast!
    cvReleaseImage(&iplImage);
    
    cv::Mat image2(grayImage);
    
    std::vector<cv::KeyPoint> searchKeyPoints;
    cv::Mat searchDescriptors;
    cv::OrbFeatureDetector detector(400);
    
    cv::FREAK extractor;
    
    cv::BFMatcher matcher(cv::NORM_HAMMING);
    
    std::vector<cv::DMatch> matches;
    
    detector.detect(image2, searchKeyPoints);
    if (searchKeyPoints.size() == 0) {
        [self imageReady:grayImage];
        return;
    }
    
    extractor.compute(image2, searchKeyPoints, searchDescriptors);
    
//    NSLog(@"targetDescriptors.type = %d", targetDescriptors.type());
//    NSLog(@"searchDescriptors.type = %d", searchDescriptors.type());
//    NSLog(@"targetDescriptors.cols = %d", targetDescriptors.cols);
//    NSLog(@"searchDescriptors.cols = %d", searchDescriptors.cols);
    if (searchDescriptors.cols == 0) {
        [self imageReady:grayImage];
        return;
    }

    matcher.match(targetDescriptors, searchDescriptors, matches);
    if (matches.size() > 30) {
        int nofmatches = 30;
        nth_element(matches.begin(),matches.begin()+nofmatches,matches.end());
        matches.erase(matches.begin()+nofmatches+1,matches.end());
    }
    
    if (matches.size() == 0) {
        [self imageReady:grayImage];
        return;
    }

    cv::Mat imgMatch;
    cv::drawMatches(targetImage, targetKeyPoints, image2, searchKeyPoints, matches, imgMatch,
                cv::Scalar::all(-1), cv::Scalar::all(-1), std::vector<char>(),
                cv::DrawMatchesFlags::DRAW_RICH_KEYPOINTS | cv::DrawMatchesFlags::NOT_DRAW_SINGLE_POINTS);

    cvReleaseImage(&grayImage);
    
    IplImage tempImage = imgMatch;
    IplImage *outImage = cvCloneImage(&tempImage);
    
    // Call imageReady with your new image.
    [self imageReady:outImage];
}

@end
