//
//  ISPDataMinerFans.m
//  iStatMenusFans
//
//  Created by iSlayer on 17/04/07.
//  Copyright 2007 iSlayer & Distorted Vista. All rights reserved.
//
// PPC stuff due for a major upgrade

#import "ISPDataMinerFans.h"

@implementation ISPDataMinerFans

- (void) dealloc {
	if(intelClassInstance)
		[intelClassInstance release];
	
	[fanSensorName release];
	
	[super dealloc];
}


- (id)init {
	self = [super init];
	
	
	intelClassInstance = nil;
	
	if([self isIntel])
		intelClassInstance = [[ISPIntelSensorController alloc] init];
	
	fanSensorName = [[NSMutableDictionary alloc] init];
	
	[self setDictionaries];
	
	return self;
}

- (BOOL)isIntel {
	long gestaltReturnValue;
	
	OSType returnType = Gestalt(gestaltSysArchitecture, &gestaltReturnValue);
	
	if(!returnType && gestaltReturnValue == gestaltIntel)
		return YES;
	return NO;
}

- (void)setDictionaries {
	[fanSensorName setObject:@"Hard Drive" forKey:@"Hard drive"];			
	[fanSensorName setObject:@"Drive Bay" forKey:@"DRIVE BAY A INTAKE"];			
	[fanSensorName setObject:@"Slots Intake" forKey:@"EXPANSION SLOTS INTAKE"];			
	[fanSensorName setObject:@"Rear Exhaust" forKey:@"REAR LEFT EXHAUST"];			
	[fanSensorName setObject:@"Right Exhaust" forKey:@"REAR RIGHT EXHAUST"];			
	[fanSensorName setObject:@"PCI Slots" forKey:@"PCI SLOTS"];			
	[fanSensorName setObject:@"CPU A Inlet" forKey:@"CPU A INLET"];			
	[fanSensorName setObject:@"CPU B Inlet" forKey:@"CPU B INLET"];			
	[fanSensorName setObject:@"CPU" forKey:@"CPU Fan"];			
	[fanSensorName setObject:@"Optical Drive" forKey:@"ODD Fan"];			
	[fanSensorName setObject:@"Hard Drive" forKey:@"HDD Fan"];			
	[fanSensorName setObject:@"System" forKey:@"System Fan"];			
	[fanSensorName setObject:@"Hard Drive" forKey:@"Hard Drive"];			
	[fanSensorName setObject:@"Rear Enclosure" forKey:@"REAR MAIN ENCLOSURE"];			
	[fanSensorName setObject:@"CPU B Pump" forKey:@"CPU B PUMP"];			
	[fanSensorName setObject:@"CPU A Pump" forKey:@"CPU A PUMP"];			
	[fanSensorName setObject:@"CPU A Intake" forKey:@"CPU A INTAKE"];			
	[fanSensorName setObject:@"CPU A Exhaust" forKey:@"CPU A EXHAUST"];			
	[fanSensorName setObject:@"CPU B Intake" forKey:@"CPU B INTAKE"];			
	[fanSensorName setObject:@"CPU B Exhaust" forKey:@"CPU B EXHAUST"];			
	[fanSensorName setObject:@"Drive Bay" forKey:@"DRIVE BAY"];			
	[fanSensorName setObject:@"Slots" forKey:@"SLOT"];			
	[fanSensorName setObject:@"Backside" forKey:@"BACKSIDE"];			
	[fanSensorName setObject:@"CPU" forKey:@"CPU fan"];			
	[fanSensorName setObject:@"Rear Fan 0" forKey:@"Rear Fan 0"];			
	[fanSensorName setObject:@"Rear Fan 1" forKey:@"Rear Fan 1"];			
	[fanSensorName setObject:@"Front Fan" forKey:@"Front fan"];			
	[fanSensorName setObject:@"Slots Fan" forKey:@"Slots fan"];			
	
	[fanSensorName setObject:@"HD/Expansion" forKey:@"IO"];
	[fanSensorName setObject:@"Exhaust" forKey:@"EXHAUST"];
	[fanSensorName setObject:@"Power Supply" forKey:@"PS"];
	[fanSensorName setObject:@"CPU Fan" forKey:@"CPU_MEM"];
	[fanSensorName setObject:@"Left Fan" forKey:@"Leftside"];
	[fanSensorName setObject:@"Right Fan" forKey:@"Rightside"];
	[fanSensorName setObject:@"Main Fan" forKey:@"Master"];
	[fanSensorName setObject:@"Optical Drive" forKey:@"ODD"];
	[fanSensorName setObject:@"CPU Fan" forKey:@"CPU"];
	[fanSensorName setObject:@"Hard Drive" forKey:@"HDD"];
	
}

