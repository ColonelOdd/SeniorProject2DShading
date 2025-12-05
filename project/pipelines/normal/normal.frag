#version 450 core

layout (location = 0) in vec2 v_texCoords;
layout (location = 1) in vec3 v_Normals;
layout (location = 2) in vec3 v_FragPos;
layout (location =3 ) in vec3 v_ViewPos;

layout(set = 2, binding=0) uniform sampler2D texSampler; 
//layout(set = 2, binding=1) uniform sampler2D normSampler; 

layout(std140, set = 3, binding = 0) uniform SrcLight {
    vec4 lightColor;
	vec4 lightPosition;
	float ambientIntensity;
	float specularIntensity;
	float specularExponent;
};

layout(set = 3, binding = 1) uniform eye {
	vec3 eyePosition;
};

layout (location = 0) out vec4 positionOut;
layout (location = 1) out vec4 colorOut;

void main()
{
	vec4 texColor = texture(texSampler, v_texCoords);
	vec3 normal = normalize(v_Normals);

	// ambient
    vec3 ambient = ambientIntensity * lightColor.rgb;
    
	// diffuse
    vec3 lightDir = normalize(lightPosition.xyz - v_FragPos);
    float diff = max(dot(normal, lightDir), 0.0);
	vec3 diffuse = diff * lightColor.rgb;

	// specular 
	vec3 viewDir = normalize(eyePosition - v_FragPos);
	vec3 reflectDir = reflect(-lightDir, normal);  

	float spec = pow(max(dot(viewDir, reflectDir), 0.0), specularExponent);
	vec3 specular = specularIntensity * spec * lightColor.rgb;

    vec3 result = texColor.rgb * (ambient + diffuse + specular);

	colorOut = vec4(result, 1.0);
	positionOut = vec4(v_ViewPos, 1.0);
}
