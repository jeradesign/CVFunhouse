//
//  CVFMainViewController.m
//  CVFunhouse
//
//  Created by John Brewer on 3/7/12.
//  Copyright (c) 2012 Jera Design LLC. All rights reserved.
//

#import "CVFMainViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "CVFFlipsideViewController.h"

#import "CVFCannyDemo.h"
#import "CVFFaceDetect.h"
#import "CVFFarneback.h"
#import "CVFLaplace.h"
#import "CVFLucasKanade.h"
#import "CVFMotionTemplates.h"

#import "CVFSephiaDemo.h"
#import "CVFPassThru.h"

@implementation CVFMainViewController {
    AVCaptureDevice *_cameraDevice;
    AVCaptureSession *_session;
    AVCaptureVideoPreviewLayer *_previewLayer;
    CVFImageProcessor *_imageProcessor;
    NSDate *_lastFrameTime;
    CGPoint _descriptionOffScreenCenter;
    CGPoint _descriptionOnScreenCenter;
    bool _useBackCamera;
    NSArray *_demoList;
    UIImage *_snapshotImage; // In case we need to hang onto it for ARC
    ALAssetsLibrary *_library;
}

@synthesize fpsLabel = _fpsLabel;
@synthesize flipCameraButton = _flipCameraButton;
@synthesize descriptionView = _descriptionView;
@synthesize flipsidePopoverController = _flipsidePopoverController;
@synthesize imageView = _imageView;
//@synthesize imageProcessor = _imageProcessor;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString *demoListPath = [[NSBundle mainBundle] pathForResource:@"Demos" ofType:@"plist"];
    _demoList = [NSArray arrayWithContentsOfFile:demoListPath];

    [self showHideFPS];
    [self initializeDescription];
    [self resetImageProcessor];
    _useBackCamera = [[NSUserDefaults standardUserDefaults] boolForKey:@"useBackCamera"];
    [self setupCamera];
    [self turnCameraOn];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(resetImageProcessor)
                                                 name:@"demoNumber"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(showHideFPS)
                                                 name:@"showFPS"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(showHideDescription)
                                                 name:@"showDescription"
                                               object:nil];
    
    _library = [[ALAssetsLibrary alloc] init];
}

- (void)viewDidAppear:(BOOL)animated {
#pragma unused(animated)
    bool showDescription = [[NSUserDefaults standardUserDefaults] boolForKey:@"showDescription"];
    if (showDescription) {
        double delayInSeconds = 1.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self.descriptionView.scrollView flashScrollIndicators];
        });
    }
}

- (void)resetImageProcessor {
    NSInteger demoNumber = [[NSUserDefaults standardUserDefaults] integerForKey:@"demoNumber"];
    if (demoNumber >= (int)_demoList.count) {
        demoNumber = _demoList.count - 1; // Force to last demo.
    }

    NSArray *demoInfo = _demoList[demoNumber];
    NSString *className = demoInfo[1];
    Class class = NSClassFromString(className);
    self.imageProcessor = [[class alloc] init];
    
    NSURL *descriptionUrl = [[NSBundle mainBundle] URLForResource:className withExtension:@"html"];
    if (descriptionUrl == nil) {
        descriptionUrl = [[NSBundle mainBundle] URLForResource:@"NoDescription"
                                                 withExtension:@"html"];
    }
    NSURLRequest *request = [NSURLRequest requestWithURL:descriptionUrl];
    [self.descriptionView loadRequest:request];
}

- (void)showHideFPS {
    bool showFPS = [[NSUserDefaults standardUserDefaults] boolForKey:@"showFPS"];
    [self.fpsLabel setHidden:!showFPS];
}

- (void)initializeDescription {
    self.descriptionContainer.layer.borderColor = [UIColor blackColor].CGColor;
    self.descriptionContainer.layer.borderWidth = 1.0;
    
    _descriptionOnScreenCenter = self.descriptionContainer.center;
    _descriptionOffScreenCenter = self.descriptionContainer.center;
    int descriptionTopY = self.descriptionContainer.center.y -
    self.descriptionContainer.bounds.size.height / 2;
    _descriptionOffScreenCenter.y += self.view.bounds.size.height - descriptionTopY;

    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"showDescription"] == nil) {
        [[NSUserDefaults standardUserDefaults] setBool:true forKey:@"showDescription"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    bool showDescription = [[NSUserDefaults standardUserDefaults] boolForKey:@"showDescription"];
    self.descriptionContainer.hidden = !showDescription;
    if (showDescription) {
        double delayInSeconds = 2.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self.descriptionView.scrollView flashScrollIndicators];
        });
    }
}