- (NSArray *)getDataSet {
	if(intelClassInstance!= nil)
		return [self intelFans];
	return [self PPCFans];
}

- (NSArray *)intelFans {
	NSMutableArray *data = [[NSMutableArray alloc] init];
	
	NSDictionary *temps = [intelClassInstance getFanValues];
	NSEnumerator *itemEnumerator = [temps keyEnumerator];
	NSString *key;
	while(key = [itemEnumerator nextObject]){
		float textWidth = 0;
		if([fanSensorName valueForKey:key] != NULL)
			textWidth = [[fanSensorName valueForKey:key] sizeWithAttributes:[NSDictionary dictionaryWithObject:[NSFont boldSystemFontOfSize:10] forKey:NSFontAttributeName]].width;
		else	
			textWidth = [key sizeWithAttributes:[NSDictionary dictionaryWithObject:[NSFont boldSystemFontOfSize:10] forKey:NSFontAttributeName]].width;
		
		if([fanSensorName valueForKey:key] != NULL)
			[data addObject:[NSArray arrayWithObjects:[fanSensorName valueForKey:key], [temps valueForKey:key], [NSNumber numberWithFloat:textWidth], nil]];
		else
			[data addObject:[NSArray arrayWithObjects:key, [temps valueForKey:key], [NSNumber numberWithFloat:textWidth], nil]];
	}
	return [data autorelease];
}

