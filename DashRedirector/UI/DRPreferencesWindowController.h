//
//  DRPreferencesWindowController.h
//  DashRedirector
//
//  Created by Graham Haworth on 7/4/13.
//  Copyright (c) 2013 Graham Haworth. All rights reserved.
//

#import "DRLockableClipView.h"

#import <Foundation/Foundation.h>


@class DRBrowserInfo;


@interface DRPreferencesWindowController : NSWindowController

@property (nonatomic, retain) NSMutableArray *browsers;
@property (nonatomic, retain) NSMutableIndexSet *selectedBrowserIndexes;

@property (nonatomic, retain) IBOutlet NSArrayController *browserArrayController;

@property (nonatomic, retain) IBOutlet NSCollectionView *defaultBrowserCollectionView;
@property (nonatomic, retain) IBOutlet NSScrollView *defaultBrowserScrollView;
@property (nonatomic, retain) IBOutlet DRLockableClipView *defaultBrowserClipView;
@property (nonatomic, retain) IBOutlet NSTextField *defaultBrowserCollectionViewLabel;

@end
