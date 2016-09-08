/*
	MDMenu.h
	MovieDraw
 
	Copyright (c) 2013. All rights reserved.
*/

#import "MDControl.h"
#include <vector>

#define MD_MENU_DEFAULT_COLOR [ NSColor colorWithCalibratedRed:1 green:1 blue:1 alpha:1 ]
#define MD_SUBMENU_DEFAULT_COLOR [ NSColor colorWithCalibratedRed:1 green:1 blue:1 alpha:0.95 ]
#define MD_MENU_DEFAULT_SELECTION_COLOR	[ NSColor colorWithCalibratedRed:0.285 green:0.45 blue:0.94 alpha:1 ]
//#define MD_MENU_DEFAULT_SELECTION_COLOR [ [ NSColor selectedMenuItemColor ] colorUsingColorSpace:[ NSColorSpace genericRGBColorSpace ] ]
#define MD_MENU_DEFAULT_SELECTION_COLOR_LOW [ NSColor colorWithCalibratedRed:0.17 green:0.38 blue:0.93 alpha:1 ]
#define MD_MENU_DEFAULT_SELECTION_COLOR_HIGH [ NSColor colorWithCalibratedRed:0.4 green:0.53 blue:0.95 alpha:1 ]
#define MD_MENU_DEFAULT_TEXT_SELECTION_COLOR [ [ NSColor selectedMenuItemTextColor ] colorUsingColorSpace:[ NSColorSpace genericRGBColorSpace ] ]
#define MD_MENU_DEFAULT_DELAY_TIME_OFF	0.075
#define MD_MENU_DEFAULT_DELAY_TIME_ON	0.1

@class MDPopupMenu;
MDPopupMenu* MDCreatePopupMenu(NSArray* items, NSPoint location, float width);

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
- (instancetype) initWithString:(NSString*)str withTarget:(id)tar andAction:(SEL)sel;
@property (copy) NSString *text;
@property (copy) NSFont *textFont;
@property (assign) id target;
@property  SEL action;
- (void) addSubItem: (MDMenuItem*)item;
- (void) removeSubItem: (MDMenuItem*)item;
- (void) insertSubItem: (MDMenuItem*)item atIndex:(unsigned int)index;
@property (readonly, copy) NSMutableArray *subItems;
@property  BOOL expanded;
@property (readonly, strong) GLString *glStr;
@property  MDRect frame;
@property (strong) MDMenuItem *parent;

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
	NSColor* selectionColor;
}

+ (instancetype) mdMenu;
+ (instancetype) mdMenuWithFrame: (MDRect)rect background:(NSColor*)bkg;
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
@property (readonly) BOOL removesOnClick;
@property  BOOL alwaysOnTop;

@property (copy) NSColor *selectionColor;

@end

@interface MDPopupMenu : MDMenu {
	unsigned int selectVao[2];
	float tempHeight;
}

@end
