# 🔍 DEBUG: Flujo de Diseño de Tickets No Se Respeta en Impresión

## 🚨 PROBLEMA REPORTADO
La impresión no respeta el diseño cargado del ticket.

## 📋 FLUJO COMPLETO ANALIZADO

### **1️⃣ FASE: GUARDAR DISEÑO (TicketsPage.qml)**

**Ubicación**: `qml/pages/TicketsPage.qml` línea 1490-1510

```javascript
function performSave(name) {
    var layoutData = {
        size: {
            width: ticketWidth,    // ej: 80
            height: ticketHeight   // ej: 200
        },
        elements: ticketElements   // Array de elementos
    }
    var layoutJson = JSON.stringify(layoutData)
    var id = templateRepository.saveTemplate(name, layoutJson)  // ✅ Se guarda en DB
}
```

**✅ VERIFICADO**: El JSON se estructura correctamente con `size` y `elements`.

**🔍 DEBUG CHECKPOINT #1**:
```javascript
console.log("Layout JSON guardado:", layoutJson)
console.log("Elementos:", ticketElements.length)
```

---

### **2️⃣ FASE: CARGAR DISEÑO ACTIVO (PrintDialog.qml)**

**Ubicación**: `qml/components/dialogs/PrintDialog.qml` línea 19-24

```javascript
onOpened: {
    if (parentPage) parentPage.layer.enabled = true
    loadActiveTemplate()  // ✅ Se llama al abrir el diálogo
}
```

**Ubicación**: Línea 71-88

```javascript
function loadActiveTemplate() {
    allTemplates = templateRepository.getAllTemplates()
    
    activeTemplate = templateRepository.getActiveTemplate()  // ⚠️ PUNTO CRÍTICO
    if (activeTemplate && activeTemplate.id) {
        console.log("Diseño activo encontrado:", activeTemplate.name)
        loadTemplateData(activeTemplate)
    } else {
        console.log("No hay diseño activo configurado")  // ⚠️ PROBLEMA POTENCIAL
        templateElements = []
    }
}
```

**🔍 DEBUG CHECKPOINT #2**:
```javascript
console.log("Templates totales:", allTemplates ? allTemplates.length : 0)
console.log("Active template:", activeTemplate)
console.log("Active template ID:", activeTemplate ? activeTemplate.id : "NULL")
console.log("Layout JSON:", activeTemplate ? activeTemplate.layoutJson : "NULL")
```

**⚠️ POSIBLE ERROR #1**: **NO HAY DISEÑO ACTIVO MARCADO**
- Si ningún diseño tiene `is_active = 1` en la base de datos
- `getActiveTemplate()` retorna `null`
- `activeTemplate.id` es `undefined`
- La impresión usa formato estándar en lugar del diseño

**SOLUCIÓN**: Verificar/forzar que haya un diseño activo:
```sql
SELECT id, name, is_active FROM ticket_templates;
UPDATE ticket_templates SET is_active = 1 WHERE id = X;
```

---

### **3️⃣ FASE: PARSEAR DATOS DEL DISEÑO**

**Ubicación**: PrintDialog.qml línea 90-115

```javascript
function loadTemplateData(template) {
    if (!template || !template.id) {
        templateElements = []
        return
    }
    
    try {
        var layoutData = JSON.parse(template.layoutJson)  // ⚠️ PUNTO CRÍTICO
        if (layoutData.size) {
            templateWidth = layoutData.size.width
            templateHeight = layoutData.size.height
        }
        if (layoutData.elements) {
            templateElements = layoutData.elements
        }
    } catch (e) {
        console.log("Error parseando diseño:", e)  // ⚠️ PROBLEMA POTENCIAL
    }
}
```

**🔍 DEBUG CHECKPOINT #3**:
```javascript
console.log("Parsing layoutJson:", template.layoutJson)
console.log("Parsed size:", layoutData.size)
console.log("Parsed elements:", layoutData.elements ? layoutData.elements.length : 0)
console.log("Template width:", templateWidth, "height:", templateHeight)
```

**⚠️ POSIBLE ERROR #2**: **JSON INVÁLIDO O CORRUPTO**
- Si el JSON guardado está mal formateado
- Si falta el campo `elements` o `size`
- El catch captura el error pero no hay fallback

---

### **4️⃣ FASE: GENERAR PDF (Botón "Generar PDF")**

**Ubicación**: PrintDialog.qml línea 155-202

```javascript
function generateSalePdf() {
    if (!root.activeTemplate || !root.activeTemplate.id) {  // ⚠️ VALIDACIÓN CRÍTICA
        console.log("No hay diseño activo configurado")
        return  // ⚠️ SE ABORTA SI NO HAY DISEÑO
    }
    
    var saleData = { ... }
    var invoiceData = { ... }
    
    var success = printService.generateCustomTicketPdf(
        saleData,
        root.voucherType,
        invoiceData,
        root.activeTemplate.layoutJson,  // ✅ Se pasa el JSON
        outputPath
    )
}
```

