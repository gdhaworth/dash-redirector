//
//  DRBrowserInfo.m
//  DashRedirector
//
//  Created by Graham Haworth on 7/7/13.
//  Copyright (c) 2013 Graham Haworth. All rights reserved.
//

#import "DRBrowserInfo.h"


#define kDRTry1BundleNameKey @"CFBundleName"
#define kDRTry2BundleNameKey @"CFBundleDisplayName"


@interface DRBrowserInfo ()

#define PROPERTY(NAME, TYPE) @property(nonatomic, readwrite, retain) TYPE * NAME;
#include "DRBrowserInfo.inc"
#undef PROPERTY

@end


@implementation DRBrowserInfo

#define PROPERTY(NAME, TYPE) @synthesize NAME;
#include "DRBrowserInfo.inc"
#undef PROPERTY

+ (DRBrowserInfo*) browserInfoFromUrl:(NSURL*)browserAppUrl {
	return [self browserInfoFromUrl:browserAppUrl loadAppIcon:YES];
}

+ (DRBrowserInfo*) browserInfoFromUrl:(NSURL*)browserAppUrl loadAppIcon:(BOOL)loadIcon {
	DRBrowserInfo *browserInfo = [[[DRBrowserInfo alloc] init] autorelease];
	browserInfo.url = browserAppUrl;
	browserInfo.bundle = [NSBundle bundleWithURL:browserAppUrl];
	[browserInfo setup:loadIcon];
	return browserInfo;
}

+ (DRBrowserInfo*) browserInfoFromBundle:(NSBundle*)browserBundle {
	return [self browserInfoFromBundle:browserBundle loadAppIcon:YES];
}

+ (DRBrowserInfo*) browserInfoFromBundle:(NSBundle*)browserBundle loadAppIcon:(BOOL)loadIcon {
	DRBrowserInfo *browserInfo = [[[DRBrowserInfo alloc] init] autorelease];
	browserInfo.bundle = browserBundle;
	browserInfo.url = browserBundle.bundleURL;
	[browserInfo setup:loadIcon];
	return browserInfo;
}

- (void) setup:(BOOL)loadIcon {
	self.displayName = [self findAppDisplayName];
	
	if(loadIcon)
		self.icon = [self findAppIcon];
}

- (NSString*) findAppDisplayName {
	NSDictionary *bundleInfo = self.bundle.infoDictionary;
	NSString *name = [bundleInfo objectForKey:kDRTry1BundleNameKey];
	if(NSStringIsNullOrEmpty(name))
		name = [bundleInfo objectForKey:kDRTry2BundleNameKey];
	if(NSStringIsNullOrEmpty(name))
		name = [[self.bundle.bundlePath lastPathComponent] stringByDeletingPathExtension];
	return name;
}

- (NSImage*) findAppIcon {
	NSString *iconPath = [self findIconPathInBundle];
	
	if(!iconPath)
		return nil;
	
	return [[[NSImage alloc] initByReferencingFile:iconPath] autorelease];
}

- (NSString*) findIconPathInBundle {
	NSString *iconFileName = [self bundleIconFileName];
	if(!iconFileName)
		return nil;
	
	NSArray *contents = [self contentsAtPath:[self.bundle resourcePath]];
	
	NSString *filename = [contents match:^BOOL(NSString *filename) {
		if([iconFileName isEqualToString:filename])
			return YES;
		
		if(![iconFileName isEqualToString:[filename stringByDeletingPathExtension]])
			return NO;
		
		NSString *pathExtension = [[filename pathExtension] lowercaseString];
		if(NSStringIsNullOrEmpty(pathExtension)) {
			NSString *fullPath = [[self.bundle resourcePath] stringByAppendingPathComponent:filename];
			LOG_WARN(@"found a resource matching icon name without a path extension: %@", fullPath);
			return NO;
		}
		
		return [SupportedImageFileTypes() containsObject:pathExtension];
	}];
	
	if(NSStringIsNullOrEmpty(filename)) {
		LOG_WARN(@"Icon file missing for bundle at '%@'", [self.bundle bundlePath]);
		return nil;
	}
	
	return [[self.bundle resourcePath] stringByAppendingPathComponent:filename];
}

- (NSString*) bundleIconFileName {
	NSString *iconFileName = [self.bundle objectForInfoDictionaryKey:@"CFBundleIconFile"];
	if(NSStringIsNullOrEmpty(iconFileName)) {
		LOG_WARN(@"Failed to find an icon file name for bundle at '%@'", [self.bundle bundlePath]);
		return nil;
	}
	return iconFileName;
}

- (NSArray*) contentsAtPath:(NSString*)path {
	NSError *err = nil;
	NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:&err];
	if(err) {
		[NSException raise:kDROperationFailedException
					format:@"Failed to list contents of '%@' with error %@", path, err];
		return nil;
	}
	return contents;
}

- (BOOL)isEqual:(id)anObject {
	if(![anObject isKindOfClass:[DRBrowserInfo class]])
		return NO;
	
	return [self.bundle.bundleIdentifier isEqualToString:((DRBrowserInfo*)anObject).bundle.bundleIdentifier];
}

- (NSUInteger) hash {
	return [self.url hash];
}

- (NSString*) description {
	return [NSString stringWithFormat:@"%@[displayName='%@', url='%@']", [self class], self.displayName, self.url];
}

- (void) dealloc {
#define PROPERTY(NAME, TYPE) \
self.NAME = nil;
#include "DRBrowserInfo.inc"
#undef PROPERTY
	
	[super dealloc];
}

NSSet* SupportedImageFileTypes(void) {
	static dispatch_once_t onceToken;
	static NSSet *imageFileTypes;
	dispatch_once(&onceToken, ^{
		imageFileTypes = ComputeSupportedImageFileTypes();
	});
	return imageFileTypes;
}

NSSet* ComputeSupportedImageFileTypes(void) {
	NSArray *fileTypes = [NSImage imageUnfilteredFileTypes];
	NSMutableSet *selectedTypes = [NSMutableSet setWithCapacity:[fileTypes count]];
	NSCharacterSet *nonAlphanumeric = [[NSCharacterSet alphanumericCharacterSet] invertedSet];
	[fileTypes each:^(NSString *fileType) {
		if([fileType rangeOfCharacterFromSet:nonAlphanumeric].location != NSNotFound)
			return;
		
		[selectedTypes addObject:[fileType lowercaseString]];
	}];
	
	return [[NSSet alloc] initWithSet:selectedTypes];
}

@end
