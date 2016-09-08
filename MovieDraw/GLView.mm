/*
 * Original Windows comment:
 * "This code was created by Jeff Molofee 2000
 * A HUGE thanks to Fredric Echols for cleaning up
 * and optimizing the base code, making it more flexible!
 * If you've found this code useful, please let me know.
 * Visit my site at nehe.gamedev.net"
 * 
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* GLView.m */

/*** Remember to include the license for AssImp ***/

/* Bugs
	* Opening animations / properties / physic properties and then chaning the number of objects (adding, copy / paste, something with set objects) causes the animations not to work anymore because the "propObj" in no longer in the scene, because a new copy of it was made.
 
 
	* Crashes sometimes when trying to add a shape immediately after removing a model (?)
	* Undoing for anything that changes the instance doesn't work - need to change from set object to set instance
	***** CHANGE lookObj / instance / obj FROM PROPERTIES TO THEIR OWN METHODS IN OTHER OBJECTS ***** - causes memory leak
	* Option + object click doesn't have correct orientations (?)
	* Animations sometimes don't work after exporting - don't care
	* Animations don't work after combining objects - don't care
	* If you change the name of the default scene, it doesn't update the name of the default scene to load on compile, so it doesn't load correctly
 
 * Split up MDTypes into many files in a MDTypes Folder
 
 * MDSound class (Other Object)
	* Can place it somewhere in the scene with attenuation
	* Can set it to a resource from the project
	* Some other properties like min volume, max volume, cutoff distance, play from beginning, repeats, speed, etc...
	* Need to make a cool music note model for it
  
 * Only save changed data
 * Implement vertex sets option - make change color only for verticies only abailable for faces with vertex sets
 * Change texture paths for objects from being hardcoded to just the last path directory so it works from all locations (append resources path) - (done I think?)
 
 * Update Particle Engine to be in GUI corectly with emitters and stuff
 
 * Skybox
	* Add texture transition (maybe don't need this if the bottom of the image is night so you could just rotate the image)
	* Add rotation
 
 * Project Properties
	* Multisampling change doesn't work
 * Liquids (like water) - particles?
 * Physics using bullet - MOSTLY IMPLEMENTED
	* Add collision callbacks - [ obj setCollisionCallback:function ] - done
	* Add more MovieDraw functions to change the physics state
	* Allow for different collisions shapes ((bounding) capsule, ...)
 * Scripts (maybe)
	* Have option to add scripts to instance which can be compiled as c or obj-c (depending on project type) and called with a [ obj performScript:@"ScriptName" ]
 * Particles
	* More options (inner color (change too), size change, tweening (linear, quadratic))
	* More efficient
 * Menu item under object menu
	* replace model from file - so you can keep properties / translations
 * Scenes
	* Scene properites (for cutscenes and whatnot) (also include physics scene properties (like gravity))
 * Color picker
 * MOSTLY IMPLEMENTED (A few bugs) - codeview
	* bug - automatically makes things like 1/3 into one character
	* bug - lets other fonts in
	* copy, paste, cut commands
	* autocompletion - like xcode (WORK IN PROGRESS)
	* line numbers
	* tabbed documents
	* have it be in a window with other information from the project (like xcode)
 * undo
	* add undo support to pretty much everything
 * 3D
	* make the move arrows scale more appropriately (distance from object, not distance from origin?)
 * Models - MOSTLY IMPLEMENTED (no animation support)
	* When importing a model, have the images copied to the resources (or resources/images) folder
	* Export scene to model (assimp)
 * Improvements in GLView
	* Right click menu (maybe)
 * Lightmaps
	* Faster
	* Better
	* Radiosity
 * Shaders
	* More efficient
	* Allow users to make them without messing up lights
	* Effects
		* Depth of Field
		* Motion Blur
		* Bloom / Glow
 * iPhone Dev
	* OpenGL ES framework
	* allow iPhone or Mac Project
	* build and compile for iPhone
	* mimic XCode Properties
	* Launch with iPhone Simulator Or Allow to build app that can then be put on a jailbroken phone
 * Windows Dev
	* Make a C++ framework
	* allow iPhone or Mac (Obj-C) or Mac/Windows/iPhone (C++) Project
	* build and compile for Windows on windows app
	* mimic XCode Properties
 * 3D text (fix)
	* Hough Line Transformation - maybe
 * Debugger - MOSTLY IMPLEMENTED
	* GDB
	* GUI incorperated into codeview window (need better detection of mouse over and to show structs not as only "{". Also need to show properites of objective objects)
	* Console window
 * Build Commands
	* Clean
	* Compile - change to compile only edited things / things dependent on other edited things
 * Change "App Resources"
	* Has compiled .o files instead of .h and .mm
 * Adding Resources (images, music, ...) (done?)
	* have them open in their own application?
 * Framework
	* Mouse Scroll Function (like mousedown and processkeys)
	* Quaternion to Euler
*/

#import "GLView.h"
#define GL_DO_NOT_WARN_IF_MULTI_GL_VERSION_HEADERS_INCLUDED	// Gets rid of a warning
#import <OpenGL/gl3.h>
#import <OpenGL/gl3ext.h>
#import "GLString.h"
#import "MDObjectTools.h"
#import "Controller.h"
#import "MDGUI.h"
#import "ShapeInterpreter.h"

std::vector<ImageWithName> loadedImages;

MDVector3 translationPoint = MDVector3Create(0, 5, -20);
MDVector3 backupTrans = translationPoint;
MDVector3 targetTrans = translationPoint;
MDVector3 lookPoint = MDVector3Create(0, 5, 0);
MDVector3 backupLook = MDVector3Create(0, 0, 0);
MDVector3 targetLook = MDVector3Create(0, 0, 0);
NSMutableArray* oldObject = nil;
MDMove move = MD_NONE;
float targetMove = 0;
float tempMove = 0;
float initialMove = 0;
unsigned long moveIndex = 0;
MDVector4 initialColor;
MDVector4 targetColor;
MDVertex moveVert = MD_X;
MDPoint* targetPoint = nil;
id oldOther = nil;
BOOL inMotion = FALSE;
MDVector3 shapeDown;
MDVector3 shapeDrag;
BOOL makeDisplayLists = TRUE;
std::vector<unsigned int> lengthTexts;
BOOL rebuildShaders = FALSE;

void InitColor(float red, float green, float blue, float alpha)
{
	memset(&initialColor, 0, sizeof(initialColor));
	initialColor.x = red;
	initialColor.y = green;
	initialColor.z = blue;
	initialColor.w = alpha;
}

void SetColor(float red, float green, float blue, float alpha)
{
	memset(&targetColor, 0, sizeof(targetColor));
	targetColor.x = red;
	targetColor.y = green;
	targetColor.z = blue;
	targetColor.w = alpha;
}

@interface GLView (InternalMethods)
- (NSOpenGLPixelFormat *) createPixelFormat:(NSRect)frame;
- (BOOL) initGL;
- (void) setupVAOs;
@end

@implementation GLView

+ (void) calculateAlphaObjects
{
	[ alphaObjects removeAllIndexes ];
	for (unsigned long z = 0; z < [ objects count ]; z++)
	{
		if ([ objects[z] colorMultiplier ].w < 0.99)
		{
			[ alphaObjects addIndex:z ];
			continue;
		}
		MDInstance* inst = [ objects[z] instance ];
		for (unsigned long y = 0; y < [ inst numberOfMeshes ]; y++)
		{
			MDMesh* mesh = [ inst meshAtIndex:y ];
			if ([ mesh color ].w < 0.99)
			{
				[ alphaObjects addIndex:z ];
				break;
			}
		}
	}
}

- (instancetype) initWithFrame:(NSRect)frame colorBits:(int)numColorBits
		   depthBits:(int)numDepthBits fullscreen:(BOOL)runFullScreen
{
	NSOpenGLPixelFormat *pixelFormat;
	
	colorBits = numColorBits;
	depthBits = numDepthBits;
	pixelFormat = [ self createPixelFormat:frame ];
	if( pixelFormat != nil )
	{
		self = [ super initWithFrame:frame pixelFormat:pixelFormat ];
		if( self )
		{
			SetLoadingContext([ [ NSOpenGLContext alloc ] initWithFormat:pixelFormat shareContext:[ self openGLContext ] ]);
			
			[ [ self openGLContext ] makeCurrentContext ];
			[ self reshape ];
			if( ![ self initGL ] )
			{
				[ self clearGLContext ];
				return nil;
			}
			truefps = 60;
			fpsTimer = [ NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateFPS) userInfo:nil repeats:YES ];
			[ self addTrackingRect:[ self bounds ] owner:self userData:nil assumeInside:NO ];
			
			[ self loadModel:@"Camera.mdm" ];
			[ self loadModel:@"DirectionalLight.mdm" ];
			[ self loadModel:@"PointLight.mdm" ];
			[ self loadModel:@"SpotLight.mdm" ];
			[ self loadModel:@"Sound.mdm" ];
			
			objects = [ [ NSMutableArray alloc ] init ];
			alphaObjects = [ [ NSMutableIndexSet alloc ] init ];
			instances = [ [ NSMutableArray alloc ] init ];
			selected = [ [ MDSelection alloc ] init ];
			otherObjects = [ [ NSMutableArray alloc ] init ];
			
			[ views removeAllObjects ];
			MDRotationBox* box = [ [ MDRotationBox alloc ] initWithFrame:MakeRect(0.95, 0.67, -2, 0.2, 0.2, 0.2) background:[ NSColor colorWithCalibratedRed:0.7 green:0.7 blue:0.7 alpha:0.7 ] ];
			[ box setIdentity:@"Rotation Box" ];
			
			previousTime = 0;
			frameDuration = 0;
			
			/*cameraPoint = MDVector3Create(0, 0, -20);
			cameraLook = MDVector3Create(0, 0, 0);
			cameraOrientation = 0;
			cameraRotation = MDVector3Create(0, 0, 0);*/
			
			[ self setupShaders ];
			[ self setupVAOs ];
		}
	}
	else
		self = nil;
	
	return self;
}

- (void) finishTranslations
{
	if (move == MD_NONE)
		return;
	makeDisplayLists = TRUE;
	
	id obj = [ selected fullValueAtIndex:0 ];
	BOOL objReplace = TRUE;
	BOOL otherReplace = FALSE;
	if (move == MD_MOVE)
	{
		if (moveVert == MD_X)
			[ obj setTranslateX:targetMove ];
		else if (moveVert == MD_Y)
			[ obj setTranslateY:targetMove ];
		else
			[ obj setTranslateZ:targetMove ];
		commandFlag |= UPDATE_INFO;
	}
	else if (move == MD_SIZE)
	{
		if (moveVert == MD_X)
			[ obj setScaleX:targetMove ];
		else if (moveVert == MD_Y)
			[ obj setScaleY:targetMove ];
		else
			[ obj setScaleZ:targetMove ];
		commandFlag |= UPDATE_INFO;
	}
	else if (move == MD_ROTATE)
	{
		MDVector3 rotateAxis = [ obj rotateAxis ];
		/*if (moveVert == MD_X)
			[ obj setRotateX:targetMove ];
		else if (moveVert == MD_Y)
			[ obj setRotateY:targetMove ];
		else
			[ obj setRotateZ:targetMove ];*/
		if (moveVert == MD_X)
			rotateAxis.x = targetMove;
		else if (moveVert == MD_Y)
			rotateAxis.y = targetMove;
		else if (moveVert == MD_Z)
			rotateAxis.z = targetMove;
		[ obj setRotateAxis:rotateAxis ];
		commandFlag |= UPDATE_INFO;
	}
	else if (move == MD_ROTATE_ANGLE)
	{
		[ obj setRotateAngle:targetMove ];
		commandFlag |= UPDATE_INFO;
	}
	/*else if (move == MD_ROTATE_POINT)
	{
		if (moveVert == MD_X)
			[ obj setRotatePoint:MDVector3Create(targetMove, [ obj rotatePoint ].y, [ obj rotatePoint ].z) ];
		else if (moveVert == MD_Y)
			[ obj setRotatePoint:MDVector3Create([ obj rotatePoint ].x, targetMove, [ obj rotatePoint ].z) ];
		else
			[ obj setRotatePoint:MDVector3Create([ obj rotatePoint ].x, [ obj rotatePoint ].y, targetMove) ];
		commandFlag |= UPDATE_INFO;
	}*/
	else if (move == MD_POINT)
	{
		if (moveVert == MD_X)
			[ obj setTranslateX:targetMove ];
		else if (moveVert == MD_Y)
			[ obj setTranslateY:targetMove ];
		else
			[ obj setTranslateZ:targetMove ];
		[ [ obj instance ] setMidPoint:MDVector3Create(0, 0, 0) ];
		[ [ obj instance ] setupVBO ];
		commandFlag |= UPDATE_INFO;
	}
	else if (move == MD_POINT_MID)
	{
		if (moveVert == MD_X)
			[ obj setX:targetMove ];
		else if (moveVert == MD_Y)
			[ obj setY:targetMove ];
		else
			[ obj setZ:targetMove ];
		[ [ obj instance ] setMidPoint:MDVector3Create(0, 0, 0) ];
		[ [ obj instance ] setupVBO ];
		commandFlag |= UPDATE_INFO;
	}
	else if (move == MD_POINT_NORMAL)
	{
		if (moveVert == MD_X)
			[ obj setNormalX:targetMove ];
		else if (moveVert == MD_Y)
			[ obj setNormalY:targetMove ];
		else
			[ obj setNormalZ:targetMove ];
		[ [ obj instance ] setupVBO ];
		commandFlag |= UPDATE_INFO;
	}
	else if (move == MD_POINT_TEXTURE)
	{
		if (moveVert == MD_X)
			[ obj setTextureCoordX:targetMove ];
		else if (moveVert == MD_Y)
			[ obj setTextureCoordY:targetMove ];
		[ [ obj instance ] setupVBO ];
		commandFlag |= UPDATE_INFO;
	}
	else if (move == MD_NORMAL && targetPoint)
	{
		if (moveVert == MD_X)
			[ targetPoint setNormalX:targetMove ];
		else if (moveVert == MD_Y)
			[ targetPoint setNormalY:targetMove ];
		else
			[ targetPoint setNormalZ:targetMove ];
		commandFlag |= UPDATE_INFO;
	}
	else if (move == MD_SCENE)
	{
		MDVector3 point = translationPoint;
		if (moveVert == MD_X)
		{
			translationPoint.x = initialMove;
			point.x = targetMove;
		}
		else if (moveVert == MD_Y)
		{
			translationPoint.y = initialMove;
			point.y = targetMove;
		}
		else
		{
			translationPoint.z = initialMove;
			point.z = targetMove;
		}
		[ undoManager setActionName:@"Scene Translation" ];
		[ Controller setTranslationPoint:point ];
		objReplace = FALSE;
		commandFlag |= UPDATE_SCENE_INFO;
	}
	else if (move == MD_SCENE)
	{
		if (moveVert == MD_X)
			lookPoint.x = targetMove;
		else if (moveVert == MD_Y)
			lookPoint.y = targetMove;
		else
			lookPoint.z = targetMove;
		objReplace = FALSE;
		commandFlag |= UPDATE_SCENE_INFO;
	}
	else if (move == MD_SCENE_WHOLE)
	{
		translationPoint = targetTrans;
		lookPoint = targetLook;
		objReplace = FALSE;
		commandFlag |= UPDATE_SCENE_INFO;
	}
	else if (move == MD_POINT_MOVE && targetPoint)
	{
		if (moveVert == MD_X)
			[ targetPoint setX:targetMove ];
		else if (moveVert == MD_Y)
			[ targetPoint setY:targetMove ];
		else
			[ targetPoint setZ:targetMove ];
		commandFlag |= UPDATE_INFO;
	}
	else if (move == MD_POINT_COLOR || move == MD_OBJECT_COLOR)
	{
		id reciever = targetPoint;
		if (move == MD_OBJECT_COLOR)
			reciever = obj;
		/*if (currentMode == MD_VERTEX_MODE)
		{
			MDInstance* recObj = [ reciever instance ];
			for (unsigned long q = 0; q < [ recObj numberOfPoints ]; q++)
			{
				MDPoint* p = [ recObj pointAtIndex:q ];
				if (p.x == ((MDPoint*)reciever).x && p.y == ((MDPoint*)reciever).y && p.z == ((MDPoint*)reciever).z && p != reciever)
					[ p setMidColor:targetColor ];
			}
		}*/
		[ reciever setMidColor:targetColor ];
		commandFlag |= UPDATE_INFO;
	}
	else if (move == MD_OBJECT_COLOR_MULTIPLY)
	{
		[ obj setColorMultiplier:targetColor ];
		commandFlag |= UPDATE_INFO;
	}
	else if (move == MD_SPECULAR_COLOR)
	{
		[ obj setSpecularColor:targetColor ];
		commandFlag |= UPDATE_INFO;
		
	}
	else if (move == MD_SHININESS)
	{
		[ obj setShininess:targetMove ];
		commandFlag |= UPDATE_INFO;
	}
	else if (move == MD_CAMERA_MID)
	{
		id other = nil;
		for (int z = 0; z < [ otherObjects count ]; z++)
		{
			if ([ otherObjects[z] selected ] || ([otherObjects[z] isKindOfClass:[ MDCamera class ] ] && [ otherObjects[z] lookSelected ]))
			{
				other = otherObjects[z];
				break;
			}
		}
		if (!other)
			return;
		if ([ other isKindOfClass:[ MDCamera class ] ])
		{
			MDCamera* camera = other;
			MDVector3 point = [ camera midPoint ];
			if (moveVert == MD_X)
				point.x = targetMove;
			else if (moveVert == MD_Y)
				point.y = targetMove;
			else
				point.z = targetMove;
			[ camera setMidPoint:point ];
			[ [ camera obj ] setTranslateX:point.x ];
			[ [ camera obj ] setTranslateY:point.y ];
			[ [ camera obj ] setTranslateZ:point.z ];
		}
		else if ([ other isKindOfClass:[ MDLight class ] ])
		{
			MDLight* light = other;
			MDVector3 point = [ light position ];
			if (moveVert == MD_X)
				point.x = targetMove;
			else if (moveVert == MD_Y)
				point.y = targetMove;
			else
				point.z = targetMove;
			[ light setPosition:point ];
			[ [ light obj ] setTranslateX:point.x ];
			[ [ light obj ] setTranslateY:point.y ];
			[ [ light obj ] setTranslateZ:point.z ];
		}
		else if ([ other isKindOfClass:[ MDParticleEngine class ] ])
		{
			MDParticleEngine* engine = other;
			MDVector3 point = [ engine position ];
			if (moveVert == MD_X)
				point.x = targetMove;
			else if (moveVert == MD_Y)
				point.y = targetMove;
			else
				point.z = targetMove;
			[ engine setPosition:point ];
		}
		commandFlag |= UPDATE_OTHER_INFO;
		objReplace = FALSE;
		otherReplace = TRUE;
	}
	else if (move == MD_CAMERA_LOOK)
	{
		id other = nil;
		for (int z = 0; z < [ otherObjects count ]; z++)
		{
			if ([ otherObjects[z] selected ] || ([otherObjects[z] isKindOfClass:[ MDCamera class ] ] && [ otherObjects[z] lookSelected ]))
			{
				other = otherObjects[z];
				break;
			}
		}
		if (!other)
			return;
		if ([ other isKindOfClass:[ MDCamera class ] ])
		{
			MDCamera* camera = other;
			MDVector3 point = [ camera lookPoint ];
			if (moveVert == MD_X)
				point.x = targetMove;
			else if (moveVert == MD_Y)
				point.y = targetMove;
			else
				point.z = targetMove;
			[ camera setLookPoint:point ];
		}
		else if ([ other isKindOfClass:[ MDLight class ] ])
		{
			MDLight* light = other;
			MDVector3 point = [ light spotDirection ];
			if (moveVert == MD_X)
				point.x = targetMove;
			else if (moveVert == MD_Y)
				point.y = targetMove;
			else
				point.z = targetMove;
			[ light setSpotDirection:point ];
		}
		commandFlag |= UPDATE_OTHER_INFO;
		objReplace = FALSE;
		otherReplace = TRUE;
	}
	else if (move == MD_CAMERA_OR)
	{
		MDCamera* camera = nil;
		for (int z = 0; z < [ otherObjects count ]; z++)
		{
			if ([ otherObjects[z] selected ] || ([ otherObjects[z] isKindOfClass:[ MDCamera class ] ] && [ otherObjects[z] lookSelected ]))
			{
				camera = otherObjects[z];
				break;
			}
		}
		[ camera setOrientation:targetMove ];
		commandFlag |= UPDATE_OTHER_INFO;
		objReplace = FALSE;
		otherReplace = TRUE;
	}
	else if (move == MD_LIGHT_AMBIENT)
	{
		MDLight* light = nil;
		for (int z = 0; z < [ otherObjects count ]; z++)
		{
			if ([ otherObjects[z] selected ])
			{
				light = otherObjects[z];
				break;
			}
		}
		MDVector4 color = [ light ambientColor ];
		if (moveVert == MD_X)
			color.x = targetMove;
		else if (moveVert == MD_Y)
			color.y = targetMove;
		else if (moveVert == MD_Z)
			color.z = targetMove;
		else
			color.w = targetMove;
		[ light setAmbientColor:color ];
		commandFlag |= UPDATE_OTHER_INFO;
		objReplace = FALSE;
		otherReplace = TRUE;
	}
	else if (move == MD_LIGHT_DIFFUSE)
	{
		MDLight* light = nil;
		for (int z = 0; z < [ otherObjects count ]; z++)
		{
			if ([ otherObjects[z] selected ])
			{
				light = otherObjects[z];
				break;
			}
		}
		MDVector4 color = [ light diffuseColor ];
		if (moveVert == MD_X)
			color.x = targetMove;
		else if (moveVert == MD_Y)
			color.y = targetMove;
		else if (moveVert == MD_Z)
			color.z = targetMove;
		else
			color.w = targetMove;
		[ light setDiffuseColor:color ];
		commandFlag |= UPDATE_OTHER_INFO;
		objReplace = FALSE;
		otherReplace = TRUE;
	}
	else if (move == MD_LIGHT_SPECULAR)
	{
		MDLight* light = nil;
		for (int z = 0; z < [ otherObjects count ]; z++)
		{
			if ([ otherObjects[z] selected ])
			{
				light = otherObjects[z];
				break;
			}
		}
		MDVector4 color = [ light specularColor ];
		if (moveVert == MD_X)
			color.x = targetMove;
		else if (moveVert == MD_Y)
			color.y = targetMove;
		else if (moveVert == MD_Z)
			color.z = targetMove;
		else
			color.w = targetMove;
		[ light setSpecularColor:color ];
		commandFlag |= UPDATE_OTHER_INFO;
		objReplace = FALSE;
		otherReplace = TRUE;
	}
	else if (move == MD_LIGHT_SPOT)
	{
		MDLight* light = nil;
		for (int z = 0; z < [ otherObjects count ]; z++)
		{
			if ([ otherObjects[z] selected ])
			{
				light = otherObjects[z];
				break;
			}
		}
		if (moveVert == MD_X)
			[ light setSpotExp:targetMove ];
		else if (moveVert == MD_Y)
			[ light setSpotCut:targetMove ];
		else if (moveVert == MD_Z)
			[ light setSpotAngle:targetMove ];
		commandFlag |= UPDATE_OTHER_INFO;
		objReplace = FALSE;
		otherReplace = TRUE;
	}
	else if (move == MD_LIGHT_ATTENUATION)
	{
		MDLight* light = nil;
		for (int z = 0; z < [ otherObjects count ]; z++)
		{
			if ([ otherObjects[z] selected ])
			{
				light = otherObjects[z];
				break;
			}
		}
		if (moveVert == MD_X)
			[ light setConstAtt:targetMove ];
		else if (moveVert == MD_Y)
			[ light setLinAtt:targetMove ];
		else if (moveVert == MD_Z)
			[ light setQuadAtt:targetMove ];
		commandFlag |= UPDATE_OTHER_INFO;
		objReplace = FALSE;
		otherReplace = TRUE;
	}
	else if (move == MD_LIGHT_SHADOW_ENABLE)
	{
		MDLight* light = nil;
		for (int z = 0; z < [ otherObjects count ]; z++)
		{
			if ([ otherObjects[z] selected ])
			{
				light = otherObjects[z];
				break;
			}
		}
		
		int value = round(targetMove);
		if (value > 1)
			value = 1;
		else if (value < 0)
			value = 0;
		[ light setEnableShadows:value ];
		
		commandFlag |= UPDATE_OTHER_INFO;
		objReplace = FALSE;
		otherReplace = TRUE;
	}
	else if (move == MD_LIGHT_STATIC_ENABLE)
	{
		MDLight* light = nil;
		for (int z = 0; z < [ otherObjects count ]; z++)
		{
			if ([ otherObjects[z] selected ])
			{
				light = otherObjects[z];
				break;
			}
		}
		
		int value = round(targetMove);
		if (value > 1)
			value = 1;
		else if (value < 0)
			value = 0;
		[ light setIsStatic:value ];
		
		commandFlag |= UPDATE_OTHER_INFO;
		objReplace = FALSE;
		otherReplace = TRUE;
	}
	else if (move == MD_PARTICLE_START)
	{
		MDParticleEngine* engine = nil;
		for (int z = 0; z < [ otherObjects count ]; z++)
		{
			if ([ otherObjects[z] selected ])
			{
				engine = otherObjects[z];
				break;
			}
		}
		MDVector4 color = [ engine startColor ];
		if (moveVert == MD_X)
			color.x = targetMove;
		else if (moveVert == MD_Y)
			color.y = targetMove;
		else if (moveVert == MD_Z)
			color.z = targetMove;
		else
			color.w = targetMove;
		[ engine setStartColor:color ];
		commandFlag |= UPDATE_OTHER_INFO;
		objReplace = FALSE;
		otherReplace = TRUE;
	}
	else if (move == MD_PARTICLE_END)
	{
		MDParticleEngine* engine = nil;
		for (int z = 0; z < [ otherObjects count ]; z++)
		{
			if ([ otherObjects[z] selected ])
			{
				engine = otherObjects[z];
				break;
			}
		}
		MDVector4 color = [ engine endColor ];
		if (moveVert == MD_X)
			color.x = targetMove;
		else if (moveVert == MD_Y)
			color.y = targetMove;
		else if (moveVert == MD_Z)
			color.z = targetMove;
		else
			color.w = targetMove;
		[ engine setEndColor:color ];
		commandFlag |= UPDATE_OTHER_INFO;
		objReplace = FALSE;
		otherReplace = TRUE;
	}
	else if (move == MD_PARTICLE_NUMBER)
	{
		MDParticleEngine* engine = nil;
		for (int z = 0; z < [ otherObjects count ]; z++)
		{
			if ([ otherObjects[z] selected ])
			{
				engine = otherObjects[z];
				break;
			}
		}
		[ engine setNumberOfParticles:round(targetMove) ];
		commandFlag |= UPDATE_OTHER_INFO;
		objReplace = FALSE;
		otherReplace = TRUE;
	}
	else if (move == MD_PARTICLE_SIZE)
	{
		MDParticleEngine* engine = nil;
		for (int z = 0; z < [ otherObjects count ]; z++)
		{
			if ([ otherObjects[z] selected ])
			{
				engine = otherObjects[z];
				break;
			}
		}
		[ engine setParticleSize:targetMove ];
		commandFlag |= UPDATE_OTHER_INFO;
		objReplace = FALSE;
		otherReplace = TRUE;
	}
	else if (move == MD_PARTICLE_LIFE)
	{
		MDParticleEngine* engine = nil;
		for (int z = 0; z < [ otherObjects count ]; z++)
		{
			if ([ otherObjects[z] selected ])
			{
				engine = otherObjects[z];
				break;
			}
		}
		[ engine setParticleLife:round(targetMove) ];
		commandFlag |= UPDATE_OTHER_INFO;
		objReplace = FALSE;
		otherReplace = TRUE;
	}
	else if (move == MD_PARTICLE_VELOCITIES)
	{
		MDParticleEngine* engine = nil;
		for (int z = 0; z < [ otherObjects count ]; z++)
		{
			if ([ otherObjects[z] selected ])
			{
				engine = otherObjects[z];
				break;
			}
		}
		MDVector3 vel = [ engine velocities ];
		if (moveVert == MD_X)
			vel.x = targetMove;
		else if (moveVert == MD_Y)
			vel.y = targetMove;
		else
			vel.z = targetMove;
		[ engine setVelocities:vel ];
		commandFlag |= UPDATE_OTHER_INFO;
		objReplace = FALSE;
		otherReplace = TRUE;
	}
	else if (move == MD_CURVE_POINT)
	{
		MDCurve* curve = nil;
		for (int z = 0; z < [ otherObjects count ]; z++)
		{
			if ([ otherObjects[z] selected ])
			{
				curve = otherObjects[z];
				break;
			}
		}
		std::vector<MDVector3> points = *[ curve curvePoints ];
		if (moveIndex < points.size())
		{
			if (moveVert == MD_X)
				points[moveIndex].x = targetMove;
			if (moveVert == MD_Y)
				points[moveIndex].y = targetMove;
			if (moveVert == MD_Z)
				points[moveIndex].z = targetMove;
		}
		[ curve setPoints:points ];
		//commandFlag |= UPDATE_OTHER_INFO;
	}
	else if (move == MD_VISIBLE)
	{
		id other = nil;
		for (int z = 0; z < [ otherObjects count ]; z++)
		{
			if ([ otherObjects[z] selected ] || ([ otherObjects[z] isKindOfClass:[ MDCamera class ] ] && [ otherObjects[z] lookSelected ]))
			{
				other = otherObjects[z];
				break;
			}
		}
		
		int value = round(targetMove);
		if (value > 1)
			value = 1;
		else if (value < 0)
			value = 0;
		[ other setShow:value ];
		
		commandFlag |= UPDATE_OTHER_INFO;
		objReplace = FALSE;
		otherReplace = TRUE;
	}
	else if (move == MD_USE)
	{
		MDCamera* camera = nil;
		unsigned int row = -1;
		for (int z = 0; z < [ otherObjects count ]; z++)
		{
			if ([ otherObjects[z] selected ] || ([ otherObjects[z] isKindOfClass:[ MDCamera class ] ] && [ otherObjects[z] lookSelected ]))
			{
				camera = otherObjects[z];
				row = z;
				break;
			}
		}
		
		int value = round(targetMove);
		if (value > 1)
			value = 1;
		else if (value < 0)
			value = 0;
		[ camera setUse:value ];
		currentCamera = (value ? row : (unsigned long)-1);
		[ ViewForIdentity(@"Rotation Box") setVisible:!value ];
		
		commandFlag |= UPDATE_OTHER_INFO;
		objReplace = FALSE;
		otherReplace = TRUE;
	}
	
	if (oldObject && objReplace)
	{
		if (currentMode == MD_OBJECT_MODE)
		{
			MDObject* newObj = [ [ MDObject alloc ] initWithObject:[ selected selectedValueAtIndex:0 ][@"Object"] ];
			unsigned long indexObj = [ objects indexOfObject:[ selected selectedValueAtIndex:0 ][@"Object"] ];
			unsigned long pointIndex = NSNotFound;
			if (indexObj != NSNotFound)
			{
				pointIndex = [ [ [ selected selectedValueAtIndex:0 ][@"Object"] points ] indexOfObject:[ selected selectedValueAtIndex:0 ][@"Point"] ];
			}
			objects[indexObj] = oldObject[0];
			[ undoManager setActionName:@"Translation" ];
			[ Controller setMDObject:newObj atIndex:indexObj faceIndex:NSNotFound edgeIndex:NSNotFound pointIndex:pointIndex selectionIndex:0 ];
		}
		else if (currentMode == MD_VERTEX_MODE)
		{
			unsigned long numberOfObjects = [ selected count ];
			MDInstance* inst[numberOfObjects];
			unsigned long instIndex[numberOfObjects];
			for (int z = 0; z < numberOfObjects; z++)
			{
				MDObject* obj = [ selected selectedValueAtIndex:z ][@"Object"];
				MouseUp(obj);
				instIndex[z] = [ instances indexOfObject:[ obj instance ] ];
				inst[z] = [ [ MDInstance alloc ] initWithInstance:[ obj instance ] ];
			}
			[ undoManager setActionName:@"Translation" ];
			for (int z = 0; z < numberOfObjects; z++)
			{
				MDInstance* instance = instances[instIndex[z]];
				for (unsigned long q = 0; q < [ instance numberOfPoints ]; q++)
					[ instance setPoint:[ oldObject[(z * 2) + 1] points ][q] atIndex:q ];
				
				[ Controller setMDInstance:inst[z] atIndex:instIndex[z] ];
			}
		}
	}
	if (otherReplace && oldOther)
	{
		id other = nil;
		for (int z = 0; z < [ otherObjects count ]; z++)
		{
			if ([ otherObjects[z] selected ] || ([otherObjects[z] isKindOfClass:[ MDCamera class ] ] && [ otherObjects[z] lookSelected ]))
			{
				other = otherObjects[z];
				break;
			}
		}
		if (other && [ other isKindOfClass:[ MDCamera class ] ])
		{
			MDCamera* camera = other;
			MDCamera* currentCam = [ [ MDCamera alloc ] initWithMDCamera:camera ];
			unsigned long cIndex = [ otherObjects indexOfObject:camera ];
			otherObjects[[ otherObjects indexOfObject:camera ]] = oldOther;
			oldOther = nil;
			[ undoManager setActionName:@"Translation" ];
			[ Controller setOtherObject:currentCam atIndex:cIndex ];
		}
		else if (other && [ other isKindOfClass:[ MDLight class ] ])
		{
			MDLight* light = other;
			MDLight* currentLight = [ [ MDLight alloc ] initWithMDLight:light ];
			unsigned long cIndex = [ otherObjects indexOfObject:light ];
			otherObjects[[ otherObjects indexOfObject:light ]] = oldOther;
			oldOther = nil;
			[ undoManager setActionName:@"Translation" ];
			[ Controller setOtherObject:currentLight atIndex:cIndex ];
		}
		else if (other && [ other isKindOfClass:[ MDParticleEngine class ] ])
		{
			MDParticleEngine* engine = other;
			MDParticleEngine* currentEngine = [ [ MDParticleEngine alloc ] initWithMDParticleEngine:engine ];
			unsigned long cIndex = [ otherObjects indexOfObject:engine ];
			otherObjects[[ otherObjects indexOfObject:engine ]] = oldOther;
			oldOther = nil;
			[ undoManager setActionName:@"Translation" ];
			[ Controller setOtherObject:currentEngine atIndex:cIndex ];
		}
	}
	
	calculatingMove = FALSE;
	moveFrames = 0;
	move = MD_NONE;
	targetMove = 0;
	initialMove = 0;
	targetPoint = nil;
	inMotion = FALSE;
}

