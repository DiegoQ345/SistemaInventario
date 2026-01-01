import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import SistemaInventario 1.0

Page {
    id: root
    title: qsTr("Ventas")
    
    // Exponer ViewModels para que Main.qml pueda conectarse a sus señales
    property alias viewModel: viewModel
    property alias printViewModel: printViewModel
    
    // Datos temporales del cliente para la venta actual
    property string currentCustomerName: ""
    property string currentRuc: ""
    property string currentBusinessName: ""
    property string currentAddress: ""

    Component.onCompleted: {
        // Los totales se calculan automáticamente desde el ViewModel
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

            onSaleCompleted: function(invoiceNumber, total, voucherType, items, subtotal, discount) {
                // Guardar todos los datos recibidos del ViewModel
                successDialog.invoiceNumber = invoiceNumber
                successDialog.total = total
                successDialog.voucherType = voucherType
                successDialog.items = items
                successDialog.subtotal = subtotal
                successDialog.discount = discount
                
                // Asignar datos del cliente guardados temporalmente
                successDialog.customerName = root.currentCustomerName
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
                
                // Limpiar datos temporales
                root.currentCustomerName = ""
                root.currentRuc = ""
                root.currentBusinessName = ""
                root.currentAddress = ""
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
                        Material.background: Material.primary
                        Material.foreground: Material.theme === Material.Dark ? "white" : "white"
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

                            delegate: Item {
                                width: ListView.view.width
                                height: 60

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

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 8
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
                                            text: "\uE710"  // Add icon (+)
                                            font.family: "Segoe MDL2 Assets"
                                            font.pixelSize: 20
                                            flat: true
                                            implicitWidth: 40
                                            implicitHeight: 40
                                            Material.foreground: Material.primary

                                            background: Rectangle {
                                                radius: 20
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
                                            Layout.preferredWidth: itemSubtotalLabel.width + 18
                                            radius: 5
                                            color: Material.theme === Material.Dark ?
                                                Qt.darker(Material.primary, 1.8) :
                                                Material.color(Material.primary, Material.Shade50)

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

                                            Material.foreground: Material.color(Material.Red)

                                            background: Rectangle {
                                                radius: 6
                                                color: parent.down ? Material.color(Material.Red, Material.Shade200) :
                                                    parent.hovered ? Material.color(Material.Red, Material.Shade100) : Qt.transparent
                                                border.width: parent.hovered ? 1 : 0
                                                border.color: Material.color(Material.Red)

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
                                addressField.text.trim() !== ""))
                        Material.background: Material.primary
                        Material.foreground: "white"

                        onClicked: {
                            console.log("=== PROCESAR VENTA CLICKED ===")
                            console.log("  Items en carrito:", viewModel.cart.count)
                            console.log("  Subtotal:", viewModel.cart.subtotal)
                            console.log("  Descuento:", viewModel.discount)
                            console.log("  Total:", viewModel.totalWithDiscount)
                            
                            // Guardar datos de factura temporalmente para usar después de onSaleCompleted
                            root.currentCustomerName = customerComboBox.currentText || "Cliente General"
                            root.currentRuc = facturaRadio.checked ? rucField.text : ""
                            root.currentBusinessName = facturaRadio.checked ? businessNameField.text : ""
                            root.currentAddress = facturaRadio.checked ? addressField.text : ""
                            
                            console.log("  Cliente:", root.currentCustomerName)
                            console.log("  Método de pago:", paymentMethodComboBox.currentText)
                            console.log("  Es factura:", facturaRadio.checked)

                            // Llamar al ViewModel con todos los datos
                            var result = viewModel.processSaleWithInvoiceData(
                                0,  // customerId - 0 = cliente genérico
                                root.currentCustomerName,
                                paymentMethodComboBox.currentIndex + 1,  // paymentMethodId (1, 2, 3)
                                paymentMethodComboBox.currentText,
                                facturaRadio.checked,  // isInvoice
                                root.currentRuc,
                                root.currentBusinessName,
                                root.currentAddress
                            )
                            
                            console.log("  Resultado processSaleWithInvoiceData:", result)
                        }
                    }

                    RoundButton {
                        text: "\uE713"  // Settings icon
                        font.family: "Segoe MDL2 Assets"
                        font.pixelSize: 18
                        Layout.preferredWidth: 48
                        Layout.preferredHeight: 48
                        ToolTip.visible: hovered
                        ToolTip.text: qsTr("Configurar impresora")

                        Material.background: Material.theme === Material.Dark ?
                            Qt.lighter(Material.background, 1.3) :
                            Material.color(Material.Grey, Material.Shade200)
                        Material.foreground: Material.foreground

                        onClicked: printerSettingsDialog.open()
                    }
                }
            }  // Fin ColumnLayout
        }  // Fin Flickable columna derecha
    }  // Fin RowLayout principal

    // ===== DIÁLOGOS =====

    // Diálogo de confirmación de venta
    SaleSuccessDialog {
        id: successDialog

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
    }

    // Diálogo de vista previa de impresión
    PrintDialog {
        id: printDialog
        printViewModel: root.printViewModel
    }

    // Diálogo de configuración de impresora
    PrinterSettingsDialog {
        id: printerSettingsDialog
        printViewModel: root.printViewModel
    }
}
