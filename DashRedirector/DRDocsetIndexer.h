//
//  DRDocsetIndexer.h
//  DashRedirector
//
//  Created by Graham Haworth on 7/1/13.
//  Copyright (c) 2013 Graham Haworth. All rights reserved.
//

#import <Foundation/Foundation.h>


@class DRTypeInfo;


typedef void(^DRReadDocsetDescriptorTaskCallback)(NSArray*);

@interface DRDocsetIndexer : NSObject

- (id) initWithWorkQueue:(NSOperationQueue*)workQueue;

- (BOOL) startIndex;
- (void) startOrQueueIndex;
- (void) reindexDocsets;

- (DRTypeInfo*) searchUrl:(NSURL*)url;

@end
