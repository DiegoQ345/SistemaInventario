import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material

Button {
    id: control
    
    // Propiedades públicas
    property string iconText: ""
    property bool isIconFont: true
    property color accentColor: Material.primary
    
    // Configuración por defecto
    implicitHeight: 40
    font.pixelSize: 14
    font.weight: Font.Medium
    
    Material.background: "transparent"
    
    // Texto con icono si está definido
    contentItem: Label {
        text: iconText !== "" ? iconText + "  " + control.text : control.text
        font.family: isIconFont && iconText !== "" ? "Segoe MDL2 Assets" : control.font.family
        font.pixelSize: control.font.pixelSize
        font.weight: control.font.weight
        color: Material.theme === Material.Dark ? "#FFFFFF" : "#000000"
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
        border.color: Material.theme === Material.Dark ? "#FFFFFF" : "#000000"
        
        Behavior on color { ColorAnimation { duration: 150 } }
    }
}
