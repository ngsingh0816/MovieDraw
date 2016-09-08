//
//  MDMatrix.m
//  MovieDraw
//
//  Created by Neil on 6/30/13.
//  Copyright (c) 2013 Neil. All rights reserved.
//

#import "MDMatrix.h"

BOOL MDFloatCompare(float a, float b)
{
	float absA = fabsf(a);
	float absB = fabsf(b);
	float diff = fabsf(a - b);
	
	if (a == b)
		return TRUE;
	else if (a == 0 || b == 0 || diff < FLT_MIN)
		return diff < (FLT_EPSILON * FLT_MIN);
	else
		return (diff / (absA + absB)) < FLT_EPSILON;
}

#pragma mark MDVector2

MDVector2 MDVector2Create(const float& x, const float& y)
{
	MDVector2 vector;
	vector.x = x;
	vector.y = y;
	return vector;
}

MDVector2 MDVector2Create(const MDVector2& xy)
{
	return MDVector2Create(xy.x, xy.y);
}

float MDVector2Magnitude(const MDVector2& v)
{
	return sqrt((v.x * v.x) + (v.y * v.y));
}

float MDVector2DotProduct(const MDVector2& v1, const MDVector2& v2)
{
	return (v1 * v2);
}

float MDVector2Angle(const MDVector2& v1, const MDVector2& v2)
{
	return (acos((v1 * v2) / MDVector2Magnitude(v1) / MDVector2Magnitude(v2)) / M_PI * 180.0);
}

MDVector2 MDVector2Normalize(const MDVector2& v)
{
	float length = MDVector2Magnitude(v);
	if (length == 0)
		return v;
	return (v / length);
}

float MDVector2Distance(const MDVector2& v1, const MDVector2& v2)
{
	float x = v2.x - v1.x;
	float y = v2.y - v1.y;
	return sqrt((x * x) + (y * y));
}

#pragma mark MDVector3

MDVector3 MDVector3Create(const float& x, const float& y, const float& z)
{
	MDVector3 point;
	point.x = x;
	point.y = y;
	point.z = z;
	return point;
}

MDVector3 MDVector3Create(const MDVector2& xy, const float& z)
{
	return MDVector3Create(xy.x, xy.y, z);
}

MDVector3 MDVector3Create(const MDVector3& xyz)
{
	return MDVector3Create(xyz.x, xyz.y, xyz.z);
}

MDVector3 MDVector3CreateXZ(const MDVector2& xz, const float& y)
{
	return MDVector3Create(xz.x, y, xz.y);
}

MDVector3 MDVector3CreateYZ(const float& x, const MDVector2& yz)
{
	return MDVector3Create(x, yz.x, yz.y);
}

float MDVector3Magnitude(const MDVector3& v)
{
	return sqrt((v.x * v.x) + (v.y * v.y) + (v.z * v.z));
}

float MDVector3DotProduct(const MDVector3& v1, const MDVector3& v2)
{
	return ((v1.x * v2.x) + (v1.y * v2.y) + (v1.z * v2.z));
}

float MDVector3Angle(const MDVector3& v1, const MDVector3& v2)
{
	return (acos(MDVector3DotProduct(v1, v2) / MDVector3Magnitude(v1) / MDVector3Magnitude(v2)) / M_PI * 180.0);
}

MDVector3 MDVector3CrossProduct(const MDVector3& v1, const MDVector3& v2)
{
	float Cx = v1.y * v2.z - v1.z * v2.y;
	float Cy = v1.z * v2.x - v1.x * v2.z;
	float Cz = v1.x * v2.y - v1.y * v2.x;
	return MDVector3Create(Cx, Cy, Cz);
}

MDVector3 MDVector3Normalize(const MDVector3& v)
{
	float length = MDVector3Magnitude(v);
	if (length == 0)
		return v;
	return (v / length);
}

float MDVector3Distance(const MDVector3& v1, const MDVector3& v2)
{
	float x = v2.x - v1.x;
	float y = v2.y - v1.y;
	float z = v2.z - v1.z;
	return sqrt((x * x) + (y * y) + (z * z));
}

