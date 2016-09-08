/*
	MDTypes.h
	MovieDraw
 
	Copyright (c) 2013. All rights reserved.
*/

#import <Foundation/Foundation.h>
#import "MDMatrix.h"
#include <vector>

// Class declarations for later classes
@class MDObject, MDInstance, MDMesh;

// A single point in a mesh, consiting of a position, a normal, and a texture coordinate
@interface MDPoint : NSObject {
@private
	MDMesh* mesh;											// The mesh that this point is assigned to
}

@property (assign) float x;
@property (assign) float y;
@property (assign) float z;
@property (assign) float normalX;
@property (assign) float normalY;
@property (assign) float normalZ;
@property (assign) float textureCoordX;
@property (assign) float textureCoordY;
@property (assign) MDMatrix boneMatrix;
@property (assign) BOOL hasBone;

// Init
- (instancetype) init;
- (instancetype) initWithPoint: (MDPoint*)point;

// Data
- (void) setPosition:(MDVector3)p;
- (void) setNormal:(MDVector3)p;
- (void) setTextureCoordinates:(MDVector2)p;
- (void) setTranslateX:(float)value;								// Sets the x value for all points with the same position as this one in the instance
- (void) setTranslateY:(float)value;								// Sets the y value for all points with the same position as this one in the instance
- (void) setTranslateZ:(float)value;								// Sets the z value for all points with the same position as this one in the instance

// Mesh
@property (readonly, strong) MDInstance *instance;
@property (strong) MDMesh *mesh;

@end

// For MDObject's flags
#define MDOBJECT_AFFECT_POSITION	(1 << 0)
#define MDOBJECT_AFFECT_ROTATION	(1 << 1)

// Object Physics Types
#define MD_OBJECT_PHYSICS_EXACT				0
#define MD_OBJECT_PHSYICS_BOUNDINGBOX		1
#define MD_OBJECT_PHYSICS_BOUNDINGSPHERE	2
#define MD_OBJECT_PHYSICS_CYLINDER_X		3
#define MD_OBJECT_PHYSICS_CYLINDER_Y		4
#define MD_OBJECT_PHYSICS_CYLINDER_Z		5

// Animation Flags
#define MD_ANIMATION_NONE					0
#define MD_ANIMATION_PAUSED					(1 << 0)
#define MD_ANIMATION_REPEAT					(1 << 1)
#define MD_ANIMATION_PAUSED_UPON_COMPLETION (1 << 2)

// A object that serves as the foundation of the framework. It refers to an instance that holds the data, and contains its own translation matrix
// along with a few properties
@interface MDObject : NSObject {
@public
	BOOL updateMatrix;
	
	// Animation
	unsigned long currentAnimation;
	
	MDMatrix modelMatrix;
	NSMutableDictionary* properties;
	
	MDInstance* base;
@private
	NSString* objName;
}

@property (readonly) float translateX;
@property (readonly) float translateY;
@property (readonly) float translateZ;
@property (readonly) float scaleX;
@property (readonly) float scaleY;
@property (readonly) float scaleZ;
@property (readonly) MDVector3 rotateAxis;
@property (readonly) float rotateAngle;
@property (assign) MDVector4 colorMultiplier;
@property (assign) BOOL shouldDraw;

// Animations
@property (assign) float currentAnimationTime;
@property (assign) float currentAnimationSpeed;
@property (assign) unsigned char animationFlags;

// Physics
@property (assign) float mass;
@property (assign) float restitution;
@property (assign) unsigned char physicsType;
@property (assign) unsigned char flags;
@property (assign) float friction;
@property (assign) float rollingFriction;

// Init
- (instancetype) init;
- (instancetype) initWithObject: (MDObject*)obj;
- (instancetype) initWithInstance:(MDInstance*)inst;

// Info
- (BOOL) isEqualToObject:(MDObject*)obj;
@property  MDVector3 midPoint;
@property (readonly) MDVector4 midColor;									// Returns the average color of all points
@property (readonly) MDVector4 specularColor;
@property (readonly) float shininess;
- (MDPoint*) pointAtIndex:(unsigned long)index;
@property (readonly) unsigned long numberOfPoints;
@property (readonly, copy) NSMutableArray *points;
@property (readonly) MDMatrix modelViewMatrix;

