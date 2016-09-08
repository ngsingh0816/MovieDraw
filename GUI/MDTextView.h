//
//  MDTextView.h
//  MovieDraw
//
//  Created by MILAP on 2/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MDScrollView.h"
#include <vector>

#define MD_TEXTVIEW_DEFAULT_SIZE	NSMakeSize(480, 320)
#define MD_TEXTVIEW_DEFAULT_COLOR	[ NSColor colorWithCalibratedRed:1 green:1 blue:1 alpha:1 ]

@interface MDTextView : MDScrollView {
	NSMutableArray* characters;
	float cursorHeight;
	unsigned long cursorIndex;
	unsigned int cursorTimer;
	BOOL editable;
	unsigned int updateScroll;
	NSPoint mouseClick;
	NSPoint mouseDrag;
	std::vector<NSRange> highlights;
	unsigned char commands;
	unsigned int clickCount;
}

+ (id) mdTextView;
+ (id) mdTextViewWithFrame: (MDRect)rect background:(NSColor*)bkg;
- (id) init;
- (id) initWithFrame:(MDRect)rect background:(NSColor*)bkg;
- (void) setEditable: (BOOL)edit;
- (BOOL) editable;
- (void) setCursorPosition:(unsigned long)pos;
- (unsigned long) cursorPosition;
- (std::vector<NSRange>&) highlights;

@end
