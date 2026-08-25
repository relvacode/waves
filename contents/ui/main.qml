import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.wallpapers.image as PlasmaWallpaper
import org.kde.kwindowsystem

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

        fragmentShader: Qt.resolvedUrl("shaders/wave.qsb")
    }
}
