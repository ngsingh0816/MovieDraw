//
//  MDRotationBox.mm
//  MovieDraw
//
//  Created by Neil on 5/16/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MDRotationBox.h" 
#import "MDMatrix.h"
#undef  __gl_h_
#import <OpenGL/gl3.h>

#define MD_PROGRAM_MODELVIEWPROJECTION		0
#define MD_PROGRAM_NORMALROTATION			1
#define MD_PROGRAM_GLOBALROTATION			2
#define MD_PROGRAM_ENABLENORMALS			3
#define MD_PROGRAM_ENABLETEXTURES			4
#define MD_PROGRAM_TEXTURE					5

MDRect ToTwoD(MDRect threeD);
MDRect ToTwoD(MDRect threeD, double xrot, double yrot, double zrot);

MDRect ToTwoD(MDRect threeD)
{
	double totalX = CONSTANT(resolution.width / 2) * -threeD.z;
	double realX = (threeD.x + (totalX / 2)) / totalX * resolution.width;
	double realW = (threeD.width / totalX) * resolution.width;
	double totalY = CONSTANT(resolution.height / 2) * -threeD.z;
	double realY = (threeD.y + (totalY / 2)) / totalY * resolution.height;
	double realH = (threeD.height / totalY) * resolution.height;
	MDRect rect = MakeRect(realX + 1, realY - 2, realW, realH);
	return rect;
	
	/*
	 threeD.x = realx / resolution.width * totalX - (totalX / 2)
	 */
}

MDRect ToTwoD(MDRect threeD, double xrot, double yrot, double zrot)
{
	double rotX = fabs(yrot);
	while (rotX > 90)
		rotX -= 90;
	if (rotX > 45)
		rotX = 90 - rotX;
	double rotY = fabs(xrot);
	while (rotY > 90)
		rotY -= 90;
	if (rotY > 45)
		rotY = 90 - rotY;

	
	double totalX = CONSTANT(resolution.width / 2) * -threeD.z;
	double realX = ((threeD.x - ((sin(rotX * M_PI / 180) * threeD.width / 3.312))) + (totalX / 2)) / totalX * resolution.width;
	double realW = ((threeD.width + ((sin(rotX * M_PI / 180) * threeD.width / 1.656))) / totalX) * resolution.width;
	double totalY = CONSTANT(resolution.height / 2) * -threeD.z;
	double realY = ((threeD.y - ((sin(rotY * M_PI / 180) * threeD.height / 3.312))) + (totalY / 2)) / totalY * resolution.height;
	double realH = ((threeD.height + ((sin(rotY * M_PI / 180) * threeD.height / 1.656))) / totalY) * resolution.height;
	MDRect rect = MakeRect(realX + 1, realY - 2, realW, realH);
	return rect;
}

@implementation MDRotationBox

+ (id) mdRotationBox
{
	MDRotationBox* view = [ [ [ MDRotationBox alloc ] init ] autorelease ];
	return view;
}

+ (id) mdRotationBoxWithFrame: (MDRect)rect background: (NSColor*)bkg
{
	MDRotationBox* view = [ [ [ MDRotationBox alloc ] initWithFrame:rect background:bkg ] autorelease ];
	return view;
}

- (BOOL) uses3D
{
	return YES;
}

