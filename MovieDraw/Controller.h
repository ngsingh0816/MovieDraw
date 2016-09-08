//
//  Controller.h
//  MovieDraw
//
//  Created by MILAP on 3/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TableWindow.h"
#import "OutlineWindow.h"
#import "CodeHelpView.h"
#import "GLWindow.h"
#import "SettingView.h"
#import "ShapeSettings.h"
#import "MDTypes.h"
#import "MDCodeView.h"
#import "MDCollada.h"
#import "MDImporter.h"
#import "MDTabSwitcher.h"

#define MD_PROJECT_SHOW_GRID		(1 << 0)
#define MD_PROJECT_DISABLE			(1 << 1)
#define MD_PROJECT_CODESIGN			(1 << 2)

// Gloabals
extern NSString* workingDirectory;
extern NSSize projectRes;
extern NSString* currentScene;
extern unsigned int projectAntialias;
extern unsigned int projectFPS;
extern NSString* projectIcon;
extern unsigned int projectCommand;
extern NSMutableDictionary* searchPaths;
extern NSString* projectScene;
extern NSUndoManager* undoManager;
extern NSMutableArray* objects;
extern NSMutableIndexSet* alphaObjects;
extern NSMutableArray* instances;
extern NSMutableArray* otherObjects;
extern NSMutableDictionary* sceneProps;
extern NSMutableDictionary* projectProps;
extern std::vector<std::vector<unsigned long>> breakpoints;
extern std::vector<NSString*> breakpointFiles;
extern BOOL documentEdited;
extern NSString* projectCertificate;
extern NSString* projectAuthor;
#define sceneProperties	[ sceneProps objectForKey:currentScene ]

typedef NS_ENUM(int, MDTool)
{
	MD_SELECTION_TOOL = 0,
	MD_MOVE_TOOL,
	MD_ZOOM_TOOL,
	MD_ROTATE_TOOL,
};
extern MDTool currentTool;

typedef NS_ENUM(int, MDMode)
{
	MD_OBJECT_MODE = 0,
	MD_FACE_MODE,
	MD_EDGE_MODE,
	MD_VERTEX_MODE,
};
extern MDMode currentMode;

typedef NS_ENUM(int, MDObjectTool)
{
	MD_OBJECT_NO = 0,
	MD_OBJECT_MOVE,
	MD_OBJECT_SIZE,
	MD_OBJECT_ROTATE,
};
extern MDObjectTool currentObjectTool;

#define UPDATE_INFO			(1 << 0)
#define SHAPE				(1 << 1)
#define SHAPE2				(1 << 2)
#define UPDATE_SCENE_INFO	(1 << 3)
#define UPDATE_OTHER_INFO	(1 << 4)
#define CLEAR_LENGTHS		(1 << 5)
#define UPDATE_LIBRARY		(1 << 6)
extern unsigned long commandFlag;
extern MDSelection* selected;
extern unsigned long currentCamera;

// Used to be use for showing lengths - can make it for all viewing modifiers?
extern unsigned long conditionsFlag;

extern NSMutableArray* currentObject;
extern NSString* currentShapePath;

extern std::vector<MDObject*> copyData;

extern BOOL appRunning;

@interface Controller : NSResponder {
	// Intro Window
    IBOutlet NSWindow* introWindow;
	IBOutlet NSImageView* imageView;
	IBOutlet NSButton* openRecentButton;
	IBOutlet NSPopUpButton* openRecentPopup;
	IBOutlet NSPopUpButton* openHeaderPopup;
	
	// Menu
	IBOutlet NSMenuItem* openRecent;
	
	// New Project
	IBOutlet NSWindow* newProjectWindow;
	IBOutlet NSTextField* projectName;
	IBOutlet NSComboBox* projectResolution;
	
	// Info Window
	IBOutlet NSPanel* infoWindow;
	IBOutlet OutlineWindow* infoTable;
	
	// OpenGL Window
	IBOutlet GLWindow* glWindow;
	
	// Shapes
	IBOutlet NSWindow* shapeSettings;
	IBOutlet OutlineWindow* outlineShape;
	IBOutlet NSScrollView* shapeScrollView;
	
