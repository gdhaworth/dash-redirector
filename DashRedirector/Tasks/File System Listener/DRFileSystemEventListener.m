//
//  DRFileSystemEventListener.m
//  DashRedirector
//
//  Created by Graham Haworth on 7/5/13.
//  Copyright (c) 2013 Graham Haworth. All rights reserved.
//

#import "DRFileSystemEventListener.h"
#import "DRDocsetDescriptor.h"
#import "DREventRunLoopThread.h"
#import "DRPathState.h"


@interface DRFileSystemEventListener () {
	DREventRunLoopThread *eventRunLoopThread;
	
	NSRecursiveLock *pathsLock;
	NSString *dashPreferencesPath;
	NSSet *docsetPaths;
}

@end


@implementation DRFileSystemEventListener

- (id) init {
	self = [super init];
	if(self) {
		eventRunLoopThread = [[DREventRunLoopThread alloc] init];
		[eventRunLoopThread start];
		
		pathsLock = [[NSRecursiveLock alloc] init];
	}
	return self;
}

- (void) setDashPreferencesPath:(NSString*)path {
	NSAssert(path, @"path was nil");
	
	[pathsLock lock];
	
	if([path isEqualToString:dashPreferencesPath])
		return;
	
	[dashPreferencesPath release];
	dashPreferencesPath = [path copy];
	
	[self pathsUpdated];
	
	[pathsLock unlock];
}

- (void) setDocsetDescriptors:(NSArray*)docsetDescriptors {
	NSMutableSet *newDocsetPaths = [NSMutableSet setWithCapacity:[docsetDescriptors count]];
	[docsetDescriptors each:^(DRDocsetDescriptor *docsetDescriptor) {
		[newDocsetPaths addObject:docsetDescriptor.basePath];
	}];
	
	[pathsLock lock];
	
	if([newDocsetPaths isEqualToSet:docsetPaths])
		return;
	
	[docsetPaths release];
	docsetPaths = [[NSSet alloc] initWithSet:newDocsetPaths];
	
	[self pathsUpdated];
	
	[pathsLock unlock];
}

- (void) pathsUpdated {
	NSString *dashPrefsPathRef = [dashPreferencesPath retain];
	NSSet *docsetPathsRef = [docsetPaths retain];
	
	NSSet *paths;
	if(docsetPathsRef) {
		paths = [NSMutableSet setWithSet:docsetPathsRef];
		[(NSMutableSet*)paths addObject:dashPrefsPathRef];
	} else
		paths = [NSSet setWithObject:dashPrefsPathRef];
	
	[eventRunLoopThread watchPaths:paths withEventCallback:^(DRFileSystemEvent event, id<DRPathState> pathState) {
		LOG_INFO(@"path updated: '%@'", pathState.path);
		
		// TODO
	} withReleaseCallback:^{
		[dashPrefsPathRef release];
		[docsetPathsRef release];
	}];
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
