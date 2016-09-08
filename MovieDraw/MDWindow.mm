//
//  MDWindow.m
//  MovieDraw
//
//  Created by MILAP on 9/18/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MDWindow.h"
#import "MDButton.h"
#import "GLString.h"
#import "MDLabel.h"
#import "MDImageView.h"

#define TITLE_HEIGHT	22
#define MD_WINDOWBUTTON_COLOR	[ NSColor colorWithCalibratedRed:0.972549 green:0.392157 blue:0.372549 alpha:1 ]
#define MD_WINDOWBUTTON_COLOR2	[ NSColor colorWithCalibratedRed:0.984314 green:0.737255 blue:0.733333 alpha:1 ]
#define MD_WINDOWBUTTON_BORDER	[ NSColor colorWithCalibratedRed:0.545098 green:0.219608 blue:0.215686 alpha:1 ]
#define MD_WINDOWBUTTON_DCOLOR	[ NSColor colorWithCalibratedRed:0.721569 green:0.243137 blue:0.227451 alpha:1 ]
#define MD_WINDOWBUTTON_DCOLOR2	[ NSColor colorWithCalibratedRed:0.737255 green:0.556863 blue:0.552941 alpha:1 ]
#define MD_WINDOWBUTTON_DBORDER	[ NSColor colorWithCalibratedRed:0.450980 green:0.184314 blue:0.176471 alpha:1 ]
#define MD_WINDOWBUTTON_TOPBORDER	[ NSColor colorWithCalibratedRed:0.411765 green:0.211765 blue:0.203922 alpha:1 ]
#define MD_WINDOWBUTTON_BOTBORDER	[ NSColor colorWithCalibratedRed:0.639216 green:0.403922 blue:0.396078 alpha:1 ]
#define MD_WINDOWBUTTON_DTOPBORDER	[ NSColor colorWithCalibratedRed:0.305882 green:0.160784 blue:0.152941 alpha:1 ]
#define MD_WINDOWBUTTON_DBOTBORDER	[ NSColor colorWithCalibratedRed:0.490196 green:0.305882 blue:0.301961 alpha:1 ]
#define MD_WINDOWBUTTON_TEXTCOLOR	[ NSColor colorWithCalibratedRed:0.545098 green:0.078431 blue:0.090196 alpha:1 ]
#define MD_WINDOWBUTTON_DTEXTCOLOR	[ NSColor colorWithCalibratedRed:0.466667 green:0.031373 blue:0.047059 alpha:1 ]

MDWindow* currentAlert = nil;
float addHeight = 0;

@implementation MDWindow

+ (instancetype) mdWindow
{
	MDWindow* view = [ [ MDWindow alloc ] init ];
	return view;
}

+ (instancetype) mdWindowWithFrame: (MDRect)rect background: (NSColor*)bkg;
{
	MDWindow* view = [ [ MDWindow alloc ] initWithFrame:rect background:bkg ];
	return view;
}

+ (void) choiceChosen: (id) sender
{
	NSNumber* number = nil;
	if ([ [ (MDButton*)sender identity ] isEqualToString:@"Default" ])
		number = @0U;
	else if ([ [ (MDButton*)sender identity ] isEqualToString:@"Alternate" ])
		number = @1U;
	else
		number = @2U;
	[ currentAlert close:number ];
	currentAlert = nil;
}

