//
//  DRTreeNode.h
//  DashRedirector
//
//  Created by Graham Haworth on 7/1/13.
//  Copyright (c) 2013 Graham Haworth. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol DRTreeNode <NSObject>

@optional
- (void) setObject:(id)object forChildSequence:(NSArray*)childSequence;
- (void) setObject:(id)object forMutableChildSequence:(NSMutableArray*)childSequence;

- (id) objectForSequenceRelativeTo:(NSArray*)searchSequence;

@required
- (id) objectForChildSequence:(NSArray*)childSequence;
- (id) objectForMutableChildSequence:(NSMutableArray*)childSequence;

- (NSString*) description;
- (void) addDescription:(NSMutableString*)description withDepth:(NSInteger)depth;

- (void) visitLeaves:(void(^)(id))leafVisitor;
- (NSInteger) deepCount;

@end
