//
//  MDOpenPanel.mm
//  MovieDraw
//
//  Created by MILAP on 9/23/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MDOpenPanel.h"
#import "MDButton.h"
#import "MDTextField.h"
#import "MDTableView.h"
#import "MDLabel.h"

@interface MDOpenPanel (InternalMethods)

- (void) open: (id) sender;
- (void) checkKey: (id) sender;
- (void) singleClick: (id) sender;
- (void) doubleClick: (id) sender;
- (void) goBack: (id) sender;
- (void) goForward: (id) sender;
@property (readonly) BOOL update;

@end

@implementation MDOpenPanel

+ (instancetype) mdOpenPanel
{
	return [ [ MDOpenPanel alloc ] init ];
}

+ (instancetype) mdOpenPanelWithFrame: (MDRect)rect background: (NSColor*)bkg
{
	return [ [ MDOpenPanel alloc ] initWithFrame:rect background:bkg  ];
}

- (instancetype) init
{
	if ((self = [ super init ]))
	{
		actTar = nil;
		fileTypes = [ [ NSMutableArray alloc ] init ];
		filename = [ [ NSMutableString alloc ] initWithString:@"/" ];
		
		MDButton* cancel = [ [ MDButton alloc ] initWithFrame:MakeRect(frame.x + 15,
							frame.y + 15, 90, 30)
			background:[ NSColor colorWithCalibratedRed:0.95 green:0.95
									blue:0.95 alpha:1 ] ];
		[ views removeObject:cancel ];
		[ cancel setText:@"Cancel" ];
		[ cancel setIdentity:@"Cancel" ];
		[ cancel setTarget:self ];
		[ cancel setAction:@selector(close:) ];
		[ subViews addObject:cancel ];
	}
	return self;
}

