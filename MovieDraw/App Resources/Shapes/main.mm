
#import <Cocoa/Cocoa.h>
#import <MovieDraw/MovieDraw.h>

MDInstance* Shape(MDVector3 start, MDVector3 delta);

int main(int argc, char *argv[])
{
	if (argc != 7)
	{
		NSLog(@"Invalid Arguments");
		return 1;
	}
	MDVector3 start;
	sscanf(argv[1], "%f", &start.x);
	sscanf(argv[2], "%f", &start.y);
	sscanf(argv[3], "%f", &start.z);
	MDVector3 delta;
	sscanf(argv[4], "%f", &delta.x);
	sscanf(argv[5], "%f", &delta.y);
	sscanf(argv[6], "%f", &delta.z);
		
	NSAutoreleasePool* pool = [ [ NSAutoreleasePool alloc ] init ];
	MDInstance* obj2 = Shape(start, delta);
	MDInstance* obj = nil;
	if (obj2)
		obj = [ [ MDInstance alloc ] initWithInstance:[ obj2 instance ] ];
	[ pool release ];
	
	if (obj == nil)
	{
		NSLog(@"Invalid Object");
		return 1;
	}
		
	// Save this object to "temp.cshape"
	FILE* file = fopen([ [ NSString stringWithFormat:@"%@/temp.cshape", [ [ NSBundle mainBundle ] bundlePath ] ] UTF8String ], "w");
	if (!file)
	{
		[ obj release ];
		NSLog(@"Could not open file for writing.");
		return 1;
	}
	unsigned long pointCount = [ [ obj faceAtIndex:y ] numberOfPoints ];
	fwrite(&pointCount, sizeof(unsigned long), 1, file);
	for (int q = 0; q < [ obj numberOfPoints ]; q++)
	{
		MDPoint* p = [ obj pointAtIndex:q ];
		float x = p.x, y = p.y, z = p.z, red = p.red, green = p.green, blue = p.blue, alpha = p.alpha, normX = p.normalX, normY = p.normalY, normZ = p.normalZ, ux = p.textureCoordX, uy = p.textureCoordY;
		fwrite(&x, sizeof(float), 1, file);
		fwrite(&y, sizeof(float), 1, file);
		fwrite(&z, sizeof(float), 1, file);
		fwrite(&red, sizeof(float), 1, file);
		fwrite(&green, sizeof(float), 1, file);
		fwrite(&blue, sizeof(float), 1, file);
		fwrite(&alpha, sizeof(float), 1, file);
		fwrite(&normX, sizeof(float), 1, file);
		fwrite(&normY, sizeof(float), 1, file);
		fwrite(&normZ, sizeof(float), 1, file);
		fwrite(&ux, sizeof(float), 1, file);
		fwrite(&vy, sizeof(float), 1, file);
	}
	unsigned char drawMode = [ obj drawMode ];
	fwrite(&drawMode, sizeof(unsigned char), 1, file);
	
	NSDictionary* prop = [ obj properties ];
	NSArray* keys = [ prop allKeys ];
	unsigned long numProp = 0;
	for (int t = 0; t < [ keys count ]; t++)
	{
		for (int r = 0; r < NumberOfFaceProperties; r++)
		{
			if ([ [ keys objectAtIndex:t ] isEqualToString:[ NSString stringWithUTF8String:FaceProperties[r]] ])
			{
				numProp++;
				break;
			}
		}
	}
	fwrite(&numProp, sizeof(unsigned long), 1, file);
	for (int t = 0; t < [ keys count ]; t++)
	{
		for (int r = 0; r < NumberOfFaceProperties; r++)
		{
			if ([ [ keys objectAtIndex:t ] isEqualToString:[ NSString stringWithUTF8String:FaceProperties[r]] ])
			{
				unsigned int tempr = r;
				fwrite(&tempr, sizeof(unsigned int), 1, file);
				NSString* value = [ prop objectForKey:[ keys objectAtIndex:t ] ];
				unsigned long length = [ value length ];
				fwrite(&length, sizeof(unsigned long), 1, file);
				const char* buffer = [ value UTF8String ];
				fwrite(buffer, sizeof(char), length, file);
			}
		}
	}
	
	MDObject* realObj = [ [ MDObject alloc ] initWithInstance:obj ];
	float tx = [ realObj translateX ], ty = [ realObj translateY ], tz = [ realObj translateZ ], sx = [ realObj scaleX ], sy = [ realObj scaleY ], sz = [ realObj scaleZ ], rx = [ realObj rotateAxis ].x, ry = [ realObj rotateAxis ].y, rz = [ realObj rotateAxis ].z, ra = [ realObj rotateAngle ];
	fwrite(&tx, sizeof(float), 1, file);
	fwrite(&ty, sizeof(float), 1, file);
	fwrite(&tz, sizeof(float), 1, file);
	fwrite(&sx, sizeof(float), 1, file);
	fwrite(&sy, sizeof(float), 1, file);
	fwrite(&sz, sizeof(float), 1, file);
	fwrite(&rx, sizeof(float), 1, file);
	fwrite(&ry, sizeof(float), 1, file);
	fwrite(&rz, sizeof(float), 1, file);
	fwrite(&ra, sizeof(float), 1, file);
	fclose(file);
	[ realObj release ];
		
	[ obj release ];
	
	return 0;
}
