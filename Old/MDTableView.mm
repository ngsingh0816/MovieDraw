//
//  MDTableView.mm
//  MovieDraw
//
//  Created by MILAP on 9/23/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MDTableView.h"
#import "MDButton.h"

@implementation MDTableView

+ (id) mdTableView
{
	return [ [ [ MDTableView alloc ] init ] autorelease ];
}

+ (id) mdTableViewWithFrame: (MDRect)rect background: (NSColor*)bkg
{
	return [ [ [ MDTableView alloc ] initWithFrame:rect background:bkg ] autorelease ];
}

- (id) init
{
	if ((self = [ super init ]))
	{
		headers = [ [ NSMutableArray alloc ] init ];
		headerStrings = [ [ NSMutableArray alloc ] init ];
		objects = [ [ NSMutableArray alloc ] init ];
		objectStrings = [ [ NSMutableArray alloc ] init ];
		objectImages = [ [ NSMutableArray alloc ] init ];
		selRow = -1;
		enableNoSel = FALSE;
		selColor[0] = [ [ NSColor colorWithDeviceRed:0.6 green:0.6 blue:1
													 alpha:1 ] retain ];
		selColor[1] = [ [ NSColor colorWithDeviceRed:0.5 green:0.5 blue:1
													 alpha:1 ] retain ];
		selColor[2] = [ [ NSColor colorWithDeviceRed:0.4 green:0.4 blue:1
													 alpha:1 ] retain ];
		selColor[3] = [ [ NSColor colorWithDeviceRed:0.3 green:0.3 blue:1
													 alpha:1 ] retain ];
		if (textFont)
		{
			[ textFont release ];
			textFont = [ [ NSFont systemFontOfSize:11 ] retain ];
		}
	}
	return self;
}

- (id) initWithFrame: (MDRect)rect background: (NSColor*)bkg
{
	if ((self = [ super initWithFrame:rect background:bkg ]))
	{
		headers = [ [ NSMutableArray alloc ] init ];
		headerStrings = [ [ NSMutableArray alloc ] init ];
		objects = [ [ NSMutableArray alloc ] init ];
		objectStrings = [ [ NSMutableArray alloc ] init ];
		objectImages = [ [ NSMutableArray alloc ] init ];
		selRow = -1;
		enableNoSel = FALSE;
		selColor[0] = [ [ NSColor colorWithDeviceRed:0.6 green:0.6 blue:1
													 alpha:[ bkg alphaComponent ] ] retain ];
		selColor[1] = [ [ NSColor colorWithDeviceRed:0.5 green:0.5 blue:1
													 alpha:[ bkg alphaComponent ] ] retain ];
		selColor[2] = [ [ NSColor colorWithDeviceRed:0.4 green:0.4 blue:1
													 alpha:[ bkg alphaComponent ] ] retain ];
		selColor[3] = [ [ NSColor colorWithDeviceRed:0.3 green:0.3 blue:1
													 alpha:[ bkg alphaComponent ] ] retain ];
		
		if (textFont)
		{
			[ textFont release ];
			textFont = [ [ NSFont systemFontOfSize:11 ] retain ];
		}
		
		[ self addHeader:@"Header" ];
		NSSize headSize = [ [ headerStrings lastObject ] frameSize ];
		[ self removeHeader:@"Header" ];
		
		[ self setScrollOffset:headSize.height ];
	}
	return self;
}

- (unsigned int) numberOfRows
{
	return (unsigned int)[ objects count ];
}

- (void) setFrame:(MDRect)rect
{
    [ super setFrame:rect ];
	
	if ([ objects count ] != 0)
	{
		NSSize headSize = [ [ headerStrings objectAtIndex:0 ] frameSize ];
		[ self setMaxScroll:NSMakeSize(0, (headSize.height * ([ objectStrings count ] + 1)) - frame.height) ];
	}
}

- (void) setClickTarget: (id) ctar
{
	if (selTar)
		[ selTar release ];
	selTar = [ ctar retain ];
}

- (void) setSingleClickAction: (SEL)ssel
{
	singleClick = ssel;
}

