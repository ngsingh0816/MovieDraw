//
//  MDButton.m
//  MovieDraw
//
//  Created by MILAP on 7/9/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MDButton.h"

@implementation MDButton

+ (instancetype) mdButton
{
	MDButton* view = [ [ MDButton alloc ] init ];
	return view;
}

+ (instancetype) mdButtonWithFrame: (MDRect)rect background: (NSColor*)bkg;
{
	MDButton* view = [ [ MDButton alloc ] initWithFrame:rect background:bkg  ];
	return view;
}

- (instancetype) init
{
	if ((self = [ super init ]))
	{
		background = MD_BUTTON_DEFAULT_BUTTON_COLOR;
		radius = 10;
		strokeSize = 2;
		return self;
	}
	return nil;
}

- (instancetype) initWithFrame: (MDRect)rect background: (NSColor*)bkg;
{
	if ((self = [ super initWithFrame:rect background:bkg ]))
	{
		radius = 10;
		strokeSize = 2;
		return self;
	}
	return nil;
}

- (void) setFrame:(MDRect)rect
{
	[ super setFrame:rect ];
	
	// Check glStr
	if ([ glStr frameSize ].width > frame.width || [ glStr frameSize ].height > frame.height)
	{
		NSSize size = [ glStr frameSize ];
		if (size.width > frame.width)
			size.width = frame.width;
		if (size.height > frame.height)
			size.height = frame.height;
		[ glStr useStaticFrame:size ];
	}
	else
		[ glStr useDynamicFrame ];
}

- (void) setEnabled:(BOOL)en
{
	if (enabled != en)
		updateVAO = TRUE;
	[ super setEnabled:en ];
}

- (void) mouseDown: (NSEvent*)event
{
	if (!visible || !enabled || (parentView && ![ parentView visible ]))
		return;
	down = FALSE;
	up = TRUE;
	NSPoint point = [ event locationInWindow ];
	point.x -= origin.x;
	point.y -= origin.y;
	point.x *= resolution.width / windowSize.width;
	point.y *= resolution.height / windowSize.height;
	point.y += 2;
	
	/*if (point.x >= frame.x && point.x <= frame.x + frame.width &&
		point.y >= frame.y && point.y <= frame.y + frame.height)*/
	
	if (MDPointInRadius(frame, radius, point))
	{
		down = TRUE;
		up = FALSE;
		realDown = TRUE;
		if (continuous && target != nil)
			((void (*)(id, SEL, id))[ target methodForSelector:action ])(target, action, self);
	}
		
}

- (void) mouseDragged:(NSEvent *)event
{
	if (!visible || !enabled || up || (parentView && ![ parentView visible ]))
		return;
		
	NSPoint point = [ event locationInWindow ];
	point.x -= origin.x;
	point.y -= origin.y;
	point.x *= resolution.width / windowSize.width;
	point.y *= resolution.height / windowSize.height;
	point.y += 2;
	
	down = FALSE;
	/*if (point.x >= frame.x && point.x <= frame.x + frame.width &&
		point.y >= frame.y && point.y <= frame.y + frame.height)*/
	if (realDown && MDPointInRadius(frame, radius, point))
		down = TRUE;
}

- (void) mouseUp:(NSEvent *)event
{
	if (!visible || !enabled || (parentView && ![ parentView visible ]))
		return;

	NSPoint point = [ event locationInWindow ];
	point.x -= origin.x;
	point.y -= origin.y;
	point.x *= resolution.width / windowSize.width;
	point.y *= resolution.height / windowSize.height;
	point.y += 2;
	
	down = FALSE;
	//if (point.x >= frame.x && point.x <= frame.x + frame.width &&
	//	point.y >= frame.y && point.y <= frame.y + frame.height)
	if (realDown && MDPointInRadius(frame, radius, point))
		down = TRUE;
		
	if ([ event clickCount ] != 2 || ![ target respondsToSelector:doubleAction ])
	{
		if (down && target != nil && !continuous && [ target respondsToSelector:action ])
			((void (*)(id, SEL, id))[ target methodForSelector:action ])(target, action, self);
	}
	else
	{
		if (down && target != nil && !continuous && [ target respondsToSelector:doubleAction ])
			((void (*)(id, SEL, id))[ target methodForSelector:doubleAction ])(target, doubleAction, self);
	}
	down = FALSE;
	up = TRUE;
	realDown = FALSE;
}

- (void) drawView
{
	if (!visible || (parentView && ![ parentView visible ]))
		return;
	
	if (!vao[0] || updateVAO)
	{
		MDDeleteVAO(vao);
		MDDeleteVAO(strokeVao);
		
		MDCreateRoundedRectVAO(frame, radius, vao);
		MDCreateStrokeVAO(frame, radius, strokeSize, strokeVao);
		
		glBindVertexArray(0);
		
		updateVAO = FALSE;
	}
	
	MDMatrix matrix = MDGUIModelViewMatrix();
	MDMatrixTranslate(&matrix, frame.x, frame.y, 0);
	glUniformMatrix4fv(MDGUIProgramLocations()[MD_PROGRAM_MODELVIEWPROJECTION], 1, NO, (MDGUIProjectionMatrix() * matrix).data);
	
	glUniform1i(MDGUIProgramLocations()[MD_PROGRAM_ENABLETEXTURES], 0);
	glUniform1i(MDGUIProgramLocations()[MD_PROGRAM_ENABLENORMALS], 0);
	
	glBindVertexArray(strokeVao[0]);
	glVertexAttrib4d(1, [ strokeColor redComponent ], [ strokeColor greenComponent ], [ strokeColor blueComponent ], [ strokeColor alphaComponent ]);
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 82);
	
	glBindVertexArray(vao[0]);
	if (down)
	{
		const float mult = 0.7;
		glVertexAttrib4d(1, [ background redComponent ] * mult, [ background greenComponent ] * mult, [ background blueComponent ] * mult, [ background alphaComponent ]);
	}
	else
	{
		float add = !enabled ? -0.3 : 0.0;
		glVertexAttrib4d(1, [ background redComponent ] + add, [ background greenComponent ] + add, [ background blueComponent ] + add, [ background alphaComponent ]);
	}
	glBindVertexArray(vao[0]);
	glDrawArrays(GL_TRIANGLE_FAN, 0, 42);
	
	glUniformMatrix4fv(MDGUIProgramLocations()[MD_PROGRAM_MODELVIEWPROJECTION], 1, NO, (MDGUIProjectionMatrix() * MDGUIModelViewMatrix()).data);
	
	if (!glStr)
		glStr = LoadString(text, textColor, textFont);
	DrawString(glStr, NSMakePoint(frame.x + (frame.width / 2), frame.y + (frame.height / 2)),
			   NSCenterTextAlignment, 0);
	
	if (continuous && down && target != nil && [ target respondsToSelector:action ] &&
		(fpsCounter % ccount) == 0)
		((void (*)(id, SEL))[ target methodForSelector:action ])(target, action);
	fpsCounter++;
	if (fpsCounter >= 3600)
		fpsCounter -= 3600;
}

@end
