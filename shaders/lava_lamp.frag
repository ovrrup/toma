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

    // Accumulate organic metaball scalar field with slow, calm motion
    float field = 0.0;
    for (int i = 1; i <= 4; i++) {
        float fi = float(i);
        // Tranquil harmonic orbital motion
        float x = sin(uTime * 0.15 + fi * 1.5) * 0.4 + cos(uTime * 0.08) * 0.12;
        float y = cos(uTime * 0.12 + fi * 2.0) * 0.5 - sin(uTime * 0.07) * 0.08;
        vec2 pos = vec2(x, y);

        float dist = length(uv - pos);
        // Metaball equation
        field += 0.12 / (dist * dist + 0.04);
    }

    // Gentle smoothstep thresholding creates subtle, soft ambient boundaries
    float threshold = 1.30;
    float edge = 0.12;
    float intensity = smoothstep(threshold - edge, threshold + edge, field);

    // Subtle fluid color mix
    vec3 fluidColor = mix(uColorA, uColorB, sin(uTime * 0.18 + uv.x * 1.2) * 0.5 + 0.5);

    // Blend background with fluid blobs + delicate ambient glow
    vec3 finalColor = mix(uBgColor, fluidColor, intensity * 0.85);
    finalColor += uColorA * field * 0.035;

    fragColor = vec4(finalColor, 1.0);
}