- (id)init
{
    self = [super init];
    if (self) {
        rotationX = 0;
		rotationY = 0;
		rotationZ = 0;
		fadealpha = 0.7;
		side = -1;
		
		sides.push_back([ MDText create2DText:[ [ [ NSAttributedString alloc ] initWithString:@" Front " attributes:[ NSDictionary dictionaryWithObject:[ NSFont systemFontOfSize:100 ] forKey:NSFontAttributeName ] ] autorelease ] removeBlack:YES ]);
		sides.push_back([ MDText create2DText:[ [ [ NSAttributedString alloc ] initWithString:@" Right " attributes:[ NSDictionary dictionaryWithObject:[ NSFont systemFontOfSize:100 ] forKey:NSFontAttributeName ] ] autorelease ] removeBlack:YES ]);
		sides.push_back([ MDText create2DText:[ [ [ NSAttributedString alloc ] initWithString:@" Back " attributes:[ NSDictionary dictionaryWithObject:[ NSFont systemFontOfSize:100 ] forKey:NSFontAttributeName ] ] autorelease ] removeBlack:YES ]);
		sides.push_back([ MDText create2DText:[ [ [ NSAttributedString alloc ] initWithString:@" Left " attributes:[ NSDictionary dictionaryWithObject:[ NSFont systemFontOfSize:100 ] forKey:NSFontAttributeName ] ] autorelease ] removeBlack:YES ]);
		sides.push_back([ MDText create2DText:[ [ [ NSAttributedString alloc ] initWithString:@" Bottom " attributes:[ NSDictionary dictionaryWithObject:[ NSFont systemFontOfSize:100 ] forKey:NSFontAttributeName ] ] autorelease ] removeBlack:YES ]);
		sides.push_back([ MDText create2DText:[ [ [ NSAttributedString alloc ] initWithString:@" Top " attributes:[ NSDictionary dictionaryWithObject:[ NSFont systemFontOfSize:100 ] forKey:NSFontAttributeName ] ] autorelease ] removeBlack:YES ]);
		
		[ self setContinuous:YES ];
    }
    
    return self;
}

- (id) initWithFrame:(MDRect)rect background:(NSColor *)bkg
{
	self = [ super initWithFrame:rect background:bkg ];
    if (self) {
		rotationX = 0;
		rotationY = 0;
		rotationZ = 0;
		fadealpha = 0.7;
		side = -1;
		
		sides.push_back([ MDText create2DText:[ [ [ NSAttributedString alloc ] initWithString:@" Front " attributes:[ NSDictionary dictionaryWithObject:[ NSFont systemFontOfSize:36 ] forKey:NSFontAttributeName ] ] autorelease ] removeBlack:YES ]);
		sides.push_back([ MDText create2DText:[ [ [ NSAttributedString alloc ] initWithString:@" Right " attributes:[ NSDictionary dictionaryWithObject:[ NSFont systemFontOfSize:36 ] forKey:NSFontAttributeName ] ] autorelease ] removeBlack:YES ]);
		sides.push_back([ MDText create2DText:[ [ [ NSAttributedString alloc ] initWithString:@" Back " attributes:[ NSDictionary dictionaryWithObject:[ NSFont systemFontOfSize:36 ] forKey:NSFontAttributeName ] ] autorelease ] removeBlack:YES ]);
		sides.push_back([ MDText create2DText:[ [ [ NSAttributedString alloc ] initWithString:@" Left " attributes:[ NSDictionary dictionaryWithObject:[ NSFont systemFontOfSize:36 ] forKey:NSFontAttributeName ] ] autorelease ] removeBlack:YES ]);
		sides.push_back([ MDText create2DText:[ [ [ NSAttributedString alloc ] initWithString:@" Bottom " attributes:[ NSDictionary dictionaryWithObject:[ NSFont systemFontOfSize:36 ] forKey:NSFontAttributeName ] ] autorelease ] removeBlack:YES ]);
		sides.push_back([ MDText create2DText:[ [ [ NSAttributedString alloc ] initWithString:@" Top " attributes:[ NSDictionary dictionaryWithObject:[ NSFont systemFontOfSize:36 ] forKey:NSFontAttributeName ] ] autorelease ] removeBlack:YES ]);
		
		[ self setContinuous:YES ];
    }
    
    return self;
}

