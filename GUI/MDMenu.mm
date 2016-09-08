//
//  MDMenu.mm
//  MovieDraw
//
//  Created by MILAP on 1/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MDMenu.h"

@implementation MDMenuItem


+ (MDMenuItem*) menuItemWithString:(NSString*)string target:(id)tar action:(SEL)sel
{
	return [ [ [ MDMenuItem alloc ] initWithString:string withTarget:tar andAction:sel ] autorelease ];
}

- (id) init
{
	if ((self = [ super init ]))
	{
		text = [ [ NSString alloc ] init ];
		target = nil;
		glStr = LoadString(text, [ NSColor whiteColor ], [ NSFont systemFontOfSize:[ NSFont systemFontSize ] ]);
		subItems = [ [ NSMutableArray alloc ] init ];
		expanded = FALSE;
		textFont = [ [ NSFont systemFontOfSize:[ NSFont systemFontSize ] ] retain ];
	}
	return self;
}

- (id) initWithString:(NSString*)str withTarget:(id)tar andAction:(SEL)sel
{
	if ((self = [ super init ]))
	{
		text = [ [ NSString alloc ] initWithString:str ];
		target = tar;
		action = sel;
		glStr = LoadString(text, [ NSColor whiteColor ], [ NSFont systemFontOfSize:[ NSFont systemFontSize ] ]);
		subItems = [ [ NSMutableArray alloc ] init ];
		textFont = [ [ NSFont systemFontOfSize:[ NSFont systemFontSize ] ] retain ];
		expanded = FALSE;
	}
	return self;
}

- (void) setText: (NSString*) str
{
	if (text)
		[ text release ];
	if (glStr)
		[ glStr release ];
	text = [ [ NSString alloc ] initWithString:str ];
	glStr = LoadString(text, [ NSColor whiteColor ], [ NSFont systemFontOfSize:[ NSFont systemFontSize ] ]);
}

- (NSString*) text
{
	return text;
}

- (void) setTextFont: (NSFont*) font
{
	if (textFont)
		[ textFont release ];
	textFont = [ font retain ];
	glStr = LoadString(text, [ NSColor whiteColor ], textFont);
}

- (NSFont*)textFont
{
	return textFont;
}

- (void) setTarget: (id) tar
{
	target = tar;
}

- (id) target
{
	return target;
}

- (void) setAction: (SEL)sel
{
	action = sel;
}

- (SEL) action
{
	return action;
}

- (void) addSubItem: (MDMenuItem*)item
{
	[ item setParent:self ];
	[ subItems addObject:item ];
}

- (void) removeSubItem: (MDMenuItem*)item
{
	[ item setParent:nil ];
	[ subItems removeObject:item ];
}

- (void) insertSubItem: (MDMenuItem*)item atIndex:(unsigned int)index
{
	if (index >= [ subItems count ])
		return;
	[ item setParent:self ];
	[ subItems insertObject:item atIndex:index ];
}

- (void) setExpanded: (BOOL)expand
{
	expanded = expand;
}

- (BOOL) expanded
{
	return expanded;
}

- (NSMutableArray*) subItems
{
	return subItems;
}

- (GLString*) glStr
{
	return glStr;
}

- (void) setFrame:(MDRect)frm
{
	frame = frm;
}
- (MDRect) frame
{
	return frame;
}

- (MDMenuItem*) parent
{
	return parent;
}

- (void) setParent: (MDMenuItem*)par
{
	parent = par; 
}

- (void) dealloc
{
	if (text)
	{
		[ text release ];
		text = nil;
	}
	if (glStr)
	{
		[ glStr release ];
		glStr = nil;
	}
	if (subItems)
	{
		[ subItems removeAllObjects ];
		[ subItems release ];
		subItems = nil;
	}
	if (textFont)
	{
		[ textFont release ];
		textFont = nil;
	}
	if (target)
		target = nil;
	if (action)
		action = nil;
	
	[ super dealloc ];
}

@end

@interface MDMenu (InternalMethods)
- (void) drawSubItems: (MDMenuItem*)item;
- (void) setExpanded: (BOOL)exp item: (MDMenuItem*)itm;
- (void) setExpanded: (BOOL)exp item: (MDMenuItem*)itm onlySubviews:(BOOL)sub;
- (MDMenuItem*) point:(NSPoint)p inItem:(MDMenuItem*)item withBars:(BOOL)bars usedBars:(BOOL*)used;
@end;


@implementation MDMenu

+ (id) mdMenu
{
	return [ [ [ MDMenu alloc ] init ] autorelease ];
}

+ (id) mdMenuWithFrame: (MDRect)rect background:(NSColor*)bkg
{
	return [ [ [ MDMenu alloc ] initWithFrame:rect background:bkg ] autorelease ];
}

- (id) init
{
	if ((self = [ super init ]))
	{
		mitems = [ [ NSMutableArray alloc ] init ];
		select = -1;
		tracking = TRUE;
		alwaysOnTop = TRUE;
	}
	return self;
}

