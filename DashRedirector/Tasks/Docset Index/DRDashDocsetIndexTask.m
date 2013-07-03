//
//  DRDashDocsetIndexTask.m
//  DashRedirector
//
//  Created by Graham Haworth on 7/2/13.
//  Copyright (c) 2013 Graham Haworth. All rights reserved.
//

#import "DRDashDocsetIndexTask.h"
#import "FMDatabase.h"
#import "NSMutableDictionary+DRTreeNode.h"
#import "DRExceptions.h"


#define kTypeSelectQuery @"SELECT name, path FROM searchIndex WHERE type IN ('Class', 'Enum', 'Error', 'Exception', 'Interface', 'Notation', 'Type')"
#define kMemberSelectQuery @"SELECT name, path FROM searchIndex WHERE type IN ('Attribute', 'Constant', 'Constructor', 'Field', 'Function', 'Method', 'Property', 'Variable')"
#warning TODO: use
#define kPackageSelectQuery @"SELECT name, path FROM searchIndex WHERE type = 'Package'"

#define kNameColumn @"name"
#define kPathColumn @"path"


@implementation DRDashDocsetIndexTask

- (id) initWithDocsetDescriptor:(DRDocsetDescriptor*)docsetDescriptor {
	self = [super initWithDocsetDescriptor:docsetDescriptor];
	return self;
}

- (NSArray*) readTypes {
	return [self openDatabase:self.docsetDescriptor.sqliteIndexPath callback:^id(FMDatabase *db) {
		FMResultSet *resultSet = [db executeQuery:kTypeSelectQuery];
		NSArray *types = [self mapTypeInfoResultSet:resultSet nameColumn:kNameColumn pathColumn:kPathColumn callback:NULL];
		
		NSDictionary *pathsToTypes = [self indexPathsToTypes:types];
		[self readMembersIntoTypeInfo:db andPathToTypeIndex:pathsToTypes];
		return types;
	}];
}

- (NSDictionary*) indexPathsToTypes:(NSArray*)types {
	NSMutableDictionary *index = [NSMutableDictionary dictionaryWithCapacity:[types count]];
	for(DRTypeInfo *type in types)
		[index setObject:type forKey:type.path];
	return index;
}

- (void) readMembersIntoTypeInfo:(FMDatabase*)database andPathToTypeIndex:(NSDictionary*)pathsToTypes {
	FMResultSet *memberResultSet = [database executeQuery:kMemberSelectQuery];
	[self collectResults:memberResultSet rowCallback:^id {
		NSString *name = [memberResultSet stringForColumn:kNameColumn];
		NSString *pathWithFragment = [memberResultSet stringForColumn:kPathColumn];
		
		NSURL *memberRelativeUrl = [NSURL URLWithString:pathWithFragment];
		NSString *path = memberRelativeUrl.path;
		NSString *anchor = [memberRelativeUrl.fragment stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		
		DRTypeInfo *typeInfo = [pathsToTypes objectForKey:path];
		if(!typeInfo) {
			DRLog(@"WARN - Unable to find typeInfo for member '%@' at '%@', parsed path: '%@'", name, pathWithFragment, path);
			return nil;
		}
		
		DRMemberInfo *memberInfo = [DRMemberInfo memberInfoWithName:name andAnchor:anchor];
		[typeInfo addMember:memberInfo];
		return nil;
	}];
}

@end