- (int) pick: (NSPoint) point
{
	// Reset framebuffer if resolution changed
	if (!MDFloatCompare(oldRes.width, resolution.width) || !MDFloatCompare(oldRes.height, resolution.height))
	{
		if (framebufferTexture)
		{
			if (glIsTexture(framebufferTexture))
				glDeleteTextures(1, &framebufferTexture);
			framebufferTexture = 0;
		}
		if (renderbuffer)
		{
			if (glIsRenderbuffer(renderbuffer))
				glDeleteRenderbuffers(1, &renderbuffer);
			renderbuffer = 0;
		}
		if (framebuffer)
		{
			if (glIsFramebuffer(framebuffer))
				glDeleteFramebuffers(1, &framebuffer);
			framebuffer = 0;
		}
	}
	
	if (!framebuffer)
	{
		glGenRenderbuffers(1, &renderbuffer);
		glBindRenderbuffer(GL_RENDERBUFFER, renderbuffer);
		glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT, resolution.width, resolution.height);
		glBindRenderbuffer(GL_RENDERBUFFER, 0);
		
		glGenTextures(1, &framebufferTexture);
		glBindTexture(GL_TEXTURE_2D, framebufferTexture);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
		glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE );
		glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE );
		
		glTexImage2D( GL_TEXTURE_2D, 0, GL_RGB, resolution.width, resolution.height, 0, GL_RGB, GL_UNSIGNED_BYTE, NULL);
		oldRes = resolution;
		glBindTexture(GL_TEXTURE_2D, 0);
		
		glGenFramebuffers(1, &framebuffer);
		glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
		
		glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, framebufferTexture, 0);
		glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, renderbuffer);
		
		if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
		{
			NSLog(@"FBOs not supported.");
			return -1;
		}

		glBindFramebuffer(GL_FRAMEBUFFER, 0);
	}
		
	glUseProgram(program);
	glUniform1i(programLocations[MD_PROGRAM_ENABLENORMALS], 0);
	glUniform1i(programLocations[MD_PROGRAM_ENABLETEXTURES], 0);
	
	glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
	glEnable(GL_DEPTH_TEST);
	glDepthFunc(GL_LEQUAL);
	glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);
	
	MDMatrix projection = MDMatrixIdentity();
	MDMatrixSetPerspective(&projection, 45.0, resolution.width / resolution.height, 0.1, 100.0);
		
	for (int z = 0; z < 6; z++)
	{
		MDMatrix modelView = MDMatrixIdentity();
		MDMatrix rotation = MDMatrixIdentity();
		MDMatrixTranslate(&modelView, frame.x / ( 640.0 / windowSize.width), frame.y, frame.z - (frame.depth / 2));
		
		MDMatrixRotate(&rotation, 1, 0, 0, rotationX);
		MDMatrixRotate(&rotation, 0, 1, 0, rotationY);
		MDMatrixRotate(&rotation, 0, 0, 1, rotationZ);
		if (z < 4)
			MDMatrixRotate(&rotation, 0, 1, 0, z * 90);
		else
		{
			MDMatrixRotate(&rotation, 0, 1, 0, (z == 4) ? 90 : -90);
			MDMatrixRotate(&rotation, 1, 0, 0, (z == 4) ? 90 : -90);
			MDMatrixRotate(&rotation, 0, 0, 1, 90);
		}
		modelView *= rotation;
		glVertexAttrib4f(1, (z + 1) / 6.0, (z + 1) / 6.0, (z + 1) / 6.0, 1);
		glUniformMatrix4fv(programLocations[MD_PROGRAM_MODELVIEWPROJECTION], 1, NO, (projection * modelView).data);
		glBindVertexArray(vao[0]);
		glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	}
	float pixels;
	glReadPixels(point.x, point.y, 1, 1, GL_RED, GL_FLOAT, &pixels);
	glBindFramebuffer(GL_FRAMEBUFFER, 0);
	
	side = -1;
	if (pixels == 0)
		return 0;
	
	side = round(pixels * 6.0) - 1;
	
	return 1;
}

- (void) setFrame:(MDRect)rect animate:(unsigned int)millisec tweening:(MDTween)tween
{
	[ super setFrame:rect animate:millisec tweening:tween ];
	if (vao[0])
	{
		if (glIsVertexArray(vao[0]))
			glDeleteVertexArrays(1, &vao[0]);
		vao[0] = 0;
	}
	for (int z = 1; z < 4; z++)
	{
		if (vao[z])
		{
			if (glIsBuffer(vao[z]))
				glDeleteBuffers(1, &vao[z]);
			vao[z] = 0;
		}
	}
}

- (float) setX
{
	return toX;
}

- (float) setY
{
	return toY;
}

- (float) setZ
{
	return toZ;
}

- (void) setProgram:(unsigned int)pr withLocations:(unsigned int*)locations
{
	program = pr;
	programLocations = locations;
}

- (unsigned int) program
{
	return program;
}

- (unsigned int*) programLocations
{
	return programLocations;
}

