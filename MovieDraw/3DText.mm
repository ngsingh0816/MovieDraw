//
//  3DText.m
//  MovieDraw
//
//  Created by Neil on 6/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "3DText.h"
#define GL_DO_NOT_WARN_IF_MULTI_GL_VERSION_HEADERS_INCLUDED	// Gets rid of a warning
#import "GLString.h"
#import "MDGUI.h"
#import <OpenGL/glu.h>
#import "MDTypes.h"
#include <vector>

typedef struct
{
	std::vector<NSPoint> points;
	GLenum drawMode;
} Final;
std::vector<Final> shapes;

typedef struct
{
	float x;
	float y;
	float z; 
} Normal;
std::vector< std::vector<Normal> > normals;

typedef struct
{
	float x;
	float y;
	float z;
} Vertex;

void beginTess(GLenum poly);
void endTess();
void errorTess(GLenum error);
void vertexTess(const void* data);
float MDVector3Distance(NSPoint p, NSPoint p2);
void MDVector3Normalize(Normal* normal);
void normalizeTriangle(Vertex v[3], Normal* normal);

std::vector< std::vector<NSPoint> > shapes2;
float percent = 0;
BOOL calculating = FALSE;
float fontSize = 150;
// Callbacks for GLU Tesselator
void beginTess(GLenum poly)
{
	// Create new object
	Final final;
	final.drawMode = poly;
	shapes.push_back(final);
}

void endTess()
{
	// Do nothing
}

void errorTess(GLenum error)
{
	NSLog(@"Error: %s", gluErrorString(error));
}

void vertexTess(const void* data)
{
	// Append data
	NSPoint p = NSMakePoint(((double*)data)[0], ((double*)data)[1]);
	shapes[shapes.size() - 1].points.push_back(p);
}
float MDVector3Distance(NSPoint p, NSPoint p2)
{
	// distance = √((x1 - x2)^2 + (y1 - y2)^2)
	return sqrtf(powf(p.x - p2.x, 2) + powf(p.y - p2.y, 2));
}

void MDVector3Normalize(Normal* normal)
{
	double len = sqrt((normal->x * normal->x) + (normal->y * normal->y) + (normal->z * normal->z));
	if (len == 0)
		len = 1;
	normal->x /= len;
	normal->y /= len;
	normal->z /= len;
}

void normalizeTriangle(Vertex v[3], Normal* normal)
{
	Vertex a, b;
	a.x = v[0].x - v[1].x;
	a.y = v[0].y - v[1].y;
	a.z = v[0].z - v[1].z;
	b.x = v[1].x - v[2].x;
	b.y = v[1].y - v[2].y;
	b.z = v[1].z - v[2].z;
	
	normal->x = (a.y * b.z) - (a.z * b.y);
	normal->y = (a.z * b.x) - (a.x * b.z);
	normal->z = (a.x * b.y) - (a.y * b.x);
	
	MDVector3Normalize(normal);
}

@implementation MDText

