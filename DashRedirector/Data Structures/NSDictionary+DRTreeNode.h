//
//  NSDictionary+DRTreeNode.h
//  DashRedirector
//
//  Created by Graham Haworth on 7/1/13.
//  Copyright (c) 2013 Graham Haworth. All rights reserved.
//

#import "DRTreeNode.h"

#import <Foundation/Foundation.h>


@interface NSDictionary (DRTreeNode) <DRTreeNode>

- (id) objectForSequenceRelativeTo:(NSArray*)searchSequence;

- (id) objectForChildSequence:(NSArray*)childSequence;
- (id) objectForMutableChildSequence:(NSMutableArray*)childSequence;

- (NSString*) description;
- (void) addDescription:(NSMutableString*)description withDepth:(NSInteger)depth;

- (void) visitLeaves:(void(^)(id))leafVisitor;
- (NSInteger) deepCount;

@end
