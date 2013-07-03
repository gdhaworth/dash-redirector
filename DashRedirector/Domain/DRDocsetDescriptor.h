//
//  DRDocsetDescriptor.h
//  DashRedirector
//
//  Created by Graham Haworth on 7/1/13.
//  Copyright (c) 2013 Graham Haworth. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef enum {
	DRDocsetTypeJava,
	DRDocsetTypeUnknown
} DRDocsetType;


@interface DRDocsetDescriptor : NSObject

+ (DRDocsetDescriptor*) parseDocset:(NSDictionary*)docsetPref;

#define ASSIGN_PROPERTY(NAME, TYPE)			@property(nonatomic, readonly) TYPE NAME;
#define RETAIN_PROPERTY(NAME, TYPE, KEY)	@property(nonatomic, readonly) TYPE * NAME;
#include "DRDocsetDescriptorProperties.inc"
#undef ASSIGN_PROPERTY
#undef RETAIN_PROPERTY

@end