- (void) doTranslations
{
	if (move == MD_NONE)
		return;
	
	if (!calculatingMove)
	{
		calculatingMove = TRUE;
		moveFrames = 0;
		inMotion = TRUE;
		tempMove = initialMove;
	}
	
	makeDisplayLists = FALSE;
	unsigned int desiredFPS = [ (GLWindow*)[ self window ] FPS ];
	// Derived from being ∑ n^2 from 0 to (desiredFPS / 2)
	const float pressure = (desiredFPS + 1) * (desiredFPS + 2) / 12.0;
	
	float value = moveFrames;
	if (value > desiredFPS / 2)
		value = desiredFPS - value;
	
	id obj = [ selected fullValueAtIndex:0 ];
	float val = (targetMove - initialMove) * 21.0 / 20.0 * value * value / pressure * frameDuration / 1000.0;
	if (move == MD_MOVE)
	{
		if (moveVert == MD_X)
			[ obj addTranslateX:val ];
		else if (moveVert == MD_Y)
			[ obj addTranslateY:val ];
		else
			[ obj addTranslateZ:val ];
		commandFlag |= UPDATE_INFO;
	}
	else if (move == MD_SIZE)
	{
		if (moveVert == MD_X)
			[ obj addScaleX:val ];
		else if (moveVert == MD_Y)
			[ obj addScaleY:val ];
		else
			[ obj addScaleZ:val ];
		commandFlag |= UPDATE_INFO;
	}
	else if (move == MD_ROTATE)
	{
		/*if (moveVert == MD_X)
			[ obj setRotateX:[ obj rotateX ] + val ];
		else if (moveVert == MD_Y)
			[ obj setRotateY:[ obj rotateY ] + val ];
		else
			[ obj setRotateZ:[ obj rotateZ ] + val ];*/
		MDVector3 rotateAxis = [ obj rotateAxis ];
		if (moveVert == MD_X)
			rotateAxis.x += val;
		else if (moveVert == MD_Y)
			rotateAxis.y += val;
		else if (moveVert == MD_Z)
			rotateAxis.z += val;
		[ obj setRotateAxis:rotateAxis ];
		commandFlag |= UPDATE_INFO;
	}
	else if (move == MD_ROTATE_ANGLE)
	{
		[ obj setRotateAngle:[ obj rotateAngle ] + val ];
		commandFlag |= UPDATE_INFO;
	}
	/*else if (move == MD_ROTATE_POINT)
	{
		if (moveVert == MD_X)
			[ obj setRotatePoint:MDVector3Create([ obj rotatePoint ].x + val, [ obj rotatePoint ].y, [ obj rotatePoint ].z) ];
		else if (moveVert == MD_Y)
			[ obj setRotatePoint:MDVector3Create([ obj rotatePoint ].x, [ obj rotatePoint ].y + val, [ obj rotatePoint ].z) ];
		else
			[ obj setRotatePoint:MDVector3Create([ obj rotatePoint ].x, [ obj rotatePoint ].y, [ obj rotatePoint ].z + val) ];
		commandFlag |= UPDATE_INFO;
	}*/
	else if (move == MD_POINT)
	{
		if (moveVert == MD_X)
			[ obj addTranslateX:val ];
		else if (moveVert == MD_Y)
			[ obj addTranslateY:val ];
		else
			[ obj addTranslateZ:val ];
		[ [ obj instance ] setupVBO ];
		commandFlag |= UPDATE_INFO;
	}
	else if (move == MD_POINT_MID)
	{
		if (moveVert == MD_X)
			[ obj addX:val ];
		else if (moveVert == MD_Y)
			[ obj addY:val ];
		else
			[ obj addZ:val ];
		[ [ obj instance ] setupVBO ];
		commandFlag |= UPDATE_INFO;
	}
	else if (move == MD_POINT_NORMAL)
	{
		if (moveVert == MD_X)
			[ obj setNormalX:[ obj normalX ] + val ];
		else if (moveVert == MD_Y)
			[ obj setNormalY:[ obj normalY ] + val ];
		else
			[ obj setNormalZ:[ obj normalZ ] + val ];
		[ [ obj instance ] setupVBO ];
		commandFlag |= UPDATE_INFO;
	}
	else if (move == MD_POINT_TEXTURE)
	{
		if (moveVert == MD_X)
			[ obj setTextureCoordX:[ obj textureCoordX ] + val ];
		else if (moveVert == MD_Y)
			[ obj setTextureCoordY:[ obj textureCoordY ] + val ];
		[ [ obj instance ] setupVBO ];
		commandFlag |= UPDATE_INFO;
	}
	else if (move == MD_NORMAL && targetPoint)
	{
		if (moveVert == MD_X)
			[ targetPoint setNormalX:[ targetPoint normalX ] + val ];
		else if (moveVert == MD_Y)
			[ targetPoint setNormalY:[ targetPoint normalY ] + val ];
		else
			[ targetPoint setNormalZ:[ targetPoint normalZ ] + val ];
		commandFlag |= UPDATE_INFO;
	}
	else if (move == MD_SCENE)
	{
		if (moveVert == MD_X)
			translationPoint.x += val;
		else if (moveVert == MD_Y)
			translationPoint.y += val;
		else
			translationPoint.z += val;
		commandFlag |= UPDATE_SCENE_INFO;
	}
	else if (move == MD_LOOK)
	{
		if (moveVert == MD_X)
			lookPoint.x += val;
		else if (moveVert == MD_Y)
			lookPoint.y += val;
		else
			lookPoint.z += val;
		commandFlag |= UPDATE_SCENE_INFO;
	}
	else if (move == MD_SCENE_WHOLE)
	{
		float valX = (targetTrans.x - backupTrans.x) * 21.0 / 20.0 * value * value / pressure * frameDuration / 1000.0;
		float valY = (targetTrans.y - backupTrans.y) * 21.0 / 20.0 * value * value / pressure * frameDuration / 1000.0;
		float valZ = (targetTrans.z - backupTrans.z) * 21.0 / 20.0 * value * value / pressure * frameDuration / 1000.0;
		translationPoint.x += valX;
		translationPoint.y += valY;
		translationPoint.z += valZ;
		float valX2 = (targetLook.x - backupLook.x) * 21.0 / 20.0 * value * value / pressure * frameDuration / 1000.0;
		float valY2 = (targetLook.y - backupLook.y) * 21.0 / 20.0 * value * value / pressure * frameDuration / 1000.0;
		float valZ2 = (targetLook.z - backupLook.z) * 21.0 / 20.0 * value * value / pressure * frameDuration / 1000.0;
		lookPoint.x += valX2;
		lookPoint.y += valY2;
		lookPoint.z += valZ2;
		commandFlag |= UPDATE_SCENE_INFO;
	}
	else if (move == MD_POINT_MOVE && targetPoint)
	{
		if (moveVert == MD_X)
			[ targetPoint addX:val ];
		else if (moveVert == MD_Y)
			[ targetPoint addY:val ];
		else
			[ targetPoint addZ:val ];
		[ [ targetPoint instance ] setupVBO ];
	}
	else if (move == MD_POINT_COLOR || move == MD_OBJECT_COLOR)
	{
		//NSLog(@"Point / Object Color change in GLView trying to mutate object");
		id reciever = targetPoint;
		if (move == MD_OBJECT_COLOR)
			reciever = obj;
		float red = (targetColor.x - initialColor.x) * 21.0 / 20.0 * value * value / pressure * frameDuration / 1000.0;
		float green = (targetColor.y - initialColor.y) * 21.0 / 20.0 * value * value / pressure * frameDuration / 1000.0;
		float blue = (targetColor.z - initialColor.z) * 21.0 / 20.0 * value * value / pressure * frameDuration / 1000.0;
		float alpha = (targetColor.w - initialColor.w) * 21.0 / 20.0 * value * value / pressure * frameDuration / 1000.0;
		/*if (currentMode == MD_VERTEX_MODE)
		{
			MDInstance* recObj = [ reciever instance ];
			for (unsigned long q = 0; q < [ recObj numberOfPoints ]; q++)
			{
				MDPoint* p = [ recObj pointAtIndex:q ];
				if (p == reciever)
					continue;
				if (p.x == ((MDPoint*)reciever).x && p.y == ((MDPoint*)reciever).y && p.z == ((MDPoint*)reciever).z)
					[ p addMidColor:MakeMDColor(red, green, blue, alpha) ];
			}
			[ recObj setupVBO ];
		}*/
		[ reciever addMidColor:MDVector4Create(red, green, blue, alpha) ];
		if (move == MD_OBJECT_COLOR)
			[ [ reciever instance ] setupVBO ];
		commandFlag |= UPDATE_INFO;
	}
	else if (move == MD_OBJECT_COLOR_MULTIPLY)
	{
		float red = (targetColor.x - initialColor.x) * 21.0 / 20.0 * value * value / pressure * frameDuration / 1000.0;
		float green = (targetColor.y - initialColor.y) * 21.0 / 20.0 * value * value / pressure * frameDuration / 1000.0;
		float blue = (targetColor.z - initialColor.z) * 21.0 / 20.0 * value * value / pressure * frameDuration / 1000.0;
		float alpha = (targetColor.w - initialColor.w) * 21.0 / 20.0 * value * value / pressure * frameDuration / 1000.0;
		[ obj setColorMultiplier:[ obj colorMultiplier ] + MDVector4Create(red, green, blue, alpha) ];
		commandFlag |= UPDATE_INFO;
	}
	else if (move == MD_SPECULAR_COLOR)
	{
		id reciever = obj;
		float red = (targetColor.x - initialColor.x) * 21.0 / 20.0 * value * value / pressure * frameDuration / 1000.0;
		float green = (targetColor.y - initialColor.y) * 21.0 / 20.0 * value * value / pressure * frameDuration / 1000.0;
		float blue = (targetColor.z - initialColor.z) * 21.0 / 20.0 * value * value / pressure * frameDuration / 1000.0;
		float alpha = (targetColor.w - initialColor.w) * 21.0 / 20.0 * value * value / pressure * frameDuration / 1000.0;
		[ reciever addSpecularColor:MDVector4Create(red, green, blue, alpha) ];
		commandFlag |= UPDATE_INFO;

	}
	else if (move == MD_SHININESS)
	{
		[ obj addShininess:val ];
		commandFlag |= UPDATE_INFO;
	}
	else if (move == MD_CAMERA_MID)
	{
		id other = nil;
		for (int z = 0; z < [ otherObjects count ]; z++)
		{
			if ([ otherObjects[z] selected ] || ([ otherObjects[z] isKindOfClass:[ MDCamera class ] ] && [ otherObjects[z] lookSelected ]))
			{
				other = otherObjects[z];
				break;
			}
		}
		if (!other)
		{
			moveFrames++;
			if (moveFrames == 60)
				[ self finishTranslations ];
			return;
		}
		
		if ([ other isKindOfClass:[ MDCamera class ] ])
		{
			MDCamera* camera = other;
			MDVector3 point = [ camera midPoint ];
			if (moveVert == MD_X)
				point.x += val;
			else if (moveVert == MD_Y)
				point.y += val;
			else
				point.z += val;
			[ camera setMidPoint:point ];
			[ [ camera obj ] setTranslateX:point.x ];
			[ [ camera obj ] setTranslateY:point.y ];
			[ [ camera obj ] setTranslateZ:point.z ];
		}
		else if ([ other isKindOfClass:[ MDLight class ] ])
		{
			MDLight* light = other;
			MDVector3 point = [ light position ];
			if (moveVert == MD_X)
				point.x += val;
			else if (moveVert == MD_Y)
				point.y += val;
			else
				point.z += val;
			[ light setPosition:point ];
			[ [ light obj ] setTranslateX:point.x ];
			[ [ light obj ] setTranslateY:point.y ];
			[ [ light obj ] setTranslateZ:point.z ];
		}
		else if ([ other isKindOfClass:[ MDParticleEngine class ] ])
		{
			MDParticleEngine* engine = other;
			MDVector3 point = [ engine position ];
			if (moveVert == MD_X)
				point.x += val;
			else if (moveVert == MD_Y)
				point.y += val;
			else
				point.z += val;
			[ engine setPosition:point ];
		}
		commandFlag |= UPDATE_OTHER_INFO;
	}
	else if (move == MD_CAMERA_LOOK)
	{
		id other = nil;
		for (int z = 0; z < [ otherObjects count ]; z++)
		{
			if ([ otherObjects[z] selected ] || ([ otherObjects[z] isKindOfClass:[ MDCamera class ] ] && [ otherObjects[z] lookSelected ]))
			{
				other = otherObjects[z];
				break;
			}
		}
		
		if (!other)
		{
			moveFrames++;
			if (moveFrames == 60)
				[ self finishTranslations ];
			return;
		}
		
		if ([ other isKindOfClass:[ MDCamera class ] ])
		{
			MDCamera* camera = other;
			MDVector3 point = [ camera lookPoint ];
			if (moveVert == MD_X)
				point.x += val;
			else if (moveVert == MD_Y)
				point.y += val;
			else
				point.z += val;
			[ camera setLookPoint:point ];
		}
		else if ([ other isKindOfClass:[ MDLight class ] ])
		{
			MDLight* light = other;
			MDVector3 point = [ light spotDirection ];
			if (moveVert == MD_X)
				point.x += val;
			else if (moveVert == MD_Y)
				point.y += val;
			else
				point.z += val;
			[ light setSpotDirection:point ];
		}
		commandFlag |= UPDATE_OTHER_INFO;
	}
	else if (move == MD_CAMERA_OR)
	{
		MDCamera* camera = nil;
		for (int z = 0; z < [ otherObjects count ]; z++)
		{
			if ([ otherObjects[z] selected ] || ([ otherObjects[z] isKindOfClass:[ MDCamera class ] ] && [ otherObjects[z] lookSelected ]))
			{
				camera = otherObjects[z];
				break;
			}
		}
		[ camera setOrientation:[ camera orientation ] + val ];
		commandFlag |= UPDATE_OTHER_INFO;
	}
	else if (move == MD_LIGHT_AMBIENT)
	{
		MDLight* light = nil;
		for (int z = 0; z < [ otherObjects count ]; z++)
		{
			if ([ otherObjects[z] selected ])
			{
				light = otherObjects[z];
				break;
			}
		}
		MDVector4 color = [ light ambientColor ];
		if (moveVert == MD_X)
			color.x += val;
		else if (moveVert == MD_Y)
			color.y += val;
		else if (moveVert == MD_Z)
			color.z += val;
		else
			color.w += val;
		[ light setAmbientColor:color ];
		commandFlag |= UPDATE_OTHER_INFO;
	}
	else if (move == MD_LIGHT_DIFFUSE)
	{
		MDLight* light = nil;
		for (int z = 0; z < [ otherObjects count ]; z++)
		{
			if ([ otherObjects[z] selected ])
			{
				light = otherObjects[z];
				break;
			}
		}
		MDVector4 color = [ light diffuseColor ];
		if (moveVert == MD_X)
			color.x += val;
		else if (moveVert == MD_Y)
			color.y += val;
		else if (moveVert == MD_Z)
			color.z += val;
		else
			color.w += val;
		[ light setDiffuseColor:color ];
		commandFlag |= UPDATE_OTHER_INFO;
	}
	else if (move == MD_LIGHT_SPECULAR)
	{
		MDLight* light = nil;
		for (int z = 0; z < [ otherObjects count ]; z++)
		{
			if ([ otherObjects[z] selected ])
			{
				light = otherObjects[z];
				break;
			}
		}
		MDVector4 color = [ light specularColor ];
		if (moveVert == MD_X)
			color.x += val;
		else if (moveVert == MD_Y)
			color.y += val;
		else if (moveVert == MD_Z)
			color.z += val;
		else
			color.w += val;
		[ light setSpecularColor:color ];
		commandFlag |= UPDATE_OTHER_INFO;
	}
	else if (move == MD_LIGHT_SPOT)
	{
		MDLight* light = nil;
		for (int z = 0; z < [ otherObjects count ]; z++)
		{
			if ([ otherObjects[z] selected ])
			{
				light = otherObjects[z];
				break;
			}
		}
		if (moveVert == MD_X)
			[ light setSpotExp:[ light spotExp ] + val ];
		else if (moveVert == MD_Y)
			[ light setSpotCut:[ light spotCut ] + val ];
		else if (moveVert == MD_Z)
			[ light setSpotAngle:[ light spotAngle ] + val ];
		commandFlag |= UPDATE_OTHER_INFO;
	}
	else if (move == MD_LIGHT_ATTENUATION)
	{
		MDLight* light = nil;
		for (int z = 0; z < [ otherObjects count ]; z++)
		{
			if ([ otherObjects[z] selected ])
			{
				light = otherObjects[z];
				break;
			}
		}
		if (moveVert == MD_X)
			[ light setConstAtt:[ light constAtt ] + val ];
		else if (moveVert == MD_Y)
			[ light setLinAtt:[ light linAtt ] + val ];
		else if (moveVert == MD_Z)
			[ light setQuadAtt:[ light quadAtt ] + val ];
		commandFlag |= UPDATE_OTHER_INFO;
	}
	else if (move == MD_LIGHT_SHADOW_ENABLE)
		moveFrames = desiredFPS;
	else if (move == MD_LIGHT_STATIC_ENABLE)
		moveFrames = desiredFPS;
	else if (move == MD_PARTICLE_START)
	{
		MDParticleEngine* engine = nil;
		for (int z = 0; z < [ otherObjects count ]; z++)
		{
			if ([ otherObjects[z] selected ])
			{
				engine = otherObjects[z];
				break;
			}
		}
		MDVector4 color = [ engine startColor ];
		if (moveVert == MD_X)
			color.x += val;
		else if (moveVert == MD_Y)
			color.y += val;
		else if (moveVert == MD_Z)
			color.z += val;
		else
			color.w += val;
		[ engine setStartColor:color ];
		commandFlag |= UPDATE_OTHER_INFO;
	}
	else if (move == MD_PARTICLE_END)
	{
		MDParticleEngine* engine = nil;
		for (int z = 0; z < [ otherObjects count ]; z++)
		{
			if ([ otherObjects[z] selected ])
			{
				engine = otherObjects[z];
				break;
			}
		}
		MDVector4 color = [ engine endColor ];
		if (moveVert == MD_X)
			color.x += val;
		else if (moveVert == MD_Y)
			color.y += val;
		else if (moveVert == MD_Z)
			color.z += val;
		else
			color.w += val;
		[ engine setEndColor:color ];
		commandFlag |= UPDATE_OTHER_INFO;
	}
	else if (move == MD_PARTICLE_NUMBER)
	{
		/*MDParticleEngine* engine = nil;
		for (int z = 0; z < [ otherObjects count ]; z++)
		{
			if ([ [ otherObjects objectAtIndex:z ] selected ])
			{
				engine = [ otherObjects objectAtIndex:z ];
				break;
			}
		}
		tempMove += val;
		[ engine setNumberOfParticles:tempMove ];
		commandFlag |= UPDATE_OTHER_INFO;*/
		moveFrames = desiredFPS;
	}
	else if (move == MD_PARTICLE_SIZE)
	{
		MDParticleEngine* engine = nil;
		for (int z = 0; z < [ otherObjects count ]; z++)
		{
			if ([ otherObjects[z] selected ])
			{
				engine = otherObjects[z];
				break;
			}
		}
		[ engine setParticleSize:[ engine particleSize ] + val ];
		commandFlag |= UPDATE_OTHER_INFO;
	}
	else if (move == MD_PARTICLE_LIFE)
	{
		MDParticleEngine* engine = nil;
		for (int z = 0; z < [ otherObjects count ]; z++)
		{
			if ([ otherObjects[z] selected ])
			{
				engine = otherObjects[z];
				break;
			}
		}
		tempMove += val;
		[ engine setParticleLife:tempMove ];
		commandFlag |= UPDATE_OTHER_INFO;
	}
	else if (move == MD_PARTICLE_VELOCITIES)
	{
		MDParticleEngine* engine = nil;
		for (int z = 0; z < [ otherObjects count ]; z++)
		{
			if ([ otherObjects[z] selected ])
			{
				engine = otherObjects[z];
				break;
			}
		}
		MDVector3 vel = [ engine velocities ];
		if (moveVert == MD_X)
			vel.x += val;
		else if (moveVert == MD_Y)
			vel.y += val;
		else
			vel.z += val;
		[ engine setVelocities:vel ];
		commandFlag |= UPDATE_OTHER_INFO;
	}
	else if (move == MD_CURVE_POINT)
	{
		MDCurve* curve = nil;
		for (int z = 0; z < [ otherObjects count ]; z++)
		{
			if ([ otherObjects[z] selected ])
			{
				curve = otherObjects[z];
				break;
			}
		}
		std::vector<MDVector3> points = *[ curve curvePoints ];
		if (moveIndex < points.size())
		{
			if (moveVert == MD_X)
				points[moveIndex].x += val;
			if (moveVert == MD_Y)
				points[moveIndex].y += val;
			if (moveVert == MD_Z)
				points[moveIndex].z += val;
		}
		[ curve setPoints:points ];
		//commandFlag |= UPDATE_OTHER_INFO;
	}
	else if (move == MD_VISIBLE)
		moveFrames = desiredFPS;
	else if (move == MD_USE)
		moveFrames = desiredFPS;
	
	moveFrames += frameDuration * desiredFPS / 1000.0;
	if (moveFrames >= desiredFPS)
		[ self finishTranslations ];
}

- (void) loadModel:(NSString *)path
{
	NSString* realPath = path;
	if (![ realPath hasPrefix:@"/" ])
		realPath = [ NSString stringWithFormat:@"%@/Models/%@", [ [ NSBundle mainBundle ] resourcePath ], path ];
	FILE* file = fopen([ realPath UTF8String ], "r");
	MDInstance* instance = [ [ MDInstance alloc ] init ];
	
	unsigned int numMesh = 0;
	fread(&numMesh, sizeof(unsigned int), 1, file);
	for (unsigned long t = 0; t < numMesh; t++)
	{
		[ instance beginMesh ];
		MDVector4 color = MDVector4Create(1, 1, 1, 1);
		fread(&color.x, sizeof(float), 1, file);
		fread(&color.y, sizeof(float), 1, file);
		fread(&color.z, sizeof(float), 1, file);
		fread(&color.w, sizeof(float), 1, file);
		[ instance setColor:color ];
		unsigned long pointCount = 0;
		fread(&pointCount, sizeof(unsigned long), 1, file);
		for (unsigned long q = 0; q < pointCount; q++)
		{
			MDPoint* p = [ [ MDPoint alloc ] init ];
			float x = 0, y = 0, z = 0, normX = 0, normY = 0, normZ = 0, ux = 0, vy = 0;
			fread(&x, sizeof(float), 1, file);
			fread(&y, sizeof(float), 1, file);
			fread(&z, sizeof(float), 1, file);
			fread(&normX, sizeof(float), 1, file);
			fread(&normY, sizeof(float), 1, file);
			fread(&normZ, sizeof(float), 1, file);
			fread(&ux, sizeof(float), 1, file);
			fread(&vy, sizeof(float), 1, file);
			p.x = x, p.y = y, p.z = z, p.normalX = normX, p.normalY = normY, p.normalZ = normZ, p.textureCoordX = ux, p.textureCoordY = vy;
			
			[ instance addPoint:p ];
		}
		unsigned int indexNum = 0;
		fread(&indexNum, sizeof(unsigned int), 1, file);
		for (unsigned int q = 0; q < indexNum; q++)
		{
			unsigned int index = 0;
			fread(&index, sizeof(unsigned int), 1, file);
			[ instance addIndex:index ];
		}
		unsigned int texNum = 0;
		fread(&texNum, sizeof(unsigned int), 1, file);
		for (unsigned int q = 0; q < texNum; q++)
		{
			unsigned char type = 0;
			fread(&type, sizeof(unsigned char), 1, file);
			unsigned int head = 0;
			fread(&head, sizeof(unsigned int), 1, file);
			float size = 0;
			fread(&size, sizeof(float), 1, file);
			unsigned int len = 0;
			fread(&len, sizeof(unsigned int), 1, file);
			char* buffer = (char*)malloc(len + 1);
			fread(buffer, len, 1, file);
			buffer[len] = 0;
			[ instance addTexture:[ NSString stringWithFormat:@"%@%s", [ path stringByDeletingLastPathComponent ], buffer ] withType:(MDTextureType)type withHead:head withSize:size ];
			free(buffer);
			buffer = NULL;
		}
		[ instance endMesh ];
	}
	
	unsigned long numProp = 0;
	fread(&numProp, sizeof(unsigned long), 1, file);
	for (int t = 0; t < numProp; t++)
	{
		unsigned long keyLength = 0;
		fread(&keyLength, sizeof(unsigned int), 1, file);
		char* buffer = (char*)malloc(keyLength + 1);
		fread(buffer, sizeof(char), keyLength, file);
		buffer[keyLength] = 0;
		NSString* key = @(buffer);
		free(buffer);
		unsigned long length = 0;
		fread(&length, sizeof(unsigned long), 1, file);
		buffer = (char*)malloc(length + 1);
		fread(buffer, sizeof(char), length, file);
		buffer[length] = 0;
		NSString* value = @(buffer);
		free(buffer);
		buffer = NULL;
		[ instance addProperty:value forKey:key ];
	}
	[ instance setMidPoint:MDVector3Create(0, 0, 0) ];
	
	fclose(file);
	
	MDObject* obj = [ [ MDObject alloc ] initWithInstance:instance ];
	obj.objectColors[0].x = obj.objectColors[1].z = obj.objectColors[2].x = obj.objectColors[2].y = 0.7;
	obj.objectColors[0].w = obj.objectColors[1].w = obj.objectColors[2].w = 1;
	
	obj.objectColors[0].x = obj.objectColors[1].z = obj.objectColors[2].x = obj.objectColors[2].y = 0.7;
	obj.objectColors[0].w = obj.objectColors[1].w = obj.objectColors[2].w = 1;
	
	MDStructModel model;
	memset(&model, 0, sizeof(model));
	model.instance = instance;
	model.obj = obj;
	model.name = [ [ NSString alloc ] initWithString:[ path lastPathComponent ] ];
	
	models.push_back(model);
}

- (std::vector<MDStructModel>) models
{
	return models;
}

/*
 * Create a pixel format and possible switch to full screen mode
 */
- (NSOpenGLPixelFormat *) createPixelFormat:(NSRect)frame
{
	NSOpenGLPixelFormatAttribute pixelAttribs[ 16 ];
	int pixNum = 0;
	NSOpenGLPixelFormat *pixelFormat;
	
	pixelAttribs[ pixNum++ ] = NSOpenGLPFAOpenGLProfile;
	pixelAttribs[ pixNum++ ] = NSOpenGLProfileVersion3_2Core;
	pixelAttribs[ pixNum++ ] = NSOpenGLPFADoubleBuffer;
	pixelAttribs[ pixNum++ ] = NSOpenGLPFAAccelerated;
	pixelAttribs[ pixNum++ ] = NSOpenGLPFAColorSize;
	pixelAttribs[ pixNum++ ] = colorBits;
	pixelAttribs[ pixNum++ ] = NSOpenGLPFADepthSize;
	pixelAttribs[ pixNum++ ] = depthBits;
	// Multisampling
	pixelAttribs[ pixNum++ ] = NSOpenGLPFAMultisample;
	pixelAttribs[ pixNum++ ] = 1;
	pixelAttribs[ pixNum++ ] = NSOpenGLPFASampleBuffers;
	pixelAttribs[ pixNum++ ] = 1;
	pixelAttribs[ pixNum++ ] = NSOpenGLPFASamples;
	pixelAttribs[ pixNum++ ] = 1;//projectAntialias;
	
	pixelAttribs[ pixNum ] = 0;
	pixelFormat = [ [ NSOpenGLPixelFormat alloc ] initWithAttributes:pixelAttribs ];
	
	return pixelFormat;
}

