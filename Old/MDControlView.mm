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
	
	// Get ready to draw
	int s = 0;
	glGetIntegerv (GL_MATRIX_MODE, &s);
	glMatrixMode (GL_PROJECTION);
	glPushMatrix();
	glLoadIdentity ();
	glMatrixMode (GL_MODELVIEW);
	glPushMatrix();

	// Draw
	NSSize bounds = resolution;
	glLoadIdentity();    // Reset the current modelview matrix
	glScaled(2.0 / bounds.width, -2.0 / bounds.height, 1.0);
	glTranslated(-bounds.width / 2.0, -bounds.height / 2.0, 0.0);
	glColor4f(1.0f, 1.0f, 1.0f, 1.0f);	// Make right color
	
	NSSize frameSize = [ string frameSize ];
	position.x -= frameSize.width / 2;
	position.y += (frameSize.height / 2) + 1;
	position.y = bounds.height - position.y;
	
	glTranslated(position.x, position.y, 0);
	glRotated(rotation, 0, 0, 1);
	glTranslated(-position.x, -position.y, 0);
	MDRect rect = MakeRect(position.x, position.y,
								  frameSize.width, frameSize.height);
	if (align == NSLeftTextAlignment)
	{
		glTranslated(frameSize.width / 2.0, 0, 0);
		rect = MakeRect(frameSize.width + position.x, position.y,
						frameSize.width, frameSize.height);
	}
	else if (align == NSRightTextAlignment)
	{
		glTranslated(-frameSize.width / 2.0, 0, 0);
		rect = MakeRect(-frameSize.width + position.x, position.y,
						frameSize.width, frameSize.height);
	}
	[ string drawAtPoint:position ];
	
	// Reset things
	glPopMatrix(); // GL_MODELVIEW
	glMatrixMode (GL_PROJECTION);
    glPopMatrix();
    glMatrixMode (s);
	
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
	
	int s = 0;
	glGetIntegerv (GL_MATRIX_MODE, &s);
	glMatrixMode (GL_PROJECTION);
	glPushMatrix();
	glLoadIdentity ();
	glMatrixMode (GL_MODELVIEW);
	glPushMatrix();
	NSSize bounds = resolution;
	glLoadIdentity();    // Reset the current modelview matrix
	glScaled(2.0 / bounds.width, -2.0 / bounds.height, 1.0);
	glTranslated(-bounds.width / 2.0, -bounds.height / 2.0, 0.0);
	NSColor* prev = [ glStr textColor ];
	[ glStr setTextColor:color ];
	glColor4f(1, 1, 1, 1);
	
	NSSize frameSize = [ glStr frameSize ];
	position.x -= frameSize.width / 2;
	position.y += (frameSize.height / 2) + 1;
	position.y = bounds.height - position.y;
	
	glTranslated(position.x, position.y, 0);
	glRotated(rotation, 0, 0, 1);
	glTranslated(-position.x, -position.y, 0);
	MDRect rect = MakeRect(position.x, position.y,
						   frameSize.width, frameSize.height);
	if (align == NSLeftTextAlignment)
	{
		glTranslated(frameSize.width / 2.0, 0, 0);
		rect = MakeRect(frameSize.width + position.x, position.y,
						frameSize.width, frameSize.height);
	}
	else if (align == NSRightTextAlignment)
	{
		glTranslated(-frameSize.width / 2.0, 0, 0);
		rect = MakeRect(-frameSize.width + position.x, position.y,
						frameSize.width, frameSize.height);
	}
	[ glStr drawAtPoint:position ];
	[ glStr setTextColor:prev ];
	
	// Reset things
	glLoadIdentity();
	glPopMatrix(); // GL_MODELVIEW
	glMatrixMode (GL_PROJECTION);
    glPopMatrix();
    glMatrixMode (s);
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
		if( bitsPPixel == 24 )        // No alpha channel
			texFormat = GL_RGB;
		else if( bitsPPixel == 32 )   // There is an alpha channel
			texFormat = GL_RGBA;
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
		
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, texSize.width, texSize.height, 0, texFormat, GL_UNSIGNED_BYTE, tdata);
		
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
	
	float square[8];
	square[0] = frame.x;
	square[1] = frame.y;
	square[2] = frame.x + frame.width;
	square[3] = frame.y;
	square[4] = frame.x;
	square[5] = frame.y + frame.height;
	square[6] = frame.x + frame.width;
	square[7] = frame.y + frame.height;
	
	float colors[16];
	for (int z = 0; z < 4; z++)
	{
		float add = !enabled ? -0.3 : 0.0;
		colors[(z * 4)] = [ background[z] redComponent ] + add;
		colors[(z * 4) + 1] = [ background[z] greenComponent ] + add;
		colors[(z * 4) + 2] = [ background[z] blueComponent ] + add;
		colors[(z * 4) + 3] = [ background[z] alphaComponent ];
	}
	
	glLoadIdentity();
	glVertexPointer(2, GL_FLOAT, 0, square);
	glEnableClientState(GL_VERTEX_ARRAY);
	glColorPointer(4, GL_FLOAT, 0, colors);
	glEnableClientState(GL_COLOR_ARRAY);
	
	// Draw
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	
	glDisableClientState(GL_VERTEX_ARRAY);
	glDisableClientState(GL_COLOR_ARRAY);
}

- (void) setFrame: (MDRect)rect
{
	[ self setFrame:rect animate:0 tweening:MDLinear ];
}

- (void) updateFrame
{
	animationSec += 1 / 60.0 * 1000;
	if (animationSec > frameSec)
	{
		[ frameTimer invalidate ];
		frameTimer = nil;
		[ self setFrame:targetFrame ];
		return;
	}
	if (frameTween == MDLinear)
	{
		MDRect newFrame = frame;
		newFrame.x = (targetFrame.x - frame.x) * animationSec / frameSec + frame.x;
		newFrame.y = (targetFrame.y - frame.y) * animationSec / frameSec + frame.y;
		newFrame.width = (targetFrame.width - frame.width) * animationSec / frameSec + frame.width;
		newFrame.height = (targetFrame.height - frame.height) * animationSec / frameSec + frame.height;
		[ self setFrame:newFrame ];
	}
}

- (void) setFrame:(MDRect)rect animate:(unsigned int)sec tweening:(MDTween)tween
{
	if (sec == 0)
		frame = rect;
	else
	{
		startFrame = frame;
		targetFrame = rect;
		frameTween = tween;
		frameSec = sec;
		animationSec = 0;
		if (frameTimer)
			[ frameTimer invalidate ];
		frameTimer = [ NSTimer scheduledTimerWithTimeInterval:1 / 60.0 target:self selector:@selector(updateFrame) userInfo:nil repeats:YES ];
	}
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
		background[z] = [ [ NSColor colorWithDeviceRed:[ backup alphaComponent ] green:
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
	if (frameTimer)
	{
		[ frameTimer invalidate ];
		frameTimer = nil;
	}
	[ super dealloc ];
}

@end