- (void) setDoubleClickAction: (SEL)dsel
{
	doubleClick = dsel;
}

- (id) clickTarget
{
	return selTar;
}

- (SEL) singleClickAction
{
	return singleClick;
}

- (SEL) doubleClickAction
{
	return doubleClick;
}

- (void) addHeader: (NSString*)title
{
	[ headers addObject:title ];
	[ headerStrings addObject:[ LoadString(title, textColor, textFont) autorelease ] ];
}

- (void) removeHeader: (NSString*)title
{
	for (int z = 0; z < [ headers count ]; z++)
	{
		if ([ [ headers objectAtIndex:z ] isEqualToString:title ])
		{
			[ headers removeObjectAtIndex:z ];
			[ headerStrings removeObjectAtIndex:z ];
			break;
		}
	}
}

- (void) removeAllHeaders
{
	[ self removeAllRows ];
	[ headers removeAllObjects ];
	[ headerStrings removeAllObjects ];
}

- (void) setImage: (unsigned int) image atIndex:(unsigned int)index
{
	if (index >= [ objectImages count ])
		return;
	[ objectImages replaceObjectAtIndex:index withObject:[ NSNumber numberWithInt:image ] ];
}

- (unsigned int) imageAtIndex:(unsigned int)index
{
	if (index >= [ objectImages count ])
		return 0;
	return [ [ objectImages objectAtIndex:index ] intValue ];
}

- (void) addRow: (NSDictionary*)obj
{
	[ objectImages addObject:[ NSNumber numberWithInt:0 ] ];
	[ objects addObject:obj ];
	NSMutableDictionary* dict = [ [ NSMutableDictionary alloc ] init ];
	for (int z = 0; z < [ headers count ]; z++)
	{
		if ([ obj objectForKey:[ headers objectAtIndex:z ] ] == nil)
			continue;
		NSMutableString* str = [ [ NSMutableString alloc ] initWithString:
								[ obj objectForKey:[ headers objectAtIndex:z ] ] ];
		[ str replaceOccurrencesOfString:@"\r" withString:@"" options:0
								   range:NSMakeRange(0, [ str length ]) ];
		[ str replaceOccurrencesOfString:@"\n" withString:@"" options:0
								   range:NSMakeRange(0, [ str length ]) ];
		[ str replaceOccurrencesOfString:@"\t" withString:@"" options:0
								   range:NSMakeRange(0, [ str length ]) ];
		
		NSDictionary* d = [ NSDictionary dictionaryWithObject:
			LoadString(str, textColor, textFont) forKey:[ headers objectAtIndex:z ] ];
		[ dict addEntriesFromDictionary:d ];
		[ str release ];
	}
	[ objectStrings addObject:dict ];
	[ dict release ];
	dict = nil;
	
	NSSize headSize = [ [ headerStrings objectAtIndex:0 ] frameSize ];
	[ self setMaxScroll:NSMakeSize(0,
			(headSize.height * ([ objectStrings count ] + 1)) - frame.height) ];
}

- (void) insertRow:(NSDictionary*) obj atIndex: (unsigned int)row
{
	[ objects insertObject:obj atIndex:row ];
	NSMutableDictionary* dict = [ [ NSMutableDictionary alloc ] init ];
	for (int z = 0; z < [ headers count ]; z++)
	{
		if ([ obj objectForKey:[ headers objectAtIndex:z ] ] == nil)
			continue;
		NSDictionary* d = [ NSDictionary dictionaryWithObject:
			LoadString([ obj objectForKey:[ headers objectAtIndex:z ] ], textColor, textFont)
											forKey:[ headers objectAtIndex:z ] ];
		[ dict addEntriesFromDictionary:d ];
	}
	[ objectStrings insertObject:dict atIndex:row ];
	[ dict release ];
	
	NSSize headSize = [ [ headerStrings objectAtIndex:0 ] frameSize ];
	[ self setMaxScroll:NSMakeSize(0,
			(headSize.height * ([ objectStrings count ] + 1)) - frame.height) ];
}