void printProgramInfoLog(GLuint obj)
{
    int infologLength = 0;
    int charsWritten  = 0;
    char *infoLog;
	
	glGetProgramiv(obj, GL_INFO_LOG_LENGTH,&infologLength);
	
    if (infologLength > 0)
    {
        infoLog = (char *)malloc(infologLength);
        glGetProgramInfoLog(obj, infologLength, &charsWritten, infoLog);
		printf("%s\n",infoLog);
        free(infoLog);
    }
}

void printShaderInfoLog(GLuint obj)
{
    int infologLength = 0;
    int charsWritten  = 0;
    char *infoLog;
	
	glGetShaderiv(obj, GL_INFO_LOG_LENGTH,&infologLength);
	
    if (infologLength > 0)
    {
        infoLog = (char *)malloc(infologLength);
        glGetShaderInfoLog(obj, infologLength, &charsWritten, infoLog);
		printf("%i - %s\n", obj, infoLog);
        free(infoLog);
    }
}

- (void) setupShaders
{
	for (unsigned long z = 0; z < sizeof(program) / sizeof(unsigned int); z++)
	{
		if (program[z])
		{
			if (vertexShader[z])
			{
				glDetachShader(program[z], vertexShader[z]);
				glDeleteShader(vertexShader[z]);
				vertexShader[z] = 0;
			}
			if (fragmentShader[z])
			{
				glDetachShader(program[z], fragmentShader[z]);
				glDeleteShader(fragmentShader[z]);
				fragmentShader[z] = 0;
			}
			glDeleteProgram(program[z]);
			program[z] = 0;
		}
	}
	
	unsigned long numOfLights[3] = { 0, 0, 0 };
	for (unsigned long z = 0; z < [ otherObjects count ]; z++)
	{
		if ([ otherObjects[z] isKindOfClass:[ MDLight class ] ])
			numOfLights[[ otherObjects[z] lightType ]]++;
	}
	unsigned long realLights[3] = { 0, 0, 0 };
	for (int z = 0; z < 3; z++)
	{
		realLights[z] = numOfLights[z];
		if (realLights[z] == 0)
			realLights[z] = 1;
	}
	
	// For now, always 1
	const unsigned int maxTextures = 1;
	
	// Setup shaders
	NSString* names[] = { @"Shader", @"Normal", @"Particles", };
	for (unsigned long z = 0; z < sizeof(program) / sizeof(unsigned int); z++)
	{
		NSMutableString* vertString = [ [ NSMutableString alloc ] initWithData:[ [ NSFileManager defaultManager ] contentsAtPath:[ NSString stringWithFormat:@"%@/Shaders/%@.vert", [ [ NSBundle mainBundle ] resourcePath ], names[z] ] ] encoding:NSUTF8StringEncoding ];
		if (z == 0)
		{
			[ vertString replaceOccurrencesOfString:@"%a" withString:[ NSString stringWithFormat:@"%li", numOfLights[0] ] options:0 range:NSMakeRange(0, [ vertString length ]) ];
			[ vertString replaceOccurrencesOfString:@"%b" withString:[ NSString stringWithFormat:@"%li", numOfLights[1] ] options:0 range:NSMakeRange(0, [ vertString length ]) ];
			[ vertString replaceOccurrencesOfString:@"%c" withString:[ NSString stringWithFormat:@"%li", numOfLights[2] ] options:0 range:NSMakeRange(0, [ vertString length ]) ];
			[ vertString replaceOccurrencesOfString:@"%d" withString:[ NSString stringWithFormat:@"%li", realLights[0] ] options:0 range:NSMakeRange(0, [ vertString length ]) ];
			[ vertString replaceOccurrencesOfString:@"%e" withString:[ NSString stringWithFormat:@"%li", realLights[1] ] options:0 range:NSMakeRange(0, [ vertString length ]) ];
			[ vertString replaceOccurrencesOfString:@"%f" withString:[ NSString stringWithFormat:@"%li", realLights[2] ] options:0 range:NSMakeRange(0, [ vertString length ]) ];
			
			NSMutableString* vertTextureSetup = [ NSMutableString string ];
			for (unsigned int y = 0; y < maxTextures; y++)
			{
				[ vertTextureSetup appendFormat:@"\
				 {\n\
					mapCoords[%i] = vTex.st * mapTextures[%i].size;\n\
					diffuseMapCoords[%i] = vTex.st * diffuseMapTextures[%i].size;\n\
					diffuseMapCoords[%i] = vTex.st * diffuseMapTextures[%i].size;\n\
					diffuseMapCoords[%i] = vTex.st * diffuseMapTextures[%i].size;\n\
				 }\n", y, y, (y * 3), (y * 3), (y * 3) + 1, (y * 3) + 1, (y * 3) + 2, (y * 3) + 2 ];
			}
			[ vertString replaceOccurrencesOfString:@"#pragma insert TextureCoordSetup" withString:vertTextureSetup options:0 range:NSMakeRange(0, [ vertString length ]) ];
			
			NSString* shadowParts[3] = { @"Dir", @"Point", @"Spot" };
			NSMutableString* vertShadowDec = [ NSMutableString string ];
			for (int t = 0; t < 3; t++)
			{
				NSString* part = shadowParts[t];
				for (unsigned int y = 0; y < numOfLights[t]; y++)
				{
					if (t == 1)
					{
						// Temp disable shadows because of image limit 
						[ vertShadowDec appendFormat:@"\
						 uniform /*samplerCube*/ int shadowMap%@%i;\n\
						 \n", part, y ];
					}
					else
					{
						// Temp disable shadows because of image limit
						[ vertShadowDec appendFormat:@"\
						 out vec4 shadowCoord%@%i;\n\
						 uniform /*sampler2D*/int shadowMap%@%i;\n\
						 uniform mat4 shadowMatrix%@%i;\n\
						 \n", part, y, part, y, part, y ];
					}
				}
			}
			[ vertString replaceOccurrencesOfString:@"#pragma insert ShadowVertDec" withString:vertShadowDec options:0 range:NSMakeRange(0, [ vertString length ]) ];
			
			NSMutableString* vertShadowSetup = [ NSMutableString stringWithString:@"\t" ];
			for (int t = 0; t < 3; t++)
			{
				NSString* part = shadowParts[t];
				for (unsigned int y = 0; y < numOfLights[t]; y++)
				{
					if (t != 1)
						[ vertShadowSetup appendFormat:@"shadowCoord%@%i = shadowMatrix%@%i * tempVert;\n", part, y, part, y ];
				}
			}
			[ vertString replaceOccurrencesOfString:@"#pragma insert ShadowVertSetup" withString:vertShadowSetup options:0 range:NSMakeRange(0, [ vertString length ]) ];
			//NSLog(@"%@", vertString);
		}
		NSMutableString* fragString = [ [ NSMutableString alloc ] initWithData:[ [ NSFileManager defaultManager ] contentsAtPath:[ NSString stringWithFormat:@"%@/Shaders/%@.frag", [ [ NSBundle mainBundle ] resourcePath ], names[z] ] ] encoding:NSUTF8StringEncoding ];
		if (z == 0)
		{
			[ fragString replaceOccurrencesOfString:@"%a" withString:[ NSString stringWithFormat:@"%li", numOfLights[0] ] options:0 range:NSMakeRange(0, [ fragString length ]) ];
			[ fragString replaceOccurrencesOfString:@"%b" withString:[ NSString stringWithFormat:@"%li", numOfLights[1] ] options:0 range:NSMakeRange(0, [ fragString length ]) ];
			[ fragString replaceOccurrencesOfString:@"%c" withString:[ NSString stringWithFormat:@"%li", numOfLights[2] ] options:0 range:NSMakeRange(0, [ fragString length ]) ];
			[ fragString replaceOccurrencesOfString:@"%d" withString:[ NSString stringWithFormat:@"%li", realLights[0] ] options:0 range:NSMakeRange(0, [ fragString length ]) ];
			[ fragString replaceOccurrencesOfString:@"%e" withString:[ NSString stringWithFormat:@"%li", realLights[1] ] options:0 range:NSMakeRange(0, [ fragString length ]) ];
			[ fragString replaceOccurrencesOfString:@"%f" withString:[ NSString stringWithFormat:@"%li", realLights[2] ] options:0 range:NSMakeRange(0, [ fragString length ]) ];
			
			 NSMutableString* fragTextureAlpha = [ NSMutableString string ];
			 // Causes laptop to go to software
			for (unsigned int y = 0; y < maxTextures; y++)
			{
				[ fragTextureAlpha appendFormat:@"\
				 {\n\
					 if (mapTextures[%i].enabled == 1)\n\
					 {\n\
						 vec4 map = texture(mapTextures[%i].texture, mapCoords[%i]).rgba;\n\
						 vec4 tex1 = texture(diffuseMapTextures[mapTextures[%i].children[0]].texture, diffuseMapCoords[mapTextures[%i].children[0]]).rgba;\n\
						 vec4 tex2 = texture(diffuseMapTextures[mapTextures[%i].children[1]].texture, diffuseMapCoords[mapTextures[%i].children[1]]).rgba;\n\
						 vec4 tex3 = texture(diffuseMapTextures[mapTextures[%i].children[2]].texture, diffuseMapCoords[mapTextures[%i].children[2]]).rgba;\n\
						 color2 += (map.r * tex1) + (map.g * tex2) + (map.b * tex3);\n\
					 }\n\
				 }\n", y, y, y, y, y, y, y, y, y ];
			}
			[ fragString replaceOccurrencesOfString:@"#pragma insert TextureAlphaMap" withString:fragTextureAlpha options:0 range:NSMakeRange(0, [ fragString length ]) ];
			
			NSString* shadowParts[3] = { @"Dir", @"Point", @"Spot" };
			NSMutableString* fragShadowDec = [ NSMutableString string ];
			for (int t = 0; t < 3; t++)
			{
				NSString* part = shadowParts[t];
				for (unsigned int y = 0; y < numOfLights[t]; y++)
				{
					if (t == 1)
					{
						// Temp disable shadows because of image limit
						[ fragShadowDec appendFormat:@"\
						 uniform /*samplerCube*/ int shadowMap%@%i;\n\
						 \n", part, y ];
					}
					else
					{
						// Temp disable shadows because of image limit
						[ fragShadowDec appendFormat:@"\
						 in vec4 shadowCoord%@%i;\n\
						 uniform /*sampler2D*/ int shadowMap%@%i;\n\
						 uniform mat4 shadowMatrix%@%i;\n\
						 \n", part, y, part, y, part, y ];
					}
				}
			}
			[ fragString replaceOccurrencesOfString:@"#pragma insert ShadowFragDec" withString:fragShadowDec options:0 range:NSMakeRange(0, [ fragString length ]) ];
			
			NSMutableString* fragShadowLight = [ NSMutableString stringWithString:@"\t" ];
			unsigned int lightCounter[3] = { 0 };
			for (int t = 0; t < 3; t++)
			{
				for (unsigned int y = 0; y < numOfLights[t]; y++)
				{
					unsigned int lightNum = lightCounter[t]++;
					if (t == 0)
					{
						[ fragShadowLight appendFormat:@"\n\
						 {\n\
							 const int z = %i;\n\
							 float shadow = (1 - dirLights[z].enableShadows);\n\
							 vec4 color = vec4(0, 0, 0, 0);//dirAmbient[z];\n\
							 \n\
							 // Compute the ligt direction\n\
							 lightDir = vec3(-dirLights[z].position);\n\
							 \n\
							 // compute the distance to the light source to a varying variable\n\
							 float dist = length(lightDir);\n\
							 \n\
							 // compute the dot product between normal and ldir\n\
							 NdotL = dot(n, normalize(lightDir));\n\
							 \n\
							 if (NdotL > 0.0)\n\
							 {\n\
								 color += dirLights[z].diffuse * NdotL;\n\
								 halfV = normalize(eyePos - realPos + vec3(dirLights[z].position));\n\
								 NdotHV = max(dot(n, halfV),0.0);\n\
								 color += frontMaterialSpecular * dirLights[z].specular * pow(NdotHV, frontMaterialShininess);\n\
								 \n\
								 // Shadows\n\
								 if (dirLights[z].enableShadows == 1)\n\
								 {\n\
									vec4 shadowCoordinateWdivide = shadowCoordDir%i / shadowCoordDir%i.w;\n\
									float bias = 0;//clamp(0.001 * tan(acos(NdotL)), 0, 0.01);\n\
									shadowCoordinateWdivide.z += bias;\n\
									float distanceFromLight = 0;//texture(shadowMapDir%i, shadowCoordinateWdivide.st).r;\n\
									if (shadowCoordDir%i.w > 0.0)\n\
										shadow = distanceFromLight < shadowCoordinateWdivide.z ? 0.0 : 1.0;	// For hard shadow - replace NdotL with 0.0\n\
									else\n\
										shadow = 1.0;\n\
								 }\n\
							 }\n\
							 totalColor += dirLights[z].ambient + vec4(color.rgb * shadow, color.a);\n\
						 }\n", lightNum, lightNum, lightNum, lightNum, lightNum ];
					}
					else if (t == 1)
					{
						[ fragShadowLight appendFormat:@"\n\
						{\n\
							const int z = %i;\n\
							float shadow = (1 - pointLights[z].enableShadows);\n\
							vec4 color = vec4(0, 0, 0, 0);\n\
							\n\
							// Compute the ligt direction\n\
							lightDir = vec3(pointLights[z].position - ecPos);\n\
							//lightDir = vec3(ecPos);\n\
							\n\
							// compute the distance to the light source to a varying variable\n\
							float dist = length(lightDir);\n\
							\n\
							// compute the dot product between normal and ldir\n\
							NdotL = dot(n, normalize(lightDir));\n\
							\n\
							if (NdotL > 0.0)\n\
							{\n\
								att = 1.0 / (pointLights[z].constantAttenuation +\n\
											 pointLights[z].linearAttenuation * dist +\n\
											 pointLights[z].quadraticAttenuation * dist * dist);\n\
								color += att * (pointLights[z].diffuse * NdotL * pointLights[z].ambient);\n\
								\n\
								halfV = normalize(eyePos - realPos + vec3(pointLights[z].position));\n\
								NdotHV = max(dot(n, halfV), 0.0);\n\
								color += att * frontMaterialSpecular * pointLights[z].specular * pow(NdotHV, frontMaterialShininess);\n\
								\n\
								// Shadows\n\
								if (pointLights[z].enableShadows == 1)\n\
								{\n\
									float bias = clamp(0.005 * tan(acos(NdotL)), 0, 0.001);\n\
									float distanceFromLight = 0;//texture(shadowMapPoint%i, -lightDir).r;\n\
									shadow = (distanceFromLight + bias) < VectorToDepthValue(-lightDir) ? 0.0 : 1.0;\n\
								}\n\
							}\n\
							\n\
							totalColor += vec4(color.rgb * shadow, color.a);\n\
						 }\n", lightNum, lightNum ];
					}
					else if (t == 2)
					{
						[ fragShadowLight appendFormat:@"\n\
						{\n\
							const int z = %i;\n\
							float shadow = (1 - spotLights[z].enableShadows);\n\
							vec4 color = vec4(0.0, 0.0, 0.0, 0.0);\n\
							\n\
							// Compute the ligt direction\n\
							lightDir = vec3(spotLights[z].position - ecPos);\n\
							\n\
							// compute the distance to the light source to a varying variable\n\
							float dist = length(lightDir);\n\
							\n\
							// compute the dot product between normal and ldir\n\
							NdotL = dot(n, normalize(lightDir));\n\
							\n\
							if (NdotL > 0.0)\n\
							{\n\
								spotEffect = dot(normalize(spotLights[z].spotDirection), normalize(-lightDir));\n\
								if (spotEffect > spotLights[z].spotCosCutoff)\n\
								{\n\
									spotEffect = pow(spotEffect, spotLights[z].spotExponent);\n\
									att = spotEffect / (spotLights[z].constantAttenuation +\n\
														spotLights[z].linearAttenuation * dist +\n\
														spotLights[z].quadraticAttenuation * dist * dist);\n\
									\n\
									color += att * (spotLights[z].diffuse * NdotL + spotLights[z].ambient);\n\
									\n\
									halfV = normalize(eyePos - realPos + vec3(spotLights[z].position));\n\
									NdotHV = max(dot(n, halfV), 0.0);\n\
									color += att * frontMaterialSpecular * spotLights[z].specular * pow(NdotHV, frontMaterialShininess);\n\
									\n\
									// Shadows\n\
									if (spotLights[z].enableShadows == 1)\n\
									{\n\
										vec4 shadowCoordinateWdivide = shadowCoordSpot%i / shadowCoordSpot%i.w;\n\
										// Used to lower moiré pattern and self-shadowing - removes the weird pattern sometimes but also causes the shadows to go up on the sides\n\
										//float bias = 0;//0.0005;\n\
										//shadowCoordinateWdivide.z += bias;\n\
										float distanceFromLight = 0;//texture(shadowMapSpot%i, shadowCoordinateWdivide.st).r;\n\
										if (shadowCoordSpot%i.w > 0.0)\n\
											shadow = distanceFromLight < shadowCoordinateWdivide.z ? 0.0 : 1.0;\n\
										else\n\
											shadow = 1.0;\n\
									}\n\
								}\n\
							}\n\
							totalColor += vec4(color.rgb * shadow, color.a);\n\
						 }\n", lightNum, lightNum, lightNum, lightNum, lightNum ];
					}
				}
			}
			[ fragString replaceOccurrencesOfString:@"#pragma insert ShadowFragLight" withString:fragShadowLight options:0 range:NSMakeRange(0, [ fragString length ]) ];
			//NSLog(@"%@", fragString);
		}
		vertexShader[z] = glCreateShader(GL_VERTEX_SHADER);
		const char* vertSources[1] = { [ vertString UTF8String ] };
		glShaderSource(vertexShader[z], 1, vertSources, NULL);
		glCompileShader(vertexShader[z]);
		fragmentShader[z] = glCreateShader(GL_FRAGMENT_SHADER);
		const char* fragSources[1] = { [ fragString UTF8String ] };
		glShaderSource(fragmentShader[z], 1, fragSources, NULL);
		glCompileShader(fragmentShader[z]);
		
		printShaderInfoLog(vertexShader[z]);
		printShaderInfoLog(fragmentShader[z]);
		
		program[z] = glCreateProgram();
		glAttachShader(program[z], vertexShader[z]);
		glAttachShader(program[z], fragmentShader[z]);
		if (z == 0)
		{
			glBindFragDataLocation(program[z], 0, "finalColor");
			glBindAttribLocation(program[z], 0, "vPos");
			glBindAttribLocation(program[z], 1, "vColor");
			glBindAttribLocation(program[z], 2, "vNormal");
			glBindAttribLocation(program[z], 3, "vTex");
			glBindAttribLocation(program[z], 4, "vBoneMatrix");	// Takes up 4 spots, not just 1
		}
		else if (z == 1)
		{
			glBindFragDataLocation(program[z], 0, "finalColor");
			glBindAttribLocation(program[z], 0, "vPos");
			glBindAttribLocation(program[z], 1, "vColor");
			glBindAttribLocation(program[z], 2, "vNormal");
			glBindAttribLocation(program[z], 3, "vTexCoord");
		}
		else if (z == 2)
		{
			glBindFragDataLocation(program[z], 0, "finalColor");
			glBindAttribLocation(program[z], 0, "vPos");
			glBindAttribLocation(program[z], 1, "vColor");
		}
		glLinkProgram(program[z]);
		glUseProgram(program[z]);
		
		printProgramInfoLog(program[z]);
	}
	
	// Setup shadow FBO
	BOOL lost = FALSE;
	for (unsigned int y = 0; y < 3; y++)
	{
		// Delete if already made
		for (unsigned int z = 0; z < shadowTexture[y].size(); z++)
		{
			if (shadowTexture[y][z])
				ReleaseImage(&shadowTexture[y][z]);
		}
		shadowTexture[y].clear();
		for (unsigned int z = 0; z < shadowFBO[y].size(); z++)
		{
			if (shadowFBO[y][z] && glIsFramebuffer(shadowFBO[y][z]))
				glDeleteFramebuffers(1, &shadowFBO[y][z]);
		}
		shadowFBO[y].clear();
		
		for (unsigned int z = 0; z < numOfLights[y]; z++)
		{
			if (y == 1)
			{
				// Must be square
				int shadowMapWidth = 640;		// Render Width * Shadow Map Scale
				int shadowMapHeight = 640;		// Render Width * Shadow Map Scale
				
				shadowTexture[y].push_back(0);
				glGenTextures(1, &shadowTexture[y][z]);
				glBindTexture(GL_TEXTURE_CUBE_MAP, shadowTexture[y][z]);
				glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
				glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
				glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_R, GL_CLAMP_TO_EDGE);
				
				glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
				glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
				for (int i = 0; i < 6; i++)
				{
					glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X + i, 0, GL_DEPTH_COMPONENT, shadowMapWidth, shadowMapHeight, 0, GL_DEPTH_COMPONENT, GL_UNSIGNED_BYTE, NULL);
				}
				
				shadowFBO[y].push_back(0);
				glGenFramebuffers(1, &shadowFBO[y][z]);
				glBindFramebuffer(GL_FRAMEBUFFER, shadowFBO[y][z]);
				
				glDrawBuffer(GL_NONE);
				glReadBuffer(GL_NONE);
				
				glFramebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_TEXTURE_CUBE_MAP_POSITIVE_X, shadowTexture[y][z], 0);
				
				if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
				{
					NSLog(@"FBOs not supported.");
					lost = TRUE;
					break;
				}
															 
				glBindFramebuffer(GL_FRAMEBUFFER, 0);
				if (lost)
					break;
			}
			else
			{
				int shadowMapWidth = 640;		// Render Width * Shadow Map Scale
				int shadowMapHeight = 480;		// Render Height * Shadow Map Scale
				shadowTexture[y].push_back(0);
				glGenTextures(1, &shadowTexture[y][z]);
				glBindTexture(GL_TEXTURE_2D, shadowTexture[y][z]);
				
				glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
				glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
				glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
				glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
				
				glTexImage2D( GL_TEXTURE_2D, 0, GL_DEPTH_COMPONENT32, shadowMapWidth, shadowMapHeight, 0, GL_DEPTH_COMPONENT, GL_FLOAT, NULL);
				glBindTexture(GL_TEXTURE_2D, 0);
				
				shadowFBO[y].push_back(0);
				glGenFramebuffers(1, &shadowFBO[y][z]);
				glBindFramebuffer(GL_FRAMEBUFFER, shadowFBO[y][z]);
				
				// Disable Color
				glDrawBuffer(GL_NONE);
				glReadBuffer(GL_NONE);
				// Attach framebuffer
				glFramebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_TEXTURE_2D, shadowTexture[y][z], 0);
				
				if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
				{
					NSLog(@"FBOs not supported.");
					lost = TRUE;
					break;
				}
								
				glBindFramebuffer(GL_FRAMEBUFFER, 0);
			}
		}
		
		if (lost)
			break;
	}
		
	if (lost)
	{
		for (unsigned int y = 0; y < 3; y++)
		{
			for (unsigned int z = 0; z < shadowTexture[y].size(); z++)
			{
				if (shadowTexture[y][z])
					ReleaseImage(&shadowTexture[y][z]);
			}
			shadowTexture[y].clear();
			for (unsigned int z = 0; z < shadowFBO[y].size(); z++)
			{
				if (shadowFBO[y][z] && glIsFramebuffer(shadowFBO[y][z]))
					glDeleteFramebuffers(1, &shadowFBO[y][z]);
			}
			shadowFBO[y].clear();
		}
	}
	
	// Setup lighting uniform locations
	if (lightingLocations)
		free(lightingLocations);
	lightingLocations = (unsigned int*)malloc(sizeof(unsigned int) * 12 * (numOfLights[0] + numOfLights[1] + numOfLights[2]));
	const NSString* lightStrs[3] = { @"dirLights", @"pointLights", @"spotLights", };
	unsigned long total[3] = { 0, 0, 0 };
	unsigned int index = 0;
	for (unsigned long z = 0; z < [ otherObjects count ]; z++)
	{
		if (![ otherObjects[z] isKindOfClass:[ MDLight class ] ])
			continue;
		MDLight* lightObj = otherObjects[z];
		unsigned int type = [ lightObj lightType ];
		const NSString* dstStr = lightStrs[type];
		
		lightingLocations[index++] = glGetUniformLocation(program[0], [ [ NSString stringWithFormat:@"%@[%li].ambient", dstStr, total[type] ] UTF8String ]);
		lightingLocations[index++] = glGetUniformLocation(program[0], [ [ NSString stringWithFormat:@"%@[%li].diffuse", dstStr, total[type] ] UTF8String ]);
		lightingLocations[index++] = glGetUniformLocation(program[0], [ [ NSString stringWithFormat:@"%@[%li].specular", dstStr, total[type] ] UTF8String ]);
		lightingLocations[index++] = glGetUniformLocation(program[0], [ [ NSString stringWithFormat:@"%@[%li].position", dstStr, total[type] ] UTF8String ]);
		lightingLocations[index++] = glGetUniformLocation(program[0], [ [ NSString stringWithFormat:@"%@[%li].spotDirection", dstStr, total[type] ] UTF8String ]);
		lightingLocations[index++] = glGetUniformLocation(program[0], [ [ NSString stringWithFormat:@"%@[%li].spotExponent", dstStr, total[type] ] UTF8String ]);
		lightingLocations[index++] = glGetUniformLocation(program[0], [ [ NSString stringWithFormat:@"%@[%li].spotCutoff", dstStr, total[type] ] UTF8String ]);
		lightingLocations[index++] = glGetUniformLocation(program[0], [ [ NSString stringWithFormat:@"%@[%li].spotCosCutoff", dstStr, total[type] ] UTF8String ]);
		lightingLocations[index++] = glGetUniformLocation(program[0], [ [ NSString stringWithFormat:@"%@[%li].constantAttenuation", dstStr, total[type] ] UTF8String ]);
		lightingLocations[index++] = glGetUniformLocation(program[0], [ [ NSString stringWithFormat:@"%@[%li].linearAttenuation", dstStr, total[type] ] UTF8String ]);
		lightingLocations[index++] = glGetUniformLocation(program[0], [ [ NSString stringWithFormat:@"%@[%li].quadraticAttenuation", dstStr, total[type] ] UTF8String ]);
		lightingLocations[index++] = glGetUniformLocation(program[0], [ [ NSString stringWithFormat:@"%@[%li].enableShadows", dstStr, total[type] ] UTF8String ]);
		total[type]++;
	}
	
	// Setup other non countable uniform locations
	if (programConstants)
		free(programConstants);
	programConstants = (unsigned int*)malloc(sizeof(unsigned int) * 34);
	programConstants[MD_PROGRAM0_TRANSLATE] = glGetUniformLocation(program[0], "translate");
	programConstants[MD_PROGRAM0_SCALE] = glGetUniformLocation(program[0], "scale");
	programConstants[MD_PROGRAM0_ROTATE] = glGetUniformLocation(program[0], "rotate");
	programConstants[MD_PROGRAM0_MIDPOINT] = glGetUniformLocation(program[0], "midpoint");
	programConstants[MD_PROGRAM0_OBJECTCOLOR] = glGetUniformLocation(program[0], "objectColor");
	programConstants[MD_PROGRAM0_OBJMATRIX] = glGetUniformLocation(program[0], "objMatrix");
	programConstants[MD_PROGRAM0_EYEPOS] = glGetUniformLocation(program[0], "eyePos");
	programConstants[MD_PROGRAM0_MODELVIEWPROJECTION] = glGetUniformLocation(program[0], "modelViewProjection");
	programConstants[MD_PROGRAM0_FRONTMATERIALSPECULAR] = glGetUniformLocation(program[0], "frontMaterialSpecular");
	programConstants[MD_PROGRAM0_FORNTMATERIALSHININESS] = glGetUniformLocation(program[0], "frontMaterialShininess");
	// Hardcoded for now
	programConstants[MD_PROGRAM0_DIFFUSETEXTURES0_SIZE] = glGetUniformLocation(program[0], "diffuseTextures[0].size");
	programConstants[MD_PROGRAM0_DIFFUSETEXTURES0_CHILDREN] = glGetUniformLocation(program[0], "diffuseTextures[0].children");
	programConstants[MD_PROGRAM0_DIFFUSETEXTURES0_ENABLED] = glGetUniformLocation(program[0], "diffuseTextures[0].enabled");
	programConstants[MD_PROGRAM0_DIFFUSETEXTURES0_TEXTURE] = glGetUniformLocation(program[0], "diffuseTextures[0].texture");
	programConstants[MD_PROGRAM0_BUMPTEXTURES0_SIZE] = glGetUniformLocation(program[0], "bumpTextures[0].size");
	programConstants[MD_PROGRAM0_BUMPTEXTURES0_CHILDREN] = glGetUniformLocation(program[0], "bumpTextures[0].children");
	programConstants[MD_PROGRAM0_BUMPTEXTURES0_ENABLED] = glGetUniformLocation(program[0], "bumpTextures[0].enabled");
	programConstants[MD_PROGRAM0_BUMPTEXTURES0_TEXTURE] = glGetUniformLocation(program[0], "bumpTextures[0].texture");
	programConstants[MD_PROGRAM0_MAPTEXTURES0_SIZE] = glGetUniformLocation(program[0], "mapTextures[0].size");
	programConstants[MD_PROGRAM0_MAPTEXTURES0_CHILDREN] = glGetUniformLocation(program[0], "mapTextures[0].children");
	programConstants[MD_PROGRAM0_MAPTEXTURES0_ENABLED] = glGetUniformLocation(program[0], "mapTextures[0].enabled");
	programConstants[MD_PROGRAM0_MAPTEXTURES0_TEXTURE] = glGetUniformLocation(program[0], "mapTextures[0].texture");
	programConstants[MD_PROGRAM0_DIFFUSEMAPTEXTURES0_SIZE] = glGetUniformLocation(program[0], "diffuseMapTextures[0].size");
	programConstants[MD_PROGRAM0_DIFFUSEMAPTEXTURES0_CHILDREN] = glGetUniformLocation(program[0], "diffuseMapTextures[0].children");
	programConstants[MD_PROGRAM0_DIFFUSEMAPTEXTURES0_ENABLED] = glGetUniformLocation(program[0], "diffuseMapTextures[0].enabled");
	programConstants[MD_PROGRAM0_DIFFUSEMAPTEXTURES0_TEXTURE] = glGetUniformLocation(program[0], "diffuseMapTextures[0].texture");
	programConstants[MD_PROGRAM0_DIFFUSEMAPTEXTURES1_SIZE] = glGetUniformLocation(program[0], "diffuseMapTextures[1].size");
	programConstants[MD_PROGRAM0_DIFFUSEMAPTEXTURES1_CHILDREN] = glGetUniformLocation(program[0], "diffuseMapTextures[1].children");
	programConstants[MD_PROGRAM0_DIFFUSEMAPTEXTURES1_ENABLED] = glGetUniformLocation(program[0], "diffuseMapTextures[1].enabled");
	programConstants[MD_PROGRAM0_DIFFUSEMAPTEXTURES1_TEXTURE] = glGetUniformLocation(program[0], "diffuseMapTextures[1].texture");
	programConstants[MD_PROGRAM0_DIFFUSEMAPTEXTURES2_SIZE] = glGetUniformLocation(program[0], "diffuseMapTextures[2].size");
	programConstants[MD_PROGRAM0_DIFFUSEMAPTEXTURES2_CHILDREN] = glGetUniformLocation(program[0], "diffuseMapTextures[2].children");
	programConstants[MD_PROGRAM0_DIFFUSEMAPTEXTURES2_ENABLED] = glGetUniformLocation(program[0], "diffuseMapTextures[2].enabled");
	programConstants[MD_PROGRAM0_DIFFUSEMAPTEXTURES2_TEXTURE] = glGetUniformLocation(program[0], "diffuseMapTextures[2].texture");
	
	// Normal program uniform locations
	if (programLocations)
		free(programLocations);
	programLocations = (unsigned int*)malloc(sizeof(unsigned int) * 6);
	programLocations[MD_PROGRAM_MODELVIEWPROJECTION] = glGetUniformLocation(program[1], "modelViewProjection");
	programLocations[MD_PROGRAM_NORMALROTATION] = glGetUniformLocation(program[1], "normalRotation");
	programLocations[MD_PROGRAM_GLOBALROTATION] = glGetUniformLocation(program[1], "globalRotation");
	programLocations[MD_PROGRAM_ENABLENORMALS] = glGetUniformLocation(program[1], "enableNormals");
	programLocations[MD_PROGRAM_ENABLETEXTURES] = glGetUniformLocation(program[1], "enableTextures");
	programLocations[MD_PROGRAM_TEXTURE] = glGetUniformLocation(program[1], "texture1");
	
	// Particle program uniform locations
	if (particleLocations)
		free(particleLocations);
	particleLocations = (unsigned int*)malloc(sizeof(unsigned int) * 4);
	particleLocations[MD_PROGRAM2_MV] = glGetUniformLocation(program[2], "MV");
	particleLocations[MD_PROGRAM2_P] = glGetUniformLocation(program[2], "P");
	particleLocations[MD_PROGRAM2_POINTSIZE] = glGetUniformLocation(program[2], "pointSize");
	particleLocations[MD_PROGRAM2_SCREENWIDTH] = glGetUniformLocation(program[2], "screenWidth");
	
	// Setup shadow textures
	glUseProgram(program[0]);
	const NSString* realTypes[3] = { @"Dir", @"Point", @"Spot" };
	unsigned int shadowNum[3] = { 0, 0, 0 };
	unsigned int realNum = 0;
	for (unsigned long z = 0; z < [ otherObjects count ]; z++)
	{
		if (![ otherObjects[z] isKindOfClass:[ MDLight class ] ])
			continue;
		int y = [ otherObjects[z] lightType];
		unsigned int realT = shadowNum[y]++;
		glUniform1i(glGetUniformLocation(program[0], [ [ NSString stringWithFormat:@"shadowMap%@%i", realTypes[y], realT ] UTF8String ]), 1 + realNum);
		glActiveTexture(1 + realNum);
		glBindTexture(GL_TEXTURE_2D, 0);
		realNum++;
	}
	glActiveTexture(0);
	
	// Set GUI programs
	MDSetGUIProgram(program[1]);
	MDSetGUIProgramLocations(programLocations);
}

