import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

Dialog {
    id: control
    
    // Propiedades públicas
    property string message: ""
    property string icon: "\uE8FB"  // ⚠️ warning
    property color iconColor: Material.color(Material.Orange)
    property string confirmText: qsTr("Confirmar")
    property string cancelText: qsTr("Cancelar")
    
    // Señales
    signal confirmed()
    signal cancelled()
    
    // Configuración
    title: qsTr("Confirmación")
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
                text: icon
                font.family: "Segoe MDL2 Assets"
                font.pixelSize: 48
                color: iconColor
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
            
            SecondaryButton {
                text: control.cancelText
                Layout.preferredWidth: 100
                
                onClicked: {
                    control.cancelled()
                    control.close()
                }
            }
            
            PrimaryButton {
                text: control.confirmText
                Layout.preferredWidth: 100
                
                onClicked: {
                    control.confirmed()
                    control.close()
                }
            }
        }
    }
}
