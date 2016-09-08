//
//  MDToolbarItem.h
//  MovieDraw
//
//  Created by MILAP on 7/22/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MDControl.h"

typedef enum
{
	MDITEM_NORMAL = 0,
	MDITEM_BUTTON,
	MDITEM_MENU,
} MDItemOption;

@interface MDToolbarItem : MDControl {
	NSString* image;
	NSColor* overlay;
	MDItemOption type;
	unsigned int img;
}

+ (id) mdToolbarItem;
+ (id) mdToolbarItemWithFrame: (MDRect)rect background: (NSColor*)bkg;
- (void) setImagePath: (char*)data length:(unsigned int)len;
- (NSString*) imagePath;
- (void) setItemType: (MDItemOption)option;
- (MDItemOption) itemType;
- (NSColor*)overlay;
- (void) setOverlay: (NSColor*)ov;

@end