- (NSArray *)PPCFans {
	NSMutableArray *theData = [[NSMutableArray alloc] init];
	kern_return_t ioStatus;
    io_iterator_t sensorsIterator;    
    io_object_t sensorObject;
	
    ioStatus = IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceNameMatching("IOHWControl"), &sensorsIterator);
    if (ioStatus == kIOReturnSuccess) {
		while (sensorObject = IOIteratorNext(sensorsIterator)) {
			NSMutableDictionary *sensorData;
			ioStatus = IORegistryEntryCreateCFProperties(sensorObject, (CFMutableDictionaryRef *)&sensorData, kCFAllocatorDefault, kNilOptions);
			if (ioStatus != kIOReturnSuccess) {
				IOObjectRelease(sensorObject);
				continue;
			}
			
			NSString *sensorType = [sensorData objectForKey:@"type"];
			if([fanSensorName objectForKey:[sensorData objectForKey:@"location"]] != NULL && ([sensorType isEqualToString:@"fan-rpm"] || [sensorType isEqualToString:@"fanspeed"])){				
				id currentValue = [NSNumber numberWithInt:0];
				id targetValue = [NSNumber numberWithInt:0];
				if([sensorData objectForKey:@"target-value"])
					targetValue = [sensorData objectForKey:@"target-value"];
				if([sensorData objectForKey:@"current-value"])
					currentValue = [sensorData objectForKey:@"current-value"];
				
				int currentSpeed = [currentValue intValue];
				if(currentSpeed >= 65536)
					currentSpeed = currentSpeed / 65536;
				int targetSpeed = [targetValue intValue];
				if(targetSpeed >= 65536)
					targetSpeed = targetSpeed / 65536;
				
				int value = 0;
				if(value == 0 && targetSpeed != 0)
					value = targetSpeed;
				if(value == 0 && currentSpeed != 0)
					value = currentSpeed;
				
				float textWidth = [[fanSensorName objectForKey:[sensorData objectForKey:@"location"]] sizeWithAttributes:[NSDictionary dictionaryWithObject:[NSFont boldSystemFontOfSize:10] forKey:NSFontAttributeName]].width;
				[theData addObject:[NSArray arrayWithObjects:[fanSensorName objectForKey:[sensorData objectForKey:@"location"]], [NSString stringWithFormat:@"%irpm",value], [NSNumber numberWithFloat:textWidth], nil]];
			}
			CFRelease(sensorData);
			IOObjectRelease(sensorObject);
		}
		IOObjectRelease(sensorsIterator);
	}
	
    ioStatus = IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceNameMatching("AppleFCU"), &sensorsIterator);
    if(ioStatus == kIOReturnSuccess) {
		while (sensorObject = IOIteratorNext(sensorsIterator)) {
			NSMutableDictionary *sensorData;
			ioStatus = IORegistryEntryCreateCFProperties(sensorObject, (CFMutableDictionaryRef *)&sensorData, kCFAllocatorDefault, kNilOptions);
			if (ioStatus != kIOReturnSuccess) {
				IOObjectRelease(sensorObject);
				continue;
			}
			
			NSArray *ci = [NSArray arrayWithArray:(NSArray *)[sensorData objectForKey:@"control-info"]];
			
			NSEnumerator *ciEnum = [ci objectEnumerator];
			NSDictionary *sensorItem;
			while (sensorItem = [ciEnum nextObject] ){
				if([fanSensorName objectForKey:[sensorItem valueForKey:@"location"]] != NULL){
					id currentValue = [sensorItem valueForKey:@"target-value"];
					int value = [currentValue intValue];
					if(value >= 65536)
						value = value / 65536;
					
					float textWidth = [[sensorItem valueForKey:@"location"] sizeWithAttributes:[NSDictionary dictionaryWithObject:[NSFont boldSystemFontOfSize:10] forKey:NSFontAttributeName]].width;
					[theData addObject:[NSArray arrayWithObjects:[sensorItem valueForKey:@"location"], [NSString stringWithFormat:@"%irpm",value], [NSNumber numberWithFloat:textWidth], nil]];
				}
			}
			
			CFRelease(sensorData);
			IOObjectRelease(sensorObject);
		}
		IOObjectRelease(sensorsIterator);	
	}
	
    ioStatus = IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceNameMatching("IOHWSensor"), &sensorsIterator);
    if (ioStatus == kIOReturnSuccess) {
		while (sensorObject = IOIteratorNext(sensorsIterator)) {
			NSMutableDictionary *sensorData;
			ioStatus = IORegistryEntryCreateCFProperties(sensorObject, (CFMutableDictionaryRef *)&sensorData,  kCFAllocatorDefault, kNilOptions);
			if (ioStatus != kIOReturnSuccess) {
				IOObjectRelease(sensorObject);
				continue;
			}
			
			
			NSString *sensorType = [sensorData objectForKey:@"type"];
			if([fanSensorName objectForKey:[sensorData objectForKey:@"location"]] != NULL && ([sensorType isEqualToString:@"fan-rpm"] || [sensorType isEqualToString:@"fanspeed"])){
				id currentValue = [NSNumber numberWithInt:0];
				id targetValue = [NSNumber numberWithInt:0];
				if([sensorData objectForKey:@"target-value"])
					targetValue = [sensorData objectForKey:@"target-value"];
				if([sensorData objectForKey:@"current-value"])
					currentValue = [sensorData objectForKey:@"current-value"];
				
				int currentSpeed = [currentValue intValue];
				int targetSpeed = [targetValue intValue];
				if(currentSpeed >= 65536)
					currentSpeed = currentSpeed / 65536;
				if(targetSpeed >= 65536)
					targetSpeed = targetSpeed / 65536;
				
				int value = 0;
				if(value == 0 && targetSpeed != 0)
					value = targetSpeed;
				if(value == 0 && currentSpeed != 0)
					value = currentSpeed;
				
				float textWidth = [[sensorData objectForKey:@"location"] sizeWithAttributes:[NSDictionary dictionaryWithObject:[NSFont boldSystemFontOfSize:10] forKey:NSFontAttributeName]].width;
				[theData addObject:[NSArray arrayWithObjects:[sensorData objectForKey:@"location"], [NSString stringWithFormat:@"%irpm",value], [NSNumber numberWithFloat:textWidth], nil]];
			}
			CFRelease(sensorData);
			IOObjectRelease(sensorObject);
		}
		IOObjectRelease(sensorsIterator);
	}
	
	return [theData autorelease];
}
@end
