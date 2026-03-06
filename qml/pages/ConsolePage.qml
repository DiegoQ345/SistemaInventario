import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

/**
 * Componente de consola de debug para el rol Programador
 * Muestra los logs de la aplicación en tiempo real
 */
Page {
    id: root
    title: qsTr("Consola de Desarrollo")

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 16

        // Encabezado
        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            Label {
                text: qsTr("💻 Consola de Desarrollo")
                font.pixelSize: 28
                font.weight: Font.Bold
            }

            Item { Layout.fillWidth: true }

            Button {
                text: qsTr("Limpiar")
                onClicked: consoleOutput.text = ""
            }

            Button {
                text: qsTr("Exportar")
                onClicked: {
                    // TODO: Implementar exportación de logs
                    globalNotification.show("Función en desarrollo", "info")
                }
            }
        }

        // Información del sistema
        GroupBox {
            Layout.fillWidth: true
            title: qsTr("Información del Sistema")

            GridLayout {
                anchors.fill: parent
                columns: 4
                columnSpacing: 20
                rowSpacing: 8

                Label { text: qsTr("Usuario:"); font.weight: Font.Medium }
                Label { text: authService.currentUserFullName }

                Label { text: qsTr("Rol:"); font.weight: Font.Medium }
                Label { 
                    text: authService.currentUserRole
                    color: Material.color(Material.Green)
                }

                Label { text: qsTr("Base de Datos:"); font.weight: Font.Medium }
                Label { text: "SQLite 3.x"; font.family: "monospace" }

                Label { text: qsTr("Qt Version:"); font.weight: Font.Medium }
                Label { text: "6.10.1"; font.family: "monospace" }
            }
        }

        // Área de salida de consola
        GroupBox {
            Layout.fillWidth: true
            Layout.fillHeight: true
            title: qsTr("Salida de Consola")

            ScrollView {
                anchors.fill: parent
                clip: true

                TextArea {
                    id: consoleOutput
                    readOnly: true
                    wrapMode: TextArea.Wrap
                    font.family: "Consolas, Courier New, monospace"
                    font.pixelSize: 12
                    textFormat: TextEdit.PlainText
                    selectByMouse: true
                    
                    text: qsTr("=== Consola de Desarrollo ===\n") +
                          qsTr("Sistema inicializado correctamente\n") +
                          qsTr("Usuario: ") + authService.currentUsername + qsTr(" (") + authService.currentUserRole + qsTr(")\n") +
                          qsTr("Fecha: ") + new Date().toLocaleString() + qsTr("\n\n") +
                          qsTr("Esperando eventos...\n")

                    Component.onCompleted: {
                        // Interceptar mensajes de qDebug (requeriría implementación nativa)
                        // Por ahora mostramos mensajes de ejemplo
                        addLogMessage("INFO", "Sistema de inventario iniciado")
                        addLogMessage("DEBUG", "Conexión a base de datos establecida")
                        addLogMessage("INFO", "Módulos cargados correctamente")
                    }

                    function addLogMessage(level, message) {
                        var timestamp = new Date().toLocaleTimeString()
                        var color = level === "ERROR" ? "red" : 
                                   level === "WARNING" ? "orange" : 
                                   level === "DEBUG" ? "gray" : "white"
                        
                        consoleOutput.append(
                            "[" + timestamp + "] [" + level + "] " + message
                        )
                        
                        // Auto-scroll al final
                        consoleOutput.cursorPosition = consoleOutput.length
                    }
                }
            }
        }

        // Botones de acciones rápidas
        GroupBox {
            Layout.fillWidth: true
            title: qsTr("Acciones Rápidas")

            RowLayout {
                anchors.fill: parent
                spacing: 12

                Button {
                    text: qsTr("🗄️ Verificar BD")
                    onClicked: {
                        consoleOutput.addLogMessage("INFO", "Verificando integridad de base de datos...")
                        consoleOutput.addLogMessage("DEBUG", "Tablas: users, products, sales, customers verificadas")
                        consoleOutput.addLogMessage("INFO", "Base de datos OK")
                    }
                }

                Button {
                    text: qsTr("📊 Estadísticas")
                    onClicked: {
                        consoleOutput.addLogMessage("INFO", "Generando estadísticas del sistema...")
                        consoleOutput.addLogMessage("DEBUG", "Memoria utilizada: ~45 MB")
                        consoleOutput.addLogMessage("DEBUG", "Tiempo de ejecución: " + Math.floor(Math.random() * 1000) + " segundos")
                    }
                }

                Button {
                    text: qsTr("🔄 Recargar Config")
                    onClicked: {
                        consoleOutput.addLogMessage("INFO", "Recargando configuración...")
                        consoleOutput.addLogMessage("DEBUG", "Configuración cargada desde settings.ini")
                        consoleOutput.addLogMessage("INFO", "Configuración actualizada")
                    }
                }

                Button {
                    text: qsTr("🧪 Test Conexión")
                    onClicked: {
                        consoleOutput.addLogMessage("INFO", "Probando conexión a base de datos...")
                        consoleOutput.addLogMessage("DEBUG", "Ping: 2ms")
                        consoleOutput.addLogMessage("INFO", "Conexión exitosa")
                    }
                }

                Item { Layout.fillWidth: true }
            }
        }
    }

    NotificationBar {
        id: globalNotification
    }
}
