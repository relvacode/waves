#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;
    float frequency;
    float amplitude;
    float waveCenter;
    float waveThicknessValue;
    float gradientFalloff;
    vec2 resolution;
    vec4 backgroundColor;
    float waveBrightness;
    float intro;
};

float path(float x, float offset, float phase, float speed) {
    float f = frequency;
    float breeze = time * 0.40 + 0.12 * sin(time * 0.18);
    float swing = (0.035 + amplitude * 0.46) * 1.5 * (0.86 + 0.14 * sin(time * 0.34));
    float broad = waveCenter - 0.17 * x + swing * sin(x * 5.1 - breeze + phase * 0.12);
    float detail = (0.010 + amplitude * 0.06) * 1.5 * sin(x * 12.0 * f + time * 0.25 + 0.18 * sin(time * 0.36) + phase * 0.16);
    float layerWobble = 0.012 * sin(x * 3.8 - time * 0.18 + 0.25 * sin(time * 0.26) + phase * 1.7) + 0.006 * sin(x * 9.0 + time * 0.12 + 0.12 * sin(time * 0.30) - phase);
    return broad + offset + detail * (0.6 + 0.4 * x) + layerWobble;
}

vec2 refractSpace(vec2 uv, float phase, float speed) {
    vec2 p = uv - vec2(0.5, waveCenter);
    p.x *= resolution.x / max(resolution.y, 1.0);

    float radius2 = dot(p, p);
    float depth = exp(-radius2 * 3.2);
    float breeze = time * (0.35 + speed * 0.55) + phase;
    float bend = depth * (0.055 + amplitude * 0.34) * (0.82 + 0.18 * sin(breeze * 0.7));

    vec2 tangent = vec2(-p.y, p.x);
    vec2 radial = p * (0.018 + amplitude * 0.10) * depth * sin(breeze + radius2 * 4.0);

    p += tangent * bend + radial;
    p.x /= resolution.x / max(resolution.y, 1.0);

    return p + vec2(0.5, waveCenter);
}

float ribbon(vec2 uv, float offset, float width, float phase, float speed, out float turnLight) {
    vec2 space = refractSpace(uv, phase, speed);

    float initialD = space.y - path(space.x, offset, phase, speed);
    float side = clamp(initialD / max(width, 0.001), -1.0, 1.0);

    float twist = sin(space.x * (8.0 + frequency * 3.0) - time * (0.72 + speed) + phase);
    float roll = sin(space.x * (5.0 + frequency * 2.0) + side * 2.8 + time * (0.48 + speed * 0.35) + phase * 1.7);

    float surfaceDepth = (0.012 + amplitude * 0.095) *
        (0.45 + 0.55 * exp(
            -dot(
                (space - vec2(0.5, waveCenter)) * vec2(resolution.x / max(resolution.y, 1.0), 1.0),
                (space - vec2(0.5, waveCenter)) * vec2(resolution.x / max(resolution.y, 1.0), 1.0)
            ) * 2.2
        ));

    space.y += roll * surfaceDepth * (0.35 + 0.65 * abs(side));
    space.x += twist * surfaceDepth * side * 0.42;

    float d = space.y - path(space.x, offset, phase, speed);
    float feather = max(width * 0.035, 0.001);
    float edge = 1.0 - smoothstep(max(width - feather, 0.0), width, abs(d));
    float across = clamp(abs(d) / max(width, 0.001), 0.0, 1.0);
    float profile = 0.008 + 0.992 * smoothstep(1.0 - gradientFalloff, 1.0, across);

    float radius = length((space - vec2(0.5, waveCenter)) * vec2(resolution.x / max(resolution.y, 1.0), 1.0));
    float sheenWave = sin(space.x * (10.0 + frequency * 4.0) - time * (0.8 + speed) + phase + radius * 7.0);
    float sheen = 0.82 + 0.18 * smoothstep(-0.35, 0.85, sheenWave);

    float normalX = cos(space.x * (5.0 + frequency * 2.0) + side * 2.8 + time * (0.48 + speed * 0.35) + phase * 1.7);
    float normalY = sin(space.x * (8.0 + frequency * 3.0) - time * (0.72 + speed) + phase);
    float facing = 0.08 + 0.92 * (0.5 + 0.5 * (0.62 * normalX + 0.38 * normalY));

    float lightCatch = smoothstep(0.55, 0.95, facing);
    turnLight = edge * lightCatch * (0.82 + 0.18 * sheen);

    return edge * profile * sheen * facing;
}

