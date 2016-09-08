//
//  GLWindow.mm
//  MovieDraw
//
//  Created by Neil on 5/16/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "GLWindow.h"


@implementation GLWindow

- (instancetype)init
{
	self = [super init];
	if (self) {
		desiredFPS = 60;
	}
	
	return self;
}

- (void) setUpGLView
{
	NSSize size = [ (NSView*)[ self contentView ] bounds ].size;
	if (!glView)
	{
		glView = [ [ GLView alloc ] initWithFrame:NSMakeRect(0, 0, size.width, size.height) colorBits:32 depthBits:32 fullscreen:NO ];
		//[ glView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable ];
		//[ [ self contentView ] addSubview:glView ];
		[ self setContentView:glView ];
	}
	[ self setAcceptsMouseMovedEvents:YES ];
	if (!timer)
	{
		if (desiredFPS == 0)
			desiredFPS = 60;
		timer = [ NSTimer scheduledTimerWithTimeInterval:1.0 / desiredFPS target:self selector:@selector(updateGL) userInfo:nil repeats:YES ];
		[ [ NSRunLoop mainRunLoop ] addTimer:timer forMode:NSRunLoopCommonModes ];
	}
}

- (void) updateGL
{
	if ([ glView canDraw ])
	{
		if (target && action2 && [ target respondsToSelector:action2 ])
			((void (*)(id, SEL))[ target methodForSelector:action2 ])(target, action2);
		
		[ glView lockFocus ];
		[ glView drawRect:[ glView frame ] ];
		[ glView unlockFocus ];
		
		if (target && action && [ target respondsToSelector:action ])
			((void (*)(id, SEL))[ target methodForSelector:action ])(target, action);
	}
}

- (GLView*) glView
{
	return glView;
}

- (void) setGLView: (GLView*)view
{
	glView = view;
	[ self setContentView:glView ];
	[ self setAcceptsMouseMovedEvents:YES ];
}

- (void) setTarget: (id) tar
{
	target = tar;
}

- (void) setAction: (SEL) act
{
	action = act;
}

- (void) setAction2: (SEL)act
{
	action2 = act;
}

- (id) target
{
	return target;
}

- (SEL) action
{
	return action;
}

- (SEL) action2
{
	return action;
}

- (void) setFPS:(unsigned int)fps
{
	desiredFPS = fps;
	if (desiredFPS == 0)
		desiredFPS = 60;
	if (timer)
		[ timer invalidate ];
	timer = [ NSTimer scheduledTimerWithTimeInterval:1.0 / desiredFPS target:self selector:@selector(updateGL) userInfo:nil repeats:YES ];
	[ [ NSRunLoop mainRunLoop ] addTimer:timer forMode:NSRunLoopCommonModes ];
}

- (unsigned int) FPS
{
	return desiredFPS;
}

- (void)dealloc
{
	if (timer)
	{
		[ timer invalidate ];
		timer = nil;
	}
	if (glView)
		[ self setContentView:nil ];
}

@end
