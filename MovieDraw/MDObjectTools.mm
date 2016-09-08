//
//  MDObjectTools.mm
//  MovieDraw
//
//  Created by Neil on 7/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MDObjectTools.h"
#import <OpenGL/OpenGL.h>
#undef __gl_h_
#import <OpenGL/gl3.h>
#import "MDGUI.h"
#import <cmath>
#import "Controller.h"
#import "GLView.h"

float diff = 0;

MDVector3 RotateX(MDVector3 point, MDVector3 around, float xrot)
{
	float radianX = xrot / 180 * M_PI;
	MDVector3 real = MDVector3Create(point.x - around.x, point.y - around.y, point.z - around.z);
	MDVector3 real2 = MDVector3Create(real.x, real.y * cos(radianX) - real.z * sin(radianX), real.y * sin(radianX) + real.z * cos(radianX));
	return MDVector3Create(real2.x + around.x, real2.y + around.y, real2.z + around.z);
}

MDVector3 RotateY(MDVector3 point, MDVector3 around, float yrot)
{
	float radianY = yrot / 180 * M_PI;
	MDVector3 real = MDVector3Create(point.x - around.x, point.y - around.y, point.z - around.z);
	MDVector3 real2 = MDVector3Create(real.z * sin(radianY) + real.x * cos(radianY), real.y, real.z * cos(radianY) - real.x * sin(radianY));
	return MDVector3Create(real2.x + around.x, real2.y + around.y, real2.z + around.z);

}

MDVector3 RotateZ(MDVector3 point, MDVector3 around, float zrot)
{
	float radianZ = zrot / 180 * M_PI;
	MDVector3 real = MDVector3Create(point.x - around.x, point.y - around.y, point.z - around.z);
	MDVector3 real2 = MDVector3Create(real.x * cos(radianZ) - real.y * sin(radianZ), real.x * sin(radianZ) + real.y * cos(radianZ), real.z);
	return MDVector3Create(real2.x + around.x, real2.y + around.y, real2.z + around.z);
}

MDVector3 Rotate(MDVector3 point, MDVector3 around, float xrot, float yrot, float zrot)
{
	return RotateX(RotateY(RotateZ(point, around, zrot), around, yrot), around, xrot);
}

MDVector3 RotateB(MDVector3 point, MDVector3 around, float xrot, float yrot, float zrot)
{
	return RotateZ(RotateY(RotateX(point, around, xrot), around, yrot), around, zrot);
}

MDVector3 RotateAxis(MDVector3 p, MDVector3 line, float angle)
{
	if (MDVector3Magnitude(line) == 0.0 || angle == 0.0)
		return p;
	
	float theta = angle / 180.0 * M_PI;
	MDVector3 p1 = MDVector3Normalize(line);
	
	/* Step 1 */
	MDVector3 q1 = p - p1;
	MDVector3 u = MDVector3Normalize(p1 * -1.0);
	float d = sqrt(u.y*u.y + u.z*u.z);
	
	MDVector3 q2;
	/* Step 2 */
	if (d != 0.0)
	{
		q2.x = q1.x;
		q2.y = q1.y * u.z / d - q1.z * u.y / d;
		q2.z = q1.y * u.y / d + q1.z * u.z / d;
	}
	else
		q2 = q1;
	
	/* Step 3 */
	q1.x = q2.x * d - q2.z * u.x;
	q1.y = q2.y;
	q1.z = q2.x * u.x + q2.z * d;
	
	/* Step 4 */
	float ct = cos(theta), st = sin(theta);
	q2.x = q1.x * ct - q1.y * st;
	q2.y = q1.x * st + q1.y * ct;
	q2.z = q1.z;
	
	/* Inverse of step 3 */
	q1.x =   q2.x * d + q2.z * u.x;
	q1.y =   q2.y;
	q1.z = - q2.x * u.x + q2.z * d;
	
	/* Inverse of step 2 */
	if (d != 0.0)
	{
		q2.x =   q1.x;
		q2.y =   q1.y * u.z / d + q1.z * u.y / d;
		q2.z = - q1.y * u.y / d + q1.z * u.z / d;
	}
	else
		q2 = q1;
	
	/* Inverse of step 1 */
	q1 = q2 + p1;
	return(q1);
}

MDRect BoundingBoxRotate(MDObject* obj)
{
	float left = 100000, right = -10000, top = 10000, bot = -10000, front = -10000, back = 10000;		// values
	MDVector3 midpoint = MDVector3Create(0, 0, 0);// Assumed to be 0 ->[ obj midPoint ];
	unsigned long numPoints = [ obj numberOfPoints ];
	for (unsigned long y = 0; y < numPoints; y++)
	{
		MDPoint* point = [ obj pointAtIndex:y ];
		MDVector3 p = MDVector3Create(point.x, point.y, point.z);
		p.x -= midpoint.x;
		p.y -= midpoint.y;
		p.z -= midpoint.z;
		p.x *= obj.scaleX;
		p.y *= obj.scaleY;
		p.z *= obj.scaleZ;
		p.x += midpoint.x;
		p.y += midpoint.y;
		p.z += midpoint.z;
		//p = Rotate(p, midpoint, obj.rotateX, obj.rotateY, obj.rotateZ);
		p = RotateAxis(p - midpoint, obj.rotateAxis, obj.rotateAngle) + midpoint;
		if (p.x < left)
			left = p.x;
		if (p.x > right)
			right = p.x;
		if (p.y < top)
			top = p.y;
		if (p.y > bot)
			bot = p.y;
		if (p.z > front)
			front = p.z;
		if (p.z < back)
			back = p.z;
	}
	MDRect rect = MakeRect(left, bot, front, right - left, top - bot, back - front);
	rect.x += obj.translateX;
	rect.y += obj.translateY;
	rect.z += obj.translateZ;
	
	return rect;
}

MDRect BoundingBoxInstance(MDInstance* obj)
{
	float left = 100000, right = -10000, top = 10000, bot = -10000, front = -10000, back = 10000;		// values
	for (int y = 0; y < [ obj numberOfPoints ]; y++)
	{
		MDPoint* point = [ obj pointAtIndex:y ];
		MDVector3 p = MDVector3Create(point.x, point.y, point.z);
		if (p.x < left)
			left = p.x;
		if (p.x > right)
			right = p.x;
		if (p.y < top)
			top = p.y;
		if (p.y > bot)
			bot = p.y;
		if (p.z > front)
			front = p.z;
		if (p.z < back)
			back = p.z;
	}
	MDRect rect = MakeRect(left, bot, front, right - left, top - bot, back - front);
	return rect;
}

std::vector<MDVector3> MDRectToPoints(MDRect rect)
{
	std::vector<MDVector3> points;
	
	float value = rect.z;
	if (rect.z + rect.depth > rect.z)
		value = rect.z + rect.depth;
	// Front
	points.push_back(MDVector3Create(rect.x, rect.y, value));
	points.push_back(MDVector3Create(rect.x + rect.width, rect.y, value));
	points.push_back(MDVector3Create(rect.x + rect.width, rect.y + rect.height, value));
	points.push_back(MDVector3Create(rect.x, rect.y + rect.height, value));
	
	return points;
}

MDRect PointsToMDRect(std::vector<MDVector3> points)
{
	float lx = 100000, rx = -100000, uy = -100000, dy = 100000, fz = -10000, bz = 10000;
	for (int z = 0; z < points.size(); z++)
	{
		MDVector3 p = points[z];
		if (p.x < lx)
			lx = p.x;
		if (p.x > rx)
			rx = p.x;
		if (p.y < dy)
			dy = p.y;
		if (p.y > uy)
			uy = p.y;
		if (p.z < bz)
			bz = p.z;
		if (p.z > fz)
			fz = p.z;
	}
	
	return MakeRect(lx, dy, bz, rx - lx, uy - dy, fz - bz);
}

