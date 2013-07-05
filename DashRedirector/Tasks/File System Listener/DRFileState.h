//
//  DRFileState.h
//  DashRedirector
//
//  Created by Graham Haworth on 7/5/13.
//  Copyright (c) 2013 Graham Haworth. All rights reserved.
//

#import "DRPathState.h"

#import <Foundation/Foundation.h>


@interface DRFileState : NSObject <DRPathState>

+ (DRFileState*) fileStateFromPath:(NSString*)path;

- (NSString*) pathToWatch;
- (BOOL) doesEventIndicateChange:(DRFileSystemEvent)event;

@property (nonatomic, readonly) NSString *path;

@end
