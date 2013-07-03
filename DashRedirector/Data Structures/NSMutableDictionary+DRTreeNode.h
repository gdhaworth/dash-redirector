//
//  NSMutableDictionary+DRRecursivePathTreeNode.h
//  DashRedirector
//
//  Created by Graham Haworth on 7/1/13.
//  Copyright (c) 2013 Graham Haworth. All rights reserved.
//

#import "DRTreeNode.h"

#import <Foundation/Foundation.h>


@interface NSMutableDictionary (DRTreeNode) <DRTreeNode>

- (void) setObject:(id)object forChildSequence:(NSArray*)childSequence;
- (void) setObject:(id)object forMutableChildSequence:(NSMutableArray*)childSequence;

- (void) mergeTrees:(NSDictionary*)other;

@end
