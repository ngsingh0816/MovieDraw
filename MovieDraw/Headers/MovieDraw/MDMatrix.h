/*
	MDMatrix.h
	MovieDraw
 
	Copyright (c) 2013. All rights reserved.
*/

#import <Foundation/Foundation.h>

// An accurate way of saying (a == b)
BOOL MDFloatCompare(float a, float b);

// A scalar value
typedef float MDScalar;

// A vector quantity with two components
struct MDVector2
{
	float x;
	float y;
	
	inline float GetX() const {
		return x;
	}
	inline float GetY() const {
		return y;
	}
	inline void SetX(const float& val) {
		x = val;
	}
	inline void SetY(const float& val) {
		y = val;
	}
	inline void SetXY(const float& xVal, const float& yVal) {
		x = xVal;
		y = yVal;
	}
	inline void SetXY(const MDVector2& p) {
		x = p.x;
		y = p.y;
	}
	inline MDVector2 operator + (const MDVector2& p) const {
		MDVector2 ret;
		ret.x = x + p.x;
		ret.y = y + p.y;
		return ret;
	}
	inline MDVector2 operator - (const MDVector2& p) const {
		MDVector2 ret;
		ret.x = x - p.x;
		ret.y = y - p.y;
		return ret;
	}
	inline float operator * (const MDVector2& p) const {
		return ((x * p.x) + (y * p.y));
	}
	inline MDVector2 operator * (const float& p) const {
		MDVector2 ret;
		ret.x = x * p;
		ret.y = y * p;
		return ret;
	}
	inline MDVector2 operator / (const float& p) const {
		MDVector2 ret;
		ret.x = x / p;
		ret.y = y / p;
		return ret;
	}
	inline MDVector2& operator = (const MDVector2& p) {
		x = p.x;
		y = p.y;
		return *this;
	}
	inline MDVector2& operator += (const MDVector2& p) {
		x += p.x;
		y += p.y;
		return *this;
	}
	
	inline MDVector2& operator -= (const MDVector2& p) {
		x -= p.x;
		y -= p.y;
		return *this;
	}
	inline MDVector2& operator *= (const float& p) {
		x *= p;
		y *= p;
		return *this;
	}
	inline MDVector2& operator /= (const float& p) {
		x /= p;
		y /= p;
		return *this;
	}
	inline BOOL operator == (const MDVector2& p) const {
		return (MDFloatCompare(x, p.x) && MDFloatCompare(y, p.y));
	}
};
// Enables an expression like (5.0 * v) to work
inline MDVector2 operator * (const float& p, const MDVector2& v) {
	MDVector2 ret;
	ret.x = v.x * p;
	ret.y = v.y * p;
	return ret;
}	

// Create a vector with two components
MDVector2 MDVector2Create(const float& x, const float& y);
MDVector2 MDVector2Create(const MDVector2& xy);

// Calculating Methods
float MDVector2Magnitude(const MDVector2& v);								// Returns the magnitude (length) of the vector
float MDVector2DotProduct(const MDVector2& v1, const MDVector2& v2);		// Returns the dot product of the two vectors
float MDVector2Angle(const MDVector2& v1, const MDVector2& v2);				// Returns the angle (in degrees) in between the two vectors
MDVector2 MDVector2Normalize(const MDVector2& v);							// Returns the normalized vector (has a magnitude of 1)
float MDVector2Distance(const MDVector2& v1, const MDVector2& v2);			// Returns the distance between two vectors

// A vector quantity with three components
// * There is no multiplication operator between two MDVector3's because there are two methods of multiplication (dot, cross)
struct MDVector3
{
	float x;
	float y;
	float z;
	
