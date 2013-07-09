//
//  DRPreferencesWindowController.h
//  DashRedirector
//
//  Created by Graham Haworth on 7/4/13.
//  Copyright (c) 2013 Graham Haworth. All rights reserved.
//

#import <Foundation/Foundation.h>


@class DRBrowserInfo;


@interface DRPreferencesWindowController : NSWindowController

@property (nonatomic, retain) NSMutableArray *browsers;
@property (nonatomic, retain) NSMutableIndexSet *selectedBrowserIndexes;

@property (nonatomic, retain) IBOutlet NSView *lastComponentBeforeDefaultBrowserScrollView;

@property (nonatomic, retain) IBOutlet NSButton *dashIsDefaultCheckbox;

@property (nonatomic, retain) IBOutlet NSArrayController *browserArrayController;

@property (nonatomic, retain) IBOutlet NSScrollView *defaultBrowserScrollView;
@property (nonatomic, retain) IBOutlet NSTextField *defaultBrowserCollectionViewLabel;

@end