- (void) removeRow: (unsigned int) row
{
	if (row >= [ objects count ])
		return;
	
	[ objects removeObjectAtIndex:row ];
	[ objectStrings removeObjectAtIndex:row ];
	[ objectImages removeObjectAtIndex:row ];
	
	NSSize headSize = [ [ headerStrings objectAtIndex:0 ] frameSize ];
	[ self setMaxScroll:NSMakeSize(0,
			(headSize.height * ([ objectStrings count ] + 1)) - frame.height) ];
}

- (void) removeAllRows
{
	[ objects removeAllObjects ];
	[ objectStrings removeAllObjects ];
	[ objectImages removeAllObjects ];
	selRow = -1;
	scroll.y = 0;
	
	NSSize headSize = [ [ headerStrings objectAtIndex:0 ] frameSize ];
	[ self setMaxScroll:NSMakeSize(0,
		(headSize.height * ([ objectStrings count ] + 1)) - frame.height)];
}

- (NSDictionary*) objectAtRow: (unsigned int) row
{
	if (row >= [ objects count ])
		return nil;
	return [ objects objectAtIndex:row ];
}

- (BOOL) rowIsVisible: (unsigned int)row
{
	if (row >= [ objects count ])
		return FALSE;
	
	float height = [ [ headerStrings objectAtIndex:0 ] frameSize ].height;
	if (frame.y + frame.height - (height * (row + 1)) + scroll.y < frame.y ||
		frame.y + frame.height - (height * (row + 1)) + scroll.y 
		> frame.y + frame.height + 2)
		return FALSE;
	return TRUE;
}

- (int) selectedRow
{
	return selRow;
}

- (void) selectRow: (int) row
{
	if (row >= [ objects count ])
		return;
	selRow = row;
}

- (void) keyDown: (NSEvent*)event
{
	[ super keyDown:event ];
	keyDown = TRUE;
	
	switch ([ [ event characters ] characterAtIndex:0 ])
	{
		case NSUpArrowFunctionKey:
		{
			if (selRow == -1)
				break;
			
			if (selRow == 0)
				selRow = (int)[ objectStrings count ] - 1;
			else
				selRow--;
			
			NSSize headSize = [ [ headerStrings objectAtIndex:0 ] frameSize ];
			if (frame.height - (headSize.height * (selRow + 2)) + scroll.y < 0)
				scroll.y += -(frame.height - (headSize.height * (selRow + 2)) + scroll.y);
			else if (-(headSize.height * selRow) + scroll.y > 0)
				scroll.y -= (-(headSize.height * selRow) + scroll.y);
			
			if (selTar && [ selTar respondsToSelector:singleClick ])
				[ selTar performSelector:singleClick withObject:self ];
			break;
		}
		case NSDownArrowFunctionKey:
		{
			if (selRow == -1)
				break;
			
			if (selRow == [ objectStrings count ] - 1)
				selRow = 0;
			else
				selRow++;
			
			NSSize headSize = [ [ headerStrings objectAtIndex:0 ] frameSize ];
			if (frame.height - (headSize.height * (selRow + 2)) + scroll.y < 0)
				scroll.y += -(frame.height - (headSize.height * (selRow + 2)) + scroll.y);
			else if (-(headSize.height * selRow) + scroll.y > 0)
				scroll.y -= (-(headSize.height * selRow) + scroll.y);
			
			if (selTar && [ selTar respondsToSelector:singleClick ])
				[ selTar performSelector:singleClick withObject:self ];
			break;
		}
		case NSCarriageReturnCharacter:
		case NSEnterCharacter:
		case NSNewlineCharacter:
		{
			if (selRow == -1)
				break;
			
			if (selTar && [ selTar respondsToSelector:doubleClick ])
				[ selTar performSelector:doubleClick withObject:self ];
		}
	}
}

- (NSSize) frameSize
{
	NSSize headSize = [ [ headerStrings objectAtIndex:0 ] frameSize ];
	return NSMakeSize(frame.width / [ headers count ], headSize.height);
}

- (void) keyUp:(NSEvent *)event
{
	[ super keyUp:event ];
	keyDown = FALSE;
}

