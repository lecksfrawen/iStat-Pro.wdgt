//
//  ISPDataMinerMemory.h
//  iStat
//
//  Created by iSlayer on 17/04/07.
//  Copyright 2007 iSlayer & Distorted Vista. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <mach/host_info.h>
#import <mach/mach_host.h>
#include <mach/machine/vm_param.h>
#include <mach/machine/vm_types.h>
#include <sys/sysctl.h>

@interface ISPDataMinerMemory : NSObject {
	mach_port_t host_port;
	NSNumberFormatter *formatter;
}

- (NSArray *)getDataSet;
- (NSString *)format_size:(NSNumber *)input;
- (NSString *)getSwap;
- (NSString *)convertSwap:(NSNumber *)input;

@end
