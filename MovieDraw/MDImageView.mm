//
//  MDImageView.m
//  GUI
//
//  Created by Neil Singh on 2/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MDImageView.h"

@implementation MDImageView

+ (MDImageView*) imageView
{
	return [ [ MDImageView alloc ] init ];
}

+ (MDImageView*) imageViewWithFrame: (MDRect)rect background:(NSColor*)bkg
{
	return [ [ MDImageView alloc ] initWithFrame:rect background:bkg ];
}

- (instancetype) init
{
	if (self = [ super init ])
	{
		image = [ [ NSString alloc ] init ];
		mouseDownColor = MD_IMAGEVIEW_DEFAULT_COLOR;
		strokeSize = 0;
	}
	return self;
}

- (instancetype) initWithFrame:(MDRect)rect background:(NSColor *)bkg
{
	if (self = [ super initWithFrame:rect background:bkg ])
	{
		image = [ [ NSString alloc ] init ];
		mouseDownColor = MD_IMAGEVIEW_DEFAULT_COLOR;
		strokeSize = 0;
	}
	return self;
}

- (void) setImage:(NSString*)img
{
	[ self setImage:img onThread:YES ];
}

- (void) setImageData:(NSData *)img
{
	[ self setImageData:img onThread:YES ];
}

- (void) loadImageThread
{
	@autoreleasepool {
		LoadImage([ image UTF8String ], &gImage, 0);
	}
}

- (void) setImage:(NSString*)img onThread:(BOOL)thread
{
	if (![ img hasPrefix:@"/" ])
		image = [ [ NSString alloc ] initWithFormat:@"%@/%@", [ [ NSBundle mainBundle ] resourcePath ], img ];
	else
		image = [ [ NSString alloc ] initWithString:img ];
	if (gImage)
		ReleaseImage(&gImage);
	if (!thread)
		LoadImage([ image UTF8String ], &gImage, 0);
	else
		[ NSThread detachNewThreadSelector:@selector(loadImageThread) toTarget:self withObject:nil ];
}

- (void) loadDataThread: (NSData*)data
{
	@autoreleasepool {
		LoadImage((const char*)[ data bytes ], &gImage, [ data length ]);
	}
}

- (void) setImageData:(NSData*)img onThread:(BOOL)thread
{
	image = nil;
	if (gImage)
		ReleaseImage(&gImage);
	if (!thread)
		LoadImage((const char*)[ img bytes ], &gImage, [ img length ]);
	else
	{
		@autoreleasepool {
			[ NSThread detachNewThreadSelector:@selector(loadDataThread:) toTarget:self withObject:img ];
		}
	}
}

- (NSString*) image
{
	return image;
}

- (unsigned int) glImage
{
	return gImage;
}

- (void) setMouseDownColor:(NSColor*)color
{
	mouseDownColor = color;
}

- (NSColor*) mouseDownColor
{
	return mouseDownColor;
}

- (void) drawView
{
	if (!visible)
		return;
	
	if (!vao[0] || updateVAO)
	{
		float square[12];
		square[0] = 0;	// frame.x
		square[1] = 0;	// frame.y
		square[2] = 0;
		square[3] = 0 + frame.width;
		square[4] = 0;	// frame.y
		square[5] = 0;
		square[6] = 0;	// frame.x
		square[7] = 0 + frame.height;
		square[8] = 0;
		square[9] = 0 + frame.width;
		square[10] = 0 + frame.height;
		square[11] = 0;
		
		float tex[8] = {
			0, 0,
			1, 0,
			0, 1,
			1, 1,
		};
		
		glGenVertexArrays(1, &vao[0]);
		glBindVertexArray(vao[0]);
		
		glGenBuffers(1, &vao[1]);
		glBindBuffer(GL_ARRAY_BUFFER, vao[1]);
		glBufferData(GL_ARRAY_BUFFER, 12 * sizeof(float), square, GL_STATIC_DRAW);
		glVertexAttribPointer(0, 3, GL_FLOAT, NO, 0, NULL);
		glEnableVertexAttribArray(0);
		
		glGenBuffers(1, &texBuffer);
		glBindBuffer(GL_ARRAY_BUFFER, texBuffer);
		glBufferData(GL_ARRAY_BUFFER, 8 * sizeof(float), tex, GL_STATIC_DRAW);
		glVertexAttribPointer(3, 2, GL_FLOAT, NO, 0, NULL);
		glEnableVertexAttribArray(3);
		
		glBindVertexArray(0);
		
		float square2[12];
		square2[0] = 0 - strokeSize;
		square2[1] = 0 - strokeSize;
		square2[2] = 0;
		square2[3] = 0 + frame.width + strokeSize;
		square2[4] = 0 - strokeSize;
		square2[5] = 0;
		square2[6] = 0 - strokeSize;
		square2[7] = 0 + frame.height + strokeSize;
		square2[8] = 0;
		square2[9] = 0 + frame.width + strokeSize;
		square2[10] = 0 + frame.height + strokeSize;
		square2[11] = 0;
		
		glGenVertexArrays(1, &strokeVao[0]);
		glBindVertexArray(strokeVao[0]);
		
		glGenBuffers(1, &strokeVao[1]);
		glBindBuffer(GL_ARRAY_BUFFER, strokeVao[1]);
		glBufferData(GL_ARRAY_BUFFER, 12 * sizeof(float), square2, GL_STATIC_DRAW);
		glVertexAttribPointer(0, 3, GL_FLOAT, NO, 0, NULL);
		glEnableVertexAttribArray(0);
		
		updateVAO = FALSE;
	}
	
	MDMatrix matrix = MDGUIModelViewMatrix();
	MDMatrixTranslate(&matrix, frame.x, frame.y, 0);
	glUniformMatrix4fv(MDGUIProgramLocations()[MD_PROGRAM_MODELVIEWPROJECTION], 1, NO, (MDGUIProjectionMatrix() * matrix).data);
	
	glUniform1i(MDGUIProgramLocations()[MD_PROGRAM_ENABLETEXTURES], 0);
	if (strokeSize > 0.01)
	{
		glBindVertexArray(strokeVao[0]);
		glVertexAttrib4d(1, [ strokeColor redComponent ], [ strokeColor greenComponent ], [ strokeColor	blueComponent ], [ strokeColor alphaComponent ]);
		glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	}
	
	glUniform1i(MDGUIProgramLocations()[MD_PROGRAM_TEXTURE], 0);
	glUniform1i(MDGUIProgramLocations()[MD_PROGRAM_ENABLETEXTURES], 1);
	
	glBindVertexArray(vao[0]);
	glActiveTexture(GL_TEXTURE0);
	glBindTexture(GL_TEXTURE_2D, gImage);
	float add = !enabled ? -0.3 : 0.0;
	glVertexAttrib4d(1, [ background redComponent ] + add, [ background greenComponent ] + add, [ background blueComponent ] + add, [ background alphaComponent ]);
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	glBindTexture(GL_TEXTURE_2D, 0);
	glUniform1i(MDGUIProgramLocations()[MD_PROGRAM_ENABLETEXTURES], 0);
	
	glUniformMatrix4fv(MDGUIProgramLocations()[MD_PROGRAM_MODELVIEWPROJECTION], 1, NO, (MDGUIProjectionMatrix() * MDGUIModelViewMatrix()).data);
}

- (void) setRotation:(float)rot
{
	rotation = rot;
}

- (float) rotation
{
	return rotation;
}

- (void) dealloc
{
	if (texBuffer)
	{
		if (glIsBuffer(texBuffer))
			glDeleteBuffers(1, &texBuffer);
		texBuffer = 0;
	}
}

@end
