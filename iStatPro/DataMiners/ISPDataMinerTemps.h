//
//  ISPDataMinerTemps.h
//  iStatMenusTemps
//
//  Created by iSlayer on 17/04/07.
//  Copyright 2007 iSlayer & Distorted Vista. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ISPIntelSensorController.h"
#import "defines.h"

@interface ISPDataMinerTemps : NSObject {
	NSMutableDictionary *_knownSensors;
	ISPIntelSensorController *intelClassInstance;
}

- (BOOL)isIntel;
- (void)setDictionaries;
- (NSArray *)getDataSet:(int)degrees;

@end
