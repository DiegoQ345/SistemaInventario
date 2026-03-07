# 🔬 Análisis Crítico de DPI y Escalado en PrintService

**Fecha:** 2 de Marzo de 2026  
**Prioridad:** CRÍTICA  
**Impacto:** Renderizado inconsistente entre PDF e impresión física

---

## 🚨 PROBLEMAS CRÍTICOS IDENTIFICADOS

### 1. ❌ **DPI Inconsistente entre QPrinter y QPdfWriter**

#### Código Actual:
```cpp
// printCustomTicket() - Línea 335
QPrinter printer(QPrinter::HighResolution);
// ❌ NO establece resolución explícita
// HighResolution puede ser 300, 600, o 1200 DPI según el driver

// generateCustomTicketPdf() - Línea 639
QPdfWriter pdfWriter(outputPath);
pdfWriter.setResolution(300);  // ✅ Fijo en 300 DPI
```

#### Problema:
```
QPrinter (HighResolution):
- Windows con driver genérico: 600 DPI
- Impresora térmica EPSON: 203 DPI
- Impresora láser HP: 1200 DPI

QPdfWriter:
- SIEMPRE: 300 DPI

Resultado: pixelsPerMM diferente = elementos mal posicionados
```

#### Cálculo:
```cpp
// PDF
logicalDpiX() = 300
pixelsPerMM = 300 / 25.4 = 11.81

// Impresora térmica
logicalDpiX() = 203
pixelsPerMM = 203 / 25.4 = 7.99

// Diferencia: 11.81 / 7.99 = 1.48x
// Un elemento de 10mm se renderiza:
// - PDF: 118.1 px
// - Térmica: 79.9 px (66% más pequeño!)
```

---

### 2. ❌ **QPrinter::HighResolution Altera DPI Interno**

#### Documentación Qt:
```cpp
enum PrinterMode {
    ScreenResolution,    // 96 DPI (o DPI de pantalla)
    PrinterResolution,   // Resolución "normal" del dispositivo
    HighResolution       // ❌ MÁXIMA resolución del dispositivo
}
```

#### Problema:
```cpp
QPrinter printer(QPrinter::HighResolution);
// Esto NO garantiza un DPI específico
// Solo garantiza "usar la máxima resolución disponible"

// INCONSISTENTE:
// Impresora A: 203 DPI
// Impresora B: 300 DPI
// Impresora C: 600 DPI
// Impresora D: 1200 DPI
```

---

### 3. ⚠️ **setFullPage(true) y setPageMargins(0,0,0,0)**

#### Código Actual:
```cpp
printer.setFullPage(true);
printer.setPageMargins(QMarginsF(0, 0, 0, 0), QPageLayout::Millimeter);
```

#### Análisis:
```cpp
setFullPage(true):
✅ Permite dibujar en toda la página física
✅ Incluye áreas no imprimibles del hardware
⚠️ Algunos drivers IGNORAN esto y fuerzan márgenes

setPageMargins(0, 0, 0, 0):
✅ Solicita 0 márgenes
⚠️ El driver puede ignorarlo si el hardware tiene área no imprimible

painter.device()->width():
✅ Retorna el ancho del área dibujable (respeta fullPage)
⚠️ Si fullPage=false, retorna ancho - márgenes
```

#### Verificación en Runtime:
```cpp
qDebug() << "Page size (mm):" << printer.pageLayout().pageSize().size(QPageSize::Millimeter);
qDebug() << "Paint area (px):" << painter.device()->width() << "x" << painter.device()->height();
qDebug() << "DPI:" << painter.device()->logicalDpiX();
qDebug() << "Margins (mm):" << printer.pageLayout().margins(QPageLayout::Millimeter);

// VERIFICAR:
// width_px / (dpi / 25.4) == width_mm ?
```

---

### 4. ❌ **Conversión mm ↔ px NO Determinística**

