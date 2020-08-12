//
//  ISPDataMinerNetwork.m
//  iStat
//
//  Created by iSlayer on 17/04/07.
//  Copyright 2007 iSlayer & Distorted Vista. All rights reserved.
//

#import "ISPDataMinerNetwork.h"
#import "ISPNetworkConnectionController.h"
#import "NetworkHistoryObject.h"

@implementation NSArray(ISPSort2)

- (NSComparisonResult)sortNetwork:(NSArray *)other {
    return [[self objectAtIndex:7] compare:[other objectAtIndex:7]];
}

@end

@implementation ISPDataMinerNetwork

int updateList = 0;

static void networkChangeCallback(SCDynamicStoreRef store, CFArrayRef changedKeys, void *info) {
	updateList = 1;
	[(ISPDataMinerNetwork *)info networkChange:nil];
}

- (BOOL)needsUpdate {
	return _needsUpdate;
}

- (void)networkChange:(NSNotification *)note {
	_needsUpdate = YES;
}


- (void)togglePPP:(NSString *)service {
	if([_networkConnectionControllers objectForKey:service]){
		[[_networkConnectionControllers objectForKey:service] togglePPP];
	}
}

- (NSArray *)getDataSet {
	if(_needsUpdate){
		NSMutableArray *storedServiceIDs = [[NSMutableArray alloc] init];
		[storedServiceIDs addObjectsFromArray:[_networkConnectionControllers allKeys]];
		
		int x;
		NSArray *specs = [self getInterfaceSpecs];

		for(x=0;x<[specs count];x++){
			// Check if we already have a controller for the connection
			if([_networkConnectionControllers objectForKey:[[specs objectAtIndex:x] valueForKey:@"serviceid"]]){
				// remove the servide id so it doesnt get deleted at the end
				[storedServiceIDs removeObject:[[specs objectAtIndex:x] valueForKey:@"serviceid"]];
				// Update connection details
				[[_networkConnectionControllers objectForKey:[[specs objectAtIndex:x] valueForKey:@"serviceid"]] updateConnectionDetails:[specs objectAtIndex:x]];
				[[_networkConnectionControllers objectForKey:[[specs objectAtIndex:x] valueForKey:@"serviceid"]] setAddress:[[specs objectAtIndex:x] valueForKey:@"ip"]];
				// Check if service is PPP based
				if([[_networkConnectionControllers objectForKey:[[specs objectAtIndex:x] valueForKey:@"serviceid"]] isPPP]){
					// Update connection
					[[_networkConnectionControllers objectForKey:[[specs objectAtIndex:x] valueForKey:@"serviceid"]] setInterfaceName:[[specs objectAtIndex:x] valueForKey:@"interfacename"]];
					[[_networkConnectionControllers objectForKey:[[specs objectAtIndex:x] valueForKey:@"serviceid"]] updatePPPDetails];
					// Check if connection uses a modem
					if([[_networkConnectionControllers objectForKey:[[specs objectAtIndex:x] valueForKey:@"serviceid"]] isModem]){
						// Update connection speed
						if([[specs objectAtIndex:x] valueForKey:@"extended"] && [[[specs objectAtIndex:x] valueForKey:@"extended"] valueForKey:@"Modem"] && [[[[specs objectAtIndex:x] valueForKey:@"extended"] valueForKey:@"Modem"] valueForKey:@"ConnectSpeed"]){
							[[_networkConnectionControllers objectForKey:[[specs objectAtIndex:x] valueForKey:@"serviceid"]] setConnectionSpeed:[[[[specs objectAtIndex:x] valueForKey:@"extended"] valueForKey:@"Modem"] valueForKey:@"ConnectSpeed"]];
						} else {
							[[_networkConnectionControllers objectForKey:[[specs objectAtIndex:x] valueForKey:@"serviceid"]] setConnectionSpeed:[NSNumber numberWithInt:-1]];					
						}
					}
				}
				// Update connection name and continue
				[[_networkConnectionControllers objectForKey:[[specs objectAtIndex:x] valueForKey:@"serviceid"]] setConnectionName:[[specs objectAtIndex:x] valueForKey:@"name"]];
				continue;
			}
			
			BOOL isPPP = NO;
			
			
			// If we get to this point then this is a connection we dont yet know about
			if([[specs objectAtIndex:x] objectForKey:@"PPP"])
				isPPP = YES;
			
			if([[specs objectAtIndex:x] valueForKey:@"hardware"] && [[[specs objectAtIndex:x] valueForKey:@"hardware"] isEqualToString:@"AirPort"]){
				isPPP = NO; // workaround for some wierd case where an airport interface has a PPP key
			}
		
			// Initialize connection controller. Different methods are used based on the OS
			ISPNetworkConnectionController *controller = [[ISPNetworkConnectionController alloc] initWithServiceID:[[specs objectAtIndex:x] valueForKey:@"serviceid"] definedName:[[specs objectAtIndex:x] valueForKey:@"name"] interfaceName:[[specs objectAtIndex:x] valueForKey:@"interfacename"] subtype:[[specs objectAtIndex:x] valueForKey:@"hardware"] isPPP:isPPP];
			[controller setSortIndex:x];
			
			// If connection uses a modem then tell controller
			if([[[specs objectAtIndex:x] valueForKey:@"hardware"] isEqualToString:@"Modem"])
				[controller setIsModem];
			[controller updateConnectionDetails:[specs objectAtIndex:x]];
			[controller setConnectionName:[[specs objectAtIndex:x] valueForKey:@"name"]];
			[controller setAddress:[[specs objectAtIndex:x] valueForKey:@"ip"]];
			if([[specs objectAtIndex:x] valueForKey:@"hardware"])
				[controller setHardwareType:[[specs objectAtIndex:x] valueForKey:@"hardware"]];
			
			
			if(isPPP){
				if([controller isModem]){ // Update connection speed for modem
					if([[specs objectAtIndex:x] valueForKey:@"extended"] && [[[specs objectAtIndex:x] valueForKey:@"extended"] valueForKey:@"Modem"] && [[[[specs objectAtIndex:x] valueForKey:@"extended"] valueForKey:@"Modem"] valueForKey:@"ConnectSpeed"]){
						[controller setConnectionSpeed:[[[[specs objectAtIndex:x] valueForKey:@"extended"] valueForKey:@"Modem"] valueForKey:@"ConnectSpeed"]];
					} else {
						[controller setConnectionSpeed:[NSNumber numberWithInt:-1]];					
					}
				}
				// Update PPP Details and submenu layout
				[controller fetchPPPConnection];
				[controller updatePPPDetails];
			}
			// store connection controller
			[_networkConnectionControllers setObject:controller forKey:[[specs objectAtIndex:x] valueForKey:@"serviceid"]];
		}
		

		// Any id's left in this array are connections that are no longer active so we need to remove them from display and dispose of them
		int y;
		for(y=0;y<[storedServiceIDs count];y++){
			[_networkConnectionControllers removeObjectForKey:[storedServiceIDs objectAtIndex:y]];
			[storedServiceIDs removeObjectAtIndex:y];
			y--;
		}
		[storedServiceIDs release];
		_needsUpdate = NO;
	}
	
	NSMutableArray *returnData = [[NSMutableArray alloc] init];
	NSDictionary *data = [self bandwidthData];
	NSArray *historyKeys = [data allKeys];
	int x;
	for(x=0;x<[historyKeys count];x++){
		NSString *key = [historyKeys objectAtIndex:x];
		if(![history objectForKey:key]){
			NSArray *d = [data objectForKey:[historyKeys objectAtIndex:x]];
			NetworkHistoryObject *h = [[NetworkHistoryObject alloc] initWithRx:[[d objectAtIndex:0] unsignedLongLongValue] tx:[[d objectAtIndex:1] unsignedLongLongValue]];
			[history setObject:h forKey:key];
			[h release];
		}
	}

	historyKeys = [history allKeys];
	for(x=0;x<[historyKeys count];x++){
		NSString *key = [historyKeys objectAtIndex:x];
		if(![data objectForKey:key]){
			[history removeObjectForKey:key];
		} else {
			NSArray *d = [data objectForKey:[historyKeys objectAtIndex:x]];
			NetworkHistoryObject *h = [history objectForKey:key];
			[h addRx:[[d objectAtIndex:0] unsignedLongLongValue] tx:[[d objectAtIndex:1] unsignedLongLongValue]];
		}
	}

	int y;
	NSArray *keys = [_networkConnectionControllers allKeys];
	for(y=0;y<[keys count];y++){
		NSString *key = [[_networkConnectionControllers objectForKey:[keys objectAtIndex:y]] interfaceName];
		if([data objectForKey:key]){
			[[_networkConnectionControllers objectForKey:[keys objectAtIndex:y]] updateInterfaceData:[data objectForKey:key]];
		}
		// Update PPP details
		if([[_networkConnectionControllers objectForKey:[keys objectAtIndex:y]] isPPP])
			[[_networkConnectionControllers objectForKey:[keys objectAtIndex:y]] updatePPPDetails];
		
		[returnData addObject:[[_networkConnectionControllers objectForKey:[keys objectAtIndex:y]] interfaceData]];
	}
	[returnData sortUsingSelector:@selector(sortNetwork:)];
	return [returnData autorelease];
}