MDVector3 MDVector3Rotate(MDVector3 p, MDVector3 line, double theta)
{
	MDVector3 p1 = line;
	MDVector3 p2 = MDVector3Create(0, 0, 0);
	MDVector3 u,q1,q2;
	double d;
	
	/* Step 1 */
	q1.x = p.x - p1.x;
	q1.y = p.y - p1.y;
	q1.z = p.z - p1.z;
	
	u.x = p2.x - p1.x;
	u.y = p2.y - p1.y;
	u.z = p2.z - p1.z;
	u = MDVector3Normalize(u);
	d = sqrt(u.y*u.y + u.z*u.z);
	
	/* Step 2 */
	if (d != 0) {
		q2.x = q1.x;
		q2.y = q1.y * u.z / d - q1.z * u.y / d;
		q2.z = q1.y * u.y / d + q1.z * u.z / d;
	} else {
		q2 = q1;
	}
	
	/* Step 3 */
	q1.x = q2.x * d - q2.z * u.x;
	q1.y = q2.y;
	q1.z = q2.x * u.x + q2.z * d;
	
	/* Step 4 */
	q2.x = q1.x * cos(theta) - q1.y * sin(theta);
	q2.y = q1.x * sin(theta) + q1.y * cos(theta);
	q2.z = q1.z;
	
	/* Inverse of step 3 */
	q1.x =   q2.x * d + q2.z * u.x;
	q1.y =   q2.y;
	q1.z = - q2.x * u.x + q2.z * d;
	
	/* Inverse of step 2 */
	if (d != 0) {
		q2.x =   q1.x;
		q2.y =   q1.y * u.z / d + q1.z * u.y / d;
		q2.z = - q1.y * u.y / d + q1.z * u.z / d;
	} else {
		q2 = q1;
	}
	
	/* Inverse of step 1 */
	q1.x = q2.x + p1.x;
	q1.y = q2.y + p1.y;
	q1.z = q2.z + p1.z;
	return(q1);
}

#pragma mark MDVector4

MDVector4 MDVector4Create(const float& x, const float& y, const float& z, const float& w)
{
	MDVector4 ret;
	ret.x = x;
	ret.y = y;
	ret.z = z;
	ret.w = w;
	return ret;
}

MDVector4 MDVector4Create(const MDVector2& xy, const float& z, const float& w)
{
	return MDVector4Create(xy.x, xy.y, z, w);
}

MDVector4 MDVector4Create(const MDVector3& xyz, const float& w)
{
	return MDVector4Create(xyz.x, xyz.y, xyz.z, w);
}

MDVector4 MDVector4Create(const MDVector4& v)
{
	return MDVector4Create(v.x, v.y, v.z, v.w);
}

MDVector4 MDVector4CreateXZ(const MDVector2& xz, const float& y, const float& w)
{
	return MDVector4Create(xz.x, y, xz.y, w);
}

MDVector4 MDVector4CreateXW(const MDVector2& xw, const float& y, const float& z)
{
	return MDVector4Create(xw.x, y, z, xw.y);
}

MDVector4 MDVector4CreateYZ(const float& x, const MDVector2& yz, const float& w)
{
	return MDVector4Create(x, yz.x, yz.y, w);
}

MDVector4 MDVector4CreateYW(const float& x, const MDVector2& yw, const float& z)
{
	return MDVector4Create(x, yw.x, z, yw.y);
}

MDVector4 MDVector4CreateZW(const float& x, const float& y, const MDVector2& zw)
{
	return MDVector4Create(x, y, zw.x, zw.y);
}

MDVector4 MDVector4CreateXYW(const MDVector3& xyw, const float& z)
{
	return MDVector4Create(xyw.x, xyw.y, z, xyw.z);
}

MDVector4 MDVector4CreateXZW(const MDVector3& xzw, const float& y)
{
	return MDVector4Create(xzw.x, y, xzw.y, xzw.z);
}

MDVector4 MDVector4CreateYZW(const float& x, const MDVector3& yzw)
{
	return MDVector4Create(x, yzw.x, yzw.y, yzw.z);
}

float MDVector4Magnitude(const MDVector4& v)
{
	return sqrt((v.x * v.x) + (v.y * v.y) + (v.z * v.z) + (v.w * v.w));
}

float MDVector4DotProduct(const MDVector4& v1, const MDVector4& v2)
{
	return (v1 * v2);
}

float MDVector4Angle(const MDVector4& v1, const MDVector4& v2)
{
	return (acos((v1 * v2) / MDVector4Magnitude(v1) / MDVector4Magnitude(v2)) / M_PI * 180.0);
}

MDVector4 MDVector4Normalize(const MDVector4& v)
{
	float length = MDVector4Magnitude(v);
	if (length == 0)
		return v;
	return (v / length);
}

float MDVector4Distance(const MDVector4& v1, const MDVector4& v2)
{
	float x = v2.x - v1.x;
	float y = v2.y - v1.y;
	float z = v2.z - v1.z;
	float w = v2.w - v1.w;
	return sqrt((x * x) + (y * y) + (z * z) + (w * w));
}

#pragma mark MDMatrix

MDMatrix MDMatrixCreate(MDMatrix matrix)
{
	MDMatrix matrix2;
	memcpy(matrix2.data, matrix.data, sizeof(float) * 16);
	return matrix2;
}

MDMatrix MDMatrixCreate(float matrix[16])
{
	MDMatrix matrix2;
	memcpy(matrix2.data, matrix, sizeof(float) * 16);
	return matrix2;
}