- (instancetype) initWithFrame: (MDRect)rect background: (NSColor*)bkg
{
	if ((self = [ super initWithFrame:rect background:bkg ]))
	{
		shouldUpdate = NO;
		button = NO;
		actTar = nil;
		fileTypes = [ [ NSMutableArray alloc ] init ];
		images = [ [ NSMutableArray alloc ] init ];
		undo = [ [ NSMutableArray alloc ] init ];
		redo = [ [ NSMutableArray alloc ] init ];
		files = nil;
		[ self setMinSize:NSMakeSize(rect.width, rect.height) ];
		undoPointer = 0;
		filename = [ [ NSMutableString alloc ] initWithString:@"/" ];
		showHidden = NO;
		
		//NSImage* fldImg = [ [ NSWorkspace sharedWorkspace ] iconForFileType:NSFileTypeForHFSTypeCode(kGenericFolderIcon) ];
		//LoadImage((const char*)[ [ fldImg TIFFRepresentation ] bytes ], &folderImg, [ [ fldImg TIFFRepresentation ] length ]);
		
		MDButton* cancel = [ [ MDButton alloc ] initWithFrame:MakeRect(frame.x + 15,
								frame.y + 15, 90, 30)
					background:[ NSColor colorWithCalibratedRed:0.95 green:0.95
								blue:0.95 alpha:[ bkg alphaComponent ] ] ];
		[ views removeObject:cancel ];
		[ cancel setText:@"Cancel" ];
		[ cancel setIdentity:@"Cancel" ];
		[ cancel setTarget:self ];
		[ cancel setAction:@selector(close:) ];
		[ subViews addObject:cancel ];
		
		MDButton* open = [ [ MDButton alloc ] initWithFrame:MakeRect(frame.x + frame.width
			- 105, frame.y + 15, 90, 30) background:[ NSColor colorWithCalibratedRed:0.95
									green:0.95 blue:0.95 alpha:[ bkg alphaComponent ] ] ];
		[ views removeObject:open ];
		[ open setText:@"Open" ];
		[ open setIdentity:@"Open" ];
		[ open setTarget:self ];
		[ open setAction:@selector(open:) ];
		[ open setEnabled:NO ];
		[ subViews addObject:open ];
		
		MDLabel* description = [ [ MDLabel alloc ] initWithFrame:MakeRect(frame.x + 10,
			frame.y + frame.height - 60, 60, 15) background:[ NSColor colorWithCalibratedRed:0
											green:0 blue:0 alpha:[ bkg alphaComponent ] ] ];
		[ views removeObject:description ];
		[ description setText:@"Open:" ];
		[ description setIdentity:@"Open Text" ];
		[ subViews addObject:description ];
		
		MDTextField* textField = [ [ MDTextField alloc ] initWithFrame:MakeRect(
				frame.x + 60, frame.y + frame.height - 65, frame.width - 80, 30)
				background:[ NSColor colorWithCalibratedRed:1 green:1 blue:1 alpha:1 ] ];
		[ views removeObject:textField ];
		[ textField setUsesThreads:NO ];
		[ textField setKeyTarget:self ];
		[ textField setKeyAction:@selector(checkKey:) ];
		[ textField setIdentity:@"Name Field" ];
		[ subViews addObject:textField ];
		
		MDTableView* table = [ [ MDTableView alloc ] initWithFrame:MakeRect(
			frame.x + 15, frame.y + 60, frame.width - 30, frame.height - 140)
			background:[ NSColor colorWithCalibratedRed:1 green:1 blue:1 alpha:1 ] ];
		[ views removeObject:table ];
		[ table setIdentity:@"File Table" ];
		[ table addHeader:@"File" ];
		
		MDButton* back = [ [ MDButton alloc ] initWithFrame:MakeRect(frame.x
			+ 120, frame.y + 15, 30, 30) background:[ NSColor colorWithCalibratedRed:0.95
					green:0.95 blue:0.95 alpha:[ bkg alphaComponent ] ] ];
		[ views removeObject:back ];
		[ back setTextFont:[ NSFont systemFontOfSize:14 ] ];
		[ back setText:@"←" ];
		[ back setIdentity:@"Back" ];
		[ back setTarget:self ];
		[ back setAction:@selector(goBack:) ];
		[ back setEnabled:NO ];
		[ subViews addObject:back ];
		
		MDButton* forward = [ [ MDButton alloc ] initWithFrame:MakeRect(frame.x + frame.width
			- 150, frame.y + 15, 30, 30) background:[ NSColor colorWithCalibratedRed:0.95
						green:0.95 blue:0.95 alpha:[ bkg alphaComponent ] ] ];
		[ views removeObject:forward ];
		[ forward setTextFont:[ NSFont systemFontOfSize:14 ] ];
		[ forward setText:@"→" ];
		[ forward setIdentity:@"Forward" ];
		[ forward setTarget:self ];
		[ forward setAction:@selector(goForward:) ];
		[ forward setEnabled:NO ];
		[ subViews addObject:forward ];
		
		NSArray* array = [ [ NSFileManager defaultManager ]
									  contentsOfDirectoryAtPath:
						  @"/" error:nil ];
		for (int z = 0; z < [ array count ]; z++)
		{
			BOOL isDir = FALSE;
			[ [ NSFileManager defaultManager ] fileExistsAtPath:[ NSString stringWithFormat:
				@"%@%@", filename, array[z] ] isDirectory:&isDir ];
			if (![ array[z] hasPrefix:@"." ] || showHidden)
			{
				[ table addRow:@{@"File": array[z]} ];
			}
			else
				continue;
			//if (!isDir)
			{
				NSImage* img = [ [ NSWorkspace sharedWorkspace ] iconForFile:[ NSString
						stringWithFormat:@"%@%@", filename, array[z] ] ];
				unsigned int theImg = 0;
				LoadImage((const char*)[ [ img TIFFRepresentation ] bytes ], &theImg,
						  (int)[ [ img TIFFRepresentation ] length ]);
				if (theImg != 0)
				{
					[ images addObject:@(theImg) ];
					[ table setImage:theImg atIndex:[ table numberOfRows ] - 1 ];
				}
			}
			//else if (isDir)
			//	[ table setImage:folderImg atIndex:[ table numberOfRows ] - 1 ];
		}
		
		[ table setClickTarget:self ];
		[ table setSingleClickAction:@selector(singleClick:) ];
		[ table setDoubleClickAction:@selector(doubleClick:) ];
		[ subViews addObject:table ];
		
		[ self setFrame:rect ];
	}
	return self;
}

