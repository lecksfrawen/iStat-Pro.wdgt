//
//  DataMinerDiskActivity.m
//  iStatMenusDrives
//
//  Created by Buffy on 27/05/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "DataMinerDiskActivity.h"
//#import "ISMDisksDefines.h"

@implementation DataMinerDiskActivity

static DataMinerDiskActivity *dataMinerCore = nil;

+ (id)dataMinerCore {
	if(dataMinerCore)
		return dataMinerCore;
	
	dataMinerCore = [[DataMinerDiskActivity alloc] init];
	[dataMinerCore setup];
	return dataMinerCore;
}

- (struct diskactivity *)allHistory {
//	return history;
}

- (void) dealloc {
	if (port)
		IONotificationPortDestroy(port);	
	if (itr)
		IOObjectRelease(itr);
	if (addItr)
		IOObjectRelease(addItr);	
	if (rmvItr)
		IOObjectRelease(rmvItr);	
	[super dealloc];
}


void mounted(void *stateRef, io_iterator_t dev) {
	io_registry_entry_t item = 0;
	while (item = IOIteratorNext(dev))
		IOObjectRelease(item);
	if (stateRef)
		*(BOOL *)stateRef = NO;
}

void unmounted(void *stateRef, io_iterator_t dev) {
	io_registry_entry_t item = 0;
	while (item = IOIteratorNext(dev))
		IOObjectRelease(item);
	if (stateRef)
		*(BOOL *)stateRef = NO;
}

- (void)setup {
	previousTime = [[NSDate date] timeIntervalSince1970];
	
	port = IONotificationPortCreate(kIOMasterPortDefault);
	runLoop = IONotificationPortGetRunLoopSource(port);
	CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoop, kCFRunLoopDefaultMode);
	
	IOServiceAddMatchingNotification(port, kIOPublishNotification,  IOServiceMatching(kIOBlockStorageDriverClass), mounted, &state, &addItr);
	mounted(&state, addItr);

	IOServiceAddMatchingNotification(port, kIOTerminatedNotification, IOServiceMatching(kIOBlockStorageDriverClass), unmounted, &state, &rmvItr);
	unmounted(&state, rmvItr);

	IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceMatching(kIOBlockStorageDriverClass), &itr);
	state = YES;
}

- (int)getActivity {
	if (!itr || !state) {
		if (itr)
			IOObjectRelease(itr);
		IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceMatching(kIOBlockStorageDriverClass), &itr);
		state = YES;
	}

	double current_time = [[NSDate date] timeIntervalSince1970];
	double timer_difference = current_time - previousTime;
	if(timer_difference < 0.5)
		timer_difference = 0.5;

	UInt64 readTotal = 0;
	UInt64 writeTotal = 0;
	
	io_registry_entry_t item = 0;

	while (item = IOIteratorNext(itr)) {	
		NSDictionary *stats = (NSDictionary *)IORegistryEntryCreateCFProperty(item, CFSTR(kIOBlockStorageDriverStatisticsKey),kCFAllocatorDefault, kNilOptions);
		if(stats) {		
			if([stats objectForKey:(NSString *)CFSTR(kIOBlockStorageDriverStatisticsBytesReadKey)])
				readTotal += [[stats objectForKey:(NSString *)CFSTR(kIOBlockStorageDriverStatisticsBytesReadKey)] unsignedLongLongValue];

			if([stats objectForKey:(NSString *)CFSTR(kIOBlockStorageDriverStatisticsBytesWrittenKey)])
				writeTotal += [[stats objectForKey:(NSString *)CFSTR(kIOBlockStorageDriverStatisticsBytesWrittenKey)] unsignedLongLongValue];
			[stats release];		
		}
		
		if(item)
			IOObjectRelease(item);
	}
	IOIteratorReset(itr);
	
	
	unsigned long long newRead = (readTotal - previousReadTotal) / timer_difference;
	unsigned long long newWrite = (writeTotal - previousWriteTotal) / timer_difference;
	if(newRead < 0)
		newRead = 0;
	if(newWrite < 0)
		newWrite = 0;
	
	BOOL showRead = NO;
	BOOL showWrite = NO;
	
	if(readTotal > previousReadTotal)
		showRead = YES;

	if(writeTotal > previousWriteTotal)
		showWrite = YES;
	
	previousReadTotal = readTotal;
	previousWriteTotal = writeTotal;
	
	/*
	int status = 0;
	if(showRead)
		status += kActivityRead;
	if(showWrite)
		status += kActivityWrite;
	*/
//	previousTime = current_time;
//	return status;
}

@end
