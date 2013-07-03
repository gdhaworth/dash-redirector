//
//  DRGetUrlListener.h
//  DashRedirector
//
//  Created by Graham Haworth on 6/28/13.
//  Copyright (c) 2013 Graham Haworth. All rights reserved.
//

#import <Foundation/Foundation.h>


@class DRDocsetIndexer;


typedef void(^UrlCallback)(NSURL*);


@interface DRGetUrlListener : NSObject

- (id) initWithDocsetIndexer:(DRDocsetIndexer*)indexer;

- (void) registerAsEventHandler;

@end
