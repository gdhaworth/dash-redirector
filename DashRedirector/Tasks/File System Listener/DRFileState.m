//
//  DRFileState.m
//  DashRedirector
//
//  Created by Graham Haworth on 7/5/13.
//  Copyright (c) 2013 Graham Haworth. All rights reserved.
//

#import "DRFileState.h"


@interface DRFileState ()

@property (nonatomic, readwrite, copy) NSString *path;
@property (nonatomic, copy) NSDate *lastModified;

@end


@implementation DRFileState

@synthesize path, lastModified;

+ (DRFileState*) fileStateFromPath:(NSString*)path {
#if DEBUG
	BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:path];
	NSAssert(exists, @"file at '%@' does not exist", path);
#endif
	
	DRFileState *fileState = [[[DRFileState alloc] init] autorelease];
	fileState.path = path;
	fileState.lastModified = FileLastModified(path);
	return fileState;
}

- (NSString*) pathToWatch {
	return [self.path stringByDeletingLastPathComponent];
}

- (BOOL) doesEventIndicateChange:(DRFileSystemEvent)event {
	return [self.lastModified compare:FileLastModified(self.path)] == NSOrderedAscending;
}

NSDate* FileLastModified(NSString *path) {
	NSError *error = nil;
	NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:&error];
	if(error) {
		[NSException raise:kDROperationFailedException
					format:@"failed to read attributes of file '%@' with error %@", path, [error description]];
		return nil;
	}
	
	return [attrs objectForKey:NSFileModificationDate];
}

- (void) dealloc {
	self.path = nil;
	self.lastModified = nil;
	
	[super dealloc];
}

@end
