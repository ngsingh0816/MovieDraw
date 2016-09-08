//
//  Controller.m
//  MovieDraw
//
//  Created by MILAP on 3/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Controller.h"
#import "MDObjectTools.h"
#import "ShapeInterpreter.h"
#import "MDCompiler.h"
#import "MDLightRenderer.h"
#import "MDFileManager.h"

// Number of open recent items to show
#define OPEN_RECENT	5

#pragma mark Gloabals
NSString* workingDirectory = nil;						// Current working directory
NSSize projectRes = NSMakeSize(640, 480);				// Current Project Dimensions
NSString* projectScene = nil;							// Current First Scene
unsigned int projectAntialias = 1;						// Current Antialias
unsigned int projectFPS = 60;							// Current Desired FPS
NSString* projectIcon = nil;							// Project Icon
unsigned int projectCommand = 0;						// Project BOOLs
NSMutableDictionary* searchPaths = nil;					// LLVM Search Paths
MDTool currentTool = MD_SELECTION_TOOL;					// Current Tool (Menu)
MDMode currentMode = MD_OBJECT_MODE;					// Current Mode (Menu)
MDObjectTool currentObjectTool = MD_OBJECT_NO;			// Current Object Tool (Menu)
NSMutableArray* objects;								// Objects for the project
NSMutableIndexSet* alphaObjects;						// List of objects that have alpha
NSMutableArray* instances;								// Instances for the project
NSMutableArray* otherObjects;							// Cameras, Lights for the project
NSMutableDictionary* sceneProps;						// Scene Properties like skybox
unsigned long commandFlag = 0;							// BOOLs 'n stuff
unsigned long conditionsFlag = 0;						// More BOOLs
MDSelection* selected = nil;							// Current Object
unsigned long currentCamera = -1;						// Current Camera
std::vector<MDObject*> copyData;						// Copy Data
NSMutableArray* currentObject;							// Current Object for creating shapes
NSString* currentShapePath;								// Shape Path
NSUndoManager* undoManager;								// Undo Manager
NSMenuItem* undoItem;									// Undo Menu Item
NSMenuItem* redoItem;									// Redo Menu Item
NSString* currentOpenFile;								// Editor Open File
NSString* currentScene;									// Current Scene Open
std::vector<std::vector<unsigned long>> breakpoints;	// Breakpoints
std::vector<NSString*> breakpointFiles;					// Filenames for reakpoint groups
BOOL appRunning = FALSE;								// Build is running
BOOL deleteAll = FALSE;									// Delete all breakpoints
BOOL addBreaks = TRUE;									// Add all breakpoints
BOOL documentEdited = FALSE;							// Was the document edited?
NSString* projectCertificate = [ [ NSString alloc ] init ];// The codesigning certificate
NSString* projectAuthor = [ [ NSString alloc ] init ];	// The project's author

#pragma mark -


@implementation Controller

#pragma mark Undo / Redo

+ (void) registerUndo
{	
	if ([ undoManager canUndo ])
		[ undoItem setAction:@selector(undo:) ];
	else
		[ undoItem setAction:nil ];
	if ([ undoManager canRedo ])
		[ redoItem setAction:@selector(redo:)];
	else
		[ redoItem setAction:nil ];
	[ undoItem setTitle:[ NSString stringWithFormat:@"Undo %@", [ undoManager undoActionName ] ] ];
	[ redoItem setTitle:[ NSString stringWithFormat:@"Redo %@", [ undoManager redoActionName ] ] ];
	
	// Anything that can be undone means that something was edited
	documentEdited = TRUE;
}

+ (void) setMDObject: (MDObject*)obj atIndex: (NSUInteger)index faceIndex:(NSUInteger)fInd edgeIndex:(NSUInteger)eInd pointIndex:(NSUInteger)pInd selectionIndex:(NSUInteger)selInd
{	
	if (index >= [ objects count ])
		return;
	
	[ [ undoManager prepareWithInvocationTarget:self ] setMDObject:objects[index] atIndex:index faceIndex:fInd edgeIndex:eInd pointIndex:pInd selectionIndex:selInd ];
	[ Controller registerUndo ];
	if (fInd == NSNotFound)
		[ selected replaceObjectAtIndex:selInd withObject:obj ];
	else if (eInd == NSNotFound && pInd == NSNotFound)
		[ selected replaceObjectAtIndex:selInd withObject:obj ];
	else if (pInd != NSNotFound)
		[ selected replaceObjectAtIndex:selInd withObject:obj withVertex:[ obj pointAtIndex:pInd ] ];
	objects[index] = obj;
	
	[ GLView calculateAlphaObjects ];
	
	commandFlag |= UPDATE_INFO;
	commandFlag |= CLEAR_LENGTHS;
}

+ (void) setMDInstance:(MDInstance*)obj atIndex: (NSUInteger)index
{
	if (index >= [ instances count ])
		return;
	
	[ obj setName:[ instances[index] name ] ];
	[ [ undoManager prepareWithInvocationTarget:self ] setMDInstance:instances[index] atIndex:index ];
	[ Controller registerUndo ];
	
	for (unsigned long z = 0; z < [ objects count ]; z++)
	{
		if ([ objects[z] instance ] == instances[index])
			[ objects[z] setInstance:obj ];
	}
	[ obj setupVBO ];
	instances[index] = obj;
	
	[ GLView calculateAlphaObjects ];
	
	commandFlag |= UPDATE_INFO;
}

+ (void) setObjects: (NSArray*)array selected: (MDSelection*)index andInstances:(NSMutableArray*)insts
{
	MDSelection* sel = [ [ MDSelection alloc ] initWithSelection:selected ];
	[ [ undoManager prepareWithInvocationTarget:self ] setObjects:[ NSArray arrayWithArray:objects ] selected:sel andInstances:[ NSMutableArray arrayWithArray:instances ] ];
	[ Controller registerUndo ];
	[ objects setArray:array ];
	for (unsigned long z = 0; z < [ objects count ]; z++)
	{
		if (![ objects[z] instance ])
		{
			[ objects removeObjectAtIndex:z ];
			z--;
			continue;
		}
	}
	selected = [ [ MDSelection alloc ] initWithSelection:index ];
	
	[ instances setArray:insts ];
	/*// Remove instances that have nothing
	for (unsigned long z = 0; z < [ instances count ]; z++)
	{
		BOOL found = FALSE;
		for (unsigned long y = 0; y < [ objects count ]; y++)
		{
			if ([ [ objects objectAtIndex:y ] instance ] == [ instances objectAtIndex:z ])
			{
				found = TRUE;
				break;
			}
		}
		if (!found)
		{
			[ instances removeObjectAtIndex:z ];
			z--;
		}
	}*/
	
	[ GLView calculateAlphaObjects ];
	
	commandFlag |= UPDATE_LIBRARY;
	commandFlag |= UPDATE_INFO;
	commandFlag |= CLEAR_LENGTHS;
}

+ (void) setOtherObject: (MDCamera*)obj atIndex:(NSUInteger)index
{
	id type = nil;
	if ([ otherObjects[index] isKindOfClass:[ MDCamera class ] ])
		type = [ MDCamera cameraWithMDCamera:otherObjects[index] ];
	else if ([ otherObjects[index] isKindOfClass:[ MDLight class ] ])
		type = [ [ MDLight alloc ] initWithMDLight:otherObjects[index] ];
	else if ([ otherObjects[index] isKindOfClass:[ MDParticleEngine class ] ])
		type = [[ MDParticleEngine alloc ] initWithMDParticleEngine:otherObjects[index] ];
	[ [ undoManager prepareWithInvocationTarget:self ] setOtherObject:type atIndex:index ];
	[ Controller registerUndo ];
	otherObjects[index] = obj;
	
	commandFlag |= UPDATE_OTHER_INFO;
}

+ (void) setTranslationPoint:(MDVector3)point
{
	[ [ undoManager prepareWithInvocationTarget:self ] setTranslationPoint:translationPoint ];
	[ Controller registerUndo ];
	translationPoint = point;
	
	commandFlag |= UPDATE_SCENE_INFO;
}

- (IBAction) undo: (id) sender
{
	if ([ editorWindow isVisible ])
	{
		[ [ editorView undoManager ] undo ];
		return;
	}
	
	[ undoManager undo ];
	if ([ undoManager canUndo ])
		[ undoItem setAction:@selector(undo:) ];
	else
		[ undoItem setAction:nil ];
	if ([ undoManager canRedo ])
		[ redoItem setAction:@selector(redo:)];
	else
		[ redoItem setAction:nil ];
	[ undoItem setTitle:[ NSString stringWithFormat:@"Undo %@", [ undoManager undoActionName ] ] ];
	[ redoItem setTitle:[ NSString stringWithFormat:@"Redo %@", [ undoManager redoActionName ] ] ];
}

- (IBAction) redo: (id) sender
{
	if ([ editorWindow isVisible ])
	{
		[ [ editorView undoManager ] redo ];
		return;
	}
	
	[ undoManager redo ];
	if ([ undoManager canUndo ])
		[ undoItem setAction:@selector(undo:) ];
	else
		[ undoItem setAction:nil ];
	if ([ undoManager canRedo ])
		[ redoItem setAction:@selector(redo:)];
	else
		[ redoItem setAction:nil ];
	[ undoItem setTitle:[ NSString stringWithFormat:@"Undo %@", [ undoManager undoActionName ] ] ];
	[ redoItem setTitle:[ NSString stringWithFormat:@"Redo %@", [ undoManager redoActionName ] ] ];
}

#pragma mark Initialization

BOOL loaded = FALSE;
- (void) applicationDidFinishLaunching: (NSNotification*)notification
{
	if (loaded)
		return;
	loaded = TRUE;
	
	// Create sandbox if it doesn't exist
	/*NSString* path = [ NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0 ];
	BOOL dir = FALSE;
	BOOL exists = [ [ NSFileManager defaultManager ] fileExistsAtPath:path isDirectory:&dir ];
	if (!exists || !dir)
		[ [ NSFileManager defaultManager ] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil ];*/
	
	// Setup the tab switchers
	[ inspectorSwitcher setNumberOfTabs:3 ];
	[ inspectorSwitcher setTabView:inspectorTabView ];
	
	// Exit Font Window If Open
	[ [ [ NSFontManager sharedFontManager ] fontPanel:NO ] orderOut:self ];
	
	// Preferences get initialized here
	searchPaths = [ [ NSMutableDictionary alloc ] init ];
	// Read preferences
	[ self readPreferences ];
	
	// Read recently opened
	[ self readRecentlyOpened ];
	
	// Set undo / redo
	undoItem = _undoItem;
	redoItem = _redoItem;
	[ undoItem setAction:nil ];
	[ redoItem setAction:nil ];
	
	// Window Delegates
	[ inspectorPanel setDelegate:(id)self ];
	[ infoWindow setDelegate:(id)self ];
	[ createText setDelegate:(id)self ];
	[ consoleWindow setDelegate:(id)self ];
	[ editorWindow setDelegate:(id)self ];
	[ projectWindow setDelegate:(id)self ];
	[ glWindow setDelegate:(id)self ];
	
	// Application Delegate
	[ NSApp setDelegate:(id)self ];
	
	NSSize screenSize = [ [ NSScreen mainScreen ] frame ].size;
	// Center and show the intro window
	if (showIntroWindow)
	{
		// Unless autosaved
		if ([ introWindow frame ].origin.x == 0 && [ introWindow frame ].origin.y == 0)
		{
			NSSize windowFrame = [ introWindow frame ].size;
			[ introWindow setFrameOrigin:NSMakePoint((screenSize.width - windowFrame.width) / 2, (screenSize.height - windowFrame.height) / 2) ];
		}
		[ self showIntroWindow:self ];
	}
	
	// Add current resolution to the resolution box for new project
	[ projectResolution addItemWithObjectValue:[ NSString stringWithFormat:@"%i x %i", (int)screenSize.width, (int)screenSize.height ] ];
	
	// Set the menu to the correct way
	[ saveMenu setAction:nil ];
	[ toolMenu setHidden:YES ];
	[ importMenu setEnabled:NO ];
	[ exportMenu setEnabled:NO ];
	[ sceneMenu setHidden:YES ];
	[ objectMenu setHidden:YES ];
	[ createMenu setHidden:YES ];
	[ copyMenu setAction:nil ];
	[ duplicateMenu setAction:nil ];
	[ cutMenu setAction:nil ];
	[ deleteMenu setAction:nil ];
	[ objectCombine setAction:nil ];
	[ objectTrans setAction:nil ];
	[ objectNormalize setEnabled:NO ];
	[ objectAddTexture setAction:nil ];
	[ objectReverseWinding setAction:nil ];
	[ objectSetHeight setAction:nil ];
	[ objectExportHeight setAction:nil ];
	[ objectProperties setAction:nil ];
	[ objectPhysicsProperties setAction:nil ];
	[ objectAnimations setAction:nil ];
	[ objectHidden setAction:nil ];
	[ objectHidden setState:NSOffState ];
	[ pasteMenu setAction:nil ];
	[ pastePlaceMenu setAction:nil ];
	[ projectMenu setHidden:YES ];
	[ viewInspectorPanel setAction:nil ];
	[ viewInfoPanel setAction:nil ];
	[ viewConsolePanel setAction:nil ];
	[ viewProjectPanel setAction:nil ];
	
	[ self loadShapes:[ NSString stringWithFormat:@"%@/Shapes/", [ [ NSBundle mainBundle ] resourcePath ] ] menu:[ createMenu submenu ] node:[ outlineShape rootNode ] ];
	
	NSArray* customPaths = [ [ NSFileManager defaultManager ] contentsOfDirectoryAtPath:[ NSString stringWithFormat:@"%@/Shapes/Custom", [ [ NSBundle mainBundle ] resourcePath ] ] error:nil ];
	[ [ [ [ createMenu submenu ] itemWithTitle:@"Custom" ] submenu ] addItemWithTitle:@"Create Shape From Code" action:@selector(createShapeCode:) keyEquivalent:@"" ];
	for (unsigned long z = 0; z < [ customPaths count ]; z++)
	{
		NSString* path = customPaths[z];
		if (![ path hasSuffix:@".tshape" ])
			continue;
		if ([ [ [ [ createMenu submenu ] itemWithTitle:@"Custom" ] submenu ] numberOfItems ] == 1)
			[ [ [ [ createMenu submenu ] itemWithTitle:@"Custom" ] submenu ] addItem:[ NSMenuItem separatorItem ] ];
		NSString* title = [ [ NSString alloc ] initWithString:[ [ path substringToIndex:[ path length ] - 7 ] lastPathComponent ] ];
		NSMenuItem* item = [ [ NSMenuItem alloc ] initWithTitle:title action:@selector(customShape:) keyEquivalent:@"" ];
		SettingView* view = [ [ SettingView alloc ] initWithFrame:NSMakeRect(0, 0, 150, 19) ];
		[ view setText:title ];
		[ view setTarget:self ];
		[ view setAction:@selector(customShapeSettings:) ];
		[ item setView:view ];
		[ [ [ [ createMenu submenu ] itemWithTitle:@"Custom" ] submenu ] addItem:item ];
	}
	
	[ [ createMenu submenu ] addItem:[ NSMenuItem separatorItem ] ];
	NSMenuItem* lightsItem = [ [ NSMenuItem alloc ] initWithTitle:@"Lights" action:nil keyEquivalent:@"" ];
	NSMenu* lightsMenu = [ [ NSMenu alloc ] init ];
	[ lightsMenu addItemWithTitle:@"Directional Light" action:@selector(createDirectionalLight:) keyEquivalent:@"" ];
	[ lightsMenu addItemWithTitle:@"Point Light" action:@selector(createPointLight:) keyEquivalent:@"" ];
	[ lightsMenu addItemWithTitle:@"Spot Light" action:@selector(createSpotLight:) keyEquivalent:@"" ];
	[ lightsItem setSubmenu:lightsMenu ];
	[ [ createMenu submenu ] addItem:lightsItem ];
	[ [ createMenu submenu ] addItemWithTitle:@"Camera" action:@selector(createCamera:) keyEquivalent:@"" ];
	[ [ createMenu submenu ] addItemWithTitle:@"Sound" action:@selector(createSound:) keyEquivalent:@"" ];
	[ [ createMenu submenu ] addItemWithTitle:@"Particle Engine" action:@selector(createParticleEngine:) keyEquivalent:@"" ];
	[ [ createMenu submenu ] addItemWithTitle:@"Curve" action:@selector(createCurve:) keyEquivalent:@"" ];
	
	//[ [ createMenu submenu ] addItem:[ NSMenuItem separatorItem ] ];
	//[ [ createMenu submenu ] addItemWithTitle:@"Text" action:@selector(createText:) keyEquivalent:@"" ];
	
	[ [ createMenu submenu ] addItem:[ NSMenuItem separatorItem ] ];
	[ [ createMenu submenu ] addItemWithTitle:@"Settings" action:@selector(settings:) keyEquivalent:@"" ];
	[ outlineShape reloadData ];
	[ outlineShape expandItem:nil expandChildren:YES ];
	[ outlineShape selectNode:[ outlineShape firstLeaf:[ outlineShape rootNode ] ] ];
	[ outlineShape setTarget:self ];
	[ outlineShape setSelectAction:@selector(shapeChosen:) ];
	
	// Set target
	[ glWindow setTarget:self ];
	[ glWindow setAction:@selector(updateGLView) ];
	[ glWindow setAction2:@selector(updateBeforeGLView) ];
	
	[ self setUpInfoPanel ];
	[ self setUpOtherPanel ];
	[ self setUpFilePanel ];
	[ self setupLibraryPanel ];
	[ self setupCodeHelp ];
	
	// Preference Search Table
	[ [ preferenceSearchTable tableColumns ][0] setIdentifier:@"Path" ];
	
	// Texture Table
	[ textureTable setTarget:self ];
	[ textureTable setAction:@selector(textureSelected:) ];
	[ textureTable setDoubleAction:@selector(editTexture:) ];
	[ [ textureTable tableColumns ][0] setIdentifier:@"Name" ];
	[ [ textureTable tableColumns ][1] setIdentifier:@"Type" ];
	
	// Texture Resources Table
	[ textureResources setTarget:self ];
	[ textureResources setDoubleAction:@selector(selectTextureImage:) ];
	[ textureResources setRightAction:@selector(textureResourcesRight) ];
	[ [ textureResources tableColumns ][0] setIdentifier:@"Name" ];
	[ [ textureResources tableColumns ][1] setIdentifier:@"Preview" ];
	
	// Skybox Table
	[ [ skyboxTable tableColumns ][0] setIdentifier:@"Name" ];
	
	// Property Table
	[ propertyTable setTarget:self ];
	[ propertyTable setEditTarget:self ];
	[ propertyTable setEditAction:@selector(propertyEdited:) ];
	[ [ propertyTable tableColumns ][0] setIdentifier:@"Name" ];
	[ [ propertyTable tableColumns ][1] setIdentifier:@"Value" ];
	
	// Physics Table
	[ physicsTable setTarget:self ];
	[ physicsTable setEditTarget:self ];
	[ physicsTable setEditAction:@selector(physicsTableEdited:) ];
	[ [ physicsTable tableColumns ][0] setIdentifier:@"Property" ];
	[ [ physicsTable tableColumns ][1] setIdentifier:@"Value" ];
	
	// Variable Table
	[ variableView setEditTarget:self ];
	[ variableView setEditAction:@selector(variableTableEdited:) ];
	[ [ variableView tableColumns ][0] setIdentifier:@"Type" ];
	[ [ variableView tableColumns ][1] setIdentifier:@"Name" ];
	[ [ variableView tableColumns ][2] setIdentifier:@"Value" ];

	// Scene Table
	[ sceneTable setTarget:self ];
	[ sceneTable setDoubleAction:@selector(sceneOpened:) ];
	[ sceneTable setRightAction:@selector(sceneShowMenu:) ];
	[ sceneTable setEditTarget:self ];
	[ sceneTable setEditAction:@selector(sceneEdited:) ];
	[ [ sceneTable tableColumns ][0] setIdentifier:@"Loaded" ];
	[ [ sceneTable tableColumns ][1] setIdentifier:@"Name" ];
	[ [ sceneTable tableColumns ][2] setIdentifier:@"Image" ];
	
	// Animation Table
	[ animationTable setTarget:self ];
	[ animationTable setEditTarget:self ];
	[ animationTable setEditAction:@selector(animationEdited:) ];
	[ animationTable setDoubleAction:@selector(animationDoubleClicked:) ];
	[ animationTable setRightAction:@selector(animationRightClicked:) ];
	[ [ animationTable tableColumns ][0] setIdentifier:@"Name" ];
	
	SettingDraw* view = [ [ SettingDraw alloc ] initWithFrame:[ [ shapeScrollView contentView ] frame ] ];
	[ shapeScrollView setContentView:view ];
	
	undoManager = [ [ NSUndoManager alloc ] init ];
	
	// Check for Cocoa/Cocoa.h
	if (![ [ NSFileManager defaultManager ] fileExistsAtPath:@"/System/Library/Frameworks/Cocoa.framework/Versions/A/Headers/Cocoa.h" ])
	{
		// Command line tools are not installed
		unsigned long z = NSRunAlertPanel(@"Error", @"It appears that you do not have the command line tools that are necessary for this compiling your applications. You can download them, but you need an Apple Developer account (which is free to make). If you choose not to download and install it, you will still be able to use this application, but you cannot compile your apps. Do you want to download them now?", @"Yes", @"No", nil);
		if (z == NSAlertDefaultReturn)
			[ [ NSWorkspace sharedWorkspace ] openURL:[ NSURL URLWithString: @"https://developer.apple.com/downloads/index.action?name=Command%20Line%20Tools" ] ];
	}
}

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename
{
	if ([ filename hasSuffix:@".mdp" ])
	{
		if ([ glWindow isVisible ] && documentEdited)
		{
			unsigned long z = NSRunAlertPanel(@"Confirm", @"If you open a new project, you will lose unsaved data. Do you want to save?", @"Cancel", @"Save", @"Dont Save");
			if (z == NSAlertDefaultReturn)
				return YES;
			else if (z == NSAlertAlternateReturn)
				[ self save:self ];
		}
		
		BOOL prevShow = showIntroWindow;
		showIntroWindow = FALSE;
		[ self applicationDidFinishLaunching:nil ];
		showIntroWindow = prevShow;
		
		workingDirectory = [ [ NSString alloc ] initWithString:[ [ filename stringByDeletingLastPathComponent ] stringByAppendingString:@"/" ] ];
		[ self readProject ];
		return YES;
	}
	
	return NO;
}

#pragma mark Intro Window

- (IBAction) showIntroWindow:(id)sender
{
	// Read File
	FILE* file = [ self recentlyOpenedFile ];
	if (!file)
		return;
	
	// Read how many recents there are
	unsigned char number = 0;
	fread(&number, 1, 1, file);
	NSMenu* submenu = [ [ NSMenu alloc ] initWithTitle:@"" ];
	for (int z = 0; z < number; z++)
	{
		unsigned int length = 0;
		fread(&length, 1, sizeof(unsigned int), file);
		char* str = (char*)malloc(length + 1);
		fread(str, length, 1, file);
		str[length] = 0;
		NSMenuItem* item = [ [ NSMenuItem alloc ] initWithTitle:[ [ NSString stringWithFormat:@"%s", str ] lastPathComponent ] action:@selector(selectRecentIntro:) keyEquivalent:@"" ];
		[ submenu insertItem:item atIndex:0 ];
		free(str);
		str = NULL;
	}
	[ openRecentPopup setMenu:submenu ];
	fclose(file);
	
	if (number)
		[ self selectRecentIntro:[ [ openRecentPopup menu ] itemAtIndex:0 ] ];
	[ openRecentButton setEnabled:(number != 0) ];
	[ introWindow makeKeyAndOrderFront:self ];
}

- (IBAction) selectRecentIntro:(id)sender
{
	int z = 0;
	for (z = 0; z < [ [ sender menu ] numberOfItems ]; z++)
	{
		if (sender == [ [ sender menu ] itemAtIndex:z ])
			break;
	}
	if (z >= OPEN_RECENT)
		return;
	FILE* file = [ self recentlyOpenedFile ];
	if (!file)
		return;
	unsigned char num = 0;
	fread(&num, 1, 1, file);
	if (num <= z)
	{
		fclose(file);
		return;
	}
	
	NSString* path = nil;
	for (int q = 0; q <= num - z - 1; q++)
	{
		unsigned int length = 0;
		fread(&length, 1, sizeof(unsigned int), file);
		char* temp = (char*)malloc(length + 1);
		fread(temp, length, 1, file);
		temp[length] = 0;
		if (q == num - z - 1)
		{
			NSString* name = [ [ NSString alloc ] initWithFormat:@"%s", temp ];
			if (![ [ NSFileManager defaultManager ] fileExistsAtPath:name ])
			{
				fclose(file);
				free(temp);
				temp = NULL;
				return;
			}
			
			path = [ [ NSString alloc ] initWithString:name ];
		}
		free(temp);
		temp = NULL;
	}
	fclose(file);
	
	if (!path)
		return;
	
	file = fopen([ path UTF8String ], "rb");
	// Project Data
	unsigned char sourceEdited = 0;
	fread(&sourceEdited, sizeof(unsigned char), 1, file);
	// Resolution
	int width = 0, height = 0;
	fread(&width, sizeof(int), 1, file);
	fread(&height, sizeof(int), 1, file);
	unsigned int length = 0;
	fread(&length, sizeof(unsigned int), 1, file);
	char* crs = (char*)malloc(length + 1);
	fread(crs, length, 1, file);
	free(crs);
	fread(&length, sizeof(unsigned int), 1, file);
	crs = (char*)malloc(length + 1);
	fread(crs, length, 1, file);
	free(crs);
	fread(&projectAntialias, sizeof(unsigned int), 1, file);
	fread(&projectFPS, sizeof(unsigned int), 1, file);
	fread(&length, sizeof(unsigned int), 1, file);
	crs = (char*)malloc(length + 1);
	fread(crs, length, 1, file);
	free(crs);
	fread(&projectCommand, sizeof(unsigned int), 1, file);
	unsigned int numOfScenes = 0;
	fread(&numOfScenes, sizeof(unsigned int), 1, file);
	if (numOfScenes != 0)
	{
		unsigned long length = 0;
		fread(&length, sizeof(unsigned long), 1, file);
		crs = (char*)malloc(length + 1);
		fread(crs, length, 1, file);
		free(crs);
		
		// Scene Properties
		unsigned long skyLen = 0;
		fread(&skyLen, sizeof(unsigned long), 1, file);
		crs = (char*)malloc(skyLen + 1);
		fread(crs, 1, skyLen, file);
		float skyDist = 0;
		fread(&skyDist, sizeof(float), 1, file);
		float skyRed = 0, skyGreen = 0, skyBlue = 0, skyAlpha = 0;
		fread(&skyRed, sizeof(float), 1, file);
		fread(&skyGreen, sizeof(float), 1, file);
		fread(&skyBlue, sizeof(float), 1, file);
		fread(&skyAlpha, sizeof(float), 1, file);
		float skyCorrection = 0;
		fread(&skyCorrection, sizeof(float), 1, file);
		unsigned char skyVisible = 0;
		fread(&skyVisible, 1, 1, file);
		free(crs);
		
		// Scene Image
		unsigned long picLength = 0;
		fread(&picLength, sizeof(unsigned long), 1, file);
		if (picLength != 0)
		{
			char* data = (char*)malloc(picLength);
			fread(data, picLength, 1, file);
			NSImage* image = [ [ NSImage alloc ] initWithData:[ NSData dataWithBytes:data length:picLength ] ];
			free(data);
			if (image)
				[ imageView setImage:image ];
		}
	}
}

- (IBAction) openRecentIntro:(id)sender
{
	unsigned long z = [ [ openRecentPopup menu ] indexOfItem:[ openRecentPopup selectedItem ] ];
	if (z >= OPEN_RECENT)
		return;
	FILE* file = [ self recentlyOpenedFile ];
	if (!file)
		return;
	unsigned char num = 0;
	fread(&num, 1, 1, file);
	if (num <= z)
	{
		fclose(file);
		return;
	}
	for (int q = 0; q <= num - z - 1; q++)
	{
		unsigned int length = 0;
		fread(&length, 1, sizeof(unsigned int), file);
		char* temp = (char*)malloc(length + 1);
		fread(temp, length, 1, file);
		temp[length] = 0;
		if (q == num - z - 1)
		{
			NSString* name = [ [ NSString alloc ] initWithFormat:@"%s", temp ];
			if (![ [ NSFileManager defaultManager ] fileExistsAtPath:name ])
			{
				NSRunAlertPanel(@"Error", @"%@ does not exist", @"Ok", nil, nil, name);
				fclose(file);
				free(temp);
				temp = NULL;
				return;
			}
			
			if ([ glWindow isVisible ] && documentEdited)
			{
				unsigned long z = NSRunAlertPanel(@"Confirm", @"If you open a new project, you will lose unsaved data. Do you want to save?", @"Cancel", @"Save", @"Dont Save");
				if (z == NSAlertDefaultReturn)
					return;
				else if (z == NSAlertAlternateReturn)
					[ self save:self ];
			}
			
			workingDirectory = [ [ NSString alloc ] initWithString:[ name substringToIndex:[ name length ] - [ [ name lastPathComponent ] length ] ] ];
			[ self readProject ];
		}
		free(temp);
		temp = NULL;
	}
	fclose(file);
}

- (IBAction) viewHeaderIntro:(id)sender
{
	NSString* file = [ [ openHeaderPopup selectedItem ] title ];
	[ codeHeadersView setEditable:NO ];
	NSString* filename = [ NSString stringWithFormat:@"%@/Headers/MovieDraw/%@", [ [ NSBundle mainBundle ] resourcePath ], file ];
	[ codeHeadersView setFileName:filename ];
	[ codeHeadersView setText:[ NSString stringWithContentsOfFile:filename encoding:NSASCIIStringEncoding error:nil ] ];
	[ codeHeadersWindow setTitle:[ NSString stringWithFormat:@"Code Headers - %@", file ] ];
	[ codeHeadersWindow makeKeyAndOrderFront:self ];
}

#pragma mark Read Menu

- (void) loadShapes: (NSString*)path menu:(NSMenu*)superMenu node:(IFNode*)root;
{
	NSArray* paths = [ [ NSFileManager defaultManager ] contentsOfDirectoryAtPath:path error:nil ];
	for (int z = 0; z < [ paths count ]; z++)
	{
		BOOL folder = FALSE;
		[ [ NSFileManager defaultManager ] fileExistsAtPath:[ NSString stringWithFormat:@"%@/%@", path, paths[z] ] isDirectory:&folder ];
		if (folder && ![ paths[z] isEqualToString:@"Custom" ])
		{
			[ superMenu addItemWithTitle:paths[z] action:nil keyEquivalent:@"" ];
			NSMenu* menu = [ [ NSMenu alloc ] init ];
			[ self loadShapes:[ NSString stringWithFormat:@"%@/%@", path, paths[z] ] menu:menu node:nil ];
			[ [ superMenu itemAtIndex:[ superMenu numberOfItems ] - 1 ] setSubmenu:menu ];
		}
		else if ([ [ paths[z] pathExtension ] isEqualToString:@"shape" ])
		{
			NSString* title = [ [ NSString alloc ] initWithString:[ paths[z] substringToIndex:[ paths[z] length ] - [ [ paths[z] pathExtension ] length ] - 1 ] ];
			IFNode* item = [ [ IFNode alloc ] initLeafWithTitle:title ];
			[ root addChild:item ];
		}
	}
	for (int z = 0; z < [ paths count ]; z++)
	{
		BOOL folder = FALSE;
		[ [ NSFileManager defaultManager ] fileExistsAtPath:[ NSString stringWithFormat:@"%@/%@", path, paths[z] ] isDirectory:&folder ];
		if (folder && ![ paths[z] isEqualToString:@"Custom" ])
		{
			IFNode* item = [ [ IFNode alloc ] initParentWithTitle:paths[z] children:nil ];
			[ self loadShapes:[ NSString stringWithFormat:@"%@/%@", path, paths[z] ] menu:nil node:item ];
			[ root addChild:item ];
		}
		else if ([ [ paths[z] pathExtension ] isEqualToString:@"shape" ])
		{
			NSString* title = [ [ NSString alloc ] initWithString:[ paths[z] substringToIndex:[ paths[z] length ] - [ [ paths[z] pathExtension ] length ] - 1 ] ];
			NSMenuItem* item = [ [ NSMenuItem alloc ] initWithTitle:title action:@selector(shape:) keyEquivalent:@"" ];
			SettingView* view = [ [ SettingView alloc ] initWithFrame:NSMakeRect(0, 0, 150, 19) ];
			[ view setText:title ];
			[ view setTarget:self ];
			[ view setAction:@selector(shapeSettings:) ];
			[ item setView:view ];
			[ superMenu addItem:item ];
		}
	}
}

#pragma mark Project Creation

- (IBAction) newProject: (id) sender
{
	// Set initial values;
	[ projectName setStringValue:@"Untitled" ];
	[ projectResolution setStringValue:@"640 x 480" ];
	[ newProjectWindow makeKeyAndOrderFront:self ];
}

- (IBAction) cancelNewProject: (id) sender
{
	[ newProjectWindow orderOut:self ];
}

- (IBAction) finishNewProject: (id) sender
{
	// Create a save panel
	NSOpenPanel* panel = [ NSOpenPanel openPanel ];
	[ panel setPrompt:@"Create" ];
	[ panel setCanChooseFiles:NO ];
	[ panel setCanChooseDirectories:YES ];
	[ panel beginSheetModalForWindow:newProjectWindow completionHandler:^(NSInteger result)
	{
		if (result == NSFileHandlingPanelCancelButton)
			return;
		
		// If create pressed
		if ([ glWindow isVisible ] && documentEdited)
		{
			unsigned long z = NSRunAlertPanel(@"Confirm", @"If you create a new project, you will lose unsaved data. Do you want to save?", @"Cancel", @"Save", @"Dont Save");
			if (z == NSAlertDefaultReturn)
				return;
			else if (z == NSAlertAlternateReturn)
				[ self save:self ];
		}
				
		// Check if file already exists
		NSString* path = [ [ [ [ panel URL ] absoluteString ] substringFromIndex:7 ] stringByReplacingPercentEscapesUsingEncoding:NSASCIIStringEncoding ];
		BOOL dir = false;
		if ([ [ NSFileManager defaultManager ] fileExistsAtPath:[ NSString stringWithFormat:@"%@%@",
																 path, [ projectName stringValue ] ] isDirectory:&dir ])
		{
			// Warn the user - ask for continue or cancel
			NSAlert* alert = [ NSAlert alertWithMessageText:[ NSString stringWithFormat:@"\"%@\" already exists. Do you want to replace it?", [ projectName stringValue ] ] defaultButton:@"Cancel" alternateButton:@"Replace" otherButton:nil informativeTextWithFormat:@"A file or folder with the same name already exists in the folder %@. Replacing it will overwrite its current contents.", path ];
			[ alert setAlertStyle:NSCriticalAlertStyle ];
			// If they cancel, stop
			if ([ alert runModal ])
				return;
			[ [ NSFileManager defaultManager ] removeItemAtPath:[ NSString stringWithFormat:@"%@%@", path, [ projectName stringValue ] ] error:nil ];
		}
		// Set the working directory
		workingDirectory = [ [ NSString alloc ] initWithFormat:@"%@%@/", path, [ projectName stringValue ] ];
		currentScene = @"Scene 1";
		
		// Deinitialize
		[ objects removeAllObjects ];
		[ instances removeAllObjects ];
		[ otherObjects removeAllObjects ];
		
		NSSize frame;
		NSString* string = [ [ NSString alloc ] initWithString:[ [ projectResolution stringValue ] stringByReplacingOccurrencesOfString:@" " withString:@"" ] ];
		NSRange range = [ string rangeOfString:@"x" ];
		frame.width = [ [ string substringWithRange:NSMakeRange(0, range.location) ] floatValue ];
		frame.height = [ [ string substringWithRange:NSMakeRange(NSMaxRange(range), [ string length ] - NSMaxRange(range)) ] floatValue ];
		projectRes = frame;
		// Create initial files
		[ [ NSFileManager defaultManager ] createDirectoryAtPath:workingDirectory
									 withIntermediateDirectories:NO attributes:nil error:nil ];
		[ [ NSFileManager defaultManager ] createDirectoryAtPath:[ NSString stringWithFormat:@"%@/build", workingDirectory ] withIntermediateDirectories:NO attributes:nil error:nil ];
		[ [ NSFileManager defaultManager ] createDirectoryAtPath:[ NSString stringWithFormat:@"%@/Models", workingDirectory ] withIntermediateDirectories:NO attributes:nil error:nil ];
		[ [ NSFileManager defaultManager ] createDirectoryAtPath:[ NSString stringWithFormat:@"%@/Scenes", workingDirectory ] withIntermediateDirectories:NO attributes:nil error:nil ];
		[ [ NSFileManager defaultManager ] createDirectoryAtPath:[ NSString stringWithFormat:@"%@/%@/Resources", workingDirectory, [ workingDirectory lastPathComponent ] ] withIntermediateDirectories:YES attributes:nil error:nil ];
		// Add correct files to file manager
		[ fileOutline removeAllItems ];
		IFNode* node = [ [ IFNode alloc ] initParentWithTitle:[ workingDirectory lastPathComponent ] children:nil ];
		IFNode* child = [ [ IFNode alloc ] initLeafWithTitle:[ NSString stringWithFormat:@"%@.mm", [ workingDirectory lastPathComponent ] ] ];
		[ node addChild:child ];
		IFNode* node2 = [ [ IFNode alloc ] initParentWithTitle:@"Resources" children:nil ];
		[ node addChild:node2 ];
		[ [ fileOutline rootNode ] addChild:node ];
		[ self save:sender ];
		[ fileOutline reloadData ];
		[ sceneTable removeAllRows ];
		[ sceneTable addRow:@{@"Name": @"Scene 1", @"Image": [ NSImage imageNamed:NSImageNameApplicationIcon ], @"Loaded": @"✓"} ];
		projectScene = @"Scene 1";
		projectAntialias = 1;
		projectFPS = 60;
		projectCommand = MD_PROJECT_DISABLE | MD_PROJECT_SHOW_GRID;
		// Add scene properties
		[ sceneProps addEntriesFromDictionary:[ NSDictionary dictionaryWithObject:[ NSMutableDictionary dictionaryWithObjectsAndKeys:@"", @"Skybox Texture Path", [ NSNumber numberWithUnsignedInt:0 ], @"Skybox Texture", [ NSNumber numberWithFloat:100 ], @"Skybox Distance", [ NSColor colorWithCalibratedRed:1 green:1 blue:1 alpha:1 ], @"Skybox Color", [ NSNumber numberWithFloat:.0015 ], @"Skybox Correction", [ NSNumber numberWithBool:NO ], @"Skybox Visible", nil ] forKey:@"Scene 1" ] ];
		// Add main file
		NSString* data = [ NSString stringWithFormat:@"// %@.mm\n\n#import <MovieDraw/MovieDraw.h>\n\n// Init - this is what's called when the application is started. If NO is returned, the app will exit.\nBOOL init()\n{\n\treturn YES;\n}\n\n// InitGL - this is what's called when the OpenGL view is created. If NO is returned, the app will exit.\nBOOL initGL()\n{\n\treturn YES;\n}\n\n// Draw - this is what's called everytime before drawing 60 times a second.\nvoid draw()\n{\n}\n\n// Key Down - called when a key is down (for typing)\nvoid KeyDown(NSEvent* event)\n{\n}\n\n// Key Up - called when a key is released (for typing)\nvoid KeyUp(NSEvent* event)\n{\n\n}\n\n// Process Keys - called 60 times a second for smooth key calling\nvoid ProcessKeys(NSArray* keys)\n{\n}\n\n// Mouse Down - called when the mouse is down.\nvoid MouseDown(NSEvent* event)\n{\n}\n\n// Mouse Up - called when the mouse is released.\nvoid MouseUp(NSEvent* event)\n{\n}\n\n// Mouse Dragged - called when the mouse is dragged.\nvoid MouseDragged(NSEvent* event)\n{\n}\n\n// Mouse Moved - called when the mouse is moved.\nvoid MouseMoved(NSEvent* event)\n{\n}\n\n// Dealloc - called when the app is exited\nvoid Dealloc()\n{\n}\n\n", [ projectName stringValue ] ];
		[ [ NSFileManager defaultManager ] createFileAtPath:[ workingDirectory stringByAppendingFormat:@"/%@/%@.mm", [ workingDirectory lastPathComponent ], [ projectName stringValue ] ] contents:[ data dataUsingEncoding:NSASCIIStringEncoding ] attributes:nil ];
		// Close the window and open the project
		[ newProjectWindow orderOut:self ];
		[ self addToRecentlyOpened:[ NSString stringWithFormat:@"%@%@.mdp", workingDirectory, [ projectName stringValue ] ] ];
		
		// Add a starting light
		MDLight* light = [ [ MDLight alloc ] init ];
		[ light setPosition:MDVector3Create(0, 5, 0) ];
		[ light setSpotDirection:MDVector3Create(0, 5, 0) ];
		[ light setShow:NO ];
		[ light setDiffuseColor:MDVector4Create(0, 0, 0, 1) ];
		[ light setLightType:MDDirectionalLight ];
		[ light setName:@"Ambient" ];
		if (!otherObjects)
			otherObjects = [ [ NSMutableArray alloc ] init ];
		[ otherObjects addObject:light ];
		
		// Remove selection
		[ selected clear ];
		// Set camera
		translationPoint = MDVector3Create(0, 5, -20);
		lookPoint = MDVector3Create(0, 5, 0);
		MDRotationBox* box = ViewForIdentity(@"Rotation Box");
		[ box setXRotation:0 ]; [ box setYRotation:0 ]; [ box setZRotation:0 ];
		
		// Set to copmile the source
		[ editorView setEdited:YES ];
		
		[ self saveWithPics:NO andModels:YES ];
		[ self readProject ];
		
		// Close
		[ introWindow orderOut:self ];
		[ newProjectWindow orderOut:self ];
	} ];
}

#pragma mark File Menun

- (IBAction) close:(id)sender
{
	if ([ glWindow isVisible ] && documentEdited)
	{
		unsigned long z = NSRunAlertPanel(@"Confirm", @"If you close this project, you will lose all unsaved data.", @"Cancel", @"Save", @"Don't Save");
		if (z == NSAlertDefaultReturn)
			return;
		else if (z == NSAlertAlternateReturn)
			[ self save:self ];
	}
	
	[ [ [ NSApplication sharedApplication ] keyWindow ] performClose:sender ];
}

#pragma mark Open Recent

- (FILE*) recentlyOpenedFile
{
	// Read File
	NSString* path = [ NSString stringWithFormat:@"%@/recent.txt", [ [ NSBundle mainBundle ] resourcePath ] ];
	FILE* file = fopen([ path UTF8String ], "r+");
	if (!file)
	{
		// If file doesn't exist, create one
		file = fopen([ path UTF8String ], "w+");
		if (!file)
		{
			// A file can't be created
			NSRunAlertPanel(@"Error", @"Cannot read from disk.", @"Ok", nil, nil);
			return NULL;
		}
		unsigned char number = 0;
		fwrite(&number, 1, 1, file);
	}
	return file;
}

- (void) readRecentlyOpened
{
	// Read File
	FILE* file = [ self recentlyOpenedFile ];
	if (!file)
		return;
	
	// Read how many recents there are
	unsigned char number = 0;
	fread(&number, 1, 1, file);
	NSMenu* submenu = [ [ NSMenu alloc ] initWithTitle:@"" ];
	for (int z = 0; z < number; z++)
	{
		unsigned int length = 0;
		fread(&length, 1, sizeof(unsigned int), file);
		char* str = (char*)malloc(length + 1);
		fread(str, length, 1, file);
		str[length] = 0;
		NSMenuItem* item = [ [ NSMenuItem alloc ] initWithTitle:[ [ NSString stringWithFormat:@"%s", str ] lastPathComponent ] action:@selector(openRecent:) keyEquivalent:@"" ];
		[ submenu insertItem:item atIndex:0 ];
		free(str);
		str = NULL;
	}
	NSMenuItem* clear = nil;
	if (number > 0)
	{
		[ submenu addItem:[ NSMenuItem separatorItem ] ];
		clear = [ [ NSMenuItem alloc ] initWithTitle:@"Clear Menu" action:@selector(clearMenu:) keyEquivalent:@"" ];
	}
	else
		clear = [ [ NSMenuItem alloc ] initWithTitle:@"Clear Menu" action:nil keyEquivalent:@"" ];
	[ submenu addItem:clear ];
	[ openRecent setSubmenu:submenu ];
	fclose(file);
}

- (void) addToRecentlyOpened:(NSString*)directory
{
	int index = [ self checkIfRecentlyOpened:directory ];
	if (index != 0)
		[ [ openRecent submenu ] removeItemAtIndex:index - 1 ];
	NSMenuItem* openRecentItem = [ [ NSMenuItem alloc ] initWithTitle:[ directory lastPathComponent ] action:@selector(openRecent:) keyEquivalent:@"" ];
	[ [ openRecent submenu ] insertItem:openRecentItem atIndex:0 ];
	
	FILE* file = [ self recentlyOpenedFile ];
	if (!file)
		return;
	
	unsigned char number = 0;
	NSMutableArray* array = [ [ NSMutableArray alloc ] init ];
	fread(&number, 1, 1, file);
	for (int z = 0; z < number; z++)
	{
		// Add them to the list
		unsigned int length = 0;
		fread(&length, 1, sizeof(unsigned int), file);
		char* str = (char*)malloc(length + 1);
		fread(str, length, 1, file);
		str[length] = 0;
		NSString* theString = [ [ NSString alloc ] initWithFormat:@"%s", str ];
		[ array addObject:theString ];
		free(str);
		str = NULL;
	}
	
	if (index != 0)
	{
		[ array removeObjectAtIndex:index - 1 ];
		[ array addObject:directory ];
	}
	else
	{
		[ array addObject:directory ];
		while ([ array count ] > OPEN_RECENT)
			[ array removeObjectAtIndex:0 ];
	}
	
	fseek(file, SEEK_SET, 0);
	number = (unsigned char)[ array count ];
	fwrite(&number, 1, 1, file);
	for (int z = 0 ; z < [ array count ]; z++)
	{
		unsigned int length = (unsigned int)[ [ array objectAtIndex:z ] length ];
		fwrite(&length, 1, sizeof(unsigned int), file);
		fwrite([ [ array objectAtIndex:z ] UTF8String ], length, 1, file);
	}
	fclose(file);
	
	[ self readRecentlyOpened ];
}

- (int) checkIfRecentlyOpened: (NSString*)directory
{
	FILE* file = [ self recentlyOpenedFile ];
	if (!file)
		return 0;
	
	// Read how many recents there are
	int ret = 0;
	unsigned char number = 0;
	fread(&number, 1, 1, file);
	for (int z = 0; z < number; z++)
	{
		// Add them to the list
		unsigned int length = 0;
		fread(&length, 1, sizeof(unsigned int), file);
		char* str = (char*)malloc(length + 1);
		fread(str, length, 1, file);
		str[length] = 0;
		if ([ directory isEqualToString:[ NSString stringWithFormat:@"%s", str ] ])
		{
			ret = z + 1;
			free(str);
			str = NULL;
			break;
		}
		free(str);
		str = NULL;
	}
	fclose(file);
	
	return ret;
}

- (IBAction) clearMenu: (id) sender
{
	NSString* path = [ NSString stringWithFormat:@"%@/Recent.txt", [ [ NSBundle mainBundle ] resourcePath ] ];
	FILE* file = fopen([ path UTF8String ], "w+");
	if (!file)
	{
		// A file can't be created
		NSRunAlertPanel(@"Error", @"Cannot read from disk.", @"Ok", nil, nil);
		return;
	}
	unsigned char num = 0;
	fwrite(&num, 1, 1, file);
	fclose(file);
	
	[ self readRecentlyOpened ];
}

- (IBAction) openRecent:(id) sender
{
	int z = 0;
	for (z = 0; z < [ [ sender menu ] numberOfItems ]; z++)
	{
		if (sender == [ [ sender menu ] itemAtIndex:z ])
			break;
	}
	if (z >= OPEN_RECENT)
		return;
	FILE* file = [ self recentlyOpenedFile ];
	if (!file)
		return;
	unsigned char num = 0;
	fread(&num, 1, 1, file);
	if (num <= z)
	{
		fclose(file);
		return;
	}
	for (int q = 0; q <= num - z - 1; q++)
	{
		unsigned int length = 0;
		fread(&length, 1, sizeof(unsigned int), file);
		char* temp = (char*)malloc(length + 1);
		fread(temp, length, 1, file);
		temp[length] = 0;
		if (q == num - z - 1)
		{
			NSString* name = [ [ NSString alloc ] initWithFormat:@"%s", temp ];
			if (![ [ NSFileManager defaultManager ] fileExistsAtPath:name ])
			{
				NSRunAlertPanel(@"Error", @"%@ does not exist", @"Ok", nil, nil, name);
				fclose(file);
				free(temp);
				temp = NULL;
				return;
			}
			
			if ([ glWindow isVisible ] && documentEdited)
			{
				unsigned long z = NSRunAlertPanel(@"Confirm", @"If you open a new project, you will lose unsaved data. Do you want to save?", @"Cancel", @"Save", @"Dont Save");
				if (z == NSAlertDefaultReturn)
					return;
				else if (z == NSAlertAlternateReturn)
					[ self save:self ];
			}
			
			workingDirectory = [ [ NSString alloc ] initWithString:[ name substringToIndex:[ name length ] - [ [ name lastPathComponent ] length ] ] ]; 
			[ self readProject ];
		}
		free(temp);
		temp = NULL;
	}
	fclose(file);
}

#pragma mark Preferences

- (IBAction) showPreferences:(id)sender
{
	[ self readPreferences ];
	[ preferenceShowStartup setState:showIntroWindow ];
	[ preferenceGrid setState:((projectCommand & MD_PROJECT_SHOW_GRID) != 0) ];
	[ preferencePause setState:((projectCommand & MD_PROJECT_DISABLE) != 0) ];
	[ preferenceCodesign setState:((projectCommand & MD_PROJECT_CODESIGN) != 0) ];
	[ preferenceCertificate setEnabled:((projectCommand & MD_PROJECT_CODESIGN) != 0) ];
	[ preferenceCertificate setStringValue:projectCertificate ];
	[ preferenceName setStringValue:projectAuthor ];
	[ preferenceWindow makeKeyAndOrderFront:self ];
}

- (IBAction) preferencesShowStartup:(id)sender
{
	showIntroWindow = [ (NSButton*)sender state ];
	[ self savePreferences ];
}

- (IBAction) preferenceGrid:(id)sender
{
	if (projectCommand & MD_PROJECT_SHOW_GRID)
		projectCommand &= ~(MD_PROJECT_SHOW_GRID);
	else
		projectCommand |= MD_PROJECT_SHOW_GRID;
	[ self savePreferences ];
}

- (IBAction) preferencePause:(id)sender
{
	if (projectCommand & MD_PROJECT_DISABLE)
		projectCommand &= ~(MD_PROJECT_DISABLE);
	else
		projectCommand |= MD_PROJECT_DISABLE;
	[ self savePreferences ];
}

- (IBAction) preferenceFramework:(id)sender
{
	destinationSearchPath = preferenceFramework;
	[ self preferenceSetupSearch ];
	[ NSApp beginSheet:preferencePanelSearch modalForWindow:preferenceWindow modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil ];
}

- (IBAction) preferenceHeader:(id)sender
{
	destinationSearchPath = preferenceHeader;
	[ self preferenceSetupSearch ];
	[ NSApp beginSheet:preferencePanelSearch modalForWindow:preferenceWindow modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil ];
}

- (IBAction) preferenceLibrary:(id)sender
{
	destinationSearchPath = preferenceLibrary;
	[ self preferenceSetupSearch ];
	[ NSApp beginSheet:preferencePanelSearch modalForWindow:preferenceWindow modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil ];
}

- (void) preferenceSetupSearch
{
	[ preferenceSearchTable removeAllRows ];
	
	NSArray* array = nil;
	if (destinationSearchPath == preferenceFramework)
		array = [ searchPaths objectForKey:@"Frameworks" ];
	else if (destinationSearchPath == preferenceHeader)
		array = [ searchPaths objectForKey:@"Headers" ];
	else if (destinationSearchPath == preferenceLibrary)
		array = [ searchPaths objectForKey:@"Libraries" ];
	
	for (unsigned long z = 0; z < [ array count ]; z++)
		[ preferenceSearchTable addRow:[ NSDictionary dictionaryWithObject:[ array objectAtIndex:z ] forKey:@"Path" ] ];
	[ preferenceSearchTable reloadData ];
}

- (IBAction) preferenceSearchRemove:(id)sender
{
	if ([ preferenceSearchTable selectedRow ] == -1)
		return;
	unsigned long row = [ preferenceSearchTable selectedRow ];
	[ preferenceSearchTable removeRow:(unsigned int)[ preferenceSearchTable selectedRow ] ];
	[ preferenceSearchTable reloadData ];
	
	NSMutableString* str = [ [ NSMutableString alloc ] init ];
	for (unsigned long z = 0; z < [ preferenceSearchTable numberOfRows ]; z++)
		[ str appendFormat:@"{ \"%@\" }, ", [ [ preferenceSearchTable itemAtRow:(unsigned int)z ] objectForKey:@"Path" ] ];
	[ destinationSearchPath setStringValue:str ];
	
	unsigned int keyPath = 0;
	if (destinationSearchPath == preferenceFramework)
		keyPath = 0;
	else if (destinationSearchPath == preferenceHeader)
		keyPath = 1;
	else if (destinationSearchPath == preferenceLibrary)
		keyPath = 2;
	
	NSMutableArray* array = [ searchPaths objectForKey:[ [ searchPaths allKeys ] objectAtIndex:keyPath ] ];
	[ array removeObjectAtIndex:row ];
	[ self savePreferences ];
}

- (IBAction) preferenceSearchAdd:(id)sender
{
	NSOpenPanel* panel = [ NSOpenPanel openPanel ];
	[ panel setTreatsFilePackagesAsDirectories:YES ];
	[ panel setCanChooseDirectories:YES ];
	[ panel setCanChooseFiles:NO ];
	[ panel setAllowsMultipleSelection:YES ];
	if ([ panel runModal ])
	{
		unsigned int keyPath = 0;
		if (destinationSearchPath == preferenceFramework)
			keyPath = 0;
		else if (destinationSearchPath == preferenceHeader)
			keyPath = 1;
		else if (destinationSearchPath == preferenceLibrary)
			keyPath = 2;
		
		NSMutableArray* array = [ searchPaths objectForKey:[ [ searchPaths allKeys ] objectAtIndex:keyPath ] ];
		for (unsigned long z = 0; z < [ [ panel URLs ] count ]; z++)
		{
			NSURL* url = [ [ panel URLs ] objectAtIndex:z ];
			NSString* path = [ [ NSString alloc ] initWithString:[ [ [ url absoluteString ] substringFromIndex:7 ] stringByReplacingPercentEscapesUsingEncoding:NSASCIIStringEncoding ] ];
			[ preferenceSearchTable addRow:[ NSDictionary dictionaryWithObject:path forKey:@"Path" ] ];
			[ array addObject:path ];
		}
		[ preferenceSearchTable reloadData ];
	}
	
	[ self savePreferences ];
	
	NSMutableString* str = [ [ NSMutableString alloc ] init ];
	for (unsigned long z = 0; z < [ preferenceSearchTable numberOfRows ]; z++)
		[ str appendFormat:@"{ \"%@\" }, ", [ [ preferenceSearchTable itemAtRow:(unsigned int)z ] objectForKey:@"Path" ] ];
	[ destinationSearchPath setStringValue:str ];
}

- (IBAction) preferenceSearchClose:(id)sender
{
	[ NSApp endSheet:preferencePanelSearch ];
}

- (IBAction) preferenceCodesign:(id)sender
{
	if (projectCommand & MD_PROJECT_CODESIGN)
	{
		projectCommand &= ~(MD_PROJECT_CODESIGN);
		[ preferenceCertificate setEnabled:NO ];
	}
	else
	{
		projectCommand |= MD_PROJECT_CODESIGN;
		[ preferenceCertificate setEnabled:YES ];
	}
	[ self savePreferences ];
}

- (IBAction) preferenceEditCertificate:(id)sender
{
	projectCertificate = [ [ NSString alloc ] initWithString:[ preferenceCertificate stringValue ] ];
	[ self savePreferences ];
}

- (IBAction) preferenceEditName:(id)sender
{
	projectAuthor = [ [ NSString alloc ] initWithString:[ preferenceName stringValue ] ];
	[ self savePreferences ];
}

- (void) savePreferences
{
	NSString* path = [ NSString stringWithFormat:@"%@/preferences", [ [ NSBundle mainBundle ] resourcePath ] ];
	FILE* file = fopen([ path UTF8String ], "w");
	fwrite(&projectCommand, 1, sizeof(unsigned int), file);
	fwrite(&showIntroWindow, 1, sizeof(BOOL), file);
	for (unsigned int y = 0; y < [ [ searchPaths allKeys ] count ]; y++)
	{
		NSString* key = [ [ searchPaths allKeys ] objectAtIndex:y ];
		NSArray* array = [ searchPaths objectForKey:key ];
		unsigned short count = [ array count ];
		fwrite(&count, 1, sizeof(unsigned short), file);
		for (unsigned long z = 0; z < [ array count ]; z++)
		{
			NSString* string = [ array objectAtIndex:z ];
			unsigned int length = (unsigned int)[ string length ];
			fwrite(&length, 1, sizeof(unsigned int), file);
			fwrite([ string UTF8String ], 1, length, file);
		}
	}
	unsigned int certLength = (unsigned int)[ [ preferenceCertificate stringValue ] length ];
	fwrite(&certLength, 1, sizeof(unsigned int), file);
	fwrite([ [ preferenceCertificate stringValue ] UTF8String ], certLength, 1, file);
	unsigned int nameLength = (unsigned int)[ [ preferenceName stringValue ] length ];
	fwrite(&nameLength, 1, sizeof(unsigned int), file);
	fwrite([ [ preferenceName stringValue ] UTF8String ], nameLength, 1, file);
	fclose(file);
}

- (void) readPreferences
{
	NSString* path = [ NSString stringWithFormat:@"%@/preferences", [ [ NSBundle mainBundle ] resourcePath ] ];
	FILE* file = fopen([ path UTF8String ], "r");
	if (!file)
	{
		showIntroWindow = TRUE;
		projectCommand = MD_PROJECT_SHOW_GRID | MD_PROJECT_DISABLE;
		[ searchPaths removeAllObjects ];
		[ searchPaths addEntriesFromDictionary:[ NSDictionary dictionaryWithObject:[ NSMutableArray arrayWithObjects:@"/System/Library/Frameworks/", nil] forKey:@"Frameworks" ] ];
		[ searchPaths addEntriesFromDictionary:[ NSDictionary dictionaryWithObject:[ NSMutableArray arrayWithObjects:@"/usr/include/", nil] forKey:@"Headers" ] ];
		[ searchPaths addEntriesFromDictionary:[ NSDictionary dictionaryWithObject:[ NSMutableArray arrayWithObjects:@"/usr/lib/", nil] forKey:@"Libraries" ] ];
		[ self savePreferences ];
		[ self readPreferences ];
		return;
	}
	fread(&projectCommand, 1, sizeof(unsigned int), file);
	fread(&showIntroWindow, 1, sizeof(BOOL), file);
	[ searchPaths removeAllObjects ];
	NSString* keys[] = { @"Frameworks", @"Headers", @"Libraries" };
	NSTextField* fields[] = { preferenceFramework, preferenceHeader, preferenceLibrary };
	for (unsigned int y = 0; y < 3; y++)
	{
		unsigned short count = 0;
		fread(&count, 1, sizeof(unsigned short), file);
		NSMutableArray* array = [ [ NSMutableArray alloc ] init ];
		for (unsigned long z = 0; z < count; z++)
		{
			unsigned int length = 0;
			fread(&length, 1, sizeof(unsigned int), file);
			char* buffer = (char*)malloc(length + 1);
			fread(buffer, 1, length, file);
			buffer[length] = 0;
			[ array addObject:[ NSString stringWithUTF8String:buffer ] ];
			free(buffer);
			buffer = NULL;
		}
		[ searchPaths addEntriesFromDictionary:[ NSDictionary dictionaryWithObject:array forKey:keys[y] ] ];
		
		NSMutableString* str = [ [ NSMutableString alloc ] init ];
		for (unsigned long z = 0; z < [ array count ]; z++)
			[ str appendFormat:@"{ \"%@\" }, ", [ array objectAtIndex:z ] ];
		[ fields[y] setStringValue:str ];
	}
	unsigned int certLength = 0;
	fread(&certLength, 1, sizeof(unsigned int), file);
	char* buffer = (char*)malloc(certLength + 1);
	fread(buffer, certLength, sizeof(char), file);
	buffer[certLength] = 0;
	projectCertificate = [ [ NSString alloc ] initWithUTF8String:buffer ];
	free(buffer);
	unsigned int nameLength = 0;
	fread(&nameLength, 1, sizeof(unsigned int), file);
	buffer = (char*)malloc(nameLength + 1);
	fread(buffer, nameLength, sizeof(char), file);
	buffer[nameLength] = 0;
	projectAuthor = [ [ NSString alloc ] initWithUTF8String:buffer ];
	free(buffer);
	fclose(file);
}

#pragma mark Code Help

- (void) setupCodeHelp
{
	[ codeHelpOutline setTarget:self ];
	[ codeHelpOutline setSelectAction:@selector(codeHelpOutlineSelected:) ];
	
	// Read all the files
	NSArray* array = [ [ [ NSFileManager defaultManager ] enumeratorAtPath:[ NSString stringWithFormat:@"%@/Help/", [ [ NSBundle mainBundle ] resourcePath ] ] ] allObjects ];
	
	for (unsigned long z = 0; z < [ array count ]; z++)
	{
		NSString* path = [ array objectAtIndex:z ];
		// Find node
		IFNode* parent = [ codeHelpOutline rootNode ];
		IFNode* parent2 = parent;
		NSString* str1 = path;
		NSString* str2 = path;
		while (parent)
		{
			parent2 = parent;
			NSRange range = [ str2 rangeOfString:@"/" ];
			if (range.length == 0)
			{
				break;
			}
			str1 = [ str2 substringToIndex:range.location ];
			str2 = [ str2 substringFromIndex:range.location + 1 ];
			parent = [ parent childWithTitle:str1 ];
		}
		parent = parent2;
		
		if ([ path hasSuffix:@".txt" ])
		{
			IFNode* next = [ [ IFNode alloc ] initLeafWithTitle:[ [ path lastPathComponent ] stringByDeletingPathExtension ] ];
			[ parent addChild:next ];
		}
		else
		{
			IFNode* next = [ [ IFNode alloc ] initParentWithTitle:[ path lastPathComponent ] children:nil ];
			[ parent addChild:next ];
		}
	}
	[ codeHelpView setFiles:array ];
	[ codeHelpOutline reloadData ];
}

- (void) codeHelpOutlineSelected:(id)sender
{
	NSMutableString* path = [ [ NSMutableString alloc ] initWithString:@".txt" ];
	IFNode* current = [ codeHelpOutline selectedNode ];
	while (current != [ codeHelpOutline rootNode ] && current)
	{
		[ path insertString:[ NSString stringWithFormat:@"/%@", [ current title ] ] atIndex:0 ];
		current = [ current parentItem ];
	}
	
	if (current)
		[ codeHelpView loadFile:[ NSString stringWithFormat:@"%@/Help%@", [ [ NSBundle mainBundle ] resourcePath ], path ] ];
}

- (IBAction) openCodeFile:(id) sender
{
	NSString* file = [ (NSMenuItem*)sender title ];
	[ codeHeadersView setEditable:NO ];
	NSString* filename = [ NSString stringWithFormat:@"%@/Headers/MovieDraw/%@", [ [ NSBundle mainBundle ] resourcePath ], file ];
	[ codeHeadersView setFileName:filename ];
	[ codeHeadersView setText:[ NSString stringWithContentsOfFile:filename encoding:NSASCIIStringEncoding error:nil ] ];
	[ codeHeadersWindow setTitle:[ NSString stringWithFormat:@"Code Headers - %@", file ] ];
	[ codeHeadersWindow makeKeyAndOrderFront:self ];
}

- (IBAction) searchCodeHelp:(id)sender
{
	[ codeHelpView searchWord:[ sender stringValue ] ];
}

#pragma mark Project Reading

- (IBAction) open: (id) sender
{
	// Create an open panel
	NSOpenPanel* panel = [ NSOpenPanel openPanel ];
	[ panel setAllowedFileTypes:[ NSArray arrayWithObject:@"mdp" ] ];
	if ([ panel runModal ])
	{
		if ([ glWindow isVisible ] && documentEdited)
		{
			unsigned long z = NSRunAlertPanel(@"Confirm", @"If you open a new project, you will lose unsaved data. Do you want to save?", @"Cancel", @"Save", @"Dont Save");
			if (z == NSAlertDefaultReturn)
				return;
			else if (z == NSAlertAlternateReturn)
				[ self save:self ];
		}
		
		// Set the working directory
		NSString* tempWorkingDirectory = [ [ NSString alloc ] initWithString:[ [ [ [ panel URL ] absoluteString ] substringToIndex:[ [ [ panel URL ] absoluteString ] length ] - [ [ [ [ panel URL ] absoluteString ] lastPathComponent ] length ] ] substringFromIndex:7 ] ];
		workingDirectory = [ [ NSString alloc ] initWithString:[ tempWorkingDirectory stringByReplacingOccurrencesOfString:@"%20" withString:@" " ] ];
		
		// Read the project opened;
		[ self readProject ];
		[ self addToRecentlyOpened:[ NSString stringWithString:[ [ [ panel URL ] absoluteString ] substringFromIndex:7 ] ] ];
		[ introWindow orderOut:self ];
	}
}

- (IBAction) read:(id)sender project:(BOOL)proj
{
	MDReadProject(proj, editorView, glWindow, sceneTable, fileOutline);
	
	commandFlag |= UPDATE_INFO;
	commandFlag |= UPDATE_SCENE_INFO;
	commandFlag |= UPDATE_LIBRARY;
	
	documentEdited = FALSE;
}

// Read and open the project from the working directory
- (void) readProject
{
	if ([ glWindow isVisible ])
	{
		[ undoManager removeAllActions ];
		[ undoItem setAction:nil ];
		[ undoItem setTitle:@"Undo" ];
		[ redoItem setAction:nil ];
		[ redoItem setTitle:@"Redo" ];
	}
	
	// Check if project is open and that a working directory exists
	if (!workingDirectory)
		return;
	[ introWindow orderOut:self ];
	
	// Reset everything
	commandFlag |= UPDATE_INFO;
	commandFlag |= UPDATE_SCENE_INFO;
	commandFlag |= UPDATE_LIBRARY;
	
	NSRect titleBar = NSMakeRect (0, 0, 100, 100);
    NSRect contentRect = [ NSWindow contentRectForFrameRect:titleBar styleMask:NSTitledWindowMask ];
    float titleHeight = (titleBar.size.height - contentRect.size.height);
	
	// Set the menu correctly
	[ saveMenu setAction:@selector(save:) ];
	[ toolMenu setHidden:NO ];
	[ importMenu setEnabled:YES ];
	[ exportMenu setEnabled:YES ];
	[ sceneMenu setHidden:NO ];
	[ objectMenu setHidden:NO ];
	// Disable animation menu for now
	//[ animationMenu setHidden:NO ];
	[ createMenu setHidden:NO ];
	[ projectMenu setHidden:NO ];
	[ selectAllMenu setAction:@selector(selectAll:) ];
	[ viewInspectorPanel setAction:@selector(viewInspectorPanel:) ];
	[ viewInfoPanel setAction:@selector(viewInfoPanel:) ];
	[ viewConsolePanel setAction:@selector(viewConsolePanel:) ];
	[ viewProjectPanel setAction:@selector(viewProjectPanel:) ];
	if (copyData.size() != 0)
	{
		[ pasteMenu setAction:@selector(paste:) ];
		[ pastePlaceMenu setAction:@selector(pasteInPlace:) ];
	}
	
	// Set up the GLView
	[ glWindow setUpGLView ];
	[ glWindow setTitle:[ NSString stringWithFormat:@"MovieDraw - %@", [ workingDirectory lastPathComponent ] ] ];
	
	// Read the actual project
	[ self read:self project:YES ];
	NSRect frame = [ glWindow frame ];
	frame.size = projectRes;
	frame.size.height += titleHeight;
	[ glWindow setFrame:frame display:YES ];
	
	[ self setUpFilePanel ];
	// Bring other windows
	if (![ inspectorPanel isVisible ])
		[ self viewInspectorPanel:viewInspectorPanel ];
	if (![ [ infoTable window ] isVisible ])
		[ self viewInfoPanel:viewInfoPanel ];
	//if (![ consoleWindow isVisible ])
	//	[ self viewConsolePanel:viewConsolePanel ];
	if ([ editorWindow isVisible ])
		[ editorWindow orderOut:self ];
	
	[ [ glWindow glView ] reshape ];
	[ glWindow makeKeyAndOrderFront:self ];
	[ glWindow makeFirstResponder:[ glWindow contentView ] ];
	
}

- (IBAction) save:(id)sender
{
	[ self saveWithPics:YES andModels:YES ];
}

- (void) saveWithPics:(BOOL)pics andModels:(BOOL)models
{
	/*if (pics)
	{
		NSString* backup = [ NSString stringWithString:currentScene ];
		for (unsigned int z = 0; z < [ sceneTable numberOfRows ]; z++)
		{
			if (currentScene)
				[ currentScene release ];
			currentScene = [ [ NSString alloc ] initWithString:[ [ sceneTable itemAtRow:z ] objectForKey:@"Name" ] ];
			[ self saveWithPics:NO ];
		}
		[ currentScene release ];
		currentScene = [ [ NSString alloc ] initWithString:backup ];
	}*/
		
	MDSaveProject(pics, models, editorView, glWindow, sceneTable, fileOutline);
	
	documentEdited = FALSE;
	
	if ([ [ editorView window ] isVisible ])
	{
		[ [ NSFileManager defaultManager ] createFileAtPath:currentOpenFile contents:[ NSData dataWithBytes:[ [ editorView string ] UTF8String ] length:[ [ editorView string ] length ] ] attributes:nil ];
	}
}

#pragma mark Tools

- (IBAction) selectionTool: (id) sender
{
	currentTool = MD_SELECTION_TOOL;
	for (int z = 0; z < [ [ toolMenu submenu ] numberOfItems ]; z++)
		[ [ [ toolMenu submenu ] itemAtIndex:z ] setState:NSOffState ];
	[ (NSMenuItem*)sender setState:NSOnState ];
}

- (IBAction) moveTool: (id) sender
{
	currentTool = MD_MOVE_TOOL;
	for (int z = 0; z < [ [ toolMenu submenu ] numberOfItems ]; z++)
		[ [ [ toolMenu submenu ] itemAtIndex:z ] setState:NSOffState ];
	[ (NSMenuItem*)sender setState:NSOnState ];
}

- (IBAction) zoomTool: (id) sender
{
	currentTool = MD_ZOOM_TOOL;
	for (int z = 0; z < [ [ toolMenu submenu ] numberOfItems ]; z++)
		[ [ [ toolMenu submenu ] itemAtIndex:z ] setState:NSOffState ];
	[ (NSMenuItem*)sender setState:NSOnState ];
}

- (IBAction) rotationTool: (id) sender
{
	currentTool = MD_ROTATE_TOOL;
	for (int z = 0; z < [ [ toolMenu submenu ] numberOfItems ]; z++)
		[ [ [ toolMenu submenu ] itemAtIndex:z ] setState:NSOffState ];
	[ (NSMenuItem*)sender setState:NSOnState ];
}

#pragma mark Mode Tools

- (IBAction) objectMode:(id)sender
{
	currentMode = MD_OBJECT_MODE;
	for (int z = 0; z < [ [ modeMenu submenu ] numberOfItems ]; z++)
		[ [ [ modeMenu submenu ] itemAtIndex:z ] setState:NSOffState ];
	[ (NSMenuItem*)sender setState:NSOnState ];
	[ selected clear ];
	
	commandFlag |= UPDATE_INFO;
	[ copyMenu setAction:nil ];
	[ duplicateMenu setAction:nil ];
	[ cutMenu setAction:nil ];
	[ objectCombine setAction:nil ];
	[ objectTrans setAction:nil ];
	[ objectNormalize setEnabled:NO ];
	[ objectAddTexture setAction:nil ];
	[ objectReverseWinding setAction:nil ];
	[ objectSetHeight setAction:nil ];
	[ objectExportHeight setAction:nil ];
	[ objectProperties setAction:nil ];
	[ objectPhysicsProperties setAction:nil ];
	[ objectAnimations setAction:nil ];
	[ objectHidden setAction:nil ];
	[ objectHidden setState:NSOffState ];
	[ deleteMenu setAction:@selector(deleteItem:) ];
	[ sizeTool setAction:@selector(sizeObject:) ];
	[ rotateTool setAction:nil ];
	// Disable Rotate;
	//[ rotateTool setAction:@selector(rotateObject:) ];
}

- (IBAction) faceMode:(id)sender
{
	currentMode = MD_FACE_MODE;
	for (int z = 0; z < [ [ modeMenu submenu ] numberOfItems ]; z++)
		[ [ [ modeMenu submenu ] itemAtIndex:z ] setState:NSOffState ];
	[ (NSMenuItem*)sender setState:NSOnState ];
	[ selected clear ];
	
	commandFlag |= UPDATE_INFO;
	[ copyMenu setAction:nil ];
	[ duplicateMenu setAction:nil ];
	[ cutMenu setAction:nil ];
	[ objectCombine setAction:nil ];
	[ objectTrans setAction:nil ];
	[ objectNormalize setEnabled:NO ];
	[ objectAddTexture setAction:nil ];
	[ objectReverseWinding setAction:nil ];
	[ objectSetHeight setAction:nil ];
	[ objectExportHeight setAction:nil ];
	[ objectProperties setAction:nil ];
	[ objectPhysicsProperties setAction:nil ];
	[ objectAnimations setAction:nil ];
	[ objectHidden setAction:nil ];
	[ objectHidden setState:NSOffState ];
	[ sizeTool setAction:nil ];
	[ rotateTool setAction:nil ];
	[ deleteMenu setAction:@selector(deleteItem:) ];
	if (currentObjectTool == MD_OBJECT_ROTATE || currentObjectTool == MD_OBJECT_SIZE)
		[ self noObject:noTool ];
}

- (IBAction) edgeMode:(id)sender
{
	currentMode = MD_EDGE_MODE;
	for (int z = 0; z < [ [ modeMenu submenu ] numberOfItems ]; z++)
		[ [ [ modeMenu submenu ] itemAtIndex:z ] setState:NSOffState ];
	[ (NSMenuItem*)sender setState:NSOnState ];
	[ selected clear ];
	
	commandFlag |= UPDATE_INFO;
	[ copyMenu setAction:nil ];
	[ duplicateMenu setAction:nil ];
	[ cutMenu setAction:nil ];
	[ objectCombine setAction:nil ];
	[ objectTrans setAction:nil ];
	[ objectNormalize setEnabled:NO ];
	[ objectAddTexture setAction:nil ];
	[ objectReverseWinding setAction:nil ];
	[ objectSetHeight setAction:nil ];
	[ objectExportHeight setAction:nil ];
	[ objectProperties setAction:nil ];
	[ objectPhysicsProperties setAction:nil ];
	[ objectAnimations setAction:nil ];
	[ objectHidden setAction:nil ];
	[ objectHidden setState:NSOffState ];
	[ sizeTool setAction:nil ];
	[ rotateTool setAction:nil ];
	[ deleteMenu setAction:nil ];
	if (currentObjectTool == MD_OBJECT_ROTATE || currentObjectTool == MD_OBJECT_SIZE)
		[ self noObject:noTool ];
}

- (IBAction) vertexMode:(id)sender
{
	currentMode = MD_VERTEX_MODE;
	for (int z = 0; z < [ [ modeMenu submenu ] numberOfItems ]; z++)
		[ [ [ modeMenu submenu ] itemAtIndex:z ] setState:NSOffState ];
	[ (NSMenuItem*)sender setState:NSOnState ];
	[ selected clear ];
	
	commandFlag |= UPDATE_INFO;
	[ copyMenu setAction:nil ];
	[ duplicateMenu setAction:nil ];
	[ cutMenu setAction:nil ];
	[ objectCombine setAction:nil ];
	[ objectTrans setAction:nil ];
	[ objectNormalize setEnabled:NO ];
	[ objectAddTexture setAction:nil ];
	[ objectReverseWinding setAction:nil ];
	[ objectSetHeight setAction:nil ];
	[ objectExportHeight setAction:nil ];
	[ objectProperties setAction:nil ];
	[ objectPhysicsProperties setAction:nil ];
	[ objectAnimations setAction:nil ];
	[ objectHidden setAction:nil ];
	[ objectHidden setState:NSOffState ];
	[ sizeTool setAction:nil ];
	[ rotateTool setAction:nil ];
	[ deleteMenu setAction:nil ];
	if (currentObjectTool == MD_OBJECT_ROTATE || currentObjectTool == MD_OBJECT_SIZE)
		[ self noObject:noTool ];
}

#pragma mark Object Tools

- (IBAction) noObject: (id) sender
{
	currentObjectTool = MD_OBJECT_NO;
	for (int z = 0; z < [ [ objectMenu submenu ] numberOfItems ]; z++)
		[ [ [ objectMenu submenu ] itemAtIndex:z ] setState:NSOffState ];
	[ (NSMenuItem*)sender setState:NSOnState ];
}

- (IBAction) moveObject: (id) sender
{
	currentObjectTool = MD_OBJECT_MOVE;
	for (int z = 0; z < [ [ objectMenu submenu ] numberOfItems ]; z++)
		[ [ [ objectMenu submenu ] itemAtIndex:z ] setState:NSOffState ];
	[ (NSMenuItem*)sender setState:NSOnState ];
}

- (IBAction) sizeObject: (id) sender
{
	currentObjectTool = MD_OBJECT_SIZE;
	for (int z = 0; z < [ [ objectMenu submenu ] numberOfItems ]; z++)
		[ [ [ objectMenu submenu ] itemAtIndex:z ] setState:NSOffState ];
	[ (NSMenuItem*)sender setState:NSOnState ];
}

- (IBAction) rotateObject: (id) sender
{
	currentObjectTool = MD_OBJECT_ROTATE;
	for (int z = 0; z < [ [ objectMenu submenu ] numberOfItems ]; z++)
		[ [ [ objectMenu submenu ] itemAtIndex:z ] setState:NSOffState ];
	[ (NSMenuItem*)sender setState:NSOnState ];
}

- (IBAction) applyTransformations: (id)sender
{
	if ([ selected count ] == 0)
		return;
	[ undoManager setActionName:@"Apply Transformations" ];
	for (int z = 0; z < [ selected count ]; z++)
	{
		MDInstance* instance = ApplyTransformationInstanceTranslates([ [ selected selectedValueAtIndex:z ] objectForKey:@"Object" ]);
		[ Controller setMDInstance:instance atIndex:[ instances indexOfObject:[ [ [ selected selectedValueAtIndex:z ] objectForKey:@"Object" ] instance ] ] ];
		
		MDObject* obj = [ [ MDObject alloc ] initWithObject:[ [ selected selectedValueAtIndex:z ] objectForKey:@"Object" ] ];
		obj.rotateAngle = 0;
		obj.rotateAxis = MDVector3Create(0, 0, 0);
		obj.scaleX = obj.scaleY = obj.scaleZ = 1;
		[ Controller setMDObject:obj atIndex:[ objects indexOfObject:[ [ selected selectedValueAtIndex:z ] objectForKey:@"Object" ] ] faceIndex:NSNotFound edgeIndex:NSNotFound pointIndex:NSNotFound selectionIndex:z ];
	}
}

- (IBAction) combineObjects:(id)sender
{
	if ([ selected count ] <= 1)
		return;
	if (currentMode != MD_OBJECT_MODE)
		return;
	
	MDInstance* objs[[ selected count ]];
	for (int z = 0; z < [ selected count ]; z++)
		objs[z] = ApplyTransformationInstance([ [ selected selectedValueAtIndex:z ] objectForKey:@"Object" ]);
	
	MDInstance* instance = [ [ MDInstance alloc ] init ];
	for (unsigned long z = 0; z < [ selected count ]; z++)
	{
		for (unsigned long q = 0; q < [ objs[z] numberOfMeshes ]; q++)
		{
			MDMesh* mesh = [ [ MDMesh alloc ] initWithMesh:[ objs[z] meshAtIndex:q ] ];
			[ instance addMesh:mesh ];
		}
	}
	
	[ self deleteItem:sender ];
	// Set the correct name
	for (unsigned long q = 0; true; q++)
	{
		[ instance setName:[ NSString stringWithFormat:@"Combined Object %lu", q ] ];
		BOOL end = TRUE;
		for (unsigned long z = 0; z < [ instances count ]; z++)
		{
			if ([ [ [ instances objectAtIndex:z ] name ] isEqualToString:[ instance name ] ])
			{
				end = FALSE;
				break;
			}
		}
		if (end)
			break;
	}
	MDVector3 midP = [ instance midPoint ];
	[ instance setMidPoint:MDVector3Create(0, 0, 0) ];
	[ instance setupVBO ];
	[ instances addObject:instance ];
	
	MDObject* obj = [ [ MDObject alloc ] initWithInstance:[ instances lastObject ] ];
	[ obj setTranslateX:midP.x ];
	[ obj setTranslateY:midP.y ];
	[ obj setTranslateZ:midP.z ];
	obj.objectColors[0].x = 0.7;
	obj.objectColors[0].w = 1;
	obj.objectColors[1].z = 0.7;
	obj.objectColors[1].w = 1;
	obj.objectColors[2].x = 0.7;
	obj.objectColors[2].y = 0.7;
	obj.objectColors[2].w = 1;
	
	NSMutableArray* array = [ NSMutableArray array ];
	for (int z = 0; z < [ objects count ]; z++)
	{
		MDObject* obj2 = [ [ MDObject alloc ] initWithObject:[ objects objectAtIndex:z ] ];
		[ array addObject:obj2 ];
	}
	[ array addObject:obj ];
	[ selected clear ];
	[ selected addObject:obj ];
	[ undoManager setActionName:@"Combine Objects" ];
	MDSelection* newSel = [ [ MDSelection alloc ] initWithSelection:selected ];
	[ Controller setObjects:array selected:newSel andInstances:instances ];
	
	[ [ glWindow glView ] loadNewTextures ];
}

- (IBAction) faceNormalize:(id)sender
{
	for (unsigned long z = 0; z < [ selected count ]; z++)
	{
		MDObject* obj = [ [ selected selectedValueAtIndex:z ] objectForKey:@"Object" ];
		MDInstance* face = [ [ MDInstance alloc ] initWithInstance:[ obj instance ] ];
		if ([ face numberOfPoints ] > 2)
		{
			unsigned int* temp = (unsigned int*)malloc(sizeof(unsigned int) * [ face numberOfPoints ]);
			memset(temp, 0, [ face numberOfPoints ] * sizeof(unsigned int));
			
			for (unsigned long t = 0; t < [ face numberOfPoints ]; t++)
				[ [ face pointAtIndex:t ] setNormal:MDVector3Create(0, 0, 0) ];
			
			unsigned long temp2 = 0;
			for (unsigned long t = 0; t < [ face numberOfIndices ]; t += 3)
			{
				unsigned long q1 = [ face indexAtIndex:t ];
				unsigned long q2 = [ face indexAtIndex:t + 1 ];
				unsigned long q3 = [ face indexAtIndex:t + 2 ];
				
				MDPoint* p1 = [ face pointAtIndex:q1 ];
				MDPoint* p2 = [ face pointAtIndex:q2 ];
				MDPoint* p3 = [ face pointAtIndex:q3 ];
								
				MDVector3 v21 = MDVector3Create(p1.x - p2.x, p1.y - p2.y, p1.z - p2.z);
				MDVector3 v23 = MDVector3Create(p3.x - p2.x, p3.y - p2.y, p3.z - p2.z);
				MDVector3 normal = MDVector3CrossProduct(v23, v21);
				
				temp[q1]++;
				temp[q2]++;
				temp[q3]++;
				
				if (q1 == 2500)
					temp2++;
				if (q2 == 2500)
					temp2++;
				if (q3 == 2500)
					temp2++;
				
				[ p1 setNormalX:normal.x + p1.normalX ];
				[ p1 setNormalY:normal.y + p1.normalY ];
				[ p1 setNormalZ:normal.z + p1.normalZ ];
				
				[ p2 setNormalX:normal.x + p2.normalX ];
				[ p2 setNormalY:normal.y + p2.normalY ];
				[ p2 setNormalZ:normal.z + p2.normalZ ];
				
				[ p3 setNormalX:normal.x + p3.normalX ];
				[ p3 setNormalY:normal.y + p3.normalY ];
				[ p3 setNormalZ:normal.z + p3.normalZ ];
			}
			for (unsigned long t = 0; t < [ face numberOfPoints ]; t++)
			{
				MDPoint* p = [ face pointAtIndex:t ];
				[ p setNormalX:p.normalX / temp[t] ];
				[ p setNormalY:p.normalY / temp[t] ];
				[ p setNormalZ:p.normalZ / temp[t] ];
				
				[ p setNormal:MDVector3Normalize(MDVector3Create(p.normalX, p.normalY, p.normalZ)) ];
			}
						
			free(temp);
			temp = NULL;
		}
		[ face setupVBO ];
	
		[ undoManager setActionName:@"Normalize" ];
		[ Controller setMDInstance:face atIndex:[ instances indexOfObject:[ obj instance ] ] ];
	}
}

- (IBAction) pointNormalize:(id)sender
{
	for (unsigned long z = 0; z < [ selected count ]; z++)
	{
		MDObject* obj = [ [ selected selectedValueAtIndex:z ] objectForKey:@"Object" ];
		
		MDInstance* face = [ [ MDInstance alloc ] initWithInstance:[ obj instance ] ];
		for (unsigned long q = 0; q < [ face numberOfPoints ]; q++)
		{
			MDPoint* p1 = [ face pointAtIndex:q ];
			MDVector3 final = MDVector3Create(p1.x, p1.y, p1.z);
			if (MDVector3Magnitude(final) != 0)
				final = MDVector3Normalize(final);
			[ p1 setNormalX:final.x ];
			[ p1 setNormalY:final.y ];
			[ p1 setNormalZ:final.z ];
		}
		[ face setupVBO ];
		
		[ undoManager setActionName:@"Normalize" ];
		[ Controller setMDInstance:face atIndex:[ instances indexOfObject:[ obj instance ] ] ];
	}
}

- (IBAction) invertNormals:(id)sender
{
	for (unsigned long z = 0; z < [ selected count ]; z++)
	{
		MDObject* obj = [ [ selected selectedValueAtIndex:z ] objectForKey:@"Object" ];
		
		MDInstance* face = [ [ MDInstance alloc ] initWithInstance:[ obj instance ] ];
		for (unsigned long q = 0; q < [ face numberOfPoints ]; q++)
		{
			MDPoint* p1 = [ face pointAtIndex:q ];
			[ p1 setNormalX:-p1.normalX ];
			[ p1 setNormalY:-p1.normalY ];
			[ p1 setNormalZ:-p1.normalZ ];
		}
		[ face setupVBO ];
		
		[ undoManager setActionName:@"Normalize" ];
		[ Controller setMDInstance:face atIndex:[ instances indexOfObject:[ obj instance ] ] ];
	}
}

- (IBAction) deleteNormals:(id)sender
{
	for (unsigned long z = 0; z < [ selected count ]; z++)
	{
		MDObject* obj = [ [ selected selectedValueAtIndex:z ] objectForKey:@"Object" ];
		
		MDInstance* face = [ [ MDInstance alloc ] initWithInstance:[ obj instance ] ];
		for (unsigned long q = 0; q < [ face numberOfPoints ]; q++)
		{
			MDPoint* p1 = [ face pointAtIndex:q ];
			[ p1 setNormalX:0 ];
			[ p1 setNormalY:0 ];
			[ p1 setNormalZ:0 ];
		}
		[ [ obj instance ] setupVBO ];
		
		[ undoManager setActionName:@"Normalize" ];
		[ Controller setMDInstance:face atIndex:[ instances indexOfObject:[ obj instance ] ] ];
	}
}

- (void) setupTextureWindow:(id)sender
{
	[ textureTable removeAllRows ];
	// Add all images from resources
	NSArray* meshes = [ [ [ selected fullValueAtIndex:0 ] instance ] meshes ];
	for (unsigned long z = 0; z < [ meshes count ]; z++)
	{
		MDMesh* mesh = [ meshes objectAtIndex:z ];
		for (unsigned long q = 0; q < [ mesh numberOfTextures ]; q++)
		{
			MDTexture* texture = [ mesh textureAtIndex:q ];
			NSString* type = @"Diffuse";
			if (texture.type == MD_TEXTURE_DIFFUSE)
				type = @"Diffuse";
			else if (texture.type == MD_TEXTURE_BUMP)
				type = @"Bump";
			else if (texture.type == MD_TEXTURE_TERRAIN_DIFFUSE)
				type = @"Splat Diffuse";
			else if (texture.type == MD_TEXTURE_TERRAIN_ALPHA)
				type = @"Splat Map";
			[ textureTable addRow:[ NSDictionary dictionaryWithObjectsAndKeys:[ [ texture path ] lastPathComponent ], @"Name", type, @"Type", nil ] ];
		}
	}
	[ textureTable reloadData ];
	[ self textureSelected:sender ];
}

- (IBAction) showTextures:(id)sender
{
	[ textureRemove setEnabled:NO ];
	[ self setupTextureWindow:sender ];
	[ textureWindow makeKeyAndOrderFront:self ];
}

- (IBAction) reverseWinding:(id)sender
{
	for (unsigned long z = 0; z < [ selected count ]; z++)
	{
		MDObject* obj = [ selected fullValueAtIndex:z ];
		MDInstance* face = [ [ MDInstance alloc ] initWithInstance:[ obj instance ] ];
		
		// Flips indicies
		for (unsigned long y = 0; y < [ face numberOfIndices ]; y += 3)
		{
			unsigned int i1 = [ face indexAtIndex:y ];
			unsigned int i3 = [ face indexAtIndex:y + 2 ];
			[ face setIndex:i1 atIndex:y + 2 ];
			[ face setIndex:i3 atIndex:y ];
		}
		[ face setupVBO ];
		
		[ undoManager setActionName:@"Reverse Winding" ];
		[ Controller setMDInstance:face atIndex:[ instances indexOfObject:[ obj instance ] ] ];
	}
}

- (IBAction) setHeightMap:(id)sender
{
	// Sometimes makes things upside down?
	NSOpenPanel* openPanel = [ NSOpenPanel openPanel ];
	[ openPanel setAllowedFileTypes:[ NSBitmapImageRep imageFileTypes ] ];
	if ([ openPanel runModal ])
	{
		NSBitmapImageRep* image = [ [ NSBitmapImageRep alloc ] initWithData:[ NSData dataWithContentsOfURL:[ openPanel URL ] ] ];
		BOOL done = FALSE;
		for (unsigned long q = 0; q < [ selected count ]; q++)
		{
			unsigned long counter = 0;
			MDInstance* obj = [ [ MDInstance alloc ] initWithInstance:[ [ selected fullValueAtIndex:q ] instance ] ];
			[ obj setName:[ [ [ selected fullValueAtIndex:q ] instance ] name ] ];
			NSArray* pointArray = [ obj points ];
			float numPoints = [ pointArray count ];
			
			for (unsigned long z = 0; z < [ pointArray count ]; z++)
				[ [ pointArray objectAtIndex:z ] setY:-4.98 ];
			
			if ([ pointArray count ] < 3)
				continue;
		
			for (unsigned long x = 0; x < [ image pixelsWide ]; x++)
			{
				for (unsigned long z = 0; z < [ image pixelsHigh ]; z++)
				{
					NSColor* color = [ [ image colorAtX:x y:z ] colorUsingColorSpace:[ NSColorSpace genericRGBColorSpace ] ];
					float red = [ color redComponent ], green = [ color greenComponent ], blue = [ color blueComponent ];
					float real = 1 - ((red + green + blue) / 3.0);
					float value = -4.98 + real * 20;
					[ [ pointArray objectAtIndex:counter ] setY:value ];
					
					counter++;
					
					if (counter >= numPoints)
					{
						done = TRUE;
						break;
					}
				}
				
				if (done)
					break;
			}
			
			[ obj setMidPoint:MDVector3Create(0, 0, 0) ];
			[ obj setupVBO ];
			
			[ undoManager setActionName:@"Set Heightmap" ];
			[ Controller setMDInstance:obj atIndex:[ instances indexOfObject:[ [ selected fullValueAtIndex:q ] instance ] ] ];
		}
	}
}

// Disable for now
- (IBAction) exportHeightMap:(id)sender
{
	NSSavePanel* savePanel = [ NSSavePanel savePanel ];
	[ savePanel setAllowedFileTypes:[ NSArray arrayWithObject:@"png" ] ];
	if ([ savePanel runModal ])
	{
		NSString* path = [ [ [ [ savePanel URL ] absoluteString ] substringFromIndex:7 ] stringByReplacingPercentEscapesUsingEncoding:NSASCIIStringEncoding ];
		
		MDInstance* obj = [ [ selected fullValueAtIndex:0 ] instance ];
		NSArray* pointArray = [ obj points ];
		float numPoints = [ pointArray count ];
		
		// Find out how many subdivisions (base / 6 = subdivisions)
		unsigned long base = -1;
		if ([ obj numberOfIndices ] > 5)
		{
			MDPoint* fiveP = [ pointArray objectAtIndex:[ obj indexAtIndex:5 ] ];
			for (unsigned long z = 6; z < [ pointArray count ]; z++)
			{
				MDPoint* p = [ pointArray objectAtIndex:z ];
				if (p.x == fiveP.x && p.y == fiveP.y && p.z == fiveP.z)
				{
					base = z;
					break;
				}
			}
		}
		NSSize size = NSMakeSize(numPoints / base, base);
		
		// Find highest and lowest
		float lowest = 1000000, highest = -1000000;
		for (unsigned long z = 0; z < [ pointArray count ]; z++)
		{
			MDPoint* p = [ pointArray objectAtIndex:z ];
			if (p.y < lowest)
				lowest = p.y;
			if (p.y > highest)
				highest = p.y;
		}
		 
		NSBitmapImageRep* imageRep = [ [ NSBitmapImageRep alloc ] initWithBitmapDataPlanes:NULL pixelsWide:size.width pixelsHigh:size.height bitsPerSample:8 samplesPerPixel:3 hasAlpha:NO isPlanar:NO colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:0 bitsPerPixel:0 ];
		unsigned long pCounter = 0;
		for (unsigned long x = 0; x < [ imageRep pixelsWide ]; x++)
		{
			for (unsigned long y = 0; y < [ imageRep pixelsHigh ]; y++)
			{
				MDPoint* p = [ pointArray objectAtIndex:pCounter++ ];
				float yVal = (p.y - lowest) / (highest - lowest);
				[ imageRep setColor:[ NSColor colorWithCalibratedRed:yVal green:yVal blue:yVal alpha:1 ] atX:x y:y ];
			}
		}
				
		[ [ NSFileManager defaultManager ] createFileAtPath:path contents:[ imageRep representationUsingType:NSPNGFileType properties:nil ] attributes:nil ];
	}
}

#pragma mark Animation Window

- (IBAction) showAnimationWindow:(id)sender
{
	animObj = [ selected fullValueAtIndex:0 ];
	
	// TODO: add duration to these
	
	[ animationTable removeAllRows ];
	NSArray* animations = [ [ animObj instance ] animations ];
	for (unsigned long z = 0; z < [ animations count ]; z++)
	{
		NSString* name = [ [ animations objectAtIndex:z ] name ];
		[ animationTable addRow:[ NSDictionary dictionaryWithObjectsAndKeys:name, @"Name", nil ] ];
	}
	[ animationTable reloadData ];
	
	[ animationWindow makeKeyAndOrderFront:self ];
}

- (IBAction) animationDoubleClicked:(id)sender
{
	unsigned long selRow = [ animationTable selectedRow ];
	if (selRow == -1)
		return;
	
	[ animObj playAnimation:[ animationTable selectedRowItemforColumnIdentifier:@"Name" ] ];
}

- (IBAction) animationRightClicked:(id)sender
{
}

- (IBAction) animationEdited:(id)sender
{
	NSString* newName = [ animationTable selectedRowItemforColumnIdentifier:@"Name" ];
	NSString* oldName = [ animationTable oldObject ];
	
	// Check if these names are ok
	NSArray* animations = [ [ animObj instance ] animations ];
	for (unsigned long z = 0; z < [ animations count ]; z++)
	{
		NSString* name = [ [ animations objectAtIndex:z ] name ];
		if ([ name isEqualToString:newName ] && ![ name isEqualToString:oldName ])
		{
			[ [ animationTable itemAtRow:(unsigned int)z ] setDictionary:[ NSDictionary dictionaryWithObjectsAndKeys:oldName, @"Name", nil ] ];
			NSRunAlertPanel(@"Name Already Taken", @"The name \"%@\" is already taken.", @"Ok", nil, nil, newName);
			[ animationTable reloadData ];
			return;
		}
	}
	// Otherwise update the new name
	[ (MDAnimation*)[ [ [ animObj instance ] animations ] objectAtIndex:[ animationTable selectedRow ] ] setName:newName ];
}

#pragma mark Property Window

- (IBAction) showPropertyWindow:(id)sender
{
	propObj = [ selected fullValueAtIndex:0 ];
	[ propertySetObjects setEnabled:NO ];
	if ([ sender isKindOfClass:[ NSNumber class ] ])
	{
		propObj = [ instances objectAtIndex:[ sender unsignedLongValue ] ];
		[ propertySetObjects setEnabled:YES ];
	}
	
	NSDictionary* dict = [ propObj properties ];
	NSArray* keys = [ dict allKeys ];
	[ propertyTable removeAllRows ];
	for (unsigned long z = 0; z < [ keys count ]; z++)
	{
		NSDictionary* row = [ NSDictionary dictionaryWithObjectsAndKeys:[ keys objectAtIndex:z ], @"Name", [ dict objectForKey:[ keys objectAtIndex:z ] ], @"Value", nil ];
		[ propertyTable addRow:row ];
	}
	if ([ propObj isKindOfClass:[ MDInstance class ] ])
	{
		[ propertyVisible setEnabled:NO ];
		[ propertyStatic setEnabled:NO ];
	}
	else
	{
		[ propertyVisible setState:[ propObj shouldDraw ] ];
		[ propertyVisible setEnabled:YES ];
		[ propertyStatic setState:[ propObj isStatic ] ];
		[ propertyStatic setEnabled:YES ];
	}
	
	[ propertyWindow makeKeyAndOrderFront:self ];
}

- (IBAction) addProperty:(id)sender
{
	NSDictionary* row = [ NSDictionary dictionaryWithObjectsAndKeys:@"Name", @"Name", @"Value", @"Value", nil ];
	[ propertyTable addRow:row ];
	[ self propertyEdited:nil ];
}

- (IBAction) removeProperty:(id)sender
{
	long selRow = [ propertyTable selectedRow ];
	if (selRow != -1)
	{
		[ propertyTable removeRow:(unsigned int)selRow ];
		[ self propertyEdited:nil ];
	}
}

- (IBAction) propertyEdited:(id)sender
{
	NSMutableDictionary* dict = [ NSMutableDictionary dictionary ];
	for (unsigned int z = 0; z < [ propertyTable numberOfRows ]; z++)
	{
		NSDictionary* rowDict = [ propertyTable itemAtRow:z ];
		NSDictionary* newDict = [ NSDictionary dictionaryWithObjectsAndKeys:[ rowDict objectForKey:@"Value" ], [ rowDict objectForKey:@"Name" ], nil];
		[ dict addEntriesFromDictionary:newDict ];
	}
	[ (NSMutableDictionary*)[ propObj properties ] setDictionary:dict ];
}

- (IBAction) propertySetVisible:(id)sender
{
	[ propObj setShouldDraw:[ propertyVisible state ] ];
}

- (IBAction) propertySetStatic:(id)sender
{
	[ propObj setIsStatic:[ propertyStatic state ] ];
}

- (IBAction) propertySetObjects:(id)sender
{
	for (unsigned long z = 0; z < [ objects count ];z ++)
	{
		if ([ [ [ [ objects objectAtIndex:z ] instance ] name ] isEqualToString:[ propObj name ] ])
		{
			[ (NSMutableDictionary*)[ [ objects objectAtIndex:z ] properties ] setDictionary:[ propObj properties ] ];
			[ [ objects objectAtIndex:z ] setShouldDraw:[ propObj shouldDraw ] ];
		}
	}
}

#pragma mark Physics Window

- (IBAction) showPhysicsWindow:(id)sender
{
	physicsObj = [ selected fullValueAtIndex:0 ];
	
	[ physicsTable removeAllRows ];
	NSTextFieldCell* field = [ [ NSTextFieldCell alloc ] init ];
	[ field setEditable:YES ];
	[ physicsTable addRow:[ NSDictionary dictionaryWithObjectsAndKeys:@"Mass", @"Property", [ NSString stringWithFormat:@"%f", [ physicsObj mass ] ], @"Value", nil ] ];
	[ (TableCell*)[ [ physicsTable tableColumns ] objectAtIndex:1 ] addCell:field ];
	NSSliderCell* slider = [ [ NSSliderCell alloc ] init ];
	[ slider setMaxValue:1 ];
	[ slider setMinValue:0 ];
	[ physicsTable addRow:[ NSMutableDictionary dictionaryWithObjectsAndKeys:@"Restitution", @"Property", [ NSString stringWithFormat:@"%f", [ physicsObj restitution ] ], @"Value", nil ] ];
	[ (TableCell*)[ [ physicsTable tableColumns ] objectAtIndex:1 ] addCell:slider ];
	NSTextFieldCell* field2 = [ [ NSTextFieldCell alloc ] init ];
	[ field2 setEditable:YES ];
	[ physicsTable addRow:[ NSMutableDictionary dictionaryWithObjectsAndKeys:@"Restitution (#)", @"Property", [ NSString stringWithFormat:@"%f", [ physicsObj restitution ] ], @"Value", nil ] ];
	[ (TableCell*)[ [ physicsTable tableColumns ] objectAtIndex:1 ] addCell:field2 ];
	NSPopUpButtonCell* type = [ [ NSPopUpButtonCell alloc ] init ];
	[ type addItemWithTitle:@"Exact" ];
	[ type addItemWithTitle:@"Bounding Box" ];
	[ type addItemWithTitle:@"Bounding Sphere" ];
	[ type addItemWithTitle:@"Bounding Cylinder (X Axis)" ];
	[ type addItemWithTitle:@"Bounding Cylinder (Y Axis)" ];
	[ type addItemWithTitle:@"Bounding Cylinder (Z Axis)" ];
	[ physicsTable addRow:[ NSMutableDictionary dictionaryWithObjectsAndKeys:@"Collision Type", @"Property", [ NSString stringWithFormat:@"%i", [ physicsObj physicsType ] ], @"Value", nil ] ];
	[ (TableCell*)[ [ physicsTable tableColumns ] objectAtIndex:1 ] addCell:type ];
	NSButtonCell* pos = [ [ NSButtonCell alloc ] init ];
	[ pos setButtonType:NSSwitchButton ];
	[ pos setTitle:@"" ];
	[ physicsTable addRow:[ NSMutableDictionary dictionaryWithObjectsAndKeys:@"Affect Position", @"Property", [ NSString stringWithFormat:@"%i", [ physicsObj affectPosition ] ], @"Value", nil ] ];
	[ (TableCell*)[ [ physicsTable tableColumns ] objectAtIndex:1 ] addCell:pos ];
	NSButtonCell* rot = [ [ NSButtonCell alloc ] init ];
	[ rot setButtonType:NSSwitchButton ];
	[ rot setTitle:@"" ];
	[ physicsTable addRow:[ NSMutableDictionary dictionaryWithObjectsAndKeys:@"Affect Rotation", @"Property", [ NSString stringWithFormat:@"%i", [ physicsObj affectRotation ] ], @"Value", nil ] ];
	[ (TableCell*)[ [ physicsTable tableColumns ] objectAtIndex:1 ] addCell:rot ];
	NSTextFieldCell* friction = [ [ NSTextFieldCell alloc ] init ];
	[ friction setEditable:YES ];
	[ physicsTable addRow:[ NSMutableDictionary dictionaryWithObjectsAndKeys:@"Friction", @"Property", [ NSString stringWithFormat:@"%f", [ physicsObj friction ] ], @"Value", nil ] ];
	[ (TableCell*)[ [ physicsTable tableColumns ] objectAtIndex:1 ] addCell:friction ];
	NSTextFieldCell* rfriction = [ [ NSTextFieldCell alloc ] init ];
	[ rfriction setEditable:YES ];
	[ physicsTable addRow:[ NSMutableDictionary dictionaryWithObjectsAndKeys:@"Rolling Friction", @"Property", [ NSString stringWithFormat:@"%f", [ physicsObj rollingFriction ] ], @"Value", nil ] ];
	[ (TableCell*)[ [ physicsTable tableColumns ] objectAtIndex:1 ] addCell:rfriction ];
	
	[ physicsTable reloadData ];
	
	[ physicsWindow makeKeyAndOrderFront:self ];
}

- (void) physicsTableEdited:(id)sender
{
	if ([ sender unsignedLongValue ] >= [ physicsTable numberOfRows ])
		return;
	
	id cell = [ [ physicsTable itemAtRow:[ sender unsignedIntValue ] ] objectForKey:@"Value" ];
	if ([ sender intValue ] == 0)
		[ physicsObj setMass:[ cell floatValue ] ];
	else if ([ sender intValue ] == 1 || [ sender intValue ] == 2)
	{
		float realValue = [ cell floatValue ];
		if (realValue > 1)
			realValue = 1;
		if (realValue < 0)
			realValue = 0;
		[ physicsObj setRestitution:realValue ];
		[ [ physicsTable itemAtRow:1 ] setObject:[ NSString stringWithFormat:@"%f", [ physicsObj restitution ] ] forKey:@"Value" ];
		[ [ physicsTable itemAtRow:2 ] setObject:[ NSString stringWithFormat:@"%f", [ physicsObj restitution ] ] forKey:@"Value" ];
	}
	else if ([ sender intValue ] == 3)
		[ physicsObj setPhysicsType:[ cell intValue ] ];
	else if ([ sender intValue ] == 4)
	{
		[ physicsObj setAffectPosition:[ cell intValue ] ];
		[ [ physicsTable itemAtRow:4 ] setObject:[ NSString stringWithFormat:@"%i", [ cell intValue ] ] forKey:@"Value" ];
	}
	else if ([ sender intValue ] == 5)
	{
		[ physicsObj setAffectRotation:[ cell intValue ] ];
		[ [ physicsTable itemAtRow:5 ] setObject:[ NSString stringWithFormat:@"%i", [ cell intValue ] ] forKey:@"Value" ];
	}
	else if ([ sender intValue ] == 6)
		[ physicsObj setFriction:[ cell floatValue ] ];
	else if ([ sender intValue ] == 7)
		[ physicsObj setRollingFriction:[ cell floatValue ] ];
}

#pragma mark Textures

- (void) resetTextureWindow
{
	[ addTextureDiffuseImage setStringValue:@"" ];
	[ addTextureBumpImage setStringValue:@"" ];
}

- (IBAction) addTextures:(id)sender
{
	// Reset all the stuff
	[ self resetTextureWindow ];
	
	[ addTextureWindow makeKeyAndOrderFront:self ];
	[ textureWindow orderOut:self ];
}

- (IBAction) editTexture:(id)sender
{
	if ([ textureTable selectedRow ] == -1)
		return;
	
	// Reset all the stuff
	[ self resetTextureWindow ];
	
	// Set all the stuff
	isEditingTexture = TRUE;
	NSString* path = [ textureTable selectedRowItemforColumnIdentifier:@"Name" ];
	NSString* type = [ textureTable selectedRowItemforColumnIdentifier:@"Type" ];
	if ([ type isEqualToString:@"Diffuse" ])
	{
		[ addTextureDiffuseImage setStringValue:path ];
		[ addTextureTab selectTabViewItemAtIndex:0 ];
	}
	else if ([ type isEqualToString:@"Bump" ])
	{
		[ addTextureBumpImage setStringValue:path ];
		[ addTextureTab selectTabViewItemAtIndex:1 ];
	}
	else if ([ type isEqualToString:@"Splat Map" ])
	{
		[ addTextureMapImage setStringValue:path ];
		
		// Find Position
		MDTexture* tex1 = nil, *tex2 = nil, *tex3 = nil;
		unsigned long sel = [ textureTable selectedRow ];
		NSArray* meshes = [ [ [ selected fullValueAtIndex:0 ] instance ] meshes ];
		for (unsigned long z = 0; z < [ meshes count ]; z++)
		{
			MDMesh* mesh = [ meshes objectAtIndex:z ];
			if (sel < [ mesh numberOfTextures ])
			{
				tex1 = [ mesh textureAtIndex:sel + 1 ];
				tex2 = [ mesh textureAtIndex:sel + 2 ];
				tex3 = [ mesh textureAtIndex:sel + 3 ];
				break;
			}
			sel -= [ mesh numberOfTextures ];
		}
		
		// Set textures
		[ addTextureTex1Image setStringValue:[ [ tex1 path ] lastPathComponent ] ];
		[ addTextureTex1Scale setFloatValue:[ tex1 size ] ];
		
		[ addTextureTex2Image setStringValue:[ [ tex2 path ] lastPathComponent ] ];
		[ addTextureTex2Scale setFloatValue:[ tex2 size ] ];
		
		[ addTextureTex3Image setStringValue:[ [ tex3 path ] lastPathComponent ] ];
		[ addTextureTex3Scale setFloatValue:[ tex3 size ] ];
		
		[ addTextureTab selectTabViewItemAtIndex:2 ];
	}
	else if ([ type isEqualToString:@"Splat Diffuse" ])		// Select the head row and open
	{
		unsigned long sel = [ textureTable selectedRow ];
		unsigned long totalSel = 0;
		NSArray* meshes = [ [ [ selected fullValueAtIndex:0 ] instance ] meshes ];
		for (unsigned long z = 0; z < [ meshes count ]; z++)
		{
			MDMesh* mesh = [ meshes objectAtIndex:z ];
			if (sel < [ mesh numberOfTextures ])
			{
				unsigned newHead = [ [ mesh textureAtIndex:sel ] head ];
				if (newHead == -1)
					return;
				[ textureTable selectRowIndexes:[ NSIndexSet indexSetWithIndex:newHead + totalSel ] byExtendingSelection:NO ];
				[ self editTexture:self ];
				break;
			}
			sel -= [ mesh numberOfTextures ];
			totalSel += [ mesh numberOfTextures ];
		}
		return;
	}
	
	[ addTextureWindow makeKeyAndOrderFront:self ];
	[ textureWindow orderOut:self ];
}

- (BOOL) removeHead:(MDTexture*)texture withNumber:(unsigned long)t withHead:(unsigned int)sel
{
	if ([ texture type ] == MD_TEXTURE_TERRAIN_ALPHA)
	{
		// Find all other things with this as head
		NSArray* meshes = [ [ [ selected fullValueAtIndex:0 ] instance ] meshes ];
		unsigned long startNumber = 0;
		unsigned long foundY = -1;
		for (unsigned long z = 0; z < [ meshes count ]; z++)
		{
			startNumber += [ [ meshes objectAtIndex:z ] numberOfTextures ];
			if (z != t)
				continue;
			
			MDMesh* mesh = [ meshes objectAtIndex:z ];
			startNumber -= [ mesh numberOfTextures ];

			for (unsigned long y = 0; y < [ mesh numberOfTextures ]; y++)
			{
				MDTexture* text = [ mesh textureAtIndex:y ];
				if ([ text head ] == sel)
				{
					foundY = y;
					break;
				}
			}
			
			if (foundY != -1)
				break;
		}
		
		foundY += startNumber;
		removingHead = TRUE;
		[ textureTable selectRowIndexes:[ NSIndexSet indexSetWithIndex:foundY + 2 ] byExtendingSelection:NO ];
		[ self removeTexture:self ];
		[ textureTable selectRowIndexes:[ NSIndexSet indexSetWithIndex:foundY + 1 ] byExtendingSelection:NO ];
		[ self removeTexture:self ];
		[ textureTable selectRowIndexes:[ NSIndexSet indexSetWithIndex:foundY ] byExtendingSelection:NO ];
		[ self removeTexture:self ];
		[ textureTable selectRowIndexes:[ NSIndexSet indexSetWithIndex:foundY - 1 ] byExtendingSelection:NO ];
		[ self removeTexture:self ];
		removingHead = FALSE;
		
		return TRUE;
	}
	else if ([ texture type ] == MD_TEXTURE_TERRAIN_DIFFUSE)
	{
		unsigned int newHead = [ texture head ];
		if (newHead == -1)
			return FALSE;
		
		NSArray* meshes = [ [ [ selected fullValueAtIndex:0 ] instance ] meshes ];
		MDMesh* mesh = [ meshes objectAtIndex:t ];
		MDTexture* headTexture = [ mesh textureAtIndex:newHead ];
		[ self removeHead:headTexture withNumber:t withHead:newHead ];
		return TRUE;
	}
	
	return FALSE;
}

- (IBAction) removeTexture:(id)sender
{
	BOOL should = sender == self;
	if (!should)
		should = NSRunAlertPanel(@"Confirm", @"Are you sure you want to remove this texutre? This cannot be undone.", @"No", @"Yes", nil) == NSAlertAlternateReturn;
	if (should)
	{
		unsigned long sel = [ textureTable selectedRow ];
		if (sel != -1)
		{
			NSArray* meshes = [ [ [ selected fullValueAtIndex:0 ] instance ] meshes ];
			for (unsigned long z = 0; z < [ meshes count ]; z++)
			{
				MDMesh* mesh = [ meshes objectAtIndex:z ];
				if (sel < [ mesh numberOfTextures ])
				{
					MDTexture* texture = [ mesh textureAtIndex:sel ];
					if (!removingHead)
					{
						BOOL quit = [ self removeHead:texture withNumber:z withHead:(unsigned int)sel ];
						if (quit)
							return;
					}
					unsigned int tex = [ texture texture ];
					if (tex != 0)
					{
						BOOL noOther = TRUE;
						for (unsigned long t = 0; t < [ objects count ]; t++)
						{
							MDInstance* face2 = [ [ objects objectAtIndex:t ] instance ];
							for (unsigned long p = 0; p < [ face2 numberOfMeshes ]; p++)
							{
								for (unsigned long i = 0; i < [ [ face2 meshAtIndex:p ] numberOfTextures ]; i++)
								{
									if (i == sel && p == z && face2 == [ [ selected fullValueAtIndex:0 ] instance ])
										continue;
									
									if ([ [ [ face2 meshAtIndex:p ] textureAtIndex:i ] texture ] == tex)
									{
										noOther = FALSE;
										break;
									}
								}
								if (!noOther)
									break;
							}
							if (!noOther)
								break;
						}
						if (noOther)
						{
							ReleaseImage(&tex);
							for (int z = 0; z < loadedImages.size(); z++)
							{
								if (loadedImages[z].textNum == tex)
								{
									loadedImages.erase(loadedImages.begin() + z);
									break;
								}
							}
						}
					}
					[ [ mesh textures ] removeObjectAtIndex:sel ];
					
					break;
				}
				unsigned long prevSel = sel;
				sel -= [ mesh numberOfTextures ];
				if (sel > prevSel) // Underflow
					break;
			}
			[ textureTable removeRow:[ textureTable selectedRow ] ];
			[ textureTable reloadData ];
			[ self textureSelected:self ];
		}
	}
}

- (IBAction) textureSelected:(id)sender
{
	if ([ textureTable selectedRow ] == -1)
		[ textureRemove setEnabled:NO ];
	else
		[ textureRemove setEnabled:YES ];
	NSString* path = [ NSString stringWithFormat:@"%@%@/Resources/%@", workingDirectory, [ workingDirectory lastPathComponent ], [ textureTable selectedRowItemforColumnIdentifier:@"Name" ] ];
	[ texturePreview setImage:[ [ NSImage alloc ] initWithContentsOfFile:path ] ];
}

- (void) finishCheckTextures:(NSString*) path withType:(MDTextureType)type withHead:(unsigned long)head withSize:(float)size
{
	if (currentMode == MD_OBJECT_MODE)
	{
		for (unsigned long z = 0; z < [ selected count ]; z++)
		{
			MDInstance* face = [ [ [ selected selectedValueAtIndex:z ] objectForKey:@"Object" ] instance ];
			NSString* texturePath = [ NSString stringWithFormat:@"%@%@/Resources/%@", workingDirectory, [ workingDirectory lastPathComponent ], path ];
			for (unsigned long y = 0; y < [ face numberOfMeshes ]; y++)
			{
				MDMesh* mesh = [ face meshAtIndex:y ];
				MDTexture* texture = [ [ MDTexture alloc ] init ];
				[ texture setPath:texturePath ];
				[ texture setType:type ];
				if (head == -2)
				{
					[ texture setHead:-1 ];
					// Find last alpha map
					for (long t = [ mesh numberOfTextures ] - 1; t >= 0; t--)
					{
						if ([ [ mesh textureAtIndex:t ] type ] == MD_TEXTURE_TERRAIN_ALPHA)
						{
							[ texture setHead:(unsigned int)t ];
							break;
						}
					}
				}
				else
					[ texture setHead:(unsigned int)head ];
				[ texture setSize:size ];
				[ [ mesh textures ] addObject:texture ];
			}
		}
		
		[ [ glWindow glView ] loadNewTextures ];
	}
	else if (currentMode == MD_FACE_MODE)
	{
	/*	for (unsigned long z = 0; z < [ selected count ]; z++)
		{
			MDFace* face = [ selected fullValueAtIndex:z ];
			[ face addProperty:[ NSString stringWithFormat:@"%@%@/Resources/%@", workingDirectory, [ workingDirectory lastPathComponent ], [ textureTable selectedRowItemforColumnIdentifier:@"Name" ] ] forKey:@"Texture" ];
			unsigned int tex = [ [ [ face properties ] objectForKey:@"Texture Number" ] intValue ];
			if (tex != 0)
			{
				BOOL noOther = TRUE;
				for (unsigned int y = 0; y < [ objects count ]; y++)
				{
					for (unsigned int x = 0; x < [ [ objects objectAtIndex:y ] numberOfFaces ]; x++)
					{
						MDFace* face2 = [ [ objects objectAtIndex:y ] faceAtIndex:x ];
						if ([ [ [ face2 properties ] objectForKey:@"Texture Number" ] intValue ] == tex)
						{
							noOther = FALSE;
							break;
						}
					}
				}
				if (noOther)
				{
					ReleaseImage(&tex);
					for (int z = 0; z < loadedImages.size(); z++)
					{
						if (loadedImages[z].textNum == tex)
						{
							if (loadedImages[z].path)
							{
								[ loadedImages[z].path release ];
								loadedImages[z].path = nil;
							}
							loadedImages.erase(loadedImages.begin() + z);
							break;
						}
					}
				}
			}
			[ [ face properties ] removeObjectForKey:@"Texture Number" ];
			if ([ textureTable selectedRowItemforColumnIdentifier:@"Name" ] == nil)
				[ [ face properties ] removeObjectForKey:@"Texture" ];
		}*/
		
		[ [ glWindow glView ] loadNewTextures ];
	}
}

- (void) setupTextureResources
{
	[ textureResources removeAllRows ];
	// Add all images from resources
	NSArray* nodes = [ [ [ [ fileOutline rootNode ] childAtIndex:0 ] childWithTitle:@"Resources" ] children ];
	for (int z = 0; z < [ nodes count ]; z++)
	{
		NSArray* types = [ NSImage imageFileTypes ];
		for (int y = 0; y < [ types count ]; y++)
		{
			if ([ [ [ nodes objectAtIndex:z ] title ] hasSuffix:[ NSString stringWithFormat:@".%@",[ types objectAtIndex:y ] ] ])
			{
				NSImage* image = [ [ NSImage alloc ] initWithContentsOfFile:[ NSString stringWithFormat:@"%@%@/Resources/%@", workingDirectory, [ workingDirectory lastPathComponent ], [ [ nodes objectAtIndex:z ] title ] ] ];
				[ textureResources addRow:[ NSDictionary dictionaryWithObjectsAndKeys:[ [ nodes objectAtIndex:z ] title ], @"Name", image, @"Preview", nil ] ];
			}
		}
	}
	[ textureResources reloadData ];
}

- (void) selectTextureResource:(NSString*)path
{
	if ([ path length ] == 0)
		return;
	
	for (unsigned long z = 0; z < [ textureResources numberOfRows ]; z++)
	{
		NSString* path2 = [ [ textureResources itemAtRow:(unsigned int)z ] objectForKey:@"Name" ];
		if ([ path isEqualToString:path2 ])
		{
			[ textureResources selectRowIndexes:[ NSIndexSet indexSetWithIndex:z ] byExtendingSelection:NO ];
			break;
		}
	}
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
{
	[ sheet orderOut:self ];
}

- (IBAction) selectDiffuseTexture:(id)sender
{
	[ self setupTextureResources ];
	destinationTextureImage = addTextureDiffuseImage;
	// Select this one
	[ self selectTextureResource:[ destinationTextureImage stringValue ] ];
	[ NSApp beginSheet:textureResourcesWindow modalForWindow:addTextureWindow modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil ];
}

- (IBAction) selectBumpTexture:(id)sender
{
	[ self setupTextureResources ];
	destinationTextureImage = addTextureBumpImage;
	// Select this one
	[ self selectTextureResource:[ destinationTextureImage stringValue ] ];
	[ NSApp beginSheet:textureResourcesWindow modalForWindow:addTextureWindow modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil ];
}

- (IBAction) selectMapTexture:(id)sender
{
	[ self setupTextureResources ];
	destinationTextureImage = addTextureMapImage;
	// Select this one
	[ self selectTextureResource:[ destinationTextureImage stringValue ] ];
	[ NSApp beginSheet:textureResourcesWindow modalForWindow:addTextureWindow modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil ];
}

- (IBAction) selectTex1Texture:(id)sender
{
	[ self setupTextureResources ];
	destinationTextureImage = addTextureTex1Image;
	// Select this one
	[ self selectTextureResource:[ destinationTextureImage stringValue ] ];
	[ NSApp beginSheet:textureResourcesWindow modalForWindow:addTextureWindow modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil ];
}

- (IBAction) selectTex2Texture:(id)sender
{
	[ self setupTextureResources ];
	destinationTextureImage = addTextureTex2Image;
	// Select this one
	[ self selectTextureResource:[ destinationTextureImage stringValue ] ];
	[ NSApp beginSheet:textureResourcesWindow modalForWindow:addTextureWindow modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil ];
}

- (IBAction) selectTex3Texture:(id)sender
{
	[ self setupTextureResources ];
	destinationTextureImage = addTextureTex3Image;
	// Select this one
	[ self selectTextureResource:[ destinationTextureImage stringValue ] ];
	[ NSApp beginSheet:textureResourcesWindow modalForWindow:addTextureWindow modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil ];
}

- (IBAction) cancelAddTexture:(id)sender
{
	isEditingTexture = FALSE;
	[ addTextureWindow orderOut:self ];
	[ textureWindow makeKeyAndOrderFront:self ];
}

- (IBAction) finishAddTexture:(id)sender
{
	// Prerequisites
	if ([ [ [ addTextureTab selectedTabViewItem ] identifier ] isEqualToString:@"Diffuse" ])
	{
		if ([ [ addTextureDiffuseImage stringValue ] length ] == 0)
		{
			NSRunAlertPanel(@"Error", @"Texture image cannot be blank.", @"Ok", nil, nil);
			return;
		}
	}
	else if ([ [ [ addTextureTab selectedTabViewItem ] identifier ] isEqualToString:@"Bump" ])
	{
		if ([ [ addTextureBumpImage stringValue ] length ] == 0)
		{
			NSRunAlertPanel(@"Error", @"Texture image cannot be blank.", @"Ok", nil, nil);
			return;
		}
	}
	else if ([ [ [ addTextureTab selectedTabViewItem ] identifier ] isEqualToString:@"Splatting" ])
	{
		if ([ [ addTextureMapImage stringValue ] length ] == 0)
		{
			NSRunAlertPanel(@"Error", @"Texture map image cannot be blank.", @"Ok", nil, nil);
			return;
		}
		else if ([ [ addTextureTex1Image stringValue ] length ] == 0 && [ [ addTextureTex2Image stringValue ] length ] == 0 && [ [ addTextureTex3Image stringValue ] length ] == 0)
		{
			NSRunAlertPanel(@"Error", @"At least one texture image must be supplied.", @"Ok", nil, nil);
			return;
		}
	}
	
	// Remove editing texture
	if (isEditingTexture)
		[ self removeTexture:self ];
	
	// Add Texture
	if ([ [ [ addTextureTab selectedTabViewItem ] identifier ] isEqualToString:@"Diffuse" ])
	{
		[ self finishCheckTextures:[ addTextureDiffuseImage stringValue ] withType:MD_TEXTURE_DIFFUSE withHead:-1 withSize:1 ];
		[ self setupTextureWindow:self ];
		[ textureTable selectRowIndexes:[ NSIndexSet indexSetWithIndex:[ textureTable numberOfRows ] - 1 ] byExtendingSelection:NO ];
		[ self textureSelected:self ];
	}
	else if ([ [ [ addTextureTab selectedTabViewItem ] identifier ] isEqualToString:@"Bump" ])
	{
		[ self finishCheckTextures:[ addTextureBumpImage stringValue ] withType:MD_TEXTURE_BUMP withHead:-1 withSize:1 ];
		[ self setupTextureWindow:self ];
		[ textureTable selectRowIndexes:[ NSIndexSet indexSetWithIndex:[ textureTable numberOfRows ] - 1 ] byExtendingSelection:NO ];
		[ self textureSelected:self ];
	}
	else if ([ [ [ addTextureTab selectedTabViewItem ] identifier ] isEqualToString:@"Splatting" ])
	{
		[ self finishCheckTextures:[ addTextureMapImage stringValue ] withType:MD_TEXTURE_TERRAIN_ALPHA withHead:-1 withSize:1 ];
		[ self finishCheckTextures:[ addTextureTex1Image stringValue ] withType:MD_TEXTURE_TERRAIN_DIFFUSE withHead:-2 withSize:[ addTextureTex1Scale floatValue ] ];
		[ self finishCheckTextures:[ addTextureTex2Image stringValue ] withType:MD_TEXTURE_TERRAIN_DIFFUSE withHead:-2 withSize:[ addTextureTex2Scale floatValue ] ];
		[ self finishCheckTextures:[ addTextureTex3Image stringValue ] withType:MD_TEXTURE_TERRAIN_DIFFUSE withHead:-2 withSize:[ addTextureTex3Scale floatValue ] ];
		[ self setupTextureWindow:self ];
		[ textureTable selectRowIndexes:[ NSIndexSet indexSetWithIndex:[ textureTable numberOfRows ] - 1 ] byExtendingSelection:NO ];
		[ self textureSelected:self ];
	}
	
	// Close the window
	[ self cancelAddTexture:sender ];
}

- (void) addTextureResources:(id)sender
{
	NSOpenPanel* panel = [ NSOpenPanel openPanel ];
	[ panel setAllowsMultipleSelection:YES ];
	[ panel setAllowedFileTypes:[ NSImage imageFileTypes ] ];
	if ([ panel runModal ])
	{
		senderNode = [ [ [ fileOutline rootNode ] childAtIndex:0 ] childWithTitle:@"Resources" ];
		NSArray* array = [ panel URLs ];
		for (int z = 0; z < [ array count ]; z++)
		{
			NSURL* working = [ NSURL fileURLWithPath:[ NSString stringWithFormat:@"%@%@%@/%@", workingDirectory, [ senderNode parentsPath ], [ senderNode title ], [ [ [ [ array objectAtIndex:z ] relativeString ] lastPathComponent ] stringByReplacingPercentEscapesUsingEncoding:NSASCIIStringEncoding ] ] ];
			[ [ NSFileManager defaultManager ] copyItemAtURL:[ array objectAtIndex:z ] toURL:working error:nil ];
			IFNode* node = [ [ IFNode alloc ] initLeafWithTitle:[ [ [ [ array objectAtIndex:z ] relativeString ] lastPathComponent ] stringByReplacingPercentEscapesUsingEncoding:NSASCIIStringEncoding ] ];
			[ senderNode addChild:node ];
		}
		[ fileOutline reloadData ];
		[ self save:sender ];
		
		[ self setupTextureResources ];
	}
}

- (void) removeTextureResource:(id)sender
{
	NSString* sel = [ NSString stringWithString:[ textureResources selectedRowItemforColumnIdentifier:@"Name" ] ];
	long z = NSRunAlertPanel(@"Confirm", @"Do you want to remove this texture from the project or delete it?", @"Cancel", @"Remove", @"Delete");
	if (z != NSAlertDefaultReturn)
	{
		// Resources
		senderNode = [ [ [ [ fileOutline rootNode ] childAtIndex:0 ] childWithTitle:@"Resources" ] childWithTitle:[ textureResources selectedRowItemforColumnIdentifier:@"Name" ] ];
		[ [ senderNode parentItem ] removeChild:senderNode ];
		[ fileOutline reloadData ];
		[ self save:self ];
		
		[ self setupTextureResources ];
	}
	if (z == NSAlertOtherReturn)
	{
		// Trash
		NSString* str = [ NSString stringWithFormat:@"%@%@/Resources/%@", workingDirectory, [ workingDirectory lastPathComponent ], sel ];
		[ [ NSFileManager defaultManager ] removeItemAtPath:str error:nil ];
	}
}

- (void) textureResourcesRight
{
	NSMenu* menu = [ [ NSMenu alloc ] init ];
	[ menu addItemWithTitle:@"Add Textures" action:@selector(addTextureResources:) keyEquivalent:@"" ];
	if ([ textureResources selectedRow ] != -1)
		[ menu addItemWithTitle:@"Remove Texture" action:@selector(removeTextureResource:) keyEquivalent:@"" ];
	[ NSMenu popUpContextMenu:menu withEvent:[ textureResources rightEvent] forView:textureResources ];
}

- (IBAction) selectTextureImage:(id)sender
{
	[ destinationTextureImage setStringValue:[ textureResources selectedRowItemforColumnIdentifier:@"Name" ] ];
	[ NSApp endSheet:textureResourcesWindow ];
}

- (IBAction) cancelTextureImage:(id)sender
{
	[ NSApp endSheet:textureResourcesWindow ];
}

#pragma mark Skybox

- (IBAction) showSkybox:(id)sender
{
	[ skyboxDistance setFloatValue:[ [ sceneProperties objectForKey:@"Skybox Distance" ] floatValue ] ];
	[ skyboxRed setFloatValue:[ [ sceneProperties objectForKey:@"Skybox Color" ] redComponent ] ];
	[ skyboxGreen setFloatValue:[ [ sceneProperties objectForKey:@"Skybox Color" ] greenComponent ] ];
	[ skyboxBlue setFloatValue:[ [ sceneProperties objectForKey:@"Skybox Color" ] blueComponent ] ];
	[ skyboxAlpha setFloatValue:[ [ sceneProperties objectForKey:@"Skybox Color" ] alphaComponent ] ];
	[ skyboxCorrection setFloatValue:[ [ sceneProperties objectForKey:@"Skybox Correction" ] floatValue ] ];
	[ skyboxVisible setState:[ [ sceneProperties objectForKey:@"Skybox Visible" ] boolValue ] ];
	
	[ skyboxTable removeAllRows ];
	// Add all images from resources
	NSArray* nodes = [ [ [ [ fileOutline rootNode ] childAtIndex:0 ] childWithTitle:@"Resources" ] children ];
	for (int z = 0; z < [ nodes count ]; z++)
	{
		NSArray* types = [ NSImage imageFileTypes ];
		for (int y = 0; y < [ types count ]; y++)
		{
			if ([ [ [ nodes objectAtIndex:z ] title ] hasSuffix:[ NSString stringWithFormat:@".%@",[ types objectAtIndex:y ] ] ])
			{
				[ skyboxTable addRow:[ NSDictionary dictionaryWithObject:[ [ nodes objectAtIndex:z ] title ] forKey:@"Name" ] ];
				if ([[ [ nodes objectAtIndex:z ] title ] isEqualToString:[ sceneProperties objectForKey:@"Skybox Texture Path" ] ])
					[ skyboxTable selectRowIndexes:[ NSIndexSet indexSetWithIndex:[ skyboxTable numberOfRows ] - 1 ] byExtendingSelection:NO ];
			}
		}
	}
	[ skyboxTable reloadData ];
	
	[ skyboxWindow makeKeyAndOrderFront:self ];
}

- (void) skyboxColorChosen:(id)sender
{
	NSColorPanel* panel = [ NSColorPanel sharedColorPanel ];
	NSColor* color = [ [ panel color ] colorUsingColorSpace:[ NSColorSpace genericRGBColorSpace ] ];
	[ skyboxRed setFloatValue:[ color redComponent ] ];
	[ skyboxGreen setFloatValue:[ color greenComponent ] ];
	[ skyboxBlue setFloatValue:[ color blueComponent ] ];
	[ skyboxAlpha setFloatValue:[ color alphaComponent ] ];
}

- (IBAction) chooseSkyboxColor:(id)sender
{
	[ [ NSColorPanel sharedColorPanel ] setTarget:self ];
	[ [ NSColorPanel sharedColorPanel ] setAction:@selector(skyboxColorChosen:) ];
	[ [ NSColorPanel sharedColorPanel ] makeKeyAndOrderFront:self ];
}

- (IBAction) okSkybox:(id)sender
{
	[ sceneProperties setObject:[ NSNumber numberWithFloat:[ skyboxDistance floatValue ] ] forKey:@"Skybox Distance" ];
	[ sceneProperties setObject:[ NSColor colorWithCalibratedRed:[ skyboxRed floatValue ] green:[ skyboxGreen floatValue ] blue:[ skyboxBlue floatValue ] alpha:[ skyboxAlpha floatValue ] ] forKey:@"Skybox Color" ];
	[ sceneProperties setObject:[ NSNumber numberWithFloat:[ skyboxCorrection floatValue ] ] forKey:@"Skybox Correction" ];
	[ sceneProperties setObject:[ NSNumber numberWithBool:[ skyboxVisible state ] ] forKey:@"Skybox Visible" ];
	NSString* texPath = [ skyboxTable selectedRowItemforColumnIdentifier:@"Name" ];
	if (!texPath)
		texPath = @"";
	[ sceneProperties setObject:[ NSString stringWithString:texPath ] forKey:@"Skybox Texture Path" ];
	unsigned int texture = [ [ sceneProperties objectForKey:@"Skybox Texture" ] unsignedIntValue ];
	if (texture != 0)
		ReleaseImage(&texture);
	if ([ texPath length ] != 0)
	{
		LoadImage([ [ NSString stringWithFormat:@"%@%@/Resources/%@", workingDirectory, [ workingDirectory lastPathComponent ], [ skyboxTable selectedRowItemforColumnIdentifier:@"Name" ] ] UTF8String ], &texture, 0);
		[ sceneProperties setObject:[ NSNumber numberWithUnsignedInt:texture ] forKey:@"Skybox Texture" ];
	}
	else
		[ sceneProperties setObject:[ NSNumber numberWithUnsignedInt:0 ] forKey:@"Skybox Texture" ];
	
	[ [ glWindow glView ] updateSkybox ];
	[ skyboxWindow orderOut:self ];
}

- (IBAction) cancelSkybox:(id)sender
{
	[ skyboxWindow orderOut:self ];
}

#pragma mark Lightmaps

- (void) createLightmaps: (NSDictionary*) data
{
	[ lightmapGenerateButton setEnabled:NO ];
	
	NSSize res = NSMakeSize([ lightmapResolutionX intValue ], [ lightmapResolutionY intValue ]);
	
	@autoreleasepool {
		NSMutableArray* objs = [ data objectForKey:@"Objects" ];
		NSMutableArray* insts = [ data objectForKey:@"Instances" ];
		NSMutableArray* otherObjs = [ data objectForKey:@"Other" ];
		
		MDGenerateLightmaps(objs, insts, otherObjs, workingDirectory, currentScene, res, lightmapProgress, lightmapInfo);
		
		[ objs removeAllObjects ];
		[ insts removeAllObjects ];
		[ otherObjs removeAllObjects ];
	}
	
	[ lightmapGenerateButton setEnabled:YES ];
}

- (IBAction) generateLightmap:(id)sender
{
	if ([ lightmapCurrentScene state ])
	{
		// Create a copy of objects and other objects
		NSMutableArray* objs = [ [ NSMutableArray alloc ] init ];
		for (unsigned long z = 0; z < [ objects count ]; z++)
		{
			MDObject* object = [ [ MDObject alloc ] initWithObject:[ objects objectAtIndex:z ] ];
			[ objs addObject:object ];
		}
		NSMutableArray* insts = [ [ NSMutableArray alloc ] init ];
		for (unsigned long z = 0; z < [ instances count ]; z++)
		{
			MDInstance* instance = [ [ MDInstance alloc ] initWithInstance:[ instances objectAtIndex:z ] ];
			[ instance setName:[ [ instances objectAtIndex:z ] name ] ];
			for (unsigned long y = 0; y < [ objs count ]; y++)
			{
				MDObject* obj = [ objs objectAtIndex:y ];
				if ([ obj instance ] == [ instances objectAtIndex:z ])
					[ obj setInstance:instance ];
			}
			[ insts addObject:instance ];
		}
		NSMutableArray* otherObjs = [ [ NSMutableArray alloc ] init ];
		for (unsigned long z = 0; z < [ otherObjects count ]; z++)
		{
			// Only lights are important
			id light = [ otherObjects objectAtIndex:z ];
			if (![ light isKindOfClass:[ MDLight class ] ])
				continue;
			MDLight* light2 = [ [ MDLight alloc ] initWithMDLight:light ];
			[ otherObjs addObject:light2 ];
		}
		NSDictionary* dictionary = [ [ NSDictionary alloc ] initWithObjectsAndKeys:objs, @"Objects", insts, @"Instances", otherObjs, @"Other", nil ];
		
		[ NSThread detachNewThreadSelector:@selector(createLightmaps:) toTarget:self withObject:dictionary ];
	}
}

#pragma mark Timer

- (void) updateBeforeGLView
{
	if (commandFlag & CLEAR_LENGTHS)
	{
		NSOpenGLContext* currentContext = [ NSOpenGLContext currentContext ];
		if (loadingContext)
			[ loadingContext makeCurrentContext	];
		for (unsigned long z = 0; z < lengthTexts.size(); z++)
		{
			unsigned int* image = &lengthTexts[z];
			if (glIsTexture(*image))
				glDeleteTextures(1, image);
		}
		if (loadingContext)
			[ currentContext makeCurrentContext ];
		lengthTexts.clear();
		commandFlag &= ~CLEAR_LENGTHS;
	}
}

- (void) clearOther
{
	[ [ [ infoTable rootNode ] childWithTitle:@"Midpoint" ] setVisible:NO ];
	[ [ [ infoTable rootNode ] childWithTitle:@"Lookpoint" ] setVisible:NO ];
	[ [ [ infoTable rootNode ] childWithTitle:@"Orientation" ] setVisible:NO ];
	[ [ [ infoTable rootNode ] childWithTitle:@"Colors" ] setVisible:NO ];
	[ [ [ infoTable rootNode ] childWithTitle:@"Spot" ] setVisible:NO ];
	[ [ [ infoTable rootNode ] childWithTitle:@"Attenuation" ] setVisible:NO ];
	[ [ [ infoTable rootNode ] childWithTitle:@"Shadows" ] setVisible:NO ];
	[ [ [ infoTable rootNode ] childWithTitle:@"Particle Colors" ] setVisible:NO ];
	[ [ [ infoTable rootNode ] childWithTitle:@"Velocities" ] setVisible:NO ];
	[ [ [ infoTable rootNode ] childWithTitle:@"Particle Number" ] setVisible:NO ];
	[ [ [ infoTable rootNode ] childWithTitle:@"Particle Size" ] setVisible:NO ];
	[ [ [ infoTable rootNode ] childWithTitle:@"Particle Life" ] setVisible:NO ];
	[ [ [ infoTable rootNode ] childWithTitle:@"Particle Slices" ] setVisible:NO ];
	[ [ [ infoTable rootNode ] childWithTitle:@"Point Number" ] setVisible:NO ];
	[ [ [ infoTable rootNode ] childWithTitle:@"Points" ] setVisible:NO ];
	[ [ [ infoTable rootNode ] childWithTitle:@"Visible" ] setVisible:NO ];
	[ [ [ infoTable rootNode ] childWithTitle:@"Use" ] setVisible:NO ];
}

- (void) updateGLView
{
	[ infoTable setEditing:NO ];
	[ infoTable setEditing:NO ];
	
	if (commandFlag & UPDATE_INFO)
	{
		[ self clearOther ];
		
		if ([ selected count ] == 1)
		{
			MDObject* obj = [ [ selected selectedValueAtIndex:0 ] objectForKey:@"Object" ];
			IFNode* general = [ [ infoTable rootNode ] childWithTitle:@"General Attributes" ];
			[ general setVisible:YES ];
			
			// Select it in the library
			[ libraryOutline selectNode:[ [ [ libraryOutline rootNode ] childWithTitle:[ [ obj instance ] name ] ] childWithTitle:[ obj name ] ] ];
			
			// Remove points
			for (unsigned long z = 0; ; z++)
			{
				IFNode* node = [ general childWithTitle:[ NSString stringWithFormat:@"Point %lu", z + 1 ] ];
				if (node)
					[ general removeChild:node ];
				else
					break;
			}
			
			if (currentMode == MD_OBJECT_MODE)
			{
				[ general setVisible:YES ];
				IFNode* translate = [ general childWithTitle:@"Translation" ];
				[ translate	setVisible:YES ];
				IFNode* translateX = [ translate childWithTitle:@"Translate X" ];
				[ translateX setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", obj.translateX ] forKey:@"Value" ] ];
				IFNode* translateY = [ translate childWithTitle:@"Translate Y" ];
				[ translateY setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", obj.translateY ] forKey:@"Value" ] ];
				IFNode* translateZ = [ translate childWithTitle:@"Translate Z" ];
				[ translateZ setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", obj.translateZ ] forKey:@"Value" ] ];
				IFNode* scale = [ general childWithTitle:@"Scale" ];
				[ scale setVisible:YES ];
				IFNode* scaleX = [ scale childWithTitle:@"Scale X" ];
				[ scaleX setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", obj.scaleX ] forKey:@"Value" ] ];
				IFNode* scaleY = [ scale childWithTitle:@"Scale Y" ];
				[ scaleY setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", obj.scaleY ] forKey:@"Value" ] ];
				IFNode* scaleZ = [ scale childWithTitle:@"Scale Z" ];
				[ scaleZ setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", obj.scaleZ ] forKey:@"Value" ] ];
				IFNode* rotate = [ general childWithTitle:@"Rotate" ];
				[ rotate setVisible:YES ];
				IFNode* rotateX = [ rotate childWithTitle:@"Rotate Axis X" ];
				[ rotateX setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", obj.rotateAxis.x ] forKey:@"Value" ] ];
				IFNode* rotateY = [ rotate childWithTitle:@"Rotate Axis Y" ];
				[ rotateY setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", obj.rotateAxis.y ] forKey:@"Value" ] ];
				IFNode* rotateZ = [ rotate childWithTitle:@"Rotate Axis Z" ];
				[ rotateZ setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", obj.rotateAxis.z ] forKey:@"Value" ] ];
				IFNode* rotateA = [ rotate childWithTitle:@"Rotate Angle" ];
				[ rotateA setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", obj.rotateAngle ] forKey:@"Value" ] ];
				/*IFNode* rotatePX = [ rotate childWithTitle:@"Rotate Point X" ];
				[ rotatePX setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", obj.rotatePoint.x ] forKey:@"Value" ] ];
				IFNode* rotatePY = [ rotate childWithTitle:@"Rotate Point Y" ];
				[ rotatePY setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", obj.rotatePoint.y ] forKey:@"Value" ] ];
				IFNode* rotatePZ = [ rotate childWithTitle:@"Rotate Point Z" ];
				[ rotatePZ setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", obj.rotatePoint.z ] forKey:@"Value" ] ];*/
				IFNode* point = [ general childWithTitle:@"Midpoint" ];
				[ point setVisible:NO ];
				/*[ point setVisible:YES ];
				IFNode* pointX = [ point childWithTitle:@"Midpoint X" ];
				[ pointX setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", [ obj midPoint ].x ] forKey:@"Value" ] ];
				IFNode* pointY = [ point childWithTitle:@"Midpoint Y" ];
				[ pointY setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", [ obj midPoint ].y ] forKey:@"Value" ] ];
				IFNode* pointZ = [ point childWithTitle:@"Midpoint Z" ];
				[ pointZ setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", [ obj midPoint ].z ] forKey:@"Value" ] ];*/
				[ [ general childWithTitle:@"Points" ] setVisible:NO ];
				[ [ general childWithTitle:@"Normal" ] setVisible:NO ];
				
				// Disable for now
				IFNode* faces = [ general childWithTitle:@"Faces" ];
				[ faces setVisible:NO ];
				/*[ faces setVisible:YES ];
				[ faces setExpanded:NO ];
				[ faces removeChildren ];*/
				
				[ infoTable setEditing:YES ];
				[ infoTable reloadData ];
			}
			else if (currentMode == MD_VERTEX_MODE)
			{
				MDPoint* p = [ selected fullValueAtIndex:0 ];
				if (p)
				{
					[ general setVisible:YES ];
					IFNode* point = [ general childWithTitle:@"Midpoint" ];
					[ point setVisible:YES ];
					IFNode* pointX = [ point childWithTitle:@"Midpoint X" ];
					[ pointX setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", p.x ] forKey:@"Value" ] ];
					IFNode* pointY = [ point childWithTitle:@"Midpoint Y" ];
					[ pointY setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", p.y ] forKey:@"Value" ] ];
					IFNode* pointZ = [ point childWithTitle:@"Midpoint Z" ];
					[ pointZ setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", p.z ] forKey:@"Value" ] ];
					
					// Find points
					NSMutableArray* points = [ [ NSMutableArray alloc ] init ];
					MDInstance* instance = [ p instance ];
					for (unsigned long z = 0; z < [ instance numberOfPoints ]; z++)
					{
						MDPoint* q = [ instance pointAtIndex:z ];
						if (MDFloatCompare(q.x, p.x) && MDFloatCompare(q.y, p.y) && MDFloatCompare(q.z, p.z))
							[ points addObject:q ];
					}
					
					// Add points
					for (unsigned long z = 0; z < [ points count ]; z++)
					{
						MDPoint* q = [ points objectAtIndex:z ];
						IFNode* node = [ [ IFNode alloc ] initParentWithTitle:[ NSString stringWithFormat:@"Point %lu", z + 1 ] children:nil ];
						
						IFNode* mid = [ [ IFNode alloc ] initParentWithTitle:@"Midpoint" children:nil ];
						IFNode* midx = [ [ IFNode alloc ] initLeafWithTitle:@"Midpoint X" ];
						[ midx setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", q.x ] forKey:@"Value" ] ];
						[ mid addChild:midx ];
						IFNode* midy = [ [ IFNode alloc ] initLeafWithTitle:@"Midpoint Y" ];
						[ midy setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", q.y ] forKey:@"Value" ] ];
						[ mid addChild:midy ];
						IFNode* midz = [ [ IFNode alloc ] initLeafWithTitle:@"Midpoint Z" ];
						[ midz setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", q.z ] forKey:@"Value" ] ];
						[ mid addChild:midz ];
						[ node addChild:mid ];
						
						IFNode* norm = [ [ IFNode alloc ] initParentWithTitle:@"Normal" children:nil ];
						IFNode* normx = [ [ IFNode alloc ] initLeafWithTitle:@"Normal X" ];
						[ normx setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", q.normalX ] forKey:@"Value" ] ];
						[ norm addChild:normx ];
						IFNode* normy = [ [ IFNode alloc ] initLeafWithTitle:@"Normal Y" ];
						[ normy setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", q.normalY ] forKey:@"Value" ] ];
						[ norm addChild:normy ];
						IFNode* normz = [ [ IFNode alloc ] initLeafWithTitle:@"Normal Z" ];
						[ normz setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", q.normalZ ] forKey:@"Value" ] ];
						[ norm addChild:normz ];
						[ node addChild:norm ];
						
						IFNode* tex = [ [ IFNode alloc ] initParentWithTitle:@"Texture Coordinates" children:nil ];
						IFNode* texx = [ [ IFNode alloc ] initLeafWithTitle:@"Texture X" ];
						[ texx setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", q.textureCoordX ] forKey:@"Value" ] ];
						[ tex addChild:texx ];
						IFNode* texy = [ [ IFNode alloc ] initLeafWithTitle:@"Texture Y" ];
						[ texy setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", q.textureCoordY ] forKey:@"Value" ] ];
						[ tex addChild:texy ];
						[ node addChild:tex ];
						
						[ general addChild:node ];
					}
					
					IFNode* translate = [ general childWithTitle:@"Translation" ];
					[ translate	setVisible:NO ];
					IFNode* scale = [ general childWithTitle:@"Scale" ];
					[ scale setVisible:NO ];
					IFNode* rotate = [ general childWithTitle:@"Rotate" ];
					[ rotate setVisible:NO ];
					[ [ general childWithTitle:@"Points" ] setVisible:NO ];
					[ [ general childWithTitle:@"Faces" ] setVisible:NO ];
					[ infoTable setEditing:YES ];
					[ infoTable reloadData ];
				}
			}
			else if (currentMode == MD_FACE_MODE)
			{
				/*
				MDFace* face = [ [ selected selectedValueAtIndex:0 ] objectForKey:@"Face" ];
				if (face)
				{
					[ general setVisible:YES ];
					IFNode* translate = [ general childWithTitle:@"Translation" ];
					[ translate	setVisible:NO ];
					IFNode* scale = [ general childWithTitle:@"Scale" ];
					[ scale setVisible:NO ];
					IFNode* rotate = [ general childWithTitle:@"Rotate" ];
					[ rotate setVisible:NO ];
					IFNode* points = [ general childWithTitle:@"Points" ];
					[ points removeChildren ];
					for (int y = 0; y < [ face numberOfPoints ]; y++)
					{
						IFNode* p = [ [ IFNode alloc ] initParentWithTitle:[ NSString stringWithFormat:@"Point %i", y ] children:nil ];
						
						IFNode* normal = [ [ IFNode alloc ] initParentWithTitle:@"Normal" children:nil ];
						IFNode* nx = [ [ IFNode alloc ] initLeafWithTitle:@"Normal X" ];
						[ nx setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", [ face pointAtIndex:y ].normalX ] forKey:@"Value" ] ];
						[ normal addChild:nx ];
						[ nx release ];
						IFNode* ny = [ [ IFNode alloc ] initLeafWithTitle:@"Normal Y" ];
						[ ny setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", [ face pointAtIndex:y ].normalY ] forKey:@"Value" ] ];
						[ normal addChild:ny ];
						[ ny release ];
						IFNode* nz = [ [ IFNode alloc ] initLeafWithTitle:@"Normal Z" ];
						[ nz setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", [ face pointAtIndex:y ].normalZ ] forKey:@"Value" ] ];
						[ normal addChild:nz ];
						[ nz release ];
						[ p addChild:normal ];
						[ normal release ];
						
						IFNode* px = [ [ IFNode alloc ] initLeafWithTitle:@"X" ];
						[ px setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", [ face pointAtIndex:y ].x ] forKey:@"Value" ] ];
						[ p addChild:px ];
						[ px release ];
						IFNode* py = [ [ IFNode alloc ] initLeafWithTitle:@"Y" ];
						[ py setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", [ face pointAtIndex:y ].y ] forKey:@"Value" ] ];
						[ p addChild:py ];
						[ py release ];
						IFNode* pz = [ [ IFNode alloc ] initLeafWithTitle:@"Z" ];
						[ pz setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", [ face pointAtIndex:y ].z ] forKey:@"Value" ] ];
						[ p addChild:pz];
						[ pz release ];
						IFNode* pr = [ [ IFNode alloc ] initLeafWithTitle:@"Red" ];
						[ pr setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", [ face pointAtIndex:y ].red ] forKey:@"Value" ] ];
						[ p addChild:pr ];
						[ pr release ];
						IFNode* pg = [ [ IFNode alloc ] initLeafWithTitle:@"Green" ];
						[ pg setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", [ face pointAtIndex:y ].green ] forKey:@"Value" ] ];
						[ p addChild:pg ];
						[ pg release ];
						IFNode* pb = [ [ IFNode alloc ] initLeafWithTitle:@"Blue" ];
						[ pb setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", [ face pointAtIndex:y ].blue ] forKey:@"Value" ] ];
						[ p addChild:pb ];
						[ pb release ];
						IFNode* pa = [ [ IFNode alloc ] initLeafWithTitle:@"Alpha" ];
						[ pa setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", [ face pointAtIndex:y ].alpha ] forKey:@"Value" ] ];
						[ p addChild:pa ];
						[ pa release ];
						
						[ points addChild:p ];
						[ p release ];
					}
					[ points setVisible:YES ];
					[ [ general childWithTitle:@"Faces" ] setVisible:NO ];
					[ [ general childWithTitle:@"Midpoint" ] setVisible:NO ];
					[ [ general childWithTitle:@"Normal" ] setVisible:NO ];
					[ infoTable setEditing:YES ];
					[ infoTable reloadData ];
				}*/
			}
			
			IFNode* color = [ general childWithTitle:@"Color" ];
			if (currentMode == MD_OBJECT_MODE || currentMode == MD_FACE_MODE)
			{
				MDVector4 p = [ [ selected fullValueAtIndex:0 ] midColor ];
					
				[ color setVisible:YES ];
				IFNode* red = [ color childWithTitle:@"Red" ];
				[ red setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", p.x ] forKey:@"Value" ] ];
				IFNode* green = [ color childWithTitle:@"Green" ];
				[ green setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", p.y ] forKey:@"Value" ] ];
				IFNode* blue = [ color childWithTitle:@"Blue" ];
				[ blue setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", p.z ] forKey:@"Value" ] ];
				IFNode* alpha = [ color childWithTitle:@"Alpha" ];
				[ alpha setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", p.w ] forKey:@"Value" ] ];
				
				if (currentMode == MD_OBJECT_MODE)
				{
					MDVector4 p2 = [ [ selected fullValueAtIndex:0 ] colorMultiplier ];
					IFNode* ored = [ color childWithTitle:@"Object Red" ];
					[ ored setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", p2.x ] forKey:@"Value" ] ];
					IFNode* ogreen = [ color childWithTitle:@"Object Green" ];
					[ ogreen setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", p2.y ] forKey:@"Value" ] ];
					IFNode* oblue = [ color childWithTitle:@"Object Blue" ];
					[ oblue setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", p2.z ] forKey:@"Value" ] ];
					IFNode* oalpha = [ color childWithTitle:@"Object Alpha" ];
					[ oalpha setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", p2.w ] forKey:@"Value" ] ];
				}
				
				if (currentMode == MD_OBJECT_MODE)
				{
					MDVector4 t = [ [ selected fullValueAtIndex:0 ] specularColor ];
					IFNode* sred = [ color childWithTitle:@"Specular Red" ];
					[ sred setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", t.x ] forKey:@"Value" ] ];
					IFNode* sgreen = [ color childWithTitle:@"Specular Green" ];
					[ sgreen setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", t.y ] forKey:@"Value" ] ];
					IFNode* sblue = [ color childWithTitle:@"Specular Blue" ];
					[ sblue setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", t.z ] forKey:@"Value" ] ];
					IFNode* salpha = [ color childWithTitle:@"Specular Alpha" ];
					[ salpha setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", t.w ] forKey:@"Value" ] ];
					IFNode* shininess = [ color childWithTitle:@"Shininess" ];
					[ shininess setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", [ [ selected fullValueAtIndex:0 ] shininess ] ] forKey:@"Value" ] ];
				}
			}
			else
				[ color setVisible:NO ];
						 
			[ infoTable setEditing:YES ];
			[ infoTable reloadItem:color reloadChildren:YES ];
		}
		else
		{
			IFNode* general = [ [ infoTable rootNode ] childWithTitle:@"General Attributes" ];
			[ general setVisible:NO ];
			[ infoTable setEditing:YES ];
			[ infoTable reloadData ];
			
			/*IFNode* color = [ [ materialTable rootNode ] childWithTitle:@"Color" ];
			[ color setVisible:NO ];
			[ materialTable reloadData ];*/
		}
		if ([ selected count ] == 0)
		{
			[ copyMenu setAction:nil ];
			[ duplicateMenu setAction:nil ];
			[ cutMenu setAction:nil ];
			[ deleteMenu setAction:nil ];
			[ objectCombine setAction:nil ];
			[ objectTrans setAction:nil ];
			[ objectNormalize setEnabled:NO ];
			[ objectAddTexture setAction:nil ];
			[ objectReverseWinding setAction:nil ];
			[ objectSetHeight setAction:nil ];
			[ objectExportHeight setAction:nil ];
			[ objectProperties setAction:nil ];
			[ objectPhysicsProperties setAction:nil ];
			[ objectAnimations setAction:nil ];
			[ objectHidden setAction:nil ];
			[ objectHidden setState:NSOffState ];
			
			BOOL thereIs = FALSE;
			for (unsigned long z = 0; z < [ otherObjects count ]; z++)
			{
				if ([ [ otherObjects objectAtIndex:z ] selected ] || ([ [ otherObjects objectAtIndex:z ] isKindOfClass:[ MDCamera class ] ] && [ (MDCamera*)[ otherObjects objectAtIndex:z ] lookSelected ]))
				{
					thereIs = TRUE;
					break;
				}
			}
			if (!thereIs)
				[ libraryOutline selectRowIndexes:[ NSIndexSet indexSet ] byExtendingSelection:NO ];
		}
		else
		{
			if (currentMode == MD_OBJECT_MODE)
			{
				[ copyMenu setAction:@selector(copy:) ];
				[ duplicateMenu setAction:@selector(duplicate:) ];
				[ cutMenu setAction:@selector(cut:) ];
				if ([ selected count ] > 1)
				{
					[ objectCombine setAction:@selector(combineObjects:) ];
					[ objectTrans setAction:@selector(applyTransformations:) ];
					[ objectNormalize setEnabled:YES ];
					[ objectAddTexture setAction:@selector(showTextures:) ];
					[ objectReverseWinding setAction:@selector(reverseWinding:) ];
					[ objectSetHeight setAction:@selector(setHeightMap:) ];
					[ objectExportHeight setAction:nil ];
					[ objectProperties setAction:nil ];
					[ objectPhysicsProperties setAction:nil ];
					[ objectAnimations setAction:nil ];
					[ objectHidden setAction:@selector(objectMarkHidden:) ];
					BOOL first = [ [ selected fullValueAtIndex:0 ] shouldView ];
					BOOL diff = FALSE;
					for (unsigned long z = 1; z < [ selected count ]; z++)
					{
						if ([ [ selected fullValueAtIndex:z ] shouldView ] != first)
						{
							diff = TRUE;
							break;
						}
					}
					[ objectHidden setState:(diff ? NSMixedState : (first ? NSOffState : NSOnState)) ];
				}
				else if ([ selected count ] == 1)
				{
					[ objectCombine setAction:nil ];
					[ objectTrans setAction:@selector(applyTransformations:) ];
					[ objectNormalize setEnabled:YES ];
					[ objectAddTexture setAction:@selector(showTextures:) ];
					[ objectReverseWinding setAction:@selector(reverseWinding:) ];
					[ objectSetHeight setAction:@selector(setHeightMap:) ];
					[ objectExportHeight setAction:@selector(exportHeightMap:) ];
					[ objectProperties setAction:@selector(showPropertyWindow:) ];
					[ objectPhysicsProperties setAction:@selector(showPhysicsWindow:) ];
					[ objectAnimations setAction:@selector(showAnimationWindow:) ];
					[ objectHidden setAction:@selector(objectMarkHidden:) ];
					[ objectHidden setState:([ [ selected fullValueAtIndex:0 ] shouldView ] ? NSOffState : NSOnState) ];
				}
				else
				{
					[ objectCombine setAction:nil ];
					[ objectTrans setAction:nil ];
					[ objectNormalize setEnabled:NO ];
					[ objectAddTexture setAction:nil ];
					[ objectReverseWinding setAction:nil ];
					[ objectSetHeight setAction:nil ];
					[ objectExportHeight setAction:nil ];
					[ objectProperties setAction:nil ];
					[ objectPhysicsProperties setAction:nil ];
					[ objectAnimations setAction:nil ];
					[ objectHidden setAction:nil ];
					[ objectHidden setState:NSOffState ];
				}
			}
			if (currentMode == MD_OBJECT_MODE || currentMode == MD_FACE_MODE)
				[ deleteMenu setAction:@selector(deleteItem:) ];
			if (currentMode == MD_FACE_MODE)
			{
				if ([ selected count ] > 1)
				{
					[ objectAddTexture setAction:@selector(showTextures:) ];
					[ objectSetHeight setAction:@selector(setHeightMap:) ];
				}
				else if ([ selected count ] == 1)
				{
					[ objectAddTexture setAction:@selector(showTextures:) ];
					[ objectSetHeight setAction:@selector(setHeightMap:) ];
					[ objectExportHeight setAction:@selector(exportHeightMap:) ];
				}
				else
				{
				}
			}
		}
		commandFlag &= ~UPDATE_INFO;
	}
	else if (commandFlag & UPDATE_SCENE_INFO)
	{
		IFNode* scene = [ [ infoTable rootNode ] childWithTitle:@"Scene" ];
		IFNode* xpos = [ scene childWithTitle:@"X Position" ];
		[ xpos setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", translationPoint.x ] forKey:@"Value" ] ];
		IFNode* ypos = [ scene childWithTitle:@"Y Position" ];
		[ ypos setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", translationPoint.y ] forKey:@"Value" ] ];
		IFNode* zpos = [ scene childWithTitle:@"Z Position" ];
		[ zpos setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", translationPoint.z ] forKey:@"Value" ] ];
		IFNode* xlook = [ scene childWithTitle:@"X Look" ];
		[ xlook setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", lookPoint.x ] forKey:@"Value" ] ];
		IFNode* ylook = [ scene childWithTitle:@"Y Look" ];
		[ ylook setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", lookPoint.y ] forKey:@"Value" ] ];
		IFNode* zlook = [ scene childWithTitle:@"Z Look" ];
		[ zlook setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", lookPoint.z ] forKey:@"Value" ] ];
		IFNode* xrot = [ scene childWithTitle:@"X Rotation" ];
		[ xrot setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", [ [ views objectAtIndex:0 ] xrotation ] ] forKey:@"Value" ] ];
		IFNode* yrot = [ scene childWithTitle:@"Y Rotation" ];
		[ yrot setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", [ [ views objectAtIndex:0 ] yrotation ] ] forKey:@"Value" ] ];
		IFNode* zrot = [ scene childWithTitle:@"Z Rotation" ];
		[ zrot setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", [ [ views objectAtIndex:0 ] zrotation ] ] forKey:@"Value" ] ];
		[ infoTable reloadItem:xpos ];
		[ infoTable reloadItem:ypos ];
		[ infoTable reloadItem:zpos ];
		[ infoTable reloadItem:xlook ];
		[ infoTable reloadItem:ylook ];
		[ infoTable reloadItem:zlook ];
		[ infoTable reloadItem:xrot ];
		[ infoTable reloadItem:yrot ];
		[ infoTable reloadItem:zrot ];
		[ infoTable setEditing:YES ];
		commandFlag &= ~UPDATE_SCENE_INFO;
	}
	if (commandFlag & UPDATE_OTHER_INFO)
	{
		[ self clearOther ];
				
		unsigned long row = -1;
		for (int z = 0; z < [ otherObjects count ]; z++)
		{
			if ([ [ otherObjects objectAtIndex:z ] selected ] || ([ [ otherObjects objectAtIndex:z ] isKindOfClass:[ MDCamera class ] ] && [ (MDCamera*)[ otherObjects objectAtIndex:z ] lookSelected ]))
			{
				row = z;
				break;
			}
		}
		
		if (row != -1)
		{
			[ [ [ infoTable rootNode ] childWithTitle:@"General Attributes" ] setVisible:NO ];
			
			// Select it in the library
			[ libraryOutline selectNode:[ [ libraryOutline rootNode ] childWithTitle:[ [ otherObjects objectAtIndex:row ] name ] ] ];
			
			if ([ [ otherObjects objectAtIndex:row ] isKindOfClass:[ MDCamera class ] ])
			{
				IFNode* vis = [ [ infoTable rootNode ] childWithTitle:@"Visible" ];
				[ vis setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%i", [ (MDCamera*)[ otherObjects objectAtIndex:row ] show ] ] forKey:@"Value" ] ];
				[ vis setVisible:YES ];
				IFNode* use = [ [ infoTable rootNode ] childWithTitle:@"Use" ];
				[ use setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%i", [ (MDCamera*)[ otherObjects objectAtIndex:row ] use ] ] forKey:@"Value" ] ];
				[ use setVisible:YES ];
				
				for (int z = 0; z < [ otherObjects count ]; z++)
				{
					if (row == z)
						continue;
					id camera = [ otherObjects objectAtIndex:z ];
					[ camera setSelected:NO ];
					if ([ [ otherObjects objectAtIndex:z ] isKindOfClass:[ MDCamera class ] ])
						[ camera setLookSelected:NO ];
				}
				if (![ [ otherObjects objectAtIndex:row ] lookSelected ])
					[ (MDCamera*)[ otherObjects objectAtIndex:row ] setSelected:YES ];
				[ selected clear ];
				
				MDCamera* camera = [ otherObjects objectAtIndex:row ];
				
				IFNode* mpx = [ [ [ infoTable rootNode ] childWithTitle:@"Midpoint" ] childWithTitle:@"X" ];
				[ mpx setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", [ camera midPoint ].x ] forKey:@"Value" ] ];
				IFNode* mpy = [ [ [ infoTable rootNode ] childWithTitle:@"Midpoint" ] childWithTitle:@"Y" ];
				[ mpy setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", [ camera midPoint ].y ] forKey:@"Value" ] ];
				IFNode* mpz = [ [ [ infoTable rootNode ] childWithTitle:@"Midpoint" ] childWithTitle:@"Z" ];
				[ mpz setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", [ camera midPoint ].z ] forKey:@"Value" ] ];
				IFNode* lpx = [ [ [ infoTable rootNode ] childWithTitle:@"Lookpoint" ] childWithTitle:@"X" ];
				[ lpx setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", [ camera lookPoint ].x ] forKey:@"Value" ] ];
				IFNode* lpy = [ [ [ infoTable rootNode ] childWithTitle:@"Lookpoint" ] childWithTitle:@"Y" ];
				[ lpy setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", [ camera lookPoint ].y ] forKey:@"Value" ] ];
				IFNode* lpz = [ [ [ infoTable rootNode ] childWithTitle:@"Lookpoint" ] childWithTitle:@"Z" ];
				[ lpz setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", [ camera lookPoint ].z ] forKey:@"Value" ] ];
				[ [ [ infoTable rootNode ] childWithTitle:@"Midpoint" ] setVisible:YES ];
				[ [ [ infoTable rootNode ] childWithTitle:@"Lookpoint" ] setVisible:YES ];
				[ [ [ infoTable rootNode ] childWithTitle:@"Orientation" ] setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", camera.orientation ] forKey:@"Value" ] ];
				[ [ [ infoTable rootNode ] childWithTitle:@"Orientation" ] setVisible:YES ];
			}
			else if ([ [ otherObjects objectAtIndex:row ] isKindOfClass:[ MDLight class ] ])
			{
				IFNode* vis = [ [ infoTable rootNode ] childWithTitle:@"Visible" ];
				[ vis setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%i", [ (MDLight*)[ otherObjects objectAtIndex:row ] show ] ] forKey:@"Value" ] ];
				[ vis setVisible:YES ];
				for (int z = 0; z < [ otherObjects count ]; z++)
				{
					if (row == z)
						continue;
					id light = [ otherObjects objectAtIndex:z ];
					[ light setSelected:NO ];
				}
				MDLight* light = [ otherObjects objectAtIndex:row ];
				[ light setSelected:YES ];
				[ selected clear ];
				
				IFNode* mpx = [ [ [ infoTable rootNode ] childWithTitle:@"Midpoint" ] childWithTitle:@"X" ];
				[ mpx setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", light.position.x ] forKey:@"Value" ] ];
				IFNode* mpy = [ [ [ infoTable rootNode ] childWithTitle:@"Midpoint" ] childWithTitle:@"Y" ];
				[ mpy setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", light.position.y ] forKey:@"Value" ] ];
				IFNode* mpz = [ [ [ infoTable rootNode ] childWithTitle:@"Midpoint" ] childWithTitle:@"Z" ];
				[ mpz setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", light.position.z ] forKey:@"Value" ] ];
				IFNode* lpx = [ [ [ infoTable rootNode ] childWithTitle:@"Lookpoint" ] childWithTitle:@"X" ];
				[ lpx setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", light.spotDirection.x ] forKey:@"Value" ] ];
				IFNode* lpy = [ [ [ infoTable rootNode ] childWithTitle:@"Lookpoint" ] childWithTitle:@"Y" ];
				[ lpy setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", light.spotDirection.y ] forKey:@"Value" ] ];
				IFNode* lpz = [ [ [ infoTable rootNode ] childWithTitle:@"Lookpoint" ] childWithTitle:@"Z" ];
				[ lpz setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", light.spotDirection.z ] forKey:@"Value" ] ];
				IFNode* car = [ [ [ infoTable rootNode ] childWithTitle:@"Colors" ] childWithTitle:@"Ambient Red" ];
				[ car setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", light.ambientColor.x ] forKey:@"Value" ] ];
				IFNode* cag = [ [ [ infoTable rootNode ] childWithTitle:@"Colors" ] childWithTitle:@"Ambient Green" ];
				[ cag setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", light.ambientColor.y ] forKey:@"Value" ] ];
				IFNode* cab = [ [ [ infoTable rootNode ] childWithTitle:@"Colors" ] childWithTitle:@"Ambient Blue" ];
				[ cab setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", light.ambientColor.z ] forKey:@"Value" ] ];
				IFNode* caa = [ [ [ infoTable rootNode ] childWithTitle:@"Colors" ] childWithTitle:@"Ambient Alpha" ];
				[ caa setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", light.ambientColor.w ] forKey:@"Value" ] ];
				IFNode* dar = [ [ [ infoTable rootNode ] childWithTitle:@"Colors" ] childWithTitle:@"Diffuse Red" ];
				[ dar setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", light.diffuseColor.x ] forKey:@"Value" ] ];
				IFNode* dag = [ [ [ infoTable rootNode ] childWithTitle:@"Colors" ] childWithTitle:@"Diffuse Green" ];
				[ dag setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", light.diffuseColor.y ] forKey:@"Value" ] ];
				IFNode* dab = [ [ [ infoTable rootNode ] childWithTitle:@"Colors" ] childWithTitle:@"Diffuse Blue" ];
				[ dab setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", light.diffuseColor.z ] forKey:@"Value" ] ];
				IFNode* daa = [ [ [ infoTable rootNode ] childWithTitle:@"Colors" ] childWithTitle:@"Diffuse Alpha" ];
				[ daa setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", light.diffuseColor.w ] forKey:@"Value" ] ];
				IFNode* sar = [ [ [ infoTable rootNode ] childWithTitle:@"Colors" ] childWithTitle:@"Specular Red" ];
				[ sar setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", light.specularColor.x ] forKey:@"Value" ] ];
				IFNode* sag = [ [ [ infoTable rootNode ] childWithTitle:@"Colors" ] childWithTitle:@"Specular Green" ];
				[ sag setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", light.specularColor.y ] forKey:@"Value" ] ];
				IFNode* sab = [ [ [ infoTable rootNode ] childWithTitle:@"Colors" ] childWithTitle:@"Specular Blue" ];
				[ sab setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", light.specularColor.z ] forKey:@"Value" ] ];
				IFNode* saa = [ [ [ infoTable rootNode ] childWithTitle:@"Colors" ] childWithTitle:@"Specular Alpha" ];
				[ saa setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", light.specularColor.w ] forKey:@"Value" ] ];
				IFNode* se = [ [ [ infoTable rootNode ] childWithTitle:@"Spot" ] childWithTitle:@"Exponent" ];
				[ se setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", light.spotExp ] forKey:@"Value" ] ];
				IFNode* sc = [ [ [ infoTable rootNode ] childWithTitle:@"Spot" ] childWithTitle:@"Cutoff" ];
				[ sc setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", light.spotCut ] forKey:@"Value" ] ];
				IFNode* scc = [ [ [ infoTable rootNode ] childWithTitle:@"Spot" ] childWithTitle:@"Angle Cutoff" ];
				[ scc setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", light.spotAngle ] forKey:@"Value" ] ];
				IFNode* ac = [ [ [ infoTable rootNode ] childWithTitle:@"Attenuation" ] childWithTitle:@"Constant" ];
				[ ac setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", light.constAtt ] forKey:@"Value" ] ];
				IFNode* al = [ [ [ infoTable rootNode ] childWithTitle:@"Attenuation" ] childWithTitle:@"Linear" ];
				[ al setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", light.linAtt ] forKey:@"Value" ] ];
				IFNode* aq = [ [ [ infoTable rootNode ] childWithTitle:@"Attenuation" ] childWithTitle:@"Quadratic" ];
				[ aq setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", light.quadAtt ] forKey:@"Value" ] ];
				IFNode* she = [ [ [ infoTable rootNode ] childWithTitle:@"Shadows" ] childWithTitle:@"Enable Shadows" ];
				[ she setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%i", light.enableShadows ] forKey:@"Value" ] ];
				IFNode* sis = [ [ [ infoTable rootNode ] childWithTitle:@"Shadows" ] childWithTitle:@"Static" ];
				[ sis setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%i", light.isStatic ] forKey:@"Value" ] ];
				
				[ [ [ infoTable rootNode ] childWithTitle:@"Midpoint" ] setVisible:YES ];
				[ [ [ infoTable rootNode ] childWithTitle:@"Lookpoint" ] setVisible:(light.lightType != MDPointLight) ];
				[ [ [ infoTable rootNode ] childWithTitle:@"Colors" ] setVisible:YES ];
				[ [ [ infoTable rootNode ] childWithTitle:@"Spot" ] setVisible:(light.lightType == MDSpotLight) ];
				[ [ [ infoTable rootNode ] childWithTitle:@"Attenuation" ] setVisible:(light.lightType != MDDirectionalLight) ];
				[ [ [ infoTable rootNode ] childWithTitle:@"Shadows" ] setVisible:YES ];
			}
			else if ([ [ otherObjects objectAtIndex:row ] isKindOfClass:[ MDParticleEngine class ] ])
			{
				IFNode* vis = [ [ infoTable rootNode ] childWithTitle:@"Visible" ];
				[ vis setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%i", [ (MDParticleEngine*)[ otherObjects objectAtIndex:row ] show ] ] forKey:@"Value" ] ];
				[ vis setVisible:YES ];
				for (int z = 0; z < [ otherObjects count ]; z++)
				{
					if (row == z)
						continue;
					id other = [ otherObjects objectAtIndex:z ];
					[ other setSelected:NO ];
				}
				MDParticleEngine* engine = [ otherObjects objectAtIndex:row ];
				[ engine setSelected:YES ];
				[ selected clear ];
				
				IFNode* mpx = [ [ [ infoTable rootNode ] childWithTitle:@"Midpoint" ] childWithTitle:@"X" ];
				[ mpx setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", engine.position.x ] forKey:@"Value" ] ];
				IFNode* mpy = [ [ [ infoTable rootNode ] childWithTitle:@"Midpoint" ] childWithTitle:@"Y" ];
				[ mpy setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", engine.position.y ] forKey:@"Value" ] ];
				IFNode* mpz = [ [ [ infoTable rootNode ] childWithTitle:@"Midpoint" ] childWithTitle:@"Z" ];
				[ mpz setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", engine.position.z ] forKey:@"Value" ] ];
				IFNode* sr = [ [ [ infoTable rootNode ] childWithTitle:@"Particle Colors" ] childWithTitle:@"Start Red" ];
				[ sr setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", engine.startColor.x ] forKey:@"Value" ] ];
				IFNode* sg = [ [ [ infoTable rootNode ] childWithTitle:@"Particle Colors" ] childWithTitle:@"Start Green" ];
				[ sg setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", engine.startColor.y ] forKey:@"Value" ] ];
				IFNode* sb = [ [ [ infoTable rootNode ] childWithTitle:@"Particle Colors" ] childWithTitle:@"Start Blue" ];
				[ sb setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", engine.startColor.z ] forKey:@"Value" ] ];
				IFNode* sa = [ [ [ infoTable rootNode ] childWithTitle:@"Particle Colors" ] childWithTitle:@"Start Alpha" ];
				[ sa setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", engine.startColor.w ] forKey:@"Value" ] ];
				IFNode* er = [ [ [ infoTable rootNode ] childWithTitle:@"Particle Colors" ] childWithTitle:@"End Red" ];
				[ er setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", engine.endColor.x ] forKey:@"Value" ] ];
				IFNode* eg = [ [ [ infoTable rootNode ] childWithTitle:@"Particle Colors" ] childWithTitle:@"End Green" ];
				[ eg setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", engine.endColor.y ] forKey:@"Value" ] ];
				IFNode* eb = [ [ [ infoTable rootNode ] childWithTitle:@"Particle Colors" ] childWithTitle:@"End Blue" ];
				[ eb setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", engine.endColor.z ] forKey:@"Value" ] ];
				IFNode* ea = [ [ [ infoTable rootNode ] childWithTitle:@"Particle Colors" ] childWithTitle:@"End Alpha" ];
				[ ea setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", engine.endColor.w ] forKey:@"Value" ] ];
				IFNode* vT = [ [ [ infoTable rootNode ] childWithTitle:@"Velocities" ] childWithTitle:@"Type" ];
				[ vT setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%i", engine.velocityType ] forKey:@"Value" ] ];
				IFNode* vX = [ [ [ infoTable rootNode ] childWithTitle:@"Velocities" ] childWithTitle:@"X" ];
				[ vX setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", engine.velocities.x ] forKey:@"Value" ] ];
				IFNode* vY = [ [ [ infoTable rootNode ] childWithTitle:@"Velocities" ] childWithTitle:@"Y" ];
				[ vY setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", engine.velocities.y ] forKey:@"Value" ] ];
				IFNode* vZ = [ [ [ infoTable rootNode ] childWithTitle:@"Velocities" ] childWithTitle:@"Z" ];
				[ vZ setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", engine.velocities.z ] forKey:@"Value" ] ];
				[ [ [ infoTable rootNode ] childWithTitle:@"Particle Number" ] setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%lu", engine.numberOfParticles ] forKey:@"Value" ] ];
				[ [ [ infoTable rootNode ] childWithTitle:@"Particle Size" ] setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", engine.particleSize ] forKey:@"Value" ] ];
				[ [ [ infoTable rootNode ] childWithTitle:@"Particle Life" ] setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%lu", engine.particleLife ] forKey:@"Value" ] ];
				
				[ [ [ infoTable rootNode ] childWithTitle:@"Midpoint" ] setVisible:YES ];
				[ [ [ infoTable rootNode ] childWithTitle:@"Velocities" ] setVisible:YES ];
				[ [ [ infoTable rootNode ] childWithTitle:@"Particle Colors" ] setVisible:YES ];
				[ [ [ infoTable rootNode ] childWithTitle:@"Particle Number" ] setVisible:YES ];
				[ [ [ infoTable rootNode ] childWithTitle:@"Particle Size" ] setVisible:YES ];
				[ [ [ infoTable rootNode ] childWithTitle:@"Particle Life" ] setVisible:YES ];
			}
			else if ([ [ otherObjects objectAtIndex:row ] isKindOfClass:[ MDCurve class ] ])
			{
				IFNode* vis = [ [ infoTable rootNode ] childWithTitle:@"Visible" ];
				[ vis setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%i", [ (MDCurve*)[ otherObjects objectAtIndex:row ] show ] ] forKey:@"Value" ] ];
				[ vis setVisible:YES ];
				for (int z = 0; z < [ otherObjects count ]; z++)
				{
					if (row == z)
						continue;
					id other = [ otherObjects objectAtIndex:z ];
					[ other setSelected:NO ];
				}
				MDCurve* curve = [ otherObjects objectAtIndex:row ];
				[ curve setSelected:YES ];
				[ selected clear ];
				
				IFNode* numP = [ [ infoTable rootNode ] childWithTitle:@"Point Number" ];
				[ numP setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%li", [ curve curvePoints ]->size() ] forKey:@"Value" ] ];
				IFNode* points = [ [ infoTable rootNode ] childWithTitle:@"Curve Points" ];
				[ points setChildren:[ NSArray array ] ];
				std::vector<MDVector3> p = *[ curve curvePoints ];
				for (unsigned long z = 0; z < p.size(); z++)
				{
					IFNode* numP = [ [ IFNode alloc ] initParentWithTitle:[ NSString stringWithFormat:@"Point %li", z + 1 ] children:nil ];
					
					IFNode* nx = [ [ IFNode alloc ] initLeafWithTitle:@"X" ];
					[ nx setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", p[z].x ] forKey:@"Value" ] ];
					[ numP addChild:nx ];
					
					IFNode* ny = [ [ IFNode alloc ] initLeafWithTitle:@"Y" ];
					[ ny setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", p[z].y ] forKey:@"Value" ] ];
					[ numP addChild:ny ];
					
					IFNode* nz = [ [ IFNode alloc ] initLeafWithTitle:@"Z" ];
					[ nz setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", p[z].z ] forKey:@"Value" ] ];
					[ numP addChild:nz ];
					
					[ points addChild:numP ];
				}
				
				[ [ [ infoTable rootNode ] childWithTitle:@"Point Number" ] setVisible:YES ];
				[ [ [ infoTable rootNode ] childWithTitle:@"Curve Points" ] setVisible:YES ];
			}
		}
		else if ([ selected count ] == 0)
			[ libraryOutline selectRowIndexes:[ NSIndexSet indexSet ] byExtendingSelection:NO ];
		
		[ infoTable setEditing:YES ];
		[ infoTable reloadData ];
		commandFlag &= ~UPDATE_OTHER_INFO;
	}
	
	if (commandFlag & UPDATE_LIBRARY)
	{
		NSMutableIndexSet* indexSet = [ [ NSMutableIndexSet alloc ] init ];
		BOOL reloadRoot = FALSE;
		for (unsigned long t = 0; t < [ [ libraryOutline rootNode ] numberOfChildren ]; t++)
		{
			NSString* type = [ [ [ [ libraryOutline rootNode ] childAtIndex:t ] dictionary ] objectForKey:@"Type" ];
			if (type)
			{
				if (![ type isEqualToString:@"Object" ])
				{
					[ [ libraryOutline rootNode ] removeChild:[ [ libraryOutline rootNode ] childAtIndex:t ] ];
					t--;
					reloadRoot = TRUE;
				}
				continue;
			}
			BOOL reload = TRUE;
			[ [ [ libraryOutline rootNode] childAtIndex:t ] removeChildren ];
			NSString* instanceName = [ [ [ libraryOutline rootNode ] childAtIndex:t ] title ];
			BOOL foundInstance = FALSE;
			for (unsigned long z = 0; z < [ instances count ]; z++)
			{
				MDInstance* instance = [ instances objectAtIndex:z ];
				if (![ instanceName isEqualToString:[ instance name ] ])
					continue;
				[ indexSet addIndex:z ];
				foundInstance = TRUE;
				for (unsigned long q = 0; q < [ objects count ]; q++)
				{
					if ([ [ objects objectAtIndex:q ] instance ] != instance)
						continue;
					NSString* name = nil;
					if ([ [ objects objectAtIndex:q ] name ])
						name = [ NSString stringWithString:[ [ objects objectAtIndex:q ] name ] ];
					if (!name)
					{
						NSString* instName = [ [ [ objects objectAtIndex:q ] instance ] name ];
						unsigned long counter = 0;
						for (;;)
						{
							name = [ NSString stringWithFormat:@"Object %lu", 1 + counter ];
							BOOL success = TRUE;
							for (unsigned long t = 0; t < [ objects count ]; t++)
							{
								if ([ [ [ objects objectAtIndex:t ] name ] isEqualToString:name ] && [ instName isEqualToString:[ [ [ objects objectAtIndex:t ] instance ] name ] ])
								{
									success = FALSE;
									break;
								}
							}
							if (success)
								break;
							counter++;
						}
						[ (MDObject*)[ objects objectAtIndex:q ] setName:name ];
					}
					else
					{
						// Check if its already taken
						NSString* instName = [ [ [ objects objectAtIndex:q ] instance ] name ];
						unsigned long counter = 0;
						for (;;)
						{
							BOOL success = TRUE;
							for (unsigned long m = 0; m < [ objects count ]; m++)
							{
								if (m == q)
									continue;
								if ([ [ [ objects objectAtIndex:m ] name ] isEqualToString:name ] && [ instName isEqualToString:[ [ [ objects objectAtIndex:m ] instance ] name ] ])
								{
									success = FALSE;
									break;
								}
							}
							if (success)
								break;
							counter++;
							name = [ NSString stringWithFormat:@"Object %lu", 1 + counter ];
						}
						[ (MDObject*)[ objects objectAtIndex:q ] setName:name ];
					}
					reload = TRUE;
					IFNode* objNode = [ [ IFNode alloc ] initLeafWithTitle:name ];
					[ objNode setDictionary:[ NSDictionary dictionaryWithObject:@"Object" forKey:@"Type" ] ];
					[ [ [ libraryOutline rootNode ] childAtIndex:t ] addChild:objNode ];
				}
			}
			if (!foundInstance)
			{
				reloadRoot = TRUE;
				[ [ libraryOutline rootNode ] removeChild:[ [ libraryOutline rootNode ] childAtIndex:t ] ];
				t--;
			}
			if (reload)
				[ libraryOutline reloadItem:[ [ libraryOutline rootNode ] childAtIndex:t ] reloadChildren:YES ];
		}
		
		for (unsigned long z = 0; z < [ instances count ]; z++)
		{
			if ([ indexSet containsIndex:z ])
				continue;
			reloadRoot = TRUE;
			
			MDInstance* instance = [ instances objectAtIndex:z ];
			IFNode* node = [ [ IFNode alloc ] initParentWithTitle:[ instance name ] children:nil ];
				
			for (unsigned long q = 0; q < [ objects count ]; q++)
			{
				if ([ [ objects objectAtIndex:q ] instance ] != instance)
					continue;
				NSString* name = nil;
				if ([ [ objects objectAtIndex:q ] name ])
					name = [ NSString stringWithString:[ [ objects objectAtIndex:q ] name ] ];
				if (!name)
				{
					NSString* instName = [ [ [ objects objectAtIndex:q ] instance ] name ];
					unsigned long counter = 0;
					for (;;)
					{
						name = [ NSString stringWithFormat:@"Object %lu", 1 + counter ];
						BOOL success = TRUE;
						for (unsigned long t = 0; t < [ objects count ]; t++)
						{
							if ([ [ [ objects objectAtIndex:t ] name ] isEqualToString:name ] && [ instName isEqualToString:[ [ [ objects objectAtIndex:t ] instance ] name ] ])
							{
								success = FALSE;
								break;
							}
						}
						if (success)
							break;
						counter++;
					}
					[ (MDObject*)[ objects objectAtIndex:q ] setName:name ];
				}
				else
				{
					// Check if its already taken
					NSString* instName = [ [ [ objects objectAtIndex:q ] instance ] name ];
					unsigned long counter = 0;
					for (;;)
					{
						BOOL success = TRUE;
						for (unsigned long t = 0; t < [ objects count ]; t++)
						{
							if (t == q)
								continue;
							if ([ [ [ objects objectAtIndex:t ] name ] isEqualToString:name ] && [ instName isEqualToString:[ [ [ objects objectAtIndex:t ] instance ] name ] ])
							{
								success = FALSE;
								break;
							}
						}
						if (success)
							break;
						counter++;
						name = [ NSString stringWithFormat:@"Object %lu", 1 + counter ];
					}
					[ (MDObject*)[ objects objectAtIndex:q ] setName:name ];
				}
				IFNode* objNode = [ [ IFNode alloc ] initLeafWithTitle:name ];
				[ objNode setDictionary:[ NSDictionary dictionaryWithObject:@"Object" forKey:@"Type" ] ];
				[ node addChild:objNode ];
				[ node setExpanded:YES ];
			}
			
			[ [ libraryOutline rootNode ] addChild:node ];
		}
		
		for (unsigned long z = 0; z < [ otherObjects count ]; z++)
		{
			NSString* name = [ [ otherObjects objectAtIndex:z ] name ];
			IFNode* node = [ [ IFNode alloc ] initLeafWithTitle:name ];
			NSString* type = @"Unknown";
			if ([ [ otherObjects objectAtIndex:z ] isKindOfClass:[ MDCamera class ] ])
				type = @"Camera";
			if ([ [ otherObjects objectAtIndex:z ] isKindOfClass:[ MDSound class ] ])
				type = @"Sound";
			else if ([ [ otherObjects objectAtIndex:z ] isKindOfClass:[ MDParticleEngine class ] ])
				type = @"Particle Engine";
			else if ([ [ otherObjects objectAtIndex:z ] isKindOfClass:[ MDCurve class ] ] )
				type = @"Curve";
			else if ([ [ otherObjects objectAtIndex:z ] isKindOfClass:[ MDLight class ] ])
			{
				unsigned int lightType = [ [ otherObjects objectAtIndex:z ] lightType ];
				if (lightType == MDDirectionalLight)
					type = @"Directional Light";
				else if (lightType == MDPointLight)
					type = @"Point Light";
				else if (lightType == MDSpotLight)
					type = @"Spot Light";
			}
			[ node setDictionary:[ NSDictionary dictionaryWithObject:type forKey:@"Type" ] ];
			[ [ libraryOutline rootNode ] addChild:node ];
			reloadRoot = TRUE;
		}
		
		if (reloadRoot)
			[ libraryOutline reloadData ];

		commandFlag &= ~UPDATE_LIBRARY;
	}
}
										
- (void) infoTableUpdated: (IFNode*)item
{
	if (move != MD_NONE)
		[ (GLView*)[ glWindow contentView ] mouseDown:nil ];
	MDObject* obj;
	BOOL objPerform = FALSE;
	if ([ selected count ] == 1)
	{
		if (currentMode == MD_OBJECT_MODE)
		{
			obj = [ [ selected selectedValueAtIndex:0 ] objectForKey:@"Object" ];
			objPerform = TRUE;
			oldObject = [ [ NSMutableArray alloc ] init ];
			for (int z = 0; z < [ selected count ]; z++)
			{
				MDObject* obj2 = [ [ MDObject alloc ] initWithObject:[ [ selected selectedValueAtIndex:z ] objectForKey:@"Object" ] ];
				[ oldObject addObject:obj2 ];
			}
		}
		else if (currentMode == MD_VERTEX_MODE)
		{
			objPerform = TRUE;
			oldObject = [ [ NSMutableArray alloc ] init ];
			MDPoint* obj2 = [ [ MDPoint alloc ] initWithPoint:[ selected fullValueAtIndex:0 ] ];
			[ oldObject addObject:obj2 ];
			MDInstance* inst = [ [ MDInstance alloc ] initWithInstance:[ [ selected fullValueAtIndex:0 ] instance ] ];
			[ oldObject addObject:inst ];
		}
	}
	float value = [ [ [ item dictionary ] objectForKey:@"Value" ] floatValue ];
	if ([ [ item title ] isEqualToString:@"Translate X" ] && objPerform)
	{
		move = MD_MOVE;
		moveVert = MD_X;
		initialMove = obj.translateX;
		targetMove = value;
	}
	else if ([ [ item title ] isEqualToString:@"Translate Y" ] && objPerform)
	{
		move = MD_MOVE;
		moveVert = MD_Y;
		initialMove = obj.translateY;
		targetMove = value;
	}
	else if ([ [ item title ] isEqualToString:@"Translate Z" ] && objPerform)
	{
		move = MD_MOVE;
		moveVert = MD_Z;
		initialMove = obj.translateZ;
		targetMove = value;
	}
	else if ([ [ item title ] isEqualToString:@"Scale X" ] && objPerform)
	{
		move = MD_SIZE;
		moveVert = MD_X;
		initialMove = obj.scaleX;
		targetMove = value;
	}
	else if ([ [ item title ] isEqualToString:@"Scale Y" ] && objPerform)
	{
		move = MD_SIZE;
		moveVert = MD_Y;
		initialMove = obj.scaleY;
		targetMove = value;
	}
	else if ([ [ item title ] isEqualToString:@"Scale Z" ] && objPerform)
	{
		move = MD_SIZE;
		moveVert = MD_Z;
		initialMove = obj.scaleZ;
		targetMove = value;
	}
	else if ([ [ item title ] isEqualToString:@"Rotate Axis X" ] && objPerform)
	{
		move = MD_ROTATE;
		moveVert = MD_X;
		initialMove = obj.rotateAxis.x;
		targetMove = value;
	}
	else if ([ [ item title ] isEqualToString:@"Rotate Axis Y" ] && objPerform)
	{
		move = MD_ROTATE;
		moveVert = MD_Y;
		initialMove = obj.rotateAxis.y;
		targetMove = value;
	}
	else if ([ [ item title ] isEqualToString:@"Rotate Axis Z" ] && objPerform)
	{
		move = MD_ROTATE;
		moveVert = MD_Z;
		initialMove = obj.rotateAxis.z;
		targetMove = value;
	}
	else if ([ [ item title ] isEqualToString:@"Rotate Angle" ] && objPerform)
	{
		move = MD_ROTATE_ANGLE;
		initialMove = obj.rotateAngle;
		targetMove = value;
	}
	/*else if ([ [ item title ] isEqualToString:@"Rotate Point X" ] && objPerform)
	{
		move = MD_ROTATE_POINT;
		moveVert = MD_X;
		initialMove = obj.rotatePoint.x;
		targetMove = value;
	}
	else if ([ [ item title ] isEqualToString:@"Rotate Point Y" ] && objPerform)
	{
		move = MD_ROTATE_POINT;
		moveVert = MD_Y;
		initialMove = obj.rotatePoint.y;
		targetMove = value;
	}
	else if ([ [ item title ] isEqualToString:@"Rotate Point Z" ] && objPerform)
	{
		move = MD_ROTATE_POINT;
		moveVert = MD_Z;
		initialMove = obj.rotatePoint.z;
		targetMove = value;
	}*/
	else if ([ [ [ [ item parentItem ] parentItem ] title ] hasPrefix:@"Point " ])
	{
		if ([ [ item title ] isEqualToString:@"Midpoint X" ])
		{
			move = MD_POINT_MID;
			moveVert = MD_X;
			initialMove = [ (MDPoint*)[ selected fullValueAtIndex:0 ] x ];
			targetMove = value;
		}
		else if ([ [ item title ] isEqualToString:@"Midpoint Y" ])
		{
			move = MD_POINT_MID;
			moveVert = MD_Y;
			initialMove = [ (MDPoint*)[ selected fullValueAtIndex:0 ] y ];
			targetMove = value;
		}
		else if ([ [ item title ] isEqualToString:@"Midpoint Z" ])
		{
			move = MD_POINT_MID;
			moveVert = MD_Z;
			initialMove = [ (MDPoint*)[ selected fullValueAtIndex:0 ] z ];
			targetMove = value;
		}
		else if ([ [ item title ] isEqualToString:@"Normal X" ])
		{
			move = MD_POINT_NORMAL;
			moveVert = MD_X;
			initialMove = [ (MDPoint*)[ selected fullValueAtIndex:0 ] x ];
			targetMove = value;
		}
		else if ([ [ item title ] isEqualToString:@"Normal Y" ])
		{
			move = MD_POINT_NORMAL;
			moveVert = MD_Y;
			initialMove = [ (MDPoint*)[ selected fullValueAtIndex:0 ] y ];
			targetMove = value;
		}
		else if ([ [ item title ] isEqualToString:@"Normal Z" ])
		{
			move = MD_POINT_NORMAL;
			moveVert = MD_Z;
			initialMove = [ (MDPoint*)[ selected fullValueAtIndex:0 ] z ];
			targetMove = value;
		}
		else if ([ [ item title ] isEqualToString:@"Texture X" ])
		{
			move = MD_POINT_NORMAL;
			moveVert = MD_X;
			initialMove = [ (MDPoint*)[ selected fullValueAtIndex:0 ] x ];
			targetMove = value;
		}
		else if ([ [ item title ] isEqualToString:@"Texture Y" ])
		{
			move = MD_POINT_NORMAL;
			moveVert = MD_Y;
			initialMove = [ (MDPoint*)[ selected fullValueAtIndex:0 ] y ];
			targetMove = value;
		}
	}
	else if ([ [ item title ] isEqualToString:@"Midpoint X" ] && objPerform)
	{
		move = MD_POINT;
		moveVert = MD_X;
		initialMove = [ (MDPoint*)[ selected fullValueAtIndex:0 ] x ];
		targetMove = value;
	}
	else if ([ [ item title ] isEqualToString:@"Midpoint Y" ] && objPerform)
	{
		move = MD_POINT;
		moveVert = MD_Y;
		initialMove = [ (MDPoint*)[ selected fullValueAtIndex:0 ] y ];
		targetMove = value;
	}
	else if ([ [ item title ] isEqualToString:@"Midpoint Z" ] && objPerform)
	{
		move = MD_POINT;
		moveVert = MD_Z;
		initialMove = [ (MDPoint*)[ selected fullValueAtIndex:0 ] z ];
		targetMove = value;
	}
	else if ([ [ item title ] isEqualToString:@"Normal X" ])
	{
		move = MD_NORMAL;
		moveVert = MD_X;
		if (currentMode == MD_VERTEX_MODE)
		{
			initialMove = [ (MDPoint*)[ selected fullValueAtIndex:0 ] normalX ];
			targetPoint = [ selected fullValueAtIndex:0 ];
		}
		else
		{
			unsigned long point = [ [ [ [ [ item parentItem ] parentItem ] title ] substringFromIndex:6 ] integerValue ];
			unsigned long face = NSNotFound;
			if ([ [ [ [ [ item parentItem ] parentItem ] parentItem ] title ] hasPrefix:@"Face " ])
				face = [ [ [ [ [ [ item parentItem ] parentItem ] parentItem ] title ] substringFromIndex:5 ] integerValue ];
			if (face == NSNotFound)
			{
				targetPoint = [ [ selected fullValueAtIndex:0 ] pointAtIndex:point ];
				initialMove = [ [ [ selected fullValueAtIndex:0 ] pointAtIndex:point ] normalX ];
			}
			else
			{
				targetPoint = [ [ [ selected selectedValueAtIndex:0 ] objectForKey:@"Object" ] pointAtIndex:point ];
				initialMove = [ [ [ [ selected selectedValueAtIndex:0 ] objectForKey:@"Object" ] pointAtIndex:point ] normalX ];
			}
		}
		targetMove = value;
	}
	else if ([ [ item title ] isEqualToString:@"Normal Y" ])
	{
		move = MD_NORMAL;
		moveVert = MD_Y;
		if (currentMode == MD_VERTEX_MODE)
		{
			initialMove = [ (MDPoint*)[ selected fullValueAtIndex:0 ] normalY ];
			targetPoint = [ selected fullValueAtIndex:0 ];
		}
		else
		{
			unsigned long point = [ [ [ [ [ item parentItem ] parentItem ] title ] substringFromIndex:6 ] integerValue ];
			unsigned long face = NSNotFound;
			if ([ [ [ [ [ item parentItem ] parentItem ] parentItem ] title ] hasPrefix:@"Face " ])
				face = [ [ [ [ [ [ item parentItem ] parentItem ] parentItem ] title ] substringFromIndex:5 ] integerValue ];
			if (face == NSNotFound)
			{
				targetPoint = [ [ selected fullValueAtIndex:0 ] pointAtIndex:point ];
				initialMove = [ [ [ selected fullValueAtIndex:0 ] pointAtIndex:point ] normalY ];
			}
			else
			{
				targetPoint = [ [ [ selected selectedValueAtIndex:0 ] objectForKey:@"Object" ] pointAtIndex:point ];
				initialMove = [ [ [ [ selected selectedValueAtIndex:0 ] objectForKey:@"Object" ] pointAtIndex:point ] normalY ];
			}
		}
		targetMove = value;
	}
	else if ([ [ item title ] isEqualToString:@"Normal Z" ])
	{
		move = MD_NORMAL;
		moveVert = MD_Z;
		if (currentMode == MD_VERTEX_MODE)
		{
			initialMove = [ (MDPoint*)[ selected fullValueAtIndex:0 ] normalZ ];
			targetPoint = [ selected fullValueAtIndex:0 ];
		}
		else
		{
			unsigned long point = [ [ [ [ [ item parentItem ] parentItem ] title ] substringFromIndex:6 ] integerValue ];
			unsigned long face = NSNotFound;
			if ([ [ [ [ [ item parentItem ] parentItem ] parentItem ] title ] hasPrefix:@"Face " ])
				face = [ [ [ [ [ [ item parentItem ] parentItem ] parentItem ] title ] substringFromIndex:5 ] integerValue ];
			if (face == NSNotFound)
			{
				targetPoint = [ [ selected fullValueAtIndex:0 ] pointAtIndex:point ];
				initialMove = [ [ [ selected fullValueAtIndex:0 ] pointAtIndex:point ] normalZ ];
			}
			else
			{
				targetPoint = [ [ [ selected selectedValueAtIndex:0 ] objectForKey:@"Object" ] pointAtIndex:point ];
				initialMove = [ [ [ [ selected selectedValueAtIndex:0 ] objectForKey:@"Object" ] pointAtIndex:point ] normalZ ];
			}
		}
		targetMove = value;
	}
	else if ([ [ item title ] isEqualToString:@"X Position" ])
	{
		move = MD_SCENE;
		moveVert = MD_X;
		initialMove = translationPoint.x;
		targetMove = value;
	}
	else if ([ [ item title ] isEqualToString:@"Y Position" ])
	{
		move = MD_SCENE;
		moveVert = MD_Y;
		initialMove = translationPoint.y;
		targetMove = value;
	}
	else if ([ [ item title ] isEqualToString:@"Z Position" ])
	{
		move = MD_SCENE;
		moveVert = MD_Z;
		initialMove = translationPoint.z;
		targetMove = value;
	}
	else if ([ [ item title ] isEqualToString:@"X Look" ])
	{
		move = MD_LOOK;
		moveVert = MD_X;
		initialMove = lookPoint.x;
		targetMove = value;
	}
	else if ([ [ item title ] isEqualToString:@"Y Look" ])
	{
		move = MD_LOOK;
		moveVert = MD_Y;
		initialMove = lookPoint.y;
		targetMove = value;
	}
	else if ([ [ item title ] isEqualToString:@"Z Look" ])
	{
		move = MD_LOOK;
		moveVert = MD_Z;
		initialMove = lookPoint.z;
		targetMove = value;
	}
	else if ([ [ item title ] isEqualToString:@"X" ])
	{
		move = MD_POINT_MOVE;
		moveVert = MD_X;
		unsigned long point = [ [ [ [ item parentItem ] title ] substringFromIndex:6 ] integerValue ];
		unsigned long face = NSNotFound;
		if ([ [ [ [ item parentItem ] parentItem ] title ] hasPrefix:@"Face " ])
			face = [ [ [ [ [ item parentItem ] parentItem ] title ] substringFromIndex:5 ] integerValue ];
		if (face == NSNotFound)
			targetPoint = [ [ selected fullValueAtIndex:0 ] pointAtIndex:point ];
		else
			targetPoint = [ [ [ selected fullValueAtIndex:0 ] objectForKey:@"Object" ] pointAtIndex:point ];
		initialMove = targetPoint.x;
		targetMove = value;
	}
	else if ([ [ item title ] isEqualToString:@"Y" ])
	{
		move = MD_POINT_MOVE;
		moveVert = MD_Y;
		unsigned long point = [ [ [ [ item parentItem ] title ] substringFromIndex:6 ] integerValue ];
		unsigned long face = NSNotFound;
		if ([ [ [ [ item parentItem ] parentItem ] title ] hasPrefix:@"Face " ])
			face = [ [ [ [ [ item parentItem ] parentItem ] title ] substringFromIndex:5 ] integerValue ];
		if (face == NSNotFound)
			targetPoint = [ [ selected fullValueAtIndex:0 ] pointAtIndex:point ];
		else
			targetPoint = [ [ [ selected fullValueAtIndex:0 ] objectForKey:@"Object" ] pointAtIndex:point ];
		initialMove = targetPoint.y;
		targetMove = value;
	}
	else if ([ [ item title ] isEqualToString:@"Z" ])
	{
		move = MD_POINT_MOVE;
		moveVert = MD_Z;
		unsigned long point = [ [ [ [ item parentItem ] title ] substringFromIndex:6 ] integerValue ];
		unsigned long face = NSNotFound;
		if ([ [ [ [ item parentItem ] parentItem ] title ] hasPrefix:@"Face " ])
			face = [ [ [ [ [ item parentItem ] parentItem ] title ] substringFromIndex:5 ] integerValue ];
		if (face == NSNotFound)
			targetPoint = [ [ selected fullValueAtIndex:0 ] pointAtIndex:point ];
		else
			targetPoint = [ [ [ selected fullValueAtIndex:0 ] objectForKey:@"Object" ] pointAtIndex:point ];
		initialMove = targetPoint.z;
		targetMove = value;
	}
	else if ([ [ [ item parentItem ] title ] isEqualToString:@"Color" ] && ([ [ item title ] isEqualToString:@"Red" ] || [ [ item title ] isEqualToString:@"Green" ] || [ [ item title ] isEqualToString:@"Blue" ] || [ [ item title ] isEqualToString:@"Alpha" ]))
	{
		IFNode* color = [ [ [ infoTable rootNode ] childWithTitle:@"General Attributes" ] childWithTitle:@"Color" ];
		float red = [ [ [ [ color childWithTitle:@"Red" ] dictionary ] objectForKey:@"Value" ] floatValue ];
		float green = [ [ [ [ color childWithTitle:@"Green" ] dictionary ] objectForKey:@"Value" ] floatValue ];
		float blue = [ [ [ [ color childWithTitle:@"Blue" ] dictionary ] objectForKey:@"Value" ] floatValue ];
		float alpha = [ [ [ [ color childWithTitle:@"Alpha" ] dictionary ] objectForKey:@"Value" ] floatValue ];
		
		MDVector4 p = [ [ selected fullValueAtIndex:0 ] midColor ];
		InitColor(p.x, p.y, p.z, p.w);
		SetColor(red, green, blue, alpha);
		move = MD_OBJECT_COLOR;
	}
	else if ([ [ [ item parentItem ] title ] isEqualToString:@"Color" ] && ([ [ item title ] isEqualToString:@"Object Red" ] || [ [ item title ] isEqualToString:@"Object Green" ] || [ [ item title ] isEqualToString:@"Object Blue" ] || [ [ item title ] isEqualToString:@"Object Alpha" ]))
	{
		IFNode* color = [ [ [ infoTable rootNode ] childWithTitle:@"General Attributes" ] childWithTitle:@"Color" ];
		float red = [ [ [ [ color childWithTitle:@"Object Red" ] dictionary ] objectForKey:@"Value" ] floatValue ];
		float green = [ [ [ [ color childWithTitle:@"Object Green" ] dictionary ] objectForKey:@"Value" ] floatValue ];
		float blue = [ [ [ [ color childWithTitle:@"Object Blue" ] dictionary ] objectForKey:@"Value" ] floatValue ];
		float alpha = [ [ [ [ color childWithTitle:@"Object Alpha" ] dictionary ] objectForKey:@"Value" ] floatValue ];
		
		MDVector4 p = [ [ selected fullValueAtIndex:0 ] colorMultiplier ];
		InitColor(p.x, p.y, p.z, p.w);
		SetColor(red, green, blue, alpha);
		move = MD_OBJECT_COLOR_MULTIPLY;
	}
	/*else if ([ [ item title ] isEqualToString:@"Red" ] || [ [ item title ] isEqualToString:@"Green" ] || [ [ item title ] isEqualToString:@"Blue" ] || [ [ item title ] isEqualToString:@"Alpha" ])
	{
		unsigned long point = [ [ [ [ item parentItem ] title ] substringFromIndex:6 ] integerValue ];
		unsigned long face = NSNotFound;
		if ([ [ [ [ item parentItem ] parentItem ] title ] hasPrefix:@"Face " ])
			face = [ [ [ [ [ item parentItem ] parentItem ] title ] substringFromIndex:5 ] integerValue ];
		if (face == NSNotFound)
			targetPoint = [ [ selected fullValueAtIndex:0 ] pointAtIndex:point ];
		else
			targetPoint = [ [ [ selected fullValueAtIndex:0 ] objectForKey:@"Object" ] pointAtIndex:point ];
		InitColor(targetPoint.red, targetPoint.green, targetPoint.blue, targetPoint.alpha);
		float red = [ [ [ [ [ item parentItem ] childWithTitle:@"Red" ] dictionary ] objectForKey:@"Value" ] floatValue ];
		float green = [ [ [ [ [ item parentItem ] childWithTitle:@"Green" ] dictionary ] objectForKey:@"Value" ] floatValue ];
		float blue = [ [ [ [ [ item parentItem ] childWithTitle:@"Blue" ] dictionary ] objectForKey:@"Value" ] floatValue ];
		float alpha = [ [ [ [ [ item parentItem ] childWithTitle:@"Alpha" ] dictionary ] objectForKey:@"Value" ] floatValue ];
		SetColor(red, green, blue, alpha);
		move = MD_POINT_COLOR;
	}*/
	else if ([ [ item title ] isEqualToString:@"Specular Red" ] || [ [ item title ] isEqualToString:@"Specular Green" ] || [ [ item title ] isEqualToString:@"Specular Blue" ] || [ [ item title ] isEqualToString:@"Specular Alpha" ])
	{
		IFNode* color = [ [ [ infoTable rootNode ] childWithTitle:@"General Attributes" ] childWithTitle:@"Color" ];
		float red = [ [ [ [ color childWithTitle:@"Specular Red" ] dictionary ] objectForKey:@"Value" ] floatValue ];
		float green = [ [ [ [ color childWithTitle:@"Specular Green" ] dictionary ] objectForKey:@"Value" ] floatValue ];
		float blue = [ [ [ [ color childWithTitle:@"Specular Blue" ] dictionary ] objectForKey:@"Value" ] floatValue ];
		float alpha = [ [ [ [ color childWithTitle:@"Specular Alpha" ] dictionary ] objectForKey:@"Value" ] floatValue ];
		
		MDVector4 p = [ [ selected fullValueAtIndex:0 ] specularColor ];
		InitColor(p.x, p.y, p.z, p.w);
		SetColor(red, green, blue, alpha);
		move = MD_SPECULAR_COLOR;
	}
	else if ([ [ item title ] isEqualToString:@"Shininess" ])
	{
		initialMove = [ [ selected fullValueAtIndex:0 ] shininess ];
		targetMove = value;
		move = MD_SHININESS;
	}
	else if ([ [ item title ] isEqualToString:@"X Rotation" ])
		[ [ views objectAtIndex:0 ] setXRotation:value show:YES ];
	else if ([ [ item title ] isEqualToString:@"Y Rotation" ])
		[ [ views objectAtIndex:0 ] setYRotation:value show:YES ];
	else if ([ [ item title ] isEqualToString:@"Z Rotation" ])
		[ [ views objectAtIndex:0 ] setZRotation:value show:YES ];
	
	unsigned long row = -1;
	for (unsigned long z = 0; z < [ otherObjects count ]; z++)
	{
		if ([ [ otherObjects objectAtIndex:z ] selected ] || ([ [ otherObjects objectAtIndex:z ] isKindOfClass:[ MDCamera class ] ] && [ [ otherObjects objectAtIndex:z ] lookSelected ]))
		{
			row = z;
			break;
		}
	}
	if (row == -1)
		return;
	
	if ([ [ item title ] isEqualToString:@"Visible" ])
	{
		move = MD_VISIBLE;
		targetMove =  [ [ [ item dictionary ] valueForKey:@"Value" ] floatValue ];
		initialMove = [ [ otherObjects objectAtIndex:row ] show ];
	}
	else if ([ [ otherObjects objectAtIndex:row ] isKindOfClass:[ MDCamera class ] ])
	{
		MDCamera* camera = [ otherObjects objectAtIndex:row ];
		if (![ camera lookSelected ] && ![ camera selected ])
			[ camera setSelected:YES ];
		oldOther = [ [ MDCamera alloc ] initWithMDCamera:[ otherObjects objectAtIndex:row ] ];
		if ([ [ [ item parentItem ] title ] isEqualToString:@"Midpoint" ])
		{
			if ([ [ item title ] isEqualToString:@"X" ])
			{
				move = MD_CAMERA_MID;
				targetMove = [ [ [ item dictionary ] valueForKey:@"Value" ] floatValue ];
				initialMove = [ (MDCamera*)[ otherObjects objectAtIndex:row ] midPoint ].x;
				moveVert = MD_X;
			}
			else if ([ [ item title ] isEqualToString:@"Y" ])
			{
				move = MD_CAMERA_MID;
				targetMove = [ [ [ item dictionary ] valueForKey:@"Value" ] floatValue ];
				initialMove = [ (MDCamera*)[ otherObjects objectAtIndex:row ] midPoint ].y;
				moveVert = MD_Y;
			}
			else if ([ [ item title ] isEqualToString:@"Z" ])
			{
				move = MD_CAMERA_MID;
				targetMove = [ [ [ item dictionary ] valueForKey:@"Value" ] floatValue ];
				initialMove = [ (MDCamera*)[ otherObjects objectAtIndex:row ] midPoint ].z;
				moveVert = MD_Z;
			}
		}
		else if ([ [ [ item parentItem ] title ] isEqualToString:@"Lookpoint" ])
		{
			if ([ [ item title ] isEqualToString:@"X" ])
			{
				move = MD_CAMERA_LOOK;
				targetMove = [ [ [ item dictionary ] valueForKey:@"Value" ] floatValue ];
				initialMove = [ (MDCamera*)[ otherObjects objectAtIndex:row ] lookPoint ].x;
				moveVert = MD_X;
			}
			else if ([ [ item title ] isEqualToString:@"Y" ])
			{
				move = MD_CAMERA_LOOK;
				targetMove = [ [ [ item dictionary ] valueForKey:@"Value" ] floatValue ];
				initialMove = [ (MDCamera*)[ otherObjects objectAtIndex:row ] lookPoint ].y;
				moveVert = MD_Y;
			}
			else if ([ [ item title ] isEqualToString:@"Z" ])
			{
				move = MD_CAMERA_LOOK;
				targetMove = [ [ [ item dictionary ] valueForKey:@"Value" ] floatValue ];
				initialMove = [ (MDCamera*)[ otherObjects objectAtIndex:row ] lookPoint ].z;
				moveVert = MD_Z;
			}
		}
		else if ([ [ item title ] isEqualToString:@"Orientation" ])
		{
			move = MD_CAMERA_OR;
			targetMove =  [ [ [ item dictionary ] valueForKey:@"Value" ] floatValue ];
			initialMove = [ (MDCamera*)[ otherObjects objectAtIndex:row ] orientation ];
		}
		else if ([ [ item title ] isEqualToString:@"Use" ])
		{
			move = MD_USE;
			targetMove =  [ [ [ item dictionary ] valueForKey:@"Value" ] floatValue ];
			initialMove = [ (MDCamera*)[ otherObjects objectAtIndex:row ] use ];
		}
	}
	else if ([ [ otherObjects objectAtIndex:row ] isKindOfClass:[ MDLight class ] ])
	{
		MDLight* light = [ otherObjects objectAtIndex:row ];
		if (![ light selected ])
			[ light setSelected:YES ];
		oldOther = [ [ MDLight alloc ] initWithMDLight:[ otherObjects objectAtIndex:row ] ];
		if ([ [ [ item parentItem ] title ] isEqualToString:@"Midpoint" ])
		{
			if ([ [ item title ] isEqualToString:@"X" ])
			{
				move = MD_CAMERA_MID;
				targetMove = [ [ [ item dictionary ] valueForKey:@"Value" ] floatValue ];
				initialMove = [ (MDLight*)[ otherObjects objectAtIndex:row ] position ].x;
				moveVert = MD_X;
			}
			else if ([ [ item title ] isEqualToString:@"Y" ])
			{
				move = MD_CAMERA_MID;
				targetMove = [ [ [ item dictionary ] valueForKey:@"Value" ] floatValue ];
				initialMove = [ (MDLight*)[ otherObjects objectAtIndex:row ] position ].y;
				moveVert = MD_Y;
			}
			else if ([ [ item title ] isEqualToString:@"Z" ])
			{
				move = MD_CAMERA_MID;
				targetMove = [ [ [ item dictionary ] valueForKey:@"Value" ] floatValue ];
				initialMove = [ (MDLight*)[ otherObjects objectAtIndex:row ] position ].z;
				moveVert = MD_Z;
			}
		}
		else if ([ [ [ item parentItem ] title ] isEqualToString:@"Lookpoint" ])
		{
			if ([ [ item title ] isEqualToString:@"X" ])
			{
				move = MD_CAMERA_LOOK;
				targetMove = [ [ [ item dictionary ] valueForKey:@"Value" ] floatValue ];
				initialMove = [ (MDLight*)[ otherObjects objectAtIndex:row ] spotDirection ].x;
				moveVert = MD_X;
			}
			else if ([ [ item title ] isEqualToString:@"Y" ])
			{
				move = MD_CAMERA_LOOK;
				targetMove = [ [ [ item dictionary ] valueForKey:@"Value" ] floatValue ];
				initialMove = [ (MDLight*)[ otherObjects objectAtIndex:row ] spotDirection ].y;
				moveVert = MD_Y;
			}
			else if ([ [ item title ] isEqualToString:@"Z" ])
			{
				move = MD_CAMERA_LOOK;
				targetMove = [ [ [ item dictionary ] valueForKey:@"Value" ] floatValue ];
				initialMove = [ (MDLight*)[ otherObjects objectAtIndex:row ] spotDirection ].z;
				moveVert = MD_Z;
			}
		}
		else if ([ [ [ item parentItem ] title ] isEqualToString:@"Colors" ])
		{
			if ([ [ item title ] isEqualToString:@"Ambient Red" ])
			{
				move = MD_LIGHT_AMBIENT;
				targetMove = [ [ [ item dictionary ] valueForKey:@"Value" ] floatValue ];
				initialMove = [ (MDLight*)[ otherObjects objectAtIndex:row ] ambientColor ].x;
				moveVert = MD_X;
			}
			else if ([ [ item title ] isEqualToString:@"Ambient Green" ])
			{
				move = MD_LIGHT_AMBIENT;
				targetMove = [ [ [ item dictionary ] valueForKey:@"Value" ] floatValue ];
				initialMove = [ (MDLight*)[ otherObjects objectAtIndex:row ] ambientColor ].y;
				moveVert = MD_Y;
			}
			else if ([ [ item title ] isEqualToString:@"Ambient Blue" ])
			{
				move = MD_LIGHT_AMBIENT;
				targetMove = [ [ [ item dictionary ] valueForKey:@"Value" ] floatValue ];
				initialMove = [ (MDLight*)[ otherObjects objectAtIndex:row ] ambientColor ].z;
				moveVert = MD_Z;
			}
			else if ([ [ item title ] isEqualToString:@"Ambient Alpha" ])
			{
				move = MD_LIGHT_AMBIENT;
				targetMove = [ [ [ item dictionary ] valueForKey:@"Value" ] floatValue ];
				initialMove = [ (MDLight*)[ otherObjects objectAtIndex:row ] ambientColor ].w;
				moveVert = MD_A;
			}
			else if ([ [ item title ] isEqualToString:@"Diffuse Red" ])
			{
				move = MD_LIGHT_DIFFUSE;
				targetMove = [ [ [ item dictionary ] valueForKey:@"Value" ] floatValue ];
				initialMove = [ (MDLight*)[ otherObjects objectAtIndex:row ] diffuseColor ].x;
				moveVert = MD_X;
			}
			else if ([ [ item title ] isEqualToString:@"Diffuse Green" ])
			{
				move = MD_LIGHT_DIFFUSE;
				targetMove = [ [ [ item dictionary ] valueForKey:@"Value" ] floatValue ];
				initialMove = [ (MDLight*)[ otherObjects objectAtIndex:row ] diffuseColor ].y;
				moveVert = MD_Y;
			}
			else if ([ [ item title ] isEqualToString:@"Diffuse Blue" ])
			{
				move = MD_LIGHT_DIFFUSE;
				targetMove = [ [ [ item dictionary ] valueForKey:@"Value" ] floatValue ];
				initialMove = [ (MDLight*)[ otherObjects objectAtIndex:row ] diffuseColor ].z;
				moveVert = MD_Z;
			}
			else if ([ [ item title ] isEqualToString:@"Diffuse Alpha" ])
			{
				move = MD_LIGHT_DIFFUSE;
				targetMove = [ [ [ item dictionary ] valueForKey:@"Value" ] floatValue ];
				initialMove = [ (MDLight*)[ otherObjects objectAtIndex:row ] diffuseColor ].w;
				moveVert = MD_A;
			}
			else if ([ [ item title ] isEqualToString:@"Specular Red" ])
			{
				move = MD_LIGHT_SPECULAR;
				targetMove = [ [ [ item dictionary ] valueForKey:@"Value" ] floatValue ];
				initialMove = [ (MDLight*)[ otherObjects objectAtIndex:row ] specularColor ].x;
				moveVert = MD_X;
			}
			else if ([ [ item title ] isEqualToString:@"Specular Green" ])
			{
				move = MD_LIGHT_SPECULAR;
				targetMove = [ [ [ item dictionary ] valueForKey:@"Value" ] floatValue ];
				initialMove = [ (MDLight*)[ otherObjects objectAtIndex:row ] specularColor ].y;
				moveVert = MD_Y;
			}
			else if ([ [ item title ] isEqualToString:@"Specular Blue" ])
			{
				move = MD_LIGHT_SPECULAR;
				targetMove = [ [ [ item dictionary ] valueForKey:@"Value" ] floatValue ];
				initialMove = [ (MDLight*)[ otherObjects objectAtIndex:row ] specularColor ].z;
				moveVert = MD_Z;
			}
			else if ([ [ item title ] isEqualToString:@"Specular Alpha" ])
			{
				move = MD_LIGHT_SPECULAR;
				targetMove = [ [ [ item dictionary ] valueForKey:@"Value" ] floatValue ];
				initialMove = [ (MDLight*)[ otherObjects objectAtIndex:row ] specularColor ].w;
				moveVert = MD_A;
			}
		}
		else if ([ [ [ item parentItem ] title ] isEqualToString:@"Spot" ])
		{
			if ([ [ item title ] isEqualToString:@"Exponent" ])
			{
				move = MD_LIGHT_SPOT;
				targetMove = [ [ [ item dictionary ] valueForKey:@"Value" ] floatValue ];
				initialMove = [ (MDLight*)[ otherObjects objectAtIndex:row ] spotExp ];
				moveVert = MD_X;
			}
			else if ([ [ item title ] isEqualToString:@"Cutoff" ])
			{
				move = MD_LIGHT_SPOT;
				targetMove = [ [ [ item dictionary ] valueForKey:@"Value" ] floatValue ];
				initialMove = [ (MDLight*)[ otherObjects objectAtIndex:row ] spotCut ];
				moveVert = MD_Y;
			}
			else if ([ [ item title ] isEqualToString:@"Angle Cutoff" ])
			{
				move = MD_LIGHT_SPOT;
				targetMove = [ [ [ item dictionary ] valueForKey:@"Value" ] floatValue ];
				initialMove = [ (MDLight*)[ otherObjects objectAtIndex:row ] spotAngle ];
				moveVert = MD_Z;
			}
		}
		else if ([ [ [ item parentItem ] title ] isEqualToString:@"Attenuation" ])
		{
			if ([ [ item title ] isEqualToString:@"Constant" ])
			{
				move = MD_LIGHT_ATTENUATION;
				targetMove = [ [ [ item dictionary ] valueForKey:@"Value" ] floatValue ];
				initialMove = [ (MDLight*)[ otherObjects objectAtIndex:row ] constAtt ];
				moveVert = MD_X;
			}
			else if ([ [ item title ] isEqualToString:@"Linear" ])
			{
				move = MD_LIGHT_ATTENUATION;
				targetMove = [ [ [ item dictionary ] valueForKey:@"Value" ] floatValue ];
				initialMove = [ (MDLight*)[ otherObjects objectAtIndex:row ] linAtt ];
				moveVert = MD_Y;
			}
			else if ([ [ item title ] isEqualToString:@"Quadratic" ])
			{
				move = MD_LIGHT_ATTENUATION;
				targetMove = [ [ [ item dictionary ] valueForKey:@"Value" ] floatValue ];
				initialMove = [ (MDLight*)[ otherObjects objectAtIndex:row ] quadAtt ];
				moveVert = MD_Z;
			}
		}
		else if ([ [ [ item parentItem ] title ] isEqualToString:@"Shadows" ])
		{
			if ([ [ item title ] isEqualToString:@"Enable Shadows" ])
			{
				move = MD_LIGHT_SHADOW_ENABLE;
				targetMove = [ [ [ item dictionary ] valueForKey:@"Value" ] floatValue ];
				initialMove = [ (MDLight*)[ otherObjects objectAtIndex:row ] enableShadows ];
			}
			else if ([ [ item title ] isEqualToString:@"Static" ])
			{
				move = MD_LIGHT_STATIC_ENABLE;
				targetMove = [ [ [ item dictionary ] valueForKey:@"Value" ] floatValue ];
				initialMove = [ (MDLight*)[ otherObjects objectAtIndex:row ] isStatic ];
			}
		}
	}
	else if ([ [ otherObjects objectAtIndex:row ] isKindOfClass:[ MDParticleEngine class ] ])
	{
		MDParticleEngine* engine = [ otherObjects objectAtIndex:row ];
		if (![ engine selected ])
			[ engine setSelected:YES ];
		oldOther = [ [ MDParticleEngine alloc ] initWithMDParticleEngine:[ otherObjects objectAtIndex:row ] ];
		if ([ [ [ item parentItem ] title ] isEqualToString:@"Midpoint" ])
		{
			if ([ [ item title ] isEqualToString:@"X" ])
			{
				move = MD_CAMERA_MID;
				targetMove = [ [ [ item dictionary ] valueForKey:@"Value" ] floatValue ];
				initialMove = [ (MDParticleEngine*)[ otherObjects objectAtIndex:row ] position ].x;
				moveVert = MD_X;
			}
			else if ([ [ item title ] isEqualToString:@"Y" ])
			{
				move = MD_CAMERA_MID;
				targetMove = [ [ [ item dictionary ] valueForKey:@"Value" ] floatValue ];
				initialMove = [ (MDParticleEngine*)[ otherObjects objectAtIndex:row ] position ].y;
				moveVert = MD_Y;
			}
			else if ([ [ item title ] isEqualToString:@"Z" ])
			{
				move = MD_CAMERA_MID;
				targetMove = [ [ [ item dictionary ] valueForKey:@"Value" ] floatValue ];
				initialMove = [ (MDParticleEngine*)[ otherObjects objectAtIndex:row ] position ].z;
				moveVert = MD_Z;
			}
		}
		else if ([ [ [ item parentItem ] title ] isEqualToString:@"Particle Colors" ])
		{
			if ([ [ item title ] isEqualToString:@"Start Red" ])
			{
				move = MD_PARTICLE_START;
				targetMove = [ [ [ item dictionary ] valueForKey:@"Value" ] floatValue ];
				initialMove = [ (MDParticleEngine*)[ otherObjects objectAtIndex:row ] startColor ].x;
				moveVert = MD_X;
			}
			else if ([ [ item title ] isEqualToString:@"Start Green" ])
			{
				move = MD_PARTICLE_START;
				targetMove = [ [ [ item dictionary ] valueForKey:@"Value" ] floatValue ];
				initialMove = [ (MDParticleEngine*)[ otherObjects objectAtIndex:row ] startColor ].y;
				moveVert = MD_Y;
			}
			else if ([ [ item title ] isEqualToString:@"Start Blue" ])
			{
				move = MD_PARTICLE_START;
				targetMove = [ [ [ item dictionary ] valueForKey:@"Value" ] floatValue ];
				initialMove = [ (MDParticleEngine*)[ otherObjects objectAtIndex:row ] startColor ].z;
				moveVert = MD_Z;
			}
			else if ([ [ item title ] isEqualToString:@"Start Alpha" ])
			{
				move = MD_PARTICLE_START;
				targetMove = [ [ [ item dictionary ] valueForKey:@"Value" ] floatValue ];
				initialMove = [ (MDParticleEngine*)[ otherObjects objectAtIndex:row ] startColor ].w;
				moveVert = MD_A;
			}
			else if ([ [ item title ] isEqualToString:@"End Red" ])
			{
				move = MD_PARTICLE_END;
				targetMove = [ [ [ item dictionary ] valueForKey:@"Value" ] floatValue ];
				initialMove = [ (MDParticleEngine*)[ otherObjects objectAtIndex:row ] endColor ].x;
				moveVert = MD_X;
			}
			else if ([ [ item title ] isEqualToString:@"End Green" ])
			{
				move = MD_PARTICLE_END;
				targetMove = [ [ [ item dictionary ] valueForKey:@"Value" ] floatValue ];
				initialMove = [ (MDParticleEngine*)[ otherObjects objectAtIndex:row ] endColor ].y;
				moveVert = MD_Y;
			}
			else if ([ [ item title ] isEqualToString:@"End Blue" ])
			{
				move = MD_PARTICLE_END;
				targetMove = [ [ [ item dictionary ] valueForKey:@"Value" ] floatValue ];
				initialMove = [ (MDParticleEngine*)[ otherObjects objectAtIndex:row ] endColor ].z;
				moveVert = MD_Z;
			}
			else if ([ [ item title ] isEqualToString:@"End Alpha" ])
			{
				move = MD_PARTICLE_END;
				targetMove = [ [ [ item dictionary ] valueForKey:@"Value" ] floatValue ];
				initialMove = [ (MDParticleEngine*)[ otherObjects objectAtIndex:row ] endColor ].w;
				moveVert = MD_A;
			}
		}
		else if ([ [ [ item parentItem ] title ] isEqualToString:@"Velocities" ])
		{
			if ([ [ item title ] isEqualToString:@"Type" ])
			{
				[ [ otherObjects objectAtIndex:row ] setVelocityType:[ [ [ item dictionary ] valueForKey:@"Value" ] floatValue ] ];
				MDParticleEngine* engine = [ otherObjects objectAtIndex:row ];
				MDParticleEngine* currentEngine = [ [ MDParticleEngine alloc ] initWithMDParticleEngine:engine ];
				unsigned long cIndex = [ otherObjects indexOfObject:engine ];
				[ otherObjects replaceObjectAtIndex:[ otherObjects indexOfObject:engine ] withObject:oldOther ];
				[ undoManager setActionName:@"Translation" ];
				[ Controller setOtherObject:currentEngine atIndex:cIndex ];
				commandFlag |= UPDATE_OTHER_INFO;
			}
			else if ([ [ item title ] isEqualToString:@"X" ])
			{
				move = MD_PARTICLE_VELOCITIES;
				targetMove = [ [ [ item dictionary ] valueForKey:@"Value" ] floatValue ];
				initialMove = [ (MDParticleEngine*)[ otherObjects objectAtIndex:row ] velocities ].x;
				moveVert = MD_X;
			}
			else if ([ [ item title ] isEqualToString:@"Y" ])
			{
				move = MD_PARTICLE_VELOCITIES;
				targetMove = [ [ [ item dictionary ] valueForKey:@"Value" ] floatValue ];
				initialMove = [ (MDParticleEngine*)[ otherObjects objectAtIndex:row ] velocities ].y;
				moveVert = MD_Y;
			}
			else if ([ [ item title ] isEqualToString:@"Z" ])
			{
				move = MD_PARTICLE_VELOCITIES;
				targetMove = [ [ [ item dictionary ] valueForKey:@"Value" ] floatValue ];
				initialMove = [ (MDParticleEngine*)[ otherObjects objectAtIndex:row ] velocities ].z;
				moveVert = MD_Z;
			}
		}
		else if ([ [ item title ] isEqualToString:@"Particle Number" ])
		{
			move = MD_PARTICLE_NUMBER;
			targetMove =  [ [ [ item dictionary ] valueForKey:@"Value" ] floatValue ];
			initialMove = [ (MDParticleEngine*)[ otherObjects objectAtIndex:row ] numberOfParticles ];
		}
		else if ([ [ item title ] isEqualToString:@"Particle Size" ])
		{
			move = MD_PARTICLE_SIZE;
			targetMove =  [ [ [ item dictionary ] valueForKey:@"Value" ] floatValue ];
			initialMove = [ (MDParticleEngine*)[ otherObjects objectAtIndex:row ] particleSize ];
		}
		else if ([ [ item title ] isEqualToString:@"Particle Life" ])
		{
			move = MD_PARTICLE_LIFE;
			targetMove =  [ [ [ item dictionary ] valueForKey:@"Value" ] floatValue ];
			initialMove = [ (MDParticleEngine*)[ otherObjects objectAtIndex:row ] particleLife ];
		}
	}
	else if ([ [ otherObjects objectAtIndex:row ] isKindOfClass:[ MDCurve class ] ])
	{
		MDCurve* curve = [ otherObjects objectAtIndex:row ];
		if (![ curve selected ])
			[ curve setSelected:YES ];
		oldOther = [ [ MDCurve alloc ] initWithMDCurve:[ otherObjects objectAtIndex:row ] ];
		
		if ([ [ item title ] isEqualToString:@"Point Number" ])
		{
			std::vector<MDVector3> p = *[ curve curvePoints ];
			unsigned long newSize = [ [ [ item dictionary ] valueForKey:@"Value" ] intValue ];
			if (newSize > p.size())
			{
				for (unsigned long z = p.size(); z < newSize; z++)
					p.push_back(MDVector3Create(0, 0, 0));
			}
			else
			{
				while (p.size() > newSize)
					p.erase(p.end());
			}
			[ curve setPoints:p ];
			
			IFNode* points = [ [ infoTable rootNode ] childWithTitle:@"Curve Points" ];
			[ points setChildren:[ NSArray array ] ];
			for (unsigned long z = 0; z < p.size(); z++)
			{
				IFNode* row1 = [ [ IFNode alloc ] initParentWithTitle:[ NSString stringWithFormat:@"Point %li", z + 1 ] children:nil ];
				
				IFNode* rx = [ [ IFNode alloc ] initLeafWithTitle:@"X" ];
				[ rx setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", p[z].x ] forKey:@"Value" ] ];
				[ row1 addChild:rx ];
				IFNode* ry = [ [ IFNode alloc ] initLeafWithTitle:@"Y" ];
				[ ry setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", p[z].y ] forKey:@"Value" ] ];
				[ row1 addChild:ry ];
				IFNode* rz = [ [ IFNode alloc ] initLeafWithTitle:@"Z" ];
				[ rz setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", p[z].z ] forKey:@"Value" ] ];
				[ row1 addChild:rz ];
				
				[ points addChild:row1 ];
			}
			[ infoTable reloadData ];
		}
		else if ([ [ [ item parentItem ] title ] hasPrefix:@"Point " ])
		{
			unsigned long num = [ [ [ [ item parentItem ] title ] substringFromIndex:6 ] intValue ] - 1;
			std::vector<MDVector3> p = *[ curve curvePoints ];
			if (num < p.size())
			{
				moveIndex = num;
				if ([ [ item title ] isEqualToString:@"X" ])
				{
					move = MD_CURVE_POINT;
					moveVert = MD_X;
					initialMove = p[num].x;
					targetMove = [ [ [ item dictionary ] valueForKey:@"Value" ] floatValue ];
				}
				else if ([ [ item title ] isEqualToString:@"Y" ])
				{
					move = MD_CURVE_POINT;
					moveVert = MD_Y;
					initialMove = p[num].y;
					targetMove = [ [ [ item dictionary ] valueForKey:@"Value" ] floatValue ];
				}
				else if ([ [ item title ] isEqualToString:@"Z" ])
				{
					move = MD_CURVE_POINT;
					moveVert = MD_Z;
					initialMove = p[num].z;
					targetMove = [ [ [ item dictionary ] valueForKey:@"Value" ] floatValue ];
				}
			}
		}
	}
}


#pragma mark Edit Functions

- (IBAction) copy: (id) sender
{
	if ([ editorWindow isVisible ])
	{
		[ editorView copy:sender ];
		return;
	}
	
	if ([ selected count ] == 0)
		return;
	copyData.clear();
	for (int z = 0; z < [ selected count ]; z++)
	{
		MDObject* obj = [ [ MDObject alloc ] initWithObject:[ [ selected selectedValueAtIndex:z ] objectForKey:@"Object" ] ];
		[ obj setName:nil ];
		obj.translateX += 1;
		obj.translateY += 1;
		copyData.push_back(obj);
	}
	
	[ pasteMenu setAction:@selector(paste:) ];
	[ pastePlaceMenu setAction:@selector(pasteInPlace:) ];
}

- (IBAction) paste: (id) sender
{
	if ([ editorWindow isVisible ])
	{
		[ editorView paste:sender ];
		return;
	}
	
	if (copyData.size() == 0)
		return;
	NSMutableArray* array = [ NSMutableArray array ];
	for (int z = 0; z < [ objects count ]; z++)
	{
		MDObject* obj = [ [ MDObject alloc ] initWithObject:[ objects objectAtIndex:z ] ];
		[ array addObject:obj ];
	}
	MDSelection* sel = [ [ MDSelection alloc ] init ];
	for (int z = 0; z < copyData.size(); z++)
	{
		[ array addObject:copyData[z] ];
		[ sel addObject:[ array objectAtIndex:[ array count ] - 1 ] ];
	}
	[ undoManager setActionName:@"Paste" ];
	[ Controller setObjects:array selected:sel andInstances:instances ];
	[ self copy:sender ];
}

- (IBAction) pasteInPlace:(id)sender
{
	if (copyData.size() == 0)
		return;
	NSMutableArray* array = [ NSMutableArray array ];
	for (int z = 0; z < [ objects count ]; z++)
	{
		MDObject* obj = [ [ MDObject alloc ] initWithObject:[ objects objectAtIndex:z ] ];
		[ array addObject:obj ];
	}
	MDSelection* sel = [ [ MDSelection alloc ] init ];
	for (int z = 0; z < copyData.size(); z++)
	{
		copyData[z].translateX -= 1;
		copyData[z].translateY -= 1;
		[ array addObject:copyData[z] ];
		[ sel addObject:[ array objectAtIndex:[ array count ] - 1 ] ];
	}
	[ undoManager setActionName:@"Paste" ];
	[ Controller setObjects:array selected:sel andInstances:instances ];
	[ self copy:sender ];
}

- (IBAction) duplicate:(id)sender
{
	if ([ selected count ] == 0)
		return;
	
	std::vector<MDObject*> backup = copyData;
	[ self copy:sender ];
	[ self pasteInPlace:sender ];
	copyData = backup;
}

- (IBAction) cut: (id) sender
{
	if ([ editorWindow isVisible ])
	{
		[ editorView cut:sender ];
		return;
	}
	[ self copy:sender ];
	[ self deleteItem:sender ];
}

- (IBAction) deleteItem: (id) sender
{
	if ([ selected count ] == 0)
		return;
	NSMutableArray* array = [ NSMutableArray array ];
	for (int z = 0; z < [ objects count ]; z++)
	{
		MDObject* obj = [ [ MDObject alloc ] initWithObject:[ objects objectAtIndex:z ] ];
		[ array addObject:obj ];
	}
	NSMutableIndexSet* set = [ [ NSMutableIndexSet alloc ] init ];
	for (int z = 0; z < [ selected count ]; z++)
	{
		unsigned long index = [ objects indexOfObject:[ [ selected selectedValueAtIndex:z ] objectForKey:@"Object" ] ];
		if (currentMode == MD_OBJECT_MODE)
			[ set addIndex:index ];
		else if (currentMode == MD_FACE_MODE)
		{
			// Doesn't work well with mutiple faces
			/*unsigned long faceIndex = [ [ [ objects objectAtIndex:index ] faces ] indexOfObject:[ [ selected selectedValueAtIndex:z ] objectForKey:@"Face" ] ];
			[ [ [ array objectAtIndex:index ] faces ] removeObjectAtIndex:faceIndex ];*/
		}
	}
	[ array removeObjectsAtIndexes:set ];
	[ undoManager setActionName:@"Delete" ];
	MDSelection* newSel = [ [ MDSelection alloc ] init ];
	[ Controller setObjects:array selected:newSel andInstances:instances ];
	
	commandFlag |= UPDATE_INFO;
}

- (IBAction) selectAll:(id)sender
{
	[ selected clear ];
	for (int z = 0; z < [ objects count ]; z++)
	{
		if (currentMode == MD_OBJECT_MODE)
			[ selected addObject:[ objects objectAtIndex:z ] ];
		else
		{
			/*for (int q = 0; q < [ [ objects objectAtIndex:z ] numberOfFaces ]; q++)
			{
				if (currentMode == MD_FACE_MODE)
					[ selected addFace:[ [ objects objectAtIndex:z ] faceAtIndex:q ] fromObject:[ objects objectAtIndex:z ] ];
			}*/
		}
	}
	
	commandFlag |= UPDATE_INFO;
}

#pragma mark Create Shapes

- (IBAction) shape: (id) sender
{
	commandFlag &= ~SHAPE2;
	commandFlag |= SHAPE;
	NSMutableString* path = [ [ NSMutableString alloc ] init ];
	id parent = [ sender parentItem ];
	do
		[ path setString:[ NSString stringWithFormat:@"%@/%@", [ parent title ], path ] ];
	while ((parent = [ parent parentItem ]) && [ parent parentItem ]);
	
	NSString* string = [ NSString stringWithFormat:@"%@%@.shape", path, [ sender title ] ];
	NSString* string2 = [ NSString stringWithFormat:@"%@%@.set", path, [ sender title ] ];
	NSString* currentShape = [ [ NSString alloc ] initWithFormat:@"%@/Shapes/%@", [ [ NSBundle mainBundle ] resourcePath ], string ];
	NSString* currentShape2 = [ [ NSString alloc ] initWithFormat:@"%@/Shapes/%@", [ [ NSBundle mainBundle ] resourcePath ], string2 ];
	
	// Read shape settings
	FILE* sfile = fopen([ currentShape2 UTF8String ], "r");
	if (!sfile)
	{
		ReleaseShapeSettings();
		NSRunAlertPanel(@"Error", @"Invalid Object", @"Ok", nil, nil);
		commandFlag &= ~SHAPE;
		return;
	}
	fclose(sfile);
	
	currentShapePath = [ [ NSString alloc ] initWithString:currentShape ];
	
	/*[ [ currentObject faces ] removeAllObjects ];
	shape = InterpretShape(currentShape, currentShape2, currentObject);
	[ currentShape release ];
	[ currentShape2 release ];
	if (!currentObject || shape.size() == 0)
	{
		NSRunAlertPanel(@"Error", @"Invalid Object", @"Ok", nil, nil);
		commandFlag &= ~SHAPE;
		return;
	}*/
}

- (IBAction) createShapeCode: (id) sender
{
	NSString* text = @"//\n// This code produces a shape that can be created in MovieDraw.\n// Function: MDInstance* Shape(MDVector3 start, MDVector3 delta)\n// Arguments: start - Initial point in space, delta - Change in x, y, and z in space.\n// Return: An MDObject that is the new shape (this should include normals / faces).\n//\n\n#import <MovieDraw/MovieDraw.h>\n\nMDInstance* Shape(MDVector3 start, MDVector3 delta)\n{\n\treturn nil;\n}\n\n";
	[ shapeCodeView removeAllErrors ];
	[ shapeCodeView setText:text ];
	currentShapeName = [ [ NSString alloc ] init ];
	[ createShapePanel makeKeyAndOrderFront:sender ];
}

- (IBAction) finishShapeCode: (id) sender
{
	if (CompileShape([ shapeCodeView string ], shapeCodeView, consoleView))
	{
		NSTask* task = [ [ NSTask alloc ] init ];
		[ task setLaunchPath:[ NSString stringWithFormat:@"%@/App Resources/Shapes/temp.bshape", [ [ NSBundle mainBundle ] resourcePath ] ] ];
		[ task setArguments:[ NSArray arrayWithObjects:@"-1", @"-1", @"-1", @"2", @"2", @"2", nil ] ];
		NSPipe* pipe3 = [ NSPipe pipe ];
		[ task setStandardOutput:pipe3 ];
		[ task setStandardError:pipe3 ];
		[ task launch ];
		NSData *data = [ [ pipe3 fileHandleForReading ] readDataToEndOfFile ];
		[ task waitUntilExit ];
		
		NSString *string = [ [ NSString alloc ] initWithData:data encoding:NSUTF8StringEncoding ];
		if ([ string length ] != 0)
		{
			NSRunAlertPanel(@"Error", @"Could not create shape", @"Ok", nil, nil);
			return;
		}
		
		FILE* file = fopen([ [ NSString stringWithFormat:@"%@/App Resources/Shapes/temp.cshape", [ [ NSBundle mainBundle ] resourcePath ] ] UTF8String ], "r");
		if (!file)
			return;
		
		MDInstance* instance = [ [ MDInstance alloc ] init ];
					
		unsigned long pointCount = 0;
		fread(&pointCount, sizeof(unsigned long), 1, file);
		for (int q = 0; q < pointCount; q++)
		{
			MDPoint* p = [ [ MDPoint alloc ] init ];
			float x = 0, y = 0, z = 0, red = 0, green = 0, blue = 0, alpha = 0, normX = 0, normY = 0, normZ = 0, ux = 0, vy = 0;
			fread(&x, sizeof(float), 1, file);
			fread(&y, sizeof(float), 1, file);
			fread(&z, sizeof(float), 1, file);
			fread(&red, sizeof(float), 1, file);
			fread(&green, sizeof(float), 1, file);
			fread(&blue, sizeof(float), 1, file);
			fread(&alpha, sizeof(float), 1, file);
			fread(&normX, sizeof(float), 1, file);
			fread(&normY, sizeof(float), 1, file);
			fread(&normZ, sizeof(float), 1, file);
			fread(&ux, sizeof(float), 1, file);
			fread(&vy, sizeof(float), 1, file);
			p.x = x, p.y = y, p.z = z, /*p.red = red, p.green = green, p.blue = blue, p.alpha = alpha,*/ p.normalX = normX, p.normalY = normY, p.normalZ = normZ, p.textureCoordX = ux, p.textureCoordY = vy;
			
			[ instance addPoint:p ];
		}
		unsigned char drawMode = 0;
		fread(&drawMode, sizeof(unsigned char), 1, file);
		
		unsigned long numProp = 0;
		fread(&numProp, sizeof(unsigned long), 1, file);
		for (int t = 0; t < numProp; t++)
		{
			unsigned int tempr = 0;
			fread(&tempr, sizeof(unsigned int), 1, file);
			//NSString* key = [ NSString stringWithUTF8String:FaceProperties[tempr] ];
			unsigned long length = 0;
			fread(&length, sizeof(unsigned long), 1, file);
			char* buffer = (char*)malloc(length + 1);
			fread(buffer, sizeof(char), length, file);
			buffer[length] = 0;
			//NSString* value = [ NSString stringWithUTF8String:buffer ];
			free(buffer);
			buffer = NULL;
			//[ instance addProperty:value forKey:key ];
		}
		
		[ instance setupVBO ];
		
		MDObject* obj = [ [ MDObject alloc ] initWithInstance:instance ];
		float tx = 0, ty = 0, tz = 0, sx = 0, sy = 0, sz = 0, rx = 0, ry = 0, rz = 0, ra = 0;
		fread(&tx, sizeof(float), 1, file);
		fread(&ty, sizeof(float), 1, file);
		fread(&tz, sizeof(float), 1, file);
		fread(&sx, sizeof(float), 1, file);
		fread(&sy, sizeof(float), 1, file);
		fread(&sz, sizeof(float), 1, file);
		fread(&rx, sizeof(float), 1, file);
		fread(&ry, sizeof(float), 1, file);
		fread(&rz, sizeof(float), 1, file);
		fread(&ra, sizeof(float), 1, file);
		obj.translateX = tx, obj.translateY = ty, obj.translateZ = tz, obj.scaleX = sx, obj.scaleY = sy, obj.scaleZ = sz, obj.rotateAngle = ra;
		obj.rotateAxis = MDVector3Create(rx, ry, rz);
		
		// Set the correct name
		for (unsigned long q = 0; true; q++)
		{
			[ instance setName:[ NSString stringWithFormat:@"Custom Shape %lu", q ] ];
			BOOL end = TRUE;
			for (unsigned long z = 0; z < [ instances count ]; z++)
			{
				if ([ [ [ instances objectAtIndex:z ] name ] isEqualToString:[ instance name ] ])
				{
					end = FALSE;
					break;
				}
			}
			if (end)
				break;
		}
		[ instances addObject:instance ];
		commandFlag |= UPDATE_LIBRARY;
		
		[ objects addObject:obj ];
		fclose(file);
		
		[ createShapePanel orderOut:self ];
	}
}

- (IBAction) cancelShapeCode: (id) sender
{
	[ createShapePanel orderOut:sender ];
}

- (IBAction) saveShapeCode: (id) sender
{
	[ saveShapeName setStringValue:currentShapeName ];
	[ saveShapeWindow makeKeyAndOrderFront:self ];
}

- (IBAction) saveShapeName:(id)sender
{
	NSMutableString* string = [ [ NSMutableString alloc ] initWithString:[ saveShapeName stringValue ] ];
	
	currentShapeName = [ [ NSString alloc ] initWithString:string ];
	
	[ string insertString:[ NSString stringWithFormat:@"%@/Shapes/Custom/", [ [ NSBundle mainBundle ] resourcePath ] ] atIndex:0 ];
	[ string appendString:@".tshape" ];
	
	[ [ NSFileManager defaultManager ] createFileAtPath:string contents:[ [ shapeCodeView string ] dataUsingEncoding:NSASCIIStringEncoding ] attributes:nil ];
	
	[ saveShapeWindow orderOut:self ];
	
	// Reload Custom Menu
	[ [ [ [ createMenu submenu ] itemWithTitle:@"Custom" ] submenu ] removeAllItems ];
	NSArray* customPaths = [ [ NSFileManager defaultManager ] contentsOfDirectoryAtPath:[ NSString stringWithFormat:@"%@/Shapes/Custom", [ [ NSBundle mainBundle ] resourcePath ] ] error:nil ];
	[ [ [ [ createMenu submenu ] itemWithTitle:@"Custom" ] submenu ] addItemWithTitle:@"Create Shape From Code" action:@selector(createShapeCode:) keyEquivalent:@"" ];
	for (unsigned long z = 0; z < [ customPaths count ]; z++)
	{
		NSString* path = [ customPaths objectAtIndex:z ];
		if (![ path hasSuffix:@".tshape" ])
			continue;
		if ([ [ [ [ createMenu submenu ] itemWithTitle:@"Custom" ] submenu ] numberOfItems ] == 1)
			[ [ [ [ createMenu submenu ] itemWithTitle:@"Custom" ] submenu ] addItem:[ NSMenuItem separatorItem ] ];
		NSString* title = [ [ NSString alloc ] initWithString:[ [ path substringToIndex:[ path length ] - 7 ] lastPathComponent ] ];
		NSMenuItem* item = [ [ NSMenuItem alloc ] initWithTitle:title action:@selector(customShape:) keyEquivalent:@"" ];
		SettingView* view = [ [ SettingView alloc ] initWithFrame:NSMakeRect(0, 0, 150, 19) ];
		[ view setText:title ];
		[ view setTarget:self ];
		[ view setAction:@selector(customShapeSettings:) ];
		[ item setView:view ];
		[ [ [ [ createMenu submenu ] itemWithTitle:@"Custom" ] submenu ] addItem:item ];
	}
}

- (IBAction) customShape:(id)sender
{
	NSString* shapeFile = [ NSString stringWithFormat:@"%@/Shapes/Custom/%@.tshape", [ [ NSBundle mainBundle ] resourcePath ], [ sender title ] ];
	[ shapeCodeView setText:[ NSString stringWithContentsOfFile:shapeFile encoding:NSASCIIStringEncoding error:nil ] ];
	[ self finishShapeCode:sender ];
}

- (IBAction) customShapeSettings:(id)sender
{
	NSString* shapeFile = [ NSString stringWithFormat:@"%@/Shapes/Custom/%@.tshape", [ [ NSBundle mainBundle ] resourcePath ], [ sender title ] ];
	[ shapeCodeView setText:[ NSString stringWithContentsOfFile:shapeFile encoding:NSASCIIStringEncoding error:nil ] ];
	currentShapeName = [ [ NSString alloc ] initWithString:[ sender title ] ];
	[ createShapePanel makeKeyAndOrderFront:sender ];
}

- (IBAction) settings: (id) sender
{
	[ outlineShape selectNode:[ outlineShape selectedNode ] ];
	if ([ outlineShape selectedNode ] == nil)
		[ outlineShape selectNode:0 ];
	[ shapeSettings makeKeyAndOrderFront:self ];
}

- (void) shapeSettings: (id) sender
{
	NSMenuItem* parent = sender;
	NSMutableArray* array = [ [ NSMutableArray alloc ] init ];
	do
		[ array addObject:[ NSString stringWithFormat:@"%@", [ parent title ] ] ];
	while ((parent = [ parent parentItem ]) && [ parent parentItem ]);
	
	IFNode* node = [ outlineShape rootNode ];
	for (long z = [ array count ] - 1; z >= 0; z--)
	{
		node = [ node childWithTitle:[ array objectAtIndex:z ] ];
		[ outlineShape expandItem:node ];
	}
	[ outlineShape selectNode:node ];
	[ outlineShape reloadData ];
	
	[ self settings:sender ];
}

- (void) shapeChosen:(id)sender
{
	NSMutableString* path = [ [ NSMutableString alloc ] init ];
	IFNode* parent = [ outlineShape selectedNode ];
	do
		[ path setString:[ NSString stringWithFormat:@"%@/%@", [ parent title ], path ] ];
	while ((parent = [ parent parentItem ]) && [ parent parentItem ]);
	
	[ path deleteCharactersInRange:NSMakeRange([ path length ] - 1, 1) ];
	[ path appendString:@".set" ];
	NSString* currentShape = [ [ NSString alloc ] initWithFormat:@"%@/Shapes/%@", [ [ NSBundle mainBundle ] resourcePath ], path ];
	
	[ [ shapeScrollView contentView ] setSubviews:[ NSArray array ] ];
	
	FILE* file = fopen([ currentShape UTF8String ], "r");
	if (!file)
	{
		ReleaseShapeSettings();
		NSRunAlertPanel(@"Error", @"Invalid Object", @"Ok", nil, nil);
		return;
	}
	
	fseek(file, 0, SEEK_END);
	unsigned long size = ftell(file);
	rewind(file);
	char* data = (char*)malloc(size + 1);
	memset(data, 0, size + 1);
	fread(data, 1, size + 1, file);
	fclose(file);
	NSMutableString* str = [ [ NSMutableString alloc ] initWithUTF8String:(const char*)data ];
	NSArray* lines = [ str componentsSeparatedByString:@";" ];
	NSString* end = [ [ lines lastObject ] substringFromIndex:NSMaxRange([ [ lines lastObject ] rangeOfString:@"@end\n" ]) ];
	[ str replaceOccurrencesOfString:@"\n" withString:@"" options:0 range:NSMakeRange(0, [ str length ]) ];
	
	ReleaseShapeSettings();
	OpenValues(end);
	InitShapeSettings([ shapeScrollView contentView ], currentShape);
    [ str setString:[ [ NSString stringWithFormat:@"%s", data ] substringWithRange:FunctionNamed(@"main").range ] ];
	free(data);
	data = NULL;
    lines = [ str componentsSeparatedByString:@";" ];
	CompileShapeSettings(lines, [ shapeScrollView contentView ]);
}

- (IBAction) createShape: (id) sender
{
	[ self okShapeSettings:sender ];
	[ self shape:[ outlineShape selectedNode ] ];
}

- (IBAction) okShapeSettings: (id) sender
{
	NSMutableString* path = [ [ NSMutableString alloc ] init ];
	IFNode* parent = [ outlineShape selectedNode ];
	do
		[ path setString:[ NSString stringWithFormat:@"%@/%@", [ parent title ], path ] ];
	while ((parent = [ parent parentItem ]) && [ parent parentItem ]);
	
	[ path deleteCharactersInRange:NSMakeRange([ path length ] - 1, 1) ];
	[ path appendString:@".set" ];
	NSString* currentShape = [ [ NSString alloc ] initWithFormat:@"%@/Shapes/%@", [ [ NSBundle mainBundle ] resourcePath ], path ];
	FILE* file = fopen([ currentShape UTF8String ], "r");
	if (!file)
	{
		NSRunAlertPanel(@"Error", @"Invalid Object", @"Ok", nil, nil);
		return;
	}
	
	fseek(file, 0, SEEK_END);
	unsigned long size = ftell(file);
	rewind(file);
	char* data = (char*)malloc(size + 1);
	memset(data, 0, size + 1);
	fread(data, 1, size + 1, file);
	NSMutableString* str = [ [ NSMutableString alloc ] initWithUTF8String:(const char*)data ];
	free(data);
	data = NULL;
	NSArray* lines = [ str componentsSeparatedByString:@";" ];
	NSString* end = [ [ lines lastObject ] substringFromIndex:NSMaxRange([ [ lines lastObject ] rangeOfString:@"@end\n" ]) ];
	[ str replaceOccurrencesOfString:@"\n" withString:@"" options:0 range:NSMakeRange(0, [ str length ]) ];
	
	SaveValues(end, file, currentShape);
	fclose(file);
	[ shapeSettings orderOut:self ];
	ReleaseShapeSettings();
}

- (IBAction) cancelShapeSettings: (id) sender
{
	[ shapeSettings orderOut:self ];
	ReleaseShapeSettings();
}

- (IBAction) createText: (id) sender
{
	[ createText makeKeyAndOrderFront:self ];
}

// TODO: add a check for the names for these adds and undo support and undo support for curve point editing
- (IBAction) createDirectionalLight:(id)sender
{
	NSString* name = [ NSString stringWithFormat:@"Light %lu", [ otherObjects count ] + 1 ];
	MDLight* light = [ [ MDLight alloc ] init ];
	[ light setPosition:MDVector3Create(0, 5, 0) ];
	[ light setLightType:MDDirectionalLight ];
	[ light setName:name ];
	[ light setObj:[ [ MDObject alloc ] initWithObject:[ [ glWindow glView ] models ][1].obj ] ];
	[ light.obj setMidPoint:MDVector3Create(0, 5, 0) ];
	[ otherObjects addObject:light ];
	
	commandFlag |= UPDATE_LIBRARY;
	documentEdited = TRUE;
	rebuildShaders = TRUE;
}

- (IBAction) createPointLight:(id)sender
{
	NSString* name = [ NSString stringWithFormat:@"Light %lu", [ otherObjects count ] + 1 ];
	MDLight* light = [ [ MDLight alloc ] init ];
	[ light setPosition:MDVector3Create(0, 5, 0) ];
	[ light setLightType:MDPointLight ];
	[ light setName:name ];
	[ light setObj:[ [ MDObject alloc ] initWithObject:[ [ glWindow glView ] models ][2].obj ] ];
	[ light.obj setMidPoint:MDVector3Create(0, 5, 0) ];
	[ otherObjects addObject:light ];
	
	commandFlag |= UPDATE_LIBRARY;
	documentEdited = TRUE;
	rebuildShaders = TRUE;
}

- (IBAction) createSpotLight:(id)sender
{
	NSString* name = [ NSString stringWithFormat:@"Light %lu", [ otherObjects count ] + 1 ];
	MDLight* light = [ [ MDLight alloc ] init ];
	[ light setPosition:MDVector3Create(0, 5, 0) ];
	[ light setLightType:MDSpotLight ];
	[ light setName:name ];
	[ light setObj:[ [ MDObject alloc ] initWithObject:[ [ glWindow glView ] models ][3].obj ] ];
	[ light.obj setMidPoint:MDVector3Create(0, 5, 0) ];
	[ otherObjects addObject:light ];
	
	commandFlag |= UPDATE_LIBRARY;
	documentEdited = TRUE;
	rebuildShaders = TRUE;
}

- (IBAction) createCamera:(id)sender
{
	NSString* name = [ NSString stringWithFormat:@"Camera %lu", [ otherObjects count ] + 1 ];
	MDCamera* camera = [ [ MDCamera alloc ] init ];
	[ camera setMidPoint:MDVector3Create(0, 5, 0) ];
	[ camera setName:name ];
	camera.use = FALSE;
	[ camera setObj:[ [ MDObject alloc ] initWithObject:[ [ glWindow glView ] models ][0].obj ] ];
	[ camera.obj setMidPoint:MDVector3Create(0, 5, 0) ];
	camera.instance = mdCube(0, 0, 0, 0.3, 0.3, 0.3);
	[ camera setLookObj:[ [ MDObject alloc ] initWithInstance:camera.instance ] ];
	[ camera.lookObj setMidPoint:MDVector3Create(5, 5, 0) ];
	[ otherObjects addObject:camera ];
	
	commandFlag |= UPDATE_LIBRARY;
	documentEdited = TRUE;
}

- (IBAction) createSound:(id)sender
{
	NSString* name = [ NSString stringWithFormat:@"Sound %lu", [ otherObjects count ] + 1 ];
	MDSound* sound = [ [ MDSound alloc ] init ];
	[ sound setPosition:MDVector3Create(0, 5, 0) ];
	[ sound setName:name ];
	[ sound setObj:[ [ MDObject alloc ] initWithObject:[ [ glWindow glView ] models ][4].obj ] ];
	[ sound.obj setMidPoint:MDVector3Create(0, 5, 0) ];
	[ otherObjects addObject:sound ];
	
	commandFlag |= UPDATE_LIBRARY;
	documentEdited = TRUE;
}

- (IBAction) createParticleEngine:(id)sender
{
	NSString* name = [ NSString stringWithFormat:@"Particle Engine %lu", [ otherObjects count ] + 1 ];
	MDParticleEngine* engine = [ [ MDParticleEngine alloc ] init ];
	[ engine setPosition:MDVector3Create(0, 5, 0) ];
	[ engine setName:name ];
	[ otherObjects addObject:engine ];
	
	commandFlag |= UPDATE_LIBRARY;
	documentEdited = TRUE;
}

- (IBAction) createCurve:(id)sender
{
	NSString* name = [ NSString stringWithFormat:@"Curve %lu", [ otherObjects count ] + 1 ];
	MDCurve* curve = [ [ MDCurve alloc ] init ];
	[ curve setName:name ];
	[ otherObjects addObject:curve ];
	
	commandFlag |= UPDATE_LIBRARY;
	documentEdited = TRUE;
}

- (IBAction) deleteOtherObject:(id)sender
{
	unsigned long row = -1;
	for (unsigned long z = 0; z < [ otherObjects count ]; z++)
	{
		if ([ [ otherObjects objectAtIndex:z ] selected ] || ([ [ otherObjects objectAtIndex:z ] isKindOfClass:[ MDCamera class ] ] && [ [ otherObjects objectAtIndex:z ] lookSelected ]))
		{
			row = z;
			break;
		}
	}
	if (row == -1)
		return;
	if ([ [ otherObjects objectAtIndex:row ] isKindOfClass:[ MDLight class ] ])
		rebuildShaders = TRUE;
	[ otherObjects removeObjectAtIndex:row ];
	
	commandFlag |= UPDATE_OTHER_INFO | UPDATE_LIBRARY;
	documentEdited = TRUE;
}

#pragma mark Create Text Window

- (IBAction) createTextOk:(id)sender
{
	NSAttributedString* str = [ [ NSAttributedString alloc ] initWithString:[ textName stringValue ] attributes:[ NSDictionary dictionaryWithObjectsAndKeys:[ NSFont fontWithName:[ fontName stringValue ] size:[ fontSize floatValue ] ], NSFontAttributeName, nil ] ];
	MDInstance* inst = [ MDText createText:str depth:0.5 ];
	// Set the correct name
	for (unsigned long q = 0; true; q++)
	{
		[ inst setName:[ NSString stringWithFormat:@"Text %lu", q ] ];
		BOOL end = TRUE;
		for (unsigned long z = 0; z < [ instances count ]; z++)
		{
			if ([ [ [ instances objectAtIndex:z ] name ] isEqualToString:[ inst name ] ])
			{
				end = FALSE;
				break;
			}
		}
		if (end)
			break;
	}
	[ instances addObject:inst ];
	MDObject* obj = [ [ MDObject alloc ] initWithInstance:inst ];
	NSMutableArray* array = [ NSMutableArray array ];
	for (int z = 0; z < [ objects count ]; z++)
	{
		MDObject* obj2 = [ [ MDObject alloc ] initWithObject:[ objects objectAtIndex:z ] ];
		[ array addObject:obj2 ];
	}
	[ array addObject:obj ];
	MDSelection* sel = [ [ MDSelection alloc ] init ];
	[ sel addObject:[ array objectAtIndex:[ array count ] - 1 ] ];
	[ undoManager setActionName:@"Create Text" ];
	[ Controller setObjects:array selected:sel andInstances:instances ];
	
	[ self createTextCancel:sender ];
	
	commandFlag |= UPDATE_INFO;
}

- (IBAction) createTextCancel:(id)sender
{
	[ createText orderOut:self ];
	[ [ [ NSFontManager sharedFontManager ] fontPanel:NO ] orderOut:self ];
}

- (IBAction) chooseFont:(id)sender
{
	NSFontManager* fontManager = [ NSFontManager sharedFontManager ];
	[ createText makeFirstResponder:self ];
	NSFont* font = [ NSFont fontWithName:[ fontName stringValue ] size:[ fontSize floatValue ] ];
	[ fontManager setSelectedFont:font isMultiple:NO ];
	[ fontManager fontPanel:YES ];
	[ fontManager orderFrontFontPanel:self ];
}

- (IBAction) changeFont:(id)sender
{
	NSFont* font = [ [ NSFontManager sharedFontManager ] selectedFont ];
	if (font == nil)
		return;
	font = [ [ NSFontManager sharedFontManager ] convertFont:font ];
	[ fontName setStringValue:[ font fontName ] ];
	[ fontSize setFloatValue:[ font pointSize ] ];
}

#pragma mark Project Properties

- (IBAction) selectIconImage:(id)sender
{
	[ self setupTextureResources ];
	destinationTextureImage = projectSettingIcon;
	// Select this one
	[ self selectTextureResource:[ destinationTextureImage stringValue ] ];
	[ NSApp beginSheet:textureResourcesWindow modalForWindow:projectWindow modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil ];
}

- (IBAction) updateProject:(id)sender
{
	NSSize frame;
	NSString* string = [ [ NSString alloc ] initWithString:[ [ projRes stringValue ] stringByReplacingOccurrencesOfString:@" " withString:@"" ] ];
	NSRange range = [ string rangeOfString:@"x" ];
	frame.width = [ [ string substringWithRange:NSMakeRange(0, range.location) ] floatValue ];
	frame.height = [ [ string substringWithRange:NSMakeRange(NSMaxRange(range), [ string length ] - NSMaxRange(range)) ] floatValue ];
	projectRes = frame;
	NSRect titleBar = NSMakeRect (0, 0, 100, 100);
    NSRect contentRect = [ NSWindow contentRectForFrameRect:titleBar styleMask:NSTitledWindowMask ];
    float titleHeight = (titleBar.size.height - contentRect.size.height);
	NSRect rframe = [ glWindow frame ];
	rframe.size = projectRes;
	rframe.size.height += titleHeight;
	[ glWindow setFrame:rframe display:YES ];
	projectScene = [ [ NSString alloc ] initWithString:[ [ projInitialScene selectedItem ] title ] ];
	
	unsigned int oldAnti = projectAntialias;
	projectAntialias = (unsigned int)pow(2, [ projectSettingsAntialias indexOfItem:[ projectSettingsAntialias selectedItem ] ]);
	if (oldAnti != projectAntialias)
		[ [ glWindow glView ] resetPixelFormat ];
	
	unsigned int setFPS = [ projectSettingsFPS intValue ];
	if (setFPS > 0)
		[ glWindow setFPS:setFPS ];
	else
		[ projectSettingsFPS setIntValue:[ glWindow FPS ] ];
	projectFPS = [ glWindow FPS ];
	
	projectIcon = [ [ NSString alloc ] initWithString:[ projectSettingIcon stringValue ] ];
	
	[ self saveWithPics:NO andModels:YES ];
}

#pragma mark Viewing Panels

- (IBAction) viewInspectorPanel: (id)sender
{
	if ([ inspectorPanel isVisible ])
	{
		[ inspectorPanel close ];
		[ sender setTitle:@"View Inspector Panel" ];
	}
	else
	{
		[ inspectorPanel makeKeyAndOrderFront:self ];
		[ sender setTitle:@"Close Inspector Panel" ];
	}
}

- (IBAction) viewInfoPanel: (id) sender
{
	if ([ [ infoTable window ] isVisible ])
	{
		[ [ infoTable window ] close ];
		[ sender setTitle:@"View Info Panel" ];
	}
	else
	{
		[ [ infoTable window ] makeKeyAndOrderFront:self ];
		[ sender setTitle:@"Close Info Panel" ];
	}
}

- (void) setUpInfoPanel
{
	[ infoTable setTarget:self ];
	[ infoTable setEditAction:@selector(infoTableUpdated:) ];
	IFNode* scene = [ [ IFNode alloc ] initParentWithTitle:@"Scene" children:nil ];
	IFNode* xpos = [ [ IFNode alloc ] initLeafWithTitle:@"X Position" ];
	[ xpos setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", translationPoint.x ] forKey:@"Value" ] ];
	[ scene addChild:xpos ];
	IFNode* ypos = [ [ IFNode alloc ] initLeafWithTitle:@"Y Position" ];
	[ ypos setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", translationPoint.y ] forKey:@"Value" ] ];
	[ scene addChild:ypos ];
	IFNode* zpos = [ [ IFNode alloc ] initLeafWithTitle:@"Z Position" ];
	[ zpos setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", translationPoint.z ] forKey:@"Value" ] ];
	[ scene addChild:zpos ];
	IFNode* xLook = [ [ IFNode alloc ] initLeafWithTitle:@"X Look" ];
	[ xLook setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", lookPoint.x ] forKey:@"Value" ] ];
	[ scene addChild:xLook ];
	IFNode* yLook = [ [ IFNode alloc ] initLeafWithTitle:@"Y Look" ];
	[ yLook setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", lookPoint.y ] forKey:@"Value" ] ];
	[ scene addChild:yLook ];
	IFNode* zLook = [ [ IFNode alloc ] initLeafWithTitle:@"Z Look" ];
	[ zLook setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", lookPoint.z ] forKey:@"Value" ] ];
	[ scene addChild:zLook ];
	IFNode* xrot = [ [ IFNode alloc ] initLeafWithTitle:@"X Rotation" ];
	[ xrot setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", 0.0f ] forKey:@"Value" ] ];
	[ scene addChild:xrot ];
	IFNode* yrot = [ [ IFNode alloc ] initLeafWithTitle:@"Y Rotation" ];
	[ yrot setDictionary:[ NSDictionary dictionaryWithObject:[  NSString stringWithFormat:@"%f", 0.0f ] forKey:@"Value" ] ];
	[ scene addChild:yrot ];
	IFNode* zrot = [ [ IFNode alloc ] initLeafWithTitle:@"Z Rotation" ];
	[ zrot setDictionary:[ NSDictionary dictionaryWithObject:[  NSString stringWithFormat:@"%f", 0.0f ] forKey:@"Value" ] ];
	[ scene addChild:zrot ];
	[ [ infoTable rootNode ] addChild:scene ];
	
	IFNode* general = [ [ IFNode alloc ] initParentWithTitle:@"General Attributes" children:nil ];
	IFNode* translate = [ [ IFNode alloc ] initParentWithTitle:@"Translation" children:nil ];
	IFNode* transX = [ [ IFNode alloc ] initLeafWithTitle:@"Translate X" ];
	[ transX setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	IFNode* transY = [ [ IFNode alloc ] initLeafWithTitle:@"Translate Y" ];
	[ transY setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	IFNode* transZ = [ [ IFNode alloc ] initLeafWithTitle:@"Translate Z" ];
	[ transZ setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	[ translate addChild:transX ];
	[ translate addChild:transY ];
	[ translate addChild:transZ ];
	[ general addChild:translate ];
	
	IFNode* scale = [ [ IFNode alloc ] initParentWithTitle:@"Scale" children:nil ];
	IFNode* scaleX = [ [ IFNode alloc ] initLeafWithTitle:@"Scale X" ];
	[ scaleX setDictionary:[ NSDictionary dictionaryWithObject:@"1" forKey:@"Value" ] ];
	IFNode* scaleY = [ [ IFNode alloc ] initLeafWithTitle:@"Scale Y" ];
	[ scaleY setDictionary:[ NSDictionary dictionaryWithObject:@"1" forKey:@"Value" ] ];
	IFNode* scaleZ = [ [ IFNode alloc ] initLeafWithTitle:@"Scale Z" ];
	[ scaleZ setDictionary:[ NSDictionary dictionaryWithObject:@"1" forKey:@"Value" ] ];
	[ scale addChild:scaleX ];
	[ scale addChild:scaleY ];
	[ scale addChild:scaleZ ];
	[ general addChild:scale ];
	
	IFNode* rotate = [ [ IFNode alloc ] initParentWithTitle:@"Rotate" children:nil ];
	IFNode* rotateX = [ [ IFNode alloc ] initLeafWithTitle:@"Rotate Axis X" ];
	[ rotateX setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	IFNode* rotateY = [ [ IFNode alloc ] initLeafWithTitle:@"Rotate Axis Y" ];
	[ rotateY setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	IFNode* rotateZ = [ [ IFNode alloc ] initLeafWithTitle:@"Rotate Axis Z" ];
	[ rotateZ setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	IFNode* rotateA = [ [ IFNode alloc ] initLeafWithTitle:@"Rotate Angle" ];
	[ rotateZ setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	/*IFNode* rotatePX = [ [ IFNode alloc ] initLeafWithTitle:@"Rotate Point X" ];
	[ rotatePX setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	IFNode* rotatePY = [ [ IFNode alloc ] initLeafWithTitle:@"Rotate Point Y" ];
	[ rotateY setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	IFNode* rotatePZ = [ [ IFNode alloc ] initLeafWithTitle:@"Rotate Point Z" ];
	[ rotateZ setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];*/
	[ rotate addChild:rotateX ];
	[ rotate addChild:rotateY ];
	[ rotate addChild:rotateZ ];
	[ rotate addChild:rotateA ];
	[ general addChild:rotate ];
	/*[ rotate addChild:rotatePX ];
	[ rotatePX release ];
	[ rotate addChild:rotatePY ];
	[ rotatePY release ];
	[ rotate addChild:rotatePZ ];
	[ rotatePZ release ];*/
	
	IFNode* point = [ [ IFNode alloc ] initParentWithTitle:@"Midpoint" children:nil ];
	IFNode* pointX = [ [ IFNode alloc ] initLeafWithTitle:@"Midpoint X" ];
	[ pointX setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	[ point addChild:pointX ];
	IFNode* pointY = [ [ IFNode alloc ] initLeafWithTitle:@"Midpoint Y" ];
	[ pointY setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	[ point addChild:pointY ];
	IFNode* pointZ = [ [ IFNode alloc ] initLeafWithTitle:@"Midpoint Z" ];
	[ pointZ setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	[ point addChild:pointZ ];
	[ general addChild:point ];
	
	IFNode* color = [ [ IFNode alloc ] initParentWithTitle:@"Color" children:nil ];
	IFNode* red = [ [ IFNode alloc ] initLeafWithTitle:@"Red" ];
	[ red setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	[ color addChild:red ];
	IFNode* green = [ [ IFNode alloc ] initLeafWithTitle:@"Green" ];
	[ green setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	[ color addChild:green ];
	IFNode* blue = [ [ IFNode alloc ] initLeafWithTitle:@"Blue" ];
	[ blue setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	[ color addChild:blue ];
	IFNode* alpha = [ [ IFNode alloc ] initLeafWithTitle:@"Alpha" ];
	[ alpha setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	[ color addChild:alpha ];
	IFNode* ored = [ [ IFNode alloc ] initLeafWithTitle:@"Object Red" ];
	[ ored setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	[ color addChild:ored ];
	IFNode* ogreen = [ [ IFNode alloc ] initLeafWithTitle:@"Object Green" ];
	[ ogreen setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	[ color addChild:ogreen ];
	IFNode* oblue = [ [ IFNode alloc ] initLeafWithTitle:@"Object Blue" ];
	[ oblue setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	[ color addChild:oblue ];
	IFNode* oalpha = [ [ IFNode alloc ] initLeafWithTitle:@"Object Alpha" ];
	[ oalpha setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	[ color addChild:oalpha ];
	IFNode* specularRed = [ [ IFNode alloc ] initLeafWithTitle:@"Specular Red" ];
	[ specularRed setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	[ color addChild:specularRed ];
	IFNode* specularGreen = [ [ IFNode alloc ] initLeafWithTitle:@"Specular Green" ];
	[ specularGreen setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	[ color addChild:specularGreen ];
	IFNode* specularBlue = [ [ IFNode alloc ] initLeafWithTitle:@"Specular Blue" ];
	[ specularBlue setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	[ color addChild:specularBlue ];
	IFNode* specularAlpha = [ [ IFNode alloc ] initLeafWithTitle:@"Specular Alpha" ];
	[ specularAlpha setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	[ color addChild:specularAlpha ];
	IFNode* shininess = [ [ IFNode alloc ] initLeafWithTitle:@"Shininess" ];
	[ shininess setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	[ color addChild:shininess ];
	[ color setVisible:NO ];
	[ general addChild:color ];
	
	IFNode* normal = [ [ IFNode alloc ] initParentWithTitle:@"Normal" children:nil ];
	IFNode* normalX = [ [ IFNode alloc ] initLeafWithTitle:@"Normal X" ];
	[ normalX setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	[ normal addChild:normalX ];
	IFNode* normalY = [ [ IFNode alloc ] initLeafWithTitle:@"Normal Y" ];
	[ normalY setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	[ normal addChild:normalY ];
	IFNode* normalZ = [ [ IFNode alloc ] initLeafWithTitle:@"Normal Z" ];
	[ normalZ setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	[ normal addChild:normalZ ];
	[ normal setVisible:NO ];
	[ general addChild:normal ];
	
	IFNode* faces = [ [ IFNode alloc ] initParentWithTitle:@"Faces" children:nil ];
	[ faces setTarget:self ];
	[ faces setAction:@selector(updateFaces:) ];
	[ general addChild:faces ];
	
	IFNode* points = [ [ IFNode alloc ] initParentWithTitle:@"Points" children:nil ];
	[ general addChild:points ];
	
	[ general setVisible:NO ];
	[ [ infoTable rootNode ] addChild:general ];
	
	[ infoTable reloadData ];
}

- (void) updateFaces:(IFNode*)node
{
	// Disable for now
	return;
	
	/*if ([ node expanded ])
	{
		IFNode* faces = node;
		MDObject* obj = [ [ selected selectedValueAtIndex:0 ] objectForKey:@"Object" ];
		[ node removeChildren ];
		for (int z = 0; z < [ obj numberOfFaces ]; z++)
		{
			IFNode* face = [ [ IFNode alloc ] initParentWithTitle:[ NSString stringWithFormat:@"Face %i", z ] children:nil ];
			for (int y = 0; y < [ [ obj faceAtIndex:z ] numberOfPoints ]; y++)
			{
				IFNode* p = [ [ IFNode alloc ] initParentWithTitle:[ NSString stringWithFormat:@"Point %i", y ] children:nil ];
				
				IFNode* normal = [ [ IFNode alloc ] initParentWithTitle:@"Normal" children:nil ];
				IFNode* nx = [ [ IFNode alloc ] initLeafWithTitle:@"Normal X" ];
				[ nx setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", [ [ obj faceAtIndex:z ] pointAtIndex:y ].normalX ] forKey:@"Value" ] ];
				[ normal addChild:nx ];
				[ nx release ];
				IFNode* ny = [ [ IFNode alloc ] initLeafWithTitle:@"Normal Y" ];
				[ ny setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", [ [ obj faceAtIndex:z ] pointAtIndex:y ].normalY ] forKey:@"Value" ] ];
				[ normal addChild:ny ];
				[ ny release ];
				IFNode* nz = [ [ IFNode alloc ] initLeafWithTitle:@"Normal Z" ];
				[ nz setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", [ [ obj faceAtIndex:z ] pointAtIndex:y ].normalZ ] forKey:@"Value" ] ];
				[ normal addChild:nz ];
				[ nz release ];
				[ p addChild:normal ];
				[ normal release ];
				
				IFNode* px = [ [ IFNode alloc ] initLeafWithTitle:@"X" ];
				[ px setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", [ [ obj faceAtIndex:z ] pointAtIndex:y ].x ] forKey:@"Value" ] ];
				[ p addChild:px ];
				[ px release ];
				IFNode* py = [ [ IFNode alloc ] initLeafWithTitle:@"Y" ];
				[ py setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", [ [ obj faceAtIndex:z ] pointAtIndex:y ].y ] forKey:@"Value" ] ];
				[ p addChild:py ];
				[ py release ];
				IFNode* pz = [ [ IFNode alloc ] initLeafWithTitle:@"Z" ];
				[ pz setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", [ [ obj faceAtIndex:z ] pointAtIndex:y ].z ] forKey:@"Value" ] ];
				[ p addChild:pz];
				[ pz release ];
				IFNode* pr = [ [ IFNode alloc ] initLeafWithTitle:@"Red" ];
				[ pr setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", [ [ obj faceAtIndex:z ] pointAtIndex:y ].red ] forKey:@"Value" ] ];
				[ p addChild:pr ];
				[ pr release ];
				IFNode* pg = [ [ IFNode alloc ] initLeafWithTitle:@"Green" ];
				[ pg setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", [ [ obj faceAtIndex:z ] pointAtIndex:y ].green ] forKey:@"Value" ] ];
				[ p addChild:pg ];
				[ pg release ];
				IFNode* pb = [ [ IFNode alloc ] initLeafWithTitle:@"Blue" ];
				[ pb setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", [ [ obj faceAtIndex:z ] pointAtIndex:y ].blue ] forKey:@"Value" ] ];
				[ p addChild:pb ];
				[ pb release ];
				IFNode* pa = [ [ IFNode alloc ] initLeafWithTitle:@"Alpha" ];
				[ pa setDictionary:[ NSDictionary dictionaryWithObject:[ NSString stringWithFormat:@"%f", [ [ obj faceAtIndex:z ] pointAtIndex:y ].alpha ] forKey:@"Value" ] ];
				[ p addChild:pa ];
				[ pa release ];
				
				[ face addChild:p ];
				[ p release ];
			}
			[ faces addChild:face ];
			[ face release ];
		}
		[ infoTable reloadItem:faces reloadChildren:YES ];
	}*/
}

- (void) setUpOtherPanel
{
	IFNode* midPoint = [ [ IFNode alloc ] initParentWithTitle:@"Midpoint" children:nil ];
	IFNode* mpx = [ [ IFNode alloc ] initLeafWithTitle:@"X" ];
	[ mpx setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	[ midPoint addChild:mpx ];
	IFNode* mpy = [ [ IFNode alloc ] initLeafWithTitle:@"Y" ];
	[ mpy setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	[ midPoint addChild:mpy ];
	IFNode* mpz = [ [ IFNode alloc ] initLeafWithTitle:@"Z" ];
	[ mpz setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	[ midPoint addChild:mpz ];
	[ midPoint setVisible:NO ];
	[ [ infoTable rootNode ] addChild:midPoint ];
	IFNode* lookPoint = [ [ IFNode alloc ] initParentWithTitle:@"Lookpoint" children:nil ];
	IFNode* lpx = [ [ IFNode alloc ] initLeafWithTitle:@"X" ];
	[ lpx setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	[ lookPoint addChild:lpx ];
	IFNode* lpy = [ [ IFNode alloc ] initLeafWithTitle:@"Y" ];
	[ lpy setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	[ lookPoint addChild:lpy ];
	IFNode* lpz = [ [ IFNode alloc ] initLeafWithTitle:@"Z" ];
	[ lpz setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	[ lookPoint addChild:lpz ];
	[ lookPoint setVisible:NO ];
	[ [ infoTable rootNode ] addChild:lookPoint ];
	
	IFNode* orien = [ [ IFNode alloc ] initLeafWithTitle:@"Orientation" ];
	[ orien setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	[ orien setVisible:NO ];
	[ [ infoTable rootNode ] addChild:orien ];
	
	IFNode* colors = [ [ IFNode alloc ] initParentWithTitle:@"Colors" children:nil ];
	IFNode* colorsAR = [ [ IFNode alloc ] initLeafWithTitle:@"Ambient Red" ];
	[ colorsAR setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	[ colors addChild:colorsAR ];
	IFNode* colorsAG = [ [ IFNode alloc ] initLeafWithTitle:@"Ambient Green" ];
	[ colorsAG setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	[ colors addChild:colorsAG ];
	IFNode* colorsAB = [ [ IFNode alloc ] initLeafWithTitle:@"Ambient Blue" ];
	[ colorsAB setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	[ colors addChild:colorsAB ];
	IFNode* colorsAA = [ [ IFNode alloc ] initLeafWithTitle:@"Ambient Alpha" ];
	[ colorsAA setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	[ colors addChild:colorsAA ];
	
	IFNode* colorsDR = [ [ IFNode alloc ] initLeafWithTitle:@"Diffuse Red" ];
	[ colorsDR setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	[ colors addChild:colorsDR ];
	IFNode* colorsDG = [ [ IFNode alloc ] initLeafWithTitle:@"Diffuse Green" ];
	[ colorsDG setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	[ colors addChild:colorsDG ];
	IFNode* colorsDB = [ [ IFNode alloc ] initLeafWithTitle:@"Diffuse Blue" ];
	[ colorsDB setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	[ colors addChild:colorsDB ];
	IFNode* colorsDA = [ [ IFNode alloc ] initLeafWithTitle:@"Diffuse Alpha" ];
	[ colorsDA setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	[ colors addChild:colorsDA ];
	
	IFNode* colorsSR = [ [ IFNode alloc ] initLeafWithTitle:@"Specular Red" ];
	[ colorsSR setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	[ colors addChild:colorsSR ];
	IFNode* colorsSG = [ [ IFNode alloc ] initLeafWithTitle:@"Specular Green" ];
	[ colorsSG setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	[ colors addChild:colorsSG ];
	IFNode* colorsSB = [ [ IFNode alloc ] initLeafWithTitle:@"Specular Blue" ];
	[ colorsSB setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	[ colors addChild:colorsSB ];
	IFNode* colorsSA = [ [ IFNode alloc ] initLeafWithTitle:@"Specular Alpha" ];
	[ colorsSA setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	[ colors addChild:colorsSA ];
	
	[ colors setVisible:NO ];
	[ [ infoTable rootNode ] addChild:colors ];
	
	IFNode* spot = [ [ IFNode alloc ] initParentWithTitle:@"Spot" children:nil ];
	IFNode* spotE = [ [ IFNode alloc ] initLeafWithTitle:@"Exponent" ];
	[ spotE setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	[ spot addChild:spotE ];
	IFNode* spotC = [ [ IFNode alloc ] initLeafWithTitle:@"Cutoff" ];
	[ spotC setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	[ spot addChild:spotC ];
	IFNode* spotCC = [ [ IFNode alloc ] initLeafWithTitle:@"Angle Cutoff" ];
	[ spotCC setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	[ spot addChild:spotCC ];
	[ spot setVisible:NO ];
	[ [ infoTable rootNode ] addChild:spot ];
	
	IFNode* att = [ [ IFNode alloc ] initParentWithTitle:@"Attenuation" children:nil ];
	IFNode* attConst = [ [ IFNode alloc ] initLeafWithTitle:@"Constant" ];
	[ attConst setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	[ att addChild:attConst ];
	IFNode* attLin = [ [ IFNode alloc ] initLeafWithTitle:@"Linear" ];
	[ attLin setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	[ att addChild:attLin ];
	IFNode* attQuad = [ [ IFNode alloc ] initLeafWithTitle:@"Quadratic" ];
	[ attQuad setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	[ att addChild:attQuad ];
	[ att setVisible:NO ];
	[ [ infoTable rootNode ] addChild:att ];
	
	IFNode* shadow = [ [ IFNode alloc ] initParentWithTitle:@"Shadows" children:nil ];
	IFNode* enableShadow = [ [ IFNode alloc ] initLeafWithTitle:@"Enable Shadows" ];
	[ enableShadow setDictionary:[ NSDictionary dictionaryWithObject:@"1" forKey:@"Value" ] ];
	[ shadow addChild:enableShadow ];
	IFNode* isStatic = [ [ IFNode alloc ] initLeafWithTitle:@"Static" ];
	[ isStatic setDictionary:[ NSDictionary dictionaryWithObject:@"1" forKey:@"Value" ] ];
	[ shadow addChild:isStatic ];
	[ shadow setVisible:NO ];
	[ [ infoTable rootNode ] addChild:shadow ];
	
	IFNode* particleColors = [ [ IFNode alloc ] initParentWithTitle:@"Particle Colors" children:nil ];
	IFNode* colorsStR = [ [ IFNode alloc ] initLeafWithTitle:@"Start Red" ];
	[ colorsStR setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	[ particleColors addChild:colorsStR ];
	IFNode* colorsStG = [ [ IFNode alloc ] initLeafWithTitle:@"Start Green" ];
	[ colorsStG setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	[ particleColors addChild:colorsStG ];
	IFNode* colorsStB = [ [ IFNode alloc ] initLeafWithTitle:@"Start Blue" ];
	[ colorsStB setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	[ particleColors addChild:colorsStB ];
	IFNode* colorsStA = [ [ IFNode alloc ] initLeafWithTitle:@"Start Alpha" ];
	[ colorsStA setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	[ particleColors addChild:colorsStA ];
	IFNode* colorsEtR = [ [ IFNode alloc ] initLeafWithTitle:@"End Red" ];
	[ colorsEtR setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	[ particleColors addChild:colorsEtR ];
	IFNode* colorsEtG = [ [ IFNode alloc ] initLeafWithTitle:@"End Green" ];
	[ colorsEtG setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	[ particleColors addChild:colorsEtG ];
	IFNode* colorsEtB = [ [ IFNode alloc ] initLeafWithTitle:@"End Blue" ];
	[ colorsEtB setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	[ particleColors addChild:colorsEtB ];
	IFNode* colorsEtA = [ [ IFNode alloc ] initLeafWithTitle:@"End Alpha" ];
	[ colorsEtA setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	[ particleColors addChild:colorsEtA ];
	[ particleColors setVisible:NO ];
	[ [ infoTable rootNode ] addChild:particleColors ];
	
	IFNode* particleVels = [ [ IFNode alloc ] initParentWithTitle:@"Velocities" children:nil ];
	IFNode* velType = [ [ IFNode alloc ] initLeafWithTitle:@"Type" ];
	[ velType setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	[ particleVels addChild:velType ];
	IFNode* velX = [ [ IFNode alloc ] initLeafWithTitle:@"X" ];
	[ velX setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	[ particleVels addChild:velX ];
	IFNode* velY = [ [ IFNode alloc ] initLeafWithTitle:@"Y" ];
	[ velY setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	[ particleVels addChild:velY ];
	IFNode* velZ = [ [ IFNode alloc ] initLeafWithTitle:@"Z" ];
	[ velZ setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	[ particleVels addChild:velZ ];
	[ particleVels setVisible:NO ];
	[ [ infoTable rootNode ] addChild:particleVels ];
	
	IFNode* pNum = [ [ IFNode alloc ] initLeafWithTitle:@"Particle Number" ];
	[ pNum setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	[ pNum setVisible:NO ];
	[ [ infoTable rootNode ] addChild:pNum ];
	IFNode* pSize = [ [ IFNode alloc ] initLeafWithTitle:@"Particle Size" ];
	[ pSize setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	[ pSize setVisible:NO ];
	[ [ infoTable rootNode ] addChild:pSize ];
	IFNode* pLife = [ [ IFNode alloc ] initLeafWithTitle:@"Particle Life" ];
	[ pLife setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	[ pLife setVisible:NO ];
	[ [ infoTable rootNode ] addChild:pLife ];
	
	IFNode* numP = [ [ IFNode alloc ] initLeafWithTitle:@"Point Number" ];
	[ numP setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	[ numP setVisible:NO ];
	[ [ infoTable rootNode ] addChild:numP ];
	
	IFNode* points = [ [ IFNode alloc ] initParentWithTitle:@"Curve Points" children:nil ];
	[ points setVisible:NO ];
	[ [ infoTable rootNode ] addChild:points ];
	
	IFNode* vis = [ [ IFNode alloc ] initLeafWithTitle:@"Visible" ];
	[ vis setDictionary:[ NSDictionary dictionaryWithObject:@"1" forKey:@"Value" ] ];
	[ vis setVisible:NO ];
	[ [ infoTable rootNode ] addChild:vis ];
	
	IFNode* use = [ [ IFNode alloc ] initLeafWithTitle:@"Use" ];
	[ use setDictionary:[ NSDictionary dictionaryWithObject:@"0" forKey:@"Value" ] ];
	[ use setVisible:NO ];
	[ [ infoTable rootNode ] addChild:use ];
	
	[ infoTable reloadData ];
}

- (void) setUpFilePanel
{
	[ fileOutline setTarget:self ];
	[ fileOutline setDoubleAction:@selector(openFilePanel:) ];
	[ fileOutline setRightClickAction:@selector(fileOutlineMenu:) ];
	[ fileOutline setEditAction:@selector(fileOutlineEdited: withOld:) ];
	[ fileOutline setShowsGroups:NO ];
	[ fileOutline setSelectParents:YES ];
	[ fileOutline setDoubleClickInsteadOfEdit:YES ];
	[ fileOutline SetDeleteEmptyTitles:YES ];
	[ editorView setEnableBreaks:YES ];
	[ editorView setBreakTarget:self ];
	[ editorView setVariableTarget:self ];
	[ editorView setVariableUpdated:@selector(updateVar:value:) ];
	[ editorView setVariableAction:@selector(updateVariableText:) ];
	[ editorView setBreakPointAction:@selector(updateEditorBreaks) ];
}

- (void) setupLibraryPanel
{
	[ libraryOutline setTarget:self ];
	[ libraryOutline setAction:@selector(selectLibraryObject:) ];
	[ libraryOutline setDoubleAction:@selector(insertLibraryObject:) ];
	[ libraryOutline setRightClickAction:@selector(rightLibraryObject:) ];
	[ libraryOutline setSelectParents:YES ];
	[ libraryOutline setEditAction:@selector(renameLibraryObject:withOld:) ];
	//[ [ [ libraryOutline tableColumns ] objectAtIndex:0 ] setIdentifier:@"Objects" ];
	[ [ [ libraryOutline tableColumns ] objectAtIndex:1 ] setIdentifier:@"Type" ];
}

- (IBAction) viewConsolePanel:(id)sender
{
	if ([ consoleWindow isVisible ])
	{
		[ consoleWindow close ];
		[ sender setTitle:@"View Console Panel" ];
	}
	else
	{
		[ consoleWindow makeKeyAndOrderFront:self ];
		[ sender setTitle:@"Close Console Panel" ];
	}
}

- (IBAction) viewProjectPanel:(id)sender
{
	if ([ projectWindow isVisible ])
	{
		[ projectWindow close ];
		[ sender setTitle:@"View Project Panel" ];
	}
	else
	{
		[ projRes setStringValue:[ NSString stringWithFormat:@"%i x %i", (unsigned int)projectRes.width, (unsigned int)projectRes.height ] ];
		[ [ projInitialScene menu ] removeAllItems ];
		NSMenuItem* current = [ [ NSMenuItem alloc ] initWithTitle:@"Current Scene" action:nil keyEquivalent:@"" ];
		NSAttributedString* string = [ [ NSAttributedString alloc ] initWithString:@"Current Scene" attributes:[ NSDictionary dictionaryWithObject:[ NSFont boldSystemFontOfSize:12 ] forKey:NSFontAttributeName ] ];
		[ current setAttributedTitle:string ];
		[ [ projInitialScene menu ] addItem:current ];
		for (unsigned int z = 0; z < [ sceneTable numberOfRows ]; z++)
		{
			[ [ projInitialScene menu ] addItemWithTitle:[ [ sceneTable itemAtRow:z ] objectForKey:@"Name" ] action:nil keyEquivalent:@"" ];
			if ([ [ [ sceneTable itemAtRow:z ] objectForKey:@"Name" ] isEqualToString:projectScene ])
				[ projInitialScene selectItemAtIndex:[ projInitialScene numberOfItems ] - 1 ];
		}
		
		[ projectSettingsAntialias selectItemAtIndex:log2(projectAntialias) ];
		[ projectSettingsFPS setIntValue:[ glWindow FPS ] ];
		
		if (projectIcon)
			[ projectSettingIcon setStringValue:projectIcon ];
		
		[ projectWindow makeKeyAndOrderFront:self ];
		[ sender setTitle:@"Close Project Panel" ];
	}
}

#pragma mark Scene Panel

- (void) sceneEdited:(id)sender
{
	NSString* selScene = [ sceneTable oldObject ];
	NSString* path = [ NSString stringWithFormat:@"%@/Scenes/%@.mds", workingDirectory, selScene ];
	NSString* newPath = [ NSString stringWithFormat:@"%@/Scenes/%@.mds", workingDirectory, [ sceneTable selectedRowItemforColumnIdentifier:@"Name" ] ];
	if (![ [ NSFileManager defaultManager ] fileExistsAtPath:path ])
		[ [ NSFileManager defaultManager ] createFileAtPath:newPath contents:[ NSData data ] attributes:nil ];
	else
		[ [ NSFileManager defaultManager ] moveItemAtPath:path toPath:newPath error:nil ];
	[ self save:sender ];
}

- (void) sceneMakeEdit:(id)sender
{
	if ([ sceneTable selectedRow ] == -1)
		return;
	[ sceneTable editColumn:1 row:[ sceneTable selectedRow ] withEvent:nil select:YES ];

}

- (void) sceneOpened:(id)sender
{
	if ([ sceneTable selectedRow ] == -1)
		return;
	[ self save:sender ];
	currentScene = [ [ NSString alloc ] initWithString:[ sceneTable selectedRowItemforColumnIdentifier:@"Name" ] ];
	[ [ sceneTable itemAtRow:(unsigned int)[ sceneTable selectedRow ] ] setObject:@"✓" forKey:@"Loaded" ];
	for (unsigned int z = 0; z < [ sceneTable numberOfRows ]; z++)
	{
		if (z == [ sceneTable selectedRow ])
			continue;
		[ [ sceneTable itemAtRow:z ] setObject:@"" forKey:@"Loaded" ];
	}
	[ sceneTable reloadData ];
	[ self read:self project:NO ];
}

- (void) sceneShowMenu:(id)sender
{
	NSMenu* menu = [ [ NSMenu alloc ] init ];
	if ([ sceneTable selectedRow ] != -1)
	{
		[ menu addItemWithTitle:@"Rename" action:@selector(sceneMakeEdit:) keyEquivalent:@"" ];
		[ menu addItem:[ NSMenuItem separatorItem ] ];
	}
	[ menu addItemWithTitle:@"Add" action:@selector(sceneAdd:) keyEquivalent:@"" ];
	if ([ sceneTable selectedRow ] != -1 && [ sceneTable numberOfRows ] > 1)
		[ menu addItemWithTitle:@"Remove" action:@selector(sceneRemove:) keyEquivalent:@"" ];
	
	[ NSMenu popUpContextMenu:menu withEvent:[ sceneTable rightEvent ] forView:sceneTable ];
}

- (void) sceneAdd:(id)sender
{
	long index = [ sceneTable numberOfRows ] + 1;
	NSString* name = nil;
	for (;;)
	{
		name = [ NSString stringWithFormat:@"Scene %li", index ];
		BOOL stop = TRUE;
		for (unsigned int z = 0; z < [ sceneTable numberOfRows ]; z++)
		{
			NSDictionary* dict = [ sceneTable itemAtRow:z ];
			if ([ [ dict objectForKey:@"Name" ] isEqualToString:name ])
			{
				stop = FALSE;
				break;
			}
		}
		if (stop)
			break;
		index++;
	}
	[ sceneTable addRow:[ NSDictionary dictionaryWithObjectsAndKeys:name, @"Name", [ NSImage imageNamed:NSImageNameApplicationIcon ], @"Image", @"", @"Loaded", nil ] ];
	[ sceneTable selectRowIndexes:[ NSIndexSet indexSetWithIndex:[ sceneTable numberOfRows ] - 1 ] byExtendingSelection:NO ];
	NSString* path = [ NSString stringWithFormat:@"%@/Scenes/%@.mds", workingDirectory, name ];
	FILE* file = fopen([ path UTF8String ], "wb");
	// Write an ambient light
	float tpx = 0, tpy = 5, tpz = -20, lpx = 0, lpy = 5, lpz = 0, rotX = 0, rotY = 0, rotZ = 0;
	fwrite(&tpx, sizeof(float), 1, file);
	fwrite(&tpy, sizeof(float), 1, file);
	fwrite(&tpz, sizeof(float), 1, file);
	fwrite(&lpx, sizeof(float), 1, file);
	fwrite(&lpy, sizeof(float), 1, file);
	fwrite(&lpz, sizeof(float), 1, file);
	fwrite(&rotX, sizeof(float), 1, file);
	fwrite(&rotY, sizeof(float), 1, file);
	fwrite(&rotZ, sizeof(float), 1, file);
	// List objects
	unsigned long objectsCount = 0;
	fwrite(&objectsCount, sizeof(unsigned long), 1, file);
	// Other Objects
	unsigned long otherObjSize = 1;
	fwrite(&otherObjSize, sizeof(unsigned long), 1, file);
	unsigned int realType = 2;
	fwrite(&realType, sizeof(realType), 1, file);
	MDVector3 point = MDVector3Create(0, 5, 0), look = MDVector3Create(0, 5, 0);
	MDVector4 ambient = MDVector4Create(0.5, 0.5, 0.5, 1.0), diffuse = MDVector4Create(0, 0, 0, 1), specular = MDVector4Create(0, 0, 0, 1);
	float exp = 1, cut = 0, ccut = 0.5, cat = 1, linat = 0, quadat = 0;
	unsigned int type = MDDirectionalLight;
	BOOL enableShadows = 0, selected = NO, show = NO;
	fwrite(&point, sizeof(point), 1, file);
	fwrite(&look, sizeof(look), 1, file);
	fwrite(&ambient, sizeof(ambient), 1, file);
	fwrite(&diffuse, sizeof(diffuse), 1, file);
	fwrite(&specular, sizeof(specular), 1, file);
	fwrite(&exp, sizeof(exp), 1, file);
	fwrite(&cut, sizeof(cut), 1, file);
	fwrite(&ccut, sizeof(ccut), 1, file);
	fwrite(&cat, sizeof(cat), 1, file);
	fwrite(&linat, sizeof(linat), 1, file);
	fwrite(&quadat, sizeof(quadat), 1, file);
	fwrite(&type, sizeof(type), 1, file);
	fwrite(&enableShadows, sizeof(enableShadows), 1, file);
	fwrite(&selected, sizeof(selected), 1, file);
	fwrite(&show, sizeof(show), 1, file);
	NSString* name2 = @"Ambient";
	unsigned int nameSize = (unsigned int)[ name2 length ];
	fwrite(&nameSize, sizeof(unsigned int), 1, file);
	char* buffer = (char*)malloc(nameSize + 1);
	memcpy(buffer, [ name2 UTF8String ], nameSize);
	buffer[nameSize] = 0;
	fwrite(buffer, nameSize, 1, file);
	free(buffer);
	buffer = NULL;
	// Selected
	unsigned long selectedSize = 0;
	fwrite(&selectedSize, sizeof(unsigned long), 1, file);
	unsigned long otherSel = -1;
	fwrite(&otherSel, sizeof(unsigned long), 1, file);
	fclose(file);
	[ sceneTable editColumn:1 row:[ sceneTable numberOfRows ] - 1 withEvent:nil select:YES ];
}

- (void) sceneRemove:(id)sender
{
	if ([ sceneTable selectedRow ] == -1 || [ sceneTable numberOfRows ] <= 1)
		return;
	long ret = NSRunAlertPanel(@"Confirm", @"Are you sure you want to remove this scene? You cannot undo this action.", @"No", @"Yes", nil);
	if (ret == NSAlertAlternateReturn)
	{
		NSString* path = [ NSString stringWithFormat:@"%@/Scenes/%@.mds", workingDirectory, [ sceneTable selectedRowItemforColumnIdentifier:@"Name" ] ];
		[ [ NSFileManager defaultManager ] removeItemAtPath:path error:nil ];
		[ sceneTable removeRow:(unsigned int)[ sceneTable selectedRow ] ];
		currentScene = [ [ NSString alloc ] initWithString:[ [ sceneTable itemAtRow:0 ] objectForKey:@"Name" ] ];
		[ self read:self project:NO ];
		[ self save:sender ];
	}
}

#pragma mark File Panel

- (void) openFilePanel:(id)sender
{
	if ([ fileOutline selectedNode ] == nil)
		return;
	if ([ [ fileOutline selectedNode ] isParent ])
		return;
	
	NSString* ext = [ [ [ fileOutline selectedNode ] title ] pathExtension ];
	if (!([ ext isEqualToString:@"m" ] || [ ext isEqualToString:@"mm" ] || [ ext isEqualToString:@"c" ] || [ ext isEqualToString:@"cpp" ] || [ ext isEqualToString:@"h" ]))
	{
		// Open in default viewer
		[ [ NSWorkspace sharedWorkspace ] openFile:[ NSString stringWithFormat:@"%@%@%@", workingDirectory, [ [ fileOutline selectedNode ] parentsPath ], [ [ fileOutline selectedNode ] title ] ] ];
		return;
	}
	
	currentOpenFile = [ [ NSString alloc ] initWithFormat:@"%@%@%@", workingDirectory, [ [ fileOutline selectedNode ] parentsPath ], [ [ fileOutline selectedNode ] title ] ];
	NSData* data = [ [ NSFileManager defaultManager ] contentsAtPath:currentOpenFile ];
	NSString* string = [ [ NSString alloc ] initWithData:data encoding:NSUTF8StringEncoding ];
	[ editorView setFileName:currentOpenFile ];
	[ editorView setText:string ];
	for (unsigned long z = 0; z < breakpointFiles.size(); z++)
	{
		if ([ breakpointFiles[z] isEqualToString:currentOpenFile ])
		{
			[ editorView setBreakpoints:breakpoints[z] ];
			break;
		}
	}
	[ editorWindow setLevel:NSFloatingWindowLevel ];
	[ editorWindow makeKeyAndOrderFront:self ];
	// Enable cut copy paste - temp
	[ copyMenu setAction:@selector(copy:) ];
	[ cutMenu setAction:@selector(cut:) ];
	[ pasteMenu setAction:@selector(paste:) ];
	[ undoItem setAction:@selector(undo:) ];
	[ redoItem setAction:@selector(redo:) ];
}

- (void) fileOutlineMenu: (NSEvent*) event
{
	NSMenu* menu = [ [ NSMenu alloc ] init ];
	senderNode = [ fileOutline selectedNode ];
	if (senderNode == nil)
		senderNode = [ fileOutline rootNode ];
	BOOL firstSep = FALSE;
	if ([ [ fileOutline selectedNode ] isParent ])
	{
		[ menu addItemWithTitle:@"New File" action:@selector(showNewFile) keyEquivalent:@"" ];
		firstSep = TRUE;
	}
	if ([ senderNode isParent ])
	{
		[ menu addItemWithTitle:@"New Folder" action:@selector(addNewFolder) keyEquivalent:@"" ];
		firstSep = TRUE;
	}
	if (firstSep && senderNode != [ fileOutline rootNode ])
		[ menu addItem:[ NSMenuItem separatorItem ] ];
	if (senderNode != [ fileOutline rootNode ])
	{
		if (!([ [ senderNode title ] isEqualToString:[ workingDirectory lastPathComponent ] ]) && !([ [ senderNode title ] isEqualToString:@"Resources" ] && [ [ [ senderNode parentItem ] title ] isEqualToString:[ workingDirectory lastPathComponent ] ]))
		{
			[ menu addItemWithTitle:@"Rename" action:@selector(renameFileOutline) keyEquivalent:@"" ];
			[ menu addItemWithTitle:@"Delete" action:@selector(deleteFileOutline) keyEquivalent:@"" ];
			[ menu addItem:[ NSMenuItem separatorItem ] ];
		}
		[ menu addItemWithTitle:@"Add Files" action:@selector(addOutlineFiles) keyEquivalent:@"" ];
		[ menu addItemWithTitle:@"Show In Finder" action:@selector(showInFinder) keyEquivalent:@"" ];
	}
	
	[ NSMenu popUpContextMenu:menu withEvent:event forView:fileOutline ];
}

- (void) fileOutlineEdited: (id)sender withOld:(id)old;
{
	if ([ [ sender title ] length ] == 0)
	{
		[ sender setTitle:[ old title ] ];
		return;
	}
	
	NSArray* array = [ [ (IFNode*)sender parentItem ] children ];
	for (unsigned long z = 0; z < [ array count ]; z++)
	{
		if ([ [ [ array objectAtIndex:z ] title ] isEqualToString:[ sender title ] ] && [ [ array objectAtIndex:z ] isParent ] == [ sender isParent ] && sender != [ array objectAtIndex:z ])
		{
			// Repeat
			NSString* fileOrFolder = ([ sender isParent ] ? @"folder" : @"file");
			NSString* parentTitle = [ NSString stringWithFormat:@"%@%@", workingDirectory, [ sender parentsPath ] ];
			NSString* newTitle = [ sender title ];
			[ sender setTitle:[ old title ] ];
			NSRunAlertPanel(@"Name Already Taken", @"The %@ name \"%@\" is already taken in the folder \"%@\". Choose a different name or folder.", @"Ok", nil, nil, fileOrFolder, newTitle, parentTitle);
			if ([ [ old title ] length ] == 0)
			{
				[ [ (IFNode*)sender parentItem ] removeChild:sender ];
				[ fileOutline reloadData ];
			}
			return;
		}
	}
	
	if ([ [ old title ] length ] == 0)
	{
		// Create Directory
		NSString* fullPath = [ NSString stringWithFormat:@"%@%@%@", workingDirectory, [ sender parentsPath ], [ sender title ] ];
		[ [ NSFileManager defaultManager ] createDirectoryAtPath:fullPath withIntermediateDirectories:YES attributes:nil error:nil ];
	}
	else
	{
		NSString* oldPath = [ NSString stringWithFormat:@"%@%@%@", workingDirectory, [ sender parentsPath ], [ old title ] ];
		NSString* newPath = [ NSString stringWithFormat:@"%@%@%@", workingDirectory, [ sender parentsPath ], [ sender title ] ];
		[ [ NSFileManager defaultManager ] moveItemAtPath:oldPath toPath:newPath error:nil ];
	}
	
	[ self save:sender ];
}

- (void) showNewFile
{
	[ nameFile setStringValue:@"" ];
	[ extensionFile setStringValue:@".mm" ];
	[ includeHFile setState:NSOnState ];
	[ newFileWindow makeKeyAndOrderFront:self ];
}

- (void) addNewFolder
{
	[ fileOutline expandItem:senderNode ];
	IFNode* node = [ [ IFNode alloc ] initParentWithTitle:@"" children:nil ];
	if (senderNode == [ fileOutline rootNode ])
		[ senderNode addChild:node ];
	else
		[ senderNode insertChild:node atIndex:0 ];
	[ fileOutline reloadData ];
	[ fileOutline editColumn:0 row:[ fileOutline rowForItem:node ] withEvent:nil select:YES ];
}

- (void) renameFileOutline
{
	[ fileOutline editColumn:0 row:[ fileOutline selectedRow ] withEvent:nil select:YES ];
}

- (IBAction) addNewFile:(id)sender
{
	[ fileOutline expandItem:senderNode ];
	if ([ includeHFile state ])
	{
		IFNode* node = [ [ IFNode alloc ] initLeafWithTitle:[ NSString stringWithFormat:@"%@.h", [ nameFile stringValue ] ] ];
		[ senderNode addChild:node ];
		NSString* fullPath = [ NSString stringWithFormat:@"%@%@%@", workingDirectory, [ node parentsPath ], [ node title ] ];
		[ [ NSFileManager defaultManager ] createFileAtPath:fullPath contents:[ [ NSString stringWithFormat:@"// %@\n\n", [ node title ] ] dataUsingEncoding:NSASCIIStringEncoding ] attributes:nil ];
	}
	NSString* nameEx = [ NSString stringWithFormat:@"%@%@", [ nameFile stringValue ], [ extensionFile stringValue ] ];
	IFNode* node = [ [ IFNode alloc ] initLeafWithTitle:nameEx ];
	[ senderNode addChild:node ];
	NSString* fullPath = [ NSString stringWithFormat:@"%@%@%@", workingDirectory, [ node parentsPath ], [ node title ] ];
	[ [ NSFileManager defaultManager ] createFileAtPath:fullPath contents:[ [ NSString stringWithFormat:@"// %@\n\n", [ node title ] ] dataUsingEncoding:NSASCIIStringEncoding ] attributes:nil ];
	[ newFileWindow orderOut:self ];
	[ fileOutline reloadData ];
	[ self save:sender ];
}

- (void) addOutlineFiles
{
	NSOpenPanel* openPanel = [ NSOpenPanel openPanel ];
	[ openPanel setAllowsMultipleSelection:YES ];
	[ openPanel setCanChooseFiles:YES ];
	[ openPanel setCanCreateDirectories:NO ];
	[ openPanel setCanChooseDirectories:NO ];
	if ([ openPanel runModal ])
	{
		NSArray* array = [ openPanel URLs ];
		for (int z = 0; z < [ array count ]; z++)
		{
			NSURL* working = [ NSURL fileURLWithPath:[ NSString stringWithFormat:@"%@%@%@/%@", workingDirectory, [ senderNode parentsPath ], [ senderNode title ], [ [ [ [ array objectAtIndex:z ] relativeString ] lastPathComponent ] stringByReplacingPercentEscapesUsingEncoding:NSASCIIStringEncoding ] ] ];
			[ [ NSFileManager defaultManager ] copyItemAtURL:[ array objectAtIndex:z ] toURL:working error:nil ];
			IFNode* node = [ [ IFNode alloc ] initLeafWithTitle:[ [ [ [ array objectAtIndex:z ] relativeString ] lastPathComponent ] stringByReplacingPercentEscapesUsingEncoding:NSASCIIStringEncoding ] ];
			[ senderNode addChild:node ];
		}
		[ fileOutline reloadData ];
		[ self save:self ];
	}
}

- (void) deleteFileOutline
{
	NSString* sel = [ NSString stringWithFormat:@"%@%@", [ senderNode parentsPath ], [ senderNode title ] ];
	long z = NSRunAlertPanel(@"Confirm", @"Do you want to remove this resource from the project or delete it?", @"Cancel", @"Remove", @"Delete");
	if (z != NSAlertDefaultReturn)
	{
		// Resources
		[ [ senderNode parentItem ] removeChild:senderNode ];
		[ fileOutline reloadData ];
		[ self save:self ];
	}
	if (z == NSAlertOtherReturn)
	{
		// Trash
		NSString* str = [ NSString stringWithFormat:@"%@%@", workingDirectory, sel ];
		[ [ NSFileManager defaultManager ] removeItemAtPath:str error:nil ];
	}
}

- (void) showInFinder
{
	NSString* path = [ NSString stringWithFormat:@"%@%@%@", workingDirectory, [ senderNode parentsPath ], [ senderNode title ] ];
	[ [ NSWorkspace sharedWorkspace ] selectFile:path inFileViewerRootedAtPath:@"" ];
}

#pragma mark Library Panel

- (void) selectLibraryObject:(id)sender
{
	// Clear other objects
	for (unsigned long z = 0; z < [ otherObjects count ]; z++)
	{
		[ [ otherObjects objectAtIndex:z ] setSelected:NO ];
		if ([ [ otherObjects objectAtIndex:z ] isKindOfClass:[ MDCamera class ] ])
			[ [ otherObjects objectAtIndex:z ] setLookSelected:NO ];
	}
	
	NSString* type = [ [ [ libraryOutline selectedNode ] dictionary ] objectForKey:@"Type" ];
	if (!type)
	{
		NSString* name = [ [ libraryOutline selectedNode ] title ];
		[ selected clear ];
		for (unsigned long z = 0; z < [ objects count ]; z++)
		{
			if ([ [ [ [ objects objectAtIndex:z ] instance ] name ] isEqualToString:name ])
				[ selected addObject:[ objects objectAtIndex:z ] ];
		}
	}
	else if ([ type isEqualToString:@"Object" ])
	{
		NSString* name = [ [ [ libraryOutline selectedNode ] parentItem ] title ];
		NSString* objName = [ [ libraryOutline selectedNode ] title ];
		[ selected clear ];
		for (unsigned long z = 0; z < [ objects count ]; z++)
		{
			if ([ [ [ [ objects objectAtIndex:z ] instance ] name ] isEqualToString:name ] && [ [ [ objects objectAtIndex:z ] name ] isEqualToString:objName ])
				[ selected addObject:[ objects objectAtIndex:z ] ];
		}
	}
	else
	{
		NSString* name = [ [ libraryOutline selectedNode ] title ];
		for (unsigned int z = 0; z < [ otherObjects count ]; z++)
		{
			if ([ name isEqualToString:[ [ otherObjects objectAtIndex:z ] name ] ])
			{
				[ [ otherObjects objectAtIndex:z ] setSelected:YES ];
				break;
			}
		}
	}
	librarySelection = [ libraryOutline selectedRow ];
	commandFlag |= UPDATE_INFO | UPDATE_OTHER_INFO;
}

- (void) insertLibraryObject:(id)sender
{
	librarySelection = [ libraryOutline selectedRow ];
	NSString* type = [ [ [ libraryOutline itemAtRow:librarySelection ] dictionary ] objectForKey:@"Type" ];
	if (!type)
	{
		NSString* name = [ [ libraryOutline itemAtRow:librarySelection ] title ];
		for (unsigned long z = 0; z < [ instances count ]; z++)
		{
			if ([ [ [ instances objectAtIndex:z ] name ] isEqualToString:name ])
			{
				MDObject* obj2 = [ [ MDObject alloc ] initWithInstance:[ instances objectAtIndex:z ] ];
				NSMutableArray* array = [ NSMutableArray array ];
				for (int z = 0; z < [ objects count ]; z++)
				{
					MDObject* obj = [ [ MDObject alloc ] initWithObject:[ objects objectAtIndex:z ] ];
					[ array addObject:obj ];
				}
				MDSelection* sel = [ [ MDSelection alloc ] init ];
				[ array addObject:obj2 ];
				[ sel addObject:[ array objectAtIndex:[ array count ] - 1 ] ];
				[ undoManager setActionName:@"Create Object" ];
				[ Controller setObjects:array selected:sel andInstances:instances ];
				break;
			}
		}
	}
}

- (void) renameLibraryObject:(id)sender withOld:(id)old
{
	IFNode* selNode = [ libraryOutline selectedNode ];
	if (!selNode && librarySelection != -1)
		selNode = [ libraryOutline itemAtRow:librarySelection ];
	NSString* type = [ [ selNode dictionary ] objectForKey:@"Type" ];
	if (!type)
	{
		NSString* objName = [ old title ];
		NSString* newName = [ selNode title ];
		NSArray* children = [ [ selNode parentItem ] children ];
		// Check if there is the same name
		BOOL success = TRUE;
		for (unsigned long z = 0; z < [ children count ]; z++)
		{
			if ([ children objectAtIndex:z ] == selNode)
				continue;
			if ([ [ [ children objectAtIndex:z ] title ] isEqualToString:newName ])
			{
				NSRunAlertPanel(@"Error", @"\"%@\" is already taken.", @"Ok", nil, nil, newName);
				success = FALSE;
				[ selNode setTitle:objName ];
				[ libraryOutline reloadItem:selNode ];
				break;
			}
		}
		if (success)
		{
			for (unsigned long z = 0; z < [ instances count ]; z++)
			{
				if ([ [ [ instances objectAtIndex:z ] name ] isEqualToString:objName ])
				{
					[ [ NSFileManager defaultManager ] moveItemAtPath:[ NSString stringWithFormat:@"%@/Models/%@.mdm", workingDirectory, objName ] toPath:[ NSString stringWithFormat:@"%@/Models/%@.mdm", workingDirectory, newName ] error:nil ];
					[ (MDInstance*)[ instances objectAtIndex:z ] setName:newName ];
					break;
				}
			}
		}
	}
	else if ([ type isEqualToString:@"Object" ])
	{
		NSString* objName = [ old title ];
		NSString* newName = [ selNode title ];
		NSString* name = [ [ selNode parentItem ] title ];
		NSArray* children = [ [ selNode parentItem ] children ];
		// Check if there is the same name
		BOOL success = TRUE;
		for (unsigned long z = 0; z < [ children count ]; z++)
		{
			if ([ children objectAtIndex:z ] == selNode)
				continue;
			if ([ [ [ children objectAtIndex:z ] title ] isEqualToString:newName ])
			{
				NSRunAlertPanel(@"Error", @"\"%@\" is already taken.", @"Ok", nil, nil, newName);
				success = FALSE;
				[ selNode setTitle:objName ];
				[ libraryOutline reloadItem:selNode ];
				break;
			}
		}
		if (success)
		{
			for (unsigned long z = 0; z < [ objects count ]; z++)
			{
				if ([ [ [ [ objects objectAtIndex:z ] instance ] name ] isEqualToString:name ] && [ [ [ objects objectAtIndex:z ] name ] isEqualToString:objName ])
				{
					[ (MDObject*)[ objects objectAtIndex:z ] setName:newName ];
					break;
				}
			}
		}
	}
	else
	{
		NSString* objName = [ old title ];
		NSString* newName = [ selNode title ];
		NSArray* children = [ [ selNode parentItem ] children ];
		// Check if there is the same name
		BOOL success = TRUE;
		for (unsigned long z = 0; z < [ children count ]; z++)
		{
			if ([ children objectAtIndex:z ] == selNode)
				continue;
			if ([ [ [ children objectAtIndex:z ] title ] isEqualToString:newName ] && [ [ [ children objectAtIndex:z ] dictionary ] objectForKey:@"Type" ])
			{
				NSRunAlertPanel(@"Error", @"\"%@\" is already taken.", @"Ok", nil, nil, newName);
				success = FALSE;
				[ selNode setTitle:objName ];
				[ libraryOutline reloadItem:selNode ];
				break;
			}
		}
		if (success)
		{
			for (unsigned long z = 0; z < [ otherObjects count ]; z++)
			{
				if ([ [ [ otherObjects objectAtIndex:z ] name ] isEqualToString:objName ])
				{
					id objType = [ otherObjects objectAtIndex:z ];
					if ([ objType isKindOfClass:[ MDCamera class ] ])
						[ (MDCamera*)objType setName:newName ];
					else if ([ objType isKindOfClass:[ MDLight class ] ])
						[ (MDLight*)objType setName:newName ];
					else if ([ objType isKindOfClass:[ MDParticleEngine class ] ])
						[ (MDParticleEngine*)objType setName:newName ];
					else if ([ objType isKindOfClass:[ MDCurve class ] ])
						[ (MDCurve*)objType setName:newName ];
					/*if ([ otherNames numberOfRows ] > z)
					{
						[ [ otherNames itemAtRow:(unsigned int)z ] setObject:newName forKey:@"Name" ];
						[ otherNames reloadData ];
					}*/
					commandFlag |= UPDATE_OTHER_INFO;
					break;
				}
			}
		}
	}
	[ self saveWithPics:NO andModels:NO ];
}

- (void) rightLibraryObject:(id)sender
{
	IFNode* selNode = [ libraryOutline selectedNode ];
	if (!selNode && librarySelection != -1)
		selNode = [ libraryOutline itemAtRow:librarySelection ];
	
	[ self selectLibraryObject:sender ];
	NSMenu* menu = [ [ NSMenu alloc ] init ];
	if ([ libraryOutline selectedRow ] != -1)
	{
		NSString* type = [ [ selNode dictionary ] objectForKey:@"Type" ];
		if (!type && selNode)
		{
			[ menu addItemWithTitle:@"Insert Object" action:@selector(insertLibraryObject:) keyEquivalent:@"" ];
			[ menu addItemWithTitle:@"Duplicate Model" action:@selector(copyLibraryObject:) keyEquivalent:@"" ];
			[ menu addItem:[ NSMenuItem separatorItem ] ];
			[ menu addItemWithTitle:@"Show Properties" action:@selector(propertiesLibraryObject:) keyEquivalent:@"" ];
			[ menu addItem:[ NSMenuItem separatorItem ] ];
			[ menu addItemWithTitle:@"Remove Model" action:@selector(deleteLibraryObject:) keyEquivalent:@"" ];
		}
		else if ([ type isEqualToString:@"Object" ])
		{
			[ menu addItemWithTitle:@"Show Properties" action:@selector(showPropertyWindow:) keyEquivalent:@"" ];
			[ menu addItemWithTitle:@"Show Physics Properties" action:@selector(showPhysicsWindow:) keyEquivalent:@"" ];
			[ menu addItem:[ NSMenuItem separatorItem ] ];
			[ menu addItemWithTitle:@"Duplicate Object" action:@selector(duplicate:) keyEquivalent:@"" ];
			[ menu addItem:[ NSMenuItem separatorItem ] ];
			[ menu addItemWithTitle:@"Delete Object" action:@selector(deleteItem:) keyEquivalent:@"" ];
		}
		else
		{
			// TODO: add copy, duplicating, cutting, deleting, creation of other objects with undo support too
			[ menu addItemWithTitle:@"Delete Object" action:@selector(deleteOtherObject:) keyEquivalent:@"" ];
		}
	}
	else
	{
		NSMenuItem* lightsItem = [ [ NSMenuItem alloc ] initWithTitle:@"Create Light" action:nil keyEquivalent:@"" ];
		NSMenu* lightsMenu = [ [ NSMenu alloc ] init ];
		[ lightsMenu addItemWithTitle:@"Directional Light" action:@selector(createDirectionalLight:) keyEquivalent:@"" ];
		[ lightsMenu addItemWithTitle:@"Point Light" action:@selector(createPointLight:) keyEquivalent:@"" ];
		[ lightsMenu addItemWithTitle:@"Spot Light" action:@selector(createSpotLight:) keyEquivalent:@"" ];
		[ lightsItem setSubmenu:lightsMenu ];
		[ menu addItem:lightsItem ];
		[ menu addItemWithTitle:@"Create Camera" action:@selector(createCamera:) keyEquivalent:@"" ];
		[ menu addItemWithTitle:@"Create Sound" action:@selector(createSound:) keyEquivalent:@"" ];
		[ menu addItemWithTitle:@"Create Particle Engine" action:@selector(createParticleEngine:) keyEquivalent:@"" ];
		[ menu addItemWithTitle:@"Create Curve" action:@selector(createCurve:) keyEquivalent:@"" ];
	}
	librarySelection = [ libraryOutline selectedRow ];
	
	[ NSMenu popUpContextMenu:menu withEvent:sender forView:libraryOutline ];
}

- (void) copyLibraryObject:(id)sender
{
	IFNode* selNode = [ libraryOutline selectedNode ];
	if (!selNode && librarySelection != -1)
		selNode = [ libraryOutline itemAtRow:librarySelection ];
	
	NSString* type = [ [ selNode dictionary ] objectForKey:@"Type" ];
	if (!type)
	{
		NSString* objName = [ selNode title ];
		NSString* newName = [ [ selNode title ] stringByAppendingString:@" copy 0" ];
		NSArray* children = [ [ selNode parentItem ] children ];
		// Check if there is the same name
		unsigned long counter = 0;
		for (unsigned long z = 0; z < [ children count ]; z++)
		{
			if ([ children objectAtIndex:z ] == selNode)
				continue;
			if ([ [ [ children objectAtIndex:z ] title ] isEqualToString:newName ])
			{
				counter++;
				newName = [ [ selNode title ] stringByAppendingFormat:@" copy %lu", counter ];
				z = 0;
				continue;
			}
		}
		for (unsigned long z = 0; z < [ instances count ]; z++)
		{
			if ([ [ [ instances objectAtIndex:z ] name ] isEqualToString:objName ])
			{
				MDInstance* instance = [ [ MDInstance alloc ] initWithInstance:[ instances objectAtIndex:z ] ];
				[ instance setName:newName ];
				[ instances addObject:instance ];
				[ [ NSFileManager defaultManager ] copyItemAtPath:[ NSString stringWithFormat:@"%@/Models/%@.mdm", workingDirectory, objName ] toPath:[ NSString stringWithFormat:@"%@/Models/%@.mdm", workingDirectory, newName ] error:nil ];
				[ self saveWithPics:NO andModels:NO ];
				break;
			}
		}
	}
	commandFlag |= UPDATE_LIBRARY;
}

- (void) deleteLibraryObject:(id)sender
{
	IFNode* selNode = [ libraryOutline selectedNode ];
	if (!selNode && librarySelection != -1)
		selNode = [ libraryOutline itemAtRow:librarySelection ];
	
	unsigned long ret = NSRunAlertPanel(@"Confirm", @"Are you sure you want to remove this model from the project? (This cannot be undone.)", @"No", @"Yes", nil);
	if (ret != NSAlertAlternateReturn)
		return;
	
	NSString* type = [ [ selNode dictionary ] objectForKey:@"Type" ];
	if (!type)
	{
		NSString* name = [ selNode title ];
		for (unsigned long z = 0; z < [ objects count ]; z++)
		{
			if ([ [ [ [ objects objectAtIndex:z ] instance ] name ] isEqualToString:name ])
			{
				[ objects removeObjectAtIndex:z ];
				z--;
				continue;
			}
		}
		for (unsigned long z = 0; z < [ instances count ]; z++)
		{
			if ([ [ [ instances objectAtIndex:z ] name ] isEqualToString:name ])
			{
				[ [ NSFileManager defaultManager ] removeItemAtPath:[ NSString stringWithFormat:@"%@/Models/%@.mdm", workingDirectory, name ] error:nil ];
				[ instances removeObjectAtIndex:z ];
				break;
			}
		}
	}
	[ selected clear ];
	commandFlag |= UPDATE_LIBRARY | UPDATE_INFO | UPDATE_OTHER_INFO;
	[ self saveWithPics:NO andModels:NO ];
}

- (void) propertiesLibraryObject:(id)sender
{
	IFNode* selNode = [ libraryOutline selectedNode ];
	if (!selNode && librarySelection != -1)
		selNode = [ libraryOutline itemAtRow:librarySelection ];
	
	NSString* type = [ [ selNode dictionary ] objectForKey:@"Type" ];
	if (!type)
	{
		NSString* name = [ selNode title ];
		for (unsigned long z = 0; z < [ instances count ]; z++)
		{
			if ([ [ [ instances objectAtIndex:z ] name ] isEqualToString:name ])
			{
				NSNumber* number = [ NSNumber numberWithUnsignedLong:z ];
				[ self showPropertyWindow:number ];
				break;
			}
		}
	}
}

- (IBAction) objectMarkHidden:(id)sender
{
	[ undoManager setActionName:@"Hide" ];
	if ([ objectHidden state ] == NSMixedState)
	{
		// Mark them all visible
		for (unsigned long z = 0; z < [ selected count ]; z++)
		{
			MDObject* obj = [ [ MDObject alloc ] initWithObject:[ selected fullValueAtIndex:z  ] ];
			[ obj setShouldView:YES ];
			
			[ Controller setMDObject:obj atIndex:[ objects indexOfObject:[ [ selected selectedValueAtIndex:z ] objectForKey:@"Object" ] ] faceIndex:NSNotFound edgeIndex:NSNotFound pointIndex:NSNotFound selectionIndex:z ];
		}
		[ objectHidden setState:NSOffState ];
	}
	else
	{
		for (unsigned long z = 0; z < [ selected count ]; z++)
		{
			MDObject* obj = [ [ MDObject alloc ] initWithObject:[ selected fullValueAtIndex:z ] ];
			[ obj setShouldView:[ objectHidden state ] ];
			
			[ Controller setMDObject:obj atIndex:[ objects indexOfObject:[ [ selected selectedValueAtIndex:z ] objectForKey:@"Object" ] ] faceIndex:NSNotFound edgeIndex:NSNotFound pointIndex:NSNotFound selectionIndex:z ];
		}
		[ objectHidden setState:![ objectHidden state ] ];
	}
}

#pragma mark Project Menu And Debugger

- (IBAction) compile:(id) sender
{
	[ self saveWithPics:NO andModels:YES ];
	
	// Save current view
	if ([ [ editorView window ] isVisible ])
	{
		[ [ NSFileManager defaultManager ] createFileAtPath:currentOpenFile contents:[ NSData dataWithBytes:[ [ editorView string ] UTF8String ] length:[ [ editorView string ] length ] ] attributes:nil ];
	}
	
	NSArray* array = [ fileOutline allLeafs ];
	NSMutableArray* newArray = [ [ NSMutableArray alloc ] init ];
	for (int z = 0; z < [ array count ]; z++)
	{
		if ([ [ [ array objectAtIndex:z ] title ] hasSuffix:@".m" ] || [ [ [ array objectAtIndex:z ] title ] hasSuffix:@".mm" ] || [ [ [ array objectAtIndex:z ] title ] hasSuffix:@".c" ] || [ [ [ array objectAtIndex:z ] title ] hasSuffix:@".cpp" ])
		{
			[ newArray addObject:[ NSString stringWithFormat:@"%@%@%@", workingDirectory, [ [ array objectAtIndex:z ] parentsPath ], [ [ array objectAtIndex:z ] title ] ] ];
		}
	}
	
	NSArray* array2 = [ [ [ [ fileOutline rootNode ] childWithTitle:[ workingDirectory lastPathComponent ] ] childWithTitle:@"Resources" ] children ];
	NSMutableArray* array3 = [ NSMutableArray array ];
	for (unsigned long z = 0; z < [ array2 count ]; z++)
		[ array3 addObject:[ [ array2 objectAtIndex:z ] title ] ];
	
	// Backup
	NSString* backupScene = [ NSString stringWithString:currentScene ];
	
	NSMutableArray* dataArray = [ [ NSMutableArray alloc ] init ];
	for (unsigned int z = 0; z < [ sceneTable numberOfRows ]; z++)
	{
		currentScene = [ [ NSString alloc ] initWithString:[ [ sceneTable itemAtRow:z ] objectForKey:@"Name" ] ];
		[ self read:self project:NO ];
		NSMutableArray* floats = [ [ NSMutableArray alloc ] init ];
		[ floats addObject:[ NSNumber numberWithUnsignedLong:currentCamera ] ];
		[ floats addObject:[ NSNumber numberWithFloat:translationPoint.x ] ];
		[ floats addObject:[ NSNumber numberWithFloat:translationPoint.y ] ];
		[ floats addObject:[ NSNumber numberWithFloat:translationPoint.z ] ];
		[ floats addObject:[ NSNumber numberWithFloat:lookPoint.x ] ];
		[ floats addObject:[ NSNumber numberWithFloat:lookPoint.y ] ];
		[ floats addObject:[ NSNumber numberWithFloat:lookPoint.z ] ];
		[ floats addObject:[ NSNumber numberWithFloat:[ [ views objectAtIndex:0 ] xrotation ] ] ];
		[ floats addObject:[ NSNumber numberWithFloat:[ [ views objectAtIndex:0 ] yrotation ] ] ];
		[ floats addObject:[ NSNumber numberWithFloat:[ [ views objectAtIndex:0 ] zrotation ] ] ];
		NSDictionary* dict = [ NSDictionary dictionaryWithObjectsAndKeys:[ NSString stringWithString:currentScene ], @"Name", [ NSMutableArray arrayWithArray:objects ], @"Objects", [ NSMutableArray arrayWithArray:otherObjects ], @"Other Objects", floats, @"Floats", nil ];
		[ dataArray addObject:dict ];
	}
	currentScene = [ [ NSString alloc ] initWithString:backupScene ];
	[ self read:self project:NO ];
	
	// Check for Cocoa/Cocoa.h
	if (![ [ NSFileManager defaultManager ] fileExistsAtPath:@"/System/Library/Frameworks/Cocoa.framework/Versions/A/Headers/Cocoa.h" ])
	{
		// Command line tools are not installed
		unsigned long z = NSRunAlertPanel(@"Error", @"It appears that you do not have the command line tools that are necessary for this compiling your applications. You can download them, but you need an Apple Developer account (which is free to make). If you choose not to download and install it, you will still be able to use this application, but you cannot compile your apps. Do you want to download them now?", @"Yes", @"No", nil);
		if (z == NSAlertDefaultReturn)
		{
			[ [ NSWorkspace sharedWorkspace ] openURL:[ NSURL URLWithString: @"https://developer.apple.com/downloads/index.action?name=Command%20Line%20Tools%20(OS%20X%20Mountain%20Lion)%20for%20Xcode%20-" ] ];
			return;
		}
	}
	
	Compile(newArray, editorView, workingDirectory, array3, consoleView, dataArray, [ editorView edited ]);
//	Compile([ NSArray arrayWithObjects:[ NSString stringWithFormat:@"%@%@.mm", workingDirectory, [ workingDirectory lastPathComponent ] ], nil ], editorView, workingDirectory);
	
	// Create backup of all files into backup directory
	[ [ NSFileManager defaultManager ] createDirectoryAtPath:[ NSString stringWithFormat:@"%@backup/", workingDirectory ] withIntermediateDirectories:NO attributes:nil error:nil ];
	[ [ NSFileManager defaultManager ] copyItemAtPath:[ NSString stringWithFormat:@"%@%@/", workingDirectory, [ workingDirectory lastPathComponent ] ] toPath:[ NSString stringWithFormat:@"%@backup/%@", workingDirectory, [ workingDirectory lastPathComponent ] ] error:nil ];
	[ [ NSFileManager defaultManager ] copyItemAtPath:[ NSString stringWithFormat:@"%@Models", workingDirectory ] toPath:[ NSString stringWithFormat:@"%@backup/Models/", workingDirectory ] error:nil ];
	[ [ NSFileManager defaultManager ] copyItemAtPath:[ NSString stringWithFormat:@"%@Scenes", workingDirectory ] toPath:[ NSString stringWithFormat:@"%@backup/Scenes/", workingDirectory ] error:nil ];
	[ [ NSFileManager defaultManager ] copyItemAtPath:[ NSString stringWithFormat:@"%@%@.mdp", workingDirectory, [ workingDirectory lastPathComponent ] ] toPath:[ NSString stringWithFormat:@"%@backup/%@.mdp", workingDirectory, [ workingDirectory lastPathComponent ] ] error:nil ];
}


- (IBAction) compileAndRun:(id)sender
{
	[ self compile:sender ];
	if (![ editorView hasErrors ])
	{
		[ self run:sender ];
	}
}

BOOL waitingExec = FALSE;
NSPipe* inputPipe = nil;

- (IBAction) run:(id)sender
{	
	NSTask* task = [ NSTask new ];
	NSString* path = [ NSString stringWithFormat:@"%@build/%@.app/Contents/MacOS/%@", workingDirectory, [ workingDirectory lastPathComponent ], [ workingDirectory lastPathComponent ] ];
	[ task setLaunchPath:@"/usr/bin/lldb" ];
	//[ task setLaunchPath:[ NSString stringWithFormat:@"%@/LLVM/bin/lldb", [ [ NSBundle mainBundle ] resourcePath ] ] ];
	[ task setArguments:[ NSArray arrayWithObject:path ] ];
	NSPipe* pipe3 = [ NSPipe pipe ];
	NSPipe* pipe = [ NSPipe pipe ];
	inputPipe = pipe;
	[ task setStandardInput:pipe ];
	[ task setStandardOutput:pipe3 ];
	[ task setStandardError:pipe3 ];
	
	[ consoleView setString:@"" ];
	NSFileHandle* handle = [ pipe3 fileHandleForReading ];
	[ [ NSNotificationCenter defaultCenter ] addObserver:self selector:@selector(updateConsoleView:) name:NSFileHandleDataAvailableNotification object:handle ];
	[ handle waitForDataInBackgroundAndNotify ];
	
	[ task launch ];
	
	waitingExec = TRUE;
	
	[ NSThread detachNewThreadSelector:@selector(bringAppToFront) toTarget:self withObject:nil ];
	
	[ editorRunItem setImage:[ NSImage imageNamed:@"Stop.png" ] ];
	[ editorRunItem setLabel:@"Stop" ];
	[ editorRunItem setAction:@selector(stop:) ];
}

- (IBAction) stop:(id)sender
{
	NSTask* task = [ NSTask new ];
	[ task setLaunchPath:@"/usr/bin/killall" ];
	[ task setArguments:[ NSArray arrayWithObject:[ NSString stringWithString:[ workingDirectory lastPathComponent  ] ] ] ];
	[ task launch ];
	appRunning = FALSE;
	
	[ editorRunItem setImage:[ NSImage imageNamed:@"Run.png" ] ];
	[ editorRunItem setLabel:@"Run" ];
	[ editorRunItem setAction:@selector(run:) ];

}

- (IBAction) continuePressed:(id)sender
{
	if (!appRunning)
		return;
	
	NSFileHandle* handle2 = [ inputPipe fileHandleForWriting ];
	[ handle2 writeData:[ @"continue\n" dataUsingEncoding:NSASCIIStringEncoding ] ];
	[ editorView setExecutionLine:0 ];
	[ self bringAppToFront ];
}

- (IBAction) stepOver:(id)sender
{
	if (!appRunning)
		return;
	
	NSFileHandle* handle2 = [ inputPipe fileHandleForWriting ];
	[ handle2 writeData:[ @"next\n" dataUsingEncoding:NSASCIIStringEncoding ] ];
}

- (void) bringAppToFront
{
	@autoreleasepool {
		BOOL found = FALSE;
		while (!found)
		{
			NSArray* apps = [ [ NSWorkspace sharedWorkspace ] runningApplications ];
			for (unsigned long z = 0; z < [ apps count ]; z++)
			{
				NSRunningApplication* obj = [ apps objectAtIndex:z ];
				if ([ [ [ obj bundleURL ] absoluteString ] isEqualToString:[ NSString stringWithFormat:@"file://%@build/%@.app", workingDirectory, [ workingDirectory lastPathComponent ] ] ])
				{
					while (![ obj isActive ])
						[ obj activateWithOptions:NSApplicationActivateAllWindows ];
					found = TRUE;
					break;
				}
			}
		}
	}
}

- (void) updateConsoleView:(NSNotification*)note
{
	NSFileHandle* handle = [ note object ];
	NSString* text = [ [ NSString alloc ] initWithData:[ handle availableData ] encoding:NSASCIIStringEncoding ];
	if ([ text length ] == 0)
		return;
	NSLog(@"%@", text);
	[ handle waitForDataInBackgroundAndNotify ];
	if (waitingExec)
	{
		NSFileHandle* handle2 = [ inputPipe fileHandleForWriting ];
		for (unsigned long z = 0; z < breakpointFiles.size(); z++)
		{
			for (unsigned long q = 0; q < breakpoints[z].size(); q++)
			{
				[ handle2 writeData:[ [ NSString stringWithFormat:@"breakpoint set -f %@ -l %lu\n", [ breakpointFiles[z] lastPathComponent ], breakpoints[z][q] ] dataUsingEncoding:NSASCIIStringEncoding ] ];
			}
		}
		[ handle2 writeData:[ @"run\n" dataUsingEncoding:NSASCIIStringEncoding ] ];
		appRunning = TRUE;
		waitingExec = FALSE;
	}
	else if (deleteAll)
	{
		NSFileHandle* handle2 = [ inputPipe fileHandleForWriting ];
		[ handle2 writeData:[ @"y\n" dataUsingEncoding:NSASCIIStringEncoding ] ];
		deleteAll = FALSE;
		addBreaks = TRUE;
	}
	else if (addBreaks)
	{
		NSFileHandle* handle2 = [ inputPipe fileHandleForWriting ];
		for (unsigned long z = 0; z < breakpointFiles.size(); z++)
		{
			for (unsigned long q = 0; q < breakpoints[z].size(); q++)
			{
				[ handle2 writeData:[ [ NSString stringWithFormat:@"breakpoint set -f %@ -l %lu\n", [ breakpointFiles[z] lastPathComponent ], breakpoints[z][q] ] dataUsingEncoding:NSASCIIStringEncoding ] ];
			}
		}
		addBreaks = FALSE;
	}
	else if ([ text hasPrefix:@"target variable" ])
	{
		unsigned long pos = [ @"target variable " length ];
		NSMutableString* varName = [ [ NSMutableString alloc ] init ];
		while (pos < [ text length ])
		{
			if ([ text characterAtIndex:pos ] == '\n')
				break;
			if ([ text characterAtIndex:pos ] != '\r')
				[ varName appendFormat:@"%c", [ text characterAtIndex:pos ] ];
			pos++;
		}
		// Check all the local objects
		BOOL found = FALSE;
		for (unsigned int z = 0; z < [ variableView numberOfRows ]; z++)
		{
			if ([ varName isEqualToString:[ [ variableView itemAtRow:z ] objectForKey:@"Name" ] ])
			{
				NSMutableString* value = [ [ NSMutableString alloc ] initWithString:[ [ variableView itemAtRow:z ] objectForKey:@"Value" ] ];
				NSString* type = [ [ variableView itemAtRow:z ] objectForKey:@"Type" ];
				[ value replaceOccurrencesOfString:@"\n" withString:@"" options:0 range:NSMakeRange(0, [ value length ]) ];
				
				[ editorView setVariableString:[ NSString stringWithFormat:@"%@\t\t%@\t\t%@", type, varName, value ] ];
				found = TRUE;
				break;
			}
		}
		pos++;
		if (![ [ text substringFromIndex:pos ] hasPrefix:@"error" ] && !found)
		{
			pos++;
			NSMutableString* type = [ [ NSMutableString alloc ] init ];
			unsigned long quantity = 1;
			while (pos < [ text length ])
			{
				if ([ text characterAtIndex:pos ] == '(')
					quantity++;
				else if ([ text characterAtIndex:pos ] == ')')
				{
					quantity--;
					if (quantity == 0)
						break;
				}
				[ type appendFormat:@"%c", [ text characterAtIndex:pos ] ];
				pos++;
			}
			
			pos += 2;
			NSMutableString* name = [ [ NSMutableString alloc ] init ];
			while (pos < [ text length ])
			{
				if ([ text characterAtIndex:pos ] == ' ')
					break;
				[ name appendFormat:@"%c", [ text characterAtIndex:pos ] ];
				pos++;
			}
			
			pos += 3;
			unsigned long oldPos = pos;
			pos = [ text rangeOfString:@"(lldb)" ].location;
			if (pos != NSNotFound)
			{
				NSMutableString* value = [ [ NSMutableString alloc ] initWithString:[ text substringWithRange:NSMakeRange(oldPos, pos- oldPos)] ];
				[ value replaceOccurrencesOfString:@"\n" withString:@"" options:0 range:NSMakeRange(0, [ value length ]) ];
			
				[ editorView setVariableString:[ NSString stringWithFormat:@"%@\t\t%@\t\t%@", type, name, value ] ];
			}
		}
	}
	else if ([ text rangeOfString:@"frame variable\r\n" ].length != 0)
	{
		NSArray* lines = [ text componentsSeparatedByString:@"\n" ];
		[ variableView removeAllRows ];
		for (unsigned long z = 1; z < [ lines count ] - 1; z++)
		{
			NSString* string = [ lines objectAtIndex:z ];
			NSMutableString* type = [ [ NSMutableString alloc ] init ];
			unsigned long pos = 1;
			unsigned long quantity = 1;
			while (pos < [ string length ])
			{
				if ([ string characterAtIndex:pos ] == '(')
					quantity++;
				else if ([ string characterAtIndex:pos ] == ')')
				{
					quantity--;
					if (quantity == 0)
						break;
				}
				[ type appendFormat:@"%c", [ string characterAtIndex:pos ] ];
				pos++;
			}
			
			pos += 2;
			if (pos > [ string length ])
				continue;
			
			NSMutableString* name = [ [ NSMutableString alloc ] init ];
			while (pos < [ string length ])
			{
				if ([ string characterAtIndex:pos ] == ' ')
					break;
				[ name appendFormat:@"%c", [ string characterAtIndex:pos ] ];
				pos++;
			}
			
			pos += 3;
			if (pos > [ string length ])
				continue;
			NSString* value = [ [ NSString alloc ] initWithString:[ string substringWithRange:NSMakeRange(pos, [ string length ] - pos)] ];
			
			[ variableView addRow:[ NSDictionary dictionaryWithObjectsAndKeys:type, @"Type", name, @"Name", value, @"Value", nil ] ];
		}
		[ variableView reloadData ];
	}
	else if ([ text rangeOfString:@", stop reason =" ].length != 0)
	{
		// App was stopped
		if (!appRunning)
		{
			// Need to continue then quit
			NSFileHandle* handle2 = [ inputPipe fileHandleForWriting ];
			[ handle2 writeData:[ @"continue\nquit\n" dataUsingEncoding:NSASCIIStringEncoding ] ];
			return;
		}
		
		// Breakpoint reached
		unsigned long loc = [ text rangeOfString:@", queue =" ].location - 1;
		unsigned long line = 0;
		unsigned base = 0;
		while (loc != -1 && [ text characterAtIndex:loc ] != ':')
		{
			char cmd = [ text characterAtIndex:loc ] - '0';
			if (cmd > 9)
				break;
			line += pow(10, base) * cmd;
			base++;
			loc--;
		}
		loc--;
		NSMutableString* file = [ [ NSMutableString alloc ] init ];
		while (loc != -1 && [ text characterAtIndex:loc ] != ' ')
		{
			char cmd = [ text characterAtIndex:loc ];
			[ file insertString:[ NSString stringWithFormat:@"%c", cmd ] atIndex:0 ];
			loc--;
		}
		
		for (unsigned long z = 0; z < breakpointFiles.size(); z++)
		{
			if ([ breakpointFiles[z] hasSuffix:file ])
			{
				NSArray* apps = [ [ NSWorkspace sharedWorkspace ] runningApplications ];
				for (unsigned long z = 0; z < [ apps count ]; z++)
				{
					NSRunningApplication* obj = [ apps objectAtIndex:z ];
					if ([ [ [ obj bundleURL ] absoluteString ] isEqualToString:[ [ [ NSBundle mainBundle ] bundleURL ] absoluteString ] ])
					{
						[ obj activateWithOptions:0 ];
						break;
					}
				}
				
				[ file setString:breakpointFiles[z] ];
				
				if (![ [ editorView fileName ] isEqualToString:breakpointFiles[z] ])
				{
					NSData* data = [ [ NSFileManager defaultManager ] contentsAtPath:breakpointFiles[z] ];
					NSString* string = [ [ NSString alloc ] initWithData:data encoding:NSUTF8StringEncoding ];
					[ editorView setFileName:breakpointFiles[z] ];
					[ editorView setText:string ];
					[ editorView setBreakpoints:breakpoints[z] ];
				}
				[ editorView setExecutionLine:line ];
				[ editorWindow setLevel:NSFloatingWindowLevel ];
				[ editorWindow makeKeyAndOrderFront:self ];
				// Enable cut copy paste - temp
				[ copyMenu setAction:@selector(copy:) ];
				[ cutMenu setAction:@selector(cut:) ];
				[ pasteMenu setAction:@selector(paste:) ];
				[ undoItem setAction:@selector(undo:) ];
				[ redoItem setAction:@selector(redo:) ];
				break;
			}
		}
		
		NSFileHandle* handle2 = [ inputPipe fileHandleForWriting ];
		[ handle2 writeData:[ @"frame variable\n" dataUsingEncoding:NSASCIIStringEncoding ] ];
	}
	else if ([ text rangeOfString:@"exited with status = " ].length != 0)
	{
		if (appRunning)
		{
			NSFileHandle* handle2 = [ inputPipe fileHandleForWriting ];
			[ handle2 writeData:[ @"quit\n" dataUsingEncoding:NSASCIIStringEncoding ] ];
			appRunning = FALSE;
			
			[ editorRunItem setImage:[ NSImage imageNamed:@"Run.png" ] ];
			[ editorRunItem setLabel:@"Run" ];
			[ editorRunItem setAction:@selector(run:) ];
		}
	}
	else if ([ text hasPrefix:@"expr" ] || [ text hasPrefix:@"next" ] || [ text hasPrefix:@"continue" ] || [ text hasPrefix:@"run" ] || [ text hasPrefix:@"Process " ] || [ text hasPrefix:@"breakpoint" ] || [ text hasPrefix:@"Breakpoint" ] || ([ text hasPrefix:@"(lldb)" ] && ![ text isEqualToString:@"(lldb)" ]))
	{
		// Don't write to console
	}
	else
	{
		[ [ consoleView textStorage ] appendAttributedString:[ [ NSAttributedString alloc ] initWithString:text ] ];
		[ consoleView scrollRangeToVisible:NSMakeRange([ [ consoleView string ] length ], 0) ];
	}
}

- (void) variableTableEdited:(id)sender
{
	NSString* varName = [ variableView selectedRowItemforColumnIdentifier:@"Name" ];
	NSString* newValue = [ variableView selectedRowItemforColumnIdentifier:@"Value" ];
	NSFileHandle* handle2 = [ inputPipe fileHandleForWriting ];
	[ handle2 writeData:[ [ NSString stringWithFormat:@"expr %@ = %@\n", varName, newValue ] dataUsingEncoding:NSASCIIStringEncoding ] ];
}

- (void) updateEditorBreaks
{
	if (appRunning)
	{
		NSFileHandle* handle2 = [ inputPipe fileHandleForWriting ];
		[ handle2 writeData:[ @"breakpoint delete\nY\n" dataUsingEncoding:NSASCIIStringEncoding ] ];
		deleteAll = TRUE;
		for (unsigned long z = 0; z < breakpointFiles.size(); z++)
		{
			if ([ breakpointFiles[z] isEqualToString:[ editorView fileName ] ])
			{
				breakpoints[z] = [ editorView breakpoints ];
				break;
			}
		}
	}
	else
	{
		for (unsigned long z = 0; z < breakpointFiles.size(); z++)
		{
			if ([ breakpointFiles[z] isEqualToString:[ editorView fileName ] ])
			{
				breakpoints[z] = [ editorView breakpoints ];
				break;
			}
		}
	}
}

- (void) updateVariableText:(NSString*)name
{
	if (!appRunning)
		return;
	
	NSFileHandle* handle2 = [ inputPipe fileHandleForWriting ];
	[ handle2 writeData:[ [ NSString stringWithFormat:@"target variable %@\n", name ] dataUsingEncoding:NSASCIIStringEncoding ] ];
}

- (void) updateVar:(NSString*)name value:(NSString*)varValue
{
	if (!appRunning)
		return;
	
	if ([ varValue hasPrefix:@"{" ])
	{
		NSFileHandle* handle2 = [ inputPipe fileHandleForWriting ];
		unsigned long pos = 1;
		while (pos < [ varValue length ])
		{
			pos = PositionAfterSpaces(pos, varValue, YES);
			NSString* realName = WordFromIndex(pos, varValue);
			if ([ realName length ] == 0)
				break;
			pos += [ realName length ];
			pos = PositionAfterSpaces(PositionAfterSpaces(pos, varValue, NO) + 1, varValue, NO);
			NSString* value = ValueFromIndex(pos, varValue);
			if ([ value hasSuffix:@"}" ])
				value = [ value substringToIndex:[ value length ] - 1 ];
			pos += [ value length ];
			
			[ handle2 writeData:[ [ NSString stringWithFormat:@"expr %@.%@ = %@\n", name, realName, value ] dataUsingEncoding:NSASCIIStringEncoding ] ];
		}
	}
	else
	{
		NSFileHandle* handle2 = [ inputPipe fileHandleForWriting ];
		[ handle2 writeData:[ [ NSString stringWithFormat:@"expr %@ = %@\n", name, varValue ] dataUsingEncoding:NSASCIIStringEncoding ] ];
	}
}

#pragma mark Importing

// TODO: add animation support for MovieDraw models
- (IBAction) importFromMDModel:(id)sender
{
	NSOpenPanel* panel = [ NSOpenPanel openPanel ];
	[ panel setAllowedFileTypes:[ NSArray arrayWithObjects:@"mdm", nil ] ];
	[ panel beginSheetModalForWindow:glWindow completionHandler:^(NSInteger result)
	{
		// If create pressed
		if (result == NSAlertDefaultReturn)
		{
			NSMutableString* path = [ [ NSMutableString alloc ] initWithString:[ [ [ panel URL ] absoluteString ] substringFromIndex:7  ] ];
			[ path replaceOccurrencesOfString:@"%20" withString:@" " options:0 range:NSMakeRange(0, [ path length ]) ];
			
			MDInstance* instance = MDReadModel(path);
			
			MDObject* obj = [ [ MDObject alloc ] initWithInstance:instance ];
			obj.objectColors[0].x = obj.objectColors[1].z = obj.objectColors[2].x = obj.objectColors[2].y = 0.7;
			obj.objectColors[0].w = obj.objectColors[1].w = obj.objectColors[2].w = 1;
			
			// Set the correct name
			for (unsigned long q = 0; true; q++)
			{
				[ instance setName:[ NSString stringWithFormat:@"%@ %lu", [ [ path lastPathComponent ] stringByDeletingPathExtension ], q ] ];
				BOOL end = TRUE;
				for (unsigned long z = 0; z < [ instances count ]; z++)
				{
					if ([ [ [ instances objectAtIndex:z ] name ] isEqualToString:[ instance name ] ])
					{
						end = FALSE;
						break;
					}
				}
				if (end)
					break;
			}
			[ instance setMidPoint:MDVector3Create(0, 0, 0) ];
			[ obj setTranslateX:0 ];
			[ obj setTranslateY:5 ];
			[ obj setTranslateZ:0 ];
			[ instances addObject:instance ];
			commandFlag |= UPDATE_LIBRARY;
			
			NSMutableArray* array = [ NSMutableArray array ];
			for (int z = 0; z < [ objects count ]; z++)
			{
				MDObject* obj2 = [ [ MDObject alloc ] initWithObject:[ objects objectAtIndex:z ] ];
				[ array addObject:obj2 ];
			}
			[ array addObject:obj ];
			[ undoManager setActionName:@"Import Model" ];
			MDSelection* selection = [ [ MDSelection alloc ] init ];
			if (currentMode == MD_OBJECT_MODE)
				[ selection addObject:obj ];
			[ Controller setObjects:array selected:selection andInstances:instances ];
			
			[ [ glWindow glView ] loadNewTextures ];
		}
	} ];
}

- (IBAction) importFromModel:(id)sender
{
	NSOpenPanel* panel = [ NSOpenPanel openPanel ];
	[ panel setAllowedFileTypes:ImportAvailableFileTypes() ];
	[ panel beginSheetModalForWindow:glWindow completionHandler:^(NSInteger result)
	{
		if (result == NSAlertDefaultReturn)
		{
			NSMutableString* path = [ [ NSMutableString alloc ] initWithString:[ [ [ panel URL ] absoluteString ] substringFromIndex:7  ] ];
			[ path replaceOccurrencesOfString:@"%20" withString:@" " options:0 range:NSMakeRange(0, [ path length ]) ];
			MDInstance* instance = ObjectFromFile(path);
			if (instance)
			{
				// Copy textures
				NSMutableArray* array = [ [ NSMutableArray alloc ] init ];
				for (unsigned long z = 0; z < [ instance numberOfMeshes ]; z++)
				{
					MDMesh* mesh = [ instance meshAtIndex:z ];
					for (unsigned long q = 0; q < [ mesh numberOfTextures ]; q++)
					{
						MDTexture* texture = [ mesh textureAtIndex:q ];
						[ array addObject:[ NSURL fileURLWithPath:[ texture path ] ] ];
						[ texture setPath:[ NSString stringWithFormat:@"%@%@/Resources/%@", workingDirectory, [ workingDirectory lastPathComponent ], [ [ texture path ] lastPathComponent ] ] ];
					}
				}
				senderNode = [ [ [ fileOutline rootNode ] childAtIndex:0 ] childWithTitle:@"Resources" ];
				for (unsigned long z = 0; z < [ array count ]; z++)
				{
					NSURL* working = [ NSURL fileURLWithPath:[ NSString stringWithFormat:@"%@%@%@/%@", workingDirectory, [ senderNode parentsPath ], [ senderNode title ], [ [ [ [ array objectAtIndex:z ] relativeString ] lastPathComponent ] stringByReplacingPercentEscapesUsingEncoding:NSASCIIStringEncoding ] ] ];
					[ [ NSFileManager defaultManager ] copyItemAtURL:[ array objectAtIndex:z ] toURL:working error:nil ];
					IFNode* node = [ [ IFNode alloc ] initLeafWithTitle:[ [ [ [ array objectAtIndex:z ] relativeString ] lastPathComponent ] stringByReplacingPercentEscapesUsingEncoding:NSASCIIStringEncoding ] ];
					if (![ senderNode childWithTitle:[ node title ] ])
						[ senderNode addChild:node ];
				}
				[ fileOutline reloadData ];
				[ self save:sender ];
				
				// Set the correct name
				for (unsigned long q = 0; true; q++)
				{
					[ instance setName:[ NSString stringWithFormat:@"%@ %lu", [ [ path lastPathComponent ] stringByDeletingPathExtension ], q ] ];
					BOOL end = TRUE;
					for (unsigned long z = 0; z < [ instances count ]; z++)
					{
						if ([ [ [ instances objectAtIndex:z ] name ] isEqualToString:[ instance name ] ])
						{
							end = FALSE;
							break;
						}
					}
					if (end)
						break;
				}
				[ instances addObject:instance ];
				commandFlag |= UPDATE_LIBRARY;
				
				MDObject* obj = [ [ MDObject alloc ] initWithInstance:instance ];
				
				[ obj setTranslateY:5 ];
				
				array = [ NSMutableArray array ];
				for (int z = 0; z < [ objects count ]; z++)
				{
					MDObject* obj2 = [ [ MDObject alloc ] initWithObject:[ objects objectAtIndex:z ] ];
					[ array addObject:obj2 ];
				}
				[ array addObject:obj ];
				[ undoManager setActionName:@"Import Collada" ];
				MDSelection* selection = [ [ MDSelection alloc ] init ];
				if (currentMode == MD_OBJECT_MODE)
					[ selection addObject:obj ];
				[ Controller setObjects:array selected:selection andInstances:instances ];
				
				[ [ glWindow glView ] loadNewTextures ];
			}
		}
	} ];
}

#pragma mark Exporting

void UpdateAnimations(NSDictionary* anims, MDObject* obj, MDObject* current)
{
	NSMutableArray* objAnims = nil;//[ obj animations ];
	
	// Check to see if it already contains the animation
	NSMutableArray* keys = [ NSMutableArray array ];
	//NSString* name = [ anims objectForKey:@"Name" ];
	BOOL add = TRUE;
	for (unsigned long z = 0; z < [ objAnims count ]; z++)
	{
		NSDictionary* checkDict = [ objAnims objectAtIndex:z ];
		if ([ [ checkDict objectForKey:@"Name" ] isEqualToString:[ anims objectForKey:@"Name" ] ])
		{
			NSMutableArray* keyFrames1 = [ checkDict objectForKey:@"KeyFrames" ];
			NSMutableArray* keyFrames2 = [ anims objectForKey:@"KeyFrames" ];
			if ([ keyFrames1 count ] != [ keyFrames2 count ])
				break;
			BOOL stop = FALSE;
			for (unsigned long y = 0; y < [ keyFrames1 count ]; y++)
			{
				//NSArray* changes1 = [ [ keyFrames1 objectAtIndex:y ] objectForKey:@"Changes" ];
				unsigned long length1 = [ [ [ keyFrames1 objectAtIndex:y ] objectForKey:@"Time" ] unsignedLongValue ];
				unsigned long type1 = [ [ [ keyFrames1 objectAtIndex:y ] objectForKey:@"Type" ] unsignedLongValue ];
				//NSArray* changes2 = [ [ keyFrames2 objectAtIndex:y ] objectForKey:@"Changes" ];
				unsigned long length2 = [ [ [ keyFrames2 objectAtIndex:y ] objectForKey:@"Time" ] unsignedLongValue ];
				unsigned long type2 = [ [ [ keyFrames2 objectAtIndex:y ] objectForKey:@"Type" ] unsignedLongValue ];
				if (/*[ changes1 count ] != [ changes2 count ] || */length1 != length2 || type1 != type2)
				{
					stop = TRUE;
					break;
				}
			}
			if (stop)
				break;
			keys = keyFrames1;
			add = FALSE;
		}
	}
	
	NSArray* realKeys = [ anims objectForKey:@"KeyFrames" ];
	for (unsigned long z = 0; z < [ realKeys count ]; z++)
	{
		unsigned long length = [ [ [ realKeys objectAtIndex:z ] objectForKey:@"Time" ] unsignedLongValue ];
		unsigned long type = [ [ [ realKeys objectAtIndex:z ] objectForKey:@"Type" ] unsignedLongValue ];
		NSMutableArray* newChanges = [ NSMutableArray array ];
		if (!add)
			newChanges = [ [ keys objectAtIndex:z ] objectForKey:@"Changes" ];
		NSArray* changes = [ [ realKeys objectAtIndex:z ] objectForKey:@"Changes" ];
		for (unsigned long q = 0; q < [ changes count ]; q++)
		{
			NSString* string = [ [ changes objectAtIndex:q ] objectForKey:@"Change" ];
			unsigned long num = [ string integerValue ];
			float value = [ [ [ changes objectAtIndex:q ] objectForKey:@"Value" ] floatValue ];
			if (num == 12)
			{
				NSScanner* scan = [ NSScanner scannerWithString:string ];
				long repNum = 0;
				[ scan scanInteger:&repNum ];
				[ scan scanString:@", " intoString:nil ];
				long faceIndex = 0;
				[ scan scanInteger:&faceIndex ];
				[ scan scanString:@", " intoString:nil ];
				long pointIndex = 0;
				[ scan scanInteger:&pointIndex ];
				[ scan scanString:@", " intoString:nil ];
				long arg = 0;
				[ scan scanInteger:&arg ];
				
				//faceIndex += [ obj numberOfFaces ];
				[ newChanges addObject:[ NSDictionary dictionaryWithObjectsAndKeys:[ NSString stringWithFormat:@"12, %li, %li, %li", faceIndex, pointIndex, arg ], @"Change", [ NSNumber numberWithFloat:value ], @"Value", nil ] ];
			}
			else if (num >= 6 && num <= 8)
			{
				/*for (unsigned long t = 0; t < [ current numberOfFaces ]; t++)
				{
					unsigned long faceIndex = [ obj numberOfFaces ] + t;
					[ newChanges addObject:[ NSDictionary dictionaryWithObjectsAndKeys:[ NSString stringWithFormat:@"13, %li, %li", faceIndex, num - 6 ], @"Change", [ NSNumber numberWithFloat:value ], @"Value", nil ] ];
				}*/
			}
			else
			{
				[ newChanges addObject:[ NSDictionary dictionaryWithObjectsAndKeys:[ NSString stringWithFormat:@"0" ], @"Change", [ NSNumber numberWithFloat:0 ], @"Value", nil ] ];
			}
		}
		if (add && [ newChanges count ] != 0)
		{
			[ keys addObject:[ NSDictionary dictionaryWithObjectsAndKeys:newChanges, @"Changes", [ NSNumber numberWithUnsignedLong:length ], @"Time", [ NSNumber numberWithUnsignedLong:type ], @"Type", nil ] ];
		}
	}
	
	//if (add)
	//	[ [ obj animations ] addObject:[ NSDictionary dictionaryWithObjectsAndKeys:name, @"Name", keys, @"KeyFrames", nil ] ];
}

- (IBAction) exportToModel:(id)sender
{
	if ([ selected count ] == 0)
	{
		NSRunAlertPanel(@"Selection Needed", @"You need to select the objects you want to export.", @"Ok", nil, nil);
		return;
	}
	
	NSSavePanel* panel = [ NSSavePanel savePanel ];
	[ panel setAllowedFileTypes:[ NSArray arrayWithObjects:@"mdm", nil ] ];
	[ panel beginSheetModalForWindow:glWindow completionHandler:^(NSInteger result)
	{
		// If create pressed
		if (result == NSAlertDefaultReturn)
		{
			NSMutableString* path = [ [ NSMutableString alloc ] initWithString:[ [ [ panel URL ] absoluteString ] substringFromIndex:7  ] ];
			[ path replaceOccurrencesOfString:@"%20" withString:@" " options:0 range:NSMakeRange(0, [ path length ]) ];
			
			MDObject* obj = [ [ MDObject alloc ] init ];
			MDInstance* instance = [ [ MDInstance alloc ] init ];
			for (int z = 0; z < [ selected count ]; z++)
			{
				MDInstance* obj2 = ApplyTransformationInstance([ selected fullValueAtIndex:z ]);
				
				// Transform Animations
				/*NSMutableArray* anims = [ obj2 animations ];
				for (unsigned int z = 0; z < [ anims count ]; z++)
					UpdateAnimations([ anims objectAtIndex:z ], obj, obj2);*/
				
				/*for (int y = 0; y < [ obj2 numberOfPoints ]; y++)
				{
					MDPoint* p = [ [ MDPoint alloc ] initWithPoint:[ obj2 pointAtIndex:y ] ];
					[ instance addPoint:p ];
					[ p release ];
				}
				

				for (unsigned long q = 0; q < [ obj2 numberOfMeshes ]; q++)
				{
					MDMesh* mesh = [ obj2 meshAtIndex:q ];
					
					[ instance beginMesh ];
					for (unsigned int t = 0; t < [ mesh numberOfIndices ]; t++)
						[ instance addIndex:[ mesh indexAtIndex:t ] + startIndex ];
					for (unsigned int t = 0; t < [ mesh numberOfTextures ]; t++)
					{
						MDTexture* texture = [ mesh textureAtIndex:t ];
						[ instance addTexture:[ texture path ] withType:[ texture type ] withHead:[ texture head ] withSize:[ texture size ] ];
					}
					[ instance setColor:[ mesh color ] ];
					[ instance endMesh ];
				}
				startIndex += [ obj2 numberOfPoints ];*/
				
				for (unsigned long q = 0; q < [ obj2 numberOfMeshes ]; q++)
				{
					MDMesh* mesh = [ [ MDMesh alloc ] initWithMesh:[ obj2 meshAtIndex:q ] ];
					[ instance addMesh:mesh ];
				}
			}
			[ obj setInstance:instance ];
			
			MDWriteModel(path, instance, obj);
		}
	} ];
}

#pragma mark Window Delegate

- (BOOL) windowShouldClose: (NSWindow*)window
{
	if (window == [ infoTable window ])
		[ self viewInfoPanel:viewInfoPanel ];
	else if (window == inspectorPanel)
		[ self viewInspectorPanel:viewInspectorPanel ];
	else if (window == consoleWindow)
		[ self viewConsolePanel:viewConsolePanel ];
	else if (window == projectWindow)
		[ self viewProjectPanel:viewProjectPanel ];
	else if (window == createShapePanel)
		[ self cancelShapeCode:createShapePanel ];
	else if (window == createText)
		[ self createTextCancel:createText ];
	else if (window == editorWindow)
	{
		// Set old copy cut paste
		if ([ selected count ] == 0)
		{
			[ copyMenu setAction:nil ];
			[ cutMenu setAction:nil ];
		}
		else
		{
			[ copyMenu setAction:@selector(copy:) ];
			[ cutMenu setAction:@selector(cut:) ];
		}
		if (copyData.size() == 0)
			[ pasteMenu setAction:nil ];
		else
			[ pasteMenu setAction:@selector(paste:) ];
		[ undoItem setAction:([ undoManager canUndo ] ? @selector(undo:) : nil) ];
		[ redoItem setAction:([ undoManager canRedo ] ? @selector(redo:) : nil) ];
		
		[ self save:self ];
	}
	else if (window == glWindow)
	{
		if ([ glWindow isVisible ] && documentEdited)
		{
			unsigned long z = NSRunAlertPanel(@"Confirm", @"If you close this window, you will lose unsaved data. Do you want to save?", @"Cancel", @"Save", @"Dont Save");
			if (z == NSAlertDefaultReturn)
				return NO;
			else if (z == NSAlertAlternateReturn)
				[ self save:self ];
		}
		
		// Cleanup
		[ undoManager removeAllActions ];
		[ undoItem setAction:nil ];
		[ redoItem setAction:nil ];
		[ saveMenu setAction:nil ];
		[ toolMenu setHidden:YES ];
		[ importMenu setEnabled:NO ];
		[ exportMenu setEnabled:NO ];
		[ sceneMenu setHidden:YES ];
		[ objectMenu setHidden:YES ];
		[ createMenu setHidden:YES ];
		[ selectAllMenu setAction:nil ];
		[ projectMenu setHidden:YES ];
		[ viewInspectorPanel setAction:nil ];
		[ viewInfoPanel setAction:nil ];
		[ viewConsolePanel setAction:nil ];
		[ viewProjectPanel setAction:nil ];
		[ copyMenu setAction:nil ];
		[ duplicateMenu setAction:nil ];
		[ deleteMenu setAction:nil ];
		[ pasteMenu setAction:nil ];
		[ pastePlaceMenu setAction:nil ];
		[ cutMenu setAction:nil ];
		[ objectCombine setAction:nil ];
		[ objectTrans setAction:nil ];
		[ objectNormalize setEnabled:NO ];
		[ objectAddTexture setAction:nil ];
		[ objectReverseWinding setAction:nil ];
		[ objectSetHeight setAction:nil ];
		[ objectExportHeight setAction:nil ];
		[ objectProperties setAction:nil ];
		[ objectPhysicsProperties setAction:nil ];
		[ objectAnimations setAction:nil ];
		[ objectHidden setAction:nil ];
		[ objectHidden setState:NSOffState ];
		if ([ inspectorPanel isVisible ])
			[ self viewInspectorPanel:viewInspectorPanel ];
		if ([ infoWindow isVisible ])
			[ self viewInfoPanel:viewInfoPanel ];
		if ([ consoleWindow isVisible ])
			[ self viewConsolePanel:viewConsolePanel ];
		if ([ projectWindow isVisible ])
			[ self viewProjectPanel:viewProjectPanel ];
	}
	return YES;
}

#pragma mark Application Delegate

- (NSApplicationTerminateReply) applicationShouldTerminate:(NSApplication*)sender
{
	if ([ glWindow isVisible ] && documentEdited)
	{
		unsigned long z = NSRunAlertPanel(@"Confirm", @"If you quit, you will lose unsaved data. Do you want to save?", @"Cancel", @"Save", @"Dont Save");
		if (z == NSAlertDefaultReturn)
			return NSTerminateCancel;
		else if (z == NSAlertAlternateReturn)
			[ self save:self ];
	}
	
	return NSTerminateNow;
}

@end
