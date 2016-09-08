//
//  MDTypes.h
//  MovieDraw
//
//  Created by Neil Singh on 8/3/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MDMatrix.h"
#include <vector>

@class MDObject, MDMesh, MDInstance;

@interface MDPoint : NSObject {
@package
	MDMesh* mesh;
}

@property (assign) float x;
@property (assign) float y;
@property (assign) float z;
/*@property (assign) float red;
@property (assign) float green;
@property (assign) float blue;
@property (assign) float alpha;*/
@property (assign) float normalX;
@property (assign) float normalY;
@property (assign) float normalZ;
@property (assign) float textureCoordX;
@property (assign) float textureCoordY;
@property (assign) MDMatrix boneMatrix;
@property (assign) BOOL hasBone;

- (instancetype) init;
- (instancetype) initWithPoint: (MDPoint*)point;
@property (readonly) MDVector3 realMidPoint;
- (void) setX:(float)xVal Y:(float)yVal Z:(float)zVal;
@property  MDVector3 normal;
@property  MDVector3 position;

// Attributes
- (void) addTranslateX:(float)value;
- (void) addTranslateY:(float)value;
- (void) addTranslateZ:(float)value;
- (void) setTranslateX:(float)value;
- (void) setTranslateY:(float)value;
- (void) setTranslateZ:(float)value;
- (void) addX:(float)value;
- (void) addY:(float)value;
- (void) addZ:(float)value;
- (void) addScaleX:(float)value;
- (void) addScaleY:(float)value;
- (void) addScaleZ:(float)value;
- (void) setRotateX:(float)value;
- (void) setRotateY:(float)value;
- (void) setRotateZ:(float)value;
@property (readonly, strong) MDInstance *instance;
@property (strong) MDMesh *mesh;
/*- (MDColor) midColor;
- (void) setRed:(float)r green:(float)g blue:(float)b alpha:(float)a;
- (void) setMidColor:(MDColor)color;
- (void) addMidColor:(MDColor)color;*/

@end

// Object Physics Types
#define MD_OBJECT_PHYSICS_EXACT				0
#define MD_OBJECT_PHSYICS_BOUNDINGBOX		1
#define MD_OBJECT_PHYSICS_BOUNDINGSPHERE	2
#define MD_OBJECT_PHYSICS_CYLINDER_X		3
#define MD_OBJECT_PHYSICS_CYLINDER_Y		4
#define MD_OBJECT_PHYSICS_CYLINDER_Z		5

#define MD_ANIMATION_NONE					0
#define MD_ANIMATION_PAUSED					(1 << 0)
#define MD_ANIMATION_REPEAT					(1 << 1)
#define MD_ANIMATION_PAUSED_UPON_COMPLETION (1 << 2)

@interface MDObject : NSObject {
@package
	BOOL updateMatrix;
	MDMatrix modelMatrix;
	MDVector4 colorMultiplier;
	
	// Size / Move / Rotate Colors (3)
	NSMutableDictionary* properties;
	
	// Animation
	unsigned long currentAnimation;
		
	MDInstance* base;
	NSString* objName;
	
