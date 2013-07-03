//
//  DRDashDocsetIndexTask.h
//  DashRedirector
//
//  Created by Graham Haworth on 7/2/13.
//  Copyright (c) 2013 Graham Haworth. All rights reserved.
//

#import "DRDocsetIndexTask.h"


@interface DRDashDocsetIndexTask : DRDocsetIndexTask

- (id) initWithDocsetDescriptor:(DRDocsetDescriptor*)docsetDescriptor;
- (NSArray*) readTypes;

@end