- (void) loadImages
{
	@autoreleasepool {
		MDTableView* table = nil;
		for (int z = 0; z < [ subViews count ]; z++)
		{
			if ([ [ (MDControlView*)subViews[z] identity ]
				 isEqualToString:@"File Table" ])
			{
				table = subViews[z];
				break;
			}
		}
		if (!table)
			return;
		
		for (int z = 0; z < [ table numberOfRows ]; z++)
		{
			if (!thread)
			{
				NSLog(@"End");
				[ NSThread exit ];
				return;
			}
			if (![ table rowIsVisible:z ])
				continue;
			
			NSImage* img = [ [ NSWorkspace sharedWorkspace ] iconForFile:[ NSString
								stringWithFormat:@"%@%@", filename, [ table objectAtRow:z ][@"File"] ] ];
			//NSLog(@"%f, %f", [ img size ].width, [ img size ].width);
			unsigned int theImg = 0;
			NSData* tiffImage = [ img TIFFRepresentation ];
			
			LoadImage((const char*)[ tiffImage bytes ], &theImg,
					  (int)[ tiffImage length ]);
			if (theImg != 0)
			{
				[ images addObject:@(theImg) ];
				[ table setImage:theImg atIndex:z ];
			}
		}
	}
	
	thread = nil;
	
	NSLog(@"End");
}

- (void) scrollWheel:(NSEvent *)event
{
	MDTableView* table = nil;
	for (int z = 0; z < [ subViews count ]; z++)
	{
		if ([ [ (MDControlView*)subViews[z] identity ]
			 isEqualToString:@"File Table" ])
		{
			table = subViews[z];
			break;
		}
	}
	if (!table)
		return;
	
	[ images removeAllObjects ];
	
	NSMutableIndexSet* index1 = [ [ NSMutableIndexSet alloc ] init ];
	for (unsigned int z = 0; z < [ table numberOfRows ]; z++)
	{
		if ([ table rowIsVisible:z ])
			[ index1 addIndex:z ];
	}
	
	[ super scrollWheel:event ];
	
	NSMutableIndexSet* index2 = [ [ NSMutableIndexSet alloc ] init ];
	for (unsigned int z = 0; z < [ table numberOfRows ]; z++)
	{
		if ([ table rowIsVisible:z ])
			[ index2 addIndex:z ];
	}
	
	//unsigned long firstIndex = [ index1 firstIndex ];
	unsigned long index = [ index1 firstIndex ];
	//unsigned int minus = 0;
	do
	{
		if (![ index2 containsIndex:index ])
		{
			unsigned int img = [ table imageAtIndex:(unsigned int)index ];
			ReleaseImage(&img);
			//[ images removeObjectAtIndex:index - minus - firstIndex ];
			//minus++;
		}
		else
			[ images addObject:@([ table imageAtIndex:(unsigned int)index ]) ];
		
		index = [ index1 indexGreaterThanIndex:index ];
	}
	while (index != NSNotFound);
	
	index = [ index2 firstIndex ];
	do
	{
		if (![ index1 containsIndex:index ])
		{
			NSImage* img = [ [ NSWorkspace sharedWorkspace ] iconForFile:[ NSString
					stringWithFormat:@"%@%@", filename, [ table objectAtRow:(unsigned int)index ][@"File"] ] ];
			//NSLog(@"%f, %f", [ img size ].width, [ img size ].width);
			unsigned int theImg = 0;
			NSData* tiffImage = [ img TIFFRepresentation ];
			
			LoadImage((const char*)[ tiffImage bytes ], &theImg,
					  (int)[ tiffImage length ]);
			if (theImg != 0)
			{
				[ images addObject:@(theImg) ];
				[ table setImage:theImg atIndex:(unsigned int)index ];
			}
		}
		index = [ index2 indexGreaterThanIndex:index ];
	}
	while (index != NSNotFound);
	
	/*for (int z = 0; z < [ images count ]; z++)
	{
		unsigned int img = [ [ images objectAtIndex:z ] unsignedIntValue ];
		ReleaseImage(&img);
	}
	[ images removeAllObjects ];*/
	
	/*if (loadingContext)
	{
		if (thread && [ thread isExecuting ])
		{
			NSLog(@"Cancel");
			[ thread cancel ];
			while ([ thread isExecuting ]) {}
			[ thread release ];
			thread = nil;
		}
		NSLog(@"Begin");
		thread = [ [ NSThread alloc ] initWithTarget:self selector:@selector(loadImages) object:nil ];
		[ thread start ];
	}
	else
		[ self loadImages ];*/
}

