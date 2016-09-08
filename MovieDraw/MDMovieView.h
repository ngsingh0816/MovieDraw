//
//  MDMovieView.h
//  MovieDraw
//
//  Created by MILAP on 2/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MDControl.h"
#import "MDButton.h"
#import "MDSlider.h"
#import "MDProgressBar.h"
#import <QTKit/QTKit.h>

@interface MDMovieView : MDControl {
	NSString* movieName;
	NSMutableArray* textures;
	unsigned int texture;
	MDButton* buttons[4];
	MDSlider* slider;
	MDProgressBar* progress;
	BOOL isPlaying;
	id finish;
	SEL finishAct;
	unsigned int currentFrame;
	NSTimer* timer;
	BOOL playing;
}

+ (instancetype) mdMovieView;
+ (instancetype) mdMovieViewWithFrame: (MDRect)rect background:(NSColor*)bkg;
- (BOOL) loadMovie: (NSString*)path;
@property (readonly, copy) NSString *loadedMovie;
- (NSSize) setUseRealSize:(BOOL)use;
@property  float volume;
@property (strong) id finishTarget;
@property  SEL finishAction;

- (void) play: (id) sender;
- (void) pause: (id) sender;
- (void) stop: (id) sender;
- (void) rewind: (id) sender;
- (void) fastForward: (id) sender;
- (void) update;

@end
