//
//  MDCompiler.m
//  MovieDraw
//
//  Created by Neil Singh on 10/29/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MDCompiler.h"
#import "GLView.h"
#import "Controller.h"
#import <sys/xattr.h>
#import "MDLightRenderer.h"
#import "MDFileManager.h"
#include <vector>

BOOL Compile(NSArray* files, MDCodeView* editorView, NSString* path, NSArray* resources, NSTextView* console, NSArray* scenes, BOOL editedFiles)
{
	[ editorView reloadLines ];
	
	[ [ NSFileManager defaultManager ] createDirectoryAtPath:[ NSString stringWithFormat:@"%@build/%@.app/", path, [ path lastPathComponent ] ] withIntermediateDirectories:YES attributes:@{NSFileType: NSFileTypeRegular} error:nil ];
	[ [ NSFileManager defaultManager ] createDirectoryAtPath:[ NSString stringWithFormat:@"%@build/%@.app/Contents/MacOS/", path, [ path lastPathComponent ] ] withIntermediateDirectories:YES attributes:nil error:nil ];
	[ [ NSFileManager defaultManager ] createDirectoryAtPath:[ NSString stringWithFormat:@"%@build/%@.app/Contents/Resources/", path, [ path lastPathComponent ] ] withIntermediateDirectories:YES attributes:nil error:nil ];
	[ [ NSFileManager defaultManager ] createDirectoryAtPath:[ NSString stringWithFormat:@"%@build/%@.app/Contents/Resources/Models", path, [ path lastPathComponent ] ] withIntermediateDirectories:YES attributes:nil error:nil ];
	[ [ NSFileManager defaultManager ] createDirectoryAtPath:[ NSString stringWithFormat:@"%@build/%@.app/Contents/Resources/Shaders/", path, [ path lastPathComponent ] ] withIntermediateDirectories:YES attributes:nil error:nil ];
	
	// Copy resources
	for (unsigned long z = 0; z < [ resources count ]; z++)
	{
		NSString* from = [ NSString stringWithFormat:@"%@%@/Resources/%@", path, [ path lastPathComponent ], resources[z] ];
		NSString* destination = [ NSString stringWithFormat:@"%@build/%@.app/Contents/Resources/%@", path, [ path lastPathComponent ], resources[z] ];
		[ [ NSFileManager defaultManager ] copyItemAtPath:from toPath:destination error:nil ];
	}
	
	// Copy shaders
	NSString* names[] = { @"Shader", @"Normal", @"Particles", @"Static" };
	for (unsigned long z = 0; z < 4; z++)
	{
		NSString* fromVert = [ NSString stringWithFormat:@"%@/Shaders/%@.vert", [ [ NSBundle mainBundle ] resourcePath ], names[z] ];
		NSString* destVert = [ NSString stringWithFormat:@"%@build/%@.app/Contents/Resources/Shaders/%@.vert", path, [ path lastPathComponent ], names[z] ];
		if ([ [ NSFileManager defaultManager ] fileExistsAtPath:destVert ])
			[ [ NSFileManager defaultManager ] removeItemAtPath:destVert error:nil ];
		[ [ NSFileManager defaultManager ] copyItemAtPath:fromVert toPath:destVert error:nil ];
		NSString* fromFrag = [ NSString stringWithFormat:@"%@/Shaders/%@.frag", [ [ NSBundle mainBundle ] resourcePath ], names[z] ];
		NSString* destFrag = [ NSString stringWithFormat:@"%@build/%@.app/Contents/Resources/Shaders/%@.frag", path, [ path lastPathComponent ], names[z] ];
		if ([ [ NSFileManager defaultManager ] fileExistsAtPath:destFrag ])
			[ [ NSFileManager defaultManager ] removeItemAtPath:destFrag error:nil ];
		[ [ NSFileManager defaultManager ] copyItemAtPath:fromFrag toPath:destFrag error:nil ];
	}
	
	NSTask* copyPlist = [ [ NSTask alloc ] init ];
	NSPipe *pipe = [ NSPipe pipe ];
	[ copyPlist setStandardOutput:pipe ];
	[ copyPlist setStandardError:pipe ];
	[ copyPlist setLaunchPath:@"/bin/cp" ];
	[ copyPlist setArguments:@[@"-f", [ NSString stringWithFormat:@"%@/App Resources/Info.plist", [ [ NSBundle mainBundle ] resourcePath ] ], [ NSString stringWithFormat:@"%@build/%@.app/Contents/", path, [ path lastPathComponent ] ]] ];
	[ copyPlist launch ];
	[ copyPlist waitUntilExit ];
	copyPlist = nil;
	
	// TODO: right now the plist is always under the category puzzle games - need to put something in preferences or project propertieis that has it customizable
	
	// Copy over icon image
	if ([ projectIcon length ] != 0)
	{
		NSString* path2 = [ NSString stringWithFormat:@"%@build/%@.app/Icon", path, [ path lastPathComponent ] ];
		if ([ [ NSFileManager defaultManager ] fileExistsAtPath:path2 ])
			[ [ NSFileManager defaultManager ] removeItemAtPath:path2 error:nil ];
		[ [ NSFileManager defaultManager ] copyItemAtPath:[ NSString stringWithFormat:@"%@%@/Resources/%@", path, [ path lastPathComponent ], projectIcon ] toPath:path2 error:nil ];
	}
	
	FILE* plist = fopen([ [ NSString stringWithFormat:@"%@/build/%@.app/Contents/Info.plist", path, [ path lastPathComponent ] ] UTF8String ], "r");
	fseek(plist, 0, SEEK_END);
	unsigned long long sizeTP = ftell(plist);
	rewind(plist);
	char* pData = (char*)malloc(sizeTP + 1);
	pData[sizeTP] = 0;
	fread(pData, 1, sizeTP, plist);
	fclose(plist);
	NSMutableString* pString = [ [ NSMutableString alloc ] initWithUTF8String:pData ];
	free(pData);
	pData = NULL;
	[ pString replaceOccurrencesOfString:@"${PRODUCT_NAME}" withString:[ path lastPathComponent ] options:0 range:NSMakeRange(0, [ pString length ]) ];
	[ pString replaceOccurrencesOfString:@"${EXECUTABLE_NAME}" withString:[ path lastPathComponent ] options:0 range:NSMakeRange(0, [ pString length ]) ];
	if (projectIcon)
		[ pString replaceOccurrencesOfString:@"%icon" withString:projectIcon options:0 range:NSMakeRange(0, [ pString length ]) ];
	else
		[ pString replaceOccurrencesOfString:@"%icon" withString:@"" options:0 range:NSMakeRange(0, [ pString length ]) ];
	
	// Search for the bundle identifier
	NSRange range = [ pString rangeOfString:@"<key>CFBundleIdentifier</key>\n\t<string>" ];
	if (range.location != NSNotFound)
	{
		NSRange range2 = [ pString rangeOfString:@"</string>\n" options:0 range:NSMakeRange(NSMaxRange(range), [ pString length ] - NSMaxRange(range)) ];
		if (range2.location != NSNotFound)
		{
			[ pString replaceCharactersInRange:NSMakeRange(NSMaxRange(range), range2.location - NSMaxRange(range)) withString:[ NSString stringWithFormat:@"com.%@.%@", projectAuthor, [ path lastPathComponent ] ] ];
		}
	}
	
	/*SInt32 version = 0;
	Gestalt(gestaltSystemVersionMajor, &version);
	SInt32 minorVersion = 0;
	Gestalt(gestaltSystemVersionMinor, &minorVersion);
	SInt32 bugFix = 0;
	Gestalt(gestaltSystemVersionBugFix, &bugFix);
	NSString* osVersion = [ NSString stringWithFormat:@"%i.%i.%i", version, minorVersion, bugFix ];
	sizeTP += [ pString replaceOccurrencesOfString:@"${MACOSX_DEPLOYMENT_TARGET}" withString:osVersion options:0 range:NSMakeRange(0, [ pString length ]) ] * ([ osVersion length ] - 27);*/
	plist = fopen([ [ NSString stringWithFormat:@"%@/build/%@.app/Contents/Info.plist", path, [ path lastPathComponent ] ] UTF8String ], "w");
	fwrite([ pString UTF8String ], 1, [ pString length ], plist);
	fclose(plist);
	
	NSTask* copyNib = [ [ NSTask alloc ] init ];
	NSPipe *pipe2 = [ NSPipe pipe ];
	[ copyNib setStandardOutput:pipe2 ];
	[ copyNib setStandardError:pipe2 ];
	[ copyNib setLaunchPath:@"/bin/cp" ];
	[ copyNib setArguments:@[@"-f", @"-R", [ NSString stringWithFormat:@"%@/App Resources/en.lproj", [ [ NSBundle mainBundle ] resourcePath ] ], [ NSString stringWithFormat:@"%@build/%@.app/Contents/Resources", path, [ path lastPathComponent ] ]] ];
	[ copyNib launch ];
	[ copyNib waitUntilExit ];
	copyNib = nil;
	
	/*FILE* file = fopen([ [ NSString stringWithFormat:@"%@/build/%@.app/Contents/Resources/en.lproj/MainMenu.xib", path, [ path lastPathComponent ] ] UTF8String ], "r");
	fseek(file, 0, SEEK_END);
	unsigned long long sizeT = ftell(file);
	rewind(file);
	char* nibData = (char*)malloc(sizeT + 1);
	nibData[sizeT] = 0;
	fread(nibData, 1, sizeT, file);
	fclose(file);
	NSMutableString* nibString = [ [ NSMutableString alloc ] initWithUTF8String:nibData ];
	free(nibData);
	nibData = NULL;
	unsigned long long diffSize = [ [ path lastPathComponent ] length ] - 4;
	sizeT += [ nibString replaceOccurrencesOfString:@"Test" withString:[ path lastPathComponent ] options:0 range:NSMakeRange(0, [ nibString length ]) ] * diffSize;
	file = fopen([ [ NSString stringWithFormat:@"%@/build/%@.app/Contents/Resources/en.lproj/MainMenu.xib", path, [ path lastPathComponent ] ] UTF8String ], "w");
	fwrite([ nibString UTF8String ], 1, sizeT, file);
	fclose(file);
	[ nibString release ];
	nibString = nil;*/
	
	/*NSTask* compileNib = [ [ NSTask alloc ] init ];
	NSPipe *pipe4 = [ NSPipe pipe ];
	[ compileNib setStandardOutput:pipe4 ];
	[ compileNib setStandardError:pipe4 ];
	[ compileNib setLaunchPath:@"/Developer/usr/bin/ibtool" ];
	[ compileNib setArguments:[ NSArray arrayWithObjects:[ NSString stringWithFormat:@"%@build/%@.app/Contents/Resources/en.lproj/MainMenu.xib", path, [ path lastPathComponent ] ], @"--compile", [ NSString stringWithFormat:@"%@build/%@.app/Contents/Resources/en.lproj/MainMenu.nib", path, [ path lastPathComponent ] ], nil ] ];
	[ compileNib launch ];
	
	NSData *nibDataS = [ [ pipe4 fileHandleForReading ] readDataToEndOfFile ];
	[ compileNib waitUntilExit ];
	[ compileNib release ];
	compileNib = nil;
	NSString *nibStringS = [ [ NSString alloc ] initWithData:nibDataS encoding:NSUTF8StringEncoding ];
	NSLog(@"%@", nibStringS);
	[ nibStringS release ];
	
	NSTask* deleteXib = [ [ NSTask alloc ] init ];
	NSPipe *pipe5 = [ NSPipe pipe ];
	[ deleteXib setStandardOutput:pipe5 ];
	[ deleteXib setStandardError:pipe5 ];
	[ deleteXib setLaunchPath:@"/bin/rm" ];
	[ deleteXib setArguments:[ NSArray arrayWithObjects:@"-f", [ NSString stringWithFormat:@"%@build/%@.app/Contents/Resources/en.lproj/MainMenu.xib", path, [ path lastPathComponent ] ], nil ] ];
	[ deleteXib launch ];
	[ deleteXib waitUntilExit ];
	[ deleteXib release ];
	deleteXib = nil;*/
	
	FILE* file = NULL;
	
	FILE* loadFile = fopen([ [ NSString stringWithFormat:@"%@build/%@.app/Contents/Resources/load", path, [ path lastPathComponent ] ] UTF8String ], "wb");
	if (loadFile)
	{
		float width = projectRes.width, height = projectRes.height;
		fwrite(&width, sizeof(float), 1, loadFile);
		fwrite(&height, sizeof(float), 1, loadFile);
		if ([ projectScene isEqualToString:@"Current Scene" ])
		{
			unsigned long length = [ currentScene length ];
			fwrite(&length, sizeof(unsigned long), 1, loadFile);
			fwrite([ currentScene UTF8String ], length, 1, loadFile);
		}
		else
		{
			unsigned long length = [ projectScene length ];
			fwrite(&length, sizeof(unsigned long), 1, loadFile);
			fwrite([ projectScene UTF8String ], length, 1, loadFile);
		}
		unsigned long length2 = [ [ workingDirectory lastPathComponent ] length ];
		fwrite(&length2, sizeof(unsigned long), 1, loadFile);
		fwrite([ [ workingDirectory lastPathComponent ] UTF8String ], length2, 1, loadFile);
		fwrite(&projectAntialias, sizeof(unsigned int), 1, loadFile);
		fwrite(&projectFPS, sizeof(unsigned int), 1, loadFile);
		// List instances
		unsigned long instancesCount = [ instances count ];
		fwrite(&instancesCount, sizeof(unsigned long), 1, loadFile);
		for (unsigned long z = 0; z < [ instances count ]; z++)
		{
			unsigned short nameLength = [ [ instances[z] name ] length ];
			fwrite(&nameLength, sizeof(unsigned short), 1, loadFile);
			fwrite([ [ instances[z] name ] UTF8String ], 1, nameLength, loadFile);
		}
		fclose(loadFile);
	}
	
	for (unsigned long z = 0; z < [ instances count ]; z++)
	{
		if ([ [ instances[z] name ] length ] == 0)
			continue;
		
		file = fopen([ [ NSString stringWithFormat:@"%@build/%@.app/Contents/Resources/Models/%@.mdm", path, [ path lastPathComponent ], [ instances[z] name ] ] UTF8String ], "wb");
		
		unsigned int numMesh = (unsigned int)[ instances[z] numberOfMeshes ];
		fwrite(&numMesh, sizeof(unsigned int), 1, file);
		for (unsigned long t = 0; t < numMesh; t++)
		{
			MDMesh* mesh = [ instances[z] meshAtIndex:t ];
			MDVector4 color = [ mesh color ];
			fwrite(&color.x, sizeof(float), 1, file);
			fwrite(&color.y, sizeof(float), 1, file);
			fwrite(&color.z, sizeof(float), 1, file);
			fwrite(&color.w, sizeof(float), 1, file);
			
			MDMatrix transformMatrix = [ mesh transformMatrix ], meshMatrix = [ mesh meshMatrix ];
			fwrite(&transformMatrix, sizeof(MDMatrix), 1, file);
			fwrite(&meshMatrix, sizeof(MDMatrix), 1, file);
			
			unsigned long pointCount = [ mesh numberOfPoints ];
			fwrite(&pointCount, sizeof(unsigned long), 1, file);
			for (int q = 0; q < [ mesh numberOfPoints ]; q++)
			{
				MDPoint* p = [ mesh pointAtIndex:q ];
				float x = p.x, y = p.y, z = p.z, normX = p.normalX, normY = p.normalY, normZ = p.normalZ, ux = p.textureCoordX, vy = p.textureCoordY;
				fwrite(&x, sizeof(float), 1, file);
				fwrite(&y, sizeof(float), 1, file);
				fwrite(&z, sizeof(float), 1, file);
				fwrite(&normX, sizeof(float), 1, file);
				fwrite(&normY, sizeof(float), 1, file);
				fwrite(&normZ, sizeof(float), 1, file);
				fwrite(&ux, sizeof(float), 1, file);
				fwrite(&vy, sizeof(float), 1, file);
			}
			
			unsigned int indexNum = [ mesh numberOfIndices ];
			fwrite(&indexNum, sizeof(unsigned int), 1, file);
			for (unsigned int q = 0; q < indexNum; q++)
			{
				unsigned int index = (unsigned int)[ mesh indexAtIndex:q ];
				fwrite(&index, sizeof(unsigned int), 1, file);
			}
			
			unsigned int texNum = (unsigned int)[ mesh numberOfTextures ];
			fwrite(&texNum, sizeof(unsigned int), 1, file);
			for (unsigned int q = 0; q < texNum; q++)
			{
				MDTexture* texture = [ mesh textureAtIndex:q ];
				unsigned char type = (unsigned char)[ texture type ];
				fwrite(&type, sizeof(unsigned char), 1, file);
				unsigned int head = [ texture head ];
				fwrite(&head, sizeof(unsigned int), 1, file);
				float size = [ texture size ];
				fwrite(&size, sizeof(float), 1, file);
				NSString* tex = [ [ texture path ] lastPathComponent ];
				unsigned int len = (unsigned int)[ tex length ];
				fwrite(&len, sizeof(unsigned int), 1, file);
				fwrite([ tex UTF8String ], len, 1, file);
			}
			
			unsigned int boneNum = (unsigned int)[ mesh numberOfBones ];
			fwrite(&boneNum, sizeof(unsigned int), 1, file);
			for (unsigned int q = 0; q < boneNum; q++)
			{
				MDBone* bone = [ mesh boneAtIndex:q ];
				MDMatrix offsetMatrix = [ bone offsetMatrix ];
				fwrite(&offsetMatrix, sizeof(MDMatrix), 1, file);
				unsigned int weightNum = (unsigned int)[ bone numberOfWeights ];
				fwrite(&weightNum, sizeof(unsigned int), 1, file);
				for (unsigned int y = 0; y < weightNum; y++)
				{
					MDVertexWeight* weight = [ bone weightAtIndex:y ];
					unsigned int vertexID = (unsigned int)[ weight vertexID ];
					fwrite(&vertexID, sizeof(unsigned int), 1, file);
					float fWeight = [ weight weight ];
					fwrite(&fWeight, sizeof(float), 1, file);
				}
			}
		}
				
		MDVector4 specularColor = [ instances[z] specularColor ];
		fwrite(&specularColor.x, sizeof(float), 1, file);
		fwrite(&specularColor.y, sizeof(float), 1, file);
		fwrite(&specularColor.z, sizeof(float), 1, file);
		fwrite(&specularColor.w, sizeof(float), 1, file);
		float shininess = [ instances[z] shininess ];
		fwrite(&shininess, sizeof(float), 1, file);
		
		MDMatrix startMatrix = [ instances[z] startMatrix ];
		fwrite(&startMatrix, sizeof(MDMatrix), 1, file);
		
		BOOL hasNode = ([ instances[z] rootNode ] != NULL);
		fwrite(&hasNode, sizeof(BOOL), 1, file);
		
		if (hasNode)
			MDWriteNodes([ instances[z] rootNode ], file);
		
		NSArray* animations = [ (MDInstance*)instances[z] animations ];
		unsigned int numAnims = (unsigned int)[ animations count ];
		fwrite(&numAnims, sizeof(unsigned int), 1, file);
		for (unsigned int q = 0; q < numAnims; q++)
		{
			MDAnimation* animation = animations[q];
			unsigned int nameLength = (unsigned int)[ [ animation name ] length ];
			fwrite(&nameLength, sizeof(unsigned int), 1, file);
			fwrite([ [ animation name ] UTF8String ], sizeof(char), nameLength, file);
			float duration = [ animation duration ];
			fwrite(&duration, sizeof(float), 1, file);
			
			std::vector<MDAnimationStep>* steps = [ animation steps ];
			unsigned int numSteps = (unsigned int)steps->size();
			fwrite(&numSteps, sizeof(unsigned int), 1, file);
			for (unsigned long t = 0; t < numSteps; t++)
			{
				unsigned int numPositions = (unsigned int)steps->at(t).positions.size();
				fwrite(&numPositions, sizeof(unsigned int), 1, file);
				for (unsigned long y = 0; y < numPositions; y++)
				{
					MDVector3 pos = steps->at(t).positions[y];
					fwrite(&pos, sizeof(MDVector3), 1, file);
					float posTime = steps->at(t).positionTimes[y];
					fwrite(&posTime, sizeof(float), 1, file);
				}
				
				unsigned int numRots = (unsigned int)steps->at(t).rotations.size();
				fwrite(&numRots, sizeof(unsigned int), 1, file);
				for (unsigned long y = 0; y < numRots; y++)
				{
					MDVector4 rot = steps->at(t).rotations[y];
					fwrite(&rot, sizeof(MDVector4), 1, file);
					float rotTime = steps->at(t).rotateTimes[y];
					fwrite(&rotTime, sizeof(float), 1, file);
				}
				
				unsigned int numScales = (unsigned int)steps->at(t).scalings.size();
				fwrite(&numScales, sizeof(unsigned int), 1, file);
				for (unsigned long y = 0; y < numScales; y++)
				{
					MDVector3 scale = steps->at(t).scalings[y];
					fwrite(&scale, sizeof(MDVector3), 1, file);
					float scaleTime = steps->at(t).scaleTimes[y];
					fwrite(&scaleTime, sizeof(float), 1, file);
				}
			}
		}
		
		// Write instance properties
		NSArray* opKeys = [ [ instances[z] properties ] allKeys ];
		unsigned long oprop = [ opKeys count ];
		fwrite(&oprop, sizeof(unsigned long), 1, file);
		for (unsigned long t = 0; t < oprop; t++)
		{
			NSString* key = opKeys[t];
			unsigned long length = [ key length ];
			fwrite(&length, sizeof(unsigned long), 1, file);
			const char* str = [ key UTF8String ];
			fwrite(str, 1, length, file);
			NSString* val = [ instances[z] properties ][key];
			length = [ val length ];
			fwrite(&length, sizeof(unsigned long), 1, file);
			str = [ val UTF8String ];
			fwrite(str, 1, length, file);
		}
		
		fclose(file);
	}

	[ [ NSFileManager defaultManager ] createDirectoryAtPath:[ NSString stringWithFormat:@"%@build/%@.app/Contents/Resources/Scenes/", path, [ path lastPathComponent ] ] withIntermediateDirectories:NO attributes:nil error:nil ];
	for (unsigned int t = 0; t < [ scenes count ]; t++)
	{
		// Create models
		file = fopen([ [ NSString stringWithFormat:@"%@build/%@.app/Contents/Resources/Scenes/%@", path, [ path lastPathComponent ], scenes[t][@"Name"] ] UTF8String ], "w");
		if (!file)
			continue;
		
		// Scene properties
		NSMutableDictionary* dict = sceneProps[scenes[t][@"Name"]];
		unsigned long skyLen = [ dict[@"Skybox Texture Path"] length ];
		fwrite(&skyLen, sizeof(unsigned long), 1, file);
		fwrite([ dict[@"Skybox Texture Path"] UTF8String ], 1, skyLen, file);
		float skyDist = [ dict[@"Skybox Distance"] floatValue ];
		fwrite(&skyDist, sizeof(float), 1, file);
		NSColor* skyColor = dict[@"Skybox Color"];
		float skyRed = [ skyColor redComponent ], skyGreen = [ skyColor greenComponent ], skyBlue = [ skyColor blueComponent ], skyAlpha = [ skyColor alphaComponent ];
		fwrite(&skyRed, sizeof(float), 1, file);
		fwrite(&skyGreen, sizeof(float), 1, file);
		fwrite(&skyBlue, sizeof(float), 1, file);
		fwrite(&skyAlpha, sizeof(float), 1, file);
		float skyCorrection = [ dict[@"Skybox Correction"] floatValue ];
		fwrite(&skyCorrection, sizeof(float), 1, file);
		unsigned char skyVisible = [ dict[@"Skybox Visible"] boolValue ];
		fwrite(&skyVisible, 1, 1, file);
		
		NSArray* objs = scenes[t][@"Objects"];
		unsigned long objCount = [ objs count ];
		fwrite(&objCount, sizeof(unsigned long), 1, file);
		for (int z = 0; z < objCount; z++)
		{
			MDInstance* inst = [ objs[z] instance ];
			unsigned long instIndex = [ instances indexOfObject:inst ];
			fwrite(&instIndex, sizeof(unsigned long), 1, file);
			
			unsigned short nameLength = [ [ objs[z] name ] length ];
			fwrite(&nameLength, sizeof(unsigned short), 1, file);
			fwrite([ [ objs[z] name ] UTF8String ], 1, nameLength, file);
			
			MDObject* obj = objs[z];
			
			float tx = [ obj translateX ], ty = [ obj translateY ], tz = [ obj translateZ ], sx = [ obj scaleX ], sy = [ obj scaleY ], sz = [ obj scaleZ ], ran = [ obj rotateAngle ];
			MDVector3 ra = [ obj rotateAxis ];
			MDVector4 cm = [ obj colorMultiplier ];
			fwrite(&tx, sizeof(float), 1, file);
			fwrite(&ty, sizeof(float), 1, file);
			fwrite(&tz, sizeof(float), 1, file);
			fwrite(&sx, sizeof(float), 1, file);
			fwrite(&sy, sizeof(float), 1, file);
			fwrite(&sz, sizeof(float), 1, file);
			fwrite(&ra.x, sizeof(float), 1, file);
			fwrite(&ra.y, sizeof(float), 1, file);
			fwrite(&ra.z, sizeof(float), 1, file);
			fwrite(&ran, sizeof(float), 1, file);
			fwrite(&cm.x, sizeof(float), 1, file);
			fwrite(&cm.y, sizeof(float), 1, file);
			fwrite(&cm.z, sizeof(float), 1, file);
			fwrite(&cm.w, sizeof(float), 1, file);
			
			// Physics
			float mass = [ obj mass ], restituion = [ obj restitution ], friction = [ obj friction ], rfriction = [ obj rollingFriction ];
			unsigned char phyType = [ obj physicsType ], phyFlags = [ obj flags ];
			fwrite(&mass, sizeof(float), 1, file);
			fwrite(&restituion, sizeof(float), 1, file);
			fwrite(&phyType, sizeof(unsigned char), 1, file);
			fwrite(&phyFlags, sizeof(unsigned char), 1, file);
			fwrite(&friction, sizeof(float), 1, file);
			fwrite(&rfriction, sizeof(float), 1, file);
			
			// Flags
			unsigned char shouldDraw = [ obj shouldDraw ] | ([ obj isStatic ] << 1);
			fwrite(&shouldDraw, sizeof(unsigned char), 1, file);
			
			// Write object properties
			NSArray* opKeys = [ [ obj properties ] allKeys ];
			unsigned long oprop = [ opKeys count ];
			fwrite(&oprop, sizeof(unsigned long), 1, file);
			for (unsigned long t = 0; t < oprop; t++)
			{
				NSString* key = opKeys[t];
				unsigned long length = [ key length ];
				fwrite(&length, sizeof(unsigned long), 1, file);
				const char* str = [ key UTF8String ];
				fwrite(str, 1, length, file);
				NSString* val = [ obj properties ][key];
				length = [ val length ];
				fwrite(&length, sizeof(unsigned long), 1, file);
				str = [ val UTF8String ];
				fwrite(str, 1, length, file);
			}
		}
		NSArray* floats = scenes[t][@"Floats"];
		unsigned long cca = [ floats[0] unsignedLongValue ];
		NSArray* other = scenes[t][@"Other Objects"];
		if (cca == -1)
		{
			float tpX = [ floats[1] floatValue ];
			float tpY = [ floats[2] floatValue ];
			float tpZ = [ floats[3] floatValue ];
			float lpX = [ floats[4] floatValue ];
			float lpY = [ floats[5] floatValue ];
			float lpZ = [ floats[6] floatValue ];
			float rpX = [ floats[7] floatValue ];
			float rpY = [ floats[8] floatValue ];
			float rpZ = [ floats[9] floatValue ];
			fwrite(&tpX, sizeof(float), 1, file);
			fwrite(&tpY, sizeof(float), 1, file);
			fwrite(&tpZ, sizeof(float), 1, file);
			fwrite(&lpX, sizeof(float), 1, file);
			fwrite(&lpY, sizeof(float), 1, file);
			fwrite(&lpZ, sizeof(float), 1, file);
			MDVector3 rot = MDVector3Create(rpX, rpY, rpZ);
			float orien = 0;
			BOOL use = 0;
			fwrite(&rot.x, sizeof(float), 1, file);
			fwrite(&rot.y, sizeof(float), 1, file);
			fwrite(&rot.z, sizeof(float), 1, file);
			fwrite(&orien, sizeof(float), 1, file);
			fwrite(&use, sizeof(char), 1, file);
		}
		else
		{
			MDCamera* camera = other[cca];
			MDVector3 midPoint = [ camera midPoint ], lPoint = [ camera lookPoint ], rot = MDVector3Create(0, 0, 0);
			float orien = [ camera orientation ];
			BOOL use = 1;
			fwrite(&midPoint.x, sizeof(float), 1, file);
			fwrite(&midPoint.y, sizeof(float), 1, file);
			fwrite(&midPoint.z, sizeof(float), 1, file);
			fwrite(&lPoint.x, sizeof(float), 1, file);
			fwrite(&lPoint.y, sizeof(float), 1, file);
			fwrite(&lPoint.z, sizeof(float), 1, file);
			fwrite(&rot.x, sizeof(float), 1, file);
			fwrite(&rot.y, sizeof(float), 1, file);
			fwrite(&rot.z, sizeof(float), 1, file);
			fwrite(&orien, sizeof(float), 1, file);
			fwrite(&use, sizeof(char), 1, file);
		}
		
		// Other Objects
		unsigned long otherObjSize = [ other count ];
		fwrite(&otherObjSize, sizeof(unsigned long), 1, file);
		for (int z = 0; z < [ other count ]; z++)
		{
			unsigned int realType = 0;
			if ([ other[z] isKindOfClass:[ MDCamera class ] ])
			{
				realType = 1;
				fwrite(&realType, sizeof(realType), 1, file);
				MDCamera* cam = other[z];
				MDVector3 point = [ cam midPoint ], look = [ cam lookPoint ];
				float orien = [ cam orientation ];
				fwrite(&point, sizeof(point), 1, file);
				fwrite(&look, sizeof(look), 1, file);
				fwrite(&orien, sizeof(float), 1, file);
				unsigned int nameSize = (unsigned int)[ [ cam name ] length ];
				fwrite(&nameSize, sizeof(unsigned int), 1, file);
				char* buffer = (char*)malloc(nameSize + 1);
				memcpy(buffer, [ [ cam name ] UTF8String ], nameSize);
				buffer[nameSize] = 0;
				fwrite(buffer, nameSize, 1, file);
				free(buffer);
				buffer = NULL;
			}
			else if ([ other[z] isKindOfClass:[ MDLight class ] ])
			{
				realType = 2;
				fwrite(&realType, sizeof(realType), 1, file);
				MDLight* light = other[z];
				MDVector3 point = light.position, look = light.spotDirection;
				MDVector4 ambient = light.ambientColor, diffuse = light.diffuseColor, specular = light.specularColor;
				float exp = light.spotExp, cut = light.spotCut, ccut = light.spotAngle, cat = light.constAtt, linat = light.linAtt, quadat = light.quadAtt;
				unsigned int type = light.lightType;
				BOOL enableShadows = light.enableShadows, isStatic = light.isStatic;
				fwrite(&point, sizeof(point), 1, file);
				fwrite(&look, sizeof(look), 1, file);
				fwrite(&ambient, sizeof(ambient), 1, file);
				fwrite(&diffuse, sizeof(diffuse), 1, file);
				fwrite(&specular, sizeof(specular), 1, file);
				fwrite(&exp, sizeof(exp), 1, file);
				fwrite(&cut, sizeof(cut), 1, file);
				fwrite(&ccut, sizeof(ccut), 1, file);
				fwrite(&cat, sizeof(cat), 1, file);
				fwrite(&linat, sizeof(linat), 1, file);
				fwrite(&quadat, sizeof(quadat), 1, file);
				fwrite(&type, sizeof(type), 1, file);
				unsigned char realEs = enableShadows | (isStatic << 1);
				fwrite(&realEs, sizeof(realEs), 1, file);
				unsigned int nameSize = (unsigned int)[ [ light name ] length ];
				fwrite(&nameSize, sizeof(unsigned int), 1, file);
				char* buffer = (char*)malloc(nameSize + 1);
				memcpy(buffer, [ [ light name ] UTF8String ], nameSize);
				buffer[nameSize] = 0;
				fwrite(buffer, nameSize, 1, file);
				free(buffer);
				buffer = NULL;
			}
			else if ([ other[z] isKindOfClass:[ MDParticleEngine class ] ])
			{
				realType = 3;
				fwrite(&realType, sizeof(realType), 1, file);
				MDParticleEngine* engine = other[z];
				MDVector3 point = engine.position, vel = engine.velocities;
				MDVector4 start = engine.startColor, end = engine.endColor;
				float size = engine.particleSize;
				unsigned long number = engine.numberOfParticles, life = engine.particleLife;
				unsigned int velType = engine.velocityType;
				BOOL show = engine.show;
				fwrite(&point, 1, sizeof(point), file);
				fwrite(&velType, 1, sizeof(velType), file);
				fwrite(&vel, 1, sizeof(vel), file);
				fwrite(&start, 1, sizeof(start), file);
				fwrite(&end, 1, sizeof(end), file);
				fwrite(&size, 1, sizeof(size), file);
				fwrite(&number, 1, sizeof(number), file);
				fwrite(&life, 1, sizeof(life), file);
				fwrite(&show, sizeof(show), 1, file);
				unsigned int nameSize = (unsigned int)[ [ engine name ] length ];
				fwrite(&nameSize, sizeof(unsigned int), 1, file);
				char* buffer = (char*)malloc(nameSize + 1);
				memcpy(buffer, [ [ engine name ] UTF8String ], nameSize);
				buffer[nameSize] = 0;
				fwrite(buffer, nameSize, 1, file);
				free(buffer);
				buffer = NULL;
			}
			else if ([ other[z] isKindOfClass:[ MDCurve class ] ])
			{
				realType = 4;
				fwrite(&realType, sizeof(realType), 1, file);
				MDCurve* curve = other[z];
				std::vector<MDVector3> p = *[ curve curvePoints ];
				unsigned long numP = p.size();
				fwrite(&numP, 1, sizeof(unsigned long), file);
				for (unsigned long q = 0; q < numP; q++)
					fwrite(&p[q], 1, sizeof(p[q]), file);
				unsigned int nameSize = (unsigned int)[ [ curve name ] length ];
				fwrite(&nameSize, sizeof(unsigned int), 1, file);
				char* buffer = (char*)malloc(nameSize + 1);
				memcpy(buffer, [ [ curve name ] UTF8String ], nameSize);
				buffer[nameSize] = 0;
				fwrite(buffer, nameSize, 1, file);
				free(buffer);
				buffer = NULL;
			}
		}
		
		fclose(file);
	}
	
	// Copy all resources
	/*NSArray* enumerator = [ [ NSFileManager defaultManager ] contentsOfDirectoryAtPath:[ NSString stringWithFormat:@"%@/Resources", workingDirectory ] error:nil ];
	for (int z = 0; z < [ enumerator count ]; z++)
	{
		if ([ [ enumerator objectAtIndex:z ] hasSuffix:@"/models" ])
		{
			NSLog(@"Error: \"models\" can not be used.");
			continue;
		}
	}*/
	
	if (editedFiles)
	{
		// Create app bundle
		NSTask* task = [ NSTask new ];
		//[ task setLaunchPath:[ NSString stringWithFormat:@"%@/LLVM/bin/g++", [ [ NSBundle mainBundle ] resourcePath ] ] ];	// Works
		//[ task setLaunchPath:@"/Developer/usr/llvm-gcc-4.2/bin/i686-apple-darwin11-llvm-g++-4.2" ];	// Doesn't work
		//[ task setLaunchPath:@"/Developer/usr/llvm-gcc-4.2/bin/llvm-g++-4.2" ];						// Works
		//[ task setLaunchPath:@"/usr/llvm-gcc-4.2/bin/llvm-g++-4.2" ];									// Works but not with sandboxing
		[ task setLaunchPath:@"/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang" ];
		NSMutableArray* array = [ [ NSMutableArray alloc ] initWithObjects:[ NSString stringWithFormat:@"%@/App Resources/main.m", [ [ NSBundle mainBundle ] resourcePath ] ], [ NSString stringWithFormat:@"%@/App Resources/MDLoad.mm", [ [ NSBundle mainBundle ] resourcePath ] ], [ NSString stringWithFormat:@"%@/App Resources/MDStart.mm", [ [ NSBundle mainBundle ] resourcePath ] ], nil ];
		for (int z = 0; z < [ files count ]; z++)
			[ array addObject:files[z] ];
		/*NSArray* array2 = [ NSArray arrayWithObjects:@"-g", @"-o", [ NSString stringWithFormat:@"%@build/%@.app/Contents/MacOS/%@", path, [ path lastPathComponent ], [ path lastPathComponent ] ], @"-I/usr/include/c++/4.2.1", @"-isystem", @"/usr/include/", @"-L", @"/usr/lib", @"-iframework/System/Library/Frameworks/", @"-I", [ NSString stringWithFormat:@"%@/App Resources/", [ [ NSBundle mainBundle ] resourcePath ] ], @"-I", [ NSString stringWithFormat:@"%@/Headers/", [ [ NSBundle mainBundle ] resourcePath ] ], @"-framework", @"Cocoa", @"-framework", @"OpenGL", @"-framework", @"QTKit", @"-framework", @"AppKit", @"-framework",@"Foundation", @"-L", [ NSString stringWithFormat:@"%@/App Resources/", [ [ NSBundle mainBundle ] resourcePath ] ], @"-l", @"MovieDraw", nil ];*/
		
		NSMutableArray* array2 = [ NSMutableArray arrayWithObjects:@"-g", @"-o", [ NSString stringWithFormat:@"%@build/%@.app/Contents/MacOS/%@", path, [ path lastPathComponent ], [ path lastPathComponent ] ], @"-I", [ NSString stringWithFormat:@"%@/App Resources/", [ [ NSBundle mainBundle ] resourcePath ] ], @"-I", [ NSString stringWithFormat:@"%@/Headers/", [ [ NSBundle mainBundle ] resourcePath ] ], nil ];
		
		NSString* flags[] = { @"-iframework", @"-I", @"-L", };
		NSString* keys[] = { @"Frameworks", @"Headers", @"Libraries" };
		for (unsigned int y = 0; y < 3; y++)
		{
			NSArray* pathArray = searchPaths[keys[y]];
			for (unsigned long z = 0; z < [ pathArray count ]; z++)
			{
				[ array2 addObject:[ NSString stringWithFormat:@"%@%@", flags[y], pathArray[z] ] ];
				if (y == 1)
					[ array2 addObject:[ NSString stringWithFormat:@"%@%@", flags[y], [ pathArray[z] stringByAppendingString:@"c++/4.2.1/" ] ] ];
			}
		}
		[ array2 addObject:@"-L/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib" ];
		[ array2 addObjectsFromArray:@[@"-framework", @"Cocoa", @"-framework", @"OpenGL", @"-framework", @"QTKit", @"-framework", @"AppKit", @"-framework",@"Foundation", @"-L", [ NSString stringWithFormat:@"%@/App Resources/", [ [ NSBundle mainBundle ] resourcePath ] ], @"-l", @"MovieDraw", @"-lstdc++",
			@"-x", @"objective-c++", @"-arch", @"x86_64", @"-fmessage-length=0", @"-fdiagnostics-show-note-include-stack", @"-fmacro-backtrace-limit=0", @"-std=gnu++11", @"-fobjc-arc", @"-Wno-trigraphs -fpascal-strings", @"-O0", @"-Wno-missing-field-initializers", @"-Wno-missing-prototypes", @"-Wno-implicit-atomic-properties", @"-Wno-receiver-is-weak", @"-Wno-arc-repeated-use-of-weak", @"-Wno-non-virtual-dtor", @"-Wno-overloaded-virtual", @"-Wno-exit-time-destructors", @"-Wduplicate-method-match", @"-Wno-missing-braces", @"-Wparentheses", @"-Wswitch", @"-Wno-unused-function", @"-Wno-unused-label", @"-Wno-unused-parameter", @"-Wunused-variable", @"-Wunused-value", @"-Wno-empty-body", @"-Wuninitialized", @"-Wno-unknown-pragmas", @"-Wno-shadow", @"-Wno-four-char-constants", @"-Wno-conversion", @"-Wno-constant-conversion", @"-Wno-int-conversion", @"-Wno-bool-conversion", @"-Wno-enum-conversion", @"-Wshorten-64-to-32", @"-Wno-newline-eof", @"-Wno-selector -Wno-strict-selector-match", @"-Wno-undeclared-selector", @"-Wno-deprecated-implementations", @"-Wno-c++11-extensions", @"-DDEBUG=1", @"-isysroot /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.10.sdk", @"-fasm-blocks", @"-fstrict-aliasing", @"-Wprotocol", @"-Wdeprecated-declarations", @"-Winvalid-offsetof", @"-mmacosx-version-min=10.10", @"-fvisibility-inlines-hidden", @"-Wno-sign-conversion" ] ];
			
		for (int z = 0; z < [ array2 count ]; z++)
			[ array addObject:array2[z] ];
		
		[ task setArguments:array ];
		NSPipe* pipe3 = [ NSPipe pipe ];
		[ task setStandardOutput:pipe3 ];
		[ task setStandardError:pipe3 ];
		
		[ task launch ];
		
		// error: Cocoa/Cocoa.h: No such file or directory
		
		NSData* data = [ [ pipe3 fileHandleForReading ] readDataToEndOfFile ];
		[ task waitUntilExit ];
		
		// Reset this file
		//objectFile = fopen([ [ NSString stringWithFormat:@"%@/App Resources/MDLoad.mm", [ [ NSBundle mainBundle ] resourcePath ] ] UTF8String ], "w");
		//fclose(objectFile);
		
		NSString* string = [ [ NSString alloc ] initWithData:data encoding:NSUTF8StringEncoding ];
		
		[ editorView removeAllErrors ];
		if ([ string length ] == 0)
		{
			[ editorView setNeedsDisplay:YES ];
			
			// Codesign and sandbox if it wants
			if (projectCommand & MD_PROJECT_CODESIGN)
			{
				NSTask* codesign = [ NSTask new ];
				[ codesign setLaunchPath:@"/usr/bin/codesign" ];
				[ codesign setArguments:@[@"-s", projectCertificate, @"-f", @"--entitlements", [ NSString stringWithFormat:@"%@/App Resources/entitlements.plist", [ [ NSBundle mainBundle ] resourcePath ] ], [ NSString stringWithFormat:@"%@build/%@.app", path, [ path lastPathComponent ] ]] ];
				
				NSPipe* pipe4 = [ NSPipe pipe ];
				[ codesign setStandardOutput:pipe4 ];
				[ codesign setStandardError:pipe4 ];
				
				[ codesign launch ];
				NSData* data2 = [ [ pipe4 fileHandleForReading ] readDataToEndOfFile ];
				[ codesign waitUntilExit ];
				
				NSString* codeString = [ [ NSString alloc ] initWithData:data2 encoding:NSUTF8StringEncoding ];
				if ([ codeString length ] != 0)
				{
					NSLog(@"Codesign: %@", codeString);
					
					return FALSE;
				}
			}
			
			return TRUE;
		}
		
		// Interpret errors and warnings
		NSLog(@"%@", string);
		[ [ console textStorage ] appendAttributedString:[ [ NSAttributedString alloc ] initWithString:[ NSString stringWithFormat:@"Compile: %@", string ]attributes:@{NSForegroundColorAttributeName: [ NSColor blackColor ]} ] ];
		
		NSRange erRange = NSMakeRange(0, 0);
		for (;;)
		{
			erRange = [ string rangeOfString:@": error: " options:0 range:NSMakeRange(NSMaxRange(erRange), [ string length ] - NSMaxRange(erRange)) ];
			if (erRange.length == 0)
				break;
			// Read backwards until next :
			unsigned long total = 0;
			BOOL isNumber = TRUE;
			unsigned int power = 0;
			for (long z = erRange.location - 1; z >= 0; z--)
			{
				unsigned char cmd = [ string characterAtIndex:z ];
				if (cmd == ':')
					break;
				if (!(cmd >= '0' && cmd <= '9'))
				{
					isNumber = FALSE;
					break;
				}
				total += (cmd - '0') * pow(10, power);
				power++;
			}
			if (!isNumber)
				continue;
			// Find next '\n'
			NSRange newRange = [ string rangeOfString:@"\n" options:0 range:NSMakeRange(NSMaxRange(erRange), [ string length ] - NSMaxRange(erRange)) ];
			if (newRange.length == 0)
				newRange.location = [ string length ];
			NSString* message = [ string substringWithRange:NSMakeRange(NSMaxRange(erRange), newRange.location - NSMaxRange(erRange)) ];
			[ editorView addError:message atLine:total type:MD_ERROR ];
		}
		erRange = NSMakeRange(0, 0);
		for (;;)
		{
			erRange = [ string rangeOfString:@": warning: " options:0 range:NSMakeRange(NSMaxRange(erRange), [ string length ] - NSMaxRange(erRange)) ];
			if (erRange.length == 0)
				break;
			// Read backwards until next :
			unsigned long total = 0;
			BOOL isNumber = TRUE;
			unsigned int power = 0;
			for (long z = erRange.location - 1; z >= 0; z--)
			{
				unsigned char cmd = [ string characterAtIndex:z ];
				if (cmd == ':')
					break;
				if (!(cmd >= '0' && cmd <= '9'))
				{
					isNumber = FALSE;
					break;
				}
				total += (cmd - '0') * pow(10, power);
				power++;
			}
			if (!isNumber)
				continue;
			// Find next '\n'
			NSRange newRange = [ string rangeOfString:@"\n" options:0 range:NSMakeRange(NSMaxRange(erRange), [ string length ] - NSMaxRange(erRange)) ];
			if (newRange.length == 0)
				newRange.location = [ string length ];
			NSString* message = [ string substringWithRange:NSMakeRange(NSMaxRange(erRange), newRange.location - NSMaxRange(erRange)) ];
			[ editorView addError:message atLine:total type:MD_WARNING ];
		}
		
		[ editorView setNeedsDisplay:YES ];
		
		// old
		/*NSLog(@"%@", string);
		
		NSRange erRange = NSMakeRange(0, 0);
		for (;;)
		{
			erRange = [ string rangeOfString:@": error: " options:0 range:NSMakeRange(NSMaxRange(erRange), [ string length ] - NSMaxRange(erRange)) ];
			if (erRange.length == 0)
				break;
			// Read backwards until next :
			unsigned long total = 0;
			BOOL isNumber = TRUE;
			unsigned int power = 0;
			for (long z = erRange.location - 1; z >= 0; z--)
			{
				unsigned char cmd = [ string characterAtIndex:z ];
				if (cmd == ':')
					break;
				if (!(cmd >= '0' && cmd <= '9'))
				{
					isNumber = FALSE;
					break;
				}
				total += (cmd - '0') * pow(10, power);
			}
			if (!isNumber)
				continue;
			// Find next '\n'
			NSRange newRange = [ string rangeOfString:@"\n" options:0 range:NSMakeRange(NSMaxRange(erRange), [ string length ] - NSMaxRange(erRange)) ];
			if (newRange.length == 0)
				newRange.location = [ string length ];
			NSString* message = [ string substringWithRange:NSMakeRange(NSMaxRange(erRange), newRange.location - NSMaxRange(erRange)) ];
			[ editorView addError:message atLine:total type:MD_ERROR ];
		}
		
		[ string release ];
		
		[ editorView setNeedsDisplay:YES ];*/
		
		return FALSE;
	}
	
	return TRUE;
}

