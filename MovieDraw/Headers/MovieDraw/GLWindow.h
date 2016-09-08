/*
	GLWindow.h
	MovieDraw
 
	Copyright (c) 2013. All rights reserved.
*/

#import <Cocoa/Cocoa.h>
#import "GLView.h"
#import "GLString.h"

@interface GLWindow : NSWindow {
    GLView* glView;
	NSTimer* timer;
	id target;
	SEL action;					// Action called during updateGL
	unsigned int desiredFPS;
	unsigned int antialias;
}

// GLView
- (void) setUpGLView;
@property (readonly, strong) GLView *glView;
- (void) setGLView: (GLView*)view;
- (void) acceptResponder;

// Update GL
- (void) updateGL;					// Called every frame to draw the frame and interpret user input
@property (assign) id target;
@property  SEL action;

// FPS
@property  unsigned int FPS;

// Antialias
@property  unsigned int antialias;

@end
