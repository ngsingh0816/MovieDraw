//
// This code produces a shape that can be created in MovieDraw.
// Function: MDObject* Shape(ThreePoint start, ThreePoint delta)
// Arguments: start - Initial point in space, delta - Change in x, y, and z in space.
// Return: An MDObject that is the new shape (this should include normals / faces).
//

#import <MovieDraw/MovieDraw.h>

MDObject* Shape(ThreePoint start, ThreePoint delta)
{
	MDObject* obj = [ [ MDObject alloc ] init ];
	
	float slicesX = 36;
	float slicesY = 36;
	float x = 0;//delta.x;
	float y =  0;//delta.y;
	float z = 0;//delta.z;
	float innerRadius = 5;
	float outerRadius = 0.4;
	for (float tx = 0; tx < slicesX; tx++)
	{
		float angleX1 = tx / slicesX * 2 * M_PI;
		float angleX2 = (tx + 1) / slicesX * 2 * M_PI;
		
		MDFace* face = [ [ MDFace alloc ] init ];
		[ face setDrawMode:GL_TRIANGLE_STRIP ];
		for (float ty = 0; ty <= slicesY; ty++)
		{
			float angleY = ty / slicesY * 2 * M_PI;
			float angleY2 = (ty + 1) / slicesY * 2 * M_PI;
			float trueY1 = cos(angleY);
			float trueY2 = cos(angleY2);
			float trueZ = sin(angleY);
			float trueZ2 = sin(angleY2);
			
			MDPoint* p = [ [ MDPoint alloc ] init ];
			ThreePoint truen = RotateY(MakeThreePoint(0, (trueY1 * 1), (trueZ * 1)), MakeThreePoint(0, 0, 0), angleX1 / M_PI * 180);				[ p setNormalX:truen.x ];
			[ p setNormalY:truen.y ];
			[ p setNormalZ:truen.z ];
			ThreePoint trueP = RotateY(MakeThreePoint(0, (trueY1 * outerRadius), innerRadius + (trueZ * outerRadius)), MakeThreePoint(0, 0, 0), angleX1 / M_PI * 180);
			[ p setX:trueP.x Y:trueP.y Z:trueP.z ];
			[ face addPoint:p ];
			[ p release ];
			
			p = [ [ MDPoint alloc ] init ];
			truen = RotateY(MakeThreePoint(0, (trueY2 * 1), (trueZ2 * 1)), MakeThreePoint(0, 0, 0), angleX2 / M_PI * 180);		
			[ p setNormalX:truen.x ];
			[ p setNormalY:truen.y ];
			[ p setNormalZ:truen.z ];
			trueP = RotateY(MakeThreePoint(0, (trueY2 * outerRadius), innerRadius + (trueZ2 * outerRadius)), MakeThreePoint(0, 0, 0), angleX2 / M_PI * 180);
			[ p setX:trueP.x Y:trueP.y Z:trueP.z ];
			[ face addPoint:p ];
			[ p release ];
			
		}
		[ obj addFace:face ];
		[ face release ];
	}
	
	obj.objectColors[0].red = 0.7;
	obj.objectColors[0].alpha = 1;
	obj.objectColors[1].blue = 0.7;
	obj.objectColors[1].alpha = 1;
	obj.objectColors[2].red = 0.7;
	obj.objectColors[2].green = 0.7;
	obj.objectColors[2].alpha = 1;
	
	[ obj setMidColor:MakeMDColor(1, 0, 0, 1) ];
	
	return obj;
}

