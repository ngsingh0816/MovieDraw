//
//  MDCodeView.mm
//  MovieDraw
//
//  Created by Neil Singh on 10/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MDCodeView.h"

@implementation MDCodeView

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
		[ [ self textStorage ] setFont:[ NSFont fontWithName:@"Menlo" size:11 ] ];
		[ self setDelegate:(id)self ];
		[ [ self textStorage ] setDelegate:(id)self ];
		if (!lineRanges)
			lineRanges = [ [ NSMutableIndexSet alloc ] init ];
    }
    
    return self;
}

- (void) setText:(NSString*)text
{
	[ self setFont:[ NSFont fontWithName:@"Menlo" size:11 ] ];
	[ self setDelegate:(id)self ];
	[ [ self textStorage ] setDelegate:(id)self ];
	if (!lineRanges)
		lineRanges = [ [ NSMutableIndexSet alloc ] init ];
	
	waitForEdit = TRUE;
	[ self setString:[ NSString stringWithString:text ] ];
	[ self processHighlight:NSMakeRange(0, [ text length ]) ];
	[ self setNeedsDisplay:YES ];
	waitForEdit = FALSE;
	
	[ self reloadLines ];
}

- (void) processHighlight: (NSRange)range
{
	if (range.length == 0)
		return;
	
	NSTextStorage* storage = [ self textStorage ];
	NSRange search = NSMakeRange(range.location, 0);
	NSString* text = [ self string ];
	[ storage removeAttribute:NSForegroundColorAttributeName range:range ];
	
	char posschar[] = { ' ', '\n', '\t', '`', '!', '#', '$', '%', '^', '&', '*', '(', ')', '-', '+', '=', '[', '{', '}', ']', '\\', '|', ',', '<', '>', '.', '?', '/', ';', ':', };
	// Types
	// C types
	const char* ctypes[] = { "unsigned", "signed", "char", "short", "int", "long", "const", "void", "float", "double", "BOOL", "bool", "if", "for", "while", "do", "self", "id", "@implementation", "@end", "@interface", "return", "@synthesize", "@property", "@protocol", "@selector", "@encode", "@try", "@catch", "@finally", "@throw", "@dynamic", "YES", "NO", "TRUE", "true", "FALSE", "false", "NULL", "nil", "Nil", "break", "switch", "case", "try", "catch", "throw", "and", "and_eq", "asm", "auto", "bitand", "bitor", "class", "compl", "const_cast", "continue", "default", "delete", "dynamic_cast", "else", "enum", "explicit", "extern", "friend", "goto", "inline", "mutable", "namespace", "new", "not", "not_eq", "operator", "or", "or_eq", "private", "protected", "public", "register", "reinterpret_cast", "sizeof", "static", "static_cast", "struct", "template", "this", "typedef", "typeid", "typename",  "union", "using", "virtual", "volatile", "wchar_t", "xor", "xor_eq", "@private", "@protected", "@public", "@synchronized", "byref", "oneway", "super", "in", "out", };
	for (int z = 0; z < sizeof(ctypes) / sizeof(const char*); z++)
	{
		search = NSMakeRange(range.location, 0);
		do
		{
			search = [ text rangeOfString:[ NSString stringWithUTF8String:ctypes[z] ] options:0 range:NSMakeRange(NSMaxRange(search), NSMaxRange(range) - NSMaxRange(search)) ];
			if (search.length == 0)
				break;
			if (search.location != 0)
			{
				BOOL doesContain = FALSE;
				unsigned char cmd = [ text characterAtIndex:search.location - 1 ];
				for (int q = 0; q < sizeof(posschar) / sizeof(char); q++)
				{
					if (cmd == posschar[q])
					{
						doesContain = TRUE;
						break;
					}
				}
				if (!doesContain)
					continue;
			}
			if (NSMaxRange(search) < [ text length ])
			{
				if (([ text characterAtIndex:NSMaxRange(search) ] >= '0' && [ text characterAtIndex:NSMaxRange(search) ] <= '9') || ([ text characterAtIndex:NSMaxRange(search) ] >= 'a' && [ text characterAtIndex:NSMaxRange(search) ] <= 'z') || ([ text characterAtIndex:NSMaxRange(search) ] >= 'A' && [ text characterAtIndex:NSMaxRange(search) ] <= 'Z'))
						continue;
			}
			[ storage addAttribute:NSForegroundColorAttributeName value:[ NSColor colorWithCalibratedRed:0.712569 green:0.2 blue:0.631373 alpha:1 ] range:search ];
		}
		while (search.length != 0);
	}
	search = NSMakeRange(range.location, 0);
	// # words
	do
	{
		search = [ text rangeOfString:@"#" options:0 range:NSMakeRange(NSMaxRange(search), NSMaxRange(range) - NSMaxRange(search)) ];
		if (search.length == 0)
			break;
		// Find last /n
		unsigned long long begin = search.location;
		while (begin != -1)
		{
			if ([ text characterAtIndex:begin ] == '\n')
				break;
			begin--;
		}
		if (begin == -1)
			begin = 0;
		// Check to see the charactes inbetween are valid
		BOOL isValid = TRUE;
		for (unsigned long long z = begin; z < search.location; z++)
		{
			if ([ text characterAtIndex:z ] != ' ' && [ text characterAtIndex:z ] != '\n' && [ text characterAtIndex:z ] != '\t')
			{
				isValid = FALSE;
				break;
			}
		}
		if (!isValid)
			continue;
		// Find next /n
		unsigned long long end = NSMaxRange(search);
		while (end < [ text length ])
		{
			if ([ text characterAtIndex:end ] == '\n')
				break;
			end++;
		}
		[ storage addAttribute:NSForegroundColorAttributeName value:[ NSColor colorWithCalibratedRed:0.466667 green:0.286275 blue:0.176471 alpha:1 ] range:NSMakeRange(search.location, end - search.location) ];
		// Check for #import / #include
		// Find next ' '
		end = NSMaxRange(search);
		if ([ [ text substringWithRange:NSMakeRange(search.location, 7) ] isEqualToString:@"#import" ] || [ [ text substringWithRange:NSMakeRange(search.location, 8) ] isEqualToString:@"#include" ])
		{
			if ([ [ text substringWithRange:NSMakeRange(search.location, 7) ] isEqualToString:@"#import" ])
				end += 6;
			else if ([ [ text substringWithRange:NSMakeRange(search.location, 8) ] isEqualToString:@"#include" ])
				end += 7;
			// Go after tabs and spaces
			BOOL goToNext = FALSE;
			while (end < [ text length ])
			{
				if ([ text characterAtIndex:end ] != ' ' && [ text characterAtIndex:end ] != '\t')
				{
					if ([ text characterAtIndex:end ] != '<' && [ text characterAtIndex:end ] != '"')
						goToNext = TRUE;
					break;
				}
				end++;
			}
			if (goToNext)
				continue;
			// Check if has <> or ""
			BOOL found = FALSE;
			while (end < [ text length ])
			{
				if ([ text characterAtIndex:end ] == '\n')
					break;
				if ([ text characterAtIndex:end ] == '<')
				{
					found = TRUE;
					break;
				}
				end++;
			}
			if (found)
			{
				// Find >
				search = [ text rangeOfString:@">" options:0 range:NSMakeRange(end, NSMaxRange(range) - end) ];
				if (search.length == 0)
					search.location = NSMaxRange(range);
				[ storage addAttribute:NSForegroundColorAttributeName value:[ NSColor colorWithCalibratedRed:0.878431 green:0.313726 blue:0.384314 alpha:1 ] range:NSMakeRange(end, NSMaxRange(search) - end) ];
				if (search.length == 0)
					continue;
			}
		}
	}
	while (search.length != 0);
	search = NSMakeRange(range.location, 0);
	// Numbers
	for (int z = 0; z < 10; z++)
	{
		search = NSMakeRange(range.location, 0);
		do
		{
			search = [ text rangeOfString:[ NSString stringWithFormat:@"%i", z ] options:0 range:NSMakeRange(NSMaxRange(search), NSMaxRange(range) - NSMaxRange(search)) ];
			if (search.length == 0)
				break;
			// Check previous stuff
			BOOL allClear = FALSE;
			for (unsigned long long index = search.location - 1; index != -1; index--)
			{
				if (([ text characterAtIndex:index ] >= 'a' && [ text characterAtIndex:index ] <= 'z') || ([ text characterAtIndex:index ] >= 'A' && [ text characterAtIndex:index ] <= 'Z') || [ text characterAtIndex:index ] == '~' || [ text characterAtIndex:index ] == '_')
				{
					if ([ text characterAtIndex:index ] == 'f' || [ text characterAtIndex:index ] == 'F' || [ text characterAtIndex:index ] == 'l')
						continue;
					break;
				}
				char cmd = [ text characterAtIndex:index ];
				for (int q = 0; q < sizeof(posschar) / sizeof(char); q++)
				{
					if (cmd == posschar[q])
					{
						allClear = TRUE;
						break;
					}
				}
				if (allClear)
					break;
			}
			if (!allClear)
				continue;
			if (NSMaxRange(search) < [ text length ] && ([ text characterAtIndex:NSMaxRange(search) ] == 'f' || [ text characterAtIndex:NSMaxRange(search) ] == 'l'))
				search.length++;
			[ storage addAttribute:NSForegroundColorAttributeName value:[ NSColor colorWithCalibratedRed:0.160784 green:0.203922 blue:0.870588 alpha:1 ] range:search ];
		}
		while (search.length != 0);
	}
	std::vector<NSRange> commentRanges;
	search = NSMakeRange(range.location, 0);
	// Comments
	// //
	do
	{
		search = [ text rangeOfString:@"//" options:0 range:NSMakeRange(NSMaxRange(search), NSMaxRange(range) - NSMaxRange(search)) ];
		if (search.length == 0)
			break;
		// Find next /n
		unsigned long long end = NSMaxRange(search);
		while (end < NSMaxRange(range))
		{
			if ([ text characterAtIndex:end ] == '\n')
				break;
			end++;
		}
		commentRanges.push_back(NSMakeRange(search.location, end - search.location));
		[ storage addAttribute:NSForegroundColorAttributeName value:[ NSColor colorWithCalibratedRed:0 green:0.48 blue:0 alpha:1 ] range:NSMakeRange(search.location, end - search.location) ];
	}
	while (search.length != 0);
	search = NSMakeRange(range.location, 0);
	// /* */
	do
	{
		search = [ text rangeOfString:@"/*" options:0 range:NSMakeRange(NSMaxRange(search), NSMaxRange(range) - NSMaxRange(search)) ];
		if (search.length == 0)
			break;
		// Find next */
		NSRange next = [ text rangeOfString:@"*/" options:0 range:NSMakeRange(NSMaxRange(search), NSMaxRange(range) - NSMaxRange(search)) ];
		if (next.length == 0)
			next.location = [ text length ];
		commentRanges.push_back(NSMakeRange(search.location, NSMaxRange(next) - search.location));
		[ storage addAttribute:NSForegroundColorAttributeName value:[ NSColor colorWithCalibratedRed:0 green:0.48 blue:0 alpha:1 ] range:NSMakeRange(search.location, NSMaxRange(next) - search.location) ];
	}
	while (search.length != 0);
	search = NSMakeRange(range.location, 0);
	BOOL fullString = TRUE;
	std::vector<NSRange> stringRanges;
	// Strings
	do
	{
		if (fullString)
			search = [ text rangeOfString:@"\"" options:0 range:NSMakeRange(NSMaxRange(search), NSMaxRange(range) - NSMaxRange(search)) ];
		else
			search = [ text rangeOfString:@"'" options:0 range:NSMakeRange(NSMaxRange(search), NSMaxRange(range) - NSMaxRange(search)) ];
		if (search.length == 0)
		{
			if (!fullString)
				break;
			search = NSMakeRange(range.location, 1);
			fullString = !fullString;
			continue;
		}
		// If its in a comment, ignore it
		BOOL shouldContinue = FALSE;
		for (int z = 0; z < commentRanges.size(); z++)
		{
			if (search.location >= commentRanges[z].location && NSMaxRange(search) <= NSMaxRange(commentRanges[z]))
			{
				shouldContinue = TRUE;
				break;
			}
		}
		if (shouldContinue)
			continue;
		if (!fullString)
		{
			for (int z = 0; z < stringRanges.size(); z++)
			{
				if (search.location >= stringRanges[z].location && NSMaxRange(search) <= NSMaxRange(stringRanges[z]))
				{
					shouldContinue = TRUE;
					break;
				}
			}
			if (shouldContinue)
				continue;
		}
		
		// Find next "
		unsigned long long end = NSMaxRange(search);
		while (end < NSMaxRange(range))
		{
			if (([ text characterAtIndex:end ] == '"' && fullString) || ([ text characterAtIndex:end ] == '\'' && !fullString))
			{
				end++;
				break;
			}
			if ([ text characterAtIndex:end ] == '\\')
				end++;
			end++;
		}
		if ([ text characterAtIndex:search.location - 1 ] == '@')
			search.location--;
		if (fullString)
		{
			stringRanges.push_back(NSMakeRange(search.location, end - search.location - 1));
			[ storage addAttribute:NSForegroundColorAttributeName value:[ NSColor colorWithCalibratedRed:0.878431 green:0.313726 blue:0.384314 alpha:1 ] range:NSMakeRange(search.location, end - search.location) ];
		}
		else
		{
			[ storage addAttribute:NSForegroundColorAttributeName value:[ NSColor colorWithCalibratedRed:0.160784 green:0.203922 blue:0.870588 alpha:1 ] range:NSMakeRange(search.location, end - search.location) ];
		}
		NSRange stringRange = NSMakeRange(search.location, end - search.location - 1);
		search.location = end - 1;
		
		// If text starts before comment and ends somewhere inbetween, delete that comment
		for (int z = 0; z < commentRanges.size(); z++)
		{
			if (stringRange.location <= commentRanges[z].location && NSMaxRange(stringRange) >= commentRanges[z].location && NSMaxRange(stringRange) <= NSMaxRange(commentRanges[z]))
			{
				NSRange processRange = NSMakeRange(NSMaxRange(stringRange) + 1, NSMaxRange(commentRanges[z]) - NSMaxRange(stringRange) - 1);
				if (NSMaxRange(processRange) > [ text length ] || processRange.location > [ text length ] || processRange.length > [ text length ])
					continue;
				if (processRange.length == 0)
					continue;
				[ self processHighlight:processRange ];
				commentRanges.erase(commentRanges.begin() + z);
				z--;
				continue;
			}
		}
		if (!fullString)
		{
			for (int z = 0; z < stringRanges.size(); z++)
			{
				if (stringRange.location <= stringRanges[z].location && NSMaxRange(stringRange) >= stringRanges[z].location && NSMaxRange(stringRange) <= NSMaxRange(stringRanges[z]))
				{
					NSRange processRange = NSMakeRange(NSMaxRange(stringRange) + 1, [ text length ] - NSMaxRange(stringRange) - 1);
					if (NSMaxRange(processRange) > [ text length ] || processRange.location > [ text length ] || processRange.length > [ text length ])
						continue;
					if (processRange.length == 0)
						continue;
					[ self processHighlight:processRange ];
					stringRanges.erase(stringRanges.begin() + z);
					z--;
					continue;
				}
			}
		}
		
		if (end == NSMaxRange(range))
		{
			if (!fullString)
				break;
			search = NSMakeRange(range.location, 1);
			fullString = !fullString;
			continue;
		}
		if (search.length == 0)
		{
			if (!fullString)
				break;
			search = NSMakeRange(range.location, 1);
			fullString = !fullString;
			continue;
		}
	}
	while (search.length != 0);
}

