import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import "../"  // Para importar TicketRenderer

Dialog {
    id: root
    title: qsTr("Vista Previa del Ticket")
    modal: true
    anchors.centerIn: parent
    width: Math.min(parent.width * 0.7, 900)
    height: Math.min(parent.height * 0.85, 1000)

    // Propiedades requeridas del contexto padre
    required property var viewModel
    property real pixelsPerMM: 11.811024  // Valor por defecto, debería ser sobrescrito por el padre

    property real previewScale: 0.6
    
    onPixelsPerMMChanged: {
        console.log("[TicketPreviewDialog] pixelsPerMM changed to:", pixelsPerMM)
    }
    
    onOpened: {
        console.log("[TicketPreviewDialog] Dialog opened")
        console.log("  - Dialog size:", width, "x", height)
        console.log("  - ViewModel:", viewModel)
        console.log("  - Ticket dimensions:", viewModel.ticketWidth, "x", viewModel.ticketHeight, "mm")
        console.log("  - Elements count:", viewModel.ticketElements ? viewModel.ticketElements.length : 0)
        console.log("  - PixelsPerMM:", pixelsPerMM)
        console.log("  - Preview scale:", previewScale)
    }

    contentItem: ColumnLayout {
        spacing: 16

        // Barra superior con información y controles de zoom
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Label {
                Layout.fillWidth: true
                text: qsTr("Previsualización con datos de ejemplo • Tamaño: %1x%2mm").arg(root.viewModel.ticketWidth).arg(root.viewModel.ticketHeight)
                font.pixelSize: 12
                opacity: 0.7
                horizontalAlignment: Text.AlignLeft
            }

            Label {
                text: qsTr("Zoom:")
                font.pixelSize: 11
                opacity: 0.7
            }

            Button {
                text: "-"
                font.pixelSize: 16
                font.bold: true
                flat: true
                implicitWidth: 36
                implicitHeight: 36
                enabled: root.previewScale > 0.3
                onClicked: root.previewScale = Math.max(0.3, root.previewScale - 0.1)
                ToolTip.visible: hovered
                ToolTip.text: qsTr("Alejar")
            }

            Label {
                text: Math.round(root.previewScale * 100) + "%"
                font.pixelSize: 12
                font.bold: true
                Layout.minimumWidth: 50
                horizontalAlignment: Text.AlignHCenter
            }

            Button {
                text: "+"
                font.pixelSize: 16
                font.bold: true
                flat: true
                implicitWidth: 36
                implicitHeight: 36
                enabled: root.previewScale < 1.5
                onClicked: root.previewScale = Math.min(1.5, root.previewScale + 0.1)
                ToolTip.visible: hovered
                ToolTip.text: qsTr("Acercar")
            }

            Button {
                text: "⟲"
                font.pixelSize: 16
                flat: true
                implicitWidth: 36
                implicitHeight: 36
                onClicked: root.previewScale = 0.6
                ToolTip.visible: hovered
                ToolTip.text: qsTr("Restablecer zoom (60%)")
            }
        }

        // Separador
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Material.theme === Material.Dark ? "#3a3a3a" : "#e0e0e0"
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AsNeeded
            ScrollBar.vertical.policy: ScrollBar.AsNeeded
            contentWidth: ticketContainer.width
            contentHeight: ticketContainer.height
            
            background: Rectangle {
                color: Material.theme === Material.Dark ? "#2a2a2a" : "#f5f5f5"
                border.width: 1
                border.color: Material.theme === Material.Dark ? "#404040" : "#e0e0e0"
            }

            // Contenedor del ticket con dimensiones calculadas dinámicamente
            Item {
                id: ticketContainer
                width: ticketRenderer.width * root.previewScale + 80
                height: ticketRenderer.height * root.previewScale + 80
                
                Component.onCompleted: {
                    console.log("[TicketContainer] Initialized")
                    console.log("  - Container size:", width, "x", height)
                }

                TicketRenderer {
                    id: ticketRenderer
                    anchors.centerIn: parent
                    ticketWidth: root.viewModel.ticketWidth
                    ticketHeight: root.viewModel.ticketHeight
                    ticketElements: root.viewModel.ticketElements
                    pixelsPerMM: root.pixelsPerMM
                    
                    Component.onCompleted: {
                        console.log("[TicketRenderer in Preview] Position:", x, y)
                        console.log("[TicketRenderer in Preview] Size:", width, "x", height)
                        console.log("[TicketRenderer in Preview] Visible:", visible)
                        console.log("[TicketRenderer in Preview] Opacity:", opacity)
                    }
                    
                    // Aplicar escala con transform para que el layout se respete
                    transform: Scale {
                        origin.x: ticketRenderer.width / 2
                        origin.y: ticketRenderer.height / 2
                        xScale: root.previewScale
                        yScale: root.previewScale
                    }
                    
                    // Configuración de vista previa (no interactiva)
                    interactive: false
                    showGrid: false
                    showHandles: false
                    usePreviewData: true
                    replacePreviewVariables: root.viewModel.replacePreviewVariables
                }
            }
        }
    }

    footer: DialogButtonBox {
        Button {
            text: "\uE8AA  " + qsTr("Generar PDF")
            font.family: "Segoe MDL2 Assets"
            DialogButtonBox.buttonRole: DialogButtonBox.ActionRole
            highlighted: true
            onClicked: root.viewModel.generatePreviewPdf()
        }

        Button {
            text: qsTr("Cerrar")
            DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
        }
    }
}