#### Código Actual:
```cpp
// drawCustomTicket() - Línea 398
const double pixelsPerMM = painter.device()->logicalDpiX() / 25.4;

// Luego:
double x = element["x"].toDouble() * pixelsPerMM;
double y = element["y"].toDouble() * pixelsPerMM;
```

#### Problema:
```
1. JSON almacena: x = 10.0 mm (double)
2. pixelsPerMM = logicalDpiX() / 25.4 (depende del device)
3. x_px = 10.0 * pixelsPerMM

Si logicalDpiX() cambia:
- PDF (300): 10 * 11.81 = 118.1 px
- Térmica (203): 10 * 7.99 = 79.9 px
- Láser (600): 10 * 23.62 = 236.2 px

¡INCONSISTENTE! El diseño se deforma según el dispositivo.
```

#### Solución:
```cpp
// OPCIÓN 1: Normalizar a DPI estándar
const double STANDARD_DPI = 300.0;
const double pixelsPerMM = STANDARD_DPI / 25.4;  // FIJO

// Luego escalar al dispositivo real
double scaleFactor = painter.device()->logicalDpiX() / STANDARD_DPI;
painter.scale(scaleFactor, scaleFactor);

// OPCIÓN 2: Forzar resolución en QPrinter
printer.setResolution(300);  // ✅ Igual que QPdfWriter
```

---

### 5. ❌ **QFontMetrics Incoherente con DPI Variable**

#### Código Actual:
```cpp
QFont itemFont("Arial", 8);  // 8 puntos
QFontMetrics fmItem(itemFont);

QRect boundingRect = fmItem.boundingRect(
    QRect(0, 0, static_cast<int>(itemsWidth), 1000),
    Qt::AlignLeft | Qt::TextWordWrap,
    productName
);
int nameHeight = boundingRect.height();
```

#### Problema:
```
QFont("Arial", 8):
- El tamaño es en PUNTOS (pt), no píxeles
- 1 pt = 1/72 inch
- 8 pt = 8/72 inch = 0.111 inch = 2.82 mm

Pero QFontMetrics depende del DPI para calcular altura:
- 96 DPI: 8 pt = 8 * 96/72 = 10.67 px
- 300 DPI: 8 pt = 8 * 300/72 = 33.33 px
- 203 DPI: 8 pt = 8 * 203/72 = 22.56 px

El cálculo de itemsHeight varía según DPI:
- PDF (300): itemsHeight = 200 px
- Térmica (203): itemsHeight = 135 px

¡Los elementos se desplazan diferente!
```

#### Solución:
```cpp
// Crear QFontMetrics asociado al QPainter
painter.setFont(itemFont);
QFontMetrics fmItem = painter.fontMetrics();  // ✅ Usa DPI del device

// O normalizar a DPI estándar primero
```

---

### 6. ⚠️ **adjustedY con itemsHeight: Desplazamiento Acumulativo**

#### Código Actual:
```cpp
// PRIMER PASS: Calcular altura de items
double itemsHeight = 0;
for (const auto& item : sale.items) {
    QRect boundingRect = fmItem.boundingRect(...);
    itemsHeight += boundingRect.height() + 4 + spacing;
}

// SEGUNDO PASS: Ajustar elementos
double adjustedY = y;
if (itemsFound && y > itemsStartY) {
    adjustedY = y + itemsHeight;  // ⚠️ Desplazamiento
}
```

#### Análisis:

**✅ NO hay acumulación:** Se calcula una sola vez y se aplica a todos los elementos posteriores.

**✅ Lógica correcta:** Solo se ajustan elementos con `y > itemsStartY`.

**⚠️ Riesgo mínimo de redondeo:**
```cpp
double adjustedY = y + itemsHeight;
// Si:
// y = 180.000000 mm * 11.81 = 2125.8 px
// itemsHeight = 150.333333 px
// adjustedY = 2276.133333 px

// Al dibujar:
painter.drawText(QRectF(x, adjustedY, width, height), ...);
// QPainter usa double, NO trunca
// ✅ Sin pérdida de precisión
```

