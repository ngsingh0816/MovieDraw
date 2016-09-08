/*
	MDCheckBox.h
	MovieDraw
 
	Copyright (c) 2013. All rights reserved.
*/

#import "MDControl.h"
#import "MDButton.h"

#define MD_CHECKBOX_DEFAULT_SIZE	NSMakeSize(14, 14)
#define MD_CHECKBOX_DEFAULT_COLOR	[ NSColor colorWithCalibratedRed:0.9 green:0.9 blue:0.9 alpha:1 ]
#define MD_CHECKBOX_DEFAULT_SELECTION_COLOR	[ NSColor colorWithCalibratedRed:0.537255 green:0.776471 blue:0.972549 alpha:1 ]
#define MD_CHECKBOX_DEFAULT_CHECK_COLOR		[ NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:1 ]

@interface MDCheckBox : MDControl {
	NSColor* selectionColor;
	NSColor* checkColor;
	
	unsigned int checkVao[2];
}

// Creation
+ (instancetype) mdCheckBox;
+ (instancetype) mdCheckBoxWithFrame: (MDRect)rect background: (NSColor*)bkg;

// Colors
@property (copy) NSColor *selectionColor;
@property (copy) NSColor *checkColor;

@end
