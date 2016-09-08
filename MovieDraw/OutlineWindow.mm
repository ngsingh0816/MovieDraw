//
//  OutlineWindow.mm
//  MovieDraw
//
//  Created by Neil on 7/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "OutlineWindow.h"
#include <vector>

@implementation IFNode

// Create the 'leaf' node (a node with no subnodes)
- (instancetype)initLeafWithTitle:(NSString *)theTitle {
	if((self = [super init])) {
		title = [ [ NSString alloc ] initWithString:theTitle ];
		children = nil;
		isParent = NO;
		isVisible = YES;
		isExpanded = NO;
	}
	
	return self;
}

// Create a 'parent' node (a node with subnodes)
- (instancetype)initParentWithTitle:(NSString *)theTitle children:(NSMutableArray *)theChildren {
	if((self = [super init])) {
		title = [ [ NSString alloc ] initWithString:theTitle ];
		children = (theChildren != nil ? [ [ NSMutableArray alloc ] initWithArray:theChildren ] : [ [ NSMutableArray alloc ] init ]);
		isParent = YES;
		isVisible = YES;
		isExpanded = NO;
	}
	
	return self;
}

// Add a child to the parent node (in case of a leaf node, this code does nothing)
- (void)addChild:(IFNode *)theChild {
	[ theChild setParentItem:self ];
	[ children addObject:theChild];
}

// Insert a child at a given index (comes handy later when implementing drag-and-drop in the sidebar)
- (void)insertChild:(IFNode *)theChild atIndex:(NSUInteger)theIndex {
	// Exclude invisible
	unsigned long actual = theIndex;
	for (int z = 0; z <= theIndex; z++)
	{
		if (z >= [ children count ])
			return;
		if (![ children[z] visible ])
			actual--;
	}
	[ theChild setParentItem:self ];
	[ children insertObject:theChild atIndex:actual];
}

// Removing a child from the parent node
- (void)removeChild:(IFNode *)theChild {
	[ theChild setParentItem:nil ];
	[ children removeObject:theChild];
}

- (void) removeChildren
{
	[ children removeAllObjects ];
}

// Getting the number of children a node has (needed for the sidebar datasource methods)
- (NSInteger)numberOfChildren {
	// Exclude invisible
	int count = 0;
	for (int z = 0; z < [ children count ]; z++)
	{
		if ([ children[z] visible ])
			count++;
	}
	return count;
}

// Getting a given child (needed for the sidebar datasource methods)
- (IFNode *)childAtIndex:(NSUInteger)theIndex {
	long actual = -1;
	for (int z = 0; z < [ children count ]; z++)
	{
		if ([ children[z] visible ])
			actual++;
		if (actual == theIndex)
			return children[z];
	}
	return nil;
}

- (IFNode*) childWithTitle: (NSString*) string
{
	for (int z = 0; z < [ children count ]; z++)
	{
		if ([ [ children[z] title ] isEqualToString:string ])
			return children[z];
	}
	return nil;
}

- (BOOL) containsLeaf
{
	BOOL contains = FALSE;
	for (int z = 0; z < [ children count ]; z++)
	{
		if (![ children[z] isParent ] && [ children[z] visible ])
		{
			contains = TRUE;
			break;
		}
	}
	return contains;
}

- (void) setTitle: (NSString*) theTitle
{
	title = [ [ NSString alloc ] initWithString:theTitle ];
}

- (NSString*) title
{
	return title;
}

- (void) setChildren: (NSArray*) childs
{
	children = [ [ NSMutableArray alloc ] initWithArray:childs ];
}

- (NSMutableArray*) children
{
	return children;
}

- (void) setIsParent: (BOOL)set
{
	isParent = set;
}

- (BOOL) isParent
{
	return isParent;
}

- (void) setDictionary: (NSDictionary*) dict
{
	dictionary = [ [ NSDictionary alloc ] initWithDictionary:dict ];
}