**🔍 DEBUG CHECKPOINT #4**:
```javascript
console.log("Active template check:", root.activeTemplate ? "OK" : "NULL")
console.log("Active template ID:", root.activeTemplate ? root.activeTemplate.id : "N/A")
console.log("Sending layoutJson:", root.activeTemplate.layoutJson)
```

**⚠️ POSIBLE ERROR #3**: **VALIDACIÓN FALLA**
- Si `activeTemplate` es `null`
- Si `activeTemplate.id` es `0` o `undefined`
- La función retorna sin hacer nada
- **El usuario NO ve ningún error visible**

---

### **5️⃣ FASE: IMPRIMIR (Botón "Imprimir")**

**Ubicación**: PrintDialog.qml línea 374-410

```javascript
onClicked: {
    if (root.activeTemplate && root.activeTemplate.id) {  // ⚠️ MISMA VALIDACIÓN
        console.log("Imprimiendo con diseño personalizado:", root.activeTemplate.name)
        success = root.printViewModel.printCustomTicket(
            ...,
            root.activeTemplate.layoutJson,  // ✅ Se pasa el JSON
            ...
        )
    } else {
        // ⚠️ FALLBACK: USA DISEÑO ESTÁNDAR
        console.log("Imprimiendo con formato estándar")
        success = root.printViewModel.printVoucher(...)
    }
}
```

**🔍 DEBUG CHECKPOINT #5**:
```javascript
console.log("Impresión - Active template:", root.activeTemplate ? root.activeTemplate.name : "NINGUNO")
console.log("Usando diseño personalizado:", root.activeTemplate && root.activeTemplate.id ? "SÍ" : "NO")
```

**⚠️ POSIBLE ERROR #4**: **CAYO EN FALLBACK**
- Si no hay diseño activo, usa `printVoucher()` genérico
- El usuario NO sabe que está usando diseño estándar
- No hay mensaje de error visible

---

### **6️⃣ FASE: PARSEAR JSON EN C++ (PrintService.cpp)**

**Ubicación**: `src/services/PrintService.cpp` línea 656-693

```cpp
bool PrintService::generateCustomTicketPdf(..., const QString& layoutJson, ...) {
    QJsonDocument doc = QJsonDocument::fromJson(layoutJson.toUtf8());
    if (doc.isNull()) {  // ⚠️ VALIDACIÓN
        qDebug() << "Error: JSON invalido";
        return false;
    }
    
    QJsonArray elements;
    double ticketWidth = 80;
    double ticketHeight = 200;
    
    if (doc.isObject()) {
        QJsonObject layoutObj = doc.object();
        if (layoutObj.contains("size")) {  // ✅ Parsea size
            QJsonObject sizeObj = layoutObj["size"].toObject();
            ticketWidth = sizeObj["width"].toDouble(80);
            ticketHeight = sizeObj["height"].toDouble(200);
        }
        if (layoutObj.contains("elements")) {  // ✅ Parsea elements
            elements = layoutObj["elements"].toArray();
        } else {
            qDebug() << "Error: Diseno sin elementos";  // ⚠️ FALTA ARRAY
            return false;
        }
    }
}
```

**🔍 DEBUG CHECKPOINT #6** (EN LOGS DE APLICACIÓN):
```
Error: JSON invalido
Error: Diseno sin elementos
Creando PDF de 80 x 200 mm  ← ✅ Si llega aquí, el JSON es válido
```

**⚠️ POSIBLE ERROR #5**: **JSON NO LLEGA A C++**
- Si `layoutJson` está vacío
- Si `layoutJson` es `undefined`
- El parseo falla y retorna `false`

---

### **7️⃣ FASE: RENDERIZAR ELEMENTOS (PrintService.cpp)**

**Ubicación**: PrintService.cpp línea 400-650

```cpp
void PrintService::drawCustomTicket(QPainter& painter, ..., 
                                    const QJsonArray& elements, ...) {
    
    // ✅ PRIMER PASS: Buscar itemsHeader
    for (const QJsonValue& value : elements) {
        QJsonObject element = value.toObject();
        QString elementId = element["id"].toString();
        
        if (elementId == "itemsHeader" || 
            element["content"].toString() == "{{Productos}}") {
            // Define área de items
        }
    }
    
    // ✅ SEGUNDO PASS: Dibujar todos los elementos
    for (const QJsonValue& value : elements) {
        QJsonObject element = value.toObject();
        QString elementType = element["type"].toString();
        double x = element["x"].toDouble() * pixelsPerMM;  // ✅ Conversión MM→PX
        double y = element["y"].toDouble() * pixelsPerMM;
        
        if (elementType == "text") {
            // Dibuja texto
        } else if (elementType == "line") {
            // Dibuja línea
        } else if (elementType == "image") {
            // Dibuja imagen
        }
    }
}
```

