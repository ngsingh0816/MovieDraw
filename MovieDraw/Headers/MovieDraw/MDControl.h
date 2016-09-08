/*
	MDControl.h
	MovieDraw
 
	Copyright (c) 2013. All rights reserved.
*/

#import "MDControlView.h"
#import "GLString.h"

@interface MDControl : MDControlView {
	NSMutableString* text;
	NSColor* textColor;
	id target;
	SEL action;
	SEL doubleAction;
	int state;
	NSFont* textFont;
	BOOL down;
	BOOL keyDown;
	BOOL up;
	GLString* glStr;
	BOOL continuous;
	BOOL scrolled;
	unsigned int ccount;
	unsigned int fpsCounter;
}

// Creation
+ (instancetype) mdControl;
+ (instancetype) mdControlWithFrame: (MDRect)rect background: (NSColor*)bkg;
- (instancetype) init;
- (instancetype) initWithFrame: (MDRect)rect background: (NSColor*)bkg;

// Text
@property (copy) NSString *text;
@property (copy) NSColor *textColor;
@property (copy) NSFont *textFont;
@property (readonly, strong) GLString *glStr;

// Action
@property (assign) id target;
@property  SEL action;
@property  SEL doubleAction;
@property  BOOL continuous;
@property  unsigned int continuousCount;

// State
@property  int state;


@end