- (NSDictionary*) dictionary
{
	return dictionary;
}

- (void) setVisible: (BOOL) vis
{
	isVisible = vis;
}

- (BOOL) visible
{
	return isVisible;
}

- (void) setExpanded: (BOOL) exp
{
	isExpanded = exp;
}

- (BOOL) expanded
{
	return isExpanded;
}

- (void) setParentItem: (IFNode*)par
{
	parent = par;
}

- (IFNode*) parentItem
{
	return parent;
}

- (void) setTarget: (id)tar
{
	target = tar;
}

- (id) target
{
	return target;
}

- (void) setAction: (SEL)act
{
	action = act;
}

- (SEL) action
{
	return action;
}

- (void) parse: (IFNode*)node withString:(NSMutableString*)string
{
	if ([ [ node parentItem ] parentItem ] == nil)
		return;
	
	[ string insertString:[ NSString stringWithFormat:@"%@/", [ [ node parentItem ] title ] ] atIndex:0 ];
	[ self parse:[ node parentItem ] withString:string ];
}

- (NSString*) parentsPath
{
	NSMutableString* string = [ NSMutableString stringWithString:@"" ];
	[ self parse:self withString:string ];
	return string;
}

@end

@implementation OutlineWindow

- (instancetype)init
{
    self = [super init];
    if (self) {
        rootNode = [ [ IFNode alloc ] initParentWithTitle:@"Root node" children:nil ];
		[ rootNode setExpanded:YES ];
		[self setDataSource:self];	// Set the data
		[ self setDelegate:(id)self ];
		[self reloadData];	// Refresh
		sameSel = TRUE;
		showGroups = TRUE;
		selectParents = FALSE;
		doubleClickEdit = FALSE;
		deleteEmptyTitles = FALSE;
    }
    
    return self;
}

- (void) awakeFromNib
{
	rootNode = [ [ IFNode alloc ] initParentWithTitle:@"Root node" children:nil ];
	[ rootNode setExpanded:YES ];
	[self setDataSource:self];	// Set the data
	[ self setDelegate:(id)self ];
	[self reloadData];	// Refresh
	sameSel = TRUE;
	showGroups = TRUE;
	selectParents = FALSE;
	doubleClickEdit = FALSE;
	deleteEmptyTitles = FALSE;
}

- (IFNode*) rootNode
{
	return rootNode;
}

- (void) removeAllItems
{
	rootNode = [ [ IFNode alloc ] initParentWithTitle:@"Root node" children:nil ];
	[ rootNode setExpanded:YES ];
	[ self reloadData ];
}

- (void) removeNodeWithTitle: (NSString*)title
{
	for (int z = 0; z < [ [ rootNode children ] count ]; z++)
	{
		if ([ [ [ rootNode childAtIndex:z ] title ] isEqualToString:title ])
		{
			[ rootNode removeChild:[ rootNode childAtIndex:z ] ];
			break;
		}
	}
	[ self reloadData ];
}

- (IFNode*) selectedNode
{
	return [ self itemAtRow:[ self selectedRow ] ];
}

- (void) selectNode: (IFNode*)node
{
	if ([ self selectedNode ] == node && sameSel)
	{
		if (target && selectAction && [ target respondsToSelector:selectAction ])
			((void (*)(id, SEL, id))[ target methodForSelector:selectAction ])(target, selectAction, self);
	}
	[ self selectRowIndexes:[ NSIndexSet indexSetWithIndex:[ self rowForItem:node ] ] byExtendingSelection:NO ];
}

- (void) setTarget:(id)tar
{
	target = tar;
}

- (id) target
{
	return target;
}
- (void) setSelectAction: (SEL)act
{
	selectAction = act;
}

- (SEL) selectAction
{
	return selectAction;
}

- (void) setEditAction: (SEL)act
{
	editAction = act;
}

