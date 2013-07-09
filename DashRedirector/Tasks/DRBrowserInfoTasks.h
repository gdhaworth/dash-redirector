//
//  DRReadBrowserInfoTasks.h
//  DashRedirector
//
//  Created by Graham Haworth on 7/7/13.
//  Copyright (c) 2013 Graham Haworth. All rights reserved.
//

#import "DRBrowserInfo.h"

#import <Foundation/Foundation.h>


typedef void(^DRReadBrowsersCallback)(NSSet *browserInfos);
typedef void(^DRReadBrowserCallback)(DRBrowserInfo *browserInfo);


@interface DRBrowserInfoTasks : NSObject

+ (void) readBrowsers:(DRReadBrowsersCallback)callback;
+ (void) readDefaultBrowser:(DRReadBrowserCallback)callback;

+ (void) setSystemDefaultBrowser:(DRBrowserInfo*)browser;

+ (BOOL) isCurrentApp:(DRBrowserInfo*)browser;
+ (DRBrowserInfo*) currentApp;

@end
