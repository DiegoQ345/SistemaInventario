import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import "../"

Dialog {
    id: root
    title: "\uE8C0  " + qsTr("Ingresar Monto Pagado")  // Calculator icon
    modal: true
    anchors.centerIn: parent
    width: 450
    
    property real totalAmount: 0.0
    property real amountPaid: 0.0
    property real changeGiven: 0.0
    
    signal paymentConfirmed(real amountPaid, real changeGiven)
    
    // Overlay con color semitransparente oscuro
    Overlay.modal: Rectangle {
        color: Material.theme === Material.Dark ? 
            Qt.rgba(0, 0, 0, 0.6) : 
            Qt.rgba(0.05, 0.05, 0.05, 0.5)
    }
    
    // Resetear cuando se cierra
    onClosed: {
        amountPaidField.text = totalAmount.toFixed(2)
        amountPaid = totalAmount
        changeGiven = 0.0
    }
    
    // Inicializar cuando se abre
    onOpened: {
        amountPaidField.text = totalAmount.toFixed(2)
        amountPaid = totalAmount
        changeGiven = 0.0
        amountPaidField.forceActiveFocus()
    }
    
    ColumnLayout {
        anchors.fill: parent
        spacing: 20
        
        // Información del total
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 80
            color: Material.theme === Material.Dark ?
                Qt.lighter(Material.background, 1.3) :
                Material.color(Material.Grey, Material.Shade100)
            radius: 8
            border.width: 2
            border.color: ApplicationWindow.window?.currentColors?.primary ?? Material.primary
            
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 4
                
                Label {
                    text: qsTr("Total a Pagar:")
                    font.pixelSize: 14
                    Layout.alignment: Qt.AlignHCenter
                    opacity: 0.7
                }
                
                Label {
                    text: "S/ " + root.totalAmount.toFixed(2)
                    font.pixelSize: 28
                    font.weight: Font.Bold
                    Layout.alignment: Qt.AlignHCenter
                    color: ApplicationWindow.window?.currentColors?.primary ?? Material.primary
                }
            }
        }
        
        // Campo de monto pagado con botón de calculadora
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8
            
            Label {
                text: qsTr("Monto Recibido:")
                font.pixelSize: 14
                font.weight: Font.Medium
            }
            
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                
                TextField {
                    id: amountPaidField
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    placeholderText: "Ingrese monto pagado"
                    text: root.totalAmount.toFixed(2)
                    font.pixelSize: 18
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    selectByMouse: true
                    validator: DoubleValidator {
                        bottom: 0.0
                        decimals: 2
                        notation: DoubleValidator.StandardNotation
                    }
                    
                    onTextChanged: {
                        var amount = parseFloat(text) || 0.0
                        root.amountPaid = amount
                        root.changeGiven = Math.max(0, amount - root.totalAmount)
                    }
                    
                    // Enter para confirmar
                    Keys.onReturnPressed: {
                        if (root.amountPaid >= root.totalAmount) {
                            root.paymentConfirmed(root.amountPaid, root.changeGiven)
                            root.close()
                        }
                    }
                }
                
                // Botón para mostrar teclado numérico
                Button {
                    Layout.preferredWidth: 56
                    Layout.preferredHeight: 48
                    text: "\uE1D0"  // Calculator icon
                    font.family: "Segoe MDL2 Assets"
                    font.pixelSize: 24
                    
                    Material.background: ApplicationWindow.window?.currentColors?.primary ?? Material.primary
                    Material.foreground: Material.theme === Material.Dark ? "#000000" : "#FFFFFF"
                    
                    ToolTip.visible: hovered
                    ToolTip.text: "Teclado numérico"
                    ToolTip.delay: 500
                    
                    onClicked: {
                        numPad.visible = !numPad.visible
                    }
                }
            }
            
            // Botones de monto rápido
            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                
                Label {
                    text: "Rápido:"
                    font.pixelSize: 12
                    opacity: 0.7
                }
                
                Repeater {
                    model: [10, 20, 50, 100]
                    
                    Button {
                        text: "+" + modelData
                        Layout.fillWidth: true
                        flat: true
                        font.pixelSize: 12
                        
                        onClicked: {
                            var currentAmount = parseFloat(amountPaidField.text) || 0.0
                            amountPaidField.text = (currentAmount + modelData).toFixed(2)
                        }
                    }
                }
            }
        }
        
        // Teclado numérico (colapsable)
        NumPad {
            id: numPad
            Layout.fillWidth: true
            Layout.preferredHeight: 360
            targetField: amountPaidField
            visible: false
        }
        
        // Display del vuelto
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 70
            radius: 8
            color: Material.theme === Material.Dark ?
                Qt.lighter(Material.background, 1.3) :
                Material.color(Material.Grey, Material.Shade100)
            border.width: 3
            border.color: root.changeGiven > 0 ?
                Material.color(Material.Green) :
                Material.frameColor
            
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 2
                
                Label {
                    text: qsTr("Vuelto:")
                    font.pixelSize: 13
                    Layout.alignment: Qt.AlignHCenter
                    opacity: 0.7
                }
                
                Label {
                    text: "S/ " + root.changeGiven.toFixed(2)
                    font.pixelSize: 24
                    font.weight: Font.Bold
                    Layout.alignment: Qt.AlignHCenter
                    color: root.changeGiven > 0 ?
                        Material.color(Material.Green) :
                        Material.foreground
                }
            }
        }
        
        // Mensaje de advertencia si el monto es insuficiente
        Label {
            Layout.fillWidth: true
            text: "⚠️ El monto pagado debe ser mayor o igual al total"
            visible: root.amountPaid < root.totalAmount && root.amountPaid > 0
            color: Material.color(Material.Orange)
            font.pixelSize: 12
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
        }
    }
    
    footer: DialogButtonBox {
        Button {
            text: qsTr("Cancelar")
            flat: true
            DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
            
            onClicked: root.close()
        }
        
        Button {
            text: qsTr("Confirmar Pago")
            enabled: root.amountPaid >= root.totalAmount
            Material.background: Material.color(Material.Green)
            
            contentItem: Label {
                text: parent.text
                font: parent.font
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                color: "#000000"
            }
            
            DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
            
            onClicked: {
                root.paymentConfirmed(root.amountPaid, root.changeGiven)
                root.close()
            }
        }
    }
}
