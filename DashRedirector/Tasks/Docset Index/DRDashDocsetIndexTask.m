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


#warning TODO: check type list is complete
#define kTypeSelectQuery @"SELECT name, path FROM searchIndex WHERE type IN ('Class', 'Interface', 'Notation', 'Enum', 'Exception', 'Error')"
#warning TODO: use
#define kPackageSelectQuery @"SELECT name, path FROM searchIndex WHERE type = 'Package'"


@implementation DRDashDocsetIndexTask

- (id) initWithDocsetDescriptor:(DRDocsetDescriptor*)docsetDescriptor {
	self = [super initWithDocsetDescriptor:docsetDescriptor];
	return self;
}

- (NSArray*) readTypes {
	return [self openDatabase:self.docsetDescriptor.sqliteIndexPath callback:^id(FMDatabase *db) {
		FMResultSet *resultSet = [db executeQuery:kTypeSelectQuery];
		return [self mapTypeInfoResultSet:resultSet nameColumn:@"name" pathColumn:@"path" callback:NULL];
	}];
}

@end