MDMatrix MDMatrixCreate(float row1[4], float row2[4], float row3[4], float row4[4])
{
	MDMatrix matrix2;
	memset(&matrix2, 0, sizeof(matrix2));
	matrix2.data[0] = row1[0];
	matrix2.data[1] = row2[0];
	matrix2.data[2] = row3[0];
	matrix2.data[3] = row4[0];
	matrix2.data[4] = row1[1];
	matrix2.data[5] = row2[1];
	matrix2.data[6] = row3[1];
	matrix2.data[7] = row4[1];
	matrix2.data[8] = row1[2];
	matrix2.data[9] = row2[2];
	matrix2.data[10] = row3[2];
	matrix2.data[11] = row4[2];
	matrix2.data[12] = row1[3];
	matrix2.data[13] = row2[3];
	matrix2.data[14] = row3[3];
	matrix2.data[15] = row4[3];
	return matrix2;
}

MDMatrix MDMatrixCreate(float r1c1, float r1c2, float r1c3, float r1c4, float r2c1, float r2c2, float r2c3, float r2c4, float r3c1, float r3c2, float r3c3, float r3c4, float r4c1, float r4c2, float r4c3, float r4c4)
{
	MDMatrix matrix2;
	memset(&matrix2, 0, sizeof(matrix2));
	matrix2.data[0] = r1c1;
	matrix2.data[4] = r1c2;
	matrix2.data[8] = r1c3;
	matrix2.data[12] = r1c4;
	matrix2.data[1] = r2c1;
	matrix2.data[5] = r2c2;
	matrix2.data[9] = r2c3;
	matrix2.data[13] = r2c4;
	matrix2.data[2] = r3c1;
	matrix2.data[6] = r3c2;
	matrix2.data[10] = r3c3;
	matrix2.data[14] = r3c4;
	matrix2.data[3] = r4c1;
	matrix2.data[7] = r4c2;
	matrix2.data[11] = r4c3;
	matrix2.data[15] = r4c4;
	return matrix2;
}

float MDMatrixValue(MDMatrix matrix, int row, int column)
{
	return matrix.data[(column * 4) + row];
}

void MDMatrixValue(MDMatrix* matrix, int row, int column, float value)
{
	matrix->data[(column * 4) + row] = value;
}

MDMatrix MDMatrixMultiply(MDMatrix matrix1, MDMatrix matrix2)
{
	return matrix1 * matrix2;
}

MDVector4 MDMatrixMultiply(MDMatrix matrix, float x, float y, float z, float w)
{
	float data[16];
	memcpy(data, matrix.data, sizeof(float) * 16);
	MDVector4 vector;
	vector.x = (data[0] * x) + (data[4] * y) + (data[8] * z) + (data[12] * w);
	vector.y = (data[1] * x) + (data[5] * y) + (data[9] * z) + (data[13] * w);
	vector.z = (data[2] * x) + (data[6] * y) + (data[10] * z) + (data[14] * w);
	vector.w = (data[3] * x) + (data[7] * y) + (data[11] * z) + (data[15] * w);
	return vector;
}

MDVector4 MDMatrixMultiply(MDMatrix matrix, MDVector3 point, float w)
{
	return MDMatrixMultiply(matrix, point.x, point.y, point.z, w);
}

MDVector4 MDMatrixMultiply(MDMatrix matrix, MDVector4 vector)
{
	return MDMatrixMultiply(matrix, vector.x, vector.y, vector.z, vector.w);
}

MDMatrix MDMatrixIdentity()
{
	MDMatrix matrix2;
	matrix2.data[0] = 1;
	matrix2.data[5] = 1;
	matrix2.data[10] = 1;
	matrix2.data[15] = 1;
	matrix2.data[1] = matrix2.data[2] = matrix2.data[3] = matrix2.data[4] = matrix2.data[6] = matrix2.data[7] = matrix2.data[8] = matrix2.data[9] = matrix2.data[11] = matrix2.data[12] = matrix2.data[13] = matrix2.data[14] = 0;
	return matrix2;
}

void MDMatrixTranslate(MDMatrix* matrix, float x, float y, float z)
{
	MDMatrix trans = MDMatrixIdentity();
	trans.data[12] = x;
	trans.data[13] = y;
	trans.data[14] = z;
	
	*matrix = *matrix * trans;
}

void MDMatrixTranslate(MDMatrix* matrix, MDVector3 translate)
{
	MDMatrixTranslate(matrix, translate.x, translate.y, translate.z);
}

