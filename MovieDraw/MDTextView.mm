//
//  MDTextView.mm
//  MovieDraw
//
//  Created by MILAP on 2/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MDTextView.h"

#define COMMAND		(1 << 0)
#define SHIFT		(1 << 1)

#define HIGHLIGHT_COLOR		[ NSColor colorWithCalibratedRed:0.709804 green:0.835294 blue:1.0 alpha:1 ]

long InRanges(unsigned long index, std::vector<NSRange> range);
long InRanges(unsigned long index, std::vector<NSRange> range)
{
	for (int z = 0; z < range.size(); z++)
	{
		unsigned long realLoc = range[z].location;
		unsigned long realLen = range[z].length;
		if ((long)range[z].length < 0)
		{
			realLoc += (long)realLen;
			realLen *= -1;
		}
		if (index > realLoc && index <= realLoc + realLen)
			return z;
	}
	return -1;
}

void DrawHighlight(NSRect bounds);
void DrawHighlight(NSRect bounds)
{
	NSColor* highlightColor = HIGHLIGHT_COLOR;
	glColor4d([ highlightColor redComponent ], [ highlightColor greenComponent ], [ highlightColor blueComponent ], [ highlightColor alphaComponent ]);
	glBindTexture (GL_TEXTURE_RECTANGLE_EXT, 0);
	glBegin (GL_TRIANGLE_STRIP);
	glVertex2f (bounds.origin.x - 0.5, bounds.origin.y);
	glVertex2f (bounds.origin.x - 0.5, bounds.origin.y + bounds.size.height);
	glVertex2f (bounds.origin.x + bounds.size.width + 0.5, bounds.origin.y);
	glVertex2f (bounds.origin.x + bounds.size.width + 0.5, bounds.origin.y + bounds.size.height);
	glEnd ();
}

@implementation MDTextView

- (BOOL) hasHighlights
{
	BOOL drawCursor = TRUE;
	if (highlights.size() == 1)
	{
		if (highlights[0].length != 0)
			drawCursor = FALSE;
	}
	else if (highlights.size() != 0)
		drawCursor = FALSE;
	return !drawCursor;
}

+ (instancetype) mdTextView
{
	return [ [ MDTextView alloc ] init ];
}

+ (instancetype) mdTextViewWithFrame: (MDRect)rect background:(NSColor*)bkg
{
	return [ [ MDTextView alloc ] initWithFrame:rect background:bkg ];
}

- (instancetype) init
{
	if ((self = [ super init ]))
	{
		characters = [ [ NSMutableArray alloc ] init ];
		editable = YES;
		updateScroll = TRUE;
		mouseClick = NSMakePoint(-1, -1);
		mouseDrag = NSMakePoint(-1, -1);
		
		GLString* string = LoadString(@"i", textColor, textFont);
		[ string setMargins:NSMakeSize(0, 0) ];
		cursorHeight = [ string frameSize ].height;
	}
	return self;
}

- (instancetype) initWithFrame:(MDRect)rect background:(NSColor*)bkg
{
	if ((self = [ super initWithFrame:rect background:bkg ]))
	{
		characters = [ [ NSMutableArray alloc ] init ];
		editable = YES;
		updateScroll = TRUE;
		mouseClick = NSMakePoint(-1, -1);
		mouseDrag = NSMakePoint(-1, -1);
		
		GLString* string = LoadString(@"i", textColor, textFont);
		[ string setMargins:NSMakeSize(0, 0) ];
		cursorHeight = [ string frameSize ].height;
	}
	return self;
}

- (void) addCharacter: (short)data toIndex:(unsigned long) index
{
	if (index > [ text length ] || index > [ characters count ])
		return;
	[ text insertString:[ NSString stringWithFormat:@"%c", data ] atIndex:index ];
	GLString* string = nil;
	if (data == '\t' || data == '\n')
		string = LoadString(@"        ", textColor, textFont);
	else
		string = LoadString([ NSString stringWithFormat:@"%c", data ], textColor, textFont);
	[ string setMargins:NSMakeSize(0, 0) ];
	[ string drawAtPoint:NSZeroPoint ];
	[ characters insertObject:string atIndex:index ];
}

