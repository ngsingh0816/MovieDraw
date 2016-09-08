//
//  MDScrollView.h
//  MovieDraw
//
//  Created by MILAP on 9/25/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

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

+ (id) mdScrollView;
+ (id) mdScrollViewWithFrame: (MDRect)rect background:(NSColor*)bkg;
- (void) setScroll: (NSPoint)scr;
- (NSPoint) scroll;
- (void) setScrollIncrement: (NSSize) inc;
- (NSSize) scrollIncrement;
- (void) setMaxScroll: (NSSize) max;
- (NSSize) maxScroll;
- (void) setAlwaysShowVertical: (BOOL)set;
- (BOOL) alwaysShowVertical;
- (void) setAlwaysShowHorizontal: (BOOL)set;
- (BOOL) alwaysShowHorizontal;
- (void) updateScroll: (double)x vertical: (double)y;
- (void) setScrollOffset: (double)offset;
- (double) scrollOffset;
- (void) startFade;
- (void) scrollToPoint:(NSPoint)point;

@end
