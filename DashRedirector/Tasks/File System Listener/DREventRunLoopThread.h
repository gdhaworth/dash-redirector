//
//  DREventRunLoopThread.h
//  DashRedirector
//
//  Created by Graham Haworth on 7/5/13.
//  Copyright (c) 2013 Graham Haworth. All rights reserved.
//

#import "DRFileSystemEvent.h"

#import <Foundation/Foundation.h>


@protocol DRPathState;

typedef void(^DRFileSystemEventCallback)(DRFileSystemEvent, id<DRPathState>);
typedef void(^DRReleaseCallback)(void);


@class DRFileSystemEventListener;

@interface DREventRunLoopThread : NSThread

- (void) watchPaths:(NSSet*)paths
  withEventCallback:(DRFileSystemEventCallback)eventCallback
withReleaseCallback:(DRReleaseCallback)releaseCallback;

@end
