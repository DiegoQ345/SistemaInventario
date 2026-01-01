import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material

Item {
    id: control
    
    // Propiedades públicas
    property bool running: true
    property int size: 48
    property color spinnerColor: Material.primary
    property int lineWidth: 4
    
    implicitWidth: size
    implicitHeight: size
    
    // Indicador circular
    BusyIndicator {
        anchors.centerIn: parent
        width: control.size
        height: control.size
        running: control.running
        
        Material.accent: control.spinnerColor
    }
}
