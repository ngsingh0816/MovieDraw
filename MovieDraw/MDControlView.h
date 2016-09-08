/*
	MDControlView.h
	MovieDraw
 
	Copyright (c) 2013. All rights reserved.
*/

#import <Cocoa/Cocoa.h>
// Temp for errors
#undef  __gl3_h_
#import <OpenGL/gl.h>
#undef  __gl_h_
#import <OpenGL/gl3.h>
#include <stdlib.h>
#include <vector>
#import "MDMatrix.h"

#define MD_PROGRAM_MODELVIEWPROJECTION		0
#define MD_PROGRAM_NORMALROTATION			1
#define MD_PROGRAM_GLOBALROTATION			2
#define MD_PROGRAM_ENABLENORMALS			3
#define MD_PROGRAM_ENABLETEXTURES			4
#define MD_PROGRAM_TEXTURE					5

#define CONSTANT(x)	((x) * (1.656 / windowSize.height))
#define TX(x, z) (((x) / windowSize.width * CONSTANT(windowSize.width / 2) * (z)) - \
(CONSTANT(windowSize.width / 2) * (z) / 2)) 
#define TY(y, z) (-(((y) / windowSize.height * CONSTANT(windowSize.height / 2) * (z)) - \
(CONSTANT(windowSize.height / 2) * (z) / 2)))
#define TW(x, z) (((x) / windowSize.width * CONSTANT(windowSize.width / 2) * (z))) 
#define TH(x, z) (((x) / windowSize.height * CONSTANT(windowSize.height / 2) * (z)))
#define TYZ(y, z) (((y) / windowSize.height * 

#define UX(x, z) (((x) + (CONSTANT(windowSize.width / 2) * (z) / 2)) * windowSize.width / CONSTANT(windowSize.width / 2) / (z))
#define UY(y, z) (-(((y) + (CONSTANT(windowSize.height / 2) * (z) / 2)) * windowSize.height / CONSTANT(windowSize.height / 2) / (z)))
#define UW(x, z) ((x) * windowSize.width / CONSTANT(windowSize.width / 2) / (z))
#define UH(x, z) ((x) * windowSize.height / CONSTANT(windowSize.height / 2) / (z))

#define CONTROL_COLOR	[ NSColor colorWithCalibratedRed:0.2 green:0.5 blue:1 alpha:1 ]

@class GLString;
struct MDMatrix;

typedef NS_ENUM(int, MDTween)
{
	MDLinear,
};

typedef struct
{
	double width;
	double height;
	double depth;
} MDSize;

typedef struct
{
	double x;
	double y;
	double z;
	double width;
	double height;
	double depth;
} MDRect;

extern MDSize MakeSize(double width, double height);
extern MDSize MakeSize(double width, double height, double depth);
extern MDRect MakeRect(double x, double y, double width, double height);
extern MDRect MakeRect(double x, double y, double z, double width, double height, double depth);
double distanceB(NSPoint a, NSPoint b);

extern id ViewForIdentity(NSString* iden);
extern id SubViewForIdentity(NSString* iden, id view);
extern BOOL MDRemoveView(id view);

extern NSMutableArray* views;
extern NSSize resolution;
extern NSSize windowSize;
extern NSOpenGLContext* loadingContext;

void SetLoadingContext(NSOpenGLContext* context);
void DeallocViews();

void MDSetGUIProgram(unsigned int program);
unsigned int MDGUIProgram();
void MDSetGUIProgramLocations(unsigned int* locations);
unsigned int* MDGUIProgramLocations();
void MDSetGUIModelViewMatrix(MDMatrix modelView);
MDMatrix MDGUIModelViewMatrix();
void MDSetGUIProjectionMatrix(MDMatrix projection);
MDMatrix MDGUIProjectionMatrix();

void MDDrawString(NSString* str, NSPoint position, NSColor* color, NSFont* font,
				  float rotation);
MDRect MDDrawString(NSString* str, NSPoint position, NSColor* color, NSFont* font,
				  float rotation, NSTextAlignment align);
GLString* LoadString(NSString* str, NSColor* color, NSFont* font);
MDRect DrawString(GLString* glStr, NSPoint position, NSTextAlignment align, float rotation);
MDRect DrawStringColor(GLString* glStr, NSPoint position, NSTextAlignment align, float rotation, NSColor* color);

BOOL LoadImage(const char* data, unsigned int* image, unsigned long bytes);
void ReleaseImage(unsigned int* image);
void SetResolution(NSSize resolution);
extern NSSize res;
extern NSPoint origin;

void MDCreateRectVAO(MDRect frame, unsigned int* vao);	// 4 verticies (3 components, triangle strips)
void MDCreateRoundedRectVAO(MDRect frame, float radius, unsigned int* vao);	// 42 verticies (3 components, trianle fan)
void MDCreateStrokeVAO(MDRect frame, float radius, float strokeSize, unsigned int* strokeVao); // 82 verticies (3 components, triangle strips)
void MDDeleteVAO(unsigned int* vao);
BOOL MDPointInRadius(MDRect frame, float radius, NSPoint point);

@interface MDControlView : NSObject {
	MDRect frame;
	NSColor* background;
	NSColor* strokeColor;
	float radius;
	float strokeSize;
	NSMutableArray* subViews;
	id parentView;
	BOOL realDown;
	NSString* iden;
	BOOL enabled;
	BOOL visible;
	unsigned int vao[2];
	unsigned int strokeVao[2];
	BOOL updateVAO;
	int drawType;
}

// Creation
+ (id) mdView;
+ (id) mdViewWithFrame: (MDRect)rect background: (NSColor*)bkg;
- (instancetype) init;
- (instancetype) initWithFrame: (MDRect)rect background: (NSColor*)bkg;

// Drawing
- (void) drawView;
@property (readonly) BOOL beforeDraw;
- (void) finishDraw;
- (void) alphaDraw;
@property (readonly) BOOL uses3D;

// Frame
@property  MDRect frame;

// Colors
@property (copy) NSColor *background;
- (void) setRed: (float)red;
- (void) setGreen: (float)green;
- (void) setBlue: (float)blue;
- (void) setAlpha: (float)alpha;
@property (copy) NSColor *strokeColor;

// Drawing sizes
@property  float roundingRadius;
@property  float strokeSize;

// Subviews
@property (readonly, copy) NSMutableArray *subViews;
- (void) addSubView: (id)view;
@property (strong) id parentView;

// Event info
@property (readonly) BOOL keyDown;
@property  BOOL mouseDown;
@property (readonly) BOOL realDown;
- (void) mouseNotDown;
- (void) mouseDown: (NSEvent*)event;
- (void) mouseMoved: (NSEvent*)event;
- (void) mouseDragged: (NSEvent*)event;
- (void) mouseUp: (NSEvent*)event;
- (void) scrollWheel: (NSEvent*)event;
@property (readonly) BOOL scrolled;
- (void) keyDown: (NSEvent*)event;
- (void) keyUp: (NSEvent*)event;

// Identity
@property (copy) NSString *identity;

// Other options
@property  BOOL enabled;
@property  BOOL visible;

// Cleanup
- (void) dealloc;

@end
