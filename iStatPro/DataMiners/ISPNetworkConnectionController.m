//
//  ISPNetworkConnectionController.m
//  iStatPro
//
//  Created by Buffy Summers on 20/11/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "ISPNetworkConnectionController.h"
#import "PPPLib.h"
#include "iStatPro.h"

@implementation ISPNetworkConnectionController

- (id)initWithServiceID:(NSString *)serviceID definedName:(NSString *)definedName interfaceName:(NSString *)interfaceName subtype:(NSString *)subtype isPPP:(BOOL)isPPP {
	self = [super init];
	_serviceID = [serviceID copy];
	if(interfaceName)
		_interfaceName = [interfaceName copy];
	if(definedName)
		_definedName = [definedName copy];
	if(subtype)
		_subtype = [subtype copy];
		
	_isPPP = isPPP;
	resetTx = 0;
	resetRx = 0;
	lastTx = 0;
	lastRx = 0;
	totalTxB = 0;
	totalRxB = 0;
	lastPPPStatus = -1;
	pppTime = 0;
	_needsReset = YES;
	_PPPSpeed = [@"N/A" retain];
	return self;
}

- (void)fetchPPPConnection {
	pppConnection = SCNetworkConnectionCreateWithServiceID(NULL, _serviceID, NULL, NULL);  
}

- (void)setSortIndex:(int)index {
	_sortIndex = index;
}

- (NSNumber *)sortIndex {
	return [NSNumber numberWithInt:_sortIndex];
}


- (NSString *)bsdName {
	if(_interfaceName)
		return _interfaceName;
	return @"";
}

- (NSString *)userDefinedName {
	if(_definedName)
		return _definedName;
	return @"";
}

- (void)setIsModem {
	_isModem = YES;
}

- (void)setIsPPP:(BOOL)isPPP {
	_isPPP = isPPP;
}

- (void)togglePPP:(id)sender {
	SCNetworkConnectionStatus status = SCNetworkConnectionGetStatus(pppConnection);
	if(status != kSCNetworkConnectionInvalid){
		if(status == kSCNetworkConnectionDisconnected){			
			CFDictionaryRef optionsPlist = CFPreferencesCopyMultiple(
																	 CFPreferencesCopyKeyList(CFSTR("com.apple.networkConnect"), kCFPreferencesCurrentUser, kCFPreferencesCurrentHost),
																	 CFSTR("com.apple.networkConnect"),
																	 kCFPreferencesCurrentUser,
																	 kCFPreferencesCurrentHost);
			
			CFDictionaryRef options = NULL;
			if(optionsPlist && [(NSDictionary *)optionsPlist objectForKey:[self service]]){
				NSArray *items = [(NSDictionary *)optionsPlist objectForKey:[self service]];
				if(items){
					int x;
					for(x=0;x<[items count];x++){
						if([[items objectAtIndex:x] objectForKey:@"ConnectByDefault"] && [[[items objectAtIndex:x] objectForKey:@"ConnectByDefault"] intValue] == 1){
							options = (CFDictionaryRef)[items objectAtIndex:x];
							break;
						}
					}
				}
			}
			SCNetworkConnectionStart(pppConnection, options, true);
		} else {
			SCNetworkConnectionStop(pppConnection, true);
		}
	}
}

- (NSString *)service {
	return _serviceID;
}

- (BOOL)isPPP {
	return _isPPP;
}

- (BOOL)isModem {
	return _isModem;
}

- (NSString *)interfaceName {
	return _interfaceName;
}

- (void)setInterfaceName:(NSString *)name {
	if(_interfaceName)
		[_interfaceName release];
	_interfaceName = [name copy];
}

- (void)setConnectionName:(NSString *)name {
}

- (void)setConnectionSpeed:(NSNumber *)speed {
	if(speed){
		if(_PPPSpeed)
			[_PPPSpeed release];
		_PPPSpeed = nil;
		
		if([speed intValue] == -1)
			_PPPSpeed = [@"N/A" retain];
		else
			_PPPSpeed = [[NSString stringWithFormat:@"%@ bps", [speed stringValue]] retain];
	}
}

- (void)setHardwareType:(NSString *)type {
	if(!type)
		return;
}

- (void)setAddress:(NSString *)newAddress {
	if(ip)
		[ip release];
	ip = nil;
	
	if(newAddress)
		ip = [newAddress copy];
}

- (void)resetBandwidth {
	resetRx = totalRxB;
	resetTx = totalTxB;
	currentTx = 0;
	currentRx = 0;
	totalTx = 0;
	totalRx = 0;
}

