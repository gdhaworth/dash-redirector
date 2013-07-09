//
//  DRPreferencesDelegate.m
//  DashRedirector
//
//  Created by Graham Haworth on 7/4/13.
//  Copyright (c) 2013 Graham Haworth. All rights reserved.
//

#import "DRPreferencesWindowController.h"
#import "DRBrowserInfoTasks.h"
#import "DRBrowserInfo.h"


@interface DRPreferencesWindowController () {
	BOOL registeredAsObserver;
	
	NSRect *originalWindowFrame;
	BOOL fallbackBrowserComponentsHidden;
	
	unsigned dashRedirectorDefaultBrowserHandleDispatchCount;
}

@property (nonatomic, readonly) BOOL dashRedirectorDefaultBrowser;
@property (nonatomic, assign) DRBrowserInfo *selectedDefaultBrowser;
@property (nonatomic, assign) DRBrowserInfo *persistedFallbackBrowser;

@end


@implementation DRPreferencesWindowController

@synthesize browsers, browserArrayController;
@synthesize lastComponentBeforeDefaultBrowserScrollView;
@synthesize dashIsDefaultCheckbox;
@synthesize defaultBrowserScrollView, defaultBrowserCollectionViewLabel;
@synthesize selectedBrowserIndexes;


#pragma mark -
#pragma mark Lifecycle Callbacks

- (id) init {
	self = [super initWithWindowNibName:@"Preferences"];
	if(self) {
		registeredAsObserver = NO;
		fallbackBrowserComponentsHidden = NO;
		
		dashRedirectorDefaultBrowserHandleDispatchCount = 0;
		self.browsers = [NSMutableArray array];
		self.selectedBrowserIndexes = [NSMutableIndexSet indexSet];
	}
	
	return self;
}

- (void) dealloc {
	self.browsers = nil;
	self.lastComponentBeforeDefaultBrowserScrollView = nil;
	self.browserArrayController = nil;
	self.defaultBrowserScrollView = nil;
	self.defaultBrowserCollectionViewLabel = nil;
	self.selectedBrowserIndexes = nil;
	
	if(originalWindowFrame)
		free(originalWindowFrame);
	
	[super dealloc];
}

- (void) awakeFromNib {
	[self registerObservations];
}

- (void) windowDidLoad {
	[super windowDidLoad];
	
	[self.window setExcludedFromWindowsMenu:YES];
	self.window.hidesOnDeactivate = NO;
	
	[DRBrowserInfoTasks readBrowsers:^(NSSet *browserInfos) {
		self.browsers = [NSMutableArray arrayWithArray:[browserInfos allObjects]];
		
		if(self.dashRedirectorDefaultBrowser)
			[self setSelectedDefaultBrowser:self.persistedFallbackBrowser];
	}];
	
	[self updateDefaultBrowserViewState:self.dashRedirectorDefaultBrowser animate:NO];
}

#pragma mark -
#pragma mark Observer Registration/Setup

- (void) registerObservations {
	if(registeredAsObserver)
		return;
	
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
															  forKeyPath:@"values.dashRedirectorIsDefaultBrowser"
																 options:NSKeyValueObservingOptionNew
																 context:@selector(handleDashRedirectorDefaultBrowserChange:)];
	[self addObserver:self
		   forKeyPath:@"selectedBrowserIndexes"
			  options:NSKeyValueObservingOptionNew
			  context:@selector(handleSelectedDefaultBrowserChange:)];
	
	registeredAsObserver = YES;
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	id newValue = [object valueForKeyPath:keyPath];
	SEL selector = (SEL)context;
	[self performSelector:selector withObject:newValue];
}


#pragma mark Observer Callbacks

- (void) handleDashRedirectorDefaultBrowserChange:(CFBooleanRef)newValue {
	Boolean drIsDefault = CFBooleanGetValue((CFBooleanRef) newValue);
	
	unsigned dispatchCount = ++dashRedirectorDefaultBrowserHandleDispatchCount;
	LOG_TRACE(@"dispatchCount: %d", dispatchCount);
	[DRBrowserInfoTasks readDefaultBrowser:^(DRBrowserInfo *browserInfo) {
		LOG_DEBUG(@"current default system browser: %@", browserInfo);
		
		if(dispatchCount != dashRedirectorDefaultBrowserHandleDispatchCount) {
			LOG_DEBUG(@"dashRedirectorDefaultBrowser change handler is stale (%d), skipping execution",
					  dashRedirectorDefaultBrowserHandleDispatchCount);
			return;
		}
		
		if(drIsDefault) {
			if(![DRBrowserInfoTasks isCurrentApp:browserInfo]) {
				self.persistedFallbackBrowser = browserInfo;
				[DRBrowserInfoTasks setSystemDefaultBrowser:[DRBrowserInfoTasks currentApp]];
			}
		} else if([DRBrowserInfoTasks isCurrentApp:browserInfo])
			[DRBrowserInfoTasks setSystemDefaultBrowser:self.persistedFallbackBrowser];
		
		[self updateDefaultBrowserViewState:drIsDefault animate:YES];
	}];
}

