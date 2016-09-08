/*
	MDScrollView.h
	MovieDraw
 
	Copyright (c) 2013. All rights reserved.
*/

#import "MDControl.h"
#import "MDButton.h"

#define MD_SCROLL_DEFAULT_COLOR	[ NSColor colorWithCalibratedRed:0.450980 green:0.450980 blue:0.450980 alpha:1 ]
#define MD_SCROLL_DEFAULT_COLOR2	[ NSColor colorWithCalibratedRed:0.913726 green:0.913726 blue:0.913726 alpha:1 ]

@interface MDScrollView : MDControl {
	NSPoint scroll;
	NSSize scrollIncrement;
	NSSize maxScroll;
	BOOL alwaysShowVertical;
	BOOL alwaysShowHorizontal;
	double scrollOffset;
	BOOL showOver;
	NSTimer* scrollTimer;
	NSTimer* alphaTimer;
	float fadeAlpha;
	BOOL isFading;
	BOOL thisDown;
}

+ (instancetype) mdScrollView;
+ (instancetype) mdScrollViewWithFrame: (MDRect)rect background:(NSColor*)bkg;
@property  NSPoint scroll;
@property  NSSize scrollIncrement;
@property  NSSize maxScroll;
@property  BOOL alwaysShowVertical;
@property  BOOL alwaysShowHorizontal;
- (void) updateScroll: (double)x vertical: (double)y;
@property  double scrollOffset;
- (void) startFade;
- (void) scrollToPoint:(NSPoint)point;

@end
