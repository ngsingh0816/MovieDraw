//
//  MDImporter.h
//  MovieDraw
//
//  Created by Neil on 3/22/13.
//  Copyright (c) 2013 Neil. All rights reserved.
//

#import "MDTypes.h"

NSArray* ImportAvailableFileTypes();
NSArray* ExportAvailableFileTypes();
MDInstance* ObjectFromFile(NSString* file);
// Todo: export
