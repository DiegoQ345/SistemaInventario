# Componentes Reutilizables QML

Este directorio contiene componentes QML reutilizables para la aplicación Sistema de Inventario, diseñados siguiendo Material Design 3 y la arquitectura MVVM del proyecto.

## 🎨 Sistema de Estilos Global (AppStyle)

El singleton `AppStyle` proporciona tamaños de fuente e iconos escalables que responden a la configuración del usuario en Ajustes.

### Uso de AppStyle

**Importar en tu archivo QML:**
```qml
import "../components"  // Si estás en qml/pages/
// o
import "."  // Si estás en qml/components/
```

**Tamaños de fuente disponibles:**
```qml
Label {
    text: "Ejemplo"
    font.pixelSize: AppStyle.fontBody        // 12px escalado
    // Opciones:
    // AppStyle.fontXSmall      -> 8px base
    // AppStyle.fontSmall       -> 10px base
    // AppStyle.fontBody        -> 12px base
    // AppStyle.fontBodyLarge   -> 14px base
    // AppStyle.fontMedium      -> 16px base
    // AppStyle.fontLarge       -> 18px base
    // AppStyle.fontXLarge      -> 20px base
    // AppStyle.fontXXLarge     -> 24px base
    // AppStyle.fontHuge        -> 32px base
}
```

**Tamaños de iconos (Segoe MDL2 Assets):**
```qml
Label {
    text: "\uE8F1"  // Icono
    font.family: "Segoe MDL2 Assets"
    font.pixelSize: AppStyle.iconMedium      // 16px escalado
    // Opciones:
    // AppStyle.iconSmall       -> 12px base
    // AppStyle.iconMedium      -> 16px base
    // AppStyle.iconLarge       -> 20px base
    // AppStyle.iconXLarge      -> 24px base
    // AppStyle.iconXXLarge     -> 32px base
    // AppStyle.iconHuge        -> 48px base
}
```

**Función de escalado personalizado:**
```qml
Rectangle {
    width: AppStyle.scaled(200)   // Escala 200px según fontScale
    height: AppStyle.scaled(50)
}
```

**⚠️ Importante:**
- Todos los nuevos componentes deben usar `AppStyle` en lugar de valores fijos
- Los cambios de tamaño se aplican inmediatamente en toda la aplicación
- Los espacios y márgenes también pueden escalarse con `AppStyle.paddingMedium`, etc.

---

## 📂 Índice de Componentes

