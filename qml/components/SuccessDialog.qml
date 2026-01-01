import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

Dialog {
    id: control
    
    // Propiedades públicas
    property string message: ""
    property string successIcon: "\uE8FB"  // ✓ checkmark
    property string actionText: ""
    property bool showActionButton: actionText !== ""
    
    // Señales
    signal actionClicked()
    
    // Configuración
    title: qsTr("Éxito")
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
                text: successIcon
                font.family: "Segoe MDL2 Assets"
                font.pixelSize: 48
                color: Material.color(Material.Green)
            }
            
            Label {
                text: control.message
                font.pixelSize: 14
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }
        
        // Botones
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            
            Item { Layout.fillWidth: true }
            
            OutlinedButton {
                text: control.actionText
                visible: control.showActionButton
                Layout.preferredWidth: 120
                accentColor: Material.color(Material.Green)
                
                onClicked: {
                    control.actionClicked()
                }
            }
            
            PrimaryButton {
                text: qsTr("Aceptar")
                Layout.preferredWidth: 100
                Material.background: Material.color(Material.Green)
                
                onClicked: control.close()
            }
        }
    }
}
