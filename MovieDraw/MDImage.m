//
//  MDImage.m
//  MovieDraw
//
//  Created by Singh on 1/8/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MDImage.h"

//void make_crc_table();
//unsigned long update_crc(unsigned long crc, unsigned char* buf, int len);
//unsigned long crc(unsigned char* buf, int len);
unsigned short readShort(unsigned char* buffer, unsigned int* pos);
void WriteShort(unsigned char* buffer, unsigned int* pos, unsigned short data);
void WriteString(unsigned char* buffer, unsigned int* pos, unsigned char* data,
				 unsigned int length);
unsigned int readInt(unsigned char* buffer, unsigned int* pos);
void WriteInt(unsigned char* buffer, unsigned int* pos, unsigned int data);

/*unsigned long crc_table[256];
BOOL crc_table_computed = FALSE;

void make_crc_table()
{
	unsigned long c;
	for (int n = 0; n < 256; n++)
	{
		c = n;
		for (int k = 0; k < 8; k++)
		{
			if (c & 1)
				c = 0xEDB88320 ^ (c >> 1);
			else
				c >>= 1;
		}
		crc_table[n] = c;
	}
	crc_table_computed = TRUE;
}

unsigned long update_crc(unsigned long crc, unsigned char* buf, int len)
{
	unsigned long c = crc;
	if (!crc_table_computed)
		make_crc_table();
	for (int n = 0; n < len; n++)
		c = crc_table[(c ^ buf[n]) & 0xFF] ^ (c >> 8);
	return c;
}

unsigned long crc(unsigned char* buf, int len)
{
	return update_crc(0xFFFFFFFF, buf, len) ^ 0xFFFFFFFF;
}

@implementation MDPNG

- (MDPNG*) initWithFileName: (NSString*) name
{
	if ((self = [ super init ]))
	{
		open = [ [ NSString alloc ] initWithString:name ];
		file = fopen([ name UTF8String ], "wb");
		
		if (!file)
		{
			return nil;
		}
	
		if (!crc_table_computed)
			make_crc_table();
		
		const char header[8] = { 137, 80, 78, 71, 13, 10, 26, 10 };
		fwrite(header, 8, 1, file);
	}
	return self;
}

- (void) addChunk: (const char*)name length:(unsigned int)len data:(unsigned char*)chkdata
{
	unsigned int realLength = (len >> 24) | (((len >> 16) & 0xFF) << 8) |
	(((len >> 8) & 0xFF) << 16) | ((len & 0xFF) << 24);
	
	fwrite(&realLength, 1, 4, file);
	fwrite(name, 4, 1, file);
	fwrite(chkdata, len, 1, file);
	
	unsigned char* crcData = (unsigned char*)malloc(len + 4);
	memcpy(crcData, name, 4);
	memcpy(&crcData[4], chkdata, len);
	unsigned long CRC = crc(crcData, len);
	CRC = (CRC >> 24) | (((CRC >> 16) & 0xFF) << 8) |
	(((CRC >> 8) & 0xFF) << 16) | ((CRC & 0xFF) << 24);
	free(crcData);
	crcData = NULL;
	
	fwrite(&CRC, 4, 1, file);
}

- (void) dealloc
{
	if (open)
	{
		[ open release ];
		open = nil;
	}
	if (file)
	{
		fclose(file);
		file = NULL;
	}
	[ super dealloc ];
}

@end*/



unsigned short readShort(unsigned char* buffer, unsigned int* pos)
{
	if (!buffer)
		return 0;
	unsigned short target = 0;
	target |= buffer[*pos + 1];
	target *= 256;
	target |= buffer[*pos];
	*pos += 2;
	return target;
}

void WriteShort(unsigned char* buffer, unsigned int* pos, unsigned short data)
{
	if (!buffer)
		return;
	buffer[*pos] = data & 0xFF;
	buffer[*pos + 1] = (data >> 8) & 0xFF;
	*pos += 2;
}

void WriteString(unsigned char* buffer, unsigned int* pos, unsigned char* data,
				 unsigned int length)
{
	if (!buffer || !data)
		return;
	for (int z = 0; z < length; z++)
		buffer[z + *pos] = data[z];
	*pos += length;
}

