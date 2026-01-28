import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Effects
import SistemaInventario 1.0

Dialog {
    id: root
    title: qsTr("Configuración de Impresión")
    modal: true
    anchors.centerIn: parent
    width: 500
    height: 650
    
    // Overlay con blur
    Overlay.modal: Rectangle {
        color: Material.theme === Material.Dark ? 
            Qt.rgba(0, 0, 0, 0.5) : 
            Qt.rgba(0.1, 0.1, 0.1, 0.4)
        
        MultiEffect {
            anchors.fill: parent
            source: parent.parent
            blur: 1.0
            blurMax: 64
            blurMultiplier: 1.2
        }
    }

    required property PrintViewModel printViewModel

    property string invoiceNumber: ""
    property string customerName: ""
    property var items: []
    property real subtotal: 0
    property real discount: 0
    property real total: 0
    property int voucherType: PrintViewModel.Boleta
    property string ruc: ""
    property string businessName: ""
    property string address: ""

    ScrollView {
        anchors.fill: parent
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AsNeeded

        ColumnLayout {
            width: root.availableWidth
            spacing: 16

        // Configuración de impresora
        GroupBox {
            Layout.fillWidth: true
            title: qsTr("Impresora")

            ColumnLayout {
                anchors.fill: parent
                spacing: 12

                ComboBox {
                    id: printerComboBox
                    Layout.fillWidth: true
                    model: root.printViewModel.availablePrinters

                    Component.onCompleted: {
                        currentIndex = root.printViewModel.defaultPrinterIndex
                    }

                    onCurrentTextChanged: {
                        if (currentText !== "")
                            root.printViewModel.defaultPrinter = currentText
                    }
                }

                Button {
                    text: "🔄 Actualizar lista"
                    Layout.fillWidth: true
                    flat: true
                    onClicked: root.printViewModel.refreshPrinters()
                }
            }
        }

        // Tamaño de papel
        GroupBox {
            Layout.fillWidth: true
            title: qsTr("Tamaño de Papel")

            ColumnLayout {
                anchors.fill: parent
                spacing: 8

                ButtonGroup {
                    id: paperSizeGroup
                }

                RadioButton {
                    text: qsTr("A4 (210 x 297 mm)")
                    checked: root.printViewModel.paperSize === PrintViewModel.A4
                    ButtonGroup.group: paperSizeGroup
                    onClicked: root.printViewModel.paperSize = PrintViewModel.A4
                }

                RadioButton {
                    text: qsTr("Carta (216 x 279 mm)")
                    checked: root.printViewModel.paperSize === PrintViewModel.Letter
                    ButtonGroup.group: paperSizeGroup
                    onClicked: root.printViewModel.paperSize = PrintViewModel.Letter
                }

                RadioButton {
                    text: qsTr("Ticket Térmico 80mm")
                    checked: root.printViewModel.paperSize === PrintViewModel.Thermal80mm
                    ButtonGroup.group: paperSizeGroup
                    onClicked: root.printViewModel.paperSize = PrintViewModel.Thermal80mm
                }

                RadioButton {
                    text: qsTr("Ticket Térmico 58mm")
                    checked: root.printViewModel.paperSize === PrintViewModel.Thermal58mm
                    ButtonGroup.group: paperSizeGroup
                    onClicked: root.printViewModel.paperSize = PrintViewModel.Thermal58mm
                }
            }
        }

        // Vista previa compacta
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Material.theme === Material.Dark ?
                Qt.lighter(Material.background, 1.1) :
                Material.color(Material.Grey, Material.Shade100)
            radius: 8
            border.width: 1
            border.color: Material.frameColor

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 8

                Label {
                    text: qsTr("Vista Previa")
                    font.pixelSize: 14
                    font.weight: Font.Bold
                }

                Label {
                    text: root.voucherType === PrintViewModel.Factura ? "FACTURA" : "BOLETA"
                    font.pixelSize: 12
                    font.weight: Font.Bold
                }

                Label {
                    text: "Nº " + root.invoiceNumber
                    font.pixelSize: 11
                }

                Label {
                    text: root.items.length + " productos"
                    font.pixelSize: 11
                    opacity: 0.7
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Material.frameColor
                }

                Label {
                    text: "Total: S/" + root.total.toFixed(2)
                    font.pixelSize: 16
                    font.weight: Font.Bold
                    color: Material.primary
                }
            }
        }

        // Botones de acción
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Button {
                text: "\uE8A5  " + qsTr("Vista Previa PDF")
                font.family: "Segoe MDL2 Assets"
                Layout.fillWidth: true
                flat: true
                Material.foreground: Material.primary

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
                    border.color: Material.primary

                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                onClicked: {
                    var pdfPath = root.printViewModel.previewPdf(
                        root.invoiceNumber,
                        root.customerName,
                        root.items,
                        root.subtotal,
                        root.discount,
                        root.total,
                        root.voucherType,
                        root.ruc,
                        root.businessName,
                        root.address
                    )
                    if (pdfPath !== "") {
                        console.log("PDF generado y abierto:", pdfPath)
                    }
                }
            }

            Button {
                text: "\uE749  " + qsTr("Imprimir")
                font.family: "Segoe MDL2 Assets"
                Layout.fillWidth: true
                Material.background: Material.primary
                Material.foreground: "white"

                onClicked: {
                    var success = root.printViewModel.printVoucher(
                        root.invoiceNumber,
                        root.customerName,
                        root.items,
                        root.subtotal,
                        root.discount,
                        root.total,
                        root.voucherType,
                        root.ruc,
                        root.businessName,
                        root.address
                    )
                    if (success) {
                        root.close()
                    }
                }
            }

            Button {
                text: qsTr("Cancelar")
                Layout.preferredWidth: 100
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
}
