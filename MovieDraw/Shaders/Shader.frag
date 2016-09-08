
#version 150

struct GLLight
{
	vec4 ambient;
	vec4 diffuse;
	vec4 specular;
	vec4 position;
	vec3 spotDirection;
	float spotExponent;
	float spotCutoff; // (range: [0.0,90.0], 180.0)
	float spotCosCutoff; // (range: [1.0,0.0],-1.0)
	float constantAttenuation;
	float linearAttenuation;
	float quadraticAttenuation;
	int enableShadows;
};

#define MAX_DIR_LIGHTS		%a
#define MAX_POINT_LIGHTS	%b
#define MAX_SPOT_LIGHTS		%c
#define REAL_DIR_LIGHTS		%d
#define REAL_POINT_LIGHTS	%e
#define REAL_SPOT_LIGHTS	%f

uniform GLLight dirLights[REAL_DIR_LIGHTS];
uniform GLLight pointLights[REAL_POINT_LIGHTS];
uniform GLLight spotLights[REAL_SPOT_LIGHTS];

uniform vec3 translate;
uniform vec3 scale;
uniform vec4 rotate;
uniform vec3 midpoint = vec3(0, 0, 0);
uniform vec4 objectColor = vec4(1, 1, 1, 1);
uniform mat4 objMatrix;

// TODO: we can take out translate, scale, and rotate because to multiply a normal by a matrix wihtout including the translate, we only need to do matrix * vec4(normal, 0) instead of matrix * vec4(normal, 1)

uniform vec3 eyePos;

vec3 dirHalfVector[REAL_DIR_LIGHTS];
vec3 pointHalfVector[REAL_POINT_LIGHTS];
vec3 spotHalfVector[REAL_SPOT_LIGHTS];

in vec4 ecPos;
vec4 dDiffuse, dAmbient;
vec3 dHalfVector, normal;


// Should be %d but for now its just 4

struct GLTexture {
	float size;
	int children[3];
	int enabled;
	sampler2D texture;
};

#define MAX_TEXTURES		1
uniform GLTexture diffuseTextures[1];
in vec2 diffuseCoords[1];
uniform GLTexture bumpTextures[1];
in vec2 bumpCoords[1];
/*uniform GLTexture mapTextures[MAX_TEXTURES];
in vec2 mapCoords[MAX_TEXTURES];
uniform GLTexture diffuseMapTextures[MAX_TEXTURES * 3];
in vec2 diffuseMapCoords[MAX_TEXTURES * 3];*/

#pragma insert ShadowFragDec

uniform mat4 modelViewProjection;
uniform vec4 frontMaterialSpecular;
uniform float frontMaterialShininess;

//in vec3 vertexPosition;
in vec3 vertexNormal;
in vec4 vertexColor;

out vec4 finalColor;

vec3 RotateAxis(vec3 p, vec3 line, float an)
{
	if (length(line) == 0.0 || an == 0.0)
		return p;
	
	float theta = an / 180.0 * 3.14159265358979323846264;
	vec3 p1 = normalize(line);
	
	/* Step 1 */
	vec3 q1 = p - p1;
	vec3 u = normalize(p1 * -1.0);
	float d = sqrt(u.y*u.y + u.z*u.z);
	
	vec3 q2;
	/* Step 2 */
	if (d != 0.0)
	{
		q2.x = q1.x;
		q2.y = q1.y * u.z / d - q1.z * u.y / d;
		q2.z = q1.y * u.y / d + q1.z * u.z / d;
	}
	else
		q2 = q1;
	
	/* Step 3 */
	q1.x = q2.x * d - q2.z * u.x;
	q1.y = q2.y;
	q1.z = q2.x * u.x + q2.z * d;
	
	/* Step 4 */
	float ct = cos(theta), st = sin(theta);
	q2.x = q1.x * ct - q1.y * st;
	q2.y = q1.x * st + q1.y * ct;
	q2.z = q1.z;
	
	/* Inverse of step 3 */
	q1.x =   q2.x * d + q2.z * u.x;
	q1.y =   q2.y;
	q1.z = - q2.x * u.x + q2.z * d;
	
	/* Inverse of step 2 */
	if (d != 0.0)
	{
		q2.x =   q1.x;
		q2.y =   q1.y * u.z / d + q1.z * u.y / d;
		q2.z = - q1.y * u.y / d + q1.z * u.z / d;
	}
	else
		q2 = q1;
	
	/* Inverse of step 1 */
	q1 = q2 + p1;
	return(q1);
}

vec4 DoTextures(inout vec3 n)
{
	vec4 color2 = vec4(0, 0, 0, 1);
	
	// Diffuse / Color Map
	if (diffuseTextures[0].enabled == 1)
		color2 += texture(diffuseTextures[0].texture, diffuseCoords[0]);
	
	// Normal / Bump Map
	if (bumpTextures[0].enabled == 1)
	{
		// Rotate the normal to face forwards, apply the map, rotate it back? - works I guess
		vec3 forwards = vec3(0, 0, 1);
		float angle = acos(dot(normal, forwards)) / 3.14159265358979323846264 * 180.0;
		vec3 axis = cross(normal, forwards);
		vec3 temp = normalize(texture(bumpTextures[0].texture, bumpCoords[0]).rgb * 2.0 - 1.0);
		n = normalize(RotateAxis(temp, axis, angle));
		if (normal.z * n.z < 0.0)	// If they don't have the same sign
			n.z = -n.z;
	}
	
	/*
	#pragma insert TextureAlphaMap
	 */
	
	return color2;
}

float VectorToDepthValue(vec3 Vec)
{
    vec3 AbsVec = abs(Vec);
    float LocalZcomp = max(AbsVec.x, max(AbsVec.y, AbsVec.z));
	
    const float f = 1000.0;
    const float n = 0.1;
    float NormZComp = (f+n) / (f-n) - (2*f*n)/(f-n)/LocalZcomp;
    return (NormZComp + 1.0) * 0.5;
}

void main()
{
	normal = normalize(vec3(vertexNormal.x * scale.x, vertexNormal.y * scale.y, vertexNormal.z * scale.z));
	normal = RotateAxis(normal, rotate.xyz, -rotate.w);
		
    vec3 n,halfV,viewV,lightDir;
    float NdotL,NdotHV;
    float att, spotEffect;
	vec3 realPos = vec3(ecPos) * 2.0;
	
    n = normalize(normal);
	
	vec4 totalColor = vec4(0.0, 0.0, 0.0, 0.0);
	
	vec4 color2 = DoTextures(n);
	
	if (color2.rgb == vec3(0.0, 0.0, 0.0))
		color2 = vec4(1.0, 1.0, 1.0, color2.a);
	
	#pragma insert ShadowFragLight
	
	finalColor = vec4((totalColor * color2 * vertexColor).rgb, color2.a * vertexColor.a) * objectColor;
}
