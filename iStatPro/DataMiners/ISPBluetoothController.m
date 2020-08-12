//
//  ISPBluetoothController.m
//  iStatPro
//
//  Created by iSlayer on 17/04/07.
//  Copyright 2007 iSlayer & Distorted Vista. All rights reserved.
//

#import "ISPBluetoothController.h"

@implementation ISPBluetoothController

- (BOOL)kb {
	return kb_exists;
}

- (BOOL)mouse {
	return mouse_exists;
}

- (NSString *)getMouseLevel {
    kern_return_t    ioStatus;
    io_iterator_t    sensorsIterator;
    io_object_t sensorObject;
	NSString *value = @"0%";
	BOOL found = NO;

	ioStatus = IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceNameMatching("AppleBluetoothHIDMouse"), &sensorsIterator);
    if (ioStatus != kIOReturnSuccess) {
		kb_exists = NO;
        return value;
    }
    
    while (sensorObject = IOIteratorNext(sensorsIterator)) {
		NSMutableDictionary *sensorData;
        ioStatus = IORegistryEntryCreateCFProperties(sensorObject, (CFMutableDictionaryRef *)&sensorData, kCFAllocatorDefault, kNilOptions);
        if (ioStatus != kIOReturnSuccess) {
            IOObjectRelease(sensorObject);
            continue;
        }
		
		if([sensorData valueForKey:@"BatteryPercent"] != NULL){
			found = YES;
			value = [NSString stringWithFormat:@"%@%%",[sensorData valueForKey:@"BatteryPercent"]];
		}
		CFRelease(sensorData);
		IOObjectRelease(sensorObject);
	}
	IOObjectRelease(sensorsIterator);

    if(!found){
		ioStatus = IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceNameMatching("IOAppleBluetoothHIDDriver"), &sensorsIterator);
		if (ioStatus != kIOReturnSuccess) {
			mouse_exists = NO;
			return value;
		}

		while (sensorObject = IOIteratorNext(sensorsIterator)) {
			NSMutableDictionary *sensorData;
			ioStatus = IORegistryEntryCreateCFProperties(sensorObject, (CFMutableDictionaryRef *)&sensorData, kCFAllocatorDefault, kNilOptions);
			if (ioStatus != kIOReturnSuccess) {
				IOObjectRelease(sensorObject);
				continue;
			}
		
			if([sensorData valueForKey:@"ProductID"] && [[sensorData valueForKey:@"ProductID"] intValue] == 777){
				if([sensorData valueForKey:@"BatteryPercent"] != NULL){
					found = YES;
					value = [NSString stringWithFormat:@"%@%%",[sensorData valueForKey:@"BatteryPercent"]];
				}
			}
			CFRelease(sensorData);
			IOObjectRelease(sensorObject);
		}
	}

	if(!found){
		ioStatus = IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceNameMatching("BNBMouseDevice"), &sensorsIterator);
		if (ioStatus != kIOReturnSuccess) {
			mouse_exists = NO;
			return value;
		}
		
		while (sensorObject = IOIteratorNext(sensorsIterator)) {
			NSMutableDictionary *sensorData;
			ioStatus = IORegistryEntryCreateCFProperties(sensorObject, (CFMutableDictionaryRef *)&sensorData, kCFAllocatorDefault, kNilOptions);
			if (ioStatus != kIOReturnSuccess) {
				IOObjectRelease(sensorObject);
				continue;
			}
			
			if([sensorData valueForKey:@"BatteryPercent"] != NULL){
				found = YES;
				value = [NSString stringWithFormat:@"%@%%",[sensorData valueForKey:@"BatteryPercent"]];
			}
			CFRelease(sensorData);
			IOObjectRelease(sensorObject);
		}
	}
	
	IOObjectRelease(sensorsIterator);
	
	mouse_exists = found;

	return value;
}

- (NSString *)getKbLevel {
    kern_return_t    ioStatus;
    io_iterator_t    sensorsIterator;
	NSString *value = @"0%";
	BOOL found = NO;	
    
    ioStatus = IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceNameMatching("IOAppleBluetoothHIDDriver"), &sensorsIterator);
    if (ioStatus != kIOReturnSuccess) {
		kb_exists = NO;
        return value;
    }
    
    io_object_t sensorObject;
    while (sensorObject = IOIteratorNext(sensorsIterator)) {
		NSMutableDictionary *sensorData;
        ioStatus = IORegistryEntryCreateCFProperties(sensorObject, (CFMutableDictionaryRef *)&sensorData, kCFAllocatorDefault, kNilOptions);
        if (ioStatus != kIOReturnSuccess) {
            IOObjectRelease(sensorObject);
            continue;
        }		
		if(![sensorData valueForKey:@"ProductID"] || [[sensorData valueForKey:@"ProductID"] intValue] != 777){
			if([sensorData valueForKey:@"BatteryPercent"] != NULL){
				found = YES;
				value = [NSString stringWithFormat:@"%@%%",[sensorData valueForKey:@"BatteryPercent"]];
			}
		}
		
		CFRelease(sensorData);
		IOObjectRelease(sensorObject);
	}
	IOObjectRelease(sensorsIterator);

	kb_exists = found;
	return value;
}

@end
