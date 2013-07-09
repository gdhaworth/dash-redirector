//
//  DRLockableClipView.m
//  DashRedirector
//
//  Created by Graham Haworth on 7/7/13.
//  Copyright (c) 2013 Graham Haworth. All rights reserved.
//

#import "DRLockableClipView.h"


@implementation DRLockableClipView

@synthesize scrollLocked;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.scrollLocked = NO;
    }
    
    return self;
}

- (void) scrollToPoint:(NSPoint)newOrigin {
	if(self.scrollLocked)
		return;
	
	[super scrollToPoint:newOrigin];
}

@end
