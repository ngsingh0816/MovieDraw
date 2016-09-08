//
//  MDCheckBox.h
//  MovieDraw
//
//  Created by MILAP on 7/10/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MDControl.h"
#import "MDButton.h"

#define MD_CHECKBOX_DEFAULT_SIZE	NSMakeSize(14, 14)
#define MD_CHECKBOX_DEFAULT_COLOR	MD_BUTTON_DEFAULT_BUTTON_COLOR
#define MD_CHECKBOX_DEFAULT_CHECK_COLOR		[ NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:1 ]

@interface MDCheckBox : MDControl {
	NSColor* checkColor;
	BOOL changed;
	float* verticies;
	float* bverticies;
	float* colors;
	float* bcolors;
}

+ (id) mdCheckBox;
+ (id) mdCheckBoxWithFrame: (MDRect)rect background: (NSColor*)bkg;
- (void) setCheckColor: (NSColor*)color;
- (NSColor*) checkColor;

@end