- (void)updateInterfaceData:(NSArray *)data {
	int txCurrentLength = 0;
	int txTotalLength = 0;
	int rxCurrentLength = 0;
	int rxTotalLength = 0;
	
	if(_needsReset){
		_needsReset = NO;
		totalTx = [[data objectAtIndex:1] unsignedLongLongValue] - resetTx;
		totalRx = [[data objectAtIndex:0] unsignedLongLongValue] - resetRx;
	}
	
	totalTxB = [[data objectAtIndex:1] unsignedLongLongValue];
	totalRxB = [[data objectAtIndex:0] unsignedLongLongValue];
	
	unsigned long long newTx = [[data objectAtIndex:1] unsignedLongLongValue] - resetTx;
	unsigned long long newRx = [[data objectAtIndex:0] unsignedLongLongValue] - resetRx;
	
	currentTx = newTx - totalTx;
	currentRx = newRx - totalRx;
	if(currentTx < 0)
		currentTx = 0;
	if(currentRx < 0)
		currentRx = 0;
		
	lastTx = currentTx;
	lastRx = currentRx;
	
	totalTx = newTx;
	totalRx = newRx;
}


- (void)updatePPPDetails {
	NSDictionary *details = (NSDictionary *)SCNetworkConnectionCopyExtendedStatus(pppConnection);
	
	if(details != NULL && [details objectForKey:@"PPP"]){
		int statusNumber = [[[details objectForKey:@"PPP"] objectForKey:@"Status"] intValue];
		if(statusNumber != lastPPPStatus){
			lastPPPStatus = statusNumber;
			if(lastPPPStatus == kSCNetworkConnectionPPPConnected)
				_needsReset = YES;
			
			NSString *status;
			switch(statusNumber){
				case kSCNetworkConnectionPPPDisconnected:
					status = @"Not Connected";
					break;
				case kSCNetworkConnectionPPPInitializing:
				case kSCNetworkConnectionPPPConnectingLink:
				case kSCNetworkConnectionPPPDialOnTraffic:
				case kSCNetworkConnectionPPPNegotiatingLink:
				case kSCNetworkConnectionPPPWaitingForCallBack:
				case kSCNetworkConnectionPPPWaitingForRedial:
					status = @"Connecting...";
					break;
				case kSCNetworkConnectionPPPNegotiatingNetwork:
					status = @"Establishing...";
					break;
				case kSCNetworkConnectionPPPAuthenticating:
					status = @"Authenticating...";
					break;
				case kSCNetworkConnectionPPPConnected:
					status = @"Connected";
					break;
				case kSCNetworkConnectionPPPTerminating:
				case kSCNetworkConnectionPPPDisconnectingLink:
				case kSCNetworkConnectionPPPHoldingLinkOff:
				case kSCNetworkConnectionPPPSuspended:
					status = @"Disconnecting...";
					break;
				default:
					status = @"Unknown";
					break;
			}
		}
		u_int32_t link = 0;
		PPPGetLinkByServiceID([iStatPro PPPRef], (CFStringRef)[self service], &link);
		struct ppp_status *stat = NULL;
		PPPStatus([iStatPro PPPRef], link, &stat);
		if(stat){
			pppTime = stat->s.run.timeElapsed;
			free(stat);
		}
	} else {
		lastPPPStatus = 0;
	}
	if(details)
		[details release];
}

- (void)updateConnectionDetails:(NSDictionary *)details {
	
}

- (NSArray *)interfaceData {
	NSArray *pppData;
	NSArray *bandwidthData;
	if([self isPPP]){
		if([self isModem])
			pppData = [NSArray arrayWithObjects:[NSNumber numberWithInt:lastPPPStatus], [self pppTime], [self connectionSpeed], nil];
		else 
			pppData = [NSArray arrayWithObjects:[NSNumber numberWithInt:lastPPPStatus], [self pppTime], nil];
		
		if(lastPPPStatus == kSCNetworkConnectionPPPConnected){
			bandwidthData = [NSArray arrayWithObjects:[self convertK:[NSNumber numberWithUnsignedLongLong:currentRx]], [self convertK:[NSNumber numberWithUnsignedLongLong:currentTx]], [self convertM:[NSNumber numberWithUnsignedLongLong:totalRx]], [self convertM:[NSNumber numberWithUnsignedLongLong:totalTx]], nil];	
		} else {
			bandwidthData = [NSArray arrayWithObjects:[self convertK:[NSNumber numberWithInt:0]], [self convertK:[NSNumber numberWithInt:0]], [self convertM:[NSNumber numberWithInt:0]], [self convertM:[NSNumber numberWithInt:0]], nil];	
		}
	} else {
		pppData = [NSArray array];
		bandwidthData = [NSArray arrayWithObjects:[self convertK:[NSNumber numberWithUnsignedLongLong:currentRx]], [self convertK:[NSNumber numberWithUnsignedLongLong:currentTx]], [self convertM:[NSNumber numberWithUnsignedLongLong:totalRx]], [self convertM:[NSNumber numberWithUnsignedLongLong:totalTx]], nil];
	}
		
	return [NSArray arrayWithObjects:[self service], [self bsdName], [self interfaceSubType], [self ipaddress], [self userDefinedName], pppData, bandwidthData, [self sortIndex], nil];
}

