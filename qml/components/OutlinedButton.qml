import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material

Button {
    id: control
    
    // Propiedades públicas
    property string icon: ""
    property bool isIconFont: true
    property color accentColor: Material.primary
    
    // Configuración por defecto
    implicitHeight: 40
    font.pixelSize: 14
    font.weight: Font.Medium
    
    Material.background: "transparent"
    Material.foreground: accentColor
    
    // Texto con icono si está definido
    contentItem: Label {
        text: icon !== "" ? icon + "  " + control.text : control.text
        font.family: isIconFont && icon !== "" ? "Segoe MDL2 Assets" : control.font.family
        font.pixelSize: control.font.pixelSize
        font.weight: control.font.weight
        color: control.Material.foreground
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
    
    background: Rectangle {
        implicitHeight: 40
        radius: 4
        color: control.down ? 
            (Material.theme === Material.Dark ?
                Qt.darker(Material.background, 1.3) :
                Material.color(Material.Grey, Material.Shade300)) :
            control.hovered ? 
            (Material.theme === Material.Dark ?
                Qt.lighter(Material.background, 1.2) :
                Material.color(Material.Grey, Material.Shade200)) :
            "transparent"
        border.width: 1
        border.color: control.accentColor
        
        Behavior on color { ColorAnimation { duration: 150 } }
    }
}