- (NSArray *)historyForInterface:(NSString *)key {
	if(![history objectForKey:key])
		return [NSArray array];
	
	NetworkHistoryObject *h = [history objectForKey:key];
	struct networkactivity *historyObject = [h history];
	
	NSMutableArray *historyData = [[NSMutableArray alloc] init];
	unsigned long long peak = 0;
	int x;
	for(x=199;x>=0;x--){	
		[historyData addObject:[NSArray arrayWithObjects:[NSNumber numberWithUnsignedLongLong:historyObject[x].rxConverted], [NSNumber numberWithUnsignedLongLong:historyObject[x].txConverted], nil]];
	}
	return [historyData autorelease];
}

- (void) dealloc {
	CFRelease(scSession);
	CFRunLoopRemoveSource(CFRunLoopGetCurrent(), notificationLoop, kCFRunLoopDefaultMode);
	CFRelease(notificationLoop);
	[super dealloc];
}

- (id) init {
	self = [super init];
	_networkConnectionControllers = [[NSMutableDictionary alloc] init];
	history = [[NSMutableDictionary alloc] init];
	
	scContext.version = 0;
	scContext.info = self;
	scContext.retain = NULL;
	scContext.release = NULL;
	scContext.copyDescription = NULL;

	scSession = SCDynamicStoreCreate(kCFAllocatorDefault, (CFStringRef)[self description], networkChangeCallback, &scContext);

	SCDynamicStoreSetNotificationKeys(scSession, (CFArrayRef)[NSArray arrayWithObjects:@"State:/Network/Global/IPv4", @"Setup:/Network/Global/IPv4", @"State:/Network/Interface", nil], (CFArrayRef)[NSArray arrayWithObjects:@"State:/Network/Interface/.*/IPv4", @"State:/Network/Interface/.*/Link", @"State:/Network/Service/.*/IPv4", @"State:/Network/Service/.*/PPP", nil]);
	notificationLoop = SCDynamicStoreCreateRunLoopSource(kCFAllocatorDefault, scSession, 0);
	CFRunLoopAddSource(CFRunLoopGetCurrent(), notificationLoop, kCFRunLoopDefaultMode);
	CFRetain(notificationLoop);
	
	_needsUpdate = YES;
	
	return self;
}

