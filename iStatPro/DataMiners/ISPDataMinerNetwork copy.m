//
//  ISPDataMinerNetwork.m
//  iStat
//
//  Created by iSlayer on 17/04/07.
//  Copyright 2007 iSlayer & Distorted Vista. All rights reserved.
//

#import "ISPDataMinerNetwork.h"
#import "ISPNetworkConnectionController.h"


@implementation ISPDataMinerNetwork

- (void)setNeedsUpdate:(BOOL)needs {
	needsUpdate = needs;
}

- (NSArray *)getDataSet {
	if(needsUpdate){
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
		
			// Initialize connection controller. Different methods are used based on the OS
			ISPNetworkConnectionController *controller = [[ISPNetworkConnectionController alloc] initWithServiceID:[[specs objectAtIndex:x] valueForKey:@"serviceid"] interfaceName:[[specs objectAtIndex:x] valueForKey:@"interfacename"] isPPP:isPPP];
			
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
				[controller updatePPPDetails];
			}
			// store connection controller
			[_networkConnectionControllers setObject:controller forKey:[[specs objectAtIndex:x] valueForKey:@"serviceid"]];
		}
		
		// TO FIX - Needs to use 0 for each item

		// Any id's left in this array are connections that are no longer active so we need to remove them from display and dispose of them
		NSArray *leftoverIds = [storedServiceIDs copy];
		int y;
		for(y=0;y<[leftoverIds count];y++){
			[_networkConnectionControllers removeObjectForKey:[leftoverIds objectAtIndex:y]];
			[storedServiceIDs removeObject:[leftoverIds objectAtIndex:y]];
		}
		
		needsUpdate = NO;
	}
	
	[self bandwidthData];
	
	return [NSArray array];
}

- (void) dealloc {
	if(sys_config_session)
		CFRelease(sys_config_session);
	[super dealloc];
}

- (NSString *)convertM:(NSNumber *)input {
	[[NSAutoreleasePool alloc] init];
	int i = 0;
	float value = [input floatValue];
	NSString *types[3]= {@"MB",@"GB",@"TB" };
	while(value > 1000){
		value = value / 1024;
		i++;
	}
	if(i == 0)
		return [NSString stringWithFormat:@"%.0f<span class='size'>%@</span>",value,types[i]];
	else
		return [NSString stringWithFormat:@"%.2f<span class='size'>%@</span>",value,types[i]];
}

- (NSString *)convertK:(NSNumber *)input {
	[[NSAutoreleasePool alloc] init];
	int i = 0;
	float value = [input floatValue];
	NSString *types[3]= {@"KB/S",@"MB/S",@"GB/S" };
	while(value > 1000){
		value = value / 1024;
		i++;
	}
	if(i == 0 || i == 1)
		return [NSString stringWithFormat:@"%.0f<span class='size'>%@</span>",value,types[i]];
	else
		return [NSString stringWithFormat:@"%.2f<span class='size'>%@</span>",value,types[i]];
}

- (id) init {
	self = [super init];

	sys_config_session = SCDynamicStoreCreate(kCFAllocatorSystemDefault, (CFStringRef)[self description], NULL, NULL);
	
	return self;
}

- (NSMutableDictionary *)bandwidthData {
	[[NSAutoreleasePool alloc] init];	
	double current_time = [[NSDate date] timeIntervalSince1970];
	double timer_difference = current_time - last_time;
	if(timer_difference < 0.5)
		timer_difference = 0.5;

	last_time = current_time;
				
	NSMutableDictionary *newData = [[NSMutableDictionary alloc] init];

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
	}
	
	if (sysctl(mib, 6, buf, &len, NULL, 0) < 0) {
		if (buf)
			free(buf);
		return [NSDictionary dictionary];
	}

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

			NSString *key = [NSString stringWithCString:sdl->sdl_data];
			[newData setObject:[NSArray arrayWithObjects:[NSNumber numberWithUnsignedLongLong:ibytes],[NSNumber numberWithUnsignedLongLong:obytes], nil] forKey:key];
		}
	}

	free(buf);
	return [newData autorelease];
}

