//
//  ISPDataMinerCPU.m
//  iStat
//
//  Created by iSlayer on 17/04/07.
//  Copyright 2007 iSlayer & Distorted Vista. All rights reserved.
//

#import "ISPDataMinerCPU.h"


@implementation ISPDataMinerCPU

static inline int max(int a, int b) {
  return a > b ? b : a;
}

static inline int min(int a, int b) {
  return a < b ? b : a;
}

- (id)init {
	self = [super init];
	
	mach_port = mach_host_self();
	processor_set_default(mach_port, &proc_port);
	
	[self setup];
	return self;
}

- (void)dealloc {
	mach_port_deallocate(mach_task_self(), mach_port);
	free(last_info);		
	[super dealloc];
}

- (void)setup {
	int  error, selectors[2] = { CTL_HW, HW_NCPU };
	mach_msg_type_number_t		processorMsgCount;
	unsigned int	processor_count;
	size_t datasize = sizeof(processor_count);
	error = sysctl(selectors, 2, &processor_count, &datasize, NULL, 0);
	processor_cpu_load_info_t	processorTickInfo;
	host_processor_info(mach_port, PROCESSOR_CPU_LOAD_INFO, &processor_count, (processor_info_array_t *)&processorTickInfo, &processorMsgCount);		
    last_info   = malloc(processor_count * sizeof(*last_info));

	int i, j;
    for (i = 0; i < processor_count; i++) {
		for (j = 0; j < CPU_STATE_MAX; j++) {
			last_info[i].cpu_ticks[j] = processorTickInfo[i].cpu_ticks[j];
		}
	}
	vm_deallocate(mach_port, (vm_address_t)processorTickInfo, (vm_size_t)(processorMsgCount * sizeof(*processorTickInfo)));
}

- (NSString *)processCount {
	kern_return_t result;
	struct processor_set_load_info processData;
	unsigned int count = PROCESSOR_SET_LOAD_INFO_COUNT;
	
	result = processor_set_statistics(proc_port, PROCESSOR_SET_LOAD_INFO, (processor_set_info_t)&processData, &count);
	if (result == KERN_SUCCESS)
		return [NSString stringWithFormat:@"%i",processData.task_count];
	return @"0";
}

- (NSArray *)getDataSet {
	[[NSAutoreleasePool alloc] init];	
	NSMutableArray *per_core_data = [[NSMutableArray alloc] init];
	
	mach_msg_type_number_t processorMsgCount;
	processor_cpu_load_info_t new_info;
	unsigned int processor_count;
	int i;
	int total_core_ticks;
	int total_user = 0;
	int total_sys = 0;
	int total_nice = 0;

	host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &processor_count, (processor_info_array_t *)&new_info, &processorMsgCount);
	for(i=0;i<processor_count;i++){
		total_core_ticks = 0;
		int j;
		for (j = 0; j < CPU_STATE_MAX; j++) {
			total_core_ticks += new_info[i].cpu_ticks[j] - last_info[i].cpu_ticks[j];
		}
		
		float core_sys = (new_info[i].cpu_ticks[CPU_STATE_SYSTEM] - last_info[i].cpu_ticks[CPU_STATE_SYSTEM]) / (float)total_core_ticks * 100;
		float core_user = (new_info[i].cpu_ticks[CPU_STATE_USER] - last_info[i].cpu_ticks[CPU_STATE_USER]) / (float)total_core_ticks * 100;
		float core_nice = (new_info[i].cpu_ticks[CPU_STATE_NICE] - last_info[i].cpu_ticks[CPU_STATE_NICE]) / (float)total_core_ticks * 100;

		total_sys += core_sys;
		total_user += core_user;
		total_nice += core_nice;

		[per_core_data addObject:[NSArray arrayWithObjects:[NSNumber numberWithInt:(core_sys + core_user + core_nice)],[NSNumber numberWithFloat:core_sys], [NSNumber numberWithFloat:core_user], [NSNumber numberWithFloat:core_nice] , nil]];

		for(j = 0; j < CPU_STATE_MAX; j++){
			last_info[i].cpu_ticks[j] = new_info[i].cpu_ticks[j];
		}
	}
	vm_deallocate(mach_task_self(), (vm_address_t)new_info, (vm_size_t)(processor_count * sizeof(*last_info)));

	// average out usage
	int activeProcs = processor_count;
	if(activeProcs > 1) {
		total_sys = total_sys / activeProcs;
		total_user = total_user / activeProcs;
		total_nice = total_nice / activeProcs;
	}
	
	// make sure numbers are valid
	total_sys = min(max(total_sys, 100), 0);
	total_user = min(max(total_user, 100), 0);
	total_nice = min(max(total_nice, 100), 0);

	int idle = min(max(100 - total_sys - total_user - total_nice, 100), 0);

	NSArray *overall_data = [NSArray arrayWithObjects:[NSNumber numberWithInt:total_sys],[NSNumber numberWithInt:total_user],[NSNumber numberWithInt:total_nice],[NSNumber numberWithInt:idle],[NSNumber numberWithInt:100 - idle],nil];
	NSArray *final_data = [NSArray arrayWithObjects:overall_data, per_core_data, nil];
	[per_core_data release];
	return final_data;
}