std::vector<MDVector3> BoundingBox(MDObject* obj)
{
	float left = 100000, right = -10000, top = 10000, bot = -10000, front = -10000, back = 10000;		// values
	for (int y = 0; y < [ obj numberOfPoints ]; y++)
	{
		MDPoint* point = [ obj pointAtIndex:y ];
		MDVector3 p = MDVector3Create(point.x, point.y, point.z);
		if (p.x < left)
			left = p.x;
		if (p.x > right)
			right = p.x;
		if (p.y < top)
			top = p.y;
		if (p.y > bot)
			bot = p.y;
		if (p.z > front)
			front = p.z;
		if (p.z < back)
			back = p.z;
	}
	MDRect rect = MakeRect(left, bot, front, right - left, top - bot, back - front);
	rect.x *= obj.scaleX;
	rect.width *= obj.scaleX;
	rect.y *= obj.scaleY;
	rect.height *= obj.scaleY;
	rect.z *= obj.scaleZ;
	rect.depth *= obj.scaleZ;
	rect.x += obj.translateX;
	rect.y += obj.translateY;
	rect.z += obj.translateZ;
	
	// Add them to the points
	std::vector<MDVector3> points;
	// Front
	points.push_back(MDVector3Create(rect.x, rect.y, rect.z));
	points.push_back(MDVector3Create(rect.x + rect.width, rect.y, rect.z));
	points.push_back(MDVector3Create(rect.x + rect.width, rect.y, rect.z));
	points.push_back(MDVector3Create(rect.x + rect.width, rect.y + rect.height, rect.z));
	points.push_back(MDVector3Create(rect.x + rect.width, rect.y + rect.height, rect.z));
	points.push_back(MDVector3Create(rect.x, rect.y + rect.height, rect.z));
	points.push_back(MDVector3Create(rect.x, rect.y + rect.height, rect.z));
	points.push_back(MDVector3Create(rect.x, rect.y, rect.z));
	
	// Top
	points.push_back(MDVector3Create(rect.x, rect.y, rect.z));
	points.push_back(MDVector3Create(rect.x, rect.y, rect.z + rect.depth));
	points.push_back(MDVector3Create(rect.x + rect.width, rect.y, rect.z + rect.depth));
	points.push_back(MDVector3Create(rect.x + rect.width, rect.y, rect.z));
	
	// Bottom
	points.push_back(MDVector3Create(rect.x, rect.y + rect.height, rect.z));
	points.push_back(MDVector3Create(rect.x, rect.y + rect.height, rect.z + rect.depth));
	points.push_back(MDVector3Create(rect.x + rect.width, rect.y + rect.height, rect.z + rect.depth));
	points.push_back(MDVector3Create(rect.x + rect.width, rect.y + rect.height, rect.z));
	
	// Back
	points.push_back(MDVector3Create(rect.x, rect.y, rect.z + rect.depth));
	points.push_back(MDVector3Create(rect.x + rect.width, rect.y, rect.z + rect.depth));
	points.push_back(MDVector3Create(rect.x + rect.width, rect.y, rect.z + rect.depth));
	points.push_back(MDVector3Create(rect.x + rect.width, rect.y + rect.height, rect.z + rect.depth));
	points.push_back(MDVector3Create(rect.x + rect.width, rect.y + rect.height, rect.z + rect.depth));
	points.push_back(MDVector3Create(rect.x, rect.y + rect.height, rect.z + rect.depth));
	points.push_back(MDVector3Create(rect.x, rect.y + rect.height, rect.z + rect.depth));
	points.push_back(MDVector3Create(rect.x, rect.y, rect.z + rect.depth));
	
	MDVector3 realMidpoint = MDVector3Create(obj.translateX, obj.translateY, obj.translateZ);// + obj.rotatePoint;
	for (int z = 0; z < points.size(); z++)
		points[z] = RotateAxis(points[z] - realMidpoint, obj.rotateAxis, -obj.rotateAngle) + realMidpoint;//RotateB(points[z], realMidpoint, obj.rotateX, obj.rotateY, obj.rotateZ);
	
	return points;
}

MDObject* ApplyTransformations(MDObject* obj2)
{
	MDObject* obj = [ [ MDObject alloc ] initWithObject:obj2 ];
	for (int y = 0; y < [ obj numberOfPoints ]; y++)
	{
		MDPoint* p = [ obj pointAtIndex:y ];
		p.x *= obj.scaleX;
		p.y *= obj.scaleY;
		p.z *= obj.scaleZ;
		p.x += obj.translateX;
		p.y += obj.translateY;
		p.z += obj.translateZ;
		
		MDVector3 realMidpoint = MDVector3Create(obj.translateX, obj.translateY, obj.translateZ);
		MDVector3 point = MDVector3Create(p.x, p.y, p.z);
		//point = Rotate(point, realMidpoint + obj.rotatePoint, obj.rotateX, obj.rotateY, obj.rotateZ);
		point = RotateAxis(point - realMidpoint, obj.rotateAxis, -obj.rotateAngle) + realMidpoint - MDVector3Create(obj.translateX, obj.translateY, obj.translateZ);
		
		p.x = point.x;
		p.y = point.y;
		p.z = point.z;
		
		MDVector3 normal = MDVector3Create(p.normalX, p.normalY, p.normalZ);
		//normal = Rotate(normal, MDVector3Create(0, 0, 0), obj.rotateX, obj.rotateY, obj.rotateZ);
		normal = RotateAxis(normal, obj.rotateAxis, -obj.rotateAngle);
		p.normalX = normal.x * (obj.scaleX / fabs(obj.scaleX));
		p.normalY = normal.y * (obj.scaleY / fabs(obj.scaleY));
		p.normalZ = normal.z * (obj.scaleZ / fabs(obj.scaleZ));
	}
	
	float scales[3] = { obj.scaleX, obj.scaleY, obj.scaleZ };
	for (unsigned int z = 0; z < 3; z++)
	{
		if (scales[z] >= 0)
			continue;
		
		MDInstance* face = [ obj instance ];
		// Flips indicies
		for (unsigned long y = 0; y < [ face numberOfIndices ]; y += 3)
		{
			unsigned int i1 = [ face indexAtIndex:y ];
			unsigned int i3 = [ face indexAtIndex:y + 2 ];
			[ face setIndex:i1 atIndex:y + 2 ];
			[ face setIndex:i3 atIndex:y ];
		}
	}
	
	//obj.translateX = obj.translateY = obj.translateZ = 0;
	obj.rotateAngle = 0;
	obj.rotateAxis = MDVector3Create(0, 0, 0);
	obj.scaleX = obj.scaleY = obj.scaleZ = 1;
	
	[ [ obj instance ] setupVBO ];
	
	commandFlag |= UPDATE_INFO;
	
	return obj;
}

MDObject* ApplyTransformationsTranslates(MDObject* obj2)
{
	MDObject* obj = [ [ MDObject alloc ] initWithObject:obj2 ];
	for (int y = 0; y < [ obj numberOfPoints ]; y++)
	{
		MDPoint* p = [ obj pointAtIndex:y ];
		p.x *= obj.scaleX;
		p.y *= obj.scaleY;
		p.z *= obj.scaleZ;
		p.x += obj.translateX;
		p.y += obj.translateY;
		p.z += obj.translateZ;
		
		MDVector3 realMidpoint = MDVector3Create(obj.translateX, obj.translateY, obj.translateZ);
		MDVector3 point = MDVector3Create(p.x, p.y, p.z);
		//point = Rotate(point, realMidpoint + obj.rotatePoint, obj.rotateX, obj.rotateY, obj.rotateZ);
		point = RotateAxis(point - realMidpoint, obj.rotateAxis, -obj.rotateAngle) + realMidpoint;
		p.x = point.x;
		p.y = point.y;
		p.z = point.z;
		
		MDVector3 normal = MDVector3Create(p.normalX, p.normalY, p.normalZ);
		//normal = Rotate(normal, MDVector3Create(0, 0, 0), obj.rotateX, obj.rotateY, obj.rotateZ);
		normal = RotateAxis(normal, obj.rotateAxis, -obj.rotateAngle);
		p.normalX = normal.x * (obj.scaleX / fabs(obj.scaleX));
		p.normalY = normal.y * (obj.scaleY / fabs(obj.scaleY));
		p.normalZ = normal.z * (obj.scaleZ / fabs(obj.scaleZ));
	}
	
	float scales[3] = { obj.scaleX, obj.scaleY, obj.scaleZ };
	for (unsigned int z = 0; z < 3; z++)
	{
		if (scales[z] >= 0)
			continue;
		
		MDInstance* face = [ obj instance ];
		// Flips indicies
		for (unsigned long y = 0; y < [ face numberOfIndices ]; y += 3)
		{
			unsigned int i1 = [ face indexAtIndex:y ];
			unsigned int i3 = [ face indexAtIndex:y + 2 ];
			[ face setIndex:i1 atIndex:y + 2 ];
			[ face setIndex:i3 atIndex:y ];
		}
	}
	
	obj.translateX = obj.translateY = obj.translateZ = 0;
	obj.rotateAngle = 0;
	obj.rotateAxis = MDVector3Create(0, 0, 0);
	obj.scaleX = obj.scaleY = obj.scaleZ = 1;
	
	[ [ obj instance ] setupVBO ];
	
	commandFlag |= UPDATE_INFO;
	
	return obj;
}

