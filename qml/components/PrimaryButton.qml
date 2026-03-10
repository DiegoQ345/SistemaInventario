import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material

Button {
    id: control
    
    // Propiedades públicas
    property string iconText: ""
    
    // Configuración por defecto con escalado
    implicitHeight: ApplicationWindow.window ? ApplicationWindow.window.appStyle.buttonHeight : 40
    font.pixelSize: ApplicationWindow.window ? ApplicationWindow.window.appStyle.fontBodyLarge : 14
    font.weight: Font.Medium
    
    // Usa el color primario actual del tema
    Material.background: ApplicationWindow.window?.currentColors?.primary ?? Material.primary
    // Texto que contrasta con el fondo del botón
    Material.foreground: Material.theme === Material.Dark ? "#000000" : "#FFFFFF"
    
    // Texto del botón
    text: iconText !== "" ? iconText + "  " + control.text : control.text
    font.family: iconText !== "" ? "Segoe MDL2 Assets" : "Segoe UI"
}