	inline float GetX() const {
		return x;
	}
	inline float GetY() const {
		return y;
	}
	inline float GetZ() const {
		return z;
	}
	inline MDVector2 GetXY() const {
		return MDVector2Create(x, y);
	}
	inline MDVector2 GetXZ() const {
		return MDVector2Create(x, z);
	}
	inline MDVector2 GetYZ() const {
		return MDVector2Create(y, z);
	}
	inline void SetX(const float& val) {
		x = val;
	}
	inline void SetY(const float& val) {
		y = val;
	}
	inline void SetZ(const float& val) {
		z = val;
	}
	inline void SetXY(const float& xVal, const float& yVal) {
		x = xVal;
		y = yVal;
	}
	inline void SetXY(const MDVector2& p) {
		x = p.x;
		y = p.y;
	}
	inline void SetXZ(const float& xVal, const float& zVal) {
		x = xVal;
		z = zVal;
	}
	inline void SetXZ(const MDVector2& p) {
		x = p.x;
		z = p.y;
	}
	inline void SetYZ(const float& yVal, const float& zVal) {
		y = yVal;
		z = zVal;
	}
	inline void SetYZ(const MDVector2& p) {
		y = p.x;
		z = p.y;
	}
	inline void SetXYZ(const float& xVal, const float& yVal, const float& zVal) {
		x = xVal;
		y = yVal;
		z = zVal;
	}
	inline void SetXYZ(const MDVector3& p) {
		x = p.x;
		y = p.y;
		z = p.z;
	}
	inline MDVector3 operator + (const MDVector3& p) const {
		MDVector3 ret;
		ret.x = x + p.x, ret.y = y + p.y, ret.z = z + p.z;
		return ret;
	}
	inline MDVector3 operator - (const MDVector3& p) const {
		MDVector3 ret;
		ret.x = x - p.x, ret.y = y - p.y, ret.z = z - p.z;
		return ret;
	}
	inline MDVector3 operator * (const float& p) const {
		MDVector3 ret;
		ret.x = x * p, ret.y = y * p, ret.z = z * p;
		return ret;
	}
	inline MDVector3 operator / (const float& p) const {
		MDVector3 ret;
		ret.x = x / p, ret.y = y / p, ret.z = z / p;
		return ret;
	}
	inline MDVector3 operator = (const MDVector3& p) {
		x = p.x;
		y = p.y;
		z = p.z;
		return *this;
	}
	inline MDVector3 operator += (const MDVector3& p) {
		x += p.x;
		y += p.y;
		z += p.z;
		return *this;
	}
	inline MDVector3 operator -= (const MDVector3& p) {
		x -= p.x;
		y -= p.y;
		z -= p.z;
		return *this;
	}
	inline MDVector3 operator *= (const float& p) {
		x *= p;
		y *= p;
		z *= p;
		return *this;
	}
	inline MDVector3 operator /= (const float& p) {
		x /= p;
		y /= p;
		z /= p;
		return *this;
	}
	inline BOOL operator == (const MDVector3& p) const {
		return (MDFloatCompare(x, p.x) && MDFloatCompare(y, p.y) && MDFloatCompare(z, p.z));
	}
};
// Enables an expression like (5.0 * v) to work
inline MDVector3 operator * (const float& p, const MDVector3& v) {
	MDVector3 ret;
	ret.x = v.x * p;
	ret.y = v.y * p;
	ret.z = v.z * p;
	return ret;
}

// Create a three component vector
MDVector3 MDVector3Create(const float& x, const float& y, const float& z);
MDVector3 MDVector3Create(const MDVector2& xy, const float& z);
MDVector3 MDVector3Create(const MDVector3& xyz);

// Luxury Methods
MDVector3 MDVector3CreateXZ(const MDVector2& xz, const float& y);
MDVector3 MDVector3CreateYZ(const float& x, const MDVector2& yz);

// Calculating Methods
float MDVector3Magnitude(const MDVector3& v);								// Returns the magnitude (length) of the vector
float MDVector3DotProduct(const MDVector3& v1, const MDVector3& v2);		// Returns the dot product of the two vectors
float MDVector3Angle(const MDVector3& v1, const MDVector3& v2);				// Returns the angle (in degrees) in between the two vectors
MDVector3 MDVector3CrossProduct(const MDVector3& v1, const MDVector3& v2);	// Returns the cross product of the two vectors (the perpendicular vector)
MDVector3 MDVector3Normalize(const MDVector3& v);							// Returns the normalized vector (has a magnitude of 1)
float MDVector3Distance(const MDVector3& v1, const MDVector3& v2);			// Returns the distance between two vectors
MDVector3 MDVector3Rotate(MDVector3 point, MDVector3 line, double angle);	// Returns a point that was rotate around a line (angle is in degrees)
	
