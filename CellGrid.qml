import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    id: root

    // modelData - это одномерный массив из 100 элементов (0..99)
    // 0 = пусто, 1 = корабль, 2 = мимо, 3 = попал по кораблю
    property var gridData: []

    property bool interactive: false

    signal cellClicked(int x, int y)

    GridLayout {
        anchors.fill: parent
        columns: 10
        rows: 10
        columnSpacing: 1
        rowSpacing: 1

        Repeater {
            model: 100

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true

                color: {
                    let val = root.gridData[index]
                    if (val === 0) return "#2196F3"
                    if (val === 1) return "#607D8B"
                    if (val === 2) return "#B3E5FC"
                    if (val === 3) return "#F44336"
                    return "white"
                }

                border.color: "white"
                border.width: 1

                MouseArea {
                    anchors.fill: parent
                    enabled: root.interactive
                    onClicked: {
                        let x = index % 10
                        let y = Math.floor(index / 10)
                        root.cellClicked(x, y)
                    }
                }
            }
        }
    }
}
