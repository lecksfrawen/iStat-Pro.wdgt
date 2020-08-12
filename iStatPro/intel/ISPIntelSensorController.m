//
//  Controller.m
//  IntelSensors
//
//  Created by iSlayer on 17/04/07.
//  Copyright 2007 iSlayer & Distorted Vista. All rights reserved.

#import "ISPIntelSensorController.h"
#import "smc.h"

@implementation ISPIntelSensorController

- (void) dealloc {
	[availableKeys release];
	[supportedKeys release];
	[keyDisplayNames release];

	SMCClose(&conn2);
//	smc_close();
	[super dealloc];
}


- (id)init {
	self = [super init];
	kern_return_t result = SMCOpen("ServiceName", &conn2);
    if (result != kIOReturnSuccess){
		supported = NO;
		return self;
	}
	supported = YES;
//	smc_init();
	
	supportedKeys = [[NSMutableArray alloc] init];
	[self setKeys];
	[self findSupportedKeys];
	
	return self;
}

- (BOOL)isSupported {
	return supported;
}

- (void)setKeys {
	availableKeys = [[NSMutableArray alloc] init];
	[availableKeys addObject:@"TC0H"];
	[availableKeys addObject:@"TC0D"];
	[availableKeys addObject:@"TC1D"];
	[availableKeys addObject:@"TCAH"];
	[availableKeys addObject:@"TCBH"];
	[availableKeys addObject:@"TG0P"];
	[availableKeys addObject:@"TA0P"];
	[availableKeys addObject:@"TH0P"];
	[availableKeys addObject:@"TO0P"];
	[availableKeys addObject:@"TH1P"];
	[availableKeys addObject:@"TH2P"];
	[availableKeys addObject:@"TH3P"];
	[availableKeys addObject:@"Th0H"];
	[availableKeys addObject:@"Th1H"];
	[availableKeys addObject:@"Th2H"];
	[availableKeys addObject:@"TG0H"];
	[availableKeys addObject:@"TG1H"];
	[availableKeys addObject:@"TG0D"];
	[availableKeys addObject:@"Tp1C"];
	[availableKeys addObject:@"Tp0C"];
	[availableKeys addObject:@"TB0T"];
	[availableKeys addObject:@"TB1T"];
	[availableKeys addObject:@"TB2T"];
	[availableKeys addObject:@"TB3T"];
	[availableKeys addObject:@"TN0P"];
	[availableKeys addObject:@"TN1P"];
	[availableKeys addObject:@"TN0H"];
	[availableKeys addObject:@"TM0S"];
	[availableKeys addObject:@"TM1S"];
	[availableKeys addObject:@"TM2S"];
	[availableKeys addObject:@"TM3S"];
	[availableKeys addObject:@"TM4S"];
	[availableKeys addObject:@"TM5S"];
	[availableKeys addObject:@"TM6S"];
	[availableKeys addObject:@"TM7S"];
	[availableKeys addObject:@"TM8S"];
	[availableKeys addObject:@"TM9S"];
	[availableKeys addObject:@"TMAS"];
	[availableKeys addObject:@"TMBS"];
	[availableKeys addObject:@"TMCS"];
	[availableKeys addObject:@"TMDS"];
	[availableKeys addObject:@"TMES"];
	[availableKeys addObject:@"TMFS"];
	[availableKeys addObject:@"TM0P"];
	[availableKeys addObject:@"TM1P"];
	[availableKeys addObject:@"TM2P"];
	[availableKeys addObject:@"TM3P"];
	[availableKeys addObject:@"TM4P"];
	[availableKeys addObject:@"TM5P"];
	[availableKeys addObject:@"TM6P"];
	[availableKeys addObject:@"TM7P"];
	[availableKeys addObject:@"TM8P"];
	[availableKeys addObject:@"TM9P"];
	[availableKeys addObject:@"TMAP"];
	[availableKeys addObject:@"TMBP"];
	[availableKeys addObject:@"TMCP"];
	[availableKeys addObject:@"TMDP"];
	[availableKeys addObject:@"TMEP"];
	[availableKeys addObject:@"TMFP"];
	[availableKeys addObject:@"Tm0P"];
	[availableKeys addObject:@"TS0C"];
	[availableKeys addObject:@"TW0P"];
	[availableKeys addObject:@"Tp0P"];

	[availableKeys addObject:@"TA0S"]; 
	[availableKeys addObject:@"TA1S"]; 
	[availableKeys addObject:@"TA2S"];
	[availableKeys addObject:@"TA3S"];
	[availableKeys addObject:@"TA1P"];
	[availableKeys addObject:@"Tp1P"];
	[availableKeys addObject:@"Tp2P"];
	[availableKeys addObject:@"Tp3P"];
	[availableKeys addObject:@"Tp4P"];
	[availableKeys addObject:@"Tp5P"];

	keyDisplayNames = [[NSMutableDictionary alloc] init];
	[keyDisplayNames setValue:@"Mem Controller" forKey:@"Tm0P"];
	[keyDisplayNames setValue:@"Mem Bank A1" forKey:@"TM0P"];
	[keyDisplayNames setValue:@"Mem Bank A2" forKey:@"TM1P"];
	[keyDisplayNames setValue:@"Mem Bank A3" forKey:@"TM2P"];
	[keyDisplayNames setValue:@"Mem Bank A4" forKey:@"TM3P"]; 
	[keyDisplayNames setValue:@"Mem Bank A5" forKey:@"TM4P"]; 
	[keyDisplayNames setValue:@"Mem Bank A6" forKey:@"TM5P"]; 
	[keyDisplayNames setValue:@"Mem Bank A7" forKey:@"TM6P"]; 
	[keyDisplayNames setValue:@"Mem Bank A8" forKey:@"TM7P"]; 
	[keyDisplayNames setValue:@"Mem Bank B1" forKey:@"TM8P"];
	[keyDisplayNames setValue:@"Mem Bank B2" forKey:@"TM9P"];
	[keyDisplayNames setValue:@"Mem Bank B3" forKey:@"TMAP"];
	[keyDisplayNames setValue:@"Mem Bank B4" forKey:@"TMBP"];  
	[keyDisplayNames setValue:@"Mem Bank B5" forKey:@"TMCP"]; 
	[keyDisplayNames setValue:@"Mem Bank B6" forKey:@"TMDP"]; 
	[keyDisplayNames setValue:@"Mem Bank B7" forKey:@"TMEP"]; 
	[keyDisplayNames setValue:@"Mem Bank B8" forKey:@"TMFP"]; 
	[keyDisplayNames setValue:@"Mem module A1" forKey:@"TM0S"];
	[keyDisplayNames setValue:@"Mem module A2" forKey:@"TM1S"];
	[keyDisplayNames setValue:@"Mem module A3" forKey:@"TM2S"];
	[keyDisplayNames setValue:@"Mem module A4" forKey:@"TM3S"];
	[keyDisplayNames setValue:@"Mem module A5" forKey:@"TM4S"]; 
	[keyDisplayNames setValue:@"Mem module A6" forKey:@"TM5S"]; 
	[keyDisplayNames setValue:@"Mem module A7" forKey:@"TM6S"]; 
	[keyDisplayNames setValue:@"Mem module A8" forKey:@"TM7S"]; 
	[keyDisplayNames setValue:@"Mem module B1" forKey:@"TM8S"];
	[keyDisplayNames setValue:@"Mem module B2" forKey:@"TM9S"];
	[keyDisplayNames setValue:@"Mem module B3" forKey:@"TMAS"]; 
	[keyDisplayNames setValue:@"Mem module B4" forKey:@"TMBS"]; 
	[keyDisplayNames setValue:@"Mem module B5" forKey:@"TMCS"]; 
	[keyDisplayNames setValue:@"Mem module B6" forKey:@"TMDS"]; 
	[keyDisplayNames setValue:@"Mem module B7" forKey:@"TMES"]; 
	[keyDisplayNames setValue:@"Mem module B8" forKey:@"TMFS"]; 
	[keyDisplayNames setValue:@"CPU A" forKey:@"TC0H"];
	[keyDisplayNames setValue:@"CPU A" forKey:@"TC0D"];
	[keyDisplayNames setValue:@"CPU B" forKey:@"TC1D"];
	[keyDisplayNames setValue:@"CPU C" forKey:@"TC2D"];
	[keyDisplayNames setValue:@"CPU D" forKey:@"TC3D"];
	[keyDisplayNames setValue:@"CPU A" forKey:@"TCAH"];
	[keyDisplayNames setValue:@"CPU B" forKey:@"TCBH"];
	[keyDisplayNames setValue:@"CPU C" forKey:@"TCCH"];
	[keyDisplayNames setValue:@"CPU D" forKey:@"TCDH"];
	[keyDisplayNames setValue:@"GPU" forKey:@"TG0P"];
	[keyDisplayNames setValue:@"Ambient" forKey:@"TA0P"];
	[keyDisplayNames setValue:@"HD Bay 1" forKey:@"TH0P"];
	[keyDisplayNames setValue:@"HD Bay 2" forKey:@"TH1P"];
	[keyDisplayNames setValue:@"HD Bay 3" forKey:@"TH2P"];
	[keyDisplayNames setValue:@"HD Bay 4" forKey:@"TH3P"];
	[keyDisplayNames setValue:@"Optical Drive" forKey:@"TO0P"];
	[keyDisplayNames setValue:@"Heatsink A" forKey:@"Th0H"];
	[keyDisplayNames setValue:@"Heatsink B" forKey:@"Th1H"];
	[keyDisplayNames setValue:@"Heatsink C" forKey:@"Th2H"];
	[keyDisplayNames setValue:@"GPU Diode" forKey:@"TG0D"];
	[keyDisplayNames setValue:@"GPU Heatsink" forKey:@"TG0H"];
	[keyDisplayNames setValue:@"GPU Heatsink 2" forKey:@"TG1H"];
	[keyDisplayNames setValue:@"Power supply 2" forKey:@"Tp1C"];
	[keyDisplayNames setValue:@"Power supply 1" forKey:@"Tp0C"];
	[keyDisplayNames setValue:@"Power supply 1" forKey:@"Tp0P"];
	[keyDisplayNames setValue:@"Enclosure Base" forKey:@"TB0T"];
	[keyDisplayNames setValue:@"Enclosure Base 2" forKey:@"TB1T"];
	[keyDisplayNames setValue:@"Enclosure Base 3" forKey:@"TB2T"];
	[keyDisplayNames setValue:@"Enclosure Base 4" forKey:@"TB3T"];
	[keyDisplayNames setValue:@"Northbridge 1" forKey:@"TN0P"];
	[keyDisplayNames setValue:@"Northbridge 2" forKey:@"TN1P"];
	[keyDisplayNames setValue:@"Northbridge" forKey:@"TN0H"];
	[keyDisplayNames setValue:@"Expansion Slots" forKey:@"TS0C"];
	[keyDisplayNames setValue:@"Airport Card" forKey:@"TW0P"];

	[keyDisplayNames setValue:@"PCI Slot 1 Pos 1" forKey:@"TA0S"];
	[keyDisplayNames setValue:@"PCI Slot 1 Pos 2" forKey:@"TA1S"];
	[keyDisplayNames setValue:@"PCI Slot 2 Pos 1" forKey:@"TA2S"];
	[keyDisplayNames setValue:@"PCI Slot 2 Pos 2" forKey:@"TA3S"];
	[keyDisplayNames setValue:@"Ambient 2" forKey:@"TA1P"];
	[keyDisplayNames setValue:@"Power supply 2" forKey:@"Tp1P"];
	[keyDisplayNames setValue:@"Power supply 3" forKey:@"Tp2P"];
	[keyDisplayNames setValue:@"Power supply 4" forKey:@"Tp3P"];
	[keyDisplayNames setValue:@"Power supply 5" forKey:@"Tp4P"];
	[keyDisplayNames setValue:@"Power supply 6" forKey:@"Tp5P"];
}

