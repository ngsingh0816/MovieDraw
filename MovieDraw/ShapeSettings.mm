//
//  ShapeSettings.mm
//  MovieDraw
//
//  Created by Neil on 7/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ShapeSettings.h"

void* InterpretArguement(NSMutableString* arguement, NSMethodSignature* sig, unsigned int index, BOOL say);
id ValueForMethod(NSString* settings, unsigned long* pos);
unsigned long PositionAfterSpaces(NSString* string, unsigned long start);
// For types
char* lastType = NULL;
// Current Timer for updating values
NSTimer* updateTimer = nil;
NSArray* currentFile = NULL;
NSArray* currentDraw = NULL;
NSString* whole = nil;

std::vector<Variable> variables;
std::vector<Function*> functions;

@implementation Function

@synthesize range;

- (void) method: (id) sender
{
	CompileShapeSettings([ [ whole substringWithRange:range ] componentsSeparatedByString:@";" ], variables[0].obj);
}

- (void) setType:(NSString*)ty
{
	if (type)
		[ type release ];
	type = [ [ NSString alloc ] initWithString:ty ];
}

- (void) setName:(NSString*)na
{
	if (name)
		[ name release ];
	name = [ [ NSString alloc ] initWithString:na ];
}

- (NSString*) type
{
	return type;
}

- (NSString*) name
{
	return name;
}

- (void) dealloc
{
	if (type)
	{
		[ type release ];
		type = nil;
	}
	if (name)
	{
		[ name release ];
		name = nil;
	}
	[ super dealloc ];
}

@end

@interface UpdateVariables : NSObject
+ (void) update: (NSTimer*)timer;
@end

@implementation UpdateVariables

+ (void) update: (NSTimer*) timer
{
	if (!currentFile)
		return;
	
	CompileShapeSettings(currentFile, variables[0].obj);
}
@end

@implementation SettingDraw

- (void) drawRect:(NSRect)dirtyRect
{
	[ super drawRect:dirtyRect ];
	if ([ self canDraw ] && currentDraw)
		CompileShapeSettings(currentDraw, variables[0].obj);
}

@end

Function* FunctionNamed(NSString* name)
{
	for (int z = 0; z < functions.size(); z++)
	{
		if ([ functions[z].name isEqualToString:name ])
			return functions[z];
	}
	
	return nil;
}

NSRange RangeOfFunction(NSString* type, NSString* name, NSString* current)
{
	char cmd = 0;
	int step = 0;
	NSMutableString* buffer = [ [ NSMutableString alloc ] init ];
	unsigned long place = 0;
	BOOL found = FALSE;
	for (unsigned long z = 0; z < [ current length ]; z++)
	{
		cmd = [ current characterAtIndex:z ];
		if (cmd == ' ' || cmd == '\n' || cmd == '\t')
		{
			BOOL does = FALSE;
			if (step == 0 && [ buffer isEqualToString:type ])
				does = TRUE;
			else if (step == 1 && [ buffer hasPrefix:name ])
				does = TRUE;
			else if (step == 2 && [ buffer isEqualToString:@"(){" ])
				does = TRUE;
			else if (!(step == 2 && [ buffer hasPrefix:@"(){" ]))
			{
				step = 0;
				[ buffer setString:@"" ];
			}
			if (does)
			{
				step++;
				if (step == 2)
					[ buffer deleteCharactersInRange:NSMakeRange(0, [ name length ]) ];
				else
					[ buffer setString:@"" ];
				if (step == 3)
				{
					place = z;
					found = TRUE;
					break;
				}
			}
			continue;
		}
		[ buffer appendFormat:@"%c", cmd ];
	}
	[ buffer release ];
	if (!found)
		return NSMakeRange(-1, 0);
	unsigned long end = 0;
	int quantity = 1;
	for (end = place; end < [ current length ]; end++)
	{
		cmd = [ current characterAtIndex:end ];
		if (cmd == '{')
			quantity++;
		else if (cmd == '}')
		{
			quantity--;
			if (quantity == 0)
				break;
		}
	}
	return NSMakeRange(place, end - 1 - place);
}

void InitShapeSettings(NSView* view, NSString* path)
{
	Variable sview;
	memset(&sview, 0, sizeof(sview));
	sview.obj = view;
	sview.name = [ [ NSString alloc ] initWithString:@"view" ];
	variables.insert(variables.begin(), sview);
	
	updateTimer = [ NSTimer scheduledTimerWithTimeInterval:0 target:[ UpdateVariables class ] selector:@selector(update:) userInfo:nil repeats:YES ];
	[ [ NSRunLoop mainRunLoop ] addTimer:updateTimer forMode:NSRunLoopCommonModes ];
	
	FILE* file = fopen([ path UTF8String ], "r");
	fseek(file, 0, SEEK_END);
	unsigned long size = ftell(file);
	rewind(file);
	char* data = (char*)malloc(size);
	fread(data, 1, size, file);
	NSMutableString* current = [ [ NSMutableString alloc ] initWithFormat:@"%s", data ];
	free(data);
	data = NULL;
	whole = [ [ NSString alloc ] initWithString:current ];
	unsigned long location = [ current rangeOfString:@"@end\n" ].location;
	[ current deleteCharactersInRange:NSMakeRange(location, [ current length ] - location) ];
	// Search for void main()
	
	Function* main = [ [ Function alloc ] init ];
	[ main setName:@"main" ];
	[ main setType:@"void" ];
	main.range = RangeOfFunction(@"void", @"main", current);
	functions.push_back(main);
	Function* update = [ [ Function alloc ] init ];
	[ update setName:@"update" ];
	[ update setType:@"void" ];
	update.range = RangeOfFunction(@"void", @"update", current);
	functions.push_back(update);
	Function* draw = [ [ Function alloc ] init ];
	[ draw setName:@"draw" ];
	[ draw setType:@"void" ];
	draw.range = RangeOfFunction(@"void", @"draw", current);
	functions.push_back(draw);
	
	currentFile = [ [ NSArray alloc ] initWithArray:[ [ current substringWithRange:FunctionNamed(@"update").range ] componentsSeparatedByString:@";" ] ];
	currentDraw = [ [ NSArray alloc ] initWithArray:[ [ current substringWithRange:FunctionNamed(@"draw").range ] componentsSeparatedByString:@";" ] ];
	[ current release ];
	current = nil;
}

unsigned long PositionAfterSpaces(NSString* string, unsigned long start)
{
	unsigned long end = start;
	for (;;)
	{
		if (end >= [ string length ])
			break;
		if ([ string characterAtIndex:end ] == ' ' ||
			[ string characterAtIndex:end ] == '\t' ||
			[ string characterAtIndex:end ] == '\n')
			end++;
		else
			break;
	}
	return end;
}

unsigned long PositionBeforeSpaces(NSString* string, unsigned long start)
{
	unsigned long end = start;
	for (;;)
	{
		if ([ string characterAtIndex:end ] == ' ' ||
			[ string characterAtIndex:end ] == '\t' ||
			[ string characterAtIndex:end ] == '\n')
			end--;
		else
			break;
		
		if (end == 0)
			break;
	}
	return end + 1;
}

