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

    // Exponer stackView como propiedad para acceso desde páginas hijas
    property alias stackView: stackView

    // Exponer settings para acceso global
    property alias settings: settings

    // ─── Helper global: cierra diálogos de la página actual antes de navegar ───
    function safeNavigate(path) {
        var currentPage = stackView.currentItem
        if (currentPage && typeof currentPage.closeAllDialogs === "function") {
            currentPage.closeAllDialogs()
        }
        try {
            stackView.replace(path)
        } catch (e) {
            stackView.replace(underConstructionComponent)
        }
    }

    // Objeto de estilos accesible globalmente
    property QtObject appStyle: QtObject {
        // Tamaños de fuente base escalados
        readonly property real fontXSmall: 8 * settings.fontScale
        readonly property real fontSmall: 10 * settings.fontScale
        readonly property real fontBody: 12 * settings.fontScale
        readonly property real fontBodyLarge: 14 * settings.fontScale
        readonly property real fontMedium: 16 * settings.fontScale
        readonly property real fontLarge: 18 * settings.fontScale
        readonly property real fontXLarge: 20 * settings.fontScale
        readonly property real fontXXLarge: 24 * settings.fontScale
        readonly property real fontHuge: 32 * settings.fontScale
        readonly property real fontGiant: 40 * settings.fontScale

        // Tamaños de iconos escalados (Segoe MDL2 Assets)
        readonly property real iconSmall: 12 * settings.fontScale
        readonly property real iconMedium: 16 * settings.fontScale
        readonly property real iconLarge: 20 * settings.fontScale
        readonly property real iconXLarge: 24 * settings.fontScale
        readonly property real iconXXLarge: 32 * settings.fontScale
        readonly property real iconHuge: 48 * settings.fontScale

        // Tamaños de componentes escalados
        readonly property real buttonHeight: 40 * settings.fontScale
        readonly property real textFieldHeight: 48 * settings.fontScale
        readonly property real toolButtonSize: 40 * settings.fontScale

        // Espaciados escalados
        readonly property real paddingSmall: 4 * settings.fontScale
        readonly property real paddingMedium: 8 * settings.fontScale
        readonly property real paddingLarge: 12 * settings.fontScale
        readonly property real paddingXLarge: 16 * settings.fontScale

        readonly property real marginSmall: 8 * settings.fontScale
        readonly property real marginMedium: 12 * settings.fontScale
        readonly property real marginLarge: 16 * settings.fontScale
        readonly property real marginXLarge: 20 * settings.fontScale

        // Radios de borde (estos no se escalan con fuente)
        readonly property real radiusSmall: 4
        readonly property real radiusMedium: 8
        readonly property real radiusLarge: 12
        readonly property real radiusXLarge: 16

        // Función auxiliar para escalar valores personalizados
        function scaled(baseValue) {
            return baseValue * settings.fontScale
        }
    }

    // Tamaños de fuente escalados (legacy - mantener por compatibilidad)
    property real fontSizeXSmall: 8 * settings.fontScale
    property real fontSizeSmall: 10 * settings.fontScale
    property real fontSizeBody: 12 * settings.fontScale
    property real fontSizeBodyLarge: 14 * settings.fontScale
    property real fontSizeMedium: 16 * settings.fontScale
    property real fontSizeLarge: 18 * settings.fontScale
    property real fontSizeXLarge: 20 * settings.fontScale
    property real fontSizeXXLarge: 24 * settings.fontScale
    property real fontSizeHuge: 32 * settings.fontScale

    // Tamaños de iconos escalados (legacy - mantener por compatibilidad)
    property real iconSizeSmall: 14 * settings.fontScale
    property real iconSizeMedium: 16 * settings.fontScale
    property real iconSizeLarge: 20 * settings.fontScale
    property real iconSizeXLarge: 24 * settings.fontScale
    property real iconSizeXXLarge: 32 * settings.fontScale

    // Configuración de temas - Material 3
    Settings {
        id: settings
        property bool isDarkMode: false
        property int colorScheme: 0  // 0: Purple, 1: Blue, 2: Green, 3: Orange
        property real fontScale: 1.0
        property bool quickSaleMode: false  // Modo venta rápida
    }

    // Esquemas de color Material 3
    property var colorSchemes: [
        { // Purple (default)
            name: "Purple",
            light: {
                primary: "#7B1FA2",
                container: "#E1BEE7",
                surface: "#FAFAFA",
                onSurface: "#000000",
                surfaceVariant: "#D1C4E9",
                outline: "#8E24AA",
                error: "#D32F2F"
            },
            dark: {
                primary: "#D0BCFF",
                container: "#1F1729",
                surface: "#0D0A12",
                onSurface: "#FFFFFF",
                surfaceVariant: "#1A1422",
                outline: "#9575CD",
                error: "#FF6B6B"
            }
        },
        { // Blue
            name: "Blue",
            light: {
                primary: "#1976D2",
                container: "#BBDEFB",
                surface: "#FAFAFA",
                onSurface: "#000000",
                surfaceVariant: "#90CAF9",
                outline: "#1565C0",
                error: "#D32F2F"
            },
            dark: {
                primary: "#64B5F6",
                container: "#0A1929",
                surface: "#020814",
                onSurface: "#FFFFFF",
                surfaceVariant: "#0D1D2E",
                outline: "#42A5F5",
                error: "#FF6B6B"
            }
        },
        { // Green
            name: "Green",
            light: {
                primary: "#388E3C",
                container: "#C8E6C9",
                surface: "#FAFAFA",
                onSurface: "#000000",
                surfaceVariant: "#A5D6A7",
                outline: "#2E7D32",
                error: "#D32F2F"
            },
            dark: {
                primary: "#81C784",
                container: "#0D1F12",
                surface: "#050A07",
                onSurface: "#FFFFFF",
                surfaceVariant: "#0F1912",
                outline: "#66BB6A",
                error: "#FF6B6B"
            }
        },
        { // Orange
            name: "Orange",
            light: {
                primary: "#F57C00",
                container: "#FFE0B2",
                surface: "#FAFAFA",
                onSurface: "#000000",
                surfaceVariant: "#FFCC80",
                outline: "#EF6C00",
                error: "#D32F2F"
            },
            dark: {
                primary: "#FFB74D",
                container: "#2D1A0D",
                surface: "#0F0A05",
                onSurface: "#FFFFFF",
                surfaceVariant: "#1F140A",
                outline: "#FFA726",
                error: "#FF6B6B"
            }
        }
    ]

    property var currentColors: settings.isDarkMode
        ? colorSchemes[settings.colorScheme].dark
        : colorSchemes[settings.colorScheme].light

    // Tema Material 3 dinámico
    Material.theme: settings.isDarkMode ? Material.Dark : Material.Light
    Material.primary: currentColors.primary
    Material.accent: currentColors.primary
    Material.background: currentColors.surface
    Material.foreground: currentColors.onSurface

    // Escala de fuente global
    font.pixelSize: 14 * settings.fontScale

    // ─── Autenticación ────────────────────────────────────────────────────────
    Connections {
        target: authService

        function onLoginSucceeded() {
            notificationService.addNotification(
                "Bienvenido",
                "Has iniciado sesión como " + authService.currentUserRole,
                3  // Success
            )
            if (authService.canAccessDashboard) {
                stackView.replace("qml/pages/DashboardPage.qml")
            } else {
                stackView.replace("qml/pages/SalesPage.qml")
            }
        }

        function onLogoutCompleted() {
            // FIX: cerrar diálogos antes de destruir la página actual
            var currentPage = stackView.currentItem
            if (currentPage && typeof currentPage.closeAllDialogs === "function") {
                currentPage.closeAllDialogs()
            }
            notificationService.clearAll()
            stackView.replace("qml/pages/LoginPage.qml")
        }
    }

    // ─── Menú lateral ────────────────────────────────────────────────────────
    Drawer {
        id: drawer
        width: Math.min(250, root.width * 0.3)
        height: root.height
        modal: true

        onOpened: contentArea.layer.enabled = true
        onClosed: contentArea.layer.enabled = false

        Overlay.modal: Rectangle {
            color: settings.isDarkMode ?
                Qt.rgba(0, 0, 0, 0.5) :
                Qt.rgba(0.1, 0.1, 0.1, 0.4)
        }

        Item {
            anchors.fill: parent

            // Header del drawer
            Rectangle {
                id: drawerHeader
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 180
                color: currentColors.container
                z: 2

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 8

                    Image {
                        source: "qrc:/resources/logo.png"
                        Layout.preferredWidth: 64
                        Layout.preferredHeight: 64
                        fillMode: Image.PreserveAspectFit
                        visible: false
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

                    Item { Layout.preferredHeight: 12 }

                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: authService.isAuthenticated
                        spacing: 4

                        Label {
                            text: authService.currentUserFullName
                            font.pixelSize: 14
                            font.weight: Font.Medium
                            color: settings.isDarkMode ? "white" : Material.foreground
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Label {
                            text: authService.currentUserRole
                            font.pixelSize: 12
                            color: Material.accent
                            Layout.fillWidth: true
                        }
                    }
                }
            }

            // Separador superior
            Rectangle {
                id: topSeparator
                anchors.top: drawerHeader.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: Material.dividerColor
                visible: authService.isAuthenticated
                z: 2
            }

            // Botón cerrar sesión
            Rectangle {
                id: logoutSection
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 57
                color: Material.background
                z: 2

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Material.dividerColor
                        visible: authService.isAuthenticated
                    }

                    ItemDelegate {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: authService.isAuthenticated

                        background: Rectangle {
                            color: parent.hovered ? Qt.rgba(Material.color(Material.Red).r,
                                                             Material.color(Material.Red).g,
                                                             Material.color(Material.Red).b, 0.08) :
                                                    "transparent"
                            radius: 28
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 24
                            anchors.rightMargin: 24
                            spacing: 16

                            Label {
                                text: "\uE8BB"
                                font.family: "Segoe MDL2 Assets"
                                font.pixelSize: 20
                                color: Material.color(Material.Red)
                                Layout.preferredWidth: 24
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Label {
                                text: qsTr("Cerrar Sesión")
                                font.pixelSize: 14
                                color: Material.color(Material.Red)
                                Layout.fillWidth: true
                            }
                        }

                        onClicked: {
                            // FIX: cerrar diálogos antes de navegar
                            var currentPage = stackView.currentItem
                            if (currentPage && typeof currentPage.closeAllDialogs === "function") {
                                currentPage.closeAllDialogs()
                            }
                            authService.logout()
                            drawer.close()
                        }
                    }
                }
            }

            // Menú de navegación
            ListView {
                id: navigationList
                anchors.top: topSeparator.bottom
                anchors.bottom: logoutSection.top
                anchors.left: parent.left
                anchors.right: parent.right
                clip: true
                z: 1
                currentIndex: 0

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    active: true
                }

                model: ListModel {
                    id: navigationModel
                    ListElement { title: "Dashboard";      iconName: "dashboard";     page: "Dashboard";        requirePermission: "canAccessDashboard" }
                    ListElement { title: "Productos";      iconName: "inventory";     page: "Products";         requirePermission: "canAccessProducts" }
                    ListElement { title: "Ventas";         iconName: "shopping-cart"; page: "Sales";            requirePermission: "canAccessSales" }
                    ListElement { title: "Clientes";       iconName: "group";         page: "Customers";        requirePermission: "canAccessCustomers" }
                    ListElement { title: "Usuarios";       iconName: "contact";       page: "UsersManagement";  requirePermission: "canAccessSettings" }
                    ListElement { title: "Reportes";       iconName: "bar-chart";     page: "Reports";          requirePermission: "canAccessReports" }
                    ListElement { title: "Tickets";        iconName: "receipt";       page: "Tickets";          requirePermission: "canAccessSettings" }
                    ListElement { title: "Importar Excel"; iconName: "upload-file";   page: "Import";           requirePermission: "canAccessImport" }
                    ListElement { title: "Consola Debug";  iconName: "code";          page: "Console";          requirePermission: "canAccessConsole" }
                    ListElement { title: "Configuración";  iconName: "settings";      page: "Settings";         requirePermission: "canAccessSettings" }
                }

                delegate: ItemDelegate {
                    width: navigationList.width
                    height: visible ? 56 : 0

                    visible: authService.isAuthenticated && hasPermission(model.requirePermission)

                    function hasPermission(permission) {
                        if (!permission || permission === "") return true
                        return authService[permission] || false
                    }

                    background: Rectangle {
                        color: ListView.isCurrentItem ?
                               Qt.rgba(Material.primary.r, Material.primary.g, Material.primary.b, 0.12) :
                               "transparent"
                        radius: ListView.isCurrentItem ? 28 : 0
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        Behavior on color  { ColorAnimation  { duration: 200 } }
                        Behavior on radius { NumberAnimation { duration: 200 } }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 24
                        anchors.rightMargin: 24
                        spacing: 16

                        Label {
                            text: getIconChar(model.iconName)
                            font.family: "Segoe MDL2 Assets"
                            font.pixelSize: 20
                            color: ListView.isCurrentItem ? Material.primary : Material.foreground
                            Layout.preferredWidth: 24
                            horizontalAlignment: Text.AlignHCenter
                            Behavior on color { ColorAnimation { duration: 200 } }

                            function getIconChar(iconName) {
                                var icons = {
                                    "dashboard":    "\uE80F",
                                    "inventory":    "\uE7B8",
                                    "shopping-cart":"\uE7BF",
                                    "warehouse":    "\uE8F1",
                                    "assessment":   "\uE9D9",
                                    "group":        "\uE716",
                                    "bar-chart":    "\uE9D2",
                                    "receipt":      "\uE8A1",
                                    "upload-file":  "\uE898",
                                    "code":         "\uE943",
                                    "settings":     "\uE713"
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

                        // FIX: cerrar diálogos de la página actual antes de navegar
                        var currentPage = stackView.currentItem
                        if (currentPage && typeof currentPage.closeAllDialogs === "function") {
                            currentPage.closeAllDialogs()
                        }

                        var pagePath = "qml/pages/" + model.page + "Page.qml"
                        try {
                            stackView.replace(pagePath)
                        } catch (e) {
                            stackView.replace(underConstructionComponent)
                        }

                        drawer.close()
                    }
                }
            }  // Fin ListView
        }  // Fin Item
    }  // Fin Drawer

    // ─── Header principal ─────────────────────────────────────────────────────
    header: ToolBar {
        Material.elevation: 0
        Material.background: currentColors.container
        height: 64
        visible: authService.isAuthenticated

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

            // Botón de notificaciones
            RoundButton {
                flat: true
                implicitWidth: 48
                implicitHeight: 48
                visible: authService.isAuthenticated

                contentItem: Item {
                    Label {
                        anchors.centerIn: parent
                        text: "\uE7E7"
                        font.family: "Segoe MDL2 Assets"
                        font.pixelSize: 20
                        color: currentColors.onSurface
                    }

                    Badge {
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.topMargin: 8
                        anchors.rightMargin: 8
                        value: notificationService.unreadCount
                        visible: notificationService.unreadCount > 0
                    }
                }

                onClicked: notificationMenu.open()

                Menu {
                    id: notificationMenu
                    y: parent.height + 5
                    width: 350

                    Rectangle {
                        width: parent.width
                        height: 50
                        color: "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12

                            Label {
                                text: "Notificaciones"
                                font.pixelSize: 16
                                font.weight: Font.DemiBold
                                Layout.fillWidth: true
                            }

                            Button {
                                text: "Marcar todo leído"
                                flat: true
                                font.pixelSize: 11
                                visible: notificationService.unreadCount > 0
                                onClicked: notificationService.markAllAsRead()
                            }
                        }
                    }

                    MenuSeparator {}

                    Repeater {
                        model: notificationService.notifications

                        delegate: MenuItem {
                            width: parent.width
                            height: 70

                            background: Rectangle {
                                color: modelData.isRead ? "transparent" :
                                    (Material.theme === Material.Dark ?
                                        Qt.rgba(1, 1, 1, 0.05) :
                                        Qt.rgba(0, 0, 0, 0.03))

                                Rectangle {
                                    anchors.left: parent.left
                                    width: 4
                                    height: parent.height
                                    color: {
                                        switch(modelData.type) {
                                            case 0: return Material.color(Material.Blue)
                                            case 1: return Material.color(Material.Orange)
                                            case 2: return Material.color(Material.Red)
                                            case 3: return Material.color(Material.Green)
                                            default: return Material.color(Material.Grey)
                                        }
                                    }
                                }
                            }

                            contentItem: RowLayout {
                                spacing: 12
                                width: parent.width

                                Label {
                                    text: {
                                        switch(modelData.type) {
                                            case 0: return "\uE946"
                                            case 1: return "\uE7BA"
                                            case 2: return "\uE783"
                                            case 3: return "\uE73E"
                                            default: return "\uE946"
                                        }
                                    }
                                    font.family: "Segoe MDL2 Assets"
                                    font.pixelSize: 18
                                    color: {
                                        switch(modelData.type) {
                                            case 0: return Material.color(Material.Blue)
                                            case 1: return Material.color(Material.Orange)
                                            case 2: return Material.color(Material.Red)
                                            case 3: return Material.color(Material.Green)
                                            default: return Material.color(Material.Grey)
                                        }
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Label {
                                        text: modelData.title
                                        font.pixelSize: 13
                                        font.weight: modelData.isRead ? Font.Normal : Font.DemiBold
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }

                                    Label {
                                        text: modelData.message
                                        font.pixelSize: 11
                                        opacity: 0.7
                                        Layout.fillWidth: true
                                        wrapMode: Text.WordWrap
                                        maximumLineCount: 2
                                    }

                                    Label {
                                        text: Qt.formatDateTime(modelData.timestamp, "hh:mm - dd/MM/yyyy")
                                        font.pixelSize: 10
                                        opacity: 0.5
                                    }
                                }

                                Button {
                                    text: "\uE74D"
                                    font.family: "Segoe MDL2 Assets"
                                    flat: true
                                    implicitWidth: 30
                                    implicitHeight: 30
                                    onClicked: notificationService.removeNotification(modelData.id)
                                }
                            }

                            onClicked: {
                                if (!modelData.isRead) {
                                    notificationService.markAsRead(modelData.id)
                                }
                            }
                        }
                    }

                    MenuItem {
                        visible: notificationService.notifications.length === 0
                        enabled: false
                        height: 80

                        contentItem: ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 8

                            Label {
                                text: "\uE7E7"
                                font.family: "Segoe MDL2 Assets"
                                font.pixelSize: 32
                                opacity: 0.3
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Label {
                                text: "No hay notificaciones"
                                font.pixelSize: 12
                                opacity: 0.5
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }

                    MenuSeparator {
                        visible: notificationService.notifications.length > 0
                    }

                    MenuItem {
                        text: "Limpiar todas"
                        visible: notificationService.notifications.length > 0
                        onClicked: notificationService.clearAll()
                    }
                }
            }

            // Botón de usuario
            RoundButton {
                flat: true
                implicitWidth: 48
                implicitHeight: 48
                visible: authService.isAuthenticated

                contentItem: Label {
                    text: "\uE77B"
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
                    width: 240

                    Rectangle {
                        width: parent.width
                        height: 80
                        color: Material.background

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 2

                            Label {
                                text: authService.currentUserFullName
                                font.pixelSize: 15
                                font.weight: Font.DemiBold
                                color: Material.foreground
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Label {
                                text: authService.currentUserRole
                                font.pixelSize: 12
                                color: Material.accent
                                font.weight: Font.Medium
                            }

                            Label {
                                text: "@" + authService.currentUsername
                                font.pixelSize: 11
                                opacity: 0.7
                            }
                        }
                    }

                    MenuSeparator { }

                    // Mi Perfil
                    MenuItem {
                        text: "Mi Perfil"
                        icon.source: "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'%3E%3Ctext x='2' y='18' font-family='Segoe MDL2 Assets' font-size='16'%3E%EF%9D%BB%3C/text%3E%3C/svg%3E"
                        onTriggered: {
                            // FIX: cerrar diálogos antes de navegar
                            var currentPage = stackView.currentItem
                            if (currentPage && typeof currentPage.closeAllDialogs === "function") {
                                currentPage.closeAllDialogs()
                            }
                            stackView.replace("qml/pages/UserProfilePage.qml")
                            userMenu.close()
                        }
                    }

                    // Gestión de Usuarios (solo Admin)
                    MenuItem {
                        text: "Gestión de Usuarios"
                        visible: authService.currentUserRole === "Admin"
                        height: visible ? implicitHeight : 0
                        icon.source: "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'%3E%3Ctext x='2' y='18' font-family='Segoe MDL2 Assets' font-size='16'%3E%EF%9C%96%3C/text%3E%3C/svg%3E"
                        onTriggered: {
                            // FIX: cerrar diálogos antes de navegar
                            var currentPage = stackView.currentItem
                            if (currentPage && typeof currentPage.closeAllDialogs === "function") {
                                currentPage.closeAllDialogs()
                            }
                            stackView.replace("qml/pages/UsersManagementPage.qml")
                            userMenu.close()
                        }
                    }

                    // Configuración
                    MenuItem {
                        text: "Configuración"
                        visible: authService.canAccessSettings
                        height: visible ? implicitHeight : 0
                        icon.source: "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'%3E%3Ctext x='2' y='18' font-family='Segoe MDL2 Assets' font-size='16'%3E%EF%9C%93%3C/text%3E%3C/svg%3E"
                        onTriggered: {
                            // FIX: cerrar diálogos antes de navegar
                            var currentPage = stackView.currentItem
                            if (currentPage && typeof currentPage.closeAllDialogs === "function") {
                                currentPage.closeAllDialogs()
                            }
                            stackView.replace("qml/pages/SettingsPage.qml")
                            userMenu.close()
                        }
                    }

                    // Cambiar Contraseña
                    MenuItem {
                        text: "Cambiar Contraseña"
                        icon.source: "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'%3E%3Ctext x='2' y='18' font-family='Segoe MDL2 Assets' font-size='16'%3E%EF%A2%AC%3C/text%3E%3C/svg%3E"
                        onTriggered: {
                            changePasswordDialog.open()
                            userMenu.close()
                        }
                    }

                    MenuSeparator { }

                    // Cerrar Sesión
                    MenuItem {
                        text: "Cerrar Sesión"
                        icon.source: "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'%3E%3Ctext x='2' y='18' font-family='Segoe MDL2 Assets' font-size='16' fill='%23d32f2f'%3E%EF%A2%BB%3C/text%3E%3C/svg%3E"

                        contentItem: Label {
                            text: parent.text
                            font: parent.font
                            color: Material.color(Material.Red)
                            horizontalAlignment: Text.AlignLeft
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: parent.icon.width + parent.spacing
                        }

                        onTriggered: {
                            // FIX: cerrar diálogos antes de navegar
                            var currentPage = stackView.currentItem
                            if (currentPage && typeof currentPage.closeAllDialogs === "function") {
                                currentPage.closeAllDialogs()
                            }
                            authService.logout()
                            userMenu.close()
                        }
                    }
                }
            }
        }
    }

    // ─── Contenido principal ──────────────────────────────────────────────────
    Item {
        id: contentArea
        anchors.fill: parent

        layer.enabled: false
        layer.effect: MultiEffect {
            blur: 1.0
            blurMax: 48
            blurMultiplier: 1.0
        }

        StackView {
            id: stackView
            anchors.fill: parent

            initialItem: authService.isAuthenticated ?
                         getDashboardOrSalesPage() :
                         "qml/pages/LoginPage.qml"

            function getDashboardOrSalesPage() {
                if (authService.canAccessDashboard) {
                    return "qml/pages/DashboardPage.qml"
                } else {
                    return "qml/pages/SalesPage.qml"
                }
            }
        }

        // Conexión para capturar código de barras desde ProductsPage
        Connections {
            target: stackView.currentItem
            ignoreUnknownSignals: true

            function onBarcodeScannedForCart(barcode) {
                var capturedBarcode = barcode  // capturar antes del replace

                stackView.replace("qml/pages/SalesPage.qml")

                // Esperar a que la página esté completamente cargada
                stackView.currentItemChanged.connect(function() {
                    var page = stackView.currentItem
                    if (page && page.viewModel && capturedBarcode !== "") {
                        page.viewModel.searchAndAddProduct(capturedBarcode, 1)
                        capturedBarcode = ""  // evitar doble ejecución
                    }
                })
            }
        }
    }

    // ─── Badge component ──────────────────────────────────────────────────────
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

    // REEMPLAZA los dos bloques Connections dinámicos por esto:

    // Propiedad para trackear el viewModel actual de forma segura
    property var activeSalesViewModel: null
    property var activePrintViewModel: null

    // Observar cambios en currentItem de forma segura
    Connections {
        target: stackView

        function onCurrentItemChanged() {
            var page = stackView.currentItem
            console.log("*** StackView: página cambió a:", page)

            // Desconectar viewModels anteriores de forma segura
            root.activeSalesViewModel = null
            root.activePrintViewModel = null

            // Conectar nuevos viewModels con delay para asegurar que la página está lista
            if (page && page.viewModel) {
                root.activeSalesViewModel = page.viewModel
            }
            if (page && page.printViewModel) {
                root.activePrintViewModel = page.printViewModel
            }
        }
    }

    // Connections estático apuntando a la propiedad (no al item directamente)
    Connections {
        target: root.activeSalesViewModel
        ignoreUnknownSignals: true

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

    Connections {
        target: root.activePrintViewModel
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



    // ─── Página en construcción ───────────────────────────────────────────────
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

    // ─── Notificaciones globales ──────────────────────────────────────────────
    NotificationBar {
        id: globalNotification
    }

    // ─── Diálogo de cambio de contraseña ─────────────────────────────────────
    Dialog {
        id: changePasswordDialog
        title: "Cambiar Contraseña"
        width: 400
        modal: true
        standardButtons: Dialog.Ok | Dialog.Cancel
        anchors.centerIn: Overlay.overlay  // FIX: usar overlay global

        property string errorMessage: ""

        ColumnLayout {
            width: parent.width
            spacing: 16

            Label {
                text: "Ingrese su contraseña actual y la nueva contraseña"
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                font.pixelSize: 13
                opacity: 0.7
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Label {
                    text: "Contraseña Actual"
                    font.pixelSize: 12
                    font.weight: Font.Medium
                }

                TextField {
                    id: currentPasswordField
                    Layout.fillWidth: true
                    echoMode: TextInput.Password
                    placeholderText: "Ingrese contraseña actual"
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Label {
                    text: "Nueva Contraseña"
                    font.pixelSize: 12
                    font.weight: Font.Medium
                }

                TextField {
                    id: newPasswordField
                    Layout.fillWidth: true
                    echoMode: TextInput.Password
                    placeholderText: "Ingrese nueva contraseña"
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Label {
                    text: "Confirmar Nueva Contraseña"
                    font.pixelSize: 12
                    font.weight: Font.Medium
                }

                TextField {
                    id: confirmPasswordField
                    Layout.fillWidth: true
                    echoMode: TextInput.Password
                    placeholderText: "Confirme nueva contraseña"
                }
            }

            Label {
                text: changePasswordDialog.errorMessage
                color: Material.color(Material.Red)
                visible: changePasswordDialog.errorMessage !== ""
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                font.pixelSize: 12
            }
        }

        onAccepted: {
            errorMessage = ""

            if (currentPasswordField.text === "") {
                errorMessage = "Debe ingresar la contraseña actual"
                open()
                return
            }

            if (newPasswordField.text === "") {
                errorMessage = "Debe ingresar la nueva contraseña"
                open()
                return
            }

            if (newPasswordField.text.length < 6) {
                errorMessage = "La nueva contraseña debe tener al menos 6 caracteres"
                open()
                return
            }

            if (newPasswordField.text !== confirmPasswordField.text) {
                errorMessage = "Las contraseñas no coinciden"
                open()
                return
            }

            if (authService.changePassword(currentPasswordField.text, newPasswordField.text)) {
                globalNotification.show("Contraseña cambiada exitosamente", "success")
                currentPasswordField.text = ""
                newPasswordField.text = ""
                confirmPasswordField.text = ""
            } else {
                errorMessage = "Contraseña actual incorrecta"
                open()
            }
        }

        onRejected: {
            errorMessage = ""
            currentPasswordField.text = ""
            newPasswordField.text = ""
            confirmPasswordField.text = ""
        }
    }

}  // Fin ApplicationWindow
