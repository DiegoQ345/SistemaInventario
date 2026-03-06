import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

Page {
    id: root
    
    signal loginSucceeded()

    Rectangle {
        anchors.fill: parent
        
        // Imagen de fondo
        Image {
            anchors.fill: parent
            source: "qrc:/resources/background.png"
            fillMode: Image.PreserveAspectCrop
            
            // Overlay oscuro para mejorar legibilidad
            Rectangle {
                anchors.fill: parent
                color: "#000000"
                opacity: 0.4
            }
        }

        Rectangle {
            anchors.centerIn: parent
            width: Math.min(450, parent.width * 0.9)
            height: Math.min(550, parent.height * 0.9)
            radius: 16
            color: Material.dialogColor

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 40
                spacing: 24

                // Logo y título
                ColumnLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 8

                    Image {
                        source: "qrc:/resources/logo.png"
                        Layout.preferredWidth: 100
                        Layout.preferredHeight: 100
                        Layout.alignment: Qt.AlignHCenter
                        fillMode: Image.PreserveAspectFit
                    }

                    Label {
                        text: qsTr("Sistema de Inventario")
                        font.pixelSize: 24
                        font.weight: Font.Bold
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Label {
                        text: qsTr("Iniciar Sesión")
                        font.pixelSize: 16
                        opacity: 0.7
                        Layout.alignment: Qt.AlignHCenter
                    }
                }

                Item { Layout.preferredHeight: 20 }

                // Formulario de login
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 16

                    // Usuario
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Label {
                            text: qsTr("Usuario")
                            font.weight: Font.Medium
                        }

                        TextField {
                            id: usernameField
                            Layout.fillWidth: true
                            placeholderText: qsTr("Ingrese su usuario")
                            font.pixelSize: 14
                            leftPadding: 16
                            rightPadding: 16
                            topPadding: 12
                            bottomPadding: 12

                            Keys.onReturnPressed: passwordField.forceActiveFocus()

                            Component.onCompleted: forceActiveFocus()
                        }
                    }

                    // Contraseña
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Label {
                            text: qsTr("Contraseña")
                            font.weight: Font.Medium
                        }

                        TextField {
                            id: passwordField
                            Layout.fillWidth: true
                            placeholderText: qsTr("Ingrese su contraseña")
                            echoMode: TextInput.Password
                            font.pixelSize: 14
                            leftPadding: 16
                            rightPadding: 16
                            topPadding: 12
                            bottomPadding: 12

                            Keys.onReturnPressed: loginButton.clicked()
                        }
                    }

                    // Mensaje de error
                    Label {
                        id: errorLabel
                        Layout.fillWidth: true
                        visible: text.length > 0
                        text: ""
                        color: Material.color(Material.Red)
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: 13
                    }

                    // Botón de login
                    Button {
                        id: loginButton
                        Layout.fillWidth: true
                        text: qsTr("Iniciar Sesión")
                        font.pixelSize: 16
                        font.weight: Font.Medium
                        Material.background: ApplicationWindow.window?.currentColors?.primary ?? Material.primary
                        Material.foreground: Material.theme === Material.Dark ? "#000000" : "#FFFFFF"
                        topPadding: 16
                        bottomPadding: 16
                        enabled: usernameField.text.length > 0 && passwordField.text.length > 0

                        onClicked: {
                            errorLabel.text = ""
                            
                            if (authService.login(usernameField.text, passwordField.text)) {
                                // Login exitoso - la señal se maneja en Main.qml
                                root.loginSucceeded()
                            } else {
                                errorLabel.text = authService.lastError
                                passwordField.text = ""
                                passwordField.forceActiveFocus()
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true }
            }
        }
    }

    Connections {
        target: authService
        
        function onLoginFailed(error) {
            errorLabel.text = error
            passwordField.text = ""
            passwordField.forceActiveFocus()
        }
    }
}