- (void)findSupportedKeys {	
	SMCVal_t      val;
	NSEnumerator *keyEnumerator = [availableKeys objectEnumerator];
	NSString *key;
	while(key = [keyEnumerator nextObject]){
		kern_return_t result = SMCReadKey(conn2, [key cString], &val);
		if (result == kIOReturnSuccess){
			if (val.dataSize > 0) {
				if(((val.bytes[0] * 256 + val.bytes[1]) >> 2)/64 <= 0)
					continue;
				
				[supportedKeys addObject:key];
			}
		}
	}

	
	if([supportedKeys containsObject:@"TC0D"]){
		if(![supportedKeys containsObject:@"TC1D"])
			[keyDisplayNames setValue:@"CPU" forKey:@"TC0D"];
	}
	
	if([supportedKeys containsObject:@"TC0H"]){
		if(![supportedKeys containsObject:@"TC1H"]){
			if([supportedKeys containsObject:@"TC0D"]){
				[keyDisplayNames setValue:@"CPU Heatsink" forKey:@"TC0H"];
			} else {
				[keyDisplayNames setValue:@"CPU" forKey:@"TC0H"];
			}
		}
	}

	if([supportedKeys containsObject:@"TCAH"]){
		if(![supportedKeys containsObject:@"TCBH"])
			[keyDisplayNames setValue:@"CPU" forKey:@"TCAH"];
	}

	if([supportedKeys containsObject:@"Th0H"]){
		if(![supportedKeys containsObject:@"Th1H"])
			[keyDisplayNames setValue:@"CPU Heatsink" forKey:@"Th0H"];
	}
	
	if([supportedKeys containsObject:@"TH0P"]){
		if(![supportedKeys containsObject:@"TH1P"])
			[keyDisplayNames setValue:@"HD Bay" forKey:@"TH0P"];
	}

	if([supportedKeys containsObject:@"TN0P"]){
		if(![supportedKeys containsObject:@"TN1P"])
			[keyDisplayNames setValue:@"Northbridge" forKey:@"TN0P"];
	}

	if([supportedKeys containsObject:@"Tp0C"]){
		if(![supportedKeys containsObject:@"Tp1C"])
			[keyDisplayNames setValue:@"Power Supply" forKey:@"Tp0C"];
	}

	if([supportedKeys containsObject:@"Tp0P"]){
		if(![supportedKeys containsObject:@"Tp1P"])
			[keyDisplayNames setValue:@"Power Supply" forKey:@"Tp0P"];
	}

	if([supportedKeys containsObject:@"Th2H"]){
		if(![supportedKeys containsObject:@"Th0H"] && ![supportedKeys containsObject:@"T10H"])
			[keyDisplayNames setValue:@"CPU Heatsink" forKey:@"Th2H"];
	}
}

