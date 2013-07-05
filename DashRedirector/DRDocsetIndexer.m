//
//  DRDocsetIndexer.m
//  DashRedirector
//
//  Created by Graham Haworth on 7/1/13.
//  Copyright (c) 2013 Graham Haworth. All rights reserved.
//

#import "DRDocsetIndexer.h"
#import "DRDocsetDescriptor.h"
#import "DRTypeInfo.h"
#import "DRReadDashPreferencesTask.h"
#import "DRDashDocsetIndexTask.h"
#import "DRAppleDocsetIndexTask.h"
#import "NSDictionary+DRTreeNode.h"
#import "NSMutableDictionary+DRTreeNode.h"
#import "DRExceptions.h"


@interface DRDocsetIndexer () {
	NSOperationQueue *workQueue;
}

@property (atomic, retain) NSDictionary *indexResults;
@property (atomic, retain) NSCondition *indexFinish;

@end


@implementation DRDocsetIndexer

@synthesize indexResults, indexFinish;

- (id) initWithWorkQueue:(NSOperationQueue*)queue {
	self = [super init];
	if(self) {
		workQueue = [queue retain];
		self.indexFinish = [[[NSCondition alloc] init] autorelease];
	}
	return self;
}

- (void) index {
	LOG_LINE();
	
	[workQueue addOperation:[DRReadDashPreferencesTask readDashPreferences:^(NSArray *docsetDescriptors) {
		[self indexParsedDashDocsets:docsetDescriptors];
	}]];
}

- (void) indexParsedDashDocsets:(NSArray*)docsetDescriptors {
	NSArray *docsetIndexTasks = [self queueIndexTasks:docsetDescriptors];
	
	NSOperation *handleResultsOperation = [[NSInvocationOperation alloc] initWithTarget:self
																			   selector:@selector(handleIndexResults:)
																				 object:docsetIndexTasks];
	for(DRDocsetIndexTask *task in docsetIndexTasks)
		[handleResultsOperation addDependency:task.operation];
	[workQueue addOperation:handleResultsOperation];
}

- (NSArray*) queueIndexTasks:(NSArray*)docsetDescriptors {
	NSMutableArray *docsetIndexTasks = [[NSMutableArray alloc] initWithCapacity:[docsetDescriptors count]];
	for(DRDocsetDescriptor *docsetDescriptor in docsetDescriptors) {
		DRDocsetIndexTask *task = [self createIndexTask:docsetDescriptor];
		if(!task)
			continue;
		
		[docsetIndexTasks addObject:task];
		[workQueue addOperation:task.operation];
	}
	return docsetIndexTasks;
}

- (DRDocsetIndexTask*) createIndexTask:(DRDocsetDescriptor*)docsetDescriptor {
	if(docsetDescriptor.type != DRDocsetTypeJava)
		return nil;
	
	if(docsetDescriptor.dashFormat)
		return [[[DRDashDocsetIndexTask alloc] initWithDocsetDescriptor:docsetDescriptor] autorelease];
	
	return [[[DRAppleDocsetIndexTask alloc] initWithDocsetDescriptor:docsetDescriptor] autorelease];
}

- (void) handleIndexResults:(NSArray*)tasks {
	NSMutableDictionary *mergedResults = [NSMutableDictionary dictionary];
	for(DRDocsetIndexTask *task in tasks)
		[mergedResults mergeTrees:task.result];
	
	NSCondition *condition = self.indexFinish;
	[condition lock];
	self.indexResults = mergedResults;
	self.indexFinish = nil;
	[condition signal];
	[condition unlock];
	
	__block int memberCount = 0;
	[self.indexResults visitLeaves:^(DRTypeInfo *typeInfo) {
		memberCount += [typeInfo.members count];
	}];
	
	LOG_INFO(@"Done indexing, found: %ld classes, %ld members", (long)[self.indexResults deepCount], (long)memberCount);
}

- (DRTypeInfo*) searchUrl:(NSURL*)url {
	// We don't care that much about the results being stale, the property is atomic
	// and will never again be nil, so this should be ok.
	NSCondition *condition = self.indexFinish;
	[condition lock];
	while(!self.indexResults)
		[condition wait];
	
	// As long as we never set self.indexResults to nil we'll have one, so we'll skip using it within the lock.
	[condition unlock];
	
	NSArray *pathComponents = [[[url path] stringByDeletingPathExtension] pathComponents];
	return [self.indexResults objectForSequenceRelativeTo:pathComponents];
}

- (id) init {
	[NSException raise:kDRUnsupportedOperationException format:@"use initWithType:"];
	return nil;
}

- (void) dealloc {
	[workQueue release];
	
	self.indexFinish = nil;
	self.indexResults = nil;
	
	[super dealloc];
}

@end
