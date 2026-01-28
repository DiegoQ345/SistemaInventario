import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Effects
import Qt.labs.settings
import "qml/components"

ApplicationWindow {
    id: root
    width: 1280
    height: 720
    minimumWidth: 1024
    minimumHeight: 600
    visible: true
    title: qsTr("Sistema de Inventario")

    // Configuración de temas - Material 3
    Settings {
        id: settings
        property bool isDarkMode: false
        property int colorScheme: 0  // 0: Purple, 1: Blue, 2: Green, 3: Orange
    }
    
    // Esquemas de color Material 3 - Mejorado para mejor contraste
    property var colorSchemes: [
        { // Purple (default)
            name: "Purple",
            light: { primary: "#6750A4", container: "#EADDFF", surface: "#FFFFFF", onSurface: "#1C1B1F", surfaceVariant: "#E7E0EC", outline: "#79747E", error: "#BA1A1A" },
            dark: { primary: "#D0BCFF", container: "#4F378B", surface: "#1C1B1F", onSurface: "#E6E1E5", surfaceVariant: "#49454F", outline: "#938F99", error: "#FFB4AB" }
        },
        { // Blue
            name: "Blue", 
            light: { primary: "#0061A4", container: "#C2E7FF", surface: "#FFFFFF", onSurface: "#001F2A", surfaceVariant: "#DEE3EB", outline: "#72777F", error: "#BA1A1A" },
            dark: { primary: "#79D1FF", container: "#004A77", surface: "#001F2A", onSurface: "#E1E2EC", surfaceVariant: "#42474E", outline: "#8C9199", error: "#FFB4AB" }
        },
        { // Green
            name: "Green",
            light: { primary: "#006E1C", container: "#96F990", surface: "#FFFFFF", onSurface: "#1A1C19", surfaceVariant: "#DEE5D8", outline: "#74796D", error: "#BA1A1A" },
            dark: { primary: "#7ADC71", container: "#005313", surface: "#1A1C19", onSurface: "#E2E3DD", surfaceVariant: "#42493F", outline: "#8D9286", error: "#FFB4AB" }
        },
        { // Orange
            name: "Orange",
            light: { primary: "#8B5000", container: "#FFDDB3", surface: "#FFFFFF", onSurface: "#201A17", surfaceVariant: "#EFE0CF", outline: "#7F7667", error: "#BA1A1A" },
            dark: { primary: "#FFB951", container: "#6A3C00", surface: "#201A17", onSurface: "#ECE0D4", surfaceVariant: "#51443A", outline: "#9A8D7E", error: "#FFB4AB" }
        }
    ]
    
    property var currentColors: settings.isDarkMode 
        ? colorSchemes[settings.colorScheme].dark 
        : colorSchemes[settings.colorScheme].light
    
    // Tema Material 3 dinámico
    Material.theme: settings.isDarkMode ? Material.Dark : Material.Light
    Material.primary: currentColors.primary
    Material.background: currentColors.surface
    Material.foreground: currentColors.onSurface

    // Menú lateral
    Drawer {
        id: drawer
        width: Math.min(250, root.width * 0.3)
        height: root.height
        modal: true
        
        // Overlay con efecto de desenfoque en el contenido de fondo
        Overlay.modal: Rectangle {
            color: settings.isDarkMode ? 
                Qt.rgba(0, 0, 0, 0.4) : 
                Qt.rgba(0.2, 0.2, 0.2, 0.3)
            
            MultiEffect {
                anchors.fill: parent
                source: contentArea
                blur: 1.0
                blurMax: 48
                blurMultiplier: 1.0
            }
        }
        
        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // Header del drawer - Material 3
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 180
                color: currentColors.container

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20

                    Image {
                        source: "qrc:/resources/logo.png"
                        Layout.preferredWidth: 64
                        Layout.preferredHeight: 64
                        fillMode: Image.PreserveAspectFit
                        visible: false  // Mostrar cuando tengas logo
                    }

                    Label {
                        text: qsTr("Sistema de Inventario")
                        font.pixelSize: 18
                        font.bold: true
                        color: settings.isDarkMode ? "white" : Material.foreground
                    }

                    Label {
                        text: qsTr("v1.0.0")
                        font.pixelSize: 12
                        color: settings.isDarkMode ? "white" : Material.foreground
                        opacity: 0.8
                    }
                }
            }

            // Menú de navegación
            ListView {
                id: navigationList
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: 0

                model: ListModel {
                    ListElement { title: "Dashboard"; iconName: "dashboard"; page: "Dashboard" }
                    ListElement { title: "Productos"; iconName: "inventory"; page: "Products" }
                    ListElement { title: "Ventas"; iconName: "shopping-cart"; page: "Sales" }
                    ListElement { title: "Clientes"; iconName: "group"; page: "Customers" }
                    ListElement { title: "Reportes"; iconName: "bar-chart"; page: "Reports" }
                    ListElement { title: "Importar Excel"; iconName: "upload-file"; page: "Import" }
                    ListElement { title: "Configuración"; iconName: "settings"; page: "Settings" }
                }

                delegate: ItemDelegate {
                    width: navigationList.width
                    height: 56
                    
                    background: Rectangle {
                        color: ListView.isCurrentItem ? 
                               Qt.rgba(Material.primary.r, Material.primary.g, Material.primary.b, 0.12) : 
                               "transparent"
                        radius: ListView.isCurrentItem ? 28 : 0
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        
                        Behavior on color { ColorAnimation { duration: 200 } }
                        Behavior on radius { NumberAnimation { duration: 200 } }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 24
                        anchors.rightMargin: 24
                        spacing: 16

                        // Icono usando Material Icons
                        Label {
                            text: getIconChar(model.iconName)
                            font.family: "Segoe MDL2 Assets" // Windows 10+ icons
                            font.pixelSize: 20
                            color: ListView.isCurrentItem ? Material.primary : Material.foreground
                            Layout.preferredWidth: 24
                            horizontalAlignment: Text.AlignHCenter
                            
                            Behavior on color { ColorAnimation { duration: 200 } }
                            
                            function getIconChar(iconName) {
                                // Usando Segoe MDL2 Assets (iconos nativos de Windows)
                                var icons = {
                                    "dashboard": "\uE80F",       // Home
                                    "inventory": "\uE7B8",       // Package
                                    "shopping-cart": "\uE7BF",   // Shop
                                    "assessment": "\uE9D9",      // Chart
                                    "group": "\uE716",           // People
                                    "bar-chart": "\uE9D2",       // BarChart
                                    "upload-file": "\uE898",     // Upload
                                    "settings": "\uE713"         // Settings
                                }
                                return icons[iconName] || "\uE8FB"
                            }
                        }

                        Label {
                            text: model.title
                            font.pixelSize: 14
                            font.weight: ListView.isCurrentItem ? Font.Medium : Font.Normal
                            Layout.fillWidth: true
                            color: ListView.isCurrentItem ? Material.primary : Material.foreground
                        }
                    }

                    onClicked: {
                        navigationList.currentIndex = index
                        
                        // Cargar la página correspondiente
                        var pagePath = "qml/pages/" + model.page + "Page.qml"
                        
                        // Intentar cargar la página, si no existe mostrar mensaje
                        try {
                            stackView.replace(pagePath)
                        } catch (e) {
                            // Si la página no existe, mostrar página de "En construcción"
                            stackView.replace(underConstructionComponent)
                        }
                        
                        drawer.close()
                    }
                }
            }
        }
    }

    // Header principal - Material 3
    header: ToolBar {
        Material.elevation: 0
        Material.background: currentColors.container
        height: 64

        RowLayout {
            anchors.fill: parent
            spacing: 8

            ToolButton {
                icon.name: "menu"
                text: "☰"
                font.pixelSize: 20
                onClicked: drawer.open()
            }

            Label {
                text: stackView.currentItem?.title ?? qsTr("Dashboard")
                font.pixelSize: 18
                font.weight: Font.Medium
                Layout.fillWidth: true
                color: currentColors.onSurface
            }
            
            // Selector de color
            RoundButton {
                text: "\uE790"
                font.family: "Segoe MDL2 Assets"
                font.pixelSize: 20
                flat: true
                
                onClicked: colorMenu.open()
                
                Menu {
                    id: colorMenu
                    y: parent.height
                    
                    MenuItem {
                        text: "⬤ Purple"
                        font.bold: settings.colorScheme === 0
                        onClicked: settings.colorScheme = 0
                    }
                    MenuItem {
                        text: "⬤ Blue"
                        font.bold: settings.colorScheme === 1
                        onClicked: settings.colorScheme = 1
                    }
                    MenuItem {
                        text: "⬤ Green"
                        font.bold: settings.colorScheme === 2
                        onClicked: settings.colorScheme = 2
                    }
                    MenuItem {
                        text: "⬤ Orange"
                        font.bold: settings.colorScheme === 3
                        onClicked: settings.colorScheme = 3
                    }
                }
            }
            
            // Toggle modo oscuro/claro
            RoundButton {
                text: settings.isDarkMode ? "\uE708" : "\uE706"
                font.family: "Segoe MDL2 Assets"
                font.pixelSize: 20
                flat: true
                
                onClicked: settings.isDarkMode = !settings.isDarkMode
            }

            // Botón de notificaciones mejorado
            RoundButton {
                flat: true
                implicitWidth: 48
                implicitHeight: 48
                
                contentItem: Item {
                    Label {
                        anchors.centerIn: parent
                        text: "\uE7E7"  // Notification icon
                        font.family: "Segoe MDL2 Assets"
                        font.pixelSize: 20
                        color: currentColors.onSurface
                    }
                    
                    Badge {
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.topMargin: 8
                        anchors.rightMargin: 8
                        value: 3  // Alertas pendientes
                    }
                }
                
                onClicked: notificationMenu.open()
                
                Menu {
                    id: notificationMenu
                    y: parent.height + 5
                    width: 320
                    
                    MenuItem {
                        text: "Producto bajo stock: Laptop HP"
                        font.pixelSize: 12
                    }
                    MenuItem {
                        text: "Nueva venta registrada: S/150.00"
                        font.pixelSize: 12
                    }
                    MenuItem {
                        text: "Inventario actualizado"
                        font.pixelSize: 12
                    }
                    MenuSeparator {}
                    MenuItem {
                        text: "Ver todas las notificaciones"
                        font.pixelSize: 12
                        font.bold: true
                    }
                }
            }

            // Botón de usuario mejorado
            RoundButton {
                flat: true
                implicitWidth: 48
                implicitHeight: 48
                
                contentItem: Label {
                    text: "\uE77B"  // Contact icon
                    font.family: "Segoe MDL2 Assets"
                    font.pixelSize: 22
                    color: currentColors.onSurface
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                
                background: Rectangle {
                    radius: 24
                    color: parent.hovered ? currentColors.surfaceVariant : "transparent"
                    border.width: 2
                    border.color: currentColors.outline
                    
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
                
                onClicked: userMenu.open()
                
                Menu {
                    id: userMenu
                    y: parent.height + 5
                    
                    MenuItem {
                        text: "👤 Administrador"
                        enabled: false
                        font.pixelSize: 13
                    }
                    MenuSeparator {}
                    MenuItem {
                        text: "⚙️ Mi Perfil"
                        font.pixelSize: 13
                    }
                    MenuItem {
                        text: "🔐 Cambiar Contraseña"
                        font.pixelSize: 13
                    }
                    MenuSeparator {}
                    MenuItem {
                        text: "🚪 Cerrar Sesión"
                        font.pixelSize: 13
                        Material.foreground: Material.Red
                    }
                }
            }
        }
    }

    // Contenido principal
    Item {
        id: contentArea
        anchors.fill: parent
        
        StackView {
            id: stackView
            anchors.fill: parent
            initialItem: Page {
                title: qsTr("Dashboard")
            
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 20
                
                Label {
                    text: qsTr("Bienvenido al Sistema de Inventario")
                    font.pixelSize: 28
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter
                }
                
                Label {
                    text: qsTr("La aplicación está lista. Configure la base de datos para comenzar.")
                    font.pixelSize: 14
                    opacity: 0.7
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }

    // Badge component (inline)
    component Badge: Rectangle {
        property int value: 0
        
        width: 20
        height: 20
        radius: 10
        color: Material.color(Material.Red)
        visible: value > 0

        Label {
            anchors.centerIn: parent
            text: parent.value > 99 ? "99+" : parent.value.toString()
            color: "white"
            font.pixelSize: 10
            font.bold: true
        }
    }
    
    // Conexiones dinámicas a SalesCartViewModel
    Connections {
        target: stackView.currentItem?.viewModel
        ignoreUnknownSignals: true
        
        // Señales de SalesCartViewModel
        function onProductAdded(productName, quantity) {
            globalNotification.showSuccess("Agregado: " + productName + " (x" + quantity + ")")
        }
        
        function onProductNotFound(code) {
            globalNotification.showError("Producto no encontrado: " + code)
        }
        
        function onInsufficientStock(productName, available, requested) {
            globalNotification.showError(
                "Stock insuficiente de " + productName + 
                ". Disponible: " + available + ", solicitado: " + requested
            )
        }
        
        function onSaleCompleted(invoiceNumber, total, voucherType, items, subtotal, discount) {
            globalNotification.showSuccess("Venta completada - Comprobante: " + invoiceNumber)
        }
        
        function onSaleFailed(errorMessage) {
            globalNotification.showError("Error en la venta: " + errorMessage)
        }
    }
    
    // Conexiones dinámicas a PrintViewModel
    Connections {
        target: stackView.currentItem?.printViewModel
        ignoreUnknownSignals: true
        
        function onPdfGenerated(filePath) {
            globalNotification.showSuccess("PDF generado exitosamente")
        }
        
        function onPrintCompleted() {
            globalNotification.showSuccess("Impresión completada")
        }
        
        function onPrintFailed(error) {
            globalNotification.showError("Error al imprimir: " + error)
        }
    }

    // Componente para páginas en construcción
    Component {
        id: underConstructionComponent
        
        Page {
            title: qsTr("En Construcción")
            
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 30
                
                Label {
                    text: "🚧"
                    font.pixelSize: 80
                    Layout.alignment: Qt.AlignHCenter
                }
                
                Label {
                    text: qsTr("Página en Construcción")
                    font.pixelSize: 24
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter
                }
                
                Label {
                    text: qsTr("Esta funcionalidad estará disponible próximamente")
                    font.pixelSize: 14
                    opacity: 0.7
                    Layout.alignment: Qt.AlignHCenter
                }
                
                Button {
                    text: qsTr("Volver al Dashboard")
                    Material.background: Material.primary
                    Layout.alignment: Qt.AlignHCenter
                    onClicked: stackView.replace("qml/pages/DashboardPage.qml")
                }
            }
        }
    }
    
    // Notificaciones globales - Componente reutilizable
    NotificationBar {
        id: globalNotification
    }
}  // Fin contentArea
}  // Fin ApplicationWindow

