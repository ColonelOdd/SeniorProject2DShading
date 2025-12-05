#version 450 core

layout(location=0) in vec3 position;
layout(location=1) in vec2 texCoords;
layout(location=2) in vec3 normals;


layout(std140, set = 1, binding = 0) uniform UniformBlock {
     layout(row_major) mat4 uModel;
     layout(row_major) mat4 uView;
     layout(row_major) mat4 uProjection;
};

layout(location=0) out vec2 v_texCoords;
layout(location=1) out vec3 v_Normals;
layout(location=2) out vec3 v_FragPos;

void main()
{
    v_texCoords = texCoords;
    v_FragPos = vec3(uModel * vec4(position,1.0));
    v_Normals = mat3(transpose(inverse(uModel))) * normals;

    vec4 finalPosition = uProjection * uView * uModel * vec4(position,1.0f);

	gl_Position = finalPosition;
}
