//
//  ISMDiskObject.h
//  iStatMenusDrives
//
//  Created by Buffy Summers on 29/07/08Tuesday.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CoreServices/CoreServices.h>

@interface ISMDiskObject : NSObject {
	BOOL _enabled;
	BOOL _boot;
	BOOL _isInEjectMode;
	int index;
	BOOL _optical;
	BOOL _ejectable;
	BOOL _whole;
	BOOL _virtual;
	NSString *_uid;
	NSString *_iconPath;
	NSString *_displayName;
	NSString *_fullPath;
	unsigned long long size;
	unsigned long long free;
	unsigned long long used;
	float percentage;
	float _percentage;
	
	NSString *mountPath;
	BOOL mounted;
	BOOL overrideWhole;
	BOOL whole;
	NSString *visibleName;
	NSString *iconFile;
	NSString *iconLocation;
	NSString *bsdName;
	NSString *bsdWholeName;
}

- (NSString *)base2Size:(double)input;
- (NSString *)base10Size:(double)input;

@end
