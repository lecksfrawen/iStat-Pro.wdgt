//
//  iStatPro.h
//  iStatPro
//
//  Created by Buffy on 26/03/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import <WebKit/WebView.h>
#import "ISPDataMinerCPU.h"
#import "ISPDataMinerDisks.h"
#import "ISPDataMinerTemps.h"
#import "ISPDataMinerFans.h"
#import "ISPDataMinerNetwork.h"
#import "ISPDataMinerMemory.h"
#import "ISPDataMinerBattery.h"
#import "ISPBluetoothController.h"
#import "ISPSmartController.h"

@interface iStatPro : NSObject {
	ISPDataMinerCPU *cpuDataMiner;
	ISPDataMinerMemory *memoryDataMiner;
	ISPDataMinerDisks *disksDataMiner;
	ISPDataMinerNetwork *networkDataMiner;
	ISPDataMinerTemps *tempsDataMiner;
	ISPDataMinerFans *fansDataMiner;
	ISPDataMinerBattery *batteryDataMiner;
	ISPBluetoothController *btController;
	ISPSmartController *smartController;
	NSString *icon_directory;
	BOOL moduleInstalled;
	BOOL diskChange;
	BOOL btChange;
	
	BOOL shouldUpdateSMART;
	BOOL smartMonitoringEnabled;
	
	BOOL ready;
	WebView *wb_view;
}

+ (int)PPPRef;

@end
