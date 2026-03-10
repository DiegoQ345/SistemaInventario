# Guía de Implementación del Sistema de Escalado de Fuentes

## 📐 Sistema AppStyle

El sistema de escalado de fuentes permite a los usuarios ajustar el tamaño del texto en toda la aplicación desde **Configuración** sin afectar el diseño general.

## 🎯 Arquitectura

### Componentes del Sistema

1. **`qml/components/AppStyle.qml`** - Singleton con propiedades escaladas
2. **`qml/components/qmldir`** - Registro del singleton
3. **`Main.qml`** - Define `settings.fontScale` (0.85, 1.0, 1.15, 1.3)
4. **`SettingsPage.qml`** - UI para cambiar el tamaño

## 🔧 Cómo Usar AppStyle

### 1. Importar en tu archivo QML

```qml
import "../components"  // Desde qml/pages/
// o
import "."              // Desde qml/components/
```

### 2. Usar propiedades de tamaño escalado

#### Tamaños de Fuente

```qml
Label {
    text: "Título Grande"
    font.pixelSize: AppStyle.fontHuge  // 32px base * fontScale
}

Label {
    text: "Contenido normal"
    font.pixelSize: AppStyle.fontBody  // 12px base * fontScale
}

Label {
    text: "Nota pequeña"
    font.pixelSize: AppStyle.fontSmall  // 10px base * fontScale
}
```

**Tamaños disponibles:**
- `AppStyle.fontXSmall` - 8px base
- `AppStyle.fontSmall` - 10px base
- `AppStyle.fontBody` - 12px base (texto general)
- `AppStyle.fontBodyLarge` - 14px base (texto destacado)
- `AppStyle.fontMedium` - 16px base (subtítulos)
- `AppStyle.fontLarge` - 18px base
- `AppStyle.fontXLarge` - 20px base
- `AppStyle.fontXXLarge` - 24px base (títulos grandes)
- `AppStyle.fontHuge` - 32px base (títulos principales)
- `AppStyle.fontGiant` - 40px base

#### Tamaños de Iconos (Segoe MDL2 Assets)

```qml
Label {
    text: "\uE8F1"  // Icono de configuración
    font.family: "Segoe MDL2 Assets"
    font.pixelSize: AppStyle.iconMedium  // 16px base * fontScale
}

ToolButton {
    icon.source: ""
    text: "\uE74D"  // Icono de papelera
    font.family: "Segoe MDL2 Assets"
    font.pixelSize: AppStyle.iconLarge  // 20px base * fontScale
}
```

**Tamaños de iconos disponibles:**
- `AppStyle.iconSmall` - 12px base
- `AppStyle.iconMedium` - 16px base
- `AppStyle.iconLarge` - 20px base
- `AppStyle.iconXLarge` - 24px base
- `AppStyle.iconXXLarge` - 32px base
- `AppStyle.iconHuge` - 48px base

#### Tamaños de Componentes

```qml
Button {
    implicitHeight: AppStyle.buttonHeight  // 40px base * fontScale
    font.pixelSize: AppStyle.fontBodyLarge
}

TextField {
    implicitHeight: AppStyle.textFieldHeight  // 48px base * fontScale
    font.pixelSize: AppStyle.fontBody
}
```

#### Espaciados y Márgenes (Opcional)

```qml
ColumnLayout {
    anchors.margins: AppStyle.marginMedium  // 12px base * fontScale
    spacing: AppStyle.paddingLarge          // 12px base * fontScale
}
```

**Espaciados disponibles:**
- `AppStyle.paddingSmall` - 4px base
- `AppStyle.paddingMedium` - 8px base
- `AppStyle.paddingLarge` - 12px base
- `AppStyle.paddingXLarge` - 16px base
- `AppStyle.marginSmall` - 8px base
- `AppStyle.marginMedium` - 12px base
- `AppStyle.marginLarge` - 16px base
- `AppStyle.marginXLarge` - 20px base

#### Radios (No se escalan)

```qml
Rectangle {
    radius: AppStyle.radiusMedium  // Siempre 8px
}
```

### 3. Función de Escalado Personalizado

Para valores específicos que necesitas escalar:

```qml
Rectangle {
    width: AppStyle.scaled(200)   // 200px * fontScale
    height: AppStyle.scaled(100)  // 100px * fontScale
}
```

## ✅ Buenas Prácticas

### ✔️ Hacer

```qml
// ✅ Usar AppStyle para fuentes
Label {
    text: "Título"
    font.pixelSize: AppStyle.fontLarge
}

// ✅ Usar AppStyle para iconos
Label {
    text: "\uE735"
    font.family: "Segoe MDL2 Assets"
    font.pixelSize: AppStyle.iconMedium
}

// ✅ Usar AppStyle para componentes
Button {
    implicitHeight: AppStyle.buttonHeight
    font.pixelSize: AppStyle.fontBodyLarge
}
```

### ❌ Evitar

