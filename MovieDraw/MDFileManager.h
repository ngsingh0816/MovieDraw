//
//  MDFileManager.h
//  MovieDraw
//
//  Created by Neil on 1/12/14.
//  Copyright (c) 2014 Neil. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GLWindow.h"
#import "TableWindow.h"
#import "MDCodeView.h"
#import "OutlineWindow.h"

// Nodes
void MDWriteNodes(MDNode* node, FILE* file);
void MDReadNodes(MDNode* node, FILE* file, MDNode* parent);
MDNode* MDNodeForAnimationStep(MDNode* nodes, unsigned int step, unsigned int animation);

// Project
void MDSaveProject(BOOL pics, BOOL models, MDCodeView* editorView, GLWindow* glWindow, TableWindow* sceneTable, OutlineWindow* fileOutline);
void MDReadProject(BOOL proj, MDCodeView* editorView, GLWindow* glWindow, TableWindow* sceneTable, OutlineWindow* fileOutline);

// Models
MDInstance* MDReadModel(NSString* path);
void MDWriteModel(NSString* path, MDInstance* instance, MDObject* object);
