//
//  MDRadioButton.m
//  MovieDraw
//
//  Created by MILAP on 7/10/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MDRadioButton.h"
#import "MDButton.h"

void CreateRadioGroup(NSArray* members)
{
	for (int z = 0; z < [ members count ] - 1; z++)
	{
		for (int y = z + 1; y < [ members count ]; y++)
			[ (MDRadioButton*)[ members objectAtIndex:z ] addMember:[ members objectAtIndex:y ] ];
	}
}


@implementation MDRadioButton

+ (id) mdRadioButton
{
	MDRadioButton* view = [ [ [ MDRadioButton alloc ] init ] autorelease ];
	return view;
}

+ (id) mdRadioButtonWithFrame: (MDRect)rect background: (NSColor*)bkg;
{
	MDRadioButton* view = [ [ [ MDRadioButton alloc ] initWithFrame:rect
													 background:bkg ] autorelease ];
	return view;
}

- (id) init
{
	if ((self = [ super init ]))
	{
		members = [ [ NSMutableArray new ] retain ];
		checkColor = MD_RADIO_DEFAULT_CHECK_COLOR;
		verticies = (float*)malloc(sizeof(float) * 76);
		bverticies = (float*)malloc(sizeof(float) * 76);
		cverticies = (float*)malloc(sizeof(float) * 76);
		colors = (float*)malloc(sizeof(float) * 38 * 4);
		bcolors = (float*)malloc(sizeof(float) * 38 * 4);
		ccolors = (float*)malloc(sizeof(float) * 38 * 4);
		changed = TRUE;
		return self;
	}
	return nil;
}

- (id) initWithFrame: (MDRect)rect background: (NSColor*)bkg;
{
	if ((self = [ super initWithFrame:rect background:bkg ]))
	{
		if (frame.height != frame.width)
			frame.height = frame.width;
		members = [ [ NSMutableArray new ] retain ];
		checkColor = MD_RADIO_DEFAULT_CHECK_COLOR;
		verticies = (float*)malloc(sizeof(float) * 76);
		bverticies = (float*)malloc(sizeof(float) * 76);
		cverticies = (float*)malloc(sizeof(float) * 76);
		colors = (float*)malloc(sizeof(float) * 38 * 4);
		bcolors = (float*)malloc(sizeof(float) * 38 * 4);
		ccolors = (float*)malloc(sizeof(float) * 38 * 4);
		changed = TRUE;
		return self;
	}
	return nil;
}

- (void) setFrame:(MDRect)rect
{
	[ super setFrame:rect ];
	changed = TRUE;
	if (frame.height != frame.width)
		frame.height = frame.width;
}

- (void) setMembers: (NSArray*)mem
{
	if (members)
		[ members release ];
	members = [ [ NSMutableArray arrayWithArray:mem ] retain ];
}

- (void) addMember:(MDRadioButton*)mem
{
	[ members addObject:mem ];
	[ [ mem members ] addObject:self ];
}

- (NSMutableArray*) members
{
	return members;
}

- (void) setCheckColor:(NSColor*)color
{
	checkColor = color;
}

- (NSColor*) checkColor
{
	return checkColor;
}

- (void) setEnabled:(BOOL)en
{
	if (enabled != en)
		changed = TRUE;
	[ super setEnabled:en ];
}

- (void) mouseDown:(NSEvent *)event
{
	if (!visible || !enabled)
		return;
	
	NSPoint point = [ event locationInWindow ];
	point.x -= origin.x;
	point.y -= origin.y;
	point.x *= resolution.width / windowSize.width;
	point.y *= resolution.height / windowSize.height;
	point.y += 2;
	if ((point.x >= frame.x + frame.width && point.x <= frame.x + frame.width + [ glStr frameSize ].width && point.y >= frame.y && point.y <= frame.y + frame.height) || distanceB(NSMakePoint(frame.x + (frame.width / 2), frame.y + (frame.height / 2)), point) <= (frame.width / 2) + 1)
	{
		down = TRUE;
		realDown = TRUE;
		changed = TRUE;
	}
}

- (void) mouseDragged: (NSEvent*)event
{
	if (!visible || !enabled)
		return;
	
	BOOL lDown = down;
	
	down = FALSE;
	NSPoint point = [ event locationInWindow ];
	point.x -= origin.x;
	point.y -= origin.y;
	point.x *= resolution.width / windowSize.width;
	point.y *= resolution.height / windowSize.height;
	point.y += 2;
	if (realDown && ((point.x >= frame.x + frame.width && point.x <= frame.x + frame.width + [ glStr frameSize ].width &&
		 point.y >= frame.y && point.y <= frame.y + frame.height) || distanceB(NSMakePoint(frame.x + (frame.width / 2), frame.y + (frame.height / 2)), point) <= (frame.width / 2) + 1))
		down = TRUE;
	if (lDown != down)
		changed = TRUE;
}

