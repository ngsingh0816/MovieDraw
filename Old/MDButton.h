//
//  MDButton.h
//  MovieDraw
//
//  Created by MILAP on 7/9/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MDControl.h"

#define MD_BUTTON_DEFAULT_SIZE	NSMakeSize(70, 20)
#define MD_BUTTON_DEFAULT_BUTTON_COLOR	[ [ NSColor whiteColor ] colorUsingColorSpace:[ NSColorSpace genericRGBColorSpace ] ]
#define MD_BUTTON_DEFAULT_BUTTON_COLOR2 [ NSColor colorWithCalibratedRed:0.930 green:0.930 blue:0.930 alpha:1 ]
#define MD_BUTTON_DEFAULT_BORDER_COLOR	[ NSColor colorWithCalibratedRed:0.565 green:0.565 blue:0.565 alpha:1 ]
#define MD_BUTTON_DEFAULT_BORDER_COLOR2	[ NSColor colorWithCalibratedRed:0.310 green:0.349 blue:0.667 alpha:1 ]
#define MD_BUTTON_DEFAULT_DOWN_COLOR	[ NSColor colorWithCalibratedRed:0.596 green:0.717 blue:0.906 alpha:1 ]
#define MD_BUTTON_DEFAULT_DOWN_COLOR2	[ NSColor colorWithCalibratedRed:0.290 green:0.583 blue:0.901 alpha:1 ]
#define MD_BUTTON_DEFAULT_ANIMATION_HIGH [ NSColor colorWithCalibratedRed:0.733333 green:0.847059 blue:0.956863 alpha:1 ]
#define MD_BUTTON_DEFAULT_ANIMATION_HIGH2 [ NSColor colorWithCalibratedRed:0.537255 green:0.776471 blue:0.972549 alpha:1 ]
#define MD_BUTTON_DEFAULT_ANIMATION_LOW [ NSColor colorWithCalibratedRed:0.650980 green:0.772549 blue:0.917647 alpha:1 ]
#define MD_BUTTON_DEFAULT_ANIMATION_LOW2 [ NSColor colorWithCalibratedRed:0.443137 green:0.674510 blue:0.921569 alpha:1 ]

typedef enum 
{
	MDButtonTypeNormal = 0,
	MDButtonTypeSquare,
	MDButtonTypeCircle,
} MDButtonType;

@interface MDButton : MDControl {
	NSColor* mouseDownColor;
	NSColor* mouseDownColor2;
	NSColor* borderColor;
	NSColor* borderDownColor;
	BOOL changed;
	float* verticies;
	float* bverticies;
	float* colors;
	float* bcolors;
	MDButtonType type;
	BOOL isDefault;
	NSTimer* animationTimer;
	float mtime;
	BOOL mup;
}

+ (id) mdButton;
+ (id) mdButtonWithFrame: (MDRect)rect background: (NSColor*)bkg;
- (id) init;
- (id) initWithFrame: (MDRect)rect background: (NSColor*)bkg;
- (void) setMouseColor:(NSColor*)color;
- (void) setMouseColor2:(NSColor*)color;
- (NSColor*) mouseColor;
- (NSColor*) mouseColor2;
- (void) setBorderColor:(NSColor*)color;
- (void) setBorderColor2:(NSColor*)color;
- (NSColor*) borderColor;
- (NSColor*) borderColor2;
- (void) setButtonType:(MDButtonType)ty;
- (MDButtonType) type;
- (void) setIsDefault:(BOOL)def;
- (BOOL) isDefault;

@end