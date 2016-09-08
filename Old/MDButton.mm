//
//  MDButton.m
//  MovieDraw
//
//  Created by MILAP on 7/9/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MDButton.h"


@implementation MDButton

+ (id) mdButton
{
	MDButton* view = [ [ [ MDButton alloc ] init ] autorelease ];
	return view;
}

+ (id) mdButtonWithFrame: (MDRect)rect background: (NSColor*)bkg;
{
	MDButton* view = [ [ [ MDButton alloc ] initWithFrame:rect
												   background:bkg ] autorelease ];
	return view;
}

- (id) init
{
	if ((self = [ super init ]))
	{
		background[0] = [ MD_BUTTON_DEFAULT_BUTTON_COLOR retain ];
		background[1] = [ MD_BUTTON_DEFAULT_BUTTON_COLOR2 retain ];
		mouseDownColor = [ MD_BUTTON_DEFAULT_DOWN_COLOR retain ];
		mouseDownColor2 = [ MD_BUTTON_DEFAULT_DOWN_COLOR2 retain ];
		borderColor = [ MD_BUTTON_DEFAULT_BORDER_COLOR retain ];
		borderDownColor = [ MD_BUTTON_DEFAULT_BORDER_COLOR2 retain ];
		changed = TRUE;
		type = MDButtonTypeNormal;
		
		verticies = (float*)malloc(sizeof(float) * 82);
		bverticies = (float*)malloc(sizeof(float) * 82);
		colors = (float*)malloc(sizeof(float) * 41 * 4);
		bcolors = (float*)malloc(sizeof(float) * 41 * 4);
		return self;
	}
	return nil;
}

- (id) initWithFrame: (MDRect)rect background: (NSColor*)bkg;
{
	if ((self = [ super initWithFrame:rect background:bkg ]))
	{
		if (background[1])
			[ background[1] release ];
		background[1] = [ MD_BUTTON_DEFAULT_BUTTON_COLOR2 retain ];
		mouseDownColor = [ MD_BUTTON_DEFAULT_DOWN_COLOR retain ];
		mouseDownColor2 = [ MD_BUTTON_DEFAULT_DOWN_COLOR2 retain ];
		borderColor = [ MD_BUTTON_DEFAULT_BORDER_COLOR retain ];
		borderDownColor = [ MD_BUTTON_DEFAULT_BORDER_COLOR2 retain ];
		changed = TRUE;
		type = MDButtonTypeNormal;
		
		verticies = (float*)malloc(sizeof(float) * 82);
		bverticies = (float*)malloc(sizeof(float) * 82);
		colors = (float*)malloc(sizeof(float) * 41 * 4);
		bcolors = (float*)malloc(sizeof(float) * 41 * 4);
		return self;
	}
	return nil;
}

- (void) setMouseColor:(NSColor*)color
{
	if (mouseDownColor)
		[ mouseDownColor release ];
	mouseDownColor = [ color retain ];
}

- (void) setMouseColor2:(NSColor *)color
{
	if (mouseDownColor2)
		[ mouseDownColor2 release ];
	mouseDownColor2 = [ color retain ];
}

- (NSColor*) mouseColor
{
	return mouseDownColor;
}

- (NSColor*) mouseColor2
{
	return mouseDownColor2;
}

- (void) setBorderColor:(NSColor*)color
{
	if (borderColor)
		[ borderColor release ];
	borderColor = [ color retain ];
}

- (void) setBorderColor2:(NSColor*)color
{
	if (borderDownColor)
		[ borderDownColor release ];
	borderDownColor = [ color retain ];
}

- (NSColor*) borderColor
{
	return borderColor;
}

- (NSColor*) borderColor2
{
	return borderDownColor;
}

- (void) setFrame:(MDRect)rect
{
	changed = TRUE;
	[ super setFrame:rect ];
	
	// Check glStr
	if ([ glStr frameSize ].width > frame.width || [ glStr frameSize ].height > frame.height)
	{
		NSSize size = [ glStr frameSize ];
		if (size.width > frame.width)
			size.width = frame.width;
		if (size.height > frame.height)
			size.height = frame.height;
		[ glStr useStaticFrame:size ];
	}
	else
		[ glStr useDynamicFrame ];
}

- (void) setEnabled:(BOOL)en
{
	if (enabled != en)
		changed = TRUE;
	[ super setEnabled:en ];
}

