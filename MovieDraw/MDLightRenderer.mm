//
//  MDLightRenderer.m
//  MovieDraw
//
//  Created by Neil on 10/17/13.
//  Copyright (c) 2013 Neil. All rights reserved.
//

#import "MDLightRenderer.h"
#import "GLView.h"
#import "MDObjectTools.h"

// Draw in 1280 x 720
const float renderWidth = 1280, renderHeight = 720;

typedef struct
{
	// Patch factors
	//float reflectance;
	MDVector3 incident;
	MDVector3 color;
	//MDVector3 excident;
	//BOOL hit;
	
	// Identifying factors
	MDObject* obj;
	MDMesh* mesh;
	MDVector3 position;
	MDVector2 uv;
	MDVector2 size;
	MDVector3 normal;
} MDPatch;

/*@interface MDPatch : NSObject
{
}

@property (assign) float reflectance;
@property (assign) MDVector3 incident;
@property (assign) MDVector3 color;
@property (assign) MDVector3 excident;
@property (assign) BOOL hit;

@property (assign) MDObject* obj;
@property (assign) MDMesh* mesh;
@property (assign) MDVector3 position;
@property (assign) MDVector2 uv;
@property (assign) MDVector2 size;
@property (assign) MDVector3 normal;

@end

@implementation MDPatch

@synthesize reflectance;
@synthesize incident;
@synthesize color;
@synthesize excident;
@synthesize hit;
@synthesize obj;
@synthesize mesh;
@synthesize position;
@synthesize uv;
@synthesize size;
@synthesize normal;

@end*/

#define PATCH_SIZE	0.01//0.25//0.01//0.5

// Given the object and the point from the mesh, this returns the real position after all the transformations
MDVector3 MDApplyTransformation(MDObject* obj, MDPoint* p)
{
	// Apply matrix transformations
	return MDMatrixMultiply([ obj modelViewMatrix ], [ p position ], 1).GetXYZ();
}

// Returns the linear interpolation of a triangle in the form of ([0,1] from first to second coordinate, [0,1] from first to third coordinate)
MDVector2 MDTriangleInterpolation(MDVector3 P, MDVector3 A, MDVector3 C, MDVector3 B)
{
	// Compute vectors
	MDVector3 v0 = C - A;
	MDVector3 v1 = B - A;
	MDVector3 v2 = P - A;
	
	// Compute dot products
	float dot00 = MDVector3DotProduct(v0, v0);
	float dot01 = MDVector3DotProduct(v0, v1);
	float dot02 = MDVector3DotProduct(v0, v2);
	float dot11 = MDVector3DotProduct(v1, v1);
	float dot12 = MDVector3DotProduct(v1, v2);
	
	// Compute barycentric coordinates
	float invDenom = 1 / (dot00 * dot11 - dot01 * dot01);
	float u = (dot11 * dot02 - dot01 * dot12) * invDenom;
	float v = (dot00 * dot12 - dot01 * dot02) * invDenom;
	
	return MDVector2Create(u, v);
}

BOOL MDPointInTriangle(MDVector2 pt, MDVector2 v1, MDVector2 v2, MDVector2 v3)
{
	
	MDVector2 uv = MDTriangleInterpolation(MDVector3Create(pt, 0), MDVector3Create(v1, 0), MDVector3Create(v2, 0), MDVector3Create(v3, 0));
	return (uv.x >= 0) && (uv.y >= 0) && (uv.x + uv.y < 1);
	
	/*
#define sign(p1, p2, p3)	((p1.x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (p1.y - p3.y))
	
	bool b1, b2, b3;
	
	b1 = sign(pt, v1, v2) < 0.0f;
	b2 = sign(pt, v2, v3) < 0.0f;
	if (b2 != b1)
		return FALSE;
	b3 = sign(pt, v3, v1) < 0.0f;
	
	return (b2 == b3);
	*/
}