void MDMatrixRotate(MDMatrix* matrix, float x, float y, float z, float angle)
{
	GLfloat mag = sqrtf((x*x) + (y*y) + (z*z));
    if (mag == 0.0)
		return;
    else if (mag != 1.0)
    {
        x /= mag;
        y /= mag;
        z /= mag;
    }
    
	float degAngle = angle / 180 * M_PI;
    float c = cos(degAngle);
    float s = sin(degAngle);
	
	float data[16];
    data[3] = data[7] = data[11] = data[12] = data[13] = data[14] = 0.0;
    data[15] = 1.0;
    data[0] = (x*x)*(1-c) + c;
    data[1] = (y*x)*(1-c) + (z*s);
    data[2] = (x*z)*(1-c) - (y*s);
    data[4] = (x*y)*(1-c)-(z*s);
    data[5] = (y*y)*(1-c)+c;
    data[6] = (y*z)*(1-c)+(x*s);
    data[8] = (x*z)*(1-c)+(y*s);
    data[9] = (y*z)*(1-c)-(x*s);
    data[10] = (z*z)*(1-c)+c;
	
	MDMatrix matrix2;
	memcpy(matrix2.data, data, sizeof(float) * 16);
	
	*matrix = *matrix * matrix2;
}

void MDMatrixRotate(MDMatrix* matrix, MDVector3 axis, float angle)
{
	MDMatrixRotate(matrix, axis.x, axis.y, axis.z, angle);
}

void MDMatrixScale(MDMatrix* matrix, float x, float y, float z)
{
	MDMatrix scale = MDMatrixIdentity();
	scale.data[0] = x;
	scale.data[5] = y;
	scale.data[10] = z;
	
	*matrix = *matrix * scale;
}

void MDMatrixScale(MDMatrix* matrix, MDVector3 scale)
{
	MDMatrixScale(matrix, scale.x, scale.y, scale.z);
}

void MDMatrixSetPerspective(MDMatrix* matrix, float fovy, float aspectRatio, float znear, float zfar)
{	
	float radians = fovy / 2 * M_PI / 180;
	
	float deltaZ = zfar - znear;
	if (deltaZ == 0 || aspectRatio == 0)
		return;
	float cotangent = tan(M_PI_2 - radians);
	
	float m[4][4];
	memcpy(m, MDMatrixIdentity().data, sizeof(float) * 16);
	m[0][0] = cotangent / aspectRatio;
	m[1][1] = cotangent;
	m[2][2] = -(zfar + znear) / deltaZ;
	m[2][3] = -1;
	m[3][2] = -2 * znear * zfar / deltaZ;
	m[3][3] = 0;
	
	MDMatrix matrix2;
	memcpy(matrix2.data, m, sizeof(float) * 16);
	
	*matrix = *matrix * matrix2;
}

void MDMatrixLookAt(MDMatrix* matrix, MDVector3 eyePosition, MDVector3 center, MDVector3 upVector)
{	
	MDVector3 forward = MDVector3Normalize(center - eyePosition);
	MDVector3 side = MDVector3Normalize(MDVector3CrossProduct(forward, upVector));
	if (MDFloatCompare(MDVector3Magnitude(side), 0) || forward == upVector)		// Should always be the same
	{
		// For now, just assume upVector = (0, 1, 0)
		// The real job is to rotate a copy of the upVector by some amount on its plane (which there are infinite) and find the perpendicular vector
		side = MDVector3Create(0, 0, -1);
	}
	
	MDVector3 up = MDVector3CrossProduct(side, forward);
	
	float matrix2[16];
	matrix2[0] = side.x;
	matrix2[4] = side.y;
	matrix2[8] = side.z;
	matrix2[12] = 0.0;
	matrix2[1] = up.x;
	matrix2[5] = up.y;
	matrix2[9] = up.z;
	matrix2[13] = 0.0;
	matrix2[2] = -forward.x;
	matrix2[6] = -forward.y;
	matrix2[10] = -forward.z;
	matrix2[14] = 0.0;
	matrix2[3] = matrix2[7] = matrix2[11] = 0.0;
	matrix2[15] = 1.0;

	*matrix *= MDMatrixCreate(matrix2);
	MDMatrixTranslate(matrix, -1 * eyePosition);
}

void MDMatrixSetOthro(MDMatrix* matrix, float left, float right, float bottom, float top)
{
	float matrix2[16];
	memset(matrix2, 0, 16 * sizeof(float));
	matrix2[0] = 2 / (right - left);
	matrix2[5] = 2 / (top - bottom);
	matrix2[10] = -1;
	matrix2[12] = -(right + left) / (right - left);
	matrix2[13] = -(top + bottom) / (top - bottom);
	matrix2[14] = 0;
	matrix2[15] = 1;
	
	*matrix *= MDMatrixCreate(matrix2);
}

