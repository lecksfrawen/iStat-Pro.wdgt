//
//  ISPDataMinerCPU.h
//  iStat
//
//  Created by iSlayer on 17/04/07.
//  Copyright 2007 iSlayer & Distorted Vista. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>
#import <mach/mach.h>
#import <mach/mach_error.h>
#import <mach/machine.h>
#import <mach/mach_types.h>
#import <mach/processor_info.h>
#import <sys/sysctl.h>

@interface ISPDataMinerCPU : NSObject {
	host_name_port_t mach_port;
	processor_set_name_port_t proc_port;
	processor_cpu_load_info_t last_info;
	int processors;
	time_t bootTime;
}

- (void)setup;
- (NSArray *)getDataSet;
- (NSString *)getLoad;
- (NSString *)processInfo;
- (NSString *)getUptime;
- (NSString *)getBoottime;

@end
