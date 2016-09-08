//
//  MDMenu.h
//  MovieDraw
//
//  Created by MILAP on 1/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MDControl.h"
#include <vector>

#define MD_MENU_DEFAULT_COLOR [ NSColor colorWithCalibratedRed:0.9 green:0.9 blue:0.9 alpha:0.8 ]
#define MD_SUBMENU_DEFAULT_COLOR [ NSColor colorWithCalibratedRed:1 green:1 blue:1 alpha:0.95 ]
//#define MD_MENU_DEFAULT_SELECTION_COLOR [ [ NSColor selectedMenuItemColor ] colorUsingColorSpace:[ NSColorSpace genericRGBColorSpace ] ]
#define MD_MENU_DEFAULT_SELECTION_COLOR_LOW [ NSColor colorWithCalibratedRed:0.17 green:0.38 blue:0.93 alpha:1 ]
#define MD_MENU_DEFAULT_SELECTION_COLOR_HIGH [ NSColor colorWithCalibratedRed:0.4 green:0.53 blue:0.95 alpha:1 ]
#define MD_MENU_DEFAULT_TEXT_SELECTION_COLOR [ [ NSColor selectedMenuItemTextColor ] colorUsingColorSpace:[ NSColorSpace genericRGBColorSpace ] ]
#define MD_MENU_DEFAULT_DELAY_TIME_OFF	0.075
#define MD_MENU_DEFAULT_DELAY_TIME_ON	0.1

@class MDMenu;
MDMenu* MDPopupMenu(NSArray* items, NSPoint location, float width);

@interface MDMenuItem : NSObject
{
	NSString* text;
	id target;
	SEL action;
	GLString* glStr;
	NSMutableArray* subItems;
	BOOL expanded;
	MDRect frame;
	MDMenuItem* parent;
	NSFont* textFont;
}

+ (MDMenuItem*) menuItemWithString:(NSString*)string target:(id)tar action:(SEL)sel;
- (id) initWithString:(NSString*)str withTarget:(id)tar andAction:(SEL)sel;
- (void) setText: (NSString*) str;
- (NSString*) text;
- (void) setTextFont: (NSFont*) font;
- (NSFont*)textFont;
- (void) setTarget: (id) tar;
- (id) target;
- (void) setAction: (SEL)sel;
- (SEL) action;
- (void) addSubItem: (MDMenuItem*)item;
- (void) removeSubItem: (MDMenuItem*)item;
- (void) insertSubItem: (MDMenuItem*)item atIndex:(unsigned int)index;
- (NSMutableArray*) subItems;
- (void) setExpanded: (BOOL)expand;
- (BOOL) expanded;
- (GLString*) glStr;
- (void) setFrame:(MDRect)frm;
- (MDRect) frame;
- (MDMenuItem*) parent;
- (void) setParent: (MDMenuItem*)par;

@end

@interface MDMenu : MDControl {
	NSMutableArray* mitems;
	std::vector<unsigned int> expanded;
	int select;
	BOOL hit;
	BOOL tracking;
	MDMenuItem* selectedItem;
	BOOL fading;
	float currentAlpha;
	MDMenuItem* lastItem;
	BOOL removeOnClick;
	MDMenuItem* itemShadows;
	float itemShadowHeight;
	BOOL alwaysOnTop;
}

+ (id) mdMenu;
+ (id) mdMenuWithFrame: (MDRect)rect background:(NSColor*)bkg;
- (void) addItem:(NSString*)item target:(id)tar action:(SEL)sel;
- (void) removeItem:(NSString*)item;
- (void) insertItem:(NSString*)item target:(id)tar action:(SEL)sel atIndex:(unsigned int)index;
- (void) addItem:(MDMenuItem*)item;
- (void) removeMenuItem:(MDMenuItem*)item;
- (void) insertItem:(MDMenuItem*)item atIndex:(unsigned int)index;
- (void) addSubItem:(MDMenuItem*)item toItem:(unsigned int)index;
- (void) removeSubItem:(MDMenuItem*)item fromItem:(unsigned int)index;
- (void) insertSubItem:(MDMenuItem*)item toItem:(unsigned int)index atIndex:(unsigned int)nin;
- (void) expandItem: (unsigned int) expand;
- (void) setRemoveOnClick: (BOOL)click;
- (BOOL) removesOnClick;
- (void) setAlwaysOnTop: (BOOL)top;
- (BOOL) alwaysOnTop;
- (NSArray*) items;

@end
