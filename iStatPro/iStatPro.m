//
//  iStatPro.m
//  iStatPro
//
//  Created by Buffy on 26/03/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "iStatPro.h"
#import <IOBluetooth/objc/IOBluetoothDevice.h>
#include <DiskArbitration/DiskArbitration.h>

@implementation iStatPro

static int PPPRef;


+ (int)PPPRef {
	if(!PPPRef)
		PPPInit(&PPPRef);
	return PPPRef;
}

- (id)initWithWebView:(WebView *)w {
	self = [super init];
	wb_view = [w retain];
		
	diskChange = NO;
	btChange = NO;
	smartMonitoringEnabled = NO;
	

	icon_directory = [[NSString alloc] initWithString:[@"~/Library/Caches/iStatPro/" stringByExpandingTildeInPath]];

	BOOL isDir;
	BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:icon_directory isDirectory:&isDir];
    if (!exists){
		[[NSFileManager defaultManager] createDirectoryAtPath:icon_directory attributes:nil];
	}


	cpuDataMiner = [[ISPDataMinerCPU alloc] init];
	memoryDataMiner = [[ISPDataMinerMemory alloc] init];
	networkDataMiner = [[ISPDataMinerNetwork alloc] init];
	tempsDataMiner = [[ISPDataMinerTemps alloc] init];
	fansDataMiner = [[ISPDataMinerFans alloc] init];
	batteryDataMiner = [[ISPDataMinerBattery alloc] init];
	btController = [[ISPBluetoothController alloc] init];
	smartController = [[ISPSmartController alloc] init];
	
	[smartController getPartitions];
	
	shouldUpdateSMART = YES;

	[btController getKbLevel];
	[btController getMouseLevel];	
	
	[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self selector: @selector(workspaceChange:) name:NSWorkspaceDidMountNotification object:nil];
	[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self selector: @selector(workspaceChange:) name:NSWorkspaceDidUnmountNotification object:nil];	
	
	/*
	[IOBluetoothDevice registerForConnectNotifications:self selector:@selector(bluetoothConnection:toDevice:)];
	NSArray * bt_divices = [IOBluetoothDevice pairedDevices];
	int x;
	for(x=0;x<[bt_divices count];x++){
		if([[bt_divices objectAtIndex:x] isConnected]){
			[[bt_divices objectAtIndex:x] registerForDisconnectNotification:self selector:@selector(bluetoothDisconnection:fromDevice:)];
		}
	}
	*/
	return self;
}

- (void)dealloc {
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver: self name: NSWorkspaceDidMountNotification object:nil];
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver: self name: NSWorkspaceDidUnmountNotification object:nil];


	[wb_view release];

	[cpuDataMiner release];
	[memoryDataMiner release];
	[networkDataMiner release];
	[tempsDataMiner release];
	[fansDataMiner release];
	[batteryDataMiner release];
	[btController release];
	[smartController release];

	[super dealloc];
}

- (void)windowScriptObjectAvailable:(WebScriptObject*)wso {
	[wso setValue:self forKey:@"iStatPro"];
}

+ (NSString *)webScriptNameForSelector:(SEL)aSel {
	NSString *retval = nil;
	if (aSel == @selector(cpuUsage)) {
		retval = @"cpuUsage";
	} else if (aSel == @selector(memoryUsage)) {
		retval = @"memoryUsage";
	} else if (aSel == @selector(diskUsage)) {
		retval = @"diskUsage";
	} else if (aSel == @selector(network)) {
		retval = @"network";
	} else if (aSel == @selector(getAppPath::)) {
		retval = @"getAppPath";
	} else if (aSel == @selector(getselfpid)) {
		retval = @"getselfpid";
	} else if (aSel == @selector(getPsName:)) {
		retval= @"getPsName";
	} else if (aSel == @selector(temps:)) {
		retval= @"temps";
	} else if (aSel == @selector(fans)) {
		retval= @"fans";
	} else if (aSel == @selector(uptime)) {
		retval= @"uptime";
	} else if (aSel == @selector(load)) {
		retval= @"load";
	} else if (aSel == @selector(processinfo)) {
		retval= @"processinfo";
	} else if (aSel == @selector(battery)) {
		retval= @"battery";
	} else if (aSel == @selector(isLaptop)) {
		retval= @"isLaptop";
	} else if (aSel == @selector(isIntel)) {
		retval= @"isIntel";
	} else if (aSel == @selector(copyTextToClipboard:)) {
		retval= @"copyTextToClipboard";
	} else if (aSel == @selector(getMouseLevel)) {
		retval= @"getMouseLevel";
	} else if (aSel == @selector(getKbLevel)) {
		retval= @"getKbLevel";
	} else if (aSel == @selector(hasBtSetupChanged)) {
		retval= @"hasBtSetupChanged";
	} else if (aSel == @selector(hasBTMouse)) {
		retval= @"hasBTMouse";
	} else if (aSel == @selector(hasBTKeyboard)) {
		retval= @"hasBTKeyboard";
	} else if (aSel == @selector(readyForNotifications)) {
		retval= @"readyForNotifications";
	} else if (aSel == @selector(setNeedsSMARTUpdate)) {
		retval= @"setNeedsSMARTUpdate";
	} else if (aSel == @selector(setShouldMonitorSMARTTemps:)) {
		retval= @"setShouldMonitorSMARTTemps";
	} else if (aSel == @selector(togglePPP:)) {
		retval= @"togglePPP";
	} else if (aSel == @selector(openDisk:)) {
		retval= @"openDisk";
	} else if (aSel == @selector(processCount)) {
		retval= @"processCount";
	} else if (aSel == @selector(resetBandwidth)) {
		retval= @"resetBandwidth";
	} else if (aSel == @selector(historyForInterface:)) {
		retval= @"historyForInterface";
	}

	return retval;
}

