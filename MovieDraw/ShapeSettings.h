//
//  ShapeSettings.h
//  MovieDraw
//
//  Created by Neil on 7/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Cocoa/Cocoa.h"
#include <vector>

typedef struct
{
	id obj;			// Value
	Class objClass;	// Object's class if obj-c type otherwise nil
	NSString* name;	// Name of variable in settings
} Variable;

extern std::vector<Variable> variables;

@interface Function : NSObject {
	NSString* type;	// Return value
	NSString* name;	// Name of the function
	NSRange range;	// Range of the code of function
}

- (void) method: (id) sender;
@property (copy) NSString *type;
@property (copy) NSString *name;
@property (assign) NSRange range;

@end

@interface SettingDraw : NSClipView {
}

- (void) drawRect:(NSRect)dirtyRect;

@end

Function* FunctionNamed(NSString* name);
void InitShapeSettings(NSView* view, NSString* path);
void OpenValues(NSString* save);
void CompileShapeSettings(NSArray* array, NSView* view);
void SaveValues(NSString* save, FILE* file, NSString* path);
void ReleaseShapeSettings();