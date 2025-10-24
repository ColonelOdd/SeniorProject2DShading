#version 450 core

layout (location = 0) in vec2 v_texCoords;

layout(set = 2, binding=0) uniform sampler2D texSampler; 

layout (location = 0) out vec4 color;

void main()
{
	vec4 texColor = texture(texSampler, v_texCoords);
	color = vec4(texColor.rgb, 1.0);
}
