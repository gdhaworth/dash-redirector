//
//  NSMutableArray+Stack.m
//  DashRedirector
//
//  Created by Graham Haworth on 7/1/13.
//  Copyright (c) 2013 Graham Haworth. All rights reserved.
//

#import "NSMutableArray+Stack.h"


@implementation NSMutableArray (Stack)

- (id) pop {
#warning TODO: consider throwing exception
	if([self count] == 0)
		return nil;
	
	id nextValue = [self objectAtIndex:0];
	[self removeObjectAtIndex:0];
	return nextValue;
}

@end
