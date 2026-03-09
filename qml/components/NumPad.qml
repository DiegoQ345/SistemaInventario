import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material

// Teclado numérico para ingreso de montos en pantallas táctiles
Rectangle {
    id: root
    
    property TextField targetField: null
    
    implicitWidth: 280
    implicitHeight: 360
    radius: 8
    color: Material.theme === Material.Dark ?
        Qt.lighter(Material.background, 1.2) :
        Material.background
    border.width: 2
    border.color: Material.theme === Material.Dark ?
        Qt.lighter(Material.frameColor, 1.5) :
        Material.frameColor
    
    // Sombra simulada con múltiples rectángulos
    Rectangle {
        anchors.fill: parent
        anchors.margins: -3
        z: -1
        radius: parent.radius + 2
        color: "transparent"
        border.width: 3
        border.color: Material.theme === Material.Dark ?
            Qt.rgba(0, 0, 0, 0.4) :
            Qt.rgba(0, 0, 0, 0.15)
        opacity: 0.5
    }
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8
        
        // Display del valor actual
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            radius: 4
            color: Material.theme === Material.Dark ?
                Material.background :
                Material.color(Material.Grey, Material.Shade100)
            border.width: 1
            border.color: Material.frameColor
            
            Label {
                id: displayLabel
                anchors.fill: parent
                anchors.margins: 8
                text: targetField ? targetField.text : "0.00"
                font.pixelSize: 22
                font.weight: Font.Bold
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideLeft
            }
        }
        
        // Grid de teclas numéricas
        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 3
            rowSpacing: 8
            columnSpacing: 8
            
            // Fila 1: 7, 8, 9
            Repeater {
                model: ["7", "8", "9"]
                
                Button {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    text: modelData
                    font.pixelSize: 20
                    font.weight: Font.Medium
                    
                    Material.background: Material.theme === Material.Dark ?
                        Qt.lighter(Material.background, 1.4) :
                        Material.color(Material.Grey, Material.Shade200)
                    
                    onClicked: appendDigit(modelData)
                }
            }
            
            // Fila 2: 4, 5, 6
            Repeater {
                model: ["4", "5", "6"]
                
                Button {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    text: modelData
                    font.pixelSize: 20
                    font.weight: Font.Medium
                    
                    Material.background: Material.theme === Material.Dark ?
                        Qt.lighter(Material.background, 1.4) :
                        Material.color(Material.Grey, Material.Shade200)
                    
                    onClicked: appendDigit(modelData)
                }
            }
            
            // Fila 3: 1, 2, 3
            Repeater {
                model: ["1", "2", "3"]
                
                Button {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    text: modelData
                    font.pixelSize: 20
                    font.weight: Font.Medium
                    
                    Material.background: Material.theme === Material.Dark ?
                        Qt.lighter(Material.background, 1.4) :
                        Material.color(Material.Grey, Material.Shade200)
                    
                    onClicked: appendDigit(modelData)
                }
            }
            
            // Fila 4: Clear, 0, Punto
            Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: "C"
                font.pixelSize: 20
                font.weight: Font.Bold
                
                Material.background: Material.color(Material.Red)
                Material.foreground: "#FFFFFF"
                
                onClicked: clearValue()
            }
            
            Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: "0"
                font.pixelSize: 20
                font.weight: Font.Medium
                
                Material.background: Material.theme === Material.Dark ?
                    Qt.lighter(Material.background, 1.4) :
                    Material.color(Material.Grey, Material.Shade200)
                
                onClicked: appendDigit("0")
            }
            
            Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: "."
                font.pixelSize: 24
                font.weight: Font.Bold
                
                Material.background: Material.theme === Material.Dark ?
                    Qt.lighter(Material.background, 1.4) :
                    Material.color(Material.Grey, Material.Shade200)
                
                onClicked: appendDecimal()
            }
        }
        
        // Fila de acciones: Borrar y Aceptar
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            
            Button {
                text: "\uE74D"  // Backspace icon
                font.family: "Segoe MDL2 Assets"
                font.pixelSize: 20
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                
                Material.background: Material.color(Material.Orange)
                Material.foreground: "#FFFFFF"
                
                onClicked: backspace()
            }
            
            Button {
                text: "\uE73E  OK"  // Checkmark icon + text
                font.family: "Segoe MDL2 Assets"
                font.pixelSize: 16
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                
                Material.background: Material.color(Material.Green)
                Material.foreground: "#FFFFFF"
                
                onClicked: root.visible = false
            }
        }
    }
    
    // Funciones del teclado
    function appendDigit(digit) {
        if (!targetField) return
        
        var currentText = targetField.text
        
        // Si es "0.00" inicial, reemplazar
        if (currentText === "0.00" || currentText === "0") {
            targetField.text = digit
        } else {
            // Limitar a 10 caracteres
            if (currentText.length < 10) {
                targetField.text = currentText + digit
            }
        }
    }
    
    function appendDecimal() {
        if (!targetField) return
        
        var currentText = targetField.text
        
        // Solo permitir un punto decimal
        if (currentText.indexOf(".") === -1) {
            // Si está vacío o es "0", agregar "0."
            if (currentText === "" || currentText === "0" || currentText === "0.00") {
                targetField.text = "0."
            } else {
                targetField.text = currentText + "."
            }
        }
    }
    
    function backspace() {
        if (!targetField) return
        
        var currentText = targetField.text
        
        if (currentText.length > 0) {
            targetField.text = currentText.slice(0, -1)
            
            // Si queda vacío, poner "0"
            if (targetField.text === "" || targetField.text === ".") {
                targetField.text = "0"
            }
        }
    }
    
    function clearValue() {
        if (!targetField) return
        targetField.text = "0.00"
    }
}