MDInstance* ApplyTransformationInstance(MDObject* obj)
{
	MDInstance* inst = [ [ MDInstance alloc ] initWithInstance:[ obj instance ] ];
	for (int y = 0; y < [ obj numberOfPoints ]; y++)
	{
		MDPoint* p = [ inst pointAtIndex:y ];
		MDVector3 point = MDMatrixMultiply([ obj modelViewMatrix ], MDVector4Create(p.x, p.y, p.z, 1.0)).GetXYZ();
		
		p.x = point.x;
		p.y = point.y;
		p.z = point.z;
		
		MDVector3 normal = MDVector3Create(p.normalX, p.normalY, p.normalZ);
		normal = RotateAxis(normal, obj.rotateAxis, -obj.rotateAngle);
		p.normalX = normal.x * (obj.scaleX / fabs(obj.scaleX));
		p.normalY = normal.y * (obj.scaleY / fabs(obj.scaleY));
		p.normalZ = normal.z * (obj.scaleZ / fabs(obj.scaleZ));
	}
	
	float scales[3] = { obj.scaleX, obj.scaleY, obj.scaleZ };
	for (unsigned int z = 0; z < 3; z++)
	{
		if (scales[z] >= 0)
			continue;
		
		// Flips indicies
		for (unsigned long y = 0; y < [ inst numberOfIndices ]; y += 3)
		{
			unsigned int i1 = [ inst indexAtIndex:y ];
			unsigned int i3 = [ inst indexAtIndex:y + 2 ];
			[ inst setIndex:i1 atIndex:y + 2 ];
			[ inst setIndex:i3 atIndex:y ];
		}
	}
	
	[ inst setupVBO ];
		
	return inst;
}

MDInstance* ApplyTransformationInstanceTranslates(MDObject* obj)
{
	MDInstance* inst = [ [ MDInstance alloc ] initWithInstance:[ obj instance ] ];
	for (int y = 0; y < [ obj numberOfPoints ]; y++)
	{
		MDPoint* p = [ inst pointAtIndex:y ];
		MDVector3 point = MDMatrixMultiply([ obj modelViewMatrix ], MDVector4Create(p.x, p.y, p.z, 1.0)).GetXYZ();
		
		p.x = point.x - [ obj translateX ];
		p.y = point.y - [ obj translateY ];
		p.z = point.z - [ obj translateZ ];
		
		MDVector3 normal = MDVector3Create(p.normalX, p.normalY, p.normalZ);
		normal = RotateAxis(normal, obj.rotateAxis, -obj.rotateAngle);
		p.normalX = normal.x * (obj.scaleX / fabs(obj.scaleX));
		p.normalY = normal.y * (obj.scaleY / fabs(obj.scaleY));
		p.normalZ = normal.z * (obj.scaleZ / fabs(obj.scaleZ));
	}
	
	float scales[3] = { obj.scaleX, obj.scaleY, obj.scaleZ };
	for (unsigned int z = 0; z < 3; z++)
	{
		if (scales[z] >= 0)
			continue;
		
		// Flips indicies
		for (unsigned long y = 0; y < [ inst numberOfIndices ]; y += 3)
		{
			unsigned int i1 = [ inst indexAtIndex:y ];
			unsigned int i3 = [ inst indexAtIndex:y + 2 ];
			[ inst setIndex:i1 atIndex:y + 2 ];
			[ inst setIndex:i3 atIndex:y ];
		}
	}
	
	[ inst setupVBO ];
	
	return inst;
}

void gluCube(float width, float height, float depth)
{
	glBegin(GL_QUADS);
	{
		glNormal3d(0, 0, 1);
		glVertex3d(-width / 2, -height / 2, depth / 2);
		glVertex3d(width / 2, -height / 2, depth / 2);
		glVertex3d(width / 2, height / 2, depth / 2);
		glVertex3d(-width / 2, height / 2, depth / 2);
		
		glNormal3d(0, 0, -1);
		glVertex3d(-width / 2, -height / 2, -depth / 2);
		glVertex3d(width / 2, -height / 2, -depth / 2);
		glVertex3d(width / 2, height / 2, -depth / 2);
		glVertex3d(-width / 2, height / 2, -depth / 2);
		
		glNormal3d(-1, 0, 0);
		glVertex3d(-width / 2, -height / 2, -depth / 2);
		glVertex3d(-width / 2, -height / 2, depth / 2);
		glVertex3d(-width / 2, height / 2, depth / 2);
		glVertex3d(-width / 2, height / 2, -depth / 2);
		
		glNormal3d(1, 0, 0);
		glVertex3d(width / 2, -height / 2, -depth / 2);
		glVertex3d(width / 2, -height / 2, depth / 2);
		glVertex3d(width / 2, height / 2, depth / 2);
		glVertex3d(width / 2, height / 2, -depth / 2);
		
		glNormal3d(0, -1, 0);
		glVertex3d(-width / 2, -height / 2, -depth / 2);
		glVertex3d(-width / 2, -height / 2, depth / 2);
		glVertex3d(width / 2, -height / 2, depth / 2);
		glVertex3d(width / 2, -height / 2, -depth / 2);
		
		glNormal3d(0, 1, 0);
		glVertex3d(-width / 2, height / 2, -depth / 2);
		glVertex3d(-width / 2, height / 2, depth / 2);
		glVertex3d(width / 2, height / 2, depth / 2);
		glVertex3d(width / 2, height / 2, -depth / 2);
	}
	glEnd();
	
	float normals[36 * 3] = {
		0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1,		// Front Face
		0, 0, -1, 0, 0, -1, 0, 0, -1, 0, 0, -1, 0, 0, -1, 0, 0, -1, // Back Face
		-1, 0, 0, -1, 0, 0, -1, 0, 0, -1, 0, 0, -1, 0, 0, -1, 0, 0, // Left Face
		1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0,		// Right Face
		0, -1, 0, 0, -1, 0, 0, -1, 0, 0, -1, 0, 0, -1, 0, 0, -1, 0,	// Bottom Face
		0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0,		// Top Face
	};
	float verts[36 * 3] = {
		// Front Face
		-width / 2, -height / 2, depth / 2, width / 2, -height / 2, depth / 2, -width / 2, height / 2, depth / 2, -width / 2, height / 2,
		depth / 2, width / 2, height / 2, depth / 2, width / 2, -height / 2, depth / 2,
		// Back Face
		-width / 2, -height / 2, -depth / 2, width / 2, -height / 2, -depth / 2, -width / 2, height / 2, -depth / 2, -width / 2, height / 2,
		-depth / 2, width / 2, height / 2, -depth / 2, width / 2, -height / 2, -depth / 2,
		// Left Face
		-width / 2, -height / 2, -depth / 2, -width / 2, -height / 2, depth / 2, -width / 2, height / 2, -depth / 2, -width / 2, height / 2, -depth / 2, -width / 2, height / 2, depth / 2, -width / 2, -height / 2, depth / 2,
		// Right Face
		width / 2, -height / 2, -depth / 2, width / 2, -height / 2, depth / 2, width / 2, height / 2, -depth / 2, width / 2, height / 2, -depth / 2, width / 2, height / 2, depth / 2, width / 2, -height / 2, depth / 2,
		// Bottom Face
		-width / 2, -height / 2, -depth / 2, -width / 2, -height / 2, depth / 2, width / 2, -height / 2, -depth / 2, width / 2, -height / 2, -depth / 2, width / 2, -height / 2, depth / 2, -width / 2, -height / 2, depth / 2,
		// Top Face
		-width / 2, height / 2, -depth / 2, -width / 2, height / 2, depth / 2, width / 2, height / 2, -depth / 2, width / 2, height / 2, -depth / 2, width / 2, height / 2, depth / 2, -width / 2, height / 2, depth / 2,
	};
	
	unsigned int vao[3];
	glGenVertexArrays(1, &vao[0]);
	glBindVertexArray(vao[0]);
	
	glGenBuffers(1, &vao[1]);
	glBindBuffer(GL_ARRAY_BUFFER, vao[1]);
	glBufferData(GL_ARRAY_BUFFER, 36 * 3 * sizeof(float), verts, GL_STREAM_DRAW);
	glVertexAttribPointer(0, 3, GL_FLOAT, NO, 0, NULL);
	glEnableVertexAttribArray(0);
	
	glGenBuffers(1, &vao[2]);
	glBindBuffer(GL_ARRAY_BUFFER, vao[2]);
	glBufferData(GL_ARRAY_BUFFER, 36 * 3 * sizeof(float), normals, GL_STREAM_DRAW);
	glVertexAttribPointer(2, 3, GL_FLOAT, NO, 0, NULL);
	glEnableVertexAttribArray(2);
	
	glDrawArrays(GL_TRIANGLES, 0, 36);
	
	glBindVertexArray(0);
	
	glDeleteBuffers(2, &vao[1]);
	glDeleteVertexArrays(1, &vao[0]);
}

