import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

Rectangle {
    id: control
    
    // Propiedades públicas
    property string title: ""
    property string value: ""
    property string subtitle: ""
    property string icon: ""
    property color accentColor: Material.primary
    property bool warning: false
    
    // Configuración visual
    color: Material.background
    radius: 8
    border.width: 1
    border.color: Material.frameColor
    
    // Sombra simulada
    layer.enabled: true
    layer.effect: ShaderEffect {
        property color shadowColor: Qt.rgba(0, 0, 0, 0.1)
        fragmentShader: "
            varying highp vec2 qt_TexCoord0;
            uniform lowp sampler2D source;
            uniform lowp vec4 shadowColor;
            void main() {
                lowp vec4 p = texture2D(source, qt_TexCoord0);
                gl_FragColor = mix(shadowColor, p, p.a);
            }
        "
    }
    
    // Contenido
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 8
        
        // Header con icono
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            
            Rectangle {
                width: 40
                height: 40
                radius: 20
                color: Qt.rgba(control.accentColor.r, control.accentColor.g, control.accentColor.b, 0.15)
                
                Label {
                    anchors.centerIn: parent
                    text: control.icon
                    font.pixelSize: 20
                    color: control.accentColor
                }
            }
            
            Item { Layout.fillWidth: true }
            
            // Indicador de advertencia
            Rectangle {
                width: 8
                height: 8
                radius: 4
                color: Material.color(Material.Red)
                visible: control.warning
            }
        }
        
        // Título
        Label {
            text: control.title
            font.pixelSize: 12
            opacity: 0.7
            Layout.fillWidth: true
        }
        
        // Valor principal
        Label {
            text: control.value
            font.pixelSize: 24
            font.weight: Font.Bold
            color: control.warning ? Material.color(Material.Red) : Material.foreground
            Layout.fillWidth: true
        }
        
        // Subtítulo
        Label {
            text: control.subtitle
            font.pixelSize: 11
            opacity: 0.6
            Layout.fillWidth: true
        }
    }
    
    // Efecto hover
    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
    }
    
    states: State {
        name: "hovered"
        when: hoverArea.containsMouse
        PropertyChanges {
            target: control
            border.color: control.accentColor
            scale: 1.02
        }
    }
    
    transitions: Transition {
        NumberAnimation {
            properties: "scale"
            duration: 150
            easing.type: Easing.OutQuad
        }
        ColorAnimation {
            properties: "border.color"
            duration: 150
        }
    }
}