	NSMutableArray* data;
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
@property (assign) BOOL shouldView;
@property (assign) MDVector4* objectColors;

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
@property (assign) unsigned char type;
@property (assign) BOOL isStatic;

- (instancetype) init;
- (instancetype) initWithObject: (MDObject*)obj;
- (instancetype) initWithInstance:(MDInstance*)inst;
- (BOOL) isEqualToObject:(MDObject*)obj;
//- (MDVector3) midPoint;
@property (readonly) MDVector3 translate;
@property (readonly) MDVector3 realMidPoint;
//- (MDVector3) objMidPoint;
@property  MDVector4 midColor;
@property  MDVector4 specularColor;
@property  float shininess;
- (MDPoint*) pointAtIndex:(unsigned long)index;
@property (readonly) unsigned long numberOfPoints;
@property (readonly, copy) NSArray *points;
@property (readonly) MDMatrix modelViewMatrix;
//- (MDMatrix) modelViewMatrixMidPoint;

// Drawing
- (void) drawVBO: (unsigned int*)program shadow:(unsigned int)shadowStart;

// Instance
@property (copy) NSString *name;
@property (strong) MDInstance *instance;

// Animations
- (void) playAnimation:(NSString*)name;
- (void) playAnimation:(NSString*)name speed:(float)sp flags:(unsigned char)flag;
- (void) pauseAnimation;
- (void) resumeAnimation;
- (void) stopAnimation;

// Attributes
- (void) setTranslateX:(float)value;
- (void) setTranslateY:(float)value;
- (void) setTranslateZ:(float)value;
- (void) setScaleX:(float)value;
- (void) setScaleY:(float)value;
- (void) setScaleZ:(float)value;
- (void) setRotateAxis:(MDVector3)value;
- (void) setRotateAngle:(float)value;

- (void) addTranslateX:(float)value;
- (void) addTranslateY:(float)value;
- (void) addTranslateZ:(float)value;
- (void) addScaleX:(float)value;
- (void) addScaleY:(float)value;
- (void) addScaleZ:(float)value;
- (void) setMidPoint:(MDVector3)point;
- (void) addMidColor:(MDVector4)color;
- (void) addSpecularColor:(MDVector4)color;
- (void) addShininess:(float)shine;
- (void) addProperty: (NSString*) prop forKey:(NSString*)string;
@property (readonly, copy) NSMutableDictionary *properties;

// Physics
@property  BOOL affectPosition;
@property  BOOL affectRotation;

@property (readonly, copy) NSMutableArray *data;

@end
	
typedef struct
{
	float position[3];		// Coordinate Position
	float color[4];			// Red, Green, Blue, Alpha
	float normal[3];		// X, Y, Z
	float textureCoord[2];	// X, Y
} VBOVertex;
	
extern const unsigned int NumberOfFaceProperties;
extern const char* FaceProperties[];
	
typedef NS_ENUM(int, MDTextureType)
{
	MD_TEXTURE_DIFFUSE,
	MD_TEXTURE_BUMP,
	MD_TEXTURE_TERRAIN_ALPHA,
	MD_TEXTURE_TERRAIN_DIFFUSE,
};
	
@interface MDTexture : NSObject
{
	NSString* path;
}

@property (assign) unsigned int texture;
@property (assign) BOOL textureLoaded;
@property (assign) MDTextureType type;
@property (assign) unsigned int head;
@property (assign) float size;

- (instancetype) initWithTexture:(MDTexture*)tex;
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
	float duration;
	std::vector<MDAnimationStep> steps;
}

@property (assign) float duration;

@property (copy) NSString *name;
- (void) setSteps:(std::vector<MDAnimationStep>) step;
- (std::vector<MDAnimationStep>*) steps NS_RETURNS_INNER_POINTER;

@end;