void FormatFunction(NSMutableString* final, NSString* string, NSMutableArray* args)
{
	// Scan string for %'s
	int argPointer = 0;
	for (int z = 0; z < [ string length ]; z++)
	{
		if ([ string characterAtIndex:z ] == '%')
		{
			if (z++ >= [ string length ])
				break;
			id data = ValueForMethod([ args objectAtIndex:argPointer++ ], NULL);
			if ([ string characterAtIndex:z ] == 'i' || [ string characterAtIndex:z ] == 'd')
			{
				double* ret = (double*)&data;
				[ final appendFormat:@"%i", (int)(*ret) ];
			}
			else if ([ string characterAtIndex:z ] == 'f')
			{
				double* ret = (double*)&data;
				[ final appendFormat:@"%f", (float)(*ret) ];
			}
			else if ([ string characterAtIndex:z ] == 'e')
			{
				double* ret = (double*)&data;
				[ final appendFormat:@"%e", (double)(*ret) ];
			}
			else if ([ string characterAtIndex:z ] == 'E')
			{
				double* ret = (double*)&data;
				[ final appendFormat:@"%E", (double)(*ret) ];
			}
			else if ([ string characterAtIndex:z ] == 's')
			{
				char* ret = (char*)data;
				[ final appendFormat:@"%s", ret ];
			}
			else if ([ string characterAtIndex:z ] == '@')
			{
				id ret = data;
				[ final appendFormat:@"%@", ret ];
			}
			else if ([ string characterAtIndex:z ] == 'x')
			{
				double* ret = (double*)&data;
				[ final appendFormat:@"%x", (unsigned int)(*ret) ];
			}
			else if ([ string characterAtIndex:z ] == 'X')
			{
				double* ret = (double*)&data;
				[ final appendFormat:@"%X", (unsigned int)(*ret) ];
			}
			else if ([ string characterAtIndex:z ] == '%')
			{
				[ final appendFormat:@"%%" ];
				argPointer--;
			}
		}
		else
			[ final appendFormat:@"%c", [ string characterAtIndex:z ] ];
	}
}

NSNumber* ValueForNumber(id num)
{
	const char* type = lastType;
	if (strcmp(type, "B") == 0)		// BOOL
	{
		
		BOOL* arg = (BOOL*)&num;
		return [ NSNumber numberWithBool:*arg ];
	}
	else if (strcmp(type, "c") == 0 || strcmp(type, "C") == 0)	// char
	{
		
		char* arg = (char*)&num;
		return [ NSNumber numberWithChar:*arg ];
	}
	else if (strcmp(type, "s") == 0 || strcmp(type, "S") == 0)	// short
	{
		
		short* arg = (short*)&num;
		return [ NSNumber numberWithShort:*arg ];
	}
	else if (strcmp(type, "i") == 0 || strcmp(type, "I") == 0)	// int
	{
		
		int* arg = (int*)&num;
		return [ NSNumber numberWithInt:*arg ];
	}
	else if (strcmp(type, "l") == 0 || strcmp(type, "L") == 0)	// long
	{
		
		long* arg = (long*)&num;
		return [ NSNumber numberWithLong:*arg ];
	}
	else if (strcmp(type, "q") == 0 || strcmp(type, "Q") == 0)	// long long
	{
		
		long long* arg = (long long*)&num;
		return [ NSNumber numberWithLongLong:*arg ];
	}
	else if (strcmp(type, "f") == 0)	// float
	{
		
		float* arg = (float*)&num;
		return [ NSNumber numberWithFloat:*arg ];
	}
	else	// double (make this default)
	{
		
		double* arg = (double*)&num;
		return [ NSNumber numberWithDouble:*arg ];
	}
	return [ NSNumber numberWithInt:0 ];
}

unsigned long ExecuteBlock(NSMutableString* string, BOOL ret)
{
	// Execute block {} and the next line if given because the line will be messed up otherwise
	char cmd = 0;
	int quantity = 1;
	unsigned long pos = PositionAfterSpaces(string, 0);
	if ([ string characterAtIndex:pos ] != '{')
		return 0;
	pos = PositionAfterSpaces(string, pos + 1);
	unsigned long start = pos;
	// Search for matching '}'
	while (cmd != '}' || quantity != 0)
	{
		cmd = [ string characterAtIndex:pos++ ];
		if (pos >= [ string length ])
			break;
		if (cmd == '{')
			quantity++;
		else if (cmd == '}')
			quantity--;
	}
	pos = PositionBeforeSpaces(string, pos - 1);
	
	// Compile
	NSMutableArray* array = [ [ NSMutableArray alloc ] initWithArray:[ [ string substringWithRange:NSMakeRange(start, pos - start) ]componentsSeparatedByString:@";" ] ];
	[ array removeObject:[ array lastObject ] ];
	if (ret)
		CompileShapeSettings(array, variables[0].obj);
	unsigned long count = [ array count ];
	[ array release ];
	array = nil;
	
	pos = PositionAfterSpaces(string, pos + 1);
	if (pos >= [ string length ])
		return count;
	
	// Do only the next one
	CompileShapeSettings([ NSArray arrayWithObject:[ [ [ string substringFromIndex:pos ] componentsSeparatedByString:@";" ] objectAtIndex:0 ] ],
						 variables[0].obj);
	return count + 1;
}


NSArray* SeparatedArguementsFromString(NSString* string)
{
	NSMutableArray* array = [ NSMutableArray array ];
	unsigned long pos = 0;
	for (;;)
	{
		NSMutableString* str = [ [ NSMutableString alloc ] init ];
		
		unsigned long quantity = 0;
		for (; pos < [ string length ]; pos++)
		{
			unsigned char cmd = [ string characterAtIndex:pos ];
			if (cmd == '(')
				quantity++;
			else if (cmd == ')')
				quantity--;
			
			if (cmd == ',' && quantity == 0)
			{
				pos++;
				break;
			}
			[ str appendFormat:@"%c", cmd ];
		}
		pos = PositionAfterSpaces(string, pos);
		
		[ array addObject:str ];
		[ str release ];
		
		if (pos >= [ string length ])
			break;
	}
	return array;
}

