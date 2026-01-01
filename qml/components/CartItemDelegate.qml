import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

/**
 * @brief Componente reutilizable para items del carrito de compras
 * 
 * Este componente encapsula la presentación de un item individual
 * en el carrito de ventas, incluyendo:
 * - Información del producto
 * - Control de cantidad con SpinBox
 * - Botón de eliminación
 * - Visualización de subtotal
 * 
 * Uso:
 * CartItemDelegate {
 *     productId: model.productId
 *     productName: model.productName
 *     quantity: model.quantity
 *     unitPrice: model.unitPrice
 *     subtotal: model.subtotal
 *     maxQuantity: model.maxQuantity
 *     
 *     onQuantityChanged: updateCartItemQuantityByProductId(productId, quantity)
 *     onRemoveClicked: removeCartItemByProductId(productId)
 * }
 */
Item {
    id: root
    
    // Propiedades públicas
    required property int productId
    required property string productName
    required property real quantity
    required property real unitPrice
    required property real subtotal
    required property real maxQuantity
    
    // Señales
    signal quantityChanged(int productId, real newQuantity)
    signal removeClicked(int productId)
    
    // Dimensiones
    width: ListView.view ? ListView.view.width : 400
    height: cardRect.height + 6
    
    // Sombra simulada
    Rectangle {
        anchors.fill: cardRect
        anchors.topMargin: 3
        anchors.leftMargin: 2
        anchors.rightMargin: 2
        radius: 8
        color: Material.theme === Material.Dark ? "#20000000" : "#15000000"
        visible: true
    }
    
    Rectangle {
        id: cardRect
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: itemContent.implicitHeight + 24
        color: Material.theme === Material.Dark ? 
               Qt.lighter(Material.background, 1.2) : 
               "white"
        border.color: Material.theme === Material.Dark ?
                      Material.primary :
                      Material.color(Material.Grey, Material.Shade300)
        border.width: 1
        radius: 8
        
        // Efecto hover
        scale: itemMouseArea.containsMouse ? 1.015 : 1.0
        
        Behavior on scale {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutQuad
            }
        }
        
        MouseArea {
            id: itemMouseArea
            anchors.fill: parent
            hoverEnabled: true
            propagateComposedEvents: true
        }
        
        // Indicador lateral colorido
        Rectangle {
            width: 4
            height: parent.height - 16
            anchors.left: parent.left
            anchors.leftMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            color: Material.primary
            radius: 2
            opacity: Material.theme === Material.Dark ? 1.0 : 0.8
        }

        RowLayout {
            id: itemContent
            anchors.fill: parent
            anchors.leftMargin: 18
            anchors.rightMargin: 12
            anchors.topMargin: 12
            anchors.bottomMargin: 12
            spacing: 12

            // Icono del producto
            Rectangle {
                Layout.preferredWidth: 50
                Layout.preferredHeight: 50
                Layout.alignment: Qt.AlignVCenter
                radius: 8
                color: Material.primary
                
                Label {
                    anchors.centerIn: parent
                    text: "\uE7BF"  // Shopping bag icon
                    font.family: "Segoe MDL2 Assets"
                    font.pixelSize: 26
                    color: "white"
                }
            }

            // Información del producto
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 6

                Label {
                    text: root.productName
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    Layout.maximumWidth: 180
                    color: Material.foreground
                }

                RowLayout {
                    spacing: 8
                    Layout.fillWidth: true
                    
                    Label {
                        text: "S/" + root.unitPrice.toFixed(2)
                        font.pixelSize: 11
                        opacity: 0.6
                        color: Material.foreground
                    }
                    
                    Label {
                        text: "×"
                        font.pixelSize: 11
                        opacity: 0.6
                        color: Material.foreground
                    }
                    
                    Rectangle {
                        width: quantityLabel.width + 10
                        height: quantityLabel.height + 6
                        radius: 4
                        color: Material.theme === Material.Dark ?
                               Qt.darker(Material.accent, 1.5) :
                               Material.color(Material.Grey, Material.Shade200)
                        
                        Label {
                            id: quantityLabel
                            anchors.centerIn: parent
                            text: root.quantity
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            color: Material.foreground
                        }
                    }
                }

                Rectangle {
                    Layout.preferredHeight: 26
                    Layout.preferredWidth: itemSubtotalLabel.width + 18
                    radius: 5
                    color: Material.theme === Material.Dark ?
                           Qt.rgba(Material.primary.r, Material.primary.g, Material.primary.b, 0.2) :
                           Qt.rgba(Material.primary.r, Material.primary.g, Material.primary.b, 0.15)
                    
                    Label {
                        id: itemSubtotalLabel
                        anchors.centerIn: parent
                        text: "S/" + root.subtotal.toFixed(2)
                        font.pixelSize: 13
                        font.weight: Font.Bold
                        color: Material.primary
                    }
                }
            }

            // Controles (cantidad y eliminar)
            ColumnLayout {
                Layout.alignment: Qt.AlignVCenter
                spacing: 10

                SpinBox {
                    id: itemQuantitySpinBox
                    from: 1
                    to: root.maxQuantity
                    value: root.quantity
                    editable: true
                    Layout.preferredWidth: 110
                    Layout.preferredHeight: 40

                    onValueModified: {
                        root.quantityChanged(root.productId, value)
                    }
                }

                Button {
                    text: "\uE74D"  // Delete icon
                    font.family: "Segoe MDL2 Assets"
                    font.pixelSize: 18
                    flat: true
                    Layout.preferredWidth: 44
                    Layout.preferredHeight: 44
                    
                    Material.foreground: "white"
                    
                    background: Rectangle {
                        radius: 8
                        color: Material.theme === Material.Light ?
                               (parent.down ? Material.color(Material.Red, Material.Shade700) :
                                parent.hovered ? Material.color(Material.Red, Material.Shade600) :
                                Material.color(Material.Red, Material.Shade500)) :
                               (parent.down ? "#1a1a1a" :
                                parent.hovered ? "#333333" : "#000000")
                        border.width: 0
                        
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    
                    onClicked: root.removeClicked(root.productId)
                }
            }
        }
    }
}
