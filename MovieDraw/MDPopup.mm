//
//  MDPopup.mm
//  MovieDraw
//
//  Created by MILAP on 12/14/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MDPopup.h"
#import "MDButton.h"
#import "MDScrollView.h"
#import "MDMenu.h"

@interface MDPopup (Internal)

- (void) buttonPressed: (id) sender;

@end


@implementation MDPopup

+ (MDPopup*) mdPopup
{
	return [ [ MDPopup alloc ] init ];
}

+ (MDPopup*) mdPopupWithFrame: (MDRect)rect background: (NSColor*)bkg
{	
	return [ [ MDPopup alloc ] initWithFrame:rect background:bkg ];
}

- (instancetype) init
{
	if ((self = [ super init ]))
	{
		titems = [ [ NSMutableArray alloc ] init ];
		strings = [ [ NSMutableArray alloc ] init ];
		
		radius = 10;
		strokeSize = 2;
		
		triangleColor = MD_POPUP_DEFAULT_TRIANGLE_COLOR;
		return self;
	}
	return nil;
}

- (instancetype) initWithFrame:(MDRect)rect background:(NSColor *)bkg
{
	if ((self = [ super initWithFrame:rect background:bkg ]))
	{
		titems = [ [ NSMutableArray alloc ] init ];
		strings = [ [ NSMutableArray alloc ] init ];
		
		radius = 10;
		strokeSize = 2;
		
		triangleColor = MD_POPUP_DEFAULT_TRIANGLE_COLOR;
		return self;
	}
	return nil;
}

- (void) setTriangleColor:(NSColor*)color
{
	triangleColor = color;
}

- (NSColor*) triangleColor
{
	return triangleColor;
}

- (void) addItem:(NSString*)str
{
	[ titems addObject:str ];
	[ strings addObject:LoadString(str, textColor, textFont)];
}

- (void) removeItem: (NSString*)str
{
	unsigned long objIndex = [ titems indexOfObject:str ];
	[ titems removeObject:str ];
	[ strings removeObjectAtIndex:objIndex ];
}

- (unsigned long) numberOfItems
{
	return [ titems count ];
}

- (NSString*) itemAtIndex:(unsigned long)index
{
	if (index >= [ titems count ])
		return nil;
	return titems[index];
}

- (void) selectItem: (unsigned long)item
{
	if (item >= [ titems count ])
		return;
	selectedItem = item;
	if (target && [ target respondsToSelector:action ])
		((void (*)(id, SEL, id))[ target methodForSelector:action ])(target, action, self);
}

- (unsigned long) selectedItem
{
	return selectedItem;
}

- (NSString*) stringValue
{
	return titems[selectedItem];
}