- (void) mouseDown: (NSEvent*)event
{
	if (!visible || !enabled)
		return;
	down = FALSE;
	up = TRUE;
	NSPoint point = [ event locationInWindow ];
	point.x -= origin.x;
	point.y -= origin.y;
	point.x *= resolution.width / windowSize.width;
	point.y *= resolution.height / windowSize.height;
	point.y += 2;
	
	if (type == MDButtonTypeSquare)
	{
		if (point.x >= frame.x && point.x <= frame.x + frame.width &&
			point.y >= frame.y && point.y <= frame.y + frame.height)
		{
			down = TRUE;
			up = FALSE;
			realDown = TRUE;
			if (continuous && target != nil)
				[ target performSelector:action withObject:self ];
		}
		
		if (down)
			changed = TRUE;
		
		return;
	}
	else if (type == MDButtonTypeCircle)
	{
		float a = (frame.width / 2);
		float b = (frame.height / 2);
		NSPoint foci[2];
		if (a >= b)
		{
			foci[0] = NSMakePoint(frame.x + (frame.width / 2) + sqrt(pow(a, 2) - pow(b, 2)), frame.y + (frame.height / 2));
			foci[1] = NSMakePoint(frame.x + (frame.width / 2) - sqrt(pow(a, 2) - pow(b, 2)), frame.y + (frame.height / 2));
		}
		else
		{
			foci[0] = NSMakePoint(frame.x + (frame.width / 2), frame.y + (frame.height / 2) + sqrt(pow(b, 2) - pow(a, 2)));
			foci[1] = NSMakePoint(frame.x + (frame.width / 2), frame.y + (frame.height / 2) - sqrt(pow(b, 2) - pow(a, 2)));
		}
		
		if ((distanceB(point, foci[0]) + distanceB(point, foci[1])) <= (distanceB(NSMakePoint(frame.x, frame.y + (frame.height / 2)), foci[0]) + distanceB(NSMakePoint(frame.x, frame.y + (frame.height / 2)), foci[1])))
		{
			down = TRUE;
			up = FALSE;
			realDown = TRUE;
			if (continuous && target != nil)
				[ target performSelector:action withObject:self ];
			changed = TRUE;
		}
		
		return;
	}
	
	// Check to see if point really is in oval
	BOOL isDown = FALSE;
	if (point.x >= (frame.x + 3.5) && point.x <= (frame.x + frame.width - 3.5) &&
		point.y >= frame.y && point.y <= frame.y + frame.height)
		isDown = TRUE;
	else if (point.x >= frame.x && point.x <= frame.x + frame.width &&
				point.y >= frame.y + 3.5 && point.y <= frame.y + frame.height - 3.5)
		isDown = TRUE;
	else
	{
		NSPoint centers[4] = { NSMakePoint(frame.x + 3.5, frame.y + 3.5), NSMakePoint(frame.x + frame.width - 3.5, frame.y + 3.5), NSMakePoint(frame.x + frame.width - 3.5, frame.y + frame.height - 3.5), NSMakePoint(frame.x + 3.5, frame.y + frame.height - 3.5) };
		for (int z = 0; z < 4; z++)
		{
			float dist = distanceB(centers[z], point);
			if (dist <= 3.5)
			{
				isDown = TRUE;
				break;
			}
		}
			
	}

	if (isDown)
	{
		down = TRUE;
		up = FALSE;
		realDown = TRUE;
		if (continuous && target != nil)
			[ target performSelector:action withObject:self ];
		changed = TRUE;
	}
}

