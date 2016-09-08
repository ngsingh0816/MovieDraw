//
//  MDMovieView.mm
//  MovieDraw
//
//  Created by MILAP on 2/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MDMovieView.h"


@interface MDMovieView (InternalMethods)
- (void) sliderMoved: (id) sender;
- (void) updateTimer;
@end

@implementation MDMovieView

+ (id) mdMovieView
{
	return [ [ [ MDMovieView alloc ] init ] autorelease ];
}

+ (id) mdMovieViewWithFrame: (MDRect)rect background:(NSColor*)bkg
{
	return [ [ [ MDMovieView alloc ] initWithFrame:rect background:bkg ] autorelease ];
}

- (id) init
{
	if ((self = [ super init ]))
	{
		isPlaying = FALSE;
	}
	return self;
}

- (id) initWithFrame:(MDRect)rect background:(NSColor *)bkg
{
	if ((self = [ super initWithFrame:rect background:bkg ]))
	{
		buttons[0] = [ [ MDButton alloc ] initWithFrame:MakeRect(frame.x, frame.y, 20, 20)
			background:[ NSColor colorWithCalibratedRed:0.5 green:0.5 blue:0.5 alpha:1 ] ];
		[ buttons[0] setText:@"▶" ];
		[ buttons[0] setIdentity:@"Play" ];
		[ buttons[0] setTarget:self ];
		[ buttons[0] setAction:@selector(play:) ];
		[ buttons[0] setButtonType:MDButtonTypeSquare ];
		
		buttons[1] = [ [ MDButton alloc ] initWithFrame:MakeRect(frame.x + 21, frame.y,20, 20)
			background:[ NSColor colorWithCalibratedRed:0.5 green:0.5 blue:0.5 alpha:1 ] ];
		[ buttons[1] setText:@"◼" ];
		[ buttons[1] setIdentity:@"Stop" ];
		[ buttons[1] setTarget:self ];
		[ buttons[1] setAction:@selector(stop:) ];
		[ buttons[1] setButtonType:MDButtonTypeSquare ];
		
		buttons[2] = [ [ MDButton alloc ] initWithFrame:MakeRect(frame.x + 42, frame.y,20, 20)
			background:[ NSColor colorWithCalibratedRed:0.5 green:0.5 blue:0.5 alpha:1 ] ];
		[ buttons[2] setText:@"<" ];
		[ buttons[2] setIdentity:@"Rewind" ];
		[ buttons[2] setTarget:self ];
		[ buttons[2] setAction:@selector(rewind:) ];
		[ buttons[2] setContinuous:NO ];
		[ buttons[2] setButtonType:MDButtonTypeSquare ];
		
		buttons[3] = [ [ MDButton alloc ] initWithFrame:MakeRect(frame.x + 63, frame.y,20, 20)
			background:[ NSColor colorWithCalibratedRed:0.5 green:0.5 blue:0.5 alpha:1 ] ];
		[ buttons[3] setText:@">" ];
		[ buttons[3] setIdentity:@"Fast Forward" ];
		[ buttons[3] setTarget:self ];
		[ buttons[3] setAction:@selector(fastForward:) ];
		[ buttons[3] setContinuous:NO ];
		[ buttons[3] setButtonType:MDButtonTypeSquare ];
		
		slider = [ [ MDSlider alloc ] initWithFrame:MakeRect(frame.x + 94, frame.y + 1,
			frame.width - 104, 18) background:[ NSColor colorWithCalibratedRed:0.2 green:0.5
																blue:1.0 alpha:1.0 ] ];
		[ slider setContinuous:YES ];
		[ slider setContinuousCount:1 ];
		[ slider setTarget:self ];
		[ slider setAction:@selector(sliderMoved:) ];
		
		progress = [ [ MDProgressBar alloc ] initWithFrame:MakeRect(frame.x + 
			(frame.width / 10), frame.y + 20 + (frame.height / 10), frame.width * 0.8,
			(frame.height - 20) * 0.8) background:[ NSColor colorWithCalibratedRed:0.7
													green:0.7 blue:0.7 alpha:1 ] ];
		[ progress setType:MD_PROGRESSBAR_NORMAL ];
		
		textures = [ [ NSMutableArray alloc ] init ];
		
		isPlaying = FALSE;
	}
	return self;	
}

- (void) updateTimer
{
	if (isPlaying)
		currentFrame++;
}

