//
//  MDColorWell.h
//  MovieDraw
//
//  Created by MILAP on 7/26/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

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

+ (id) mdColorWell;
+ (id) mdColorWellWithFrame: (MDRect)rect background: (NSColor*)bkg;
- (void) setRotation: (float)rot;
- (float) rotation;
- (NSColor*) selectedColor;
- (void) selectColor: (NSColor*)col;
- (void) setSliderPos: (float)pos;
- (float) sliderPos;

@end