@interface MDMesh : NSObject
{
	// Data
	NSMutableArray* points;
	NSMutableArray* indices;
	NSMutableArray* textures;
	NSMutableArray* bones;
	MDVector4 color;
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

- (instancetype) initWithMesh:(MDMesh*)mesh;

- (void) setupVAO;
@property (readonly) unsigned int vao;

@property (readonly, copy) NSMutableArray *points;
@property (readonly) unsigned long numberOfPoints;
- (MDPoint*) pointAtIndex: (unsigned long)index;
- (void) setPoint: (MDPoint*)point atIndex:(unsigned long)index;
- (void) addPoint: (MDPoint*)point;
- (void) addTexture:(MDTexture*)tex;
@property (readonly, copy) NSMutableArray *textures;
@property (readonly) unsigned long numberOfTextures;
- (MDTexture*) textureAtIndex:(unsigned long)index;
@property (readonly) unsigned int numberOfIndices;
- (void) addIndex:(unsigned int)index;
- (unsigned int) indexAtIndex:(unsigned int)index;
@property (readonly, copy) NSMutableArray *indices;
- (void) addBone:(MDBone*)bone;
@property (readonly, copy) NSMutableArray *bones;
@property (readonly) unsigned long numberOfBones;
- (MDBone*) boneAtIndex:(unsigned long)index;
@property  MDVector4 color;
@property  MDMatrix transformMatrix;
@property (readonly) MDMatrix inverseTransformMatrix;

- (void) setMatrixData:(MDMatrix)matrix atIndex:(unsigned long)z;
- (void) updateMatrixData;
- (void) resetMatrixData;

@end

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

@property (assign) MDVector4 specularColor;
@property (assign) float shininess;

- (instancetype) init;
- (instancetype) initWithInstance:(MDInstance*)inst;
@property (copy) NSString *name;
- (void) addProperty: (NSString*) prop forKey:(NSString*)string;
@property (readonly, copy) NSMutableDictionary *properties;

@property  MDMatrix startMatrix;
@property (readonly) MDMatrix inverseStartMatrix;
@property (readonly) MDMatrix inverseRoot;
@property (strong) MDNode *rootNode;

- (void) addAnimation:(MDAnimation*)animation;
@property (readonly, copy) NSMutableArray *animations;

- (void) addMesh:(MDMesh*)mesh;
- (void) beginMesh;
- (void) addPoint: (MDPoint*)point;
- (void) setTransformMatrix:(MDMatrix)matrix;
- (void) setMeshMatrix:(MDMatrix)matrix;
- (void) addTexture:(NSString*)path withType:(MDTextureType)type;
- (void) addTexture:(NSString *)path withType:(MDTextureType)type withHead:(unsigned int)head withSize:(float)size;
- (void) addBone:(NSArray*)weights withMatrix:(MDMatrix)matrix;
- (void) addIndex:(unsigned int)index;
- (void) setColor:(MDVector4)color;
- (void) endMesh;
@property (readonly, copy) NSArray *meshes;
- (MDMesh*) meshAtIndex:(unsigned long)index;
@property (readonly) unsigned long numberOfMeshes;

@property (readonly) unsigned long numberOfPoints;
@property (readonly, copy) NSArray *points;
- (MDPoint*) pointAtIndex: (unsigned long)index;
- (void) setPoint: (MDPoint*)point atIndex:(unsigned long)index;
- (unsigned int) indexAtIndex:(unsigned long)index;
- (void) setIndex:(unsigned int)index atIndex:(unsigned long)place;
@property (readonly) unsigned long numberOfIndices;
- (void) setupVBO;
- (void) drawVBO: (unsigned int*)program shadow:(unsigned int)shadowStart;
- (void) drawShadowVBO;
- (void) drawVBOColor:(MDVector4)color;
- (void) updateVBOPoint:(unsigned long)point;

@property (readonly) MDVector3 realMidPoint;
@property  MDVector3 midPoint;
- (void) setScale:(MDVector3)scale;
@property  MDVector4 midColor;
- (void) addMidColor:(MDVector4)color;
- (void) addSpecularColor:(MDVector4)color;
- (void) addShininess:(float)shine;

- (void) addTranslateX:(float)value;
- (void) addTranslateY:(float)value;
- (void) addTranslateZ:(float)value;
- (void) addScaleX:(float)value;
- (void) addScaleY:(float)value;
- (void) addScaleZ:(float)value;
- (void) setRotateX:(float)value;
- (void) setRotateY:(float)value;
- (void) setRotateZ:(float)value;

@end

@class MDLight, MDSound, MDParticleEngine, MDCurve;

@interface MDCamera : NSObject {
@package
	MDVector3 lookPoint;
	NSString* name;
}

@property (assign) MDVector3 midPoint;
@property (readonly) MDVector3 lookPoint;
@property (assign) float orientation;
@property (assign) BOOL show;
@property (assign) BOOL use;
@property (retain) MDObject* obj;
@property (assign) BOOL selected;
@property (assign) BOOL lookSelected;
@property (retain) MDInstance* instance;
@property (retain) MDObject* lookObj;

+ (MDCamera*) cameraWithMDCamera: (MDCamera*)cam;
- (MDCamera*) initWithMDCamera: (MDCamera*)cam;
- (MDCamera*) initWithMDLight: (MDLight*)light;
- (MDCamera*) initWithMDSound:(MDSound*)sound;
- (MDCamera*) initWithMDParticleEngine: (MDParticleEngine*)engine;
- (MDCamera*) initWithMDCurve:(MDCurve*)curve;
- (instancetype) init;
- (void) setLookPoint:(MDVector3)lp;
- (void) setOnlyLookPoint:(MDVector3)lp;
@property (copy) NSString *name;

@end

#define MDDirectionalLight		0
#define MDPointLight			1
#define MDSpotLight				2

@interface MDLight : NSObject {
@package
	NSString* name;
}

@property (assign) MDVector4 ambientColor;
@property (assign) MDVector4 diffuseColor;
@property (assign) MDVector4 specularColor;
@property (assign) MDVector3 position;
@property (assign) MDVector3 spotDirection;
@property (assign) float spotExp;
@property (assign) float spotCut;
@property (assign) float spotAngle;
@property (assign) float constAtt;
@property (assign) float linAtt;
@property (assign) float quadAtt;
@property (assign) unsigned int lightType;
@property (retain) MDObject* obj;
@property (assign) BOOL selected;
@property (assign) BOOL show;
@property (assign) BOOL enableShadows;
@property (assign) BOOL isStatic;

- (MDLight*) initWithMDLight:(MDLight*)light;
- (MDLight*) initWithMDCamera:(MDCamera*)cam;
- (MDLight*) initWithMDSound:(MDSound*)sound;
- (MDLight*) initWithMDParticleEngine:(MDParticleEngine*)engine;
- (MDLight*) initWithMDCurve:(MDCurve*)curve;
- (MDLight*) init;
@property (copy) NSString *name;
- (void) lightData: (float*)data;

@end

#define MD_SOUND_REPEAT			(1 << 0)
#define MD_SOUND_PLAY_ON_LOAD	(1 << 1)
#define MD_SOUND_ENABLED		(1 << 2)

@interface MDSound : NSObject {
	@package
	NSString* name;
	NSString* file;
}

@property (assign) MDVector3 position;
@property (assign) float linAtt;
@property (assign) float quadAtt;
@property (assign) float minVolume;
@property (assign) float maxVolume;
@property (assign) float speed;
@property (assign) unsigned char flags;
@property (retain) MDObject* obj;
@property (assign) BOOL selected;
@property (assign) BOOL show;

- (MDSound*) initWithMDLight:(MDLight*)light;
- (MDSound*) initWithMDCamera:(MDCamera*)cam;
- (MDSound*) initWithMDSound:(MDSound*)sound;
- (MDSound*) initWithMDParticleEngine:(MDParticleEngine*)engine;
- (MDSound*) initWithMDCurve:(MDCurve*)curve;
- (MDSound*) init;

@property (copy) NSString *name;
@property (copy) NSString *file;

- (void) updateVolume:(MDVector3) pos;
@property (readonly) float volume;

@end
	
#pragma pack(push, 1)
	
typedef struct
{
	float position[3];		// Coordinate Position
	float color[4];			// Red, Green, Blue, Alpha
	//float textureCoord[2];	// X, Y
} MDParticleVertex;

typedef struct
{
	double life;
	float position[3];
	float startPos[3];
	float color[4];
	float size;
	float seed[3];
} MDParticle;
	
#pragma pack(pop)
	
typedef NS_ENUM(int, MDEmitterType)
{
	MD_EMITTER_POINT,
	MD_EMITTER_LINE,
	MD_EMITTER_RECTANGLE,
};
	
@interface MDParticleEngine : NSObject {
@private
	MDParticle* particles;
	unsigned long liveParticles;
	MDVector4 startColor;
	MDVector4 endColor;
	unsigned long numberOfParticles;
	MDVector3 currentPos;
	float particleSize;
	unsigned long particleLife;
	unsigned int velocityType;
	MDVector3 velocities;
	NSString* imageString;
	unsigned int image;
	unsigned int vao[2];
	MDParticleVertex* vertices;
	void (*ParticleCreated)(MDParticle* p, MDParticleEngine* engine);
	void (*UpdateVelocity)(MDParticle* p, float& xVal, float& aVal, MDParticleEngine* engine, MDVector3& velocities, unsigned int& vel);
	BOOL lessThanFull;
	float particleAngle;
	unsigned long shouldPart;
	BOOL oneShotDone;
	
