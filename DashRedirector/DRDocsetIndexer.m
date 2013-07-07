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
#import "DRFileSystemEventListener.h"


@interface DRDocsetIndexer () {
	NSOperationQueue *workQueue;
	DRFileSystemEventListener *fileSystemListener;
	
	// The following ivar groupings are each guarded by the lock at the end of the group
	
	BOOL indexing;
	BOOL indexQueued;
	NSObject *indexStatusLock;
	
	NSMutableDictionary *mergedIndexInProgress;
	NSObject *indexInProgressLock;
	
	NSDictionary *indexResults;
	NSCondition *indexPublishCondition;
}

@property (atomic, retain) NSSet *mostRecentDocsetDescriptors;

@end


@implementation DRDocsetIndexer

@synthesize mostRecentDocsetDescriptors;

- (id) initWithWorkQueue:(NSOperationQueue*)queue {
	self = [super init];
	if(self) {
		workQueue = [queue retain];
		indexStatusLock = [[NSObject alloc] init];
		indexInProgressLock = [[NSObject alloc] init];
		indexPublishCondition = [[NSCondition alloc] init];
		
		mergedIndexInProgress = [[NSMutableDictionary alloc] init];
		indexing = NO;
		indexQueued = NO;
		
		fileSystemListener = [[DRFileSystemEventListener alloc] initWithDocsetIndexer:self];
	}
	return self;
}

#pragma mark - Indexing Methods

#pragma mark Public Indexing Methods

- (void) startOrQueueIndex {
	@synchronized(indexStatusLock) {
		BOOL started = [self startIndex];
		if(started)
			return;
		
		LOG_DEBUG(@"Index already running, queueing another index");
		indexQueued = YES;
	}
}

- (BOOL) startIndex {
	@synchronized(indexStatusLock) {
		if(indexing)
			return NO;
		
		indexing = YES;
	}
	
	[self submitReadDashPreferencesTask];
	return YES;
}


#pragma mark Internal Indexing Methods

- (void) submitReadDashPreferencesTask {
	LOG_INFO(@"Reading docset descriptions from Dash preferences...");
	
	[fileSystemListener setDashPreferencesPath:[DRReadDashPreferencesTask dashPreferencesPath]];
	
	[workQueue addOperation:[DRReadDashPreferencesTask readDashPreferences:^(NSArray *docsetDescriptors) {
		NSSet *docsetDescriptorSet = [NSSet setWithArray:docsetDescriptors];
		if([docsetDescriptorSet isEqualToSet:self.mostRecentDocsetDescriptors]) {
			LOG_DEBUG(@"Finished reading docset descriptions, no changes found");
			
			[self finishIndexing];
			return;
		}
		
		self.mostRecentDocsetDescriptors = docsetDescriptorSet;
		[fileSystemListener setDocsetDescriptors:self.mostRecentDocsetDescriptors];
		[self indexDocsets];
	}]];
}

- (void) indexDocsets {
	LOG_INFO(@"Indexing docsets...");
	
	@synchronized(indexInProgressLock) {
		[mergedIndexInProgress removeAllObjects];
	}
	
	NSOperation *handleCompletionOperation = [NSBlockOperation blockOperationWithBlock:^{
		[self handleIndexCompletion];
	}];
	
	[self queueIndexTasks:handleCompletionOperation];
	[workQueue addOperation:handleCompletionOperation];
}

- (void) queueIndexTasks:(NSOperation*)finishOperation {
	[self.mostRecentDocsetDescriptors each:^(DRDocsetDescriptor *docsetDescriptor) {
		DRDocsetIndexTask *task = [self createIndexTask:docsetDescriptor];
		if(!task)
			return;
		
		[workQueue addOperation:task.operation];
		
		NSOperation *resultOperation = [NSBlockOperation blockOperationWithBlock:^{
			[self handleIndexResult:task];
		}];
		[resultOperation addDependency:task.operation];
		[workQueue addOperation:resultOperation];
		
		[finishOperation addDependency:resultOperation];
	}];
}

- (DRDocsetIndexTask*) createIndexTask:(DRDocsetDescriptor*)docsetDescriptor {
	if(docsetDescriptor.type != DRDocsetTypeJava)
		return nil;
	
	if(docsetDescriptor.dashFormat)
		return [[[DRDashDocsetIndexTask alloc] initWithDocsetDescriptor:docsetDescriptor] autorelease];
	
	return [[[DRAppleDocsetIndexTask alloc] initWithDocsetDescriptor:docsetDescriptor] autorelease];
}

- (void) handleIndexResult:(DRDocsetIndexTask*)task {
	@synchronized(indexInProgressLock) {
		[mergedIndexInProgress mergeTrees:task.result];
	}
}

- (void) handleIndexCompletion {
	NSDictionary *mergedResults;
	@synchronized(indexInProgressLock) {
		mergedResults = [NSDictionary dictionaryWithDictionary:mergedIndexInProgress];
	}
	
#if DEBUG
	__block int memberCount = 0;
	[mergedResults visitLeaves:^(DRTypeInfo *typeInfo) {
		memberCount += [typeInfo.members count];
	}];
	
	LOG_INFO(@"Done indexing, found: %ld classes, %ld members", (long)[mergedResults deepCount], (long)memberCount);
#endif
	
	[self doLocked:indexPublishCondition execute:^{
		[indexResults release];
		indexResults = [mergedResults retain];
		
		[indexPublishCondition signal];
	}];
	
	[self finishIndexing];
}

- (void) finishIndexing {
	BOOL shouldSubmitReadDashPreferencesTask = NO;
	@synchronized(indexStatusLock) {
		if(indexQueued) {
			LOG_DEBUG(@"Indexing task was queued, running again");
			
			indexQueued = NO;
			shouldSubmitReadDashPreferencesTask = YES;
		} else
			indexing = NO;
	}
	
	if(shouldSubmitReadDashPreferencesTask)
		[self submitReadDashPreferencesTask];
}


#pragma mark - Search Methods
#pragma mark Public Search Methods

- (DRTypeInfo*) searchUrl:(NSURL*)url {
	[self awaitIndexResults];
	
	NSArray *pathComponents = [[[url path] stringByDeletingPathExtension] pathComponents];
	return [indexResults objectForSequenceRelativeTo:pathComponents];
}

#pragma mark Internal Search Methods

- (void) awaitIndexResults {
	// We don't care that much about the results being stale, the property is atomic
	// and will never again be nil, so this should be ok.
	if(indexResults)
		return;
	
	[self doLocked:indexPublishCondition execute:^{
		while(!indexResults)
			[indexPublishCondition wait];
	}];
}


#pragma mark - Internal Utility methods

- (void) doLocked:(id<NSLocking>)lock execute:(void(^)(void))callback {
	[lock lock];
	callback();
	[lock unlock];
}


#pragma mark Instance Lifecycle Methods

- (id) init {
	[NSException raise:kDRUnsupportedOperationException format:@"use initWithType:"];
	return nil;
}

- (void) dealloc {
	[workQueue release];
	[fileSystemListener release];
	[indexStatusLock release];
	[indexInProgressLock release];
	[indexPublishCondition release];
	[indexResults release];
	[mergedIndexInProgress release];
	
	self.mostRecentDocsetDescriptors = nil;
	
	[super dealloc];
}

@end
