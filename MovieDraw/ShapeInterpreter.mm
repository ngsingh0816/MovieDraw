//
//  ShapeInterpreter.mm
//  MovieDraw
//
//  Created by Neil Singh on 8/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ShapeInterpreter.h"
#import "MDObjectTools.h"

MDVector3 currentNormal;
MDVector3 currentTexCoord;
std::vector<double> regs;
MDFace* currentFace = nil;
BOOL needsTwo = YES;

std::vector<Variable> ShapeVariables(NSString* settings)
{
	FILE* sfile = fopen([ settings UTF8String ], "r");
	fseek(sfile, 0, SEEK_END);
	unsigned long size = ftell(sfile);
	rewind(sfile);
	char* data = (char*)malloc(size + 1);
	memset(data, 0, size + 1);
	fread(data, 1, size + 1, sfile);
	fclose(sfile);
	NSMutableString* str = [ [ NSMutableString alloc ] initWithUTF8String:(const char*)data ];
	NSArray* lines = [ str componentsSeparatedByString:@";" ];
	NSString* end = [ [ lines lastObject ] substringFromIndex:NSMaxRange([ [ lines lastObject ] rangeOfString:@"@end\n" ]) ];
	[ str release ];
	ReleaseShapeSettings();
	OpenValues(end);
	free(data);
	data = NULL;
	
	std::vector<Variable> ret;
	for (unsigned long z = 0; z < variables.size(); z++)
	{
		Variable var;
		var.obj = variables[z].obj;
		var.name = [ NSString stringWithString:variables[z].name ];
		var.objClass = variables[z].objClass;
		ret.push_back(var);
	}
	
	ReleaseShapeSettings();
	
	return ret;
}

void InterpretShape(NSString* path, NSString* settings, NSMutableArray* obj, MDVector3 origin, MDVector3 tSize)
{
	FILE* sfile = fopen([ settings UTF8String ], "r");
	fseek(sfile, 0, SEEK_END);
	unsigned long size = ftell(sfile);
	rewind(sfile);
	char* data = (char*)malloc(size + 1);
	memset(data, 0, size + 1);
	fread(data, 1, size + 1, sfile);
	fclose(sfile);
	NSMutableString* str = [ [ NSMutableString alloc ] initWithUTF8String:(const char*)data ];
	NSArray* lines = [ str componentsSeparatedByString:@";" ];
	NSString* end = [ [ lines lastObject ] substringFromIndex:NSMaxRange([ [ lines lastObject ] rangeOfString:@"@end\n" ]) ];
	[ str release ];
	ReleaseShapeSettings();
	OpenValues(end);
	free(data);
	data = NULL;
	
	currentNormal = MDVector3Create(0, 0, 0);
	currentTexCoord = MDVector3Create(0, 0, 0);
	needsTwo = YES;
	
	regs.clear();
	[ obj removeAllObjects ];
	regs.push_back(tSize.x);
	regs.push_back(tSize.y);
	regs.push_back(tSize.z);
	
	FILE* file = fopen([ path UTF8String ], "r");
	if (!file)
		return;
	fseek(file, 0, SEEK_END);
	size = ftell(file);
	rewind(file);
	unsigned char* buffer = (unsigned char*)malloc(size);
	fread(buffer, 1, size, file);
	for (unsigned long pc = 0; pc < size;)
		Execute((unsigned int)buffer[pc], &pc, obj, buffer, origin);
	free(buffer);
	buffer = NULL;
	
	/*int faces = 0;
	 fscanf(file, "%i\n", &faces);
	 for (int z = 0; z < faces; z++)
	 {
		int vert = 0, mode = 0;
		float xn = 0, yn = 0, zn = 0;
		fscanf(file, "%i %i %f %f %f\n", &vert, &mode, &xn, &yn, &zn);
		MDFace* face = [ [ MDFace alloc ] init ];
		face.drawMode = mode;
		std::vector<NSMutableString*> sh;
		for (int y = 0; y < vert; y++)
		{
	 // Show how many points there are
	 MDPoint* p = [ [ MDPoint alloc ] init ];
	 [ [ face points ] addObject:p ];
	 [ p release ];
	 
	 char* px = (char*)malloc(24);
	 char* py = (char*)malloc(24);
	 char* pz = (char*)malloc(24);
	 fscanf(file, "%s %s %s\n", px, py, pz);
	 sh.push_back([ [ NSMutableString alloc ] initWithFormat:@"%s", px ]);
	 sh.push_back([ [ NSMutableString alloc ] initWithFormat:@"%s", py ]);
	 sh.push_back([ [ NSMutableString alloc ] initWithFormat:@"%s", pz ]);
	 free(px);
	 px = NULL;
	 free(py);
	 py = NULL;
	 free(pz);
	 pz = NULL;
		}
		[ face setPointNormals:xn y:yn z:zn ];
		
		for (int z = 0; z < variables.size(); z++)
		{
	 if (variables[z].objClass)
	 continue;
	 double* ret = (double*)&variables[z].obj;
	 if (!variables[z].name)
	 continue;
	 for (int y = 0; y < sh.size(); y++)
	 {
	 [ sh[y] replaceOccurrencesOfString:variables[z].name withString:[ NSString stringWithFormat:@"%f", *ret ] options:0 range:NSMakeRange(0, [ sh[y] length ]) ];
	 }
		}
		
		[ [ obj faces ] addObject:face ];
		[ face release ];
		shape.push_back(sh);
	 }
	 fclose(file);*/
	
	ReleaseShapeSettings();
}