- (NSArray *)getFans {
    UInt32Char_t  key;
    int           totalFans, i;
	SMCVal_t      val;

    kern_return_t result = SMCReadKey(conn2, "FNum", &val);
    if (result != kIOReturnSuccess)
        return [NSArray array];

    totalFans = _strtoul(val.bytes, val.dataSize, 10);

	NSMutableArray *fans = [[NSMutableArray alloc] init];
    for (i = 0; i < totalFans; i++)
    {
        sprintf(key, "F%dAc", i); 
        SMCReadKey(conn2, key, &val);
		[fans addObject:[NSString stringWithFormat:@"Fan %i",i]];
    }

	return [fans autorelease];
}


// getFanName - originally from smcFanControl
// used as a fallback when we havent got a clean name for a fan sensor
- (NSString *)getFanName:(int)number {
	SMCVal_t      val;
	UInt32Char_t  key;
	char temp;
	kern_return_t result;
	NSMutableString *desc;
	desc = [[NSMutableString alloc]init];
	sprintf(key, "F%dID", number);
	result = SMCReadKey(conn2, key, &val);
	int i;
	for (i = 0; i < val.dataSize; i++) {
		if ((int)val.bytes[i ] >32) {
			temp = (unsigned char)val.bytes[i];
			[desc appendFormat:@"%c",temp];
		}
	}
	
	if([desc length] == 0)
		[desc setString:[NSString stringWithFormat:@"Fan %i",number]];
	return [desc autorelease];
}	

