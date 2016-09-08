//
//  MDProgressBar.mm
//  MovieDraw
//
//  Created by MILAP on 12/29/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MDProgressBar.h"

#define PART_WIDTH		15	// Maybe 16?


@implementation MDProgressBar

+ (MDProgressBar*) mdProgressBar
{
	return [ [ [ MDProgressBar alloc ] init ] autorelease ];
}

+ (MDProgressBar*) mdProgressBarWithFrame: (MDRect)rect background:(NSColor*)bkg
{
	return [ [ [ MDProgressBar alloc ] initWithFrame:rect background:bkg ] autorelease ];
}

- (id) init
{
	if ((self = [ super init ]))
	{
		background[1] = [ MD_PROGRESS_DEFAULT_BKG2 retain ];
		minValue = 0;
		maxValue = 100;
		currentValue = 0;
		otherColor = [ [ NSColor greenColor ] retain ];
		rotation = 0;
		speed = 12.5;
		width1 = 20;
		width2 = 20;
		
		verticies = (float*)malloc(sizeof(float) * 82);
		bverticies = (float*)malloc(sizeof(float) * 82);
		colors = (float*)malloc(sizeof(float) * 41 * 4);
		bcolors = (float*)malloc(sizeof(float) * 41 * 4);
		changed = TRUE;
	}
	return self;
}

- (id) initWithFrame:(MDRect)rect background:(NSColor *)bkg
{
	if ((self = [ super initWithFrame:rect background:bkg ]))
	{
		background[1] = [ MD_PROGRESS_DEFAULT_BKG2 retain ];
		minValue = 0;
		maxValue = 100;
		currentValue = 0;
		otherColor = [ [ NSColor greenColor ] retain ];
		rotation = 0;
		speed = 12.5;
		width1 = 20;
		width2 = 20;
		
		verticies = (float*)malloc(sizeof(float) * 82);
		bverticies = (float*)malloc(sizeof(float) * 82);
		colors = (float*)malloc(sizeof(float) * 41 * 4);
		bcolors = (float*)malloc(sizeof(float) * 41 * 4);
		changed = TRUE;
	}
	return self;
}

- (void) setFrame:(MDRect)rect
{
	[ super setFrame:rect ];
	changed = TRUE;
}

- (void) setType: (MDProgressBarType)ty
{
	type = ty;
	if (type == MD_PROGRESSBAR_SPIN)
	{
		if ([ otherColor isEqualTo:[ NSColor greenColor ] ])
		{
			[ otherColor release ];
			otherColor = [ [ NSColor colorWithCalibratedRed:0 green:0 blue:0 
													  alpha:0 ] retain ];
		}
	}
	changed = TRUE;
}

- (MDProgressBarType) type
{
	return type;
}

- (void) setMinValue: (float)min
{
	minValue = min;
}

- (float) minValue
{
	return minValue;
}

- (void) setMaxValue: (float)max
{
	maxValue = max;
}

- (float) maxValue
{
	return maxValue;
}

- (void) setCurrentValue: (float)value
{
	if (value > maxValue)
		currentValue = maxValue;
	else
		currentValue = value;
	changed = TRUE;
}

- (float) currentValue
{
	return currentValue;
}

- (void) setOtherColor: (NSColor*)color
{
	if (otherColor)
		[ otherColor release ];
	otherColor = [ color retain ];
}

- (NSColor*) otherColor
{
	return otherColor;
}

- (void) setSpeed: (float)sped
{
	speed = sped;
}

- (float) speed
{
	return speed;
}

- (void) setWidth1: (float)width
{
	width1 = width;
	if (width1 == 0)
		width1 = 1;
}

- (float) width1
{
	return width1;
}

- (void) setWidth2: (float)width
{
	width2 = width;
	if (width2 == 0)
		width2 = 1;
}

- (float) width2
{
	return width2;
}

