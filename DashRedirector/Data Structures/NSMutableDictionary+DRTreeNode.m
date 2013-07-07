//
//  NSMutableDictionary+DRRecursivePathTreeNode.m
//  DashRedirector
//
//  Created by Graham Haworth on 7/1/13.
//  Copyright (c) 2013 Graham Haworth. All rights reserved.
//

#import "DRLeaf.h"


@implementation NSMutableDictionary (DRTreeNode)

- (void) setObject:(id)object forChildSequence:(NSArray*)childSequence {
#warning TODO: handle empty
	
	[self setObject:object forMutableChildSequence:[NSMutableArray arrayWithArray:childSequence]];
}

- (void) setObject:(id)object forMutableChildSequence:(NSMutableArray*)childSequence {
	id nextValue = [childSequence pop];
#warning TODO: handle nil
	
	if([childSequence count] == 0) {
		[self setObject:[DRLeaf leafWithValue:object] forKey:nextValue];
	} else {
		NSMutableDictionary *childTree = [self objectForKey:nextValue];
		if(!childTree) {
			childTree = [NSMutableDictionary dictionary];
			[self setObject:childTree forKey:nextValue];
		}
		
		[childTree setObject:object forMutableChildSequence:childSequence];
	}
}

- (void) mergeTrees:(NSDictionary*)other {
	if(!other)
		return;
	
	for(id key in [other allKeys]) {
		NSMutableDictionary *childTree = [self getChildTree:key];
		id<DRTreeNode> otherChildNode = [other objectForKey:key];
		id<DRTreeNode> mergedChildNode = [self mergeChildTree:childTree withOtherChildNode:otherChildNode forKey:key];
		[self setObject:mergedChildNode forKey:key];
	}
}

- (NSMutableDictionary*) getChildTree:(id)key {
	id<DRTreeNode> childNode = [self objectForKey:key];
	NSMutableDictionary *childTree = nil;
	if(childNode) {
		childTree = [self getMutableIfDictionary:childNode];
		if(!childTree)
			[NSException raise:kDRConflictingValueException format:@"child at '%@' is a leaf, it cannot be merged", key];
	}
	return childTree;
}

- (id<DRTreeNode>) mergeChildTree:(NSMutableDictionary*)childTree
			   withOtherChildNode:(id<DRTreeNode>)otherChildNode
						   forKey:(id)key {
	
	NSAssert(otherChildNode, @"otherChildNode should not be nil for key: '%@'", key);
	
	NSMutableDictionary *otherChildTree = [self getMutableIfDictionary:otherChildNode];
	if(otherChildTree) {
		[otherChildTree mergeTrees:childTree];
		otherChildNode = otherChildTree;
	} else if(childTree) {
		[NSException raise:kDRConflictingValueException format:@"other's child at '%@' is a leaf, it cannot be merged", key];
		return nil;
	}
	
	return otherChildNode;
}

- (NSMutableDictionary*) getMutableIfDictionary:(id<DRTreeNode>)node {
	if(![[node class] isSubclassOfClass:[NSDictionary class]])
		return nil;
	
	NSDictionary *dictionary = (NSDictionary*) node;
	if([[dictionary class] isSubclassOfClass:[NSMutableDictionary class]])
		return (NSMutableDictionary*)dictionary;
	
	return [NSMutableDictionary dictionaryWithDictionary:dictionary];
}

@end