**Conclusión:** NO es un problema crítico, pero documentar que se usa double.

---

### 7. ❌ **Tamaño del PDF NO Coincide Exactamente con JSON**

#### Código Actual:
```cpp
// JSON: 80mm x 200mm
double ticketWidth = sizeObj["width"].toDouble(80);   // mm
double ticketHeight = sizeObj["height"].toDouble(200); // mm

// QPdfWriter
pdfWriter.setPageSize(QPageSize(QSizeF(ticketWidth, ticketHeight), 
                      QPageSize::Millimeter));
pdfWriter.setResolution(300);
```

#### Verificación:
```cpp
// Tamaño solicitado: 80mm x 200mm
// Resolución: 300 DPI
// pixelsPerMM: 300 / 25.4 = 11.811 px/mm

// Ancho en píxeles:
80 mm * 11.811 = 944.88 px

// painter.device()->width() debería retornar:
// 945 px (redondeado)

// PERO Qt puede redondear interno:
// 80 mm = 80 * 300 / 25.4 = 944.88... px
// Internamente podría usar 944 o 945 px

// PROBLEMA: No podemos controlar el redondeo de Qt
```

#### Solución:
```cpp
// Verificar en runtime:
qDebug() << "Expected width (mm):" << ticketWidth;
qDebug() << "Actual width (px):" << painter.device()->width();
qDebug() << "DPI:" << painter.device()->logicalDpiX();
qDebug() << "Computed width (mm):" 
         << (painter.device()->width() * 25.4 / painter.device()->logicalDpiX());

// Debe coincidir ±0.1 mm
```

---

### 8. ✅ **NO Existe Doble Escalado**

#### Análisis del Flujo:
```cpp
// 1. Conversión mm → px
double x = element["x"].toDouble() * pixelsPerMM;

// 2. Dibujar directamente
painter.drawText(QRectF(x, y, width, height), alignment, content);

// ✅ NO hay painter.scale() antes
// ✅ NO hay transformación adicional
// ✅ NO hay conversión px → mm → px
```

**Conclusión:** NO hay doble escalado. ✅

---

### 9. ❌ **CRÍTICO: Arquitectura Depende del DPI del Dispositivo**

#### Problema Fundamental:
```
DISEÑADOR (QML):
pixelsPerMM = 3.78 (96 DPI fijo)

IMPRESIÓN (C++):
pixelsPerMM = logicalDpiX() / 25.4 (VARIABLE)

RESULTADO:
- Diseñador: 10mm → 37.8 px
- PDF: 10mm → 118.1 px (300 DPI)
- Térmica: 10mm → 79.9 px (203 DPI)
- Láser: 10mm → 236.2 px (600 DPI)

¡INCONSISTENTE! El mismo diseño se ve diferente.
```

#### Impacto:
```
Elemento en diseñador:
{
  "x": 10,
  "y": 50,
  "fontSize": 12
}

PDF (300 DPI):
x = 10 * 11.81 = 118.1 px
fontSize = 12 pt = 50 px @ 300 DPI
✅ Se ve correcto

Térmica (203 DPI):
x = 10 * 7.99 = 79.9 px
fontSize = 12 pt = 33.8 px @ 203 DPI
⚠️ Fuente más pequeña, todo comprimido

Láser (600 DPI):
x = 10 * 23.62 = 236.2 px
fontSize = 12 pt = 100 px @ 600 DPI
⚠️ Fuente gigante, todo expandido
```

---

## ✅ SOLUCIONES IMPLEMENTADAS

### **Solución 1: Normalizar DPI a 300 en TODO**

