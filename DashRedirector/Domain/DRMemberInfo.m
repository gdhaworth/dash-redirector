//
//  DRMemberInfo.m
//  DashRedirector
//
//  Created by Graham Haworth on 7/2/13.
//  Copyright (c) 2013 Graham Haworth. All rights reserved.
//

#import "DRMemberInfo.h"


@interface DRMemberInfo ()

#define PROPERTY(NAME, TYPE) @property(nonatomic, readwrite, retain) TYPE * NAME;
#include "DRMemberInfoProperties.inc"
#undef PROPERTY

@end


@implementation DRMemberInfo

#define PROPERTY(NAME, TYPE) @synthesize NAME;
#include "DRMemberInfoProperties.inc"
#undef PROPERTY

+ (DRMemberInfo*) memberInfoWithName:(NSString*)name andAnchor:(NSString*)anchor {
	DRMemberInfo *memberInfo = [[[DRMemberInfo alloc] init] autorelease];
	memberInfo.name = name;
	memberInfo.anchor = anchor;
	return memberInfo;
}

- (NSString*) description {
	return [NSString stringWithFormat:@"%@[name='%@']",
			[self class], self.name];
}

- (void) dealloc {
#define PROPERTY(NAME, TYPE) \
self.NAME = nil;
#include "DRMemberInfoProperties.inc"
#undef PROPERTY
	
	[super dealloc];
}

@end
