//
//  DRLeaf.m
//  DashRedirector
//
//  Created by Graham Haworth on 7/1/13.
//  Copyright (c) 2013 Graham Haworth. All rights reserved.
//

#import "DRLeaf.h"


@implementation DRLeaf

@synthesize value;

+ (DRLeaf*) leafWithValue:(id)value {
	DRLeaf *leaf = [[[DRLeaf alloc] init] autorelease];
	leaf.value = value;
	return leaf;
}

- (id) objectForChildSequence:(NSArray*)childSequence {
#warning TODO: deal with non-empty childSequence
	return self.value;
}

- (id) objectForMutableChildSequence:(NSMutableArray*)childSequence {
#warning TODO: deal with non-empty childSequence
	return self.value;
}

- (NSString*) description {
	return [NSString stringWithFormat:@"%@[%@]", [self class], [self.value description]];
}

- (void) addDescription:(NSMutableString*)description withDepth:(NSInteger)depth {
	for(int i = 0; i < depth; i++)
		[description appendString:@"  "];
	[description appendFormat:@"%@\n", [self description]];
}

- (void) visitLeaves:(void(^)(id))leafVisitor {
	leafVisitor(self.value);
}

- (NSInteger) deepCount {
	return 1;
}

- (void) dealloc {
	self.value = nil;
	
	[super dealloc];
}

@end
