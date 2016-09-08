//
//  MDRotationBox.h
//  MovieDraw
//
//  Created by Neil on 5/16/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MDControl.h"

@interface MDRotationBox : MDControl {
    float rotationX;
	float toX;
	BOOL setX;
	double framesX;
	float startX;
	float rotationY;
	float toY;
	BOOL setY;
	double framesY;
	float startY;
	float toZ;
	BOOL setZ;
	double framesZ;
	float startZ;
	float rotationZ;
	float viewX, viewY;
	float fadealpha;
	NSPoint lastMouse;
	NSPoint downPoint;
	BOOL isSpecial;
	unsigned int vao2[4];
	unsigned int framebuffer;
	unsigned int framebufferTexture;
	unsigned int renderbuffer;
	NSSize oldRes;
	unsigned int desiredFPS;
	double frameDuration;
	
	// Strings
	std::vector<NSNumber*> sides;
	int side;
	
	BOOL picking;
}

+ (instancetype) mdRotationBox;
+ (instancetype) mdRotationBoxWithFrame: (MDRect)rect background: (NSColor*)bkg;
@property (readonly) BOOL uses3D;
@property (readonly) float xrotation;
@property (readonly) float yrotation;
@property (readonly) float zrotation;
- (void) setXRotation: (float)xrot;
- (void) setYRotation: (float)yrot;
- (void) setZRotation: (float)zrot;
- (void) setXRotation: (float)xrot show:(BOOL)sh;
- (void) setYRotation: (float)yrot show:(BOOL)sh;
- (void) setZRotation: (float)zrot show:(BOOL)sh;
@property (readonly) float setX;
@property (readonly) float setY;
@property (readonly) float setZ;
@property (getter=isShowing, readonly) BOOL showing;
@property (readonly) double showPercent;
@property (getter=isSpecial, readonly) BOOL special;
- (void) draw3DView:(MDMatrix)modelView projectionMatrix:(MDMatrix)projection;
@property  unsigned int desiredFPS;
@property  double frameDuration;

@end
