/*
	MDColorWell.h
	MovieDraw
 
	Copyright (c) 2013. All rights reserved.
*/

#import "MDControl.h"

@class MDSlider, MDLabel;

@interface MDColorWell : MDControl {
	float rotation;
	NSColor* selectedColor;
	NSPoint colorPoint;
	float sliderPos;
	bool update;
	bool wantSel;
	NSColor* wantCol;
	MDSlider* alphaSlider;
	MDLabel* alphaText;
	BOOL slideDown;
}

+ (instancetype) mdColorWell;
+ (instancetype) mdColorWellWithFrame: (MDRect)rect background: (NSColor*)bkg;
@property  float rotation;
@property (readonly, copy) NSColor *selectedColor;
- (void) selectColor: (NSColor*)col;
@property  float sliderPos;

@end
