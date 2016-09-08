/*
	MDTableView.h
	MovieDraw
 
	Copyright (c) 2013. All rights reserved.
*/

#import "MDScrollView.h"

@interface MDTableView : MDScrollView {
	NSMutableArray* headers;
	NSMutableArray* headerStrings;
	NSMutableArray* objects;
	NSMutableArray* objectStrings;
	NSMutableArray* objectImages;
	int selRow;
	BOOL enableNoSel;
	NSColor* selColor[4];
	id selTar;
	SEL singleClick;
	SEL doubleClick;
}

+ (instancetype) mdTableView;
+ (instancetype) mdTableViewWithFrame: (MDRect)rect background: (NSColor*)bkg;
- (void) addHeader: (NSString*)title;
- (void) removeHeader: (NSString*)title;
- (void) removeAllHeaders;
- (void) addRow: (NSDictionary*)obj;
- (void) insertRow:(NSDictionary*) obj atIndex: (unsigned int)row;
- (void) removeRow: (unsigned int) row;
- (void) removeAllRows;
- (NSDictionary*) objectAtRow: (unsigned int) row;
@property (readonly) unsigned int numberOfRows;
- (BOOL) rowIsVisible: (unsigned int) row;
@property (readonly) int selectedRow;
- (void) selectRow: (int) row;
@property (readonly) BOOL enableNoSelection;
- (void) setNoSelectionEnabled: (BOOL)en;
- (void) setSelectionColor: (NSColor*)col atIndex: (unsigned int) index;
- (NSColor*) selectionColorAtIndex: (unsigned int) index;
@property (strong) id clickTarget;
@property  SEL singleClickAction;
@property  SEL doubleClickAction;
- (void) setImage: (unsigned int) image atIndex:(unsigned int)index;
- (unsigned int) imageAtIndex:(unsigned int)index;
@property (readonly) NSSize frameSize;

@end
