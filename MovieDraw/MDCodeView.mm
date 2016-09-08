//
//  MDCodeView.mm
//  MovieDraw
//
//  Created by Neil Singh on 10/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MDCodeView.h"
#import <objc/message.h>

/* TODO:
 * Support for Functions - done?
 * Update autocomplete to give xcode like bubbles for arguements
 * Fix - only loads stuff from new documents on load
 * After first loading a screen that has enters at the end that cause it to scroll, you must type something to move the cursor
 * Cannot delete multiple lines when its the last line
 */

// C types
const char* ctypes[] = { "unsigned", "signed", "char", "short", "int", "long", "const", "void", "float", "double", "BOOL", "bool", "if", "for", "while", "do", "self", "id", "SEL", "IMP", "@implementation", "@end", "@interface", "return", "@synthesize", "@property", "@protocol", "@selector", "@encode", "@try", "@catch", "@finally", "@throw", "@dynamic", "YES", "NO", "TRUE", "true", "FALSE", "false", "NULL", "nil", "Nil", "break", "switch", "case", "try", "catch", "throw", "and", "and_eq", "asm", "auto", "bitand", "bitor", "class", "compl", "const_cast", "continue", "default", "delete", "dynamic_cast", "else", "enum", "explicit", "extern", "friend", "goto", "inline", "mutable", "namespace", "new", "not", "not_eq", "operator", "or", "or_eq", "private", "protected", "public", "register", "reinterpret_cast", "sizeof", "static", "static_cast", "struct", "template", "this", "typedef", "typeid", "typename",  "union", "using", "virtual", "volatile", "wchar_t", "xor", "xor_eq", "@class" "@private", "@protected", "@public", "@synchronized", "byref", "oneway", "super", "in", "out", };
// Javascript types
const char* jtypes[] = { "break", "case", "catch", "continue", "debugger", "default", "delete", "do", "else", "finally", "for", "function", "if", "in", "instanceof", "new", "return", "switch", "this", "throw", "try", "typeof", "var", "void", "while", "with", };
char posschar[] = { ' ', '\n', '\t', '`', '!', '#', '$', '%', '^', '&', '*', '(', ')', '-', '+', '=', '[', '{', '}', ']', '\\', '|', ',', '<', '>', '.', '?', '/', ';', ':', };
BOOL loadingClass = FALSE;
NSRange editRange = NSMakeRange(-1, 0);
NSRange oldEditRange = NSMakeRange(-1, 0);
NSString* oldEditString = nil;
BOOL normalEdit = FALSE;
NSString* previousString = nil;
long long editedLength = 0;
unsigned long long editPosition = 0;
BOOL shouldDeleteBlocks = TRUE;

BOOL exitSearch = FALSE;
BOOL isSearching = FALSE;
BOOL isMatching = FALSE;

const char* preprocessorWords[] = { "#import", "#include", "#pragma", };

NSString* WordFromIndex(unsigned long long index, NSString* str)
{
	NSMutableString* string = [ NSMutableString string ];
	for (unsigned long long z = index; z < [ str length ]; z++)
	{
		BOOL isFound = FALSE;
		for (int y = 0; y < sizeof(posschar); y++)
		{
			if ([ str characterAtIndex:z ] == posschar[y])
			{
				isFound = TRUE;
				break;
			}
		}
		if (isFound)
			break;
		[ string appendFormat:@"%c", [ str characterAtIndex:z ] ];
	}
	return string;
}

NSString* ValueFromIndex(unsigned long long index, NSString* str)
{
	NSMutableString* string = [ NSMutableString string ];
	for (unsigned long long z = index; z < [ str length ]; z++)
	{
		char cmd = [ str characterAtIndex:z ];
		if (cmd == ' ' || cmd == '\n' || cmd == '\t')
			break;
		[ string appendFormat:@"%c", [ str characterAtIndex:z ] ];
	}
	return string;
}

unsigned long long CheckType(NSString* line, unsigned long long pos, NSMutableString* type, NSArray* vars, MDLanguage language);
unsigned long long CheckType(NSString* line, unsigned long long pos, NSMutableString* type, NSArray* vars, MDLanguage language)
{
	unsigned long long startPos = pos;
	NSString* first = WordFromIndex(pos, line);
	[ type setString:@"" ];
	if (language == MD_OBJ_C)
	{
		BOOL constFirst = FALSE;
		BOOL otherFirst = FALSE;
		BOOL hadFirstVar = FALSE;
		BOOL allowInts = FALSE;
		BOOL allowsIntLong = FALSE;
		BOOL allowsTrueInt = FALSE;
		while (([ first isEqualToString:@"const" ] && !constFirst) || [ first isEqualToString:@"id" ] || [ first isEqualToString:@"char" ] || [ first isEqualToString:@"short" ] || [ first isEqualToString:@"int" ] || [ first isEqualToString:@"long" ] || [ first isEqualToString:@"float" ] || [ first isEqualToString:@"double" ] || [ first isEqualToString:@"wchar_t" ] || [ first isEqualToString:@"void" ] || [ first isEqualToString:@"bool" ] || ([ first isEqualToString:@"unsigned" ] && !otherFirst) || ([ first isEqualToString:@"signed" ] && !otherFirst) || ([ vars containsObject:first ] && !hadFirstVar))
		{
			BOOL done = FALSE;
			if (otherFirst && (!(allowInts && ([ first isEqualToString:@"char" ] || [ first isEqualToString:@"short" ] || [ first isEqualToString:@"int" ] || [ first isEqualToString:@"long" ])) && !(allowsIntLong && ([ first isEqualToString:@"int" ] || [ first isEqualToString:@"long" ])) && !(allowsTrueInt && [ first isEqualToString:@"int" ])))
				done = TRUE;
			else if ((allowInts && ([ first isEqualToString:@"char" ] ||[ first isEqualToString:@"short" ] || [ first isEqualToString:@"int" ] || [ first isEqualToString:@"long" ])))
			{
				allowInts = FALSE;
				if ([ first isEqualToString:@"long" ])
					allowsIntLong = TRUE;
				else if (![ first isEqualToString:@"int" ])
					allowsTrueInt = TRUE;
			}
			else if (allowsIntLong && ([ first isEqualToString:@"int" ] || [ first isEqualToString:@"long" ]))
			{
				allowsIntLong = FALSE;
				if ([ first isEqualToString:@"long" ])
					allowsTrueInt = TRUE;
			}
			else if (allowsTrueInt && [ first isEqualToString:@"int" ])
			{
				allowsTrueInt = FALSE;
				done = TRUE;
			}
			
			if ([ first isEqualToString:@"const" ])
				constFirst = TRUE;
			else
			{
				constFirst = TRUE;
				otherFirst = TRUE;
			}
			if ([ first isEqualToString:@"unsigned" ] || [ first isEqualToString:@"signed" ])
				allowInts = TRUE;
			else if ([ first isEqualToString:@"long" ])
				allowsIntLong = TRUE;
			else if ([ first isEqualToString:@"short" ] || [ first isEqualToString:@"char" ])
				allowsTrueInt = TRUE;
				
			if ([ vars containsObject:first ])
			{
				hadFirstVar = TRUE;
				done = TRUE;
			}
			startPos += [ first length ];
			if ([ type length ] != 0)
				[ type appendFormat:@" %@", first ];
			else
				[ type appendString:first ];
			first = WordFromIndex(PositionAfterSpaces(startPos, line, YES), line);
			startPos = PositionAfterSpaces(startPos, line, YES);
			
			if (done)
				break;
		}
	}
	else
	{
		if ([ first isEqualToString:@"var" ])
		{
			startPos += [ first length ];
			[ type setString:@"var" ];
			first = WordFromIndex(PositionAfterSpaces(startPos, line, YES), line);
			startPos = PositionAfterSpaces(startPos, line, YES);
		}
	}
	return startPos - pos;
}

@implementation MDAutoComplete

- (NSString*) wordFromIndex: (unsigned long long) index fromString:(NSString*)str
{
	NSMutableString* string = [ NSMutableString string ];
	for (unsigned long long z = index; z < [ str length ]; z++)
	{
		BOOL isFound = FALSE;
		for (int y = 0; y < sizeof(posschar); y++)
		{
			if ([ str characterAtIndex:z ] == posschar[y])
			{
				isFound = TRUE;
				break;
			}
		}
		if (isFound)
			break;
		[ string appendFormat:@"%c", [ str characterAtIndex:z ] ];
	}
	return string;
}

- (instancetype) initWithFrame:(NSRect)frameRect
{
	if (self = [ super initWithFrame:frameRect ])
	{
		variables = [ [ NSMutableArray alloc ] init ];
		keyword = [ [ NSString alloc ] init ];
		visible = FALSE;
	}
	return self;
}

- (void) addVariable:(NSString*)var
{
	// Check all others for same prefix but shorter length
	for (unsigned long z = 0; z < [ variables count ]; z++)
	{
		if ([ variables[z] hasPrefix:var ] && [ var length ] < [ variables[z] length ])
		{
			[ variables insertObject:var atIndex:z ];
			return;
		}
	}
	[ variables insertObject:var atIndex:0 ];
}

- (void) removeVaraible:(NSString*)var
{
	for (unsigned long long z = 0; z < [ variables count ]; z++)
	{
		if ([ variables[z] isEqualToString:var ])
		{
			[ variables removeObjectAtIndex:z ];
			break;
		}
	}
}

- (NSMutableArray*) variables
{
	return variables;
}

- (void) setKeyword:(NSString*)word
{
	if ([ codeView loading ])
		return;
	
	NSString* sel = [ self selectedItem ];
	
	keyword = [ [ NSString alloc ] initWithString:word ];
	maxScroll = 0;
	scroll = 0;
	
	selected = 0;
	NSArray* array = [ self matches ];
	if (!sel)
		return;
	for (unsigned long long z = 0; z < [ array count ]; z++)
	{
		if ([ array[z] isEqualToString:sel ])
		{
			selected = z;
			break;
		}
	}
	/*matchesWithoutFunction = array;
	NSMutableArray* mutArray = [ NSMutableArray arrayWithArray:array ];
	for (unsigned long long z = 0; z < [ mutArray count ]; z++)
	{
		for (unsigned long long q = 0; q < [ mutArray count ]; q++)
		{
			if ([ [ mutArray objectAtIndex:q ] isEqualToString:[ [ mutArray objectAtIndex:z ] objectForKey:@"Name" ] ])
				[ mutArray replaceObjectAtIndex:q withObject:[ [ functionMatches objectAtIndex:z ] objectForKey:@"Function" ] ];
		}
	}
	matchesWithFunction = array;*/
}
- (void) setClassType: (NSString*)word withData:(NSArray*)data andNames:(NSArray*)names hasDot:(BOOL)dot
{
	loadingClass = TRUE;
	maxScroll = 0;
	keyword = nil;
	classType = [ [ NSString alloc ] initWithString:word ];
	method = TRUE;
	
	methods = [ [ NSMutableArray alloc ] init ];
	
	unsigned long long classIndex = [ names indexOfObject:word ];
	if (classIndex == NSNotFound)
		return;
	NSArray* documents = data[classIndex][@"Documents"];
	for (unsigned long long z = 0; z < [ documents count ]; z++)
	{
		NSMutableString* string = nil;
		if ([ documents[z] isEqualToString:@"" ])
			string = [ [ NSMutableString alloc ] initWithString:[ [ self codeView ] string ] ];
		else
		{
			NSFileHandle* handle = [ NSFileHandle fileHandleForReadingAtPath:documents[z] ];
			string = [ [ NSMutableString alloc ] initWithData:[ handle readDataToEndOfFile ] encoding:NSASCIIStringEncoding ];
			[ handle closeFile ];
		}
		
		// Remove all comments
		NSRange commentRange = NSMakeRange(0, 0);
		do
		{
			commentRange = [ string rangeOfString:@"/*" options:0 range:NSMakeRange(NSMaxRange(commentRange), [ string length ] - NSMaxRange(commentRange)) ];
			if (commentRange.length == 0)
				break;
			// Find */
			NSRange prevRange = commentRange;
			commentRange = [ string rangeOfString:@"*/" options:0 range:NSMakeRange(NSMaxRange(commentRange), [ string length ] - NSMaxRange(commentRange)) ];
			[ string deleteCharactersInRange:NSMakeRange(prevRange.location, NSMaxRange(commentRange) - prevRange.location) ];
			commentRange.location = prevRange.location;
			commentRange.length = 0;
		}
		while (commentRange.location != NSNotFound);
		commentRange = NSMakeRange(0, 0);
		do
		{
			commentRange = [ string rangeOfString:@"//" options:0 range:NSMakeRange(NSMaxRange(commentRange), [ string length ] - NSMaxRange(commentRange)) ];
			if (commentRange.length == 0)
				break;
			// Find */
			NSRange prevRange = commentRange;
			commentRange = [ string rangeOfString:@"\n" options:0 range:NSMakeRange(NSMaxRange(commentRange), [ string length ] - NSMaxRange(commentRange)) ];
			[ string deleteCharactersInRange:NSMakeRange(prevRange.location, NSMaxRange(commentRange) - prevRange.location) ];
			commentRange.location = prevRange.location;
			commentRange.length = 0;
		}
		while (commentRange.location != NSNotFound);
		
		if ([ data[classIndex][@"Type"] isEqualToString:@"Struct" ] && dot)
		{
			NSString* fileString = string;
			if ([ data[classIndex][@"Documents"] count ] != 0)
			{
				NSFileHandle* fileHandle = [ NSFileHandle fileHandleForReadingAtPath:data[classIndex][@"Documents"][0] ];
				if (fileHandle)
				{
					fileString = [ [ NSString alloc ] initWithData:[ fileHandle readDataToEndOfFile ] encoding:NSASCIIStringEncoding ];
					[ fileHandle closeFile ];
				}
			}
			NSRange structRange = NSMakeRange(0, 0);
			do
			{
				structRange = [ fileString rangeOfString:@"struct" options:0 range:NSMakeRange(NSMaxRange(structRange), [ fileString length ] - NSMaxRange(structRange)) ];
				if (structRange.length == 0)
					break;
				
				// Check to see if its for this class
				unsigned long long nameIndex = PositionAfterSpaces(NSMaxRange(structRange), fileString, NO);
				if ([ fileString characterAtIndex:nameIndex ] == '{')
				{
					unsigned int quantity = 0;
					while (nameIndex < [ fileString length ])
					{
						char cmd = [ fileString characterAtIndex:nameIndex++ ];
						if (cmd == '{')
							quantity++;
						else if (cmd == '}')
						{
							quantity--;
							if (quantity == 0)
								break;
						}
					}
					nameIndex = PositionAfterSpaces(nameIndex, fileString, YES);
				}
				NSMutableString* testName = [ [ NSMutableString alloc ] init ];
				while (nameIndex < [ fileString length ])
				{
					BOOL does = FALSE;
					for (int z = 0; z < sizeof(posschar); z++)
					{
						if ([ fileString characterAtIndex:nameIndex ] == posschar[z])
						{
							does = TRUE;
							break;
						}
					}
					if (does)
						break;
					
					[ testName appendFormat:@"%c", [ fileString characterAtIndex:nameIndex ] ];
					nameIndex++;
				}
				if (![ testName isEqualToString:word ])
					continue;
				
				NSRange bracket = [ fileString rangeOfString:@"{" options:0 range:NSMakeRange(NSMaxRange(structRange), [ fileString length ] - NSMaxRange(structRange)) ];
				unsigned long quantity = 1;
				unsigned long long pos = PositionAfterSpaces(NSMaxRange(bracket), fileString, NO);
				while (pos < [ string length ])
				{
					if ([ fileString characterAtIndex:pos ] == '{')
						quantity++;
					else if ([ fileString characterAtIndex:pos] == '}')
						quantity--;
					if (quantity == 0)
						break;
					pos++;
				}
				
				NSString* varString = [ [ NSString alloc ] initWithString:[ fileString substringWithRange:NSMakeRange(NSMaxRange(bracket), pos - 1 - NSMaxRange(bracket)) ] ];
				
				NSArray* lines = [ varString componentsSeparatedByString:@";" ];
				for (unsigned long z = 0; z < [ lines count ]; z++)
				{
					NSString* line = lines[z];
					if ([ line length ] == 0)
						continue;
					
					unsigned long pos = PositionAfterSpaces(0, line, NO);
					NSMutableString* type = [ [ NSMutableString alloc ] init ];
					pos = PositionAfterSpaces(pos + CheckType(line, pos, type, names, [ codeView language ]), line, NO);
					
					if (pos == PositionAfterSpaces(0, line, NO))
						continue;
					
					NSString* name = [ self wordFromIndex:pos fromString:line ];
					[ methods addObject:@{@"Name": name, @"Function": name} ];
				}
			}
			while (structRange.length != 0);
		}
		else if ([ data[classIndex][@"Type"] isEqualToString:@"ObjC-Class" ])
		{
			NSRange classRange = NSMakeRange(0, 0);
			do
			{
				classRange = [ string rangeOfString:@"@interface" options:0 range:NSMakeRange(NSMaxRange(classRange), [ string length ] - NSMaxRange(classRange)) ];
				if (classRange.length == 0)
					break;
				
				// Check to see if its for this class
				unsigned long long nameIndex = PositionAfterSpaces(NSMaxRange(classRange), string, YES);
				NSMutableString* testName = [ [ NSMutableString alloc ] init ];
				while (nameIndex < [ string length ])
				{
					BOOL does = FALSE;
					for (int z = 0; z < sizeof(posschar); z++)
					{
						if ([ string characterAtIndex:nameIndex ] == posschar[z])
						{
							does = TRUE;
							break;
						}
					}
					if (does)
						break;
					
					[ testName appendFormat:@"%c", [ string characterAtIndex:nameIndex ] ];
					nameIndex++;
				}
				if (![ testName isEqualToString:word ])
					continue;
				
				// Find corresponding @end
				NSRange prevRange = classRange;
				classRange = [ string rangeOfString:@"@end" options:0 range:NSMakeRange(NSMaxRange(classRange), [ string length ] - NSMaxRange(classRange)) ];
				if (classRange.length == 0)
					break;
				
				NSMutableString* classImp = [ NSMutableString stringWithString:[ string substringWithRange:NSMakeRange(NSMaxRange(prevRange), classRange.location - NSMaxRange(prevRange)) ] ];
				
				// Find first "+" or "-"
				NSRange methodRange = [ classImp rangeOfString:@"+" ];
				NSRange prevMethod = methodRange;
				methodRange = [ classImp rangeOfString:@"-" ];
				if (prevMethod.location < methodRange.location)
					methodRange.location = prevMethod.location;
				if (methodRange.location == NSNotFound)
					continue;
				
				NSArray* methodLines = [ [ classImp substringWithRange:NSMakeRange(methodRange.location, [ classImp length ] - methodRange.location) ] componentsSeparatedByString:@";" ];
				
				for (unsigned long long z = 0; z < [ methodLines count ]; z++)
				{
					NSString* line = methodLines[z];
					
					if (dot && [ line rangeOfString:@":" ].length != 0)
						continue;
					
					NSMutableString* met = [ [ NSMutableString alloc ] init ];
					
					//BOOL isStatic = FALSE;
					NSMutableString* retType = [ [ NSMutableString alloc ] init ];
					//NSMutableArray* paramTypes = [ [ NSMutableArray alloc ] init ];
					//NSMutableArray* paramNames = [ [ NSMutableArray alloc ] init ];
					
					unsigned long long pos = PositionAfterSpaces(0, line, NO);
					if (pos >= [ line length ])
					continue;
					
					NSMutableString* function = [ NSMutableString string ];
					
					//isStatic = ([ line characterAtIndex:pos ] == '+');
					[ function appendFormat:@"%c (", [ line characterAtIndex:pos ] ];
					if ([ line characterAtIndex:pos ] != '+' && [ line characterAtIndex:pos ] != '-')
						continue;
					pos = PositionAfterSpaces(pos + 1, line, NO) + 1;
					unsigned int quantity = 1;
					while (pos < [ line length ])
					{
						if ([ line characterAtIndex:pos ] == '(')
							quantity++;
						else if ([ line characterAtIndex:pos ] == ')')
						{
							quantity--;
							if (quantity == 0)
								break;
						}
						else
							[ retType appendFormat:@"%c", [ line characterAtIndex:pos ] ];
						pos++;
					}
					[ function appendFormat:@"%@) ", retType ];
					
					NSMutableString* piece = [ [ NSMutableString alloc ] init ];
					NSRange cRange = NSMakeRange(pos + 1, 0);
					if (cRange.location >= [ line length ])
						continue;

					do
					{
						cRange = [ line rangeOfString:@":" options:0 range:NSMakeRange(NSMaxRange(cRange), [ line length ] - NSMaxRange(cRange)) ];
						if (cRange.length == 0)
							break;
						NSRange prevCRange = cRange;
						while (cRange.location > pos)
						{
							[ piece insertString:[ NSString stringWithFormat:@"%c", [ line characterAtIndex:cRange.location ] ] atIndex:0 ];
							if (cRange.location == 0)
								break;
							cRange.location--;
							BOOL isDone = FALSE;
							for (int z = 0; z < sizeof(posschar); z++)
							{
								if (posschar[z] == [ line characterAtIndex:cRange.location ])
								{
									isDone = TRUE;
									break;
								}
							}
							if (isDone)
								break;
						}
						cRange = prevCRange;
						cRange.location++;
						NSMutableString* argType = [ NSMutableString string ];
						while (cRange.location < [ line length ])
						{
							if ([ line characterAtIndex:cRange.location ] == '(')
								quantity++;
							else if ([ line characterAtIndex:cRange.location ] == ')')
							{
								quantity--;
								if (quantity == 0)
									break;
							}
							else
								[ argType appendFormat:@"%c", [ line characterAtIndex:cRange.location ] ];
							cRange.location++;
						}
						cRange = prevCRange;
						
						[ function appendFormat:@"%@", piece ];
						if ([ argType length ] != 0)
							[ function appendFormat:@"(%@) ", argType ];
						else
							[ function appendFormat:@" " ];
						[ met appendFormat:@"%@ ", piece ];
						[ piece setString:@"" ];
					}
					while (cRange.length != 0);
					
					if ([ met length ] == 0)
					{
						pos = PositionAfterSpaces(pos + 1, line, NO);
						while (pos < [ line length ])
						{
							[ met appendFormat:@"%c", [ line characterAtIndex:pos ] ];
							pos++;
							if (pos == [ line length ])
								break;
							BOOL isDone = FALSE;
							for (int z = 0; z < sizeof(posschar); z++)
							{
								if (posschar[z] == [ line characterAtIndex:pos ])
								{
									isDone = TRUE;
									break;
								}
							}
							if (isDone)
								break;
						}
						[ function appendString:met ];
					}
					else
					{
						[ met deleteCharactersInRange:NSMakeRange([ met length ] - 1, 1) ];
						[ function deleteCharactersInRange:NSMakeRange([ function length ] - 1, 1) ];
					}
					
					//	NSLog(@"%@", met);
					
					NSDictionary* dict = @{@"Name": met, @"Function": function};
					BOOL inserted = FALSE;
					/*for (unsigned long z = 0; z < [ methods count ]; z++)
					 {
					 if ([ [ [ methods objectAtIndex:z ] objectForKey:@"Name" ] hasPrefix:met ])
					 {
					 [ methods insertObject:dict atIndex:z ];
					 inserted = TRUE;
					 break;
					 }
					 }*/
					if (!inserted)
						[ methods addObject:dict ];
				}
			}
			while (classRange.length != 0);
		}
		else if ([ data[classIndex][@"Type"] isEqualToString:@"Typedef" ])
		{
			NSString* realType = data[classIndex][@"Old Name"];
			[ self setClassType:realType withData:data andNames:names hasDot:dot ];
		}
	}
	
	loadingClass = FALSE;
}

