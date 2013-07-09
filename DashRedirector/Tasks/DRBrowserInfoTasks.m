//
//  DRReadBrowserInfoTasks.m
//  DashRedirector
//
//  Created by Graham Haworth on 7/7/13.
//  Copyright (c) 2013 Graham Haworth. All rights reserved.
//

#import "DRBrowserInfoTasks.h"
#import "DRAppDelegate.h"


#define kExampleHttpUrl @"http://docs.oracle.com/javase/7/docs/api/java/lang/String.html"
#define kExampleUrls @[ kExampleHttpUrl, \
						@"https://docs.oracle.com/javase/7/docs/api/java/lang/String.html", \
						@"file:/tmp/file.html", @"file:/tmp/file.htm" ]


@implementation DRBrowserInfoTasks

+ (void) readBrowsers:(DRReadBrowsersCallback)callback {
	[self callInBackground:^id{
		NSSet *foundBrowsers = [self findBrowserUrls];
		
		NSSet *browserInfos = [foundBrowsers map:^DRBrowserInfo*(NSURL *browserUrl) {
			return [DRBrowserInfo browserInfoFromUrl:browserUrl];
		}];
		return [browserInfos reject:^BOOL(DRBrowserInfo *browser) {
			return [self isCurrentApp:browser];
		}];
	} passResultToForeground:callback];
}

+ (NSSet*) findBrowserUrls {
	NSMutableSet *foundBrowsers = [NSMutableSet set];
	[kExampleUrls each:^(NSString *urlString) {
		CFURLRef url = (CFURLRef) [NSURL URLWithString:urlString];
		NSArray *apps = (NSArray*) LSCopyApplicationURLsForURL(url, (kLSRolesViewer | kLSRolesEditor));
		[foundBrowsers addObjectsFromArray:apps];
	}];
	
	return foundBrowsers;
}

+ (void) readDefaultBrowser:(DRReadBrowserCallback)callback {
	[self callInBackground:^id{
		CFURLRef url = (CFURLRef) [NSURL URLWithString:kExampleHttpUrl];
		CFURLRef appUrl = nil;
		LSGetApplicationForURL(url, (kLSRolesEditor | kLSRolesViewer), NULL, &appUrl);
		return [DRBrowserInfo browserInfoFromUrl:(NSURL*)appUrl];
	} passResultToForeground:callback];
}

+ (void) callInBackground:(id<NSObject>(^)(void))background passResultToForeground:(void(^)(id<NSObject>))foreground {
	ASSERT_MAIN_THREAD();
	
	static NSOperation *lastOperation = nil;
	__block id<NSObject> result;
	
	NSOperation *workBlock = [NSBlockOperation blockOperationWithBlock:^{
		LOG_TRACE(@"callInBackground: background start");
		
		result = [background() retain];
	}];
	if(lastOperation)
		[workBlock addDependency:lastOperation];
	
	[lastOperation release];
	if(foreground) {
		NSOperation *callbackOp = [NSBlockOperation blockOperationWithBlock:^{
			LOG_TRACE(@"callInBackground: main start");
			foreground(result);
			[result release];
		}];
		[callbackOp addDependency:workBlock];
		[[NSOperationQueue mainQueue] addOperation:callbackOp];
		lastOperation = [callbackOp retain];
	} else
		lastOperation = [workBlock retain];
	
	LOG_TRACE(@"callInBackground: main -> background");
	[((DRAppDelegate*)[NSApp delegate]).workQueue addOperation:workBlock];
}

+ (void) setSystemDefaultBrowser:(DRBrowserInfo*)browser {
	LOG_INFO(@"setting system browser: %@", browser.url);
	
	[@[ @"http", @"https" ] each:^(NSString *scheme) {
		LSSetDefaultHandlerForURLScheme((CFStringRef)scheme, (CFStringRef)browser.bundle.bundleIdentifier);
	}];
}

+ (BOOL) isCurrentApp:(DRBrowserInfo*)browser {
	return [[self currentApp] isEqual:browser];
}

+ (DRBrowserInfo*) currentApp {
	static DRBrowserInfo *currentAppInfo;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		currentAppInfo = [[DRBrowserInfo browserInfoFromBundle:[NSBundle mainBundle] loadAppIcon:NO] retain];
	});
	return currentAppInfo;
}

@end