void gluSphere(float radius, unsigned int slices, unsigned int stacks)
{
	float ballVerts[3 * (slices + 1) * (stacks + 1) * 2];
	float normals[3 * (slices + 1) * (stacks + 1) * 2];
	
	for(int i = 0; i <= slices; i++)
	{
		double lat0 = M_PI * (-0.5 + (double) (i - 1) / slices);
		double z0  = sin(lat0);
		double zr0 =  cos(lat0);
		
		double lat1 = M_PI * (-0.5 + (double) i / slices);
		double z1 = sin(lat1);
		double zr1 = cos(lat1);
		
		for(int j = 0; j <= stacks; j++)
		{
			double lng = 2 * M_PI * (double) (j - 1) / stacks;
			double x = cos(lng);
			double y = sin(lng);
			
			ballVerts[(i * slices + j) * 6 + 0] = x * zr0 * radius;
			ballVerts[(i * slices + j) * 6 + 1] = y * zr0 * radius;
			ballVerts[(i * slices + j) * 6 + 2] = z0 * radius;
			normals[(i * slices + j) * 6 + 0] = x * zr0;
			normals[(i * slices + j) * 6 + 1] = y * zr0;
			normals[(i * slices + j) * 6 + 2] = z0;
			
			ballVerts[(i * slices + j) * 6 + 3] = x * zr1 * radius;
			ballVerts[(i * slices + j) * 6 + 4] = y * zr1 * radius;
			ballVerts[(i * slices + j) * 6 + 5] = z1 * radius;
			normals[(i * slices + j) * 6 + 3] = x * zr1;
			normals[(i * slices + j) * 6 + 4] = y * zr1;
			normals[(i * slices + j) * 6 + 5] = z1;
		}
	}
	
	unsigned int vao[3];
	glGenVertexArrays(1, &vao[0]);
	glBindVertexArray(vao[0]);
	
	glGenBuffers(1, &vao[1]);
	glBindBuffer(GL_ARRAY_BUFFER, vao[1]);
	glBufferData(GL_ARRAY_BUFFER, (slices + 1) * (stacks + 1) * 2 * 3 * sizeof(float), ballVerts, GL_STREAM_DRAW);
	glVertexAttribPointer(0, 3, GL_FLOAT, NO, 0, NULL);
	glEnableVertexAttribArray(0);
	
	glGenBuffers(1, &vao[2]);
	glBindBuffer(GL_ARRAY_BUFFER, vao[2]);
	glBufferData(GL_ARRAY_BUFFER, (slices + 1) * (stacks + 1) * 2 * 3 * sizeof(float), normals, GL_STREAM_DRAW);
	glVertexAttribPointer(2, 3, GL_FLOAT, NO, 0, NULL);
	glEnableVertexAttribArray(2);
	
	glDrawArrays(GL_TRIANGLE_STRIP, 0, (slices + 1) * (stacks + 0) * 2);
	
	glBindVertexArray(0);
	
	glDeleteBuffers(2, &vao[1]);
	glDeleteVertexArrays(1, &vao[0]);
	
	glBindBuffer(GL_ARRAY_BUFFER, 0);
}

void gluLine(MDVector3 p1, MDVector3 p2)
{
	float verts[6] = { p1.x, p1.y, p1.z, p2.x, p2.y, p2.z };
	
	unsigned int vao[2];
	glGenVertexArrays(1, &vao[0]);
	glBindVertexArray(vao[0]);
	
	glGenBuffers(1, &vao[1]);
	glBindBuffer(GL_ARRAY_BUFFER, vao[1]);
	glBufferData(GL_ARRAY_BUFFER, 2 * 3 * sizeof(float), verts, GL_STREAM_DRAW);
	glVertexAttribPointer(0, 3, GL_FLOAT, NO, 0, NULL);
	glEnableVertexAttribArray(0);
	
	glDrawArrays(GL_LINES, 0, 2);
	
	glBindVertexArray(0);
	
	glDeleteBuffers(1, &vao[1]);
	glDeleteVertexArrays(1, &vao[0]);
}

MDInstance* mdCube(float x, float y, float z, float width, float height, float depth)
{
	float xpos = x, ypos = y, zpos = z;
	float width2 = width / 2;
	float height2 = height / 2;
	float depth2 = depth / 2;
	MDInstance* obj = [ [ MDInstance alloc ] init ];
	
	MDPoint* p = [ [ MDPoint alloc ] init ];
	[ p setX:xpos - width2 Y:ypos - height2 Z:zpos - depth2 ];
	[ p setNormal:MDVector3Create(0, 0, -1) ];
	[ obj addPoint:p ];
	p = [ [ MDPoint alloc ] init ];
	[ p setX:xpos + width2 Y:ypos - height2 Z:zpos - depth2 ];
	[ p setNormal:MDVector3Create(0, 0, -1) ];
	[ obj addPoint:p ];
	p = [ [ MDPoint alloc ] init ];
	[ p setX:xpos + width2 Y:ypos + height2 Z:zpos - depth2 ];
	[ p setNormal:MDVector3Create(0, 0, -1) ];
	[ obj addPoint:p ];
	p = [ [ MDPoint alloc ] init ];
	[ p setX:xpos - width2 Y:ypos + height2 Z:zpos - depth2 ];
	[ p setNormal:MDVector3Create(0, 0, -1) ];
	[ obj addPoint:p ];
	
	p = [ [ MDPoint alloc ] init ];
	[ p setX:xpos - width2 Y:ypos - height2 Z:zpos + depth2 ];
	[ p setNormal:MDVector3Create(0, 0, 1) ];
	[ obj addPoint:p ];
	p = [ [ MDPoint alloc ] init ];
	[ p setX:xpos + width2 Y:ypos - height2 Z:zpos + depth2 ];
	[ p setNormal:MDVector3Create(0, 0, 1) ];
	[ obj addPoint:p ];
	p = [ [ MDPoint alloc ] init ];
	[ p setX:xpos + width2 Y:ypos + height2 Z:zpos + depth2 ];
	[ p setNormal:MDVector3Create(0, 0, 1) ];
	[ obj addPoint:p ];
	p = [ [ MDPoint alloc ] init ];
	[ p setX:xpos - width2 Y:ypos + height2 Z:zpos + depth2 ];
	[ p setNormal:MDVector3Create(0, 0, 1) ];
	[ obj addPoint:p ];
	
	p = [ [ MDPoint alloc ] init ];
	[ p setX:xpos - width2 Y:ypos + height2 Z:zpos - depth2 ];
	[ p setNormal:MDVector3Create(-1, 0, 0) ];
	[ obj addPoint:p ];
	p = [ [ MDPoint alloc ] init ];
	[ p setX:xpos - width2 Y:ypos + height2 Z:zpos + depth2 ];
	[ p setNormal:MDVector3Create(-1, 0, 0) ];
	[ obj addPoint:p ];
	p = [ [ MDPoint alloc ] init ];
	[ p setX:xpos - width2 Y:ypos - height2 Z:zpos + depth2 ];
	[ p setNormal:MDVector3Create(-1, 0, 0) ];
	[ obj addPoint:p ];
	p = [ [ MDPoint alloc ] init ];
	[ p setX:xpos - width2 Y:ypos - height2 Z:zpos - depth2 ];
	[ p setNormal:MDVector3Create(-1, 0, 0) ];
	[ obj addPoint:p ];
	
	p = [ [ MDPoint alloc ] init ];
	[ p setX:xpos + width2 Y:ypos + height2 Z:zpos - depth2 ];
	[ p setNormal:MDVector3Create(1, 0, 0) ];
	[ obj addPoint:p ];
	p = [ [ MDPoint alloc ] init ];
	[ p setX:xpos + width2 Y:ypos + height2 Z:zpos + depth2 ];
	[ p setNormal:MDVector3Create(1, 0, 0) ];
	[ obj addPoint:p ];
	p = [ [ MDPoint alloc ] init ];
	[ p setX:xpos + width2 Y:ypos - height2 Z:zpos + depth2 ];
	[ p setNormal:MDVector3Create(1, 0, 0) ];
	[ obj addPoint:p ];
	p = [ [ MDPoint alloc ] init ];
	[ p setX:xpos + width2 Y:ypos - height2 Z:zpos - depth2 ];
	[ p setNormal:MDVector3Create(1, 0, 0) ];
	[ obj addPoint:p ];
	
	p = [ [ MDPoint alloc ] init ];
	[ p setX:xpos - width2 Y:ypos + height2 Z:zpos - depth2 ];
	[ p setNormal:MDVector3Create(0, 1, 0) ];
	[ obj addPoint:p ];
	p = [ [ MDPoint alloc ] init ];
	[ p setX:xpos + width2 Y:ypos + height2 Z:zpos - depth2 ];
	[ p setNormal:MDVector3Create(0, 1, 0) ];
	[ obj addPoint:p ];
	p = [ [ MDPoint alloc ] init ];
	[ p setX:xpos + width2 Y:ypos + height2 Z:zpos + depth2 ];
	[ p setNormal:MDVector3Create(0, 1, 0) ];
	[ obj addPoint:p ];
	p = [ [ MDPoint alloc ] init ];
	[ p setX:xpos - width2 Y:ypos + height2 Z:zpos + depth2 ];
	[ p setNormal:MDVector3Create(0, 1, 0) ];
	[ obj addPoint:p ];
	
	p = [ [ MDPoint alloc ] init ];
	[ p setX:xpos - width2 Y:ypos - height2 Z:zpos - depth2 ];
	[ p setNormal:MDVector3Create(0, -1, 0) ];
	[ obj addPoint:p ];
	p = [ [ MDPoint alloc ] init ];
	[ p setX:xpos + width2 Y:ypos - height2 Z:zpos - depth2 ];
	[ p setNormal:MDVector3Create(0, -1, 0) ];
	[ obj addPoint:p ];
	p = [ [ MDPoint alloc ] init ];
	[ p setX:xpos + width2 Y:ypos - height2 Z:zpos + depth2 ];
	[ p setNormal:MDVector3Create(0, -1, 0) ];
	[ obj addPoint:p ];
	p = [ [ MDPoint alloc ] init ];
	[ p setX:xpos - width2 Y:ypos - height2 Z:zpos + depth2 ];
	[ p setNormal:MDVector3Create(0, -1, 0) ];
	[ obj addPoint:p ];
	
	/*obj.objectColors[0].red = 0.7;
	obj.objectColors[0].alpha = 1;
	obj.objectColors[1].blue = 0.7;
	obj.objectColors[1].alpha = 1;
	obj.objectColors[2].red = 0.7;
	obj.objectColors[2].green = 0.7;
	obj.objectColors[2].alpha = 1;*/
	
	return obj;
}