- (void) updateAlways:(NSTimer*)timer
{
	if (alwaysOnTop)
	{
		if ([ views indexOfObject:self ] != [ views count ] - 1)
		{
			[ self retain ];
			[ views removeObject:self ];
			[ views addObject:self ];
			[ self release ];
		}
	}
}

- (id) initWithFrame:(MDRect)rect background:(NSColor *)bkg
{
	if ((self = [ super initWithFrame:rect background:bkg ]))
	{
		mitems = [ [ NSMutableArray alloc ] init ];
		select = -1;
		tracking = TRUE;
		alwaysOnTop = TRUE;
		//[ NSTimer scheduledTimerWithTimeInterval:1 / 60.0 target:self selector:@selector(updateAlways:) userInfo:0 repeats:YES ];
	}
	return self;
}

- (void) addItem:(NSString*)item target:(id)tar action:(SEL)sel
{
	[ self addItem:[ [ [ MDMenuItem alloc ] initWithString:item
												  withTarget:tar andAction:sel ] autorelease ] ];
}

- (void) removeItem:(NSString*)item
{
	for (int z = 0; z < [ mitems count ]; z++)
	{
		if ([ item isEqualToString:[ [ mitems objectAtIndex:z ] text ] ])
		{
			[ self removeMenuItem:[ mitems objectAtIndex:z ] ];
			break;
		}
	}
}

- (void) insertItem:(NSString*)item target:(id)tar action:(SEL)sel atIndex:(unsigned int)index
{
	if (index >= [ mitems count ])
		return;
	[ self insertItem:[ [ [ MDMenuItem alloc ] initWithString:item
								withTarget:tar andAction:sel ] autorelease ] atIndex:index ];
}

- (void) findFrames:(MDMenuItem*)item
{
	MDRect itemFrame = [ item frame ];
	float width = 100;
	float height = 0;
	for (int z = 0; z < [ [ item subItems ] count ]; z++)
	{
		if (width < [ [ [ [ item subItems ] objectAtIndex:z ] glStr ] frameSize ].width + 30)
		{
			width = [ [ [ [ item subItems ] objectAtIndex:z ] glStr ] frameSize ].width + 30;
			for (int y = 0; y < [ [ item subItems ] count ]; y++)
			{
				MDRect rect = [ (MDMenuItem*)[ [ item subItems ] objectAtIndex:y ] frame ];
				rect.width = width;
				[ (MDMenuItem*)[ [ item subItems ] objectAtIndex:y ] setFrame:rect ];
			}
		}
		MDRect rect = MakeRect(itemFrame.x + itemFrame.width, itemFrame.y + itemFrame.height - height - 2, width, -[ [ [ [ item subItems ] objectAtIndex:z ] glStr ] frameSize ].height);
		rect.y += rect.height;
		rect.height *= -1;
		height += rect.height;
		[ (MDMenuItem*)[ [ item subItems ] objectAtIndex:z ] setFrame:rect ];
		[ self findFrames:[ [ item subItems ] objectAtIndex:z ] ];
	}
}

- (void) addItem:(MDMenuItem*)item
{
	float x = frame.x + 10;
	if ([ mitems count ] != 0)
		x = [ (MDMenuItem*)[ mitems lastObject ] frame ].x + [ (MDMenuItem*)[ mitems lastObject ] frame ].width;
	float width = [ [ item glStr ] frameSize ].width + 5;
	MDRect frm = MakeRect(x, frame.y, width, frame.height);
	[ item setFrame:frm ];
	float height = 0;
	float wdth = 100;
	for (int z = 0; z < [ [ item subItems ] count ]; z++)
	{
		if (wdth < [ [ [ [ item subItems ] objectAtIndex:z ] glStr ] frameSize ].width + 30)
		{
			wdth = [ [ [ [ item subItems ] objectAtIndex:z ] glStr ] frameSize ].width + 30;
			for (int y = 0; y < [ [ item subItems ] count ]; y++)
			{
				MDRect rect = [ (MDMenuItem*)[ [ item subItems ] objectAtIndex:y ] frame ];
				rect.width = wdth;
				[ (MDMenuItem*)[ [ item subItems ] objectAtIndex:y ] setFrame:rect ];
			}
		}
		MDRect subFrame = MakeRect(frm.x, frm.y - height - 4, wdth, -[ [ [ [ item subItems ] objectAtIndex:z ] glStr ] frameSize ].height);
		subFrame.y += subFrame.height;
		subFrame.height *= -1;
		height += subFrame.height;
		[ (MDMenuItem*)[ [ item subItems ] objectAtIndex:z ] setFrame:subFrame ];
		[ self findFrames:[ [ item subItems ] objectAtIndex:z ] ];
	}
	[ mitems addObject:item ];
}

