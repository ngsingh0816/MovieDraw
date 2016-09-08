//
//  GLWindow.h
//  MovieDraw
//
//  Created by Neil on 5/16/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GLView.h"
#import "GLString.h"

@interface GLWindow : NSWindow {
    GLView* glView;
	NSTimer* timer;
	id target;
	SEL action;
	SEL action2;
	unsigned int desiredFPS;
	
}

- (void) setUpGLView;
@property (readonly, strong) GLView *glView;
- (void) setGLView: (GLView*)view;
- (void) updateGL;
@property (assign) id target;
@property  SEL action;
@property  SEL action2;
@property  unsigned int FPS;

@end
