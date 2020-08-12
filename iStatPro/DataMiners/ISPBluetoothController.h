//
//  ISPBluetoothController.h
//  iStatPro
//
//  Created by iSlayer on 17/04/07.
//  Copyright 2007 iSlayer & Distorted Vista. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ISPBluetoothController : NSObject {
	BOOL mouse_exists;
	BOOL kb_exists;
}

- (BOOL)kb;
- (BOOL)mouse;
- (NSString *)getMouseLevel;
- (NSString *)getKbLevel;

@end