- (void) removeMenuItem:(MDMenuItem*)item
{
	if ([ mitems indexOfObject:item ] == [ mitems count ] - 1)
	{
		[ mitems removeObject:item ];
		return;
	}
	else
	{
		NSMutableArray* array = [ [ NSMutableArray alloc ] init ];
		for (int z = 0; z < [ mitems count ]; z++)
		{
			if ([ mitems objectAtIndex:z ] == item)
				continue;
			[ array addObject:[ mitems objectAtIndex:z ] ];
		}
		[ mitems removeAllObjects ];
		for (int z = 0; z < [ array count ]; z++)
			[ self addItem:[ array objectAtIndex:z ] ];
		[ array release ];
		array = nil;
	}
}

- (void) insertItem:(MDMenuItem*)item atIndex:(unsigned int)index;
{
	if (index >= [ mitems count ])
		return;
	NSMutableArray* array = [ [ NSMutableArray alloc ] init ];
	for (int z = 0; z < [ mitems count ]; z++)
		[ array addObject:[ mitems objectAtIndex:z ] ];
	[ array insertObject:item atIndex:index ];
	[ mitems removeAllObjects ];
	for (int z = 0; z < [ array count ]; z++)
		[ self addItem:[ array objectAtIndex:z ] ];
	[ array release ];
	array = nil;
}

- (void) addSubItem:(MDMenuItem*)item toItem:(unsigned int)index
{
	if (index >= [ mitems count ])
		return;
	[ [ mitems objectAtIndex:index ] addSubItem:item ];
}

- (void) removeSubItem:(MDMenuItem*)item fromItem:(unsigned int)index
{
	if (index >= [ mitems count ])
		return;
	[ [ mitems objectAtIndex:index ] removeSubItem:item ];
}

- (void) insertSubItem:(MDMenuItem*)item toItem:(unsigned int)index atIndex:(unsigned int)nin
{
	if (index >= [ mitems count ])
		return;
	[ [ mitems objectAtIndex:index ] insertSubItem:item atIndex:nin ];
}

- (void) setExpanded: (BOOL)exp item: (MDMenuItem*)itm
{
	[ itm setExpanded:exp ];
	for (int z = 0; z < [ [ itm subItems ] count ]; z++)
		[ self setExpanded:exp item:[ [ itm subItems ] objectAtIndex:z ] ];
}

- (void) setExpanded: (BOOL)exp item: (MDMenuItem*)itm onlySubviews:(BOOL)sub
{
	for (int z = 0; z < [ [ itm subItems ] count ]; z++)
	{
		[ [ [ itm subItems ] objectAtIndex:z ] setExpanded:exp ];
		[ self setExpanded:exp item:[ [ itm subItems ] objectAtIndex:z ] ];
	}
}

- (MDMenuItem*) point:(NSPoint)point inItem:(MDMenuItem*)item withBars:(BOOL)bars usedBars:(BOOL*)used
{
	for (int z = 0; z < [ [ item subItems ] count ]; z++)
	{
		MDRect subFrame = [ (MDMenuItem*)[ [ item subItems ] objectAtIndex:z ] frame ];
		if ([ item expanded ] && point.x >= subFrame.x && point.x < subFrame.x + subFrame.width &&
			point.y >= subFrame.y && point.y < subFrame.y + subFrame.height)
			return [ [ item subItems ] objectAtIndex:z ];
		if (bars && z == 0)
		{
			if ([ item expanded ] && point.x >= subFrame.x && point.x < subFrame.x + subFrame.width &&
				point.y >= subFrame.y && point.y < subFrame.y + subFrame.height + 4)
			{
				if (used)
					(*used) = YES;
				return [ [ item subItems ] objectAtIndex:z ];
			}
		}
		else if (bars && z == [ [ item subItems ] count ] - 1)
		{
			if ([ item expanded ] && point.x >= subFrame.x && point.x < subFrame.x + subFrame.width &&
				point.y >= subFrame.y - 5 && point.y < subFrame.y + subFrame.height)
			{
				if (used)
					(*used) = YES;
				return [ [ item subItems ] objectAtIndex:z ];
			}
		}
		MDMenuItem* titem = [ self point:point inItem:[ [ item subItems ] objectAtIndex:z ] withBars:bars usedBars:used ];
		if (titem)
			return titem;
	}
	return nil;
}

- (void) mouseNotDown
{
	[ super mouseNotDown ];
	
	if (expanded.size() != 0)
	{
		selectedItem = nil;
		currentAlpha = [ MD_SUBMENU_DEFAULT_COLOR alphaComponent ];
		tracking = FALSE;
		fading = TRUE;
	}
	else
	{
		expanded.clear();
		for (int z = 0; z < [ mitems count ]; z++)
			[ self setExpanded:NO item:[ mitems objectAtIndex:z ] ];
	}
}

