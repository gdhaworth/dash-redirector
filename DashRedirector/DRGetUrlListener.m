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

@end


@implementation DRGetUrlListener

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
	
	NSURL *urlToOpen = [self computeUrlToOpen:url];
	
	// TEMP
	LOG_DEBUG(@"dashUrl: %@", urlToOpen);
	
	LSOpenCFURLRef((CFURLRef)urlToOpen, NULL);
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
	
	[super dealloc];
}

@end
