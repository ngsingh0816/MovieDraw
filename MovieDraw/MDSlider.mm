//
//  MDSlider.m
//  MovieDraw
//
//  Created by MILAP on 9/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MDSlider.h"


@implementation MDSlider

+ (instancetype) mdSlider
{
	return [ [ MDSlider alloc ] init ];
}

+ (instancetype) mdSliderWithFrame: (MDRect)rect background: (NSColor*)bkg
{
	return [ [ MDSlider alloc ] initWithFrame:rect background:bkg ];
}

- (instancetype) init
{
	if ((self = [ super init ]))
	{
		continuous = YES;
		maxValue = 100;
		changed  = TRUE;
		
		verticies = (float*)malloc(sizeof(float) * 44);
		cverticies = (float*)malloc(sizeof(float) * 76);
		bverticies = (float*)malloc(sizeof(float) * 44);
		bverticies2 = (float*)malloc(sizeof(float) * 76);
		colors = (float*)malloc(sizeof(float) * 22 * 4);
		ccolors = (float*)malloc(sizeof(float) * 38 * 4);
		bcolors = (float*)malloc(sizeof(float) * 22 * 4);
		bcolors2 = (float*)malloc(sizeof(float) * 38 * 4);
	}
	return self;
}

- (instancetype) initWithFrame:(MDRect) rect background:(NSColor*) bkg
{
	if ((self = [ super initWithFrame:rect background:bkg ]))
	{
		continuous = YES;
		maxValue = 100;
		changed = TRUE;
		
		verticies = (float*)malloc(sizeof(float) * 44);
		cverticies = (float*)malloc(sizeof(float) * 76);
		bverticies = (float*)malloc(sizeof(float) * 44);
		bverticies2 = (float*)malloc(sizeof(float) * 76);
		colors = (float*)malloc(sizeof(float) * 22 * 4);
		ccolors = (float*)malloc(sizeof(float) * 38 * 4);
		bcolors = (float*)malloc(sizeof(float) * 22 * 4);
		bcolors2 = (float*)malloc(sizeof(float) * 38 * 4);
	}
	return self;
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
	
	BOOL inCircle = FALSE;
	NSPoint center = NSMakePoint(frame.x + (frame.width * (selValue / maxValue)), frame.y + (frame.height / 2));
	if (distanceB(center, point) <= (frame.height / 2))
		inCircle = TRUE;
	BOOL inSquare = FALSE;
	if (fabs(point.x - center.x) <= (frame.height / 3) + 1 && point.y >= frame.y && point.y <= frame.y + frame.height)
		inSquare = TRUE;
	
	if ((point.x >= frame.x && point.x <= frame.x + frame.width &&
		point.y >= frame.y && point.y <= frame.y + frame.height) || (inCircle && tickMarks == 0) || (inSquare && tickMarks != 0))
	{
		down = TRUE;
		up = FALSE;
		realDown = TRUE;
		float position = point.x - frame.x;
		selValue = (position / frame.width) * maxValue;
		if (selValue < 0)
			selValue = 0;
		if (selValue > maxValue)
			selValue = maxValue;
		if (stopOnTicks && tickMarks > 1)
		{
			float subtract = selValue;
			while (subtract > maxValue / (tickMarks - 1))
				subtract -= maxValue / (tickMarks - 1);
			float add = (maxValue / (tickMarks - 1)) - subtract;
			if (add <= subtract)
				selValue += add;
			else
				selValue -= subtract;
		}
		else if (stopOnTicks && tickMarks == 1)
			selValue = maxValue / 2;
		if (target != nil && continuous)
			((void (*)(id, SEL, id))[ target methodForSelector:action ])(target, action, self);
		
		changed = TRUE;
	}
}

- (void) mouseDragged: (NSEvent*)event
{
	if (!visible || !enabled)
		return;
	
	if (up || !realDown)
		return;
	down = !up;
	NSPoint point = [ event locationInWindow ];
	point.x -= origin.x;
	point.y -= origin.y;
	point.x *= resolution.width / windowSize.width;
	point.y *= resolution.height / windowSize.height;
	float position = point.x - frame.x;
	selValue = (position / frame.width) * maxValue;
	if (selValue < 0)
		selValue = 0;
	if (selValue > maxValue)
		selValue = maxValue;
	if (stopOnTicks && tickMarks > 1)
	{
		float subtract = selValue;
		while (subtract > maxValue / (tickMarks - 1))
			subtract -= maxValue / (tickMarks - 1);
		float add = (maxValue / (tickMarks - 1)) - subtract;
		if (add <= subtract)
			selValue += add;
		else
			selValue -= subtract;
	}
	else if (stopOnTicks && tickMarks == 1)
		selValue = maxValue / 2;
	
	if (target != nil && continuous)
		((void (*)(id, SEL, id))[ target methodForSelector:action ])(target, action, self);
}

