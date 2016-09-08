/*
	MDRadioButton.h
	MovieDraw
 
	Copyright (c) 2013. All rights reserved.
*/

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

+ (instancetype) mdRadioButton;
+ (instancetype) mdRadioButtonWithFrame: (MDRect)rect background: (NSColor*)bkg;
- (void) setMembers: (NSArray*)mem;
- (void) addMember:(MDRadioButton*)mem;
- (NSMutableArray*) members;
@property (copy) NSColor *checkColor;

@end