- (void) setLightingUniform
{
}

// TODO - change so these are only changed when the light data is edited - in framework too
- (void) setUniforms
{
	unsigned long trueZ = 0;
	for (unsigned long z = 0; z < [ otherObjects count ]; z++)
	{
		if ([ otherObjects[z] isKindOfClass:[ MDLight class ] ])
		{
			MDLight* lightObj = otherObjects[z];
			float light[26];
			[ lightObj lightData:light ];
			
			unsigned int location = (unsigned int)(trueZ * 12);
			glUniform4fv(lightingLocations[location + 0], 1, &light[0]);
			glUniform4fv(lightingLocations[location + 1], 1, &light[4]);
			glUniform4fv(lightingLocations[location + 2], 1, &light[8]);
			glUniform4fv(lightingLocations[location + 3], 1, &light[12]);
			glUniform3fv(lightingLocations[location + 4], 1, &light[16]);
			glUniform1f(lightingLocations[location + 5], light[19]);
			glUniform1f(lightingLocations[location + 6], light[20]);
			glUniform1f(lightingLocations[location + 7], light[21]);
			glUniform1f(lightingLocations[location + 8], light[22]);
			glUniform1f(lightingLocations[location + 9], light[23]);
			glUniform1f(lightingLocations[location + 10], light[24]);
			glUniform1i(lightingLocations[location + 11], (unsigned int)(light[25] + 0.5));	// Rounds
			trueZ++;
		}
	}
}

/*
 * Initial OpenGL setup
 */
- (BOOL) initGL
{ 
	glShadeModel( GL_SMOOTH );                // Enable smooth shading
	glClearColor( 0.0f, 0.0f, 0.0f, 0.5f );   // Black background
	glClear(GL_DEPTH_BUFFER_BIT);
	glClearDepth( 1.0f );                     // Depth buffer setup
	glEnable( GL_DEPTH_TEST );                // Enable depth testing
	glDepthFunc( GL_LEQUAL );                 // Type of depth test to do
	
	//glEnable(GL_POINT_SMOOTH);
	glEnable(GL_LINE_SMOOTH);
	glEnable(GL_POLYGON_SMOOTH);
	glHint( GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST );
	glHint(GL_LINE_SMOOTH_HINT, GL_NICEST);
	//glHint(GL_POINT_SMOOTH_HINT, GL_NICEST);
	glHint(GL_POLYGON_SMOOTH_HINT, GL_NICEST);
	
	glEnable(GL_TEXTURE_CUBE_MAP_SEAMLESS);
	
	return TRUE;
}

- (void) setupVAOs
{
	// Setup VAOs
	if (gridData[0] == 0)
	{
		float verts[44 * 3];
		for (int z = 0; z <= 10; z++)
		{
			verts[z * 6] = -5 + z;
			verts[(z * 6) + 1] = -0.01;
			verts[(z * 6) + 2] = 5;
			verts[(z * 6) + 3] = -5 + z;
			verts[(z * 6) + 4] = -0.01;
			verts[(z * 6) + 5] = -5;
		}
		for (int z = 0; z <= 10; z++)
		{
			verts[(z * 6) + 66] = -5;
			verts[(z * 6) + 67] = -0.01;
			verts[(z * 6) + 68] = z - 5;
			verts[(z * 6) + 69] = 5;
			verts[(z * 6) + 70] = -0.01;
			verts[(z * 6) + 71] = z - 5;
		}
		
		glGenVertexArrays(1, &gridData[0]);
		glBindVertexArray(gridData[0]);
		
		glGenBuffers(1, &gridData[1]);
		glBindBuffer(GL_ARRAY_BUFFER, gridData[1]);
		glBufferData(GL_ARRAY_BUFFER, 44 * 3 * sizeof(float), verts, GL_STATIC_DRAW);
		glVertexAttribPointer(0, 3, GL_FLOAT, NO, 0, NULL);
		glEnableVertexAttribArray(0);
		glBindVertexArray(0);
	}
	if (boxData[0] == 0)
	{
		float verts[24 * 3] = {
			-0.5, -0.5, -0.5,
			0.5, -0.5, -0.5,
			
			0.5, -0.5, -0.5,
			0.5, -0.5, 0.5,
			
			0.5, -0.5, 0.5,
			-0.5, -0.5, 0.5,
			
			-0.5, -0.5, 0.5,
			-0.5, -0.5, -0.5,
			
			-0.5, 0.5, -0.5,
			0.5, 0.5, -0.5,
			
			0.5, 0.5, -0.5,
			0.5, 0.5, 0.5,
			
			0.5, 0.5, 0.5,
			-0.5, 0.5, 0.5,
			
			-0.5, 0.5, 0.5,
			-0.5, 0.5, -0.5,
			
			-0.5, -0.5, -0.5,
			-0.5, 0.5, -0.5,
			
			0.5, -0.5, -0.5,
			0.5, 0.5, -0.5,
			
			-0.5, -0.5, 0.5,
			-0.5, 0.5, 0.5,
			
			0.5, -0.5, 0.5,
			0.5, 0.5, 0.5,
		};
		
		glGenVertexArrays(1, &boxData[0]);
		glBindVertexArray(boxData[0]);
		
		glGenBuffers(1, &boxData[1]);
		glBindBuffer(GL_ARRAY_BUFFER, boxData[1]);
		glBufferData(GL_ARRAY_BUFFER, 24 * 3 * sizeof(float), verts, GL_STATIC_DRAW);
		glVertexAttribPointer(0, 3, GL_FLOAT, NO, 0, NULL);
		glEnableVertexAttribArray(0);
		glBindVertexArray(0);
	}
	if (projectData[0] == 0)
	{
		float verts[] = { -100, 0, -100, 100, 0, -100, -100, 0, 100, 100, 0, 100 };
		
		glGenVertexArrays(1, &projectData[0]);
		glBindVertexArray(projectData[0]);
		
		glGenBuffers(1, &projectData[1]);
		glBindBuffer(GL_ARRAY_BUFFER, projectData[1]);
		glBufferData(GL_ARRAY_BUFFER, 4 * 3 * sizeof(float), verts, GL_STATIC_DRAW);
		glVertexAttribPointer(0, 3, GL_FLOAT, NO, 0, NULL);
		glEnableVertexAttribArray(0);
		glBindVertexArray(0);
	}
	if (cubeData[0] == 0)
	{
		float distance = 0.2;
		float verts[] = {
			// Front Face
			-distance / 2, -distance / 2, distance / 2,
			distance / 2, -distance / 2, distance / 2,
			-distance / 2, distance / 2, distance / 2,
			distance / 2, distance / 2, distance / 2,
			-distance / 2, distance / 2, distance / 2,
			distance / 2, -distance / 2, distance / 2,
			
			// Back Face
			distance / 2, -distance / 2, -distance / 2,
			-distance / 2, -distance / 2, -distance / 2,
			-distance / 2, distance / 2, -distance / 2,
			-distance / 2, distance / 2, -distance / 2,
			distance / 2, distance / 2, -distance / 2,
			distance / 2, -distance / 2, -distance / 2,
			
			// Right Face
			distance / 2, distance / 2, distance / 2,
			distance / 2, -distance / 2, distance / 2,
			distance / 2, distance / 2, -distance / 2,
			distance / 2, -distance / 2, -distance / 2,
			distance / 2, distance / 2, -distance / 2,
			distance / 2, -distance / 2, distance / 2,
			
			// Left Face
			-distance / 2, -distance / 2, distance / 2,
			-distance / 2, distance / 2, distance / 2,
			-distance / 2, distance / 2, -distance / 2,
			-distance / 2, distance / 2, -distance / 2,
			-distance / 2, -distance / 2, -distance / 2,
			-distance / 2, -distance / 2, distance / 2,
			
			// Top Face
			-distance / 2, distance / 2, distance / 2,
			distance / 2, distance / 2, distance / 2,
			distance / 2, distance / 2, -distance / 2,
			distance / 2, distance / 2, -distance / 2,
			-distance / 2, distance / 2, -distance / 2,
			-distance / 2, distance / 2, distance / 2,
			
			// Bottom Face
			distance / 2, -distance / 2, distance / 2,
			-distance / 2, -distance / 2, distance / 2,
			distance / 2, -distance / 2, -distance / 2,
			-distance / 2, -distance / 2, -distance / 2,
			distance / 2, -distance / 2, -distance / 2,
			-distance / 2, -distance / 2, distance / 2,
		};
		float norms[] = {
			// Front Face
			0, 0, 1,
			0, 0, 1,
			0, 0, 1,
			0, 0, 1,
			0, 0, 1,
			0, 0, 1,
			
			// Back Face
			0, 0, -1,
			0, 0, -1,
			0, 0, -1,
			0, 0, -1,
			0, 0, -1,
			0, 0, -1,
			
			// Right Face
			1, 0, 0,
			1, 0, 0,
			1, 0, 0,
			1, 0, 0,
			1, 0, 0,
			1, 0, 0,
			
			// Left Face
			-1, 0, 0,
			-1, 0, 0,
			-1, 0, 0,
			-1, 0, 0,
			-1, 0, 0,
			-1, 0, 0,
			
			// Top Face
			0, 1, 0,
			0, 1, 0,
			0, 1, 0,
			0, 1, 0,
			0, 1, 0,
			0, 1, 0,
			
			// Bottom Face
			0, -1, 0,
			0, -1, 0,
			0, -1, 0,
			0, -1, 0,
			0, -1, 0,
			0, -1, 0,
		};
		
		glGenVertexArrays(1, &cubeData[0]);
		glBindVertexArray(cubeData[0]);
		
		glGenBuffers(1, &cubeData[1]);
		glBindBuffer(GL_ARRAY_BUFFER, cubeData[1]);
		glBufferData(GL_ARRAY_BUFFER, 36 * 3 * sizeof(float), verts, GL_STATIC_DRAW);
		glVertexAttribPointer(0, 3, GL_FLOAT, NO, 0, NULL);
		glEnableVertexAttribArray(0);
		
		glGenBuffers(1, &cubeData[2]);
		glBindBuffer(GL_ARRAY_BUFFER, cubeData[2]);
		glBufferData(GL_ARRAY_BUFFER, 36 * 3 * sizeof(float), norms, GL_STATIC_DRAW);
		glVertexAttribPointer(2, 3, GL_FLOAT, NO, 0, NULL);
		glEnableVertexAttribArray(2);
		
		glBindVertexArray(0);
	}
	[ self updateSkybox ];
}

- (void) updateSkybox
{
	if (skyboxData[0])
	{
		if (glIsVertexArray(skyboxData[0]))
			glDeleteVertexArrays(1, &skyboxData[0]);
		skyboxData[0] = 0;
	}
	if (skyboxData[1])
	{
		if (glIsBuffer(skyboxData[1]))
			glDeleteBuffers(1, &skyboxData[1]);
		skyboxData[1] = 0;
	}
	if (skyboxData[2])
	{
		if (glIsBuffer(skyboxData[2]))
			glDeleteBuffers(1, &skyboxData[2]);
		skyboxData[2] = 0;
	}
	
	float distance = [ sceneProperties[@"Skybox Distance"] floatValue ];
	float correction = [ sceneProperties[@"Skybox Correction"] floatValue ];
	
	float verts[] = {
		// Front Face
		-distance / 2, -distance / 2, distance / 2,
		distance / 2, -distance / 2, distance / 2,
		-distance / 2, distance / 2, distance / 2,
		-distance / 2, distance / 2, distance / 2,
		distance / 2, distance / 2, distance / 2,
		distance / 2, -distance / 2, distance / 2,
		
		// Back Face
		-distance / 2, -distance / 2, -distance / 2,
		distance / 2, -distance / 2, -distance / 2,
		-distance / 2, distance / 2, -distance / 2,
		-distance / 2, distance / 2, -distance / 2,
		distance / 2, distance / 2, -distance / 2,
		distance / 2, -distance / 2, -distance / 2,
		
		// Right Face
		distance / 2, -distance / 2, distance / 2,
		distance / 2, distance / 2, distance / 2,
		distance / 2, distance / 2, -distance / 2,
		distance / 2, distance / 2, -distance / 2,
		distance / 2, -distance / 2, -distance / 2,
		distance / 2, -distance / 2, distance / 2,
		
		// Left Face
		-distance / 2, -distance / 2, distance / 2,
		-distance / 2, distance / 2, distance / 2,
		-distance / 2, distance / 2, -distance / 2,
		-distance / 2, distance / 2, -distance / 2,
		-distance / 2, -distance / 2, -distance / 2,
		-distance / 2, -distance / 2, distance / 2,
		
		// Top Face
		-distance / 2, distance / 2, distance / 2,
		distance / 2, distance / 2, distance / 2,
		distance / 2, distance / 2, -distance / 2,
		distance / 2, distance / 2, -distance / 2,
		-distance / 2, distance / 2, -distance / 2,
		-distance / 2, distance / 2, distance / 2,
		
		// Bottom Face
		-distance / 2, -distance / 2, distance / 2,
		distance / 2, -distance / 2, distance / 2,
		distance / 2, -distance / 2, -distance / 2,
		distance / 2, -distance / 2, -distance / 2,
		-distance / 2, -distance / 2, -distance / 2,
		-distance / 2, -distance / 2, distance / 2,
	};
	float texCoords[] = {
		// Front Face
		1 / 4.0, (float)(1 / 3.0 + correction),
		2 / 4.0, (float)(1 / 3.0 + correction),
		1 / 4.0, (float)(2 / 3.0 - correction),
		1 / 4.0, (float)(2 / 3.0 - correction),
		2 / 4.0, (float)(2 / 3.0 - correction),
		2 / 4.0, (float)(1 / 3.0 + correction),
		
		// Back Face
		4 / 4.0, (float)(1 / 3.0 + correction),
		3 / 4.0, (float)(1 / 3.0 + correction),
		4 / 4.0, (float)(2 / 3.0 - correction),
		4 / 4.0, (float)(2 / 3.0 - correction),
		3 / 4.0, (float)(2 / 3.0 - correction),
		3 / 4.0, (float)(1 / 3.0 + correction),
		
		// Right Face
		2 / 4.0, (float)(1 / 3.0 + correction),
		2 / 4.0, (float)(2 / 3.0 - correction),
		3 / 4.0, (float)(2 / 3.0 - correction),
		3 / 4.0, (float)(2 / 3.0 - correction),
		3 / 4.0, (float)(1 / 3.0 + correction),
		2 / 4.0, (float)(1 / 3.0 + correction),
		
		// Left Face
		1 / 4.0, (float)(1 / 3.0 + correction),
		1 / 4.0, (float)(2 / 3.0 - correction),
		0 / 4.0, (float)(2 / 3.0 - correction),
		0 / 4.0, (float)(2 / 3.0 - correction),
		0 / 4.0, (float)(1 / 3.0 + correction),
		1 / 4.0, (float)(1 / 3.0 + correction),
		
		// Top Face
		(float)(1 / 4.0 + correction), (float)(2 / 3.0 + correction),
		(float)(2 / 4.0 - correction), (float)(2 / 3.0 + correction),
		(float)(2 / 4.0 - correction), (float)(3 / 3.0 - correction),
		(float)(2 / 4.0 - correction), (float)(3 / 3.0 - correction),
		(float)(1 / 4.0 + correction), (float)(3 / 3.0 - correction),
		(float)(1 / 4.0 + correction), (float)(2 / 3.0 + correction),
		
		// Bottom Face
		(float)(1 / 4.0 + correction), (float)(1 / 3.0 - correction),
		(float)(2 / 4.0 - correction), (float)(1 / 3.0 - correction),
		(float)(2 / 4.0 - correction), (float)(0 / 3.0 + correction),
		(float)(2 / 4.0 - correction), (float)(0 / 3.0 + correction),
		(float)(1 / 4.0 + correction), (float)(0 / 3.0 + correction),
		(float)(1 / 4.0 + correction), (float)(1 / 3.0 - correction),
	};
	
	glGenVertexArrays(1, &skyboxData[0]);
	glBindVertexArray(skyboxData[0]);
	
	glGenBuffers(1, &skyboxData[1]);
	glBindBuffer(GL_ARRAY_BUFFER, skyboxData[1]);
	glBufferData(GL_ARRAY_BUFFER, 36 * 3 * sizeof(float), verts, GL_STATIC_DRAW);
	glVertexAttribPointer(0, 3, GL_FLOAT, NO, 0, NULL);
	glEnableVertexAttribArray(0);
	
	glGenBuffers(1, &skyboxData[2]);
	glBindBuffer(GL_ARRAY_BUFFER, skyboxData[2]);
	glBufferData(GL_ARRAY_BUFFER, 36 * 2 * sizeof(float), texCoords, GL_STATIC_DRAW);
	glVertexAttribPointer(3, 2, GL_FLOAT, NO, 0, NULL);
	glEnableVertexAttribArray(3);
	
	glBindVertexArray(0);
}


/*
 * Resize ourself
 */
- (void) reshape
{
	NSRect sceneBounds;
	
	[ [ self openGLContext ] update ];
	sceneBounds = [ self bounds ];
	
	glUseProgram(program[2]);
	if (particleLocations)
		glUniform1f(particleLocations[MD_PROGRAM2_SCREENWIDTH], sceneBounds.size.width);
	glUseProgram(program[1]);
	
	NSSize oldRes = resolution;
	resolution = sceneBounds.size;
	windowSize = sceneBounds.size;
	
	if (!(MDFloatCompare(oldRes.width, resolution.width) && MDFloatCompare(oldRes.height, resolution.height)) || pickingBuffer[0] == 0)
	{
		// Setup framebuffers
		if (pickingBuffer[5])
		{
			if (glIsRenderbuffer(pickingBuffer[5]))
				glDeleteRenderbuffers(1, &pickingBuffer[5]);
			pickingBuffer[5] = 0;
		}
		if (pickingBuffer[4])
		{
			if (glIsRenderbuffer(pickingBuffer[4]))
				glDeleteRenderbuffers(1, &pickingBuffer[4]);
			pickingBuffer[4] = 0;
		}
		if (pickingBuffer[3])
		{
			if (glIsFramebuffer(pickingBuffer[3]))
				glDeleteFramebuffers(1, &pickingBuffer[3]);
			pickingBuffer[3] = 0;
		}
		if (pickingBuffer[2])
		{
			if (glIsRenderbuffer(pickingBuffer[2]))
				glDeleteRenderbuffers(1, &pickingBuffer[2]);
			pickingBuffer[2] = 0;
		}
		if (pickingBuffer[1])
		{
			if (glIsRenderbuffer(pickingBuffer[1]))
				glDeleteRenderbuffers(1, &pickingBuffer[1]);
			pickingBuffer[1] = 0;
		}
		if (pickingBuffer[0])
		{
			if (glIsFramebuffer(pickingBuffer[0]))
				glDeleteFramebuffers(1, &pickingBuffer[0]);
			pickingBuffer[0] = 0;
		}
		glGenRenderbuffers(1, &pickingBuffer[2]);
		glBindRenderbuffer(GL_RENDERBUFFER, pickingBuffer[2]);
		glRenderbufferStorageMultisample(GL_RENDERBUFFER, 1, GL_DEPTH_COMPONENT, resolution.width, resolution.height);
		glBindRenderbuffer(GL_RENDERBUFFER, 0);
		
		glGenRenderbuffers(1, &pickingBuffer[1]);
		glBindRenderbuffer(GL_RENDERBUFFER, pickingBuffer[1]);
		glRenderbufferStorageMultisample(GL_RENDERBUFFER, 1, GL_RGB, resolution.width, resolution.height);
		glBindRenderbuffer(GL_RENDERBUFFER, 0);
		
		glGenFramebuffers(1, &pickingBuffer[0]);
		glBindFramebuffer(GL_FRAMEBUFFER, pickingBuffer[0]);
		
		glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, pickingBuffer[1]);
		glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, pickingBuffer[2]);
		
		if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
			NSLog(@"FBOs not supported - 0x%X.", glCheckFramebufferStatus(GL_FRAMEBUFFER));
		
		glBindFramebuffer(GL_FRAMEBUFFER, 0);
		
		glGenRenderbuffers(1, &pickingBuffer[5]);
		glBindRenderbuffer(GL_RENDERBUFFER, pickingBuffer[5]);
		glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT, resolution.width, resolution.height);
		glBindRenderbuffer(GL_RENDERBUFFER, 0);
		
		glGenRenderbuffers(1, &pickingBuffer[4]);
		glBindRenderbuffer(GL_RENDERBUFFER, pickingBuffer[4]);
		glRenderbufferStorage(GL_RENDERBUFFER, GL_RGB, resolution.width, resolution.height);
		glBindRenderbuffer(GL_RENDERBUFFER, 0);
		
		glGenFramebuffers(1, &pickingBuffer[3]);
		glBindFramebuffer(GL_FRAMEBUFFER, pickingBuffer[3]);
		
		glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, pickingBuffer[4]);
		//glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, pickingBuffer[5]);	// Depth buffer not needed for this one
		
		if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
			NSLog(@"FBOs not supported - 0x%X.", glCheckFramebufferStatus(GL_FRAMEBUFFER));
		
		glBindFramebuffer(GL_FRAMEBUFFER, 0);
	}
	
	// Update box
	MDRotationBox* box = ViewForIdentity(@"Rotation Box");
	[ box setFrame:MakeRect(TX(windowSize.width * 0.51 + 280, 2), TY(35, 2), -2, TW(50, 2), TW(50, 2), TW(50, 2)) ];
	
	glViewport( 0, 0, sceneBounds.size.width, sceneBounds.size.height );
	projectionMatrix = MDMatrixIdentity();
	MDMatrixSetPerspective(&projectionMatrix, 45.0, sceneBounds.size.width / sceneBounds.size.height, 0.1, 1000.0);
}

- (void) updateFPS
{
	truefps = fpsCounter;
	fpsCounter = 0;
}

- (void) writeString: (NSString*) str textColor: (NSColor*) text 
			boxColor: (NSColor*) box borderColor: (NSColor*) border
		  atLocation: (NSPoint) location withSize: (double) dsize 
		withFontName: (NSString*) fontName rotation:(float) rot center:(BOOL)align
{
	// Init string and font
	NSFont* font = [ NSFont fontWithName:fontName size:dsize ];
	if (font == nil)
		return;
	
	GLString* string = [ [ GLString alloc ] initWithString:str withAttributes:@{NSForegroundColorAttributeName: text, NSFontAttributeName: font} withTextColor: text withBoxColor: box withBorderColor: border ];
	
	NSSize internalRes = [ self bounds ].size;
	MDMatrix model = MDMatrixIdentity();
	MDMatrixScale(&model, 2.0 / internalRes.width, -2.0 / internalRes.height, 1.0);
	MDMatrixTranslate(&model, -internalRes.width / 2.0, -internalRes.height / 2.0, 0.0);
	NSSize frameSize = [ string frameSize ];
	MDMatrixTranslate(&model, location.x + (frameSize.width / 2), location.y + (frameSize.height / 2), 0);
	MDMatrixRotate(&model, 0, 0, 1, rot);
	MDMatrixTranslate(&model, -(location.x + (frameSize.width / 2)), -(location.y + (frameSize.height / 2)), 0);
	if (align)
		MDMatrixTranslate(&model, -frameSize.width / 2, -frameSize.height / 2, 0);
	MDMatrixTranslate(&model, location.x, location.y, 0);
	float scale = 1 / [ [ NSScreen mainScreen ] backingScaleFactor ];
	MDMatrixScale(&model, scale, scale, 1);
	
	glUniformMatrix4fv(programLocations[MD_PROGRAM_MODELVIEWPROJECTION], 1, NO, model.data);
	glUniform1i(programLocations[MD_PROGRAM_ENABLENORMALS], 0);
	glUniform1i(programLocations[MD_PROGRAM_ENABLETEXTURES], 1);
	glUniform1i(programLocations[MD_PROGRAM_TEXTURE], 0);
	[ string drawAtPoint:location ];
	
	glEnable(GL_DEPTH_TEST);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
}

- (int) pick: (NSPoint) point withFlags:(unsigned long)flags
{
	glUseProgram(program[1]);
	glUniform1i(programLocations[MD_PROGRAM_ENABLENORMALS], 0);
	glUniform1i(programLocations[MD_PROGRAM_ENABLETEXTURES], 0);
	glBindFramebuffer(GL_FRAMEBUFFER, pickingBuffer[0]);
	glEnable(GL_DEPTH_TEST);
	glDepthFunc(GL_LEQUAL);
	glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);
	
	projectionMatrix = MDMatrixIdentity();
	MDMatrixSetPerspective(&projectionMatrix, 45.0, resolution.width / resolution.height, 0.1, 1000.0);
	if (currentCamera != -1 && [ otherObjects[currentCamera] isKindOfClass:[ MDCamera class ] ])
	{
		MDCamera* camera = otherObjects[currentCamera];
		if ([ camera use ])
		{
			MDVector3 cameraPoint = [ camera midPoint ];
			MDVector3 cameraLook = [ camera lookPoint ];
			float cameraOrientation = [ camera orientation ];
			// Setup ModelView Matrix
			modelViewMatrix = MDMatrixIdentity();
			MDMatrixLookAt(&modelViewMatrix, cameraPoint, cameraLook, MDVector3Create(sin(cameraOrientation / 180 * M_PI), cos(cameraOrientation / 180 * M_PI), 0));
		}
	}
	else
	{
		MDRotationBox* box = ViewForIdentity(@"Rotation Box");
		// Setup ModelView Matrix
		modelViewMatrix = MDMatrixIdentity();
		MDMatrixTranslate(&modelViewMatrix, -translationPoint.x, -translationPoint.y, translationPoint.z);
		MDMatrixTranslate(&modelViewMatrix, lookPoint);
		MDMatrixRotate(&modelViewMatrix, 1, 0, 0, [ box xrotation ]);
		MDMatrixRotate(&modelViewMatrix, 0, 1, 0, [ box yrotation ]);
		MDMatrixRotate(&modelViewMatrix, 0, 0, 1, [ box zrotation ]);
		MDMatrixTranslate(&modelViewMatrix, -1 * lookPoint);
	}
	