- (void)showHideDescription {
    bool showDescription = [[NSUserDefaults standardUserDefaults] boolForKey:@"showDescription"];
    if (showDescription && self.descriptionContainer.isHidden) {
        self.descriptionContainer.center = _descriptionOffScreenCenter;
        [self.descriptionContainer setHidden:false];
        [UIView animateWithDuration:0.5 animations:^{
            self.descriptionContainer.center = _descriptionOnScreenCenter;
        } completion:^(BOOL finished) {
#pragma unused(finished)
            [self.descriptionView.scrollView flashScrollIndicators];
        }];
    } else if (!showDescription && !self.descriptionContainer.isHidden) {
        [UIView animateWithDuration:0.5 animations:^{
            self.descriptionContainer.center = _descriptionOffScreenCenter;
        } completion:^(BOOL finished) {
#pragma unused(finished)
            self.descriptionContainer.hidden = true;
        }];
    }
}

- (void)setImageProcessor:(CVFImageProcessor *)imageProcessor
{
    if (_imageProcessor != imageProcessor) {
        _imageProcessor.delegate = nil;
        _imageProcessor = imageProcessor;
        _imageProcessor.delegate = self;
    }
}

- (CVFImageProcessor *)imageProcessor {
    return _imageProcessor;
}


- (void)viewDidUnload
{
    [self turnCameraOff];
    [self setImageView:nil];
    [self setFpsLabel:nil];
    [self setFlipCameraButton:nil];
    [self setDescriptionView:nil];
    [self setDescriptionContainer:nil];
    [self setArView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Flipside View Controller

- (void)flipsideViewControllerDidFinish:(CVFFlipsideViewController *)controller
{
#pragma unused(controller)
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        [self dismissModalViewControllerAnimated:YES];
    } else {
        [self.flipsidePopoverController dismissPopoverAnimated:YES];
        self.flipsidePopoverController = nil;
    }
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
#pragma unused(popoverController)
    self.flipsidePopoverController = nil;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
#pragma unused(sender)
    if ([[segue identifier] isEqualToString:@"showAlternate"]) {
        [[segue destinationViewController] setDelegate:self];
        if ([segue.destinationViewController respondsToSelector:@selector(setDemoList:)]) {
            [segue.destinationViewController performSelector:@selector(setDemoList:)
                                                  withObject:_demoList];
        }

        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            UIPopoverController *popoverController = [(UIStoryboardPopoverSegue *)segue popoverController];
            self.flipsidePopoverController = popoverController;
            popoverController.delegate = self;
        }
    }
}

#pragma mark - UIWebViewDelegate methods

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request
 navigationType:(UIWebViewNavigationType)navigationType
{
#pragma unused(webView)
#pragma unused(navigationType)

    NSURL *url = [request URL];
    if ([[url scheme] isEqual: @"about"]) {
        return YES;
    }
    if ([[url scheme] isEqual:@"file"]) {
        return YES;
    }

    [[UIApplication sharedApplication] openURL:url];
    return NO;
}

#pragma mark - IBAction methods

- (IBAction)flipAction:(id)sender
{
#pragma unused(sender)
    _useBackCamera = !_useBackCamera;
    [[NSUserDefaults standardUserDefaults] setBool:_useBackCamera forKey:@"useBackCamera"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self turnCameraOff];
    [self setupCamera];
    [self turnCameraOn];
}

- (IBAction)togglePopover:(id)sender
{
    if (self.flipsidePopoverController) {
        [self.flipsidePopoverController dismissPopoverAnimated:YES];
        self.flipsidePopoverController = nil;
    } else {
        [self performSegueWithIdentifier:@"showAlternate" sender:sender];
    }
}

- (IBAction)swipeUpAction:(id)sender {
#pragma unused(sender)
    [[NSUserDefaults standardUserDefaults] setBool:true forKey:@"showDescription"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"showDescription" object:nil];
}

