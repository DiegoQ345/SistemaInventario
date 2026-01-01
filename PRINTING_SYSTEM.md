# 🖨️ Sistema de Impresión y Generación de PDFs

**Fecha de implementación:** 31 de Diciembre de 2025

## 📋 Resumen

Se ha implementado un sistema completo de impresión de comprobantes (Boletas y Facturas) con generación de PDFs dinámicos y soporte para múltiples tamaños de papel, incluyendo impresoras térmicas.

---

## 🏗️ Arquitectura Implementada

### Componentes Principales

```
┌─────────────────────────────────────────────────┐
│  QML (SalesPage.qml)                            │
│  - PrintViewModel instance                      │
│  - Diálogos de configuración                    │
└─────────────────┬───────────────────────────────┘
                  │
┌─────────────────▼───────────────────────────────┐
│  PrintViewModel (C++)                           │
│  - Expone propiedades y métodos a QML           │
│  - Coordina servicios de impresión              │
└─────────┬───────────────┬───────────────────────┘
          │               │
┌─────────▼──────┐  ┌────▼──────────────────────┐
│ PrintService   │  │ PdfGeneratorService       │
│ - Impresión    │  │ - Generación de PDFs      │
│   directa      │  │ - HTML a PDF              │
│ - QPrinter     │  │ - Estilos dinámicos       │
└────────────────┘  └───────────────────────────┘
```

---

## 📁 Archivos Nuevos Creados

### 1. PrintViewModel.h / .cpp
**Ubicación:** `src/viewmodels/`

**Responsabilidades:**
- Exponer funcionalidad de impresión a QML
- Gestionar configuración de impresora
- Coordinar generación de PDFs
- Manejar múltiples tamaños de papel

**Propiedades Qt expuestas a QML:**
```cpp
Q_PROPERTY(bool isPrinting ...)              // Estado de impresión
Q_PROPERTY(QString lastError ...)            // Último error
Q_PROPERTY(QStringList availablePrinters ...) // Impresoras disponibles
Q_PROPERTY(QString defaultPrinter ...)       // Impresora predeterminada
Q_PROPERTY(PaperSize paperSize ...)          // Tamaño de papel
```

**Enums:**
```cpp
enum PaperSize {
    A4,              // 210 x 297 mm (estándar)
    Letter,          // 216 x 279 mm (EE.UU.)
    Thermal80mm,     // 80 x continuo mm (impresora térmica)
    Thermal58mm,     // 58 x continuo mm (impresora térmica pequeña)
    Custom
};

enum VoucherType {
    Boleta,
    Factura
};
```

**Métodos principales:**
```cpp
// Generar PDF del comprobante
QString generatePdf(invoiceNumber, customerName, items, 
                   subtotal, discount, total, voucherType, 
                   ruc, businessName, address)

// Imprimir directamente
bool printVoucher(...)

// Vista previa del PDF
QString previewPdf(...)

// Configurar información del negocio
void setBusinessInfo(name, taxId, address, phone, email)

// Refrescar lista de impresoras
void refreshPrinters()
```

**Señales:**
```cpp
void pdfGenerated(filePath)      // PDF creado exitosamente
void printCompleted()            // Impresión completada
void printFailed(error)          // Error en impresión
```

---

### 2. Actualizaciones en PdfGeneratorService

**Mejoras implementadas:**
- ✅ Generación de HTML dinámico con estilos CSS
- ✅ Soporte para formato A4 estándar
- ✅ Soporte para tickets térmicos (58mm y 80mm)
- ✅ Estilos adaptativos según tipo de papel
- ✅ Información del negocio personalizable

**Método clave: `generateReceiptHtml()`**

Genera HTML completo con:
1. Encabezado del negocio
2. Información de la venta (número, fecha, cliente)
3. Tabla de productos
4. Totales (subtotal, descuento, total)
5. Pie de página

**Estilos CSS dinámicos:**

