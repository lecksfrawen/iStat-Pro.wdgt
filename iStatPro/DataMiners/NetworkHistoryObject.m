//
//  NetworkHistoryObject.m
//  iStatPro
//
//  Created by Buffy Summers on 21/06/09Sunday.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "NetworkHistoryObject.h"


@implementation NetworkHistoryObject

- (id)initWithRx:(unsigned long long)r tx:(unsigned long long)t {
	self = [super init];
	int x;
	double time = [[NSDate date] timeIntervalSince1970];
	for(x=0;x<200;x++){
		history[x].rx = r;
		history[x].tx = t;
		history[x].rxConverted = 0;
		history[x].txConverted = 0;
		history[x].time = time;
	}
	return self;
}	

- (struct networkactivity *)history {
	return history;
}

- (void)setKey:(NSString *)k {
	key = [k copy];
}

- (void)addRx:(unsigned long long)r tx:(unsigned long long)t {
	int x;
	for(x=199;x>0;x--){
		history[x].rx = history[x-1].rx;
		history[x].tx = history[x-1].tx;
		history[x].rxConverted = history[x-1].rxConverted;
		history[x].txConverted = history[x-1].txConverted;
		history[x].time = history[x-1].time;
	}
	history[0].rx = r;
	history[0].tx = t;
	history[0].time = [[NSDate date] timeIntervalSince1970];
	
	double timeDifference = history[0].time - history[1].time;
	if(timeDifference < 0.1)
		timeDifference = 0.1;
	
	unsigned long long rxDifference = history[0].rx - history[1].rx;
	unsigned long long txDifference = history[0].tx - history[1].tx;
	history[0].rxConverted = rxDifference / timeDifference;
	history[0].txConverted = txDifference / timeDifference;
}

- (NSString *)key {
	return key;
}


@end
