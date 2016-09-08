//
//  MDToolbar.m
//  MovieDraw
//
//  Created by MILAP on 7/22/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MDToolbar.h"
#import "MDToolbarItem.h"

@interface MDToolbar (InternalMethods)
- (void) checkShow;
@end

@implementation MDToolbar

+ (instancetype) mdToolbar
{
	MDToolbar* view = [ [ MDToolbar alloc ] init  ];
	return view;
}

+ (instancetype) mdToolbarWithFrame: (MDRect)rect background: (NSColor*)bkg
{
	MDToolbar* view = [ [ MDToolbar alloc ] initWithFrame:rect background:bkg ];
	return view;
}

- (instancetype) init
{
	if ((self = [ super init ]))
	{
		shown = FALSE;
		titems = [ [ NSMutableArray alloc ] init ];
		speed = 2.0;
		height = 0;
		changing = 0;
		drawTri = YES;
		flags = 0;
	}
	return self;
}

- (instancetype) initWithFrame: (MDRect)rect background: (NSColor*)bkg
{
	if ((self = [ super initWithFrame:rect background:bkg ]))
	{
		shown = FALSE;
		titems = [ [ NSMutableArray alloc ] init ];
		speed = frame.width / 200.0;
		height = 0;
		changing = 0;
		drawTri = YES;
		flags = 0;
	}
	return self;
}

- (BOOL) shown
{
	return shown;
}

- (void) setShown: (BOOL) set
{
	shown = set;
	changing = false;
	for (int z = 0; z < [ titems count ]; z++)
	{
		if (shown)
		{
			if ([ (MDControlView*)titems[z] frame ].x +
			[ (MDControlView*)titems[z] frame ].width >= 
			frame.x + frame.width - (frame.height / 2))
				break;
		}
		[ titems[z] setVisible:shown ];
	}
	if (!shown)
		flags &= ~(1 | (1 << 1));
}

- (NSMutableArray*) items
{
	return titems;
}

- (void) setItems: (NSArray*) array
{
	if (titems)
	{
		[ titems removeAllObjects ];
		[ titems setArray:array ];
	}
	else
		titems = [ [ NSMutableArray alloc ] initWithArray:array ];
}

- (void) setBackground: (NSColor*)bkg
{
	[ super setBackground:bkg ];
	if (titems)
	{
		for (int z = 0; z < [ titems count ]; z++)
			[ titems[z] setBackground:bkg ];
	}
}

- (void) setRed: (float)red
{
	[ super setRed:red ];
	for (int z = 0; z < [ titems count ]; z++)
		[ titems[z] setRed:red ];
}

- (void) setGreen: (float)green
{
	[ super setGreen:green ];
	for (int z = 0; z < [ titems count ]; z++)
		[ titems[z] setGreen:green ];
}

- (void) setBlue: (float)blue
{
	[ super setBlue:blue ];
	for (int z = 0; z < [ titems count ]; z++)
		[ titems[z] setBlue:blue ];
}

- (void) setAlpha: (float)alpha
{
	[ super setAlpha:alpha ];
	for (int z = 0; z < [ titems count ]; z++)
		[ (MDToolbarItem*)titems[z] setAlpha:alpha ];
}

- (BOOL) mouseDown
{
	if (!visible || !enabled)
		return FALSE;
	if (!shown)
		return FALSE;
	return ((flags >> 3) & 0x1);
}

- (void) setDrawTriangle:(BOOL) drw
{
	drawTri = drw;
}

- (BOOL) drawTriangle
{
	return drawTri;
}

