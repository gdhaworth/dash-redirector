//
//  DRGetUrlListener.m
//  DashRedirector
//
//  Created by Graham Haworth on 6/28/13.
//  Copyright (c) 2013 Graham Haworth. All rights reserved.
//

#import "DRGetUrlListener.h"
#import "DRDocsetIndexer.h"
#import "DRMemberInfo.h"
#import "DRTypeInfo.h"
#import "DRBrowserInfoTasks.h"


@interface DRGetUrlListener () {
	DRDocsetIndexer *docsetIndexer;
	
	CFAbsoluteTime lastGetUrlEvent;
	CFAbsoluteTime lastApplicationReadyToLaunchDashUrl;
}

@property (nonatomic, retain) NSURL *lastGetUrl;

@end


@implementation DRGetUrlListener

@synthesize lastGetUrl;

- (id) initWithDocsetIndexer:(DRDocsetIndexer*)indexer {
	self = [super init];
	if(self) {
		docsetIndexer = [indexer retain];
		
		lastGetUrlEvent = -1;
		lastApplicationReadyToLaunchDashUrl = -1;
	}
	return self;
}

- (void) registerAsEventHandler {
	[[NSAppleEventManager sharedAppleEventManager] setEventHandler:self
													   andSelector:@selector(handleGetURLEvent:withReplyEvent:)
													 forEventClass:kInternetEventClass
														andEventID:kAEGetURL];
}

- (void) handleGetURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent {
	NSURL *url = [NSURL URLWithString:[[event paramDescriptorForKeyword:keyDirectObject] stringValue]];
	
	LOG_TRACE(@"url: '%@'  path: '%@'  fragment: '%@'", url, [[url path] stringByDeletingPathExtension],
		  [[url fragment] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]);
	
	DRForceMainThread(^void{
		self.lastGetUrl = url;
		lastGetUrlEvent = CFAbsoluteTimeGetCurrent();
		
		[self launchLastComputedUrlIfReady];
	});
}

- (void) applicationReadyToLaunchDashUrl {
	ASSERT_MAIN_THREAD();
	
	lastApplicationReadyToLaunchDashUrl = CFAbsoluteTimeGetCurrent();
	[self launchLastComputedUrlIfReady];
}

// TODO: get out of configurable settings
#define kDRMaxEventDelay 0.500

- (void) launchLastComputedUrlIfReady {
	ASSERT_MAIN_THREAD();
	
	BOOL shouldLaunch = NO;
	if(lastGetUrlEvent > 0 && lastApplicationReadyToLaunchDashUrl > 0) {
		double interval = fabs(lastGetUrlEvent - lastApplicationReadyToLaunchDashUrl);
		shouldLaunch = (interval <= kDRMaxEventDelay);
		LOG_TRACE(@"shouldLaunch: %d  interval: %f", shouldLaunch, interval);
	}
	
	if(shouldLaunch) {
		// Don't clear lastGetUrlEvent so if the application accidentally becomes active again we re-launch Dash
		lastApplicationReadyToLaunchDashUrl = -1;
		
		BOOL dashUrl;
		NSURL *launchUrl = [self computeUrlToOpen:self.lastGetUrl isDashUrl:&dashUrl];
		LOG_DEBUG(@"launching url: %@", launchUrl);
		
		NSURL *browser = nil;
		if(!dashUrl && DRDashRedirectorIsDefaultBrowser())
			browser = DRPersistedFallbackBrowserUrl();
		[self launchUrl:launchUrl browser:browser];
	} else
		LOG_TRACE(@"Skipped launching dashUrl; lastGetUrlEvent: %f  lastApplicationReadyToLaunchDashUrl: %f",
				  lastGetUrlEvent, lastApplicationReadyToLaunchDashUrl);
}

- (NSURL*) computeUrlToOpen:(NSURL*)requestUrl isDashUrl:(BOOL*)isDashUrl {
	DRTypeInfo *foundTypeInfo = [docsetIndexer searchUrl:requestUrl];
	
	LOG_TRACE(@"foundTypeInfo: %@", foundTypeInfo);
	
	if(!foundTypeInfo) {
		*isDashUrl = NO;
		return requestUrl;
	}
	
	*isDashUrl = YES;
	NSString *dashUrl = [self computeDashUrl:requestUrl forType:foundTypeInfo];
	return [NSURL URLWithString:[dashUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
}

- (NSString*) computeDashUrl:(NSURL*)requestUrl forType:(DRTypeInfo*)type {
	NSString *fragment = [[requestUrl fragment] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	if(!NSStringIsNullOrEmpty(fragment)) {
		DRMemberInfo *foundMemberInfo = [type.members match:^BOOL(DRMemberInfo *member) {
			return [member.anchor isEqualToString:fragment];
		}];
		
		if(foundMemberInfo)
			return DashUrlForMemberInType(foundMemberInfo, type);
	}
	
	return DashUrlForType(type);
}

static inline NSString* DashUrlForType(DRTypeInfo *type) {
	return [NSString stringWithFormat:@"dash://%@:%@", type.docsetDescriptor.keyword, type.name];
}

static inline NSString* DashUrlForMemberInType(DRMemberInfo *member, DRTypeInfo *type) {
	return [NSString stringWithFormat:@"dash://%@:%@ %@", type.docsetDescriptor.keyword, type.name, member.name];
}

- (void) launchUrl:(NSURL*)url browser:(NSURL*)browser {
	LSLaunchURLSpec launchSpec;
	launchSpec.appURL = (CFURLRef) browser;
	launchSpec.itemURLs = (CFArrayRef) [NSArray arrayWithObject:url];
	launchSpec.passThruParams = NULL;
	launchSpec.launchFlags = kLSLaunchDefaults;
	launchSpec.asyncRefCon = NULL;
	LSOpenFromURLSpec(&launchSpec, NULL);
}

- (void) dealloc {
	[docsetIndexer release];
	
	self.lastGetUrl = nil;
	
	[super dealloc];
}

@end
