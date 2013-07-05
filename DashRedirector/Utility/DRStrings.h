//
//  DRStrings.h
//  DashRedirector
//
//  Created by Graham Haworth on 7/3/13.
//  Copyright (c) 2013 Graham Haworth. All rights reserved.
//

static inline BOOL NSStringIsNullOrEmpty(NSString *string) {
	return !string || string.length == 0;
}