- (void) checkShow
{
	if (!visible || !enabled)
		return;
	
	if (((flags >> 1) & 0x1) || ([ views count ] != (1 + [ titems count ]))	)
		return;
	NSPoint point = [ NSEvent mouseLocation ];
	point.x -= origin.x;
	point.y -= origin.y;
	point.x *= resolution.width / windowSize.width;
	point.y *= resolution.height / windowSize.height;
	if (![ [ [ NSApp mainWindow ] contentView ] isInFullScreenMode ])
	{
		NSRect rect = [ [ NSApp mainWindow ] frame ];
		point.x -= rect.origin.x;
		point.y -= rect.origin.y;
	}
	bool should = shown ? NO : YES;
	if ((point.x >= frame.x && point.x <= frame.x + frame.width &&
		point.y >= frame.y && point.y <= frame.y + frame.height) == should)
	{
		shown = !shown;
		if (changing == 0)
		{
			if (shown)
			{
				changing = 1;
				height = 0;
			}
			else
			{
				changing = -1;
				height = frame.height;
			}
		}
		else
			changing = shown ? 1 : -1;
		
		MDRect fakeFrame = MakeRect(frame.x + frame.width - (frame.height / 2),
									frame.y + (frame.height / 4),
									frame.x + frame.width - (frame.height / 10),
									frame.y + (frame.height * 0.75));
		if (titems && changing != 1)
		{
			for (int z = 0; z < [ titems count ]; z++)
			{
				if (shown)
				{
					if ([ (MDControlView*)titems[z] frame ].x +
					[ (MDControlView*)titems[z] frame ].width >= fakeFrame.x)
						break;
				}
				[ titems[z] setVisible:shown ];
			}
		}
	}
	flags &= 0xFE; // checking
}

- (void) mouseMoved:(NSEvent*)event
{
	if (!visible || !enabled)
		return;
	
	if (flags & 0x1)	// checking
		return;
	bool should = shown ? NO : YES;
	NSPoint point = [ event locationInWindow ];
	point.x -= origin.x;
	point.y -= origin.y;
	point.x *= resolution.width / windowSize.width;
	point.y *= resolution.height / windowSize.height;
	if (((point.x >= frame.x && point.x <= frame.x + frame.width &&
		point.y >= frame.y && point.y <= frame.y + frame.height) == should) &&
		[ views count ] == (1 + [ titems count ]))
	{
		[ NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(checkShow)
										userInfo:nil repeats:NO ];
		flags |= 0x1;
	}
}

- (void) mouseDown:(NSEvent*)event
{
	if (!visible || !enabled)
		return;
	
	NSPoint point = [ event locationInWindow ];
	point.x -= origin.x;
	point.y -= origin.y;
	point.x *= resolution.width / windowSize.width;
	point.y *= resolution.height / windowSize.height;
	lastMouse = point;
	
	down = FALSE;
	up = TRUE;
	if (point.x >= frame.x && point.x <= frame.x + frame.width &&
		point.y >= frame.y && point.y <= frame.y + frame.height)
	{
		down = TRUE;
		realDown = TRUE;
		flags |= (1 << 3);
		up = FALSE;
		left = 20;
	}
}

