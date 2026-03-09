import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

Dialog {
    id: root
    title: qsTr("Referencias de Variables")
    modal: true
    anchors.centerIn: parent
    width: Math.min(700, parent.width * 0.95)
    height: Math.min(650, parent.height * 0.9)

    background: Rectangle {
        color: Material.dialogColor
        radius: 8
        border.width: 1
        border.color: Material.theme === Material.Dark ?
            Qt.lighter(Material.backgroundColor, 1.3) :
            Qt.darker(Material.backgroundColor, 1.1)
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        Label {
            Layout.fillWidth: true
            text: qsTr("Utiliza estas variables en el contenido de texto para mostrar información dinámica en tus tickets")
            wrapMode: Text.WordWrap
            font.pixelSize: 12
            opacity: 0.9
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            ColumnLayout {
                width: root.availableWidth - 40
                spacing: 16

                // Información del Negocio
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: businessGroup.implicitHeight + 24
                    color: Material.theme === Material.Dark ?
                        Qt.lighter(Material.background, 1.2) :
                        Qt.darker(Material.background, 1.05)
                    radius: 6

                    ColumnLayout {
                        id: businessGroup
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        Label {
                            text: "Información del Negocio"
                            font.bold: true
                            font.pixelSize: 13
                            color: Material.accent
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: root.width > 600 ? 2 : 1
                            columnSpacing: 12
                            rowSpacing: 6

                            Label {
                                text: "{{businessName}}"
                                font.family: "Consolas"
                                color: Material.accent
                            }
                            Label {
                                text: "Nombre del negocio"
                                opacity: 0.8
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }

                            Label {
                                text: "{{ruc}}"
                                font.family: "Consolas"
                                color: Material.accent
                            }
                            Label {
                                text: "RUC/Número de identificación tributaria"
                                opacity: 0.8
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }

                            Label {
                                text: "{{address}}"
                                font.family: "Consolas"
                                color: Material.accent
                            }
                            Label {
                                text: "Dirección del negocio"
                                opacity: 0.8
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }

                            Label {
                                text: "{{phone}}"
                                font.family: "Consolas"
                                color: Material.accent
                            }
                            Label {
                                text: "Teléfono de contacto"
                                opacity: 0.8
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }

                            Label {
                                text: "{{email}}"
                                font.family: "Consolas"
                                color: Material.accent
                            }
                            Label {
                                text: "Correo electrónico"
                                opacity: 0.8
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                        }
                    }
                }

                // Información de la Venta
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: saleGroup.implicitHeight + 24
                    color: Material.theme === Material.Dark ?
                        Qt.lighter(Material.background, 1.2) :
                        Qt.darker(Material.background, 1.05)
                    radius: 6

                    ColumnLayout {
                        id: saleGroup
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        Label {
                            text: "Información de la Venta"
                            font.bold: true
                            font.pixelSize: 13
                            color: Material.accent
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: root.width > 600 ? 2 : 1
                            columnSpacing: 12
                            rowSpacing: 6

                            Label {
                                text: "{{invoiceNumber}}"
                                font.family: "Consolas"
                                color: Material.accent
                            }
                            Label {
                                text: "Número de factura o boleta"
                                opacity: 0.8
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }

                            Label {
                                text: "{{voucherType}}"
                                font.family: "Consolas"
                                color: Material.accent
                            }
                            Label {
                                text: "Tipo de comprobante (FACTURA/BOLETA)"
                                opacity: 0.8
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }

                            Label {
                                text: "{{customerName}}"
                                font.family: "Consolas"
                                color: Material.accent
                            }
                            Label {
                                text: "Nombre del cliente"
                                opacity: 0.8
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }

                            Label {
                                text: "{{customerRuc}}"
                                font.family: "Consolas"
                                color: Material.accent
                            }
                            Label {
                                text: "RUC del cliente (para facturas)"
                                opacity: 0.8
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }

                            Label {
                                text: "{{customerBusinessName}}"
                                font.family: "Consolas"
                                color: Material.accent
                            }
                            Label {
                                text: "Razón Social del cliente (para facturas)"
                                opacity: 0.8
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }

                            Label {
                                text: "{{customerAddress}}"
                                font.family: "Consolas"
                                color: Material.accent
                            }
                            Label {
                                text: "Dirección del cliente (para facturas)"
                                opacity: 0.8
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                        }
                    }
                }

                // Información de Fecha y Hora
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: dateGroup.implicitHeight + 24
                    color: Material.theme === Material.Dark ?
                        Qt.lighter(Material.background, 1.2) :
                        Qt.darker(Material.background, 1.05)
                    radius: 6

                    ColumnLayout {
                        id: dateGroup
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        Label {
                            text: "Fecha y Hora"
                            font.bold: true
                            font.pixelSize: 13
                            color: Material.accent
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: root.width > 600 ? 2 : 1
                            columnSpacing: 12
                            rowSpacing: 6

                            Label {
                                text: "{{date}}"
                                font.family: "Consolas"
                                color: Material.accent
                            }
                            Label {
                                text: "Fecha de la venta (ej: 19/02/2026)"
                                opacity: 0.8
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }

                            Label {
                                text: "{{time}}"
                                font.family: "Consolas"
                                color: Material.accent
                            }
                            Label {
                                text: "Hora de la venta (ej: 14:30:00)"
                                opacity: 0.8
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }

                            Label {
                                text: "{{datetime}}"
                                font.family: "Consolas"
                                color: Material.accent
                            }
                            Label {
                                text: "Fecha y hora completas"
                                opacity: 0.8
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                        }
                    }
                }

                // Productos
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: productsGroup.implicitHeight + 24
                    color: Material.theme === Material.Dark ?
                        Qt.lighter(Material.background, 1.2) :
                        Qt.darker(Material.background, 1.05)
                    radius: 6

                    ColumnLayout {
                        id: productsGroup
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        Label {
                            text: "Lista de Productos"
                            font.bold: true
                            font.pixelSize: 13
                            color: Material.accent
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: root.width > 600 ? 2 : 1
                            columnSpacing: 12
                            rowSpacing: 6

                            Label {
                                text: "{{Productos}}"
                                font.family: "Consolas"
                                color: Material.accent
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                Label {
                                    text: "Lista completa de productos con cantidades y subtotales"
                                    opacity: 0.8
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }
                                Label {
                                    text: "Formato: Producto x Cantidad S/ Subtotal"
                                    font.pixelSize: 10
                                    opacity: 0.6
                                    font.italic: true
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }
                            }
                        }
                    }
                }

                // Totales y Montos
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: totalsGroup.implicitHeight + 24
                    color: Material.theme === Material.Dark ?
                        Qt.lighter(Material.background, 1.2) :
                        Qt.darker(Material.background, 1.05)
                    radius: 6

                    ColumnLayout {
                        id: totalsGroup
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        Label {
                            text: "Totales y Montos"
                            font.bold: true
                            font.pixelSize: 13
                            color: Material.accent
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: root.width > 600 ? 2 : 1
                            columnSpacing: 12
                            rowSpacing: 6

                            Label {
                                text: "{{subtotal}}"
                                font.family: "Consolas"
                                color: Material.accent
                            }
                            Label {
                                text: "Subtotal de la venta (sin impuestos)"
                                opacity: 0.8
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }

                            Label {
                                text: "{{discount}}"
                                font.family: "Consolas"
                                color: Material.accent
                            }
                            Label {
                                text: "Descuento aplicado"
                                opacity: 0.8
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }

                            Label {
                                text: "{{tax}}"
                                font.family: "Consolas"
                                color: Material.accent
                            }
                            Label {
                                text: "Impuestos (IGV u otros)"
                                opacity: 0.8
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }

                            Label {
                                text: "{{total}}"
                                font.family: "Consolas"
                                color: Material.accent
                            }
                            Label {
                                text: "Total final a pagar"
                                opacity: 0.8
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }

                            Label {
                                text: "{{amountPaid}}"
                                font.family: "Consolas"
                                color: Material.accent
                            }
                            Label {
                                text: "Monto pagado por el cliente"
                                opacity: 0.8
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }

                            Label {
                                text: "{{changeGiven}}"
                                font.family: "Consolas"
                                color: Material.accent
                            }
                            Label {
                                text: "Vuelto entregado al cliente"
                                opacity: 0.8
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                        }
                    }
                }

                // Ejemplo de uso
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: exampleGroup.implicitHeight + 24
                    color: Material.color(Material.Blue, Material.Shade900)
                    radius: 6

                    ColumnLayout {
                        id: exampleGroup
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        Label {
                            text: "Ejemplo de Uso"
                            font.bold: true
                            font.pixelSize: 13
                            color: Material.accent
                        }

                        ScrollView {
                            Layout.fillWidth: true
                            implicitHeight: Math.min(exampleText.implicitHeight + 20, 300)
                            clip: true

                            Label {
                                id: exampleText
                                width: exampleGroup.width - 24
                                text: "{{businessName}}\n" +
                                      "RUC: {{ruc}}\n" +
                                      "Dirección: {{address}}\n" +
                                      "Tel: {{phone}}\n" +
                                      "----------------------------\n" +
                                      "Boleta: {{invoiceNumber}}\n" +
                                      "Fecha: {{date}} - {{time}}\n" +
                                      "----------------------------\n" +
                                      "{{Productos}}\n" +
                                      "----------------------------\n" +
                                      "Subtotal: S/ {{subtotal}}\n" +
                                      "Descuento: S/ {{discount}}\n" +
                                      "Total: S/ {{total}}\n" +
                                      "Pagado: S/ {{amountPaid}}\n" +
                                      "Vuelto: S/ {{changeGiven}}\n" +
                                      "----------------------------\n" +
                                      "Gracias por su compra!"
                                font.family: "Consolas"
                                font.pixelSize: 10
                                wrapMode: Text.Wrap
                            }
                        }
                    }
                }
            }
        }

        Button {
            text: qsTr("Cerrar")
            Layout.alignment: Qt.AlignRight
            Layout.preferredWidth: 120
            onClicked: root.close()
        }
    }
}
