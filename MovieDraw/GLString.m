//
// File:		GLString.m
//				(Originally StringTexture.m)
//
// Abstract:	Uses Quartz to draw a string into an OpenGL texture
//
// Version:		1.1 - Antialiasing option, Rounded Corners to the frame
//					  self contained OpenGL state, performance enhancements,
//					  other bug fixes.
//				1.0 - Original release.
//				
//
// Disclaimer:	IMPORTANT:  This Apple software is supplied to you by Apple Inc. ("Apple")
//				in consideration of your agreement to the following terms, and your use,
//				installation, modification or redistribution of this Apple software
//				constitutes acceptance of these terms.  If you do not agree with these
//				terms, please do not use, install, modify or redistribute this Apple
//				software.
//
//				In consideration of your agreement to abide by the following terms, and
//				subject to these terms, Apple grants you a personal, non - exclusive
//				license, under Apple's copyrights in this original Apple software ( the
//				"Apple Software" ), to use, reproduce, modify and redistribute the Apple
//				Software, with or without modifications, in source and / or binary forms;
//				provided that if you redistribute the Apple Software in its entirety and
//				without modifications, you must retain this notice and the following text
//				and disclaimers in all such redistributions of the Apple Software. Neither
//				the name, trademarks, service marks or logos of Apple Inc. may be used to
//				endorse or promote products derived from the Apple Software without specific
//				prior written permission from Apple.  Except as expressly stated in this
//				notice, no other rights or licenses, express or implied, are granted by
//				Apple herein, including but not limited to any patent rights that may be
//				infringed by your derivative works or by other works in which the Apple
//				Software may be incorporated.
//
//				The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
//				WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
//				WARRANTIES OF NON - INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A
//				PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION
//				ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
//
//				IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
//				CONSEQUENTIAL DAMAGES ( INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//				SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//				INTERRUPTION ) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION
//				AND / OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER
//				UNDER THEORY OF CONTRACT, TORT ( INCLUDING NEGLIGENCE ), STRICT LIABILITY OR
//				OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// Copyright ( C ) 2003-2007 Apple Inc. All Rights Reserved.
//

#import "GLString.h"
#import <OpenGL/OpenGL.h>
#import <OpenGL/CGLContext.h>
#import <OpenGL/gl.h>
#undef __gl_h_
#import <OpenGL/gl3.h>

// The following is a NSBezierPath category to allow
// for rounded corners of the border

#pragma mark -
#pragma mark NSBezierPath Category

@implementation NSBezierPath (RoundRect)

+ (NSBezierPath *)bezierPathWithRoundedRect:(NSRect)rect cornerRadius:(float)radius {
    NSBezierPath *result = [NSBezierPath bezierPath];
    [result appendBezierPathWithRoundedRect:rect cornerRadius:radius];
    return result;
}

- (void)appendBezierPathWithRoundedRect:(NSRect)rect cornerRadius:(float)radius {
    if (!NSIsEmptyRect(rect)) {
		if (radius > 0.0) {
			// Clamp radius to be no larger than half the rect's width or height.
			float clampedRadius = MIN(radius, 0.5 * MIN(rect.size.width, rect.size.height));
			
			NSPoint topLeft = NSMakePoint(NSMinX(rect), NSMaxY(rect));
			NSPoint topRight = NSMakePoint(NSMaxX(rect), NSMaxY(rect));
			NSPoint bottomRight = NSMakePoint(NSMaxX(rect), NSMinY(rect));
			
			[self moveToPoint:NSMakePoint(NSMidX(rect), NSMaxY(rect))];
			[self appendBezierPathWithArcFromPoint:topLeft     toPoint:rect.origin radius:clampedRadius];
			[self appendBezierPathWithArcFromPoint:rect.origin toPoint:bottomRight radius:clampedRadius];
			[self appendBezierPathWithArcFromPoint:bottomRight toPoint:topRight    radius:clampedRadius];
			[self appendBezierPathWithArcFromPoint:topRight    toPoint:topLeft     radius:clampedRadius];
			[self closePath];
		} else {
			// When radius == 0.0, this degenerates to the simple case of a plain rectangle.
			[self appendBezierPathWithRect:rect];
		}
    }
}

