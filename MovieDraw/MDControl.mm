//
//  MDControl.m
//  MovieDraw
//
//  Created by MILAP on 7/9/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MDControl.h"

@implementation MDControl

+ (instancetype) mdControl
{
	MDControl* view = [ [ MDControl alloc ] init ];
	return view;
}

+ (instancetype) mdControlWithFrame: (MDRect)rect background: (NSColor*)bkg;
{
	MDControl* view = [ [ MDControl alloc ] initWithFrame:rect background:bkg ];
	return view;
}

- (instancetype) init
{
	if ((self = [ super init ]))
	{
		text = [ [ NSMutableString alloc ] init ];
		textColor = [ NSColor colorWithDeviceRed:0 green:0 blue:0 alpha:1 ];
		textFont =[ NSFont systemFontOfSize:[ NSFont systemFontSize ] ];
		up = TRUE;
		glStr = nil;
		continuous = NO;
		ccount = 1;
		return self;
	}
	return nil;
}

- (instancetype) initWithFrame: (MDRect)rect background: (NSColor*)bkg;
{
	if ((self = [ super initWithFrame:rect background:bkg ]))
	{
		text = [ [ NSMutableString alloc ] init ];
		textColor = [ NSColor colorWithDeviceRed:0 green:0 blue:0 alpha:1 ];
		textFont =[ NSFont systemFontOfSize:[ NSFont systemFontSize ] ];
		up = TRUE;
		glStr = nil;
		continuous = NO;
		ccount = 1;
		return self;
	}
	return nil;
}

- (void) setText: (NSString*)str
{
	text = [ NSMutableString stringWithString:str ];
	glStr = LoadString(text, textColor, textFont);
}

- (NSString*) text
{
	return text;
}

- (void) setTextColor: (NSColor*)color
{
	textColor = color;
	if (glStr)
		glStr = LoadString(text, textColor, textFont);
}

- (NSColor*) textColor
{
	return textColor;
}

- (void) setTarget: (id) tar
{
	target = tar;
}

- (id) target
{
	return target;
}

- (void) setAction: (SEL) sel
{
	action = sel;
}

- (void) setDoubleAction:(SEL)sel
{
	doubleAction = sel;
}

- (SEL) doubleAction
{
	return doubleAction;
}

- (SEL) action
{
	return action;
}

- (BOOL) scrolled
{
	BOOL s = scrolled;
	scrolled = NO;
	return s;
}

- (void) setRed: (float) red
{
	[ super setRed:red ];
	glStr = nil;
}

- (void) setGreen: (float)green
{
	[ super setGreen:green ];
	glStr = nil;
}

- (void) setBlue: (float)blue
{
	[ super setBlue:blue ];
	glStr = nil;
}

- (void) setAlpha: (float)alpha
{
	[ super setAlpha:alpha ];
	glStr = nil;
}

- (void) mouseDown: (NSEvent*)event
{
	if (!visible || !enabled || (parentView && ![ parentView visible ]))
		return;
	down = FALSE;
	up = TRUE;
	NSPoint point = [ event locationInWindow ];
	point.x -= origin.x;
	point.y -= origin.y;
	point.x *= resolution.width / windowSize.width;
	point.y *= resolution.height / windowSize.height;
	if (point.x >= frame.x && point.x <= frame.x + frame.width &&
		point.y >= frame.y && point.y <= frame.y + frame.height)
	{
		down = TRUE;
		up = FALSE;
		realDown = TRUE;
		if (continuous && target != nil)
			((void (*)(id, SEL, id))[ target methodForSelector:action ])(target, action, self);
	}
}