- (void) mouseUp:(NSEvent *)event
{
	if (realDown)
		changed = TRUE;
	[ super mouseUp:event ];
}

- (void) setMaxValue: (float) value
{
	maxValue = value;
	if (maxValue == 0)
		maxValue = 100;
}

- (float) maxValue
{
	return maxValue;
}

- (void) drawView
{
	if (!visible)
		return;
	
	if (changed)
	{
		float realHeight = 0;
		if (tickMarks == 0)
			realHeight = round(frame.height / 7.5);
		else
			realHeight = round(frame.height / 12.0);
		
		memset(verticies, 0, 44);
		verticies[0] = frame.x + 3.5;
		verticies[1] = frame.y + (frame.height / 2) + realHeight;
		for (int i = 0; i <= 18; i += 2)
		{
			float angle = (i * 10) + 90;
			float rad = (M_PI * angle / 180.0);
			verticies[2 + i] = frame.x + 3.5 + (cos(rad) * 3.5);
			verticies[3 + i] = frame.y + (frame.height / 2) + (sin(rad) * realHeight);
		}
		for (int i = 0; i <= 18; i += 2)
		{
			float angle = (i * 10) - 90;
			float rad = (M_PI * angle / 180.0);
			verticies[22 + i] = frame.x + frame.width - 3.5 + (cos(rad) * 3.5);
			verticies[23 + i] = frame.y + (frame.height / 2) + (sin(rad) * realHeight);
		}
		verticies[42] = frame.x + 3.5;
		verticies[43] = frame.y + (frame.height / 2) + realHeight;
		
		float lane = 1;
		memset(bverticies, 0, 44);
		bverticies[0] = frame.x + 3.5 - lane;
		bverticies[1] = frame.y + (frame.height / 2) + realHeight + lane;
		for (int i = 0; i <= 18; i += 2)
		{
			float angle = (i * 10) + 90;
			float rad = (M_PI * angle / 180.0);
			bverticies[2 + i] = frame.x + 3.5 - lane + (cos(rad) * 3.5);
			bverticies[3 + i] = frame.y + (frame.height / 2) + (sin(rad) * (realHeight + lane));
		}
		for (int i = 0; i <= 18; i += 2)
		{
			float angle = (i * 10) - 90;
			float rad = (M_PI * angle / 180.0);
			bverticies[22 + i] = frame.x + frame.width - 3.5 + lane + (cos(rad) * 3.5);
			bverticies[23 + i] = frame.y + (frame.height / 2) + (sin(rad) * (realHeight + lane));
		}
		bverticies[42] = frame.x + 3.5 - lane;
		bverticies[43] = frame.y + (frame.height / 2) + realHeight + lane;
		
		if (tickMarks == 0)
		{
			memset(cverticies, 0, 76);
			cverticies[0] = frame.x;
			cverticies[1] = frame.y + (frame.height / 2);
			for (int i = 0; i < 72; i += 2)
			{
				float angle = (i * 5);
				float rad = (M_PI * angle / 180.0);
				cverticies[2 + i] = frame.x + (cos(rad) * frame.height / 2);
				cverticies[3 + i] = frame.y + (frame.height / 2) + (sin(rad) * frame.height / 2);
			}
			cverticies[74] = frame.x + (frame.height / 2);
			cverticies[75] = frame.y + (frame.height / 2);
			
			float blane = 1;
			memset(bverticies2, 0, 76);
			bverticies2[0] = frame.x - blane;
			bverticies2[1] = frame.y + (frame.height / 2);
			for (int i = 0; i < 72; i += 2)
			{
				float angle = (i * 5);
				float rad = (M_PI * angle / 180.0);
				bverticies2[2 + i] = frame.x + (cos(rad) * (frame.height / 2 + blane));
				bverticies2[3 + i] = frame.y + (frame.height / 2) + (sin(rad) * (frame.height / 2 + blane));
			}
			bverticies2[74] = frame.x + (frame.height / 2) + blane;
			bverticies2[75] = frame.y + (frame.height / 2);
		}
		else
		{
			memset(cverticies, 0, 76);
			cverticies[0] = frame.x;
			cverticies[1] = frame.y + (frame.height / 2);
			cverticies[2] = frame.x - (frame.height / 3);
			cverticies[3] = frame.y + (frame.height / 2) - (frame.height / 4);
			cverticies[4] = frame.x + (frame.height / 3);
			cverticies[5] = frame.y + (frame.height / 2) - (frame.height / 4);
			cverticies[6] = frame.x + (frame.height / 3);
			cverticies[7] = frame.y + (frame.height / 3 * 2);
			cverticies[8] = frame.x;
			cverticies[9] = frame.y + frame.height;
			cverticies[10] = frame.x - (frame.height / 3);
			cverticies[11] = frame.y + (frame.height / 3 * 2);
			cverticies[12] = frame.x - (frame.height / 3);
			cverticies[13] = frame.y + (frame.height / 2) - (frame.height / 4);
			
			float lane = 1;
			memset(bverticies2, 0, 76);
			bverticies2[0] = frame.x;
			bverticies2[1] = frame.y + (frame.height / 2);
			bverticies2[2] = frame.x - (frame.height / 3) - lane;
			bverticies2[3] = frame.y  + (frame.height / 2) - (frame.height / 4) - lane;
			bverticies2[4] = frame.x + (frame.height / 3) + lane;
			bverticies2[5] = frame.y + (frame.height / 2) - (frame.height / 4) - lane;
			bverticies2[6] = frame.x + (frame.height / 3) + lane;
			bverticies2[7] = frame.y + (frame.height / 3 * 2) + lane;
			bverticies2[8] = frame.x;
			bverticies2[9] = frame.y + frame.height + lane;
			bverticies2[10] = frame.x - (frame.height / 3) - lane;
			bverticies2[11] = frame.y + (frame.height / 3 * 2) + lane;
			bverticies2[12] = frame.x - (frame.height / 3) - lane;
			bverticies2[13] = frame.y + (frame.height / 2) - (frame.height / 4) - lane;

		}
		
		
		for (int z = 0; z < 22; z++)
		{
			float add = !enabled ? -0.3 : 0.0;
			
			NSColor* color = MD_SLIDER_DEFAULT_COLOR;
			colors[(z * 4)] = [ color redComponent ] + add;
			colors[(z * 4) + 1] = [ color greenComponent ] + add;
			colors[(z * 4) + 2] = [ color blueComponent ] + add;
			colors[(z * 4) + 3] = [ color alphaComponent ];
			
			NSColor* bcolor = MD_SLIDER_DEFAULT_BORDER_COLOR;
			bcolors[(z * 4)] = [ bcolor redComponent ];
			bcolors[(z * 4) + 1] = [ bcolor greenComponent ];
			bcolors[(z * 4) + 2] = [ bcolor blueComponent ];
			bcolors[(z * 4) + 3] = [ bcolor alphaComponent ];
			
			if (z > 5 && z < 16)
			{
				bcolors[(z * 4)] += 0.23;
				bcolors[(z * 4) + 1] += 0.23;
				bcolors[(z * 4) + 2] += 0.23;
			}
		}
		
		for (int z = 0; z < 38; z++)
		{
			float add = !enabled ? -0.3 : 0.0;
			
			NSColor* color = MD_SLIDER_DEFAULT_BUTTON_COLOR;
			if (down)
				color = MD_SLIDER_DEFAULT_MOUSE_COLOR;
			ccolors[(z * 4)] = [ color redComponent ] + add;
			ccolors[(z * 4) + 1] = [ color greenComponent ] + add;
			ccolors[(z * 4) + 2] = [ color blueComponent ] + add;
			ccolors[(z * 4) + 3] = [ color alphaComponent ];
			
			NSColor* bcolor = MD_SLIDER_DEFAULT_BUTTON_BORDER_COLOR;
			bcolors2[(z * 4)] = [ bcolor redComponent ] + add;
			bcolors2[(z * 4) + 1] = [ bcolor greenComponent ] + add;
			bcolors2[(z * 4) + 2] = [ bcolor blueComponent ] + add;
			bcolors2[(z * 4) + 3] = [ bcolor alphaComponent ];
		}
		
		
		changed = FALSE;
	}
	
	glLoadIdentity();
	
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_COLOR_ARRAY);
	
	glVertexPointer(2, GL_FLOAT, 0, bverticies);
	glColorPointer(4, GL_FLOAT, 0, bcolors);
	glDrawArrays(GL_TRIANGLE_FAN, 0, 22);
	
	glVertexPointer(2, GL_FLOAT, 0, verticies);
	glColorPointer(4, GL_FLOAT, 0, colors);
	glDrawArrays(GL_TRIANGLE_FAN, 0, 22);
	
	if (tickMarks != 0)
	{
		glLoadIdentity();
		glTranslated(frame.x, frame.y + frame.height, 0);
		glColor4d(0, 0, 0, 1);
		float space = 0;
		float position = 0;
		if (tickMarks != 1)
			space = frame.width / (tickMarks - 1);
		else
			position = (frame.width / 2);
		for (unsigned long z = 0; z < tickMarks; z++)
		{
			glBegin(GL_LINES);
			{
				glVertex2d(position, 0);
				glVertex2d(position, frame.height / 6);
			}
			glEnd();
			position += space;
		}
		glLoadIdentity();
	}
	
	
	glTranslated(round(selValue / maxValue * frame.width), 0, 0);
	
	glVertexPointer(2, GL_FLOAT, 0, bverticies2);
	glColorPointer(4, GL_FLOAT, 0, bcolors2);
	glDrawArrays(GL_TRIANGLE_FAN, 0, (tickMarks == 0) ? 38 : 7);
	
	glVertexPointer(2, GL_FLOAT, 0, cverticies);
	glColorPointer(4, GL_FLOAT, 0, ccolors);
	glDrawArrays(GL_TRIANGLE_FAN, 0, (tickMarks == 0) ? 38 : 7);
	
	glDisableClientState(GL_VERTEX_ARRAY);
	glDisableClientState(GL_COLOR_ARRAY);
	
	if (tickMarks == 0)
	{
		glTranslated(frame.x, frame.y, 0);
		glColor4d(0, 0, 0, 0.062745);
		glBegin(GL_TRIANGLE_FAN);
		{
			glVertex2d(0, frame.height / 2);
			for (int i = 0; i < 36; i++)
			{
				float angle = (i * 5) + 180;
				float rad = (M_PI * angle / 180.0);
				glVertex2d(cos(rad) * frame.height / 2, (frame.height / 2) + (sin(rad) * frame.height / 2));
			}
			glVertex2d(frame.height / 2, frame.height / 2);
		}
		glEnd();
		glColor4d(1, 1, 1, 1);
		glLoadIdentity();
	}
	else
	{
		glTranslated(frame.x, frame.y - (frame.height / 8), 0);
		glColor4d(0, 0, 0, 0.062745);
		glBegin(GL_TRIANGLE_STRIP);
		{
			glVertex2d(frame.height / 3, (frame.height / 2) + (frame.height / 6));
			glVertex2d(-frame.height / 3, (frame.height / 2) + (frame.height / 6));
			glVertex2d(frame.height / 3, (frame.height / 2) - (frame.height / 6));
			glVertex2d(-frame.height / 3, (frame.height / 2) - (frame.height / 6));
		}
		glEnd();
		glColor4d(1, 1, 1, 1);
		glLoadIdentity();
	}
	
	if (continuous && down && target != nil && [ target respondsToSelector:action ] &&
		(fpsCounter % ccount) == 0)
		((void (*)(id, SEL, id))[ target methodForSelector:action ])(target, action, self);
	fpsCounter++;
	if (fpsCounter >= 3600)
		fpsCounter -= 3600;
}

