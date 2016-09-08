//
//  MDTabSwitcher.h
//  MovieDraw
//
//  Created by Neil on 12/28/13.
//  Copyright (c) 2013 Neil. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// TODO: make image support

@interface MDTabSwitcher : NSView
{
	unsigned int numTabs;
	NSTabView* tabView;
}

@property  unsigned int numberOfTabs;
@property (strong) NSTabView *tabView;

@end
