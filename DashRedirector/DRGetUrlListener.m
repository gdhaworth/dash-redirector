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


@interface DRGetUrlListener () {
	DRDocsetIndexer *docsetIndexer;
}

@property (nonatomic, retain) NSURL *lastComputedUrl;
@property (nonatomic, retain) NSDate *lastGetUrlEvent;
@property (nonatomic, retain) NSDate *lastApplicationReadyToLaunchDashUrl;

@end


@implementation DRGetUrlListener

@synthesize lastComputedUrl, lastGetUrlEvent, lastApplicationReadyToLaunchDashUrl;

- (id) initWithDocsetIndexer:(DRDocsetIndexer*)indexer {
	self = [super init];
	if(self) {
		docsetIndexer = [indexer retain];
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
	
	// TEMP
	LOG_DEBUG(@"url: '%@'  path: '%@'  fragment: '%@'", url, [[url path] stringByDeletingPathExtension],
		  [[url fragment] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]);
	
	[self calculateRedirectAndOpenUrl:url];
}

- (void) applicationReadyToLaunchDashUrl {
	ASSERT_MAIN_THREAD();
	
	self.lastApplicationReadyToLaunchDashUrl = [NSDate date];
	[self launchLastComputedUrlIfReady];
}

- (void) calculateRedirectAndOpenUrl:(NSURL*)url {
	DRForceMainThread(^void{
		self.lastComputedUrl = [self computeUrlToOpen:url];
		self.lastGetUrlEvent = [NSDate date];
		
		[self launchLastComputedUrlIfReady];
	});
}

// TODO: get out of configurable settings
#define kDRMaxEventDelay 0.100

- (void) launchLastComputedUrlIfReady {
	ASSERT_MAIN_THREAD();
	
	BOOL shouldLaunch = NO;
	if(self.lastGetUrlEvent && self.lastApplicationReadyToLaunchDashUrl) {
		double interval = fabs([self.lastGetUrlEvent timeIntervalSinceDate:self.lastApplicationReadyToLaunchDashUrl]);
		shouldLaunch = interval < kDRMaxEventDelay;
	}
	
	if(shouldLaunch) {
		// Don't clear lastGetUrlEvent so if the application accidentally becomes active again we re-launch Dash
		self.lastApplicationReadyToLaunchDashUrl = nil;
		
		LOG_DEBUG(@"launching dashUrl: %@", self.lastComputedUrl);
		LSOpenCFURLRef((CFURLRef)self.lastComputedUrl, NULL);
	} else
		LOG_DEBUG(@"Skipped launching dashUrl; lastGetUrlEvent: %@  lastApplicationReadyToLaunchDashUrl: %@",
				  self.lastGetUrlEvent, self.lastApplicationReadyToLaunchDashUrl);
}

- (NSURL*) computeUrlToOpen:(NSURL*)requestUrl {
	DRTypeInfo *foundTypeInfo = [docsetIndexer searchUrl:requestUrl];
	
	// TEMP
	LOG_DEBUG(@"%@", foundTypeInfo);
	
	if(!foundTypeInfo)
		return requestUrl;
	
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

- (void) dealloc {
	[docsetIndexer release];
	
	self.lastComputedUrl = nil;
	self.lastGetUrlEvent = nil;
	self.lastApplicationReadyToLaunchDashUrl = nil;
	
	[super dealloc];
}

@end
