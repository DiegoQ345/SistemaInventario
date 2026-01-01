import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material

Rectangle {
    id: control
    
    // Propiedades públicas
    property int value: 0
    property int maxValue: 99
    property color badgeColor: Material.color(Material.Red)
    
    // Configuración visual
    width: value > 9 ? 20 : 16
    height: 16
    radius: 8
    color: badgeColor
    visible: value > 0
    
    // Número
    Label {
        anchors.centerIn: parent
        text: control.value > control.maxValue ? control.maxValue + "+" : control.value.toString()
        color: Material.theme === Material.Dark ? Material.background : "white"
        font.pixelSize: 10
        font.bold: true
    }
}
