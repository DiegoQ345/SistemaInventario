# 🎨 Guía Rápida de Componentes

## Importar Componentes

```qml
import "qml/components"  // Desde páginas
// o
import "../components"   // Si estás en qml/pages/
```

## Ejemplos Prácticos

### Formulario con Validación

```qml
Page {
    ColumnLayout {
        spacing: 16
        
        StyledGroupBox {
            title: "Datos del Producto"
            Layout.fillWidth: true
            
            ColumnLayout {
                SearchField {
                    id: searchField
                    placeholderText: "Buscar por código..."
                }
                
                TextField { placeholderText: "Nombre" }
                
                QuantitySpinBox {
                    id: quantitySpinBox
                    decimals: 2
                }
            }
        }
        
        RowLayout {
            SecondaryButton {
                text: "Cancelar"
                onClicked: cancel()
            }
            
            PrimaryButton {
                text: "Guardar"
                icon: "\uE74E"
                onClicked: save()
            }
        }
    }
}
```

### Diálogo de Confirmación de Eliminación

```qml
Page {
    ConfirmDialog {
        id: confirmDelete
        message: "¿Eliminar este producto?"
        icon: "\uE74D"
        iconColor: Material.color(Material.Red)
        confirmText: "Eliminar"
        
        onConfirmed: {
            viewModel.deleteProduct(selectedId)
        }
    }
    
    ErrorDialog {
        id: errorDialog
    }
    
    SuccessDialog {
        id: successDialog
    }
    
    Button {
        text: "Eliminar"
        onClicked: confirmDelete.open()
    }
}
```

### Dashboard con Tarjetas

```qml
Page {
    GridLayout {
        columns: 4
        rowSpacing: 16
        columnSpacing: 16
        
        StatCard {
            title: "Ventas Hoy"
            value: "S/" + sales.toFixed(2)
            subtitle: count + " ventas"
            icon: "󰄫"
            accentColor: Material.color(Material.Green)
        }
        
        StatCard {
            title: "Stock Bajo"
            value: lowStock.toString()
            subtitle: "Requieren atención"
            icon: "󰀦"
            accentColor: Material.color(Material.Orange)
            warning: lowStock > 0
        }
    }
}
```

### Búsqueda con Resultados

```qml
Page {
    ColumnLayout {
        SearchField {
            id: searchField
            Layout.fillWidth: true
            onTextChanged: model.search(text)
        }
        
        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: productsModel
            
            // Mostrar spinner mientras carga
            header: Item {
                width: parent.width
                height: model.isLoading ? 60 : 0
                visible: model.isLoading
                
                LoadingSpinner {
                    anchors.centerIn: parent
                }
            }
        }
    }
}
```

### Botones con Iconos

```qml
RowLayout {
    // Botón primario con icono
    PrimaryButton {
        text: "Nueva Venta"
        icon: "\uE710"  // + Add
        onClicked: newSale()
    }
    
    // Botón secundario
    SecondaryButton {
        text: "Cancelar"
        icon: "\uE711"  // ✕ Close
        onClicked: cancel()
    }
    
    // Botón con color personalizado
    OutlinedButton {
        text: "Imprimir"
        icon: "\uE749"  // 🖨️ Print
        accentColor: Material.color(Material.Blue)
        onClicked: print()
    }
}
```

### Notificación con Badge

```qml
ToolBar {
    RoundButton {
        text: "\uE7E7"  // 🔔 Bell
        
        Badge {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 4
            value: notificationCount
        }
        
        onClicked: notificationsMenu.open()
    }
}
```

## 🎯 Iconos MDL2 Comunes

```qml
// Acciones
"\uE710"  // + Add
"\uE711"  // ✕ Close
"\uE74E"  // 💾 Save
"\uE74D"  // 🗑️ Delete
"\uE70F"  // ✎ Edit
"\uE721"  // 🔍 Search
"\uE72E"  // ↻ Refresh

// Documentos
"\uE749"  // 🖨️ Print
"\uE8A5"  // 📄 Document
"\uE8B7"  // 📊 Chart
"\uE8F1"  // 📁 Folder

// Navegación
"\uE76B"  // ← Back
"\uE76C"  // → Forward
"\uE74A"  // ▼ Dropdown
"\uE74B"  // ▲ Up

// Estado
"\uE73E"  // ✓ Checkmark
"\uE783"  // ❌ Error
"\uE8FB"  // ⚠️ Warning
"\uEA39"  // ℹ️ Info

// Comercio
"\uE7BF"  // 🛒 Shopping Cart
"\uE825"  // 💰 Money
"\uE7C1"  // 📦 Package
"\uE8EB"  // 📈 Trending Up
```

## 📋 Checklist de Migración

Si estás actualizando código existente para usar componentes:

- [ ] Reemplazar `Button` con `PrimaryButton`, `SecondaryButton` o `OutlinedButton`
- [ ] Reemplazar `TextField` de búsqueda con `SearchField`
- [ ] Reemplazar `SpinBox` de cantidades con `QuantitySpinBox`
- [ ] Reemplazar diálogos custom con `ConfirmDialog`, `ErrorDialog` o `SuccessDialog`
- [ ] Reemplazar `GroupBox` con `StyledGroupBox`
- [ ] Usar `StatCard` para estadísticas en Dashboard
- [ ] Agregar `LoadingSpinner` durante operaciones asíncronas
- [ ] Usar `Badge` para contadores de notificaciones

## 🔧 Personalización

Todos los componentes respetan el tema Material Design configurado en Main.qml:

```qml
// Los componentes usan automáticamente:
Material.primary      // Color primario del tema
Material.background   // Color de fondo
Material.foreground   // Color de texto
Material.frameColor   // Color de bordes

// Para personalizar un componente específico:
PrimaryButton {
    Material.background: Material.color(Material.Green)
}
```

## ⚡ Performance

- Los componentes son **ligeros** y **reutilizables**
- Usan **property binding** para actualizaciones automáticas
- Incluyen **animaciones suaves** (150ms) para transiciones
- **Lazy loading**: Solo se instancian cuando se usan

## 📚 Recursos

- [Material Design Icons (MDL2)](https://learn.microsoft.com/en-us/windows/apps/design/style/segoe-ui-symbol-font)
- [Qt Quick Controls](https://doc.qt.io/qt-6/qtquickcontrols-index.html)
- [Material Design 3](https://m3.material.io/)
