//
//  ISPDataMinerFans.h
//  iStatMenusFans
//
//  Created by iSlayer on 17/04/07.
//  Copyright 2007 iSlayer & Distorted Vista. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ISPIntelSensorController.h"


@interface ISPDataMinerFans : NSObject {
	NSMutableDictionary *fanSensorName;
	ISPIntelSensorController *intelClassInstance;
}

- (void)moduleInstalled;
- (NSArray *)sensors;
- (BOOL)isIntel;
- (BOOL)hasIntelBundle;
- (void)setDictionaries;
- (NSArray *)getDataSet;

@end