- (void) loading
{
	NSAutoreleasePool* pool = [ [ NSAutoreleasePool alloc ] init ];
	
	QTMovie* movie = [ QTMovie movieWithFile:movieName error:nil ];
	
	NSTimeInterval time = 0;
	for (;;)
	{
		QTTime qtTime = QTMakeTimeWithTimeInterval(time);
		NSImage* img = [ movie frameImageAtTime:qtTime ];
		if (!img)
			break;
		unsigned int frameImg = 0;
		LoadImage((const char*)[ [ img TIFFRepresentation ] bytes ], &frameImg, [ [ img TIFFRepresentation ] length ]);
		[ textures addObject:[ NSNumber numberWithUnsignedInt:frameImg ] ];
		time += 1 / 60.0;
	}
	currentFrame = 0;
	
	if (timer)
		[ timer invalidate ];
	timer = [ [ NSTimer scheduledTimerWithTimeInterval:1 / 60.0 target:self selector:@selector(updateTimer) userInfo:nil repeats:YES ] retain ];
	
	NSTimeInterval time2 = 0;
	QTGetTimeInterval([ movie duration ], &time2);
	[ slider setMaxValue:time2 * 60 ];
	[ progress setVisible:NO ];
	
	[ pool release ];
}

- (BOOL) loadMovie: (NSString*)path
{
	if (movieName)
		[ movieName release ];
	movieName = [ [ NSString alloc ] initWithString:path ];
	if (![ movieName hasPrefix:@"/" ])
	{
		[ movieName release ];
		movieName = [ [ NSString alloc ] initWithFormat:@"%@/%@",
					 [ [ NSBundle mainBundle ] resourcePath ], path ];
	}
	if ([ [ NSFileManager defaultManager ] fileExistsAtPath:movieName ])
	{
		[ progress setVisible:YES ];
		
		[ NSThread detachNewThreadSelector:@selector(loading) toTarget:self withObject:nil ];
		return YES;
	}
	else
	{
		[ movieName release ];
		movieName = nil;
	}
	return NO;
}

- (NSString*) loadedMovie
{
	return movieName;
}

- (void) setFrame:(MDRect)rect
{
	[ super setFrame:rect ];
	for (int z = 0; z < 4; z++)
		[ buttons[z] setFrame:MakeRect(frame.x + (z * 21), frame.y, 20, 20) ];
	[ slider setFrame:MakeRect(frame.x + 94, frame.y + 1, frame.width - 104, 18) ];
	[ progress setFrame:MakeRect(frame.x + (frame.width / 10), frame.y + 20 +
				(frame.height / 10), frame.width * 0.8, (frame.height - 20) * 0.8) ];
}

- (void) sliderMoved: (id) sender
{
	/*if (!(movieView && [ movieView movie ]))
		return;
	[ [ movieView movie ] setCurrentTime:QTMakeTimeWithTimeInterval([ slider value ]) ];*/
}

- (void) drawView
{
	if (currentFrame < [ textures count ])
		
	{
		glLoadIdentity();
		glTranslated(frame.x, frame.y + 20, 0);
		glEnable(GL_TEXTURE_2D);
		glBindTexture(GL_TEXTURE_2D, [ [ textures objectAtIndex:currentFrame ] unsignedIntValue ]);
		glColor4d(1, 1, 1, 1);
		glBegin(GL_QUADS);
		{
			glTexCoord2d(0, 0);
			glVertex2d(0, 0);
			glTexCoord2d(1, 0);
			glVertex2d(frame.width, 0);
			glTexCoord2d(1, 1);
			glVertex2d(frame.width, frame.height - 20);
			glTexCoord2d(0, 1);
			glVertex2d(0, frame.height - 20);
		}
		glEnd();
		glLoadIdentity();
		glDisable(GL_TEXTURE_2D);
	}
	else
	{
		float square1[8];
		square1[0] = frame.x;
		square1[1] = frame.y + 20;
		square1[2] = frame.x + frame.width;
		square1[3] = frame.y + 20;
		square1[4] = frame.x;
		square1[5] = frame.y + frame.height;
		square1[6] = frame.x + frame.width;
		square1[7] = frame.y + frame.height;
		
		float colors1[16];
		for (int z = 0; z < 4; z++)
		{
			colors1[z * 4] = 0;
			colors1[(z * 4) + 1] = 0;
			colors1[(z * 4) + 2] = 0;
			colors1[(z * 4) + 3] = 1.0;
		}
		
		glLoadIdentity();
		glEnable(GL_TEXTURE_2D);
		glEnableClientState(GL_VERTEX_ARRAY);
		glEnableClientState(GL_COLOR_ARRAY);
		glVertexPointer(2, GL_FLOAT, 0, square1);
		glColorPointer(4, GL_FLOAT, 0, colors1);
		glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
		glDisable(GL_TEXTURE_2D);
		glDisableClientState(GL_COLOR_ARRAY);
		glDisableClientState(GL_VERTEX_ARRAY);
		glLoadIdentity();
	}
	
	float square[8];
	square[0] = frame.x;
	square[1] = frame.y;
	square[2] = frame.x + frame.width;
	square[3] = frame.y;
	square[4] = frame.x;
	square[5] = frame.y + 20;
	square[6] = frame.x + frame.width;
	square[7] = frame.y + 20;
	
	float colors[16];
	for (int z = 0; z < 4; z++)
	{
		colors[z * 4] = 0.7;
		colors[(z * 4) + 1] = 0.7;
		colors[(z * 4) + 2] = 0.7;
		colors[(z * 4) + 3] = 1.0;
	}
	
	glLoadIdentity();
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_COLOR_ARRAY);
	glVertexPointer(2, GL_FLOAT, 0, square);
	glColorPointer(4, GL_FLOAT, 0, colors);
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	glDisableClientState(GL_COLOR_ARRAY);
	glDisableClientState(GL_VERTEX_ARRAY);
	glLoadIdentity();
	
	[ self update ];
}