MDInstance* mdCircle(float x, float y, float z, float radiusX, float radiusY, float radiusZ, int slices)
{
	MDInstance* obj = [ [ MDInstance alloc ] init ];
	
	for (float tx = 0; tx < slices; tx++)
	{
		float angleX1 = tx / slices * 2 * M_PI;
		float angleX2 = (tx + 1) / slices * 2 * M_PI;
		float trueX1 = sin(angleX1);
		float trueX2 = sin(angleX2);
		
		for (float ty = 0; ty <= slices; ty++)
		{
			float angleY = ty / slices * 2 * M_PI;
			float trueY1 = cos(angleY) * cos(angleX1);
			float trueY2 = cos(angleY) * cos(angleX2);
			float trueZ1 = sin(angleY) * cos(angleX1);
			float trueZ2 = sin(angleY) * cos(angleX2);
			
			MDPoint* p = [ [ MDPoint alloc ] init ];
			[ p setNormalX:trueX1 ];
			[ p setNormalY:trueY1 ];
			[ p setNormalZ:trueZ1 ];
			[ p setX:(trueX1 * radiusX) + x Y:(trueY1 * radiusY) + y Z:(trueZ1 * radiusZ) + z ];
			[ obj addPoint:p ];
			
			p = [ [ MDPoint alloc ] init ];
			[ p setNormalX:trueX2 ];
			[ p setNormalY:trueY2 ];
			[ p setNormalZ:trueZ2 ];
			[ p setX:(trueX2 * radiusX) + x Y:(trueY2 * radiusY) + y Z:(trueZ2 * radiusZ) + z ];
			[ obj addPoint:p ];
			
		}
	}
	
	/*obj.objectColors[0].red = 0.7;
	obj.objectColors[0].alpha = 1;
	obj.objectColors[1].blue = 0.7;
	obj.objectColors[1].alpha = 1;
	obj.objectColors[2].red = 0.7;
	obj.objectColors[2].green = 0.7;
	obj.objectColors[2].alpha = 1;*/
	
	return obj;
}

void mdCylinder(float baseRadius, float topRadius, float height, float slices, float stacks)
{	
	unsigned int CACHE_SIZE = stacks + 1;
	
    GLfloat sinCache[CACHE_SIZE];
    GLfloat cosCache[CACHE_SIZE];
    GLfloat sinCache2[CACHE_SIZE];
    GLfloat cosCache2[CACHE_SIZE];
    if (slices < 2 || stacks < 1 || baseRadius < 0.0 || topRadius < 0.0 || height < 0.0)
		return;
	
    /* Compute length (needed for normal calculations) */
    float deltaRadius = baseRadius - topRadius;
    float length = sqrt(deltaRadius*deltaRadius + height*height);
    if (length == 0.0)
		return;
	
	float zNormal = deltaRadius / length;
	float xyNormalRatio = height / length;
	
    for (unsigned long i = 0; i < slices; i++)
	{
		float angle = 2 * M_PI * i / slices;
		sinCache2[i] = xyNormalRatio * sin(angle);
		cosCache2[i] = xyNormalRatio * cos(angle);
		sinCache[i] = sin(angle);
		cosCache[i] = cos(angle);
    }
	
    sinCache[(unsigned long)slices] = sinCache[0];
    cosCache[(unsigned long)slices] = cosCache[0];
	sinCache2[(unsigned long)slices] = sinCache2[0];
	cosCache2[(unsigned long)slices] = cosCache2[0];
    	
	unsigned int numPoints = (stacks * slices * 6);
	float normals[numPoints * 3];
	float verts[numPoints * 3];
	
	unsigned int counter = 0;
	for (float j = 0; j < stacks; j++)
	{
		float zLow = j * height / stacks;
		float zHigh = (j + 1) * height / stacks;
		float radiusLow = baseRadius - deltaRadius * ((j + 1) / stacks);
		float radiusHigh = baseRadius - deltaRadius * (j / stacks);
		
		for (unsigned long i = 0; i < slices; i++)
		{
			normals[(counter * 3) + 0] = sinCache2[i], normals[(counter * 3) + 1] = cosCache2[i], normals[(counter * 3) + 2] = zNormal;
			verts[(counter * 3) + 0] = radiusLow * sinCache[i], verts[(counter * 3) + 1] = radiusLow * cosCache[i], verts[(counter * 3) + 2] = zHigh;
			counter++;
			normals[(counter * 3) + 0] = sinCache2[i], normals[(counter * 3) + 1] = cosCache2[i], normals[(counter * 3) + 2] = zNormal;
			verts[(counter * 3) + 0] = radiusHigh * sinCache[i], verts[(counter * 3) + 1] = radiusHigh * cosCache[i], verts[(counter * 3) + 2] = zLow;
			counter++;
			i++;
			normals[(counter * 3) + 0] = sinCache2[i], normals[(counter * 3) + 1] = cosCache2[i], normals[(counter * 3) + 2] = zNormal;
			verts[(counter * 3) + 0] = radiusLow * sinCache[i], verts[(counter * 3) + 1] = radiusLow * cosCache[i], verts[(counter * 3) + 2] = zHigh;
			counter++;
			
			normals[(counter * 3) + 0] = sinCache2[i], normals[(counter * 3) + 1] = cosCache2[i], normals[(counter * 3) + 2] = zNormal;
			verts[(counter * 3) + 0] = radiusHigh * sinCache[i], verts[(counter * 3) + 1] = radiusHigh * cosCache[i], verts[(counter * 3) + 2] = zLow;
			counter++;
			normals[(counter * 3) + 0] = sinCache2[i], normals[(counter * 3) + 1] = cosCache2[i], normals[(counter * 3) + 2] = zNormal;
			verts[(counter * 3) + 0] = radiusLow * sinCache[i], verts[(counter * 3) + 1] = radiusLow * cosCache[i], verts[(counter * 3) + 2] = zHigh;
			counter++;
			i--;
			normals[(counter * 3) + 0] = sinCache2[i], normals[(counter * 3) + 1] = cosCache2[i], normals[(counter * 3) + 2] = zNormal;
			verts[(counter * 3) + 0] = radiusHigh * sinCache[i], verts[(counter * 3) + 1] = radiusHigh * cosCache[i], verts[(counter * 3) + 2] = zLow;
			counter++;
		}
	}
	
	unsigned int vao[3];
	glGenVertexArrays(1, &vao[0]);
	glBindVertexArray(vao[0]);
	
	glGenBuffers(1, &vao[1]);
	glGenBuffers(1, &vao[1]);
	glBindBuffer(GL_ARRAY_BUFFER, vao[1]);
	glBufferData(GL_ARRAY_BUFFER, numPoints * 3 * sizeof(float), verts, GL_STREAM_DRAW);
	glVertexAttribPointer(0, 3, GL_FLOAT, NO, 0, NULL);
	glEnableVertexAttribArray(0);
	
	glGenBuffers(1, &vao[2]);
	glGenBuffers(1, &vao[2]);
	glBindBuffer(GL_ARRAY_BUFFER, vao[2]);
	glBufferData(GL_ARRAY_BUFFER, numPoints * 3 * sizeof(float), normals, GL_STREAM_DRAW);
	glVertexAttribPointer(2, 3, GL_FLOAT, NO, 0, NULL);
	glEnableVertexAttribArray(2);
	
	glDrawArrays(GL_TRIANGLES, 0, numPoints);
	
	glBindVertexArray(0);
	
	glDeleteBuffers(2, &vao[1]);
	glDeleteVertexArrays(1, &vao[0]);
}