double ReadDouble(unsigned char* buffer, unsigned long* pc)
{
	char bytes[8];
	for (int z = 0; z < 8; z++)
		bytes[z] = buffer[(*pc)++];
	double* x = (double*)bytes;
	return *x;
}

unsigned int ReadInt(unsigned char* buffer, unsigned long* pc)
{
	char bytes[sizeof(unsigned int)];
	for (int z = 0; z < sizeof(unsigned int); z++)
		bytes[z] = buffer[(*pc)++];
	unsigned int* x = (unsigned int*)bytes;
	return *x;
}

BOOL RequiresTwoMouseClicks()
{
	return needsTwo;
}

void Execute(unsigned int opcode, unsigned long* pc, NSMutableArray* obj, unsigned char* buffer, MDVector3 origin)
{
	(*pc)++;
	switch (opcode)
	{
			// Begin Face
		case 0x01:
		{
			if (currentFace)
				[ currentFace release ];
			currentFace = [ [ MDFace alloc ] init ];
			unsigned char drawMode = buffer[(*pc)++];
			[ currentFace setDrawMode:drawMode ];
			break;
		}
			// End Face
		case 0x02:
		{
			[ obj addObject:currentFace ];
			if (currentFace)
				[ currentFace release ];
			currentFace = nil;
			break;
		}
			// Load Reg (0 - 2 are x, y, z)
		case 0x03:
		{
			unsigned char reg = buffer[(*pc)++];
			double value = ReadDouble(buffer, pc);
			regs[reg] = value;
			break;
		}
			// Push Reg Back
		case 0x04:
		{
			double value = ReadDouble(buffer, pc);
			regs.push_back(value);
			break;
		}
			// Delete Reg
		case 0x05:
		{
			unsigned char reg = buffer[(*pc)++];
			regs.erase(regs.begin() + reg);
			break;
		}
			// Load Reg From Variable
		case 0x06:
		{
			unsigned char reg = buffer[(*pc)++];
			unsigned char var = buffer[(*pc)++];
			if (var > variables.size())
				break;
			double* ret = (double*)&variables[var].obj;
			regs[reg] = *ret;
			break;
		}
			// Load Normal
		case 0x07:
		{
			unsigned char reg1 = buffer[(*pc)++];
			unsigned char reg2 = buffer[(*pc)++];
			unsigned char reg3 = buffer[(*pc)++];
			currentNormal = MDVector3Create(regs[reg1], regs[reg2], regs[reg3]);
			break;
		}
			// Add Point
		case 0x08:
		{
			unsigned char reg1 = buffer[(*pc)++];
			unsigned char reg2 = buffer[(*pc)++];
			unsigned char reg3 = buffer[(*pc)++];
			MDPoint* p = [ [ MDPoint alloc ] init ];
			[ p setX:regs[reg1] + origin.x ];
			[ p setY:regs[reg2] + origin.y ];
			[ p setZ:regs[reg3] + origin.z ];
			[ p setNormalX:currentNormal.x ];
			[ p setNormalY:currentNormal.y ];
			[ p setNormalZ:currentNormal.z ];
			[ p setTextureCoordX:currentTexCoord.x ];
			[ p setTextureCoordY:currentTexCoord.y ];
			/*[ p setRed:0.3 ];
			 [ p setGreen:0.3 ];
			 [ p setBlue:0.3 ];
			 [ p setAlpha:1 ];*/
			[ currentFace addPoint:p ];
			[ p release ];
			break;
		}
			// Add
		case 0x09:
		{
			unsigned char store = buffer[(*pc)++];
			unsigned char reg1 = buffer[(*pc)++];
			unsigned char reg2 = buffer[(*pc)++];
			regs[store] = regs[reg1] + regs[reg2];
			break;
		}
			// Subtract
		case 0x0A:
		{
			unsigned char store = buffer[(*pc)++];
			unsigned char reg1 = buffer[(*pc)++];
			unsigned char reg2 = buffer[(*pc)++];
			regs[store] = regs[reg1] - regs[reg2];
			break;
		}
			// Multiply
		case 0x0B:
		{
			unsigned char store = buffer[(*pc)++];
			unsigned char reg1 = buffer[(*pc)++];
			unsigned char reg2 = buffer[(*pc)++];
			regs[store] = regs[reg1] * regs[reg2];
			break;
		}
			// Divide
		case 0x0C:
		{
			unsigned char store = buffer[(*pc)++];
			unsigned char reg1 = buffer[(*pc)++];
			unsigned char reg2 = buffer[(*pc)++];
			regs[store] = regs[reg1] / regs[reg2];
			break;
		}
			// Set requires 2 mouse clicks
		case 0x0D:
		{
			unsigned char does = buffer[(*pc)++];
			needsTwo = does;
			break;
		}
			// Jump
		case 0x0E:
		{
			unsigned int location = ReadInt(buffer, pc);
			*pc = location;
			break;
		}
			// Jump If Equal
		case 0x0F:
		{
			unsigned int location = ReadInt(buffer, pc);
			unsigned char reg1 = buffer[(*pc)++];
			unsigned char reg2 = buffer[(*pc)++];
			if (regs[reg1] == regs[reg2])
				*pc = location;
			break;
		}
			// Jump If Not Equal
		case 0x10:
		{
			unsigned int location = ReadInt(buffer, pc);
			unsigned char reg1 = buffer[(*pc)++];
			unsigned char reg2 = buffer[(*pc)++];
			if (regs[reg1] != regs[reg2])
				*pc = location;
			break;
		}
			// Jump If Greater Than
		case 0x11:
		{
			unsigned int location = ReadInt(buffer, pc);
			unsigned char reg1 = buffer[(*pc)++];
			unsigned char reg2 = buffer[(*pc)++];
			if (regs[reg1] > regs[reg2])
				*pc = location;
			break;
		}
			// Jump If Less Than
		case 0x12:
		{
			unsigned int location = ReadInt(buffer, pc);
			unsigned char reg1 = buffer[(*pc)++];
			unsigned char reg2 = buffer[(*pc)++];
			if (regs[reg1] < regs[reg2])
				*pc = location;
			break;
		}
			// Jump If Greater Than or Equal To
		case 0x13:
		{
			unsigned int location = ReadInt(buffer, pc);
			unsigned char reg1 = buffer[(*pc)++];
			unsigned char reg2 = buffer[(*pc)++];
			if (regs[reg1] >= regs[reg2])
				*pc = location;
			break;
		}
			// Jump If Less Than or Equal To
		case 0x14:
		{
			unsigned int location = ReadInt(buffer, pc);
			unsigned char reg1 = buffer[(*pc)++];
			unsigned char reg2 = buffer[(*pc)++];
			if (regs[reg1] <= regs[reg2])
				*pc = location;
			break;
		}
			// Cos
		case 0x15:
		{
			unsigned char store = buffer[(*pc)++];
			unsigned char reg1 = buffer[(*pc)++];
			regs[store] = cos(regs[reg1] / 180.0 * M_PI);
			break;
		}
			// Sin
		case 0x16:
		{
			unsigned char store = buffer[(*pc)++];
			unsigned char reg1 = buffer[(*pc)++];
			regs[store] = sin(regs[reg1] / 180.0 * M_PI);
			break;
		}
			// Sqrt
		case 0x17:
		{
			unsigned char store = buffer[(*pc)++];
			unsigned char reg1 = buffer[(*pc)++];
			regs[store] = sqrt(regs[reg1]);
			break;
			break;
		}
			// RotateX
		case 0x18:
		{
			unsigned char storex = buffer[(*pc)++];
			unsigned char storey = buffer[(*pc)++];
			unsigned char storez = buffer[(*pc)++];
			unsigned char xreg = buffer[(*pc)++];
			unsigned char yreg = buffer[(*pc)++];
			unsigned char zreg = buffer[(*pc)++];
			unsigned char rot = buffer[(*pc)++];
			MDVector3 point = RotateX(MDVector3Create(regs[xreg], regs[yreg], regs[zreg]), MDVector3Create(0, 0, 0), regs[rot]);
			regs[storex] = point.x;
			regs[storey] = point.y;
			regs[storez] = point.z;
			break;
		}
			// RotateY
		case 0x19:
		{
			unsigned char storex = buffer[(*pc)++];
			unsigned char storey = buffer[(*pc)++];
			unsigned char storez = buffer[(*pc)++];
			unsigned char xreg = buffer[(*pc)++];
			unsigned char yreg = buffer[(*pc)++];
			unsigned char zreg = buffer[(*pc)++];
			unsigned char rot = buffer[(*pc)++];
			MDVector3 point = RotateY(MDVector3Create(regs[xreg], regs[yreg], regs[zreg]), MDVector3Create(0, 0, 0), regs[rot]);
			regs[storex] = point.x;
			regs[storey] = point.y;
			regs[storez] = point.z;
			break;
		}
			// RotateZ
		case 0x1A:
		{
			unsigned char storex = buffer[(*pc)++];
			unsigned char storey = buffer[(*pc)++];
			unsigned char storez = buffer[(*pc)++];
			unsigned char xreg = buffer[(*pc)++];
			unsigned char yreg = buffer[(*pc)++];
			unsigned char zreg = buffer[(*pc)++];
			unsigned char rot = buffer[(*pc)++];
			MDVector3 point = RotateZ(MDVector3Create(regs[xreg], regs[yreg], regs[zreg]), MDVector3Create(0, 0, 0), regs[rot]);
			regs[storex] = point.x;
			regs[storey] = point.y;
			regs[storez] = point.z;
			break;
		}
			// Begin Face Variable
		case 0x1B:
		{
			if (currentFace)
				[ currentFace release ];
			currentFace = [ [ MDFace alloc ] init ];
			unsigned char reg = buffer[(*pc)++];
			[ currentFace setDrawMode:regs[reg] ];
			break;
		}
			// Load Texture Coordinate
		case 0x1C:
		{
			unsigned char reg1 = buffer[(*pc)++];
			unsigned char reg2 = buffer[(*pc)++];
			currentTexCoord = MDVector3Create(regs[reg1], regs[reg2], 0);
			break;
		}
			// Add Index Immediate
		case 0x1D:
		{
			unsigned int val = ReadInt(buffer, pc);
			[ currentFace addIndex:val ];
			break;
		}
			// Add Index
		case 0x1E:
		{
			unsigned char reg = buffer[(*pc)++];
			[ currentFace addIndex:regs[reg] ];
			break;
		}
			// Modulo
		case 0x1F:
		{
			unsigned char store = buffer[(*pc)++];
			unsigned char reg1 = buffer[(*pc)++];
			unsigned char reg2 = buffer[(*pc)++];
			regs[store] = regs[reg1];
			while (regs[store] >= regs[reg2])
				regs[store] -= regs[reg2];
			break;
		}
			// Set Last Index
		case 0x20:
		{
			unsigned int reg = ReadInt(buffer, pc);
			[ [ currentFace indices ] replaceObjectAtIndex:[ [ currentFace indices ] count ] - 1 withObject:[ NSNumber numberWithUnsignedInt:reg ] ];
			break;
		}
			// Normalize Last 3 Indices (Triangle)
		case 0x21:
		{
			MDPoint* p1 = [ [ currentFace points ] objectAtIndex:[ [ [ currentFace indices ] objectAtIndex:[ [ currentFace indices ] count ] - 1 ] unsignedIntValue ] ];
			MDPoint* p2 = [ [ currentFace points ] objectAtIndex:[ [ [ currentFace indices ] objectAtIndex:[ [ currentFace indices ] count ] - 2 ] unsignedIntValue ] ];
			MDPoint* p3 = [ [ currentFace points ] objectAtIndex:[ [ [ currentFace indices ] objectAtIndex:[ [ currentFace indices ] count ] - 3 ] unsignedIntValue ] ];
			
			MDVector3 v21 = MDVector3Create(p1.x - p2.x, p1.y - p2.y, p1.z - p2.z);
			MDVector3 v23 = MDVector3Create(p3.x - p2.x, p3.y - p2.y, p3.z - p2.z);
			MDVector3 normal = MDVector3CrossProduct(v21, v23);
			if (MDVector3Magnitude(normal) != 0)
				normal = MDVector3Normalize(normal);
			
			[ p1 setNormal:normal ];
			[ p2 setNormal:normal ];
			[ p3 setNormal:normal ];
			break;
		}
			// Set nth Last Index
		case 0x22:
		{
			unsigned int reg = ReadInt(buffer, pc);
			unsigned int reg2 = ReadInt(buffer, pc);
			[ [ currentFace indices ] replaceObjectAtIndex:[ [ currentFace indices ] count ] - reg2 withObject:[ NSNumber numberWithUnsignedInt:reg ] ];
			break;
		}
			// Switch Last Two Indices
		case 0x23:
		{
			unsigned int lastI1 = [ [ [ currentFace indices ] objectAtIndex:[ [ currentFace indices ] count ] - 1 ] unsignedIntValue ];
			unsigned int lastI2 = [ [ [ currentFace indices ] objectAtIndex:[ [ currentFace indices ] count ] - 2 ] unsignedIntValue ];
			[ [ currentFace indices ] replaceObjectAtIndex:[ [ currentFace indices ] count ] - 1 withObject:[ NSNumber numberWithUnsignedInt:lastI2 ] ];
			[ [ currentFace indices ] replaceObjectAtIndex:[ [ currentFace indices ] count ] - 2 withObject:[ NSNumber numberWithUnsignedInt:lastI1 ] ];
			break;
		}
			// Normalize the whole things
		case 0x24:
		{
			for (unsigned long z = 0; z < [ obj count ]; z++)
			{
				MDFace* face = [ obj objectAtIndex:z ];
				if ([ [ face points ] count ] > 2)
				{
					unsigned int* temp = (unsigned int*)malloc(sizeof(unsigned int) * [ [ face points ] count ]);
					memset(temp, 0, [ [ face points ] count ] * sizeof(unsigned int));
					
					for (unsigned long t = 0; t < [ [ face points ] count ]; t++)
						[ [ [ face points ] objectAtIndex:t ] setNormal:MDVector3Create(0, 0, 0) ];
					
					unsigned long temp2 = 0;
					for (unsigned long t = 0; t < [ [ face indices ] count ]; t += 3)
					{
						unsigned long q1 = [ [ [ face indices ] objectAtIndex:t ] unsignedLongValue ];
						unsigned long q2 = [ [ [ face indices ] objectAtIndex:t + 1 ] unsignedLongValue ];
						unsigned long q3 = [ [ [ face indices ] objectAtIndex:t + 2 ] unsignedLongValue ];
						
						MDPoint* p1 = [ [ face points ] objectAtIndex:q1 ];
						MDPoint* p2 = [ [ face points ] objectAtIndex:q2 ];
						MDPoint* p3 = [ [ face points ] objectAtIndex:q3 ];
						
						MDVector3 v21 = MDVector3Create(p1.x - p2.x, p1.y - p2.y, p1.z - p2.z);
						MDVector3 v23 = MDVector3Create(p3.x - p2.x, p3.y - p2.y, p3.z - p2.z);
						MDVector3 normal = MDVector3CrossProduct(v23, v21);
						
						temp[q1]++;
						temp[q2]++;
						temp[q3]++;
						
						if (q1 == 2500)
							temp2++;
						if (q2 == 2500)
							temp2++;
						if (q3 == 2500)
							temp2++;
						
						[ p1 setNormalX:normal.x + p1.normalX ];
						[ p1 setNormalY:normal.y + p1.normalY ];
						[ p1 setNormalZ:normal.z + p1.normalZ ];
						
						[ p2 setNormalX:normal.x + p2.normalX ];
						[ p2 setNormalY:normal.y + p2.normalY ];
						[ p2 setNormalZ:normal.z + p2.normalZ ];
						
						[ p3 setNormalX:normal.x + p3.normalX ];
						[ p3 setNormalY:normal.y + p3.normalY ];
						[ p3 setNormalZ:normal.z + p3.normalZ ];
					}
					for (unsigned long t = 0; t < [ [ face points ] count ]; t++)
					{
						MDPoint* p = [ [ face points ] objectAtIndex:t ];
						[ p setNormalX:p.normalX / temp[t] ];
						[ p setNormalY:p.normalY / temp[t] ];
						[ p setNormalZ:p.normalZ / temp[t] ];
						
						[ p setNormal:MDVector3Normalize(MDVector3Create(p.normalX, p.normalY, p.normalZ)) ];
					}
					
					free(temp);
					temp = NULL;
				}
			}
			break;
		}
	}
}
