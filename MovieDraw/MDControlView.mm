//
//  MDView.m
//  MovieDraw
//
//  Created by MILAP on 7/9/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MDControlView.h"
#import "GLString.h"
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
		if ([ [ (MDControlView*)views[z] identity ] isEqualToString:iden ])
		{
			view = views[z];
			break;
		}
	}
	return view;
}

extern id SubViewForIdentity(NSString* iden, id view)
{
	if (view == nil)
		return nil;
	id ret = nil;
	for (int z = 0; z < [ [ view subViews ] count ]; z++)
	{
		if ([ [ (MDControlView*)[ view subViews ][z] identity ] isEqualToString:iden ])
		{
			ret = [ view subViews ][z];
			break;
		}
	}
	return ret;
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
	loadingContext = context;
}

void DeallocViews()
{
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
	
	GLString* string = [ [ GLString alloc ] initWithString:str withAttributes:@{NSForegroundColorAttributeName: color, NSFontAttributeName: font} withTextColor:color withBoxColor:
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
	MDMatrixTranslate(&model, position.x, position.y, 0);
	
	glUniformMatrix4fv(MDGUIProgramLocations()[MD_PROGRAM_MODELVIEWPROJECTION], 1, NO, model.data);
	glUniform1i(MDGUIProgramLocations()[MD_PROGRAM_ENABLENORMALS], 0);
	glUniform1i(MDGUIProgramLocations()[MD_PROGRAM_ENABLETEXTURES], 1);
	glUniform1i(MDGUIProgramLocations()[MD_PROGRAM_TEXTURE], 0);
	
	[ string drawAtPoint:position ];
	
	glEnable(GL_DEPTH_TEST);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	
	return rect;
}

GLString* LoadString(NSString* str, NSColor* color, NSFont* font)
{
	if (!font)
		return nil;
	GLString* glStr = [ [ GLString alloc ] initWithString:str withAttributes:@{NSForegroundColorAttributeName: color, NSFontAttributeName: font} withTextColor:color withBoxColor:
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
	MDMatrixTranslate(&model, position.x, position.y, 0);
	
	glUniformMatrix4fv(MDGUIProgramLocations()[MD_PROGRAM_MODELVIEWPROJECTION], 1, NO, model.data);
	glUniform1i(MDGUIProgramLocations()[MD_PROGRAM_ENABLENORMALS], 0);
	glUniform1i(MDGUIProgramLocations()[MD_PROGRAM_ENABLETEXTURES], 1);
	glUniform1i(MDGUIProgramLocations()[MD_PROGRAM_TEXTURE], 0);
	
	[ glStr drawAtPoint:position ];
	[ glStr setTextColor:prev ];
	
	glEnable(GL_DEPTH_TEST);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	
	glUniform1i(MDGUIProgramLocations()[MD_PROGRAM_ENABLETEXTURES], 0);
	glUniformMatrix4fv(MDGUIProgramLocations()[MD_PROGRAM_MODELVIEWPROJECTION], 1, NO, (MDGUIProjectionMatrix() * MDGUIModelViewMatrix()).data);
	
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
					@(data) ];
	}
	if( theImage != nil )
	{
		bitsPPixel = [ theImage bitsPerPixel ];
		bytesPRow = [ theImage bytesPerRow ];
		GLenum texFormat = GL_RGB;
		GLenum totalBits = GL_UNSIGNED_BYTE;
		if ([ [ theImage colorSpace ] colorSpaceModel ] == NSGrayColorSpaceModel)
		{
			texFormat = GL_LUMINANCE;
			if (bitsPPixel == 8)
				totalBits = GL_UNSIGNED_BYTE;
			else if (bitsPPixel == 16)
				totalBits = GL_UNSIGNED_SHORT;
			else if (bitsPPixel == 32)
				totalBits = GL_UNSIGNED_INT;
		}
		else
		{
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
		
		glTexImage2D(GL_TEXTURE_2D, 0, texFormat, texSize.width, texSize.height, 0, GL_RGBA, totalBits, tdata);
		
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

void MDCreateRectVAO(MDRect frame, unsigned int* vao)
{
	float square[12];
	square[0] = 0; // frame.x
	square[1] = 0; // frame.y
	square[2] = 0;
	square[3] = 0 + frame.width; // frame.x + frame.width
	square[4] = 0; // frame .y
	square[5] = 0;
	square[6] = 0; // frame.x
	square[7] = 0 + frame.height; // frame.y + frame.height
	square[8] = 0;
	square[9] = 0 + frame.width; // frame.x + frame.width
	square[10] = 0 + frame.height; // frame.y + frame.height
	square[11] = 0;
	glGenVertexArrays(1, &vao[0]);
	glBindVertexArray(vao[0]);
	
	glGenBuffers(1, &vao[1]);
	glBindBuffer(GL_ARRAY_BUFFER, vao[1]);
	glBufferData(GL_ARRAY_BUFFER, 12 * sizeof(float), square, GL_STATIC_DRAW);
	glVertexAttribPointer(0, 3, GL_FLOAT, NO, 0, NULL);
	glEnableVertexAttribArray(0);
	glBindVertexArray(0);
}

void MDCreateRoundedRectVAO(MDRect frame, float radius, unsigned int* vao)
{
	float square[42 * 3];
	square[0] = 0 + frame.width / 2;
	square[1] = 0 + frame.height / 2;
	square[2] = 0;
	
	for (long z = 0; z <= 9; z++)
	{
		float angle = (180 - (z * 10)) / 180.0 * M_PI;
		square[3 + (z * 3)] = cos(angle) * radius + 0 + radius;
		square[4 + (z * 3)] = sin(angle) * radius + 0 + frame.height - radius;
		square[5 + (z * 3)] = 0;
	}
	for (long z = 0; z <= 9; z++)
	{
		float angle = (90 - (z * 10)) / 180.0 * M_PI;
		square[33 + (z * 3)] = cos(angle) * radius + 0 + frame.width - radius;
		square[34 + (z * 3)] = sin(angle) * radius + 0 + frame.height - radius;
		square[35 + (z * 3)] = 0;
	}
	for (long z = 0; z <= 9; z++)
	{
		float angle = (0 - (z * 10)) / 180.0 * M_PI;
		square[63 + (z * 3)] = cos(angle) * radius + 0 + frame.width - radius;
		square[64 + (z * 3)] = sin(angle) * radius + 0 + radius;
		square[65 + (z * 3)] = 0;
	}
	for (long z = 0; z <= 9; z++)
	{
		float angle = (-90 - (z * 10)) / 180.0 * M_PI;
		square[93 + (z * 3)] = cos(angle) * radius + 0 + radius;
		square[94 + (z * 3)] = sin(angle) * radius + 0 + radius;
		square[95 + (z * 3)] = 0;
	}
	square[123] = 0;	// frame.x
	square[124] = 0 + frame.height - radius;
	square[125] = 0;
	
	glGenVertexArrays(1, &vao[0]);
	glBindVertexArray(vao[0]);
	
	glGenBuffers(1, &vao[1]);
	glBindBuffer(GL_ARRAY_BUFFER, vao[1]);
	glBufferData(GL_ARRAY_BUFFER, 42 * 3 * sizeof(float), square, GL_STATIC_DRAW);
	glVertexAttribPointer(0, 3, GL_FLOAT, NO, 0, NULL);
	glEnableVertexAttribArray(0);
}

void MDCreateStrokeVAO(MDRect frame, float radius, float strokeSize, unsigned int* strokeVao)
{
	float square2[41 * 3 * 2];
	
	for (long z = 0; z <= 9; z++)
	{
		float angle = (180 - (z * 10)) / 180.0 * M_PI;
		square2[0 + (z * 6)] = cos(angle) * radius + 0 + radius;
		square2[1 + (z * 6)] = sin(angle) * radius + 0 + frame.height - radius;
		square2[2 + (z * 6)] = 0;
	}
	for (long z = 0; z <= 9; z++)
	{
		float angle = (90 - (z * 10)) / 180.0 * M_PI;
		square2[60 + (z * 6)] = cos(angle) * radius + 0 + frame.width - radius;
		square2[61 + (z * 6)] = sin(angle) * radius + 0 + frame.height - radius;
		square2[62 + (z * 6)] = 0;
	}
	for (long z = 0; z <= 9; z++)
	{
		float angle = (0 - (z * 10)) / 180.0 * M_PI;
		square2[120 + (z * 6)] = cos(angle) * radius + 0 + frame.width - radius;
		square2[121 + (z * 6)] = sin(angle) * radius + 0 + radius;
		square2[122 + (z * 6)] = 0;
	}
	for (long z = 0; z <= 9; z++)
	{
		float angle = (-90 - (z * 10)) / 180.0 * M_PI;
		square2[180 + (z * 6)] = cos(angle) * radius + 0 + radius;
		square2[181 + (z * 6)] = sin(angle) * radius + 0 + radius;
		square2[182 + (z * 6)] = 0;
	}
	square2[240] = 0;	// frame.x
	square2[241] = 0 + frame.height - radius;
	square2[242] = 0;
	
	//frame.x -= strokeSize;
	//frame.y -= strokeSize;
	frame.width += strokeSize * 2;
	frame.height += strokeSize * 2;
	
	for (long z = 0; z <= 9; z++)
	{
		float angle = (180 - (z * 10)) / 180.0 * M_PI;
		square2[3 + (z * 6)] = cos(angle) * radius - strokeSize + radius;
		square2[4 + (z * 6)] = sin(angle) * radius - strokeSize + frame.height - radius;
		square2[5 + (z * 6)] = 0;
	}
	for (long z = 0; z <= 9; z++)
	{
		float angle = (90 - (z * 10)) / 180.0 * M_PI;
		square2[63 + (z * 6)] = cos(angle) * radius - strokeSize + frame.width - radius;
		square2[64 + (z * 6)] = sin(angle) * radius - strokeSize + frame.height - radius;
		square2[65 + (z * 6)] = 0;
	}
	for (long z = 0; z <= 9; z++)
	{
		float angle = (0 - (z * 10)) / 180.0 * M_PI;
		square2[123 + (z * 6)] = cos(angle) * radius - strokeSize + frame.width - radius;
		square2[124 + (z * 6)] = sin(angle) * radius - strokeSize + radius;
		square2[125 + (z * 6)] = 0;
	}
	for (long z = 0; z <= 9; z++)
	{
		float angle = (-90 - (z * 10)) / 180.0 * M_PI;
		square2[183 + (z * 6)] = cos(angle) * radius - strokeSize + radius;
		square2[184 + (z * 6)] = sin(angle) * radius - strokeSize + radius;
		square2[185 + (z * 6)] = 0;
	}
	square2[243] = -strokeSize;	// frame.x
	square2[244] = -strokeSize + frame.height - radius;
	square2[245] = 0;
	
	//frame.x += strokeSize;
	//frame.y += strokeSize;
	frame.width -= strokeSize * 2;
	frame.height -= strokeSize * 2;
	
	glGenVertexArrays(1, &strokeVao[0]);
	glBindVertexArray(strokeVao[0]);
	
	glGenBuffers(1, &strokeVao[1]);
	glBindBuffer(GL_ARRAY_BUFFER, strokeVao[1]);
	glBufferData(GL_ARRAY_BUFFER, 41 * 2 * 3 * sizeof(float), square2, GL_STATIC_DRAW);
	glVertexAttribPointer(0, 3, GL_FLOAT, NO, 0, NULL);
	glEnableVertexAttribArray(0);
}

void MDDeleteVAO(unsigned int* vao)
{
	if (vao[0])
	{
		if (glIsVertexArray(vao[0]))
			glDeleteVertexArrays(1, &vao[0]);
		vao[0] = 0;
	}
	if (vao[1])
	{
		if (glIsBuffer(vao[1]))
			glDeleteBuffers(1, &vao[1]);
		vao[1] = 0;
	}
}

BOOL MDPointInRadius(MDRect frame, float radius, NSPoint point)
{
	BOOL isDown = FALSE;
	if (point.x >= (frame.x + radius) && point.x <= (frame.x + frame.width - radius) &&
		point.y >= frame.y && point.y <= frame.y + frame.height)
		isDown = TRUE;
	else if (point.x >= frame.x && point.x <= frame.x + frame.width &&
			 point.y >= frame.y + radius && point.y <= frame.y + frame.height - radius)
		isDown = TRUE;
	else
	{
		NSPoint centers[4] = { NSMakePoint(frame.x + radius, frame.y + radius), NSMakePoint(frame.x + frame.width - radius, frame.y + radius), NSMakePoint(frame.x + frame.width - radius, frame.y + frame.height - radius), NSMakePoint(frame.x + radius, frame.y + frame.height - radius) };
		for (int z = 0; z < 4; z++)
		{
			float dist = distanceB(centers[z], point);
			if (dist <= radius)
			{
				isDown = TRUE;
				break;
			}
		}
		
	}
	return isDown;
}

@implementation MDControlView

+ (id) mdView
{
	MDControlView* view = [ [ MDControlView alloc ] init ];
	return view;
}

+ (id) mdViewWithFrame: (MDRect)rect background: (NSColor*)bkg;
{
	MDControlView* view = [ [ MDControlView alloc ] initWithFrame:rect background:bkg ];
	return view;
}

- (instancetype) init
{
	if ((self = [ super init ]))
	{
		frame = MakeRect(0, 0, 0, 0);
		background = [ NSColor colorWithDeviceRed:0 green:0 blue:0 alpha:1 ];
		strokeColor = [ NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:1 ];
		subViews = [ [ NSMutableArray alloc ] init ];
		if (!views)
			views = [ [ NSMutableArray alloc ] init ];
		[ views addObject:self ];
		enabled = TRUE;
		visible = TRUE;
		radius = 30;
		strokeSize = 3;
		return self;
	}
	return nil;
}

- (instancetype) initWithFrame: (MDRect)rect background: (NSColor*)bkg;
{
	if ((self = [ super init ]))
	{
		frame = rect;
		background = [ NSColor colorWithCalibratedRed:[ bkg redComponent ] green:[ bkg greenComponent ] blue:[ bkg blueComponent ] alpha:[ bkg alphaComponent ] ];
		strokeColor = [ NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:1 ];
		subViews = [ [ NSMutableArray alloc ] init ];
		if (!views)
			views = [ [ NSMutableArray alloc ] init ];
		[ views addObject:self ];
		enabled = TRUE;
		visible = TRUE;
		radius = 30;
		strokeSize = 3;
		return self;
	}
	return nil;
}

- (void) drawView
{
	if (!visible)
		return;
	
	if (!vao[0] || updateVAO)
	{
		MDDeleteVAO(vao);
		MDDeleteVAO(strokeVao);
					
		MDCreateRoundedRectVAO(frame, radius, vao);
		MDCreateStrokeVAO(frame, radius, strokeSize, strokeVao);
		
		glBindVertexArray(0);
		
		updateVAO = FALSE;
	}
	
	glUniform1i(MDGUIProgramLocations()[MD_PROGRAM_ENABLETEXTURES], 0);
	glUniform1i(MDGUIProgramLocations()[MD_PROGRAM_ENABLENORMALS], 0);
	
	MDMatrix matrix = MDGUIModelViewMatrix();
	MDMatrixTranslate(&matrix, frame.x, frame.y, 0);
	glUniformMatrix4fv(MDGUIProgramLocations()[MD_PROGRAM_MODELVIEWPROJECTION], 1, NO, (MDGUIProjectionMatrix() * matrix).data);
	
	if (strokeSize > 0.01)
	{
		glBindVertexArray(strokeVao[0]);
		glVertexAttrib4d(1, [ strokeColor redComponent ], [ strokeColor greenComponent ], [ strokeColor	blueComponent ], [ strokeColor alphaComponent ]);
		glDrawArrays(GL_TRIANGLE_STRIP, 0, 82);
	}
	
	glBindVertexArray(vao[0]);
	float add = !enabled ? -0.3 : 0.0;
	glVertexAttrib4d(1, [ background redComponent ] + add, [ background greenComponent ] + add, [ background blueComponent ] + add, [ background alphaComponent ]);
	glDrawArrays(GL_TRIANGLE_FAN, 0, 42);
	
	glUniformMatrix4fv(MDGUIProgramLocations()[MD_PROGRAM_MODELVIEWPROJECTION], 1, NO, (MDGUIProjectionMatrix() * MDGUIModelViewMatrix()).data);
	
	for (unsigned long z = 0; z < [ subViews count ]; z++)
		[ subViews[z] drawView ];
}

- (void) setFrame: (MDRect)rect
{
	// Does not support resizing yet
	float diffX = rect.x - frame.x;
	float diffY = rect.y - frame.y;
	float diffWidth = rect.width - frame.width;
	float diffHeight = rect.height - frame.height;
	
	for (unsigned long z = 0; z < [ subViews count ]; z++)
	{
		MDControlView* view = subViews[z];
		MDRect temp = [ view frame ];
		temp.x += diffX;
		temp.y += diffY;
		[ view setFrame:temp ];
	}
	
	frame = rect;
	if (!(MDFloatCompare(diffWidth, 0) && MDFloatCompare(diffHeight, 0)))
		updateVAO = TRUE;
}

- (MDRect) frame
{
	return frame;
}

- (BOOL) keyDown
{
	return NO;
}

- (void) setBackground: (NSColor*)bkg
{
	background = [ NSColor colorWithDeviceRed:[ bkg redComponent ] green:[ bkg greenComponent ] blue:[ bkg blueComponent ] alpha:[ bkg alphaComponent ] ];
	updateVAO = TRUE;
}


- (NSColor*) background
{
	return background;
}

- (void) setStrokeColor:(NSColor*)color
{
	strokeColor = [ NSColor colorWithDeviceRed:[ color redComponent ] green:[ color greenComponent ] blue:[ color blueComponent ] alpha:[ color alphaComponent ] ];
	updateVAO = TRUE;
}

- (NSColor*) strokeColor
{
	return strokeColor;
}

- (void) setRoundingRadius:(float)rad
{
	radius = rad;
	updateVAO = TRUE;
}

- (float) roundingRadius
{
	return radius;
}

- (void) setStrokeSize:(float)size
{
	strokeSize = size;
	updateVAO = TRUE;
}

- (float) strokeSize
{
	return strokeSize;
}

- (NSMutableArray*) subViews
{
	return subViews;
}

- (void) addSubView: (id)view
{
	[ view setParentView:self ];
	[ subViews addObject:view ];
	MDRect frm = [ (MDControlView*)view frame ];
	frm.x += frame.x;
	frm.y += frame.y;
	[ (MDControlView*)view setFrame:frm ];
	[ views removeObject:view ];
}

- (id) parentView
{
	return parentView;
}

- (void) setParentView: (id) view
{
	//if (parentView)
	//	[ parentView release ];
	parentView = view;//[ view retain ];
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
	for (long z = [ subViews count ] - 1; z >= 0; z--)
	{
		MDControlView* view = subViews[z];
		[ view mouseNotDown ];
	}
}

- (void) mouseDown: (NSEvent*)event
{
	for (long z = [ subViews count ] - 1; z >= 0; z--)
	{
		MDControlView* view = subViews[z];
		[ view mouseDown:event ];
		if ([ view mouseDown ])
			break;
	}
}

- (void) mouseMoved: (NSEvent*)event
{
	for (long z = [ subViews count ] - 1; z >= 0; z--)
	{
		MDControlView* view = subViews[z];
		[ view mouseMoved:event ];
	}
}

- (void) mouseDragged: (NSEvent*)event
{
	for (long z = [ subViews count ] - 1; z >= 0; z--)
	{
		MDControlView* view = subViews[z];
		[ view mouseDragged:event ];
		if ([ view mouseDown ])
			break;
	}
}

- (void) mouseUp: (NSEvent*)event
{
	for (long z = [ subViews count ] - 1; z >= 0; z--)
	{
		MDControlView* view = subViews[z];
		[ view mouseUp:event ];
	}
}

- (void) scrollWheel: (NSEvent*)event
{
	for (long z = [ subViews count ] - 1; z >= 0; z--)
	{
		MDControlView* view = subViews[z];
		[ view scrollWheel:event ];
	}
}

- (BOOL) scrolled
{
	return NO;
}

- (void) keyDown: (NSEvent*)event
{
	for (long z = [ subViews count ] - 1; z >= 0; z--)
	{
		MDControlView* view = subViews[z];
		[ view keyDown:event ];
	}
}

- (void) keyUp: (NSEvent*)event
{
	for (long z = [ subViews count ] - 1; z >= 0; z--)
	{
		MDControlView* view = subViews[z];
		[ view keyUp:event ];
	}
}

- (void) setRed: (float) red
{
	background = [ NSColor colorWithCalibratedRed:red green:[ background greenComponent ] blue:[ background blueComponent ] alpha:[ background alphaComponent ] ];
}

- (void) setGreen: (float)green
{
	background = [ NSColor colorWithCalibratedRed:[ background redComponent ] green:green blue:[ background blueComponent ] alpha:[ background alphaComponent ] ];
}

- (void) setBlue: (float)blue
{
	background = [ NSColor colorWithCalibratedRed:[ background redComponent ] green:[ background greenComponent ] blue:blue alpha:[ background alphaComponent ] ];
}

- (void) setAlpha: (float)alpha
{
	background = [ NSColor colorWithCalibratedRed:[ background redComponent ] green:[ background greenComponent ] blue:[ background blueComponent ] alpha:alpha ];
}

- (BOOL) beforeDraw
{
	for (unsigned long z = 0; z < [ subViews count ]; z++)
		[ subViews[z] beforeDraw ];
	return FALSE;
}

- (void) finishDraw
{
	for (unsigned long z = 0; z < [ subViews count ]; z++)
		[ subViews[z] finishDraw ];
}

- (void) alphaDraw
{
	for (unsigned long z = 0; z < [ subViews count ]; z++)
		[ subViews[z] alphaDraw ];
}

- (void) setEnabled: (BOOL)en
{
	enabled = en;
	for (int z = 0; z < [ subViews count ]; z++)
		[ subViews[z] setEnabled:en ];
}

- (BOOL) enabled
{
	return enabled;
}

- (void) setVisible: (BOOL)vis
{
	visible = vis;
	for (int z = 0; z < [ subViews count ]; z++)
		[ subViews[z] setVisible:vis ];
}

- (BOOL) visible
{
	return visible;
}

- (void) setIdentity: (NSString*) str
{
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
	if (views && [ views containsObject:self ])
		[ views removeObject:self ];
	MDDeleteVAO(vao);
	MDDeleteVAO(strokeVao);
}

@end