#define SEED	255

// Draw the current tool for the object
void DrawObjectTool(MDObject* obj, int object, float currentZ, unsigned int name, MDObject* parentObj, MDMatrix projection, MDMatrix modelView, unsigned int* locations)
{
	if (object == (int)MD_OBJECT_NO)
		return;
	
	// Temp
	currentZ = -20;
	
	// Save the matrix
	//glPushMatrix();
	
	// Calculate the bounding box
	/*float left = 100000, right = -10000, top = 10000, bot = -10000, front = -10000, back = 10000;		// values
	for (int y = 0; y < [ obj numberOfPoints ]; y++)
	{
		MDPoint* point = [ obj pointAtIndex:y ];
		MDVector3 p = MDVector3Create(point.x, point.y, point.z);
		p.x *= fabs(obj.scaleX);
		p.y *= fabs(obj.scaleY);
		p.z *= fabs(obj.scaleZ);
		//p = Rotate(p, midpoint, obj.rotateX, obj.rotateY, obj.rotateZ);
		p = RotateAxis(p, obj.rotateAxis, obj.rotateAngle);
		if (p.x < left)
			left = p.x;
		if (p.x > right)
			right = p.x;
		if (p.y < top)
			top = p.y;
		if (p.y > bot)
			bot = p.y;
		if (p.z > front)
			front = p.z;
		if (p.z < back)
			back = p.z;
	}
	MDRect rect = MakeRect(left, bot, front, right - left, top - bot, back - front);
	rect.x += obj.translateX;
	rect.y += obj.translateY;
	rect.z += obj.translateZ;*/
	MDRect rect = BoundingBoxRotate(obj);
	
	float colors[12];
	if (name != 0)
	{
		for (int z = 1; z <= 3; z++)
		{
			colors[(z - 1) * 4] = ((name + z) % SEED) / (float)SEED;
			colors[(z - 1) * 4 + 1] = (((name + z)/ SEED) % SEED) / (float)SEED;
			colors[(z - 1) * 4 + 2] = (((name + z) / SEED / SEED) % SEED) / (float)SEED;
			colors[(z - 1) * 4 + 3] = 1;
		}
	}
	
	MDMatrix rotate = MDMatrixIdentity();
	switch (object)
	{
		case (int)MD_OBJECT_MOVE:
		{
			float z = (rect.z + (rect.depth / 2));
			
			MDMatrixTranslate(&modelView, rect.x + (rect.width / 2), rect.y, 0);
			// X
			MDMatrixTranslate(&modelView, (rect.width / 2), (rect.height / 2), z);
			//if ((currentMode == MD_FACE_MODE || currentMode == MD_VERTEX_MODE) && [ [ obj faceAtIndex:0 ] realMidPoint ].x < [ parentObj midPoint ].x)
			//	glRotated(180, 0, 1, 0);
			if (name != 0)
				glVertexAttrib4f(1, colors[0], colors[1], colors[2], colors[3]);
			else
				glVertexAttrib4f(1, parentObj.objectColors[0].x, parentObj.objectColors[0].y, parentObj.objectColors[0].z, parentObj.objectColors[0].w);
			MDMatrixRotate(&modelView, 0, 1, 0, 90);
			MDMatrixRotate(&rotate, 0, 1, 0, 90);
			glUniformMatrix4fv(locations[MD_PROGRAM_NORMALROTATION], 1, NO, rotate.data);
			glUniformMatrix4fv(locations[MD_PROGRAM_MODELVIEWPROJECTION], 1, NO, (projection * modelView).data);
			mdCylinder(0.261474, 0.261474, 1.74316, 32, 32);
			MDMatrixRotate(&rotate, 0, 1, 0, -90);
			MDMatrixRotate(&modelView, 0, 1, 0, -90);
			MDMatrixTranslate(&modelView, 1.74316, 0, 0);
			MDMatrixRotate(&modelView, 0, 1, 0, 90);
			MDMatrixRotate(&rotate, 0, 1, 0, 90);
			glUniformMatrix4fv(locations[MD_PROGRAM_NORMALROTATION], 1, NO, rotate.data);
			glUniformMatrix4fv(locations[MD_PROGRAM_MODELVIEWPROJECTION], 1, NO, (projection * modelView).data);
			mdCylinder(0.522947, 0, 0.697263, 32, 32);
			MDMatrixRotate(&modelView, 0, 1, 0, -90);
			MDMatrixRotate(&rotate, 0, 1, 0, -90);
			MDMatrixTranslate(&modelView, -rect.width / 2 - 1.74316, -rect.height / 2, 0);
			// Y
			//if ((currentMode == MD_FACE_MODE || currentMode == MD_VERTEX_MODE) && [ [ obj faceAtIndex:0 ] realMidPoint ].y < [ parentObj midPoint ].y)
			//	glRotated(180, 0, 0, 1);
			if (name != 0)
				glVertexAttrib4f(1, colors[4], colors[5], colors[6], colors[7]);
			else
				glVertexAttrib4f(1, parentObj.objectColors[1].x, parentObj.objectColors[1].y, parentObj.objectColors[1].z, parentObj.objectColors[1].w);
			MDMatrixRotate(&modelView, 1, 0, 0, -90);
			MDMatrixRotate(&rotate, 1, 0, 0, -90);
			glUniformMatrix4fv(locations[MD_PROGRAM_NORMALROTATION], 1, NO, rotate.data);
			glUniformMatrix4fv(locations[MD_PROGRAM_MODELVIEWPROJECTION], 1, NO, (projection * modelView).data);
			mdCylinder(0.261474, 0.261474, 1.74316, 32, 32);
			MDMatrixRotate(&modelView, 1, 0, 0, 90);
			MDMatrixRotate(&rotate, 1, 0, 0, 90);
			MDMatrixTranslate(&modelView, 0, 1.74316, 0);
			MDMatrixRotate(&modelView, 1, 0, 0, -90);
			MDMatrixRotate(&rotate, 1, 0, 0, -90);
			glUniformMatrix4fv(locations[MD_PROGRAM_NORMALROTATION], 1, NO, rotate.data);
			glUniformMatrix4fv(locations[MD_PROGRAM_MODELVIEWPROJECTION], 1, NO, (projection * modelView).data);
			mdCylinder(0.522947, 0, 0.697263, 32, 32);
			MDMatrixRotate(&modelView, 1, 0, 0, 90);
			MDMatrixRotate(&rotate, 1, 0, 0, 90);
			//if ((currentMode == MD_FACE_MODE || currentMode == MD_VERTEX_MODE) && [ [ obj faceAtIndex:0 ] realMidPoint ].x < [ parentObj midPoint ].x)
			//	glRotated(-180, 0, 1, 0);
			MDMatrixTranslate(&modelView, 0, -1.74316 + rect.height / 2, rect.depth / 2);
			// Z
			//if ((currentMode == MD_FACE_MODE || currentMode == MD_VERTEX_MODE) && [ [ obj faceAtIndex:0 ] realMidPoint ].z > [ parentObj midPoint ].z)
			//	glRotated(180, 1, 0, 0);
			z += rect.depth / 2;
			if (name != 0)
				glVertexAttrib4f(1, colors[8], colors[9], colors[10], colors[11]);
			else
				glVertexAttrib4f(1, parentObj.objectColors[2].x, parentObj.objectColors[2].y, parentObj.objectColors[2].z, parentObj.objectColors[2].w);
			MDMatrixRotate(&modelView, 0, 1, 0, 180);
			MDMatrixRotate(&rotate, 0, 1, 0, 180);
			glUniformMatrix4fv(locations[MD_PROGRAM_NORMALROTATION], 1, NO, rotate.data);
			glUniformMatrix4fv(locations[MD_PROGRAM_MODELVIEWPROJECTION], 1, NO, (projection * modelView).data);
			mdCylinder(0.261474, 0.261474, 1.74316, 32, 32);
			MDMatrixRotate(&modelView, 0, 1, 0, -180);
			MDMatrixRotate(&rotate, 0, 1, 0, -180);
			MDMatrixTranslate(&modelView, 0, 0, -1.74316);
			MDMatrixRotate(&modelView, 0, 1, 0, 180);
			MDMatrixRotate(&rotate, 0, 1, 0, 180);
			glUniformMatrix4fv(locations[MD_PROGRAM_NORMALROTATION], 1, NO, rotate.data);
			glUniformMatrix4fv(locations[MD_PROGRAM_MODELVIEWPROJECTION], 1, NO, (projection * modelView).data);
			mdCylinder(0.522947, 0, 0.697263, 32, 32);
			MDMatrixRotate(&modelView, 0, 1, 0, -180);
			MDMatrixRotate(&rotate, 0, 1, 0, -180);
			
			break;
		}
		case (int)MD_OBJECT_SIZE:
		{
			float z = rect.z + (rect.depth / 2);
			
			MDMatrixTranslate(&modelView, rect.x + (rect.width / 2), rect.y, 0);
			// X
			MDMatrixTranslate(&modelView, rect.width / 2, (rect.height / 2), z);
			//if (currentMode == MD_FACE_MODE && [ [ obj faceAtIndex:0 ] realMidPoint ].x < [ parentObj midPoint ].x)
			//	glRotated(180, 0, 1, 0);
			if (name != 0)
				glVertexAttrib4f(1, colors[0], colors[1], colors[2], colors[3]);
			else
				glVertexAttrib4f(1, obj.objectColors[0].x, obj.objectColors[0].y, obj.objectColors[0].z, obj.objectColors[0].w);
			MDMatrixRotate(&modelView, 0, 1, 0, 90);
			MDMatrixRotate(&rotate, 0, 1, 0, 90);
			glUniformMatrix4fv(locations[MD_PROGRAM_NORMALROTATION], 1, NO, rotate.data);
			glUniformMatrix4fv(locations[MD_PROGRAM_MODELVIEWPROJECTION], 1, NO, (projection * modelView).data);
			mdCylinder(0.261474, 0.261474, 1.74316, 32, 32);
			MDMatrixRotate(&modelView, 0, 1, 0, -90);
			MDMatrixRotate(&rotate, 0, 1, 0, -90);
			MDMatrixTranslate(&modelView, 1.74316, 0, 0);
			glUniformMatrix4fv(locations[MD_PROGRAM_NORMALROTATION], 1, NO, rotate.data);
			glUniformMatrix4fv(locations[MD_PROGRAM_MODELVIEWPROJECTION], 1, NO, (projection * modelView).data);
			gluCube(0.697263, 0.697263, 0.697263);
			MDMatrixTranslate(&modelView, -rect.width / 2 - 1.74316, -rect.height / 2, 0);
			// Y
			//if (currentMode == MD_FACE_MODE && [ [ obj faceAtIndex:0 ] realMidPoint ].y < [ parentObj midPoint ].y)
			//	glRotated(180, 0, 0, 1);
			if (name != 0)
				glVertexAttrib4f(1, colors[4], colors[5], colors[6], colors[7]);
			else
				glVertexAttrib4f(1, obj.objectColors[1].x, obj.objectColors[1].y, obj.objectColors[1].z, obj.objectColors[1].w);
			MDMatrixRotate(&modelView, 1, 0, 0, -90);
			MDMatrixRotate(&rotate, 1, 0, 0, -90);
			glUniformMatrix4fv(locations[MD_PROGRAM_NORMALROTATION], 1, NO, rotate.data);
			glUniformMatrix4fv(locations[MD_PROGRAM_MODELVIEWPROJECTION], 1, NO, (projection * modelView).data);
			mdCylinder(0.261474, 0.261474, 1.74316, 32, 32);
			MDMatrixRotate(&modelView, 1, 0, 0, 90);
			MDMatrixRotate(&rotate, 1, 0, 0, 90);
			MDMatrixTranslate(&modelView, 0, 1.74316, 0);
			glUniformMatrix4fv(locations[MD_PROGRAM_NORMALROTATION], 1, NO, rotate.data);
			glUniformMatrix4fv(locations[MD_PROGRAM_MODELVIEWPROJECTION], 1, NO, (projection * modelView).data);
			gluCube(0.697263, 0.697263, 0.697263);
			//if (currentMode == MD_FACE_MODE && [ [ obj faceAtIndex:0 ] realMidPoint ].x < [ parentObj midPoint ].x)
			//	glRotated(-180, 0, 1, 0);
			MDMatrixTranslate(&modelView, 0, -1.74316 + rect.height / 2, rect.depth / 2);
			// Z
			//if (currentMode == MD_FACE_MODE && [ [ obj faceAtIndex:0 ] realMidPoint ].z > [ parentObj midPoint ].z)
			//	glRotated(180, 1, 0, 0);
			z += rect.depth / 2;
			if (name != 0)
				glVertexAttrib4f(1, colors[8], colors[9], colors[10], colors[11]);
			else
				glVertexAttrib4f(1, obj.objectColors[2].x, obj.objectColors[2].y, obj.objectColors[2].z, obj.objectColors[2].w);
			MDMatrixRotate(&modelView, 0, 1, 0, 180);
			MDMatrixRotate(&rotate, 0, 1, 0, 180);
			glUniformMatrix4fv(locations[MD_PROGRAM_NORMALROTATION], 1, NO, rotate.data);
			glUniformMatrix4fv(locations[MD_PROGRAM_MODELVIEWPROJECTION], 1, NO, (projection * modelView).data);
			mdCylinder(0.261474, 0.261474, 1.74316, 32, 32);
			MDMatrixRotate(&modelView, 0, 1, 0, -180);
			MDMatrixRotate(&rotate, 0, 1, 0, -180);
			MDMatrixTranslate(&modelView, 0, 0, -1.74316);
			glUniformMatrix4fv(locations[MD_PROGRAM_NORMALROTATION], 1, NO, rotate.data);
			glUniformMatrix4fv(locations[MD_PROGRAM_MODELVIEWPROJECTION], 1, NO, (projection * modelView).data);
			gluCube(0.697263, 0.697263, 0.697263);
			
			break;
		}
		case (int)MD_OBJECT_ROTATE:
		{
			// Todo: rest + emit light from mid point
			float z = rect.z + (rect.depth / 2);
			
			MDMatrixTranslate(&modelView, obj.translateX, obj.translateY, obj.translateZ);
			MDMatrixRotate(&modelView, obj.rotateAxis, obj.rotateAngle);
			MDMatrixRotate(&rotate, obj.rotateAxis, obj.rotateAngle);
			MDMatrixTranslate(&modelView, -obj.translateX, -obj.translateY, -obj.translateZ);
			
			float value = fabs(rect.width);
			if (value < fabs(rect.height))
				value = fabs(rect.height);
			if (value < fabs(rect.depth))
				value = fabs(rect.depth);
			
			MDMatrixTranslate(&modelView, rect.x + (rect.width / 2), rect.y + (rect.height / 2), -TW(5, -(currentZ + z)) + rect.z + (rect.depth / 2));
			// X
			if (name != 0)
				glVertexAttrib4f(1, colors[0], colors[1], colors[2], colors[3]);
			else
				glVertexAttrib4f(1, obj.objectColors[0].x, obj.objectColors[0].y, obj.objectColors[0].z, obj.objectColors[0].w);
			glUniformMatrix4fv(locations[MD_PROGRAM_NORMALROTATION], 1, NO, rotate.data);
			glUniformMatrix4fv(locations[MD_PROGRAM_MODELVIEWPROJECTION], 1, NO, (projection * modelView).data);
			mdCylinder(value + 0.1, value + 0.1, TH(10, -(currentZ + z)), 32, 32);
			// Y
			MDMatrixRotate(&modelView, 1, 0, 0, 90);
			MDMatrixRotate(&rotate, 1, 0, 0, 90);
			if (name != 0)
				glVertexAttrib4f(1, colors[4], colors[5], colors[6], colors[7]);
			else
				glVertexAttrib4f(1, obj.objectColors[1].x, obj.objectColors[1].y, obj.objectColors[1].z, obj.objectColors[1].w);
			glUniformMatrix4fv(locations[MD_PROGRAM_NORMALROTATION], 1, NO, rotate.data);
			glUniformMatrix4fv(locations[MD_PROGRAM_MODELVIEWPROJECTION], 1, NO, (projection * modelView).data);
			mdCylinder(value - 0.1, value - 0.1, TH(10, -(currentZ + z)), 32, 32);
			MDMatrixRotate(&modelView, 1, 0, 0, -90);
			MDMatrixRotate(&rotate, 1, 0, 0, -90);
			// Z
			MDMatrixRotate(&modelView, 0, 1, 0, 90);
			MDMatrixRotate(&rotate, 0, 1, 0, 90);
			if (name != 0)
				glVertexAttrib4f(1, colors[8], colors[9], colors[10], colors[11]);
			else
				glVertexAttrib4f(1, obj.objectColors[2].x, obj.objectColors[2].y, obj.objectColors[2].z, obj.objectColors[2].w);
			glUniformMatrix4fv(locations[MD_PROGRAM_NORMALROTATION], 1, NO, rotate.data);
			glUniformMatrix4fv(locations[MD_PROGRAM_MODELVIEWPROJECTION], 1, NO, (projection * modelView).data);
			mdCylinder(value, value, TH(10, -(currentZ + z)), 32, 32);
			
			break;
		}
	}
	
	/*glDisable(GL_LIGHTING);
	glDisable(GL_LIGHT0);
	glDisable(GL_COLOR_MATERIAL);*/
	
	// Retrieve the matrix
	//glPopMatrix();
}

