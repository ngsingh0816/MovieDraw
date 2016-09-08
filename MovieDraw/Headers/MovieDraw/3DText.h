/*
	3DText.h
	MovieDraw
 
	Copyright (c) 2013. All rights reserved.
*/

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import "MDTypes.h"

extern float percent;
extern BOOL calculating;

@interface MDText : NSObject {
}

+ (MDInstance*) createText: (NSAttributedString*) str depth: (float)dep;
+ (NSNumber*) create2DText: (NSAttributedString*) text removeBlack:(BOOL)black;

@end