// Drawing
- (void) drawVBO: (unsigned int*)program shadow:(unsigned int)shadowStart;

// Animations
- (void) playAnimation:(NSString*)name;
- (void) playAnimation:(NSString*)name speed:(float)sp flags:(unsigned char)flag;
- (void) pauseAnimation;
- (void) resumeAnimation;
- (void) stopAnimation;

// Instance
@property (strong) MDInstance *instance;

// Attributes
- (void) setTranslateX:(float)value;
- (void) setTranslateY:(float)value;
- (void) setTranslateZ:(float)value;
- (void) setScaleX:(float)value;
- (void) setScaleY:(float)value;
- (void) setScaleZ:(float)value;
- (void) setRotateAxis:(MDVector3)value;
- (void) setRotateAngle:(float)value;
- (void) addProperty: (NSString*) prop forKey:(NSString*)string;
@property (readonly, copy) NSMutableDictionary *properties;

// Physics
@property  BOOL affectPosition;
@property  BOOL affectRotation;

// Name
@property (copy) NSString *name;

// Static
- (BOOL) isStatic;

@end

@interface MDStaticObject : MDObject
{
@private
	NSMutableArray* lightmapTextures;
}

// Lightmap
- (void) loadLightmap:(NSString*)path;

// Draw
- (void) drawVBO: (unsigned int*)program shadow:(unsigned int)shadowStart;

@end

// Types of textures
typedef NS_ENUM(int, MDTextureType)
{
	MD_TEXTURE_DIFFUSE,				// Affects color
	MD_TEXTURE_BUMP,				// Affects normals
	MD_TEXTURE_TERRAIN_ALPHA,		// Texture map for terrain
	MD_TEXTURE_TERRAIN_DIFFUSE,		// Textures for terrain
};

// A object that contains info for a texture
@interface MDTexture : NSObject
{
@private
	NSString* path;
}

@property (assign) unsigned int texture;
@property (assign) BOOL textureLoaded;
@property (assign) MDTextureType type;
@property (assign) unsigned int head;	// Parent texture (for terrain textures)
@property (assign) float size;			// Texture scale

// Init
- (instancetype) initWithTexture:(MDTexture*)tex;

// Path
@property (copy) NSString *path;

@end

@interface MDVertexWeight : NSObject
{
}

@property (assign) unsigned long vertexID;
@property (assign) float weight;

- (instancetype) init;
- (instancetype) initWithVeretx:(unsigned long)vertex withWeight:(float)weight;
- (instancetype) initWithVertexWeight:(MDVertexWeight*)vertex;

@end

@class MDMesh;

@interface MDBone : NSObject
{
	NSMutableArray* vertexWeights;
}

@property (assign) MDMatrix offsetMatrix;
@property (assign) MDMatrix transformation;
@property (retain) MDMesh* mesh;

- (instancetype) init;
- (instancetype) initWithBone:(MDBone*)bone;
@property (readonly) unsigned long numberOfWeights;
- (MDVertexWeight*) weightAtIndex:(unsigned long)index;
- (void) addVertex:(unsigned long)vertexID withWeight:(float)weight;
- (void) addVertexWeight:(MDVertexWeight*)weight;
@property (readonly, copy) NSMutableArray *vertexWeights;

@end

@interface MDNode : NSObject
{
	NSMutableArray* meshIndices;
	NSMutableArray* boneIndices;
	MDNode* parent;
	NSMutableArray* children;
	NSMutableArray* animationSteps;
	NSMutableArray* meshes;
}

@property (assign) MDMatrix transformation;
@property (assign) BOOL isBone;