void MouseDragged(float deltaX, float deltaY, int name, int object, id obj, float zpos, float xrot, float yrot, NSPoint mouse, int mode)
{
	double number = 0;
	int which = (name % 4);
	switch (which)
	{
		case 0:
			return;
		case 1:
		{
			float x = TW(deltaX, zpos) * cos(yrot / 180 * 3.1415926535);
			float y = TH(deltaY, zpos) * sin(yrot / 180 * 3.1415926535);
			if (object == (int)MD_OBJECT_MOVE || object == (int)MD_OBJECT_SIZE)
				number = x + y;
			else if (object == (int)MD_OBJECT_ROTATE)
			{
				MDVector3 mid = [ obj realMidPoint ];
				y = cos(yrot / 180 * 3.1415926535) * mid.x;
				y += sin(yrot / 180 * 3.1415926535) * mid.z;
				float ux = UX(y, zpos);
				float uy = -UY(mid.y, zpos);
				number = atan2f(mouse.x - ux, mouse.y - uy) * 180 / 3.1415926535 + diff;
			}
			
			// X
			if (object == (int)MD_OBJECT_MOVE)
				[ obj addTranslateX:number ];
			else if (object == (int)MD_OBJECT_SIZE)
				[ obj addScaleX:number ];
			else if (object == (int)MD_OBJECT_ROTATE)
				[ obj setRotateX:number ];
			break;
		}
		case 2:
		{
			float y = TH(deltaY, zpos);
			if (object == (int)MD_OBJECT_MOVE || object == (int)MD_OBJECT_SIZE)
				number = y;
			else if (object == (int)MD_OBJECT_ROTATE)
			{
				MDVector3 mid = [ obj realMidPoint ];
				y = cos(yrot / 180 * 3.1415926535) * mid.y;
				y += sin(yrot / 180 * 3.1415926535) * mid.z;
				float ux = UX(mid.x, zpos);
				float uy = -UY(y, zpos);
				number = atan2f(mouse.x - ux, mouse.y - uy) * 180 / 3.1415926535 + diff;
			}
			
			// Y
			if (object == (int)MD_OBJECT_MOVE)
				[ obj addTranslateY:number ];
			else if (object == (int)MD_OBJECT_SIZE)
				[ obj addScaleY:number ];
			else if (object == (int)MD_OBJECT_ROTATE)
				[ obj setRotateY:number ];
			break;
		}
		case 3:
		{
			float x = TW(deltaX, zpos) * sin(yrot / 180 * 3.1415926535);
			float y = TH(deltaY, zpos) * -cos(yrot / 180 * 3.1415926535);
			if (object == (int)MD_OBJECT_MOVE)
				number = y + x;
			else if (object == (int)MD_OBJECT_SIZE)
				number = -y - x;
			else if (object == (int)MD_OBJECT_ROTATE)
			{
				MDVector3 mid = [ obj realMidPoint ];
				y = cos(yrot / 180 * 3.1415926535) * mid.x;
				y += sin(yrot / 180 * 3.1415926535) * mid.z;
				float ux = UX(y, zpos);
				float uy = -UY(mid.y, zpos);
				number = -atan2f(mouse.x - ux, mouse.y - uy) * 180 / 3.1415926535 + diff;
			}
			
			// Z
			if (object == (int)MD_OBJECT_MOVE)
				[ obj addTranslateZ:number ];
			else if (object == (int)MD_OBJECT_SIZE)
				[ obj addScaleZ:number ];
			else if (object == (int)MD_OBJECT_ROTATE)
				[ obj setRotateZ:number ];
			break;
		}
	}

	// Update VBO
	if (mode == MD_FACE_MODE || mode == MD_VERTEX_MODE)
		[ [ obj instance ] setupVBO ];
}

