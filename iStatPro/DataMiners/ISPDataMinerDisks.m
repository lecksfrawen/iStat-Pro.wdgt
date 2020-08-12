//
//  ISPDataMinerDisks.m
//  iStatMenusDisks
//
//  Created by iSlayer on 17/04/07.
//  Copyright 2007 iSlayer & Distorted Vista. All rights reserved.
//

#import "ISPDataMinerDisks.h"
#import "ISMDiskObject.h"

@implementation ISPDataMinerDisks

static ISPDataMinerDisks *dataMinerCore = nil;

+ (id)dataMinerCore {
	if(dataMinerCore)
		return dataMinerCore;
	
	dataMinerCore = [[ISPDataMinerDisks alloc] init];
	[dataMinerCore setup];
	[dataMinerCore findDrives];
	return dataMinerCore;
}

- (void)setup {
	_disks = [[NSMutableArray alloc] init];
}

- (id)init {
	self = [super init];

	BOOL isDir;
	
	BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:[@"~/Library/Caches/iStatPro/" stringByExpandingTildeInPath] isDirectory:&isDir];
    if(!exists)
		[[NSFileManager defaultManager] createDirectoryAtPath:[@"~/Library/Caches/iStatPro/" stringByExpandingTildeInPath] attributes:nil];

	[self findDrives];
	[self getDataSet];
	
	return self;
}

- (void) dealloc {
	[super dealloc];
}

- (NSString *)formattedSize:(NSNumber *)input {
	unsigned long long value = [input unsignedLongLongValue];
	NSString *str = nil;
	
	NSString *types[4]= {@"KB", @"MB", @"GB", @"TB"};
	
	if(value == LONG_LONG_MAX)
		return @"0KB";
	
	if(value < 1000){ // KB
		str = [NSString stringWithFormat:@"%llu%@", value, types[0]];
	} else if(value < 1048576){ // MB
		str = [NSString stringWithFormat:@"%.0f%@", (float)value / 1024, types[1]];		
	} else if(value < 1073741824){ // GB
		unsigned long long wp = value / 1048576;
		value %= 1048576;
		float fvalue = (float)value / 1048576;
		fvalue += wp;
		if(fvalue > 99)
			str = [NSString stringWithFormat:@"%.1f%@",fvalue,types[2]];
		else
			str = [NSString stringWithFormat:@"%.2f%@",fvalue,types[2]];
	} else { // TB
		unsigned long long wp = value / 1073741824;
		value %= 1073741824;
		float fvalue = (float)value / 1073741824;
		fvalue += wp;
		if(fvalue > 99)
			str = [NSString stringWithFormat:@"%.1f%@",fvalue,types[3]];
		else
			str = [NSString stringWithFormat:@"%.2f%@",fvalue,types[3]];
	}
	return str;
}

