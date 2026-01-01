import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import SistemaInventario 1.0

Page {
    id: root
    title: qsTr("Reportes")

    ReportsViewModel {
        id: viewModel
        Component.onCompleted: setQuickPeriod("today")
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        // Encabezado con título y controles de período
        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Label {
                    text: qsTr("Reportes y Análisis")
                    font.pixelSize: 32
                    font.weight: Font.Bold
                    color: Material.foreground
                }

                Label {
                    text: qsTr("Analiza el rendimiento de tus ventas")
                    font.pixelSize: 16
                    opacity: 0.7
                    color: Material.foreground
                }
            }

            // Botones de período rápido
            RowLayout {
                spacing: 8

                Button {
                    text: qsTr("Hoy")
                    flat: true
                    onClicked: viewModel.setQuickPeriod("today")
                    Material.background: viewModel.periodType === "daily" ? Material.primary : "transparent"
                    Material.foreground: viewModel.periodType === "daily" ? "white" : Material.primary
                }

                Button {
                    text: qsTr("Esta Semana")
                    flat: true
                    onClicked: viewModel.setQuickPeriod("week")
                    Material.background: viewModel.periodType === "weekly" ? Material.primary : "transparent"
                    Material.foreground: viewModel.periodType === "weekly" ? "white" : Material.primary
                }

                Button {
                    text: qsTr("Este Mes")
                    flat: true
                    onClicked: viewModel.setQuickPeriod("month")
                    Material.background: viewModel.periodType === "monthly" ? Material.primary : "transparent"
                    Material.foreground: viewModel.periodType === "monthly" ? "white" : Material.primary
                }

                Button {
                    text: qsTr("Este Año")
                    flat: true
                    onClicked: viewModel.setQuickPeriod("year")
                    Material.background: viewModel.periodType === "yearly" ? Material.primary : "transparent"
                    Material.foreground: viewModel.periodType === "yearly" ? "white" : Material.primary
                }
            }
        }

        // Filtros de fecha personalizada
        Rectangle {
            Layout.fillWidth: true
            height: 80
            color: Material.theme === Material.Dark ?
                Qt.lighter(Material.background, 1.2) :
                Material.color(Material.Grey, Material.Shade100)
            radius: 8
            border.width: 1
            border.color: Material.theme === Material.Dark ?
                Material.color(Material.Grey, Material.Shade700) :
                Material.color(Material.Grey, Material.Shade300)

            RowLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 16

                Label {
                    text: "\uE787"  // Calendar icon
                    font.family: "Segoe MDL2 Assets"
                    font.pixelSize: 24
                    color: Material.primary
                }

                ColumnLayout {
                    spacing: 4

                    Label {
                        text: qsTr("Desde:")
                        font.pixelSize: 12
                        opacity: 0.7
                    }

                    Button {
                        id: startDateButton
                        text: Qt.formatDate(viewModel.startDate, "dd/MM/yyyy")
                        Layout.preferredWidth: 140
                        Layout.preferredHeight: 40
                        icon.source: "\uE787"
                        font.family: "Segoe MDL2 Assets"
                        
                        onClicked: startDatePopup.open()
                        
                        Popup {
                            id: startDatePopup
                            x: {
                                var buttonX = startDateButton.mapToItem(root, 0, 0).x
                                var availableRight = root.width - buttonX
                                if (availableRight >= width) {
                                    return 0  // Alineado a la izquierda del botón
                                } else if (buttonX >= width) {
                                    return startDateButton.width - width  // Alineado a la derecha del botón
                                } else {
                                    return -(buttonX + width - root.width + 20)  // Ajustado al borde derecho con margen
                                }
                            }
                            y: parent.height
                            width: 320
                            height: 380
                            modal: true
                            focus: true
                            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
                            
                            property int currentMonth: viewModel.startDate.getMonth()
                            property int currentYear: viewModel.startDate.getFullYear()
                            
                            background: Rectangle {
                                color: Material.theme === Material.Dark ?
                                    Qt.lighter(Material.background, 1.2) :
                                    "white"
                                radius: 8
                                border.width: 1
                                border.color: Material.primary
                            }
                            
                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 8
                                
                                // Navegación mes/año
                                RowLayout {
                                    Layout.fillWidth: true
                                    
                                    Button {
                                        text: "\uE76B"  // Previous
                                        font.family: "Segoe MDL2 Assets"
                                        flat: true
                                        onClicked: {
                                            if (startDatePopup.currentMonth === 0) {
                                                startDatePopup.currentMonth = 11
                                                startDatePopup.currentYear--
                                            } else {
                                                startDatePopup.currentMonth--
                                            }
                                        }
                                    }
                                    
                                    Label {
                                        Layout.fillWidth: true
                                        text: Qt.locale().monthName(startDatePopup.currentMonth) + " " + startDatePopup.currentYear
                                        horizontalAlignment: Text.AlignHCenter
                                        font.weight: Font.Bold
                                        font.pixelSize: 14
                                    }
                                    
                                    Button {
                                        text: "\uE76C"  // Next
                                        font.family: "Segoe MDL2 Assets"
                                        flat: true
                                        onClicked: {
                                            if (startDatePopup.currentMonth === 11) {
                                                startDatePopup.currentMonth = 0
                                                startDatePopup.currentYear++
                                            } else {
                                                startDatePopup.currentMonth++
                                            }
                                        }
                                    }
                                }
                                
                                // Días de la semana
                                GridLayout {
                                    Layout.fillWidth: true
                                    columns: 7
                                    rowSpacing: 4
                                    columnSpacing: 4
                                    
                                    Repeater {
                                        model: ["D", "L", "M", "M", "J", "V", "S"]
                                        Label {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 30
                                            text: modelData
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                            font.weight: Font.Bold
                                            font.pixelSize: 12
                                            opacity: 0.7
                                        }
                                    }
                                }
                                
                                // Calendario
                                GridLayout {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    columns: 7
                                    rowSpacing: 4
                                    columnSpacing: 4
                                    
                                    Repeater {
                                        model: 42  // 6 semanas máximo
                                        
                                        delegate: Rectangle {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            radius: width / 2
                                            
                                            property int dayNumber: {
                                                var firstDay = new Date(startDatePopup.currentYear, startDatePopup.currentMonth, 1).getDay()
                                                return index - firstDay + 1
                                            }
                                            
                                            property bool isCurrentMonth: {
                                                var daysInMonth = new Date(startDatePopup.currentYear, startDatePopup.currentMonth + 1, 0).getDate()
                                                return dayNumber >= 1 && dayNumber <= daysInMonth
                                            }
                                            
                                            property bool isSelected: {
                                                return isCurrentMonth &&
                                                       dayNumber === viewModel.startDate.getDate() &&
                                                       startDatePopup.currentMonth === viewModel.startDate.getMonth() &&
                                                       startDatePopup.currentYear === viewModel.startDate.getFullYear()
                                            }
                                            
                                            color: isSelected ? Material.primary : "transparent"
                                            
                                            Label {
                                                anchors.centerIn: parent
                                                text: parent.isCurrentMonth ? parent.dayNumber : ""
                                                color: parent.isSelected ? "white" : Material.foreground
                                                font.pixelSize: 12
                                                opacity: parent.isCurrentMonth ? 1 : 0
                                            }
                                            
                                            MouseArea {
                                                anchors.fill: parent
                                                enabled: parent.isCurrentMonth
                                                cursorShape: parent.isCurrentMonth ? Qt.PointingHandCursor : Qt.ArrowCursor
                                                
                                                onClicked: {
                                                    var newDate = new Date(startDatePopup.currentYear, startDatePopup.currentMonth, parent.dayNumber)
                                                    viewModel.setStartDate(newDate)
                                                    startDatePopup.close()
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                ColumnLayout {
                    spacing: 4

                    Label {
                        text: qsTr("Hasta:")
                        font.pixelSize: 12
                        opacity: 0.7
                    }

                    Button {
                        id: endDateButton
                        text: Qt.formatDate(viewModel.endDate, "dd/MM/yyyy")
                        Layout.preferredWidth: 140
                        Layout.preferredHeight: 40
                        icon.source: "\uE787"
                        font.family: "Segoe MDL2 Assets"
                        
                        onClicked: endDatePopup.open()
                        
                        Popup {
                            id: endDatePopup
                            x: {
                                var buttonX = endDateButton.mapToItem(root, 0, 0).x
                                var availableRight = root.width - buttonX
                                if (availableRight >= width) {
                                    return 0  // Alineado a la izquierda del botón
                                } else if (buttonX >= width) {
                                    return endDateButton.width - width  // Alineado a la derecha del botón
                                } else {
                                    return -(buttonX + width - root.width + 20)  // Ajustado al borde derecho con margen
                                }
                            }
                            y: parent.height
                            width: 320
                            height: 380
                            modal: true
                            focus: true
                            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
                            
                            property int currentMonth: viewModel.endDate.getMonth()
                            property int currentYear: viewModel.endDate.getFullYear()
                            
                            background: Rectangle {
                                color: Material.theme === Material.Dark ?
                                    Qt.lighter(Material.background, 1.2) :
                                    "white"
                                radius: 8
                                border.width: 1
                                border.color: Material.primary
                            }
                            
                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 8
                                
                                // Navegación mes/año
                                RowLayout {
                                    Layout.fillWidth: true
                                    
                                    Button {
                                        text: "\uE76B"  // Previous
                                        font.family: "Segoe MDL2 Assets"
                                        flat: true
                                        onClicked: {
                                            if (endDatePopup.currentMonth === 0) {
                                                endDatePopup.currentMonth = 11
                                                endDatePopup.currentYear--
                                            } else {
                                                endDatePopup.currentMonth--
                                            }
                                        }
                                    }
                                    
                                    Label {
                                        Layout.fillWidth: true
                                        text: Qt.locale().monthName(endDatePopup.currentMonth) + " " + endDatePopup.currentYear
                                        horizontalAlignment: Text.AlignHCenter
                                        font.weight: Font.Bold
                                        font.pixelSize: 14
                                    }
                                    
                                    Button {
                                        text: "\uE76C"  // Next
                                        font.family: "Segoe MDL2 Assets"
                                        flat: true
                                        onClicked: {
                                            if (endDatePopup.currentMonth === 11) {
                                                endDatePopup.currentMonth = 0
                                                endDatePopup.currentYear++
                                            } else {
                                                endDatePopup.currentMonth++
                                            }
                                        }
                                    }
                                }
                                
                                // Días de la semana
                                GridLayout {
                                    Layout.fillWidth: true
                                    columns: 7
                                    rowSpacing: 4
                                    columnSpacing: 4
                                    
                                    Repeater {
                                        model: ["D", "L", "M", "M", "J", "V", "S"]
                                        Label {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 30
                                            text: modelData
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                            font.weight: Font.Bold
                                            font.pixelSize: 12
                                            opacity: 0.7
                                        }
                                    }
                                }
                                
                                // Calendario
                                GridLayout {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    columns: 7
                                    rowSpacing: 4
                                    columnSpacing: 4
                                    
                                    Repeater {
                                        model: 42  // 6 semanas máximo
                                        
                                        delegate: Rectangle {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            radius: width / 2
                                            
                                            property int dayNumber: {
                                                var firstDay = new Date(endDatePopup.currentYear, endDatePopup.currentMonth, 1).getDay()
                                                return index - firstDay + 1
                                            }
                                            
                                            property bool isCurrentMonth: {
                                                var daysInMonth = new Date(endDatePopup.currentYear, endDatePopup.currentMonth + 1, 0).getDate()
                                                return dayNumber >= 1 && dayNumber <= daysInMonth
                                            }
                                            
                                            property bool isSelected: {
                                                return isCurrentMonth &&
                                                       dayNumber === viewModel.endDate.getDate() &&
                                                       endDatePopup.currentMonth === viewModel.endDate.getMonth() &&
                                                       endDatePopup.currentYear === viewModel.endDate.getFullYear()
                                            }
                                            
                                            color: isSelected ? Material.primary : "transparent"
                                            
                                            Label {
                                                anchors.centerIn: parent
                                                text: parent.isCurrentMonth ? parent.dayNumber : ""
                                                color: parent.isSelected ? "white" : Material.foreground
                                                font.pixelSize: 12
                                                opacity: parent.isCurrentMonth ? 1 : 0
                                            }
                                            
                                            MouseArea {
                                                anchors.fill: parent
                                                enabled: parent.isCurrentMonth
                                                cursorShape: parent.isCurrentMonth ? Qt.PointingHandCursor : Qt.ArrowCursor
                                                
                                                onClicked: {
                                                    var newDate = new Date(endDatePopup.currentYear, endDatePopup.currentMonth, parent.dayNumber)
                                                    viewModel.setEndDate(newDate)
                                                    endDatePopup.close()
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Button {
                    text: "\uE72C  " + qsTr("Actualizar")
                    font.family: "Segoe MDL2 Assets"
                    Material.background: Material.primary
                    Material.foreground: "white"
                    onClicked: viewModel.loadReport()
                }

                Item { Layout.fillWidth: true }

                Button {
                    text: "\uE8CA  " + qsTr("Exportar PDF")
                    font.family: "Segoe MDL2 Assets"
                    flat: true
                    Material.foreground: Material.primary
                    onClicked: {
                        // TODO: Abrir diálogo de guardar archivo
                        viewModel.exportToPdf("reporte.pdf")
                    }
                }
            }
        }

        // Tarjetas de resumen
        GridLayout {
            Layout.fillWidth: true
            columns: 4
            rowSpacing: 12
            columnSpacing: 12

            // Total de Ventas
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 120
                color: Material.theme === Material.Dark ?
                    Qt.lighter(Material.background, 1.2) :
                    "white"
                radius: 8
                border.width: 2
                border.color: Material.primary

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 8

                    Label {
                        text: "\uE7BF"  // Money icon
                        font.family: "Segoe MDL2 Assets"
                        font.pixelSize: 32
                        color: Material.primary
                    }

                    Label {
                        text: "S/" + (viewModel.summary.totalSales || 0).toFixed(2)
                        font.pixelSize: 24
                        font.weight: Font.Bold
                        color: Material.foreground
                    }

                    Label {
                        text: qsTr("Total Ventas")
                        font.pixelSize: 12
                        opacity: 0.7
                        color: Material.foreground
                    }
                }
            }

            // Total de Transacciones
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 120
                color: Material.theme === Material.Dark ?
                    Qt.lighter(Material.background, 1.2) :
                    "white"
                radius: 8
                border.width: 1
                border.color: Material.theme === Material.Dark ?
                    Material.color(Material.Grey, Material.Shade700) :
                    Material.color(Material.Grey, Material.Shade300)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 8

                    Label {
                        text: "\uE8EF"  // Receipt icon
                        font.family: "Segoe MDL2 Assets"
                        font.pixelSize: 32
                        color: Material.primary
                    }

                    Label {
                        text: (viewModel.summary.totalTransactions || 0).toString()
                        font.pixelSize: 24
                        font.weight: Font.Bold
                        color: Material.foreground
                    }

                    Label {
                        text: qsTr("Transacciones")
                        font.pixelSize: 12
                        opacity: 0.7
                        color: Material.foreground
                    }
                }
            }

            // Ticket Promedio
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 120
                color: Material.theme === Material.Dark ?
                    Qt.lighter(Material.background, 1.2) :
                    "white"
                radius: 8
                border.width: 1
                border.color: Material.theme === Material.Dark ?
                    Material.color(Material.Grey, Material.Shade700) :
                    Material.color(Material.Grey, Material.Shade300)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 8

                    Label {
                        text: "\uE8BA"  // Calculator icon
                        font.family: "Segoe MDL2 Assets"
                        font.pixelSize: 32
                        color: Material.primary
                    }

                    Label {
                        text: "S/" + (viewModel.summary.averageTicket || 0).toFixed(2)
                        font.pixelSize: 24
                        font.weight: Font.Bold
                        color: Material.foreground
                    }

                    Label {
                        text: qsTr("Ticket Promedio")
                        font.pixelSize: 12
                        opacity: 0.7
                        color: Material.foreground
                    }
                }
            }

            // Crecimiento
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 120
                color: Material.theme === Material.Dark ?
                    Qt.lighter(Material.background, 1.2) :
                    "white"
                radius: 8
                border.width: 1
                border.color: Material.theme === Material.Dark ?
                    Material.color(Material.Grey, Material.Shade700) :
                    Material.color(Material.Grey, Material.Shade300)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 8

                    Label {
                        text: (viewModel.summary.salesGrowth || 0) >= 0 ? "\uE74A" : "\uE74B"  // Arrow up/down
                        font.family: "Segoe MDL2 Assets"
                        font.pixelSize: 32
                        color: (viewModel.summary.salesGrowth || 0) >= 0 ? 
                            Material.color(Material.Green) : 
                            Material.color(Material.Red)
                    }

                    Label {
                        text: ((viewModel.summary.salesGrowth || 0) >= 0 ? "+" : "") + 
                              (viewModel.summary.salesGrowth || 0).toFixed(1) + "%"
                        font.pixelSize: 24
                        font.weight: Font.Bold
                        color: (viewModel.summary.salesGrowth || 0) >= 0 ? 
                            Material.color(Material.Green) : 
                            Material.color(Material.Red)
                    }

                    Label {
                        text: qsTr("Crecimiento")
                        font.pixelSize: 12
                        opacity: 0.7
                        color: Material.foreground
                    }
                }
            }
        }

        // Historial de Ventas
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Material.theme === Material.Dark ?
                Qt.lighter(Material.background, 1.2) :
                "white"
            radius: 8
            border.width: 1
            border.color: Material.theme === Material.Dark ?
                Material.color(Material.Grey, Material.Shade700) :
                Material.color(Material.Grey, Material.Shade300)

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                Label {
                    text: qsTr("Historial de Ventas")
                    font.pixelSize: 18
                    font.weight: Font.Bold
                    color: Material.foreground
                }

                // Tabla de ventas
                ListView {
                    id: salesListView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    
                    model: viewModel.salesHistory

                    header: Rectangle {
                        width: parent.width
                        height: 40
                        color: Material.theme === Material.Dark ?
                            Qt.darker(Material.background, 1.1) :
                            Material.color(Material.Grey, Material.Shade200)

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            spacing: 0

                            Label {
                                width: 120
                                height: parent.height
                                text: qsTr("Factura")
                                font.weight: Font.Bold
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Label {
                                width: 150
                                height: parent.height
                                text: qsTr("Fecha")
                                font.weight: Font.Bold
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Label {
                                width: 180
                                height: parent.height
                                text: qsTr("Cliente")
                                font.weight: Font.Bold
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Label {
                                width: 100
                                height: parent.height
                                text: qsTr("Total")
                                font.weight: Font.Bold
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Label {
                                width: 120
                                height: parent.height
                                text: qsTr("Pago")
                                font.weight: Font.Bold
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Label {
                                width: 80
                                height: parent.height
                                text: qsTr("Items")
                                font.weight: Font.Bold
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }

                    delegate: Rectangle {
                        width: ListView.view.width
                        height: 50
                        color: index % 2 === 0 ? "transparent" : 
                            Material.theme === Material.Dark ?
                                Qt.rgba(1, 1, 1, 0.02) :
                                Qt.rgba(0, 0, 0, 0.02)

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            spacing: 0

                            Label {
                                width: 120
                                height: parent.height
                                text: modelData.invoiceNumber
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                                font.family: "Consolas"
                            }

                            Label {
                                width: 150
                                height: parent.height
                                text: modelData.date
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                                opacity: 0.8
                            }

                            Label {
                                width: 180
                                height: parent.height
                                text: modelData.customerName
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                            }

                            Label {
                                width: 100
                                height: parent.height
                                text: "S/" + modelData.total.toFixed(2)
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                                font.weight: Font.Bold
                                color: Material.primary
                            }

                            Label {
                                width: 120
                                height: parent.height
                                text: modelData.paymentMethod
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                                opacity: 0.7
                            }

                            Label {
                                width: 80
                                height: parent.height
                                text: modelData.itemCount
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                                opacity: 0.7
                            }
                        }
                    }

                    ScrollBar.vertical: ScrollBar {}
                }
            }
        }
    }
}