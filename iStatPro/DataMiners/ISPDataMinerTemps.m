//
//  ISPDataMinerTemps.m
//  iStatMenusTemps
//
//  Created by iSlayer on 17/04/07.
//  Copyright 2007 iSlayer & Distorted Vista. All rights reserved.
//
// PPC stuff due for a major upgrade


#import "ISPDataMinerTemps.h"

@implementation NSArray(ISPSort)

- (NSComparisonResult)sortTemps:(NSArray *)other {
	if([[self objectAtIndex:0] hasPrefix:@"CPU"]){
		if([[other objectAtIndex:0] hasPrefix:@"CPU"])
			return [[self objectAtIndex:0] compare:[other objectAtIndex:0] options:NSCaseInsensitiveSearch];
		return NSOrderedAscending;
	}
	
	if([[other objectAtIndex:0] hasPrefix:@"CPU"]){
		if([[self objectAtIndex:0] hasPrefix:@"CPU"])
			return [[self objectAtIndex:0] compare:[other objectAtIndex:0] options:NSCaseInsensitiveSearch];
		return NSOrderedDescending;
	}
	
    return [[self objectAtIndex:0] compare:[other objectAtIndex:0] options:NSCaseInsensitiveSearch];
}

@end

@implementation ISPDataMinerTemps

- (id)init {
	self = [super init];
	
	intelClassInstance = nil;
	
	if([self isIntel])
		intelClassInstance = [[ISPIntelSensorController alloc] init];
	
	_knownSensors = [[NSMutableDictionary alloc] init];
	
	[self setDictionaries];
	
	return self;
}

- (void) dealloc {
	if(intelClassInstance)
		[intelClassInstance release];
	
	[_knownSensors release];
	
	[super dealloc];
}

- (BOOL)isIntel {
	long gestaltReturnValue;
	
	OSType returnType = Gestalt(gestaltSysArchitecture, &gestaltReturnValue);
	
	if (!returnType && gestaltReturnValue == gestaltIntel)
		return YES;
	return NO;
}

- (void) setDictionaries {
	[_knownSensors setObject:@"Hard Drive" forKey:@"Hard drive"];
	[_knownSensors setObject:@"CPU Bottom" forKey:@"CPU TOPSIDE"];
	[_knownSensors setObject:@"CPU Top" forKey:@"CPU BOTTOMSIDE"];		
	[_knownSensors setObject:@"CPU A Ambient" forKey:@"CPU A AD7417 AMB"];
	[_knownSensors setObject:@"CPU B Ambient" forKey:@"CPU B AD7417 AMB"];
	[_knownSensors setObject:@"CPU A" forKey:@"CPU A AD7417 AD1"];
	[_knownSensors setObject:@"CPU B" forKey:@"CPU B AD7417 AD1"];
	[_knownSensors setObject:@"CPU" forKey:@"CPU T-Diode"];
	[_knownSensors setObject:@"CPU A" forKey:@"CPU A DIODE TEMP"];
	[_knownSensors setObject:@"CPU A Core 1" forKey:@"CPU A0 DIODE TEMP"];
	[_knownSensors setObject:@"CPU A Core 2" forKey:@"CPU A1 DIODE TEMP"];
	[_knownSensors setObject:@"CPU B Core 1" forKey:@"CPU B0 DIODE TEMP"];
	[_knownSensors setObject:@"CPU B Core 2" forKey:@"CPU B1 DIODE TEMP"];
	[_knownSensors setObject:@"Optical Drive" forKey:@"ODD Temp"];
	[_knownSensors setObject:@"HD Temp" forKey:@"HD Temp"];
	[_knownSensors setObject:@"Mem Controller" forKey:@"NB Ambient"];
	[_knownSensors setObject:@"Mem Controller" forKey:@"NB Temp"];
	[_knownSensors setObject:@"GPU Ambient" forKey:@"GPU Ambient"];
	[_knownSensors setObject:@"GPU" forKey:@"GPU Temp"];
	[_knownSensors setObject:@"Incoming Air" forKey:@"Incoming Air Temp"];
	[_knownSensors setObject:@"CPU Bottom" forKey:@"CPU/INTREPID BOTTOMSIDE"];
	[_knownSensors setObject:@"Power Supply" forKey:@"PWR SUPPLY BOTTOMSIDE"];
	[_knownSensors setObject:@"Track Pad" forKey:@"TRACK PAD"];
	[_knownSensors setObject:@"Drive Bay" forKey:@"DRIVE BAY"];
	[_knownSensors setObject:@"Backside" forKey:@"BACKSIDE"];
	[_knownSensors setObject:@"U3 Heatsink" forKey:@"U3 HEATSINK"];
	[_knownSensors setObject:@"GPU" forKey:@"gpu-diode"];
	[_knownSensors setObject:@"GPU Case" forKey:@"gpu-case"];
	[_knownSensors setObject:@"Sys Controller Ambient" forKey:@"SYS CTRLR AMBIENT"];
	[_knownSensors setObject:@"Sys Controller" forKey:@"SYS CTRLR INTERNAL"];
	[_knownSensors setObject:@"Memory Bank" forKey:@"Behind the DIMMS"];
	[_knownSensors setObject:@"Ambient 2" forKey:@"Between the Processors"];
	[_knownSensors setObject:@"PCI Slots" forKey:@"PCI SLOTS"];
	[_knownSensors setObject:@"Memory/Power" forKey:@"PWR/MEMORY BOTTOMSIDE"];
	[_knownSensors setObject:@"Tunnel" forKey:@"TUNNEL"];
	[_knownSensors setObject:@"Tunnel Heatsink" forKey:@"TUNNEL HEATSINK"];
	[_knownSensors setObject:@"Battery" forKey:@"BATTERY"];
	[_knownSensors setObject:@"GPU" forKey:@"GPU ON DIE"];
	[_knownSensors setObject:@"Hard Drive" forKey:@"HDD BOTTOMSIDE"];
	[_knownSensors setObject:@"Battery" forKey:@"BATT-TEMP"];
	[_knownSensors setObject:@"Mem Controller" forKey:@"KODIAK DIODE"];	
	[_knownSensors setObject:@"CPU" forKey:@"temp-monitor"];
}