// A vector quantity with four components
struct MDVector4
{
	float x;
	float y;
	float z;
	float w;
	
	inline float GetX() const {
		return x;
	}
	inline float GetY() const {
		return y;
	}
	inline float GetZ() const {
		return z;
	}
	inline float GetW() const {
		return w;
	}
	inline MDVector2 GetXY() const {
		return MDVector2Create(x, y);
	}
	inline MDVector2 GetXZ() const {
		return MDVector2Create(x, z);
	}
	inline MDVector2 GetXW() const {
		return MDVector2Create(x, w);
	}
	inline MDVector2 GetYZ() const {
		return MDVector2Create(y, z);
	}
	inline MDVector2 GetYW() const {
		return MDVector2Create(y, w);
	}
	inline MDVector2 GetZW() const {
		return MDVector2Create(z, w);
	}
	inline MDVector3 GetXYZ() const {
		return MDVector3Create(x, y, z);
	}
	inline MDVector3 GetXYW() const {
		return MDVector3Create(x, y, w);
	}
	inline MDVector3 GetXZW() const {
		return MDVector3Create(x, z, w);
	}
	inline MDVector3 GetYZW() const {
		return MDVector3Create(y, z, w);
	}
	inline void SetX(const float& val) {
		x = val;
	}
	inline void SetY(const float& val) {
		y = val;
	}
	inline void SetZ(const float& val) {
		z = val;
	}
	inline void SetW(const float& val) {
		w = val;
	}
	inline void SetXY(const float& xVal, const float& yVal) {
		x = xVal;
		y = yVal;
	}
	inline void SetXY(const MDVector2& p) {
		x = p.x;
		y = p.y;
	}
	inline void SetXZ(const float& xVal, const float& zVal) {
		x = xVal;
		z = zVal;
	}
	inline void SetXZ(const MDVector2& p) {
		x = p.x;
		z = p.y;
	}
	inline void SetXW(const float& xVal, const float& wVal) {
		x = xVal;
		w = wVal;
	}
	inline void SetXW(const MDVector2& p) {
		x = p.x;
		w = p.y;
	}
	inline void SetYZ(const float& yVal, const float& zVal) {
		y = yVal;
		z = zVal;
	}
	inline void SetYZ(const MDVector2& p) {
		y = p.x;
		z = p.y;
	}
	inline void SetYW(const float& yVal, const float& wVal) {
		y = yVal;
		w = wVal;
	}
	inline void SetYW(const MDVector2& p) {
		y = p.x;
		w = p.y;
	}
	inline void SetZW(const float& zVal, const float& wVal) {
		z = zVal;
		w = wVal;
	}
	inline void SetZW(const MDVector2& p) {
		z = p.x;
		w = p.y;
	}
	inline void SetXYZ(const float& xVal, const float& yVal, const float& zVal) {
		x = xVal;
		y = yVal;
		z = zVal;
	}
	inline void SetXYZ(const MDVector3& p) {
		x = p.x;
		y = p.y;
		z = p.z;
	}
	inline void SetXYW(const float& xVal, const float& yVal, const float& wVal) {
		x = xVal;
		y = yVal;
		w = wVal;
	}
	inline void SetXYW(const MDVector3& p) {
		x = p.x;
		y = p.y;
		w = p.z;
	}
	inline void SetXZW(const float& xVal, const float& zVal, const float& wVal) {
		x = xVal;
		z = zVal;
		w = wVal;
	}
	inline void SetXZW(const MDVector3& p) {
		x = p.x;
		z = p.y;
		w = p.z;
	}
	inline void SetYZW(const float& yVal, const float& zVal, const float& wVal) {
		y = yVal;
		z = zVal;
		w = wVal;
	}
	inline void SetYZW(const MDVector3& p) {
		y = p.x;
		z = p.y;
		w = p.z;
	}
	inline void SetXYZW(const float& xVal, const float& yVal, const float& zVal, const float& wVal) {
		x = xVal;
		y = yVal;
		z = zVal;
		w = wVal;
	}
	inline void SetXYZW(const MDVector4& p) {
		x = p.x;
		y = p.y;
		z = p.z;
		w = p.w;
	}
	inline MDVector4 operator + (const MDVector4& p) const {
		MDVector4 ret;
		ret.x = x + p.x, ret.y = y + p.y, ret.z = z + p.z, ret.w = w + p.w;
		return ret;
	}
	inline MDVector4 operator - (const MDVector4& p) const {
		MDVector4 ret;
		ret.x = x - p.x, ret.y = y - p.y, ret.z = z - p.z, ret.w = w - p.w;
		return ret;
	}
	inline float operator * (const MDVector4& p) const {
		return ((x * p.x) + (y * p.y) + (z * p.z) + (w * p.w));
	}
	inline MDVector4 operator * (const float &p) const {
		MDVector4 ret;
		ret.x = x * p, ret.y = y * p, ret.z = z * p, ret.w = w * p;
		return ret;
	}
	inline MDVector4 operator / (const float &p) const {
		MDVector4 ret;
		ret.x = x / p, ret.y = y / p, ret.z = z / p, ret.w = w / p;
		return ret;
	}
	inline MDVector4 operator = (const MDVector4& p) {
		x = p.x;
		y = p.y;
		z = p.z;
		w = p.w;
		return *this;
	}
	inline MDVector4 operator += (const MDVector4& p) {
		x += p.x;
		y += p.y;
		z += p.z;
		w += p.w;
		return *this;
	}
	inline MDVector4 operator -= (const MDVector4& p) {
		x -= p.x;
		y -= p.y;
		z -= p.z;
		w -= p.w;
		return *this;
	}
	inline MDVector4 operator *= (const float& p) {
		x *= p;
		y *= p;
		z *= p;
		w *= p;
		return *this;
	}
	inline MDVector4 operator /= (const float& p) {
		x /= p;
		y /= p;
		z /= p;
		z /= p;
		return *this;
	}
	inline BOOL operator == (const MDVector4& p) const {
		return (MDFloatCompare(x, p.x) && MDFloatCompare(y, p.y) && MDFloatCompare(z, p.z) && MDFloatCompare(w, p.w));
	}
};
// Enables expressions like (5.0 * v) to work
inline MDVector4 operator * (const float& p, const MDVector4& v) {
	MDVector4 ret;
	ret.x = v.x * p;
	ret.y = v.y * p;
	ret.z = v.z * p;
	ret.w = v.w * p;
	return ret;
}

