//
//  CodeHelpView.m
//  MovieDraw
//
//  Created by Neil on 8/1/13.
//  Copyright (c) 2013 Neil. All rights reserved.
//

#import "CodeHelpView.h"
#include <vector>

@interface MDLink : NSTextField
{
	NSTrackingArea* trackingArea;
	BOOL over;
	BOOL wasOver;
	id target;
	SEL action;
	NSString* path;
}

@property (strong) id linkTarget;
@property  SEL linkAction;
@property (copy) NSString *path;

@end

@implementation MDLink

- (void) setLinkTarget:(id)tar
{
	target = tar;
}

- (id) linkTarget
{
	return target;
}

- (void) setLinkAction:(SEL)act
{
	action = act;
}

- (SEL) linkAction
{
	return action;
}

- (void) setPath:(NSString*)p
{
	path = [ [ NSString alloc ] initWithString:p ];
}

- (NSString*) path
{
	return path;
}

- (void) setStringValue:(NSString *)aString
{
	[ super setStringValue:aString ];
	
	NSRect rect = [ self bounds ];
	rect.size = [ aString boundingRectWithSize:NSMakeSize(800, 0) options:NSLineBreakByWordWrapping | NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: [ self font ]} ].size;
	
	trackingArea = [ [ NSTrackingArea alloc ] initWithRect:rect options:(NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways) owner:self userInfo:nil ];
    [ self addTrackingArea:trackingArea ];
}

- (void) mouseEntered:(NSEvent *)theEvent
{
	NSMutableAttributedString* str = [ [ NSMutableAttributedString alloc ] initWithAttributedString:[ self attributedStringValue ] ];
	[ str beginEditing ];
	[ str addAttribute:NSUnderlineStyleAttributeName value:[ NSNumber numberWithInt:NSSingleUnderlineStyle ] range:NSMakeRange(0, [ str length ]) ];
	[ str endEditing ];
	[ self setAttributedStringValue:str ];
	[ [ NSCursor pointingHandCursor ] set ];
	over = TRUE;
}

- (void) mouseExited:(NSEvent *)theEvent
{
	NSMutableAttributedString* str = [ [ NSMutableAttributedString alloc ] initWithAttributedString:[ self attributedStringValue ] ];
	[ str beginEditing ];
	[ str removeAttribute:NSUnderlineStyleAttributeName range:NSMakeRange(0, [ str length ]) ];
	[ str endEditing ];
	[ self setAttributedStringValue:str ];
	[ [ NSCursor arrowCursor ] set ];
	over = FALSE;
}

- (void) mouseDown:(NSEvent *)theEvent
{
	wasOver = over;
}

- (void) mouseUp:(NSEvent *)theEvent
{
	if (over && wasOver)
	{
		if (target && [ target respondsToSelector:action ])
			((void (*)(id, SEL, id))[ target methodForSelector:action ])(target, action, self);
	}
	wasOver = FALSE;
}

@end

@interface MDExample : NSTextView
{
	NSString* name;
}

@property (assign) BOOL setName;

- (void) processHighlight:(NSRange)range;
@property (copy) NSString *name;

@end

@implementation MDExample

@synthesize setName;

- (void) setName:(NSString*)nam
{
	name = [ [ NSString alloc ] initWithString:nam ];
}

- (NSString*) name
{
	return name;
}

- (void) setString:(NSString *)string
{
	[ super setString:string ];
	[ self processHighlight:NSMakeRange(0, [ string length ]) ];
}

const char* atypes[] = { "unsigned", "signed", "char", "short", "int", "long", "const", "void", "float", "double", "BOOL", "bool", "if", "for", "while", "do", "self", "id", "SEL", "IMP", "@implementation", "@end", "@interface", "return", "@synthesize", "@property", "@protocol", "@selector", "@encode", "@try", "@catch", "@finally", "@throw", "@dynamic", "YES", "NO", "TRUE", "true", "FALSE", "false", "NULL", "nil", "Nil", "break", "switch", "case", "try", "catch", "throw", "and", "and_eq", "asm", "auto", "bitand", "bitor", "class", "compl", "const_cast", "continue", "default", "delete", "dynamic_cast", "else", "enum", "explicit", "extern", "friend", "goto", "inline", "mutable", "namespace", "new", "not", "not_eq", "operator", "or", "or_eq", "private", "protected", "public", "register", "reinterpret_cast", "sizeof", "static", "static_cast", "struct", "template", "this", "typedef", "typeid", "typename",  "union", "using", "virtual", "volatile", "wchar_t", "xor", "xor_eq", "@class", "@private", "@protected", "@public", "@synchronized", "byref", "oneway", "super", "in", "out", };
char aposschar[] = { ' ', '\n', '\t', '`', '!', '#', '$', '%', '^', '&', '*', '(', ')', '-', '+', '=', '[', '{', '}', ']', '\\', '|', ',', '<', '>', '.', '?', '/', ';', ':', };
const char* objtypes[] = { "MDScalar", "MDVector2", "MDVector3", "MDVector4", "MDMatrix", "MDPoint", "MDObject", "MDMesh", "MDTexture", "MDInstance", "MDCamera", "MDLight", "MDParticleEngine", "MDCurve", "GLString", "GLView", "GLWindow", "NSString", "NSArray", "NSMutableString", "NSMutableArray", "NSDictionary", "NSMutableDictionary", "NSObject", "NSColor", "NSSize", "NSRect", "MDParticle", "MDParticleVertex", "std::vector", };

