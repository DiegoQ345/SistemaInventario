# Refactorización de Diálogos en SalesPage

## Resumen de Cambios

Se han extraído todos los diálogos de `SalesPage.qml` en componentes separados para mejorar la organización, mantenibilidad y evitar problemas de sintaxis causados por archivos muy grandes.

## Archivos Creados

### 1. `qml/components/dialogs/SaleSuccessDialog.qml` (137 líneas)
**Propósito:** Diálogo de confirmación cuando una venta se completa exitosamente.

**Propiedades:**
- `invoiceNumber` (string): Número de factura/boleta
- `total` (real): Total de la venta
- `voucherType` (string): Tipo de comprobante ("BOLETA" o "FACTURA")
- `ruc`, `businessName`, `address` (string): Datos de factura
- `customerName` (string): Nombre del cliente
- `subtotal`, `discount` (real): Detalles financieros
- `items` (var): Array de items vendidos

**Señales:**
- `printRequested()`: Emitida cuando el usuario hace clic en "Imprimir"

**Uso:**
```qml
SaleSuccessDialog {
    id: successDialog
    
    onPrintRequested: {
        // Lógica para abrir diálogo de impresión
        printDialog.open()
    }
}
```

### 2. `qml/components/dialogs/SaleErrorDialog.qml` (37 líneas)
**Propósito:** Diálogo para mostrar errores durante el proceso de venta.

**Propiedades:**
- `errorMessage` (string): Mensaje de error a mostrar

**Uso:**
```qml
SaleErrorDialog {
    id: errorDialog
}

// Para mostrar un error:
errorDialog.errorMessage = "Stock insuficiente"
errorDialog.open()
```

### 3. `qml/components/dialogs/PrintDialog.qml` (252 líneas)
**Propósito:** Diálogo de configuración e impresión de comprobantes.

**Propiedades Requeridas:**
- `printViewModel` (PrintViewModel): Referencia al ViewModel de impresión

**Propiedades:**
- `invoiceNumber` (string): Número de comprobante
- `customerName` (string): Nombre del cliente
- `items` (var): Items a imprimir
- `subtotal`, `discount`, `total` (real): Totales
- `voucherType` (int): Tipo (PrintViewModel.Boleta o PrintViewModel.Factura)
- `ruc`, `businessName`, `address` (string): Datos de factura

**Características:**
- Selector de impresora
- Selector de tamaño de papel (A4, Carta, Térmico 80mm, Térmico 58mm)
- Vista previa del comprobante
- Botones: Vista Previa PDF, Imprimir, Cancelar

**Uso:**
```qml
PrintDialog {
    id: printDialog
    printViewModel: root.printViewModel
}

// Para abrir:
printDialog.invoiceNumber = "B001-00123"
printDialog.total = 150.00
printDialog.open()
```

### 4. `qml/components/dialogs/PrinterSettingsDialog.qml` (171 líneas)
**Propósito:** Diálogo para configurar las opciones predeterminadas de impresión.

**Propiedades Requeridas:**
- `printViewModel` (PrintViewModel): Referencia al ViewModel de impresión

**Características:**
- Selector de impresora predeterminada
- Tamaño de papel predeterminado (A4 o Térmico 80mm)
- Información del negocio (Nombre, RUC, Dirección, Teléfono, Email)

**Uso:**
```qml
PrinterSettingsDialog {
    id: printerSettingsDialog
    printViewModel: root.printViewModel
}
```

## Integración en SalesPage.qml

### Antes (1487 líneas)
El archivo contenía 4 diálogos inline con ~531 líneas de código embebido.

### Después (956 líneas)
Reducción de **531 líneas** (35.7% más pequeño).

Los diálogos ahora se instancian de forma limpia:

```qml
// ===== DIÁLOGOS =====

SaleSuccessDialog {
    id: successDialog
    onPrintRequested: { /* lógica */ }
}

SaleErrorDialog {
    id: errorDialog
}

PrintDialog {
    id: printDialog
    printViewModel: root.printViewModel
}

PrinterSettingsDialog {
    id: printerSettingsDialog
    printViewModel: root.printViewModel
}
```

## Beneficios

### 1. **Mantenibilidad Mejorada**
- Cada diálogo es un archivo independiente
- Más fácil de encontrar y editar código específico
- Reduce la complejidad cognitiva de SalesPage.qml

### 2. **Reutilización**
- Los diálogos pueden usarse en otras páginas si es necesario
- Código DRY (Don't Repeat Yourself)

### 3. **Depuración Simplificada**
- Errores de sintaxis aislados en archivos pequeños
- Mensajes de error más precisos (archivo y línea específicos)
- Menos conflictos de merge en Git

### 4. **Rendimiento**
- QML puede cachear y compilar componentes separados de forma más eficiente
- Carga lazy-loading potencial

### 5. **Testing**
- Cada diálogo puede probarse de forma independiente
- Más fácil crear tests unitarios para cada componente

## Arquitectura MVVM Mantenida

Todos los diálogos siguen el patrón MVVM:
- **NO** contienen lógica de negocio
- Reciben el `printViewModel` como propiedad requerida
- Usan signals para comunicar acciones al padre
- Son completamente declarativos

## Actualización de CMakeLists.txt

Se agregaron los 4 nuevos archivos QML a la configuración:

```cmake
# Diálogos de ventas
qml/components/dialogs/SaleSuccessDialog.qml
qml/components/dialogs/SaleErrorDialog.qml
qml/components/dialogs/PrintDialog.qml
qml/components/dialogs/PrinterSettingsDialog.qml
```

## Compatibilidad

- ✅ Qt 6.10.1
- ✅ Material Design 3
- ✅ Arquitectura MVVM existente
- ✅ Todas las propiedades y señales preservadas
- ✅ Sin cambios en la funcionalidad (solo refactorización)

## Próximos Pasos Recomendados

1. **Migrar diálogos de otras páginas** siguiendo este mismo patrón
2. **Crear tests** para cada diálogo
3. **Documentar casos de uso** con screenshots
4. **Considerar crear más componentes reutilizables** como:
   - `VoucherTypeSelector.qml`
   - `PaymentMethodSelector.qml`
   - `CustomerInfoSection.qml`

## Impacto en el Proyecto

| Métrica | Antes | Después | Mejora |
|---------|-------|---------|--------|
| Líneas en SalesPage.qml | 1487 | 956 | -531 (-35.7%) |
| Archivos de diálogo | 0 | 4 | +4 |
| Total líneas QML | 1487 | 1553 | +66 (+4.4%) |
| Componentes reutilizables | 14 | 18 | +4 |
| Errores de sintaxis | 1 | 0 | -100% |

**Nota:** El ligero aumento en total de líneas QML se debe a la encapsulación adecuada (properties, signals, documentación), pero mejora significativamente la calidad del código.

---

**Fecha:** 31 de diciembre de 2025  
**Arquitecto:** GitHub Copilot  
**Estado:** ✅ Completado y Validado
