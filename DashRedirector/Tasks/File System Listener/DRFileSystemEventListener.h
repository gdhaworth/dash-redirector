//
//  DRFileSystemEventListener.h
//  DashRedirector
//
//  Created by Graham Haworth on 7/5/13.
//  Copyright (c) 2013 Graham Haworth. All rights reserved.
//

#import <Foundation/Foundation.h>


@class DRDocsetIndexer;


@interface DRFileSystemEventListener : NSObject

- (id) initWithDocsetIndexer:(DRDocsetIndexer*)docsetIndexer;

- (void) setDashPreferencesPath:(NSString*)path;
- (void) setDocsetDescriptors:(NSSet*)docsetDescriptors;

@end
