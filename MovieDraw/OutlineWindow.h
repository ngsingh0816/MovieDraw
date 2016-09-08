//
//  OutlineWindow.h
//  MovieDraw
//
//  Created by Neil on 7/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IFNode : NSObject {
	NSString *title;
	NSMutableArray *children;
	BOOL isParent;
	NSDictionary* dictionary;
	BOOL isVisible;
	BOOL isExpanded;
	IFNode* parent;
	id target;
	SEL action;
}

// Initialization methods
- (instancetype)initLeafWithTitle:(NSString *)theTitle;
- (instancetype)initParentWithTitle:(NSString *)theTitle children:(NSMutableArray *)theChildren;

// Child access methods
- (void)addChild:(IFNode *)theChild;
- (void)insertChild:(IFNode *)theChild atIndex:(NSUInteger)theIndex;
- (void)removeChild:(IFNode *)theChild;
- (void) removeChildren;
@property (readonly) NSInteger numberOfChildren;
- (IFNode *)childAtIndex:(NSUInteger)theIndex;
- (IFNode*) childWithTitle: (NSString*) string;
@property (readonly) BOOL containsLeaf;

@property (copy) NSString *title;
- (void) setChildren: (NSArray*) childs;
- (NSMutableArray*) children;
@property  BOOL isParent;
- (void) setDictionary: (NSDictionary*) dict;
- (NSDictionary*) dictionary;
@property  BOOL visible;
@property  BOOL expanded;
@property (strong) IFNode *parentItem;
@property (readonly, copy) NSString *parentsPath;
@property (assign) id target;
@property  SEL action;

@end

@interface OutlineWindow : NSOutlineView<NSOutlineViewDataSource> {
    IFNode *rootNode;
	id target;
	SEL selectAction;
	SEL editAction;
	SEL rightClickAction;
	BOOL sameSel;
	BOOL showGroups;
	BOOL selectParents;
	BOOL doubleClickEdit;
	BOOL deleteEmptyTitles;
	BOOL reloading;
	BOOL editing;
}

@property (readonly, strong) IFNode *rootNode;
- (void) removeAllItems;
- (void) removeNodeWithTitle: (NSString*)title;
@property (readonly, strong) IFNode *selectedNode;
- (void) selectNode: (IFNode*)node;
@property (assign) id target;
@property  SEL selectAction;
@property  SEL editAction;
@property  SEL rightClickAction;
- (IFNode*) firstLeaf: (IFNode*) node;
@property  BOOL sameSelection;
@property (readonly, copy) NSArray *allLeafs;
- (NSArray*) allLeafsOfParent:(IFNode*)node;
@property (readonly, copy) NSArray *allNodes;
@property (readonly) BOOL showGroups;
- (void) setShowsGroups:(BOOL)groups;
@property  BOOL selectParents;
@property  BOOL doubleClickInsteadOfEdit;
- (void) SetDeleteEmptyTitles:(BOOL)del;
@property (readonly) BOOL deleteEmptyTitles;
@property (getter=isEditing) BOOL editing;

@end
