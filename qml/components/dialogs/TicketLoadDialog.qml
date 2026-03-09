import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

Dialog {
    id: root
    title: qsTr("Cargar Diseño")
    modal: true
    anchors.centerIn: parent
    width: 450
    height: 500

    required property var viewModel

    onOpened: root.viewModel.refreshTemplates()

    contentItem: ColumnLayout {
        spacing: 16

        Label {
            text: qsTr("Selecciona un diseño guardado:")
            Layout.fillWidth: true
            font.bold: true
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            visible: root.viewModel.savedTemplates.length > 0

            ColumnLayout {
                width: parent.width
                spacing: 8

                Repeater {
                    model: root.viewModel.savedTemplates

                    ItemDelegate {
                        Layout.fillWidth: true

                        contentItem: RowLayout {
                            spacing: 12

                            Rectangle {
                                width: 40
                                height: 40
                                color: modelData.isActive ? Material.accent : Material.frameColor
                                radius: 4

                                Label {
                                    anchors.centerIn: parent
                                    text: "\uE8A1"
                                    font.family: "Segoe MDL2 Assets"
                                    font.pixelSize: 24
                                    color: modelData.isActive ? 
                                           (Material.theme === Material.Dark ? "white" : "white") : 
                                           Material.foreground
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                Label {
                                    text: modelData.name
                                    font.bold: true
                                    Layout.fillWidth: true
                                }

                                Label {
                                    text: modelData.isActive ? "✓ Activo" : "Guardado: " + modelData.createdAt
                                    font.pixelSize: 10
                                    color: modelData.isActive ? Material.accent : Material.hintTextColor
                                }
                            }

                            Button {
                                text: qsTr("Cargar")
                                onClicked: {
                                    root.viewModel.loadDesign(modelData.id)
                                    root.close()
                                }
                            }

                            Button {
                                text: modelData.isActive ? qsTr("Activo") : qsTr("Activar")
                                flat: true
                                enabled: !modelData.isActive
                                onClicked: {
                                    root.viewModel.setActiveTemplate(modelData.id)
                                    root.close()
                                }
                            }
                        }
                    }
                }
            }
        }

        // Mensaje cuando no hay diseños guardados
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignCenter
            spacing: 16
            visible: root.viewModel.savedTemplates.length === 0

            Label {
                text: "\uE8A1"
                font.family: "Segoe MDL2 Assets"
                font.pixelSize: 64
                color: Material.hintTextColor
                Layout.alignment: Qt.AlignHCenter
            }

            Label {
                text: qsTr("No hay diseños guardados")
                font.pixelSize: 16
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }

            Label {
                text: qsTr("Crea y guarda tu primer diseño de ticket")
                font.pixelSize: 12
                color: Material.hintTextColor
                Layout.alignment: Qt.AlignHCenter
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignRight

            Button {
                text: qsTr("Cerrar")
                onClicked: root.close()
            }
        }
    }
}
