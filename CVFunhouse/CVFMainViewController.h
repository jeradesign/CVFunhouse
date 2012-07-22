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

@interface CVFMainViewController : UIViewController <UITableViewDataSource, UITableViewDelegate,CVFFlipsideViewControllerDelegate,
    UIPopoverControllerDelegate,
    AVCaptureVideoDataOutputSampleBufferDelegate,
    CVFImageProcessorDelegate>
{
    int CameraState;
}
@property (strong, nonatomic) UIPopoverController *flipsidePopoverController;
@property (weak, nonatomic) IBOutlet UIView *previewView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;





- (IBAction)flipAction:(id)se;

@end
