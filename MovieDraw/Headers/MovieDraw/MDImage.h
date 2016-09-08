/*
	MDImage.h
	MovieDraw
 
	Copyright (c) 2013. All rights reserved.
*/

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
@property  unsigned int fileSize;
@property  unsigned int width;
@property  unsigned int height;
@property (readonly) unsigned int offset;
@property  unsigned short numberOfPlanes;
@property  unsigned short bitsPerPixel;
@property  unsigned int compression;
@property  unsigned int imageSize;
@property  unsigned int horizontalResolution;
@property  unsigned int verticalResolution;
@property  unsigned int colorTableSize;
@property  unsigned int importantColors;
@property (readonly) unsigned char *pixels;
- (NSColor*) colorAtPixel: (NSPoint*) point; 
- (unsigned char*) data NS_RETURNS_INNER_POINTER;

// Setters
- (void) setPixels: (unsigned char*) bytes length: (unsigned int) len;
- (void) setColorAtPixel: (NSPoint*) point color: (NSColor*)col;
- (BOOL) setData: (unsigned char*) data;

// Operations
- (BOOL) readFile: (NSString*) filename;
- (BOOL) writeToFile: (NSString*) filename;
@property (readonly, copy) NSData *imageData;
- (BOOL) checkIfFileIsImage: (NSString*) filename;

// Cleanup
- (void) dealloc;

@end
