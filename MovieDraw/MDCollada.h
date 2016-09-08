//
//  MDCollada.h
//  MovieDraw
//
//  Created by Neil on 3/16/13.
//  Copyright (c) 2013 Neil. All rights reserved.
//

#import "MDTypes.h"

@interface MDCollada : NSObject
{
	NSMutableArray* elements;
	NSMutableArray* objects;
	NSMutableArray* sources;
	NSMutableArray* vertices;
	NSMutableArray* polylists;
	NSMutableArray* materials;
	NSMutableArray* images;
	NSMutableArray* nodes;
	NSString* loadingFile;
	NSString* currentGeo;
}

- (id) init;
- (MDObject*) objectFromFile:(NSString*)file;

@end
