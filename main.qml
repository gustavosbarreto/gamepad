import QtQuick 2.11
import QtGraphicalEffects 1.0
import QtQuick.Controls 1.3
import "./qml-flappy-bird" as FlappyBird

Item {
    id: merda

    focus: true

    StackView {
        id: stack
        initialItem: main
        anchors.fill: parent

        Component.onCompleted: menu.focus = true
    }

    Keys.onRightPressed: menu.incrementCurrentIndex()
    Keys.onLeftPressed: menu.decrementCurrentIndex()

    Keys.onReturnPressed: {
        stack.push(game);
    }

    Component {
        id: game

        Item {
            focus: true

            FlappyBird.Game {
                height: 480

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter

                Keys.onReturnPressed: {}
                Keys.onEscapePressed: stack.pop()
            }
        }
    }

    Item {
        id: main

        Image {
            id: bg

            source: "/home/gustavo/gamepad/background2.jpg"
            anchors.fill: parent
            sourceSize: Qt.size(parent.width, parent.height)
            visible: false
        }

        FastBlur {
            anchors.fill: bg
            source: bg
            radius: 50
        }

        Component {
            id: delegate

            Column {
                id: wrapper


                Image {
                    id: icon
                    //anchors.horizontalCenter: nameText.horizontalCenter
                    width: 128; height: 128
                    smooth: true
                    source: model.icon
                    mipmap: true

                    //opacity: wrapper.PathView.isCurrentItem ? 1 : 0.4

                    ColorOverlay {
                        anchors.fill: icon
                        source: icon
                        color: wrapper.PathView.isCurrentItem ? "#fff" : "#0C5E9C"
                        // 0C5E9C
                    }
                }

                /*Text {
                id: nameText
                text: name
                font.pointSize: 16
                color: wrapper.PathView.isCurrentItem ? "#fff" : "#777"
            }*/
            }
        }

        ListModel {
            id: model

            ListElement {
                name: "Jogar"
                icon: "/home/gustavo/gamepad/game.png"
            }
            ListElement {
                name: "Configurações"
                icon: "/home/gustavo/gamepad/config.png"
            }
            ListElement {
                name: "Sobre"
                icon: "/home/gustavo/gamepad/about.png"
            }

        }

        Item {
            width: 400
            height: 400
            anchors.centerIn: parent

            PathView {
                id: menu

                anchors.fill: parent
                anchors.leftMargin: -60
                anchors.topMargin:  0
                width: 0
                height: 0
                model: model
                delegate: delegate
                path: Path {
                    startX: 120 * 2; startY: 180*2
                    PathQuad { x: 120*2; y: 25*2; controlX: 260*2; controlY: 75*2 }
                    PathQuad { x: 120*2; y: 180*2; controlX: -20*2; controlY: 75*2 }
                }
            }
        }
    }
}