+ (MDInstance*) createText:(NSAttributedString *)str depth: (float)dep
{
	if ([ str length ] == 0)
	{
		shapes.clear();
		shapes2.clear();
		normals.clear();
		return nil;
	}

	percent = 0;
	@autoreleasepool {
		calculating = TRUE;
		std::vector<NSPoint> points;
		NSAttributedString* text = str;
		NSSize size = [ text size ];
		NSImage* image = [ [ NSImage alloc ] initWithSize:NSMakeSize(size.width, size.height) ];
		[ image lockFocus ];
		[ [ NSGraphicsContext currentContext ] setShouldAntialias:NO ];
		[ [ NSColor whiteColor ] set ];
		[ text drawAtPoint:NSMakePoint(0, 0) ];
		NSBitmapImageRep* bitmap = [ [ NSBitmapImageRep alloc ] initWithFocusedViewRect:NSMakeRect(0, 0, size.width, size.height) ];
		[ image unlockFocus ];

		// Get Points
		for (int y = 0; y < [ bitmap pixelsHigh ]; y++)
		{
			for (int x = 0; x < [ bitmap pixelsWide ]; x++)
			{
				if ([ [ bitmap colorAtX:x y:y ] redComponent ] == 0 && [ [ bitmap colorAtX:x y:y ] greenComponent ] == 0 && [ [ bitmap colorAtX:x y:y ] blueComponent ] == 0 && [ [ bitmap colorAtX:x y:y ] alphaComponent ] > 0)
				{
					int amount = 0;
					if ([ [ bitmap colorAtX:x+1 y:y ] redComponent ] == 0 && [ [ bitmap colorAtX:x+1 y:y ] greenComponent ] == 0 && [ [ bitmap colorAtX:x+1 y:y ] blueComponent ] == 0 && [ [ bitmap colorAtX:x+1 y:y ] alphaComponent ] > 0)
						amount++;
					if ([ [ bitmap colorAtX:x-1 y:y ] redComponent ] == 0 && [ [ bitmap colorAtX:x-1 y:y ] greenComponent ] == 0 && [ [ bitmap colorAtX:x-1 y:y ] blueComponent ] == 0 && [ [ bitmap colorAtX:x-1 y:y ] alphaComponent ] > 0)
						amount++;
					if ([ [ bitmap colorAtX:x y:y+1 ] redComponent ] == 0 && [ [ bitmap colorAtX:x y:y+1 ] greenComponent ] == 0 && [ [ bitmap colorAtX:x y:y+1 ] blueComponent ] == 0 && [ [ bitmap colorAtX:x y:y+1 ] alphaComponent ] > 0)
						amount++;
					if ([ [ bitmap colorAtX:x y:y-1 ] redComponent ] == 0 && [ [ bitmap colorAtX:x y:y-1 ] greenComponent ] == 0 && [ [ bitmap colorAtX:x y:y-1 ] blueComponent ] == 0 && [ [ bitmap colorAtX:x y:y-1 ] alphaComponent ] > 0)
						amount++;
					
					int nsides = 0;
					if ([ [ bitmap colorAtX:x+1 y:y+1 ] redComponent ] == 0 && [ [ bitmap colorAtX:x+1 y:y+1 ] greenComponent ] == 0 && [ [ bitmap colorAtX:x+1 y:y+1 ] blueComponent ] == 0 && [ [ bitmap colorAtX:x+1 y:y+1 ] alphaComponent ] > 0)
						nsides++;
					if ([ [ bitmap colorAtX:x+1 y:y-1 ] redComponent ] == 0 && [ [ bitmap colorAtX:x+1 y:y-1 ] greenComponent ] == 0 && [ [ bitmap colorAtX:x+1 y:y-1 ] blueComponent ] == 0 && [ [ bitmap colorAtX:x+1 y:y-1 ] alphaComponent ] > 0)
						nsides++;
					if ([ [ bitmap colorAtX:x-1 y:y+1 ] redComponent ] == 0 && [ [ bitmap colorAtX:x-1 y:y+1 ] greenComponent ] == 0 && [ [ bitmap colorAtX:x-1 y:y+1 ] blueComponent ] == 0 && [ [ bitmap colorAtX:x-1 y:y+1 ] alphaComponent ] > 0)
						nsides++;
					if ([ [ bitmap colorAtX:x-1 y:y-1 ] redComponent ] == 0 && [ [ bitmap colorAtX:x-1 y:y-1 ] greenComponent ] == 0 && [ [ bitmap colorAtX:x-1 y:y-1 ] blueComponent ] == 0 && [ [ bitmap colorAtX:x-1 y:y-1 ] alphaComponent ] > 0)
						nsides++;
					
					if (amount != 4 || nsides != 4)
						points.push_back(NSMakePoint(x, y));
						}
			}
		}

		// Check to see if that each point is touching at least 2 other points
		for (int z = 0; z < points.size(); z++)
		{
			int touching = 0;
			for (int y = 0; y < points.size(); y++)
			{
				if (points[z].x == points[y].x + 1 && points[z].y == points[y].y)
					touching++;
				if (points[z].x == points[y].x - 1 && points[z].y == points[y].y)
					touching++;
				if (points[z].x == points[y].x && points[z].y == points[y].y + 1)
					touching++;
				if (points[z].x == points[y].x && points[z].y == points[y].y - 1)
					touching++;
				
				if (touching > 1)
					break;
			}
			if (touching < 2)
			{
				points.erase(points.begin() + z);
				z--;
			}
		}

		shapes2.clear();
		if (points.size() == 0)
		{
			percent = 100;
			calculating = FALSE;
			return nil;
		}

		// Find lines
		NSPoint startPoint = NSMakePoint([ image size ].width, [ image size ].height);
		startPoint = points[0];
		std::vector<NSPoint> newPoints;
		newPoints.push_back(startPoint);
		NSPoint currentPoint = startPoint;
		unsigned long originalSize = points.size();
		std::vector<NSPoint> helpPoints;
		BOOL doX = TRUE;
		int direction = 1;
		for (;;)
		{
			NSPoint pB = currentPoint;
			// Go in the direction
			if (doX)
				currentPoint.x += direction;
				else
					currentPoint.y += direction;
					
					// Check if this is a real point
					BOOL isValid = FALSE;
					for (int z = 0; z < points.size(); z++)
					{
						if (points[z].x == currentPoint.x && points[z].y == currentPoint.y)
						{
							isValid = TRUE;
							// Check how many ways to go there are
							int many = 0;
							for (int q = 0; q < points.size(); q++)
							{
								if (points[q].x == points[z].x + 1 && points[q].y == points[z].y)
									many++;
								if (points[q].x == points[z].x - 1 && points[q].y == points[z].y)
									many++;
								if (points[q].x == points[z].x && points[q].y == points[z].y + 1)
									many++;
								if (points[q].x == points[z].x && points[q].y == points[z].y - 1)
									many++;
								// Don't count the last direction
								if (points[q].x == pB.x && points[q].y == pB.y)
									many--;
								if (many == 2)
									break;
							}
							if (many == 2)
							{
								// Check to see if this is touching all the help points
								//BOOL touching = TRUE;
								for (int q = 0; q < helpPoints.size(); q++)
								{
									int many2 = 0;
									if (helpPoints[q].x == points[z].x + 1 && helpPoints[q].y == points[z].y)
										many2++;
									if (helpPoints[q].x == points[z].x - 1 && helpPoints[q].y == points[z].y)
										many2++;
									if (helpPoints[q].x == points[z].x && helpPoints[q].y == points[z].y + 1)
										many2++;
									if (helpPoints[q].x == points[z].x && helpPoints[q].y == points[z].y - 1)
										many2++;
									if (many2 == 0)
									{
									//	touching = FALSE;
										break;
									}
								}
								// If we don't have pB, add it
								BOOL haveP = FALSE;
								for (int q = 0; q < helpPoints.size(); q++)
								{
									if (helpPoints[q].x == pB.x && helpPoints[q].y == pB.y)
									{
										haveP = TRUE;
										break;
									}
								}
								// And if it isn't the start point
								if (!haveP && !(pB.x == startPoint.x && pB.y == startPoint.y))
									helpPoints.push_back(pB);
								// Same with points[z]
								haveP = FALSE;
								for (int q = 0; q < helpPoints.size(); q++)
								{
									if (helpPoints[q].x == points[z].x && helpPoints[q].y == points[z].y)
									{
										haveP = TRUE;
										break;
									}
								}
								if (!haveP && !(points[z].x == startPoint.x && points[z].y == startPoint.y))
									helpPoints.push_back(points[z]);
							}
							points.erase(points.begin() + z);
							percent = 100 - ((float)points.size() / originalSize * 100);
							break;
						}
					}
			if (!isValid && direction == 1)
			{
				direction *= -1;
				currentPoint = pB;
				// Try again
				continue;
			}
			else if (!isValid && direction == -1)
			{
				if (doX)
				{
					doX = !doX;
					direction = 1;
					currentPoint = pB;
					// Try again
					continue;
				}
				else
				{
					// If there are no points, that would explain why
					if (points.size() == 0)
						break;
					// If there are help points, add those and see
					if (helpPoints.size() != 0)
					{
						for (int z = 0; z < helpPoints.size(); z++)
							points.push_back(helpPoints[z]);
							helpPoints.clear();
							
							// Add this current point
							newPoints.push_back(pB);
							
							// Try with those points
							direction = 1;
							doX = TRUE;
							currentPoint = pB;
							continue;
					}
					
					// There are still points left
					BOOL found = FALSE;
					// Check if one if them is the start point
					for (int z = 0; z < points.size(); z++)
					{
						if (startPoint.x == points[z].x && startPoint.y == points[z].y)
						{
							// Erase it
							found = TRUE;
							points.erase(points.begin() + z);
							break;
						}
					}
					
					if (found)
						currentPoint = startPoint;
						else
						{
							// Otherwise, Error
							NSLog(@"Error: No where to go, (%f, %f), %lu", pB.x, pB.y, points.size());
							shapes2.push_back(newPoints);
							newPoints.clear();
							// And Exit
							break;
						}
				}
			}
			else if (isValid)
			{
				// Check if there is point in the other direction
				int backupDir = direction;
				NSPoint backupPoint = currentPoint;
				direction = 1;
			check:
				if (doX)
					currentPoint.y += direction;
					else
						currentPoint.x += direction;
						// Check
						isValid = FALSE;
						for (int z = 0; z < points.size(); z++)
						{
							if (points[z].x == currentPoint.x && points[z].y == currentPoint.y)
							{
								isValid = TRUE;
								break;
							}
						}
				if (isValid)
				{
					// Set that way
					doX = !doX;
					currentPoint = backupPoint;
					// Add it
					newPoints.push_back(currentPoint);
				}
				else if (!isValid && direction == 1)
				{
					direction *= -1;
					currentPoint = backupPoint;
					goto check;
				}
				else	// Keep going
				{
					currentPoint = backupPoint;
					direction = backupDir;
				}
			}
			
			if (startPoint.x == currentPoint.x && currentPoint.y == startPoint.y)
			{
				// Polygon complete
				shapes2.push_back(newPoints);
				newPoints.clear();
				// Find next point
				if (points.size() == 0)
					break;
				startPoint = points[0];
				// Add help points in line of this one
				doX = TRUE;
				direction = 1;
				NSPoint backupStartPoint = startPoint;
				for (;;)
				{
					if (doX)
						startPoint.x += direction;
						else
							startPoint.y += direction;
							// Check all help points
							BOOL found = FALSE;
							for (int z = 0; z < helpPoints.size(); z++)
							{
								if (startPoint.x == helpPoints[z].x && startPoint.y == helpPoints[z].y)
								{
									points.insert(points.begin(), helpPoints[z]);
									found = TRUE;
									break;
								}
							}
					
					if (!found)
					{
						// Check if its a part of points
						for (int z = 0; z < points.size(); z++)
						{
							if (startPoint.x == points[z].x && startPoint.y == points[z].y)
							{
								found = TRUE;
								break;
							}
						}
					}
					
					if (!found && direction == 1)
					{
						direction *= -1;
						startPoint = backupStartPoint;
					}
					else if (!found && direction == -1 && doX == TRUE)
					{
						direction *= -1;
						doX = !doX;
						startPoint = backupStartPoint;
					}
					else if (!found)		// If still not found
						break;
				}
				helpPoints.clear();
				// Find the real start point
				startPoint = points[0];
				newPoints.push_back(startPoint);
				currentPoint = startPoint;
				doX = TRUE;
				direction = 1;
			}
			if (points.size() == 0)
			{
				shapes2.push_back(newPoints);
				newPoints.clear();
				break;
			}
		}

		points.clear();
		if (shapes2.size() < 1 || (shapes2.size() != 0 && shapes2[0].size() < 1))
		{
			shapes2.clear();
			calculating = FALSE;
			percent = 100;
			return nil;
		}
		
		unsigned long numOfPoints = 0;
		for (int z = 0; z < shapes2.size(); z++)
			numOfPoints += shapes2[z].size();
		if (numOfPoints == 0)
		{
			shapes2.clear();
			calculating = FALSE;
			percent = 100;
			return nil;
		}

		// Tesselate
		GLUtesselator* tess = gluNewTess();

		gluTessCallback(tess, GLU_TESS_BEGIN, (void (*)())beginTess);
		gluTessCallback(tess, GLU_TESS_END, (void (*)())endTess);
		gluTessCallback(tess, GLU_TESS_ERROR, (void (*)())errorTess);
		gluTessCallback(tess, GLU_TESS_VERTEX, (void (*)())vertexTess);

		std::vector< std::vector<NSPoint> > countours = shapes2;
		shapes.clear();

		double* verticies = (double*)malloc(sizeof(double) * numOfPoints * 3);
		unsigned long currentOffset = 0;
		for (int z = 0; z < countours.size(); z++)
		{
			for (int y = 0; y < countours[z].size(); y++)
			{
				verticies[currentOffset] = countours[z][y].x;
				verticies[currentOffset + 1] = countours[z][y].y;
				verticies[currentOffset + 2] = 0;
				currentOffset += 3;
			}
		}
		currentOffset = 0;
		gluTessBeginPolygon(tess, NULL);
		{
			for (int q = 0; q < countours.size(); q++)
			{
				gluTessBeginContour(tess);
				{
					points = countours[q];
					for (int z = 0; z < points.size(); z++)
					{
						gluTessVertex(tess, &verticies[currentOffset], &verticies[currentOffset]);
						currentOffset += 3;
					}
				}
				gluTessEndContour(tess);
			}
		}
		gluTessEndPolygon(tess);

		free(verticies);
		verticies = NULL;

		gluDeleteTess(tess);

		// Normals are temporarily disabled
		/*normals.clear();
		for (int z = 0; z < shapes2.size(); z++)
		{
			Normal normal;
			memset(&normal, 0, sizeof(Normal));
			std::vector<Normal> norms;
			for (int q = 0; q < shapes2[z].size() - 1; q++)
			{
				long index = (q + 1) % shapes2[z].size();
				Vertex p = { TX(shapes2[z][q].x, 5 + zpos), TY(shapes2[z][q].y, 5 + zpos), 0 };
				Vertex p1 = { TX(shapes2[z][q].x, 5 + zpos), TY(shapes2[z][q].y, 5 + zpos), DEPTH };
				Vertex p2 = { TX(shapes2[z][index].x, 5 + zpos), TY(shapes2[z][index].y, 5 + zpos), 0 };
				Vertex v1[3] = { p, p1, p2 };
				normalizeTriangle(v1, &normal);
				
				// Check if points are clockwise or counter clockwise
				float sum = 0;
				sum += (p1.x - p.x) * (p1.y - p.y);
				sum += (p2.x - p1.x) * (p2.y - p1.y);
				sum += (p.x - p2.x) * (p.y - p2.y);
				if (sum < 0)		// Counter - Clockwise
				{
					normal.x *= -1;
					normal.y *= -1;
				}
				//	normal.x *= -1;
				//	normal.y *= -1;
				norms.push_back(normal);
			}
			normals.push_back(norms);
		}*/
	}
	
	NSRect rect = NSMakeRect(100000, 100000, 0, 0);
	for (int z = 0; z < shapes.size(); z++)
	{
		for (int y = 0; y < shapes[z].points.size(); y++)
		{
			if (rect.origin.x > shapes[z].points[y].x)
				rect.origin.x = shapes[z].points[y].x;
			if (rect.origin.y > shapes[z].points[y].y)
				rect.origin.y = shapes[z].points[y].y;
			if (rect.size.width < shapes[z].points[y].x)
				rect.size.width = shapes[z].points[y].x;
			if (rect.size.height < shapes[z].points[y].y)
				rect.size.height = shapes[z].points[y].y;
		}
	}
	rect.size.width -= rect.origin.x;
	rect.size.height -= rect.origin.y;
	Vertex midPoint;
	midPoint.x = -(rect.size.width / 2);
	midPoint.y = -(rect.size.height / 2);
	midPoint.z = 0;//dep / 2;
	
	MDInstance* obj = [ [ MDInstance alloc ] init ];
	// Convert points into faces
	for (int z = 0; z < shapes.size() * 2; z++)
	{		
		for (int q = 0; q < shapes[z / 2].points.size(); q++)
		{
			MDPoint* p = [ [ MDPoint alloc ] init ];
			[ p setX:TX(shapes[z / 2].points[q].x - midPoint.x, 20) ];
			[ p setY:TY(shapes[z / 2].points[q].y - midPoint.y, 20) - 10 ];
			[ p setZ:((z % 2) == 0) ? 0 : -dep ];
			/*[ p setRed:1 ];
			[ p setGreen:1 ];
			[ p setBlue:1 ];
			[ p setAlpha:1 ];*/
			[ p setNormalX:0 ];
			[ p setNormalY:0 ];
			[ p setNormalZ:((z % 2) == 0) ? 1 : -1 ];
			[ obj addPoint:p ];
		}
	}
	// And more
	for (int z = 0; z < shapes2.size(); z++)
	{
		if (shapes2[z].size() <= 2)
			continue;
		
		for (int q = 0; q < 2; q++)
		{
			MDPoint* p1 = [ [ MDPoint alloc ] init ];
			[ p1 setX:TX(shapes2[z][0].x - midPoint.x, 20) ];
			[ p1 setY:TY(shapes2[z][0].y - midPoint.y, 20) - 10 ];
			[ p1 setZ:(q == 0) ? 0 : -dep ];
			/*[ p1 setRed:1 ];
			[ p1 setGreen:1 ];
			[ p1 setBlue:1 ];
			[ p1 setAlpha:1 ];*/
			[ obj addPoint:p1 ];
		}
		for (int q = 1; q < shapes2[z].size() * 2; q++)
		{
			MDPoint* p = [ [ MDPoint alloc ] init ];
			[ p setX:TX(shapes2[z][q / 2].x - midPoint.x, 20) ];
			[ p setY:TY(shapes2[z][q / 2].y - midPoint.y, 20) - 10 ];
			[ p setZ:((q % 2) == 1) ? 0 : -dep ];
			/*[ p setRed:1 ];
			[ p setGreen:1 ];
			[ p setBlue:1 ];
			[ p setAlpha:1 ];*/
			[ p setNormalX:0 ];
			[ p setNormalY:0 ];
			[ p setNormalZ:0 ];
			[ obj addPoint:p ];
		}
	}
	[ obj setMidPoint:MDVector3Create(0, 0, 0) ];

	calculating = FALSE;

	return obj;
}

