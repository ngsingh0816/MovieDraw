//
//  MDCompiler.h
//  MovieDraw
//
//  Created by Neil Singh on 10/29/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import "MDCodeView.h"

BOOL Compile(NSArray* files, MDCodeView* editorView, NSString* path, NSArray* resources, NSTextView* console, NSArray* scenes, BOOL editedFiles);
BOOL CompileShape(NSString* text, MDCodeView* editorView, NSTextView* console);
