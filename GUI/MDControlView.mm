//
//  MDView.m
//  MovieDraw
//
//  Created by MILAP on 7/9/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MDControlView.h"
#import "GLString.h"
#import "MDMatrix.h"
#import "MDMenu.h"

NSMutableArray* views = nil;
NSSize res = { 640, 480 };
NSSize resolution = { 640, 480 };
NSSize windowSize = { 640, 480 };
NSPoint origin = { 0, 0 };
NSOpenGLContext* loadingContext = nil;
unsigned int mdProgram = 0;
unsigned int* mdLocations = NULL;
MDMatrix modelViewMatrix, projectionMatrix;

MDSize MakeSize(double width, double height)
{
	MDSize size;
	memset(&size, 0, sizeof(size));
	size.width = width;
	size.height = height;
	size.depth = 0;
	return size;
}

MDSize MakeSize(double width, double height, double depth)
{
	MDSize size;
	memset(&size, 0, sizeof(size));
	size.width = width;
	size.height = height;
	size.depth = depth;
	return size;
}

MDRect MakeRect(double x, double y, double width, double height)
{
	MDRect rect;
	memset(&rect, 0, sizeof(rect));
	rect.x = x;
	rect.y = y;
	rect.z = 0;
	rect.width = width;
	rect.height = height;
	rect.depth = 0;
	return rect;
}

MDRect MakeRect(double x, double y, double z, double width, double height, double depth)
{
	MDRect rect;
	memset(&rect, 0, sizeof(rect));
	rect.x = x;
	rect.y = y;
	rect.z = z;
	rect.width = width;
	rect.height = height;
	rect.depth = depth;
	return rect;
}

id ViewForIdentity(NSString* iden)
{
	if (iden == nil)
		return nil;
	id view = nil;
	for (int z = 0; z < [ views count ]; z++)
	{
		if ([ [ (MDControlView*)[ views objectAtIndex:z ] identity ] isEqualToString:iden ])
		{
			view = [ views objectAtIndex:z ];
			break;
		}
	}
	return view;
}

extern BOOL MDRemoveView(id view)
{
	BOOL ret = [ views containsObject:view ];
	if (ret)
		[ views removeObject:view ];
	return ret;
}

double distanceB(NSPoint a, NSPoint b)
{
	return sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2));
}

void SetResolution(NSSize resolution)
{
	res = resolution;
}

void SetLoadingContext(NSOpenGLContext* context)
{
	loadingContext = [ context retain ];
}

void DeallocViews()
{
	if (views)
	{
		[ views release ];
		views = nil;
	}
	if (loadingContext)
	{
		[ loadingContext release ];
		loadingContext = nil;
	}
}

void MDSetGUIProgram(unsigned int program)
{
	mdProgram = program;
}

unsigned int MDGUIProgram()
{
	return mdProgram;
}

void MDSetGUIProgramLocations(unsigned int* locations)
{
	mdLocations = locations;
}

unsigned int* MDGUIProgramLocations()
{
	return mdLocations;
}

void MDSetGUIModelViewMatrix(MDMatrix modelView)
{
	modelViewMatrix = modelView;
}

MDMatrix MDGUIModelViewMatrix()
{
	return modelViewMatrix;
}

void MDSetGUIProjectionMatrix(MDMatrix projection)
{
	projectionMatrix = projection;
}

MDMatrix MDGUIProjectionMatrix()
{
	return projectionMatrix;
}

void MDDrawString(NSString* str, NSPoint position, NSColor* color, NSFont* font,
				  float rotation)
{
	MDDrawString(str, position, color, font, rotation, NSCenterTextAlignment);
}