unsigned int readInt(unsigned char* buffer, unsigned int* pos)
{
	if (!buffer)
		return 0;
	int target = 0;
	target |= buffer[*pos + 3];
	target *= 256;
	target |= buffer[*pos + 2];
	target *= 256;
	target |= buffer[*pos + 1];
	target *= 256;
	target |= buffer[*pos];
	*pos += 4;
	return target;
}

void WriteInt(unsigned char* buffer, unsigned int* pos, unsigned int data)
{
	if (!buffer)
		return;
	buffer[*pos] = data & 0xFF;
	buffer[*pos + 1] = (data >> 8) & 0xFF;
	buffer[*pos + 2] = (data >> 16) & 0xFF;
	buffer[*pos + 3] = (data >> 24) & 0xFF;
	*pos += 4;
}


@implementation MDImage

+ (MDImage*) mdImageWithFileName: (NSString*) filename
{
	return [ [ MDImage alloc ] initWithFileName:filename ];
}

+ (MDImage*) mdImageWithData: (unsigned char*) data
{
	return [ [ MDImage alloc ] initWithCData:data ];
}

- (MDImage*) initWithFileName: (NSString*) filename
{
	if ((self = [ super init ]))
	{
		if (![ self readFile:filename ])
			self = nil;
	}
	return self;
}

- (MDImage*) initWithCData: (unsigned char*) data
{
	if ((self = [ super init ]))
	{
		if (![ self setData:data ])
			self = nil;
	}
	return self;
}

- (unsigned int) fileSize
{
	return fsize;
}

- (unsigned int) width
{
	return width;
}

- (unsigned int) height
{
	return (unsigned int)abs((int)height);
}

- (unsigned int) offset
{
	return 54;
}

- (unsigned short) numberOfPlanes
{
	return planes;
}

- (unsigned short) bitsPerPixel
{
	return bpp;
}

- (unsigned int) compression
{
	return compression;
}

- (unsigned int) imageSize
{
	return size;
}

- (unsigned int) horizontalResolution
{
	return xmeter;
}

- (unsigned int) verticalResolution
{
	return ymeter;
}

- (unsigned int) colorTableSize
{
	return used;
}

- (unsigned int) importantColors
{
	return important;
}

- (unsigned char*) pixels
{
	return pixels;
}

- (NSColor*) colorAtPixel:(NSPoint *)point
{
	return [ NSColor blackColor ];
}

- (unsigned char*) data
{
	return nil;
}

- (void) setFileSize: (unsigned int) fileSize
{
	fsize = fileSize;
}

- (void) setWidth: (unsigned int) hWidth
{
	width = hWidth;
}

- (void) setHeight: (unsigned int) hHeight
{
	height = -(int)hHeight;
}

- (void) setNumberOfPlanes: (unsigned short) number
{
	planes = number;
}

- (void) setBitsPerPixel: (unsigned short) bits
{
	bpp = bits;
}

- (void) setCompression: (unsigned int) compress
{
	compression = compress;
}

- (void) setImageSize: (unsigned int) imageSize
{
	size = imageSize;
}

- (void) setHorizontalResolution: (unsigned int) resolution
{
	xmeter = resolution;
}

- (void) setVerticalResolution: (unsigned int) resolution
{
	ymeter = resolution;
}

- (void) setColorTableSize: (unsigned int) tableSize
{
	used = tableSize;
}

- (void) setImportantColors: (unsigned int) colors
{
	important = colors;
}

- (void) setPixels: (unsigned char*) bytes length: (unsigned int) len
{
	if (bytes)
	{
		if (pixels)
		{
			pixels = NULL;
			free(pixels);
		}
		pixels = (unsigned char*)malloc(len);
		memcpy(pixels, bytes, len);
		plength = len;
	}
}

- (void) setColorAtPixel:(NSPoint *)point color:(NSColor*) col
{
}