- (void) mouseDragged:(NSEvent *)event
{
	if (!visible || !enabled || up)
		return;
	
	BOOL ldown = down;
	
	NSPoint point = [ event locationInWindow ];
	point.x -= origin.x;
	point.y -= origin.y;
	point.x *= resolution.width / windowSize.width;
	point.y *= resolution.height / windowSize.height;
	point.y += 2;
	
	down = FALSE;
	if (type == MDButtonTypeSquare)
	{
		if (point.x >= frame.x && point.x <= frame.x + frame.width &&
			point.y >= frame.y && point.y <= frame.y + frame.height)
			down = TRUE;
		
		if (ldown != down)
			changed = TRUE;
		
		return;
	}
	else if (type == MDButtonTypeCircle)
	{
		float a = (frame.width / 2);
		float b = (frame.height / 2);
		NSPoint foci[2];
		if (a >= b)
		{
			foci[0] = NSMakePoint(frame.x + (frame.width / 2) + sqrt(pow(a, 2) - pow(b, 2)), frame.y + (frame.height / 2));
			foci[1] = NSMakePoint(frame.x + (frame.width / 2) - sqrt(pow(a, 2) - pow(b, 2)), frame.y + (frame.height / 2));
		}
		else
		{
			foci[0] = NSMakePoint(frame.x + (frame.width / 2), frame.y + (frame.height / 2) + sqrt(pow(b, 2) - pow(a, 2)));
			foci[1] = NSMakePoint(frame.x + (frame.width / 2), frame.y + (frame.height / 2) - sqrt(pow(b, 2) - pow(a, 2)));
		}
		
		if ((distanceB(point, foci[0]) + distanceB(point, foci[1])) <= (distanceB(NSMakePoint(frame.x, frame.y + (frame.height / 2)), foci[0]) + distanceB(NSMakePoint(frame.x, frame.y + (frame.height / 2)), foci[1])))
			down = TRUE;
		
		if (ldown != down)
			changed = TRUE;
		
		return;
	}
	
	// Check to see if point really is in oval
	BOOL isDown = FALSE;
	if (point.x >= (frame.x + 3.5) && point.x <= (frame.x + frame.width - 3.5) &&
		point.y >= frame.y && point.y <= frame.y + frame.height)
		isDown = TRUE;
	else if (point.x >= frame.x && point.x <= frame.x + frame.width &&
			 point.y >= frame.y + 3.5 && point.y <= frame.y + frame.height - 3.5)
		isDown = TRUE;
	else
	{
		NSPoint centers[4] = { NSMakePoint(frame.x + 3.5, frame.y + 3.5), NSMakePoint(frame.x + frame.width - 3.5, frame.y + 3.5), NSMakePoint(frame.x + frame.width - 3.5, frame.y + frame.height - 3.5), NSMakePoint(frame.x + 3.5, frame.y + frame.height - 3.5) };
		for (int z = 0; z < 4; z++)
		{
			float dist = distanceB(centers[z], point);
			if (dist <= 3.5)
			{
				isDown = TRUE;
				break;
			}
		}
		
	}
	
	if (isDown)
		down = TRUE;
	
	if (ldown != down)
		changed = TRUE;
}

- (void) mouseUp:(NSEvent *)event
{
	if (!visible || !enabled)
		return;

	if (down)
		changed = TRUE;
	
	NSPoint point = [ event locationInWindow ];
	point.x -= origin.x;
	point.y -= origin.y;
	point.x *= resolution.width / windowSize.width;
	point.y *= resolution.height / windowSize.height;
	point.y += 2;
	
	down = FALSE;
	if (type == MDButtonTypeSquare)
	{
		if (point.x >= frame.x && point.x <= frame.x + frame.width &&
			point.y >= frame.y && point.y <= frame.y + frame.height)
			down = TRUE;
		
		if (down && target != nil && !continuous)
			[ target performSelector:action withObject:self ];
		down = FALSE;
		up = TRUE;
		realDown = FALSE;
		return;
	}
	else if (type == MDButtonTypeCircle)
	{
		float a = (frame.width / 2);
		float b = (frame.height / 2);
		NSPoint foci[2];
		if (a >= b)
		{
			foci[0] = NSMakePoint(frame.x + (frame.width / 2) + sqrt(pow(a, 2) - pow(b, 2)), frame.y + (frame.height / 2));
			foci[1] = NSMakePoint(frame.x + (frame.width / 2) - sqrt(pow(a, 2) - pow(b, 2)), frame.y + (frame.height / 2));
		}
		else
		{
			foci[0] = NSMakePoint(frame.x + (frame.width / 2), frame.y + (frame.height / 2) + sqrt(pow(b, 2) - pow(a, 2)));
			foci[1] = NSMakePoint(frame.x + (frame.width / 2), frame.y + (frame.height / 2) - sqrt(pow(b, 2) - pow(a, 2)));
		}
		
		if ((distanceB(point, foci[0]) + distanceB(point, foci[1])) <= (distanceB(NSMakePoint(frame.x, frame.y + (frame.height / 2)), foci[0]) + distanceB(NSMakePoint(frame.x, frame.y + (frame.height / 2)), foci[1])))
			down = TRUE;
		
		if (down && target != nil && !continuous)
			[ target performSelector:action withObject:self ];
		down = FALSE;
		up = TRUE;
		realDown = FALSE;
		return;
	}
	
	// Check to see if point really is in oval
	BOOL isDown = FALSE;
	if (point.x >= (frame.x + 3.5) && point.x <= (frame.x + frame.width - 3.5) &&
		point.y >= frame.y && point.y <= frame.y + frame.height)
		isDown = TRUE;
	else if (point.x >= frame.x && point.x <= frame.x + frame.width &&
			 point.y >= frame.y + 3.5 && point.y <= frame.y + frame.height - 3.5)
		isDown = TRUE;
	else
	{
		NSPoint centers[4] = { NSMakePoint(frame.x + 3.5, frame.y + 3.5), NSMakePoint(frame.x + frame.width - 3.5, frame.y + 3.5), NSMakePoint(frame.x + frame.width - 3.5, frame.y + frame.height - 3.5), NSMakePoint(frame.x + 3.5, frame.y + frame.height - 3.5) };
		for (int z = 0; z < 4; z++)
		{
			float dist = distanceB(centers[z], point);
			if (dist <= 3.5)
			{
				isDown = TRUE;
				break;
			}
		}
	}
	if (isDown)
	{
		if (realDown && target != nil && !continuous)
			[ target performSelector:action withObject:self ];
	}
	
	down = FALSE;
	up = TRUE;
	realDown = FALSE;
}

