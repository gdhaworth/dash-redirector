//
//  DRMemberInfo.h
//  DashRedirector
//
//  Created by Graham Haworth on 7/2/13.
//  Copyright (c) 2013 Graham Haworth. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface DRMemberInfo : NSObject

+ (DRMemberInfo*) memberInfoWithName:(NSString*)name andAnchor:(NSString*)anchor;

#define PROPERTY(NAME, TYPE) @property(nonatomic, readonly) TYPE * NAME;
#include "DRMemberInfoProperties.inc"
#undef PROPERTY

@end
