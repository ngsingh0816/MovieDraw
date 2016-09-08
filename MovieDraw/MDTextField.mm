//
//  MDTextField.m
//  MovieDraw
//
//  Created by MILAP on 7/27/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MDTextField.h"
#import "GLString.h"

#define COMMAND	(1 << 0)
#define SHIFT	(1 << 1)

#define HIGHLIGHT_COLOR		[ NSColor colorWithCalibratedRed:0.709804 green:0.835294 blue:1.0 alpha:1 ]

long InRanges(unsigned long index, std::vector<NSRange> range);
void DrawHighlight(NSRect bounds);

@implementation MDTextField

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

+ (MDTextField*) mdTextField
{
	return [ [ MDTextField alloc ] init ];
}

+ (MDTextField*) mdTextFieldWithFrame:(MDRect) rect background:(NSColor*)bkg
{
	return [ [ MDTextField alloc ] initWithFrame:rect background:bkg ];
}

- (instancetype) init
{
	if ((self = [ super init ]))
	{	
		characters = [ [ NSMutableArray alloc ] init ];
		mouseClick = NSMakePoint(-1, -1);
		mouseDrag = NSMakePoint(-1, -1);
		
		GLString* string = LoadString(@"i", textColor, textFont);
		[ string setMargins:NSMakeSize(0, 0) ];
		cursorHeight = [ string frameSize ].height;
		
		numeric = FALSE;
		editable = TRUE;
		safe = FALSE;
		useThreads = TRUE;
	}
	return self;
}