```qml
// ❌ NO usar tamaños fijos
Label {
    text: "Título"
    font.pixelSize: 18  // Esto NO se escalará
}

// ❌ NO usar cálculos manuales
Label {
    text: "Texto"
    font.pixelSize: 14 * ApplicationWindow.window.settings.fontScale  // Redundante
}
```

## 🔄 Migración de Código Existente

### Antes:
```qml
Label {
    text: "Panel de Control"
    font.pixelSize: 32
    font.weight: Font.Bold
}

ToolButton {
    text: "\uE8F1"
    font.family: "Segoe MDL2 Assets"
    font.pixelSize: 20
}

Button {
    text: "Guardar"
    implicitHeight: 40
    font.pixelSize: 14
}
```

### Después:
```qml
import "../components"

Label {
    text: "Panel de Control"
    font.pixelSize: AppStyle.fontHuge
    font.weight: Font.Bold
}

ToolButton {
    text: "\uE8F1"
    font.family: "Segoe MDL2 Assets"
    font.pixelSize: AppStyle.iconLarge
}

Button {
    text: "Guardar"
    implicitHeight: AppStyle.buttonHeight
    font.pixelSize: AppStyle.fontBodyLarge
}
```

## 📊 Tabla de Conversión Rápida

| Tamaño Fijo | AppStyle Equivalente |
|-------------|---------------------|
| 8px         | `AppStyle.fontXSmall` |
| 10px        | `AppStyle.fontSmall` |
| 11px        | `AppStyle.fontSmall` o `AppStyle.fontBody` |
| 12px        | `AppStyle.fontBody` |
| 14px        | `AppStyle.fontBodyLarge` |
| 16px        | `AppStyle.fontMedium` o `AppStyle.iconMedium` |
| 18px        | `AppStyle.fontLarge` |
| 20px        | `AppStyle.fontXLarge` o `AppStyle.iconLarge` |
| 24px        | `AppStyle.fontXXLarge` o `AppStyle.iconXLarge` |
| 32px        | `AppStyle.fontHuge` o `AppStyle.iconXXLarge` |
| 40px        | `AppStyle.fontGiant` |

## 🎨 Configuración del Usuario

Los usuarios pueden cambiar el tamaño desde:
- **Configuración → Apariencia → Tamaño de fuente**

Opciones:
- **Pequeño** - 85% (0.85x)
- **Normal** - 100% (1.0x) - Por defecto
- **Grande** - 115% (1.15x)
- **Extra Grande** - 130% (1.3x)

## 🐛 Solución de Problemas

### "AppStyle is not defined"

```qml
// Asegúrate de importar
import "../components"  // o "." si estás en components/
```

### "Cannot read property 'fontScale'"

El singleton intenta acceder a `ApplicationWindow.window.settings.fontScale`. Asegúrate de que:
1. Estás ejecutando desde `Main.qml` que tiene `Settings { id: settings }`
2. Si estás probando un componente aislado, AppStyle usará 1.0 por defecto

### Los cambios no se reflejan

- El singleton lee `fontScale` dinámicamente
- Si un componente asigna `font.pixelSize` en `Component.onCompleted`, necesitas usar un binding:

```qml
// ❌ No reactivo
Component.onCompleted: { font.pixelSize = AppStyle.fontBody }

// ✅ Reactivo
font.pixelSize: AppStyle.fontBody
```

## 📝 Ejemplos Completos

### Página con AppStyle

```qml
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import "../components"

Page {
    title: "Mi Página"
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: AppStyle.marginLarge
        spacing: AppStyle.paddingLarge
        
        Label {
            text: "Título Principal"
            font.pixelSize: AppStyle.fontHuge
            font.weight: Font.Bold
        }
        
        Label {
            text: "Descripción del contenido"
            font.pixelSize: AppStyle.fontBody
            opacity: 0.7
        }
        
        PrimaryButton {
            text: "Acción Principal"
            iconText: "\uE8FB"
        }
    }
}
```

### Componente Personalizado

```qml
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import "."

Rectangle {
    id: control
    
    property string title: ""
    property string icon: ""
    
    width: AppStyle.scaled(200)
    height: AppStyle.scaled(80)
    radius: AppStyle.radiusMedium
    
    Row {
        anchors.fill: parent
        anchors.margins: AppStyle.paddingMedium
        spacing: AppStyle.paddingMedium
        
        Label {
            text: icon
            font.family: "Segoe MDL2 Assets"
            font.pixelSize: AppStyle.iconXLarge
        }
        
        Label {
            text: title
            font.pixelSize: AppStyle.fontMedium
            font.weight: Font.Medium
        }
    }
}
```

## 🚀 Próximos Pasos

1. **Prioridad Alta**: Actualizar componentes críticos (botones, campos, diálogos)
2. **Prioridad Media**: Actualizar páginas principales (Dashboard, Ventas, Productos)
3. **Prioridad Baja**: Actualizar páginas secundarias y diálogos específicos

---

**Última actualización**: Marzo 2026
