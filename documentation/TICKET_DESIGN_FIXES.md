# 🔧 Correcciones Críticas - Sistema de Diseño de Tickets

**Prioridad:** ALTA  
**Impacto:** Mejora la precisión y confiabilidad del sistema

---

## 🚨 PROBLEMA CRÍTICO 1: Mezcla de Layouts y Posicionamiento Manual

### Código Actual (INCORRECTO)

```qml
// qml/pages/TicketsPage.qml:342-556

RowLayout {
    anchors.fill: parent
    spacing: 0
    
    Rectangle {
        Layout.fillWidth: true        // ❌ Layout automático
        Layout.fillHeight: true
        
        ColumnLayout {                // ❌ Nested layout
            anchors.fill: parent
            
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                
                ScrollView {
                    anchors.fill: parent
                    
                    Item {
                        id: canvasContainer
                        
                        Rectangle {
                            id: ticketCanvas
                            anchors.centerIn: parent  // ⚠️ Anchor en canvas
                            width: ticketWidth * pixelsPerMM   // Manual
                            height: ticketHeight * pixelsPerMM
                            
                            Repeater {
                                model: ticketElements
                                delegate: Rectangle {
                                    x: modelData.x * pixelsPerMM  // ❌ Manual dentro de Layout
                                    y: modelData.y * pixelsPerMM
                                    
                                    Label {
                                        anchors.fill: parent  // ⚠️ Anchor en elemento posicionado
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
```

### Código Corregido (CORRECTO)

```qml
// qml/pages/TicketsPage.qml - VERSIÓN CORREGIDA

RowLayout {
    anchors.fill: parent
    spacing: 0
    
    // Panel izquierdo: Canvas de edición
    Item {  // ✅ Cambiar Rectangle a Item
        Layout.fillWidth: true
        Layout.fillHeight: true
        
        Rectangle {
            anchors.fill: parent
            color: Material.theme === Material.Dark ? "#1a1a1a" : "#e0e0e0"
        }
        
        ColumnLayout {
            anchors.fill: parent
            spacing: 16
            
            // Toolbar superior (Layouts OK aquí)
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                // ... toolbar content
            }
            
            // Área de trabajo SIN LAYOUTS
            Item {  // ✅ Item en lugar de Layout
                Layout.fillWidth: true
                Layout.fillHeight: true
                
                ScrollView {
                    anchors.fill: parent
                    clip: true
                    
                    Item {
                        id: canvasContainer
                        // Tamaño suficiente para scroll
                        width: Math.max(scrollView.width, ticketCanvas.width + 300)
                        height: Math.max(scrollView.height, ticketCanvas.height + 300)
                        
                        // Canvas del ticket - SOLO POSICIONAMIENTO MANUAL
                        Item {  // ✅ Item puro, sin Rectangle
                            id: ticketCanvas
                            // Centrado con cálculo manual
                            x: (parent.width - width) / 2
                            y: (parent.height - height) / 2
                            width: ticketWidth * pixelsPerMM
                            height: ticketHeight * pixelsPerMM
                            clip: true  // ✅ CRÍTICO: evita elementos fuera
                            
                            // Fondo del ticket
                            Rectangle {
                                anchors.fill: parent
                                color: Material.theme === Material.Dark ? "#1a1a1a" : "white"
                                border.width: 2
                                border.color: Material.primary
                            }
                            
                            // Cuadrícula
                            Canvas {
                                id: gridCanvas
                                anchors.fill: parent
                                z: 1
                                // ... paint logic
                            }
                            
                            // Elementos del ticket - SOLO X, Y, WIDTH, HEIGHT
                            Repeater {
                                model: ticketElements
                                delegate: Item {  // ✅ Item raíz del delegate
                                    id: elementContainer
                                    x: modelData.x * pixelsPerMM
                                    y: modelData.y * pixelsPerMM
                                    width: modelData.width * pixelsPerMM
                                    height: modelData.height * pixelsPerMM
                                    z: 15
                                    
                                    // Fondo con borde
                                    Rectangle {
                                        id: elementBorder
                                        anchors.fill: parent
                                        color: "transparent"
                                        border.width: selectedElementIndex === index ? 2 : 1
                                        border.color: selectedElementIndex === index ? 
                                            Material.accent : "#90A4AE"
                                    }
                                    
                                    // Contenido del elemento - SIN ANCHORS
                                    Label {
                                        x: 2
                                        y: 2
                                        width: parent.width - 4   // ✅ Cálculo manual
                                        height: parent.height - 4
                                        text: modelData.content
                                        font.pixelSize: modelData.fontSize * (pixelsPerMM / 3)
                                        font.bold: modelData.bold
                                        horizontalAlignment: modelData.align === "center" ? 
                                            Text.AlignHCenter : 
                                            modelData.align === "right" ? 
                                            Text.AlignRight : Text.AlignLeft
                                        verticalAlignment: Text.AlignVCenter
                                        wrapMode: Text.WordWrap
                                        visible: modelData.type !== "image"
                                        color: Material.theme === Material.Dark ? "white" : "black"
                                    }
                                    
                                    // Drag con validación de límites
                                    MouseArea {
                                        anchors.fill: parent
                                        drag.target: parent
                                        drag.axis: Drag.XAndYAxis
                                        
                                        // ✅ VALIDAR LÍMITES
                                        drag.minimumX: 0
                                        drag.maximumX: (ticketWidth - modelData.width) * pixelsPerMM
                                        drag.minimumY: 0
                                        drag.maximumY: (ticketHeight - modelData.height) * pixelsPerMM
                                        
                                        cursorShape: Qt.SizeAllCursor
                                        
                                        onClicked: {
                                            selectedElementIndex = index
                                        }
                                        
                                        onReleased: {
                                            // Convertir a mm con validación
                                            var newX = parent.x / pixelsPerMM
                                            var newY = parent.y / pixelsPerMM
                                            
                                            // ✅ ASEGURAR QUE ESTÁ DENTRO DEL CANVAS
                                            newX = Math.max(0, Math.min(newX, 
                                                ticketWidth - ticketElements[index].width))
                                            newY = Math.max(0, Math.min(newY, 
                                                ticketHeight - ticketElements[index].height))
                                            
                                            ticketElements[index].x = Math.round(newX * 10) / 10
                                            ticketElements[index].y = Math.round(newY * 10) / 10
                                            root.ticketElementsChanged()
                                        }
                                    }
                                    
                                    // Handles de redimensionamiento (mantener lógica actual)
                                    // ... código de handles
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Panel derecho: Propiedades (Layouts OK aquí)
    Rectangle {
        Layout.preferredWidth: 320
        Layout.fillHeight: true
        // ... panel de propiedades
    }
}
```