void* CheckCMethods(NSMutableString* arguement, unsigned long* pos, unsigned int* skip, NSArray* lines)
{
	if ([ arguement hasPrefix:@"NSMakeRect(" ])		// NSRect(float, float, float, float)
	{
		if (pos)
			*pos += [ arguement length ];
		NSString* str = [ arguement substringWithRange:NSMakeRange(11, [ arguement length ] - 12) ];
		NSArray* args = [ str componentsSeparatedByString:@"," ];
		float x = [ ValueForNumber(ValueForMethod([ args objectAtIndex:0 ], NULL)) floatValue ];
		float y = [ ValueForNumber(ValueForMethod([ args objectAtIndex:1 ], NULL)) floatValue ];
		float width = [ ValueForNumber(ValueForMethod([ args objectAtIndex:2 ], NULL)) floatValue ];
		float height = [ ValueForNumber(ValueForMethod([ args objectAtIndex:3 ], NULL)) floatValue ];
		NSRect arg = NSMakeRect(x, [ variables[0].obj frame ].size.height - y - height, width, height);
		void* data = malloc(sizeof(arg));
		memcpy(data, &arg, sizeof(arg));
		return data;
	}
	else if ([ arguement hasPrefix:@"NSMakePoint(" ])	// NSPoint(float, float)
	{
		if (pos)
			*pos += [ arguement length ];
		NSString* str = [ arguement substringWithRange:NSMakeRange(12, [ arguement length ] - 13) ];
		NSArray* args = [ str componentsSeparatedByString:@"," ];
		float x = [ ValueForNumber(ValueForMethod([ args objectAtIndex:0 ], NULL)) floatValue ];
		float y = [ ValueForNumber(ValueForMethod([ args objectAtIndex:1 ], NULL)) floatValue ];
		NSPoint arg = NSMakePoint(x, [ variables[0].obj frame ].size.height - y);
		void* data = malloc(sizeof(arg));
		memcpy(data, &arg, sizeof(arg));
		return data;
	}
	else if ([ arguement hasPrefix:@"NSMakeSize(" ])	// NSSize(float, float)
	{
		if (pos)
			*pos += [ arguement length ];
		NSString* str = [ arguement substringWithRange:NSMakeRange(11, [ arguement length ] - 12) ];
		NSArray* args = [ str componentsSeparatedByString:@"," ];
		float width = [ ValueForNumber(ValueForMethod([ args objectAtIndex:0 ], NULL)) floatValue ];
		float height = [ ValueForNumber(ValueForMethod([ args objectAtIndex:1 ], NULL)) floatValue ];
		NSSize arg = NSMakeSize(width, height);
		void* data = malloc(sizeof(arg));
		memcpy(data, &arg, sizeof(arg));
		return data;
	}
	else if ([ arguement hasPrefix:@"NSLog(@" ])		// NSLog(NSString* str, ...)
	{
		if (pos)
			*pos += [ arguement length ];
		unsigned long end = [ arguement rangeOfString:@"\"" options:0 range:NSMakeRange(8, [ arguement length ] - 8) ].location;
		NSMutableString* string = [ NSMutableString stringWithString:[ arguement substringWithRange:NSMakeRange(8, end - 8) ] ];
		
		end++;
		NSMutableString* final = [ [ NSMutableString alloc ] init ];
		if (end < [ arguement length ])
		{
			// Find arguements
			NSMutableArray* args = [ [ NSMutableArray alloc ] init ];
			NSMutableString* rest = [ [ NSMutableString alloc ] initWithString:[ arguement substringFromIndex:end ] ];
			NSMutableString* buffer = [ [ NSMutableString alloc ] init ];
			// First one should be a comma (',')
			for (end = PositionAfterSpaces(rest, 1); end < [ rest length ] && [ rest characterAtIndex:end ] != ')'; end++)
			{
				if ([ rest characterAtIndex:end ] == ',')
				{
					[ args addObject:[ NSString stringWithString:buffer ] ];
					[ buffer setString:@"" ];
					end = PositionAfterSpaces(rest, end + 1) - 1;
				}
				else
					[ buffer appendFormat:@"%c", [ rest characterAtIndex:end ] ];
			}
			[ args addObject:[ NSString stringWithString:buffer ] ];
			
			FormatFunction(final, string, args);
			
			[ buffer release ];
			buffer = nil;
			[ rest release ];
			rest = nil;
			[ args release ];
			args = nil;
		}
		else
			[ final appendString:string ];
		
		
		NSLog(@"%@", final);
		
		[ final release ];
		final = nil;
	}
	else if ([ arguement hasPrefix:@"Format(@" ])		// Format(NSString* str, ...)
	{
		if (pos)
			*pos += [ arguement length ];
		unsigned long end = [ arguement rangeOfString:@"\"" options:0 range:NSMakeRange(9, [ arguement length ] - 9) ].location;
		NSMutableString* string = [ NSMutableString stringWithString:[ arguement substringWithRange:NSMakeRange(9, end - 9) ] ];
		
		end++;
		NSMutableString* final = [ NSMutableString string ];
		if (end < [ arguement length ])
		{
			// Find arguements
			NSMutableArray* args = [ [ NSMutableArray alloc ] init ];
			NSMutableString* rest = [ [ NSMutableString alloc ] initWithString:[ arguement substringFromIndex:end ] ];
			NSMutableString* buffer = [ [ NSMutableString alloc ] init ];
			int quantity = 1;
			// First one should be a comma (',')
			for (end = PositionAfterSpaces(rest, 1); end < [ rest length ] && !([ rest characterAtIndex:end ] == ')' && quantity == 0); end++)
			{
				if ([ rest characterAtIndex:end ] == ',' && quantity == 0)
				{
					[ args addObject:[ NSString stringWithString:buffer ] ];
					[ buffer setString:@"" ];
					end = PositionAfterSpaces(rest, end + 1) - 1;
				}
				else
					[ buffer appendFormat:@"%c", [ rest characterAtIndex:end ] ];
				
				if ([ rest characterAtIndex:end ] == '(')
					quantity++;
				else if ([ rest characterAtIndex:end ] == ')')
					quantity--;
			}
			[ buffer deleteCharactersInRange:NSMakeRange([ buffer length ] - 1, 1) ];
			[ args addObject:[ NSString stringWithString:buffer ] ];
			
			FormatFunction(final, string, args);
			
			[ buffer release ];
			buffer = nil;
			[ rest release ];
			rest = nil;
			[ args release ];
			args = nil;
		}
		else
			[ final appendString:string ];
		
		NSString* strFinal = [ [ NSString alloc ] initWithString:final ];
		void* data = malloc(sizeof(strFinal));
		memcpy(data, &strFinal, sizeof(strFinal));
		return data;
	}
	else if ([ arguement hasPrefix:@"Add(" ])	// double + double
	{
		if (pos)
			*pos += [ arguement length ];
		NSString* str = [ arguement substringWithRange:NSMakeRange(4, [ arguement length ] - 5) ];
		NSArray* args = SeparatedArguementsFromString(str);
		double arg1 = [ ValueForNumber(ValueForMethod([ args objectAtIndex:0 ], NULL)) doubleValue ];
		double arg2 = [ ValueForNumber(ValueForMethod([ args objectAtIndex:1 ], NULL)) doubleValue ];
		double result = arg1 + arg2;
		NSNumber* num = [ [ NSNumber alloc ] initWithDouble:result ];
		void* data = malloc(sizeof(num));
		memcpy(data, &num, sizeof(num));
		return data;
	}
	else if ([ arguement hasPrefix:@"Subtract(" ])	// double - double
	{
		if (pos)
			*pos += [ arguement length ];
		NSString* str = [ arguement substringWithRange:NSMakeRange(9, [ arguement length ] - 10) ];
		NSArray* args = SeparatedArguementsFromString(str);
		double arg1 = [ ValueForNumber(ValueForMethod([ args objectAtIndex:0 ], NULL)) doubleValue ];
		double arg2 = [ ValueForNumber(ValueForMethod([ args objectAtIndex:1 ], NULL)) doubleValue ];
		double result = arg1 - arg2;
		NSNumber* num = [ [ NSNumber alloc ] initWithDouble:result ];
		void* data = malloc(sizeof(num));
		memcpy(data, &num, sizeof(num));
		return data;
	}
	else if ([ arguement hasPrefix:@"Multiply(" ])	// double * double
	{
		if (pos)
			*pos += [ arguement length ];
		NSString* str = [ arguement substringWithRange:NSMakeRange(9, [ arguement length ] - 10) ];
		NSArray* args = SeparatedArguementsFromString(str);
		double arg1 = [ ValueForNumber(ValueForMethod([ args objectAtIndex:0 ], NULL)) doubleValue ];
		double arg2 = [ ValueForNumber(ValueForMethod([ args objectAtIndex:1 ], NULL)) doubleValue ];
		double result = arg1 * arg2;
		NSNumber* num = [ [ NSNumber alloc ] initWithDouble:result ];
		void* data = malloc(sizeof(num));
		memcpy(data, &num, sizeof(num));
		return data;
	}
	else if ([ arguement hasPrefix:@"Divide(" ])	// double / double
	{
		if (pos)
			*pos += [ arguement length ];
		NSString* str = [ arguement substringWithRange:NSMakeRange(7, [ arguement length ] - 8) ];
		NSArray* args = SeparatedArguementsFromString(str);
		double arg1 = [ ValueForNumber(ValueForMethod([ args objectAtIndex:0 ], NULL)) doubleValue ];
		double arg2 = [ ValueForNumber(ValueForMethod([ args objectAtIndex:1 ], NULL)) doubleValue ];
		double result = arg1 / arg2;
		NSNumber* num = [ [ NSNumber alloc ] initWithDouble:result ];
		void* data = malloc(sizeof(num));
		memcpy(data, &num, sizeof(num));
		return data;
	}
	else if ([ arguement hasPrefix:@"sin(" ])	// double
	{
		if (pos)
			*pos += [ arguement length ];
		NSString* str = [ arguement substringWithRange:NSMakeRange(4, [ arguement length ] - 5) ];
		double arg1 = [ ValueForNumber(ValueForMethod(str, NULL)) doubleValue ];
		double result = sin(arg1 / 180.0 * M_PI);
		NSNumber* num = [ [ NSNumber alloc ] initWithDouble:result ];
		void* data = malloc(sizeof(num));
		memcpy(data, &num, sizeof(num));
		return data;
	}
	else if ([ arguement hasPrefix:@"cos(" ])	// double
	{
		if (pos)
			*pos += [ arguement length ];
		NSString* str = [ arguement substringWithRange:NSMakeRange(4, [ arguement length ] - 5) ];
		double arg1 = [ ValueForNumber(ValueForMethod(str, NULL)) doubleValue ];
		double result = cos(arg1 / 180.0 * M_PI);
		NSNumber* num = [ [ NSNumber alloc ] initWithDouble:result ];
		void* data = malloc(sizeof(num));
		memcpy(data, &num, sizeof(num));
		return data;
	}
	else if ([ arguement hasPrefix:@"Round(" ])		// double val, int places
	{
		if (pos)
			*pos += [ arguement length ];
		NSString* str = [ arguement substringWithRange:NSMakeRange(6, [ arguement length ] - 7) ];
		NSArray* args = SeparatedArguementsFromString(str);
		double arg1 = [ ValueForNumber(ValueForMethod([ args objectAtIndex:0 ], NULL)) doubleValue ];
		int arg2 = [ ValueForNumber(ValueForMethod([ args objectAtIndex:1 ], NULL)) intValue ];
		double result = ((double)((int)((arg1 * pow(10, arg2)) + 0.5))) / pow(10, arg2);
		NSNumber* num = [ [ NSNumber alloc ] initWithDouble:result ];
		void* data = malloc(sizeof(num));
		memcpy(data, &num, sizeof(num));
		return data;
	}
	else if ([ arguement hasPrefix:@"Equal(" ])		// double, double
	{
		if (pos)
			*pos += [ arguement length ];
		NSString* str = [ arguement substringWithRange:NSMakeRange(6, [ arguement length ] - 7) ];
		NSArray* args = SeparatedArguementsFromString(str);
		double arg1 = [ ValueForNumber(ValueForMethod([ args objectAtIndex:0 ], NULL)) doubleValue ];
		double arg2 = [ ValueForNumber(ValueForMethod([ args objectAtIndex:1 ], NULL)) doubleValue ];
		double result = arg1 == arg2;
		NSNumber* num = [ [ NSNumber alloc ] initWithDouble:result ];
		void* data = malloc(sizeof(num));
		memcpy(data, &num, sizeof(num));
		return data;
	}
	else if ([ arguement hasPrefix:@"NotEqual(" ])		// double, double
	{
		if (pos)
			*pos += [ arguement length ];
		NSString* str = [ arguement substringWithRange:NSMakeRange(9, [ arguement length ] - 10) ];
		NSArray* args = SeparatedArguementsFromString(str);
		double arg1 = [ ValueForNumber(ValueForMethod([ args objectAtIndex:0 ], NULL)) doubleValue ];
		double arg2 = [ ValueForNumber(ValueForMethod([ args objectAtIndex:1 ], NULL)) doubleValue ];
		double result = arg1 != arg2;
		NSNumber* num = [ [ NSNumber alloc ] initWithDouble:result ];
		void* data = malloc(sizeof(num));
		memcpy(data, &num, sizeof(num));
		return data;
	}
	else if ([ arguement hasPrefix:@"LessThan(" ])		// double, double
	{
		if (pos)
			*pos += [ arguement length ];
		NSString* str = [ arguement substringWithRange:NSMakeRange(9, [ arguement length ] - 10) ];
		NSArray* args = SeparatedArguementsFromString(str);
		double arg1 = [ ValueForNumber(ValueForMethod([ args objectAtIndex:0 ], NULL)) doubleValue ];
		double arg2 = [ ValueForNumber(ValueForMethod([ args objectAtIndex:1 ], NULL)) doubleValue ];
		double result = arg1 < arg2;
		NSNumber* num = [ [ NSNumber alloc ] initWithDouble:result ];
		void* data = malloc(sizeof(num));
		memcpy(data, &num, sizeof(num));
		return data;
	}
	else if ([ arguement hasPrefix:@"MoreThan(" ])		// double, double
	{
		if (pos)
			*pos += [ arguement length ];
		NSString* str = [ arguement substringWithRange:NSMakeRange(9, [ arguement length ] - 10) ];
		NSArray* args = SeparatedArguementsFromString(str);
		double arg1 = [ ValueForNumber(ValueForMethod([ args objectAtIndex:0 ], NULL)) doubleValue ];
		double arg2 = [ ValueForNumber(ValueForMethod([ args objectAtIndex:1 ], NULL)) doubleValue ];
		double result = arg1 > arg2;
		NSNumber* num = [ [ NSNumber alloc ] initWithDouble:result ];
		void* data = malloc(sizeof(num));
		memcpy(data, &num, sizeof(num));
		return data;
	}
	else if ([ arguement hasPrefix:@"OR(" ])		// double, double
	{
		if (pos)
			*pos += [ arguement length ];
		NSString* str = [ arguement substringWithRange:NSMakeRange(3, [ arguement length ] - 4) ];
		NSArray* args = SeparatedArguementsFromString(str);
		double arg1 = [ ValueForMethod([ args objectAtIndex:0 ], NULL) doubleValue ];
		double arg2 = [ ValueForMethod([ args objectAtIndex:1 ], NULL) doubleValue ];
		double result = arg1 || arg2;
		NSNumber* num = [ [ NSNumber alloc ] initWithDouble:result ];
		void* data = malloc(sizeof(num));
		memcpy(data, &num, sizeof(num));
		return data;
	}
	else if ([ arguement hasPrefix:@"AND(" ])		// double, double
	{
		if (pos)
			*pos += [ arguement length ];
		NSString* str = [ arguement substringWithRange:NSMakeRange(4, [ arguement length ] - 5) ];
		NSArray* args = SeparatedArguementsFromString(str);
		double arg1 = [ ValueForMethod([ args objectAtIndex:0 ], NULL) doubleValue ];
		double arg2 = [ ValueForMethod([ args objectAtIndex:1 ], NULL) doubleValue ];
		double result = arg1 && arg2;
		NSNumber* num = [ [ NSNumber alloc ] initWithDouble:result ];
		void* data = malloc(sizeof(num));
		memcpy(data, &num, sizeof(num));
		return data;
	}
	else if ([ arguement hasPrefix:@"DrawNGon" ])	// Double, double
	{
		if (pos)
			*pos += [ arguement length ];
		NSString* str = [ arguement substringWithRange:NSMakeRange(9, [ arguement length ] - 10) ];
		NSArray* args = SeparatedArguementsFromString(str);
		double arg1 = [ ValueForNumber(ValueForMethod([ args objectAtIndex:0 ], NULL)) doubleValue ];
		double arg2 = [ ValueForNumber(ValueForMethod([ args objectAtIndex:1 ], NULL)) doubleValue ];
		if (arg1 == 0)
			return NULL;
		NSBezierPath* path = [ [ NSBezierPath alloc ] init ];
		[ path moveToPoint:NSMakePoint(210.5, arg2 + 142) ];
		for (float counter = 0; counter <= 360.0; counter += 360.0 / arg1)
			[ path lineToPoint:NSMakePoint((sin(counter / 180.0 * M_PI) * arg2 ) + 210.5, (cos(counter / 180.0 * M_PI) * arg2) + 142) ];
		[ path closePath ];
		[ [ NSColor blueColor ] set ];
		[ path fill ];
		[ path release ];
		return NULL;
	}
	else if ([ arguement hasPrefix:@"@selector(" ])	// function
	{
		unsigned long end = [ arguement rangeOfString:@")" options:0 range:NSMakeRange(10, [ arguement length ] - 10) ].location;
		NSMutableString* name = [ [ NSMutableString alloc ] initWithString:[ arguement substringWithRange:NSMakeRange(10, end - 10) ] ];
		
		// Check for all the functions
		for (int z = 0; z < functions.size(); z++)
		{
			if ([ functions[z].name isEqualToString:name ])
			{
				if (pos)
					*pos += [ arguement length ];
				[ name release ];
				name = nil;
				if ([ arguement hasSuffix:@".target" ])
				{
					id sel = functions[z];
					void* data = malloc(sizeof(sel));
					memcpy(data, &sel, sizeof(sel));
					return data;
				}
				else
				{
					SEL sel = @selector(method:);
					void* data = malloc(sizeof(sel));
					memcpy(data, &sel, sizeof(sel));
					return data;
				}
			}
		}
		NSString* type = [ [ NSString alloc ] initWithString:@"void" ];
		Function* function = [ [ Function alloc ] init ];
		function.range = RangeOfFunction(type, name, whole);
		if (function.range.length != 0)
		{
			[ function setName:name ];
			[ function setType:type ];
			functions.push_back(function);
			if (pos)
				*pos += [ arguement length ];
			[ type release ];
			type = nil;
			[ name release ];
			name = nil;
			if ([ arguement hasSuffix:@".target" ])
			{
				id sel = function;
				void* data = malloc(sizeof(sel));
				memcpy(data, &sel, sizeof(sel));
				return data;
			}
			else
			{
				SEL sel = @selector(method:);
				void* data = malloc(sizeof(sel));
				memcpy(data, &sel, sizeof(sel));
				return data;
			}
		}
		else
			[ function release ];
		[ type release ];
		type = nil;
		[ name release ];
		name = nil;
		
		return nil;
	}
	else if ([ arguement hasPrefix:@"if" ] && skip != NULL)		// if (bool)
	{
		unsigned long tpos = PositionAfterSpaces(arguement, 2);
		if ([ arguement characterAtIndex:tpos ] != '(')
			return NULL;
		//unsigned int linesToSkip = 0;
		NSMutableString* buffer = [ [ NSMutableString alloc ] init ];
		char cmd = 0;
		int quantity = 1;
		for (;;)
		{
			tpos++;
			if (tpos >= [ arguement length ])
				break;
			
			cmd = [ arguement characterAtIndex:tpos ];
			if (cmd == '(')
				quantity++;
			else if (cmd == ')')
				quantity--;
			[ buffer appendFormat:@"%c", cmd ];
			
			if (cmd == ')' && quantity == 0)
				break;
		}
		[ buffer deleteCharactersInRange:NSMakeRange([ buffer length ] - 1, 1) ];
		id ret = ValueForMethod(buffer, NULL);
		// Skip lines
		tpos = PositionAfterSpaces(arguement, tpos + 1);
		if ([ arguement characterAtIndex:tpos ] == '{')
		{
			// Calculate how many lines until '}'
			unsigned long start = tpos;
			tpos = PositionAfterSpaces(arguement, tpos + 1);
			cmd = 0;
			quantity = 1;
			unsigned int prev = *skip;
			NSMutableString* buffer = [ [ NSMutableString alloc ] init ];
			while (cmd != '}' || quantity != 0)
			{
				tpos++;
				if (tpos >= [ arguement length ])
				{
					(*skip)++;
					[ buffer appendFormat:@"%@;", [ arguement substringFromIndex:start ] ];
					if (*skip >= [ lines count ])
						break;
					[ arguement setString:[ lines objectAtIndex:*skip ] ];
					tpos = 0;
					start = 0;
				}
				cmd = [ arguement characterAtIndex:tpos ];
				if (cmd == '{')
					quantity++;
				else if (cmd == '}')
					quantity--;
			}
			// Add the next line
			if (*skip < [ lines count ])
				[ buffer appendFormat:@"%@;", [ arguement substringFromIndex:start ] ];
			*skip = prev;
			
			BOOL doesRet = ret != 0;
			(*skip) += ExecuteBlock(buffer, doesRet);
			[ buffer release ];
			buffer = nil;
		}
		else
		{
			if (ret)
				CompileShapeSettings([ NSArray arrayWithObject:[ arguement substringFromIndex:tpos ] ], variables[0].obj);
			(*skip)++;
		}
		if (pos)
			*pos += tpos;
		
		[ buffer release ];
		
		return NULL;
	}
	else	// Check User Functions
	{
		unsigned long index = [ arguement rangeOfString:@"(" ].location;
		if (index < [ arguement length ])
		{
			for (int z = 0; z < functions.size(); z++)
			{
				if ([ functions[z].name isEqualToString:[ arguement substringToIndex:index ] ])
				{
					// Compile it
					NSArray* lines = [ [ whole substringWithRange:functions[z].range ] componentsSeparatedByString:@";" ];
					CompileShapeSettings(lines, variables[0].obj);
					if (pos)
						*pos += [ arguement length ];
					return NULL;
				}
			}
		}
		NSString* type = [ [ NSString alloc ] initWithString:@"void" ];
		// Find name
		if (index < [ arguement length ])
		{
			Function* function = [ [ Function alloc ] init ];
			function.range = RangeOfFunction(type, [ arguement substringToIndex:index ], whole);
			if (function.range.length != 0)
			{
				[ function setName:[ arguement substringToIndex:index ] ];
				[ function setType:type ];
				functions.push_back(function);
				// Compile it
				NSArray* lines = [ [ whole substringWithRange:function.range ] componentsSeparatedByString:@";" ];
				CompileShapeSettings(lines, variables[0].obj);
				if (pos)
					*pos += [ arguement length ];
				[ type release ];
				return NULL;
			}
			else
				[ function release ];
		}
		
		[ type release ];
	}
	
	return NULL;
}

