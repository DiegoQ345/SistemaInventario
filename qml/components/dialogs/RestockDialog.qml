import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import "../"

Dialog {
    id: root
    
    title: "\uE7C3  " + qsTr("Reponer Inventario")  // Package icon
    modal: true
    
    property int productId: 0
    property string productName: ""
    property real currentStock: 0
    property real addedQuantity: 0
    
    property alias quantity: quantityField.text
    
    signal restockConfirmed(int productId, real quantity)
    
    function openForProduct(id, name, stock) {
        productId = id
        productName = name
        currentStock = stock
        quantityField.text = "1"
        addedQuantity = 1
        numPad.visible = false
        open()
        quantityField.forceActiveFocus()
        quantityField.selectAll()
    }
    
    standardButtons: Dialog.NoButton
    
    width: Math.min(450, ApplicationWindow.window ? ApplicationWindow.window.width * 0.9 : 450)
    
    ColumnLayout {
        width: parent.width
        spacing: 16
        
        // Información del producto
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 80
            radius: 8
            color: Material.theme === Material.Dark ?
                Qt.rgba(1, 1, 1, 0.05) :
                Material.color(Material.Grey, Material.Shade100)
            border.width: 1
            border.color: Material.frameColor
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 4
                
                Label {
                    text: productName
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
                
                Label {
                    text: "Stock actual: " + currentStock.toFixed(0) + " unidades"
                    font.pixelSize: 12
                    opacity: 0.7
                }
                
                Label {
                    text: "Stock después: " + (currentStock + addedQuantity).toFixed(0) + " unidades"
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    color: Material.color(Material.Green)
                }
            }
        }
        
        // Campo de cantidad con botones +/-
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            
            Label {
                text: "Cantidad a agregar:"
                font.pixelSize: 13
                Layout.preferredWidth: 130
            }
            
            Button {
                text: "-"
                font.pixelSize: 20
                font.weight: Font.Bold
                Layout.preferredWidth: 45
                Layout.preferredHeight: 45
                Material.background: Material.color(Material.Grey, Material.Shade300)
                onClicked: {
                    var val = parseFloat(quantityField.text) || 0
                    if (val > 1) {
                        quantityField.text = (val - 1).toString()
                        addedQuantity = val - 1
                    }
                }
            }
            
            TextField {
                id: quantityField
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                text: "1"
                font.pixelSize: 18
                font.weight: Font.Bold
                horizontalAlignment: Text.AlignHCenter
                selectByMouse: true
                inputMethodHints: Qt.ImhDigitsOnly
                validator: DoubleValidator {
                    bottom: 0.01
                    decimals: 2
                    notation: DoubleValidator.StandardNotation
                }
                
                onTextChanged: {
                    addedQuantity = parseFloat(text) || 0
                }
                
                Keys.onReturnPressed: {
                    restockButton.clicked()
                }
            }
            
            Button {
                text: "+"
                font.pixelSize: 20
                font.weight: Font.Bold
                Layout.preferredWidth: 45
                Layout.preferredHeight: 45
                Material.background: Material.color(Material.Green, Material.Shade300)
                onClicked: {
                    var val = parseFloat(quantityField.text) || 0
                    quantityField.text = (val + 1).toString()
                    addedQuantity = val + 1
                }
            }
            
            // Botón para mostrar teclado numérico
            Button {
                text: "\uE1D0"  // Calculator icon
                font.family: "Segoe MDL2 Assets"
                font.pixelSize: 18
                Layout.preferredWidth: 45
                Layout.preferredHeight: 45
                flat: true
                Material.foreground: Material.accent
                ToolTip.text: "Teclado numérico"
                ToolTip.visible: hovered
                
                onClicked: {
                    numPad.visible = !numPad.visible
                }
            }
        }
        
        // Teclado numérico (colapsable)
        NumPad {
            id: numPad
            Layout.fillWidth: true
            Layout.preferredHeight: 320
            visible: false
            targetField: quantityField
            
            Behavior on visible {
                NumberAnimation { duration: 200 }
            }
        }
        
        // Botones de acción
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 8
            spacing: 8
            
            Item { Layout.fillWidth: true }
            
            Button {
                text: qsTr("Cancelar")
                flat: true
                onClicked: root.close()
            }
            
            Button {
                id: restockButton
                text: qsTr("Reponer")
                highlighted: true
                enabled: addedQuantity > 0
                icon.source: "qrc:/icons/check.png"
                Material.background: Material.color(Material.Green)
                
                onClicked: {
                    var qty = parseFloat(quantityField.text)
                    if (qty > 0) {
                        restockConfirmed(productId, qty)
                        root.close()
                    }
                }
            }
        }
    }
}