// Create a four component vector
MDVector4 MDVector4Create(const float& x, const float& y, const float& z, const float& w);
MDVector4 MDVector4Create(const MDVector2& xy, const float& z, const float& w);
MDVector4 MDVector4Create(const MDVector3& xyz, const float& w);
MDVector4 MDVector4Create(const MDVector4& v);

// Luxury Methods
MDVector4 MDVector4CreateXZ(const MDVector2& xz, const float& y, const float& w);
MDVector4 MDVector4CreateXW(const MDVector2& xw, const float& y, const float& z);
MDVector4 MDVector4CreateYZ(const float& x, const MDVector2& yz, const float& w);
MDVector4 MDVector4CreateYW(const float& x, const MDVector2& yw, const float& z);
MDVector4 MDVector4CreateZW(const float& x, const float& y, const MDVector2& zw);
MDVector4 MDVector4CreateXYW(const MDVector3& xyw, const float& z);
MDVector4 MDVector4CreateXZW(const MDVector3& xzw, const float& y);
MDVector4 MDVector4CreateYZW(const float& x, const MDVector3& zyw);

// Calculating Methods
float MDVector4Magnitude(const MDVector4& v);								// Returns the magnitude (length) of the vector
float MDVector4DotProduct(const MDVector4& v1, const MDVector4& v2);		// Returns the dot product of the two vectors
float MDVector4Angle(const MDVector4& v1, const MDVector4& v2);				// Returns the angle (in degrees) in between the two vectors
MDVector4 MDVector4Normalize(const MDVector4& v);							// Returns the normalized vector (has a magnitude of 1)
float MDVector4Distance(const MDVector4& v1, const MDVector4& v2);			// Returns the distance between two vectors