void* InterpretArguement(NSMutableString* arguement, NSMethodSignature* sig, unsigned int index, BOOL say)
{
	for (int t = 0; t < variables.size(); t++)
	{
		if ([ arguement isEqualToString:variables[t].name ])	// Variable
		{
			void* data = malloc(sizeof(variables[t].obj));
			memcpy(data, &variables[t].obj, sizeof(variables[t].obj));
			return data;
		}
	}
	
	if ([ arguement hasPrefix:@"@\"" ])		// NSString
	{
		NSString* arg = [ arguement substringWithRange:NSMakeRange(2, [ arguement length ] - 3) ];
		void* data = malloc(sizeof(arg));
		memcpy(data, &arg, sizeof(arguement));
		return data;
	}
	else if ([ arguement hasPrefix:@"\"" ])			// C - String
	{
		const char* arg = [ [ arguement substringWithRange:NSMakeRange(1, [ arguement length ] - 2) ] UTF8String ];
		void* data = malloc(sizeof(arg));
		memcpy(data, &arg, sizeof(arg));
		return data;
	}
	else if ([ arguement isEqualToString:@"nil" ] || [ arguement isEqualToString:@"NULL" ]) // nil / NULL
	{
		id arg = nil;
		void* data = malloc(sizeof(arg));
		memcpy(data, &arg, sizeof(arg));
		return data;
	}
	
	// BOOL
	if ([ arguement isEqualToString:@"YES" ] || [ arguement isEqualToString:@"TRUE" ] || [ arguement isEqualToString:@"true" ])
		[ arguement setString:@"1" ];
	else if ([ arguement isEqualToString:@"NO" ] || [ arguement isEqualToString:@"FALSE" ] || [ arguement isEqualToString:@"false" ])
		[ arguement setString:@"0" ];
	
	NSNumberFormatter* form = [ [ NSNumberFormatter alloc ] init ];
	NSLocale* loc = [ [ NSLocale alloc ] initWithLocaleIdentifier:@"en_US" ];
	[ form setLocale:loc ];
	if ([ form numberFromString:arguement ])		// Any number
	{
		char* type = (char*)[ sig getArgumentTypeAtIndex:index ];
		if (!type)
			type = (char*)"d";	// double
		lastType = type;
		double full = [ [ form numberFromString:arguement ] doubleValue ];
		[ loc release ];
		loc = nil;
		[ form release ];
		form = nil;
		if (strcmp(type, "B") == 0)		// BOOL
		{
			
			BOOL arg = (BOOL)full;
			void* data = malloc(sizeof(arg));
			memcpy(data, &arg, sizeof(arg));
			return data;
		}
		else if (strcmp(type, "c") == 0 || strcmp(type, "C") == 0)	// char
		{
			
			char arg = (char)full;
			void* data = malloc(sizeof(arg));
			memcpy(data, &arg, sizeof(arg));
			return data;
		}
		else if (strcmp(type, "s") == 0 || strcmp(type, "S") == 0)	// short
		{
			
			short arg = (short)full;
			void* data = malloc(sizeof(arg));
			memcpy(data, &arg, sizeof(arg));
			return data;
		}
		else if (strcmp(type, "i") == 0 || strcmp(type, "I") == 0)	// int
		{
			
			int arg = (int)full;
			void* data = malloc(sizeof(arg));
			memcpy(data, &arg, sizeof(arg));
			return data;
		}
		else if (strcmp(type, "l") == 0 || strcmp(type, "L") == 0)	// long
		{
			
			long arg = (long)full;
			void* data = malloc(sizeof(arg));
			memcpy(data, &arg, sizeof(arg));
			return data;
		}
		else if (strcmp(type, "q") == 0 || strcmp(type, "Q") == 0)	// long long
		{
			
			long long arg = (long long)full;
			void* data = malloc(sizeof(arg));
			memcpy(data, &arg, sizeof(arg));
			return data;
		}
		else if (strcmp(type, "f") == 0)	// float
		{
			
			float arg = (float)full;
			void* data = malloc(sizeof(arg));
			memcpy(data, &arg, sizeof(arg));
			return data;
		}
		else	// double (make this default)
		{
			
			double arg = (double)full;
			void* data = malloc(sizeof(arg));
			memcpy(data, &arg, sizeof(arg));
			return data;
		}
	}
	else
	{
		[ loc release ];
		loc = nil;
		[ form release ];
		form = nil;
	}
	void* realData = CheckCMethods(arguement, NULL, NULL, NULL);
	if (realData)
		return realData;
	
	if (say)	// Not really the end
	{
		// Error, arguement not defined
		NSLog(@"Compilation Error: \"%@\" not defined.", arguement);
	}
	return NULL;
}

