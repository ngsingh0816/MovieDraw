//
//  MDCheckBox.m
//  MovieDraw
//
//  Created by MILAP on 7/10/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MDCheckBox.h"


@implementation MDCheckBox

+ (instancetype) mdCheckBox
{
	MDCheckBox* view = [ [ MDCheckBox alloc ] init ];
	return view;
}

+ (instancetype) mdCheckBoxWithFrame: (MDRect)rect background: (NSColor*)bkg;
{
	MDCheckBox* view = [ [ MDCheckBox alloc ] initWithFrame:rect background:bkg ];
	return view;
}

- (instancetype) init
{
	if ((self = [ super init ]))
	{
		selectionColor = MD_CHECKBOX_DEFAULT_SELECTION_COLOR;
		checkColor = MD_CHECKBOX_DEFAULT_CHECK_COLOR;
		
		radius = 4;
		strokeSize = 2;
		return self;
	}
	return nil;
}

- (instancetype) initWithFrame: (MDRect)rect background: (NSColor*)bkg;
{
	if ((self = [ super initWithFrame:rect background:bkg ]))
	{
		selectionColor = MD_CHECKBOX_DEFAULT_SELECTION_COLOR;
		checkColor = MD_CHECKBOX_DEFAULT_CHECK_COLOR;
		
		radius = 4;
		strokeSize = 2;
		return self;
	}
	return nil;
}

- (void) mouseDown: (NSEvent*)event
{
	if (!visible || !enabled || (parentView && ![ parentView visible ]))
		return;
	
	if (text && textFont && glStr)
		frame.width += [ glStr frameSize ].width;
	
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
		down = TRUE;
		up = FALSE;
		realDown = TRUE;
		if (continuous && target != nil)
			((void (*)(id, SEL, id))[ target methodForSelector:action ])(target, action, self);
	}
	
	if (text && textFont && glStr)
		frame.width -= [ glStr frameSize ].width;
}

- (void) mouseDragged: (NSEvent*)event
{
	if (!visible || !enabled || (parentView && ![ parentView visible ]))
		return;
		
	if (text && textFont && glStr)
		frame.width += [ glStr frameSize ].width;

	[ super mouseDragged:event ];
	
	if (text && textFont && glStr)
		frame.width -= [ glStr frameSize ].width;
}

- (void) mouseUp: (NSEvent*)event
{
	if (!visible || !enabled || (parentView && ![ parentView visible ]))
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
		if ([ event clickCount ] != 2 || ![ target respondsToSelector:doubleAction ])
		{
			if (down && target != nil && !continuous && [ target respondsToSelector:action ])
				((void (*)(id, SEL, id))[ target methodForSelector:action ])(target, action, self);
		}
		else
		{
			if (down && target != nil && !continuous && [ target respondsToSelector:doubleAction ])
				((void (*)(id, SEL, id))[ target methodForSelector:action ])(target, action, self);
		}
		if (down)
		{
			state = !state;
		}
	}
	down = FALSE;
	realDown = FALSE;
	
	if (text && textFont && glStr)
		frame.width -= [ glStr frameSize ].width;
}

- (void) setSelectionColor:(NSColor*)color
{
	selectionColor = color;
}

- (NSColor*) selectionColor
{
	return selectionColor;
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
	
	if (!vao[0] || updateVAO)
	{
		MDDeleteVAO(vao);
		MDDeleteVAO(strokeVao);
		MDDeleteVAO(checkVao);
		
		MDCreateRoundedRectVAO(frame, radius, vao);
		MDCreateStrokeVAO(frame, radius, strokeSize, strokeVao);
		
		float square[12 * 3];
		
		square[0] = 0; // frame.x
		square[1] = 0 + frame.height * 2 / 7;
		square[2] = 0;
		
		square[3] = 0 + frame.width / 7;
		square[4] = 0 + (frame.height * 3.25 / 7);
		square[5] = 0;
		
		square[6] = 0 + frame.width * 3 / 7;
		square[7] = 0 + frame.height * 2 / 7;
		square[8] = 0;
		
		square[9] = square[6];
		square[10] = square[7];
		square[11] = 0;
		
		square[12] = square[0];
		square[13] = square[1];
		square[14] = 0;
		
		square[15] = 0 + frame.width * 3.5 / 7;
		square[16] = 0;	// frame.y
		square[17] = 0;
		
		
		square[18] = square[6];
		square[19] = square[7];
		square[20] = 0;
		
		square[21] = square[15];
		square[22] = square[16];
		square[23] = 0;
		
		square[24] = 0 + frame.width * 7.75 / 7;
		square[25] = 0 + frame.height * 9 / 7;
		square[26] = 0;
		
		
		square[27] = square[24];
		square[28] = square[25];
		square[29] = 0;
		
		square[30] = square[15];
		square[31] = square[16];
		square[32] = 0;
		
		square[33] = 0 + frame.width * 9 / 7;
		square[34] = 0 + frame.height * 8.25 / 7;
		square[35] = 0;

		
		glGenVertexArrays(1, &checkVao[0]);
		glBindVertexArray(checkVao[0]);
		
		glGenBuffers(1, &checkVao[1]);
		glBindBuffer(GL_ARRAY_BUFFER, checkVao[1]);
		glBufferData(GL_ARRAY_BUFFER, 12 * 3 * sizeof(float), square, GL_STATIC_DRAW);
		glVertexAttribPointer(0, 3, GL_FLOAT, NO, 0, NULL);
		glEnableVertexAttribArray(0);
		
		glBindVertexArray(0);
		
		updateVAO = FALSE;
	}
	
	MDMatrix matrix = MDGUIModelViewMatrix();
	MDMatrixTranslate(&matrix, frame.x, frame.y, 0);
	glUniformMatrix4fv(MDGUIProgramLocations()[MD_PROGRAM_MODELVIEWPROJECTION], 1, NO, (MDGUIProjectionMatrix() * matrix).data);
	
	glUniform1i(MDGUIProgramLocations()[MD_PROGRAM_ENABLETEXTURES], 0);
	glUniform1i(MDGUIProgramLocations()[MD_PROGRAM_ENABLENORMALS], 0);
	
	if (strokeSize > 0.01)
	{
		glBindVertexArray(strokeVao[0]);
		glVertexAttrib4d(1, [ strokeColor redComponent ], [ strokeColor greenComponent ], [ strokeColor	blueComponent ], [ strokeColor alphaComponent ]);
		glDrawArrays(GL_TRIANGLE_STRIP, 0, 82);
	}
	
	glBindVertexArray(vao[0]);
	float add = !enabled ? -0.3 : 0.0;
	float mult = down ? 0.7 : 1;
	NSColor* color = background;
	if (state)
		color = selectionColor;
	glVertexAttrib4d(1, [ color redComponent ] * mult + add, [ color greenComponent ] * mult + add, [ color blueComponent ] * mult + add, [ color alphaComponent ]);
	glDrawArrays(GL_TRIANGLE_FAN, 0, 42);
	if (state)
	{
		glBindVertexArray(checkVao[0]);
		color = checkColor;
		glVertexAttrib4d(1, [ color redComponent ] * mult + add, [ color greenComponent ] * mult + add, [ color blueComponent ] * mult + add, [ color alphaComponent ]);
		glDrawArrays(GL_TRIANGLES, 0, 12);
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
		((void (*)(id, SEL))[ target methodForSelector:action ])(target, action);
	fpsCounter++;
	if (fpsCounter >= 3600)
		fpsCounter -= 3600;
}

@end