- (void) drawView
{
	if (!visible)
		return;
	
	/*if (changed)
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
			
			NSColor* color = MD_POPUP_DEFAULT_COLOR;
			colors[(z * 4)] = [ color redComponent ] + add;
			colors[(z * 4) + 1] = [ color greenComponent ] + add;
			colors[(z * 4) + 2] = [ color blueComponent ] + add;
			colors[(z * 4) + 3] = [ color alphaComponent ];;
			
			NSColor* bcolor = MD_POPUP_DEFAULT_BORDER_COLOR;
			bcolors[(z * 4)] = [ bcolor redComponent ];
			bcolors[(z * 4) + 1] = [ bcolor greenComponent ];
			bcolors[(z * 4) + 2] = [ bcolor blueComponent ];
			bcolors[(z * 4) + 3] = [ bcolor alphaComponent ];
		}
		changed = FALSE;
	}*/
	
	/*glLoadIdentity();
	
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_COLOR_ARRAY);
	
	glVertexPointer(2, GL_FLOAT, 0, bverticies);
	glColorPointer(4, GL_FLOAT, 0, bcolors);
	glDrawArrays(GL_TRIANGLE_FAN, 0, 41);
	
	glVertexPointer(2, GL_FLOAT, 0, verticies);
	glColorPointer(4, GL_FLOAT, 0, colors);
	glDrawArrays(GL_TRIANGLE_FAN, 0, 41);
	
	glLoadIdentity();
	glTranslated(frame.x, frame.y + (frame.height / 2) - 0.5, 0);
	NSColor* color = MD_POPUP_DEFAULT_COLOR;
	glBegin(GL_QUADS);
	{
		glColor4d([ color redComponent ], [ color greenComponent ], [ color blueComponent ], [ color alphaComponent ]);
		glVertex2d(frame.width, (frame.height / 2) - 3);
		glVertex2d(0, (frame.height / 2) - 3);
		color = MD_POPUP_DEFAULT_COLOR2;
		glColor4d([ color redComponent ], [ color greenComponent ], [ color blueComponent ], [ color alphaComponent ]);
		glVertex2d(0, 0);
		glVertex2d(frame.width, 0);
		
		glVertex2d(0, 0);
		glVertex2d(frame.width, 0);
		color = MD_POPUP_DEFAULT_COLOR;
		glColor4d([ color redComponent ], [ color greenComponent ], [ color blueComponent ], [ color alphaComponent ]);
		glVertex2d(frame.width, -(frame.height / 2) + 4);
		glVertex2d(0, -(frame.height / 2) + 4);
	}
	glEnd();
	
	glLoadIdentity();
	glTranslated(frame.x + frame.width - 10, frame.y + (frame.height / 2), 0);
	glColor4d(0.32549, 0.32549, 0.32549, 1);
	glBegin(GL_TRIANGLES);
	{
		glVertex2d(0, 6);
		glVertex2d(3, 2);
		glVertex2d(-3, 2);
		
		glVertex2d(0, -6);
		glVertex2d(3, -2);
		glVertex2d(-3, -2);
	}
	glEnd();
	
	glLoadIdentity();*/
	
	if (!vao[0] || updateVAO)
	{
		MDDeleteVAO(vao);
		MDDeleteVAO(strokeVao);
		MDDeleteVAO(triangleVao);
		
		MDCreateRoundedRectVAO(frame, radius, vao);
		MDCreateStrokeVAO(frame, radius, strokeSize, strokeVao);
		
		float square[6 * 3];
		square[0] = 0 + frame.width - 10;
		square[1] = 0 + (frame.height / 2) + 6;
		square[2] = 0;
		
		square[3] = 0 + frame.width - 10 + 3;
		square[4] = 0 + (frame.height / 2) + 2;
		square[5] = 0;
		
		square[6] = 0 + frame.width - 10 - 3;
		square[7] = 0 + (frame.height / 2) + 2;
		square[8] = 0;
		
		square[9] = 0 + frame.width - 10;
		square[10] = 0 + (frame.height / 2) - 6;
		square[11] = 0;
		
		square[12] = 0 + frame.width - 10 + 3;
		square[13] = 0 + (frame.height / 2) - 2;
		square[14] = 0;
		
		square[15] = 0 + frame.width - 10 - 3;
		square[16] = 0 + (frame.height / 2) - 2;
		square[17] = 0;
		
		glGenVertexArrays(1, &triangleVao[0]);
		glBindVertexArray(triangleVao[0]);
		
		glGenBuffers(1, &triangleVao[1]);
		glBindBuffer(GL_ARRAY_BUFFER, triangleVao[1]);
		glBufferData(GL_ARRAY_BUFFER, 6 * 3 * sizeof(float), square, GL_STATIC_DRAW);
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
	
	glBindVertexArray(strokeVao[0]);
	glVertexAttrib4d(1, [ strokeColor redComponent ], [ strokeColor greenComponent ], [ strokeColor blueComponent ], [ strokeColor alphaComponent ]);
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 82);
	
	glBindVertexArray(vao[0]);
	float add = !enabled ? -0.3 : 0.0;
	float mult = ([ popUp visible ] ? 0.7 : 1);
	glVertexAttrib4d(1, [ background redComponent ] * mult + add, [ background greenComponent ] * mult + add, [ background blueComponent ] * mult + add, [ background alphaComponent ]);
	glDrawArrays(GL_TRIANGLE_FAN, 0, 42);
	
	glBindVertexArray(triangleVao[0]);
	glVertexAttrib4d(1, [ triangleColor redComponent ] + add, [ triangleColor greenComponent ] + add, [ triangleColor blueComponent ] + add, [ triangleColor alphaComponent ]);
	glDrawArrays(GL_TRIANGLES, 0, 6);
	
	if (selectedItem <= [ titems count ])
	{
		DrawString(strings[selectedItem], NSMakePoint(frame.x + 3, frame.y + (frame.height / 2)), NSLeftTextAlignment, 0);
	}
	
	glUniformMatrix4fv(MDGUIProgramLocations()[MD_PROGRAM_MODELVIEWPROJECTION], 1, NO, (MDGUIProjectionMatrix() * MDGUIModelViewMatrix()).data);
	
	/*glDisableClientState(GL_VERTEX_ARRAY);
	glDisableClientState(GL_COLOR_ARRAY);*/
}

- (void) popupItemChosen:(MDMenuItem*) sender
{
	[ self selectItem:[ titems indexOfObject:[ sender text ] ] ];
	popUp = nil;
}

- (void) menuFinished: (id)sender
{
	popUp = nil;
}

- (void) mouseDown:(NSEvent *)event
{
	if (!visible || !enabled || [ views containsObject:popUp ])
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
		down = TRUE;
		up = FALSE;
		realDown = TRUE;
		
		if ([ strings count ] == 0)
			return;
		
		NSMutableArray* array = [ NSMutableArray array ];
		for (unsigned long z = 0; z < [ strings count ]; z++)
		{
			[ array addObject:[ MDMenuItem menuItemWithString:[ [ (GLString*)strings[z] string ] string ] target:self action:@selector(popupItemChosen:) ] ];
		}
		
		float height = [ strings[selectedItem] frameSize ].height;
		popUp = MDCreatePopupMenu(array, NSMakePoint(frame.x - 10, frame.y + frame.height + (height * selectedItem)), frame.width);
		[ popUp setTarget:self ];
		[ popUp setAction:@selector(menuFinished:) ];
		[ popUp expandItem:(unsigned int)selectedItem ];
	}
}

- (void) mouseDragged: (NSEvent*)event
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
	if (!(point.x >= frame.x && point.x <= frame.x + frame.width &&
		  point.y >= frame.y && point.y <= frame.y + frame.height))
		down = up;
	else
		down = !up;
}

- (void) mouseUp: (NSEvent*)event
{
	if (!visible || !enabled)
		return;
	down = FALSE;
	up = TRUE;
	realDown = FALSE;
}

- (void) dealloc
{
	MDDeleteVAO(triangleVao);
}

@end
