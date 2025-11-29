#version 450 core

layout(location=0) in vec3 position;
layout(location=1) in vec2 texCoords;

layout(std140, set = 1, binding = 0) uniform UniformBlock {
    mat4 uModel;
    mat4 uView;
    mat4 uProjection;
};

layout(location=0) out vec2 v_texCoords;

void main()
{
    v_texCoords = texCoords;

    vec4 finalPosition = uProjection * uView * uModel * vec4(position,1.0f);

	gl_Position = finalPosition;
}
