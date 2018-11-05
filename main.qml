import QtQuick 2.7
import QtGraphicalEffects 1.0
import QtQuick.Controls 1.3
import QtQuick.Window 2.2
import updatehub.Agent 1.0 as UpdateHub

import "./qml-flappy-bird" as FlappyBird

Window {
    visibility: Window.FullScreen
    visible: true

    property string currentState: ""

    UpdateHub.Agent {
        id: updatehub
    }

    UpdateHub.StateChangeListener {
        Component.onCompleted: listen()

        onStateChanged: {
            switch (state.id) {
            case UpdateHub.AgentState.Downloading:
                currentState = "Downloading";
                break;
            case UpdateHub.AgentState.Installing:
                currentState = "Installing";
                break;
            case UpdateHub.AgentState.Rebooting:
                currentState = "Rebooting";
            }
        }
    }

    Item {
        focus: true

        anchors.fill: parent

        Image {
            id: bg

            source: "background.jpg"
            anchors.fill: parent
            sourceSize: Qt.size(parent.width, parent.height)
            visible: false
        }

        FastBlur {
            anchors.fill: bg
            source: bg
            radius: 50
        }

        StackView {
            id: stack
            initialItem: main
            anchors.fill: parent

            Component.onCompleted: menu.focus = true
        }

        Keys.onRightPressed: menu.incrementCurrentIndex()
        Keys.onLeftPressed: menu.decrementCurrentIndex()

        Keys.onReturnPressed: {
            switch (model.get(menu.currentIndex).type) {
            case "game":
                stack.push(game);
                break;
            case "about":
                stack.push(about);
                break;
            case "upgrade":
                stack.push(upgrade);
            }
        }

        Keys.onEscapePressed: stack.pop()

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

            Component {
                id: about

                Item {
                    width: 200
                    height: 200

                    Column {
                        anchors.centerIn: parent
                        spacing: 20

                        Text {
                            font.pixelSize: 28
                            color: "#fff"
                            anchors.horizontalCenter: parent.horizontalCenter

                            text: "Gamepad"
                        }

                        Rectangle {
                            border.width: 1
                            height: 2
                            width: parent.width
                            border.color: "#0C5E9C"
                        }

                        Text {
                            font.pixelSize: 20
                            color: "#fff"
                            anchors.horizontalCenter: parent.horizontalCenter

                            text: "Current version:"

                            Component.onCompleted: {
                                var info = updatehub.info();
                                if (typeof info != "undefined") {
                                    text = "Current version: " + info.version;
                                }
                            }
                        }
                    }
                }
            }

            Component {
                id: upgrade

                Item {
                    width: 200
                    height: 200


                    Column {
                        anchors.centerIn: parent
                        spacing: 20

                        Image {
                            source: "logo.png"
                        }

                        Text {
                            font.pixelSize: 24
                            color: "#fff"
                            anchors.horizontalCenter: parent.horizontalCenter

                            text: "Checking for updates..."

                            Component.onCompleted: {
                                var probe = updatehub.probe();

                                if (typeof probe != "undefined") {
                                    if (probe["update-available"]) {
                                        text = "Update available!";
                                    } else {
                                        text = "No update available!";
                                        busy.running = false;
                                    }
                                }
                            }
                        }

                        Text {
                            font.pixelSize: 18
                            color: "#fff"
                            anchors.horizontalCenter: parent.horizontalCenter

                            text: currentState
                        }

                        BusyIndicator {
                            id: busy
                            anchors.horizontalCenter: parent.horizontalCenter
                            running: true
                        }
                    }
                }
            }

            Component {
                id: delegate

                Column {
                    id: wrapper

                    spacing: 8

                    Image {
                        id: icon

                        width: 128; height: 128
                        smooth: true
                        source: model.icon
                        mipmap: true

                        ColorOverlay {
                            anchors.fill: icon
                            source: icon
                            color: wrapper.PathView.isCurrentItem ? "#fff" : "#0C5E9C"
                        }
                    }

                    Text {
                        text: model.name
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.pixelSize: 16
                        color: wrapper.PathView.isCurrentItem ? "#fff" : "#0C5E9C"
                    }
                }
            }

            ListModel {
                id: model

                ListElement {
                    name: "Play"
                    icon: "game.png"
                    type: "game"
                }
                ListElement {
                    name: "Upgrade"
                    icon: "upgrade.png"
                    type: "upgrade"
                }
                ListElement {
                    name: "About"
                    icon: "about.png"
                    type: "about"
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
                    anchors.topMargin:  -60
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
}