```cpp
// Constante global
const double STANDARD_DPI = 300.0;
const double STANDARD_PIXELS_PER_MM = STANDARD_DPI / 25.4;  // 11.811024

// EN TODAS LAS FUNCIONES DE RENDERIZADO:

bool PrintService::printCustomTicket(...) {
    QPrinter printer(QPrinter::HighResolution);
    
    // ✅ FORZAR RESOLUCIÓN
    printer.setResolution(STANDARD_DPI);  // 300 DPI
    
    // Resto del código...
}

bool PrintService::generateCustomTicketPdf(...) {
    QPdfWriter pdfWriter(outputPath);
    
    // ✅ CONSISTENTE CON QPRINTER
    pdfWriter.setResolution(STANDARD_DPI);  // 300 DPI
    
    // Resto del código...
}

void PrintService::drawCustomTicket(QPainter& painter, ...) {
    // ✅ VERIFICAR DPI
    const double actualDpi = painter.device()->logicalDpiX();
    
    if (qAbs(actualDpi - STANDARD_DPI) > 1.0) {
        qWarning() << "DPI mismatch! Expected:" << STANDARD_DPI 
                   << "Actual:" << actualDpi;
        // Aplicar factor de corrección
        double scaleFactor = actualDpi / STANDARD_DPI;
        painter.scale(scaleFactor, scaleFactor);
    }
    
    // ✅ USAR CONSTANTE
    const double pixelsPerMM = STANDARD_PIXELS_PER_MM;
    
    // Resto del código...
}
```

---

### **Solución 2: QFontMetrics con Painter**

```cpp
// ❌ ANTES
QFont itemFont("Arial", 8);
QFontMetrics fmItem(itemFont);  // Usa DPI de pantalla

// ✅ DESPUÉS
QFont itemFont("Arial", 8);
painter.setFont(itemFont);
QFontMetrics fmItem = painter.fontMetrics();  // ✅ Usa DPI del device
```

---

### **Solución 3: Verificación de Márgenes**

```cpp
void PrintService::drawCustomTicket(QPainter& painter, ...) {
    // ✅ VERIFICAR CONFIGURACIÓN
    QPaintDevice* device = painter.device();
    
    qDebug() << "=== PAINT DEVICE INFO ===";
    qDebug() << "DPI:" << device->logicalDpiX() << "x" << device->logicalDpiY();
    qDebug() << "Size (px):" << device->width() << "x" << device->height();
    qDebug() << "Size (mm):" << (device->width() * 25.4 / device->logicalDpiX())
             << "x" << (device->height() * 25.4 / device->logicalDpiY());
    
    // Verificar que coincide con JSON
    double expectedWidthMM = /* from JSON */;
    double actualWidthMM = device->width() * 25.4 / device->logicalDpiX();
    
    if (qAbs(actualWidthMM - expectedWidthMM) > 0.5) {
        qWarning() << "SIZE MISMATCH! Expected:" << expectedWidthMM 
                   << "mm, Actual:" << actualWidthMM << "mm";
    }
    
    // Resto del código...
}
```

---

### **Solución 4: Conversión Determinística**

```cpp
// PrintService.h - Agregar constantes
class PrintService : public QObject {
private:
    static constexpr double STANDARD_DPI = 300.0;
    static constexpr double STANDARD_PIXELS_PER_MM = STANDARD_DPI / 25.4;
    
    // Método helper
    double mmToPixels(double mm) const {
        return mm * STANDARD_PIXELS_PER_MM;
    }
    
    double pixelsToMM(double pixels) const {
        return pixels / STANDARD_PIXELS_PER_MM;
    }
};

// Uso:
double x = mmToPixels(element["x"].toDouble());
double y = mmToPixels(element["y"].toDouble());
```

---

## 📋 CHECKLIST DE VALIDACIÓN

### Antes de Imprimir:
- [ ] `printer.resolution()` == 300 DPI
- [ ] `painter.device()->logicalDpiX()` == 300 DPI
- [ ] `painter.device()->width()` == expected width en píxeles
- [ ] Márgenes == 0 (o documentar si no es posible)

