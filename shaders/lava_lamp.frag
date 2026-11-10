#version 460 core
precision mediump float;

#include <flutter/runtime_effect.glsl>

uniform vec2 uResolution;
uniform float uTime;
uniform vec3 uColorA;
uniform vec3 uColorB;
uniform vec3 uBgColor;

out vec4 fragColor;

void main() {
    // Normalize coordinates and preserve aspect ratio
    vec2 uv = (FlutterFragCoord().xy - 0.5 * uResolution.xy) / min(uResolution.x, uResolution.y);

    // Accumulate organic metaball scalar field
    float field = 0.0;
    for (int i = 1; i <= 5; i++) {
        float fi = float(i);
        // Harmonic orbital motion for fluid puddles
        float x = sin(uTime * 0.45 + fi * 1.4) * 0.45 + cos(uTime * 0.25) * 0.15;
        float y = cos(uTime * 0.35 + fi * 2.1) * 0.65 - sin(uTime * 0.2) * 0.1;
        vec2 pos = vec2(x, y);

        float dist = length(uv - pos);
        // Metaball equation
        field += 0.14 / (dist * dist + 0.035);
    }

    // Smoothstep thresholding creates organic fluid merging borders
    float threshold = 1.35;
    float edge = 0.08;
    float intensity = smoothstep(threshold - edge, threshold + edge, field);

    // Dynamic color gradient between uniform colors
    vec3 fluidColor = mix(uColorA, uColorB, sin(uTime * 0.6 + uv.x * 2.0) * 0.5 + 0.5);

    // Blend background with fluid blobs + subtle ambient glow
    vec3 finalColor = mix(uBgColor, fluidColor, intensity);
    finalColor += uColorA * field * 0.06;

    fragColor = vec4(finalColor, 1.0);
}