// A 4x4 Column Major Matrix
/*
	[ r1c1(0) r1c2(4) r1c3( 8) r1c4(12) ]
	[ r2c1(1) r2c2(5) r2c3( 9) r2c4(13) ]
	[ r3c1(2) r3c2(6) r3c3(10) r3c4(14) ]
	[ r4c1(3) r4c2(7) r4c3(11) r4c4(15) ]
*/
struct MDMatrix
{
	float data[16];
	
	MDMatrix operator + (const MDMatrix& p) const {
		MDMatrix matrix;		
		for (int z = 0; z < 16; z++)
			matrix.data[z] = data[z] + p.data[z];
		return matrix;
	}
	
	MDMatrix operator - (const MDMatrix& p) const {
		MDMatrix matrix;		
		for (int z = 0; z < 16; z++)
			matrix.data[z] = data[z] - p.data[z];
		return matrix;
	}
	
	MDMatrix operator * (const MDMatrix& p) const {
		MDMatrix matrix;
		
		matrix.data[0] = data[0] * p.data[0] + data[4] * p.data[1] + data[8] * p.data[2] + data[12] * p.data[3];
		matrix.data[1] = data[1] * p.data[0] + data[5] * p.data[1] + data[9] * p.data[2] + data[13] * p.data[3];
		matrix.data[2] = data[2] * p.data[0] + data[6] * p.data[1] + data[10] * p.data[2] + data[14] * p.data[3];
		matrix.data[3] = data[3] * p.data[0] + data[7] * p.data[1] + data[11] * p.data[2] + data[15] * p.data[3];
		
		matrix.data[4] = data[0] * p.data[4] + data[4] * p.data[5] + data[8] * p.data[6] + data[12] * p.data[7];
		matrix.data[5] = data[1] * p.data[4] + data[5] * p.data[5] + data[9] * p.data[6] + data[13] * p.data[7];
		matrix.data[6] = data[2] * p.data[4] + data[6] * p.data[5] + data[10] * p.data[6] + data[14] * p.data[7];
		matrix.data[7] = data[3] * p.data[4] + data[7] * p.data[5] + data[11] * p.data[6] + data[15] * p.data[7];
		
		matrix.data[8] = data[0] * p.data[8] + data[4] * p.data[9] + data[8] * p.data[10] + data[12] * p.data[11];
		matrix.data[9] = data[1] * p.data[8] + data[5] * p.data[9] + data[9] * p.data[10] + data[13] * p.data[11];
		matrix.data[10] = data[2] * p.data[8] + data[6] * p.data[9] + data[10] * p.data[10] + data[14] * p.data[11];
		matrix.data[11] = data[3] * p.data[8] + data[7] * p.data[9] + data[11] * p.data[10] + data[15] * p.data[11];
		
		matrix.data[12] = data[0] * p.data[12] + data[4] * p.data[13] + data[8] * p.data[14] + data[12] * p.data[15];
		matrix.data[13] = data[1] * p.data[12] + data[5] * p.data[13] + data[9] * p.data[14] + data[13] * p.data[15];
		matrix.data[14] = data[2] * p.data[12] + data[6] * p.data[13] + data[10] * p.data[14] + data[14] * p.data[15];
		matrix.data[15] = data[3] * p.data[12] + data[7] * p.data[13] + data[11] * p.data[14] + data[15] * p.data[15];
		
		return matrix;
	}
	
	inline MDMatrix operator * (const float& p) {
		MDMatrix matrix;
		for (int z = 0; z < 16; z++)
			matrix.data[z] = data[z] * p;
		return matrix;
	}
	
	inline MDMatrix operator / (const float& p) {
		MDMatrix matrix;
		for (int z = 0; z < 16; z++)
			matrix.data[z] = data[z] / p;
		return matrix;
	}
	
	inline MDMatrix operator = (const MDMatrix& p) {
		memcpy(data, p.data, sizeof(float) * 16);
		return *this;
	}
	
	inline MDMatrix operator += (const MDMatrix& p) {
		*this = *this + p;
		return *this;
	}
	
