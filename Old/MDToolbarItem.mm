//
//  MDToolbarItem.m
//  MovieDraw
//
//  Created by MILAP on 7/22/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MDToolbarItem.h"


@implementation MDToolbarItem

+ (id) mdToolbarItem
{
	MDToolbarItem* view = [ [ [ MDToolbarItem alloc ] init ] autorelease ];
	return view;
}

+ (id) mdToolbarItemWithFrame: (MDRect)rect background: (NSColor*)bkg
{
	MDToolbarItem* view = [ [ [ MDToolbarItem alloc ] initWithFrame:rect
												 background:bkg ] autorelease ];
	return view;
}

- (id) init
{
	if ((self = [ super init ]))
	{
		image = [ [ NSString alloc ] init ];
		type = MDITEM_NORMAL;
		img = 0;
		if (textFont)
			[ textFont release ];
		textFont = [ [ NSFont systemFontOfSize:10 ] retain ];
		overlay = [ [ NSColor colorWithCalibratedRed:1 green:1 blue:1 alpha:1 ] retain ];
	}
	return self;
}

- (id) initWithFrame: (MDRect)rect background: (NSColor*)bkg
{
	if ((self = [ super initWithFrame:rect background:bkg ]))
	{
		image = [ [ NSString alloc ] init ];
		type = MDITEM_NORMAL;
		img = 0;
		if (textFont)
			[ textFont release ];
		textFont = [ [ NSFont systemFontOfSize:10 ] retain ];
		overlay = [ [ NSColor colorWithCalibratedRed:1 green:1 blue:1 alpha:1 ] retain ];
	}
	return self;
}

- (NSColor*)overlay
{
	return overlay;
}

- (void) setOverlay: (NSColor*)ov
{
	if (overlay)
		[ overlay release];
	overlay = [ ov retain ];
}

- (void) setImagePath: (char*)data length:(unsigned int)len;
{
	if (image)
		[ image release ];
	unsigned int oldImage = img;
	img = 0;
	if (len == 0)
	{
		NSString* path = [ NSString stringWithFormat:@"%s", data ];
		if ([ path hasPrefix:@"NS" ])
		{
			NSImage* timage = [ NSImage imageNamed:path ];
			if (timage)
			{
				NSData* data = [ [ timage TIFFRepresentation ] retain ];
				[ self setImagePath:(char*)[ data bytes ] length:(int)[ data length ] ];
				[ data release ];
				data = nil;
			}
		}
		else if (![ path hasPrefix:@"/" ])
		{
			image = [ [ NSString alloc ] initWithFormat:@"%@/%@", [ [ NSBundle mainBundle ]
										resourcePath ], path ];
		}
		else
			image = [ [ NSString alloc ] initWithFormat:@"%s", data ];
		if (![ [ NSFileManager defaultManager ] fileExistsAtPath:image ])
		{
			[ image release ];
			image = nil;
		}
		else if (!LoadImage([ image UTF8String ], &img, 0))
		{
			[ image release ];
			image = nil;
		}
	}
	else
	{
		if (!LoadImage(data, &img, len))
			img = 0;
	}
	if (oldImage != 0)
	{
		GLboolean is = false;
		glAreTexturesResident(1, &oldImage, &is);
		if (is)
			glDeleteTextures(1, &oldImage);
		
	}
}

- (NSString*) imagePath
{
	return image;
}

- (void) setItemType: (MDItemOption)option
{
	type = option;
}

- (MDItemOption) itemType
{
	return type;
}

