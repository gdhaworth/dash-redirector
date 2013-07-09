//
//  DRAppDelegate.m
//  DashRedirector
//
//  Created by Graham Haworth on 6/28/13.
//  Copyright (c) 2013 Graham Haworth. All rights reserved.
//

#import "DRAppDelegate.h"
#import "DRStatusItemDelegate.h"
#import "DRGetUrlListener.h"
#import "DRDocsetIndexer.h"
#import "DRPreferencesWindowController.h"
#import "DRBrowserInfoTasks.h"


@interface DRAppDelegate () {	
	DRGetUrlListener *getUrlListener;
}

@end


@implementation DRAppDelegate

@synthesize workQueue, docsetIndexer, preferencesWindowController;


#pragma mark - Application Lifecycle Callbacks

- (void) applicationWillFinishLaunching:(NSNotification *)notification {
	[getUrlListener registerAsEventHandler];
}

- (void) applicationDidFinishLaunching:(NSNotification *)notification {
	LOG_LINE();
	
	[docsetIndexer startIndex];
	
	if(DRDashRedirectorIsDefaultBrowser()) {
		[DRBrowserInfoTasks readDefaultBrowser:^(DRBrowserInfo *browserInfo) {
			DRBrowserInfo *currentApp = [DRBrowserInfoTasks currentApp];
			if(![currentApp isEqual:browserInfo]) {
				DRSetPersistedFallbackBrowser(browserInfo);
				[DRBrowserInfoTasks setSystemDefaultBrowser:currentApp];
			}
		}];
	}
		
}

- (void) applicationDidBecomeActive:(NSNotification*)notification {
	LOG_LINE();
	
	[getUrlListener applicationReadyToLaunchDashUrl];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
	LOG_LINE();
	
	if(DRDashRedirectorIsDefaultBrowser())
		[DRBrowserInfoTasks setSystemDefaultBrowser:DRPersistedFallbackBrowser()];
}


#pragma mark - Actions

- (IBAction) openPreferencesPanel:(id)sender {
	LOG_LINE();
	
	[self.preferencesWindowController showWindow:self];
	[NSApp activateIgnoringOtherApps:YES];
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
	
	self.preferencesWindowController = nil;
	
    [super dealloc];
}

@end
