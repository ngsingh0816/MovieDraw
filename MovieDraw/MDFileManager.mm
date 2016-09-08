//
//  MDFileManager.m
//  MovieDraw
//
//  Created by Neil on 1/12/14.
//  Copyright (c) 2014 Neil. All rights reserved.
//

#import "MDFileManager.h"
#import "Controller.h"
#import "MDObjectTools.h"

NSMutableArray* ImagesFromProject()
{
	NSMutableArray* array = [ NSMutableArray array ];
	
	FILE* file = fopen([ [ NSString stringWithFormat:@"%@/%@.mdp", workingDirectory, [ workingDirectory lastPathComponent ] ] UTF8String ], "rb");
	if (!file)
		return array;
	
	unsigned char sourceEdited = 0;
	fread(&sourceEdited, sizeof(unsigned char), 1, file);
	int width = 0, height = 0;
	fread(&width, sizeof(int), 1, file);
	fread(&height, sizeof(int), 1, file);
	unsigned int length = 0;
	fread(&length, sizeof(unsigned int), 1, file);
	char* crs = (char*)malloc(length + 1);
	fread(crs, length, 1, file);
	crs[length] = 0;
	free(crs);
	fread(&length, sizeof(unsigned int), 1, file);
	crs = (char*)malloc(length + 1);
	fread(crs, length, 1, file);
	crs[length] = 0;
	free(crs);
	unsigned int temp = 0;
	fread(&temp, sizeof(unsigned int), 1, file);	// Antialias
	fread(&temp, sizeof(unsigned int), 1, file);	// FPS
	fread(&length, sizeof(unsigned int), 1, file);
	crs = (char*)malloc(length + 1);
	fread(crs, length, 1, file);
	crs[length] = 0;
	free(crs);
	fread(&temp, sizeof(unsigned int), 1, file);	// Command
	unsigned int numOfScenes = 0;
	fread(&numOfScenes, sizeof(unsigned int), 1, file);
	for (unsigned int z = 0; z < numOfScenes; z++)
	{
		// Scene Name
		unsigned long length = 0;
		fread(&length, sizeof(unsigned long), 1, file);
		crs = (char*)malloc(length + 1);
		fread(crs, length, 1, file);
		crs[length] = 0;
		free(crs);
		
		// Scene Properties
		unsigned long skyLen = 0;
		fread(&skyLen, sizeof(unsigned long), 1, file);
		crs = (char*)malloc(skyLen + 1);
		fread(crs, 1, skyLen, file);
		crs[skyLen] = 0;
		float skyDist = 0;
		fread(&skyDist, sizeof(float), 1, file);
		float skyRed = 0, skyGreen = 0, skyBlue = 0, skyAlpha = 0;
		fread(&skyRed, sizeof(float), 1, file);
		fread(&skyGreen, sizeof(float), 1, file);
		fread(&skyBlue, sizeof(float), 1, file);
		fread(&skyAlpha, sizeof(float), 1, file);
		float skyCorrection = 0;
		fread(&skyCorrection, sizeof(float), 1, file);
		unsigned char skyVisible = 0;
		fread(&skyVisible, 1, 1, file);
		
		// Scene Image
		unsigned long picLength = 0;
		fread(&picLength, sizeof(unsigned long), 1, file);
		if (picLength != 0)
		{
			char* data = (char*)malloc(picLength);
			fread(data, picLength, 1, file);
			[ array addObject:[ NSData dataWithBytes:data length:picLength ] ];
			free(data);
		}
		else
			[ array addObject:[ NSData data ] ];
	}
	fclose(file);
	
	return array;
}

NSData* ImageFromGL(GLWindow* glWindow)
{
	NSSize frameSize = [ [ glWindow glView ] frame ].size;
	NSBitmapImageRep *image = [ [ NSBitmapImageRep alloc ] initWithBitmapDataPlanes:NULL pixelsWide:frameSize.width / 1.0 pixelsHigh:frameSize.height / 1.0 bitsPerSample:8 samplesPerPixel:3 hasAlpha:NO isPlanar:NO colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:0 bitsPerPixel:0 ];
	glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
	unsigned char pixels[(unsigned long)(frameSize.width * frameSize.height * 3)];
	glReadPixels(0, 0, frameSize.width, frameSize.height, GL_RGB, GL_UNSIGNED_BYTE, pixels);
	unsigned long index = 0;
	for (unsigned int y = 0; y < frameSize.height / 1.0; y++)
	{
		for (unsigned int x = 0; x < frameSize.width / 1.0; x++)
		{
			[ image setColor:[ NSColor colorWithCalibratedRed:pixels[index] / 255.0 green:pixels[index + 1] / 255.0 blue:pixels[index + 2] / 255.0 alpha:1 ] atX:x y:(frameSize.height / 1.0) - y ];
			index += 3;
		}
	}
	
	NSImage* trueImage = [ [ NSImage alloc ] initWithSize:[ image size ] ];
	[ trueImage addRepresentation:image ];
	NSSize realSize = NSMakeSize(frameSize.width * (102 / frameSize.height), 102);
	NSImage* scaledImage = [ trueImage imageByScalingProportionallyToSize:realSize ];
	[ scaledImage lockFocus ];
	NSBitmapImageRep* finalImage = [ [ NSBitmapImageRep alloc ] initWithFocusedViewRect:NSMakeRect(0, 0, realSize.width, realSize.height) ];
	
	return [ finalImage representationUsingType:NSPNGFileType properties:nil ];
}

void WriteDirectories(IFNode* node, FILE* file)
{
	unsigned long number = [ node numberOfChildren ];
	fwrite(&number, sizeof(unsigned long), 1, file);
	unsigned char parent = [ node isParent ];
	fwrite(&parent, 1, 1, file);
	for (unsigned long z = 0; z < number; z++)
	{
		unsigned long childLength = [ [ [ node childAtIndex:z ] title ] length ];
		fwrite(&childLength, sizeof(unsigned long), 1, file);
		fwrite([ [ [ node childAtIndex:z ] title ] UTF8String ], 1, childLength, file);
		
		// BreakPoints
		unsigned long numberOfBreaks = 0;
		unsigned long breakIndex = -1;
		if (TRUE)
		{
			IFNode* node2 = [ node childAtIndex:z ];
			NSString* currentOpenFile = [ [ NSString alloc ] initWithFormat:@"%@%@%@", workingDirectory, [ node2 parentsPath ], [ node2 title ] ];
			for (unsigned long q = 0; q < breakpointFiles.size(); q++)
			{
				if ([ breakpointFiles[q] isEqualToString:currentOpenFile ])
				{
					numberOfBreaks = breakpoints[q].size();
					breakIndex = q;
					break;
				}
			}
		}
		fwrite(&numberOfBreaks, sizeof(unsigned long), 1, file);
		for (unsigned long q = 0; q < numberOfBreaks; q++)
			fwrite(&breakpoints[breakIndex][q], sizeof(unsigned long), 1, file);
		
		WriteDirectories([ node childAtIndex:z ], file);
	}
}

void ReadDirectories(IFNode* node, FILE* file)
{
	unsigned long number = 0;
	fread(&number, sizeof(unsigned long), 1, file);
	unsigned char parent = 0;
	fread(&parent, 1, 1, file);
	[ node setIsParent:parent ];
	for (unsigned long z = 0; z < number; z++)
	{
		unsigned long childLength = 0;
		fread(&childLength, sizeof(unsigned long), 1, file);
		char* buffer = (char*)malloc(childLength + 1);
		buffer[childLength] = 0;
		fread(buffer, 1, childLength, file);
		IFNode* node2 = [ [ IFNode alloc ] initParentWithTitle:[ NSString stringWithFormat:@"%s", buffer ] children:[ NSMutableArray array ] ];
		[ node addChild:node2 ];
		free(buffer);
		
		unsigned long numberOfBreaks = 0;
		// BreakPoints
		unsigned long breakIndex = -1;
		if (TRUE)
		{
			NSString* currentOpenFile = [ [ NSString alloc ] initWithFormat:@"%@%@%@", workingDirectory, [ node2 parentsPath ], [ node2 title ] ];
			breakpointFiles.push_back(currentOpenFile);
			std::vector<unsigned long> b;
			breakpoints.push_back(b);
			breakIndex = breakpointFiles.size() - 1;
		}
		
		fread(&numberOfBreaks, sizeof(unsigned long), 1, file);
		for (unsigned long q = 0; q < numberOfBreaks; q++)
		{
			unsigned long b = 0;
			fread(&b, sizeof(unsigned long), 1, file);
			breakpoints[breakIndex].push_back(b);
		}
		
		ReadDirectories([ node childAtIndex:z ], file);
	}
}

