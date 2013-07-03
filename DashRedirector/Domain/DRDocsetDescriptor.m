//
//  DRDocsetDescriptor.m
//  DashRedirector
//
//  Created by Graham Haworth on 7/1/13.
//  Copyright (c) 2013 Graham Haworth. All rights reserved.
//

#import "DRDocsetDescriptor.h"
#import "DRExceptions.h"


@interface DRDocsetDescriptor ()

#define ASSIGN_PROPERTY(NAME, TYPE)			@property(nonatomic, readwrite, assign) TYPE NAME;
#define RETAIN_PROPERTY(NAME, TYPE, KEY)	@property(nonatomic, readwrite, retain) TYPE * NAME;
#include "DRDocsetDescriptorProperties.inc"
#undef ASSIGN_PROPERTY
#undef RETAIN_PROPERTY

@end


@implementation DRDocsetDescriptor

#define ASSIGN_PROPERTY(NAME, TYPE)			@synthesize NAME;
#define RETAIN_PROPERTY(NAME, TYPE, KEY)	@synthesize NAME;
#include "DRDocsetDescriptorProperties.inc"
#undef ASSIGN_PROPERTY
#undef RETAIN_PROPERTY

+ (DRDocsetDescriptor*) parseDocset:(NSDictionary*)docsetPref {
	DRDocsetDescriptor *parsedDocset = [[[DRDocsetDescriptor alloc] init] autorelease];
	
	parsedDocset.type = [DRDocsetDescriptor determineDocsetType:docsetPref];
	parsedDocset.dashFormat = [[docsetPref objectForKey:@"isDash"] boolValue];
	
#define RETAIN_PROPERTY(NAME, TYPE, KEY) \
	parsedDocset.NAME = [docsetPref objectForKey:KEY];
#include "DRDocsetDescriptorProperties.inc"
#undef RETAIN_PROPERTY
	
	return parsedDocset;
}

+ (DRDocsetType) determineDocsetType:(NSDictionary*) docsetPref {
	NSString *platform = [docsetPref objectForKey:@"platform"];
	NSString *parseFamily = [docsetPref objectForKey:@"parseFamily"];
	if([@"java" isEqualToString:platform] || [@"java" isEqualToString:parseFamily])
		return DRDocsetTypeJava;
	
	return DRDocsetTypeUnknown;
}

+ (NSString*) typeAsString:(DRDocsetType)type {
	switch(type) {
		case DRDocsetTypeJava:
			return @"Java";
			
		case DRDocsetTypeUnknown:
			return @"Unknown";
			
		default:
			[NSException raise:kDRUnsupportedValueException format:@"unknown DRDocSetType: %d", type];
			return nil;
	}
}

- (NSString*) description {
	return [NSString stringWithFormat:@"%@[name='%@', type='%@', sqliteIndexPath='%@', keyword='%@', dashFormat=%d]",
			[self class], self.name, [DRDocsetDescriptor typeAsString:self.type], self.sqliteIndexPath, self.keyword,
			self.dashFormat];
}

- (void) dealloc {
#define RETAIN_PROPERTY(NAME, TYPE, KEY) \
	self.NAME = nil;
#include "DRDocsetDescriptorProperties.inc"
#undef RETAIN_PROPERTY
	
	[super dealloc];
}

@end
