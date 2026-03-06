import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material

Button {
    id: control
    
    // Propiedades públicas
    property string iconText: ""

    // Configuración por defecto
    implicitHeight: 40
    font.pixelSize: 14
    font.weight: Font.Medium
    flat: true

    // Texto del botón con icono
    contentItem: Label {
        text: control.iconText !== "" ? control.iconText + "  " + control.text : control.text
        font.family: control.iconText !== "" ? "Segoe MDL2 Assets" : "Segoe UI"
        font.pixelSize: control.font.pixelSize
        font.weight: control.font.weight
        color: Material.theme === Material.Dark ? "white" : "black"
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}