- (void) mouseDown:(NSEvent*)event
{
	[ super mouseDown:event ];
	
	if (![ self mouseDown ])
		return;
	
	NSPoint mouse = [ event locationInWindow ];
	mouse.x -= origin.x;
	mouse.y -= origin.y;
	mouse.x *= resolution.width / windowSize.width;
	mouse.y *= resolution.height / windowSize.height;
	
	if (mouse.x >= frame.x + frame.width - 7 && mouse.x <= frame.x + frame.width && 
		mouse.y >= frame.y && mouse.y <= frame.y + frame.height - scrollOffset && fadeAlpha > 0.0)
		return;
	
	if ([ headers count ] == 0)
		return;
	
	NSSize headSize = [ [ headerStrings objectAtIndex:0 ] frameSize ];
	
	if (!(mouse.x >= frame.x && mouse.x <= frame.x + frame.width &&
		mouse.y >= frame.y && mouse.y <= frame.y + frame.height - headSize.height))
		return;
	
	mouse.x -= frame.x;
	mouse.y -= frame.y - 2;
	mouse.y = round(mouse.y);

	if (enableNoSel)
		selRow = -1;
	bool caught = false;
	for (int z = 0; z < [ objects count ]; z++)
	{
		if (mouse.y <= frame.height - (headSize.height * (z + 1)) + scroll.y &&
			mouse.y >= frame.height - (headSize.height * (z + 2)) + scroll.y)
		{
			caught = true;
			selRow = z;
			if (frame.y + frame.height - (headSize.height * (selRow + 2)) + scroll.y
				< frame.y)
				scroll.y += -(frame.height - (headSize.height * (selRow + 2)) + scroll.y);
			else if (frame.y + frame.height - (headSize.height * selRow) + scroll.y
					 > frame.y + frame.height)
				scroll.y -= (-(headSize.height * selRow) + scroll.y);			
			break;
		}
	}
	if (selRow == -1 || !caught)
		return;
	
	if (frame.height - (headSize.height * (selRow + 2)) + scroll.y
		< 0)
		scroll.y += -(frame.height - (headSize.height * (selRow + 2)) + scroll.y);
	else if (-(headSize.height * selRow) + scroll.y
			 > 0)
		scroll.y -= (-(headSize.height * selRow) + scroll.y);
	
	if ([ event clickCount ] == 2 && selTar && [ selTar respondsToSelector:doubleClick ])
		[ selTar performSelector:doubleClick withObject:self ];
	else if (selTar && [ selTar respondsToSelector:singleClick ])
		[ selTar performSelector:singleClick withObject:self ];
}

- (void) mouseDragged:(NSEvent*)event
{
	[ super mouseDragged:event ];
	
	if (!realDown || thisDown)
		return;
	
	if (![ self mouseDown ])
		return;
	NSPoint mouse = [ event locationInWindow ];
	mouse.x -= origin.x;
	mouse.y -= origin.y;
	mouse.x *= resolution.width / windowSize.width;
	mouse.y *= resolution.height / windowSize.height;
	
	if (mouse.x >= frame.x + frame.width - 7 && mouse.x <= frame.x + frame.width && 
		mouse.y >= frame.y && mouse.y <= frame.y + frame.height - scrollOffset && fadeAlpha > 0.0)
	{
		realDown = FALSE;
		return;
	}
	
	if (mouse.y < frame.y)
		return;
	if (mouse.y >= frame.y + frame.height)
		return;
	
	if ([ headers count ] == 0)
		return;
	
	NSSize headSize = [ [ headerStrings objectAtIndex:0 ] frameSize ];
	
	if (!(mouse.x >= frame.x && mouse.x <= frame.x + frame.width &&
		  mouse.y >= frame.y && mouse.y <= frame.y + frame.height - headSize.height))
		return;
	
	mouse.x -= frame.x;
	mouse.y -= frame.y - 2;
	mouse.y = round(mouse.y);

	if (enableNoSel)
		selRow = -1;
	bool caught = false;
	for (int z = 0; z < [ objects count ]; z++)
	{
		if (mouse.y <= frame.height - (headSize.height * (z + 1)) + scroll.y &&
			mouse.y >= frame.height - (headSize.height * (z + 2)) + scroll.y)
		{
			caught = true;
			selRow = z;
			break;
		}
	}
	if (selRow == -1 || !caught)
		return;
	
	if (frame.height - (headSize.height * (selRow + 2)) + scroll.y
		< 0)
		scroll.y += -(frame.height - (headSize.height * (selRow + 2)) + scroll.y);
	else if (-(headSize.height * selRow) + scroll.y
			 > 0)
		scroll.y -= (-(headSize.height * selRow) + scroll.y);
	
	if (selTar && [ selTar respondsToSelector:singleClick ])
		[ selTar performSelector:singleClick withObject:self ];
}

