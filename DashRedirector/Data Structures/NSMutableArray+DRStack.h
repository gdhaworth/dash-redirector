//
//  NSMutableArray+Stack.h
//  DashRedirector
//
//  Created by Graham Haworth on 7/1/13.
//  Copyright (c) 2013 Graham Haworth. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef NSMutableArray DRStack;


@interface NSMutableArray (DRStack)

- (id) pop;
- (void) push:(id)value;

@end
