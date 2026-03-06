import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material

Page {
    id: root
    
    header: ToolBar {
        Material.background: ApplicationWindow.window?.currentColors?.primary ?? Material.primary
        
        RowLayout {
            anchors.fill: parent
            spacing: 12
            
            Label {
                text: "\uE77B"  // Person icon
                font.family: "Segoe MDL2 Assets"
                font.pixelSize: 20
                Layout.leftMargin: 16
            }
            
            Label {
                text: "Mi Perfil"
                font.pixelSize: 20
                font.weight: Font.Medium
                Layout.fillWidth: true
            }
        }
    }
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 24
        
        // Sección de foto de perfil
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 16
            
            Rectangle {
                id: avatarRect
                Layout.alignment: Qt.AlignHCenter
                width: 120
                height: 120
                radius: 60
                color: Material.color(Material.Grey, Material.Shade200)
                border.color: Material.accent
                border.width: 3
                
                Label {
                    anchors.centerIn: parent
                    text: authService.currentUserFullName.substring(0, 2).toUpperCase()
                    font.pixelSize: 48
                    font.weight: Font.Bold
                    color: Material.color(Material.Grey, Material.Shade600)
                }
            }
            
            Button {
                Layout.alignment: Qt.AlignHCenter
                text: "Cambiar Foto"
                flat: true
                Material.foreground: Material.accent
                onClicked: {
                    // TODO: Implementar selección de imagen
                    console.log("Cambiar foto de perfil")
                }
            }
        }
        
        // Formulario de información
        GridLayout {
            Layout.fillWidth: true
            Layout.maximumWidth: 600
            Layout.alignment: Qt.AlignHCenter
            columns: 2
            rowSpacing: 20
            columnSpacing: 16
            
            // Nombre de usuario (solo lectura)
            Label {
                text: "Nombre de Usuario"
                font.weight: Font.Medium
                font.pixelSize: 13
            }
            
            TextField {
                id: usernameField
                Layout.fillWidth: true
                text: authService.currentUserUsername
                readOnly: true
                enabled: false
                placeholderText: "Nombre de usuario"
            }
            
            // Nombre completo
            Label {
                text: "Nombre Completo"
                font.weight: Font.Medium
                font.pixelSize: 13
            }
            
            TextField {
                id: fullNameField
                Layout.fillWidth: true
                text: authService.currentUserFullName
                placeholderText: "Ingrese nombre completo"
            }
            
            // Rol (solo lectura)
            Label {
                text: "Rol"
                font.weight: Font.Medium
                font.pixelSize: 13
            }
            
            TextField {
                id: roleField
                Layout.fillWidth: true
                text: authService.currentUserRole
                readOnly: true
                enabled: false
            }
            
            // Estado (solo lectura)
            Label {
                text: "Estado"
                font.weight: Font.Medium
                font.pixelSize: 13
            }
            
            Label {
                text: "Activo"
                color: Material.color(Material.Green)
                font.pixelSize: 13
                font.weight: Font.Medium
            }
        }
        
        // Botones de acción
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 16
            spacing: 16
            
            Button {
                text: "Guardar Cambios"
                Material.background: ApplicationWindow.window?.currentColors?.primary ?? Material.primary
                Material.foreground: Material.theme === Material.Dark ? "#000000" : "#FFFFFF"
                font.pixelSize: 13
                padding: 12
                
                onClicked: {
                    if (fullNameField.text.trim() === "") {
                        console.log("El nombre completo no puede estar vacío")
                        return
                    }
                    
                    // TODO: Implementar guardado de cambios
                    console.log("Guardar cambios:", fullNameField.text)
                    // Aquí se llamaría a un método del servicio para actualizar el usuario
                }
            }
            
            Button {
                text: "Cancelar"
                flat: true
                font.pixelSize: 13
                
                onClicked: {
                    // Restaurar valores originales
                    fullNameField.text = authService.currentUserFullName
                }
            }
        }
        
        Item {
            Layout.fillHeight: true
        }
    }
}
