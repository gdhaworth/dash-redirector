#ifdef ASSIGN_PROPERTY
ASSIGN_PROPERTY(type, DRDocsetType)
ASSIGN_PROPERTY(dashFormat, BOOL)
#endif

#ifdef RETAIN_PROPERTY
RETAIN_PROPERTY(name, NSString, @"docsetName")
RETAIN_PROPERTY(keyword, NSString, @"keyword")
RETAIN_PROPERTY(basePath, NSString, @"docsetPath")
RETAIN_PROPERTY(sqliteIndexPath, NSString, @"docsetSQLPath")
RETAIN_PROPERTY(dashIndexFilePath, NSString, @"dashIndexFilePath")
#endif