@property (strong) MDNode *parent;
- (void) addChild:(MDNode*)node;
- (void) setChildren:(NSArray*)child;
- (NSMutableArray*) children;
- (void) addAnimationStep:(unsigned long)step;
- (void) setAnimationSteps:(NSArray*)steps;
- (NSMutableArray*) animationSteps;
- (unsigned long) animationStepAtIndex:(unsigned long)index;
- (void) addMesh:(unsigned int)mesh;
- (void) setMehses:(NSArray*)mesh;
@property (readonly, copy) NSMutableArray *meshes;
- (void) addMeshIndex:(unsigned int)mesh boneIndex:(unsigned int)bone;
- (unsigned int) meshIndexAtIndex:(unsigned long)index;
- (unsigned int) boneIndexAtIndex:(unsigned long)index;
@property (readonly) unsigned long numberOfBones;

@end;

struct MDAnimationStep
{
	MDNode* node;
	std::vector<MDVector3> positions;
	std::vector<float> positionTimes;
	std::vector<MDVector4> rotations;
	std::vector<float> rotateTimes;
	std::vector<MDVector3> scalings;
	std::vector<float> scaleTimes;
};

@interface MDAnimation : NSObject
{
	NSString* name;
	std::vector<MDAnimationStep> steps;
}

@property (assign) float duration;

@property (copy) NSString *name;
- (void) setSteps:(std::vector<MDAnimationStep>) step;
- (std::vector<MDAnimationStep>*) steps NS_RETURNS_INNER_POINTER;

@end;

// A mesh object that contains vertex indices, textures, and a color
@interface MDMesh : NSObject
{
@public
	MDVector4 color;
@private
	// Data
	NSMutableArray* points;
	NSMutableArray* indices;
	NSMutableArray* textures;
	NSMutableArray* bones;
	MDMatrix transformMatrix;
	MDMatrix inverseTransformMatrix;
	
	// VAO Stuff
	unsigned int vao;
	unsigned int vaoBuffers[8];
	MDVector3* vertices;
	unsigned int* indexData;
	MDVector3* normals;
	MDVector2* texCoords;
	MDVector4* colors;
	MDVector4* matrixData;
}

@property (assign) MDMatrix meshMatrix;
@property (retain) MDInstance* instance;

// Init
- (instancetype) initWithMesh:(MDMesh*)mesh;

- (void) setupVAO;
@property (readonly) unsigned int vao;

// Points
@property (readonly, copy) NSMutableArray *points;
@property (readonly) unsigned long numberOfPoints;
- (MDPoint*) pointAtIndex: (unsigned long)index;
- (void) setPoint: (MDPoint*)point atIndex:(unsigned long)index;
- (void) addPoint: (MDPoint*)point;

// Indices
@property (readonly, copy) NSMutableArray *indices;
@property (readonly) unsigned int numberOfIndices;
- (void) addIndex:(unsigned int)index;
- (unsigned int) indexAtIndex:(unsigned int)index;

// Textures
- (void) addTexture:(MDTexture*)tex;
@property (readonly, copy) NSMutableArray *textures;
@property (readonly) unsigned long numberOfTextures;
- (MDTexture*) textureAtIndex:(unsigned long)index;

// Bones
- (void) addBone:(MDBone*)bone;
@property (readonly, copy) NSMutableArray *bones;
@property (readonly) unsigned long numberOfBones;
- (MDBone*) boneAtIndex:(unsigned long)index;

// Transform Matrices
@property  MDMatrix transformMatrix;
@property (readonly) MDMatrix inverseTransformMatrix;

// Matrix Data
- (void) setMatrixData:(MDMatrix)matrix atIndex:(unsigned long)z;
- (void) updateMatrixData;
- (void) resetMatrixData;

// Color
@property  MDVector4 color;

// Instance
- (void) setInstance:(MDInstance*)inst;
- (MDInstance*) instance;

@end

// A container for meshes that also contains point data and other properties
@interface MDInstance : NSObject {
@private
	NSString* name;
	NSMutableDictionary* properties;
	
	// Animations
	NSMutableArray* animations;
	MDNode* rootNode;
	MDMatrix inverseRoot;
	MDMatrix startMatrix;
	MDMatrix startInverse;
	
