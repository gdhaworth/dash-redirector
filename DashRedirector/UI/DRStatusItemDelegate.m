//
//  DRStatusItemDelegate.m
//  DashRedirector
//
//  Created by Graham Haworth on 7/4/13.
//  Copyright (c) 2013 Graham Haworth. All rights reserved.
//

#import "DRStatusItemDelegate.h"


@interface DRStatusItemDelegate () {
	IBOutlet NSMenu *statusMenu;
	NSStatusItem *statusItem;
}

@end


@implementation DRStatusItemDelegate

- (void) awakeFromNib {
	statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength] retain];
	statusItem.menu = statusMenu;
	statusItem.title = @"DR"; // TODO image
	statusItem.highlightMode = YES;
}

@end
