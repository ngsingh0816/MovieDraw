//
//  MDRotationBox.h
//  MovieDraw
//
//  Created by Neil on 5/16/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MDControl.h"
#import "3DText.h"

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

+ (id) mdRotationBox;
+ (id) mdRotationBoxWithFrame: (MDRect)rect background: (NSColor*)bkg;
- (BOOL) uses3D;
- (float) xrotation;
- (float) yrotation;
- (float) zrotation;
- (void) setXRotation: (float)xrot;
- (void) setYRotation: (float)yrot;
- (void) setZRotation: (float)zrot;
- (void) setXRotation: (float)xrot show:(BOOL)sh;
- (void) setYRotation: (float)yrot show:(BOOL)sh;
- (void) setZRotation: (float)zrot show:(BOOL)sh;
- (float) setX;
- (float) setY;
- (float) setZ;
- (BOOL) isShowing;
- (double) showPercent;
- (BOOL) isSpecial;
- (void) draw3DView:(MDMatrix)modelView projectionMatrix:(MDMatrix)projection;
- (void) setDesiredFPS:(unsigned int)fps;
- (unsigned int) desiredFPS;
- (void) setFrameDuration:(double)duration;
- (double) frameDuration;

@end
