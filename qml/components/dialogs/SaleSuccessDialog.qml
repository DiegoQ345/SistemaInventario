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
    
    // Activar blur en la página de fondo
    property var parentPage: null
    
    onOpened: {
        if (parentPage) parentPage.layer.enabled = true
    }
    onClosed: {
        if (parentPage) parentPage.layer.enabled = false
    }
    
    // Overlay con color semitransparente oscuro
    Overlay.modal: Rectangle {
        color: Material.theme === Material.Dark ? 
            Qt.rgba(0, 0, 0, 0.6) : 
            Qt.rgba(0.05, 0.05, 0.05, 0.5)
    }

    property string invoiceNumber: "FACT-0001"
    property real total: 0.0
    property string voucherType: "BOLETA"
    property string ruc: ""
    property string businessName: ""
    property string address: ""
    property string customerName: "Cliente General"
    property real subtotal: 0.0
    property real discount: 0.0
    property real amountPaid: 0.0
    property real changeGiven: 0.0
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
            }
        }
        
        // Resumen de pago - Destacado
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: paymentSummaryLayout.implicitHeight + 32
            color: Material.theme === Material.Dark ?
                Qt.rgba(0.2, 0.5, 1.0, 0.15) :
                Material.color(Material.Blue, Material.Shade50)
            radius: 6
            border.width: 2
            border.color: ApplicationWindow.window?.currentColors?.primary ?? Material.primary
            
            ColumnLayout {
                id: paymentSummaryLayout
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 16
                spacing: 10
                
                Label {
                    text: "\uE8C0  RESUMEN DE PAGO"  // Calculator/Money icon
                    font.family: "Segoe MDL2 Assets"
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    Layout.alignment: Qt.AlignHCenter
                    color: ApplicationWindow.window?.currentColors?.primary ?? Material.primary
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Material.frameColor
                }
                
                // Subtotal
                RowLayout {
                    Layout.fillWidth: true
                    
                    Label {
                        text: qsTr("Subtotal:")
                        font.pixelSize: 13
                        Layout.fillWidth: true
                    }
                    
                    Label {
                        text: "S/ " + root.subtotal.toFixed(2)
                        font.pixelSize: 13
                        font.weight: Font.Medium
                    }
                }
                
                // Descuento
                RowLayout {
                    Layout.fillWidth: true
                    visible: root.discount > 0
                    Layout.preferredHeight: root.discount > 0 ? implicitHeight : 0
                    
                    Label {
                        text: qsTr("Descuento:")
                        font.pixelSize: 13
                        color: Material.color(Material.Orange)
                        Layout.fillWidth: true
                    }
                    
                    Label {
                        text: "- S/ " + root.discount.toFixed(2)
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        color: Material.color(Material.Orange)
                    }
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 2
                    color: Material.frameColor
                }
                
                // Total
                RowLayout {
                    Layout.fillWidth: true
                    
                    Label {
                        text: qsTr("TOTAL:")
                        font.pixelSize: 16
                        font.weight: Font.Bold
                        Layout.fillWidth: true
                    }
                    
                    Label {
                        text: "S/ " + root.total.toFixed(2)
                        font.pixelSize: 18
                        font.weight: Font.Bold
                        color: ApplicationWindow.window?.currentColors?.primary ?? Material.primary
                    }
                }
                
                // Separador antes de información de pago
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Material.frameColor
                }
                
                // Monto pagado - SIEMPRE VISIBLE
                RowLayout {
                    Layout.fillWidth: true
                    
                    Label {
                        text: "\uE8CB  " + qsTr("Pagado con:")  // Money icon
                        font.family: "Segoe MDL2 Assets"
                        font.pixelSize: 14
                        font.weight: Font.Medium
                        Layout.fillWidth: true
                    }
                    
                    Label {
                        text: "S/ " + root.amountPaid.toFixed(2)
                        font.pixelSize: 16
                        font.weight: Font.Bold
                        color: Material.theme === Material.Dark ?
                            Material.color(Material.Blue, Material.Shade300) :
                            Material.color(Material.Blue, Material.Shade700)
                    }
                }
                
                // Vuelto - Solo visible si hay vuelto
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.changeGiven > 0 ? 50 : 0
                    visible: root.changeGiven > 0
                    color: Material.theme === Material.Dark ?
                        Qt.rgba(0.2, 0.8, 0.4, 0.2) :
                        Material.color(Material.Green, Material.Shade50)
                    radius: 4
                    border.width: 2
                    border.color: Material.color(Material.Green)
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        
                        Label {
                            text: "\uE8C0  VUELTO:"  // Calculator/Money icon
                            font.family: "Segoe MDL2 Assets"
                            font.pixelSize: 15
                            font.weight: Font.Bold
                            Layout.fillWidth: true
                            color: Material.color(Material.Green)
                        }
                        
                        Label {
                            text: "S/ " + root.changeGiven.toFixed(2)
                            font.pixelSize: 20
                            font.weight: Font.Bold
                            color: Material.color(Material.Green)
                        }
                    }
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
                Material.background: ApplicationWindow.window?.currentColors?.primary ?? Material.primary
                Material.foreground: Material.theme === Material.Dark ? "#000000" : "#FFFFFF"

                onClicked: {
                    root.printRequested()
                    root.close()
                }
            }

            Button {
                text: qsTr("Cerrar")
                Layout.fillWidth: true
                Material.background: Material.color(Material.Red)
                
                contentItem: Label {
                    text: parent.text
                    font: parent.font
                    color: Material.theme === Material.Dark ? "white" : "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: root.close()
            }
        }
    }
}
