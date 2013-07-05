//
//  DRPathState.h
//  DashRedirector
//
//  Created by Graham Haworth on 7/5/13.
//  Copyright (c) 2013 Graham Haworth. All rights reserved.
//

#import "DRFileSystemEvent.h"

#import <Foundation/Foundation.h>


@protocol DRPathState <NSObject>

- (NSString*) pathToWatch;
- (BOOL) doesEventIndicateChange:(DRFileSystemEvent)event;

@property (nonatomic, readonly) NSString *path;

@end