	// Meshes
	NSMutableArray* meshes;
	MDMesh* currentMesh;
}

// Materials
@property (assign) MDVector4 specularColor;
@property (assign) float shininess;

// Init
- (instancetype) init;
- (instancetype) initWithInstance:(MDInstance*)inst;

// Properties
- (void) addProperty: (NSString*) prop forKey:(NSString*)string;
@property (readonly, copy) NSMutableDictionary *properties;

// Animation Data
@property  MDMatrix startMatrix;
@property (readonly) MDMatrix inverseStartMatrix;
@property (readonly) MDMatrix inverseRoot;
@property (strong) MDNode *rootNode;

// Animations
- (void) addAnimation:(MDAnimation*)animation;
@property (readonly, copy) NSMutableArray *animations;

// Meshes
- (void) beginMesh;		// Allows a mesh to be added
// These may be called in between a beginMesh and endMesh call
- (void) setTransformMatrix:(MDMatrix)matrix;
- (void) setMeshMatrix:(MDMatrix)matrix;
- (void) addTexture:(NSString*)path withType:(MDTextureType)type;
- (void) addTexture:(NSString *)path withType:(MDTextureType)type withHead:(unsigned int)head withSize:(float)size;
- (void) addBone:(NSArray*)weights withMatrix:(MDMatrix)matrix;
- (void) addIndex:(unsigned int)index;
- (void) setColor:(MDVector4)color;
- (void) endMesh;		// Adds the current mesh to the instance
@property (readonly, copy) NSArray *meshes;
- (MDMesh*) meshAtIndex:(unsigned long)index;
@property (readonly) unsigned long numberOfMeshes;

// Points
@property (readonly, copy) NSMutableArray *points;
@property (readonly) unsigned long numberOfPoints;
- (MDPoint*) pointAtIndex: (unsigned long)index;
- (void) setPoint: (MDPoint*)point atIndex:(unsigned long)index;
- (void) addPoint: (MDPoint*)point;
- (unsigned int) indexAtIndex:(unsigned long)index;
- (void) setIndex:(unsigned int)index atIndex:(unsigned long)place;
@property (readonly) unsigned long numberOfIndices;

// Draw
- (void) setupVBO;																	// Load the VBO
- (void) drawShadowVBO;																// Draw for shadows
- (void) drawVBOColor:(MDVector4)color;												// Draw for picking

// Info
@property  MDVector3 midPoint;
- (void) setScale:(MDVector3)scale;
@property  MDVector4 midColor;																// Average of the colors of all points

// Name
@property (copy) NSString *name;

@end

// Other objects
@class MDLight, MDParticleEngine, MDCurve;

// A camera that points to a particular position
@interface MDCamera : NSObject {
@private
	NSString* name;
}

@property (assign) MDVector3 midPoint;
@property (assign) MDVector3 lookPoint;
@property (assign) float orientation;

// Init
- (MDCamera*) init;
- (MDCamera*) initWithMDCamera: (MDCamera*)cam;

// Name
@property (copy) NSString *name;

@end

// Types of light
#define MDDirectionalLight		0
#define MDPointLight			1
#define MDSpotLight				2

// A light of different types that illuminates the scene
@interface MDLight : NSObject {
@private
	NSString* name;
}

@property (assign) MDVector4 ambientColor;
@property (assign) MDVector4 diffuseColor;
@property (assign) MDVector4 specularColor;
@property (assign) MDVector3 position;
@property (assign) MDVector3 spotDirection;
@property (assign) float spotExp;				// Exponential decay of spot light
@property (assign) float spotCut;				// Currently does nothing
@property (assign) float spotAngle;				// Changes the angle by which the spot light radiates [0, 1]
@property (assign) float constAtt;				// Constant decay of light
@property (assign) float linAtt;				// Linear decay of light
@property (assign) float quadAtt;				// Quadratic decay of light
@property (assign) unsigned int lightType;
// Shadows
@property (assign) BOOL enableShadows;
@property (assign) BOOL isStatic;