- (void) mouseUp: (NSEvent*)event
{
	if (!visible || !enabled)
		return;

	NSPoint point = [ event locationInWindow ];
	point.x -= origin.x;
	point.y -= origin.y;
	point.x *= resolution.width / windowSize.width;
	point.y *= resolution.height / windowSize.height;
	point.y += 2;
	if ((point.x >= frame.x + frame.width && point.x <= frame.x + frame.width + [ glStr frameSize ].width &&
		 point.y >= frame.y && point.y <= frame.y + frame.height) || distanceB(NSMakePoint(frame.x + (frame.width / 2), frame.y + (frame.height / 2)), point) <= (frame.width / 2) + 1)
	{
		if (down && target != nil)
			[ target performSelector:action withObject:self ];
		if (down)
		{
			state = 1;
			for (int z = 0; z < [ members count ]; z++)
				[ (MDControl*)[ members objectAtIndex:z ] setState:0 ];
			changed = TRUE;
		}
	}
	if (down)
		changed = TRUE;
	down = FALSE;
	realDown = FALSE;
}

- (void) drawView
{
	if (!visible)
		return;
	
	if (lastState != state)
	{
		changed = TRUE;
		lastState = state;
	}
	
	if (changed)
	{
		memset(verticies, 0, 76);
		verticies[0] = frame.x + (frame.width / 2);
		verticies[1] = frame.y + (frame.height / 2);
		for (float i = 0; i < 36; i++)
		{
			float angle = (i * 10);
			float rad = (angle * M_PI / 180.0);
			verticies[((int)i * 2) + 2] = (frame.x + (frame.width / 2.0)) + (cos(rad) * (frame.width / 2));
			verticies[((int)i * 2) + 3] = (frame.y + (frame.height / 2.0)) + (sin(rad) * (frame.height / 2));
		}
		verticies[74] = frame.x + frame.width;
		verticies[75] = frame.y + (frame.height / 2);
		
		memset(bverticies, 0, 76);
		bverticies[0] = frame.x + (frame.width / 2);
		bverticies[1] = frame.y + (frame.height / 2);
		for (float i = 0; i < 36; i++)
		{
			float angle = (i * 10);
			float rad = (angle * M_PI / 180.0);
			bverticies[((int)i * 2) + 2] = (frame.x + (frame.width / 2.0)) + (cos(rad) * ((frame.width / 2) + 1.5));
			bverticies[((int)i * 2) + 3] = (frame.y + (frame.height / 2.0)) + (sin(rad) * ((frame.height / 2)  + 1.5));
		}
		bverticies[74] = frame.x + frame.width + 1.5;
		bverticies[75] = frame.y + (frame.height / 2);
		
		memset(cverticies, 0, 76);
		cverticies[0] = frame.x + (frame.width / 2);
		cverticies[1] = frame.y + (frame.height / 2);
		for (float i = 0; i < 36; i++)
		{
			float angle = (i * 10);
			float rad = (angle * M_PI / 180.0);
			cverticies[((int)i * 2) + 2] = (frame.x + (frame.width / 2.0)) + (cos(rad) * (frame.width / 5));
			cverticies[((int)i * 2) + 3] = (frame.y + (frame.height / 2.0)) + (sin(rad) * (frame.height / 5));
		}
		cverticies[74] = frame.x + (frame.width / 2) + (frame.width / 5);
		cverticies[75] = frame.y + (frame.height / 2);
		
		memset(colors, 0, 38 * 4);
		memset(bcolors, 0, 38 * 4);
		for (int z = 0; z < 38; z++)
		{
			float add = !enabled ? -0.3 : 0.0;
			
			NSColor* color = MD_BUTTON_DEFAULT_BUTTON_COLOR;
			if (down)
				add -= 0.15;
			if (state)
				color = MD_BUTTON_DEFAULT_DOWN_COLOR;
			colors[(z * 4)] = [ color redComponent ] + add;
			colors[(z * 4) + 1] = [ color greenComponent ] + add;
			colors[(z * 4) + 2] = [ color blueComponent ] + add;
			colors[(z * 4) + 3] = [ color alphaComponent ];
			
			NSColor* bcolor = MD_BUTTON_DEFAULT_BORDER_COLOR;
			if (state)
				bcolor = MD_BUTTON_DEFAULT_BORDER_COLOR2;
			bcolors[(z * 4)] = [ bcolor redComponent ] + add;
			bcolors[(z * 4) + 1] = [ bcolor greenComponent ] + add;
			bcolors[(z * 4) + 2] = [ bcolor blueComponent ] + add;
			bcolors[(z * 4) + 3] = [ bcolor alphaComponent ];
			
			NSColor* ccolor = MD_RADIO_DEFAULT_CHECK_COLOR;
			ccolors[(z * 4)] = [ ccolor redComponent ] + add;
			ccolors[(z * 4) + 1] = [ ccolor greenComponent ] + add;
			ccolors[(z * 4) + 2] = [ ccolor blueComponent ] + add;
			ccolors[(z * 4) + 3] = [ ccolor alphaComponent ];
		}
		
		changed = FALSE;
	}
	
	glLoadIdentity();
	
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_COLOR_ARRAY);
	
	glVertexPointer(2, GL_FLOAT, 0, bverticies);
	glColorPointer(4, GL_FLOAT, 0, bcolors);
	glDrawArrays(GL_TRIANGLE_FAN, 0, 38);
	
	glVertexPointer(2, GL_FLOAT, 0, verticies);
	glColorPointer(4, GL_FLOAT, 0, colors);
	glDrawArrays(GL_TRIANGLE_FAN, 0, 38);
	
	if (enabled)
	{
		glLoadIdentity();
		glTranslated(frame.x, frame.y + (frame.height / 2), 0);
		NSColor* color = MD_BUTTON_DEFAULT_BUTTON_COLOR;
		float add = 0;
		if (down)
			add -= 0.15;
		if (state)
			color = MD_BUTTON_DEFAULT_DOWN_COLOR;
		glBegin(GL_QUADS);
		{
			float minus = frame.height / 5;
			float minusWidth = frame.width * (1 - cos(18.0 * M_PI / 180.0));
			glColor4d([ color redComponent ] + add, [ color greenComponent ] + add, [ color blueComponent ] + add, [ color alphaComponent ]);
			glVertex2d(frame.width - minusWidth, (frame.height / 2) - minus);
			glVertex2d(minusWidth, (frame.height / 2) - minus);
			color = MD_BUTTON_DEFAULT_BUTTON_COLOR2;
			if (state)
				color = MD_BUTTON_DEFAULT_DOWN_COLOR2;
			glColor4d([ color redComponent ] + add, [ color greenComponent ] + add, [ color blueComponent ] + add, [ color alphaComponent ]);
			glVertex2d(0, 0);
			glVertex2d(frame.width, 0);
			
			glVertex2d(0, 0);
			glVertex2d(frame.width, 0);
			color = MD_BUTTON_DEFAULT_BUTTON_COLOR;
			if (state)
				color = MD_BUTTON_DEFAULT_DOWN_COLOR;
			glColor4d([ color redComponent ] + add, [ color greenComponent ] + add, [ color blueComponent ] + add, [ color alphaComponent ]);
			glVertex2d(frame.width - minusWidth, -(frame.height / 2) + minus);
			glVertex2d(minusWidth, -(frame.height / 2) + minus);
		}
		glEnd();
	}
	
	glLoadIdentity();
	if (state)
	{
		glVertexPointer(2, GL_FLOAT, 0, cverticies);
		glColorPointer(4, GL_FLOAT, 0, ccolors);
		glDrawArrays(GL_TRIANGLE_FAN, 0, 38);
	}
	
	glDisableClientState(GL_VERTEX_ARRAY);
	glDisableClientState(GL_COLOR_ARRAY);
	
	if (text != nil && [ text length ] != 0)
	{
		float add = !enabled ? -0.3 : 0.0;
		if (!glStr)
		{
			glStr = LoadString([ NSString stringWithFormat:@"%@", text ],
							   [ NSColor colorWithCalibratedRed:[ textColor redComponent ] + add green:
								[ textColor greenComponent ] + add blue:[ textColor blueComponent ] + add
														  alpha:[ textColor alphaComponent ] ], textFont);
		}
		DrawString(glStr, NSMakePoint(frame.x + frame.width,
									  frame.y + (frame.height / 2)), NSLeftTextAlignment, 0);
	}
	
	if (continuous && down && target != nil && [ target respondsToSelector:action ] &&
		(fpsCounter % ccount) == 0)
		[ target performSelector:action ];
	fpsCounter++;
	if (fpsCounter >= 3600)
		fpsCounter -= 3600;
}

- (void) dealloc
{
	if (members)
	{
		[ members release ];
		members = nil;
	}
	if (verticies)
	{
		free(verticies);
		verticies = NULL;
	}
	if (bverticies)
	{
		free(bverticies);
		bverticies = NULL;
	}
	if (cverticies)
	{
		free(cverticies);
		cverticies = NULL;
	}
	if (colors)
	{
		free(colors);
		colors = NULL;
	}
	if (bcolors)
	{
		free(bcolors);
		bcolors = NULL;
	}
	if (ccolors)
	{
		free(ccolors);
		ccolors = NULL;
	}
	[ super dealloc ];
}

@end
