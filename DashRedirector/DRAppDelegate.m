//
//  DRAppDelegate.m
//  DashRedirector
//
//  Created by Graham Haworth on 6/28/13.
//  Copyright (c) 2013 Graham Haworth. All rights reserved.
//

#import "DRAppDelegate.h"
#import "DRGetUrlListener.h"
#import "DRDocsetIndexer.h"
#import "DRTypeInfo.h"
#import "DRMemberInfo.h"


@implementation DRAppDelegate

@synthesize workQueue, docsetIndexer;


#pragma mark - Application Lifecycle Callbacks

- (void) applicationWillFinishLaunching:(NSNotification *)notification {
	DRGetUrlListener *listener = [[DRGetUrlListener alloc] initWithGetUrlCallback:^(NSURL *url) {
		// TEMP
		DRLog(@"url: '%@'  path: '%@'  fragment: '%@'", url, [[url path] stringByDeletingPathExtension],
			  [[url fragment] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]);
		
		DRTypeInfo *foundTypeInfo = [docsetIndexer searchUrl:url];
		
		// TEMP
		DRLog(@"foundTypeInfo: %@", foundTypeInfo);
		
		// TEMP
		NSURL *urlToOpen;
		if(foundTypeInfo) {
			NSString *dashUrl = nil;
			
			// TODO handle nil keyword
			NSString *fragment = [[url fragment] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
			if(fragment && [fragment length] > 0) {
				DRMemberInfo *foundMemberInfo = nil;
				for(DRMemberInfo *member in foundTypeInfo.members) {
					if([member.anchor isEqualToString:fragment]) {
						foundMemberInfo = member;
						break;
					}
				}
				
				if(foundMemberInfo)
					dashUrl = [NSString stringWithFormat:@"dash://%@%@ %@", foundTypeInfo.docsetDescriptor.keyword,
							   foundTypeInfo.name, foundMemberInfo.name];
			}
			
			if(!dashUrl)
				dashUrl = [NSString stringWithFormat:@"dash://%@%@", foundTypeInfo.docsetDescriptor.keyword, foundTypeInfo.name];
			
			urlToOpen = [NSURL URLWithString:[dashUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
			DRLog(@"dashUrl: %@", dashUrl);
		} else {
			urlToOpen = url;
		}
		LSOpenCFURLRef((CFURLRef)urlToOpen, NULL);
		
		// TODO
	}];
	[listener registerAsEventHandler];
}

- (void) applicationDidFinishLaunching:(NSNotification *)aNotification {
	DRLogLine;
	
#warning TODO: consider moving to applicationWillFinishLaunching so this always exists
	[docsetIndexer index];
}


#pragma mark - Instance Lifecycle

- (id) init {
	self = [super init];
	if(self) {
//		self.workQueue = [[NSOperationQueue alloc] init];
//		self.docsetIndexer = [[DRDocsetIndexer alloc] initWithWorkQueue:workQueue];
		workQueue = [[NSOperationQueue alloc] init];
		docsetIndexer = [[DRDocsetIndexer alloc] initWithWorkQueue:workQueue];
	}
	return self;
}

- (void) dealloc {
//	self.workQueue = nil;
//	self.docsetIndexer = nil;
	[workQueue release];
	[docsetIndexer release];
	
    [super dealloc];
}

@end
