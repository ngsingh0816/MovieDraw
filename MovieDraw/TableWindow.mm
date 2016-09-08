//
//  TableWindow.m
//  Emu
//
//  Created by Singh on 6/11/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "TableWindow.h"

@implementation NSImage (Scaling)

- (NSImage*)imageByScalingProportionallyToSize:(NSSize)targetSize
{
	NSImage* sourceImage = self;
	NSImage* newImage = nil;
	
	if ([sourceImage isValid])
	{
		NSSize imageSize = [sourceImage size];
		float width  = imageSize.width;
		float height = imageSize.height;
		
		float targetWidth  = targetSize.width;
		float targetHeight = targetSize.height;
		
		float scaleFactor  = 0.0;
		float scaledWidth  = targetWidth;
		float scaledHeight = targetHeight;
		
		NSPoint thumbnailPoint = NSZeroPoint;
		
		if ( NSEqualSizes( imageSize, targetSize ) == NO )
		{
			
			float widthFactor  = targetWidth / width;
			float heightFactor = targetHeight / height;
			
			if ( widthFactor < heightFactor )
				scaleFactor = widthFactor;
			else
				scaleFactor = heightFactor;
			
			scaledWidth  = width  * scaleFactor;
			scaledHeight = height * scaleFactor;
			
			if ( widthFactor < heightFactor )
				thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
			
			else if ( widthFactor > heightFactor )
				thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
		}
		
		newImage = [[NSImage alloc] initWithSize:targetSize];
		
		[newImage lockFocus];
		
		NSRect thumbnailRect;
		thumbnailRect.origin = thumbnailPoint;
		thumbnailRect.size.width = scaledWidth;
		thumbnailRect.size.height = scaledHeight;
		
		[sourceImage drawInRect: thumbnailRect
					   fromRect: NSZeroRect
					  operation: NSCompositeSourceOver
					   fraction: 1.0];
		
		[newImage unlockFocus];
		
	}
	
	return newImage;
}

@end

@implementation TableCell

- (id)dataCellForRow:(long)row
{
    if (row < [ cells count ] && row >= 0)
        return cells[row];
    return [ super dataCellForRow:row ];
}

- (NSMutableArray*) cells
{
	if (!cells)
		cells = [ [ NSMutableArray alloc ] init ];
	return cells;
}

- (void) addCell: (id)cell
{
	if (!cells)
		cells = [ [ NSMutableArray alloc ] init ];
	[ cells addObject:cell ];
}

@end


@implementation TableWindow

// Creation
- (void) awakeFromNib
{
	if (!items)
		items = [ NSMutableArray array ];
	[self setDataSource:self];	// Set the data
	[self reloadData];	// Refresh
}

// Items
- (NSMutableArray *)items {
	return items;
}

// Object At Row
- (id) itemAtRow: (unsigned)row
{
	if (row >= [ items count ])
		return nil;
	return items[row];
}

// Text
- (id) selectedRowItemforColumnIdentifier:(NSString * )anIdentifier
{
	// If a row is selected, give the object of the column's selected row
	if ([self selectedRow] != -1)
		return items[[self selectedRow]][anIdentifier];
	
	// Otherwise give nothing
	return nil;
}

// Replace row
- (void) replaceRow: (unsigned)row item: (NSDictionary*) obj
{
	items[row] = [ NSMutableDictionary dictionaryWithDictionary:obj ];
	[ self reloadData ];	// Refresh
}

// Delete all items
- (void) removeAllRows
{
	[ self setItems:[ NSMutableArray array ] ];
}

// Set
- (void) setItems:(NSMutableArray *) anArray 
{
	// Check to see if equal
	if (items == anArray)
		return;
	// Set
	items = [ [ NSMutableArray alloc ] initWithArray:anArray ];
	// Refresh
	[self reloadData];
}

// Add
- (void) addRow:(NSDictionary *) item 
{
	// Push back object
	[items insertObject:[ NSMutableDictionary dictionaryWithDictionary:item ] atIndex:[items count]];
	// Refresh
	[self reloadData];
}

// Remove
- (void) removeRow:(unsigned) row 
{
	// Delete
	[items removeObjectAtIndex:row];
	// Refresh
	[self reloadData];
}

// Mouse Down
- (void) mouseDown:(NSEvent *)theEvent
{
	[ super mouseDown: theEvent ];
	if ([ theEvent modifierFlags ] & NSControlKeyMask)
		[ self rightMouseDown:theEvent ];
}

// Right Mouse Down
- (void) rightMouseDown:(NSEvent *)theEvent
{
	[ super rightMouseDown:theEvent ];
	rightEvent = theEvent;
	if ([ [ self target ] respondsToSelector:rightAction ])
		((void (*)(id, SEL, id))[ [ self target ] methodForSelector:rightAction ])([ self target ], rightAction, self);
}

- (NSEvent*) rightEvent
{
	return rightEvent;
}

// Right Mouse Down Action
- (SEL) rightAction
{
	return rightAction;
}

// Right Mouse Down Action
- (void) setRightAction: (SEL) sel
{
	rightAction = sel;
}

// Number of rows
- (NSInteger) numberOfRowsInTableView:(NSTableView *)tableView 
{
	return [items count];
}

// Other stuff
- (id) tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	if (row != -1)
		return items[row][[tableColumn identifier]];
	
	return nil;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row;
{
	if ([ items[row][[ tableColumn identifier ]] isKindOfClass:[ NSString class ] ])
		oldObject = [ [ NSString alloc ] initWithString:items[row][[ tableColumn identifier ]] ];
	else
		oldObject = nil;
	editedIdentifier = [ [ NSString alloc ] initWithString:[ tableColumn identifier ] ];
	items[row][[ tableColumn identifier ]] = object;
	[ self reloadData ];
	
	if (editTarget && editAction && [ editTarget respondsToSelector:editAction ])
		((void (*)(id, SEL, id))[ editTarget methodForSelector:editAction ])(editTarget, editAction, @(row));
}

- (void) setEditTarget: (id) tar
{
	editTarget = tar;
}

- (id) editTarget
{
	return editTarget;
}

- (void) setEditAction: (SEL) act
{
	editAction = act;
}

- (SEL) editAction
{
	return editAction;
}

- (id) oldObject
{
	return oldObject;
}

- (NSString*) editedIdentifier
{
	return editedIdentifier;
}

@end
