//
//  CVFMainViewController.h
//  CVFunhouse
//
//  Created by John Brewer on 3/7/12.
//  Copyright (c) 2012 Jera Design LLC. All rights reserved.
//

#import "CVFFlipsideViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "CVFImageProcessorDelegate.h"

@class CVFImageProcessor;

@interface CVFMainViewController : UIViewController <
    CVFFlipsideViewControllerDelegate,
    UIPopoverControllerDelegate,
    AVCaptureVideoDataOutputSampleBufferDelegate,
    CVFImageProcessorDelegate,
    UIWebViewDelegate
    >
{
    int CameraState;
}
@property (strong, nonatomic) UIPopoverController *flipsidePopoverController;
@property (weak, nonatomic) IBOutlet UIView *previewView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, atomic) CVFImageProcessor *imageProcessor;
@property (weak, nonatomic) IBOutlet UILabel *fpsLabel;
@property (weak, nonatomic) IBOutlet UIButton *flipCameraButton;
@property (weak, nonatomic) IBOutlet UIWebView *descriptionView;


- (IBAction)flipAction:(id)se;
- (IBAction)swipeUpAction:(id)sender;
- (IBAction)swipeDownAction:(id)sender;

@end
