/*
	MDControlView.h
	MovieDraw
 
	Copyright (c) 2013. All rights reserved.
*/

#import <Cocoa/Cocoa.h>
#undef  __gl_h_
#import <OpenGL/gl3.h>
#include <stdlib.h>
#include <vector>

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

typedef enum
{
	MDLinear,
} MDTween;

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

#define MD_CONTROL_SQUARE	0
#define MD_CONTROL_ROUNDED	1

@interface MDControlView : NSObject {
	MDRect frame;
	NSColor* background[4];
	NSMutableArray* subViews;
	id parentView;
	BOOL realDown;
	NSString* iden;
	BOOL enabled;
	BOOL visible;
	unsigned int vao;
	unsigned int buffers[2];
	unsigned int strokeVao[2];
	BOOL updateVAO;
	int drawType;
}

+ (id) mdView;
+ (id) mdViewWithFrame: (MDRect)rect background: (NSColor*)bkg;
- (id) init;
- (id) initWithFrame: (MDRect)rect background: (NSColor*)bkg;
- (id) initWithoutView;
- (void) drawView;
- (void) setFrame: (MDRect)rect;
- (void) setFrame:(MDRect)rect animate:(unsigned int)millisec tweening:(MDTween)tween;
- (MDRect) frame;
- (void) setBackground: (NSColor*)bkg atIndex:(unsigned int)index;
- (void) setBackground:(NSColor*)bkg;
- (NSColor*) backgroundAtIndex:(unsigned int)index;
- (NSMutableArray*) subViews;
- (id) parentView;
- (void) setParentView: (id) view;
- (void) dealloc;
- (BOOL) keyDown;
- (BOOL) mouseDown;
- (BOOL) realDown;
- (void) setMouseDown: (BOOL)mouse;
- (void) mouseNotDown;
- (void) mouseDown: (NSEvent*)event;
- (void) mouseMoved: (NSEvent*)event;
- (void) mouseDragged: (NSEvent*)event;
- (void) mouseUp: (NSEvent*)event;
- (void) scrollWheel: (NSEvent*)event;
- (BOOL) scrolled;
- (void) keyDown: (NSEvent*)event;
- (void) keyUp: (NSEvent*)event;
- (void) setRed: (float)red;
- (void) setGreen: (float)green;
- (void) setBlue: (float)blue;
- (void) setAlpha: (float)alpha;
- (void) setIdentity: (NSString*) str;
- (NSString*) identity;
- (void) setEnabled: (BOOL)en;
- (BOOL) enabled;
- (void) setVisible: (BOOL)vis;
- (BOOL) visible;
- (BOOL) beforeDraw;
- (void) finishDraw;
- (void) alphaDraw;
- (BOOL) uses3D;
- (void) setDrawType:(int)type;
- (int) drawType;

@end