- (void) setButtonType:(MDButtonType)ty
{
	type = ty;
	changed = TRUE;
}

- (MDButtonType) type
{
	return type;
}

- (void) updateAnimation
{
	float stime = 60;
	float time = mtime / stime;
	if (mup)
	{
		NSColor* high1 = MD_BUTTON_DEFAULT_ANIMATION_HIGH;
		NSColor* high2 = MD_BUTTON_DEFAULT_ANIMATION_HIGH2;
		NSColor* low1 = MD_BUTTON_DEFAULT_ANIMATION_LOW;
		NSColor* low2 = MD_BUTTON_DEFAULT_ANIMATION_LOW2;
		
		float red1 = [ low1 redComponent ] - (([ low1 redComponent ] - [ high1 redComponent ]) * time);
		float green1 = [ low1 greenComponent ] - (([ low1 greenComponent ] - [ high1 greenComponent ]) * time);
		float blue1 = [ low1 blueComponent ] - (([ low1 blueComponent ] - [ high1 blueComponent ]) * time);
		float alpha1 = [ low1 alphaComponent ] - (([ low1 alphaComponent ] - [ high1 alphaComponent ]) * time);
		NSColor* current1 = [ NSColor colorWithCalibratedRed:red1 green:green1 blue:blue1 alpha:alpha1 ];
		float red2 = [ low2 redComponent ] - (([ low2 redComponent ] - [ high2 redComponent ]) * time);
		float green2 = [ low2 greenComponent ] - (([ low2 greenComponent ] - [ high2 greenComponent ]) * time);
		float blue2 = [ low2 blueComponent ] - (([ low2 blueComponent ] - [ high2 blueComponent ]) * time);
		float alpha2 = [ low2 alphaComponent ] - (([ low2 alphaComponent ] - [ high2 alphaComponent ]) * time);
		NSColor* current2 = [ NSColor colorWithCalibratedRed:red2 green:green2 blue:blue2 alpha:alpha2 ];
		
		if (background[0])
			[ background[0] release ];
		background[0] = [ current1 retain ];
		if (background[1])
			[ background[1] release ];
		background[1] = [ current2 retain ];
	}
	else
	{
		NSColor* high1 = MD_BUTTON_DEFAULT_ANIMATION_HIGH;
		NSColor* high2 = MD_BUTTON_DEFAULT_ANIMATION_HIGH2;
		NSColor* low1 = MD_BUTTON_DEFAULT_ANIMATION_LOW;
		NSColor* low2 = MD_BUTTON_DEFAULT_ANIMATION_LOW2;
		
		float red1 = [ high1 redComponent ] - (([ high1 redComponent ] - [ low1 redComponent ]) * time);
		float green1 = [ high1 greenComponent ] - (([ high1 greenComponent ] - [ low1 greenComponent ]) * time);
		float blue1 = [ high1 blueComponent ] - (([ high1 blueComponent ] - [ low1 blueComponent ]) * time);
		float alpha1 = [ high1 alphaComponent ] - (([ high1 alphaComponent ] - [ low1 alphaComponent ]) * time);
		NSColor* current1 = [ NSColor colorWithCalibratedRed:red1 green:green1 blue:blue1 alpha:alpha1 ];
		float red2 = [ high2 redComponent ] - (([ high2 redComponent ] - [ low2 redComponent ]) * time);
		float green2 = [ high2 greenComponent ] - (([ high2 greenComponent ] - [ low2 greenComponent ]) * time);
		float blue2 = [ high2 blueComponent ] - (([ high2 blueComponent ] - [ low2 blueComponent ]) * time);
		float alpha2 = [ high2 alphaComponent ] - (([ high2 alphaComponent ] - [ low2 alphaComponent ]) * time);
		NSColor* current2 = [ NSColor colorWithCalibratedRed:red2 green:green2 blue:blue2 alpha:alpha2 ];
		
		if (background[0])
			[ background[0] release ];
		background[0] = [ current1 retain ];
		if (background[1])
			[ background[1] release ];
		background[1] = [ current2 retain ];
	}
	
	mtime++;
	if (stime == mtime)
	{
		mtime = 0;
		mup = !mup;
	}
}

