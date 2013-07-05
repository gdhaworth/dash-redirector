//
//  DRPreferencesDelegate.m
//  DashRedirector
//
//  Created by Graham Haworth on 7/4/13.
//  Copyright (c) 2013 Graham Haworth. All rights reserved.
//

#import "DRPreferencesWindowController.h"
#import "DRAppDelegate.h"


@implementation DRPreferencesWindowController

- (id) init {
	return [super initWithWindowNibName:@"Preferences"];
}

- (void) awakeFromNib {
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(userDefaultsChanged:)
												 name:NSUserDefaultsDidChangeNotification
											   object:nil];
}

- (void) windowDidLoad {
	[super windowDidLoad];
	
	[self.window setExcludedFromWindowsMenu:YES];
}

- (void) userDefaultsChanged:(NSNotification*)notification {
	// TEMP
	LOG_INFO(@"notification: %@", [notification description]);
}

@end