- (NSArray *)getInterfaceSpecs {
	[[NSAutoreleasePool alloc] init];
	
	NSDictionary *servicesDict = (NSDictionary *)SCDynamicStoreCopyValue(sys_config_session,(CFStringRef)@"Setup:/Network/Global/IPv4"); // Get a list of all interfaces
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
		NSDictionary *serviceInterface = (NSDictionary *)SCDynamicStoreCopyValue(sys_config_session,(CFStringRef)servicePath); // Get the details for the current interface
		if(serviceInterface == NULL){
			[connection release];
			continue;
		}
		
		[connection setValue:service forKey:@"serviceid"];
	
		NSString *name = nil;
		
		
		if([serviceInterface objectForKey:@"DeviceName"])
			name = [serviceInterface objectForKey:@"DeviceName"];

		NSString *PPPPath = [NSString stringWithFormat:@"Setup:/Network/Service/%@/PPP",service]; // Get the ppp dictionary for the interface
		NSDictionary *PPPDetails = (NSDictionary *)SCDynamicStoreCopyValue(sys_config_session,(CFStringRef)PPPPath);
		if(PPPDetails != NULL){ // PPP Connection
			SCNetworkConnectionRef connRef = SCNetworkConnectionCreateWithServiceID(NULL, CFStringCreateWithCString(NULL,[service cString],NSUTF8StringEncoding) ,NULL,NULL);
			NSDictionary *extDetails = (NSDictionary *)SCNetworkConnectionCopyExtendedStatus(connRef);
			if(extDetails)
				[connection setValue:extDetails forKey:@"extended"];
				
			[connection setValue:PPPDetails forKey:@"PPP"];
			NSString *PPPState = [NSString stringWithFormat:@"State:/Network/Service/%@/PPP",service]; // Get the ppp dictionary for the interface
			NSDictionary *PPPStateDetails = (NSDictionary *)SCDynamicStoreCopyValue(sys_config_session,(CFStringRef)PPPState);
			
			NSString *usdPath = [NSString stringWithFormat:@"Setup:/Network/Service/%@",service];
			NSDictionary *usdDetails = (NSDictionary *)SCDynamicStoreCopyValue(sys_config_session,(CFStringRef)usdPath); // Get the details for the current interface
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
				continue; // No dictionary was found so we continue
			}
			if([PPPStateDetails valueForKey:@"InterfaceName"])
				name = [PPPStateDetails valueForKey:@"InterfaceName"];
			else {
				[connectionDetails addObject:connection];
				[connection release];
				continue; // no InterfaceName key means the interface is not active
			}
			[connectionDetails addObject:connection];
		}
		
		// Check Link status.We only care about active interfaces
		NSString *linkPath = [NSString stringWithFormat:@"State:/Network/Service/%@/Link",service];
		NSDictionary *interfaceLink = (NSDictionary *)SCDynamicStoreCopyValue(sys_config_session,(CFStringRef)linkPath); 
		if(interfaceLink != NULL){
			 if([[interfaceLink objectForKey:@"Active"] intValue] == 0){
				[connection release];
				continue;
			}
		}

		// Workout the path for the IP for the current Interface
		NSString *ipPath = [NSString stringWithFormat:@"State:/Network/Service/%@/IPv4",service];
		NSDictionary *interfaceIP = (NSDictionary *)SCDynamicStoreCopyValue(sys_config_session,(CFStringRef)ipPath);
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
		NSDictionary *usdDetails = (NSDictionary *)SCDynamicStoreCopyValue(sys_config_session,(CFStringRef)usdPath); // Get the details for the current interface
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
			// SubType - This helps us differenciate Ethernet from Airport
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

@end