id ValueForMethod(NSString* settings, unsigned long* pos)
{
	id ret = nil;
	void* data = InterpretArguement([ NSMutableString stringWithString:settings ], nil, 0, NO);
	if (data != NULL)
	{
		ret = ((id*)data)[0];
		free(data);
		data = NULL;
		if (pos)
			*pos += [ settings length ];
		return ret;
	}
	
	NSMutableArray* methods = [ [ NSMutableArray alloc ] init ];
	
	NSMutableString* temp = [ [ NSMutableString alloc ] initWithString:settings ];
	for (;;)
	{
		unsigned long start = [ temp rangeOfString:@"[ " ].location;
		if (start >= [ temp length ])
			break;
		[ temp replaceOccurrencesOfString:@"[ " withString:@"[" options:0 range:NSMakeRange(0, [ temp length ]) ];
	}
	for (;;)
	{
		unsigned long start = [ temp rangeOfString:@" ]" ].location;
		if (start >= [ temp length ])
			break;
		[ temp replaceOccurrencesOfString:@" ]" withString:@"]" options:0 range:NSMakeRange(0, [ temp length ]) ];
	}
	
	do
	{
		// Find next "["
		unsigned long start = [ temp rangeOfString:@"[" ].location + 1;
		if (start >= [ temp length ])
		{
			[ temp release ];
			temp = nil;
			break;
		}
		start = PositionAfterSpaces(temp, start);
		unsigned long end = [ temp rangeOfString:@"]" options:NSBackwardsSearch ].location - 1;
		if (end >= [ temp length ])
		{
			// Error - invalid [ ] combination
			NSLog(@"Compilation Error: [ and ] don't match.");
			[ temp release ];
			temp = nil;
			break;
		}
		end = PositionBeforeSpaces(temp, end);
		[ methods addObject:[ NSMutableString stringWithFormat:@"[%@]", [ temp substringWithRange:NSMakeRange(start, end - start) ] ] ];
		[ temp setString:[ temp substringWithRange:NSMakeRange(start, end - start) ] ];
	}
	while (true);
	
	std::vector<Variable> prevVar = variables;
	for (long z = [ methods count ] - 1; z >= 0; z--)
	{
		NSMutableString* sub = [ [ NSMutableString alloc ] initWithString:[ [ methods objectAtIndex:z ] substringWithRange:NSMakeRange(1, [ [ methods objectAtIndex:z ] length ] - 2) ] ];
		
		NSMutableString* buffer = [ [ NSMutableString alloc ] init ];
		NSMutableString* action = [ [ NSMutableString alloc ] init ];
		NSMutableArray* arguements = [ [ NSMutableArray alloc ] init ];
		BOOL hasTarget = FALSE;
		BOOL hasAction = FALSE;
		BOOL hasArguement = TRUE;
		BOOL inString = FALSE;
		int quantity = 0;
		id target = nil;
		for (unsigned long q = 0; q < [ sub length ]; q++)
		{
			if ([ sub characterAtIndex:q ] == '(' && !hasArguement && !inString)
				quantity++;
			else if ([ sub characterAtIndex:q ] == ')' && !hasArguement && !inString)
				quantity--;
			if ([ sub characterAtIndex:q ] == ' ' && (!hasTarget || (!hasArguement && quantity == 0 && inString == FALSE)))
			{
				if (!hasTarget)
				{
					target = NSClassFromString(buffer);
					if (!target)
					{
						// Check variables
						for (int t = 0; t < variables.size(); t++)
						{
							if ([ buffer isEqualToString:variables[t].name ])
							{
								target = variables[t].obj;
								break;
							}
						}
						// Error - target not defined
						if (!target)
						{
							NSLog(@"Compilation Error: \"%@\" not defined", buffer);
							break;
						}
					}
					hasTarget = TRUE;
					q = PositionAfterSpaces(sub, q) - 1;
				}
				else if (!hasArguement)
				{
					[ arguements addObject:[ NSMutableString stringWithString:buffer ] ];
					hasArguement = TRUE;
					hasAction = FALSE;
					q = PositionAfterSpaces(sub, q) - 1;
				}
				
				[ buffer setString:@"" ];
			}
			else if ([ sub characterAtIndex:q ] == ':' && !hasAction && hasArguement)
			{
				hasAction = TRUE;
				hasArguement = FALSE;
				[ action appendFormat:@"%@:", buffer ];
				[ buffer setString:@"" ];
				q = PositionAfterSpaces(sub, q + 1) - 1;
				
			}
			else if ([ sub characterAtIndex:q ] == ',' && hasAction && !hasArguement && quantity == 0)
			{
				[ arguements addObject:[ NSMutableString stringWithString:buffer ] ];
				[ buffer setString:@"" ];
				for (q = PositionAfterSpaces(sub, q + 1); q < [ sub length ]; q++)
				{
					if ([ sub characterAtIndex:q ] == ',')
					{
						[ arguements addObject:[ NSMutableString stringWithString:buffer ] ];
						[ buffer setString:@"" ];
						q = PositionAfterSpaces(sub, q + 1) - 1;
					}
					else
						[ buffer appendFormat:@"%c", [ sub characterAtIndex:q ] ];
				}
				[ arguements addObject:[ NSString stringWithString:buffer ] ];
				break;
			}
			else
			{
				if (!inString && ([ sub characterAtIndex:q ] == '"' || ((q + 1 < [ sub length ] && [ sub characterAtIndex:q ] == '@' && [ sub characterAtIndex:q + 1 ] == '"'))))
				{
					inString = TRUE;
					if ([ sub characterAtIndex:q ] == '@')
					{
						[ buffer appendFormat:@"%c%c", [ sub characterAtIndex:q ], [ sub characterAtIndex:q + 1 ] ];
						q++;
					}
					else
						[ buffer appendFormat:@"%c", [ sub characterAtIndex:q ] ];
					continue;
				}
				if (q + 1 < [ sub length ] && [ sub characterAtIndex:q ] == '\\')
				{
					[ buffer appendString:[ NSString stringWithFormat:@"\%c", [ sub characterAtIndex:q + 1 ] ] ];
					q++;
					continue;
				}
				if (inString && [ sub characterAtIndex:q ] == '"')
					inString = FALSE;
				
				[ buffer appendFormat:@"%c", [ sub characterAtIndex:q ] ];
			}
		}
		if ([ buffer length ] != 0 && !hasAction && hasArguement)
			[ action appendFormat:@"%@", buffer ];
		else if ([ buffer length ] != 0 && hasAction && !hasArguement)
			[ arguements addObject:[ NSMutableString stringWithString:buffer ] ];
		
		SEL sel = NSSelectorFromString(action);
		if (target && [ target respondsToSelector:sel ])
		{
			NSInvocation* invoc = [ NSInvocation invocationWithMethodSignature:[ target methodSignatureForSelector:sel ] ];
			[ invoc setTarget:target ];
			[ invoc setSelector:sel ];
			for (int m = 0; m < [ arguements count ]; m++)
			{
				void* temp = InterpretArguement([ arguements objectAtIndex:m ], [ target methodSignatureForSelector:sel ], m + 2, YES);
				[ invoc setArgument:temp atIndex:2 + m ];
				free(temp);
				temp = NULL;
			}
			[ invoc invoke ];
			id rets = nil;
			lastType = (char*)[ [ target methodSignatureForSelector:sel ] methodReturnType ];
			if (strcmp(lastType, "v") != 0 && strcmp(lastType, "Vv") != 0 && lastType != 0)
				[ invoc getReturnValue:&rets ];
			
			// Make this a variable
			Variable var;
			memset(&var, 0, sizeof(var));
			//var.objClass = [ rets class ];
			var.obj = rets;
			var.name = [ NSString stringWithFormat:@"Var%li", z ];
			for (long m = z - 1; m >= 0; m--)
			{
				// Replace this string with the variable
				[ [ methods objectAtIndex:m ] replaceOccurrencesOfString:[ NSString stringWithFormat:@"[%@]", sub ] withString:var.name options:0 range:NSMakeRange(0, [ [ methods objectAtIndex:m ] length ]) ];
			}
			BOOL exists = FALSE;
			for (int z = 0; z < variables.size(); z++)
			{
				if ([ variables[z].name isEqualToString:var.name ])
				{
					if (variables[z].obj && z != 0 && variables[z].objClass)
						[ variables[z].obj release ];
					if (variables[z].name)
						[ variables[z].name release ];
					variables[z] = var;
					exists = TRUE;
					break;
				}
			}
			if (!exists)
				variables.push_back(var);
		}
		else
			NSLog(@"Compilation Error: \"%@\" does not respond to \"%@\".", target, action);
		
		[ action release ];
		action = nil;
		[ buffer release ];
		buffer = nil;
		[ arguements release ];
		arguements = nil;
		
		[ sub release ];
		sub = nil;
	}
	ret = variables[variables.size() - 1].obj;
	variables = prevVar;
	if (pos)
		*pos += [ settings length ];
	[ methods release ];
	methods = nil;
	
	return ret;
}

