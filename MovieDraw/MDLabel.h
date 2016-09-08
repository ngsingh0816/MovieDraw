/*
	MDLabel.h
	MovieDraw
 
	Copyright (c) 2013. All rights reserved.
*/

#import "MDControl.h"

@interface MDLabel : MDControl {
	float rotation;
	NSTextAlignment align;
	NSString* realText;
	BOOL oneLine;
	BOOL changeHeight;
	BOOL wrap;
	BOOL truncate;
}

+ (instancetype) mdLabel;
+ (instancetype) mdLabelWithFrame: (MDRect)rect background: (NSColor*)bkg;
@property  float rotation;
@property  NSTextAlignment textAlignment;
@property  BOOL oneLine;
@property  BOOL changeHeight;
@property  BOOL wraps;
@property  BOOL truncates;

@end
