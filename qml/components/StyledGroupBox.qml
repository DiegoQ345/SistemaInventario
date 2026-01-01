import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material

GroupBox {
    id: control
    
    // Propiedades públicas
    property color accentColor: Material.primary
    property bool showBorder: true
    
    // Estilos personalizados
    font.pixelSize: 14
    font.weight: Font.Medium
    
    background: Rectangle {
        y: control.topPadding - control.bottomPadding
        width: parent.width
        height: parent.height - control.topPadding + control.bottomPadding
        color: "transparent"
        border.width: showBorder ? 1 : 0
        border.color: Material.frameColor
        radius: 4
    }
    
    label: Rectangle {
        x: control.leftPadding
        width: titleLabel.width + 16
        height: titleLabel.height + 4
        color: Material.background
        
        Label {
            id: titleLabel
            x: 8
            y: 2
            text: control.title
            font: control.font
            color: control.accentColor
        }
    }
}