float MDMatrixDeterminant(MDMatrix matrix)
{
	float m[16];
	memcpy(m, matrix.data, sizeof(float) * 16);
	
	float inv0 = m[5]  * m[10] * m[15] -
	m[5]  * m[11] * m[14] -
	m[9]  * m[6]  * m[15] +
	m[9]  * m[7]  * m[14] +
	m[13] * m[6]  * m[11] -
	m[13] * m[7]  * m[10];
	
    float inv4 = -m[4]  * m[10] * m[15] +
	m[4]  * m[11] * m[14] +
	m[8]  * m[6]  * m[15] -
	m[8]  * m[7]  * m[14] -
	m[12] * m[6]  * m[11] +
	m[12] * m[7]  * m[10];
	
    float inv8 = m[4]  * m[9] * m[15] -
	m[4]  * m[11] * m[13] -
	m[8]  * m[5] * m[15] +
	m[8]  * m[7] * m[13] +
	m[12] * m[5] * m[11] -
	m[12] * m[7] * m[9];
	
    float inv12 = -m[4]  * m[9] * m[14] +
	m[4]  * m[10] * m[13] +
	m[8]  * m[5] * m[14] -
	m[8]  * m[6] * m[13] -
	m[12] * m[5] * m[10] +
	m[12] * m[6] * m[9];
	
	return (m[0] * inv0 + m[1] * inv4 + m[2] * inv8 + m[3] * inv12);
}

MDMatrix MDMatrixInverse(MDMatrix matrix)
{
	float inv[16];
	float m[16];
	memcpy(m, matrix.data, sizeof(float) * 16);
	
	inv[0] = m[5]  * m[10] * m[15] -
	m[5]  * m[11] * m[14] -
	m[9]  * m[6]  * m[15] +
	m[9]  * m[7]  * m[14] +
	m[13] * m[6]  * m[11] -
	m[13] * m[7]  * m[10];
	
    inv[4] = -m[4]  * m[10] * m[15] +
	m[4]  * m[11] * m[14] +
	m[8]  * m[6]  * m[15] -
	m[8]  * m[7]  * m[14] -
	m[12] * m[6]  * m[11] +
	m[12] * m[7]  * m[10];
	
    inv[8] = m[4]  * m[9] * m[15] -
	m[4]  * m[11] * m[13] -
	m[8]  * m[5] * m[15] +
	m[8]  * m[7] * m[13] +
	m[12] * m[5] * m[11] -
	m[12] * m[7] * m[9];
	
    inv[12] = -m[4]  * m[9] * m[14] +
	m[4]  * m[10] * m[13] +
	m[8]  * m[5] * m[14] -
	m[8]  * m[6] * m[13] -
	m[12] * m[5] * m[10] +
	m[12] * m[6] * m[9];
	
    inv[1] = -m[1]  * m[10] * m[15] +
	m[1]  * m[11] * m[14] +
	m[9]  * m[2] * m[15] -
	m[9]  * m[3] * m[14] -
	m[13] * m[2] * m[11] +
	m[13] * m[3] * m[10];
	
    inv[5] = m[0]  * m[10] * m[15] -
	m[0]  * m[11] * m[14] -
	m[8]  * m[2] * m[15] +
	m[8]  * m[3] * m[14] +
	m[12] * m[2] * m[11] -
	m[12] * m[3] * m[10];
	
    inv[9] = -m[0]  * m[9] * m[15] +
	m[0]  * m[11] * m[13] +
	m[8]  * m[1] * m[15] -
	m[8]  * m[3] * m[13] -
	m[12] * m[1] * m[11] +
	m[12] * m[3] * m[9];
	
    inv[13] = m[0]  * m[9] * m[14] -
	m[0]  * m[10] * m[13] -
	m[8]  * m[1] * m[14] +
	m[8]  * m[2] * m[13] +
	m[12] * m[1] * m[10] -
	m[12] * m[2] * m[9];
	
    inv[2] = m[1]  * m[6] * m[15] -
	m[1]  * m[7] * m[14] -
	m[5]  * m[2] * m[15] +
	m[5]  * m[3] * m[14] +
	m[13] * m[2] * m[7] -
	m[13] * m[3] * m[6];
	
    inv[6] = -m[0]  * m[6] * m[15] +
	m[0]  * m[7] * m[14] +
	m[4]  * m[2] * m[15] -
	m[4]  * m[3] * m[14] -
	m[12] * m[2] * m[7] +
	m[12] * m[3] * m[6];
	
    inv[10] = m[0]  * m[5] * m[15] -
	m[0]  * m[7] * m[13] -
	m[4]  * m[1] * m[15] +
	m[4]  * m[3] * m[13] +
	m[12] * m[1] * m[7] -
	m[12] * m[3] * m[5];
	
    inv[14] = -m[0]  * m[5] * m[14] +
	m[0]  * m[6] * m[13] +
	m[4]  * m[1] * m[14] -
	m[4]  * m[2] * m[13] -
	m[12] * m[1] * m[6] +
	m[12] * m[2] * m[5];
	
    inv[3] = -m[1] * m[6] * m[11] +
	m[1] * m[7] * m[10] +
	m[5] * m[2] * m[11] -
	m[5] * m[3] * m[10] -
	m[9] * m[2] * m[7] +
	m[9] * m[3] * m[6];
	
    inv[7] = m[0] * m[6] * m[11] -
	m[0] * m[7] * m[10] -
	m[4] * m[2] * m[11] +
	m[4] * m[3] * m[10] +
	m[8] * m[2] * m[7] -
	m[8] * m[3] * m[6];
	
    inv[11] = -m[0] * m[5] * m[11] +
	m[0] * m[7] * m[9] +
	m[4] * m[1] * m[11] -
	m[4] * m[3] * m[9] -
	m[8] * m[1] * m[7] +
	m[8] * m[3] * m[5];
	
    inv[15] = m[0] * m[5] * m[10] -
	m[0] * m[6] * m[9] -
	m[4] * m[1] * m[10] +
	m[4] * m[2] * m[9] +
	m[8] * m[1] * m[6] -
	m[8] * m[2] * m[5];
	
    float det = m[0] * inv[0] + m[1] * inv[4] + m[2] * inv[8] + m[3] * inv[12];
	
    if (det == 0)
	{
		MDMatrix matrix2;
		memset(&matrix2, 0, sizeof(matrix2));
		return matrix2;
	}
	
	MDMatrix matrix2;
	memset(&matrix2, 0, sizeof(matrix2));
    for (int i = 0; i < 16; i++)
        matrix2.data[i] = inv[i] / det;
	return matrix2;
}