- (char) lastRealCharFromIndex:(unsigned long long) start
{
	NSString* text = [ self string ];
	
	unsigned long long tmp = start;
	while (tmp != -1)
	{
		if ([ text characterAtIndex:tmp ] != ' ' && [ text characterAtIndex:tmp ] != '\n' && [ text characterAtIndex:tmp ] != '\t')
			break;
		tmp--;
	}
	if (tmp == -1)
		tmp++;
	
	if (tmp == 0)
		return 0;
	return [ text characterAtIndex:tmp ];
}

- (void) keyDown:(NSEvent *)theEvent
{
	[ super keyDown:theEvent ];
	
	unsigned short key = [ [ theEvent characters ] characterAtIndex:0 ];
	if (key == NSUpArrowFunctionKey || key == NSDownArrowFunctionKey || key == NSLeftArrowFunctionKey || key == NSRightArrowFunctionKey)
		return;
	
	if (key == '}')
	{
		unsigned long long cursor = [ [ [ self selectedRanges ] objectAtIndex:0 ] rangeValue ].location;
		unsigned long long bcursor = cursor;
		if (cursor != 0 && ([ [ self string ] characterAtIndex:cursor - 2 ] == '\t' || [ [ self string ] characterAtIndex:cursor - 2 ] == ' '))
		{
			if ([ [ self string ] characterAtIndex:cursor - 2 ] == ' ')
			{
				// Find last \t
				unsigned long long z = cursor - 3;
				while (z != -1)
				{
					if ([ [ self string ] characterAtIndex:z ] == '\t')
						break;
					z--;
				}
				cursor = z;
			}
			NSMutableString* newString = [ [ NSMutableString alloc ] initWithString:[ self string ] ];
			[ newString deleteCharactersInRange:NSMakeRange(cursor - 2, 1) ];
			[ self setString:newString ];
			[ self setSelectedRange:NSMakeRange(bcursor - 1, 0) affinity:NSSelectionAffinityDownstream stillSelecting:NO ];
			[ newString release ];
		}

	}
	
	if (key == NSBackspaceCharacter || key == NSDeleteCharacter)
	{
		/*// If the last one was a '\n', move errors
		NSRange cursorR = [ [ [ self selectedRanges ] objectAtIndex:0 ] rangeValue ];
		BOOL containsLine = FALSE;
		unsigned long lineNumber = -1;
		for (unsigned long z = NSMaxRange(cursorR); z >= cursorR.location; z--)
		{
			for (int tot = 0; tot < 6; tot++)
			{
				unsigned short cool = [ [ self string ] characterAtIndex:z - tot ];
				if (cool == '\t')
					NSLog(@"\\t");
				else if (cool == '\n')
					NSLog(@"\\n");
				else
					NSLog(@"%c", [ [ self string ] characterAtIndex:z - tot ]);
			}
			if ([ [ self string ] characterAtIndex:z - 1 ] == '\n')
			{
				unsigned long* lines = (unsigned long*)malloc([ lineRanges count ] * sizeof(unsigned long));
				[ lineRanges getIndexes:lines maxCount:[ lineRanges count ] inIndexRange:nil ];
				for (int y = 0; y < [ lineRanges count ] - 1; y++)
				{
					if (z - 1 >= lines[y] && z - 1 <= lines[y + 1])
					{
						lineNumber = y;
						break;
					}
				}
				free(lines);
				lines = NULL;
				
				containsLine = TRUE;
				break;
			}
		}
		if (containsLine && lineNumber != -1)
		{
			for (int z = 0; z < errors.size(); z++)
			{
				if (errors[z].line >= lineNumber)
					errors[z].line--;
			}
		}*/
		
		// For now just remove all the errors
		errors.clear();
	}
	
	if (!(key == NSNewlineCharacter || key == NSEnterCharacter || key == NSCarriageReturnCharacter))
		return;
	
	// Check if last was "if", "for", "while", "do"
	unsigned long long cursor = [ [ [ self selectedRanges ] objectAtIndex:0 ] rangeValue ].location;
	// Find last ';'
	unsigned long long z = cursor;
	BOOL foundIf = FALSE;
	while (z != -1)
	{
		if ([ [ self string ] characterAtIndex:z ] == ';')
		{
			z++;
			
			while ([ [ self string ] characterAtIndex:z ] == ' ' || [ [ self string ] characterAtIndex:z ] == '\t' || [ [ self string ] characterAtIndex:z ] == '\n') { z++; }
			
			NSMutableString* realString = [ NSMutableString stringWithString:[ [ self string ] substringWithRange:NSMakeRange(z, cursor - z) ] ];
			[ realString replaceOccurrencesOfString:@" " withString:@"" options:0 range:NSMakeRange(0, [ realString length ]) ];
			if ([ realString hasPrefix:@"if(" ] || [ realString hasPrefix:@"for(" ] || [ realString hasPrefix:@"while(" ] || [ realString hasPrefix:@"do" ])
			{
				if ([ realString hasPrefix:@"do" ])
				{
					// Check next letter
					char posschar[] = { ' ', '\n', '\t', '`', '!', '#', '$', '%', '^', '&', '*', '(', ')', '-', '+', '=', '[', '{', '}', ']', '\\', '|', ',', '<', '>', '.', '?', '/', ';', ':', };
					BOOL foundChar = FALSE;
					for (int q = 0; q < sizeof(posschar); q++)
					{
						if ([ realString characterAtIndex:3 ] == posschar[q])
							foundChar = TRUE;
					}
					if (!foundChar)
						break;
					
					z = cursor;
					// Find how indented it is
					unsigned int count = 1;
					unsigned int count2 = 0;
					unsigned long long prevZ = z;
					while ([ [ self string ] characterAtIndex:z-- ] == '\t')
						count++;
					z = prevZ;
					while ([ [ self string ] characterAtIndex:z-- ] == ' ')
						count2++;
					NSMutableString* newString = [ [ NSMutableString alloc ] initWithString:[ self string ] ];
					for (int q = 0; q < count; q++)
						[ newString insertString:@"\t" atIndex:cursor ];
					for (int q = 0; q < count2; q++)
						[ newString insertString:@" " atIndex:cursor ];
					[ self setString:newString ];
					[ self setSelectedRange:NSMakeRange(cursor + count, 0) affinity:NSSelectionAffinityDownstream stillSelecting:NO ];
					[ newString release ];
				}
				foundIf = TRUE;
			}
			break;
		}
		z--;
	}
	if (foundIf)
		return;
	
	// Find last '{'
	z = cursor;
	unsigned long long quantity = 0;
	unsigned long long quantity2 = 0;
	while (z != -1)
	{
		if ([ [ self string ] characterAtIndex:z ] == '{' && quantity == 0)
		{
			z--;
			// Find how indented it is
			unsigned int count = 1;
			unsigned int count2 = 0;
			unsigned long long prevZ = z;
			while ([ [ self string ] characterAtIndex:z-- ] == '\t')
				count++;
			z = prevZ;
			while ([ [ self string ] characterAtIndex:z-- ] == ' ')
				count2++;
			NSMutableString* newString = [ [ NSMutableString alloc ] initWithString:[ self string ] ];
			for (int q = 0; q < count; q++)
				[ newString insertString:@"\t" atIndex:cursor ];
			for (int q = 0; q < count2; q++)
				[ newString insertString:@" " atIndex:cursor ];
			[ self setString:newString ];
			[ self setSelectedRange:NSMakeRange(cursor + count, 0) affinity:NSSelectionAffinityDownstream stillSelecting:NO ];
			[ newString release ];
			break;
		}
		else if ([ [ self string ] characterAtIndex:z ] == '[' && quantity == 0)
		{
		}
		else if ([ [ self string ] characterAtIndex:z ] == '{' && quantity != 0)
			quantity--;
		else if ([ [ self string ] characterAtIndex:z ] == '[' && quantity2 != 0)
			quantity2--;
		else if ([ [ self string ] characterAtIndex:z ] == ']')
			quantity2++;
		else if ([ [ self string ] characterAtIndex:z ] == '}')
		{
			z--;
			quantity++;
		}
		z--;
	}
	
	// Update errors
	unsigned long long cursorPosition = [ [ [ self selectedRanges ] objectAtIndex:0 ] rangeValue ].location;
	unsigned long* lines = (unsigned long*)malloc([ lineRanges count ] * sizeof(unsigned long));
	[ lineRanges getIndexes:lines maxCount:[ lineRanges count ] inIndexRange:nil ];
	for (int z = 0; z < [ lineRanges count ] - 1; z++)
	{
		if (cursorPosition >= lines[z] && cursorPosition <= lines[z + 1])
		{
			// Add 1 line to all errors higher than this
			for (int y = 0; y < errors.size(); y++)
			{
				if (errors[y].line > z)
					errors[y].line++;
			}
			break;
		}
	}
	free(lines);
	lines = NULL;
}


