
#version 150

in vec4 color1;
in vec4 color;

out vec4 finalColor;

void main()
{
	finalColor = color1;
	if (dot(gl_PointCoord - 0.5, gl_PointCoord - 0.5) > 0.25)
		discard;
	finalColor = color;
}
