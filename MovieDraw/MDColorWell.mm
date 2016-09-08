//
//  MDColorWell.m
//  MovieDraw
//
//  Created by MILAP on 7/26/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MDColorWell.h"
#import "MDSlider.h"
#import "MDLabel.h"

@interface MDColorWell (InternalMethods)
- (void) alphaUpdated: (id) sender;
@end

@implementation MDColorWell

+ (instancetype) mdColorWell
{
	MDColorWell* view = [ [ MDColorWell alloc ] init ];
	return view;
}

+ (instancetype) mdColorWellWithFrame: (MDRect)rect background: (NSColor*)bkg
{
	MDColorWell* view = [ [ MDColorWell alloc ] initWithFrame:rect background:bkg ];
	return view;
}

- (instancetype) init
{
	if ((self = [ super init ]))
	{
		rotation = 0;
		colorPoint = NSMakePoint(0, 0);
		selectedColor = [ NSColor colorWithDeviceRed:1 green:1 blue:1 alpha:1 ];
		sliderPos = 1.0;
		update = false;
		wantSel = false;
		alphaSlider = [ [ MDSlider alloc ] init ];
		[ views removeObject:alphaSlider ];
		[ alphaSlider setValue:0 ];
		[ alphaSlider setTarget:self ];
		[ alphaSlider setAction:@selector(alphaUpdated:) ];
		alphaText = [ [ MDLabel alloc ] initWithFrame:MakeRect(frame.x + 35, frame.y + 27.5,
			40, 15) background:[ NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:1 ] ];
		[ views removeObject:alphaText ];
		[ alphaText setText:@"Alpha:" ];
		continuous = YES;
	}
	return self;
}

- (instancetype) initWithFrame: (MDRect)rect background: (NSColor*)bkg
{
	if ((self = [ super initWithFrame:rect background:bkg ]))
	{
		[ self setFrame:rect ];
		rotation = 0;
		colorPoint = NSMakePoint((frame.x + 15) + ((frame.width - 80) / 2.0),
								 (frame.y + 55) + ((frame.height - 75) / 2.0));
		selectedColor = [ NSColor colorWithDeviceRed:1 green:1 blue:1 alpha:1 ];
		sliderPos = 1.0;
		update = false;
		wantSel = false;
		alphaSlider = [ [ MDSlider alloc ] initWithFrame:MakeRect(frame.x + 70,
			frame.y + 15, frame.width - 85, 20) background:[ NSColor
			colorWithCalibratedRed:0.2 green:0.5 blue:1 alpha:[ bkg alphaComponent ] ] ];
		[ views removeObject:alphaSlider ];
		[ alphaSlider setValue:100 ];
		[ alphaSlider setTarget:self ];
		[ alphaSlider setAction:@selector(alphaUpdated:) ];
		alphaText = [ [ MDLabel alloc ] initWithFrame:MakeRect(frame.x + 10, frame.y + 15,
			40, 15) background:[ NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:1 ] ];
		[ views removeObject:alphaText ];
		[ alphaText setText:@"Alpha:" ];
		continuous = YES;
	}
	return self;
}

- (void) alphaUpdated: (id) sender
{
	float red = 1, green = 1, blue = 1; 
	if (selectedColor)
	{
		red = [ selectedColor redComponent ];
		green = [ selectedColor greenComponent ];
		blue = [ selectedColor blueComponent ];
	}
	selectedColor = [ NSColor colorWithCalibratedRed:red green:green blue:blue alpha:
					   [ (MDSlider*)sender value ] / 100.0 ];
	if (target)
		((void (*)(id, SEL, id))[ target methodForSelector:action ])(target, action, self);
}

- (void) setFrame:(MDRect)rect
{
	rect.width = rect.height + 10;
	[ alphaSlider setFrame:MakeRect(rect.x + 70, rect.y + 15, rect.width - 85, 20) ];
	[ alphaText setFrame:MakeRect(frame.x + 10, frame.y + 15, 40, 15) ];
	[ super setFrame:rect ];
}

- (void) setAlpha:(float)alpha
{
	[ super setAlpha:alpha ];
	[ alphaSlider setAlpha:alpha ];
}

- (void) setRotation: (float)rot
{
	rotation = rot;
}

- (float) rotation
{
	return rotation;
}

- (NSColor*) selectedColor
{
	return selectedColor;
}