- (SEL) editAction
{
	return editAction;
}

- (void) setRightClickAction: (SEL)act
{
	rightClickAction = act;
}

- (SEL) rightClickAction
{
	return rightClickAction;
}

- (void) setSameSelection: (BOOL)same
{
	sameSel = same;
}

- (BOOL) sameSelection
{
	return sameSel;
}

- (BOOL) acceptsFirstResponder
{
	return YES;
}

- (void) rightMouseDown:(NSEvent *)theEvent
{
	NSPoint p = [ self convertPoint:[ theEvent locationInWindow ] fromView:nil ];
	[ self selectRowIndexes:[ NSIndexSet indexSetWithIndex:[ self rowAtPoint:p ] ] byExtendingSelection:NO ];
	if (target && rightClickAction && [ target respondsToSelector:rightClickAction ])
		((void (*)(id, SEL, id))[ target methodForSelector:rightClickAction ])(target, rightClickAction, theEvent);
}

- (void) mouseDown:(NSEvent *)theEvent
{
	if ([ theEvent modifierFlags ] & NSControlKeyMask)
	{
		[ self rightMouseDown:theEvent ];
		return;
	}
	if (doubleClickEdit)
	{
		std::vector<BOOL> tables;
		for (int z = 0; z < [ [ self tableColumns ] count ]; z++)
		{
			tables.push_back( [ [ self tableColumns ][z] isEditable ]);
			[ [ self tableColumns ][z] setEditable:NO ];
		}
		[ super mouseDown:theEvent ];
		for (int z = 0; z < [ [ self tableColumns ] count ]; z++)
			[ [ self tableColumns ][z] setEditable:tables[z] ];
	}
	else
		[ super mouseDown:theEvent ];
}

- (void) parse: (IFNode*) node withArray:(NSMutableArray*)array
{
	for (unsigned long z = 0; z < [ node numberOfChildren ]; z++)
	{
		if (![ [ node childAtIndex:z ] isParent ])
		{
			[ array addObject:[ node childAtIndex:z ] ];
			continue;
		}
		[ self parse:[ node childAtIndex:z ] withArray:array ];
	}
}

- (NSArray*) allLeafs
{
	return [ self allLeafsOfParent:rootNode ];
}

- (NSArray*) allLeafsOfParent:(IFNode*)node
{
	NSMutableArray* array = [ [ NSMutableArray alloc ] init ];
	[ self parse:node withArray:array ];
	return array;
}

- (void) parseNodes:(IFNode*)node withArray:(NSMutableArray*)array
{
	[ array addObject:node ];
	for (unsigned long z = 0; z < [ node numberOfChildren ]; z++)
	{
		if (![ [ node childAtIndex:z ] isParent ])
		{
			[ array addObject:[ node childAtIndex:z ] ];
			continue;
		}
		[ self parseNodes:[ node childAtIndex:z ] withArray:array ];
	}
}

- (NSArray*) allNodes
{
	NSMutableArray* array = [ [ NSMutableArray alloc ] init ];
	[ self parseNodes:rootNode withArray:array ];
	return array;
}

- (BOOL) showGroups
{
	return showGroups;
}

- (void) setShowsGroups:(BOOL)groups
{
	showGroups = groups;
}

- (BOOL) selectParents
{
	return selectParents;
}

- (void) setSelectParents:(BOOL)pars
{
	selectParents = pars;
}

- (BOOL) doubleClickInsteadOfEdit
{
	return doubleClickEdit;
}

- (void) setDoubleClickInsteadOfEdit:(BOOL)ed
{
	doubleClickEdit = ed;
}

- (void) SetDeleteEmptyTitles:(BOOL)del
{
	deleteEmptyTitles = del;
}

- (BOOL) deleteEmptyTitles
{
	return deleteEmptyTitles;
}

- (BOOL) isEditing
{
	return editing;
}

- (void) setEditing:(BOOL)edit
{
	editing = edit;
}