	// Menu
	IBOutlet NSMenuItem* saveMenu;
	IBOutlet NSMenuItem* toolMenu;
	IBOutlet NSMenuItem* sceneMenu;
	IBOutlet NSMenuItem* objectMenu;
	IBOutlet NSMenuItem* objectTrans;
	IBOutlet NSMenuItem* objectCombine;
	IBOutlet NSMenuItem* objectNormalize;
	IBOutlet NSMenuItem* objectAddTexture;
	IBOutlet NSMenuItem* objectReverseWinding;
	IBOutlet NSMenuItem* objectSetHeight;
	IBOutlet NSMenuItem* objectExportHeight;
	IBOutlet NSMenuItem* objectProperties;
	IBOutlet NSMenuItem* objectPhysicsProperties;
	IBOutlet NSMenuItem* objectAnimations;
	IBOutlet NSMenuItem* objectHidden;
	IBOutlet NSMenuItem* noTool;
	IBOutlet NSMenuItem* sizeTool;
	IBOutlet NSMenuItem* rotateTool;
	IBOutlet NSMenuItem* copyMenu;
	IBOutlet NSMenuItem* pasteMenu;
	IBOutlet NSMenuItem* pastePlaceMenu;
	IBOutlet NSMenuItem* duplicateMenu;
	IBOutlet NSMenuItem* cutMenu;
	IBOutlet NSMenuItem* deleteMenu;
	IBOutlet NSMenuItem* selectAllMenu;
	IBOutlet NSMenuItem* createMenu;
	IBOutlet NSMenuItem* projectMenu;
	IBOutlet NSMenuItem* viewInspectorPanel;
	IBOutlet NSMenuItem* viewInfoPanel;
	IBOutlet NSMenuItem* viewConsolePanel;
	IBOutlet NSMenuItem* viewProjectPanel;
	IBOutlet NSMenuItem* _undoItem;
	IBOutlet NSMenuItem* _redoItem;
	IBOutlet NSMenuItem* modeMenu;
	IBOutlet NSMenuItem* importMenu;
	IBOutlet NSMenuItem* exportMenu;
	
	// Preference Window
	IBOutlet NSWindow* preferenceWindow;
	IBOutlet NSButton* preferenceShowStartup;
	IBOutlet NSButton* preferenceGrid;
	IBOutlet NSButton* preferencePause;
	IBOutlet NSTextField* preferenceFramework;
	IBOutlet NSTextField* preferenceHeader;
	IBOutlet NSTextField* preferenceLibrary;
	IBOutlet NSPanel* preferencePanelSearch;
	IBOutlet TableWindow* preferenceSearchTable;
	NSTextField* destinationSearchPath;
	IBOutlet NSButton* preferenceCodesign;
	IBOutlet NSTextField* preferenceCertificate;
	IBOutlet NSTextField* preferenceName;
	
	// Code Help Window
	IBOutlet NSWindow* codeHelpWindow;
	IBOutlet OutlineWindow* codeHelpOutline;
	IBOutlet CodeHelpView* codeHelpView;
	IBOutlet NSWindow* codeHeadersWindow;
	IBOutlet MDCodeView* codeHeadersView;
	
	// Create Shape From Code Window
	IBOutlet NSPanel* createShapePanel;
	IBOutlet MDCodeView* shapeCodeView;
	IBOutlet NSPanel* saveShapeWindow;
	IBOutlet NSTextField* saveShapeName;
	NSString* currentShapeName;
	
	// Create Text Window
	IBOutlet NSWindow* createText;
	IBOutlet NSTextField* textName;
	IBOutlet NSTextField* fontName;
	IBOutlet NSTextField* fontSize;
	
	// Texture Window
	IBOutlet NSWindow* textureWindow;
	IBOutlet TableWindow* textureTable;
	IBOutlet NSImageView* texturePreview;
	IBOutlet NSButton* textureRemove;
	
	// Add Texture Window
	IBOutlet NSWindow* addTextureWindow;
	IBOutlet NSTabView* addTextureTab;
	IBOutlet NSTextField* addTextureDiffuseImage;
	IBOutlet NSTextField* addTextureBumpImage;
	IBOutlet NSTextField* addTextureMapImage;
	IBOutlet NSTextField* addTextureTex1Image;
	IBOutlet NSTextField* addTextureTex1Scale;
	IBOutlet NSTextField* addTextureTex2Image;
	IBOutlet NSTextField* addTextureTex2Scale;
	IBOutlet NSTextField* addTextureTex3Image;
	IBOutlet NSTextField* addTextureTex3Scale;
	NSTextField* destinationTextureImage;
	BOOL isEditingTexture;
	BOOL removingHead;
	
	// Texture Resources Window
	IBOutlet NSWindow* textureResourcesWindow;
	IBOutlet TableWindow* textureResources;
	
	// Skybox Window
	IBOutlet NSWindow* skyboxWindow;
	IBOutlet TableWindow* skyboxTable;
	IBOutlet NSTextField* skyboxDistance;
	IBOutlet NSTextField* skyboxRed;
	IBOutlet NSTextField* skyboxGreen;
	IBOutlet NSTextField* skyboxBlue;
	IBOutlet NSTextField* skyboxAlpha;
	IBOutlet NSButton* skyboxVisible;
	IBOutlet NSTextField* skyboxCorrection;
	