void CompileShapeSettings(NSArray* array, NSView* view)
{
	for (unsigned int lineNumber = 0; lineNumber < [ array count ]; lineNumber++)
	{
		NSString* settings = [ array objectAtIndex:lineNumber ];
		NSMutableString* buffer = [ [ NSMutableString alloc ] init ];
		
		unsigned int last = lineNumber;
		unsigned long tempZ = 0;
		tempZ = PositionAfterSpaces(settings, tempZ);
		void* tempData = CheckCMethods([ NSMutableString stringWithString:[ settings substringFromIndex:tempZ ] ], &tempZ, &lineNumber, array);
		free(tempData);
		tempData = nil;
		if (last != lineNumber)
		{
			lineNumber--;
			[ buffer release ];
			continue;
		}
		
		BOOL defining = FALSE;
		id currentClass = nil;
		for (unsigned long z = tempZ; z < [ settings length ]; z++)
		{
			if ([ settings characterAtIndex:z ] == '[')
				ValueForMethod([ settings substringFromIndex:z ], &z);
			else if ([ settings characterAtIndex:z ] == ' ')
			{
				if (defining)
				{
					// Buffer should be the name of the variable
					Variable var;
					memset(&var, 0, sizeof(var));
					var.objClass = currentClass;
					var.name = [ [ NSString alloc ] initWithString:buffer ];
					[ buffer setString:@"" ];
					
					// Check if setting the value already
					unsigned long pos = PositionAfterSpaces(settings, z);
					if ([ settings characterAtIndex:pos ] == '=')
					{
						pos = PositionAfterSpaces(settings, pos + 1);
						var.obj = ValueForMethod([ settings substringFromIndex:pos ], &pos);
						z = pos;
					}
					currentClass = NULL;
					
					// Check if name already exists
					BOOL exists = FALSE;
					for (int z = 0; z < variables.size(); z++)
					{
						if ([ variables[z].name isEqualToString:var.name ])
						{
							if (variables[z].obj && z != 0 && variables[z].objClass)
								[ variables[z].obj release ];
							if (variables[z].name)
								[ variables[z].name release ];
							variables[z] = var;
							exists = TRUE;
							break;
						}
					}
					if (!exists)
						variables.push_back(var);
					defining = FALSE;
				}
				else
				{
					// Check if class
					if ([ buffer hasSuffix:@"*" ])
					{
						[ buffer deleteCharactersInRange:NSMakeRange([ buffer length ] - 1, 1) ];
						defining = TRUE;
					}
					else	// Check if has * next
					{
						unsigned long pos = PositionAfterSpaces(settings, z);
						defining = ([ settings characterAtIndex:pos ] == '*');
					}
					id obj = NSClassFromString(buffer);
					if (!obj)
					{
						// Check if variable
						for (int q = 0; q < variables.size(); q++)
						{
							if ([ buffer isEqualToString:variables[q].name ])
							{
								// Yep
								unsigned long pos = z;
								pos = PositionAfterSpaces(settings, z);
								if ([ settings characterAtIndex:pos ] == '=')
								{
									pos = PositionAfterSpaces(settings, pos + 1);
									variables[q].obj = ValueForMethod([ settings substringFromIndex:pos ], &pos);
									z = pos;
								}
								break;
							}
						}
					}
					else
						currentClass = obj;
				}
				
				z = PositionAfterSpaces(settings, z) - 1;
				[ buffer setString:@"" ];
			}
			else
				[ buffer appendFormat:@"%c", [ settings characterAtIndex:z ] ];
			
			if ([ buffer isEqualToString:@"@end\n" ])
				break;
		}
		if (defining)
		{
			// Buffer should be the name of the variable
			Variable var;
			memset(&var, 0, sizeof(var));
			var.name = [ [ NSString alloc ] initWithString:buffer ];
			BOOL exists = FALSE;
			for (int z = 0; z < variables.size(); z++)
			{
				if ([ variables[z].name isEqualToString:var.name ])
				{
					if (variables[z].obj && z != 0 && variables[z].objClass)
						[ variables[z].obj release ];
					if (variables[z].name)
						[ variables[z].name release ];
					variables[z] = var;
					exists = TRUE;
					break;
				}
			}
			if (!exists)
				variables.push_back(var);
		}
		
		[ buffer release ];
		buffer = nil;
	}
}

