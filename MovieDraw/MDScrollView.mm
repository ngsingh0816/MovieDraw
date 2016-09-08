// 6408 , 684, 65(35, 380) - 10656, 38, 416520, 404920, = 410,000 = 1 pixel, 600, 224000
//  MDScrollView.mm
//  MovieDraw
//
//  Created by MILAP on 9/25/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

// barheight * scrollPixels = 600 * heightPixels
// value * maxScroll.height = 600 * frame.height;

#import "MDScrollView.h"
#import "MDButton.h"

@interface MDScrollView (InternalMethods)

- (void) decScroll: (id) sender;
- (void) incScroll: (id) sender;

@end

@implementation MDScrollView

+ (instancetype) mdScrollView
{
	return [ [ MDScrollView alloc ] init ];
}

+ (instancetype) mdScrollViewWithFrame: (MDRect)rect background:(NSColor*)bkg
{
	return [ [ MDScrollView alloc ] initWithFrame:rect background:bkg ];
}

- (instancetype) init
{
	if ((self = [ super init ]))
	{
		scroll.y = 0;
		scrollIncrement.height = 2;
		maxScroll.height = 100;
		alwaysShowVertical = FALSE;
		continuous = YES;
	}
	return self;
}

- (instancetype) initWithFrame: (MDRect)rect background:(NSColor*)bkg
{
	if ((self = [ super initWithFrame:rect background:bkg ]))
	{
		scroll.y = 0;
		scrollIncrement.height = 2;
		maxScroll.height = 100;
		alwaysShowVertical = FALSE;
		continuous = YES;
	}
	return self;
}

- (void) decScroll: (id) sender
{
    [ self updateScroll:0 vertical:scrollIncrement.height ];
	realDown = FALSE;
}

- (void) incScroll: (id) sender
{
	[ self updateScroll:0 vertical:-scrollIncrement.height ];
	realDown = FALSE;
}

- (void) updateScroll: (double)x vertical:(double)y
{
    double prevX = scroll.x, prevY = scroll.y;
    scroll.x -= x;
    if (scroll.x > maxScroll.width)
        scroll.x = maxScroll.width;
    if (scroll.x < 0)
        scroll.x = 0;
    scroll.y += y;
    if (scroll.y > maxScroll.height)
        scroll.y = maxScroll.height;
    if (scroll.y < 0)
        scroll.y = 0;
    
    for (int z = 0; z < [ subViews count ]; z++)
    {
        MDRect rect = [ (MDControlView*)subViews[z] frame ];
        rect.x += scroll.x - prevX;
        rect.y += scroll.y - prevY;
        [ (MDControlView*)subViews[z] setFrame:rect ];
    }
}

- (void) setScroll: (NSPoint)scr
{
	double prevX = scroll.x, prevY = scroll.y;
    scroll.x = scr.x;
    if (scroll.x > maxScroll.width)
        scroll.x = maxScroll.width;
    if (scroll.x < 0)
        scroll.x = 0;
    scroll.y = scr.y;
    if (scroll.y > maxScroll.height)
        scroll.y = maxScroll.height;
    if (scroll.y < 0)
        scroll.y = 0;
    
    for (int z = 0; z < [ subViews count ]; z++)
    {
        MDRect rect = [ (MDControlView*)subViews[z] frame ];
        rect.x += scroll.x - prevX;
        rect.y += scroll.y - prevY;
        [ (MDControlView*)subViews[z] setFrame:rect ];
    }
}

- (NSPoint) scroll
{
	return scroll;
}

- (void) setScrollIncrement: (NSSize) inc
{
	scrollIncrement = inc;
}

- (NSSize) scrollIncrement
{
	return scrollIncrement;
}

- (void) setMaxScroll: (NSSize) max
{
	maxScroll = max;
	if (maxScroll.height < 0)
		maxScroll.height = 0;
	if (maxScroll.width < 0)
		maxScroll.width = 0;
}

- (NSSize) maxScroll
{
	return maxScroll;
}

