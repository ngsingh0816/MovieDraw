//
//  MDToolbarItem.h
//  MovieDraw
//
//  Created by MILAP on 7/22/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MDControl.h"

typedef NS_ENUM(int, MDItemOption)
{
	MDITEM_NORMAL = 0,
	MDITEM_BUTTON,
	MDITEM_MENU,
};

@interface MDToolbarItem : MDControl {
	NSString* image;
	NSColor* overlay;
	MDItemOption type;
	unsigned int img;
}

+ (instancetype) mdToolbarItem;
+ (instancetype) mdToolbarItemWithFrame: (MDRect)rect background: (NSColor*)bkg;
- (void) setImagePath: (char*)data length:(unsigned int)len;
@property (readonly, copy) NSString *imagePath;
@property  MDItemOption itemType;
@property (copy) NSColor *overlay;

@end
