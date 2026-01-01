import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Dialogs
import SistemaInventario
import "../components"

Page {
    id: root
    title: qsTr("Importar Excel")

    ExcelImportViewModel {
        id: importViewModel

        onImportCompleted: function(imported, failed) {
            successDialog.imported = imported
            successDialog.failed = failed
            successDialog.open()
        }
    }

    FileDialog {
        id: fileDialog
        title: qsTr("Seleccionar archivo Excel")
        nameFilters: ["Archivos Excel (*.xlsx *.xls)"]
        onAccepted: {
            importViewModel.loadFile(selectedFile)
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Header
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 80
            color: Material.background

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: Material.frameColor
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Label {
                        text: qsTr("📊 Importar desde Excel")
                        font.pixelSize: 24
                        font.weight: Font.Bold
                    }

                    Label {
                        text: qsTr("Importa múltiples productos desde un archivo Excel de forma rápida y sencilla")
                        font.pixelSize: 14
                        opacity: 0.7
                    }
                }

                SecondaryButton {
                    text: qsTr("Limpiar")
                    iconText: "\uE8E5"
                    visible: importViewModel.hasFile
                    onClicked: importViewModel.resetImport()
                }
            }
        }

        // Contenido principal
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: availableWidth
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            ColumnLayout {
                width: parent.width - 40
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 20
                anchors.topMargin: 20
                anchors.bottomMargin: 20

                // Información del formato esperado
                Rectangle {
                    Layout.fillWidth: true
                    Layout.margins: 20
                    Layout.preferredHeight: infoColumn.implicitHeight + 32
                    color: Material.theme === Material.Dark ? 
                           Qt.rgba(0.2, 0.4, 0.8, 0.15) : 
                           Material.color(Material.Blue, Material.Shade50)
                    radius: 8
                    border.width: 1
                    border.color: Material.theme === Material.Dark ?
                                  Qt.rgba(0.3, 0.5, 0.9, 0.4) :
                                  Material.color(Material.Blue, Material.Shade300)
                    visible: !importViewModel.hasFile

                    ColumnLayout {
                        id: infoColumn
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 16
                        spacing: 12

                        RowLayout {
                            spacing: 8
                            Label {
                                text: "ℹ️"
                                font.pixelSize: 18
                            }
                            Label {
                                text: qsTr("Formato del archivo Excel")
                                font.pixelSize: 15
                                font.weight: Font.Bold
                                color: Material.theme === Material.Dark ?
                                       Material.color(Material.Blue, Material.Shade200) :
                                       Material.color(Material.Blue, Material.Shade900)
                            }
                        }

                        Label {
                            text: qsTr("Tu archivo Excel debe contener columnas con los datos de los productos. El sistema detectará automáticamente:")
                            font.pixelSize: 13
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                            opacity: 0.9
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 2
                            columnSpacing: 20
                            rowSpacing: 8

                            Label { text: "•  Nombre del producto"; font.pixelSize: 12; opacity: 0.8 }
                            Label { text: "•  Precio de compra"; font.pixelSize: 12; opacity: 0.8 }
                            Label { text: "•  SKU (código único)"; font.pixelSize: 12; opacity: 0.8 }
                            Label { text: "•  Precio de venta"; font.pixelSize: 12; opacity: 0.8 }
                            Label { text: "•  Código de barras"; font.pixelSize: 12; opacity: 0.8 }
                            Label { text: "•  Descripción"; font.pixelSize: 12; opacity: 0.8 }
                            Label { text: "•  Stock actual"; font.pixelSize: 12; opacity: 0.8 }
                            Label { text: "•  Stock mínimo"; font.pixelSize: 12; opacity: 0.8 }
                        }
                    }
                }

                // PASO 1: Zona de drop
                StyledGroupBox {
                title: qsTr("PASO 1: Selecciona tu archivo Excel")
                Layout.fillWidth: true
                Layout.preferredHeight: dropContent.implicitHeight + 60

                Rectangle {
                    id: dropContent
                    anchors.fill: parent
                    anchors.margins: 16
                    color: dropArea.containsDrag ?
                           (Material.theme === Material.Dark ? 
                            Qt.rgba(0.2, 0.4, 0.8, 0.25) :
                            Material.color(Material.Primary, Material.Shade100)) :
                           (Material.theme === Material.Dark ? 
                            Qt.rgba(1, 1, 1, 0.03) : 
                            "white")
                    radius: 12

                    // Canvas para borde punteado cuando NO está arrastrando
                    Canvas {
                        id: dashedBorder
                        anchors.fill: parent
                        visible: !dropArea.containsDrag && !importViewModel.hasFile
                        opacity: Material.theme === Material.Dark ? 0.4 : 0.6

                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);
                            ctx.strokeStyle = Material.theme === Material.Dark ?
                                              Material.color(Material.Grey, Material.Shade400) :
                                              Material.color(Material.Grey, Material.Shade500);
                            ctx.lineWidth = 2;
                            ctx.setLineDash([8, 4]);
                            ctx.beginPath();
                            ctx.roundedRect(0, 0, width, height, 12, 12);
                            ctx.stroke();
                        }

                        Connections {
                            target: Material
                            function onThemeChanged() { dashedBorder.requestPaint(); }
                        }
                    }

                    // Borde sólido cuando está arrastrando o tiene archivo
                    Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                        border.width: dropArea.containsDrag ? 3 : (importViewModel.hasFile ? 2 : 0)
                        border.color: dropArea.containsDrag ?
                                      Material.primary :
                                      importViewModel.hasFile ?
                                      (Material.theme === Material.Dark ?
                                       Material.color(Material.Green, Material.Shade400) :
                                       Material.color(Material.Green, Material.Shade600)) :
                                      "transparent"
                        radius: 12

                        Behavior on border.width {
                            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                        }

                        Behavior on border.color {
                            ColorAnimation { duration: 200 }
                        }
                    }

                    Behavior on color {
                        ColorAnimation { duration: 200 }
                    }

                    DropArea {
                        id: dropArea
                        anchors.fill: parent
                        enabled: !importViewModel.isLoading
                        onDropped: (drop) => {
                            if (drop.hasUrls && drop.urls.length > 0) {
                                importViewModel.loadFile(drop.urls[0])
                            }
                        }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 20
                            width: parent.width - 32

                            Label {
                                text: "\uE8B7"
                                font.family: "Segoe MDL2 Assets"
                                font.pixelSize: 72
                                color: dropArea.containsDrag ? 
                                       Material.primary : 
                                       importViewModel.hasFile ? 
                                       (Material.theme === Material.Dark ?
                                        Material.color(Material.Green, Material.Shade400) :
                                        Material.color(Material.Green, Material.Shade600)) :
                                       Material.accent
                                Layout.alignment: Qt.AlignHCenter
                                opacity: dropArea.containsDrag ? 1.0 : 0.7

                                Behavior on color {
                                    ColorAnimation { duration: 200 }
                                }

                                Behavior on opacity {
                                    NumberAnimation { duration: 200 }
                                }
                            }

                            Label {
                                text: dropArea.containsDrag ?
                                      qsTr("Suelta aquí tu archivo") :
                                      importViewModel.hasFile ?
                                      qsTr("Archivo cargado correctamente") :
                                      qsTr("Arrastra tu archivo Excel aquí")
                                font.pixelSize: 18
                                font.weight: Font.DemiBold
                                Layout.alignment: Qt.AlignHCenter
                                color: dropArea.containsDrag ? Material.primary : Material.foreground

                                Behavior on color {
                                    ColorAnimation { duration: 200 }
                                }
                            }

                            Label {
                                text: qsTr("Formatos: .xlsx, .xls")
                                font.pixelSize: 13
                                opacity: 0.6
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Rectangle {
                                Layout.preferredWidth: 80
                                Layout.preferredHeight: 1
                                color: Material.frameColor
                                opacity: 0.3
                                Layout.alignment: Qt.AlignHCenter
                            }

                            PrimaryButton {
                                text: qsTr("Seleccionar archivo")
                                iconText: "\uE8E5"
                                Layout.alignment: Qt.AlignHCenter
                                Layout.preferredHeight: 44
                                onClicked: fileDialog.open()
                            }
                        }
                    }
                }
            }

            // PASO 2: Mapeo de columnas
            StyledGroupBox {
                    Layout.fillWidth: true
                    Layout.margins: 20
                    visible: importViewModel.excelColumns.length > 0
                    title: qsTr("🔗 PASO 2: Verifica el mapeo de columnas")

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 16

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: helpText.implicitHeight + 24
                            color: Material.theme === Material.Dark ?
                                   Qt.rgba(0.2, 0.8, 0.4, 0.12) :
                                   Material.color(Material.Green, Material.Shade50)
                            radius: 6
                            border.width: 1
                            border.color: Material.theme === Material.Dark ?
                                          Qt.rgba(0.3, 0.9, 0.5, 0.35) :
                                          Material.color(Material.Green, Material.Shade300)

                            Label {
                                id: helpText
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.margins: 12
                                text: qsTr("✓ El sistema ha detectado y ordenado automáticamente tus columnas. Verifica que cada columna del Excel esté relacionada correctamente con el campo del sistema. Si alguna no es correcta, puedes cambiarla manualmente.")
                                font.pixelSize: 13
                                wrapMode: Text.WordWrap
                                color: Material.theme === Material.Dark ?
                                       Material.color(Material.Green, Material.Shade200) :
                                       Material.color(Material.Green, Material.Shade900)
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 20

                            Rectangle {
                                Layout.preferredWidth: 200
                                Layout.preferredHeight: 40
                                color: Material.theme === Material.Dark ?
                                       Qt.rgba(0.2, 0.4, 0.8, 0.2) :
                                       Material.color(Material.Blue, Material.Shade100)
                                radius: 6
                                border.width: 1
                                border.color: Material.theme === Material.Dark ?
                                              Qt.rgba(0.3, 0.5, 0.9, 0.5) :
                                              Material.color(Material.Blue, Material.Shade400)

                                Label {
                                    id: headerText1
                                    anchors.centerIn: parent
                                    text: qsTr("COLUMNAS DEL EXCEL")
                                    font.pixelSize: 12
                                    font.weight: Font.Bold
                                    color: Material.theme === Material.Dark ?
                                           Material.color(Material.Blue, Material.Shade200) :
                                           Material.color(Material.Blue, Material.Shade900)
                                }
                            }

                            Label {
                                text: ""
                                Layout.preferredWidth: 20
                            }

                            Rectangle {
                                Layout.preferredWidth: 250
                                Layout.preferredHeight: 40
                                color: Material.theme === Material.Dark ?
                                       Qt.rgba(0.2, 0.8, 0.4, 0.18) :
                                       Material.color(Material.Green, Material.Shade100)
                                radius: 6
                                border.width: 1
                                border.color: Material.theme === Material.Dark ?
                                              Qt.rgba(0.3, 0.9, 0.5, 0.5) :
                                              Material.color(Material.Green, Material.Shade400)

                                Label {
                                    id: headerText2
                                    anchors.centerIn: parent
                                    text: qsTr("CAMPOS DEL SISTEMA")
                                    font.pixelSize: 12
                                    font.weight: Font.Bold
                                    color: Material.theme === Material.Dark ?
                                           Material.color(Material.Green, Material.Shade200) :
                                           Material.color(Material.Green, Material.Shade900)
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: 60
                                Layout.preferredHeight: 40
                                color: Material.theme === Material.Dark ? Qt.lighter(Material.background, 1.2) : Material.color(Material.Grey, Material.Shade100)
                                radius: 6

                                Label {
                                    id: headerText3
                                    anchors.centerIn: parent
                                    text: qsTr("ESTADO")
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                    opacity: 0.7
                                }
                            }

                            Item { Layout.fillWidth: true }
                        }

                        Label {
                            text: qsTr("Columnas detectadas: %1").arg(importViewModel.excelColumns.length)
                            font.pixelSize: 13
                            font.weight: Font.Bold
                            opacity: 0.8
                        }

                        // Grid de mapeos
                        GridLayout {
                            Layout.fillWidth: true
                            columns: 2
                            columnSpacing: 20
                            rowSpacing: 12

                            Repeater {
                                id: repeaterMapeo
                                model: importViewModel.excelColumns

                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.columnSpan: 2
                                    spacing: 16

                                    // Columna del Excel
                                    Rectangle {
                                        Layout.preferredWidth: 200
                                        Layout.preferredHeight: 48
                                        color: Material.color(Material.Blue, Material.Shade100)
                                        radius: 6
                                        border.width: 2
                                        border.color: Material.color(Material.Blue, Material.Shade300)

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.margins: 8
                                            spacing: 8

                                            Label {
                                                text: "📥"
                                                font.pixelSize: 16
                                            }

                                            Label {
                                                text: modelData
                                                font.weight: Font.Bold
                                                font.pixelSize: 13
                                                color: Material.color(Material.Blue, Material.Shade900)
                                                Layout.fillWidth: true
                                                elide: Text.ElideRight
                                            }
                                        }
                                    }

                                    Label {
                                        text: "→"
                                        font.pixelSize: 24
                                        color: Material.primary
                                        font.weight: Font.Bold
                                    }

                                    // Campo del Sistema
                                    ComboBox {
                                        id: mappingCombo
                                        Layout.preferredWidth: 250
                                        Layout.preferredHeight: 48

                                        property var fieldDescriptions: ({
                                            "ninguno": "No importar esta columna",
                                            "name": "Nombre del producto (obligatorio)",
                                            "sku": "Código único del producto (obligatorio)",
                                            "barcode": "Código de barras para escaneo",
                                            "currentStock": "Cantidad disponible en inventario",
                                            "minimumStock": "Alerta de stock bajo",
                                            "purchasePrice": "Precio de compra al proveedor",
                                            "salePrice": "Precio de venta al cliente",
                                            "description": "Descripción detallada del producto"
                                        })

                                        model: ListModel {
                                            ListElement { text: "❌ Ninguno"; value: "ninguno" }
                                            ListElement { text: "📝 Nombre *"; value: "name" }
                                            ListElement { text: "🏷️ SKU *"; value: "sku" }
                                            ListElement { text: "📊 Código de Barras"; value: "barcode" }
                                            ListElement { text: "📦 Stock Actual"; value: "currentStock" }
                                            ListElement { text: "⚠️ Stock Mínimo"; value: "minimumStock" }
                                            ListElement { text: "💵 Precio Compra"; value: "purchasePrice" }
                                            ListElement { text: "💰 Precio Venta"; value: "salePrice" }
                                            ListElement { text: "📄 Descripción"; value: "description" }
                                        }

                                        ToolTip.visible: hovered
                                        ToolTip.text: fieldDescriptions[currentValue] || ""
                                        ToolTip.delay: 500

                                        textRole: "text"
                                        valueRole: "value"

                                        onActivated: {
                                            importViewModel.setColumnMapping(modelData, currentValue)
                                        }

                                        Component.onCompleted: {
                                            let suggestedField = importViewModel.autoMapColumn(modelData)
                                            for (let i = 0; i < model.count; i++) {
                                                if (model.get(i).value === suggestedField) {
                                                    currentIndex = i
                                                    importViewModel.setColumnMapping(modelData, suggestedField)
                                                    break
                                                }
                                            }
                                        }
                                    }

                                    // Indicador de estado
                                    Rectangle {
                                        Layout.preferredWidth: 60
                                        Layout.preferredHeight: 48
                                        radius: 6
                                        color: {
                                            if (mappingCombo.currentValue === "ninguno") {
                                                return Material.theme === Material.Dark ? Qt.lighter(Material.background, 1.2) : Material.color(Material.Grey, Material.Shade100)
                                            } else if (mappingCombo.currentValue === "name" || mappingCombo.currentValue === "sku") {
                                                return Material.color(Material.Green, Material.Shade100)
                                            } else {
                                                return Material.color(Material.Teal, Material.Shade100)
                                            }
                                        }
                                        border.width: 2
                                        border.color: {
                                            if (mappingCombo.currentValue === "ninguno") {
                                                return Material.frameColor
                                            } else if (mappingCombo.currentValue === "name" || mappingCombo.currentValue === "sku") {
                                                return Material.color(Material.Green)
                                            } else {
                                                return Material.color(Material.Teal)
                                            }
                                        }

                                        ColumnLayout {
                                            anchors.centerIn: parent
                                            spacing: 2

                                            Label {
                                                text: {
                                                    if (mappingCombo.currentValue === "ninguno") {
                                                        return "—"
                                                    } else if (mappingCombo.currentValue === "name" || mappingCombo.currentValue === "sku") {
                                                        return "✓"
                                                    } else {
                                                        return "✓"
                                                    }
                                                }
                                                font.pixelSize: 20
                                                font.weight: Font.Bold
                                                color: {
                                                    if (mappingCombo.currentValue === "ninguno") {
                                                        return Material.color(Material.Grey)
                                                    } else if (mappingCombo.currentValue === "name" || mappingCombo.currentValue === "sku") {
                                                        return Material.color(Material.Green)
                                                    } else {
                                                        return Material.color(Material.Teal)
                                                    }
                                                }
                                                Layout.alignment: Qt.AlignHCenter
                                            }

                                            Label {
                                                text: {
                                                    if (mappingCombo.currentValue === "ninguno") {
                                                        return "Sin mapear"
                                                    } else if (mappingCombo.currentValue === "name" || mappingCombo.currentValue === "sku") {
                                                        return "Obligatorio"
                                                    } else {
                                                        return "Mapeado"
                                                    }
                                                }
                                                font.pixelSize: 9
                                                opacity: 0.8
                                                Layout.alignment: Qt.AlignHCenter
                                                color: {
                                                    if (mappingCombo.currentValue === "ninguno") {
                                                        return Material.color(Material.Grey)
                                                    } else if (mappingCombo.currentValue === "name" || mappingCombo.currentValue === "sku") {
                                                        return Material.color(Material.Green, Material.Shade900)
                                                    } else {
                                                        return Material.color(Material.Teal, Material.Shade900)
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    Item { Layout.fillWidth: true }
                                }
                            }
                        }

                        // Resumen de mapeo
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: summaryRow.implicitHeight + 24
                            Layout.minimumHeight: 60
                            color: Material.theme === Material.Dark ? Qt.lighter(Material.background, 1.3) : Qt.lighter(Material.background, 0.97)
                            radius: 8
                            border.width: 1
                            border.color: Material.frameColor

                            RowLayout {
                                id: summaryRow
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.margins: 12
                                spacing: 20

                                Label {
                                    text: "📊 Resumen del mapeo:"
                                    font.weight: Font.Bold
                                    font.pixelSize: 13
                                }

                                Rectangle {
                                    width: totalLabel.width + 16
                                    height: totalLabel.height + 12
                                    radius: 4
                                    color: Material.color(Material.Blue, Material.Shade100)
                                    border.width: 1
                                    border.color: Material.color(Material.Blue)

                                    Label {
                                        id: totalLabel
                                        anchors.centerIn: parent
                                        text: "📥 Total columnas: " + importViewModel.excelColumns.length
                                        font.pixelSize: 12
                                        font.weight: Font.Medium
                                        color: Material.color(Material.Blue, Material.Shade900)
                                    }
                                }

                                Rectangle {
                                    width: infoLabel.width + 20
                                    height: infoLabel.height + 12
                                    radius: 4
                                    color: Material.theme === Material.Dark ?
                                           Qt.rgba(1, 1, 1, 0.08) :
                                           Material.color(Material.Grey, Material.Shade100)
                                    border.width: 1
                                    border.color: Material.theme === Material.Dark ?
                                                  Qt.rgba(1, 1, 1, 0.15) :
                                                  Material.frameColor

                                    Label {
                                        id: infoLabel
                                        anchors.centerIn: parent
                                        text: "→ Se mapean automáticamente"
                                        font.pixelSize: 11
                                        opacity: 0.8
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                Label {
                                    text: "✓"
                                    font.pixelSize: 18
                                    color: Material.color(Material.Green)
                                    font.weight: Font.Bold
                                }

                                Label {
                                    text: "= Campo obligatorio"
                                    font.pixelSize: 11
                                    opacity: 0.7
                                }

                                Label {
                                    text: "✓"
                                    font.pixelSize: 18
                                    color: Material.color(Material.Teal)
                                    font.weight: Font.Bold
                                }

                                Label {
                                    text: "= Campo opcional mapeado"
                                    font.pixelSize: 11
                                    opacity: 0.7
                                }

                                Label {
                                    text: "—"
                                    font.pixelSize: 18
                                    opacity: 0.5
                                    font.weight: Font.Bold
                                }

                                Label {
                                    text: "= Sin mapear"
                                    font.pixelSize: 11
                                    opacity: 0.7
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: requiredLabel.implicitHeight + 16
                            Layout.minimumHeight: 40
                            color: Material.theme === Material.Dark ?
                                   Qt.rgba(0.9, 0.6, 0.2, 0.15) :
                                   Material.color(Material.Orange, Material.Shade50)
                            radius: 6
                            border.width: 1
                            border.color: Material.theme === Material.Dark ?
                                          Qt.rgba(0.9, 0.6, 0.2, 0.4) :
                                          Material.color(Material.Orange, Material.Shade300)

                            Label {
                                id: requiredLabel
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.margins: 8
                                text: qsTr("⚠️ Campos obligatorios: Nombre y SKU. Sin estos campos no se podrán importar los productos.")
                                font.pixelSize: 12
                                wrapMode: Text.WordWrap
                                color: Material.theme === Material.Dark ?
                                       Material.color(Material.Orange, Material.Shade200) :
                                       Material.color(Material.Orange, Material.Shade900)
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            PrimaryButton {
                                text: qsTr("👁️ Vista Previa")
                                iconText: "\uE890"
                                onClicked: importViewModel.loadPreview(10)
                            }

                            Label {
                                text: qsTr("Total de filas: %1").arg(importViewModel.totalRows)
                                font.pixelSize: 13
                                opacity: 0.7
                                visible: importViewModel.totalRows > 0
                            }

                            Item { Layout.fillWidth: true }
                        }
                    }
                }

                // PASO 3: Vista previa de datos
                StyledGroupBox {
                    Layout.fillWidth: true
                    Layout.margins: 20
                    visible: importViewModel.previewRows.length > 0
                    title: qsTr("👁️ PASO 3: Revisa los datos antes de importar")

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 16

                        Label {
                            text: qsTr("Esta es una muestra de las primeras 10 filas. Verifica que los datos se vean correctos antes de importar.")
                            font.pixelSize: 13
                            opacity: 0.7
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        ScrollView {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 400
                            clip: true
                            ScrollBar.horizontal.policy: ScrollBar.AsNeeded

                            ColumnLayout {
                                spacing: 12
                                width: Math.max(1200, parent.width)

                                // Encabezado de la tabla
                                Rectangle {
                                    width: 1200
                                    height: 44
                                    color: Material.theme === Material.Dark ?
                                           Qt.rgba(0.2, 0.4, 0.8, 0.2) :
                                           Material.color(Material.Blue, Material.Shade100)
                                    radius: 6
                                    border.width: 1
                                    border.color: Material.theme === Material.Dark ?
                                                  Qt.rgba(0.3, 0.5, 0.9, 0.5) :
                                                  Material.color(Material.Blue, Material.Shade300)

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 16
                                        anchors.rightMargin: 16
                                        spacing: 12

                                        Label {
                                            text: "#"
                                            Layout.preferredWidth: 40
                                            font.weight: Font.Bold
                                            font.pixelSize: 12
                                            color: Material.theme === Material.Dark ?
                                                   Material.color(Material.Blue, Material.Shade200) :
                                                   Material.color(Material.Blue, Material.Shade900)
                                        }

                                        Label {
                                            text: "Nombre"
                                            Layout.fillWidth: true
                                            font.weight: Font.Bold
                                            font.pixelSize: 12
                                            color: Material.theme === Material.Dark ?
                                                   Material.color(Material.Blue, Material.Shade200) :
                                                   Material.color(Material.Blue, Material.Shade900)
                                        }

                                        Label {
                                            text: "SKU"
                                            Layout.preferredWidth: 100
                                            font.weight: Font.Bold
                                            font.pixelSize: 12
                                            color: Material.theme === Material.Dark ?
                                                   Material.color(Material.Blue, Material.Shade200) :
                                                   Material.color(Material.Blue, Material.Shade900)
                                        }

                                        Label {
                                            text: "Código Barras"
                                            Layout.preferredWidth: 110
                                            font.weight: Font.Bold
                                            font.pixelSize: 12
                                            color: Material.theme === Material.Dark ?
                                                   Material.color(Material.Blue, Material.Shade200) :
                                                   Material.color(Material.Blue, Material.Shade900)
                                        }

                                        Label {
                                            text: "Stock"
                                            Layout.preferredWidth: 70
                                            font.weight: Font.Bold
                                            font.pixelSize: 12
                                            horizontalAlignment: Text.AlignRight
                                            color: Material.theme === Material.Dark ?
                                                   Material.color(Material.Blue, Material.Shade200) :
                                                   Material.color(Material.Blue, Material.Shade900)
                                        }

                                        Label {
                                            text: "Mín"
                                            Layout.preferredWidth: 60
                                            font.weight: Font.Bold
                                            font.pixelSize: 12
                                            horizontalAlignment: Text.AlignRight
                                            color: Material.theme === Material.Dark ?
                                                   Material.color(Material.Blue, Material.Shade200) :
                                                   Material.color(Material.Blue, Material.Shade900)
                                        }

                                        Label {
                                            text: "P. Compra"
                                            Layout.preferredWidth: 90
                                            font.weight: Font.Bold
                                            font.pixelSize: 12
                                            horizontalAlignment: Text.AlignRight
                                            color: Material.theme === Material.Dark ?
                                                   Material.color(Material.Blue, Material.Shade200) :
                                                   Material.color(Material.Blue, Material.Shade900)
                                        }

                                        Label {
                                            text: "P. Venta"
                                            Layout.preferredWidth: 90
                                            font.weight: Font.Bold
                                            font.pixelSize: 12
                                            horizontalAlignment: Text.AlignRight
                                            color: Material.theme === Material.Dark ?
                                                   Material.color(Material.Blue, Material.Shade200) :
                                                   Material.color(Material.Blue, Material.Shade900)
                                        }

                                        Label {
                                            text: "Descripción"
                                            Layout.preferredWidth: 150
                                            font.weight: Font.Bold
                                            font.pixelSize: 12
                                            color: Material.theme === Material.Dark ?
                                                   Material.color(Material.Blue, Material.Shade200) :
                                                   Material.color(Material.Blue, Material.Shade900)
                                        }
                                    }
                                }

                                Repeater {
                                    model: importViewModel.previewRows

                                    Rectangle {
                                        width: 1200
                                        height: 56
                                        color: Material.theme === Material.Dark ?
                                               Qt.rgba(1, 1, 1, 0.05) :
                                               Material.color(Material.Grey, Material.Shade50)
                                        radius: 6
                                        border.width: 1
                                        border.color: Material.theme === Material.Dark ?
                                                      Qt.rgba(1, 1, 1, 0.1) :
                                                      Material.frameColor

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 16
                                            anchors.rightMargin: 16
                                            spacing: 12

                                            Label {
                                                text: (index + 1).toString()
                                                Layout.preferredWidth: 40
                                                font.weight: Font.Bold
                                                font.pixelSize: 13
                                                opacity: 0.5
                                            }

                                            Label {
                                                text: modelData.name || "-"
                                                Layout.fillWidth: true
                                                elide: Text.ElideRight
                                                font.weight: Font.Medium
                                                font.pixelSize: 13
                                                ToolTip.visible: truncated && hovered
                                                ToolTip.text: modelData.name || ""

                                                property bool hovered: false
                                                MouseArea {
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    onEntered: parent.hovered = true
                                                    onExited: parent.hovered = false
                                                }
                                            }

                                            Label {
                                                text: modelData.sku || "-"
                                                Layout.preferredWidth: 100
                                                elide: Text.ElideRight
                                                font.pixelSize: 13
                                                opacity: 0.8
                                            }

                                            Label {
                                                text: modelData.barcode || "-"
                                                Layout.preferredWidth: 110
                                                elide: Text.ElideRight
                                                font.pixelSize: 13
                                                opacity: 0.8
                                            }

                                            Label {
                                                text: modelData.currentStock !== undefined ? modelData.currentStock.toString() : "-"
                                                Layout.preferredWidth: 70
                                                horizontalAlignment: Text.AlignRight
                                                font.pixelSize: 13
                                                opacity: 0.8
                                            }

                                            Label {
                                                text: modelData.minimumStock !== undefined ? modelData.minimumStock.toString() : "-"
                                                Layout.preferredWidth: 60
                                                horizontalAlignment: Text.AlignRight
                                                font.pixelSize: 13
                                                opacity: 0.8
                                            }

                                            Label {
                                                text: modelData.purchasePrice !== undefined ? "S/ " + Number(modelData.purchasePrice).toFixed(2) : "-"
                                                Layout.preferredWidth: 90
                                                horizontalAlignment: Text.AlignRight
                                                font.pixelSize: 13
                                                opacity: 0.8
                                            }

                                            Label {
                                                text: modelData.salePrice !== undefined ? "S/ " + Number(modelData.salePrice).toFixed(2) : "-"
                                                Layout.preferredWidth: 90
                                                horizontalAlignment: Text.AlignRight
                                                font.weight: Font.Bold
                                                font.pixelSize: 13
                                                color: Material.theme === Material.Dark ?
                                                       Material.color(Material.Green, Material.Shade300) :
                                                       Material.color(Material.Green, Material.Shade700)
                                            }

                                            Label {
                                                text: modelData.description || "-"
                                                Layout.preferredWidth: 150
                                                elide: Text.ElideRight
                                                opacity: 0.7
                                                font.pixelSize: 11
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            PrimaryButton {
                                text: importViewModel.isLoading ? "" : qsTr("Importar %1 productos").arg(importViewModel.totalRows)
                                iconText: importViewModel.isLoading ? "" : "\uE896"
                                enabled: !importViewModel.isLoading
                                Layout.preferredHeight: 50
                                Layout.fillWidth: true
                                onClicked: importViewModel.startImport()

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 12
                                    visible: importViewModel.isLoading

                                    LoadingSpinner {
                                        size: 24
                                    }

                                    Label {
                                        text: qsTr("Importando productos... %1%").arg(Math.round(importViewModel.importProgress))
                                        color: "white"
                                        font.pixelSize: 14
                                        font.weight: Font.Medium
                                    }
                                }
                            }

                            Label {
                                text: qsTr("Nota: Los productos con SKU existente serán actualizados")
                                font.pixelSize: 12
                                opacity: 0.6
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }

                // Mensaje de error
                Rectangle {
                    Layout.fillWidth: true
                    Layout.margins: 20
                    Layout.preferredHeight: errorLayout.implicitHeight + 32
                    Layout.minimumHeight: 60
                    visible: importViewModel.errorMessage !== ""
                    color: Material.color(Material.Red, Material.Shade100)
                    radius: 8
                    border.width: 1
                    border.color: Material.color(Material.Red)

                    RowLayout {
                        id: errorLayout
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 12

                        Label {
                            text: "\uE783"
                            font.family: "Segoe MDL2 Assets"
                            font.pixelSize: 24
                            color: Material.color(Material.Red)
                        }

                        Label {
                            text: importViewModel.errorMessage
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            color: Material.color(Material.Red, Material.Shade900)
                        }
                    }
                }

                Item {
                    Layout.fillHeight: true
                }
            }
        }
    }

    // Diálogo de éxito
    Dialog {
        id: successDialog
        title: qsTr("✅ Importación Completada")
        modal: true
        anchors.centerIn: parent
        width: 500

        property int imported: 0
        property int failed: 0

        ColumnLayout {
            anchors.fill: parent
            spacing: 20

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 120
                color: Material.color(Material.Green, Material.Shade100)
                radius: 12
                border.width: 2
                border.color: Material.color(Material.Green)

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 12

                    Label {
                        text: "\uE73E"
                        font.family: "Segoe MDL2 Assets"
                        font.pixelSize: 56
                        color: Material.color(Material.Green)
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Label {
                        text: qsTr("¡Importación exitosa!")
                        font.pixelSize: 18
                        font.weight: Font.Bold
                        Layout.alignment: Qt.AlignHCenter
                        color: Material.color(Material.Green, Material.Shade900)
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                color: Material.theme === Material.Dark ? Qt.lighter(Material.background, 1.2) : Material.color(Material.Grey, Material.Shade100)
                radius: 8
                height: statsColumn.height + 24

                ColumnLayout {
                    id: statsColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: 12
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Label {
                            text: "✓"
                            font.pixelSize: 24
                            color: Material.color(Material.Green)
                            font.weight: Font.Bold
                        }

                        Label {
                            text: qsTr("Productos importados:")
                            font.pixelSize: 14
                            opacity: 0.7
                            Layout.fillWidth: true
                        }

                        Label {
                            text: successDialog.imported
                            font.pixelSize: 24
                            font.weight: Font.Bold
                            color: Material.color(Material.Green)
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Material.frameColor
                        visible: successDialog.failed > 0
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        visible: successDialog.failed > 0

                        Label {
                            text: "✗"
                            font.pixelSize: 24
                            color: Material.color(Material.Orange)
                            font.weight: Font.Bold
                        }

                        Label {
                            text: qsTr("Filas fallidas:")
                            font.pixelSize: 14
                            opacity: 0.7
                            Layout.fillWidth: true
                        }

                        Label {
                            text: successDialog.failed
                            font.pixelSize: 24
                            font.weight: Font.Bold
                            color: Material.color(Material.Orange)
                        }
                    }
                }
            }

            Label {
                text: successDialog.failed > 0 ?
                      qsTr("⚠️ Algunas filas no se pudieron importar. Verifica que no haya SKUs duplicados o campos obligatorios vacíos.") :
                      qsTr("🎉 Todos los productos se importaron correctamente. Ya están disponibles en tu inventario.")
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 13
                opacity: 0.8
            }

            Rectangle {
                Layout.fillWidth: true
                color: Material.color(Material.Blue, Material.theme === Material.Dark ? Material.Shade800 : Material.Shade50)
                radius: 6
                height: tipLabel.height + 16
                border.width: 1
                border.color: Material.color(Material.Blue, Material.Shade300)

                Label {
                    id: tipLabel
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: 8
                    text: qsTr("💡 Tip: Puedes ver los productos importados en la página de Inventario")
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                    color: Material.color(Material.Blue, Material.Shade900)
                }
            }

            PrimaryButton {
                text: qsTr("Aceptar")
                Layout.fillWidth: true
                onClicked: {
                    successDialog.close()
                    importViewModel.resetImport()
                }
            }
        }
    }
}