+ (void) zoomIntro: (NSTimer*)timer
{
	float quick = 10;
	static unsigned int times = 0;
	
	NSColor* color = [ currentAlert background ];
	[ currentAlert setBackground:[ NSColor colorWithCalibratedRed:[ color redComponent ] green:[ color greenComponent ] blue:[ color blueComponent ] alpha:times / (quick - 1) ] ];
	
	NSSize targetSize = NSMakeSize(420, 150 + addHeight);
	[ currentAlert setFrame:MakeRect((resolution.width - (targetSize.width * times / (quick - 1))) / 2, (resolution.height - (targetSize.height * times / (quick - 1))) / 2, (targetSize.width * times / (quick - 1)), (targetSize.height * times / (quick - 1))) withSizes:YES ];
	[ currentAlert setVisible:YES ];
	
	for (int z = 0; z < [ [ currentAlert subViews ] count ]; z++)
	{
		if ([ [ (MDControlView*)[ currentAlert subViews ][z] identity ] isEqualToString:@"Title" ])
		{
			MDLabel* view = [ currentAlert subViews ][z];
			color = [ view background ];
			[ view setBackground:[ NSColor colorWithCalibratedRed:[ color redComponent ] green:[ color greenComponent ] blue:[ color blueComponent ] alpha:times / (quick - 1) ] ];
			float windowX = (resolution.width - (targetSize.width * times / (quick - 1))) / 2;
			float windowY = (resolution.height - (targetSize.height * times / (quick - 1))) / 2;
			float windowWidth = (targetSize.width * times / (quick - 1));
			float windowHeight = ((targetSize.height + TITLE_HEIGHT) * times / (quick - 1)) - TITLE_HEIGHT;
			[ view setChangeHeight:((times == (quick - 1)) ? YES : NO) ];
			[ view setFrame:MakeRect(windowX + (100 * times / (quick - 1)), windowY + windowHeight - (40 * times / (quick - 1)), windowWidth - (120 * times / (quick - 1)), 20 * times / (quick - 1)) ];
			[ view setVisible:YES ];
			
		}
		else if ([ [ (MDControlView*)[ currentAlert subViews ][z] identity ] isEqualToString:@"Message" ])
		{
			MDLabel* view = [ currentAlert subViews ][z];
			MDLabel* view2 = nil;
			for (int y = 0; y < [ [ currentAlert subViews ] count ]; y++)
			{
				if ([ [ (MDControlView*)[ currentAlert subViews ][y] identity ] isEqualToString:@"Title" ])
					view2 = [ currentAlert subViews ][y];
			}
			MDRect rect = MakeRect(0, 0, 0, 0);
			if (view2)
				rect = [ view2 frame ];
			color = [ view background ];
			[ view setBackground:[ NSColor colorWithCalibratedRed:[ color redComponent ] green:[ color greenComponent ] blue:[ color blueComponent ] alpha:times / (quick - 1) ] ];
			float windowX = (resolution.width - (targetSize.width * times / (quick - 1))) / 2;
			float windowWidth = (targetSize.width * times / (quick - 1));
			[ view setChangeHeight:((times == (quick - 1)) ? YES : NO) ];
			[ view setFrame:MakeRect(windowX + (100 * times / (quick - 1)), rect.y - (15 * times / (quick - 1)), windowWidth - (120 * times / (quick - 1)), 20 * times / (quick - 1)) ];
			[ view setVisible:YES ];
		}
		else if ([ [ (MDControlView*)[ currentAlert subViews ][z] identity ] isEqualToString:@"Image" ])
		{
			MDImageView* view = [ currentAlert subViews ][z];
			color = [ view background ];
			[ view setBackground:[ NSColor colorWithCalibratedRed:[ color redComponent ] green:[ color greenComponent ] blue:[ color blueComponent ] alpha:times / (quick - 1) ] ];
			float windowX = (resolution.width - (targetSize.width * times / (quick - 1))) / 2;
			float windowY = (resolution.height - (targetSize.height * times / (quick - 1))) / 2;
			float windowHeight = ((targetSize.height + TITLE_HEIGHT) * times / (quick - 1)) - TITLE_HEIGHT;
			[ view setFrame:MakeRect(windowX + (20 * times / (quick - 1)), windowY + windowHeight - (105 * times / (quick - 1)), 60 * times / (quick - 1), 60 * times / (quick - 1)) ];
			 [ view setVisible:YES ];
		}
		if (![ [ currentAlert subViews ][z] isKindOfClass:[ MDButton class ] ])
			continue;
		MDButton* button = [ currentAlert subViews ][z];
		if ([ [ button identity ] isEqualToString:@"Default" ])
		{
			float windowX = (resolution.width - (targetSize.width * times / (quick - 1))) / 2;
			float windowY = (resolution.height - (targetSize.height * times / (quick - 1))) / 2;
			float windowWidth = (targetSize.width * times / (quick - 1));
			[ button setFrame:MakeRect(windowX + windowWidth - (90 * times / (quick - 1)), windowY + (20 * times / (quick - 1)), 70 * times / (quick - 1), 20 * times / (quick - 1)) ];
			color = [ button background ];
			[ button setBackground:[ NSColor colorWithCalibratedRed:[ color redComponent ] green:[ color greenComponent ] blue:[ color blueComponent ] alpha:times / (quick - 1) ] ];
			//color = [ button backgroundAtIndex:1 ];
			//[ button setBackground:[ NSColor colorWithCalibratedRed:[ color redComponent ] green:[ color greenComponent ] blue:[ color blueComponent ] alpha:times / (quick - 1) ] atIndex:1 ];
			[ button setVisible:YES ];
		}
		else if ([ [ button identity ] isEqualToString:@"Alternate" ])
		{
			float windowX = (resolution.width - (targetSize.width * times / (quick - 1))) / 2;
			float windowY = (resolution.height - (targetSize.height * times / (quick - 1))) / 2;
			[ button setFrame:MakeRect(windowX + (100 * times / (quick - 1)), windowY + (20 * times / (quick - 1)), 70 * times / (quick - 1), 20 * times / (quick - 1)) ];
			color = [ button background ];
			[ button setBackground:[ NSColor colorWithCalibratedRed:[ color redComponent ] green:[ color greenComponent ] blue:[ color blueComponent ] alpha:times / (quick - 1) ] ];
			//color = [ button backgroundAtIndex:1 ];
			//[ button setBackground:[ NSColor colorWithCalibratedRed:[ color redComponent ] green:[ color greenComponent ] blue:[ color blueComponent ] alpha:times / (quick - 1) ] atIndex:1 ];
			[ button setVisible:YES ];
		}
		else if ([ [ button identity ] isEqualToString:@"Other" ])
		{
			float windowX = (resolution.width - (targetSize.width * times / (quick - 1))) / 2;
			float windowY = (resolution.height - (targetSize.height * times / (quick - 1))) / 2;
			float windowWidth = (targetSize.width * times / (quick - 1));
			[ button setFrame:MakeRect((windowX + windowWidth - (175 * times / (quick - 1))), windowY + (20 * times / (quick - 1)), 70 * times / (quick - 1), 20 * times / (quick - 1)) ];
			color = [ button background ];
			[ button setBackground:[ NSColor colorWithCalibratedRed:[ color redComponent ] green:[ color greenComponent ] blue:[ color blueComponent ] alpha:times / (quick - 1) ] ];
			//color = [ button backgroundAtIndex:1 ];
			//[ button setBackground:[ NSColor colorWithCalibratedRed:[ color redComponent ] green:[ color greenComponent ] blue:[ color blueComponent ] alpha:times / (quick - 1) ] atIndex:1 ];
			[ button setVisible:YES ];
		}
	}
	
	times++;
	if (times == quick)
	{
		[ timer invalidate ];
		times = 0;
	}
}

- (instancetype) init
{
	if ((self = [ super init ]))
	{
		closeButton = [ [ MDButton alloc ] init ];
		[ views removeObject:closeButton ];
		
		/*[ closeButton setButtonType:MDButtonTypeCircle ];
		[ closeButton setBorderColor:[ NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:0 ] ];
		[ closeButton setBorderColor2:[ NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:0 ] ];
		[ closeButton setBackground:MD_WINDOWBUTTON_COLOR ];
		[ closeButton setBackground:MD_WINDOWBUTTON_COLOR atIndex:1 ];
		[ closeButton setMouseColor2:MD_WINDOWBUTTON_DCOLOR ];
		[ closeButton setMouseColor:MD_WINDOWBUTTON_DCOLOR ];*/
		
		minFrame = NSZeroSize;
		maxFrame = NSZeroSize;
		canResize = TRUE;
		resizeViews = TRUE;
		originalRect = MakeRect(0, 0, 0, 0);
		
		titleChanged = TRUE;
		titleVert = (float*)malloc(sizeof(float) * 22 * 2);
		titleColors = (float*)malloc(sizeof(float) * 22 * 4);
		frameChanged = TRUE;
		frameVert = (float*)malloc(sizeof(float) * 22 * 2);
		frameColors = (float*)malloc(sizeof(float) * 22 * 4);
		bounds = MakeRect(0, 0, 0, 0);
	}
	return self;
}