- (NSArray *)getDataSet:(int)degrees {
	if(intelClassInstance!= nil)
		return [self intelTemperatures:degrees];
	return [self PPCTemperatures:degrees];
}

- (NSArray *)intelTemperatures:(int)degrees {
	NSMutableArray *data = [[NSMutableArray alloc] init];
	
	NSString *degreesSuffix = [NSString stringWithUTF8String:"\xC2\xB0"];					
	if(degrees == 2)
		degreesSuffix = @"K";
	
	NSDictionary *temps = [intelClassInstance getTempValues];
	
	NSEnumerator *groupEnumerator = [temps objectEnumerator];
	NSArray *sensor;
	while(sensor = [groupEnumerator nextObject]){
		int value = convertTemperature(degrees, [[sensor objectAtIndex:1] intValue]);
		
		float textWidth = [[sensor objectAtIndex:0] sizeWithAttributes:[NSDictionary dictionaryWithObject:[NSFont boldSystemFontOfSize:10] forKey:NSFontAttributeName]].width;
		[data addObject:[NSArray arrayWithObjects:[sensor objectAtIndex:0], [NSString stringWithFormat:@"%i%@",value,degreesSuffix], [NSNumber numberWithFloat:textWidth], nil]];
	}
	[data sortUsingSelector:@selector(sortTemps:)];
	return [data autorelease];
}

- (NSArray *)PPCTemperatures:(int)degrees {
	NSMutableArray *data = [[NSMutableArray alloc] init];
	
	NSString *degreesSuffix = [NSString stringWithUTF8String:"\xC2\xB0"];					
	if(degrees == 2)
		degreesSuffix = @"K";
	
    kern_return_t    ioStatus;
    io_iterator_t    sensorsIterator;    
    
    ioStatus = IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceNameMatching("IOHWSensor"), &sensorsIterator);
    if (ioStatus != kIOReturnSuccess) {
		return [NSArray array];
    }
    
    io_object_t sensorObject;
    while (sensorObject = IOIteratorNext(sensorsIterator)) {
		NSMutableDictionary *sensorData;
        ioStatus = IORegistryEntryCreateCFProperties(sensorObject, (CFMutableDictionaryRef *)&sensorData,  kCFAllocatorDefault, kNilOptions);
        if (ioStatus != kIOReturnSuccess) {
            IOObjectRelease(sensorObject);
            continue;
        }
		
		if([_knownSensors objectForKey:[sensorData objectForKey:@"location"]] != NULL){
			IORegistryEntrySetCFProperty(sensorObject,CFSTR("force-update"),(CFNumberRef)[sensorData valueForKey:@"sensor-id"]);
			
			int value = [[sensorData objectForKey:@"current-value"] intValue];
			
			int divisor = 10;
			if(value >= 65536)
				divisor = 65536;
			
			value = value / divisor;
			
			if(value <= 0)
				continue;
			
			value = convertTemperature(degrees, value);
			
			float textWidth = [[_knownSensors valueForKey:[sensorData objectForKey:@"location"]] sizeWithAttributes:[NSDictionary dictionaryWithObject:[NSFont boldSystemFontOfSize:10] forKey:NSFontAttributeName]].width;
			[data addObject:[NSArray arrayWithObjects:[_knownSensors valueForKey:[sensorData objectForKey:@"location"]], [NSString stringWithFormat:@"%i%@",value,degreesSuffix], [NSNumber numberWithFloat:textWidth], nil]];
		}
        CFRelease(sensorData);
        IOObjectRelease(sensorObject);
    }
    IOObjectRelease(sensorsIterator);	
	
    ioStatus = IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceNameMatching("AppleCPUThermo"), &sensorsIterator);
    if (ioStatus != kIOReturnSuccess) {
		return [NSArray array];
    }
    
    while (sensorObject = IOIteratorNext(sensorsIterator)) {
		NSMutableDictionary *sensorData;
        ioStatus = IORegistryEntryCreateCFProperties(sensorObject, (CFMutableDictionaryRef *)&sensorData,  kCFAllocatorDefault, kNilOptions);
        if (ioStatus != kIOReturnSuccess) {
            IOObjectRelease(sensorObject);
            continue;
        }
		
		if([sensorData objectForKey:@"temperature"]){			
			id currentValue = [sensorData objectForKey:@"temperature"];
			int value = [currentValue floatValue] / 256.0;
			if(value > 0)
				value = convertTemperature(degrees, value);
			
			float textWidth = [[_knownSensors valueForKey:@"temp-monitor"] sizeWithAttributes:[NSDictionary dictionaryWithObject:[NSFont boldSystemFontOfSize:10] forKey:NSFontAttributeName]].width;
			[data addObject:[NSArray arrayWithObjects:[_knownSensors valueForKey:@"temp-monitor"], [NSString stringWithFormat:@"%i%@", value, degreesSuffix], [NSNumber numberWithFloat:textWidth], nil]];
		}
        CFRelease(sensorData);
        IOObjectRelease(sensorObject);
    }
    IOObjectRelease(sensorsIterator);	
	
	[data sortUsingSelector:@selector(sortTemps:)];
	return [data autorelease];
}

@end
