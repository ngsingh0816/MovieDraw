//
//  MDColor.m
//  MovieDraw
//
//  Created by MILAP on 12/29/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MDColor.h"


@implementation MDColor

+ (MDColor*) colorWithMDColor: (MDColor*) color
{
	return [ [ [ MDColor alloc ] initWithMDColor:color ] autorelease ];
}

+ (MDColor*) colorWithColor: (NSColor*) color
{
	return [ [ [ MDColor alloc ] initWithColor:color ] autorelease ];
}

+ (MDColor*) colorWithRed: (float) r green: (float) g blue: (float) b alpha: (float) a
{
	return [ [ [ MDColor alloc ] initWithRed:r green:g blue:b alpha:a ] autorelease ];
}

+ (MDColor*) color
{
	return [ [ [ MDColor alloc ] init ] autorelease ];
}

- (MDColor*) initWithMDColor: (MDColor*) color
{
	if (color == nil)
		return nil;
	if ((self = [ super init ]))
	{
		red = [ color redValue ];
		green = [ color greenValue ];
		blue = [ color blueValue ];
		alpha = [ color alphaValue ];
		return self;
	}
	return nil;
}

- (MDColor*) initWithColor: (NSColor*) color
{
	if (color == nil)
		return nil;
	if ((self = [ super init ]))
	{
		red = [ color redComponent ];
		green = [ color greenComponent ];
		blue = [ color blueComponent ];
		alpha = [ color alphaComponent ];
		return self;
	}
	return nil;
}

- (MDColor*) initWithRed: (float) r green: (float) g blue: (float) b alpha: (float) a
{
	if ((self = [ super init ]))
	{
		red = r;
		green = g;
		blue = b;
		alpha = a;
		return self;
	}
	return nil;
}

- (MDColor*) init
{
	if ((self = [ super init ]))
	{
		red = 0;
		green = 0;
		blue = 0;
		alpha = 1;
		return self;
	}
	return nil;
}

- (float) redValue
{
	return red;
}

- (float) greenValue
{
	return green;
}

- (float) blueValue
{
	return blue;
}

- (float) alphaValue
{
	return alpha;
}

- (void) setRedValue: (float) value
{
	red = value;
}

- (void) setGreenValue: (float) value
{
	green = value;
}

- (void) setBlueValue: (float) value
{
	blue = value;
}

- (void) setAlphaValue: (float) value
{
	alpha = value;
}

- (NSColor*) colorValue
{
	return [ NSColor colorWithCalibratedRed:red / 255.0
				green:green / 255.0 blue:blue / 255.0 alpha:alpha / 255.0 ];
}

@end
