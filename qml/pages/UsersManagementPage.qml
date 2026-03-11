import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material
import SistemaInventario 1.0

Page {
    id: root
    title: qsTr("Gestión de Usuarios")
    
    UserListModel {
        id: userModel
        
        Component.onCompleted: {
            loadUsers()
        }
    }
    
    Connections {
        target: userModel
        function onOperationCompleted(message) {
            console.log("Operación completada:", message)
        }
        function onErrorOccurred(message) {
            console.log("Error:", message)
        }
    }
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20
        
        // Encabezado con botón de crear
        RowLayout {
            Layout.fillWidth: true
            
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                
                Label {
                    text: "\uE716  " + qsTr("Gestión de Usuarios")
                    font.family: "Segoe MDL2 Assets"
                    font.pixelSize: 38
                    font.weight: Font.Bold
                }
                
                Label {
                    text: qsTr("Administra usuarios, roles y permisos del sistema")
                    font.pixelSize: 16
                    opacity: 0.7
                }
            }
            
            Button {
                text: "\uE710  " + qsTr("Nuevo Usuario")
                font.family: "Segoe MDL2 Assets"
                Material.background: ApplicationWindow.window?.currentColors?.primary ?? Material.primary
                Material.foreground: "white"
                padding: 12
                
                onClicked: {
                    userDialog.editMode = false
                    userDialog.open()
                }
            }
        }
        
        // Barra de búsqueda y filtros
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            
            TextField {
                id: searchField
                Layout.fillWidth: true
                placeholderText: qsTr("Buscar por nombre o usuario...")
                selectByMouse: true
                
                text: userModel.searchText
                onTextChanged: userModel.searchText = text
            }
            
            ComboBox {
                Layout.preferredWidth: 150
                model: ["Todos", "Admin", "Vendedor", "Programador", "Custom"]
                onCurrentTextChanged: {
                    userModel.roleFilter = currentIndex === 0 ? "" : currentText
                }
            }
            
            CheckBox {
                text: qsTr("Mostrar inactivos")
                checked: userModel.showInactive
                onCheckedChanged: userModel.showInactive = checked
            }
            
            Label {
                text: qsTr("%1 usuarios").arg(userModel.count)
                font.weight: Font.Medium
            }
        }
        
        // Lista de usuarios con cabezales
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0
            
            // Cabezales de columna
            Rectangle {
                Layout.fillWidth: true
                height: 40
                color: Material.color(Material.Grey, Material.Shade800)
                
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 12
                    
                    Label {
                        text: qsTr("Usuario")
                        font.weight: Font.Bold
                        color: "white"
                        Layout.preferredWidth: 300
                    }
                    
                    Label {
                        text: qsTr("Rol")
                        font.weight: Font.Bold
                        color: "white"
                        Layout.preferredWidth: 120
                    }
                    
                    Label {
                        text: qsTr("Ventas")
                        font.weight: Font.Bold
                        color: "white"
                        Layout.preferredWidth: 80
                    }
                    
                    Label {
                        text: qsTr("Estado")
                        font.weight: Font.Bold
                        color: "white"
                        Layout.preferredWidth: 80
                    }
                    
                    Label {
                        text: qsTr("Acciones")
                        font.weight: Font.Bold
                        color: "white"
                        Layout.fillWidth: true
                    }
                }
            }
            
            ListView {
                id: usersListView
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: userModel
                
                delegate: ItemDelegate {
                    width: usersListView.width
                    height: 60
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        spacing: 12
                        
                        ColumnLayout {
                            Layout.preferredWidth: 300
                            spacing: 2
                            
                            Label {
                                text: fullName
                                font.weight: Font.Medium
                            }
                            
                            Label {
                                text: "@" + username + (email ? " • " + email : "")
                                opacity: 0.7
                                font.pixelSize: 12
                            }
                        }
                        
                        Label {
                            text: roleDisplay
                            font.pixelSize: 12
                            padding: 6
                            Layout.preferredWidth: 120
                            background: Rectangle {
                                radius: 4
                                color: role === "Admin" ? Material.color(Material.Red, Material.Shade100) :
                                       role === "Vendedor" ? Material.color(Material.Green, Material.Shade100) :
                                       Material.color(Material.Blue, Material.Shade100)
                            }
                        }
                        
                        Label {
                            text: totalSales + " ventas"
                            font.pixelSize: 12
                            Layout.preferredWidth: 80
                        }
                        
                        Label {
                            text: isActive ? qsTr("Activo") : qsTr("Inactivo")
                            font.pixelSize: 12
                            Layout.preferredWidth: 80
                            color: isActive ? Material.color(Material.Green) : Material.color(Material.Grey)
                        }
                    
                        Row {
                            spacing: 4
                            Layout.fillWidth: true
                            
                            ToolButton {
                                text: "\uE70F"
                                font.family: "Segoe MDL2 Assets"
                                ToolTip.text: qsTr("Editar")
                                ToolTip.visible: hovered
                                onClicked: {
                                    userDialog.loadUser(userId)
                                    userDialog.open()
                                }
                            }
                            
                            ToolButton {
                                text: "\uE72E"
                                font.family: "Segoe MDL2 Assets"
                                ToolTip.text: qsTr("Cambiar contraseña")
                                ToolTip.visible: hovered
                                onClicked: {
                                    passwordDialog.userId = userId
                                    passwordDialog.username = username
                                    passwordDialog.open()
                                }
                            }
                            
                            ToolButton {
                                text: "\uE74D"
                                font.family: "Segoe MDL2 Assets"
                                ToolTip.text: qsTr("Eliminar")
                                ToolTip.visible: hovered
                                enabled: userId !== 1
                                onClicked: {
                                    userModel.deleteUser(userId)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Diálogo de usuario (crear/editar)
    Dialog {
        id: userDialog
        title: editMode ? qsTr("Editar Usuario") : qsTr("Nuevo Usuario")
        modal: true
        anchors.centerIn: parent
        width: 500
        
        property bool editMode: false
        property int editUserId: 0
        
        function loadUser(userId) {
            editMode = true
            editUserId = userId
            var data = userModel.getUserData(userId)
            usernameField.text = data.username
            fullNameField.text = data.fullName
            emailField.text = data.email || ""
            activeCheck.checked = data.isActive
            
            var roleIndex = roleCombo.model.indexOf(data.role)
            roleCombo.currentIndex = roleIndex >= 0 ? roleIndex : 0
        }
        
        ColumnLayout {
            width: parent.width
            spacing: 12
            
            TextField {
                id: usernameField
                Layout.fillWidth: true
                placeholderText: qsTr("Nombre de usuario")
                enabled: !userDialog.editMode
            }
            
            TextField {
                id: passwordField
                Layout.fillWidth: true
                placeholderText: qsTr("Contraseña")
                echoMode: TextInput.Password
                visible: !userDialog.editMode
            }
            
            TextField {
                id: fullNameField
                Layout.fillWidth: true
                placeholderText: qsTr("Nombre completo")
            }
            
            TextField {
                id: emailField
                Layout.fillWidth: true
                placeholderText: qsTr("Email (opcional)")
            }
            
            ComboBox {
                id: roleCombo
                Layout.fillWidth: true
                model: userModel.getAvailableRoles()
            }
            
            CheckBox {
                id: activeCheck
                text: qsTr("Usuario activo")
                checked: true
            }
            
            // Permisos personalizados (solo si Custom)
            GroupBox {
                Layout.fillWidth: true
                title: qsTr("Permisos Personalizados")
                visible: roleCombo.currentText === "Custom"
                
                ColumnLayout {
                    width: parent.width
                    
                    Repeater {
                        model: userModel.getAvailablePermissions()
                        
                        CheckBox {
                            text: modelData
                            Layout.fillWidth: true
                            checked: false
                            
                            property string permission: modelData
                        }
                    }
                }
            }
        }
        
        standardButtons: Dialog.Save | Dialog.Cancel
        
        onAccepted: {
            if (editMode) {
                // Obtener permisos seleccionados
                var perms = []
                if (roleCombo.currentText === "Custom") {
                    // Implementar lógica para obtener permisos de los checkboxes
                }
                
                userModel.updateUser(
                    editUserId,
                    usernameField.text,
                    fullNameField.text,
                    emailField.text,
                    roleCombo.currentText,
                    perms,
                    activeCheck.checked
                )
            } else {
                var perms = []
                userModel.createUser(
                    usernameField.text,
                    passwordField.text,
                    fullNameField.text,
                    emailField.text,
                    roleCombo.currentText,
                    perms
                )
            }
        }
        
        onOpened: {
            if (!editMode) {
                usernameField.text = ""
                passwordField.text = ""
                fullNameField.text = ""
                emailField.text = ""
                roleCombo.currentIndex = 1
                activeCheck.checked = true
            }
        }
    }
    
    // Diálogo de cambio de contraseña
    Dialog {
        id: passwordDialog
        title: qsTr("Cambiar Contraseña")
        modal: true
        anchors.centerIn: parent
        width: 400
        
        property int userId: 0
        property string username: ""
        
        ColumnLayout {
            width: parent.width
            spacing: 12
            
            Label {
                text: qsTr("Usuario: %1").arg(passwordDialog.username)
                font.weight: Font.Medium
            }
            
            TextField {
                id: newPasswordField
                Layout.fillWidth: true
                placeholderText: qsTr("Nueva contraseña")
                echoMode: TextInput.Password
            }
            
            TextField {
                id: confirmNewPasswordField
                Layout.fillWidth: true
                placeholderText: qsTr("Confirmar contraseña")
                echoMode: TextInput.Password
            }
        }
        
        standardButtons: Dialog.Save | Dialog.Cancel
        
        onAccepted: {
            if (newPasswordField.text !== confirmNewPasswordField.text) {
                if (notification) notification.show(qsTr("Las contraseñas no coinciden"), false)
                return
            }
            
            if (userModel.changePassword(userId, newPasswordField.text)) {
                if (notification) notification.show(qsTr("Contraseña actualizada"), true)
            }
        }
        
        onOpened: {
            newPasswordField.text = ""
            confirmNewPasswordField.text = ""
        }
    }
}
