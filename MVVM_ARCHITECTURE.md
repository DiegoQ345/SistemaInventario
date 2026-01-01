# Arquitectura MVVM - Sistema de Inventario

## 🎯 Principios Arquitectónicos

### ✅ Separación de Responsabilidades

Este proyecto sigue **estrictamente** el patrón **Model-View-ViewModel (MVVM)**:

```
┌─────────────────────────────────────────────────────────┐
│                        QML VIEW                         │
│  - Solo presentación visual                             │
│  - Bindings a propiedades del ViewModel                │
│  - NO contiene lógica de negocio                       │
│  - NO realiza cálculos                                 │
│  - NO manipula datos directamente                     │
└─────────────────────────────────────────────────────────┘
                            ▼
                    Property Bindings
                    Signal/Slot Connections
                            ▼
┌─────────────────────────────────────────────────────────┐
│                      VIEWMODEL (C++)                    │
│  - Expone propiedades Q_PROPERTY para QML              │
│  - Expone métodos Q_INVOKABLE                          │
│  - Contiene lógica de presentación                     │
│  - Valida datos de UI                                  │
│  - Coordina servicios                                  │
│  - Emite señales para eventos                          │
└─────────────────────────────────────────────────────────┘
                            ▼
                    Llama a servicios
                            ▼
┌─────────────────────────────────────────────────────────┐
│                     SERVICES (C++)                      │
│  - Lógica de negocio pura                              │
│  - Acceso a repositorios                               │
│  - Transformación de datos                             │
│  - Reglas de validación                                │
└─────────────────────────────────────────────────────────┘
                            ▼
                    Accede a datos
                            ▼
┌─────────────────────────────────────────────────────────┐
│                  REPOSITORIES (C++)                     │
│  - Acceso a base de datos                              │
│  - CRUD operations                                     │
│  - Queries SQL                                         │
└─────────────────────────────────────────────────────────┘
```

## 📋 Reglas Estrictas

### ❌ PROHIBIDO en las Vistas QML:

1. **Lógica de negocio**: Cálculos, validaciones, transformaciones
2. **Loops de búsqueda**: `for`, `while` para buscar datos
3. **Manipulación de modelos**: Acceso directo a `data()`, `index()`, `rowCount()`
4. **Construcción de objetos**: Crear objetos de negocio
5. **Decisiones de negocio**: Lógica condicional compleja
6. **Acceso a servicios**: Llamadas directas a repositorios o servicios

### ✅ PERMITIDO en las Vistas QML:

1. **Bindings simples**: `text: viewModel.propertyName`
2. **Llamadas a métodos del ViewModel**: `viewModel.methodName(params)`
3. **Lógica de presentación visual**: Mostrar/ocultar, animaciones, colores
4. **Validación básica de UI**: Formato de texto, límites de input
5. **Navegación**: Abrir diálogos, cambiar páginas

## 🏗️ Ejemplo Correcto: SalesPage.qml

### ❌ ANTES (INCORRECTO):

```qml
// ❌ Lógica de negocio en QML
function removeCartItemByProductId(productId) {
    for (let i = 0; i < viewModel.cart.rowCount(); i++) {
        let idx = viewModel.cart.index(i, 0)
        let itemProductId = viewModel.cart.data(idx, 256)
        if (itemProductId === productId) {
            viewModel.cart.removeItem(i)
            return
        }
    }
}

// ❌ Cálculo en la vista
Label {
    text: "S/" + Math.max(0, viewModel.cart.subtotal - discountSpinBox.realValue).toFixed(2)
}

// ❌ Construcción de objetos de negocio
function processSale() {
    let capturedItems = []
    for (let i = 0; i < viewModel.cart.count; i++) {
        let idx = viewModel.cart.index(i, 0)
        capturedItems.push({
            productName: viewModel.cart.data(idx, 257),
            quantity: viewModel.cart.data(idx, 260),
            // ...
        })
    }
    // ❌ Construcción de notas de negocio
    let notes = voucherType
    if (facturaRadio.checked) {
        notes += " - RUC: " + rucField.text
    }
}
```

### ✅ DESPUÉS (CORRECTO):

```qml
// ✅ Llamada directa al ViewModel
Button {
    onClicked: viewModel.cart.removeItemByProductId(model.productId)
}

// ✅ Binding simple a propiedad calculada en ViewModel
Label {
    text: "S/" + viewModel.totalWithDiscount.toFixed(2)
}

// ✅ ViewModel maneja toda la lógica
Button {
    text: "Procesar Venta"
    enabled: viewModel.canProcessSale  // ✅ Validación en ViewModel
    
    onClicked: {
        // ✅ Solo pasar datos, el ViewModel construye el objeto
        viewModel.processSaleWithInvoiceData(
            0,  // customerId
            customerComboBox.currentText,
            paymentMethodComboBox.currentIndex + 1,
            paymentMethodComboBox.currentText,
            facturaRadio.checked,
            rucField.text,
            businessNameField.text,
            addressField.text
        )
    }
}
```