---

## 🚨 PROBLEMA CRÍTICO 2: Validación de Límites en Redimensionamiento

### Código Actual (INCORRECTO)

```qml
// Handle esquina inferior derecha
Rectangle {
    x: parent.width - 4
    y: parent.height - 4
    
    MouseArea {
        onPositionChanged: function(mouse) {
            if (pressed) {
                var dx = parent.x - (elementRect.width - 4)
                var dy = parent.y - (elementRect.height - 4)
                
                var newWidth = startWidth + dx
                var newHeight = startHeight + dy
                
                // ❌ NO VALIDA LÍMITES
                if (newWidth > 10 && newHeight > 10) {
                    elementRect.width = newWidth
                    elementRect.height = newHeight
                }
            }
        }
        
        onReleased: {
            // ❌ PUEDE QUEDAR FUERA DEL CANVAS
            ticketElements[index].width = Math.round((elementRect.width / pixelsPerMM) * 10) / 10
            ticketElements[index].height = Math.round((elementRect.height / pixelsPerMM) * 10) / 10
        }
    }
}
```

### Código Corregido (CORRECTO)

```qml
// Handle esquina inferior derecha - VERSIÓN CORREGIDA
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
                var dx = parent.x - (elementRect.width - 4)
                var dy = parent.y - (elementRect.height - 4)
                
                var newWidth = startWidth + dx
                var newHeight = startHeight + dy
                
                // ✅ VALIDAR LÍMITES DEL CANVAS
                var maxWidth = (ticketWidth * pixelsPerMM) - startX
                var maxHeight = (ticketHeight * pixelsPerMM) - startY
                
                if (newWidth > 10 && newWidth <= maxWidth && 
                    newHeight > 10 && newHeight <= maxHeight) {
                    elementRect.width = newWidth
                    elementRect.height = newHeight
                }
            }
        }
        
        onReleased: {
            // ✅ VALIDAR Y GUARDAR
            var newWidthMM = elementRect.width / pixelsPerMM
            var newHeightMM = elementRect.height / pixelsPerMM
            var xMM = elementRect.x / pixelsPerMM
            var yMM = elementRect.y / pixelsPerMM
            
            // Asegurar que no excede el canvas
            newWidthMM = Math.min(newWidthMM, ticketWidth - xMM)
            newHeightMM = Math.min(newHeightMM, ticketHeight - yMM)
            
            ticketElements[index].width = Math.round(newWidthMM * 10) / 10
            ticketElements[index].height = Math.round(newHeightMM * 10) / 10
            root.ticketElementsChanged()
            
            // ✅ FEEDBACK VISUAL
            if (newWidthMM >= ticketWidth - xMM || 
                newHeightMM >= ticketHeight - yMM) {
                showMessage("Elemento ajustado al límite del canvas", "info")
            }
        }
    }
}
```

