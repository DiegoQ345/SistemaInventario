import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import SistemaInventario

Dialog {
    id: root
    title: qsTr("Nuevo Cliente")
    modal: true
    anchors.centerIn: parent
    width: Math.min(500, parent.width * 0.9)
    
    standardButtons: Dialog.Save | Dialog.Cancel
    
    signal customerCreated(int customerId, string customerName)
    
    // ViewModel para crear cliente
    CustomerFormViewModel {
        id: customerViewModel
        
        onSaved: {
            root.customerCreated(customerViewModel.customerId, customerViewModel.name)
            globalNotification.show("Cliente creado exitosamente", "success")
            root.close()
        }
        
        onErrorOccurred: function(message) {
            globalNotification.show(message, "error")
        }
    }
    
    // Notificación local
    NotificationBar {
        id: globalNotification
    }
    
    onAboutToShow: {
        // Limpiar campos al abrir
        customerViewModel.clear()
        nameField.forceActiveFocus()
    }
    
    onAccepted: {
        // Validar solo campo obligatorio: nombre
        if (nameField.text.trim() === "") {
            globalNotification.show("El nombre es obligatorio", "error")
            return
        }
        
        // Guardar cliente (documento es opcional)
        customerViewModel.name = nameField.text.trim()
        customerViewModel.documentType = documentTypeCombo.currentText
        customerViewModel.documentNumber = documentField.text.trim()
        customerViewModel.phone = phoneField.text.trim()
        customerViewModel.email = emailField.text.trim()
        customerViewModel.address = addressField.text.trim()
        
        customerViewModel.save()
    }
    
    contentItem: Flickable {
        implicitHeight: Math.min(columnLayout.implicitHeight, 500)
        contentHeight: columnLayout.implicitHeight
        clip: true
        
        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
        }
        
        ColumnLayout {
            id: columnLayout
            width: parent.width
            spacing: 16
            
            // Nombre (obligatorio)
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                
                Label {
                    text: qsTr("Nombre *")
                    font.weight: Font.Medium
                    font.pixelSize: 13
                }
                
                TextField {
                    id: nameField
                    Layout.fillWidth: true
                    placeholderText: qsTr("Nombre del cliente")
                    
                    Keys.onReturnPressed: documentField.forceActiveFocus()
                }
            }
            
            // Tipo de documento
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                
                Label {
                    text: qsTr("Tipo de Documento")
                    font.weight: Font.Medium
                    font.pixelSize: 13
                }
                
                ComboBox {
                    id: documentTypeCombo
                    Layout.fillWidth: true
                    model: ["DNI", "RUC", "CE", "PASAPORTE"]
                    currentIndex: 0
                    
                    onCurrentIndexChanged: {
                        // Actualizar placeholder y validación según tipo
                        if (currentIndex === 0) {
                            documentField.placeholderText = "8 dígitos"
                            documentField.validator = dniValidator
                        } else if (currentIndex === 1) {
                            documentField.placeholderText = "11 dígitos"
                            documentField.validator = rucValidator
                        } else {
                            documentField.placeholderText = "Número de documento"
                            documentField.validator = null
                        }
                    }
                }
            }
            
            // Número de documento
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                
                Label {
                    text: qsTr("Número de Documento")
                    font.weight: Font.Medium
                    font.pixelSize: 13
                }
                
                TextField {
                    id: documentField
                    Layout.fillWidth: true
                    placeholderText: "8 dígitos"
                    inputMethodHints: Qt.ImhDigitsOnly
                    
                    validator: RegularExpressionValidator {
                        id: dniValidator
                        regularExpression: /^\d{8}$/
                    }
                    
                    Keys.onReturnPressed: phoneField.forceActiveFocus()
                }
                
                RegularExpressionValidator {
                    id: rucValidator
                    regularExpression: /^\d{11}$/
                }
            }
            
            // Teléfono
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                
                Label {
                    text: qsTr("Teléfono")
                    font.weight: Font.Medium
                    font.pixelSize: 13
                }
                
                TextField {
                    id: phoneField
                    Layout.fillWidth: true
                    placeholderText: qsTr("9 dígitos (opcional)")
                    inputMethodHints: Qt.ImhDialableCharactersOnly
                    
                    validator: RegularExpressionValidator {
                        regularExpression: /^\d{0,9}$/
                    }
                    
                    Keys.onReturnPressed: emailField.forceActiveFocus()
                }
            }
            
            // Email
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                
                Label {
                    text: qsTr("Email")
                    font.weight: Font.Medium
                    font.pixelSize: 13
                }
                
                TextField {
                    id: emailField
                    Layout.fillWidth: true
                    placeholderText: qsTr("correo@ejemplo.com (opcional)")
                    inputMethodHints: Qt.ImhEmailCharactersOnly
                    
                    Keys.onReturnPressed: addressField.forceActiveFocus()
                }
            }
            
            // Dirección
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                
                Label {
                    text: qsTr("Dirección")
                    font.weight: Font.Medium
                    font.pixelSize: 13
                }
                
                TextField {
                    id: addressField
                    Layout.fillWidth: true
                    placeholderText: qsTr("Dirección (opcional)")
                    
                    Keys.onReturnPressed: root.accept()
                }
            }
            
            // Nota informativa
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                color: Material.theme === Material.Dark ? 
                       Qt.lighter(Material.background, 1.2) : 
                       Material.color(Material.Grey, Material.Shade100)
                radius: 4
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8
                    
                    Label {
                        text: "\uE946"  // Info icon
                        font.family: "Segoe MDL2 Assets"
                        font.pixelSize: 16
                        color: Material.accentColor
                    }
                    
                    Label {
                        Layout.fillWidth: true
                        text: qsTr("Solo el nombre es obligatorio")
                        font.pixelSize: 11
                        wrapMode: Text.WordWrap
                        color: Material.secondaryTextColor
                    }
                }
            }
        }
    }
}
