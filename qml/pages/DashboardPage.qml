import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import SistemaInventario

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
        contentWidth: availableWidth

        ColumnLayout {
            width: parent.width
            spacing: 20
            padding: 20

            // Título
            Label {
                text: qsTr("Panel de Control")
                font.pixelSize: 32
                font.weight: Font.Bold
                color: Material.foreground
                Layout.bottomMargin: 8
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
                            text: "👤"
                            font.pixelSize: 20
                        }
                        
                        ComboBox {
                            id: cashierComboBox
                            Layout.fillWidth: true
                            model: viewModel.availableCashiers
                            currentIndex: viewModel.availableCashiers.indexOf(viewModel.currentCashier)
                            onActivated: {
                                viewModel.currentCashier = currentText
                            }
                        }
                        
                        Label {
                            text: qsTr("Ventas: S/") + viewModel.todaySalesByCashier.toFixed(2) + 
                                  qsTr(" | Transacciones: ") + viewModel.todayTransactionsByCashier
                            font.weight: Font.Medium
                            color: Material.primary
                        }
                    }
                }

                // Ventas del día
                StatCard {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 120
                    title: qsTr("Ventas del Día")
                    value: "S/" + viewModel.todaySales.toFixed(2)
                    subtitle: viewModel.todayTransactions + " transacciones"
                    icon: "󰄫"
                    accentColor: Material.color(Material.Green)
                }

                // Ventas del mes
                StatCard {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 120
                    title: qsTr("Ventas del Mes")
                    value: "S/" + viewModel.monthSales.toFixed(2)
                    subtitle: "Ticket promedio: S/" + viewModel.averageTicket.toFixed(2)
                    icon: "󰄬"
                    accentColor: Material.color(Material.Blue)
                }

                // Productos totales
                StatCard {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 120
                    title: qsTr("Productos")
                    value: viewModel.totalProducts.toString()
                    subtitle: qsTr("Total en catálogo")
                    icon: "󰏓"
                    accentColor: Material.color(Material.Purple)
                }

                // Stock bajo
                StatCard {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 120
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

                    Button {
                        Layout.fillWidth: true
                        text: "\uE8C8  " + qsTr("Nueva Venta")
                        font.family: "Segoe MDL2 Assets"
                        Material.background: Material.primary
                        Material.foreground: "white"
                        font.weight: Font.Medium
                        onClicked: {
                            // Navegar a nueva venta
                        }
                    }

                    Button {
                        Layout.fillWidth: true
                        text: "\uE710  " + qsTr("Nuevo Producto")
                        font.family: "Segoe MDL2 Assets"
                        Material.background: Material.theme === Material.Dark ?
                            Qt.rgba(Material.primary.r, Material.primary.g, Material.primary.b, 0.3) :
                            Qt.rgba(Material.primary.r, Material.primary.g, Material.primary.b, 0.1)
                        Material.foreground: Material.primary
                        font.weight: Font.Medium
                        onClicked: {
                            // Navegar a nuevo producto
                        }
                    }

                    Button {
                        Layout.fillWidth: true
                        text: "\uE898  " + qsTr("Importar Excel")
                        font.family: "Segoe MDL2 Assets"
                        Material.background: Material.theme === Material.Dark ?
                            Qt.rgba(Material.primary.r, Material.primary.g, Material.primary.b, 0.3) :
                            Qt.rgba(Material.primary.r, Material.primary.g, Material.primary.b, 0.1)
                        Material.foreground: Material.primary
                        font.weight: Font.Medium
                        onClicked: {
                            // Navegar a importación
                        }
                    }

                    Button {
                        Layout.fillWidth: true
                        text: "\uE9D9  " + qsTr("Ver Reportes")
                        font.family: "Segoe MDL2 Assets"
                        Material.background: Material.theme === Material.Dark ?
                            Qt.rgba(Material.primary.r, Material.primary.g, Material.primary.b, 0.3) :
                            Qt.rgba(Material.primary.r, Material.primary.g, Material.primary.b, 0.1)
                        Material.foreground: Material.primary
                        font.weight: Font.Medium
                        onClicked: {
                            // Navegar a reportes
                        }
                    }
                }
            }

            // Productos con stock bajo
            GroupBox {
                Layout.fillWidth: true
                title: qsTr("Alertas de Stock Bajo")
                visible: viewModel.lowStockProducts > 0

                Label {
                    text: qsTr("Hay %1 productos con stock bajo. Revisar inventario.").arg(viewModel.lowStockProducts)
                    wrapMode: Text.WordWrap
                    color: Material.color(Material.Orange)
                }
            }
            
            // Cierre de día
            GroupBox {
                Layout.fillWidth: true
                title: qsTr("📊 Cierre de Día")
                
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 12
                    
                    Label {
                        text: qsTr("Generar reporte de cierre del día actual")
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                    
                    RowLayout {
                        spacing: 12
                        
                        Button {
                            text: qsTr("📋 Ver Reporte del Día")
                            Material.background: Material.theme === Material.Dark ?
                                Qt.rgba(Material.primary.r, Material.primary.g, Material.primary.b, 0.3) :
                                Qt.rgba(Material.primary.r, Material.primary.g, Material.primary.b, 0.1)
                            Material.foreground: Material.primary
                            onClicked: {
                                var report = viewModel.getDailyReport()
                                closingReportDialog.reportData = JSON.parse(report)
                                closingReportDialog.open()
                            }
                        }
                        
                        Button {
                            text: qsTr("🔒 Cerrar Día")
                            Material.background: Material.color(Material.Green)
                            Material.foreground: "white"
                            font.weight: Font.Medium
                            onClicked: {
                                closeDayConfirmDialog.open()
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Diálogo de confirmación de cierre de día
    Dialog {
        id: closeDayConfirmDialog
        title: qsTr("⚠️ Confirmar Cierre de Día")
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
        title: qsTr("📊 Reporte de Cierre de Día")
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
                            color: "white"
                            Layout.alignment: Qt.AlignHCenter
                        }
                        
                        Label {
                            text: closingReportDialog.reportData.date || ""
                            font.pixelSize: 14
                            color: "white"
                            opacity: 0.9
                            Layout.alignment: Qt.AlignHCenter
                        }
                        
                        Label {
                            text: qsTr("Cajero: ") + (closingReportDialog.reportData.cashier || "")
                            font.pixelSize: 12
                            color: "white"
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
                        Label { text: qsTr("🧾 Boletas") }
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
                        Label { text: qsTr("📄 Facturas") }
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
                        Label { text: qsTr("🎫 Tickets") }
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
                    title: qsTr("🏆 Productos Más Vendidos")
                    
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

        radius: 16
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
            anchors.margins: 20
            spacing: 16

            Rectangle {
                Layout.preferredWidth: 64
                Layout.preferredHeight: 64
                radius: 16
                color: Qt.rgba(parent.parent.accentColor.r, parent.parent.accentColor.g, parent.parent.accentColor.b, 0.12)

                Label {
                    anchors.centerIn: parent
                    text: parent.parent.parent.icon
                    font.pixelSize: 32
                    color: parent.parent.parent.accentColor
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                Label {
                    text: parent.parent.parent.title
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    opacity: 0.6
                    color: Material.foreground
                }

                Label {
                    text: parent.parent.parent.value
                    font.pixelSize: 28
                    font.weight: Font.Bold
                    color: Material.foreground
                }

                Label {
                    text: parent.parent.parent.subtitle
                    font.pixelSize: 12
                    opacity: 0.5
                    color: Material.foreground
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
        Material.background: Material.primary
        Material.foreground: "white"
        
        onClicked: viewModel.refresh()
    }
}