- (BOOL) update
{
	BOOL ret = TRUE;
	@autoreleasepool {
		MDTableView* table = nil;
		for (int z = 0; z < [ subViews count ]; z++)
		{
			if ([ [ (MDControlView*)subViews[z] identity ]
				 isEqualToString:@"File Table" ])
			{
				table = subViews[z];
				break;
			}
		}
		if (!table)
			return ret;
		
		MDTextField* textField = nil;
		for (int z = 0; z < [ subViews count ]; z++)
		{
			if ([ [ (MDControlView*)subViews[z] identity ]
				 isEqualToString:@"Name Field" ])
			{
				textField = subViews[z];
				break;
			}
		}
		if (!textField)
			return ret;
		
		NSString* backup = [ [ NSString alloc ] initWithString:filename ];
		if (button && files == nil)
		{
			[ redo removeAllObjects ];
			redoPointer = 0;
			[ undo addObject:backup ];
			undoPointer++;
			[ filename appendFormat:@"%@/", [ textField text ] ];
		}
		
		for (int z = 0; z < [ images count ]; z++)
		{
			unsigned int img = [ images[z] unsignedIntValue ];
			ReleaseImage(&img);
		}
		[ images removeAllObjects ];
		
		///static int fptr = 0;
		if (files == nil)
		{
			files = [ [ NSFileManager defaultManager ] contentsOfDirectoryAtPath:filename error:nil ];
			[ table removeAllRows ];
			//fptr = 0;
		}
		if (files != nil)
		{
			int z = 0;//fptr;
			int y = 0;
			//int amt = ((frame.height - 140 - [ table frameSize ].height) / 
			//		   [ table frameSize ].height) + 1;
			for (; ; z++, y++)
			{
				if (!(z < [ files count ]))
					break;
				BOOL isDir = FALSE;
				[ [ NSFileManager defaultManager ] fileExistsAtPath:[ NSString
						stringWithFormat:@"%@%@", filename, files[z] ]
														isDirectory:&isDir ];
				if (![ files[z] hasPrefix:@"." ] || showHidden)
				{
					[ table addRow:@{@"File": files[z]} ];
				}
				else
					continue;
				//if (isDir && ![ [ files objectAtIndex:z ] hasSuffix:@".app" ])
				//	[ table setImage:folderImg atIndex:[ table numberOfRows ] - 1 ];
				/*else */if ([ table rowIsVisible:[ table numberOfRows ] - 1 ])
				{
					NSImage* img = [ [ NSWorkspace sharedWorkspace ] iconForFile:[ NSString
							stringWithFormat:@"%@%@", filename, files[z] ] ];
					//NSLog(@"%f, %f", [ img size ].width, [ img size ].width);
					unsigned int theImg = 0;
					NSData* tiffImage = [ img TIFFRepresentation ];
					
					LoadImage((const char*)[ tiffImage bytes ], &theImg,
							  (int)[ tiffImage length ]);
					if (theImg != 0)
					{
						[ images addObject:@(theImg) ];
						[ table setImage:theImg atIndex:[ table numberOfRows ] - 1 ];
					}
				}
			}
			if (z >= [ files count ])
				ret = FALSE;
			//fptr = z;
		}
		else
			filename = [ [ NSMutableString alloc ] initWithString:backup ];
	}
	
	shouldUpdate = ret;
	return ret;
}

- (void) goBack: (id) sender
{
	if (filename)
	{
		NSString* backup = [ [ NSString alloc ] initWithString:filename ];
		[ redo addObject:backup ];
		redoPointer++;
		filename = [ [ NSMutableString alloc ] initWithString:undo[--undoPointer] ];
		[ undo removeObjectAtIndex:undoPointer ];
		
	}
	if (undoPointer == 0)
		[ sender setEnabled:NO ];
	
	MDButton* forward = nil;
	for (int z = 0; z < [ subViews count ]; z++)
	{
		if ([ [ (MDControlView*)subViews[z] identity ]
			 isEqualToString:@"Forward" ])
		{
			forward = subViews[z];
			break;
		}
	}
	[ forward setEnabled:YES ];
	
	button = NO;
	shouldUpdate = YES;
	files = nil;
}