// Init
- (MDLight*) init;
- (MDLight*) initWithMDLight:(MDLight*)light;

// Data
- (void) lightData: (float*)data;				// Puts all the data of the light into a float array

// Name
@property (copy) NSString *name;

@end
	
#pragma pack(push, 1)
	
typedef struct
{
	float position[3];		// Coordinate Position
	float color[4];			// Red, Green, Blue, Alpha
} MDParticleVertex;

typedef struct
{
	double life;
	float position[3];
	float startPos[3];
	float color[4];
	float size;
	float seed[3];			// 3 random numbers
} MDParticle;
	
#pragma pack(pop)

@interface MDParticleEngine : NSObject {
@public
	unsigned long numberOfParticles;
	MDVector3 currentPos;
	unsigned long particleLife;
	unsigned int velocityType;				// Determines the animation that the particle engine is performing, [0, 10]
	float animationValue;					// Current animation position
	float animationRate;					// How fast the animation is proceeding (does nothing yet)
	BOOL oneShotDone;
	
@private
	MDParticle* particles;
	unsigned long liveParticles;
	NSString* imageString;
	unsigned int image;
	unsigned int vao[2];
	MDParticleVertex* vertices;
	void (*ParticleCreated)(MDParticle* p, MDParticleEngine* engine);
	void (*UpdateVelocity)(MDParticle* p, float& xVal, float& aVal, MDParticleEngine* engine, MDVector3& velocities, unsigned int& vel);
	BOOL lessThanFull;
	float particleAngle;
	unsigned int emitRate;
	unsigned long shouldPart;
	
	NSString* name;
}

@property (assign) BOOL oneShot;
@property (assign) BOOL tail;
@property (assign) BOOL flow;
@property (assign) BOOL show;
@property (assign) MDVector4 startColor;
@property (assign) MDVector4 endColor;
@property (assign) float particleSize;
@property (assign) MDVector3 velocities;	// Specifies the strength in each direction of that animation

// Init
- (MDParticleEngine*) init;
- (MDParticleEngine*) initWithMDParticleEngine:(MDParticleEngine*)engine;

// Draw
- (void) draw:(unsigned int*)program duration:(double)frameDuration desired:(unsigned int)desiredFPS;
- (void) reloadModel;							// Setup all the particles

// Attributes
@property  MDVector3 position;
@property  unsigned long numberOfParticles;
@property  unsigned long particleLife;
@property  unsigned int velocityType;
@property  void (*particleCreatedFunction)(MDParticle *, MDParticleEngine *);
@property  void (*updateVelocityFunction)(MDParticle *, float &, float &, MDParticleEngine *, MDVector3 &, unsigned int &);
@property (copy) NSString *image;

// Data
@property (readonly) MDParticleVertex *vertices;
@property (readonly) MDParticle *particles;

// Other Info
@property (readonly) unsigned long liveParticles;
@property (readonly) BOOL lessThanFull;

// Name
@property (copy) NSString *name;

@end

// A collection of points that defines a curve
// 2 points - line
// 3 points - circle
// 4 points - bézier curve
// More than 4 - not yet supported
@interface MDCurve : NSObject {
@private
	std::vector<MDVector3> points;
	NSString* name;
}

// Init
- (MDCurve*) init ;
- (MDCurve*) initWithMDCurve:(MDCurve*)curve;

// Points
- (void) addPoint:(MDVector3)point;
- (void) removeAllPoints;
- (void) setPoints:(std::vector<MDVector3>)p;
@property (readonly) std::vector<MDVector3> *curvePoints;

// Draw
- (void) draw;

// Data
- (MDVector3) interpolate:(float)time;		// Returns the position along the curve (time is from 0 to 1)
- (MDVector3) tangent:(float)time;			// Returns the tangent vector along the curve (time is from 0 to 1)
- (MDVector3) normal:(float)time;			// Returns the normal vector along the curve (time is from 0 to 1)
- (float) length:(unsigned int)slices;		// Number of slices to cut the curve into (more = better approximation)

// Name
@property (copy) NSString *name;

@end