- (void)readyForNotifications {
	ready = YES;
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)aSel {	
	return NO;
}

+ (BOOL)isKeyExcludedFromWebScript:(const char*)k {
	return YES;
}

- (void)openDisk:(NSString *)disk {
	[[NSWorkspace sharedWorkspace] openFile:disk];
}

- (void)togglePPP:(NSString *)service {
	[networkDataMiner togglePPP:service];
}

- (BOOL)hasBTKeyboard {
	return [btController kb];
}

- (BOOL)hasBTMouse {
	return [btController mouse];
}

- (void)setNeedsSMARTUpdate {
	shouldUpdateSMART = YES;
}

- (void)setShouldMonitorSMARTTemps:(int)should {
	if(should == 1)
		smartMonitoringEnabled = YES;
	else
		smartMonitoringEnabled = NO;
}

- (void)bluetoothConnection: (IOBluetoothUserNotification*)note toDevice: (IOBluetoothDevice *)device {
	[device registerForDisconnectNotification: self selector:@selector(bluetoothDisconnection:fromDevice:)];
	btChange = YES;
	
	// sent notification to widget after a delay. sending it instantly doesnt work because the devices dont register in iokit instantly
	[self performSelector:@selector(sendBTNotification) withObject:nil afterDelay:3];
}

- (void)sendBTNotification {
	[btController getKbLevel];
	[btController getMouseLevel];	
//	if(ready)
//		[wb_view stringByEvaluatingJavaScriptFromString:@"bt_change_from_plugin();"];
}

- (void)bluetoothDisconnection: (IOBluetoothUserNotification*)note fromDevice: (IOBluetoothDevice *)device {
	[note unregister];
	btChange = YES;

	// sent notification to widget after a delay. sending it instantly doesnt work because the devices dont register in iokit instantly
	[self performSelector:@selector(sendBTNotification) withObject:nil afterDelay:3];
}

- (NSString *)getKbLevel {
	return [btController getKbLevel];
}

- (NSString *)getMouseLevel {
	return [btController getMouseLevel];
}

- (BOOL)hasBtSetupChanged {
	if(btChange) {
		btChange = NO;
		return YES;
	}
	return NO;
}

