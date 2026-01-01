import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material

SpinBox {
    id: control
    
    // Propiedades para decimales
    property int decimals: 2
    property real realValue: value / factor
    property real realFrom: from / factor
    property real realTo: to / factor
    property real realStepSize: stepSize / factor
    
    readonly property int factor: Math.pow(10, decimals)
    
    // Configuración por defecto
    from: 0
    to: 999999 * factor
    stepSize: 1 * factor
    value: 1 * factor
    editable: true
    
    implicitHeight: 40
    
    // Validador para decimales
    validator: DoubleValidator {
        bottom: control.realFrom
        top: control.realTo
        decimals: control.decimals
        notation: DoubleValidator.StandardNotation
    }
    
    // Convertir texto a valor
    textFromValue: function(value, locale) {
        return Number(value / factor).toLocaleString(locale, 'f', decimals)
    }
    
    // Convertir valor a texto
    valueFromText: function(text, locale) {
        return Number.fromLocaleString(locale, text) * factor
    }
    
    // Estilos personalizados
    background: Rectangle {
        implicitHeight: 40
        radius: 4
        color: control.enabled ? Material.background : Material.color(Material.Grey, Material.Shade100)
        border.width: control.activeFocus ? 2 : 1
        border.color: control.activeFocus ? Material.primary : Material.frameColor
        
        Behavior on border.color { ColorAnimation { duration: 150 } }
    }
    
    contentItem: TextInput {
        text: control.textFromValue(control.value, control.locale)
        font: control.font
        color: control.Material.foreground
        selectionColor: Material.primary
        selectedTextColor: Material.theme === Material.Dark ? Material.background : "white"
        horizontalAlignment: Qt.AlignHCenter
        verticalAlignment: Qt.AlignVCenter
        readOnly: !control.editable
        validator: control.validator
        inputMethodHints: Qt.ImhFormattedNumbersOnly
    }
}
