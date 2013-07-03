//
//  DRDocsetIndexer.h
//  DashRedirector
//
//  Created by Graham Haworth on 7/1/13.
//  Copyright (c) 2013 Graham Haworth. All rights reserved.
//

#import <Foundation/Foundation.h>


@class DRTypeInfo;


@interface DRDocsetIndexer : NSObject

- (id) initWithWorkQueue:(NSOperationQueue*)workQueue;

- (void) index;
- (DRTypeInfo*) searchUrl:(NSURL*)url;

@end
