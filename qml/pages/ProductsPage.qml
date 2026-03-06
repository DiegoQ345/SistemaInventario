import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Effects
import SistemaInventario
import "../components"

Page {
    id: root
    title: qsTr("Productos")
    
    // Señal para notificar que se escaneó un código y debe agregarse al carrito
    signal barcodeScannedForCart(string barcode)
    
    // Habilitar captura de teclas para escáner de código de barras
    focus: true
    
    Component.onCompleted: {
        console.log("*** ProductsPage: Página cargada, forzando foco ***")
        root.forceActiveFocus()
    }
    
    onActiveFocusChanged: {
        console.log("*** ProductsPage: Foco activo =", activeFocus, "***")
    }
    
    Keys.onPressed: function(event) {
        console.log("*** ProductsPage: Keys.onPressed disparado - Tecla:", event.key, "Texto:", event.text, "***")
        // Solo procesar si no hay diálogos abiertos
        if (!newProductDialog.opened && !deleteDialog.opened && !deleteAllConfirmDialog.opened && !deleteAllFinalDialog.opened) {
            // Capturar caracteres alfanuméricos del escáner
            if (event.text.length > 0) {
                console.log("ProductsPage: Tecla presionada:", event.text)
                barcodeScanner.processCharacter(event.text)
                event.accepted = true
            }
            // Enter finaliza el escaneo - IMPORTANTE: enviar al handler
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                console.log("ProductsPage: Enter detectado, finalizando escaneo")
                barcodeScanner.processCharacter("\n")
                event.accepted = true
            }
        }
    }
    
    // Configuración del blur cuando se activa
    layer.enabled: false
    layer.effect: MultiEffect {
        blur: 1.0
        blurMax: 64
        blurMultiplier: 1.2
    }

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
    
    // Handler para escáner de código de barras láser
    BarcodeScannerHandler {
        id: barcodeScanner
        enabled: true
        timeout: 100  // 100ms entre caracteres del escáner
        
        onBarcodeScanned: function(barcode) {
            console.log("Código de barras escaneado en productos:", barcode)
            
            // Verificar si el producto existe en el inventario
            if (productModel.hasProductWithBarcode(barcode)) {
                // Producto existe: buscar y mostrar en la lista
                console.log("Producto encontrado, buscando en lista")
                searchField.text = barcode
                productModel.searchProducts(barcode)
            } else {
                // Producto NO existe: abrir diálogo para agregarlo
                console.log("Producto no encontrado, abriendo diálogo para agregarlo")
                newProductDialog.openNewWithBarcode(barcode)
            }
        }
    }
    
    property int count: productModel.rowCount()

    // MouseArea para capturar clics y mantener el foco
    MouseArea {
        anchors.fill: parent
        propagateComposedEvents: true
        z: -1
        onClicked: function(mouse) {
            console.log("*** ProductsPage: Clic detectado, restaurando foco ***")
            root.forceActiveFocus()
            mouse.accepted = false
        }
    }

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
                    placeholderText: qsTr("Buscar por nombre, SKU o código de barras...")
                    
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

                ComboBox {
                    id: categoryFilterCombo
                    Layout.preferredWidth: 200
                    Layout.preferredHeight: 48
                    model: productModel.availableCategories
                    
                    displayText: "\uE71C  " + currentText
                    font.family: "Segoe MDL2 Assets"
                    
                    onCurrentTextChanged: {
                        productModel.filterByCategoryName(currentText)
                    }
                }

                OutlinedButton {
                    id: stockBajoBtn
                    text: qsTr("Stock Bajo")
                    iconText: "\uE9D2"
                    onClicked: productModel.filterLowStock()
                    
                    // Excepción: fondo rojo y texto blanco
                    contentItem: Label {
                        text: stockBajoBtn.iconText !== "" ? stockBajoBtn.iconText + "  " + stockBajoBtn.text : stockBajoBtn.text
                        font.family: stockBajoBtn.iconText !== "" ? "Segoe MDL2 Assets" : stockBajoBtn.font.family
                        font.pixelSize: stockBajoBtn.font.pixelSize
                        font.weight: stockBajoBtn.font.weight
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    background: Rectangle {
                        implicitHeight: 40
                        radius: 4
                        color: stockBajoBtn.down ? 
                            Qt.darker(Material.color(Material.Red), 1.3) :
                            stockBajoBtn.hovered ? 
                            Qt.darker(Material.color(Material.Red), 1.1) :
                            Material.color(Material.Red)
                        border.width: 0
                        
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }

                PrimaryButton {
                    text: qsTr("Todos")
                    iconText: "\uE73E"
                    onClicked: {
                        categoryFilterCombo.currentIndex = 0
                        productModel.loadProducts()
                    }
                }

                PrimaryButton {
                    text: qsTr("Nuevo Producto")
                    iconText: "\uE710"
                    onClicked: newProductDialog.openNew()
                }
                
                Button {
                    text: "\uE74D  " + qsTr("Borrar Todos")
                    font.family: "Segoe MDL2 Assets"
                    font.weight: Font.Medium
                    Material.background: Material.color(Material.Red)
                    contentItem: Label {
                        text: parent.text
                        font: parent.font
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: deleteAllConfirmDialog.open()
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
                        text: qsTr("Categoría")
                        Layout.preferredWidth: 140
                        font.bold: true
                        font.pixelSize: 13
                    }
                    Label { 
                        text: qsTr("SKU")
                        Layout.preferredWidth: 100
                        font.bold: true
                        font.pixelSize: 13
                    }
                    Label { 
                        text: qsTr("Stock")
                        Layout.preferredWidth: 70
                        font.bold: true
                        font.pixelSize: 13
                        horizontalAlignment: Text.AlignRight
                    }
                    Label { 
                        text: qsTr("Precio")
                        Layout.preferredWidth: 90
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
                            text: model.description ? 
                                model.description.substring(0, Math.min(50, model.description.length)) + 
                                (model.description.length > 50 ? "..." : "") : 
                                qsTr("Sin descripción")
                            font.pixelSize: 11
                            opacity: 0.6
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    Label {
                        text: model.category || qsTr("Sin categoría")
                        Layout.preferredWidth: 140
                        font.pixelSize: 12
                        elide: Text.ElideRight
                        opacity: 0.8
                    }

                    Label {
                        text: model.sku || "-"
                        Layout.preferredWidth: 100
                        font.pixelSize: 13
                        elide: Text.ElideRight
                    }

                    Label {
                        text: model.currentStock.toFixed(0)
                        Layout.preferredWidth: 70
                        horizontalAlignment: Text.AlignRight
                        color: model.isLowStock ? Material.color(Material.Orange) : Material.foreground
                        font.bold: model.isLowStock
                        font.pixelSize: 13
                    }

                    Label {
                        text: "S/" + model.salePrice.toFixed(2)
                        Layout.preferredWidth: 90
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
            Material.background: Material.theme === Material.Dark ? 
                Qt.darker(ApplicationWindow.window?.currentColors?.primary ?? Material.primary, 1.5) :
                Qt.darker(ApplicationWindow.window?.currentColors?.primary ?? Material.primary, 1.3)

            Label {
                anchors.centerIn: parent
                text: qsTr("%1 productos").arg(productModel.count)
                color: Material.theme === Material.Dark ? "#FFFFFF" : "#FFFFFF"
                font.weight: Font.Medium
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
        
        onOpened: root.layer.enabled = true
        onClosed: root.layer.enabled = false
        
        // Overlay con color semitransparente
        Overlay.modal: Rectangle {
            color: Material.theme === Material.Dark ? 
                Qt.rgba(0, 0, 0, 0.5) : 
                Qt.rgba(0.1, 0.1, 0.1, 0.4)
        }
        
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
        
        function openNewWithBarcode(barcode) {
            editMode = false
            errorLabel.visible = false
            nameField.text = ""
            skuField.text = ""
            barcodeField.text = barcode  // Precargar código de barras
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

        contentItem: ScrollView {
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            
            ColumnLayout {
                width: newProductDialog.availableWidth
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
                    
                    // Campo de categoría con autocompletado
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: categoryField.height
                        
                        TextField {
                            id: categoryField
                            width: parent.width
                            placeholderText: qsTr("Escribe para buscar categoría...")
                            
                            property var allCategories: productModel.availableCategories.filter(function(cat) { return cat !== "Todas" })
                            property var filteredCategories: []
                            
                            onTextChanged: {
                                // Filtrar categorías según el texto
                                var search = text.toLowerCase().trim()
                                if (search === "") {
                                    filteredCategories = allCategories
                                } else {
                                    filteredCategories = allCategories.filter(function(cat) {
                                        return cat.toLowerCase().includes(search)
                                    })
                                }
                                
                                // Mostrar popup si hay resultados
                                if (filteredCategories.length > 0 && activeFocus) {
                                    categoryPopup.open()
                                } else {
                                    categoryPopup.close()
                                }
                            }
                            
                            onActiveFocusChanged: {
                                if (activeFocus && filteredCategories.length > 0) {
                                    categoryPopup.open()
                                } else if (!activeFocus) {
                                    categoryPopup.close()
                                }
                            }
                            
                            // Navegación con teclado
                            Keys.onDownPressed: {
                                if (categoryPopup.visible && categoryListView.count > 0) {
                                    categoryListView.forceActiveFocus()
                                    categoryListView.currentIndex = 0
                                }
                            }
                            
                            Keys.onUpPressed: {
                                if (categoryPopup.visible) {
                                    categoryPopup.close()
                                }
                            }
                        }
                        
                        // Popup con lista de categorías
                        Popup {
                            id: categoryPopup
                            y: categoryField.height + 2
                            width: categoryField.width
                            height: Math.min(categoryListView.contentHeight + 10, 250)
                            
                            padding: 5
                            
                            background: Rectangle {
                                color: Material.background
                                border.color: Material.frameColor
                                border.width: 1
                                radius: 4
                                
                                layer.enabled: true
                                layer.effect: MultiEffect {
                                    shadowEnabled: true
                                    shadowColor: "#40000000"
                                    shadowVerticalOffset: 2
                                    shadowBlur: 0.4
                                }
                            }
                            
                            contentItem: ListView {
                                id: categoryListView
                                clip: true
                                
                                model: categoryField.filteredCategories
                                
                                delegate: ItemDelegate {
                                    width: categoryListView.width
                                    height: 40
                                    
                                    contentItem: Label {
                                        text: modelData
                                        verticalAlignment: Text.AlignVCenter
                                        leftPadding: 12
                                    }
                                    
                                    background: Rectangle {
                                        color: parent.hovered || categoryListView.currentIndex === index ? 
                                               Material.listHighlightColor : "transparent"
                                    }
                                    
                                    onClicked: {
                                        categoryField.text = modelData
                                        categoryPopup.close()
                                        categoryField.forceActiveFocus()
                                    }
                                }
                                
                                // Navegación con teclado
                                Keys.onReturnPressed: {
                                    if (currentIndex >= 0 && currentIndex < count) {
                                        categoryField.text = categoryField.filteredCategories[currentIndex]
                                        categoryPopup.close()
                                        categoryField.forceActiveFocus()
                                    }
                                }
                                
                                Keys.onEscapePressed: {
                                    categoryPopup.close()
                                    categoryField.forceActiveFocus()
                                }
                                
                                ScrollBar.vertical: ScrollBar {
                                    policy: ScrollBar.AsNeeded
                                }
                            }
                        }
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

                Label { 
                    text: qsTr("Descripción:"); 
                    font.weight: Font.Medium
                    Layout.topMargin: 8
                }
                
                TextArea {
                    id: descriptionField
                    Layout.fillWidth: true
                    Layout.preferredHeight: 120
                    placeholderText: qsTr("Descripción del producto (opcional)")
                    wrapMode: TextArea.Wrap
                    selectByMouse: true
                    
                    background: Rectangle {
                        color: Material.theme === Material.Dark ? 
                            Qt.lighter(Material.background, 1.2) : 
                            "white"
                        border.color: descriptionField.activeFocus ? 
                            (ApplicationWindow.window?.currentColors?.primary ?? Material.primary) : 
                            Material.color(Material.Grey, Material.Shade400)
                        border.width: descriptionField.activeFocus ? 2 : 1
                        radius: 4
                    }
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
                category: categoryField.text,
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
        
        onOpened: root.layer.enabled = true
        onClosed: root.layer.enabled = false
        
        // Overlay con color semitransparente
        Overlay.modal: Rectangle {
            color: Material.theme === Material.Dark ? 
                Qt.rgba(0, 0, 0, 0.5) : 
                Qt.rgba(0.1, 0.1, 0.1, 0.4)
        }

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
    
    // Diálogo de confirmación para borrar todos los productos (PASO 1)
    Dialog {
        id: deleteAllConfirmDialog
        title: qsTr("⚠️ ADVERTENCIA: Borrar Todos los Productos")
        modal: true
        anchors.centerIn: parent
        
        onOpened: root.layer.enabled = true
        onClosed: root.layer.enabled = false
        
        Overlay.modal: Rectangle {
            color: Material.theme === Material.Dark ? 
                Qt.rgba(0, 0, 0, 0.7) : 
                Qt.rgba(0.1, 0.1, 0.1, 0.6)
        }
        
        ColumnLayout {
            spacing: 16
            
            Label {
                text: qsTr("Esta acción eliminará TODOS los productos de la base de datos.")
                font.pixelSize: 14
                font.weight: Font.Medium
                color: Material.color(Material.Red)
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
            
            Label {
                text: qsTr("Total de productos: %1").arg(productModel.count)
                font.pixelSize: 13
                Layout.fillWidth: true
            }
            
            Label {
                text: qsTr("⚠️ Esta operación NO se puede deshacer.")
                font.pixelSize: 13
                font.weight: Font.Bold
                color: Material.color(Material.Red)
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
            
            Label {
                text: qsTr("¿Está seguro de que desea continuar?")
                font.pixelSize: 13
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
        }
        
        standardButtons: Dialog.Yes | Dialog.No
        
        onAccepted: {
            deleteAllFinalDialog.open()
        }
    }
    
    // Diálogo de confirmación final (PASO 2)
    Dialog {
        id: deleteAllFinalDialog
        title: qsTr("🛑 CONFIRMACIÓN FINAL")
        modal: true
        anchors.centerIn: parent
        
        onOpened: root.layer.enabled = true
        onClosed: root.layer.enabled = false
        
        Overlay.modal: Rectangle {
            color: Material.theme === Material.Dark ? 
                Qt.rgba(0, 0, 0, 0.8) : 
                Qt.rgba(0.1, 0.1, 0.1, 0.7)
        }
        
        ColumnLayout {
            spacing: 16
            
            Label {
                text: qsTr("ÚLTIMA ADVERTENCIA")
                font.pixelSize: 16
                font.weight: Font.Bold
                color: Material.color(Material.Red)
                Layout.fillWidth: true
            }
            
            Label {
                text: qsTr("Se eliminarán %1 productos permanentemente.").arg(productModel.count)
                font.pixelSize: 14
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
            
            Label {
                text: qsTr("Para confirmar, escriba 'BORRAR' en el campo de abajo:")
                font.pixelSize: 13
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
            
            TextField {
                id: confirmTextField
                Layout.fillWidth: true
                placeholderText: qsTr("Escriba BORRAR para confirmar")
            }
        }
        
        standardButtons: Dialog.Ok | Dialog.Cancel
        
        onAccepted: {
            if (confirmTextField.text.toUpperCase() === "BORRAR") {
                productModel.deleteAllProducts()
                confirmTextField.text = ""
            } else {
                errorLabel.text = qsTr("Debe escribir 'BORRAR' para confirmar")
                errorLabel.visible = true
            }
        }
        
        onRejected: {
            confirmTextField.text = ""
        }
    }}