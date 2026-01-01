# Flujo de Procesamiento de Venta e Impresión

## Diagrama de Flujo

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. Usuario llena el formulario de venta                        │
│    - Selecciona productos (carrito)                             │
│    - Elige cliente (ComboBox)                                   │
│    - Selecciona tipo: Boleta o Factura                         │
│    - Si es Factura: RUC, Razón Social, Dirección               │
│    - Elige método de pago                                       │
└─────────────────┬───────────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────────┐
│ 2. Usuario hace clic en "Procesar Venta"                       │
│    Button.onClicked:                                            │
│    - Guarda datos temporales en root.current*                  │
│    - Llama viewModel.processSaleWithInvoiceData()              │
└─────────────────┬───────────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────────┐
│ 3. ViewModel procesa la venta (C++)                            │
│    SalesCartViewModel::processSaleWithInvoiceData()            │
│    - Valida datos                                               │
│    - Guarda en base de datos                                    │
│    - Genera número de comprobante                               │
│    - Emite signal: saleCompleted()                             │
└─────────────────┬───────────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────────┐
│ 4. Signal onSaleCompleted recibido en QML                      │
│    - Recibe: invoiceNumber, total, voucherType, items, etc.   │
│    - Asigna datos a successDialog                              │
│    - Añade datos del cliente desde root.current*              │
│    - Muestra SaleSuccessDialog                                 │
│    - Limpia formulario y datos temporales                      │
└─────────────────┬───────────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────────┐
│ 5. SaleSuccessDialog mostrado                                  │
│    Muestra:                                                     │
│    - ✓ Venta Exitosa                                           │
│    - Tipo de comprobante (BOLETA/FACTURA)                      │
│    - Número: B001-00123 / F001-00456                           │
│    - Total: S/150.00                                            │
│    - Si es FACTURA: RUC, Razón Social, Dirección              │
│    Botones: [Imprimir] [Cerrar]                               │
└─────────────────┬───────────────────────────────────────────────┘
                  │
                  ▼ (Usuario hace clic en "Imprimir")
┌─────────────────────────────────────────────────────────────────┐
│ 6. Signal printRequested() emitido                             │
│    SaleSuccessDialog.onPrintRequested:                         │
│    - Convierte voucherType a enum (Boleta/Factura)             │
│    - Transfiere TODOS los datos a PrintDialog                  │
│      * invoiceNumber, customerName, items                       │
│      * subtotal, discount, total                                │
│      * voucherType, ruc, businessName, address                  │
│    - Abre PrintDialog                                           │
│    - Cierra SaleSuccessDialog                                   │
└─────────────────┬───────────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────────┐
│ 7. PrintDialog mostrado                                        │
│    Configuración:                                               │
│    - Selector de impresora (ComboBox)                          │
│    - Tamaño de papel: A4 / Carta / Térmico 80mm / 58mm        │
│    Vista Previa:                                                │
│    - BOLETA / FACTURA                                           │
│    - Nº B001-00123                                              │
│    - 3 productos                                                │
│    - Total: S/150.00                                            │
│    Botones: [Vista Previa PDF] [Imprimir] [Cancelar]          │
└─────────────────┬───────────────────────────────────────────────┘
                  │
                  ├─────► [Vista Previa PDF] ─────────────────┐
                  │       printViewModel.previewPdf()          │
                  │       - Genera PDF                          │
                  │       - Abre con visor predeterminado      │
                  │                                             │
                  └─────► [Imprimir] ────────────────────────┐ │
                          printViewModel.printVoucher()       │ │
                          - Envía a impresora                 │ │
                          - Cierra PrintDialog si exitoso     │ │
                                                               │ │