- (void) mouseDown:(NSEvent *)event
{
	if (!visible || !enabled || !tracking)
		return;
	down = FALSE;
	up = TRUE;
	NSPoint point = [ event locationInWindow ];
	point.x -= origin.x;
	point.y -= origin.y;
	point.x *= resolution.width / windowSize.width;
	point.y *= resolution.height / windowSize.height;
	
	BOOL top = FALSE;
	if (point.x >= frame.x && point.x <= frame.x + frame.width &&
		point.y >= frame.y && point.y <= frame.y + frame.height)
	{
		down = TRUE;
		up = FALSE;
		realDown = TRUE;
		top = TRUE;
		
		for (int z = 0; z < [ mitems count ]; z++)
		{
			MDRect frm = [ (MDMenuItem*)[ mitems objectAtIndex:z ] frame ];
			if (point.x >= frm.x && point.x < frm.x + frm.width &&
				point.y >= frm.y && point.y < frm.y + frm.height)
			{
				expanded.clear();
				for (int q = 0; q < [ mitems count ]; q++)
					[ self setExpanded:NO item:[ mitems objectAtIndex:q ] ];
				expanded.push_back(z);
				[ [ mitems objectAtIndex:z ] setExpanded:YES ];
				break;
			}
		}
	}
	
	hit = FALSE;
	if (expanded.size() != 0)
	{
		MDMenuItem* item = [ self point:point inItem:[ mitems objectAtIndex:expanded[0] ] withBars:YES usedBars:NULL ];
		if (item)
			hit = TRUE;
		realDown = TRUE;
	}
	
	if (!hit && !top)
	{
		if (expanded.size() != 0)
		{
			selectedItem = nil;
			currentAlpha = [ MD_SUBMENU_DEFAULT_COLOR alphaComponent ];
			tracking = FALSE;
			fading = TRUE;
		}
		else
		{
			expanded.clear();
			for (int z = 0; z < [ mitems count ]; z++)
				[ self setExpanded:NO item:[ mitems objectAtIndex:z ] ];
		}
	}
}

- (void) mouseDragged:(NSEvent *)event
{
	[ self mouseMoved:event ];
}

- (void) itemPressed2:(NSTimer*)timer
{
	[ timer invalidate ];
	fading = TRUE;
	currentAlpha = [ MD_SUBMENU_DEFAULT_COLOR alphaComponent ];
}

- (void) itemPressed:(NSTimer*)timer
{
	[ selectedItem setExpanded:YES ];
	[ timer invalidate ];
	[ NSTimer scheduledTimerWithTimeInterval:MD_MENU_DEFAULT_DELAY_TIME_ON target:self selector:@selector(itemPressed2:) userInfo:nil repeats:NO ];
}

- (void) mouseUp:(NSEvent *)event
{
	if (!visible || !enabled)
		return;
	NSPoint point = [ event locationInWindow ];
	point.x -= origin.x;
	point.y -= origin.y;
	point.x *= resolution.width / windowSize.width;
	point.y *= resolution.height / windowSize.height;
	
	if (hit && expanded.size() != 0 && tracking)
	{
		MDMenuItem* item = [ self point:point inItem:[ mitems objectAtIndex:expanded[0] ] withBars:NO usedBars:NULL ];
		if (item && [ [ item subItems ] count ] == 0)
		{
			selectedItem = item;
			[ item setExpanded:NO ];
			tracking = FALSE;
			
			[ NSTimer scheduledTimerWithTimeInterval:MD_MENU_DEFAULT_DELAY_TIME_OFF target:self selector:@selector(itemPressed:) userInfo:nil repeats:NO ];
		}
	}
	hit = FALSE;
	
	down = FALSE;
	up = TRUE;
	realDown = FALSE;
}

- (void) mouseMoved:(NSEvent *)event
{
	if (!visible || !enabled || expanded.size() == 0 || !tracking)
		return;
	NSPoint point = [ event locationInWindow ];
	point.x -= origin.x;
	point.y -= origin.y;
	point.x *= resolution.width / windowSize.width;
	point.y *= resolution.height / windowSize.height;
	
	hit = FALSE;
	if (expanded.size() != 0)
	{
		BOOL bars = FALSE;
		MDMenuItem* item = [ self point:point inItem:[ mitems objectAtIndex:expanded[0] ] withBars:NO usedBars:&bars ];
		if (item)
		{
			hit = TRUE;
			//if (bars)
			//	[ item setExpanded:NO ];
		}
	}
	
	if (expanded.size() != 0 && point.x >= frame.x && point.x <= frame.x + frame.width &&
		point.y >= frame.y && point.y <= frame.y + frame.height)
	{
		for (int z = 0; z < [ mitems count ]; z++)
		{
			if (expanded[0] == z)
				continue;
			
			MDRect frm = [ (MDMenuItem*)[ mitems objectAtIndex:z ] frame ];
			if (point.x >= frm.x && point.x < frm.x + frm.width &&
				point.y >= frm.y && point.y < frm.y + frm.height)
			{
				expanded.clear();
				for (int q = 0; q < [ mitems count ]; q++)
					[ self setExpanded:NO item:[ mitems objectAtIndex:q ] ];
				expanded.push_back(z);
				[ [ mitems objectAtIndex:z ] setExpanded:YES ];
				break;
			}
		}
	}
	
	if (expanded.size() != 0)
	{
		BOOL bars = FALSE;
		MDMenuItem* item = [ self point:point inItem:[ mitems objectAtIndex:expanded[0] ] withBars:YES usedBars:&bars ];
		if (item)
		{
			lastItem = item;
			for (int z = 0; z < [ mitems count ]; z++)
				[ self setExpanded:NO item:[ mitems objectAtIndex:z ] ];
			[ item setExpanded:YES ];
			MDMenuItem* parent = item;
			while (parent)
			{
				[ parent setExpanded:YES ];
				parent = [ parent parent ];
			}
			if (bars)
				[ item setExpanded:NO ];
		}
		else
			[ lastItem setExpanded:NO ];
	}
}