- (void) setTextFont:(NSFont *)font
{
	[ super setTextFont:font ];
	GLString* string = LoadString(@"i", textColor, textFont);
	cursorHeight = [ string frameSize ].height;
}

- (void) deleteCharacterAtIndex:(unsigned long) index
{
	if (index >= [ text length ] || index >= [ characters count ])
		return;
	
	[ text deleteCharactersInRange:NSMakeRange(index, 1) ];
	[ characters removeObjectAtIndex:index ];
}

- (void) loadText:(NSString*) str
{
	@autoreleasepool {
		[ text setString:@"" ];
		[ characters removeAllObjects ];
		cursorIndex = 0;
		cursorTimer = 0;
		for (unsigned long z = 0; z < [ str length ]; z++)
			[ self addCharacter:[ str characterAtIndex:z ] toIndex:z ];
	}
}


- (void) setText:(NSString *)str
{		
	if (loadingContext)
		[ NSThread detachNewThreadSelector:@selector(loadText:) toTarget:self withObject:str ];
	else
		[ self loadText:str ];
}

- (void) setEditable: (BOOL)edit
{
	editable = edit;
}

- (BOOL) editable
{
	return editable;
}

- (void) setCursorPosition:(unsigned long)pos
{
	if (pos > [ text length ])
		return;
	cursorIndex = pos;
}

- (unsigned long) cursorPosition
{
	return cursorIndex;
}

- (std::vector<NSRange>&) highlights
{
	return highlights;
}

- (void) mouseDown:(NSEvent *)event
{
	[ super mouseDown:event ];
	
	commands = 0;
	if ([ event modifierFlags ] & NSCommandKeyMask)
		commands |= COMMAND;
	else if ([ event modifierFlags ] & NSShiftKeyMask)
		commands |= SHIFT;
	else
		highlights.clear();
	
	clickCount = 0;
	mouseClick = NSMakePoint(-1, -1);
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
		mouseClick = NSMakePoint(point.x - frame.x, point.y - frame.y);
		clickCount = (unsigned int)[ event clickCount ];
	}
	else
		cursorIndex = -1;
}

- (void) mouseDragged:(NSEvent *)event
{
	[ super mouseDragged:event ];
	if (!visible || !enabled)
		return;
	mouseDrag = NSMakePoint(-1, -1);
	NSPoint point = [ event locationInWindow ];
	point.x -= origin.x;
	point.y -= origin.y;
	point.x *= resolution.width / windowSize.width;
	point.y *= resolution.height / windowSize.height;
	if (point.x >= frame.x && point.x <= frame.x + frame.width &&
		point.y >= frame.y && point.y <= frame.y + frame.height)
		mouseDrag = NSMakePoint(point.x - frame.x, point.y - frame.y);
}

