/*
	MDTextView.h
	MovieDraw
 
	Copyright (c) 2013. All rights reserved.
*/

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

+ (instancetype) mdTextView;
+ (instancetype) mdTextViewWithFrame: (MDRect)rect background:(NSColor*)bkg;
- (instancetype) init;
- (instancetype) initWithFrame:(MDRect)rect background:(NSColor*)bkg;
@property  BOOL editable;
@property  unsigned long cursorPosition;
@property (readonly) std::vector<NSRange> & highlights;

@end
