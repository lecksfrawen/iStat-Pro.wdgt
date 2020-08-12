//
//  DataMinerBattery.m
//  iStat
//
//  Created by iSlayer on 17/04/07.
//  Copyright 2007 iSlayer & Distorted Vista. All rights reserved.
//

#define kBatteryUnknown -1
#define kBatteryStateCharged 0
#define kBatteryStateCharging 1
#define kBatteryStateDraining 2
#define kBatteryStateNA 4
#define kBatterySourceBattery 0
#define kBatterySourceAC 1
#define kBatteryTimeCalculating -1
#define kBatteryTimeCharged -2

#import "ISPDataMinerBattery.h"

@implementation ISPDataMinerBattery

- (id)init {
	[self isLaptop];
	
	return self;
}

- (void) dealloc {
	
	[super dealloc];
}


- (BOOL) isLaptop {
	SInt32 machineName;
	Gestalt(gestaltUserVisibleMachineName, &machineName);
	NSString *theString = [NSString stringWithCString:(char *)machineName];
	NSString *substring = @"PowerBook";
	NSRange range = [theString rangeOfString:substring];
	int length = range.length;
	if(length){
		type = 0;
		return YES;
	} else {
		range = [theString rangeOfString:@"MacBook"];
		length = range.length;
		if(length){
			type = 1;
			return YES;
		} else {
			type = -1;
			return NO;
		}
	}
	type = -1;
	return NO;
}

- (NSArray *)getDataSet {
	if(type == 0){
		return [self getIOBattery];
	} else if(type == 1) {
		return [self getSmartBattery];
	}
	return [NSArray array];
}

- (NSArray *)getSmartBattery {
	float percentage = 0;
	float currentCapacity = 0;
	float capacityPercent = 0;
	float maxCapacity = 0;
	int cycles = 0;
	int status = kBatteryUnknown;
	int source = kBatteryUnknown;
	int time = kBatteryUnknown;
    io_iterator_t    sensorsIterator;
    
    kern_return_t ioStatus = IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceNameMatching("AppleSmartBattery"), &sensorsIterator);
    if (ioStatus == kIOReturnSuccess) {    
		io_object_t sensorObject;
		while (sensorObject = IOIteratorNext(sensorsIterator)) {
			NSMutableDictionary *sensorData;
			ioStatus = IORegistryEntryCreateCFProperties(sensorObject, (CFMutableDictionaryRef *)&sensorData, kCFAllocatorDefault, kNilOptions);
			if (ioStatus != kIOReturnSuccess) {
				IOObjectRelease(sensorObject);
				continue;
			}
			
			percentage = ([[sensorData objectForKey:@"CurrentCapacity"] floatValue] / [[sensorData objectForKey:@"MaxCapacity"] floatValue]) * 100;
			
			maxCapacity = [[sensorData objectForKey:@"DesignCapacity"] intValue];
			currentCapacity = [[sensorData objectForKey:@"MaxCapacity"] floatValue];
			capacityPercent = (currentCapacity / maxCapacity) * 100;
			if(capacityPercent > 100)
				capacityPercent = 100;
			
			cycles = [[sensorData objectForKey:@"CycleCount"] intValue];
			
			
			if([[sensorData objectForKey:@"ExternalConnected"]intValue] == 1)
				source = kBatterySourceAC;
			else
				source = kBatterySourceBattery;
			
			if([[sensorData objectForKey:@"FullyCharged"] intValue] == 1) {
				time = kBatteryTimeCharged;
				status = kBatteryStateCharged;
			} else if([[sensorData objectForKey:@"IsCharging"] intValue] == 1) {
				status = kBatteryStateCharging;
				if([[sensorData objectForKey:@"Amperage"] intValue] > 0)
					time = [[sensorData objectForKey:@"TimeRemaining"] intValue];
				else
					time = kBatteryTimeCalculating;
			} else if([[sensorData objectForKey:@"FullyCharged"] intValue] == 0 && [[sensorData objectForKey:@"IsCharging"] intValue] == 0 && [[sensorData objectForKey:@"Amperage"] intValue] == 0){
				time = kBatteryTimeCharged;
				status = kBatteryStateCharged;
			} else {
				status = kBatteryStateDraining;
				if([[sensorData objectForKey:@"Amperage"] intValue] < 0)
					time = [[sensorData objectForKey:@"TimeRemaining"] intValue];
				else
					time = kBatteryTimeCalculating;
			}
			CFRelease(sensorData);
			IOObjectRelease(sensorObject);
		}
		IOObjectRelease(sensorsIterator);	
	}
	
	
	NSString *timeString;
	NSString *statusString;
	NSString *sourceString;
	
	if(status == kBatteryStateCharged)
		statusString = @"Charged";
	else if(status == kBatteryStateCharging)
		statusString = @"Charging";
	else if(status == kBatteryStateDraining)
		statusString = @"Draining";
	else
		statusString = @"Unknown";
	
	if(source == kBatterySourceBattery)
		sourceString = @"Battery";
	else if(source == kBatterySourceAC)
		sourceString = @"AC Power";
	else
		sourceString = @"Unknown";
	
	if(time == kBatteryTimeCalculating)
		timeString = @"Calculating";
	else if(time == kBatteryTimeCharged)
		timeString = @"Charged";
	else if(time > 0){
		int hours = 0;
		hours = time / (60);
		time %= (60);
		if(time < 10){
			timeString = [NSString stringWithFormat:@"%i:0%i remaining", hours, time];
		} else {
			timeString = [NSString stringWithFormat:@"%i:%i remaining", hours, time];
		}
	} else
		timeString = @"Unknown";
	
	NSString *cycleString = [NSString stringWithFormat:@"%i", cycles];
	NSString *percentageString = [NSString stringWithFormat:@"%.0f%%", percentage];
	NSString *health = [NSString stringWithFormat:@"%.0f%%", capacityPercent];
	
	return [NSArray arrayWithObjects:timeString, percentageString, sourceString, statusString, cycleString, health, nil];
	
}