- (void) mouseDown:(NSEvent*)event
{
	if (!visible || !enabled)
		return;
	[ super mouseDown:event ];
	
	if (scrollTimer)
	{
		[ scrollTimer invalidate ];
		scrollTimer = nil;
	}
	
	NSPoint point = [ event locationInWindow ];
	point.x -= origin.x;
	point.y -= origin.y;
	point.x *= resolution.width / windowSize.width;
	point.y *= resolution.height / windowSize.height;
	if ((point.x >= frame.x + frame.width - 7 && point.x <= frame.x + frame.width && 
		point.y >= frame.y && point.y <= frame.y + frame.height - scrollOffset) || thisDown)
	{
		if (showOver)
		{
			float height = frame.height * frame.height / (frame.height + maxScroll.height);
			if (height < 20)
				height = 20;
			if (maxScroll.height <= 0.0)
				height = 0;
			float pos1 = frame.y + frame.height - scrollOffset - (height / 2) - ((scroll.y / maxScroll.height) * (frame.height - height - scrollOffset));
			float dist = pos1 - point.y;
			scroll.y += dist;
			[ self updateScroll:0 vertical:0 ];
			thisDown = TRUE;
		}
		return;
	}
	
	for (int z = 0; z < [ subViews count ]; z++)
		[ subViews[z] mouseDown:event ];
}

- (void) mouseDragged:(NSEvent*)event
{
	if (!visible || !enabled)
		return;
	if (up)
		return;
	[ super mouseDragged:event ];
	
	if (scrollTimer)
	{
		[ scrollTimer invalidate ];
		scrollTimer = [ NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(startFade) userInfo:nil repeats:NO ];
	}
	
	NSPoint point = [ event locationInWindow ];
	point.x -= origin.x;
	point.y -= origin.y;
	point.x *= resolution.width / windowSize.width;
	point.y *= resolution.height / windowSize.height;
	if ((point.x >= frame.x + frame.width - 7 && point.x <= frame.x + frame.width && 
		point.y >= frame.y && point.y <= frame.y + frame.height - scrollOffset) || thisDown)
	{
		if (showOver)
		{
			float height = frame.height * frame.height / (frame.height + maxScroll.height);//(600 * frame.height) / maxScroll.height;
			if (height < 20)
				height = 20;
			if (maxScroll.height <= 0.0)
				height = 0;
			float pos1 = frame.y + frame.height - scrollOffset - (height / 2) - ((scroll.y / maxScroll.height) * (frame.height - height - scrollOffset));
			float dist = pos1 - point.y;
			scroll.y += dist;
			[ self updateScroll:0 vertical:0 ];
			thisDown = TRUE;
		}
		return;
	}

	
	for (int z = 0; z < [ subViews count ]; z++)
		[ subViews[z] mouseDragged:event ];
}

- (void) mouseUp:(NSEvent*)event
{
	if (!visible || !enabled)
		return;
	
	thisDown = FALSE;
	
	if (fadeAlpha > 0.0)
	{
		if (scrollTimer)
			[ scrollTimer invalidate ];
		scrollTimer = [ NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(startFade) userInfo:nil repeats:NO ];
	}
	
	[ super mouseUp:event ];
	for (int z = 0; z < [ subViews count ]; z++)
		[ subViews[z] mouseUp:event ];
}

- (void) mouseMoved:(NSEvent*)event
{
	if (!visible || !enabled)
		return;
	[ super mouseMoved:event ];
	
	NSPoint point = [ event locationInWindow ];
	point.x -= origin.x;
	point.y -= origin.y;
	point.x *= resolution.width / windowSize.width;
	point.y *= resolution.height / windowSize.height;
	if (point.x >= frame.x + frame.width - 7 && point.x <= frame.x + frame.width && 
		point.y >= frame.y && point.y <= frame.y + frame.height - scrollOffset)
	{
		showOver = TRUE;
	}
	
	if (scrollTimer)
	{
		[ scrollTimer invalidate ];
		scrollTimer = [ NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(startFade) userInfo:nil repeats:NO ];
	}
	
	for (int z = 0; z < [ subViews count ]; z++)
		[ subViews[z] mouseMoved:event ];
}

