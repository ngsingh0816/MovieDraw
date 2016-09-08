//
//  MDToolbar.h
//  MovieDraw
//
//  Created by MILAP on 7/22/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MDControl.h"

@interface MDToolbar : MDControl {
	BOOL shown;
	NSMutableArray* titems;
	NSPoint lastMouse;
	float offset;
	int left;
	float speed;
	float height;
	int changing;
	unsigned char flags;
	BOOL drawTri;
}

+ (id) mdToolbar;
+ (id) mdToolbarWithFrame: (MDRect)rect background: (NSColor*)bkg;
- (BOOL) shown;
- (void) setShown: (BOOL) set;
- (NSMutableArray*) items;
- (void) setItems: (NSArray*) array;
- (void) addItem: (NSString*)str image:(NSString*)path target:(id)tar action:(SEL)sel;
- (float) moveSpeed;
- (void) setMoveSpeed: (float) spd;
- (void) setDrawTriangle:(BOOL) drw;
- (BOOL) drawTriangle;

@end
