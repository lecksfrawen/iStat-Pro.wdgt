//
//  ISPDataMinerMemory.m
//  iStat
//
//  Created by iSlayer on 17/04/07.
//  Copyright 2007 iSlayer & Distorted Vista. All rights reserved.
//

#import "ISPDataMinerMemory.h"


@implementation ISPDataMinerMemory

- (id)init {
	host_port = mach_host_self();

	formatter = [[NSNumberFormatter alloc] init];
	[formatter setFormat:@"#,###;0;($ #,##0)"];
	[formatter setFormatterBehavior:NSNumberFormatterBehavior10_0];
	[formatter setNumberStyle:NSNumberFormatterDecimalStyle];

	return self;
}

- (void)dealloc {
	mach_port_deallocate(mach_task_self(), host_port);
	[super dealloc];
}

- (NSString *)getSwap {
	int vmmib[2] = {CTL_VM, VM_SWAPUSAGE};
	struct xsw_usage swapused;
	size_t swlen = sizeof(swapused);
	sysctl(vmmib, 2, &swapused, &swlen, NULL, 0);
	NSString *swapTotal = [self convertSwap:[NSNumber numberWithFloat:((float) swapused.xsu_total) / 1048576]];
	NSString *swapUsed = [self convertSwap:[NSNumber numberWithFloat:((float) swapused.xsu_used) / 1048576]];
	return [NSString stringWithFormat:@"%@/%@", swapUsed, swapTotal];
}

- (NSArray *)getDataSet {		
	[[NSAutoreleasePool alloc] init];
    vm_statistics_data_t	memoryData;
    mach_msg_type_number_t	numBytes = HOST_VM_INFO_COUNT;
	unsigned int free, active, inactive, wired, used, total;
	float pageins, pageouts;
	NSString *pagesins_formatted;
	NSString *pagesouts_formatted;
   
    host_statistics(host_port, HOST_VM_INFO, (host_info_t)&memoryData, &numBytes);
	
	free = (memoryData.free_count * 4) / 1024;
	active = (memoryData.active_count * 4) / 1024;
	inactive = (memoryData.inactive_count * 4) / 1024;
	wired = (memoryData.wire_count * 4) / 1024;
	used = active + wired;
	total = used + free + inactive;

	pageins = memoryData.pageins;
	pageouts = memoryData.pageouts;
	
	if(pageins > 999999) {
		float millions = pageins / 1000000;
		pagesins_formatted = [NSString stringWithFormat:@"%.1fmil",millions];
	} else {
		pagesins_formatted = [formatter stringFromNumber:[NSNumber numberWithFloat:pageins]];
	}

	if(pageouts > 999999) {
		float millions = pageouts / 1000000;
		pagesouts_formatted = [NSString stringWithFormat:@"%.1fmil",millions];
	} else {
		pagesouts_formatted = [formatter stringFromNumber:[NSNumber numberWithFloat:pageouts]];
	}
	
	float percentage = ([[NSNumber numberWithUnsignedInt:used] floatValue] / [[NSNumber numberWithUnsignedInt:total] floatValue]) * 100;
	
	NSArray *latestData = [NSArray arrayWithObjects:
		[self format_size:[NSNumber numberWithUnsignedInt:free]],
		[self format_size:[NSNumber numberWithUnsignedInt:used]],
		[self format_size:[NSNumber numberWithUnsignedInt:active]],
		[self format_size:[NSNumber numberWithUnsignedInt:inactive]],
		[self format_size:[NSNumber numberWithUnsignedInt:wired]],
		[NSNumber numberWithFloat:percentage],
		[NSArray arrayWithObjects:
			pagesins_formatted,
			[formatter stringFromNumber:[NSNumber numberWithFloat:pageins]],nil],
		[NSArray arrayWithObjects:
			pagesouts_formatted,
			[formatter stringFromNumber:[NSNumber numberWithFloat:pageouts]],nil],
		[self format_size:[NSNumber numberWithUnsignedInt:inactive + free]],
		[self getSwap],
		nil];
	return latestData;
}

- (NSString *)format_size:(NSNumber *)input {
	[[NSAutoreleasePool alloc] init];
	float value = [input floatValue];
	NSString *types[3]= {@"MB",@"GB",@"TB" };

	int i = 0;
	while(value > 1000 && i < 4){
		value = value/1024;
		i++;
	}
		
	if(i == 0)
		return [NSString stringWithFormat:@"%.0f<span class='size'>%@</span>",value,types[i]];
	else if(value < 10)
		return [NSString stringWithFormat:@"%.2f<span class='size'>%@</span>",value,types[i]];
	else if(value >= 10 && value < 100)
		return [NSString stringWithFormat:@"%.1f<span class='size'>%@</span>",value,types[i]];
	else if(value >= 100)
		return [NSString stringWithFormat:@"%.0f<span class='size'>%@</span>",value,types[i]];
	else
		return [NSString stringWithFormat:@"%.2f<span class='size'>%@</span>",value,types[i]];
}

- (NSString *)convertSwap:(NSNumber *)input {
	[[NSAutoreleasePool alloc] init];
	float value = [input floatValue];
	NSString *types[3]= {@"MB",@"GB",@"TB" };
	int i=0;
	while(value > 1000){
		value = value/1024;
		i++;
	}
	
	if(i == 0)
		return [NSString stringWithFormat:@"%.0f<span class='size'>%@</span>",value,types[i]];
	else if(value < 10)
		return [NSString stringWithFormat:@"%.1f<span class='size'>%@</span>",value,types[i]];
	else if(value >= 10)
		return [NSString stringWithFormat:@"%.1f<span class='size'>%@</span>",value,types[i]];
	return @"<span class='size'>%@</span>";
}


@end
