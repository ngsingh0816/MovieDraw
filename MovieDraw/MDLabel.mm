//
//  MDLabel.m
//  MovieDraw
//
//  Created by MILAP on 7/10/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MDLabel.h"


@implementation MDLabel

+ (instancetype) mdLabel
{
	MDLabel* view = [ [ MDLabel alloc ] init ];
	return view;
}

+ (instancetype) mdLabelWithFrame: (MDRect)rect background: (NSColor*)bkg;
{
	MDLabel* view = [ [ MDLabel alloc ] initWithFrame:rect background:bkg ];
	return view;
}

- (instancetype) init
{
	if ((self = [ super init ]))
	{
		rotation = 0;
		align = NSCenterTextAlignment;
		realText = [ [ NSString alloc ] init ];
		changeHeight = TRUE;
		wrap = TRUE;
		return self;
	}
	return nil;
}

- (instancetype) initWithFrame: (MDRect)rect background: (NSColor*)bkg;
{
	if ((self = [ super initWithFrame:rect background:bkg ]))
	{
		rotation = 0;
		align = NSCenterTextAlignment;
		realText = [ [ NSString alloc ] init ];
		changeHeight = TRUE;
		wrap = TRUE;
		return self;
	}
	return nil;
}

- (void) setRotation: (float)rot
{
	rotation = rot;
}

- (float) rotation
{
	return rotation;
}

- (void) setBackground:(NSColor *)bkg
{
	[ super setBackground:bkg ];
	glStr = LoadString(text, background, textFont);
	if (changeHeight && frame.height < [ glStr frameSize ].height)
		frame.height = [ glStr frameSize ].height;
	if (truncate)
	{
		[ glStr setFromRight:YES ];
		[ glStr useStaticFrame:NSMakeSize(frame.width, frame.height) ];
	}
}

- (void) setTextFont:(NSFont *)font
{
	[ super setTextFont:font ];
	[ self setText:[ NSString stringWithFormat:@"%@", realText ] ];
}

- (void) setFrame:(MDRect)rect
{
	float prevWidth = frame.width;
	[ super setFrame:rect ];
	if (prevWidth != rect.width)
		[ self setText:[ NSString stringWithFormat:@"%@", realText ] ];
}

- (void) setText:(NSString *)str
{
	text = [ [ NSMutableString alloc ] initWithString:str ];
	realText = [ [ NSString alloc ] initWithString:str ];
	float width = 0;
	float specialWidth = 0;
	if (oneLine)
	{
		GLString* string = LoadString(@"...", background, textFont);
		[ string setMargins:NSMakeSize(0, 0) ];
		specialWidth = [ string frameSize ].width;
	}
	for (unsigned long z = 0; z < [ text length ]; z++)
	{
		GLString* string = LoadString([ NSString stringWithFormat:@"%c", [ text characterAtIndex:z ] ], background, textFont);
		[ string setMargins:NSMakeSize(0, 0) ];
		width += [ string frameSize ].width;
		if ([ text characterAtIndex:z ] == '\n')
			width = 0;
		if (width >= frame.width - specialWidth - 4)
		{
			if (oneLine)
			{
				[ text deleteCharactersInRange:NSMakeRange(z, [ text length ] - z) ];
				[ text appendString:@"..." ];
				break;
			}
			else if (wrap)
			{
				BOOL shouldStop = FALSE;
				// find last space
				for (long long y = z; y >= 0; y--)
				{
					if (([ text characterAtIndex:y ] == ' ' || [ text characterAtIndex:y ] == '\n' || [ text characterAtIndex:y ] == '\t') || y == 0)
					{
						if ([ text length ] > z + 1)
						{
							GLString* string2 = LoadString([ text substringWithRange:NSMakeRange(y, z - y + 1) ], background, textFont);
							[ string2 setMargins:NSMakeSize(0, 0) ];
							if ([ string2 frameSize ].width > frame.width)
							{
								shouldStop = TRUE;
								break;
							}
						}
						[ text insertString:@"\n" atIndex:y + 1 ];
						z = y + 2;
						break;
					}
				}
				if (shouldStop)
					break;
				width = 0;
			}
		}
	}
	glStr = LoadString(text, background, textFont);
	if (changeHeight && frame.height < [ glStr frameSize ].height)
		frame.height = [ glStr frameSize ].height;
	if (truncate)
	{
		[ glStr setFromRight:YES ];
		[ glStr useStaticFrame:NSMakeSize(frame.width, frame.height) ];
	}
}

- (void) setTextAlignment: (NSTextAlignment) alignment
{
	align = alignment;
}

- (NSTextAlignment) textAlignment
{
	return align;
}

- (void) setOneLine:(BOOL)one
{
	oneLine = one;
	[ self setText:[ NSString stringWithString:realText ] ];
}

- (BOOL) oneLine
{
	return oneLine;
}

- (void) setChangeHeight: (BOOL)change
{
	changeHeight = change;
}

- (BOOL) changeHeight
{
	return changeHeight;
}

- (void) setWraps: (BOOL)wr
{
	wrap = wr;
}

- (BOOL) wraps
{
	return wrap;
}

- (void) setTruncates:(BOOL)trun
{
	truncate = trun;
	[ self setText:[ NSString stringWithString:realText ] ];
}

- (BOOL) truncates
{
	return truncate;
}

- (void) drawView
{
	if (!visible)
		return;
	if (!text || [ text length ] == 0)
		return;
	if (!glStr)
	{
		float add = !enabled ? -0.3 : 0.0;
		glStr = LoadString(text, [ NSColor colorWithCalibratedRed:
		[ background redComponent ] + add green:[ background greenComponent ] + add
		blue:[ background blueComponent ] + add alpha:[ background alphaComponent ] ],
						   textFont);
	}
	NSPoint drawPoint = NSMakePoint(frame.x, frame.y - [ glStr realSize ].height / 2);
	if (align == NSLeftTextAlignment)
		drawPoint.x += [ glStr frameSize ].width / 2;
	else if (align == NSRightTextAlignment)
		drawPoint.x -= [ glStr frameSize ].width / 2;
	DrawString(glStr, drawPoint, NSCenterTextAlignment, rotation);
	
	if (continuous && down && target != nil && [ target respondsToSelector:action ] &&
		(fpsCounter % ccount) == 0)
		((void (*)(id, SEL))[ target methodForSelector:action ])(target, action);
	fpsCounter++;
	if (fpsCounter >= 3600)
		fpsCounter -= 3600;
}

@end