**🔍 DEBUG CHECKPOINT #7** (EN LOGS):
```
=== RENDER TICKET ===
Standard DPI: 300
Items area found: X=... Y=... Width=...
Text element: ... at Y ...
Drawing items at EXACT position: X=... Y=...
```

**⚠️ POSIBLE ERROR #6**: **ELEMENTOS VACÍOS O MAL FORMADOS**
- Si `elements.toArray()` está vacío
- Si los elementos no tienen campos requeridos (`x`, `y`, `type`)
- No se dibuja nada o se usa posiciones por defecto

---

## 🎯 CHECKLIST DE DIAGNÓSTICO

Ejecuta estos pasos EN ORDEN para identificar el problema:

### ✅ **PASO 1: Verificar que hay diseño activo**

**Consola JavaScript (cuando abras PrintDialog)**:
```
Diseño activo encontrado: [nombre]  ← ✅ DEBE APARECER
```

**Si aparece**:
```
No hay diseño activo configurado  ← ⚠️ PROBLEMA AQUÍ
```

**SOLUCIÓN**:
1. Abre TicketsPage
2. Ve a la lista de diseños guardados
3. Haz clic en "Establecer como activo" en uno de ellos
4. O ejecuta SQL: `UPDATE ticket_templates SET is_active = 1 WHERE id = X;`

---

### ✅ **PASO 2: Verificar contenido del diseño**

**Agrega estos logs en PrintDialog.qml línea 71**:
```javascript
function loadActiveTemplate() {
    allTemplates = templateRepository.getAllTemplates()
    activeTemplate = templateRepository.getActiveTemplate()
    
    console.log("========== DEBUG ACTIVE TEMPLATE ==========")
    console.log("Active template:", activeTemplate)
    console.log("ID:", activeTemplate ? activeTemplate.id : "NULL")
    console.log("Name:", activeTemplate ? activeTemplate.name : "NULL")
    console.log("Layout JSON length:", activeTemplate ? activeTemplate.layoutJson.length : 0)
    console.log("Layout JSON:", activeTemplate ? activeTemplate.layoutJson : "NULL")
    console.log("===========================================")
    
    if (activeTemplate && activeTemplate.id) {
        loadTemplateData(activeTemplate)
    } else {
        console.log("⚠️ PROBLEMA: No hay diseño activo")
        templateElements = []
    }
}
```

**Esperado**:
```
========== DEBUG ACTIVE TEMPLATE ==========
Active template: [Object object]
ID: 1
Name: Mi Diseño de Ticket
Layout JSON length: 1234
Layout JSON: {"size":{"width":80,"height":200},"elements":[...]}
===========================================
```

**Si ves**:
```
ID: NULL
```
→ **NO HAY DISEÑO ACTIVO EN DB**

---

### ✅ **PASO 3: Verificar parseo del JSON**

**Agrega logs en PrintDialog.qml línea 90**:
```javascript
function loadTemplateData(template) {
    if (!template || !template.id) {
        console.log("⚠️ Template inválido")
        templateElements = []
        return
    }
    
    console.log("========== DEBUG PARSE TEMPLATE ==========")
    console.log("Raw JSON:", template.layoutJson)
    
    try {
        var layoutData = JSON.parse(template.layoutJson)
        console.log("Parsed OK:", layoutData)
        console.log("Size:", layoutData.size)
        console.log("Elements count:", layoutData.elements ? layoutData.elements.length : 0)
        
        if (layoutData.size) {
            templateWidth = layoutData.size.width
            templateHeight = layoutData.size.height
            console.log("✅ Size loaded:", templateWidth, "x", templateHeight)
        }
        if (layoutData.elements) {
            templateElements = layoutData.elements
            console.log("✅ Elements loaded:", templateElements.length)
        }
    } catch (e) {
        console.log("⚠️ ERROR PARSEANDO:", e)
        console.log("⚠️ JSON que falló:", template.layoutJson)
    }
    console.log("==========================================")
}
```

**Si ves**:
```
⚠️ ERROR PARSEANDO: SyntaxError: ...
```
→ **JSON CORRUPTO EN LA BASE DE DATOS**

---

### ✅ **PASO 4: Verificar que se pasa al servicio de impresión**

**Agrega logs en PrintDialog.qml línea 155**:
```javascript
function generateSalePdf() {
    console.log("========== DEBUG GENERATE PDF ==========")
    console.log("Active template check:", root.activeTemplate ? "EXISTS" : "NULL")
    console.log("Active template ID:", root.activeTemplate ? root.activeTemplate.id : "N/A")
    
    if (!root.activeTemplate || !root.activeTemplate.id) {
        console.log("⚠️ ABORTANDO: No hay diseño activo")
        console.log("==========================================")
        return
    }
    
    console.log("✅ Passed validation")
    console.log("Sending layoutJson:", root.activeTemplate.layoutJson.substring(0, 100) + "...")
    
    var success = printService.generateCustomTicketPdf(...)
    console.log("Result:", success ? "SUCCESS" : "FAILED")
    console.log("==========================================")
}
```