---

## 🚨 PROBLEMA MEDIO: Función de Validación Global

### Agregar Función de Validación

```qml
// qml/pages/TicketsPage.qml

Page {
    id: root
    
    // ... propiedades existentes
    
    // ✅ FUNCIÓN DE VALIDACIÓN GLOBAL
    function validateElementBounds(index) {
        if (index < 0 || index >= ticketElements.length) return
        
        var element = ticketElements[index]
        var changed = false
        
        // Validar X
        if (element.x < 0) {
            element.x = 0
            changed = true
        }
        if (element.x + element.width > ticketWidth) {
            element.x = ticketWidth - element.width
            if (element.x < 0) {
                element.x = 0
                element.width = ticketWidth
            }
            changed = true
        }
        
        // Validar Y
        if (element.y < 0) {
            element.y = 0
            changed = true
        }
        if (element.y + element.height > ticketHeight) {
            element.y = ticketHeight - element.height
            if (element.y < 0) {
                element.y = 0
                element.height = ticketHeight
            }
            changed = true
        }
        
        // Validar tamaños mínimos
        if (element.width < 1) {
            element.width = 1
            changed = true
        }
        if (element.height < 1) {
            element.height = 1
            changed = true
        }
        
        if (changed) {
            ticketElements[index] = element
            ticketElementsChanged()
            showMessage("Elemento ajustado a límites válidos", "warning")
        }
        
        return !changed  // true si es válido
    }
    
    // ✅ VALIDAR TODOS LOS ELEMENTOS
    function validateAllElements() {
        var invalidCount = 0
        for (var i = 0; i < ticketElements.length; i++) {
            if (!validateElementBounds(i)) {
                invalidCount++
            }
        }
        
        if (invalidCount > 0) {
            showMessage(invalidCount + " elemento(s) ajustado(s) a límites válidos", "warning")
        }
        
        return invalidCount === 0
    }
    
    // ✅ LLAMAR EN LOAD
    function loadDesign(templateId) {
        var template = templateRepository.getTemplate(templateId)
        if (!template || !template.id) {
            showMessage("Error al cargar el diseño", "error")
            return
        }
        
        try {
            var layoutData = JSON.parse(template.layoutJson)
            
            if (layoutData.size) {
                ticketWidth = layoutData.size.width
                ticketHeight = layoutData.size.height
            }
            
            if (layoutData.elements) {
                ticketElements = layoutData.elements
                
                // ✅ VALIDAR DESPUÉS DE CARGAR
                validateAllElements()
            }
            
            showMessage("Diseño cargado: " + template.name, "success")
        } catch (e) {
            showMessage("Error al parsear el diseño: " + e.message, "error")
        }
    }
    
    // ✅ VALIDAR ANTES DE GUARDAR
    function performSave(name) {
        // Validar primero
        if (!validateAllElements()) {
            showMessage("Algunos elementos fueron ajustados. Verifica el diseño.", "warning")
        }
        
        var layoutData = {
            version: "1.0",  // ✅ Agregar versión
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
            savedTemplates = templateRepository.getAllTemplates()
        } else {
            showMessage("Error al guardar el diseño", "error")
        }
    }
}
```

---

## 🔍 MEJORA: Guías Visuales de Límites

### Agregar Zona Segura

```qml
// Dentro de ticketCanvas

// Zona segura (5mm de margen)
Rectangle {
    id: safeZone
    x: 5 * pixelsPerMM
    y: 5 * pixelsPerMM
    width: (ticketWidth - 10) * pixelsPerMM
    height: (ticketHeight - 10) * pixelsPerMM
    color: "transparent"
    border.color: Material.color(Material.Orange)
    border.width: 1
    opacity: showSafeZone ? 0.4 : 0
    z: 5
    
    Behavior on opacity {
        NumberAnimation { duration: 200 }
    }
}

// Toggle en toolbar
CheckBox {
    text: qsTr("Mostrar zona segura")
    checked: showSafeZone
    onCheckedChanged: showSafeZone = checked
}

// Propiedad
property bool showSafeZone: true
```

### Indicador de Overflow

