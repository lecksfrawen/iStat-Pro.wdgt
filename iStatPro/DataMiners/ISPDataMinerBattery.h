//
//  DataMinerBattery.h
//  iStat
//
//  Created by iSlayer on 17/04/07.
//  Copyright 2007 iSlayer & Distorted Vista. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ISPDataMinerBattery : NSObject {
	int type;
	int PPCcycleCount;
	float PPChealthPercentage;
	int PPCcurrentCapacity;
}

- (BOOL) isLaptop;
- (NSArray *)getDataSet;
- (NSArray *)getMBP;
- (NSArray *)getPB;
- (NSString *)getCycles;
- (void)updateCycles;

@end
