//
//  DRReadDashPreferencesTask.h
//  DashRedirector
//
//  Created by Graham Haworth on 7/1/13.
//  Copyright (c) 2013 Graham Haworth. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef void(^CompletionCallback)(NSArray*);


@interface DRReadDashPreferencesTask : NSObject

+ (NSOperation*) readDashPreferences:(CompletionCallback)callback;

@end