- (NSString*) classType
{
	return classType;
}

- (NSString*) keyWord
{
	return keyword;
}

- (void) setVisible:(BOOL)vis
{
	visible = vis;
	[ self setNeedsDisplay:YES ];
}

- (BOOL) visible
{
	return visible;
}
- (void) setHasClassType: (BOOL)set
{
	method = set;
	if (!method && methods)
		methods = nil;
	if (!method && classType)
		classType = nil;
	maxScroll = 0;
}

- (BOOL) hasClassType
{
	return method;
}

- (void) setSelectedIndex: (unsigned long)sel
{
	selected = sel;
}

- (unsigned long) selectedIndex
{
	return selected;
}

- (void) setCodeView: (MDCodeView*)view
{
	codeView = view;
}

- (MDCodeView*) codeView
{
	return codeView;
}

- (void) setUseBoth: (BOOL)use keyWord:(NSString*)key;
{
	keyword2 = [ [ NSString alloc ] initWithString:key ];
	useBoth = use;
}

- (BOOL) useBoth
{
	return useBoth;
}

- (NSString*) trueKeyword
{
	if (!useBoth)
		return keyword;
	
	BOOL inVars = [ variables containsObject:[ self selectedItem ] ];
	if (inVars == method)
		return keyword2;
	else
		return keyword;
}

- (void) keyDown:(NSEvent *)theEvent
{
	unsigned short key = [ [ theEvent characters ] characterAtIndex:0 ];
	if (key == NSUpArrowFunctionKey)
	{
		if (selected != 0)
			selected--;
		else
			selected = lastDrawNumber - 1;
		if (rowHeight * selected < scroll * maxScroll)
			scroll = rowHeight * selected / maxScroll;
		else if (rowHeight * (selected + 1) > scroll * maxScroll + [ self frame ].size.height)
			scroll = (rowHeight * (selected + 1) - [ self frame ].size.height) / maxScroll;
		[ self setNeedsDisplay:YES ];
	}
	else if (key == NSDownArrowFunctionKey)
	{
		if (selected != lastDrawNumber - 1)
			selected++;
		else
			selected = 0;
		if (rowHeight * selected < scroll * maxScroll)
			scroll = rowHeight * selected / maxScroll;
		else if (rowHeight * (selected + 1) > scroll * maxScroll + [ self frame ].size.height)
			scroll = (rowHeight * (selected + 1) - [ self frame ].size.height) / maxScroll;
		[ self setNeedsDisplay:YES ];
	}
}

- (void) mouseDown:(NSEvent *)theEvent
{
	if (!visible)
	{
		[ super mouseDown:theEvent ];
		return;
	}
	
	NSRect rect = [ self frame ];
	NSPoint p = [ theEvent locationInWindow ];
	p.y = [ [ codeView enclosingScrollView ] documentVisibleRect ].size.height - p.y;
	if (p.x >= rect.origin.x && p.x <= rect.origin.x + rect.size.width && p.y >= rect.origin.y && p.y <= rect.origin.y + rect.size.height && visible)
	{
		unsigned long num = ((p.y - rect.origin.y + (scroll * maxScroll)) / rowHeight);
		[ self setSelectedIndex:num ];
		
		if ([ theEvent clickCount ] == 2)
			[ self fillMatch:[ codeView autoStart ] fullComplete:YES ];
		
		[ self setNeedsDisplay:YES ];
	}
}

- (void) mouseDragged:(NSEvent *)theEvent
{
	if (!visible)
	{
		[ super mouseDown:theEvent ];
		return;
	}
	
	NSRect rect = [ self frame ];
	NSPoint p = [ theEvent locationInWindow ];
	p.y = [ [ codeView enclosingScrollView ] documentVisibleRect ].size.height - p.y;
	if (p.x >= rect.origin.x && p.x <= rect.origin.x + rect.size.width && p.y >= rect.origin.y && p.y <= rect.origin.y + rect.size.height && visible)
	{
		unsigned long num = ((p.y - rect.origin.y + (scroll * maxScroll)) / rowHeight);
		[ self setSelectedIndex:num ];
		
		if ([ theEvent clickCount ] == 2)
			[ self fillMatch:[ codeView autoStart ] fullComplete:YES ];
		
		[ self setNeedsDisplay:YES ];
	}
}

- (NSString*) selectedItem
{
	if (!keyword)
		return nil;
	unsigned long index = 0;
	NSArray* vars = matchesWithoutFunction;
	for (unsigned long z = 0; z < [ vars count ]; z++)
	{
		if ([ [ vars[z] lowercaseString ] hasPrefix:[ keyword lowercaseString ] ])
		{
			if (selected == index)
				return [ NSString stringWithString:vars[z] ];
			index++;
		}
	}
	if (useBoth)
	{
		//vars = !method ? methods : variables;
		for (unsigned long z = 0; z < [ vars count ]; z++)
		{
			if ([ [ vars[z] lowercaseString ] hasPrefix:[ keyword2 lowercaseString ] ])
			{
				if (selected == index)
					return [ NSString stringWithString:vars[z] ];
				index++;
			}
		}
	}
	return nil;
}

- (unsigned long long) numberOfMatches
{
	return [ matchesWithoutFunction count ];
}

- (NSArray*) matches
{
	return [ self matches:NO ];
}

- (NSArray*) matches: (BOOL)withFunction
{
	if (!keyword)
		return nil;
	
	isMatching = TRUE;
	
	NSMutableArray* matches = [ NSMutableArray array ];
	NSMutableArray* vars = method ? methods : variables;
	NSMutableArray* functionMatches = [ NSMutableArray array ];
	for (unsigned long z = 0; z < [ vars count ]; z++)
	{
		if (method)
		{
			if ([ [ vars[z][@"Name"] lowercaseString ] hasPrefix:[ keyword lowercaseString ] ])
			{
				[ matches addObject:vars[z][@"Name"] ];
				//if (withFunction)
					[ functionMatches addObject:vars[z] ];
			}
		}
		else
		{
			if ([ [ vars[z] lowercaseString ] hasPrefix:[ keyword lowercaseString ] ])
				[ matches addObject:vars[z] ];
		}
		
		if (exitSearch)
		{
			exitSearch = FALSE;
			isMatching = FALSE;
			return matches;
		}
	}
	if (useBoth)
	{
		vars = !method ? methods : variables;
		for (unsigned long z = 0; z < [ vars count ]; z++)
		{
			if (!method)
			{
				if ([ [ vars[z][@"Name"] lowercaseString ] hasPrefix:[ keyword lowercaseString ] ])
				{
					[ matches addObject:vars[z][@"Name"] ];
					//if (withFunction)
						[ functionMatches addObject:vars[z] ];
				}
			}
			else
			{
				if ([ [ vars[z] lowercaseString ] hasPrefix:[ keyword lowercaseString ] ])
					[ matches addObject:vars[z] ];
			}
		}
		
		if (exitSearch)
		{
			exitSearch = FALSE;
			isMatching = FALSE;
			return matches;
		}
	}
	
	// Sort
	if ([ matches count ] != 0)
	{
		for (long long z = 0; z < [ matches count ] - 1; z++)
		{
			NSString* first = [ NSString stringWithString:matches[z] ];
			NSString* second = [ NSString stringWithString:matches[z + 1] ];
			while ([ second length ] < [ first length ])
			{
				matches[z] = second;
				matches[z + 1] = first;
				z--;
				if (z < 0)
					break;
				first = [ NSString stringWithString:matches[z] ];
				second = [ NSString stringWithString:matches[z + 1] ];
			}
			
			if (exitSearch)
			{
				exitSearch = FALSE;
				isMatching = FALSE;
				return matches;
			}
		}
	}
	
	matchesWithoutFunction = [ [ NSArray alloc ] initWithArray:matches ];
	
	// Change the "Names" to @"Functions"
	NSMutableArray* funcArray = [ NSMutableArray arrayWithArray:matches ];
	for (unsigned long long z = 0; z < [ functionMatches count ]; z++)
	{
		for (unsigned long long q = 0; q < [ funcArray count ]; q++)
		{
			if ([ funcArray[q] isEqualToString:functionMatches[z][@"Name"] ])
				funcArray[q] = functionMatches[z][@"Function"];
			
			if (exitSearch)
			{
				exitSearch = FALSE;
				return matches;
			}
		}
		
		if (exitSearch)
		{
			exitSearch = FALSE;
			return matches;
		}
	}
	if (withFunction)
		matches = funcArray;
	
	matchesWithFunction = [ [ NSArray alloc ] initWithArray:funcArray ];
	
	isMatching = FALSE;
	
	return matches;
}

- (void) scrollWheel:(NSEvent *)theEvent
{
	if (!visible)
	{
		[ super scrollWheel:theEvent ];
		return;
	}
	
	if (maxScroll == 0)
		return;
	scroll -= [ theEvent deltaY ] / maxScroll;
	if (scroll > 1)
		scroll = 1;
	else if (scroll < 0)
		scroll = 0;
	[ self setNeedsDisplay:YES ];
}

- (void) drawRect:(NSRect)dirtyRect
{
	if (!visible)
	{
		//[ self lockFocusIfCanDraw ];
		//[ self unlockFocus ];
		return;
	}
	
	NSRect rect = [ self frame ];
	
	/*if (dirtyRect.origin.y != 0)
	{
		rect.origin.y += (rect.size.height - dirtyRect.origin.y);
		[ self setFrame:rect ];
		//[ self setNeedsDisplay:YES ];
		//return;
	}*/

	//[ self lockFocusIfCanDraw ];
	[ [ NSColor whiteColor ] set ];
	[ [ NSBezierPath bezierPathWithRoundedRect:NSMakeRect(0, 0, rect.size.width, rect.size.height) xRadius:5 yRadius:5 ] fill ];
	[ [ NSColor colorWithCalibratedRed:0.729412 green:0.729412 blue:0.729412 alpha:1 ] set ];	
	[ [ NSBezierPath bezierPathWithRoundedRect:NSMakeRect(0, 0, rect.size.width, rect.size.height) xRadius:5 yRadius:5 ] stroke ];
	float yPos = rect.size.height;
	unsigned long index = 0;
	NSMutableArray* vars = [ NSMutableArray arrayWithArray:matchesWithFunction ];//[ NSMutableArray arrayWithArray:[ self matches:YES ] ];
	
	// Find out maxScroll
	NSAttributedString* test = [ [ NSAttributedString alloc ] initWithString:@"test" attributes:@{NSFontAttributeName: [ NSFont fontWithName:@"Helvetica" size:12 ], NSForegroundColorAttributeName: [ NSColor blackColor ]} ];
	float testHeight = [ test size ].height;
	maxScroll = (testHeight + 3) * [ vars count ] - rect.size.height;
	for (unsigned long z = 0; z < [ vars count ]; z++)
	{
		if (yPos + (scroll * maxScroll) - testHeight > rect.size.height)
		{
			yPos -= testHeight + 3;
			index++;
			continue;
		}
		//if ([ [ [ vars objectAtIndex:z ] lowercaseString ] hasPrefix:[ keyword lowercaseString ] ])
		{
			NSColor* color = [ NSColor blackColor ];
			if (index == selected)
				color = [ NSColor whiteColor ];
			// Add it
			NSAttributedString* string = [ [ NSAttributedString alloc ] initWithString:vars[z] attributes:@{NSFontAttributeName: [ NSFont fontWithName:@"Helvetica" size:12 ], NSForegroundColorAttributeName: color} ];
			if (index == selected)
			{
				[ [ NSColor colorWithCalibratedRed:0.431373 green:0.639216 blue:0.850980 alpha:1 ] set ];
				[ [ NSBezierPath bezierPathWithRect:NSMakeRect(0, yPos - [ string size ].height - 4 + (scroll * maxScroll), rect.size.width, [ string size ].height + 2) ] fill ];
			}
			yPos -= [ string size ].height + 3;
			rowHeight = [ string size ].height + 3;
			[ string drawAtPoint:NSMakePoint(3, yPos + (scroll * maxScroll)) ];
			index++;
		}
		if (yPos + (scroll * maxScroll) < 0)
			break;
	}
	lastDrawNumber = index;
	
	yPos = (rect.size.height - ((testHeight + 3) * [ vars count ]));
	if (yPos < 0)
	{
		maxScroll = -yPos;
		float height = rect.size.height * rect.size.height / (-yPos + rect.size.height);
		if (height < 15)
			height = 15;
		[ [ NSColor grayColor ] set ];
		[ [ NSBezierPath bezierPathWithRoundedRect:NSMakeRect(rect.size.width - 15, (rect.size.height / 2) - (((scroll * 2) - 1) * ((rect.size.height / 2) - 2 - (height / 2))) - (height / 2), 10, height) xRadius:5 yRadius:5 ] fill ];
	}
	
	//[ self unlockFocus ];
}

- (unsigned long long) checkForFunction:(NSMutableString*)selString cursorLeft:(unsigned long long)left
{
	unsigned long long cursor = [ codeView selectedRange ].location - 1;
	unsigned long long bkCursor = left;
	NSRange funcRange = [ selString rangeOfString:@":" ];
	if (funcRange.length != 0)
	{
		// Find last space
		while (cursor != -1)
		{
			char cmd = [ [ codeView string ] characterAtIndex:cursor ];
			if (cmd == ' ' || cmd == '\t' || cmd == '\n')
			{
				cursor++;
				break;
			}
			cursor--;
		}
		if (cursor == -1)
			cursor = 0;
		bkCursor = cursor + funcRange.location + 1;
		BOOL hasSelected = FALSE;
		// Its a function
		NSMutableString* newSel = [ NSMutableString stringWithString:selString ];
		unsigned long long selIndex = [ matchesWithoutFunction indexOfObject:selString ];
		if (selIndex != NSNotFound && selIndex < [ matchesWithFunction count ])
		{
			NSString* realString = matchesWithFunction[selIndex];
			funcRange = NSMakeRange(0, 0);
			NSRange funcRange2 = NSMakeRange(0, 0);
			unsigned long long totalAdd = 0;
			do
			{
				funcRange = [ realString rangeOfString:@":" options:0 range:NSMakeRange(NSMaxRange(funcRange), [ realString length ] - NSMaxRange(funcRange)) ];
				if (funcRange.length == 0)
					break;
				funcRange2 = [ selString rangeOfString:@":" options:0 range:NSMakeRange(NSMaxRange(funcRange2), [ selString length] - NSMaxRange(funcRange2)) ];
				if (funcRange2.length == 0)
					break;
				NSMutableString* word = [ NSMutableString string ];
				unsigned long long pos = funcRange.location + 1;
				unsigned long long quantity = 0;
				while (pos < [ realString length ])
				{
					char cmd = [ realString characterAtIndex:pos ];
					if (cmd == '(')
						quantity++;
					else if (cmd == ')')
						quantity--;
					[ word appendFormat:@"%c", cmd ];
					pos++;
					if (quantity == 0)
						break;
				}
				[ newSel insertString:word atIndex:funcRange2.location + 1 + totalAdd ];
				AutoCompleteBlock block;
				memset(&block, 0, sizeof(block));
				block.position = cursor + funcRange2.location + 1 + totalAdd;
				block.text = [ [ NSString alloc ] initWithString:word ];
				[ codeView addCompleteBlock:&block ];
				if (!hasSelected)
				{
					hasSelected = TRUE;
					[ codeView setSelectedBlock:[ codeView numberOfBlocks ] - 1 ];
				}
				totalAdd += [ word length ];
			}
			while (funcRange.length != 0);
			[ selString setString:newSel ];
		}
		return bkCursor;
	}
	
	funcRange = [ selString rangeOfString:@"(" ];
	if (funcRange.length != 0)
	{
		unsigned long long pos = NSMaxRange(funcRange);
		int quantity = 1;
		NSMutableString* total = [ [ NSMutableString alloc ] init ];
		while (pos < [ selString length ])
		{
			char cmd = [ selString characterAtIndex:pos ];
			if (cmd == '(')
				quantity++;
			else if (cmd == ')')
				quantity--;
			if (quantity == 0)
				break;
			[ total appendFormat:@"%c", cmd ];
			pos++;
		}
		
		BOOL hasSelected = FALSE;
		pos = 0;
		NSMutableString* arg = [ [ NSMutableString alloc ] init ];
		while (pos < [ total length ])
		{
			char cmd = [ total characterAtIndex:pos ];
			if (cmd == ',' || pos == [ total length ] - 1)
			{
				unsigned long long offset = 0;
				if (pos == [ total length ] - 1)
				{
					[ arg appendFormat:@"%c", cmd ];
					offset = 1;
				}
				AutoCompleteBlock block;
				memset(&block, 0, sizeof(block));
				block.position = left + NSMaxRange(funcRange) + pos - [ selString length ] - [ arg length ] + offset;
				block.text = [ [ NSString alloc ] initWithString:arg ];
				[ codeView addCompleteBlock:&block ];
				if (!hasSelected)
				{
					hasSelected = TRUE;
					[ codeView setSelectedBlock:[ codeView numberOfBlocks ] - 1 ];
					bkCursor = block.position;
				}
				[ arg setString:@"" ];
				pos = PositionAfterSpaces(pos + 1, total, NO);
				continue;
			}
			[ arg appendFormat:@"%c", cmd ];
			pos++;
		}
	}
	
	return bkCursor;
}

