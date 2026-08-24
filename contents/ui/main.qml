import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.wallpapers.image as PlasmaWallpaper
import org.kde.kwindowsystem
import Qt5Compat.GraphicalEffects.private

WallpaperItem {
    id: root

    property real frequency: configuration.frequency ?? 1.15
    property real amplitude: configuration.amplitude ?? 0.12
    property real center: configuration.center ?? 0.575
    property real thickness: configuration.thickness ?? 0.32
    property real gradientFalloff: configuration.gradientFalloff ?? 0.24
    property real speed: configuration.speed ?? 0.22
    property int targetFps: configuration.targetFps ?? 30
    property color color: configuration.color ?? "#003791"
    property real brightness: configuration.brightness ?? 2.0
    property real elapsed: 0

    Behavior on color {
        ColorAnimation {
            duration: 500
            easing.type: Easing.InOutQuad
        }
    }

    Behavior on brightness {
        NumberAnimation {
            duration: 350
            easing.type: Easing.InOutQuad
        }
    }
    readonly property rect desktopRect: Window.window
        ? Qt.rect(Window.window.x, Window.window.y, Window.window.width, Window.window.height)
        : Qt.rect(0, 0, 0, 0)

    PlasmaWallpaper.MaximizedWindowMonitor {
        id: maximizedWindowMonitor
        regionGeometry: root.desktopRect
    }

    readonly property bool animationPaused: maximizedWindowMonitor.count > 0
        && !KWindowSystem.showingDesktop

    Timer {
        interval: Math.max(1, Math.round(1000 / Math.max(1, root.targetFps)))
        repeat: true
        running: root.visible && !root.animationPaused
        onTriggered: root.elapsed += interval / 1000 * root.speed
    }

    ShaderEffect {
        anchors.fill: parent
        property real time: root.elapsed
        property vector2d resolution: Qt.vector2d(width, height)
        property real frequency: root.frequency
        property real amplitude: root.amplitude
        property real waveCenter: root.center
        property real waveThicknessValue: root.thickness
        property real gradientFalloff: root.gradientFalloff
        property color backgroundColor: root.color
        property real waveBrightness: root.brightness

        // Qt 6 needs a QShader rather than legacy gl_FragColor GLSL. Keeping
        // this source in the QML makes the package installable without a
        // separate build step; ShaderBuilder compiles it once at startup.
        property string shaderSource: "#version 440\n" +
            "layout(location = 0) in vec2 qt_TexCoord0;\n" +
            "layout(location = 0) out vec4 fragColor;\n" +
            "layout(std140, binding = 0) uniform buf {\n" +
            "    mat4 qt_Matrix;\n" +
            "    float qt_Opacity;\n" +
            "    float time;\n" +
            "    float frequency;\n" +
            "    float amplitude;\n" +
            "    float waveCenter;\n" +
            "    float waveThicknessValue;\n" +
            "    float gradientFalloff;\n" +
            "    vec2 resolution;\n" +
            "    vec4 backgroundColor;\n" +
            "    float waveBrightness;\n" +
            "};\n" +
            "float path(float x, float offset, float phase, float speed) {\n" +
            "    float f = frequency;\n" +
            "    float breeze = time * 0.40 + 0.12 * sin(time * 0.18);\n" +
            "    float swing = (0.035 + amplitude * 0.46) * 1.5 * (0.86 + 0.14 * sin(time * 0.34));\n" +
            "    float broad = waveCenter - 0.17 * x + swing * sin(x * 5.1 - breeze + phase * 0.12);\n" +
            "    float detail = (0.010 + amplitude * 0.06) * 1.5 * sin(x * 12.0 * f + time * 0.25 + 0.18 * sin(time * 0.36) + phase * 0.16);\n" +
            "    float layerWobble = 0.012 * sin(x * 3.8 - time * 0.18 + 0.25 * sin(time * 0.26) + phase * 1.7) + 0.006 * sin(x * 9.0 + time * 0.12 + 0.12 * sin(time * 0.30) - phase);\n" +
            "    return broad + offset + detail * (0.6 + 0.4 * x) + layerWobble;\n" +
            "}\n" +
            // A cheap 2-D approximation of a shallow, round surface.  The
            // centre is the camera's focus: nearby samples are turned around
            // it and slightly pushed away, which makes the bands read as
            // ribbons passing over a curved volume instead of flat paths.
            "vec2 refractSpace(vec2 uv, float phase, float speed) {\n" +
            "    vec2 p = uv - vec2(0.5, waveCenter);\n" +
            "    p.x *= resolution.x / max(resolution.y, 1.0);\n" +
            "    float radius2 = dot(p, p);\n" +
            "    float depth = exp(-radius2 * 3.2);\n" +
            "    float breeze = time * (0.35 + speed * 0.55) + phase;\n" +
            "    float bend = depth * (0.055 + amplitude * 0.34) * (0.82 + 0.18 * sin(breeze * 0.7));\n" +
            "    vec2 tangent = vec2(-p.y, p.x);\n" +
            "    vec2 radial = p * (0.018 + amplitude * 0.10) * depth * sin(breeze + radius2 * 4.0);\n" +
            "    p += tangent * bend + radial;\n" +
            "    p.x /= resolution.x / max(resolution.y, 1.0);\n" +
            "    return p + vec2(0.5, waveCenter);\n" +
            "}\n" +
            "float ribbon(vec2 uv, float offset, float width, float phase, float speed, out float turnLight) {\n" +
            "    vec2 space = refractSpace(uv, phase, speed);\n" +
            "    float initialD = space.y - path(space.x, offset, phase, speed);\n" +
            "    float side = clamp(initialD / max(width, 0.001), -1.0, 1.0);\n" +
            "    float twist = sin(space.x * (8.0 + frequency * 3.0) - time * (0.72 + speed) + phase);\n" +
            "    float roll = sin(space.x * (5.0 + frequency * 2.0) + side * 2.8 + time * (0.48 + speed * 0.35) + phase * 1.7);\n" +
            "    float surfaceDepth = (0.012 + amplitude * 0.095) * (0.45 + 0.55 * exp(-dot((space - vec2(0.5, waveCenter)) * vec2(resolution.x / max(resolution.y, 1.0), 1.0), (space - vec2(0.5, waveCenter)) * vec2(resolution.x / max(resolution.y, 1.0), 1.0)) * 2.2));\n" +
            // Offset the two sides differently to emulate a strip rotating
            // around its length. This changes the apparent depth throughout
            // the ribbon, not only at its antialiased boundary.
            "    space.y += roll * surfaceDepth * (0.35 + 0.65 * abs(side));\n" +
            "    space.x += twist * surfaceDepth * side * 0.42;\n" +
            "    float d = space.y - path(space.x, offset, phase, speed);\n" +
            "    float feather = max(width * 0.035, 0.001);\n" +
            "    float edge = 1.0 - smoothstep(max(width - feather, 0.0), width, abs(d));\n" +
            "    float across = clamp(abs(d) / max(width, 0.001), 0.0, 1.0);\n" +
            "    float profile = 0.008 + 0.992 * smoothstep(1.0 - gradientFalloff, 1.0, across);\n" +
            "    float radius = length((space - vec2(0.5, waveCenter)) * vec2(resolution.x / max(resolution.y, 1.0), 1.0));\n" +
            "    float sheenWave = sin(space.x * (10.0 + frequency * 4.0) - time * (0.8 + speed) + phase + radius * 7.0);\n" +
            "    float sheen = 0.82 + 0.18 * smoothstep(-0.35, 0.85, sheenWave);\n" +
            "    float normalX = cos(space.x * (5.0 + frequency * 2.0) + side * 2.8 + time * (0.48 + speed * 0.35) + phase * 1.7);\n" +
            "    float normalY = sin(space.x * (8.0 + frequency * 3.0) - time * (0.72 + speed) + phase);\n" +
            "    float facing = 0.08 + 0.92 * (0.5 + 0.5 * (0.62 * normalX + 0.38 * normalY));\n" +
            // The strip's centre remains transparent when turned away. Only
            // a surface facing the light is allowed to reveal it there.
            "    float lightCatch = smoothstep(0.55, 0.95, facing);\n" +
            "    turnLight = edge * lightCatch * (0.82 + 0.18 * sheen);\n" +
            // Apply the turn to the ribbon itself so every band, including
            // the upper layers, is shaded rather than merely overlaid with a
            // highlight.
            "    return edge * profile * sheen * facing;\n" +
            "}\n" +
            "float evolvingThickness(float phase, float speed) {\n" +
            "    float pulse = 0.5 + 0.5 * sin(time * (0.42 + speed * 0.20) + phase);\n" +
            "    return waveThicknessValue * (0.76 + 0.40 * pulse);\n" +
            "}\n" +
            "void main() {\n" +
            "    vec2 uv = qt_TexCoord0;\n" +
            "    const float layerSpread = 1.0;\n" +
            "    vec3 top = backgroundColor.rgb * 1.10;\n" +
            "    vec3 bottom = backgroundColor.rgb * 0.62;\n" +
            "    vec3 color = mix(top, bottom, smoothstep(0.04, 1.0, uv.y));\n" +
            "    color += backgroundColor.rgb * 0.08 * sin(uv.x * 3.0 + uv.y * 5.0);\n" +
            "    float a = max(amplitude, 0.01);\n" +
            "    float bodyTurn;\n" +
            "    float shoulderTurn;\n" +
            "    float lowerFoldTurn;\n" +
            "    float lowerShadowTurn;\n" +
            "    float body = ribbon(uv, 0.0, evolvingThickness(0.0, 0.32), 0.0, 0.32, bodyTurn);\n" +
            "    float shoulder = ribbon(uv, -0.045 * layerSpread, evolvingThickness(1.7, 0.32), 1.7, 0.32, shoulderTurn);\n" +
            "    float lowerFold = ribbon(uv, 0.075 * layerSpread, evolvingThickness(5.1, 0.32), 5.1, 0.32, lowerFoldTurn);\n" +
            "    float lowerShadow = ribbon(uv, 0.115 * layerSpread, evolvingThickness(2.2, 0.20), 2.2, 0.20, lowerShadowTurn);\n" +
            "    float broad = max(body, max(shoulder, lowerShadow));\n" +
            "    vec3 waveColor = min(backgroundColor.rgb * waveBrightness, vec3(1.0));\n" +
            "    vec3 pale = mix(waveColor, vec3(1.0), 0.48);\n" +
            "    vec3 blue = mix(backgroundColor.rgb, waveColor, 0.72);\n" +
            "    vec3 shadowColor = mix(backgroundColor.rgb, waveColor, 0.72);\n" +
            // Moving pseudo-specular light follows the same curved field as
            // the geometry. It costs only a few scalar operations and avoids
            // an additional texture, pass, or framebuffer.
            "    vec2 focus = (uv - vec2(0.5, waveCenter)) * vec2(resolution.x / max(resolution.y, 1.0), 1.0);\n" +
            "    float focusDepth = exp(-dot(focus, focus) * 3.2);\n" +
            "    float glint = smoothstep(0.48, 0.98, sin(time * 1.15 + focus.x * 5.0 - focus.y * 3.0) * 0.5 + 0.5);\n" +
            "    vec3 specular = vec3(0.72, 0.86, 1.0) * glint * focusDepth * 0.22;\n" +
            "    color += blue * broad * (0.28 + 0.16 * (1.0 - uv.y));\n" +
            "    color += pale * body * 0.38;\n" +
            "    color += pale * shoulder * 0.44;\n" +
            "    color += blue * lowerFold * 0.42;\n" +
            "    color -= shadowColor * lowerShadow * 0.12;\n" +
            "    color += pale * (bodyTurn * 0.18 + shoulderTurn * 0.22 + lowerFoldTurn * 0.16);\n" +
            "    color -= shadowColor * lowerShadowTurn * 0.10;\n" +
            "    color += specular * broad;\n" +
            "    fragColor = vec4(max(color, vec3(0.0)), 1.0) * qt_Opacity;\n" +
            "}\n"
        fragmentShader: ShaderBuilder.buildFragmentShader(shaderSource)
    }
}
