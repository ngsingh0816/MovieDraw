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

/* GLView.h */

#import <Cocoa/Cocoa.h>
#import "MDGUI.h"
#import "MDTypes.h"

// MDRotationBox.h has its own copy
#define MD_PROGRAM_MODELVIEWPROJECTION		0
#define MD_PROGRAM_NORMALROTATION			1
#define MD_PROGRAM_GLOBALROTATION			2
#define MD_PROGRAM_ENABLENORMALS			3
#define MD_PROGRAM_ENABLETEXTURES			4
#define MD_PROGRAM_TEXTURE					5

// MDTypes.h has its own copy
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

typedef NS_ENUM(int, MDMove)
{
	MD_NONE = 0,
	MD_MOVE,
	MD_SIZE,
	MD_ROTATE,
	MD_ROTATE_ANGLE,
	//MD_ROTATE_POINT,
	MD_POINT,
	MD_POINT_MID,
	MD_POINT_NORMAL,
	MD_POINT_TEXTURE,
	MD_NORMAL,
	MD_SCENE,
	MD_LOOK,
	MD_SCENE_WHOLE,
	MD_POINT_MOVE,
	MD_POINT_COLOR,
	MD_OBJECT_COLOR,
	MD_OBJECT_COLOR_MULTIPLY,
	MD_SPECULAR_COLOR,
	MD_SHININESS,
	MD_CAMERA_MID,
	MD_CAMERA_LOOK,
	MD_CAMERA_OR,
	MD_LIGHT_AMBIENT,
	MD_LIGHT_DIFFUSE,
	MD_LIGHT_SPECULAR,
	MD_LIGHT_SPOT,
	MD_LIGHT_ATTENUATION,
	MD_LIGHT_SHADOW_ENABLE,
	MD_LIGHT_STATIC_ENABLE,
	MD_PARTICLE_START,
	MD_PARTICLE_END,
	MD_PARTICLE_NUMBER,
	MD_PARTICLE_SIZE,
	MD_PARTICLE_LIFE,
	MD_PARTICLE_VELOCITIES,
	MD_CURVE_POINT,
	MD_VISIBLE,
	MD_USE,
};
extern unsigned long moveIndex;

typedef NS_ENUM(int, MDVertex)
{
	MD_X = 0,
	MD_Y,
	MD_Z,
	MD_A,
};

typedef struct
{
	MDInstance* instance;
	MDObject* obj;
	NSString* name;
	unsigned int list;
} MDStructModel;

typedef struct
{
	NSString* path;
	unsigned int textNum;
} ImageWithName;
extern std::vector<ImageWithName> loadedImages;

extern MDVector3 translationPoint;
extern MDVector3 lookPoint;
extern NSMutableArray* oldObject;
extern MDMove move;
extern float targetMove;
extern float initialMove;
extern MDVertex moveVert;
extern MDPoint* targetPoint;
void InitColor(float red, float green, float blue, float alpha);
void SetColor(float red, float green, float blue, float alpha);
extern id oldOther;
extern std::vector<unsigned int> lengthTexts;
extern BOOL rebuildShaders;

@interface GLView : NSOpenGLView
{
	int colorBits, depthBits;
	int fpsCounter;
	int truefps;
	NSTimer* fpsTimer;
	std::vector<MDStructModel> models;
	NSPoint mousePoint;
	BOOL calculatingMove;
	double moveFrames;
	unsigned int vertexShader[3], fragmentShader[3], program[3];
	std::vector<unsigned int> shadowFBO[3], shadowTexture[3];
	
	MDMatrix projectionMatrix, modelViewMatrix;
	
	// Assorted VAOs
	unsigned int gridData[2];
	unsigned int cubeData[3];
	unsigned int boxData[2];
	unsigned int projectData[2];
	unsigned int skyboxData[3];
	
	// Framebuffers
	unsigned int pickingBuffer[6];
	
	// Uniform locations
	unsigned int* lightingLocations;
	unsigned int* programLocations;
	unsigned int* programConstants;
	unsigned int* particleLocations;
	
	// Timers
	double previousTime;
	double frameDuration;
}


+ (void) calculateAlphaObjects;
- (instancetype) initWithFrame:(NSRect)frame colorBits:(int)numColorBits
		   depthBits:(int)numDepthBits fullscreen:(BOOL)runFullScreen;
- (void) reshape;
- (void) drawRect:(NSRect)rect;
- (void) updateFPS;
- (void) loadModel:(NSString*)path;
- (void) writeString: (NSString*) str textColor: (NSColor*) text 
			boxColor: (NSColor*) box borderColor: (NSColor*) border
		  atLocation: (NSPoint) location withSize: (double) dsize 
		withFontName: (NSString*) fontName rotation:(float) rot center:(BOOL)align;
- (void) loadNewTextures;
- (void) updateSkybox;
@property (readonly) std::vector<MDStructModel> models;
- (void) resetPixelFormat;
- (void) dealloc;

@end
