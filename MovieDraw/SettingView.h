//
//  SettingView.h
//  MovieDraw
//
//  Created by Neil on 7/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface SettingView : NSView {
	id target;
	SEL action;
	NSString* text;
	BOOL over;
	BOOL lastOver;
	BOOL overSetting;
	BOOL realOver;
	NSTrackingArea* track;
}

@property (assign) id target;
@property  SEL action;
@property (copy) NSString *text;
- (void) unselect;

@end
