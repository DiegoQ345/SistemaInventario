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
        Component.onCompleted: refresh()
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
                color: "#1D1B20"
                Layout.bottomMargin: 8
            }

            // Tarjetas de estadísticas
            GridLayout {
                Layout.fillWidth: true
                columns: root.width > 1000 ? 4 : 2
                rowSpacing: 16
                columnSpacing: 16

                // Ventas del día
                StatCard {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 120
                    title: qsTr("Ventas del Día")
                    value: "$" + viewModel.todaySales.toFixed(2)
                    subtitle: viewModel.todayTransactions + " transacciones"
                    icon: "󰄫"
                    accentColor: Material.color(Material.Green)
                }

                // Ventas del mes
                StatCard {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 120
                    title: qsTr("Ventas del Mes")
                    value: "$" + viewModel.monthSales.toFixed(2)
                    subtitle: "Ticket promedio: $" + viewModel.averageTicket.toFixed(2)
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
                        Material.background: "#6750A4"
                        Material.foreground: "#FFFFFF"
                        font.weight: Font.Medium
                        onClicked: {
                            // Navegar a nueva venta
                        }
                    }

                    Button {
                        Layout.fillWidth: true
                        text: "\uE710  " + qsTr("Nuevo Producto")
                        font.family: "Segoe MDL2 Assets"
                        Material.background: "#E8DEF8"
                        Material.foreground: "#6750A4"
                        font.weight: Font.Medium
                        onClicked: {
                            // Navegar a nuevo producto
                        }
                    }

                    Button {
                        Layout.fillWidth: true
                        text: "\uE898  " + qsTr("Importar Excel")
                        font.family: "Segoe MDL2 Assets"
                        Material.background: "#E8DEF8"
                        Material.foreground: "#6750A4"
                        font.weight: Font.Medium
                        onClicked: {
                            // Navegar a importación
                        }
                    }

                    Button {
                        Layout.fillWidth: true
                        text: "\uE9D9  " + qsTr("Ver Reportes")
                        font.family: "Segoe MDL2 Assets"
                        Material.background: "#E8DEF8"
                        Material.foreground: "#6750A4"
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
        }
    }

    // Componente de tarjeta estadística
    component StatCard: Rectangle {
        property string title: ""
        property string value: ""
        property string subtitle: ""
        property string icon: ""
        property color accentColor: Material.accentColor
        property bool warning: false

        radius: 16
        color: "#FFFFFF"
        border.width: 1
        border.color: warning ? "#F9A825" : "#E7E0EC"
        
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
                    color: "#1D1B20"
                }

                Label {
                    text: parent.parent.parent.value
                    font.pixelSize: 28
                    font.weight: Font.Bold
                    color: "#1D1B20"
                }

                Label {
                    text: parent.parent.parent.subtitle
                    font.pixelSize: 12
                    opacity: 0.5
                    color: "#49454F"
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
        Material.background: Material.accentColor
        Material.foreground: "white"
        
        onClicked: viewModel.refresh()
    }
}