MDRect MDDrawString(NSString* str, NSPoint position, NSColor* color, NSFont* font,
				  float rotation, NSTextAlignment align)
{
	if (font == nil)
		return MakeRect(0, 0, 0, 0);
	
	GLString* string = [ [ GLString alloc ] initWithString:str withAttributes:[ NSDictionary
			dictionaryWithObjectsAndKeys:color, NSForegroundColorAttributeName, font,
				NSFontAttributeName, nil ] withTextColor:color withBoxColor:
				[ NSColor clearColor ] withBorderColor:[ NSColor clearColor ] ];
	if (loadingContext)
		[ string setContext:loadingContext ];
	
	// Draw
	NSSize bounds = resolution;
	MDMatrix model = MDMatrixIdentity();
	MDMatrixScale(&model, 2.0 / bounds.width, -2.0 / bounds.height, 1.0);
	MDMatrixTranslate(&model, -bounds.width / 2.0, -bounds.height / 2.0, 0.0);
	
	NSSize frameSize = [ string frameSize ];
	position.x -= frameSize.width / 2;
	position.y += (frameSize.height / 2) + 1;
	position.y = bounds.height - position.y;
	
	MDMatrixTranslate(&model, position.x, position.y, 0);
	MDMatrixRotate(&model, 0, 0, 1, rotation);
	MDMatrixTranslate(&model, -position.x, -position.y, 0);
	MDRect rect = MakeRect(position.x, position.y,
								  frameSize.width, frameSize.height);
	if (align == NSLeftTextAlignment)
	{
		MDMatrixTranslate(&model, frameSize.width / 2.0, 0, 0);
		rect = MakeRect(frameSize.width + position.x, position.y,
						frameSize.width, frameSize.height);
	}
	else if (align == NSRightTextAlignment)
	{
		MDMatrixTranslate(&model, -frameSize.width / 2.0, 0, 0);
		rect = MakeRect(-frameSize.width + position.x, position.y,
						frameSize.width, frameSize.height);
	}
	[ string drawAtPoint:position ];
	
	glEnable(GL_DEPTH_TEST);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	
	// Cleanup
	[ string release ];
	return rect;
}

GLString* LoadString(NSString* str, NSColor* color, NSFont* font)
{
	if (!font)
		return nil;
	GLString* glStr = [ [ GLString alloc ] initWithString:str withAttributes:[ NSDictionary
			dictionaryWithObjectsAndKeys:color, NSForegroundColorAttributeName, font,
			NSFontAttributeName, nil ] withTextColor:color withBoxColor:
			  [ NSColor clearColor ] withBorderColor:[ NSColor clearColor ] ];
	if (loadingContext)
		[ glStr setContext:loadingContext ];
	return glStr;
}

MDRect DrawString(GLString* glStr, NSPoint position, NSTextAlignment align, float rotation)
{
	return DrawStringColor(glStr, position, align, rotation, [ NSColor colorWithCalibratedRed:1 green:1 blue:1 alpha:1 ]);
}

MDRect DrawStringColor(GLString* glStr, NSPoint position, NSTextAlignment align, float rotation, NSColor* color)
{
	if (glStr == nil)
		return MakeRect(0, 0, 0, 0);
	
	NSSize bounds = resolution;
	MDMatrix model = MDMatrixIdentity();
	MDMatrixScale(&model, 2.0 / bounds.width, -2.0 / bounds.height, 1.0);
	MDMatrixTranslate(&model, -bounds.width / 2.0, -bounds.height / 2.0, 0.0);
	NSColor* prev = [ glStr textColor ];
	[ glStr setTextColor:color ];
	glColor4f(1, 1, 1, 1);
	
	NSSize frameSize = [ glStr frameSize ];
	position.x -= frameSize.width / 2;
	position.y += (frameSize.height / 2) + 1;
	position.y = bounds.height - position.y;
	
	MDMatrixTranslate(&model, position.x, position.y, 0);
	MDMatrixRotate(&model, 0, 0, 1, rotation);
	MDMatrixTranslate(&model, -position.x, -position.y, 0);
	MDRect rect = MakeRect(position.x, position.y,
						   frameSize.width, frameSize.height);
	if (align == NSLeftTextAlignment)
	{
		MDMatrixTranslate(&model, frameSize.width / 2.0, 0, 0);
		rect = MakeRect(frameSize.width + position.x, position.y,
						frameSize.width, frameSize.height);
	}
	else if (align == NSRightTextAlignment)
	{
		MDMatrixTranslate(&model, -frameSize.width / 2.0, 0, 0);
		rect = MakeRect(-frameSize.width + position.x, position.y,
						frameSize.width, frameSize.height);
	}
	[ glStr drawAtPoint:position ];
	[ glStr setTextColor:prev ];
	
	glEnable(GL_DEPTH_TEST);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	
	return rect;
}