@end


#pragma mark -
#pragma mark GLString

// GLString follows

@implementation GLString

#pragma mark -
#pragma mark Deallocs

- (void) deleteTexture
{
	if (texName && cgl_ctx) {
		(*cgl_ctx->disp.delete_textures)(cgl_ctx->rend, 1, &texName);
		texName = 0; // ensure it is zeroed for failure cases
		cgl_ctx = 0;
	}
}

- (void) dealloc
{
	[ self deleteTexture ];
	if (vao[0])
	{
		if (glIsVertexArray(vao[0]))
			glDeleteVertexArrays(1, &vao[0]);
	}
	if (vao[1])
	{
		if (glIsBuffer(vao[1]))
			glDeleteBuffers(1, &vao[1]);
	}
	if (vao[2])
	{
		if (glIsBuffer(vao[2]))
			glDeleteBuffers(1, &vao[2]);
	}
}

#pragma mark -
#pragma mark Initializers

// designated initializer
- (instancetype) initWithAttributedString:(NSAttributedString *)attributedString withTextColor:(NSColor *)text withBoxColor:(NSColor *)box withBorderColor:(NSColor *)border
{
	if ((self = [super init]))
	{
		cgl_ctx = NULL;
		texName = 0;
		texSize.width = 0.0f;
		texSize.height = 0.0f;
		string = attributedString;
		textColor = text;
		boxColor = box;
		borderColor = border;
		staticFrame = NO;
		antialias = YES;
		marginSize.width = 4.0f; // standard margins
		marginSize.height = 2.0f;
		cRadius = 4.0f;
		requiresUpdate = YES;
		fromTop = FALSE;
		fromRight = FALSE;
		// all other variables 0 or NULL
	}
	return self;
}

- (instancetype) initWithString:(NSString *)aString withAttributes:(NSDictionary *)attribs withTextColor:(NSColor *)text withBoxColor:(NSColor *)box withBorderColor:(NSColor *)border
{
	return [self initWithAttributedString:[[NSAttributedString alloc] initWithString:aString attributes:attribs] withTextColor:text withBoxColor:box withBorderColor:border];
}

// basic methods that pick up defaults
- (instancetype) initWithAttributedString:(NSAttributedString *)attributedString;
{
	return [self initWithAttributedString:attributedString withTextColor:[NSColor colorWithDeviceRed:1.0f green:1.0f blue:1.0f alpha:1.0f] withBoxColor:[NSColor colorWithDeviceRed:1.0f green:1.0f blue:1.0f alpha:0.0f] withBorderColor:[NSColor colorWithDeviceRed:1.0f green:1.0f blue:1.0f alpha:0.0f]];
}

- (instancetype) initWithString:(NSString *)aString withAttributes:(NSDictionary *)attribs
{
	return [self initWithAttributedString:[[NSAttributedString alloc] initWithString:aString attributes:attribs] withTextColor:[NSColor colorWithDeviceRed:1.0f green:1.0f blue:1.0f alpha:1.0f] withBoxColor:[NSColor colorWithDeviceRed:1.0f green:1.0f blue:1.0f alpha:0.0f] withBorderColor:[NSColor colorWithDeviceRed:1.0f green:1.0f blue:1.0f alpha:0.0f]];
}

- (void) setContext:(NSOpenGLContext*)context
{
	contextObj = context;
}