- (NSMutableDictionary *)bandwidthData {
	u_int64_t ibytes = 0;
	u_int64_t obytes = 0;

	struct if_msghdr *ifm;
	struct ifmedia_description *media;
	struct ifreq *ifr;

	int i;
	i=0;			
    int mib[6];
    char *buf = NULL, *lim, *next;
	size_t len;
	
	mib[0]	= CTL_NET;			
	mib[1]	= PF_ROUTE;	
	mib[2]	= 0;
	mib[3]	= 0;
	mib[4]	= NET_RT_IFLIST2;
	mib[5]	= 0;
	if (sysctl(mib, 6, NULL, &len, NULL, 0) < 0)
		return [NSDictionary dictionary];

	if ((buf = malloc(len)) == NULL) {
		return [NSDictionary dictionary];
	}
	
	if (sysctl(mib, 6, buf, &len, NULL, 0) < 0) {
		if (buf)
			free(buf);
		return [NSDictionary dictionary];
	}

 	NSMutableDictionary *newData = [[NSMutableDictionary alloc] init];

	lim = buf + len;
    for (next = buf; next < lim; ) {
		char name[32];
		
		ifr = (struct ifreq *)next;
        ifm = (struct if_msghdr *)next;
		next += ifm->ifm_msglen;

        if (ifm->ifm_type == RTM_IFINFO2) {
			struct if_msghdr2 *if2m = (struct if_msghdr2 *)ifm;
			media = (struct ifmedia_description *)if2m;
            struct sockaddr_dl	*sdl = (struct sockaddr_dl *)(if2m + 1);
			strncpy(name, sdl->sdl_data, sdl->sdl_nlen);
			name[sdl->sdl_nlen] = 0;
			
			if ((if2m->ifm_flags & IFF_UP) == 0){
				continue;
			}
			sdl = (struct sockaddr_dl *)(if2m + 1);

			if(if2m->ifm_flags & IFF_LOOPBACK){
				continue;
			}
					
			ibytes = if2m->ifm_data.ifi_ibytes;
			obytes = if2m->ifm_data.ifi_obytes;
			
			ibytes = ibytes / 1024;
			obytes = obytes / 1024;

			char device_buf[64];
			strncpy(device_buf, sdl->sdl_data, sdl->sdl_nlen);
			device_buf[sdl->sdl_nlen] = NULL;
			NSString *key = [[NSString alloc] initWithCString:device_buf];
			[newData setObject:[NSArray arrayWithObjects:[NSNumber numberWithUnsignedLongLong:ibytes],[NSNumber numberWithUnsignedLongLong:obytes], nil] forKey:key];
			[key release];
		}
	}

	free(buf);
	return [newData autorelease];
}

