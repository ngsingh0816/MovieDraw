//
//  MDCollada.m
//  MovieDraw
//
//  Created by Neil on 3/16/13.
//  Copyright (c) 2013 Neil. All rights reserved.
//

#import "MDCollada.h"
#import "MDObjectTools.h"

unsigned long PosToSpaces(NSString* string, unsigned long pos)
{
	if ([ string length ] <= pos)
		return pos;
	while ([ string characterAtIndex:pos ] != ' ')
	{
		pos++;
		if ([ string length ] <= pos)
			return pos;
	}
	return pos;
}

unsigned long PosAfterSpaces(NSString* string, unsigned long pos)
{
	if ([ string length ] <= pos)
		return pos;
	while ([ string characterAtIndex:pos ] == ' ')
	{
		pos++;
		if ([ string length ] <= pos)
			return pos;
	}
	return pos;
}

@interface MDCollada (Parser)

- (NSString*) currentElement;
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict;
- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName;
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string;

@end

@implementation MDCollada

- (id) init
{
	if (self = [ super init ])
		return self;
	return nil;
}

- (MDObject*) objectFromFile:(NSString*)file
{
	NSFileHandle* handle = [ NSFileHandle fileHandleForReadingAtPath:file ];
	if (!handle)
		return nil;
	
	NSXMLParser* parser = [ [ NSXMLParser alloc ] initWithData:[ handle readDataToEndOfFile ] ];
	[ handle closeFile ];
	
	elements = [ [ NSMutableArray alloc ] init ];
	objects = [ [ NSMutableArray alloc ] init ];
	sources = [ [ NSMutableArray alloc ] init ];
	vertices = [ [ NSMutableArray alloc ] init ];
	polylists = [ [ NSMutableArray alloc ] init ];
	materials = [ [ NSMutableArray alloc ] init ];
	images = [ [ NSMutableArray alloc ] init ];
	loadingFile = [ [ NSString alloc ] initWithString:file ];
	currentGeo = [ [ NSString alloc ] init ];
	
	[ parser setDelegate:(id)self ];
	[ parser parse ];
		
	NSString* currentObj = [ NSString string ];
	
	//if ([ elementName isEqualToString:@"polylist" ])
	for (unsigned long poly = 0; poly < [ polylists count ]; poly++)
	{		
		NSDictionary* dict = [ polylists objectAtIndex:poly ];
		
		if (![ [ dict objectForKey:@"object" ] isEqualToString:currentObj ])
		{
			if ([ objects count ] != 0)
			{
				NSArray* translates = nil;
				for (unsigned long z = 0; z < [ nodes count ]; z++)
				{
					if ([ [ [ nodes objectAtIndex:z ] objectForKey:@"mesh" ] isEqualToString:currentObj ])
					{
						translates = [ [ nodes objectAtIndex:z ] objectForKey:@"translates" ];
						break;
					}
				}
				MDObject* obj = [ objects lastObject ];
				for (unsigned long z = 0; z < [ translates count ]; z++)
				{
					NSString* type = [ [ translates objectAtIndex:z ] objectForKey:@"type" ];
					float x = [ [ [ translates objectAtIndex:z ] objectForKey:@"X" ] floatValue ];
					float y = [ [ [ translates objectAtIndex:z ] objectForKey:@"Y" ] floatValue ];
					float z1 = [ [ [ translates objectAtIndex:z ] objectForKey:@"Z" ] floatValue ];
					if ([ type isEqualToString:@"rotate" ])
					{
						float a = [ [ [ translates objectAtIndex:z ] objectForKey:@"Angle" ] floatValue ];
						obj.rotateX = a * x;
						obj.rotateY = a * y;
						obj.rotateZ = a * z1;
					}
					else if ([ type isEqualToString:@"translate" ])
					{
						obj.translateX = x;
						obj.translateY = y;
						obj.translateZ = z1;
					}
					else if ([ type isEqualToString:@"scale" ])
					{
						obj.scaleX = x;
						obj.scaleY = y;
						obj.scaleZ = z1;
					}
					obj = ApplyTransformations(obj);
					[ objects replaceObjectAtIndex:[ objects count ] - 1 withObject:obj ];
					[ obj release ];
				}
			}
			[ objects addObject:[ [ [ MDObject alloc ] init ] autorelease ] ];
			currentObj = [ NSString stringWithString:[ dict objectForKey:@"object" ] ];
		}
		
		unsigned long faceCount = [ [ dict objectForKey:@"count" ] unsignedLongValue ];
		
		unsigned int drawType = 0;
		unsigned int countMult = 1;
		NSString* polyType = [ dict objectForKey:@"type" ];
		if ([ polyType isEqualToString:@"lines" ])
		{
			drawType = GL_LINES;
			countMult = 2;
		}
		else if ([ polyType isEqualToString:@"linestrips" ])
			drawType = GL_LINES;
		else if ([ polyType isEqualToString:@"polygons" ])	// need to use tesselator
			drawType = GL_POLYGON;
		else if ([ polyType isEqualToString:@"polylist" ])
			drawType = GL_POLYGON;
		else if ([ polyType isEqualToString:@"triangles" ])
		{
			drawType = GL_TRIANGLES;
			countMult = 3;
		}
		else if ([ polyType isEqualToString:@"trifans" ])
			drawType = GL_TRIANGLE_FAN;
		else if ([ polyType isEqualToString:@"tristrips" ])
			drawType = GL_TRIANGLE_STRIP;
		
		NSDictionary* material = nil;
		for (unsigned long z = 0; z < [ materials count ]; z++)
		{
			if ([ [ [ materials objectAtIndex:z ] objectForKey:@"id" ] isEqualToString:[ dict objectForKey:@"material" ] ])
			{
				material = [ materials objectAtIndex:z ];
				BOOL found = FALSE;
				for (unsigned long q = 0; q < [ sources count ]; q++)
				{
					if ([ [ material objectForKey:@"effect" ] isEqualToString:[ [ sources objectAtIndex:q ] objectForKey:@"id" ] ])
					{
						found = TRUE;
						material = [ [ sources objectAtIndex:q ] objectForKey:@"effect" ];
						break;
					}
				}
				if (!found)
					material = nil;
				break;
			}
		}
		
		NSMutableArray* facePointCount = [ dict objectForKey:@"vcount" ];
		if ([ facePointCount count ] == 0)
		{
			[ facePointCount addObject:[ NSNumber numberWithUnsignedLong:faceCount * countMult ] ];
			faceCount = 1;
		}
		unsigned int* indexData = (unsigned int*)[ [ dict objectForKey:@"p" ] bytes ];
		unsigned long indexCount = [ [ dict objectForKey:@"p" ] length ] / sizeof(unsigned int);
		
		float* vertexData = NULL;
		unsigned long vertexOffset = 0;
		float* normalData = NULL;
		unsigned long normalOffset = 0;
		float* textureData = NULL;
		unsigned long textureOffset = 0;
		
		NSArray* inputs = [ dict objectForKey:@"inputs" ];
		for (unsigned long z = 0; z < [ inputs count ]; z++)
		{
			NSDictionary* inDict = [ inputs objectAtIndex:z ];
			if ([ [ inDict objectForKey:@"semantic" ] isEqualToString:@"VERTEX" ])
			{
				NSMutableArray* dict2 = [ [ inDict objectForKey:@"source" ] objectForKey:@"source" ];
				for (unsigned long q = 0; q < [ dict2 count ]; q++)
				{
					if ([ [ [ dict2 objectAtIndex:q ] objectForKey:@"semantic" ] isEqualToString:@"POSITION" ])
					{
						vertexData = (float*)[ [ [ [ dict2 objectAtIndex:q ] objectForKey:@"source" ] objectForKey:@"data" ] bytes ];
						vertexOffset = [ [ inDict objectForKey:@"offset" ] unsignedLongValue ];
					}
					else if ([ [ [ dict2 objectAtIndex:q ] objectForKey:@"semantic" ] isEqualToString:@"NORMAL" ])
					{
						normalData = (float*)[ [ [ [ dict2 objectAtIndex:q ] objectForKey:@"source" ] objectForKey:@"data" ] bytes ];
						normalOffset = [ [ inDict objectForKey:@"offset" ] unsignedLongValue ];
					}
					else if ([ [ [ dict2 objectAtIndex:q ] objectForKey:@"semantic" ] isEqualToString:@"TEXCOORD" ])
					{
						textureData = (float*)[ [ [ [ dict2 objectAtIndex:q ] objectForKey:@"source" ] objectForKey:@"data" ] bytes ];
						textureOffset = [ [ inDict objectForKey:@"offset" ] unsignedLongValue ];
					}
				}
				continue;
			}
			else if ([ [ inDict objectForKey:@"semantic" ] isEqualToString:@"POSITION" ])
			{
				vertexData = (float*)[ [ [ inDict objectForKey:@"source" ] objectForKey:@"data" ] bytes ];
				vertexOffset = [ [ inDict objectForKey:@"offset" ] unsignedLongValue ];
				continue;
			}
			else if ([ [ inDict objectForKey:@"semantic" ] isEqualToString:@"NORMAL" ])
			{
				normalData = (float*)[ [ [ inDict objectForKey:@"source" ] objectForKey:@"data" ] bytes ];
				normalOffset = [ [ inDict objectForKey:@"offset" ] unsignedLongValue ];
				continue;
			}
			else if ([ [ inDict objectForKey:@"semantic" ] isEqualToString:@"TEXCOORD" ])
			{
				textureData = (float*)[ [ [ inDict objectForKey:@"source" ] objectForKey:@"data" ] bytes ];
				textureOffset = [ [ inDict objectForKey:@"offset" ] unsignedLongValue ];
				continue;
			}
		}
		
		MDObject* obj = [ objects lastObject ];
		unsigned long pointIndex = 0;
		unsigned long highest = 0;
		if (highest < vertexOffset)
			highest = vertexOffset;
		if (highest < normalOffset)
			highest = normalOffset;
		if (highest < textureOffset)
			highest = textureOffset;
		highest++;
		for (unsigned long z = 0; z < faceCount; z++)
		{
			MDFace* face = [ [ MDFace alloc ] init ];
			
			[ face setDrawMode:drawType ];
			if ([ facePointCount count ] <= z)
			{
				[ face release ];
				break;
			}
			
			unsigned long pointCount = [ [ facePointCount objectAtIndex:z ] unsignedLongValue ] * highest;
			for (unsigned long q = 0; q < pointCount; q += highest)
			{
				if (indexCount <= (q + pointIndex))	// maybe q + pointIndex + 1
					break;
				unsigned long vIndex = 0;
				if (vertexData)
					vIndex = indexData[q + pointIndex + vertexOffset] * 3;//[ [ indexData objectAtIndex:(q + pointIndex + vertexOffset) ] unsignedLongValue ] * 3;
				unsigned long nIndex = 0;
				if (normalData)
					nIndex = indexData[q + pointIndex + normalOffset] * 3;//[ [ indexData objectAtIndex:(q + pointIndex + normalOffset) ] unsignedLongValue ] * 3;
				unsigned long tIndex = 0;
				if (textureData)
					tIndex = indexData[q + pointIndex + textureOffset] * 2;//[ [ indexData objectAtIndex:(q + pointIndex + textureOffset) ] unsignedLongValue ] * 2;
				MDPoint* p = [ [ MDPoint alloc ] init ];
				
				
				// This reverses Y and Z
				if (vertexData)
				{
					p.x = vertexData[vIndex];
					p.z = vertexData[vIndex + 1];
					p.y = vertexData[vIndex + 2];
				}
				if (normalData)
				{
					p.normalX = normalData[nIndex];
					p.normalZ = normalData[nIndex + 1];
					p.normalY = normalData[nIndex + 2];
				}
				if (textureData)
				{
					p.textureCoordX = textureData[tIndex];
					p.textureCoordY = textureData[tIndex + 1];
				}
				
				if (material)
				{
					p.red = [ [ [ material objectForKey:@"diffuse" ] objectForKey:@"Red" ] floatValue ];
					p.green = [ [ [ material objectForKey:@"diffuse" ] objectForKey:@"Green" ] floatValue ];
					p.blue = [ [ [ material objectForKey:@"diffuse" ] objectForKey:@"Blue" ] floatValue ];
					p.alpha = [ [ [ material objectForKey:@"diffuse" ] objectForKey:@"Alpha" ] floatValue ];
				}
				else
				{
					p.red = 0.3;
					p.green = 0.3;
					p.blue = 0.3;
					p.alpha = 1;
				}
				
				[ face addPoint:p ];
				[ p release ];
			}
			pointIndex += pointCount;
			
			if (material && [ material objectForKey:@"image" ])
			{
				NSString* imageId = [ material objectForKey:@"image" ];
				NSMutableString* path = nil;
				for (unsigned long q = 0; q < [ images count ]; q++)
				{
					if ([ [ [ images objectAtIndex:q ] objectForKey:@"id" ] isEqualToString:imageId ])
						path = [ NSMutableString stringWithString:[ [ images objectAtIndex:q ] objectForKey:@"path" ] ];
				}
				if (path)
				{
					BOOL add = YES;
					for (;;)
					{
						NSRange range = [ path rangeOfString:@"../" ];
						if (range.length == 0)
							break;
						unsigned int quantity = 0;
						while (range.location != 0 && range.location < [ path length ] && NSMaxRange(range) < [ path length ])
						{
							char cmd = [ path characterAtIndex:range.location ];
							if (cmd == '/')
							{
								quantity++;
								if (quantity == 2)
								{
									range.location++;
									range.length--;
									break;
								}
							}
							range.location--;
							range.length++;
						}
						if (range.location < [ path length ] && NSMaxRange(range) < [ path length ])
							[ path deleteCharactersInRange:range ];
						else
						{
							add = NO;
							break;
						}
					}
					if (add)
						[ face addProperty:path forKey:@"Texture" ];
				}
			}
			
			[ obj addFace:face ];
			[ face release ];
		}
		
		// For now
		/*obj.scaleX = 1 / 50.0;
		obj.scaleY = 1 / 50.0;
		obj.scaleZ = 1 / 50.0;*/
	}
	
	[ parser release ];
	[ elements release ];
	elements = nil;
	[ sources release ];
	sources = nil;
	[ vertices release ];
	vertices = nil;
	[ polylists release ];
	polylists = nil;
	[ materials release ];
	materials = nil;
	[ images release ];
	images = nil;
	[ loadingFile release ];
	loadingFile = nil;
	[ currentGeo release ];
	currentGeo = nil;
	
	if ([ objects count ] == 0)
	{
		[ objects release ];
		objects = nil;
		
		return nil;
	}
	
	MDObject* realObj = [ [ MDObject alloc ] init ];
	for (unsigned long z = 0; z < [ objects count ]; z++)
	{
		for (unsigned long y = 0; y < [ [ objects objectAtIndex:z ] numberOfFaces ]; y++)
			[ realObj addFace:[ [ objects objectAtIndex:z ] faceAtIndex:y ] ];
	}
	[ objects removeAllObjects ];
	[ objects addObject:realObj ];
	[ realObj release ];
	
	[ [ objects objectAtIndex:0 ] setMidPoint:MakeThreePoint(0, 0, 0) ];
	MDRect rect = BoundingBoxRotate([ objects objectAtIndex:0 ]);
	float scale = 1;
	if (rect.width > 10 || rect.height > 10 || rect.depth > 10)
	{
		float biggest = rect.width;
		if (biggest < rect.height)
			biggest = rect.height;
		if (biggest < rect.depth)
			biggest = rect.depth;
		if (biggest == 0)
			scale = 1;
		scale = 10.0 / biggest;
	}
	[ [ objects objectAtIndex:0 ] setScaleX:scale ];
	[ [ objects objectAtIndex:0 ] setScaleY:scale ];
	[ [ objects objectAtIndex:0 ] setScaleZ:scale ];
	MDObject* obj2 = ApplyTransformations([ objects objectAtIndex:0 ]);
	[ objects replaceObjectAtIndex:0 withObject:obj2 ];
	[ obj2 release ];
	
	MDObject* obj = [ [ MDObject alloc ] initWithObject:[ objects objectAtIndex:0 ] ];
	[ objects release ];
	objects = nil;
	
	return obj;
}

