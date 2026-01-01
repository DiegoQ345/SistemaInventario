import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material

Item {
    id: root

    property string iconText: "ℹ️"
    property string helpText: ""
    property int iconSize: 16

    width: iconSize + 4
    height: iconSize + 4

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: Material.color(Material.Blue, Material.Shade100)
        border.width: 1
        border.color: Material.color(Material.Blue, Material.Shade300)

        Label {
            anchors.centerIn: parent
            text: root.iconText
            font.pixelSize: root.iconSize - 4
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
        }

        ToolTip {
            visible: mouseArea.containsMouse
            text: root.helpText
            delay: 200
            timeout: 5000
        }
    }
}
