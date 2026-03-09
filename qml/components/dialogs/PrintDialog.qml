import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import Qt.labs.platform as Platform
import SistemaInventario 1.0

Dialog {
    id: root
    title: qsTr("Configuración de Impresión")
    modal: true
    anchors.centerIn: parent
    width: 500
    height: root.activeTemplate && root.activeTemplate.id ? 600 : 650
    
    // Activar blur en la página de fondo
    property var parentPage: null
    
    onOpened: {
        if (parentPage) parentPage.layer.enabled = true
        loadActiveTemplate()
    }
    onClosed: {
        if (parentPage) parentPage.layer.enabled = false
    }
    
    // Overlay con color semitransparente
    Overlay.modal: Rectangle {
        color: Material.theme === Material.Dark ? 
            Qt.rgba(0, 0, 0, 0.6) : 
            Qt.rgba(0.05, 0.05, 0.05, 0.5)
    }

    required property PrintViewModel printViewModel

    property string invoiceNumber: ""
    property string customerName: ""
    property var items: []
    property real subtotal: 0
    property real discount: 0
    property real total: 0
    property real amountPaid: 0
    property real changeGiven: 0
    property int voucherType: PrintViewModel.Boleta
    property string ruc: ""
    property string businessName: ""
    property string address: ""
    property string phone: ""
    property string email: ""
    
    // Diseño seleccionado
    property var activeTemplate: null
    property var templateElements: []
    property real templateWidth: 80
    property real templateHeight: 200
    property real pixelsPerMM: 3.78
    property var allTemplates: []
    
    TicketTemplateRepository {
        id: templateRepository
    }
    
    PrintService {
        id: printService
        onPrintCompleted: {
            console.log("PDF generado exitosamente")
        }
        onPrintFailed: function(error) {
            console.log("Error generando PDF:", error)
        }
    }
    
    function loadActiveTemplate() {
        // Cargar todos los diseños disponibles
        allTemplates = templateRepository.getAllTemplates()
        
        console.log("========== DEBUG: CARGAR DISEÑO ACTIVO ==========")
        console.log("Total de diseños disponibles:", allTemplates ? allTemplates.length : 0)
        
        // Cargar el diseño activo por defecto
        activeTemplate = templateRepository.getActiveTemplate()
        console.log("Diseño activo obtenido:", activeTemplate ? "SÍ" : "NULL")
        console.log("ID del diseño:", activeTemplate ? activeTemplate.id : "N/A")
        console.log("Nombre del diseño:", activeTemplate ? activeTemplate.name : "N/A")
        console.log("Longitud del JSON:", activeTemplate && activeTemplate.layoutJson ? activeTemplate.layoutJson.length : 0)
        
        if (activeTemplate && activeTemplate.id) {
            console.log("[OK] Diseno activo encontrado:", activeTemplate.name)
            loadTemplateData(activeTemplate)
        } else {
            console.log("[WARNING] NO HAY DISENO ACTIVO CONFIGURADO")
            console.log("[WARNING] Se usara formato estandar de impresion")
            templateElements = []
        }
        console.log("==================================================")
    }
    
    function loadTemplateData(template) {
        console.log("========== DEBUG: PARSEAR DATOS DEL DISENO ==========")
        if (!template || !template.id) {
            console.log("[WARNING] Template invalido o sin ID")
            templateElements = []
            return
        }
        
        console.log("Layout JSON (primeros 200 chars):", template.layoutJson.substring(0, 200))
        
        // Auto-configurar tamaño de papel basado en el diseño
        try {
            var layoutData = JSON.parse(template.layoutJson)
            console.log("[OK] JSON parseado correctamente")
            console.log("Estructura del layout:", Object.keys(layoutData))
            
            if (layoutData.size) {
                templateWidth = layoutData.size.width
                templateHeight = layoutData.size.height
                console.log("[OK] Tamanio del ticket:", templateWidth, "x", templateHeight, "mm")
                
                if (templateWidth === 80) {
                    root.printViewModel.paperSize = PrintViewModel.Thermal80mm
                    console.log("Configurado: Thermal 80mm")
                } else if (templateWidth === 58) {
                    root.printViewModel.paperSize = PrintViewModel.Thermal58mm
                    console.log("Configurado: Thermal 58mm")
                }
            } else {
                console.log("[WARNING] No se encontro 'size' en el layout")
            }
            
            if (layoutData.elements) {
                templateElements = layoutData.elements
                console.log("[OK] Elementos cargados:", templateElements.length)
                // Mostrar primeros 3 elementos
                for (var i = 0; i < Math.min(3, templateElements.length); i++) {
                    console.log("  Elemento", i + ":", templateElements[i].type, "en", templateElements[i].x, ",", templateElements[i].y)
                }
            } else {
                console.log("[WARNING] No se encontro 'elements' en el layout")
            }
        } catch (e) {
            console.log("[ERROR] ERROR PARSEANDO DISENO:", e)
            console.log("[ERROR] JSON que fallo:", template.layoutJson)
        }
        console.log("=======================================================")
    }
    
    // Función para generar la lista de productos formateada
    function formatProductsList() {
        if (!root.items || root.items.length === 0) {
            return "No hay productos"
        }
        
        var productLines = []
        for (var i = 0; i < root.items.length; i++) {
            var item = root.items[i]
            var line = item.productName + " x" + item.quantity + " S/" + item.subtotal.toFixed(2)
            productLines.push(line)
        }
        
        return productLines.join("\n")
    }
    
    // Función para reemplazar variables con datos reales de la venta
    function replaceVariables(text) {
        if (!text) return text
        
        var result = text
        result = result.replace(/{{businessName}}/g, root.businessName || root.printViewModel.businessName || "Mi Negocio")
        result = result.replace(/{{ruc}}/g, root.ruc || root.printViewModel.businessRuc || "")
        result = result.replace(/{{address}}/g, root.address || root.printViewModel.businessAddress || "")
        result = result.replace(/{{phone}}/g, root.phone || root.printViewModel.businessPhone || "")
        result = result.replace(/{{email}}/g, root.email || root.printViewModel.businessEmail || "")
        result = result.replace(/{{invoiceNumber}}/g, root.invoiceNumber)
        result = result.replace(/{{date}}/g, new Date().toLocaleDateString())
        result = result.replace(/{{time}}/g, new Date().toLocaleTimeString())
        result = result.replace(/{{datetime}}/g, new Date().toLocaleString())
        result = result.replace(/{{customerName}}/g, root.customerName)
        result = result.replace(/{{customerRuc}}/g, "")
        result = result.replace(/{{subtotal}}/g, root.subtotal.toFixed(2))
        result = result.replace(/{{discount}}/g, root.discount.toFixed(2))
        result = result.replace(/{{tax}}/g, (root.total - root.subtotal).toFixed(2))
        result = result.replace(/{{total}}/g, root.total.toFixed(2))
        result = result.replace(/{{amountPaid}}/g, root.amountPaid.toFixed(2))
        result = result.replace(/{{changeGiven}}/g, root.changeGiven.toFixed(2))
        result = result.replace(/{{voucherType}}/g, root.voucherType === PrintViewModel.Factura ? "FACTURA" : "BOLETA")
        result = result.replace(/{{Productos}}/g, formatProductsList())
        
        return result
    }
    
    function generateSalePdf() {
        console.log("========== DEBUG: GENERAR PDF ==========")
        console.log("Active template existe:", root.activeTemplate ? "SÍ" : "NO")
        console.log("Active template ID:", root.activeTemplate ? root.activeTemplate.id : "N/A")
        
        if (!root.activeTemplate || !root.activeTemplate.id) {
            console.log("[WARNING] ABORTANDO: No hay diseno activo configurado")
            console.log("[WARNING] Resultado: No se genera PDF")
            console.log("=========================================")
            return
        }
        
        console.log("[OK] Validacion pasada - Diseno:", root.activeTemplate.name)
        console.log("Enviando layoutJson (primeros 100 chars):", root.activeTemplate.layoutJson.substring(0, 100))
        
        // Crear sale object con los datos
        var saleData = {
            id: 0,
            invoiceNumber: root.invoiceNumber,
            customerName: root.customerName,
            createdAt: new Date(),
            paymentMethodName: "Efectivo",
            subtotal: root.subtotal,
            discount: root.discount,
            tax: root.total - root.subtotal,
            total: root.total,
            items: root.items || []
        }
        
        var invoiceData = {
            ruc: root.ruc,
            businessName: root.businessName,
            address: root.address
        }
        
        // Generar nombre de archivo con timestamp
        var timestamp = new Date().toISOString().replace(/[:.]/g, "-").substring(0, 19)
        var downloadsPath = Platform.StandardPaths.writableLocation(Platform.StandardPaths.DownloadLocation)
        
        // Convertir URI a ruta nativa de Windows
        var downloadsPathStr = String(downloadsPath).replace('file:///', '')
        var outputPath = downloadsPathStr + "/ticket_" + root.invoiceNumber.replace(/[:\\/]/g, "_") + "_" + timestamp + ".pdf"
        
        console.log("Generando PDF de venta en:", outputPath)
        console.log("Layout JSON:", root.activeTemplate.layoutJson)
        
        // Llamar al servicio de impresi\u00f3n para generar PDF
        var success = printService.generateCustomTicketPdf(
            saleData,
            root.voucherType,
            invoiceData,
            root.activeTemplate.layoutJson,
            outputPath
        )
        
        console.log("========== RESULTADO ==========")
        if (success) {
            console.log("[OK] PDF generado exitosamente:", outputPath)
            // Podrias agregar un dialogo de confirmacion aqui
        } else {
            console.log("[ERROR] Error al generar el PDF")
        }
        console.log("===============================")
    }

    ScrollView {
        anchors.fill: parent
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AsNeeded

        ColumnLayout {
            width: root.availableWidth
            spacing: 16

        // Configuración de impresora
        GroupBox {
            Layout.fillWidth: true
            title: qsTr("Impresora")

            ColumnLayout {
                anchors.fill: parent
                spacing: 12

                ComboBox {
                    id: printerComboBox
                    Layout.fillWidth: true
                    model: root.printViewModel.availablePrinters

                    Component.onCompleted: {
                        currentIndex = root.printViewModel.defaultPrinterIndex
                    }

                    onCurrentTextChanged: {
                        if (currentText !== "")
                            root.printViewModel.defaultPrinter = currentText
                    }
                }

                Button {
                    text: "Actualizar lista"
                    Layout.fillWidth: true
                    flat: true
                    onClicked: root.printViewModel.refreshPrinters()
                }
            }
        }

        // Selector de diseño de ticket
        GroupBox {
            Layout.fillWidth: true
            title: qsTr("Diseño de Ticket")
            
            ColumnLayout {
                anchors.fill: parent
                spacing: 8
                
                Label {
                    text: qsTr("Selecciona el diseño a utilizar:")
                    font.pixelSize: 12
                    opacity: 0.8
                }
                
                ComboBox {
                    id: templateSelector
                    Layout.fillWidth: true
                    model: root.allTemplates
                    textRole: "name"
                    valueRole: "id"
                    
                    Component.onCompleted: {
                        // Seleccionar el diseño activo por defecto
                        if (root.activeTemplate && root.activeTemplate.id) {
                            for (var i = 0; i < root.allTemplates.length; i++) {
                                if (root.allTemplates[i].id === root.activeTemplate.id) {
                                    currentIndex = i
                                    break
                                }
                            }
                        }
                    }
                    
                    onCurrentIndexChanged: {
                        if (currentIndex >= 0 && currentIndex < root.allTemplates.length) {
                            root.activeTemplate = root.allTemplates[currentIndex]
                            root.loadTemplateData(root.activeTemplate)
                        }
                    }
                }
                
                // Banner de estado del diseño activo
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: statusRow.implicitHeight + 20
                    color: root.activeTemplate && root.activeTemplate.id ? 
                        Material.color(Material.Green, Material.Shade100) :
                        Material.color(Material.Orange, Material.Shade100)
                    radius: 6
                    border.width: 2
                    border.color: root.activeTemplate && root.activeTemplate.id ? 
                        Material.color(Material.Green) :
                        Material.color(Material.Orange)
                    
                    RowLayout {
                        id: statusRow
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12
                        
                        Label {
                            text: root.activeTemplate && root.activeTemplate.id ? "[OK]" : "[!]"
                            font.pixelSize: 18
                            font.bold: true
                        }
                        
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            
                            Label {
                                Layout.fillWidth: true
                                text: root.activeTemplate && root.activeTemplate.id ? 
                                    qsTr("Diseno activo: %1").arg(root.activeTemplate.name) :
                                    qsTr("[!] NO HAY DISENO ACTIVO")
                                font.bold: true
                                font.pixelSize: 13
                                color: root.activeTemplate && root.activeTemplate.id ? 
                                    Material.color(Material.Green, Material.Shade900) :
                                    Material.color(Material.Orange, Material.Shade900)
                                wrapMode: Text.WordWrap
                            }
                            
                            Label {
                                Layout.fillWidth: true
                                text: root.activeTemplate && root.activeTemplate.id ? 
                                    qsTr("La impresion usara tu diseno personalizado (%1x%2mm)").arg(root.templateWidth).arg(root.templateHeight) :
                                    qsTr("Se usara formato estandar. Ve a 'Disenador de Tickets' para activar un diseno.")
                                font.pixelSize: 10
                                wrapMode: Text.WordWrap
                                opacity: 0.8
                            }
                        }
                    }
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: infoRow.implicitHeight + 16
                    color: Material.theme === Material.Dark ? 
                        Qt.lighter(Material.background, 1.3) : 
                        Material.color(Material.Grey, Material.Shade200)
                    radius: 4
                    visible: root.activeTemplate && root.activeTemplate.id
                    
                    RowLayout {
                        id: infoRow
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 8
                        
                        Label {
                            text: "\uE946"
                            font.family: "Segoe MDL2 Assets"
                            font.pixelSize: 16
                            color: Material.accent
                        }
                        
                        Label {
                            Layout.fillWidth: true
                            text: qsTr("El tamanio de papel se configurara automaticamente segun el diseno seleccionado")
                            font.pixelSize: 10
                            wrapMode: Text.WordWrap
                            opacity: 0.7
                        }
                    }
                }
                
                Label {
                    Layout.fillWidth: true
                    text: qsTr("[!] Si no hay disenos disponibles, ve a 'Disenador de Tickets' para crear uno")
                    font.pixelSize: 10
                    wrapMode: Text.WordWrap
                    opacity: 0.6
                    visible: root.allTemplates.length === 0
                    color: Material.color(Material.Orange)
                }
            }
        }

        // Botones de acción
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Button {
                text: "\uE8A5  " + qsTr("Vista Previa")
                font.family: "Segoe MDL2 Assets"
                Layout.fillWidth: true
                Material.background: ApplicationWindow.window?.currentColors?.primary ?? Material.primary
                Material.foreground: Material.theme === Material.Dark ? "#000000" : "#FFFFFF"

                onClicked: previewDialog.open()
            }
            
            Button {
                text: "\uE8AA  " + qsTr("Generar PDF")
                font.family: "Segoe MDL2 Assets"
                Layout.fillWidth: true
                Material.background: Material.color(Material.Green)
                Material.foreground: "#FFFFFF"
                enabled: root.activeTemplate && root.activeTemplate.id

                onClicked: generateSalePdf()
            }

            Button {
                text: "\uE749  " + qsTr("Imprimir")
                font.family: "Segoe MDL2 Assets"
                Layout.fillWidth: true
                Material.background: ApplicationWindow.window?.currentColors?.primary ?? Material.primary
                Material.foreground: Material.theme === Material.Dark ? "#000000" : "#FFFFFF"

                onClicked: {
                    console.log("========== DEBUG: BOTÓN IMPRIMIR ==========")
                    var success = false
                    
                    console.log("Active template existe:", root.activeTemplate ? "SÍ" : "NO")
                    console.log("Active template ID:", root.activeTemplate ? root.activeTemplate.id : "N/A")
                    
                    // Usar diseno personalizado si esta disponible
                    if (root.activeTemplate && root.activeTemplate.id) {
                        console.log("[OK] Imprimiendo con diseno personalizado:", root.activeTemplate.name)
                        console.log("Enviando layoutJson (primeros 100 chars):", root.activeTemplate.layoutJson.substring(0, 100))
                        success = root.printViewModel.printCustomTicket(
                            root.invoiceNumber,
                            root.customerName,
                            root.items,
                            root.subtotal,
                            root.discount,
                            root.total,
                            root.voucherType,
                            root.activeTemplate.layoutJson,
                            root.ruc,
                            root.businessName,
                            root.address,
                            root.amountPaid,
                            root.changeGiven
                        )
                    } else {
                        // Usar impresion estandar
                        console.log("[WARNING] Imprimiendo con formato estandar (sin diseno personalizado)")
                        success = root.printViewModel.printVoucher(
                            root.invoiceNumber,
                            root.customerName,
                            root.items,
                            root.subtotal,
                            root.discount,
                            root.total,
                            root.voucherType,
                            root.ruc,
                            root.businessName,
                            root.address,
                            root.amountPaid,
                            root.changeGiven
                        )
                    }
                    
                    console.log("========== RESULTADO ==========")
                    if (success) {
                        console.log("✅ Impresión exitosa")
                        root.close()
                    } else {
                        console.log("❌ Error en la impresión")
                    }
                    console.log("===============================")
                }
            }

            Button {
                text: qsTr("Cancelar")
                Layout.preferredWidth: 100
                Material.background: Material.color(Material.Red)
                
                contentItem: Label {
                    text: parent.text
                    font: parent.font
                    color: Material.theme === Material.Dark ? "white" : "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: root.close()
            }
        }
        }
    }
    
    // Diálogo de Vista Previa Completa
    Dialog {
        id: previewDialog
        title: qsTr("Vista Previa del Ticket - ") + (root.activeTemplate && root.activeTemplate.id ? root.activeTemplate.name : qsTr("Formato Estándar"))
        modal: true
        anchors.centerIn: parent
        width: Math.min(600, (ApplicationWindow.window?.width ?? 1024) * 0.95)
        height: Math.min(850, (ApplicationWindow.window?.height ?? 768) * 0.95)
        
        background: Rectangle {
            color: Material.dialogColor
            radius: 8
            border.width: 1
            border.color: Material.theme === Material.Dark ? 
                Qt.lighter(Material.backgroundColor, 1.3) :
                Qt.darker(Material.backgroundColor, 1.1)
        }
        
        Overlay.modal: Rectangle {
            color: Material.theme === Material.Dark ? 
                Qt.rgba(0, 0, 0, 0.7) : 
                Qt.rgba(0.05, 0.05, 0.05, 0.6)
        }
        
        ColumnLayout {
            anchors.fill: parent
            spacing: 12
            
            // Mensaje informativo
            Label {
                Layout.fillWidth: true
                text: qsTr("Vista previa de cómo se verá el ticket impreso con todos los productos y totales")
                font.pixelSize: 11
                wrapMode: Text.WordWrap
                opacity: 0.8
                horizontalAlignment: Text.AlignHCenter
            }
            
            // Vista previa del ticket renderizado
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                
                ScrollBar.vertical.policy: ScrollBar.AlwaysOn
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                
                // Contenedor que crece con el contenido
                Column {
                    id: contentColumn
                    width: previewDialog.availableWidth
                    spacing: 0
                    
                    Item {
                        width: parent.width
                        height: 20  // Margen superior
                    }
                    
                    Rectangle {
                        id: ticketRect
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: root.activeTemplate && root.activeTemplate.id ? 
                            templateWidth * pixelsPerMM : 
                            300
                        // Para diseño personalizado usar altura fija, para estándar usar contenido
                        height: {
                            if (root.activeTemplate && root.activeTemplate.id) {
                                return templateHeight * pixelsPerMM
                            } else {
                                // Para diseño estándar, calcular desde el ColumnLayout
                                return standardPreviewColumn.visible ? 
                                    (standardPreviewColumn.implicitHeight + 40) : 
                                    500
                            }
                        }
                        color: Material.theme === Material.Dark ? "#1a1a1a" : "white"
                        border.width: 2
                        border.color: Material.theme === Material.Dark ? "white" : "#cccccc"
                        
                        // Diseño personalizado
                        Repeater {
                            model: root.activeTemplate && root.activeTemplate.id ? templateElements : []
                            visible: root.activeTemplate && root.activeTemplate.id
                            
                            Loader {
                                x: modelData.x * pixelsPerMM
                                y: modelData.y * pixelsPerMM
                                
                                sourceComponent: modelData.type === "text" ? textPreviewComponent : 
                                                modelData.type === "line" ? linePreviewComponent : imagePreviewComponent
                                
                                property var elementData: modelData
                            }
                        }
                        
                        // Diseño estándar si no hay diseño personalizado
                        ColumnLayout {
                                id: standardPreviewColumn
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.leftMargin: 16
                                anchors.rightMargin: 16
                                anchors.topMargin: 20
                                spacing: 8
                                visible: !root.activeTemplate || !root.activeTemplate.id
                                
                                Label {
                                    Layout.fillWidth: true
                                    text: root.businessName || "Mi Negocio"
                                    font.pixelSize: 14
                                    font.bold: true
                                    horizontalAlignment: Text.AlignHCenter
                                    wrapMode: Text.WordWrap
                                }
                                
                                Label {
                                    Layout.fillWidth: true
                                    text: "RUC: " + (root.ruc || "N/A")
                                    font.pixelSize: 10
                                    horizontalAlignment: Text.AlignHCenter
                                }
                                
                                Label {
                                    Layout.fillWidth: true
                                    text: root.address || ""
                                    font.pixelSize: 9
                                    horizontalAlignment: Text.AlignHCenter
                                    visible: root.address !== ""
                                    wrapMode: Text.WordWrap
                                }
                                
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 1
                                    color: Material.theme === Material.Dark ? "white" : "black"
                                }
                                
                                Label {
                                    Layout.fillWidth: true
                                    text: (root.voucherType === PrintViewModel.Factura ? "FACTURA" : "BOLETA") + 
                                          "\nN° " + root.invoiceNumber
                                    font.pixelSize: 12
                                    font.bold: true
                                    horizontalAlignment: Text.AlignHCenter
                                    wrapMode: Text.WordWrap
                                }
                                
                                Label {
                                    Layout.fillWidth: true
                                    text: "Cliente: " + root.customerName
                                    font.pixelSize: 10
                                    wrapMode: Text.WordWrap
                                }
                                
                                Label {
                                    Layout.fillWidth: true
                                    text: "Fecha: " + new Date().toLocaleString()
                                    font.pixelSize: 9
                                }
                                
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 1
                                    color: Material.theme === Material.Dark ? "white" : "black"
                                }
                                
                                Label {
                                    Layout.fillWidth: true
                                    text: "PRODUCTOS:"
                                    font.pixelSize: 10
                                    font.bold: true
                                }
                                
                                Repeater {
                                    model: root.items
                                    
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        
                                        Label {
                                            Layout.fillWidth: true
                                            text: modelData.productName
                                            font.pixelSize: 9
                                            wrapMode: Text.WordWrap
                                        }
                                        
                                        RowLayout {
                                            Layout.fillWidth: true
                                            
                                            Label {
                                                text: modelData.quantity + " x S/ " + modelData.unitPrice.toFixed(2)
                                                font.pixelSize: 9
                                            }
                                            
                                            Item { Layout.fillWidth: true }
                                            
                                            Label {
                                                text: "S/ " + (modelData.quantity * modelData.unitPrice).toFixed(2)
                                                font.pixelSize: 9
                                                font.bold: true
                                            }
                                        }
                                    }
                                }
                                
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 1
                                    color: Material.theme === Material.Dark ? "white" : "black"
                                }
                                
                                RowLayout {
                                    Layout.fillWidth: true
                                    
                                    Label {
                                        text: "SUBTOTAL:"
                                        font.pixelSize: 10
                                    }
                                    
                                    Item { Layout.fillWidth: true }
                                    
                                    Label {
                                        text: "S/ " + root.subtotal.toFixed(2)
                                        font.pixelSize: 10
                                    }
                                }
                                
                                RowLayout {
                                    Layout.fillWidth: true
                                    visible: root.discount > 0
                                    
                                    Label {
                                        text: "DESCUENTO:"
                                        font.pixelSize: 10
                                        color: Material.color(Material.Red)
                                    }
                                    
                                    Item { Layout.fillWidth: true }
                                    
                                    Label {
                                        text: "- S/ " + root.discount.toFixed(2)
                                        font.pixelSize: 10
                                        color: Material.color(Material.Red)
                                    }
                                }
                                
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 2
                                    color: Material.theme === Material.Dark ? "white" : "black"
                                }
                                
                                RowLayout {
                                    Layout.fillWidth: true
                                    
                                    Label {
                                        text: "TOTAL:"
                                        font.pixelSize: 14
                                        font.bold: true
                                    }
                                    
                                    Item { Layout.fillWidth: true }
                                    
                                    Label {
                                        text: "S/ " + root.total.toFixed(2)
                                        font.pixelSize: 14
                                        font.bold: true
                                    }
                                }
                                
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 1
                                    color: Material.theme === Material.Dark ? "white" : "black"
                                }
                                
                                Label {
                                    Layout.fillWidth: true
                                    text: "¡Gracias por su compra!"
                                    font.pixelSize: 10
                                    horizontalAlignment: Text.AlignHCenter
                                    topPadding: 8
                                    bottomPadding: 20
                                }
                        }  // Cierre del ColumnLayout standardPreviewColumn
                    }  // Cierre del Rectangle ticketRect
                    
                    Item {
                        width: parent.width
                        height: 20  // Margen inferior
                    }
                }  // Cierre del Column contentColumn
            }  // Cierre del ScrollView
            
            Label {
                Layout.fillWidth: true
                text: qsTr("Esta es la boleta final con todos los productos, subtotal y total que se imprimirá")
                font.pixelSize: 11
                wrapMode: Text.WordWrap
                opacity: 0.75
                horizontalAlignment: Text.AlignHCenter
                topPadding: 8
            }
            
            // Botón cerrar
            Button {
                text: qsTr("Cerrar")
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                Material.background: ApplicationWindow.window?.currentColors?.primary ?? Material.primary
                Material.foreground: Material.theme === Material.Dark ? "#000000" : "#FFFFFF"
                
                onClicked: previewDialog.close()
            }
        }  // Cierre del ColumnLayout
    }  // Cierre del Dialog previewDialog
    
    // Componentes para renderizado
    Component {
        id: textPreviewComponent
        Item {
            width: elementData.width * pixelsPerMM
            height: elementData.height * pixelsPerMM
            
            // Si es el marcador de items, mostrar productos reales
            Column {
                anchors.fill: parent
                spacing: 2
                visible: elementData.content === "[ITEMS - Auto]"
                
                Repeater {
                    model: root.items
                    
                    Label {
                        width: parent.width
                        text: modelData.quantity + "x " + modelData.productName + " - S/ " + (modelData.quantity * modelData.unitPrice).toFixed(2)
                        font.pixelSize: 8 * (pixelsPerMM / 3)
                        wrapMode: Text.WordWrap
                        color: Material.theme === Material.Dark ? "white" : "black"
                    }
                }
            }
            
            // Para texto normal
            Label {
                anchors.fill: parent
                text: replaceVariables(elementData.content)
                font.pixelSize: elementData.fontSize * (pixelsPerMM / 3)
                font.bold: elementData.bold
                horizontalAlignment: elementData.align === "center" ? Text.AlignHCenter : 
                                    elementData.align === "right" ? Text.AlignRight : Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap
                color: Material.theme === Material.Dark ? "white" : "black"
                visible: elementData.content !== "[ITEMS - Auto]"
            }
        }
    }
    
    Component {
        id: linePreviewComponent
        Rectangle {
            width: elementData.width * pixelsPerMM
            height: 1
            color: Material.theme === Material.Dark ? "white" : "black"
        }
    }
    
    Component {
        id: imagePreviewComponent
        Item {
            width: elementData.width * pixelsPerMM
            height: elementData.height * pixelsPerMM
            
            Image {
                anchors.fill: parent
                source: elementData.content || ""
                fillMode: Image.PreserveAspectFit
                visible: elementData.content && elementData.content !== ""
                smooth: true
                asynchronous: true
            }
            
            Rectangle {
                anchors.fill: parent
                color: Material.theme === Material.Dark ? "#2a2a2a" : "#f0f0f0"
                border.color: Material.theme === Material.Dark ? "#555" : "#ccc"
                visible: !elementData.content || elementData.content === ""
                
                Label {
                    anchors.centerIn: parent
                    text: "\uEB9F"
                    font.family: "Segoe MDL2 Assets"
                    font.pixelSize: 16
                    color: Material.theme === Material.Dark ? "#888" : "#999"
                }
            }
        }
    }
}