void MouseDown(int name, id obj, float xrot, float yrot, float zrot, float zpos, NSPoint mouse, int tool, int mode, MDObject* realObj)
{
	// Todo smooth transition
	switch (name % 4)
	{
		case 0:
			break;
		case 1:
		{
			realObj.objectColors[0].x = 1;
			if (mode == (int)MD_OBJECT_MODE && tool == (int)MD_OBJECT_ROTATE)
			{
				MDVector3 mid = [  obj realMidPoint ];
				float y = cos(yrot / 180 * 3.1415926535) * mid.x;
				y += sin(yrot / 180 * 3.1415926535) * mid.z;
				float ux = UX(y, zpos);
				float uy = -UY(mid.y, zpos);
				diff = [ (MDObject*)obj rotateAxis ].x - atan2f(mouse.x - ux, mouse.y - uy) * 180 / 3.1415926535;
			}
			break;
		}
		case 2:
		{
			realObj.objectColors[1].z = 1;
			if (mode == (int)MD_OBJECT_MODE && tool == (int)MD_OBJECT_ROTATE)
			{
				MDVector3 mid = [ obj realMidPoint ];
				float y = cos(yrot / 180 * 3.1415926535) * mid.y;
				y += sin(yrot / 180 * 3.1415926535) * mid.z;
				float ux = UX(mid.x, zpos);
				float uy = -UY(y, zpos);
				diff = [ (MDObject*)obj rotateAxis ].y - atan2f(mouse.x - ux, mouse.y - uy) * 180 / 3.1415926535;
			}
			break;
		}
		case 3:
		{
			realObj.objectColors[2].x = 1;
			realObj.objectColors[2].y = 1;
			if (mode == (int)MD_OBJECT_MODE && tool == (int)MD_OBJECT_ROTATE)
			{
				MDVector3 mid = [ obj realMidPoint ];
				float y = cos(yrot / 180 * 3.1415926535) * mid.x;
				y += sin(yrot / 180 * 3.1415926535) * mid.z;
				float ux = UX(y, zpos);
				float uy = -UY(mid.y, zpos);
				diff = [ (MDObject*)obj rotateAxis ].z + atan2f(mouse.x - ux, mouse.y - uy) * 180 / 3.1415926535;
			}
			break;
		}
	}
}

void MouseUp(MDObject* obj)
{
	obj.objectColors[0].x = 0.7;
	obj.objectColors[1].z = 0.7;
	obj.objectColors[2].x = 0.7;
	obj.objectColors[2].y = 0.7;
	diff = 0;
}

float Volume(MDObject* obj)
{
	// For now, just do w * h * d
	MDRect rect = BoundingBoxRotate(obj);
	return std::abs(rect.width * rect.height * rect.depth);
}

