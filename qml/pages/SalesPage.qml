import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Effects
import Qt.labs.settings
import SistemaInventario 1.0
import "../components"

Page {
    id: root
    title: qsTr("Ventas")
    
    // Habilitar captura de teclas para escáner de código de barras
    focus: true
    
    Component.onCompleted: {
        console.log("*** SalesPage: Página cargada, forzando foco ***")
        root.forceActiveFocus()
        // Los totales se calculan automáticamente desde el ViewModel
        console.log("*** SalesPage: ViewModels inicializados ***")
        
        // Asignar automáticamente el usuario logueado como cajero
        if (authService && authService.currentUserFullName) {
            viewModel.cashierName = authService.currentUserFullName
            console.log("*** SalesPage: Cajero asignado automáticamente:", authService.currentUserFullName, "***")
        }
        
        // Cargar datos guardados de factura
        if (salesSettings.savedRuc !== "") {
            rucField.text = salesSettings.savedRuc
        }
        if (salesSettings.savedBusinessName !== "") {
            businessNameField.text = salesSettings.savedBusinessName
        }
        if (salesSettings.savedAddress !== "") {
            addressField.text = salesSettings.savedAddress
        }
    }
    
    onActiveFocusChanged: {
        console.log("*** SalesPage: Foco activo =", activeFocus, "***")
    }
    
    Keys.onPressed: function(event) {
        console.log("*** SalesPage: Keys.onPressed disparado - Tecla:", event.key, "Texto:", event.text, "***")
        // Solo procesar si no hay diálogos abiertos
        if (!successDialog.opened && !errorDialog.opened && !printDialog.opened && !quantityDialog.opened) {
            // Capturar caracteres alfanuméricos del escáner
            if (event.text.length > 0) {
                console.log("SalesPage: Tecla presionada:", event.text)
                barcodeScanner.processCharacter(event.text)
                event.accepted = true
            }
            // Enter finaliza el escaneo - IMPORTANTE: enviar al handler
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                console.log("SalesPage: Enter detectado, finalizando escaneo")
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
    
    // Exponer ViewModels para que Main.qml pueda conectarse a sus señales
    property alias viewModel: viewModel
    property alias printViewModel: printViewModel
    
    // Datos temporales del cliente para la venta actual
    property int currentCustomerId: 0  // 0 = cliente genérico
    property string currentCustomerName: "Cliente General"
    property string currentCustomerDocument: ""
    property string currentRuc: ""
    property string currentBusinessName: ""
    property string currentAddress: ""
    
    // Último código de barras escaneado para detectar duplicados
    property string lastScannedBarcode: ""
    
    // Settings para persistir datos de factura
    Settings {
        id: salesSettings
        category: "SalesInvoiceData"
        property string savedRuc: ""
        property string savedBusinessName: ""
        property string savedAddress: ""
        property string savedPhone: ""
        property string savedEmail: ""
    }
    
    // MouseArea para capturar clics y mantener el foco
    MouseArea {
        anchors.fill: parent
        propagateComposedEvents: true
        z: -1
        onClicked: function(mouse) {
            console.log("*** SalesPage: Clic detectado, restaurando foco ***")
            root.forceActiveFocus()
            mouse.accepted = false
        }
    }
    
    // Función para procesar la venta después de confirmar el pago
    function processSaleAfterPayment() {
        console.log("=== PROCESAR VENTA ===")
        console.log("  Items en carrito:", viewModel.cart.count)
        console.log("  Subtotal:", viewModel.cart.subtotal)
        console.log("  Descuento:", viewModel.discount)
        console.log("  Total:", viewModel.totalWithDiscount)
        console.log("  Cliente ID:", root.currentCustomerId)
        console.log("  Cliente:", root.currentCustomerName)
        console.log("  Tipo de pago:", paymentTypeComboBox.currentText)
        console.log("  Método de pago:", paymentMethodComboBox.currentText)
        console.log("  Monto pagado:", viewModel.amountPaid)
        console.log("  Vuelto:", viewModel.changeGiven)
        
        // Guardar datos de factura temporalmente para usar después de onSaleCompleted
        root.currentRuc = facturaRadio.checked ? rucField.text : ""
        root.currentBusinessName = facturaRadio.checked ? businessNameField.text : ""
        root.currentAddress = facturaRadio.checked ? addressField.text : ""
        
        console.log("  Es factura:", facturaRadio.checked)

        // Llamar al ViewModel con todos los datos incluyendo tipo y método de pago
        var result = viewModel.processSaleWithInvoiceData(
            root.currentCustomerId,  // customerId real del selector
            root.currentCustomerName,
            paymentMethodComboBox.currentIndex + 1,  // paymentMethodId (1, 2, 3, 4, 5)
            paymentMethodComboBox.currentText,
            facturaRadio.checked,  // isInvoice
            root.currentRuc,
            root.currentBusinessName,
            root.currentAddress,
            paymentTypeComboBox.currentIndex === 0 ? "CONTADO" : "CREDITO"  // paymentType
        )
        
        console.log("  Resultado processSaleWithInvoiceData:", result)
    }

        // ViewModel del carrito de ventas (base de datos real)
        SalesCartViewModel {
            id: viewModel

            onProductAdded: function(productName, quantity) {
                console.log("Producto agregado:", productName, "x", quantity)
            }

            onProductNotFound: function(code) {
                console.log("Producto no encontrado:", code)
            }

            onInsufficientStock: function(productName, available, requested) {
                console.log("Stock insuficiente de", productName, "Disponible:", available, "Solicitado:", requested)
            }

            onSaleCompleted: function(invoiceNumber, total, voucherType, items, subtotal, discount, customerName, amountPaid, changeGiven) {
                // Guardar todos los datos recibidos del ViewModel
                successDialog.invoiceNumber = invoiceNumber
                successDialog.total = total
                successDialog.voucherType = voucherType
                successDialog.items = items
                successDialog.subtotal = subtotal
                successDialog.discount = discount
                successDialog.amountPaid = amountPaid
                successDialog.changeGiven = changeGiven
                
                // Usar el customerName recibido directamente del ViewModel
                successDialog.customerName = customerName
                successDialog.ruc = root.currentRuc
                successDialog.businessName = root.currentBusinessName
                successDialog.address = root.currentAddress

                // Recargar productos para actualizar stock en la vista
                productsModel.loadProducts()

                // Mostrar diálogo
                successDialog.open()

                // Limpiar campos de UI
                searchField.text = ""
                quantitySpinBox.value = 1
                discountSpinBox.value = 0
                customerSelector.clearSelection()  // Limpiar selección de cliente
                boletaRadio.checked = true  // Volver a boleta por defecto
                
                // Limpiar datos temporales
                root.currentCustomerId = 0
                root.currentCustomerName = "Cliente General"
                root.currentCustomerDocument = ""
                root.currentRuc = ""
                root.currentBusinessName = ""
                root.currentAddress = ""
                root.lastScannedBarcode = ""  // Resetear último código escaneado
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

        // ViewModel de impresión
        PrintViewModel {
            id: printViewModel

            onPdfGenerated: function(filePath) {
                console.log("PDF generado en:", filePath)
            }

            onPrintCompleted: function() {
                console.log("Impresión completada")
            }

            onPrintFailed: function(error) {
                console.error("Error de impresión:", error)
                errorDialog.errorMessage = "Error al imprimir: " + error
                errorDialog.open()
            }
        }

        // Handler para escáner de código de barras láser
        BarcodeScannerHandler {
            id: barcodeScanner
            enabled: true
            timeout: 100  // 100ms entre caracteres del escáner
            
            onBarcodeScanned: function(barcode) {
                console.log("Código de barras escaneado:", barcode)
                
                // PASO 1: Verificar si el producto existe en la base de datos
                var productData = viewModel.findProductByCode(barcode)
                
                if (!productData || !productData.exists) {
                    // Producto NO existe - Mostrar error sin abrir diálogo
                    console.log("Producto no encontrado:", barcode)
                    errorDialog.errorMessage = qsTr("Producto no encontrado: ") + barcode
                    errorDialog.open()
                    root.lastScannedBarcode = ""  // Resetear
                    return
                }
                
                console.log("Producto encontrado:", productData.name, "- Stock:", productData.currentStock)
                
                // PASO 2: Verificar si es el mismo código escaneado consecutivamente
                if (barcode === root.lastScannedBarcode && root.lastScannedBarcode !== "") {
                    // Es el mismo código - Incrementar cantidad automáticamente
                    console.log("Código duplicado detectado - Incrementando cantidad automáticamente")
                    
                    // Agregar 1 unidad más al carrito
                    viewModel.searchAndAddProduct(barcode, 1)
                    
                    // Feedback visual rápido
                    duplicateNotification.productName = productData.name
                    duplicateNotification.open()
                    
                } else {
                    // Es un código nuevo - Abrir diálogo para elegir cantidad
                    console.log("Código nuevo - Abriendo diálogo de cantidad")
                    quantityDialog.scannedBarcode = barcode
                    quantityDialog.productName = productData.name
                    quantityDialog.currentStock = productData.currentStock
                    quantityDialog.open()
                }
                
                // PASO 3: Guardar código como último escaneado
                root.lastScannedBarcode = barcode
            }
        }

        // Los totales se actualizan automáticamente mediante bindings de propiedades
        // No se necesitan conexiones manuales

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
                                viewModel.searchAndAddProduct(text.trim(), quantitySpinBox.value)
                                text = ""
                                quantitySpinBox.value = 1
                            }
                        }

                        onTextChanged: {
                            if (text.length > 0) {
                                searchTimer.restart()
                                // Si es un número, también iniciar el timer de auto-add
                                var trimmedText = text.trim()
                                if (/^\d+$/.test(trimmedText) && trimmedText.length >= 3) {
                                    autoAddTimer.restart()
                                } else {
                                    autoAddTimer.stop()
                                }
                            } else {
                                autoAddTimer.stop()
                            }
                        }

                        Timer {
                            id: searchTimer
                            interval: 300
                            repeat: false
                            onTriggered: {
                                if (searchField.text.trim() !== "") {
                                    productsModel.searchProducts(searchField.text.trim())
                                }
                            }
                        }
                        
                        // Timer para añadir automáticamente cuando se detecta un código numérico
                        Timer {
                            id: autoAddTimer
                            interval: 800  // Esperar 800ms después de que termine de escribir
                            repeat: false
                            onTriggered: {
                                var code = searchField.text.trim()
                                // Solo auto-añadir si es un número de 3+ dígitos
                                if (/^\d+$/.test(code) && code.length >= 3) {
                                    viewModel.searchAndAddProduct(code, quantitySpinBox.value)
                                    searchField.text = ""
                                    quantitySpinBox.value = 1
                                }
                            }
                        }
                    }

                    Button {
                        text: "\uE8FE"  // QR/Barcode icon
                        font.family: "Segoe MDL2 Assets"
                        font.pixelSize: 20
                        flat: true
                        Material.foreground: Material.primary
                        ToolTip.visible: hovered
                        ToolTip.text: qsTr("Escanear código de barras")

                        background: Rectangle {
                            implicitWidth: 40
                            implicitHeight: 40
                            radius: 4
                            color: parent.down ?
                                (Material.theme === Material.Dark ?
                                    Qt.lighter(Material.background, 1.4) :
                                    Material.color(Material.Grey, Material.Shade300)) :
                                parent.hovered ?
                                (Material.theme === Material.Dark ?
                                    Qt.lighter(Material.background, 1.2) :
                                    Material.color(Material.Grey, Material.Shade200)) :
                                (Material.theme === Material.Dark ?
                                    Qt.transparent :
                                    Material.background)
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
                        Material.background: ApplicationWindow.window?.currentColors?.primary ?? Material.primary
                        Material.foreground: Material.theme === Material.Dark ? "#000000" : "#FFFFFF"
                        implicitHeight: 40
                        implicitWidth: 40

                        onClicked: {
                            if (searchField.text.trim() !== "") {
                                viewModel.searchAndAddProduct(searchField.text.trim(), quantitySpinBox.value)
                                searchField.text = ""
                                quantitySpinBox.value = 1
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
                        text: qsTr("(Ingresa código numérico para añadir automáticamente)")
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
                            font.pixelSize: 17
                            font.weight: Font.Medium
                        }

                        ListView {
                            id: productsListView
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            spacing: 4

                            model: productsModel

                            delegate: Item {
                                width: ListView.view.width
                                height: 76

                                Rectangle {
                                    anchors.fill: parent
                                    color: delegateMouseArea.containsMouse ?
                                        (Material.theme === Material.Dark ?
                                            Qt.lighter(Material.background, 1.2) :
                                            Material.color(Material.Grey, Material.Shade200)) :
                                        Material.background
                                    radius: 6

                                    Behavior on color { ColorAnimation { duration: 150 } }

                                    MouseArea {
                                        id: delegateMouseArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        
                                        onClicked: {
                                            viewModel.addProductById(model.productId, quantitySpinBox.value)
                                            quantitySpinBox.value = 1
                                        }
                                    }

                                    // Layout tipo tabla con anchos fijos
                                    Item {
                                        anchors.fill: parent
                                        anchors.leftMargin: 12
                                        anchors.rightMargin: 12
                                        anchors.topMargin: 10
                                        anchors.bottomMargin: 10

                                        // Columna 1: Nombre y detalles (ocupa espacio restante)
                                        ColumnLayout {
                                            anchors.left: parent.left
                                            anchors.right: priceLabel.left
                                            anchors.rightMargin: 12
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 4

                                            Label {
                                                text: model.name
                                                font.pixelSize: 17
                                                font.weight: Font.Medium
                                                color: Material.foreground
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }

                                            Label {
                                                text: "SKU: " + model.sku + " | Stock: " + model.currentStock
                                                font.pixelSize: 13
                                                opacity: 0.7
                                                color: Material.foreground
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }
                                        }

                                        // Columna 2: Precio (ancho fijo 90px, alineado derecha)
                                        Label {
                                            id: priceLabel
                                            anchors.right: addButton.left
                                            anchors.rightMargin: 12
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "S/" + model.salePrice.toFixed(2)
                                            font.pixelSize: 18
                                            font.weight: Font.Bold
                                            color: Material.primary
                                            width: 100
                                            horizontalAlignment: Text.AlignRight
                                        }

                                        // Columna 3: Botón (ancho fijo 36px)
                                        RoundButton {
                                            id: addButton
                                            anchors.right: parent.right
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "\uE710"  // Add icon (+)
                                            font.family: "Segoe MDL2 Assets"
                                            font.pixelSize: 22
                                            flat: true
                                            width: 44
                                            height: 44
                                            Material.foreground: Material.primary

                                            background: Rectangle {
                                                radius: 18
                                                color: parent.down ?
                                                    (Material.theme === Material.Dark ?
                                                        Qt.lighter(Material.background, 1.4) :
                                                        Material.color(Material.Grey, Material.Shade300)) :
                                                    parent.hovered ?
                                                    (Material.theme === Material.Dark ?
                                                        Qt.lighter(Material.background, 1.2) :
                                                        Material.color(Material.Grey, Material.Shade200)) :
                                                    (Material.theme === Material.Dark ?
                                                        Qt.transparent :
                                                        Material.background)
                                                border.width: 1
                                                border.color: parent.hovered ? Material.primary : Material.frameColor

                                                Behavior on color { ColorAnimation { duration: 150 } }
                                                Behavior on border.color { ColorAnimation { duration: 150 } }
                                            }

                                            onClicked: {
                                                viewModel.addProductById(model.productId, quantitySpinBox.value)
                                                quantitySpinBox.value = 1
                                            }
                                        }
                                    }
                                }
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
            Flickable {
                Layout.fillHeight: true
                Layout.preferredWidth: parent.width * 0.4
                Layout.minimumWidth: 400
                clip: true
                
                contentWidth: width
                contentHeight: columnContent.implicitHeight
                
                ScrollBar.vertical: ScrollBar {}

                ColumnLayout {
                    id: columnContent
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
                            text: viewModel.cart.count + " items"
                            font.pixelSize: 12
                            opacity: 0.7
                        }
                    }

                    // Items del carrito con scroll interno
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 400
                        Layout.minimumHeight: 200
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
                                        color: Material.primary

                                        Label {
                                            anchors.centerIn: parent
                                            text: "\uE7BF"  // Shopping bag icon
                                            font.family: "Segoe MDL2 Assets"
                                            font.pixelSize: 26
                                            color: Material.theme === Material.Dark ? "#000000" : "#FFFFFF"
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
                                            Layout.preferredWidth: itemSubtotalLabel.width + 18
                                            radius: 5
                                            color: Material.theme === Material.Dark ?
                                                Qt.rgba(Material.primary.r, Material.primary.g, Material.primary.b, 0.2) :
                                                Qt.rgba(Material.primary.r, Material.primary.g, Material.primary.b, 0.15)

                                            Label {
                                                id: itemSubtotalLabel
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
                                                viewModel.cart.updateQuantityByProductId(model.productId, value)
                                            }
                                        }

                                        Button {
                                            text: "\uE74D"  // Delete icon
                                            font.family: "Segoe MDL2 Assets"
                                            font.pixelSize: 18
                                            flat: true
                                            Layout.preferredWidth: 44
                                            Layout.preferredHeight: 44

                                            Material.foreground: Material.theme === Material.Dark ? "#FFFFFF" : "#FFFFFF"

                                            background: Rectangle {
                                                radius: 8
                                                color: Material.theme === Material.Light ?
                                                       (parent.down ? Material.color(Material.Red, Material.Shade700) :
                                                        parent.hovered ? Material.color(Material.Red, Material.Shade600) :
                                                        Material.color(Material.Red, Material.Shade500)) :
                                                       (parent.down ? Material.color(Material.Red, Material.Shade900) :
                                                        parent.hovered ? Material.color(Material.Red, Material.Shade800) :
                                                        Material.color(Material.Red, Material.Shade700))
                                                border.width: 0

                                                Behavior on color { ColorAnimation { duration: 150 } }
                                            }

                                            onClicked: {
                                                viewModel.cart.removeItemByProductId(model.productId)
                                            }
                                        }
                                    }
                                }  // Fin RowLayout itemContent
                            }  // Fin Rectangle cardRect
                        }  // Fin Item delegate

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
                                text: "S/" + viewModel.cart.subtotal.toFixed(2)
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
                                value: viewModel.discount * 100  // Convertir a centavos para el SpinBox
                                editable: true
                                stepSize: 100
                                Layout.preferredWidth: 120

                                textFromValue: function(value) {
                                    return "S/" + (value / 100).toFixed(2)
                                }

                                valueFromText: function(text) {
                                    return parseFloat(text.replace("S/", "")) * 100
                                }

                                onValueModified: {
                                    viewModel.discount = value / 100
                                }
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
                                text: "S/" + viewModel.totalWithDiscount.toFixed(2)
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
                        spacing: 12

                        CustomerSelector {
                            id: customerSelector
                            Layout.fillWidth: true
                            
                            onCustomerSelected: function(customerId, customerName, documentNumber, address) {
                                root.currentCustomerId = customerId
                                root.currentCustomerName = customerName
                                root.currentCustomerDocument = documentNumber
                                
                                console.log("Cliente seleccionado:", customerId, customerName, "Doc:", documentNumber, "Dir:", address)
                                
                                // Si tiene RUC (11 dígitos), autocompletar datos de factura
                                if (documentNumber && documentNumber.length === 11) {
                                    facturaRadio.checked = true
                                    rucField.text = documentNumber
                                    businessNameField.text = customerName
                                    if (address && address.length > 0) {
                                        addressField.text = address
                                    }
                                }
                            }
                            
                            onCustomerCleared: {
                                root.currentCustomerId = 0
                                root.currentCustomerName = "Cliente General"
                                root.currentCustomerDocument = ""
                            }
                        }
                        
                        // Botón para limpiar selección
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            
                            Button {
                                text: qsTr("Limpiar")
                                flat: true
                                icon.source: "qrc:/icons/clear.png"
                                
                                onClicked: {
                                    customerSelector.clearSelection()
                                }
                                
                                ToolTip.visible: hovered
                                ToolTip.text: qsTr("Limpiar selección de cliente")
                            }
                            
                            Button {
                                text: qsTr("Historial PDF")
                                flat: true
                                icon.source: "qrc:/icons/pdf.png"
                                Material.foreground: Material.color(Material.Red)
                                enabled: root.currentCustomerId > 0
                                
                                onClicked: {
                                    // Generar nombre de archivo
                                    var timestamp = new Date().getTime()
                                    var fileName = "historial_cliente_" + root.currentCustomerId + "_" + timestamp + ".pdf"
                                    var outputPath = "C:/Users/Public/Documents/" + fileName
                                    
                                    // Intentar generar el PDF
                                    var success = customerSelector.model.generatePurchaseHistoryPdf(root.currentCustomerId, outputPath)
                                    
                                    if (success) {
                                        // Abrir el PDF automáticamente con la aplicación predeterminada
                                        Qt.openUrlExternally("file:///" + outputPath.replace(/\\/g, "/"))
                                        notificationBar.show("PDF generado y abierto: " + fileName, "success")
                                    } else {
                                        notificationBar.show("Error al generar el PDF del historial", "error")
                                    }
                                }
                                
                                ToolTip.visible: hovered
                                ToolTip.text: qsTr("Generar y abrir PDF del historial de compras")
                            }
                            
                            Button {
                                text: qsTr("Nuevo Cliente")
                                flat: true
                                icon.source: "qrc:/icons/add.png"
                                Material.foreground: Material.accent
                                
                                onClicked: {
                                    console.log("🔵 Botón 'Nuevo Cliente' clickeado")
                                    clickConfirmPopup.open()
                                    Qt.callLater(function() {
                                        quickCustomerDialog.open()
                                    })
                                }
                                
                                ToolTip.visible: hovered
                                ToolTip.text: qsTr("Crear nuevo cliente")
                            }
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
                                
                                onTextChanged: {
                                    // Guardar automáticamente cuando cambia
                                    salesSettings.savedRuc = text
                                }
                            }

                            TextField {
                                id: businessNameField
                                Layout.fillWidth: true
                                placeholderText: qsTr("Razón Social")
                                
                                onTextChanged: {
                                    // Guardar automáticamente cuando cambia
                                    salesSettings.savedBusinessName = text
                                }
                            }

                            TextField {
                                id: addressField
                                Layout.fillWidth: true
                                placeholderText: qsTr("Dirección")
                                
                                onTextChanged: {
                                    // Guardar automáticamente cuando cambia
                                    salesSettings.savedAddress = text
                                }
                            }
                        }
                    }
                }

                // Tipo de pago
                GroupBox {
                    Layout.fillWidth: true
                    title: qsTr("Tipo de Pago")

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 12

                        // Tipo: Contado o Crédito
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            
                            Label {
                                text: qsTr("Tipo:")
                                font.pixelSize: 13
                                font.weight: Font.Medium
                            }
                            
                            ComboBox {
                                id: paymentTypeComboBox
                                Layout.fillWidth: true
                                model: ["Al Contado", "Al Crédito"]
                                currentIndex: 0  // Por defecto: Al Contado
                                
                                onCurrentIndexChanged: {
                                    // Si es crédito y no hay cliente seleccionado, mostrar advertencia
                                    if (currentIndex === 1 && root.currentCustomerId === 0) {
                                        console.warn("⚠️ TIPO CRÉDITO: Se requiere seleccionar un cliente")
                                    }
                                }
                            }
                            
                            // Advertencia cuando es crédito sin cliente
                            Label {
                                Layout.fillWidth: true
                                text: "⚠️ Las ventas al crédito requieren un cliente seleccionado"
                                visible: paymentTypeComboBox.currentIndex === 1 && root.currentCustomerId === 0
                                color: Material.color(Material.Orange)
                                font.pixelSize: 12
                                wrapMode: Text.Wrap
                            }
                        }
                        
                        // Método: Efectivo, Tarjeta, etc.
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            
                            Label {
                                text: qsTr("Método:")
                                font.pixelSize: 13
                                font.weight: Font.Medium
                            }
                            
                            ComboBox {
                                id: paymentMethodComboBox
                                Layout.fillWidth: true
                                model: ["Efectivo", "Tarjeta", "Transferencia", "Yape", "Plin"]
                            }
                        }
                    }
                }

                // Botones de acción
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Button {
                        text: "\uE711  " + qsTr("Cancelar")  // X icon + text
                        font.family: "Segoe MDL2 Assets"
                        Layout.preferredWidth: 120
                        flat: true

                        background: Rectangle {
                            implicitWidth: 120
                            implicitHeight: 40
                            radius: 4
                            color: parent.down ? 
                                (Material.theme === Material.Dark ?
                                    Qt.lighter(Material.background, 1.4) :
                                    Material.color(Material.Grey, Material.Shade300)) :
                                parent.hovered ? 
                                (Material.theme === Material.Dark ?
                                    Qt.lighter(Material.background, 1.2) :
                                    Material.color(Material.Grey, Material.Shade200)) :
                                (Material.theme === Material.Dark ?
                                    Qt.transparent :
                                    Material.background)
                            border.width: 1
                            border.color: Material.frameColor

                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        onClicked: {
                            viewModel.cancelSale()
                            viewModel.discount = 0
                            searchField.text = ""
                            quantitySpinBox.value = 1
                            root.lastScannedBarcode = ""  // Resetear último código escaneado
                            customerSelector.clearSelection()  // Limpiar selección de cliente
                            boletaRadio.checked = true  // Volver a boleta por defecto
                        }
                    }

                    Button {
                        id: processSaleButton
                        text: qsTr("Procesar Venta")
                        Layout.fillWidth: true
                        enabled: viewModel.canProcessSale &&
                                (!facturaRadio.checked ||
                                (rucField.acceptableInput &&
                                businessNameField.text.trim() !== "" &&
                                addressField.text.trim() !== "")) &&
                                (paymentTypeComboBox.currentIndex === 0 || root.currentCustomerId !== 0)  // Validar cliente para crédito
                        Material.background: ApplicationWindow.window?.currentColors?.primary ?? Material.primary
                        Material.foreground: Material.theme === Material.Dark ? "#000000" : "#FFFFFF"

                        onClicked: {
                            console.log("=== PROCESAR VENTA CLICKED ===")
                            console.log("  Items en carrito:", viewModel.cart.count)
                            console.log("  Subtotal:", viewModel.cart.subtotal)
                            console.log("  Descuento:", viewModel.discount)
                            console.log("  Total:", viewModel.totalWithDiscount)
                            console.log("  Cliente ID:", root.currentCustomerId)
                            console.log("  Cliente:", root.currentCustomerName)
                            console.log("  Tipo de pago:", paymentTypeComboBox.currentText)
                            console.log("  Método de pago:", paymentMethodComboBox.currentText)
                            
                            // Validación adicional para crédito
                            if (paymentTypeComboBox.currentIndex === 1 && root.currentCustomerId === 0) {
                                errorDialog.errorMessage = "Las ventas al crédito requieren un cliente seleccionado.\n\nPor favor, seleccione un cliente antes de procesar la venta."
                                errorDialog.open()
                                return
                            }
                            
                            // Si es venta al CRÉDITO con cliente seleccionado, procesar directamente
                            if (paymentTypeComboBox.currentIndex === 1 && root.currentCustomerId !== 0) {
                                // Para crédito, el monto pagado es 0 (deuda completa)
                                viewModel.amountPaid = 0
                                processSaleAfterPayment()
                            }
                            // Si es CONTADO y pago en EFECTIVO, mostrar diálogo de ingreso de monto
                            else if (paymentTypeComboBox.currentIndex === 0 && paymentMethodComboBox.currentIndex === 0) {
                                paymentAmountDialog.totalAmount = viewModel.totalWithDiscount
                                paymentAmountDialog.open()
                            } else {
                                // Para otros métodos de pago al contado, asumir pago exacto
                                viewModel.amountPaid = viewModel.totalWithDiscount
                                // changeGiven se calcula automáticamente en el setter (será 0)
                                processSaleAfterPayment()
                            }
                        }
                    }

                }
            }  // Fin ColumnLayout
        }  // Fin Flickable columna derecha
    }  // Fin RowLayout principal

    // ===== DIÁLOGOS =====

    // Diálogo de confirmación de venta
    SaleSuccessDialog {
        id: successDialog
        parentPage: root

        onPrintRequested: {
            // Preparar datos para impresión
            var voucherType = successDialog.voucherType === "FACTURA"
                            ? PrintViewModel.Factura
                            : PrintViewModel.Boleta

            // Abrir diálogo de impresión con datos guardados
            printDialog.invoiceNumber = successDialog.invoiceNumber
            printDialog.customerName = successDialog.customerName
            printDialog.items = successDialog.items
            printDialog.subtotal = successDialog.subtotal
            printDialog.discount = successDialog.discount
            printDialog.total = successDialog.total
            printDialog.amountPaid = successDialog.amountPaid
            printDialog.changeGiven = successDialog.changeGiven
            printDialog.voucherType = voucherType
            printDialog.ruc = successDialog.ruc
            printDialog.businessName = successDialog.businessName
            printDialog.address = successDialog.address

            printDialog.open()
        }
    }

    // Diálogo de error
    SaleErrorDialog {
        id: errorDialog
        parentPage: root
    }
    
    // Diálogo de creación rápida de cliente
    Dialog {
        id: quickCustomerDialog
        title: qsTr("Nuevo Cliente")
        modal: true
        anchors.centerIn: parent
        width: Math.min(500, parent ? parent.width * 0.9 : 500)
        
        // ViewModel para crear cliente
        CustomerFormViewModel {
            id: customerViewModel
            
            onSaved: {
                console.log("✅ Cliente guardado en BD:", customerId, name)
                
                // Timer para refrescar después de un pequeño delay
                refreshTimer.savedCustomerId = customerId
                refreshTimer.savedCustomerName = name
                refreshTimer.restart()
            }
            
            onErrorOccurred: function(message) {
                console.error("❌ Error al guardar cliente:", message)
                notificationBar.show("Error: " + message, "error")
            }
        }
        
        // Timer para refrescar y seleccionar cliente después de guardarlo
        Timer {
            id: refreshTimer
            interval: 200 // Primera búsqueda rápida: 200ms
            repeat: false
            
            property int savedCustomerId: -1
            property string savedCustomerName: ""
            property int retryCount: 0
            property int maxRetries: 3
            
            onTriggered: {
                console.log("🔄 Refrescando lista de clientes (intento " + (retryCount + 1) + "/" + maxRetries + ")...")
                
                // Forzar refresco completo del modelo
                customerSelector.model.refresh()
                
                // Esperar a que se complete el refresco del modelo
                Qt.callLater(function() {
                    console.log("🔍 Buscando cliente recién creado (ID:" + savedCustomerId + ")...")
                    console.log("   Total clientes en lista:", customerSelector.model.count)
                    
                    var found = false
                    for (var i = 0; i < customerSelector.model.count; i++) {
                        var customer = customerSelector.model.get(i)
                        
                        if (customer.customerId === savedCustomerId) {
                            found = true
                            console.log("✅ Cliente encontrado en posición", i)
                            
                            // Actualizar las propiedades del selector
                            customerSelector.selectedCustomerId = savedCustomerId
                            customerSelector.selectedCustomerName = savedCustomerName
                            customerSelector.selectedDocumentNumber = customer.documentNumber || ""
                            customerSelector.selectedAddress = customer.address || ""
                            
                            // Actualizar las propiedades del root
                            root.currentCustomerId = savedCustomerId
                            root.currentCustomerName = savedCustomerName
                            root.currentCustomerDocument = customer.documentNumber || ""
                            
                            // Emitir señal de selección
                            customerSelector.customerSelected(
                                savedCustomerId,
                                savedCustomerName,
                                customer.documentNumber || "",
                                customer.address || ""
                            )
                            
                            notificationBar.show("Cliente '" + savedCustomerName + "' creado y seleccionado", "success")
                            console.log("✅ Cliente auto-seleccionado exitosamente")
                            
                            // Cerrar el diálogo
                            quickCustomerDialog.close()
                            
                            // Resetear contador de reintentos
                            retryCount = 0
                            break
                        }
                    }
                    
                    if (!found) {
                        retryCount++
                        if (retryCount < maxRetries) {
                            console.warn("⚠️ Cliente no encontrado, reintentando en " + interval + "ms...")
                            // Aumentar el intervalo para el siguiente intento
                            interval = interval + 200
                            restart()
                        } else {
                            console.error("❌ No se encontró el cliente después de " + maxRetries + " intentos")
                            notificationBar.show("Cliente creado. Actualice manualmente si no aparece.", "warning")
                            retryCount = 0
                            interval = 200 // Resetear intervalo
                            quickCustomerDialog.close()
                        }
                    }
                })
            }
        }
        
        onAboutToShow: {
            console.log("🔵 Abriendo diálogo de nuevo cliente")
            customerViewModel.clear()
            newCustomerNameField.text = ""
            newCustomerDocumentNumberField.text = ""
            newCustomerPhoneField.text = ""
            newCustomerEmailField.text = ""
            newCustomerAddressField.text = ""
            newCustomerDocumentTypeCombo.currentIndex = 0
            newCustomerNameField.forceActiveFocus()
        }
        
        function saveCustomer() {
            console.log("💾 Intentando guardar nuevo cliente")
            
            // Validar campos requeridos
            if (newCustomerNameField.text.trim() === "") {
                notificationBar.show("El nombre es obligatorio", "error")
                return false
            }
            
            if (newCustomerDocumentTypeCombo.currentIndex < 0) {
                notificationBar.show("Seleccione un tipo de documento", "error")
                return false
            }
            
            if (newCustomerDocumentNumberField.text.trim() === "") {
                notificationBar.show("El número de documento es obligatorio", "error")
                return false
            }
            
            // Validar formato según tipo de documento
            var docType = newCustomerDocumentTypeCombo.currentText
            var docNumber = newCustomerDocumentNumberField.text.trim()
            
            if (docType === "DNI" && docNumber.length !== 8) {
                notificationBar.show("El DNI debe tener 8 dígitos", "error")
                return false
            }
            
            if (docType === "RUC" && docNumber.length !== 11) {
                notificationBar.show("El RUC debe tener 11 dígitos", "error")
                return false
            }
            
            // Asignar valores al ViewModel
            customerViewModel.name = newCustomerNameField.text.trim()
            customerViewModel.documentType = newCustomerDocumentTypeCombo.currentText
            customerViewModel.documentNumber = newCustomerDocumentNumberField.text.trim()
            customerViewModel.phone = newCustomerPhoneField.text.trim()
            customerViewModel.email = newCustomerEmailField.text.trim()
            customerViewModel.address = newCustomerAddressField.text.trim()
            
            console.log("📝 Datos del cliente a guardar:")
            console.log("  - Nombre:", customerViewModel.name)
            console.log("  - Tipo Doc:", customerViewModel.documentType)
            console.log("  - Nro Doc:", customerViewModel.documentNumber)
            console.log("  - Teléfono:", customerViewModel.phone)
            console.log("  - Email:", customerViewModel.email)
            console.log("  - Dirección:", customerViewModel.address)
            
            // Guardar en la base de datos
            customerViewModel.save()
            return true
        }
        
        contentItem: Flickable {
            implicitHeight: contentColumn.implicitHeight
            contentHeight: contentColumn.implicitHeight
            clip: true
            
            ScrollBar.vertical: ScrollBar {}
            
            ColumnLayout {
                id: contentColumn
                width: parent.width
                spacing: 16
                
                // Nombre (requerido)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    
                    Label {
                        text: qsTr("Nombre *")
                        font.weight: Font.Medium
                        font.pixelSize: 13
                    }
                    
                    TextField {
                        id: newCustomerNameField
                        Layout.fillWidth: true
                        placeholderText: qsTr("Ingrese nombre completo")
                    }
                }
                
                // Tipo de documento (requerido)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    
                    Label {
                        text: qsTr("Tipo de Documento *")
                        font.weight: Font.Medium
                        font.pixelSize: 13
                    }
                    
                    ComboBox {
                        id: newCustomerDocumentTypeCombo
                        Layout.fillWidth: true
                        model: ["DNI", "RUC", "CE", "PASAPORTE"]
                        currentIndex: 0
                    }
                }
                
                // Número de documento (requerido)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    
                    Label {
                        text: qsTr("Número de Documento *")
                        font.weight: Font.Medium
                        font.pixelSize: 13
                    }
                    
                    TextField {
                        id: newCustomerDocumentNumberField
                        Layout.fillWidth: true
                        placeholderText: newCustomerDocumentTypeCombo.currentText === "DNI" ? "8 dígitos" : newCustomerDocumentTypeCombo.currentText === "RUC" ? "11 dígitos" : "Número de documento"
                        validator: RegularExpressionValidator {
                            regularExpression: /^\d{0,20}$/
                        }
                        maximumLength: newCustomerDocumentTypeCombo.currentText === "DNI" ? 8 : newCustomerDocumentTypeCombo.currentText === "RUC" ? 11 : 20
                    }
                }
                
                // Teléfono (opcional)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    
                    Label {
                        text: qsTr("Teléfono")
                        font.pixelSize: 13
                    }
                    
                    TextField {
                        id: newCustomerPhoneField
                        Layout.fillWidth: true
                        placeholderText: qsTr("9 dígitos")
                        validator: RegularExpressionValidator {
                            regularExpression: /^\d{0,9}$/
                        }
                        maximumLength: 9
                    }
                }
                
                // Email (opcional)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    
                    Label {
                        text: qsTr("Email")
                        font.pixelSize: 13
                    }
                    
                    TextField {
                        id: newCustomerEmailField
                        Layout.fillWidth: true
                        placeholderText: qsTr("ejemplo@correo.com")
                        inputMethodHints: Qt.ImhEmailCharactersOnly
                    }
                }
                
                // Dirección (opcional)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    
                    Label {
                        text: qsTr("Dirección")
                        font.pixelSize: 13
                    }
                    
                    TextField {
                        id: newCustomerAddressField
                        Layout.fillWidth: true
                        placeholderText: qsTr("Dirección completa")
                    }
                }
                
                Label {
                    text: qsTr("* Campos obligatorios")
                    font.pixelSize: 11
                    opacity: 0.6
                    Layout.fillWidth: true
                }
            }
        }
        
        footer: DialogButtonBox {
            Button {
                text: qsTr("Cancelar")
                flat: true
                DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
                
                onClicked: {
                    console.log("❌ Cancelar creación de cliente")
                    quickCustomerDialog.close()
                }
            }
            
            Button {
                text: qsTr("Guardar")
                highlighted: true
                DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
                Material.background: Material.primary
                Material.foreground: Material.theme === Material.Dark ? "#000000" : "#FFFFFF"
                
                onClicked: {
                    console.log("💾 Botón Guardar clickeado")
                    quickCustomerDialog.saveCustomer()
                }
            }
        }
    }
    
    // Notificación rápida para código duplicado (incremento automático)
    Popup {
        id: duplicateNotification
        anchors.centerIn: parent
        width: 320
        height: 100
        modal: false
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        
        property string productName: ""
        
        background: Rectangle {
            color: Material.theme === Material.Dark ?
                Qt.rgba(0.2, 0.8, 0.4, 0.95) :
                Material.color(Material.Green, Material.Shade100)
            radius: 8
            border.width: 2
            border.color: Material.color(Material.Green)
        }

        RowLayout {
            anchors.centerIn: parent
            spacing: 16

            Label {
                text: "\uE8FB"  // Icono de añadir
                font.family: "Segoe MDL2 Assets"
                font.pixelSize: 36
                color: Material.color(Material.Green)
            }
            
            ColumnLayout {
                spacing: 4
                
                Label {
                    text: qsTr("✓ Cantidad aumentada")
                    font.weight: Font.Bold
                    font.pixelSize: 16
                }
                
                Label {
                    text: duplicateNotification.productName
                    font.pixelSize: 12
                    opacity: 0.9
                    Layout.maximumWidth: 220
                    elide: Text.ElideRight
                }
            }
        }

        Timer {
            interval: 1500
            running: duplicateNotification.visible
            onTriggered: duplicateNotification.close()
        }
    }
    
    // Popup de confirmación de clic en "Nuevo Cliente"
    Popup {
        id: clickConfirmPopup
        anchors.centerIn: parent
        width: 300
        height: 90
        modal: false
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        
        background: Rectangle {
            color: Material.dialogColor
            radius: 8
            border.width: 2
            border.color: Material.primary
        }

        RowLayout {
            anchors.centerIn: parent
            spacing: 16

            Label {
                text: "\uE73E"  // Checkmark icon
                font.family: "Segoe MDL2 Assets"
                font.pixelSize: 32
                color: Material.primary
            }
            
            Label {
                text: qsTr("Abriendo formulario de nuevo cliente...")
                font.pixelSize: 14
                font.weight: Font.Medium
                Layout.maximumWidth: 220
                wrapMode: Text.WordWrap
            }
        }

        Timer {
            interval: 1500
            running: clickConfirmPopup.visible
            onTriggered: clickConfirmPopup.close()
        }
    }

    // Diálogo de vista previa de impresión
    PrintDialog {
        id: printDialog
        printViewModel: root.printViewModel
        parentPage: root
    }
    
    // Diálogo de selección de cantidad con numpad
    Dialog {
        id: quantityDialog
        title: qsTr("Cantidad")
        modal: true
        anchors.centerIn: parent
        width: 320
        height: 500
        
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
                        text: qsTr("Stock disponible: ") + quantityDialog.currentStock
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
    
    // Diálogo de ingreso de monto pagado (solo para efectivo)
    PaymentAmountDialog {
        id: paymentAmountDialog
        
        onPaymentConfirmed: function(amountPaid, changeGiven) {
            // Guardar valores en el viewModel
            viewModel.amountPaid = amountPaid
            // changeGiven ya se calcula automáticamente en el setter
            
            // Procesar la venta después de confirmar el pago
            processSaleAfterPayment()
        }
    }
}
