/*
	MDPopup.h
	MovieDraw
 
	Copyright (c) 2013. All rights reserved.
*/

#import "MDControl.h"

@class MDPopupMenu;

#define MD_POPUP_DEFAULT_SIZE	NSMakeSize(96, 20)
#define MD_POPUP_DEFAULT_COLOR	[ [ NSColor whiteColor ] colorUsingColorSpace:[ NSColorSpace genericRGBColorSpace ] ]
#define MD_POPUP_DEFAULT_TRIANGLE_COLOR [ [ NSColor blackColor ] colorUsingColorSpace:[ NSColorSpace genericRGBColorSpace ] ]

@interface MDPopup : MDControl {
	NSMutableArray* titems;
	NSMutableArray* strings;
	unsigned long selectedItem;
	MDPopupMenu* popUp;
	NSColor* triangleColor;
	
	unsigned int triangleVao[2];
}

// Creation
+ (MDPopup*) mdPopup;
+ (MDPopup*) mdPopupWithFrame: (MDRect)rect background: (NSColor*)bkg;

// Colors
@property (copy) NSColor *triangleColor;

// Items
- (void) addItem:(NSString*)str;
- (void) removeItem: (NSString*)str;
@property (readonly) unsigned long numberOfItems;
- (NSString*) itemAtIndex:(unsigned long)index;
@property (readonly, copy) NSString *stringValue;
- (void) selectItem: (unsigned long)item;
@property (readonly) unsigned long selectedItem;

@end