- (void) genTexture; // generates the texture without drawing texture to current context
{
	NSImage * image;
	NSBitmapImageRep * bitmap;
	
	NSSize previousSize = texSize;
	
	if ((NO == staticFrame) && (0.0f == frameSize.width) && (0.0f == frameSize.height)) { // find frame size if we have not already found it
		frameSize = [string size]; // current string size
		frameSize.width += marginSize.width * 2.0f; // add padding
		frameSize.height += marginSize.height * 2.0f;
		realSize = frameSize;
	}
	if (realSize.width == 0 && realSize.height == 0)
		return;
	
	image = [[NSImage alloc] initWithSize:realSize];
	
	[image lockFocus];
	[[NSGraphicsContext currentContext] setShouldAntialias:antialias];
	
	if ([boxColor alphaComponent]) { // this should be == 0.0f but need to make sure
		[boxColor set]; 
		NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(NSMakeRect (0.0f, 0.0f, frameSize.width, frameSize.height) , 0.5, 0.5)
														cornerRadius:cRadius];
		[path fill];
	}
	
	if ([borderColor alphaComponent]) {
		[borderColor set]; 
		NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(NSMakeRect (0.0f, 0.0f, frameSize.width, frameSize.height), 0.5, 0.5) 
														cornerRadius:cRadius];
		[path setLineWidth:1.0f];
		[path stroke];
	}
	
	//[textColor set]; 
	[ [ NSColor colorWithCalibratedRed:1 green:1 blue:1 alpha:1 ] set ];
	[string drawAtPoint:NSMakePoint (marginSize.width, marginSize.height)]; // draw at offset position
	NSRect therect = NSMakeRect(realSize.width - frameSize.width,
				realSize.height - frameSize.height, frameSize.width, frameSize.height);
	if (fromTop)
	{
		therect.origin.y = 0;
		therect.size.height = frameSize.height;
	}
	if (fromRight)
	{
		therect.origin.x = 0;
		therect.size.width = frameSize.width;
	}
	bitmap = [[NSBitmapImageRep alloc] initWithFocusedViewRect:therect];
	[image unlockFocus];
	texSize.width = [bitmap pixelsWide];
	texSize.height = [bitmap pixelsHigh];
	
	
	NSOpenGLContext* prevContext = [ NSOpenGLContext currentContext ];
	if (contextObj)
		[ contextObj makeCurrentContext ];
	
	if ((cgl_ctx = CGLGetCurrentContext ())) { // if we successfully retrieve a current context (required)
		//glPushAttrib(GL_TEXTURE_BIT);
		if (0 == texName) glGenTextures (1, &texName);
		glBindTexture (GL_TEXTURE_2D, texName);
		if (NSEqualSizes(previousSize, texSize)) {
			glTexSubImage2D(GL_TEXTURE_2D,0,0,0,texSize.width,texSize.height,[bitmap hasAlpha] ? GL_RGBA : GL_RGB,GL_UNSIGNED_BYTE,[bitmap bitmapData]);
		} else {
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
			glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, texSize.width, texSize.height, 0, [bitmap hasAlpha] ? GL_RGBA : GL_RGB, GL_UNSIGNED_BYTE, [bitmap bitmapData]);
		}
		//glPopAttrib();
	} else
		NSLog (@"StringTexture -genTexture: Failure to get current OpenGL context\n");
	
	if (contextObj)
		[ prevContext makeCurrentContext ];
	
	NSRect bounds = NSMakeRect(0, 0, texSize.width, texSize.height);
	
	glGenVertexArrays(1, &vao[0]);
	glBindVertexArray(vao[0]);
	
	float verts[] = { bounds.origin.x, bounds.origin.y, 0,
		bounds.origin.x, bounds.origin.y + bounds.size.height, 0,
		bounds.origin.x + bounds.size.width, bounds.origin.y, 0,
		bounds.origin.x + bounds.size.width, bounds.origin.y + bounds.size.height, 0 };
	float texCoords[] = { 0, 0, 0, 1, 1, 0, 1, 1 };
	
	glGenBuffers(1, &vao[1]);
	glBindBuffer(GL_ARRAY_BUFFER, vao[1]);
	glBufferData(GL_ARRAY_BUFFER, 4 * 3 * sizeof(float), verts, GL_STATIC_DRAW);
	glVertexAttribPointer(0, 3, GL_FLOAT, NO, 0, NULL);
	glEnableVertexAttribArray(0);
	
	glGenBuffers(1, &vao[2]);
	glBindBuffer(GL_ARRAY_BUFFER, vao[2]);
	glBufferData(GL_ARRAY_BUFFER, 4 * 2 * sizeof(float), texCoords, GL_STATIC_DRAW);
	glVertexAttribPointer(3, 2, GL_FLOAT, NO, 0, NULL);
	glEnableVertexAttribArray(3);
	
	glBindVertexArray(0);
	
	requiresUpdate = NO;
}