- (instancetype) initWithFrame:(MDRect)rect background:(NSColor *)bkg
{
	if ((self = [ super initWithFrame:rect background:bkg ]))
	{
		closeButton = [ [ MDButton alloc ] init ];
		[ views removeObject:closeButton ];
		
		/*[ closeButton setButtonType:MDButtonTypeCircle ];
		[ closeButton setBorderColor:[ NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:0 ] ];
		[ closeButton setBorderColor2:[ NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:0 ] ];
		[ closeButton setBackground:MD_WINDOWBUTTON_COLOR ];
		[ closeButton setBackground:MD_WINDOWBUTTON_COLOR atIndex:1 ];
		[ closeButton setMouseColor2:MD_WINDOWBUTTON_DCOLOR ];
		[ closeButton setMouseColor:MD_WINDOWBUTTON_DCOLOR ];*/
		[ closeButton setFrame:MakeRect(rect.x + 11, rect.y + rect.height -	TITLE_HEIGHT + 6,
										10, 10) ];
		[ closeButton setTarget:self ];
		[ closeButton setAction:@selector(close:) ];
		
		
		minFrame = NSZeroSize;
		maxFrame = NSZeroSize;
		canResize = TRUE;
		resizeViews = TRUE;
		originalRect = rect;
		
		titleChanged = TRUE;
		titleVert = (float*)malloc(sizeof(float) * 22 * 2);
		titleColors = (float*)malloc(sizeof(float) * 22 * 4);
		frameChanged = TRUE;
		frameVert = (float*)malloc(sizeof(float) * 22 * 2);
		frameColors = (float*)malloc(sizeof(float) * 22 * 4);
		bounds = MakeRect(0, 0, 0, 0);
	}
	return self;
}

- (void) setEnabled:(BOOL)en
{
	[ super setEnabled:en ];
	glStr = nil;
}
- (void) setTextFont: (NSFont*) font
{
	[ super setTextFont:font ];
	glStr = nil;
	titleDot = nil;
}

- (void) setText: (NSString*) str
{
	[ super setText:str ];
	glStr = nil;
}

- (void) setTextColor:(NSColor *)color
{
	[ super setTextColor:color ];
	glStr = nil;
	titleDot = nil;
}

- (void) setFrame:(MDRect) rect
{
	[ self setFrame:rect withSizes:YES ];
}

- (void) setFrame:(MDRect) rect withSizes:(BOOL)use
{	
	if (use)
	{
		if (rect.width < minFrame.width)
			rect.width = minFrame.width;
		if (rect.height < minFrame.height)
			rect.height = minFrame.height;
		if ((rect.width > maxFrame.width) && maxFrame.width != 0)
			rect.width = maxFrame.width;
		if ((rect.height > maxFrame.height) && maxFrame.height != 0)
			rect.height = maxFrame.height;
		if (rect.width < 30)
			rect.width = 30;
		if (rect.height < TITLE_HEIGHT)
			rect.height = TITLE_HEIGHT;
	}
	if (bounds.width != 0)
	{
		if (boundedPoint[0])
		{
			if (rect.x < bounds.x)
				rect.x = bounds.x;
		}
		if (boundedPoint[1])
		{
			if (rect.x + rect.width > bounds.x + bounds.width)
				rect.x = bounds.x + bounds.width - rect.width;
		}
	}
	if (bounds.height != 0)
	{
		if (boundedPoint[2])
		{
			if (rect.y < bounds.y)
				rect.y = bounds.y;
		}
		if (boundedPoint[3])
		{
			if (rect.y + rect.height > bounds.y + bounds.height)
				rect.y = bounds.y + bounds.height - rect.height;
		}
	}
	
	[ closeButton setFrame:MakeRect(rect.x + 11, rect.y + rect.height - TITLE_HEIGHT + 6,
								   10, 10) ];
	for (int z = 0; z < [ subViews count ]; z++)
	{
		MDRect zf = [ (MDControlView*)subViews[z] frame ];
		if (!resizeViews)
		{
			[ (MDControlView*)subViews[z] setFrame:
			 MakeRect(zf.x - frame.x + rect.x, zf.y - frame.y + rect.y,
					  zf.width, zf.height) ];
		}
		else
		{
			double xper = 0, yper = 0, wper = 0, hper = 0;
			if (frame.width != 0)
			{
				xper = (zf.x - frame.x) / frame.width;
				wper = zf.width / frame.width;
			}
			if (frame.height != 0)
			{
				yper = (zf.y - frame.y) / (frame.height - TITLE_HEIGHT);
				hper = zf.height / (frame.height - TITLE_HEIGHT);
			}
			[ (MDControlView*)subViews[z] setFrame:
			 MakeRect((xper * rect.width) + rect.x, (yper * (rect.height - TITLE_HEIGHT)) + rect.y,
					  wper * rect.width, hper * (rect.height - TITLE_HEIGHT)) ];
		}
	}
	
	titleChanged = TRUE;
	frameChanged = TRUE;
	
	[ super setFrame:rect ];
	
	if (resizeTar && [ resizeTar respondsToSelector:resizeAct ])
		((void (*)(id, SEL, id))[ resizeTar methodForSelector:resizeAct ])(resizeTar, resizeAct, self);
}

- (void) setHasCloseButton:(BOOL)canClose
{
	[ closeButton setVisible:canClose ];
	[ closeButton setEnabled:canClose ];
}

- (BOOL) hasCloseButton
{
	return [ closeButton visible ];
}

- (void) setBackground:(NSColor *)bkg
{
	[ super setBackground:bkg ];
	titleChanged = TRUE;
	frameChanged = TRUE;
}

- (void) mouseDown:(NSEvent*)event
{
	if (!visible || !enabled)
		return;
	down = FALSE;
	up = TRUE;
	NSPoint point = [ event locationInWindow ];
	point.x -= origin.x;
	point.y -= origin.y;
	point.x *= resolution.width / windowSize.width;
	point.y *= resolution.height / windowSize.height;
	if (point.x >= frame.x && point.x <= frame.x + frame.width &&
		point.y >= frame.y && point.y <= frame.y + frame.height)
	{
		[ views removeObject:self ];
		[ views addObject:self ];
		
		down = TRUE;
		up = FALSE;
		realDown = TRUE;
		downPoint = point;
	}
	
	titleDown = FALSE;
	if (point.x >= frame.x + 25 && point.x <= frame.x + frame.width && point.y >= frame.y + frame.height - TITLE_HEIGHT && point.y <= frame.y + frame.height)
		titleDown = TRUE;
	
	[ closeButton mouseDown:event ];
	for (int z = 0; z < [ subViews count ]; z++)
		[ subViews[z] mouseDown:event ];
	
	mouse = [ event locationInWindow ];
	mouse.x -= origin.x;
	mouse.y -= origin.y;
	mouse.x *= resolution.width / windowSize.width;
	mouse.y *= resolution.height / windowSize.height;
	if (mouse.x >= frame.x + frame.width - 15 && mouse.x <= frame.x + frame.width &&
		mouse.y >= frame.y && mouse.y <= frame.y + 15)
		resizing = TRUE;
}

