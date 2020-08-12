//
//  DataMinerDiskActivity.h
//  iStatMenusDrives
//
//  Created by Buffy on 27/05/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <IOKit/IOKitLib.h>
#import <IOKit/storage/IOBlockStorageDriver.h>


@interface DataMinerDiskActivity : NSObject {
	double previousTime;
	IONotificationPortRef port;
	CFRunLoopSourceRef runLoop;
	io_iterator_t itr;
	io_iterator_t addItr;
	io_iterator_t rmvItr;
	BOOL state;
	UInt64 previousReadTotal;
	UInt64 previousWriteTotal;
}

@end
