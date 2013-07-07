//
//  DRFileSystemEventListener.m
//  DashRedirector
//
//  Created by Graham Haworth on 7/5/13.
//  Copyright (c) 2013 Graham Haworth. All rights reserved.
//

#import "DRFileSystemEventListener.h"
#import "DRDocsetIndexer.h"
#import "DRDocsetDescriptor.h"
#import "DREventRunLoopThread.h"
#import "DRPathState.h"


@interface DRFileSystemEventListener () {
	DREventRunLoopThread *eventRunLoopThread;
	
	NSString *dashPreferencesPath;
	NSSet *docsetPaths;
	NSObject *pathsLock;
}

@property (nonatomic, readonly) DRDocsetIndexer *docsetIndexer;

@end


@implementation DRFileSystemEventListener

@synthesize docsetIndexer;

- (id) initWithDocsetIndexer:(DRDocsetIndexer*)indexer {
	self = [super init];
	if(self) {
		docsetIndexer = indexer;
		
		eventRunLoopThread = [[DREventRunLoopThread alloc] init];
		[eventRunLoopThread start];
		
		pathsLock = [[NSObject alloc] init];
	}
	return self;
}

- (void) setDashPreferencesPath:(NSString*)path {
	NSAssert(path, @"path was nil");
	
	path = [path stringByStandardizingPath];
	
	@synchronized(pathsLock) {
		if([path isEqualToString:dashPreferencesPath])
			return;
		
		[dashPreferencesPath release];
		dashPreferencesPath = [path copy];
	}
	
	[self pathsChanged];
}

- (void) setDocsetDescriptors:(NSSet*)descriptors {
	NSSet *newDocsetPaths = [descriptors map:^NSString*(DRDocsetDescriptor *docsetDescriptor) {
		return docsetDescriptor.basePath;
	}];
	
	@synchronized(pathsLock) {
		if([newDocsetPaths isEqualToSet:docsetPaths])
			return;
		
		[docsetPaths release];
		docsetPaths = [[NSSet alloc] initWithSet:newDocsetPaths];
	}
	
	[self pathsChanged];
}

- (void) pathsChanged {
	NSString *dashPrefsPathRef;
	NSSet *docsetPathsRef;
	@synchronized(pathsLock) {
		dashPrefsPathRef = [dashPreferencesPath retain];
		docsetPathsRef = [docsetPaths retain];
	}
	
	NSSet *paths;
	if(docsetPathsRef) {
		paths = [NSMutableSet setWithSet:docsetPathsRef];
		[(NSMutableSet*)paths addObject:dashPrefsPathRef];
	} else
		paths = [NSSet setWithObject:dashPrefsPathRef];
	
	[eventRunLoopThread watchPaths:paths withEventCallback:^(DRFileSystemEvent event, id<DRPathState> pathState) {
		LOG_DEBUG(@"path updated: '%@'", pathState.path);
		
		if([pathState.path isEqualToString:dashPrefsPathRef])
			[self.docsetIndexer startOrQueueIndex];
		else
			[self.docsetIndexer reindexDocsets];
	} withReleaseCallback:^{
		[dashPrefsPathRef release];
		[docsetPathsRef release];
	}];
}

- (id) init {
	[NSException raise:kDRUnsupportedOperationException format:@"use initWithDocsetIndexer:"];
	return nil;
}

- (void) dealloc {
#warning TODO: stop thread if necessary
	[eventRunLoopThread release];
	[pathsLock release];
	[dashPreferencesPath release];
	[docsetPaths release];
	
	[super dealloc];
}

@end
