import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtCharts

Item {
    id: root
    
    // Propiedades públicas
    property var viewModel: null
    property string currentPeriod: "days" // days, month, year
    
    // Señales
    signal periodChanged(string period)
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12
        
        // Header con selector de periodo y leyenda
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            
            // Leyenda
            RowLayout {
                spacing: 8
                
                Rectangle {
                    width: 16
                    height: 16
                    radius: 8
                    color: Material.theme === Material.Dark ? 
                           Material.color(Material.Green, Material.Shade600) :
                           Material.color(Material.Green, Material.Shade700)
                }
                
                Label {
                    text: "Ventas"
                    font.pixelSize: 11
                    font.weight: Font.Medium
                }
            }
            
            Item { Layout.fillWidth: true }
            
            // Selector de período
            Row {
                spacing: 4
                
                Button {
                    text: "14 días"
                    checkable: true
                    checked: root.currentPeriod === "days"
                    font.pixelSize: 10
                    padding: 6
                    
                    Material.background: checked ? 
                        (Material.theme === Material.Dark ? 
                            Qt.darker(ApplicationWindow.window?.currentColors?.primary ?? Material.accent, 1.5) : 
                            (ApplicationWindow.window?.currentColors?.primary ?? Material.accent)) :
                        (Material.theme === Material.Dark ? "#2d2d2d" : "#f5f5f5")
                    
                    contentItem: Label {
                        text: parent.text
                        font: parent.font
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        color: parent.checked ? 
                            (Material.theme === Material.Dark ? "#FFFFFF" : "#000000") : 
                            Material.foreground
                    }
                    
                    onClicked: {
                        root.currentPeriod = "days"
                    }
                }
                
                Button {
                    text: "30 días"
                    checkable: true
                    checked: root.currentPeriod === "month"
                    font.pixelSize: 10
                    padding: 6
                    
                    Material.background: checked ? 
                        (Material.theme === Material.Dark ? 
                            Qt.darker(ApplicationWindow.window?.currentColors?.primary ?? Material.accent, 1.5) : 
                            (ApplicationWindow.window?.currentColors?.primary ?? Material.accent)) :
                        (Material.theme === Material.Dark ? "#2d2d2d" : "#f5f5f5")
                    
                    contentItem: Label {
                        text: parent.text
                        font: parent.font
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        color: parent.checked ? 
                            (Material.theme === Material.Dark ? "#FFFFFF" : "#000000") : 
                            Material.foreground
                    }
                    
                    onClicked: {
                        root.currentPeriod = "month"
                    }
                }
                
                Button {
                    text: "12 meses"
                    checkable: true
                    checked: root.currentPeriod === "year"
                    font.pixelSize: 10
                    padding: 6
                    
                    Material.background: checked ? 
                        (Material.theme === Material.Dark ? 
                            Qt.darker(ApplicationWindow.window?.currentColors?.primary ?? Material.accent, 1.5) : 
                            (ApplicationWindow.window?.currentColors?.primary ?? Material.accent)) :
                        (Material.theme === Material.Dark ? "#2d2d2d" : "#f5f5f5")
                    
                    contentItem: Label {
                        text: parent.text
                        font: parent.font
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        color: parent.checked ? 
                            (Material.theme === Material.Dark ? "#FFFFFF" : "#000000") : 
                            Material.foreground
                    }
                    
                    onClicked: {
                        root.currentPeriod = "year"
                    }
                }
            }
        }
        
        // Gráfico de líneas con área
        ChartView {
            id: chartView
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 250
            antialiasing: true
            legend.visible: false
            backgroundColor: "transparent"
            animationOptions: ChartView.SeriesAnimations
            animationDuration: 1000
            animationEasingCurve.type: Easing.OutCubic
            theme: Material.theme === Material.Dark ? ChartView.ChartThemeDark : ChartView.ChartThemeLight
            
            // Eje X: Fechas
            DateTimeAxis {
                id: dateAxis
                format: root.currentPeriod === "year" ? "MMM" : 
                       root.currentPeriod === "month" ? "dd" : "dddd d"
                tickCount: root.currentPeriod === "year" ? 12 : 
                          root.currentPeriod === "month" ? 30 : 14
                labelsAngle: root.currentPeriod === "days" ? -45 : 
                            root.currentPeriod === "month" ? -45 : 0
                titleText: root.currentPeriod === "year" ? "Mes" : 
                          root.currentPeriod === "month" ? "Día del Mes" : "Día de la Semana"
                titleFont.pixelSize: 17
                titleFont.bold: true
                gridVisible: true
                labelsFont.pixelSize: root.currentPeriod === "days" ? 12 : 14
                minorGridVisible: false
                lineVisible: true
            }
            
            // Eje Y: Cantidad
            ValueAxis {
                id: countAxis
                titleText: "Cantidad de Ventas"
                titleFont.pixelSize: 17
                titleFont.bold: true
                min: 0
                max: 100
                tickCount: 6
                labelFormat: "%.0f"
                gridVisible: true
                minorGridVisible: false
                lineVisible: true
                labelsFont: Qt.font({ pixelSize: 14 })
            }
            
            // Serie de línea con área
            AreaSeries {
                id: areaSeries
                name: "Ventas"
                axisX: dateAxis
                axisY: countAxis
                
                // Línea superior (datos reales)
                upperSeries: LineSeries {
                    id: lineSeries
                    color: Material.theme === Material.Dark ? 
                           Material.color(Material.Green, Material.Shade600) :
                           Material.color(Material.Green, Material.Shade700)
                    width: 3
                    pointsVisible: true
                    pointLabelsVisible: false
                }
                
                // Color de relleno del área
                color: Material.theme === Material.Dark ? 
                       Material.color(Material.Green, Material.Shade900).toString() + "40" : 
                       Material.color(Material.Green, Material.Shade100).toString() + "80"
                borderColor: Material.theme === Material.Dark ? 
                            Material.color(Material.Green, Material.Shade600) :
                            Material.color(Material.Green, Material.Shade700)
                borderWidth: 3
            }
        }
    }
    
    // Función para actualizar el gráfico
    function updateChart() {
        if (!viewModel) {
            console.warn("⚠️ SalesTrendLineChart: ViewModel no está configurado")
            return
        }
        
        console.log("🔄 SalesTrendLineChart: Actualizando gráfico - Período:", currentPeriod)
        
        var days = currentPeriod === "year" ? 365 : currentPeriod === "month" ? 30 : 14
        var data = viewModel.getSalesTrendData(days)
        lineSeries.clear()
        
        var today = new Date()
        today.setHours(12, 0, 0, 0)
        
        var dateMap = {}
        var dates = []
        
        if (currentPeriod === "year") {
            // Últimos 12 meses - agrupar por mes
            for (var i = 11; i >= 0; i--) {
                var date = new Date(today.getFullYear(), today.getMonth() - i, 15, 12, 0, 0)
                dates.push(date)
                var key = date.getFullYear() + "-" + String(date.getMonth() + 1).padStart(2, '0')
                dateMap[key] = 0
            }
        } else if (currentPeriod === "month") {
            // Últimos 30 días
            for (var i = 29; i >= 0; i--) {
                var date = new Date(today)
                date.setDate(date.getDate() - i)
                date.setHours(12, 0, 0, 0)
                dates.push(date)
                var key = date.toISOString().substr(0, 10)
                dateMap[key] = 0
            }
        } else {
            // Últimos 14 días (default)
            for (var i = 13; i >= 0; i--) {
                var date = new Date(today)
                date.setDate(date.getDate() - i)
                date.setHours(12, 0, 0, 0)
                dates.push(date)
                var key = date.toISOString().substr(0, 10)
                dateMap[key] = 0
            }
        }
        
        // Llenar con datos reales
        var maxCount = 0
        if (data.length > 0) {
            for (var i = 0; i < data.length; i++) {
                var count = data[i].salesCount
                
                if (currentPeriod === "year") {
                    // Agrupar por mes
                    var dateStr = data[i].date // "YYYY-MM-DD"
                    var key = dateStr.substr(0, 7) // "YYYY-MM"
                    if (dateMap.hasOwnProperty(key)) {
                        dateMap[key] += count
                    }
                } else {
                    // Por día
                    var dateStr = data[i].date
                    if (dateMap.hasOwnProperty(dateStr)) {
                        dateMap[dateStr] = count
                    }
                }
            }
            
            // Calcular máximo
            for (var key in dateMap) {
                if (dateMap[key] > maxCount) {
                    maxCount = dateMap[key]
                }
            }
        }
        
        // Configurar rango del eje X
        dateAxis.min = dates[0]
        dateAxis.max = dates[dates.length - 1]
        
        // Añadir puntos al gráfico
        for (var i = 0; i < dates.length; i++) {
            var date = dates[i]
            var count = 0
            
            if (currentPeriod === "year") {
                var key = date.getFullYear() + "-" + String(date.getMonth() + 1).padStart(2, '0')
                count = dateMap[key] || 0
            } else {
                var key = date.toISOString().substr(0, 10)
                count = dateMap[key] || 0
            }
            
            lineSeries.append(date.getTime(), count)
        }
        
        // Ajustar escala del eje Y
        countAxis.max = Math.max(10, Math.ceil(maxCount * 1.3 / 10) * 10)
        
        console.log("✅ SalesTrendLineChart: Gráfico actualizado - Max:", maxCount)
    }
    
    // Conexión con ViewModel
    Connections {
        target: root.viewModel
        function onTodaySalesChanged() {
            root.updateChart()
        }
    }
    
    // Inicialización
    Component.onCompleted: {
        if (viewModel) {
            updateChart()
        }
    }
    
    // Observar cambios en viewModel
    onViewModelChanged: {
        if (viewModel) {
            updateChart()
        }
    }
    
    // Observar cambios en el período
    onCurrentPeriodChanged: {
        if (viewModel) {
            updateChart()
            periodChanged(currentPeriod)
        }
    }
}
