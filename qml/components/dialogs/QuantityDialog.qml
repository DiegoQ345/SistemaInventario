import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts


// Diálogo de selección de cantidad con numpad
Dialog {
    id: root
    title: qsTr("Cantidad")
    modal: true
    width: 320
    height: 500
    anchors.centerIn: Overlay.overlay

    property string scannedBarcode: ""
    property string currentQuantity: "1"
    property string productName: ""
    property int currentStock: 0

    onOpened: {
        root.layer.enabled = true
        currentQuantity = "1"
        // Forzar foco después de que el diálogo se haya renderizado
        Qt.callLater(function() {
            quantityDisplay.forceActiveFocus()
        })
    }

    onClosed: {
        root.layer.enabled = false
        productName = ""
        currentStock = 0
    }

    // Overlay con color semitransparente
    Overlay.modal: Rectangle {
        color: Material.theme === Material.Dark ?
            Qt.rgba(0, 0, 0, 0.5) :
            Qt.rgba(0.1, 0.1, 0.1, 0.4)
    }

    contentItem: ColumnLayout {
        spacing: 16

        // Información del producto
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            color: Material.theme === Material.Dark ?
                Qt.rgba(1, 1, 1, 0.05) :
                Qt.rgba(0, 0, 0, 0.03)
            radius: 6
            border.width: 1
            border.color: Material.frameColor
            visible: quantityDialog.productName !== ""

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 4

                Label {
                    text: quantityDialog.productName
                    font.weight: Font.Medium
                    font.pixelSize: 14
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Label {
                    text: qsTr("Disponible para venta: ") + quantityDialog.currentStock
                    font.pixelSize: 12
                    opacity: 0.7
                }
            }
        }

        // Display de cantidad
        TextField {
            id: quantityDisplay
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            text: quantityDialog.currentQuantity
            font.pixelSize: 32
            font.bold: true
            horizontalAlignment: Text.AlignRight
            readOnly: true
            focus: true

            background: Rectangle {
                color: Material.theme === Material.Dark ? "#2d2d2d" : "#f5f5f5"
                border.color: Material.frameColor
                border.width: 2
                radius: 4
            }

            // Captura de teclado físico
            Keys.onPressed: function(event) {
                console.log("*** NumPad: Tecla presionada:", event.key, "Texto:", event.text)
                if (event.key >= Qt.Key_0 && event.key <= Qt.Key_9) {
                    // Números del teclado principal
                    quantityDialog.appendDigit((event.key - Qt.Key_0).toString())
                    event.accepted = true
                } else if (event.key >= 0x1000030 && event.key <= 0x1000039) {
                    // Números del numpad
                    quantityDialog.appendDigit((event.key - 0x1000030).toString())
                    event.accepted = true
                } else if (event.key === Qt.Key_Backspace || event.key === Qt.Key_C) {
                    quantityDialog.clearQuantity()
                    event.accepted = true
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    quantityDialog.confirmQuantity()
                    event.accepted = true
                } else if (event.key === Qt.Key_Escape) {
                    quantityDialog.close()
                    event.accepted = true
                }
            }
        }

        // Grid de botones numéricos
        GridLayout {
            Layout.fillWidth: true
            columns: 3
            rowSpacing: 8
            columnSpacing: 8

            // Botones 7-9
            Repeater {
                model: ["7", "8", "9"]
                Button {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    text: modelData
                    font.pixelSize: 24
                    font.bold: true
                    onClicked: {
                        console.log("Botón clickeado:", modelData)
                        quantityDialog.appendDigit(modelData)
                    }
                }
            }

            // Botones 4-6
            Repeater {
                model: ["4", "5", "6"]
                Button {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    text: modelData
                    font.pixelSize: 24
                    font.bold: true
                    onClicked: {
                        console.log("Botón clickeado:", modelData)
                        quantityDialog.appendDigit(modelData)
                    }
                }
            }

            // Botones 1-3
            Repeater {
                model: ["1", "2", "3"]
                Button {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    text: modelData
                    font.pixelSize: 24
                    font.bold: true
                    onClicked: {
                        console.log("Botón clickeado:", modelData)
                        quantityDialog.appendDigit(modelData)
                    }
                }
            }

            // Botón C (limpiar)
            Button {
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                text: "C"
                font.pixelSize: 24
                font.bold: true
                Material.background: Material.color(Material.Orange)
                onClicked: {
                    console.log("Botón C clickeado")
                    quantityDialog.clearQuantity()
                }
            }

            // Botón 0
            Button {
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                text: "0"
                font.pixelSize: 24
                font.bold: true
                onClicked: {
                    console.log("Botón 0 clickeado")
                    quantityDialog.appendDigit("0")
                }
            }

            // Botón OK
            Button {
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                text: "✓"
                font.pixelSize: 28
                font.bold: true
                Material.background: Material.color(Material.Green)
                onClicked: {
                    console.log("Botón OK clickeado")
                    quantityDialog.confirmQuantity()
                }
            }
        }

        // Botones de acción
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Button {
                Layout.fillWidth: true
                text: qsTr("Cancelar")
                flat: true
                onClicked: quantityDialog.close()
            }

            Button {
                Layout.fillWidth: true
                text: qsTr("Agregar al Carrito")
                highlighted: true
                onClicked: {
                    console.log("Botón Agregar clickeado")
                    quantityDialog.confirmQuantity()
                }
            }
        }
    }

    // Funciones del numpad
    function appendDigit(digit) {
        console.log("appendDigit llamado con:", digit, "Cantidad actual:", currentQuantity)
        if (currentQuantity === "0" || (currentQuantity === "1" && currentQuantity.length === 1)) {
            currentQuantity = digit
        } else if (currentQuantity.length < 4) {  // Máximo 9999
            currentQuantity += digit
        }
        console.log("Nueva cantidad:", currentQuantity)
    }

    function clearQuantity() {
        console.log("clearQuantity llamado")
        currentQuantity = "1"
    }

    function confirmQuantity() {
        console.log("confirmQuantity llamado. Cantidad:", currentQuantity, "Código:", scannedBarcode)
        var qty = parseInt(currentQuantity)
        if (qty > 0 && qty <= 9999) {
            console.log("Agregando producto con cantidad:", qty)
            viewModel.searchAndAddProduct(scannedBarcode, qty)
            searchField.text = ""
            quantitySpinBox.value = 1
            quantityDialog.close()
        } else {
            console.log("Cantidad inválida:", qty)
        }
    }
}
