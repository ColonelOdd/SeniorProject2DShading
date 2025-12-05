#version 450 core
layout(location=0) in vec2 v_texCoords;

layout (set = 2, binding = 0) uniform sampler2D positionTexture;
layout (set = 2, binding = 1) uniform sampler2D colorTexture;
layout (set = 2, binding = 2) uniform sampler2D noiseTexture;

layout (location = 0) out vec4 outColor;

void main() {

    // ---- Tunable parameters ----
    float minSeparation = 1.0;
    float maxSeparation = 3.0;
    float minDistance   = 0.01;
    float maxDistance   = 0.05;
    int   size          = 1;
    vec3  colorModifier = vec3(0.324, 0.063, 0.099);
    float noiseScale    = 10;

    float near = 0.1;
    float far  = 1000.0;

    // ---- Screen UV ----
    vec2 texSize = textureSize(colorTexture, 0).xy;
    vec2 fragCoord = gl_FragCoord.xy;
    vec2 uv = fragCoord / texSize;

    // ---- Noise ----
    vec2 noise = texture(noiseTexture,
                         fragCoord / textureSize(noiseTexture, 0).xy).rb;

    noise = noise * 2.0 - 1.0;   // [-1, 1]
    noise *= noiseScale;

    // ---- Distorted sampling UV ----
    vec2 noisyUV = (fragCoord - noise) / texSize;

    // ---- Base color ----
    vec4 texColor = texture(colorTexture, uv);

    // ---- Position (view-space!) ----
    vec4 pos = texture(positionTexture, noisyUV);

    // Depth from near->far
    float depth = clamp(1.0 - ( (far - pos.z)  / (far - near)), 0.0, 1.0);

    float separation = mix(maxSeparation, minSeparation, depth);

    // ---- Edge detection ----
    float mx = 0.0;

    for (int i = -size; i <= size; ++i) {
        for (int j = -size; j <= size; ++j) {

            vec2 uvTemp = (vec2(i,j) * separation + fragCoord + noise) / texSize;
            vec4 posTemp = texture(positionTexture, uvTemp);


            mx = max(mx, abs(pos.z - posTemp.z));
        }
    }

    float diff = smoothstep(minDistance, maxDistance, mx);

    // ---- Outline tint ----
    vec3 lineColor = texColor.rgb * colorModifier;

    outColor.rgb = mix(texColor.rgb, lineColor, diff);
	//outColor= texture(colorTexture, v_texCoords);
    outColor.a = 1.0;
}