- (void) drawView
{	
	float square[8];
	square[0] = frame.x;
	square[1] = frame.y;
	square[2] = frame.x + frame.width;
	square[3] = frame.y;
	square[4] = frame.x;
	square[5] = frame.y + frame.height;
	square[6] = frame.x + frame.width;
	square[7] = frame.y + frame.height;
	float colors[16];
	for (int z = 0; z < 4; z++)
	{
		colors[(z * 4)] = [ background redComponent ];
		colors[(z * 4) + 1] = [ background greenComponent ];
		colors[(z * 4) + 2] = [ background blueComponent ];
		colors[(z * 4) + 3] = [ background alphaComponent ];
	}
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_COLOR_ARRAY);
	glVertexPointer(2, GL_FLOAT, 0, square);
	glColorPointer(4, GL_FLOAT, 0, colors);
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	
	int s = 0;
	glGetIntegerv (GL_MATRIX_MODE, &s);
	glMatrixMode (GL_PROJECTION);
	glPushMatrix();
	glLoadIdentity ();
	glMatrixMode (GL_MODELVIEW);
	glPushMatrix();
	NSSize bounds = resolution;
	glLoadIdentity();    // Reset the current modelview matrix
	glScaled(2.0 / bounds.width, -2.0 / bounds.height, 1.0);
	glTranslated(-bounds.width / 2.0, -bounds.height / 2.0, 0.0);
	glTranslated(0, -scroll.y, 0);
	glColor4f(1, 1, 1, 1);
	glPushAttrib(GL_ENABLE_BIT | GL_TEXTURE_BIT | GL_COLOR_BUFFER_BIT); // GL_COLOR_BUFFER_BIT for glBlendFunc, GL_ENABLE_BIT for glEnable / glDisable
	glDisable (GL_DEPTH_TEST); // ensure text is not remove by depth buffer test.
	glEnable (GL_BLEND); // for text fading
	glBlendFunc (GL_ONE, GL_ONE_MINUS_SRC_ALPHA); // ditto
	glEnable (GL_TEXTURE_RECTANGLE_EXT);	
	
	glEnable(GL_SCISSOR_TEST);
	glScissor(frame.x, frame.y, frame.width, frame.height);
	
	NSPoint cursorPoint = NSMakePoint(5, cursorHeight / 2);
	NSSize cursorSize = NSMakeSize(0,  cursorHeight);
	
	// Draw each chararcter individually
	unsigned long line = 0;
	float height = 0;
	float halfHeight = 0;
	BOOL foundCursor = TRUE;
	unsigned long textLength = [ text length ];
	if (textLength != 0 && [ characters count ] != 0)
	{
		height = [ characters[0] frameSize ].height / 2;
		halfHeight = height;
		foundCursor = FALSE;
	}
	float width = 5;
	BOOL foundMouse = FALSE;
	unsigned long prevCursor = cursorIndex;
	long endCursor = -2;
	for (unsigned long z = 0; z < textLength; z++)
	{
		if (z >= [ characters count ])
			break;
		GLString* string = characters[z];
		if ([ text characterAtIndex:z ] == '\n')
			[ string useStaticFrame:NSMakeSize(frame.width - width - 5, [ string frameSize ].height) ];
		NSSize frameSize = [ string frameSize ];
		
		if (mouseClick.x != -1 && mouseClick.y != -1)
		{
			if (mouseClick.y - scroll.y >= frame.height - height - halfHeight && mouseClick.x <= width + [ string frameSize ].width / 2)
			{
				mouseClick = NSMakePoint(-1, -1);
				cursorIndex = z;
				foundMouse = TRUE;
			}
			else if (mouseClick.y - scroll.y >= frame.height - height + halfHeight)
			{
				// Back to previous line
				mouseClick = NSMakePoint(-1, -1);
				cursorIndex = z - 1;
				foundMouse = TRUE;
			}
			cursorTimer = 0;
		}
		if (mouseDrag.x != -1 && mouseDrag.y != -1)
		{
			if (mouseDrag.y - scroll.y >= frame.height - height - halfHeight && mouseDrag.x <= width + [ string frameSize ].width / 2)
			{
				mouseDrag = NSMakePoint(-1, -1);
				endCursor = z;
			}
			else if (mouseDrag.y - scroll.y >= frame.height - height + halfHeight)
			{
				// Back to previous line
				mouseDrag = NSMakePoint(-1, -1);
				endCursor = z - 1;
			}
			cursorTimer = 0;
		}

		if ([ text characterAtIndex:z ] == '\n')
		{
			if (InRanges(z + 1, highlights) != -1)
			{
				float fakeHeight = frame.y + frame.height - height + (frameSize.height / 2) + 1;
				fakeHeight = resolution.height - fakeHeight;
				NSRect bounds = NSMakeRect(frame.x + width, fakeHeight, frame.width - 5 - width, frameSize.height);
				DrawHighlight(bounds);
			}
			
			height += frameSize.height;
			line++;
			width = 5;
			
			if (cursorIndex == z + 1)
			{
				foundCursor = TRUE;
				cursorPoint = NSMakePoint(width, height);
				cursorSize = NSMakeSize(0, frameSize.height);
			}
			
			continue;
		}
		if (width + ([ string frameSize ].width) >= frame.width - 5)
		{
			width = 5;
			height += [ string frameSize ].height;
			line++;
		}
		
		if (height - scroll.y + halfHeight < 0 || height - scroll.y - halfHeight > frame.height)
		{
			width += [ string frameSize ].width;
			
			if (cursorIndex == z + 1)
			{
				foundCursor = TRUE;
				cursorPoint = NSMakePoint(width, height);
				cursorSize = frameSize;
			}
			
			continue;
		}
		
		if (cursorIndex == z + 1)
		{
			foundCursor = TRUE;
			cursorPoint = NSMakePoint(width, height);
			cursorSize = frameSize;
		}
		
		
		
		NSPoint position = NSMakePoint(frame.x + width, frame.y + frame.height - height);
		
		
		position.x -= frameSize.width / 2;
		position.y += (frameSize.height / 2) + 1;
		position.y = bounds.height - position.y;
		
		glTranslated(frameSize.width / 2.0, 0, 0);
		
		NSSize texSize = [ string texSize ];
		NSRect bounds = NSMakeRect(position.x, position.y, [ string texSize ].width, [ string texSize ].height);
		
		if (InRanges(z + 1, highlights) != -1)
			DrawHighlight(bounds);
		
		NSColor* color = [ textColor colorUsingColorSpace:[ NSColorSpace genericRGBColorSpace ] ];
		glColor4d([ color redComponent ], [ color greenComponent ], [ color blueComponent ], [ color alphaComponent ]);
		
		glBindTexture (GL_TEXTURE_RECTANGLE_EXT, [ string texName ]);
		glBegin (GL_TRIANGLE_STRIP);
		glTexCoord2f (0.0f, 0.0f); // draw upper left in world coordinates
		glVertex2f (bounds.origin.x, bounds.origin.y);
		
		glTexCoord2f (0.0f, texSize.height); // draw lower left in world coordinates
		glVertex2f (bounds.origin.x, bounds.origin.y + bounds.size.height);
		
		glTexCoord2f (texSize.width, 0.0f); // draw lower right in world coordinates
		glVertex2f (bounds.origin.x + bounds.size.width, bounds.origin.y);
		
		glTexCoord2f (texSize.width, texSize.height); // draw upper right in world coordinates
		glVertex2f (bounds.origin.x + bounds.size.width, bounds.origin.y + bounds.size.height);
		
		glEnd ();
				
		glTranslated(-frameSize.width / 2.0, 0, 0);
		
		width += [ string frameSize ].width;
	}
	
	if (mouseClick.x != -1 && mouseClick.y != -1)
	{
		mouseClick = NSMakePoint(-1, -1);
		cursorIndex = textLength;
		foundMouse = TRUE;
	}
	if (mouseDrag.x != -1 && mouseDrag.y != -1)
	{
		mouseDrag = NSMakePoint(-1, -1);
		endCursor = textLength;
	}
	
	if (foundMouse)
	{
		if (clickCount == 2)
		{
			// Find last space
			long long firstSpace = 0;
			for (firstSpace = cursorIndex; firstSpace >= 0; firstSpace--)
			{
				if (firstSpace >= [ text length ])
					continue;
				if (!(([ text characterAtIndex:firstSpace ] >= 'a' && [ text characterAtIndex:firstSpace ] <= 'z') || ([ text characterAtIndex:firstSpace ] >= 'A' && [ text characterAtIndex:firstSpace ] <= 'Z') || ([ text characterAtIndex:firstSpace ] >= '0' && [ text characterAtIndex:firstSpace ] <= '9')))
					break;
			}
			firstSpace++;
			long long secondSpace = 0;
			for (secondSpace = cursorIndex - 1; secondSpace < (long long)[ text length ]; secondSpace++)
			{
				if (secondSpace < 0)
					continue;
				
				if (!(([ text characterAtIndex:secondSpace ] >= 'a' && [ text characterAtIndex:secondSpace ] <= 'z') || ([ text characterAtIndex:secondSpace ] >= 'A' && [ text characterAtIndex:secondSpace ] <= 'Z') || ([ text characterAtIndex:secondSpace ] >= '0' && [ text characterAtIndex:secondSpace ] <= '9')))
					break;
			}
			NSRange range = NSMakeRange(firstSpace, secondSpace - firstSpace);
			if (range.length != 0)
			{
				if (commands & COMMAND)
					highlights.push_back(range);
				else
				{
					highlights.clear();
					highlights.push_back(range);
				}
			}
			clickCount = 0;
		}
		else if (clickCount == 3)
		{
			// Find last enter
			long firstSpace = 0;
			for (firstSpace = cursorIndex; firstSpace >= 0; firstSpace--)
			{
				if (firstSpace >= [ text length ])
					continue;
				if ([ text characterAtIndex:firstSpace ] == '\n')
					break;
			}
			firstSpace++;
			unsigned long secondSpace = 0;
			for (secondSpace = cursorIndex; secondSpace < [ text length ]; secondSpace++)
			{
				if ([ text characterAtIndex:secondSpace ] == '\n')
				{
					secondSpace++;
					break;
				}
			}
			NSRange range = NSMakeRange(firstSpace, secondSpace - firstSpace);
			if (range.length != 0)
			{
				if (commands & COMMAND)
					highlights.push_back(range);
				else
				{
					highlights.clear();
					highlights.push_back(range);
				}
			}
			clickCount = 0;
		}
		if ((commands & SHIFT) && highlights.size() != 0)
		{
			if (cursorIndex > NSMaxRange(highlights[highlights.size() - 1]))
			{
				if ((long)highlights[highlights.size() - 1].length < 0)
				{
					highlights[highlights.size() - 1].location += highlights[highlights.size() - 1].length;
					highlights[highlights.size() - 1].length *= -1;
				}
				highlights[highlights.size() - 1].length = cursorIndex - highlights[highlights.size() - 1].location;
			}
			else if (cursorIndex > highlights[highlights.size() - 1].location)
				highlights[highlights.size() - 1].length = cursorIndex - highlights[highlights.size() - 1].location;
			else
				highlights[highlights.size() - 1].length = cursorIndex - highlights[highlights.size() - 1].location;
			cursorIndex = prevCursor;
		}
		else
		{
			for (int z = 0; z < highlights.size(); z++)
			{
				if (highlights[z].length == 0)
				{
					highlights.erase(highlights.begin() + z);
					z--;
				}
			}
			NSRange range = NSMakeRange(cursorIndex, 0);
			highlights.push_back(range);
		}
	}
	if (endCursor != -2 && highlights.size() != 0)
	{
		unsigned long start = highlights[highlights.size() - 1].location;
		highlights[highlights.size() - 1].length = endCursor - start;
	}
	
	height += halfHeight;
	float mScroll = height - frame.height;
	if (mScroll < 0)
		mScroll = 0;
	[ self setMaxScroll:NSMakeSize(0, mScroll) ];
	
	if (updateScroll == 1)
	{
		float tempValue = scroll.y;
		while (tempValue >= cursorHeight)
			tempValue -= cursorHeight;
		float tempScroll = scroll.y + cursorHeight - tempValue;
		if (cursorPoint.y - tempScroll <= -cursorHeight / 2)
			scroll.y = cursorPoint.y - (cursorHeight / 2);
		updateScroll = 0;
	}
	if (updateScroll == 2)
	{
		float tempValue = scroll.y;
		while (tempValue >= cursorHeight)
			tempValue -= cursorHeight;
		float tempScroll = scroll.y - tempValue;
		if (cursorPoint.y - cursorHeight / 2 - tempScroll >= frame.height)
			scroll.y = cursorPoint.y + (cursorHeight / 2) - frame.height;
		updateScroll = 0;
	}
	
	glColor4d(1, 1, 1, 1);
	glPopAttrib();
	// Reset things
	glLoadIdentity();
	glPopMatrix(); // GL_MODELVIEW
	glMatrixMode (GL_PROJECTION);
	glPopMatrix();
	glMatrixMode (s);
	
	// Draw Cursor
	if ((cursorTimer <= 30 && (foundCursor || cursorIndex == 0)) && ![ self hasHighlights ] && cursorIndex != -1)
	{
		glEnable(GL_SCISSOR_TEST);
		glScissor(frame.x, frame.y, frame.width, frame.height);
		
		glLoadIdentity();
		glTranslated(0, scroll.y, 0);
		glColor4d(0, 0, 0, 1);
		glBegin(GL_LINES);
		{
			glVertex2d(frame.x + cursorPoint.x + cursorSize.width, frame.y + frame.height - cursorPoint.y + (cursorSize.height / 2));
			glVertex2d(frame.x + cursorPoint.x + cursorSize.width, frame.y + frame.height - cursorPoint.y - cursorSize.height / 2);
		}
		glEnd();
		
		glDisable(GL_SCISSOR_TEST);
	}
	
	cursorTimer++;
	if (cursorTimer > 60)
		cursorTimer = 0;
	
	[ super drawView ];
}