	NSString* name;
}

@property (retain) MDObject* obj;
@property (assign) BOOL selected;
@property (assign) BOOL show;
@property (assign) BOOL oneShot;
@property (assign) unsigned int emitRate;
@property (assign) float animationValue;
@property (assign) float animationRate;
@property (assign) BOOL tail;
@property (assign) BOOL flow;

- (MDParticleEngine*) initWithMDLight:(MDLight*)light;
- (MDParticleEngine*) initWithMDCamera:(MDCamera*)cam;
- (MDParticleEngine*) initWithMDSound:(MDSound*)sound;
- (MDParticleEngine*) initWithMDParticleEngine:(MDParticleEngine*)engine;
- (MDParticleEngine*) initWithMDCurve:(MDCurve*)curve;

- (instancetype) init;
- (void) draw:(unsigned int*)program duration:(double)frameDuration desired:(unsigned int)desiredFPS;

@property  MDVector3 position;
@property  MDVector4 startColor;
@property  MDVector4 endColor;
@property  unsigned long numberOfParticles;
@property  float particleSize;
@property  unsigned long particleLife;
@property  unsigned int velocityType;
@property  MDVector3 velocities;
- (void) reloadModel;
@property  void (*particleCreatedFunction)(MDParticle *, MDParticleEngine *);
@property  void (*updateVelocityFunction)(MDParticle *, float &, float &, MDParticleEngine *, MDVector3 &, unsigned int &);
@property (copy) NSString *image;

@property (readonly) MDParticleVertex *vertices;
@property (readonly) MDParticle *particles;
@property (readonly) unsigned long liveParticles;
@property (readonly) BOOL lessThanFull;

@property (copy) NSString *name;

@end
	
@interface MDCurve : NSObject {
@private
	std::vector<MDVector3> points;
	//NSMutableArray* pObjs;
	//NSMutableArray* pSelected;
	
