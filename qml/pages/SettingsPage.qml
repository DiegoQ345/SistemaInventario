import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import Qt.labs.settings
import Qt.labs.platform as Platform
import SistemaInventario 1.0

Page {
    id: root
    title: qsTr("Configuración")

    Settings {
        id: localSettings
        property string businessName: ""
        property string businessRuc: ""
        property string businessAddress: ""
        property string businessPhone: ""
        property string businessEmail: ""
    }

    PrintViewModel {
        id: printViewModel
        
        Component.onCompleted: {
            // Cargar datos guardados
            if (localSettings.businessName !== "") {
                setBusinessInfo(
                    localSettings.businessName,
                    localSettings.businessRuc,
                    localSettings.businessAddress,
                    localSettings.businessPhone,
                    localSettings.businessEmail
                )
            }
        }
    }

    ScrollView {
        anchors.fill: parent
        anchors.margins: 20
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AsNeeded

        ColumnLayout {
            width: parent.width
            spacing: 24

            // Header
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Label {
                    text: "\uE713  " + qsTr("Configuración")
                    font.family: "Segoe MDL2 Assets"
                    font.pixelSize: 32
                    font.weight: Font.Bold
                }

                Label {
                    text: qsTr("Personaliza el sistema según tus necesidades")
                    font.pixelSize: 16
                    opacity: 0.7
                }
            }

            // ========== APARIENCIA ==========
            GroupBox {
                Layout.fillWidth: true
                title: "\uE790  " + qsTr("Apariencia")
                font.family: "Segoe MDL2 Assets"
                font.pixelSize: 18
                font.weight: Font.Medium

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 16

                    // Tamaño de fuente
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Label {
                            text: qsTr("Tamaño de fuente:")
                            font.weight: Font.Medium
                            font.pixelSize: 14
                        }

                        Label {
                            text: qsTr("Ajusta el tamaño del texto en toda la aplicación para mejorar la visibilidad")
                            font.pixelSize: 12
                            opacity: 0.7
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        ButtonGroup {
                            id: fontSizeGroup
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 4
                            rowSpacing: 8
                            columnSpacing: 12

                            RadioButton {
                                text: qsTr("Pequeño")
                                checked: ApplicationWindow.window.settings.fontScale === 0.85
                                ButtonGroup.group: fontSizeGroup
                                onClicked: ApplicationWindow.window.settings.fontScale = 0.85
                            }

                            RadioButton {
                                text: qsTr("Normal")
                                checked: ApplicationWindow.window.settings.fontScale === 1.0
                                ButtonGroup.group: fontSizeGroup
                                onClicked: ApplicationWindow.window.settings.fontScale = 1.0
                            }

                            RadioButton {
                                text: qsTr("Grande")
                                checked: ApplicationWindow.window.settings.fontScale === 1.15
                                ButtonGroup.group: fontSizeGroup
                                onClicked: ApplicationWindow.window.settings.fontScale = 1.15
                            }

                            RadioButton {
                                text: qsTr("Extra Grande")
                                checked: ApplicationWindow.window.settings.fontScale === 1.3
                                ButtonGroup.group: fontSizeGroup
                                onClicked: ApplicationWindow.window.settings.fontScale = 1.3
                            }
                        }
                        
                        // Vista previa del tamaño de fuente
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 120
                            Layout.topMargin: 12
                            radius: 8
                            color: Material.theme === Material.Dark ? 
                                   Qt.lighter(Material.background, 1.2) : 
                                   Material.color(Material.Grey, Material.Shade100)
                            border.width: 1
                            border.color: Material.frameColor
                            
                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 16
                                spacing: 12
                                
                                Label {
                                    text: "Vista Previa"
                                    font.weight: Font.Medium
                                    font.pixelSize: ApplicationWindow.window.appStyle.fontMedium
                                    opacity: 0.7
                                }
                                
                                RowLayout {
                                    spacing: 12
                                    
                                    Label {
                                        text: "\uE735"  // Icono de documento
                                        font.family: "Segoe MDL2 Assets"
                                        font.pixelSize: ApplicationWindow.window.appStyle.iconXLarge
                                        color: Material.accent
                                    }
                                    
                                    Column {
                                        spacing: 4
                                        
                                        Label {
                                            text: "Texto de ejemplo"
                                            font.pixelSize: ApplicationWindow.window.appStyle.fontBodyLarge
                                            font.weight: Font.Medium
                                        }
                                        
                                        Label {
                                            text: "Este es el tamaño actual: " + 
                                                  (ApplicationWindow.window.settings.fontScale === 0.85 ? "Pequeño (85%)" :
                                                   ApplicationWindow.window.settings.fontScale === 1.0 ? "Normal (100%)" :
                                                   ApplicationWindow.window.settings.fontScale === 1.15 ? "Grande (115%)" :
                                                   "Extra Grande (130%)")
                                            font.pixelSize: ApplicationWindow.window.appStyle.fontBody
                                            opacity: 0.7
                                        }
                                    }
                                }
                            }
                        }
                        
                        Label {
                            text: "⚠️ Los cambios se aplican inmediatamente en toda la aplicación"
                            font.pixelSize: ApplicationWindow.window.appStyle.fontSmall
                            opacity: 0.6
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                            Layout.topMargin: 8
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Material.frameColor
                    }

                    // Selector de tema (referencia al existente)
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Label {
                            text: qsTr("Tema y color:")
                            font.weight: Font.Medium
                            font.pixelSize: 14
                        }

                        Label {
                            text: qsTr("Cambia el tema y esquema de colores desde el menú de la esquina superior derecha")
                            font.pixelSize: 12
                            opacity: 0.7
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }
                }
            }

            // ========== INFORMACIÓN DE LA EMPRESA ==========
            GroupBox {
                Layout.fillWidth: true
                title: "\uE821  " + qsTr("Información de la Empresa")
                font.family: "Segoe MDL2 Assets"
                font.pixelSize: 18
                font.weight: Font.Medium

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 16

                    Label {
                        text: qsTr("Esta información aparecerá en los tickets y facturas impresas")
                        font.pixelSize: 12
                        opacity: 0.7
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        rowSpacing: 12
                        columnSpacing: 16

                        Label {
                            text: qsTr("Nombre del negocio:")
                            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                        }
                        TextField {
                            id: businessNameField
                            Layout.fillWidth: true
                            placeholderText: qsTr("Ej: Mi Tienda S.A.C.")
                            text: localSettings.businessName
                        }

                        Label {
                            text: qsTr("RUC:")
                            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                        }
                        TextField {
                            id: businessRucField
                            Layout.fillWidth: true
                            placeholderText: qsTr("Ej: 20123456789")
                            text: localSettings.businessRuc
                            inputMethodHints: Qt.ImhDigitsOnly
                            maximumLength: 11
                        }

                        Label {
                            text: qsTr("Dirección:")
                            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                        }
                        TextField {
                            id: businessAddressField
                            Layout.fillWidth: true
                            placeholderText: qsTr("Ej: Av. Principal 123, Lima")
                            text: localSettings.businessAddress
                        }

                        Label {
                            text: qsTr("Teléfono:")
                            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                        }
                        TextField {
                            id: businessPhoneField
                            Layout.fillWidth: true
                            placeholderText: qsTr("Ej: (01) 123-4567")
                            text: localSettings.businessPhone
                        }

                        Label {
                            text: qsTr("Email:")
                            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                        }
                        TextField {
                            id: businessEmailField
                            Layout.fillWidth: true
                            placeholderText: qsTr("Ej: contacto@mitienda.com")
                            text: localSettings.businessEmail
                            inputMethodHints: Qt.ImhEmailCharactersOnly
                        }
                    }

                    Button {
                        text: "\uE74E  " + qsTr("Guardar Información")
                        font.family: "Segoe MDL2 Assets"
                        Layout.alignment: Qt.AlignRight
                        Material.background: ApplicationWindow.window?.currentColors?.primary ?? Material.primary
                        Material.foreground: Material.theme === Material.Dark ? "#000000" : "#FFFFFF"

                        onClicked: {
                            // Guardar en settings
                            localSettings.businessName = businessNameField.text
                            localSettings.businessRuc = businessRucField.text
                            localSettings.businessAddress = businessAddressField.text
                            localSettings.businessPhone = businessPhoneField.text
                            localSettings.businessEmail = businessEmailField.text

                            // Actualizar PrintViewModel
                            printViewModel.setBusinessInfo(
                                businessNameField.text,
                                businessRucField.text,
                                businessAddressField.text,
                                businessPhoneField.text,
                                businessEmailField.text
                            )

                            successNotification.open()
                        }
                    }
                }
            }

            // ========== IMPRESIÓN ==========
            GroupBox {
                Layout.fillWidth: true
                title: "\uE749  " + qsTr("Configuración de Impresión")
                font.family: "Segoe MDL2 Assets"
                font.pixelSize: 18
                font.weight: Font.Medium

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 16

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        rowSpacing: 12
                        columnSpacing: 16

                        Label {
                            text: qsTr("Impresora por defecto:")
                            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                        }
                        ComboBox {
                            id: printerComboBox
                            Layout.fillWidth: true
                            model: printViewModel.availablePrinters
                            currentIndex: printViewModel.defaultPrinterIndex
                            onCurrentTextChanged: {
                                if (currentText !== "")
                                    printViewModel.defaultPrinter = currentText
                            }
                        }

                        Label {
                            text: qsTr("Tamaño de papel:")
                            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                        }
                        ComboBox {
                            id: paperSizeComboBox
                            Layout.fillWidth: true
                            model: [
                                qsTr("A4 (210 x 297 mm)"),
                                qsTr("Carta (216 x 279 mm)"),
                                qsTr("Térmico 80mm"),
                                qsTr("Térmico 58mm")
                            ]
                            currentIndex: printViewModel.paperSize
                            onCurrentIndexChanged: {
                                printViewModel.paperSize = currentIndex
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Material.frameColor
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Label {
                            text: "\uE8A5"
                            font.family: "Segoe MDL2 Assets"
                            font.pixelSize: 24
                            color: Material.primary
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Label {
                                text: qsTr("Diseñador de Tickets")
                                font.weight: Font.Medium
                            }

                            Label {
                                text: qsTr("Personaliza el formato de tus tickets y facturas")
                                font.pixelSize: 12
                                opacity: 0.7
                            }
                        }

                        Button {
                            text: qsTr("Abrir")
                            flat: true
                            Material.foreground: Material.primary
                            onClicked: {
                                ApplicationWindow.window.stackView.push("qml/pages/TicketsPage.qml")
                            }
                        }
                    }
                }
            }

            // ========== SISTEMA ==========
            GroupBox {
                Layout.fillWidth: true
                title: "\uE950  " + qsTr("Información del Sistema")
                font.family: "Segoe MDL2 Assets"
                font.pixelSize: 18
                font.weight: Font.Medium

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 16

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        rowSpacing: 8
                        columnSpacing: 16

                        Label {
                            text: qsTr("Versión:")
                            font.weight: Font.Medium
                        }
                        Label {
                            text: "1.0.0"
                            opacity: 0.7
                        }

                        Label {
                            text: qsTr("Base de datos:")
                            font.weight: Font.Medium
                        }
                        Label {
                            text: "SQLite (Local)"
                            opacity: 0.7
                        }

                        Label {
                            text: qsTr("Qt Version:")
                            font.weight: Font.Medium
                        }
                        Label {
                            text: Qt.platform.os + " - Qt " + Qt.version
                            opacity: 0.7
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Material.frameColor
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Button {
                            text: "\uE8FD  " + qsTr("Exportar Base de Datos")
                            font.family: "Segoe MDL2 Assets"
                            Material.background: ApplicationWindow.window?.currentColors?.primary ?? Material.primary
                            Material.foreground: Material.theme === Material.Dark ? "#000000" : "#FFFFFF"
                            
                            onClicked: {
                                exportFileDialog.open()
                            }
                        }

                        Button {
                            text: "\uE8B5  " + qsTr("Acerca de")
                            font.family: "Segoe MDL2 Assets"
                            flat: true
                            Material.foreground: Material.primary
                            
                            onClicked: aboutDialog.open()
                        }
                    }
                }
            }

            Item {
                Layout.fillHeight: true
                Layout.minimumHeight: 40
            }
        }
    }

    // Notificación de éxito
    Popup {
        id: successNotification
        anchors.centerIn: parent
        width: 300
        height: 80
        modal: false
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        
        background: Rectangle {
            color: Material.theme === Material.Dark ?
                Qt.rgba(0.2, 0.8, 0.4, 0.9) :
                Material.color(Material.Green, Material.Shade100)
            radius: 8
            border.width: 2
            border.color: Material.color(Material.Green)
        }

        RowLayout {
            anchors.centerIn: parent
            spacing: 12

            Label {
                text: "\uE73E"
                font.family: "Segoe MDL2 Assets"
                font.pixelSize: 28
                color: Material.color(Material.Green)
            }

            Label {
                text: qsTr("Información guardada correctamente")
                font.weight: Font.Medium
            }
        }

        Timer {
            interval: 2000
            running: successNotification.visible
            onTriggered: successNotification.close()
        }
    }

    // Notificación de exportación
    Popup {
        id: exportNotification
        anchors.centerIn: parent
        width: 350
        height: 100
        modal: false
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        
        property bool isSuccess: true
        property string message: ""
        
        background: Rectangle {
            color: exportNotification.isSuccess ?
                (Material.theme === Material.Dark ?
                    Qt.rgba(0.2, 0.8, 0.4, 0.9) :
                    Material.color(Material.Green, Material.Shade100)) :
                (Material.theme === Material.Dark ?
                    Qt.rgba(0.8, 0.2, 0.2, 0.9) :
                    Material.color(Material.Red, Material.Shade100))
            radius: 8
            border.width: 2
            border.color: exportNotification.isSuccess ? 
                Material.color(Material.Green) : 
                Material.color(Material.Red)
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 8

            Label {
                text: exportNotification.isSuccess ? "\uE73E" : "\uE711"
                font.family: "Segoe MDL2 Assets"
                font.pixelSize: 32
                color: exportNotification.isSuccess ? 
                    Material.color(Material.Green) : 
                    Material.color(Material.Red)
                Layout.alignment: Qt.AlignHCenter
            }

            Label {
                text: exportNotification.message
                font.weight: Font.Medium
                Layout.alignment: Qt.AlignHCenter
                wrapMode: Text.WordWrap
                Layout.maximumWidth: 320
                horizontalAlignment: Text.AlignHCenter
            }
        }

        Timer {
            interval: 3000
            running: exportNotification.visible
            onTriggered: exportNotification.close()
        }
    }

    // Diálogo Acerca de
    Dialog {
        id: aboutDialog
        title: qsTr("Acerca de Sistema de Inventario")
        anchors.centerIn: parent
        width: 450
        modal: true

        ColumnLayout {
            anchors.fill: parent
            spacing: 16

            Image {
                source: "qrc:/resources/logo.png"
                Layout.preferredWidth: 80
                Layout.preferredHeight: 80
                Layout.alignment: Qt.AlignHCenter
                fillMode: Image.PreserveAspectFit
                visible: false  // Mostrar cuando tengas logo
            }

            Label {
                text: qsTr("Sistema de Inventario")
                font.pixelSize: 24
                font.weight: Font.Bold
                Layout.alignment: Qt.AlignHCenter
            }

            Label {
                text: qsTr("Versión 1.0.0")
                font.pixelSize: 16
                Layout.alignment: Qt.AlignHCenter
                opacity: 0.7
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Material.frameColor
            }

            Label {
                text: qsTr("Sistema integral de gestión de inventario, ventas y reportes para pequeños y medianos negocios.")
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                opacity: 0.8
            }

            Label {
                text: qsTr("Desarrollado con Qt 6.10.1 + QML + C++")
                font.pixelSize: 12
                Layout.alignment: Qt.AlignHCenter
                opacity: 0.6
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Material.frameColor
            }

            Label {
                text: "© 2026 - Todos los derechos reservados"
                font.pixelSize: 12
                Layout.alignment: Qt.AlignHCenter
                opacity: 0.6
            }
        }

        footer: DialogButtonBox {
            Button {
                text: qsTr("Cerrar")
                DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
                Material.background: ApplicationWindow.window?.currentColors?.primary ?? Material.primary
                Material.foreground: Material.theme === Material.Dark ? "#000000" : "#FFFFFF"
            }
        }
    }
    
    // Di\u00e1logo para seleccionar d\u00f3nde guardar el backup
    Platform.FileDialog {
        id: exportFileDialog
        title: qsTr("Guardar copia de seguridad de la base de datos")
        fileMode: Platform.FileDialog.SaveFile
        nameFilters: [qsTr("Base de datos SQLite (*.db)")]
        defaultSuffix: "db"
        currentFile: Platform.StandardPaths.writableLocation(Platform.StandardPaths.DocumentsLocation) + 
                     "/backup_inventario_" + Qt.formatDateTime(new Date(), "yyyy-MM-dd_HHmmss") + ".db"
        
        onAccepted: {
            // Obtener la ruta del archivo seleccionado (quitar el prefijo file:///)
            var filePath = exportFileDialog.currentFile.toString()
            
            // Convertir URL a ruta local
            if (Qt.platform.os === "windows") {
                filePath = filePath.replace(/^file:\/\/\//, "")
            } else {
                filePath = filePath.replace(/^file:\/\//, "")
            }
            
            // Intentar exportar la base de datos
            if (databaseManager.exportDatabase(filePath)) {
                exportNotification.isSuccess = true
                exportNotification.message = qsTr("Base de datos exportada exitosamente")
                exportNotification.open()
            } else {
                exportNotification.isSuccess = false
                exportNotification.message = qsTr("Error al exportar: ") + databaseManager.lastError()
                exportNotification.open()
            }
        }
    }
}