BOOL CompileShape(NSString* text, MDCodeView* editorView, NSTextView* console)
{	
	FILE* file = fopen([ [ NSString stringWithFormat:@"%@/App Resources/Shapes/temp.mm", [ [ NSBundle mainBundle ] resourcePath ] ] UTF8String ], "w");
	if (!file)
		return FALSE;
	fwrite([ text UTF8String ], 1, [ text length ], file);
	fclose(file);
	
	NSTask* task = [ NSTask new ];
	[ task setLaunchPath:[ NSString stringWithFormat:@"%@/LLVM/bin/g++", [ [ NSBundle mainBundle ] resourcePath ] ] ];
	NSMutableArray* array = [ [ NSMutableArray alloc ] initWithObjects:[ NSString stringWithFormat:@"%@/App Resources/Shapes/temp.mm", [ [ NSBundle mainBundle ] resourcePath ] ], [ NSString stringWithFormat:@"%@/App Resources/Shapes/main.mm", [ [ NSBundle mainBundle ] resourcePath ] ], nil ];
	NSArray* array2 = @[@"-o", [ NSString stringWithFormat:@"%@/App Resources/Shapes/temp.bshape", [ [ NSBundle mainBundle ] resourcePath ] ], @"-I/usr/include/c++/4.2.1", @"-isystem", @"/usr/include/", @"-L", @"/usr/lib", @"-iframework/System/Library/Frameworks/", @"-I", [ NSString stringWithFormat:@"%@/App Resources/", [ [ NSBundle mainBundle ] resourcePath ] ], @"-I", [ NSString stringWithFormat:@"%@/Headers/", [ [ NSBundle mainBundle ] resourcePath ] ], @"-framework", @"Cocoa", @"-framework", @"OpenGL", @"-framework", @"QTKit", @"-framework", @"AppKit", @"-framework",@"Foundation", @"-framework", @"MovieDraw"];
	for (int z = 0; z < [ array2 count ]; z++)
		[ array addObject:array2[z] ];
	[ task setArguments:array ];
	NSPipe* pipe3 = [ NSPipe pipe ];
	[ task setStandardOutput:pipe3 ];
	[ task setStandardError:pipe3 ];
	
	[ task launch ];
	
	NSData *data = [ [ pipe3 fileHandleForReading ] readDataToEndOfFile ];
	[ task waitUntilExit ];
	NSString *string = [ [ NSString alloc ] initWithData:data encoding:NSUTF8StringEncoding ];
	[ editorView removeAllErrors ];
	if ([ string length ] == 0)
	{
		[ editorView setNeedsDisplay:YES ];
		return TRUE;
	}
	[ [ console textStorage ] appendAttributedString:[ [ NSAttributedString alloc ] initWithString:[ NSString stringWithFormat:@"Compile Shape: %@", string ]attributes:@{NSForegroundColorAttributeName: [ NSColor blackColor ]} ] ];
	
	NSLog(@"%@", string);
	
	NSRange erRange = NSMakeRange(0, 0);
	for (;;)
	{
		erRange = [ string rangeOfString:@": error: " options:0 range:NSMakeRange(NSMaxRange(erRange), [ string length ] - NSMaxRange(erRange)) ];
		if (erRange.length == 0)
			break;
		// Read backwards until next :
		unsigned long total = 0;
		BOOL isNumber = TRUE;
		unsigned int power = 0;
		for (long z = erRange.location - 1; z >= 0; z--)
		{
			unsigned char cmd = [ string characterAtIndex:z ];
			if (cmd == ':')
				break;
			if (!(cmd >= '0' && cmd <= '9'))
			{
				isNumber = FALSE;
				break;
			}
			total += (cmd - '0') * pow(10, power);
			power++;
		}
		if (!isNumber)
			continue;
		// Find next '\n'
		NSRange newRange = [ string rangeOfString:@"\n" options:0 range:NSMakeRange(NSMaxRange(erRange), [ string length ] - NSMaxRange(erRange)) ];
		if (newRange.length == 0)
			newRange.location = [ string length ];
		NSString* message = [ string substringWithRange:NSMakeRange(NSMaxRange(erRange), newRange.location - NSMaxRange(erRange)) ];
		[ editorView addError:message atLine:total type:MD_ERROR ];
	}
	erRange = NSMakeRange(0, 0);
	for (;;)
	{
		erRange = [ string rangeOfString:@": warning: " options:0 range:NSMakeRange(NSMaxRange(erRange), [ string length ] - NSMaxRange(erRange)) ];
		if (erRange.length == 0)
			break;
		// Read backwards until next :
		unsigned long total = 0;
		BOOL isNumber = TRUE;
		unsigned int power = 0;
		for (long z = erRange.location - 1; z >= 0; z--)
		{
			unsigned char cmd = [ string characterAtIndex:z ];
			if (cmd == ':')
				break;
			if (!(cmd >= '0' && cmd <= '9'))
			{
				isNumber = FALSE;
				break;
			}
			total += (cmd - '0') * pow(10, power);
			power++;
		}
		if (!isNumber)
			continue;
		// Find next '\n'
		NSRange newRange = [ string rangeOfString:@"\n" options:0 range:NSMakeRange(NSMaxRange(erRange), [ string length ] - NSMaxRange(erRange)) ];
		if (newRange.length == 0)
			newRange.location = [ string length ];
		NSString* message = [ string substringWithRange:NSMakeRange(NSMaxRange(erRange), newRange.location - NSMaxRange(erRange)) ];
		[ editorView addError:message atLine:total type:MD_WARNING ];
	}
	
	[ editorView setNeedsDisplay:YES ];
	
	return FALSE;
}
