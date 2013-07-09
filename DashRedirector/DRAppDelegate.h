//
//  DRAppDelegate.h
//  DashRedirector
//
//  Created by Graham Haworth on 6/28/13.
//  Copyright (c) 2013 Graham Haworth. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class DRDocsetIndexer;
@class DRPreferencesWindowController;


@interface DRAppDelegate : NSObject <NSApplicationDelegate>

- (IBAction) openPreferencesPanel:(id)sender;

@property (nonatomic, readonly) NSOperationQueue *workQueue;
@property (nonatomic, readonly) DRDocsetIndexer *docsetIndexer;

@property (nonatomic, retain) IBOutlet DRPreferencesWindowController *preferencesWindowController;

@end
