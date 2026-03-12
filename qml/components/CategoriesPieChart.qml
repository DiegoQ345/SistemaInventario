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
    
    // Modelo para el resumen de categorías
    ListModel {
        id: summaryModel
    }
    
    RowLayout {
        anchors.fill: parent
        spacing: 16
        
        // Panel de leyendas (35%)
        Rectangle {
            Layout.preferredWidth: parent.width * 0.35
            Layout.fillHeight: true
            color: Material.theme === Material.Dark ? 
                   Qt.lighter(Material.background, 1.1) : 
                   Qt.lighter(Material.background, 0.98)
            radius: 8
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12
                
                Label {
                    text: qsTr("Resumen de Categorías")
                    font.weight: Font.Bold
                    font.pixelSize: 14
                }
                
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    
                    ListView {
                        model: summaryModel
                        spacing: 8
                        
                        delegate: Rectangle {
                            width: ListView.view.width
                            height: 60
                            color: "transparent"
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 10
                                
                                Rectangle {
                                    Layout.preferredWidth: 10
                                    Layout.preferredHeight: 10
                                    radius: 5
                                    color: {
                                        var colors = [
                                            "#2196F3", "#4CAF50", "#FF9800", "#9C27B0", "#F44336",
                                            "#00BCD4", "#8BC34A", "#FFC107", "#E91E63", "#3F51B5"
                                        ]
                                        // Usar index del ListView en lugar de model.index
                                        var idx = typeof index !== 'undefined' ? index : 0
                                        return colors[idx % colors.length]
                                    }
                                }
                                
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0
                                    
                                    Label {
                                        text: model.label
                                        font.weight: Font.Medium
                                        font.pixelSize: 13
                                    }
                                    
                                    Label {
                                        text: model.count + " unidades (" + model.percentage + "%)"
                                        opacity: 0.6
                                        font.pixelSize: 11
                                    }
                                }
                                
                                Label {
                                    text: "S/ " + Number(model.value).toFixed(2)
                                    font.weight: Font.Bold
                                    font.pixelSize: 15
                                    Layout.alignment: Qt.AlignRight
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // Gráfico circular (65%)
        ChartView {
            id: chartView
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 200
            antialiasing: true
            legend.visible: false
            backgroundColor: "transparent"
            animationOptions: ChartView.SeriesAnimations
            theme: Material.theme === Material.Dark ? ChartView.ChartThemeDark : ChartView.ChartThemeLight
            backgroundRoundness: 0
            
            PieSeries {
                id: pieSeries
                size: 0.85
                holeSize: 0.4
                
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
    
    // Función para actualizar el gráfico
    function updateChart() {
        if (!viewModel) {
            console.warn("⚠️ CategoriesPieChart: ViewModel no está configurado")
            return
        }
        
        console.log("🔄 CategoriesPieChart: Actualizando gráfico")
        
        var days = currentPeriod === "year" ? 365 : currentPeriod === "month" ? 30 : 1
        var data = viewModel.getTopCategoriesByPeriod(10, days)
        
        pieSeries.clear()
        summaryModel.clear()
        
        if (data.length === 0) {
            console.log("⚠️ No hay categorías para mostrar")
            var emptySlice = pieSeries.append("Sin ventas", 1)
            emptySlice.color = Qt.rgba(0.5, 0.5, 0.5, 0.2)
            return
        }
        
        // Calcular el total para porcentajes
        var totalQty = 0
        var totalRevenue = 0
        for (var i = 0; i < data.length; i++) {
            totalQty += data[i].quantity
            totalRevenue += data[i].revenue
        }
        
        // Paleta de colores
        var colors = [
            "#2196F3", "#4CAF50", "#FF9800", "#9C27B0", "#F44336",
            "#00BCD4", "#8BC34A", "#FFC107", "#E91E63", "#3F51B5"
        ]
        
        for (var i = 0; i < data.length; i++) {
            var percentage = totalQty > 0 ? ((data[i].quantity / totalQty) * 100).toFixed(1) : 0
            
            var slice = pieSeries.append(data[i].name, data[i].quantity)
            slice.color = colors[i % colors.length]
            slice.labelVisible = false
            slice.borderWidth = 0
            
            summaryModel.append({
                "label": data[i].name,
                "count": data[i].quantity,
                "value": data[i].revenue,
                "percentage": percentage
            })
        }
        
        console.log("✅ CategoriesPieChart: Gráfico actualizado")
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