- (void) drawView
{
	if (!visible)
		return;

	if (type == MD_PROGRESSBAR_NORMAL)
	{
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
				
				NSColor* color = background[0];
				if (currentValue != 0)
					color = MD_PROGRESS_DEFAULT_BKG;
				colors[(z * 4)] = [ color redComponent ] + add;
				colors[(z * 4) + 1] = [ color greenComponent ] + add;
				colors[(z * 4) + 2] = [ color blueComponent ] + add;
				colors[(z * 4) + 3] = [ color alphaComponent ];;
				
				NSColor* bcolor = MD_PROGRESS_DEFAULT_BORDER;
				bcolors[(z * 4)] = [ bcolor redComponent ];
				bcolors[(z * 4) + 1] = [ bcolor greenComponent ];
				bcolors[(z * 4) + 2] = [ bcolor blueComponent ];
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
		
		if (currentValue == 0)
		{
			glEnable(GL_SCISSOR_TEST);
			glScissor(frame.x, frame.y, frame.width, frame.height);
		
			rotation += speed / 12.5;
			if (rotation >= PART_WIDTH * 4)
				rotation -= PART_WIDTH * 4;
		
			float addX = -rotation;
			for (;;)
			{
				float realX = round(addX);
				glLoadIdentity();
				glTranslated(frame.x + frame.width - realX, frame.y, 0);
				glBegin(GL_QUADS);
				{
					NSColor* color = MD_PROGRESS_DEFAULT_OTHER;
					glColor4d([ color redComponent ], [ color greenComponent ], [ color blueComponent ], [ color alphaComponent ]);
					glVertex2d(0, 0);
					glVertex2d(PART_WIDTH, 0);
					glColor4d([ color redComponent ], [ color greenComponent ], [ color blueComponent ], [ color alphaComponent ]);
					glVertex2d(0, frame.height);
					glVertex2d(-PART_WIDTH, frame.height);
				}
				glEnd();
				
				addX += PART_WIDTH * 2;
				
				if (addX >= frame.width + PART_WIDTH)
					break;
			}
			
			glDisable(GL_SCISSOR_TEST);
			
			glLoadIdentity();
			glTranslated(frame.x, frame.y + (frame.height / 2) - 0.5, 0);
			glBegin(GL_QUADS);
			{
				glColor4d(0, 0, 0, 0.07451);
				glVertex2d(0, 0);
				glVertex2d(frame.width, 0);
				glColor4d(0, 0, 0, 1 - 0.949020);
				glVertex2d(frame.width, -(frame.height / 2) + 2);
				glVertex2d(0, -(frame.height / 2) + 2);
			}
			glEnd();
		}
		else
		{
			glLoadIdentity();
			glTranslated(frame.x, frame.y, 0);
			NSColor* color = MD_PROGRESS_DEFAULT_OTHER;
			glColor4d([ color redComponent ], [ color greenComponent ], [ color blueComponent ], [ color alphaComponent ]);
			glBegin(GL_QUADS);
			{
				glVertex2d(0, 0);
				glVertex2d(0, frame.height);
				glVertex2d((currentValue / maxValue) * frame.width, frame.height);
				glVertex2d((currentValue / maxValue) * frame.width, 0);
			}
			glEnd();
			
			glLoadIdentity();
			glTranslated(frame.x, frame.y + (frame.height / 2) - 2, 0);
			glColor4d(0, 0, 0, 0.07451);
			glLineWidth(3);
			glBegin(GL_LINES);
			{
				glVertex2d(0, 0);
				glVertex2d(((currentValue / maxValue) * frame.width), 0);
			}
			glEnd();
			glLineWidth(1);
			
			glEnable(GL_SCISSOR_TEST);
			glScissor(frame.x, frame.y, frame.width * (currentValue / maxValue), frame.height);
			
			if (rotation >= PART_WIDTH * 4)
				rotation -= PART_WIDTH * 4;
			rotation += speed / 25;
			
			float addX = -rotation;
			for (;;)
			{
				float realX = addX;
				glLoadIdentity();
				glTranslated(frame.x + realX, frame.y + (frame.height / 2) - 1, 0);
				glBegin(GL_QUADS);
				{
					glColor4d(0, 0, 0, 0);
					glVertex2d(-PART_WIDTH, -5);
					glColor4d(0, 0, 0, 0.06451);
					glVertex2d(0, -5);
					glColor4d(0, 0, 0, 0.06451);
					glVertex2d(0, 5);
					glColor4d(0, 0, 0, 0);
					glVertex2d(-PART_WIDTH, 5);
					
					glColor4d(0, 0, 0, 0.06451);
					glVertex2d(0, -5);
					glColor4d(0, 0, 0, 0);
					glVertex2d(PART_WIDTH, -5);
					glVertex2d(PART_WIDTH, 5);
					glColor4d(0, 0, 0, 0.06451);
					glVertex2d(0, 5);
				}
				glEnd();
						
				addX += PART_WIDTH * 2;
				
				if (addX >= (currentValue / maxValue) * frame.width + (PART_WIDTH / 2))
					break;
			}
			
			glDisable(GL_SCISSOR_TEST);
		}
		
		
		glDisableClientState(GL_VERTEX_ARRAY);
		glDisableClientState(GL_COLOR_ARRAY);
	}
	else
	{
		glLoadIdentity();
		glTranslated(frame.x + (frame.width / 2), frame.y + (frame.height / 2), 0);
		glColor4d(0.7, 0.7, 0.7, 1);
		glBegin(GL_QUADS);
		{
			glVertex2d(-100, -100);
			glVertex2d(100, -100);
			glVertex2d(100, 100);
			glVertex2d(-100, 100);
		}
		glEnd();
		
		float diffRed = ([background[0] redComponent ] - [ background[1] redComponent ]) / 11;
		float diffGreen = ([background[0] greenComponent ] - [ background[1] greenComponent ]) / 11;
		float diffBlue = ([background[0] blueComponent ] - [ background[1] blueComponent ]) / 11;
		float diffAlpha = ([background[0] alphaComponent ] - [ background[1] alphaComponent ]) / 11;
		
		glLoadIdentity();
		glTranslated(frame.x + (frame.height / 2), frame.y + (frame.height / 2), 0);
		glRotated(rotation - ((int)rotation % 30), 0, 0, 1);
		
		rotation -= speed / 12.5 * 6;
		if (rotation <= -360)
			rotation += 360;
		
		for (int z = 0; z < 12; z++)
		{
			glColor4d([ background[0] redComponent ] - (diffRed * z), [ background[0] greenComponent ] - (diffGreen * z),
					  [ background[0] blueComponent ] - (diffBlue * z), [ background[0] alphaComponent ] - (diffAlpha * z));
			glBegin(GL_TRIANGLE_FAN);
			{
				glVertex2d(0, frame.height / 3);
				for (int q = 0; q < 18; q++)
				{
					glVertex2d(cos((-q - 18) * M_PI / 18.0) * frame.height / 32, (frame.height * 7 / 16) + sin((-q - 18) * M_PI / 18.0) * frame.height / 16);
				}
				glVertex2d(frame.height / 32, (frame.height * 7 / 16));
				
				glVertex2d(frame.height / 32, (frame.height / 6) + (frame.height * 2 / 16));
				for (int q = 0; q < 18; q++)
				{
					glVertex2d(cos(-q * M_PI / 18.0) * frame.height / 32, (frame.height / 6) + (frame.height * 2 / 16) + sin(-q * M_PI / 18.0) * frame.height / 16);
				}
				glVertex2d(-frame.height / 32, (frame.height / 6) + (frame.height * 2 / 16));
				
				glVertex2d(-frame.height / 32, frame.height * 7 / 16);
			}
			glEnd();
			
			glColor4d([ background[0] redComponent ] - (diffRed * z), [ background[0] greenComponent ] - (diffGreen * z),
					  [ background[0] blueComponent ] - (diffBlue * z), -0.5 + [ background[0] alphaComponent ] - (diffAlpha * z));
			
			glBegin(GL_TRIANGLE_FAN);
			{
				glVertex2d(0, frame.height / 3);
				for (int q = 0; q < 18; q++)
				{
					glVertex2d(cos((-q - 18) * M_PI / 18.0) * frame.height / 24, (frame.height * 7 / 16) + sin((-q - 18) * M_PI / 18.0) * frame.height / 16);
				}
				glVertex2d(frame.height / 24, (frame.height * 7 / 16));
				
				glVertex2d(frame.height / 24, (frame.height / 6) + (frame.height * 2 / 16));
				for (int q = 0; q < 18; q++)
				{
					glVertex2d(cos(-q * M_PI / 18.0) * frame.height / 24, (frame.height / 6) + (frame.height * 2 / 16) + sin(-q * M_PI / 18.0) * frame.height / 16);
				}
				glVertex2d(-frame.height / 24, (frame.height / 6) + (frame.height * 2 / 16));
				
				glVertex2d(-frame.height / 24, frame.height * 7 / 16);
			}
			glEnd();
			glRotated(30, 0, 0, 1);
		}
	}
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
	if (otherColor)
	{
		[ otherColor release ];
		otherColor = nil;
	}
	[ super dealloc ];
}

@end