- (IBAction)swipeDownAction:(id)sender {
#pragma unused(sender)
    [[NSUserDefaults standardUserDefaults] setBool:false forKey:@"showDescription"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"showDescription" object:nil];
}

- (IBAction)closeDescription:(id)sender {
#pragma unused(sender)
    [[NSUserDefaults standardUserDefaults] setBool:false forKey:@"showDescription"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"showDescription" object:nil];
}

- (IBAction)takeSnapshot:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        _snapshotImage = self.imageView.image;
        NSLog(@"_snapshotImage = %@", _snapshotImage);
        NSLog(@"CGImage = %@", _snapshotImage.CGImage);
        [_library writeImageToSavedPhotosAlbum:_snapshotImage.CGImage orientation:ALAssetOrientationUp completionBlock:^(NSURL *assetURL, NSError *error) {
            NSLog(@"assetURL = %@, error = %@", assetURL, error);
            _snapshotImage = nil;
        }];
        //    UIImageWriteToSavedPhotosAlbum(_snapshotImage,
        //                                   self,
        //                                   @selector(image:didFinishSavingWithError:contextInfo:),
        //                                   nil);
    }
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    (void)image;
    (void)contextInfo;
    NSLog(@"image:%@ didFinishSavingWithError:%@", image, error);
    _snapshotImage = nil;
}

#pragma mark - CVFImageProcessorDelegate

-(void)imageProcessor:(CVFImageProcessor*)imageProcessor didCreateImage:(UIImage*)image
{
#pragma unused(imageProcessor)
//    NSLog(@"Image Received");
    [self.imageView setImage:image];
    NSDate *now = [NSDate date];
    NSTimeInterval frameDelay = [now timeIntervalSinceDate:_lastFrameTime];
    double fps = 1.0/frameDelay;
    if (fps != fps) {
        self.fpsLabel.text = @"";
    } else {
        self.fpsLabel.text = [NSString stringWithFormat:@"%05.2f FPS", fps];
    }
    _lastFrameTime = now;
}

#pragma mark - Camera support

- (void)setupCamera {
    _cameraDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSArray *devices = [AVCaptureDevice devices];
    if (devices.count == 1) {
        
    }
    for (AVCaptureDevice *device in devices) {
        if (device.position == AVCaptureDevicePositionFront && !_useBackCamera) {
            
            _cameraDevice = device;
            break;
        }
        if (device.position == AVCaptureDevicePositionBack && _useBackCamera) {
            
            _cameraDevice = device;
            break;
        }
    }
}

- (void)turnCameraOn {
    NSError *error;
    _session = [[AVCaptureSession alloc] init];
    [_session beginConfiguration];
    [_session setSessionPreset:AVCaptureSessionPresetMedium];
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:_cameraDevice
                                                                        error:&error];
    if (input == nil) {
        NSLog(@"%@", error);
    }
    
    [_session addInput:input];
    
    // Create a VideoDataOutput and add it to the session
    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
    [_session addOutput:output];
    
    // Configure your output.
    dispatch_queue_t queue = dispatch_queue_create("myQueue", NULL);
    [output setSampleBufferDelegate:self queue:queue];
    dispatch_release(queue);
    
    // Specify the pixel format
    output.videoSettings = 
    @{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)};
    output.alwaysDiscardsLateVideoFrames = YES;
    //kCVPixelFormatType_32BGRA
    
//    _previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:_session];
//    _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
//    AVCaptureVideoOrientation orientation = AVCaptureVideoOrientationLandscapeRight;
//    [_previewLayer setOrientation:orientation];
//    _previewLayer.frame = self.previewView.bounds;
//    [self.previewView.layer addSublayer:_previewLayer];
    
    // Start the session running to start the flow of data
    [_session commitConfiguration];
    [_session startRunning];
}

- (void)turnCameraOff {
    [_previewLayer removeFromSuperlayer];
    _previewLayer = nil;
    [_session stopRunning];
    _session = nil;
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    @autoreleasepool {
#pragma unused(captureOutput)
#pragma unused(connection)
        // Get a CMSampleBuffer's Core Video image buffer for the media data
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        
        [self.imageProcessor processImageBuffer:imageBuffer
                                  withMirroring:(_cameraDevice.position ==
                                                 AVCaptureDevicePositionFront)];
    }
}

@end