void MDWriteNodes(MDNode* node, FILE* file)
{
	MDMatrix trans = [ node transformation ];
	fwrite(&trans, sizeof(MDMatrix), 1, file);
	BOOL isBone = [ node isBone ];
	fwrite(&isBone, sizeof(BOOL), 1, file);
	
	unsigned int numIndices = (unsigned int)[ node numberOfBones ];
	fwrite(&numIndices, sizeof(unsigned int), 1, file);
	for (unsigned int z = 0; z < numIndices; z++)
	{
		unsigned int meshIndex = [ node meshIndexAtIndex:z ];
		unsigned int boneIndex = [ node boneIndexAtIndex:z ];
		fwrite(&meshIndex, sizeof(unsigned int), 1, file);
		fwrite(&boneIndex, sizeof(unsigned int), 1, file);
	}
	
	unsigned int numSteps = (unsigned int)[ [ node animationSteps ] count ];
	fwrite(&numSteps, sizeof(unsigned int), 1, file);
	for (unsigned int z = 0; z < numSteps; z++)
	{
		unsigned int step = (unsigned int)[ node animationStepAtIndex:z ];
		fwrite(&step, sizeof(unsigned int), 1, file);
	}
	
	unsigned int numMeshes = (unsigned int)[ [ node meshes ] count ];
	fwrite(&numMeshes, sizeof(unsigned int), 1, file);
	for (unsigned int z = 0; z < numMeshes; z++)
	{
		unsigned int mesh = [ [ node meshes ][z] unsignedIntValue ];
		fwrite(&mesh, sizeof(unsigned int), 1, file);
	}
	
	unsigned int numChildren = (unsigned int)[ [ node children ] count ];
	fwrite(&numChildren, sizeof(unsigned int), 1, file);
	for (unsigned int z = 0; z < numChildren; z++)
		MDWriteNodes([ node children ][z], file);
}

void MDReadNodes(MDNode* node, FILE* file, MDNode* parent)
{
	[ node setParent:parent ];
	
	MDMatrix trans;
	fread(&trans, sizeof(MDMatrix), 1, file);
	[ node setTransformation:trans ];
	BOOL isBone = FALSE;
	fread(&isBone, sizeof(BOOL), 1, file);
	[ node setIsBone:isBone ];
	
	unsigned int numIndices = 0;
	fread(&numIndices, sizeof(unsigned int), 1, file);
	for (unsigned int z = 0; z < numIndices; z++)
	{
		unsigned int meshIndex = 0, boneIndex = 0;
		fread(&meshIndex, sizeof(unsigned int), 1, file);
		fread(&boneIndex, sizeof(unsigned int), 1, file);
		[ node addMeshIndex:meshIndex boneIndex:boneIndex ];
	}
	
	unsigned int numSteps = 0;
	fread(&numSteps, sizeof(unsigned int), 1, file);
	for (unsigned int z = 0; z < numSteps; z++)
	{
		unsigned int step = 0;
		fread(&step, sizeof(unsigned int), 1, file);
		[ node addAnimationStep:step ];
	}
	
	unsigned int numMeshes = 0;
	fread(&numMeshes, sizeof(unsigned int), 1, file);
	for (unsigned int z = 0; z < numMeshes; z++)
	{
		unsigned int mesh = 0;
		fread(&mesh, sizeof(unsigned int), 1, file);
		[ node addMesh:mesh ];
	}
	
	unsigned int numChildren = 0;
	fread(&numChildren, sizeof(unsigned int), 1, file);
	for (unsigned int z = 0; z < numChildren; z++)
	{
		MDNode* child = [ [ MDNode alloc ] init ];
		MDReadNodes(child, file, node);
		[ node addChild:child ];
	}
}

MDNode* MDNodeForAnimationStep(MDNode* nodes, unsigned int step, unsigned int animation)
{
	if ([ [ nodes animationSteps ] count ] > step && [ nodes animationStepAtIndex:animation ] == step)
		return nodes;
	
	for (unsigned long z = 0; z < [ [ nodes children ] count ]; z++)
	{
		MDNode* ret = MDNodeForAnimationStep([ nodes children ][z], step, animation);
		if (ret)
			return ret;
	}
	
	return nil;
}

