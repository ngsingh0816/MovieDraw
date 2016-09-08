/*
	GLView.h
	MovieDraw
 
	Copyright (c) 2013. All rights reserved.
*/

#import <Cocoa/Cocoa.h>
#import "MDTypes.h"
#import "btBulletDynamicsCommon.h"
#import "GLString.h"

@interface GLView : NSOpenGLView
{
@private
	// Options
	int colorBits, depthBits;
	BOOL defaultPhysics;						// Sets whether to use default physics
	unsigned int antialias;
	BOOL rebuildShaders;
	NSString* loadedString;
	NSMutableDictionary* sceneProperties;		// Contains properties like skybox information
	
	// Data
	NSMutableArray* instances;
	NSMutableArray* objects;
	NSMutableIndexSet* alphaObjects;
	NSMutableArray* otherObjects;
	NSMutableArray* dynamicLights;
	
	// Camera
	MDVector3 cameraPoint;
	MDVector3 cameraLook;
	MDVector3 cameraRotation;
	float cameraOrientation;
	BOOL useCamera;
	
	// FPS
	int fpsCounter;
	int truefps;
	NSTimer* fpsTimer;
	
	// Keys
	NSMutableArray* keys;
	
	// User functinos
	void (*drawFunc)();
	void (*customDraw)();
	void (*keyFunc)(NSArray*);
	void (*downFunc)(NSEvent*);
	void (*upFunc)(NSEvent*);
	void (*mouseDownFunc)(NSEvent*);
	void (*mouseUpFunc)(NSEvent*);
	void (*mouseDraggedFunc)(NSEvent*);
	void (*rightDownFunc)(NSEvent*);
	void (*rightUpFunc)(NSEvent*);
	void (*rightDraggedFunc)(NSEvent*);
	void (*mouseMovedFunc)(NSEvent*);
	void (*reshapeFunc)(NSSize);
	void (*collisionFunc)(MDObject* obj1, MDObject* obj2, MDVector3 contactPoint, MDVector3 normal);
	
	// Shaders
	unsigned int vertexShader[4], fragmentShader[4], program[4];
	std::vector<unsigned int> shadowFBO[3], shadowTexture[3];
	
	// Matrices
	MDMatrix projectionMatrix, modelViewMatrix;
	
	// VAOs
	unsigned int skyboxData[3];
	
	// Framebuffers
	unsigned int pickingBuffer[3];
	
	// Uniform locations
	unsigned int* lightingLocations;
	unsigned int* lightingLocationsStatic;
	unsigned int* programLocations;
	unsigned int* programConstants;
	unsigned int* programConstantsStatic;
	unsigned int* particleLocations;
	
	// Timers
	double previousTime;
	double frameDuration;
	
	// Physics
	btBroadphaseInterface* broadphase;
	btDefaultCollisionConfiguration* collisionConfiguration;
	btCollisionDispatcher* dispatcher;
	btSequentialImpulseConstraintSolver* solver;
	btDiscreteDynamicsWorld* dynamicsWorld;
	std::vector<btRigidBody*> rigidBodies;
	std::vector<unsigned long> rigidBodyObjects;
}



- (instancetype) initWithFrame:(NSRect)frame colorBits:(int)numColorBits
		   depthBits:(int)numDepthBits antialias:(int)anti fullscreen:(BOOL)runFullScreen;
- (void) reshape;								// Window resized handler
- (void) drawRect:(NSRect)rect;					// Draws

// Camera
- (void) setCamera:(MDVector3)midPoint toLocation:(MDVector3)look rotation:(MDVector3)rot orientation:(float)orien;
@property  MDVector3 cameraMidPoint;
@property  MDVector3 cameraLookPoint;
@property  MDVector3 cameraRotation;
@property  float cameraOrientation;
@property (readonly) BOOL cameraUse;
- (void) setUseCamera:(BOOL)use;

// Displays text
- (void) drawString:(GLString*)string atLocation:(NSPoint)location rotation:(float)rot center:(BOOL)align;
- (GLString*) createString:(NSString*)str textColor:(NSColor*)text withSize:(double)dsize withFontName:(NSString*)fontName;
- (void) writeString: (NSString*) str textColor: (NSColor*) text 
			boxColor: (NSColor*) box borderColor: (NSColor*) border
		  atLocation: (NSPoint) location withSize: (double) dsize 
		withFontName: (NSString*) fontName rotation:(float) rot center:(BOOL)align;

// Data
- (void) setInstances: (NSArray*)insts;
- (void) setObjects: (NSArray*)objs;
- (void) calculateAlphaObjects;
- (void) setOtherObjects: (NSArray*)objs;
- (NSMutableArray*) instances;
- (NSMutableArray*) objects;
@property (readonly, copy) NSIndexSet *alphaObjects;
- (NSMutableArray*) otherObjects;

// User functions
// Called before a frame is drawn, but cannot implement its own draw commands
@property  void (*drawFunction)();
// Called during the middle of a frame and can implement its own draw commands
@property  void (*customDrawFunction)();
// Function that is called every frame with the current keys that are pressed
@property  void (*keyFunction)(NSArray *);
// Key Down event
@property  void (*keyDownFunction)(NSEvent *);
// Key Up event
@property  void (*keyUpFunction)(NSEvent *);
// Mouse Down Event
@property  void (*mouseDownFunction)(NSEvent *);
// Mouse Up Event
@property  void (*mouseUpFunction)(NSEvent *);
// Mouse Dragged Event
@property  void (*mouseDraggedFunction)(NSEvent *);
// Right Mouse Down Event
@property  void (*rightMouseDownFunction)(NSEvent *);
// Right Mouse Up Event
@property  void (*rightMouseUpFunction)(NSEvent *);
// Right Mouse Dragged Event
@property  void (*rightMouseDraggedFunction)(NSEvent *);
// Mouse Moved Event
@property  void (*mouseMovedFunction)(NSEvent *);
// Reshape event
@property  void (*reshapeFunction)(NSSize);
// Collision event
@property  void (*collisionFunction)(MDObject *, MDObject *, MDVector3, MDVector3);
// Calls the user's key function handler
- (void) processKeys;

// Options
- (void) setDefaultPhysics:(BOOL)physics;
- (BOOL) defaultPhysics;
@property (copy) NSString *loadedString;		// MSAA antialiasing
@property  unsigned int antialias;

// Updating
- (void) rebuildShaders;
- (void) removeAllTextures;
- (void) loadNewTextures;
- (void) updateSkybox;

// Picking
- (unsigned int) pick:(NSPoint) point;			// Returns the index of the object at the point in the window

// Matrices
@property (readonly) MDMatrix projectionMatrix;
@property (readonly) MDMatrix modelViewMatrix;

// FPS
@property (readonly) double frameDuration;						// Frame duration in milliseconds
- (void) updateFPS;								// Called once a second to update the FPS

// Physics
@property (readonly) btDiscreteDynamicsWorld *dynamicsWorld;
@property (readonly) std::vector<btRigidBody *> *rigidBodies;
@property (readonly) std::vector<unsigned long> *rigidBodyObjects;

// Properties
@property (copy) NSMutableDictionary *sceneProperties;

@end
