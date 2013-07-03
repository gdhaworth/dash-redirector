//
//  DRGetUrlListener.m
//  DashRedirector
//
//  Created by Graham Haworth on 6/28/13.
//  Copyright (c) 2013 Graham Haworth. All rights reserved.
//

#import "DRGetUrlListener.h"


@interface DRGetUrlListener () {
	UrlCallback urlCallback;
}

@end


@implementation DRGetUrlListener

- (id) initWithGetUrlCallback:(UrlCallback)callback {
	self = [super init];
	if(self) {
		urlCallback = [callback copy];
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
	[self makeGetURLCallbackOnMainThread:[NSURL URLWithString:[[event paramDescriptorForKeyword:keyDirectObject] stringValue]]];
}

- (void) makeGetURLCallbackOnMainThread:(NSURL*)url {
	if(![NSThread isMainThread]) {
		[self performSelectorOnMainThread:@selector(makeGetURLCallbackOnMainThread:) withObject:url waitUntilDone:NO];
		return;
	}
	
	urlCallback(url);
}

- (void) dealloc {
	[urlCallback release];
	
	[super dealloc];
}

@end