- (NSString*) currentElement
{
	return [ elements lastObject ];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
	if ([ elementName isEqualToString:@"mesh" ])
	{
		/*MDObject* obj = [ [ MDObject alloc ] init ];
		[ objects addObject:obj ];
		[ obj release ];*/
	}
	else if ([ elementName isEqualToString:@"geometry" ])
	{
		if (currentGeo)
			[ currentGeo release ];
		currentGeo = [ [ NSString alloc ] initWithString:[ attributeDict objectForKey:@"id" ] ];
	}
	else if ([ elementName isEqualToString:@"source" ] && [ attributeDict objectForKey:@"id" ])
	{
		NSMutableDictionary* dict = [ NSMutableDictionary dictionaryWithObject:[ attributeDict objectForKey:@"id" ] forKey:@"id" ];
		[ sources addObject:dict ];
	}
	else if ([ elementName isEqualToString:@"material" ])
	{
		NSMutableDictionary* dict = [ NSMutableDictionary dictionaryWithObjectsAndKeys:[ attributeDict objectForKey:@"id" ], @"id", @"", @"effect", nil ];
		[ materials addObject:dict ];
	}
	else if ([ elementName isEqualToString:@"instance_effect" ])
		[ [ materials lastObject ] setObject:[ [ attributeDict objectForKey:@"url" ] substringFromIndex:1 ] forKey:@"effect" ];
	else if ([ elementName isEqualToString:@"instance_material" ])
	{
		NSString* tar = [ [ attributeDict objectForKey:@"target" ] substringFromIndex:1 ];
		for (unsigned long z = 0; z < [ materials count ]; z++)
		{
			if ([ [ [ materials objectAtIndex:z ] objectForKey:@"id" ] isEqualToString:tar ])
			{
				[ [ materials objectAtIndex:z ] setObject:[ attributeDict objectForKey:@"symbol" ] forKey:@"id" ];
				break;
			}
		}
	}
	else if ([ elementName isEqualToString:@"effect" ])
	{
		NSMutableDictionary* dict = [ NSMutableDictionary dictionaryWithObjectsAndKeys:[ attributeDict objectForKey:@"id" ], @"id", [ NSMutableDictionary dictionary ], @"effect", nil ];
		[ sources addObject:dict ];
	}
	else if ([ elementName isEqualToString:@"image" ])
	{
		//NSMutableDictionary* dict = [ NSMutableDictionary dictionaryWithObjectsAndKeys:[ attributeDict objectForKey:@"id" ], @"id", @"", @"path", [ NSNumber numberWithUnsignedInt:0 ], @"texture", nil ];
		NSMutableDictionary* dict = [ NSMutableDictionary dictionaryWithObjectsAndKeys:[ attributeDict objectForKey:@"id" ], @"id", @"", @"path", nil ];
		[ images addObject:dict ];
	}
	else if ([ elementName isEqualToString:@"texture" ])
	{
		if ([ [ elements lastObject ] isEqualToString:@"diffuse" ])
		{
			[ [ [ sources lastObject ] objectForKey:@"effect" ] setObject:[ NSMutableDictionary dictionary ] forKey:@"diffuse" ];
			NSMutableDictionary* dict = [ [ [ sources lastObject ] objectForKey:@"effect" ] objectForKey:@"diffuse" ];
			[ dict setObject:[ NSNumber numberWithFloat:1 ] forKey:@"Red" ];
			[ dict setObject:[ NSNumber numberWithFloat:1 ] forKey:@"Green" ];
			[ dict setObject:[ NSNumber numberWithFloat:1 ] forKey:@"Blue" ];
			[ dict setObject:[ NSNumber numberWithFloat:1 ] forKey:@"Alpha" ];
		}
	}
	else if ([ elementName isEqualToString:@"node" ])
	{
		NSMutableDictionary* dict = [ NSMutableDictionary dictionaryWithObjectsAndKeys:[ NSMutableArray array ], @"translates", @"", @"mesh", nil ];
		[ nodes addObject:dict ];
	}
	else if ([ elementName isEqualToString:@"instance_geometry" ])
		[ [ nodes lastObject ] setObject:[ [ attributeDict objectForKey:@"url" ] substringFromIndex:1 ] forKey:@"mesh" ];
	else if ([ elementName isEqualToString:@"float_array" ] || [ elementName isEqualToString:@"bool_array" ] || [ elementName isEqualToString:@"int_array" ])
	{
		NSDictionary* dict = [ NSDictionary dictionaryWithObjectsAndKeys:[ NSMutableDictionary dictionary ], @"data", [ NSNumber numberWithUnsignedInteger:[ [ attributeDict objectForKey:@"count" ] integerValue ] ], @"count", nil ];
		[ [ sources lastObject ] addEntriesFromDictionary:dict ];
	}
	else if ([ elementName isEqualToString:@"vertices" ])
	{
		NSMutableDictionary* dict = [ NSMutableDictionary dictionaryWithObjectsAndKeys:[ attributeDict objectForKey:@"id" ], @"id", [ NSMutableArray array ], @"source", nil ];
		[ vertices addObject:dict ];
	}
	else if ([ elementName isEqualToString:@"input" ] && [ [ self currentElement ] isEqualToString:@"vertices" ])
	{
		NSString* sourceID = [ [ attributeDict objectForKey:@"source" ] substringFromIndex:1 ];
		NSMutableDictionary* dict = nil;
		for (unsigned long z = 0; z < [ sources count ]; z++)
		{
			if ([ [ [ sources objectAtIndex:z ] objectForKey:@"id" ] isEqualToString:sourceID ])
			{
				dict = [ sources objectAtIndex:z ];
				break;
			}
		}
		[ [ [ vertices lastObject ] objectForKey:@"source" ] addObject:[ NSDictionary dictionaryWithObjectsAndKeys:dict, @"source", [ attributeDict objectForKey:@"semantic" ], @"semantic", nil ] ];
	}
	else if ([ elementName isEqualToString:@"lines" ] || [ elementName isEqualToString:@"linestrips" ] || [ elementName isEqualToString:@"polygons" ] || [ elementName isEqualToString:@"polylist" ] || [ elementName isEqualToString:@"triangles" ] || [ elementName isEqualToString:@"trifans" ] || [ elementName isEqualToString:@"tristrips" ])
	{
		unsigned long count = [ [ attributeDict objectForKey:@"count" ] integerValue ];
		NSString* mat = [ attributeDict objectForKey:@"material" ];
		if (!mat)
			mat = @"";
		
		NSMutableDictionary* dict = [ NSMutableDictionary dictionaryWithObjectsAndKeys:[ NSString stringWithString:currentGeo ], @"object", [ NSNumber numberWithUnsignedLong:count ], @"count", mat, @"material", [ NSMutableArray array ], @"inputs", [ NSMutableArray array ], @"vcount", [ NSData data ], @"p", elementName, @"type", nil ];
		[ polylists addObject:dict ];
	}
	else if ([ elementName isEqualToString:@"input" ] && ([ [ self currentElement ] isEqualToString:@"lines" ] || [ [ self currentElement ] isEqualToString:@"linestrips" ] || [ [ self currentElement ] isEqualToString:@"polygons" ] || [ [ self currentElement ] isEqualToString:@"polylist" ] || [ [ self currentElement ] isEqualToString:@"triangles" ] || [ [ self currentElement ] isEqualToString:@"trifans" ] || [ [ self currentElement ] isEqualToString:@"tristrips" ]))
	{
		NSString* semantic = [ attributeDict objectForKey:@"semantic" ];
		
		NSString* sourceID = [ [ attributeDict objectForKey:@"source" ] substringFromIndex:1 ];
		NSMutableDictionary* dict = nil;
		
		if ([ semantic isEqualToString:@"VERTEX" ])
		{
			for (unsigned long z = 0; z < [ vertices count ]; z++)
			{
				if ([ [ [ vertices objectAtIndex:z ] objectForKey:@"id" ] isEqualToString:sourceID ])
				{
					dict = [ vertices objectAtIndex:z ];
					break;
				}
			}
		}
		else if ([ semantic isEqualToString:@"NORMAL" ] || [ semantic isEqualToString:@"TEXCOORD" ])
		{
			for (unsigned long z = 0; z < [ sources count ]; z++)
			{
				if ([ [ [ sources objectAtIndex:z ] objectForKey:@"id" ] isEqualToString:sourceID ])
				{
					dict = [ sources objectAtIndex:z ];
					break;
				}
			}
		}
		
		[ [ [ polylists lastObject ] objectForKey:@"inputs" ] addObject:[ NSDictionary dictionaryWithObjectsAndKeys:semantic, @"semantic", dict, @"source", [ NSNumber numberWithUnsignedLong:[ [ attributeDict objectForKey:@"offset" ] integerValue ] ], @"offset", nil ] ];
	}
	
	[ elements addObject:elementName ];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
	[ elements removeObject:elementName ];
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
	if ([ [ self currentElement ] isEqualToString:@"float_array" ] || [ [ self currentElement ] isEqualToString:@"int_array" ] || [ [ self currentElement ] isEqualToString:@"bool_array" ])
	{
		NSMutableDictionary* dict = [ sources lastObject ];
		NSMutableString* str = [ [ NSMutableString alloc ] initWithString:string ];
		[ str replaceOccurrencesOfString:@"\n" withString:@" " options:0 range:NSMakeRange(0, [ str length ]) ];
		[ str replaceOccurrencesOfString:@"\t" withString:@" " options:0 range:NSMakeRange(0, [ str length ]) ];
		unsigned char type = sizeof(float);
		float* bytes = (float*)malloc(type * [ [ dict objectForKey:@"count" ] unsignedIntegerValue ]);
		NSArray* array = [ str componentsSeparatedByString:@" " ];
		for (unsigned long z = 0; z < [ array count ]; z++)
		{
			if (z >= [ [ dict objectForKey:@"count" ] unsignedIntegerValue ])
				break;
			bytes[z] = [ [ array objectAtIndex:z ] floatValue ];
		}
		NSData* data = [ NSData dataWithBytes:bytes length:type * [ [ dict objectForKey:@"count" ] unsignedIntegerValue ] ];
		[ dict setObject:data forKey:@"data" ];
		free(bytes);
		bytes = NULL;
		[ str release ];
		str = nil;
	}
	else if ([ [ self currentElement ] isEqualToString:@"vcount" ])
	{
		NSDictionary* dict = [ polylists lastObject ];
		NSMutableString* str = [ [ NSMutableString alloc ] initWithString:string ];
		[ str replaceOccurrencesOfString:@"\n" withString:@" " options:0 range:NSMakeRange(0, [ str length ]) ];
		[ str replaceOccurrencesOfString:@"\t" withString:@" " options:0 range:NSMakeRange(0, [ str length ]) ];
		unsigned long pos = PosAfterSpaces(str, 0);
		unsigned long count = 0;
		while (pos < [ str length ] || count == [ [ dict objectForKey:@"count" ] unsignedIntegerValue ])
		{
			unsigned long val = [ [ str substringFromIndex:pos ] integerValue ];
			[ [ dict objectForKey:@"vcount" ] addObject:[ NSNumber numberWithUnsignedLong:val ] ];
			pos = PosAfterSpaces(str, PosToSpaces(str, pos));
		}
		[ str release ];
	}
	else if ([ [ self currentElement ] isEqualToString:@"p" ])
	{
		NSMutableDictionary* dict = [ polylists lastObject ];
		NSMutableString* str = [ [ NSMutableString alloc ] initWithString:string ];
		[ str replaceOccurrencesOfString:@"\n" withString:@" " options:0 range:NSMakeRange(0, [ str length ]) ];
		[ str replaceOccurrencesOfString:@"\t" withString:@" " options:0 range:NSMakeRange(0, [ str length ]) ];
		NSArray* array = [ str componentsSeparatedByString:@" " ];
		unsigned int* bytes = (unsigned int*)malloc(sizeof(unsigned int) * [ array count ]);
		for (unsigned long z = 0; z < [ array count ]; z++)
			bytes[z] = [ [ array objectAtIndex:z ] floatValue ];
		[ dict setObject:[ NSData dataWithBytes:bytes length:sizeof(unsigned int) * [ array count ] ] forKey:@"p" ];
		free(bytes);
		bytes = NULL;
		[ str release ];
		str = nil;
	}
	else if ([ [ self currentElement ] isEqualToString:@"color" ])
	{
		NSMutableString* str = [ [ NSMutableString alloc ] initWithString:string ];
		[ str replaceOccurrencesOfString:@"\n" withString:@" " options:0 range:NSMakeRange(0, [ str length ]) ];
		[ str replaceOccurrencesOfString:@"\t" withString:@" " options:0 range:NSMakeRange(0, [ str length ]) ];
		float colors[4];
		unsigned long pos = 0;
		for (int z = 0; z < 4; z++)
		{
			colors[z] = [ [ str substringFromIndex:pos ] floatValue ];
			pos = PosAfterSpaces(str, PosToSpaces(str, pos));
			if (pos >= [ str length ])
				break;
		}
		NSString* type = [ elements objectAtIndex:[ elements count ] - 2 ];
		NSString* name = nil;
		if ([ elements count ] > 1)
			name = [ elements objectAtIndex:[ elements count ] - 3 ];
		if ([ name isEqualToString:@"phong" ] || [ name isEqualToString:@"lambert" ])
		{
			[ [ [ sources lastObject ] objectForKey:@"effect" ] setObject:[ NSMutableDictionary dictionary ] forKey:type ];
			NSMutableDictionary* dict = [ [ [ sources lastObject ] objectForKey:@"effect" ] objectForKey:type ];
			[ dict setObject:[ NSNumber numberWithFloat:colors[0] ] forKey:@"Red" ];
			[ dict setObject:[ NSNumber numberWithFloat:colors[1] ] forKey:@"Green" ];
			[ dict setObject:[ NSNumber numberWithFloat:colors[2] ] forKey:@"Blue" ];
			[ dict setObject:[ NSNumber numberWithFloat:colors[3] ] forKey:@"Alpha" ];
		}
		[ str release ];
	}
	else if ([ [ self currentElement ] isEqualToString:@"float" ])
	{
		NSMutableString* str = [ [ NSMutableString alloc ] initWithString:string ];
		[ str replaceOccurrencesOfString:@"\n" withString:@" " options:0 range:NSMakeRange(0, [ str length ]) ];
		[ str replaceOccurrencesOfString:@"\t" withString:@" " options:0 range:NSMakeRange(0, [ str length ]) ];
		float value = [ [ str substringFromIndex:0 ] floatValue ];
		NSString* type = [ elements objectAtIndex:[ elements count ] - 2 ];
		NSString* name = nil;
		if ([ elements count ] > 1)
			name = [ elements objectAtIndex:[ elements count ] - 3 ];
		if ([ name isEqualToString:@"phong" ] || [ name isEqualToString:@"lambert" ])
			[ [ [ sources lastObject ] objectForKey:@"effect" ] setObject:[ NSNumber numberWithFloat:value ] forKey:type ];
		[ str release ];
	}
	else if ([ [ self currentElement ] isEqualToString:@"init_from" ])
	{
		if ([ [ elements objectAtIndex:[ elements count ] - 2 ] isEqualToString:@"image" ])
		{
			NSString* fullPath = [ NSString stringWithFormat:@"%@/%@", [ loadingFile stringByDeletingLastPathComponent ], string ];
			/*unsigned int tex = 0;
			LoadImage([ fullPath UTF8String ], &tex, 0);*/
			[ [ images lastObject ] setObject:fullPath forKey:@"path" ];
			//[ [ images lastObject ] setObject:[ NSNumber numberWithUnsignedInt:tex ] forKey:@"texture" ];
		}
		else if ([ [ elements objectAtIndex:[ elements count ] - 2 ] isEqualToString:@"surface" ])
			[ [ [ sources lastObject ] objectForKey:@"effect" ] setObject:[ NSString stringWithString:string ] forKey:@"image" ];
	}
	else if ([ [ self currentElement ] isEqualToString:@"rotate" ] || [ [ self currentElement ] isEqualToString:@"scale" ] || [ [ self currentElement ] isEqualToString:@"translate" ])
	{
		NSString* type = [ NSString stringWithString:[ self currentElement ] ];
		NSMutableString* str = [ [ NSMutableString alloc ] initWithString:string ];
		[ str replaceOccurrencesOfString:@"\n" withString:@" " options:0 range:NSMakeRange(0, [ str length ]) ];
		[ str replaceOccurrencesOfString:@"\t" withString:@" " options:0 range:NSMakeRange(0, [ str length ]) ];
		unsigned int number = 3;
		if ([ [ self currentElement ] isEqualToString:@"rotate" ])
			number = 4;
		float colors[number];
		unsigned long pos = 0;
		for (int z = 0; z < number; z++)
		{
			colors[z] = [ [ str substringFromIndex:pos ] floatValue ];
			pos = PosAfterSpaces(str, PosToSpaces(str, pos));
			if (pos >= [ str length ])
				break;
		}
		NSMutableArray* array = [ [ nodes lastObject ] objectForKey:@"translates" ];
		NSMutableDictionary* dict = [ NSMutableDictionary dictionary ];
		[ dict setObject:[ NSNumber numberWithFloat:colors[0] ] forKey:@"X" ];
		[ dict setObject:[ NSNumber numberWithFloat:colors[1] ] forKey:@"Y" ];
		[ dict setObject:[ NSNumber numberWithFloat:colors[2] ] forKey:@"Z" ];
		if (number == 4)
			[ dict setObject:[ NSNumber numberWithFloat:colors[3] ] forKey:@"Angle" ];
		[ dict setObject:type forKey:@"type" ];
		[ array addObject:dict ];
	}
}

@end
