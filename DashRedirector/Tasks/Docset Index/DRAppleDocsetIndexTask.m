//
//  DRAppleDocsetIndexTask.m
//  DashRedirector
//
//  Created by Graham Haworth on 7/2/13.
//  Copyright (c) 2013 Graham Haworth. All rights reserved.
//

#import "DRAppleDocsetIndexTask.h"
#import "FMDatabase.h"
#import "NSMutableDictionary+DRTreeNode.h"


#warning TODO: check type/member list is complete
#define kTypeSelectQuery @"SELECT fp.ZPATH, t.ZTOKENNAME, fp.Z_PK AS FILE_ID FROM ZFILEPATH fp INNER JOIN ZTOKENMETAINFORMATION tmi ON fp.Z_PK = tmi.ZFILE INNER JOIN ZTOKEN t ON tmi.ZTOKEN = t.Z_PK INNER JOIN ZTOKENTYPE tt ON t.ZTOKENTYPE = tt.Z_PK WHERE tt.ZTYPENAME IN ('cl', 'Interface', 'Enum', 'Exception', 'Error')"
#define kMemberSelectQuery @"SELECT t.ZTOKENNAME, tmi.ZANCHOR FROM ZTOKEN t INNER JOIN ZTOKENMETAINFORMATION tmi ON t.Z_PK = tmi.ZTOKEN INNER JOIN ZTOKENTYPE tt ON t.ZTOKENTYPE = tt.Z_PK WHERE tt.ZTYPENAME IN ('instm', 'intfm', 'Constructor', 'clm', 'Field') AND tmi.ZANCHOR IS NOT NULL AND tmi.ZANCHOR <> '' AND tmi.ZFILE = ?"
#warning TODO: package


@implementation DRAppleDocsetIndexTask

- (id) initWithDocsetDescriptor:(DRDocsetDescriptor*)docsetDescriptor {
	self = [super initWithDocsetDescriptor:docsetDescriptor];
	return self;
}

- (NSArray*) readTypes {
	return [self openDatabase:self.docsetDescriptor.sqliteIndexPath callback:^id(FMDatabase *db) {
		FMResultSet *resultSet = [db executeQuery:kTypeSelectQuery];
		return [self mapTypeInfoResultSet:resultSet nameColumn:@"ZTOKENNAME" pathColumn:@"ZPATH" callback:^(DRTypeInfo *typeInfo) {
			[self readMembersIntoTypeInfo:typeInfo withDatabase:db andTypeResultSet:resultSet];
		}];
	}];
}

- (void) readMembersIntoTypeInfo:(DRTypeInfo*)typeInfo withDatabase:(FMDatabase*)database andTypeResultSet:(FMResultSet*)typeResultSet {
	id fileId = [typeResultSet objectForColumnName:@"FILE_ID"];
	FMResultSet *memberResultSet = [database executeQuery:kMemberSelectQuery, fileId];
	[self mapMemberInfoResultSet:memberResultSet nameColumn:@"ZTOKENNAME" anchorColumn:@"ZANCHOR" callback:^(DRMemberInfo *memberInfo) {
		[typeInfo addMember:memberInfo];
	}];
}

@end
