//
//  DRBrowserInfo.h
//  DashRedirector
//
//  Created by Graham Haworth on 7/7/13.
//  Copyright (c) 2013 Graham Haworth. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface DRBrowserInfo : NSObject

+ (DRBrowserInfo*) browserInfoFromUrl:(NSURL*)browserAppUrl;
+ (DRBrowserInfo*) browserInfoFromUrl:(NSURL*)browserAppUrl loadAppIcon:(BOOL)loadIcon;
+ (DRBrowserInfo*) browserInfoFromBundle:(NSBundle*)browserBundle;
+ (DRBrowserInfo*) browserInfoFromBundle:(NSBundle*)browserBundle loadAppIcon:(BOOL)loadIcon;

#define PROPERTY(NAME, TYPE) @property(nonatomic, readonly) TYPE * NAME;
#include "DRBrowserInfo.inc"
#undef PROPERTY

@end
