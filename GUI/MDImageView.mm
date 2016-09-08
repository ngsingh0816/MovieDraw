//
//  MDImageView.m
//  GUI
//
//  Created by Neil Singh on 2/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MDImageView.h"

@implementation MDImageView

- (MDImageView*) imageView
{
	return [ [ [ MDImageView alloc ] init ] autorelease ];
}

- (MDImageView*) imageViewWithFrame: (MDRect)rect background:(NSColor*)bkg
{
	return [ [ [ MDImageView alloc ] initWithFrame:rect background:bkg ] autorelease ];
}

- (id) init
{
	if (self = [ super init ])
	{
		image = [ [ NSString alloc ] init ];
		mouseDownColor = [ MD_IMAGEVIEW_DEFAULT_COLOR retain ];
	}
	return self;
}

- (id) initWithFrame:(MDRect)rect background:(NSColor *)bkg
{
	if (self = [ super initWithFrame:rect background:bkg ])
	{
		image = [ [ NSString alloc ] init ];
		mouseDownColor = [ MD_IMAGEVIEW_DEFAULT_COLOR retain ];
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
	NSAutoreleasePool* pool = [ [ NSAutoreleasePool alloc ] init ];
	
	LoadImage([ image UTF8String ], &gImage, 0);
	
	[ pool release ];
	pool = nil;
}

- (void) setImage:(NSString*)img onThread:(BOOL)thread
{
	if (image)
		[ image release ];
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
	NSAutoreleasePool* pool = [ [ NSAutoreleasePool alloc ] init ];
	
	LoadImage((const char*)[ data bytes ], &gImage, [ data length ]);
	
	[ pool release ];
	pool = nil;
}

- (void) setImageData:(NSData*)img onThread:(BOOL)thread
{
	if (image)
	{
		[ image release ];
		image = nil;
	}
	if (gImage)
		ReleaseImage(&gImage);
	if (!thread)
		LoadImage((const char*)[ img bytes ], &gImage, [ img length ]);
	else
		[ NSThread detachNewThreadSelector:@selector(loadDataThread:) toTarget:self withObject:img ];
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
	if (mouseDownColor)
		[ mouseDownColor release ];
	mouseDownColor = [ color retain ];
}

- (NSColor*) mouseDownColor
{
	return mouseDownColor;
}

- (void) drawView
{
	if (!visible)
		return;
	
	glLoadIdentity();
	glTranslated(frame.x, frame.y, 0);
	glEnable(GL_TEXTURE_2D);
	glBindTexture(GL_TEXTURE_2D, gImage);
	NSColor* color = background[0];
	if (realDown)
		color = mouseDownColor;
	glColor4d([ color redComponent ], [ color greenComponent ], [ color blueComponent ], [ color alphaComponent ]);
	glBegin(GL_QUADS);
	{
		glTexCoord2d(0, 0);
		glVertex2d(0, 0);
		glTexCoord2d(1, 0);
		glVertex2d(frame.width, 0);
		glTexCoord2d(1, 1);
		glVertex2d(frame.width, frame.height);
		glTexCoord2d(0, 1);
		glVertex2d(0, frame.height);
	}
	glEnd();
	glBindTexture(GL_TEXTURE_2D, 0);
	glDisable(GL_TEXTURE_2D);
	glLoadIdentity();
}

- (void) dealloc
{
	if (image)
	{
		[ image release ];
		image = nil;
	}
	if (gImage)
	{
		ReleaseImage(&gImage);
		gImage = 0;
	}
	if (mouseDownColor)
	{
		[ mouseDownColor release ];
		mouseDownColor = nil;
	}
	[ super dealloc ];
}

@end