- (void) drawSubItems: (MDMenuItem*)item
{
	if (![ item expanded ])
		return;
	
	if ([ [ item subItems ] count ] != 0)
	{
		glLoadIdentity();
		MDRect itemFrame = [ (MDMenuItem*)[ [ item subItems ] objectAtIndex:0 ] frame ];
		glTranslated(itemFrame.x, itemFrame.y + itemFrame.height + 4, 0);
		NSColor* color = MD_SUBMENU_DEFAULT_COLOR;
		if (fading)
			glColor4d([ color redComponent ], [ color greenComponent ], [ color blueComponent ], currentAlpha);
		else
		{
			glColor4d([ color redComponent ], [ color greenComponent ], [ color blueComponent ], [ color alphaComponent ]);
		}
		glBegin(GL_TRIANGLE_STRIP);
		{
			glVertex2d(0, 0);
			glVertex2d(itemFrame.width, 0);
			glVertex2d(0, -4);
			glVertex2d(itemFrame.width, -4);
		}
		glEnd();
		
		glLoadIdentity();
		MDRect itemFrame2 = [ (MDMenuItem*)[ [ item subItems ] lastObject ] frame ];
		glTranslated(itemFrame2.x, itemFrame2.y, 0);
		if (fading)
			glColor4d([ color redComponent ], [ color greenComponent ], [ color blueComponent ], currentAlpha);
		else
		{
			glColor4d([ color redComponent ], [ color greenComponent ], [ color blueComponent ], [ color alphaComponent ]);
		}
		glBegin(GL_TRIANGLE_STRIP);
		{
			glVertex2d(0, 0);
			glVertex2d(itemFrame2.width, 0);
			glVertex2d(0, -5);
			glVertex2d(itemFrame2.width, -5);
		}
		glEnd();
	}
	
	NSMutableArray* sub = [ item subItems ];
	float height = 0;
	for (int z = 0; z < [ sub count ]; z++)
	{
		MDRect frm = [ (MDMenuItem*)[ sub objectAtIndex:z ] frame ];
		glLoadIdentity();
		glTranslated(frm.x, frm.y, 0);
		if ([ [ sub objectAtIndex:z ] expanded ])
		{
			NSColor* color = MD_MENU_DEFAULT_SELECTION_COLOR_LOW;
			if (fading)
				glColor4d([ color redComponent ], [ color greenComponent ], [ color blueComponent ], currentAlpha);
			else
			{
				glColor4d([ color redComponent ], [ color greenComponent ], [ color blueComponent ], [ color alphaComponent ]);
			}
		}
		else
		{
			NSColor* color = MD_SUBMENU_DEFAULT_COLOR;
			if (fading)
				glColor4d([ color redComponent ], [ color greenComponent ], [ color blueComponent ], currentAlpha);
			else
			{
				glColor4d([ color redComponent ], [ color greenComponent ], [ color blueComponent ], [ color alphaComponent ]);
			}
		}
		glBegin(GL_TRIANGLE_STRIP);
		{
			glVertex2d(0, 0);
			glVertex2d(frm.width, 0);
			//NSColor* high = MD_SUBMENU_DEFAULT_COLOR;
			if ([ [ sub objectAtIndex:z ] expanded ])
			{
				NSColor* high = MD_MENU_DEFAULT_SELECTION_COLOR_HIGH;
				if (fading)
					glColor4d([ high redComponent ], [ high greenComponent ], [ high blueComponent ], currentAlpha);
				else
				{
					glColor4d([ high redComponent ], [ high greenComponent ], [ high blueComponent ], [ high alphaComponent ]);
				}
			}
			glVertex2d(0, frm.height);
			glVertex2d(frm.width, frm.height);
		}
		glEnd();
		NSColor* color = textColor;
		if ([ [ sub objectAtIndex:z ] expanded ])
			color = MD_MENU_DEFAULT_TEXT_SELECTION_COLOR;
		if (fading)
		{
			color = [ NSColor colorWithCalibratedRed:[ color redComponent ] green:[ color greenComponent ] blue:[ color blueComponent ] alpha:currentAlpha ];
			MDDrawString([ [ [ [ sub objectAtIndex:z ] glStr ] string ] string ], NSMakePoint(frm.x + 2, frm.y + (frm.height / 2)), color, textFont, 0, NSLeftTextAlignment);
		}
		else
		{
			DrawStringColor([ [ sub objectAtIndex:z ] glStr ], NSMakePoint(frm.x + 2,
				frm.y + (frm.height / 2)), NSLeftTextAlignment, 0, color);
		}
		if ([ [ [ sub objectAtIndex:z ] subItems ] count ] != 0)
		{
			glLoadIdentity();
			glTranslated(frm.x + frm.width - 20, frm.y + (frm.height / 2), 0);
			glColor4d([ color redComponent ], [ color greenComponent ], [ color blueComponent ], [ color alphaComponent ]);
			glBegin(GL_TRIANGLE_STRIP);
			{
				glVertex2d(0, (frm.height / 2) - 5);
				glVertex2d(0, (-frm.height / 2) + 5);
				glVertex2d(10, 0);
			}
			glEnd();
			[ self drawSubItems:[ sub objectAtIndex:z ] ];
		}
		height += frm.height;
	}
	if ([ sub count ] != 0)
	{
		if ([ item parent ])
		{
			glLoadIdentity();
			glTranslated([ item frame ].x + [ item frame ].width, [ item frame ].y + [ item frame ].height + 4, 0);
			glColor4d(0, 0, 0, (fading ? currentAlpha : 1));
			glBegin(GL_LINE_STRIP);
			{
				glVertex2d(0, 0);
				glVertex2d([ (MDMenuItem*)[ sub objectAtIndex:0 ] frame ].width, 0);
				glVertex2d([ (MDMenuItem*)[ sub objectAtIndex:0 ] frame ].width, -height - 13);
				glVertex2d(0, -height - 13);
				glVertex2d(0, 0);
			}
			glEnd();
		}
		else
		{
			glLoadIdentity();
			glTranslated([ item frame ].x, [ item frame ].y, 0);
			glColor4d(0, 0, 0, (fading ? currentAlpha : 1));
			glBegin(GL_LINE_STRIP);
			{
				glVertex2d(0, 0);
				glVertex2d([ (MDMenuItem*)[ sub objectAtIndex:0 ] frame ].width, 0);
				glVertex2d([ (MDMenuItem*)[ sub objectAtIndex:0 ] frame ].width, -height - 9);
				glVertex2d(0, -height - 9);
				glVertex2d(0, 0);
			}
			glEnd();
		}
		itemShadows = item;
		itemShadowHeight = height;
	}
	sub = nil;
}

