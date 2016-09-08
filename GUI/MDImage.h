//
//  MDImage.h
//  MovieDraw
//
//  Created by Singh on 1/8/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


/*@interface MDPNG : NSObject
{
	NSString* open;					// Curent open file
	FILE* file;
}

- (MDPNG*) initWithFileName: (NSString*) name;

- (void) addChunk: (const char*)name length:(unsigned int)len data:(unsigned char*)chkdata;

@end*/



@interface MDImage : NSObject 
{
	NSString* open;					// Current file open
	
	// Bitmap Info
	unsigned int fsize;				// File Size
	int width;						// Width in pixels
	int height;						// Height in pixels
	unsigned short planes;			// Usually 1
	unsigned short bpp;				// Bits per pixel
	unsigned int compression;		// Compressed
	unsigned int size;				// Image size
	int xmeter;						// Horizontal Resolution
	int ymeter;						// Vertical Resolution
	unsigned int used;				// 0 (color table size)
	unsigned int important;			// Important color count

	unsigned char* pixels;					// Pixels
	unsigned int plength;
}

// Creation
+ (MDImage*) mdImageWithFileName: (NSString*) filename;
+ (MDImage*) mdImageWithData: (unsigned char*) data;

// Init
- (MDImage*) initWithFileName: (NSString*) filename;
- (MDImage*) initWithCData: (unsigned char*) data;

// Getters
- (unsigned int) fileSize;
- (unsigned int) width;
- (unsigned int) height;
- (unsigned int) offset;
- (unsigned short) numberOfPlanes;
- (unsigned short) bitsPerPixel;
- (unsigned int) compression;
- (unsigned int) imageSize;
- (unsigned int) horizontalResolution;
- (unsigned int) verticalResolution;
- (unsigned int) colorTableSize;
- (unsigned int) importantColors;
- (unsigned char*) pixels;
- (NSColor*) colorAtPixel: (NSPoint*) point; 
- (unsigned char*) data;

// Setters
- (void) setFileSize: (unsigned int) fileSize;
- (void) setWidth: (unsigned int) hWidth;
- (void) setHeight: (unsigned int) hHeight;
- (void) setNumberOfPlanes: (unsigned short) number;
- (void) setBitsPerPixel: (unsigned short) bits;
- (void) setCompression: (unsigned int) compress;
- (void) setImageSize: (unsigned int) imageSize;
- (void) setHorizontalResolution: (unsigned int) resolution;
- (void) setVerticalResolution: (unsigned int) resolution;
- (void) setColorTableSize: (unsigned int) tableSize;
- (void) setImportantColors: (unsigned int) colors;
- (void) setPixels: (unsigned char*) bytes length: (unsigned int) len;
- (void) setColorAtPixel: (NSPoint*) point color: (NSColor*)col;
- (BOOL) setData: (unsigned char*) data;

// Operations
- (BOOL) readFile: (NSString*) filename;
- (BOOL) writeToFile: (NSString*) filename;
- (NSData*) imageData;
- (BOOL) checkIfFileIsImage: (NSString*) filename;

// Cleanup
- (void) dealloc;

@end
