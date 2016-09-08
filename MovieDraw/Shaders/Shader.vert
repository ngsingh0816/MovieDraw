
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
//uniform int enableDefaultLight;

uniform GLLight dirLights[REAL_DIR_LIGHTS];
uniform GLLight pointLights[REAL_POINT_LIGHTS];
uniform GLLight spotLights[REAL_SPOT_LIGHTS];

//uniform int noLights;
uniform vec3 translate;
uniform vec3 scale;
uniform vec4 rotate;
uniform vec3 midpoint = vec3(0, 0, 0);
uniform vec4 objectColor = vec4(1, 1, 1, 1);
uniform mat4 objMatrix;

struct GLTexture {
	float size;
	int children[3];
	int enabled;
	sampler2D texture;
};

// Should be %d but for now its just 1
#define MAX_TEXTURES		1
uniform GLTexture diffuseTextures[1];
out vec2 diffuseCoords[1];
uniform GLTexture bumpTextures[1];
out vec2 bumpCoords[1];
/*uniform GLTexture mapTextures[MAX_TEXTURES];
out vec2 mapCoords[MAX_TEXTURES];
uniform GLTexture diffuseMapTextures[MAX_TEXTURES * 3];
out vec2 diffuseMapCoords[MAX_TEXTURES * 3];*/

uniform mat4 modelViewProjection;

in vec3 vPos;
in vec4 vColor;
in vec3 vNormal;
in vec2 vTex;
in mat4 vBoneMatrix;

//out vec3 vertexPosition;
out vec3 vertexNormal;
out vec4 vertexColor;
out vec4 ecPos;

#pragma insert ShadowVertDec

void main()
{
	//vertexPosition = vPos;
	vertexNormal = (vBoneMatrix * vec4(vNormal, 0)).xyz;
	vertexColor = vColor;
	
	
	// Setup texture coordinates
	diffuseCoords[0] = vTex.st * diffuseTextures[0].size;
	bumpCoords[0] = vTex.st * bumpTextures[0].size;
	/*
#pragma insert TextureCoordSetup
	 */
	
	vec4 realPos = vec4((vBoneMatrix * vec4(vPos, 1)).xyz, 1);
	
	vec4 tempVert = objMatrix * realPos;
	ecPos = tempVert;
	
#pragma insert ShadowVertSetup
	
	gl_Position = modelViewProjection * realPos;
}
