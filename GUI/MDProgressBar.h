//
//  MDProgressBar.h
//  MovieDraw
//
//  Created by MILAP on 12/29/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MDControl.h"

#define MD_PROGRESS_DEFAULT_SIZE	NSMakeSize(16, 16)
#define MD_PROGRESS_DEFAULT_COLOR	[ NSColor colorWithCalibratedRed:1 green:1 blue:1 alpha:1 ]
#define MD_PROGRESS_DEFAULT_COLOR2	[ NSColor colorWithCalibratedRed:0.925490 green:0.925490 blue:0.925490 alpha:1 ]
#define MD_PROGRESS_DEFAULT_OTHER	[ NSColor colorWithCalibratedRed:0.360784 green:0.725490 blue:0.952941 alpha:1 ]
#define MD_PROGRESS_DEFAULT_OTHER2	[ NSColor colorWithCalibratedRed:0.341176 green:0.674510 blue:0.937255 alpha:1 ]
#define MD_PROGRESS_DEFAULT_BORDER	[ NSColor colorWithCalibratedRed:0.639216 green:0.639216 blue:0.639216 alpha:1 ]
#define MD_PROGRESS_DEFAULT_BKG		[ NSColor colorWithCalibratedRed:0.866667 green:0.866667 blue:0.866667 alpha:1 ]
#define MD_PROGRESS_DEFAULT_BKG2	[ NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:1 / 12.0 ]

typedef enum
{
	MD_PROGRESSBAR_NORMAL = 0,
	MD_PROGRESSBAR_SPIN,
} MDProgressBarType;

@interface MDProgressBar : MDControl {
	MDProgressBarType type;
	float minValue;
	float maxValue;
	float currentValue;
	NSColor* otherColor;
	float rotation;
	float speed;
	float width1;
	float width2;
	
	BOOL changed;
	float* verticies;
	float* bverticies;
	float* colors;
	float* bcolors;
}

+ (MDProgressBar*) mdProgressBar;
+ (MDProgressBar*) mdProgressBarWithFrame: (MDRect)rect background:(NSColor*)bkg;
- (void) setType: (MDProgressBarType)ty;
- (MDProgressBarType) type;
- (void) setMinValue: (float)min;
- (float) minValue;
- (void) setMaxValue: (float)max;
- (float) maxValue;
- (void) setCurrentValue: (float)value;
- (float) currentValue;
- (void) setOtherColor: (NSColor*)color;
- (NSColor*) otherColor;
- (void) setSpeed: (float)sped;
- (float) speed;
- (void) setWidth1: (float)width;
- (float) width1;
- (void) setWidth2: (float)width;
- (float) width2;

@end
