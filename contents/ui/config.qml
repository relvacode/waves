import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kquickcontrols as KQuickControls

Item {
    id: root
    implicitWidth: 460
    implicitHeight: form.implicitHeight + 32

    // Keep these as real config properties. Plasma writes the cfg_* values
    // back to the wallpaper configuration when the settings dialog applies.
    property real cfg_waveFrequency: 1.15
    property real cfg_waveAmplitude: 0.12
    property real cfg_waveCenter: 0.575
    property real cfg_waveThickness: 0.32
    property real cfg_gradientFalloff: 0.24
    property real cfg_waveSpeed: 0.22
    property int cfg_targetFps: 30
    property alias cfg_waveColor: waveColor.color
    property alias cfg_backgroundColor: backgroundColor.color

    // Also notify Plasma directly so Apply updates immediately, including
    // when the configuration map has not been populated yet.
    signal configurationChanged()

    GridLayout {
        id: form
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
        columns: 2
        columnSpacing: 16
        rowSpacing: 10

        Controls.Label { text: i18n("Wave frequency") }
        Controls.Slider {
            id: frequency
            from: 0.45; to: 2.0; stepSize: 0.05
            value: root.cfg_waveFrequency
            onMoved: {
                root.cfg_waveFrequency = value
                root.configurationChanged()
            }
            Layout.fillWidth: true
        }
        Controls.Label { text: i18n("Wave amplitude") }
        Controls.Slider {
            id: amplitude
            from: 0.04; to: 0.24; stepSize: 0.01
            value: root.cfg_waveAmplitude
            onMoved: {
                root.cfg_waveAmplitude = value
                root.configurationChanged()
            }
            Layout.fillWidth: true
        }
        Controls.Label { text: i18n("Wave center") }
        Controls.Slider {
            id: center
            from: 0.30; to: 0.75; stepSize: 0.01
            value: root.cfg_waveCenter
            onMoved: {
                root.cfg_waveCenter = value
                root.configurationChanged()
            }
            Layout.fillWidth: true
        }
        Controls.Label { text: i18n("Wave thickness") }
        Controls.Slider {
            id: thickness
            from: 0.08; to: 0.32; stepSize: 0.01
            value: root.cfg_waveThickness
            onMoved: {
                root.cfg_waveThickness = value
                root.configurationChanged()
            }
            Layout.fillWidth: true
        }
        Controls.Label { text: i18n("Gradient falloff") }
        Controls.Slider {
            id: gradientFalloff
            from: 0.05; to: 0.60; stepSize: 0.01
            value: root.cfg_gradientFalloff
            onMoved: {
                root.cfg_gradientFalloff = value
                root.configurationChanged()
            }
            Layout.fillWidth: true
        }
        Controls.Label { text: i18n("Wave speed") }
        Controls.Slider {
            id: speed
            from: 0.05; to: 1.5; stepSize: 0.01
            value: root.cfg_waveSpeed
            onMoved: {
                root.cfg_waveSpeed = value
                root.configurationChanged()
            }
            Layout.fillWidth: true
        }
        Controls.Label { text: i18n("Framerate") }
        Controls.TextField {
            id: fps
            text: root.cfg_targetFps.toString()
            validator: IntValidator { bottom: 1 }
            inputMethodHints: Qt.ImhDigitsOnly
            onTextEdited: {
                if (acceptableInput) {
                    root.cfg_targetFps = parseInt(text, 10)
                    root.configurationChanged()
                }
            }
            onEditingFinished: {
                if (!acceptableInput || parseInt(text, 10) < 1)
                    text = root.cfg_targetFps.toString()
            }
            Layout.fillWidth: true
        }
        Controls.Label { text: i18n("Wave color") }
        KQuickControls.ColorButton {
            id: waveColor
            color: "#dcecff"
            showAlphaChannel: false
            dialogTitle: i18n("Select wave color")
            onAccepted: {
                root.configurationChanged()
            }
            Layout.fillWidth: true
        }
        Controls.Label { text: i18n("Background color") }
        KQuickControls.ColorButton {
            id: backgroundColor
            color: "#07152c"
            showAlphaChannel: false
            dialogTitle: i18n("Select background color")
            onAccepted: {
                root.configurationChanged()
            }
            Layout.fillWidth: true
        }
    }
}