- (void) drawView
{
	if (!visible)
		return;
	
	glLoadIdentity();
	float dimenW = [ glStr frameSize ].height / 2;
	if ((image && [ image length ] != 0) || img != 0)
	{
		float height = [ (MDControlView*)[ self parentView ] frame ].height
		- (dimenW * 2);
		float middle = (((frame.x + frame.width + frame.x) / 2.0) - (height / 2.0));
		MDRect rect = MakeRect(middle, frame.y - (height - frame.height), height, height);
		float square[8];
		square[0] = rect.x;
		square[1] = rect.y;
		square[2] = rect.x + rect.width;
		square[3] = rect.y;
		square[4] = rect.x;
		square[5] = rect.y + rect.height;
		square[6] = rect.x + rect.width;
		square[7] = rect.y + rect.height;
		
		glPushMatrix();
		glLoadIdentity();
		float add = !enabled ? -0.3 : 0.0;
		glColor4f([ overlay redComponent ] + add, [ overlay greenComponent ] + add,
				  [ overlay blueComponent ] + add, [ background[0] alphaComponent ]);
		glEnable(GL_TEXTURE_2D);
		glBindTexture(GL_TEXTURE_2D, img);
		glVertexPointer(2, GL_FLOAT, 0, square);
		glEnableClientState(GL_VERTEX_ARRAY);
		GLfloat coordinates[] = { 0, 0, 1, 0, 0, 1, 1, 1 };
		glTexCoordPointer(2, GL_FLOAT, 0, coordinates);
		glEnableClientState(GL_TEXTURE_COORD_ARRAY);
		glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
		glDisableClientState(GL_VERTEX_ARRAY);
		glDisableClientState(GL_TEXTURE_COORD_ARRAY);
		glDisable(GL_TEXTURE_2D);
		glLoadIdentity();
		glPopMatrix();
	}
	else
		[ super drawView ];
	if (down)
	{
		float square[8];
		square[0] = frame.x;
		square[1] = frame.y;
		square[2] = frame.x + frame.width;
		square[3] = frame.y;
		square[4] = frame.x + frame.width;
		square[5] = frame.y + frame.height;
		square[6] = frame.x;
		square[7] = frame.y + frame.height;
		
		float colors[16];
		for (int z = 0; z < 4; z++)
		{
			float add = !enabled ? -0.3 : 0.0;
			colors[(z * 4)] = add;
			colors[(z * 4) + 1] = add;
			colors[(z * 4) + 2] = add;
			colors[(z * 4) + 3] = [ background[z] alphaComponent ];
		}
		
		glVertexPointer(2, GL_FLOAT, 0, square);
		glEnableClientState(GL_VERTEX_ARRAY);
		glColorPointer(4, GL_FLOAT, 0, colors);
		glEnableClientState(GL_COLOR_ARRAY);
		
		// Draw
		glDrawArrays(GL_LINE_LOOP, 0, 4);
		
		glDisableClientState(GL_VERTEX_ARRAY);
		glDisableClientState(GL_COLOR_ARRAY);
	}
	
	if (text && [ text length ] != 0)
	{
		float middle = frame.y + dimenW;
		if ((!image || [ image length ] == 0) && img == 0)
			middle += dimenW / 2.0;
		float add = !enabled ? -0.3 : 0.0;
		
		if (!glStr)
		{
			glStr = LoadString(text, [ NSColor colorWithCalibratedRed:
				[ textColor redComponent ] + add green:[ textColor greenComponent ] + add
				blue:[ textColor blueComponent ] + add alpha:[ textColor alphaComponent ] ],
							   textFont);
		}
		DrawString(glStr, NSMakePoint(frame.x + (frame.width / 2), middle),
				   NSCenterTextAlignment, 0);
	}
	if (continuous && down && target != nil && [ target respondsToSelector:action ] &&
		(fpsCounter % ccount) == 0)
		[ target performSelector:action ];
	fpsCounter++;
	if (fpsCounter >= 3600)
		fpsCounter -= 3600;
}

- (void) dealloc
{
	if (image)
	{
		[ image release ];
		image = nil;
	}
	if (img != 0)
	{
		GLboolean is = false;
		glAreTexturesResident(1, &img, &is);
		if (is)
			glDeleteTextures(1, &img);
			
	}
	if (overlay)
	{
		[ overlay release ];
		overlay = nil;
	}
	[ super dealloc ];
}

@end