float evolvingThickness(float phase, float speed) {
    float pulse = 0.5 + 0.5 * sin(time * (0.42 + speed * 0.20) + phase);
    return waveThicknessValue * (0.76 + 0.40 * pulse);
}

// Break up low-frequency gradients before they are quantized to the display's
// limited color precision. The pattern is screen-stable, so it does not
// introduce temporal noise while the wallpaper is animated.
float dither(vec2 pixel) {
    return fract(52.9829189 * fract(0.06711056 * pixel.x + 0.00583715 * pixel.y)) - 0.5;
}

void main() {
    vec2 uv = qt_TexCoord0;

    const float layerSpread = 1.0;

    // Boot intro: the pattern starts compressed into a small region around
    // the wave center, then rapidly expands to fill the screen, echoing the
    // PlayStation boot sequence. `intro` eases from 0 to 1 on first load.
    float t = clamp(intro, 0.0, 1.0);
    float expand = 1.0 - pow(1.0 - pow(t, 1.4), 3.0);
    float frontRadius = mix(0.05, 2.0, expand);
    float introZoom = frontRadius / 2.0;

    vec2 center = vec2(0.5, waveCenter);
    vec2 scaled = center + (uv - center) * introZoom;

    float aspect = resolution.x / max(resolution.y, 1.0);
    float dist = length((uv - center) * vec2(aspect, 1.0));
    float front = 1.0 - smoothstep(frontRadius, frontRadius + 0.15, dist);
    float introMask = max(front, smoothstep(0.94, 1.0, t));
    float introFade = smoothstep(0.0, 0.06, t) * introMask;

    vec3 top = backgroundColor.rgb * 1.10;
    vec3 bottom = backgroundColor.rgb * 0.62;
    vec3 color = mix(top, bottom, smoothstep(0.04, 1.0, uv.y));
    color += backgroundColor.rgb * 0.08 * sin(uv.x * 3.0 + uv.y * 5.0);

    float a = max(amplitude, 0.01);

    float bodyTurn;
    float shoulderTurn;
    float lowerFoldTurn;
    float lowerShadowTurn;

    float body = ribbon(scaled, 0.0, evolvingThickness(0.0, 0.32), 0.0, 0.32, bodyTurn);
    float shoulder = ribbon(scaled, -0.045 * layerSpread, evolvingThickness(1.7, 0.32), 1.7, 0.32, shoulderTurn);
    float lowerFold = ribbon(scaled, 0.075 * layerSpread, evolvingThickness(5.1, 0.32), 5.1, 0.32, lowerFoldTurn);
    float lowerShadow = ribbon(scaled, 0.115 * layerSpread, evolvingThickness(2.2, 0.20), 2.2, 0.20, lowerShadowTurn);

    float broad = max(body, max(shoulder, lowerShadow));

    vec3 waveColor = min(backgroundColor.rgb * waveBrightness, vec3(1.0));
    vec3 pale = mix(waveColor, vec3(1.0), 0.48);
    vec3 blue = mix(backgroundColor.rgb, waveColor, 0.72);
    vec3 shadowColor = mix(backgroundColor.rgb, waveColor, 0.72);

    vec2 focus = (uv - vec2(0.5, waveCenter)) * vec2(resolution.x / max(resolution.y, 1.0), 1.0);
    float focusDepth = exp(-dot(focus, focus) * 3.2);
    float glint = smoothstep(0.48, 0.98, sin(time * 1.15 + focus.x * 5.0 - focus.y * 3.0) * 0.5 + 0.5);
    vec3 specular = vec3(0.72, 0.86, 1.0) * glint * focusDepth * 0.22;

    // The wave pattern accumulates only while the compressed sample fits
    // inside the expanding front, so the pattern appears as it is reached.
    color += blue * broad * (0.28 + 0.16 * (1.0 - uv.y)) * introFade;
    color += pale * body * 0.38 * introFade;
    color += pale * shoulder * 0.44 * introFade;
    color += blue * lowerFold * 0.42 * introFade;
    color -= shadowColor * lowerShadow * 0.12 * introFade;
    color += pale * (bodyTurn * 0.18 + shoulderTurn * 0.22 + lowerFoldTurn * 0.16) * introFade;
    color -= shadowColor * lowerShadowTurn * 0.10 * introFade;
    color += specular * broad * introFade;

    // Expanding shockwave band that sweeps outward with the intro front.
    float band = (1.0 - smoothstep(0.0, 0.22, abs(dist - frontRadius))) * (1.0 - t) * 0.5;
    color += waveColor * band;

    color += vec3(dither(gl_FragCoord.xy) / 255.0);

    fragColor = vec4(max(color, vec3(0.0)), 1.0) * qt_Opacity;
}