#define SEED	255
	
	glEnable(GL_CULL_FACE);
	glCullFace(GL_BACK);
	glFrontFace(GL_CCW);
	
	unsigned int totalPicks = 1;
	
	if (currentCamera == -1)
	{
		for (unsigned long z = 0; z < [ otherObjects count ]; z++)
		{
			if ([ otherObjects[z] isKindOfClass:[ MDCamera class ] ])
			{
				MDCamera* camera = otherObjects[z];
				if ([ camera show ] && ![ camera use ])
				{
					MDVector3 midPoint = [ camera midPoint ];
					MDVector3 look = [ camera lookPoint ];
					if (look.x == midPoint.x)
						look.x += 0.00001;
					float yrot = (atan2f(look.x - midPoint.x, look.z - midPoint.z) / M_PI * 180) + 90;
					MDVector3 zPoint = Rotate(MDVector3Create(look.y - midPoint.y, look.x - midPoint.x, 0), MDVector3Create(0, 0, 0), 0, yrot, 0);
					float zrot = -(atan2f(zPoint.y, zPoint.x) / M_PI * 180) - 90;
					if (yrot >= 90 && yrot < 270)
						zrot += 180;
					float xrot = [ camera orientation ];
					MDVector3 rotatePoint = Rotate(MDVector3Create(0, 0.3, 0), MDVector3Create(0, 0, 0), 0, yrot, zrot);
			
					MDMatrix cameraMatrix = MDMatrixIdentity();
					MDMatrixTranslate(&cameraMatrix, midPoint + rotatePoint);
					MDMatrixRotate(&cameraMatrix, 0, 1, 0, yrot);
					MDMatrixRotate(&cameraMatrix, 0, 0, 1, zrot);
					MDMatrixTranslate(&cameraMatrix, -1 * rotatePoint);
					MDMatrixRotate(&cameraMatrix, 1, 0, 0, xrot);
					MDMatrixTranslate(&cameraMatrix, rotatePoint);
					glUniformMatrix4fv(programLocations[MD_PROGRAM_MODELVIEWPROJECTION], 1, NO, (projectionMatrix * modelViewMatrix * cameraMatrix).data);
					float red = (totalPicks % SEED) / (float)SEED;
					float green = ((totalPicks / SEED) % SEED) / (float)SEED;
					float blue = ((totalPicks / SEED / SEED) % SEED) / (float)SEED;
					[ models[0].instance drawVBOColor:MDVector4Create(red, green, blue, 1) ];
					
					totalPicks += 4;
					MDMatrix translate = MDMatrixIdentity();
					MDMatrixTranslate(&translate, look);
					glUniformMatrix4fv(programLocations[MD_PROGRAM_MODELVIEWPROJECTION], 1, NO, (projectionMatrix * modelViewMatrix * translate).data);
					red = (totalPicks % SEED) / (float)SEED;
					green = ((totalPicks / SEED) % SEED) / (float)SEED;
					blue = ((totalPicks / SEED / SEED) % SEED) / (float)SEED;
					glVertexAttrib4f(1, red, green, blue, 1);
					gluSphere(0.1, 16, 16);
					totalPicks -= 4;
					
					if ([ camera selected ])
					{
						if (currentObjectTool == MD_OBJECT_MOVE)
							DrawObjectTool([ camera obj ], currentObjectTool, translationPoint.z, totalPicks, [ camera obj ], projectionMatrix, modelViewMatrix, programLocations);
					}
					else if ([ camera lookSelected ])
					{
						if (currentObjectTool == MD_OBJECT_MOVE)
						{
							DrawObjectTool([ camera lookObj ], currentObjectTool, translationPoint.z, totalPicks + 4, [ camera lookObj ], projectionMatrix, modelViewMatrix, programLocations);
						}
					}
				}
				totalPicks += 8;
			}
			else if ([ otherObjects[z] isKindOfClass:[ MDLight class ] ])
			{
				MDLight* light = otherObjects[z];
				if ([ light show ])
				{
					MDVector3 midPoint = light.position;
					MDVector3 look = light.spotDirection;
					
					if (light.lightType != MDPointLight)
					{
						if (look.x == midPoint.x)
							look.x += 0.00001;
						float yrot = (atan2f(look.x - midPoint.x, look.z - midPoint.z) / M_PI * 180) + 90;
						MDVector3 zPoint = Rotate(MDVector3Create(look.y - midPoint.y, look.x - midPoint.x, 0), MDVector3Create(0, 0, 0), 0, yrot, 0);
						float zrot = -(atan2f(zPoint.y, zPoint.x) / M_PI * 180) - 90;
						if (yrot >= 90 && yrot < 270)
							zrot += 180;
						MDMatrix lightMatrix = MDMatrixIdentity();
						MDMatrixTranslate(&lightMatrix, midPoint);
						MDMatrixRotate(&lightMatrix, 0, 1, 0, yrot);
						MDMatrixRotate(&lightMatrix, 0, 0, 1, zrot);
						
						glUniformMatrix4fv(programLocations[MD_PROGRAM_MODELVIEWPROJECTION], 1, NO, (projectionMatrix * modelViewMatrix * lightMatrix).data);
						float red = (totalPicks % SEED) / (float)SEED;
						float green = ((totalPicks / SEED) % SEED) / (float)SEED;
						float blue = ((totalPicks / SEED / SEED) % SEED) / (float)SEED;
						[ models[light.lightType + 1].instance drawVBOColor:MDVector4Create(red, green, blue, 1) ];
					}
					else
					{
						MDMatrix lightMatrix = MDMatrixIdentity();
						MDMatrixTranslate(&lightMatrix, midPoint);
						glUniformMatrix4fv(programLocations[MD_PROGRAM_MODELVIEWPROJECTION], 1, NO, (projectionMatrix * modelViewMatrix * lightMatrix).data);
						float red = (totalPicks % SEED) / (float)SEED;
						float green = ((totalPicks / SEED) % SEED) / (float)SEED;
						float blue = ((totalPicks / SEED / SEED) % SEED) / (float)SEED;
						[ models[light.lightType + 1].instance drawVBOColor:MDVector4Create(red, green, blue, 1) ];
					}
					
					if ([ light selected ])
					{
						if (currentObjectTool == MD_OBJECT_MOVE)
							DrawObjectTool([ light obj ], currentObjectTool, translationPoint.z, totalPicks, [ light obj ], projectionMatrix, modelViewMatrix, programLocations);
					}
				}
				totalPicks += 8;
			}
			else if ([ otherObjects[z] isKindOfClass:[ MDSound class ] ])
			{
				MDSound* sound = otherObjects[z];
				if ([ sound show ])
				{
					MDMatrix soundMatrix = MDMatrixIdentity();
					MDMatrixTranslate(&soundMatrix, [ sound position ]);
					glUniformMatrix4fv(programLocations[MD_PROGRAM_MODELVIEWPROJECTION], 1, NO, (projectionMatrix * modelViewMatrix * soundMatrix).data);
					float red = (totalPicks % SEED) / (float)SEED;
					float green = ((totalPicks / SEED) % SEED) / (float)SEED;
					float blue = ((totalPicks / SEED / SEED) % SEED) / (float)SEED;
					[ models[4].instance drawVBOColor:MDVector4Create(red, green, blue, 1) ];

					if ([ sound selected ])
					{
						if (currentObjectTool == MD_OBJECT_MOVE)
							DrawObjectTool([ sound obj ], currentObjectTool, translationPoint.z, totalPicks, [ sound obj ], projectionMatrix, modelViewMatrix, programLocations);
					}
				}
				totalPicks += 8;
			}
		}
	}

	MDMatrix modelViewProjection = projectionMatrix * modelViewMatrix;
	unsigned int cameraNames = totalPicks;
	for (unsigned long z = 0; z < [ objects count ]; z++)
	{
		MDObject* obj = objects[z];
		
		if (![ obj shouldDraw ] || ![ obj shouldView ])
		{
			totalPicks += 4;
			continue;
		}
		
		if (currentMode == MD_OBJECT_MODE)
		{
			unsigned int negScales = 0;
			if (obj.scaleX < 0)
				negScales++;
			if (obj.scaleY < 0)
				negScales++;
			if (obj.scaleZ < 0)
				negScales++;
			glFrontFace(((negScales % 2) == 0) ? GL_CCW : GL_CW);
			
			glUniformMatrix4fv(programLocations[MD_PROGRAM_MODELVIEWPROJECTION], 1, NO, (modelViewProjection * [ obj modelViewMatrix ]).data);
			float red = (totalPicks % SEED) / (float)SEED;
			float green = ((totalPicks / SEED) % SEED) / (float)SEED;
			float blue = ((totalPicks / SEED / SEED) % SEED) / (float)SEED;
			[ [ obj instance ] drawVBOColor:MDVector4Create(red, green, blue, 1) ];
			if ([ selected containsObject:obj withPoints:nil ])
			{
				glDisable(GL_CULL_FACE);
				DrawObjectTool(obj, currentObjectTool, translationPoint.z, totalPicks, obj, projectionMatrix, modelViewMatrix, programLocations);
				glEnable(GL_CULL_FACE);
			}
			totalPicks += 4;
		}
		else if (currentMode == MD_VERTEX_MODE)
		{
			glBindVertexArray(cubeData[0]);
			for (unsigned long q = 0; q < [ obj numberOfPoints ]; q++)
			{
				MDPoint* p = [ obj pointAtIndex:q ];
				
				MDMatrix vertexMatrix = MDMatrixIdentity();
				MDMatrixTranslate(&vertexMatrix, p.x + obj.translateX, p.y + obj.translateY, p.z + obj.translateZ);
				glUniformMatrix4fv(programLocations[MD_PROGRAM_MODELVIEWPROJECTION], 1, NO, (modelViewProjection * vertexMatrix).data);
				float red = (totalPicks % SEED) / (float)SEED;
				float green = ((totalPicks / SEED) % SEED) / (float)SEED;
				float blue = ((totalPicks / SEED / SEED) % SEED) / (float)SEED;
				glVertexAttrib4d(1, red, green, blue, 1);
				glDrawArrays(GL_TRIANGLES, 0, 36);
				if ([ selected containsObject:obj withPoints:@[[ obj pointAtIndex:q ]] ])
				{
					glDisable(GL_CULL_FACE);
					MDInstance* instance = mdCube(p.x + obj.translateX, p.y + obj.translateY, p.z + obj.translateZ, 0.3, 0.3, 0.3);
					MDObject* pointObj = [ [ MDObject alloc ] initWithInstance:instance ];
					DrawObjectTool(pointObj, currentObjectTool, translationPoint.z, 0, obj, projectionMatrix, modelViewMatrix, programLocations);
					pointObj = nil;
					instance = nil;
					glEnable(GL_CULL_FACE);
				}
				totalPicks += 4;
			}
			glBindVertexArray(0);
		}
	}
	
	glDisable(GL_CULL_FACE);
	
	glBindFramebuffer(GL_FRAMEBUFFER, 0);
	glBindFramebuffer(GL_READ_FRAMEBUFFER, pickingBuffer[0]);
	glBindFramebuffer(GL_DRAW_FRAMEBUFFER, pickingBuffer[3]);
	glBlitFramebuffer(0, 0, resolution.width, resolution.height, 0, 0, resolution.width, resolution.height, GL_COLOR_BUFFER_BIT, GL_NEAREST);
	glBindFramebuffer(GL_FRAMEBUFFER, pickingBuffer[3]);
	
	float pixels[3];
	glReadPixels(point.x, point.y, 1, 1, GL_RGB, GL_FLOAT, &pixels);
	
	glBindFramebuffer(GL_FRAMEBUFFER, 0);
	
	unsigned int number = round(pixels[0] * SEED) + (round(pixels[1] * SEED) * SEED) + (round(pixels[2] * SEED) * SEED * SEED);

	if (number != 0)
	{
		for (int z = 0; z < [ otherObjects count ]; z++)
		{
			if (![ otherObjects[z] isKindOfClass:[ MDParticleEngine class ] ] && ![ otherObjects[z] isKindOfClass:[ MDCurve class ] ])
			{
				if (!(flags & NSCommandKeyMask))
				{
					[ otherObjects[z] setSelected:NO ];
					if ([ otherObjects[z] isKindOfClass:[ MDCamera class ] ])
						[ otherObjects[z] setLookSelected:NO ];
				}
			}
		}
	}
	if (number == 0)
	{
		for (int z = 0; z < [ otherObjects count ]; z++)
		{
			[ otherObjects[z] setSelected:NO ];
			if ([ otherObjects[z] isKindOfClass:[ MDCamera class ] ])
				[ otherObjects[z] setLookSelected:NO ];
		}
		[ selected clear ];
		commandFlag |= UPDATE_INFO;
		commandFlag |= UPDATE_OTHER_INFO;
	}
	else if (number < cameraNames)
	{
		[ selected clear ];
		commandFlag |= UPDATE_INFO;
		for (int z = 0; z < [ otherObjects count ]; z++)
		{
			[ otherObjects[z] setSelected:NO ];
			if ([ otherObjects[z] isKindOfClass:[ MDCamera class ] ])
				[ otherObjects[z] setLookSelected:NO ];
		}
		
		unsigned int choose = number - 1;
		unsigned int cam = 0;
		unsigned int realIndex = -1;
		for (unsigned long z = 0; z < [ otherObjects count ]; z++)
		{
			if ([ otherObjects[z] isKindOfClass:[ MDCamera class ] ])
				realIndex++;
			else if ([ otherObjects[z] isKindOfClass:[ MDLight class ] ])
				realIndex++;
			else if ([ otherObjects[z] isKindOfClass:[ MDSound class ] ])
				realIndex++;
			if (realIndex == (choose / 8))
				break;
			cam++;
		}
		
		if ([ otherObjects[cam] isKindOfClass:[ MDCamera class ] ])
		{
			MDCamera* camera = otherObjects[cam];
			BOOL look = (choose % 8) >= 4;
			if (choose % 4 != 0 && currentObjectTool == MD_OBJECT_MOVE)
			{
				MDObject* obj2 = !look ? [ camera obj ] : [ camera lookObj ];
				MDRotationBox* box = ViewForIdentity(@"Rotation Box");
				
				oldObject = [ [ NSMutableArray alloc ] init ];
				MDObject* obj = [ [ MDObject alloc ] initWithObject:obj2 ];
				[ oldObject addObject:obj ];
				MouseDown(choose % 4, obj2, [ box xrotation ], [ box yrotation ], [ box zrotation ], translationPoint.z, point, currentObjectTool, currentMode, obj2);
			}
			if (!look)
				[ camera setSelected:YES ];
			else
				[ camera setLookSelected:YES ];
		}
		else if ([ otherObjects[cam] isKindOfClass:[ MDLight class ] ])
		{
			MDLight* light = otherObjects[cam];
			if (choose % 4 != 0 && currentObjectTool == MD_OBJECT_MOVE)
			{
				MDObject* obj2 = [ light obj ];
				MDRotationBox* box = ViewForIdentity(@"Rotation Box");
				
				oldObject = [ [ NSMutableArray alloc ] init ];
				MDObject* obj = [ [ MDObject alloc ] initWithObject:obj2 ];
				[ oldObject addObject:obj ];
				MouseDown(choose % 4, obj2, [ box xrotation ], [ box yrotation ], [ box zrotation ], translationPoint.z, point, currentObjectTool, currentMode, obj2);
			}
			[ light setSelected:YES ];
		}
		else if ([ otherObjects[cam] isKindOfClass:[ MDSound class ] ])
		{
			MDSound* sound = otherObjects[cam];
			if (choose % 4 != 0 && currentObjectTool == MD_OBJECT_MOVE)
			{
				MDObject* obj2 = [ sound obj ];
				MDRotationBox* box = ViewForIdentity(@"Rotation Box");
				
				oldObject = [ [ NSMutableArray alloc ] init ];
				MDObject* obj = [ [ MDObject alloc ] initWithObject:obj2 ];
				[ oldObject addObject:obj ];
				MouseDown(choose % 4, obj2, [ box xrotation ], [ box yrotation ], [ box zrotation ], translationPoint.z, point, currentObjectTool, currentMode, obj2);
			}
			[ sound setSelected:YES ];
		}
		
		commandFlag |= UPDATE_OTHER_INFO;
	}
	else
	{
		for (int z = 0; z < [ otherObjects count ]; z++)
		{
			[ otherObjects[z] setSelected:NO ];
			if ([ otherObjects[z] isKindOfClass:[ MDCamera class ] ])
				[ otherObjects[z] setLookSelected:NO ];
		}
		commandFlag |= UPDATE_OTHER_INFO;
		
		unsigned long object = (number - cameraNames) / 4;
		if (currentMode == MD_OBJECT_MODE && object < [ objects count ] && (number - cameraNames) % 4 == 0)
		{
			if (![ selected containsObject:objects[object] withPoints:nil ])
			{
				if (!(flags & NSCommandKeyMask))
					[ selected clear ];
				[ selected addObject:objects[object] ];
				commandFlag |= UPDATE_INFO;
				commandFlag |= CLEAR_LENGTHS;
			}
			else if (flags & NSCommandKeyMask)
			{
				[ selected removeValue:objects[object] withPoints:nil ];
				commandFlag |= UPDATE_INFO;
				commandFlag |= CLEAR_LENGTHS;
			}
		}
		else if (currentMode == MD_VERTEX_MODE && (number - cameraNames) % 4 == 0)
		{
			unsigned long realObj = object;
			unsigned long realVertex = 0;
			for (unsigned long z = 0; z < [ objects count ]; z++)
			{
				if (realObj >= [ objects[z] numberOfPoints ])
					realObj -= [ objects[z] numberOfPoints ];
				else
				{
					realVertex = realObj;
					realObj = z;
					break;
				}
			}
			if (![ selected containsObject:objects[realObj] withPoints:@[[ objects[realObj] pointAtIndex:realVertex ]] ])
			{
				if (!(flags & NSCommandKeyMask))
					[ selected clear ];
				[ selected addVertex:[ objects[realObj] pointAtIndex:realVertex ] fromObject:objects[realObj] ];
				commandFlag |= UPDATE_INFO;
			}
			else if (flags & NSCommandKeyMask)
			{
				[ selected removeValue:objects[realObj] withPoints:@[[ objects[realObj] pointAtIndex:realVertex ]] ];
				commandFlag |= UPDATE_INFO;
			}
		}
		if ((number - cameraNames) % 4 != 0)
		{
			MDRotationBox* box = ViewForIdentity(@"Rotation Box");
			
			oldObject = [ [ NSMutableArray alloc ] init ];
			for (int z = 0; z < [ selected count ]; z++)
			{
				MDObject* obj = [ [ MDObject alloc ] initWithObject:[ selected selectedValueAtIndex:z ][@"Object"] ];
				MouseDown((number - cameraNames) % 4, [ selected fullValueAtIndex:z ], [ box xrotation ], [ box yrotation ], [ box zrotation ], translationPoint.z, point, currentObjectTool, currentMode, [ selected selectedValueAtIndex:z ][@"Object"]);
				[ oldObject addObject:obj ];
				if (currentMode == MD_VERTEX_MODE)
				{
					MDInstance* instance = [ [ MDInstance alloc ] initWithInstance:[ obj instance ] ];
					[ obj setInstance:instance ];
					[ oldObject addObject:instance ];
				}
			}
		}
	}
	
	return (number != 0);
	
	// TODO: Delete this part (it's not used)
	unsigned int hits = 0;
	unsigned int buffer[512];
	
	if (hits != 0)
	{
		int choose = buffer[3];	// name
		int depth = buffer[1]; // minimum z;
		for (int z = 1; z < hits; z++)
		{
			// If anything is closer, take that
			if (buffer[(z * 4) + 1] < (unsigned int)depth)
			{
				choose = buffer[(z * 4) + 3];
				depth = buffer[(z * 4) + 1];
			}
		}
		
		if (choose != -1)
		{
			unsigned int cameraNames = 0;
			if (currentCamera == -1)
			{
				for (int z = 0; z < [ otherObjects count ]; z++)
				{
					if (![ otherObjects[z] isKindOfClass:[ MDParticleEngine class ] ] && ![ otherObjects[z] isKindOfClass:[ MDCurve class ] ])
					{
						cameraNames += 8;
						if (!(flags & NSCommandKeyMask))
						{
							[ otherObjects[z] setSelected:NO ];
							if ([ otherObjects[z] isKindOfClass:[ MDCamera class ] ])
								[ otherObjects[z] setLookSelected:NO ];
						}
					}
				}
			}
			
			if (choose >= cameraNames)
			{
				unsigned long object = (choose - cameraNames) / 4;
				if (currentMode == MD_OBJECT_MODE && object < [ objects count ] && choose % 4 == 0)
				{
					if (![ selected containsObject:objects[object] withPoints:nil ])
					{
						if (!(flags & NSCommandKeyMask))
							[ selected clear ];
						[ selected addObject:objects[object] ];
						commandFlag |= UPDATE_INFO;
						commandFlag |= CLEAR_LENGTHS;
					}
					else if (flags & NSCommandKeyMask)
					{
						[ selected removeValue:objects[object] withPoints:nil ];
						commandFlag |= UPDATE_INFO;
						commandFlag |= CLEAR_LENGTHS;
					}
				}
				/*else if (currentMode == MD_FACE_MODE && choose % 4 == 0)
				{
					unsigned long realObj = object;
					unsigned long realFace = 0;
					for (unsigned long z = 0; z < [ objects count ]; z++)
					{
						if (realObj >= [ [ objects objectAtIndex:z ] numberOfFaces ])
							realObj -= [ [ objects objectAtIndex:z ] numberOfFaces ];
						else
						{
							realFace = realObj;
							realObj = z;
							break;
						}
					}
					if (![ selected containsObject:[ objects objectAtIndex:realObj ] withFace:[ [ objects objectAtIndex:realObj ] faceAtIndex:realFace ] withPoints:nil ])
					{
						if (!(flags & NSCommandKeyMask))
							[ selected clear ];
						[ selected addFace:[ [ objects objectAtIndex:realObj ] faceAtIndex:realFace ] fromObject:[ objects objectAtIndex:realObj ] ];
						commandFlag |= UPDATE_INFO;
						commandFlag |= CLEAR_LENGTHS;
					}
					else if (flags & NSCommandKeyMask)
					{
						[ selected removeValue:[ objects objectAtIndex:realObj ] withFace:[ [ objects objectAtIndex:realObj ] faceAtIndex:realFace ] withPoints:nil ];
						commandFlag |= UPDATE_INFO;
						commandFlag |= CLEAR_LENGTHS;
					}
				}*/
				else if (currentMode == MD_VERTEX_MODE && choose % 4 == 0)
				{
					unsigned long realObj = object;
					unsigned long realVertex = 0;
					for (unsigned long z = 0; z < [ objects count ]; z++)
					{
						if (realObj >= [ objects[z] numberOfPoints ])
							realObj -= [ objects[z] numberOfPoints ];
						else
						{
							realVertex = realObj;
							realObj = z;
							break;
						}
					}
					if (![ selected containsObject:objects[realObj] withPoints:@[[ objects[realObj] pointAtIndex:realVertex ]] ])
					{
						if (!(flags & NSCommandKeyMask))
							[ selected clear ];
						[ selected addVertex:[ objects[realObj] pointAtIndex:realVertex ] fromObject:objects[realObj] ];
						commandFlag |= UPDATE_INFO;
					}
					else if (flags & NSCommandKeyMask)
					{
						[ selected removeValue:objects[realObj] withPoints:@[[ objects[realObj] pointAtIndex:realVertex ]] ];
						commandFlag |= UPDATE_INFO;
					}
				}
				if (choose % 4 != 0)
				{
					MDRotationBox* box = ViewForIdentity(@"Rotation Box");
					
					oldObject = [ [ NSMutableArray alloc ] init ];
					for (int z = 0; z < [ selected count ]; z++)
					{
						MDObject* obj = [ [ MDObject alloc ] initWithObject:[ selected selectedValueAtIndex:z ][@"Object"] ];
						MouseDown(choose % 4, [ selected fullValueAtIndex:z ], [ box xrotation ], [ box yrotation ], [ box zrotation ], translationPoint.z, point, currentObjectTool, currentMode, [ selected selectedValueAtIndex:z ][@"Object"]);
						[ oldObject addObject:obj ];
					}
				}
			}
			else if (choose / 8 < [ otherObjects count ])
			{
				if (!(flags & NSCommandKeyMask))
					[ selected clear ];
				else
				{
					for (int z = 0; z < [ otherObjects count ]; z++)
					{
						[ otherObjects[z] setSelected:NO ];
						if ([ otherObjects[z] isKindOfClass:[ MDCamera class ] ])
							[ otherObjects[z] setLookSelected:NO ];
					}
				}
				
				unsigned int cam = (choose / 8);
				if ([ otherObjects[cam] isKindOfClass:[ MDCamera class ] ])
				{
					MDCamera* camera = otherObjects[cam];
					BOOL look = (choose % 8) >= 4;
					if (choose % 4 != 0 && currentObjectTool == MD_OBJECT_MOVE)
					{
						MDObject* obj2 = !look ? [ camera obj ] : [ camera lookObj ];
						MDRotationBox* box = ViewForIdentity(@"Rotation Box");
						
						oldObject = [ [ NSMutableArray alloc ] init ];
						MDObject* obj = [ [ MDObject alloc ] initWithObject:obj2 ];
						[ oldObject addObject:obj ];
						MouseDown(choose % 4, obj2, [ box xrotation ], [ box yrotation ], [ box zrotation ], translationPoint.z, point, currentObjectTool, currentMode, obj2);
					}
					if (!look)
						[ camera setSelected:YES ];
					else
						[ camera setLookSelected:YES ];
				}
				else if ([ otherObjects[cam] isKindOfClass:[ MDLight class ] ])
				{
					MDLight* light = otherObjects[cam];
					if (choose % 4 != 0 && currentObjectTool == MD_OBJECT_MOVE)
					{
						MDObject* obj2 = [ light obj ];
						MDRotationBox* box = ViewForIdentity(@"Rotation Box");
						
						oldObject = [ [ NSMutableArray alloc ] init ];
						MDObject* obj = [ [ MDObject alloc ] initWithObject:obj2 ];
						[ oldObject addObject:obj ];
						MouseDown(choose % 4, obj2, [ box xrotation ], [ box yrotation ], [ box zrotation ], translationPoint.z, point, currentObjectTool, currentMode, obj2);
					}
					[ light setSelected:YES ];
				}
				commandFlag |= UPDATE_OTHER_INFO;
			}
		}
		else
		{
			for (int z = 0; z < [ otherObjects count ]; z++)
			{
				if ([ otherObjects[z] show ])
				{
					[ otherObjects[z] setSelected:NO ];
					if ([ otherObjects[z] isKindOfClass:[ MDCamera class ] ])
						[ otherObjects[z] setLookSelected:NO ];
				}
			}
			[ selected clear ];
			commandFlag |= UPDATE_INFO;
			commandFlag |= UPDATE_OTHER_INFO;
		}
	}
	else
	{
		for (int z = 0; z < [ otherObjects count ]; z++)
		{
			if ([ otherObjects[z] show ])
			{
				[ otherObjects[z] setSelected:NO ];
				if ([ otherObjects[z] isKindOfClass:[ MDCamera class ] ])
					[ otherObjects[z] setLookSelected:NO ];
			}
		}
		[ selected clear ];
		commandFlag |= UPDATE_INFO;
		commandFlag |= UPDATE_OTHER_INFO;
	}
	return hits;
}

- (void) readyUnproject
{
	//return;
	// Clear the screen and depth buffer
	/*glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);*/
	
	if (currentCamera != -1 && ![ otherObjects[currentCamera] isKindOfClass:[ MDCamera class ] ])
	{
		MDCamera* camera = otherObjects[currentCamera];
		if ([ camera use ])
		{
			MDVector3 cameraPoint = [ camera midPoint ];
			MDVector3 cameraLook = [ camera lookPoint ];
			float cameraOrientation = [ camera orientation ];
			modelViewMatrix = MDMatrixIdentity();
			MDMatrixLookAt(&modelViewMatrix, cameraPoint, cameraLook, MDVector3Create(sin(cameraOrientation / 180.0 * M_PI), cos(cameraOrientation / 180.0 * M_PI), 0));
		}
	}
	else
	{
		MDRotationBox* box = ViewForIdentity(@"Rotation Box");
		
		modelViewMatrix = MDMatrixIdentity();
		MDMatrixTranslate(&modelViewMatrix, -translationPoint.x, -translationPoint.y, translationPoint.z);
		MDMatrixTranslate(&modelViewMatrix, lookPoint);
		MDMatrixRotate(&modelViewMatrix, 1, 0, 0, [ box xrotation ]);
		MDMatrixRotate(&modelViewMatrix, 0, 1, 0, [ box yrotation ]);
		MDMatrixRotate(&modelViewMatrix, 0, 0, 1, [ box zrotation ]);
		MDMatrixTranslate(&modelViewMatrix, -1 * lookPoint);
	}
	
	projectionMatrix = MDMatrixIdentity();
	MDMatrixSetPerspective(&projectionMatrix, 45.0, resolution.width / resolution.height, 0.1, 1000.0);
	glViewport(0, 0, resolution.width, resolution.height);
	
	/*glUseProgram(program[1]);
	MDMatrixTranslate(&modelViewMatrix, 0, 0, -20 - translationPoint.z);
	glVertexAttrib4f(1, 1, 1, 1, 0);		// Colors
	glVertexAttrib3f(2, 0, 0, 0);			// Normals
	glVertexAttrib2f(3, 0, 0);				// Texture Coordinates
	glUniformMatrix4fv(programLocations[MD_PROGRAM_MODELVIEWPROJECTION], 1, NO, (projectionMatrix * modelViewMatrix).data);
	glUniform1i(programLocations[MD_PROGRAM_ENABLENORMALS], 0);
	glUniform1i(programLocations[MD_PROGRAM_ENABLETEXTURES], 0);
	glBindVertexArray(projectData[0]);
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	MDMatrixTranslate(&modelViewMatrix, 0, 0, 20 + translationPoint.z);*/
}

- (void) mouseDown:(NSEvent *)theEvent
{
	if (move != MD_NONE)
	{
		[ self finishTranslations ];
		return;
	}
	
	BOOL down = FALSE;
	for (int z = (int)[ views count ] - 1; z >= 0; z--)
	{
		MDControlView* view = views[z];
		if (down)
			[ view mouseNotDown ];
		else
		{
			unsigned long prevViews = [ views count ];
			[ view mouseDown:theEvent ];
			if (prevViews != [ views count ])
				break;
			if ([ view mouseDown ])
			{
				for (int q = 0; q < [ [ view subViews ] count ]; q++)
				{
					if (![ [ view subViews ][q] mouseDown ])
					{
						[ [ view subViews ][q] mouseDown:theEvent ];
					}
				}
				if ([ view parentView ] &&
					![ [ view parentView ] mouseDown ])
					[ [ view parentView ] mouseDown:theEvent ];
				down = TRUE;
			}
		}
	}
	if (down)
		return;

	
	if (commandFlag & SHAPE)
	{
		NSPoint point = [ theEvent locationInWindow ];
		
		[ self readyUnproject ];
		
		int viewport[4];
		glGetIntegerv(GL_VIEWPORT, viewport);
		
		float xPos = point.x;
		float yPos = point.y;
		float zPos = 0;
		glReadPixels(point.x, int(yPos), 1, 1, GL_DEPTH_COMPONENT, GL_FLOAT, &zPos);
		
		shapeDown = MDMatrixUnProject(MDVector3Create(xPos, yPos, zPos), modelViewMatrix, projectionMatrix, viewport);
		shapeDrag = MDVector3Create(shapeDown.x, 0, shapeDown.z);
		
		currentObject = [ [ NSMutableArray alloc ] init ];
		NSString* set = [ NSString stringWithFormat:@"%@set", [ currentShapePath substringToIndex:[ currentShapePath length ] - [ [ currentShapePath pathExtension ] length ] ] ];
		InterpretShape(currentShapePath, set, currentObject, shapeDown, MDVector3Create(0, 0, 0));
		
		return;
	}
	else if (commandFlag & SHAPE2)
	{
		
		mousePoint = [ theEvent locationInWindow ];
		return;
	}
	
	mousePoint = [ theEvent locationInWindow ];
	
	if (currentTool == MD_SELECTION_TOOL)
		[ self pick:[ theEvent locationInWindow ] withFlags:[ theEvent modifierFlags ] ];
	else if (currentTool == MD_MOVE_TOOL)
	{
		[ [ NSCursor closedHandCursor ] set ];
		backupTrans = translationPoint;
	}
}

