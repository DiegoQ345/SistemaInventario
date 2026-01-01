import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import SistemaInventario

Page {
    id: root
    title: qsTr("Productos")

    // Modelo real de productos
    ProductListModel {
        id: productModel
        Component.onCompleted: loadProducts()
        
        onErrorOccurred: function(message) {
            errorLabel.text = message
            errorLabel.visible = true
        }
        
        onOperationSucceeded: function(message) {
            errorLabel.visible = false
            newProductDialog.close()
        }
    }
    
    property int count: productModel.rowCount()

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Barra de herramientas - Material 3
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 72
            color: Material.background
            
            // Sombra sutil
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: Material.frameColor
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                TextField {
                    id: searchField
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    placeholderText: qsTr("Buscar productos...")
                    
                    // Icono de búsqueda
                    leftPadding: 44
                    
                    Label {
                        anchors.left: parent.left
                        anchors.leftMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        text: "\uE721"
                        font.family: "Segoe MDL2 Assets"
                        font.pixelSize: 16
                        color: Material.primary
                        opacity: 0.7
                    }
                    
                    background: Rectangle {
                        color: Material.theme === Material.Dark ? 
                               Qt.lighter(Material.background, 1.2) : 
                               Material.color(Material.Grey, Material.Shade100)
                        radius: 24
                        border.width: searchField.activeFocus ? 2 : 0
                        border.color: Material.primary
                        
                        Behavior on border.width { NumberAnimation { duration: 150 } }
                    }
                    
                    onTextChanged: {
                        if (text.length > 0) {
                            productModel.searchProducts(text)
                        } else {
                            productModel.loadProducts()
                        }
                    }
                }

                Button {
                    text: "\uE9D2  " + qsTr("Stock Bajo")
                    font.family: "Segoe MDL2 Assets"
                    font.weight: Font.Medium
                    flat: true
                    Material.foreground: Material.primary
                    
                    background: Rectangle {
                        implicitWidth: 120
                        implicitHeight: 40
                        radius: 20
                        color: parent.down ? Qt.darker(Material.primary, 1.3) :
                               parent.hovered ? Material.color(Material.Primary, Material.theme === Material.Dark ? Material.Shade800 : Material.Shade100) :
                               "transparent"
                        border.width: 1
                        border.color: Material.theme === Material.Dark ? 
                                     Material.color(Material.Primary, Material.Shade700) :
                                     Material.color(Material.Primary, Material.Shade300)
                        
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    
                    onClicked: productModel.filterLowStock()
                }

                Button {
                    text: "\uE73E  " + qsTr("Todos")
                    font.family: "Segoe MDL2 Assets"
                    font.weight: Font.Medium
                    Material.background: Material.primary
                    Material.foreground: Material.theme === Material.Dark ? "#000000" : "#FFFFFF"
                    
                    onClicked: productModel.loadProducts()
                }

                Button {
                    text: "\uE710  " + qsTr("Nuevo Producto")
                    font.family: "Segoe MDL2 Assets"
                    font.weight: Font.Medium
                    Material.background: Material.primary
                    Material.foreground: Material.theme === Material.Dark ? "#000000" : "#FFFFFF"
                    onClicked: newProductDialog.openNew()
                }
            }
        }

        // Lista de productos
        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            model: productModel

            header: Rectangle {
                width: parent.width
                height: 48
                color: Material.background
                border.width: 1
                border.color: Material.dividerColor

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 12

                    Label { 
                        text: qsTr("Nombre")
                        Layout.fillWidth: true
                        font.bold: true
                        font.pixelSize: 13
                    }
                    Label { 
                        text: qsTr("SKU")
                        Layout.preferredWidth: 120
                        font.bold: true
                        font.pixelSize: 13
                    }
                    Label { 
                        text: qsTr("Stock")
                        Layout.preferredWidth: 80
                        font.bold: true
                        font.pixelSize: 13
                        horizontalAlignment: Text.AlignRight
                    }
                    Label { 
                        text: qsTr("Precio")
                        Layout.preferredWidth: 100
                        font.bold: true
                        font.pixelSize: 13
                        horizontalAlignment: Text.AlignRight
                    }
                    Item { 
                        Layout.preferredWidth: 100
                    }
                }
            }

            delegate: ItemDelegate {
                width: listView.width
                height: 72

                Rectangle {
                    anchors.fill: parent
                    color: model.isLowStock ? Qt.rgba(1, 0.5, 0, 0.1) : "transparent"
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 12

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Label {
                            text: model.name
                            font.pixelSize: 14
                            font.bold: true
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Label {
                            text: model.category || qsTr("Sin categoría")
                            font.pixelSize: 12
                            opacity: 0.7
                        }
                    }

                    Label {
                        text: model.sku || "-"
                        Layout.preferredWidth: 120
                        font.pixelSize: 13
                        elide: Text.ElideRight
                    }

                    Label {
                        text: model.currentStock.toFixed(0)
                        Layout.preferredWidth: 80
                        horizontalAlignment: Text.AlignRight
                        color: model.isLowStock ? Material.color(Material.Orange) : Material.foreground
                        font.bold: model.isLowStock
                        font.pixelSize: 13
                    }

                    Label {
                        text: "S/" + model.salePrice.toFixed(2)
                        Layout.preferredWidth: 100
                        horizontalAlignment: Text.AlignRight
                        font.bold: true
                        font.pixelSize: 13
                    }

                    Row {
                        Layout.preferredWidth: 100
                        spacing: 4
                        layoutDirection: Qt.RightToLeft

                        ToolButton {
                            text: "\uE74D"
                            font.family: "Segoe MDL2 Assets"
                            font.pixelSize: 16
                            onClicked: {
                                deleteDialog.productId = model.productId
                                deleteDialog.productName = model.name
                                deleteDialog.open()
                            }
                        }

                        ToolButton {
                            text: "\uE70F"
                            font.family: "Segoe MDL2 Assets"
                            font.pixelSize: 16
                            onClicked: {
                                newProductDialog.openEdit(model.productId)
                            }
                        }
                    }
                }
            }

            Label {
                anchors.centerIn: parent
                text: qsTr("No hay productos")
                visible: listView.count === 0 && !productModel.isLoading
                font.pixelSize: 16
                opacity: 0.5
            }

            BusyIndicator {
                anchors.centerIn: parent
                running: productModel.isLoading
            }
        }

        // Footer con contador
        ToolBar {
            Layout.fillWidth: true

            Label {
                anchors.centerIn: parent
                text: qsTr("%1 productos").arg(productModel.count)
            }
        }
    }

    // Diálogo de Nuevo/Editar Producto
    Dialog {
        id: newProductDialog
        title: editMode ? qsTr("Editar Producto") : qsTr("Nuevo Producto")
        modal: true
        anchors.centerIn: parent
        width: Math.min(600, root.width * 0.9)
        
        property bool editMode: false
        property int editProductId: 0
        
        function openNew() {
            editMode = false
            errorLabel.visible = false
            nameField.text = ""
            skuField.text = ""
            barcodeField.text = ""
            categoryField.text = ""
            stockField.text = "0"
            minStockField.text = "0"
            purchasePriceField.text = "0.00"
            salePriceField.text = "0.00"
            descriptionField.text = ""
            open()
        }
        
        function openEdit(productId) {
            editMode = true
            editProductId = productId
            errorLabel.visible = false
            
            // Obtener datos del producto desde el ViewModel
            var product = productModel.getProductForEdit(productId)
            if (product && product.id) {
                // Cargar datos del producto seleccionado
                nameField.text = product.name || ""
                skuField.text = product.sku || ""
                barcodeField.text = product.barcode || ""
                categoryField.text = product.category || ""
                stockField.text = product.currentStock ? product.currentStock.toString() : "0"
                minStockField.text = product.minimumStock ? product.minimumStock.toString() : "0"
                purchasePriceField.text = product.purchasePrice ? product.purchasePrice.toFixed(2) : "0.00"
                salePriceField.text = product.salePrice ? product.salePrice.toFixed(2) : "0.00"
                descriptionField.text = product.description || ""
            } else {
                errorLabel.text = "No se pudo cargar el producto"
                errorLabel.visible = true
            }
            
            open()
        }

        contentItem: ColumnLayout {
            spacing: 16

            // Mensaje de error
            Label {
                id: errorLabel
                Layout.fillWidth: true
                visible: false
                color: Material.color(Material.Red)
                font.pixelSize: 13
                font.weight: Font.Medium
                wrapMode: Text.WordWrap
            }

            GridLayout {
                columns: 2
                Layout.fillWidth: true
                columnSpacing: 16
                rowSpacing: 12

                Label { text: qsTr("Nombre:") + "*"; font.weight: Font.Medium }
                TextField {
                    id: nameField
                    Layout.fillWidth: true
                    placeholderText: qsTr("Nombre del producto")
                }

                Label { text: qsTr("SKU:") + "*"; font.weight: Font.Medium }
                TextField {
                    id: skuField
                    Layout.fillWidth: true
                    placeholderText: qsTr("Código SKU")
                }

                Label { text: qsTr("Código de Barras:"); font.weight: Font.Medium }
                TextField {
                    id: barcodeField
                    Layout.fillWidth: true
                    placeholderText: qsTr("EAN, UPC...")
                }

                Label { text: qsTr("Categoría:"); font.weight: Font.Medium }
                TextField {
                    id: categoryField
                    Layout.fillWidth: true
                    placeholderText: qsTr("Categoría del producto")
                }

                Label { text: qsTr("Stock Actual:") + "*"; font.weight: Font.Medium }
                TextField {
                    id: stockField
                    Layout.fillWidth: true
                    placeholderText: "0"
                    validator: DoubleValidator { bottom: 0 }
                }

                Label { text: qsTr("Stock Mínimo:"); font.weight: Font.Medium }
                TextField {
                    id: minStockField
                    Layout.fillWidth: true
                    placeholderText: "0"
                    validator: DoubleValidator { bottom: 0 }
                }

                Label { text: qsTr("Precio Compra:"); font.weight: Font.Medium }
                TextField {
                    id: purchasePriceField
                    Layout.fillWidth: true
                    placeholderText: "0.00"
                    validator: DoubleValidator { bottom: 0; decimals: 2 }
                }

                Label { text: qsTr("Precio Venta:") + "*"; font.weight: Font.Medium }
                TextField {
                    id: salePriceField
                    Layout.fillWidth: true
                    placeholderText: "0.00"
                    validator: DoubleValidator { bottom: 0; decimals: 2 }
                }
            }

            Label { text: qsTr("Descripción:"); font.weight: Font.Medium }
            ScrollView {
                Layout.fillWidth: true
                Layout.preferredHeight: 100
                clip: true
                
                TextArea {
                    id: descriptionField
                    placeholderText: qsTr("Descripción del producto (opcional)")
                    wrapMode: TextArea.Wrap
                }
            }
        }

        standardButtons: Dialog.Save | Dialog.Cancel

        onAccepted: {
            errorLabel.visible = false
            
            // Preparar datos del producto (el ViewModel validará)
            var product = {
                name: nameField.text,
                sku: skuField.text,
                barcode: barcodeField.text,
                // categoryId se mantiene del producto original, category es solo para mostrar
                currentStock: parseFloat(stockField.text || "0"),
                minimumStock: parseFloat(minStockField.text || "0"),
                purchasePrice: parseFloat(purchasePriceField.text || "0"),
                salePrice: parseFloat(salePriceField.text || "0"),
                description: descriptionField.text
            }
            
            // El ViewModel maneja validación y guardado
            if (editMode) {
                productModel.updateProduct(editProductId, product)
            } else {
                productModel.addProduct(product)
            }
        }
    }

    // Diálogo de confirmación de eliminación
    Dialog {
        id: deleteDialog
        title: qsTr("Eliminar Producto")
        modal: true
        anchors.centerIn: parent

        property int productId: 0
        property string productName: ""

        Label {
            text: qsTr("¿Está seguro de eliminar el producto '%1'?").arg(deleteDialog.productName)
        }

        standardButtons: Dialog.Yes | Dialog.No

        onAccepted: {
            productModel.deleteProduct(productId)
        }
    }
}
