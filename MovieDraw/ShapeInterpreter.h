//
//  ShapeInterpreter.h
//  MovieDraw
//
//  Created by Neil Singh on 8/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ShapeSettings.h"
#import "MDTypes.h"

std::vector<Variable> ShapeVariables(NSString* settings);
void InterpretShape(NSString* path, NSString* settings, NSMutableArray* obj, MDVector3 origin, MDVector3 size);
void Execute(unsigned int opcode, unsigned long* pc, NSMutableArray* obj, unsigned char* buffer, MDVector3 origin);
BOOL RequiresTwoMouseClicks();