- (void) mouseUp:(NSEvent *)theEvent
{
	BOOL down = FALSE;
	for (int z = 0; z < [ views count ]; z++)
	{
		if ([ views[z] mouseDown ])
			down = TRUE;
		[ (MDControlView*)views[z] mouseUp:theEvent ];
	}
	if (down)
	{
		MDRotationBox* box = ViewForIdentity(@"Rotation Box");
		if ([ box isShowing ] && ([ theEvent modifierFlags ] & NSAlternateKeyMask) && [ selected count ] == 1)
		{
			move = MD_SCENE_WHOLE;
			backupTrans = translationPoint;
			backupLook = lookPoint;
			MDObject* obj = [ selected selectedValueAtIndex:0 ][@"Object"];
			MDRect rect = BoundingBoxRotate(obj);
			MDVector3 sizes = MDVector3Create(rect.width, rect.height, rect.depth);
			sizes = Rotate(sizes, MDVector3Create(0, 0, 0), [ box setX ], [ box setY ], [ box setZ ]);
			float XtoY = windowSize.width / windowSize.height;
			float bigger = fabs(sizes.x);
			if (bigger < fabs(sizes.y) * XtoY)
				bigger = fabs(sizes.y) * XtoY;
			float realZ = -rect.z - (rect.depth / 2);
			realZ -= fabs(sizes.z / 2);
			targetTrans = MDVector3Create(rect.x + (rect.width / 2), rect.y + (rect.height / 2), realZ - bigger);
			targetLook = [ obj realMidPoint ];
		}
		else if ([ box isShowing ] && ([ theEvent modifierFlags ] & NSAlternateKeyMask) && [ selected count ] == 0)
		{
			// Check for other object
			BOOL sel = FALSE;
			for (unsigned long z = 0; z < [ otherObjects count ]; z++)
			{
				id other = otherObjects[z];
				if ([ other isKindOfClass:[ MDLight class ] ])
				{
					if ([ other selected ])
					{
						move = MD_SCENE_WHOLE;
						backupTrans = translationPoint;
						backupLook = lookPoint;
						MDObject* obj = [ other obj ];
						MDRect rect = BoundingBoxRotate(obj);
						MDVector3 sizes = MDVector3Create(rect.width, rect.height, rect.depth);
						sizes = Rotate(sizes, MDVector3Create(0, 0, 0), [ box setX ], [ box setY ], [ box setZ ]);
						float XtoY = windowSize.width / windowSize.height;
						float bigger = fabs(sizes.x);
						if (bigger < fabs(sizes.y) * XtoY)
							bigger = fabs(sizes.y) * XtoY;
						float realZ = -rect.z - (rect.depth / 2);
						realZ -= fabs(sizes.z / 2);
						targetTrans = MDVector3Create(rect.x + (rect.width / 2), rect.y + (rect.height / 2), realZ - bigger);
						targetLook = [ obj realMidPoint ];
						
						sel = TRUE;
						break;
					}
				}
				else if ([ other isKindOfClass:[ MDCamera class ] ])
				{
					if ([ other selected ])
					{
						move = MD_SCENE_WHOLE;
						backupTrans = translationPoint;
						backupLook = lookPoint;
						MDObject* obj = [ other obj ];
						MDRect rect = BoundingBoxRotate(obj);
						MDVector3 sizes = MDVector3Create(rect.width, rect.height, rect.depth);
						sizes = Rotate(sizes, MDVector3Create(0, 0, 0), [ box setX ], [ box setY ], [ box setZ ]);
						float XtoY = windowSize.width / windowSize.height;
						float bigger = fabs(sizes.x);
						if (bigger < fabs(sizes.y) * XtoY)
							bigger = fabs(sizes.y) * XtoY;
						float realZ = -rect.z - (rect.depth / 2);
						realZ -= fabs(sizes.z / 2);
						targetTrans = MDVector3Create(rect.x + (rect.width / 2), rect.y + (rect.height / 2), realZ - bigger);
						targetLook = [ obj realMidPoint ];
						sel = TRUE;
						break;
					}
					else if ([ other lookSelected ])
					{
						move = MD_SCENE_WHOLE;
						backupTrans = translationPoint;
						backupLook = lookPoint;
						MDObject* obj = [ other lookObj ];
						MDRect rect = BoundingBoxRotate(obj);
						MDVector3 sizes = MDVector3Create(rect.width, rect.height, rect.depth);
						sizes = Rotate(sizes, MDVector3Create(0, 0, 0), [ box setX ], [ box setY ], [ box setZ ]);
						float XtoY = windowSize.width / windowSize.height;
						float bigger = fabs(sizes.x);
						if (bigger < fabs(sizes.y) * XtoY)
							bigger = fabs(sizes.y) * XtoY;
						float realZ = -rect.z - (rect.depth / 2);
						realZ -= fabs(sizes.z / 2);
						targetTrans = MDVector3Create(rect.x + (rect.width / 2), rect.y + (rect.height / 2), realZ - bigger);
						targetLook = [ obj realMidPoint ];
						sel = TRUE;
						break;
					}
				}
			}
			if (!sel)
			{
				move = MD_SCENE_WHOLE;
				backupTrans = translationPoint;
				targetTrans = MDVector3Create(0, 5, -20);
				backupLook = lookPoint;
				targetLook = MDVector3Create(0, 5, 0);
			}
		}
		return;
	}
	
	if (commandFlag & SHAPE)
	{
		if (fabs(shapeDrag.x - shapeDown.x) < 0.1)
		{
			shapeDrag.x = 1 + shapeDown.x;
			NSString* set = [ NSString stringWithFormat:@"%@set", [ currentShapePath substringToIndex:[ currentShapePath length ] - [ [ currentShapePath pathExtension ] length ] ] ];
			InterpretShape(currentShapePath, set, currentObject, shapeDown, MDVector3Create(shapeDrag.x - shapeDown.x, 0, shapeDrag.z - shapeDown.z));
		}
		if (fabs(shapeDrag.z - shapeDown.z) < 0.1)
		{
			shapeDrag.z = shapeDown.z + 1;
			NSString* set = [ NSString stringWithFormat:@"%@set", [ currentShapePath substringToIndex:[ currentShapePath length ] - [ [ currentShapePath pathExtension ] length ] ] ];
			InterpretShape(currentShapePath, set, currentObject, shapeDown, MDVector3Create(shapeDrag.x - shapeDown.x, 0, shapeDrag.z - shapeDown.z));
		}
		commandFlag &= ~(SHAPE);
		
		if (RequiresTwoMouseClicks())
			commandFlag |= SHAPE2;
		else
		{			
			MDInstance* instance = [ [ MDInstance alloc ] init ];
			// Set the correct name
			for (unsigned long q = 0; true; q++)
			{
				[ instance setName:[ NSString stringWithFormat:@"New Object %lu", q ] ];
				BOOL end = TRUE;
				for (unsigned long z = 0; z < [ instances count ]; z++)
				{
					if ([ [ instances[z] name ] isEqualToString:[ instance name ] ])
					{
						end = FALSE;
						break;
					}
				}
				if (end)
					break;
			}
			
			for (unsigned long z = 0; z < [ currentObject count ]; z++)
			{
				MDFace* face = currentObject[z];
				[ instance beginMesh ];
				for (unsigned long q = 0; q < [ [ face points ] count ]; q++)
				{
					MDPoint* p = [ [ MDPoint alloc ] initWithPoint:[ face points ][q] ];
					[ instance addPoint:p ];
				}
				for (unsigned long q = 0; q < [ [ face indices ] count ]; q++)
					[ instance addIndex:[ [ face indices ][q] unsignedIntValue ] ];
				[ instance setColor:MDVector4Create(0.3, 0.3, 0.3, 1.0) ];
				[ instance endMesh ];
			}
						
			MDVector3 trans = [ instance midPoint ];
			[ instance setMidPoint:MDVector3Create(0, 0, 0) ];
			
			BOOL reverseX = shapeDrag.x < shapeDown.x;
			BOOL reverseZ = shapeDrag.z < shapeDown.z;
			for (unsigned long q = 0; q < [ instance numberOfPoints ]; q++)
			{
				MDPoint* p = [ instance pointAtIndex:q ];
				if (reverseX)
					p.normalX *= -1;
				if (reverseZ)
					p.normalZ *= -1;
			}

			[ instances addObject:instance ];
			commandFlag |= UPDATE_LIBRARY;
			
			MDObject* obj = [ [ MDObject alloc ] initWithInstance:instance ];
			obj.translateX = trans.x;
			obj.translateY = trans.y;
			obj.translateZ = trans.z;
			obj.objectColors[0].x = 0.7;
			obj.objectColors[1].z = 0.7;
			obj.objectColors[2].x = 0.7;
			obj.objectColors[2].y = 0.7;
			obj.objectColors[0].w = obj.objectColors[1].w = obj.objectColors[2].w = 1;
			currentObject = nil;
			NSMutableArray* array = [ NSMutableArray array ];
			MDSelection* newSel = [ [ MDSelection alloc ] initWithSelection:selected ];
			for (int z = 0; z < [ objects count ]; z++)
			{
				MDObject* obj2 = [ [ MDObject alloc ] initWithObject:objects[z] ];
				[ array addObject:obj2 ];
				if ([ newSel containsObject:objects[z] withPoints:nil ])
					[ newSel replaceObjectAtIndex:[ newSel indexOfObject:objects[z] withPoints:nil ] withObject:obj2 ];
			}
			[ array addObject:obj ];
			[ undoManager setActionName:@"Create" ];
			[ Controller setObjects:array selected:newSel andInstances:instances ];
		}
		return;
	}
	else if (commandFlag & SHAPE2)
	{
		if (!currentObject)
		{
			commandFlag &= ~(SHAPE2);
			return;
		}
		
		if (fabs(shapeDrag.y) < 0.1)
		{
			shapeDrag.y = 1;
			NSString* set = [ NSString stringWithFormat:@"%@set", [ currentShapePath substringToIndex:[ currentShapePath length ] - [ [ currentShapePath pathExtension ] length ] ] ];
			InterpretShape(currentShapePath, set, currentObject, shapeDown, MDVector3Create(shapeDrag.x - shapeDown.x, shapeDrag.y, shapeDrag.z - shapeDown.z));
		}
		
		MDInstance* instance = [ [ MDInstance alloc ] init ];
		// Set the correct name
		for (unsigned long q = 0; true; q++)
		{
			[ instance setName:[ NSString stringWithFormat:@"New Object %lu", q ] ];
			BOOL end = TRUE;
			for (unsigned long z = 0; z < [ instances count ]; z++)
			{
				if ([ [ instances[z] name ] isEqualToString:[ instance name ] ])
				{
					end = FALSE;
					break;
				}
			}
			if (end)
				break;
		}

		for (unsigned long z = 0; z < [ currentObject count ]; z++)
		{
			MDFace* face = currentObject[z];
			[ instance beginMesh ];
			for (unsigned long q = 0; q < [ [ face points ] count ]; q++)
			{
				MDPoint* p = [ [ MDPoint alloc ] initWithPoint:[ face points ][q] ];
				[ instance addPoint:p ];
			}
			for (unsigned long q = 0; q < [ [ face indices ] count ]; q++)
				[ instance addIndex:[ [ face indices ][q] unsignedIntValue ] ];
			[ instance setColor:MDVector4Create(0.3, 0.3, 0.3, 1.0) ];
			[ instance endMesh ];
		}
		
		MDVector3 trans = [ instance midPoint ];
		[ instance setMidPoint:MDVector3Create(0, 0, 0) ];
		
		BOOL reverseX = shapeDrag.x < shapeDown.x;
		BOOL reverseY = shapeDrag.y < 0;
		BOOL reverseZ = shapeDrag.z < shapeDown.z;
		for (unsigned long q = 0; q < [ instance numberOfPoints ]; q++)
		{
			MDPoint* p = [ instance pointAtIndex:q ];
			if (reverseX)
				p.normalX *= -1;
			if (reverseY)
				p.normalY *= -1;
			if (reverseZ)
				p.normalZ *= -1;
		}
		
		[ instances addObject:instance ];
		commandFlag |= UPDATE_LIBRARY;
		
		MDObject* obj = [ [ MDObject alloc ] initWithInstance:instance ];
		obj.translateX = trans.x;
		obj.translateY = trans.y;
		obj.translateZ = trans.z;
		obj.objectColors[0].x = 0.7;
		obj.objectColors[1].z = 0.7;
		obj.objectColors[2].x = 0.7;
		obj.objectColors[2].y = 0.7;
		obj.objectColors[0].w = obj.objectColors[1].w = obj.objectColors[2].w = 1;
		currentObject = nil;
		NSMutableArray* array = [ NSMutableArray array ];
		MDSelection* newSel = [ [ MDSelection alloc ] initWithSelection:selected ];
		for (int z = 0; z < [ objects count ]; z++)
		{
			MDObject* obj2 = [ [ MDObject alloc ] initWithObject:objects[z] ];
			[ array addObject:obj2 ];
			if ([ newSel containsObject:objects[z] withPoints:nil ])
				[ newSel replaceObjectAtIndex:[ newSel indexOfObject:objects[z] withPoints:nil ] withObject:obj2 ];
		}
		[ array addObject:obj ];
		[ undoManager setActionName:@"Create" ];
		[ Controller setObjects:array selected:newSel andInstances:instances ];
		
		commandFlag &= ~(SHAPE2);
		return;
	}
	
	if (currentTool == MD_MOVE_TOOL)
	{
		[ [ NSCursor openHandCursor ] set ];
		MDVector3 point = translationPoint;
		translationPoint = backupTrans;
		[ undoManager setActionName:@"Scene Translation" ];
		[ Controller setTranslationPoint:point ];
	}
	NSPoint point = [ theEvent locationInWindow ];
	NSSize bounds = [ self bounds ].size;
	if (!(point.x >= 0 && point.x <= bounds.width && point.y >= 0 && point.y <= bounds.height))
		[ [ NSCursor arrowCursor ] set ];
	
	if ([ selected count ] != 0 && oldObject)
	{
		[ undoManager setActionName:@"Translation" ];
		if (currentMode == MD_OBJECT_MODE)
		{
			unsigned long numberOfObjects = [ selected count ];
			MDObject* obj[numberOfObjects];
			unsigned long objIndex[numberOfObjects];
			unsigned long faceIndex[numberOfObjects];
			unsigned long pointIndex[numberOfObjects];
			for (int z = 0; z < numberOfObjects; z++)
			{
				MouseUp([ selected selectedValueAtIndex:z ][@"Object"]);
				obj[z] = [ [ MDObject alloc ] initWithObject:[ selected selectedValueAtIndex:z ][@"Object"] ];
				objIndex[z] = [ objects indexOfObject:[ selected selectedValueAtIndex:z ][@"Object"] ];
				faceIndex[z] = NSNotFound;
				//faceIndex[z] = [ [ [ [ selected selectedValueAtIndex:z ] objectForKey:@"Object" ] faces ] indexOfObject:[ [ selected selectedValueAtIndex:z ] objectForKey:@"Face" ] ];
				pointIndex[z] = NSNotFound;
				if (objIndex[z] != NSNotFound)
				{
					pointIndex[z] = [ [ [ selected selectedValueAtIndex:z ][@"Object"] points ] indexOfObject:[ selected selectedValueAtIndex:z ][@"Point"] ];
				}
			}
			for (int z = 0; z < numberOfObjects; z++)
			{
				objects[objIndex[z]] = oldObject[z];
				[ Controller setMDObject:obj[z] atIndex:objIndex[z] faceIndex:faceIndex[z] edgeIndex:NSNotFound pointIndex:pointIndex[z] selectionIndex:z ];
			}
		}
		else if (currentMode == MD_VERTEX_MODE)
		{
			unsigned long numberOfObjects = [ selected count ];
			MDInstance* inst[numberOfObjects];
			unsigned long instIndex[numberOfObjects];
			for (int z = 0; z < numberOfObjects; z++)
			{
				MDObject* obj = [ selected selectedValueAtIndex:z ][@"Object"];
				MouseUp(obj);
				instIndex[z] = [ instances indexOfObject:[ obj instance ] ];
				inst[z] = [ [ MDInstance alloc ] initWithInstance:[ obj instance ] ];
			}
			for (int z = 0; z < numberOfObjects; z++)
			{
				MDInstance* instance = instances[instIndex[z]];
				for (unsigned long q = 0; q < [ instance numberOfPoints ]; q++)
					[ instance setPoint:[ oldObject[(z * 2) + 1] points ][q] atIndex:q ];
				
				[ Controller setMDInstance:inst[z] atIndex:instIndex[z] ];
			}
		}
	}
	else if (oldObject)
	{
		for (unsigned long z = 0; z < [ otherObjects count ]; z++)
		{
			if ([ otherObjects[z] isKindOfClass:[ MDCamera class ] ])
			{
				MDCamera* camera = otherObjects[z];
				if ([ camera show ] && ([ camera selected ] || [ camera lookSelected ]))
				{
					MDObject* obj2 = [ camera selected ] ? [ camera obj ] : [ camera lookObj ];
					MouseUp(obj2);
					MDCamera* camera2 = [ [ MDCamera alloc ] initWithMDCamera:camera ];
					if ([ camera selected ])
					{
						[ camera setMidPoint:[ oldObject[0] realMidPoint ] ];
						[ camera setObj:[ [ MDObject alloc ] initWithObject:oldObject[0] ] ];
					}
					else
					{
						[ camera setOnlyLookPoint:[ oldObject[0] realMidPoint ] ];
						[ camera setLookObj:[ [ MDObject alloc ] initWithObject:oldObject[0] ] ];
					}
					[ undoManager setActionName:@"Transformation" ];
					[ Controller setOtherObject:camera2 atIndex:z ];
					oldObject = nil;
					break;
				}
			}
			else if ([ otherObjects[z] isKindOfClass:[ MDLight class ] ])
			{
				MDLight* light = otherObjects[z];
				if ([ light show ] && [ light selected ])
				{
					MDObject* obj2 = light.obj;
					MouseUp(obj2);
					MDLight* light2 = [ [ MDLight alloc ] initWithMDLight:light ];
					[ light setPosition:[ oldObject[0] realMidPoint ] ];
					[ light setObj:[ [ MDObject alloc ] initWithObject:oldObject[0] ] ];
					[ undoManager setActionName:@"Transformation" ];
					[ Controller setOtherObject:light2 atIndex:z ];
					oldObject = nil;
					break;
				}
			}
			else if ([ otherObjects[z] isKindOfClass:[ MDSound class ] ])
			{
				MDSound* sound = otherObjects[z];
				if ([ sound show ] && [ sound selected ])
				{
					MDObject* obj2 = sound.obj;
					MouseUp(obj2);
					MDSound* sound2 = [ [ MDSound alloc ] initWithMDSound:sound ];
					[ sound setPosition:[ oldObject[0] realMidPoint ] ];
					[ sound setObj:[ [ MDObject alloc ] initWithObject:oldObject[0] ] ];
					[ undoManager setActionName:@"Transformation" ];
					[ Controller setOtherObject:sound2 atIndex:z ];
					break;
				}
			}
		}
	}
}

- (void) mouseDragged:(NSEvent *)theEvent
{
	BOOL down = FALSE;
	for (int z = 0; z < [ views count ]; z++)
	{
		MDControlView* view = views[z];
		[ view mouseDragged:theEvent ];
		if ([ view mouseDown ])
		{
			down = TRUE;
			if ([ [ view identity ] isEqualToString:@"Rotation Box" ])
				commandFlag |= UPDATE_SCENE_INFO;
			break;
		}
	}
	if (down)
		return;
	
	if (commandFlag & SHAPE)
	{
		NSPoint point = [ theEvent locationInWindow ];

		[ self readyUnproject ];
		
		int viewport[4];
		glGetIntegerv(GL_VIEWPORT, viewport);
		
		float xPos = point.x;
		float yPos = point.y;
		float zPos = 0;
		glReadPixels(point.x, int(yPos), 1, 1, GL_DEPTH_COMPONENT, GL_FLOAT, &zPos);
		
		shapeDrag = MDMatrixUnProject(MDVector3Create(xPos, yPos, zPos), modelViewMatrix, projectionMatrix, viewport);
		shapeDrag.y = 0;
		
		if ([ theEvent modifierFlags ] & NSShiftKeyMask)
		{
			float timesX = (shapeDrag.x - shapeDown.x) > 0 ? 1 : -1;
			float timesZ = (shapeDrag.z - shapeDown.z) > 0 ? 1 : -1;
			if (fabs(shapeDrag.x - shapeDown.x) > fabs(shapeDrag.z - shapeDown.z))
				shapeDrag.z = (shapeDrag.x - shapeDown.x) * timesZ + shapeDown.z;
			else
				shapeDrag.x = (shapeDrag.z - shapeDown.z) * timesX + shapeDown.x;
		}
		
		// Makes distance always positive
		MDVector3 fakeDown = shapeDown;
		MDVector3 fakeDrag = shapeDrag;
		if (fakeDrag.x - fakeDown.x < 0)
		{
			fakeDrag.x = shapeDown.x;
			fakeDown.x = shapeDrag.x;
		}
		if (fakeDrag.z - fakeDown.z < 0)
		{
			fakeDrag.z = shapeDown.z;
			fakeDown.z = shapeDrag.z;
		}
		
		NSString* set = [ NSString stringWithFormat:@"%@set", [ currentShapePath substringToIndex:[ currentShapePath length ] - [ [ currentShapePath pathExtension ] length ] ] ];
		InterpretShape(currentShapePath, set, currentObject, fakeDown, fakeDrag - fakeDown);
		
		return;
	}
	else if (commandFlag & SHAPE2)
	{
		NSPoint point = [ theEvent locationInWindow ];
		
		float closeZ = shapeDrag.z;
		if (closeZ < shapeDown.z)
			closeZ = shapeDown.z;
		float yS = TH(point.y - mousePoint.y, -closeZ - translationPoint.z);
		shapeDrag = MDVector3Create(shapeDrag.x, yS, shapeDrag.z);
		if ([ theEvent modifierFlags ] & NSShiftKeyMask)
		{
			float times = (shapeDrag.y > 0) ? 1 : -1;
			if (fabs(shapeDrag.x - shapeDown.x) >= fabs(shapeDrag.z - shapeDown.z))
				shapeDrag.y = (shapeDrag.x - shapeDown.x) * times;
			else
				shapeDrag.y = (shapeDrag.z - shapeDown.z) * times;
		}
		
		// Makes distance always positive
		MDVector3 fakeDown = shapeDown;
		MDVector3 fakeDrag = shapeDrag;
		if (fakeDrag.x - fakeDown.x < 0)
		{
			fakeDrag.x = shapeDown.x;
			fakeDown.x = shapeDrag.x;
		}
		if (fakeDrag.y - fakeDown.y < 0)
		{
			fakeDrag.y = shapeDown.y;
			fakeDown.y = shapeDrag.y;
		}
		if (fakeDrag.z - fakeDown.z < 0)
		{
			fakeDrag.z = shapeDown.z;
			fakeDown.z = shapeDrag.z;
		}
		
		NSString* set = [ NSString stringWithFormat:@"%@set", [ currentShapePath substringToIndex:[ currentShapePath length ] - [ [ currentShapePath pathExtension ] length ] ] ];
		InterpretShape(currentShapePath, set, currentObject, fakeDown, fakeDrag - fakeDown);
		return;
	}
	
	if (currentTool == MD_SELECTION_TOOL)
	{
		NSPoint point = [ theEvent locationInWindow ];
		for (int z = 0; z < [ objects count ]; z++)
		{
			MDObject* obj = objects[z];
			unsigned int which = 0;
			for (int z = 0; z < 3; z++)
			{
				MDVector4 color = [ obj objectColors ][z];
				if (color.x == 1 || color.y == 1 || color.z == 1)
				{
					which = z + 1;
					break;
				}
			}
			if (which != 0)
			{
				MDRotationBox* box = ViewForIdentity(@"Rotation Box");
				for (int q = 0; q < [ selected count ]; q++)
				{
					float xrot = [ box xrotation ];
					float yrot = [ box yrotation ];
					float newZ = translationPoint.z;
					if (currentCamera != -1)
					{
						MDVector3 cameraMid = [ otherObjects[currentCamera] midPoint ];
						MDVector3 cameraLook = [ otherObjects[currentCamera] lookPoint ];
						yrot = -atan2f(cameraLook.x - cameraMid.x, cameraLook.z - cameraMid.z) * 180 / M_PI + 180;
						MDVector3 newPoint = MDVector3Create(cameraLook.x - cameraMid.x, cameraLook.y - cameraMid.y, cameraLook.z - cameraMid.z);
						xrot = 0;
						newZ = -sqrt(pow(newPoint.x, 2) + pow(newPoint.y, 2) + pow(newPoint.z, 2));
					}
					MouseDragged(-(point.x - mousePoint.x), -(point.y - mousePoint.y), which, currentObjectTool, [ selected fullValueAtIndex:q ], newZ, xrot, yrot, point, currentMode);
				}
				commandFlag |= UPDATE_INFO;
				break;
			}
		}
		if (currentObjectTool == MD_OBJECT_MOVE)
		{
			for (int z = 0; z < [ otherObjects count ]; z++)
			{
				if ([ otherObjects[z] isKindOfClass:[ MDCamera class ] ])
				{
					MDCamera* camera = otherObjects[z];
					if ([ camera show ] && ([ camera selected ] || [ camera lookSelected ]))
					{
						MDObject* obj = [ camera selected ] ? [ camera obj ] : [ camera lookObj ];
						unsigned int which = 0;
						for (int z = 0; z < 3; z++)
						{
							MDVector4 color = [ obj objectColors ][z];
							if (color.x == 1 || color.y == 1 || color.z == 1)
							{
								which = z + 1;
								break;
							}
						}
						if (which != 0)
						{
							MDRotationBox* box = ViewForIdentity(@"Rotation Box");
							MouseDragged(-(point.x - mousePoint.x), -(point.y - mousePoint.y), which, currentObjectTool, obj, translationPoint.z, [ box xrotation ], [ box yrotation ], point, currentMode);
							if ([ camera selected ])
								[ camera setMidPoint:[ [ camera obj ] realMidPoint ] ];
							else
								[ camera setOnlyLookPoint:[ [ camera lookObj ] realMidPoint ] ];
							commandFlag |= UPDATE_OTHER_INFO;
							break;
						}
					}
				}
				else if ([ otherObjects[z] isKindOfClass:[ MDLight class ] ] || [ otherObjects[z] isKindOfClass:[ MDSound class ] ])
				{
					id light = otherObjects[z];
					if ([ light show ] && [ light selected ])
					{
						MDObject* obj = [ light obj ];
						unsigned int which = 0;
						for (int z = 0; z < 3; z++)
						{
							MDVector4 color = [ obj objectColors ][z];
							if (color.x == 1 || color.y == 1 || color.z == 1)
							{
								which = z + 1;
								break;
							}
						}
						if (which != 0)
						{
							MDRotationBox* box = ViewForIdentity(@"Rotation Box");
							MouseDragged(-(point.x - mousePoint.x), -(point.y - mousePoint.y), which, currentObjectTool, obj, translationPoint.z, [ box xrotation ], [ box yrotation ], point, currentMode);
							if ([ light isKindOfClass:[ MDLight class ] ])
								[ (MDLight*)light setPosition:[ [ light obj ] realMidPoint ] ];
							else
								[ (MDSound*)light setPosition:[ [ light obj ] realMidPoint ] ];
							commandFlag |= UPDATE_OTHER_INFO;
							break;
						}
					}
				}
			}
		}
	}
	else if (currentTool == MD_MOVE_TOOL)
	{
		NSPoint point = [ theEvent locationInWindow ];
		if (currentCamera == -1 || (currentCamera != -1 && ![ otherObjects[currentCamera] isKindOfClass:[ MDCamera class ] ]))
		{
			translationPoint.x -= TW(point.x - mousePoint.x, -translationPoint.z);
			translationPoint.y -= TH(point.y - mousePoint.y, -translationPoint.z);
			commandFlag |= UPDATE_SCENE_INFO;
		}
		else
		{
			MDCamera* camera = otherObjects[currentCamera];
			MDVector3 cameraMid = [ otherObjects[currentCamera] midPoint ];
			MDVector3 cameraLook = [ otherObjects[currentCamera] lookPoint ];
			MDVector3 newPoint = MDVector3Create(cameraLook.x - cameraMid.x, cameraLook.y - cameraMid.y, cameraLook.z - cameraMid.z);
			float newZ = sqrt(pow(newPoint.x, 2) + pow(newPoint.y, 2) + pow(newPoint.z, 2));
			float yrot = -atan2f(cameraLook.x - cameraMid.x, cameraLook.z - cameraMid.z) * 180 / M_PI + 180;
			float changeX = TW(point.x - mousePoint.x, newZ);
			float changeY = TH(point.y - mousePoint.y, newZ);
			MDVector3 addPoint = Rotate(MDVector3Create(changeX, -changeY, 0), MDVector3Create(0, 0, 0), 0, yrot, 0);
			cameraMid.x += addPoint.x;
			cameraMid.y += addPoint.y;
			cameraMid.z += addPoint.z;
			[ camera setMidPoint:cameraMid ];
			commandFlag |= UPDATE_OTHER_INFO;
		}
	}
	else if (currentTool == MD_ZOOM_TOOL)
	{
		NSPoint point = [ theEvent locationInWindow ];
		if(currentCamera == -1 || (currentCamera != -1 && [ otherObjects[currentCamera] isKindOfClass:[ MDCamera class ] ]))
		{
			translationPoint.z += (point.y - mousePoint.y) / 10.0;
			commandFlag |= UPDATE_SCENE_INFO;
		}
		else
		{
			MDCamera* camera = otherObjects[currentCamera];
			MDVector3 cameraMid = [ otherObjects[currentCamera] midPoint ];
			MDVector3 cameraLook = [ otherObjects[currentCamera] lookPoint ];
			MDVector3 newPoint = MDVector3Create(cameraLook.x - cameraMid.x, cameraLook.y - cameraMid.y, cameraLook.z - cameraMid.z);
			float newZ = sqrt(pow(newPoint.x, 2) + pow(newPoint.y, 2) + pow(newPoint.z, 2));
			float yrot = -atan2f(cameraLook.x - cameraMid.x, cameraLook.z - cameraMid.z) * 180 / M_PI + 180;
			float changeZ = TW(point.y - mousePoint.y, newZ);
			MDVector3 addPoint = Rotate(MDVector3Create(0, 0, -changeZ), MDVector3Create(0, 0, 0), 0, yrot, 0);
			cameraMid.x += addPoint.x;
			cameraMid.y += addPoint.y;
			cameraMid.z += addPoint.z;
			[ camera setMidPoint:cameraMid ];
			commandFlag |= UPDATE_OTHER_INFO;
		}
	}
	else if (currentTool == MD_ROTATE_TOOL)
	{
		NSPoint point = [ theEvent locationInWindow ];
		if (currentCamera == -1 || (currentCamera != -1 && [ otherObjects[currentCamera] isKindOfClass:[ MDCamera class ] ]))
		{
			NSSize bounds = [ self bounds ].size;
			float yRot = (point.x - mousePoint.x) / bounds.width * 360;
			float xRot = -(point.y - mousePoint.y) / bounds.height * 360;
			MDRotationBox* box = ViewForIdentity(@"Rotation Box");
			[ box setXRotation:[ box xrotation ] + xRot show:NO ];
			[ box setYRotation:[ box yrotation ] + yRot show:NO ];
		}
		else
		{
			MDCamera* camera = otherObjects[currentCamera];
			MDVector3 cameraMid = [ otherObjects[currentCamera] midPoint ];
			MDVector3 cameraLook = [ otherObjects[currentCamera] lookPoint ];
			MDVector3 newPoint = MDVector3Create(cameraLook.x - cameraMid.x, cameraLook.y - cameraMid.y, cameraLook.z - cameraMid.z);
			float newZ = sqrt(pow(newPoint.x, 2) + pow(newPoint.y, 2) + pow(newPoint.z, 2));
			float yrot = -atan2f(cameraLook.x - cameraMid.x, cameraLook.z - cameraMid.z) * 180 / M_PI + 180;
			float changeX = TW(point.x - mousePoint.x, newZ);
			float changeY = TH(point.y - mousePoint.y, newZ);
			MDVector3 addPoint = Rotate(MDVector3Create(changeX, -changeY, 0), MDVector3Create(0, 0, 0), 0, yrot, 0);
			cameraLook.x += addPoint.x;
			cameraLook.y += addPoint.y;
			cameraLook.z += addPoint.z;
			[ camera setLookPoint:cameraLook ];
			commandFlag |= UPDATE_OTHER_INFO;
		}
	}
	
	mousePoint = [ theEvent locationInWindow ];
}

