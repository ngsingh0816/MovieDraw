//
//  MDImporter.m
//  MovieDraw
//
//  Created by Neil on 3/22/13.
//  Copyright (c) 2013 Neil. All rights reserved.
//


// Remember to put the license for this

#import "MDImporter.h"
#import "MDObjectTools.h"
#include "assimp/Importer.hpp"		// C++ importer interface
#include "assimp/scene.h"			// Output data structure
#include "assimp/postprocess.h"		// Post processing flags

NSArray* ImportAvailableFileTypes()
{
	return @[@"dae", @"blend", @"3ds", @"ase", @"obj", @"ifc", @"xgl", @"zgl", @"ply", @"dxf", @"lwo", @"lws", @"lxo", @"stl", @"x", @"ac", @"ms3d", @"cob", @"scn", @"bvh", @"csm", @"xml", @"irrmesh", @"irr", @"md1", @"md2", @"md3", @"md5mesh", @"pk3", @"mdc", @"smd", @"vta", @"m3", @"3d", @"b3d", @"q3d", @"q3s", @"nff", @"off", @"raw", @"ter", @"mdl", @"hmp", @"ndo"];
}

NSArray* ExportAvailableFileTypes()
{
	return @[@"dae", @"obj", @"stl", @"ply"];
}

MDMatrix MatrixFromAIMatrix(aiMatrix4x4 mat2)
{
	aiMatrix4x4 mat = mat2;
	MDMatrix matrix;
	matrix.data[0] = mat.a1, matrix.data[1] = mat.a2, matrix.data[2] = mat.a3, matrix.data[3] = mat.a4;
	matrix.data[4] = mat.b1, matrix.data[5] = mat.b2, matrix.data[6] = mat.b3, matrix.data[7] = mat.b4;
	matrix.data[8] = mat.c1, matrix.data[9] = mat.c2, matrix.data[10] = mat.c3, matrix.data[11] = mat.c4;
	matrix.data[12] = mat.d1, matrix.data[13] = mat.d2, matrix.data[14] = mat.d3, matrix.data[15] = mat.d4;
	return MDMatrixTranspose(matrix);
}

unsigned int FindRealMeshNumber(unsigned int mesh, const aiScene* scene)
{
	unsigned int real = mesh;
	for (unsigned long z = 0; z < mesh; z++)
	{
		if (scene->mMeshes[z]->mPrimitiveTypes != aiPrimitiveType_TRIANGLE || !scene->mMeshes[z]->mVertices)
			real--;
	}
	return real;
}

void FillNode(MDNode* node, aiNode* sceneNode, MDInstance* obj, MDNode* parent, const aiScene* scene)
{
	[ node setTransformation:MatrixFromAIMatrix(sceneNode->mTransformation) ];
	[ node setParent:parent ];
	
	// Check if it is a bone
	aiString name = sceneNode->mName;
	unsigned int real = 0;
	for (unsigned long z = 0; z < scene->mNumMeshes; z++)
	{
		if (scene->mMeshes[z]->mPrimitiveTypes != aiPrimitiveType_TRIANGLE || !scene->mMeshes[z]->mVertices)
		{
			real++;
			continue;
		}
		//BOOL found = FALSE;
		for (unsigned long y = 0; y < scene->mMeshes[z]->mNumBones; y++)
		{
			aiBone* bone = scene->mMeshes[z]->mBones[y];
			if (bone->mName == name)
			{
				[ node setIsBone:YES ];
				[ node addMeshIndex:(unsigned int)(z - real) boneIndex:(unsigned int)y ];
				//[ node setMeshIndex:z - real ];
				//[ node setBoneIndex:y ];
				//found = TRUE;
				//break;
			}
		}
		//if (found)
		//	break;
	}
	
	for (unsigned long z = 0; z < sceneNode->mNumMeshes; z++)
	{
		unsigned int meshNum = sceneNode->mMeshes[z];
		if (scene->mMeshes[meshNum]->mPrimitiveTypes == aiPrimitiveType_TRIANGLE && scene->mMeshes[z]->mVertices)
			[ node addMesh:FindRealMeshNumber(sceneNode->mMeshes[z], scene) ];
	}
	
	for (unsigned long z = 0; z < sceneNode->mNumChildren; z++)
	{
		MDNode* child = [ [ MDNode alloc ] init ];
		FillNode(child, sceneNode->mChildren[z], obj, node, scene);
		[ node addChild:child ];
	}
}