- (void) textStorageDidProcessEditing:(NSNotification*)notification
{
	if (waitForEdit)
		return;
	
	NSScrollView *sv = [ self enclosingScrollView ];
	if(!sv) 
		return;
	NSLayoutManager *lm = [ self layoutManager ];
	NSRect visRect = [ self visibleRect ];
	NSPoint tco = [ self textContainerOrigin ];
	visRect.origin.x -= tco.x;
	visRect.origin.y -= tco.y;
	NSRange glyphRange = [ lm glyphRangeForBoundingRect:visRect inTextContainer:[ self textContainer ] ];
	NSRange charRange = [ lm characterRangeForGlyphRange:glyphRange actualGlyphRange:nil ];
	
	// Backspace
	if (NSMaxRange(charRange) >= [ [ self string ] length ])
		charRange = NSMakeRange(0, [ [ self string ] length ]);
	[ self processHighlight:charRange ];
	
	[ self reloadLines ];
}

- (void) drawRect:(NSRect)dirtyRect
{
	[ super drawRect:dirtyRect ];
	
	[ self lockFocusIfCanDraw ];
	unsigned long* lines = (unsigned long*)malloc([ lineRanges count ] * sizeof(unsigned long));
	[ lineRanges getIndexes:lines maxCount:[ lineRanges count ] inIndexRange:nil ];
	// Draw errors
	for (int z = 0; z < errors.size(); z++)
	{
		// Figure out range of that line
		NSRange range = NSMakeRange(lines[errors[z].line - 1], lines[errors[z].line] - lines[errors[z].line - 1] - 1);
		NSLayoutManager *layoutManager = [self layoutManager];
		range = [ layoutManager glyphRangeForCharacterRange:range actualCharacterRange:NULL ];
		NSRect rect = [ layoutManager boundingRectForGlyphRange:range inTextContainer:[ self textContainer ] ];
		NSPoint containerOrigin = [ self  textContainerOrigin ];
		rect = NSOffsetRect(rect,containerOrigin.x,containerOrigin.y);
		float oldOffset = rect.origin.x + rect.size.width + 20;
		rect.size.width += rect.origin.x + 20;
		rect.origin.x = 0;
		if (errors[z].type == MD_ERROR)
			[ [ NSColor colorWithCalibratedRed:0.97 green:0.6 blue:0.6 alpha:0.3 ] set ];
		else
			[ [ NSColor colorWithCalibratedRed:0.96 green:0.90 blue:0.62 alpha:0.3 ] set ];		
		NSBezierPath* path = [ [ NSBezierPath alloc ] init ];
		[ path moveToPoint:NSMakePoint(rect.origin.x, rect.origin.y) ];
		[ path lineToPoint:NSMakePoint(rect.origin.x, rect.origin.y + rect.size.height) ];
		[ path lineToPoint:NSMakePoint(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height) ];
		[ path lineToPoint:NSMakePoint(rect.origin.x + rect.size.width, rect.origin.y) ];
		[ path closePath ];
		[ path fill ];
		[ path release ];
		
		if (errors[z].type == MD_ERROR)
			[ [ NSColor colorWithCalibratedRed:0.97 green:0.6 blue:0.6 alpha:1 ] set ];
		else
			[ [ NSColor colorWithCalibratedRed:0.96 green:0.90 blue:0.62 alpha:1 ] set ];	
		path = [ [ NSBezierPath alloc ] init ];
		[ path moveToPoint:NSMakePoint(oldOffset, rect.origin.y) ];
		[ path lineToPoint:NSMakePoint(oldOffset - 5, rect.origin.y + (rect.size.height / 2)) ];
		[ path lineToPoint:NSMakePoint(oldOffset, rect.origin.y + rect.size.height) ];
		[ path lineToPoint:NSMakePoint(dirtyRect.size.width, rect.origin.y + rect.size.height) ];
		[ path lineToPoint:NSMakePoint(dirtyRect.size.width, rect.origin.y) ];
		[ path closePath ];
		[ path fill ];
		[ path release ];
		path = nil;
		
		NSAttributedString* string = [ [ NSAttributedString alloc ] initWithString:errors[z].error attributes:[ NSDictionary dictionaryWithObjectsAndKeys:[ NSFont fontWithName:@"Helvetica" size:10 ], NSFontAttributeName, nil ] ];
		[ string drawAtPoint:NSMakePoint(oldOffset + 3, rect.origin.y - (rect.size.height / 2) + 7) ];
		[ string release ];
	}
	free(lines);
	lines = NULL;
	[ self unlockFocus ];
}

