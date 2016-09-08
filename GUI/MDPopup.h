//
//  MDPopup.h
//  MovieDraw
//
//  Created by MILAP on 12/14/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MDControl.h"

@class MDMenu;

#define MD_POPUP_DEFAULT_SIZE	NSMakeSize(96, 20)
#define MD_POPUP_DEFAULT_COLOR	[ [ NSColor whiteColor ] colorUsingColorSpace:[ NSColorSpace genericRGBColorSpace ] ]
#define MD_POPUP_DEFAULT_COLOR2 [ NSColor colorWithCalibratedRed:0.930 green:0.930 blue:0.930 alpha:1 ]
#define MD_POPUP_DEFAULT_BORDER_COLOR	[ NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:1 ]
// ^ really is 0.565, 0.565, 0.565, 1

@interface MDPopup : MDControl {
	NSMutableArray* titems;
	NSMutableArray* strings;
	unsigned long selectedItem;
	MDMenu* popUp;
	
	BOOL changed;
	float* verticies;
	float* bverticies;
	float* colors;
	float* bcolors;
}

+ (MDPopup*) mdPopup;
+ (MDPopup*) mdPopupWithFrame: (MDRect)rect background: (NSColor*)bkg;
- (void) addItem:(NSString*)str;
- (void) removeItem: (NSString*)str;
- (NSString*) stringValue;
- (void) selectItem: (unsigned long)item;
- (unsigned long) selectedItem;

@end
