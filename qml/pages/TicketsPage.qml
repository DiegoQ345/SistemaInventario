import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Effects
import Qt.labs.platform as Platform
import SistemaInventario

Page {
    id: root
    title: qsTr("Diseñador de Tickets")
    
    property real ticketWidth: 80  // mm
    property real ticketHeight: 200  // mm
    // NOTA: pixelsPerMM es solo para VISUALIZACIÓN en el diseñador (96 DPI pantalla)
    // La impresión usa DPI dinámico del dispositivo (300 DPI PDF, 203 DPI térmica, etc)
    // IMPORTANTE: fontSize usa unidad especial con factor /3 para legibilidad en diseñador
    property real pixelsPerMM: 11.811024  // 300 DPI / 25.4 para visualización base
    
    // Tipo de comprobante para el diseño
    property string voucherDesignType: "Boleta"  // "Boleta" o "Factura"
    
    // Función para cargar modelo estándar según tipo de comprobante
    function loadStandardTemplate(type) {
        if (type === "Factura") {
            // Modelo para facturas (incluye RUC, razón social, dirección del cliente)
            ticketElements = [
                { id: "logo", type: "image", label: "Logo", x: 10, y: 5, width: 60, height: 30, content: "", fontSize: 12, bold: false, align: "center" },
                { id: "businessName", type: "text", label: "Nombre del Negocio", x: 10, y: 40, width: 60, height: 8, content: "{{businessName}}", fontSize: 14, bold: true, align: "center" },
                { id: "ruc", type: "text", label: "RUC", x: 10, y: 50, width: 60, height: 6, content: "RUC: {{ruc}}", fontSize: 10, bold: false, align: "center" },
                { id: "address", type: "text", label: "Dirección", x: 10, y: 58, width: 60, height: 10, content: "{{address}}", fontSize: 8, bold: false, align: "center" },
                { id: "phone", type: "text", label: "Teléfono", x: 10, y: 70, width: 60, height: 6, content: "Tel: {{phone}}", fontSize: 8, bold: false, align: "center" },
                { id: "separator1", type: "line", label: "Línea Separadora 1", x: 5, y: 80, width: 70, height: 1 },
                { id: "invoiceNumber", type: "text", label: "Número de Comprobante", x: 10, y: 85, width: 60, height: 8, content: "{{voucherType}}: {{invoiceNumber}}", fontSize: 12, bold: true, align: "center" },
                { id: "date", type: "text", label: "Fecha", x: 10, y: 95, width: 60, height: 6, content: "{{datetime}}", fontSize: 9, bold: false, align: "left" },
                { id: "customer", type: "text", label: "Cliente", x: 10, y: 103, width: 60, height: 6, content: "Cliente: {{customerName}}", fontSize: 8, bold: false, align: "left" },
                { id: "customerRuc", type: "text", label: "RUC Cliente", x: 10, y: 110, width: 60, height: 6, content: "RUC: {{customerRuc}}", fontSize: 8, bold: false, align: "left" },
                { id: "customerBusinessName", type: "text", label: "Razón Social", x: 10, y: 117, width: 60, height: 6, content: "{{customerBusinessName}}", fontSize: 8, bold: false, align: "left" },
                { id: "customerAddress", type: "text", label: "Dirección Cliente", x: 10, y: 124, width: 60, height: 8, content: "Dir: {{customerAddress}}", fontSize: 8, bold: false, align: "left" },
                { id: "separator2", type: "line", label: "Línea Separadora 2", x: 5, y: 134, width: 70, height: 1 },
                { id: "itemsHeader", type: "text", label: "[ITEMS]", x: 10, y: 138, width: 60, height: 6, content: "{{Productos}}", fontSize: 8, bold: false, align: "left" },
                { id: "separator3", type: "line", label: "Línea Separadora 3", x: 5, y: 188, width: 70, height: 1 },
                { id: "subtotal", type: "text", label: "Subtotal", x: 10, y: 193, width: 60, height: 6, content: "Subtotal: S/ {{subtotal}}", fontSize: 9, bold: false, align: "right" },
                { id: "total", type: "text", label: "Total", x: 10, y: 201, width: 60, height: 8, content: "TOTAL: S/ {{total}}", fontSize: 12, bold: true, align: "right" },
                { id: "separator4", type: "line", label: "Línea Separadora 4", x: 5, y: 211, width: 70, height: 1 },
                { id: "footer", type: "text", label: "Pie de Página", x: 10, y: 215, width: 60, height: 6, content: "¡Gracias por su compra!", fontSize: 9, bold: false, align: "center" }
            ]
        } else {
            // Modelo para boletas (solo nombre del cliente)
            ticketElements = [
                { id: "logo", type: "image", label: "Logo", x: 10, y: 5, width: 60, height: 30, content: "", fontSize: 12, bold: false, align: "center" },
                { id: "businessName", type: "text", label: "Nombre del Negocio", x: 10, y: 40, width: 60, height: 8, content: "{{businessName}}", fontSize: 14, bold: true, align: "center" },
                { id: "ruc", type: "text", label: "RUC", x: 10, y: 50, width: 60, height: 6, content: "RUC: {{ruc}}", fontSize: 10, bold: false, align: "center" },
                { id: "address", type: "text", label: "Dirección", x: 10, y: 58, width: 60, height: 10, content: "{{address}}", fontSize: 8, bold: false, align: "center" },
                { id: "phone", type: "text", label: "Teléfono", x: 10, y: 70, width: 60, height: 6, content: "Tel: {{phone}}", fontSize: 8, bold: false, align: "center" },
                { id: "separator1", type: "line", label: "Línea Separadora 1", x: 5, y: 80, width: 70, height: 1 },
                { id: "invoiceNumber", type: "text", label: "Número de Comprobante", x: 10, y: 85, width: 60, height: 8, content: "{{voucherType}}: {{invoiceNumber}}", fontSize: 12, bold: true, align: "center" },
                { id: "date", type: "text", label: "Fecha", x: 10, y: 95, width: 60, height: 6, content: "{{datetime}}", fontSize: 9, bold: false, align: "left" },
                { id: "customer", type: "text", label: "Cliente", x: 10, y: 103, width: 60, height: 6, content: "Cliente: {{customerName}}", fontSize: 8, bold: false, align: "left" },
                { id: "separator2", type: "line", label: "Línea Separadora 2", x: 5, y: 111, width: 70, height: 1 },
                { id: "itemsHeader", type: "text", label: "[ITEMS]", x: 10, y: 115, width: 60, height: 6, content: "{{Productos}}", fontSize: 8, bold: false, align: "left" },
                { id: "separator3", type: "line", label: "Línea Separadora 3", x: 5, y: 165, width: 70, height: 1 },
                { id: "subtotal", type: "text", label: "Subtotal", x: 10, y: 170, width: 60, height: 6, content: "Subtotal: S/ {{subtotal}}", fontSize: 9, bold: false, align: "right" },
                { id: "total", type: "text", label: "Total", x: 10, y: 178, width: 60, height: 8, content: "TOTAL: S/ {{total}}", fontSize: 12, bold: true, align: "right" },
                { id: "separator4", type: "line", label: "Línea Separadora 4", x: 5, y: 188, width: 70, height: 1 },
                { id: "footer", type: "text", label: "Pie de Página", x: 10, y: 192, width: 60, height: 6, content: "¡Gracias por su compra!", fontSize: 9, bold: false, align: "center" }
            ]
        }
        selectedElementIndex = -1
    }
    
    // Tamaños predefinidos
    property var ticketSizes: [
        { name: "80mm x 200mm (Estándar)", width: 80, height: 200 },
        { name: "80mm x 297mm (A4 Largo)", width: 80, height: 297 },
        { name: "58mm x 200mm (Compacto)", width: 58, height: 200 },
        { name: "58mm x 297mm (Compacto Largo)", width: 58, height: 297 },
        { name: "80mm x 150mm (Corto)", width: 80, height: 150 }
    ]
    property int selectedSizeIndex: 0
    
    onSelectedSizeIndexChanged: {
        if (selectedSizeIndex >= 0 && selectedSizeIndex < ticketSizes.length) {
            ticketWidth = ticketSizes[selectedSizeIndex].width
            ticketHeight = ticketSizes[selectedSizeIndex].height
        }
    }
    
    // Repositorio de diseños
    TicketTemplateRepository {
        id: templateRepository
    }
    
    // Servicio de impresión
    PrintService {
        id: printService
        onPrintCompleted: {
            showMessage("Vista previa PDF generada correctamente", "success")
        }
        onPrintFailed: function(error) {
            showMessage("Error generando PDF: " + error, "error")
        }
    }
    
    // Elementos del ticket con sus posiciones y propiedades
    property var ticketElements: [
        {
            id: "logo",
            type: "image",
            label: "Logo",
            x: 10,
            y: 5,
            width: 60,
            height: 30,
            content: "",
            fontSize: 12,
            bold: false,
            align: "center"
        },
        {
            id: "businessName",
            type: "text",
            label: "Nombre del Negocio",
            x: 10,
            y: 40,
            width: 60,
            height: 8,
            content: "{{businessName}}",
            fontSize: 14,
            bold: true,
            align: "center"
        },
        {
            id: "ruc",
            type: "text",
            label: "RUC",
            x: 10,
            y: 50,
            width: 60,
            height: 6,
            content: "RUC: {{ruc}}",
            fontSize: 10,
            bold: false,
            align: "center"
        },
        {
            id: "address",
            type: "text",
            label: "Dirección",
            x: 10,
            y: 58,
            width: 60,
            height: 10,
            content: "{{address}}",
            fontSize: 8,
            bold: false,
            align: "center"
        },
        {
            id: "phone",
            type: "text",
            label: "Teléfono",
            x: 10,
            y: 70,
            width: 60,
            height: 6,
            content: "Tel: (01) 123-4567",
            fontSize: 8,
            bold: false,
            align: "center"
        },
        {
            id: "separator1",
            type: "line",
            label: "Línea Separadora 1",
            x: 5,
            y: 80,
            width: 70,
            height: 1
        },
        {
            id: "invoiceNumber",
            type: "text",
            label: "Número de Comprobante",
            x: 10,
            y: 85,
            width: 60,
            height: 8,
            content: "{{voucherType}}: {{invoiceNumber}}",
            fontSize: 12,
            bold: true,
            align: "center"
        },
        {
            id: "date",
            type: "text",
            label: "Fecha",
            x: 10,
            y: 95,
            width: 60,
            height: 6,
            content: "{{datetime}}",
            fontSize: 9,
            bold: false,
            align: "left"
        },
        {
            id: "customer",
            type: "text",
            label: "Cliente",
            x: 10,
            y: 103,
            width: 60,
            height: 6,
            content: "Cliente: {{customerName}}",
            fontSize: 8,
            bold: false,
            align: "left"
        },
        {
            id: "customerRuc",
            type: "text",
            label: "RUC Cliente (Factura)",
            x: 10,
            y: 110,
            width: 60,
            height: 6,
            content: "RUC: {{customerRuc}}",
            fontSize: 8,
            bold: false,
            align: "left"
        },
        {
            id: "customerBusinessName",
            type: "text",
            label: "Razón Social (Factura)",
            x: 10,
            y: 117,
            width: 60,
            height: 6,
            content: "Razón Social: {{customerBusinessName}}",
            fontSize: 8,
            bold: false,
            align: "left"
        },
        {
            id: "customerAddress",
            type: "text",
            label: "Dirección Cliente (Factura)",
            x: 10,
            y: 124,
            width: 60,
            height: 8,
            content: "Dirección: {{customerAddress}}",
            fontSize: 8,
            bold: false,
            align: "left"
        },
        {
            id: "separator2",
            type: "line",
            label: "Línea Separadora 2",
            x: 5,
            y: 134,
            width: 70,
            height: 1
        },
        {
            id: "itemsHeader",
            type: "text",
            label: "[ITEMS - Auto]",
            x: 10,
            y: 138,
            width: 60,
            height: 6,
            content: "[Los productos se agregan aquí automáticamente]",
            fontSize: 7,
            bold: false,
            align: "center"
        },
        {
            id: "separator3",
            type: "line",
            label: "Línea Separadora 3",
            x: 5,
            y: 188,
            width: 70,
            height: 1
        },
        {
            id: "subtotal",
            type: "text",
            label: "Subtotal",
            x: 10,
            y: 193,
            width: 60,
            height: 6,
            content: "Subtotal: S/ {{subtotal}}",
            fontSize: 9,
            bold: false,
            align: "right"
        },
        {
            id: "total",
            type: "text",
            label: "Total",
            x: 10,
            y: 201,
            width: 60,
            height: 8,
            content: "TOTAL: S/ {{total}}",
            fontSize: 12,
            bold: true,
            align: "right"
        },
        {
            id: "separator4",
            type: "line",
            label: "Línea Separadora 4",
            x: 5,
            y: 211,
            width: 70,
            height: 1
        },
        {
            id: "footer",
            type: "text",
            label: "Pie de Página",
            x: 10,
            y: 215,
            width: 60,
            height: 6,
            content: "¡Gracias por su compra!",
            fontSize: 9,
            bold: false,
            align: "center"
        }
    ]
    
    property int selectedElementIndex: -1
    property var savedTemplates: []
    property bool isPanning: false
    property point lastMousePos: Qt.point(0, 0)
    
    RowLayout {
        anchors.fill: parent
        spacing: 0
        
        // Panel izquierdo: Canvas de edición
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Material.theme === Material.Dark ? "#1a1a1a" : "#e0e0e0"
            
            ColumnLayout {
                anchors.fill: parent
                spacing: 16
                
                // Toolbar superior
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    color: Material.background
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12
                        
                        Item { Layout.fillWidth: true }
                        
                        Label {
                            text: qsTr("Tipo:")
                            font.pixelSize: 12
                        }
                        
                        ComboBox {
                            id: voucherTypeComboBox
                            Layout.preferredWidth: 120
                            model: ["Boleta", "Factura"]
                            currentIndex: voucherDesignType === "Factura" ? 1 : 0
                            onCurrentIndexChanged: {
                                var newType = currentIndex === 1 ? "Factura" : "Boleta"
                                if (voucherDesignType !== newType) {
                                    voucherDesignType = newType
                                    // Cargar modelo estándar cuando cambie el tipo
                                    loadStandardTemplate(newType)
                                }
                            }
                        }
                        
                        Rectangle {
                            width: 1
                            Layout.preferredHeight: 30
                            color: Material.frameColor
                        }
                        
                        Label {
                            text: qsTr("Tamaño:")
                            font.pixelSize: 12
                        }
                        
                        ComboBox {
                            id: sizeComboBox
                            Layout.preferredWidth: 200
                            model: ticketSizes.map(size => size.name)
                            currentIndex: selectedSizeIndex
                            onCurrentIndexChanged: {
                                selectedSizeIndex = currentIndex
                            }
                        }
                        
                        Rectangle {
                            width: 1
                            Layout.preferredHeight: 30
                            color: Material.frameColor
                        }
                        
                        Button {
                            text: "\uE8E5  " + qsTr("Cargar")
                            font.family: "Segoe MDL2 Assets"
                            onClicked: loadDialog.open()
                        }
                        
                        Button {
                            text: "\uE74E  " + qsTr("Guardar")
                            font.family: "Segoe MDL2 Assets"
                            highlighted: true
                            onClicked: saveDesign()
                        }
                        
                        Button {
                            text: "\uE7C5  " + qsTr("Vista Previa")
                            font.family: "Segoe MDL2 Assets"
                            onClicked: previewDialog.open()
                        }
                    }
                }
                
                // Área de trabajo con el ticket
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.margins: 20
                    
                    // ScrollView para permitir scroll si el ticket es muy grande
                    ScrollView {
                        id: scrollView
                        anchors.fill: parent
                        clip: true
                        contentWidth: canvasContainer.width
                        contentHeight: canvasContainer.height
                        
                        ScrollBar.horizontal.policy: ScrollBar.AlwaysOn
                        ScrollBar.vertical.policy: ScrollBar.AlwaysOn
                        
                        // Propiedades para el panning
                        property point panStartPos: Qt.point(0, 0)
                        property real panStartHorizontal: 0
                        property real panStartVertical: 0
                        
                        Item {
                            id: canvasContainer
                            // Agregar padding suficiente para que las barras de scroll no se sobrepongan
                            width: Math.max(scrollView.width, ticketCanvas.width + 300)
                            height: Math.max(scrollView.height, ticketCanvas.height + 300)
                            
                            // Fondo para capturar eventos de panning
                            Rectangle {
                                anchors.fill: parent
                                color: "transparent"
                                z: 0
                                
                                MouseArea {
                                    anchors.fill: parent
                                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                                    cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                                    
                                    onPressed: function(mouse) {
                                        scrollView.panStartPos = Qt.point(mouse.x, mouse.y)
                                        scrollView.panStartHorizontal = scrollView.ScrollBar.horizontal.position
                                        scrollView.panStartVertical = scrollView.ScrollBar.vertical.position
                                        isPanning = true
                                    }
                                    
                                    onPositionChanged: function(mouse) {
                                        if (pressed) {
                                            var dx = scrollView.panStartPos.x - mouse.x
                                            var dy = scrollView.panStartPos.y - mouse.y
                                            
                                            var hSize = scrollView.ScrollBar.horizontal.size
                                            var vSize = scrollView.ScrollBar.vertical.size
                                            
                                            if (hSize < 1) {
                                                var newHPos = scrollView.panStartHorizontal + (dx / canvasContainer.width)
                                                scrollView.ScrollBar.horizontal.position = Math.max(0, Math.min(1 - hSize, newHPos))
                                            }
                                            
                                            if (vSize < 1) {
                                                var newVPos = scrollView.panStartVertical + (dy / canvasContainer.height)
                                                scrollView.ScrollBar.vertical.position = Math.max(0, Math.min(1 - vSize, newVPos))
                                            }
                                        }
                                    }
                                    
                                    onReleased: {
                                        isPanning = false
                                    }
                                }
                            }
                            
                            // Información del tamaño actual
                            Rectangle {
                                x: 10
                                y: 10
                                width: infoLabel.width + 20
                                height: infoLabel.height + 10
                                color: Material.accent
                                radius: 4
                                z: 100
                                
                                Label {
                                    id: infoLabel
                                    anchors.centerIn: parent
                                    text: ticketWidth + "mm × " + ticketHeight + "mm"
                                    color: "white"
                                    font.pixelSize: 12
                                    font.bold: true
                                }
                            }
                            
                            // Fondo con cuadrícula
                            Rectangle {
                                id: ticketCanvas
                                anchors.centerIn: parent
                                width: ticketWidth * pixelsPerMM
                                height: ticketHeight * pixelsPerMM
                                color: Material.theme === Material.Dark ? "#1a1a1a" : "white"
                                border.width: 2
                                border.color: Material.theme === Material.Dark ? "white" : Material.primary
                                z: 10
                        
                        // Cuadrícula de fondo
                        Canvas {
                            id: gridCanvas
                            anchors.fill: parent
                            
                            Connections {
                                target: root
                                function onTicketWidthChanged() { gridCanvas.requestPaint() }
                                function onTicketHeightChanged() { gridCanvas.requestPaint() }
                            }
                            
                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.clearRect(0, 0, width, height)
                                ctx.strokeStyle = Material.theme === Material.Dark ? "#404040" : "#e0e0e0"
                                ctx.lineWidth = 0.5
                                
                                // Líneas verticales cada 10mm
                                for (var x = 0; x <= width; x += 10 * pixelsPerMM) {
                                    ctx.beginPath()
                                    ctx.moveTo(x, 0)
                                    ctx.lineTo(x, height)
                                    ctx.stroke()
                                }
                                
                                // Líneas horizontales cada 10mm
                                for (var y = 0; y <= height; y += 10 * pixelsPerMM) {
                                    ctx.beginPath()
                                    ctx.moveTo(0, y)
                                    ctx.lineTo(width, y)
                                    ctx.stroke()
                                }
                            }
                        }
                        
                        // Elementos del ticket
                        Repeater {
                            model: ticketElements
                            
                            Rectangle {
                                id: elementRect
                                x: modelData.x * pixelsPerMM
                                y: modelData.y * pixelsPerMM
                                width: modelData.width * pixelsPerMM
                                height: modelData.height * pixelsPerMM
                                color: "transparent"
                                border.width: selectedElementIndex === index ? 2 : 1
                                border.color: selectedElementIndex === index ? Material.accent : "#90A4AE"
                                z: 15
                                
                                // Contenido del elemento
                                Label {
                                    anchors.fill: parent
                                    anchors.margins: 2
                                    text: modelData.type === "line" ? "━━━━━━━━━━" : modelData.content
                                    font.pixelSize: modelData.fontSize * (pixelsPerMM / 3)
                                    font.bold: modelData.bold
                                    horizontalAlignment: modelData.align === "center" ? Text.AlignHCenter : 
                                                        modelData.align === "right" ? Text.AlignRight : Text.AlignLeft
                                    verticalAlignment: Text.AlignVCenter
                                    wrapMode: Text.WordWrap
                                    visible: modelData.type !== "image"
                                    color: Material.theme === Material.Dark ? "white" : "black"
                                }
                                
                                // Contenedor de imagen con DropArea
                                Item {
                                    anchors.fill: parent
                                    visible: modelData.type === "image"
                                    
                                    DropArea {
                                        id: imageDropArea
                                        anchors.fill: parent
                                        keys: ["text/uri-list"]
                                        
                                        onDropped: function(drop) {
                                            if (drop.hasUrls) {
                                                var url = drop.urls[0]
                                                var path = url.toString()
                                                
                                                // Remover file:/// del inicio
                                                if (path.startsWith("file:///")) {
                                                    path = path.substring(8)
                                                }
                                                
                                                // Verificar si es una imagen
                                                var validExtensions = [".png", ".jpg", ".jpeg", ".bmp", ".gif"]
                                                var isValidImage = validExtensions.some(function(ext) {
                                                    return path.toLowerCase().endsWith(ext)
                                                })
                                                
                                                if (isValidImage) {
                                                    ticketElements[index].content = url.toString()
                                                    root.ticketElementsChanged()
                                                    showMessage("Imagen cargada correctamente", "success")
                                                } else {
                                                    showMessage("Solo se permiten archivos de imagen", "error")
                                                }
                                            }
                                        }
                                        
                                        Rectangle {
                                            anchors.fill: parent
                                            color: imageDropArea.containsDrag ? Material.accent : 
                                                   (modelData.content && modelData.content !== "") ? "transparent" : "#f0f0f0"
                                            border.color: imageDropArea.containsDrag ? Material.accent : "#ccc"
                                            border.width: imageDropArea.containsDrag ? 2 : 1
                                            opacity: imageDropArea.containsDrag ? 0.3 : 1
                                            
                                            // Mostrar imagen si existe
                                            Image {
                                                anchors.fill: parent
                                                anchors.margins: 2
                                                source: modelData.content || ""
                                                fillMode: Image.PreserveAspectFit
                                                visible: modelData.content && modelData.content !== ""
                                                smooth: true
                                                asynchronous: true
                                            }
                                            
                                            // Placeholder cuando no hay imagen
                                            ColumnLayout {
                                                anchors.centerIn: parent
                                                visible: !modelData.content || modelData.content === ""
                                                spacing: 4
                                                
                                                Label {
                                                    Layout.alignment: Qt.AlignHCenter
                                                    text: "\uEB9F"
                                                    font.family: "Segoe MDL2 Assets"
                                                    font.pixelSize: 24
                                                    color: imageDropArea.containsDrag ? Material.accent : "#999"
                                                }
                                                
                                                Label {
                                                    Layout.alignment: Qt.AlignHCenter
                                                    text: imageDropArea.containsDrag ? "Suelta aquí" : "Arrastra imagen"
                                                    font.pixelSize: 8
                                                    color: "#999"
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                // Hacer draggable
                                MouseArea {
                                    anchors.fill: parent
                                    drag.target: parent
                                    drag.axis: Drag.XAndYAxis
                                    cursorShape: Qt.SizeAllCursor
                                    z: 10
                                    preventStealing: true
                                    propagateComposedEvents: false
                                    
                                    onClicked: {
                                        selectedElementIndex = index
                                    }
                                    
                                    onReleased: {
                                        // Actualizar posición en el modelo
                                        var newX = parent.x / pixelsPerMM
                                        var newY = parent.y / pixelsPerMM
                                        ticketElements[index].x = Math.round(newX * 10) / 10
                                        ticketElements[index].y = Math.round(newY * 10) / 10
                                    }
                                }
                                
                                // Handles de redimensionamiento (solo visibles cuando está seleccionado)
                                // Handle esquina superior izquierda
                                Rectangle {
                                    x: -4
                                    y: -4
                                    width: 8
                                    height: 8
                                    color: "white"
                                    border.color: Material.accent
                                    border.width: 2
                                    radius: 4
                                    visible: selectedElementIndex === index
                                    z: 20
                                    
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.SizeFDiagCursor
                                        drag.target: parent
                                        
                                        property point startPos
                                        property real startWidth
                                        property real startHeight
                                        property real startX
                                        property real startY
                                        
                                        onPressed: function(mouse) {
                                            startPos = Qt.point(mouse.x, mouse.y)
                                            startWidth = elementRect.width
                                            startHeight = elementRect.height
                                            startX = elementRect.x
                                            startY = elementRect.y
                                        }
                                        
                                        onPositionChanged: function(mouse) {
                                            if (pressed) {
                                                var dx = parent.x + 4
                                                var dy = parent.y + 4
                                                
                                                var newWidth = startWidth - dx
                                                var newHeight = startHeight - dy
                                                
                                                if (newWidth > 10 && newHeight > 10) {
                                                    elementRect.width = newWidth
                                                    elementRect.height = newHeight
                                                    elementRect.x = startX + dx
                                                    elementRect.y = startY + dy
                                                }
                                            }
                                        }
                                        
                                        onReleased: {
                                            ticketElements[index].width = Math.round((elementRect.width / pixelsPerMM) * 10) / 10
                                            ticketElements[index].height = Math.round((elementRect.height / pixelsPerMM) * 10) / 10
                                            ticketElements[index].x = Math.round((elementRect.x / pixelsPerMM) * 10) / 10
                                            ticketElements[index].y = Math.round((elementRect.y / pixelsPerMM) * 10) / 10
                                            root.ticketElementsChanged()
                                        }
                                    }
                                }
                                
                                // Handle esquina superior derecha
                                Rectangle {
                                    x: parent.width - 4
                                    y: -4
                                    width: 8
                                    height: 8
                                    color: "white"
                                    border.color: Material.accent
                                    border.width: 2
                                    radius: 4
                                    visible: selectedElementIndex === index
                                    z: 20
                                    
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.SizeBDiagCursor
                                        drag.target: parent
                                        
                                        property point startPos
                                        property real startWidth
                                        property real startHeight
                                        property real startY
                                        
                                        onPressed: function(mouse) {
                                            startPos = Qt.point(mouse.x, mouse.y)
                                            startWidth = elementRect.width
                                            startHeight = elementRect.height
                                            startY = elementRect.y
                                        }
                                        
                                        onPositionChanged: function(mouse) {
                                            if (pressed) {
                                                var dx = parent.x - (elementRect.width - 4)
                                                var dy = parent.y + 4
                                                
                                                var newWidth = startWidth + dx
                                                var newHeight = startHeight - dy
                                                
                                                if (newWidth > 10 && newHeight > 10) {
                                                    elementRect.width = newWidth
                                                    elementRect.height = newHeight
                                                    elementRect.y = startY + dy
                                                }
                                            }
                                        }
                                        
                                        onReleased: {
                                            ticketElements[index].width = Math.round((elementRect.width / pixelsPerMM) * 10) / 10
                                            ticketElements[index].height = Math.round((elementRect.height / pixelsPerMM) * 10) / 10
                                            ticketElements[index].y = Math.round((elementRect.y / pixelsPerMM) * 10) / 10
                                            root.ticketElementsChanged()
                                        }
                                    }
                                }
                                
                                // Handle esquina inferior izquierda
                                Rectangle {
                                    x: -4
                                    y: parent.height - 4
                                    width: 8
                                    height: 8
                                    color: "white"
                                    border.color: Material.accent
                                    border.width: 2
                                    radius: 4
                                    visible: selectedElementIndex === index
                                    z: 20
                                    
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.SizeBDiagCursor
                                        drag.target: parent
                                        
                                        property point startPos
                                        property real startWidth
                                        property real startHeight
                                        property real startX
                                        
                                        onPressed: function(mouse) {
                                            startPos = Qt.point(mouse.x, mouse.y)
                                            startWidth = elementRect.width
                                            startHeight = elementRect.height
                                            startX = elementRect.x
                                        }
                                        
                                        onPositionChanged: function(mouse) {
                                            if (pressed) {
                                                var dx = parent.x + 4
                                                var dy = parent.y - (elementRect.height - 4)
                                                
                                                var newWidth = startWidth - dx
                                                var newHeight = startHeight + dy
                                                
                                                if (newWidth > 10 && newHeight > 10) {
                                                    elementRect.width = newWidth
                                                    elementRect.height = newHeight
                                                    elementRect.x = startX + dx
                                                }
                                            }
                                        }
                                        
                                        onReleased: {
                                            ticketElements[index].width = Math.round((elementRect.width / pixelsPerMM) * 10) / 10
                                            ticketElements[index].height = Math.round((elementRect.height / pixelsPerMM) * 10) / 10
                                            ticketElements[index].x = Math.round((elementRect.x / pixelsPerMM) * 10) / 10
                                            root.ticketElementsChanged()
                                        }
                                    }
                                }
                                
                                // Handle esquina inferior derecha
                                Rectangle {
                                    x: parent.width - 4
                                    y: parent.height - 4
                                    width: 8
                                    height: 8
                                    color: "white"
                                    border.color: Material.accent
                                    border.width: 2
                                    radius: 4
                                    visible: selectedElementIndex === index
                                    z: 20
                                    
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.SizeFDiagCursor
                                        drag.target: parent
                                        
                                        property point startPos
                                        property real startWidth
                                        property real startHeight
                                        
                                        onPressed: function(mouse) {
                                            startPos = Qt.point(mouse.x, mouse.y)
                                            startWidth = elementRect.width
                                            startHeight = elementRect.height
                                        }
                                        
                                        onPositionChanged: function(mouse) {
                                            if (pressed) {
                                                var dx = parent.x - (elementRect.width - 4)
                                                var dy = parent.y - (elementRect.height - 4)
                                                
                                                var newWidth = startWidth + dx
                                                var newHeight = startHeight + dy
                                                
                                                if (newWidth > 10 && newHeight > 10) {
                                                    elementRect.width = newWidth
                                                    elementRect.height = newHeight
                                                }
                                            }
                                        }
                                        
                                        onReleased: {
                                            ticketElements[index].width = Math.round((elementRect.width / pixelsPerMM) * 10) / 10
                                            ticketElements[index].height = Math.round((elementRect.height / pixelsPerMM) * 10) / 10
                                            root.ticketElementsChanged()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }  // Fin Rectangle ticketCanvas
            }  // Fin Item canvasContainer
        }  // Fin ScrollView / Fin Item área de trabajo
        }  // Fin ColumnLayout
        }  // Fin Rectangle panel izquierdo
        
        // Panel derecho: Propiedades
        Rectangle {
            Layout.preferredWidth: 320
            Layout.fillHeight: true
            color: Material.background
            border.width: 1
            border.color: Material.frameColor
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 16
                
                Label {
                    text: qsTr("Propiedades")
                    font.pixelSize: 18
                    font.bold: true
                }
                
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    ScrollBar.vertical.policy: ScrollBar.AsNeeded
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                    
                    ColumnLayout {
                        width: parent.parent.width - 40  // Padding adicional para evitar sobreposición
                        spacing: 12
                        
                        // Mostrar propiedades si hay elemento seleccionado
                        GroupBox {
                            Layout.fillWidth: true
                            title: selectedElementIndex >= 0 ? ticketElements[selectedElementIndex].label : qsTr("Ningún elemento seleccionado")
                            visible: selectedElementIndex >= 0
                            
                            ColumnLayout {
                                width: parent.width
                                spacing: 12
                                
                                Label {
                                    text: qsTr("Posición y Tamaño")
                                    font.bold: true
                                    Layout.fillWidth: true
                                }
                                
                                GridLayout {
                                    Layout.fillWidth: true
                                    columns: 2
                                    columnSpacing: 8
                                    rowSpacing: 8
                                    
                                    Label { text: "X (mm):" }
                                    SpinBox {
                                        id: xSpinBox
                                        Layout.fillWidth: true
                                        from: 0
                                        to: ticketWidth
                                        value: selectedElementIndex >= 0 ? ticketElements[selectedElementIndex].x : 0
                                        onValueModified: {
                                            if (selectedElementIndex >= 0) {
                                                ticketElements[selectedElementIndex].x = value
                                                root.ticketElementsChanged()
                                            }
                                        }
                                    }
                                    
                                    Label { text: "Y (mm):" }
                                    SpinBox {
                                        id: ySpinBox
                                        Layout.fillWidth: true
                                        from: 0
                                        to: ticketHeight
                                        value: selectedElementIndex >= 0 ? ticketElements[selectedElementIndex].y : 0
                                        onValueModified: {
                                            if (selectedElementIndex >= 0) {
                                                ticketElements[selectedElementIndex].y = value
                                                root.ticketElementsChanged()
                                            }
                                        }
                                    }
                                    
                                    Label { text: "Ancho (mm):" }
                                    SpinBox {
                                        Layout.fillWidth: true
                                        from: 1
                                        to: ticketWidth
                                        value: selectedElementIndex >= 0 ? ticketElements[selectedElementIndex].width : 0
                                        onValueModified: {
                                            if (selectedElementIndex >= 0) {
                                                ticketElements[selectedElementIndex].width = value
                                                root.ticketElementsChanged()
                                            }
                                        }
                                    }
                                    
                                    Label { text: "Alto (mm):" }
                                    SpinBox {
                                        Layout.fillWidth: true
                                        from: 1
                                        to: ticketHeight
                                        value: selectedElementIndex >= 0 ? ticketElements[selectedElementIndex].height : 0
                                        onValueModified: {
                                            if (selectedElementIndex >= 0) {
                                                ticketElements[selectedElementIndex].height = value
                                                root.ticketElementsChanged()
                                            }
                                        }
                                    }
                                }
                                
                                // Propiedades de texto
                                Label {
                                    text: qsTr("Formato de Texto")
                                    font.bold: true
                                    Layout.fillWidth: true
                                    visible: selectedElementIndex >= 0 && ticketElements[selectedElementIndex].type === "text"
                                }
                                
                                GridLayout {
                                    Layout.fillWidth: true
                                    columns: 2
                                    columnSpacing: 8
                                    rowSpacing: 8
                                    visible: selectedElementIndex >= 0 && ticketElements[selectedElementIndex].type === "text"
                                    
                                    Label { text: "Contenido:" }
                                    TextArea {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 60
                                        text: selectedElementIndex >= 0 ? ticketElements[selectedElementIndex].content : ""
                                        wrapMode: TextArea.WordWrap
                                        onTextChanged: {
                                            if (selectedElementIndex >= 0) {
                                                ticketElements[selectedElementIndex].content = text
                                                root.ticketElementsChanged()
                                            }
                                        }
                                    }
                                    
                                    // Botón de ayuda de referencias
                                    Button {
                                        Layout.columnSpan: 2
                                        Layout.preferredWidth: 200
                                        flat: true
                                        icon.name: "help"
                                        text: qsTr("Ver Referencias")
                                        
                                        contentItem: RowLayout {
                                            spacing: 6
                                            Label {
                                                text: "\uE897"  // Ícono de interrogación circular
                                                font.family: "Segoe MDL2 Assets"
                                                font.pixelSize: 16
                                                color: Material.accent
                                            }
                                            Label {
                                                text: qsTr("Ver Referencias de Variables")
                                                font.pixelSize: 11
                                                color: Material.accent
                                            }
                                        }
                                        
                                        onClicked: variablesReferenceDialog.open()
                                    }
                                    
                                    Label { 
                                        text: "Tamaño de Fuente:" 
                                        Layout.columnSpan: 2
                                        font.bold: true
                                        topPadding: 8
                                    }
                                    
                                    // Presets de tamaño
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Layout.columnSpan: 2
                                        spacing: 4
                                        
                                        Button {
                                            text: "Pequeño"
                                            Layout.fillWidth: true
                                            font.pixelSize: 10
                                            flat: true
                                            onClicked: {
                                                if (selectedElementIndex >= 0) {
                                                    ticketElements[selectedElementIndex].fontSize = 8
                                                    root.ticketElementsChanged()
                                                }
                                            }
                                        }
                                        Button {
                                            text: "Normal"
                                            Layout.fillWidth: true
                                            font.pixelSize: 11
                                            flat: true
                                            onClicked: {
                                                if (selectedElementIndex >= 0) {
                                                    ticketElements[selectedElementIndex].fontSize = 12
                                                    root.ticketElementsChanged()
                                                }
                                            }
                                        }
                                        Button {
                                            text: "Grande"
                                            Layout.fillWidth: true
                                            font.pixelSize: 13
                                            flat: true
                                            onClicked: {
                                                if (selectedElementIndex >= 0) {
                                                    ticketElements[selectedElementIndex].fontSize = 16
                                                    root.ticketElementsChanged()
                                                }
                                            }
                                        }
                                        Button {
                                            text: "XL"
                                            Layout.fillWidth: true
                                            font.pixelSize: 14
                                            font.bold: true
                                            flat: true
                                            onClicked: {
                                                if (selectedElementIndex >= 0) {
                                                    ticketElements[selectedElementIndex].fontSize = 20
                                                    root.ticketElementsChanged()
                                                }
                                            }
                                        }
                                    }
                                    
                                    // Control con slider y spinbox
                                    Label { text: "Tamaño:" }
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8
                                        
                                        Slider {
                                            id: fontSizeSlider
                                            Layout.fillWidth: true
                                            from: 4
                                            to: 48
                                            stepSize: 1
                                            value: selectedElementIndex >= 0 ? ticketElements[selectedElementIndex].fontSize : 12
                                            onMoved: {
                                                if (selectedElementIndex >= 0) {
                                                    ticketElements[selectedElementIndex].fontSize = Math.round(value)
                                                    root.ticketElementsChanged()
                                                }
                                            }
                                        }
                                        
                                        SpinBox {
                                            id: fontSizeSpinBox
                                            Layout.preferredWidth: 80
                                            from: 4
                                            to: 48
                                            value: selectedElementIndex >= 0 ? ticketElements[selectedElementIndex].fontSize : 12
                                            onValueModified: {
                                                if (selectedElementIndex >= 0) {
                                                    ticketElements[selectedElementIndex].fontSize = value
                                                    root.ticketElementsChanged()
                                                }
                                            }
                                        }
                                    }
                                    
                                    // Vista previa del tamaño
                                    Label {
                                        Layout.columnSpan: 2
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 40
                                        text: "Abc 123"
                                        font.pixelSize: selectedElementIndex >= 0 ? ticketElements[selectedElementIndex].fontSize : 12
                                        font.bold: selectedElementIndex >= 0 ? ticketElements[selectedElementIndex].bold : false
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                        background: Rectangle {
                                            color: Material.theme === Material.Dark ? "#2a2a2a" : "#f5f5f5"
                                            border.color: Material.frameColor
                                            border.width: 1
                                            radius: 4
                                        }
                                    }
                                    
                                    Label { text: "Estilo:" }
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 4
                                        
                                        CheckBox {
                                            text: "Negrita"
                                            checked: selectedElementIndex >= 0 ? ticketElements[selectedElementIndex].bold : false
                                            onCheckedChanged: {
                                                if (selectedElementIndex >= 0) {
                                                    ticketElements[selectedElementIndex].bold = checked
                                                    root.ticketElementsChanged()
                                                }
                                            }
                                        }
                                    }
                                    
                                    Label { text: "Alineación:" }
                                    ComboBox {
                                        Layout.fillWidth: true
                                        model: ["left", "center", "right"]
                                        displayText: currentText === "left" ? "Izquierda" : 
                                                    currentText === "center" ? "Centro" : "Derecha"
                                        currentIndex: {
                                            if (selectedElementIndex < 0) return 0
                                            var align = ticketElements[selectedElementIndex].align
                                            return align === "right" ? 2 : align === "center" ? 1 : 0
                                        }
                                        onCurrentTextChanged: {
                                            if (selectedElementIndex >= 0) {
                                                ticketElements[selectedElementIndex].align = currentText
                                                root.ticketElementsChanged()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Lista de elementos
                        GroupBox {
                            Layout.fillWidth: true
                            title: qsTr("Elementos del Ticket")
                            
                            ColumnLayout {
                                width: parent.width
                                spacing: 8
                                
                                Repeater {
                                    model: ticketElements
                                    
                                    ItemDelegate {
                                        Layout.fillWidth: true
                                        text: modelData.label
                                        highlighted: selectedElementIndex === index
                                        
                                        onClicked: {
                                            selectedElementIndex = index
                                        }
                                        
                                        contentItem: RowLayout {
                                            spacing: 8
                                            
                                            Label {
                                                text: modelData.type === "text" ? "\uE8D2" : 
                                                      modelData.type === "image" ? "\uEB9F" : "\uE81C"
                                                font.family: "Segoe MDL2 Assets"
                                            }
                                            
                                            Label {
                                                text: modelData.label
                                                Layout.fillWidth: true
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
    }  // Fin RowLayout principal
    
    // Diálogo de vista previa
    Dialog {
        id: previewDialog
        title: qsTr("Vista Previa del Ticket")
        modal: true
        anchors.centerIn: parent
        width: Math.min(parent.width * 0.7, 900)
        height: Math.min(parent.height * 0.85, 1000)
        
        // Factor de escala para la vista previa (ajustable por el usuario)
        property real previewScale: 0.6
        
        // Función para reemplazar variables con valores de ejemplo
        function replacePreviewVariables(text) {
            if (!text) return text
            
            var result = text
            result = result.replace(/{{businessName}}/g, "Mi Negocio E.I.R.L.")
            result = result.replace(/{{ruc}>/g, "20123456789")
            result = result.replace(/{{address}}/g, "Av. Principal 123, Lima")
            result = result.replace(/{{phone}}/g, "01-234-5678")
            result = result.replace(/{{email}}/g, "ventas@minegocio.com")
            result = result.replace(/{{invoiceNumber}}/g, "B001-00123")
            result = result.replace(/{{date}}/g, new Date().toLocaleDateString())
            result = result.replace(/{{time}}/g, new Date().toLocaleTimeString())
            result = result.replace(/{{datetime}}/g, new Date().toLocaleString())
            result = result.replace(/{{customerName}}/g, "Cliente Ejemplo")
            result = result.replace(/{{customerRuc}}/g, "10987654321")
            result = result.replace(/{{customerBusinessName}}/g, "EMPRESA EJEMPLO S.A.C.")
            result = result.replace(/{{customerRazonSocial}}/g, "EMPRESA EJEMPLO S.A.C.")
            result = result.replace(/{{customerAddress}}/g, "Jr. Ejemplo 456, Lima")
            result = result.replace(/{{subtotal}}/g, "100.00")
            result = result.replace(/{{discount}}/g, "10.00")
            result = result.replace(/{{tax}}/g, "16.20")
            result = result.replace(/{{total}}/g, "106.20")
            result = result.replace(/{{voucherType}}/g, voucherDesignType.toUpperCase())
            result = result.replace(/{{Productos}}/g, "Producto A x2 S/50.00\nProducto B x1 S/30.00\nProducto C x3 S/20.00")
            
            return result
        }
        
        contentItem: ColumnLayout {
            spacing: 16
            
            // Barra superior con información y controles de zoom
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                
                Label {
                    Layout.fillWidth: true
                    text: qsTr("Previsualización con datos de ejemplo • Tamaño: %1x%2mm").arg(ticketWidth).arg(ticketHeight)
                    font.pixelSize: 12
                    opacity: 0.7
                    horizontalAlignment: Text.AlignLeft
                }
                
                Label {
                    text: qsTr("Zoom:")
                    font.pixelSize: 11
                    opacity: 0.7
                }
                
                Button {
                    text: "-"
                    font.pixelSize: 16
                    font.bold: true
                    flat: true
                    implicitWidth: 36
                    implicitHeight: 36
                    enabled: previewDialog.previewScale > 0.3
                    onClicked: previewDialog.previewScale = Math.max(0.3, previewDialog.previewScale - 0.1)
                    ToolTip.visible: hovered
                    ToolTip.text: qsTr("Alejar")
                }
                
                Label {
                    text: Math.round(previewDialog.previewScale * 100) + "%"
                    font.pixelSize: 12
                    font.bold: true
                    Layout.minimumWidth: 50
                    horizontalAlignment: Text.AlignHCenter
                }
                
                Button {
                    text: "+"
                    font.pixelSize: 16
                    font.bold: true
                    flat: true
                    implicitWidth: 36
                    implicitHeight: 36
                    enabled: previewDialog.previewScale < 1.5
                    onClicked: previewDialog.previewScale = Math.min(1.5, previewDialog.previewScale + 0.1)
                    ToolTip.visible: hovered
                    ToolTip.text: qsTr("Acercar")
                }
                
                Button {
                    text: "⟲"
                    font.pixelSize: 16
                    flat: true
                    implicitWidth: 36
                    implicitHeight: 36
                    onClicked: previewDialog.previewScale = 0.6
                    ToolTip.visible: hovered
                    ToolTip.text: qsTr("Restablecer zoom (60%)")
                }
            }
            
            // Separador
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Material.theme === Material.Dark ? "#3a3a3a" : "#e0e0e0"
            }
            
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                ScrollBar.horizontal.policy: ScrollBar.AsNeeded
                ScrollBar.vertical.policy: ScrollBar.AsNeeded
                
                Item {
                    width: Math.max(previewContainer.width, previewDialog.width - 80)
                    height: Math.max(previewContainer.height, previewDialog.height - 250)
                    
                    Rectangle {
                        id: previewContainer
                        anchors.centerIn: parent
                        width: (ticketWidth * pixelsPerMM) * previewDialog.previewScale
                        height: (ticketHeight * pixelsPerMM) * previewDialog.previewScale
                        color: Material.theme === Material.Dark ? "#1a1a1a" : "white"
                        border.width: 2
                        border.color: Material.theme === Material.Dark ? "#555555" : "#cccccc"
                        
                        Repeater {
                            model: ticketElements
                            
                            Loader {
                                x: modelData.x * pixelsPerMM * previewDialog.previewScale
                                y: modelData.y * pixelsPerMM * previewDialog.previewScale
                                
                                sourceComponent: modelData.type === "text" ? textComponent : 
                                                modelData.type === "line" ? lineComponent : imageComponent
                                
                                property var elementData: modelData
                            }
                        }
                        
                        Component {
                            id: textComponent
                            Item {
                                width: elementData.width * pixelsPerMM * previewDialog.previewScale
                                height: elementData.height * pixelsPerMM * previewDialog.previewScale
                                
                                // Si es el marcador de items, mostrar productos de ejemplo
                                Column {
                                    anchors.fill: parent
                                    spacing: 2 * previewDialog.previewScale
                                    visible: elementData.content === "[ITEMS - Auto]"
                                    
                                    Repeater {
                                        model: [
                                            {name: "Producto 1", qty: 2, price: 25.00},
                                            {name: "Producto 2", qty: 1, price: 50.00}
                                        ]
                                        
                                        Label {
                                            width: parent.width
                                            text: modelData.qty + "x " + modelData.name + " - S/ " + modelData.price.toFixed(2)
                                            font.pixelSize: 8 * (pixelsPerMM / 3) * previewDialog.previewScale
                                            wrapMode: Text.WordWrap
                                            color: Material.theme === Material.Dark ? "white" : "black"
                                        }
                                    }
                                }
                                
                                // Para texto normal
                                Label {
                                    anchors.fill: parent
                                    text: previewDialog.replacePreviewVariables(elementData.content)
                                    font.pixelSize: elementData.fontSize * (pixelsPerMM / 3) * previewDialog.previewScale
                                    font.bold: elementData.bold
                                    horizontalAlignment: elementData.align === "center" ? Text.AlignHCenter : 
                                                        elementData.align === "right" ? Text.AlignRight : Text.AlignLeft
                                    verticalAlignment: Text.AlignVCenter
                                    wrapMode: Text.WordWrap
                                    color: Material.theme === Material.Dark ? "white" : "black"
                                    visible: elementData.content !== "[ITEMS - Auto]"
                                }
                            }
                        }
                        
                        Component {
                            id: lineComponent
                            Rectangle {
                                width: elementData.width * pixelsPerMM * previewDialog.previewScale
                                height: 1 * previewDialog.previewScale
                                color: Material.theme === Material.Dark ? "white" : "black"
                            }
                        }
                        
                        Component {
                            id: imageComponent
                            Item {
                                width: elementData.width * pixelsPerMM * previewDialog.previewScale
                                height: elementData.height * pixelsPerMM * previewDialog.previewScale
                                
                                Image {
                                    anchors.fill: parent
                                    source: elementData.content || ""
                                    fillMode: Image.PreserveAspectFit
                                    visible: elementData.content && elementData.content !== ""
                                    smooth: true
                                    asynchronous: true
                                }
                                
                                // Placeholder si no hay imagen
                                Rectangle {
                                    anchors.fill: parent
                                    color: "#f0f0f0"
                                    border.color: "#ccc"
                                    visible: !elementData.content || elementData.content === ""
                                    
                                    Label {
                                        anchors.centerIn: parent
                                        text: "\uEB9F"
                                        font.family: "Segoe MDL2 Assets"
                                        font.pixelSize: 24 * previewDialog.previewScale
                                        color: "#999"
                                    }
                                }
                            }
                        }
                    } // Fin Rectangle previewContainer
                } // Fin Item contenedor scroll
            } // Fin ScrollView
        } // Fin ColumnLayout
        
        footer: DialogButtonBox {
            Button {
                text: "\uE8AA  " + qsTr("Generar PDF")
                font.family: "Segoe MDL2 Assets"
                DialogButtonBox.buttonRole: DialogButtonBox.ActionRole
                highlighted: true
                onClicked: {
                    generatePreviewPdf()
                }
            }
            
            Button {
                text: qsTr("Cerrar")
                DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
            }
        }
    }
    
    function saveDesign() {
        saveNameDialog.open()
    }
    
    function performSave(name) {
        var layoutData = {
            size: {
                width: ticketWidth,
                height: ticketHeight
            },
            elements: ticketElements
        }
        var layoutJson = JSON.stringify(layoutData)
        var id = templateRepository.saveTemplate(name, layoutJson)
        
        if (id > 0) {
            showMessage("Diseño guardado correctamente", "success")
            savedTemplates = templateRepository.getAllTemplates() // Actualizar lista
            // Establecer como activo automáticamente si es el primero
            var templates = templateRepository.getAllTemplates()
            if (templates.length === 1) {
                templateRepository.setActiveTemplate(id)
            }
        } else {
            showMessage("Error al guardar el diseño", "error")
        }
    }
    
    function showMessage(message, type) {
        messageLabel.text = message
        messageBar.color = type === "success" ? Material.color(Material.Green) : Material.color(Material.Red)
        messageBar.visible = true
        messageTimer.start()
    }
    
    function generatePreviewPdf() {
        // Crear JSON del layout actual
        var layoutData = {
            size: {
                width: ticketWidth,
                height: ticketHeight
            },
            elements: ticketElements
        }
        var layoutJson = JSON.stringify(layoutData)
        
        // Generar nombre de archivo con timestamp
        var timestamp = new Date().toISOString().replace(/[:.]/g, "-").substring(0, 19)
        var downloadsPath = Platform.StandardPaths.writableLocation(Platform.StandardPaths.DownloadLocation)
        
        // Convertir URI a ruta nativa de Windows
        var downloadsPathStr = String(downloadsPath).replace('file:///', '')
        var outputPath = downloadsPathStr + "/ticket_preview_" + timestamp + ".pdf"
        
        console.log("Generando PDF preview en:", outputPath)
        
        // Generar PDF
        var success = printService.generatePreviewPdf(layoutJson, outputPath)
        
        if (success) {
            showMessage("PDF generado en Descargas: ticket_preview_" + timestamp + ".pdf", "success")
        } else {
            showMessage("Error al generar el PDF", "error")
        }
    }
    
    function loadDesign(templateId) {
        var template = templateRepository.getTemplate(templateId)
        if (!template || !template.id) {
            showMessage("Error al cargar el diseño", "error")
            return
        }
        
        try {
            var layoutData = JSON.parse(template.layoutJson)
            
            // Cargar tamaño si existe
            if (layoutData.size) {
                ticketWidth = layoutData.size.width
                ticketHeight = layoutData.size.height
                
                // Actualizar selector de tamaño
                for (var i = 0; i < ticketSizes.length; i++) {
                    if (ticketSizes[i].width === ticketWidth && ticketSizes[i].height === ticketHeight) {
                        selectedSizeIndex = i
                        break
                    }
                }
            }
            
            // Cargar elementos
            if (layoutData.elements) {
                ticketElements = layoutData.elements
            } else {
                // Formato antiguo (solo elementos)
                ticketElements = layoutData
            }
            
            showMessage("Diseño cargado: " + template.name, "success")
        } catch (e) {
            showMessage("Error al parsear el diseño: " + e.message, "error")
        }
    }
    
    // Diálogo para cargar diseño guardado
    Dialog {
        id: loadDialog
        title: qsTr("Cargar Diseño")
        modal: true
        anchors.centerIn: parent
        width: 450
        height: 500
        
        onOpened: {
            savedTemplates = templateRepository.getAllTemplates()
        }
        
        contentItem: ColumnLayout {
            spacing: 16
            
            Label {
                text: qsTr("Selecciona un diseño guardado:")
                Layout.fillWidth: true
                font.bold: true
            }
            
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                visible: savedTemplates.length > 0
                
                ColumnLayout {
                    width: parent.width
                    spacing: 8
                    
                    Repeater {
                        model: savedTemplates
                        
                        ItemDelegate {
                            Layout.fillWidth: true
                            
                            contentItem: RowLayout {
                                spacing: 12
                                
                                Rectangle {
                                    width: 40
                                    height: 40
                                    color: modelData.isActive ? Material.accent : Material.frameColor
                                    radius: 4
                                    
                                    Label {
                                        anchors.centerIn: parent
                                        text: "\uE8A1"
                                        font.family: "Segoe MDL2 Assets"
                                        font.pixelSize: 24
                                        color: modelData.isActive ? "white" : Material.foreground
                                    }
                                }
                                
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 4
                                    
                                    Label {
                                        text: modelData.name
                                        font.bold: true
                                        Layout.fillWidth: true
                                    }
                                    
                                    Label {
                                        text: modelData.isActive ? "✓ Activo" : "Guardado: " + modelData.createdAt
                                        font.pixelSize: 10
                                        color: modelData.isActive ? Material.accent : Material.hintTextColor
                                    }
                                }
                                
                                Button {
                                    text: "Cargar"
                                    onClicked: {
                                        loadDesign(modelData.id)
                                        loadDialog.close()
                                    }
                                }
                                
                                Button {
                                    text: modelData.isActive ? "Activo" : "Activar"
                                    flat: true
                                    enabled: !modelData.isActive
                                    onClicked: {
                                        if (templateRepository.setActiveTemplate(modelData.id)) {
                                            showMessage("Diseño activado para impresión", "success")
                                            savedTemplates = templateRepository.getAllTemplates() // Actualizar lista
                                            loadDialog.close()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            // Mensaje cuando no hay diseños guardados
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignCenter
                spacing: 16
                visible: savedTemplates.length === 0
                
                Label {
                    text: "\uE8A1"
                    font.family: "Segoe MDL2 Assets"
                    font.pixelSize: 64
                    color: Material.hintTextColor
                    Layout.alignment: Qt.AlignHCenter
                }
                
                Label {
                    text: qsTr("No hay diseños guardados")
                    font.pixelSize: 16
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter
                }
                
                Label {
                    text: qsTr("Crea y guarda tu primer diseño de ticket")
                    font.pixelSize: 12
                    color: Material.hintTextColor
                    Layout.alignment: Qt.AlignHCenter
                }
            }
            
            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 8
                
                Button {
                    text: qsTr("Cerrar")
                    onClicked: loadDialog.close()
                }
            }
        }
    }
    
    // Diálogo para ingresar nombre del diseño
    Dialog {
        id: saveNameDialog
        title: qsTr("Guardar Diseño")
        modal: true
        anchors.centerIn: parent
        width: 400
        
        contentItem: ColumnLayout {
            spacing: 16
            
            Label {
                text: qsTr("Ingrese un nombre para el diseño:")
                Layout.fillWidth: true
            }
            
            TextField {
                id: designNameField
                Layout.fillWidth: true
                placeholderText: qsTr("Ej: Diseño predeterminado")
                
                Keys.onReturnPressed: {
                    if (text.trim() !== "") {
                        saveNameDialog.accept()
                    }
                }
            }
            
            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 8
                
                Button {
                    text: qsTr("Cancelar")
                    onClicked: saveNameDialog.reject()
                }
                
                Button {
                    text: qsTr("Guardar")
                    highlighted: true
                    enabled: designNameField.text.trim() !== ""
                    onClicked: saveNameDialog.accept()
                }
            }
        }
        
        onAccepted: {
            var name = designNameField.text.trim()
            if (templateRepository.templateNameExists(name)) {
                showMessage("Ya existe un diseño con ese nombre", "error")
            } else {
                performSave(name)
                designNameField.text = ""
            }
        }
        
        onRejected: {
            designNameField.text = ""
        }
    }
    
    // Diálogo de referencias de variables
    Dialog {
        id: variablesReferenceDialog
        title: qsTr("Referencias de Variables")
        modal: true
        anchors.centerIn: parent
        width: Math.min(700, parent.width * 0.95)
        height: Math.min(650, parent.height * 0.9)
        
        background: Rectangle {
            color: Material.dialogColor
            radius: 8
            border.width: 1
            border.color: Material.theme === Material.Dark ? 
                Qt.lighter(Material.backgroundColor, 1.3) :
                Qt.darker(Material.backgroundColor, 1.1)
        }
        
        ColumnLayout {
            anchors.fill: parent
            spacing: 12
            
            Label {
                Layout.fillWidth: true
                text: qsTr("Utiliza estas variables en el contenido de texto para mostrar información dinámica en tus tickets")
                wrapMode: Text.WordWrap
                font.pixelSize: 12
                opacity: 0.9
            }
            
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                
                ColumnLayout {
                    width: variablesReferenceDialog.availableWidth - 40
                    spacing: 16
                    
                    // Información del Negocio
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: businessGroup.implicitHeight + 24
                        color: Material.theme === Material.Dark ? 
                            Qt.lighter(Material.background, 1.2) : 
                            Qt.darker(Material.background, 1.05)
                        radius: 6
                        
                        ColumnLayout {
                            id: businessGroup
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 8
                            
                            Label {
                                text: "Información del Negocio"
                                font.bold: true
                                font.pixelSize: 13
                                color: Material.accent
                            }
                            
                            GridLayout {
                                Layout.fillWidth: true
                                columns: variablesReferenceDialog.width > 600 ? 2 : 1
                                columnSpacing: 12
                                rowSpacing: 6
                                
                                Label { 
                                    text: "{{businessName}}"
                                    font.family: "Consolas"
                                    color: Material.accent
                                }
                                Label { 
                                    text: "Nombre del negocio"
                                    opacity: 0.8
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }
                                
                                Label { 
                                    text: "{{ruc}}"
                                    font.family: "Consolas"
                                    color: Material.accent
                                }
                                Label { 
                                    text: "RUC/Número de identificación tributaria"
                                    opacity: 0.8
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }
                                
                                Label { 
                                    text: "{{address}}"
                                    font.family: "Consolas"
                                    color: Material.accent
                                }
                                Label { 
                                    text: "Dirección del negocio"
                                    opacity: 0.8
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }
                                
                                Label { 
                                    text: "{{phone}}"
                                    font.family: "Consolas"
                                    color: Material.accent
                                }
                                Label { 
                                    text: "Teléfono de contacto"
                                    opacity: 0.8
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }
                                
                                Label { 
                                    text: "{{email}}"
                                    font.family: "Consolas"
                                    color: Material.accent
                                }
                                Label { 
                                    text: "Correo electrónico"
                                    opacity: 0.8
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }
                            }
                        }
                    }
                    
                    // Información de la Venta
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: saleGroup.implicitHeight + 24
                        color: Material.theme === Material.Dark ? 
                            Qt.lighter(Material.background, 1.2) : 
                            Qt.darker(Material.background, 1.05)
                        radius: 6
                        
                        ColumnLayout {
                            id: saleGroup
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 8
                            
                            Label {
                                text: "Información de la Venta"
                                font.bold: true
                                font.pixelSize: 13
                                color: Material.accent
                            }
                            
                            GridLayout {
                                Layout.fillWidth: true
                                columns: variablesReferenceDialog.width > 600 ? 2 : 1
                                columnSpacing: 12
                                rowSpacing: 6
                                
                                Label { 
                                    text: "{{invoiceNumber}}"
                                    font.family: "Consolas"
                                    color: Material.accent
                                }
                                Label { 
                                    text: "Número de factura o boleta"
                                    opacity: 0.8
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }
                                
                                Label { 
                                    text: "{{voucherType}}"
                                    font.family: "Consolas"
                                    color: Material.accent
                                }
                                Label { 
                                    text: "Tipo de comprobante (FACTURA/BOLETA)"
                                    opacity: 0.8
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }
                                
                                Label { 
                                    text: "{{customerName}}"
                                    font.family: "Consolas"
                                    color: Material.accent
                                }
                                Label { 
                                    text: "Nombre del cliente"
                                    opacity: 0.8
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }
                                
                                Label { 
                                    text: "{{customerRuc}}"
                                    font.family: "Consolas"
                                    color: Material.accent
                                }
                                Label { 
                                    text: "RUC del cliente (para facturas)"
                                    opacity: 0.8
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }
                                
                                Label { 
                                    text: "{{customerBusinessName}}"
                                    font.family: "Consolas"
                                    color: Material.accent
                                }
                                Label { 
                                    text: "Razón Social del cliente (para facturas)"
                                    opacity: 0.8
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }
                                
                                Label { 
                                    text: "{{customerAddress}}"
                                    font.family: "Consolas"
                                    color: Material.accent
                                }
                                Label { 
                                    text: "Dirección del cliente (para facturas)"
                                    opacity: 0.8
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }
                            }
                        }
                    }
                    
                    // Información de Fecha y Hora
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: dateGroup.implicitHeight + 24
                        color: Material.theme === Material.Dark ? 
                            Qt.lighter(Material.background, 1.2) : 
                            Qt.darker(Material.background, 1.05)
                        radius: 6
                        
                        ColumnLayout {
                            id: dateGroup
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 8
                            
                            Label {
                                text: "Fecha y Hora"
                                font.bold: true
                                font.pixelSize: 13
                                color: Material.accent
                            }
                            
                            GridLayout {
                                Layout.fillWidth: true
                                columns: variablesReferenceDialog.width > 600 ? 2 : 1
                                columnSpacing: 12
                                rowSpacing: 6
                                
                                Label { 
                                    text: "{{date}}"
                                    font.family: "Consolas"
                                    color: Material.accent
                                }
                                Label { 
                                    text: "Fecha de la venta (ej: 19/02/2026)"
                                    opacity: 0.8
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }
                                
                                Label { 
                                    text: "{{time}}"
                                    font.family: "Consolas"
                                    color: Material.accent
                                }
                                Label { 
                                    text: "Hora de la venta (ej: 14:30:00)"
                                    opacity: 0.8
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }
                                
                                Label { 
                                    text: "{{datetime}}"
                                    font.family: "Consolas"
                                    color: Material.accent
                                }
                                Label { 
                                    text: "Fecha y hora completas"
                                    opacity: 0.8
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }
                            }
                        }
                    }
                    
                    // Productos
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: productsGroup.implicitHeight + 24
                        color: Material.theme === Material.Dark ? 
                            Qt.lighter(Material.background, 1.2) : 
                            Qt.darker(Material.background, 1.05)
                        radius: 6
                        
                        ColumnLayout {
                            id: productsGroup
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 8
                            
                            Label {
                                text: "Lista de Productos"
                                font.bold: true
                                font.pixelSize: 13
                                color: Material.accent
                            }
                            
                            GridLayout {
                                Layout.fillWidth: true
                                columns: variablesReferenceDialog.width > 600 ? 2 : 1
                                columnSpacing: 12
                                rowSpacing: 6
                                
                                Label { 
                                    text: "{{Productos}}"
                                    font.family: "Consolas"
                                    color: Material.accent
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 4
                                    Label { 
                                        text: "Lista completa de productos con cantidades y subtotales"
                                        opacity: 0.8
                                        wrapMode: Text.WordWrap
                                        Layout.fillWidth: true
                                    }
                                    Label {
                                        text: "Formato: Producto x Cantidad S/ Subtotal"
                                        font.pixelSize: 10
                                        opacity: 0.6
                                        font.italic: true
                                        wrapMode: Text.WordWrap
                                        Layout.fillWidth: true
                                    }
                                }
                            }
                        }
                    }
                    
                    // Totales y Montos
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: totalsGroup.implicitHeight + 24
                        color: Material.theme === Material.Dark ? 
                            Qt.lighter(Material.background, 1.2) : 
                            Qt.darker(Material.background, 1.05)
                        radius: 6
                        
                        ColumnLayout {
                            id: totalsGroup
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 8
                            
                            Label {
                                text: "Totales y Montos"
                                font.bold: true
                                font.pixelSize: 13
                                color: Material.accent
                            }
                            
                            GridLayout {
                                Layout.fillWidth: true
                                columns: variablesReferenceDialog.width > 600 ? 2 : 1
                                columnSpacing: 12
                                rowSpacing: 6
                                
                                Label { 
                                    text: "{{subtotal}}"
                                    font.family: "Consolas"
                                    color: Material.accent
                                }
                                Label { 
                                    text: "Subtotal de la venta (sin impuestos)"
                                    opacity: 0.8
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }
                                
                                Label { 
                                    text: "{{discount}}"
                                    font.family: "Consolas"
                                    color: Material.accent
                                }
                                Label { 
                                    text: "Descuento aplicado"
                                    opacity: 0.8
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }
                                
                                Label { 
                                    text: "{{tax}}"
                                    font.family: "Consolas"
                                    color: Material.accent
                                }
                                Label { 
                                    text: "Impuestos (IGV u otros)"
                                    opacity: 0.8
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }
                                
                                Label { 
                                    text: "{{total}}"
                                    font.family: "Consolas"
                                    color: Material.accent
                                }
                                Label { 
                                    text: "Total final a pagar"
                                    opacity: 0.8
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }
                            }
                        }
                    }
                    
                    // Ejemplo de uso
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: exampleGroup.implicitHeight + 24
                        color: Material.color(Material.Blue, Material.Shade900)
                        radius: 6
                        
                        ColumnLayout {
                            id: exampleGroup
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 8
                            
                            Label {
                                text: "Ejemplo de Uso"
                                font.bold: true
                                font.pixelSize: 13
                                color: "#4FC3F7"
                            }
                            
                            ScrollView {
                                Layout.fillWidth: true
                                implicitHeight: Math.min(exampleText.implicitHeight + 20, 300)
                                clip: true
                                
                                Label {
                                    id: exampleText
                                    width: exampleGroup.width - 24
                                    text: "{{businessName}}\n" +
                                          "RUC: {{ruc}}\n" +
                                          "Dirección: {{address}}\n" +
                                          "Tel: {{phone}}\n" +
                                          "----------------------------\n" +
                                          "Boleta: {{invoiceNumber}}\n" +
                                          "Fecha: {{date}} - {{time}}\n" +
                                          "----------------------------\n" +
                                          "{{Productos}}\n" +
                                          "----------------------------\n" +
                                          "Subtotal: S/ {{subtotal}}\n" +
                                          "Descuento: S/ {{discount}}\n" +
                                          "Total: S/ {{total}}\n" +
                                          "----------------------------\n" +
                                          "Gracias por su compra!"
                                    font.family: "Consolas"
                                    font.pixelSize: 10
                                    wrapMode: Text.Wrap
                                }
                            }
                        }
                    }
                }
            }
            
            Button {
                text: qsTr("Cerrar")
                Layout.alignment: Qt.AlignRight
                Layout.preferredWidth: 120
                onClicked: variablesReferenceDialog.close()
            }
        }
    }
    
    // Barra de mensajes
    Rectangle {
        id: messageBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 50
        visible: false
        z: 100
        
        Label {
            id: messageLabel
            anchors.centerIn: parent
            color: "white"
            font.bold: true
        }
    }
    
    Timer {
        id: messageTimer
        interval: 3000
        onTriggered: messageBar.visible = false
    }
}
