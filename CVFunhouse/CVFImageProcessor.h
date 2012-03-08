//
//  CVFImageProcessor.h
//  CVFunhouse
//
//  Created by John Brewer on 3/7/12.
//  Copyright (c) 2012 Jera Design LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CVFImageProcessorDelegate;

@interface CVFImageProcessor : NSObject

@property (nonatomic, weak) id<CVFImageProcessorDelegate> delegate;

-(void)processImageBuffer:(CVImageBufferRef)imageBuffer;

@end