- (void) setValue: (float)value
{
	selValue = value;
	if (stopOnTicks && tickMarks > 1)
	{
		float subtract = selValue;
		while (subtract > maxValue / (tickMarks - 1))
			subtract -= maxValue / (tickMarks - 1);
		float add = (maxValue / (tickMarks - 1)) - subtract;
		if (add <= subtract)
			selValue += add;
		else
			selValue -= subtract;
	}
	else if (stopOnTicks && tickMarks == 1)
		selValue = maxValue / 2;
	if (target && [ target respondsToSelector:action ])
		((void (*)(id, SEL, id))[ target methodForSelector:action ])(target, action, self);
}

- (float) value
{
	return selValue;
}

- (void) setNumberOfTickMarks:(unsigned long)num
{
	if ((tickMarks == 0 && num != 0) || (tickMarks != 0 && num == 0))
		changed = TRUE;
	tickMarks = num;
}

- (unsigned long) numberOfTickMarks
{
	return tickMarks;
}

- (void) setOnlyStopsOnTickMarks:(BOOL)does
{
	stopOnTicks = does;
	[ self setValue:selValue ];
}

- (BOOL) onlyStopsOnTickMarks
{
	return stopOnTicks;
}

- (void) dealloc
{
	if (verticies)
	{
		free(verticies);
		verticies = NULL;
	}
	if (cverticies)
	{
		free(cverticies);
		cverticies = NULL;
	}
	if (bverticies)
	{
		free(bverticies);
		bverticies = NULL;
	}
	if (bverticies2)
	{
		free(bverticies2);
		bverticies2 = NULL;
	}
	if (colors)
	{
		free(colors);
		colors = NULL;
	}
	if (ccolors)
	{
		free(ccolors);
		ccolors = NULL;
	}
	if (bcolors)
	{
		free(bcolors);
		bcolors = NULL;
	}
	if (bcolors2)
	{
		free(bcolors2);
		bcolors2 = NULL;
	}
}

@end
