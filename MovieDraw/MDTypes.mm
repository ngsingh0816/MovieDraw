//
//  MDTypes.m
//  MovieDraw
//
//  Created by Neil Singh on 8/3/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MDTypes.h"
#define GL_DO_NOT_WARN_IF_MULTI_GL_VERSION_HEADERS_INCLUDED	// Gets rid of a warning
#import <OpenGL/gl3.h>
#import <OpenGL/gl3ext.h>
#import "MDObjectTools.h"
#include <vector>

#define MD_PROGRAM0_TRANSLATE				0
#define MD_PROGRAM0_SCALE					1
#define MD_PROGRAM0_ROTATE					2
#define MD_PROGRAM0_MIDPOINT				3
#define MD_PROGRAM0_OBJECTCOLOR				4
#define MD_PROGRAM0_OBJMATRIX				5
#define MD_PROGRAM0_EYEPOS					6
#define MD_PROGRAM0_MODELVIEWPROJECTION		7
#define MD_PROGRAM0_FRONTMATERIALSPECULAR	8
#define MD_PROGRAM0_FORNTMATERIALSHININESS	9

// Hardcoded for now

#define MD_PROGRAM0_TEXTURE_SIZE				0
#define MD_PROGRAM0_TEXTURE_CHILDREN			1
#define MD_PROGRAM0_TEXTURE_ENABLED				2
#define MD_PROGRAM0_TEXTURE_TEXTURE				3

// Diffuse
#define MD_PROGRAM0_DIFFUSETEXTURES0_SIZE		10
#define MD_PROGRAM0_DIFFUSETEXTURES0_CHILDREN	11
#define MD_PROGRAM0_DIFFUSETEXTURES0_ENABLED	12
#define MD_PROGRAM0_DIFFUSETEXTURES0_TEXTURE	13
// Bump
#define MD_PROGRAM0_BUMPTEXTURES0_SIZE			14
#define MD_PROGRAM0_BUMPTEXTURES0_CHILDREN		15
#define MD_PROGRAM0_BUMPTEXTURES0_ENABLED		16
#define MD_PROGRAM0_BUMPTEXTURES0_TEXTURE		17
// Map
#define MD_PROGRAM0_MAPTEXTURES0_SIZE			18
#define MD_PROGRAM0_MAPTEXTURES0_CHILDREN		19
#define MD_PROGRAM0_MAPTEXTURES0_ENABLED		20
#define MD_PROGRAM0_MAPTEXTURES0_TEXTURE		21
// Diffuse Map 1
#define MD_PROGRAM0_DIFFUSEMAPTEXTURES0_SIZE		22
#define MD_PROGRAM0_DIFFUSEMAPTEXTURES0_CHILDREN	23
#define MD_PROGRAM0_DIFFUSEMAPTEXTURES0_ENABLED		24
#define MD_PROGRAM0_DIFFUSEMAPTEXTURES0_TEXTURE		25
// Diffuse Map 2
#define MD_PROGRAM0_DIFFUSEMAPTEXTURES1_SIZE		26
#define MD_PROGRAM0_DIFFUSEMAPTEXTURES1_CHILDREN	27
#define MD_PROGRAM0_DIFFUSEMAPTEXTURES1_ENABLED		28
#define MD_PROGRAM0_DIFFUSEMAPTEXTURES1_TEXTURE		29
// Diffuse Map 3
#define MD_PROGRAM0_DIFFUSEMAPTEXTURES2_SIZE		30
#define MD_PROGRAM0_DIFFUSEMAPTEXTURES2_CHILDREN	31
#define MD_PROGRAM0_DIFFUSEMAPTEXTURES2_ENABLED		32
#define MD_PROGRAM0_DIFFUSEMAPTEXTURES2_TEXTURE		33

// Particle locations
#define MD_PROGRAM2_MV			0
#define MD_PROGRAM2_P			1
#define MD_PROGRAM2_POINTSIZE	2
#define MD_PROGRAM2_SCREENWIDTH	3

static inline unsigned int MDUniformTextureLocation(unsigned int index, unsigned int type)
{
	return 10 + (index * 4) + (type * 4);	// Need to change to depend on how many indices there are for each texture
}

@implementation MDPoint

@synthesize x;
@synthesize y;
@synthesize z;
/*@synthesize red;
@synthesize green;
@synthesize blue;
@synthesize alpha;*/
@synthesize normalX;
@synthesize normalY;
@synthesize normalZ;
@synthesize textureCoordX;
@synthesize textureCoordY;
@synthesize boneMatrix;
@synthesize hasBone;

- (instancetype) init
{
	if ((self = [ super init ]))
	{
		x = y = z = /*red = green = blue =*/ 0;
		//alpha = 1;
		boneMatrix = MDMatrixIdentity();
	}
	return self;
}

- (instancetype) initWithPoint: (MDPoint*)point
{
	if ((self = [ super init ]))
	{
		x = point.x;
		y = point.y;
		z = point.z;
		/*red = point.red;
		green = point.green;
		blue = point.blue;
		alpha = point.alpha;*/
		normalX = point.normalX;
		normalY = point.normalY;
		normalZ = point.normalZ;
		textureCoordX = point.textureCoordX;
		textureCoordY = point.textureCoordY;
		boneMatrix = [ point boneMatrix ];
		mesh = [ point mesh ];
	}
	return self;
}

- (MDVector3) realMidPoint
{
	return MDVector3Create(x, y, z);
}

- (void) setX:(float)xVal Y:(float)yVal Z:(float)zVal
{
	x = xVal;
	y = yVal;
	z = zVal;
}

- (void) setPosition:(MDVector3)p;
{
	x = p.x;
	y = p.y;
	z = p.z;
}

- (void) setNormal:(MDVector3)p
{
	normalX = p.x;
	normalY = p.y;
	normalZ = p.z;
}

- (MDVector3) normal
{
	return MDVector3Create(normalX, normalY, normalZ);
}

- (MDVector3) position
{
	return MDVector3Create(x, y, z);
}

- (void) addTranslateX:(float)value
{
	[ self setTranslateX:x + value ];
}

- (void) addTranslateY:(float)value
{
	[ self setTranslateY:y + value ];
}

- (void) addTranslateZ:(float)value
{
	[ self setTranslateZ:z + value ];
}

- (void) setTranslateX:(float)value
{
	MDInstance* instance = [ mesh instance ];
	MDPoint* p1 = self;
	unsigned long numPoints = [ instance numberOfPoints ];
	for (unsigned long t = 0; t < numPoints; t++)
	{
		MDPoint* p = [ instance pointAtIndex:t ];
		if (p == self)
			continue;
		if (MDFloatCompare(p1.x, p.x) && MDFloatCompare(p1.y, p.y) && MDFloatCompare(p1.z, p.z))
			p.x = value;
	}
	
	x = value;
}

- (void) setTranslateY:(float)value
{
	MDInstance* instance = [ mesh instance ];
	MDPoint* p1 = self;
	unsigned long numPoints = [ instance numberOfPoints ];
	for (unsigned long t = 0; t < numPoints; t++)
	{
		MDPoint* p = [ instance pointAtIndex:t ];
		if (p == self)
			continue;
		if (MDFloatCompare(p1.x, p.x) && MDFloatCompare(p1.y, p.y) && MDFloatCompare(p1.z, p.z))
			p.y = value;
	}
	
	y = value;
}

- (void) setTranslateZ:(float)value
{
	MDInstance* instance = [ mesh instance ];
	MDPoint* p1 = self;
	unsigned long numPoints = [ instance numberOfPoints ];
	for (unsigned long t = 0; t < numPoints; t++)
	{
		MDPoint* p = [ instance pointAtIndex:t ];
		if (p == self)
			continue;
		if (MDFloatCompare(p1.x, p.x) && MDFloatCompare(p1.y, p.y) && MDFloatCompare(p1.z, p.z))
			p.z = value;
	}
	
	z = value;
}

- (void) addX:(float)value
{
	x += value;
}

- (void) addY:(float)value
{
	y += value;
}

- (void) addZ:(float)value
{
	z += value;
}


- (void) addScaleX:(float)value
{
}

- (void) addScaleY:(float)value
{
}

- (void) addScaleZ:(float)value
{
}

- (void) setRotateX:(float)value
{
}

- (void) setRotateY:(float)value
{
}

- (void) setRotateZ:(float)value
{
}

- (MDInstance*) instance
{
	return [ mesh instance ];
}

- (void) setMesh:(MDMesh*) m
{
	mesh = m;
}

- (MDMesh*) mesh
{
	return mesh;
}

/*- (MDColor) midColor
{
	MDColor color;
	memset(&color, 0, sizeof(color));
	color.red = red;
	color.green = green;
	color.blue = blue;
	color.alpha = alpha;
	return color;
}

- (void) setRed:(float)r green:(float)g blue:(float)b alpha:(float)a
{
	red = r;
	green = g;
	blue = b;
	alpha = a;
}

- (void) setMidColor:(MDColor)color
{
	[ self setRed:color.red green:color.green blue:color.blue alpha:color.alpha ];
}

- (void) addMidColor:(MDColor)color
{
	red += color.red;
	green += color.green;
	blue += color.blue;
	alpha += color.alpha;
}*/

@end

@implementation MDObject

@synthesize translateX;
@synthesize translateY;
@synthesize translateZ;
@synthesize scaleX;
@synthesize scaleY;
@synthesize scaleZ;
/*@synthesize rotateX;
@synthesize rotateY;
@synthesize rotateZ;
@synthesize rotatePoint;*/
@synthesize rotateAxis;
@synthesize rotateAngle;
@synthesize colorMultiplier;
@synthesize shouldDraw;
@synthesize shouldView;
@synthesize objectColors;
@synthesize mass;
@synthesize restitution;
@synthesize physicsType;
@synthesize flags;
@synthesize friction;
@synthesize rollingFriction;
@synthesize type;
@synthesize isStatic;

@synthesize currentAnimationTime;
@synthesize currentAnimationSpeed;
@synthesize animationFlags;

- (instancetype) init
{
	if ((self = [ super init ]))
	{
		scaleX = scaleY = scaleZ = 1;
		updateMatrix = TRUE;
		objectColors = (MDVector4*)malloc(sizeof(MDVector4) * 3);
		memset(objectColors, 0, sizeof(MDVector4) * 3);
		//faces = [ [ NSMutableArray alloc ] init ];
		objectColors[0].x = objectColors[1].z = objectColors[2].x = objectColors[2].y = 0.7;
		objectColors[0].w = objectColors[1].w = objectColors[2].w = 1;
		//rotatePoint = MDVector3Create(0, 0, 0);
		rotateAxis = MDVector3Create(0, 0, 0);
		properties = [ [ NSMutableDictionary alloc ] init ];
		colorMultiplier = MDVector4Create(1, 1, 1, 1);
		shouldDraw = TRUE;
		shouldView = TRUE;
		isStatic = FALSE;
		currentAnimation = -1;
		
		type = 0;
		data = [ [ NSMutableArray alloc ] init ];
		flags = (1 << 0) | (1 << 1);	// affect position and rotation
	}
	return self;
}

- (instancetype) initWithObject: (MDObject*)obj
{
	if ((self = [ super init ]))
	{
		if (!obj)
			return self;
		
		translateX = obj.translateX;
		translateY = obj.translateY;
		translateZ = obj.translateZ;
		scaleX = obj.scaleX;
		scaleY = obj.scaleY;
		scaleZ = obj.scaleZ;
		/*rotateX = obj.rotateX;
		rotateY = obj.rotateY;
		rotateZ = obj.rotateZ;
		rotatePoint = obj.rotatePoint;*/
		rotateAxis = obj.rotateAxis;
		rotateAngle = obj.rotateAngle;
		updateMatrix = TRUE;
		colorMultiplier = obj.colorMultiplier;
		shouldDraw = obj.shouldDraw;
		shouldView = obj.shouldView;
		isStatic = obj.isStatic;
		properties = [ [ NSMutableDictionary alloc ] initWithDictionary:[ obj properties ] ];
		base = [ obj instance ];
		if ([ obj name ])
			objName = [ [ NSString alloc ] initWithString:[ obj name ] ];
		currentAnimation = -1;
		
		objectColors = (MDVector4*)malloc(sizeof(MDVector4) * 3);
		memcpy(objectColors, obj.objectColors, sizeof(MDVector4) * 3);
		
		/*faces = [ [ NSMutableArray alloc ] init ];
		for (int z = 0; z < [ obj numberOfFaces	]; z++)
		{
			MDFace* face = [ [ MDFace alloc ] init ];
			[ face setMDObject:self ];
			face.drawMode = [ obj faceAtIndex:z ].drawMode;
			for (int y = 0; y < [ [ obj faceAtIndex:z ] numberOfPoints ]; y++)
			{
				MDPoint* p = [ [ MDPoint alloc ] initWithPoint:[ [ obj faceAtIndex:z ] pointAtIndex:y ] ];
				[ face addPoint:p ];
				[ p release ];
			}
			[ [ face properties ] setDictionary:[ [ obj faceAtIndex:z ] properties ] ];
			[ faces addObject:face ];
			[ face release ];
		}*/
		
		mass = obj.mass;
		restitution = obj.restitution;
		physicsType = obj.physicsType;
		flags = obj.flags;
		friction = obj.friction;
		rollingFriction = obj.rollingFriction;
		
		type = [ obj type ];
		data = [ [ NSMutableArray alloc ] initWithArray:[ obj data ] ];
	}
	return self;
}

- (instancetype) initWithInstance:(MDInstance*)inst
{
	if ((self = [ super init ]))
	{
		if (!inst)
			return self;
		
		scaleX = scaleY = scaleZ = 1;
		updateMatrix = TRUE;
		objectColors = (MDVector4*)malloc(sizeof(MDVector4) * 3);
		memset(objectColors, 0, sizeof(MDVector4) * 3);
		//faces = [ [ NSMutableArray alloc ] init ];
		objectColors[0].x = objectColors[1].z = objectColors[2].x = objectColors[2].y = 0.7;
		objectColors[0].w = objectColors[1].w = objectColors[2].w = 1;
		//rotatePoint = MDVector3Create(0, 0, 0);
		rotateAxis = MDVector3Create(0, 0, 0);
		colorMultiplier = MDVector4Create(1, 1, 1, 1);
		shouldDraw = TRUE;
		shouldView = TRUE;
		properties = [ [ NSMutableDictionary alloc ] initWithDictionary:[ inst properties ] ];
		base = inst;
		type = 0;
		data = [ [ NSMutableArray alloc ] init ];
		isStatic = FALSE;
		currentAnimation = -1;
		
		flags = (1 << 0) | (1 << 1);	// affect position and rotation
	}
	return self;
}

- (BOOL) isEqualToObject:(MDObject*)obj
{
	if (fabs(obj.translateX - translateX) > 0.01)
		return FALSE;
	if (fabs(obj.translateY - translateY) > 0.01)
		return FALSE;
	if (fabs(obj.translateZ - translateZ) > 0.01)
		return FALSE;
	if (fabs(obj.scaleX - scaleX) > 0.01)
		return FALSE;
	if (fabs(obj.scaleY - scaleY) > 0.01)
		return FALSE;
	if (fabs(obj.scaleZ	- scaleZ) > 0.01)
		return FALSE;
	/*if (fabs(obj.rotateX - rotateX) > 0.01)
		return FALSE;
	if (fabs(obj.rotateY - rotateY) > 0.01)
		return FALSE;
	if (fabs(obj.rotateZ - rotateZ) > 0.01)
		return FALSE;
	if (fabs(obj.rotatePoint.x - rotatePoint.x) > 0.01)
		return FALSE;
	if (fabs(obj.rotatePoint.y - rotatePoint.y) > 0.01)
		return FALSE;
	if (fabs(obj.rotatePoint.z - rotatePoint.z) > 0.01)
		return FALSE;*/
	if (fabs(obj.rotateAxis.x - rotateAxis.x) > 0.01)
		return FALSE;
	if (fabs(obj.rotateAxis.y - rotateAxis.y) > 0.01)
		return FALSE;
	if (fabs(obj.rotateAxis.z - rotateAxis.z) > 0.01)
		return FALSE;
	if (fabs(obj.rotateAngle - rotateAngle) > 0.01)
		return FALSE;
	if (!(obj.colorMultiplier == colorMultiplier))
		return FALSE;
	if (obj.shouldDraw != shouldDraw)
		return FALSE;
	if (obj.isStatic != isStatic)
		return FALSE;
	
	if ([ obj numberOfPoints ] != [ self numberOfPoints ])
		return FALSE;
	
	for (unsigned long z = 0; z < [ self numberOfPoints ]; z++)
	{
		MDPoint* p1 = [ obj pointAtIndex:z ];
		MDPoint* p2 = [ self pointAtIndex:z ];
		if (fabs(p1.x - p2.x) > 0.01)
			return FALSE;
		if (fabs(p1.y - p2.y) > 0.01)
			return FALSE;
		if (fabs(p1.z - p2.z) > 0.01)
			return FALSE;
		/*if (fabs(p1.red - p2.red) > 0.01)
			return FALSE;
		if (fabs(p1.green - p2.green) > 0.01)
			return FALSE;
		if (fabs(p1.blue - p2.blue) > 0.01)
			return FALSE;
		if (fabs(p1.alpha - p2.alpha) > 0.01)
			return FALSE;*/
	}
	
	NSArray* prop1 = [ properties allKeys ];
	NSArray* prop2 = [ [ obj properties ] allKeys ];
	if ([ prop1 count ] != [ prop2 count ])
		return FALSE;
	
	for (unsigned long z = 0; z < [ prop1 count ]; z++)
	{
		id obj1 = prop1[z];
		id obj2 = prop2[z];
		if (![ obj1 isEqualTo:obj2 ])
			return FALSE;
	}
	
	if (fabs(obj.mass - mass) > 0.01)
		return FALSE;
	if (fabs(obj.restitution - restitution) > 0.01)
		return FALSE;
	if (obj.physicsType != physicsType)
		return FALSE;
	if (obj.flags != flags)
		return FALSE;
	if (fabs(obj.friction - friction) > 0.01)
		return FALSE;
	if (fabs(obj.rollingFriction - rollingFriction) > 0.01)
		return FALSE;
	
	return TRUE;
}