BOOL LoadImage(const char* data, unsigned int* image, unsigned long bytes)
{
	NSOpenGLContext* currentContext = [ NSOpenGLContext currentContext ];
	if (loadingContext)
		[ loadingContext makeCurrentContext ];
	
	BOOL success = FALSE;
	NSBitmapImageRep *theImage;
	long bitsPPixel, bytesPRow;
	int rowNum, destRowNum;
	
	if (bytes != 0)
	{
		NSData* d = [ NSData dataWithBytes:data length:bytes ];
		theImage = [ NSBitmapImageRep imageRepWithData:d ];
	}
	else
	{
		theImage = [ NSBitmapImageRep imageRepWithContentsOfFile:
					[ NSString stringWithUTF8String:data ] ];
	}
	if( theImage != nil )
	{
		bitsPPixel = [ theImage bitsPerPixel ];
		bytesPRow = [ theImage bytesPerRow ];
		GLenum texFormat = GL_RGB;
		GLenum totalBits = GL_UNSIGNED_BYTE;
		if(bitsPPixel == 24)        // No alpha channel
		{
			texFormat = GL_RGB;
			totalBits = GL_UNSIGNED_BYTE;
		}
		else if(bitsPPixel == 32)   // There is an alpha channel
		{
			texFormat = GL_RGBA;
			totalBits = GL_UNSIGNED_BYTE;
		}
		else if (bitsPPixel == 48)
		{
			texFormat = GL_RGB;
			totalBits = GL_UNSIGNED_SHORT;
		}
		else if (bitsPPixel == 64)
		{
			texFormat = GL_RGBA;
			totalBits = GL_UNSIGNED_SHORT;
		}
		else if (bitsPPixel == 96)
		{
			texFormat = GL_RGB;
			totalBits = GL_UNSIGNED_INT;
		}
		else if (bitsPPixel == 128)
		{
			texFormat = GL_RGBA;
			totalBits = GL_UNSIGNED_INT;
		}
		NSSize texSize = NSMakeSize([ theImage pixelsWide ], [ theImage pixelsHigh ]);
		unsigned char* tdata = (unsigned char*)malloc(bytesPRow * texSize.height);
		
		if (tdata)
		{
			success = TRUE;
			destRowNum = 0;
			for( rowNum = texSize.height - 1; rowNum >= 0;
				rowNum--, destRowNum++ )
			{
				// Copy the entire row in one shot
				memcpy(tdata + ( destRowNum * bytesPRow ),
					   [ theImage bitmapData ] + ( rowNum * bytesPRow ),
					   bytesPRow );
			}
		}
		
		unsigned int img = 0;
		glGenTextures(1, &img);
		(*image) = img;
		glBindTexture(GL_TEXTURE_2D, img);
		
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, texSize.width, texSize.height, 0, texFormat, totalBits, tdata);
		
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		
		free(tdata);
		tdata = NULL;
	}
	
	if (loadingContext)
		[ currentContext makeCurrentContext ];
	
	return success;
}

void ReleaseImage(unsigned int* image)
{
	NSOpenGLContext* currentContext = [ NSOpenGLContext currentContext ];
	if (loadingContext)
		[ loadingContext makeCurrentContext	];
	if (glIsTexture(*image))
		glDeleteTextures(1, image);
	if (loadingContext)
		[ currentContext makeCurrentContext ];
}

@implementation MDControlView

+ (id) mdView
{
	MDControlView* view = [ [ [ MDControlView alloc ] init ] autorelease ];
	return view;
}

+ (id) mdViewWithFrame: (MDRect)rect background: (NSColor*)bkg;
{
	MDControlView* view = [ [ [ MDControlView alloc ] initWithFrame:rect
							background:bkg ] autorelease ];
	return view;
}

- (id) init
{
	if ((self = [ super init ]))
	{
		frame = MakeRect(0, 0, 0, 0);
		for (int z = 0; z < 4; z++)
		{
			background[z] = [ [ NSColor colorWithDeviceRed:0 green:0 blue:0 alpha:1 ]
							 retain ];
		}
		subViews = [ [ NSMutableArray new ] retain ];
		if (!views)
			views = [ [ NSMutableArray alloc ] init ];
		[ views addObject:self ];
		enabled = TRUE;
		visible = TRUE;
		return self;
	}
	return nil;
}

