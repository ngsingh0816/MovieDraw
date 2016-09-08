//
//  MDCheckBox.m
//  MovieDraw
//
//  Created by MILAP on 7/10/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MDCheckBox.h"


@implementation MDCheckBox

+ (id) mdCheckBox
{
	MDCheckBox* view = [ [ [ MDCheckBox alloc ] init ] autorelease ];
	return view;
}

+ (id) mdCheckBoxWithFrame: (MDRect)rect background: (NSColor*)bkg;
{
	MDCheckBox* view = [ [ [ MDCheckBox alloc ] initWithFrame:rect
											 background:bkg ] autorelease ];
	return view;
}

- (id) init
{
	if ((self = [ super init ]))
	{
		checkColor = MD_CHECKBOX_DEFAULT_CHECK_COLOR;
		verticies = (float*)malloc(sizeof(float) * 82);
		bverticies = (float*)malloc(sizeof(float) * 82);
		colors = (float*)malloc(sizeof(float) * 41 * 4);
		bcolors = (float*)malloc(sizeof(float) * 41 * 4);
		changed = TRUE;
		return self;
	}
	return nil;
}

- (id) initWithFrame: (MDRect)rect background: (NSColor*)bkg;
{
	if ((self = [ super initWithFrame:rect background:bkg ]))
	{
		checkColor = MD_CHECKBOX_DEFAULT_CHECK_COLOR;
		verticies = (float*)malloc(sizeof(float) * 82);
		bverticies = (float*)malloc(sizeof(float) * 82);
		colors = (float*)malloc(sizeof(float) * 41 * 4);
		bcolors = (float*)malloc(sizeof(float) * 41 * 4);
		changed = TRUE;
		return self;
	}
	return nil;
}

- (void) setFrame:(MDRect)rect
{
	changed = TRUE;
	[ super setFrame:rect ];
}

- (void) setEnabled:(BOOL)en
{
	if (enabled != en)
		changed = TRUE;
	[ super setEnabled:en ];
}

- (void) setState:(int)nstate
{
	if (state != nstate)
		changed = TRUE;
	[ super setState:nstate ];
}

- (void) mouseDown: (NSEvent*)event
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
	point.y += 2;
	
	BOOL isDown = FALSE;
	if (point.x >= (frame.x + 3.5) && point.x <= (frame.x + frame.width - 3.5) &&
		point.y >= frame.y && point.y <= frame.y + frame.height)
		isDown = TRUE;
	else if (point.x >= frame.x && point.x <= frame.x + frame.width &&
			 point.y >= frame.y + 3.5 && point.y <= frame.y + frame.height - 3.5)
		isDown = TRUE;
	else if (point.x >= frame.x + frame.width && point.x <= frame.x + frame.width + [ glStr frameSize ].width &&
			 point.y >= frame.y && point.y <= frame.y + frame.height)
		isDown = TRUE;
	else
	{
		NSPoint centers[4] = { NSMakePoint(frame.x + 3.5, frame.y + 3.5), NSMakePoint(frame.x + frame.width - 3.5, frame.y + 3.5), NSMakePoint(frame.x + frame.width - 3.5, frame.y + frame.height - 3.5), NSMakePoint(frame.x + 3.5, frame.y + frame.height - 3.5) };
		for (int z = 0; z < 4; z++)
		{
			float dist = distanceB(centers[z], point);
			if (dist <= 3.5)
			{
				isDown = TRUE;
				break;
			}
		}
		
	}
	
	if (isDown)
	{
		down = TRUE;
		up = FALSE;
		realDown = TRUE;
		if (continuous && target != nil)
			[ target performSelector:action withObject:self ];
		changed = TRUE;
	}
}

- (void) mouseDragged: (NSEvent*)event
{
	if (!visible || !enabled)
		return;
	
	BOOL lDown = down;
	
	if (text && textFont && glStr)
		frame.width += [ glStr frameSize ].width;

	[ super mouseDragged:event ];
	
	if (down != lDown)
		changed = TRUE;
	
	if (text && textFont && glStr)
		frame.width -= [ glStr frameSize ].width;
}

- (void) mouseUp: (NSEvent*)event
{
	if (!visible || !enabled)
		return;
	
	if (text && textFont && glStr)
		frame.width += [ glStr frameSize ].width;

	NSPoint point = [ event locationInWindow ];
	point.x -= origin.x;
	point.y -= origin.y;
	point.x *= resolution.width / windowSize.width;
	point.y *= resolution.height / windowSize.height;
	if (point.x >= frame.x && point.x <= frame.x + frame.width &&
		point.y >= frame.y && point.y <= frame.y + frame.height)
	{
		if (down && target != nil)
			[ target performSelector:action withObject:self ];
		if (down)
		{
			state = !state;
			changed = TRUE;
		}
	}
	if (realDown)
		changed = TRUE;
	down = FALSE;
	realDown = FALSE;
	
	if (text && textFont && glStr)
		frame.width -= [ glStr frameSize ].width;
}

- (void) setCheckColor: (NSColor*)color
{
	checkColor = color;
}

- (NSColor*) checkColor
{
	return checkColor;
}