MDMatrix MDMatrixTranspose(MDMatrix matrix)
{
	MDMatrix matrix2;
	matrix2.data[0] = matrix.data[0];
	matrix2.data[1] = matrix.data[4];
	matrix2.data[2] = matrix.data[8];
	matrix2.data[3] = matrix.data[12];
	matrix2.data[4] = matrix.data[1];
	matrix2.data[5] = matrix.data[5];
	matrix2.data[6] = matrix.data[9];
	matrix2.data[7] = matrix.data[13];
	matrix2.data[8] = matrix.data[2];
	matrix2.data[9] = matrix.data[6];
	matrix2.data[10] = matrix.data[10];
	matrix2.data[11] = matrix.data[14];
	matrix2.data[12] = matrix.data[3];
	matrix2.data[13] = matrix.data[7];
	matrix2.data[14] = matrix.data[11];
	matrix2.data[15] = matrix.data[15];
	return matrix2;
}

MDVector3 MDMatrixProject(MDVector3 obj, MDMatrix modelViewMatrix, MDMatrix projectionMatrix, int* viewport)
{
	float modelview[16];
	memcpy(modelview, modelViewMatrix.data, sizeof(float) * 16);
	float projection[16];
	memcpy(projection, projectionMatrix.data, sizeof(float) * 16);
	//Transformation vectors
	float fTempo[8];
	//Modelview transform
	fTempo[0]=modelview[0]*obj.x+modelview[4]*obj.y+modelview[8]*obj.z+modelview[12];  //w is always 1
	fTempo[1]=modelview[1]*obj.x+modelview[5]*obj.y+modelview[9]*obj.z+modelview[13];
	fTempo[2]=modelview[2]*obj.x+modelview[6]*obj.y+modelview[10]*obj.z+modelview[14];
	fTempo[3]=modelview[3]*obj.x+modelview[7]*obj.y+modelview[11]*obj.z+modelview[15];
	//Projection transform, the final row of projection matrix is always [0 0 -1 0]
	//so we optimize for that.
	fTempo[4]=projection[0]*fTempo[0]+projection[4]*fTempo[1]+projection[8]*fTempo[2]+projection[12]*fTempo[3];
	fTempo[5]=projection[1]*fTempo[0]+projection[5]*fTempo[1]+projection[9]*fTempo[2]+projection[13]*fTempo[3];
	fTempo[6]=projection[2]*fTempo[0]+projection[6]*fTempo[1]+projection[10]*fTempo[2]+projection[14]*fTempo[3];
	fTempo[7]=-fTempo[2];
	//The result normalizes between -1 and 1
	if(fTempo[7]==0.0)        //The w value
		return MDVector3Create(-1, -1, -1);
	fTempo[7]=1.0/fTempo[7];
	//Perspective division
	fTempo[4]*=fTempo[7];
	fTempo[5]*=fTempo[7];
	fTempo[6]*=fTempo[7];
	//Window coordinates
	//Map x, y to range 0-1
	MDVector3 ret;
	ret.x=(fTempo[4]*0.5+0.5)*viewport[2]+viewport[0];
	ret.y =(fTempo[5]*0.5+0.5)*viewport[3]+viewport[1];
	//This is only correct when glDepthRange(0.0, 1.0)
	ret.z =(1.0+fTempo[6])*0.5;  //Between 0 and 1
	return ret;
}

