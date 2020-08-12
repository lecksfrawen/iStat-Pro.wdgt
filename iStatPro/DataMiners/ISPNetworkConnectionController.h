//
//  ISPNetworkConnectionController.h
//  iStatPro
//
//  Created by Buffy Summers on 20/11/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <SystemConfiguration/SCNetworkConnection.h>


@interface ISPNetworkConnectionController : NSObject {
	SCNetworkConnectionRef pppConnection;
	unsigned long long totalTxB;
	unsigned long long totalRxB;
	unsigned long long totalTx;
	unsigned long long totalRx;
	unsigned long long lastTx;
	unsigned long long lastRx;
	unsigned long long currentTx;
	unsigned long long currentRx;

	unsigned long long resetTx;
	unsigned long long resetRx;

	unsigned int pppTime;
	NSString *_PPPSpeed;

	BOOL _needsReset;

	NSString *_serviceID;
	NSString *_interfaceName;
	NSString *_definedName;
	NSString *_subtype;
	
	BOOL _submenuOpen;
	BOOL _isPPP;
	BOOL _isModem;
	
	int lastPPPStatus;
	
	BOOL hasIP;
	NSString *ip;
	int _sortIndex;
}

@end
