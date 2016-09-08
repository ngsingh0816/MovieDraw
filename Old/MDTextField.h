//
//  MDTextField.h
//  MovieDraw
//
//  Created by MILAP on 7/27/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MDControl.h"

#define MD_TEXTFIELD_DEFAULT_SIZE	NSMakeSize(96, 22)
#define MD_TEXTFIELD_DEFAULT_COLOR	[ NSColor colorWithCalibratedRed:1 green:1 blue:1 alpha:1 ]

@interface MDTextField : MDControl {
	NSMutableArray* characters;
	unsigned long cursorIndex;
	float cursorHeight;
	unsigned int cursorTimer;
	NSPoint mouseClick;
	NSPoint mouseDrag;
	std::vector<NSRange> highlights;
	unsigned char commands;
	unsigned int clickCount;
	id keyTar;
	SEL keyAct;
	BOOL numeric;
	BOOL editable;
	BOOL safe;
	BOOL canHighlight;
	float scrollx;
	unsigned long scrollIndex;
	unsigned int updateScroll;
	unsigned int moveWay;
	NSPoint moveAway;
	GLString* safeText;
	float pixelOffset;
	BOOL useThreads;
}

+ (MDTextField*) mdTextField;
+ (MDTextField*) mdTextFieldWithFrame:(MDRect) rect background:(NSColor*)bkg;
- (void) setKeyTarget: (id) tkey;
- (id) keyTarget;
- (void) setKeyAction: (SEL) kact;
- (SEL) keyAction;
- (void) setNumbersOnly:(BOOL) numb;
- (BOOL) numbersOnly;
- (void) setEditable: (BOOL) edit;
- (BOOL) editable;
- (void) setCanHighlight: (BOOL)high;
- (BOOL) canHighlight;
- (void) setSafeText: (BOOL) sf;
- (BOOL) safeText;
- (void) addCharacter: (short)data toIndex:(unsigned long) index;
- (void) deleteCharacterAtIndex:(unsigned long) index;
- (unsigned long) cursorPosition;
- (void) setCursorPosition:(unsigned long)position;
- (std::vector<NSRange>*) highlights;
- (void) setPixelOffset:(float) offset;
- (float) pixelOffset;
- (void) setUsesThreads:(BOOL)set;
- (BOOL) usesThreads;

@end
