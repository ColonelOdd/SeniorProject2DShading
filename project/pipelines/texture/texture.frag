#version 450 core

layout (location = 0) in vec2 v_texCoords;

layout(set = 2, binding=0) uniform sampler2D texSampler; 

layout(std140, set = 1, binding = 0) uniform SrcLight {
     vec3 lightColor;
	vec3 lightPosition;
	float ambientIntensity;
	float specularIntensity;
	float specularExponent;
};

layout (location = 0) out vec4 color;

void main()
{
	vec4 texColor = texture(texSampler, v_texCoords);
	color = vec4(texColor.rgb, 1.0);
}
