//
//  DRDocsetIndexTask.m
//  DashRedirector
//
//  Created by Graham Haworth on 7/1/13.
//  Copyright (c) 2013 Graham Haworth. All rights reserved.
//

#import "DRDocsetIndexTask.h"
#import "DRTypeInfo.h"
#import "FMDatabase.h"
#import "NSMutableDictionary+DRTreeNode.h"
#import "DRExceptions.h"


@interface DRDocsetIndexTask ()

@property (atomic, readwrite, retain) DRDocsetDescriptor *docsetDescriptor;
@property (atomic, readwrite, retain) NSOperation *operation;
@property (atomic, readwrite, retain) NSDictionary *result;

@property (atomic, readwrite, retain) NSArray *pathPrefixComponents;

@end


@implementation DRDocsetIndexTask

@synthesize docsetDescriptor, operation, result;

- (id) initWithDocsetDescriptor:(DRDocsetDescriptor*)docset {
	self = [super init];
	if(self) {
		self.docsetDescriptor = [docset retain];
		self.operation = [[NSBlockOperation blockOperationWithBlock:^{
			[self doIndex];
		}] retain];
		self.pathPrefixComponents = [[self computePathPrefixComponents] retain];
	}
	return self;
}

- (NSArray*) computePathPrefixComponents {
	NSString *pathPrefix = [self.docsetDescriptor.dashIndexFilePath stringByDeletingLastPathComponent];
	if([pathPrefix length] == 0)
		return [NSArray array];
	return [pathPrefix pathComponents];
}

- (void) doIndex {
	NSArray *components = [self readTypes];
	self.result = [self createPathTree:components];
}

- (NSArray*) readTypes {
	[NSException raise:kDRUnimplementedMethodException format:@"subclasses must implement readComponents"];
	return nil;
}

- (NSDictionary*) createPathTree:(NSArray*)components {
	NSMutableDictionary *pathTree = [NSMutableDictionary dictionary];
	for(DRTypeInfo *component in components)
		[pathTree setObject:component forChildSequence:[self cleanAndSplitPathComponents:component.path]];
	
//	// TEMP
//	NSLog(@"\n\npathTree: %@\n%@", self.docsetDescriptor.name, [pathTree description]);
	
	return pathTree;
}

- (NSArray*) cleanAndSplitPathComponents:(NSString*)path {
	NSArray *pathComponents = [[path stringByDeletingPathExtension] pathComponents];
	for(NSString *pathPrefixComponent in self.pathPrefixComponents) {
		NSString *firstPathComponent = [pathComponents objectAtIndex:0];
		if([firstPathComponent isEqual:pathPrefixComponent]) {
			NSRange subRange = NSMakeRange(1, [pathComponents count] - 1);
			pathComponents = [pathComponents subarrayWithRange:subRange];
		} else {
			DRLog(@"WARN - pathPrefixComponent '%@' did not match firstPathComponent '%@' for path '%@'",
				  pathPrefixComponent, firstPathComponent, path);
			break;
		}
	}
	return pathComponents;
}


#pragma mark - SQLite/FMDatabase Utilities

- (id) openDatabase:(NSString*)path callback:(id(^)(FMDatabase*))callback {
	FMDatabase *database = [FMDatabase databaseWithPath:path];
	if(!database) {
#warning TODO: handle error
		DRLog(@"failed create FMDatabase for path: %@", path);
		return nil;
	}
	
	BOOL opened = [database openWithFlags:SQLITE_OPEN_READONLY];
	if (!opened) {
		[database release];
		
#warning TODO: handle error
		DRLog(@"failed to open database at path: %@", path);
		return nil;
	}
	
	id callbackResult = callback(database);
	
	[database close];
	
	return callbackResult;
}

- (NSArray*) mapTypeInfoResultSet:(FMResultSet*)resultSet
					   nameColumn:(NSString*)nameColumn
					   pathColumn:(NSString*)pathColumn
						 callback:(void(^)(DRTypeInfo*))typeInfoCallback {
	
	return [self collectResults:resultSet rowCallback:^id {
		NSString *name = [resultSet stringForColumn:nameColumn];
		NSString *path = [resultSet stringForColumn:pathColumn];
		DRTypeInfo *typeInfo = [DRTypeInfo typeInfoWithName:name andPath:path andDocsetDescriptor:self.docsetDescriptor];
		if(typeInfoCallback)
			typeInfoCallback(typeInfo);
		return typeInfo;
	}];
}

- (NSArray*) mapMemberInfoResultSet:(FMResultSet*)resultSet
						 nameColumn:(NSString*)nameColumn
					   anchorColumn:(NSString*)anchorColumn
						   callback:(void(^)(DRMemberInfo*))callback {
	
	return [self collectResults:resultSet rowCallback:^id {
		NSString *name = [resultSet stringForColumn:nameColumn];
		NSString *anchor = [resultSet stringForColumn:anchorColumn];
		DRMemberInfo *memberInfo = [DRMemberInfo memberInfoWithName:name andAnchor:anchor];
		if(callback)
			callback(memberInfo);
		return memberInfo;
	}];
}

- (NSArray*) collectResults:(FMResultSet*)resultSet rowCallback:(id(^)(void))callback {
	NSMutableArray *results = [NSMutableArray array];
	while([resultSet next]) {
		id rowResult = callback();
		if(rowResult)
			[results addObject:rowResult];
	}
	return results;
}


#pragma mark - Other Lifecycle

- (id) init {
	[NSException raise:kDRUnsupportedOperationException format:@"use initWithDocset:"];
	return nil;
}

- (void) dealloc {
	self.docsetDescriptor = nil;
	self.operation = nil;
	self.result = nil;
	self.pathPrefixComponents = nil;
	
	[super dealloc];
}

@end