- (unsigned int) findKey:(std::vector<float>*)times atTime:(float)time
{
	unsigned int ret = 0;
	for (unsigned int z = 0; z < times->size() - 1; z++)
	{
		if (time < times->at(z + 1))
		{
			ret = z;
			break;
		}
	}
	return ret;
}

- (void) processNode:(MDNode*)node atTime:(float)time withMatrix:(MDMatrix)parent withAnimations:(NSArray*)animations withMeshes:(NSArray*)meshes
{
	unsigned long stepIndex = [ node animationStepAtIndex:currentAnimation ];
	
	MDMatrix nodeTransform = [ node transformation ];
	
	if (stepIndex != -1)
	{
		MDAnimation* animation = animations[currentAnimation];
		MDAnimationStep step = [ animation steps ]->at(stepIndex);
		// Interpolate scaling
		MDVector3 scaling = MDVector3Create(1, 1, 1);
		if (step.scalings.size() == 1)
			scaling = step.scalings[0];
		else if (step.scalings.size() != 0)
		{
			unsigned int key = [ self findKey:&step.scaleTimes atTime:time ];
			unsigned int nextKey = key + 1;
			// if nextKey > step.scaleTimes.size(), do nothing?
			float deltaT = step.scaleTimes[nextKey] - step.scaleTimes[key];
			float factor = (time - step.scaleTimes[key]) / deltaT;
			// if (factor < 0 || factor > 1), do nothing?
			MDVector3 start = step.scalings[key];
			scaling = start + (step.scalings[nextKey] - start) * factor;
		}
		MDMatrix scaleMatrix = MDMatrixIdentity();
		MDMatrixScale(&scaleMatrix, scaling.x, scaling.y, scaling.z);
		
		// Interpolate rotation
		MDVector4 q = MDVector4Create(0, 0, 0, 1);
		if (step.rotations.size() == 1)
			q = step.rotations[0];
		else if (step.rotations.size() != 0)
		{
			unsigned int key = [ self findKey:&step.rotateTimes atTime:time ];
			unsigned int nextKey = key + 1;
			// if nextKey > step.rotateTimes.size(), do nothing?
			float deltaT = step.rotateTimes[nextKey] - step.rotateTimes[key];
			float factor = (time - step.rotateTimes[key]) / deltaT;
			// if (factor < 0 || factor > 1), do nothing?
			MDVector4 start = step.rotations[key], end = step.rotations[nextKey];
			// Spherical interpolation
			float dot = MDVector4DotProduct(start, end);
			if (dot < 0)
			{
				dot = -dot;
				end = -1 * end;
			}
			if (dot < 0.9999)
			{
				float omega = acos(dot);
				q = (sin((1 - factor) * omega) * start + sin(factor * omega) * end) / sin(omega);
			}
			else
				q = (1 - factor) * start + factor * end;
		}
		MDMatrix rotateMatrix = MDMatrixTranspose(MDMatrixCreate(1 - 2 * q.y * q.y - 2 * q.z * q.z, 2 * q.x * q.y + 2 * q.z * q.w, 2 * q.x * q.z - 2 * q.y * q.w, 0,
																 2 * q.x * q.y - 2 * q.z * q.w, 1 - 2 * q.x * q.x - 2 * q.z * q.z, 2 * q.y * q.z + 2 * q.x * q.w, 0,
																 2 * q.x * q.z + 2 * q.y * q.w, 2 * q.y * q.z - 2 * q.x * q.w, 1 - 2 * q.x * q.x - 2 * q.y * q.y, 0,
																 0, 0, 0, 1));
		
		// Interpolate translation
		MDVector3 translate = MDVector3Create(0, 0, 0);
		if (step.positions.size() == 1)
			translate = step.positions[0];
		else if (step.positions.size() != 0)
		{
			unsigned int key = [ self findKey:&step.positionTimes atTime:time ];
			unsigned int nextKey = key + 1;
			// if nextKey > step.positionTimes.size(), do nothing?
			float deltaT = step.positionTimes[nextKey] - step.positionTimes[key];
			float factor = (time - step.positionTimes[key]) / deltaT;
			// if (factor < 0 || factor > 1), do nothing?
			MDVector3 start = step.positions[key];
			translate = start + (step.positions[nextKey] - start) * factor;
		}
		MDMatrix translateMatrix = MDMatrixIdentity();
		MDMatrixTranslate(&translateMatrix, translate.x, translate.y, translate.z);
		
		nodeTransform = translateMatrix * rotateMatrix * scaleMatrix;
	}
	
	MDMatrix globalTransform = parent * nodeTransform;
	
	if ([ node isBone ])
	{
		for (unsigned long z = 0; z < [ node numberOfBones ]; z++)
		{
			MDBone* bone = [ meshes[[ node meshIndexAtIndex:z ]] boneAtIndex:[ node boneIndexAtIndex:z ] ];
			[ bone setTransformation:[ [ bone mesh ] transformMatrix ] * [ base inverseRoot ] * globalTransform * [ bone offsetMatrix ] ];
		}
	}
	for (unsigned long z = 0; z < [ [ node meshes ] count ]; z++)
	{
		MDMesh* mesh = meshes[[ [ node meshes ][z] unsignedIntValue ]];
		[ mesh setMeshMatrix:globalTransform * [ mesh inverseTransformMatrix ] ];
	}
	
	for (unsigned long z = 0; z < [ [ node children ] count ]; z++)
		[ self processNode:[ node children ][z] atTime:time withMatrix:globalTransform withAnimations:animations withMeshes:meshes ];
}

- (void) updateAnimation
{
	if (currentAnimation == -1)
		return;
	
	MDNode* rootNode = [ base rootNode ];
	NSArray* animations = [ base animations ];
	
	NSArray* meshes = [ base meshes ];
	
	// Not Paused
	if (!(animationFlags & 0x1))
		currentAnimationTime += 1 / 60.0 * currentAnimationSpeed;
	
	MDAnimation* animation = animations[currentAnimation];
	if (currentAnimationSpeed > 0)
	{
		// Repeats
		if ((animationFlags & 0x2) && [ animation duration ] <= currentAnimationTime)
			currentAnimationTime -= [ animation duration ];
		else if ([ animation duration ] <= currentAnimationTime)	// Done
			currentAnimation = -1;
	}
	else
	{
		// Repeats
		if ((animationFlags & 0x2) && 0 >= currentAnimationTime)
			currentAnimationTime += [ animation duration ];
		else if ([ animation duration ] <= currentAnimationTime)	// Done
			currentAnimation = -1;
	}
	
	[ self processNode:rootNode atTime:currentAnimationTime withMatrix:MDMatrixIdentity() withAnimations:animations withMeshes:meshes ];
	
	// Update the bone matrices
	MDMatrix zeroMatrix;
	memset(zeroMatrix.data, 0, 16 * sizeof(float));
	for (unsigned long z = 0; z < [ meshes count ]; z++)
	{
		MDMesh* mesh = meshes[z];
		for (unsigned long y = 0; y < [ mesh numberOfPoints ]; y++)
		{
			MDPoint* p = [ mesh pointAtIndex:y ];
			[ p setBoneMatrix:zeroMatrix ];
			[ p setHasBone:NO ];
		}
		for (unsigned long y = 0; y < [ mesh numberOfBones ]; y++)
		{
			MDBone* bone = [ mesh boneAtIndex:y ];
			for (unsigned long x = 0; x < [ bone numberOfWeights ]; x++)
			{
				MDVertexWeight* weight = [ bone weightAtIndex:x ];
				MDPoint* p = [ mesh pointAtIndex:[ weight vertexID ] ];
				p.boneMatrix += [ bone transformation ] * [ weight weight ];
				[ p setHasBone:YES ];
			}
		}
	}
	
	MDMatrix startMatrix = [ base startMatrix ], startInverse = [ base inverseStartMatrix ];
	
	for (unsigned long y = 0; y < [ meshes count ]; y++)
	{
		MDMesh* mesh = meshes[y];
		unsigned long numberOfPoints = [ mesh numberOfPoints ];
		for (unsigned long z = 0; z < numberOfPoints; z++)
		{
			MDPoint* p = [ mesh pointAtIndex:z ];
			MDMatrix matrix = [ p boneMatrix ];
			if (![ p hasBone ])
				matrix = MDMatrixIdentity();
			matrix = startMatrix * matrix * [ mesh meshMatrix ] * startInverse;
			
			[ mesh setMatrixData:matrix atIndex:z ];
		}
		[ mesh updateMatrixData ];
	}
}

- (void) drawVBO:(unsigned int*)program shadow:(unsigned int)shadowStart
{
	[ self updateAnimation ];
	
	MDVector4 specularColor = [ base specularColor ];
	float shininess = [ base shininess ];
	
	glUniform4f(program[MD_PROGRAM0_FRONTMATERIALSPECULAR], specularColor.x, specularColor.y, specularColor.z, specularColor.w);
	glUniform1f(program[MD_PROGRAM0_FORNTMATERIALSHININESS], shininess);
	
	NSArray* meshes = [ base meshes ];
	for (unsigned long z = 0; z < [ meshes count ]; z++)
	{
		MDMesh* mesh = meshes[z];
		
		glBindVertexArray([ mesh vao ]);
		
		unsigned int texCount[4] = { 0 };	// 1 for each type of texture
		//NSString* texNames[4] = { @"diffuse", @"bump", @"diffuseMap", @"map" };
		// Disable unused textures
		for (unsigned int q = 0; q < 1; q++)
		{
			//glUniform1i(glGetUniformLocation(program, [ [ NSString stringWithFormat:@"diffuseTextures[%u].enabled", q ] UTF8String ]), 0);
			//glUniform1i(glGetUniformLocation(program, [ [ NSString stringWithFormat:@"bumpTextures[%u].enabled", q ] UTF8String ]), 0);
			
			
			// For now - can cache them in memory
			glUniform1i(program[MD_PROGRAM0_DIFFUSETEXTURES0_ENABLED], 0);
			glUniform1i(program[MD_PROGRAM0_BUMPTEXTURES0_ENABLED], 0);
		}
		// Replace 1 with MAX_TEXTURES
		for (unsigned int q = 0; q < 1; q++)
		{
			//glUniform1i(glGetUniformLocation(program, [ [ NSString stringWithFormat:@"mapTextures[%u].enabled", q ] UTF8String ]), 0);
			//for (unsigned int y = 0; y < 3; y++)
			//{
			//	glUniform1i(glGetUniformLocation(program, [ [ NSString stringWithFormat:@"diffuseMapTextures[%u].enabled", (q * 3) + y ] UTF8String ]), 0);
			//}
			
			// For now - can cache them in memory
			glUniform1i(program[MD_PROGRAM0_MAPTEXTURES0_ENABLED], 0);
			glUniform1i(program[MD_PROGRAM0_DIFFUSEMAPTEXTURES0_ENABLED], 0);
			glUniform1i(program[MD_PROGRAM0_DIFFUSEMAPTEXTURES1_ENABLED], 0);
			glUniform1i(program[MD_PROGRAM0_DIFFUSEMAPTEXTURES2_ENABLED], 0);
		}
		
		for (unsigned int q = 0; q < [ mesh numberOfTextures ]; q++)
		{
			MDTexture* texture = [ mesh textureAtIndex:q ];
			glActiveTexture(GL_TEXTURE0 + q + shadowStart);
			glBindTexture(GL_TEXTURE_2D, [ texture texture ]);
			
			unsigned int dest = texCount[texture.type]++;
			//NSString* str = texNames[texture.type];
			glUniform1i(program[MDUniformTextureLocation(dest, texture.type) + MD_PROGRAM0_TEXTURE_TEXTURE], q + shadowStart);
			glUniform1f(program[MDUniformTextureLocation(dest, texture.type) + MD_PROGRAM0_TEXTURE_SIZE], texture.size);
			glUniform1i(program[MDUniformTextureLocation(dest, texture.type) + MD_PROGRAM0_TEXTURE_ENABLED], 1);
			//glUniform1i(glGetUniformLocation(program, [ [ NSString stringWithFormat:@"%@Textures[%u].texture", str, dest ] UTF8String ]), q + shadowStart);
			//glUniform1f(glGetUniformLocation(program, [ [ NSString stringWithFormat:@"%@Textures[%u].size", str, dest ] UTF8String ]), texture.size);
			//glUniform1i(glGetUniformLocation(program, [ [ NSString stringWithFormat:@"%@Textures[%u].enabled", str, dest ] UTF8String ]), 1);
			int children[3] = { 0 };
			if (texture.type == MD_TEXTURE_TERRAIN_ALPHA)
			{
				unsigned long iCounter = 0;
				for (unsigned int y = 0, num = 0; y < [ mesh numberOfTextures ]; y++)
				{
					if ([ mesh textureAtIndex:y ].head == q)
					{
						children[iCounter++] = num;
						if (iCounter == 3)
							break;
					}
					if ([ mesh textureAtIndex:y ].type == MD_TEXTURE_TERRAIN_DIFFUSE)
						num++;
				}
			}
			glUniform1iv(program[MDUniformTextureLocation(dest, texture.type) + MD_PROGRAM0_TEXTURE_CHILDREN], 3, children);
			//glUniform1iv(glGetUniformLocation(program, [ [ NSString stringWithFormat:@"%@Textures[%u].children", str, dest ] UTF8String ]), 3, children);
		}
		if ([ mesh numberOfTextures ] == 0)
			glBindTexture(GL_TEXTURE_2D, 0);
		
		MDVector4 color = [ mesh color ];
		glVertexAttrib4f(1, color.x, color.y, color.z, color.w);
		glDrawElements(GL_TRIANGLES, [ mesh numberOfIndices ], GL_UNSIGNED_INT, NULL);
		
		if (currentAnimation != -1)
			[ mesh resetMatrixData ];
	}
	
	// Unbind
	//glBindVertexArray(0);
	
	//glActiveTexture(GL_TEXTURE0);
	//glBindTexture(GL_TEXTURE_2D, 0);
}

- (void) setName:(NSString*)name
{
	if (name)
		objName = [ [ NSString alloc ] initWithString:name ];
	else
		objName = nil;
}

- (NSString*) name
{
	return objName;
}

- (void) setInstance:(MDInstance*)inst
{
	base = inst;
}

- (MDInstance*) instance
{
	return base;
}

- (void) playAnimation:(NSString*)name
{
	[ self playAnimation:name speed:1 flags:MD_ANIMATION_NONE ];
}

- (void) playAnimation:(NSString*)name speed:(float)sp flags:(unsigned char)flag
{
	NSArray* animations = [ base animations ];
	for (unsigned long z = 0; z < [ animations count ]; z++)
	{
		MDAnimation* animation = animations[z];
		if ([ [ animation name ] isEqualToString:name ])
		{
			currentAnimation = z;
			break;
		}
	}
	currentAnimationTime = 0;
	currentAnimationSpeed = sp;
	if (sp < 0)
		currentAnimationTime = [ (MDAnimation*)animations[currentAnimation] duration ];
	animationFlags = flag;
}

- (void) pauseAnimation
{
	animationFlags |= MD_ANIMATION_PAUSED;
}

- (void) resumeAnimation
{
	animationFlags &= ~(MD_ANIMATION_PAUSED);
}

- (void) stopAnimation
{
	currentAnimation = -1;
}

- (MDVector3) midPoint
{
	MDObject* obj = self;
	float left = 100000, right = -10000, top = 10000, bot = -10000, front = -10000, back = 10000;
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
	MDVector3 p = { left + ((right - left) / 2), bot + ((top - bot) / 2), front + ((back - front) / 2) };
	return p;
}

- (MDVector3) realMidPoint
{
	MDVector3 mid = [ self midPoint ];
	mid.x += translateX;
	mid.y += translateY;
	mid.z += translateZ;
	return mid;
}

- (MDVector3) translate
{
	return MDVector3Create(translateX, translateY, translateZ);
}

- (MDVector3) objMidPoint
{
	return [ base midPoint ];
}

- (MDVector4) midColor
{	
	MDVector4 color2;
	memset(&color2, 0, sizeof(color2));
	
	float divide = 0;
	
	for (unsigned long y = 0; y < [ base numberOfMeshes ]; y++)
	{
		MDVector4 color = [ [ base meshAtIndex:y ] color ];
		divide++;
		color2 += color;
	}
	
	if (divide != 0)
		color2 /= divide;
	
	return color2;
}

- (MDVector4) specularColor
{
	return [ base specularColor ];
}

- (float) shininess
{
	return [ base shininess ];
}

- (MDPoint*) pointAtIndex:(unsigned long)index
{
	return [ base pointAtIndex:index ];
}

- (unsigned long) numberOfPoints
{
	return [ base numberOfPoints ];
}

- (NSArray*) points
{
	return [ base points ];
}

- (MDMatrix) modelViewMatrix
{
	if (updateMatrix)
	{
		modelMatrix = MDMatrixIdentity();
		// Assumed to be zero
		//MDVector3 midPoint = [ self midPoint ];
		//MDMatrixTranslate(&matrix, translateX + midPoint.x, translateY + midPoint.y, translateZ + midPoint.z);
		MDMatrixTranslate(&modelMatrix, translateX, translateY, translateZ);
		if (MDVector3Magnitude(rotateAxis) != 0 && rotateAngle != 0)
			MDMatrixRotate(&modelMatrix, rotateAxis, rotateAngle);
		MDMatrixScale(&modelMatrix, scaleX, scaleY, scaleZ);
		//MDMatrixTranslate(&matrix, -1 * midPoint);
		updateMatrix = FALSE;
	}
	return modelMatrix;
}

/*- (MDMatrix) modelViewMatrixMidPoint
{
	MDMatrix matrix2 = MDMatrixIdentity();
	MDVector3 midPoint = [ self midPoint ];
	MDMatrixTranslate(&matrix2, translateX + midPoint.x, translateY + midPoint.y, translateZ + midPoint.z);
	if (MDVector3Magnitude(rotateAxis) != 0 && rotateAngle != 0)
		MDMatrixRotate(&matrix2, rotateAxis, rotateAngle);
	MDMatrixScale(&matrix2, scaleX, scaleY, scaleZ);
	MDMatrixTranslate(&matrix2, -1 * midPoint);
	return matrix2;
}*/