┌──────────────────────────────────────────────────────────────┼─┤
│ 8. PrintViewModel genera comprobante                        │ │
│    Según paperSize:                                         │ │
│    - A4/Carta: Comprobante formato completo                 │ │
│    - Térmico 80mm/58mm: Ticket térmico                      │ │
│                                                              │ │
│    Contenido:                                                │ │
│    - Encabezado: Nombre del negocio, RUC, dirección        │ │
│    - Tipo de comprobante: BOLETA/FACTURA                    │ │
│    - Número de comprobante                                   │ │
│    - Datos del cliente                                       │ │
│    - Si es FACTURA: RUC, Razón Social, Dirección cliente   │ │
│    - Fecha y hora                                            │ │
│    - Método de pago                                          │ │
│    - Tabla de productos                                      │ │
│    - Subtotal, Descuento, Total                             │ │
│    - Pie de página                                           │ │
└──────────────────────────────────────────────────────────────┴─┘
```

## Flujo de Datos

### Propiedades Temporales en SalesPage.qml

```qml
Page {
    id: root
    
    // Datos guardados temporalmente hasta que se complete la venta
    property string currentCustomerName: ""
    property string currentRuc: ""
    property string currentBusinessName: ""
    property string currentAddress: ""
}
```

### Transferencia de Datos

#### Paso 1: Botón "Procesar Venta" → Propiedades temporales
```qml
onClicked: {
    root.currentCustomerName = customerComboBox.currentText
    root.currentRuc = facturaRadio.checked ? rucField.text : ""
    root.currentBusinessName = facturaRadio.checked ? businessNameField.text : ""
    root.currentAddress = facturaRadio.checked ? addressField.text : ""
    
    viewModel.processSaleWithInvoiceData(...)
}
```

#### Paso 2: onSaleCompleted → SaleSuccessDialog
```qml
onSaleCompleted: function(invoiceNumber, total, voucherType, items, subtotal, discount) {
    successDialog.invoiceNumber = invoiceNumber
    successDialog.total = total
    successDialog.voucherType = voucherType  // "BOLETA" o "FACTURA"
    successDialog.items = items
    successDialog.subtotal = subtotal
    successDialog.discount = discount
    
    // Desde propiedades temporales
    successDialog.customerName = root.currentCustomerName
    successDialog.ruc = root.currentRuc
    successDialog.businessName = root.currentBusinessName
    successDialog.address = root.currentAddress
    
    successDialog.open()
}
```

#### Paso 3: SaleSuccessDialog → PrintDialog
```qml
SaleSuccessDialog {
    id: successDialog
    
    onPrintRequested: {
        var voucherType = successDialog.voucherType === "FACTURA"
                        ? PrintViewModel.Factura
                        : PrintViewModel.Boleta
        
        printDialog.invoiceNumber = successDialog.invoiceNumber
        printDialog.customerName = successDialog.customerName
        printDialog.items = successDialog.items
        printDialog.subtotal = successDialog.subtotal
        printDialog.discount = successDialog.discount
        printDialog.total = successDialog.total
        printDialog.voucherType = voucherType  // Enum: 0 o 1
        printDialog.ruc = successDialog.ruc
        printDialog.businessName = successDialog.businessName
        printDialog.address = successDialog.address
        
        printDialog.open()
    }
}
```

#### Paso 4: PrintDialog → PrintViewModel
```qml
// Vista Previa PDF
Button {
    onClicked: {
        var pdfPath = printViewModel.previewPdf(
            printDialog.invoiceNumber,
            printDialog.customerName,
            printDialog.items,
            printDialog.subtotal,
            printDialog.discount,
            printDialog.total,
            printDialog.voucherType,  // Enum
            printDialog.ruc,
            printDialog.businessName,
            printDialog.address
        )
    }
}

// Imprimir
Button {
    onClicked: {
        var success = printViewModel.printVoucher(
            printDialog.invoiceNumber,
            printDialog.customerName,
            printDialog.items,
            printDialog.subtotal,
            printDialog.discount,
            printDialog.total,
            printDialog.voucherType,  // Enum
            printDialog.ruc,
            printDialog.businessName,
            printDialog.address
        )
    }
}
```

## Estructura de Datos

### VoucherType (Conversión)

```
QML String → QML Enum → C++ Enum

"BOLETA"  →  PrintViewModel.Boleta  (0)  →  PdfGeneratorService::Boleta
"FACTURA" →  PrintViewModel.Factura (1)  →  PdfGeneratorService::Factura
```

### Items Array

```javascript
items = [
    {
        productName: "Producto A",
        quantity: 2.0,
        unitPrice: 50.00,
        subtotal: 100.00
    },
    {
        productName: "Producto B",
        quantity: 1.0,
        unitPrice: 50.00,
        subtotal: 50.00
    }
]
```

## Componentes Involucrados

1. **SalesPage.qml** - Página principal de ventas
2. **SaleSuccessDialog.qml** - Diálogo de confirmación
3. **PrintDialog.qml** - Diálogo de configuración de impresión
4. **PrintViewModel** (C++) - Lógica de impresión
5. **PdfGeneratorService** (C++) - Generación de PDF
6. **PrintService** (C++) - Servicio de impresión

## Configuración de Impresora

El usuario puede configurar:

1. **Impresora predeterminada**: Desde PrinterSettingsDialog o PrintDialog
2. **Tamaño de papel**: A4, Carta, Térmico 80mm, Térmico 58mm
3. **Información del negocio**: Nombre, RUC, Dirección, Teléfono, Email

Esta configuración se guarda en PrintViewModel y se usa para todas las impresiones.

## Troubleshooting

### Problema: "No se pasan los datos del cliente"
**Solución**: Los datos se guardan en `root.current*` antes de procesar la venta, y se asignan al diálogo en `onSaleCompleted`.

### Problema: "VoucherType incorrecto"
**Solución**: Se convierte de String ("BOLETA"/"FACTURA") a Enum (0/1) en `onPrintRequested`.

### Problema: "Items vacíos en impresión"
**Solución**: Los items se pasan desde el ViewModel en el signal `saleCompleted`.

---

**Fecha**: 31 de diciembre de 2025  
**Estado**: ✅ Completamente funcional