- (void) setIsDefault:(BOOL)def
{
	isDefault = def;
	if (!isDefault)
	{
		if (background[0])
			[ background[0] release ];
		background[0] = [ MD_BUTTON_DEFAULT_BUTTON_COLOR retain ];
		if (background[1])
			[ background[1] release ];
		background[1] = [ MD_BUTTON_DEFAULT_BUTTON_COLOR2 retain ];
		if (borderColor)
			[ borderColor release ];
		borderColor = [ MD_BUTTON_DEFAULT_BORDER_COLOR retain ];
		if (animationTimer)
		{
			[ animationTimer invalidate ];
			animationTimer = nil;
		}
	}
	else
	{
		if (background[0])
			[ background[0] release ];
		background[0] = [ MD_BUTTON_DEFAULT_ANIMATION_HIGH retain ];
		if (background[1])
			[ background[1] release ];
		background[1] = [ MD_BUTTON_DEFAULT_ANIMATION_HIGH2 retain ];
		if (borderColor)
			[ borderColor release ];
		borderColor = [ MD_BUTTON_DEFAULT_BORDER_COLOR2 retain ];
		
		animationTimer = [ NSTimer scheduledTimerWithTimeInterval:1 / 60.0 target:self selector:@selector(updateAnimation) userInfo:nil repeats:YES ];
	}
	
	changed = TRUE;
}

- (BOOL) isDefault
{
	return isDefault;
}

