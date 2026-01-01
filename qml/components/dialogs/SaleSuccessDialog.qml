import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import SistemaInventario 1.0

Dialog {
    id: root
    title: qsTr("✓ Venta Exitosa")
    modal: true
    anchors.centerIn: parent
    width: 400

    property string invoiceNumber: "FACT-0001"
    property real total: 0.0
    property string voucherType: "BOLETA"
    property string ruc: ""
    property string businessName: ""
    property string address: ""
    property string customerName: "Cliente General"
    property real subtotal: 0.0
    property real discount: 0.0
    property var items: []

    signal printRequested()

    ColumnLayout {
        anchors.fill: parent
        spacing: 16

        Label {
            text: qsTr("La venta se ha registrado correctamente")
            font.pixelSize: 14
            Layout.fillWidth: true
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 100
            color: Material.theme === Material.Dark ?
                Qt.rgba(0.2, 0.8, 0.4, 0.2) :
                Material.color(Material.Green, Material.Shade100)
            radius: 8
            border.width: 2
            border.color: Material.color(Material.Green, Material.Shade500)

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 8

                Label {
                    text: root.voucherType
                    font.pixelSize: 16
                    font.weight: Font.Bold
                    Layout.alignment: Qt.AlignHCenter
                    color: Material.theme === Material.Dark ?
                        Material.color(Material.Green, Material.Shade300) :
                        Material.color(Material.Green, Material.Shade900)
                }

                Label {
                    text: qsTr("Nº: ") + root.invoiceNumber
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    Layout.alignment: Qt.AlignHCenter
                }

                Label {
                    text: qsTr("Total: S/") + root.total.toFixed(2)
                    font.pixelSize: 18
                    font.weight: Font.Bold
                    Layout.alignment: Qt.AlignHCenter
                    color: Material.primary
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            visible: root.voucherType === "FACTURA"

            Label {
                text: qsTr("RUC: ") + root.ruc
                font.pixelSize: 12
            }

            Label {
                text: qsTr("Razón Social: ") + root.businessName
                font.pixelSize: 12
            }

            Label {
                text: qsTr("Dirección: ") + root.address
                font.pixelSize: 12
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Button {
                text: "\uE749  " + qsTr("Imprimir")
                font.family: "Segoe MDL2 Assets"
                Layout.fillWidth: true
                Material.background: Material.primary
                Material.foreground: "white"

                onClicked: {
                    root.printRequested()
                    root.close()
                }
            }

            Button {
                text: qsTr("Cerrar")
                Layout.fillWidth: true
                flat: true

                background: Rectangle {
                    implicitHeight: 40
                    radius: 4
                    color: parent.down ? 
                        (Material.theme === Material.Dark ?
                            Qt.darker(Material.background, 1.3) :
                            Material.color(Material.Grey, Material.Shade300)) :
                        parent.hovered ? 
                        (Material.theme === Material.Dark ?
                            Qt.lighter(Material.background, 1.2) :
                            Material.color(Material.Grey, Material.Shade200)) :
                        Qt.transparent
                    border.width: 1
                    border.color: Material.frameColor

                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                onClicked: root.close()
            }
        }
    }
}