- (NSArray *)getIOBattery {
	float percentage = 0;
	int status = kBatteryUnknown;
	int source = kBatteryUnknown;
	int time = kBatteryUnknown;
	
	NSArray *powerSources = (NSArray *)IOPSCopyPowerSourcesList( IOPSCopyPowerSourcesInfo());
    NSEnumerator *powerEnumerator = [powerSources objectEnumerator];
    CFTypeRef itemRef;
	
	while(itemRef = [powerEnumerator nextObject]){
		NSDictionary *itemData = (NSDictionary *)IOPSGetPowerSourceDescription(IOPSCopyPowerSourcesInfo(), itemRef);
        if([[itemData objectForKey:@"Transport Type"] isEqualToString: @"Internal"]){
			percentage = [[itemData objectForKey:@"Current Capacity"] intValue];
			if([[itemData objectForKey:@"Power Source State"] isEqualToString:@"AC Power"]){
				source = kBatterySourceAC;
				if([[itemData objectForKey:@"Time to Full Charge"] intValue] < 0){
					if([[itemData objectForKey:@"Is Charging"] intValue] == 0){
						time = kBatteryTimeCharged;
						status = kBatteryStateCharged;
					} else {
						time = kBatteryTimeCalculating;
						status = kBatteryStateCharging;
					}
				} else {
					status = kBatteryStateCharging;
					time = [[itemData objectForKey:@"Time to Full Charge"] intValue];
				}
			}
			if([[itemData objectForKey:@"Power Source State"] isEqualToString:@"Battery Power"]){
				source = kBatterySourceBattery;
				if([[itemData objectForKey:@"Time to Empty"] intValue] < 0){
					time = kBatteryTimeCalculating;
					status = kBatteryStateDraining;
				} else {
					status = kBatteryStateDraining;
					time = [[itemData objectForKey:@"Time to Empty"] intValue];
				}
			}
			break;
		}
    }
	NSString *timeString;
	NSString *statusString;
	NSString *sourceString;
	
	if(status == kBatteryStateCharged)
		statusString = @"Charged";
	else if(status == kBatteryStateCharging)
		statusString = @"Charging";
	else if(status == kBatteryStateDraining)
		statusString = @"Draining";
	else
		statusString = @"Unknown";
	
	if(source == kBatterySourceBattery)
		sourceString = @"Battery";
	else if(source == kBatterySourceAC)
		sourceString = @"AC Power";
	else
		sourceString = @"Unknown";
	
	if(time == kBatteryTimeCalculating)
		timeString = @"Calculating";
	else if(time == kBatteryTimeCharged)
		timeString = @"Charged";
	else if(time > 0){
		int hours = 0;
		hours = time / (60);
		time %= (60);
		if(time < 10){
			timeString = [NSString stringWithFormat:@"%i:0%i remaining", hours, time];
		} else {
			timeString = [NSString stringWithFormat:@"%i:%i remaining", hours, time];
		}
	} else
		timeString = @"Unknown";
	
	[self updatePPCInfo];
	
	NSString *cycleString = [NSString stringWithFormat:@"%i", PPCcycleCount];
	NSString *percentageString = [NSString stringWithFormat:@"%.0f%%", percentage];
	NSString *health = [NSString stringWithFormat:@"%.0f%%", PPChealthPercentage];
	
	
	return [NSArray arrayWithObjects:timeString, percentageString, sourceString, statusString, cycleString, health, nil];
}