- (void) addProperty: (NSString*) prop forKey:(NSString*)string
{
	NSDictionary* dict = @{string: prop};
	[ properties addEntriesFromDictionary:dict ];
}

- (NSMutableDictionary*) properties
{
	return properties;
}

- (void) setTranslateX:(float)value
{
	translateX = value;
	updateMatrix = TRUE;
}

- (void) setTranslateY:(float)value
{
	translateY = value;
	updateMatrix = TRUE;
}

- (void) setTranslateZ:(float)value
{
	translateZ = value;
	updateMatrix = TRUE;
}

- (void) setScaleX:(float)value
{
	scaleX = value;
	updateMatrix = TRUE;
}

- (void) setScaleY:(float)value
{
	scaleY = value;
	updateMatrix = TRUE;
}

- (void) setScaleZ:(float)value
{
	scaleZ = value;
	updateMatrix = TRUE;
}

- (void) setRotateAxis:(MDVector3)value
{
	rotateAxis = value;
	updateMatrix = TRUE;
}

- (void) setRotateAngle:(float)value
{
	rotateAngle = value;
	updateMatrix = TRUE;
}

- (void) addTranslateX:(float)value
{
	translateX += value;
	updateMatrix = TRUE;
}

- (void) addTranslateY:(float)value
{
	translateY += value;
	updateMatrix = TRUE;
}

- (void) addTranslateZ:(float)value
{
	translateZ += value;
	updateMatrix = TRUE;
}

- (void) addScaleX:(float)value
{
	scaleX += value;
	updateMatrix = TRUE;
}

- (void) addScaleY:(float)value
{
	scaleY += value;
	updateMatrix = TRUE;
}

- (void) addScaleZ:(float)value
{
	scaleZ += value;
	updateMatrix = TRUE;
}

/*- (void) setMidPointX:(float)value
{
	float diff = [ self midPoint ].x - value;
	for (int z = 0; z < [ faces count ]; z++)
	{
		for (int q = 0; q < [ [ faces objectAtIndex:z ] numberOfPoints ]; q++)
		{
			MDPoint* p = [ [ faces objectAtIndex:z ] pointAtIndex:q ];
			p.x -= diff;
		}
		
		if ([ [ self faceAtIndex:z ] displayList ] != (unsigned int)-1)
		{
			glDeleteLists([ [ self faceAtIndex:z ] displayList ], 1);
			[ [ self faceAtIndex:z ] setDisplayList:-1 ];
		}
	}
}

- (void) setMidPointY:(float)value
{
	float diff = [ self midPoint ].y - value;
	for (int z = 0; z < [ faces count ]; z++)
	{
		for (int q = 0; q < [ [ faces objectAtIndex:z ] numberOfPoints ]; q++)
		{
			MDPoint* p = [ [ faces objectAtIndex:z ] pointAtIndex:q ];
			p.y -= diff;
		}
		
		if ([ [ self faceAtIndex:z ] displayList ] != (unsigned int)-1)
		{
			glDeleteLists([ [ self faceAtIndex:z ] displayList ], 1);
			[ [ self faceAtIndex:z ] setDisplayList:-1 ];
		}
	}
}

- (void) setMidPointZ:(float)value
{
	float diff = [ self midPoint ].z - value;
	for (int z = 0; z < [ faces count ]; z++)
	{
		for (int q = 0; q < [ [ faces objectAtIndex:z ] numberOfPoints ]; q++)
		{
			MDPoint* p = [ [ faces objectAtIndex:z ] pointAtIndex:q ];
			p.z -= diff;
		}
		
		if ([ [ self faceAtIndex:z ] displayList ] != (unsigned int)-1)
		{
			glDeleteLists([ [ self faceAtIndex:z ] displayList ], 1);
			[ [ self faceAtIndex:z ] setDisplayList:-1 ];
		}
	}
}*/

- (void) setMidPoint:(MDVector3)point
{
	/*[ self setMidPointX:point.x ];
	[ self setMidPointY:point.y ];
	[ self setMidPointZ:point.z ];*/
	
	translateX = point.x;
	translateY = point.y;
	translateZ = point.z;
	updateMatrix = TRUE;
}

- (void) setMidColor:(MDVector4)color2
{
	/*for (unsigned long q = 0; q < [ self numberOfPoints ]; q++)
	{
		MDPoint* p = [ self pointAtIndex:q ];
		p.red = color.red;
		p.green = color.green;
		p.blue = color.blue;
		p.alpha = color.alpha;
	}*/
	
	for (unsigned long q = 0; q < [ base numberOfMeshes ]; q++)
		[ [ base meshAtIndex:q ] setColor:color2 ];
}

- (void) addMidColor:(MDVector4)color2
{
	MDVector4 midColor = [ self midColor ];
	[ self setMidColor:color2 + midColor ];
}

- (void) setSpecularColor:(MDVector4)color2
{
	[ base setSpecularColor:color2 ];
}

- (void) addSpecularColor:(MDVector4)color2
{
	MDVector4 spec = [ base specularColor ];
	[ base setSpecularColor:color2 + spec ];
}

- (void) setShininess:(float)shine
{
	[ base setShininess:shine ];
}

- (void) addShininess:(float)shine
{
	[ self setShininess:[ self shininess ] + shine ];
}

// Physics
- (void) setAffectPosition:(BOOL)set
{
	flags &= ~(1 << 0);
	flags |= (set << 0);
}

- (BOOL) affectPosition
{
	return (flags >> 0) & 1;
}

- (void) setAffectRotation:(BOOL)set
{
	flags &= ~(1 << 1);
	flags |= (set << 1);
}

- (BOOL) affectRotation
{
	return (flags >> 1) & 1;
}

- (NSMutableArray*) data
{
	return data;
}

- (void) dealloc
{
	if (objectColors)
	{
		free(objectColors);
		objectColors = NULL;
	}
}

@end

@implementation MDTexture

@synthesize texture;
@synthesize textureLoaded;
@synthesize type;
@synthesize head;
@synthesize size;

- (instancetype) init
{
	if ((self = [ super init ]))
	{
		texture = 0;
		path = [ [ NSString alloc ] init ];
		type = MD_TEXTURE_DIFFUSE;
		textureLoaded = NO;
		head = -1;
		size = 1;
	}
	return self;
}

- (instancetype) initWithTexture:(MDTexture*)tex
{
	if ((self = [ super init ]))
	{
		texture = tex.texture;
		path = [ [ NSString alloc ] initWithString:[ tex path ] ];
		type = tex.type;
		textureLoaded = tex.textureLoaded;
		head = tex.head;
		size = tex.size;
	}
	return self;
}

- (void) setPath:(NSString*)tex
{
	path = [ [ NSString alloc ] initWithString:tex ];
}

- (NSString*) path
{
	return path;
}

@end

@implementation MDVertexWeight

@synthesize vertexID;
@synthesize weight;

- (instancetype) init
{
	if ((self = [ super init ]))
	{
		vertexID = 0;
		weight = 1;
	}
	return self;
}

- (instancetype) initWithVeretx:(unsigned long)vertex withWeight:(float)theWeight
{
	if ((self = [ super init ]))
	{
		vertexID = vertex;
		weight = theWeight;
	}
	return self;
}

- (instancetype) initWithVertexWeight:(MDVertexWeight *)vertex
{
	if ((self = [ super init ]))
	{
		vertexID = [ vertex vertexID ];
		weight = [ vertex weight ];
	}
	return self;
}

@end

@implementation MDBone

@synthesize offsetMatrix;
@synthesize transformation;
@synthesize mesh;

- (instancetype) init
{
	if ((self = [ super init ]))
	{
		vertexWeights = [ [ NSMutableArray alloc ] init ];
		offsetMatrix = MDMatrixIdentity();
	}
	return self;
}

- (instancetype) initWithBone:(MDBone *)bone
{
	if ((self = [ super init ]))
	{
		vertexWeights = [ [ NSMutableArray alloc ] init ];
		for (unsigned long z = 0; z < [ bone numberOfWeights ]; z++)
		{
			MDVertexWeight* weight = [ [ MDVertexWeight alloc ] initWithVertexWeight:[ bone weightAtIndex:z ] ];
			[ vertexWeights addObject:weight ];
		}
		offsetMatrix = [ bone offsetMatrix ];
		transformation = [ bone transformation ];
		mesh = [ bone mesh ];
	}
	return self;
}

- (unsigned long) numberOfWeights
{
	return [ vertexWeights count ];
}

- (MDVertexWeight*) weightAtIndex:(unsigned long)index
{
	if (index >= [ vertexWeights count ])
		return nil;
	return vertexWeights[index];
}

- (void) addVertex:(unsigned long)vertexID withWeight:(float)weight
{
	MDVertexWeight* vert = [ [ MDVertexWeight alloc ] initWithVeretx:vertexID withWeight:weight ];
	[ vertexWeights addObject:vert ];
}

- (void) addVertexWeight:(MDVertexWeight *)weight
{
	[ vertexWeights addObject:weight ];
}

- (NSMutableArray*) vertexWeights
{
	return vertexWeights;
}

@end

@implementation MDMesh

@synthesize meshMatrix;
@synthesize instance;

- (instancetype) init
{
	if ((self = [ super init ]))
	{
		points = [ [ NSMutableArray alloc ] init ];
		textures = [ [ NSMutableArray alloc ] init ];
		indices = [ [ NSMutableArray alloc ] init ];
		bones = [ [ NSMutableArray alloc ] init ];
		meshMatrix = MDMatrixIdentity();
	}
	return self;
}

- (instancetype) initWithMesh:(MDMesh*)mesh
{
	if ((self = [ super init ]))
	{
		points = [ [ NSMutableArray alloc ] init ];
		for (unsigned long z = 0; z < [ mesh numberOfPoints ]; z++)
		{
			MDPoint* p = [ [ MDPoint alloc ] initWithPoint:[ mesh pointAtIndex:z ] ];
			[ points addObject:p ];
		}
		textures = [ [ NSMutableArray alloc ] init ];
		NSArray* texs = [ mesh textures ];
		for (unsigned int z = 0; z < [ texs count ]; z++)
		{
			MDTexture* texture = [ [ MDTexture alloc ] initWithTexture:texs[z] ];
			[ textures addObject:texture ];
		}
		bones = [ [ NSMutableArray alloc ] init ];
		NSArray* bons = [ mesh bones ];
		for (unsigned long z = 0; z < [ bons count ]; z++)
		{
			MDBone* bone = [ [ MDBone alloc ] initWithBone:bons[z] ];
			[ bones addObject:bone ];
		}
		color = [ mesh color ];
		indices = [ [ NSMutableArray alloc ] initWithArray:[ mesh indices ] ];
		
		meshMatrix = [ mesh meshMatrix ];
		
		[ self setupVAO ];
	}
	return self;
}

- (void) setupVAO
{
	// Delete old
	if (vao)
	{
		if (glIsVertexArray(vao))
			glDeleteVertexArrays(1, &vao);
	}
	for (int z = 0; z < 8; z++)
	{
		if (glIsBuffer(vaoBuffers[z]))
			glDeleteBuffers(1, &vaoBuffers[z]);
	}
	if (vertices)
		free(vertices);
	if (indexData)
		free(indexData);
	if (normals)
		free(normals);
	if (texCoords)
		free(texCoords);
	if (colors)
		free(colors);
	if (matrixData)
		free(matrixData);
	
	// Fill the data
	unsigned long numberOfPoints = [ points count ];
	vertices = (MDVector3*)malloc(numberOfPoints * sizeof(MDVector3));
	memset(vertices, 0, sizeof(MDVector3) * [ points count ]);
	indexData = (unsigned int*)malloc([ indices count ] * sizeof(unsigned int));
	for (unsigned long z = 0; z < [ indices count ]; z++)
		indexData[z] = [ indices[z] unsignedIntValue ];
	normals = (MDVector3*)malloc(numberOfPoints * sizeof(MDVector3));
	memset(normals, 0, sizeof(MDVector3) * [ points count ]);
	texCoords = (MDVector2*)malloc(numberOfPoints * sizeof(MDVector2));
	memset(texCoords, 0, sizeof(MDVector2) * [ points count ]);
	//colors = (MDVector4*)malloc(numberOfPoints * sizeof(MDVector4));
	//memset(colors, 0, sizeof(MDVector4) * [ points count ]);
	matrixData = (MDVector4*)malloc(4 * sizeof(MDVector4) * numberOfPoints);
	memset(matrixData, 0, sizeof(MDVector4) * 4 * numberOfPoints);
	for (unsigned long z = 0; z < [ points count ]; z++)
	{
		MDPoint* p = points[z];
		vertices[z] = MDVector3Create(p.x, p.y, p.z);
		normals[z] = MDVector3Create(p.normalX, p.normalY, p.normalZ);
		texCoords[z] = MDVector2Create(p.textureCoordX, p.textureCoordY);
		//colors[z] = MDVector4Create(p.red, p.green, p.blue, p.alpha);
		
		// Setup the identity
		matrixData[z + ([ points count ] * 0)] = MDVector4Create(1, 0, 0, 0);
		matrixData[z + ([ points count ] * 1)] = MDVector4Create(0, 1, 0, 0);
		matrixData[z + ([ points count ] * 2)] = MDVector4Create(0, 0, 1, 0);
		matrixData[z + ([ points count ] * 3)] = MDVector4Create(0, 0, 0, 1);
	}
	
	//if ([ self numberOfIndices ] == 0)
	//	[ self setupIndices ];
	
	glGenVertexArrays(1, &vao);
	glBindVertexArray(vao);
	
	glGenBuffers(9, vaoBuffers);
	
	// Vertices
	glBindBuffer(GL_ARRAY_BUFFER, vaoBuffers[0]);
	glBufferData(GL_ARRAY_BUFFER, sizeof(MDVector3) * numberOfPoints, vertices, GL_STATIC_DRAW);
	glEnableVertexAttribArray(0);
	glVertexAttribPointer(0, 3, GL_FLOAT, NO, 0, NULL);
	
	// Indices
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vaoBuffers[1]);
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(unsigned int) * [ indices count ], indexData, GL_STATIC_DRAW);
	
	/*// Colors
	 glBindBuffer(GL_ARRAY_BUFFER, vaoBuffers[1]);
	 glBufferData(GL_ARRAY_BUFFER, sizeof(MDVector4) * numberOfPoints, colors, GL_STATIC_DRAW);
	 glEnableVertexAttribArray(1);
	 glVertexAttribPointer(1, 4, GL_FLOAT, NO, 0, NULL);*/
	
	// Normals
	glBindBuffer(GL_ARRAY_BUFFER, vaoBuffers[2]);
	glBufferData(GL_ARRAY_BUFFER, sizeof(MDVector3) * numberOfPoints, normals, GL_STATIC_DRAW);
	glEnableVertexAttribArray(2);
	glVertexAttribPointer(2, 3, GL_FLOAT, NO, 0, NULL);
	
	// Texture Coords
	glBindBuffer(GL_ARRAY_BUFFER, vaoBuffers[3]);
	glBufferData(GL_ARRAY_BUFFER, sizeof(MDVector2) * numberOfPoints, texCoords, GL_STATIC_DRAW);
	glEnableVertexAttribArray(3);
	glVertexAttribPointer(3, 2, GL_FLOAT, NO, 0, NULL);
	
	// Vertex Matrix
	for (int z = 0; z < 4; z++)
	{
		glBindBuffer(GL_ARRAY_BUFFER, vaoBuffers[4 + z]);
		glBufferData(GL_ARRAY_BUFFER, sizeof(MDVector4) * numberOfPoints, &matrixData[numberOfPoints * z], GL_STREAM_DRAW);
		glEnableVertexAttribArray(4 + z);
		glVertexAttribPointer(4 + z, 4, GL_FLOAT, NO, 0, NULL);
	}
	
	// Unbind
	glBindVertexArray(0);
}

- (unsigned int) vao
{
	if (vao == 0)
		[ self setupVAO ];
	return vao;
}

- (NSMutableArray*) points
{
	return points;
}

- (unsigned long) numberOfPoints
{
	return [ points count ];
}

- (MDPoint*) pointAtIndex: (unsigned long)index
{
	if ([ points count ] > index)
		return points[index];
	return nil;
}

- (void) setPoint: (MDPoint*)point atIndex:(unsigned long)index
{
	if ([ points count ] > index)
	{
		[ point setMesh:self ];
		points[index] = point;
	}
}

- (void) addPoint: (MDPoint*)point
{
	[ point setMesh:self ];
	[ points addObject:point ];
}

- (void) addTexture:(MDTexture*)tex
{
	[ textures addObject:tex ];
}

- (NSMutableArray*) textures
{
	return textures;
}

- (unsigned long) numberOfTextures
{
	return [ textures count ];
}

- (MDTexture*) textureAtIndex:(unsigned long)index
{
	return textures[index];
}

- (unsigned int) numberOfIndices
{
	return (unsigned int)[ indices count ];
}

- (void) addIndex:(unsigned int)index
{
	[ indices addObject:@(index) ];
}

- (unsigned int) indexAtIndex:(unsigned int)index
{
	return [ indices[index] unsignedIntValue ];
}

- (NSMutableArray*)indices
{
	return indices;
}

- (void) addBone:(MDBone*)bone
{
	[ bones addObject:bone ];
}

- (NSMutableArray*) bones
{
	return bones;
}

- (unsigned long) numberOfBones
{
	return [ bones count ];
}

- (MDBone*) boneAtIndex:(unsigned long)index
{
	if (index >= [ bones count ])
		return nil;
	return bones[index];
}

- (void) setColor:(MDVector4)col
{
	color = col;
}

- (MDVector4) color
{
	return color;
}

- (void) setTransformMatrix:(MDMatrix)matrix
{
	transformMatrix = matrix;
	inverseTransformMatrix = MDMatrixInverse(matrix);
}

- (MDMatrix) transformMatrix
{
	return transformMatrix;
}

- (MDMatrix) inverseTransformMatrix
{
	return inverseTransformMatrix;
}