- (void) mouseDragged:(NSEvent*)event
{
	if (!visible || !enabled)
		return;
	if (up)
		return;
	NSPoint point = [ event locationInWindow ];
	point.x -= origin.x;
	point.y -= origin.y;
	point.x *= resolution.width / windowSize.width;
	point.y *= resolution.height / windowSize.height;
	point.x = round(point.x);
	point.y = round(point.y);
	if (!(point.x >= frame.x && point.x <= frame.x + frame.width &&
		  point.y >= frame.y && point.y <= frame.y + frame.height))
		down = up;
	else
		down = !up;
	
	[ closeButton mouseDragged:event ];
	for (int z = 0; z < [ subViews count ]; z++)
		[ subViews[z] mouseDragged:event ];
	
	NSSize tbounds = resolution;
	if (mouse.x >= frame.x + 25 && mouse.y >= frame.y + frame.height - TITLE_HEIGHT &&
		mouse.x > 0 && mouse.x < tbounds.width && mouse.y > 0 && mouse.y < tbounds.height)
	{
	}
	else if (resizing && canResize)
	{
		double newY = frame.y + point.y - mouse.y;
		float newW = frame.width + point.x - mouse.x;
		float newH = frame.height - point.y + mouse.y;
		if (newW + frame.x > resolution.width)
			newW = resolution.width - frame.x;
		else if (newW + frame.x < 15)
			newW = -frame.x + 15;
		if (newH + newY > resolution.height)
			newH = resolution.height - newY;
		if (newY < 0)
		{
			newH += newY;
			newY = 0;
		}
		[ self setFrame:MakeRect(frame.x, newY, newW, newH) ];
	}
	
	if (titleDown)
	{
		if (point.x > resolution.width || point.x < 0)
		{
			float minus = (point.x < 0) ? mouse.x : -(resolution.width - mouse.x);
			float yPoint = frame.y + point.y - mouse.y;
			if (point.y > resolution.height || point.y < 0)
			{
				float minusy = (point.y < 0) ? mouse.y : -(resolution.height - mouse.y);
				yPoint = frame.y - minusy;
			}
			[ self setFrame:MakeRect(frame.x - minus, yPoint, frame.width, frame.height) withSizes:NO ];
		}
		else if (point.y > resolution.height || point.y < 0)
		{
			float minus = (point.y < 0) ? mouse.y : -(resolution.height - mouse.y);
			[ self setFrame:MakeRect(frame.x + point.x - mouse.x, frame.y - minus, frame.width, frame.height) withSizes:NO ];
		}
		
		if (!(point.x > resolution.width || point.x < 0 || point.y > resolution.height || point.y < 0))
		{
			[ self setFrame:MakeRect(frame.x + point.x - mouse.x, frame.y + point.y - mouse.y, frame.width, frame.height) withSizes:NO ];
		}
	}
	
	float totalX = bounds.x;
	if (totalX < 0)
		totalX = 0;
	float totalWidth = bounds.x + bounds.width;
	if (totalWidth == 0 || totalWidth > resolution.width)
		totalWidth = resolution.width;
	float totalY = bounds.y;
	if (totalY < 0)
		totalY = 0;
	float totalHeight = bounds.y + bounds.height;
	if (totalHeight == 0 || totalHeight > resolution.height)
		totalHeight = resolution.height;
	
	if (point.x >= totalX && point.x <= totalWidth)
		mouse.x = point.x;
	else
		mouse.x = (point.x < totalX) ? totalX : totalWidth;
	if (point.y >= totalY && point.y <= totalHeight)
		mouse.y = point.y;
	else
		mouse.y = (point.y < totalY) ? totalY : totalHeight;
}

- (void) mouseUp:(NSEvent*)event
{
	if (!visible || !enabled)
		return;
	down = FALSE;
	up = TRUE;
	realDown = FALSE;
	resizing = FALSE;
	titleDown = FALSE;
	
	[ closeButton mouseUp:event ];
	for (int z = 0; z < [ subViews count ]; z++)
		[ subViews[z] mouseUp:event ];
}

- (void) mouseMoved:(NSEvent*)event
{
	[ super mouseMoved:event ];

	mouse = [ event locationInWindow ];
	mouse.x -= origin.x;
	mouse.y -= origin.y;
	mouse.x *= resolution.width / windowSize.width;
	mouse.y *= resolution.height / windowSize.height;
	
	[ closeButton mouseMoved:event ];
	for (int z = 0; z < [ subViews count ]; z++)
		[ subViews[z] mouseMoved:event ];
	resizing = FALSE;
}

- (void) scrollWheel:(NSEvent *)event
{
	[ super scrollWheel:event ];
	[ closeButton scrollWheel:event ];
	for (int z = (int)[ subViews count ] - 1; z >= 0; z--)
	{
		[ subViews[z] scrollWheel:event ];
		if ([ subViews[z] scrolled ])
		{
			scrolled = TRUE;
			break;
		}
	}
}

- (void) keyDown:(NSEvent *)event
{
	[ super keyDown:event ];
	[ closeButton keyDown:event ];
	for (int z = 0; z < [ subViews count ]; z++)
		[ subViews[z] keyDown:event ];
}

- (void) keyUp:(NSEvent *)event
{
	[ super keyUp:event ];
	[ closeButton keyUp:event ];
	for (int z = 0; z < [ subViews count ]; z++)
		[ subViews[z] keyUp:event ];
}

