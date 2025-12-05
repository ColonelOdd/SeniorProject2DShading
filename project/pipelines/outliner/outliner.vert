#version 450 core

layout(location=0) in vec3 position;
layout(location=1) in vec2 texCoords;

layout(location=0) out vec2 v_texCoords;

void main()
{
    v_texCoords = vec2(texCoords.x, 1.0f - texCoords.y);

	gl_Position = vec4(position, 1.0);
}