- (void) setMatrixData:(MDMatrix)matrix atIndex:(unsigned long)z
{
	unsigned long numberOfPoints = [ points count ];
	for (int y = 0; y < 4; y++)
		matrixData[y * numberOfPoints + z] = MDVector4Create(matrix.data[y * 4 + 0], matrix.data[y * 4 + 1], matrix.data[y * 4 + 2], matrix.data[y * 4 + 3]);
}

- (void) updateMatrixData
{
	unsigned long numberOfPoints = [ points count ];
	for (int z = 0; z < 4; z++)
	{
		glBindBuffer(GL_ARRAY_BUFFER, vaoBuffers[4 + z]);
		glBufferData(GL_ARRAY_BUFFER, sizeof(MDVector4) * numberOfPoints, &matrixData[z * numberOfPoints], GL_STREAM_DRAW);
	}
	glBindBuffer(GL_ARRAY_BUFFER, 0);
}

- (void) resetMatrixData
{
	MDMatrix matrix = MDMatrixIdentity();
	unsigned long numberOfPoints = [ points count ];
	for (unsigned long z = 0; z < numberOfPoints; z++)
	{
		for (int y = 0; y < 4; y++)
			matrixData[y * numberOfPoints + z] = MDVector4Create(matrix.data[y * 4 + 0], matrix.data[y * 4 + 1], matrix.data[y * 4 + 2], matrix.data[y * 4 + 3]);
	}
	for (int z = 0; z < 4; z++)
	{
		glBindBuffer(GL_ARRAY_BUFFER, vaoBuffers[4 + z]);
		glBufferData(GL_ARRAY_BUFFER, sizeof(MDVector4) * numberOfPoints, &matrixData[z * numberOfPoints], GL_STREAM_DRAW);
	}
	glBindBuffer(GL_ARRAY_BUFFER, 0);
}

- (void) dealloc
{
	if (vao)
	{
		if (glIsVertexArray(vao))
			glDeleteVertexArrays(1, &vao);
		vao = 0;
	}
	for (int z = 0; z < 8; z++)
	{
		if (glIsBuffer(vaoBuffers[z]))
			glDeleteBuffers(1, &vaoBuffers[z]);
	}
	if (vertices)
		free(vertices);
	if (indexData)
		free(indexData);
	if (normals)
		free(normals);
	if (texCoords)
		free(texCoords);
	if (colors)
		free(colors);
	if (matrixData)
		free(matrixData);
}

@end

@implementation MDNode

@synthesize transformation;
@synthesize isBone;

- (instancetype) init
{
	if ((self = [ super init ]))
	{
		children = [ [ NSMutableArray alloc ] init ];
		animationSteps = [ [ NSMutableArray alloc ] init ];
		meshes = [ [ NSMutableArray alloc ] init ];
		meshIndices = [ [ NSMutableArray alloc ] init ];
		boneIndices = [ [ NSMutableArray alloc ] init ];
		isBone = FALSE;
	}
	return self;
}

- (void) setParent:(MDNode*)par
{
	parent = par;
}

- (MDNode*) parent
{
	return parent;
}

- (void) addChild:(MDNode*)node
{
	[ children addObject:node ];
}

- (void) setChildren:(NSArray*)child
{
	[ children setArray:child ];
}

- (NSMutableArray*) children
{
	return children;
}

- (void) addAnimationStep:(unsigned long)step
{
	[ animationSteps addObject:@(step) ];
}

- (void) setAnimationSteps:(NSArray*)steps
{
	[ animationSteps setArray:steps ];
}

- (NSMutableArray*) animationSteps
{
	return animationSteps;
}

- (unsigned long) animationStepAtIndex:(unsigned long)index
{
	if (index >= [ animationSteps count ])
		return (unsigned long)-1;
	return [ animationSteps[index] unsignedLongValue ];
}

- (void) addMesh:(unsigned int)mesh
{
	[ meshes addObject:@(mesh) ];
}

- (void) setMehses:(NSArray*)mesh
{
	[ meshes setArray:mesh ];
}

- (NSMutableArray*) meshes
{
	return meshes;
}

- (void) addMeshIndex:(unsigned int)mesh boneIndex:(unsigned int)bone
{
	[ meshIndices addObject:@(mesh) ];
	[ boneIndices addObject:@(bone) ];
}

- (unsigned int) meshIndexAtIndex:(unsigned long)index
{
	if (index >= [ meshIndices count ])
		return -1;
	return [ meshIndices[index] unsignedIntValue ];
}

- (unsigned int) boneIndexAtIndex:(unsigned long)index
{
	if (index >= [ boneIndices count ])
		return -1;
	return [ boneIndices[index] unsignedIntValue ];
}

- (unsigned long) numberOfBones
{
	return [ boneIndices count ];
}

@end

@implementation MDAnimation

@synthesize duration;

- (instancetype) init
{
	if ((self = [ super init ]))
	{
		name = [ [ NSString alloc ] init ];
	}
	return self;
}

- (void) setName:(NSString*)nam
{
	name = [ [ NSString alloc ] initWithString:nam ];
}

- (NSString*) name
{
	return name;
}

- (void) setSteps:(std::vector<MDAnimationStep>) step
{
	steps = step;
}

- (std::vector<MDAnimationStep>*) steps
{
	return &steps;
}

@end

@implementation MDInstance

@synthesize specularColor;
@synthesize shininess;

- (instancetype) init
{
	if ((self = [ super init ]))
	{
		name = [ [ NSString alloc ] init ];
		properties = [ [ NSMutableDictionary alloc ] init ];
		animations = [ [ NSMutableArray alloc ] init ];
		meshes = [ [ NSMutableArray alloc ] init ];
		specularColor = MDVector4Create(0, 0, 0, 1);
		shininess = 20;
		startMatrix = MDMatrixIdentity();
		startInverse = MDMatrixIdentity();
	}
	return self;
}

- (instancetype) initWithInstance:(MDInstance*)inst
{
	// TODO: update these to have their info
	if ((self = [ super init ]))
	{
		name = [ [ NSString alloc ] init ];
		meshes = [ [ NSMutableArray alloc ] init ];
		NSArray* instMesh = [ inst meshes ];
		for (unsigned long z = 0; z < [ instMesh count ]; z++)
		{
			MDMesh* mesh = [ [ MDMesh alloc ] initWithMesh:instMesh[z] ];
			[ meshes addObject:mesh ];
		}
		specularColor = inst.specularColor;
		shininess = inst.shininess;
		
		properties = [ [ NSMutableDictionary alloc ] initWithDictionary:[ inst properties ] ];
		animations = [ [ NSMutableArray alloc ] init ];
		startMatrix = [ inst startMatrix ];
		startInverse = MDMatrixInverse(startMatrix);
		
	}
	return self;
}

- (void) addProperty: (NSString*) prop forKey:(NSString*)string
{
	NSDictionary* dict = @{string: prop};
	[ properties addEntriesFromDictionary:dict ];
}

- (NSMutableDictionary*) properties
{
	return properties;
}

- (void) setName:(NSString*)nam
{
	name = [ [ NSString alloc ] initWithString:nam ];
}

- (NSString*) name
{
	return name;
}

- (void) setStartMatrix:(MDMatrix)matrix
{
	startMatrix = matrix;
	startInverse = MDMatrixInverse(startMatrix);
}

- (MDMatrix) startMatrix
{
	return startMatrix;
}

- (MDMatrix) inverseStartMatrix
{
	return startInverse;
}

- (MDMatrix) inverseRoot
{
	return inverseRoot;
}

- (void) setRootNode:(MDNode*)node
{
	rootNode = [ [ MDNode alloc ] init ];
	[ rootNode setTransformation:[ node transformation ] ];
	[ rootNode setIsBone:[ node isBone ] ];
	[ rootNode setParent:[ node parent ] ];
	[ rootNode setChildren:[ node children ] ];
	inverseRoot = MDMatrixInverse([ rootNode transformation ]);
}

- (MDNode*) rootNode
{
	return rootNode;
}

- (void) addAnimation:(MDAnimation *)animation
{
	[ animations addObject:animation ];
}

- (NSMutableArray*) animations
{
	return animations;
}

- (void) addMesh:(MDMesh*)mesh
{
	[ mesh setInstance:self ];
	[ meshes addObject:mesh ];
}

- (void) beginMesh
{
	currentMesh = [ [ MDMesh alloc ] init ];
}

- (void) addPoint: (MDPoint*)point
{
	[ currentMesh addPoint:point ];
}

- (void) setTransformMatrix:(MDMatrix)matrix
{
	[ currentMesh setTransformMatrix:matrix ];
}

- (void) setMeshMatrix:(MDMatrix)matrix
{
	[ currentMesh setMeshMatrix:matrix ];
}

- (void) addTexture:(NSString*)path withType:(MDTextureType)type;
{
	MDTexture* texture = [ [ MDTexture alloc ] init ];
	[ texture setType:type ];
	[ texture setPath:path ];
	[ currentMesh addTexture:texture ];
}

- (void) addTexture:(NSString *)path withType:(MDTextureType)type withHead:(unsigned int)head withSize:(float)size
{
	MDTexture* texture = [ [ MDTexture alloc ] init ];
	[ texture setType:type ];
	[ texture setPath:path ];
	[ texture setHead:head ];
	[ texture setSize:size ];
	[ currentMesh addTexture:texture ];
}

- (void) addBone:(NSArray*)weights withMatrix:(MDMatrix)matrix
{
	MDBone* bone = [ [ MDBone alloc ] init ];
	[ [ bone vertexWeights ] setArray:weights ];
	[ bone setOffsetMatrix:matrix ];
	[ bone setMesh:currentMesh ];
	[ currentMesh addBone:bone ];
}

- (void) addIndex:(unsigned int)index
{
	[ currentMesh addIndex:index ];
}

- (void) setColor:(MDVector4)color
{
	[ currentMesh setColor:color ];
}

- (void) endMesh
{
	[ currentMesh setInstance:self ];
	[ meshes addObject:currentMesh ];
	currentMesh = nil;
}

- (NSArray*) meshes
{
	return [ NSArray arrayWithArray:meshes ];
}

- (MDMesh*) meshAtIndex:(unsigned long)index
{
	return meshes[index];
}

- (unsigned long) numberOfMeshes
{
	return [ meshes count ];
}

- (unsigned long) numberOfPoints
{
	unsigned long total = 0;
	for (unsigned long z = 0; z < [ meshes count ]; z++)
		total += [ meshes[z] numberOfPoints ];
	return total;
}

- (NSArray*) points
{
	NSMutableArray* points = [ NSMutableArray array ];
	for (unsigned long z = 0; z < [ meshes count ]; z++)
	{
		for (unsigned long y = 0; y < [ meshes[z] numberOfPoints ]; y++)
			[ points addObject:[ meshes[z] pointAtIndex:y ] ];
	}
	return points;
}

- (MDPoint*) pointAtIndex: (unsigned long)index
{
	unsigned long total = 0;
	for (unsigned long z = 0; z < [ meshes count ]; z++)
	{
		if (index - total < [ meshes[z] numberOfPoints ])
			return [ meshes[z] pointAtIndex:index - total ];
		total += [ meshes[z] numberOfPoints ];
	}
	return nil;
}

- (void) setPoint: (MDPoint*)point atIndex:(unsigned long)index
{
	unsigned long total = 0;
	for (unsigned long z = 0; z < [ meshes count ]; z++)
	{
		if (index - total < [ meshes[z] numberOfPoints ])
		{
			[ meshes[z] setPoint:point atIndex:index - total ];
			break;
		}
		total += [ meshes[z] numberOfPoints ];
	}
}

- (unsigned int) indexAtIndex:(unsigned long)index
{
	unsigned long compare = 0;
	for (unsigned long z = 0; z < [ meshes count ]; z++)
	{
		MDMesh* mesh = meshes[z];
		if (index - compare < [ mesh numberOfIndices ])
			return [ mesh indexAtIndex:(unsigned int)(index - compare) ];
		compare += [ mesh numberOfIndices];
	}
	return -1;
}

- (void) setIndex:(unsigned int)index atIndex:(unsigned long)place
{
	unsigned long compare = 0;
	for (unsigned long z = 0; z < [ meshes count ]; z++)
	{
		MDMesh* mesh = meshes[z];
		if (place - compare < [ mesh numberOfIndices ])
		{
			[ mesh indices ][(unsigned int)(place - compare)] = @(index);
			break;
		}
		compare += [ mesh numberOfIndices];
	}
}

- (unsigned long) numberOfIndices
{
	unsigned int total = 0;
	for (unsigned long z = 0; z < [ meshes count ]; z++)
		total += [ (MDMesh*)meshes[z] numberOfIndices ];
	return total;
}

- (void) setupVBO
{
	for (unsigned long z = 0; z < [ meshes count ]; z++)
		[ meshes[z] setupVAO ];
}

/*- (void) setupIndices
{
	NSMutableArray* verts = [ [ NSMutableArray alloc ] init ];
	
	for (unsigned long z = 0; z < [ points count ]; z++)
	{
		MDPoint* p = [ points objectAtIndex:z ];
		
		BOOL found = FALSE;
		for (unsigned long t = 0; t < [ verts count ]; t++)
		{
			MDPoint* p1 = [ verts objectAtIndex:t ];
			if (MDFloatCompare(p1.x, p.x) && MDFloatCompare(p1.y, p.y) && MDFloatCompare(p1.z, p.z) &&
				MDFloatCompare(p1.normalX, p.normalX) && MDFloatCompare(p1.normalY, p.normalY) && MDFloatCompare(p1.normalZ, p.normalZ) &&
				MDFloatCompare(p1.textureCoordX, p.textureCoordX) && MDFloatCompare(p1.textureCoordY, p.textureCoordY))
			{
				found = TRUE;
				break;
			}
		}
		
		if (!found)
			[ verts addObject:p ];
	}
	
	[ meshes removeAllObjects ];
	
	[ self beginMesh ];
	for (unsigned long z = 0; z < [ points count ]; z++)
	{
		MDPoint* p = [ points objectAtIndex:z ];
		for (unsigned long t = 0; t < [ verts count ]; t++)
		{
			MDPoint* p1 = [ verts objectAtIndex:t ];
			if (MDFloatCompare(p1.x, p.x) && MDFloatCompare(p1.y, p.y) && MDFloatCompare(p1.z, p.z) &&
				MDFloatCompare(p1.normalX, p.normalX) && MDFloatCompare(p1.normalY, p.normalY) && MDFloatCompare(p1.normalZ, p.normalZ) &&
				MDFloatCompare(p1.textureCoordX, p.textureCoordX) && MDFloatCompare(p1.textureCoordY, p.textureCoordY))
			{
				[ self addIndex:(unsigned int)t ];
				break;
			}
		}
	}
	[ self endMesh ];
	
	[ points setArray:verts ];
	[ verts release ];
}*/

- (void) drawVBO:(unsigned int*)program shadow:(unsigned int)shadowStart
{
	glUniform4f(program[MD_PROGRAM0_FRONTMATERIALSPECULAR], specularColor.x, specularColor.y, specularColor.z, specularColor.w);
	glUniform1f(program[MD_PROGRAM0_FORNTMATERIALSHININESS], shininess);
	
	for (unsigned long z = 0; z < [ meshes count ]; z++)
	{
		MDMesh* mesh = meshes[z];
		
		glBindVertexArray([ mesh vao ]);
		
		unsigned int texCount[4] = { 0 };	// 1 for each type of texture
		//NSString* texNames[4] = { @"diffuse", @"bump", @"diffuseMap", @"map" };
		// Disable unused textures
		for (unsigned int q = 0; q < 1; q++)
		{
			//glUniform1i(glGetUniformLocation(program, [ [ NSString stringWithFormat:@"diffuseTextures[%u].enabled", q ] UTF8String ]), 0);
			//glUniform1i(glGetUniformLocation(program, [ [ NSString stringWithFormat:@"bumpTextures[%u].enabled", q ] UTF8String ]), 0);
			
			
			// For now - can cache them in memory
			glUniform1i(program[MD_PROGRAM0_DIFFUSETEXTURES0_ENABLED], 0);
			glUniform1i(program[MD_PROGRAM0_BUMPTEXTURES0_ENABLED], 0);
		}
		// Replace 1 with MAX_TEXTURES
		for (unsigned int q = 0; q < 1; q++)
		{
			//glUniform1i(glGetUniformLocation(program, [ [ NSString stringWithFormat:@"mapTextures[%u].enabled", q ] UTF8String ]), 0);
			//for (unsigned int y = 0; y < 3; y++)
			//{
			//	glUniform1i(glGetUniformLocation(program, [ [ NSString stringWithFormat:@"diffuseMapTextures[%u].enabled", (q * 3) + y ] UTF8String ]), 0);
			//}
			
			// For now - can cache them in memory
			glUniform1i(program[MD_PROGRAM0_MAPTEXTURES0_ENABLED], 0);
			glUniform1i(program[MD_PROGRAM0_DIFFUSEMAPTEXTURES0_ENABLED], 0);
			glUniform1i(program[MD_PROGRAM0_DIFFUSEMAPTEXTURES1_ENABLED], 0);
			glUniform1i(program[MD_PROGRAM0_DIFFUSEMAPTEXTURES2_ENABLED], 0);
		}
		
		for (unsigned int q = 0; q < [ mesh numberOfTextures ]; q++)
		{
			MDTexture* texture = [ mesh textureAtIndex:q ];
			glActiveTexture(GL_TEXTURE0 + q + shadowStart);
			glBindTexture(GL_TEXTURE_2D, [ texture texture ]);
			
			unsigned int dest = texCount[texture.type]++;
			//NSString* str = texNames[texture.type];
			glUniform1i(program[MDUniformTextureLocation(dest, texture.type) + MD_PROGRAM0_TEXTURE_TEXTURE], q + shadowStart);
			glUniform1f(program[MDUniformTextureLocation(dest, texture.type) + MD_PROGRAM0_TEXTURE_SIZE], texture.size);
			glUniform1i(program[MDUniformTextureLocation(dest, texture.type) + MD_PROGRAM0_TEXTURE_ENABLED], 1);
			//glUniform1i(glGetUniformLocation(program, [ [ NSString stringWithFormat:@"%@Textures[%u].texture", str, dest ] UTF8String ]), q + shadowStart);
			//glUniform1f(glGetUniformLocation(program, [ [ NSString stringWithFormat:@"%@Textures[%u].size", str, dest ] UTF8String ]), texture.size);
			//glUniform1i(glGetUniformLocation(program, [ [ NSString stringWithFormat:@"%@Textures[%u].enabled", str, dest ] UTF8String ]), 1);
			int children[3] = { 0 };
			if (texture.type == MD_TEXTURE_TERRAIN_ALPHA)
			{
				unsigned long iCounter = 0;
				for (unsigned int y = 0, num = 0; y < [ mesh numberOfTextures ]; y++)
				{
					if ([ mesh textureAtIndex:y ].head == q)
					{
						children[iCounter++] = num;
						if (iCounter == 3)
							break;
					}
					if ([ mesh textureAtIndex:y ].type == MD_TEXTURE_TERRAIN_DIFFUSE)
						num++;
				}
			}
			glUniform1iv(program[MDUniformTextureLocation(dest, texture.type) + MD_PROGRAM0_TEXTURE_CHILDREN], 3, children);
			//glUniform1iv(glGetUniformLocation(program, [ [ NSString stringWithFormat:@"%@Textures[%u].children", str, dest ] UTF8String ]), 3, children);
		}
		if ([ mesh numberOfTextures ] == 0)
			glBindTexture(GL_TEXTURE_2D, 0);
		
		MDVector4 color = [ mesh color ];
		glVertexAttrib4f(1, color.x, color.y, color.z, color.w);
		glDrawElements(GL_TRIANGLES, [ mesh numberOfIndices ], GL_UNSIGNED_INT, NULL);
	}
	
	// Unbind
	//glBindVertexArray(0);
	
	//glActiveTexture(GL_TEXTURE0);
	//glBindTexture(GL_TEXTURE_2D, 0);
}