- (void) drawView
{
	if (!visible)
		return;
	
	if (titleChanged)
	{
		memset(titleVert, 0, 22 * 2 * sizeof(float));
		titleVert[0] = frame.x + (frame.width / 2);
		titleVert[1] = frame.y + frame.height - (TITLE_HEIGHT / 2.0);
		for (int i = 0; i < 18; i += 2)
		{
			float rad = ((i * 5) + 90) / 180.0 * M_PI;
			titleVert[i + 2] = frame.x + 3.5 - (sin(rad) * 3.5);
			titleVert[i + 3] = frame.y + frame.height - 3.5 - (cos(rad) * 3.5);
		}
		for (int i = 0; i < 18; i += 2)
		{
			float rad = (i * 5) / 180.0 * M_PI;
			titleVert[i + 20] = frame.x + frame.width - 3.5 + (sin(rad) * 3.5);
			titleVert[i + 21] = frame.y + frame.height - 3.5 + (cos(rad) * 3.5);
		}
		titleVert[38] = frame.x + frame.width;
		titleVert[39] = frame.y + frame.height - TITLE_HEIGHT;
		titleVert[40] = frame.x;
		titleVert[41] = frame.y + frame.height - TITLE_HEIGHT;
		titleVert[42] = frame.x;
		titleVert[43] = frame.y + frame.height - 3.5;
		
		memset(titleColors, 0, 22 * 4 * sizeof(float));
		for (int z = 0; z < 22; z++)
		{
			NSColor* color = MD_WINDOW_DEFAULT_TITLE_COLOR3;
			
			titleColors[(z * 4)] = [ color redComponent ];
			titleColors[(z * 4) + 1] = [ color greenComponent ];
			titleColors[(z * 4) + 2] = [ color blueComponent ];
			titleColors[(z * 4) + 3] = [ background alphaComponent ];
		}
		
		titleChanged = FALSE;
	}
	
#define STRENGTH	0.25
#define POWER		20
#define WPOWER		10
#define INTENSITY	0
	
	if (frame.height > TITLE_HEIGHT + 3.5)
	{		
		float fakeHeight = (frame.height - TITLE_HEIGHT);
		glLoadIdentity();
		glTranslated(frame.x + (frame.width / 2), frame.y + (fakeHeight / 2) - TITLE_HEIGHT, 0);
		glBegin(GL_TRIANGLE_FAN);
		{
			glColor4d(0, 0, 0, 0.3);
			glVertex2d(frame.width / 2, (fakeHeight / 2));
			
			glColor4d(0, 0, 0, INTENSITY);
			for (int z = 0; z <= 9; z++)
			{
				float angle = z / 18.0 * M_PI;
				glVertex2d((frame.width / 2) + (cos(angle) * WPOWER), (fakeHeight / 2) + (sin(angle) * WPOWER));
			}
		}
		glEnd();
		glBegin(GL_QUADS);
		{
			glColor4d(0, 0, 0, INTENSITY);
			glVertex2d((frame.width / 2) + WPOWER, fakeHeight / 2);
			glVertex2d((frame.width / 2) + WPOWER, -fakeHeight / 2 + TITLE_HEIGHT);
			glColor4d(0, 0, 0, 0.3);
			glVertex2d((frame.width / 2), -fakeHeight / 2  + TITLE_HEIGHT);
			glVertex2d((frame.width / 2), fakeHeight / 2);
		}
		glEnd();
		glBegin(GL_TRIANGLE_FAN);
		{
			glColor4d(0, 0, 0, 0.3);
			glVertex2d(frame.width / 2, -(fakeHeight / 2) + TITLE_HEIGHT);
			
			glColor4d(0, 0, 0, INTENSITY);
			for (int z = 0; z <= 9; z++)
			{
				float angle = z / 18.0 * M_PI;
				glVertex2d((frame.width / 2) + (cos(angle) * WPOWER), -(fakeHeight / 2) + TITLE_HEIGHT - (sin(angle) * POWER));
			}
		}
		glEnd();
		glBegin(GL_TRIANGLE_FAN);
		{
			glColor4d(0, 0, 0, 0.3);
			glVertex2d(-frame.width / 2, (fakeHeight / 2));
			
			glColor4d(0, 0, 0, INTENSITY);
			for (int z = 0; z <= 9; z++)
			{
				float angle = z / 18.0 * M_PI;
				glVertex2d(-(frame.width / 2) - (cos(angle) * WPOWER), (fakeHeight / 2) + (sin(angle) * WPOWER));
			}
		}
		glEnd();
		glBegin(GL_QUADS);
		{
			glColor4d(0, 0, 0, INTENSITY);
			glVertex2d(-(frame.width / 2) - WPOWER, fakeHeight / 2);
			glVertex2d(-(frame.width / 2) - WPOWER, -fakeHeight / 2 + TITLE_HEIGHT);
			glColor4d(0, 0, 0, 0.3);
			glVertex2d(-(frame.width / 2), -fakeHeight / 2  + TITLE_HEIGHT);
			glVertex2d(-(frame.width / 2), fakeHeight / 2);
		}
		glEnd();
		glBegin(GL_TRIANGLE_FAN);
		{
			glColor4d(0, 0, 0, 0.3);
			glVertex2d(-frame.width / 2, -(fakeHeight / 2) + TITLE_HEIGHT);
			
			glColor4d(0, 0, 0, INTENSITY);
			for (int z = 0; z <= 9; z++)
			{
				float angle = z / 18.0 * M_PI;
				glVertex2d(-(frame.width / 2) - (cos(angle) * WPOWER), -(fakeHeight / 2) + TITLE_HEIGHT - (sin(angle) * POWER));
			}
		}
		glEnd();
		glBegin(GL_QUADS);
		{
			glColor4d(0, 0, 0, INTENSITY);
			glVertex2d(-(frame.width / 2), -fakeHeight / 2 + TITLE_HEIGHT - POWER);
			glVertex2d((frame.width / 2), -fakeHeight / 2 + TITLE_HEIGHT - POWER);
			glColor4d(0, 0, 0, 0.3);
			glVertex2d((frame.width / 2), -fakeHeight / 2 + TITLE_HEIGHT);
			glVertex2d(-(frame.width / 2), -fakeHeight / 2 + TITLE_HEIGHT);
		}
		glEnd();
	}
	
	glLoadIdentity();
	glVertexPointer(2, GL_FLOAT, 0, titleVert);
	glEnableClientState(GL_VERTEX_ARRAY);
	glColorPointer(4, GL_FLOAT, 0, titleColors);
	glEnableClientState(GL_COLOR_ARRAY);
	glDrawArrays(GL_TRIANGLE_FAN, 0, 22);
	glDisableClientState(GL_VERTEX_ARRAY);
	glDisableClientState(GL_COLOR_ARRAY);
	
	glLoadIdentity();
	glTranslated(frame.x, frame.y + frame.height, 0);
	glBegin(GL_LINES);
	{
		NSColor* color = MD_WINDOW_DEFAULT_TITLE_COLOR3;
		glColor4d([ color redComponent ], [ color greenComponent ], [ color blueComponent ], [ background alphaComponent ]);
		glVertex2d(3.5, 0);
		glVertex2d(frame.width - 3.5, 0);
		
		color = MD_WINDOW_DEFAULT_TITLE_COLOR4;
		glColor4d([ color redComponent ], [ color greenComponent ], [ color blueComponent ], [ background alphaComponent ]);
		glVertex2d(0, -TITLE_HEIGHT);
		glVertex2d(frame.width, -TITLE_HEIGHT);
	}
	glEnd();
	glBegin(GL_QUADS);
	{
		glColor4d(0, 0, 0, 0);
		glVertex2d(0, -3.5);
		glVertex2d(frame.width, -3.5);
		float alpha = ([ MD_WINDOW_DEFAULT_TITLE_COLOR1 redComponent ] - [ MD_WINDOW_DEFAULT_TITLE_COLOR2 redComponent ]);
		glColor4d(0, 0, 0, alpha * [ background alphaComponent ]);
		glVertex2d(frame.width, -TITLE_HEIGHT);
		glVertex2d(0, -TITLE_HEIGHT);
	}
	glEnd();
	glLoadIdentity();
	
	if (frameChanged)
	{
		memset(frameVert, 0, 22 * 2 * sizeof(float));
		frameVert[0] = frame.x + (frame.width / 2);
		frameVert[1] = frame.y + ((frame.height - TITLE_HEIGHT) / 2);
		frameVert[2] = frame.x;
		frameVert[3] = frame.y + frame.height - TITLE_HEIGHT;
		frameVert[4] = frame.x + frame.width;
		frameVert[5] = frame.y + frame.height - TITLE_HEIGHT;		
		
		for (int i = 0; i < 18; i += 2)
		{
			float rad = -(i * 5) / 180.0 * M_PI;
			frameVert[i + 6] = frame.x + frame.width - 3.5 + (cos(rad) * 3.5);
			frameVert[i + 7] = frame.y + 3.5 + (sin(rad) * 3.5);
		}
		frameVert[22] = frame.x + frame.width - 3.5;
		frameVert[23] = frame.y;
		for (int i = 0; i < 18; i += 2)
		{
			float rad = (-(i * 5) + 270) / 180.0 * M_PI;
			frameVert[i + 24] = frame.x + 3.5 + (cos(rad) * 3.5);
			frameVert[i + 25] = frame.y + 3.5 + (sin(rad) * 3.5);
		}
		frameVert[40] = frame.x;
		frameVert[41] = frame.y + 3.5;
		frameVert[42] = frame.x;
		frameVert[43] = frame.y + frame.height - TITLE_HEIGHT;
		
		memset(frameColors, 0, 22 * 4 * sizeof(float));
		for (int z = 0; z < 22; z++)
		{
			NSColor* color = background;
			
			frameColors[(z * 4)] = [ color redComponent ];
			frameColors[(z * 4) + 1] = [ color greenComponent ];
			frameColors[(z * 4) + 2] = [ color blueComponent ];
			frameColors[(z * 4) + 3] = [ color alphaComponent ];
		}
		
		frameChanged = FALSE;
	}
	
	if (frame.height > TITLE_HEIGHT + 3.5)
	{
		glLoadIdentity();
		glVertexPointer(2, GL_FLOAT, 0, frameVert);
		glEnableClientState(GL_VERTEX_ARRAY);
		glColorPointer(4, GL_FLOAT, 0, frameColors);
		glEnableClientState(GL_COLOR_ARRAY);
		glDrawArrays(GL_TRIANGLE_FAN, 0, 22);
		glDisableClientState(GL_VERTEX_ARRAY);
		glDisableClientState(GL_COLOR_ARRAY);
	}
	
	if (canResize)
	{
		// Lines
		glLoadIdentity();
		glColor4d(0, 0, 0, [ background alphaComponent ]);
		glBegin(GL_LINES);
		{
			glVertex2d(frame.x + frame.width - 15, frame.y + 1);
			glVertex2d(frame.x + frame.width - 1, frame.y + 15);
			
			glVertex2d(frame.x + frame.width - 10, frame.y + 1);
			glVertex2d(frame.x + frame.width - 1, frame.y + 10);
			
			glVertex2d(frame.x + frame.width - 5, frame.y + 1);
			glVertex2d(frame.x + frame.width - 1, frame.y + 5);
		}
		glEnd();
		glLoadIdentity();
	}
	
	for (int z = 0; z < [ subViews count ]; z++)
		[ subViews[z] drawView ];
	
	if ([ closeButton enabled ])
	{
		MDRect closeRect = [ closeButton frame ];
		glLoadIdentity();
		glTranslated(closeRect.x + (closeRect.width / 2), closeRect.y + (closeRect.height / 2), 0);
		glBegin(GL_TRIANGLE_FAN);
		{
			NSColor* color = MD_WINDOWBUTTON_BORDER;
			if ([ closeButton realDown ])
				color = MD_WINDOWBUTTON_DBORDER;
			glColor4d([ color redComponent ], [ color greenComponent ], [ color blueComponent ], [ color alphaComponent ]);
			glVertex2d(0, 0);
			
			color = MD_WINDOWBUTTON_BOTBORDER;
			NSColor* color2 = MD_WINDOWBUTTON_TOPBORDER;
			if ([ closeButton realDown ])
			{
				color = MD_WINDOWBUTTON_DBOTBORDER;
				color2 = MD_WINDOWBUTTON_DTOPBORDER;
			}
			float diffHeightr = ([ color redComponent ] - [ color2 redComponent ]);
			float diffHeightg = ([ color greenComponent ] - [ color2 greenComponent ]);
			float diffHeightb = ([ color blueComponent ] - [ color2 blueComponent ]);
			float diffHeighta = ([ color alphaComponent ] - [ color2 alphaComponent ]);
			for (int z = 0; z < 18; z++)
			{
				float angle = z / 9.0 * M_PI;
				float mult = (sin(angle) + 1) / 2;
				float newRed = [ color redComponent ] - (diffHeightr * mult);
				float newGreen = [ color greenComponent ] - (diffHeightg * mult);
				float newBlue = [ color blueComponent ] - (diffHeightb * mult);
				float newAlpha = [ color alphaComponent ] - (diffHeighta * mult);
				glColor4d(newRed, newGreen, newBlue, newAlpha);
				glVertex2d(round(cos(angle) * (closeRect.width + 2) / 2), round(sin(angle) * (closeRect.height + 2) / 2));
			}
			glColor4d([ color redComponent ] + (diffHeightr / 2), [ color greenComponent ] + (diffHeightg / 2), [ color blueComponent ] + (diffHeightb / 2), [ color alphaComponent ] + (diffHeighta / 2));
			glVertex2d((closeRect.width / 2) + 1, 0);
		}
		glEnd();
		[ closeButton drawView ];
		glLoadIdentity();
		float amplitude = 1;
		if ([ closeButton realDown ])
			amplitude = 0.75;
		glTranslated(closeRect.x + (closeRect.width / 2), closeRect.y + 2.5, 0);
		glBegin(GL_TRIANGLE_FAN);
		{
			glColor4d(amplitude, amplitude, amplitude, 0.6);
			glVertex2d(0, 0);
			
			glColor4d(amplitude, amplitude, amplitude, 0.1);
			for (int z = 0; z < 9; z++)
			{
				float angle = (z * 40) / 180.0 * M_PI;
				glVertex2d(cos(angle) * 6, sin(angle) * 3);
			}
			glVertex2d(6, 0);
		}
		glEnd();
		glLoadIdentity();
		glTranslated(closeRect.x + (closeRect.width / 2), closeRect.y + closeRect.height - 2, 0);
		glBegin(GL_TRIANGLE_FAN);
		{
			glColor4d(amplitude, amplitude, amplitude, 0.9);
			glVertex2d(0, 0);
			
			glColor4d(amplitude, amplitude, amplitude, 0);
			for (int z = 0; z < 9; z++)
			{
				float angle = (z * 40) / 180.0 * M_PI;
				glVertex2d(cos(angle) * 6, sin(angle) * 3);
			}
			glVertex2d(6, 0);
		}
		glEnd();
		glLoadIdentity();
	
		if (mouse.x >= frame.x + 9 && mouse.x <= frame.x + 25 && mouse.y >= frame.y + frame.height - TITLE_HEIGHT + 3 && mouse.y <= frame.y + frame.height - 3)
		{
			glTranslated(closeRect.x + (closeRect.width / 2), closeRect.y + (closeRect.height / 2), 0);
			NSColor* color = MD_WINDOWBUTTON_TEXTCOLOR;
			if ([ closeButton realDown ])
				color = MD_WINDOWBUTTON_DTEXTCOLOR;
			glColor4d([ color redComponent ], [ color greenComponent ], [ color blueComponent ], 1);
			glBegin(GL_QUADS);
			{
				glVertex2d(-2, -2);
				glVertex2d(2, -2);
				glVertex2d(2, 2);
				glVertex2d(-2, 2);
						
				glVertex2d(-1, -1);
				glVertex2d(-3, -1);
				glVertex2d(-3, -3);
				glVertex2d(-1, -3);
				
				glVertex2d(1, -1);
				glVertex2d(3, -1);
				glVertex2d(3, -3);
				glVertex2d(1, -3);
				
				glVertex2d(-1, 1);
				glVertex2d(-3, 1);
				glVertex2d(-3, 3);
				glVertex2d(-1, 3);
				
				glVertex2d(1, 1);
				glVertex2d(3, 1);
				glVertex2d(3, 3);
				glVertex2d(1, 3);
			}
			glEnd();
			glLoadIdentity();
		}
	}
	
	if (!glStr)
		glStr = LoadString(text, textColor, textFont);
	
	if (!titleDot)
	{
		titleDot = LoadString(@"...", textColor, textFont);
	}
	
	if (frame.width > 60 + [ glStr realSize ].width)
	{
		[ glStr setFromRight:NO ];
		[ glStr useDynamicFrame ];
		DrawString(glStr, NSMakePoint(frame.x + (frame.width / 2), frame.y + frame.height - (TITLE_HEIGHT / 2)),
				   NSCenterTextAlignment, 0);
	}
	else if (frame.width > 30 + [ glStr realSize ].width)
	{
		[ glStr setFromRight:NO ];
		[ glStr useDynamicFrame ];
		DrawString(glStr, NSMakePoint(frame.x + 30, frame.y + frame.height - (TITLE_HEIGHT / 2)),
				   NSLeftTextAlignment, 0);
	}
	else if (frame.width > 30 + [ titleDot realSize ].width)
	{
		[ titleDot setFromRight:NO ];
		[ titleDot useDynamicFrame ];
		[ glStr setFromRight:YES ];
		[ glStr useStaticFrame:NSMakeSize(frame.width - 28 - [ titleDot frameSize ].width, [ glStr frameSize ].height) ];
		DrawString(glStr, NSMakePoint(frame.x + 30, frame.y + frame.height - (TITLE_HEIGHT / 2)),
				   NSLeftTextAlignment, 0);
		DrawString(titleDot, NSMakePoint(frame.x + 28 + [ glStr frameSize ].width, frame.y + frame.height - (TITLE_HEIGHT / 2)), NSLeftTextAlignment, 0);
	}
	else
	{
		[ titleDot setFromRight:YES ];
		[ titleDot useStaticFrame:NSMakeSize(frame.width - 35, [ titleDot realSize ].height) ];
		DrawString(titleDot, NSMakePoint(frame.x + 30, frame.y + frame.height - (TITLE_HEIGHT / 2)), NSLeftTextAlignment, 0);
	} 
}

