
#version 150

uniform mat4 modelViewProjection;
uniform int enableNormals;
uniform int enableTextures;

in vec3 vPos;
in vec4 vColor;
in vec3 vNormal;
in vec2 vTexCoord;

out vec4 color;
out vec3 normal;
out vec2 texCoord;

void main()
{
	color = vColor;
	normal = vNormal;
	texCoord = vTexCoord;
	gl_Position = modelViewProjection * vec4(vPos, 1.0);
}
