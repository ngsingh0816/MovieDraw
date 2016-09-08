//
//  MDComboBox.mm
//  MovieDraw
//
//  Created by MILAP on 12/26/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MDComboBox.h"
#import "MDMenu.h"
#import "MDTextField.h"
#import "MDButton.h"

@implementation MDComboBox

+ (MDComboBox*) mdComboBox
{
	return [ [ [ MDComboBox alloc ] init ] autorelease ];
}

+ (MDComboBox*) mdComboBoxWithFrame:(MDRect)rect background:(NSColor*)bkg
{
	return [ [ [ MDComboBox alloc ] initWithFrame:rect background:bkg ] autorelease ];
}

- (id) init
{
	if ((self = [ super init ]))
	{
		titems = [ [ NSMutableArray alloc ] init ];
		strings = [ [ NSMutableArray alloc ] init ];
		
		field = [ [ MDTextField alloc ] init ];
		[ field setPixelOffset:5 ];
		[ views removeObject:field ];
		downButton = [ [ MDButton alloc ] init ];
		[ downButton setTarget:self ];
		[ downButton setAction:@selector(downPressed) ];
		[ downButton setText:@"▾" ];
		[ views removeObject:downButton ];
		
	}
	return self;
}

- (id) initWithFrame:(MDRect)rect background:(NSColor*)bkg
{
	if ((self = [ super initWithFrame:rect background:bkg ]))
	{
		titems = [ [ NSMutableArray alloc ] init ];
		strings = [ [ NSMutableArray alloc ] init ];
		
		field = [ [ MDTextField alloc ] initWithFrame:MakeRect(rect.x, rect.y, rect.width - 17, rect.height) background:bkg ];
		[ field setPixelOffset:5 ];
		[ views removeObject:field ];
		downButton = [ [ MDButton alloc ] initWithFrame:MakeRect(rect.x + rect.width - 18, rect.y, 18, rect.height) background:MD_BUTTON_DEFAULT_BUTTON_COLOR ];
		[ downButton setTarget:self ];
		[ downButton setAction:@selector(downPressed) ];
		[ downButton setText:@"▾" ];
		[ views removeObject:downButton ];
	}
	return self;
}

- (void) menuFinished: (id)sender
{
	popUp = nil;
}

- (void) itemChosen: (MDMenuItem*)item
{
	[ self selectItem:[ titems indexOfObject:[ item text ] ] ];
	(*[ field highlights ]).clear();
	(*[ field highlights ]).push_back(NSMakeRange(0, [ [ item text ] length ]));
	popUp = nil;
}

- (void) downPressed
{
	if ([ strings count ] == 0)
		return;
	if (popUp)
	{
		[ views removeObject:popUp ];
		popUp = nil;
		return;
	}
	
	NSMutableArray* array = [ NSMutableArray array ];
	for (unsigned long z = 0; z < [ strings count ]; z++)
	{
		[ array addObject:[ MDMenuItem menuItemWithString:[ [ (GLString*)[ strings objectAtIndex:z ] string ] string ] target:self action:@selector(itemChosen:) ] ];
	}
	
	popUp = MDPopupMenu(array, NSMakePoint(frame.x, frame.y - 7), frame.width);
	[ popUp setTarget:self ];
	[ popUp setAction:@selector(menuFinished:) ];
	[ popUp setMouseDown:YES ];
}

- (void) setFrame:(MDRect)rect
{
	[ super setFrame:rect ];
	[ field setFrame:MakeRect(rect.x, rect.y, rect.width - 17, rect.height) ];
	[ downButton setFrame:MakeRect(rect.x + rect.width - 18, rect.y, 18, rect.height) ];
}

- (void) addItem:(NSString*)str
{
	[ titems addObject:str ];
	[ strings addObject:LoadString(str, textColor, textFont)];
}

- (void) removeItem: (NSString*)str
{
	unsigned long objIndex = [ titems indexOfObject:str ];
	[ titems removeObject:str ];
	[ strings removeObjectAtIndex:objIndex ];
}

- (void) selectItem: (unsigned long)item
{
	if (item >= [ titems count ])
		return;
	[ field setText:[ titems objectAtIndex:item ] ];
	if (text)
		[ text release ];
	text = [ [ NSMutableString alloc ] initWithString:[ titems objectAtIndex:item ] ];
 	if (target && [ target respondsToSelector:action ])
		[ target performSelector:action withObject:self ];
	popUp = nil;
}

- (NSString*) stringValue
{
	return text;
}

- (MDTextField*) field
{
	return field;
}

- (void) setEnabled:(BOOL)en
{
	[ super setEnabled:en ];
	[ field setEnabled:en ];
	[ downButton setEnabled:en ];
}

- (void) drawView
{
	if (!visible)
		return;
	
	[ field drawView ];
	[ downButton drawView ];
}

- (void) alphaDraw
{
	[ field alphaDraw ];
	[ downButton alphaDraw ];
}

- (void) finishDraw
{
	[ field finishDraw ];
	[ downButton finishDraw ];
}

- (void) mouseDown:(NSEvent *)event
{
	if (!visible || !enabled)
		return;
	
	[ field mouseDown:event ];
	[ downButton mouseDown:event ];
}

- (void) mouseUp:(NSEvent *)event
{
	if (!visible || !enabled)
		return;
	
	[ field mouseUp:event ];
	[ downButton mouseUp:event ];
}

- (void) mouseDragged:(NSEvent *)event
{
	if (!visible || !enabled)
		return;
	
	[ field mouseDragged:event ];
	[ downButton mouseDragged:event ];
}

- (void) mouseMoved:(NSEvent *)event
{
	if (!visible || !enabled)
		return;
	
	[ field mouseMoved:event ];
	[ downButton mouseMoved:event ];
}

- (void) keyDown:(NSEvent *)event
{
	if (!visible || !enabled || popUp)
		return;
	
	[ field keyDown:event ];
	if ([ field cursorPosition ] != (unsigned long)-1)
	{
		unsigned short key = [ [ event characters ] characterAtIndex:0 ];
		if (key == NSCarriageReturnCharacter || key == NSEnterCharacter ||
			key == NSNewlineCharacter)
		{
			if (text)
				[ text release ];
			text = [ [ NSMutableString alloc ] initWithString:[ field text ] ];
			if (target && [ target respondsToSelector:action ])
				[ target performSelector:action withObject:self ];
		}
	}
	[ downButton keyDown:event ];
}

- (void) keyUp:(NSEvent *)event
{
	if (!visible || !enabled)
		return;
	
	[ field keyUp:event ];
	[ downButton keyUp:event ];
}

- (void) scrollWheel:(NSEvent *)event
{
	if (!visible || !enabled)
		return;
	
	[ field scrollWheel:event ];
	[ downButton scrollWheel:event ];
}

- (void) dealloc
{
	if (field)
	{
		[ field release ];
		field = nil;
	}
	if (downButton)
	{
		[ downButton release ];
		downButton = nil;
	}
	
	[ super dealloc ];
}

@end