- (NSDictionary *)getFanValues {
    UInt32Char_t  key;
    int           totalFans, i;
	SMCVal_t      val;

	kern_return_t result = SMCReadKey(conn2, "FNum", &val);
    if (result != kIOReturnSuccess)
        return [NSDictionary dictionary];

	totalFans = _strtoul(val.bytes, val.dataSize, 10); 

	NSMutableDictionary *fans = [[NSMutableDictionary alloc] init];
    for (i = 0; i < totalFans; i++) {
        sprintf(key, "F%dAc", i); 
        SMCReadKey(conn2, key, &val);
        [fans setValue:[NSString stringWithFormat:@"%@rpm",[NSNumber numberWithInt:1]] forKey:[self getFanName:i]];
//		[fans setValue:[NSString stringWithFormat:@"%@rpm",[NSNumber numberWithInt:_strtof(val.bytes, val.dataSize, 2)]] forKey:[self getFanName:i]];
	}

	return [fans autorelease];
}

- (NSDictionary *)getTempValues {
	NSMutableArray *values = [[NSMutableArray alloc] init];
	SMCVal_t      val;

	NSEnumerator *keyEnumerator = [supportedKeys objectEnumerator];
	NSString *key;
	while(key = [keyEnumerator nextObject]){
		kern_return_t result = SMCReadKey(conn2, [key cString], &val);
		if (result == kIOReturnSuccess){
			if (val.dataSize > 0) {
				if(((val.bytes[0] * 256 + val.bytes[1]) >> 2)/64 == 0)
					continue;
				[values addObject:[NSArray arrayWithObjects:[keyDisplayNames objectForKey:key], [NSNumber numberWithInt:((val.bytes[0] * 256 + val.bytes[1]) >> 2)/64], nil]];
			}	
		}
	}
	
	return [values autorelease];
}

@end
