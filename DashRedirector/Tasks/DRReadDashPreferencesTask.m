//
//  DRReadDashPreferencesTask.m
//  DashRedirector
//
//  Created by Graham Haworth on 7/1/13.
//  Copyright (c) 2013 Graham Haworth. All rights reserved.
//

#import "DRReadDashPreferencesTask.h"
#import "DRDocsetDescriptor.h"
#import "DRExceptions.h"


#define kDashPreferencesFile @"com.kapeli.dash.plist"


@implementation DRReadDashPreferencesTask

+ (NSOperation*) readDashPreferences:(CompletionCallback)callback {
	return [NSBlockOperation blockOperationWithBlock:^{
		callback([DRReadDashPreferencesTask parseInstalledDashDocsets]);
	}];
}

+ (NSArray*) parseInstalledDashDocsets {
	NSDictionary *dashPrefs = [DRReadDashPreferencesTask readDashPreferences];
	NSArray *docsetsPrefs = [dashPrefs objectForKey:@"docsets"];
	
	return [docsetsPrefs map:^id(NSDictionary *docsetPref) {
		return [DRDocsetDescriptor parseDocset:docsetPref];
	}];
}

+ (NSDictionary*) readDashPreferences {
	NSArray *pathComponents = @[ NSHomeDirectory(), @"Library/Preferences", kDashPreferencesFile ];
	return [NSDictionary dictionaryWithContentsOfFile:[NSString pathWithComponents:pathComponents]];
}

@end
