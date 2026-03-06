import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import SistemaInventario 1.0

Dialog {
    id: root
    title: qsTr("Configuración de Impresora")
    modal: true
    anchors.centerIn: parent
    width: 450
    height: 600
    
    // Activar blur en la página de fondo
    property var parentPage: null
    
    onOpened: {
        if (parentPage) parentPage.layer.enabled = true
    }
    onClosed: {
        if (parentPage) parentPage.layer.enabled = false
    }
    
    // Overlay con color semitransparente
    Overlay.modal: Rectangle {
        color: Material.theme === Material.Dark ? 
            Qt.rgba(0, 0, 0, 0.6) : 
            Qt.rgba(0.05, 0.05, 0.05, 0.5)
    }

    required property PrintViewModel printViewModel

    ScrollView {
        anchors.fill: parent
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AsNeeded

        ColumnLayout {
            width: root.availableWidth
            spacing: 16

        Label {
            text: qsTr("Configuración predeterminada de impresión")
            font.pixelSize: 13
            opacity: 0.8
            Layout.fillWidth: true
        }

        GroupBox {
            Layout.fillWidth: true
            title: qsTr("Impresora Predeterminada")

            ColumnLayout {
                anchors.fill: parent
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

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
                        text: "\uE72C"
                        font.family: "Segoe MDL2 Assets"
                        font.pixelSize: 16
                        implicitWidth: 40
                        implicitHeight: 40
                        ToolTip.visible: hovered
                        ToolTip.text: qsTr("Actualizar lista de impresoras")
                        onClicked: root.printViewModel.refreshPrinters()
                    }
                }
            }
        }

        GroupBox {
            Layout.fillWidth: true
            title: qsTr("Tamaño de Papel Predeterminado")

            ColumnLayout {
                anchors.fill: parent
                spacing: 6

                RadioButton {
                    text: qsTr("A4 (210 x 297 mm)")
                    checked: root.printViewModel.paperSize === PrintViewModel.A4
                    onClicked: root.printViewModel.paperSize = PrintViewModel.A4
                }

                RadioButton {
                    text: qsTr("Ticket Térmico 80mm")
                    checked: root.printViewModel.paperSize === PrintViewModel.Thermal80mm
                    onClicked: root.printViewModel.paperSize = PrintViewModel.Thermal80mm
                }
            }
        }

        GroupBox {
            Layout.fillWidth: true
            title: qsTr("Información del Negocio")

            GridLayout {
                anchors.fill: parent
                columns: 2
                rowSpacing: 8
                columnSpacing: 12

                Label { text: "Nombre:" }
                TextField {
                    id: businessNameInput
                    Layout.fillWidth: true
                    text: "SISTEMA DE INVENTARIO"
                }

                Label { text: "RUC:" }
                TextField {
                    id: businessTaxIdInput
                    Layout.fillWidth: true
                    text: "20123456789"
                }

                Label { text: "Dirección:" }
                TextField {
                    id: businessAddressInput
                    Layout.fillWidth: true
                    text: "Av. Principal 123"
                }

                Label { text: "Teléfono:" }
                TextField {
                    id: businessPhoneInput
                    Layout.fillWidth: true
                    text: "(01) 234-5678"
                }

                Label { text: "Email:" }
                TextField {
                    id: businessEmailInput
                    Layout.fillWidth: true
                    text: "ventas@sistemainventario.com"
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Button {
                text: qsTr("Guardar")
                Layout.fillWidth: true
                Material.background: Material.primary
                Material.foreground: Material.theme === Material.Dark ? "#000000" : "#FFFFFF"

                onClicked: {
                    root.printViewModel.setBusinessInfo(
                        businessNameInput.text,
                        businessTaxIdInput.text,
                        businessAddressInput.text,
                        businessPhoneInput.text,
                        businessEmailInput.text
                    )
                    root.close()
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
