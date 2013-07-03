//
//  NSDictionary+DRTreeNode.m
//  DashRedirector
//
//  Created by Graham Haworth on 7/1/13.
//  Copyright (c) 2013 Graham Haworth. All rights reserved.
//

#import "NSDictionary+DRTreeNode.h"
#import "NSMutableArray+Stack.h"


@implementation NSDictionary (DRTreeNode)

- (id) objectForSequenceRelativeTo:(NSArray*)searchSequence {
	NSMutableArray *mutableSearchSequence = [NSMutableArray arrayWithArray:searchSequence];
	while([mutableSearchSequence count] > 0) {
		id result = [self objectForChildSequence:mutableSearchSequence];
		if(result)
			return result;
		[mutableSearchSequence removeObjectAtIndex:0];
	}
	return nil;
}

- (id) objectForChildSequence:(NSArray*)childSequence {
	return [self objectForMutableChildSequence:[NSMutableArray arrayWithArray:childSequence]];
}

- (id) objectForMutableChildSequence:(NSMutableArray*)childSequence {
	id nextValue = [childSequence pop];
#warning TODO: handle nil
	
	id<DRTreeNode> childNode = [self objectForKey:nextValue];
	return [childNode objectForMutableChildSequence:childSequence];
}

- (NSString*) description {
	NSMutableString *description = [NSMutableString string];
	[self addDescription:description withDepth:0];
	return description;
}

- (void) addDescription:(NSMutableString*)description withDepth:(NSInteger)depth {
	for(id key in [self allKeys]) {
		for(int i = 0; i < depth; i++)
			[description appendString:@"  "];
		[description appendFormat:@"%@\n", [key description]];
		
		id<DRTreeNode> childNode = [self objectForKey:key];
		[childNode addDescription:description withDepth:(depth + 1)];
	}
}

- (void) visitLeaves:(void(^)(id))leafVisitor {
	for(id key in [self allKeys]) {
		id<DRTreeNode> node = [self objectForKey:key];
		[node visitLeaves:leafVisitor];
	}
}

- (NSInteger) deepCount {
	__block NSInteger count = 0;
	[self visitLeaves:^(id leaf) {
		count++;
	}];
	return count;
}

@end