- (NSData *)iconForDisk:(NSString *)uuid {
	if([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/Library/Application Support/iStat Server/Cache/disk_%@.tiff", uuid]])
		return [NSData dataWithContentsOfFile:[NSString stringWithFormat:@"/Library/Application Support/iStat Server/Cache/disk_%@.tiff", uuid]];
	return nil;
}

- (NSArray *)disks {
	return _disks;
}

- (ISMDiskObject *)diskForPath:(NSString *)path {
	int y;
	for(y=0;y<[_disks count];y++){
		ISMDiskObject *disk = [_disks objectAtIndex:y];
		if([[disk bsdName] isEqualToString:path]){
			return disk;
		}
	}
	return nil;
}

- (void)removeDisk:(DADiskRef)diskRef {
	const char *p = DADiskGetBSDName(diskRef);
	if(p == NULL)
		return;
	NSString *path = [NSString stringWithCString:p];
	int y;
	for(y=0;y<[_disks count];y++){
		ISMDiskObject *disk = [_disks objectAtIndex:y];
		if([[disk bsdName] isEqualToString:path]){
			[_disks removeObjectAtIndex:y];
			y--;
		}
	}
}

- (void)addDisk:(DADiskRef)diskRef {
	NSDictionary *info = (NSDictionary *)DADiskCopyDescription(diskRef);
	if(!info)
		return;
	
	if(![info valueForKey:(NSString *)kDADiskDescriptionVolumeUUIDKey]){
		if(![info valueForKey:(NSString *)kDADiskDescriptionMediaKindKey]){
			[info release];
			return;
		}
	}
	
	
	if(![info valueForKey:(NSString *)kDADiskDescriptionMediaBSDNameKey] || [[info valueForKey:(NSString *)kDADiskDescriptionDeviceProtocolKey] isEqualToString:@"Virtual Interface"] || [[info valueForKey:(NSString *)kDADiskDescriptionMediaKindKey] isEqualToString:@"IODVDMedia"] || [[info valueForKey:(NSString *)kDADiskDescriptionMediaKindKey] isEqualToString:@"IOCDMedia"]){
		[info release];
		return;
	}
	
	const char *p = DADiskGetBSDName(diskRef);
	if(p == NULL){
		[info release];
		return;
	}
	
	NSString *path = [NSString stringWithCString:p];
	
	CFURLRef pathURL = CFDictionaryGetValue(info, kDADiskDescriptionVolumePathKey);
	
	ISMDiskObject *disk = [self diskForPath:path];
	if(!disk){
		disk = [[ISMDiskObject alloc] initWithDictionary:info index:_disks.count];
		if(pathURL){
			CFStringRef tempPath = CFURLCopyFileSystemPath(pathURL,kCFURLPOSIXPathStyle);
			NSString *bsdPath = [(NSString*)tempPath stringByStandardizingPath];
			
			[disk setMountPath:bsdPath];
			[disk setMounted:YES];
			[disk setVisibleName:[[NSFileManager defaultManager] displayNameAtPath:[disk mountPath]]];
			[disk update];
			[tempPath release];
		} else {
			[disk setVisibleName:CFDictionaryGetValue(info, kDADiskDescriptionVolumeNameKey)];
			[disk setMounted:NO];
		}
		[_disks addObject:disk];
		[disk release];
	}
	[_disks sortUsingSelector:@selector(sortDisks:)];
	[info release];
}

- (void)sort {
	[_disks sortUsingSelector:@selector(sortDisks:)];
}

- (BOOL)diskExists:(NSString *)disk {
	int x;
	for(x=0;x<[_disks count];x++){
		ISMDiskObject *d = [_disks objectAtIndex:x];
		if([[d bsdName] isEqualToString:disk])
			return YES;
	}	
	return NO;
}

- (NSString *)uuidForDiskWithBSDName:(NSString *)bsd volumeName:(NSString *)volume buffer:(struct statfs)buffer disk:(DADiskRef)diskRef {
	NSString *uuid = nil;
	if(diskRef){
		NSDictionary *info = (NSDictionary *)DADiskCopyDescription(diskRef);
		if(info){
			if([info valueForKey:(NSString *)kDADiskDescriptionVolumeUUIDKey])
				uuid = (NSString *)CFUUIDCreateString(NULL, (CFUUIDRef)[info valueForKey:(NSString *)kDADiskDescriptionVolumeUUIDKey]);
			else {
				NSString *uuidKey = [NSString stringWithFormat:@"%@", [info objectForKey:(NSString *)kDADiskDescriptionVolumeNameKey]];
				if([info objectForKey:(NSString *)kDADiskDescriptionMediaSizeKey])
					uuidKey = [NSString stringWithFormat:@"%@-%@", uuidKey, [info objectForKey:(NSString *)kDADiskDescriptionMediaSizeKey]];
				if([info objectForKey:(NSString *)kDADiskDescriptionDevicePathKey])
					uuidKey = [NSString stringWithFormat:@"%@-%@", uuidKey, [info objectForKey:(NSString *)kDADiskDescriptionDevicePathKey]];
				
				CFUUIDRef uuidRef = CFUUIDCreateFromString(NULL, (CFStringRef)uuidKey);
				uuid = (NSString *)CFUUIDCreateString(NULL, uuidRef);
				CFRelease(uuidRef);
			}
		}
	}
	if(!uuid){
		NSString *uuidKey = volume;
		uuidKey = [NSString stringWithFormat:@"%@-%@", uuidKey, [[NSNumber numberWithLong:buffer.f_blocks] stringValue]];
		CFUUIDRef uuidRef = CFUUIDCreateFromString(NULL, (CFStringRef)uuidKey);
		uuid = (NSString *)CFUUIDCreateString(NULL, uuidRef);
		CFRelease(uuidRef);
	}
	return uuid;
}

- (void)findDrives {
	DASessionRef diskArbSession = DASessionCreate(kCFAllocatorDefault);
	NSMutableArray *mountedDisks = [[NSMutableArray alloc] init];
	struct statfs *buffer;
	int count = getmntinfo(&buffer,MNT_NOWAIT);
	int x;
	for(x=0;x<count;x++){
		if(![[NSString stringWithFormat:@"%s",buffer[x].f_mntonname] hasPrefix:@"/Volumes"] && !(buffer[x].f_flags & MNT_ROOTFS))
			continue;
		NSString *name = [[NSString stringWithFormat:@"%s",buffer[x].f_mntfromname] lastPathComponent];
		if(!name)
			continue;
		
		DADiskRef diskRef = DADiskCreateFromBSDName(kCFAllocatorDefault, diskArbSession, [name fileSystemRepresentation]);
		if(diskRef){
			NSDictionary *info = (NSDictionary *)DADiskCopyDescription(diskRef);
			if(info){
				if([info objectForKey:(NSString *)kDADiskDescriptionDeviceProtocolKey] && [[info valueForKey:(NSString *)kDADiskDescriptionDeviceProtocolKey] isEqualToString:@"Virtual Interface"]){
					[info release];
					CFRelease(diskRef);
					continue;
				}
				if([info objectForKey:(NSString *)kDADiskDescriptionMediaKindKey] && ([[info valueForKey:(NSString *)kDADiskDescriptionMediaKindKey] isEqualToString:@"IODVDMedia"] || [[info valueForKey:(NSString *)kDADiskDescriptionMediaKindKey] isEqualToString:@"IOCDMedia"])){
					[info release];
					CFRelease(diskRef);
					continue;
				}
				[info release];
			}
		}
		
		[mountedDisks addObject:name];
		
		if([self diskExists:name]){
			if(diskRef)
				CFRelease(diskRef);
			continue;
		}
		
		ISMDiskObject *disk = [[ISMDiskObject alloc] init];
		[disk setMountPath:[NSString stringWithFormat:@"%s",buffer[x].f_mntonname]];
		[disk setVisibleName:[[NSFileManager defaultManager] displayNameAtPath:[disk mountPath]]];
		[disk setUuid:[self uuidForDiskWithBSDName:name volumeName:[disk visibleName] buffer:buffer[x] disk:diskRef]];
		[disk setBsdName:name];		
		[disk setMounted:YES];
		[disk update];
		
		
		[_disks addObject:disk];
		[disk release];
		if(diskRef)
			CFRelease(diskRef);
	}
	
	for(x=0;x<[_disks count];x++){
		ISMDiskObject *d = [_disks objectAtIndex:x];
		
		if(![mountedDisks containsObject:[d bsdName]]){
			[_disks removeObjectAtIndex:x];
			x--;
		}
	}	
	CFRelease(diskArbSession);
	
	[_disks makeObjectsPerformSelector:@selector(update)];
	[_disks sortUsingSelector:@selector(sortDisks:)];
	
	[self updateIcons];
}

- (void)updateIcons {
	int y;
	for(y=0;y<[_disks count];y++){
		ISMDiskObject *disk = [_disks objectAtIndex:y];
		NSString *iconFilePath = nil;
		if([disk uuid])
			iconFilePath = [NSString stringWithFormat:@"%@/%@.tiff",[@"~/Library/Caches/iStatPro/" stringByExpandingTildeInPath],[[NSFileManager defaultManager] displayNameAtPath:[disk uuid]]];
		else
			iconFilePath = [NSString stringWithFormat:@"%@/%@.tiff",[@"~/Library/Caches/iStatPro/" stringByExpandingTildeInPath],[[NSFileManager defaultManager] displayNameAtPath:[disk path]]];

		if([[NSFileManager defaultManager] fileExistsAtPath:iconFilePath])
			[[NSFileManager defaultManager] removeFileAtPath:iconFilePath handler:NULL];
		
		NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:[disk path]];       
		NSArray *reps = [icon representations];
		if([reps count] > 0){
			int x;
			float smallestSize = FLT_MAX;
			int index = 0;
			
			for(x=0;x<[reps count];x++){
				NSSize size = [[reps objectAtIndex:x] size];
				if(size.width < smallestSize && size.width > 16){
					smallestSize = size.width;
					index = x;
				}
			}
			NSImageRep *rep = [reps objectAtIndex:index];
			NSImage *smallIcon = [[NSImage alloc] initWithSize:[rep size]];
			[smallIcon addRepresentation:rep];
			
			NSData *tiffRep = [smallIcon TIFFRepresentation];
			[tiffRep writeToFile:iconFilePath atomically:YES];
			[smallIcon release];
		}
	}
}

- (void)update {
	[_disks makeObjectsPerformSelector:@selector(update)];
}

- (NSArray *)getDataSet {
	NSMutableArray *theData = [[NSMutableArray alloc] init];
	int y;
	for(y=0;y<[_disks count];y++){
		ISMDiskObject *disk = [_disks objectAtIndex:y];
		NSString *iconFilePath = nil;
		if([disk uuid])
			iconFilePath = [NSString stringWithFormat:@"%@/%@.tiff",[@"~/Library/Caches/iStatPro/" stringByExpandingTildeInPath],[[NSFileManager defaultManager] displayNameAtPath:[disk uuid]]];
		else
			iconFilePath = [NSString stringWithFormat:@"%@/%@.tiff",[@"~/Library/Caches/iStatPro/" stringByExpandingTildeInPath],[[NSFileManager defaultManager] displayNameAtPath:[disk path]]];

		
		NSString *filterKey = nil;
		if([disk uuid])
			filterKey = [disk uuid];
		else
			filterKey = [[NSFileManager defaultManager] displayNameAtPath:[disk path]];
		
		[theData addObject:[NSArray arrayWithObjects:[[NSFileManager defaultManager] displayNameAtPath:[disk path]], [disk percentage],[disk formattedSize:[disk used]],[disk formattedSize:[disk free]], [disk path], iconFilePath, filterKey, nil]];
	}
	return [theData autorelease];
}


@end