```qml
// Dentro del delegate del Repeater

// Indicador de overflow
Rectangle {
    anchors.fill: parent
    color: "red"
    opacity: isOutOfBounds ? 0.3 : 0
    z: 100
    
    Behavior on opacity {
        NumberAnimation { duration: 150 }
    }
    
    Label {
        anchors.centerIn: parent
        text: "⚠"
        font.pixelSize: 24
        color: "white"
        visible: isOutOfBounds
    }
}

property bool isOutOfBounds: {
    var xMM = elementRect.x / pixelsPerMM
    var yMM = elementRect.y / pixelsPerMM
    var wMM = elementRect.width / pixelsPerMM
    var hMM = elementRect.height / pixelsPerMM
    
    return xMM < 0 || yMM < 0 || 
           (xMM + wMM) > ticketWidth || 
           (yMM + hMM) > ticketHeight
}
```

---

## 📋 Checklist de Implementación

### Fase 1: Correcciones Críticas (2-4 horas)
- [ ] Refactorizar estructura de layouts en TicketsPage.qml
- [ ] Cambiar `Rectangle` a `Item` para canvas del ticket
- [ ] Eliminar todos los `anchors` de elementos del ticket
- [ ] Agregar `clip: true` al ticketCanvas
- [ ] Implementar validación en drag.minimumX/Y y maximumX/Y

### Fase 2: Validación Robusta (1-2 horas)
- [ ] Implementar función `validateElementBounds(index)`
- [ ] Implementar función `validateAllElements()`
- [ ] Llamar validación en `loadDesign()`
- [ ] Llamar validación en `performSave()`
- [ ] Agregar validación en todos los handles de resize

### Fase 3: Mejoras Visuales (1-2 horas)
- [ ] Agregar zona segura (safe zone)
- [ ] Implementar indicador de overflow
- [ ] Agregar feedback visual cuando se ajustan límites
- [ ] Mejorar mensajes de advertencia

### Fase 4: Pruebas (2 horas)
- [ ] Probar arrastrar elementos al borde
- [ ] Probar redimensionar contra límites
- [ ] Probar cargar diseños antiguos
- [ ] Probar con diferentes tamaños de ticket (58mm, 80mm)
- [ ] Verificar que PDF genera correctamente
- [ ] Probar en impresora térmica real

---

## 🧪 Pruebas de Validación

### Test 1: Drag fuera de límites
```
1. Arrastrar elemento al borde derecho del canvas
2. Soltar fuera del área visible
3. Resultado esperado: Elemento se ajusta automáticamente dentro
```

### Test 2: Resize excediendo canvas
```
1. Redimensionar elemento con handle inferior derecho
2. Intentar hacerlo más grande que el canvas
3. Resultado esperado: Se detiene en el límite máximo
```

### Test 3: Load de diseño inválido
```
1. Editar JSON manualmente con coordenadas negativas
2. Cargar diseño modificado
3. Resultado esperado: Elementos se ajustan automáticamente + mensaje de advertencia
```

### Test 4: Cambio de tamaño de ticket
```
1. Crear diseño en 80mm
2. Cambiar tamaño a 58mm
3. Resultado esperado: Elementos fuera del nuevo tamaño se ajustan + advertencia
```

---

## 📊 Impacto Estimado

| Corrección | Tiempo | Impacto | Riesgo |
|------------|--------|---------|--------|
| Refactorizar layouts | 3h | Alto | Medio |
| Validación de límites | 2h | Alto | Bajo |
| Guías visuales | 1h | Medio | Bajo |
| Pruebas | 2h | Alto | - |

**Total:** ~8 horas de desarrollo + pruebas

**Beneficios:**
- ✅ Elimina elementos fuera del área imprimible
- ✅ Mejora experiencia del usuario
- ✅ Previene errores de diseño
- ✅ Diseños más confiables
- ✅ Mejor feedback visual

---

## 📝 Notas de Migración

### Para diseños existentes en BD:

```sql
-- Agregar columna de versión
ALTER TABLE ticket_templates ADD COLUMN version TEXT DEFAULT '1.0';

-- Script de migración (ejecutar en DatabaseManager)
UPDATE ticket_templates 
SET layout_json = (
    SELECT json_object(
        'version', '1.0',
        'size', json_extract(layout_json, '$.size'),
        'elements', json_extract(layout_json, '$.elements')
    )
)
WHERE layout_json NOT LIKE '%"version"%';
```

### Verificar migración:

```qml
function loadDesign(templateId) {
    var template = templateRepository.getTemplate(templateId)
    var layoutData = JSON.parse(template.layoutJson)
    
    // Detectar versión
    if (!layoutData.version) {
        console.warn("Diseño sin versión, aplicando migración")
        layoutData = {
            version: "1.0",
            size: layoutData.size || { width: 80, height: 200 },
            elements: layoutData.elements || layoutData  // Backward compat
        }
    }
    
    // Validar elementos
    validateAllElements()
}
```

---

**Fecha de creación:** 2 de Marzo de 2026  
**Prioridad:** ALTA  
**Estado:** PENDIENTE DE IMPLEMENTACIÓN
