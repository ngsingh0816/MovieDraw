//
//  CodeHelpView.h
//  MovieDraw
//
//  Created by Neil on 8/1/13.
//  Copyright (c) 2013 Neil. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CodeHelpView : NSView
{
	NSMutableArray* files;
}

@property (copy) NSArray *files;
- (void) loadFile:(NSString*)path;
- (void) searchWord:(NSString*)string;

@end