- (void) draw3DView:(MDMatrix)modelView projectionMatrix:(MDMatrix)projection
{
	if (!visible)
		return;
	
	if (!vao[0])
	{
		glGenVertexArrays(1, &vao[0]);
		glBindVertexArray(vao[0]);
		
		float normals[12] = { 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1 };
		float texCoords[8] = { 0, 0, 1, 0, 0, 1, 1, 1 };
		float verts[12] = { float(-frame.width / 2), float(-frame.height / 2), (float)(frame.depth / 2),
			float(frame.width / 2), float(-frame.height / 2), float(frame.depth / 2),
			float(-frame.width / 2), float(frame.height / 2), float(frame.depth / 2),
			float(frame.width / 2), float(frame.height / 2), float(frame.depth / 2), };
		
		glGenBuffers(1, &vao[1]);
		glGenBuffers(1, &vao[1]);
		glBindBuffer(GL_ARRAY_BUFFER, vao[1]);
		glBufferData(GL_ARRAY_BUFFER, 4 * 3 * sizeof(float), verts, GL_STATIC_DRAW);
		glVertexAttribPointer(0, 3, GL_FLOAT, NO, 0, NULL);
		glEnableVertexAttribArray(0);
		
		glGenBuffers(1, &vao[2]);
		glGenBuffers(1, &vao[2]);
		glBindBuffer(GL_ARRAY_BUFFER, vao[2]);
		glBufferData(GL_ARRAY_BUFFER, 4 * 3 * sizeof(float), normals, GL_STATIC_DRAW);
		glVertexAttribPointer(2, 3, GL_FLOAT, NO, 0, NULL);
		glEnableVertexAttribArray(2);
		
		glGenBuffers(1, &vao[3]);
		glGenBuffers(1, &vao[3]);
		glBindBuffer(GL_ARRAY_BUFFER, vao[3]);
		glBufferData(GL_ARRAY_BUFFER, 4 * 2 * sizeof(float), texCoords, GL_STATIC_DRAW);
		glVertexAttribPointer(3, 2, GL_FLOAT, NO, 0, NULL);
		glEnableVertexAttribArray(3);
		
		glBindVertexArray(0);
	}
	
	for (int z = 0; z < 6; z++)
	{
		modelView = MDMatrixIdentity();
		MDMatrix rotation = MDMatrixIdentity();
		MDMatrixTranslate(&modelView, frame.x / ( 640.0 / windowSize.width), frame.y, frame.z - (frame.depth / 2));
		
		MDMatrixRotate(&rotation, 1, 0, 0, rotationX);
		MDMatrixRotate(&rotation, 0, 1, 0, rotationY);
		MDMatrixRotate(&rotation, 0, 0, 1, rotationZ);
		if (z < 4)
			MDMatrixRotate(&rotation, 0, 1, 0, z * 90);
		else
		{
			MDMatrixRotate(&rotation, 0, 1, 0, (z == 4) ? 90 : -90);
			MDMatrixRotate(&rotation, 1, 0, 0, (z == 4) ? 90 : -90);
			MDMatrixRotate(&rotation, 0, 0, 1, 90);
		}
		modelView *= rotation;
		if (side == z)
			glVertexAttrib4f(1, 0.7, 0.7, 0.2, 1);
		else
			glVertexAttrib4f(1, 0.5, 0.5, 0.5, 1);
		for (int q = 0; q < 2; q++)
		{				
			glUniformMatrix4fv(programLocations[MD_PROGRAM_NORMALROTATION], 1, NO, rotation.data);
			glUniformMatrix4fv(programLocations[MD_PROGRAM_MODELVIEWPROJECTION], 1, NO, (projection * modelView).data);
			glUniform1i(programLocations[MD_PROGRAM_ENABLETEXTURES], (q == 1));
			if (q == 1)
			{
				glUniform1i(programLocations[MD_PROGRAM_TEXTURE], 0);
				glBindTexture(GL_TEXTURE_2D, [ sides[z] unsignedIntValue ]);
			}
			
			glBindVertexArray(vao[0]);
			glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
		}
	}
	
	if (picking)
		return;
	
	if (fadealpha < -0.3)
	{
		fadealpha += 0.05;
		if (fadealpha > -0.3)
			fadealpha = -0.3;
	}
	else if (fadealpha > 0.2)
	{
		fadealpha += 0.05;
		if (fadealpha > 0.8)
			fadealpha = 0.8;
	}
	
	if (setX || setY || setZ)
		[ self pick:lastMouse ];
	
	const float pressure = (desiredFPS + 1) * (desiredFPS + 2) / 12.0 / desiredFPS;
	const double val = 21.0 / 20.0 / desiredFPS / pressure * frameDuration / 1000.0;
	if (setX)
	{
		float value = framesX;
		if (value > desiredFPS / 2)
			value = desiredFPS - value;
		
		rotationX += (toX - startX) * val * value * value;
		framesX += frameDuration * desiredFPS / 1000.0;
		if (framesX >= desiredFPS)
		{
			setX = FALSE;
			rotationX = toX;
			while (rotationX >= 360)
				rotationX -= 360;
		}
	}
	if (setY)
	{
		float value = framesY;
		if (value > desiredFPS / 2)
			value = desiredFPS - value;
		rotationY += (toY - startY) * val * value * value;
		framesY += frameDuration * desiredFPS / 1000.0;
		if (framesY >= desiredFPS)
		{
			setY = FALSE;
			rotationY = toY;
			while (rotationY >= 360)
				rotationY -= 360;
		}
	}
	if (setZ)
	{
		float value = framesZ;
		if (value > desiredFPS / 2)
			value = desiredFPS - value;
		rotationZ += (toZ - startZ) * val * value * value;
		framesZ += frameDuration * desiredFPS / 1000.0;
		if (framesZ >= desiredFPS)
		{
			setZ = FALSE;
			rotationZ = toZ;
			while (rotationZ >= 360)
				rotationZ -= 360;
		}
	}
}

