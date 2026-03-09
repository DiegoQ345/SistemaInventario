import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

Dialog {
    id: root
    title: qsTr("Guardar Diseño")
    modal: true
    anchors.centerIn: parent
    width: 400

    required property var viewModel

    onOpened: designNameField.forceActiveFocus()

    contentItem: ColumnLayout {
        spacing: 16

        Label {
            text: qsTr("Ingrese un nombre para el diseño:")
            Layout.fillWidth: true
        }

        TextField {
            id: designNameField
            Layout.fillWidth: true
            placeholderText: qsTr("Ej: Diseño predeterminado")

            Keys.onReturnPressed: {
                if (text.trim() !== "") {
                    root.accept()
                }
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: 8

            Button {
                text: qsTr("Cancelar")
                onClicked: root.reject()
            }

            Button {
                text: qsTr("Guardar")
                highlighted: true
                enabled: designNameField.text.trim() !== ""
                onClicked: root.accept()
            }
        }
    }

    onAccepted: {
        root.viewModel.saveDesign(designNameField.text.trim())
        designNameField.text = ""
    }

    onRejected: {
        designNameField.text = ""
    }
}