- (void) drawShadowVBO
{
	for (unsigned long z = 0; z < [ meshes count ]; z++)
	{
		MDMesh* mesh = meshes[z];
		glBindVertexArray([ mesh vao ]);
		glDrawElements(GL_TRIANGLES, [ mesh numberOfIndices ], GL_UNSIGNED_INT, NULL);
	}
	glBindVertexArray(0);
}

- (void) drawVBOColor:(MDVector4)color
{
	glVertexAttrib4f(1, color.x, color.y, color.z, color.w);
	for (unsigned long z = 0; z < [ meshes count ]; z++)
	{
		MDMesh* mesh = meshes[z];
		glBindVertexArray([ mesh vao ]);
		glBindTexture(GL_TEXTURE_2D, 0);
		glDrawElements(GL_TRIANGLES, [ mesh numberOfIndices ], GL_UNSIGNED_INT, NULL);
	}
	
	// Unbind
	glBindVertexArray(0);
}

- (void) updateVBOPoint:(unsigned long)point
{
	/*if (vboVerticies == 0 || vertices == NULL)
		return;
	
	const int step1[4] = { 0, 1, 1, 0 };
	const int step2[4] = { 0, 0, 1, 1 };
	
	// Update
	unsigned long z = point;
	MDPoint* p = [ points objectAtIndex:z ];
	
	vertices[z].position[0] = p.x;
	vertices[z].position[1] = p.y;
	vertices[z].position[2] = p.z;
	vertices[z].color[0] = p.red;
	vertices[z].color[1] = p.green;
	vertices[z].color[2] = p.blue;
	vertices[z].color[3] = p.alpha;
	vertices[z].normal[0] = p.normalX;
	vertices[z].normal[1] = p.normalY;
	vertices[z].normal[2] = p.normalZ;
	vertices[z].textureCoord[0] = step1[z % 4]; //p.textureCoordX;
	vertices[z].textureCoord[1] = step2[z % 4]; //p.textureCoordY;
	
	// Apply
	glBindBuffer(GL_ARRAY_BUFFER, vboVerticies);
	glBufferSubData(GL_ARRAY_BUFFER, point * sizeof(VBOVertex), sizeof(VBOVertex), &vertices[point]);*/
}

