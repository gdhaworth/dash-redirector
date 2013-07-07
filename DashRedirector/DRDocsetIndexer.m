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
	BOOL readAndIndexQueued;
	BOOL reindexQueued;
	NSObject *indexStatusLock;
	
	NSMutableDictionary *mergedIndexInProgress;
	NSObject *indexInProgressLock;
	
	NSCondition *indexPublishCondition;
}

@property (atomic, retain) NSSet *mostRecentDocsetDescriptors;
@property (atomic, retain) NSDictionary *indexResults;

@end


@implementation DRDocsetIndexer

@synthesize mostRecentDocsetDescriptors, indexResults;

- (id) initWithWorkQueue:(NSOperationQueue*)queue {
	self = [super init];
	if(self) {
		workQueue = [queue retain];
		indexStatusLock = [[NSObject alloc] init];
		indexInProgressLock = [[NSObject alloc] init];
		indexPublishCondition = [[NSCondition alloc] init];
		
		mergedIndexInProgress = [[NSMutableDictionary alloc] init];
		indexing = NO;
		readAndIndexQueued = NO;
		reindexQueued = NO;
		
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
		readAndIndexQueued = YES;
	}
}

- (BOOL) startIndex {
	@synchronized(indexStatusLock) {
		if(indexing)
			return NO;
		
		indexing = YES;
	}
	
	[self submitReadDashPreferencesTask:NO];
	return YES;
}

- (void) reindexDocsets {
	BOOL start = NO;
	@synchronized(indexStatusLock) {
		if(indexing) {
			LOG_DEBUG(@"Index already running, queueing another re-index");
			
			reindexQueued = YES;
		} else {
			indexing = YES;
			start = YES;
		}
	}
	
	if(start)
		[self indexDocsets];
}


#pragma mark Internal Indexing Methods

- (void) submitReadDashPreferencesTask:(BOOL)forceReindex {
	LOG_INFO(@"Reading docset descriptions from Dash preferences...");
	
	[fileSystemListener setDashPreferencesPath:[DRReadDashPreferencesTask dashPreferencesPath]];
	
	[workQueue addOperation:[DRReadDashPreferencesTask readDashPreferences:^(NSArray *docsetDescriptors) {
		NSSet *docsetDescriptorSet = [NSSet setWithArray:docsetDescriptors];
		if(!forceReindex && [docsetDescriptorSet isEqualToSet:self.mostRecentDocsetDescriptors]) {
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
	
	[self submitDocsetIndexTasks:handleCompletionOperation];
	[workQueue addOperation:handleCompletionOperation];
}

- (void) submitDocsetIndexTasks:(NSOperation*)finishOperation {
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
		self.indexResults = mergedResults;
		
		[indexPublishCondition signal];
	}];
	
	[self finishIndexing];
}

- (void) finishIndexing {
	BOOL shouldSubmitReadDashPreferencesTask = NO;
	BOOL shouldReindex = NO;
	@synchronized(indexStatusLock) {
		if(readAndIndexQueued) {
			LOG_DEBUG(@"Read Dash docset descriptors task was queued, running again");
			
			readAndIndexQueued = NO;
			shouldSubmitReadDashPreferencesTask = YES;
		}
		
		if(reindexQueued) {
			LOG_DEBUG(@"Reindexing task was queued, running again");
			
			reindexQueued = NO;
			shouldReindex = YES;
		}
		
		if(!shouldSubmitReadDashPreferencesTask && !shouldReindex)
			indexing = NO;
	}
	
	if(shouldSubmitReadDashPreferencesTask)
		[self submitReadDashPreferencesTask:shouldReindex];
	else if(shouldReindex)
		[self indexDocsets];
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
	if(self.indexResults)
		return;
	
	[self doLocked:indexPublishCondition execute:^{
		while(!self.indexResults)
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
	[mergedIndexInProgress release];
	
	self.mostRecentDocsetDescriptors = nil;
	self.indexResults = nil;
	
	[super dealloc];
}

@end
