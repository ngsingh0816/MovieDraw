//
//  MDRadioButton.h
//  MovieDraw
//
//  Created by MILAP on 7/10/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MDControl.h"

#define MD_RADIO_DEFAULT_SIZE	NSMakeSize(16, 16)
#define MD_RADIO_DEFAULT_COLOR	MD_BUTTON_DEFAULT_BUTTON_COLOR
#define MD_RADIO_DEFAULT_CHECK_COLOR		[ NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:1 ]

void CreateRadioGroup(NSArray* members);

@interface MDRadioButton : MDControl {
	NSMutableArray* members;
	NSColor* checkColor;
	BOOL changed;
	float* verticies;
	float* bverticies;
	float* cverticies;
	float* colors;
	float* bcolors;
	float* ccolors;
	int lastState;
}

+ (id) mdRadioButton;
+ (id) mdRadioButtonWithFrame: (MDRect)rect background: (NSColor*)bkg;
- (void) setMembers: (NSArray*)mem;
- (void) addMember:(MDRadioButton*)mem;
- (NSMutableArray*) members;
- (void) setCheckColor:(NSColor*)color;
- (NSColor*) checkColor;

@end