- (void) mouseEntered:(NSEvent *)theEvent
{
	// Current Tools
	if (currentTool == MD_SELECTION_TOOL)
		[ [ NSCursor arrowCursor ] set ];
	else if (currentTool == MD_MOVE_TOOL)
		[ [ NSCursor openHandCursor ] set ];
	else if (currentTool == MD_ZOOM_TOOL)
		[ [ NSCursor resizeUpDownCursor ] set ];
	else if (currentTool == MD_ROTATE_TOOL)
		[ [ NSCursor crosshairCursor ] set ];
}

- (void) mouseExited:(NSEvent *)theEvent
{
	[ [ NSCursor arrowCursor ] set ];
}

- (void) mouseMoved:(NSEvent *)theEvent
{
	for (int z = 0; z < [ views count ]; z++)
		[ views[z] mouseMoved:theEvent ];
}

- (void) scrollWheel:(NSEvent *)theEvent
{
	for (int z = (int)[ views count ] - 1; z >= 0; z--)
	{
		MDControlView* view = views[z];
		[ view scrollWheel:theEvent ];
		if ([ view scrolled ])
			return;
	}
	
	translationPoint.z += [ theEvent deltaY ] / 20;
	commandFlag |= UPDATE_SCENE_INFO;
}

- (void) keyDown:(NSEvent *)theEvent
{
	for (int z = 0; z < [ views count ]; z++)
	{
		[ views[z] keyDown:theEvent ];
		if ([ views[z] keyDown ])
			return;
	}
	
	unsigned short key = [ [ theEvent characters ] characterAtIndex:0 ];
	switch (key) {
		case NSBackspaceCharacter:
		case NSDeleteCharacter:
		{
			if ([ selected count ] == 0)
				return;
			NSMutableArray* array = [ NSMutableArray array ];
			for (int z = 0; z < [ objects count ]; z++)
			{
				MDObject* obj = [ [ MDObject alloc ] initWithObject:objects[z] ];
				[ array addObject:obj ];
			}
			for (int z = 0; z < [ selected count ]; z++)
			{
				unsigned long index = [ objects indexOfObject:[ selected selectedValueAtIndex:z ][@"Object"] ];
				if (currentMode == MD_OBJECT_MODE)
					[ array removeObjectAtIndex:index ];
				else if (currentMode == MD_FACE_MODE)
				{
					/*unsigned long faceIndex = [ [ [ objects objectAtIndex:index ] faces ] indexOfObject:[ [ selected selectedValueAtIndex:z ] objectForKey:@"Face" ] ];

					[ [ [ array objectAtIndex:index ] faces ] removeObjectAtIndex:faceIndex ];*/
				}
			}
			[ undoManager setActionName:@"Delete" ];
			MDSelection* newSel = [ [ MDSelection alloc ] init ];
			[ Controller setObjects:array selected:newSel andInstances:instances ];
			
			commandFlag |= UPDATE_INFO;
			break;
		}
	}
}

- (void) keyUp:(NSEvent *)theEvent
{
	for (int z = 0; z < [ views count ]; z++)
		[ views[z] keyUp:theEvent ];
}

/*
 * Called when the system thinks we need to draw.
 */
- (void) drawRect:(NSRect)rect
{
	double currentTime = CFAbsoluteTimeGetCurrent();
	if (previousTime != 0)
		frameDuration = (currentTime - previousTime) * 1000.0;
	previousTime = currentTime;
	
	// Disable this view while the app is running
	if (appRunning && (projectCommand & MD_PROJECT_DISABLE))
		return;
		
	glEnable(GL_MULTISAMPLE);
	
	if (rebuildShaders)
	{
		[ self setupShaders ];
		rebuildShaders = FALSE;
	}
	
	glUseProgram(program[1]);
	
	glUniform1i(programLocations[MD_PROGRAM_ENABLENORMALS], 0);
	glUniform1i(programLocations[MD_PROGRAM_ENABLETEXTURES], 0);
	// Render from POV of light
	unsigned int numberOfShadowTextures = 1;
	unsigned int shadowNums[3] = { 0, 0, 0 };
	std::vector<unsigned int> shadowNums2[3];
	{
		const NSString* realType[3] = { @"Dir", @"Point", @"Spot" };
		for (unsigned int t = 0; t < [ otherObjects count ]; t++)
		{
			if (![ otherObjects[t] isKindOfClass:[ MDLight class ] ])
				continue;
			MDLight* light = otherObjects[t];
			int y = [ light lightType ];
			unsigned int realT = shadowNums[y]++;
			
			shadowNums2[y].push_back(realT);
			if (![ light enableShadows ])
			{
				numberOfShadowTextures++;
				continue;
			}
			
			glBindFramebuffer(GL_FRAMEBUFFER, shadowFBO[y][realT]);
			
			glColorMask(FALSE, FALSE, FALSE, FALSE);
			
			if (y == 1)
			{
				numberOfShadowTextures++;
				projectionMatrix = MDMatrixIdentity();
				MDMatrixSetPerspective(&projectionMatrix, 90, 1.0, 0.1, 1000.0);
				const MDVector3 looks[] = { { 50, 0, 0 }, { -50, 0, 0 }, { 0, 50, 0 }, { 0, -50, 0 }, { 0, 0, 50 }, { 0, 0, -50 } };
				const MDVector3 ups[] = { { 0, -1, 0 }, { 0, -1, 0 }, { 0, 0, 1 }, { 0, 0, -1 }, { 0, -1, 0 }, { 0, -1, 0 } };
				glUseProgram(program[1]);
				for (int i = 0; i < 6; i++)
				{
					modelViewMatrix = MDMatrixIdentity();
					MDMatrixLookAt(&modelViewMatrix, [ light position ], [ light position ] + looks[i], ups[i]);
					
					glFramebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_TEXTURE_CUBE_MAP_POSITIVE_X + i, shadowTexture[y][realT], 0);
					glViewport(0, 0, 640, 640);
					glClear(GL_DEPTH_BUFFER_BIT);
					glEnable(GL_DEPTH_TEST);
					glDepthFunc(GL_LEQUAL);
					
					glEnable(GL_CULL_FACE);
					glCullFace(GL_BACK);
					
					// Draw objects
					MDMatrix modelViewProjection = projectionMatrix * modelViewMatrix;
					for (unsigned int z = 0; z < [ objects count ]; z++)
					{
						if (![ objects[z] shouldDraw ])
							continue;
						MDObject* obj = objects[z];
						
						// Determine winding
						unsigned int negScales = 0;
						if (obj.scaleX < 0)
							negScales++;
						if (obj.scaleY < 0)
							negScales++;
						if (obj.scaleZ < 0)
							negScales++;
						glFrontFace(((negScales % 2) == 0) ? GL_CCW : GL_CW);
						
						MDMatrix realMatrix = modelViewProjection * [ obj modelViewMatrix ];
						glUniformMatrix4fv(programLocations[MD_PROGRAM_MODELVIEWPROJECTION], 1, NO, realMatrix.data);
						
						[ [ obj instance ] drawShadowVBO ];
					}
					glDisable(GL_CULL_FACE);
				}
			}
			else
			{
				glEnable(GL_DEPTH_TEST);
				glDepthFunc(GL_LEQUAL);
				glViewport(0, 0, 640, 480);
				glClear(GL_DEPTH_BUFFER_BIT);
				
				projectionMatrix = MDMatrixIdentity();
				float fovY = 45;
				if (y == 2)
					fovY = acos([ light spotCut ]) / M_PI * 180;
				MDMatrixSetPerspective(&projectionMatrix, fovY, 640.0 / 480.0, 0.1, 1000.0);
				modelViewMatrix = MDMatrixIdentity();
				MDMatrixLookAt(&modelViewMatrix, [ light position ], [ light spotDirection ], MDVector3Create(0, 1, 0));
				
				numberOfShadowTextures++;
				
				glEnable(GL_CULL_FACE);
				glCullFace(GL_FRONT);
				
				// Draw objects
				MDMatrix modelViewProjection = projectionMatrix * modelViewMatrix;
				for (unsigned int z = 0; z < [ objects count ]; z++)
				{
					if (![ objects[z] shouldDraw ])
						continue;
					MDObject* obj = objects[z];
					
					// Determine winding
					unsigned int negScales = 0;
					if (obj.scaleX < 0)
						negScales++;
					if (obj.scaleY < 0)
						negScales++;
					if (obj.scaleZ < 0)
						negScales++;
					glFrontFace(((negScales % 2) == 0) ? GL_CCW : GL_CW);
					
					MDMatrix realMatrix = modelViewProjection * [ obj modelViewMatrix ];
					glUniformMatrix4fv(programLocations[MD_PROGRAM_MODELVIEWPROJECTION], 1, NO, realMatrix.data);
					
					[ [ obj instance ] drawShadowVBO ];
				}
				glDisable(GL_CULL_FACE);
				
				// Setup texture matrix for shadows
				// Moving from unit cube [-1,1] to [0,1]
				float bias[16] = {
					0.5, 0.0, 0.0, 0.0,
					0.0, 0.5, 0.0, 0.0,
					0.0, 0.0, 0.5, 0.0,
					0.5, 0.5, 0.5, 1.0
				};
				
				MDMatrix matrix = MDMatrixCreate(bias) * modelViewProjection;
				glUseProgram(program[0]);
				glUniformMatrix4fv(glGetUniformLocation(program[0], [ [ NSString stringWithFormat:@"shadowMatrix%@%i", realType[y], realT ] UTF8String ]), 1, NO, matrix.data);
				glUseProgram(program[1]);
			}
		}
		
		// Reset framebuffer
		glBindFramebuffer(GL_FRAMEBUFFER, 0);
		
		glViewport( 0, 0, resolution.width, resolution.height );
		projectionMatrix = MDMatrixIdentity();
		MDMatrixSetPerspective(&projectionMatrix, 45.0, resolution.width / resolution.height, 0.1, 1000.0);
		modelViewMatrix = MDMatrixIdentity();
		
		glColorMask(TRUE, TRUE, TRUE, TRUE);
		
		glUseProgram(program[1]);
	}
	
	unsigned long fullCount = [ views count ];
	for (unsigned long z = 0; z < fullCount; z++)
	{
		if ([ (MDControlView*)views[z] beforeDraw ])
		{
			z--;
			fullCount--;
		}
	}
	
	// Clear the screen and depth buffer
	glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glEnable(GL_DEPTH_TEST);
	glDepthFunc(GL_LEQUAL);
		
	MDVector3 eyePos;
	if (currentCamera != -1 && [ otherObjects[currentCamera] isKindOfClass:[ MDCamera class ] ])
	{
		MDCamera* camera = otherObjects[currentCamera];
		if ([ camera use ])
		{
			MDVector3 cameraPoint = [ camera midPoint ];
			MDVector3 cameraLook = [ camera lookPoint ];
			float cameraOrientation = [ camera orientation ];
			/*float zrot = fabs([ camera orientation ]);
			float yrot = -atan2f(look.x, look.z) / M_PI * 180;
			MDVector3 zPoint = Rotate(MDVector3Create(look.y, look.z, 0), MDVector3Create(0, 0, 0), 0, yrot, 0);
			float xrot = atan2f(zPoint.x, zPoint.y) / M_PI * 180;
			if (fabs(yrot - 90) < 0.01)
				xrot = -atan2f(look.y, look.x) / M_PI * 180;
			else if (fabs(yrot + 90) < 0.01)
				xrot = atan2f(look.y, look.x) / M_PI * 180 + 180;
			rotatePoint = MDVector3Create(xrot, yrot, zrot);*/
			
			// Setup ModelView Matrix
			modelViewMatrix = MDMatrixIdentity();
			MDMatrixLookAt(&modelViewMatrix, cameraPoint, cameraLook, MDVector3Create(sin(cameraOrientation / 180 * M_PI), cos(cameraOrientation / 180 * M_PI), 0));
			eyePos = cameraPoint;
		}
	}
	else
	{
		MDRotationBox* box = ViewForIdentity(@"Rotation Box");
		
		// Setup ModelView Matrix
		modelViewMatrix = MDMatrixIdentity();
		MDMatrixTranslate(&modelViewMatrix, -translationPoint.x, -translationPoint.y, translationPoint.z);
		MDMatrixTranslate(&modelViewMatrix, lookPoint);
		MDMatrixRotate(&modelViewMatrix, 1, 0, 0, [ box xrotation ]);
		MDMatrixRotate(&modelViewMatrix, 0, 1, 0, [ box yrotation ]);
		MDMatrixRotate(&modelViewMatrix, 0, 0, 1, [ box zrotation ]);
		MDMatrixTranslate(&modelViewMatrix, -1 * lookPoint);
		
		// Set global rotation
		MDMatrix rotate = MDMatrixIdentity();
		MDMatrixRotate(&rotate, 0, 0, 1, -[ box zrotation ]);
		MDMatrixRotate(&rotate, 0, 1, 0, -[ box yrotation ]);
		MDMatrixRotate(&rotate, 1, 0, 0, -[ box xrotation ]);
		glUniformMatrix4fv(programLocations[MD_PROGRAM_GLOBALROTATION], 1, NO, rotate.data);
		
		eyePos = RotateB(-1 * translationPoint, lookPoint, -[ box xrotation ], -[ box yrotation ], -[ box zrotation ]) + lookPoint;
	}
		
	if (currentCamera == -1)
	{
		for (unsigned long z = 0; z < [ otherObjects count ]; z++)
		{
			glUniform1i(programLocations[MD_PROGRAM_ENABLENORMALS], 1);
			glUniform1i(programLocations[MD_PROGRAM_ENABLETEXTURES], 0);
			if ([ otherObjects[z] isKindOfClass:[ MDCamera class ] ])
			{
				MDCamera* camera = otherObjects[z];
				if ([ camera show ] && ![ camera use ])
				{
					MDVector3 midPoint = [ camera midPoint ];
					MDVector3 look = [ camera lookPoint ];
					if (look.x == midPoint.x)
						look.x += 0.00001;
					float yrot = (atan2f(look.x - midPoint.x, look.z - midPoint.z) / M_PI * 180) + 90;
					MDVector3 zPoint = Rotate(MDVector3Create(look.y - midPoint.y, look.x - midPoint.x, 0), MDVector3Create(0, 0, 0), 0, yrot, 0);
					float zrot = -(atan2f(zPoint.y, zPoint.x) / M_PI * 180) - 90;
					if (yrot >= 90 && yrot < 270)
						zrot += 180;
					float xrot = [ camera orientation ];
					MDVector3 rotatePoint = Rotate(MDVector3Create(0, 0.3, 0), MDVector3Create(0, 0, 0), 0, yrot, zrot);
					
					MDMatrix cameraMatrix = MDMatrixIdentity();
					MDMatrixTranslate(&cameraMatrix, midPoint + rotatePoint);
					MDMatrixRotate(&cameraMatrix, 0, 1, 0, yrot);
					MDMatrixRotate(&cameraMatrix, 0, 0, 1, zrot);
					MDMatrixTranslate(&cameraMatrix, -1 * rotatePoint);
					MDMatrixRotate(&cameraMatrix, 1, 0, 0, xrot);
					MDMatrixTranslate(&cameraMatrix, rotatePoint);
					glUniformMatrix4fv(programLocations[MD_PROGRAM_MODELVIEWPROJECTION], 1, NO, (projectionMatrix * modelViewMatrix * cameraMatrix).data);
					MDMatrix rotate = MDMatrixIdentity();
					MDMatrixRotate(&rotate, 0, 1, 0, yrot);
					MDMatrixRotate(&rotate, 0, 0, 1, zrot);
					MDMatrixRotate(&rotate, 1, 0, 0, xrot);
					glUniformMatrix4fv(programLocations[MD_PROGRAM_NORMALROTATION], 1, NO, (rotate).data);
					[ models[0].instance drawVBO:programConstants shadow:0 ];
					
					MDMatrix translate = MDMatrixIdentity();
					MDMatrixTranslate(&translate, look);
					glUniformMatrix4fv(programLocations[MD_PROGRAM_MODELVIEWPROJECTION], 1, NO, (projectionMatrix * modelViewMatrix * translate).data);
					glUniformMatrix4fv(programLocations[MD_PROGRAM_NORMALROTATION], 1, NO, MDMatrixIdentity().data);
					glVertexAttrib4f(1, 1, 1, 0.3, 1);
					gluSphere(0.1, 16, 16);
					
					glUniformMatrix4fv(programLocations[MD_PROGRAM_MODELVIEWPROJECTION], 1, NO, (projectionMatrix * modelViewMatrix).data);
					glUniform1i(programLocations[MD_PROGRAM_ENABLENORMALS], 0);
					glVertexAttrib4f(1, 0.7, 0.7, 0, 1);
					gluLine(midPoint, look);
					
					if ([ camera selected ])
					{
						MDMatrix boxMatrix = MDMatrixIdentity();
						MDRect rect = BoundingBoxRotate([ camera obj ]);
						MDMatrixTranslate(&boxMatrix, rect.x + rect.width / 2, rect.y + rect.height / 2, rect.z + rect.depth / 2);
						MDMatrixScale(&boxMatrix, rect.width, rect.height, rect.depth);
						glVertexAttrib4f(1, 1, 1, 1, 1);		// Colors
						glVertexAttrib3f(2, 0, 0, 0);			// Normals
						glVertexAttrib2f(3, 0, 0);				// Texture Coordinates
						glUniformMatrix4fv(programLocations[MD_PROGRAM_MODELVIEWPROJECTION], 1, NO, (projectionMatrix * modelViewMatrix * boxMatrix).data);
						glUniform1i(programLocations[MD_PROGRAM_ENABLENORMALS], 0);
						glUniform1i(programLocations[MD_PROGRAM_ENABLETEXTURES], 0);
						glBindVertexArray(boxData[0]);
						glDrawArrays(GL_LINES, 0, 24);
						
						if (currentObjectTool == MD_OBJECT_MOVE)
						{
							glUniform1i(programLocations[MD_PROGRAM_ENABLENORMALS], 1);
							DrawObjectTool([ camera obj ], currentObjectTool, translationPoint.z, 0, [ camera obj ], projectionMatrix, modelViewMatrix, programLocations);
						}
					}
					else if ([ camera lookSelected ])
					{
						MDMatrix boxMatrix = MDMatrixIdentity();
						MDRect rect = BoundingBoxRotate([ camera lookObj ]);
						MDMatrixTranslate(&boxMatrix, rect.x + rect.width / 2, rect.y + rect.height / 2, rect.z + rect.depth / 2);
						MDMatrixScale(&boxMatrix, rect.width, rect.height, rect.depth);
						glVertexAttrib4f(1, 1, 1, 1, 1);		// Colors
						glVertexAttrib3f(2, 0, 0, 0);			// Normals
						glVertexAttrib2f(3, 0, 0);				// Texture Coordinates
						glUniformMatrix4fv(programLocations[MD_PROGRAM_MODELVIEWPROJECTION], 1, NO, (projectionMatrix * modelViewMatrix * boxMatrix).data);
						glUniform1i(programLocations[MD_PROGRAM_ENABLENORMALS], 0);
						glUniform1i(programLocations[MD_PROGRAM_ENABLETEXTURES], 0);
						glBindVertexArray(boxData[0]);
						glDrawArrays(GL_LINES, 0, 24);
						
						if (currentObjectTool == MD_OBJECT_MOVE)
						{
							glUniform1i(programLocations[MD_PROGRAM_ENABLENORMALS], 1);
							DrawObjectTool([ camera lookObj ], currentObjectTool, translationPoint.z, 0, [ camera lookObj ], projectionMatrix, modelViewMatrix, programLocations);
						}
					}
				}
			}
			else if ([ otherObjects[z] isKindOfClass:[ MDLight class ] ])
			{
				MDLight* light = otherObjects[z];
				if ([ light show ])
				{
					MDVector3 midPoint = light.position;
					MDVector3 look = light.spotDirection;
					
					if (light.lightType != MDPointLight)
					{
						if (look.x == midPoint.x)
							look.x += 0.00001;
						float yrot = (atan2f(look.x - midPoint.x, look.z - midPoint.z) / M_PI * 180) + 90;
						MDVector3 zPoint = Rotate(MDVector3Create(look.y - midPoint.y, look.x - midPoint.x, 0), MDVector3Create(0, 0, 0), 0, yrot, 0);
						float zrot = -(atan2f(zPoint.y, zPoint.x) / M_PI * 180) - 90;
						if (yrot >= 90 && yrot < 270)
							zrot += 180;
						
						MDMatrix lightMatrix = MDMatrixIdentity();
						MDMatrixTranslate(&lightMatrix, midPoint);
						MDMatrixRotate(&lightMatrix, 0, 1, 0, yrot);
						MDMatrixRotate(&lightMatrix, 0, 0, 1, zrot);
						
						glUniformMatrix4fv(programLocations[MD_PROGRAM_MODELVIEWPROJECTION], 1, NO, (projectionMatrix * modelViewMatrix * lightMatrix).data);
						MDMatrix rotate = MDMatrixIdentity();
						MDMatrixRotate(&rotate, 0, 1, 0, yrot);
						MDMatrixRotate(&rotate, 0, 0, 1, zrot);
						glUniformMatrix4fv(programLocations[MD_PROGRAM_NORMALROTATION], 1, NO, (rotate).data);
						[ models[light.lightType + 1].instance drawVBO:programConstants shadow:0 ];
					}
					else
					{
						MDMatrix lightMatrix = MDMatrixIdentity();
						MDMatrixTranslate(&lightMatrix, midPoint);
						glUniformMatrix4fv(programLocations[MD_PROGRAM_MODELVIEWPROJECTION], 1, NO, (projectionMatrix * modelViewMatrix * lightMatrix).data);
						glUniformMatrix4fv(programLocations[MD_PROGRAM_NORMALROTATION], 1, NO, (MDMatrixIdentity()).data);
						[ models[light.lightType + 1].instance drawVBO:programConstants shadow:0 ];
					}
					
					if ([ light selected ])
					{
						MDMatrix boxMatrix = MDMatrixIdentity();
						MDRect rect = BoundingBoxRotate([ light obj ]);
						MDMatrixTranslate(&boxMatrix, rect.x + rect.width / 2, rect.y + rect.height / 2, rect.z + rect.depth / 2);
						MDMatrixScale(&boxMatrix, rect.width, rect.height, rect.depth);
						glVertexAttrib4f(1, 1, 1, 1, 1);		// Colors
						glVertexAttrib3f(2, 0, 0, 0);			// Normals
						glVertexAttrib2f(3, 0, 0);				// Texture Coordinates
						glUniformMatrix4fv(programLocations[MD_PROGRAM_MODELVIEWPROJECTION], 1, NO, (projectionMatrix * modelViewMatrix * boxMatrix).data);
						glUniform1i(programLocations[MD_PROGRAM_ENABLENORMALS], 0);
						glUniform1i(programLocations[MD_PROGRAM_ENABLETEXTURES], 0);
						glBindVertexArray(boxData[0]);
						glDrawArrays(GL_LINES, 0, 24);
						
						if (currentObjectTool == MD_OBJECT_MOVE)
						{
							glUniform1i(programLocations[MD_PROGRAM_ENABLENORMALS], 1);
							DrawObjectTool([ light obj ], currentObjectTool, translationPoint.z, 0, [ light obj ], projectionMatrix, modelViewMatrix, programLocations);
						}
					}
				}
			}
			else if ([ otherObjects[z] isKindOfClass:[ MDSound class ] ])
			{
				MDSound* sound = otherObjects[z];
				if ([ sound show ])
				{
					MDMatrix lightMatrix = MDMatrixIdentity();
					MDMatrixTranslate(&lightMatrix, [ sound position ]);
					glUniformMatrix4fv(programLocations[MD_PROGRAM_MODELVIEWPROJECTION], 1, NO, (projectionMatrix * modelViewMatrix * lightMatrix).data);
					glUniformMatrix4fv(programLocations[MD_PROGRAM_NORMALROTATION], 1, NO, (MDMatrixIdentity()).data);
					[ models[4].instance drawVBO:programConstants shadow:0 ];
					
					if ([ sound selected ])
					{
						MDMatrix boxMatrix = MDMatrixIdentity();
						MDRect rect = BoundingBoxRotate([ sound obj ]);
						MDMatrixTranslate(&boxMatrix, rect.x + rect.width / 2, rect.y + rect.height / 2, rect.z + rect.depth / 2);
						MDMatrixScale(&boxMatrix, rect.width, rect.height, rect.depth);
						glVertexAttrib4f(1, 1, 1, 1, 1);		// Colors
						glVertexAttrib3f(2, 0, 0, 0);			// Normals
						glVertexAttrib2f(3, 0, 0);				// Texture Coordinates
						glUniformMatrix4fv(programLocations[MD_PROGRAM_MODELVIEWPROJECTION], 1, NO, (projectionMatrix * modelViewMatrix * boxMatrix).data);
						glUniform1i(programLocations[MD_PROGRAM_ENABLENORMALS], 0);
						glUniform1i(programLocations[MD_PROGRAM_ENABLETEXTURES], 0);
						glBindVertexArray(boxData[0]);
						glDrawArrays(GL_LINES, 0, 24);
						
						if (currentObjectTool == MD_OBJECT_MOVE)
						{
							glUniform1i(programLocations[MD_PROGRAM_ENABLENORMALS], 1);
							DrawObjectTool([ sound obj ], currentObjectTool, translationPoint.z, 0, [ sound obj ], projectionMatrix, modelViewMatrix, programLocations);
						}
					}
				}
			}
		}
	}
	
	if (projectCommand & MD_PROJECT_SHOW_GRID)
	{
		// Draw Grid
		glVertexAttrib4f(1, 1, 1, 1, 1);		// Colors
		glVertexAttrib3f(2, 0, 0, 0);			// Normals
		glVertexAttrib2f(3, 0, 0);				// Texture Coordinates
		glUniformMatrix4fv(programLocations[MD_PROGRAM_MODELVIEWPROJECTION], 1, NO, (projectionMatrix * modelViewMatrix).data);
		glUniform1i(programLocations[MD_PROGRAM_ENABLENORMALS], 0);
		glUniform1i(programLocations[MD_PROGRAM_ENABLETEXTURES], 0);
		glBindVertexArray(gridData[0]);
		glDrawArrays(GL_LINES, 0, 44);
	}
	
	glUseProgram(program[0]);
	[ self setUniforms ];
	
	//unsigned int currentName = cameraNames;
	
	// Culling
	glCullFace(GL_BACK);
	
	const NSString* realTypes[3] = { @"Dir", @"Point", @"Spot" };
	unsigned int thisShadow = 0;
	for (int y = 0; y < 3; y++)
	{
		for (unsigned int z = 0; z < shadowNums2[y].size(); z++)
		{
			// Set the shadow texture
			glUniform1i(glGetUniformLocation(program[0], [ [ NSString stringWithFormat:@"shadowMap%@%u", realTypes[y], shadowNums2[y][z] ] UTF8String ]), thisShadow + 1);
			glActiveTexture(GL_TEXTURE0 + thisShadow + 1);
			glBindTexture((y == 1) ? GL_TEXTURE_CUBE_MAP : GL_TEXTURE_2D, shadowTexture[y][shadowNums2[y][z]]);
			thisShadow++;
		}
	}
	glActiveTexture(GL_TEXTURE0);
	glUniform3f(programConstants[MD_PROGRAM0_EYEPOS], eyePos.x, eyePos.y, eyePos.z);
	
	MDMatrix modelViewProjection = projectionMatrix * modelViewMatrix;
	for (unsigned int z = 0; z < [ objects count ]; z++)
	{
		if (![ objects[z] shouldDraw ] || ![ objects[z] shouldView ])
			continue;
		
		MDObject* obj = objects[z];
		
		if (![ alphaObjects containsIndex:z ])
		{
			// Determine winding
			unsigned int negScales = 0;
			if (obj.scaleX < 0)
				negScales++;
			if (obj.scaleY < 0)
				negScales++;
			if (obj.scaleZ < 0)
				negScales++;
			glFrontFace(((negScales % 2) == 0) ? GL_CCW : GL_CW);
			
			MDMatrix objMatrix = [ obj modelViewMatrix ];
			MDMatrix realMatrix = modelViewProjection * objMatrix;
			glUniformMatrix4fv(programConstants[MD_PROGRAM0_MODELVIEWPROJECTION], 1, NO, realMatrix.data);
						
			glUniform3f(programConstants[MD_PROGRAM0_TRANSLATE], obj.translateX, obj.translateY, obj.translateZ);
			glUniform3f(programConstants[MD_PROGRAM0_SCALE], obj.scaleX, obj.scaleY, obj.scaleZ);
			glUniform4f(programConstants[MD_PROGRAM0_ROTATE], obj.rotateAxis.x, obj.rotateAxis.y, obj.rotateAxis.z, obj.rotateAngle);
			glUniform4f(programConstants[MD_PROGRAM0_OBJECTCOLOR], obj.colorMultiplier.x, obj.colorMultiplier.y, obj.colorMultiplier.z, obj.colorMultiplier.w);
			glUniformMatrix4fv(programConstants[MD_PROGRAM0_OBJMATRIX], 1, NO, objMatrix.data);
			
			glEnable(GL_CULL_FACE);
			[ obj drawVBO:programConstants shadow:numberOfShadowTextures ];
			glDisable(GL_CULL_FACE);
		}
		
		if (currentMode == MD_FACE_MODE)
		{
			if ([ selected containsObject:obj withPoints:nil ])
			{
				MDObject* faceObj = [ [ MDObject alloc ] init ];
				for (int q = 0; q < 3; q++)
				{
					faceObj.objectColors[q].x = obj.objectColors[q].x;
					faceObj.objectColors[q].y = obj.objectColors[q].y;
					faceObj.objectColors[q].z = obj.objectColors[q].z;
					faceObj.objectColors[q].w = obj.objectColors[q].w;
				}
				MDInstance* instance = [ [ MDInstance alloc ] initWithInstance:[ obj instance ] ];
				[ faceObj setInstance:instance ];
				
				/*glDisable(GL_LIGHTING);
				[ self setLightingUniform ];
				std::vector<MDVector3> points = BoundingBox(faceObj, [ faceObj midPoint ]);
				glColor4d(1, 1, 1, 1);
				glBegin(GL_LINES);
				{
					for (int z = 0; z < points.size(); z++)
						glVertex3d(points[z].x, points[z].y, points[z].z);
				}
				glEnd();
				glEnable(GL_LIGHTING);
				[ self setLightingUniform ];*/
				DrawObjectTool(faceObj, currentObjectTool, translationPoint.z, 0, obj, projectionMatrix, modelViewMatrix, programLocations);
			}
		}
		else if (currentMode == MD_VERTEX_MODE)
		{
			glUseProgram(program[1]);
			glVertexAttrib4d(1, 1.0, 1.0, 0.2, 1.0);
			glBindVertexArray(cubeData[0]);
			glUniform1i(programLocations[MD_PROGRAM_ENABLENORMALS], 1);
			glUniform1i(programLocations[MD_PROGRAM_ENABLETEXTURES], 0);
			glUniformMatrix4fv(programLocations[MD_PROGRAM_NORMALROTATION], 1, NO, MDMatrixIdentity().data);
			for (unsigned long q = 0; q < [ obj numberOfPoints ]; q++)
			{
				MDPoint* p = [ obj pointAtIndex:q ];
				
				MDMatrix vertexMatrix = MDMatrixIdentity();
				MDMatrixTranslate(&vertexMatrix, p.x + obj.translateX, p.y + obj.translateY, p.z + obj.translateZ);
				glUniformMatrix4fv(programLocations[MD_PROGRAM_MODELVIEWPROJECTION], 1, NO, (modelViewProjection * vertexMatrix).data);
				glDrawArrays(GL_TRIANGLES, 0, 36);
				
				if ([ selected containsObject:obj withPoints:@[[ obj pointAtIndex:q ]] ])
				{
					MDInstance* instance = mdCube(p.x + obj.translateX, p.y + obj.translateY, p.z + obj.translateZ, 0.3, 0.3, 0.3);
					MDObject* pointObj = [ [ MDObject alloc ] initWithInstance:instance ];
					
					MDMatrix boxMatrix = vertexMatrix;
					MDMatrixScale(&boxMatrix, 0.3, 0.3, 0.3);
					glVertexAttrib4f(1, 1, 1, 1, 1);		// Colors
					glVertexAttrib3f(2, 0, 0, 0);			// Normals
					glVertexAttrib2f(3, 0, 0);				// Texture Coordinates
					glUniformMatrix4fv(programLocations[MD_PROGRAM_MODELVIEWPROJECTION], 1, NO, (modelViewProjection * boxMatrix).data);
					glUniform1i(programLocations[MD_PROGRAM_ENABLENORMALS], 0);
					glUniform1i(programLocations[MD_PROGRAM_ENABLETEXTURES], 0);
					glBindVertexArray(boxData[0]);
					glDrawArrays(GL_LINES, 0, 24);
					glUniform1i(programLocations[MD_PROGRAM_ENABLENORMALS], 1);
					
					DrawObjectTool(pointObj, currentObjectTool, translationPoint.z, 0, obj, projectionMatrix, modelViewMatrix, programLocations);
					
					glVertexAttrib4d(1, 1.0, 1.0, 0.2, 1.0);
					glBindVertexArray(cubeData[0]);
					glUniform1i(programLocations[MD_PROGRAM_ENABLENORMALS], 1);
					glUniform1i(programLocations[MD_PROGRAM_ENABLETEXTURES], 0);
					glUniformMatrix4fv(programLocations[MD_PROGRAM_NORMALROTATION], 1, NO, MDMatrixIdentity().data);
				}
			}
			glBindVertexArray(0);
			glUseProgram(program[0]);
		}
		
		// Update any animations
		//if ([ obj isPlayingAnimation ])
		//	[ obj updateCurrentAnimation ];
				
		if ([ selected containsObject:obj withPoints:nil ] && currentMode == MD_OBJECT_MODE)
		{
			glUseProgram(program[1]);
			
			MDMatrix boxMatrix = MDMatrixIdentity();
			MDRect rect = BoundingBoxRotate(obj);
			MDMatrixTranslate(&boxMatrix, rect.x + rect.width / 2, rect.y + rect.height / 2, rect.z + rect.depth / 2);
			MDMatrixScale(&boxMatrix, rect.width, rect.height, rect.depth);
			glVertexAttrib4f(1, 1, 1, 1, 1);		// Colors
			glVertexAttrib3f(2, 0, 0, 0);			// Normals
			glVertexAttrib2f(3, 0, 0);				// Texture Coordinates
			glUniformMatrix4fv(programLocations[MD_PROGRAM_MODELVIEWPROJECTION], 1, NO, (modelViewProjection * boxMatrix).data);
			glUniform1i(programLocations[MD_PROGRAM_ENABLENORMALS], 0);
			glUniform1i(programLocations[MD_PROGRAM_ENABLETEXTURES], 0);
			glBindVertexArray(boxData[0]);
			glDrawArrays(GL_LINES, 0, 24);
			
			glUniform1i(programLocations[MD_PROGRAM_ENABLENORMALS], 1);
			DrawObjectTool(obj, currentObjectTool, translationPoint.z, 0, obj, projectionMatrix, modelViewMatrix, programLocations);
			
			glUseProgram(program[0]);
		}
	}
	
	if ([ alphaObjects count ] != 0)
	{
		unsigned long temp = [ alphaObjects firstIndex ];
		do
		{
			MDObject* obj = objects[temp];
			
			if (!obj.shouldDraw || !obj.shouldView)
				continue;
			
			// Determine winding
			unsigned int negScales = 0;
			if (obj.scaleX < 0)
				negScales++;
			if (obj.scaleY < 0)
				negScales++;
			if (obj.scaleZ < 0)
				negScales++;
			glFrontFace(((negScales % 2) == 0) ? GL_CCW : GL_CW);
			
			MDMatrix objMatrix = [ obj modelViewMatrix ];
			MDMatrix realMatrix = modelViewProjection * objMatrix;
			glUniformMatrix4fv(programConstants[MD_PROGRAM0_MODELVIEWPROJECTION], 1, NO, realMatrix.data);
			glUniform3f(programConstants[MD_PROGRAM0_TRANSLATE], obj.translateX, obj.translateY, obj.translateZ);
			glUniform3f(programConstants[MD_PROGRAM0_SCALE], obj.scaleX, obj.scaleY, obj.scaleZ);
			glUniform4f(programConstants[MD_PROGRAM0_ROTATE], obj.rotateAxis.x, obj.rotateAxis.y, obj.rotateAxis.z, obj.rotateAngle);
			glUniform4f(programConstants[MD_PROGRAM0_OBJECTCOLOR], obj.colorMultiplier.x, obj.colorMultiplier.y, obj.colorMultiplier.z, obj.colorMultiplier.w);
			glUniformMatrix4fv(programConstants[MD_PROGRAM0_OBJMATRIX], 1, NO, objMatrix.data);
			
			glEnable(GL_CULL_FACE);
			[ obj drawVBO:programConstants shadow:numberOfShadowTextures ];
			glDisable(GL_CULL_FACE);
		}
		while ((temp = [ alphaObjects indexGreaterThanIndex:temp ]) != NSNotFound);
	}
	
	glBindVertexArray(0);
	glActiveTexture(GL_TEXTURE0);
	glBindTexture(GL_TEXTURE_2D, 0);
	
	glDisable(GL_MULTISAMPLE);
	
	glUseProgram(program[1]);
	if (currentObject)
	{
		NSArray* obj = currentObject;
		
		glUniformMatrix4fv(programLocations[MD_PROGRAM_MODELVIEWPROJECTION], 1, NO, (projectionMatrix * modelViewMatrix).data);
		glUniform1i(programLocations[MD_PROGRAM_ENABLENORMALS], 0);
		glUniform1i(programLocations[MD_PROGRAM_ENABLETEXTURES], 0);
		for (unsigned int y = 0; y < [ obj count ]; y++)
		{
			unsigned int currentObjData[3];
			
			MDFace* face = obj[y];
			
			float verts[[ [ face points ] count ] * 3];
			for (int z = 0; z < [ [ face points ] count ]; z++)
			{
				MDPoint* p = [ face points ][z];
				verts[(z * 3)] = p.x;
				verts[(z * 3) + 1] = p.y;
				verts[(z * 3) + 2] = p.z;
			}
			
			glGenVertexArrays(1, &currentObjData[0]);
			glBindVertexArray(currentObjData[0]);
			
			glGenBuffers(1, &currentObjData[1]);
			glBindBuffer(GL_ARRAY_BUFFER, currentObjData[1]);
			glBufferData(GL_ARRAY_BUFFER, [ [ face points ] count ] * 3 * sizeof(float), verts, GL_STREAM_DRAW);
			glVertexAttribPointer(0, 3, GL_FLOAT, NO, 0, NULL);
			glEnableVertexAttribArray(0);

			glVertexAttrib4f(1, 0.3, 0.3, 0.3, 1);	// Colors
			glVertexAttrib3f(2, 0, 0, 0);			// Normals
			glVertexAttrib2f(3, 0, 0);				// Texture Coordinates
						
			glGenBuffers(1, &currentObjData[2]);
			glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, currentObjData[2]);
			unsigned int* indexData = (unsigned int*)malloc(sizeof(unsigned int) * [ [ face indices ] count ]);
			for (unsigned int z = 0; z < [ [ face indices ] count ]; z++)
				indexData[z] = [ [ face indices ][z] unsignedIntValue ];
			glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(unsigned int) * [ [ face indices ] count ], indexData, GL_STREAM_DRAW);
			
			glDrawElements(GL_TRIANGLES, (unsigned int)[ [ face indices ] count ], GL_UNSIGNED_INT, NULL);
			free(indexData);
			
			glDeleteBuffers(1, &currentObjData[2]);
			glDeleteBuffers(1, &currentObjData[1]);
			glDeleteVertexArrays(1, &currentObjData[0]);
		}
	}
	
	glUniform1i(programLocations[MD_PROGRAM_ENABLENORMALS], 0);
	glUniform1i(programLocations[MD_PROGRAM_ENABLETEXTURES], 0);
	glUniformMatrix4fv(programLocations[MD_PROGRAM_MODELVIEWPROJECTION], 1, NO, (projectionMatrix * modelViewMatrix).data);
	for (unsigned long z = 0; z < [ otherObjects count ]; z++)
	{
		if ([ otherObjects[z] isKindOfClass:[ MDCurve class ] ])
		{
			MDCurve* curve = otherObjects[z];
			if ([ curve show ])
				[ curve draw ];
		}
	}

	// Skybox
	if ([ sceneProperties[@"Skybox Visible"] boolValue ])
	{
		MDMatrix skyMatrix = MDMatrixIdentity();
		if (currentCamera != -1 && [ otherObjects[currentCamera] isKindOfClass:[ MDCamera class ] ])
		{
			MDCamera* camera = otherObjects[currentCamera];
			if ([ camera use ])
			{
				MDVector3 look = [ camera lookPoint ] - [ camera midPoint ];
				float zrot = fabs([ camera orientation ]);
				float yrot = -atan2f(look.x, look.z) / M_PI * 180;
				MDVector3 zPoint = Rotate(MDVector3Create(look.y, look.z, 0), MDVector3Create(0, 0, 0), 0, yrot, 0);
				float xrot = -atan2f(-fabs(zPoint.x), -fabs(zPoint.y)) / M_PI * 180 + 180;
				if (look.y < 0)
					xrot = 360 - xrot;
				if (fabs(yrot - 90) < 0.01)
					xrot = atan2f(look.y, look.x) / M_PI * 180 + 180;
				else if (fabs(yrot + 90) < 0.01)
					xrot = -atan2f(look.y, look.x) / M_PI * 180;
				
				MDMatrixRotate(&skyMatrix, 1, 0, 0, xrot);
				MDMatrixRotate(&skyMatrix, 0, 1, 0, yrot);
				MDMatrixRotate(&skyMatrix, 0, 0, 1, zrot);
			}
		}
		else
		{
			MDRotationBox* box = ViewForIdentity(@"Rotation Box");
			MDMatrixRotate(&skyMatrix, 1, 0, 0, [ box xrotation ]);
			MDMatrixRotate(&skyMatrix, 0, 1, 0, [ box yrotation ]);
			MDMatrixRotate(&skyMatrix, 0, 0, 1, [ box zrotation ]);
		}
		
		NSColor* color = sceneProperties[@"Skybox Color"];
		unsigned int texture = [ sceneProperties[@"Skybox Texture"] unsignedIntValue ];
		
		glEnable(GL_MULTISAMPLE);
		glBindTexture(GL_TEXTURE_2D, texture);
		
		glUniformMatrix4fv(programLocations[MD_PROGRAM_MODELVIEWPROJECTION], 1, NO, (projectionMatrix * skyMatrix).data);
		glUniform1i(programLocations[MD_PROGRAM_ENABLENORMALS], 0);
		glUniform1i(programLocations[MD_PROGRAM_ENABLETEXTURES], 1);
		glUniform1i(programLocations[MD_PROGRAM_TEXTURE], 0);
		
		glBindVertexArray(skyboxData[0]);
		glVertexAttrib4f(1, [ color redComponent ], [ color greenComponent ], [ color blueComponent ], [ color alphaComponent ]);
		glDrawArrays(GL_TRIANGLES, 0, 36);
		
		glBindTexture(GL_TEXTURE_2D, 0);
		glDisable(GL_MULTISAMPLE);
	}
	
	glUseProgram(program[2]);
	glUniformMatrix4fv(particleLocations[MD_PROGRAM2_MV], 1, NO, modelViewMatrix.data);
	glUniformMatrix4fv(particleLocations[MD_PROGRAM2_P], 1, NO, projectionMatrix.data);
	unsigned int desiredFPS = [ (GLWindow*)[ self window ] FPS ];
	for (unsigned long z = 0; z < [ otherObjects count ]; z++)
	{
		if ([ otherObjects[z] isKindOfClass:[ MDParticleEngine class ] ])
		{
			MDParticleEngine* engine = otherObjects[z];
			if ([ engine show ])
				[ engine draw:particleLocations duration:frameDuration desired:desiredFPS ];
		}
	}
	glUseProgram(program[1]);
	
	if ((commandFlag & SHAPE) ||( commandFlag & SHAPE2))
	{
		MDMatrix trans = MDMatrixIdentity();
		MDMatrixTranslate(&trans, 0, 0, -20 - translationPoint.z);
		glVertexAttrib4f(1, 1, 1, 1, 0);		// Colors
		glVertexAttrib3f(2, 0, 0, 0);			// Normals
		glVertexAttrib2f(3, 0, 0);				// Texture Coordinates
		glUniformMatrix4fv(programLocations[MD_PROGRAM_MODELVIEWPROJECTION], 1, NO, (projectionMatrix * modelViewMatrix * trans).data);
		glUniform1i(programLocations[MD_PROGRAM_ENABLENORMALS], 0);
		glUniform1i(programLocations[MD_PROGRAM_ENABLETEXTURES], 0);
		glBindVertexArray(projectData[0]);
		glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	}
	
	glBindBuffer(GL_ARRAY_BUFFER, 0);
	
	MDMatrix viewProjection = MDMatrixIdentity();
	MDMatrixSetOthro(&viewProjection, 0, resolution.width, 0, resolution.height);
	MDSetGUIModelViewMatrix(MDMatrixIdentity());
	MDSetGUIProjectionMatrix(viewProjection);
	
	glUniformMatrix4fv(programLocations[MD_PROGRAM_GLOBALROTATION], 1, NO, (MDMatrixIdentity()).data);

	MDMatrix matrix = (MDGUIProjectionMatrix() * MDGUIModelViewMatrix());
	glEnable(GL_MULTISAMPLE);
	for (int z = 0; z < [ views count ]; z++)
	{
		glUniformMatrix4fv(MDGUIProgramLocations()[MD_PROGRAM_MODELVIEWPROJECTION], 1, NO, matrix.data);
		if ([ views[z] uses3D ])
		{
			glUniform1i(programLocations[MD_PROGRAM_ENABLENORMALS], 1);
			
			MDRotationBox* box = views[z];
			// Make it so these fps options apply to views as whole with MDSetDesiredFPS and etc.
			[ box setDesiredFPS:desiredFPS ];
			[ box setFrameDuration:frameDuration ];
			[ box draw3DView:modelViewMatrix projectionMatrix:projectionMatrix ];
			
			glUniform1i(programLocations[MD_PROGRAM_ENABLENORMALS], 0);
			
			continue;
		}
		[ views[z] drawView ];
	}
	
	for (int z = 0; z < [ views count ]; z++)
		[ views[z] alphaDraw ];
	
	// Shows shadow image
	/*glUniform1i(glGetUniformLocation(program[1], "isDepth"), 1);
	for (int y = 0; y < 3; y++)
	{
		if (shadowTexture[y].size() == 0)
			continue;
		// Draw texture in bottom left
		unsigned int textureVAO[3];
		glGenVertexArrays(1, &textureVAO[0]);
		glBindVertexArray(textureVAO[0]);
		
		float texCoords[8] = { 0, 0, 1, 0, 0, 1, 1, 1 };
		float verts[12] = { -1.5, -1.1, -3, 0, -1.1, -3, -1.5, 0, -3, 0, 0, -3 };
		
		glGenBuffers(1, &textureVAO[1]);
		glGenBuffers(1, &textureVAO[1]);
		glBindBuffer(GL_ARRAY_BUFFER, textureVAO[1]);
		glBufferData(GL_ARRAY_BUFFER, 4 * 3 * sizeof(float), verts, GL_STATIC_DRAW);
		glVertexAttribPointer(0, 3, GL_FLOAT, NO, 0, NULL);
		glEnableVertexAttribArray(0);
		
		glGenBuffers(1, &textureVAO[2]);
		glGenBuffers(1, &textureVAO[2]);
		glBindBuffer(GL_ARRAY_BUFFER, textureVAO[2]);
		glBufferData(GL_ARRAY_BUFFER, 4 * 2 * sizeof(float), texCoords, GL_STATIC_DRAW);
		glVertexAttribPointer(3, 2, GL_FLOAT, NO, 0, NULL);
		glEnableVertexAttribArray(3);
		
		glVertexAttrib4f(1, 1, 1, 1, 1);
		
		if (y == 1)
		{
			glActiveTexture(GL_TEXTURE1);
			glUniform1i(glGetUniformLocation(program[1], "isCube"), 1);
			glBindTexture(GL_TEXTURE_CUBE_MAP, shadowTexture[y][0]);
			glUniform1i(glGetUniformLocation(program[1], "textureCube"), 1);

			MDMatrix model = MDMatrixIdentity();
			MDMatrixScale(&model, 0.5, 0.5, 1);
			MDMatrixTranslate(&model, -1.6, -1.4, 0);
			glUniformMatrix4fv(programLocations[MD_PROGRAM_MODELVIEWPROJECTION], 1, NO, (projectionMatrix * model).data);
			glUniform1i(glGetUniformLocation(program[1], "isDepth"), 1);
			glUniform1i(programLocations[MD_PROGRAM_ENABLENORMALS], 0);
			glUniform1i(programLocations[MD_PROGRAM_ENABLETEXTURES], 1);
			glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
			
			MDMatrixTranslate(&model, 1.75, 0, 0);
			glUniformMatrix4fv(programLocations[MD_PROGRAM_MODELVIEWPROJECTION], 1, NO, (projectionMatrix * model).data);
			glUniform1i(glGetUniformLocation(program[1], "isDepth"), 2);
			glUniform1i(programLocations[MD_PROGRAM_ENABLENORMALS], 0);
			glUniform1i(programLocations[MD_PROGRAM_ENABLETEXTURES], 1);
			glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
			
			MDMatrixTranslate(&model, 1.75, 0, 0);
			glUniformMatrix4fv(programLocations[MD_PROGRAM_MODELVIEWPROJECTION], 1, NO, (projectionMatrix * model).data);
			glUniform1i(programLocations[MD_PROGRAM_ENABLENORMALS], 0);
			glUniform1i(programLocations[MD_PROGRAM_ENABLETEXTURES], 1);
			glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
			
			glUniform1i(glGetUniformLocation(program[1], "isCube"), 0);
			glUniform1i(glGetUniformLocation(program[1], "isDepth"), 1);
			glActiveTexture(GL_TEXTURE0);
		}
		else
		{
			glUniformMatrix4fv(programLocations[MD_PROGRAM_MODELVIEWPROJECTION], 1, NO, (projectionMatrix).data);
			glUniform1i(programLocations[MD_PROGRAM_ENABLENORMALS], 0);
			glUniform1i(programLocations[MD_PROGRAM_ENABLETEXTURES], 1);
			glUniform1i(programLocations[MD_PROGRAM_TEXTURE], 0);
			glBindTexture(GL_TEXTURE_2D, shadowTexture[y][1]);
			glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
		}
		
		glBindVertexArray(0);
		
		glDeleteBuffers(2, &textureVAO[1]);
		glDeleteVertexArrays(1, &textureVAO[0]);
	}
	glUniform1i(glGetUniformLocation(program[1], "isDepth"), 0);
	//glUniform1i(glGetUniformLocation(program[1], "isCube"), 0);*/
	
	// Picking image
	/*{
		// Draw texture in bottom left
		unsigned int textureVAO[3];
		glGenVertexArrays(1, &textureVAO[0]);
		glBindVertexArray(textureVAO[0]);
		
		float texCoords[8] = { 0, 0, 1, 0, 0, 1, 1, 1 };
		float verts[12] = { -1.5, -1.1, -3, 0, -1.1, -3, -1.5, 0, -3, 0, 0, -3 };
		
		glGenBuffers(1, &textureVAO[1]);
		glGenBuffers(1, &textureVAO[1]);
		glBindBuffer(GL_ARRAY_BUFFER, textureVAO[1]);
		glBufferData(GL_ARRAY_BUFFER, 4 * 3 * sizeof(float), verts, GL_STATIC_DRAW);
		glVertexAttribPointer(0, 3, GL_FLOAT, NO, 0, NULL);
		glEnableVertexAttribArray(0);
		
		glGenBuffers(1, &textureVAO[2]);
		glGenBuffers(1, &textureVAO[2]);
		glBindBuffer(GL_ARRAY_BUFFER, textureVAO[2]);
		glBufferData(GL_ARRAY_BUFFER, 4 * 2 * sizeof(float), texCoords, GL_STATIC_DRAW);
		glVertexAttribPointer(3, 2, GL_FLOAT, NO, 0, NULL);
		glEnableVertexAttribArray(3);
		
		glVertexAttrib4f(1, 1, 1, 1, 1);
		glVertexAttrib3f(2, 0, 0, 0);
		
		glUniformMatrix4fv(programLocations[MD_PROGRAM_MODELVIEWPROJECTION], 1, NO, (projectionMatrix).data);
		glUniform1i(programLocations[MD_PROGRAM_ENABLENORMALS], 0);
		glUniform1i(programLocations[MD_PROGRAM_ENABLETEXTURES], 1);
		glUniform1i(programLocations[MD_PROGRAM_TEXTURE], 0);
		glActiveTexture(GL_TEXTURE0);
		glBindTexture(GL_TEXTURE_2D, pickingBuffer[1]);
		glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
		
		glBindVertexArray(0);
		
		glDeleteBuffers(2, &textureVAO[1]);
		glDeleteVertexArrays(1, &textureVAO[0]);
	}*/
	
	[ self writeString:[ NSString stringWithFormat:@"%i", truefps ] textColor:[ NSColor yellowColor ] boxColor:[ NSColor clearColor ] borderColor:[ NSColor clearColor ] atLocation:NSMakePoint(0, 0) withSize:12 withFontName:@"Helvetica" rotation:0 center:NO ];
	
	if (commandFlag & SHAPE)
	{
		[ self writeString:@"Click and drag for width and depth."  textColor:[ NSColor yellowColor ] boxColor:[ NSColor clearColor ] borderColor:[ NSColor clearColor ] atLocation:NSMakePoint(resolution.width / 2, resolution.height * 0.95) withSize:12 withFontName:@"Helvetica" rotation:0 center:YES ];
	}
	else if (commandFlag & SHAPE2)
	{
		[ self writeString:@"Drag up for height."  textColor:[ NSColor yellowColor ] boxColor:[ NSColor clearColor ] borderColor:[ NSColor clearColor ] atLocation:NSMakePoint(resolution.width / 2, resolution.height * 0.95) withSize:12 withFontName:@"Helvetica" rotation:0 center:YES ];
	}
	
	[ [ self openGLContext ] flushBuffer ];
	
	for (int z = 0; z < [ views count ]; z++)
		[ views[z] finishDraw ];
	
	[ self doTranslations ];
	
	fpsCounter++;
}