MDNode* FindNodeNamed(MDNode* node, aiNode* sceneNode, aiString nodeName)
{
	// If it's this node, return it
	if (sceneNode->mName == nodeName)
		return node;
	// Otherwise check all of its children
	for (unsigned long z = 0; z < [ [ node children ] count ]; z++)
	{
		MDNode* ret = FindNodeNamed([ node children ][z], sceneNode->mChildren[z], nodeName);
		if (ret)
			return ret;
	}
	
	return nil;
}

void CacheAnimationStep(MDNode* node, MDAnimation* animation)
{
	for (unsigned long z = 0; z < [ animation steps ]->size(); z++)
	{
		if (node == [ animation steps ]->at(z).node)
		{
			[ node addAnimationStep:z ];
			break;
		}
	}
	
	for (unsigned long z = 0; z < [ [ node children ] count ]; z++)
		CacheAnimationStep([ node children ][z], animation);
}

MDMatrix TransformMatrixForMeshIndex(unsigned int meshIndex, MDMatrix matrix, aiNode* node, BOOL* found)
{
	matrix = matrix * MatrixFromAIMatrix(node->mTransformation);
	for (unsigned long z = 0; z < node->mNumMeshes; z++)
	{
		if (meshIndex == node->mMeshes[z])
		{
			if (found)
				*found = TRUE;
			return matrix;
		}
	}
	
	BOOL didFind = FALSE;
	for (unsigned long z = 0; z < node->mNumChildren; z++)
	{
		MDMatrix matrix2 = TransformMatrixForMeshIndex(meshIndex, matrix, node->mChildren[z], &didFind);
		if (didFind)
		{
			if (found)
				*found = TRUE;
			return matrix2;
		}
	}
	
	if (found)
		*found = FALSE;
	return MDMatrixIdentity();
}