- (void) keyDown: (NSEvent*) theEvent
{
	if (cursorIndex == (unsigned long)-1)
		return;
	
	unsigned short key = [ [ theEvent characters ] characterAtIndex:0 ];
	switch (key)
	{
		case NSUpArrowFunctionKey:
		{
			if (highlights.size() != 0)
				cursorIndex = highlights[0].location;
			// Find last 2 '\n'
			unsigned int found = 0;
			unsigned long difference = 0;
			unsigned long cursor1 = 0;
			for (unsigned long cursor = cursorIndex; cursor > 0; cursor--)
			{
				if ([ text characterAtIndex:cursor - 1 ] == '\n')
				{
					found++;
					if (found == 1)
					{
						difference = cursorIndex - cursor;
						cursor1 = cursor;
					}
					else if (found == 2)
					{
						cursorIndex = cursor + difference;
						if (cursorIndex >= cursor1)
							cursorIndex = cursor1 - 1;
						break;
					}
				}
			}
			if (found == 0)
				cursorIndex = 0;
			else if (found == 1)
			{
				cursorIndex = difference;
				if (cursorIndex >= cursor1)
					cursorIndex = cursor1 - 1;
			}
			cursorTimer = 0;
			updateScroll = 1;
			highlights.clear();
			break;
		}
		case NSDownArrowFunctionKey:
		{
			if (highlights.size() != 0)
				cursorIndex = highlights[0].location;
			// Find last '\n'
			unsigned int found = 0;
			unsigned long difference = 0;
			for (unsigned long cursor = cursorIndex; cursor > 0; cursor--)
			{
				if ([ text characterAtIndex:cursor - 1 ] == '\n')
				{
					found++;
					if (found == 1)
					{
						difference = cursorIndex - cursor;
						break;
					}
				}
			}
			if (found == 0)
				difference = cursorIndex;
			found = 0;
			for (unsigned long cursor = cursorIndex + 1; cursor <= [ text length ]; cursor++)
			{
				if ([ text characterAtIndex:cursor - 1 ] == '\n')
				{
					found++;
					if (found == 1)
					{
						cursorIndex = cursor + difference;
						if (cursorIndex > [ text length ])
							cursorIndex = [ text length ];
						
						for (unsigned long cursor2 = cursor + 1; cursor2 <= [ text length ]; cursor2++)
						{
							if ([ text characterAtIndex:cursor2 - 1 ] == '\n')
							{
								if (cursorIndex >= cursor2)
									cursorIndex = cursor2 - 1;
							}
						}
						
						break;
					}
				}
			}
			if (found == 0)
				cursorIndex = [ text length ];
			
			cursorTimer = 0;
			updateScroll = 2;
			highlights.clear();
			break;
		}
		case NSLeftArrowFunctionKey:
			if ([ self hasHighlights ])
			{
				cursorIndex = highlights[0].location;
				if ((long)highlights[0].length < 0)
					cursorIndex = highlights[0].location - (long)highlights[0].length;
				cursorTimer = 0;
				highlights.clear();
				break;
			}
			cursorTimer = 0;
			if (cursorIndex > 0)
				cursorIndex--;
			updateScroll = 1;
			highlights.clear();
			break;
		case NSRightArrowFunctionKey:
			if ([ self hasHighlights ])
			{
				cursorIndex = NSMaxRange(highlights[0]);
				if ((long)highlights[0].length < 0)
					cursorIndex = highlights[0].location;
				cursorTimer = 0;
				highlights.clear();
				break;
			}
			cursorTimer = 0;
			if (cursorIndex < [ text length ])
				cursorIndex++;
			updateScroll = 2;
			highlights.clear();
			break;
		case NSDeleteCharacter:
			if (editable)
			{
				if ([ self hasHighlights ])
				{
					if (highlights.size() != 0)
						cursorIndex = highlights[0].location;
					unsigned long lowestLoc = cursorIndex;
					NSMutableIndexSet* set = [ [ NSMutableIndexSet alloc ] init ];
					for (unsigned long z = 0; z < highlights.size(); z++)
					{
						unsigned long loc = highlights[z].location;
						long len = highlights[z].length;
						if (len < 0)
						{
							//if (loc <= cursorIndex)
							//	cursorIndex--;
							loc += len;
							len *= -1;
						}
						if (loc < lowestLoc)
							lowestLoc = loc;
						for (unsigned long q = loc; q < loc + (unsigned long)len; q++)
						{
							[ set addIndex:q ];
							//if (q < cursorIndex)
							//	cursorIndex--;
						}
					}
					cursorIndex = lowestLoc;
					
					unsigned long lastIndex = [ set lastIndex ];
					do
					{
						if (lastIndex == NSNotFound)
							break;
						[ self deleteCharacterAtIndex:lastIndex ];
						lastIndex = [ set indexLessThanIndex:lastIndex ];
					}
					while (lastIndex != NSNotFound);
					
					highlights.clear();
					cursorTimer = 0;
				}
				else if (cursorIndex != 0)
				{
					cursorIndex--;
					[ self deleteCharacterAtIndex:cursorIndex ];
					cursorTimer = 0;
				}
			}
			break;
		default:
		{
			if (!editable)
				break;
			if (key == NSCarriageReturnCharacter || key == NSEnterCharacter ||
				key == NSNewlineCharacter)
				key = '\n';
			else if (key == NSTabCharacter)
				key = '\t';
			
			if ([ self hasHighlights ])
			{
				if (highlights.size() != 0)
					cursorIndex = highlights[0].location;
				NSMutableIndexSet* set = [ [ NSMutableIndexSet alloc ] init ];
				for (unsigned long z = 0; z < highlights.size(); z++)
				{
					unsigned long loc = highlights[z].location;
					long len = highlights[z].length;
					if (len < 0)
					{
						loc += len;
						len *= -1;
					}
					for (unsigned long q = loc; q < loc + (unsigned long)len; q++)
					{
						[ set addIndex:q ];
						if (q < cursorIndex)
							cursorIndex--;
					}
				}
				
				
				unsigned long lastIndex = [ set lastIndex ];
				do
				{
					if (lastIndex == NSNotFound)
						break;
					[ self deleteCharacterAtIndex:lastIndex ];
					lastIndex = [ set indexLessThanIndex:lastIndex ];
				}
				while (lastIndex != NSNotFound);
				
				highlights.clear();
				cursorTimer = 0;
			}
			
			[ self addCharacter:key toIndex:cursorIndex ];
			cursorIndex++;
			cursorTimer = 0;
			updateScroll = 2;
			break;
		}
	}
}

@end
