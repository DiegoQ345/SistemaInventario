import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Effects
import SistemaInventario

Page {
    id: root
    title: qsTr("Diseñador de Tickets")
    
    // ── UI-only state ─────────────────────────────────────────────────────────
    // NOTA: pixelsPerMM es solo para VISUALIZACIÓN en el diseñador (96 DPI pantalla)
    // La impresión usa DPI dinámico del dispositivo (300 DPI PDF, 203 DPI térmica, etc)
    // IMPORTANTE: fontSize usa unidad especial con factor /3 para legibilidad en diseñador
    property real pixelsPerMM: 11.811024  // 300 DPI / 25.4 para visualización base
    property real canvasZoom: 1.0
    property bool propertiesPanelCollapsed: false
    property bool isPanning: false
    property point lastMousePos: Qt.point(0, 0)

    // ── ViewModel ─────────────────────────────────────────────────────────────
    TicketDesignerViewModel {
        id: viewModel
    }

    // Bridge: forward status notifications from ViewModel to the message bar
    Connections {
        target: viewModel
        function onShowStatus(message, isSuccess) {
            messageLabel.text = message
            messageBar.color = isSuccess ? Material.color(Material.Green)
                                         : Material.color(Material.Red)
            messageBar.visible = true
            messageTimer.restart()
        }
    }

    // Sincroniza todos los controles del panel de propiedades con el elemento seleccionado
    function syncPropertiesPanel() {
        var idx = viewModel.selectedElementIndex
        if (idx < 0) return
        var el = viewModel.ticketElements[idx]
        if (!el) return
        
        // Sincronizar controles básicos (aplica a todos los tipos)
        if (typeof labelTextField !== "undefined")
            labelTextField.text = el.label !== undefined ? el.label : ""
        if (typeof xSpinBox !== "undefined")
            xSpinBox.value = Math.round(el.x !== undefined ? el.x : 0)
        if (typeof ySpinBox !== "undefined")
            ySpinBox.value = Math.round(el.y !== undefined ? el.y : 0)
        if (typeof wSpinBox !== "undefined")
            wSpinBox.value = Math.max(1, Math.round(el.width !== undefined ? el.width : 1))
        if (typeof hSpinBox !== "undefined")
            hSpinBox.value = Math.max(1, Math.round(el.height !== undefined ? el.height : 1))
        
        // Sincronizar controles de texto (solo para elementos tipo "text")
        if (el.type === "text") {
            var fs = el.fontSize !== undefined ? el.fontSize : 12
            if (typeof fontSizeSlider !== "undefined")
                fontSizeSlider.value = fs
            if (typeof fontSizeSpinBox !== "undefined")
                fontSizeSpinBox.value = fs
            if (typeof boldCheckBox !== "undefined")
                boldCheckBox.checked = el.bold === true
            if (typeof alignComboBox !== "undefined")
                alignComboBox.currentIndex = el.align === "right" ? 2 : el.align === "center" ? 1 : 0
            if (typeof contentTextArea !== "undefined" && !contentTextArea.activeFocus)
                contentTextArea.text = el.content !== undefined ? el.content : ""
        }
    }

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
                            currentIndex: viewModel.voucherDesignType === "Factura" ? 1 : 0
                            onCurrentIndexChanged: {
                                var newType = currentIndex === 1 ? "Factura" : "Boleta"
                                if (viewModel.voucherDesignType !== newType) {
                                    viewModel.loadStandardTemplate(newType)
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
                            model: viewModel.ticketSizes.map(size => size.name)
                            currentIndex: viewModel.selectedSizeIndex
                            onCurrentIndexChanged: {
                                viewModel.setSelectedSizeIndex(currentIndex)
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
                            onClicked: saveNameDialog.open()
                        }
                        
                        Button {
                            text: "\uE7C5  " + qsTr("Vista Previa")
                            font.family: "Segoe MDL2 Assets"
                            onClicked: {
                                console.log("[TicketsPage] Opening preview dialog")
                                console.log("  - pixelsPerMM value:", root.pixelsPerMM)
                                console.log("  - Ticket size:", viewModel.ticketWidth, "x", viewModel.ticketHeight, "mm")
                                console.log("  - Elements count:", viewModel.ticketElements.length)
                                previewDialog.open()
                            }
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
                                    text: viewModel.ticketWidth + "mm × " + viewModel.ticketHeight + "mm"
                                    color: "white"
                                    font.pixelSize: 12
                                    font.bold: true
                                }
                            }
                            
                            // Fondo con cuadrícula
                            Rectangle {
                                id: ticketCanvas
                                anchors.centerIn: parent
                                width: viewModel.ticketWidth * pixelsPerMM
                                height: viewModel.ticketHeight * pixelsPerMM
                                color: Material.theme === Material.Dark ? "#1a1a1a" : "white"
                                border.width: 2
                                border.color: Material.theme === Material.Dark ? "white" : Material.primary
                                z: 10
                                scale: canvasZoom
                                transformOrigin: Item.Center
                        
                        // Cuadrícula de fondo
                        Canvas {
                            id: gridCanvas
                            anchors.fill: parent
                            
                            Connections {
                                target: viewModel
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
                            model: viewModel.ticketElements
                            
                            Rectangle {
                                id: elementRect
                                x: modelData.x * pixelsPerMM
                                y: modelData.y * pixelsPerMM
                                width: modelData.width * pixelsPerMM
                                height: modelData.height * pixelsPerMM
                                color: "transparent"
                                border.width: viewModel.selectedElementIndex === index ? 2 : 1
                                border.color: viewModel.selectedElementIndex === index ? Material.accent : "#90A4AE"
                                z: 15
                                
                                // Contenido del elemento
                                // Para separadores, mostrar línea visual
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
                                        target: viewModel
                                        function onTicketElementsChanged() { parent.requestPaint() }
                                    }
                                }
                                
                                // Para texto, mostrar el contenido
                                Label {
                                    anchors.fill: parent
                                    anchors.margins: 2
                                    text: modelData.content || ""
                                    font.pixelSize: modelData.fontSize * (pixelsPerMM / 3)
                                    font.bold: modelData.bold || false
                                    horizontalAlignment: modelData.align === "center" ? Text.AlignHCenter : 
                                                        modelData.align === "right" ? Text.AlignRight : Text.AlignLeft
                                    verticalAlignment: Text.AlignVCenter
                                    wrapMode: Text.WordWrap
                                    visible: modelData.type === "text"
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
                                                viewModel.setElementImageUrl(index, drop.urls[0].toString())
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
                                                    color: imageDropArea.containsDrag ? Material.accent : 
                                                           (Material.theme === Material.Dark ? "#888" : "#999")
                                                }
                                                
                                                Label {
                                                    Layout.alignment: Qt.AlignHCenter
                                                    text: imageDropArea.containsDrag ? "Suelta aquí" : "Arrastra imagen"
                                                    font.pixelSize: 8
                                                    color: Material.theme === Material.Dark ? "#aaa" : "#999"
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                // Hacer draggable
                                MouseArea {
                                    anchors.fill: parent
                                    drag.target: parent
                                    // Los separadores (líneas) solo se pueden mover horizontalmente
                                    drag.axis: modelData.type === "line" ? Drag.XAxis : Drag.XAndYAxis
                                    cursorShape: modelData.type === "line" ? Qt.SizeHorCursor : Qt.SizeAllCursor
                                    z: 10
                                    preventStealing: true
                                    propagateComposedEvents: false
                                    
                                    onClicked: {
                                        viewModel.setSelectedElementIndex(index)
                                    }
                                    
                                    onReleased: {
                                        // Actualizar posición en el modelo
                                        var newX = Math.round((parent.x / pixelsPerMM) * 10) / 10
                                        var newY = Math.round((parent.y / pixelsPerMM) * 10) / 10
                                        // Los separadores no cambian Y
                                        if (modelData.type === "line") {
                                            viewModel.updateElementPosition(index, newX, modelData.y)
                                        } else {
                                            viewModel.updateElementPosition(index, newX, newY)
                                        }
                                    }
                                }
                                
                                // Handles de redimensionamiento (solo visibles cuando está seleccionado)
                                // Para separadores, solo handles laterales (izquierda y derecha)
                                // Para otros elementos, handles en las 4 esquinas
                                
                                // Handle lateral izquierdo (solo para separadores)
                                Rectangle {
                                    x: -4
                                    y: parent.height / 2 - 4
                                    width: 8
                                    height: 8
                                    color: "white"
                                    border.color: Material.accent
                                    border.width: 2
                                    radius: 4
                                    visible: viewModel.selectedElementIndex === index && modelData.type === "line"
                                    z: 20
                                    
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.SizeHorCursor
                                        drag.target: parent
                                        
                                        property point startPos
                                        property real startWidth
                                        property real startX
                                        
                                        onPressed: function(mouse) {
                                            startPos = Qt.point(mouse.x, mouse.y)
                                            startWidth = elementRect.width
                                            startX = elementRect.x
                                        }
                                        
                                        onPositionChanged: function(mouse) {
                                            if (pressed) {
                                                var dx = parent.x + 4
                                                var newWidth = startWidth - dx
                                                
                                                if (newWidth > 10) {
                                                    elementRect.width = newWidth
                                                    elementRect.x = startX + dx
                                                }
                                            }
                                        }
                                        
                                        onReleased: {
                                            viewModel.updateElementGeometry(
                                                index,
                                                Math.round((elementRect.x / pixelsPerMM) * 10) / 10,
                                                modelData.y,
                                                Math.round((elementRect.width / pixelsPerMM) * 10) / 10,
                                                modelData.height
                                            )
                                        }
                                    }
                                }
                                
                                // Handle lateral derecho (solo para separadores)
                                Rectangle {
                                    x: parent.width - 4
                                    y: parent.height / 2 - 4
                                    width: 8
                                    height: 8
                                    color: "white"
                                    border.color: Material.accent
                                    border.width: 2
                                    radius: 4
                                    visible: viewModel.selectedElementIndex === index && modelData.type === "line"
                                    z: 20
                                    
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.SizeHorCursor
                                        drag.target: parent
                                        
                                        property point startPos
                                        property real startWidth
                                        
                                        onPressed: function(mouse) {
                                            startPos = Qt.point(mouse.x, mouse.y)
                                            startWidth = elementRect.width
                                        }
                                        
                                        onPositionChanged: function(mouse) {
                                            if (pressed) {
                                                var dx = parent.x - (elementRect.width - 4)
                                                var newWidth = startWidth + dx
                                                
                                                if (newWidth > 10) {
                                                    elementRect.width = newWidth
                                                }
                                            }
                                        }
                                        
                                        onReleased: {
                                            viewModel.updateElementGeometry(
                                                index,
                                                modelData.x,
                                                modelData.y,
                                                Math.round((elementRect.width / pixelsPerMM) * 10) / 10,
                                                modelData.height
                                            )
                                        }
                                    }
                                }
                                
                                // Handle esquina superior izquierda (solo para elementos NO separadores)
                                Rectangle {
                                    x: -4
                                    y: -4
                                    width: 8
                                    height: 8
                                    color: "white"
                                    border.color: Material.accent
                                    border.width: 2
                                    radius: 4
                                    visible: viewModel.selectedElementIndex === index && modelData.type !== "line"
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
                                            viewModel.updateElementGeometry(
                                                index,
                                                Math.round((elementRect.x / pixelsPerMM) * 10) / 10,
                                                Math.round((elementRect.y / pixelsPerMM) * 10) / 10,
                                                Math.round((elementRect.width / pixelsPerMM) * 10) / 10,
                                                Math.round((elementRect.height / pixelsPerMM) * 10) / 10
                                            )
                                        }
                                    }
                                }
                                
                                // Handle esquina superior derecha (solo para elementos NO separadores)
                                Rectangle {
                                    x: parent.width - 4
                                    y: -4
                                    width: 8
                                    height: 8
                                    color: "white"
                                    border.color: Material.accent
                                    border.width: 2
                                    radius: 4
                                    visible: viewModel.selectedElementIndex === index && modelData.type !== "line"
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
                                            viewModel.updateElementGeometry(
                                                index,
                                                modelData.x,
                                                Math.round((elementRect.y / pixelsPerMM) * 10) / 10,
                                                Math.round((elementRect.width / pixelsPerMM) * 10) / 10,
                                                Math.round((elementRect.height / pixelsPerMM) * 10) / 10
                                            )
                                        }
                                    }
                                }
                                
                                // Handle esquina inferior izquierda (solo para elementos NO separadores)
                                Rectangle {
                                    x: -4
                                    y: parent.height - 4
                                    width: 8
                                    height: 8
                                    color: "white"
                                    border.color: Material.accent
                                    border.width: 2
                                    radius: 4
                                    visible: viewModel.selectedElementIndex === index && modelData.type !== "line"
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
                                            viewModel.updateElementGeometry(
                                                index,
                                                Math.round((elementRect.x / pixelsPerMM) * 10) / 10,
                                                modelData.y,
                                                Math.round((elementRect.width / pixelsPerMM) * 10) / 10,
                                                Math.round((elementRect.height / pixelsPerMM) * 10) / 10
                                            )
                                        }
                                    }
                                }
                                
                                // Handle esquina inferior derecha (solo para elementos NO separadores)
                                Rectangle {
                                    x: parent.width - 4
                                    y: parent.height - 4
                                    width: 8
                                    height: 8
                                    color: "white"
                                    border.color: Material.accent
                                    border.width: 2
                                    radius: 4
                                    visible: viewModel.selectedElementIndex === index && modelData.type !== "line"
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
                                            viewModel.updateElementGeometry(
                                                index,
                                                modelData.x,
                                                modelData.y,
                                                Math.round((elementRect.width / pixelsPerMM) * 10) / 10,
                                                Math.round((elementRect.height / pixelsPerMM) * 10) / 10
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }
                }  // Fin Item canvasContainer
        }  // Fin ScrollView
    }  // Fin Item área de trabajo
                
                // Controles de zoom debajo del canvas
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 50
                    color: Material.background
                    border.width: 1
                    border.color: Material.frameColor
                    
                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 12
                        
                        Label {
                            text: qsTr("Zoom:")
                            font.pixelSize: 12
                        }
                        
                        Button {
                            text: "\uE71E"  // Minus icon
                            font.family: "Segoe MDL2 Assets"
                            font.pixelSize: 16
                            flat: true
                            enabled: canvasZoom > 0.5
                            onClicked: canvasZoom = Math.max(0.5, canvasZoom - 0.1)
                            ToolTip.visible: hovered
                            ToolTip.text: qsTr("Alejar")
                        }
                        
                        Slider {
                            id: zoomSlider
                            from: 0.5
                            to: 2.0
                            value: canvasZoom
                            stepSize: 0.1
                            Layout.preferredWidth: 150
                            onValueChanged: {
                                if (Math.abs(value - canvasZoom) > 0.01) {
                                    canvasZoom = value
                                }
                            }
                        }
                        
                        Label {
                            text: Math.round(canvasZoom * 100) + "%"
                            font.pixelSize: 12
                            font.bold: true
                            Layout.minimumWidth: 50
                            horizontalAlignment: Text.AlignHCenter
                        }
                        
                        Button {
                            text: "\uE710"  // Plus icon
                            font.family: "Segoe MDL2 Assets"
                            font.pixelSize: 16
                            flat: true
                            enabled: canvasZoom < 2.0
                            onClicked: canvasZoom = Math.min(2.0, canvasZoom + 0.1)
                            ToolTip.visible: hovered
                            ToolTip.text: qsTr("Acercar")
                        }
                        
                        Button {
                            text: "100%"
                            flat: true
                            onClicked: canvasZoom = 1.0
                            ToolTip.visible: hovered
                            ToolTip.text: qsTr("Restablecer zoom")
                        }
                    }
                }
            }  // Fin ColumnLayout
        }  // Fin Rectangle panel izquierdo
        
        // Panel derecho: Propiedades
        Rectangle {
            Layout.preferredWidth: propertiesPanelCollapsed ? 50 : 320
            Layout.fillHeight: true
            color: Material.background
            border.width: 1
            border.color: Material.frameColor
            
            Behavior on Layout.preferredWidth {
                NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
            }

            // Clic en cualquier parte del panel colapsado para expandirlo
            MouseArea {
                anchors.fill: parent
                enabled: propertiesPanelCollapsed
                cursorShape: Qt.PointingHandCursor
                z: 2
                onClicked: propertiesPanelCollapsed = false
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: propertiesPanelCollapsed ? 8 : 16
                spacing: propertiesPanelCollapsed ? 8 : 16
                
                // Botón para colapsar/expandir
                Button {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: propertiesPanelCollapsed ? 34 : 40
                    Layout.preferredHeight: propertiesPanelCollapsed ? 34 : 40
                    flat: true
                    text: propertiesPanelCollapsed ? "\uE76C" : "\uE76B"  // Chevron derecha/izquierda
                    font.family: "Segoe MDL2 Assets"
                    font.pixelSize: 16
                    onClicked: propertiesPanelCollapsed = !propertiesPanelCollapsed
                    ToolTip.visible: hovered
                    ToolTip.text: propertiesPanelCollapsed ? qsTr("Expandir panel") : qsTr("Contraer panel")
                }
                
                Label {
                    text: qsTr("Propiedades")
                    font.pixelSize: 18
                    font.bold: true
                    visible: !propertiesPanelCollapsed
                }
                
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    visible: !propertiesPanelCollapsed
                    ScrollBar.vertical.policy: ScrollBar.AsNeeded
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                    
                    ColumnLayout {
                        width: parent.parent.width - 40  // Padding adicional para evitar sobreposición
                        spacing: 12

                        // Sincroniza controles cada vez que cambia la selección O el modelo
                        Connections {
                            target: viewModel
                            function onSelectedElementIndexChanged() { Qt.callLater(syncPropertiesPanel) }
                            function onTicketElementsChanged()       { Qt.callLater(syncPropertiesPanel) }
                        }

                        // Mostrar propiedades si hay elemento seleccionado
                        GroupBox {
                            Layout.fillWidth: true
                            title: viewModel.selectedElementIndex >= 0 ? viewModel.ticketElements[viewModel.selectedElementIndex].label : qsTr("Ningún elemento seleccionado")
                            visible: viewModel.selectedElementIndex >= 0
                            
                            ColumnLayout {
                                width: parent.width
                                spacing: 12
                                
                                // Editar nombre del elemento
                                Label {
                                    text: qsTr("Nombre del Elemento")
                                    font.bold: true
                                    Layout.fillWidth: true
                                }
                                
                                TextField {
                                    id: labelTextField
                                    Layout.fillWidth: true
                                    placeholderText: qsTr("Nombre del elemento...")
                                    onEditingFinished: {
                                        if (viewModel.selectedElementIndex >= 0 && text.trim() !== "") {
                                            viewModel.updateElementProperty(viewModel.selectedElementIndex, "label", text)
                                        }
                                    }
                                }
                                
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 1
                                    color: Material.dividerColor
                                }
                                
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
                                        to: viewModel.ticketWidth
                                        onValueModified: {
                                            if (viewModel.selectedElementIndex >= 0) {
                                                viewModel.updateElementProperty(viewModel.selectedElementIndex, "x", value)
                                            }
                                        }
                                    }
                                    
                                    Label { text: "Y (mm):" }
                                    SpinBox {
                                        id: ySpinBox
                                        Layout.fillWidth: true
                                        from: 0
                                        to: viewModel.ticketHeight
                                        // Los separadores no permiten cambiar Y
                                        enabled: viewModel.selectedElementIndex >= 0 && 
                                                viewModel.ticketElements[viewModel.selectedElementIndex].type !== "line"
                                        onValueModified: {
                                            if (viewModel.selectedElementIndex >= 0) {
                                                viewModel.updateElementProperty(viewModel.selectedElementIndex, "y", value)
                                            }
                                        }
                                    }
                                    
                                    Label { text: "Ancho (mm):" }
                                    SpinBox {
                                        id: wSpinBox
                                        Layout.fillWidth: true
                                        from: 1
                                        to: viewModel.ticketWidth
                                        onValueModified: {
                                            if (viewModel.selectedElementIndex >= 0) {
                                                viewModel.updateElementProperty(viewModel.selectedElementIndex, "width", value)
                                            }
                                        }
                                    }
                                    
                                    Label { text: "Alto (mm):" }
                                    SpinBox {
                                        id: hSpinBox
                                        Layout.fillWidth: true
                                        from: 1
                                        to: viewModel.ticketHeight
                                        // Los separadores no permiten cambiar altura
                                        enabled: viewModel.selectedElementIndex >= 0 && 
                                                viewModel.ticketElements[viewModel.selectedElementIndex].type !== "line"
                                        onValueModified: {
                                            if (viewModel.selectedElementIndex >= 0) {
                                                viewModel.updateElementProperty(viewModel.selectedElementIndex, "height", value)
                                            }
                                        }
                                    }
                                }
                                
                                // Propiedades de texto
                                Label {
                                    text: qsTr("Formato de Texto")
                                    font.bold: true
                                    Layout.fillWidth: true
                                    visible: viewModel.selectedElementIndex >= 0 && viewModel.ticketElements[viewModel.selectedElementIndex].type === "text"
                                }
                                
                                GridLayout {
                                    Layout.fillWidth: true
                                    columns: 2
                                    columnSpacing: 8
                                    rowSpacing: 8
                                    visible: viewModel.selectedElementIndex >= 0 && viewModel.ticketElements[viewModel.selectedElementIndex].type === "text"
                                    
                                    Label { text: "Contenido:" }
                                    TextArea {
                                        id: contentTextArea
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 60
                                        wrapMode: TextArea.WordWrap
                                        
                                        // Padding uniforme para alineación
                                        leftPadding: 12
                                        rightPadding: 12
                                        topPadding: 8
                                        bottomPadding: 8
                                        
                                        // Binding para mostrar el contenido actual del elemento seleccionado
                                        text: {
                                            if (viewModel.selectedElementIndex >= 0) {
                                                var elem = viewModel.ticketElements[viewModel.selectedElementIndex]
                                                return elem ? (elem.content || "") : ""
                                            }
                                            return ""
                                        }
                                        
                                        // Actualización en tiempo real mientras se escribe
                                        onTextChanged: {
                                            if (viewModel.selectedElementIndex >= 0 && activeFocus) {
                                                viewModel.updateElementProperty(viewModel.selectedElementIndex, "content", text)
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
                                                if (viewModel.selectedElementIndex >= 0) {
                                                    viewModel.updateElementProperty(viewModel.selectedElementIndex, "fontSize", 8)
                                                }
                                            }
                                        }
                                        Button {
                                            text: "Normal"
                                            Layout.fillWidth: true
                                            font.pixelSize: 11
                                            flat: true
                                            onClicked: {
                                                if (viewModel.selectedElementIndex >= 0) {
                                                    viewModel.updateElementProperty(viewModel.selectedElementIndex, "fontSize", 12)
                                                }
                                            }
                                        }
                                        Button {
                                            text: "Grande"
                                            Layout.fillWidth: true
                                            font.pixelSize: 13
                                            flat: true
                                            onClicked: {
                                                if (viewModel.selectedElementIndex >= 0) {
                                                    viewModel.updateElementProperty(viewModel.selectedElementIndex, "fontSize", 16)
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
                                                if (viewModel.selectedElementIndex >= 0) {
                                                    viewModel.updateElementProperty(viewModel.selectedElementIndex, "fontSize", 20)
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
                                            onMoved: {
                                                if (viewModel.selectedElementIndex >= 0) {
                                                    viewModel.updateElementProperty(viewModel.selectedElementIndex, "fontSize", Math.round(value))
                                                }
                                            }
                                        }
                                        
                                        SpinBox {
                                            id: fontSizeSpinBox
                                            Layout.preferredWidth: 80
                                            from: 4
                                            to: 48
                                            onValueModified: {
                                                if (viewModel.selectedElementIndex >= 0) {
                                                    viewModel.updateElementProperty(viewModel.selectedElementIndex, "fontSize", value)
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
                                        font.pixelSize: viewModel.selectedElementIndex >= 0 ? viewModel.ticketElements[viewModel.selectedElementIndex].fontSize : 12
                                        font.bold: viewModel.selectedElementIndex >= 0 ? viewModel.ticketElements[viewModel.selectedElementIndex].bold : false
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
                                            id: boldCheckBox
                                            text: "Negrita"
                                            onToggled: {
                                                if (viewModel.selectedElementIndex >= 0) {
                                                    viewModel.updateElementProperty(viewModel.selectedElementIndex, "bold", checked)
                                                }
                                            }
                                        }
                                    }
                                    
                                    Label { text: "Alineación:" }
                                    ComboBox {
                                        id: alignComboBox
                                        Layout.fillWidth: true
                                        model: ["left", "center", "right"]
                                        displayText: currentText === "left" ? "Izquierda" : 
                                                    currentText === "center" ? "Centro" : "Derecha"
                                        onActivated: {
                                            if (viewModel.selectedElementIndex >= 0) {
                                                viewModel.updateElementProperty(viewModel.selectedElementIndex, "align", model[currentIndex])
                                            }
                                        }
                                    }
                                }
                                
                                // Propiedades de separador (línea)
                                Label {
                                    text: qsTr("Estilo de Línea")
                                    font.bold: true
                                    Layout.fillWidth: true
                                    visible: viewModel.selectedElementIndex >= 0 && viewModel.ticketElements[viewModel.selectedElementIndex].type === "line"
                                }
                                
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 8
                                    visible: viewModel.selectedElementIndex >= 0 && viewModel.ticketElements[viewModel.selectedElementIndex].type === "line"
                                    
                                    Label { 
                                        text: "Tipo de línea:" 
                                        font.pixelSize: 11
                                    }
                                    
                                    ButtonGroup {
                                        id: lineStyleGroup
                                    }
                                    
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8
                                        
                                        Button {
                                            Layout.fillWidth: true
                                            text: "━━━"
                                            font.pixelSize: 14
                                            flat: true
                                            checkable: true
                                            checked: viewModel.selectedElementIndex >= 0 && 
                                                     viewModel.ticketElements[viewModel.selectedElementIndex].lineStyle === "solid"
                                            ButtonGroup.group: lineStyleGroup
                                            onClicked: {
                                                if (viewModel.selectedElementIndex >= 0) {
                                                    viewModel.updateElementProperty(viewModel.selectedElementIndex, "lineStyle", "solid")
                                                }
                                            }
                                            ToolTip.visible: hovered
                                            ToolTip.text: "Línea sólida"
                                        }
                                        
                                        Button {
                                            Layout.fillWidth: true
                                            text: "╌╌╌"
                                            font.pixelSize: 14
                                            flat: true
                                            checkable: true
                                            checked: viewModel.selectedElementIndex >= 0 && 
                                                     viewModel.ticketElements[viewModel.selectedElementIndex].lineStyle === "dashed"
                                            ButtonGroup.group: lineStyleGroup
                                            onClicked: {
                                                if (viewModel.selectedElementIndex >= 0) {
                                                    viewModel.updateElementProperty(viewModel.selectedElementIndex, "lineStyle", "dashed")
                                                }
                                            }
                                            ToolTip.visible: hovered
                                            ToolTip.text: "Línea discontinua"
                                        }
                                        
                                        Button {
                                            Layout.fillWidth: true
                                            text: "┄┄┄"
                                            font.pixelSize: 14
                                            flat: true
                                            checkable: true
                                            checked: viewModel.selectedElementIndex >= 0 && 
                                                     viewModel.ticketElements[viewModel.selectedElementIndex].lineStyle === "dotted"
                                            ButtonGroup.group: lineStyleGroup
                                            onClicked: {
                                                if (viewModel.selectedElementIndex >= 0) {
                                                    viewModel.updateElementProperty(viewModel.selectedElementIndex, "lineStyle", "dotted")
                                                }
                                            }
                                            ToolTip.visible: hovered
                                            ToolTip.text: "Línea punteada"
                                        }
                                    }
                                    
                                    // Vista previa de la línea
                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 40
                                        color: Material.theme === Material.Dark ? "#2a2a2a" : "#f5f5f5"
                                        border.color: Material.frameColor
                                        border.width: 1
                                        radius: 4
                                        
                                        Canvas {
                                            anchors.fill: parent
                                            anchors.margins: 8
                                            
                                            onPaint: {
                                                if (viewModel.selectedElementIndex < 0) return
                                                
                                                var ctx = getContext("2d")
                                                ctx.clearRect(0, 0, width, height)
                                                ctx.strokeStyle = Material.theme === Material.Dark ? "white" : "black"
                                                ctx.lineWidth = 2
                                                
                                                var y = height / 2
                                                var lineStyle = viewModel.ticketElements[viewModel.selectedElementIndex].lineStyle
                                                
                                                if (lineStyle === "dotted") {
                                                    ctx.setLineDash([2, 4])
                                                } else if (lineStyle === "dashed") {
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
                                                target: viewModel
                                                function onTicketElementsChanged() { parent.requestPaint() }
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
                                
                                // Configuración de viñetas para productos
                                Label {
                                    text: qsTr("Viñeta para Productos")
                                    font.bold: true
                                    font.pixelSize: 11
                                }
                                
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8
                                    
                                    Label {
                                        text: qsTr("Carácter:")
                                        font.pixelSize: 10
                                    }
                                    
                                    ComboBox {
                                        id: bulletComboBox
                                        Layout.fillWidth: true
                                        model: ["•", "-", "*", "▪", "►", "○", "▸", "✓"]
                                        currentIndex: model.indexOf(viewModel.bulletCharacter)
                                        onCurrentTextChanged: {
                                            viewModel.setBulletCharacter(currentText)
                                        }
                                        displayText: currentText + "  (" + currentText + ")"
                                    }
                                }
                                
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 1
                                    color: Material.dividerColor
                                    Layout.topMargin: 8
                                    Layout.bottomMargin: 8
                                }
                                
                                // Botones de gestión de elementos
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 4
                                    
                                    Button {
                                        text: "\uE710"  // Add icon
                                        font.family: "Segoe MDL2 Assets"
                                        Layout.fillWidth: true
                                        font.pixelSize: 14
                                        onClicked: addElementMenu.open()
                                        ToolTip.visible: hovered
                                        ToolTip.text: qsTr("Agregar elemento")
                                        
                                        Menu {
                                            id: addElementMenu
                                            
                                            MenuItem {
                                                text: "\uE8D2  Texto"
                                                font.family: "Segoe MDL2 Assets"
                                                onTriggered: viewModel.addTextElement()
                                            }
                                            
                                            MenuItem {
                                                text: "\uE81C  Separador Sólido"
                                                font.family: "Segoe MDL2 Assets"
                                                onTriggered: viewModel.addSeparatorElement("solid")
                                            }
                                            
                                            MenuItem {
                                                text: "\uE81C  Separador Punteado"
                                                font.family: "Segoe MDL2 Assets"
                                                onTriggered: viewModel.addSeparatorElement("dotted")
                                            }
                                            
                                            MenuItem {
                                                text: "\uE81C  Separador Discontinuo"
                                                font.family: "Segoe MDL2 Assets"
                                                onTriggered: viewModel.addSeparatorElement("dashed")
                                            }
                                            
                                            MenuItem {
                                                text: "\uEB9F  Imagen"
                                                font.family: "Segoe MDL2 Assets"
                                                onTriggered: viewModel.addImageElement()
                                            }
                                        }
                                    }
                                    
                                    Button {
                                        text: "\uE74D"  // Delete icon
                                        font.family: "Segoe MDL2 Assets"
                                        Layout.fillWidth: true
                                        font.pixelSize: 14
                                        enabled: viewModel.selectedElementIndex >= 0
                                        onClicked: viewModel.deleteSelectedElement()
                                        ToolTip.visible: hovered
                                        ToolTip.text: qsTr("Eliminar elemento seleccionado")
                                    }
                                }
                                
                                Repeater {
                                    model: viewModel.ticketElements
                                    
                                    ItemDelegate {
                                        Layout.fillWidth: true
                                        text: modelData.label
                                        highlighted: viewModel.selectedElementIndex === index
                                        
                                        onClicked: {
                                            viewModel.setSelectedElementIndex(index)
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
                    }  // Fin ColumnLayout del ScrollView
                }  // Fin ScrollView
            }  // Fin ColumnLayout del panel derecho
        }  // Fin Rectangle panel derecho
    }  // Fin RowLayout principal
    
    // Diálogo de vista previa
    TicketPreviewDialog {
        id: previewDialog
        viewModel: viewModel
        pixelsPerMM: root.pixelsPerMM
    }
    // Diálogo para cargar diseño guardado
    TicketLoadDialog {
        id: loadDialog
        viewModel: viewModel
    }

    // Diálogo para ingresar nombre del diseño
    TicketSaveNameDialog {
        id: saveNameDialog
        viewModel: viewModel
    }

    // Diálogo de referencias de variables
    VariablesReferenceDialog {
        id: variablesReferenceDialog
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

