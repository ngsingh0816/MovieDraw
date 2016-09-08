//
//  MDTableView.h
//  MovieDraw
//
//  Created by MILAP on 9/23/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

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

+ (id) mdTableView;
+ (id) mdTableViewWithFrame: (MDRect)rect background: (NSColor*)bkg;
- (void) addHeader: (NSString*)title;
- (void) removeHeader: (NSString*)title;
- (void) removeAllHeaders;
- (void) addRow: (NSDictionary*)obj;
- (void) insertRow:(NSDictionary*) obj atIndex: (unsigned int)row;
- (void) removeRow: (unsigned int) row;
- (void) removeAllRows;
- (NSDictionary*) objectAtRow: (unsigned int) row;
- (unsigned int) numberOfRows;
- (BOOL) rowIsVisible: (unsigned int) row;
- (int) selectedRow;
- (void) selectRow: (int) row;
- (BOOL) enableNoSelection;
- (void) setNoSelectionEnabled: (BOOL)en;
- (void) setSelectionColor: (NSColor*)col atIndex: (unsigned int) index;
- (NSColor*) selectionColorAtIndex: (unsigned int) index;
- (void) setClickTarget: (id) ctar;
- (void) setSingleClickAction: (SEL)ssel;
- (void) setDoubleClickAction: (SEL)dsel;
- (id) clickTarget;
- (SEL) singleClickAction;
- (SEL) doubleClickAction;
- (void) setImage: (unsigned int) image atIndex:(unsigned int)index;
- (unsigned int) imageAtIndex:(unsigned int)index;
- (NSSize) frameSize;

@end