- (NSSize) setUseRealSize:(BOOL)use
{
	return NSZeroSize;
}

- (void) setVolume:(float)volume
{
}

- (float) volume
{
	return 0;
}

- (void) setFinishTarget: (id) tar
{
	target = tar;
}

- (id) finishTarget
{
	return target;
}

- (void) setFinishAction: (SEL) act
{
	finishAct = act;
}

- (SEL) finishAction
{
	return finishAct;
}

- (void) play: (id) sender
{
	//if (!movieView)
	//	return;
	//[ movieView play:self ];
	playing = TRUE;
	[ buttons[0] setAction:@selector(pause:) ];
	[ buttons[0] setText:@"❚❚" ];
	isPlaying = TRUE;
}

- (void) pause:(id)sender
{
	//if (!movieView)
	//	return;
	//[ movieView pause:self ];
	playing = FALSE;
	[ buttons[0] setAction:@selector(play:) ];
	[ buttons[0] setText:@"▶" ];
	isPlaying = FALSE;
}

- (void) stop: (id) sender
{
	//if (!movieView)
	//	return;
	//[ movieView pause:self ];
	//[ movieView gotoBeginning:self ];
	playing = FALSE;
	currentFrame = 0;
	[ buttons[0] setAction:@selector(play:) ];
	[ buttons[0] setText:@"▶" ];
	isPlaying = FALSE;
	[ self update ];
}

- (void) rewind: (id) sender
{
	/*if (!movieView)
		return;
	NSTimeInterval time = 0;
	QTGetTimeInterval([ [ movieView movie ] currentTime ], &time);
	[ [ movieView movie ] setCurrentTime:QTMakeTimeWithTimeInterval(time - 1) ];
	if (isPlaying)
		[ movieView play:self ];
	[ self update ];*/
}

- (void) fastForward: (id) sender
{
	/*if (!movieView)
		return;
	NSTimeInterval time = 0;
	QTGetTimeInterval([ [ movieView movie ] currentTime ], &time);
	[ [ movieView movie ] setCurrentTime:QTMakeTimeWithTimeInterval(time + 1) ];
	if (isPlaying)
		[ movieView play:self ];
	[ self update ];*/
}

- (void) update
{
	double time = currentFrame;
	[ slider setValue:time ];
	if ((float)time >= [ slider maxValue ])
	{
		if (finish && [ finish respondsToSelector:finishAct ])
			[ finish performSelector:finishAct ];
		[ self stop:self ];
	}
}

- (void) dealloc
{
	for (int z = 0; z < 4; z++)
	{
		if (buttons[z])
			[ views removeObject:buttons[z] ];
		if (buttons[z])
		{
			[ buttons[z] release ];
			buttons[z] = nil;
		}
	}
	if (slider)
	{
		[ views removeObject:slider ];
		if (slider)
		{
			[ slider release ];
			slider = nil;
		}
	}
	if (progress)
	{
		[ views removeObject:progress ];
		if (progress)
		{
			[ progress release ];
			progress = nil;
		}
	}
	if (movieName)
	{
		[ movieName release ];
		movieName = nil;
	}
	if (timer)
	{
		[ timer invalidate ];
		timer = nil;
	}
	if (textures)
	{
		for (int z = 0; z < [ textures count ]; z++)
		{
			unsigned int image = [ [ textures objectAtIndex:z ] unsignedIntValue ];
			ReleaseImage(&image);
		}
		[ textures release ];
		textures = nil;
	}
	[ super dealloc ];
}

@end
