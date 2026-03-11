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
        
        // Header con selector de período
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            
            Label {
                text: "🏆 Top 10 Productos"
                font.pixelSize: 12
                font.weight: Font.DemiBold
                color: Material.color(Material.Green)
            }
            
            Row {
                spacing: 4
                
                Button {
                    text: "Día"
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
                    text: "Mes"
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
                    text: "Año"
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
            
            Item { Layout.fillWidth: true }
            
            Label {
                text: "Unidades"
                font.pixelSize: 10
                opacity: 0.7
            }
        }
        
        // Gráfico de barras
        ChartView {
            id: chartView
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 250
            antialiasing: true
            legend.visible: true
            legend.alignment: Qt.AlignBottom
            legend.font.pixelSize: 14
            legend.font.bold: true
            backgroundColor: "transparent"
            animationOptions: ChartView.SeriesAnimations
            theme: Material.theme === Material.Dark ? ChartView.ChartThemeDark : ChartView.ChartThemeLight
            
            BarSeries {
                id: barSeries
                labelsVisible: true
                labelsPosition: AbstractBarSeries.LabelsOutsideEnd
                labelsFormat: "@value"
                labelsPrecision: 0
                
                BarSet {
                    id: barSet
                    label: "Unidades vendidas"
                    color: Material.theme === Material.Dark ? 
                           Material.color(Material.Green, Material.Shade700) :
                           Material.color(Material.Green, Material.Shade400)
                    borderColor: Material.theme === Material.Dark ?
                                Material.color(Material.Green, Material.Shade900) :
                                Material.color(Material.Green, Material.Shade600)
                    borderWidth: 2
                }
            }
            
            BarCategoryAxis {
                id: axisX
                titleText: "Productos"
                titleFont.pixelSize: 17
                titleFont.bold: true
                labelsAngle: -45
                labelsFont.pixelSize: 13
                gridVisible: false
            }
            
            ValueAxis {
                id: axisY
                titleText: "Cantidad vendida (unidades)"
                titleFont.pixelSize: 17
                titleFont.bold: true
                min: 0
                max: 50
                tickCount: 6
                labelFormat: "%.0f"
                labelsFont.pixelSize: 14
            }
            
            Component.onCompleted: {
                barSeries.axisX = axisX
                barSeries.axisY = axisY
                if (root.viewModel) {
                    root.updateChart()
                }
            }
        }
    }
    
    // Función para actualizar el gráfico
    function updateChart() {
        if (!viewModel) {
            console.warn("⚠️ TopProductsBarChart: ViewModel no está configurado")
            return
        }
        
        console.log("🔄 TopProductsBarChart: Actualizando gráfico")
        
        var days = currentPeriod === "year" ? 365 : currentPeriod === "month" ? 30 : 1
        var data = viewModel.getTopProductsByPeriod(10, days)
        
        if (!data || data.length === 0) {
            console.log("⚠️ No hay productos para mostrar")
            axisX.categories = ["Sin ventas"]
            barSet.values = [0]
            axisY.max = 10
            return
        }
        
        // Preparar categorías y valores
        var categories = []
        var values = []
        var maxQty = 0
        
        for (var i = 0; i < data.length; i++) {
            var product = data[i]
            
            // Nombre del producto (truncar si es muy largo)
            var name = product.name || "Sin nombre"
            if (name.length > 15) {
                name = name.substring(0, 12) + "..."
            }
            
            categories.push(name)
            values.push(product.quantity)
            
            if (product.quantity > maxQty) {
                maxQty = product.quantity
            }
        }
        
        // Asignar datos al gráfico
        axisX.categories = categories
        barSet.values = values
        
        // Ajustar escala del eje Y con margen superior
        axisY.max = Math.max(10, Math.ceil(maxQty * 1.3 / 5) * 5)
        
        console.log("✅ TopProductsBarChart: Gráfico actualizado:", categories.length, "productos")
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