- (void) startFade
{
	if (scrollTimer)
		[ scrollTimer invalidate ];
	fadeAlpha = 1;
	isFading = TRUE;
}

- (void) scrollWheel: (NSEvent*)event
{
	if (!visible || !enabled)
		return;
    
    for (int z = 0; z < [ subViews count ]; z++)
		[ subViews[z] scrollWheel:event ];
    
	NSPoint point = [ event locationInWindow ];
	point.x -= origin.x;
	point.y -= origin.y;
	point.x *= resolution.width / windowSize.width;
	point.y *= resolution.height / windowSize.height;
	if (!(point.x >= frame.x && point.x <= frame.x + frame.width &&
		point.y >= frame.y && point.y <= frame.y + frame.height))
		return;
	
	double xVal = [ event deltaX ], yVal = [ event deltaY ];
    [ self updateScroll:-xVal vertical:-yVal ];
	
	if (scrollTimer)
		[ scrollTimer invalidate ];
	scrollTimer = [ NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(startFade) userInfo:nil repeats:NO ];
	
	fadeAlpha = 1;
	scrolled = TRUE;
}

- (void) setAlwaysShowVertical: (BOOL)set
{
	alwaysShowVertical = set;
}

- (BOOL) alwaysShowVertical
{
	return alwaysShowVertical;
}

- (void) setAlwaysShowHorizontal: (BOOL)set
{
	alwaysShowHorizontal = set;
}

- (BOOL) alwaysShowHorizontal
{
	return alwaysShowHorizontal;
}

- (void) finishDraw
{
    [ super finishDraw ];
    for (int z = 0; z < [ subViews count ]; z++)
        [ subViews[z] finishDraw ];
}

- (void) setScrollOffset: (double)offset
{
	scrollOffset = offset;
}

- (double) scrollOffset
{
	return scrollOffset;
}

