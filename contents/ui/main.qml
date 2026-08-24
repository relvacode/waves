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
    property color color: configuration.color ?? "#07152c"
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
            "float ribbon(vec2 uv, float offset, float width, float phase, float speed) {\n" +
            "    float d = uv.y - path(uv.x, offset, phase, speed);\n" +
            "    float feather = max(width * 0.035, 0.001);\n" +
            "    float edge = 1.0 - smoothstep(max(width - feather, 0.0), width, abs(d));\n" +
            "    float across = clamp(abs(d) / max(width, 0.001), 0.0, 1.0);\n" +
            "    float profile = 0.008 + 0.992 * smoothstep(1.0 - gradientFalloff, 1.0, across);\n" +
            "    float sheen = 0.82 + 0.18 * sin(uv.x * 8.0 + phase);\n" +
            "    return edge * profile * sheen;\n" +
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
            "    float body = ribbon(uv, 0.0, evolvingThickness(0.0, 0.32), 0.0, 0.32);\n" +
            "    float shoulder = ribbon(uv, -0.045 * layerSpread, evolvingThickness(1.7, 0.32), 1.7, 0.32);\n" +
            "    float lowerFold = ribbon(uv, 0.075 * layerSpread, evolvingThickness(5.1, 0.32), 5.1, 0.32);\n" +
            "    float lowerShadow = ribbon(uv, 0.115 * layerSpread, evolvingThickness(2.2, 0.20), 2.2, 0.20);\n" +
            "    float broad = max(body, max(shoulder, lowerShadow));\n" +
            "    vec3 waveColor = min(backgroundColor.rgb * waveBrightness, vec3(1.0));\n" +
            "    vec3 pale = mix(waveColor, vec3(1.0), 0.48);\n" +
            "    vec3 blue = mix(backgroundColor.rgb, waveColor, 0.72);\n" +
            "    vec3 shadowColor = mix(backgroundColor.rgb, waveColor, 0.72);\n" +
            "    color += blue * broad * (0.28 + 0.16 * (1.0 - uv.y));\n" +
            "    color += pale * body * 0.38;\n" +
            "    color += pale * shoulder * 0.44;\n" +
            "    color += blue * lowerFold * 0.42;\n" +
            "    color -= shadowColor * lowerShadow * 0.12;\n" +
            "    fragColor = vec4(max(color, vec3(0.0)), 1.0) * qt_Opacity;\n" +
            "}\n"
        fragmentShader: ShaderBuilder.buildFragmentShader(shaderSource)
    }
}
