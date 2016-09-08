/*
	MDTextField.h
	MovieDraw
 
	Copyright (c) 2013. All rights reserved.
*/

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
@property (strong) id keyTarget;
@property  SEL keyAction;
@property  BOOL numbersOnly;
@property  BOOL editable;
@property  BOOL canHighlight;
@property  BOOL safeText;
- (void) addCharacter: (short)data toIndex:(unsigned long) index;
- (void) deleteCharacterAtIndex:(unsigned long) index;
@property  unsigned long cursorPosition;
@property (readonly) std::vector<NSRange> *highlights;
@property  float pixelOffset;
@property  BOOL usesThreads;

@end