- (id) initWithFrame: (MDRect)rect background: (NSColor*)bkg;
{
	if ((self = [ super init ]))
	{
		frame = rect;
		for (int z = 0; z < 4; z++)
		{
			background[z] = [ [ NSColor colorWithDeviceRed:[ bkg redComponent ] green:
							   [ bkg greenComponent ] blue:[ bkg blueComponent ] alpha:
							   [ bkg alphaComponent ] ] retain ];
		}
		subViews = [ [ NSMutableArray new ] retain ];
		if (!views)
			views = [ [ NSMutableArray alloc ] init ];
		[ views addObject:self ];
		enabled = TRUE;
		visible = TRUE;
		return self;
	}
	return nil;
}

- (id) initWithoutView
{
	if ((self = [ super init ]))
	{
		frame = MakeRect(0, 0, 0, 0);
		for (int z = 0; z < 4; z++)
		{
			background[z] = [ [ NSColor colorWithDeviceRed:0 green:0 blue:0 alpha:1 ]
							 retain ];
		}
		subViews = [ [ NSMutableArray new ] retain ];
		if (!views)
			views = [ [ NSMutableArray alloc ] init ];
		[ views addObject:self ];
		enabled = TRUE;
		visible = TRUE;
		return self;
	}
	return nil;
}