## 🔧 Implementación en ViewModels

### Propiedades Q_PROPERTY

Las propiedades permiten **binding bidireccional** con QML:

```cpp
// SalesCartViewModel.h
class SalesCartViewModel : public QObject
{
    Q_OBJECT
    Q_PROPERTY(double discount READ discount WRITE setDiscount NOTIFY discountChanged)
    Q_PROPERTY(double totalWithDiscount READ totalWithDiscount NOTIFY totalWithDiscountChanged)
    Q_PROPERTY(bool canProcessSale READ canProcessSale NOTIFY canProcessSaleChanged)
    
public:
    double discount() const { return m_discount; }
    void setDiscount(double discount);
    
    double totalWithDiscount() const {
        return qMax(0.0, m_cart->subtotal() - m_discount);
    }
    
    bool canProcessSale() const {
        return m_cart->rowCount() > 0 && !m_isProcessing;
    }
    
signals:
    void discountChanged();
    void totalWithDiscountChanged();
    void canProcessSaleChanged();
};
```

### Métodos Q_INVOKABLE

Exponen funcionalidad al QML:

```cpp
public slots:
    // ✅ Método que opera con productId (mejor para QML)
    Q_INVOKABLE void removeItemByProductId(int productId);
    Q_INVOKABLE void updateQuantityByProductId(int productId, double quantity);
    
    // ✅ Método con toda la lógica de negocio
    Q_INVOKABLE bool processSaleWithInvoiceData(
        int customerId,
        const QString& customerName,
        int paymentMethodId,
        const QString& paymentMethodName,
        bool isInvoice,
        const QString& ruc,
        const QString& businessName,
        const QString& address
    );
```

### Señales con Datos Completos

Las señales deben enviar **todos los datos necesarios** para la UI:

```cpp
signals:
    // ✅ Señal con todos los datos que la UI necesita
    void saleCompleted(
        const QString& invoiceNumber, 
        double total, 
        const QString& voucherType,
        const QVariantList& items,  // Items como QVariantList para QML
        double subtotal, 
        double discount
    );
```

## 📊 Flujo de Datos

### Entrada del Usuario → ViewModel → Servicios

```
Usuario ingresa descuento en SpinBox
           ↓
SpinBox.onValueModified → viewModel.discount = value
           ↓
ViewModel.setDiscount() valida y emite señales
           ↓
totalWithDiscountChanged() actualiza UI automáticamente
```

### Servicios → ViewModel → Vista

```
viewModel.processSaleWithInvoiceData()
           ↓
Captura datos del carrito (itemsAsVariantList())
           ↓
salesService.createSale()
           ↓
emit saleCompleted(invoiceNumber, total, voucherType, items, ...)
           ↓
QML onSaleCompleted: guarda datos y abre diálogo
```

## 🎓 Beneficios de Seguir la Arquitectura

### ✅ Mantenibilidad

- **Cambios aislados**: Modificar lógica sin tocar UI
- **Testing**: ViewModels y Services son testables unitariamente
- **Debugging**: Errores de negocio están en C++, no en QML

### ✅ Reutilización

- **ViewModels compartidos**: Misma lógica para diferentes vistas
- **Servicios independientes**: Pueden usarse desde cualquier ViewModel

### ✅ Performance

- **Cálculos en C++**: Más rápido que JavaScript
- **Bindings eficientes**: Qt optimiza las actualizaciones

### ✅ Escalabilidad

- **Fácil agregar features**: Extender ViewModels sin tocar QML
- **Múltiples UIs**: Desktop, móvil, web pueden compartir ViewModels

## 📝 Checklist para Nuevas Features

Antes de agregar código, pregúntate:

- [ ] ¿Esta lógica pertenece a la vista o al negocio?
- [ ] ¿Estoy haciendo cálculos en QML? → **Moverlos al ViewModel**
- [ ] ¿Estoy buscando datos con loops? → **Método en ViewModel/Model**
- [ ] ¿Estoy construyendo objetos? → **ViewModel debe hacerlo**
- [ ] ¿Esta validación es de UI o de negocio? → **Negocio = ViewModel**
- [ ] ¿Puedo hacer esto con un simple binding? → **Usar Q_PROPERTY**

## 🚀 Resultado Final

Con esta arquitectura, **SalesPage.qml** pasó de **1667 líneas** con lógica compleja a una vista **limpia y mantenible** que solo:

1. **Muestra datos** mediante bindings
2. **Captura entrada** del usuario
3. **Llama métodos** del ViewModel
4. **Reacciona a señales** del ViewModel

**TODA la lógica de negocio** está en los ViewModels y Services C++, donde debe estar.

---

**Mantén esta separación estricta en TODO el proyecto.**