// Returns whether a segment intersects a triangle
BOOL MDSegmentIntersectsTriangle(MDVector3 r1, MDVector3 r2, MDVector3 p1, MDVector3 p2, MDVector3 p3)
{
	MDVector3 e1 = p2 - p1, e2 = p3 - p1, d = r2 - r1;
	MDVector3 h = MDVector3CrossProduct(d, e2);
	
	float a = MDVector3DotProduct(e1, h);
	
	if (MDFloatCompare(a, 0))
		return FALSE;
	
	float f = 1.0 / a;
	MDVector3 s = r1 - p1;
	float u = f * MDVector3DotProduct(s, h);
	
	if (u <= 0.0 || u >= 1.0)
		return FALSE;
	
	MDVector3 q = MDVector3CrossProduct(s, e1);
	float v = f * MDVector3DotProduct(d, q);
	
	if (v <= 0.0 || u + v >= 1.0)
		return FALSE;
	
	// at this stage we can compute t to find out where
	// the intersection point is on the line
	float t = f * MDVector3DotProduct(e2, q);
	
	if (t > 0 && t < 1) // ray intersection
		return TRUE;
	else // this means that there is a line intersection
		// but not a ray intersection
		return FALSE;
}

void MDGenerateLightmaps(NSMutableArray* objects, NSMutableArray* instances, NSMutableArray* otherObjects, NSString* path, NSString* scene, NSSize res, NSProgressIndicator* progress, NSTextField* label)
{
	double currentTime = CFAbsoluteTimeGetCurrent(), endTime = currentTime;
	
	// 606 ms, 524800 patches (before)
	
	// 64 - 4290
	
	//NSLog(@"Starting");
	[ label setStringValue:@"Starting" ];
	
	// Cache all the lights
	unsigned long totalLights = 0;
	NSMutableArray* lights = [ [ NSMutableArray alloc ] init ];
	for (unsigned long z = 0; z < [ otherObjects count ]; z++)
	{
		// Add if its a light and is static
		id obj = otherObjects[z];
		if ([ obj isKindOfClass:[ MDLight class ] ] && [ obj isStatic ])
		{
			[ lights addObject:obj ];
			totalLights++;
		}
	}
	
	// Patches to test
	//NSMutableArray* patches = [ [ NSMutableArray alloc ] init ];
	// Order of arrays to faster parse the patches per mesh
	//NSMutableArray* meshPatches = [ [ NSMutableArray alloc ] init ];
	// Mesh sizes
	NSMutableArray* meshSizes = [ [ NSMutableArray alloc ] init ];
	
	// Setup mesh indicies
	unsigned long totalMeshes = 0;
	for (unsigned long y = 0; y < [ objects count ]; y++)
	{
		MDObject* obj = objects[y];
		if (!obj.isStatic)
			continue;
		MDInstance* inst = [ obj instance ];
		for (unsigned long q = 0; q < [ inst numberOfMeshes ]; q++)
		{
			MDMesh* mesh = [ inst meshAtIndex:q ];
			// If its not triangles, ignore it
			if ([ mesh numberOfIndices ] % 3 != 0)
				continue;
			totalMeshes++;
		}
	}
	unsigned long* meshPatches = (unsigned long*)malloc(sizeof(unsigned long) * totalMeshes);
	
	//NSLog(@"Begin Division");
	
	// Sizes
	unsigned long totalTriangles = 0, totalPatches = 0, meshCounter = 0;
	NSSize biggest = NSMakeSize(0.0001, 0.0001);
	for (unsigned long y = 0; y < [ objects count ]; y++)
	{
		MDObject* obj = objects[y];
		if (!obj.isStatic)
			continue;
		
		// Add new object array
		NSMutableArray* array2 = [ [ NSMutableArray alloc ] init ];
		[ meshSizes addObject:array2 ];
		
		MDInstance* inst = [ obj instance ];
		for (unsigned long q = 0; q < [ inst numberOfMeshes ]; q++)
		{
			MDMesh* mesh = [ inst meshAtIndex:q ];
			
			// Add new mesh to the array
			NSMutableArray* array = [ [ NSMutableArray alloc ] init ];
			[ array2 addObject:array ];
			
			// If its not triangles, ignore it
			if ([ mesh numberOfIndices ] % 3 != 0)
				continue;
			
			for (unsigned int t = 0; t < [ mesh numberOfIndices ]; t += 3)
			{
				// Properties of triangle
				MDPoint* point1 = [ inst pointAtIndex:[ mesh indexAtIndex:(t + 0) ] ];
				MDPoint* point2 = [ inst pointAtIndex:[ mesh indexAtIndex:(t + 1) ] ];
				MDPoint* point3 = [ inst pointAtIndex:[ mesh indexAtIndex:(t + 2) ] ];
				MDVector3 meshNormal = MDVector3Normalize([ point1 normal ] + [ point2 normal ] + [ point3 normal ]);
				// Rotate this normal
				if (!MDFloatCompare(obj.rotateAngle, 0))
					meshNormal = MDVector3Rotate(meshNormal, obj.rotateAxis, -obj.rotateAngle / 180 * M_PI);
				MDVector3 p[3] = { MDApplyTransformation(obj, point1), MDApplyTransformation(obj, point2), MDApplyTransformation(obj, point3) };
				
				//MDVector2 dt1 = MDVector2Create(point1.textureCoordX, point1.textureCoordY);
				float length1 = MDVector3Distance(p[0], p[1]);// / MDVector2Distance(dt1, MDVector2Create(point2.textureCoordX, point2.textureCoordY));
				float length2 = MDVector3Distance(p[0], p[2]);// / MDVector2Distance(dt1, MDVector2Create(point3.textureCoordX, point3.textureCoordY));
				
				//NSLog(@"(%f x %f)", length1, length2);
				
				[ array addObject:@(length1) ];
				[ array addObject:@(length2) ];
				
				if (length1 > biggest.width)
					biggest.width = length1;
				if (length2 > biggest.height)
					biggest.height = length2;
				
				totalTriangles++;
			}
		}
	}
	
	unsigned long realY = 0;
	for (unsigned long y = 0; y < [ objects count ]; y++)
	{
		MDObject* obj = objects[y];
		if (!obj.isStatic)
			continue;
		MDInstance* inst = [ obj instance ];
		for (unsigned long q = 0; q < [ inst numberOfMeshes ]; q++)
		{
			MDMesh* mesh = [ inst meshAtIndex:q ];
			// If its not triangles, ignore it
			if ([ mesh numberOfIndices ] % 3 != 0)
				continue;
			
			unsigned long prevPatches = totalPatches;
			for (unsigned int t = 0; t < [ mesh numberOfIndices ]; t += 3)
			{
				float length1 = [ meshSizes[realY][q][(t / 3) * 2] floatValue ];
				float length2 = [ meshSizes[realY][q][(t / 3) * 2 + 1] floatValue ];
				const unsigned int resX = round(res.width / biggest.width * length1);
				const unsigned int resX1 = resX - 1;
				const unsigned int resY = round(res.height / biggest.height * length2);
				const unsigned int resY1 = resY - 1;
				const unsigned long multRes = resX1 * resY1;
				
				for (unsigned int uvx = 0; uvx < resX; uvx++)
				{
					for (unsigned int uvy = 0; uvy < resY; uvy++)
					{
						if (uvx * resY1 + uvy * resX1 > multRes)
							break;
						totalPatches++;
					}
				}
			}
			unsigned long newPatches = totalPatches - prevPatches;
			meshPatches[meshCounter++] = newPatches;
		}
		realY++;
	}
	
	// Initialize the patches
	MDPatch* patches = (MDPatch*)malloc(sizeof(MDPatch) * totalPatches);
	if (!patches)
	{
		// Todo, dealloc
		return;
	}
	
	unsigned long patchCounter = 0;
	realY = 0;
	// Have a counter
	unsigned long counter = 0;
	for (unsigned long y = 0; y < [ objects count ]; y++)
	{
		MDObject* obj = objects[y];
		if (!obj.isStatic)
			continue;
		
		MDInstance* inst = [ obj instance ];
		for (unsigned long q = 0; q < [ inst numberOfMeshes ]; q++)
		{
			MDMesh* mesh = [ inst meshAtIndex:q ];
			
			MDVector4 meshC = [ mesh color ], objC = [ obj colorMultiplier ];
			MDVector3 realColor = MDVector3Create(meshC.x * objC.x, meshC.y * objC.y, meshC.z * objC.z);
			
			// If its not triangles, ignore it
			if ([ mesh numberOfIndices ] % 3 != 0)
				continue;
			
			for (unsigned int t = 0; t < [ mesh numberOfIndices ]; t += 3)
			{
				// Properties of triangle
				MDPoint* point1 = [ inst pointAtIndex:[ mesh indexAtIndex:(t + 0) ] ];
				MDPoint* point2 = [ inst pointAtIndex:[ mesh indexAtIndex:(t + 1) ] ];
				MDPoint* point3 = [ inst pointAtIndex:[ mesh indexAtIndex:(t + 2) ] ];
				MDVector3 meshNormal = MDVector3Normalize([ point1 normal ] + [ point2 normal ] + [ point3 normal ]);
				// Transform this normal
				meshNormal = MDVector3Normalize(MDVector3Create(meshNormal.x * obj.scaleX, meshNormal.y * obj.scaleY, meshNormal.z * obj.scaleZ));
				if (!MDFloatCompare(obj.rotateAngle, 0))
					meshNormal = MDVector3Rotate(meshNormal, obj.rotateAxis, -obj.rotateAngle / 180 * M_PI);
				
				// Get real positions
				MDVector3 p[3] = { MDApplyTransformation(obj, point1), MDApplyTransformation(obj, point2), MDApplyTransformation(obj, point3) };
			
				const unsigned int resX = round(res.width / biggest.width * [ meshSizes[realY][q][(t / 3) * 2] floatValue ]);
				const unsigned int resX1 = resX - 1;
				const unsigned int resY = round(res.height / biggest.height * [ meshSizes[realY][q][(t / 3) * 2 + 1] floatValue ]);
				const unsigned int resY1 = resY - 1;
				const float deltaX = 1.0 / resX1;
				const float deltaY = 1.0 / resY1;
				const unsigned long multRes = resX1 * resY1;
				
				// Cache some stuff
				MDVector3 p10 = p[1] - p[0], p20 = p[2] - p[0];
				float t21x = (point2.textureCoordX - point1.textureCoordX), t21y = (point2.textureCoordY - point1.textureCoordY);
				float t31x = (point3.textureCoordX - point1.textureCoordX), t31y = (point3.textureCoordY - point1.textureCoordY);
								
				for (unsigned int uvx = 0; uvx < resX; uvx++)
				{
					for (unsigned int uvy = 0; uvy < resY; uvy++)
					{
						if (uvx * resY1 + uvy * resX1 > multRes)
							break;
																		
						MDVector2 uv = MDVector2Create((float)uvx / resX1, (float)uvy / resY1);
						
						//MDVector3 point = p[0] + uv.x * p10 + uv.y * p20;
						
						//uv = MDVector2Create((point1.textureCoordX + uv.x * t21x + uv.y * t31x), (point1.textureCoordY + uv.x * t21y + uv.y * t31y));
						//uv.y = 1 - uv.y;
						MDPatch* patch = &patches[patchCounter++];
						patch->obj = obj;
						patch->mesh = mesh;
						patch->position = p[0] + uv.x * p10 + uv.y * p20;
						//patch->excident = MDVector3Create(0, 0, 0);
						patch->incident = MDVector3Create(0, 0, 0);
						patch->color = realColor;
						//patch->reflectance = 0;
						patch->uv = MDVector2Create((point1.textureCoordX + uv.x * t21x + uv.y * t31x), 1 - (point1.textureCoordY + uv.x * t21y + uv.y * t31y));
						patch->size = MDVector2Create(deltaX, deltaY);
						if (resX1 == 0)
							patch->size.x = 1;
						if (resY1 == 0)
							patch->size.y = 1;
						patch->normal = meshNormal;
						//patch->hit = TRUE;
					}
				}
				
				counter++;
				[ progress setDoubleValue:((double)counter / totalTriangles) / 3.0 * 100 ];
				[ label setStringValue:[ NSString stringWithFormat:@"Divison - Triangle %lu / %lu", counter, totalTriangles ] ];
			}
		}
		realY++;
	}
		
	//NSLog(@"End Division (%lu ms)", (unsigned long)((CFAbsoluteTimeGetCurrent() - endTime) * 1000.0));
	endTime = CFAbsoluteTimeGetCurrent();
	
	//NSLog(@"Begin Ray Tracing");
	counter = 0;
	// Cast a ray from all point light sources to each of the patches
	for (unsigned long y = 0; y < [ lights count ]; y++)
	{
		[ progress setDoubleValue:(1 + (double)counter / totalLights) / 3.0 * 100 ];
		[ label setStringValue:[ NSString stringWithFormat:@"Ray Tracing - Light %lu / %lu", counter + 1, totalLights ] ];
		
		MDLight* light = lights[y];
		
		if ([ light lightType ] == MDPointLight)
		{
			// Cache light data
			MDVector3 lightPos = [ light position ];
			MDVector3 diffuse = [ light diffuseColor ].GetXYZ();
			MDVector3 ambient = [ light ambientColor ].GetXYZ();
			MDVector3 amDi = MDVector3Create(diffuse.x * ambient.x, diffuse.y * ambient.y, diffuse.z * ambient.z);
			
			// Disable shadows for now
			/*for (unsigned long q = 0; q < [ objects count ]; q++)
			{
				MDObject* obj = [ objects objectAtIndex:q ];
				if (!obj.isStatic)
					continue;
				
				MDInstance* inst = [ obj instance ];
				for (unsigned long t = 0; t < [ inst numberOfMeshes ]; t++)
				{
					MDMesh* mesh = [ inst meshAtIndex:t ];
					for (unsigned int r = 0; r < [ mesh numberOfIndices ]; r += 3)
					{
						// Todo: Maybe can multiply the patch position and lightPos by the inverse matrix so that its like the same thing
						MDVector3 p1 = MDApplyTransformation(obj, [ inst pointAtIndex:[ mesh indexAtIndex:r + 0 ] ]);
						MDVector3 p2 = MDApplyTransformation(obj, [ inst pointAtIndex:[ mesh indexAtIndex:r + 1 ] ]);
						MDVector3 p3 = MDApplyTransformation(obj, [ inst pointAtIndex:[ mesh indexAtIndex:r + 2 ] ]);
						
						for (unsigned long z = 0; z < [ patches count ]; z++)
						{
							MDPatch* patch = [ patches objectAtIndex:z ];
							if (obj == patch.obj)
								continue;
							if (MDSegmentIntersectsTriangle(patch.position, lightPos, p1, p2, p3))
								patch.hit = FALSE;
						}
					}
				}
			}*/
			
			for (unsigned long z = 0; z < totalPatches; z++)
			{
				MDPatch* patch = &patches[z];
				//if (!patch.hit)
				//	continue;
				
				//if (MDFloatCompare(patch.position.x, 5) && MDFloatCompare(patch.position.y, 4.5) && MDFloatCompare(patch.position.z, -55))
				{
					//patch.incident = MDVector3Create(0.5, 0, 0);
					//NSLog(@"Here");
				}
				
				MDVector3 ray = lightPos - patch->position;
				
				// Calculate light color / intensity
				float dist = MDVector3Magnitude(ray);
				MDVector3 normDist = ray / dist;
				float att = 1.0 / ([ light constAtt ] + (dist * [ light linAtt ]) + (dist * dist * [ light quadAtt ]));
				float dot = MDVector3DotProduct(patch->normal, normDist);
				if (dot > 0)
					patch->incident += amDi * dot * att;
			}
		}
		else if ([ light lightType ] == MDDirectionalLight)
		{
			// Cache light data
			MDVector3 ray = [ light spotDirection ] - [ light position ];
			MDVector3 diffuse = [ light diffuseColor ].GetXYZ();
			MDVector3 ambient = [ light ambientColor ].GetXYZ();
			
			// Calculate light color / intensity
			float dist = MDVector3Magnitude(ray);
			MDVector3 normDist = ray / -dist;
			
			for (unsigned long z = 0; z < totalPatches; z++)
			{
				MDPatch* patch = &patches[z];
				
				// No shadows for now
								
				float dot = MDVector3DotProduct(patch->normal, normDist);
				if (dot > 0)
					patch->incident += diffuse * dot;
				patch->incident += ambient;
			}
		}
		else if ([ light lightType ] == MDSpotLight)
		{
			MDVector3 lightPos = [ light position ];
			MDVector3 diffuse = [ light diffuseColor ].GetXYZ();
			MDVector3 ambient = [ light ambientColor ].GetXYZ();
			MDVector3 spotDir = MDVector3Normalize([ light spotDirection ] - lightPos);
			float angle = [ light spotAngle ];
			float exp = [ light spotExp ];
			
			for (unsigned long z = 0; z < totalPatches; z++)
			{
				MDPatch* patch = &patches[z];
				
				// No shadows for now
				
				MDVector3 ray = lightPos - patch->position;
				float dist = MDVector3Magnitude(ray);
				MDVector3 normDist = ray / dist;
				float dot = MDVector3DotProduct(patch->normal, normDist);
				if (dot > 0)
				{
					float spotEffect = MDVector3DotProduct(spotDir, -1 * normDist);
					if (spotEffect > angle)
					{
						spotEffect = pow(spotEffect, exp);
						float att = spotEffect / ([ light constAtt ] + (dist * [ light linAtt ]) + (dist * dist * [ light quadAtt ]));
						patch->incident += att * ((diffuse * dot) + ambient);
					}
				}
			}
		}
		
		counter++;
		//NSLog(@"%lu", counter);
	}
	//NSLog(@"End Ray Tracing (%lu ms)", (unsigned long)((CFAbsoluteTimeGetCurrent() - endTime) * 1000.0));
	endTime = CFAbsoluteTimeGetCurrent();
	
	/*//NSLog(@"Begin Radiosity");
	// Todo
	//NSLog(@"End Radiosity (%lu ms)", (unsigned long)((CFAbsoluteTimeGetCurrent() - endTime) * 1000.0));
	endTime = CFAbsoluteTimeGetCurrent();*/
	
	//NSLog(@"Begin Creating Images");
	
	[ [ NSFileManager defaultManager ] removeItemAtPath:[ NSString stringWithFormat:@"%@/build/%@.app/Contents/Resources/LightMaps/%@/", path, [ path lastPathComponent ], scene ] error:nil ];
	[ [ NSFileManager defaultManager ] createDirectoryAtPath:[ NSString stringWithFormat:@"%@/build/%@.app/Contents/Resources/LightMaps/%@/", path, [ path lastPathComponent ], scene ] withIntermediateDirectories:YES attributes:nil error:nil ];
	
	// Keep a counter for seeing progress
	counter = 0;
	// Create the lightmaps for each object
	unsigned long realQ = 0, currentPatch = 0;
	for (unsigned long q = 0; q < [ objects count ]; q++)
	{
		if (![ objects[q] isStatic ])
			continue;
		
		// Retrieve the instance and the array of objects
		MDInstance* inst = [ objects[q] instance ];
		
		for (unsigned long t = 0; t < [ inst numberOfMeshes ]; t++)
		{
			// Retrieve the array of meshes
			unsigned long numPatches = meshPatches[counter];
			
			NSMutableArray* meshSizeArray = meshSizes[realQ][t];
			
			// Make it the first one and assume the others are the same size (they might have to be since they are under the same scaling)
			NSSize realRes = NSMakeSize(round([ meshSizeArray[0] floatValue ] / biggest.width * res.width), round([ meshSizeArray[1] floatValue ] / biggest.height * res.height));
			//realRes = NSMakeSize(32, 32);
			
			if (realRes.width < 1 || realRes.height < 1)
				continue;
			
			// Create an image
			unsigned long length = round((realRes.width) * (realRes.height + 0) * 3);
			unsigned char* pixelData = (unsigned char*)malloc(length);
			memset(pixelData, 0, length);
			for (unsigned long z = 0; z < numPatches; z++)
			{
				// Get the specific patch
				MDPatch* patch = &patches[z + currentPatch];
				// Todo: Since light cannot above 1.0 in an image, we should divide this number by like 2 or 4 so that we can remultiply that back in in the shader to get brighter values ;)
				MDVector3 color = MDVector3Create(round(patch->incident.x * patch->color.x * 255), round(patch->incident.y * patch->color.y * 255), round(patch->incident.z * patch->color.z * 255));
				if (color.x > 255)
					color.x = 255;
				if (color.y > 255)
					color.y = 255;
				if (color.z > 255)
					color.z = 255;
				MDVector2 pos = MDVector2Create(patch->uv.x * realRes.width, patch->uv.y * realRes.height);
				// Fill in the colors (fill in the rectangle of pixels for the size)
				for (float x = -patch->size.x * realRes.width; x < patch->size.x * realRes.width; x++)
				{
					for (float y = -patch->size.y * realRes.height; y < patch->size.y * realRes.height; y++)
					{
						// Get actual pixel coordinates
						int xPos = (x + pos.x);
						int yPos = (y + pos.y);
						
						// Check that its inside the image (apparently, the right bottom most pixel is cut off or something)
						if (xPos < 0 || xPos >= realRes.width || yPos < 0 || yPos >= realRes.height)
							continue;
						
						// Set the pixel in the image data
						unsigned long pos2 = (xPos + (yPos * realRes.width)) * 3;
						if (pos2 >= length)
							continue;
						
						pixelData[pos2] = color.x;
						pixelData[pos2 + 1] = color.y;
						pixelData[pos2 + 2] = color.z;
					}
				}
			}
			currentPatch += numPatches;
			
			// Cause bitmap formats are too hard
			NSBitmapImageRep* rep = [ [ NSBitmapImageRep alloc ] initWithBitmapDataPlanes:NULL pixelsWide:realRes.width pixelsHigh:realRes.height bitsPerSample:8 samplesPerPixel:3 hasAlpha:NO isPlanar:NO colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:0 bitsPerPixel:0 ];
			for (int x = 0; x < realRes.width; x++)
			{
				for (int y = 0; y < realRes.height; y++)
				{
					unsigned long pos = (x + (y * realRes.width)) * 3;
					unsigned long data[3] = { pixelData[pos], pixelData[pos + 1], pixelData[pos + 2] };
					[ rep setPixel:data atX:x y:y ];
				}
			}
			
			// Create the file
			[ [ NSFileManager defaultManager ] createFileAtPath:[ NSString stringWithFormat:@"%@/build/%@.app/Contents/Resources/LightMaps/%@/%@ - %@ - %lu.png", path, [ path lastPathComponent ], scene, [ inst name ], [ objects[q] name ], t ] contents:[ rep representationUsingType:NSPNGFileType properties:nil ] attributes:nil ];
			free(pixelData);
			
			counter++;
			[ progress setDoubleValue:(2 + (double)counter / totalMeshes) / 3.0 * 100 ];
			[ label setStringValue:[ NSString stringWithFormat:@"Creating Images - Mesh %lu / %lu", counter, totalMeshes ] ];
			//NSLog(@"%lu", counter);
		}
		realQ++;
	}
	
	//NSLog(@"End Creating Images (%lu ms)", (unsigned long)((CFAbsoluteTimeGetCurrent() - endTime) * 1000.0));
	[ label setStringValue:[ NSString stringWithFormat:@"Done - %lu patches (%lu ms)", totalPatches, (unsigned long)((CFAbsoluteTimeGetCurrent() - currentTime) * 1000) ] ];
	endTime = CFAbsoluteTimeGetCurrent();
	[ progress setDoubleValue:100 ];
	
	// Done
	//NSLog(@"Done - %lu patches (%lu ms)", [ patches count ], (unsigned long)((CFAbsoluteTimeGetCurrent() - currentTime) * 1000));
	
	/* TODO:
	 * Atlas the lightmaps into one or a couple big textures
		* Save the new texture coordinates in separate files
		* In the framework, make a new class called the static object that accepts texture coordinates per object (plus some other stuff)
	 * Implement ray tracing shadows
	 * Radiosity bounces
	 * Reduce memory (and leaks)
	 */
	
	
	// Cleanup
	free(patches);
	patches = NULL;
	free(meshPatches);
	meshPatches = NULL;
}
