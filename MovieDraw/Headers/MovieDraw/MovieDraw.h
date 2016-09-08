/*
	MovieDraw.h
	MovieDraw
 
	Copyright (c) 2013. All rights reserved.
*/

#import "MovieDraw/MDTypes.h"
#import "MovieDraw/GLWindow.h"
#import "MovieDraw/GLView.h"
#import "MovieDraw/GLString.h"
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>
#import "MDGUI.h"

// GLWindow
void MDSetGLWindow(GLWindow* wind);
GLWindow* MDGLWindow();
void MDSetWindowTitle(NSString* name);
NSString* MDWindowTitle();
GLView* MDGLView();

// Objects
void MDAddObject(MDObject* obj);											// Adds an object to the scene
void MDRemoveObject(MDObject* obj);											// Removes an object from the scene
NSMutableArray* MDObjects();												// Objects in the current scene
NSMutableArray* MDInstances();												// Instances in the current scene
NSMutableArray* MDOtherObjects();											// Cameras, lights, particle engines, and curves in the scene
MDObject* MDObjectWithName(NSString* objName, NSString* instName);			// Returns the first object with the right instance and object name
MDObject* MDObjectWithValueForProperty(NSString* value, NSString* key);		// Returns the first object with the correct value for the key
id MDOtherObjectNamed(NSString* name);										// Returns the first camera, light, particle engine, or cuve with that name
void MDSetObjects(NSArray* objs);
void MDSetInstances(NSArray* insts);
void MDSetOtherObjects(NSArray* objs);

// Camera
void MDSetCamera(MDVector3 mid, MDVector3 look, MDVector3 rot, float orien, BOOL use);
void MDSetCamera(MDCamera* camera);

// User functions
void MDSetDrawFunction(void (*func)());										// Called at the beginning every frame, but cannot draw
void MDSetCustomDrawFunction(void (*func)());								// Called in the middle of every frame, but can draw
void MDSetKeyFunction(void (*func)(NSArray*));								// Called every frame with an array of the keys pressed
void MDSetKeyDown(void (*func)(NSEvent*));									// Key down event
void MDSetKeyUp(void (*func)(NSEvent*));									// Key up event
void MDSetMouseDown(void (*func)(NSEvent*));								// Mouse down event
void MDSetMouseUp(void (*func)(NSEvent*));									// Mouse up event
void MDSetMouseDragged(void (*func)(NSEvent*));								// Mouse dragged event
void MDSetRightMouseDown(void (*func)(NSEvent*));							// Right Mouse down event
void MDSetRightMouseUp(void (*func)(NSEvent*));								// Right Mouse up event
void MDSetRightMouseDragged(void (*func)(NSEvent*));						// RightMouse dragged event
void MDSetMouseMoved(void (*func)(NSEvent*));								// Mouse moved event
void MDSetLoadSceneFunction(void (*func)(NSString* scene));					// Called when a new scene is loaded
void MDSetReshapeFunction(void (*func)(NSSize size));						// Called when the window is resized

// Options
void MDRebuildShaders();													// Rebuilds the shaders (needs to be called when a light is added or removed)
void MDSetDefaultPhysics(BOOL physics);										// Sets whether to use default physics

// Scene
void MDLoadScene(NSString* scene);
NSString* MDLoadedScene();													// Name of the current scene

// Graphics
void MDSetGLResolution(NSSize resolution);
NSSize MDGLResolution();
void MDSetFullScreen(BOOL full);
BOOL MDFullScreen();
void MDSetAntialias(unsigned int antialias);								// 1, 2, 4, 8, 16 MSAA
unsigned int MDAntialias();
void MDSetFPS(unsigned int fps);
unsigned int MDFPS();
double MDElapsedTime();														// Elapsed time from the last frame in milliseconds