- (void) goForward: (id) sender
{
	if (filename)
	{
		NSString* backup = [ [ NSString alloc ] initWithString:filename ];
		[ undo addObject:backup ];
		undoPointer++;
		filename = [ [ NSMutableString alloc ] initWithString:redo[--redoPointer] ];
		[ redo removeObjectAtIndex:redoPointer ];
	}
	if (redoPointer == 0)
		[ sender setEnabled:NO ];
	MDButton* back = nil;
	for (int z = 0; z < [ subViews count ]; z++)
	{
		if ([ [ (MDControlView*)subViews[z] identity ]
			 isEqualToString:@"Back" ])
		{
			back = subViews[z];
			break;
		}
	}
	[ back setEnabled:YES ];
	
	button = NO;
	shouldUpdate = YES;
	files = nil;
}

- (void) setShowHidden: (BOOL)show
{
	showHidden = show;
}

- (BOOL) showHidden
{
	return showHidden;
}

- (void) open: (id) sender
{
	MDTextField* textField = nil;
	for (int z = 0; z < [ subViews count ]; z++)
	{
		if ([ [ (MDControlView*)subViews[z] identity ]
			 isEqualToString:@"Name Field" ])
		{
			textField = subViews[z];
			break;
		}
	}
	if (!textField)
		return;
	
	MDTableView* table = nil;
	for (int z = 0; z < [ subViews count ]; z++)
	{
		if ([ [ (MDControlView*)subViews[z] identity ]
			 isEqualToString:@"File Table" ])
		{
			table = subViews[z];
			break;
		}
	}
	if (!table)
		return;
	
	BOOL dir = NO;
	BOOL result = [ [ NSFileManager defaultManager ] fileExistsAtPath:[ NSString 
			stringWithFormat:@"%@%@", filename, [ textField text ] ] isDirectory:&dir ];
	if (!result)
		return;
	if (dir)
	{
		MDButton* back = nil;
		for (int z = 0; z < [ subViews count ]; z++)
		{
			if ([ [ (MDControlView*)subViews[z] identity ] isEqualToString:
				 @"Back" ])
			{
				back = subViews[z];
				break;
			}
		}
		if (back)
			[ back setEnabled:YES ];
		MDButton* forward = nil;
		for (int z = 0; z < [ subViews count ]; z++)
		{
			if ([ [ (MDControlView*)subViews[z] identity ] isEqualToString:
				 @"Forward" ])
			{
				forward = subViews[z];
				break;
			}
		}
		if (forward)
			[ forward setEnabled:NO ];
		
		button = YES;
		shouldUpdate = YES;
		files = nil;
		
		[ sender setEnabled:NO ];
		return;
	}
	
	[ filename appendFormat:@"%@", [ textField text ] ];
	
	if (actTar && [ actTar respondsToSelector:actSel ])
		((void (*)(id, SEL, id))[ actTar methodForSelector:actSel ])(actTar, actSel, filename);
	[ self close:sender ];
}

- (void) finishDraw
{
	if (shouldUpdate)
	{
		if (loadingContext)
		{
			shouldUpdate = FALSE;
			[ NSThread detachNewThreadSelector:@selector(update) toTarget:self withObject:nil ];
		}
		else
			shouldUpdate = [ self update ];
	}
}

- (void) singleClick: (id) sender
{
	MDTextField* textField = nil;
	for (int z = 0; z < [ subViews count ]; z++)
	{
		if ([ [ (MDControlView*)subViews[z] identity ]
			 isEqualToString:@"Name Field" ])
		{
			textField = subViews[z];
			break;
		}
	}
	if (textField)
	{
		[ textField setText:[ (MDTableView*)sender objectAtRow:
				[ (MDTableView*)sender selectedRow ] ][@"File"] ];
		[ self checkKey:textField ];
	}
}