### Botones
- [PrimaryButton](#primarybutton) - Botón principal con fondo de color
- [SecondaryButton](#secondarybutton) - Botón secundario con borde
- [OutlinedButton](#outlinedbutton) - Botón con borde de color personalizado

### Inputs
- [SearchField](#searchfield) - Campo de búsqueda con icono y botón de limpiar
- [QuantitySpinBox](#quantityspinbox) - SpinBox para cantidades con decimales
- [NumPad](#numpad) - Teclado numérico para pantallas táctiles

### Diálogos
- [ConfirmDialog](#confirmdialog) - Diálogo de confirmación genérico
- [ErrorDialog](#errordialog) - Diálogo para mostrar errores
- [SuccessDialog](#successdialog) - Diálogo de éxito con acción opcional

### Contenedores
- [StyledGroupBox](#styledgroupbox) - GroupBox con estilos personalizados
- [StatCard](#statcard) - Tarjeta de estadísticas para Dashboard

### Otros
- [Badge](#badge) - Insignia numérica para notificaciones
- [LoadingSpinner](#loadingspinner) - Indicador de carga
- [NotificationBar](#notificationbar) - Barra de notificaciones global
- [CartItemDelegate](#cartitemdelegate) - Delegate para items del carrito

---

## 🎨 Componentes de Botones

### PrimaryButton

Botón principal con fondo de color Material Design.

**Propiedades:**
```qml
property string icon: ""           // Icono MDL2 opcional
property bool isIconFont: true     // Si el icono es de fuente MDL2
property int iconSize: 16          // Tamaño del icono
```

**Ejemplo de uso:**
```qml
import "qml/components"

PrimaryButton {
    text: "Guardar"
    icon: "\uE74E"  // 💾 Save icon
    onClicked: saveData()
}
```

### SecondaryButton

Botón secundario con fondo transparente y borde.

**Propiedades:**
```qml
property string icon: ""           // Icono MDL2 opcional
property bool isIconFont: true     // Si el icono es de fuente MDL2
property int iconSize: 16          // Tamaño del icono
```

**Ejemplo de uso:**
```qml
import "qml/components"

SecondaryButton {
    text: "Cancelar"
    icon: "\uE711"  // ✕ Close icon
    onClicked: dialog.close()
}
```

### OutlinedButton

Botón con borde de color personalizado.

**Propiedades:**
```qml
property string icon: ""           // Icono MDL2 opcional
property bool isIconFont: true     // Si el icono es de fuente MDL2
property color accentColor: Material.primary  // Color del borde y texto
```

**Ejemplo de uso:**
```qml
import "qml/components"

OutlinedButton {
    text: "Imprimir"
    icon: "\uE749"  // 🖨️ Printer icon
    accentColor: Material.color(Material.Blue)
    onClicked: printDocument()
}
```

---

## 📝 Componentes de Inputs

### SearchField

Campo de búsqueda con icono y botón para limpiar.

**Propiedades:**
```qml
property string searchIcon: "\uE721"  // Icono de búsqueda
property bool showClearButton: text.length > 0  // Mostrar botón limpiar
```

**Ejemplo de uso:**
```qml
import "qml/components"

SearchField {
    id: searchField
    placeholderText: "Buscar productos..."
    Layout.fillWidth: true
    
    onTextChanged: productsModel.searchProducts(text)
}
```

### QuantitySpinBox

SpinBox para cantidades con soporte de decimales.

**Propiedades:**
```qml
property int decimals: 2              // Número de decimales
property real realValue: value / factor  // Valor real con decimales
property real realFrom: from / factor    // Mínimo real
property real realTo: to / factor        // Máximo real
property real realStepSize: stepSize / factor  // Paso real
```

**Ejemplo de uso:**
```qml
import "qml/components"

QuantitySpinBox {
    id: quantitySpinBox
    decimals: 2
    realFrom: 0.01
    realTo: 999.99
    realValue: 1.00
    
    onValueModified: updateQuantity(realValue)
}
```

---

## 💬 Componentes de Diálogos

### ConfirmDialog

Diálogo genérico de confirmación con icono personalizable.

**Propiedades:**
```qml
property string message: ""              // Mensaje a mostrar
property string icon: "\uE8FB"           // Icono (default: warning)
property color iconColor: Material.color(Material.Orange)
property string confirmText: "Confirmar" // Texto botón confirmar
property string cancelText: "Cancelar"   // Texto botón cancelar
```

**Señales:**
```qml
signal confirmed()  // Emitido al confirmar
signal cancelled()  // Emitido al cancelar
```

**Ejemplo de uso:**
```qml
import "qml/components"

ConfirmDialog {
    id: deleteDialog
    message: "¿Estás seguro de eliminar este producto?"
    icon: "\uE74D"  // 🗑️ Delete icon
    iconColor: Material.color(Material.Red)
    confirmText: "Eliminar"
    
    onConfirmed: {
        deleteProduct()
    }
}

// Abrir diálogo
Button {
    text: "Eliminar"
    onClicked: deleteDialog.open()
}
```

### ErrorDialog

Diálogo para mostrar mensajes de error.

**Propiedades:**
```qml
property string errorMessage: ""   // Mensaje de error
property string errorIcon: "\uE783"  // Icono (default: error)
```

**Ejemplo de uso:**
```qml
import "qml/components"

ErrorDialog {
    id: errorDialog
}

// Mostrar error
onErrorOccurred: function(message) {
    errorDialog.errorMessage = message
    errorDialog.open()
}
```

### SuccessDialog

Diálogo de éxito con botón de acción opcional.

**Propiedades:**
```qml
property string message: ""              // Mensaje de éxito
property string successIcon: "\uE8FB"    // Icono (default: checkmark)
property string actionText: ""           // Texto del botón de acción
property bool showActionButton: actionText !== ""  // Mostrar botón acción
```

**Señales:**
```qml
signal actionClicked()  // Emitido al hacer clic en acción
```

**Ejemplo de uso:**
```qml
import "qml/components"

SuccessDialog {
    id: successDialog
    message: "Venta procesada correctamente"
    actionText: "Imprimir Comprobante"
    
    onActionClicked: {
        printVoucher()
    }
}
```

---

## 📦 Componentes de Contenedores

### StyledGroupBox

GroupBox con estilos Material Design personalizados.

**Propiedades:**
```qml
property color accentColor: Material.primary  // Color del título
property bool showBorder: true                // Mostrar borde
```

**Ejemplo de uso:**
```qml
import "qml/components"

StyledGroupBox {
    title: "Información del Producto"
    accentColor: Material.color(Material.Blue)
    Layout.fillWidth: true
    
    ColumnLayout {
        TextField { placeholderText: "Nombre" }
        TextField { placeholderText: "SKU" }
    }
}
```

### StatCard

Tarjeta de estadísticas para Dashboard con icono y valores.

**Propiedades:**
```qml
property string title: ""        // Título de la estadística
property string value: ""        // Valor principal
property string subtitle: ""     // Subtítulo o detalle
property string icon: ""         // Icono
property color accentColor: Material.primary  // Color del acento
property bool warning: false     // Mostrar como advertencia
```

**Ejemplo de uso:**
```qml
import "qml/components"

StatCard {
    Layout.fillWidth: true
    Layout.preferredHeight: 120
    title: "Ventas del Día"
    value: "S/" + viewModel.todaySales.toFixed(2)
    subtitle: viewModel.todayTransactions + " transacciones"
    icon: "󰄫"
    accentColor: Material.color(Material.Green)
}

StatCard {
    Layout.fillWidth: true
    Layout.preferredHeight: 120
    title: "Stock Bajo"
    value: viewModel.lowStockProducts.toString()
    subtitle: "Requieren atención"
    icon: "󰀦"
    accentColor: Material.color(Material.Orange)
    warning: viewModel.lowStockProducts > 0
}
```

---

## 🔔 Otros Componentes

### Badge

Insignia numérica para notificaciones (como contador de items).

**Propiedades:**
```qml
property int value: 0                    // Valor a mostrar
property int maxValue: 99                // Valor máximo antes de "+"
property color badgeColor: Material.color(Material.Red)  // Color
```

**Ejemplo de uso:**
```qml
import "qml/components"

RoundButton {
    text: "\uE7E7"  // 🔔 Bell icon
    
    Badge {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 4
        value: notificationCount
    }
}
```

### LoadingSpinner

Indicador de carga circular.

**Propiedades:**
```qml
property bool running: true            // Si está girando
property int size: 48                  // Tamaño del spinner
property color spinnerColor: Material.primary  // Color
property int lineWidth: 4              // Grosor de línea
```

**Ejemplo de uso:**
```qml
import "qml/components"

Rectangle {
    visible: isLoading
    
    LoadingSpinner {
        anchors.centerIn: parent
        size: 64
        spinnerColor: Material.color(Material.Blue)
    }
}
```

### NotificationBar

**Descripción:** Componente para mostrar un item individual en el carrito de compras.

**Propiedades:**
- `productId: int` (required) - ID del producto
- `productName: string` (required) - Nombre del producto
- `quantity: real` (required) - Cantidad en el carrito
- `unitPrice: real` (required) - Precio unitario
- `subtotal: real` (required) - Subtotal del item
- `maxQuantity: real` (required) - Stock máximo disponible

**Señales:**
- `quantityChanged(int productId, real newQuantity)` - Emitido cuando cambia la cantidad
- `removeClicked(int productId)` - Emitido cuando se presiona el botón eliminar

**Uso en SalesPage.qml:**
```qml
ListView {
    model: viewModel.cart
    
    delegate: CartItemDelegate {
        productId: model.productId
        productName: model.productName
        quantity: model.quantity
        unitPrice: model.unitPrice
        subtotal: model.subtotal
        maxQuantity: model.maxQuantity
        
        onQuantityChanged: function(prodId, newQty) {
            updateCartItemQuantityByProductId(prodId, newQty)
        }
        
        onRemoveClicked: function(prodId) {
            removeCartItemByProductId(prodId)
        }
    }
}
```

**Características:**
- ✅ Diseño Material Design 3
- ✅ Efecto hover con animación
- ✅ Sombra simulada para profundidad
- ✅ Indicador lateral colorido
- ✅ SpinBox para ajustar cantidad
- ✅ Botón de eliminación con confirmación visual
- ✅ Responsive a cambios de tema (claro/oscuro)

---

### NumPad

Teclado numérico estilo calculadora para ingreso de montos en pantallas táctiles.

**Propiedades:**
```qml
property TextField targetField: null  // Campo de texto vinculado
```

**Ejemplo de uso:**
```qml
import "qml/components"

RowLayout {
    TextField {
        id: amountField
        placeholderText: "Ingrese monto"
    }
    
    Button {
        text: "🔢"
        onClicked: numPadPopup.open()
    }
}

Popup {
    id: numPadPopup
    anchors.centerIn: parent
    modal: true
    
    NumPad {
        targetField: amountField
    }
}
```

**Funcionalidades:**
- ✅ Teclas numéricas 0-9
- ✅ Punto decimal (solo uno permitido)
- ✅ Botón Clear (C) para limpiar
- ✅ Botón Backspace (←) para borrar último dígito
- ✅ Botón OK para cerrar el teclado
- ✅ Display en tiempo real del valor
- ✅ Validación automática de entrada
- ✅ Límite de 10 caracteres
- ✅ Diseño Material Design con sombra
- ✅ Responsive a tema claro/oscuro

**Teclas disponibles:**
```
┌─────┬─────┬─────┐
│  7  │  8  │  9  │
├─────┼─────┼─────┤
│  4  │  5  │  6  │
├─────┼─────┼─────┤
│  1  │  2  │  3  │
├─────┼─────┼─────┤
│  C  │  0  │  .  │
└─────┴─────┴─────┘
┌──────────┬────────┐
│    ←     │   OK   │
└──────────┴────────┘
```

**Integración en SalesPage:**
- Se activa con el botón de calculadora (🔢) junto al campo "Monto Pagado"
- Solo visible cuando el método de pago es "Efectivo"
- Facilita el ingreso rápido en pantallas táctiles y tablets

---

## 🚀 Componentes Futuros (Planificados)

### VoucherPreviewDialog.qml
- Diálogo de vista previa de comprobante
- ~200 líneas extraídas de SalesPage.qml

### SuccessDialog.qml
- Diálogo de confirmación de venta exitosa
- ~100 líneas

### ErrorDialog.qml
- Diálogo de error genérico
- ~50 líneas

### CustomerSelector.qml
- Selector de cliente con GroupBox
- Autocompletado de clientes
- ~80 líneas

### VoucherTypeSelector.qml
- Selector de tipo de comprobante (Boleta/Factura)
- Campos condicionales para RUC
- ~100 líneas

### PaymentMethodSelector.qml
- Selector de método de pago
- ~50 líneas

---

## 📝 Guía de Creación de Componentes

### 1. Estructura Básica

```qml
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

/**
 * @brief Descripción breve del componente
 * 
 * Descripción detallada...
 */
Item {
    id: root
    
    // Propiedades públicas
    required property tipo nombrePropiedad
    property tipo nombreOpcional: valorDefault
    
    // Señales personalizadas
    signal nombreSeñal(tipo parametro)
    
    // Propiedades internas (privadas)
    readonly property tipo nombreInterno: valor
    
    // Contenido del componente
    // ...
}
```

### 2. Convenciones de Nombres

- **Archivos:** PascalCase (ej: `CartItemDelegate.qml`)
- **IDs:** camelCase (ej: `cartItemCard`)
- **Propiedades públicas:** camelCase (ej: `productName`)
- **Señales:** camelCase + participio pasado (ej: `quantityChanged`)

### 3. Propiedades Required vs Opcionales

**Required:** Siempre usar `required` para propiedades obligatorias
```qml
required property int productId
required property string productName
```

**Opcionales:** Proporcionar valor por defecto
```qml
property bool showIcon: true
property int maxItems: 100
```

### 4. Documentación

Siempre incluir comentario JSDoc al inicio:
```qml
/**
 * @brief Descripción corta
 * 
 * Descripción extendida del componente,
 * su propósito y cómo usarlo.
 * 
 * Uso:
 * MiComponente {
 *     prop1: valor1
 *     prop2: valor2
 * }
 */
```

### 5. Señales vs Callbacks

**Preferir señales:**
```qml
signal itemClicked(int itemId)
```

**Evitar callbacks directos:**
```qml
property var onItemClicked: null  // ❌ No recomendado
```

### 6. Estilos y Temas

Siempre usar Material Design:
```qml
color: Material.primary
color: Material.foreground
color: Material.background
```

Soporte para tema claro/oscuro:
```qml
color: Material.theme === Material.Dark ? 
       valorOscuro : 
       valorClaro
```

---

## ✅ Beneficios de Componentización

1. **Reutilización:** Usar el mismo componente en múltiples páginas
2. **Mantenibilidad:** Cambios en un solo lugar
3. **Testing:** Más fácil probar componentes aislados
4. **Rendimiento:** Carga bajo demanda
5. **Legibilidad:** Código más limpio y organizado
6. **Colaboración:** Múltiples desarrolladores trabajando en paralelo

---

## 📚 Referencias

- [Qt QML Documentation](https://doc.qt.io/qt-6/qmlfirststeps.html)
- [Material Design 3](https://m3.material.io/)
- [Qt Quick Controls](https://doc.qt.io/qt-6/qtquickcontrols-index.html)

---

**Última actualización:** 31 de Diciembre de 2025
