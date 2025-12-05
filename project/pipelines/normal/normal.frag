#version 450 core

layout (location = 0) in vec2 v_texCoords;
layout (location = 1) in vec3 v_Normals;
layout (location = 2) in vec3 v_FragPos;

layout(set = 2, binding=0) uniform sampler2D texSampler; 
//layout(set = 2, binding=1) uniform sampler2D normSampler; 

layout(std140, set = 3, binding = 0) uniform SrcLight {
    vec4 lightColor;
	vec4 lightPosition;
	float ambientIntensity;
	float specularIntensity;
	float specularExponent;
};

layout (location = 0) out vec4 color;

void main()
{
	vec4 texColor = texture(texSampler, v_texCoords);
	vec3 normal = normalize(v_Normals);

	// ambient
    vec3 ambient = ambientIntensity * lightColor.rgb;
    
	// diffuse
    vec3 lightDir = normalize(lightPosition.xyz - v_FragPos);
    float diff = max(dot(normal, lightDir), 0.0);
	float cellLevels = 2.0;
	diff = floor(diff * cellLevels) / cellLevels;
	vec3 diffuse = diff * lightColor.rgb;
    
    vec3 result = texColor.rgb * (ambient + diffuse);

	color = vec4(result.rgb, 1.0);
}