	// Lightmaps Window
	IBOutlet NSWindow* lightmapWindow;
	IBOutlet NSButtonCell* lightmapCurrentScene;
	IBOutlet NSButtonCell* lightmapAllScenes;
	IBOutlet NSButton* lightmapShadows;
	IBOutlet NSButton* lightmapSoftShadows;
	IBOutlet NSButton* lightmapRadiosity;
	IBOutlet NSTextField* lightmapRadiosityBounces;
	IBOutlet NSTextField* lightmapResolutionX;
	IBOutlet NSTextField* lightmapResolutionY;
	IBOutlet NSTextField* lightmapInfo;
	IBOutlet NSProgressIndicator* lightmapProgress;
	IBOutlet NSButton* lightmapGenerateButton;
	
	// Inspector Panel
	IBOutlet NSPanel* inspectorPanel;
	IBOutlet MDTabSwitcher* inspectorSwitcher;
	IBOutlet NSTabView* inspectorTabView;
	// File
	IBOutlet OutlineWindow* fileOutline;
	// Scene
	IBOutlet TableWindow* sceneTable;
	// Library
	IBOutlet OutlineWindow* libraryOutline;
	unsigned long librarySelection;
	
	// New File
	IBOutlet NSWindow* newFileWindow;
	IBOutlet NSTextField* nameFile;
	IBOutlet NSComboBox* extensionFile;
	IBOutlet NSButton* includeHFile;
	IFNode* senderNode;
	
	// Editor Window
	IBOutlet NSWindow* editorWindow;
	IBOutlet MDCodeView* editorView;
	IBOutlet NSToolbarItem* editorRunItem;
	
	// Console Window
	IBOutlet NSPanel* consoleWindow;
	IBOutlet NSTextView* consoleView;
	IBOutlet TableWindow* variableView;
	
	// Object Property Window
	IBOutlet NSPanel* propertyWindow;
	IBOutlet TableWindow* propertyTable;
	IBOutlet NSButton* propertySetObjects;
	IBOutlet NSButton* propertyVisible;
	IBOutlet NSButton* propertyStatic;
	id propObj;
	
	// Physics Property Window
	IBOutlet NSPanel* physicsWindow;
	IBOutlet TableWindow* physicsTable;
	id physicsObj;
	
	// Project Property Window
	IBOutlet NSPanel* projectWindow;
	IBOutlet NSComboBox* projRes;
	IBOutlet NSPopUpButton* projInitialScene;
	IBOutlet NSPopUpButton* projectSettingsAntialias;
	IBOutlet NSComboBox* projectSettingsFPS;
	IBOutlet NSTextField* projectSettingIcon;
	
	// Animation Window
	IBOutlet NSPanel* animationWindow;
	IBOutlet TableWindow* animationTable;
	MDObject* animObj;
						   
	BOOL showIntroWindow;
}

// Undo / Redo Functions
+ (void) registerUndo;
+ (void) setMDObject: (MDObject*)obj atIndex: (NSUInteger)index faceIndex:(NSUInteger)fInd edgeIndex:(NSUInteger)eInd pointIndex:(NSUInteger)pInd selectionIndex:(NSUInteger)selInd;
+ (void) setMDInstance:(MDInstance*)obj atIndex: (NSUInteger)index;
+ (void) setObjects: (NSArray*)array selected: (MDSelection*)index andInstances:(NSMutableArray*)insts;
+ (void) setOtherObject: (id)obj atIndex:(NSUInteger)index;
+ (void) setTranslationPoint:(MDVector3)point;
- (IBAction) undo: (id) sender;
- (IBAction) redo: (id) sender;

// Intro Window
- (IBAction) showIntroWindow:(id)sender;
- (IBAction) selectRecentIntro:(id)sender;
- (IBAction) openRecentIntro:(id)sender;
- (IBAction) viewHeaderIntro:(id)sender;

// Read Menu
- (void) loadShapes: (NSString*)path menu:(id)superMenu node:(IFNode*)root;

// Project Creation
- (IBAction) newProject: (id) sender;
- (IBAction) cancelNewProject: (id) sender;
- (IBAction) finishNewProject: (id) sender;

// File Menu
- (IBAction) close:(id)sender;