- (BOOL) isShowing
{
	if (setX || setY || setZ)
		return YES;
	return NO;
}

- (double) showPercent
{
	return framesX / 60.0;
}

- (BOOL) isSpecial
{
	return isSpecial;
}

- (void) mouseDown:(NSEvent *)event
{
	NSPoint point = [ event locationInWindow ];
	point.x -= origin.x;
	point.y -= origin.y;
	point.x *= resolution.width / windowSize.width;
	point.y *= resolution.height / windowSize.height;
	lastMouse = point;
	downPoint = point;
	
	if ([ self pick:point ] != 0)
	{
		up = FALSE;
		down = TRUE;
		realDown = TRUE;
		//fadealpha = 0.2;
	}
	if (target && continuous && [ target respondsToSelector:action ])
		[ target performSelector:action withObject:self ];
	
	setX = FALSE;
	setY = FALSE;
}

- (void) mouseDragged:(NSEvent *)event
{
	NSPoint point = [ event locationInWindow ];
	point.x -= origin.x;
	point.y -= origin.y;
	point.x *= resolution.width / windowSize.width;
	point.y *= resolution.height / windowSize.height;
	
	[ self pick:point ];
	if (down)
	{
		float changeX = point.x - lastMouse.x;
		float changeY = point.y - lastMouse.y;
		
		rotationX -= (TH(changeY, -frame.z) / frame.height) * 90;
		while (rotationX >= 360)
			rotationX -= 360;
		while (rotationX < 0)
			rotationX += 360;
		
		rotationY += (TW(changeX, -frame.z) / frame.width) * 90;
		while (rotationY >= 360)
			rotationY -= 360;
		while (rotationY < 0)
			rotationY += 360;
		
		lastMouse = point;
	
		if (target && continuous && [ target respondsToSelector:action ])
			[ target performSelector:action withObject:self ];
	}
}

- (void) mouseMoved:(NSEvent *)event
{
	[ super mouseMoved:event ];
	
	NSPoint point = [ event locationInWindow ];
	point.x -= origin.x;
	point.y -= origin.y;
	point.x *= resolution.width / windowSize.width;
	point.y *= resolution.height / windowSize.height;
	lastMouse = point;
	
	[ self pick:point ];
}