- (void) drawView
{
	if (!visible)
		return;
	
	if (!vao || updateVAO)
	{
		if (vao)
		{
			if (glIsVertexArray(vao))
				glDeleteVertexArrays(1, &vao);
			vao = 0;
		}
		for (unsigned int z = 0; z < 2; z++)
		{
			if (buffers[z])
			{
				if (glIsBuffer(buffers[z]))
					glDeleteBuffers(1, &buffers[z]);
				buffers[z] = 0;
			}
		}
		
		if (drawType == MD_CONTROL_ROUNDED)
		{
			float radius = 30;
			
			float square[42 * 3];
			square[0] = frame.x + frame.width / 2;
			square[1] = frame.y + frame.height / 2;
			square[2] = 0;
			
			for (long z = 0; z <= 9; z++)
			{
				float angle = (180 - (z * 10)) / 180.0 * M_PI;
				square[3 + (z * 3)] = cos(angle) * radius + frame.x + radius;
				square[4 + (z * 3)] = sin(angle) * radius + frame.y + frame.height - radius;
				square[5 + (z * 3)] = 0;
			}
			for (long z = 0; z <= 9; z++)
			{
				float angle = (90 - (z * 10)) / 180.0 * M_PI;
				square[33 + (z * 3)] = cos(angle) * radius + frame.x + frame.width - radius;
				square[34 + (z * 3)] = sin(angle) * radius + frame.y + frame.height - radius;
				square[35 + (z * 3)] = 0;
			}
			for (long z = 0; z <= 9; z++)
			{
				float angle = (0 - (z * 10)) / 180.0 * M_PI;
				square[63 + (z * 3)] = cos(angle) * radius + frame.x + frame.width - radius;
				square[64 + (z * 3)] = sin(angle) * radius + frame.y + radius;
				square[65 + (z * 3)] = 0;
			}
			for (long z = 0; z <= 9; z++)
			{
				float angle = (-90 - (z * 10)) / 180.0 * M_PI;
				square[93 + (z * 3)] = cos(angle) * radius + frame.x + radius;
				square[94 + (z * 3)] = sin(angle) * radius + frame.y + radius;
				square[95 + (z * 3)] = 0;
			}
			square[123] = frame.x;
			square[124] = frame.y + frame.height - radius;
			square[125] = 0;
			
			float square2[42 * 3];
			float stroke = 3;
			
			frame.x -= stroke;
			frame.y -= stroke;
			frame.width += stroke * 2;
			frame.height += stroke * 2;
			
			square2[0] = frame.x + frame.width / 2;
			square2[1] = frame.y + frame.height / 2;
			square2[2] = 0;
			
			for (long z = 0; z <= 9; z++)
			{
				float angle = (180 - (z * 10)) / 180.0 * M_PI;
				square2[3 + (z * 3)] = cos(angle) * radius + frame.x + radius;
				square2[4 + (z * 3)] = sin(angle) * radius + frame.y + frame.height - radius;
				square2[5 + (z * 3)] = 0;
			}
			for (long z = 0; z <= 9; z++)
			{
				float angle = (90 - (z * 10)) / 180.0 * M_PI;
				square2[33 + (z * 3)] = cos(angle) * radius + frame.x + frame.width - radius;
				square2[34 + (z * 3)] = sin(angle) * radius + frame.y + frame.height - radius;
				square2[35 + (z * 3)] = 0;
			}
			for (long z = 0; z <= 9; z++)
			{
				float angle = (0 - (z * 10)) / 180.0 * M_PI;
				square2[63 + (z * 3)] = cos(angle) * radius + frame.x + frame.width - radius;
				square2[64 + (z * 3)] = sin(angle) * radius + frame.y + radius;
				square2[65 + (z * 3)] = 0;
			}
			for (long z = 0; z <= 9; z++)
			{
				float angle = (-90 - (z * 10)) / 180.0 * M_PI;
				square2[93 + (z * 3)] = cos(angle) * radius + frame.x + radius;
				square2[94 + (z * 3)] = sin(angle) * radius + frame.y + radius;
				square2[95 + (z * 3)] = 0;
			}
			square2[123] = frame.x;
			square2[124] = frame.y + frame.height - radius;
			square2[125] = 0;
			
			frame.x += stroke;
			frame.y += stroke;
			frame.width -= stroke * 2;
			frame.height -= stroke * 2;
			
			float colors[42 * 4];
			for (int z = 0; z < 42; z++)
			{
				float add = !enabled ? -0.3 : 0.0;
				colors[(z * 4)] = [ background[0] redComponent ] + add;
				colors[(z * 4) + 1] = [ background[0] greenComponent ] + add;
				colors[(z * 4) + 2] = [ background[0] blueComponent ] + add;
				colors[(z * 4) + 3] = [ background[0] alphaComponent ];
			}
			
			glGenVertexArrays(1, &vao);
			glBindVertexArray(vao);
			
			glGenBuffers(1, &buffers[0]);
			glBindBuffer(GL_ARRAY_BUFFER, buffers[0]);
			glBufferData(GL_ARRAY_BUFFER, 42 * 3 * sizeof(float), square, GL_STATIC_DRAW);
			glVertexAttribPointer(0, 3, GL_FLOAT, NO, 0, NULL);
			glEnableVertexAttribArray(0);
			
			glGenBuffers(1, &buffers[1]);
			glBindBuffer(GL_ARRAY_BUFFER, buffers[1]);
			glBufferData(GL_ARRAY_BUFFER, 42 * 4 * sizeof(float), colors, GL_STATIC_DRAW);
			glVertexAttribPointer(1, 4, GL_FLOAT, NO, 0, NULL);
			glEnableVertexAttribArray(1);
			
			glGenVertexArrays(1, &strokeVao[0]);
			glBindVertexArray(strokeVao[0]);
			
			glGenBuffers(1, &strokeVao[1]);
			glBindBuffer(GL_ARRAY_BUFFER, strokeVao[1]);
			glBufferData(GL_ARRAY_BUFFER, 42 * 3 * sizeof(float), square2, GL_STATIC_DRAW);
			glVertexAttribPointer(0, 3, GL_FLOAT, NO, 0, NULL);
			glEnableVertexAttribArray(0);
		}
		else
		{
			float square[12];
			square[0] = frame.x;
			square[1] = frame.y;
			square[2] = 0;
			square[3] = frame.x + frame.width;
			square[4] = frame.y;
			square[5] = 0;
			square[6] = frame.x;
			square[7] = frame.y + frame.height;
			square[8] = 0;
			square[9] = frame.x + frame.width;
			square[10] = frame.y + frame.height;
			square[11] = 0;
			
			float colors[16];
			for (int z = 0; z < 4; z++)
			{
				float add = !enabled ? -0.3 : 0.0;
				colors[(z * 4)] = [ background[z] redComponent ] + add;
				colors[(z * 4) + 1] = [ background[z] greenComponent ] + add;
				colors[(z * 4) + 2] = [ background[z] blueComponent ] + add;
				colors[(z * 4) + 3] = [ background[z] alphaComponent ];
			}
			
			glGenVertexArrays(1, &vao);
			glBindVertexArray(vao);
			
			glGenBuffers(1, &buffers[0]);
			glBindBuffer(GL_ARRAY_BUFFER, buffers[0]);
			glBufferData(GL_ARRAY_BUFFER, 12 * sizeof(float), square, GL_STATIC_DRAW);
			glVertexAttribPointer(0, 3, GL_FLOAT, NO, 0, NULL);
			glEnableVertexAttribArray(0);
			
			glGenBuffers(1, &buffers[1]);
			glBindBuffer(GL_ARRAY_BUFFER, buffers[1]);
			glBufferData(GL_ARRAY_BUFFER, 16 * sizeof(float), colors, GL_STATIC_DRAW);
			glVertexAttribPointer(1, 4, GL_FLOAT, NO, 0, NULL);
			glEnableVertexAttribArray(1);
		}
		
		glBindVertexArray(0);
		
		updateVAO = FALSE;
	}
	
	glUniformMatrix4fv(MDGUIProgramLocations()[MD_PROGRAM_MODELVIEWPROJECTION], 1, NO, (MDGUIProjectionMatrix() * MDGUIModelViewMatrix()).data);
	glUniform1i(MDGUIProgramLocations()[MD_PROGRAM_ENABLETEXTURES], 0);
	glUniform1i(MDGUIProgramLocations()[MD_PROGRAM_ENABLENORMALS], 0);
	
	if (drawType == 1)
	{
		glBindVertexArray(strokeVao[0]);
		glVertexAttrib4d(1, 0, 0, 0, 1);	// Black stroke
		glDrawArrays(GL_TRIANGLE_FAN, 0, 42);
		glBindVertexArray(vao);
		glDrawArrays(GL_TRIANGLE_FAN, 0, 42);
	}
	else
	{
		glBindVertexArray(vao);
		glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	}
}

