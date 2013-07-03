//
//  DRDocsetIndexTask.h
//  DashRedirector
//
//  Created by Graham Haworth on 7/1/13.
//  Copyright (c) 2013 Graham Haworth. All rights reserved.
//

#import "DRDocsetDescriptor.h"
#import "DRTypeInfo.h"
#import "DRMemberInfo.h"

#import <Foundation/Foundation.h>


@class FMDatabase;
@class FMResultSet;


@interface DRDocsetIndexTask : NSObject

- (id) initWithDocsetDescriptor:(DRDocsetDescriptor*)docsetDescriptor;

/* Subclasses should override. The expected result is a NSArray containing DRTypeInfos. */
- (NSArray*) readTypes;

- (id) openDatabase:(NSString*)path callback:(id(^)(FMDatabase*))callback;

- (NSArray*) mapTypeInfoResultSet:(FMResultSet*)resultSet
					   nameColumn:(NSString*)nameColumn
					   pathColumn:(NSString*)pathColumn
						 callback:(void(^)(DRTypeInfo*))callback;
- (NSArray*) mapMemberInfoResultSet:(FMResultSet*)resultSet
						 nameColumn:(NSString*)nameColumn
					   anchorColumn:(NSString*)anchorColumn
						   callback:(void(^)(DRMemberInfo*))callback;

@property (atomic, readonly) DRDocsetDescriptor *docsetDescriptor;
@property (atomic, readonly) NSOperation *operation;
@property (atomic, readonly) NSDictionary *result;

@end