- (void) drawView
{
	if (!visible)
		return;
	
	if (changed && type == MDButtonTypeNormal)
	{
		memset(verticies, 0, 82);
		verticies[0] = frame.x + 3.5;
		verticies[1] = frame.y + frame.height;
		for (int i = 0; i <= 18; i += 2)
		{
			float angle = (i * 5);
			float rad = (M_PI * angle / 180.0);
			verticies[2 + i] = ((frame.x + frame.width - 3.5) + (sin(rad) * 3.5));
			verticies[3 + i] = ((frame.y + frame.height - 3.5) + (cos(rad) * 3.5));
		}
		for (int i = 0; i <= 18; i += 2)
		{
			float angle = (i * 5);
			float rad = (M_PI * angle / 180.0);
			verticies[22 + i] = ((frame.x + frame.width - 3.5) + (cos(rad) * 3.5));
			verticies[23 + i] = ((frame.y + 3.5) - (sin(rad) * 3.5));
		}
		for (int i = 0; i <= 18; i += 2)
		{
			float angle = (i * 5);
			float rad = (M_PI * angle / 180.0);
			verticies[42 + i] = ((frame.x + 3.5) - (sin(rad) * 3.5));
			verticies[43 + i] = ((frame.y + 3.5) - (cos(rad) * 3.5));
		}
		for (int i = 0; i <= 18; i += 2)
		{
			float angle = (i * 5);
			float rad = (M_PI * angle / 180.0);
			verticies[62 + i] = ((frame.x + 3.5) - (cos(rad) * 3.5));
			verticies[63 + i] = ((frame.y + frame.height - 3.5) + (sin(rad) * 3.5));
		}
		
		
		float lane = 2.5;
		memset(bverticies, 0, 82);
		bverticies[0] = frame.x + lane;
		bverticies[1] = frame.y + frame.height + 1;
		for (int i = 0; i <= 18; i += 2)
		{
			float angle = (i * 5);
			float rad = (M_PI * angle / 180.0);
			bverticies[2 + i] = ((frame.x + frame.width - lane) + (sin(rad) * 3.5));
			bverticies[3 + i] = ((frame.y + frame.height - lane) + (cos(rad) * 3.5));
		}
		for (int i = 0; i <= 18; i += 2)
		{
			float angle = (i * 5);
			float rad = (M_PI * angle / 180.0);
			bverticies[22 + i] = ((frame.x + frame.width - lane) + (cos(rad) * 3.5));
			bverticies[23 + i] = ((frame.y + lane) - (sin(rad) * 3.5));
		}
		for (int i = 0; i <= 18; i += 2)
		{
			float angle = (i * 5);
			float rad = (M_PI * angle / 180.0);
			bverticies[42 + i] = ((frame.x + lane) - (sin(rad) * 3.5));
			bverticies[43 + i] = ((frame.y + lane) - (cos(rad) * 3.5));
		}
		for (int i = 0; i <= 18; i += 2)
		{
			float angle = (i * 5);
			float rad = (M_PI * angle / 180.0);
			bverticies[62 + i] = ((frame.x + lane) - (cos(rad) * 3.5));
			bverticies[63 + i] = ((frame.y + frame.height - lane) + (sin(rad) * 3.5));
		}
		
		for (int z = 0; z < 41; z++)
		{
			float add = !enabled ? -0.047059 : 0.0;
			
			NSColor* color = background[0];
			if (down)
				color = mouseDownColor;
			colors[(z * 4)] = [ color redComponent ] + add;
			colors[(z * 4) + 1] = [ color greenComponent ] + add;
			colors[(z * 4) + 2] = [ color blueComponent ] + add;
			colors[(z * 4) + 3] = [ color alphaComponent ];
			
			NSColor* bcolor = borderColor;
			if (down)
				bcolor = borderDownColor;
			bcolors[(z * 4)] = [ bcolor redComponent ] + add;
			bcolors[(z * 4) + 1] = [ bcolor greenComponent ] + add;
			bcolors[(z * 4) + 2] = [ bcolor blueComponent ] + add;
			bcolors[(z * 4) + 3] = [ bcolor alphaComponent ];
		}
		changed = FALSE;
	}
	else if (changed && type == MDButtonTypeCircle)
	{
		memset(verticies, 0, 82);
		verticies[0] = frame.x + (frame.width / 2);
		verticies[1] = frame.y + (frame.height / 2);
		for (int i = 0; i < 72; i += 2)
		{
			float angle = (i * 5);
			float rad = angle / 180 * M_PI;
			verticies[i + 2] = frame.x + (frame.width / 2) + (cos(rad) * frame.width / 2);
			verticies[i + 3] = frame.y + (frame.height / 2) + (sin(rad) * frame.height / 2);
		}
		verticies[74] = frame.x + frame.width;
		verticies[75] = frame.y + (frame.height / 2);
		
		float lane = 1;
		memset(bverticies, 0, 82);
		bverticies[0] = frame.x + (frame.width / 2);
		bverticies[1] = frame.y + (frame.height / 2);
		for (int i = 0; i < 72; i += 2)
		{
			float angle = (i * 5);
			float rad = angle / 180 * M_PI;
			bverticies[i + 2] = frame.x + (frame.width / 2) + (cos(rad) * (frame.width / 2 + lane));
			bverticies[i + 3] = frame.y + (frame.height / 2) + (sin(rad) * (frame.height / 2 + lane));
		}
		bverticies[74] = frame.x + frame.width + lane;
		bverticies[75] = frame.y + (frame.height / 2);
		
		for (int z = 0; z < 38; z++)
		{
			float add = !enabled ? -0.047059 : 0.0;
			
			NSColor* color = background[0];
			if (down)
				color = mouseDownColor;
			colors[(z * 4)] = [ color redComponent ] + add;
			colors[(z * 4) + 1] = [ color greenComponent ] + add;
			colors[(z * 4) + 2] = [ color blueComponent ] + add;
			colors[(z * 4) + 3] = [ color alphaComponent ];
			
			NSColor* bcolor = borderColor;
			if (down)
				bcolor = borderDownColor;
			bcolors[(z * 4)] = [ bcolor redComponent ] + add;
			bcolors[(z * 4) + 1] = [ bcolor greenComponent ] + add;
			bcolors[(z * 4) + 2] = [ bcolor blueComponent ] + add;
			bcolors[(z * 4) + 3] = [ bcolor alphaComponent ];
		}
		changed = FALSE;
	}

	if (type == MDButtonTypeNormal)
	{
		glLoadIdentity();
		
		glEnableClientState(GL_VERTEX_ARRAY);
		glEnableClientState(GL_COLOR_ARRAY);
		
		glVertexPointer(2, GL_FLOAT, 0, bverticies);
		glColorPointer(4, GL_FLOAT, 0, bcolors);
		glDrawArrays(GL_TRIANGLE_FAN, 0, 41);
		
		glVertexPointer(2, GL_FLOAT, 0, verticies);
		glColorPointer(4, GL_FLOAT, 0, colors);
		
		// Draw
		glDrawArrays(GL_TRIANGLE_FAN, 0, 41);
		
		glDisableClientState(GL_VERTEX_ARRAY);
		glDisableClientState(GL_COLOR_ARRAY);
		
		if (enabled)
		{
			glLoadIdentity();
			glTranslated(frame.x, frame.y + (frame.height / 2) - 0.5, 0);
			NSColor* color = background[0];
			if (down)
				color = mouseDownColor;
			glBegin(GL_QUADS);
			{
				glColor4d([ color redComponent ], [ color greenComponent ], [ color blueComponent ], [ color alphaComponent ]);
				glVertex2d(frame.width, (frame.height / 2) - 3);
				glVertex2d(0, (frame.height / 2) - 3);
				color = background[1];
				if (down)
					color = mouseDownColor2;
				glColor4d([ color redComponent ], [ color greenComponent ], [ color blueComponent ], [ color alphaComponent ]);
				glVertex2d(0, 0);
				glVertex2d(frame.width, 0);
				
				glVertex2d(0, 0);
				glVertex2d(frame.width, 0);
				color = background[0];
				if (down)
					color = mouseDownColor;
				glColor4d([ color redComponent ], [ color greenComponent ], [ color blueComponent ], [ color alphaComponent ]);
				glVertex2d(frame.width, -(frame.height / 2) + 4);
				glVertex2d(0, -(frame.height / 2) + 4);
			}
			glEnd();
		}
	}
	else if (type == MDButtonTypeCircle)
	{
		glLoadIdentity();
		
		glEnableClientState(GL_VERTEX_ARRAY);
		glEnableClientState(GL_COLOR_ARRAY);
		
		glVertexPointer(2, GL_FLOAT, 0, bverticies);
		glColorPointer(4, GL_FLOAT, 0, bcolors);
		glDrawArrays(GL_TRIANGLE_FAN, 0, 38);
		
		glVertexPointer(2, GL_FLOAT, 0, verticies);
		glColorPointer(4, GL_FLOAT, 0, colors);
		glDrawArrays(GL_TRIANGLE_FAN, 0, 38);
		
		if (enabled)
		{
			glLoadIdentity();
			glTranslated(frame.x + (frame.width / 2), frame.y + (frame.height / 2) - 0.5, 0);
			NSColor* color = background[1];
			if (down)
				color = mouseDownColor2;
			
			float red1 = [ color redComponent ], green1 = [ color greenComponent ], blue1 = [ color blueComponent ], alpha1 = [ color alphaComponent ];
			color = background[0];
			if (down)
				color = mouseDownColor;
			float red2 = [ color redComponent ], green2 = [ color greenComponent ], blue2 = [ color blueComponent ], alpha2 = [ color alphaComponent ];
			float totalNumber = (unsigned int)(frame.width / 3);
			float eachHeight = (frame.height - 7) / totalNumber / 2;
			for (unsigned z = 0; z < (unsigned int)totalNumber; z++)
			{
				float angle1 = asinf((eachHeight * z) / (frame.height / 2));
				float angle2 = asinf((eachHeight * (z + 1)) / (frame.height / 2));
				glBegin(GL_QUADS);
				{
					float red_1 = (red2 - red1) * (z / (float)totalNumber) + red1;
					float green_1 = (green2 - green1) * (z / (float)totalNumber) + green1;
					float blue_1 = (blue2 - blue1) * (z / (float)totalNumber) + blue1;
					float alpha_1 = (alpha2 - alpha1) * (z / (float)totalNumber) + alpha1;
					
					float red_2 = (red2 - red1) * ((z + 1) / (float)totalNumber) + red1;
					float green_2 = (green2 - green1) * ((z + 1) / (float)totalNumber) + green1;
					float blue_2 = (blue2 - blue1) * ((z + 1) / (float)totalNumber) + blue1;
					float alpha_2 = (alpha2 - alpha1) * ((z + 1) / (float)totalNumber) + alpha1;
					
					glColor4d(red_1, green_1, blue_1, alpha_1);
					glVertex2d(cos(angle1) * frame.width / 2, eachHeight * z);
					glVertex2d(-cos(angle1) * frame.width / 2, eachHeight * z);
					glColor4d(red_2, green_2, blue_2, alpha_2);
					glVertex2d(-cos(angle2) * frame.width / 2, eachHeight * (z + 1));
					glVertex2d(cos(angle2) * frame.width / 2, eachHeight * (z + 1));
					
					glColor4d(red_1, green_1, blue_1, alpha_1);
					glVertex2d(cos(angle1) * frame.width / 2, -eachHeight * z);
					glVertex2d(-cos(angle1) * frame.width / 2, -eachHeight * z);
					glColor4d(red_2, green_2, blue_2, alpha_2);
					glVertex2d(-cos(angle2) * frame.width / 2, -eachHeight * (z + 1));
					glVertex2d(cos(angle2) * frame.width / 2, -eachHeight * (z + 1));
				}
				glEnd();
			}
			
		/*	glBegin(GL_QUADS);
			{
				glColor4d([ color redComponent ], [ color greenComponent ], [ color blueComponent ], [ color alphaComponent ]);
				glVertex2d(frame.width - 5, (frame.height / 2) - 3);
				glVertex2d(5, (frame.height / 2) - 3);
				color = background[1];
				if (down)
					color = mouseDownColor2;
				glColor4d([ color redComponent ], [ color greenComponent ], [ color blueComponent ], [ color alphaComponent ]);
				glVertex2d(5, 0);
				glVertex2d(frame.width - 5, 0);
				
				glVertex2d(5, 0);
				glVertex2d(frame.width - 5, 0);
				color = background[0];
				if (down)
					color = mouseDownColor;
				glColor4d([ color redComponent ], [ color greenComponent ], [ color blueComponent ], [ color alphaComponent ]);
				glVertex2d(frame.width - 5, -(frame.height / 2) + 4);
				glVertex2d(5, -(frame.height / 2) + 4);
			}
			glEnd();*/
		}
		
		glDisableClientState(GL_VERTEX_ARRAY);
		glDisableClientState(GL_COLOR_ARRAY);
	}
	else
	{
		float square[8];
		square[0] = frame.x;
		square[1] = frame.y;
		square[2] = frame.x + frame.width;
		square[3] = frame.y;
		square[4] = frame.x;
		square[5] = frame.y + frame.height;
		square[6] = frame.x + frame.width;
		square[7] = frame.y + frame.height;
		
		float colors1[16];
		for (int z = 0; z < 4; z++)
		{
			float add = !enabled ? -0.3 : 0.0;
			
			if (down && enabled)
			{
				colors1[(z * 4)] = [ mouseDownColor redComponent ] + add;
				colors1[(z * 4) + 1] = [ mouseDownColor greenComponent ] + add;
				colors1[(z * 4) + 2] = [ mouseDownColor blueComponent ] + add;
				colors1[(z * 4) + 3] = [ mouseDownColor alphaComponent ];
			}
			else
			{
				colors1[(z * 4)] = [ background[z] redComponent ] + add;
				colors1[(z * 4) + 1] = [ background[z] greenComponent ] + add;
				colors1[(z * 4) + 2] = [ background[z] blueComponent ] + add;
				colors1[(z * 4) + 3] = [ background[z] alphaComponent ];
			}
		}
		
		glLoadIdentity();
		glVertexPointer(2, GL_FLOAT, 0, square);
		glEnableClientState(GL_VERTEX_ARRAY);
		glColorPointer(4, GL_FLOAT, 0, colors1);
		glEnableClientState(GL_COLOR_ARRAY);
		glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
		glDisableClientState(GL_VERTEX_ARRAY);
		glDisableClientState(GL_COLOR_ARRAY);
	}
	
	if (!glStr)
		glStr = LoadString(text, textColor, textFont);
	DrawString(glStr, NSMakePoint(frame.x + (frame.width / 2), frame.y + (frame.height / 2)),
			   NSCenterTextAlignment, 0);
	
	if (continuous && down && target != nil && [ target respondsToSelector:action ] &&
		(fpsCounter % ccount) == 0)
		[ target performSelector:action ];
	fpsCounter++;
	if (fpsCounter >= 3600)
		fpsCounter -= 3600;
}

- (void) dealloc
{
	if (mouseDownColor)
	{
		[ mouseDownColor release ];
		mouseDownColor = nil;
	}
	if (mouseDownColor2)
	{
		[ mouseDownColor2 release ];
		mouseDownColor2 = nil;
	}
	if (borderColor)
	{
		[ borderColor release ];
		borderColor = nil;
	}
	if (borderDownColor)
	{
		[ borderDownColor release ];
		borderDownColor = nil;
	}
	if (verticies)
	{
		free(verticies);
		verticies = NULL;
	}
	if (bverticies)
	{
		free(bverticies);
		bverticies = NULL;
	}
	if (colors)
	{
		free(colors);
		colors = NULL;
	}
	if (bcolors)
	{
		free(bcolors);
		bcolors = NULL;
	}
	if (animationTimer)
	{
		[ animationTimer invalidate ];
		animationTimer = nil;
	}
	
	[ super dealloc ];
}

@end