- (void) drawView
{
	if (!visible)
		return;
	if (maxScroll.height == 0 && !alwaysShowVertical)
		return;
	
	float height = frame.height * frame.height / (frame.height + maxScroll.height);
	if (height < 20)
		height = 20;
	if (maxScroll.height <= 0.0)
		height = 0;
	if (height != 0 && fadeAlpha > 0.0)
	{
		if (showOver)
		{
			glLoadIdentity();
			float realHeight = (frame.height / 2) - scrollOffset;
			glTranslated(frame.x + frame.width - 3.5, frame.y + (frame.height / 2) - scrollOffset, 0);
			NSColor* color = MD_SCROLL_DEFAULT_COLOR2;
			glColor4d([ color redComponent ], [ color greenComponent ], [ color blueComponent ], fadeAlpha);
			glBegin(GL_TRIANGLE_FAN);
			{
				glVertex2d(0, 0);
				for (int q = 0; q < 18; q++)
				{
					glVertex2d(cos((-q - 18) * M_PI / 18.0) * 3.5, ((frame.height / 2) - 3) + sin((-q - 18) * M_PI / 18.0) * 2);
				}
				glVertex2d(3.5, (frame.height / 2) - 3);
				
				glVertex2d(3.5, -realHeight + 3);
				for (int q = 0; q < 18; q++)
				{
					glVertex2d(cos(-q * M_PI / 18.0) * 3.5, (-realHeight + 3) + sin(-q * M_PI / 18.0) * 2);
				}
				glVertex2d(-3.5, -realHeight + 3);
				
				glVertex2d(-3.5, (frame.height / 2) - 3);
			}
			glEnd();
			
			glColor4d([ color redComponent ], [ color greenComponent ], [ color blueComponent ], -0.5 + fadeAlpha);
			glBegin(GL_TRIANGLE_FAN);
			{
				glVertex2d(0, 0);
				for (int q = 0; q < 18; q++)
				{
					glVertex2d(cos((-q - 18) * M_PI / 18.0) * 3.5, ((frame.height / 2) - 3) + sin((-q - 18) * M_PI / 18.0) * 3);
				}
				glVertex2d(3.5, (frame.height / 2) - 3);
				
				glVertex2d(3.5, -realHeight + 3);
				for (int q = 0; q < 18; q++)
				{
					glVertex2d(cos(-q * M_PI / 18.0) * 3.5, (-realHeight + 3) + sin(-q * M_PI / 18.0) * 3);
				}
				glVertex2d(-3.5, -realHeight + 3);
				
				glVertex2d(-3.5, (frame.height / 2) - 3);
			}
			glEnd();
		}
		
		glLoadIdentity();
		glTranslated(frame.x + frame.width - 3.5, frame.y + frame.height - scrollOffset - (height / 2) - ((scroll.y / maxScroll.height) * (frame.height - height - scrollOffset)), 0);
		NSColor* color = MD_SCROLL_DEFAULT_COLOR;
		glColor4d([ color redComponent ], [ color greenComponent ], [ color blueComponent ], fadeAlpha);
		glBegin(GL_TRIANGLE_FAN);
		{
			glVertex2d(0, 0);
			for (int q = 0; q < 18; q++)
			{
				glVertex2d(cos((-q - 18) * M_PI / 18.0) * 3.5, ((height / 2) - 3) + sin((-q - 18) * M_PI / 18.0) * 2);
			}
			glVertex2d(3.5, (height / 2) - 3);
			
			glVertex2d(3.5, (-height / 2) + 3);
			for (int q = 0; q < 18; q++)
			{
				glVertex2d(cos(-q * M_PI / 18.0) * 3.5, ((-height / 2) + 3) + sin(-q * M_PI / 18.0) * 2);
			}
			glVertex2d(-3.5, (-height / 2) + 3);
			
			glVertex2d(-3.5, (height / 2) - 3);
		}
		glEnd();
		
		glColor4d([ color redComponent ], [ color greenComponent ], [ color blueComponent ], -0.5 + fadeAlpha);
		glBegin(GL_TRIANGLE_FAN);
		{
			glVertex2d(0, 0);
			for (int q = 0; q < 18; q++)
			{
				glVertex2d(cos((-q - 18) * M_PI / 18.0) * 3.5, ((height / 2) - 3) + sin((-q - 18) * M_PI / 18.0) * 3);
			}
			glVertex2d(3.5, (height / 2) - 3);
			
			glVertex2d(3.5, (-height / 2) + 3);
			for (int q = 0; q < 18; q++)
			{
				glVertex2d(cos(-q * M_PI / 18.0) * 3.5, ((-height / 2) + 3) + sin(-q * M_PI / 18.0) * 3);
			}
			glVertex2d(-3.5, (-height / 2) + 3);
			
			glVertex2d(-3.5, (height / 2) - 3);
		}
		glEnd();
		
		if (isFading)
		{
			fadeAlpha -= 0.1;
			if (fadeAlpha <= 0.0)
			{
				fadeAlpha = 0;
				isFading = FALSE;
				showOver = FALSE;
			}
		}
	}
	
    glScissor(frame.x, frame.y, frame.width - 0, frame.height);
    glEnable(GL_SCISSOR_TEST);
	for (int z = 0; z < [ subViews count ]; z++)
		[ subViews[z] drawView ];
    glDisable(GL_SCISSOR_TEST);
    
	if (continuous && down && target != nil && [ target respondsToSelector:action ] &&
		(fpsCounter % ccount) == 0)
		((void (*)(id, SEL))[ target methodForSelector:action ])(target, action);
	fpsCounter++;
	if (fpsCounter >= 3600)
		fpsCounter -= 3600;
}

- (void) scrollToPoint:(NSPoint)point
{
	scroll.x = point.x;
	scroll.y = point.y;
}

- (void) dealloc
{    
	if (scrollTimer)
	{
		[ scrollTimer invalidate ];
		scrollTimer = nil;
	}
}

@end