#define SWAP_ROWS_DOUBLE(a, b) { double *_tmp = a; (a)=(b); (b)=_tmp; }
#define SWAP_ROWS_FLOAT(a, b) { float *_tmp = a; (a)=(b); (b)=_tmp; }
#define MAT(m,r,c) (m)[(c)*4+(r)]

int glhInvertMatrixf2(float *m, float *outM);
int glhInvertMatrixf2(float *m, float *outM)
{
	float wtmp[4][8];
	float m0, m1, m2, m3, s;
	float *r0, *r1, *r2, *r3;
	r0 = wtmp[0], r1 = wtmp[1], r2 = wtmp[2], r3 = wtmp[3];
	r0[0] = MAT(m, 0, 0), r0[1] = MAT(m, 0, 1),
	r0[2] = MAT(m, 0, 2), r0[3] = MAT(m, 0, 3),
	r0[4] = 1.0, r0[5] = r0[6] = r0[7] = 0.0,
	r1[0] = MAT(m, 1, 0), r1[1] = MAT(m, 1, 1),
	r1[2] = MAT(m, 1, 2), r1[3] = MAT(m, 1, 3),
	r1[5] = 1.0, r1[4] = r1[6] = r1[7] = 0.0,
	r2[0] = MAT(m, 2, 0), r2[1] = MAT(m, 2, 1),
	r2[2] = MAT(m, 2, 2), r2[3] = MAT(m, 2, 3),
	r2[6] = 1.0, r2[4] = r2[5] = r2[7] = 0.0,
	r3[0] = MAT(m, 3, 0), r3[1] = MAT(m, 3, 1),
	r3[2] = MAT(m, 3, 2), r3[3] = MAT(m, 3, 3),
	r3[7] = 1.0, r3[4] = r3[5] = r3[6] = 0.0;
	/* choose pivot - or die */
	if (fabsf(r3[0]) > fabsf(r2[0]))
		SWAP_ROWS_FLOAT(r3, r2);
	if (fabsf(r2[0]) > fabsf(r1[0]))
		SWAP_ROWS_FLOAT(r2, r1);
	if (fabsf(r1[0]) > fabsf(r0[0]))
		SWAP_ROWS_FLOAT(r1, r0);
	if (0.0 == r0[0])
		return 0;
	/* eliminate first variable     */
	m1 = r1[0] / r0[0];
	m2 = r2[0] / r0[0];
	m3 = r3[0] / r0[0];
	s = r0[1];
	r1[1] -= m1 * s;
	r2[1] -= m2 * s;
	r3[1] -= m3 * s;
	s = r0[2];
	r1[2] -= m1 * s;
	r2[2] -= m2 * s;
	r3[2] -= m3 * s;
	s = r0[3];
	r1[3] -= m1 * s;
	r2[3] -= m2 * s;
	r3[3] -= m3 * s;
	s = r0[4];
	if (s != 0.0) {
		r1[4] -= m1 * s;
		r2[4] -= m2 * s;
		r3[4] -= m3 * s;
	}
	s = r0[5];
	if (s != 0.0) {
		r1[5] -= m1 * s;
		r2[5] -= m2 * s;
		r3[5] -= m3 * s;
	}
	s = r0[6];
	if (s != 0.0) {
		r1[6] -= m1 * s;
		r2[6] -= m2 * s;
		r3[6] -= m3 * s;
	}
	s = r0[7];
	if (s != 0.0) {
		r1[7] -= m1 * s;
		r2[7] -= m2 * s;
		r3[7] -= m3 * s;
	}
	/* choose pivot - or die */
	if (fabsf(r3[1]) > fabsf(r2[1]))
		SWAP_ROWS_FLOAT(r3, r2);
	if (fabsf(r2[1]) > fabsf(r1[1]))
		SWAP_ROWS_FLOAT(r2, r1);
	if (0.0 == r1[1])
		return 0;
	/* eliminate second variable */
	m2 = r2[1] / r1[1];
	m3 = r3[1] / r1[1];
	r2[2] -= m2 * r1[2];
	r3[2] -= m3 * r1[2];
	r2[3] -= m2 * r1[3];
	r3[3] -= m3 * r1[3];
	s = r1[4];
	if (0.0 != s) {
		r2[4] -= m2 * s;
		r3[4] -= m3 * s;
	}
	s = r1[5];
	if (0.0 != s) {
		r2[5] -= m2 * s;
		r3[5] -= m3 * s;
	}
	s = r1[6];
	if (0.0 != s) {
		r2[6] -= m2 * s;
		r3[6] -= m3 * s;
	}
	s = r1[7];
	if (0.0 != s) {
		r2[7] -= m2 * s;
		r3[7] -= m3 * s;
	}
	/* choose pivot - or die */
	if (fabsf(r3[2]) > fabsf(r2[2]))
		SWAP_ROWS_FLOAT(r3, r2);
	if (0.0 == r2[2])
		return 0;
	/* eliminate third variable */
	m3 = r3[2] / r2[2];
	r3[3] -= m3 * r2[3], r3[4] -= m3 * r2[4],
	r3[5] -= m3 * r2[5], r3[6] -= m3 * r2[6], r3[7] -= m3 * r2[7];
	/* last check */
	if (0.0 == r3[3])
		return 0;
	s = 1.0 / r3[3];             /* now back substitute row 3 */
	r3[4] *= s;
	r3[5] *= s;
	r3[6] *= s;
	r3[7] *= s;
	m2 = r2[3];                  /* now back substitute row 2 */
	s = 1.0 / r2[2];
	r2[4] = s * (r2[4] - r3[4] * m2), r2[5] = s * (r2[5] - r3[5] * m2),
	r2[6] = s * (r2[6] - r3[6] * m2), r2[7] = s * (r2[7] - r3[7] * m2);
	m1 = r1[3];
	r1[4] -= r3[4] * m1, r1[5] -= r3[5] * m1,
	r1[6] -= r3[6] * m1, r1[7] -= r3[7] * m1;
	m0 = r0[3];
	r0[4] -= r3[4] * m0, r0[5] -= r3[5] * m0,
	r0[6] -= r3[6] * m0, r0[7] -= r3[7] * m0;
	m1 = r1[2];                  /* now back substitute row 1 */
	s = 1.0 / r1[1];
	r1[4] = s * (r1[4] - r2[4] * m1), r1[5] = s * (r1[5] - r2[5] * m1),
	r1[6] = s * (r1[6] - r2[6] * m1), r1[7] = s * (r1[7] - r2[7] * m1);
	m0 = r0[2];
	r0[4] -= r2[4] * m0, r0[5] -= r2[5] * m0,
	r0[6] -= r2[6] * m0, r0[7] -= r2[7] * m0;
	m0 = r0[1];                  /* now back substitute row 0 */
	s = 1.0 / r0[0];
	r0[4] = s * (r0[4] - r1[4] * m0), r0[5] = s * (r0[5] - r1[5] * m0),
	r0[6] = s * (r0[6] - r1[6] * m0), r0[7] = s * (r0[7] - r1[7] * m0);
	MAT(outM, 0, 0) = r0[4];
	MAT(outM, 0, 1) = r0[5], MAT(outM, 0, 2) = r0[6];
	MAT(outM, 0, 3) = r0[7], MAT(outM, 1, 0) = r1[4];
	MAT(outM, 1, 1) = r1[5], MAT(outM, 1, 2) = r1[6];
	MAT(outM, 1, 3) = r1[7], MAT(outM, 2, 0) = r2[4];
	MAT(outM, 2, 1) = r2[5], MAT(outM, 2, 2) = r2[6];
	MAT(outM, 2, 3) = r2[7], MAT(outM, 3, 0) = r3[4];
	MAT(outM, 3, 1) = r3[5], MAT(outM, 3, 2) = r3[6];
	MAT(outM, 3, 3) = r3[7];
	return 1;
}

