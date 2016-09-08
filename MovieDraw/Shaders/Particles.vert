
#version 150

in vec3 vPos;
in vec4 vColor;

// If named pos, it just doesn't work...
out vec4 color1;
out vec4 color;

uniform mat4 MV;
uniform mat4 P;
uniform float pointSize = 50.0;
uniform float screenWidth = 640.0;

void main()
{	
	color = vColor;
	color1 = vec4(vPos, 1.0);
	
	
	vec4 eyePos = MV * vec4(vPos.x, vPos.y, vPos.z, 1);
	vec4 projCorner = P * vec4(0.5 * pointSize, 0.5 * pointSize, eyePos.z, eyePos.w);
	gl_PointSize = screenWidth * projCorner.x / projCorner.w;
	gl_Position = P * eyePos;
}
