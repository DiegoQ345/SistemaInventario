import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material

Rectangle {
    id: root
    
    // API pública
    function showSuccess(message) {
        label.text = "✓ " + message
        backgroundColor = Material.color(Material.Green, Material.Shade700)
        visible = true
        hideTimer.restart()
    }
    
    function showError(message) {
        label.text = "✗ " + message
        backgroundColor = Material.color(Material.Red, Material.Shade700)
        visible = true
        hideTimer.restart()
    }
    
    function showInfo(message) {
        label.text = message
        backgroundColor = Material.primary
        visible = true
        hideTimer.restart()
    }
    
    // Propiedades
    property color backgroundColor: Material.primary
    property int displayDuration: 3000
    
    // Configuración visual
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.margins: 20
    height: 50
    radius: 8
    color: backgroundColor
    visible: false
    z: 999
    
    // Animación de entrada/salida
    opacity: visible ? 1.0 : 0.0
    Behavior on opacity {
        NumberAnimation { duration: 200 }
    }
    
    Label {
        id: label
        anchors.centerIn: parent
        color: Material.theme === Material.Dark ? Material.background : "white"
        font.pixelSize: 14
        font.weight: Font.Medium
    }
    
    Timer {
        id: hideTimer
        interval: root.displayDuration
        onTriggered: root.visible = false
    }
    
    // Cerrar al hacer clic
    MouseArea {
        anchors.fill: parent
        onClicked: root.visible = false
    }
}
