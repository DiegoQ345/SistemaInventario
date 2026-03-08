import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import SistemaInventario 1.0

Page {
    id: root
    title: qsTr("Clientes")

    // ViewModels
    CustomerListModel {
        id: customerListModel
    }

    CustomerFormViewModel {
        id: customerFormViewModel

        onSaved: {
            customerListModel.refresh()
            customerDialog.close()
            globalNotification.show("Cliente guardado exitosamente", "success")
        }

        onErrorOccurred: function(message) {
            globalNotification.show(message, "error")
        }
    }

    // NotificationBar global (debe estar en Main.qml pero usamos una local)
    NotificationBar {
        id: globalNotification
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        // Encabezado
        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Label {
                    text: qsTr("Gestión de Clientes")
                    font.pixelSize: 32
                    font.weight: Font.Bold
                }

                Label {
                    text: qsTr("Total: %1 clientes").arg(customerListModel.count)
                    font.pixelSize: 16
                    opacity: 0.7
                }
            }

            Button {
                text: qsTr("➕ Nuevo Cliente")
                font.pixelSize: 16
                font.weight: Font.Medium
                Material.background: Material.primary
                Material.foreground: Material.theme === Material.Dark ? "#000000" : "#FFFFFF"
                leftPadding: 24
                rightPadding: 24
                topPadding: 12
                bottomPadding: 12

                onClicked: {
                    customerFormViewModel.clear()
                    customerDialog.open()
                }
            }
        }

        // Barra de búsqueda
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            TextField {
                id: searchField
                Layout.fillWidth: true
                placeholderText: qsTr("🔍 Buscar por nombre, documento, email o teléfono...")
                font.pixelSize: 14

                onTextChanged: {
                    searchTimer.restart()
                }

                Timer {
                    id: searchTimer
                    interval: 300
                    onTriggered: {
                        customerListModel.search(searchField.text)
                    }
                }
            }

            Button {
                text: qsTr("Limpiar")
                visible: searchField.text.length > 0
                onClicked: {
                    searchField.text = ""
                    customerListModel.refresh()
                }
            }
        }

        // Tabla de clientes
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Material.background
            border.color: Material.dividerColor
            border.width: 1
            radius: 8

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 1
                spacing: 0

                // Encabezado de tabla
                Rectangle {
                    Layout.fillWidth: true
                    height: 48
                    color: Material.dialogColor
                    radius: 8

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        spacing: 8

                        Label {
                            Layout.preferredWidth: 200
                            text: qsTr("Nombre")
                            font.weight: Font.Medium
                            font.pixelSize: 13
                        }

                        Label {
                            Layout.preferredWidth: 80
                            text: qsTr("Documento")
                            font.weight: Font.Medium
                            font.pixelSize: 13
                        }

                        Label {
                            Layout.preferredWidth: 100
                            text: qsTr("Nro. Doc.")
                            font.weight: Font.Medium
                            font.pixelSize: 13
                        }

                        Label {
                            Layout.fillWidth: true
                            text: qsTr("Email")
                            font.weight: Font.Medium
                            font.pixelSize: 13
                        }

                        Label {
                            Layout.preferredWidth: 100
                            text: qsTr("Teléfono")
                            font.weight: Font.Medium
                            font.pixelSize: 13
                        }
                        
                        Label {
                            Layout.preferredWidth: 85
                            text: qsTr("Límite Créd.")
                            font.weight: Font.Medium
                            font.pixelSize: 13
                        }

                        Label {
                            Layout.preferredWidth: 85
                            text: qsTr("Deuda")
                            font.weight: Font.Medium
                            font.pixelSize: 13
                            color: Material.color(Material.Red)
                        }

                        Label {
                            Layout.preferredWidth: 180
                            text: qsTr("Acciones")
                            font.weight: Font.Medium
                            font.pixelSize: 13
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }

                // Lista de clientes
                ListView {
                    id: customerListView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: customerListModel

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                    }

                    delegate: ItemDelegate {
                        width: customerListView.width
                        height: 64

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            spacing: 8

                            // Nombre
                            Label {
                                Layout.preferredWidth: 200
                                text: model.customerName
                                font.pixelSize: 14
                                elide: Text.ElideRight
                                font.weight: Font.Medium
                            }

                            // Tipo de documento
                            Label {
                                Layout.preferredWidth: 80
                                text: model.documentType || "-"
                                font.pixelSize: 13
                                opacity: 0.7
                            }

                            // Número de documento
                            Label {
                                Layout.preferredWidth: 100
                                text: model.documentNumber || "-"
                                font.pixelSize: 13
                                font.family: "monospace"
                            }

                            // Email
                            Label {
                                Layout.fillWidth: true
                                text: model.email || "-"
                                font.pixelSize: 13
                                opacity: 0.7
                                elide: Text.ElideRight
                            }

                            // Teléfono
                            Label {
                                Layout.preferredWidth: 100
                                text: model.phone || "-"
                                font.pixelSize: 13
                                font.family: "monospace"
                            }
                            
                            // Límite de crédito
                            Label {
                                Layout.preferredWidth: 85
                                text: model.creditLimit ? "S/ " + Number(model.creditLimit).toFixed(2) : "-"
                                font.pixelSize: 13
                                font.family: "monospace"
                                opacity: 0.8
                            }

                            // Deuda actual
                            Label {
                                Layout.preferredWidth: 85
                                text: model.currentDebt > 0 ? "S/ " + Number(model.currentDebt).toFixed(2) : "-"
                                font.pixelSize: 13
                                font.family: "monospace"
                                font.weight: model.currentDebt > 0 ? Font.Bold : Font.Normal
                                color: model.currentDebt > 0 ? Material.color(Material.Red) : Material.foreground
                            }

                            // Acciones
                            RowLayout {
                                Layout.preferredWidth: 180
                                spacing: 2

                                Button {
                                    text: "\uE8BC"
                                    font.family: "Segoe MDL2 Assets"
                                    font.pixelSize: 18
                                    flat: true
                                    Material.foreground: Material.color(Material.Blue)
                                    ToolTip.visible: hovered
                                    ToolTip.text: "Ver detalles de ventas"
                                    enabled: model.totalPurchases > 0
                                    Layout.preferredWidth: 40
                                    Layout.preferredHeight: 40

                                    onClicked: {
                                        customerDetailsDialog.customerId = model.customerId
                                        customerDetailsDialog.customerName = model.customerName
                                        customerDetailsDialog.loadSales()
                                        customerDetailsDialog.open()
                                    }
                                }

                                Button {
                                    text: "\uE8A5"
                                    font.family: "Segoe MDL2 Assets"
                                    font.pixelSize: 18
                                    flat: true
                                    Material.foreground: Material.color(Material.Blue)
                                    ToolTip.visible: hovered
                                    ToolTip.text: "Generar y abrir PDF de historial de compras"
                                    enabled: model.totalPurchases > 0
                                    Layout.preferredWidth: 40
                                    Layout.preferredHeight: 40

                                    onClicked: {
                                        // Generar nombre de archivo
                                        var timestamp = new Date().getTime()
                                        var customerName = model.customerName.replace(/\s+/g, '_').replace(/[^a-zA-Z0-9_]/g, '')
                                        var fileName = "historial_" + customerName + "_" + timestamp + ".pdf"
                                        var outputPath = "C:/Users/Public/Documents/" + fileName
                                        
                                        // Intentar generar el PDF
                                        var success = customerListModel.generatePurchaseHistoryPdf(model.customerId, outputPath)
                                        
                                        if (success) {
                                            // Abrir el PDF automáticamente con la aplicación predeterminada
                                            Qt.openUrlExternally("file:///" + outputPath.replace(/\\/g, "/"))
                                            globalNotification.show("PDF generado y abierto: " + fileName, "success")
                                        } else {
                                            globalNotification.show("Error: El cliente no tiene historial de compras", "error")
                                        }
                                    }
                                }

                                Button {
                                    text: "\uE70F"
                                    font.family: "Segoe MDL2 Assets"
                                    font.pixelSize: 18
                                    flat: true
                                    Material.foreground: Material.color(Material.Green)
                                    ToolTip.visible: hovered
                                    ToolTip.text: "Editar"
                                    Layout.preferredWidth: 40
                                    Layout.preferredHeight: 40

                                    onClicked: {
                                        customerFormViewModel.loadCustomer(model.customerId)
                                        customerDialog.open()
                                    }
                                }

                                Button {
                                    text: "\uE74D"
                                    font.family: "Segoe MDL2 Assets"
                                    font.pixelSize: 18
                                    flat: true
                                    Material.foreground: Material.color(Material.Red)
                                    ToolTip.visible: hovered
                                    ToolTip.text: "Eliminar"
                                    Layout.preferredWidth: 40
                                    Layout.preferredHeight: 40

                                    onClicked: {
                                        deleteDialog.customerId = model.customerId
                                        deleteDialog.customerName = model.customerName
                                        deleteDialog.open()
                                    }
                                }
                            }
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: 1
                            color: Material.dividerColor
                        }
                    }

                    // Estado vacío
                    Label {
                        anchors.centerIn: parent
                        visible: customerListModel.count === 0
                        text: searchField.text.length > 0 
                            ? qsTr("No se encontraron clientes con '%1'").arg(searchField.text)
                            : qsTr("No hay clientes registrados\nHaz clic en 'Nuevo Cliente' para agregar uno")
                        font.pixelSize: 16
                        opacity: 0.5
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }
    }

    // Diálogo de formulario de cliente
    Dialog {
        id: customerDialog
        title: customerFormViewModel.isEditMode ? qsTr("Editar Cliente") : qsTr("Nuevo Cliente")
        width: Math.min(600, root.width * 0.9)
        height: Math.min(550, root.height * 0.9)
        modal: true
        anchors.centerIn: parent
        standardButtons: Dialog.Save | Dialog.Cancel

        onAccepted: {
            if (customerFormViewModel.save()) {
                // El evento onSaved se encarga del cierre
            }
        }

        onRejected: {
            customerFormViewModel.clear()
        }

        ScrollView {
            anchors.fill: parent
            contentWidth: availableWidth

            ColumnLayout {
                width: parent.width
                spacing: 16

                // Nombre (obligatorio)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Label {
                        text: qsTr("Nombre *")
                        font.weight: Font.Medium
                    }

                    TextField {
                        Layout.fillWidth: true
                        placeholderText: qsTr("Nombre completo o razón social")
                        text: customerFormViewModel.name
                        onTextChanged: customerFormViewModel.name = text
                    }
                }

                // Tipo de documento
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Label {
                        text: qsTr("Tipo de Documento")
                        font.weight: Font.Medium
                    }

                    ComboBox {
                        Layout.fillWidth: true
                        model: ["DNI", "RUC", "CE", "Pasaporte", "Otro"]
                        currentIndex: {
                            var type = customerFormViewModel.documentType
                            var idx = model.indexOf(type)
                            return idx >= 0 ? idx : 0
                        }
                        onActivated: {
                            customerFormViewModel.documentType = currentText
                        }
                    }
                }

                // Número de documento
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Label {
                        text: qsTr("Número de Documento")
                        font.weight: Font.Medium
                    }

                    TextField {
                        Layout.fillWidth: true
                        placeholderText: qsTr("Ingrese número de documento")
                        text: customerFormViewModel.documentNumber
                        onTextChanged: customerFormViewModel.documentNumber = text
                        inputMethodHints: Qt.ImhDigitsOnly
                    }
                }

                // Email
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Label {
                        text: qsTr("Email")
                        font.weight: Font.Medium
                    }

                    TextField {
                        Layout.fillWidth: true
                        placeholderText: qsTr("correo@ejemplo.com")
                        text: customerFormViewModel.email
                        onTextChanged: customerFormViewModel.email = text
                        inputMethodHints: Qt.ImhEmailCharactersOnly
                    }
                }

                // Teléfono
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Label {
                        text: qsTr("Teléfono")
                        font.weight: Font.Medium
                    }

                    TextField {
                        Layout.fillWidth: true
                        placeholderText: qsTr("+51 999 999 999")
                        text: customerFormViewModel.phone
                        onTextChanged: customerFormViewModel.phone = text
                        inputMethodHints: Qt.ImhDialableCharactersOnly
                    }
                }

                // Dirección
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Label {
                        text: qsTr("Dirección")
                        font.weight: Font.Medium
                    }

                    TextArea {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 80
                        placeholderText: qsTr("Dirección completa")
                        text: customerFormViewModel.address
                        onTextChanged: customerFormViewModel.address = text
                        wrapMode: TextArea.Wrap
                    }
                }
                
                // Límite de crédito
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Label {
                        text: qsTr("Límite de Crédito")
                        font.weight: Font.Medium
                    }
                    
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        
                        Label {
                            text: "S/"
                            font.pixelSize: 14
                        }
                        
                        TextField {
                            Layout.fillWidth: true
                            placeholderText: qsTr("0.00")
                            text: customerFormViewModel.creditLimit > 0 ? customerFormViewModel.creditLimit.toFixed(2) : ""
                            onTextChanged: {
                                var value = parseFloat(text)
                                if (!isNaN(value) && value >= 0) {
                                    customerFormViewModel.creditLimit = value
                                } else if (text === "") {
                                    customerFormViewModel.creditLimit = 0
                                }
                            }
                            inputMethodHints: Qt.ImhFormattedNumbersOnly
                            validator: DoubleValidator {
                                bottom: 0
                                decimals: 2
                            }
                        }
                    }
                    
                    // Mostrar deuda actual si está en modo edición
                    Label {
                        visible: customerFormViewModel.isEditMode && customerFormViewModel.currentDebt > 0
                        text: qsTr("⚠️ Deuda actual: S/ %1").arg(customerFormViewModel.currentDebt.toFixed(2))
                        font.pixelSize: 12
                        color: Material.color(Material.Orange)
                        wrapMode: Text.Wrap
                    }
                }

                Item {
                    Layout.fillHeight: true
                }
            }
        }
    }

    // Diálogo de confirmación de eliminación
    Dialog {
        id: deleteDialog
        title: qsTr("Confirmar eliminación")
        modal: true
        anchors.centerIn: parent
        standardButtons: Dialog.Yes | Dialog.No

        property int customerId: 0
        property string customerName: ""

        Label {
            text: qsTr("¿Está seguro que desea eliminar al cliente '%1'?\n\nEsta acción no se puede deshacer.").arg(deleteDialog.customerName)
            wrapMode: Text.WordWrap
        }

        onAccepted: {
            if (customerListModel.remove(deleteDialog.customerId)) {
                globalNotification.show("Cliente eliminado exitosamente", "success")
            } else {
                globalNotification.show("Error al eliminar cliente", "error")
            }
        }
    }

    // Diálogo de detalles de ventas del cliente
    Dialog {
        id: customerDetailsDialog
        title: qsTr("Detalles de Ventas - %1").arg(customerName)
        width: Math.min(900, root.width * 0.95)
        height: Math.min(700, root.height * 0.9)
        modal: true
        anchors.centerIn: parent
        standardButtons: Dialog.Close

        property int customerId: 0
        property string customerName: ""
        property var salesData: []

        function loadSales() {
            var fromDate = fromDateField.text ? new Date(fromDateField.text) : new Date(1970, 0, 1)
            var toDate = toDateField.text ? new Date(toDateField.text) : new Date()
            salesData = customerListModel.getCustomerSales(customerId, fromDate, toDate)
            salesListModel.clear()
            
            var totalAmount = 0
            var totalPending = 0
            
            for (var i = 0; i < salesData.length; i++) {
                salesListModel.append(salesData[i])
                totalAmount += salesData[i].total
                if (salesData[i].paymentStatus === "PENDING" || salesData[i].paymentStatus === "PARTIAL") {
                    totalPending += salesData[i].total
                }
            }
            
            salesCountLabel.text = salesData.length.toString()
            totalPendingLabel.text = "S/ " + totalPending.toFixed(2)
            totalSalesLabel.text = "S/ " + totalAmount.toFixed(2)
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 16

            // Filtros de fecha
            GroupBox {
                Layout.fillWidth: true
                title: qsTr("Filtrar por fecha")

                RowLayout {
                    anchors.fill: parent
                    spacing: 16

                    ColumnLayout {
                        spacing: 4

                        Label {
                            text: qsTr("Desde:")
                            font.pixelSize: 12
                        }

                        TextField {
                            id: fromDateField
                            placeholderText: "dd/MM/yyyy"
                            inputMask: "99/99/9999"
                            Layout.preferredWidth: 120
                        }
                    }

                    ColumnLayout {
                        spacing: 4

                        Label {
                            text: qsTr("Hasta:")
                            font.pixelSize: 12
                        }

                        TextField {
                            id: toDateField
                            placeholderText: "dd/MM/yyyy"
                            inputMask: "99/99/9999"
                            Layout.preferredWidth: 120
                        }
                    }

                    Button {
                        text: qsTr("Aplicar Filtro")
                        Material.background: Material.primary
                        onClicked: customerDetailsDialog.loadSales()
                    }

                    Button {
                        text: qsTr("Limpiar")
                        onClicked: {
                            fromDateField.text = ""
                            toDateField.text = ""
                            customerDetailsDialog.loadSales()
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }
                }
            }

            // Resumen en tabla compacta 2x3
            Rectangle {
                Layout.fillWidth: true
                height: 80
                color: Material.dialogColor
                border.color: Material.dividerColor
                border.width: 1
                radius: 4

                GridLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    columns: 3
                    rows: 2
                    rowSpacing: 2
                    columnSpacing: 12

                    // Primera columna
                    Label {
                        text: qsTr("Total de ventas:")
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: Material.theme === Material.Dark ? "#FFFFFF" : "#000000"
                        Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                    }

                    // Segunda columna
                    Label {
                        text: qsTr("Total pendiente:")
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: Material.theme === Material.Dark ? "#FFFFFF" : "#000000"
                        Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                    }

                    // Tercera columna
                    Label {
                        text: qsTr("Monto total:")
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: Material.theme === Material.Dark ? "#FFFFFF" : "#000000"
                        Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                    }

                    // Segunda fila - valores
                    Label {
                        id: salesCountLabel
                        font.pixelSize: 16
                        font.weight: Font.Bold
                        color: Material.color(Material.Blue)
                        Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                    }

                    Label {
                        id: totalPendingLabel
                        font.pixelSize: 16
                        font.weight: Font.Bold
                        color: Material.color(Material.Red)
                        Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                    }

                    Label {
                        id: totalSalesLabel
                        font.pixelSize: 16
                        font.weight: Font.Bold
                        color: Material.color(Material.Green)
                        Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                    }
                }
            }

            // Botón para pagar deudas
            Button {
                id: payDebtsButton
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                visible: totalPendingLabel.text !== "S/ 0.00" && totalPendingLabel.text !== ""
                text: qsTr("💰 Pagar Todas las Deudas Pendientes")
                font.pixelSize: 14
                font.weight: Font.Bold
                Material.background: Material.color(Material.Green)
                Material.foreground: "white"
                
                onClicked: {
                    payDebtsConfirmDialog.open()
                }
            }

            // Tabla de ventas
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Material.background
                border.color: Material.dividerColor
                border.width: 1
                radius: 4

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 1
                    spacing: 0

                    // Encabezado de tabla
                    Rectangle {
                        Layout.fillWidth: true
                        height: 40
                        color: Material.dialogColor

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 8

                            Label {
                                Layout.preferredWidth: 90
                                text: qsTr("Fecha")
                                font.weight: Font.Medium
                                font.pixelSize: 12
                            }

                            Label {
                                Layout.preferredWidth: 100
                                text: qsTr("Factura")
                                font.weight: Font.Medium
                                font.pixelSize: 12
                            }

                            Label {
                                Layout.preferredWidth: 70
                                text: qsTr("Tipo")
                                font.weight: Font.Medium
                                font.pixelSize: 12
                            }

                            Label {
                                Layout.preferredWidth: 60
                                text: qsTr("Items")
                                font.weight: Font.Medium
                                font.pixelSize: 12
                                horizontalAlignment: Text.AlignRight
                            }

                            Label {
                                Layout.preferredWidth: 100
                                text: qsTr("Método")
                                font.weight: Font.Medium
                                font.pixelSize: 12
                            }

                            Label {
                                Layout.preferredWidth: 90
                                text: qsTr("Estado")
                                font.weight: Font.Medium
                                font.pixelSize: 12
                            }

                            Label {
                                Layout.fillWidth: true
                                text: qsTr("Total")
                                font.weight: Font.Medium
                                font.pixelSize: 12
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                    }

                    // Lista de ventas
                    ListView {
                        id: salesListView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        model: ListModel {
                            id: salesListModel
                        }

                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AsNeeded
                        }

                        delegate: ItemDelegate {
                            width: salesListView.width
                            height: 50

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 8

                                Label {
                                    Layout.preferredWidth: 90
                                    text: model.saleDate
                                    font.pixelSize: 13
                                }

                                Label {
                                    Layout.preferredWidth: 100
                                    text: model.invoiceNumber || "-"
                                    font.pixelSize: 13
                                    font.family: "monospace"
                                }

                                Label {
                                    Layout.preferredWidth: 70
                                    text: model.paymentType === "CREDITO" ? "Crédito" : "Contado"
                                    font.pixelSize: 12
                                    color: model.paymentType === "CREDITO" ? Material.color(Material.Orange) : Material.foreground
                                }

                                Label {
                                    Layout.preferredWidth: 60
                                    text: model.totalItems ? model.totalItems.toFixed(0) : model.itemCount
                                    font.pixelSize: 13
                                    horizontalAlignment: Text.AlignRight
                                    font.family: "monospace"
                                }

                                Label {
                                    Layout.preferredWidth: 100
                                    text: model.paymentMethod || "-"
                                    font.pixelSize: 12
                                    opacity: 0.8
                                }

                                Label {
                                    Layout.preferredWidth: 90
                                    text: {
                                        if (model.paymentStatus === "PAID") return "Pagado"
                                        if (model.paymentStatus === "PENDING") return "Pendiente"
                                        if (model.paymentStatus === "PARTIAL") return "Parcial"
                                        return "-"
                                    }
                                    font.pixelSize: 12
                                    font.weight: Font.Medium
                                    color: {
                                        if (model.paymentStatus === "PAID") return Material.color(Material.Green)
                                        if (model.paymentStatus === "PENDING") return Material.color(Material.Red)
                                        if (model.paymentStatus === "PARTIAL") return Material.color(Material.Orange)
                                        return Material.foreground
                                    }
                                }

                                Label {
                                    Layout.fillWidth: true
                                    text: "S/ " + (model.total ? model.total.toFixed(2) : "0.00")
                                    font.pixelSize: 14
                                    font.weight: Font.Medium
                                    font.family: "monospace"
                                    horizontalAlignment: Text.AlignRight
                                }
                            }

                            Rectangle {
                                anchors.bottom: parent.bottom
                                width: parent.width
                                height: 1
                                color: Material.dividerColor
                            }
                        }

                        // Estado vacío
                        Label {
                            anchors.centerIn: parent
                            visible: salesListModel.count === 0
                            text: qsTr("No se encontraron ventas\nen el rango de fechas especificado")
                            font.pixelSize: 14
                            opacity: 0.5
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }
            }
        }

        onOpened: {
            fromDateField.text = ""
            toDateField.text = ""
        }
    }

    // Diálogo de confirmación para pagar deudas
    Dialog {
        id: payDebtsConfirmDialog
        title: qsTr("Confirmar Pago de Deudas")
        width: Math.min(500, root.width * 0.9)
        modal: true
        anchors.centerIn: parent
        standardButtons: Dialog.Yes | Dialog.No

        ColumnLayout {
            anchors.fill: parent
            spacing: 16

            Label {
                Layout.fillWidth: true
                text: qsTr("¿Está seguro que desea marcar todas las deudas pendientes de este cliente como pagadas?")
                wrapMode: Text.WordWrap
                font.pixelSize: 14
            }

            Rectangle {
                Layout.fillWidth: true
                height: 60
                color: Material.color(Material.Red, Material.Shade100)
                radius: 4
                border.color: Material.color(Material.Red)
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 4

                    Label {
                        text: qsTr("Total a pagar:")
                        font.pixelSize: 12
                        opacity: 0.8
                    }

                    Label {
                        text: totalPendingLabel.text
                        font.pixelSize: 20
                        font.weight: Font.Bold
                        color: Material.color(Material.Red)
                    }
                }
            }

            Label {
                Layout.fillWidth: true
                text: qsTr("Esta acción cambiará el estado de todas las ventas pendientes a 'PAGADO' en la base de datos.")
                wrapMode: Text.WordWrap
                font.pixelSize: 12
                opacity: 0.7
            }
        }

        onAccepted: {
            console.log("=== INICIANDO PAGO DE DEUDAS ===")
            console.log("Cliente ID:", customerDetailsDialog.customerId)
            console.log("Monto pendiente antes:", totalPendingLabel.text)
            
            var updatedCount = customerListModel.payCustomerDebts(customerDetailsDialog.customerId)
            
            console.log("Ventas actualizadas:", updatedCount)
            
            if (updatedCount > 0) {
                // Mostrar mensaje de éxito con el monto pagado
                var paidAmount = totalPendingLabel.text
                snackbar.show(qsTr("✓ ¡Pago exitoso! %1 venta(s) marcadas como PAGADAS. Total: %2").arg(updatedCount).arg(paidAmount), "success")
                
                // Recargar las ventas del cliente (esto actualizará los estados a PAID)
                customerDetailsDialog.loadSales()
                
                // Forzar actualización de la lista principal de clientes
                customerListModel.refresh()
                
                console.log("Monto pendiente después:", totalPendingLabel.text)
                console.log("=== PAGO COMPLETADO ===")
            } else {
                snackbar.show(qsTr("No se encontraron deudas pendientes para pagar"), "info")
            }
        }
    }

    // Snackbar para mensajes
    Rectangle {
        id: snackbar
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 20
        width: Math.min(400, parent.width - 40)
        height: 50
        radius: 4
        color: Material.dialogColor
        border.color: Material.accentColor
        border.width: 1
        visible: false
        z: 1000

        property string messageType: "info"

        function show(message, type) {
            messageType = type || "info"
            snackbarLabel.text = message
            
            if (type === "success") {
                snackbar.color = Material.color(Material.Green, Material.Shade900)
                snackbar.border.color = Material.color(Material.Green)
            } else if (type === "error") {
                snackbar.color = Material.color(Material.Red, Material.Shade900)
                snackbar.border.color = Material.color(Material.Red)
            } else {
                snackbar.color = Material.dialogColor
                snackbar.border.color = Material.accentColor
            }
            
            visible = true
            snackbarTimer.restart()
        }

        Label {
            id: snackbarLabel
            anchors.centerIn: parent
            anchors.margins: 12
            color: "white"
            font.pixelSize: 14
            font.weight: Font.Medium
        }

        Timer {
            id: snackbarTimer
            interval: 4000
            onTriggered: snackbar.visible = false
        }

        MouseArea {
            anchors.fill: parent
            onClicked: snackbar.visible = false
        }
    }
}