- (void) drawView
{
	if (!visible)
		return;
	
	if (changed)
	{
		memset(verticies, 0, 82);
		verticies[0] = frame.x + 3.5;
		verticies[1] = frame.y + frame.height;
		for (int i = 0; i <= 18; i += 2)
		{
			float angle = (i * 5);
			float rad = (M_PI * angle / 180.0);
			verticies[2 + i] = ((frame.x + frame.width - 3.5) + (sin(rad) * 3.5));
			verticies[3 + i] = ((frame.y + frame.height - 3.5) + (cos(rad) * 3.5));
		}
		for (int i = 0; i <= 18; i += 2)
		{
			float angle = (i * 5);
			float rad = (M_PI * angle / 180.0);
			verticies[22 + i] = ((frame.x + frame.width - 3.5) + (cos(rad) * 3.5));
			verticies[23 + i] = ((frame.y + 3.5) - (sin(rad) * 3.5));
		}
		for (int i = 0; i <= 18; i += 2)
		{
			float angle = (i * 5);
			float rad = (M_PI * angle / 180.0);
			verticies[42 + i] = ((frame.x + 3.5) - (sin(rad) * 3.5));
			verticies[43 + i] = ((frame.y + 3.5) - (cos(rad) * 3.5));
		}
		for (int i = 0; i <= 18; i += 2)
		{
			float angle = (i * 5);
			float rad = (M_PI * angle / 180.0);
			verticies[62 + i] = ((frame.x + 3.5) - (cos(rad) * 3.5));
			verticies[63 + i] = ((frame.y + frame.height - 3.5) + (sin(rad) * 3.5));
		}
		
		
		float lane = 2.5;
		memset(bverticies, 0, 82);
		bverticies[0] = frame.x + lane;
		bverticies[1] = frame.y + frame.height + 1;
		for (int i = 0; i <= 18; i += 2)
		{
			float angle = (i * 5);
			float rad = (M_PI * angle / 180.0);
			bverticies[2 + i] = ((frame.x + frame.width - lane) + (sin(rad) * 3.5));
			bverticies[3 + i] = ((frame.y + frame.height - lane) + (cos(rad) * 3.5));
		}
		for (int i = 0; i <= 18; i += 2)
		{
			float angle = (i * 5);
			float rad = (M_PI * angle / 180.0);
			bverticies[22 + i] = ((frame.x + frame.width - lane) + (cos(rad) * 3.5));
			bverticies[23 + i] = ((frame.y + lane) - (sin(rad) * 3.5));
		}
		for (int i = 0; i <= 18; i += 2)
		{
			float angle = (i * 5);
			float rad = (M_PI * angle / 180.0);
			bverticies[42 + i] = ((frame.x + lane) - (sin(rad) * 3.5));
			bverticies[43 + i] = ((frame.y + lane) - (cos(rad) * 3.5));
		}
		for (int i = 0; i <= 18; i += 2)
		{
			float angle = (i * 5);
			float rad = (M_PI * angle / 180.0);
			bverticies[62 + i] = ((frame.x + lane) - (cos(rad) * 3.5));
			bverticies[63 + i] = ((frame.y + frame.height - lane) + (sin(rad) * 3.5));
		}
		
		for (int z = 0; z < 41; z++)
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
		}
		
		changed = FALSE;
	}
	
	glLoadIdentity();
	
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_COLOR_ARRAY);
	
	glVertexPointer(2, GL_FLOAT, 0, bverticies);
	glColorPointer(4, GL_FLOAT, 0, bcolors);
	glDrawArrays(GL_TRIANGLE_FAN, 0, 41);
	
	glVertexPointer(2, GL_FLOAT, 0, verticies);
	glColorPointer(4, GL_FLOAT, 0, colors);
	
	// Draw
	glDrawArrays(GL_TRIANGLE_FAN, 0, 41);
	
	glLoadIdentity();
	glTranslated(frame.x, frame.y + (frame.height / 2) - 0.5, 0);
	NSColor* color = MD_BUTTON_DEFAULT_BUTTON_COLOR;
	float add = 0;
	if (down)
		add -= 0.15;
	if (state)
		color = MD_BUTTON_DEFAULT_DOWN_COLOR;
	glBegin(GL_QUADS);
	{
		glColor4d([ color redComponent ] + add, [ color greenComponent ] + add, [ color blueComponent ] + add, [ color alphaComponent ]);
		glVertex2d(frame.width, (frame.height / 2) - 3);
		glVertex2d(0, (frame.height / 2) - 3);
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
		glVertex2d(frame.width, -(frame.height / 2) + 4);
		glVertex2d(0, -(frame.height / 2) + 4);
	}
	glEnd();
	
	glDisableClientState(GL_VERTEX_ARRAY);
	glDisableClientState(GL_COLOR_ARRAY);
	
	if (state)
	{
		glLoadIdentity();
		glTranslated(frame.x, frame.y, 0);
		glColor4d([ checkColor redComponent ], [ checkColor greenComponent ], [ checkColor blueComponent ], [ checkColor alphaComponent ]);
		glLineWidth(2.5);
		glBegin(GL_LINES);
		{
			glVertex2d((frame.width * 3 / 14), (frame.height * 10 / 14));
			//glVertex2d(frame.width * 2 / 7, (frame.height * 11 / 14));
			//glVertex2d(frame.width / 2, (frame.height / 2) - 1);
			glVertex2d(frame.width / 2, (frame.height * 4 / 14));
			
			glVertex2d(frame.width / 2, (frame.height * 4 / 14));
			glVertex2d(frame.width * 14 / 14, frame.height * 17 / 14);
		}
		glEnd();
		glLineWidth(1);
	}
	
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
	
	[ super dealloc ];
}

@end