- (void) mouseDragged:(NSEvent*)event
{
	if (!visible || !enabled)
		return;
	
	if (!shown || up)
		return;
		
	NSPoint point = [ event locationInWindow ];
	point.x -= origin.x;
	point.y -= origin.y;
	point.x *= resolution.width / windowSize.width;
	point.y *= resolution.height / windowSize.height;
	if (!(point.x >= frame.x && point.x <= frame.x + frame.width &&
		point.y >= frame.y && point.y <= frame.y + frame.height))
	{
		lastMouse = point;
		down = FALSE;
		return;
	}
	MDRect fakeFrame = MakeRect(frame.x + frame.width - (drawTri ? 20 : 0),
								frame.y + (frame.height / 4),
								frame.x + frame.width - 5, frame.y + (frame.height * 0.75));
	if (point.x >= fakeFrame.x && point.x <= fakeFrame.x + fakeFrame.width &&
		point.y >= fakeFrame.y && point.y <= fakeFrame.y + fakeFrame.height)
	{
		lastMouse = point;
		return;
	}
	float translate = point.x - lastMouse.x;
	float width = 0;
	if (left != 0)
	{
		if (translate < 0)
		{
			left += translate;
			if (left < 0)
				left = 0;
			lastMouse = point;
			down = FALSE;
			return;
		}
		else if (translate >= 0)
		{
			left -= translate;
			if (left < 0)
				left = 0;
			lastMouse = point;
			down = FALSE;
			return;
		}
	}
	for (int z = 0; z < [ titems count ]; z++)
		width += [ (MDToolbarItem*)titems[z] frame ].width;
	if (([ (MDToolbarItem*)[ titems lastObject ] frame ].x < frame.x) && translate >= 0)
	{
		lastMouse = point;
		down = FALSE;
		return;
	}
	else if (([ (MDToolbarItem*)[ titems lastObject ] frame ].x +
			 [ (MDToolbarItem*)[ titems lastObject ] frame ].width <=
			 frame.x + frame.width - (drawTri ? 20 : 0))
			 && [ (MDToolbarItem*)[ titems lastObject ]
			visible ] && translate >= 0 && width > frame.width)
	{
		lastMouse = point;
		down = FALSE;
		left = 20;
		return;
	}
	else if (([ (MDToolbarItem*)titems[0] frame ].x > frame.x + 10)
			 && translate < 0 && [ (MDToolbarItem*)titems[0] visible ])
	{
		lastMouse = point;
		down = FALSE;
		return;
	}
	lastMouse = point;
	down = FALSE;
	
	if ([ titems count ] != 0)
	{
		MDRect rect = [ (MDToolbarItem*)[ titems lastObject ] frame ];
		if (rect.x - translate < frame.x)
			return;
	}
	for (int z = 0; z < [ titems count ]; z++)
	{
		MDRect rect = [ (MDToolbarItem*)titems[z] frame ];
		
		rect.x -= translate;
		[ (MDToolbarItem*)titems[z] setFrame:rect ];
		if (rect.x + rect.width >= frame.x + frame.width - (drawTri ? 20 : 0) ||
			rect.x + rect.width < frame.x)
			[ (MDToolbarItem*)titems[z] setVisible:NO ];
		else
			[ (MDToolbarItem*)titems[z] setVisible:YES ];
	}
}

- (void) mouseUp:(NSEvent*)event
{
	if (!visible || !enabled)
		return;
	
	MDRect fakeFrame = MakeRect(frame.x + frame.width - (frame.height / 2),
								frame.y + (frame.height / 4),
								frame.x + frame.width - (frame.height / 10),
								frame.y + (frame.height * 0.75));
	NSPoint point = [ event locationInWindow ];
	point.x -= origin.x;
	point.y -= origin.y;
	point.x *= resolution.width / windowSize.width;
	point.y *= resolution.height / windowSize.height;
	if (point.x >= fakeFrame.x && point.x <= fakeFrame.x + fakeFrame.width &&
		point.y >= fakeFrame.y && point.y <= fakeFrame.y + fakeFrame.height)
	{
		if (down && target != nil && drawTri)
			((void (*)(id, SEL, id))[ target methodForSelector:action ])(target, action, self);
		if (down && drawTri)
		{
			shown = !shown;
			flags &= ~(1 | (1 << 1));
			flags |= shown | (shown << 1);
			if (changing == 0)
			{
				if (shown)
				{
					changing = 1;
					height = 0;
				}
				else
				{
					changing = -1;
					height = frame.height;
				}
			}
			else
				changing = shown ? 1 : -1;
			if (titems && changing != 1)
			{
				for (int z = 0; z < [ titems count ]; z++)
				{
					if (shown)
					{
						if ([ (MDControlView*)titems[z] frame ].x +
							[ (MDControlView*)titems[z] frame ].width >=
							fakeFrame.x)
							break;
					}
					[ titems[z] setVisible:shown ];
				}
			}
		}
	}
	up = TRUE;
	down = FALSE;
	realDown = FALSE;
	flags &= ~(1 << 3);
}

- (void) addItem: (NSString*)str image:(NSString*)path target:(id)tar action:(SEL)sel
{
	MDRect lastFrame = MakeRect(frame.x + speed, frame.y, 
							  frame.height, frame.height);
	if (!titems)
		titems = [ [ NSMutableArray alloc ] init ];
	else if ([ titems count ] != 0)
	{
		lastFrame = [ (MDToolbarItem*)[ titems lastObject ] frame ];
		lastFrame.x += lastFrame.width;
	}
	
	float width = frame.height;
	MDToolbarItem* item = [ [ MDToolbarItem alloc ] initWithFrame:
			MakeRect(lastFrame.x, frame.y, frame.height, frame.height)
													   background:background ];
	[ item setImagePath:(char*)[ path UTF8String ] length:0 ];
	[ item setText:str ];
	if ([ [ item glStr ] frameSize ].width > width)
	{
		width = [ [ item glStr ] frameSize ].width;
		[ item setFrame:MakeRect(lastFrame.x, frame.y, width, frame.height) ];
	}
	[ item setTarget:tar ];
	[ item setAction:sel ];
	if (lastFrame.x + width >= frame.x + frame.width - (drawTri ? 20 : 0))
		[ item setVisible:NO ];
	else
		[ item setVisible:shown ];
	[ item setParentView:self ];
	
	[ titems addObject:item ];
}