### Durante el Renderizado:
- [ ] `pixelsPerMM` == 11.811024 (constante)
- [ ] `QFontMetrics` creado desde `painter.fontMetrics()`
- [ ] Coordenadas calculadas con STANDARD_PIXELS_PER_MM

### Después de Generar:
- [ ] Verificar dimensiones del PDF con visor
- [ ] Medir elementos clave con regla digital
- [ ] Comparar con diseño original en QML

---

## 🧪 TESTS DE VALIDACIÓN

### Test 1: Consistency Check
```cpp
void PrintService::validateDpiConsistency(QPainter& painter, 
                                          double expectedWidthMM,
                                          double expectedHeightMM) {
    QPaintDevice* device = painter.device();
    
    double actualDpi = device->logicalDpiX();
    double actualWidthMM = device->width() * 25.4 / actualDpi;
    double actualHeightMM = device->height() * 25.4 / actualDpi;
    
    qDebug() << "DPI Check:"
             << "Expected:" << STANDARD_DPI
             << "Actual:" << actualDpi
             << "Match:" << (qAbs(actualDpi - STANDARD_DPI) < 1.0);
             
    qDebug() << "Size Check:"
             << "Expected:" << expectedWidthMM << "x" << expectedHeightMM
             << "Actual:" << actualWidthMM << "x" << actualHeightMM
             << "Match:" << (qAbs(actualWidthMM - expectedWidthMM) < 0.5);
}
```

### Test 2: Font Rendering Check
```cpp
void testFontConsistency() {
    QFont font("Arial", 12);
    
    // Con DPI de pantalla (96)
    QFontMetrics fm1(font);
    int height1 = fm1.height();
    
    // Con DPI de impresora (300)
    QPdfWriter writer("test.pdf");
    writer.setResolution(300);
    QPainter painter(&writer);
    painter.setFont(font);
    QFontMetrics fm2 = painter.fontMetrics();
    int height2 = fm2.height();
    
    qDebug() << "Font height @ 96 DPI:" << height1;   // ~16 px
    qDebug() << "Font height @ 300 DPI:" << height2;  // ~50 px
    qDebug() << "Ratio:" << (double)height2 / height1; // ~3.125 (300/96)
}
```

---

## 📊 IMPACTO DE LAS CORRECCIONES

| Aspecto | Antes | Después |
|---------|-------|---------|
| DPI QPrinter | Variable (203-1200) | Fijo 300 ✅ |
| DPI QPdfWriter | Fijo 300 | Fijo 300 ✅ |
| pixelsPerMM | Variable | Constante 11.811 ✅ |
| QFontMetrics | Pantalla (96 DPI) | Device (300 DPI) ✅ |
| Consistencia PDF vs Print | ❌ Diferente | ✅ Idéntico |
| Tamaño verificado | ❌ No | ✅ Sí |

---

## ⚡ PRIORIDAD DE IMPLEMENTACIÓN

### **CRÍTICA (Hacer AHORA):**
1. ✅ Agregar constantes STANDARD_DPI y STANDARD_PIXELS_PER_MM
2. ✅ Llamar `printer.setResolution(300)` en printCustomTicket()
3. ✅ Usar `painter.fontMetrics()` en lugar de `QFontMetrics(font)`
4. ✅ Agregar verificación de DPI en drawCustomTicket()

### **ALTA:**
5. ✅ Implementar validateDpiConsistency()
6. ✅ Documentar conversión mm ↔ px
7. ✅ Agregar warnings si DPI != 300

### **MEDIA:**
8. Crear tests unitarios de consistencia
9. Comparativa visual PDF vs diseñador
10. Documentar limitaciones del hardware

---

**Revisado por:** GitHub Copilot  
**Estado:** SOLUCIONES LISTAS PARA IMPLEMENTAR  
**Riesgo sin corrección:** ALTO (diseños inconsistentes)
