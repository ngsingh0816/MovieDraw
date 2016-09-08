//
//  MDLoad.h
//  MovieDraw
//

#import <Foundation/Foundation.h>
#import <MovieDraw/MovieDraw.h>

NSSize MDInitialResolution();
NSString* MDInitialScene();
NSString* MDProjectName();
void MDProjectOptions(unsigned int* antialias, unsigned int* fps);
void MDLoadObjects(GLView* glView, NSString* scene);
