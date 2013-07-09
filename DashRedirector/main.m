//
//  main.m
//  DashRedirector
//
//  Created by Graham Haworth on 6/28/13.
//  Copyright (c) 2013 Graham Haworth. All rights reserved.
//

#import "DRAppDelegate.h"

#import <Cocoa/Cocoa.h>


int main(int argc, char *argv[])
{
	LOG_SETUP();
	
	return NSApplicationMain(argc, (const char **)argv);
	
	LOG_FLUSH();
}
