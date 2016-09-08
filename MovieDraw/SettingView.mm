//
//  SettingView.mm
//  MovieDraw
//
//  Created by Neil on 7/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SettingView.h"


@implementation SettingView

- (instancetype)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
		text = [ [ NSString alloc ] init ];
		NSTrackingAreaOptions trackingOptions = NSTrackingEnabledDuringMouseDrag |
		NSTrackingMouseEnteredAndExited |
		NSTrackingActiveInActiveApp |
		NSTrackingActiveAlways;
		NSDictionary* userInfo = @{@"Number": @0};
		[ self addTrackingArea:[ [ NSTrackingArea alloc ] initWithRect:frame options:trackingOptions owner:self userInfo:userInfo ] ];
		NSRect rect = NSMakeRect(frame.origin.x + frame.size.width - 20, frame.origin.y + (frame.size.height / 2) - 5, 10, 10);
		userInfo = @{@"Number": @1};
		track =  [ [ NSTrackingArea alloc ] initWithRect:rect options:trackingOptions owner:self userInfo:userInfo ];
		[ self addTrackingArea:track ];
		[ self setAutoresizingMask:NSViewWidthSizable ];
		over = TRUE;
		lastOver = TRUE;
		overSetting = FALSE;
		realOver = FALSE;
    }
    
    return self;
}

- (void) setFrame:(NSRect)frameRect
{
	[ super setFrame:frameRect ];
	if (!track)
		return;
	
	[ self removeTrackingArea:track ];
	NSRect frame = frameRect;
	NSTrackingAreaOptions trackingOptions = NSTrackingEnabledDuringMouseDrag |
	NSTrackingMouseEnteredAndExited |
	NSTrackingActiveInActiveApp |
	NSTrackingActiveAlways;
	NSRect rect = NSMakeRect(frame.origin.x + frame.size.width - 20, frame.origin.y + (frame.size.height / 2) - 5, 10, 10);
	NSDictionary* userInfo = @{@"Number": @1};
	track =  [ [ NSTrackingArea alloc ] initWithRect:rect options:trackingOptions owner:self userInfo:userInfo ];
	[ self addTrackingArea:track ];
}

- (void) setTarget: (id) tar
{
	target = tar;
}

- (id) target
{
	return target;
}

- (void) setAction: (SEL) act
{
	action = act;
}

- (SEL) action
{
	return action;
}

- (void) setText: (NSString*)te
{
	text = [ [ NSString alloc ] initWithString:te ];
}

- (NSString*) text
{
	return text;
}

- (void) toggle: (NSTimer*)timer
{
	over = TRUE;
	[ self setNeedsDisplay:YES ];
}

- (void) toggle2: (NSTimer*)timer
{
	NSMenu* menu = [ [ self enclosingMenuItem ] menu ];
	if (!overSetting)
		[ menu performActionForItemAtIndex:[ menu indexOfItem:[ self enclosingMenuItem ] ] ];
	else if (target && action && [ target respondsToSelector:action ])
		((void (*)(id, SEL, id))[ target methodForSelector:action ])(target, action, [ self enclosingMenuItem ]);
	overSetting = FALSE;
	realOver = FALSE;
}

- (void) mouseEntered:(NSEvent *)theEvent
{
	// Set all others to off
	NSMenu* menu = [ [ self enclosingMenuItem ] menu ];
	for (unsigned long z = 0; z < [ menu numberOfItems ]; z++)
	{
		SettingView* view = (SettingView*)[ [ menu itemAtIndex:z ] view ];
		if (view != self)
			[ view unselect ];
	}
	
	int which = [ [ [ theEvent trackingArea ] userInfo ][@"Number"] intValue ];
	if (which == 0)
		realOver = TRUE;
	else
		overSetting = TRUE;
}

- (void) mouseExited:(NSEvent *)theEvent
{
	int which = [ [ [ theEvent trackingArea ] userInfo ][@"Number"] intValue ];
	if (which == 0)
		realOver = FALSE;
	else
		overSetting = FALSE;
}


- (void) mouseUp:(NSEvent *)theEvent
{
	if ([ [ self enclosingMenuItem ] isHighlighted ])
	{
		over = FALSE;
		NSTimer* timer = [ NSTimer scheduledTimerWithTimeInterval:0.075 target:self selector:@selector(toggle:) userInfo:nil repeats:NO ];
		[ [ NSRunLoop currentRunLoop ] addTimer:timer forMode:NSRunLoopCommonModes ];
		[ self setNeedsDisplay:YES ];
	}
}

- (void) unselect
{
	realOver = FALSE;
	overSetting = FALSE;
	[ self setNeedsDisplay:YES ];
}

- (void)drawRect:(NSRect)dirtyRect
{
	if (dirtyRect.size.width < [ [ [ self enclosingMenuItem ] menu ] size ].width)
	{
		dirtyRect.size.width = [ [ [ self enclosingMenuItem ] menu ] size ].width;
		[ self setFrame:dirtyRect ];
	}
	[ self lockFocus ];

	float value = 251.0 / 255.0;
	NSColor* background = [ NSColor colorWithCalibratedRed:value green:value blue:value alpha:value ];
	if (over && realOver)
		background = [ NSColor selectedMenuItemColor ];
	[ background set ];
	[ NSBezierPath fillRect:dirtyRect ];
	
	NSFont* font = [ [ [ self enclosingMenuItem ] menu ] font ];
	NSColor* textColor = [ NSColor blackColor ];
	if (over && realOver)
		textColor = [ NSColor selectedMenuItemTextColor ];
	[ [ NSString stringWithString:text ] drawAtPoint:NSMakePoint(dirtyRect.origin.x + 21, dirtyRect.origin.y + 2) withAttributes:@{NSFontAttributeName: font, NSForegroundColorAttributeName: textColor} ];
	
	NSRect rect = NSMakeRect(dirtyRect.origin.x + dirtyRect.size.width - 20, dirtyRect.origin.y + (dirtyRect.size.height / 2) - 5, 10, 10);
	[ textColor set ];
	NSFrameRect(rect);
	
	[ self unlockFocus ];
	
	if (lastOver != over && lastOver == FALSE)
	{
		[ [ [ self enclosingMenuItem ] menu ] cancelTracking ];
		NSTimer* timer = [ NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(toggle2:) userInfo:nil repeats:NO ];
		[ [ NSRunLoop currentRunLoop ] addTimer:timer forMode:NSRunLoopCommonModes ];

	}
	lastOver = over;
}

@end