void OpenValues(NSString* save)
{
	NSArray* componets = [ save componentsSeparatedByString:@"\n" ];
	for (int z = 0; z < [ componets count ]; z++)
	{
		NSString* str = [ [ NSString alloc ] initWithString:[ componets objectAtIndex:z ] ];
		if ([ str length ] == 0)
		{
			[ str release ];
			continue;
		}
		unsigned long loc = 0;
		NSMutableString* value = [ [ NSMutableString alloc ] init ];
		NSString* name = nil;
		for (unsigned long q = loc; q < [ [ componets objectAtIndex:z ] length ]; q++)
		{
			if ([ [ componets objectAtIndex:z ] characterAtIndex:q ] == ' ')
			{
				name = [ [ NSString alloc ] initWithString:value ];
				[ value setString:@"" ];
				loc = q + 3;
				break;
			}
			else
				[ value appendFormat:@"%c", [ [ componets objectAtIndex:z ] characterAtIndex:q ] ];
		}
		
		int quantityp = 0;
		int quantityb = 0;
		for (unsigned long q = loc; q < [ str length ]; q++)
		{
			if ([ str characterAtIndex:q ] == '(')
				quantityp++;
			else if ([ str characterAtIndex:q ] == ')')
				quantityp--;
			else if ([ str characterAtIndex:q ] == '[')
				quantityb++;
			else if ([ str characterAtIndex:q ] == ']')
				quantityb--;
			else if ([ str characterAtIndex:q ] == ' ' && quantityb == 0 && quantityp == 0)
			{
				ValueForMethod(value, NULL);
				[ value setString:@"" ];
				break;
			}
			
			[ value appendFormat:@"%c", [ str characterAtIndex:q ] ];
		}
		
		Variable var;
		memset(&var, 0, sizeof(var));
		var.name = name;
		var.obj = ValueForMethod(value, NULL);
		
		BOOL exists = FALSE;
		for (int z = 0; z < variables.size(); z++)
		{
			if ([ variables[z].name isEqualToString:var.name ])
			{
				if (variables[z].obj && z != 0 && variables[z].objClass)
					[ variables[z].obj release ];
				if (variables[z].name)
					[ variables[z].name release ];
				variables[z] = var;
				exists = TRUE;
				break;
			}
		}
		if (!exists)
			variables.push_back(var);
		
		[ value release ];
		value = nil;
		[ str release ];
		str = nil;
	}
}