- (void) setFrame: (MDRect)rect
{
	frame = rect;
	updateVAO = TRUE;
}

- (void) setFrame:(MDRect)rect animate:(unsigned int)millisec tweening:(MDTween)tween
{
	[ self setFrame:rect ];
}

- (MDRect) frame
{
	return frame;
}

- (BOOL) keyDown
{
	return NO;
}

- (void) setBackground: (NSColor*)bkg atIndex:(unsigned int)index
{
	if (index >= 4)
		return;
	if (background[index])
		[ background[index] release ];
	background[index] = [ [ NSColor colorWithDeviceRed:[ bkg redComponent ] green:
				[ bkg greenComponent ] blue:[ bkg blueComponent ] alpha:
						   [ bkg alphaComponent ] ] retain ];
	updateVAO = TRUE;
}

- (void) setBackground:(NSColor*)bkg
{
	for (int z = 0; z < 4; z++)
		[ self setBackground:bkg atIndex:z ];
}

- (NSColor*) backgroundAtIndex:(unsigned int)index
{
	if (index >= 4)
		return [ NSColor colorWithDeviceRed:0 green:0 blue:0 alpha:0 ];
	return background[index];
}

- (NSMutableArray*) subViews
{
	return subViews;
}

- (id) parentView
{
	return parentView;
}

- (void) setParentView: (id) view
{
	if (parentView)
		[ parentView release ];
	parentView = [ view retain ];
}

- (BOOL) mouseDown
{
	if (!visible || !enabled)
		return FALSE;
	return realDown;
}

- (BOOL) realDown
{
	return NO;
}

- (void) setMouseDown: (BOOL) mouse
{
	realDown = mouse;
}

- (void) mouseNotDown
{
}

- (void) mouseDown: (NSEvent*)event
{
}

- (void) mouseMoved: (NSEvent*)event
{
}

- (void) mouseDragged: (NSEvent*)event
{
}

- (void) mouseUp: (NSEvent*)event
{
}

- (void) scrollWheel: (NSEvent*)event
{
}

- (BOOL) scrolled
{
	return NO;
}

- (void) keyDown: (NSEvent*)event
{
}