- (float) moveSpeed
{
	return speed;
}

- (void) setMoveSpeed: (float) spd
{
	speed = spd;
}

- (void) setEnabled: (BOOL) en
{
	[ super setEnabled:en ];
	for (int z = 0; z < [ titems count ]; z++)
		[ (MDToolbarItem*)titems[z] setEnabled:en ];
}

- (void) setVisible: (BOOL)vis
{
	[ super setVisible:vis ];
	shown = false;
}

- (void) drawView
{
	if (!visible)
		return;
	
	glLoadIdentity();
	if (!shown && changing == 0)
	{
		if (drawTri)
		{
			float square[6];
			square[0] = frame.x + frame.width - (((frame.height / 10) +
												  (frame.height / 2)) / 2);
			square[1] = frame.y + (frame.height / 4);
			square[2] = frame.x + frame.width - (frame.height / 10);
			square[3] = frame.y + (frame.height * 0.75);
			square[4] = frame.x + frame.width - (frame.height / 2);
			square[5] = frame.y + (frame.height * 0.75);
			float colors[12];
			for (int z = 0; z < 3; z++)
			{
				float add = !enabled ? -0.3 : 0.0;
				colors[(z * 4)] = [ background redComponent ] + add;
				colors[(z * 4) + 1] = [ background greenComponent ] + add;
				colors[(z * 4) + 2] = [ background blueComponent ] + add;
				colors[(z * 4) + 3] = [ background alphaComponent ];
			}
		
			glVertexPointer(2, GL_FLOAT, 0, square);
			glEnableClientState(GL_VERTEX_ARRAY);
			glColorPointer(4, GL_FLOAT, 0, colors);
			glEnableClientState(GL_COLOR_ARRAY);
		
			// Draw
			glDrawArrays(GL_TRIANGLES, 0, 3);
		
			glDisableClientState(GL_VERTEX_ARRAY);
			glDisableClientState(GL_COLOR_ARRAY);
		}
	}
	else if (changing == 0)
	{
		[ super drawView ];
		if (up)
		{
			for (int y = 0; y < [ titems count ]; y++)
			{
				if ([ (MDToolbarItem*)titems[y] frame ].x < frame.x + speed
					&& [ (MDToolbarItem*)titems[y] visible ])
				{
					float width = 0;
					for (int z = 0; z < [ titems count ]; z++)
					{
						width += [ (MDToolbarItem*)titems[z] 
								   frame ].width;
					}
					if (width > frame.width &&
						[ (MDToolbarItem*)[ titems lastObject ] visible ] &&
						([ (MDToolbarItem*)[ titems lastObject ] frame ].x +
						 [ (MDToolbarItem*)[ titems lastObject ] frame ].width <=
						  frame.x + frame.width - (drawTri ? 20 : 0)))
						break;
					for (int z = 0; z < [ titems count ]; z++)
					{
						MDRect rect = [ (MDToolbarItem*)titems[z] frame ];
						rect.x += speed;
						[ (MDToolbarItem*)titems[z] setFrame:rect ];
						if (width <= frame.width)
							[ (MDToolbarItem*)titems[z] setVisible:YES ];
						else if (rect.x + rect.width >= frame.x + frame.width -
								 (drawTri ? 20 : 0))
							[ (MDToolbarItem*)titems[z] setVisible:NO ];
					}
					break;
				}
			}
			if ([ titems count ] != 0 && [ (MDToolbarItem*)
						titems[0] frame ].x > frame.x + speed)
			{
				for (int z = 0; z < [ titems count ]; z++)
				{
					MDRect rect = [ (MDToolbarItem*)titems[z] frame ];
					rect.x -= speed;
					[ (MDToolbarItem*)titems[z] setFrame:rect ];
					if (rect.x + rect.width <= frame.x + frame.width - (drawTri ? 20 : 0))
						[ (MDToolbarItem*)titems[z] setVisible:YES ];
					else
						[ (MDToolbarItem*)titems[z] setVisible:NO ];
				}
			}
		}
		
		if (drawTri)
		{
			float square[6];
			square[0] = frame.x + frame.width - (frame.height / 10);
			square[1] = frame.y + (frame.height / 4);
			square[2] = frame.x + frame.width - (frame.height / 2);
			square[3] = frame.y + (frame.height / 4);
			square[4] = frame.x + frame.width - (((frame.height / 10) +
												  (frame.height / 2)) / 2);
			square[5] = frame.y + (frame.height  * 0.75);
			float colors[12];
			for (int z = 0; z < 3; z++)
			{
				float add = !enabled ? -0.3 : 0.0;
				colors[(z * 4)] = [ background redComponent ] + 0.07 + add;
				colors[(z * 4) + 1] = [ background greenComponent ] + 0.07 + add;
				colors[(z * 4) + 2] = [ background blueComponent ] + 0.07 + add;
				colors[(z * 4) + 3] = [ background alphaComponent ];
			}
			
			glVertexPointer(2, GL_FLOAT, 0, square);
			glEnableClientState(GL_VERTEX_ARRAY);
			glColorPointer(4, GL_FLOAT, 0, colors);
			glEnableClientState(GL_COLOR_ARRAY);
			
			// Draw
			glDrawArrays(GL_TRIANGLES, 0, 3);
			
			glDisableClientState(GL_VERTEX_ARRAY);
			glDisableClientState(GL_COLOR_ARRAY);
		}
	}
	else if (changing != 0)
	{
		if (changing == 1)
			height += frame.height / 30.0;
		else
			height -= frame.height / 30.0;
		
		float prev = frame.height;
		frame.height = height;
		
		float tsquare[8];
		tsquare[0] = frame.x;
		tsquare[1] = frame.y;
		tsquare[2] = frame.x + frame.width;
		tsquare[3] = frame.y;
		tsquare[4] = frame.x;
		tsquare[5] = frame.y + frame.height;
		tsquare[6] = frame.x + frame.width;
		tsquare[7] = frame.y + frame.height;
		
		float tcolors[16];
		for (int z = 0; z < 4; z++)
		{
			float add = !enabled ? -0.3 : 0.0;
			tcolors[(z * 4)] = [ background redComponent ] + add;
			tcolors[(z * 4) + 1] = [ background greenComponent ] + add;
			tcolors[(z * 4) + 2] = [ background blueComponent ] + add;
			tcolors[(z * 4) + 3] = [ background alphaComponent ];
		}
		
		glLoadIdentity();
		glVertexPointer(2, GL_FLOAT, 0, tsquare);
		glEnableClientState(GL_VERTEX_ARRAY);
		glColorPointer(4, GL_FLOAT, 0, tcolors);
		glEnableClientState(GL_COLOR_ARRAY);
		
		// Draw
		glTranslated(frame.x + (frame.width / 2), frame.y + (prev / 2), 0);
		glRotated(180, 0, 0, 1);
		glTranslated(-(frame.x + (frame.width / 2)), -(frame.y + (prev / 2)), 0);
		glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
		
		glDisableClientState(GL_VERTEX_ARRAY);
		glDisableClientState(GL_COLOR_ARRAY);
		glLoadIdentity();
		
		frame.height = prev;
		
		if ((height >=  frame.height - 1 && height <= frame.height + 1)
			|| (height <= 1 && height >= -1))
		{
			changing = 0;
			for (int z = 0; z < [ titems count ]; z++)
			{
				if ([ (MDControlView*)titems[z] frame ].x +
					[ (MDControlView*)titems[z] frame ].width >=
					frame.x + frame.width - (drawTri ? 20 : 0))
					break;
				[ titems[z] setVisible:shown ];
			}
		}
	}
}

@end