- (void)updatePPCInfo {
	PPCcycleCount = 0;
	PPChealthPercentage = 0;
	PPCcurrentCapacity = 0;
	
	BOOL found = NO;
    kern_return_t    ioStatus;
    io_iterator_t    sensorsIterator;
	
    ioStatus = IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceMatching("IOPMrootDomain"), &sensorsIterator);
	
    if (ioStatus == kIOReturnSuccess) {
		io_object_t sensorObject;
		while (sensorObject = IOIteratorNext(sensorsIterator)) {
			NSMutableDictionary *sensorData;
			ioStatus = IORegistryEntryCreateCFProperties(sensorObject, (CFMutableDictionaryRef *)&sensorData, kCFAllocatorDefault, kNilOptions);
			if([sensorData objectForKey:@"IOBatteryInfo"] && ([[[sensorData objectForKey:@"IOBatteryInfo"] objectAtIndex:0] count] > 0)){
				found = YES;
				
				PPCcycleCount = [[[[sensorData objectForKey:@"IOBatteryInfo"] objectAtIndex:0] objectForKey:@"Cycle Count"] intValue];
				
				PPChealthPercentage = ([[[[sensorData objectForKey:@"IOBatteryInfo"] objectAtIndex:0] objectForKey:@"Capacity"] floatValue] / [[[[sensorData objectForKey:@"IOBatteryInfo"] objectAtIndex:0] objectForKey:@"AbsoluteMaxCapacity"] floatValue]) * 100;
				if(PPChealthPercentage > 100)
					PPChealthPercentage = 100;
				
				PPCcurrentCapacity = [[[[sensorData objectForKey:@"IOBatteryInfo"] objectAtIndex:0] objectForKey:@"Capacity"] intValue];
			}
			[sensorData release];
			IOObjectRelease(sensorObject);
		}
		IOObjectRelease(sensorsIterator);	
	}
	
	if(!found){
		ioStatus = IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceMatching("AppleSMUDevice"), &sensorsIterator);
		if (ioStatus == kIOReturnSuccess) {
			io_object_t sensorObject;
			while (sensorObject = IOIteratorNext(sensorsIterator)) {
				NSMutableDictionary *sensorData;
				ioStatus = IORegistryEntryCreateCFProperties(sensorObject, (CFMutableDictionaryRef *)&sensorData, kCFAllocatorDefault, kNilOptions);
				if([sensorData objectForKey:@"IOBatteryInfo"] && ([[[sensorData objectForKey:@"IOBatteryInfo"] objectAtIndex:0] count] > 0)){
					found = YES;
					
					PPCcycleCount = [[[[sensorData objectForKey:@"IOBatteryInfo"] objectAtIndex:0] objectForKey:@"Cycle Count"] intValue];
					
					PPChealthPercentage = ([[[[sensorData objectForKey:@"IOBatteryInfo"] objectAtIndex:0] objectForKey:@"Capacity"] floatValue] / [[[[sensorData objectForKey:@"IOBatteryInfo"] objectAtIndex:0] objectForKey:@"AbsoluteMaxCapacity"] floatValue]) * 100;
					if(PPChealthPercentage > 100)
						PPChealthPercentage = 100;
					
					PPCcurrentCapacity = [[[[sensorData objectForKey:@"IOBatteryInfo"] objectAtIndex:0] objectForKey:@"Capacity"] intValue];
				}
				[sensorData release];
				IOObjectRelease(sensorObject);
			}
			IOObjectRelease(sensorsIterator);	
		}
	}
	
	if(!found){
		ioStatus = IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceMatching("IOPMUPowerSource"), &sensorsIterator);
		
		if (ioStatus == kIOReturnSuccess) {
			io_object_t sensorObject;
			while (sensorObject = IOIteratorNext(sensorsIterator)) {
				NSMutableDictionary *sensorData;
				ioStatus = IORegistryEntryCreateCFProperties(sensorObject, (CFMutableDictionaryRef *)&sensorData, kCFAllocatorDefault, kNilOptions);
				if(sensorData){
					if([sensorData objectForKey:@"CycleCount"]){
						found = YES;
						
						// get cycle count
						PPCcycleCount = [[sensorData objectForKey:@"CycleCount"] intValue];
						
						NSDictionary *legacy = [sensorData objectForKey:@"LegacyBatteryInfo"];
						if(legacy){
							// calculate the battery health
							PPChealthPercentage = ([[legacy objectForKey:@"Capacity"] floatValue] / [[legacy objectForKey:@"AbsoluteMaxCapacity"] floatValue]) * 100;
							if(PPChealthPercentage > 100)
								PPChealthPercentage = 100;
							
							PPCcurrentCapacity = [[legacy objectForKey:@"Capacity"] intValue];
						}
					}
				}
				[sensorData release];
				IOObjectRelease(sensorObject);
			}
			IOObjectRelease(sensorsIterator);		
		}
	}
}

@end