- (NSString *)ipaddress {
	if(ip)
		return ip;
	return @"";
}

- (NSString *)interfaceSubType {
	if(_subtype)
		return _subtype;
	return @"";
}

- (NSString *)connectionSpeed {
	return _PPPSpeed;
}

- (NSString *)pppTime {
	if(lastPPPStatus != kSCNetworkConnectionPPPConnected)
		return @"N/A";
		
	unsigned int time = pppTime;
	int hours = 0;
	int minutes = 0;
	int seconds = 0;
	hours = time / 3600;
	time %= (3600);
	minutes = time / 60;
	time %= (60);
	seconds = time;
	
	NSString *hourString = [NSString stringWithFormat:@"%i", hours];
	NSString *minuteString = [NSString stringWithFormat:@"%i", minutes];
	NSString *secondString = [NSString stringWithFormat:@"%i", seconds];
	if(hours < 10)
		hourString = [NSString stringWithFormat:@"0%i", hours];
	if(minutes < 10)
		minuteString = [NSString stringWithFormat:@"0%i", minutes];
	if(seconds < 10)
		secondString = [NSString stringWithFormat:@"0%i", seconds];
		
	return [NSString stringWithFormat:@"%@:%@:%@", hourString, minuteString, secondString];
}


- (NSString *)convertM:(NSNumber *)input {
	unsigned long long value = [input unsignedLongLongValue];
	int i = 0;
	
	if(value == LONG_LONG_MAX)
		return @"0<span class='size'>KB</span>";

	if(value < 1000){ // KB
		return [NSString stringWithFormat:@"%llu<span class='size'>KB</span>",value];
	}
	
	
	value = value / 1024; // Move to MB
	
	if(value < 1000){ // MB
		return [NSString stringWithFormat:@"%llu<span class='size'>MB</span>",value];
	}
	
	i++;
	if(value < 1048576){ // GB
		float fValue = value / 1024.0;
		if(fValue < 10)
			return [NSString stringWithFormat:@"%.2f<span class='size'>GB</span>",fValue];
		else
			return [NSString stringWithFormat:@"%.1f<span class='size'>GB</span>",fValue];
	}
	
	i++;
	float fValue = value / 1048576.0; //TB
	if(fValue < 10)
		return [NSString stringWithFormat:@"%.2f<span class='size'>TB</span>",fValue];
	return [NSString stringWithFormat:@"%.1f<span class='size'>TB</span>",fValue];
}

- (NSString *)convertK:(NSNumber *)input {
	unsigned long long value = [input unsignedLongLongValue];
	int i = 0;

	if(value == LONG_LONG_MAX)
		return @"0<span class='size'>KB/S</span>";

	if(value < 1000){ // KB
		return [NSString stringWithFormat:@"%llu<span class='size'>KB/S</span>",value];
	}
	
	i++;
	if(value < 1048576){ // MB
		float fValue = value / 1024.0;
		return [NSString stringWithFormat:@"%.1f<span class='size'>MB/S</span>",fValue];
	}

	i++;
	if(value < 1073741824){ // MB
		float fValue = value / 1048576.0;
		return [NSString stringWithFormat:@"%.1f<span class='size'>GB/S</span>",fValue];
	}
	
	i++;
	float fValue = value / 1073741824.0; // TB
	return [NSString stringWithFormat:@"%.2f<span class='size'>TB/S</span>",fValue];
}

- (void)togglePPP {
	u_int32_t link = 0;
	PPPGetLinkByServiceID([iStatPro PPPRef], (CFStringRef)[self service], &link);
	struct ppp_status *stat = NULL;
	PPPStatus([iStatPro PPPRef], link, &stat);
	if(stat != NULL){
		if(stat->status == PPP_IDLE){
			PPPConnect([iStatPro PPPRef], link);
		} else {
			PPPDisconnect([iStatPro PPPRef], link);
		}
	}
}

@end
