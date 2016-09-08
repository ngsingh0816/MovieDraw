
#version 150

uniform mat4 modelViewProjection;
uniform mat4 normalRotation;
uniform mat4 globalRotation;
uniform int enableNormals;
uniform int enableTextures;
// Temp - isdepth
uniform int isDepth;
uniform int isCube;
uniform sampler2D texture1;
uniform samplerCube textureCube;

in vec4 color;
in vec3 normal;
in vec2 texCoord;

out vec4 finalColor;

void main()
{
	float total = 1;
	if (enableNormals == 1)
		total = max(dot(normalize(vec3(globalRotation * vec4(0, 0, 1, 1))), normalize(vec3(normalRotation * vec4(normal, 1)))), 0.5);
	vec4 texColor = vec4(1, 1, 1, 1);
	if (enableTextures == 1)
	{
		/*if (isCube == 1)
		{
			if (isDepth == 1)
			{
				texColor = texture(textureCube, vec3(0.0, 0.0, 1.0));
				float val = (texColor.r - 0.9) * 10.0;
				finalColor = vec4(val, val, val, 1.0);
				return;
			}
		}
		else*/
		{
			texColor = texture(texture1, texCoord);
			if (isDepth == 1)
			{
				float val = (texColor.r - 0.9) * 10.0;
				finalColor = vec4(val, val, val, 1.0);
				return;
			}
		}
	}
	
	finalColor = vec4(color.rgb * texColor.rgb * total, color.a * texColor.a);
}
