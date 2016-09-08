//
//  TableWindow.h
//  Emu
//
//  Created by Singh on 6/11/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSImage (Scaling)

- (NSImage*)imageByScalingProportionallyToSize:(NSSize)targetSize;

@end

@interface TableCell : NSTableColumn
{
	NSMutableArray* cells;
}

@property (readonly, copy) NSMutableArray *cells;
- (void) addCell: (id)cell;

@end

@interface TableWindow : NSTableView<NSTableViewDataSource>
{
	NSMutableArray* items;		// Items
	SEL rightAction;			// Action
	id editTarget;
	SEL editAction;
	id oldObject;
	NSString* editedIdentifier;
	NSEvent* rightEvent;
}

// Item Mutation	// Set Items
- (void) addRow: (NSDictionary*)item;		// Add Row
- (void) removeRow: (unsigned)row;			// Remove Row
- (void) replaceRow: (unsigned)row item: (NSDictionary*) obj;	// Replace Row
- (void) removeAllRows;						// Delete all items
- (id) itemAtRow: (unsigned)row;			// Item at row

// Mouse
- (void) mouseDown:(NSEvent *)theEvent;		// Mouse Down
- (void) rightMouseDown:(NSEvent *)theEvent;// Mouse Down
@property  SEL rightAction;		// Right Mouse Down Action		// Set Right Action
@property (readonly, copy) NSEvent *rightEvent;

// Info
@property (copy) NSMutableArray *items;	// Items
- (id) selectedRowItemforColumnIdentifier: (NSString*) anIdentifier;	// Text of column's seleced row
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView; // # of rows
- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row;

// Editing
@property (strong) id editTarget;
@property  SEL editAction;
@property (readonly, strong) id oldObject;
@property (readonly, copy) NSString *editedIdentifier;

@end