- (BOOL) enableNoSelection
{
	return enableNoSel;
}

- (void) setNoSelectionEnabled: (BOOL)en
{
	enableNoSel = en;
}

- (void) setSelectionColor: (NSColor*)col atIndex: (unsigned int) index
{
	if (index >= 4)
		return;
	if (selColor[index])
		[ selColor[index] release ];
	selColor[index] = [ col retain ];
}

- (NSColor*) selectionColorAtIndex: (unsigned int) index
{
	if (index >= 4)
		return nil;
	return selColor[index];
}

- (void) drawView
{
	if (!visible)
		return;
	
	if ([ headers count ] == 0)
	{
		[ super drawView ];
		return;
	}
	
	NSSize headSize = [ [ headerStrings objectAtIndex:0 ] frameSize ];
	float square[8];
	square[0] = frame.x;
	square[1] = frame.y + frame.height - headSize.height;
	square[2] = frame.x + frame.width;
	square[3] = frame.y + frame.height - headSize.height;
	square[4] = frame.x;
	square[5] = frame.y + frame.height;
	square[6] = frame.x + frame.width;
	square[7] = frame.y + frame.height;
	
	float colors[16];
	for (int z = 0; z < 4; z++)
	{
		float add = !enabled ? -0.3 : 0.0;
		colors[(z * 4)] = [ background[z] redComponent ] + add - 0.2;
		colors[(z * 4) + 1] = [ background[z] greenComponent ] + add - 0.2;
		colors[(z * 4) + 2] = [ background[z] blueComponent ] + add - 0.2;
		colors[(z * 4) + 3] = [ background[z] alphaComponent ];
	}
	
	glLoadIdentity();
	glVertexPointer(2, GL_FLOAT, 0, square);
	glEnableClientState(GL_VERTEX_ARRAY);
	glColorPointer(4, GL_FLOAT, 0, colors);
	glEnableClientState(GL_COLOR_ARRAY);
	
	// Draw
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	
	glDisableClientState(GL_VERTEX_ARRAY);
	glDisableClientState(GL_COLOR_ARRAY);
	
	NSSize cellBounds = NSMakeSize(frame.width / [ headers count ], headSize.height);
	for (int z = 0; z < [ headers count ]; z++)
	{
		glLoadIdentity();
		glColor4d(0, 0, 0, [ background[0] alphaComponent ]);
		glBegin(GL_LINES);
		{
			if (z != 0)
			{
				glVertex2d(frame.x + (cellBounds.width * z), frame.y + frame.height);
				glVertex2d(frame.x + (cellBounds.width * z),
					   frame.y + frame.height - cellBounds.height);
			}
		}
		glEnd();
		glLoadIdentity();
		
		DrawString([ headerStrings objectAtIndex:z ], NSMakePoint(frame.x + 
			(cellBounds.width * z) + 5, frame.y + frame.height -
					(cellBounds.height / 2)), NSLeftTextAlignment, 0);
	}
	
	if (selRow == -1 || 
		(frame.y + frame.height - (headSize.height * (selRow + 1)) + scroll.y) < frame.y)
	{
		float square2[8];
		square2[0] = frame.x;
		square2[1] = frame.y;
		square2[2] = frame.x + frame.width;
		square2[3] = frame.y;
		square2[4] = frame.x;
		square2[5] = frame.y + frame.height - headSize.height;
		square2[6] = frame.x + frame.width;
		square2[7] = frame.y + frame.height - headSize.height;
		
		float colors2[16];
		for (int z = 0; z < 4; z++)
		{
			float add = !enabled ? -0.3 : 0.0;
			colors2[(z * 4)] = [ background[z] redComponent ] + add;
			colors2[(z * 4) + 1] = [ background[z] greenComponent ] + add;
			colors2[(z * 4) + 2] = [ background[z] blueComponent ] + add;
			colors2[(z * 4) + 3] = [ background[z] alphaComponent ];
		}
		
		glLoadIdentity();
		glVertexPointer(2, GL_FLOAT, 0, square2);
		glEnableClientState(GL_VERTEX_ARRAY);
		glColorPointer(4, GL_FLOAT, 0, colors2);
		glEnableClientState(GL_COLOR_ARRAY);
		
		// Draw
		glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
		
		glDisableClientState(GL_VERTEX_ARRAY);
		glDisableClientState(GL_COLOR_ARRAY);
	}
	else
	{
		float square2[8];
		float tempHeight = frame.y + frame.height - (headSize.height *
													 (selRow + 2)) + scroll.y;
		if (tempHeight > frame.y + frame.height - headSize.height)
			tempHeight = frame.y + frame.height - headSize.height;
		else if (tempHeight < frame.y)
			tempHeight = frame.y;
		square2[0] = frame.x;
		square2[1] = frame.y;
		square2[2] = frame.x + frame.width;
		square2[3] = frame.y;
		square2[4] = frame.x;
		square2[5] = tempHeight;
		square2[6] = frame.x + frame.width;
		square2[7] = tempHeight;
		
		float colors2[16];
		for (int z = 0; z < 4; z++)
		{
			float add = !enabled ? -0.3 : 0.0;
			colors2[(z * 4)] = [ background[z / 2] redComponent ] + add;
			colors2[(z * 4) + 1] = [ background[z / 2] greenComponent ] + add;
			colors2[(z * 4) + 2] = [ background[z / 2] blueComponent ] + add;
			colors2[(z * 4) + 3] = [ background[z / 2] alphaComponent ];
		}
		
		float square3[8];
		float colors3[16];
		float square4[8];
		float colors4[16];
		float square5[8];
		BOOL need3 = TRUE;
		if (-(headSize.height * (selRow + 1)) + scroll.y < 0)
		{
			float tempHeight2 = frame.y + frame.height - 
			(headSize.height * (selRow + 1)) + scroll.y;
			float tempStart = frame.y + frame.height - 
			(headSize.height * (selRow + 2)) + scroll.y;
			if (tempHeight2 >= frame.y + frame.height - headSize.height)
			{
				tempHeight2 = frame.y + frame.height - headSize.height;
				need3 = FALSE;
			}
			else
			{
				if (tempStart < frame.y)
					tempStart = frame.y;
				
				square3[0] = frame.x;
				square3[1] = frame.y + frame.height - (headSize.height * 
													   (selRow + 1)) + scroll.y;
				square3[2] = frame.x + frame.width;
				square3[3] = frame.y + frame.height - (headSize.height *
													   (selRow + 1)) + scroll.y;
				square3[4] = frame.x;
				square3[5] = frame.y + frame.height - headSize.height;
				square3[6] = frame.x + frame.width;
				square3[7] = frame.y + frame.height - headSize.height;
			}
			for (int z = 0; z < 4; z++)
			{
				float add = !enabled ? -0.3 : 0.0;
				colors3[(z * 4)] = [ background[(z / 2) + 2] redComponent ] + add;
				colors3[(z * 4) + 1] = [ background[(z / 2) + 2] greenComponent ] + add;
				colors3[(z * 4) + 2] = [ background[(z / 2) + 2] blueComponent ] + add;
				colors3[(z * 4) + 3] = [ background[(z / 2) + 2] alphaComponent ];
			}
			
			square4[0] = frame.x;
			square4[1] = tempHeight2;
			square4[2] = frame.x + frame.width;
			square4[3] = tempHeight2;
			square4[4] = frame.x;
			square4[5] = tempStart;
			square4[6] = frame.x + frame.width;
			square4[7] = tempStart;
			
			for (int z = 0; z < 4; z++)
			{
				float add = !enabled ? -0.3 : 0.0;
				colors4[(z * 4)] = [ selColor[z] redComponent ] + add;
				colors4[(z * 4) + 1] = [ selColor[z] greenComponent ] + add;
				colors4[(z * 4) + 2] = [ selColor[z] blueComponent ] + add;
				colors4[(z * 4) + 3] = [ selColor[z] alphaComponent ];
			}
			
			square5[0] = frame.x + frame.width;
			square5[1] = tempHeight2;
			square5[2] = frame.x + frame.width;
			square5[3] = tempHeight2;
			square5[4] = frame.x + frame.width;
			square5[5] = tempStart;
			square5[6] = frame.x + frame.width;
			square5[7] = tempStart;
		}
		
		glLoadIdentity();
		glVertexPointer(2, GL_FLOAT, 0, square2);
		glEnableClientState(GL_VERTEX_ARRAY);
		glColorPointer(4, GL_FLOAT, 0, colors2);
		glEnableClientState(GL_COLOR_ARRAY);
		
		glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
		
		if (frame.y + frame.height - (headSize.height * (selRow + 1)) + scroll.y <
				frame.y + frame.height)
		{
			if (need3)
			{
				glVertexPointer(2, GL_FLOAT, 0, square3);
				glColorPointer(4, GL_FLOAT, 0, colors3);
				glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
			}
			
			glVertexPointer(2, GL_FLOAT, 0, square4);
			glColorPointer(4, GL_FLOAT, 0, colors4);
			glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
			
			glVertexPointer(2, GL_FLOAT, 0, square5);
			glColorPointer(4, GL_FLOAT, 0, colors3);
			glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
		}
		
		glDisableClientState(GL_VERTEX_ARRAY);
		glDisableClientState(GL_COLOR_ARRAY);
	}
	
	for (int z = 0; z < [ objectStrings count ]; z++)
	{
		if (frame.y + frame.height - (cellBounds.height * (z + 1)) + scroll.y < frame.y ||
			frame.y + frame.height - (cellBounds.height * (z + 1)) + scroll.y 
			> frame.y + frame.height + 2)
			continue;
		for (int y = 0; y < [ headers count ]; y++)
		{
			if ([ [ objectStrings objectAtIndex:z ] objectForKey:
				 [ headers objectAtIndex:y ] ] == nil)
				 continue;
			NSSize bounds = [ [ [ objectStrings objectAtIndex:z ] objectForKey:
								 [ headers objectAtIndex:y ] ] frameSize ];
			
			bool lower = frame.height - (cellBounds.height * (z + 2)) + scroll.y < 0;
			bool higher = -(cellBounds.height * z) + scroll.y > 2;
			bool hasStatic = [ [ [ objectStrings objectAtIndex:z ] objectForKey:
								[ headers objectAtIndex:y ] ] staticFrame ];
			
			float newHeight = 0;
			if (lower || higher || hasStatic)
			{
				if (higher)
				{
					[ [ [ objectStrings objectAtIndex:z ] objectForKey:
					   [ headers objectAtIndex:y ] ] setFromTop:YES ];
					[ [ [ objectStrings objectAtIndex:z ] objectForKey:
					   [ headers objectAtIndex:y ] ] useStaticFrame:NSMakeSize(
						bounds.width, cellBounds.height + (cellBounds.height * z) - scroll.y - 2) ];
					newHeight = cellBounds.height + (cellBounds.height * z) - scroll.y - 2;
				}
				else if (lower)
				{
					[ [ [ objectStrings objectAtIndex:z ] objectForKey:
					   [ headers objectAtIndex:y ] ] setFromTop:NO ];
					[ [ [ objectStrings objectAtIndex:z ] objectForKey:
					   [ headers objectAtIndex:y ] ] useStaticFrame:NSMakeSize(
						bounds.width, frame.height - (cellBounds.height * (z + 1))
										+ scroll.y) ];
					newHeight = frame.height - (cellBounds.height * (z + 1)) + scroll.y;
				}
				else
				{
					[ [ [ objectStrings objectAtIndex:z ] objectForKey:
					   [ headers objectAtIndex:y ] ] useDynamicFrame ];
				}
			}
			
			unsigned int img = [ [ objectImages objectAtIndex:z ] intValue ];
			float addAny = 5;
			if (img != 0)
			{
				// Todo: Add cutting off from top and bottom
				glLoadIdentity();
				glColor4d(1, 1, 1, [ background[0] alphaComponent ]);
				glEnable(GL_TEXTURE_2D);
				glBindTexture(GL_TEXTURE_2D, img);
				glBegin(GL_QUADS);
				{
					if (higher)
					{
						glTexCoord2d(0.0, newHeight / cellBounds.height);
						glVertex2d(frame.x + (cellBounds.width * y) + 2, frame.y +
							frame.height - cellBounds.height);
					}
					else
					{
						glTexCoord2d(0.0, 1.0);
						glVertex2d(frame.x + (cellBounds.width * y) + 2, frame.y +
							frame.height - (cellBounds.height * (z + 1)) + scroll.y);
					}
					if (lower)
					{
						glTexCoord2d(0.0, 1.0 - (newHeight / cellBounds.height));
						glVertex2d(frame.x + (cellBounds.width * y) + 2, frame.y);
						glTexCoord2d(1.0, 1.0 - (newHeight / cellBounds.height));
						glVertex2d(frame.x + (cellBounds.width * y) + 2 + cellBounds.height,
							frame.y);
					}
					else
					{
						glTexCoord2d(0.0, 0.0);
						glVertex2d(frame.x + (cellBounds.width * y) + 2, frame.y +
							frame.height - (cellBounds.height * (z + 2)) + scroll.y);
						glTexCoord2d(1.0, 0.0);
						glVertex2d(frame.x + (cellBounds.width * y) + 2 + cellBounds.height,
							frame.y + frame.height - (cellBounds.height * (z + 2)) + 
								   scroll.y);
					}
					if (higher)
					{
						glTexCoord2d(1.0, newHeight / cellBounds.height);
						glVertex2d(frame.x + (cellBounds.width * y) + 2 + cellBounds.height,
								   frame.y + frame.height - cellBounds.height);
					}
					else
					{
						glTexCoord2d(1.0, 1.0);
						glVertex2d(frame.x + (cellBounds.width * y) + 2 + cellBounds.height,
						frame.y + frame.height - (cellBounds.height * (z + 1)) + scroll.y);
					}
				}
				glEnd();
				glBindTexture(GL_TEXTURE_2D, 0);
				glDisable(GL_TEXTURE_2D);
				glLoadIdentity();
				addAny = headSize.height + 5;
			}
			
			DrawString([ [ objectStrings objectAtIndex:z ] objectForKey:
				[ headers objectAtIndex:y ] ], NSMakePoint(frame.x + (cellBounds.width * y)
				+ addAny, frame.y + frame.height - (cellBounds.height * (z + 1)) - 
				(cellBounds.height / 2) + scroll.y), NSLeftTextAlignment, 0);
		}
	}
	
	[ super drawView ];
}

- (void) dealloc
{
	if (headers)
	{
		[ headers removeAllObjects ];
		[ headers release ];
		headers = nil;
	}
	if (headerStrings)
	{
		[ headerStrings removeAllObjects ];
		[ headerStrings release ];
		headerStrings = nil;
	}
	if (objects)
	{
		[ objects removeAllObjects ];
		[ objects release ];
		objects = nil;
	}
	if (objectStrings)
	{
		[ objectStrings removeAllObjects ];
		[ objectStrings release ];
		objectStrings = nil;
	}
	if (objectImages)
	{
		[ objectImages removeAllObjects ];
		[ objectImages release ];
		objectImages = nil;
	}
	if (selTar)
	{
		[ selTar release ];
		selTar = nil;
	}
	for (int z = 0; z < 4; z++)
	{
		if (selColor[z])
		{
			[selColor[z] release ];
			selColor[z] = nil;
		}
	}
		 
	[ super dealloc ];
}

@end
