import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

Dialog {
    id: root
    title: qsTr("✗ Error en la Venta")
    modal: true
    anchors.centerIn: parent
    width: 400

    property string errorMessage: ""

    ColumnLayout {
        anchors.fill: parent
        spacing: 16

        // Icono de error
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 80
            color: Material.theme === Material.Dark ?
                Qt.rgba(0.8, 0.2, 0.2, 0.2) :
                Material.color(Material.Red, Material.Shade100)
            radius: 8
            border.width: 2
            border.color: Material.color(Material.Red, Material.Shade500)

            Label {
                anchors.centerIn: parent
                text: "\uE783"  // Error icon
                font.family: "Segoe MDL2 Assets"
                font.pixelSize: 48
                color: Material.theme === Material.Dark ?
                    Material.color(Material.Red, Material.Shade300) :
                    Material.color(Material.Red, Material.Shade700)
            }
        }

        Label {
            text: root.errorMessage
            font.pixelSize: 14
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            color: Material.foreground
            horizontalAlignment: Text.AlignHCenter
        }

        Button {
            text: qsTr("Cerrar")
            Layout.fillWidth: true
            Material.background: Material.color(Material.Red)
            Material.foreground: "white"

            onClicked: root.close()
        }
    }
}