- (BOOL) beforeDraw
{
	if (alwaysOnTop)
	{
		if ([ views indexOfObject:self ] != [ views count ] - 1)
		{
			[ self retain ];
			[ views removeObject:self ];
			[ views addObject:self ];
			[ self release ];
			[ super beforeDraw ];
			return TRUE;
		}
	}
	
	return [ super beforeDraw ];
}

- (void) drawView
{
	if (!visible)
		return;
	
	if (expanded.size() == 0)
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
		
		float colors[16];
		
		for (int z = 0; z < 4; z++)
		{
			float add = !enabled ? -0.3 : 0.0;
			colors[(z * 4)] = [ background[0] redComponent ] + add;
			colors[(z * 4) + 1] = [ background[0] greenComponent ] + add;
			colors[(z * 4) + 2] = [ background[0] blueComponent ] + add;
			colors[(z * 4) + 3] = [ background[0] alphaComponent ];

		}
		glLoadIdentity();
		glEnableClientState(GL_VERTEX_ARRAY);
		glEnableClientState(GL_COLOR_ARRAY);
		glVertexPointer(2, GL_FLOAT, 0, square);
		glColorPointer(4, GL_FLOAT, 0, colors);
		glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
		
		glDisableClientState(GL_VERTEX_ARRAY);
		glDisableClientState(GL_COLOR_ARRAY);
	}
	else
	{
		float x = [ (MDMenuItem*)[ mitems objectAtIndex:expanded[0] ] frame ].x;
		float width = [ (MDMenuItem*)[ mitems objectAtIndex:expanded[0] ] frame ].width;
		float square1[8];
		square1[0] = frame.x;
		square1[1] = frame.y;
		square1[2] = x;
		square1[3] = frame.y;
		square1[4] = frame.x;
		square1[5] = frame.y + frame.height;
		square1[6] = x;
		square1[7] = frame.y + frame.height;
		
		float square2[8];
		square2[0] = x;
		square2[1] = frame.y;
		square2[2] = x + width;
		square2[3] = frame.y;
		square2[4] = x;
		square2[5] = frame.y + frame.height;
		square2[6] = x + width;
		square2[7] = frame.y + frame.height;
		
		float square3[8];
		square3[0] = x + width;
		square3[1] = frame.y;
		square3[2] = frame.x + frame.width;
		square3[3] = frame.y;
		square3[4] = x + width;
		square3[5] = frame.y + frame.height;
		square3[6] = frame.x + frame.width;
		square3[7] = frame.y + frame.height;
		
		float colors1[16];
		for (int z = 0; z < 4; z++)
		{
			float add = !enabled ? -0.3 : 0.0;
			colors1[(z * 4)] = [ background[z] redComponent ] + add;
			colors1[(z * 4) + 1] = [ background[z] greenComponent ] + add;
			colors1[(z * 4) + 2] = [ background[z] blueComponent ] + add;
			colors1[(z * 4) + 3] = [ background[z] alphaComponent ];
		}
		
		float colors2[16];
		for (int z = 0; z < 4; z++)
		{
			NSColor* color = MD_MENU_DEFAULT_SELECTION_COLOR_LOW;
			if (z >= 2)
				color = MD_MENU_DEFAULT_SELECTION_COLOR_HIGH;
			colors2[(z * 4)] = [ color redComponent ];
			colors2[(z * 4) + 1] = [ color greenComponent ];
			colors2[(z * 4) + 2] = [ color blueComponent ];
			colors2[(z * 4) + 3] = [ color alphaComponent ];
		}
		
		glLoadIdentity();
		glEnableClientState(GL_VERTEX_ARRAY);
		glEnableClientState(GL_COLOR_ARRAY);
		
		glVertexPointer(2, GL_FLOAT, 0, square1);
		glColorPointer(4, GL_FLOAT, 0, colors1);
		glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
		
		glVertexPointer(2, GL_FLOAT, 0, square2);
		glColorPointer(4, GL_FLOAT, 0, colors2);
		glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
		
		glVertexPointer(2, GL_FLOAT, 0, square3);
		glColorPointer(4, GL_FLOAT, 0, colors1);
		glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
		
		glDisableClientState(GL_VERTEX_ARRAY);
		glDisableClientState(GL_COLOR_ARRAY);
	}
	
	if (fading)
	{
		currentAlpha -= 0.1;
		if (currentAlpha <= 0)
		{
			fading = FALSE;
			expanded.clear();
			if ([ selectedItem target ] && [ selectedItem action ] && [ [ selectedItem target ] respondsToSelector:[ selectedItem action ] ])
				[ [ selectedItem target ] performSelector:[ selectedItem action ] withObject:selectedItem ];
			for (int z = 0; z < [ mitems count ]; z++)
				[ self setExpanded:NO item:[ mitems objectAtIndex:z ] ];
			selectedItem = nil;
			itemShadows = nil;
			tracking = TRUE;
			
			if (removeOnClick)
			{
				if (target && [ target respondsToSelector:action ])
					[ target performSelector:action withObject:self ];
				[ views removeObject:self ];
				return;
			}
		}
	}
	
	for (int z = 0; z < [ mitems count ]; z++)
	{
		NSColor* color = textColor;
		if (expanded.size() && expanded[0] == z)
			color = MD_MENU_DEFAULT_TEXT_SELECTION_COLOR;
		MDRect frm = [ (MDMenuItem*)[ mitems objectAtIndex:z ] frame ];
		DrawStringColor([ [ mitems objectAtIndex:z ] glStr ], NSMakePoint(frm.x + (frm.width / 2),
					frm.y + (frm.height / 2) - 1), NSCenterTextAlignment, 0, color);
		[ self drawSubItems:[ mitems objectAtIndex:z ] ];
	}
	
	glLoadIdentity();
	glColor4d(0, 0, 0, 1);
	glBegin(GL_LINES);
	{
		glVertex2d(frame.x, frame.y);
		glVertex2d(frame.x + frame.width, frame.y);
	}
	glEnd();
	
	MDMenuItem* item = itemShadows;
	if (!item)
		return;
	NSArray* sub = [ item subItems ];
	float height = itemShadowHeight;
	
