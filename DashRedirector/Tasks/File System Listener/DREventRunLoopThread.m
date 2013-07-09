//
//  DREventRunLoopThread.m
//  DashRedirector
//
//  Created by Graham Haworth on 7/5/13.
//  Copyright (c) 2013 Graham Haworth. All rights reserved.
//

#import "DREventRunLoopThread.h"
#import "DRFileSystemEventListener.h"
#import "DRFileState.h"
#import "DRDirectoryState.h"


#define kDRFSEventLatency 1.0
#define kDRFSEventRunLoopInterval 5.0


typedef struct {
	NSDictionary *parentDirsToPaths;
	int32_t watchedVersion;
	DRFileSystemEventCallback callback;
} DRWatchedPathData;


@interface DREventRunLoopThread () {
	NSSet *watchedPaths;
	volatile int32_t watchedPathsVersion;
	DRFileSystemEventCallback eventCallback;
	DRReleaseCallback releaseCallback;
	
	NSCondition *runCondition;
}

@end


@implementation DREventRunLoopThread

- (id) init {
	self = [super init];
	if(self) {
		runCondition = [[NSCondition alloc] init];
		
		watchedPathsVersion = INT32_MIN;
	}
	return self;
}

- (void) watchPaths:(NSSet*)paths
  withEventCallback:(DRFileSystemEventCallback)event
withReleaseCallback:(DRReleaseCallback)release {
	
	[runCondition lock];
	
	if(releaseCallback)
		releaseCallback();
	[watchedPaths release];
	watchedPaths = [paths copy];
	[eventCallback release];
	eventCallback = [event copy];
	[releaseCallback release];
	releaseCallback = [release copy];
	OSAtomicIncrement32Barrier(&watchedPathsVersion);
	
	[runCondition signal];
	[runCondition unlock];
}

- (void) main {
	do {
		[runCondition lock];
		
		while([watchedPaths count] < 1)
			[runCondition wait];
		
		DRWatchedPathData watchedPathData;
		watchedPathData.parentDirsToPaths = PathStateDictionary(watchedPaths);
		watchedPathData.callback = [eventCallback retain];
		watchedPathData.watchedVersion = watchedPathsVersion;
		[runCondition unlock];
		
		
		[self createEventStreamAndListen:&watchedPathData];
		
		[watchedPathData.callback release];
	} while(true);
}

NSDictionary* PathStateDictionary(NSSet *fullPaths) {
	NSMutableDictionary *parentDirsToPaths = [NSMutableDictionary dictionaryWithCapacity:[fullPaths count]];
	[fullPaths each:^(id path) {
		id<DRPathState> pathState = PathState(path);
		if(!pathState)
			return;
		
		NSString *pathToWatch = [[pathState pathToWatch] stringByStandardizingPath];
		NSMutableArray *children = [parentDirsToPaths objectForKey:pathToWatch];
		if(!children) {
			children = [NSMutableArray array];
			[parentDirsToPaths setObject:children forKey:pathToWatch];
		}
		[children addObject:pathState];
	}];
	return parentDirsToPaths;
}

id<DRPathState> PathState(NSString *path) {
	path = [path stringByStandardizingPath];
	
	BOOL directory = false;
	BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&directory];
	if(!exists)
		return nil;
	
	return directory ? [DRDirectoryState directoryStateFromPath:path] : [DRFileState fileStateFromPath:path];
}

- (void) createEventStreamAndListen:(DRWatchedPathData*)watchedPathData {
	FSEventStreamRef stream = CreateEventFileStream(watchedPathData);
	FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
	FSEventStreamStart(stream);
	
	[self doRunLoop:watchedPathData];
	
	FSEventStreamStop(stream);
	FSEventStreamInvalidate(stream);
	FSEventStreamRelease(stream);
}

FSEventStreamRef CreateEventFileStream(DRWatchedPathData *watchedPathData) {
	FSEventStreamContext context = { 0, watchedPathData, NULL, NULL, NULL };
	return FSEventStreamCreate(NULL, &FileSystemEventCallback, &context,
							   (CFArrayRef) [watchedPathData->parentDirsToPaths allKeys], kFSEventStreamEventIdSinceNow,
							   kDRFSEventLatency, kFSEventStreamCreateFlagUseCFTypes);
}

- (void) doRunLoop:(DRWatchedPathData*)watchedPathData {
	while(watchedPathData->watchedVersion == watchedPathsVersion)
		CFRunLoopRunInMode(kCFRunLoopDefaultMode, kDRFSEventRunLoopInterval, false);
}

void FileSystemEventCallback(ConstFSEventStreamRef streamRef, void *callbackInfo, size_t numEvents,
							 void *eventPathsArray, const FSEventStreamEventFlags eventFlags[],
							 const FSEventStreamEventId eventIds[]) {
	
	DRWatchedPathData *watchedPathData = (DRWatchedPathData*) callbackInfo;
	NSArray *eventPaths = (NSArray*) eventPathsArray;
	for(unsigned i = 0; i < numEvents; i++) {
		DRFileSystemEvent event = { [eventPaths[i] stringByStandardizingPath], eventFlags[i], eventIds[i] };
		NSArray *childStates = [watchedPathData->parentDirsToPaths objectForKey:event.path];
		[childStates each:^(id<DRPathState> childPathState) {
			if([childPathState doesEventIndicateChange:event])
				watchedPathData->callback(event, childPathState);
		}];
	}
}

- (void) dealloc {
	[runCondition release];
	[watchedPaths release];
	[eventCallback release];
	
	if(releaseCallback)
		releaseCallback();
	[releaseCallback release];
	
	[super dealloc];
}

@end