	inline MDMatrix operator -= (const MDMatrix& p) {
		*this = *this - p;
		return *this;
	}
	
	inline MDMatrix operator *= (const MDMatrix& p) {
		*this = *this * p;
		return *this;
	}
	
	inline MDMatrix operator *= (const float& p) {
		*this = *this * p;
		return *this;
	}
	
	inline MDMatrix operator /= (const float& p) {
		*this = *this / p;
		return *this;
	}
};

// Create a matrix
MDMatrix MDMatrixCreate(MDMatrix matrix);
MDMatrix MDMatrixCreate(float matrix[16]);
MDMatrix MDMatrixCreate(float row1[4], float row2[4], float row3[4], float row4[4]);
MDMatrix MDMatrixCreate(float r1c1, float r1c2, float r1c3, float r1c4, float r2c1, float r2c2, float r2c3, float r2c4, float r3c1, float r3c2, float r3c3, float r3c4, float r4c1, float r4c2, float r4c3, float r4c4);

// Editing matrices
float MDMatrixValue(MDMatrix matrix, int row, int column);						// Returns the value at the specified row and column of the matrix
void MDMatrixValue(MDMatrix* matrix, int row, int column, float value);			// Sets the value at the specified row and column of the matrix

// Multiply matrices 
MDMatrix MDMatrixMultiply(MDMatrix matrix1, MDMatrix matrix2);					// Multiply matrix by matrix
MDVector4 MDMatrixMultiply(MDMatrix matrix, float x, float y, float z, float w);// Multiply matrix by point (apply transform matrix to point)
MDVector4 MDMatrixMultiply(MDMatrix matrix, MDVector3 point, float w);			// Multiply matrix by point (apply transform matrix to point)
MDVector4 MDMatrixMultiply(MDMatrix matrix, MDVector4 vector);					// Multiply matrix by point (apply transform matrix to point)

// Matrix transformations comperable to OpenGL functions
MDMatrix MDMatrixIdentity();													// Returns the identity matrix (glLoadIdentity())
void MDMatrixTranslate(MDMatrix* matrix, float x, float y, float z);			// Translates a matrix (glTranslate())
void MDMatrixTranslate(MDMatrix* matrix, MDVector3 translate);					// Translates a matrix (glTranslate())
void MDMatrixRotate(MDMatrix* matrix, float x, float y, float z, float angle);	// Rotates a matrix (glRotate()) - angle is in degrees
void MDMatrixRotate(MDMatrix* matrix, MDVector3 axis, float angle);				// Rotates a matrix (glRotate()) - angle is in degrees
void MDMatrixScale(MDMatrix* matrix, float x, float y, float z);				// Scales a matrix (glScale())
void MDMatrixScale(MDMatrix* matrix, MDVector3 scale);							// Scales a matrix (glScale())
void MDMatrixSetPerspective(MDMatrix* matrix, float fovy, float aspectRatio,	// Setups a perspective matrix (gluPerspective())
							float znear, float zfar);
void MDMatrixLookAt(MDMatrix* matrix, MDVector3 eyePosition, MDVector3 center,	// Setups a matrix that looks at the specified position (gluLookAt())
					MDVector3 up);
void MDMatrixSetOthro(MDMatrix* matrix, float left, float right, float bottom,	// Setups a othrographic matrix (gluOrtho2D())
					  float top);
	
// Matrix functions
MDVector3 MDMatrixProject(MDVector3 obj, MDMatrix modelview,					// Maps object coordinates to window coordinates (gluProject())
							MDMatrix projection, int* viewport);
MDVector3 MDMatrixUnProject(MDVector3 win, MDMatrix modelview,					// Maps window coordinates to object coordinates (gluUnproject())
							MDMatrix projection, int* viewport);


float MDMatrixDeterminant(MDMatrix matrix);										// Determinant of a matrix
MDMatrix MDMatrixInverse(MDMatrix matrix);										// Inverse of a matrix (matrix * inverse matrix = identity matrix)
MDMatrix MDMatrixTranspose(MDMatrix matrix);									// Transpose of a matrix

	