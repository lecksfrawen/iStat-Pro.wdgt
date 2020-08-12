//
//  ISMDiskObject.m
//  iStatMenusDrives
//
//  Created by Buffy Summers on 29/07/08Tuesday.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "ISMDiskObject.h"
#import <DiskArbitration/DiskArbitration.h>

@implementation ISMDiskObject

- (void)dealloc {
	[super dealloc];
}

- (NSComparisonResult)sortDisks:(ISMDiskObject *)second {
	if(![[self bsdName] hasPrefix:@"disk"])
		return NSOrderedDescending;
	if(![[second bsdName] hasPrefix:@"disk"])
		return NSOrderedAscending;
	return [[self bsdName] compare:[second bsdName] options:NSCaseInsensitiveSearch];
}

- (void)setUuid:(NSString *)u {
	_uid = [u copy];
}

- (NSString *)uuid {
	if(_uid)
		return _uid;
	return mountPath;
}

- (NSString *)bsdName {
	return bsdName;
}

- (void)setBsdName:(NSString *)b {
	bsdName = [b copy];
}

- (NSString *)path {
	return mountPath;
}

- (void)setEnabled:(BOOL)enabled {
	_enabled = enabled;
}

- (void)setMounted:(BOOL)m {
	mounted = m;
}

- (BOOL)mounted {
	return mounted;
}

- (BOOL)enabled {
	return _enabled;
}

- (NSString *)mountPath {
	return mountPath;
}

- (NSString *)visibleName {
	return visibleName;
}

- (void)setMountPath:(NSString *)mp {
	mountPath = [mp copy];
}

- (void)setVisibleName:(NSString *)v {
	visibleName = [v copy];
}

- (NSNumber *)free {
	return [NSNumber numberWithUnsignedLongLong:free];
}

- (NSNumber *)used {
	return [NSNumber numberWithUnsignedLongLong:used];
}

- (NSString *)percentage {
	return [NSString stringWithFormat:@"%.0f", percentage];
}

- (void)update {
	FSRef pathRef;
	FSPathMakeRef([mountPath fileSystemRepresentation], &pathRef, NULL);
	FSCatalogInfo catInfo;
	FSGetCatalogInfo(&pathRef, kFSCatInfoVolume, &catInfo, NULL, NULL, NULL);
	
	FSVolumeInfo info;
	FSGetVolumeInfo (catInfo.volume, 0, NULL, kFSVolInfoSizes, &info, NULL, NULL);
	
	size = (unsigned long long)info.totalBytes / 1048576;
	free = (unsigned long long)info.freeBytes / 1048576;
	used = (unsigned long long)size - free;
	percentage = ((float)used / (float)size) * 100;
}
/*
- (NSString *)formattedSize:(NSNumber *)input {
	unsigned long long value = [input unsignedLongLongValue];
	NSString *str = nil;
	
	NSString *types[4]= {@"KB", @"MB", @"GB", @"TB"};
	
	if(value < 1000){ // KB
		str = [NSString stringWithFormat:@"%llu<span class='size'>%@</span>", value, types[0]];
	} else if(value < 1048576){ // MB
		str = [NSString stringWithFormat:@"%.0f<span class='size'>%@</span>", (float)value / 1024, types[1]];		
	} else if(value < 1073741824){ // GB
		unsigned long long wp = value / 1048576; // get whole gigabytes
		value %= 1048576; // remove whole 
		float fvalue = (float)value / 1048576; // get leftover percentage
		fvalue += wp; // combine whole and percentage
		if(fvalue > 99)
			str = [NSString stringWithFormat:@"%.1f<span class='size'>%@</span>",fvalue,types[2]];
		else
			str = [NSString stringWithFormat:@"%.2f<span class='size'>%@</span>",fvalue,types[2]];
	} else { // TB
		unsigned long long wp = value / 1073741824; // get whole gigabytes
		value %= 1073741824; // remove whole 
		float fvalue = (float)value / 1073741824; // get leftover percentage
		fvalue += wp; // combine whole and percentage
		if(fvalue > 99)
			str = [NSString stringWithFormat:@"%.1f<span class='size'>%@</span>",fvalue,types[3]];
		else
			str = [NSString stringWithFormat:@"%.2f<span class='size'>%@</span>",fvalue,types[3]];
	}
	return str;
}*/

- (NSString *)formattedSize:(NSNumber *)input {
    OSErr err;
    SInt32 systemVersion;
    Gestalt(gestaltSystemVersion, &systemVersion);
    if (systemVersion >= 0x1060)
		return [self base10Size:[input doubleValue]];
	return [self base2Size:[input doubleValue]];
}

- (NSString *)base2Size:(double)input {
	unsigned long long value = (unsigned long long)input;
	NSString *str = nil;
	
	NSString *types[4]= {@"KB", @"MB", @"GB", @"TB"};
	
	if(value == LONG_LONG_MAX)
		return @"0KB";
	
	if(value < 1000){ // MB
		str = [NSString stringWithFormat:@"%.0f<span class='size'>%@</span>", input, types[1]];
	} else if(value < 1048576){ // GB
		float fvalue = (float)value / 1024; // get leftover percentage
		if(fvalue > 99)
			str = [NSString stringWithFormat:@"%.1f<span class='size'>%@</span>",fvalue,types[2]];
		else
			str = [NSString stringWithFormat:@"%.2f<span class='size'>%@</span>",fvalue,types[2]];
	} else { // TB
		unsigned long long wp = value / 1048576; // get whole gigabytes
		value %= 1048576; // remove whole 
		float fvalue = (float)value / 1048576; // get leftover percentage
		fvalue += wp; // combine whole and percentage
		if(fvalue > 99)
			str = [NSString stringWithFormat:@"%.1f<span class='size'>%@</span>",fvalue,types[3]];
		else
			str = [NSString stringWithFormat:@"%.2f<span class='size'>%@</span>",fvalue,types[3]];
	} 
	return str;
}

- (NSString *)base10Size:(double)input {
	unsigned long long value = ((unsigned long long)input * 1.024) * 1.024;
	NSString *str = nil;
	
	NSString *types[4]= {@"KB", @"MB", @"GB", @"TB"};
	
	if(value == LONG_LONG_MAX)
		return @"0KB";
	
	if(value < 1000){ // MB
		str = [NSString stringWithFormat:@"%.0f<span class='size'>%@</span>", input, types[1]];
	} else if(value < 1000000){ // GB
		float fvalue = (float)value / 1000; // get leftover percentage
		if(fvalue > 99)
			str = [NSString stringWithFormat:@"%.1f<span class='size'>%@</span>",fvalue,types[2]];
		else
			str = [NSString stringWithFormat:@"%.2f<span class='size'>%@</span>",fvalue,types[2]];
	} else { // TB
		unsigned long long wp = value / 1000000; // get whole gigabytes
		value %= 1000000; // remove whole 
		float fvalue = (float)value / 1000000; // get leftover percentage
		fvalue += wp; // combine whole and percentage
		if(fvalue > 99)
			str = [NSString stringWithFormat:@"%.1f<span class='size'>%@</span>",fvalue,types[3]];
		else
			str = [NSString stringWithFormat:@"%.2f<span class='size'>%@</span>",fvalue,types[3]];
	} 
	return str;
}


@end
