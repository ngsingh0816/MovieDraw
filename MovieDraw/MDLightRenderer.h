//
//  MDLightRenderer.h
//  MovieDraw
//
//  Created by Neil on 10/17/13.
//  Copyright (c) 2013 Neil. All rights reserved.
//

// Adapted from (maybe)
// http://freespace.virgin.net/hugo.elias/radiosity/radiosity.htm
// and probably
// http://www.flipcode.com/archives/Light_Mapping_Theory_and_Implementation.shtml
//

#import <Cocoa/Cocoa.h>

void MDGenerateLightmaps(NSMutableArray* objects, NSMutableArray* instances, NSMutableArray* otherObjects, NSString* path, NSString* scene, NSSize res, NSProgressIndicator* progress, NSTextField* label);
