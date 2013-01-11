//
//  CVFImageProcessorDelegate.h
//  CVFunhouse
//
//  Created by John Brewer on 3/7/12.
//  Copyright (c) 2012 Jera Design LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CVFImageProcessor;

@protocol CVFImageProcessorDelegate <NSObject>

-(void)imageProcessor:(CVFImageProcessor*)imageProcessor didCreateImage:(UIImage*)image;
-(void)imageProcessor:(CVFImageProcessor*)imageProcessor didProvideData:(NSObject*)data;

@end