- (void)copyTextToClipboard:(NSString *)text {
	NSPasteboard* pb = [NSPasteboard generalPasteboard];
	[pb declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
	[pb setString:text forType:NSStringPboardType];
}

- (void)workspaceChange:(NSNotification *)note {
	[[ISPDataMinerDisks dataMinerCore] findDrives];
	diskChange = YES;
	if(ready)
		[wb_view stringByEvaluatingJavaScriptFromString:@"disk_change_from_plugin();"];
	if(ready)
		[wb_view stringByEvaluatingJavaScriptFromString:@"dc.changeFromPlugin(0);"];
}

- (BOOL)hasDiskSetupChanged {
	if(diskChange) {
		diskChange = NO;
		return YES;
	}
	return NO;
}

- (BOOL)hasNetworkSetupChanged {
	if([networkDataMiner needsUpdate]){
		return YES;
	}
	return NO;
}


- (NSArray *)cpuUsage {
	return [cpuDataMiner getDataSet];
}

- (NSArray *)memoryUsage {
	return [memoryDataMiner getDataSet];
}

- (NSArray *)diskUsage {
	[[ISPDataMinerDisks dataMinerCore] update];
	return [[ISPDataMinerDisks dataMinerCore] getDataSet];
}

- (NSArray *)network {

	return [networkDataMiner getDataSet];
}

- (NSArray *)temps:(int)degrees {
	if(!smartMonitoringEnabled){
		return [tempsDataMiner getDataSet:degrees];
	}
	
	if(shouldUpdateSMART){
		shouldUpdateSMART = NO;
		[smartController update];
	}
	
	NSMutableArray *finalTemps = [[NSMutableArray alloc] init];
	
	NSArray *sensorTemps = [tempsDataMiner getDataSet:degrees];
	NSArray *smartTemps = [smartController getDataSet:degrees];
	
	
	[finalTemps addObjectsFromArray:smartTemps];
	[finalTemps addObjectsFromArray:sensorTemps];
	
	return [finalTemps autorelease];
}

- (NSArray *)fans {
	return [fansDataMiner getDataSet];
}

- (NSArray *)battery {
	return [batteryDataMiner getDataSet];
}

- (BOOL)isLaptop {
	return [batteryDataMiner isLaptop];
}

- (NSString *)uptime {
	return [cpuDataMiner getUptime];
}

- (NSString *)boottime {
	return [cpuDataMiner getBoottime];
}

- (NSString *)load {
	return [cpuDataMiner getLoad];
}

- (NSString *)processinfo {
	return [cpuDataMiner processInfo];
}

- (NSString *)getAppPath:(int)thePID:(NSString *)name {
	if([name hasPrefix:@"LaunchCFM"]){
		return @"";
	}

	FSRef theRef;
	ProcessSerialNumber psn;
	GetProcessForPID(thePID, &psn); 
	GetProcessBundleLocation(&psn, &theRef);

	CFURLRef url = CFURLCreateFromFSRef(kCFAllocatorDefault, &theRef);
	if (url) {
		NSString *pathName = (NSString *)CFURLCopyFileSystemPath(url, kCFURLPOSIXPathStyle);
		NSString *bundlePath = [[NSBundle bundleWithPath:pathName] bundleIdentifier];
		
		NSRange range = [bundlePath rangeOfString:@"/"];
		while(range.location != NSNotFound){
			bundlePath = [NSString stringWithFormat:@"%@%@", [bundlePath substringToIndex:range.location], [bundlePath substringFromIndex:range.location + 1]]; 
			range = [bundlePath rangeOfString:@"/"];
		}
		
		NSString *icon_path = [NSString stringWithFormat:@"%@/%@.tiff", icon_directory, bundlePath];
		if([[NSFileManager defaultManager] fileExistsAtPath:icon_path] == NO) {
			NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:pathName];
			NSArray *reps = [icon representations];
			if([reps count] > 0){
				int x;
				float smallestSize = FLT_MAX;
				int index = 0;
				
				for(x=0;x<[reps count];x++){
					NSSize size = [[reps objectAtIndex:x] size];
					if(size.width < smallestSize){
						smallestSize = size.width;
						index = x;
					}
				}
				
				NSImageRep *rep = [reps objectAtIndex:index];
				NSImage *repIcon = [[NSImage alloc] initWithSize:[rep size]];
				[repIcon addRepresentation:rep];
				
				NSData *tiffRep = [repIcon TIFFRepresentation];
				[tiffRep writeToFile:icon_path atomically:YES];
				[repIcon release];
			} else {
				NSData *tiffRep = [icon TIFFRepresentation];
				[tiffRep writeToFile:icon_path atomically:YES];
			}
		}
		CFRelease(url);
		CFRelease(pathName);
		return icon_path;
	}
	return @"";
}

- (NSString *)getPsName:(int)thePid {

	CFStringRef name = NULL;
	ProcessSerialNumber psn2;
	OSStatus err = GetProcessForPID(thePid, &psn2); 
	if(err != noErr) {
		return @"";
	}
	
	err = CopyProcessName(&psn2, &name);
	if(err != noErr) {
		return @"";
	}
	
	if(name == NULL)
		return @"";

	return (NSString *)name;
}

- (int)getselfpid {
	return getpid();
}

- (BOOL)isIntel {
	OSType		returnType;
	long		gestaltReturnValue,swappedReturnValue;
	returnType=Gestalt(gestaltNativeCPUtype, &gestaltReturnValue);
	if (!returnType){
		char		type[5] = { 0 };
		swappedReturnValue = EndianU32_BtoN(gestaltReturnValue);
		memmove( type, &swappedReturnValue, 4 );
		if(gestaltReturnValue == gestaltCPUPentium)
			return YES;
	}
	return NO;
}

- (NSString *)processCount {
	return [cpuDataMiner processCount];
}

- (void)resetBandwidth {
	[networkDataMiner resetBandwidth];
}

- (NSArray *)historyForInterface:(NSString *)key {
	return [networkDataMiner historyForInterface:key];
}

@end
