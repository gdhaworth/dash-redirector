//
//  DRFileSystemEvent.h
//  DashRedirector
//
//  Created by Graham Haworth on 7/5/13.
//  Copyright (c) 2013 Graham Haworth. All rights reserved.
//

typedef struct {
	NSString *path;
	FSEventStreamEventFlags flags;
	FSEventStreamEventId eventId;
} DRFileSystemEvent;
