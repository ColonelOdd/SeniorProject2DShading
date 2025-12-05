#version 450 core

layout (location = 0) in vec2 v_texCoords;

layout(set = 2, binding=0) uniform sampler2D positionTexture; 
layout(set = 2, binding=1) uniform sampler2D colorTexture; 

layout (location = 0) out vec4 color;

void main()
{
	// Parameters for outline
	float minSeparation = 1.0;
	float maxSeparation = 3.0;
	float minDistance   = 0.01;
	float maxDistance   = 0.1;
	int   size          = 1;
	vec3 colorModifier  = vec3(0.324, 0.063, 0.099);

	// Camera near / far, objectively should pass this in as a uniform from uProjection
	float near = 0.1f;
	float far = 1000.0f;

	// Fragment position
	vec2 texSize   = textureSize(colorTexture, 0).xy;
	vec2 fragCoord = v_texCoords.xy;

	vec4 position = texture(positionTexture, v_texCoords);
	vec4 texColor = texture(colorTexture, v_texCoords);

	// Fragment Depth
	float depth = clamp(1.0 - ((far - position.y) / (far - near)), 0.0, 1.0);

	float separation = mix(maxSeparation, minSeparation, depth);

	float mx = 0.0;
    
    for (int i = -size; i <= size; ++i) {
        for (int j = -size; j <= size; ++j) {
            // Sample neighboring pixel
            vec2 offset = vec2(i, j) * (separation / texSize);
            vec2 sampleCoord = (fragCoord + offset);
            
            vec4 positionTemp = texture(positionTexture, sampleCoord);
            
            // Find maximum difference in Y position (depth)
            mx = max(mx, abs(position.y - positionTemp.y));
        }
    }
    
    // Convert difference to edge strength (0 = no edge, 1 = strong edge)
    float diff = smoothstep(minDistance, maxDistance, mx);
    
    // Create outline color by darkening the base color
    vec3 lineColor = texColor.rgb * colorModifier;
    
    // Mix between original color and outline color based on edge strength
    color.rgb = mix(texColor.rgb, lineColor, diff);
    color.a = 1.0;
}
