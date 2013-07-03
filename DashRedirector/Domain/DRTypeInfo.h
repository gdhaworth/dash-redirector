//
//  DRTypeInfo.h
//  DashRedirector
//
//  Created by Graham Haworth on 7/2/13.
//  Copyright (c) 2013 Graham Haworth. All rights reserved.
//

#import "DRDocsetDescriptor.h"

#import <Foundation/Foundation.h>


@interface DRTypeInfo : NSObject

+ (DRTypeInfo*) typeInfoWithName:(NSString*)name
						 andPath:(NSString*)path
			 andDocsetDescriptor:(DRDocsetDescriptor*)docsetDescriptor;

- (void) addMember:(id)member;

#define PROPERTY(NAME, TYPE) @property(nonatomic, readonly) TYPE * NAME;
#include "DRTypeInfoProperties.inc"
#undef PROPERTY

@end
