//
//  MDStart.m
//  MovieDraw
//

#import "MDStart.h"
#import "MDLoad.h"

void draw();
BOOL init();
BOOL initGL();
void Dealloc();

void KeyDown(NSEvent* event);
void KeyUp(NSEvent* event);
void MouseDown(NSEvent* event);
void MouseUp(NSEvent* event);
void MouseDragged(NSEvent* event);
void MouseMoved(NSEvent* event);
void ProcessKeys(NSArray* keys);

@implementation MDStart

- (void) applicationDidFinishLaunching: (NSNotification*)notification
{
	// Setup the menu
	NSString* applicationName = MDProjectName();
	NSMenu* mainMenu = [ [ NSApplication sharedApplication ] mainMenu ];
	NSMenu* applicationMenu = [ [ mainMenu itemAtIndex:0 ] submenu ];
	[ [ applicationMenu itemAtIndex:0 ] setTitle:[ NSString stringWithFormat:@"About %@", applicationName ] ];
	[ [ applicationMenu itemAtIndex:6 ] setTitle:[ NSString stringWithFormat:@"Hide %@", applicationName ] ];
	[ [ applicationMenu itemAtIndex:10 ] setTitle:[ NSString stringWithFormat:@"Quit %@", applicationName ] ];
	NSMenu* helpMenu = [ [ mainMenu itemAtIndex:2 ] submenu ];
	[ [ helpMenu itemAtIndex:0 ] setTitle:[ NSString stringWithFormat:@"%@ Help", applicationName ] ];
	
	// Create the window
	NSRect screen = [ [ NSScreen mainScreen ] frame ];
	NSSize size = MDInitialResolution();
	glWindow = [ [ GLWindow alloc ] initWithContentRect:NSMakeRect((screen.size.width / 2) - size.width / 2, (screen.size.height / 2) - size.height / 2, size.width, size.height) styleMask:NSTitledWindowMask | NSClosableWindowMask backing:NSBackingStoreBuffered defer:NO ];
	
	// Hide fullscreen button
    [ glWindow setCollectionBehavior:NSWindowCollectionBehaviorManaged ];
	
	[ glWindow setTitle:applicationName ];
	unsigned int fps = 0, antialias = 0;
	MDProjectOptions(&antialias, &fps);
	[ glWindow setFPS:fps ];
	
	MDSetGLWindow(glWindow);
	[ glWindow setAntialias:antialias ];
	if (!init())
		[ NSApp terminate:self ];
	[ glWindow setUpGLView ];
	if (!initGL())
		[ NSApp terminate:self ];
	[ glWindow makeFirstResponder:[ glWindow glView ] ];
	
	// Assign functions
	MDSetDrawFunction(draw);
	MDSetKeyFunction(ProcessKeys);
	MDSetKeyDown(KeyDown);
	MDSetKeyUp(KeyUp);
	MDSetMouseDown(MouseDown);
	MDSetMouseUp(MouseUp);
	MDSetMouseDragged(MouseDragged);
	MDSetMouseMoved(MouseMoved);
	
	// Load the first scene
	MDLoadObjects([ glWindow glView ], MDInitialScene());
	
	[ glWindow makeKeyAndOrderFront:NSApp ];
}
				  
- (void) dealloc
{
	// Cleanup
	Dealloc();
	if (glWindow)
	{
		[ glWindow release ];
		glWindow = nil;
	}
	[ super dealloc ];
}
				  
@end
