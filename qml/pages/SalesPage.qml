import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import SistemaInventario 1.0

Page {
    id: root
    title: qsTr("Ventas")
    
    Component.onCompleted: {
        // Inicializar totales
        updateTotals()
    }

    // ViewModel del carrito de ventas (base de datos real)
    SalesCartViewModel {
        id: viewModel

        onProductAdded: function(productName, quantity) {
            console.log("Producto agregado:", productName, "x", quantity)
            notificationLabel.text = "✓ Agregado: " + productName + " (x" + quantity + ")"
            notificationLabel.visible = true
            notificationTimer.restart()
        }

        onProductNotFound: function(code) {
            notificationLabel.text = "✗ Producto no encontrado: " + code
            notificationLabel.visible = true
            notificationTimer.restart()
        }

        onInsufficientStock: function(productName, available, requested) {
            notificationLabel.text = "✗ Stock insuficiente de " + productName + 
                                     ". Disponible: " + available + ", solicitado: " + requested
            notificationLabel.visible = true
            notificationTimer.restart()
        }

        onSaleCompleted: function(invoiceNumber, total) {
            successDialog.invoiceNumber = invoiceNumber
            successDialog.total = total
            successDialog.open()
            searchField.text = ""
            quantitySpinBox.value = 1
        }

        onSaleFailed: function(errorMessage) {
            errorDialog.errorMessage = errorMessage
            errorDialog.open()
        }
    }

    // Modelo de productos para búsqueda (base de datos real)
    ProductListModel {
        id: productsModel
        
        Component.onCompleted: {
            // Cargar todos los productos al iniciar
            loadProducts()
        }
    }
    
    // Conexiones para actualizar totales automáticamente cuando cambia el carrito
    Connections {
        target: viewModel.cart
        
        function onSubtotalChanged() {
            updateTotals()
        }
        
        function onTotalChanged() {
            updateTotals()
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        // ===== COLUMNA IZQUIERDA: Búsqueda y Lista de Productos =====
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: parent.width * 0.6
            spacing: 16

            // Header
            Label {
                text: "\uE8C8  " + qsTr("Nueva Venta")
                font.family: "Segoe MDL2 Assets"
                font.pixelSize: 28
                font.weight: Font.Bold
            }

            // Búsqueda de productos
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                TextField {
                    id: searchField
                    Layout.fillWidth: true
                    placeholderText: qsTr("Buscar producto por código de barras o SKU...")
                    font.pixelSize: 14

                    Keys.onReturnPressed: {
                        if (text.trim() !== "") {
                            addProductToCart(text.trim())
                            text = ""
                        }
                    }

                    onTextChanged: {
                        if (text.length > 0) {
                            searchTimer.restart()
                        }
                    }

                    Timer {
                        id: searchTimer
                        interval: 300
                        repeat: false
                        onTriggered: {
                            if (searchField.text.trim() !== "") {
                                searchProducts(searchField.text.trim())
                            }
                        }
                    }
                }

                Button {
                    text: "\uE71E"  // Scan icon
                    font.family: "Segoe MDL2 Assets"
                    font.pixelSize: 18
                    flat: true
                    Material.foreground: Material.primary
                    ToolTip.visible: hovered
                    ToolTip.text: qsTr("Escanear código de barras")
                    
                    background: Rectangle {
                        implicitWidth: 40
                        implicitHeight: 40
                        radius: 4
                        color: parent.down ? Qt.darker(Material.primary, 1.2) : 
                               parent.hovered ? Qt.lighter(Material.primary, 1.8) : "transparent"
                        border.width: 1
                        border.color: Material.primary
                        
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    
                    onClicked: searchField.forceActiveFocus()
                }

                Button {
                    text: "\uE11A"  // Search icon
                    font.family: "Segoe MDL2 Assets"
                    font.pixelSize: 16
                    Material.background: Material.primary
                    Material.foreground: "white"
                    
                    onClicked: {
                        if (searchField.text.trim() !== "") {
                            addProductToCart(searchField.text.trim())
                            searchField.text = ""
                        }
                    }
                }
            }

            // Cantidad rápida
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Label {
                    text: qsTr("Cantidad:")
                    font.pixelSize: 13
                }

                SpinBox {
                    id: quantitySpinBox
                    from: 1
                    to: 9999
                    value: 1
                    editable: true
                    Layout.preferredWidth: 120
                }

                Label {
                    text: qsTr("(Presiona Enter en búsqueda para agregar)")
                    font.pixelSize: 11
                    opacity: 0.6
                    Layout.fillWidth: true
                }
            }

            // Sugerencias de productos (ListView)
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Material.background
                border.color: Material.frameColor
                border.width: 1
                radius: 8

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    Label {
                        text: qsTr("Productos Sugeridos")
                        font.pixelSize: 14
                        font.weight: Font.Medium
                    }

                    ListView {
                        id: productsListView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 4

                        model: productsModel

                        delegate: ItemDelegate {
                            width: ListView.view.width
                            height: 60

                            background: Rectangle {
                                color: parent.hovered ? 
                                       (Material.theme === Material.Dark ? 
                                        Qt.lighter(Material.background, 1.2) :
                                        Material.color(Material.Grey, Material.Shade200)) : 
                                       "transparent"
                                radius: 6
                                
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }

                            contentItem: RowLayout {
                                spacing: 12

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Label {
                                        text: model.name
                                        font.pixelSize: 14
                                        font.weight: Font.Medium
                                        color: Material.foreground
                                    }

                                    Label {
                                        text: "SKU: " + model.sku + " | Stock: " + model.currentStock
                                        font.pixelSize: 11
                                        opacity: 0.7
                                        color: Material.foreground
                                    }
                                }

                                Label {
                                    text: "S/" + model.salePrice.toFixed(2)
                                    font.pixelSize: 16
                                    font.weight: Font.Bold
                                    color: Material.primary
                                }

                                RoundButton {
                                    text: "\uE109"  // Add icon
                                    font.family: "Segoe MDL2 Assets"
                                    font.pixelSize: 18
                                    flat: true
                                    implicitWidth: 40
                                    implicitHeight: 40
                                    Material.foreground: Material.primary
                                    
                                    background: Rectangle {
                                        radius: 20
                                        color: parent.hovered ? 
                                               (Material.theme === Material.Dark ?
                                                Qt.darker(Material.primary, 1.5) :
                                                Material.color(Material.primary, Material.Shade100)) :
                                               "transparent"
                                        border.width: 1
                                        border.color: parent.hovered ? Material.primary : "transparent"
                                        
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                        Behavior on border.color { ColorAnimation { duration: 150 } }
                                    }
                                    
                                    onClicked: addProductByIdToCart(model.productId, quantitySpinBox.value)
                                }
                            }

                            onClicked: addProductByIdToCart(model.productId, quantitySpinBox.value)
                        }

                        ScrollBar.vertical: ScrollBar {}

                        Label {
                            anchors.centerIn: parent
                            text: qsTr("Busca productos para agregarlos al carrito")
                            font.pixelSize: 13
                            opacity: 0.5
                            visible: productsListView.count === 0
                            color: Material.foreground
                        }
                    }
                }
            }
        }

        // ===== COLUMNA DERECHA: Carrito y Total =====
        ScrollView {
            Layout.fillHeight: true
            Layout.preferredWidth: parent.width * 0.4
            Layout.minimumWidth: 400
            clip: true
            
            ScrollBar.vertical.policy: ScrollBar.AsNeeded
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            
            ColumnLayout {
                width: parent.width
                spacing: 16

                // Header del carrito
                RowLayout {
                    Layout.fillWidth: true

                    Label {
                        text: "\uE7BF  " + qsTr("Carrito de Compras")
                        font.family: "Segoe MDL2 Assets"
                        font.pixelSize: 20
                        font.weight: Font.Bold
                        Layout.fillWidth: true
                    }

                    Label {
                        text: viewModel.cart.rowCount() + " items"
                        font.pixelSize: 12
                        opacity: 0.7
                    }
                }

            // Items del carrito
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Material.background
                border.color: Material.primary
                border.width: 2
                radius: 8

                ListView {
                    id: cartListView
                    anchors.fill: parent
                    anchors.margins: 12
                    clip: true
                    spacing: 8

                    model: viewModel.cart

                    delegate: Item {
                        width: ListView.view.width
                        height: cardRect.height + 6
                        
                        // Sombra simulada con rectángulo de fondo
                        Rectangle {
                            anchors.fill: cardRect
                            anchors.topMargin: 3
                            anchors.leftMargin: 2
                            anchors.rightMargin: 2
                            radius: 8
                            color: "#20000000"
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
                            border.color: Material.primary
                            border.width: 1
                            radius: 8
                            visible: true
                            
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
                                    color: Material.theme === Material.Dark ?
                                           Qt.darker(Material.primary, 1.5) :
                                           Material.color(Material.primary, Material.Shade100)
                                    
                                    Label {
                                        anchors.centerIn: parent
                                        text: "\uE7BF"  // Shopping bag icon
                                        font.family: "Segoe MDL2 Assets"
                                        font.pixelSize: 26
                                        color: Material.primary
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: 6

                                    Label {
                                        text: model.productName
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
                                            text: "S/" + model.unitPrice.toFixed(2)
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
                                                text: model.quantity
                                                font.pixelSize: 11
                                                font.weight: Font.Bold
                                                color: Material.foreground
                                            }
                                        }
                                    }

                                    Rectangle {
                                        Layout.preferredHeight: 26
                                        Layout.preferredWidth: subtotalLabel.width + 18
                                        radius: 5
                                        color: Material.theme === Material.Dark ?
                                               Qt.darker(Material.primary, 1.8) :
                                               Material.color(Material.primary, Material.Shade50)
                                        
                                        Label {
                                            id: subtotalLabel
                                            anchors.centerIn: parent
                                            text: "S/" + model.subtotal.toFixed(2)
                                            font.pixelSize: 13
                                            font.weight: Font.Bold
                                            color: Material.primary
                                        }
                                    }
                                }

                                ColumnLayout {
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: 10

                                    SpinBox {
                                        id: itemQuantitySpinBox
                                        from: 1
                                        to: model.maxQuantity
                                        value: model.quantity
                                        editable: true
                                        Layout.preferredWidth: 110
                                        Layout.preferredHeight: 40

                                        onValueModified: {
                                            updateCartItemQuantity(index, value)
                                        }
                                    }

                                    Button {
                                        text: "\uE74D"  // Delete icon
                                        font.family: "Segoe MDL2 Assets"
                                        font.pixelSize: 18
                                        flat: true
                                        Layout.preferredWidth: 44
                                        Layout.preferredHeight: 44
                                        
                                        Material.foreground: Material.color(Material.Red)
                                        
                                        background: Rectangle {
                                            radius: 6
                                            color: parent.down ? Material.color(Material.Red, Material.Shade200) :
                                                   parent.hovered ? Material.color(Material.Red, Material.Shade100) : "transparent"
                                            border.width: parent.hovered ? 1 : 0
                                            border.color: Material.color(Material.Red)
                                            
                                            Behavior on color { ColorAnimation { duration: 150 } }
                                        }
                                        
                                        onClicked: removeCartItem(index)
                                    }
                                }
                            }
                        }
                    }

                    ScrollBar.vertical: ScrollBar {}

                    // Empty state
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 12
                        visible: cartListView.count === 0

                        Label {
                            text: "\uE7BF"
                            font.family: "Segoe MDL2 Assets"
                            font.pixelSize: 64
                            opacity: 0.3
                            Layout.alignment: Qt.AlignHCenter
                            color: Material.foreground
                        }

                        Label {
                            text: qsTr("Carrito vacío")
                            font.pixelSize: 16
                            opacity: 0.5
                            Layout.alignment: Qt.AlignHCenter
                            color: Material.foreground
                        }

                        Label {
                            text: qsTr("Agrega productos usando la búsqueda")
                            font.pixelSize: 12
                            opacity: 0.4
                            Layout.alignment: Qt.AlignHCenter
                            color: Material.foreground
                        }
                    }
                }
            }

            // Resumen de totales
            Rectangle {
                Layout.fillWidth: true
                color: Material.theme === Material.Dark ?
                       Qt.lighter(Material.background, 1.15) :
                       Material.color(Material.Grey, Material.Shade100)
                radius: 8
                height: totalsColumn.height + 24
                border.width: Material.theme === Material.Dark ? 1 : 0
                border.color: Material.frameColor

                ColumnLayout {
                    id: totalsColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: 12
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true

                        Label {
                            text: qsTr("Subtotal:")
                            font.pixelSize: 14
                            Layout.fillWidth: true
                            color: Material.foreground
                        }

                        Label {
                            id: subtotalLabel
                            text: "S/0.00"
                            font.pixelSize: 14
                            font.weight: Font.Medium
                            color: Material.foreground
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        Label {
                            text: qsTr("Descuento:")
                            font.pixelSize: 13
                            Layout.fillWidth: true
                            color: Material.foreground
                        }

                        SpinBox {
                            id: discountSpinBox
                            from: 0
                            to: 100000
                            value: 0
                            editable: true
                            stepSize: 100
                            Layout.preferredWidth: 120

                            property real realValue: value / 100

                            textFromValue: function(value) {
                                return "S/" + (value / 100).toFixed(2)
                            }

                            valueFromText: function(text) {
                                return parseFloat(text.replace("S/", "")) * 100
                            }

                            onValueModified: updateTotals()
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Material.frameColor
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        Label {
                            text: qsTr("TOTAL:")
                            font.pixelSize: 18
                            font.weight: Font.Bold
                            Layout.fillWidth: true
                            color: Material.foreground
                        }

                        Label {
                            id: totalLabel
                            text: "S/0.00"
                            font.pixelSize: 24
                            font.weight: Font.Bold
                            color: Material.primary
                        }
                    }
                }
            }

            // Información del cliente
            GroupBox {
                Layout.fillWidth: true
                title: qsTr("Cliente")

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 8

                    ComboBox {
                        id: customerComboBox
                        Layout.fillWidth: true
                        model: ["Cliente General", "Cliente Frecuente", "Empresa XYZ"]
                        // TODO: Conectar con modelo real de clientes
                    }
                }
            }

            // Tipo de Comprobante
            GroupBox {
                Layout.fillWidth: true
                title: qsTr("Tipo de Comprobante")

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 12

                    ButtonGroup {
                        id: voucherTypeGroup
                    }

                    RowLayout {
                        spacing: 12
                        Layout.fillWidth: true

                        RadioButton {
                            id: boletaRadio
                            text: qsTr("Boleta")
                            checked: true
                            ButtonGroup.group: voucherTypeGroup
                            font.pixelSize: 13
                        }

                        RadioButton {
                            id: facturaRadio
                            text: qsTr("Factura (RUC)")
                            ButtonGroup.group: voucherTypeGroup
                            font.pixelSize: 13
                        }
                    }

                    // Campos adicionales para Factura
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        visible: facturaRadio.checked

                        TextField {
                            id: rucField
                            Layout.fillWidth: true
                            placeholderText: qsTr("RUC (11 dígitos)")
                            validator: RegularExpressionValidator { regularExpression: /\d{11}/ }
                            maximumLength: 11
                        }

                        TextField {
                            id: businessNameField
                            Layout.fillWidth: true
                            placeholderText: qsTr("Razón Social")
                        }

                        TextField {
                            id: addressField
                            Layout.fillWidth: true
                            placeholderText: qsTr("Dirección")
                        }
                    }
                }
            }

            // Método de pago
            GroupBox {
                Layout.fillWidth: true
                title: qsTr("Método de Pago")

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 8

                    ComboBox {
                        id: paymentMethodComboBox
                        Layout.fillWidth: true
                        model: ["Efectivo", "Tarjeta", "Transferencia"]
                        // TODO: Conectar con modelo real de métodos de pago
                    }
                }
            }

            // Botones de acción
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Button {
                    text: qsTr("Cancelar")
                    Layout.preferredWidth: 100
                    Material.background: "transparent"
                    Material.foreground: Material.foreground
                    
                    background: Rectangle {
                        implicitWidth: 100
                        implicitHeight: 40
                        radius: 4
                        color: parent.down ? Material.color(Material.Grey, Material.Shade300) :
                               parent.hovered ? Material.color(Material.Grey, Material.Shade200) : "transparent"
                        border.width: 1
                        border.color: Material.frameColor
                        
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    
                    onClicked: cancelSale()
                }

                Button {
                    text: qsTr("Procesar Venta")
                    Layout.fillWidth: true
                    enabled: viewModel.cart.rowCount() > 0 && (!facturaRadio.checked || (rucField.acceptableInput && businessNameField.text !== ""))
                    Material.background: Material.primary
                    Material.foreground: "white"
                    
                    onClicked: processSale()
                }

                RoundButton {
                    text: "\uE749"  // Print icon
                    font.family: "Segoe MDL2 Assets"
                    font.pixelSize: 18
                    Layout.preferredWidth: 48
                    Layout.preferredHeight: 48
                    enabled: false  // Se habilitará después de procesar venta
                    ToolTip.visible: hovered
                    ToolTip.text: qsTr("Imprimir comprobante")
                    
                    Material.background: Material.color(Material.Grey, Material.Shade200)
                    Material.foreground: Material.foreground
                    
                    onClicked: printVoucher()
                }
            }
        }  // Fin ColumnLayout dentro de ScrollView
        }  // Fin ScrollView columna derecha
    }

    // ===== FUNCIONES JAVASCRIPT =====

    function searchProducts(searchText) {
        // Buscar productos en la base de datos real
        console.log("Buscando productos:", searchText)
        productsModel.searchProducts(searchText)
    }

    function addProductToCart(code) {
        // Usar el ViewModel real para agregar productos
        console.log("Agregando producto por código:", code, "cantidad:", quantitySpinBox.value)
        
        let success = viewModel.searchAndAddProduct(code, quantitySpinBox.value)
        
        if (success) {
            searchField.text = ""
            quantitySpinBox.value = 1
        }
    }

    function addProductByIdToCart(productId, quantity) {
        // Usar el ViewModel real para agregar por ID
        console.log("Agregando producto por ID:", productId, "cantidad:", quantity)
        
        let success = viewModel.addProductById(productId, quantity)
        
        if (success) {
            quantitySpinBox.value = 1
        }
    }

    function removeCartItem(index) {
        // Usar el cart del viewModel real
        viewModel.cart.removeItem(index)
    }

    function updateCartItemQuantity(index, newQuantity) {
        // Usar el cart del viewModel real
        viewModel.cart.updateQuantity(index, newQuantity)
    }

    function updateTotals() {
        // Los totales se calculan automáticamente en el cart del viewModel
        let subtotal = viewModel.cart.subtotal
        
        subtotalLabel.text = "S/" + subtotal.toFixed(2)
        
        let discount = discountSpinBox.realValue
        let total = subtotal - discount
        
        totalLabel.text = "S/" + total.toFixed(2)
    }

    function cancelSale() {
        // Usar el viewModel real
        viewModel.cancelSale()
        discountSpinBox.value = 0
        searchField.text = ""
        quantitySpinBox.value = 1
    }

    function processSale() {
        // Usar el viewModel real para procesar la venta
        console.log("Procesando venta...")
        
        // Datos del cliente (por ahora sin cliente específico)
        let customerId = 0  // 0 = cliente genérico
        let customerName = "Cliente General"
        
        // Método de pago desde el ComboBox
        let paymentMethodId = paymentMethodComboBox.currentIndex + 1  // 1=Efectivo, 2=Tarjeta, 3=Transferencia
        let paymentMethodName = paymentMethodComboBox.currentText
        
        // Descuento
        let discount = discountSpinBox.realValue
        
        // Notas adicionales
        let voucherType = facturaRadio.checked ? "FACTURA" : "BOLETA"
        let notes = voucherType
        if (facturaRadio.checked) {
            notes += " - RUC: " + rucField.text + " - " + businessNameField.text
        }
        
        console.log("Parámetros de venta:", {
            customerId: customerId,
            customerName: customerName,
            paymentMethodId: paymentMethodId,
            paymentMethodName: paymentMethodName,
            discount: discount,
            notes: notes
        })
        
        // Procesar venta en el backend
        let success = viewModel.processSale(
            customerId, 
            customerName, 
            paymentMethodId, 
            paymentMethodName, 
            discount, 
            notes
        )
        
        console.log("Resultado de processSale:", success)
        
        if (success) {
            // Guardar datos para impresión
            successDialog.voucherType = voucherType
            successDialog.ruc = facturaRadio.checked ? rucField.text : ""
            successDialog.businessName = facturaRadio.checked ? businessNameField.text : ""
            successDialog.address = facturaRadio.checked ? addressField.text : ""
            successDialog.total = viewModel.cart.total
            
            // Mostrar mensaje de éxito
            successDialog.open()
        } else {
            console.error("Error: processSale retornó false")
        }
    }

    function printVoucher() {
        console.log("Imprimiendo comprobante...")
        console.log("Tipo:", successDialog.voucherType)
        console.log("RUC:", successDialog.ruc)
        console.log("Razón Social:", successDialog.businessName)
        console.log("Dirección:", successDialog.address)
        console.log("Total:", successDialog.total)
        
        // TODO: Implementar impresión real con Qt PrintSupport
        // Por ahora solo muestra el diálogo de vista previa
        printDialog.open()
    }

    // Diálogo de confirmación de venta
    Dialog {
        id: successDialog
        title: qsTr("✓ Venta Exitosa")
        modal: true
        anchors.centerIn: parent
        width: 400

        property string invoiceNumber: "FACT-0001"
        property real total: 0.0
        property string voucherType: "BOLETA"
        property string ruc: ""
        property string businessName: ""
        property string address: ""

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
                color: Material.color(Material.Green, Material.Shade100)
                radius: 8
                border.width: 2
                border.color: Material.color(Material.Green, Material.Shade500)

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 8

                    Label {
                        text: successDialog.voucherType
                        font.pixelSize: 16
                        font.weight: Font.Bold
                        Layout.alignment: Qt.AlignHCenter
                        color: Material.color(Material.Green, Material.Shade900)
                    }

                    Label {
                        text: qsTr("Nº: ") + successDialog.invoiceNumber
                        font.pixelSize: 13
                        font.weight: Font.Bold
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Label {
                        text: qsTr("Total: S/") + successDialog.total.toFixed(2)
                        font.pixelSize: 18
                        font.weight: Font.Bold
                        Layout.alignment: Qt.AlignHCenter
                        color: Material.primary
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                visible: successDialog.voucherType === "FACTURA"

                Label {
                    text: qsTr("RUC: ") + successDialog.ruc
                    font.pixelSize: 12
                }

                Label {
                    text: qsTr("Razón Social: ") + successDialog.businessName
                    font.pixelSize: 12
                }

                Label {
                    text: qsTr("Dirección: ") + successDialog.address
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
                    Material.background: Material.primary
                    Material.foreground: "white"
                    
                    onClicked: {
                        printVoucher()
                        successDialog.close()
                    }
                }

                Button {
                    text: qsTr("Cerrar")
                    Layout.fillWidth: true
                    Material.background: "transparent"
                    Material.foreground: Material.foreground
                    
                    background: Rectangle {
                        implicitHeight: 40
                        radius: 4
                        color: parent.down ? Material.color(Material.Grey, Material.Shade300) :
                               parent.hovered ? Material.color(Material.Grey, Material.Shade200) : "transparent"
                        border.width: 1
                        border.color: Material.frameColor
                        
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    
                    onClicked: successDialog.close()
                }
            }
        }
    }

    // Diálogo de error
    Dialog {
        id: errorDialog
        title: qsTr("Error en la Venta")
        modal: true
        anchors.centerIn: parent
        width: 400

        property string errorMessage: ""

        ColumnLayout {
            anchors.fill: parent
            spacing: 16

            Label {
                text: errorDialog.errorMessage
                font.pixelSize: 14
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                color: Material.color(Material.Red)
            }

            Button {
                text: qsTr("Cerrar")
                Layout.fillWidth: true
                Material.background: Material.primary
                Material.foreground: "white"
                
                onClicked: errorDialog.close()
            }
        }
    }

    // Diálogo de vista previa de impresión
    Dialog {
        id: printDialog
        title: qsTr("Vista Previa - ") + successDialog.voucherType
        modal: true
        anchors.centerIn: parent
        width: 400
        height: 600

        ColumnLayout {
            anchors.fill: parent
            spacing: 12

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                Rectangle {
                    width: 350
                    height: contentColumn.height + 40
                    color: "white"
                    border.width: 1
                    border.color: "#ccc"

                    ColumnLayout {
                        id: contentColumn
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 12

                        // Header
                        Label {
                            text: "SISTEMA DE INVENTARIO"
                            font.pixelSize: 16
                            font.weight: Font.Bold
                            Layout.alignment: Qt.AlignHCenter
                            color: "#000"
                        }

                        Label {
                            text: "RUC: 20123456789"
                            font.pixelSize: 10
                            Layout.alignment: Qt.AlignHCenter
                            color: "#000"
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 2
                            color: "#000"
                        }

                        // Tipo de comprobante
                        Label {
                            text: successDialog.voucherType
                            font.pixelSize: 14
                            font.weight: Font.Bold
                            Layout.alignment: Qt.AlignHCenter
                            color: "#000"
                        }

                        Label {
                            text: "Nº " + successDialog.invoiceNumber
                            font.pixelSize: 12
                            Layout.alignment: Qt.AlignHCenter
                            color: "#000"
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: "#ccc"
                        }

                        // Cliente
                        Label {
                            text: "CLIENTE: " + customerComboBox.currentText
                            font.pixelSize: 10
                            color: "#000"
                        }

                        ColumnLayout {
                            spacing: 2
                            visible: successDialog.voucherType === "FACTURA"

                            Label {
                                text: "RUC: " + successDialog.ruc
                                font.pixelSize: 10
                                color: "#000"
                            }

                            Label {
                                text: successDialog.businessName
                                font.pixelSize: 10
                                color: "#000"
                            }

                            Label {
                                text: successDialog.address
                                font.pixelSize: 10
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                                color: "#000"
                            }
                        }

                        Label {
                            text: "FECHA: " + new Date().toLocaleString(Qt.locale(), "dd/MM/yyyy hh:mm")
                            font.pixelSize: 10
                            color: "#000"
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: "#000"
                        }

                        // Items (simulado)
                        GridLayout {
                            Layout.fillWidth: true
                            columns: 3
                            columnSpacing: 8

                            Label {
                                text: "PRODUCTO"
                                font.pixelSize: 9
                                font.weight: Font.Bold
                                color: "#000"
                            }
                            Label {
                                text: "CANT"
                                font.pixelSize: 9
                                font.weight: Font.Bold
                                color: "#000"
                            }
                            Label {
                                text: "PRECIO"
                                font.pixelSize: 9
                                font.weight: Font.Bold
                                horizontalAlignment: Text.AlignRight
                                Layout.fillWidth: true
                                color: "#000"
                            }
                        }

                        Repeater {
                            model: viewModel.cart
                            delegate: GridLayout {
                                Layout.fillWidth: true
                                columns: 3
                                columnSpacing: 8

                                Label {
                                    text: model.productName
                                    font.pixelSize: 9
                                    color: "#000"
                                }
                                Label {
                                    text: model.quantity
                                    font.pixelSize: 9
                                    color: "#000"
                                }
                                Label {
                                    text: "S/" + model.subtotal.toFixed(2)
                                    font.pixelSize: 9
                                    horizontalAlignment: Text.AlignRight
                                    Layout.fillWidth: true
                                    color: "#000"
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: "#000"
                        }

                        // Totales
                        RowLayout {
                            Layout.fillWidth: true

                            Label {
                                text: "SUBTOTAL:"
                                font.pixelSize: 10
                                Layout.fillWidth: true
                                color: "#000"
                            }
                            Label {
                                text: subtotalLabel.text
                                font.pixelSize: 10
                                color: "#000"
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            visible: discountSpinBox.value > 0

                            Label {
                                text: "DESCUENTO:"
                                font.pixelSize: 10
                                Layout.fillWidth: true
                                color: "#000"
                            }
                            Label {
                                text: "-S/" + discountSpinBox.realValue.toFixed(2)
                                font.pixelSize: 10
                                color: "#000"
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true

                            Label {
                                text: "TOTAL:"
                                font.pixelSize: 12
                                font.weight: Font.Bold
                                Layout.fillWidth: true
                                color: "#000"
                            }
                            Label {
                                text: totalLabel.text
                                font.pixelSize: 12
                                font.weight: Font.Bold
                                color: "#000"
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 2
                            color: "#000"
                        }

                        Label {
                            text: "¡Gracias por su compra!"
                            font.pixelSize: 10
                            Layout.alignment: Qt.AlignHCenter
                            color: "#000"
                        }
                    }
                }
            }

            RowLayout {
                spacing: 12

                Button {
                    text: "\uE749  " + qsTr("Imprimir")
                    font.family: "Segoe MDL2 Assets"
                    Layout.fillWidth: true
                    Material.background: Material.primary
                    Material.foreground: "white"
                    
                    onClicked: {
                        console.log("Enviando a imprimir...")
                        // TODO: Implementar impresión real con QPrinter
                        printDialog.close()
                    }
                }

                Button {
                    text: qsTr("Cancelar")
                    Layout.fillWidth: true
                    Material.background: "transparent"
                    Material.foreground: Material.foreground
                    
                    background: Rectangle {
                        implicitHeight: 40
                        radius: 4
                        color: parent.down ? Material.color(Material.Grey, Material.Shade300) :
                               parent.hovered ? Material.color(Material.Grey, Material.Shade200) : "transparent"
                        border.width: 1
                        border.color: Material.frameColor
                        
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    
                    onClicked: printDialog.close()
                }
            }
        }
    }

    // Barra de notificaciones
    Rectangle {
        id: notificationBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 20
        height: 50
        radius: 8
        color: Material.primary
        visible: notificationLabel.visible
        z: 999

        Label {
            id: notificationLabel
            anchors.centerIn: parent
            color: "white"
            font.pixelSize: 14
            font.weight: Font.Medium
            visible: false
        }

        Timer {
            id: notificationTimer
            interval: 3000
            onTriggered: notificationLabel.visible = false
        }
    }
}
