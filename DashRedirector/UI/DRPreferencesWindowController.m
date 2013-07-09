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


#define kDRDashRedirectorDefaultBrowser @"dashRedirectorDefaultBrowser"
#define kDRFallbackBrowser @"fallbackBrowser"


@interface DRPreferencesWindowController () {
	unsigned dashRedirectorDefaultBrowserHandleDispatchCount;
}

@property (nonatomic, readonly) BOOL dashRedirectorDefaultBrowser;
@property (nonatomic, assign) DRBrowserInfo *selectedDefaultBrowser;
@property (nonatomic, assign) DRBrowserInfo *persistedFallbackBrowser;

@end


@implementation DRPreferencesWindowController

@synthesize browsers, browserArrayController;
@synthesize defaultBrowserCollectionView, defaultBrowserScrollView, defaultBrowserClipView, defaultBrowserCollectionViewLabel;
@synthesize selectedBrowserIndexes;

- (id) init {
	self = [super initWithWindowNibName:@"Preferences"];
	if(self) {
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
																  forKeyPath:@"values.dashRedirectorDefaultBrowser"
																	 options:NSKeyValueObservingOptionNew
																	 context:@selector(handleDashRedirectorDefaultBrowserChange:)];
		[self addObserver:self
			   forKeyPath:@"selectedBrowserIndexes"
				  options:NSKeyValueObservingOptionNew
				  context:@selector(handleSelectedDefaultBrowserChange:)];
		
		dashRedirectorDefaultBrowserHandleDispatchCount = 0;
		self.browsers = [NSMutableArray array];
		self.selectedBrowserIndexes = [NSMutableIndexSet indexSet];
	}
	
	return self;
}

- (void) awakeFromNib {
	[self setUpLockableClipView];
}

// TODO move into LockableClipView
- (void) setUpLockableClipView {
	if(self.defaultBrowserClipView == self.defaultBrowserScrollView.contentView)
		return;
	
	self.defaultBrowserClipView.documentView = self.defaultBrowserScrollView.contentView.documentView;
	self.defaultBrowserClipView.copiesOnScroll = self.defaultBrowserScrollView.contentView.copiesOnScroll;
	self.defaultBrowserClipView.documentCursor = self.defaultBrowserScrollView.contentView.documentCursor;
	self.defaultBrowserClipView.drawsBackground = self.defaultBrowserScrollView.contentView.drawsBackground;
	self.defaultBrowserScrollView.contentView = self.defaultBrowserClipView;
}

- (void) windowDidLoad {
	[super windowDidLoad];
	
	[self.window setExcludedFromWindowsMenu:YES];
	self.window.hidesOnDeactivate = NO;
	[(NSPanel*)self.window setFloatingPanel:YES];
	
	[DRBrowserInfoTasks readBrowsers:^(NSSet *browserInfos) {
		self.browsers = [NSMutableArray arrayWithArray:[browserInfos allObjects]];
		
		[self updateDefaultBrowserViewState:self.dashRedirectorDefaultBrowser];
	}];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	id newValue = [object valueForKeyPath:keyPath];
	SEL selector = (SEL)context;
	[self performSelector:selector withObject:newValue];
}

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
			
			[self updateDefaultBrowserViewState:drIsDefault];
		} else {
			if([DRBrowserInfoTasks isCurrentApp:browserInfo])
				[DRBrowserInfoTasks setSystemDefaultBrowser:self.persistedFallbackBrowser];
			
			[self updateDefaultBrowserViewState:drIsDefault];
		}
	}];
}

- (void) handleSelectedDefaultBrowserChange:(id)newValue {
	DRBrowserInfo *selectedDefaultBrowser = self.selectedDefaultBrowser;
	
	// TEMP
	LOG_DEBUG(@"selectedBrowser: %@", selectedDefaultBrowser);
	
	if(!selectedDefaultBrowser)
		return;
	
	self.persistedFallbackBrowser = selectedDefaultBrowser;
}

- (void) updateDefaultBrowserViewState:(BOOL)drIsDefault {
	[self.defaultBrowserCollectionView setSelectable:drIsDefault];
	if(drIsDefault)
		self.selectedDefaultBrowser = self.persistedFallbackBrowser;
	
	[self.defaultBrowserScrollView.verticalScroller setEnabled:drIsDefault];
	
	self.defaultBrowserClipView.scrollLocked = !drIsDefault;
	self.defaultBrowserCollectionViewLabel.textColor =
			drIsDefault ? [NSColor controlTextColor] : [NSColor disabledControlTextColor];
}

- (void) insertObject:(DRBrowserInfo *)browser inBrowsersAtIndex:(NSUInteger)index {
    [browsers insertObject:browser atIndex:index];
}

- (void) removeObjectFromBrowsersAtIndex:(NSUInteger)index {
    [browsers removeObjectAtIndex:index];
}

- (BOOL) dashRedirectorDefaultBrowser {
	return [[NSUserDefaults standardUserDefaults] boolForKey:kDRDashRedirectorDefaultBrowser];
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
	NSURL *browserUrl = [NSURL URLWithString:[[NSUserDefaults standardUserDefaults] objectForKey:kDRFallbackBrowser]];
	return [DRBrowserInfo browserInfoFromUrl:browserUrl loadAppIcon:NO];
}

- (void) setPersistedFallbackBrowser:(DRBrowserInfo *)browser {
	LOG_DEBUG(@"new persistedFallbackBrowser: %@", browser);
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:[browser.url absoluteString] forKey:kDRFallbackBrowser];
	[defaults synchronize];
}

- (void) dealloc {
	self.browsers = nil;
	self.browserArrayController = nil;
	self.defaultBrowserCollectionView = nil;
	self.defaultBrowserScrollView = nil;
	self.defaultBrowserClipView = nil;
	self.defaultBrowserCollectionViewLabel = nil;
	self.selectedBrowserIndexes = nil;
	
	[super dealloc];
}

@end
