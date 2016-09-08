//
//  MDControl.h
//  MovieDraw
//
//  Created by MILAP on 7/9/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MDControlView.h"
#import "GLString.h"

@interface MDControl : MDControlView {
	NSMutableString* text;
	NSColor* textColor;
	id target;
	SEL action;
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

+ (id) mdControl;
+ (id) mdControlWithFrame: (MDRect)rect background: (NSColor*)bkg;
- (id) init;
- (id) initWithFrame: (MDRect)rect background: (NSColor*)bkg;
- (void) setText: (NSString*)str;
- (NSString*) text;
- (void) setTextColor: (NSColor*)color;
- (NSColor*) textColor;
- (void) setTarget: (id) tar;
- (id) target;
- (void) setAction: (SEL) sel;
- (SEL) action;
- (int) state;
- (void) setState: (int)nstate;
- (void) setTextFont: (NSFont*) font;
- (NSFont*) textFont;
- (void) setContinuous:(BOOL) cont;
- (BOOL) continuous;
- (void) setContinuousCount:(unsigned int)count;
- (unsigned int) continuousCount;
- (GLString*) glStr;

@end