#define WPOWER	5
#define POWER	9
#define INTENSITY	0
	
	MDRect itemFrame = MakeRect([ item frame ].x, [ item frame ].y - height - 9, [ (MDMenuItem*)[ sub objectAtIndex:0 ] frame ].width, height);
	
	float realAlpha = 0.3;
	if (fading)
		realAlpha = 0.3 * currentAlpha;
	glLoadIdentity();
	glTranslated(itemFrame.x + (itemFrame.width / 2), itemFrame.y + (itemFrame.height / 2), 0);
	glBegin(GL_TRIANGLE_FAN);
	{
		glColor4d(0, 0, 0, realAlpha);
		glVertex2d(itemFrame.width / 2, (itemFrame.height / 2));
		
		glColor4d(0, 0, 0, INTENSITY);
		for (int z = 0; z <= 9; z++)
		{
			float angle = z / 18.0 * M_PI;
			glVertex2d((itemFrame.width / 2) + (cos(angle) * WPOWER), (itemFrame.height / 2) + (sin(angle) * WPOWER));
		}
	}
	glEnd();
	glBegin(GL_QUADS);
	{
		glColor4d(0, 0, 0, INTENSITY);
		glVertex2d((itemFrame.width / 2) + WPOWER, itemFrame.height / 2);
		glVertex2d((itemFrame.width / 2) + WPOWER, -itemFrame.height / 2);
		glColor4d(0, 0, 0, realAlpha);
		glVertex2d((itemFrame.width / 2), -itemFrame.height / 2 );
		glVertex2d((itemFrame.width / 2), itemFrame.height / 2);
	}
	glEnd();
	glBegin(GL_TRIANGLE_FAN);
	{
		glColor4d(0, 0, 0, realAlpha);
		glVertex2d(itemFrame.width / 2, -(itemFrame.height / 2));
		
		glColor4d(0, 0, 0, INTENSITY);
		for (int z = 0; z <= 9; z++)
		{
			float angle = z / 18.0 * M_PI;
			glVertex2d((itemFrame.width / 2) + (cos(angle) * WPOWER), -(itemFrame.height / 2) - (sin(angle) * POWER));
		}
	}
	glEnd();
	glBegin(GL_TRIANGLE_FAN);
	{
		glColor4d(0, 0, 0, realAlpha);
		glVertex2d(-itemFrame.width / 2, (itemFrame.height / 2));
		
		glColor4d(0, 0, 0, INTENSITY);
		for (int z = 0; z <= 9; z++)
		{
			float angle = z / 18.0 * M_PI;
			glVertex2d(-(itemFrame.width / 2) - (cos(angle) * WPOWER), (itemFrame.height / 2) + (sin(angle) * WPOWER));
		}
	}
	glEnd();
	glBegin(GL_QUADS);
	{
		glColor4d(0, 0, 0, INTENSITY);
		glVertex2d(-(itemFrame.width / 2) - WPOWER, itemFrame.height / 2);
		glVertex2d(-(itemFrame.width / 2) - WPOWER, -itemFrame.height / 2);
		glColor4d(0, 0, 0, realAlpha);
		glVertex2d(-(itemFrame.width / 2), -itemFrame.height / 2);
		glVertex2d(-(itemFrame.width / 2), itemFrame.height / 2);
	}
	glEnd();
	glBegin(GL_TRIANGLE_FAN);
	{
		glColor4d(0, 0, 0, realAlpha);
		glVertex2d(-itemFrame.width / 2, -(itemFrame.height / 2));
		
		glColor4d(0, 0, 0, INTENSITY);
		for (int z = 0; z <= 9; z++)
		{
			float angle = z / 18.0 * M_PI;
			glVertex2d(-(itemFrame.width / 2) - (cos(angle) * WPOWER), -(itemFrame.height / 2) - (sin(angle) * POWER));
		}
	}
	glEnd();
	glBegin(GL_QUADS);
	{
		glColor4d(0, 0, 0, INTENSITY);
		glVertex2d(-(itemFrame.width / 2), -itemFrame.height / 2 - POWER);
		glVertex2d((itemFrame.width / 2), -itemFrame.height / 2 - POWER);
		glColor4d(0, 0, 0, realAlpha);
		glVertex2d((itemFrame.width / 2), -itemFrame.height / 2);
		glVertex2d(-(itemFrame.width / 2), -itemFrame.height / 2);
	}
	glEnd();
}