- (NSArray *)getInterfaceSpecs {
	[[NSAutoreleasePool alloc] init];
	
	NSDictionary *servicesDict = (NSDictionary *)SCDynamicStoreCopyValue(scSession,(CFStringRef)@"Setup:/Network/Global/IPv4");
	NSArray *services = [servicesDict valueForKey:@"ServiceOrder"];
	if(!services){
		return [NSArray array];
	}

	NSMutableArray *connectionDetails = [[NSMutableArray alloc] init];

	int x;
	for(x=0;x<[services count];x++){
		NSMutableDictionary *connection = [[NSMutableDictionary alloc] init];
		NSString *service = [services objectAtIndex:x];
		NSString *servicePath = [NSString stringWithFormat:@"Setup:/Network/Service/%@/Interface",service];
		NSDictionary *serviceInterface = (NSDictionary *)SCDynamicStoreCopyValue(scSession,(CFStringRef)servicePath);
		if(serviceInterface == NULL){
			[connection release];
			continue;
		}
		
		[connection setValue:service forKey:@"serviceid"];
	
		NSString *name = nil;
		
		
		if([serviceInterface objectForKey:@"DeviceName"])
			name = [serviceInterface objectForKey:@"DeviceName"];

		NSString *PPPPath = [NSString stringWithFormat:@"Setup:/Network/Service/%@/PPP",service];
		NSDictionary *PPPDetails = (NSDictionary *)SCDynamicStoreCopyValue(scSession,(CFStringRef)PPPPath);
		if(PPPDetails != NULL){ // PPP Connection
			SCNetworkConnectionRef connRef = SCNetworkConnectionCreateWithServiceID(NULL, CFStringCreateWithCString(NULL,[service cString],NSUTF8StringEncoding) ,NULL,NULL);
			NSDictionary *extDetails = (NSDictionary *)SCNetworkConnectionCopyExtendedStatus(connRef);
			if(extDetails)
				[connection setValue:extDetails forKey:@"extended"];
				
			[connection setValue:PPPDetails forKey:@"PPP"];
			NSString *PPPState = [NSString stringWithFormat:@"State:/Network/Service/%@/PPP",service];
			NSDictionary *PPPStateDetails = (NSDictionary *)SCDynamicStoreCopyValue(scSession,(CFStringRef)PPPState);
			
			NSString *usdPath = [NSString stringWithFormat:@"Setup:/Network/Service/%@",service];
			NSDictionary *usdDetails = (NSDictionary *)SCDynamicStoreCopyValue(scSession,(CFStringRef)usdPath);
			if(usdDetails != NULL && [usdDetails valueForKey:@"UserDefinedName"])
				[connection setObject:[usdDetails valueForKey:@"UserDefinedName"] forKey:@"name"];
			else
				[connection setObject:@"Unknown" forKey:@"name"];
			
			if(name)
				[connection setObject:name forKey:@"interfacename"];

			if([serviceInterface objectForKey:@"Hardware"])
				[connection setObject:[serviceInterface objectForKey:@"Hardware"] forKey:@"hardware"];

			if([connection objectForKey:@"hardware"] == NULL){
				if([serviceInterface objectForKey:@"SubType"]){
					NSString *type = [serviceInterface objectForKey:@"SubType"];
					if([type isEqualToString:@"PPTP"] || [type isEqualToString:@"L2TP"]){
						[connection setObject:@"VPN" forKey:@"hardware"];
					}
				}
			}
				
			if(PPPStateDetails == NULL){
				[connectionDetails addObject:connection];
				[connection release];
				continue;
			}
			if([PPPStateDetails valueForKey:@"InterfaceName"])
				name = [PPPStateDetails valueForKey:@"InterfaceName"];
			else {
				[connectionDetails addObject:connection];
				[connection release];
				continue;
			}
			[connectionDetails addObject:connection];
		}
		
		// Check Link status.We only care about active interfaces
		NSString *linkPath = [NSString stringWithFormat:@"State:/Network/Service/%@/Link",service];
		NSDictionary *interfaceLink = (NSDictionary *)SCDynamicStoreCopyValue(scSession,(CFStringRef)linkPath); 
		if(interfaceLink != NULL){
			 if([[interfaceLink objectForKey:@"Active"] intValue] == 0){
				[connection release];
				continue;
			}
		}

		NSString *ipPath = [NSString stringWithFormat:@"State:/Network/Service/%@/IPv4",service];
		NSDictionary *interfaceIP = (NSDictionary *)SCDynamicStoreCopyValue(scSession,(CFStringRef)ipPath);
		if(interfaceIP == NULL){
			[connection release];		
			continue;
		}

		if(name == nil){ // if we dont have a device name by now then forget about the interface
			[connection release];
			continue;
		}
			
		[connection setValue:name forKey:@"interfacename"];

		// IP Address
		if([interfaceIP objectForKey:@"Addresses"]){
			[connection setObject:[[interfaceIP objectForKey:@"Addresses"] objectAtIndex:0] forKey:@"ip"];
		}			

		NSString *usdPath = [NSString stringWithFormat:@"Setup:/Network/Service/%@",service];
		NSDictionary *usdDetails = (NSDictionary *)SCDynamicStoreCopyValue(scSession,(CFStringRef)usdPath); // Get the details for the current interface
		if(usdDetails != NULL && [usdDetails valueForKey:@"UserDefinedName"])
			[connection setObject:[usdDetails valueForKey:@"UserDefinedName"] forKey:@"name"];
		else
			[connection setObject:@"Unknown" forKey:@"name"];
				
		// Interface Type (Ethernet, Modem etc)
		if([serviceInterface objectForKey:@"Type"])
			[connection setObject:[serviceInterface objectForKey:@"Type"] forKey:@"type"];
		else
			[connection setObject:@"Ethernet" forKey:@"type"];
	
		// Interface Hardware (Ethernet, Modem etc)
		if([serviceInterface objectForKey:@"SubType"]){
			NSString *type = [serviceInterface objectForKey:@"SubType"];
			if([type isEqualToString:@"PPTP"] || [type isEqualToString:@"L2TP"]){
				[connection setObject:@"VPN" forKey:@"hardware"];
				[connection setObject:@"VPN" forKey:@"subtype"];
			}
		}

		if([connection objectForKey:@"hardware"] == NULL){
			if([serviceInterface objectForKey:@"Hardware"])
				[connection setObject:[serviceInterface objectForKey:@"Hardware"] forKey:@"hardware"];
			else
				[connection setObject:@"Ethernet" forKey:@"hardware"];
		}
		
		if([connection objectForKey:@"subtype"] == NULL){
			if([serviceInterface objectForKey:@"SubType"])
				[connection setObject:[serviceInterface objectForKey:@"SubType"] forKey:@"subtype"];
			else
				[connection setObject:[connection objectForKey:@"hardware"] forKey:@"subtype"];
		}
			
		if([serviceInterface objectForKey:@"Type"]){
			NSString *type = [serviceInterface objectForKey:@"Type"];
			if([type isEqualToString:@"PPP"])
				[connection setObject:[connection valueForKey:@"name"] forKey:@"filterkey"];
			else
				[connection setObject:service forKey:@"filterkey"];
		} else
			[connection setObject:service forKey:@"filterkey"];
		
		if([connection objectForKey:@"PPP"] == NULL)
			[connectionDetails addObject:connection];
		[connection release];
	}
	
	return [connectionDetails autorelease];
}

- (void)resetBandwidth {
	NSArray *keys = [_networkConnectionControllers allKeys];
	int y;
	for(y=0;y<[keys count];y++){
		[[_networkConnectionControllers objectForKey:[keys objectAtIndex:y]] resetBandwidth];
	}	
}

@end
