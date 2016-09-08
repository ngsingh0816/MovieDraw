//
//  MDWindow.h
//  MovieDraw
//
//  Created by MILAP on 9/18/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MDControl.h"

@class MDButton, MDWindow;

#define MD_WINDOW_DEFAULT_COLOR	[ NSColor colorWithCalibratedRed:0.929412 green:0.929412 blue:0.929412 alpha:1 ]
#define MD_WINDOW_DEFAULT_TITLE_COLOR1	[ NSColor colorWithCalibratedRed:0.909804 green:0.909804 blue:0.909804 alpha:1 ]
#define MD_WINDOW_DEFAULT_TITLE_COLOR2	[ NSColor colorWithCalibratedRed:0.729412 green:0.729412 blue:0.729412 alpha:1 ]
#define MD_WINDOW_DEFAULT_TITLE_COLOR3	[ NSColor colorWithCalibratedRed:0.749020 green:0.749020 blue:0.749020 alpha:1 ]
#define MD_WINDOW_DEFAULT_TITLE_COLOR4	[ NSColor colorWithCalibratedRed:0.407843 green:0.407843 blue:0.407843 alpha:1 ]

MDWindow* MDRunAlertPanel(NSString* title, NSString* message, NSString* defaultButton, NSString* alternateButton, NSString* otherButton, id target, SEL action);

@interface MDWindow : MDControl {
	MDButton* closeButton;
	MDRect originalRect;
	NSPoint mouse;
	BOOL update;
	BOOL resizeViews;
	BOOL canResize;
	NSSize minFrame;
	NSSize maxFrame;
	BOOL resizing;
	BOOL titleDown;
	NSPoint downPoint;
	GLString* titleDot;
	id resizeTar;
	SEL resizeAct;
	MDRect bounds;
	BOOL boundedPoint[4];
	
	float* titleVert;
	float* titleColors;
	BOOL titleChanged;
	float* frameVert;
	float* frameColors;
	BOOL frameChanged;
}

+ (id) mdWindow;
+ (id) mdWindowWithFrame: (MDRect)rect background: (NSColor*)bkg;
- (void) setHasCloseButton:(BOOL)canClose;
- (BOOL) hasCloseButton;
- (void) close: (id) sender;
- (void) addSubView: (id) subview;
- (void) removeSubViewAtIndex: (unsigned int) index;
- (void) removeSubView: (id) subview;
- (void) setResizeSubviews: (BOOL) set;
- (BOOL) resizeSubviews;
- (void) setCanResize: (BOOL) set;
- (BOOL) canResize;
- (void) setMinSize: (NSSize)rect;
- (NSSize) minSize;
- (void) setMaxSize: (NSSize)rect;
- (NSSize) maxSize;
- (void) setFrame:(MDRect) rect withSizes:(BOOL)use;
- (void) setResizeTarget: (id) tar;
- (id) resizeTarget;
- (void) setResizeAction: (SEL) act;
- (SEL) resizeAction;
- (void) setBounds:(MDRect)bd;
- (MDRect) bounds;
- (void) setBoundedByPoint: (BOOL)bo atIndex:(unsigned int)index;
- (BOOL) boundedByPointAtIndex:(unsigned int)index;

@end