- (void) setMinSize: (NSSize)rect
{
	minFrame = rect;
}

- (NSSize) minSize
{
	return minFrame;
}

- (void) setMaxSize: (NSSize)rect
{
	maxFrame = rect;
}

- (NSSize) maxSize
{
	return maxFrame;
}

- (void) close: (id) sender
{
	if (target && [ target respondsToSelector:action ])
		((void (*)(id, SEL, id))[ target methodForSelector:action ])(target, action, sender ? sender : self);
	
	[ subViews removeAllObjects ];
	[ views removeObject:self ];
	//[ self release ];
	//self = nil;
}

- (void) addSubView: (id) subview
{
	MDRect zf = [ (MDControlView*)subview frame ];
	[ (MDControlView*)subview setFrame:
	 MakeRect(frame.x + zf.x, frame.y + zf.y - TITLE_HEIGHT, zf.width, zf.height) ];
	[ (MDControlView*)subview setParentView:self ];
	[ subViews addObject:subview ];
	[ views removeObject:subview ];
}

- (void) removeSubViewAtIndex: (unsigned int) index
{
	if (index >= [ subViews count ])
		return;
	[ self removeSubView:subViews[index] ];
}

- (void) removeSubView: (id) subview
{
	if (![ views containsObject:subview ])
		[ views addObject:subview ];
	[ subViews removeObject:subview ];
}

