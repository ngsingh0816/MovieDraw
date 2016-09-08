//
//  MDTabSwitcher.m
//  MovieDraw
//
//  Created by Neil on 12/28/13.
//  Copyright (c) 2013 Neil. All rights reserved.
//

#import "MDTabSwitcher.h"

@implementation MDTabSwitcher

- (void) setNumberOfTabs:(unsigned int)tabs
{
	numTabs = tabs;
}

- (unsigned int) numberOfTabs
{
	return numTabs;
}

- (void) setTabView:(NSTabView*)tab
{
	tabView = tab;
}

- (NSTabView*) tabView
{
	return tabView;
}

- (void) mouseDown:(NSEvent *)theEvent
{
	[ super mouseDown:theEvent ];
	
	NSPoint point = [ theEvent locationInWindow ];
	point.x -= [ self frame ].origin.x;
	point.y -= [ self frame ].origin.y;
	
	NSPoint mid = NSMakePoint([ self bounds ].size.width / 2, [ self bounds ].size.height / 2);
	float height = [ self bounds ].size.height;
	
	float subtractX = -10.0 * numTabs + 5;
	
	for (unsigned long z = 0; z < numTabs; z++)
	{
		NSRect rect = NSMakeRect(mid.x + subtractX - 5, 0, 20, height);
		if (point.x >= rect.origin.x && point.x <= rect.origin.x + rect.size.width &&
			point.y >= rect.origin.y && point.y <= rect.origin.y + rect.size.height)
		{
			[ tabView selectTabViewItemAtIndex:z ];
			[ self setNeedsDisplay:YES ];
			break;
		}
		subtractX += 20;
	}
}

- (void)drawRect:(NSRect)dirtyRect
{
	[ super drawRect:dirtyRect ];
	
    // Drawing code here.
	
	[ self lockFocusIfCanDraw ];
	
	NSPoint mid = NSMakePoint([ self bounds ].size.width / 2, [ self bounds ].size.height / 2);
	
	float subtractX = -10.0 * numTabs + 5;
	
	for (unsigned long z = 0; z < numTabs; z++)
	{
		if ([ tabView indexOfTabViewItem:[ tabView selectedTabViewItem ] ] == z)
			[ [ NSColor colorWithCalibratedRed:0.3 green:0.5 blue:1.0 alpha:1.0 ] set ];
		else
			[ [ NSColor lightGrayColor ] set ];
		NSRectFill(NSMakeRect(mid.x + subtractX, mid.y - 6, 10, 10));
		subtractX += 20;
	}
	
	[ self unlockFocus ];
}

@end