- (void) mouseDragged: (NSEvent*)event
{
	if (!visible || !enabled || (parentView && ![ parentView visible ]))
		return;
	if (up)
		return;
	NSPoint point = [ event locationInWindow ];
	point.x -= origin.x;
	point.y -= origin.y;
	point.x *= resolution.width / windowSize.width;
	point.y *= resolution.height / windowSize.height;
	if (!(point.x >= frame.x && point.x <= frame.x + frame.width &&
		point.y >= frame.y && point.y <= frame.y + frame.height))
		down = up;
	else
	{
		down = !up;
		if (continuous && target != nil)
			((void (*)(id, SEL, id))[ target methodForSelector:action ])(target, action, self);
	}
}

- (BOOL) keyDown
{
	return keyDown;
}

- (BOOL) realDown
{
	return down;
}

- (void) mouseUp: (NSEvent*)event
{
	if (!visible || !enabled || (parentView && ![ parentView visible ]))
		return;
	NSPoint point = [ event locationInWindow ];
	point.x -= origin.x;
	point.y -= origin.y;
	point.x *= resolution.width / windowSize.width;
	point.y *= resolution.height / windowSize.height;
	if (point.x >= frame.x && point.x <= frame.x + frame.width &&
		point.y >= frame.y && point.y <= frame.y + frame.height)
	{
		if ([ event clickCount ] != 2 || ![ target respondsToSelector:doubleAction ])
		{
			if (down && target != nil && !continuous && [ target respondsToSelector:action ])
				((void (*)(id, SEL, id))[ target methodForSelector:action ])(target, action, self);
		}
		else
		{
			if (down && target != nil && !continuous && [ target respondsToSelector:doubleAction ])
				((void (*)(id, SEL, id))[ target methodForSelector:doubleAction ])(target, doubleAction, self);
		}
	}
	down = FALSE;
	up = TRUE;
	realDown = FALSE;
}

- (int) state
{
	return state;
}

- (void) setState: (int)nstate
{
	state = nstate;
}

- (void) setEnabled:(BOOL)en
{
	[ super setEnabled:en ];
	glStr = LoadString(text, textColor, textFont);
}

- (void) setContinuous:(BOOL) cont
{
	continuous = cont;
}

- (BOOL) continuous
{
	return continuous;
}

- (void) setContinuousCount:(unsigned int)count
{
	ccount = count;
}

- (unsigned int) continuousCount
{
	return ccount;
}

- (void) setTextFont: (NSFont*) font
{
	textFont = font;
	glStr = LoadString(text, textColor, textFont);
}

- (NSFont*) textFont
{
	return textFont;
}

/*- (void) setRed: (float)red
{
	[ super setRed:red ];
	NSColor* backup = [ textColor retain ];
	if (textColor)
		[ textColor release ];
	textColor = [ [ NSColor colorWithDeviceRed:red green:[ backup greenComponent ]
				blue:[ backup blueComponent ] alpha:[ backup alphaComponent ] ] retain ];
	[ backup release ];
}

- (void) setGreen: (float)green
{
	[ super setGreen:green ];
	NSColor* backup = [ textColor retain ];
	if (textColor)
		[ textColor release ];
	textColor = [ [ NSColor colorWithDeviceRed:[ backup redComponent ] green:green
				blue:[ backup blueComponent ] alpha:[ backup alphaComponent ] ] retain ];
	[ backup release ];
}

- (void) setBlue: (float)blue
{
	[ super setBlue:blue ];
	NSColor* backup = [ textColor retain ];
	if (textColor)
		[ textColor release ];
	textColor = [ [ NSColor colorWithDeviceRed:[ backup redComponent ] green:
			[ backup greenComponent ] blue:blue alpha:[ backup alphaComponent ] ] retain ];
	[ backup release ];
}

- (void) setAlpha: (float)alpha
{
	[ super setAlpha:alpha ];
	NSColor* backup = [ textColor retain ];
	if (textColor)
		[ textColor release ];
	textColor = [ [ NSColor colorWithDeviceRed:[ backup redComponent ] green:
			[ backup greenComponent ] blue:[ backup blueComponent ] alpha:alpha ] retain ];
	[ backup release ];
}*/

- (GLString*) glStr
{
	return glStr;
}

@end