void MDSaveProject(BOOL pics, BOOL models, MDCodeView* editorView, GLWindow* glWindow, TableWindow* sceneTable, OutlineWindow* fileOutline)
{
	NSMutableArray* savedImages = ImagesFromProject();
	
	FILE* file = fopen([ [ NSString stringWithFormat:@"%@/%@.mdp", workingDirectory, [ workingDirectory lastPathComponent ] ] UTF8String ], "wb");
	// Project Data
	unsigned char sourceEdited = [ editorView editedNoReset ];
	fwrite(&sourceEdited, sizeof(unsigned char), 1, file);
	// Resolution
	int width = projectRes.width, height = projectRes.height;
	fwrite(&width, sizeof(int), 1, file);
	fwrite(&height, sizeof(int), 1, file);
	unsigned int length = (unsigned int)[ currentScene length ];
	fwrite(&length, sizeof(unsigned int), 1, file);
	fwrite([ currentScene UTF8String ], length, 1, file);
	length = (unsigned int)[ projectScene length ];
	fwrite(&length, sizeof(unsigned int), 1, file);
	fwrite([ projectScene UTF8String ], length, 1, file);
	fwrite(&projectAntialias, sizeof(unsigned int), 1, file);
	projectFPS = [ glWindow FPS ];
	fwrite(&projectFPS, sizeof(unsigned int), 1, file);
	length = (unsigned int)[ projectIcon length ];
	fwrite(&length, sizeof(unsigned int), 1, file);
	fwrite([ projectIcon UTF8String ], length, 1, file);
	fwrite(&projectCommand, sizeof(unsigned int), 1, file);
	unsigned int numOfScenes = (unsigned int)[ sceneTable numberOfRows ];
	fwrite(&numOfScenes, sizeof(unsigned int), 1, file);
	for (unsigned int z = 0; z < numOfScenes; z++)
	{
		NSString* path = [ NSString stringWithFormat:@"%@", [ sceneTable itemAtRow:z ][@"Name"] ];
		unsigned long length = [ path length ];
		fwrite(&length, sizeof(unsigned long), 1, file);
		fwrite([ path UTF8String ], length, 1, file);
		
		// Scene properties
		NSMutableDictionary* dict = sceneProps[[ sceneTable itemAtRow:z ][@"Name"]];
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
		
		// Scene Image
		unsigned long picLength = 0;
		if ([ glWindow glView ] && [ currentScene isEqualToString:[ sceneTable itemAtRow:z ][@"Name"] ] && pics)
		{
			NSData* data = ImageFromGL(glWindow);
			[ sceneTable itemAtRow:z ][@"Image"] = [ [ NSImage alloc ] initWithData:data ];
			[ sceneTable reloadData ];
			picLength = [ data length ];
			fwrite(&picLength, sizeof(unsigned long), 1, file);
			fwrite([ data bytes ], picLength, 1, file);
		}
		else if ([ savedImages count ] > z)
		{
			NSData* data = savedImages[z];
			picLength = [ data length ];
			fwrite(&picLength, sizeof(unsigned long), 1, file);
			if (picLength != 0)
				fwrite([ data bytes ], picLength, 1, file);
		}
		else
		{
			picLength = 0;
			fwrite(&picLength, sizeof(unsigned long), 1, file);
		}
	}
	// Files
	WriteDirectories([ fileOutline rootNode ], file);
	// List instances
	unsigned long instancesCount = [ instances count ];
	fwrite(&instancesCount, sizeof(unsigned long), 1, file);
	for (unsigned long z = 0; z < [ instances count ]; z++)
	{
		unsigned short nameLength = [ [ instances[z] name ] length ];
		fwrite(&nameLength, sizeof(unsigned short), 1, file);
		fwrite([ [ instances[z] name ] UTF8String ], 1, nameLength, file);
		
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
	}
	fclose(file);
	
	//if (models)
	{
		for (unsigned long z = 0; z < [ instances count ]; z++)
		{
			if ([ [ instances[z] name ] length ] == 0)
				continue;
			
			// For now, write all models and change to make it only saves if it is changed
			/*file = fopen([ [ NSString stringWithFormat:@"%@/Models/%@.mdm", workingDirectory, [ [ instances objectAtIndex:z ] name ] ] UTF8String ], "rb");
			 if (file)
			 {
			 // Only skip if we don't have to create models and it already exists
			 fclose(file);
			 if (!models)
			 continue;
			 }*/
			
			file = fopen([ [ NSString stringWithFormat:@"%@/Models/%@.mdm", workingDirectory, [ instances[z] name ] ] UTF8String ], "wb");
			
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
			
			fclose(file);
		}
	}
	
	file = fopen([ [ NSString stringWithFormat:@"%@/Scenes/%@.mds", workingDirectory, currentScene ] UTF8String ], "wb");
	// Scene
	float tpx = translationPoint.x, tpy = translationPoint.y, tpz = translationPoint.z;
	float lpx = lookPoint.x, lpy = lookPoint.y, lpz = lookPoint.z;
	float rotX = [ (MDRotationBox*)ViewForIdentity(@"Rotation Box") xrotation ], rotY = [ (MDRotationBox*)ViewForIdentity(@"Rotation Box") yrotation ], rotZ = [ (MDRotationBox*)ViewForIdentity(@"Rotation Box") zrotation ];
	fwrite(&tpx, sizeof(float), 1, file);
	fwrite(&tpy, sizeof(float), 1, file);
	fwrite(&tpz, sizeof(float), 1, file);
	fwrite(&lpx, sizeof(float), 1, file);
	fwrite(&lpy, sizeof(float), 1, file);
	fwrite(&lpz, sizeof(float), 1, file);
	fwrite(&rotX, sizeof(float), 1, file);
	fwrite(&rotY, sizeof(float), 1, file);
	fwrite(&rotZ, sizeof(float), 1, file);
	
	// List objects
	unsigned long objectsCount = [ objects count ];
	fwrite(&objectsCount, sizeof(unsigned long), 1, file);
	for (int z = 0; z < [ objects count ]; z++)
	{
		MDInstance* inst = [ objects[z] instance ];
		unsigned long instIndex = [ instances indexOfObject:inst ];
		fwrite(&instIndex, sizeof(unsigned long), 1, file);
		
		unsigned short nameLength = [ [ objects[z] name ] length ];
		fwrite(&nameLength, sizeof(unsigned short), 1, file);
		fwrite([ [ objects[z] name ] UTF8String ], 1, nameLength, file);
		
		float tx = [ objects[z] translateX ], ty = [ objects[z] translateY ], tz = [ objects[z] translateZ ], sx = [ objects[z] scaleX ], sy = [ objects[z] scaleY ], sz = [ objects[z] scaleZ ], rx = [ objects[z] rotateAxis ].x, ry = [ objects[z] rotateAxis ].y, rz = [ objects[z] rotateAxis ].z, cx = [ objects[z] colorMultiplier ].x, cy = [ objects[z] colorMultiplier ].y, cz = [ objects[z] colorMultiplier ].z, cw = [ objects[z] colorMultiplier ].w;
		float ra = [ objects[z] rotateAngle ];
		fwrite(&tx, sizeof(float), 1, file);
		fwrite(&ty, sizeof(float), 1, file);
		fwrite(&tz, sizeof(float), 1, file);
		fwrite(&sx, sizeof(float), 1, file);
		fwrite(&sy, sizeof(float), 1, file);
		fwrite(&sz, sizeof(float), 1, file);
		fwrite(&rx, sizeof(float), 1, file);
		fwrite(&ry, sizeof(float), 1, file);
		fwrite(&rz, sizeof(float), 1, file);
		fwrite(&ra, sizeof(float), 1, file);
		fwrite(&cx, sizeof(float), 1, file);
		fwrite(&cy, sizeof(float), 1, file);
		fwrite(&cz, sizeof(float), 1, file);
		fwrite(&cw, sizeof(float), 1, file);
		
		// Physics
		float mass = [ objects[z] mass ], restituion = [ objects[z] restitution ], friction = [ objects[z] friction ], rfriction = [ objects[z] rollingFriction ];
		unsigned char phyType = [ objects[z] physicsType ], phyFlags = [ objects[z] flags ];
		fwrite(&mass, sizeof(float), 1, file);
		fwrite(&restituion, sizeof(float), 1, file);
		fwrite(&phyType, sizeof(unsigned char), 1, file);
		fwrite(&phyFlags, sizeof(unsigned char), 1, file);
		fwrite(&friction, sizeof(float), 1, file);
		fwrite(&rfriction, sizeof(float), 1, file);
		
		// Flags
		unsigned char shouldDraw = [ objects[z] shouldDraw ] | ([ objects[z] shouldView ] << 1) | ([ objects[z] isStatic ] << 2);
		fwrite(&shouldDraw, sizeof(unsigned char), 1, file);
		
		// Write object properties
		NSArray* opKeys = [ [ objects[z] properties ] allKeys ];
		unsigned long oprop = [ opKeys count ];
		fwrite(&oprop, sizeof(unsigned long), 1, file);
		for (unsigned long t = 0; t < oprop; t++)
		{
			NSString* key = opKeys[t];
			unsigned long length = [ key length ];
			fwrite(&length, sizeof(unsigned long), 1, file);
			const char* str = [ key UTF8String ];
			fwrite(str, 1, length, file);
			NSString* val = [ objects[z] properties ][key];
			length = [ val length ];
			fwrite(&length, sizeof(unsigned long), 1, file);
			str = [ val UTF8String ];
			fwrite(str, 1, length, file);
		}
	}
	
	// Other Objects
	unsigned long otherObjSize = [ otherObjects count ];
	fwrite(&otherObjSize, sizeof(unsigned long), 1, file);
	for (int z = 0; z < [ otherObjects count ]; z++)
	{
		unsigned int realType = 0;
		if ([ otherObjects[z] isKindOfClass:[ MDCamera class ] ])
		{
			realType = 1;
			fwrite(&realType, sizeof(realType), 1, file);
			MDCamera* cam = otherObjects[z];
			MDVector3 point = [ cam midPoint ], look = [ cam lookPoint ];
			float orien = [ cam orientation ];
			BOOL show = [ cam show ], use = [ cam use ], sel = [ cam selected ], looksel = [ cam lookSelected ];
			fwrite(&point, sizeof(point), 1, file);
			fwrite(&look, sizeof(look), 1, file);
			fwrite(&orien, sizeof(float), 1, file);
			fwrite(&show, 1, 1, file);
			fwrite(&use, 1, 1, file);
			fwrite(&sel, 1, 1, file);
			fwrite(&looksel, 1, 1, file);
			unsigned int nameSize = (unsigned int)[ [ cam name ] length ];
			fwrite(&nameSize, sizeof(unsigned int), 1, file);
			char* buffer = (char*)malloc(nameSize + 1);
			memcpy(buffer, [ [ cam name ] UTF8String ], nameSize);
			buffer[nameSize] = 0;
			fwrite(buffer, nameSize, 1, file);
			free(buffer);
			buffer = NULL;
		}
		else if ([ otherObjects[z] isKindOfClass:[ MDLight class ] ])
		{
			realType = 2;
			fwrite(&realType, sizeof(realType), 1, file);
			MDLight* light = otherObjects[z];
			MDVector3 point = light.position, look = light.spotDirection;
			MDVector4 ambient = light.ambientColor, diffuse = light.diffuseColor, specular = light.specularColor;
			float exp = light.spotExp, cut = light.spotCut, ccut = light.spotAngle, cat = light.constAtt, linat = light.linAtt, quadat = light.quadAtt;
			unsigned int type = light.lightType;
			BOOL enableShadows = light.enableShadows, selected = light.selected, show = light.show, isStatic = light.isStatic;
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
			fwrite(&selected, sizeof(selected), 1, file);
			fwrite(&show, sizeof(show), 1, file);
			unsigned int nameSize = (unsigned int)[ [ light name ] length ];
			fwrite(&nameSize, sizeof(unsigned int), 1, file);
			char* buffer = (char*)malloc(nameSize + 1);
			memcpy(buffer, [ [ light name ] UTF8String ], nameSize);
			buffer[nameSize] = 0;
			fwrite(buffer, nameSize, 1, file);
			free(buffer);
			buffer = NULL;
		}
		else if ([ otherObjects[z] isKindOfClass:[ MDParticleEngine class ] ])
		{
			realType = 3;
			fwrite(&realType, sizeof(realType), 1, file);
			MDParticleEngine* engine = otherObjects[z];
			MDVector3 point = engine.position, vel = engine.velocities;
			MDVector4 start = engine.startColor, end = engine.endColor;
			float size = engine.particleSize;
			unsigned long number = engine.numberOfParticles, life = engine.particleLife;
			unsigned int velType = engine.velocityType;
			BOOL selected = engine.selected, show = engine.show;
			fwrite(&point, 1, sizeof(point), file);
			fwrite(&velType, 1, sizeof(velType), file);
			fwrite(&vel, 1, sizeof(vel), file);
			fwrite(&start, 1, sizeof(start), file);
			fwrite(&end, 1, sizeof(end), file);
			fwrite(&size, 1, sizeof(size), file);
			fwrite(&number, 1, sizeof(number), file);
			fwrite(&life, 1, sizeof(life), file);
			fwrite(&selected, sizeof(selected), 1, file);
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
		else if ([ otherObjects[z] isKindOfClass:[ MDCurve class ] ])
		{
			realType = 4;
			fwrite(&realType, sizeof(realType), 1, file);
			MDCurve* curve = otherObjects[z];
			std::vector<MDVector3> p = *[ curve curvePoints ];
			BOOL selected = [ curve selected ], show = [ curve show ];
			unsigned long numP = p.size();
			fwrite(&numP, 1, sizeof(unsigned long), file);
			for (unsigned long q = 0; q < numP; q++)
				fwrite(&p[q], 1, sizeof(p[q]), file);
			fwrite(&selected, sizeof(selected), 1, file);
			fwrite(&show, sizeof(show), 1, file);
			unsigned int nameSize = (unsigned int)[ [ curve name ] length ];
			fwrite(&nameSize, sizeof(unsigned int), 1, file);
			char* buffer = (char*)malloc(nameSize + 1);
			memcpy(buffer, [ [ curve name ] UTF8String ], nameSize);
			buffer[nameSize] = 0;
			fwrite(buffer, nameSize, 1, file);
			free(buffer);
			buffer = NULL;
		}
		else if ([ otherObjects[z] isKindOfClass:[ MDSound class ] ])
		{
			realType = 5;
			fwrite(&realType, sizeof(realType), 1, file);
			MDSound* sound = otherObjects[z];
			
			MDVector3 position = [ sound position ];
			fwrite(&position, sizeof(MDVector3), 1, file);
			
			float linAtt = [ sound linAtt ], quadAtt = [ sound quadAtt ], minVol = [ sound minVolume ], maxVol = [ sound maxVolume ], speed = [ sound speed ];
			fwrite(&linAtt, sizeof(float), 1, file);
			fwrite(&quadAtt, sizeof(float), 1, file);
			fwrite(&minVol, sizeof(float), 1, file);
			fwrite(&maxVol, sizeof(float), 1, file);
			fwrite(&speed, sizeof(float), 1, file);
			unsigned char flags = [ sound flags ];
			fwrite(&flags, sizeof(unsigned char), 1, file);
			
			BOOL selected = [ sound selected ], show = [ sound show ];
			fwrite(&selected, sizeof(selected), 1, file);
			fwrite(&show, sizeof(show), 1, file);
			
			unsigned int fileSize = (unsigned int)[ [ sound file ] length ];
			fwrite(&fileSize, sizeof(unsigned int), 1, file);
			char* buffer = (char*)malloc(fileSize + 1);
			memcpy(buffer, [ [ sound file ] UTF8String ], fileSize);
			buffer[fileSize] = 0;
			fwrite(buffer, fileSize, 1, file);
			free(buffer);
			buffer = NULL;
						
			unsigned int nameSize = (unsigned int)[ [ sound name ] length ];
			fwrite(&nameSize, sizeof(unsigned int), 1, file);
			buffer = (char*)malloc(nameSize + 1);
			memcpy(buffer, [ [ sound name ] UTF8String ], nameSize);
			buffer[nameSize] = 0;
			fwrite(buffer, nameSize, 1, file);
			free(buffer);
			buffer = NULL;
		}
	}
	// Selected
	unsigned long selectedSize = [ selected count ];
	fwrite(&selectedSize, sizeof(unsigned long), 1, file);
	for (int z = 0; z < [ selected count ]; z++)
	{
		unsigned long indexSel = [ objects indexOfObject:[ selected selectedValueAtIndex:z ][@"Object"] ];
		fwrite(&indexSel, sizeof(unsigned long), 1, file);
	}
	// Other selected
	if (selectedSize == 0)
	{
		unsigned long otherSel = -1;//[ otherNames selectedRow ];
		fwrite(&otherSel, sizeof(unsigned long), 1, file);
	}
	
	/*unsigned long fileViewer = [ [ [ fileOutline rootNode ] childAtIndex:0 ] numberOfChildren ];
	 fwrite(&fileViewer, sizeof(unsigned long), 1, file);
	 for (int z = 0; z < fileViewer; z++)
	 {
	 NSString* string = [ NSString stringWithString:[ [ (IFNode*)[ [ fileOutline itemAtRow:0 ] childAtIndex:z ] dictionary ] objectForKey:@"Location" ] ];
	 unsigned long fileLength = [ string length ];
	 fwrite(&fileLength, sizeof(unsigned long), 1, file);
	 fwrite([ string UTF8String ], 1, [ string length ], file);
	 }*/
	
	fclose(file);
}

void MDReadProject(BOOL proj, MDCodeView* editorView, GLWindow* glWindow, TableWindow* sceneTable, OutlineWindow* fileOutline)
{
	FILE* file = NULL;
	if (proj)
	{
		file = fopen([ [ NSString stringWithFormat:@"%@/%@.mdp", workingDirectory, [ workingDirectory lastPathComponent ] ] UTF8String ], "rb");
		// Project Data
		unsigned char sourceEdited = 0;
		fread(&sourceEdited, sizeof(unsigned char), 1, file);
		[ editorView setEdited:sourceEdited ];
		// Resolution
		int width = 0, height = 0;
		fread(&width, sizeof(int), 1, file);
		fread(&height, sizeof(int), 1, file);
		projectRes = NSMakeSize(width, height);
		unsigned int length = 0;
		fread(&length, sizeof(unsigned int), 1, file);
		char* crs = (char*)malloc(length + 1);
		fread(crs, length, 1, file);
		crs[length] = 0;
		currentScene = @(crs);
		free(crs);
		fread(&length, sizeof(unsigned int), 1, file);
		crs = (char*)malloc(length + 1);
		fread(crs, length, 1, file);
		crs[length] = 0;
		projectScene = @(crs);
		free(crs);
		fread(&projectAntialias, sizeof(unsigned int), 1, file);
		[ [ glWindow glView ] resetPixelFormat ];
		fread(&projectFPS, sizeof(unsigned int), 1, file);
		[ glWindow setFPS:projectFPS ];
		fread(&length, sizeof(unsigned int), 1, file);
		crs = (char*)malloc(length + 1);
		fread(crs, length, 1, file);
		crs[length] = 0;
		projectIcon = @(crs);
		free(crs);
		fread(&projectCommand, sizeof(unsigned int), 1, file);
		sceneProps = [ [ NSMutableDictionary alloc ] init ];
		unsigned int numOfScenes = 0;
		fread(&numOfScenes, sizeof(unsigned int), 1, file);
		[ sceneTable removeAllRows ];
		for (unsigned int z = 0; z < numOfScenes; z++)
		{
			unsigned long length = 0;
			fread(&length, sizeof(unsigned long), 1, file);
			crs = (char*)malloc(length + 1);
			fread(crs, length, 1, file);
			crs[length] = 0;
			NSString* name = [ NSString stringWithFormat:@"%@/Scenes/%s.mds", workingDirectory, crs ];
			NSString* trueName = [ [ name lastPathComponent ] substringToIndex:[ [ name lastPathComponent ] length ] - 4 ];
			[ sceneTable addRow:@{@"Name": trueName, @"Image": [ NSImage imageNamed:NSImageNameApplicationIcon ], @"Loaded": @""} ];
			if ([ trueName isEqualToString:currentScene ])
			{
				[ sceneTable itemAtRow:z ][@"Loaded"] = @"✓";
				[ sceneTable reloadData ];
			}
			free(crs);
			
			// Scene Properties
			unsigned long skyLen = 0;
			fread(&skyLen, sizeof(unsigned long), 1, file);
			crs = (char*)malloc(skyLen + 1);
			fread(crs, 1, skyLen, file);
			crs[skyLen] = 0;
			float skyDist = 0;
			fread(&skyDist, sizeof(float), 1, file);
			float skyRed = 0, skyGreen = 0, skyBlue = 0, skyAlpha = 0;
			fread(&skyRed, sizeof(float), 1, file);
			fread(&skyGreen, sizeof(float), 1, file);
			fread(&skyBlue, sizeof(float), 1, file);
			fread(&skyAlpha, sizeof(float), 1, file);
			float skyCorrection = 0;
			fread(&skyCorrection, sizeof(float), 1, file);
			unsigned char skyVisible = 0;
			fread(&skyVisible, 1, 1, file);
			
			[ sceneProps addEntriesFromDictionary:@{trueName: [ NSMutableDictionary dictionaryWithObjectsAndKeys:[ NSString stringWithFormat:@"%s", crs ], @"Skybox Texture Path", @(skyDist), @"Skybox Distance", [ NSColor colorWithCalibratedRed:skyRed green:skyGreen blue:skyBlue alpha:skyAlpha ], @"Skybox Color", @(skyCorrection), @"Skybox Correction", [ NSNumber numberWithBool:skyVisible ], @"Skybox Visible", nil ]} ];
			if (skyLen != 0)
			{
				unsigned int texture = 0;
				LoadImage([ [ NSString stringWithFormat:@"%@%@/Resources/%s", workingDirectory, [ workingDirectory lastPathComponent ], crs ] UTF8String ], &texture, 0);
				sceneProperties[@"Skybox Texture"] = @(texture);
				[ [ glWindow glView ] updateSkybox ];
			}
			free(crs);
			
			// Scene Image
			unsigned long picLength = 0;
			fread(&picLength, sizeof(unsigned long), 1, file);
			if (picLength != 0)
			{
				char* data = (char*)malloc(picLength);
				fread(data, picLength, 1, file);
				NSImage* image = [ [ NSImage alloc ] initWithData:[ NSData dataWithBytes:data length:picLength ] ];
				free(data);
				if (image)
				{
					[ sceneTable itemAtRow:z ][@"Image"] = image;
					[ sceneTable reloadData ];
				}
			}
		}
		[ fileOutline removeAllItems ];
		breakpoints.clear();
		breakpointFiles.clear();
		ReadDirectories([ fileOutline rootNode ], file);
		[ fileOutline reloadData ];
		// List instances
		unsigned long instancesCount = 0;
		fread(&instancesCount, sizeof(unsigned long), 1, file);
		[ instances removeAllObjects ];
		for (unsigned long z = 0; z < instancesCount; z++)
		{
			unsigned short nameLength = 0;
			fread(&nameLength, sizeof(unsigned short), 1, file);
			char* buffer = (char*)malloc(nameLength + 1);
			fread(buffer, 1, nameLength, file);
			buffer[nameLength] = 0;
			
			MDInstance* instance = [ [ MDInstance alloc ] init ];
			[ instance setName:[ NSString stringWithFormat:@"%s", buffer ] ];
			
			// Read instance properties
			unsigned long oprop = 0;
			fread(&oprop, sizeof(unsigned long), 1, file);
			for (unsigned long t = 0; t < oprop; t++)
			{
				unsigned long length = 0;
				fread(&length, sizeof(unsigned long), 1, file);
				char* str = (char*)malloc(length + 1);
				fread(str, length, 1, file);
				str[length] = 0;
				NSString* key = @(str);
				free(str);
				fread(&length, sizeof(unsigned long), 1, file);
				str = (char*)malloc(length + 1);
				fread(str, length, 1, file);
				str[length] = 0;
				NSString* val = @(str);
				free(str);
				[ instance addProperty:val forKey:key ];
			}
			
			FILE* file2 = fopen([ [ NSString stringWithFormat:@"%@/Models/%s.mdm", workingDirectory, buffer ] UTF8String ], "rb");
			
			if (!file2)
			{
				NSString* path = [ NSString stringWithFormat:@"%@/Models/%s.mdm", workingDirectory, buffer ];
				NSRunAlertPanel(@"Error", @"Could not find \"%@\".", @"Ok", nil, nil, path);
				
				// So indexing still works
				[ instances addObject:instance ];
				
				free(buffer);
				buffer = nil;
				
				continue;
			}
			
			free(buffer);
			buffer = NULL;
			
			unsigned int numMesh = 0;
			fread(&numMesh, sizeof(unsigned int), 1, file2);
			for (unsigned long t = 0; t < numMesh; t++)
			{
				[ instance beginMesh ];
				MDVector4 color = MDVector4Create(1, 1, 1, 1);
				fread(&color.x, sizeof(float), 1, file2);
				fread(&color.y, sizeof(float), 1, file2);
				fread(&color.z, sizeof(float), 1, file2);
				fread(&color.w, sizeof(float), 1, file2);
				[ instance setColor:color ];
				
				MDMatrix transformMatrix, meshMatrix;
				fread(&transformMatrix, sizeof(MDMatrix), 1, file2);
				fread(&meshMatrix, sizeof(MDMatrix), 1, file2);
				[ instance setTransformMatrix:transformMatrix ];
				[ instance setMeshMatrix:meshMatrix ];
				
				unsigned long pointCount = 0;
				fread(&pointCount, sizeof(unsigned long), 1, file2);
				for (unsigned long q = 0; q < pointCount; q++)
				{
					MDPoint* p = [ [ MDPoint alloc ] init ];
					float x = 0, y = 0, z = 0, normX = 0, normY = 0, normZ = 0, ux = 0, vy = 0;
					fread(&x, sizeof(float), 1, file2);
					fread(&y, sizeof(float), 1, file2);
					fread(&z, sizeof(float), 1, file2);
					fread(&normX, sizeof(float), 1, file2);
					fread(&normY, sizeof(float), 1, file2);
					fread(&normZ, sizeof(float), 1, file2);
					fread(&ux, sizeof(float), 1, file2);
					fread(&vy, sizeof(float), 1, file2);
					p.x = x, p.y = y, p.z = z, p.normalX = normX, p.normalY = normY, p.normalZ = normZ, p.textureCoordX = ux, p.textureCoordY = vy;
					
					[ instance addPoint:p ];
				}
				
				unsigned int indexNum = 0;
				fread(&indexNum, sizeof(unsigned int), 1, file2);
				for (unsigned int q = 0; q < indexNum; q++)
				{
					unsigned int index = 0;
					fread(&index, sizeof(unsigned int), 1, file2);
					[ instance addIndex:index ];
				}
				
				unsigned int texNum = 0;
				fread(&texNum, sizeof(unsigned int), 1, file2);
				for (unsigned int q = 0; q < texNum; q++)
				{
					unsigned char type = 0;
					fread(&type, sizeof(unsigned char), 1, file2);
					unsigned int head = 0;
					fread(&head, sizeof(unsigned int), 1, file2);
					float size = 0;
					fread(&size, sizeof(float), 1, file2);
					unsigned int len = 0;
					fread(&len, sizeof(unsigned int), 1, file2);
					char* buffer = (char*)malloc(len + 1);
					fread(buffer, len, 1, file2);
					buffer[len] = 0;
					[ instance addTexture:[ NSString stringWithFormat:@"%@/%@/Resources/%s", workingDirectory, [ workingDirectory lastPathComponent ], buffer ] withType:(MDTextureType)type withHead:head withSize:size ];
					free(buffer);
					buffer = NULL;
				}
				
				unsigned int boneNum = 0;
				fread(&boneNum, sizeof(unsigned int), 1, file2);
				for (unsigned int q = 0; q < boneNum; q++)
				{
					NSMutableArray* array = [ [ NSMutableArray alloc ] init ];
					MDMatrix offsetMatrix;
					fread(&offsetMatrix, sizeof(MDMatrix), 1, file2);
					unsigned int weightNum = 0;
					fread(&weightNum, sizeof(unsigned int), 1, file2);
					for (unsigned int y = 0; y < weightNum; y++)
					{
						unsigned int vertexID = 0;
						fread(&vertexID, sizeof(unsigned int), 1, file2);
						float fWeight = 0;
						fread(&fWeight, sizeof(float), 1, file2);
						
						MDVertexWeight* weight = [ [ MDVertexWeight alloc ] initWithVeretx:vertexID withWeight:fWeight ];
						[ array addObject:weight ];
					}
					[ instance addBone:array withMatrix:offsetMatrix ];
				}
				
				[ instance endMesh ];
			}
			
			MDVector4 specularColor;
			fread(&specularColor.x, sizeof(float), 1, file2);
			fread(&specularColor.y, sizeof(float), 1, file2);
			fread(&specularColor.z, sizeof(float), 1, file2);
			fread(&specularColor.w, sizeof(float), 1, file2);
			float shininess = 0;
			fread(&shininess, sizeof(float), 1, file2);
			[ instance setSpecularColor:specularColor ];
			[ instance setShininess:shininess ];
			
			MDMatrix startMatrix;
			fread(&startMatrix, sizeof(MDMatrix), 1, file2);
			[ instance setStartMatrix:startMatrix ];
			
			BOOL hasNode = 0;
			fread(&hasNode, sizeof(BOOL), 1, file2);
			
			if (hasNode)
			{
				MDNode* rootNode = [ [ MDNode alloc ] init ];
				MDReadNodes(rootNode, file2, nil);
				[ instance setRootNode:rootNode ];
			}
			
			unsigned int numAnims = 0;
			fread(&numAnims, sizeof(unsigned int), 1, file2);
			for (unsigned int q = 0; q < numAnims; q++)
			{
				MDAnimation* animation = [ [ MDAnimation alloc ] init ];
				
				unsigned int nameLength = 0;
				fread(&nameLength, sizeof(unsigned int), 1, file2);
				char* buffer = (char*)malloc(nameLength + 1);
				fread(buffer, sizeof(char), nameLength, file2);
				buffer[nameLength] = 0;
				[ animation setName:@(buffer) ];
				free(buffer);
				buffer = NULL;
				
				float duration = 0;
				fread(&duration, sizeof(float), 1, file2);
				[ animation setDuration:duration ];
				
				std::vector<MDAnimationStep> steps;
				unsigned int numSteps = 0;
				fread(&numSteps, sizeof(unsigned int), 1, file2);
				for (unsigned int t = 0; t < numSteps; t++)
				{
					MDAnimationStep step;
					
					step.node = MDNodeForAnimationStep([ instance rootNode ], t, q);
					unsigned int numPositions = 0;
					fread(&numPositions, sizeof(unsigned int), 1, file2);
					for (unsigned long y = 0; y < numPositions; y++)
					{
						MDVector3 pos;
						fread(&pos, sizeof(MDVector3), 1, file2);
						float posTime = 0;
						fread(&posTime, sizeof(float), 1, file2);
						
						step.positions.push_back(pos);
						step.positionTimes.push_back(posTime);
					}
					
					unsigned int numRots = 0;
					fread(&numRots, sizeof(unsigned int), 1, file2);
					for (unsigned long y = 0; y < numRots; y++)
					{
						MDVector4 rot;
						fread(&rot, sizeof(MDVector4), 1, file2);
						float rotTime = 0;
						fread(&rotTime, sizeof(float), 1, file2);
						
						step.rotations.push_back(rot);
						step.rotateTimes.push_back(rotTime);
					}
					
					unsigned int numScales = 0;
					fread(&numScales, sizeof(unsigned int), 1, file2);
					for (unsigned long y = 0; y < numScales; y++)
					{
						MDVector3 scale;
						fread(&scale, sizeof(MDVector3), 1, file2);
						float scaleTime = 0;
						fread(&scaleTime, sizeof(float), 1, file2);
						
						step.scalings.push_back(scale);
						step.scaleTimes.push_back(scaleTime);
					}
					
					steps.push_back(step);
				}
				
				[ animation setSteps:steps ];
				
				[ instance addAnimation:animation ];
			}
			
			[ instance setupVBO ];
			
			[ instances addObject:instance ];
			fclose(file2);
		}
		fclose(file);
	}
	
	
	file = fopen([ [ NSString stringWithFormat:@"%@/Scenes/%@.mds", workingDirectory, currentScene ] UTF8String ], "rb");
	unsigned long size = 0;
	if (file)
	{
		fseek(file, 0, SEEK_END);
		size = ftell(file);
		rewind(file);
	}
	if (size < 9 * sizeof(float) + 3 * sizeof(unsigned long) || !file)
	{
		translationPoint = MDVector3Create(0, 0, -20);
		lookPoint = MDVector3Create(0, 0, 0);
		if (ViewForIdentity(@"Rotation Box") != nil)
		{
			[ (MDRotationBox*)ViewForIdentity(@"Rotation Box") setXRotation:0 show:NO ];
			[ (MDRotationBox*)ViewForIdentity(@"Rotation Box") setYRotation:0 show:NO ];
			[ (MDRotationBox*)ViewForIdentity(@"Rotation Box") setZRotation:0 show:NO ];
		}
		[ objects removeAllObjects ];
		[ otherObjects removeAllObjects ];
		[ selected clear ];
		
		if (file)
			fclose(file);
		else
		{
			NSRunAlertPanel(@"Error", @"Could not find the file \"%@\".", @"Ok", nil, nil, [ NSString stringWithFormat:@"%@Scenes/%@.mds", workingDirectory, currentScene ]);
		}
		return;
	}
	
	// Scene
	float tpx = 0, tpy = 0, tpz = 0, lpx = 0, lpy = 0, lpz = 0, rotX = 0, rotY = 0, rotZ = 0;
	fread(&tpx, sizeof(float), 1, file);
	fread(&tpy, sizeof(float), 1, file);
	fread(&tpz, sizeof(float), 1, file);
	fread(&lpx, sizeof(float), 1, file);
	fread(&lpy, sizeof(float), 1, file);
	fread(&lpz, sizeof(float), 1, file);
	fread(&rotX, sizeof(float), 1, file);
	fread(&rotY, sizeof(float), 1, file);
	fread(&rotZ, sizeof(float), 1, file);
	translationPoint.x = tpx, translationPoint.y = tpy, translationPoint.z = tpz;
	lookPoint.x = lpx, lookPoint.y = lpy, lookPoint.z = lpz;
	if (ViewForIdentity(@"Rotation Box") != nil)
	{
		[ (MDRotationBox*)ViewForIdentity(@"Rotation Box") setXRotation:rotX show:NO ];
		[ (MDRotationBox*)ViewForIdentity(@"Rotation Box") setYRotation:rotY show:NO ];
		[ (MDRotationBox*)ViewForIdentity(@"Rotation Box") setZRotation:rotZ show:NO ];
	}
	// List objects
	unsigned long objectsCount = 0;
	[ objects removeAllObjects ];
	fread(&objectsCount, sizeof(unsigned long), 1, file);
	for (int z = 0; z < objectsCount; z++)
	{
		MDObject* obj = [ [ MDObject alloc ] init ];
		
		unsigned long instIndex = 0;
		fread(&instIndex, sizeof(unsigned long), 1, file);
		if (instIndex < [ instances count ])
			[ obj setInstance:instances[instIndex] ];
		
		unsigned short nameLength = 0;
		fread(&nameLength, sizeof(unsigned short), 1, file);
		char* nameBuffer = (char*)malloc(nameLength + 1);
		fread(nameBuffer, 1, nameLength, file);
		nameBuffer[nameLength] = 0;
		[ obj setName:[ NSString stringWithFormat:@"%s", nameBuffer ] ];
		free(nameBuffer);
		nameBuffer = NULL;
		
		float tx = 0, ty = 0, tz = 0, sx = 0, sy = 0, sz = 0, ran = 0;
		MDVector3 ra;
		MDVector4 cm;
		//MDVector3 rp;
		fread(&tx, sizeof(float), 1, file);
		fread(&ty, sizeof(float), 1, file);
		fread(&tz, sizeof(float), 1, file);
		fread(&sx, sizeof(float), 1, file);
		fread(&sy, sizeof(float), 1, file);
		fread(&sz, sizeof(float), 1, file);
		fread(&ra.x, sizeof(float), 1, file);
		fread(&ra.y, sizeof(float), 1, file);
		fread(&ra.z, sizeof(float), 1, file);
		fread(&ran, sizeof(float), 1, file);
		fread(&cm.x, sizeof(float), 1, file);
		fread(&cm.y, sizeof(float), 1, file);
		fread(&cm.z, sizeof(float), 1, file);
		fread(&cm.w, sizeof(float), 1, file);
		obj.translateX = tx, obj.translateY = ty, obj.translateZ = tz, obj.scaleX = sx, obj.scaleY = sy, obj.scaleZ = sz, obj.rotateAxis = ra, obj.rotateAngle = ran, obj.colorMultiplier = cm; //obj.rotatePoint = rp;
		
		// Physics
		float mass = 0, restituion = 0, friction = 0, rfriction = 0;
		unsigned char phyType = 0, phyFlags = 0;
		fread(&mass, sizeof(float), 1, file);
		fread(&restituion, sizeof(float), 1, file);
		fread(&phyType, sizeof(unsigned char), 1, file);
		fread(&phyFlags, sizeof(unsigned char), 1, file);
		fread(&friction, sizeof(float), 1, file);
		fread(&rfriction, sizeof(float), 1, file);
		obj.mass = mass, obj.restitution = restituion, obj.physicsType = phyType, obj.flags = phyFlags, obj.friction = friction, obj.rollingFriction = rfriction;
		
		// Flags
		unsigned char shouldDraw = 0;
		fread(&shouldDraw, sizeof(unsigned char), 1, file);
		obj.shouldDraw = shouldDraw & 0x1;
		obj.shouldView = (shouldDraw >> 1) & 0x1;
		obj.isStatic = (shouldDraw >> 2) & 0x1;
		
		// Read object properties
		unsigned long oprop = 0;
		fread(&oprop, sizeof(unsigned long), 1, file);
		for (unsigned long t = 0; t < oprop; t++)
		{
			unsigned long length = 0;
			fread(&length, sizeof(unsigned long), 1, file);
			char* str = (char*)malloc(length + 1);
			fread(str, length, 1, file);
			str[length] = 0;
			NSString* key = @(str);
			free(str);
			fread(&length, sizeof(unsigned long), 1, file);
			str = (char*)malloc(length + 1);
			fread(str, length, 1, file);
			str[length] = 0;
			NSString* val = @(str);
			free(str);
			[ obj addProperty:val forKey:key ];
		}
		
		[ objects addObject:obj ];
	}
	
	// Other Objects
	unsigned long otherObjSize = 0;
	fread(&otherObjSize, sizeof(unsigned long), 1, file);
	[ otherObjects removeAllObjects ];
	unsigned long used = -1;
	for (int z = 0; z < otherObjSize; z++)
	{
		unsigned int realType = 0;
		fread(&realType, sizeof(realType), 1, file);
		if (realType == 1)
		{
			MDVector3 point, look;
			float orien = 0;
			BOOL show = 0, use = 0, sel = 0, looksel = 0;
			fread(&point, sizeof(point), 1, file);
			fread(&look, sizeof(look), 1, file);
			fread(&orien, sizeof(float), 1, file);
			fread(&show, 1, 1, file);
			fread(&use, 1, 1, file);
			if (use)
				used = z;
			fread(&sel, 1, 1, file);
			fread(&looksel, 1, 1, file);
			unsigned int nameSize = 0;
			fread(&nameSize, sizeof(unsigned int), 1, file);
			char* buffer = (char*)malloc(nameSize + 1);
			buffer[nameSize] = 0;
			fread(buffer, nameSize, 1, file);
			MDCamera* camera = [ [ MDCamera alloc ] init ];
			[ camera setName:[ NSString stringWithFormat:@"%s", buffer ] ];
			free(buffer);
			buffer = NULL;
			[ camera setMidPoint:point ];
			[ camera setLookPoint:look ];
			[ camera setOrientation:orien ];
			[ camera setShow:show ];
			[ camera setUse:use ];
			[ camera setSelected:sel ];
			[ camera setLookSelected:looksel ];
			[ camera setObj:[ [ MDObject alloc ] initWithObject:[ [ glWindow glView ] models ][0].obj ] ];
			[ camera.obj setMidPoint:point ];
			camera.instance = mdCube(look.x, look.y, look.z, 0.2, 0.2, 0.2);
			[ camera setLookObj:[ [ MDObject alloc ] initWithInstance:camera.instance ] ];
			[ otherObjects addObject:camera ];
		}
		else if (realType == 2)
		{
			MDVector3 point, look;
			MDVector4 ambient, diffuse, specular;
			float exp, cut, ccut, cat, linat, quadat;
			unsigned int type;
			BOOL enableShadows, selected, show;
			fread(&point, sizeof(point), 1, file);
			fread(&look, sizeof(look), 1, file);
			fread(&ambient, sizeof(ambient), 1, file);
			fread(&diffuse, sizeof(diffuse), 1, file);
			fread(&specular, sizeof(specular), 1, file);
			fread(&exp, sizeof(exp), 1, file);
			fread(&cut, sizeof(cut), 1, file);
			fread(&ccut, sizeof(ccut), 1, file);
			fread(&cat, sizeof(cat), 1, file);
			fread(&linat, sizeof(linat), 1, file);
			fread(&quadat, sizeof(quadat), 1, file);
			fread(&type, sizeof(type), 1, file);
			fread(&enableShadows, sizeof(enableShadows), 1, file);
			fread(&selected, sizeof(selected), 1, file);
			fread(&show, sizeof(show), 1, file);
			unsigned int nameSize = 0;
			fread(&nameSize, sizeof(unsigned int), 1, file);
			char* buffer = (char*)malloc(nameSize + 1);
			buffer[nameSize] = 0;
			fread(buffer, nameSize, 1, file);
			MDLight* light = [ [ MDLight alloc ] init ];
			[ light setName:[ NSString stringWithFormat:@"%s", buffer ] ];
			free(buffer);
			buffer = NULL;
			light.position = point, light.spotDirection = look;
			light.ambientColor = ambient, light.diffuseColor = diffuse, light.specularColor = specular;
			light.spotExp = exp, light.spotCut = cut, light.spotAngle = ccut, light.constAtt = cat, light.linAtt = linat, light.quadAtt = quadat;
			light.lightType = type, light.enableShadows = (enableShadows & 0x1), light.selected = selected, light.show = show, light.isStatic = (enableShadows >> 1) & 0x1;
			[ light setObj:[ [ MDObject alloc ] initWithObject:[ [ glWindow glView ] models ][type + 1].obj ] ];
			[ light.obj setMidPoint:point ];
			[ otherObjects addObject:light ];
			
			rebuildShaders = TRUE;
		}
		else if (realType == 3)
		{
			MDVector3 point, vel;
			MDVector4 start, end;
			float size;
			unsigned long number, life;
			unsigned int velType;
			BOOL selected, show;
			fread(&point, 1, sizeof(point), file);
			fread(&velType, 1, sizeof(velType), file);
			fread(&vel, 1, sizeof(vel), file);
			fread(&start, 1, sizeof(start), file);
			fread(&end, 1, sizeof(end), file);
			fread(&size, 1, sizeof(size), file);
			fread(&number, 1, sizeof(number), file);
			fread(&life, 1, sizeof(life), file);
			fread(&selected, sizeof(selected), 1, file);
			fread(&show, sizeof(show), 1, file);
			unsigned int nameSize;
			fread(&nameSize, sizeof(unsigned int), 1, file);
			char* buffer = (char*)malloc(nameSize + 1);
			fread(buffer, nameSize, 1, file);
			buffer[nameSize] = 0;
			
			MDParticleEngine* engine = [ [ MDParticleEngine alloc ] init ];
			[ engine setName:[ NSString stringWithFormat:@"%s", buffer ] ];
			[ engine setVelocities:vel ];
			[ engine setVelocityType:velType ];
			[ engine setPosition:point ];
			[ engine setStartColor:start ];
			[ engine setEndColor:end ];
			[ engine setParticleSize:size ];
			[ engine setNumberOfParticles:number ];
			[ engine setParticleLife:life ];
			[ engine setSelected:selected ];
			[ engine setShow:show ];
			[ otherObjects addObject:engine ];
			
			free(buffer);
			buffer = NULL;
		}
		else if (realType == 4)
		{
			std::vector<MDVector3> p;
			unsigned long numP;
			fread(&numP, 1, sizeof(unsigned long), file);
			for (unsigned long q = 0; q < numP; q++)
			{
				MDVector3 point;
				fread(&point, 1, sizeof(point), file);
				p.push_back(point);
			}
			BOOL selected, show;
			fread(&selected, sizeof(selected), 1, file);
			fread(&show, sizeof(show), 1, file);
			unsigned int nameSize;
			fread(&nameSize, sizeof(unsigned int), 1, file);
			char* buffer = (char*)malloc(nameSize + 1);
			fread(buffer, nameSize, 1, file);
			buffer[nameSize] = 0;
			
			MDCurve* curve = [ [ MDCurve alloc ] init ];
			[ curve setName:[ NSString stringWithFormat:@"%s", buffer ] ];
			[ curve setPoints:p ];
			[ curve setShow:show ];
			[ curve setSelected:selected ];
			[ otherObjects addObject:curve ];
			
			free(buffer);
			buffer = NULL;
		}
		else if (realType == 5)
		{
			MDVector3 position;
			fread(&position, sizeof(MDVector3), 1, file);
			
			float linAtt, quadAtt, minVol, maxVol, speed;
			fread(&linAtt, sizeof(float), 1, file);
			fread(&quadAtt, sizeof(float), 1, file);
			fread(&minVol, sizeof(float), 1, file);
			fread(&maxVol, sizeof(float), 1, file);
			fread(&speed, sizeof(float), 1, file);
			unsigned char flags;
			fread(&flags, sizeof(unsigned char), 1, file);
			
			BOOL selected, show;
			fread(&selected, sizeof(selected), 1, file);
			fread(&show, sizeof(show), 1, file);
			
			unsigned int fileSize;
			fread(&fileSize, sizeof(unsigned int), 1, file);
			char* buffer = (char*)malloc(fileSize + 1);
			fread(buffer, fileSize, 1, file);
			buffer[fileSize] = 0;
			
			unsigned int nameSize;
			fread(&nameSize, sizeof(unsigned int), 1, file);
			char* buffer2 = (char*)malloc(nameSize + 1);
			fread(buffer2, nameSize, 1, file);
			buffer[nameSize] = 0;
			
			MDSound* sound = [ [ MDSound alloc ] init ];
			[ sound setPosition:position ];
			[ sound setLinAtt:linAtt ];
			[ sound setQuadAtt:quadAtt ];
			[ sound setMinVolume:minVol ];
			[ sound setMaxVolume:maxVol ];
			[ sound setSpeed:speed ];
			[ sound setFlags:flags ];
			[ sound setSelected:selected ];
			[ sound setShow:show ];
			[ sound setFile:@(buffer) ];
			[ sound setName:@(buffer2) ];
			[ sound setObj:[ [ MDObject alloc ] initWithObject:[ [ glWindow glView ] models ][4].obj ] ];
			[ sound.obj setMidPoint:position ];

			[ otherObjects addObject:sound ];
			
			free(buffer);
			buffer = NULL;
			free(buffer2);
			buffer2 = NULL;
		}
	}
	if (used != -1)
	{
		[ otherObjects[used] setSelected:YES ];
		MDRotationBox* box = ViewForIdentity(@"Rotation Box");
		[ box setVisible:NO ];
	}
	
	// Selected
	unsigned long selectedSize = 0;
	fread(&selectedSize, sizeof(unsigned long), 1, file);
	[ selected clear ];
	for (int z = 0; z < selectedSize; z++)
	{
		unsigned long indexSel = 0;
		fread(&indexSel, sizeof(unsigned long), 1, file);
		if (currentMode == MD_OBJECT_MODE)
		{
			if ([ objects count ] > indexSel)
				[ selected addObject:objects[indexSel] ];
		}
	}
	// Other selected
	if (selectedSize == 0)
	{
		unsigned long otherSel = 0;
		fread(&otherSel, sizeof(unsigned long), 1, file);
		if (otherSel < [ otherObjects count ])
			[ otherObjects[otherSel] setSelected:YES ];
	}
	
	[ GLView calculateAlphaObjects ];
	// Update Textures
	[ [ glWindow glView ] loadNewTextures ];
	
	// Files
	/*IFNode* parent = [ [ IFNode alloc ] initParentWithTitle:[ workingDirectory lastPathComponent ] children:nil ];
	 unsigned long fileViewer = 0;
	 fread(&fileViewer, sizeof(unsigned long), 1, file);
	 for (int z = 0; z < fileViewer; z++)
	 {
		 unsigned long fileLength = 0;//[ string length ];
		 fread(&fileLength, sizeof(unsigned long), 1, file);
		 char* buffer = (char*)malloc(fileLength + 1);
		 buffer[fileLength] = 0;
		 fread(buffer, 1, fileLength, file);
		 NSString* string = [ NSString stringWithUTF8String:buffer ];
		 free(buffer);
		 buffer = NULL;
		 IFNode* node = [ [ IFNode alloc ] initLeafWithTitle:[ string lastPathComponent ] ];
		 [ node setDictionary:[ NSDictionary dictionaryWithObject:string forKey:@"Location" ] ];
		 [ parent addChild:node ];
		 [ node release ];
	 }
	 [ [ fileOutline rootNode ] addChild:parent ];*/
	
	fclose(file);
}

MDInstance* MDReadModel(NSString* path)
{
	FILE* file = fopen([ path UTF8String ], "r");
	
	MDInstance* instance = [ [ MDInstance alloc ] init ];
	
	unsigned int numMesh = 0;
	fread(&numMesh, sizeof(unsigned int), 1, file);
	for (unsigned long t = 0; t < numMesh; t++)
	{
		[ instance beginMesh ];
		MDVector4 color = MDVector4Create(1, 1, 1, 1);
		fread(&color.x, sizeof(float), 1, file);
		fread(&color.y, sizeof(float), 1, file);
		fread(&color.z, sizeof(float), 1, file);
		fread(&color.w, sizeof(float), 1, file);
		[ instance setColor:color ];
		unsigned long pointCount = 0;
		fread(&pointCount, sizeof(unsigned long), 1, file);
		for (unsigned long q = 0; q < pointCount; q++)
		{
			MDPoint* p = [ [ MDPoint alloc ] init ];
			float x = 0, y = 0, z = 0, normX = 0, normY = 0, normZ = 0, ux = 0, vy = 0;
			fread(&x, sizeof(float), 1, file);
			fread(&y, sizeof(float), 1, file);
			fread(&z, sizeof(float), 1, file);
			fread(&normX, sizeof(float), 1, file);
			fread(&normY, sizeof(float), 1, file);
			fread(&normZ, sizeof(float), 1, file);
			fread(&ux, sizeof(float), 1, file);
			fread(&vy, sizeof(float), 1, file);
			p.x = x, p.y = y, p.z = z, p.normalX = normX, p.normalY = normY, p.normalZ = normZ, p.textureCoordX = ux, p.textureCoordY = vy;
			
			[ instance addPoint:p ];
		}
		unsigned int indexNum = 0;
		fread(&indexNum, sizeof(unsigned int), 1, file);
		for (unsigned int q = 0; q < indexNum; q++)
		{
			unsigned int index = 0;
			fread(&index, sizeof(unsigned int), 1, file);
			[ instance addIndex:index ];
		}
		unsigned int texNum = 0;
		fread(&texNum, sizeof(unsigned int), 1, file);
		for (unsigned int q = 0; q < texNum; q++)
		{
			unsigned char type = 0;
			fread(&type, sizeof(unsigned char), 1, file);
			unsigned int head = 0;
			fread(&head, sizeof(unsigned int), 1, file);
			float size = 0;
			fread(&size, sizeof(float), 1, file);
			unsigned int len = 0;
			fread(&len, sizeof(unsigned int), 1, file);
			char* buffer = (char*)malloc(len + 1);
			fread(buffer, len, 1, file);
			buffer[len] = 0;
			[ instance addTexture:[ NSString stringWithFormat:@"%@/%s", [ path stringByDeletingLastPathComponent ], buffer ] withType:(MDTextureType)type withHead:head withSize:size ];
			free(buffer);
			buffer = NULL;
		}
		[ instance endMesh ];
	}
	
	unsigned long numProp = 0;
	fread(&numProp, sizeof(unsigned long), 1, file);
	for (int t = 0; t < numProp; t++)
	{
		unsigned long keyLength = 0;
		fread(&keyLength, sizeof(unsigned int), 1, file);
		char* buffer = (char*)malloc(keyLength + 1);
		fread(buffer, sizeof(char), keyLength, file);
		buffer[keyLength] = 0;
		NSString* key = @(buffer);
		free(buffer);
		unsigned long length = 0;
		fread(&length, sizeof(unsigned long), 1, file);
		buffer = (char*)malloc(length + 1);
		fread(buffer, sizeof(char), length, file);
		buffer[length] = 0;
		NSString* value = @(buffer);
		free(buffer);
		buffer = NULL;
		[ instance addProperty:value forKey:key ];
	}
	
	fclose(file);
	
	return instance;
}

void MDWriteModel(NSString* path, MDInstance* instance, MDObject* obj)
{
	FILE* file = fopen([ path UTF8String ], "w");
	unsigned int numMesh = (unsigned int)[ instance numberOfMeshes ];
	fwrite(&numMesh, sizeof(unsigned int), 1, file);
	for (unsigned long t = 0; t < numMesh; t++)
	{
		MDMesh* mesh = [ instance meshAtIndex:t ];
		MDVector4 color = [ mesh color ];
		fwrite(&color.x, sizeof(float), 1, file);
		fwrite(&color.y, sizeof(float), 1, file);
		fwrite(&color.z, sizeof(float), 1, file);
		fwrite(&color.w, sizeof(float), 1, file);
		unsigned long pointCount = [ mesh numberOfPoints ];
		fwrite(&pointCount, sizeof(unsigned long), 1, file);
		for (unsigned long q = 0; q < [ mesh numberOfPoints ]; q++)
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
			NSString* tex = [ texture path ];
			[ [ NSFileManager defaultManager ] copyItemAtPath:tex toPath:[ path stringByAppendingFormat:@"_%@", [ tex lastPathComponent ] ] error:nil ];
			tex = [ [ path stringByAppendingFormat:@"_%@", [ tex lastPathComponent ] ] lastPathComponent ];
			unsigned int len = (unsigned int)[ tex length ];
			fwrite(&len, sizeof(unsigned int), 1, file);
			fwrite([ tex UTF8String ], len, 1, file);
		}
	}
	
	NSDictionary* prop = [ obj properties ];
	NSArray* keys = [ prop allKeys ];
	unsigned long numProp = [ keys count ];
	fwrite(&numProp, sizeof(unsigned long), 1, file);
	for (int t = 0; t < [ keys count ]; t++)
	{
		NSString* value = prop[keys[t]];
		unsigned long keyLength = [ keys[t] length ];
		fwrite(&keyLength, sizeof(unsigned long), 1, file);
		fwrite([ keys[t] UTF8String ], sizeof(char), keyLength, file);
		unsigned long length = [ value length ];
		fwrite(&length, sizeof(unsigned long), 1, file);
		const char* buffer = [ value UTF8String ];
		fwrite(buffer, sizeof(char), length, file);
	}
	
	fclose(file);
}