- (void) mouseUp:(NSEvent *)event
{
	NSPoint point = [ event locationInWindow ];
	point.x -= origin.x;
	point.y -= origin.y;
	point.x *= resolution.width / windowSize.width;
	point.y *= resolution.height / windowSize.height;
	lastMouse = point;
	
	[ self pick:point ];
	
	if (down)
	{
		//	fadealpha = -1;
		if (downPoint.x == point.x && downPoint.y == point.y && side != -1)
		{
			if (side < 4)
			{
				toX = 0;
				if (rotationX > 180)
					toX = 360;
				[ self setXRotation:toX show:YES ];
				toY = 360 - (side * 90);
				while (toY >= 360)
					toY -= 360;
				if (fabs(toY - rotationY) > fabs(360 + toY - rotationY))
					toY += 360;
				[ self setYRotation:toY show:YES ];
				[ self setZRotation:0 show:YES ];
			}
			else
			{
				toY = 0;
				if (rotationY > 180)
					toY = 360;
				[ self setYRotation:toY show:YES ];
				toX = (side == 4) ? -90 : 90;
				if (fabs(toX - rotationX) > fabs(360 + toX - rotationX))
					toX += 360;
				[ self setXRotation:toX show:YES ];
				[ self setZRotation:0 show:YES ];
			}
		}
		isSpecial = FALSE;
		if ([ event modifierFlags ] & NSAlternateKeyMask)
			isSpecial = TRUE;
	}
	
	
	lastMouse = point;
	up = TRUE;
	down = FALSE;
	realDown = FALSE;
	
	[ super mouseUp:event ];
}

- (float) xrotation
{
	return rotationX;
}

- (float) yrotation
{
	return rotationY;
}

- (float) zrotation
{
	return rotationZ;
}

- (void) setXRotation:(float)xrot
{
	[ self setXRotation:xrot show:NO ];
}

- (void) setYRotation:(float)yrot
{
	[ self setYRotation:yrot show:NO ];
}

- (void) setZRotation:(float)zrot
{
	[ self setZRotation:zrot show:NO ];
}

- (void) setXRotation: (float)xrot show:(BOOL)sh
{
	framesX = 0;
	startX = rotationX;
	toX = xrot;
	setX = sh;
	if (!sh)
	{
		rotationX = xrot;
		while (rotationX >= 360)
			rotationX -= 360;
		while (rotationX < 0)
			rotationX += 360;
	}
}

- (void) setYRotation: (float)yrot show:(BOOL)sh
{
	framesY = 0;
	startY = rotationY;
	toY = yrot;
	setY = sh;
	if (!sh)
	{	
		rotationY = yrot;
		while (rotationY >= 360)
			rotationY -= 360;
		while (rotationY < 0)
			rotationY += 360;
	}
}

- (void) setZRotation: (float)zrot show:(BOOL)sh
{
	framesZ = 0;
	startZ = rotationZ;
	toZ = zrot;
	setZ = sh;
	if (!sh)
	{
		rotationZ = zrot;
		while (rotationY >= 360)
			rotationY -= 360;
		while (rotationY < 0)
			rotationY += 360;
	}
}

- (void) setDesiredFPS:(unsigned int)fps
{
	desiredFPS = fps;
}

- (unsigned int) desiredFPS
{
	return desiredFPS;
}

- (void) setFrameDuration:(double)duration
{
	frameDuration = duration;
}

- (double) frameDuration
{
	return frameDuration;
}

- (void)dealloc
{
	if (framebufferTexture)
	{
		if (glIsTexture(framebufferTexture))
			glDeleteTextures(1, &framebufferTexture);
		framebufferTexture = 0;
	}
	if (renderbuffer)
	{
		if (glIsRenderbuffer(renderbuffer))
			glDeleteRenderbuffers(1, &renderbuffer);
		renderbuffer = 0;
	}
	if (framebuffer)
	{
		if (glIsFramebuffer(framebuffer))
			glDeleteTextures(1, &framebuffer);
		framebuffer = 0;
	}
	if (vao[0])
	{
		if (glIsVertexArray(vao[0]))
			glDeleteVertexArrays(1, &vao[0]);
		vao[0] = 0;
	}
	for (int z = 1; z < 4; z++)
	{
		if (vao[z])
		{
			if (glIsBuffer(vao[z]))
				glDeleteBuffers(1, &vao[z]);
			vao[z] = 0;
		}
	}
	for (int z = 0; z < 6; z++)
	{
		unsigned int value = [ sides[z] unsignedIntValue ];
		ReleaseImage(&value);
	}
    [super dealloc];
}

@end
