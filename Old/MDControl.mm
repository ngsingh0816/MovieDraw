//
//  MDControl.m
//  MovieDraw
//
//  Created by MILAP on 7/9/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MDControl.h"

@implementation MDControl

+ (id) mdControl
{
	MDControl* view = [ [ [ MDControl alloc ] init ] autorelease ];
	return view;
}

+ (id) mdControlWithFrame: (MDRect)rect background: (NSColor*)bkg;
{
	MDControl* view = [ [ [ MDControl alloc ] initWithFrame:rect
											 background:bkg ] autorelease ];
	return view;
}

- (id) init
{
	if ((self = [ super init ]))
	{
		text = [ [ NSMutableString alloc ] init ];
		textColor = [ [ NSColor colorWithDeviceRed:0 green:0 blue:0 alpha:1 ] retain ];
		textFont = [ [ NSFont systemFontOfSize:[ NSFont systemFontSize ] ] retain ];
		up = TRUE;
		glStr = nil;
		continuous = NO;
		ccount = 1;
		return self;
	}
	return nil;
}

- (id) initWithFrame: (MDRect)rect background: (NSColor*)bkg;
{
	if ((self = [ super initWithFrame:rect background:bkg ]))
	{
		text = [ [ NSMutableString alloc ] init ];
		textColor = [ [ NSColor colorWithDeviceRed:0 green:0 blue:0 alpha:1 ] retain ];
		textFont = [ [ NSFont systemFontOfSize:[ NSFont systemFontSize ] ] retain ];
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
	if (text)
		[ text release ];
	text = [ [ NSMutableString stringWithString:str ] retain ];
	if (glStr)
		[ glStr release ];
	glStr = LoadString(text, textColor, textFont);
}

- (NSString*) text
{
	return text;
}

- (void) setTextColor: (NSColor*)color
{
	if (textColor)
		[ textColor release ];
	textColor = [ color retain ];
	if (glStr)
	{
		[ glStr release ];
		glStr = LoadString(text, textColor, textFont);
	}
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

- (void) mouseDown: (NSEvent*)event
{
	if (!visible || !enabled)
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
			[ target performSelector:action withObject:self ];
	}
}

- (void) mouseDragged: (NSEvent*)event
{
	if (!visible || !enabled)
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
			[ target performSelector:action withObject:self ];
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
	if (!visible || !enabled)
		return;
	NSPoint point = [ event locationInWindow ];
	point.x -= origin.x;
	point.y -= origin.y;
	point.x *= resolution.width / windowSize.width;
	point.y *= resolution.height / windowSize.height;
	if (point.x >= frame.x && point.x <= frame.x + frame.width &&
		point.y >= frame.y && point.y <= frame.y + frame.height)
	{
		if (down && target != nil && !continuous)
			[ target performSelector:action withObject:self ];
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
	if (glStr)
	{
		[ glStr release ];
		glStr = LoadString(text, textColor, textFont);
	}
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
	if (textFont)
		[ textFont release ];
	textFont = [ font retain ];
	if (glStr)
	{
		[ glStr release ];
		glStr = LoadString(text, textColor, textFont);
	}
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

- (void) dealloc
{
	if (text)
	{
		[ text release ];
		text = nil;
	}
	if (textFont)
	{
		[ textFont release ];
		textFont = nil;
	}
	if (textColor)
	{
		[ textColor release ];
		textColor = nil;
	}
	if (glStr)
	{
		[ glStr release ];
		glStr = nil;
	}
	[ super dealloc ];
}

@end
