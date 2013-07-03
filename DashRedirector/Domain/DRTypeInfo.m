//
//  DRTypeInfo.m
//  DashRedirector
//
//  Created by Graham Haworth on 7/2/13.
//  Copyright (c) 2013 Graham Haworth. All rights reserved.
//

#import "DRTypeInfo.h"


@interface DRTypeInfo ()

#define PROPERTY(NAME, TYPE) @property(nonatomic, readwrite, retain) TYPE * NAME;
#include "DRTypeInfoProperties.inc"
#undef PROPERTY

@end


@implementation DRTypeInfo

#define PROPERTY(NAME, TYPE) @synthesize NAME;
#include "DRTypeInfoProperties.inc"
#undef PROPERTY

+ (DRTypeInfo*) typeInfoWithName:(NSString*)name
						 andPath:(NSString*)path
			 andDocsetDescriptor:(DRDocsetDescriptor*)docsetDescriptor {
	
	DRTypeInfo *typeInfo = [[[DRTypeInfo alloc] init] autorelease];
	typeInfo.name = name;
	typeInfo.path = path;
	typeInfo.docsetDescriptor = docsetDescriptor;
	typeInfo.members = [NSMutableArray array];
	return typeInfo;
}

- (void) addMember:(id)member {
	[(NSMutableArray*)self.members addObject:member];
}

- (NSString*) description {
	return [NSString stringWithFormat:@"%@[name='%@', path='%@', docsetDescriptor=%@]",
			[self class], self.name, self.path, self.docsetDescriptor];
}

- (void) dealloc {
#define PROPERTY(NAME, TYPE) \
	self.NAME = nil;
#include "DRTypeInfoProperties.inc"
#undef PROPERTY
	
	[super dealloc];
}

@end