#pragma mark -
#pragma mark NSOutlineView Datasource Methods

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
	// The "item" input is actually an IFNode, but the compiler doesn't know this
	// We have to convert it with a cast
	// Also, if item is nil, we have to return the number of children of the root node
	return (item == nil ? [rootNode childAtIndex:index] : [(IFNode *)item childAtIndex:index]);
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
	// The boolean we return signals whether we can expand or retract a row
	// If the node is a parent, we return yes, and if not, no (we also return NO for the root node)
	return (item == nil ? NO : [ (IFNode *)item isParent ]);
	
	// Alternately, if you don't want any items to expand and collapse, ever, just return NO.
	// Just make sure to expand all the items manually first, though (they start off completely collapsed
	// [outlineView expandItem:nil children:YES];
	// return NO;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
	// This is rather self-explanatory, the sidebar just wants to know how many children a given node has
	// If the item is nil, however, we need to return the number of children that the root node has...
	return (item == nil ? [rootNode numberOfChildren] : [(IFNode *)item numberOfChildren]);
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
	// This is probably the most important method in all of the datasource methods
	// This is the method that tells the sidebar what to display
	
	// In our case, we want to display a string, but you can display an image, a web view, anything (you do have to change the sidebar's principal cell class, but that's not difficult)
	// So to display the name of the node, we just return its title
	if ([ item dictionary ] && [ tableColumn identifier ] &&
		[ [ [ item dictionary ] allKeys ] containsObject:[ tableColumn identifier ] ])
		return [ item dictionary ][[ tableColumn identifier ]];
	if (![ tableColumn identifier ])
		return [ (IFNode *)item title ];
	return nil;
}

- (void) outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	IFNode* oldItem = [ [ IFNode alloc ] init ];
	[ oldItem setTitle:[ item title ] ];
	[ oldItem setChildren:[ NSArray arrayWithArray:[ item children ] ] ];
	[ oldItem setIsParent:[ item isParent ] ];
	[ oldItem setParentItem:[ (IFNode*)item parentItem ] ];
	[ oldItem setExpanded:[ item expanded ] ];
	[ oldItem setVisible:[ item visible ] ];
	[ oldItem setDictionary:[ NSDictionary dictionaryWithDictionary:[ item dictionary ] ] ];
	if ([ item dictionary ] && [ tableColumn identifier ] &&
		[ [ [ item dictionary ] allKeys ] containsObject:[ tableColumn identifier ] ])
	{
		NSMutableDictionary* dict = [ [ NSMutableDictionary alloc ] initWithDictionary:[ item dictionary ] ];
		[ dict removeObjectForKey:[ tableColumn identifier ] ];
		NSDictionary* dictionary = @{[ tableColumn identifier ]: object};
		[ dict addEntriesFromDictionary:dictionary ];
		[ item setDictionary:dict ];
	}
	else if (![ tableColumn identifier ])
	{
		if ([ object isKindOfClass:[ NSString class ] ])
			[ (IFNode*)item setTitle:object ];
	}
	if (target && editAction && [ target respondsToSelector:editAction ])
		((void (*)(id, SEL, id, id))[ target methodForSelector:editAction ])(target, editAction, item, oldItem);
}

