import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import SistemaInventario 1.0

Page {
    id: root
    title: qsTr("Clientes")

    // ViewModels
    CustomerListModel {
        id: customerListModel
    }

    CustomerFormViewModel {
        id: customerFormViewModel

        onSaved: {
            customerListModel.refresh()
            customerDialog.close()
            globalNotification.show("Cliente guardado exitosamente", "success")
        }

        onErrorOccurred: function(message) {
            globalNotification.show(message, "error")
        }
    }

    // NotificationBar global (debe estar en Main.qml pero usamos una local)
    NotificationBar {
        id: globalNotification
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        // Encabezado
        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Label {
                    text: qsTr("Gestión de Clientes")
                    font.pixelSize: 32
                    font.weight: Font.Bold
                }

                Label {
                    text: qsTr("Total: %1 clientes").arg(customerListModel.count)
                    font.pixelSize: 16
                    opacity: 0.7
                }
            }

            Button {
                text: qsTr("➕ Nuevo Cliente")
                font.pixelSize: 16
                font.weight: Font.Medium
                Material.background: Material.primary
                Material.foreground: Material.theme === Material.Dark ? "#000000" : "#FFFFFF"
                leftPadding: 24
                rightPadding: 24
                topPadding: 12
                bottomPadding: 12

                onClicked: {
                    customerFormViewModel.clear()
                    customerDialog.open()
                }
            }
        }

        // Barra de búsqueda
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            TextField {
                id: searchField
                Layout.fillWidth: true
                placeholderText: qsTr("🔍 Buscar por nombre, documento, email o teléfono...")
                font.pixelSize: 14

                onTextChanged: {
                    searchTimer.restart()
                }

                Timer {
                    id: searchTimer
                    interval: 300
                    onTriggered: {
                        customerListModel.search(searchField.text)
                    }
                }
            }

            Button {
                text: qsTr("Limpiar")
                visible: searchField.text.length > 0
                onClicked: {
                    searchField.text = ""
                    customerListModel.refresh()
                }
            }
        }

        // Tabla de clientes
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Material.background
            border.color: Material.dividerColor
            border.width: 1
            radius: 8

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 1
                spacing: 0

                // Encabezado de tabla
                Rectangle {
                    Layout.fillWidth: true
                    height: 48
                    color: Material.dialogColor
                    radius: 8

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        spacing: 8

                        Label {
                            Layout.preferredWidth: 200
                            text: qsTr("Nombre")
                            font.weight: Font.Medium
                            font.pixelSize: 13
                        }

                        Label {
                            Layout.preferredWidth: 100
                            text: qsTr("Documento")
                            font.weight: Font.Medium
                            font.pixelSize: 13
                        }

                        Label {
                            Layout.preferredWidth: 120
                            text: qsTr("Nro. Documento")
                            font.weight: Font.Medium
                            font.pixelSize: 13
                        }

                        Label {
                            Layout.fillWidth: true
                            text: qsTr("Email")
                            font.weight: Font.Medium
                            font.pixelSize: 13
                        }

                        Label {
                            Layout.preferredWidth: 100
                            text: qsTr("Teléfono")
                            font.weight: Font.Medium
                            font.pixelSize: 13
                        }

                        Label {
                            Layout.preferredWidth: 150
                            text: qsTr("Acciones")
                            font.weight: Font.Medium
                            font.pixelSize: 13
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }

                // Lista de clientes
                ListView {
                    id: customerListView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: customerListModel

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                    }

                    delegate: ItemDelegate {
                        width: customerListView.width
                        height: 64

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            spacing: 8

                            // Nombre
                            Label {
                                Layout.preferredWidth: 200
                                text: model.customerName
                                font.pixelSize: 14
                                elide: Text.ElideRight
                                font.weight: Font.Medium
                            }

                            // Tipo de documento
                            Label {
                                Layout.preferredWidth: 100
                                text: model.documentType || "-"
                                font.pixelSize: 13
                                opacity: 0.7
                            }

                            // Número de documento
                            Label {
                                Layout.preferredWidth: 120
                                text: model.documentNumber || "-"
                                font.pixelSize: 13
                                font.family: "monospace"
                            }

                            // Email
                            Label {
                                Layout.fillWidth: true
                                text: model.email || "-"
                                font.pixelSize: 13
                                opacity: 0.7
                                elide: Text.ElideRight
                            }

                            // Teléfono
                            Label {
                                Layout.preferredWidth: 100
                                text: model.phone || "-"
                                font.pixelSize: 13
                                font.family: "monospace"
                            }

                            // Acciones
                            RowLayout {
                                Layout.preferredWidth: 150
                                spacing: 8

                                Button {
                                    text: "✏️"
                                    font.pixelSize: 16
                                    flat: true
                                    ToolTip.visible: hovered
                                    ToolTip.text: "Editar"

                                    onClicked: {
                                        customerFormViewModel.loadCustomer(model.customerId)
                                        customerDialog.open()
                                    }
                                }

                                Button {
                                    text: "🗑️"
                                    font.pixelSize: 16
                                    flat: true
                                    Material.foreground: Material.color(Material.Red)
                                    ToolTip.visible: hovered
                                    ToolTip.text: "Eliminar"

                                    onClicked: {
                                        deleteDialog.customerId = model.customerId
                                        deleteDialog.customerName = model.customerName
                                        deleteDialog.open()
                                    }
                                }
                            }
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: 1
                            color: Material.dividerColor
                        }
                    }

                    // Estado vacío
                    Label {
                        anchors.centerIn: parent
                        visible: customerListModel.count === 0
                        text: searchField.text.length > 0 
                            ? qsTr("No se encontraron clientes con '%1'").arg(searchField.text)
                            : qsTr("No hay clientes registrados\nHaz clic en 'Nuevo Cliente' para agregar uno")
                        font.pixelSize: 16
                        opacity: 0.5
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }
    }

    // Diálogo de formulario de cliente
    Dialog {
        id: customerDialog
        title: customerFormViewModel.isEditMode ? qsTr("Editar Cliente") : qsTr("Nuevo Cliente")
        width: Math.min(600, root.width * 0.9)
        height: Math.min(550, root.height * 0.9)
        modal: true
        anchors.centerIn: parent
        standardButtons: Dialog.Save | Dialog.Cancel

        onAccepted: {
            if (customerFormViewModel.save()) {
                // El evento onSaved se encarga del cierre
            }
        }

        onRejected: {
            customerFormViewModel.clear()
        }

        ScrollView {
            anchors.fill: parent
            contentWidth: availableWidth

            ColumnLayout {
                width: parent.width
                spacing: 16

                // Nombre (obligatorio)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Label {
                        text: qsTr("Nombre *")
                        font.weight: Font.Medium
                    }

                    TextField {
                        Layout.fillWidth: true
                        placeholderText: qsTr("Nombre completo o razón social")
                        text: customerFormViewModel.name
                        onTextChanged: customerFormViewModel.name = text
                    }
                }

                // Tipo de documento
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Label {
                        text: qsTr("Tipo de Documento")
                        font.weight: Font.Medium
                    }

                    ComboBox {
                        Layout.fillWidth: true
                        model: ["DNI", "RUC", "CE", "Pasaporte", "Otro"]
                        currentIndex: {
                            var type = customerFormViewModel.documentType
                            var idx = model.indexOf(type)
                            return idx >= 0 ? idx : 0
                        }
                        onActivated: {
                            customerFormViewModel.documentType = currentText
                        }
                    }
                }

                // Número de documento
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Label {
                        text: qsTr("Número de Documento")
                        font.weight: Font.Medium
                    }

                    TextField {
                        Layout.fillWidth: true
                        placeholderText: qsTr("Ingrese número de documento")
                        text: customerFormViewModel.documentNumber
                        onTextChanged: customerFormViewModel.documentNumber = text
                        inputMethodHints: Qt.ImhDigitsOnly
                    }
                }

                // Email
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Label {
                        text: qsTr("Email")
                        font.weight: Font.Medium
                    }

                    TextField {
                        Layout.fillWidth: true
                        placeholderText: qsTr("correo@ejemplo.com")
                        text: customerFormViewModel.email
                        onTextChanged: customerFormViewModel.email = text
                        inputMethodHints: Qt.ImhEmailCharactersOnly
                    }
                }

                // Teléfono
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Label {
                        text: qsTr("Teléfono")
                        font.weight: Font.Medium
                    }

                    TextField {
                        Layout.fillWidth: true
                        placeholderText: qsTr("+51 999 999 999")
                        text: customerFormViewModel.phone
                        onTextChanged: customerFormViewModel.phone = text
                        inputMethodHints: Qt.ImhDialableCharactersOnly
                    }
                }

                // Dirección
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Label {
                        text: qsTr("Dirección")
                        font.weight: Font.Medium
                    }

                    TextArea {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 80
                        placeholderText: qsTr("Dirección completa")
                        text: customerFormViewModel.address
                        onTextChanged: customerFormViewModel.address = text
                        wrapMode: TextArea.Wrap
                    }
                }

                Item {
                    Layout.fillHeight: true
                }
            }
        }
    }

    // Diálogo de confirmación de eliminación
    Dialog {
        id: deleteDialog
        title: qsTr("Confirmar eliminación")
        modal: true
        anchors.centerIn: parent
        standardButtons: Dialog.Yes | Dialog.No

        property int customerId: 0
        property string customerName: ""

        Label {
            text: qsTr("¿Está seguro que desea eliminar al cliente '%1'?\n\nEsta acción no se puede deshacer.").arg(deleteDialog.customerName)
            wrapMode: Text.WordWrap
        }

        onAccepted: {
            if (customerListModel.remove(deleteDialog.customerId)) {
                globalNotification.show("Cliente eliminado exitosamente", "success")
            } else {
                globalNotification.show("Error al eliminar cliente", "error")
            }
        }
    }
}
