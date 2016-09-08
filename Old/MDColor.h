//
//  MDColor.h
//  MovieDraw
//

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
- (float) redValue;
- (float) greenValue;
- (float) blueValue;
- (float) alphaValue;

// Setters
- (void) setRedValue: (float) value;
- (void) setGreenValue: (float) value;
- (void) setBlueValue: (float) value;
- (void) setAlphaValue: (float) value;

// Value
- (NSColor*) colorValue;

@end
