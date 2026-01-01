import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

Dialog {
    id: control
    
    // Propiedades públicas
    property string errorMessage: ""
    property string errorIcon: "\uE783"  // ❌ error
    
    // Configuración
    title: qsTr("Error")
    modal: true
    anchors.centerIn: parent
    width: 400
    standardButtons: Dialog.NoButton
    
    ColumnLayout {
        width: parent.width
        spacing: 20
        
        // Icono y mensaje
        RowLayout {
            Layout.fillWidth: true
            spacing: 16
            
            Label {
                text: errorIcon
                font.family: "Segoe MDL2 Assets"
                font.pixelSize: 48
                color: Material.color(Material.Red)
            }
            
            Label {
                text: control.errorMessage
                font.pixelSize: 14
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }
        
        // Botón cerrar
        PrimaryButton {
            text: qsTr("Cerrar")
            Layout.preferredWidth: 100
            Layout.alignment: Qt.AlignRight
            Material.background: Material.color(Material.Red)
            
            onClicked: control.close()
        }
    }
}
