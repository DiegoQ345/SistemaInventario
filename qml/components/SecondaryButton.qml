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

    // Texto del botón
    text: iconText !== "" ? iconText + "  " + control.text : control.text
    font.family: iconText !== "" ? "Segoe MDL2 Assets" : "Segoe UI"
}