- (void) addError:(NSString*)error atLine:(unsigned long long)line type:(unsigned int)etype
{
	MDError er;
	memset(&er, 0, sizeof(er));
	er.error = [ [ NSString alloc ] initWithString:error ];
	er.line = line;
	er.type = etype;
	errors.push_back(er);
	
	[ self setNeedsDisplay:YES ];
}

- (void) removeAllErrors
{
	for (int z = 0; z < errors.size(); z++)
		[ errors[z].error release ];
	errors.clear();
}

- (std::vector<MDError>&) errors
{
	return errors;
}

- (BOOL) hasErrors
{
	if (errors.size() != 0)
		return YES;
	return NO;
}

- (void) reloadLines
{
	// Index every line
	[ lineRanges removeAllIndexes ];
	NSRange range = NSMakeRange(0, 0);
	[ lineRanges addIndex:0 ];
	for (;;)
	{
		range = [ [ self string ] rangeOfString:@"\n" options:0 range:NSMakeRange(NSMaxRange(range), [ [ self string ] length ] - NSMaxRange(range)) ];
		if (range.length == 0)
			break;
		[ lineRanges addIndex:range.location + 1 ];
		range.location++;
		range.length = 0;
	}
}

- (void) dealloc
{
	for (int z = 0; z < errors.size(); z++)
		[ errors[z].error release ];
	errors.clear();
	if (lineRanges)
	{
		[ lineRanges release ];
		lineRanges = nil;
	}
	
	[ super dealloc ];
}

@end
