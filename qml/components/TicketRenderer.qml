import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

/**
 * Componente reutilizable para renderizar tickets
 * Garantiza que el diseñador y la vista previa sean idénticos
 */
Rectangle {
    id: root
    
    // Propiedades requeridas
    required property real ticketWidth      // en mm
    required property real ticketHeight     // en mm
    required property var ticketElements    // lista de elementos
    required property real pixelsPerMM      // conversión mm a píxeles
    
    // Propiedades opcionales
    property real scale: 1.0
    property int selectedElementIndex: -1
    property bool showGrid: false
    property bool showHandles: false
    property bool interactive: false
    property bool usePreviewData: false     // Si true, muestra datos de ejemplo
    property var replacePreviewVariables: null  // Función para reemplazar variables
    
    // Señales para el modo interactivo
    signal elementSelected(int index)
    signal elementPositionChanged(int index, real x, real y)
    signal elementGeometryChanged(int index, real x, real y, real width, real height)
    signal imageDropped(int index, string url)
    
    Component.onCompleted: {
        console.log("[TicketRenderer] Component initialized")
        console.log("  - Ticket size:", ticketWidth, "x", ticketHeight, "mm")
        console.log("  - Pixels per MM:", pixelsPerMM)
        console.log("  - Elements count:", ticketElements ? ticketElements.length : 0)
        console.log("  - Use preview data:", usePreviewData)
        console.log("  - Has replacePreviewVariables:", replacePreviewVariables !== null)
        console.log("  - Calculated width:", ticketWidth * pixelsPerMM, "px")
        console.log("  - Base height:", ticketHeight * pixelsPerMM, "px")
    }
    
    // Calcular offset acumulativo por expansión de {{Productos}}
    function calculateDynamicOffset(elementIndex) {
        if (!usePreviewData || !replacePreviewVariables || !ticketElements) {
            return 0
        }
        
        var offset = 0
        for (var i = 0; i < elementIndex && i < ticketElements.length; i++) {
            var elem = ticketElements[i]
            if (elem && elem.content && elem.content.includes("{{Productos}}")) {
                try {
                    var textContent = replacePreviewVariables(elem.content)
                    var lineCount = (textContent.match(/\n/g) || []).length + 1
                    var lineHeight = elem.fontSize * (pixelsPerMM / 3) * 1.2 // 1.2 = line spacing
                    var neededHeight = lineCount * lineHeight + 4
                    var originalHeight = elem.height * pixelsPerMM
                    if (neededHeight > originalHeight) {
                        var elementExpansion = neededHeight - originalHeight
                        offset += elementExpansion
                    }
                } catch (e) {
                    console.warn("Error calculating offset for element", i, ":", e)
                }
            }
        }
        return offset
    }
    
    // Calcular altura total incluyendo expansiones dinámicas
    function calculateTotalHeight() {
        var baseHeight = ticketHeight * pixelsPerMM
        var extraHeight = 0
        
        if (usePreviewData && replacePreviewVariables && ticketElements) {
            for (var i = 0; i < ticketElements.length; i++) {
                var elem = ticketElements[i]
                if (elem.content && elem.content.includes("{{Productos}}")) {
                    var textContent = replacePreviewVariables(elem.content)
                    var lineCount = (textContent.match(/\n/g) || []).length + 1
                    var lineHeight = elem.fontSize * (pixelsPerMM / 3) * 1.2
                    var neededHeight = lineCount * lineHeight + 4
                    var originalHeight = elem.height * pixelsPerMM
                    if (neededHeight > originalHeight) {
                        extraHeight += (neededHeight - originalHeight)  // Sumar todas las expansiones
                    }
                }
            }
        }
        
        return baseHeight + extraHeight
    }
    
    width: ticketWidth * pixelsPerMM
    // Usar binding directo en lugar de función para mejor reactividad
    height: {
        var baseHeight = ticketHeight * pixelsPerMM
        var extraHeight = 0
        
        if (usePreviewData && replacePreviewVariables && ticketElements) {
            for (var i = 0; i < ticketElements.length; i++) {
                var elem = ticketElements[i]
                if (elem && elem.content && elem.content.includes("{{Productos}}")) {
                    try {
                        var textContent = replacePreviewVariables(elem.content)
                        var lineCount = (textContent.match(/\n/g) || []).length + 1
                        var lineHeight = elem.fontSize * (pixelsPerMM / 3) * 1.2
                        var neededHeight = lineCount * lineHeight + 4
                        var originalHeight = elem.height * pixelsPerMM
                        if (neededHeight > originalHeight) {
                            var expansion = neededHeight - originalHeight
                            console.log("[TicketRenderer] Element", i, "{{Productos}} expansion:", 
                                       expansion, "px (original:", originalHeight, "needed:", neededHeight, ")")
                            extraHeight += expansion
                        }
                    } catch (e) {
                        console.warn("Error calculating height:", e)
                    }
                }
            }
            if (extraHeight > 0) {
                console.log("[TicketRenderer] Total extra height:", extraHeight, "px")
            }
        }
        
        var totalHeight = baseHeight + extraHeight
        console.log("[TicketRenderer] Final height - Base:", baseHeight, "Extra:", extraHeight, "Total:", totalHeight)
        return totalHeight
    }
    color: Material.theme === Material.Dark ? "#1a1a1a" : "white"
    border.width: 2
    border.color: Material.theme === Material.Dark ? "white" : Material.primary
    visible: true
    opacity: 1.0
    z: 1
    
    onWidthChanged: console.log("[TicketRenderer] Width changed to:", width)
    onHeightChanged: console.log("[TicketRenderer] Height changed to:", height)
    onVisibleChanged: console.log("[TicketRenderer] Visibility changed to:", visible)
    
    // Cuadrícula de fondo (opcional)
    Canvas {
        id: gridCanvas
        anchors.fill: parent
        visible: root.showGrid
        
        onVisibleChanged: if (visible) requestPaint()
        
        Connections {
            target: root
            function onTicketWidthChanged() { if (gridCanvas.visible) gridCanvas.requestPaint() }
            function onTicketHeightChanged() { if (gridCanvas.visible) gridCanvas.requestPaint() }
        }
        
        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            ctx.strokeStyle = Material.theme === Material.Dark ? "#404040" : "#e0e0e0"
            ctx.lineWidth = 0.5
            
            // Líneas verticales cada 10mm
            for (var x = 0; x <= width; x += 10 * root.pixelsPerMM) {
                ctx.beginPath()
                ctx.moveTo(x, 0)
                ctx.lineTo(x, height)
                ctx.stroke()
            }
            
            // Líneas horizontales cada 10mm
            for (var y = 0; y <= height; y += 10 * root.pixelsPerMM) {
                ctx.beginPath()
                ctx.moveTo(0, y)
                ctx.lineTo(width, y)
                ctx.stroke()
            }
        }
    }
    
    // Elementos del ticket
    Repeater {
        model: root.ticketElements
        
        Rectangle {
            id: elementRect
            x: modelData.x * root.pixelsPerMM
            y: {
                var baseY = modelData.y * root.pixelsPerMM
                var offset = root.calculateDynamicOffset(index)
                var finalY = baseY + offset
                if (offset > 0) {
                    console.log("[TicketRenderer] Element", index, "Y position - Base:", baseY, 
                               "Offset:", offset, "Final:", finalY)
                }
                return finalY
            }
            width: modelData.width * root.pixelsPerMM
            // En modo preview, expandir altura si contiene {{Productos}}
            height: {
                if (root.usePreviewData && modelData.content && modelData.content.includes("{{Productos}}")) {
                    var textContent = root.replacePreviewVariables ? root.replacePreviewVariables(modelData.content) : modelData.content
                    var lineCount = (textContent.match(/\n/g) || []).length + 1
                    var lineHeight = modelData.fontSize * (root.pixelsPerMM / 3) * 1.2 // 1.2 = line spacing
                    var calculatedHeight = Math.max(modelData.height * root.pixelsPerMM, lineCount * lineHeight + 4)
                    console.log("[TicketRenderer] Element", index, "{{Productos}} height - Original:", 
                               modelData.height * root.pixelsPerMM, "Calculated:", calculatedHeight, 
                               "Lines:", lineCount)
                    return calculatedHeight
                }
                return modelData.height * root.pixelsPerMM
            }
            color: "transparent"
            border.width: root.selectedElementIndex === index ? 2 : (root.interactive ? 1 : 0)
            border.color: root.selectedElementIndex === index ? Material.accent : "#90A4AE"
            z: 15
            
            // Para separadores (líneas), renderizar con Canvas
            Canvas {
                anchors.fill: parent
                visible: modelData.type === "line"
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    ctx.strokeStyle = Material.theme === Material.Dark ? "white" : "black"
                    ctx.lineWidth = 2
                    
                    var y = height / 2
                    
                    if (modelData.lineStyle === "dotted") {
                        ctx.setLineDash([2, 4])
                    } else if (modelData.lineStyle === "dashed") {
                        ctx.setLineDash([8, 4])
                    } else {
                        ctx.setLineDash([])
                    }
                    
                    ctx.beginPath()
                    ctx.moveTo(0, y)
                    ctx.lineTo(width, y)
                    ctx.stroke()
                }
                
                Connections {
                    target: root
                    function onTicketElementsChanged() { parent.requestPaint() }
                }
            }
            
            // Contenido de texto
            Label {
                anchors.fill: parent
                anchors.margins: 2
                visible: modelData.type === "text"
                wrapMode: Text.WordWrap
                verticalAlignment: {
                    // En modo preview con {{Productos}}, alinear arriba para evitar cortes
                    if (root.usePreviewData && modelData.content && modelData.content.includes("{{Productos}}")) {
                        return Text.AlignTop
                    }
                    return Text.AlignVCenter
                }
                color: Material.theme === Material.Dark ? "white" : "black"
                
                // Si estamos en modo preview y hay función de reemplazo, usarla
                text: {
                    if (root.usePreviewData && root.replacePreviewVariables) {
                        return root.replacePreviewVariables(modelData.content)
                    }
                    
                    return modelData.content || ""
                }
                
                font.pixelSize: modelData.fontSize * (root.pixelsPerMM / 3)
                font.bold: modelData.bold || false
                horizontalAlignment: {
                    if (modelData.align === "center") return Text.AlignHCenter
                    if (modelData.align === "right") return Text.AlignRight
                    return Text.AlignLeft
                }
            }
            
            // Contenedor de imagen con DropArea
            Item {
                anchors.fill: parent
                visible: modelData.type === "image"
                
                DropArea {
                    id: imageDropArea
                    anchors.fill: parent
                    keys: ["text/uri-list"]
                    enabled: root.interactive
                    
                    onDropped: function(drop) {
                        if (drop.hasUrls) {
                            root.imageDropped(index, drop.urls[0].toString())
                        }
                    }
                    
                    Rectangle {
                        anchors.fill: parent
                        color: imageDropArea.containsDrag ? Material.accent : 
                               (modelData.content && modelData.content !== "") ? "transparent" : 
                               (Material.theme === Material.Dark ? "#2a2a2a" : "#f0f0f0")
                        border.color: imageDropArea.containsDrag ? Material.accent : 
                                      (Material.theme === Material.Dark ? "#555" : "#ccc")
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
                                color: Material.theme === Material.Dark ? "#888" : "#999"
                            }
                            
                            Label {
                                Layout.alignment: Qt.AlignHCenter
                                text: root.interactive ? "Arrastra imagen aquí" : "Sin imagen"
                                font.pixelSize: 9
                                opacity: 0.7
                                color: Material.theme === Material.Dark ? "#aaa" : "#999"
                            }
                        }
                    }
                }
            }
            
            // MouseArea para interacción (solo en modo interactivo)
            MouseArea {
                anchors.fill: parent
                drag.target: root.interactive ? parent : null
                drag.axis: Drag.XAndYAxis
                cursorShape: root.interactive ? Qt.SizeAllCursor : Qt.ArrowCursor
                z: 10
                enabled: root.interactive
                preventStealing: true
                propagateComposedEvents: false
                
                onClicked: {
                    if (root.interactive) {
                        root.elementSelected(index)
                    }
                }
                
                onReleased: {
                    if (root.interactive) {
                        // Actualizar posición en el modelo
                        var newX = Math.round((parent.x / root.pixelsPerMM) * 10) / 10
                        var newY = Math.round((parent.y / root.pixelsPerMM) * 10) / 10
                        root.elementPositionChanged(index, newX, newY)
                    }
                }
            }
            
            // Handles de redimensionamiento (solo visibles en modo interactivo cuando está seleccionado)
            Loader {
                active: root.interactive && root.showHandles && root.selectedElementIndex === index
                sourceComponent: Component {
                    Item {
                        anchors.fill: parent
                        
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
                            z: 20
                            
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.SizeFDiagCursor
                                drag.target: parent
                                drag.axis: Drag.XAndYAxis
                                preventStealing: true
                                
                                property real startX
                                property real startY
                                property real startWidth
                                property real startHeight
                                
                                onPressed: {
                                    startX = elementRect.x
                                    startY = elementRect.y
                                    startWidth = elementRect.width
                                    startHeight = elementRect.height
                                }
                                
                                onPositionChanged: {
                                    if (pressed) {
                                        var deltaX = parent.x - (elementRect.width - 4)
                                        var deltaY = parent.y - (elementRect.height - 4)
                                        
                                        elementRect.width = Math.max(10 * root.pixelsPerMM, startWidth + deltaX)
                                        elementRect.height = Math.max(5 * root.pixelsPerMM, startHeight + deltaY)
                                        
                                        parent.x = elementRect.width - 4
                                        parent.y = elementRect.height - 4
                                    }
                                }
                                
                                onReleased: {
                                    var newX = Math.round((elementRect.x / root.pixelsPerMM) * 10) / 10
                                    var newY = Math.round((elementRect.y / root.pixelsPerMM) * 10) / 10
                                    var newW = Math.round((elementRect.width / root.pixelsPerMM) * 10) / 10
                                    var newH = Math.round((elementRect.height / root.pixelsPerMM) * 10) / 10
                                    root.elementGeometryChanged(index, newX, newY, newW, newH)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