- (void) doubleClick: (id) sender
{
	MDTextField* textField = nil;
	for (int z = 0; z < [ subViews count ]; z++)
	{
		if ([ [ (MDControlView*)subViews[z] identity ]
			 isEqualToString:@"Name Field" ])
		{
			textField = subViews[z];
			break;
		}
	}
	if (textField == nil)
		return;
	
	MDTableView* table = nil;
	for (int z = 0; z < [ subViews count ]; z++)
	{
		if ([ [ (MDControlView*)subViews[z] identity ]
			 isEqualToString:@"File Table" ])
		{
			table = subViews[z];
			break;
		}
	}
	if (table == nil)
		return;
	
	BOOL dir = NO;
	BOOL result = [ [ NSFileManager defaultManager ] fileExistsAtPath:[ NSString 
		stringWithFormat:@"%@%@", filename, (NSString*)[ table objectAtRow:
			[ table selectedRow ] ][@"File"] ] isDirectory:&dir ];
	if (!result)
		return;
	bool hasSuffix = false;
	if (fileTypes && [ fileTypes count ] == 0)
		hasSuffix = true;
	for (int z = 0; z < [ fileTypes count ]; z++)
	{
		if ([ [ textField text ] hasSuffix:fileTypes[z] ])
		{
			hasSuffix = true;
			break;
		}
	}
	if (hasSuffix && !dir)
	{
		[ filename appendFormat:@"%@", [ textField text ] ];
		
		if (actTar && [ actTar respondsToSelector:actSel ])
			((void (*)(id, SEL, id))[ actTar methodForSelector:actSel ])(actTar, actSel, filename);
		
		[ self close:self ];
		return;
	}
	else if (dir)
	{
		MDButton* back = nil;
		for (int z = 0; z < [ subViews count ]; z++)
		{
			if ([ [ (MDControlView*)subViews[z] identity ] isEqualToString:
				 @"Back" ])
			{
				back = subViews[z];
				break;
			}
		}
		if (back)
			[ back setEnabled:YES ];
		MDButton* forward = nil;
		for (int z = 0; z < [ subViews count ]; z++)
		{
			if ([ [ (MDControlView*)subViews[z] identity ] isEqualToString:
				 @"Forward" ])
			{
				forward = subViews[z];
				break;
			}
		}
		if (forward)
			[ forward setEnabled:NO ];
		
		button = YES;
		shouldUpdate = YES;
		files = nil;
		
		MDTableView* open = nil;
		for (int z = 0; z < [ subViews count ]; z++)
		{
			if ([ [ (MDControlView*)subViews[z] identity ]
				 isEqualToString:@"Open" ])
			{
				open = subViews[z];
				break;
			}
		}
		if (open == nil)
			return;
		[ open setEnabled:NO ];
	}
}

- (void) setActionTarget: (id) otar
{
	actTar = otar;
}

- (id) actionTarget
{
	return actTar;
}

- (void) setActionSelector: (SEL) osel
{
	actSel = osel;
}

- (SEL) actionSelector
{
	return actSel;
}

- (void) setFileTypes: (NSArray*) array
{
	fileTypes = [ [ NSMutableArray alloc ] initWithArray:array ];
}

- (NSMutableArray*) fileTypes
{
	return fileTypes;
}

- (void) checkKey: (id) sender
{
	MDButton* view = nil;
	for (int z = 0; z < [ subViews count ]; z++)
	{
		if ([ [ (MDControlView*)subViews[z] identity ]
			 isEqualToString:@"Open" ])
		{
			view = subViews[z];
			break;
		}
	}
	if (view != nil)
	{
		BOOL isDir = false;
		bool enable = [ [ NSFileManager defaultManager ] fileExistsAtPath:
			[ NSString stringWithFormat:@"%@%@", filename, [ sender text ] ] 
															  isDirectory:&isDir ];
		bool hasSuffix = false;
		if ([ fileTypes count ] == 0)
			hasSuffix = true;
		for (int z = 0; z < [ fileTypes count ]; z++)
		{
			if ([ [ sender text ] hasSuffix:fileTypes[z] ])
			{
				hasSuffix = true;
				break;
			}
		}
		[ view setEnabled:(enable && !isDir && hasSuffix) || isDir ];
	}
}

- (void) drawView
{
	if (!visible)
		return;
	
	[ super drawView ];
}

- (void) dealloc
{
	ReleaseImage(&folderImg);
	if (images)
	{
		for (int z = 0; z < [ images count ]; z++)
		{
			unsigned int img = [ images[z] unsignedIntValue ];
			ReleaseImage(&img);
		}
		images = nil;
	}
}

@end