- (BOOL) setData: (unsigned char*) data
{
	if (!data)
		return FALSE;
	unsigned short signature = 0;
	unsigned int pos = 0;
	signature = readShort(data, &pos);
	if (signature != 0x4D42)
		return FALSE;
	
	fsize = readInt(data, &pos);
	readShort(data, &pos);				// Reserved
	readShort(data, &pos);				// Reserved
	readInt(data, &pos);				// Offset
	readInt(data, &pos);				// Header Bytes
	width = readInt(data, &pos);
	height = abs((int)readInt(data, &pos));
	planes = readShort(data, &pos);
	bpp = readShort(data, &pos);
	compression = readInt(data, &pos);
	unsigned int length = 0;
	pos += 4;
	xmeter = readInt(data, &pos);
	ymeter = readInt(data, &pos);
	used = readInt(data, &pos);
	important = readInt(data, &pos);

	length = fsize - 54;
	size = length;
	
	if (bpp != 24 && bpp != 32)
		bpp = 24;
	
	if (pixels)
	{
		free(pixels);
		pixels = NULL;
	}
	pixels = (unsigned char*)malloc(length);
	if (!pixels)
		return FALSE;
	
	memcpy(pixels, data + pos, length);
	
	return TRUE;
}

- (BOOL) readFile: (NSString*) filename
{
	FILE* file = fopen([ filename UTF8String ], "rb");
	if (file == NULL)
		return FALSE;
	
	fseek(file, 0, SEEK_END);
	unsigned long total = ftell(file);
	rewind(file);
	
	unsigned char* buffer = (unsigned char*) malloc(total);
	fread(buffer, total, 1, file);
	fclose(file);
	
	BOOL ret = [ self setData:buffer ];
	
	free(buffer);
	buffer = NULL;
	
	return ret;
}

- (BOOL) writeToFile: (NSString*) filename
{
	FILE* file = fopen([ filename UTF8String ], "wb");
	
	fwrite("BM", 2, 1, file);
	int temp = 0x36 + plength;
	fwrite(&temp, 4, 1, file);
	temp = 0;
	fwrite(&temp, 4, 1, file);
	temp = 54;
	fwrite(&temp, 4, 1, file);
	temp = 40;
	fwrite(&temp, 4, 1, file);
	fwrite(&width, 4, 1, file);
	temp = -height;
	fwrite(&temp, 4, 1, file);
	if (planes == 0)
		planes = 1;
	fwrite(&planes, 2, 1, file);
	if (bpp == 0)
		bpp = 8;
	fwrite(&bpp, 2, 1, file);
	fwrite(&compression, 4, 1, file);
	temp = plength;
	fwrite(&temp, 4, 1, file);
	if (xmeter == 0)
		xmeter = 2835;
	if (ymeter == 0)
		ymeter = 2835;
	fwrite(&xmeter, 4, 1, file);
	fwrite(&ymeter, 4, 1, file);
	fwrite(&used, 4, 1, file);
	fwrite(&important, 4, 1, file);
	
	fwrite(pixels, plength, 1, file);
	fclose(file);
	
	return TRUE;
}

- (NSData*) imageData
{
	unsigned int length = 54 + plength;
	unsigned char* d = (unsigned char*)malloc(length);
	if (!d)
		return nil;
	
	unsigned int pointer = 0;
	WriteString(d, &pointer, (unsigned char*)"BM", 2);
	WriteInt(d, &pointer, length);
	WriteInt(d, &pointer, 0);
	WriteInt(d, &pointer, 54);
	WriteInt(d, &pointer, 40);
	WriteInt(d, &pointer, width);
	WriteInt(d, &pointer, -height);
	if (planes == 0)
		planes = 1;
	WriteShort(d, &pointer, planes);
	if (bpp == 0)
		bpp = 8;
	WriteShort(d, &pointer, bpp);
	WriteInt(d, &pointer, compression);
	WriteInt(d, &pointer, plength);
	if (xmeter == 0)
		xmeter = 2835;
	if (ymeter == 0)
		ymeter = 2835;
	WriteInt(d, &pointer, xmeter);
	WriteInt(d, &pointer, ymeter);
	WriteInt(d, &pointer, used);
	WriteInt(d, &pointer, important);
	
	WriteString(d, &pointer, pixels, plength);
	
	NSData* data = [ [ NSData alloc ] initWithBytes:d length:length ];
	
	free(d);
	d = NULL;
	
	return data;
}

- (BOOL) checkIfFileIsImage: (NSString*) filename
{
	FILE* file = fopen([ filename UTF8String ], "rb");
	if (file == NULL)
		return FALSE;
	char buffer[2];
	fread(buffer, 2, 1, file);
	fclose(file);
	if (buffer[0] == 'B' && buffer[1] == 'M')
		return TRUE;
	return FALSE;
}

- (void) dealloc
{
	if (pixels)
	{
		free(pixels);
		pixels = NULL;
	}
}

@end