- (void) fillMatch: (unsigned long long) autoStart fullComplete:(BOOL)full
{
	MDAutoComplete* completeView = self;
	//NSArray* matches = [ completeView matches ];
	// Disable the first captial letter for now
	/*if ([ matches count ] != 1)
	{
		NSMutableString* selString = [ NSMutableString stringWithString:[ completeView selectedItem ] ];
		[ selString deleteCharactersInRange:NSMakeRange(0, [ [ completeView trueKeyword ] length ]) ];
		// Find next capital letter
		unsigned long capitalLoc = 0;
		unsigned long addLength = 0;
		
		if (!full)
		{
			for (unsigned long z = 0; z < [ selString length ]; z++)
			{
				char cmd = [ selString characterAtIndex:z ];
				if (cmd >= 'A' && cmd <= 'Z')
				{
					capitalLoc = z;
					break;
				}
			}
			while (capitalLoc == 0)
			{
				if ([ selString length ] == 0)
				{
					NSRange range = NSMakeRange(autoStart, [ [ completeView trueKeyword ] length ]);
					NSMutableString* repString = [ NSMutableString stringWithString:[ completeView selectedItem ] ];
					unsigned long long cursorPos = NSMaxRange(range) + [ repString length ] - range.length;
					unsigned long long cur = [ self checkForFunction:repString cursorLeft:cursorPos ];
					[ codeView shouldChangeTextInRange:range replacementString:repString ];
					[ codeView replaceCharactersInRange:range withString:repString ];
					[ codeView didChangeText ];
					[ codeView textStorageDidProcessEditing:nil ];
					[ completeView setVisible:NO ];
					[ codeView setSelectedRange:NSMakeRange(cur, 0) ];
					[ self setNeedsDisplay:YES ];
					[ codeView checkMessage ];
					if ([ [ completeView keyWord ] isEqualToString:@"" ])
						[ completeView setKeyword:repString ];
					unsigned long long numMatches = [ completeView numberOfMatches ];
					if (numMatches == 0 || (numMatches == 1 && [ [ completeView selectedItem ] isEqualToString:[ completeView trueKeyword ] ]))
						[ completeView setVisible:NO ];
					return;
				}
				addLength++;
				[ selString deleteCharactersInRange:NSMakeRange(0, 1) ];
				for (unsigned long z = 0; z < [ selString length ]; z++)
				{
					char cmd = [ selString characterAtIndex:z ];
					if (cmd >= 'A' && cmd <= 'Z')
					{
						capitalLoc = z;
						break;
					}
				}
			}
		}
		else
			capitalLoc = [ selString length ];
		
		NSString* comString = [ selString substringToIndex:capitalLoc ];
		
		BOOL found = FALSE;
		for (unsigned long z = 0; z < [ matches count ]; z++)
		{
			if ([ [ matches objectAtIndex:z ] isEqualToString:[ completeView selectedItem ] ])
				continue;
			NSMutableString* compString = [ NSMutableString stringWithString:[ matches objectAtIndex:z ] ];
			[ compString deleteCharactersInRange:NSMakeRange(0, [ [ completeView trueKeyword ] length ]) ];
			if ([ compString length ] <= capitalLoc + addLength)
				continue;
			if ([ [ compString substringToIndex:capitalLoc + addLength ] isEqualToString:comString ])
			{
				found = TRUE;
				break;
			}
		}
		if (found)
		{
			NSRange range = NSMakeRange(autoStart, [ [ completeView trueKeyword ] length ]);
			NSMutableString* repString = [ NSMutableString stringWithString:[ [ completeView selectedItem ] substringToIndex:capitalLoc + [ [ completeView trueKeyword ] length ] ] ];
			unsigned long long cursorPos = NSMaxRange(range) + [ repString length ] - range.length;
			unsigned long long cur = [ self checkForFunction:repString cursorLeft:cursorPos ];
			[ codeView shouldChangeTextInRange:range replacementString:repString ];
			[ codeView replaceCharactersInRange:range withString:repString ];
			[ codeView didChangeText ];
			[ codeView textStorageDidProcessEditing:nil ];
			[ codeView setSelectedRange:NSMakeRange(cur, 0) ];
			[ self setNeedsDisplay:YES ];
			[ codeView checkMessage ];
			if ([ [ completeView keyWord ] isEqualToString:@"" ])
				[ completeView setKeyword:repString ];
			unsigned long long numMatches = [ completeView numberOfMatches ];
			if (numMatches == 0 || (numMatches == 1 && [ [ completeView selectedItem ] isEqualToString:[ completeView trueKeyword ] ]))
				[ completeView setVisible:NO ];
			return;
		}
	}*/
	
	// Replaced autostart with realAutoStart
	unsigned long long realAutoStart = [ codeView selectedRange ].location;
	unsigned long long compStart = realAutoStart;
	NSString* codeString = [ codeView string ];
	while (realAutoStart < [ codeString length ])
	{
		char cmd = [ codeString characterAtIndex:compStart ];
		if (cmd == '\n' || cmd == ' ' || cmd == '\t')
			break;
		compStart++;
	}
	NSRange range = NSMakeRange(realAutoStart, [ [ completeView trueKeyword ] length ]);
	range.location -= range.length;
	range.length += compStart - realAutoStart;
	NSMutableString* repString = [ NSMutableString stringWithString:[ completeView selectedItem ] ];
	unsigned long long cursorPos = NSMaxRange(range) + [ repString length ] - range.length;
	unsigned long long cur = [ self checkForFunction:repString cursorLeft:cursorPos ];
	//NSRect visRect = [ codeView visibleRect ];
	[ codeView shouldChangeTextInRange:range replacementString:repString ];
	[ codeView replaceCharactersInRange:range withString:repString ];
	[ codeView didChangeText ];
	//[ codeView textStorageDidProcessEditing:nil ];
	[ codeView setSelectedRange:NSMakeRange(cur, 0) ];
	//[ codeView scrollRectToVisible:visRect ];
	[ codeView scrollRangeToVisible:NSMakeRange(cur, 0) ];
	[ completeView setVisible:NO ];
	[ self setNeedsDisplay:YES ];
	/*[ codeView checkMessage ];
	if ([ [ completeView keyWord ] isEqualToString:@"" ])
		[ completeView setKeyword:repString ];
	unsigned long long numMatches = [ completeView numberOfMatches ];
	if (numMatches == 0 || (numMatches == 1 && [ [ completeView selectedItem ] isEqualToString:[ completeView trueKeyword ] ]))
		[ completeView setVisible:NO ];*/
}

@end

@implementation MDCodeView

- (void) setupVariables
{
	[ [ completeView variables ] removeAllObjects ];
	if (language == MD_OBJ_C)
	{
		for (int z = 0; z < sizeof(ctypes) / sizeof(const char*); z++)
			[ completeView addVariable:@(ctypes[z]) ];
		for (int z = 0; z < sizeof(preprocessorWords) / sizeof(const char*); z++)
			[ completeView addVariable:@(preprocessorWords[z]) ];
	}
	else
	{
		for (int z = 0; z < sizeof(jtypes) / sizeof(const char*); z++)
			[ completeView addVariable:@(jtypes[z]) ];
	}
	
	/*int numClasses = objc_getClassList(NULL, 0);
	if (numClasses > 0)
	{
		Class* classes = (Class*)malloc(sizeof(Class) * numClasses);
		if (classes)
		{
			numClasses = objc_getClassList(classes, numClasses);
			for (int z = 0; z < numClasses; z++)
				[ completeView addVariable:[ NSString stringWithUTF8String:class_getName(classes[z]) ] ];
			free(classes);
			classes = NULL;
		}
	}*/
}

- (void) setup
//- (void) awakeFromNib
{
	[ self setDelegate:(id)self ];
	[ [ self textStorage ] setDelegate:(id)self ];
	[ [ self textStorage ] setFont:[ NSFont fontWithName:@"Menlo" size:11 ] ];
	completeView = [ [ MDAutoComplete alloc ] initWithFrame:NSMakeRect(0, 0, 400, 200) ];
	[ completeView setCodeView:self ];
	[ self addSubview:completeView ];
	[ self setupVariables ];
	fileName = [ [ NSString alloc ] init ];
	
	included = [ [ NSMutableArray alloc ] init ];
	classNames = [ [ NSMutableArray alloc ] init ];
	classData = [ [ NSMutableArray alloc ] init ];
	
	NSMenu* menu = [ [ NSMenu alloc ] init ];
	[ menu setAllowsContextMenuPlugIns:NO ];
	[ menu addItemWithTitle:@"Copy" action:@selector(copy:) keyEquivalent:@"" ];
	[ menu addItemWithTitle:@"Cut" action:@selector(cut:) keyEquivalent:@"" ];
	[ menu addItemWithTitle:@"Paste" action:@selector(paste:) keyEquivalent:@"" ];
	//[ menu addItem:[ NSMenuItem separatorItem ] ];
	//[ menu addItemWithTitle:@"Jump to Definition" action:@selector(jumpToDefinition) keyEquivalent:@"" ];
	[ self setMenu:menu ];
	
	selectedBlock = -1;
	enableBreaks = FALSE;
	
	[ self setSmartInsertDeleteEnabled:NO ];
	[ self setAutomaticDashSubstitutionEnabled:NO ];
	[ self setAutomaticDataDetectionEnabled:NO ];
	[ self setAutomaticLinkDetectionEnabled:YES ];
	[ self setAutomaticQuoteSubstitutionEnabled:NO ];
	[ self setAutomaticTextReplacementEnabled:NO ];
	
	[ self setFrame:[ self frame ] ];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        /*// Initialization code here.
		[ [ self textStorage ] setFont:[ NSFont fontWithName:@"Menlo" size:11 ] ];
		[ self setDelegate:(id)self ];
		[ [ self textStorage ] setDelegate:(id)self ];
		completeView = [ [ MDAutoComplete alloc ] initWithFrame:NSMakeRect(0, 0, 400, 200) ];
		[ completeView setCodeView:self ];
		[ self addSubview:completeView ];
		[ self setupVariables ];
		[ completeView release ];
		fileName = [ [ NSString alloc ] initWithString:@"" ];
		
		included = [ [ NSMutableArray alloc ] init ];
		classNames = [ [ NSMutableArray alloc ] init ];
		classData = [ [ NSMutableArray alloc ] init ];
		
		NSMenu* menu = [ [ NSMenu alloc ] init ];
		[ menu setAllowsContextMenuPlugIns:NO ];
		[ menu addItemWithTitle:@"Copy" action:@selector(copy:) keyEquivalent:@"" ];
		[ menu addItemWithTitle:@"Cut" action:@selector(cut:) keyEquivalent:@"" ];
		[ menu addItemWithTitle:@"Paste" action:@selector(paste:) keyEquivalent:@"" ];
		//[ menu addItem:[ NSMenuItem separatorItem ] ];
		//[ menu addItemWithTitle:@"Jump to Definition" action:@selector(jumpToDefinition) keyEquivalent:@"" ];
		[ self setMenu:menu ];
		[ menu release ];
		
		selectedBlock = -1;*/
		[ self setup ];
    }
    
    return self;
}

/*- (id) initWithFrame:(NSRect)frameRect
{
	self = [ super initWithFrame:frameRect ];
	if (self) {
		[ self setup ];
	}
	return self;
}*/

- (void) awakeFromNib
{
	[ self setup ];
}

- (void) setFrame:(NSRect)frameRect
{
	[ super setFrame:frameRect ];
	
	[ [ self textContainer ] setLineFragmentPadding:35 ];
}

- (void) setText:(NSString*)text
{
	executionLine = 0;
	breakpoints.clear();
	[ self setFont:[ NSFont fontWithName:@"Menlo" size:11 ] ];
	[ self setDelegate:(id)self ];
	[ [ self textStorage ] setDelegate:(id)self ];
	
	if (loadingThread)
	{
		[ loadingThread cancel ];
		while (loading) {}
	}
	
	waitForEdit = TRUE;
	[ self setString:[ NSString stringWithString:text ] ];
	[ self processHighlight:NSMakeRange(0, [ text length ]) ];
	[ self setNeedsDisplay:YES ];
	waitForEdit = FALSE;
	
	[ self reloadLines ];
	
	// Really buggy atm
	//[ NSThread detachNewThreadSelector:@selector(readDocuments) toTarget:self withObject:nil ];
	[ self readDocuments ];
	
	//[ self parseRegion:NSMakeRange(0, [ [ self string ] length ]) usingString:[ self string ] ];
}