- (void) setResizeSubviews: (BOOL) set
{
	resizeViews = set;
}

- (BOOL) resizeSubviews
{
	return resizeViews;
}

- (void) setCanResize: (BOOL) set
{
	canResize = set;
}

- (BOOL) canResize
{
	return canResize;
}

- (void) setResizeTarget: (id) tar
{
	resizeTar = tar;
}

- (id) resizeTarget
{
	return resizeTar;
}

- (void) setResizeAction: (SEL) act
{
	resizeAct = act;
}

- (SEL) resizeAction
{
	return resizeAct;
}

- (void) setBounds:(MDRect)bd
{
	bounds = bd;
}

- (MDRect) bounds
{
	return bounds;
}

- (void) setBoundedByPoint: (BOOL)bo atIndex:(unsigned int)index
{
	if (index > 3)
		return;
	boundedPoint[index] = bo;
}

- (BOOL) boundedByPointAtIndex:(unsigned int)index
{
	if (index > 3)
		return FALSE;
	return boundedPoint[index];
}

- (void) dealloc
{
	if (titleVert)
	{
		free(titleVert);
		titleVert = NULL;
	}
	if (titleColors)
	{
		free(titleColors);
		titleColors = NULL;
	}
	if (frameVert)
	{
		free(frameVert);
		frameVert = nil;
	}
	if (frameColors)
	{
		free(frameColors);
		frameColors = nil;
	}
	for (int z = 0; z < [ subViews count ]; z++)
	{
		if ([ views containsObject:subViews[z] ])
			[ views removeObject:subViews[z] ];
	}
}