// Open Recent
@property (readonly) FILE *recentlyOpenedFile;
- (void) readRecentlyOpened;
- (void) addToRecentlyOpened:(NSString*)directory;
- (int) checkIfRecentlyOpened: (NSString*)directory;
- (IBAction) clearMenu: (id) sender;
- (IBAction) openRecent: (id) sender;

// Preferences
- (IBAction) showPreferences:(id)sender;
- (IBAction) preferencesShowStartup:(id)sender;
- (IBAction) preferenceGrid:(id)sender;
- (IBAction) preferencePause:(id)sender;
- (IBAction) preferenceFramework:(id)sender;
- (IBAction) preferenceHeader:(id)sender;
- (IBAction) preferenceLibrary:(id)sender;
- (void) preferenceSetupSearch;
- (IBAction) preferenceSearchRemove:(id)sender;
- (IBAction) preferenceSearchAdd:(id)sender;
- (IBAction) preferenceSearchClose:(id)sender;
- (IBAction) preferenceCodesign:(id)sender;
- (IBAction) preferenceEditCertificate:(id)sender;
- (IBAction) preferenceEditName:(id)sender;
- (void) savePreferences;
- (void) readPreferences;

// Code Help
- (void) setupCodeHelp;
- (void) codeHelpOutlineSelected:(id)sender;
- (IBAction) openCodeFile:(id) sender;
- (IBAction) searchCodeHelp:(id)sender;

// Project Reading
- (IBAction) open: (id) sender;
- (IBAction) read: (id) sender project:(BOOL)proj;
- (void) readProject;

// Saving
- (IBAction) save:(id)sender;
- (void) saveWithPics:(BOOL)pics andModels:(BOOL)models;

// Tools
- (IBAction) selectionTool: (id) sender;
- (IBAction) moveTool: (id) sender;
- (IBAction) zoomTool: (id) sender;
- (IBAction) rotationTool: (id) sender;

// Mode Tools
- (IBAction) objectMode:(id)sender;
- (IBAction) faceMode:(id)sender;
- (IBAction) edgeMode:(id)sender;
- (IBAction) vertexMode:(id)sender;

// Object Tools
- (IBAction) noObject: (id) sender;
- (IBAction) moveObject: (id) sender;
- (IBAction) sizeObject: (id) sender;
- (IBAction) rotateObject: (id) sender;
- (IBAction) applyTransformations: (id)sender;
- (IBAction) combineObjects:(id)sender;
- (IBAction) faceNormalize:(id)sender;
- (IBAction) pointNormalize:(id)sender;
- (IBAction) invertNormals:(id)sender;
- (IBAction) deleteNormals:(id)sender;
- (IBAction) showTextures:(id)sender;
- (IBAction) reverseWinding:(id)sender;
- (IBAction) setHeightMap:(id)sender;
- (IBAction) exportHeightMap:(id)sender;
- (IBAction) objectMarkHidden:(id)sender;

// Animation Window
- (IBAction) showAnimationWindow:(id)sender;
- (IBAction) animationDoubleClicked:(id)sender;
- (IBAction) animationRightClicked:(id)sender;
- (IBAction) animationEdited:(id)sender;

// Property Window
- (IBAction) showPropertyWindow:(id)sender;
- (IBAction) addProperty:(id)sender;
- (IBAction) removeProperty:(id)sender;
- (IBAction) propertyEdited:(id)sender;
- (IBAction) propertySetVisible:(id)sender;
- (IBAction) propertySetStatic:(id)sender;
- (IBAction) propertySetObjects:(id)sender;

// Physics Window
- (IBAction) showPhysicsWindow:(id)sender;
- (void) physicsTableEdited:(id)sender;

// Textures
- (IBAction) addTextures:(id)sender;
- (IBAction) removeTexture:(id)sender;
- (IBAction) textureSelected:(id)sender;
- (IBAction) editTexture:(id)sender;
// Add Textures
- (IBAction) selectDiffuseTexture:(id)sender;
- (IBAction) selectBumpTexture:(id)sender;
- (IBAction) selectMapTexture:(id)sender;
- (IBAction) selectTex1Texture:(id)sender;
- (IBAction) selectTex2Texture:(id)sender;
- (IBAction) selectTex3Texture:(id)sender;
- (IBAction) selectTextureImage:(id)sender;
- (IBAction) cancelTextureImage:(id)sender;
- (IBAction) cancelAddTexture:(id)sender;
- (IBAction) finishAddTexture:(id)sender;
- (void) textureResourcesRight;

// Skybox
- (IBAction) showSkybox:(id)sender;
- (IBAction) chooseSkyboxColor:(id)sender;
- (IBAction) okSkybox:(id)sender;
- (IBAction) cancelSkybox:(id)sender;

