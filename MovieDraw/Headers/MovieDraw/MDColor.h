/*
	MDColor.h
	MovieDraw
 
	Copyright (c) 2013. All rights reserved.
*/

#import <Cocoa/Cocoa.h>


@interface MDColor : NSObject {
	float red;		// Red Value
	float green;	// Green Value
	float blue;		// Blue Value
	float alpha;	// Alpha Value
}

// Creation
+ (MDColor*) colorWithMDColor: (MDColor*) color;
+ (MDColor*) colorWithColor: (NSColor*) color;
+ (MDColor*) colorWithRed: (float) r green: (float) g blue: (float) b alpha: (float) a;
+ (MDColor*) color;

// Init
- (MDColor*) initWithMDColor: (MDColor*) color;
- (MDColor*) initWithColor: (NSColor*) color;
- (MDColor*) initWithRed: (float) r green: (float) g blue: (float) b alpha: (float) a;
- (MDColor*) init;

// Getters
@property  float redValue;
@property  float greenValue;
@property  float blueValue;
@property  float alphaValue;

// Setters

// Value
@property (readonly, copy) NSColor *colorValue;

@end
