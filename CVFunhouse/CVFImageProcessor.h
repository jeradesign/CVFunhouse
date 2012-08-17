//
//  CVFImageProcessor.h
//  CVFunhouse
//
//  Created by John Brewer on 3/7/12.
//  Copyright (c) 2012 Jera Design LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#include "opencv2/core/core_c.h"
#include "opencv2/imgproc/imgproc_c.h"

@protocol CVFImageProcessorDelegate;

@interface CVFImageProcessor : NSObject

@property (nonatomic, weak) id<CVFImageProcessorDelegate> delegate;
@property (nonatomic, readonly) NSString *demoDescription;

-(void)processImageBuffer:(CVImageBufferRef)imageBuffer withMirroring:(BOOL)shouldMirror;
-(void)imageReady:(IplImage*)image;
-(void)processIplImage:(IplImage*)iplImage;

@end