// Lightmaps
- (IBAction) generateLightmap:(id)sender;

// Update GL View Timer
- (void) updateBeforeGLView;
- (void) updateGLView;
- (void) infoTableUpdated: (IFNode*)item;

// Edit Functions
- (IBAction) copy: (id) sender;
- (IBAction) paste: (id) sender;
- (IBAction) pasteInPlace:(id)sender;
- (IBAction) duplicate:(id)sender;
- (IBAction) cut: (id) sender;
- (IBAction) deleteItem: (id) sender;
- (IBAction) selectAll:(id)sender;

// Create Functions
- (IBAction) shape: (id) sender;
- (IBAction) createShapeCode: (id) sender;
- (IBAction) finishShapeCode: (id) sender;
- (IBAction) cancelShapeCode: (id) sender;
- (IBAction) saveShapeCode: (id) sender;
- (IBAction) saveShapeName:(id)sender;
- (IBAction) customShape:(id)sender;
- (IBAction) customShapeSettings:(id)sender;
- (IBAction) settings: (id) sender;
- (void) shapeSettings: (id) sender;
- (void) shapeChosen: (id) sender;
- (IBAction) createShape: (id) sender;
- (IBAction) okShapeSettings: (id) sender;
- (IBAction) cancelShapeSettings: (id) sender;
- (IBAction) createText: (id) sender;
- (IBAction) createDirectionalLight:(id)sender;
- (IBAction) createPointLight:(id)sender;
- (IBAction) createSpotLight:(id)sender;
- (IBAction) createCamera:(id)sender;
- (IBAction) createSound:(id)sender;
- (IBAction) createParticleEngine:(id)sender;
- (IBAction) createCurve:(id)sender;
- (IBAction) deleteOtherObject:(id)sender;

// Create Text Window
- (IBAction) createTextOk:(id)sender;
- (IBAction) createTextCancel:(id)sender;
- (IBAction) chooseFont:(id)sender;
- (IBAction) changeFont:(id)sender;

// Project Properties
- (IBAction) selectIconImage:(id)sender;
- (IBAction) updateProject:(id)sender;

// Viewing Panels
- (IBAction) viewInspectorPanel: (id)sender;
- (IBAction) viewInfoPanel: (id) sender;
- (void) setUpInfoPanel;
- (void) updateFaces:(IFNode*)node;
- (void) setUpOtherPanel;
- (void) setUpFilePanel;
- (void) setupLibraryPanel;
- (IBAction) viewConsolePanel:(id)sender;
- (IBAction) viewProjectPanel:(id)sender;

// Scene Panel
- (void) sceneEdited:(id)sender;
- (void) sceneOpened:(id)sender;
- (void) sceneShowMenu:(id)sender;
- (void) sceneAdd:(id)sender;
- (void) sceneRemove:(id)sender;

// File Panel
- (void) openFilePanel:(IFNode*)node;
- (void) fileOutlineMenu: (OutlineWindow*) sender;
- (void) fileOutlineEdited: (id)sender withOld:(id)old;
- (void) showNewFile;
- (IBAction) addNewFile:(id)sender;
- (void) addNewFolder;
- (void) renameFileOutline;
- (void) addOutlineFiles;
- (void) deleteFileOutline;
- (void) showInFinder;

// Library Panel
- (void) selectLibraryObject:(id)sender;
- (void) insertLibraryObject:(id)sender;
- (void) renameLibraryObject:(id)sender withOld:(id)old;
- (void) rightLibraryObject:(id)sender;
- (void) copyLibraryObject:(id)sender;
- (void) deleteLibraryObject:(id)sender;
- (void) propertiesLibraryObject:(id)sender;

// Project Menu / Debugger
- (IBAction) compile:(id) sender;
- (IBAction) compileAndRun:(id)sender;
- (IBAction) run:(id)sender;
- (IBAction) stop:(id)sender;
- (IBAction) continuePressed:(id)sender;
- (IBAction) stepOver:(id)sender;
- (void) bringAppToFront;
- (void) updateConsoleView:(NSNotification*)note;
- (void) variableTableEdited:(id)sender;
- (void) updateEditorBreaks;
- (void) updateVariableText:(NSString*)name;
- (void) updateVar:(NSString*)name value:(NSString*)varValue;

// Importing
- (IBAction) importFromModel:(id)sender;
- (IBAction) importFromMDModel:(id)sender;

// Exporting
- (IBAction) exportToModel:(id)sender;

// Window Delegate
- (BOOL) windowShouldClose: (NSWindow*)window;

// Application Delegate
- (NSApplicationTerminateReply) applicationShouldTerminate:(NSApplication*)sender;

@end