- (void) processHighlight: (NSRange)range
{
	//if (loading)
//		return;
	
	if (range.length == 0)
		return;
	
	waitForEdit = TRUE;
	
	NSTextStorage* storage = [ self textStorage ];
	NSRange search = NSMakeRange(range.location, 0);
	NSString* text = [ self string ];
	[ storage removeAttribute:NSForegroundColorAttributeName range:range ];
		
	// Check every word for a Objective-C class
	NSMutableString* wordString = [ [ NSMutableString alloc ] init ];
	unsigned long long startSearch = range.location;
	NSMutableArray* classCopy = [ classNames copy ];
	for (unsigned long long searchIndex = range.location; searchIndex < NSMaxRange(range); searchIndex++)
	{
		unsigned char cmd = [ text characterAtIndex:searchIndex ];
		BOOL happens = FALSE;
		for (int z = 0; z < sizeof(posschar); z++)
		{
			if (cmd == posschar[z])
			{
				happens = TRUE;
				break;
			}
		}
		if (happens)
		{
			if ([ wordString length ] != 0 && [ classCopy containsObject:wordString ])
			{
				[ storage addAttribute:NSForegroundColorAttributeName value:[ NSColor colorWithCalibratedRed:0.435294 green:0.254902 blue:0.654902 alpha:1 ] range:NSMakeRange(startSearch, searchIndex - startSearch) ];
			}
			[ wordString setString:@"" ];
			startSearch = searchIndex;
		}
		else
		{
			[ wordString appendFormat:@"%c", cmd ];
		}
	}
	
	// Types
	unsigned long numTypes = (language == MD_OBJ_C) ? (sizeof(ctypes) / sizeof(const char*)) : (sizeof(jtypes) / sizeof(const char*));
	const char** validtypes = (language == MD_OBJ_C) ? ctypes : jtypes;
	for (int z = 0; z < numTypes; z++)
	{
		search = NSMakeRange(range.location, 0);
		do
		{
			search = [ text rangeOfString:@(validtypes[z]) options:0 range:NSMakeRange(NSMaxRange(search), NSMaxRange(range) - NSMaxRange(search)) ];
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
	
	waitForEdit = FALSE;
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

- (unsigned long long) positionAfterSpaces:(unsigned long long)start
{
	unsigned long long tmp = start;
	NSString* text = [ self string ];
	while (tmp < [ text length ])
	{
		if (!([ text characterAtIndex:tmp ] != ' ' && [ text characterAtIndex:tmp ] != '\n' && [ text characterAtIndex:tmp ] != '\t'))
		{
			tmp++;
			break;
		}
		tmp++;
	}
	return tmp;
}

- (NSString*) interpretString: (NSString*) string
{
	for (unsigned long z = 0; z < variables.size(); z++)
	{
		if ([ variables[z].name isEqualToString:string ])
		{
			if ([ variables[z].type isEqualToString:@"Class" ])
				return variables[z].name;
			return variables[z].type;
		}
	}
	
	for (unsigned long z = 0; z < globalVariables.size(); z++)
	{
		if ([ globalVariables[z].name isEqualToString:string ])
		{
			if ([ globalVariables[z].type isEqualToString:@"Class" ])
				return globalVariables[z].name;
			return globalVariables[z].type;
		}
	}
	
	if ([ classNames containsObject:string ])
		return string;
	
	// Make this apply to others
	if ([ string hasPrefix:@"[" ])
	{
		unsigned char cmd = 0;
		unsigned long z = 1;
		NSMutableString* target = [ NSMutableString string ];
		NSMutableString* action = [ NSMutableString string ];
		BOOL done = FALSE;
		for (;;)
		{
			if (z >= [ string length ])
			{
				done = TRUE;
				break;
			}
			
			cmd = [ string characterAtIndex:z++ ];
			if (cmd != ' ' && cmd != '\n' && cmd != '\t')
			{
				z--;
				break;
			}
		}
		if (done)
			return @"";
		for (;;)
		{
			if (z >= [ string length ])
			{
				done = TRUE;
				break;
			}
			
			cmd = [ string characterAtIndex:z++ ];
			if (cmd == ' ' || cmd == '\n' || cmd == '\t')
				break;
			[ target appendFormat:@"%c", cmd ];
		}
		if (done)
			return @"";
		for (;;)
		{
			done = FALSE;
			for (;;)
			{
				if (z >= [ string length ])
				{
					done = TRUE;
					break;
				}
				
				cmd = [ string characterAtIndex:z++ ];
				if (cmd != ' ' && cmd != '\n' && cmd != '\t')
				{
					if (cmd == ']')
					{
						done = TRUE;
						break;
					}
					z--;
					break;
				}
			}
			if (done)
				break;
			for (;;)
			{
				if (z >= [ string length ])
				{
					done = TRUE;
					break;
				}
				
				cmd = [ string characterAtIndex:z++ ];
				if (cmd == ' ' || cmd == '\n' || cmd == '\t' || cmd == ':')
				{
					if (cmd == ':')
					{
						[ action appendFormat:@"%c", cmd ];
						for (;;)
						{
							cmd = [ string characterAtIndex:z++ ];
							if (cmd != ' ' && cmd != '\n' && cmd != '\t')
							{
								z--;
								break;
							}
						}
						for (;;)
						{
							cmd = [ string characterAtIndex:z++ ];
							if (cmd == ' ' || cmd == '\n' || cmd == '\t')
								break;
						}
					}
					break;
				}
				[ action appendFormat:@"%c", cmd ];
			}
		}
		
		[ target setString:[ self interpretString:target ] ];
		if (NSClassFromString(target)/* && class_respondsToSelector(NSClassFromString(target), NSSelectorFromString(action))*/)
		{
			Method meth = class_getInstanceMethod(NSClassFromString(target), NSSelectorFromString(action));
			char* dst = method_copyReturnType(meth);
			if (!dst)
				return @"";
			NSString* ret = @(dst);
			free(dst);
			dst = NULL;
			return ret;
		}
	}
	
	return @"";
}

- (void) checkMessage
{
	
	unsigned long long cursorR = [ [ self selectedRanges ][0] rangeValue ].location - 1;
	NSMutableString* name = [ [ NSMutableString alloc ] init ];
	while (cursorR < [ [ self string ] length ])
	{
		char cmd = [ [ self string ] characterAtIndex:cursorR ];
		if (cmd == '\n' || cmd == '\t' || cmd == ' ')
			break;
		[ name insertString:[ NSString stringWithFormat:@"%c", cmd ] atIndex:0 ];
		cursorR--;
	}
	
	//NSLog(@"%@", name);
	
	// Interpret name to see if it is something bigger (i.e rect.size.width)
	
	if ([ name rangeOfString:@"." ].length != 0)
	{
		unsigned long long pointIndex = [ name rangeOfString:@"." ].location;
		NSString* realName = [ NSString stringWithString:[ name substringToIndex:pointIndex ] ];
		NSString* realVar = [ NSString stringWithString:[ name substringFromIndex:pointIndex + 1 ] ];
		NSString* type = nil;
		for (int z = 0; z < globalVariables.size(); z++)
		{
			if ([ globalVariables[z].name isEqualToString:realName ])
			{
				type = [ NSString stringWithString:globalVariables[z].type ];
				break;
			}
		}

		if (!type || [ type length ] == 0)
		{
			[ completeView setKeyword:@"" ];
			[ completeView setHasClassType:NO ];
			[ completeView setUseBoth:NO keyWord:@"" ];
			return;
		}

		if (![ [ completeView classType ] isEqualToString:type ])
		{
			/*NSMethodSignature* sig = [ completeView methodSignatureForSelector:@selector(setClassType:withData:andNames:hasDot:) ];
			NSInvocation* invoc = [ NSInvocation invocationWithMethodSignature:sig ];
			[ invoc setTarget:completeView ];
			[ invoc setSelector:@selector(setClassType:withData:andNames:hasDot:) ];
			[ invoc setArgument:&type atIndex:2 ];
			[ invoc setArgument:&classData atIndex:3 ];
			[ invoc setArgument:&classNames atIndex:4 ];
			BOOL yep = YES;
			[ invoc setArgument:&yep atIndex:5 ];
			[ NSThread detachNewThreadSelector:@selector(invoke) toTarget:invoc withObject:nil ];
			loadingClass = TRUE;*/
			[ completeView setClassType:type withData:classData andNames:classNames hasDot:YES  ];
		}
		if (!loadingClass)
		{
			[ completeView setKeyword:realVar ];
			if ([ completeView numberOfMatches ] != 0)
			{
				[ completeView setVisible:YES ];
				NSLayoutManager *lm = [ self layoutManager ];
				unsigned long long searchIndex = [ [ self selectedRanges ][0] rangeValue ].location - [ realVar length ];
				NSRange glyphRange = [ lm glyphRangeForCharacterRange:NSMakeRange(searchIndex, 0) actualCharacterRange:NULL ];
				autoStart = searchIndex;
				NSRect completionRect = [ lm boundingRectForGlyphRange:glyphRange inTextContainer:[ self textContainer ] ];
				[ completeView setFrame:NSMakeRect(completionRect.origin.x, completionRect.origin.y + completionRect.size.height, 400, 200) ];
			}
		}

		return;
	}
	
	inObjCCommand = FALSE;
	// Check if in brackets
	unsigned long bquantity = 0;
	unsigned long long cursorB = [ [ self selectedRanges ][0] rangeValue ].location;
	msgSender = [ [ NSMutableString alloc ] init ];
	NSMutableString* msgMethod = [ [ NSMutableString alloc ] init ];
	while (cursorB < [ [ self string ] length ])
	{
		if ([ [ self string ] characterAtIndex:cursorB ] == ']')
			bquantity--;
		else if ([ [ self string ] characterAtIndex:cursorB ] == '[')
		{
			bquantity++;
			inObjCCommand = TRUE;
			unsigned long long bcursor = [ self positionAfterSpaces:cursorB + 1 ];
			unsigned long quantityB = 0;
			BOOL usedB = FALSE;
			[ msgSender setString:@"" ];
			while (bcursor < [ [ self selectedRanges ][0] rangeValue ].location)
			{
				if ([ [ self string ] characterAtIndex:bcursor ] == '[')
				{
					quantityB++;
					usedB = TRUE;
					
				}
				else if ([ [ self string ] characterAtIndex:bcursor ] == ']')
				{
					quantityB--;
					usedB = TRUE;
				}
				if (![ msgSender hasPrefix:@"[" ] && ([ [ self string ] characterAtIndex:bcursor ] == ' ' || [ [ self string ] characterAtIndex:bcursor ] == '\n' || [ [ self string ] characterAtIndex:bcursor ] == '\t'))
					break;
				[ msgSender appendFormat:@"%c", [ [ self string ] characterAtIndex:bcursor ] ];
				if (usedB && quantityB == 0)
					break;
				bcursor++;
			}
			bcursor = [ self positionAfterSpaces:bcursor ];
			while (bcursor < [ [ self selectedRanges ][0] rangeValue ].location)
			{
				if ([ [ self string ] characterAtIndex:bcursor ] == ']' || [ [ self string ] characterAtIndex:bcursor ] == ';')
					break;
				[ msgMethod appendFormat:@"%c", [ [ self string ] characterAtIndex:bcursor ] ];
				bcursor++;
			}
			while ([ msgMethod rangeOfString:@": " ].length != 0)
			{
				[ msgMethod replaceOccurrencesOfString:@": " withString:@":" options:0 range:NSMakeRange(0, [ msgMethod length ]) ];
			}
			while ([ msgMethod rangeOfString:@":\t" ].length != 0)
			{
				[ msgMethod replaceOccurrencesOfString:@"\t" withString:@":" options:0 range:NSMakeRange(0, [ msgMethod length ]) ];
			}
			while ([ msgMethod rangeOfString:@":\n" ].length != 0)
			{
				[ msgMethod replaceOccurrencesOfString:@"\n" withString:@":" options:0 range:NSMakeRange(0, [ msgMethod length ]) ];
			}
			// Remove arguements from msgMethod
		}
		else if ([ [ self string ] characterAtIndex:cursorB ] == ';')
			break;
		cursorB--;
	}
	
	if ([ msgSender length ] != 0 && [ msgMethod length ] != 0)
	{
		// For now
		//[ msgSender setString:@"NSString" ];
		// Add something here to interpret the sender and simplify it and see if it is legit
		// Right now calls this every time a new letter is added, even if this isnt changed
		[ msgSender setString:[ self interpretString:msgSender ] ];
		
		if ([ msgSender length ] == 0)
		{
			[ completeView setKeyword:@"" ];
			[ completeView setHasClassType:NO ];
			[ completeView setUseBoth:NO keyWord:@"" ];
			
			return;
		}
		
		BOOL hasPrev = [ completeView hasClassType ] && [ completeView keyWord ];
		if (![ [ completeView classType ] isEqualToString:msgSender ])
		{
			/*NSMethodSignature* sig = [ completeView methodSignatureForSelector:@selector(setClassType:withData:andNames:hasDot:) ];
			NSInvocation* invoc = [ NSInvocation invocationWithMethodSignature:sig ];
			[ invoc setTarget:completeView ];
			[ invoc setSelector:@selector(setClassType:withData:andNames:hasDot:) ];
			[ invoc setArgument:&msgSender atIndex:2 ];
			[ invoc setArgument:&classData atIndex:3 ];
			[ invoc setArgument:&classNames atIndex:4 ];
			BOOL nope = NO;
			[ invoc setArgument:&nope atIndex:5 ];
			[ NSThread detachNewThreadSelector:@selector(invoke) toTarget:invoc withObject:nil ];*/
			[ completeView setClassType:msgSender withData:classData andNames:classNames hasDot:NO ];
		}
		BOOL useBoth = FALSE;
		if ([ msgMethod rangeOfString:@":" ].length != 0)
			useBoth = TRUE;
		[ completeView setKeyword:msgMethod ];
		BOOL prevUse = [ completeView useBoth ];
		if (prevUse != useBoth)
			hasPrev = FALSE;
		[ completeView setUseBoth:useBoth keyWord:(useBoth ? [ msgMethod substringFromIndex:[ msgMethod rangeOfString:@":" ].location + 1 ] : @"") ];
		if (!hasPrev && [ completeView numberOfMatches ] != 0)
		{
			[ completeView setVisible:YES ];
			NSLayoutManager *lm = [ self layoutManager ];
			unsigned long long searchIndex = [ [ self selectedRanges ][0] rangeValue ].location;
			NSRange glyphRange = [ lm glyphRangeForCharacterRange:NSMakeRange(searchIndex, 0) actualCharacterRange:NULL ];
			autoStart = searchIndex - 1;
			if (useBoth)
				autoStart++;
			NSRect completionRect = [ lm boundingRectForGlyphRange:glyphRange inTextContainer:[ self textContainer ] ];
			[ completeView setFrame:NSMakeRect(completionRect.origin.x, completionRect.origin.y + completionRect.size.height, 400, 200) ];
		}
		else if ([ completeView numberOfMatches ] == 0)
		{
			[ completeView setVisible:NO ];
			[ completeView setKeyword:@"" ];
			[ completeView setHasClassType:NO ];
			[ completeView setUseBoth:NO keyWord:@"" ];
		}
	}
	else
	{
		[ completeView setKeyword:@"" ];
		[ completeView setHasClassType:NO ];
		[ completeView setUseBoth:NO keyWord:@"" ];
	}
	
	if ([ completeView hasClassType ] && !inObjCCommand)
	{
		[ completeView setKeyword:@"" ];
		[ completeView setHasClassType:NO ];
		[ completeView setUseBoth:NO keyWord:@"" ];
	}
}

- (void) setKeyWord:(NSArray*)array
{
	while (isMatching) {}
	
	isSearching = TRUE;
	
	NSMutableString* string = array[0];
	[ completeView setKeyword:string ];
	if (exitSearch)
	{
		isSearching = FALSE;
		return;
	}
	if ([ completeView numberOfMatches ] != 0)
	{
		[ completeView setVisible:YES ];
		[ completeView setNeedsDisplay:YES ];
	}
	
	isSearching = FALSE;
}

- (void) findClassType
{
	// Find last word
	if (![ completeView hasClassType ])
	{
		NSRange cursorR = [ [ self selectedRanges ][0] rangeValue ];
		[ completeView setVisible:NO ];
		if (cursorR.length == 0)
		{
			NSMutableString* string = [ [ NSMutableString alloc ] init ];
			unsigned long long searchIndex = cursorR.location;
			while (searchIndex != 0)
			{
				unsigned char cmd = [ [ self string ] characterAtIndex:searchIndex-1 ];
				BOOL happen = FALSE;
				for (int z = 0; z < sizeof(posschar); z++)
				{
					if (cmd == posschar[z])
					{
						happen = TRUE;
						break;
					}
				}
				if (!happen)
					[ string insertString:[ NSString stringWithFormat:@"%c", cmd ] atIndex:0 ];
				else if ([ string length ] != 0)
				{
					if (isSearching)
						exitSearch = TRUE;
					// idk sometimes hangs
					//while (isSearching) {}
					[ NSThread detachNewThreadSelector:@selector(setKeyWord:) toTarget:self withObject:@[string, @(searchIndex)] ];
					
					NSLayoutManager *lm = [ self layoutManager ];
					NSRange glyphRange = [ lm glyphRangeForCharacterRange:NSMakeRange(searchIndex, 0) actualCharacterRange:NULL ];
					autoStart = searchIndex;
					NSRect completionRect = [ lm boundingRectForGlyphRange:glyphRange inTextContainer:[ self textContainer ] ];
					
					[ completeView setFrame:NSMakeRect(completionRect.origin.x, completionRect.origin.y + completionRect.size.height, 400, 200) ];
					[ self setNeedsDisplay:YES ];
					break;
				}
				else
					[ completeView setVisible:NO ];
				if (happen && [ string length ] == 0)
					break;
				searchIndex--;
			}
		}
	}
}

unsigned long bpDown = -1;
BOOL noMove = FALSE;

- (void) mouseDown:(NSEvent *)theEvent
{
	NSPoint p = [ theEvent locationInWindow ];
	p.y = [ [ self enclosingScrollView ] documentVisibleRect ].size.height - p.y;
	
	if (showVariable && enableBreaks)
	{
		NSPoint point = [ theEvent locationInWindow ];
		point.y = [ [ self enclosingScrollView ] documentVisibleRect ].size.height - point.y;
		point.y += [ [ self enclosingScrollView ] documentVisibleRect ].origin.y;
		//NSLog(@"%f, %f, %f, %f", point.x, variablePoint.x, width, variableSize.width);
		if (point.x >= variablePoint.x && point.x <= variablePoint.x + variableSize.width &&
			point.y >= variablePoint.y && point.y <= variablePoint.y + variableSize.height)
		{
			unsigned long pos = 0, pos1 = 0, pos2 = 0;
			unsigned long counter = 0;
			while (pos < [ variableString length ])
			{
				if ([ variableString characterAtIndex:pos ] == '\t')
				{
					counter++;
					if (counter == 2)
						pos1 = pos;
					else if (counter == 4)
					{
						pos2 = pos;
						break;
					}
				}
				pos++;
			}
			NSString* varName = [ variableString substringWithRange:NSMakeRange(pos1, pos2 - 1 - pos1) ];
			NSString* value = [ variableString substringFromIndex:pos2 + 1 ];
			
			// Show window
			NSAlert *alert = [NSAlert alertWithMessageText:[ NSString stringWithFormat:@"Set the value of the variable \"%@\"", varName ] defaultButton:@"Set" alternateButton:@"Cancel" otherButton:nil informativeTextWithFormat:@""];
			NSTextField *input = [ [ NSTextField alloc ] initWithFrame:NSMakeRect(0, 0, 230, 24) ];
			[ input setStringValue:value ];
			[ alert setAccessoryView:input ];
			NSInteger button = [ alert runModal ];
			if (button == NSAlertDefaultReturn)
			{
				[ input validateEditing ];
				[ self updateVariable:varName value:[ input stringValue ] ];
				showVariable = FALSE;
				[ self setNeedsDisplay:YES ];
			}
		}
		else
		{
			showVariable = FALSE;
			[ self setNeedsDisplay:YES ];
		}
		return;
	}
	
	if (p.x < 35 && enableBreaks)
	{
		// Lines
		bpDown = -1;
		float scroll = [ [ self enclosingScrollView ] documentVisibleRect ].origin.y + p.y;
		for (unsigned long z = lineHeights.size() - 1; z != -1; z--)
		{
			if (lineHeights[z] < scroll)
			{
				BOOL found = FALSE;
				for (unsigned long q = 0; q < breakpoints.size(); q++)
				{
					if (breakpoints[q] == z + 1)
					{
						//breakpoints.erase(breakpoints.begin() + q);
						bpDown = q;
						found = TRUE;
						noMove = TRUE;
						break;
					}
				}
				if (!found)
				{
					breakpoints.push_back(z + 1);
					updateBreaks = TRUE;
					[ self setNeedsDisplay:YES ];
				}
				break;
			}
		}
		return;
	}
	
	NSRect rect = [ completeView frame ];
	if (!(p.x >= rect.origin.x && p.x <= rect.origin.x + rect.size.width && p.y >= rect.origin.y && p.y <= rect.origin.y + rect.size.height))
	{
		[ completeView setVisible:NO ];
		[ completeView setNeedsDisplay:YES ];
	}
	else if ([ completeView visible ] || (![completeView visible ] && [ completeView needsDisplay ]))
		return;

	if (![ completeView visible ] && completeBlocks.size() != 0)
	{
		unsigned long long selB = selectedBlock;
		selectedBlock = -1;
		for (unsigned long long z = 0; z < completeBlocks.size(); z++)
		{
			AutoCompleteBlock block = completeBlocks[z];
			NSLayoutManager *layoutManager = [self layoutManager];
			NSRange range = [ layoutManager glyphRangeForCharacterRange:NSMakeRange(block.position, 0) actualCharacterRange:NULL ];
			NSRect rect = [ layoutManager boundingRectForGlyphRange:range inTextContainer:[ self textContainer ] ];
			NSPoint containerOrigin = [ self textContainerOrigin ];
			rect = NSOffsetRect(rect,containerOrigin.x,containerOrigin.y);
			rect.origin.y -= 1;
			NSAttributedString* string = [ [ NSAttributedString alloc ] initWithString:block.text attributes:@{NSFontAttributeName: [ self font ], NSForegroundColorAttributeName: [ NSColor blackColor ]} ];
			rect.size = [ string size ];
			rect.size.height -= 3;
			rect.origin.x -= 2;
			rect.size.width += 4;
			
			if (selB == z)
				[ self setNeedsDisplayInRect:rect ];
			
			if (NSPointInRect(p, rect))
			{
				selectedBlock = z;
				[ self setSelectedRange:NSMakeRange(completeBlocks[z].position, 0) ];
				[ super mouseDown:theEvent ];
				[ self setNeedsDisplay:YES ];
				return;
			}
		}
	}
	
	[ super mouseDown:theEvent ];
}

- (void) mouseDragged:(NSEvent *)theEvent
{
	NSPoint p = [ theEvent locationInWindow ];
	p.y = [ [ self enclosingScrollView ] documentVisibleRect ].size.height - p.y;
	
	if (bpDown != -1 && bpDown < breakpoints.size() && enableBreaks)
	{
		// Lines
		float scroll = [ [ self enclosingScrollView ] documentVisibleRect ].origin.y + p.y;
		for (unsigned long z = lineHeights.size() - 1; z != -1; z--)
		{
			if (lineHeights[z] < scroll)
			{
				BOOL found = FALSE;
				unsigned long q = bpDown;
				breakpoints.erase(breakpoints.begin() + q);
				breakpoints.push_back(z + 1);
				bpDown = breakpoints.size() - 1;
				found = TRUE;
				if (z + 1 != q)
				{
					noMove = FALSE;
					updateBreaks = TRUE;
					[ self setNeedsDisplay:YES ];
				}
				if (!found)
					bpDown = -1;
				break;
			}
		}
		return;
	}
}

- (void) mouseUp:(NSEvent *)theEvent
{
	if (bpDown != -1 && bpDown < breakpoints.size() && enableBreaks)
	{
		if (noMove)
		{
			breakpoints.erase(breakpoints.begin() + bpDown);
			updateBreaks = TRUE;
			[ self setNeedsDisplay:YES ];
		}
		bpDown = -1;
	}
}

- (void) mouseMoved:(NSEvent *)theEvent
{
	if (enableBreaks && executionLine != 0)
	{
		if (variableTimer && [ variableTimer isValid ])
			[ variableTimer invalidate ];
		float time = 1;
		BOOL doTimer = TRUE;
		if (showVariable)// && variableSize.width != 0 && variableSize.height != 0)
		{
			time = .2;
			NSPoint point = [ theEvent locationInWindow ];
			point.y = [ [ self enclosingScrollView ] documentVisibleRect ].size.height - point.y;
			point.y += [ [ self enclosingScrollView ] documentVisibleRect ].origin.y;
			if (point.x >= variablePoint.x && point.x <= variablePoint.x + variableSize.width &&
				point.y >= variablePoint.y && point.y <= variablePoint.y + variableSize.height)
				doTimer = FALSE;
		}
		//else if (variableSize.width == 0 && variableSize.height == 0)
		//	doTimer = FALSE;
		
		if (doTimer)
		{
			variableTimer = [ NSTimer scheduledTimerWithTimeInterval:time target:self selector:@selector(checkVariableSecond) userInfo:nil repeats:NO ];
			variablePoint = [ theEvent locationInWindow ];
			variablePoint.y = [ [ self enclosingScrollView ] documentVisibleRect ].size.height - variablePoint.y;
			variablePoint.y += [ [ self enclosingScrollView ] documentVisibleRect ].origin.y;
		}
		else
		{
			variableTimer = nil;
		//	variableSize = NSMakeSize(0, 0);
		}
	}
}

- (void) keyDown:(NSEvent *)theEvent
{
	unsigned short key = [ [ theEvent characters ] characterAtIndex:0 ];
	
	if (readingDocs && key != NSUpArrowFunctionKey && key != NSDownArrowFunctionKey && key != NSLeftArrowFunctionKey && key != NSRightArrowFunctionKey)
		return;
	if (![ completeView visible ] && (key == NSUpArrowFunctionKey || key == NSDownArrowFunctionKey || key == NSLeftArrowFunctionKey || key == NSRightArrowFunctionKey))
	{
		if (key == NSRightArrowFunctionKey || key == NSLeftArrowFunctionKey)
		{
			unsigned long long pos = [ self selectedRange ].location;
			if (selectedBlock != -1)
			{
				if ((completeBlocks[selectedBlock].position == pos && key == NSRightArrowFunctionKey) || (completeBlocks[selectedBlock].position + [ completeBlocks[selectedBlock].text length ] == pos && key == NSLeftArrowFunctionKey))
				{
					if (key == NSRightArrowFunctionKey)
						pos = completeBlocks[selectedBlock].position + [ completeBlocks[selectedBlock].text length ] - 1;
					else
						pos = completeBlocks[selectedBlock].position + 1;
					[ self setSelectedRange:NSMakeRange(pos, 0) ];
				}
			}
			selectedBlock = -1;
			if (key == NSRightArrowFunctionKey)
				pos = NSMaxRange([ self selectedRange ]) + ([ self selectedRange ].length == 0 ? 1 : 0);
			else
				pos = [ self selectedRange ].location - ([ self selectedRange ].length == 0 ? 1 : 0);
			for (unsigned long long z = 0; z < completeBlocks.size(); z++)
			{
				//if (pos == ((key == NSRightArrowFunctionKey) ? completeBlocks[z].position : (completeBlocks[z].position + [ completeBlocks[z].text length ])))
				if (pos == completeBlocks[z].position || pos == completeBlocks[z].position + [ completeBlocks[z].text length ])
				{
					selectedBlock = z;
					break;
				}
			}
			[ self setNeedsDisplay:YES ];
		}
		[ super keyDown:theEvent ];
		if (key == NSUpArrowFunctionKey || key == NSDownArrowFunctionKey)
		{
			unsigned long long cursorPos = [ self selectedRange ].location;
			selectedBlock = -1;
			for (unsigned long long z = 0; z < completeBlocks.size(); z++)
			{
				if (cursorPos >= completeBlocks[z].position && cursorPos <= completeBlocks[z].position + [ completeBlocks[z].text length ])
				{
					selectedBlock = z;
					if (cursorPos != completeBlocks[z].position + [ completeBlocks[z].text length ])
						cursorPos = completeBlocks[z].position;
					[ self setSelectedRange:NSMakeRange(cursorPos, 0) ];
					[ self setNeedsDisplay:YES ];
					break;
				}
			}
			[ self setNeedsDisplay:YES ];
		}
		return;
	}
	
	if ([ theEvent keyCode ] == 53)
	{
		if (![ completeView visible ])
		{
			[ self checkMessage ];
			if ([ [ completeView keyWord ] isEqualToString:@"" ])
				[ self findClassType ];
			if ([ completeView visible ])
				[ completeView setVisible:NO ];
			else if ([ completeView numberOfMatches ] != 0)
				[ completeView setVisible:YES ];
			[ completeView setNeedsDisplay:YES ];
		}
		else
		{
			[ completeView setVisible:NO ];
			[ completeView setNeedsDisplay:YES ];
		}
		return;
	}
	
	if ((key == NSTabCharacter || key == NSBackTabCharacter) && ![ completeView visible ] && completeBlocks.size() != 0)
	{
		unsigned long long pos = [ self selectedRange ].location;
		if (pos > [ [ self string ] length ] || pos == NSNotFound)
		{
			[ super keyDown:theEvent ];
			return;
		}
		
		BOOL done = FALSE;
		BOOL gone = TRUE;
		if (key == NSBackTabCharacter)
		{
			do
			{
				for (unsigned long long z = 0; z < completeBlocks.size(); z++)
				{
					if (selectedBlock == z && gone)
					{
						gone = FALSE;
						continue;
					}
					if (pos == completeBlocks[z].position)
					{
						selectedBlock = z;
						done = TRUE;
						break;
					}
				}
				if (done)
					break;
				pos--;
				if (pos == -1)
					pos = [ [ self string ] length ] - 1;
			}
			while (pos != [ self selectedRange ].location);
		}
		else
		{
			do
			{
				for (unsigned long long z = 0; z < completeBlocks.size(); z++)
				{
					if (selectedBlock == z && gone)
					{
						gone = FALSE;
						continue;
					}
					if (pos == completeBlocks[z].position)
					{
						selectedBlock = z;
						done = TRUE;
						break;
					}
				}
				if (done)
					break;
				pos++;
				if (pos >= [ [ self string ] length ])
					pos = 0;
			}
			while (pos != [ self selectedRange ].location);
		}
		if (!done)
			selectedBlock = -1;
		else
		{
			[ self scrollRangeToVisible:NSMakeRange(completeBlocks[selectedBlock].position, [ completeBlocks[selectedBlock].text length ])];
			[ self setSelectedRange:NSMakeRange(pos, 0) ];
		}
		[ self setNeedsDisplay:YES ];
		return;
	}
	
	editedLength = 0;
	if (![ completeView visible ] && selectedBlock != -1)
	{
		// Remove this block and put the cursor at the start of its position, and remove whats under it
		NSRange range = NSMakeRange(completeBlocks[selectedBlock].position, [ completeBlocks[selectedBlock].text length ]);
		unsigned long long delPos = completeBlocks[selectedBlock].position;
		if (key == NSDeleteCharacter || key == NSBackspaceCharacter)
		{
			range.location++;
			range.length--;
			delPos++;
		}
		shouldDeleteBlocks = FALSE;
		[ self shouldChangeTextInRange:range replacementString:@"" ];
		[ self replaceCharactersInRange:range withString:@"" ];
		[ self didChangeText ];
		//[ self textStorageDidProcessEditing:nil ];
		
		[ self setSelectedRange:NSMakeRange(delPos, 0) ];
		completeBlocks.erase(completeBlocks.begin() + selectedBlock);
		selectedBlock = -1;
		
		shouldDeleteBlocks = TRUE;
		
		editedLength = -range.length;
	}
	
	if ((key == NSDeleteCharacter || key == NSBackspaceCharacter) && ![ completeView visible ])
	{
		unsigned long long pos = [ self selectedRange ].location - ([ self selectedRange ].length == 0 ? 1 : 0);
		selectedBlock = -1;
		for (unsigned long long z = 0; z < completeBlocks.size(); z++)
		{
			if (pos == completeBlocks[z].position + [ completeBlocks[z].text length ])
			{
				selectedBlock = z;
				break;
			}
		}
		[ self setNeedsDisplay:YES ];
	}
	
	if ([ [ self selectedRanges ][0] rangeValue ].length != 0 || key == NSBackspaceCharacter || key == NSDeleteCharacter)
	{
		// If the last one was a '\n', move errors
		NSRange cursorR = [ [ self selectedRanges ][0] rangeValue ];
		if (cursorR.length != 0)
			cursorR.location++;
		unsigned long long cursor = NSMaxRange(cursorR);
		if (cursor >= [ [ self string ] length ])
			cursor--;
		unsigned long long lineNumber = -1;
		unsigned long long amount = 0;
		while (cursor >= cursorR.location - 1)
		{
			if (cursor >= [ [ self string ] length ])
				break;
			if ([ [ self string ] characterAtIndex:cursor ] == '\n')
			{
				for (unsigned long long y = 0; y < lineRanges.size(); y++)
				{
					if (cursor >= lineRanges[y].location && cursor <= NSMaxRange(lineRanges[y]))
					{
						if (lineNumber > y)
							lineNumber = y;
						
						amount++;
						break;
					}
				}
			}
			cursor--;
			if (cursor >= [ [ self string ] length ])
				break;
		}
		amount--;
		if (lineNumber != -1 && amount != 0 && amount != -1)
		{
			for (int z = 0; z < errors.size(); z++)
			{
				if (errors[z].line >= lineNumber)
					errors[z].line -= amount;
			}
			for (int z = 0; z < breakpoints.size(); z++)
			{
				if (breakpoints[z] >= lineNumber)
					breakpoints[z] -= amount;
			}
		}
	}
	
	if (!([ completeView visible ] && (key == NSUpArrowFunctionKey || key == NSDownArrowFunctionKey || key == '\t')))
	{
		if (key == ';')
		{
			NSRange cursorR = [ [ self selectedRanges ][0] rangeValue ];
			if (cursorR.location != NSNotFound)
			{
				BOOL wasSpace = FALSE;
				unsigned long long firstPos = cursorR.location;
				while (firstPos != -1)
				{
					char cmd = [ [ self string ] characterAtIndex:firstPos ];
					if (cmd == ';' || cmd == '{' || cmd == '}')
						break;
					else if (cmd == '\t' || cmd == ' ' || cmd == '\n')
						wasSpace = TRUE;
					else if ((cmd == '>' && wasSpace) || (cmd == '"' && wasSpace))
						break;
					firstPos--;
				}
				firstPos++;
				editRange = NSMakeRange(firstPos, cursorR.location + 1 - firstPos);
				oldEditRange = editRange;
				oldEditString = [ [ self string ] substringWithRange:editRange ];
				normalEdit = FALSE;
			}
			else
			{
				editRange = NSMakeRange(-1, 0);
				oldEditRange = NSMakeRange(-1, 0);
			}
		}
		else
		{
			NSRange cursorR = [ [ self selectedRanges ][0] rangeValue ];
			if (cursorR.location != NSNotFound)
			{
				NSRange fullPos = [ self fullLineFromIndex:cursorR fromString:[ self string ] ];
				if (fullPos.length < [ [ self string ] length ] && fullPos.location < [ [ self string ] length ] && NSMaxRange(fullPos) < [ [ self string ] length ])
				{
					editRange = NSMakeRange(fullPos.location, fullPos.length);
					oldEditRange = editRange;
					oldEditString = [ [ self string ] substringWithRange:editRange ];
					normalEdit = TRUE;
				}
				else
				{
					editRange = NSMakeRange(-1, 0);
					oldEditRange = NSMakeRange(-1, 0);
				}
			}
			else
			{
				editRange = NSMakeRange(-1, 0);
				oldEditRange = NSMakeRange(-1, 0);
			}
		}
		if (key == NSBackspaceCharacter || key == NSDeleteCharacter)
		{
			editedLength += -[ self selectedRange ].length;
			if (editedLength == 0)
				editedLength = -1;
		}
		else if (key == NSCarriageReturnCharacter || key == NSEnterCharacter || key == NSNewlineCharacter)
			editedLength += -[ self selectedRange ].length + 2;
		else
			editedLength += -[ self selectedRange ].length + [ [ theEvent characters ] length ];
		editPosition = [ self selectedRange ].location;
				
		NSRect rect = [ self visibleRect ];
		
		[ super keyDown:theEvent ];
		[ self checkMessage ];
		
		NSLayoutManager *lm = [ self layoutManager ];
		NSRange glyphRange = [ lm glyphRangeForCharacterRange:[ self selectedRange ] actualCharacterRange:NULL ];
		NSRect completionRect = [ lm boundingRectForGlyphRange:glyphRange inTextContainer:[ self textContainer ] ];
		if (NSPointInRect(completionRect.origin, rect) && (key == NSCarriageReturnCharacter || key == NSEnterCharacter || key == NSNewlineCharacter || key == NSBackspaceCharacter || key == NSDeleteCharacter))
			[ self scrollRectToVisible:rect ];
	}
	else if ([ completeView visible ] && key == '\t')
	{
		editedLength = 0;
		oldEditString = nil;
		editRange = NSMakeRange(-1, 0);
		[ completeView fillMatch:autoStart fullComplete:NO ];
		return;
	}
	else
	{
		[ completeView keyDown:theEvent ];
		return;
	}
	//[ self setNeedsDisplay:YES ];
	
	[ self findClassType ];
	
	// Line starts with #
	unsigned long long numPos = [ [ self selectedRanges ][0] rangeValue ].location - 1;
	while (numPos < [ [ self string ] length ])
	{
		if ([ [ self string ] characterAtIndex:numPos ] == '\n')
		{
			numPos++;
			break;
		}
		numPos--;
	}
	numPos = PositionAfterSpaces(numPos, [ self string ], NO);
	if (numPos < [ [ self string ] length ] && [ [ self string ] characterAtIndex:numPos ] == '#')
		[ completeView setVisible:NO ];
	
	unsigned long long numMatches = [ completeView numberOfMatches ];
	if (numMatches == 0 || (numMatches == 1 && [ [ completeView selectedItem ] isEqualToString:[ completeView trueKeyword ] ]))
		[ completeView setVisible:NO ];
	
	if (key == NSUpArrowFunctionKey || key == NSDownArrowFunctionKey || key == NSLeftArrowFunctionKey || key == NSRightArrowFunctionKey)
		return;
	
	if (key == '}')
	{
		// Find last '{' and take the indent of that
		unsigned long long cursor = [ [ self selectedRanges ][0] rangeValue ].location;
		unsigned long long z = cursor - 1;
		while (z != -1)
		{
			if ([ [ self string ] characterAtIndex:z ] == '\n')
			{
				BOOL done = FALSE;
				unsigned long long endOfLine = z;
				for (unsigned long long y = z; y < cursor - 1; y++)
				{
					if (!([ [ self string ] characterAtIndex:y ] == '\n' || [ [ self string ] characterAtIndex:y ] == '\t' || [ [ self string ] characterAtIndex:y ] == ' '))
					{
						done = TRUE;
						break;
					}
				}
				if (done)
					break;
				long long quantity = 1;
				while (z != -1)
				{
					if ([ [ self string ] characterAtIndex:z ] == '{')
						quantity--;
					else if ([ [ self string ] characterAtIndex:z ] == '}')
						quantity++;
					if ([ [ self string ] characterAtIndex:z ] == '{' && quantity == 0)
					{
						unsigned long long endPos = z;
						while (z != -1)
						{
							if ([ [ self string ] characterAtIndex:z ] == '\n')
							{
								unsigned long long startPos = z + 1;
								NSMutableString* indent = [ [ NSMutableString alloc ] initWithString:[ [ self string ] substringWithRange:NSMakeRange(startPos, endPos - startPos) ] ];
								for (unsigned long long q = 0; q < [ indent length ]; q++)
								{
									if ([ indent characterAtIndex:q ] != '\n' && [ indent characterAtIndex:q ] != '\t' && [ indent characterAtIndex:q ] != ' ')
									{
										[ indent deleteCharactersInRange:NSMakeRange(q, 1) ];
										q--;
									}
								}
								unsigned long long difference = (cursor - endOfLine - 2) - [ indent length ];
								NSMutableString* newString = [ [ NSMutableString alloc ] initWithString:[ self string ] ];
								[ newString replaceCharactersInRange:NSMakeRange(endOfLine + 1, cursor - endOfLine - 2) withString:indent ];
								[ self setString:newString ];
								[ self setSelectedRange:NSMakeRange(cursor - difference, 0) affinity:NSSelectionAffinityDownstream stillSelecting:NO ];
								done = TRUE;
								break;
							}
							z--;
						}
						if (done)
							break;
					}
					z--;
				}
				if (done)
					break;
			}
			z--;
		}
	}
	else if (key == '{')
	{
		// Find last '\n'
		unsigned long long cursor = [ [ self selectedRanges ][0] rangeValue ].location;
		unsigned long long z = cursor - 1;
		while (z != -1)
		{
			if ([ [ self string ] characterAtIndex:z ] == '\n' || z == 0)
			{
				BOOL done = FALSE;
				unsigned long long endOfLine = z;
				for (unsigned long long y = z; y < cursor - 1; y++)
				{
					if (!([ [ self string ] characterAtIndex:y ] == '\n' || [ [ self string ] characterAtIndex:y ] == '\t' || [ [ self string ] characterAtIndex:y ] == ' '))
					{
						done = TRUE;
						break;
					}
				}
				if (done)
					break;
				z--;
				long long quantity = 1;
				while (z != -1)
				{
					if ([ [ self string ] characterAtIndex:z ] == '}')
						quantity++;
					else if ([ [ self string ] characterAtIndex:z ] == '{')
						quantity--;
					if (([ [ self string ] characterAtIndex:z ] == '{' && quantity == 0)|| z == 0)
					{
						unsigned long long startOfLine = z;
						while (z != -1)
						{
							if ([ [ self string ] characterAtIndex:z ] == '\n' || z == 0)
							{
								NSMutableString* indent = [ [ NSMutableString alloc ] initWithString:[ [ self string ] substringWithRange:NSMakeRange(z + 1, startOfLine - z - 1) ] ];
								for (unsigned long long q = 0; q < [ indent length ]; q++)
								{
									if ([ indent characterAtIndex:q ] != '\n' && [ indent characterAtIndex:q ] != '\t' && [ indent characterAtIndex:q ] != ' ')
									{
										[ indent deleteCharactersInRange:NSMakeRange(q, 1) ];
										q--;
									}
								}
								[ indent appendString:@"\t" ];
								unsigned long long difference = (cursor - endOfLine - 2) - [ indent length ];
								NSMutableString* newString = [ [ NSMutableString alloc ] initWithString:[ self string ] ];
								[ newString replaceCharactersInRange:NSMakeRange(endOfLine + 1, cursor - endOfLine - 2) withString:indent ];
								[ self setString:newString ];
								[ self setSelectedRange:NSMakeRange(cursor - difference, 0) affinity:NSSelectionAffinityDownstream stillSelecting:NO ];
								done = TRUE;
								break;
							}
							z--;
						}
						if (done)
							break;
					}
					z--;
				}
				if (done)
					break;
			}
			z--;
		}
	}
	else if (key == '>' || key == '"')
	{
		// Update new documents that are imported
		// This doesn't unload the documents when you unadd them or account for changes when the > or " isn't changed
		
		// Check if its #import / #include
		unsigned long long numPos = [ [ self selectedRanges ][0] rangeValue ].location - 1;
		while (numPos != NSNotFound)
		{
			if ([ [ self string ] characterAtIndex:numPos ] == '\n')
			{
				numPos++;
				break;
			}
			numPos--;
		}
		numPos = PositionAfterSpaces(numPos, [ self string ], NO);
		if ([ [ [ self string ] substringWithRange:NSMakeRange(numPos, 7) ] isEqualToString:@"#import" ] || [ [ [ self string ] substringWithRange:NSMakeRange(numPos, 8) ] isEqualToString:@"#include" ])
		{
			if ([ [ self string ] characterAtIndex:numPos ] == '#')
				[ completeView setVisible:NO ];
			
			NSMutableArray* backup = [ [ NSMutableArray alloc ] initWithArray:classNames ];
			[ classNames removeAllObjects ];
			
			NSMutableString* path = [ NSMutableString string ];
			unsigned long long pos =  [ [ self selectedRanges ][0] rangeValue ].location - 2;
			while (pos > 0)
			{
				if ([ [ self string ] characterAtIndex:pos ] == '<')
					break;
				[ path insertString:[ NSString stringWithFormat:@"%c", [ [ self string ] characterAtIndex:pos ] ] atIndex:0 ];
				pos--;
			}
			
			BOOL isFile = TRUE;
			NSString* framework = @"";
			NSString* rest = @"";
			if ([ path rangeOfString:@"/" ].location != NSNotFound)
			{
				framework = [ path substringToIndex:[ path rangeOfString:@"/" ].location ];
				rest = [ path substringFromIndex:[ path rangeOfString:@"/" ].location + 1 ];
			}
			NSMutableString* realPath = [ NSMutableString stringWithFormat:@"/Developer/SDKs/MacOSX10.7.sdk/System/Library/Frameworks/%@.framework/Headers/%@", framework, rest ];
			if (![ [ NSFileManager defaultManager ] fileExistsAtPath:realPath ])
			{
				[ realPath setString:[ NSString stringWithFormat:@"/System/Library/Frameworks/%@.framework/Headers/%@", framework, rest ] ];
				if (![ [ NSFileManager defaultManager ] fileExistsAtPath:realPath ])
				{
					[ realPath setString:[ NSString stringWithFormat:@"/Developer/SDKs/MacOSX10.7.sdk/usr/include/%@", path ] ];
					if (![ [ NSFileManager defaultManager ] fileExistsAtPath:realPath ])
					{
						[ realPath setString:[ NSString stringWithFormat:@"/Developer/SDKs/MacOSX10.7.sdk/usr/include/c++/4.2.1/%@", path ] ];
						if (![ [ NSFileManager defaultManager ] fileExistsAtPath:realPath ])
							isFile = FALSE;
					}
				}
			}
			
			if (isFile)
			{
				[ self interpretFile:[ [ NSString alloc ] initWithData:[ [ NSFileManager defaultManager ] contentsAtPath:realPath ] encoding:NSASCIIStringEncoding ] fromName:realPath removing:NO ];
				
				for (unsigned long long z = 0; z < [ classNames count ]; z++)
					[ completeView addVariable:classNames[z] ];
			}
			
			[ classNames addObjectsFromArray:backup ];
			
			[ self processHighlight:NSMakeRange(0, [ [ self string ] length ]) ];
		}
	}
	
	if (!(key == NSNewlineCharacter || key == NSEnterCharacter || key == NSCarriageReturnCharacter))
		return;
	
	// Get line number
	
	// Move breakpoints
	unsigned long long cursorPosition = [ [ self selectedRanges ][0] rangeValue ].location;
	for (unsigned long z = 0; z < lineRanges.size(); z++)
	{
		if (cursorPosition >= lineRanges[z].location && cursorPosition <= NSMaxRange(lineRanges[z]))
		{
			// Add 1 line to all errors higher than this
			for (int y = 0; y < breakpoints.size(); y++)
			{
				if (breakpoints[y] >= z)
					breakpoints[y]++;
			}
			break;
		}
	}
	
	// Check if last was "if", "for", "while", "do"
	unsigned long long cursor = [ [ self selectedRanges ][0] rangeValue ].location;
	// Find last '\n'
	unsigned long long z = cursor - 2;
	BOOL foundIf = FALSE;
	while (z != -1)
	{
		if ([ [ self string ] characterAtIndex:z ] == '\n' || [ [ self string ] characterAtIndex:z ] == ';')
		{
			BOOL isLine = [ [ self string ] characterAtIndex:z ] == ';';
			z++;
			
			BOOL shouldLeave = FALSE;
			while ([ [ self string ] characterAtIndex:z ] == ' ' || [ [ self string ] characterAtIndex:z ] == '\t' || [ [ self string ] characterAtIndex:z ] == '\n')
			{
				z++;
				if (z >= [ [ self string ] length ])
				{
					shouldLeave = TRUE;
					break;
				}
			}
			if (shouldLeave)
				break;
			
			if (z >= cursor)
				break;
			NSMutableString* realString = [ NSMutableString stringWithString:[ [ self string ] substringWithRange:NSMakeRange(z, cursor - z) ] ];
			[ realString replaceOccurrencesOfString:@" " withString:@"" options:0 range:NSMakeRange(0, [ realString length ]) ];
			[ realString replaceOccurrencesOfString:@"\n" withString:@"" options:0 range:NSMakeRange(0, [ realString length ]) ];
			[ realString replaceOccurrencesOfString:@"\t" withString:@"" options:0 range:NSMakeRange(0, [ realString length ]) ];
			if ([ realString hasPrefix:@"if(" ] || [ realString hasPrefix:@"for(" ] || [ realString hasPrefix:@"while(" ] || [ realString hasPrefix:@"do" ])
			{
				if ([ realString hasPrefix:@"do" ])
				{
					// Check next letter
					BOOL foundChar = FALSE;
					for (int q = 0; q < sizeof(posschar); q++)
					{
						if ([ realString characterAtIndex:3 ] == posschar[q])
							foundChar = TRUE;
					}
					if (!foundChar)
						break;
				}
				// Find how indented it is
				z--;
				if (isLine)
				{
					while (z != -1)
					{
						if ([ [ self string ] characterAtIndex:z ] == '\n')
							break;
						z--;
					}
					z++;
					while ([ [ self string ] characterAtIndex:z ] == ' ' || [ [ self string ] characterAtIndex:z ] == '\t' || [ [ self string ] characterAtIndex:z ] == '\n') { z++; }
					z--;
				}
				unsigned int count = 1;
				unsigned int count2 = 0;
				unsigned long long prevZ = z;
				while ([ [ self string ] characterAtIndex:z-- ] == '\t')
					count++;
				z = prevZ;
				while ([ [ self string ] characterAtIndex:z-- ] == ' ')
					count2++;
				NSMutableString* newString = [ [ NSMutableString alloc ] init ];
				for (int q = 0; q < count; q++)
					[ newString appendString:@"\t" ];
				for (int q = 0; q < count2; q++)
					[ newString appendString:@" " ];
				[ [ self textStorage ] replaceCharactersInRange:NSMakeRange(cursor, 0) withString:newString ];
				[ self setSelectedRange:NSMakeRange(cursor + count, 0) affinity:NSSelectionAffinityDownstream stillSelecting:NO ];
				foundIf = TRUE;
			}
			break;
		}
		z--;
	}
	
	if (!foundIf)
	{
		// Find last '{'
		z = cursor - 1;
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
				NSMutableString* newString = [ [ NSMutableString alloc ] init ];
				for (int q = 0; q < count; q++)
					[ newString appendString:@"\t" ];
				for (int q = 0; q < count2; q++)
					[ newString appendString:@" " ];
				[ [ self textStorage ] replaceCharactersInRange:NSMakeRange(cursor, 0) withString:newString ];
				[ self setSelectedRange:NSMakeRange(cursor + count, 0) affinity:NSSelectionAffinityDownstream stillSelecting:NO ];
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
	}
	
	// Update errors
	cursorPosition = [ [ self selectedRanges ][0] rangeValue ].location;
	for (unsigned long z = 0; z < lineRanges.size(); z++)
	{
		if (cursorPosition >= lineRanges[z].location && cursorPosition <= NSMaxRange(lineRanges[z]))
		{
			// Add 1 line to all errors higher than this
			for (int y = 0; y < errors.size(); y++)
			{
				if (errors[y].line >= z)
					errors[y].line++;
			}
			break;
		}
	}
}

- (NSString*) wordFromIndex: (unsigned long long) index fromString:(NSString*)str
{
	NSMutableString* string = [ NSMutableString string ];
	for (unsigned long long z = index; z < [ str length ]; z++)
	{
		BOOL isFound = FALSE;
		for (int y = 0; y < sizeof(posschar); y++)
		{
			if ([ str characterAtIndex:z ] == posschar[y])
			{
				isFound = TRUE;
				break;
			}
		}
		if (isFound)
			break;
		[ string appendFormat:@"%c", [ str characterAtIndex:z ] ];
	}
	return string;
}

- (NSString*) lineFromIndex: (unsigned long long) index usingString:(NSString*)totalString
{
	NSMutableString* string = [ NSMutableString string ];
	BOOL inComment = FALSE;
	BOOL commentType = FALSE;
	for (unsigned long long z = index; z < [ totalString length ]; z++)
	{
		if (z + 1 < [ totalString length ] && [ totalString characterAtIndex:z ] == '/' && [ totalString characterAtIndex:z + 1 ] == '/')
		{
			inComment = TRUE;
			commentType = TRUE;
		}
		else if (z + 1 < [ totalString length ] && [ totalString characterAtIndex:z ] == '/' && [ totalString characterAtIndex:z + 1 ] == '*')
		{
			inComment = TRUE;
			commentType = FALSE;
		}
		
		[ string appendFormat:@"%c", [ totalString characterAtIndex:z ] ];
		if (!inComment)
		{
			if ([ totalString characterAtIndex:z ] == ';')
				break;
			else if ([ totalString characterAtIndex:z ] == '{')
				break;
			else if ([ totalString characterAtIndex:z ] == '}')
				break;
		}
		else
		{
			if (commentType && [ totalString characterAtIndex:z ] == '\n')
				inComment = FALSE;
			else if (!commentType && z + 1 < [ totalString length ] && [ totalString characterAtIndex:z ] == '*' && [ totalString characterAtIndex:z + 1 ] == '/')
				inComment = FALSE;
		}
		
		//if (z == [ totalString length ] - 1)
		//	return @"";
	}
	return string;
}

unsigned long long PositionAfterSpaces(unsigned long long index, NSString* string, BOOL any)
{
	unsigned long long z = index;
	while (z < [ string length ])
	{
		if (!any)
		{
			if ([ string characterAtIndex:z ] != ' ' && [ string characterAtIndex:z ] != '\n' && [ string characterAtIndex:z ] != '\t')
				break;
		}
		else
		{
			BOOL found = FALSE;
			for (int y = 0; y < sizeof(posschar); y++)
			{
				if ([ string characterAtIndex:z ] == posschar[y])
				{
					found = TRUE;
					break;
				}
			}
			if (!found)
				break;
		}
		z++;
	}
	return z;
}

unsigned long long PositionAfterSpacesAndComments(unsigned long long index, NSString* string, BOOL any)
{
	unsigned long long z = index;
	BOOL inComment = FALSE;
	BOOL commentType = TRUE;
	while (z < [ string length ])
	{
		if (z + 1 < [ string length ] && [ string characterAtIndex:z ] == '/' && [ string characterAtIndex:z + 1 ] == '/')
		{
			inComment = TRUE;
			commentType = TRUE;
		}
		else if (z + 1 < [ string length ] && [ string characterAtIndex:z ] == '/' && [ string characterAtIndex:z + 1 ] == '*')
		{
			inComment = TRUE;
			commentType = FALSE;
		}
		
		if (!any && !inComment)
		{
			if ([ string characterAtIndex:z ] != ' ' && [ string characterAtIndex:z ] != '\n' && [ string characterAtIndex:z ] != '\t')
				break;
		}
		else if (!inComment)
		{
			BOOL found = FALSE;
			for (int y = 0; y < sizeof(posschar); y++)
			{
				if ([ string characterAtIndex:z ] == posschar[y])
				{
					found = TRUE;
					break;
				}
			}
			if (!found)
				break;
		}
		
		if (inComment && commentType && [ string characterAtIndex:z ] == '\n')
			inComment = FALSE;
		else if (inComment && !commentType && z + 1 < [ string length ] && [ string characterAtIndex:z ] == '*' && [ string characterAtIndex:z + 1 ] == '/')
			inComment = FALSE;
		
		z++;
	}
	return z;
}

unsigned long long PositionBeforeSpaces(unsigned long long index, NSString* string, BOOL any)
{
	unsigned long long z = index;
	while (z != (unsigned long long)-1)
	{
		if (!any)
		{
			if ([ string characterAtIndex:z ] != ' ' && [ string characterAtIndex:z ] != '\n' && [ string characterAtIndex:z ] != '\t')
				break;
		}
		else
		{
			BOOL found = FALSE;
			for (int y = 0; y < sizeof(posschar); y++)
			{
				if ([ string characterAtIndex:z ] == posschar[y])
				{
					found = TRUE;
					break;
				}
			}
			if (!found)
				break;
		}
		z--;
	}
	return z;
}

void ReleaseVariable(CodeVariable var);
void ReleaseVariable(CodeVariable var)
{
}

- (CodeVariable) createVariable:(NSString*) name withType:(NSString*) type fromIndex:(unsigned long long) index
{
	CodeVariable var;
	memset(&var, 0, sizeof(var));
	var.name = [ [ NSString alloc ] initWithString:name ];
	var.type = @"#define";
	unsigned long long lineNumber = 0;
	for (unsigned long z = 0; z < lineRanges.size(); z++)
	{
		if (index <= lineRanges[z].location && index <= NSMaxRange(lineRanges[z]))
		{
			lineNumber = z;
			break;
		}
	}
	var.line = lineNumber;
	return var;
}

//char* functionTypes[] = { "void", "char", "short", "int", "long", };

- (void) interpretFile: (NSString*)file fromName:(NSString*)filename removing:(BOOL)remove
{
	if ([ loadingThread isCancelled ])
	{
		loading = FALSE;
		depthIn = 0;
		[ NSThread exit ];
		return;
	}
	
	loading = TRUE;
	depthIn++;
	
	@autoreleasepool {
		NSMutableArray* varCopy = [ [ completeView variables ] copy ];
		
		//if (!remove)
		//{
			NSRange importRanges = NSMakeRange(0, 0);
			BOOL imports = TRUE;
			for (;;)
			{
				if (imports)
				{
					importRanges = [ file rangeOfString:@"#import" options:0 range:NSMakeRange(NSMaxRange(importRanges), [ file length ] - NSMaxRange(importRanges)) ];
				}
				else
				{
					importRanges = [ file rangeOfString:@"#include" options:0 range:NSMakeRange(NSMaxRange(importRanges), [ file length ] - NSMaxRange(importRanges)) ];
				}
				
				if (importRanges.length == 0 && imports)
				{
					imports = FALSE;
					importRanges = NSMakeRange(0, 0);
					continue;
				}
				else if (importRanges.length == 0)
					break;
				
				unsigned long z = PositionAfterSpaces(NSMaxRange(importRanges), file, NO);
				BOOL usesQuotes = ([ file characterAtIndex:z ] == '"');
				z++;
				NSMutableString* document = [ NSMutableString string ];
				BOOL add = TRUE;
				while (z < [ file length ])
				{
					if (([ file characterAtIndex:z ] == '>' && !usesQuotes) || ([ file characterAtIndex:z ] == '"' && usesQuotes))
					{
						if ([ file characterAtIndex:z ] == '>')
						{
							NSString* prev = [ NSString stringWithString:document ];
							NSRange docRange = [ document rangeOfString:@"/" ];
							NSString* framework = nil;
							NSString* rest = nil;
							if (docRange.length != 0)
							{
								framework = [ document substringToIndex:docRange.location ];
								rest = [ document substringFromIndex:NSMaxRange(docRange) ];
								[ document setString:[ NSString stringWithFormat:@"/Developer/SDKs/MacOSX10.7.sdk/System/Library/Frameworks/%@.framework/Headers/%@", framework, rest ] ];
							}
							else
								[ document setString:@"." ];
							if (![ [ NSFileManager defaultManager ] fileExistsAtPath:document ])
							{
								if (docRange.length != 0)
								{
									[ document setString:[ NSString stringWithFormat:@"/System/Library/Frameworks/%@.framework/Headers/%@", framework, rest ] ];
								}
								if (![ [ NSFileManager defaultManager ] fileExistsAtPath:document ])
								{
									[ document setString:[ NSString stringWithFormat:@"/Developer/SDKs/MacOSX10.7.sdk/usr/include/%@", prev ] ];
									if (![ [ NSFileManager defaultManager ] fileExistsAtPath:document ])
									{
										[ document setString:[ NSString stringWithFormat:@"/Developer/SDKs/MacOSX10.7.sdk/usr/include/c++/4.2.1/%@", prev ] ];
										if (![ [ NSFileManager defaultManager ] fileExistsAtPath:document ])
										{
											[ document setString:[ NSString stringWithFormat:@"%@/Headers/%@", [ [ NSBundle mainBundle ] resourcePath ], prev ] ];
											if (![ [ NSFileManager defaultManager ] fileExistsAtPath:document ])
											{
												add = FALSE;
												break;
											}
										}
									}
								}
							}
						}
						else
						{
							if ([ filename length ] == 0)
							{
								add = FALSE;
								break;
							}
							NSString* prevDoc = [ NSString stringWithString:document ];
							[ document setString:[ NSString stringWithFormat:@"%@/%@", [ filename stringByDeletingLastPathComponent ], document ] ];
							if (![ [ NSFileManager defaultManager ] fileExistsAtPath:document ])
							{
								[ document setString:[ NSString stringWithFormat:@"/Developer/SDKs/MacOSX10.7.sdk/usr/include/%@", prevDoc ] ];
								if (![ [ NSFileManager defaultManager ] fileExistsAtPath:document ])
								{
									[ document setString:[ NSString stringWithFormat:@"/Developer/SDKs/MacOSX10.7.sdk/usr/include/c++/4.2.1/%@", prevDoc ] ];
									if (![ [ NSFileManager defaultManager ] fileExistsAtPath:document ])
									{
										add = FALSE;
										break;
									}
								}
							}
						}
						break;
					}
					[ document appendFormat:@"%c", [ file characterAtIndex:z ] ];
					z++;
				}
				if (add)
				{
					if (![ included containsObject:document ])
					{
						[ included addObject:document ];
						//NSLog(@"%@", document);
						
						NSFileHandle* handle = [ NSFileHandle fileHandleForReadingAtPath:document ];
						
						NSMutableString* data = [ [ NSMutableString alloc ] initWithData:[ handle readDataToEndOfFile ] encoding:NSASCIIStringEncoding ];
						// Remove all comments
						NSRange commentRange = NSMakeRange(0, 0);
						do
						{
							commentRange = [ data rangeOfString:@"/*" options:0 range:NSMakeRange(NSMaxRange(commentRange), [ data length ] - NSMaxRange(commentRange)) ];
							if (commentRange.length == 0)
								break;
							// Find */
							NSRange prevRange = commentRange;
							commentRange = [ data rangeOfString:@"*/" options:0 range:NSMakeRange(NSMaxRange(commentRange), [ data length ] - NSMaxRange(commentRange)) ];
							[ data deleteCharactersInRange:NSMakeRange(prevRange.location, NSMaxRange(commentRange) - prevRange.location) ];
							commentRange.location = prevRange.location;
							commentRange.length = 0;
						}
						while (commentRange.location != NSNotFound);
						commentRange = NSMakeRange(0, 0);
						do
						{
							commentRange = [ data rangeOfString:@"//" options:0 range:NSMakeRange(NSMaxRange(commentRange), [ data length ] - NSMaxRange(commentRange)) ];
							if (commentRange.length == 0)
								break;
							// Find */
							NSRange prevRange = commentRange;
							commentRange = [ data rangeOfString:@"\n" options:0 range:NSMakeRange(NSMaxRange(commentRange), [ data length ] - NSMaxRange(commentRange)) ];
							[ data deleteCharactersInRange:NSMakeRange(prevRange.location, NSMaxRange(commentRange) - prevRange.location) ];
							commentRange.location = prevRange.location;
							commentRange.length = 0;
						}
						while (commentRange.location != NSNotFound);
						[ self interpretFile:data fromName:document removing:remove ];
					}
				}
			}
		//}
		
		// Defines
		NSMutableArray* defines = [ [ NSMutableArray alloc ] init ];
		
		NSRange defineRange = NSMakeRange(0, 0);
		do
		{
			defineRange = [ file rangeOfString:@"#define" options:0 range:NSMakeRange(NSMaxRange(defineRange), [ file length ] - NSMaxRange(defineRange)) ];
			if (defineRange.length == 0 || NSMaxRange(defineRange) >= [ file length ] - 1)
				break;
			
			unsigned long long pos = PositionAfterSpaces(NSMaxRange(defineRange), file, NO);
			NSString* defineName = WordFromIndex(pos, file);
			pos = PositionAfterSpaces(pos, file, YES);
			unsigned long long quantity = 0;
			if ([ file characterAtIndex:pos ] == '(')
			{
				quantity++;
				while (pos < [ file length ])
				{
					if ([ file characterAtIndex:pos ] == ')')
					{
						quantity--;
						if (quantity == 0)
						{
							pos++;
							break;
						}
					}
					else if ([ file characterAtIndex:pos ] == '(')
						quantity++;
					pos++;
				}
			}
			
			pos = PositionAfterSpaces(pos, file, YES);
			unsigned long long initialPos = pos;
			char lastChar = 0;
			while (pos < [ file length ])
			{
				if ([ file characterAtIndex:pos ] == '\n')
				{
					if (lastChar != '\\')
					{
						break;
					}
				}
				lastChar = [ file characterAtIndex:pos ];
				pos++;
			}
			NSMutableString* defineDef = [ NSMutableString stringWithString:[ file substringWithRange:NSMakeRange(initialPos, pos - initialPos) ] ];
			[ defineDef replaceOccurrencesOfString:@"\\\n" withString:@"\t" options:0 range:NSMakeRange(0, [ defineDef length ]) ];
			defineRange = NSMakeRange(pos - 1, 1);
			
			//NSLog(@"%@, %@", defineName, defineDef);
			
			NSMutableDictionary* dict = [ NSMutableDictionary dictionaryWithObjects:@[defineName, defineDef] forKeys:@[@"Name", @"Defintion"] ];
			[ defines addObject:dict ];
			if (remove)
			{
				if ([ varCopy containsObject:defineName ])
				{
					if ([ self isEditable ])
						[ [ completeView variables ] removeObject:defineName ];
					for (unsigned long z = 0; z < globalVariables.size(); z++)
					{
						if ([ globalVariables[z].name isEqualToString:defineName ])
						{
							ReleaseVariable(globalVariables[z]);
							globalVariables.erase(globalVariables.begin() + z);
						}
					}
				}
			}
			else
			{
				// The editable stuff is a speedup
				if (![ varCopy containsObject:defineName ])
				{
					if ([ self isEditable ])
						[ completeView addVariable:defineName ];
					CodeVariable var = [ self createVariable:defineName withType:@"#define" fromIndex:pos ];
					globalVariables.push_back(var);
				}
			}
		}
		while (defineRange.length != 0);
		
		NSMutableArray* classCopy = [ classNames copy ];
		
		// Search for every class
		NSRange classRanges = NSMakeRange(0, 0);
		do
		{
			classRanges =  [ file rangeOfString:@"@interface" options:0 range:NSMakeRange(NSMaxRange(classRanges), [ file length ] - NSMaxRange(classRanges)) ];
			if (classRanges.length == 0 || NSMaxRange(classRanges) >= [ file length ] - 1)
				break;
			// Make sure next letter is one that we like
			char nextLetter = [ file characterAtIndex:NSMaxRange(classRanges) ];
			BOOL does = FALSE;
			for (int z = 0; z < sizeof(posschar); z++)
			{
				if (posschar[z] == nextLetter)
				{
					does = TRUE;
					break;
				}
			}
			if (!does)
				continue;
			unsigned long long pos = PositionAfterSpaces(NSMaxRange(classRanges), file, YES);
			NSMutableString* className = [ [ NSMutableString alloc ] init ];
			while (pos < [ file length ])
			{
				BOOL end = FALSE;
				for (int z = 0; z < sizeof(posschar); z++)
				{
					if (posschar[z] == [ file characterAtIndex:pos ])
					{
						end = TRUE;
						break;
					}
				}
				if (end)
					break;
				
				[ className appendFormat:@"%c", [ file characterAtIndex:pos ] ];
				pos++;
			}
			
			if ([ className length ] == 0)
				continue;
			
			if (remove)
			{
				if ([ classCopy containsObject:className ])
				{
					unsigned long long index = [ classNames indexOfObject:className ];
					[ classNames removeObject:className ];
					[ classData removeObjectAtIndex:index ];
					[ [ completeView variables ] removeObject:className ];
				}
			}
			else
			{
				if (![ classCopy containsObject:className ])
				{
					[ classNames addObject:className ];
					
					NSMutableDictionary* dict = [ NSMutableDictionary dictionaryWithObjects:@[className, [ NSMutableArray arrayWithObject:filename ], @"ObjC-Class"] forKeys:@[@"Name", @"Documents", @"Type"] ];
					[ classData addObject:dict ];
					
					[ completeView addVariable:className ];
					//NSLog(@"%@", className);
				}
				else
				{
					if ([ classData[[ classNames indexOfObject:className ]][@"Type"] isEqualToString:@"@class" ])
					{
						NSMutableDictionary* dict = [ NSMutableDictionary dictionaryWithObjects:@[className, [ NSMutableArray arrayWithObject:filename ], @"ObjC-Class"] forKeys:@[@"Name", @"Documents", @"Type"] ];
						classData[[ classNames indexOfObject:className ]] = dict;
					}
					else
					{
						NSMutableDictionary* dict = classData[[ classNames indexOfObject:className ]];
						NSMutableArray* array = dict[@"Documents"];
						if (![ array containsObject:filename ])
							[ array addObject:filename ];
					}
				}
			}
		}
		while (classRanges.length != 0);
		
		// Search for @class's but have them replaced later
		classRanges = NSMakeRange(0, 0);
		do
		{
			classRanges =  [ file rangeOfString:@"@class" options:0 range:NSMakeRange(NSMaxRange(classRanges), [ file length ] - NSMaxRange(classRanges)) ];
			unsigned long long pos = NSMaxRange(classRanges);
			// Find next ';'
			while (pos < [ file length ])
			{
				if ([ file characterAtIndex:pos ] == ';')
					break;
				pos++;
			}
			unsigned long long donePosition = pos;
			pos = NSMaxRange(classRanges);
			do
			{
				pos = PositionAfterSpaces(pos, file, NO);
				NSString* newClass = WordFromIndex(pos, file);
				pos += [ newClass length ];
				
				if (remove)
				{
					if ([ classCopy containsObject:newClass ])
					{
						unsigned long long index = [ classNames indexOfObject:newClass ];
						[ classNames removeObject:newClass ];
						[ classData removeObjectAtIndex:index ];
						[ [ completeView variables ] removeObject:newClass ];
					}
				}
				else
				{
					if (![ classCopy containsObject:newClass ])
					{
						NSMutableDictionary* dict = [ NSMutableDictionary dictionaryWithObjects:@[newClass, [ NSMutableArray arrayWithObject:filename ], @"@class"] forKeys:@[@"Name", @"Documents", @"Type"] ];
						[ classData addObject:dict ];
						[ classNames addObject:newClass ];
						[ completeView addVariable:newClass ];
					}
				}
				
				pos = PositionAfterSpaces(pos, file, YES);
				if (pos >= donePosition)
					break;
			}
			while (pos < [ file length ]);
		}
		while (classRanges.length != 0);
		
		// Search for structs
		NSRange structRanges = NSMakeRange(0, 0);
		do
		{
			structRanges = [ file rangeOfString:@"struct" options:0 range:NSMakeRange(NSMaxRange(structRanges), [ file length ] - NSMaxRange(structRanges)) ];
			if (structRanges.length == 0 || NSMaxRange(structRanges) >= [ file length ] - 1)
				break;
			
			unsigned long pos = PositionAfterSpaces(NSMaxRange(structRanges), file, NO);
			if (pos == NSMaxRange(structRanges))
				continue;
			NSString* name = [ self wordFromIndex:pos fromString:file ];
			
			if ([ name length ] == 0)
			{
				// Check word before struct to see if typedef
				pos = PositionBeforeSpaces(structRanges.location - 1, file, NO);
				while (pos != NSUIntegerMax)
				{
					char cmd = [ file characterAtIndex:pos ];
					if (cmd == ' ' || cmd == '\n' || cmd == '\t')
						break;
					pos--;
				}
				NSString* isTypedef = [ self wordFromIndex:pos + 1 fromString:file ];
				if ([ isTypedef isEqualToString:@"typedef" ])
				{
					unsigned int quantity = 0;
					pos = NSMaxRange(structRanges);
					while (pos < [ file length ])
					{
						char cmd = [ file characterAtIndex:pos++ ];
						if (cmd == '{')
							quantity++;
						else if (cmd == '}')
						{
							quantity--;
							if (quantity == 0)
								break;
						}
					}
					if (pos == [ file length ])
						continue;
					name = [ self wordFromIndex:PositionAfterSpaces(pos, file, NO) fromString:file ];
					if ([ name length ] == 0)
						continue;
				}
				else
					continue;
			}
			
			NSMutableDictionary* dict = [ NSMutableDictionary dictionaryWithObjects:@[name, [ NSMutableArray arrayWithObject:filename ], @"Struct"] forKeys:@[@"Name", @"Documents", @"Type"] ];
			
			if (remove)
			{
				if ([ classCopy containsObject:name ])
				{
					unsigned long long index = [ classNames indexOfObject:name ];
					[ classNames removeObject:name ];
					[ classData removeObjectAtIndex:index ];
					[ [ completeView variables ] removeObject:name ];
				}
			}
			else
			{
				if (![ classCopy containsObject:name ])
				{
					[ classData addObject:dict ];
					[ classNames addObject:name ];
					[ completeView addVariable:name ];
				}
			}
		}
		while (structRanges.length != 0);
			
		// Typedefs
		NSRange typeRanges = NSMakeRange(0, 0);
		do
		{
			typeRanges = [ file rangeOfString:@"typedef" options:0 range:NSMakeRange(NSMaxRange(typeRanges), [ file length ] - NSMaxRange(typeRanges)) ];
			if (typeRanges.length == 0 || NSMaxRange(typeRanges) >= [ file length ] - 1)
				break;
			unsigned long long pos = NSMaxRange(typeRanges);
			pos = PositionAfterSpaces(pos, file, YES);
			NSString* oldType = WordFromIndex(pos, file);
			// Already taken care of
			unsigned long long prevPos = pos;
			while ([ oldType isEqualToString:@"const" ])
			{
				pos += [ oldType length ];
				pos = PositionAfterSpaces(pos, file, YES);
				oldType = WordFromIndex(pos, file);
			}
			if ([ oldType isEqualToString:@"struct" ] || [ oldType isEqualToString:@"enum" ] || [ oldType isEqualToString:@"union" ])
				continue;
			pos = prevPos;
			unsigned long endOfLine = [ file rangeOfString:@";" options:0 range:NSMakeRange(NSMaxRange(typeRanges), [ file length ] - NSMaxRange(typeRanges)) ].location;
			NSMutableString* type = [ [ NSMutableString alloc ] init ];
			NSString* lineString = [ file substringWithRange:NSMakeRange(NSMaxRange(typeRanges), endOfLine - NSMaxRange(typeRanges)) ];
			//pos += PositionAfterSpaces(0, lineString, YES);
			pos += CheckType(lineString, PositionAfterSpaces(0, lineString, YES), type, classCopy, language);
			NSString* name = WordFromIndex(pos, file);
			pos += [ name length ];

			/*if ([ type length ] == 0)
			{
				NSLog(@"%@ - %@, %@", [ file substringWithRange:NSMakeRange(NSMaxRange(typeRanges), endOfLine - NSMaxRange(typeRanges)) ], type, name);
			}*/
			
			if (remove)
			{
				if ([ name length ] == 0)
					continue;
				unsigned long long index = [ classNames indexOfObject:name ];
				[ classNames removeObject:name ];
				[ classData removeObjectAtIndex:index ];
				[ [ completeView variables ] removeObject:name ];
			}
			else
			{
				if ([ name length ] == 0 || [ classCopy containsObject:name ])
					continue;
				[ classNames addObject:name ];
				NSMutableDictionary* dict = [ NSMutableDictionary dictionaryWithObjects:@[name, [ NSMutableArray arrayWithObject:filename ], @"Typedef", type] forKeys:@[@"Name", @"Documents", @"Type", @"Old Name"] ];
				[ classData addObject:dict ];
				[ completeView addVariable:name ];
			}
		}
		while (typeRanges.length != 0);
		
		// Check for functions
		NSRange functionRanges = NSMakeRange(0, 0);
		do
		{
			functionRanges = [ file rangeOfString:@"(" options:0 range:NSMakeRange(NSMaxRange(functionRanges), [ file length ] - NSMaxRange(functionRanges)) ];
			BOOL doneWell = FALSE;
			unsigned long long pos = functionRanges.location;
			if (functionRanges.location == NSNotFound)
				break;
			unsigned long long z = pos - 1;
			while (z != (unsigned long long)-1)
			{
				BOOL found = FALSE;
				for (int y = 0; y < sizeof(posschar); y++)
				{
					char realCMD = [ file characterAtIndex:z ];
					if (realCMD == ' ' || realCMD == '\n' || realCMD == '\t')
						break;
					if (realCMD == posschar[y])
					{
						doneWell = TRUE;
						break;
					}
					found = TRUE;
				}
				if (found)
					break;
				z--;
			}
			if (doneWell)
				continue;
			pos = z;
			NSMutableString* funcName = [ [ NSMutableString alloc ] init ];
			while (z != (unsigned long long)-1)
			{
				BOOL found = FALSE;
				char cmd = [  file characterAtIndex:z ];
				for (int y = 0; y < sizeof(posschar); y++)
				{
					if (cmd == posschar[y])
					{
						found = TRUE;
						break;
					}
				}
				if (found)
					break;
				[ funcName insertString:[ NSString stringWithFormat:@"%c", cmd ] atIndex:0 ];
				z--;
			}
			
			unsigned long long prevPos = pos + 1;
			// Find args
			NSMutableString* args = [ [ NSMutableString alloc ] init ];
			int quantityA = 0;
			prevPos = PositionAfterSpaces(prevPos, file, NO);
			while (prevPos < [ file length ])
			{
				char cmd = [ file characterAtIndex:prevPos ];
				[ args appendFormat:@"%c", cmd ];
				if (cmd == '(')
					quantityA++;
				else if (cmd == ')')
				{
					quantityA--;
					if (quantityA == 0)
						break;
				}
				prevPos++;
			}
			
			//NSLog(@"%@", funcName);
			NSMutableString* funcType = [ [ NSMutableString alloc ] init ];
			BOOL cancel = FALSE;
			for (;;)
			{
				while (z != (unsigned long long)-1)
				{
					BOOL found = TRUE;
					char realCMD = [ file characterAtIndex:z ];
					if (realCMD == ' ' || realCMD == '\n' || realCMD == '\t')
						found = FALSE;
					else
					{
						for (int y = 0; y < sizeof(posschar); y++)
						{
							if (realCMD == posschar[y])
							{
								doneWell = TRUE;
								break;
							}
						}
					}
					if (found)
					{
						if (realCMD == '#')
							cancel = TRUE;
						break;
					}
					z--;
				}
				if (doneWell || cancel)
					break;
				if (z == -1)
					break;
				
				if ([ funcType length ] != 0)
					[ funcType insertString:@" " atIndex:0 ];
				while (z != (unsigned long long)-1)
				{
					BOOL found = FALSE;
					for (int y = 0; y < sizeof(posschar); y++)
					{
						if ([ file characterAtIndex:z ] == posschar[y])
						{
							found = TRUE;
							break;
						}
					}
					if (found)
						break;
					[ funcType insertString:[ NSString stringWithFormat:@"%c", [ file characterAtIndex:z ] ] atIndex:0 ];
					z--;
				}
			}
			
			if ([ funcType length ] == 0 || cancel)
				continue;
			
			NSMutableString* type = [ [ NSMutableString alloc ] init ];
			CheckType(funcType, PositionAfterSpaces(0, funcType, NO), type, classCopy, language);
			if ([ type length ] == 0)
				continue;
			if (remove)
			{
				if ([ varCopy containsObject:[ funcName stringByAppendingString:args ] ])
					[ completeView removeVaraible:[ funcName stringByAppendingString:args ] ];
			}
			else
			{
				if (![ varCopy containsObject:[ funcName stringByAppendingString:args ] ])
				{
					//NSLog(@"%@ %@()", funcType, funcName);
					[ completeView addVariable:[ funcName stringByAppendingString:args ] ];
				}
			}
		}
		while (functionRanges.length != 0);
		
		depthIn--;
		if (depthIn == 0 && [ fileName isEqualToString:filename ] && [ [ self string ] length ] == [ file length ])
		{
			loading = FALSE;
			if (![ self isEditable ])
			{
				updateHighlight = TRUE;
				[ self setNeedsDisplay:YES ];
				//[ self processHighlight:NSMakeRange(0, [ [ self string ] length ]) ];
			}
			[ self parseRegion:NSMakeRange(0, [ [ self string ] length ]) usingString:[ self string ] ];
		}
		else if (depthIn == 0)
		{
			loading = FALSE;
			if (![ self isEditable ])
			{
				updateHighlight = TRUE;
				[ self setNeedsDisplay:YES ];
				//[ self processHighlight:NSMakeRange(0, [ [ self string ] length ]) ];
			}
		}
	}
}

- (void) readDocuments
{
	//readingDocs = TRUE;
	
	//[ [ completeView variables ] removeAllObjects ];
	@autoreleasepool {
		[ self setupVariables ];
		/*for (int z = 0; z < sizeof(ctypes) / sizeof(const char*); z++)
			[ completeView addVariable:[ NSString stringWithUTF8String:ctypes[z] ] ];*/
		
		NSMethodSignature* sig = [ self methodSignatureForSelector:@selector(interpretFile:fromName:removing:) ];
		NSInvocation* invoc = [ NSInvocation invocationWithMethodSignature:sig ];
		[ invoc setTarget:self ];
		[ invoc setSelector:@selector(interpretFile:fromName:removing:) ];
		NSString* str = [ self string ];
		[ invoc setArgument:&str atIndex:2 ];
		[ invoc setArgument:&fileName atIndex:3 ];
		BOOL nope = NO;
		[ invoc setArgument:&nope atIndex:4 ];
		if (loadingThread)
		{
			[ loadingThread cancel ];
			while (loading) {}
		}
		loadingThread = [ [ NSThread alloc ] initWithTarget:invoc selector:@selector(invoke) object:nil ];
		[ loadingThread start ];
		
		//[ self interpretFile:[ self string ] fromName:fileName removing:NO ];
		//[ self processHighlight:NSMakeRange(0, [ [ self string ] length ]) ];
		
		//for (unsigned long long z = 0; z < [ classNames count ]; z++)
		//	[ completeView addVariable:[ classNames objectAtIndex:z ] ];
	}
	//readingDocs = FALSE;
}

- (void) removeComments: (NSMutableString*)string
{
	// Remove all comments
	NSRange commentRange = NSMakeRange(0, 0);
	do
	{
		commentRange = [ string rangeOfString:@"/*" options:0 range:NSMakeRange(NSMaxRange(commentRange), [ string length ] - NSMaxRange(commentRange)) ];
		if (commentRange.length == 0)
			break;
		// Find */
		NSRange prevRange = commentRange;
		commentRange = [ string rangeOfString:@"*/" options:0 range:NSMakeRange(NSMaxRange(commentRange), [ string length ] - NSMaxRange(commentRange)) ];
		if (commentRange.location == NSNotFound)
			commentRange = NSMakeRange([ string length ], 0);
		[ string deleteCharactersInRange:NSMakeRange(prevRange.location, NSMaxRange(commentRange) - prevRange.location) ];
		commentRange.location = prevRange.location;
		commentRange.length = 0;
	}
	while (commentRange.location != NSNotFound);
	commentRange = NSMakeRange(0, 0);
	do
	{
		commentRange = [ string rangeOfString:@"//" options:0 range:NSMakeRange(NSMaxRange(commentRange), [ string length ] - NSMaxRange(commentRange)) ];
		if (commentRange.length == 0)
			break;
		// Find */
		NSRange prevRange = commentRange;
		commentRange = [ string rangeOfString:@"\n" options:0 range:NSMakeRange(NSMaxRange(commentRange), [ string length ] - NSMaxRange(commentRange)) ];
		if (commentRange.location == NSNotFound)
			commentRange = NSMakeRange([ string length ], 0);
		[ string deleteCharactersInRange:NSMakeRange(prevRange.location, NSMaxRange(commentRange) - prevRange.location) ];
		commentRange.location = prevRange.location;
		commentRange.length = 0;
	}
	while (commentRange.location != NSNotFound);
}

- (void) parseRegion: (NSRange)range usingString:(NSString*)string
{
	return [ self parseRegion:range usingString:string shouldString:NO ];
}

- (void) parseRegion: (NSRange)range usingString:(NSString*)string shouldString:(BOOL)shouldStr
{
	/*for (unsigned long long z = 0; z < variables.size(); z++)
	{
		if (lineRanges[variables[z].line - 1].location >= range.location && NSMaxRange(range) - [ [ self textStorage ] changeInLength ] >= NSMaxRange(lineRanges[variables[z].line - 1]))
		{
			variables.erase(variables.begin() + z);
			z--;
		}
	}*/
	
	variables.clear();
	NSRange realRange = range;
	if (shouldStr && [ self string ] != string)
		realRange = NSMakeRange(0, [ string length ]);
	
	NSMutableArray* classCopy = [ classNames copy ];
	unsigned long long index = realRange.location;
	while (index < NSMaxRange(realRange))
	{
		NSMutableString* line = [ NSMutableString stringWithString:[ self lineFromIndex:index usingString:string ] ];
		index += [ line length ] + 1;
		if ([ line isEqualToString:@"" ])
			continue;
		unsigned long initPos = PositionAfterSpacesAndComments(0, line, NO);
		/*NSString* word = [ self wordFromIndex:initPos fromString:line ];
		BOOL isCType = FALSE;*/
		NSMutableString* type = [ NSMutableString string ];
		CheckType(line, PositionAfterSpacesAndComments(0, line, NO), type, classCopy, language);
		if (![ type isEqualToString:@"" ])
		{
			CodeVariable var;
			memset(&var, 0, sizeof(var));
			var.name = [ [ NSString alloc ] initWithString:[ self wordFromIndex:PositionAfterSpaces(initPos + [ type length ] + 1, line, YES) fromString:line ] ];
			var.type = [ [ NSString alloc ] initWithString:type ];
			unsigned long long lineNumber = 0;
			for (unsigned long z = 0; z < lineRanges.size(); z++)
			{
				if (index <= lineRanges[z].location && index <= NSMaxRange(lineRanges[z]))
				{
					lineNumber = z;
					break;
				}
			}
			var.line = lineNumber;
			//NSLog(@"%@, %@, %llu, %lu", var.name, var.type, var.line, variables.size() + 1);
			variables.push_back(var);
		}
	}
	
	//[ NSThread detachNewThreadSelector:@selector(readDocuments) toTarget:self withObject:nil ];
	
	NSMutableArray* varCopy = [ [ completeView variables ] copy ];
	for (unsigned long z = 0; z < variables.size(); z++)
	{
		if (![ varCopy containsObject:variables[z].name ])
		{
			//NSLog(@"%@", variables[z].name);
			[ completeView addVariable:variables[z].name ];
			globalVariables.push_back(variables[z]);
		}
	}
}

- (NSRange) fullLineFromIndex:(NSRange)index fromString:(NSString*)string
{
	if ([ string length ] == 0)
		return NSMakeRange(0, 0);
	BOOL wasSpace = FALSE;
	unsigned long long firstPos = index.location;
	while (firstPos < [ string length ])
	{
		char cmd = [ string characterAtIndex:firstPos ];
		if (cmd == ';' || cmd == '{' || cmd == '}')
			break;
		else if (cmd == '\t' || cmd == ' ' || cmd == '\n')
			wasSpace = TRUE;
		else if ((cmd == '>' && wasSpace) || (cmd == '"' && wasSpace))
			break;
		firstPos--;
	}
	firstPos++;
	unsigned long long secondPos = index.location;
	while (secondPos < [ string length ] - 1)
	{
		if (([ string characterAtIndex:secondPos ] == ';' || [ string characterAtIndex:secondPos ] == '}') && secondPos >= NSMaxRange(index))
			break;
		secondPos++;
	}
	return NSMakeRange(firstPos, secondPos - firstPos);
}

/*- (BOOL) textShouldBeginEditing:(NSText*)textObject
{
	
	if (previousString)
		[ previousString release ];
	previousString = [ [ NSString alloc ] initWithString:[ self string ] ];
	
	return YES;
}*/


- (void) textStorageDidProcessEditing:(NSNotification*)notification
{
	edited = TRUE;
	//if (loading)
	// 	return;
	
	if (waitForEdit)
		return;
	
	// Temp
	
	/*// Process the current word
	unsigned long pos = [ [ self textStorage ] editedRange ].location;
	NSString* text = [ self string ];
	while (pos != NSNotFound)
	{
		if ([ text length ] <= pos)
			break;
		char cmd = [ text characterAtIndex:pos ];
		BOOL done = FALSE;
		for (int z = 0; z < sizeof(posschar); z++)
		{
			if (cmd == posschar[z])
			{
				done = TRUE;
				break;
			}
		}
		if (done)
		{
			pos++;
			if (pos > [ [ self textStorage ] editedRange ].location)
				pos = [ [ self textStorage ] editedRange ].location;
			break;
		}
		if (pos == 0)
			break;
		pos--;
	}
	unsigned long end = NSMaxRange([ [ self textStorage ] editedRange ]);
	while (end < [ text length ])
	{
		char cmd = [ text characterAtIndex:end ];
		BOOL done = FALSE;
		for (int z = 0; z < sizeof(posschar); z++)
		{
			if (cmd == posschar[z])
			{
				done = TRUE;
				break;
			}
		}
		if (done)
		{
			if (end < NSMaxRange([ [ self textStorage ] editedRange ]))
				end = NSMaxRange([ [ self textStorage ] editedRange ]);
			break;
		}
		end++;
	}
	[ self processHighlight:NSMakeRange(pos, end - pos) ];*/

	// This highlights the whole visible region, but you probably only need to update the edited region
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
	charRange.length += [ [ self textStorage ] editedRange ].length;
	//NSRange range = [ [ self textStorage ] editedRange ];
	
	// Backspace
	if (NSMaxRange(charRange) >= [ [ self string ] length ])
		charRange = NSMakeRange(0, [ [ self string ] length ]);
	[ self processHighlight:charRange ];
	
	/*unsigned long long startLoc = 0;
	NSLog(@"%ld", long([ [ self textStorage ] changeInLength ]));
	for (unsigned long z = 0; z < lineRanges.size(); z++)
	{
		if (range.location + [ [ self textStorage ] changeInLength ] < NSMaxRange(lineRanges[z]))
		{
			startLoc = lineRanges[z].location;
			break;
		}
	}
	unsigned long long endLoc = [ [ self string ] length ];
	for (unsigned long z = 0; z < lineRanges.size(); z++)
	{
		if (NSMaxRange(range) + [ [ self textStorage ] changeInLength ] < lineRanges[z].location)
		{
			if (z != 0)
				endLoc = NSMaxRange(lineRanges[z - 1]);
			else
				endLoc = 0;
			break;
		}
	}
	[ self parseRegion:NSMakeRange(startLoc, endLoc - startLoc) ];*/
	
	//NSLog(@"%lu, %lu", [ [ self textStorage ] editedRange ].location, [ [ self textStorage ] editedRange ].length);
	
	[ self reloadLines ];
	
	// For now
	// Remove all errors
	errors.clear();
	
	if (loading)
	 	return;
	
	NSRange realEditedRange = [ [ self textStorage ] editedRange ];
		
	//[ self parseRegion:NSMakeRange(0, [ [ self string ] length ]) ];
	if (editRange.length != 0)
	{
		if (oldEditString)
		{
			[ self parseRegion:oldEditRange usingString:oldEditString shouldString:YES ];
			NSMutableArray* varCopy = [ [ completeView variables ] copy ];
			for (unsigned long z = 0; z < variables.size(); z++)
			{
				if ([ varCopy containsObject:variables[z].name ])
					[ [ completeView variables ] removeObject:variables[z].name ];
				for (unsigned long q = 0; q < globalVariables.size(); q++)
				{
					if ([ globalVariables[q].name isEqualToString:variables[z].name ])
					{
						//NSLog(@"Removed - %@", variables[z].name);
						ReleaseVariable(globalVariables[q]);
						globalVariables.erase(globalVariables.begin() + q);
						break;
					}
				}
			}
			[ self interpretFile:oldEditString fromName:fileName removing:YES ];
		}
		[ self parseRegion:editRange usingString:[ self string ] shouldString:YES ];
		if (NSMaxRange(editRange) < [ [ self string ] length ])
			[ self interpretFile:[ [ self string ] substringWithRange:editRange ] fromName:fileName removing:NO ];
		oldEditString = nil;
		editRange = NSMakeRange(-1, 0);
	}
	else
	{
		if (previousString)
		{
			// Compare these strings
			unsigned long long firstPos = [ [ self string ] length ];
			for (unsigned long long z = 0; z < [ [ self string ] length ]; z++)
			{
				char cmd1 = [ [ self string ] characterAtIndex:z ];
				if (z >= [ previousString length ])
				{
					firstPos = z;
					break;
				}
				char cmd2 = [ previousString characterAtIndex:z ];
				if (cmd1 != cmd2)
				{
					firstPos = z;
					break;
				}
			}
			unsigned long long secondPos1 = 0;
			unsigned long long secondPos2 = 0;
			for (unsigned long long z = 0; z < [ [ self string ] length ]; z++)
			{
				unsigned long long trueZ1 = [ [ self string ] length ] - z - 1;
				char cmd1 = [ [ self string ] characterAtIndex:trueZ1 ];
				unsigned long long trueZ2 = [ previousString length ] - z - 1;
				if (trueZ2 >= [ previousString length ])
				{
					secondPos1 = trueZ1;
					secondPos2 = [ previousString length ];
					break;
				}
				char cmd2 = [ previousString characterAtIndex:trueZ2 ];
				if (cmd1 != cmd2)
				{
					secondPos1 = trueZ1;
					secondPos2 = trueZ2;
					break;
				}
			}
			
			if (secondPos2 > firstPos)
			{
				realEditedRange = NSMakeRange(firstPos, secondPos2 - firstPos);
				NSRange range1 = [ self fullLineFromIndex:realEditedRange fromString:previousString ];
				[ self parseRegion:range1 usingString:previousString ];
				NSMutableArray* varCopy = [ [ completeView variables ] copy ];
				for (unsigned long z = 0; z < variables.size(); z++)
				{
					if ([ varCopy containsObject:variables[z].name ])
						[ [ completeView variables ] removeObject:variables[z].name ];
					for (unsigned long q = 0; q < globalVariables.size(); q++)
					{
						if ([ globalVariables[q].name isEqualToString:variables[z].name ])
						{
							//NSLog(@"Removed 2 - %@", variables[z].name);
							ReleaseVariable(globalVariables[q]);
							globalVariables.erase(globalVariables.begin() + q);
							break;
						}
					}
				}
				if (NSMaxRange(range1) < [ previousString length ])
					[ self interpretFile:[ previousString substringWithRange:range1 ] fromName:fileName removing:YES ];
				realEditedRange = NSMakeRange(firstPos, secondPos2 - firstPos);
				//editedLength = realEditedRange.length;
				editPosition = firstPos;
				NSRange range2 = [ self fullLineFromIndex:realEditedRange fromString:[ self string ] ];
				[ self parseRegion:range2 usingString:[ self string ] ];
				if (NSMaxRange(range2) < [ [ self string ] length ])
					[ self interpretFile:[ [ self string ] substringWithRange:range2 ] fromName:fileName removing:NO ];
			}
		}
		else
		{
			NSRange range1 = [ self fullLineFromIndex:realEditedRange fromString:[ self string ] ];
			[ self parseRegion:range1 usingString:[ self string ] ];
			//editedLength = range1.length;
			editPosition = range1.location;
			if (NSMaxRange(range1) < [ [ self string ] length ])
				[ self interpretFile:[ [ self string ] substringWithRange:range1 ] fromName:fileName removing:NO ];
		}
	}
	
	if (editedLength != 0)
	{
		for (unsigned long long z = 0; z < completeBlocks.size(); z++)
		{
			if (completeBlocks[z].position >= editPosition)
				completeBlocks[z].position += editedLength;
		}
		[ self setNeedsDisplay:YES ];
		editedLength = 0;
	}
	
	if (shouldDeleteBlocks)
	{
		// Check to see if all the autocomplete blocks have the same thing under them otherwise delete them
		for (unsigned long long z = 0; z < completeBlocks.size(); z++)
		{
			AutoCompleteBlock block = completeBlocks[z];
			if (block.position >= [ [ self string ] length ])
			{
				if (completeBlocks.size() == 1)
				{
					completeBlocks.clear();
					selectedBlock = -1;
					break;
				}
				completeBlocks.erase(completeBlocks.begin() + z);
				z--;
				selectedBlock = -1;
				continue;
			}
			unsigned long long pos = block.position;
			while (pos < block.position + [ block.text length ])
			{
				char cmd = [ [ self string ] characterAtIndex:pos ];
				if (cmd != [ block.text characterAtIndex:pos - block.position ])
				{
					if (completeBlocks.size() == 1)
					{
						completeBlocks.clear();
						selectedBlock = -1;
						break;
					}
					completeBlocks.erase(completeBlocks.begin() + z);
					z--;
					selectedBlock = -1;
					break;
				}
				pos++;
			}
		}
	}
	
	previousString = [ [ NSString alloc ] initWithString:[ self string ] ];
}

- (void) paste:(id)sender
{
	
	if ([ [ [ NSPasteboard generalPasteboard ] pasteboardItems ] count ] == 0 || ![ loadingThread isFinished ])
	{
		[ super paste:sender ];
		return;
	}
	
	oldEditRange = [ [ self selectedRanges ][0] rangeValue ];
	NSData* first = [ [ [ NSPasteboard generalPasteboard ] pasteboardItems ][0] dataForType:NSPasteboardTypeString ];
	if ([ first length ] != 0)
	{
		NSString* real = [ [ NSString alloc ] initWithData:first encoding:NSASCIIStringEncoding ];
		editRange = NSMakeRange(oldEditRange.location, [ real length ]);
	}
	editedLength = -[ self selectedRange ].length + [ first length ];
	editPosition = [ self selectedRange ].location;
	[ super paste:sender ];
}

- (void) drawRect:(NSRect)dirtyRect
{
	// Temp
	if (dispatch_get_main_queue() != dispatch_get_current_queue())
		return;
	
	if (updateHighlight)
	{
		updateHighlight = FALSE;
		//[ self processHighlight:NSMakeRange(0, [ [ self string ] length ]) ];
	}
	
	if (updateBreaks && enableBreaks)
	{
		updateBreaks = FALSE;
		if (breakTarget && [ breakTarget respondsToSelector:breakPointEdited ])
			((void (*)(id, SEL))[ breakTarget methodForSelector:breakPointEdited ])(breakTarget, breakPointEdited);
	}
	
	[ super drawRect:dirtyRect ];
	
	//[ self lockFocusIfCanDraw ];
	
	// Draw lines
	[ [ NSColor colorWithCalibratedRed:0.945098 green:0.945098 blue:0.945098 alpha:1 ] set ];
	NSRectFill(NSMakeRect(0, 0, 29,  [ self frame ].size.height));
	[ [ NSColor colorWithCalibratedRed:0.6 green:0.6 blue:0.6 alpha:1 ] set ];
	NSRectFill(NSMakeRect(29, 0, 1, [ self frame ].size.height));
	unsigned long current = 1;
	float currentHeight = 0;
	lineHeights.clear();
	float realWidth = [ self frame ].size.width - 70;
	NSArray* lines = [ [ self string ] componentsSeparatedByString:@"\n" ];
	// The isEditable part is temp for the code headers view to always show the lines
	while (current - 1 < [ lines count ] || (![ self isEditable ] && currentHeight < [ self frame ].size.height))
	{
		unsigned long bp = -1;
		for (unsigned long z = 0; z < breakpoints.size(); z++)
		{
			if (breakpoints[z] == current)
			{
				bp = current;
				break;
			}
		}
		
		NSColor* trueColor = [ NSColor colorWithCalibratedRed:0.6 green:0.6 blue:0.6 alpha:1 ];
		if (bp != -1 && enableBreaks)
			trueColor = [ NSColor whiteColor ];
		NSMutableAttributedString* test = [ [ NSMutableAttributedString alloc ] initWithString:[ NSString stringWithFormat:@"%lu", current ] attributes:@{NSFontAttributeName: [ NSFont fontWithName:@"Helvetica" size:10 ], NSForegroundColorAttributeName: trueColor} ];
		
		if (bp != -1 && enableBreaks)
		{
			// Draw breakpoint
			[ [ NSColor colorWithCalibratedRed:0.423529 green:0.600000 blue:0.780392 alpha:1 ] set ];
			NSRectFill(NSMakeRect(0, currentHeight - 1, 30, [ test size ].height));
		}
		
		lineHeights.push_back(currentHeight);
		[ test drawInRect:NSMakeRect(27 - [ test size ].width, currentHeight - 1, [ test size ].width, [ test size ].height) ];
		
		NSMutableAttributedString* test2 = [ [ NSMutableAttributedString alloc ] initWithString:[ NSString stringWithFormat:@"" ] attributes:@{NSFontAttributeName: [ NSFont fontWithName:@"Menlo" size:11 ], NSForegroundColorAttributeName: trueColor} ];
		CGRect rect = [ test2 boundingRectWithSize:CGSizeMake(100000, 10000) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading ];
		
		if (current - 1 < lineRanges.size())
		{
			NSString* string2 = lines[current - 1];//[ [ self string ] substringWithRange:lineRanges[current-1] ];
			NSAttributedString* string =  [ [ NSMutableAttributedString alloc ] initWithString:string2 attributes:@{NSFontAttributeName: [ NSFont fontWithName:@"Menlo" size:11 ], NSForegroundColorAttributeName: [ NSColor colorWithCalibratedRed:0.6 green:0.6 blue:0.6 alpha:1 ]} ];
			float width = [ string size ].width;
			//NSLog(@"%f, %f", [ [ self enclosingScrollView ] documentVisibleRect ].size.width, width);
			while (width > realWidth)
			{
				width -= realWidth;
				currentHeight += [ test2 size ].height - 2;
			}
		}
		
		currentHeight += rect.size.height - 2;
		current++;
	}
	
	if (executionLine != 0)
	{
		// Figure out range of that line
		NSRange range = lineRanges[executionLine - 1];
		range.length--;
		NSLayoutManager *layoutManager = [self layoutManager];
		range = [ layoutManager glyphRangeForCharacterRange:range actualCharacterRange:NULL ];
		NSRect rect = [ layoutManager boundingRectForGlyphRange:range inTextContainer:[ self textContainer ] ];
		NSPoint containerOrigin = [ self textContainerOrigin ];
		rect = NSOffsetRect(rect,containerOrigin.x,containerOrigin.y);
		float oldOffset = rect.origin.x + rect.size.width + 20;
		rect.size.width += rect.origin.x + 20;
		rect.origin.x = 0;
		[ [ NSColor colorWithCalibratedRed:0.831373 green:0.878431 blue:0.741176 alpha:0.3 ] set ];
		NSBezierPath* path = [ [ NSBezierPath alloc ] init ];
		[ path moveToPoint:NSMakePoint(rect.origin.x, rect.origin.y) ];
		[ path lineToPoint:NSMakePoint(rect.origin.x, rect.origin.y + rect.size.height) ];
		[ path lineToPoint:NSMakePoint(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height) ];
		[ path lineToPoint:NSMakePoint(rect.origin.x + rect.size.width, rect.origin.y) ];
		[ path closePath ];
		[ path fill ];
		
		[ [ NSColor colorWithCalibratedRed:0.831373 green:0.878431 blue:0.741176 alpha:1 ] set ];
		path = [ [ NSBezierPath alloc ] init ];
		[ path moveToPoint:NSMakePoint(oldOffset, rect.origin.y) ];
		[ path lineToPoint:NSMakePoint(oldOffset - 5, rect.origin.y + (rect.size.height / 2)) ];
		[ path lineToPoint:NSMakePoint(oldOffset, rect.origin.y + rect.size.height) ];
		[ path lineToPoint:NSMakePoint(dirtyRect.size.width, rect.origin.y + rect.size.height) ];
		[ path lineToPoint:NSMakePoint(dirtyRect.size.width, rect.origin.y) ];
		[ path closePath ];
		[ path fill ];
		
		[ NSBezierPath strokeRect:rect ];
		
		NSAttributedString* string = [ [ NSAttributedString alloc ] initWithString:[ NSString stringWithFormat:@"Line %lu", executionLine ] attributes:@{NSFontAttributeName: [ NSFont fontWithName:@"Helvetica" size:10 ]} ];
		[ string drawAtPoint:NSMakePoint(oldOffset + 3, rect.origin.y - (rect.size.height / 2) + 7) ];
	}
	
	// Draw errors
	for (int z = 0; z < errors.size(); z++)
	{
		// Figure out range of that line
		if (lineRanges.size() <= errors[z].line - 1)
			continue;
		NSRange range = lineRanges[errors[z].line - 1];
		range.length--;
		NSLayoutManager *layoutManager = [self layoutManager];
		range = [ layoutManager glyphRangeForCharacterRange:range actualCharacterRange:NULL ];
		NSRect rect = [ layoutManager boundingRectForGlyphRange:range inTextContainer:[ self textContainer ] ];
		NSPoint containerOrigin = [ self textContainerOrigin ];
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
		
		[ NSBezierPath strokeRect:rect ];
		
		NSAttributedString* string = [ [ NSAttributedString alloc ] initWithString:errors[z].error attributes:@{NSFontAttributeName: [ NSFont fontWithName:@"Helvetica" size:10 ]} ];
		[ string drawAtPoint:NSMakePoint(oldOffset + 3, rect.origin.y - (rect.size.height / 2) + 7) ];
	}
	
	// Draw Autocopmlete Blocks
	for (unsigned long z = 0; z < completeBlocks.size(); z++)
	{
		AutoCompleteBlock block = completeBlocks[z];
		NSLayoutManager *layoutManager = [ self layoutManager];
		NSRange range = [ layoutManager glyphRangeForCharacterRange:NSMakeRange(block.position, 0) actualCharacterRange:NULL ];
		NSRect rect = [ layoutManager boundingRectForGlyphRange:range inTextContainer:[ self textContainer ] ];
		NSPoint containerOrigin = [ self textContainerOrigin ];
		rect = NSOffsetRect(rect, containerOrigin.x, containerOrigin.y);
		rect.origin.y -= 1;
		// r,g,b = .0.913726, 0.937255, 0.980392
		// outline r,g,b = 0.701961, 0.760784, 0.862745
		// selected = 0.596078, 0.709804, 0.941177
		if (selectedBlock == z)
		{
			NSAttributedString* string = [ [ NSAttributedString alloc ] initWithString:block.text attributes:@{NSFontAttributeName: [ self font ], NSForegroundColorAttributeName: [ NSColor blackColor ]} ];
			rect.size = [ string size ];
			rect.size.height -= 3;
			rect.origin.x -= 2;
			rect.size.width += 4;
			[ [ NSColor colorWithCalibratedRed:0.596078 green:0.709804 blue:0.941177 alpha:1 ] set ];
			[ [ NSBezierPath bezierPathWithRoundedRect:rect xRadius:2 yRadius:2 ] fill ];
			rect.origin.x += 2;
			rect.origin.y -= 3;
			[ string drawAtPoint:rect.origin ];
		}
		else
		{
			NSAttributedString* string = [ [ NSAttributedString alloc ] initWithString:block.text attributes:@{NSFontAttributeName: [ self font ], NSForegroundColorAttributeName: [ NSColor blackColor ]} ];
			rect.size = [ string size ];
			rect.size.height -= 3;
			rect.origin.x -= 2;
			rect.size.width += 4;
			[ [ NSColor colorWithCalibratedRed:0.913726 green:0.937255 blue:0.980392 alpha:1 ] set ];
			[ [ NSBezierPath bezierPathWithRoundedRect:rect xRadius:2 yRadius:2 ] fill ];
			rect.origin.x += 1;
			rect.size.width -= 2;
			[ [ NSColor colorWithCalibratedRed:0.701961 green:0.760784 blue:0.862745 alpha:1 ] set ];
			[ [ NSBezierPath bezierPathWithRoundedRect:rect xRadius:2 yRadius:2 ] stroke ];
			rect.origin.x += 1;
			rect.origin.y -= 3;
			[ string drawAtPoint:rect.origin ];
		}
	}
	
	if (showVariable && variableString && executionLine != 0)
	{
		NSAttributedString* drawString = [ [ NSAttributedString alloc ] initWithString:variableString attributes:@{NSFontAttributeName: [ self font ], NSForegroundColorAttributeName: [ NSColor blackColor ]} ];
		
		// Draw variable string
		variableSize.width = [ drawString size ].width + 30;
		variableSize.height = [ drawString size ].height + 6;
		[ [ NSColor colorWithCalibratedRed:0.952941 green:0.949020 blue:0.776471 alpha:1 ] set ];
		NSRectFill(NSMakeRect(variablePoint.x, variablePoint.y, variableSize.width, variableSize.height));
		[ drawString drawAtPoint:NSMakePoint(variablePoint.x + 15, variablePoint.y + 1) ];
	}
	
	//[ self unlockFocus ];
}

- (void) addError:(NSString*)error atLine:(unsigned long long)line type:(unsigned int)etype
{
	// Check for line already
	for (unsigned long z = 0; z < errors.size(); z++)
	{
		if (errors[z].line == line)
		{
			if (errors[z].type == etype)
			{
				// Append message;
				NSString* string = [ NSString stringWithString:errors[z].error ];
				errors[z].error = [ [ NSString alloc ] initWithFormat:@"%@ %@", string, error ];
				return;
			}
			else
			{
				// Just ignore it for now
				return;
			}
		}
	}
	
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

BOOL updatingLines = FALSE;

- (void) updateLineNumbers
{
	return;
	
	while (updatingLines) {}
	
	updatingLines = TRUE;
	@autoreleasepool {
		numberArray = [ [ NSMutableArray alloc ] init ];
		
		unsigned long current = 1;
		float currentHeight = 0;
		lineHeights.clear();
		while (current - 1 < lineRanges.size())
		{
			unsigned long bp = -1;
			for (unsigned long z = 0; z < breakpoints.size(); z++)
			{
				if (breakpoints[z] == current)
				{
					bp = current;
					break;
				}
			}
			
			NSColor* trueColor = [ NSColor colorWithCalibratedRed:0.6 green:0.6 blue:0.6 alpha:1 ];
			if (bp != -1 && enableBreaks)
				trueColor = [ NSColor whiteColor ];
			NSMutableAttributedString* test = [ [ NSMutableAttributedString alloc ] initWithString:[ NSString stringWithFormat:@"%lu", current ] attributes:@{NSFontAttributeName: [ NSFont fontWithName:@"Helvetica" size:10 ], NSForegroundColorAttributeName: trueColor} ];
			
			NSAttributedString* string =  [ [ NSMutableAttributedString alloc ] initWithString:[ [ self string ] substringWithRange:lineRanges[current-1] ] attributes:@{NSFontAttributeName: [ NSFont fontWithName:@"Menlo" size:11 ], NSForegroundColorAttributeName: [ NSColor colorWithCalibratedRed:0.6 green:0.6 blue:0.6 alpha:1 ]} ];
			float width = [ string size ].width;
			//NSLog(@"%f, %f", [ [ self enclosingScrollView ] documentVisibleRect ].size.width, width);
			while (width > [ self frame ].size.width)
			{
				width -= [ self frame ].size.width;
				currentHeight += [ test size ].height;
			}
			
			currentHeight += [ test size ].height;
			lineHeights.push_back(currentHeight);
			[ numberArray addObject:test ];
			current++;
		}
		
		[ self setNeedsDisplay:YES ];
	}
	
	updatingLines = FALSE;
}

- (void) reloadLines
{
	// Index every line
	lineRanges.clear();
	//[ self setNeedsDisplay:YES ];
	NSRange range = NSMakeRange(0, 0);
	unsigned long long prevMax = 0;
	while (NSMaxRange(range) < [ [ self string ] length ])
	{
		range = [ [ self string ] rangeOfString:@"\n" options:0 range:NSMakeRange(NSMaxRange(range), [ [ self string ] length ] - NSMaxRange(range)) ];
		if (range.length == 0)
		{
			lineRanges.push_back(NSMakeRange(prevMax, [ [ self string ] length ] - prevMax));
			break;
		}
		lineRanges.push_back(NSMakeRange(prevMax, NSMaxRange(range) - prevMax));
		prevMax = NSMaxRange(range);
		range.location++;
		range.length = 0;
	}
	[ NSThread detachNewThreadSelector:@selector(updateLineNumbers) toTarget:self withObject:nil ];
}

- (unsigned long long) autoStart
{
	return autoStart;
}

- (void) jumpToDefinition
{
	// Check the word selected
	unsigned long pos1 = PositionAfterSpaces([ self selectedRange ].location, [ self string ], YES);
	unsigned long pos2 = PositionBeforeSpaces(NSMaxRange([ self selectedRange ]), [ self string ], YES);
	NSString* word = [ [ self string ] substringWithRange:NSMakeRange(pos1, pos2 - pos1) ];
	// Check all the names
	for (unsigned long z = 0; z < [ classNames count ]; z++)
	{
		if ([ classNames[z] isEqualToString:word ])
		{
			return;
		}
	}
	
	
}

- (void) addCompleteBlock:(AutoCompleteBlock *)block
{
	completeBlocks.push_back(*block);
}

- (unsigned long long) numberOfBlocks
{
	return completeBlocks.size();
}

- (void) setSelectedBlock:(unsigned long long)block
{
	if (block < completeBlocks.size())
		selectedBlock = block;
	else
		selectedBlock = -1;
	[ self setNeedsDisplay:YES ];
}

- (void) setFileName:(NSString*)file
{
	fileName = [ [ NSString alloc ] initWithString:file ];
}

- (NSString*) fileName
{
	return fileName;
}

- (BOOL) loading
{
	return loading;
}

- (void) setExecutionLine:(unsigned long)exec
{
	executionLine = exec;
	if (executionLine != 0 && lineRanges.size() > executionLine - 1)
	{
		NSRange range = lineRanges[executionLine - 1];
		[ self scrollRangeToVisible:range ];
	}
	[ self setNeedsDisplay:YES ];
}

- (unsigned long) executionLine
{
	return executionLine;
}

- (void) setBreakpoints:(std::vector<unsigned long>) breaks
{
	breakpoints = breaks;
	[ self reloadLines ];
}

- (std::vector<unsigned long>&) breakpoints
{
	return breakpoints;
}

- (void) setEnableBreaks:(BOOL)enable
{
	enableBreaks = enable;
	[ self reloadLines ];
}

- (BOOL) enableBreaks
{
	return enableBreaks;
}

- (void) setBreakTarget:(id)tar
{
	breakTarget = tar;
}

- (id) breakTarget
{
	return breakTarget;
}

- (void) setBreakPointAction:(SEL)act
{
	breakPointEdited = act;
}

- (SEL) breakPointAction
{
	return breakPointEdited;
}

- (void) setVariableTarget:(id)tar
{
	variableTarget = tar;
}

- (id) variableTarget
{
	return variableTarget;
}

- (void) setVariableAction:(SEL)act
{
	variableRequested = act;
}

- (SEL) variableAction
{
	return variableRequested;
}

- (void) checkVariableSecond
{
	variableTimer = nil;
	
	if (showVariable)// || [ NSView focusView ] != self)
	{
		showVariable = FALSE;
		[ self setNeedsDisplay:YES ];
	}
	else if (enableBreaks && executionLine != 0)
	{
		NSPoint newPoint = variablePoint;
		//newPoint.x += 35;
		newPoint.y -= [ [ self enclosingScrollView ] documentVisibleRect ].origin.y;
		newPoint.y = [ [ self enclosingScrollView ] documentVisibleRect ].size.height - newPoint.y;
		newPoint.x += [ [ self window ] frame ].origin.x;
		newPoint.y += [ [ self window ] frame ].origin.y;
		unsigned long pos = [ self characterIndexForPoint:newPoint ];
		while (pos != 0)
		{
			char cmd = [ [ self string ] characterAtIndex:pos ];
			BOOL found = FALSE;
			for (unsigned long z = 0; z < sizeof(posschar); z++)
			{
				if (cmd == posschar[z])
				{
					pos++;
					found = TRUE;
					break;
				}
			}
			if (found)
				break;
			pos--;
		}
		NSString* varName = [ self wordFromIndex:pos fromString:[ self string ] ];
		[ self requestVariable:varName ];
	}
}

- (void) requestVariable:(NSString*)varName
{
	if (variableTarget && [ variableTarget respondsToSelector:variableRequested ])
		((void (*)(id, SEL, id))[ variableTarget methodForSelector:variableRequested ])(variableTarget, variableRequested, varName);
}

- (void) setVariableString:(NSString*)string
{
	variableString = [ [ NSString alloc ] initWithString:string ];
	showVariable = TRUE;
	[ self setNeedsDisplay:YES ];
}

- (NSString*) variableString
{
	return variableString;
}

- (void) setVariableUpdated:(SEL)act
{
	variableUpdated = act;
}

- (SEL) variableUpdatedAction
{
	return variableUpdated;
}

- (void) updateVariable:(NSString*)varName value:(NSString*)varValue
{
	if (variableTarget && [ variableTarget respondsToSelector:variableUpdated ])
		((void (*)(id, SEL, id))[ variableTarget methodForSelector:variableUpdated ])(variableTarget, variableUpdated, varValue);
}

- (BOOL) edited
{
	BOOL ret = edited;
	edited = FALSE;
	return ret;
}

- (BOOL) editedNoReset
{
	return edited;
}

- (void) setEdited:(BOOL)edit
{
	edited = edit;
}

- (void) setLanguage:(MDLanguage)lan
{
	language = lan;
}

- (MDLanguage) language
{
	return language;
}

- (void) dealloc
{
	errors.clear();
	variables.clear();
	globalVariables.clear();
	lineRanges.clear();
	completeBlocks.clear();
}

@end