---

### ✅ **PASO 5: Verificar logs de C++ (Application Output)**

**Busca en la salida de la aplicación**:
```
Error: JSON invalido                ← ⚠️ JSON no llegó o está mal
Error: Diseno sin elementos         ← ⚠️ Falta array de elements
Creando PDF de 80 x 200 mm          ← ✅ JSON válido
=== RENDER TICKET ===               ← ✅ Comenzó a renderizar
Items area found: ...               ← ✅ Encontró área de items
Text element: ... at Y ...          ← ✅ Dibujando elementos
```

**Si NO ves ninguno de estos logs**:
→ **LA FUNCIÓN C++ NO SE ESTÁ LLAMANDO**

---

## 💡 SOLUCIONES RÁPIDAS

### **SOLUCIÓN #1: Forzar diseño activo**

```sql
-- Ver diseños existentes
SELECT id, name, is_active FROM ticket_templates;

-- Activar el primero
UPDATE ticket_templates SET is_active = 0;  -- Desactivar todos
UPDATE ticket_templates SET is_active = 1 WHERE id = 1;  -- Activar uno
```

### **SOLUCIÓN #2: Agregar validación visual en UI**

**En PrintDialog.qml, agregar**:
```qml
// Justo después de los botones
Label {
    text: root.activeTemplate && root.activeTemplate.id 
        ? "✅ Usando diseño: " + root.activeTemplate.name
        : "⚠️ Sin diseño personalizado (usando formato estándar)"
    color: root.activeTemplate && root.activeTemplate.id 
        ? Material.color(Material.Green) 
        : Material.color(Material.Orange)
    font.bold: true
    Layout.fillWidth: true
    horizontalAlignment: Text.AlignHCenter
}
```

### **SOLUCIÓN #3: Mensaje de error cuando no hay diseño**

**En PrintDialog.qml línea 155**:
```javascript
function generateSalePdf() {
    if (!root.activeTemplate || !root.activeTemplate.id) {
        console.log("⚠️ No hay diseño activo configurado")
        // AGREGAR NOTIFICACIÓN VISIBLE
        notificationService.showError(
            "No hay diseño de ticket activo.\n" +
            "Ve a la página de Tickets y activa un diseño."
        )
        return
    }
    // ... resto del código
}
```

---

## 🔥 PROBLEMA MÁS PROBABLE

Basándome en el análisis, el problema **MÁS PROBABLE** es:

### **No hay diseño marcado como activo en la base de datos**

**Evidencia**:
- El código hace validación `if (activeTemplate && activeTemplate.id)`
- Si falla, usa impresión estándar **SIN MOSTRAR ERROR**
- El usuario no se da cuenta que no está usando su diseño

**Fix inmediato**:
1. Abre la aplicación
2. Ve a "Tickets" (diseñador)
3. En la lista de diseños guardados, haz clic en uno
4. Presiona "Establecer como activo"
5. Vuelve a intentar imprimir

**Fix permanente**:
- Agregar indicador visual en PrintDialog que muestre qué diseño se está usando
- Agregar mensaje de error si no hay diseño activo
- Auto-activar el primer diseño cuando se crea

---

## 📊 DIAGRAMA DE FLUJO CON PUNTOS DE FALLO

```
[TicketsPage] Guardar diseño ✅
    ↓
[SQLite] ticket_templates.is_active = ?  ← ⚠️ PUNTO DE FALLO #1
    ↓
[PrintDialog.onOpened] loadActiveTemplate()
    ↓
[getActiveTemplate()] Retorna diseño activo o NULL  ← ⚠️ PUNTO DE FALLO #2
    ↓
[loadTemplateData()] JSON.parse(layoutJson)  ← ⚠️ PUNTO DE FALLO #3
    ↓
[Botón Imprimir] if (activeTemplate && id)  ← ⚠️ PUNTO DE FALLO #4
    ↓
[printCustomTicket()] Pasa layoutJson
    ↓
[PrintService.cpp] QJsonDocument::fromJson()  ← ⚠️ PUNTO DE FALLO #5
    ↓
[drawCustomTicket()] Renderiza elementos  ← ⚠️ PUNTO DE FALLO #6
    ↓
[PDF Generado] ✅
```

---

## 🎯 SIGUIENTE PASO

**Ejecuta PASO 1 primero**: Agrega los logs en `loadActiveTemplate()` y observa la consola.

¿Qué mensaje ves cuando abres PrintDialog?