#pragma mark -
#pragma mark NSOutlineView Delegate Methods
- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item {
	// I have no idea why this is in the Delegate Methods instead of the Datasource methods like it should be, but whatever
	// This tells the sidebar to draw the title of the node like a section indicator (for instance, like the blue "Library" heading in the iTunes sidebar)
	// In our case, we want all parent nodes in blue, though if you have more than two tiers of nodes, this is not really practical
	if (showGroups)
		return [ (IFNode*)item isParent ];
	return NO;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item {
	// Normally, headers in sidebars are not selectable, so we're going to reject selecting table headers
	// In this case, table headers coincide with parent objects, so we'll return NO if the node is a parent, and YES if it's a child
	if (selectParents)
		return YES;
	return (item == nil ? NO : ![ (IFNode *)item isParent ]);
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
	if (target && selectAction && [ target respondsToSelector:selectAction ])
		((void (*)(id, SEL, id))[ target methodForSelector:selectAction ])(target, selectAction, self);
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldExpandItem:(id)item
{
	[ (IFNode*)item setExpanded:YES ];
	if ([ (IFNode*)item target ] && [ [ (IFNode*)item target ] respondsToSelector:[ (IFNode*)item action ] ] && !reloading)
		((void (*)(id, SEL, id))[ [ (IFNode*)item target ] methodForSelector:[ (IFNode*)item action ] ])([ (IFNode*)item target ], [ (IFNode*)item action ], item);
	return YES;
}

- (void) textDidEndEditing:(NSNotification *)notification
{	
	[ super textDidEndEditing:notification ];
	[ self reloadData ];
}

- (IFNode*) firstLeaf: (IFNode*) node
{
	for (int z = 0; z < [ node numberOfChildren ]; z++)
	{
		if ([ [ node childAtIndex:z ] expanded ] && [ [ node childAtIndex:z ] visible ])
		{
			IFNode* n = [ self firstLeaf:[ node childAtIndex:z ] ];
			if (n)
				return n;
		}
		else if (![ [ node childAtIndex:z ] isParent ] && [ [ node childAtIndex:z ] visible ])
			return [ node childAtIndex:z ];
	}
	return nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldCollapseItem:(id)item
{
	BOOL prev = [ (IFNode*)item expanded ];
	[ (IFNode*)item setExpanded:NO ];
	if (![ outlineView allowsEmptySelection ])
	{
		IFNode* first = [ self firstLeaf:rootNode ];
		if (!first)
		{
			[ item setExpanded:prev ];
			return NO;
		}
		IFNode* parent = item;
		BOOL should = FALSE;
		while ((parent = [ parent parentItem ]) && !should)
		{
			for (int z = 0; z < [ [ parent children ] count ]; z++)
			{
				if ((IFNode*)[ parent children ][z] == (IFNode*)[ outlineView itemAtRow:[ outlineView selectedRow ] ])
				{
					should = TRUE;
					break;
				}
			}
		}
		
		if (should)
			[ self selectNode:first ];
	}
	
	if ([ (IFNode*)item target ] && [ [ (IFNode*)item target ] respondsToSelector:[ (IFNode*)item action ] ] && !reloading)
		((void (*)(id, SEL, id))[ [ (IFNode*)item target ] methodForSelector:[ (IFNode*)item action ] ])([ (IFNode*)item target ], [ (IFNode*)item action ], item);
	
	return YES;
}

- (void) expand: (IFNode*)node
{
	for (int z = 0; z < [ [ node children ] count ]; z++)
	{
		if ([ [ node children ][z] expanded ] && [ [ node children ][z] visible ])
		{
			[ self expandItem:[ node children ][z] ];
			[ self expand:[ node children ][z] ];
		}
		else if (![ [ node children ][z] expanded ] && [ [ node children ][z] visible ])
		{
			[ self collapseItem:[ node children ][z] ];
			[ self expand:[ node children ][z] ];
		}
	}
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	return !editing;
}

- (void) reloadData
{
	if (deleteEmptyTitles)
	{
		NSArray* all = [ self allNodes ];
		for (int z = 0; z < [ all count ]; z++)
		{
			if ([ [ all[z] title ] length ] == 0 && [ self editedRow ] != [ self rowForItem:all[z] ])
			{
				[ [ (IFNode*)all[z] parentItem ] removeChild:all[z] ];
				//[ self reloadData ];
			}
		}
	}
	reloading = TRUE;
	[ super reloadData ];
	reloading = FALSE;
	[ self expand:rootNode ];
}

@end