MDInstance* ObjectFromFile(NSString* file)
{
	// Create an instance of the Importer class
	Assimp::Importer importer;
	
	// Optimize Graph optimizes the nodes, but it may lose data, not sure yet
	const aiScene* scene = importer.ReadFile( [ file UTF8String ], (aiProcessPreset_TargetRealtime_MaxQuality | aiProcess_TransformUVCoords));
	
	// If the import failed, report it
	if( !scene)
	{
		NSRunAlertPanel(@"Importing Error", @"%s", @"Ok", nil, nil, importer.GetErrorString());
		return nil;
	}
	// Now we can access the file's contents.
	
	MDInstance* obj = [ [ MDInstance alloc ] init ];
	
	for (unsigned long z = 0; z < scene->mNumMeshes; z++)
	{
		if (scene->mMeshes[z]->mPrimitiveTypes != aiPrimitiveType_TRIANGLE)
			continue;
		
		aiVector3D* verticies = scene->mMeshes[z]->mVertices;
		aiVector3D* normals = scene->mMeshes[z]->mNormals;
		aiVector3D* texCoords = scene->mMeshes[z]->mTextureCoords[0];
		//aiColor4D* colors = scene->mMeshes[z]->mColors[0];
		unsigned int matIndex = scene->mMeshes[z]->mMaterialIndex;
		
		aiMaterial* material = NULL;
		aiColor4D diffuse;
		if (matIndex < scene->mNumMaterials)
		{
			material = scene->mMaterials[matIndex];
			aiGetMaterialColor(material, AI_MATKEY_COLOR_DIFFUSE, &diffuse);
		}

		if (!verticies)
			continue;
		
		NSMutableArray* texturePaths = [ NSMutableArray array ];
		NSMutableArray* textureTypes = [ NSMutableArray array ];
		if (material)
		{
			aiTextureType aiTypes[] = { aiTextureType_DIFFUSE, aiTextureType_NORMALS };
			MDTextureType mdTypes[] = { MD_TEXTURE_DIFFUSE, MD_TEXTURE_BUMP };
			unsigned long numOfTypes = 2;
			
			for (unsigned long q = 0; q < numOfTypes; q++)
			{
				unsigned int numTextures = material->GetTextureCount(aiTypes[q]);
				for (unsigned int t = 0; t < numTextures; t++)
				{
					aiString path;
					material->GetTexture(aiTypes[q], t, &path);
					// TODO: copy texture to project path
					NSMutableString* realPath = [ [ NSMutableString alloc ] initWithFormat:@"%s", path.C_Str() ];
					if (!([ realPath hasPrefix:@"\\" ] || [ realPath hasPrefix:@"/" ] || [ realPath hasPrefix:@"." ]))
					{
						[ realPath insertString:[ [ file stringByDeletingLastPathComponent ] stringByAppendingString:@"/" ] atIndex:0 ];
					}
					else
					{
						[ realPath replaceOccurrencesOfString:@"\\" withString:@"/" options:0 range:NSMakeRange(0, [ realPath length ]) ];
						while ([ realPath hasPrefix:@"/" ])
							[ realPath deleteCharactersInRange:NSMakeRange(0, 1) ];
						NSString* replace = file;
						unsigned int amount = 0;
						while ([ [ realPath substringFromIndex:amount ] hasPrefix:@"." ])
						{
							replace = [ replace stringByDeletingLastPathComponent ];
							amount++;
						}
						if (amount != 0)
							[ realPath replaceCharactersInRange:NSMakeRange(0, amount) withString:replace ];
					}
					[ texturePaths addObject:realPath ];
					[ textureTypes addObject:@((unsigned int)mdTypes[q]) ];
				}
			}
		}
		
		MDInstance* face = obj;
		
		[ face beginMesh ];
		MDMatrix transformMatrix = TransformMatrixForMeshIndex((unsigned int)z, MDMatrixIdentity(), scene->mRootNode, NULL);
		for (unsigned long q = 0; q < scene->mMeshes[z]->mNumVertices; q++)
		{
			unsigned long vertIndex = q;
			if (vertIndex >= scene->mMeshes[z]->mNumVertices)
				continue;
			
			MDPoint* p = [ [ MDPoint alloc ] init ];
			
			MDVector3 realVert = MDMatrixMultiply(transformMatrix, verticies[vertIndex].x, verticies[vertIndex].y, verticies[vertIndex].z, 1).GetXYZ();
			[ p setPosition:realVert ];
			if (normals)
			{
				MDVector3 realNorm = MDMatrixMultiply(transformMatrix, normals[vertIndex].x, normals[vertIndex].y, normals[vertIndex].z, 0).GetXYZ();
				[ p setNormal:realNorm ];
			}
			if (texCoords)
			{
				// Only 2D textures for now
				[ p setTextureCoordX:texCoords[vertIndex].x ];
				[ p setTextureCoordY:texCoords[vertIndex].y ];
			}
			/*[ p setRed:0.3 ];
			[ p setGreen:0.3 ];
			[ p setBlue:0.3 ];
			[ p setAlpha:1 ];
			if (material)
			{
				[ p setRed:diffuse.r ];
				[ p setGreen:diffuse.g ];
				[ p setBlue:diffuse.b ];
				[ p setAlpha:diffuse.a ];
			}
			if (colors)
			{
				[ p setRed:colors[vertIndex].r * p.red ];
				[ p setGreen:colors[vertIndex].g  * p.green];
				[ p setBlue:colors[vertIndex].b * p.blue ];
				[ p setAlpha:colors[vertIndex].a * p.alpha ];
			}*/
			
			[ face addPoint:p ];
		}
		
		[ face setTransformMatrix:transformMatrix ];
		MDMatrix inverseTransform = MDMatrixInverse(transformMatrix);
		// Indices
		for (unsigned long y = 0; y < scene->mMeshes[z]->mNumFaces; y++)
		{
			for (unsigned long q = 0; q < scene->mMeshes[z]->mFaces[y].mNumIndices; q++)
				[ face addIndex:scene->mMeshes[z]->mFaces[y].mIndices[q] ];
		}
		// Bones
		for (unsigned long y = 0; y < scene->mMeshes[z]->mNumBones; y++)
		{
			aiBone* bone = scene->mMeshes[z]->mBones[y];
			NSMutableArray* weights = [ [ NSMutableArray alloc ] init ];
			for (unsigned long q = 0; q < bone->mNumWeights; q++)
			{
				MDVertexWeight* weight = [ [ MDVertexWeight alloc ] initWithVeretx:bone->mWeights[q].mVertexId withWeight:bone->mWeights[q].mWeight ];
				[ weights addObject:weight ];
			}
			[ face addBone:weights withMatrix:MatrixFromAIMatrix(bone->mOffsetMatrix) * inverseTransform ];
		}
		// Textures
		for (unsigned long y = 0; y < [ texturePaths count ]; y++)
			[ face addTexture:texturePaths[y] withType:(MDTextureType)[ textureTypes[y] unsignedIntValue ] ];
		// Materials
		if (material)
			[ face setColor:MDVector4Create(diffuse.r, diffuse.g, diffuse.b, diffuse.a) ];
		else
			[ face setColor:MDVector4Create(0.3, 0.3, 0.3, 1.0) ];
		[ face endMesh ];
	}
	
	[ obj setMidPoint:MDVector3Create(0, 0, 0) ];
	MDRect rect = BoundingBoxInstance(obj);
	float scale = 1;
	if (rect.width > 10 || rect.height > 10 || rect.depth > 10)
	{
		float biggest = rect.width;
		if (biggest < rect.height)
			biggest = rect.height;
		if (biggest < rect.depth)
			biggest = rect.depth;
		if (biggest == 0)
			scale = 1;
		else
			scale = 10.0 / biggest;
	}
	[ obj setScale:MDVector3Create(scale, scale, scale) ];
	
	// Nodes
	MDNode* rootNode = [ [ MDNode alloc ] init ];
	FillNode(rootNode, scene->mRootNode, obj, nil, scene);
	[ obj setRootNode:rootNode ];
	
	// Animations
	for (unsigned long z = 0; z < scene->mNumAnimations; z++)
	{
		aiAnimation* anim = scene->mAnimations[z];
		float ticksPerSec = anim->mTicksPerSecond;
		if (ticksPerSec == 0)
			ticksPerSec = 25;
		MDAnimation* animation = [ [ MDAnimation alloc ] init ];
		// TODO: check if this name is already taken
		if (anim->mName.length != 0)
			[ animation setName:@(anim->mName.C_Str()) ];
		else
			[ animation setName:@"Unnamed Animation" ];
		[ animation setDuration:anim->mDuration / ticksPerSec ];
		
		std::vector<MDAnimationStep>steps;
		steps.resize(anim->mNumChannels);
		for (unsigned long q = 0; q < anim->mNumChannels; q++)
		{
			aiNodeAnim* nodeAnim = anim->mChannels[q];
			MDAnimationStep step;
			memset(&step, 0, sizeof(MDAnimationStep));
			
			step.node = FindNodeNamed([ obj rootNode ], scene->mRootNode, nodeAnim->mNodeName);
			// Position keys
			for (unsigned long t = 0; t < nodeAnim->mNumPositionKeys; t++)
			{
				float time = nodeAnim->mPositionKeys[t].mTime / ticksPerSec;
				aiVector3D pos = nodeAnim->mPositionKeys[t].mValue;
				step.positions.push_back(MDVector3Create(pos.x, pos.y, pos.z));
				step.positionTimes.push_back(time);
			}
			
			// Rotation keys
			for (unsigned long t = 0; t < nodeAnim->mNumRotationKeys; t++)
			{
				float time = nodeAnim->mRotationKeys[t].mTime / ticksPerSec;
				aiQuaternion rot = nodeAnim->mRotationKeys[t].mValue;
				step.rotations.push_back(MDVector4Create(rot.x, rot.y, rot.z, rot.w));
				step.rotateTimes.push_back(time);
			}
			
			// Scaling keys
			for (unsigned long t = 0; t < nodeAnim->mNumScalingKeys; t++)
			{
				float time = nodeAnim->mScalingKeys[t].mTime / ticksPerSec;
				aiVector3D scale = nodeAnim->mScalingKeys[t].mValue;
				step.scalings.push_back(MDVector3Create(scale.x, scale.y, scale.z));
				step.scaleTimes.push_back(time);
			}
			
			steps[q] = step;
		}
		[ animation setSteps:steps ];
		CacheAnimationStep([ obj rootNode ], animation);
		
		[ obj addAnimation:animation ];
	}
	
	[ obj setupVBO ];
	
	// We're done. Everything will be cleaned up by the importer destructor
	return obj;
}