- (void) selectColor: (NSColor*)col
{
	wantSel = true;
	wantCol = col;
	[ alphaSlider setValue:[ col alphaComponent ] * 100 ];
}

- (void) setSliderPos: (float)pos
{
	sliderPos = pos;
}

- (float) sliderPos
{
	return sliderPos;
}

- (void) mouseDown:(NSEvent*)event
{
	if (!visible || !enabled)
		return;
	
	[ super mouseDown:event ];
	
	MDRect rect = MakeRect(frame.x + 15, frame.y + 55, frame.width - 80, frame.height - 70);
	
	NSPoint point = [ event locationInWindow ];
	point.x -= origin.x;
	point.y -= origin.y;
	point.x *= resolution.width / windowSize.width;
	point.y *= resolution.height / windowSize.height;
	float x = sqrt(pow(point.x - (rect.x + (rect.width / 2.0)), 2) +
				   pow(point.y - (rect.y + (rect.height / 2.0)), 2));
	if (x < (rect.width / 2.0) - 1)
	{
		unsigned char* data = (unsigned char*)malloc(4);
		memset(data, 0, 4);
		glPixelStorei(GL_PACK_ALIGNMENT, 1);
		glReadPixels(point.x * (windowSize.width / resolution.width),
					 point.y * (windowSize.height / resolution.height),
					 1, 1, GL_RGB, GL_UNSIGNED_BYTE, data);
		
		double d0 = data[0] / 255.0;
		double d1 = data[1] / 255.0;
		double d2 = data[2] / 255.0;
		selectedColor = [ NSColor colorWithDeviceRed:d0 green:d1 blue:d2 alpha:[ alphaSlider value ] / 100.0 ];
		colorPoint = point;
		
		free(data);
		data = NULL;
		
		if (target && continuous)
			((void (*)(id, SEL, id))[ target methodForSelector:action ])(target, action, self);
		return;
	}
	
	MDRect slider = MakeRect(frame.x + frame.width - 30, frame.y + 55,
							 20, frame.height - 70);
	MDRect sliderR = MakeRect(frame.x + frame.width - 35, (frame.y + 55) + ((sliderPos - 0.04)
																			* (frame.height - 70)) , 30, 10);
	if ((point.x >= slider.x && point.x <= slider.x + slider.width &&
		 point.y >= slider.y && point.y <= slider.y + slider.height) || 
		(point.x >= sliderR.x && point.x <= sliderR.x + sliderR.width &&
		point.y >= sliderR.y && point.y <= sliderR.y + sliderR.height))
	{
		slideDown = TRUE;
		float diff = slider.y + slider.height - point.y - 5;
		sliderPos = 1 - (diff / slider.height);
		if (sliderPos < 0.04)
			sliderPos = 0.04;
		update = true;
		if (target && continuous)
			((void (*)(id, SEL, id))[ target methodForSelector:action ])(target, action, self);
	}
	
	[ alphaSlider mouseDown:event ];
}

- (void) mouseDragged:(NSEvent*)event
{
	if (!visible || !enabled)
		return;
	
	[ super mouseDragged:event ];
	
	MDRect rect = MakeRect(frame.x + 15, frame.y + 55, frame.width - 80, frame.height - 70);
	
	NSPoint point = [ event locationInWindow ];
	point.x -= origin.x;
	point.y -= origin.y;
	point.x *= resolution.width / windowSize.width;
	point.y *= resolution.height / windowSize.height;
	float x = sqrt(pow(point.x - (rect.x + (rect.width / 2.0)), 2) +
				   pow(point.y - (rect.y + (rect.height / 2.0)), 2));
	if (x < (rect.width / 2.0) - 1)
	{
		unsigned char* data = (unsigned char*)malloc(4);
		memset(data, 0, 4);
		glPixelStorei(GL_PACK_ALIGNMENT, 1);
		glReadPixels(point.x * (windowSize.width / resolution.width),
					 point.y * (windowSize.height / resolution.height),
					 1, 1, GL_RGB, GL_UNSIGNED_BYTE, data);
		
		double d0 = data[0] / 255.0;
		double d1 = data[1] / 255.0;
		double d2 = data[2] / 255.0;
		selectedColor = [ NSColor colorWithDeviceRed:d0 green:d1 blue:d2 alpha:[ alphaSlider value ] / 100.0 ];
		colorPoint = point;
		
		free(data);
		data = NULL;
		
		if (target && continuous)
			((void (*)(id, SEL, id))[ target methodForSelector:action ])(target, action, self);
		return;
	}
	
	MDRect slider = MakeRect(frame.x + frame.width - 30, frame.y + 55,
							 20, frame.height - 70);
	if (slideDown)
	{
		float diff = slider.y + slider.height - point.y - 5;
		sliderPos = 1 - (diff / slider.height);
		if (sliderPos > 1)
			sliderPos = 1;
		if (sliderPos < 0.04)
			sliderPos = 0.04;
		update = true;
		if (target && continuous)
			((void (*)(id, SEL, id))[ target methodForSelector:action ])(target, action, self);
	}
	
	[ alphaSlider mouseDragged:event ];
}

