pragma Singleton
import QtQuick

QtObject {
    id: appStyle
    
    // Escala de fuente por defecto (1.0 = 100%)
    // NOTA: Este singleton ya no se usa directamente.
    // Usar ApplicationWindow.window.appStyle en su lugar.
    readonly property real fontScale: 1.0
    
    // Tamaños de fuente base NO escalados (valores por defecto)
    readonly property real fontXSmall: 8
    readonly property real fontSmall: 10
    readonly property real fontBody: 12
    readonly property real fontBodyLarge: 14
    readonly property real fontMedium: 16
    readonly property real fontLarge: 18
    readonly property real fontXLarge: 20
    readonly property real fontXXLarge: 24
    readonly property real fontHuge: 32
    readonly property real fontGiant: 40
    
    // Tamaños de iconos NO escalados (valores por defecto)
    readonly property real iconSmall: 12
    readonly property real iconMedium: 16
    readonly property real iconLarge: 20
    readonly property real iconXLarge: 24
    readonly property real iconXXLarge: 32
    readonly property real iconHuge: 48
    
    // Tamaños de componentes NO escalados
    readonly property real buttonHeight: 40
    readonly property real textFieldHeight: 48
    readonly property real toolButtonSize: 40
    
    // Espaciados NO escalados
    readonly property real paddingSmall: 4
    readonly property real paddingMedium: 8
    readonly property real paddingLarge: 12
    readonly property real paddingXLarge: 16
    
    readonly property real marginSmall: 8
    readonly property real marginMedium: 12
    readonly property real marginLarge: 16
    readonly property real marginXLarge: 20
    
    // Radios de borde (estos no se escalan con fuente)
    readonly property real radiusSmall: 4
    readonly property real radiusMedium: 8
    readonly property real radiusLarge: 12
    readonly property real radiusXLarge: 16
    
    // Función auxiliar para escalar valores personalizados
    function scaled(baseValue) {
        return baseValue * fontScale
    }
}