void SaveValues(NSString* save, FILE* file, NSString* path)
{
	fseek(file, 0, SEEK_END);
	unsigned long size = ftell(file);
	rewind(file);
	char* data = (char*)malloc(size + 1);
	memset(data, 0, size + 1);
	fread(data, 1, size + 1, file);
	NSMutableString* str = [ [ NSMutableString alloc ] initWithUTF8String:(const char*)data ];
	unsigned long loc = NSMaxRange([ str rangeOfString:@"@end\n" ]);
	[ str setString:[ str substringToIndex:loc ] ];
	free(data);
	data = NULL;
	
	NSArray* componets = [ save componentsSeparatedByString:@"\n" ];
	for (int z = 0; z < [ componets count ]; z++)
	{
		if (z != 0)
			[ str appendFormat:@"\n" ];
		NSString* string = [ [ NSString alloc ] initWithString:[ componets objectAtIndex:z ] ];
		loc = 0;
		NSMutableString* value = [ [ NSMutableString alloc ] init ];
		NSString* name = nil;
		for (unsigned long q = loc; q < [ [ componets objectAtIndex:z ] length ]; q++)
		{
			if ([ [ componets objectAtIndex:z ] characterAtIndex:q ] == ' ')
			{
				name = [ [ NSString alloc ] initWithString:value ];
				[ value setString:@"" ];
				loc = q + 3;
				break;
			}
			else
				[ value appendFormat:@"%c", [ [ componets objectAtIndex:z ] characterAtIndex:q ] ];
		}
		
		int quantityp = 0;
		int quantityb = 0;
		for (unsigned long q = loc; q < [ string length ]; q++)
		{
			if ([ string characterAtIndex:q ] == '(')
				quantityp++;
			else if ([ string characterAtIndex:q ] == ')')
				quantityp--;
			else if ([ string characterAtIndex:q ] == '[')
				quantityb++;
			else if ([ string characterAtIndex:q ] == ']')
				quantityb--;
			else if ([ string characterAtIndex:q ] == ' ' && quantityb == 0 && quantityp == 0)
			{
				[ value setString:@"" ];
				break;
			}
			[ value appendFormat:@"%c", [ string characterAtIndex:q ] ];
		}
		id finalValue = nil;
		for (int z = 0; z < variables.size(); z++)
		{
			if ([ variables[z].name isEqualToString:name ])
			{
				finalValue = variables[z].obj;
				break;
			}
		}
		double* val = (double*)&finalValue;
		[ str appendFormat:@"%@ = %f", name, (double)(*val) ];
		[ name release ];
		name = nil;
		[ value release ];
		value = nil;
		[ string release ];
		string = nil;
	}
	
	fclose(file);
	file = fopen([ path UTF8String ], "w");
	fwrite([ str UTF8String ], 1, [ str length ], file);
	
	[ str release ];
	str = nil;
}

void ReleaseShapeSettings()
{
	if (updateTimer)
	{
		[ updateTimer invalidate ];
		updateTimer = nil;
	}
	
	for (int z = 0; z < variables.size(); z++)
	{
		if (variables[z].obj && z != 0 && variables[z].objClass)
			[ variables[z].obj release ];
		if (variables[z].name)
			[ variables[z].name release ];
	}
	variables.clear();
	
	for (int z = 0; z < functions.size(); z++)
	{
		if (functions[z])
		{
			[ functions[z] release ];
			functions[z] = nil;
		}
	}
	functions.clear();
	
	if (currentFile)
	{
		[ currentFile release ];
		currentFile = nil;
	}
	if (currentDraw)
	{
		[ currentDraw release ];
		currentDraw = nil;
	}
	if (whole)
	{
		[ whole release ];
		whole = nil;
	}
}
