import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

Page {
    id: root
    title: qsTr("Inventario y Kardex")

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        Label {
            text: qsTr("📦 Inventario y Kardex")
            font.pixelSize: 32
            font.weight: Font.Bold
        }

        Label {
            text: qsTr("Gestión de movimientos de stock")
            font.pixelSize: 16
            opacity: 0.7
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Material.background
            border.color: Material.primary
            border.width: 2
            radius: 8

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 16

                Label {
                    text: "🚧"
                    font.pixelSize: 64
                    Layout.alignment: Qt.AlignHCenter
                }

                Label {
                    text: qsTr("Página en construcción")
                    font.pixelSize: 20
                    font.weight: Font.Medium
                    Layout.alignment: Qt.AlignHCenter
                }

                Label {
                    text: qsTr("Funcionalidades próximamente:\n• Registro de entradas y salidas\n• Kardex valorizado\n• Historial de movimientos\n• Ajustes de inventario")
                    font.pixelSize: 14
                    horizontalAlignment: Text.AlignLeft
                    Layout.alignment: Qt.AlignHCenter
                    opacity: 0.7
                }
            }
        }
    }
}
