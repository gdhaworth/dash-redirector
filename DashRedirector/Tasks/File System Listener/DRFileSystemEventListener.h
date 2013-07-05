//
//  DRFileSystemEventListener.h
//  DashRedirector
//
//  Created by Graham Haworth on 7/5/13.
//  Copyright (c) 2013 Graham Haworth. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface DRFileSystemEventListener : NSObject

- (void) setDashPreferencesPath:(NSString*)path;
- (void) setDocsetDescriptors:(NSArray*)docsetDescriptors;

@end
