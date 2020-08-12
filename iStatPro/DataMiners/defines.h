//
//  defines.h
//  iStatPro
//
//  Created by Buffy Summers on 21/07/08Monday.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

static inline int convertTemperature(int format, int value) {
	if(format == 0)
		return value;
	
	if(format == 1){
		return (value * 2) - ((value * 2) * 1 / 10) + 32;
	}
	
	if(format == 2){
		return value + 273.15;
	}
	
	return value;
}