#pragma mark -
#pragma mark Accessors

- (GLuint) texName
{
	return texName;
}

- (NSSize) texSize
{
	return texSize;
}

#pragma mark Text Color

- (void) setTextColor:(NSColor *)color // set default text color
{
	textColor = color;
	//requiresUpdate = YES;
}

- (NSColor *) textColor
{
	return textColor;
}

#pragma mark String
- (NSAttributedString*) string
{
	return string;
}

#pragma mark Box Color

- (void) setBoxColor:(NSColor *)color // set default text color
{
	boxColor = color;
	requiresUpdate = YES;
}

- (NSColor *) boxColor
{
	return boxColor;
}

#pragma mark Border Color

- (void) setBorderColor:(NSColor *)color // set default text color
{
	borderColor = color;
	requiresUpdate = YES;
}

- (NSColor *) borderColor
{
	return borderColor;
}

#pragma mark Margin Size

// these will force the texture to be regenerated at the next draw
- (void) setMargins:(NSSize)size // set offset size and size to fit with offset
{
	marginSize = size;
	if (NO == staticFrame) { // ensure dynamic frame sizes will be recalculated
		frameSize.width = 0.0f;
		frameSize.height = 0.0f;
	}
	requiresUpdate = YES;
}

- (NSSize) marginSize
{
	return marginSize;
}

#pragma mark Antialiasing
- (BOOL) antialias
{
	return antialias;
}

- (void) setAntialias:(bool)request
{
	antialias = request;
	requiresUpdate = YES;
}


#pragma mark Frame

- (NSSize) frameSize
{
	if ((NO == staticFrame) && (0.0f == frameSize.width) && (0.0f == frameSize.height)) { // find frame size if we have not already found it
		frameSize = [string size]; // current string size
		frameSize.width += marginSize.width * 2.0f; // add padding
		frameSize.height += marginSize.height * 2.0f;
		realSize = frameSize;
	}
	return frameSize;
}

- (BOOL) staticFrame
{
	return staticFrame;
}

- (BOOL) fromRight
{
	return fromRight;
}

- (void) setFromRight: (BOOL)right
{
	fromRight = right;
}

- (BOOL) fromTop
{
	return fromTop;
}

- (void) setFromTop: (BOOL)top
{
	fromTop = top;
}

- (NSSize) realSize
{
	if (realSize.width == 0 && realSize.height == 0)
		realSize = [ self frameSize ];
	return realSize;
}

- (void) useStaticFrame:(NSSize)size // set static frame size and size to frame
{
	frameSize = size;
	staticFrame = YES;
	requiresUpdate = YES;
}

- (void) useDynamicFrame
{
	if (staticFrame) { // set to dynamic frame and set to regen texture
		staticFrame = NO;
		frameSize.width = 0.0f; // ensure frame sizes will be recalculated
		frameSize.height = 0.0f;
		requiresUpdate = YES;
	}
}

#pragma mark String

- (void) setString:(NSAttributedString *)attributedString // set string after initial creation
{
	string = attributedString;
	if (NO == staticFrame) { // ensure dynamic frame sizes will be recalculated
		frameSize.width = 0.0f;
		frameSize.height = 0.0f;
	}
	requiresUpdate = YES;
}

- (void) setString:(NSString *)aString withAttributes:(NSDictionary *)attribs; // set string after initial creation
{
	[self setString:[[NSAttributedString alloc] initWithString:aString attributes:attribs]];
}

#pragma mark -
#pragma mark Drawing