**Para A4:**
- Fuente: Arial, sans-serif, 12pt
- Márgenes: 20mm
- Tabla con hover effects
- Colores profesionales (#333, #666)
- Bordes definidos

**Para Térmicas:**
- Fuente: Courier New, monospace, 10pt (compacto)
- Márgenes: 2-5mm
- Texto centrado
- Líneas punteadas como separadores
- Optimizado para impresión monocromática

---

## 🖥️ Integración con QML (SalesPage.qml)

### PrintViewModel Instance

```qml
PrintViewModel {
    id: printViewModel
    
    onPdfGenerated: function(filePath) {
        console.log("PDF generado en:", filePath)
        // Mostrar notificación
    }
    
    onPrintCompleted: function() {
        console.log("Impresión completada")
    }
    
    onPrintFailed: function(error) {
        console.error("Error:", error)
        // Mostrar diálogo de error
    }
}
```

### Diálogo de Configuración de Impresión

**Características:**
- ✅ Selector de impresora (con lista de impresoras disponibles)
- ✅ Selector de tamaño de papel (A4, Carta, Térmica 80mm, Térmica 58mm)
- ✅ Vista previa compacta del comprobante
- ✅ Botón "Vista Previa PDF" (abre PDF en visor predeterminado)
- ✅ Botón "Imprimir" (envía a impresora seleccionada)

**Código del diálogo:**
```qml
Dialog {
    id: printDialog
    title: qsTr("Configuración de Impresión")
    
    ColumnLayout {
        // Selector de impresora
        GroupBox {
            title: "Impresora"
            ComboBox {
                model: printViewModel.availablePrinters
                onCurrentTextChanged: {
                    printViewModel.defaultPrinter = currentText
                }
            }
        }
        
        // Tamaño de papel
        GroupBox {
            title: "Tamaño de Papel"
            RadioButton { text: "A4 (210 x 297 mm)" }
            RadioButton { text: "Ticket Térmico 80mm" }
            // ...
        }
        
        // Botones de acción
        Button {
            text: "Vista Previa PDF"
            onClicked: {
                printViewModel.previewPdf(...)
            }
        }
        
        Button {
            text: "Imprimir"
            onClicked: {
                printViewModel.printVoucher(...)
            }
        }
    }
}
```

### Diálogo de Configuración de Impresora (Preferencias)

**Ubicación:** Botón de configuración (⚙️) en la página de ventas

**Permite configurar:**
1. **Impresora predeterminada** - Se usa en todas las impresiones
2. **Tamaño de papel predeterminado** - A4 o Térmica 80mm
3. **Información del negocio**:
   - Nombre del negocio
   - RUC/NIT
   - Dirección
   - Teléfono
   - Email

```qml
Dialog {
    id: printerSettingsDialog
    title: "Configuración de Impresora"
    
    ColumnLayout {
        GroupBox {
            title: "Información del Negocio"
            GridLayout {
                TextField { id: businessNameInput }
                TextField { id: businessTaxIdInput }
                TextField { id: businessAddressInput }
                TextField { id: businessPhoneInput }
                TextField { id: businessEmailInput }
            }
        }
        
        Button {
            text: "Guardar"
            onClicked: {
                printViewModel.setBusinessInfo(
                    businessNameInput.text,
                    businessTaxIdInput.text,
                    businessAddressInput.text,
                    businessPhoneInput.text,
                    businessEmailInput.text
                )
            }
        }
    }
}
```

---

## 🚀 Flujo de Uso

### 1. Procesar Venta

```
Usuario presiona "Procesar Venta"
    ↓
viewModel.processSale(...)
    ↓
Venta guardada en base de datos
    ↓
emit saleCompleted(invoiceNumber, total)
    ↓
QML muestra diálogo de éxito
```

### 2. Imprimir Comprobante

```
Usuario presiona "Imprimir" en diálogo de éxito
    ↓
Se abre printDialog (configuración de impresión)
    ↓
Usuario selecciona:
  - Impresora
  - Tamaño de papel
    ↓
Usuario presiona "Vista Previa PDF" o "Imprimir"
    ↓
printViewModel.generatePdf(...) o printViewModel.printVoucher(...)
    ↓
PDF generado en: Documents/SistemaInventario/Comprobantes/
Nombre: BOLETA_FACT-0042_20251231_143022.pdf
    ↓
emit pdfGenerated(filePath)
    ↓
Si "Vista Previa": Abrir PDF con visor predeterminado
Si "Imprimir": Enviar a impresora con QPrinter
```

### 3. Estructura de Datos Pasada a C++

```javascript
// Preparar items del carrito
let items = []
for (let i = 0; i < viewModel.cart.rowCount(); i++) {
    let idx = viewModel.cart.index(i, 0)
    items.push({
        productName: viewModel.cart.data(idx, 257),
        quantity: viewModel.cart.data(idx, 260),
        unitPrice: viewModel.cart.data(idx, 261),
        subtotal: viewModel.cart.data(idx, 262)
    })
}

// Llamar al ViewModel
printViewModel.generatePdf(
    invoiceNumber,    // "FACT-0042"
    customerName,     // "Cliente General"
    items,            // Array de productos
    subtotal,         // 2450.00
    discount,         // 50.00
    total,            // 2400.00
    voucherType,      // PrintViewModel.Factura
    ruc,              // "20123456789"
    businessName,     // "Empresa XYZ SAC"
    address           // "Av. Principal 123"
)
```

---

## 📊 Ejemplo de PDF Generado

### Formato A4

```
┌──────────────────────────────────────────────────┐
│                                                  │
│           SISTEMA DE INVENTARIO                  │
│           RUC: 20123456789                       │
│    Av. Principal 123, Lima, Perú                │
│         Tel: (01) 234-5678                       │
│                                                  │
├──────────────────────────────────────────────────┤
│                                                  │
│        COMPROBANTE DE VENTA - FACTURA            │
│              Nº: FACT-0042                       │
│        Fecha: 31/12/2025 14:30                   │
│        Cliente: Empresa XYZ SAC                  │
│        RUC: 20987654321                          │
│        Pago: Efectivo                            │
│                                                  │
├──────────────────────────────────────────────────┤
│ Producto           Cant.   P.Unit    Subtotal   │
├──────────────────────────────────────────────────┤
│ Laptop HP Pavilion  2.00   1200.00   2400.00    │
│ Mouse Logitech      1.00     50.00     50.00    │
│                                                  │
├──────────────────────────────────────────────────┤
│                              Subtotal:  2450.00  │
│                              Descuento:  -50.00  │
│                              TOTAL:     2400.00  │
├──────────────────────────────────────────────────┤
│                                                  │
│           ¡Gracias por su compra!                │
│       ventas@sistemainventario.com               │
│                                                  │
└──────────────────────────────────────────────────┘
```

### Formato Térmico 80mm

```
┌────────────────────────┐
│ SISTEMA DE INVENTARIO  │
│  RUC: 20123456789      │
│ Av. Principal 123      │
│  Tel: (01) 234-5678    │
├------------------------┤
│   BOLETA DE VENTA      │
│    Nº: BOL-0043        │
│ 31/12/2025 14:30       │
│ Cliente: General       │
│ Pago: Efectivo         │
├------------------------┤
│ Producto   Cant Precio │
├------------------------┤
│ Laptop HP   2   2400.00│
│ Mouse Logi  1     50.00│
├------------------------┤
│ SUBTOTAL:      2450.00 │
│ DESCUENTO:      -50.00 │
│ TOTAL:         2400.00 │
├------------------------┤
│ ¡Gracias por su compra!│
└────────────────────────┘
```

---

## 📝 Ubicación de PDFs Generados

**Ruta en Windows:**
```
C:\Users\[Usuario]\Documents\SistemaInventario\Comprobantes\
```

**Formato de nombre:**
```
[TIPO]_[NUMERO]_[TIMESTAMP].pdf

Ejemplos:
- BOLETA_BOL-0043_20251231_143022.pdf
- FACTURA_FACT-0042_20251231_142530.pdf
```

---

## ⚙️ Configuración del Sistema

### Información del Negocio (Personalizable)

Se configura desde el diálogo de configuración de impresora:

```cpp
// Valores por defecto
BusinessInfo {
    name = "SISTEMA DE INVENTARIO"
    taxId = "20123456789"
    address = "Av. Principal 123, Lima, Perú"
    phone = "(01) 234-5678"
    email = "ventas@sistemainventario.com"
}
```

### Impresora Predeterminada

Se selecciona automáticamente la primera impresora disponible. El usuario puede cambiarla en:
1. Diálogo de configuración de impresión (temporal)
2. Diálogo de preferencias de impresora (permanente)

---

## 🎯 Características Destacadas

### ✅ Implementadas

1. **Generación dinámica de PDFs**
   - HTML + CSS a PDF con QTextDocument
   - Estilos adaptativos según tamaño de papel
   - Información personalizable del negocio

2. **Múltiples tamaños de papel**
   - A4 (210 x 297 mm)
   - Carta (216 x 279 mm)
   - Ticket Térmico 80mm
   - Ticket Térmico 58mm

3. **Vista previa de PDF**
   - Genera PDF temporal
   - Abre con visor predeterminado del sistema
   - Permite revisar antes de imprimir

4. **Impresión directa**
   - Diálogo de selección de impresora (QPrintDialog)
   - Envío directo a impresora seleccionada
   - Soporte para múltiples impresoras

5. **Integración completa con QML**
   - PrintViewModel expuesto con Q_PROPERTY
   - Señales para notificaciones
   - Enums para tipos de papel y comprobantes

6. **Configuración persistente**
   - Información del negocio guardada
   - Impresora predeterminada recordada
   - Tamaño de papel preferido

### ⏳ Pendientes (Mejoras Futuras)

1. **Plantillas personalizables**
   - Editor de plantillas HTML
   - Múltiples diseños de comprobantes
   - Logo del negocio

2. **Envío por email**
   - Adjuntar PDF al email
   - Enviar comprobante al cliente

3. **Historial de impresiones**
   - Registro de comprobantes impresos
   - Reimpresión de comprobantes antiguos

4. **Códigos QR**
   - QR con datos de la venta
   - Verificación de autenticidad

---

## 🔧 Dependencias Utilizadas

### Qt Modules
- **Qt PrintSupport** - Impresión y generación de PDFs
  - `QPrinter` - Configuración de impresora
  - `QPrintDialog` - Diálogo de selección
  - `QPainter` - Renderizado
  - `QTextDocument` - HTML a PDF

- **Qt Core** - Funcionalidad base
  - `QDateTime` - Timestamps
  - `QFile` - Manejo de archivos
  - `QStandardPaths` - Rutas del sistema

- **Qt Gui** - Interfaz
  - `QDesktopServices` - Abrir archivos

### Sin dependencias externas
- ✅ No requiere bibliotecas de terceros
- ✅ Todo con Qt nativo
- ✅ Compatible con Qt 6.10+

---

## 📚 Ejemplos de Uso

### Generar PDF desde QML

```qml
Button {
    text: "Generar PDF"
    onClicked: {
        let pdfPath = printViewModel.generatePdf(
            "FACT-0042",
            "Cliente General",
            [
                { productName: "Laptop HP", quantity: 2, unitPrice: 1200, subtotal: 2400 },
                { productName: "Mouse", quantity: 1, unitPrice: 50, subtotal: 50 }
            ],
            2450.00,   // subtotal
            50.00,     // discount
            2400.00,   // total
            PrintViewModel.Factura,
            "20987654321",
            "Empresa XYZ SAC",
            "Av. Principal 123"
        )
        
        if (pdfPath !== "") {
            console.log("PDF generado:", pdfPath)
        }
    }
}
```

### Vista Previa

```qml
Button {
    text: "Vista Previa"
    onClicked: {
        printViewModel.previewPdf(/* mismos parámetros que generatePdf */)
        // Abre automáticamente el PDF con el visor predeterminado
    }
}
```

### Imprimir Directamente

```qml
Button {
    text: "Imprimir"
    onClicked: {
        let success = printViewModel.printVoucher(/* mismos parámetros */)
        if (success) {
            console.log("Impresión iniciada")
        }
    }
}
```

---

## 🐛 Troubleshooting

### Problema: No aparecen impresoras

**Solución:**
```qml
Button {
    text: "Actualizar impresoras"
    onClicked: printViewModel.refreshPrinters()
}
```

### Problema: PDF no se genera

**Causas posibles:**
1. Sin permisos de escritura en `Documents`
2. Disco lleno
3. Nombre de archivo inválido

**Verificar:**
```javascript
let pdfPath = printViewModel.generatePdf(...)
if (pdfPath === "") {
    console.error("Error:", printViewModel.lastError)
}
```

### Problema: Formato de impresión incorrecto

**Solución:** Verificar que el tamaño de papel coincida con la impresora:
- Impresoras láser/inyección → A4 o Carta
- Impresoras térmicas POS → Thermal80mm o Thermal58mm

---

**Documentación generada:** 31 de Diciembre de 2025  
**Versión del sistema:** 1.0.0
