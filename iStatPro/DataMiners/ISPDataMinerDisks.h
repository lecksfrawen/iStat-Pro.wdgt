//
//  ISPDataMinerDisks.h
//  iStatMenusDisks
//
//  Created by iSlayer on 17/04/07.
//  Copyright 2007 iSlayer & Distorted Vista. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <IOKit/IOKitLib.h>
#import <IOKit/storage/IOBlockStorageDriver.h>
#include <IOKit/IOKitLib.h>
#include <IOKit/storage/IOMedia.h>
#include <IOKit/storage/IOStorageProtocolCharacteristics.h>
#include <IOKit/storage/IOCDMedia.h>
#include <IOKit/storage/IODVDMedia.h>
#include <sys/param.h>
#include <sys/mount.h>

@interface ISPDataMinerDisks : NSObject {
	NSMutableArray *_disks;
}

- (NSArray *)getDataSet;
- (void)findDrives;

@end
