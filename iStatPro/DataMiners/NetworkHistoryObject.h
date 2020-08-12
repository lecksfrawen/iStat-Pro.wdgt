//
//  NetworkHistoryObject.h
//  iStatPro
//
//  Created by Buffy Summers on 21/06/09Sunday.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef struct networkactivity {
	unsigned long long rx;
	unsigned long long tx;
	unsigned long long rxConverted;
	unsigned long long txConverted;
	double time;
} networkactivity_t;

@interface NetworkHistoryObject : NSObject {
	struct networkactivity history[200];
	NSString *key;
}

- (id)initWithRx:(unsigned long long)r tx:(unsigned long long)t;
- (void)addRx:(unsigned long long)r tx:(unsigned long long)t;
- (void)setKey:(NSString *)k;
- (NSString *)key;
- (struct networkactivity *)history;

@end
