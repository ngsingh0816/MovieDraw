/*
	MDSlider.h
	MovieDraw
 
	Copyright (c) 2013. All rights reserved.
*/

#import "MDControl.h"

#define MD_SLIDER_DEFAULT_SIZE	NSMakeSize(96, 15)
#define MD_SLIDER_DEFAULT_SIZE_WITH_TICKS	NSMakeSize(96, 24)

#define MD_SLIDER_DEFAULT_COLOR [ NSColor colorWithCalibratedRed:0.803922 green:0.803922 blue:0.803922 alpha:1 ]
#define MD_SLIDER_DEFAULT_BORDER_COLOR	[ NSColor colorWithCalibratedRed:0.454902 green:0.454902 blue:0.454902 alpha:1 ]
#define MD_SLIDER_DEFAULT_BUTTON_COLOR	[ NSColor colorWithCalibratedRed:1 green:1 blue:1 alpha:1 ]
#define MD_SLIDER_DEFAULT_BUTTON_COLOR2 [ NSColor colorWithCalibratedRed:0.937255 green:0.937255 blue:0.937255 alpha:1 ]
#define MD_SLIDER_DEFAULT_BUTTON_BORDER_COLOR	[ NSColor colorWithCalibratedRed:0.509804 green:0.509804 blue:0.509804 alpha:1 ]
#define MD_SLIDER_DEFAULT_MOUSE_COLOR	[ NSColor colorWithCalibratedRed:0.878431 green:0.878431 blue:0.878431 alpha: 1 ]


@interface MDSlider : MDControl {
	float selValue;
	float maxValue;
	unsigned long tickMarks;
	BOOL stopOnTicks;
	
	BOOL changed;
	float* verticies;
	float* bverticies;
	float* cverticies;
	float* bverticies2;
	float* colors;
	float* bcolors;
	float* ccolors;
	float* bcolors2;
}

+ (instancetype) mdSlider;
+ (instancetype) mdSliderWithFrame: (MDRect)rect background: (NSColor*)bkg;
@property  float value;
@property  float maxValue;
@property  unsigned long numberOfTickMarks;
@property  BOOL onlyStopsOnTickMarks;

@end
