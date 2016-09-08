
#version 150

uniform mat4 modelViewProjection;
uniform mat4 normalRotation;
uniform mat4 globalRotation;
uniform int enableNormals;
uniform int enableTextures;
uniform sampler2D texture1;
//uniform int isDepth;

in vec4 color;
in vec3 normal;
in vec2 texCoord;

out vec4 finalColor;

void main()
{
	float total = 1;
	if (enableNormals == 1)
		total = min(1.0, max(dot(vec3(globalRotation * vec4(0, 0, 1, 1)), vec3(normalRotation * vec4(normal, 1))), 0.5));
	vec4 texColor = vec4(1, 1, 1, 1);
	if (enableTextures == 1)
	{
		/*if (isDepth == 1)
		{
			float value = (texture(texture1, texCoord).r - 0.8) * 5.0;
			texColor = vec4(value, value, value, 1.0);
		}
		else*/
			texColor = texture(texture1, texCoord);
	}
	
	finalColor = vec4(color.rgb * texColor.rgb * total, color.a * texColor.a);
}