@end

MDWindow* MDRunAlertPanel(NSString* title, NSString* message, NSString* defaultButton, NSString* alternateButton, NSString* otherButton, id target, SEL action)
{
	if (currentAlert)
		return nil;
	
	MDLabel* label = nil;
	addHeight = 0;
	if (message)
	{
		label = [ [ MDLabel alloc ] initWithFrame:MakeRect(100, 150 - 40, 420 - 120, 150 - 120) background:[ NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:1 ] ];
		[ label setVisible:NO ];
		[ label setIdentity:@"Message" ];
		[ label setTruncates:YES ];
		[ label setTextFont:[ NSFont systemFontOfSize:11 ] ];
		[ label setText:message ];
		if ([ label frame ].height != 150 - 120)
		{
			addHeight = [ label frame ].height - 150 + 120;
			MDRect lfrm = [ label frame ];
			lfrm.y += [ label frame ].height - 150 + 120;
			[ label setFrame:lfrm ];
			//[ window setFrame:frm withSizes:NO ];
		}
		[ label setTextAlignment:NSLeftTextAlignment ];
	}
	
	NSSize targetSize = NSMakeSize(420, 150 + addHeight);
	
	MDLabel* label2 = nil;
	if (title)
	{
		label2 = [ [ MDLabel alloc ] initWithFrame:MakeRect(100, targetSize.height - 20, targetSize.width - 120, 20) background:[ NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:1 ] ];
		[ label2 setVisible:NO ];
		[ label2 setIdentity:@"Title" ];
		[ label2 setTruncates:YES ];
		[ label2 setTextFont:[ NSFont boldSystemFontOfSize:[ NSFont systemFontSize ] ] ];
		[ label2 setText:title ];
		if ([ label2 frame ].height != 20)
		{
			addHeight += [ label2 frame ].height - 20;
			MDRect lfrm2 = [ label2 frame ];
			lfrm2.y += [ label2 frame ].height - 20;
			[ label2 setFrame:lfrm2 ];
		}
		[ label2 setTextAlignment:NSLeftTextAlignment ];
	}
	
	targetSize = NSMakeSize(420, 150 + addHeight);
	
	NSColor* color = [ NSColor colorWithCalibratedRed:0.929412 green:0.929412 blue:0.929412 alpha:0 ];
	MDWindow* window = [ MDWindow mdWindowWithFrame:MakeRect((resolution.width - targetSize.width) / 2, (resolution.height - targetSize.height) / 2, targetSize.width, targetSize.height) background:color ];
	[ window setIdentity:[ NSString stringWithFormat:@"Alert - %@", title ] ];
	[ window setCanResize:NO ];
	[ window setHasCloseButton:NO ];
	[ window setResizeSubviews:NO ];
	[ window setTarget:target ];
	[ window setAction:action ];
	[ window setVisible:NO ];
	
	if (message)
		[ window addSubView:label ];
	
	if (title)
		[ window addSubView:label2 ];
	
	MDImageView* image = [ [ MDImageView alloc ] initWithFrame:MakeRect(20, targetSize.height - 105, 60, 60) background:MD_IMAGEVIEW_DEFAULT_COLOR ];
	[ image setImageData:[ [ NSApp applicationIconImage ] TIFFRepresentation ] ];
	[ image setIdentity:@"Image" ];
	[ image setVisible:NO ];
	[ window addSubView:image ];
	
	if (defaultButton)
	{
		MDButton* button = [ [ MDButton alloc ] initWithFrame:MakeRect(targetSize.width - 90, 40, 70, 20) background:[ NSColor colorWithCalibratedRed:1 green:1 blue:1 alpha:0 ] ];
		[ button setIdentity:@"Default" ];
		//[ button setIsDefault:YES ];
		[ button setText:defaultButton ];
		[ button setVisible:NO ];
		[ button setTarget:[ MDWindow class ] ];
		[ button setAction:@selector(choiceChosen:) ];
		[ window addSubView:button ];
	}
	if (alternateButton)
	{
		MDButton* button = [ [ MDButton alloc ] initWithFrame:MakeRect(100, 40, 70, 20) background:[ NSColor colorWithCalibratedRed:1 green:1 blue:1 alpha:0 ] ];
		[ button setIdentity:@"Alternate" ];
		[ button setText:alternateButton ];
		[ button setVisible:NO ];
		[ button setTarget:[ MDWindow class ] ];
		[ button setAction:@selector(choiceChosen:) ];
		[ window addSubView:button ];
	}
	if (otherButton)
	{
		MDButton* button = [ [ MDButton alloc ] initWithFrame:MakeRect(targetSize.width - 175, 40, 70, 20) background:[ NSColor colorWithCalibratedRed:1 green:1 blue:1 alpha:0 ] ];
		[ button setIdentity:@"Other" ];
		[ button setText:otherButton ];
		[ button setVisible:NO ];
		[ button setTarget:[ MDWindow class ] ];
		[ button setAction:@selector(choiceChosen:) ];
		[ window addSubView:button ];
	}
	
	currentAlert = window;
	[ NSTimer scheduledTimerWithTimeInterval:1 / 60.0 target:[ MDWindow class ] selector:@selector(zoomIntro:) userInfo:nil repeats:YES ];
	return window;
}