- (void) loadNewTextures
{
	for (unsigned long z = 0; z < [ instances count ]; z++)
	{
		MDInstance* obj = instances[z];
		for (unsigned long y = 0; y < [ obj numberOfMeshes ]; y++)
		{
			MDMesh* mesh = [ obj meshAtIndex:y ];
			for (unsigned long q = 0; q < [ mesh numberOfTextures ]; q++)
			{
				MDTexture* texture = [ mesh textureAtIndex:q ];
				if ([ [ texture path ] length ] != 0 && ![ texture textureLoaded ])
				{
					BOOL did = FALSE;
					for (unsigned long t = 0; t < loadedImages.size(); t++)
					{
						if ([ [ texture path ] isEqualToString:loadedImages[t].path ])
						{
							[ texture setTextureLoaded:YES ];
							[ texture setTexture:loadedImages[t].textNum ];
							did = TRUE;
							break;
						}
					}
					if (!did)
					{
						unsigned int image = 0;
						LoadImage([ [ texture path ] UTF8String ], &image, 0);
						[ texture setTextureLoaded:YES ];
						[ texture setTexture:image ];
						ImageWithName imageName;
						memset(&imageName, 0, sizeof(imageName));
						imageName.path = [ [ NSString alloc ] initWithString:[ texture path ] ];
						imageName.textNum = image;
						loadedImages.push_back(imageName);
					}
				}
			}
		}
	}
}

- (void) resetPixelFormat
{
	// Doesn't work for some reason
	NSOpenGLPixelFormat* format = [ self createPixelFormat:[ self frame ] ];
	[ self setPixelFormat:format ];
}

/*
 * Cleanup
 */
- (void) dealloc
{
	for (unsigned long z = 0; z < sizeof(program) / sizeof(unsigned int); z++)
	{
		if (program[z])
		{
			if (vertexShader[z])
			{
				glDetachShader(program[z], vertexShader[z]);
				glDeleteShader(vertexShader[z]);
				vertexShader[z] = 0;
			}
			if (fragmentShader[z])
			{
				glDetachShader(program[z], fragmentShader[z]);
				glDeleteShader(fragmentShader[z]);
				fragmentShader[z] = 0;
			}
			glDeleteProgram(program[z]);
			program[z] = 0;
		}
	}
	if (fpsTimer)
	{
		[ fpsTimer invalidate ];
		fpsTimer = nil;
	}
	for (unsigned long z = 0; z < models.size(); z++)
	{
		if (models[z].list != 0)
			glDeleteLists(models[z].list, 1);
	}
	for (unsigned long z = 0; z < loadedImages.size(); z++)
		ReleaseImage(&loadedImages[z].textNum);
	loadedImages.clear();
	
	for (int y = 0; y < 3; y++)
	{
		for (int z = 0; z < shadowTexture[y].size(); z++)
		{
			if (shadowTexture[y][z])
				ReleaseImage(&shadowTexture[y][z]);
		}
		shadowTexture[y].clear();
		for (unsigned long z = 0; z < shadowFBO[y].size(); z++)
		{
			if (shadowFBO[y][z] && glIsFramebuffer(shadowFBO[y][z]))
				glDeleteFramebuffers(1, &shadowFBO[y][z]);
		}
		shadowTexture[y].clear();
	}
	
	// Delete VAOs
	if (gridData[0])
	{
		if (glIsVertexArray(gridData[0]))
			glDeleteVertexArrays(1, &gridData[0]);
		gridData[0] = 0;
	}
	if (gridData[1])
	{
		if (glIsBuffer(gridData[1]))
			glDeleteBuffers(1, &gridData[1]);
		gridData[1] = 0;
	}
	if (cubeData[0])
	{
		if (glIsVertexArray(cubeData[0]))
			glDeleteVertexArrays(1, &cubeData[0]);
		cubeData[0] = 0;
	}
	if (cubeData[1])
	{
		if (glIsBuffer(cubeData[1]))
			glDeleteBuffers(1, &cubeData[1]);
		cubeData[1] = 0;
	}
	if (cubeData[2])
	{
		if (glIsBuffer(cubeData[2]))
			glDeleteBuffers(1, &cubeData[2]);
		cubeData[2] = 0;
	}
	if (boxData[0])
	{
		if (glIsVertexArray(boxData[0]))
			glDeleteVertexArrays(1, &boxData[0]);
		boxData[0] = 0;
	}
	if (boxData[1])
	{
		if (glIsBuffer(boxData[1]))
			glDeleteBuffers(1, &boxData[1]);
		boxData[1] = 0;
	}
	if (projectData[0])
	{
		if (glIsVertexArray(projectData[0]))
			glDeleteVertexArrays(1, &projectData[0]);
		projectData[0] = 0;
	}
	if (projectData[1])
	{
		if (glIsBuffer(projectData[1]))
			glDeleteBuffers(1, &projectData[1]);
		projectData[1] = 0;
	}
	if (skyboxData[0])
	{
		if (glIsVertexArray(skyboxData[0]))
			glDeleteVertexArrays(1, &skyboxData[0]);
		skyboxData[0] = 0;
	}
	if (skyboxData[1])
	{
		if (glIsBuffer(skyboxData[1]))
			glDeleteBuffers(1, &skyboxData[1]);
		skyboxData[1] = 0;
	}
	if (skyboxData[2])
	{
		if (glIsBuffer(skyboxData[2]))
			glDeleteBuffers(1, &skyboxData[2]);
		skyboxData[2] = 0;
	}
	
	// Delete framebuffers
	if (pickingBuffer[5])
	{
		if (glIsRenderbuffer(pickingBuffer[5]))
			glDeleteRenderbuffers(1, &pickingBuffer[5]);
		pickingBuffer[5] = 0;
	}
	if (pickingBuffer[4])
	{
		if (glIsRenderbuffer(pickingBuffer[4]))
			glDeleteRenderbuffers(1, &pickingBuffer[4]);
		pickingBuffer[4] = 0;
	}
	if (pickingBuffer[3])
	{
		if (glIsFramebuffer(pickingBuffer[3]))
			glDeleteFramebuffers(1, &pickingBuffer[3]);
		pickingBuffer[3] = 0;
	}
	if (pickingBuffer[2])
	{
		if (glIsRenderbuffer(pickingBuffer[2]))
			glDeleteRenderbuffers(1, &pickingBuffer[2]);
		pickingBuffer[2] = 0;
	}
	if (pickingBuffer[1])
	{
		if (glIsRenderbuffer(pickingBuffer[1]))
			glDeleteRenderbuffers(1, &pickingBuffer[1]);
		pickingBuffer[1] = 0;
	}
	if (pickingBuffer[0])
	{
		if (glIsFramebuffer(pickingBuffer[0]))
			glDeleteFramebuffers(1, &pickingBuffer[0]);
		pickingBuffer[0] = 0;
	}
	
	// Delete uniform locations
	if (programConstants)
	{
		free(programConstants);
		programConstants = NULL;
	}
	if (lightingLocations)
	{
		free(lightingLocations);
		lightingLocations = NULL;
	}
	if (programLocations)
	{
		free(programLocations);
		programLocations = NULL;
	}
	if (particleLocations)
	{
		free(particleLocations);
		particleLocations = NULL;
	}
	
	DeallocViews();
}

@end
