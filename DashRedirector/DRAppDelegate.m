//
//  DRAppDelegate.m
//  DashRedirector
//
//  Created by Graham Haworth on 6/28/13.
//  Copyright (c) 2013 Graham Haworth. All rights reserved.
//

#import "DRAppDelegate.h"
#import "DRGetUrlListener.h"
#import "DRDocsetIndexer.h"
#import "DRTypeInfo.h"
#import "DRMemberInfo.h"


@interface DRAppDelegate () {
	DRGetUrlListener *getUrlListener;
}

@end


@implementation DRAppDelegate

@synthesize workQueue, docsetIndexer;


#pragma mark - Application Lifecycle Callbacks

- (void) applicationWillFinishLaunching:(NSNotification *)notification {
	[getUrlListener registerAsEventHandler];
}

- (void) applicationDidFinishLaunching:(NSNotification *)aNotification {
	LOG_LINE();
	
#warning TODO: consider moving to applicationWillFinishLaunching so this always exists
	[docsetIndexer index];
}


#pragma mark - Instance Lifecycle

- (id) init {
	self = [super init];
	if(self) {
		workQueue = [[NSOperationQueue alloc] init];
		docsetIndexer = [[DRDocsetIndexer alloc] initWithWorkQueue:workQueue];
		getUrlListener = [[DRGetUrlListener alloc] initWithDocsetIndexer:self.docsetIndexer];
	}
	return self;
}

- (void) dealloc {
	[workQueue release];
	[docsetIndexer release];
	[getUrlListener release];
	
    [super dealloc];
}

@end
