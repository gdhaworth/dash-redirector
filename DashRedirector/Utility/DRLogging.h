//
//  DRLogging.h
//  DashRedirector
//
//  Created by Graham Haworth on 7/4/13.
//  Copyright (c) 2013 Graham Haworth. All rights reserved.
//

// This sets up the debug configuration to log using the NSLogging utility.

#import "LoggerClient.h"


typedef enum {
	DRLogError = 0,
	DRLogWarning = 1,
	DRLogInfo = 2,
	DRLogDebug = 3,
	DRLogTrace = 4
} DRLogLevel;

static inline NSString* DRLogLevelText(DRLogLevel level) {
	switch(level) {
		case DRLogError: return @"ERROR";
		case DRLogWarning: return @"WARN";
		case DRLogInfo: return @"INFO";
		case DRLogDebug: return @"DEBUG";
		case DRLogTrace: return @"TRACE";
			
		default: return nil;
	}
}


#define LOG_ERROR(...) LOG_MESSAGE(DRLogError, __VA_ARGS__)
#define LOG_WARN(...)  LOG_MESSAGE(DRLogWarning, __VA_ARGS__)
#define LOG_INFO(...)  LOG_MESSAGE(DRLogInfo, __VA_ARGS__)
#define LOG_DEBUG(...) LOG_MESSAGE(DRLogDebug, __VA_ARGS__)
#define LOG_TRACE(...) LOG_MESSAGE(DRLogTrace, __VA_ARGS__)


#ifdef DEBUG
	#define LOGGER_OPTIONS	(kLoggerOption_BufferLogsUntilConnection | \
							 kLoggerOption_BrowseBonjour | \
							 kLoggerOption_BrowseOnlyLocalDomain | \
							 kLoggerOption_UseSSL)
	#define LOG_SETUP() LoggerSetOptions(LoggerGetDefaultLogger(), LOGGER_OPTIONS)
	#define LOG_FLUSH() LoggerFlush(NULL, NO)

	#define LOG_LINE() \
		do { \
			LogMarker([NSString stringWithUTF8String:__FUNCTION__]); \
			NSLog(@"%s", __PRETTY_FUNCTION__); \
		} while(0)

	#define LOG_MESSAGE(level, ...) \
		do { \
			LogMessageF(__FILE__, __LINE__, __FUNCTION__, DRLogLevelText(level), level, __VA_ARGS__); \
			NSLog(@"%s:\n%@", __PRETTY_FUNCTION__, [NSString stringWithFormat:__VA_ARGS__]); \
		} while(0)

#else
	#define DO_NOTHING do {} while(0)

	#define LOG_SETUP() DO_NOTHING
	#define LOG_FLUSH() DO_NOTHING
	#define LOG_LINE() DO_NOTHING
	#define LOG_MESSAGE(...) DO_NOTHING
#endif
