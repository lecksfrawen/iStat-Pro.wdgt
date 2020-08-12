//
//  Controller.h
//  IntelSensors
//
//  Created by iSlayer on 17/04/07.
//  Copyright 2007 iSlayer & Distorted Vista. All rights reserved.

#import <Cocoa/Cocoa.h>
#import <smc.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <IOKit/IOKitLib.h>


@interface ISPIntelSensorController : NSObject {
	io_connect_t conn2;
	
	BOOL supported;
	NSMutableArray *availableKeys;
	NSMutableArray *supportedKeys;
	NSMutableDictionary *keyDisplayNames;
}

- (NSArray *)getFans;
- (BOOL)isSupported;
- (void)setKeys;
- (void)findSupportedKeys;
- (NSArray *)getFans;
- (NSString *)getFanName:(int)number;
- (NSDictionary *)getFanValues;
- (NSDictionary *)getTempValues;

@end
