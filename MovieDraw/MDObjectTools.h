//
//  MDObjectTools.h
//  MovieDraw
//
//  Created by Neil on 7/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MDTypes.h"
#import "MDGUI.h"

// Object
MDRect BoundingBoxRotate(MDObject* obj);
MDRect BoundingBoxInstance(MDInstance* obj);
std::vector<MDVector3> MDRectToPoints(MDRect rect);
MDRect PointsToMDRect(std::vector<MDVector3> points);
std::vector<MDVector3> BoundingBox(MDObject* obj);
void DrawObjectTool(MDObject* obj, int object, float currentZ, unsigned int name, MDObject* parentObj, MDMatrix projection, MDMatrix modelView, unsigned int* locations);
void MouseDragged(float deltaX, float deltaY, int name, int object, id obj, float zpos, float xrot, float yrot, NSPoint mouse, int mode);
void MouseDown(int name, id obj, float xrot, float yrot, float zrot, float zpos, NSPoint mouse, int tool, int mode, MDObject* realObj);
void MouseUp(MDObject* obj);
MDVector3 RotateAxis(MDVector3 point, MDVector3 axis, float angle);
MDVector3 Rotate(MDVector3 point, MDVector3 around, float xrot, float yrot, float zrot);
MDVector3 RotateB(MDVector3 point, MDVector3 around, float xrot, float yrot, float zrot);
MDVector3 RotateX(MDVector3 point, MDVector3 around, float xrot);
MDVector3 RotateY(MDVector3 point, MDVector3 around, float yrot);
MDVector3 RotateZ(MDVector3 point, MDVector3 around, float zrot);
MDObject* ApplyTransformations(MDObject* obj);
MDObject* ApplyTransformationsTranslates(MDObject* obj2);
MDInstance* ApplyTransformationInstance(MDObject* obj);
MDInstance* ApplyTransformationInstanceTranslates(MDObject* obj);

void gluCube(float width, float height, float depth);
void gluSphere(float radius, unsigned int slices, unsigned int stacks);
void gluLine(MDVector3 p1, MDVector3 p2);
// TODO: disable these they don't work
MDInstance* mdCube(float x, float y, float z, float width, float height, float depth);
MDInstance* mdCircle(float x, float y, float z, float radiusX, float radiusY, float radiusZ, int slices);

float Volume(MDObject* obj);