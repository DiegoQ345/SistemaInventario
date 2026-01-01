# Sistema de Notificaciones Globales

## Arquitectura

Las notificaciones están implementadas como un **componente global reutilizable** en `Main.qml`, siguiendo los principios de la arquitectura MVVM.

### ❌ Antes (Incorrecto)
Cada página tenía su propia barra de notificaciones:
- Código duplicado
- Difícil de mantener
- Inconsistencia visual
- Violaba el principio DRY

### ✅ Ahora (Correcto)
Un solo componente de notificaciones en `Main.qml`:
- Código reutilizable
- Fácil de mantener
- Consistencia visual en toda la aplicación
- Sigue el principio DRY

## Estructura de Archivos

```
qml/
├── components/
│   └── NotificationBar.qml    # Componente reutilizable
└── pages/
    └── SalesPage.qml           # Solo escucha señales del ViewModel
Main.qml                        # Instancia global del componente
```

## Componente NotificationBar

### API Pública

```qml
// Mostrar notificación de éxito (verde)
globalNotification.showSuccess("Operación completada")

// Mostrar notificación de error (rojo)
globalNotification.showError("Error al procesar")

// Mostrar notificación informativa (azul/primary)
globalNotification.showInfo("Información general")
```

### Propiedades Configurables

```qml
NotificationBar {
    id: globalNotification
    displayDuration: 3000  // Duración en milisegundos (default: 3000)
}
```

### Características

- ✅ Auto-cierre después de 3 segundos (configurable)
- ✅ Cierre manual al hacer clic
- ✅ Animaciones suaves de entrada/salida
- ✅ Colores semánticos (éxito=verde, error=rojo, info=primary)
- ✅ z-index alto (999) para estar siempre visible
- ✅ Material Design 3

## Uso en Main.qml

```qml
import "qml/components"

ApplicationWindow {
    id: root
    
    // ... otros componentes ...
    
    // Notificaciones globales
    NotificationBar {
        id: globalNotification
    }
    
    // Conectar señales del ViewModel a notificaciones
    Connections {
        target: salesViewModel
        
        function onProductAdded(productName, quantity) {
            globalNotification.showSuccess("Agregado: " + productName + " (x" + quantity + ")")
        }
        
        function onProductNotFound(code) {
            globalNotification.showError("Producto no encontrado: " + code)
        }
        
        function onInsufficientStock(productName, available, requested) {
            globalNotification.showError(
                "Stock insuficiente de " + productName + 
                ". Disponible: " + available + ", solicitado: " + requested
            )
        }
    }
}
```

## Uso en ViewModels (C++)

Los ViewModels emiten señales que `Main.qml` captura:

```cpp
// SalesCartViewModel.h
signals:
    void productAdded(const QString &productName, double quantity);
    void productNotFound(const QString &code);
    void insufficientStock(const QString &productName, double available, double requested);

// SalesCartViewModel.cpp
emit productAdded(product.name, quantity);
emit productNotFound(code);
emit insufficientStock(product.name, available, requested);
```

## Flujo de Datos

```
ViewModel (C++)
    ↓ emit signal
Main.qml (Connections)
    ↓ captura signal
    ↓ llama a globalNotification.showXXX()
NotificationBar (QML)
    ↓ muestra notificación
Usuario
```

## ⚠️ Reglas Importantes

### ❌ NO HACER en las Páginas

```qml
// ❌ NO crear notificaciones locales
Rectangle {
    id: notificationBar
    // ...
}

// ❌ NO manejar notificaciones directamente
onProductAdded: {
    notificationLabel.text = "Producto agregado"
    notificationLabel.visible = true
}
```

### ✅ SÍ HACER en las Páginas

```qml
// ✅ Solo conectar señales del ViewModel (si es necesario)
SalesCartViewModel {
    id: viewModel
    
    onProductAdded: function(productName, quantity) {
        console.log("Producto agregado:", productName, "x", quantity)
        // Main.qml se encarga de las notificaciones
    }
}
```

### ✅ SÍ HACER en Main.qml

```qml
// ✅ Capturar señales globalmente
Connections {
    target: stackView.currentItem?.viewModel
    ignoreUnknownSignals: true
    
    function onProductAdded(productName, quantity) {
        globalNotification.showSuccess("Agregado: " + productName)
    }
}
```

## Ventajas de Esta Arquitectura

1. **Separación de Responsabilidades**
   - ViewModels: Lógica de negocio y señales
   - Páginas: Presentación de datos
   - Main.qml: Coordinación global y notificaciones

2. **Mantenibilidad**
   - Un solo lugar para modificar el comportamiento de notificaciones
   - Cambios visuales se propagan automáticamente a toda la app

3. **Consistencia**
   - Todas las notificaciones se ven y comportan igual
   - Duraciones y animaciones uniformes

4. **Escalabilidad**
   - Fácil agregar nuevos tipos de notificaciones
   - Fácil agregar características (sonidos, iconos, acciones)

## Futuras Mejoras Posibles

- [ ] Cola de notificaciones (mostrar múltiples)
- [ ] Sonidos para cada tipo de notificación
- [ ] Iconos personalizados por tipo
- [ ] Acciones en notificaciones (botones)
- [ ] Notificaciones persistentes (no auto-cierre)
- [ ] Niveles de prioridad
- [ ] Historial de notificaciones

## Ejemplo Completo

Ver `Main.qml` y `qml/pages/SalesPage.qml` para la implementación completa.
