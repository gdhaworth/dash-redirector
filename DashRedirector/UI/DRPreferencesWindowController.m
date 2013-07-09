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
	BOOL registered;
	
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
		registered = NO;
		
		dashRedirectorDefaultBrowserHandleDispatchCount = 0;
		self.browsers = [NSMutableArray array];
		self.selectedBrowserIndexes = [NSMutableIndexSet indexSet];
	}
	
	return self;
}

- (void) awakeFromNib {
	[self setUpLockableClipView];
	
	if(!registered) {
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
																  forKeyPath:@"values.dashRedirectorIsDefaultBrowser"
																	 options:NSKeyValueObservingOptionNew
																	 context:@selector(handleDashRedirectorDefaultBrowserChange:)];
		[self addObserver:self
			   forKeyPath:@"selectedBrowserIndexes"
				  options:NSKeyValueObservingOptionNew
				  context:@selector(handleSelectedDefaultBrowserChange:)];
		
		registered = YES;
	}
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
		} else if([DRBrowserInfoTasks isCurrentApp:browserInfo])
			[DRBrowserInfoTasks setSystemDefaultBrowser:self.persistedFallbackBrowser];
		
		[self updateDefaultBrowserViewState:drIsDefault];
	}];
}

- (void) handleSelectedDefaultBrowserChange:(id)newValue {
	DRBrowserInfo *selectedDefaultBrowser = self.selectedDefaultBrowser;
	
	LOG_TRACE(@"selectedBrowser: %@", selectedDefaultBrowser);
	
	if(!selectedDefaultBrowser)
		return;
	
	self.persistedFallbackBrowser = selectedDefaultBrowser;
}

- (void) updateDefaultBrowserViewState:(BOOL)drIsDefault {
	LOG_TRACE(@"dash redirector is default: %d", drIsDefault);
	
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