- (void) keyUp: (NSEvent*)event
{
}

- (void) setRed: (float) red
{
	for (int z = 0; z < 4; z++)
	{
		NSColor* backup = [ background[z] retain ];
		if (background[z])
			[ background[z] release ];
		background[z] = [ [ NSColor colorWithDeviceRed:red green:[ backup greenComponent ]
				blue:[ backup blueComponent ] alpha:[ backup alphaComponent ] ] retain ];
		[ backup release ];
	}
}

- (void) setGreen: (float)green
{
	for (int z = 0; z < 4; z++)
	{
		NSColor* backup = [ background[z] retain ];
		if (background[z])
			[ background[z] release ];
		background[z] = [ [ NSColor colorWithDeviceRed:[ backup redComponent ] green:green
				blue:[ backup blueComponent ] alpha:[ backup alphaComponent ] ] retain ];
		[ backup release ];
	}
}

- (void) setBlue: (float)blue
{
	for (int z = 0; z < 4; z++)
	{
		NSColor* backup = [ background[z] retain ];
		if (background[z])
			[ background[z] release ];
		background[z] = [ [ NSColor colorWithDeviceRed:[ backup redComponent ] green:
			[ backup greenComponent ] blue:blue alpha:[ backup alphaComponent ] ] retain ];
		[ backup release ];
	}
}

- (void) setAlpha: (float)alpha
{
	for (int z = 0; z < 4; z++)
	{
		NSColor* backup = [ background[z] retain ];
		if (background[z])
			[ background[z] release ];
		background[z] = [ [ NSColor colorWithDeviceRed:[ backup redComponent ] green:
			[ backup greenComponent ] blue:[ backup blueComponent ] alpha:alpha ] retain ];
		[ backup release ];
	}
}

- (BOOL) beforeDraw
{
	return FALSE;
}

- (void) finishDraw
{
}

- (void) alphaDraw
{
}

- (void) setDrawType:(int)type
{
	drawType = type;
}

- (int) drawType
{
	return drawType;
}

- (void) setEnabled: (BOOL)en
{
	enabled = en;
	for (int z = 0; z < [ subViews count ]; z++)
		[ [ subViews objectAtIndex:z ] setEnabled:en ];
}

- (BOOL) enabled
{
	return enabled;
}

- (void) setVisible: (BOOL)vis
{
	visible = vis;
	for (int z = 0; z < [ subViews count ]; z++)
		[ [ subViews objectAtIndex:z ] setVisible:vis ];
}

- (BOOL) visible
{
	return visible;
}

- (void) setIdentity: (NSString*) str
{
	if (iden)
		[ iden release ];
	iden = [ [ NSString alloc ] initWithString:str ];
}

- (NSString*) identity
{
	return iden;
}

- (BOOL) uses3D
{
	return NO;
}

- (void) dealloc
{
	for (int z = 0; z < 4; z++)
	{
		if (background[z])
		{
			[ background[z] release ];
			background[z] = nil;
		}
	}
	if (subViews)
	{
		[ subViews release ];
		subViews = nil;
	}
	if (parentView)
	{
		[ parentView release ];
		parentView = nil;
	}
	if (views && [ views containsObject:self ])
		[ views removeObject:self ];
	if ([ views count ] == 0)
	{
		[ views release ];
		views = nil;
	}
	if (iden)
	{
		[ iden release ];
		iden = nil;
	}
	if (vao)
	{
		if (glIsVertexArray(vao))
			glDeleteVertexArrays(1, &vao);
		vao = 0;
	}
	if (strokeVao[0])
	{
		if (glIsVertexArray(strokeVao[0]))
			glDeleteVertexArrays(1, &strokeVao[0]);
		strokeVao[0] = 0;
	}
	if (strokeVao[1])
	{
		if (glIsBuffer(strokeVao[1]))
			glDeleteBuffers(1, &strokeVao[1]);
		strokeVao[1] = 0;
	}
	for (unsigned int z = 0; z < 2; z++)
	{
		if (buffers[z])
		{
			if (glIsBuffer(buffers[z]))
				glDeleteBuffers(1, &buffers[z]);
			buffers[z] = 0;
		}
	}
	
	[ super dealloc ];
}

@end