- (void) processHighlight: (NSRange)range
{
	NSTextStorage* storage = [ self textStorage ];
	NSRange search = NSMakeRange(0, 0);
	NSString* text = [ self string ];
	[ storage removeAttribute:NSForegroundColorAttributeName range:range ];
	[ storage removeAttribute:NSStrokeWidthAttributeName range:range ];	
	
	// Bold name
	if (name)
	{
		search = NSMakeRange(0, 0);
		do
		{
			search = [ text rangeOfString:name options:0 range:NSMakeRange(NSMaxRange(search), NSMaxRange(range) - NSMaxRange(search)) ];
			if (search.length == 0)
				break;
			if (search.location != 0)
			{
				BOOL doesContain = FALSE;
				unsigned char cmd = [ text characterAtIndex:search.location - 1 ];
				for (int q = 0; q < sizeof(aposschar) / sizeof(char); q++)
				{
					if (cmd == aposschar[q])
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
			[ storage addAttribute:NSStrokeWidthAttributeName value:@-3.0f range:search ];
		}
		while (search.length != 0);
	}
	if (setName && [ name length ] != 0)
	{
		NSString* otherName = [ NSString stringWithFormat:@"set%c%@", toupper([ name characterAtIndex:0 ]), [ name substringFromIndex:1 ] ];
		search = NSMakeRange(0, 0);
		do
		{
			search = [ text rangeOfString:otherName options:0 range:NSMakeRange(NSMaxRange(search), NSMaxRange(range) - NSMaxRange(search)) ];
			if (search.length == 0)
				break;
			if (search.location != 0)
			{
				BOOL doesContain = FALSE;
				unsigned char cmd = [ text characterAtIndex:search.location - 1 ];
				for (int q = 0; q < sizeof(aposschar) / sizeof(char); q++)
				{
					if (cmd == aposschar[q])
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
			[ storage addAttribute:NSStrokeWidthAttributeName value:@-3.0f range:search ];
		}
		while (search.length != 0);
	}
	
	// Types
	for (int z = 0; z < sizeof(atypes) / sizeof(const char*); z++)
	{
		search = NSMakeRange(0, 0);
		do
		{
			search = [ text rangeOfString:@(atypes[z]) options:0 range:NSMakeRange(NSMaxRange(search), NSMaxRange(range) - NSMaxRange(search)) ];
			if (search.length == 0)
				break;
			if (search.location != 0)
			{
				BOOL doesContain = FALSE;
				unsigned char cmd = [ text characterAtIndex:search.location - 1 ];
				for (int q = 0; q < sizeof(aposschar) / sizeof(char); q++)
				{
					if (cmd == aposschar[q])
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
	
	for (int z = 0; z < sizeof(objtypes) / sizeof(const char*); z++)
	{
		search = NSMakeRange(0, 0);
		do
		{
			search = [ text rangeOfString:@(objtypes[z]) options:0 range:NSMakeRange(NSMaxRange(search), NSMaxRange(range) - NSMaxRange(search)) ];
			if (search.length == 0)
				break;
			if (search.location != 0)
			{
				BOOL doesContain = FALSE;
				unsigned char cmd = [ text characterAtIndex:search.location - 1 ];
				for (int q = 0; q < sizeof(aposschar) / sizeof(char); q++)
				{
					if (cmd == aposschar[q])
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
			[ storage addAttribute:NSForegroundColorAttributeName value:[ NSColor colorWithCalibratedRed:0.435294 green:0.254902 blue:0.654902 alpha:1 ] range:search ];
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
		if ([ text length ] <= search.location + 8)
			continue;
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
				for (int q = 0; q < sizeof(aposschar) / sizeof(char); q++)
				{
					if (cmd == aposschar[q])
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
	search = NSMakeRange(0, 0);
	// /* */
	do
	{
		search = [ text rangeOfString:@"/*" options:0 range:NSMakeRange(NSMaxRange(search), [ text length ] - NSMaxRange(search)) ];
		if (search.length == 0)
			break;
		// Find next */
		NSRange next = [ text rangeOfString:@"*/" options:0 range:NSMakeRange(NSMaxRange(search), [ text length ] - NSMaxRange(search)) ];
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

- (void) drawRect:(NSRect)dirtyRect
{
	[ super drawRect:dirtyRect ];
	
	[ self lockFocusIfCanDraw ];
	
	[ [ NSColor colorWithCalibratedRed:0.945098 green:0.945098 blue:0.945098 alpha:1 ] set ];
	NSRectFill(NSMakeRect(0, 0, 29,  [ self frame ].size.height));
	[ [ NSColor colorWithCalibratedRed:0.6 green:0.6 blue:0.6 alpha:1 ] set ];
	NSRectFill(NSMakeRect(29, 0, 1, [ self frame ].size.height));
	unsigned long current = 1;
	float currentHeight = 0;
	NSArray* lines = [ [ self string ] componentsSeparatedByString:@"\n" ];
	while (current - 1 < [ lines count ])
	{
		NSColor* trueColor = [ NSColor colorWithCalibratedRed:0.6 green:0.6 blue:0.6 alpha:1 ];
		NSMutableAttributedString* test = [ [ NSMutableAttributedString alloc ] initWithString:[ NSString stringWithFormat:@"%lu", current ] attributes:@{NSFontAttributeName: [ NSFont fontWithName:@"Helvetica" size:10 ], NSForegroundColorAttributeName: trueColor} ];
		
		[ test drawInRect:NSMakeRect(27 - [ test size ].width, currentHeight - 1, [ test size ].width, [ test size ].height) ];
		
		/*if (current - 1 < [ lines count ])
		{
			NSString* string2 = [ lines objectAtIndex:current - 1 ];
			NSAttributedString* string =  [ [ NSMutableAttributedString alloc ] initWithString:string2 attributes:[ NSDictionary dictionaryWithObjectsAndKeys:[ NSFont fontWithName:@"Menlo" size:11 ], NSFontAttributeName, [ NSColor colorWithCalibratedRed:0.6 green:0.6 blue:0.6 alpha:1 ], NSForegroundColorAttributeName, nil ] ];
		}*/
		
		currentHeight += [ test size ].height;
		current++;
	}
	
	[ self unlockFocus ];
}

@end

unsigned long PositionAfterSpaces(unsigned long pos, NSString* string)
{
	unsigned long pos2 = pos;
	while (pos2 < [ string length ])
	{
		char cmd = [ string characterAtIndex:pos2++ ];
		if (cmd != ' ' && cmd != '\t' && cmd != '\n')
		{
			pos2--;
			break;
		}
	}
	return pos2;
}

unsigned long PositionBeforeSpaces(unsigned long pos, NSString* string)
{
	unsigned long pos2 = pos;
	while (pos2 <= [ string length ])
	{
		char cmd = [ string characterAtIndex:--pos2 ];
		if (cmd != ' ' && cmd != '\t' && cmd != '\n')
		{
			pos2++;
			break;
		}
	}
	return pos2;
}

NSString* ReadTag(unsigned long* pos, NSString* string)
{	
	if (*pos >= [ string length ] || [ string characterAtIndex:*pos ] != '<')
		return @"";
	
	// Read starting tag
	unsigned long startPos = *pos;
	while (*pos < [ string length ])
	{
		char cmd = [ string characterAtIndex:(*pos)++ ];
		if (cmd == '>')
			break;
	}
	
	// Find end tag
	unsigned long tempPos = *pos;
	unsigned long quantity = 1;
	while (tempPos < [ string length ])
	{
		char cmd = [ string characterAtIndex:tempPos++ ];
		if (cmd == '<' && tempPos > 2 && [ string characterAtIndex:tempPos - 2] != '\\')
		{
			if (tempPos < [ string length ])
			{
				char cmd2 = [ string characterAtIndex:tempPos++ ];
				if (cmd2 == '/')
					quantity--;
				else
					quantity++;
			}
		}
		
		if (quantity == 0)
			break;
	}
	
	*pos = tempPos;
	while (*pos < [ string length ])
	{
		char cmd = [ string characterAtIndex:(*pos)++ ];
		if (cmd == '>')
			break;
	}
	
	return [ string substringWithRange:NSMakeRange(startPos, (*pos) - startPos) ];
}

NSString* GetTagName(NSString* string)
{
	unsigned long pos = 0;
	if ([ string characterAtIndex:pos++ ] != '<')
		return @"";
	
	// Read starting tag
	unsigned long startPos = pos;
	while (pos < [ string length ])
	{
		char cmd = [ string characterAtIndex:pos++ ];
		if (cmd == '>')
			break;
	}
	return [ string substringWithRange:NSMakeRange(startPos, pos - 1 - startPos) ];
}

NSString* GetTagData(NSString* string)
{
	NSString* name = GetTagName(string);
	unsigned long pos = [ name length ] + 2;
	if (pos > [ string length ])
		return @"";
	
	return [ string substringWithRange:NSMakeRange(pos, [ string length ] - pos - 1 - pos) ];
}

BOOL InterpretTagData(NSString* string, unsigned long* pos, NSMutableDictionary* dictionary)
{
	*pos = PositionAfterSpaces(*pos, string);
	NSString* tag = ReadTag(pos, string);
	if (![ tag length ])
		return FALSE;
	NSString* name = GetTagName(tag);
	NSString* data = GetTagData(tag);
	
	unsigned long dataPos = PositionAfterSpaces(0, data);
	// Add it if its a single thing
	if ([ data length ] > dataPos && ([ data characterAtIndex:dataPos ] != '<' || ([ data characterAtIndex:dataPos ] == '<' && [ data length ] > dataPos + 2 && [ data characterAtIndex:dataPos + 1 ] == 'b' && [ data characterAtIndex:dataPos + 2 ] == '>')))
	{
		NSString* realData = data;
		// Escape codes
		realData = [ realData stringByReplacingOccurrencesOfString:@"\\<" withString:@"<" ];
		realData = [ realData stringByReplacingOccurrencesOfString:@"\\>" withString:@">" ];
		if (![ name isEqualToString:@"example" ])
		{
			unsigned long start = PositionAfterSpaces(0, realData);
			realData = [ realData substringWithRange:NSMakeRange(start, PositionBeforeSpaces([ realData length ], realData) - start) ];
			while ([ realData rangeOfString:@"\t\t" ].length != 0)
				realData = [ realData stringByReplacingOccurrencesOfString:@"\t\t" withString:@" "];
			realData = [ realData stringByReplacingOccurrencesOfString:@"\n" withString:@" " ];
			while ([ realData rangeOfString:@"  " ].length != 0)
				realData = [ realData stringByReplacingOccurrencesOfString:@"  " withString:@" "];
			realData = [ realData stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n" ];
			realData = [ realData stringByReplacingOccurrencesOfString:@"\\\\" withString:@"\\" ];
		}
		else
			realData = [ realData stringByReplacingOccurrencesOfString:@"\t" withString:@"    " ];
		[ dictionary addEntriesFromDictionary:@{name: realData} ];
	}
	else
	{
		[ dictionary addEntriesFromDictionary:@{name: [ NSMutableDictionary dictionary ]} ];
		unsigned long pos2 = 0;
		while (pos2 < [ data length ])
		{
			if (!InterpretTagData(data, &pos2, dictionary[name]))
				break;
		}
	}
	
	return TRUE;
}

const char* actypes[] = { "char", "short", "int", "long", "long long", "unsigned char", "unsigned short", "unsigned int", "unsigned long", "unsigned long long", "signed char", "signed short", "signed int", "signed long", "signed long long", "float", "double", "BOOL", "bool", "void", "wchar_t", "id", "SEL" };

void ApplyBolds(NSTextField* field, NSFont* font, BOOL sel)
{
	NSMutableAttributedString* str = [ [ NSMutableAttributedString alloc ] initWithAttributedString:[ field attributedStringValue ] ];
	[ str beginEditing ];
	
	NSRange range = NSMakeRange(0, 0);
	unsigned long totalPos = 0;
	NSMutableString* string = [ str mutableString ];
	do
	{
		range = [ [ string substringFromIndex:totalPos ] rangeOfString:@"<b>" ];
		if (range.length == 0)
			break;
		totalPos += range.location;
		
		unsigned long lookPos = totalPos + range.length;
		while (lookPos < [ string length ] - 3)
		{
			char cmd1 = [ string characterAtIndex:lookPos ];
			char cmd2 = [ string characterAtIndex:lookPos + 1 ];
			char cmd3 = [ string characterAtIndex:lookPos + 2 ];
			char cmd4 = [ string characterAtIndex:lookPos + 3 ];
			if (cmd1 == '<' && cmd2 == '/' && cmd3 == 'b' && cmd4 == '>')
			{
				lookPos += 3;
				break;
			}
			lookPos++;
		}
		
		// For now disable the bolds because when selection happens, they go away
		if (!sel)
			[ str addAttribute:NSFontAttributeName value:font range:NSMakeRange(totalPos + 3, lookPos - totalPos - 6) ];
		totalPos += range.length;
	}
	while (range.length != 0);
	
	range = NSMakeRange(0, 0);
	totalPos = 0;
	string = [ str mutableString ];
	do
	{
		range = [ [ string substringFromIndex:totalPos ] rangeOfString:@"<c>" ];
		if (range.length == 0)
			break;
		totalPos += range.location;
		
		unsigned long lookPos = totalPos + range.length;
		while (lookPos < [ string length ] - 3)
		{
			char cmd1 = [ string characterAtIndex:lookPos ];
			char cmd2 = [ string characterAtIndex:lookPos + 1 ];
			char cmd3 = [ string characterAtIndex:lookPos + 2 ];
			char cmd4 = [ string characterAtIndex:lookPos + 3 ];
			if (cmd1 == '<' && cmd2 == '/' && cmd3 == 'c' && cmd4 == '>')
			{
				lookPos += 3;
				break;
			}
			lookPos++;
		}
		
		// For now disable the bolds because when selection happens, they go away
		if (!sel)
		{
			NSColor* color = [ NSColor colorWithCalibratedRed:0.435294 green:0.254902 blue:0.654902 alpha:1 ];
			NSString* name = [ string substringWithRange:NSMakeRange(totalPos + 3, lookPos - totalPos - 6) ];
			for (unsigned long z = 0; z < sizeof(actypes) / sizeof(const char*); z++)
			{
				if ([ name isEqualToString:@(actypes[z]) ])
				{
					color = [ NSColor colorWithCalibratedRed:0.712569 green:0.2 blue:0.631373 alpha:1 ];
					break;
				}
			}
			if ([ name hasSuffix:@"*" ])
				lookPos--;
			[ str addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(totalPos + 3, lookPos - totalPos - 6) ];
		}
		totalPos += range.length;
	}
	while (range.length != 0);
	
	[ str endEditing ];
	[ string replaceOccurrencesOfString:@"<b>" withString:@"" options:0 range:NSMakeRange(0, [ string length ]) ];
	[ string replaceOccurrencesOfString:@"</b>" withString:@"" options:0 range:NSMakeRange(0, [ string length ]) ];
	[ string replaceOccurrencesOfString:@"<c>" withString:@"" options:0 range:NSMakeRange(0, [ string length ]) ];
	[ string replaceOccurrencesOfString:@"</c>" withString:@"" options:0 range:NSMakeRange(0, [ string length ]) ];
	[ field setAttributedStringValue:str ];
}

void SetLabel(NSTextField* field, BOOL sel, NSFont* font)
{
	[ field setDrawsBackground:NO ];
	[ field setSelectable:sel ];
	[ field setEditable:NO ];
	[ field setBezeled:NO ];
	ApplyBolds(field, font, sel);
}

@implementation CodeHelpView

- (void) linkFollowed:(id)sender
{
	if ([ [ (MDLink*) sender path ] hasSuffix:@".txt" ])
		[ self loadFile:[ NSString stringWithFormat:@"%@/Help/%@", [ [ NSBundle mainBundle ] resourcePath ], [ (MDLink*)sender path ] ] ];
	else
		[ self searchWord:[ NSString stringWithFormat:@"%@/", [ (MDLink*)sender path ] ] ];
}

- (void) setFiles:(NSArray*)array
{
	files = [ [ NSMutableArray alloc ] initWithArray:array ];
}

- (NSArray*) files
{
	return files;
}

- (void) loadFile:(NSString*)path
{
	NSFileHandle* handle = [ NSFileHandle fileHandleForReadingAtPath:path ];
	NSString* string = [ [ NSString alloc ] initWithData:[ handle readDataToEndOfFile ] encoding:NSASCIIStringEncoding ];
	[ handle closeFile ];
	
	NSMutableDictionary* dictionary = [ [ NSMutableDictionary alloc ] init ];
	
	unsigned long pos = 0;
	while (pos < [ string length ])
	{
		if (!InterpretTagData(string, &pos, dictionary))
			break;
	}
	
	[ self setSubviews:[ NSArray array ] ];
	
	NSSize size = [ self bounds ].size;
	
	NSTextField* title = [ [ NSTextField alloc ] initWithFrame:NSMakeRect(20, size.height - 60, size.width - 40, 40) ];
	[ title setStringValue:dictionary[@"name"] ];
	[ title setFont:[ NSFont systemFontOfSize:30 ] ];
	SetLabel(title, YES, [ NSFont boldSystemFontOfSize:30 ]);
	[ self addSubview:title ];
	
	NSFont* descFont = [ NSFont systemFontOfSize:[ NSFont systemFontSizeForControlSize:NSRegularControlSize ] ];
	NSString* trueDesc = [ NSString stringWithFormat:@"\t%@", dictionary[@"desc"] ];
	NSSize descSize = [ trueDesc boundingRectWithSize:NSMakeSize(size.width - 40, 0) options:NSLineBreakByWordWrapping | NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: descFont} ].size;
	NSTextField* desc = [ [ NSTextField alloc ] initWithFrame:NSMakeRect(20, size.height - 60 - descSize.height, size.width - 40, descSize.height) ];
	[ desc setStringValue:trueDesc ];
	[ desc setFont:descFont ];
	SetLabel(desc, YES, [ NSFont boldSystemFontOfSize:[ NSFont systemFontSizeForControlSize:NSRegularControlSize ] ]);
	[ self addSubview:desc ];
	
	float totalHeight = 70 + descSize.height;
	if (![ dictionary[@"type"] isKindOfClass:[ NSString class ] ])
	{
		totalHeight += 40;
		NSTextField* arguments = [ [ NSTextField alloc ] initWithFrame:NSMakeRect(20, size.height - totalHeight, size.width - 40, 40) ];
		[ arguments setStringValue:@"Arguments" ];
		[ arguments setFont:[ NSFont systemFontOfSize:20 ] ];
		SetLabel(arguments, YES, [ NSFont boldSystemFontOfSize:20 ]);
		[ self addSubview:arguments ];

		NSDictionary* typeDictionary = dictionary[@"type"];
		NSString* argumentKey = @"argument0";
		NSDictionary* argumentDict = nil;
		unsigned int argumentNum = 0;
		while ((argumentDict = typeDictionary[argumentKey]))
		{
			totalHeight += 10;
			NSTextField* aname = [ [ NSTextField alloc ] initWithFrame:NSMakeRect(40, size.height - totalHeight, size.width - 60, 20) ];
			[ aname setStringValue:[ NSString stringWithFormat:@"<b><c>%@</c></b> <b>%@</b>", argumentDict[@"type"], argumentDict[@"name"] ] ];
			[ aname setFont:descFont ];
			SetLabel(aname, NO, [ NSFont boldSystemFontOfSize:[ NSFont systemFontSizeForControlSize:NSRegularControlSize ] ]);
			[ self addSubview:aname ];
			
			NSSize adescSize = [ argumentDict[@"desc"] boundingRectWithSize:NSMakeSize(size.width - 90, 0) options:NSLineBreakByWordWrapping | NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: descFont} ].size;
			totalHeight += adescSize.height;
			NSTextField* adesc = [ [ NSTextField alloc ] initWithFrame:NSMakeRect(70, size.height - totalHeight, size.width - 90, adescSize.height) ];
			[ adesc setStringValue:argumentDict[@"desc"] ];
			[ adesc setFont:descFont ];
			SetLabel(adesc, YES, [ NSFont boldSystemFontOfSize:[ NSFont systemFontSizeForControlSize:NSRegularControlSize ] ]);
			[ self addSubview:adesc ];
			
			totalHeight += 20;
			
			argumentKey = [ NSString stringWithFormat:@"argument%i", ++argumentNum ];
		}
		
		totalHeight += 30;
		NSTextField* returns = [ [ NSTextField alloc ] initWithFrame:NSMakeRect(20, size.height - totalHeight, size.width - 40, 40) ];
		[ returns setStringValue:@"Return" ];
		[ returns setFont:[ NSFont systemFontOfSize:20 ] ];
		SetLabel(returns, YES, [ NSFont boldSystemFontOfSize:20 ]);
		[ self addSubview:returns ];
		
		NSDictionary* returnDict = typeDictionary[@"return"];
		totalHeight += 10;
		NSTextField* aname = [ [ NSTextField alloc ] initWithFrame:NSMakeRect(40, size.height - totalHeight, size.width - 60, 20) ];
		[ aname setStringValue:[ NSString stringWithFormat:@"<b><c>%@</c></b>", returnDict[@"type"] ] ];
		[ aname setFont:descFont ];
		SetLabel(aname, NO, [ NSFont boldSystemFontOfSize:[ NSFont systemFontSizeForControlSize:NSRegularControlSize ] ]);
		[ self addSubview:aname ];
		
		NSSize adescSize = [ returnDict[@"desc"] boundingRectWithSize:NSMakeSize(size.width - 90, 0) options:NSLineBreakByWordWrapping | NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: descFont} ].size;
		totalHeight += adescSize.height;
		NSTextField* adesc = [ [ NSTextField alloc ] initWithFrame:NSMakeRect(70, size.height - totalHeight, size.width - 90, adescSize.height) ];
		[ adesc setStringValue:returnDict[@"desc"] ];
		[ adesc setFont:descFont ];
		SetLabel(adesc, YES, [ NSFont boldSystemFontOfSize:[ NSFont systemFontSizeForControlSize:NSRegularControlSize ] ]);
		[ self addSubview:adesc ];
	}
	else if ([ dictionary[@"type"] hasPrefix:@"property" ])
	{
		NSString* realType = [ dictionary[@"type"] substringFromIndex:9 ];
		totalHeight += 40;
		NSTextField* properties = [ [ NSTextField alloc ] initWithFrame:NSMakeRect(20, size.height - totalHeight, size.width - 40, 40) ];
		[ properties setStringValue:@"Property" ];
		[ properties setFont:[ NSFont systemFontOfSize:20 ] ];
		SetLabel(properties, YES, [ NSFont boldSystemFontOfSize:20 ]);
		[ self addSubview:properties ];
		
		totalHeight += 10;
		NSTextField* aname = [ [ NSTextField alloc ] initWithFrame:NSMakeRect(40, size.height - totalHeight, size.width - 60, 20) ];
		[ aname setStringValue:[ NSString stringWithFormat:@"<b><c>%@</c></b>", realType ] ];
		[ aname setFont:descFont ];
		SetLabel(aname, NO, [ NSFont boldSystemFontOfSize:[ NSFont systemFontSizeForControlSize:NSRegularControlSize ] ]);
		[ self addSubview:aname ];
	}
	
	if (dictionary[@"example"])
	{
		totalHeight += 50;
		NSTextField* example = [ [ NSTextField alloc ] initWithFrame:NSMakeRect(20, size.height - totalHeight, size.width - 40, 40) ];
		[ example setStringValue:@"Example" ];
		[ example setFont:[ NSFont systemFontOfSize:20 ] ];
		SetLabel(example, YES, [ NSFont boldSystemFontOfSize:20 ]);
		[ self addSubview:example ];
		
		NSFont* textFont = [ NSFont fontWithName:@"Menlo" size:11 ];
		NSString* exampleString = [ NSString stringWithFormat:@"\n//...\n%@\n//...\n", dictionary[@"example"] ];
		NSSize exampleSize = [ exampleString boundingRectWithSize:NSMakeSize(FLT_MAX, 0) options:NSLineBreakByClipping | NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: textFont} ].size;
		float realHeight = [ [ NSMutableAttributedString alloc ] initWithString:@"a" attributes:@{NSFontAttributeName: [ NSFont fontWithName:@"Helvetica" size:10 ], NSForegroundColorAttributeName: [ NSColor blackColor ]} ].size.height * [ [ exampleString componentsSeparatedByString:@"\n" ] count ];
		totalHeight += realHeight;
		
		NSScrollView* scrollView = [ [ NSScrollView alloc ] initWithFrame:NSMakeRect(20, size.height - totalHeight, size.width - 40, realHeight + 3) ];
		[ scrollView setBorderType:NSBezelBorder ];
		[ scrollView setHasVerticalScroller:YES ];
		[ scrollView setHasHorizontalScroller:YES ];
		
		MDExample* textView = [ [ MDExample alloc ] initWithFrame:NSMakeRect(20, size.height - totalHeight, exampleSize.width + 35, realHeight) ];
		[ [ textView textContainer ] setLineFragmentPadding:35 ];
		[ textView setVerticallyResizable:YES ];
		[ textView setHorizontallyResizable:YES ];
		[ textView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable ];
		[ [ textView textContainer ] setContainerSize:NSMakeSize(FLT_MAX, FLT_MAX)];
		[ [ textView textContainer ] setWidthTracksTextView:NO ];
		
		[ textView setSetName:([ dictionary[@"type"] isKindOfClass:[ NSString class ] ] && [ dictionary[@"type"] hasPrefix:@"property" ]) ];
		[ textView setName:dictionary[@"name"] ];
		[ textView setString:exampleString ];
		[ textView setBackgroundColor:[ NSColor colorWithCalibratedRed:1 green:1 blue:1 alpha:1.0 ] ];
		[ textView setFont:textFont ];
		[ textView setEditable:NO ];
		[ scrollView setDocumentView:textView ];
		[ self addSubview:scrollView ];
		
		totalHeight += 20;
	}
	
	if (dictionary[@"see"])
	{
		totalHeight += 40;
		NSTextField* see = [ [ NSTextField alloc ] initWithFrame:NSMakeRect(20, size.height - totalHeight + 10, size.width - 40, 30) ];
		[ see setStringValue:@"See Also" ];
		[ see setFont:[ NSFont systemFontOfSize:20 ] ];
		SetLabel(see, YES, [ NSFont boldSystemFontOfSize:20 ]);
		[ self addSubview:see ];
		
		NSDictionary* seeDictionary = dictionary[@"see"];
		NSString* entryKey = @"entry0";
		NSDictionary* entryDict = nil;
		unsigned int entryNum = 0;
		while ((entryDict = seeDictionary[entryKey]))
		{
			totalHeight += 10;
			MDLink* aname = [ [ MDLink alloc ] initWithFrame:NSMakeRect(40, size.height - totalHeight, size.width - 40, 20) ];
			[ aname setStringValue:entryDict[@"name"] ];
			[ aname setTextColor:[ NSColor blueColor ] ];
			[ aname setFont:descFont ];
			[ aname setLinkTarget:self ];
			[ aname setLinkAction:@selector(linkFollowed:) ];
			[ aname setPath:entryDict[@"path"] ];
			SetLabel(aname, NO, [ NSFont boldSystemFontOfSize:[ NSFont systemFontSizeForControlSize:NSRegularControlSize ] ]);
			[ self addSubview:aname ];
			
			totalHeight += 10;
			entryKey = [ NSString stringWithFormat:@"entry%i", ++entryNum ];
		}
	}
	
	NSRect frame = [ self frame ];
	float diffHeight = (totalHeight + 20) - frame.size.height;
	if ([ [ [ self window ] contentView ] bounds ].size.height < totalHeight + 20)
	{
		frame.size.height = totalHeight + 20;
		[ self setFrame:frame ];
	}
	else
	{
		diffHeight = [ [ self superview ] frame ].size.height - frame.size.height;
		frame.size.height = [ [ self superview ] frame ].size.height;
		[ self setFrame:frame ];
	}
	
	NSArray* subviews = [ self subviews ];
	for (unsigned long z = 0; z < [ subviews count ]; z++)
	{
		NSView* subview = subviews[z];
		NSRect frame = [ subview frame ];
		frame.origin.y += diffHeight;
		[ subview setFrame:frame ];
	}
	
	[ self scrollPoint:NSMakePoint(0, [ self frame ].size.height) ];
}

- (void) searchWord:(NSString*)string
{
	float totalHeight = 75;
	
	[ self setSubviews:[ NSArray array ] ];
	
	NSSize size = [ self bounds ].size;
	
	NSTextField* title = [ [ NSTextField alloc ] initWithFrame:NSMakeRect(20, size.height - 60, size.width - 40, 40) ];
	[ title setStringValue:@"Search" ];
	[ title setFont:[ NSFont systemFontOfSize:30 ] ];
	SetLabel(title, YES, [ NSFont boldSystemFontOfSize:30 ]);
	[ self addSubview:title ];
	
	NSFont* descFont = [ NSFont systemFontOfSize:[ NSFont systemFontSizeForControlSize:NSRegularControlSize ] ];
	BOOL foundOne = FALSE;
	if ([ string length ] == 0)
	{
		for (unsigned long z = 0; z < [ files count ]; z++)
		{
			NSString* path = files[z];
			totalHeight += 10;
			MDLink* aname = [ [ MDLink alloc ] initWithFrame:NSMakeRect(40, size.height - totalHeight, size.width - 40, 20) ];
			[ aname setStringValue:[ path stringByDeletingPathExtension ] ];
			[ aname setTextColor:[ NSColor blueColor ] ];
			[ aname setFont:descFont ];
			[ aname setLinkTarget:self ];
			[ aname setLinkAction:@selector(linkFollowed:) ];
			[ aname setPath:path ];
			SetLabel(aname, NO, [ NSFont boldSystemFontOfSize:[ NSFont systemFontSizeForControlSize:NSRegularControlSize ] ]);
			[ self addSubview:aname ];
			
			totalHeight += 10;
			foundOne = TRUE;
		}
	}
	else
	{
		for (unsigned long z = 0; z < [ files count ]; z++)
		{
			NSString* path = files[z];
			if ([ [ path stringByDeletingPathExtension ] rangeOfString:string options:NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch | NSWidthInsensitiveSearch ].location != NSNotFound)
			{
				totalHeight += 10;
				MDLink* aname = [ [ MDLink alloc ] initWithFrame:NSMakeRect(40, size.height - totalHeight, size.width - 40, 20) ];
				[ aname setStringValue:[ path stringByDeletingPathExtension ] ];
				[ aname setTextColor:[ NSColor blueColor ] ];
				[ aname setFont:descFont ];
				[ aname setLinkTarget:self ];
				[ aname setLinkAction:@selector(linkFollowed:) ];
				[ aname setPath:path ];
				SetLabel(aname, NO, [ NSFont boldSystemFontOfSize:[ NSFont systemFontSizeForControlSize:NSRegularControlSize ] ]);
				[ self addSubview:aname ];
				
				totalHeight += 10;
				foundOne = TRUE;
			}
		}
	}
	
	if (!foundOne)
	{
		totalHeight += 10;
		NSTextField* desc = [ [ NSTextField alloc ] initWithFrame:NSMakeRect(20, size.height - totalHeight, size.width - 40, 20) ];
		[ desc setStringValue:@"There are no search results." ];
		[ desc setFont:descFont ];
		SetLabel(desc, YES, [ NSFont boldSystemFontOfSize:[ NSFont systemFontSizeForControlSize:NSRegularControlSize ] ]);
		[ self addSubview:desc ];
		totalHeight += 10;
	}
	
	NSRect frame = [ self frame ];
	float diffHeight = (totalHeight + 20) - frame.size.height;
	if ([ [ [ self window ] contentView ] bounds ].size.height < totalHeight + 20)
	{
		frame.size.height = totalHeight + 20;
		[ self setFrame:frame ];
	}
	else
	{
		diffHeight = [ [ self superview ] frame ].size.height - frame.size.height;
		frame.size.height = [ [ self superview ] frame ].size.height;
		[ self setFrame:frame ];
	}
	
	NSArray* subviews = [ self subviews ];
	for (unsigned long z = 0; z < [ subviews count ]; z++)
	{
		NSView* subview = subviews[z];
		NSRect frame = [ subview frame ];
		frame.origin.y += diffHeight;
		[ subview setFrame:frame ];
	}
	
	[ self scrollPoint:NSMakePoint(0, [ self frame ].size.height) ];
}

@end