- (void) expandItem: (unsigned int) expand
{
	for (int q = 0; q < [ mitems count ]; q++)
		[ self setExpanded:NO item:[ mitems objectAtIndex:q ] ];
	expanded.push_back(expand);
	MDMenuItem* item = [ mitems objectAtIndex:expanded[0] ];
	[ item setExpanded:YES ];
	for (int z = 1; z < expanded.size(); z++)
	{
		item = [ [ item subItems ] objectAtIndex:expanded[z] ];
		[ item setExpanded:YES ];
	}
	selectedItem = item;
}

- (void) setRemoveOnClick: (BOOL)click
{
	removeOnClick = click;
}

- (BOOL) removesOnClick
{
	return removeOnClick;
}

- (void) setAlwaysOnTop: (BOOL)top
{
	alwaysOnTop = top;
}

- (BOOL) alwaysOnTop
{
	return alwaysOnTop;
}

- (NSArray*) items
{
	return mitems;
}

- (void) dealloc
{
	if (mitems)
	{
		[ mitems removeAllObjects ];
		[ mitems release ];
		mitems = nil;
	}
	[ super dealloc ];
}

@end

MDMenu* MDPopupMenu(NSArray* items, NSPoint location, float width)
{
	MDMenu* menu = [ [ [ MDMenu alloc ] initWithFrame:MakeRect(location.x - 10, location.y + 5, 0, 0) background:MD_MENU_DEFAULT_COLOR ] autorelease ];
	[ menu setRemoveOnClick:YES ];
	
	MDMenuItem* item = [ MDMenuItem menuItemWithString:@"" target:nil action:nil ];
	for (unsigned long z = 0; z < [ items count ]; z++)
		[ item addSubItem:[ items objectAtIndex:z ] ];
	[ menu addItem:item ];
	if (width != 0)
	{
		MDMenuItem* realItem = [ [ menu items ] objectAtIndex:0 ];
		for (unsigned long z = 0; z < [ [ realItem subItems ] count ]; z++)
		{
			MDMenuItem* item2 = [ [ realItem subItems ] objectAtIndex:z ];
			MDRect frame = [ item2 frame ];
			frame.width = width;
			[ item2 setFrame:frame ];
		}
	}
	[ menu expandItem:0 ];
	
	return menu;
}
