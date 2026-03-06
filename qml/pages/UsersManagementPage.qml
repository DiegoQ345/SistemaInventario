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
                text: "\uE716"  // People icon
                font.family: "Segoe MDL2 Assets"
                font.pixelSize: 20
                Layout.leftMargin: 16
            }
            
            Label {
                text: "Gestión de Usuarios"
                font.pixelSize: 20
                font.weight: Font.Medium
                Layout.fillWidth: true
            }
            
            Button {
                text: "Nuevo Usuario"
                icon.source: "\uE710"  // Add icon
                font.family: "Segoe MDL2 Assets"
                Material.background: ApplicationWindow.window?.currentColors?.primary ?? Material.primary
                Material.foreground: Material.theme === Material.Dark ? "#000000" : "#FFFFFF"
                Layout.rightMargin: 16
                
                onClicked: userDialog.openForCreate()
            }
        }
    }
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 16
        
        // Barra de búsqueda
        TextField {
            id: searchField
            Layout.fillWidth: true
            placeholderText: "Buscar usuarios..."
            leftPadding: 40
            
            Label {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 12
                text: "\uE721"  // Search icon
                font.family: "Segoe MDL2 Assets"
                font.pixelSize: 16
                opacity: 0.6
            }
        }
        
        // Lista de usuarios
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "transparent"
            border.color: Material.color(Material.Grey, Material.Shade300)
            border.width: 1
            radius: 4
            
            ListView {
                id: usersList
                anchors.fill: parent
                anchors.margins: 1
                clip: true
                
                model: ListModel {
                    id: usersModel
                    
                    Component.onCompleted: {
                        // Datos de ejemplo - En producción vendría de UserRepository
                        append({
                            id: 1,
                            username: "admin",
                            fullName: "Administrador del Sistema",
                            role: "Admin",
                            isActive: true
                        })
                        append({
                            id: 2,
                            username: "vendedor",
                            fullName: "Vendedor Principal",
                            role: "Vendedor",
                            isActive: true
                        })
                        append({
                            id: 3,
                            username: "dev",
                            fullName: "Desarrollador",
                            role: "Programador",
                            isActive: true
                        })
                    }
                }
                
                delegate: ItemDelegate {
                    width: usersList.width
                    height: 80
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 16
                        
                        // Avatar
                        Rectangle {
                            width: 56
                            height: 56
                            radius: 28
                            color: model.isActive ? Material.color(Material.Blue, Material.Shade100) : Material.color(Material.Grey, Material.Shade200)
                            
                            Label {
                                anchors.centerIn: parent
                                text: model.fullName.substring(0, 2).toUpperCase()
                                font.pixelSize: 20
                                font.weight: Font.Bold
                                color: model.isActive ? Material.color(Material.Blue, Material.Shade700) : Material.color(Material.Grey, Material.Shade600)
                            }
                        }
                        
                        // Información del usuario
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            
                            Label {
                                text: model.fullName
                                font.weight: Font.Medium
                                font.pixelSize: 14
                            }
                            
                            RowLayout {
                                spacing: 8
                                
                                Label {
                                    text: "@" + model.username
                                    font.pixelSize: 12
                                    opacity: 0.7
                                }
                                
                                Rectangle {
                                    width: 4
                                    height: 4
                                    radius: 2
                                    color: Material.color(Material.Grey)
                                }
                                
                                Label {
                                    text: model.role
                                    font.pixelSize: 12
                                    color: ApplicationWindow.window?.currentColors?.primary ?? Material.accent
                                    font.weight: Font.Medium
                                }
                            }
                            
                            Label {
                                text: model.isActive ? "Activo" : "Inactivo"
                                font.pixelSize: 11
                                color: model.isActive ? Material.color(Material.Green) : Material.color(Material.Red)
                            }
                        }
                        
                        // Botones de acción
                        RowLayout {
                            spacing: 8
                            
                            Button {
                                text: "\uE70F"  // Edit icon
                                font.family: "Segoe MDL2 Assets"
                                flat: true
                                Material.foreground: Material.accent
                                
                                onClicked: {
                                    userDialog.openForEdit(model.id, model.username, model.fullName, model.role, model.isActive)
                                }
                                
                                ToolTip.visible: hovered
                                ToolTip.text: "Editar usuario"
                            }
                            
                            Button {
                                text: model.isActive ? "\uE8D8" : "\uE73E"  // Block / Checkmark
                                font.family: "Segoe MDL2 Assets"
                                flat: true
                                Material.foreground: model.isActive ? Material.color(Material.Orange) : Material.color(Material.Green)
                                
                                onClicked: {
                                    // Toggle estado activo
                                    usersModel.setProperty(index, "isActive", !model.isActive)
                                    console.log("Toggle activo/inactivo:", model.username)
                                }
                                
                                ToolTip.visible: hovered
                                ToolTip.text: model.isActive ? "Desactivar" : "Activar"
                            }
                            
                            Button {
                                text: "\uE74D"  // Delete icon
                                font.family: "Segoe MDL2 Assets"
                                flat: true
                                Material.foreground: Material.color(Material.Red)
                                enabled: model.username !== "admin"  // No permitir eliminar admin
                                
                                onClicked: {
                                    deleteConfirmDialog.userId = model.id
                                    deleteConfirmDialog.userName = model.username
                                    deleteConfirmDialog.open()
                                }
                                
                                ToolTip.visible: hovered
                                ToolTip.text: "Eliminar usuario"
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Diálogo para crear/editar usuario
    Dialog {
        id: userDialog
        title: isEditMode ? "Editar Usuario" : "Nuevo Usuario"
        width: 500
        modal: true
        standardButtons: Dialog.Ok | Dialog.Cancel
        anchors.centerIn: parent
        
        property bool isEditMode: false
        property int editUserId: -1
        property string errorMessage: ""
        
        function openForCreate() {
            isEditMode = false
            editUserId = -1
            usernameDialogField.text = ""
            fullNameDialogField.text = ""
            passwordDialogField.text = ""
            confirmPasswordDialogField.text = ""
            roleComboBox.currentIndex = 1  // Vendedor por defecto
            activeCheckBox.checked = true
            errorMessage = ""
            usernameDialogField.enabled = true
            passwordRow.visible = true
            confirmPasswordRow.visible = true
            open()
        }
        
        function openForEdit(id, username, fullName, role, isActive) {
            isEditMode = true
            editUserId = id
            usernameDialogField.text = username
            fullNameDialogField.text = fullName
            roleComboBox.currentIndex = role === "Admin" ? 0 : (role === "Vendedor" ? 1 : 2)
            activeCheckBox.checked = isActive
            errorMessage = ""
            usernameDialogField.enabled = false
            passwordRow.visible = false
            confirmPasswordRow.visible = false
            open()
        }
        
        ColumnLayout {
            width: parent.width
            spacing: 16
            
            // Nombre de usuario
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                
                Label {
                    text: "Nombre de Usuario"
                    font.pixelSize: 12
                    font.weight: Font.Medium
                }
                
                TextField {
                    id: usernameDialogField
                    Layout.fillWidth: true
                    placeholderText: "usuario123"
                }
            }
            
            // Nombre completo
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                
                Label {
                    text: "Nombre Completo"
                    font.pixelSize: 12
                    font.weight: Font.Medium
                }
                
                TextField {
                    id: fullNameDialogField
                    Layout.fillWidth: true
                    placeholderText: "Juan Pérez"
                }
            }
            
            // Contraseña (solo en crear)
            ColumnLayout {
                id: passwordRow
                Layout.fillWidth: true
                spacing: 4
                
                Label {
                    text: "Contraseña"
                    font.pixelSize: 12
                    font.weight: Font.Medium
                }
                
                TextField {
                    id: passwordDialogField
                    Layout.fillWidth: true
                    echoMode: TextInput.Password
                    placeholderText: "Mínimo 6 caracteres"
                }
            }
            
            // Confirmar contraseña (solo en crear)
            ColumnLayout {
                id: confirmPasswordRow
                Layout.fillWidth: true
                spacing: 4
                
                Label {
                    text: "Confirmar Contraseña"
                    font.pixelSize: 12
                    font.weight: Font.Medium
                }
                
                TextField {
                    id: confirmPasswordDialogField
                    Layout.fillWidth: true
                    echoMode: TextInput.Password
                    placeholderText: "Repita la contraseña"
                }
            }
            
            // Rol
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                
                Label {
                    text: "Rol"
                    font.pixelSize: 12
                    font.weight: Font.Medium
                }
                
                ComboBox {
                    id: roleComboBox
                    Layout.fillWidth: true
                    model: ["Admin", "Vendedor", "Programador"]
                }
            }
            
            // Estado activo
            CheckBox {
                id: activeCheckBox
                text: "Usuario activo"
                checked: true
            }
            
            // Mensaje de error
            Label {
                text: userDialog.errorMessage
                color: Material.color(Material.Red)
                visible: userDialog.errorMessage !== ""
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                font.pixelSize: 12
            }
        }
        
        onAccepted: {
            errorMessage = ""
            
            // Validaciones
            if (usernameDialogField.text.trim() === "") {
                errorMessage = "Debe ingresar un nombre de usuario"
                open()
                return
            }
            
            if (fullNameDialogField.text.trim() === "") {
                errorMessage = "Debe ingresar el nombre completo"
                open()
                return
            }
            
            if (!isEditMode) {
                if (passwordDialogField.text === "") {
                    errorMessage = "Debe ingresar una contraseña"
                    open()
                    return
                }
                
                if (passwordDialogField.text.length < 6) {
                    errorMessage = "La contraseña debe tener al menos 6 caracteres"
                    open()
                    return
                }
                
                if (passwordDialogField.text !== confirmPasswordDialogField.text) {
                    errorMessage = "Las contraseñas no coinciden"
                    open()
                    return
                }
            }
            
            if (isEditMode) {
                // Actualizar usuario existente
                console.log("Actualizar usuario:", editUserId, usernameDialogField.text, fullNameDialogField.text, roleComboBox.currentText, activeCheckBox.checked)
                // TODO: Llamar a UserRepository.update()
                
                // Actualizar en el modelo de ejemplo
                for (var i = 0; i < usersModel.count; i++) {
                    if (usersModel.get(i).id === editUserId) {
                        usersModel.setProperty(i, "fullName", fullNameDialogField.text)
                        usersModel.setProperty(i, "role", roleComboBox.currentText)
                        usersModel.setProperty(i, "isActive", activeCheckBox.checked)
                        break
                    }
                }
            } else {
                // Crear nuevo usuario
                console.log("Crear usuario:", usernameDialogField.text, passwordDialogField.text, fullNameDialogField.text, roleComboBox.currentText, activeCheckBox.checked)
                // TODO: Llamar a UserRepository.create()
                
                // Agregar al modelo de ejemplo
                usersModel.append({
                    id: usersModel.count + 1,
                    username: usernameDialogField.text,
                    fullName: fullNameDialogField.text,
                    role: roleComboBox.currentText,
                    isActive: activeCheckBox.checked
                })
            }
        }
        
        onRejected: {
            errorMessage = ""
        }
    }
    
    // Diálogo de confirmación de eliminación
    Dialog {
        id: deleteConfirmDialog
        title: "Confirmar Eliminación"
        modal: true
        standardButtons: Dialog.Yes | Dialog.No
        anchors.centerIn: parent
        
        property int userId: -1
        property string userName: ""
        
        Label {
            text: "¿Está seguro que desea eliminar el usuario '@" + deleteConfirmDialog.userName + "'?\n\nEsta acción no se puede deshacer."
            wrapMode: Text.WordWrap
        }
        
        onAccepted: {
            console.log("Eliminar usuario:", userId, userName)
            // TODO: Llamar a UserRepository.deleteById()
            
            // Eliminar del modelo de ejemplo
            for (var i = 0; i < usersModel.count; i++) {
                if (usersModel.get(i).id === userId) {
                    usersModel.remove(i)
                    break
                }
            }
        }
    }
}