- (void) mouseUp:(NSEvent*)event
{
	if (!visible || !enabled)
		return;
	
	NSPoint point = [ event locationInWindow ];
	point.x -= origin.x;
	point.y -= origin.y;
	point.x *= resolution.width / windowSize.width;
	point.y *= resolution.height / windowSize.height;
	if (point.x >= frame.x && point.x <= frame.x + frame.width &&
		point.y >= frame.y && point.y <= frame.y + frame.height)
	{
		if (down && target != nil && !continuous)
			((void (*)(id, SEL, id))[ target methodForSelector:action ])(target, action, self);
	}
	down = FALSE;
	up = TRUE;
	realDown = FALSE;
	slideDown = FALSE;
	
	[ alphaSlider mouseUp:event ];
}

- (void) drawView
{	
	if (!visible)
		return;
	
	float toadd = !enabled ? -0.3 : 0.0;
	[ super drawView ];
	if (text && [ text length ] != 0)
	{
		if (!glStr)
			glStr = LoadString(text, textColor, textFont);
		DrawString(glStr, NSMakePoint(frame.x + (frame.width / 2), frame.y + 10),
				   NSCenterTextAlignment, 0);
	}
	
	float square[722];
	memset(square, 0, 722);
	MDRect rect = MakeRect(frame.x + 15, frame.y + 55, frame.width - 80, frame.height - 70);
	
	square[0] = (rect.x + (rect.width / 2.0));
	square[1] = (rect.y + (rect.height / 2.0));
	for(int i = 0; i < 720; i += 2)
	{ 
        float angle = M_PI * (i / 2) / 180.0; 
		square[i + 2] = ((rect.x + (rect.width / 2.0)) + (cos(angle) * 
															(rect.width / 2.0)));
		square[i + 3] = ((rect.y + (rect.height / 2.0)) + (sin(angle) *
																 (rect.height / 2.0)));
    }
	square[720] = (rect.x + rect.width);
	square[721] = (rect.y + (rect.height / 2.0));
	
	
	float colors[1444];
	memset(colors, 0, 1444);
	float red = 255.0, green = 0, blue = 0;
	colors[0] = sliderPos + toadd;
	colors[1] = sliderPos + toadd;
	colors[2] = sliderPos + toadd;
	colors[3] = 1;
	for (int z = 4; z < 484; z += 4)
	{
		colors[z] = (red * sliderPos / 255.0) + toadd;
		colors[z + 1] = (green * sliderPos / 255.0) + toadd;
		colors[z + 2] = (blue * sliderPos / 255.0) + toadd;
		colors[z + 3] = 1;
		if (green != 255)
			green += (255.0 / 60);
		else
			red -= (255.0 / 60);
	}
	for (int z = 484; z < 964; z += 4)
	{
		colors[z] = (red * sliderPos / 255.0) + toadd;
		colors[z + 1] = (green * sliderPos / 255.0) + toadd;
		colors[z + 2] = (blue * sliderPos / 255.0) + toadd;
		colors[z + 3] = 1;
		if (blue != 255)
			blue += (255.0 / 60);
		else
			green -= (255.0 / 60);
	}
	for (int z = 964; z < 1444; z += 4)
	{
		colors[z] = (red * sliderPos / 255.0) + toadd;
		colors[z + 1] = (green * sliderPos / 255.0) + toadd;
		colors[z + 2] = (blue * sliderPos / 255.0) + toadd;
		colors[z + 3] = 1;
		if (red != 255)
			red += (255.0 / 60);
		else
			blue -= (255.0 / 60);
	}
	
	glLoadIdentity();
	glVertexPointer(2, GL_FLOAT, 0, square);
	glEnableClientState(GL_VERTEX_ARRAY);
	glColorPointer(4, GL_FLOAT, 0, colors);
	glEnableClientState(GL_COLOR_ARRAY);
	
	// Draw
	glTranslatef(rect.x + (rect.width / 2.0),
				 rect.y + (rect.height / 2.0), 0);
	glRotatef(-rotation, 0, 0, 1);
	glTranslatef(-(rect.x + (rect.width / 2.0)),
				 -(rect.y + (rect.height / 2.0)), 0);
	
    glDrawArrays(GL_TRIANGLE_FAN, 0, 361);
	glDisableClientState(GL_VERTEX_ARRAY);
	glDisableClientState(GL_COLOR_ARRAY);
	
	glLoadIdentity();
	
	float slideS[8];
	memset(slideS, 0, 8);
	MDRect slider = MakeRect(frame.x + frame.width - 30, frame.y + 55, 20, frame.height - 70);
	slideS[0] = slider.x;
	slideS[1] = slider.y;
	slideS[2] = slider.x + slider.width;
	slideS[3] = slider.y;
	slideS[4] = slider.x;
	slideS[5] = slider.y + slider.height;
	slideS[6] = slider.x + slider.width;
	slideS[7] = slider.y + slider.height;
	
	float scolors[16];
	double tred = [ selectedColor redComponent ], tgreen = [ selectedColor greenComponent ],
		tblue = [ selectedColor blueComponent ];
	double diffr = tred;
	double diffg = tgreen;
	double diffb = tblue;
	double percent = 0;
	if (diffr >= diffg && diffr >= diffb)
		percent = 1 / diffr;
	else if (diffg >= diffb)
		percent = 1 / diffg;
	else
		percent = 1 / diffb;
	tred = tred * percent;
	tgreen = tgreen * percent;
	tblue = tblue * percent;
	scolors[0] = toadd;
	scolors[1] = toadd;
	scolors[2] = toadd;
	scolors[3] = 1;
	scolors[4] = toadd;
	scolors[5] = toadd;
	scolors[6] = toadd;
	scolors[7] = 1;
	scolors[8] = tred + toadd;
	scolors[9] = tgreen + toadd;
	scolors[10] = tblue + toadd;
	scolors[11] = 1;
	scolors[12] = tred + toadd;
	scolors[13] = tgreen + toadd;
	scolors[14] = tblue + toadd;
	scolors[15] = 1;
	
	glVertexPointer(2, GL_FLOAT, 0, slideS);
	glEnableClientState(GL_VERTEX_ARRAY);
	glColorPointer(4, GL_FLOAT, 0, scolors);
	glEnableClientState(GL_COLOR_ARRAY);
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	glDisableClientState(GL_VERTEX_ARRAY);
	glDisableClientState(GL_COLOR_ARRAY);
	
	float slideP[8];
	memset(slideP, 0, 8);
	MDRect sliderR = MakeRect(frame.x + frame.width - 35, (frame.y + 55) + ((sliderPos - 0.04)
								* (frame.height - 70)) , 30, 10);
	slideP[0] = sliderR.x;
	slideP[1] = sliderR.y;
	slideP[2] = sliderR.x + sliderR.width;
	slideP[3] = sliderR.y;
	slideP[4] = sliderR.x;
	slideP[5] = sliderR.y + sliderR.height;
	slideP[6] = sliderR.x + sliderR.width;
	slideP[7] = sliderR.y + sliderR.height;
	
	if (slideDown && enabled)
		toadd -= 0.2;
	float spcolors[16];
	spcolors[0] = 1.0 + toadd;
	spcolors[1] = 1.0 + toadd;
	spcolors[2] = 1.0 + toadd;
	spcolors[3] = [ background alphaComponent ];
	spcolors[4] = 0.8 + toadd;
	spcolors[5] = 0.8 + toadd;
	spcolors[6] = 0.8 + toadd;
	spcolors[7] = [ background alphaComponent ];
	spcolors[8] = 1.0 + toadd;
	spcolors[9] = 1.0 + toadd;
	spcolors[10] = 1.0 + toadd;
	spcolors[11] = [ background alphaComponent ];
	spcolors[12] = 0.8 + toadd;
	spcolors[13] = 0.8 + toadd;
	spcolors[14] = 0.8 + toadd;
	spcolors[15] = [ background alphaComponent ];
	glVertexPointer(2, GL_FLOAT, 0, slideP);
	glEnableClientState(GL_VERTEX_ARRAY);
	glColorPointer(4, GL_FLOAT, 0, spcolors);
	glEnableClientState(GL_COLOR_ARRAY);
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	glDisableClientState(GL_VERTEX_ARRAY);
	glDisableClientState(GL_COLOR_ARRAY);
	if (slideDown && enabled)
		toadd += 0.2;
	
	float selpoint[8];
	memset(selpoint, 0, 8);
	MDRect selRect = MakeRect(colorPoint.x - 10, colorPoint.y - 10, 20, 20);
	selpoint[0] = selRect.x;
	selpoint[1] = selRect.y;
	selpoint[2] = selRect.x + selRect.width;
	selpoint[3] = selRect.y;
	selpoint[4] = selRect.x + selRect.width;
	selpoint[5] = selRect.y + selRect.height;
	selpoint[6] = selRect.x;
	selpoint[7] = selRect.y + selRect.height;
	
	unsigned char selcol[16];
	memset(selcol, 255 + (toadd * 255), 16);
	selcol[3] = [ background alphaComponent ] * 255;
	selcol[7] = [ background alphaComponent ] * 255;
	selcol[11] = [ background alphaComponent ] * 255;
	selcol[15] = [ background alphaComponent ] * 255;
	
	glVertexPointer(2, GL_FLOAT, 0, selpoint);
	glEnableClientState(GL_VERTEX_ARRAY);
	glColorPointer(4, GL_UNSIGNED_BYTE, 0, selcol);
	glEnableClientState(GL_COLOR_ARRAY);
	glDrawArrays(GL_LINE_LOOP, 0, 4);
	glDisableClientState(GL_VERTEX_ARRAY);
	glDisableClientState(GL_COLOR_ARRAY);
	
	if (update && enabled)
	{
		float* data = (float*)malloc(4 * sizeof(float));
		memset(data, 0, 4 * sizeof(float));
		glPixelStorei(GL_PACK_ALIGNMENT, 1);
		glReadPixels(colorPoint.x * (windowSize.width / resolution.width),
					 colorPoint.y * (windowSize.height / resolution.height),
					 1, 1, GL_RGBA, GL_FLOAT, data);
		selectedColor = [ NSColor colorWithDeviceRed:data[0] green:data[1] blue:data[2] alpha:data[3] ];
		free(data);
		data = NULL;
		
		update = false;
	}
	
	if (wantSel && enabled)
	{
		MDRect rect = MakeRect((frame.x + 15) * (windowSize.width / resolution.width),
							   (frame.y + 55) * (windowSize.height / resolution.height),
							   (frame.width - 80) * (windowSize.width / resolution.width),
							   (frame.height - 70) * (windowSize.height / resolution.height));
		sliderPos = 1;
		for (int z = 0; z < 100; z++, sliderPos -= 0.01)
		{
			unsigned char* data = (unsigned char*)malloc(rect.width * rect.height * 3);
			glPixelStorei(GL_PACK_ALIGNMENT, 1);
			glReadPixels(rect.x, rect.y, rect.width, rect.height, GL_RGB,
						 GL_UNSIGNED_BYTE, data);
			bool stop = false;
			for (float y = rect.y; y < rect.y + rect.height; y++)
			{
				int realy = y - rect.y;
				for (float x = rect.x; x < rect.x + rect.width; x++)
				{
					int realx = x - rect.x;
					unsigned int position = (realx + (realy * rect.width)) * 3;
					int red = data[position] * sliderPos;
					int green = data[position + 1] * sliderPos;
					int blue = data[position + 2] * sliderPos;
					int realr = [ wantCol redComponent ] * 255;
					int realg = [ wantCol greenComponent ] * 255;
					int realb = [ wantCol blueComponent ] * 255;
					
					if (realr >= red - 3 && realr <= red + 3 && realg >= green - 3 &&
						realg <= green + 3 && realb >= blue - 3 && realb <= blue + 3)
					{
						selectedColor = wantCol;
						colorPoint = NSMakePoint(x, y);
						stop = true;
						break;
					}
				}
				if (stop)
					break;
			}
			free(data);
			data = NULL;
			if (stop)
				break;
		}
		wantSel = false;
	}
	
	[ alphaText drawView ];
	[ alphaSlider drawView ];
}

- (void) dealloc
{
	if (alphaSlider)
		[ views removeObject:alphaSlider ];
}

@end
