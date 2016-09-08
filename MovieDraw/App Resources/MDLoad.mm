// Todo - make this and "MDStart.mm" a precompiled file

#import "MDLoad.h"
#import <stdio.h>

NSSize MDInitialResolution()
{
	FILE* file = fopen([ [ NSString stringWithFormat:@"%@/load", [ [ NSBundle mainBundle ] resourcePath ] ] UTF8String ], "r");
	if (!file)
		return NSMakeSize(0, 0);
	float width = 0, height = 0;
	fread(&width, sizeof(float), 1, file);
	fread(&height, sizeof(float), 1, file);
	fclose(file);
	return NSMakeSize(width, height);
}

NSString* MDInitialScene()
{
	FILE* file = fopen([ [ NSString stringWithFormat:@"%@/load", [ [ NSBundle mainBundle ] resourcePath ] ] UTF8String ], "r");
	if (!file)
		return nil;
	fseek(file, 2 * sizeof(float), SEEK_SET);
	unsigned long length = 0;
	fread(&length, sizeof(unsigned long), 1, file);
	char* data = (char*)malloc(length + 1);
	fread(data, length, 1, file);
	data[length] = 0;
	NSString* ret = [ NSString stringWithUTF8String:data ];
	free(data);
	fclose(file);
	return ret;
}

NSString* MDProjectName()
{
	FILE* file = fopen([ [ NSString stringWithFormat:@"%@/load", [ [ NSBundle mainBundle ] resourcePath ] ] UTF8String ], "r");
	if (!file)
		return nil;
	fseek(file, 2 * sizeof(float), SEEK_SET);
	unsigned long length = 0;
	fread(&length, sizeof(unsigned long), 1, file);
	fseek(file, length, SEEK_CUR);
	fread(&length, sizeof(unsigned long), 1, file);
	char* data = (char*)malloc(length + 1);
	fread(data, length, 1, file);
	data[length] = 0;
	NSString* ret = [ NSString stringWithUTF8String:data ];
	free(data);
	fclose(file);
	return ret;
}

void MDProjectOptions(unsigned int* antialias, unsigned int* fps)
{
	
	FILE* file = fopen([ [ NSString stringWithFormat:@"%@/load", [ [ NSBundle mainBundle ] resourcePath ] ] UTF8String ], "r");
	if (!file)
		return;
	fseek(file, 2 * sizeof(float), SEEK_SET);
	unsigned long length = 0;
	fread(&length, sizeof(unsigned long), 1, file);
	fseek(file, length, SEEK_CUR);
	fread(&length, sizeof(unsigned long), 1, file);
	fseek(file, length, SEEK_CUR);
	fread(antialias, sizeof(unsigned int), 1, file);
	fread(fps, sizeof(unsigned int), 1, file);
	fclose(file);
}

void MDLoadObjects(GLView* glView, NSString* scene)
{
	MDLoadScene(scene);
}