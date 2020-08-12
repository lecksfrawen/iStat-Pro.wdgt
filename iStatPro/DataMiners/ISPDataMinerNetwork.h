//
//  ISPDataMinerNetwork.h
//  iStat
//
//  Created by iSlayer on 17/04/07.
//  Copyright 2007 iSlayer & Distorted Vista. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include <SystemConfiguration/SCNetwork.h>
#include <SystemConfiguration/SCNetworkConfiguration.h>
#include <SystemConfiguration/SCNetworkConnection.h>
#include <SystemConfiguration/SystemConfiguration.h>


#include <net/if.h>
#include <net/if_var.h>
#include <net/if_dl.h>
#include <net/if_types.h>
#include <net/if_mib.h>
#include <net/ethernet.h>
#include <net/route.h>

#include <netinet/in.h>
#include <netinet/in_var.h>
#include <sys/sysctl.h>

@interface ISPDataMinerNetwork : NSObject {
	CFRunLoopSourceRef notificationLoop;
	SCDynamicStoreRef			scSession;
	SCDynamicStoreContext		scContext;
	
	BOOL _needsUpdate;

	NSMutableDictionary *_networkConnectionControllers;
	NSMutableDictionary *history;

//	NSArray *latestData;

//	NSMutableDictionary		*interfaceData;
//	NSMutableDictionary		*userDefinedNames;
//	NSMutableDictionary *hardwareConnections;
//	NSMutableArray*			networkArray;
//	NSMutableArray*			networkInterfaces;
	BOOL					needsUpdate;
	
//	NSMutableDictionary* lastData;
	
//	NSMutableDictionary *interfaceTypes;
//	NSMutableDictionary *interfaceSubTypes;
//	NSMutableDictionary *interfaceFilterKeys;
//	NSMutableDictionary *deviceFilterKeys;
		
//	double last_time;
	
}

- (NSArray *)getDataSet;
- (void)setNeedsUpdate:(BOOL)new;
- (NSArray *)getInterfaceTypes;

@end
