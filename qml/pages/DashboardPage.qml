import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtCharts
import SistemaInventario
import "../components"

Page {
    id: root
    title: qsTr("Dashboard")

    // ViewModel real de Dashboard
    DashboardViewModel {
        id: viewModel
        Component.onCompleted: {
            refresh()
            // Seleccionar cajero por defecto si hay disponibles
            if (availableCashiers.length > 0) {
                currentCashier = availableCashiers[0]
            }
        }
        
        onDayClosingCompleted: function(report) {
            closingReportDialog.reportData = JSON.parse(report)
            closingReportDialog.open()
        }
    }
    
    // Datos temporales de prueba - ELIMINADOS, ahora usa viewModel real

    ScrollView {
        anchors.fill: parent
        anchors.margins: root.width > 800 ? 20 : (root.width > 600 ? 16 : 12)
        contentWidth: availableWidth

        ColumnLayout {
            width: parent.width
            spacing: root.width > 800 ? 20 : (root.width > 600 ? 16 : 12)

            // Título
            Label {
                text: qsTr("Panel de Control")
                font.pixelSize: root.width > 800 ? 32 : (root.width > 600 ? 28 : 24)
                font.weight: Font.Bold
                color: Material.foreground
                Layout.bottomMargin: root.width > 600 ? 8 : 4
            }

            // Tarjetas de estadísticas
            GridLayout {
                Layout.fillWidth: true
                columns: root.width > 1000 ? 4 : 2
                rowSpacing: 16
                columnSpacing: 16

                // Selector de cajero
                GroupBox {
                    Layout.columnSpan: root.width > 1000 ? 4 : 2
                    Layout.fillWidth: true
                    title: qsTr("Cajero/Vendedor Actual")
                    
                    RowLayout {
                        anchors.fill: parent
                        spacing: 12
                        
                        Label {
                            text: "\uE77B"
                            font.family: "Segoe MDL2 Assets"
                            font.pixelSize: root.width > 600 ? 20 : 16
                            color: Material.primary
                        }
                        
                        // Mostrar ComboBox solo si hay múltiples cajeros (Admin/Programador)
                        ComboBox {
                            id: cashierComboBox
                            Layout.fillWidth: root.width <= 700
                            Layout.preferredWidth: root.width > 700 ? 200 : -1
                            model: viewModel.availableCashiers
                            currentIndex: viewModel.availableCashiers.indexOf(viewModel.currentCashier)
                            visible: viewModel.availableCashiers.length > 1
                            font.pixelSize: root.width > 600 ? 14 : 12
                            onActivated: {
                                viewModel.currentCashier = currentText
                            }
                        }
                        
                        // Mostrar Label si solo hay un cajero (Vendedor)
                        Label {
                            Layout.fillWidth: root.width <= 700
                            text: viewModel.currentCashier
                            font.pixelSize: root.width > 600 ? 14 : 12
                            font.weight: Font.Medium
                            visible: viewModel.availableCashiers.length === 1
                            elide: Text.ElideRight
                        }
                        
                        Label {
                            text: root.width > 700 ? 
                                qsTr("Ventas: S/") + viewModel.todaySalesByCashier.toFixed(2) + 
                                qsTr(" | Transacciones: ") + viewModel.todayTransactionsByCashier :
                                "S/" + viewModel.todaySalesByCashier.toFixed(2) + " | " + viewModel.todayTransactionsByCashier
                            font.weight: Font.Medium
                            font.pixelSize: root.width > 600 ? 14 : 11
                            color: Material.primary
                            elide: Text.ElideRight
                            Layout.fillWidth: root.width <= 700
                        }
                    }
                }

                // Ventas del día
                StatCard {
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.width > 800 ? 120 : (root.width > 600 ? 100 : 90)
                    title: qsTr("Ventas del Día")
                    value: "S/" + viewModel.todaySales.toFixed(2)
                    subtitle: viewModel.todayTransactions + " transacciones"
                    icon: "󰄫"
                    accentColor: Material.color(Material.Green)
                }

                // Ventas del mes
                StatCard {
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.width > 800 ? 120 : (root.width > 600 ? 100 : 90)
                    title: qsTr("Ventas del Mes")
                    value: "S/" + viewModel.monthSales.toFixed(2)
                    subtitle: "Ticket promedio: S/" + viewModel.averageTicket.toFixed(2)
                    icon: "󰄬"
                    accentColor: Material.color(Material.Blue)
                }

                // Productos totales
                StatCard {
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.width > 800 ? 120 : (root.width > 600 ? 100 : 90)
                    title: qsTr("Productos")
                    value: viewModel.totalProducts.toString()
                    subtitle: qsTr("Total en catálogo")
                    icon: "󰏓"
                    accentColor: Material.color(Material.Purple)
                }

                // Stock bajo
                StatCard {
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.width > 800 ? 120 : (root.width > 600 ? 100 : 90)
                    title: qsTr("Stock Bajo")
                    value: viewModel.lowStockProducts.toString()
                    subtitle: qsTr("Requieren atención")
                    icon: "󰀦"
                    accentColor: Material.color(Material.Orange)
                    warning: viewModel.lowStockProducts > 0
                }
            }

            // Acciones rápidas
            GroupBox {
                Layout.fillWidth: true
                title: qsTr("Acciones Rápidas")

                GridLayout {
                    anchors.fill: parent
                    columns: root.width > 1000 ? 4 : 2
                    rowSpacing: 12
                    columnSpacing: 12

                PrimaryButton {
                    Layout.fillWidth: true
                    text: qsTr("Nueva Venta")
                    iconText: "\uE8C8"
                    Material.background: Material.theme === Material.Dark ?
                        Qt.darker(ApplicationWindow.window?.currentColors?.primary ?? Material.primary, 1.2) :
                        Qt.lighter(ApplicationWindow.window?.currentColors?.primary ?? Material.primary, 1.2)
                    contentItem: Label {
                        text: parent.iconText !== "" ? parent.iconText + "  " + parent.text : parent.text
                        font.family: parent.iconText !== "" ? "Segoe MDL2 Assets" : parent.font.family
                        font.pixelSize: parent.font.pixelSize
                        font.weight: parent.font.weight
                        color: "#FFFFFF"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: {
                        // Navegar a la página de ventas
                        if (ApplicationWindow.window && ApplicationWindow.window.stackView) {
                            ApplicationWindow.window.stackView.replace("SalesPage.qml")
                        }
                    }
                }

                PrimaryButton {
                    Layout.fillWidth: true
                    text: qsTr("Nuevo Producto")
                    iconText: "\uE710"
                    Material.background: Material.theme === Material.Dark ?
                        Qt.darker(ApplicationWindow.window?.currentColors?.primary ?? Material.primary, 1.2) :
                        Qt.lighter(ApplicationWindow.window?.currentColors?.primary ?? Material.primary, 1.2)
                    contentItem: Label {
                        text: parent.iconText !== "" ? parent.iconText + "  " + parent.text : parent.text
                        font.family: parent.iconText !== "" ? "Segoe MDL2 Assets" : parent.font.family
                        font.pixelSize: parent.font.pixelSize
                        font.weight: parent.font.weight
                        color: "#FFFFFF"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: {
                        // Navegar a la página de productos
                        if (ApplicationWindow.window && ApplicationWindow.window.stackView) {
                            ApplicationWindow.window.stackView.replace("ProductsPage.qml")
                        }
                    }
                }

                PrimaryButton {
                    Layout.fillWidth: true
                    text: qsTr("Importar Excel")
                    iconText: "\uE898"
                    Material.background: Material.theme === Material.Dark ?
                        Qt.darker(ApplicationWindow.window?.currentColors?.primary ?? Material.primary, 1.2) :
                        Qt.lighter(ApplicationWindow.window?.currentColors?.primary ?? Material.primary, 1.2)
                    contentItem: Label {
                        text: parent.iconText !== "" ? parent.iconText + "  " + parent.text : parent.text
                        font.family: parent.iconText !== "" ? "Segoe MDL2 Assets" : parent.font.family
                        font.pixelSize: parent.font.pixelSize
                        font.weight: parent.font.weight
                        color: "#FFFFFF"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: {
                        // Navegar a la página de importación
                        if (ApplicationWindow.window && ApplicationWindow.window.stackView) {
                            ApplicationWindow.window.stackView.replace("ImportPage.qml")
                        }
                    }
                }

                PrimaryButton {
                    Layout.fillWidth: true
                    text: qsTr("Ver Reportes")
                    iconText: "\uE9D9"
                    Material.background: Material.theme === Material.Dark ?
                        Qt.darker(ApplicationWindow.window?.currentColors?.primary ?? Material.primary, 1.2) :
                        Qt.lighter(ApplicationWindow.window?.currentColors?.primary ?? Material.primary, 1.2)
                    contentItem: Label {
                        text: parent.iconText !== "" ? parent.iconText + "  " + parent.text : parent.text
                        font.family: parent.iconText !== "" ? "Segoe MDL2 Assets" : parent.font.family
                        font.pixelSize: parent.font.pixelSize
                        font.weight: parent.font.weight
                        color: "#FFFFFF"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: {
                        // Navegar a la página de reportes
                        if (ApplicationWindow.window && ApplicationWindow.window.stackView) {
                            ApplicationWindow.window.stackView.replace("ReportsPage.qml")
                        }
                    }
                }
                }
            }

            // Gráficos de ventas - Siempre visibles
            GridLayout {
                Layout.fillWidth: true
                columns: root.width > 1000 ? 2 : 1
                rowSpacing: 16
                columnSpacing: 16
                
                // Gráfico circular - Ventas por comprobante
                GroupBox {
                    id: voucherChartBox
                    Layout.fillWidth: true
                    Layout.preferredHeight: 400
                    title: "Ventas por Tipo de Comprobante (Hoy)"
                    
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 12
                        
                        // Resumen en cards
                        GridLayout {
                            visible: voucherSummaryModel.count > 0
                            Layout.fillWidth: true
                            columns: root.width > 1200 ? 3 : (root.width > 600 ? 3 : 1)
                            rowSpacing: 6
                            columnSpacing: 6
                            
                            Repeater {
                                id: voucherSummary
                                model: ListModel { id: voucherSummaryModel }
                                
                                delegate: Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 50
                                    radius: 6
                                    color: "transparent"
                                    border.width: 1
                                    border.color: Material.theme === Material.Dark ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(0, 0, 0, 0.08)
                                    
                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        spacing: 8
                                        
                                        Rectangle {
                                            Layout.preferredWidth: 8
                                            Layout.preferredHeight: 8
                                            radius: 4
                                            color: {
                                                var colors = ["#2196F3", "#9C27B0", "#4CAF50"]
                                                return colors[index % colors.length]
                                            }
                                        }
                                        
                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 0
                                            
                                            Label {
                                                text: model.label
                                                font.weight: Font.Medium
                                                font.pixelSize: 11
                                            }
                                            
                                            Label {
                                                text: model.count + " ventas (" + model.percentage + "%)"
                                                opacity: 0.6
                                                font.pixelSize: 9
                                            }
                                        }
                                        
                                        Label {
                                            text: "S/ " + Number(model.value).toFixed(2)
                                            font.weight: Font.Bold
                                            font.pixelSize: 12
                                            Layout.alignment: Qt.AlignRight
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Gráfico circular
                        ChartView {
                            id: voucherChart
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.minimumHeight: 250
                            antialiasing: true
                            legend.visible: false
                            backgroundColor: "transparent"
                            animationOptions: ChartView.SeriesAnimations
                            theme: Material.theme === Material.Dark ? ChartView.ChartThemeDark : ChartView.ChartThemeLight
                            backgroundRoundness: 0
                            
                            PieSeries {
                                id: voucherSeries
                                size: 0.8
                                holeSize: 0.45
                                
                                onClicked: function(slice) {
                                    slice.exploded = !slice.exploded
                                }
                                
                                onHovered: function(slice, state) {
                                    if(state) slice.explodeDistanceFactor = 0.05
                                    else slice.explodeDistanceFactor = 0.03
                                }
                            }
                        }
                    }
                    
                    Component.onCompleted: {
                        updateVoucherChart()
                    }
                    
                    function updateVoucherChart() {
                        var data = viewModel.getSalesByVoucherType()
                        voucherSeries.clear()
                        voucherSummaryModel.clear()
                        
                        if (data.length === 0) {
                            var emptySlice = voucherSeries.append("Sin ventas", 1)
                            emptySlice.color = Qt.rgba(0.5, 0.5, 0.5, 0.2)
                            return
                        }
                        
                        // Calcular el total para porcentajes
                        var total = 0
                        for (var i = 0; i < data.length; i++) {
                            total += data[i].value
                        }
                        
                        var colors = ["#2196F3", "#9C27B0", "#4CAF50"]
                        for (var i = 0; i < data.length; i++) {
                            var percentage = total > 0 ? ((data[i].value / total) * 100).toFixed(1) : 0
                            
                            var slice = voucherSeries.append(data[i].label + "\n" + percentage + "%", data[i].value)
                            slice.color = colors[i % colors.length]
                            slice.labelVisible = true
                            slice.labelPosition = PieSlice.LabelInsideHorizontal
                            slice.labelColor = "#FFFFFF"
                            slice.labelFont.pixelSize = 10
                            slice.labelFont.bold = true
                            
                            voucherSummaryModel.append({
                                "label": data[i].label,
                                "count": data[i].count,
                                "value": data[i].value,
                                "percentage": percentage
                            })
                        }
                    }
                    
                    Connections {
                        target: viewModel
                        function onTodaySalesChanged() {
                            voucherChartBox.updateVoucherChart()
                        }
                    }
                }
                
                // Gráfico de barras - Productos con stock bajo
                GroupBox {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 400
                    title: "Productos con Stock Bajo"
                    
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 12
                        
                        Label {
                            text: viewModel.lowStockProducts > 0 ? 
                                viewModel.lowStockProducts + " productos requieren atención" : 
                                "Stock en niveles normales"
                            font.pixelSize: 11
                            opacity: 0.7
                            color: viewModel.lowStockProducts > 0 ? Material.color(Material.Orange) : Material.color(Material.Green)
                        }
                        
                        ChartView {
                            id: stockChart
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.minimumHeight: 280
                            antialiasing: true
                            legend.visible: false
                            backgroundColor: "transparent"
                            animationOptions: ChartView.SeriesAnimations
                            theme: Material.theme === Material.Dark ? ChartView.ChartThemeDark : ChartView.ChartThemeLight
                            
                            BarSeries {
                                id: stockSeries
                                labelsVisible: true
                                labelsPosition: AbstractBarSeries.LabelsOutsideEnd
                                
                                BarSet {
                                    id: stockBarSet
                                    label: "Stock actual"
                                    color: Material.color(Material.Orange)
                                }
                            }
                            
                            BarCategoryAxis {
                                id: stockAxisX
                                titleText: ""
                            }
                            
                            ValueAxis {
                                id: stockAxisY
                                titleText: "Unidades"
                                min: 0
                                max: 50
                                tickCount: 6
                            }
                            
                            Component.onCompleted: {
                                stockSeries.axisX = stockAxisX
                                stockSeries.axisY = stockAxisY
                                updateStockChart()
                            }
                        }
                    }
                    
                    function updateStockChart() {
                        // Simulación de datos - conectar con ViewModel más adelante
                        stockAxisX.categories = ["Prod. A", "Prod. B", "Prod. C", "Prod. D", "Prod. E"]
                        stockBarSet.values = [12, 8, 15, 5, 18]
                    }
                }
            }
            
            // Productos más vendidos y clientes frecuentes
            GridLayout {
                Layout.fillWidth: true
                columns: root.width > 1000 ? 2 : 1
                rowSpacing: 16
                columnSpacing: 16
                
                // Productos más vendidos
                GroupBox {
                    id: topProductsBox
                    Layout.fillWidth: true
                    Layout.minimumHeight: Math.max(300, Math.min(380, root.height * 0.35))
                    Layout.preferredHeight: Math.max(350, Math.min(450, root.height * 0.4))
                    title: qsTr("Top 5 Productos Más Vendidos (Hoy)")
                    
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 8
                        
                        Repeater {
                            id: topProductsRepeater
                            model: ListModel { id: topProductsModel }
                            
                            delegate: Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 48
                                radius: 4
                                color: "transparent"
                                border.width: Material.theme === Material.Dark ? 0 : 1
                                border.color: Material.theme === Material.Dark ? "transparent" : Qt.rgba(0, 0, 0, 0.08)
                                
                                Rectangle {
                                    anchors.fill: parent
                                    radius: parent.radius
                                    opacity: 0.03
                                    color: Material.primary
                                }
                                
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 16
                                    anchors.rightMargin: 16
                                    anchors.topMargin: 8
                                    anchors.bottomMargin: 8
                                    spacing: 16
                                    
                                    Label {
                                        text: index === 0 ? "\uE735" : index === 1 ? "\uE735" : index === 2 ? "\uE735" : (index + 1)
                                        font.family: index < 3 ? "Segoe MDL2 Assets" : ""
                                        font.weight: Font.Bold
                                        font.pixelSize: 16
                                        color: index === 0 ? "#FFD700" : index === 1 ? "#C0C0C0" : index === 2 ? "#CD7F32" : Material.primary
                                        Layout.preferredWidth: 24
                                    }
                                    
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 0
                                        
                                        Label {
                                            text: model.name
                                            font.weight: Font.Medium
                                            font.pixelSize: 13
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                        
                                        Label {
                                            text: "S/ " + Number(model.revenue).toFixed(2)
                                            opacity: 0.6
                                            font.pixelSize: 11
                                        }
                                    }
                                    
                                    Label {
                                        text: Number(model.quantity).toFixed(0) + " u."
                                        font.weight: Font.DemiBold
                                        font.pixelSize: 14
                                        color: Material.accent
                                        Layout.alignment: Qt.AlignRight
                                    }
                                }
                            }
                        }
                        
                        ColumnLayout {
                            visible: topProductsModel.count === 0
                            Layout.alignment: Qt.AlignHCenter
                            Layout.topMargin: 40
                            spacing: 8
                            
                            Label {
                                text: "\uE7C5"
                                font.family: "Segoe MDL2 Assets"
                                font.pixelSize: 48
                                opacity: 0.2
                                Layout.alignment: Qt.AlignHCenter
                            }
                            
                            Label {
                                text: qsTr("Realiza ventas para ver estadísticas")
                                opacity: 0.5
                                font.pixelSize: 12
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }
                    
                    Component.onCompleted: {
                        updateTopProducts()
                    }
                    
                    function updateTopProducts() {
                        var data = viewModel.getTopProducts(5)
                        topProductsModel.clear()
                        
                        for (var i = 0; i < data.length; i++) {
                            topProductsModel.append({
                                "name": data[i].name,
                                "quantity": data[i].quantity,
                                "revenue": data[i].revenue
                            })
                        }
                    }
                    
                    Connections {
                        target: viewModel
                        function onTodaySalesChanged() {
                            topProductsBox.updateTopProducts()
                        }
                    }
                }
                
                // Clientes frecuentes
                GroupBox {
                    id: topCustomersBox
                    Layout.fillWidth: true
                    Layout.minimumHeight: Math.max(300, Math.min(380, root.height * 0.35))
                    Layout.preferredHeight: Math.max(350, Math.min(450, root.height * 0.4))
                    title: qsTr("Clientes Frecuentes (Este Mes)")
                    
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 8
                        
                        Repeater {
                            id: topCustomersRepeater
                            model: ListModel { id: topCustomersModel }
                            
                            delegate: Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 48
                                radius: 4
                                color: "transparent"
                                border.width: Material.theme === Material.Dark ? 0 : 1
                                border.color: Material.theme === Material.Dark ? "transparent" : Qt.rgba(0, 0, 0, 0.08)
                                
                                Rectangle {
                                    anchors.fill: parent
                                    radius: parent.radius
                                    opacity: 0.03
                                    color: Material.primary
                                }
                                
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 16
                                    anchors.rightMargin: 16
                                    anchors.topMargin: 8
                                    anchors.bottomMargin: 8
                                    spacing: 16
                                    
                                    Label {
                                        text: "\uE77B"
                                        font.family: "Segoe MDL2 Assets"
                                        font.pixelSize: 18
                                        color: Material.primary
                                        opacity: 0.7
                                        Layout.preferredWidth: 24
                                    }
                                    
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 0
                                        
                                        Label {
                                            text: model.name
                                            font.weight: Font.Medium
                                            font.pixelSize: 13
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                        
                                        Label {
                                            text: qsTr("%1 compras").arg(model.purchases)
                                            opacity: 0.6
                                            font.pixelSize: 11
                                        }
                                    }
                                    
                                    Label {
                                        text: "S/ " + Number(model.totalSpent).toFixed(2)
                                        font.weight: Font.DemiBold
                                        font.pixelSize: 14
                                        color: Material.accent
                                        Layout.alignment: Qt.AlignRight
                                    }
                                }
                            }
                        }
                        
                        ColumnLayout {
                            visible: topCustomersModel.count === 0
                            Layout.alignment: Qt.AlignHCenter
                            Layout.topMargin: 40
                            spacing: 8
                            
                            Label {
                                text: "\uE716"
                                font.family: "Segoe MDL2 Assets"
                                font.pixelSize: 48
                                opacity: 0.2
                                Layout.alignment: Qt.AlignHCenter
                            }
                            
                            Label {
                                text: qsTr("Registra clientes para ver estadísticas")
                                opacity: 0.5
                                font.pixelSize: 12
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }
                    
                    Component.onCompleted: {
                        updateTopCustomers()
                    }
                    
                    function updateTopCustomers() {
                        var data = viewModel.getTopCustomers(5)
                        topCustomersModel.clear()
                        
                        for (var i = 0; i < data.length; i++) {
                            topCustomersModel.append({
                                "name": data[i].name,
                                "purchases": data[i].purchases,
                                "totalSpent": data[i].totalSpent
                            })
                        }
                    }
                    
                    Connections {
                        target: viewModel
                        function onMonthSalesChanged() {
                            topCustomersBox.updateTopCustomers()
                        }
                    }
                }
            }
            
            // Gráfico de líneas - Tendencia de ventas últimos 7 días
            GroupBox {
                Layout.fillWidth: true
                Layout.preferredHeight: 400
                title: "Tendencia de Ventas (Últimos 7 Días)"
                
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 12
                    
                    // Leyenda personalizada con puntos redondos
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 20
                        
                        RowLayout {
                            spacing: 6
                            Rectangle {
                                width: 10
                                height: 10
                                radius: 5
                                color: Material.color(Material.Blue)
                            }
                            Label {
                                text: "Total Ventas"
                                font.pixelSize: 11
                            }
                        }
                        
                        RowLayout {
                            spacing: 6
                            Rectangle {
                                width: 10
                                height: 10
                                radius: 5
                                color: Material.color(Material.Green)
                            }
                            Label {
                                text: "N° Transacciones"
                                font.pixelSize: 11
                            }
                        }
                    }
                    
                    ChartView {
                        id: salesTrendChart
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.minimumHeight: 280
                        antialiasing: true
                        legend.visible: false
                        backgroundColor: "transparent"
                        animationOptions: ChartView.SeriesAnimations
                        theme: Material.theme === Material.Dark ? ChartView.ChartThemeDark : ChartView.ChartThemeLight
                        
                        LineSeries {
                            id: salesAmountSeries
                            name: "Total Ventas"
                            color: Material.color(Material.Blue)
                            width: 2
                            pointsVisible: true
                            
                            axisX: DateTimeAxis {
                                id: salesDateAxis
                                format: "dd/MM"
                                tickCount: 7
                                labelsAngle: 0
                            }
                            
                            axisY: ValueAxis {
                                id: salesAmountAxis
                                titleText: "Monto (S/)"
                                min: 0
                                max: 1000
                                tickCount: 6
                            }
                        }
                        
                        LineSeries {
                            id: salesCountSeries
                            name: "N° Transacciones"
                            color: Material.color(Material.Green)
                            width: 2
                            pointsVisible: true
                            
                            axisX: salesDateAxis
                            axisYRight: ValueAxis {
                                id: salesCountAxis
                                titleText: "Cantidad"
                                min: 0
                                max: 50
                                tickCount: 6
                            }
                        }
                    }
                    
                    Component.onCompleted: {
                        updateSalesTrend()
                    }
                    
                    function updateSalesTrend() {
                        // Simulación de datos - conectar con ViewModel más adelante
                        salesAmountSeries.clear()
                        salesCountSeries.clear()
                        
                        var today = new Date()
                        for (var i = 6; i >= 0; i--) {
                            var date = new Date(today)
                            date.setDate(date.getDate() - i)
                            var timestamp = date.getTime()
                            
                            // Datos simulados
                            var amount = 200 + Math.random() * 500
                            var count = 5 + Math.floor(Math.random() * 20)
                            
                            salesAmountSeries.append(timestamp, amount)
                            salesCountSeries.append(timestamp, count)
                        }
                        
                        // Ajustar máximo del eje Y
                        var maxAmount = 0
                        var maxCount = 0
                        for (var j = 0; j < salesAmountSeries.count; j++) {
                            if (salesAmountSeries.at(j).y > maxAmount) maxAmount = salesAmountSeries.at(j).y
                        }
                        for (var k = 0; k < salesCountSeries.count; k++) {
                            if (salesCountSeries.at(k).y > maxCount) maxCount = salesCountSeries.at(k).y
                        }
                        salesAmountAxis.max = Math.ceil(maxAmount * 1.2 / 100) * 100
                        salesCountAxis.max = Math.ceil(maxCount * 1.2 / 5) * 5
                    }
                }
            }

            // Productos con stock bajo
            GroupBox {
                Layout.fillWidth: true
                title: "Alertas de Stock Bajo"
                visible: viewModel.lowStockProducts > 0

                Label {
                    text: qsTr("Hay %1 productos con stock bajo. Revisar inventario.").arg(viewModel.lowStockProducts)
                    wrapMode: Text.WordWrap
                    color: Material.color(Material.Orange)
                }
            }
            
            // Reportes del día
            GroupBox {
                Layout.fillWidth: true
                title: qsTr("Reportes del Día")
                
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 12
                    
                    Label {
                        text: qsTr("Genera reportes y consulta las ventas del día")
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                        opacity: 0.7
                    }
                    
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 20
                        
                        // Espaciador izquierdo para centrar
                        Item {
                            Layout.fillWidth: true
                        }
                        
                        // Botón para ver reporte en tabla
                        ToolButton {
                            id: viewReportButton
                            implicitWidth: 64
                            implicitHeight: 64
                            
                            ToolTip.visible: hovered
                            ToolTip.text: qsTr("Ver Reporte del Día")
                            ToolTip.delay: 500
                            
                            contentItem: Label {
                                text: "\uE8F3"  // Table icon
                                font.family: "Segoe MDL2 Assets"
                                font.pixelSize: 28
                                color: Material.theme === Material.Dark 
                                    ? Material.foreground 
                                    : Material.primary
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            
                            background: Rectangle {
                                radius: 6
                                color: parent.down 
                                    ? (Material.theme === Material.Dark 
                                        ? Qt.lighter(Material.background, 1.4) 
                                        : Material.color(Material.Grey, Material.Shade300))
                                    : parent.hovered 
                                        ? (Material.theme === Material.Dark 
                                            ? Qt.lighter(Material.background, 1.2) 
                                            : Material.color(Material.Grey, Material.Shade200))
                                        : (Material.theme === Material.Dark 
                                            ? Qt.lighter(Material.background, 1.1) 
                                            : Material.background)
                                border.width: 1
                                border.color: parent.hovered || parent.down
                                    ? Material.primary 
                                    : Material.frameColor
                                
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on border.color { ColorAnimation { duration: 150 } }
                            }
                            
                            onClicked: {
                                var report = viewModel.getDailyReport()
                                closingReportDialog.reportData = JSON.parse(report)
                                closingReportDialog.open()
                            }
                        }
                        
                        // Botón para exportar a Excel
                        ToolButton {
                            id: exportExcelButton
                            implicitWidth: 64
                            implicitHeight: 64
                            
                            ToolTip.visible: hovered
                            ToolTip.text: qsTr("Exportar a Excel")
                            ToolTip.delay: 500
                            
                            contentItem: Label {
                                text: "\uE9F9"  // Excel/Table icon
                                font.family: "Segoe MDL2 Assets"
                                font.pixelSize: 28
                                color: Material.theme === Material.Dark 
                                    ? Material.foreground 
                                    : Material.color(Material.Green)
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            
                            background: Rectangle {
                                radius: 6
                                color: parent.down 
                                    ? (Material.theme === Material.Dark 
                                        ? Qt.lighter(Material.background, 1.4) 
                                        : Material.color(Material.Grey, Material.Shade300))
                                    : parent.hovered 
                                        ? (Material.theme === Material.Dark 
                                            ? Qt.lighter(Material.background, 1.2) 
                                            : Material.color(Material.Grey, Material.Shade200))
                                        : (Material.theme === Material.Dark 
                                            ? Qt.lighter(Material.background, 1.1) 
                                            : Material.background)
                                border.width: 1
                                border.color: parent.hovered || parent.down
                                    ? Material.color(Material.Green)
                                    : Material.frameColor
                                
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on border.color { ColorAnimation { duration: 150 } }
                            }
                            
                            onClicked: {
                                viewModel.generateDailyReportExcel()
                            }
                        }
                        
                        // Botón para exportar a PDF
                        ToolButton {
                            id: exportPdfButton
                            implicitWidth: 64
                            implicitHeight: 64
                            
                            ToolTip.visible: hovered
                            ToolTip.text: qsTr("Exportar a PDF")
                            ToolTip.delay: 500
                            
                            contentItem: Label {
                                text: "\uE8E0"  // PDF/Download icon
                                font.family: "Segoe MDL2 Assets"
                                font.pixelSize: 28
                                color: Material.theme === Material.Dark 
                                    ? Material.foreground 
                                    : Material.color(Material.Red)
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            
                            background: Rectangle {
                                radius: 6
                                color: parent.down 
                                    ? (Material.theme === Material.Dark 
                                        ? Qt.lighter(Material.background, 1.4) 
                                        : Material.color(Material.Grey, Material.Shade300))
                                    : parent.hovered 
                                        ? (Material.theme === Material.Dark 
                                            ? Qt.lighter(Material.background, 1.2) 
                                            : Material.color(Material.Grey, Material.Shade200))
                                        : (Material.theme === Material.Dark 
                                            ? Qt.lighter(Material.background, 1.1) 
                                            : Material.background)
                                border.width: 1
                                border.color: parent.hovered || parent.down
                                    ? Material.color(Material.Red)
                                    : Material.frameColor
                                
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on border.color { ColorAnimation { duration: 150 } }
                            }
                            
                            onClicked: {
                                viewModel.generateDailyReportPDF()
                            }
                        }
                        
                        // Espaciador derecho para centrar
                        Item {
                            Layout.fillWidth: true
                        }
                    }
                }
            }
        }
    }
    
    // Diálogo de confirmación de cierre de día
    Dialog {
        id: closeDayConfirmDialog
        title: "\uE7BA  " + qsTr("Confirmar Cierre de Día")
        font.family: "Segoe MDL2 Assets"
        modal: true
        anchors.centerIn: parent
        width: Math.min(400, root.width * 0.9)
        
        standardButtons: Dialog.Ok | Dialog.Cancel
        
        ColumnLayout {
            anchors.fill: parent
            spacing: 12
            
            Label {
                text: qsTr("¿Está seguro de cerrar el día?")
                font.weight: Font.Bold
                Layout.fillWidth: true
            }
            
            Label {
                text: qsTr("Se generará un reporte final con todas las ventas del día.")
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                opacity: 0.8
            }
            
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Material.frameColor
            }
            
            Label {
                text: qsTr("Cajero: ") + viewModel.currentCashier
                font.weight: Font.Medium
            }
            
            Label {
                text: qsTr("Ventas del día: S/") + viewModel.todaySales.toFixed(2)
                color: Material.color(Material.Green)
            }
            
            Label {
                text: qsTr("Transacciones: ") + viewModel.todayTransactions
            }
        }
        
        onAccepted: {
            viewModel.closeDayShift()
        }
    }
    
    // Diálogo de reporte de cierre
    Dialog {
        id: closingReportDialog
        title: qsTr("Reporte de Cierre de Día")
        font.family: "Segoe MDL2 Assets"
        modal: true
        anchors.centerIn: parent
        width: Math.min(700, root.width * 0.95)
        height: Math.min(600, root.height * 0.9)
        
        property var reportData: ({})
        
        standardButtons: Dialog.Close
        
        ScrollView {
            anchors.fill: parent
            clip: true
            
            ColumnLayout {
                width: closingReportDialog.availableWidth
                spacing: 16
                
                // Encabezado
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 80
                    radius: 8
                    color: Material.primary
                    
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        
                        Label {
                            text: qsTr("REPORTE DE CIERRE")
                            font.pixelSize: 20
                            font.weight: Font.Bold
                            color: Material.theme === Material.Dark ? "#000000" : "#FFFFFF"
                            Layout.alignment: Qt.AlignHCenter
                        }
                        
                        Label {
                            text: closingReportDialog.reportData.date || ""
                            font.pixelSize: 14
                            color: Material.theme === Material.Dark ? "#000000" : "#FFFFFF"
                            opacity: 0.9
                            Layout.alignment: Qt.AlignHCenter
                        }
                        
                        Label {
                            text: qsTr("Cajero: ") + (closingReportDialog.reportData.cashier || "")
                            font.pixelSize: 12
                            color: Material.theme === Material.Dark ? "#000000" : "#FFFFFF"
                            opacity: 0.8
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }
                
                // Estadísticas generales
                GroupBox {
                    Layout.fillWidth: true
                    title: qsTr("Estadísticas Generales")
                    
                    GridLayout {
                        anchors.fill: parent
                        columns: 2
                        rowSpacing: 8
                        columnSpacing: 12
                        
                        Label { text: qsTr("Total Ventas:"); font.weight: Font.Medium }
                        Label { 
                            text: "S/" + (closingReportDialog.reportData.generalStats?.totalSales?.toFixed(2) || "0.00")
                            color: Material.color(Material.Green)
                            font.weight: Font.Bold
                            font.pixelSize: 18
                        }
                        
                        Label { text: qsTr("Total Transacciones:"); font.weight: Font.Medium }
                        Label { text: closingReportDialog.reportData.generalStats?.totalTransactions || "0" }
                        
                        Label { text: qsTr("Ticket Promedio:"); font.weight: Font.Medium }
                        Label { text: "S/" + (closingReportDialog.reportData.generalStats?.averageTicket?.toFixed(2) || "0.00") }
                    }
                }
                
                // Ventas por tipo de comprobante
                GroupBox {
                    Layout.fillWidth: true
                    title: qsTr("Por Tipo de Comprobante")
                    
                    GridLayout {
                        anchors.fill: parent
                        columns: 3
                        rowSpacing: 8
                        columnSpacing: 12
                        
                        Label { text: qsTr("Tipo"); font.weight: Font.Bold }
                        Label { text: qsTr("Cantidad"); font.weight: Font.Bold; Layout.alignment: Qt.AlignRight }
                        Label { text: qsTr("Total"); font.weight: Font.Bold; Layout.alignment: Qt.AlignRight }
                        
                        // Boletas
                        Label { 
                            text: "\uE8A5  " + qsTr("Boletas")
                            font.family: "Segoe MDL2 Assets"
                        }
                        Label { 
                            text: closingReportDialog.reportData.byVoucherType?.boletas?.count || "0"
                            Layout.alignment: Qt.AlignRight
                        }
                        Label { 
                            text: "S/" + (closingReportDialog.reportData.byVoucherType?.boletas?.total?.toFixed(2) || "0.00")
                            Layout.alignment: Qt.AlignRight
                            color: Material.color(Material.Blue)
                        }
                        
                        // Facturas
                        Label { 
                            text: "\uE8A5  " + qsTr("Facturas")
                            font.family: "Segoe MDL2 Assets"
                        }
                        Label { 
                            text: closingReportDialog.reportData.byVoucherType?.facturas?.count || "0"
                            Layout.alignment: Qt.AlignRight
                        }
                        Label { 
                            text: "S/" + (closingReportDialog.reportData.byVoucherType?.facturas?.total?.toFixed(2) || "0.00")
                            Layout.alignment: Qt.AlignRight
                            color: Material.color(Material.Purple)
                        }
                        
                        // Tickets
                        Label { 
                            text: "\uE8A5  " + qsTr("Tickets")
                            font.family: "Segoe MDL2 Assets"
                        }
                        Label { 
                            text: closingReportDialog.reportData.byVoucherType?.tickets?.count || "0"
                            Layout.alignment: Qt.AlignRight
                        }
                        Label { 
                            text: "S/" + (closingReportDialog.reportData.byVoucherType?.tickets?.total?.toFixed(2) || "0.00")
                            Layout.alignment: Qt.AlignRight
                            color: Material.color(Material.Green)
                        }
                    }
                }
                
                // Productos más vendidos
                GroupBox {
                    Layout.fillWidth: true
                    title: "\uE734  " + qsTr("Productos Más Vendidos")
                    font.family: "Segoe MDL2 Assets"
                    
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 8
                        
                        Repeater {
                            model: closingReportDialog.reportData.topProducts || []
                            
                            delegate: Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                radius: 4
                                color: Material.theme === Material.Dark ?
                                    Qt.lighter(Material.background, 1.15) :
                                    Material.background
                                border.width: 1
                                border.color: Material.frameColor
                                
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 12
                                    
                                    Label {
                                        text: (index + 1) + "."
                                        font.weight: Font.Bold
                                        color: Material.primary
                                        Layout.preferredWidth: 20
                                    }
                                    
                                    Label {
                                        text: modelData.name || ""
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }
                                    
                                    Label {
                                        text: qsTr("Vendidos: ") + (modelData.quantity || 0)
                                        font.weight: Font.Medium
                                        color: Material.color(Material.Orange)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Tabla de ventas del día
                GroupBox {
                    Layout.fillWidth: true
                    title: "\uE8A5  " + qsTr("Ventas del Día")
                    font.family: "Segoe MDL2 Assets"
                    
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 8
                        
                        // Encabezado de tabla
                        Rectangle {
                            Layout.fillWidth: true
                            height: 40
                            color: Material.primary
                            radius: 4
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 8
                                
                                Label {
                                    text: qsTr("Factura")
                                    font.weight: Font.Bold
                                    color: "white"
                                    Layout.preferredWidth: 100
                                }
                                
                                Label {
                                    text: qsTr("Hora")
                                    font.weight: Font.Bold
                                    color: "white"
                                    Layout.preferredWidth: 80
                                }
                                
                                Label {
                                    text: qsTr("Tipo")
                                    font.weight: Font.Bold
                                    color: "white"
                                    Layout.preferredWidth: 70
                                }
                                
                                Label {
                                    text: qsTr("Items")
                                    font.weight: Font.Bold
                                    color: "white"
                                    Layout.preferredWidth: 50
                                    horizontalAlignment: Text.AlignHCenter
                                }
                                
                                Label {
                                    text: qsTr("Total")
                                    font.weight: Font.Bold
                                    color: "white"
                                    Layout.preferredWidth: 90
                                    horizontalAlignment: Text.AlignRight
                                }
                                
                                Label {
                                    text: qsTr("Detalles")
                                    font.weight: Font.Bold
                                    color: "white"
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }
                        }
                        
                        // Lista de ventas
                        ScrollView {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 300
                            clip: true
                            
                            ListView {
                                model: closingReportDialog.reportData.sales || []
                                spacing: 4
                                
                                delegate: Rectangle {
                                    width: ListView.view.width
                                    height: 50
                                    radius: 4
                                    color: Material.theme === Material.Dark ?
                                        Qt.lighter(Material.background, 1.15) :
                                        Material.background
                                    border.width: 1
                                    border.color: Material.frameColor
                                    
                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        spacing: 8
                                        
                                        Label {
                                            text: modelData.invoiceNumber || ""
                                            Layout.preferredWidth: 100
                                            elide: Text.ElideRight
                                        }
                                        
                                        Label {
                                            text: {
                                                var dateStr = modelData.createdAt || ""
                                                var parts = dateStr.split(" ")
                                                return parts.length > 1 ? parts[1] : ""
                                            }
                                            Layout.preferredWidth: 80
                                            opacity: 0.7
                                        }
                                        
                                        Label {
                                            text: modelData.voucherType || ""
                                            Layout.preferredWidth: 70
                                            font.pixelSize: 11
                                        }
                                        
                                        Label {
                                            text: modelData.itemCount || 0
                                            Layout.preferredWidth: 50
                                            horizontalAlignment: Text.AlignHCenter
                                            font.weight: Font.Medium
                                        }
                                        
                                        Label {
                                            text: "S/ " + (modelData.total || 0).toFixed(2)
                                            Layout.preferredWidth: 90
                                            horizontalAlignment: Text.AlignRight
                                            color: Material.color(Material.Green)
                                            font.weight: Font.Bold
                                        }
                                        
                                        Button {
                                            text: "\uE8A5  Ver"
                                            font.family: "Segoe MDL2 Assets"
                                            flat: true
                                            Layout.fillWidth: true
                                            Material.foreground: Material.accent
                                            
                                            onClicked: {
                                                saleDetailsDialog.saleData = modelData
                                                saleDetailsDialog.open()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        function generatePDF() {
            // Usar el ViewModel para generar el PDF del reporte
            if (viewModel && reportData) {
                viewModel.generateDailyReportPDF()
            }
        }
    }
    
    // Diálogo de detalles de venta
    Dialog {
        id: saleDetailsDialog
        title: qsTr("Detalles de Venta - %1").arg(saleData.invoiceNumber || "")
        modal: true
        anchors.centerIn: parent
        
        property var saleData: ({})
        
        width: Math.min(500, root.width * 0.9)
        height: Math.min(root.height * 0.9, 700)
        
        standardButtons: Dialog.Close
        
        ColumnLayout {
            anchors.fill: parent
            spacing: 12
            
            // Información de la venta
            Rectangle {
                Layout.fillWidth: true
                height: 80
                radius: 6
                color: Material.theme === Material.Dark ?
                    Qt.lighter(Material.background, 1.2) :
                    Material.color(Material.Grey, Material.Shade100)
                
                GridLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    columns: 2
                    rowSpacing: 6
                    columnSpacing: 12
                    
                    Label { 
                        text: qsTr("Tipo de Comprobante:")
                        font.weight: Font.Medium
                    }
                    Label { 
                        text: saleDetailsDialog.saleData.voucherType || ""
                        Layout.fillWidth: true
                    }
                    
                    Label { 
                        text: qsTr("Tipo de Pago:")
                        font.weight: Font.Medium
                    }
                    Label { text: saleDetailsDialog.saleData.paymentType || "" }
                    
                    Label { 
                        text: qsTr("Fecha:")
                        font.weight: Font.Medium
                    }
                    Label { text: saleDetailsDialog.saleData.createdAt || "" }
                }
            }
            
            // Título de productos
            Label {
                text: qsTr("Productos Vendidos:")
                font.weight: Font.Bold
                font.pixelSize: 14
            }
            
            // Lista de productos
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                
                ColumnLayout {
                    width: saleDetailsDialog.availableWidth
                    spacing: 6
                    
                    Repeater {
                        model: saleDetailsDialog.saleData.items || []
                        
                        delegate: Rectangle {
                            Layout.fillWidth: true
                            height: 60
                            radius: 6
                            color: Material.theme === Material.Dark ?
                                Qt.lighter(Material.background, 1.15) :
                                Material.background
                            border.width: 1
                            border.color: Material.frameColor
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 12
                                
                                // Cantidad
                                Rectangle {
                                    Layout.preferredWidth: 50
                                    Layout.preferredHeight: 40
                                    radius: 6
                                    color: Material.accent
                                    
                                    ColumnLayout {
                                        anchors.centerIn: parent
                                        spacing: 0
                                        
                                        Label {
                                            text: modelData.quantity || 0
                                            font.weight: Font.Bold
                                            font.pixelSize: 16
                                            color: "white"
                                            Layout.alignment: Qt.AlignHCenter
                                        }
                                        
                                        Label {
                                            text: "cant."
                                            font.pixelSize: 9
                                            color: "white"
                                            opacity: 0.9
                                            Layout.alignment: Qt.AlignHCenter
                                        }
                                    }
                                }
                                
                                // Nombre del producto
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    
                                    Label {
                                        text: modelData.productName || ""
                                        font.weight: Font.Medium
                                        font.pixelSize: 13
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }
                                    
                                    Label {
                                        text: "S/ " + (modelData.unitPrice || 0).toFixed(2) + " c/u"
                                        font.pixelSize: 11
                                        opacity: 0.7
                                    }
                                }
                                
                                // Subtotal
                                Label {
                                    text: "S/ " + (modelData.subtotal || 0).toFixed(2)
                                    font.weight: Font.Bold
                                    font.pixelSize: 16
                                    color: Material.color(Material.Green)
                                    Layout.preferredWidth: 100
                                    horizontalAlignment: Text.AlignRight
                                }
                            }
                        }
                    }
                }
            }
            
            // Total
            Rectangle {
                Layout.fillWidth: true
                height: 50
                radius: 6
                color: Material.color(Material.Green)
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    
                    Label {
                        text: qsTr("TOTAL:")
                        font.weight: Font.Bold
                        font.pixelSize: 16
                        color: "white"
                        Layout.fillWidth: true
                    }
                    
                    Label {
                        text: "S/ " + (saleDetailsDialog.saleData.total || 0).toFixed(2)
                        font.weight: Font.Bold
                        font.pixelSize: 20
                        color: "white"
                    }
                }
            }
        }
    }

    // Componente de tarjeta estadística
    component StatCard: Rectangle {
        property string title: ""
        property string value: ""
        property string subtitle: ""
        property string icon: ""
        property color accentColor: Material.primary
        property bool warning: false

        radius: root.width > 800 ? 16 : 12
        color: Material.theme === Material.Dark ?
            Qt.lighter(Material.background, 1.15) :
            Material.background
        border.width: 1
        border.color: warning ? Material.color(Material.Orange) : Material.frameColor
        
        layer.enabled: true
        // DropShadow requiere Qt5Compat - comentado por ahora
        // layer.effect: DropShadow {
        //     horizontalOffset: 0
        //     verticalOffset: 2
        //     radius: 8
        //     samples: 17
        //     color: "#1A000000"
        // }

        RowLayout {
            anchors.fill: parent
            anchors.margins: root.width > 600 ? 20 : 12
            spacing: root.width > 600 ? 16 : 10

            Rectangle {
                Layout.preferredWidth: root.width > 600 ? 64 : 48
                Layout.preferredHeight: root.width > 600 ? 64 : 48
                radius: root.width > 600 ? 16 : 12
                color: Qt.rgba(parent.parent.accentColor.r, parent.parent.accentColor.g, parent.parent.accentColor.b, 0.12)

                Label {
                    anchors.centerIn: parent
                    text: parent.parent.parent.icon
                    font.pixelSize: root.width > 600 ? 32 : 24
                    color: parent.parent.parent.accentColor
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: root.width > 600 ? 6 : 4

                Label {
                    text: parent.parent.parent.title
                    font.pixelSize: root.width > 600 ? 13 : 11
                    font.weight: Font.Medium
                    opacity: 0.6
                    color: Material.foreground
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Label {
                    text: parent.parent.parent.value
                    font.pixelSize: root.width > 800 ? 28 : (root.width > 600 ? 24 : 20)
                    font.weight: Font.Bold
                    color: Material.foreground
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Label {
                    text: parent.parent.parent.subtitle
                    font.pixelSize: root.width > 600 ? 12 : 10
                    opacity: 0.5
                    color: Material.foreground
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }
        }
    }

    // Botón de refrescar
    RoundButton {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 20
        width: 56
        height: 56
        icon.name: "refresh"
        text: "↻"
        font.pixelSize: 24
        Material.background: ApplicationWindow.window?.currentColors?.primary ?? Material.primary
        contentItem: Label {
            text: parent.text
            font: parent.font
            color: Material.theme === Material.Dark ? "#000000" : "#FFFFFF"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        
        onClicked: viewModel.refresh()
    }
}