MDVector3 MDMatrixUnProject(MDVector3 win, MDMatrix modelView, MDMatrix projection, int* viewport)
{
	//Transformation matrices
	float m[16], A[16];
	float inM[4], outM[4];
	//Calculation for inverting a matrix, compute projection x modelview
	//and store in A[16]
	memcpy(A, (projection * modelView).data, sizeof(float) * 16);
	//Now compute the inverse of matrix A
	if(glhInvertMatrixf2(A, m) == 0)
		return MDVector3Create(0, 0, 0);
	//Transformation of normalized coordinates between -1 and 1
	inM[0] = (win.x - (float)viewport[0]) / (float)viewport[2] * 2.0 - 1.0;
	inM[1] = (win.y - (float)viewport[1]) / (float)viewport[3] * 2.0 - 1.0;
	inM[2] = 2.0 * win.z -1.0;
	inM[3] = 1.0;
	//Objects coordinates
	MDVector4 vec = MDMatrixMultiply(MDMatrixCreate(m), inM[0], inM[1], inM[2], inM[3]);
	outM[0] = vec.x, outM[1] = vec.y, outM[2] = vec.z, outM[3] = vec.w;
	if(outM[3] == 0.0)
		return MDVector3Create(0, 0, 0);
	outM[3] = 1.0 / outM[3];
	return (MDVector3Create(outM[0], outM[1], outM[2]) * outM[3]);
}