- (MDVector3) realMidPoint
{
	float left = 100000, right = -10000, top = 10000, bot = -10000, front = -10000, back = 10000;
	for (unsigned long z = 0; z < [ meshes count ]; z++)
	{
		NSArray* points = [ meshes[z] points ];
		for (int y = 0; y < [ points count ]; y++)
		{
			MDPoint* point = points[y];
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
	}
	MDVector3 p = { left + ((right - left) / 2), bot + ((top - bot) / 2), front + ((back - front) / 2) };
	return p;
}

- (MDVector3) midPoint
{
	float left = 100000, right = -10000, top = 10000, bot = -10000, front = -10000, back = 10000;
	for (unsigned long z = 0; z < [ meshes count ]; z++)
	{
		NSArray* points = [ meshes[z] points ];
		for (int y = 0; y < [ points count ]; y++)
		{
			MDPoint* point = points[y];
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
	}
	MDVector3 p = { left + ((right - left) / 2), bot + ((top - bot) / 2), front + ((back - front) / 2) };
	return p;
}

- (void) setMidPoint:(MDVector3)point
{
	MDVector3 diff = [ self midPoint ] - point;
	for (unsigned long z = 0; z < [ meshes count ]; z++)
	{
		NSArray* points = [ meshes[z] points ];
		for (unsigned long q = 0; q < [ points count ]; q++)
		{
			MDPoint* p = points[q];
			p.x -= diff.x;
			p.y -= diff.y;
			p.z -= diff.z;
		}
	}
	
	MDMatrix temp = MDMatrixIdentity();
	MDMatrixTranslate(&temp, -1 * diff);
	startMatrix = temp * startMatrix;
	
	startInverse = MDMatrixInverse(startMatrix);
}

- (void) setScale:(MDVector3)scale
{
	MDVector3 mid = [ self midPoint ];
	for (unsigned long z = 0; z < [ meshes count ]; z++)
	{
		NSArray* points = [ meshes[z] points ];
		for (unsigned long q = 0; q < [ points count ]; q++)
		{
			MDPoint* p = points[q];
			p.x = (p.x - mid.x) * scale.x + mid.x;
			p.y = (p.y - mid.y) * scale.y + mid.y;
			p.z = (p.z - mid.z) * scale.z + mid.z;
		}
	}
	
	// TODO: might have to flip mid and -1 * mid (I don't really know, they are always 0 in tests)
	MDMatrix temp = MDMatrixIdentity();
	MDMatrixTranslate(&temp, mid);
	MDMatrixScale(&temp, scale.x, scale.y, scale.z);
	MDMatrixTranslate(&temp, -1 * mid);
	startMatrix = temp * startMatrix;
	
	startInverse = MDMatrixInverse(startMatrix);
}

- (MDVector4) midColor
{
	MDVector4 color;
	memset(&color, 0, sizeof(color));
	
	float divide = 0;
	for (unsigned long y = 0; y < [ self numberOfMeshes ]; y++)
	{
		MDVector4 color2 = [ [ self meshAtIndex:y ] color ];
		divide++;
		color += color2;
	}
	if (divide != 0)
		color /= divide;
	
	return color;
}

- (void) setMidColor:(MDVector4)color
{
	for (unsigned long q = 0; q < [ self numberOfMeshes ]; q++)
		[ [ self meshAtIndex:q ] setColor:color ];
}

- (void) addMidColor:(MDVector4)color
{
	MDVector4 midColor = [ self midColor ];
	[ self setMidColor:color + midColor ];
}

- (void) addSpecularColor:(MDVector4)color
{
	specularColor += color;
}

- (void) addShininess:(float)shine
{
	shininess += shine;
}

- (void) addTranslateX:(float)value
{
	for (unsigned long y = 0; y < [ meshes count ]; y++)
	{
		NSArray* points = [ meshes[y] points ];
		for (int z = 0; z < [ points count ]; z++)
		{
			MDPoint* p1 = points[z];
			p1.x += value;
		}
	}
}

- (void) addTranslateY:(float)value
{
	for (unsigned long y = 0; y < [ meshes count ]; y++)
	{
		NSArray* points = [ meshes[y] points ];
		for (int z = 0; z < [ points count ]; z++)
		{
			MDPoint* p1 = points[z];
			p1.y += value;
		}
	}
}

- (void) addTranslateZ:(float)value
{
	for (unsigned long y = 0; y < [ meshes count ]; y++)
	{
		NSArray* points = [ meshes[y] points ];
		for (int z = 0; z < [ points count ]; z++)
		{
			MDPoint* p1 = points[z];
			p1.z += value;
		}
	}
}

- (void) addScaleX:(float)value
{
	/*if ([ points count ] != [ original count ])
	 {
	 [ original removeAllObjects ];
	 for (int z = 0; z < [ points count ]; z++)
	 {
	 MDPoint* p = [ [ MDPoint alloc ] initWithPoint:[ points objectAtIndex:z ] ];
	 [ original addObject:p ];
	 [ p release ];
	 }
	 }
	 lastX += value;
	 for (int z = 0; z < [ points count ]; z++)
	 {
	 MDPoint* p1 = [ points objectAtIndex:z ];
	 double realValue = (([ [ original objectAtIndex:z ] x ] - [ self originalMidPoint ].x) * lastX) + [ self originalMidPoint ].x;
	 // Check all other faces for same point
	 for (int q = 0; q < [ object numberOfFaces ]; q++)
	 {
	 if ([ object faceAtIndex:q ] == self)
	 continue;
	 for (int m = 0; m < [ [ object faceAtIndex:q ] numberOfPoints ]; m++)
	 {
	 MDPoint* p2 = [ [ [ object faceAtIndex:q ] original ] objectAtIndex:m ];
	 MDPoint* p3 = [ original objectAtIndex:z ];
	 MDPoint* p4 = [ [ object faceAtIndex:q ] pointAtIndex:m ];
	 if (p3.x == p2.x && p3.y == p2.y && p3.z == p2.z)
	 [ p4 addX:realValue - p4.x ];
	 }
	 }
	 p1.x = realValue;
	 }
	 
	 if ([ self displayList ] != (unsigned int)-1)
	 {
	 glDeleteLists([ self displayList ], 1);
	 [ self setDisplayList:-1 ];
	 }*/
}

- (void) addScaleY:(float)value
{
	/*if ([ points count ] != [ original count ])
	 {
	 [ original removeAllObjects ];
	 for (int z = 0; z < [ points count ]; z++)
	 {
	 MDPoint* p = [ [ MDPoint alloc ] initWithPoint:[ points objectAtIndex:z ] ];
	 [ original addObject:p ];
	 [ p release ];
	 }
	 }
	 lastY += value;
	 for (int z = 0; z < [ points count ]; z++)
	 {
	 MDPoint* p1 = [ points objectAtIndex:z ];
	 float realValue = ((p1.y - [ self originalMidPoint ].y) * lastY) + [ self originalMidPoint ].y;
	 // Check all other faces for same point
	 for (int q = 0; q < [ object numberOfFaces ]; q++)
	 {
	 if ([ object faceAtIndex:q ] == self)
	 continue;
	 for (int m = 0; m < [ [ object faceAtIndex:q ] numberOfPoints ]; m++)
	 {
	 MDPoint* p2 = [ [ [ object faceAtIndex:q ] original ] objectAtIndex:m ];
	 MDPoint* p3 = [ original objectAtIndex:z ];
	 MDPoint* p4 = [ [ object faceAtIndex:q ] pointAtIndex:m ];
	 if (p3.x == p2.x && p3.y == p2.y && p3.z == p2.z)
	 [ p4 addY:realValue - p4.y ];
	 }
	 }
	 p1.y = realValue;
	 }
	 
	 if ([ self displayList ] != (unsigned int)-1)
	 {
	 glDeleteLists([ self displayList ], 1);
	 [ self setDisplayList:-1 ];
	 }*/
}

- (void) addScaleZ:(float)value
{
	/*if ([ points count ] != [ original count ])
	 {
	 [ original removeAllObjects ];
	 for (int z = 0; z < [ points count ]; z++)
	 {
	 MDPoint* p = [ [ MDPoint alloc ] initWithPoint:[ points objectAtIndex:z ] ];
	 [ original addObject:p ];
	 [ p release ];
	 }
	 }
	 lastZ += value;
	 for (int z = 0; z < [ points count ]; z++)
	 {
	 MDPoint* p1 = [ points objectAtIndex:z ];
	 float realValue = ((p1.z - [ self originalMidPoint ].z) * lastZ) + [ self originalMidPoint ].z;
	 // Check all other faces for same point
	 for (int q = 0; q < [ object numberOfFaces ]; q++)
	 {
	 if ([ object faceAtIndex:q ] == self)
	 continue;
	 for (int m = 0; m < [ [ object faceAtIndex:q ] numberOfPoints ]; m++)
	 {
	 MDPoint* p2 = [ [ [ object faceAtIndex:q ] original ] objectAtIndex:m ];
	 MDPoint* p3 = [ original objectAtIndex:z ];
	 MDPoint* p4 = [ [ object faceAtIndex:q ] pointAtIndex:m ];
	 if (p3.x == p2.x && p3.y == p2.y && p3.z == p2.z)
	 [ p4 addZ:realValue - p4.z ];
	 }
	 }
	 p1.z = realValue;
	 }
	 
	 if ([ self displayList ] != (unsigned int)-1)
	 {
	 glDeleteLists([ self displayList ], 1);
	 [ self setDisplayList:-1 ];
	 }*/
}

- (void) setRotateX:(float)value
{
}

- (void) setRotateY:(float)value
{
}

- (void) setRotateZ:(float)value
{
}

@end

@implementation MDFace

@synthesize drawMode;

- (MDFace*) init
{
	if (self = [ super init ])
	{
		points = [ [ NSMutableArray alloc ] init ];
		indices = [ [ NSMutableArray alloc ] init ];
	}
	return self;
}

- (void) addPoint:(MDPoint*)p
{
	[ points addObject:p ];
}

- (NSMutableArray*) points
{
	return points;
}

- (NSMutableArray*) indices
{
	return indices;
}

- (void) addIndex:(unsigned int)index
{
	[ indices addObject:@(index) ];
}

@end

@implementation MDCamera

@synthesize midPoint;
@synthesize lookPoint;
@synthesize orientation;
@synthesize show;
@synthesize use;
@synthesize obj;
@synthesize selected;
@synthesize lookSelected;
@synthesize instance;
@synthesize lookObj;

+ (MDCamera*) cameraWithMDCamera: (MDCamera*)cam
{
	return [ [ MDCamera alloc ] initWithMDCamera:cam ];
}

- (MDCamera*) initWithMDCamera: (MDCamera*)cam
{
	if ((self = [ super init ]))
	{
		midPoint = [ cam midPoint ];
		lookPoint = [ cam lookPoint ];
		orientation = [ cam orientation ];
		show = [ cam show ];
		use = [ cam use ];
		if ([ cam name ])
			name = [ [ NSString alloc ] initWithString:[ cam name ] ];
		else
			name = [ [ NSString alloc ] init ];
		selected = [ cam selected ];
		lookSelected = [ cam lookSelected ];
		[ self setObj:[ [ MDObject alloc ] initWithObject:[ cam obj ] ] ];
		[ self setInstance:[ [ MDInstance alloc ] initWithInstance:[ cam instance ] ] ];
		[ self setLookObj:[ [ MDObject alloc ] initWithObject:[ cam lookObj ] ] ];
		[ lookObj setInstance:instance ];
	}
	return self;
}

- (MDCamera*) initWithMDLight: (MDLight*)light
{
	if ((self = [ super init ]))
	{
		midPoint = light.position;
		lookPoint = light.spotDirection;
		orientation = 0;
		show = light.show;
		use = FALSE;
		if (light.name)
			name = [ [ NSString alloc ] initWithString:light.name ];
		else
			name = [ [ NSString alloc ] init ];
		selected = light.selected;
	}
	return self;
}

- (MDCamera*) initWithMDSound:(MDSound*)sound
{
	if ((self = [ super init ]))
	{
		midPoint = sound.position;
		lookPoint = MDVector3Create(5, 0, 0);
		orientation = 0;
		show = sound.show;
		selected = sound.selected;
		use = FALSE;
		if (sound.name)
			name = [ [ NSString alloc ] initWithString:sound.name ];
		else
			name = [ [ NSString alloc ] init ];
	}
	return self;
}

- (MDCamera*) initWithMDParticleEngine:  (MDParticleEngine*)engine
{
	if ((self = [ super init ]))
	{
		midPoint = engine.position;
		lookPoint = MDVector3Create(5, 0, 0);
		orientation = 0;
		show = engine.show;
		selected = engine.selected;
		use = FALSE;
		if (engine.name)
			name = [ [ NSString alloc ] initWithString:engine.name ];
		else
			name = [ [ NSString alloc ] init ];
	}
	return self;
}

- (MDCamera*) initWithMDCurve:(MDCurve*)curve
{
	if (self = [ super init ])
	{
		name = [ [ NSString alloc ] initWithString:[ curve name ] ];
		selected = [ curve selected ];
		show = [ curve show ];
		midPoint = MDVector3Create(0, 5, 0);
		lookPoint = MDVector3Create(5, 5, 0);
		orientation = 0;
		use = FALSE;
	}
	return self;
}

- (instancetype) init
{
	if ((self = [ super init ]))
	{
		midPoint = MDVector3Create(0, 5, 0);
		lookPoint = MDVector3Create(5, 5, 0);
		orientation = 0;
		show = TRUE;
		use = TRUE;
		name = [ [ NSString alloc ] init ];
	}
	return self;
}

- (void) setName: (NSString*)nam
{
	name = [ [ NSString alloc ] initWithString:nam ];
}

- (NSString*) name
{
	return name;
}

- (void) setLookPoint:(MDVector3)lp
{
	if (lookObj)
	{
		/*[ lookObj setTranslateX:0 ];
		[ lookObj setTranslateY:0 ];
		[ lookObj setTranslateZ:0 ];*/
		[ lookObj setMidPoint:lp ];
	}
	lookPoint = lp;
}

- (void) setOnlyLookPoint:(MDVector3)lp
{
	lookPoint = lp;
}

@end

@implementation MDLight

@synthesize ambientColor;
@synthesize diffuseColor;
@synthesize specularColor;
@synthesize position;
@synthesize spotDirection;
@synthesize spotExp;
@synthesize spotCut;
@synthesize spotAngle;
@synthesize constAtt;
@synthesize linAtt;
@synthesize quadAtt;
@synthesize lightType;
@synthesize obj;
@synthesize selected;
@synthesize show;
@synthesize enableShadows;
@synthesize isStatic;

- (MDLight*) initWithMDLight:(MDLight*)light
{
	if ((self = [ super init ]))
	{
		position = light.position;
		ambientColor = light.ambientColor;
		diffuseColor = light.diffuseColor;
		specularColor = light.specularColor;
		spotDirection = light.spotDirection;
		spotExp = light.spotExp;
		spotCut = light.spotCut;
		spotAngle = light.spotAngle;
		constAtt = light.constAtt;
		linAtt = light.linAtt;
		quadAtt = light.quadAtt;
		lightType = light.lightType;
		selected = light.selected;
		[ self setObj:[ [ MDObject alloc ] initWithObject:light.obj ] ];
		if (light.name)
			name = [ [ NSString alloc ] initWithString:light.name ];
		else
			name = [ [ NSString alloc ] init ];
		show = light.show;
		enableShadows = light.enableShadows;
		isStatic = light.isStatic;
	}
	return self;
}

- (MDLight*) initWithMDCamera:(MDCamera*)cam
{
	if ((self = [ super init ]))
	{
		position = cam.midPoint;
		spotDirection = cam.lookPoint;
		ambientColor = MDVector4Create(0.5, 0.5, 0.5, 1);
		diffuseColor = MDVector4Create(1, 1, 1, 1);
		specularColor = MDVector4Create(0, 0, 0, 1);
		lightType = 0;
		constAtt = 1;
		spotAngle = 0.5;
		spotExp = 1;
		selected = cam.selected;
		if (cam.name)
			name = [ [ NSString alloc ] initWithString:cam.name ];
		else
			name = [ [ NSString alloc ] init ];
		show = cam.show;
		enableShadows = FALSE;
		isStatic = TRUE;
	}
	return self;
}

- (MDLight*) initWithMDSound:(MDSound *)sound
{
	if ((self = [ super init ]))
	{
		position = sound.position;
		ambientColor = MDVector4Create(0.5, 0.5, 0.5, 1);
		diffuseColor = MDVector4Create(1, 1, 1, 1);
		specularColor = MDVector4Create(0, 0, 0, 1);
		spotAngle = 0.5;
		spotCut = 0;
		lightType = 0;
		selected = sound.selected;
		show = sound.show;
		if (sound.name)
			name = [ [ NSString alloc ] initWithString:sound.name ];
		else
			name = [ [ NSString alloc ] init ];
		constAtt = 1;
		linAtt = [ sound linAtt ];
		quadAtt = [ sound quadAtt ];
		spotDirection = MDVector3Create(5, 5, 0);
		enableShadows = FALSE;
		isStatic = TRUE;
	}
	return self;
}

- (MDLight*) initWithMDParticleEngine:(MDParticleEngine*)engine
{
	if ((self = [ super init ]))
	{
		position = engine.position;
		ambientColor = engine.startColor;
		diffuseColor = engine.endColor;
		spotAngle = engine.particleSize;
		spotCut = engine.particleLife;
		lightType = 0;
		selected = engine.selected;
		show = engine.show;
		if (engine.name)
			name = [ [ NSString alloc ] initWithString:engine.name ];
		else
			name = [ [ NSString alloc ] init ];
		constAtt = 1;
		spotDirection = MDVector3Create(5, 5, 0);
		specularColor = MDVector4Create(0, 0, 0, 1);
		enableShadows = FALSE;
		isStatic = TRUE;
	}
	return self;
}

- (MDLight*) initWithMDCurve:(MDCurve*)curve
{
	if (self = [ super init ])
	{
		name = [ [ NSString alloc ] initWithString:[ curve name ] ];
		selected = [ curve selected ];
		show = [ curve show ];
		
		position = MDVector3Create(0, 5, 0);
		spotDirection = MDVector3Create(5, 5, 0);
		ambientColor = MDVector4Create(0.5, 0.5, 0.5, 1);
		diffuseColor = MDVector4Create(1, 1, 1, 1);
		specularColor = MDVector4Create(0, 0, 0, 1);
		lightType = 0;
		spotAngle = 0.5;
		spotExp = 1;
		constAtt = 1;
		enableShadows = FALSE;
		isStatic = TRUE;
	}
	return self;
}

- (MDLight*) init
{
	if ((self = [ super init ]))
	{
		position = MDVector3Create(0, 5, 0);
		spotDirection = MDVector3Create(5, 5, 0);
		ambientColor = MDVector4Create(0.5, 0.5, 0.5, 1);
		diffuseColor = MDVector4Create(1, 1, 1, 1);
		specularColor = MDVector4Create(0, 0, 0, 1);
		lightType = 0;
		spotAngle = 0.5;
		spotExp = 1;
		name = [ [ NSString alloc ] init ];
		show = TRUE;
		constAtt = 1;
		enableShadows = FALSE;
		isStatic = TRUE;
	}
	return self;
}

- (void) setName: (NSString*)nam
{
	name = [ [ NSString alloc ] initWithString:nam ];
}

- (NSString*) name
{
	return name;
}

- (void) lightData: (float*)data
{
	MDVector3 pos = position;
	MDVector3 realSpotDirection = spotDirection;
	if (lightType == MDDirectionalLight)
		pos = spotDirection - position;
	else
		realSpotDirection = spotDirection - position;
	
	float light[26] = {
		ambientColor.x, ambientColor.y, ambientColor.z, ambientColor.w,
		diffuseColor.x, diffuseColor.y, diffuseColor.z, diffuseColor.w,
		specularColor.x, specularColor.y, specularColor.z, specularColor.w,
		pos.x, pos.y, pos.z, 1.0,
		realSpotDirection.x, realSpotDirection.y, realSpotDirection.z,
		spotExp,
		spotCut,
		spotAngle,
		constAtt,
		linAtt,
		quadAtt,
		(float)enableShadows,
	};
	memcpy(data, light, sizeof(float) * 26);
}

@end

@implementation MDSound

@synthesize position;
@synthesize linAtt;
@synthesize quadAtt;
@synthesize minVolume;
@synthesize maxVolume;
@synthesize speed;
@synthesize flags;
@synthesize obj;
@synthesize selected;
@synthesize show;

- (MDSound*) initWithMDLight:(MDLight*)light
{
	if ((self = [ super init ]))
	{
		position = [ light position ];
		linAtt = [ light linAtt ];;
		quadAtt = [ light quadAtt ];
		minVolume = 0;
		maxVolume = 1;
		speed = 1;
		flags = MD_SOUND_PLAY_ON_LOAD;
		selected = [ light selected ];
		show = [ light show ];
		
		if ([ light name ])
			name = [ [ NSString alloc ] initWithString:[ light name ] ];
		else
			name = [ [ NSString alloc ] init ];
	}
	return self;
}

- (MDSound*) initWithMDCamera:(MDCamera*)cam
{
	if ((self = [ super init ]))
	{
		position = [ cam midPoint ];
		linAtt = 0;
		quadAtt = 0;
		minVolume = 0;
		maxVolume = 1;
		speed = 1;
		flags = MD_SOUND_PLAY_ON_LOAD;
		selected = [ cam selected ];
		show = [ cam show ];
		
		if ([ cam name ])
			name = [ [ NSString alloc ] initWithString:[ cam name ] ];
		else
			name = [ [ NSString alloc ] init ];
	}
	return self;
}

- (MDSound*) initWithMDSound:(MDSound*)sound
{
	if ((self = [ super init ]))
	{
		position = [ sound position ];
		linAtt = [ sound linAtt ];
		quadAtt = [ sound quadAtt ];
		minVolume = [ sound minVolume ];
		maxVolume = [ sound maxVolume ];
		speed = [ sound speed ];
		flags = [ sound flags ];
		selected = [ sound selected ];
		show = [ sound show ];
		
		if ([ sound name ])
			name = [ [ NSString alloc ] initWithString:[ sound name ] ];
		else
			name = [ [ NSString alloc ] init ];
	}
	return self;
}

- (MDSound*) initWithMDParticleEngine:(MDParticleEngine*)engine
{
	if ((self = [ super init ]))
	{
		position = [ engine position ];
		linAtt = 0;
		quadAtt = 0;
		minVolume = 0;
		maxVolume = 1;
		speed = 1;
		flags = MD_SOUND_PLAY_ON_LOAD;
		selected = [ engine selected ];
		show = [ engine show ];
		
		if ([ engine name ])
			name = [ [ NSString alloc ] initWithString:[ engine name ] ];
		else
			name = [ [ NSString alloc ] init ];
	}
	return self;
}

- (MDSound*) initWithMDCurve:(MDCurve*)curve
{
	if ((self = [ super init ]))
	{
		if ([ curve curvePoints ]->size() != 0)
			position = [ curve curvePoints  ]->at(0);
		else
			position = MDVector3Create(0, 0, 0);
		linAtt = 0;
		quadAtt = 0;
		minVolume = 0;
		maxVolume = 1;
		speed = 1;
		flags = MD_SOUND_PLAY_ON_LOAD;
		selected = [ curve selected ];
		show = [ curve show ];
		
		if ([ curve name ])
			name = [ [ NSString alloc ] initWithString:[ curve name ] ];
		else
			name = [ [ NSString alloc ] init ];
	}
	return self;
}

- (MDSound*) init
{
	if ((self = [ super init ]))
	{
		position = MDVector3Create(0, 0, 0);
		linAtt = 0;
		quadAtt = 0;
		minVolume = 0;
		maxVolume = 1;
		speed = 1;
		flags = MD_SOUND_PLAY_ON_LOAD;
		selected = NO;
		show = TRUE;
		
		name = [ [ NSString alloc ] init ];
	}
	return self;
}

- (void) setName: (NSString*)nam
{
	name = [ [ NSString alloc ] initWithString:nam ];
}

- (NSString*) name
{
	return name;
}

- (void) setFile: (NSString*)fil
{
	file = [ [ NSString alloc ] initWithString:fil ];
}

- (NSString*) file
{
	return file;
}

- (void) updateVolume:(MDVector3) pos
{
}

- (float) volume
{
	return 0;
}


@end

@implementation MDParticleEngine

@synthesize obj;
@synthesize selected;
@synthesize show;
@synthesize oneShot;
@synthesize emitRate;
@synthesize animationValue;
@synthesize animationRate;
@synthesize tail;
@synthesize flow;

- (MDParticleEngine*) initWithMDLight:(MDLight*)light
{
	if ((self = [ super init ]))
	{
		currentPos = light.position;
		startColor = light.ambientColor;
		endColor = light.diffuseColor;
		particleSize = light.spotAngle;
		particleLife = light.spotCut;
		if (particleLife == 0)
			particleLife = 60;
		selected = light.selected;
		show = light.show;
		shouldPart = -1;
		if (light.name)
			name = [ [ NSString alloc ] initWithString:light.name ];
		else
			name = [ [ NSString alloc ] init ];
		
		numberOfParticles = 1000;
		velocityType = 0;
		flow = TRUE;
		velocities = MDVector3Create(1, 1, 1);
		animationRate = 1 / 60.0;
		[ self reloadModel ];
		image = 0;
		lessThanFull = TRUE;
	}
	return self;
}

- (MDParticleEngine*) initWithMDCamera:(MDCamera*)cam
{
	if ((self = [ super init ]))
	{
		currentPos = cam.midPoint;
		startColor = MDVector4Create(1, 0.5, 0, 1);
		endColor = MDVector4Create(1, 0, 0, 0);
		particleSize = 0.2;
		particleLife = 60;
		numberOfParticles = 1000;
		velocityType = 0;
		flow = TRUE;
		velocities = MDVector3Create(1, 1, 1);
		[ self reloadModel ];
		image = 0;
		lessThanFull = TRUE;
		animationRate = 1 / 60.0;
		shouldPart = -1;
		
		show = cam.show;
		selected = cam.selected;
		if (cam.name)
			name = [ [ NSString alloc ] initWithString:cam.name ];
		else
			name = [ [ NSString alloc ] init ];
	}
	return self;
}

- (MDParticleEngine*) initWithMDSound:(MDSound *)sound
{
	if ((self = [ super init ]))
	{
		currentPos = sound.position;
		startColor = MDVector4Create(1, 0.5, 0, 1);
		endColor = MDVector4Create(1, 0, 0, 0);
		particleSize = 0.2;
		particleLife = 60;
		numberOfParticles = 1000;
		velocityType = 0;
		flow = TRUE;
		velocities = MDVector3Create(1, 1, 1);
		[ self reloadModel ];
		image = 0;
		lessThanFull = TRUE;
		animationRate = 1 / 60.0;
		shouldPart = -1;
		
		show = sound.show;
		selected = sound.selected;
		if (sound.name)
			name = [ [ NSString alloc ] initWithString:sound.name ];
		else
			name = [ [ NSString alloc ] init ];
	}
	return self;
}

- (MDParticleEngine*) initWithMDParticleEngine:(MDParticleEngine*)engine
{
	if (self = [ super init ])
	{
		currentPos = engine.position;
		startColor = engine.startColor;
		endColor = engine.endColor;
		particleSize = engine.particleSize;
		particleLife = engine.particleLife;
		numberOfParticles = engine.numberOfParticles;
		liveParticles = [ engine liveParticles ];
		velocityType = engine.velocityType;
		velocities = engine.velocities;
		//image = engine.image;
		//[ self reloadModel ];
		lessThanFull = [ engine lessThanFull ];
		animationValue = engine.animationValue;
		animationRate = engine.animationRate;
		oneShot = engine.oneShot;
		UpdateVelocity = [ engine updateVelocityFunction ];
		shouldPart = -1;
		
		flow = [ engine flow ];
		tail = [ engine tail ];
		
		// Create the data
		particles = (MDParticle*)malloc(numberOfParticles * sizeof(MDParticle));
		memcpy(particles, [ engine particles ], sizeof(MDParticle) * numberOfParticles);
		vertices = (MDParticleVertex*)malloc(numberOfParticles * sizeof(MDParticleVertex));
		memcpy(vertices, [ engine particles ], sizeof(MDParticleVertex) * numberOfParticles);
		
		// Create the VAO
		glGenVertexArrays(1, &vao[0]);
		glBindVertexArray(vao[0]);
		
		glGenBuffers(1, &vao[1]);
		glBindBuffer(GL_ARRAY_BUFFER, vao[1]);
		glBufferData(GL_ARRAY_BUFFER, sizeof(MDParticleVertex) * numberOfParticles, NULL, GL_STREAM_DRAW);
		
		// Vertices
		glEnableVertexAttribArray(0);
		glVertexAttribPointer(0, 3, GL_FLOAT, NO, sizeof(MDParticleVertex), NULL);
		// Colors
		glEnableVertexAttribArray(1);
		glVertexAttribPointer(1, 4, GL_FLOAT, NO, sizeof(MDParticleVertex), (char*)NULL + (3 * sizeof(float)));
		
		glBindVertexArray(0);
		glDisableVertexAttribArray(0);
		glDisableVertexAttribArray(1);
		
		show = engine.show;
		selected = engine.selected;
		if (engine.name)
			name = [ [ NSString alloc ] initWithString:engine.name ];
		else
			name = [ [ NSString alloc ] init ];
	}
	return self;
}

- (MDParticleEngine*) initWithMDCurve:(MDCurve*)curve
{
	if (self = [ super init ])
	{
		lessThanFull = TRUE;
		startColor = MDVector4Create(1, 0.5, 0, 1);
		endColor = MDVector4Create(1, 0, 0, 0);
		particleSize = 0.2;
		particleLife = 60;
		numberOfParticles = 1000;
		velocityType = 0;
		flow = TRUE;
		velocities = MDVector3Create(1, 1, 1);
		[ self reloadModel ];
		shouldPart = -1;
		animationRate = 1 / 60.0;
		
		name = [ [ NSString alloc ] initWithString:[ curve name ] ];
		selected = [ curve selected ];
		show = [ curve show ];
	}
	return self;
}

- (instancetype) init
{
	if (self = [ super init ])
	{
		lessThanFull = TRUE;
		startColor = MDVector4Create(1, 0.5, 0, 1);
		endColor = MDVector4Create(1, 0, 0, 0);
		particleSize = 0.2;
		particleLife = 60;
		numberOfParticles = 1000;
		velocityType = 0;
		flow = TRUE;
		velocities = MDVector3Create(1, 1, 1);
		[ self reloadModel ];
		shouldPart = -1;
		animationRate = 1 / 60.0;
		currentPos = MDVector3Create(0, 5, 0);
		//image = 0;
		
		show = TRUE;
		name = [ [ NSString alloc ] init ];
	}
	return self;
}

- (void) setPosition:(MDVector3)point
{
	for (unsigned long z = 0; z < liveParticles; z++)
	{
		MDParticle* p = &particles[z];
		p->startPos[0] -= currentPos.x, p->startPos[1] -= currentPos.y, p->startPos[2] -= currentPos.z;
		p->startPos[0] += point.x, p->startPos[1] += point.y, p->startPos[2] += point.z;
	}
	
	currentPos = point;
}

- (void) createParticle: (float&)angle atIndex:(unsigned long)z life:(float)thisLife
{
	BOOL realShould = FALSE;
	if (shouldPart == -1)
	{
		realShould = TRUE;
		/*if (velocityType == MD_EMITTER_POINT)
		{
		}
		else if (velocityType == MD_EMITTER_LINE)
		{
			for (unsigned int q = 1; q < emitRate; q++)
			{
				shouldPart = q;
				if (liveParticles + 1 >= numberOfParticles)
				{
					//liveParticles--;
					break;
				}
				[ self createParticle:angle atIndex:z + q life:thisLife ];
			}
		}
		else if (velocityType == MD_EMITTER_RECTANGLE)
		{
			for (unsigned int q = 1; q < emitRate * emitRate; q++)
			{
				shouldPart = q;
				if (liveParticles + 1 >= numberOfParticles)
				{
					//liveParticles--;
					break;
				}
				[ self createParticle:angle atIndex:z + q life:thisLife ];
			}
		}*/
		shouldPart = 0;
	}
	if (z >= numberOfParticles)
	{
		if (realShould)
			shouldPart = -1;
		return;
	}
	
	MDParticle* p = &particles[z];
	p->startPos[0] = currentPos.x, p->startPos[1] = currentPos.y, p->startPos[2] = currentPos.z;
	
	/*if (velocityType == MD_EMITTER_POINT)
	{
	}
	else if (velocityType == MD_EMITTER_LINE)
	{
		p->startPos[2] += ((shouldPart / (float)(emitRate)) - 0.5) * 2;
	}
	else if (velocityType == MD_EMITTER_RECTANGLE)
	{
		p->startPos[0] += ((shouldPart % emitRate) / (float)(emitRate) - 0.5) * 2;
		p->startPos[1] += (((float)(shouldPart / emitRate) / emitRate) - 0.5) * 2;
		
		
		// Circle - kinda
		//if (distanceB(NSMakePoint(p->startPos[0], p->startPos[1]), NSMakePoint(0, 0)) > 1)
		//{
		//	p->startPos[0] = 0;
		//	p->startPos[1] = 0;
		//}
	}*/
	
	p->color[0] = startColor.x, p->color[1] = startColor.y, p->color[2] = startColor.z, p->color[3] = startColor.w;
	p->life = thisLife;
	p->seed[0] = ((rand() % 10000) - 5000) / 5000.0;
	p->seed[1] = ((rand() % 10000) - 5000) / 5000.0;
	p->seed[2] = ((rand() % 10000) - 5000) / 5000.0;
	
	liveParticles++;
	
	if (ParticleCreated)
		ParticleCreated(p, self);
	
	if (liveParticles >= numberOfParticles)
		lessThanFull = FALSE;
	
	if (realShould)
		shouldPart = -1;
}

// Make a particlize function that converts mdobjects to particles so that we can blow stuff up :)

// position = f(xVal), aVal = animation
void UpdateVel(MDParticle* p, float& xVal, float& aVal, MDParticleEngine* engine, MDVector3& velocities, unsigned int& vel);
void UpdateVel(MDParticle* p, float& xVal, float& aVal, MDParticleEngine* engine, MDVector3& velocities, unsigned int& vel)
{
	// Move through space
	/*p->position[0] = cos(xVal * 2 * M_PI) * 5;
	p->position[1] = xVal * 6;
	p->position[2] = sin(xVal * 2 * M_PI) * 5;*/
	
	// Emitter moving
	/*p->position[0] = p->startPos[0];
	p->position[1] = p->startPos[1];
	p->position[2] = p->startPos[2] + (-pow(2 * xVal - 1, 2) + 1) * [ engine velocities ].z;*/
	
	if (vel == 0)
	{
		// Fire - flow, no tail
		p->position[0] = p->startPos[0] + p->seed[0] * sqrt(xVal) * velocities.x;
		p->position[1] = p->startPos[1] + xVal * velocities.y;
		p->position[2] = p->startPos[2] + p->seed[2] * sqrt(xVal) * velocities.z;
	}
	else if (vel == 1)
	{
		// Fire 2 / Smoke - flow, no tail
		p->position[0] = p->startPos[0] + p->seed[0] * sqrt(xVal) * velocities.x;
		p->position[1] = p->startPos[1] + (xVal + p->seed[1] + 1) * velocities.y / 2;
		p->position[2] = p->startPos[2] + p->seed[2] * sqrt(xVal) * velocities.z;
	}
	else if (vel == 2)
	{
		// Form Rectangle - no tail
		p->position[0] = p->startPos[0] + p->seed[0] * (1 - xVal) * 5 * velocities.x;
		p->position[1] = p->startPos[1] + p->seed[1] * (1 - xVal) * 5 * velocities.y;
		p->position[2] = p->startPos[2] + p->seed[2] * (1 - xVal) * 5 * velocities.z;
	}
	else if (vel == 3)
	{
		// Form Circle - no tail
		p->position[0] = p->startPos[0] + p->seed[0] * (1 - xVal) * 5 * velocities.x;
		p->position[1] = p->startPos[1] + p->seed[1] * (1 - xVal) * 5 * velocities.y;
		p->position[2] = p->startPos[2] + p->seed[2] * (1 - xVal) * 5 * velocities.z;
		// Makes circle vs rectangle
		float dist = MDVector3Distance(MDVector3Create(p->position[0], p->position[1], p->position[2]), MDVector3Create(p->startPos[0], p->startPos[1], p->startPos[2]));
		if (dist > (1 - xVal) * 5)
			p->color[3] = 0;
	}
	else if (vel == 4) // Makes weird things sometimes
	{
		// Grow
		p->position[0] = p->startPos[0] + ((rand() % 10000) - 5000) / 10000.0 * xVal * velocities.x;
		p->position[1] = p->startPos[1] + ((rand() % 10000) - 5000) / 10000.0 * xVal * velocities.y;
		p->position[2] = p->startPos[2] + ((rand() % 10000) - 5000) / 10000.0 * xVal * velocities.z;
	}
	else if (vel == 5)
	{
		// Shrink
		unsigned long num = [ engine numberOfParticles ];
		p->position[0] = p->startPos[0] + ((rand() % 10000) - 5000) / 100.0 * ((float)p->life / num) * velocities.x;
		p->position[1] = p->startPos[1] + ((rand() % 10000) - 5000) / 100.0 * ((float)p->life / num) * velocities.y;
		p->position[2] = p->startPos[2] + ((rand() % 10000) - 5000) / 100.0 * ((float)p->life / num) * velocities.z;
	}
	else if (vel == 6)
	{
		// Rectangle Explosion - no tail
		p->position[0] = p->startPos[0] + p->seed[0] * xVal * 5 * velocities.x;
		p->position[1] = p->startPos[1] + p->seed[1] * xVal * 5 * velocities.y;
		p->position[2] = p->startPos[2] + p->seed[2] * xVal * 5 * velocities.z;
	}
	else if (vel == 7)
	{
		// Sphere Explosion - no tail
		p->position[0] = p->startPos[0] + p->seed[0] * xVal * 5 * velocities.x;
		p->position[1] = p->startPos[1] + p->seed[1] * xVal * 5 * velocities.y;
		p->position[2] = p->startPos[2] + p->seed[2] * xVal * 5 * velocities.z;
		float dist = MDVector3Distance(MDVector3Create(p->position[0], p->position[1], p->position[2]), MDVector3Create(p->startPos[0], p->startPos[1], p->startPos[2]));
		if (dist > xVal * 5)
			p->color[3] = 0;
	}
	else if (vel == 8)
	{
		// Dissolve
		p->position[0] = p->startPos[0] + p->seed[0] * 2 * velocities.x;
		p->position[1] = p->startPos[1] + p->seed[1] * 2 * velocities.y;
		p->position[2] = p->startPos[2] + p->seed[2] * 2 * velocities.z;
		// Makes circle vs rectangle
		float dist = MDVector3Distance(MDVector3Create(p->position[0], p->position[1], p->position[2]), MDVector3Create(p->startPos[0], p->startPos[1], p->startPos[2]));
		if (dist > 2)
			p->color[3] = 0;
	}
	else if (vel == 9)
	{
		// Fountain - flow, no tail
		p->position[0] = p->startPos[0] + p->seed[0] * xVal * velocities.x;
		p->position[1] = p->startPos[1] + (-pow(1.5 * xVal - 1, 2) + 1) * velocities.y;	// The 1.5 controls how much it comes back down from none (1) to all (2)
		p->position[2] = p->startPos[2] + p->seed[2] * xVal * velocities.z;
	}
	else if (vel == 10)
	{
		// Sin wave
		p->position[0] = p->startPos[0] + (xVal - 0.5) * 5 * velocities.x;
		p->position[1] = p->startPos[1] + sin(xVal * 2 * M_PI) / 3 * 5 * velocities.y;
		p->position[2] = p->startPos[2];
	}
	/*else if (vel == 11)
	{
		// Circle glow thing
		if (p->seed[2] < 50)
		{
			p->seed[0] = sin(xVal * 2 * M_PI);
			p->seed[1] = cos(xVal * 2 * M_PI);
			p->seed[2] = 51;
		}
		
		p->position[0] = p->startPos[0] + p->seed[0] * xVal * 5 * velocities.x;
		p->position[1] = p->startPos[1] + p->seed[1] * xVal * 5 * velocities.y;
		p->position[2] = p->startPos[2];
	}*/
	else
	{
		p->position[0] = p->startPos[0];
		p->position[1] = p->startPos[1];
		p->position[2] = p->startPos[2];
	}
}


- (void) draw:(unsigned int*)program duration:(double)frameDuration desired:(unsigned int)desiredFPS
{
	if (oneShotDone)
		[ self reloadModel ];	// Should be return;
	
	// VBO
	if (vertices == NULL)
		[ self reloadModel ];
	
	//glEnable(GL_POINT_SPRITE);
	if (image)
	{
		//glEnable(GL_POINT_SPRITE);
		//glDisable(GL_POINT_SMOOTH);
		glBindTexture(GL_TEXTURE_2D, image);
		//glTexEnvi(GL_POINT_SPRITE, GL_COORD_REPLACE, GL_TRUE);
	}
	
	// Temps
	emitRate = 1;
	
	// if tail
	{
		animationRate = 1.0 / 3.0 * frameDuration / 1000.0;	// 3 Seconds
	}
	// else
	/*{
		animationRate = 1.0 / particleLife;//1 / 3.0 / 60.0;
	}*/
	
	animationValue += animationRate;	// Different tweenings?
	
	if (liveParticles < numberOfParticles)
		[ self createParticle:particleAngle atIndex:liveParticles life:particleLife ];
		
	double newLife = frameDuration * 60.0 / 1000.0;
	while (newLife > numberOfParticles)
		newLife -= numberOfParticles;
	glDepthMask(GL_FALSE);
	
	unsigned long temp1 = numberOfParticles + particleLife - (numberOfParticles % particleLife);
	float temp2 = numberOfParticles / (float)particleLife / (float)particleLife;
	float temp3 = (float)particleLife;
	MDVector4 diffColor = startColor - endColor;
	int times = 0;
	
	for (long z = 0; z < liveParticles; z++)
	{
		MDParticle* p = &particles[z];
		
		float value = 0;
		if (flow)
			value = ((unsigned long)(temp1 - p->life) % particleLife) / temp3 + (unsigned int)(z / particleLife) / temp2;
		else
		{
			//if (velocityType == MD_EMITTER_POINT)
			{
				value = animationValue + (z / (float)(liveParticles - 1)) * particleLife / liveParticles;
			}
			/*else if (velocityType == MD_EMITTER_LINE)
			{
				value = animationValue + (z / (float)(liveParticles - 1)) * particleLife / liveParticles;
			}
			else if (velocityType == MD_EMITTER_RECTANGLE)
			{
				value = animationValue + ((unsigned long)((z / (float)emitRate / (float)emitRate)) / (float)(liveParticles - 1)) * ((float)particleLife * emitRate * emitRate) / liveParticles;
			}*/
		}
	
		while (value > 1)
			value -= 1;
		
		float val = 0;
		if (tail)
			val = (float)z / (liveParticles - 1);
		else
			val = 1 - value;
		
		p->color[0] = endColor.x + (diffColor.x * val);
		p->color[1] = endColor.y + (diffColor.y * val);
		p->color[2] = endColor.z + (diffColor.z * val);
		p->color[3] = endColor.w + (diffColor.w * val);
		
		if (UpdateVelocity)
			UpdateVelocity(p, value, animationValue, self, velocities, velocityType);
		
		p->life -= newLife;
		if (p->life <= 0)
		{
			//if (velocityType == MD_EMITTER_POINT)
			{
				liveParticles -= 1;
			}
			/*else if (velocityType == MD_EMITTER_LINE)
			{
				liveParticles -= emitRate;
			}
			else if (velocityType == MD_EMITTER_RECTANGLE)
			{
				liveParticles -= emitRate * emitRate;
			}*/
			if (liveParticles - 1 < numberOfParticles)
			{
				[ self createParticle:particleAngle atIndex:z life:numberOfParticles + p->life ];
				times++;
				z--;
			}
			continue;
		}
				
		vertices[z].position[0] = p->position[0];
		vertices[z].position[1] = p->position[1];
		vertices[z].position[2] = p->position[2];
		vertices[z].color[0] = p->color[0];
		vertices[z].color[1] = p->color[1];
		vertices[z].color[2] = p->color[2];
		vertices[z].color[3] = p->color[3];
	}
	
	
	if (animationValue >= 1.0)
	{
		animationValue -= 1.0;
		if (oneShot)
			oneShotDone = TRUE;
	}
	
	// Copy data
	glBindBuffer(GL_ARRAY_BUFFER, vao[1]);
	glBufferData(GL_ARRAY_BUFFER, sizeof(MDParticleVertex) * numberOfParticles, NULL, GL_STREAM_DRAW);
	glBufferSubData(GL_ARRAY_BUFFER, 0, liveParticles * sizeof(MDParticleVertex), vertices);
	
	glUniform1f(program[MD_PROGRAM2_POINTSIZE], particleSize);
	
	glEnable(GL_VERTEX_PROGRAM_POINT_SIZE);
	/*GLfloat psr[2];
    GLfloat pda[3] = { 0.0f, 0.0f, 1 }; // defaults are (1.0, 0.0, 0.0)*/
	
	//glTexEnvi (GL_POINT_SPRITE, GL_COORD_REPLACE, GL_TRUE);
	//glEnable (GL_POINT_SPRITE);
	
    glPointSize(particleSize);
	glBindVertexArray(vao[0]);
	glDrawArrays(GL_POINTS, 0, (unsigned int)numberOfParticles);
	glBindVertexArray(0);
	glDisable(GL_VERTEX_PROGRAM_POINT_SIZE);
	
	//NSLog(@"%lu", liveParticles);
	
	// Disable
	glDepthMask(GL_TRUE);
	if (image)
	{
		//glDisable(GL_POINT_SPRITE);
		glBindTexture(GL_TEXTURE_2D, 0);
		//glEnable(GL_POINT_SMOOTH);
		//glTexEnvi(GL_POINT_SPRITE, GL_COORD_REPLACE, GL_FALSE);
	}
}

- (MDVector3) position
{
	return currentPos;
}

- (void) setStartColor:(MDVector4)start
{
	startColor = start;
}

- (MDVector4) startColor
{
	return startColor;
}

- (void) setEndColor:(MDVector4)end
{
	endColor = end;
}

- (MDVector4) endColor
{
	return endColor;
}

- (void) setNumberOfParticles:(unsigned long)num
{
	numberOfParticles = num;
	[ self reloadModel ];
}

- (unsigned long) numberOfParticles
{
	return numberOfParticles;
}

- (void) setParticleSize:(float)size
{
	particleSize = size;
}

- (float) particleSize
{
	return particleSize;
}

- (void) setParticleLife:(unsigned long)life
{
	particleLife = life;
	if (particleLife < 1)
		particleLife = 1;
}

- (unsigned long) particleLife
{
	return particleLife;
}

- (void) setVelocityType:(unsigned int)type
{
	velocityType = type;
	
	if (velocityType == 0)
	{
		tail = FALSE;
		flow = TRUE;
	}
	else if (velocityType == 1)
	{
		tail = FALSE;
		flow = TRUE;
	}
	else if (velocityType == 2)
	{
		tail = FALSE;
		flow = FALSE;
	}
	else if (velocityType == 3)
	{
		tail = FALSE;
		flow = FALSE;
	}
	else if (velocityType == 4)
	{
		tail = FALSE;
		flow = FALSE;
	}
	else if (velocityType == 5)
	{
		tail = FALSE;
		flow = FALSE;
	}
	else if (velocityType == 6)
	{
		tail = FALSE;
		flow = FALSE;
	}
	else if (velocityType == 7)
	{
		tail = FALSE;
		flow = FALSE;
	}
	else if (velocityType == 8)
	{
		tail = FALSE;
		flow = FALSE;
	}
	else if (velocityType == 9)
	{
		tail = FALSE;
		flow = TRUE;
	}
	else if (velocityType == 10)
	{
		tail = TRUE;
		flow = FALSE;
	}
	/*else if (velocityType == 11)
	{
		tail = FALSE;
		flow = TRUE;
	}*/
	else
	{
		tail = FALSE;
		flow = FALSE;
	}
	
	[ self reloadModel ];
}

- (unsigned int) velocityType
{
	return velocityType;
}

- (void) setVelocities:(MDVector3)vel
{
	velocities = vel;
}

- (MDVector3) velocities
{
	return velocities;
}

- (void) reloadModel
{
	/*if (imageString)
	{
		[ imageString release ];
	}
		imageString = [ [ NSString alloc ] initWithString:@"/Users/Neil/Downloads/particle.png" ];*/
	
	[ self setUpdateVelocityFunction:UpdateVel ];
	if (image)
	{
		ReleaseImage(&image);
		image = 0;
	}
	if (imageString)
		LoadImage([ imageString UTF8String ], &image, 0);
	
	if (vertices)
	{
		free(vertices);
		vertices = NULL;
	}
	if (particles)
	{
		free(particles);
		particles = NULL;
	}
	
	liveParticles = 0;
	shouldPart = -1;
	emitRate = 1;
	oneShotDone = FALSE;
	
	// Create the data
	particles = (MDParticle*)malloc(numberOfParticles * sizeof(MDParticle));
	memset(particles, 0, sizeof(MDParticle) * numberOfParticles);
	vertices = (MDParticleVertex*)malloc(numberOfParticles * sizeof(MDParticleVertex));
	memset(vertices, 0, sizeof(MDParticleVertex) * numberOfParticles);
	
	// Fill it up
	unsigned long add = 0;
	while (liveParticles < numberOfParticles)
	{
		[ self createParticle:particleAngle atIndex:liveParticles life:particleLife + add ];
		add++;
	}
	if (!flow)
	{
		for (unsigned long z = 0; z < numberOfParticles; z++)
		{
			MDParticle* p = &particles[z];
			p->life -= add;
			while (p->life <= 0)
				p->life += particleLife;
		}
		//oneShot = TRUE;
		lessThanFull = FALSE;
	}
	
	// Create the VBO
	/*glGenBuffers(1, &vboVerticies);
	glBindBuffer(GL_ARRAY_BUFFER, vboVerticies);
	glBufferData(GL_ARRAY_BUFFER, sizeof(ParticleVertex) * numberOfParticles, NULL, GL_STREAM_DRAW);*/
	
	if (vao[0])
	{
		if (glIsVertexArray(vao[0]))
			glDeleteVertexArrays(1, &vao[0]);
	}
	if (vao[1])
	{
		if (glIsBuffer(vao[1]))
			glDeleteBuffers(1, &vao[1]);
	}
	
	glGenVertexArrays(1, &vao[0]);
	glBindVertexArray(vao[0]);
	
	glGenBuffers(1, &vao[1]);
	glBindBuffer(GL_ARRAY_BUFFER, vao[1]);
	glBufferData(GL_ARRAY_BUFFER, sizeof(MDParticleVertex) * numberOfParticles, NULL, GL_STREAM_DRAW);
	
	// Vertices
	glEnableVertexAttribArray(0);
	glVertexAttribPointer(0, 3, GL_FLOAT, NO, sizeof(MDParticleVertex), NULL);
	// Colors
	glEnableVertexAttribArray(1);
	glVertexAttribPointer(1, 4, GL_FLOAT, NO, sizeof(MDParticleVertex), (char*)NULL + (3 * sizeof(float)));
	
	glBindVertexArray(0);
	glDisableVertexAttribArray(0);
	glDisableVertexAttribArray(1);
}

- (void) setParticleCreatedFunction:(void (*)(MDParticle*, MDParticleEngine*))func
{
	ParticleCreated = func;
}

- (void (*)(MDParticle*, MDParticleEngine*)) particleCreatedFunction
{
	return ParticleCreated;
}

- (void) setUpdateVelocityFunction:(void (*)(MDParticle*, float&, float&, MDParticleEngine*, MDVector3&, unsigned int&))func
{
	UpdateVelocity = func;
}

- (void (*)(MDParticle*, float&, float&, MDParticleEngine*, MDVector3&, unsigned int&)) updateVelocityFunction
{
	return UpdateVelocity;
}

- (void) setImage:(NSString*)img
{
	imageString = [ [ NSString alloc ] initWithString:img ];
	[ self reloadModel ];
}

- (NSString*) image
{
	return imageString;
}

- (void) setName: (NSString*)nam
{
	name = [ [ NSString alloc ] initWithString:nam ];
}

- (NSString*) name
{
	return name;
}

- (MDParticleVertex*) vertices
{
	return vertices;
}

- (MDParticle*) particles
{
	return particles;
}

- (unsigned long) liveParticles
{
	return liveParticles;
}

- (BOOL) lessThanFull
{
	return lessThanFull;
}

- (void) dealloc
{
	if (particles)
	{
		free(particles);
		particles = NULL;
	}
	if (image != 0)
	{
		ReleaseImage(&image);
		image = 0;
	}
	if (vao[0])
	{
		if (glIsVertexArray(vao[0]))
			glDeleteVertexArrays(1, &vao[0]);
		vao[0] = 0;
	}
	if (vao[1])
	{
		if (glIsBuffer(vao[1]))
			glDeleteBuffers(1, &vao[1]);
		vao[1] = 0;
	}
	if (vertices)
	{
		free(vertices);
		vertices = NULL;
	}
}

@end

@implementation MDCurve

@synthesize obj;
@synthesize selected;
@synthesize show;

- (MDCurve*) initWithMDLight:(MDLight*)light
{
	if (self = [ super init ])
	{
		if ([ light name ])
			name = [ [ NSString alloc ] initWithString:[ light name ] ];
		else
			name = [ [ NSString alloc ] init ];
		selected = [ light selected ];
		show = [ light show ];
	}
	return self;
}

- (MDCurve*) initWithMDCamera:(MDCamera*)cam
{
	if (self = [ super init ])
	{
		if ([ cam name ])
			name = [ [ NSString alloc ] initWithString:[ cam name ] ];
		else
			name = [ [ NSString alloc ] init ];
		selected = [ cam selected ];
		show = [ cam show ];
	}
	return self;
}

- (MDCurve*) initWithMDSound:(MDSound *)sound
{
	if (self = [ super init ])
	{
		if ([ sound name ])
			name = [ [ NSString alloc ] initWithString:[ sound name ] ];
		else
			name = [ [ NSString alloc ] init ];
		selected = [ sound selected ];
		show = [ sound show ];
	}
	return self;
}

- (MDCurve*) initWithMDParticleEngine:(MDParticleEngine*)engine
{
	if (self = [ super init ])
	{
		if ([ engine name ])
			name = [ [ NSString alloc ] initWithString:[ engine name ] ];
		else
			name = [ [ NSString alloc ] init ];
		selected = [ engine selected ];
		show = [ engine show ];
	}
	return self;
}

- (MDCurve*) initWithMDCurve:(MDCurve*)curve
{
	if (self = [ super init ])
	{
		points = *[ curve curvePoints ];
		if ([ curve name ])
			name = [ [ NSString alloc ] initWithString:[ curve name ] ];
		else
			name = [ [ NSString alloc ] init ];
		selected = [ curve selected ];
		show = [ curve show ];
	}
	return self;
}

- (MDCurve*) init
{
	if (self = [ super init ])
	{
		name = [ [ NSString alloc ] init ];
		show = TRUE;
	}
	return self;
}

- (void) setName: (NSString*)nam
{
	name = [ [ NSString alloc ] initWithString:nam ];
}

- (NSString*) name
{
	return name;
}

- (void) addPoint:(MDVector3)point
{
	points.push_back(point);
}

- (void) removeAllPoints
{
	points.clear();
}

- (void) draw
{
	if (points.size() == 0)
		return;
	
	unsigned int vao[2];
	
	glGenVertexArrays(1, &vao[0]);
	glBindVertexArray(vao[0]);
	
	float verts[51 * 3];
	for (unsigned long z = 0; z <= 50; z++)
	{
		MDVector3 p = [ self interpolate:(z / 50.0) ];
		verts[z * 3 + 0] = p.x;
		verts[z * 3 + 1] = p.y;
		verts[z * 3 + 2] = p.z;
	}
	
	glGenBuffers(1, &vao[1]);
	glBindBuffer(GL_ARRAY_BUFFER, vao[1]);
	glBufferData(GL_ARRAY_BUFFER, 51 * 3 * sizeof(float), verts, GL_STREAM_DRAW);
	glVertexAttribPointer(0, 3, GL_FLOAT, NO, 0, NULL);
	glEnableVertexAttribArray(0);
	glVertexAttrib4f(1, 1, 1, 1, 1);
	glDrawArrays(GL_LINE_STRIP, 0, 51);
	
	glDeleteBuffers(1, &vao[1]);
	glDeleteVertexArrays(1, &vao[0]);
	
	float pts[points.size() * 3];
	for (unsigned long z = 0; z < points.size(); z++)
	{
		pts[(z * 3) + 0] = points[z].x;
		pts[(z * 3) + 1] = points[z].y;
		pts[(z * 3) + 2] = points[z].z;
	}
	
	glGenVertexArrays(1, &vao[0]);
	
	glGenBuffers(1, &vao[1]);
	glBindBuffer(GL_ARRAY_BUFFER, vao[1]);
	glBufferData(GL_ARRAY_BUFFER, points.size() * 3 * sizeof(float), pts, GL_STREAM_DRAW);
	glVertexAttribPointer(0, 3, GL_FLOAT, NO, 0, NULL);
	glEnableVertexAttribArray(0);
	
	glVertexAttrib4f(1, 1, 1, 0, 1);
	glPointSize(8);
	glDrawArrays(GL_POINTS, 0, (unsigned int)points.size());
	glPointSize(1);
	
	glBindBuffer(GL_ARRAY_BUFFER, 0);
	glBindVertexArray(0);
	
	glDeleteBuffers(1, &vao[1]);
	glDeleteVertexArrays(1, &vao[0]);
	
	/*glColor4d(1, 0, 0, 1);
	for (float z = 0; z <= 1; z += 1 / 10.0)
	{
		MDVector3 p = [ self interlopate:z ];
		MDVector3 tan = MDVector3Normalize([ self tangent:z ]);
		glBegin(GL_LINES);
		{
			//glVertex3d(p.x, p.y, p.z);
			glVertex3d(p.x - tan.x, p.y - tan.y, p.z - tan.z);
			glVertex3d(p.x + tan.x, p.y + tan.y, p.z + tan.z);
		}
		glEnd();
	}*/
}

- (void) setPoints:(std::vector<MDVector3>)p
{
	points = p;
}

- (std::vector<MDVector3>*) curvePoints
{
	return &points;
}

- (MDVector3) interpolate:(float)time
{
	if (points.size() == 4)
	{
		// Bezier
		float s = 1 - time;
		MDVector3 A = points[0], B = points[1], C = points[2], D = points[3];
		
		MDVector3 AB = A * s + B * time;
		MDVector3 BC = B * s + C * time;
		MDVector3 CD = C * s + D * time;
		MDVector3 ABC = AB * s + CD * time;
		MDVector3 BCD = BC * s + CD * time;
		return ABC * s + BCD * time;
	}
	else if (points.size() == 3)
	{
		// Circle
		MDVector3 p1 = points[0];	// Center
		MDVector3 p2 = points[1];
		MDVector3 p3 = points[2];
		// triangle "edges"
		const MDVector3 t = p2-p1;
		const MDVector3 u = p3-p1;
		const MDVector3 v = p3-p2;
		
		// triangle normal
		const MDVector3 w = MDVector3CrossProduct(t, u);
		const double wsl = MDVector3Magnitude(w) * MDVector3Magnitude(w);
		// helpers
		const double iwsl2 = 1.0 / (2.0 * wsl);
		const double tt = MDVector3DotProduct(t, t);
		const double uu = MDVector3DotProduct(u, u);
		
		// result circle
		MDVector3 circCenter = p1 + (u * tt * MDVector3DotProduct(u, v) - t * uu * MDVector3DotProduct(t, v)) * iwsl2;
		MDVector3 circAxis   = w / sqrt(wsl);
					
		return MDVector3Rotate(circCenter, circAxis, 2 * M_PI * time);
	}
	else if (points.size() == 2)
	{
		MDVector3 p1 = points[0];
		MDVector3 p2 = points[1];
		return p1 + ((p2 - p1) * time);
	}
	
	return MDVector3Create(0, 0, 0);
}

- (MDVector3) tangent:(float)time
{
	return ([ self interpolate:time ] - [ self interpolate:time - 0.01 ]);
}

- (MDVector3) normal:(float)time
{	
	//MDVector3 p1 = [ self interlopate:0 ], p2 = [ self interlopate:1.0 / 3.0 ], p3 = [ self interlopate:2.0 / 3.0 ];
	//return MDVector3CrossProduct(p3 - p2, p2 - p1);
	
	MDVector3 p1 = [ self interpolate:time - 0.01 ], p2 = [ self interpolate:time ], p3 = [ self interpolate:time + 0.01 ];
	MDVector3 v1 = MDVector3CrossProduct(p3 - p2, p2 - p1), v2 = [ self tangent:time ];
	MDVector3 ret = MDVector3CrossProduct(v1, v2);
	if (ret.y < 0)
		ret = MDVector3CrossProduct(v2, v1);
	return ret;
}

- (float) length:(unsigned int)slices
{
	float total = 0;
	MDVector3 p1 = [ self interpolate:0 ];
	for (float z = 1.0 / slices; z <= 1; z += 1.0 / slices)
	{
		MDVector3 p2 = [ self interpolate:z ];
		total += MDVector3Distance(p1, p2);
		p1 = p2;
	}
	return total;
}

@end

@implementation MDSelection

- (instancetype) init
{
	if ((self = [ super init ]))
	{
		data = [ [ NSMutableDictionary alloc ] init ];
	}
	return self;
}

- (instancetype) initWithSelection: (MDSelection*)sel
{
	if ((self = [ super init ]))
	{
		data = [ [ NSMutableDictionary alloc ] initWithDictionary:[ sel completeData ] ];
	}
	return self;
}

- (void) addObject: (MDObject*) obj
{
	NSMutableDictionary* mutDict = [ [ NSMutableDictionary alloc ] initWithObjectsAndKeys:obj, @"Object", nil ];
	NSDictionary* dict = @{@([ self count ]): mutDict};
	[ data addEntriesFromDictionary:dict ];
}

- (void) replaceObjectAtIndex: (unsigned long)index withObject:(MDObject*)obj
{
	if (index >= [ self count ])
		return;
	NSMutableDictionary* mutDict = [ [ NSMutableDictionary alloc ] initWithObjectsAndKeys:obj, @"Object", nil ];
	data[@(index)] = mutDict;
}

- (void) addVertex:(MDPoint*)point fromObject:(MDObject*)obj
{
	NSMutableDictionary* mutDict = [ [ NSMutableDictionary alloc ] initWithObjectsAndKeys:obj, @"Object", @([ [ [ obj instance ] points ] indexOfObject:point ]), @"Point", nil ];
	NSDictionary* dict = @{@([ self count ]): mutDict};
	[ data addEntriesFromDictionary:dict ];
}

- (void) replaceObjectAtIndex: (unsigned long)index withObject:(MDObject*)obj withVertex:(MDPoint*)point
{
	if (index >= [ self count ])
		return;
	NSMutableDictionary* mutDict = [ [ NSMutableDictionary alloc ] initWithObjectsAndKeys:obj, @"Object", @([ [ [ obj instance ] points ] indexOfObject:point ]), @"Point", nil ];
	data[@(index)] = mutDict;
}

- (NSDictionary*) selectedValueAtIndex: (unsigned long)index
{
	if (index >= [ self count ])
		return nil;
	return data[@(index)];
}

- (BOOL) containsObject: (MDObject*)obj withPoints:(NSArray*)points
{
	if (points && ([ points count ] > 2 || [ points count ] == 0))
		return NO;
	
	for (int z = 0; z < [ self count ]; z++)
	{
		NSDictionary* dict = [ self selectedValueAtIndex:z ];
		if (dict[@"Object"] == obj)
		{
			if (!points)
				return YES;
			if ([ points count ] == 1)
			{
				if ([ dict[@"Point"] unsignedLongValue ] == [ [ [ obj instance ] points ] indexOfObject:points[0] ])
					return YES;
			}
			// Need to change to indices rather than pointers
			/*else
			{
				if ([ [ dict objectForKey:@"Edge" ] objectAtIndex:0 ] == [ points objectAtIndex:0 ] && [ [ dict objectForKey:@"Edge" ] objectAtIndex:1 ] == [ points objectAtIndex:1 ])
					return YES;
			}*/
		}
	}
	return NO;
}

- (unsigned long) count
{
	return [ [ data allKeys ] count ];
}

- (void) clear
{
	[ data removeAllObjects ];
}

- (void) removeValue: (MDObject*)obj withPoints:(NSArray*)points
{
	if (points && ([ points count ] > 2 || [ points count ] == 0))
		return;
	
	for (int z = 0; z < [ self count ]; z++)
	{
		NSDictionary* dict = [ self selectedValueAtIndex:z ];
		if (dict[@"Object"] == obj)
		{
			if (!points)
			{
				[ self removeValueAtIndex:z ];
				break;
			}
			
			if ([ points count ] == 1)
			{
				if ([ dict[@"Point"] unsignedLongValue ] == [ [ [ obj instance ] points ] indexOfObject:points[0] ])
				{
					[ self removeValueAtIndex:z ];
					break;
				}
			}
			// Need to change to indices rather than pointers
			/*else
			{
				if ([ [ dict objectForKey:@"Edge" ] objectAtIndex:0 ] == [ points objectAtIndex:0 ] && [ [ dict objectForKey:@"Edge" ] objectAtIndex:1 ] == [ points objectAtIndex:1 ])
				{
					[ self removeValueAtIndex:z ];
					break;
				}
			}*/
		}
	}
}

- (void) removeValueAtIndex:(unsigned long) index
{
	if (index >= [ self count ])
		return;
	[ data removeObjectForKey:@(index) ];
	for (unsigned long z = index + 1; z < [ self count ] + 1; z++)
	{
		id backup = data[@(z)];
		[ data addEntriesFromDictionary:@{@(z - 1): backup} ];
		[ data removeObjectForKey:@(z) ];
	}
}

- (NSDictionary*) completeData
{
	return data;
}

- (id) fullValueAtIndex: (unsigned long) index
{
	NSDictionary* dict = [ self selectedValueAtIndex:index ];
	if (!dict)
		return nil;
	if (dict[@"Point"])
		return [ [ dict[@"Object"] instance ] pointAtIndex:[ dict[@"Point"] unsignedLongValue ] ];
	//if ([ dict objectForKey:@"Edge" ])
	//	return [ dict objectForKey:@"Edge" ];
	if (dict[@"Object"])
		return dict[@"Object"];
	return nil;
}

- (unsigned long) indexOfObject:(MDObject*)obj withPoints:(NSArray*)points
{
	if (points && ([ points count ] > 2 || [ points count ] == 0))
		return NSNotFound;
	
	for (int z = 0; z < [ self count ]; z++)
	{
		NSDictionary* dict = [ self selectedValueAtIndex:z ];
		if (dict[@"Object"] == obj)
		{
			if (!points)
				return z;
			
			if ([ points count ] == 1)
			{
				if ([ dict[@"Point"] unsignedLongValue ] == [ [ [ obj instance ] points ] indexOfObject:points[0] ])
					return z;
			}
			else
			{
				if (dict[@"Edge"][0] == points[0] && dict[@"Edge"][1] == points[1])
					return z;
			}
		}
	}
	return NSNotFound;
}

- (void) addObject:(id)obj forString:(NSString*)name
{
	NSMutableDictionary* mutDict = [ [ NSMutableDictionary alloc ] initWithObjectsAndKeys:obj, name, nil ];
	NSDictionary* dict = @{@([ self count ]): mutDict};
	[ data addEntriesFromDictionary:dict ];
}


@end