- (instancetype) initWithFrame:(MDRect)rect background:(NSColor*)bkg
{
	if ((self = [ super initWithFrame:rect background:bkg ]))
	{
		characters = [ [ NSMutableArray alloc ] init ];
		mouseClick = NSMakePoint(-1, -1);
		mouseDrag = NSMakePoint(-1, -1);
		
		GLString* string = LoadString(@"i", textColor, textFont);
		[ string setMargins:NSMakeSize(0, 0) ];
		cursorHeight = [ string frameSize ].height;
		
		numeric = FALSE;
		editable = TRUE;
		safe = FALSE;
		useThreads = TRUE;
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

- (void) deleteCharacterAtIndex:(unsigned long) index
{
	if (index >= [ text length ] || index >= [ characters count ])
		return;
	
	[ text deleteCharactersInRange:NSMakeRange(index, 1) ];
	[ characters removeObjectAtIndex:index ];
}

- (void) setUsesThreads:(BOOL)set
{
	useThreads = set;
}

- (BOOL) usesThreads
{
	return useThreads;
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
	if (loadingContext && useThreads)
		[ NSThread detachNewThreadSelector:@selector(loadText:) toTarget:self withObject:str ];
	else
		[ self loadText:str ];
}

- (void) setNumbersOnly:(BOOL) numb
{
	numeric = numb;
}

- (BOOL) numbersOnly
{
	return numeric;
}

- (void) setCanHighlight: (BOOL)high
{
	canHighlight = high;
}

- (BOOL) canHighlight
{
	return canHighlight;
}

- (std::vector<NSRange>*) highlights
{
	return &highlights;
}


- (unsigned long) cursorPosition
{
	return cursorIndex;
}

- (void) setCursorPosition:(unsigned long)pos
{
	if (pos > [ text length ])
		return;
	cursorIndex = pos;
}

- (void) setPixelOffset:(float) offset
{
	pixelOffset = offset;
}

- (float) pixelOffset
{
	return pixelOffset;
}

- (void) drawView
{
	if (!visible)
		return;
	
	glLoadIdentity();
	glColor4d(0, 0, 0, 1);
	glBegin(GL_LINE_LOOP);
	{
		glVertex2d(frame.x, frame.y);
		glVertex2d(frame.x + frame.width, frame.y);
		glVertex2d(frame.x + frame.width, frame.y + frame.height);
		glVertex2d(frame.x, frame.y + frame.height);
	}
	glEnd();
	
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
	glTranslated(-scrollx, 0, 0);
	glColor4f(1, 1, 1, 1);
	glPushAttrib(GL_ENABLE_BIT | GL_TEXTURE_BIT | GL_COLOR_BUFFER_BIT); // GL_COLOR_BUFFER_BIT for glBlendFunc, GL_ENABLE_BIT for glEnable / glDisable
	glDisable (GL_DEPTH_TEST); // ensure text is not remove by depth buffer test.
	glEnable (GL_BLEND); // for text fading
	glBlendFunc (GL_ONE, GL_ONE_MINUS_SRC_ALPHA); // ditto
	glEnable (GL_TEXTURE_RECTANGLE_EXT);	
	
	glEnable(GL_SCISSOR_TEST);
	glScissor(frame.x, frame.y, frame.width - pixelOffset, frame.height);
	
	NSPoint cursorPoint = NSMakePoint(5, cursorHeight / 2);
	NSSize cursorSize = NSMakeSize(0,  cursorHeight);
	
	// Draw each chararcter individually
	BOOL foundCursor = TRUE;
	unsigned long textLength = [ text length ];
	if (textLength != 0 && [ characters count ] != 0)
		foundCursor = FALSE;
	float width = 5;
	BOOL foundMouse = FALSE;
	unsigned long prevCursor = cursorIndex;
	long endCursor = -2;
	float nextScrollx = scrollx;
	if (updateScroll != 0)
		nextScrollx = 0;
	for (unsigned long z = 0; z < textLength; z++)
	{
		if (z >= [ characters count ])
			break;
		
		GLString* string = characters[z];
		if (safeText)
			string = safeText;
		NSSize frameSize = [ string frameSize ];
		
		if (mouseClick.x != -1 && mouseClick.y != -1)
		{
			if (mouseClick.x + scrollx <= width + [ string frameSize ].width / 2)
			{
				mouseClick = NSMakePoint(-1, -1);
				cursorIndex = z;
				foundMouse = TRUE;
				
			}
			cursorTimer = 0;
		}
		if (mouseDrag.x != -1 && mouseDrag.y != -1)
		{
			if (mouseDrag.x + scrollx <= width + [ string frameSize ].width / 2)
			{
				mouseDrag = NSMakePoint(-1, -1);
				endCursor = z;
			}
			cursorTimer = 0;
		}
		
		if (width - scrollx + (frameSize.width / 1) < 0 || width - scrollx - (frameSize.width / 2) >= frame.width)
		{
			if (cursorIndex == z + 1)
			{
				foundCursor = TRUE;
				cursorPoint = NSMakePoint(width, 0);
				cursorSize = frameSize;
			}
			
			width += [ string frameSize ].width;
			
			if (updateScroll == 2 && scrollIndex == z + 1)
			{
				nextScrollx = width;
				if (nextScrollx > scrollx)
					nextScrollx = scrollx;
				updateScroll = 0;
			}
			else if (updateScroll == 1 && scrollIndex == z + 1)
			{
				nextScrollx = width - scrollx;
				if (nextScrollx < (frame.width - pixelOffset) && nextScrollx > 0)
					nextScrollx = scrollx;
				else if (nextScrollx > 0)
					nextScrollx -= -scrollx + (frame.width - pixelOffset);
				updateScroll = 0;
			}
			
			continue;
		}
		
		if (cursorIndex == z + 1)
		{
			foundCursor = TRUE;
			cursorPoint = NSMakePoint(width, 0);
			cursorSize = frameSize;
		}
				
		NSPoint position = NSMakePoint(frame.x + width, frame.y + (frame.height / 2));
		
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
		
		if (updateScroll == 2 && scrollIndex == z + 1)
		{
			nextScrollx = width;
			if (nextScrollx > scrollx)
				nextScrollx = scrollx;
			updateScroll = 0;
		}
		else if (updateScroll == 1 && scrollIndex == z + 1)
		{
			nextScrollx = width - scrollx;
			if (nextScrollx < (frame.width - pixelOffset) && nextScrollx > 0)
				nextScrollx = scrollx;
			else if (nextScrollx > 0)
				nextScrollx -= -scrollx + (frame.width - pixelOffset);
			updateScroll = 0;
		}
	}
	
	if (mouseClick.x != -1 && mouseClick.y != -1 && !foundMouse)
	{
		if (moveWay == 0)
			mouseClick = NSMakePoint(-1, -1);
		cursorIndex = textLength;
		foundMouse = TRUE;
	}
	if (mouseDrag.x != -1 && mouseDrag.y != -1)
	{
		mouseDrag = NSMakePoint(-1, -1);
		endCursor = textLength;
	}
	
	if (foundMouse && moveWay == 0)
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
			NSRange range = NSMakeRange(0, [ text length ]);
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
		glScissor(frame.x, frame.y, frame.width - pixelOffset, frame.height);
		
		glLoadIdentity();
		glTranslated(-scrollx, -frame.height / 2, 0);
		glColor4d(0, 0, 0, 1);
		glBegin(GL_LINES);
		{
			glVertex2d(frame.x + cursorPoint.x + cursorSize.width, frame.y + frame.height + (cursorSize.height / 2));
			glVertex2d(frame.x + cursorPoint.x + cursorSize.width, frame.y + frame.height - cursorSize.height / 2);
		}
		glEnd();
		
		glDisable(GL_SCISSOR_TEST);
	}
	scrollx = nextScrollx;
	
	if (moveWay != 0)
	{
		if (moveWay == 1)
		{
			scrollx += (moveAway.x - (frame.width - pixelOffset)) / 10.0;
			if (scrollx > width - (frame.width - pixelOffset))
				scrollx = width - (frame.width - pixelOffset);
		}
		else
		{
			scrollx += (moveAway.x / 10.0);
			if (scrollx < 0)
				scrollx = 0;
		}
		mouseDrag = moveAway;
	}
	
	cursorTimer++;
	if (cursorTimer > 60)
		cursorTimer = 0;
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
	if (point.x >= frame.x && point.x <= frame.x + (frame.width - pixelOffset) &&
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
	if (realDown && point.x >= frame.x && point.x <= frame.x + (frame.width - pixelOffset))
		mouseDrag = NSMakePoint(point.x - frame.x, point.y - frame.y);
	moveWay = 0;
	if (realDown && point.x <= frame.x)
		moveWay = 2;
	else if (realDown && point.x >= frame.x + (frame.width - pixelOffset))
		moveWay = 1;
	if (moveWay != 0)
		moveAway = NSMakePoint(point.x - frame.x, point.y - frame.y);
}

- (void) setTextColor:(NSColor *)color
{
	if (safeText)
	{
		safeText = LoadString(@"*", textColor, textFont);
		[ safeText setMargins:NSMakeSize(0, 0) ];
		[ safeText drawAtPoint:NSZeroPoint ];
	}
	[ super setTextColor:color ];
}

- (void) setTextFont:(NSFont *)font
{
	if (safeText)
	{
		safeText = LoadString(@"*", textColor, textFont);
		[ safeText setMargins:NSMakeSize(0, 0) ];
		[ safeText drawAtPoint:NSZeroPoint ];
	}
	[ super setTextFont:font ];
}

- (void) setSafeText: (BOOL) sf
{
	safe = sf;
	safeText = nil;
	if (safe)
	{
		safeText = LoadString(@"*", textColor, textFont);
		[ safeText setMargins:NSMakeSize(0, 0) ];
		[ safeText drawAtPoint:NSZeroPoint ];
	}
}

- (BOOL) safeText
{
	return safe;
}

- (void) mouseUp: (NSEvent*)event
{
	if (!visible || !enabled)
		return;
	
	state = false;
	NSPoint point = [ event locationInWindow ];
	point.x -= origin.x;
	point.y -= origin.y;
	point.x *= resolution.width / windowSize.width;
	point.y *= resolution.height / windowSize.height;
	if (point.x >= frame.x && point.x <= frame.x + (frame.width - pixelOffset) &&
		point.y >= frame.y && point.y <= frame.y + frame.height)
		state = true;
	down = FALSE;
	up = TRUE;
	realDown = FALSE;
	
	moveWay = FALSE;
}

- (void) keyDown: (NSEvent*) theEvent
{
	if (cursorIndex == (unsigned long)-1)
		return;
	
	unsigned short key = [ [ theEvent characters ] characterAtIndex:0 ];
	switch (key)
	{
		case NSUpArrowFunctionKey:
			cursorIndex = 0;
			scrollIndex = 0;
			updateScroll = 2;
			break;
		case NSDownArrowFunctionKey:
			cursorIndex = [ text length ];
			scrollIndex = [ text length ];
			updateScroll = 1;
			break;
		case NSLeftArrowFunctionKey:
			if ([ self hasHighlights ])
			{
				cursorIndex = highlights[0].location;
				if ((long)highlights[0].length < 0)
					cursorIndex = highlights[0].location + (long)highlights[0].length;
				scrollIndex = cursorIndex;
				updateScroll = 2;
				cursorTimer = 0;
				highlights.clear();
				break;
			}
			cursorTimer = 0;
			if (cursorIndex > 0)
				cursorIndex--;
			scrollIndex = cursorIndex;
			updateScroll = 2;
			highlights.clear();
			break;
		case NSRightArrowFunctionKey:
			if ([ self hasHighlights ])
			{
				cursorIndex = NSMaxRange(highlights[0]);
				if ((long)highlights[0].length < 0)
					cursorIndex = highlights[0].location;
				scrollIndex = cursorIndex;
				updateScroll = 1;
				cursorTimer = 0;
				highlights.clear();
				break;
			}
			cursorTimer = 0;
			if (cursorIndex < [ text length ])
				cursorIndex++;
			scrollIndex = cursorIndex;
			updateScroll = 1;
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
					scrollIndex = lowestLoc;
					
					unsigned long lastIndex = [ set lastIndex ];
					do
					{
						if (lastIndex == NSNotFound)
							break;
						scrollx -= [ characters[lastIndex] frameSize ].width;
						if (scrollx < 0)
							scrollx = 0;
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
					scrollIndex--;
					scrollx -= [ characters[cursorIndex] frameSize ].width;
					if (scrollx < 0)
						scrollx = 0;
					[ self deleteCharacterAtIndex:cursorIndex ];
					cursorTimer = 0;
				}
			}
			break;
		default:
		{
			if (!editable)
				break;
			if (numeric)
			{
				if (!((key >= '0' && key <= '9') || key == '.'))
					break;
				// Check if already has a '.'
				NSRange range = [ text rangeOfString:@"." ];
				if (range.length != 0 && key == '.')
					break;
			}
			
			
			if (key == NSCarriageReturnCharacter || key == NSEnterCharacter ||
				key == NSNewlineCharacter)
			{
				if (target != nil && [ target respondsToSelector:action ])
					((void (*)(id, SEL, id))[ target methodForSelector:action ])(target, action, self);
				break;
			}
			if (key == NSTabCharacter)
				break;
			
			if ([ self hasHighlights ])
			{
				if (highlights.size() != 0)
				{
					cursorIndex = highlights[0].location;
					scrollIndex = cursorIndex;
				}
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
						{
							cursorIndex--;
							scrollIndex--;
						}
					}
				}
				
				unsigned long lastIndex = [ set lastIndex ];
				do
				{
					if (lastIndex == NSNotFound)
						break;
					scrollx -= [ characters[lastIndex] frameSize ].width;
					if (scrollx < 0)
						scrollx = 0;
					[ self deleteCharacterAtIndex:lastIndex ];
					lastIndex = [ set indexLessThanIndex:lastIndex ];
				}
				while (lastIndex != NSNotFound);

				highlights.clear();
				cursorTimer = 0;
			}
			
			[ self addCharacter:key toIndex:cursorIndex ];
			cursorIndex++;
			scrollIndex = cursorIndex;
			cursorTimer = 0;
			updateScroll = 1;
			break;
		}
	}
	
	if (keyTar && [ keyTar respondsToSelector:keyAct ])
		((void (*)(id, SEL, id))[ keyTar methodForSelector:keyAct ])(keyTar, keyAct, self);
}

- (void) setKeyTarget: (id) tkey
{
	keyTar = tkey;
}

- (id) keyTarget
{
	return keyTar;
}

- (void) setKeyAction: (SEL) kact
{
	keyAct = kact;
}

- (SEL) keyAction
{
	return keyAct;
}

- (void) setEditable: (BOOL) edit
{
	editable = edit;
}

- (BOOL) editable
{
	return editable;
}

- (void) dealloc
{
	highlights.clear();
}

@end