- (void) handleSelectedDefaultBrowserChange:(id)newValue {
	DRBrowserInfo *selectedDefaultBrowser = self.selectedDefaultBrowser;
	
	LOG_TRACE(@"selectedBrowser: %@", selectedDefaultBrowser);
	
	if(!selectedDefaultBrowser)
		return;
	
	self.persistedFallbackBrowser = selectedDefaultBrowser;
}


#pragma mark - View Controlling Methods

- (void) updateDefaultBrowserViewState:(BOOL)drIsDefault animate:(BOOL)animate {
	LOG_TRACE(@"dash redirector is default: %d", drIsDefault);
	
	if(!originalWindowFrame) {
		originalWindowFrame = malloc(sizeof(NSRect));
		*originalWindowFrame = self.window.frame;
	}
	
	if(animate) {
		if(drIsDefault)
			[self animateShowFallbackBrowserComponents];
		else
			[self animateHideFallbackBrowserComponents];
	} else if(!drIsDefault)
		[self hideFallbackBrowserComponents];
}

- (void) animateShowFallbackBrowserComponents {
	if(!fallbackBrowserComponentsHidden)
		return;
	
	[self.dashIsDefaultCheckbox setEnabled:NO];
	[self.defaultBrowserScrollView setHidden:NO];
	[self.defaultBrowserCollectionViewLabel setHidden:NO];
	fallbackBrowserComponentsHidden = NO;
	
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
		[self.window.animator setFrame:*originalWindowFrame display:NO];
		[self.defaultBrowserScrollView.animator setAlphaValue:1.0f];
		[self.defaultBrowserCollectionViewLabel.animator setAlphaValue:1.0f];
	} completionHandler:^{
		[self.dashIsDefaultCheckbox setEnabled:YES];
	}];
}

- (void) animateHideFallbackBrowserComponents {
	if(fallbackBrowserComponentsHidden)
		return;
	
	[self.dashIsDefaultCheckbox setEnabled:NO];
	fallbackBrowserComponentsHidden = YES;
	
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
		[self.window.animator setFrame:[self calculateWindowFrameForHiddenFallbackBrowserComponents] display:NO];
		[self.defaultBrowserScrollView.animator setAlphaValue:0.0f];
		[self.defaultBrowserCollectionViewLabel.animator setAlphaValue:0.0f];
	} completionHandler:^{
		[self.dashIsDefaultCheckbox setEnabled:YES];
		[self.defaultBrowserScrollView setHidden:YES];
		[self.defaultBrowserCollectionViewLabel setHidden:YES];
	}];
}

- (void) hideFallbackBrowserComponents {
	fallbackBrowserComponentsHidden = YES;
	
	[self.window setFrame:[self calculateWindowFrameForHiddenFallbackBrowserComponents] display:YES];
	[self.defaultBrowserScrollView setHidden:YES];
	[self.defaultBrowserCollectionViewLabel setHidden:YES];
}

- (NSRect) calculateWindowFrameForHiddenFallbackBrowserComponents {
	NSRect windowFrame = self.window.frame;
	
	NSRect scrollFrame = self.defaultBrowserScrollView.frame;
	NSRect lastFrame = self.lastComponentBeforeDefaultBrowserScrollView.frame;
	
	CGFloat shrink = lastFrame.origin.y - scrollFrame.origin.y;
	NSRect newWindowFrame = {
		{ windowFrame.origin.x, windowFrame.origin.y + shrink },
		{ windowFrame.size.width, windowFrame.size.height - shrink } };
	return newWindowFrame;
}


#pragma mark - Property Accessors/KVC Compliance

- (void) insertObject:(DRBrowserInfo *)browser inBrowsersAtIndex:(NSUInteger)index {
    [browsers insertObject:browser atIndex:index];
}

- (void) removeObjectFromBrowsersAtIndex:(NSUInteger)index {
    [browsers removeObjectAtIndex:index];
}

- (BOOL) dashRedirectorDefaultBrowser {
	return DRDashRedirectorIsDefaultBrowser();
}

- (DRBrowserInfo*) selectedDefaultBrowser {
	NSArray *selectedObjects = [self.browserArrayController selectedObjects];
	if([selectedObjects count] == 0)
		return nil;
	return [selectedObjects objectAtIndex:0];
}

- (void) setSelectedDefaultBrowser:(DRBrowserInfo *)browser {
	LOG_DEBUG(@"new selectedDefaultBrowser: %@", browser);
	
	[self.browserArrayController setSelectedObjects:[NSArray arrayWithObject:browser]];
}

- (DRBrowserInfo*) persistedFallbackBrowser {
	return DRPersistedFallbackBrowser();
}

- (void) setPersistedFallbackBrowser:(DRBrowserInfo *)browser {
	LOG_DEBUG(@"new persistedFallbackBrowser: %@", browser);
	DRSetPersistedFallbackBrowser(browser);
}

@end
