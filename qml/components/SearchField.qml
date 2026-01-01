import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

TextField {
    id: control
    
    // Propiedades públicas
    property string searchIcon: "\uE721"  // 🔍
    property bool showClearButton: text.length > 0
    
    // Configuración por defecto
    placeholderText: qsTr("Buscar...")
    selectByMouse: true
    
    leftPadding: 40
    rightPadding: showClearButton ? 40 : 16
    
    background: Rectangle {
        implicitHeight: 40
        radius: 4
        color: Material.theme === Material.Dark ?
            (control.activeFocus ? Qt.lighter(Material.background, 1.2) : Material.background) :
            (control.activeFocus ? Material.color(Material.Grey, Material.Shade100) : Material.color(Material.Grey, Material.Shade50))
        border.width: control.activeFocus ? 2 : 1
        border.color: control.activeFocus ? Material.primary : Material.frameColor
        
        Behavior on border.color { ColorAnimation { duration: 150 } }
        Behavior on color { ColorAnimation { duration: 150 } }
    }
    
    // Icono de búsqueda
    Label {
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        text: searchIcon
        font.family: "Segoe MDL2 Assets"
        font.pixelSize: 16
        color: control.activeFocus ? Material.primary : Material.color(Material.Grey, Material.Shade600)
        
        Behavior on color { ColorAnimation { duration: 150 } }
    }
    
    // Botón de limpiar
    RoundButton {
        anchors.right: parent.right
        anchors.rightMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        width: 32
        height: 32
        visible: control.showClearButton
        
        text: "\uE711"  // ✕
        font.family: "Segoe MDL2 Assets"
        font.pixelSize: 12
        
        Material.background: "transparent"
        
        onClicked: control.clear()
    }
}