- (void) drawWithBounds:(NSRect)bounds
{
	if (requiresUpdate)
		[self genTexture];
	if (texName) {
		//glPushAttrib(GL_ENABLE_BIT | GL_TEXTURE_BIT | GL_COLOR_BUFFER_BIT); // GL_COLOR_BUFFER_BIT for glBlendFunc, GL_ENABLE_BIT for glEnable / glDisable
		
		glDisable (GL_DEPTH_TEST); // ensure text is not remove by depth buffer test.
		glEnable (GL_BLEND); // for text fading
		NSColor* color = [ textColor colorUsingColorSpace:[ NSColorSpace genericRGBColorSpace ] ];
		if ([ color alphaComponent ] > 0.99)
			glBlendFunc (GL_ONE, GL_ONE_MINUS_SRC_ALPHA); // ditto
		
		unsigned int vao2[3];
		
		glGenVertexArrays(1, &vao2[0]);
		glBindVertexArray(vao2[0]);
		
		float verts[] = { bounds.origin.x, bounds.origin.y, 0,
			bounds.origin.x, bounds.origin.y + bounds.size.height, 0,
			bounds.origin.x + bounds.size.width, bounds.origin.y, 0,
			bounds.origin.x + bounds.size.width, bounds.origin.y + bounds.size.height, 0 };
		float texCoords[] = { 0, 0, 0, 1, 1, 0, 1, 1 };
		
		glGenBuffers(1, &vao2[1]);
		glGenBuffers(1, &vao2[1]);
		glBindBuffer(GL_ARRAY_BUFFER, vao2[1]);
		glBufferData(GL_ARRAY_BUFFER, 4 * 3 * sizeof(float), verts, GL_STATIC_DRAW);
		glVertexAttribPointer(0, 3, GL_FLOAT, NO, 0, NULL);
		glEnableVertexAttribArray(0);
		
		glGenBuffers(1, &vao2[2]);
		glGenBuffers(1, &vao2[2]);
		glBindBuffer(GL_ARRAY_BUFFER, vao2[2]);
		glBufferData(GL_ARRAY_BUFFER, 4 * 2 * sizeof(float), texCoords, GL_STATIC_DRAW);
		glVertexAttribPointer(3, 2, GL_FLOAT, NO, 0, NULL);
		glEnableVertexAttribArray(3);
		
		glVertexAttrib4f(1, [ color redComponent ], [ color greenComponent ], [ color blueComponent ], [ color alphaComponent ]);
		glVertexAttrib3f(2, 0, 0, 0);
		
		glBindTexture (GL_TEXTURE_2D, texName);
		float scale = 1 / [ [ NSScreen mainScreen ] backingScaleFactor ];
		glScaled(scale, scale, 1);
		glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
		glScaled(1 / scale, 1 / scale, 1);
		
		glBindVertexArray(0);
		
		glDeleteBuffers(2, &vao2[1]);
		glDeleteVertexArrays(1, &vao2[0]);
			
	//	glPopAttrib();
	}
}

- (void) drawAtPoint:(NSPoint)point
{
	if (requiresUpdate)
		[self genTexture]; // ensure size is calculated for bounds
	if (texName) // if successful
	{
		/*if (!fromTop)
			point.y -= (realSize.height - frameSize.height) / 2.0;
		else
			point.y += (realSize.height - frameSize.height) / 2.0;
		[self drawWithBounds:NSMakeRect (point.x, point.y, texSize.width, texSize.height)];*/
		
	//	glPushAttrib(GL_ENABLE_BIT | GL_TEXTURE_BIT | GL_COLOR_BUFFER_BIT); // GL_COLOR_BUFFER_BIT for glBlendFunc, GL_ENABLE_BIT for glEnable / glDisable
		
		NSColor* color = [ textColor colorUsingColorSpace:[ NSColorSpace genericRGBColorSpace ] ];
		
		glDisable (GL_DEPTH_TEST); // ensure text is not remove by depth buffer test.
		glEnable (GL_BLEND); // for text fading
		if ([ color alphaComponent ] > 0.99)
			glBlendFunc (GL_ONE, GL_ONE_MINUS_SRC_ALPHA); // ditto
		glBindVertexArray(vao[0]);
		glVertexAttrib4f(1, [ color redComponent ], [ color greenComponent ], [ color blueComponent ], [ color alphaComponent ]);
		glVertexAttrib3f(2, 0, 0, 0);
		glBindTexture (GL_TEXTURE_2D, texName);
		float scale = 1 / [ [ NSScreen mainScreen ] backingScaleFactor ];
		glScaled(scale, scale, 1);
		glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
		glBindVertexArray(0);
		glScaled(1 / scale, 1 / scale, 1);
	//	glPopAttrib();
	}
}

@end