+ (NSNumber*) create2DText: (NSAttributedString*) text removeBlack:(BOOL)black
{
	NSSize size = [ text size ];
	NSImage* image = [ [ NSImage alloc ] initWithSize:NSMakeSize(size.width, size.height) ];
	[ image lockFocus ];
	[ [ NSGraphicsContext currentContext ] setShouldAntialias:YES ];
	[ [ NSColor whiteColor ] set ];
	[ text drawAtPoint:NSMakePoint(0, 0) ];
	NSBitmapImageRep* bitmap = [ [ NSBitmapImageRep alloc ] initWithFocusedViewRect:NSMakeRect(0, 0, size.width, size.height) ];
	[ image unlockFocus ];
	
	for (int y = 0; y < [ bitmap pixelsHigh ]; y++)
	{
		for (int x = 0; x < [ bitmap pixelsWide ]; x++)
		{
			if (black)
			{
				if ([ bitmap colorAtX:x y:y ] != [ NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:1 ])
					[ bitmap setColor:[ NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:0 ] atX:x y:y ];
			}
			else
			{
				NSColor* color = [ bitmap colorAtX:x y:y ];
 				if ([ color redComponent ] == 0 && [ color greenComponent ] == 0 && [ color blueComponent ] == 0)
					[ bitmap setColor:[ NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:0 ] atX:x y:y ];
			}
		}
	}	
	long bitsPPixel = [ bitmap bitsPerPixel ];
	long bytesPRow = [ bitmap bytesPerRow ];
	GLenum texFormat = GL_RGB;
	if (bitsPPixel == 24)
		texFormat = GL_RGB;
	else if (bitsPPixel == 32)
		texFormat = GL_RGBA;
	NSSize texSize = NSMakeSize([ bitmap pixelsWide ], [ bitmap pixelsHigh ]);
	unsigned char* tdata = (unsigned char*)malloc(bytesPRow * texSize.height);
	
	if (tdata)
	{
		unsigned int destRowNum = 0;
		for( int rowNum = texSize.height - 1; rowNum >= 0;
			rowNum--, destRowNum++ )
		{
			// Copy the entire row in one shot
			memcpy(tdata + ( destRowNum * bytesPRow ),
				   [ bitmap bitmapData ] + ( rowNum * bytesPRow ),
				   bytesPRow );
		}
	}
	
	unsigned int img = 0;
	glGenTextures(1, &img);
	glBindTexture(GL_TEXTURE_2D, img);
	
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, texSize.width,
				 texSize.height, 0, texFormat,
				 GL_UNSIGNED_BYTE, tdata);
	
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	
	free(tdata);
	tdata = NULL;
	
	return @(img);
}

@end
