#version 450 core

layout(location=0) in vec3 position;
layout(location=1) in vec2 texCoords;

layout(location=0) out vec2 v_texCoords;

void main()
{
    v_texCoords = texCoords;

	gl_Position = vec4(position.x, position.y, position.z, 1.0f);
}