- (NSString *)getLoad {
	[[NSAutoreleasePool alloc] init];
	struct loadavg loadinfo;
	int mib[2];
	size_t size;
	mib[0] = CTL_VM;
	mib[1] = VM_LOADAVG;
	size = sizeof(loadinfo);
	sysctl(mib, 2, &loadinfo, &size, NULL, 0);

	return [NSString stringWithFormat:@"%.2f, %.2f, %.2f",(double) loadinfo.ldavg[0]/ loadinfo.fscale, (double) loadinfo.ldavg[1]/ loadinfo.fscale, (double) loadinfo.ldavg[2]/ loadinfo.fscale];
}

- (NSString *)processInfo {
	kern_return_t result;
	struct processor_set_load_info process_data;
	unsigned int count = PROCESSOR_SET_LOAD_INFO_COUNT;
	
	result = processor_set_statistics(proc_port, PROCESSOR_SET_LOAD_INFO, (processor_set_info_t)&process_data, &count);
	if (result != KERN_SUCCESS)
		return @"";
	else
		return [NSString stringWithFormat:@"%i tasks, %i threads",process_data.task_count, process_data.thread_count];
} 

- (NSString *)getUptime {
	int days, hours, minutes, seconds;
    struct timeval boot_time;
    size_t size = sizeof(boot_time);
    int mib[2] = { CTL_KERN, KERN_BOOTTIME };    
	
    time_t now = time(&now);
	
	if(!bootTime){
		if ((sysctl(mib, 2, &boot_time, &size, NULL, 0) != -1) && (boot_time.tv_sec != 0))
			bootTime = boot_time.tv_sec;
	}
	
	seconds = now - bootTime;
	
	days = seconds / (60 * 60 * 24);
	seconds %= (60 * 60 * 24);
	
	hours = seconds / (60 * 60);
	seconds %= (60 * 60);
	
	minutes = seconds / 60;
	seconds %= 60;
	
	return [NSString stringWithFormat:@"%id %ih %im", days, hours, minutes, seconds];
}

- (NSString *)getBoottime {
    time_t currentTime;
    struct timeval bootTime;
    size_t size = sizeof(bootTime);
    int mib[2] = { CTL_KERN, KERN_BOOTTIME };    

    time(&currentTime);
        
	sysctl(mib, 2, &bootTime, &size, NULL, 0);
	
	NSString *boottime = [[[NSDate dateWithTimeIntervalSince1970:bootTime.tv_sec] dateWithCalendarFormat:nil timeZone:nil] descriptionWithCalendarFormat:@"%H:%M, %b %e"];

	return boottime;
}

@end
