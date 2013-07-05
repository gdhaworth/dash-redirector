//
//  DRThreads.h
//  DashRedirector
//
//  Created by Graham Haworth on 7/5/13.
//  Copyright (c) 2013 Graham Haworth. All rights reserved.
//

#define ASSERT_MAIN_THREAD() NSAssert([NSThread isMainThread], @"Not running in main thread")

static inline void DRForceMainThread(void(^block)(void)) {
	if([NSThread isMainThread])
		block();
	else
		[[NSOperationQueue mainQueue] addOperation:[NSBlockOperation blockOperationWithBlock:block]];
}