// Physics
void MDSetGravity(MDVector3 gravity);
MDVector3 MDGravity();
void MDSetLinearVelocity(MDObject* obj, MDVector3 vel);
MDVector3 MDLinearVelocity(MDObject* obj);
void MDSetAngularVelocity(MDObject* obj, MDVector3 vel);
MDVector3 MDAngularVelocity(MDObject* obj);
void MDSetObjectGravity(MDObject* obj, MDVector3 gravity);
MDVector3 MDObjectGravity(MDObject* obj);
void MDSetObjectPosition(MDObject* obj, MDVector3 pos);
MDVector3 MDObjectPosition(MDObject* obj);
void MDSetObjectRotation(MDObject* obj, MDVector3 axis, float angle);
MDVector3 MDObjectRotation(MDObject* obj, float* angle);
void MDObjectEnable(MDObject* obj);
void MDObjectDisable(MDObject* obj);
BOOL MDIsObjectEnabled(MDObject* obj);
void MDSetCollisionFunction(void (*func)(MDObject* obj1, MDObject* obj2, MDVector3 contactPoint, MDVector3 normal));

// Skybox
void MDSetSkyboxDistance(float distance);
float MDSkyboxDistance();
void MDSetSkyboxColor(MDVector4 color);
MDVector4 MDSkyboxColor();
void MDSetSkyboxCorrection(float correction);
float MDSkyboxCorrection();
void MDSetSkyboxVisible(BOOL visible);
BOOL MDSkyboxVisible();
void MDSetSkyboxImage(NSString* name);
NSString* MDSkyboxImage();

// Math Functions
unsigned int MDPick(NSPoint point);															// Returns the index of an object at that point in the window
MDVector3 MDRotate(MDVector3 point, MDVector3 around, float xrot, float yrot, float zrot);	// Rotates around x, y, then z axes
MDVector3 MDRotateB(MDVector3 point, MDVector3 around, float xrot, float yrot, float zrot);	// Rotate backwards
MDVector3 MDRotateX(MDVector3 point, MDVector3 around, float xrot);							// Rotate around x-axis
MDVector3 MDRotateY(MDVector3 point, MDVector3 around, float yrot);							// Rotate around y-axis
MDVector3 MDRotateZ(MDVector3 point, MDVector3 around, float zrot);							// Rotate around z-axis
MDVector3 MDRotateAxis(MDVector3 point, MDVector3 axis, float angle);						// Rotates around an axis
MDVector3 MDEulerToAxis(MDVector3 rot, float* angle);										// Returns an axis with an angle given a euler (x, y, z) rotation
MDRect MDBoundingBoxRotate(MDObject* obj);													// Returns the bounding box of a rotated object
std::vector<MDVector3> MDBoundingBox(MDObject* obj);										// Returns the rotated bounding box of an object

// Tweening - time goes from 0 to 1
// Returns a value from 0 to 1
float MDTweenLinear(float time);
float MDTweenEaseInQuadratic(float time);
float MDTweenEaseOutQuadratic(float time);
float MDTweenEaseInOutQuadratic(float time);
float MDTweenEaseInCubic(float time);
float MDTweenEaseOutCubic(float time);
float MDTweenEaseInOutCubic(float time);
float MDTweenEaseInQuartic(float time);
float MDTweenEaseOutQuartic(float time);
float MDTweenEaseInOutQuartic(float time);
float MDTweenEaseInQuintic(float time);
float MDTweenEaseOutQuintic(float time);
float MDTweenEaseInOutQuintic(float time);
float MDTweenEaseInSin(float time);
float MDTweenEaseOutSin(float time);
float MDTweenEaseInOutSin(float time);
float MDTweenEaseInExp(float time);								// 2^10
float MDTweenEaseOutExp(float time);							// 2^10
float MDTweenEaseInOutExp(float time);							// 2^10
float MDTweenEaseInExpX(float time, float base, float exp);		// base^exp
float MDTweenEaseOutExpX(float time, float base, float exp);	// base^exp
float MDTweenEaseInOutExpX(float time, float base, float exp);	// base^exp
float MDTweenEaseInCircle(float time);
float MDTweenEaseOutCircle(float time);
float MDTweenEaseInOutCircle(float time);
float MDTweenEaseInElastic(float time);		
float MDTweenEaseOutElastic(float time);	
float MDTweenEaseInOutElastic(float time);	
float MDTweenEaseInBack(float time);		
float MDTweenEaseOutBack(float time);		
float MDTweenEaseInOutBack(float time);		
float MDTweenEaseInBounce(float time);		
float MDTweenEaseOutBounce(float time);		
float MDTweenEaseInOutBounce(float time);
