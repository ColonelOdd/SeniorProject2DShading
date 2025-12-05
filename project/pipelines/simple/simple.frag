#version 450 core
layout(location=0) in vec2 v_texCoords;

layout (set = 2, binding = 0) uniform sampler2D positionTexture;
layout (set = 2, binding = 1) uniform sampler2D colorTexture;
layout (set = 2, binding = 2) uniform sampler2D noiseTexture;

layout (location = 0) out vec4 outColor;

void main() {
	outColor= texture(colorTexture, v_texCoords);
    outColor.a = 1.0;
}