	NSString* name;
}

@property (retain) MDObject* obj;
@property (assign) BOOL selected;
@property (assign) BOOL show;

- (MDCurve*) initWithMDLight:(MDLight*)light;
- (MDCurve*) initWithMDCamera:(MDCamera*)cam;
- (MDCurve*) initWithMDSound:(MDSound*)sound;
- (MDCurve*) initWithMDParticleEngine:(MDParticleEngine*)engine;
- (MDCurve*) initWithMDCurve:(MDCurve*)curve;
@property (copy) NSString *name;
- (void) addPoint:(MDVector3)point;
- (void) removeAllPoints;
- (void) draw;
- (void) setPoints:(std::vector<MDVector3>)p;
@property (readonly) std::vector<MDVector3> *curvePoints;

- (MDVector3) interpolate:(float)time;		// Time is from 0 to 1
- (MDVector3) tangent:(float)time;
- (MDVector3) normal:(float)time;
- (float) length:(unsigned int)slices;		// Number of slices to cut into (more = better approximation)

@end

@interface MDFace : NSObject
{
	NSMutableArray* points;
	NSMutableArray* indices;
}

@property (assign) unsigned char drawMode;

- (void) addPoint:(MDPoint*)p;
@property (readonly, copy) NSMutableArray *points;
@property (readonly, copy) NSMutableArray *indices;
- (void) addIndex:(unsigned int)index;

@end

@interface MDSelection : NSObject {
@private
    NSMutableDictionary* data;
}

- (instancetype) init;
- (instancetype) initWithSelection: (MDSelection*)sel;
- (void) addObject: (MDObject*) obj;
- (void) replaceObjectAtIndex: (unsigned long)index withObject:(MDObject*)obj;
- (void) addVertex:(MDPoint*)point fromObject:(MDObject*)obj;
- (void) replaceObjectAtIndex: (unsigned long)index withObject:(MDObject*)obj withVertex:(MDPoint*)point;
- (NSDictionary*) selectedValueAtIndex: (unsigned long)index;
- (BOOL) containsObject: (MDObject*)obj withPoints:(NSArray*)points;
@property (readonly) unsigned long count;
- (void) clear;
- (void) removeValue: (MDObject*)obj withPoints:(NSArray*)points;
- (void) removeValueAtIndex:(unsigned long) index;
@property (readonly, copy) NSDictionary *completeData;
- (id) fullValueAtIndex: (unsigned long)index;
- (unsigned long) indexOfObject:(MDObject*)obj withPoints:(NSArray*)points;
- (void) addObject:(id)obj forString:(NSString*)name;

@end
