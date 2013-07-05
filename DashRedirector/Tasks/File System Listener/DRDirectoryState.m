//
//  DRDirectoryState.m
//  DashRedirector
//
//  Created by Graham Haworth on 7/5/13.
//  Copyright (c) 2013 Graham Haworth. All rights reserved.
//

#import "DRDirectoryState.h"


@interface DRDirectoryState ()

@property (nonatomic, readwrite, copy) NSString *path;

@end


@implementation DRDirectoryState

@synthesize path;

+ (DRDirectoryState*) directoryStateFromPath:(NSString*)path {
#if DEBUG
	BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:path];
	NSAssert(exists, @"file at '%@' does not exist", path);
#endif
	
	DRDirectoryState *dirState = [[[DRDirectoryState alloc] init] autorelease];
	dirState.path = path;
	return dirState;
}

- (NSString*) pathToWatch {
	return self.path;
}

- (BOOL) doesEventIndicateChange:(DRFileSystemEvent)event {
	NSAssert([event.path isEqualToString:self.path], @"event path '%@' does not match directory path: '%@'",
			 event.path, self.path);
	
	return YES;
}

@end
