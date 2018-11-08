import QtQuick 2.7
import QtGraphicalEffects 1.0
import QtQuick.Controls 1.3
import QtQuick.Window 2.2
import updatehub.Agent 1.0 as UpdateHub
import OSSystems.Utils 1.0 as Utils

import "./../qml-flappy-bird" as FlappyBird

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
            switch (state.id()) {
            case UpdateHub.AgentState.Downloading:
                currentState = "Downloading";
                break;
            case UpdateHub.AgentState.Installing:
                currentState = "Installing";
                break;
            case UpdateHub.AgentState.Rebooting:
                currentState = "Rebooting";
            }

            state.done();
        }
    }

    Utils.Process {
        id: process
    }

    Rectangle {
        focus: true
        color: "black"

        anchors.fill: parent

        Image {
            id: bg

            source: "background.jpg"
            anchors.fill: parent
            sourceSize: Qt.size(parent.width, parent.height)
            visible: false
        }

        FastBlur {
            id: bgblur
            anchors.fill: bg
            source: bg
            radius: 20
            opacity: 0

            Component.onCompleted: bgblur.opacity = 1

            Behavior on opacity {
                NumberAnimation {
                    property: "opacity"
                    duration: 1000
                }
            }

            onOpacityChanged: {
                if (opacity == 1) {
                    stack.opacity = 1;
                }
            }
        }

        StackView {
            id: stack
            initialItem: main
            anchors.fill: parent
            opacity: 0

            Behavior on opacity {
                NumberAnimation {
                    property: "opacity"
                    duration: 1000
                }
            }

            onOpacityChanged: {
                if (opacity == 0) {
                    process.start("poweroff");
                }
            }

            Component.onCompleted: menu.focus = true;
        }

        Keys.onRightPressed: if (!poweroff.active) menu.incrementCurrentIndex()
        Keys.onLeftPressed: if (!poweroff.active) menu.decrementCurrentIndex()
        Keys.onDownPressed: poweroff.active = true
        Keys.onUpPressed: poweroff.active = false

        Keys.onReturnPressed: {
            if (poweroff.active) {
                bgblur.opacity = 0;
                stack.opacity = 0;
                return;
            }

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
                                    text = "Current version: " + info.firmware.version;
                                }
                            }
                        }

                        Text {
                            font.pixelSize: 20
                            color: "#fff"
                            anchors.horizontalCenter: parent.horizontalCenter

                            text: "IP Address:"

                            Utils.Process {
                                id: nmcli
                            }

                            Component.onCompleted: {
                                nmcli.start("nmcli", "-g IP4.ADDRESS device show wlan0".split(" "));
                                nmcli.waitForFinished(-1);

                                text = "IP Address: " + nmcli.readAllStandardOutput().split("/")[0];
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

                            Timer {
                                id: timer

                                running: false

                                onTriggered: {
                                    var probe = updatehub.probe();

                                    if (typeof probe != "undefined") {
                                        if (probe["update-available"]) {
                                            parent.text = "Update available!";
                                        } else {
                                            parent.text = "No update available!";
                                            busy.running = false;
                                        }
                                    }
                                }
                            }

                            Component.onCompleted: timer.start()
                        }

                        BusyIndicator {
                            id: busy
                            anchors.horizontalCenter: parent.horizontalCenter
                            running: true
                        }

                        Text {
                            font.pixelSize: 18
                            color: "#fff"
                            anchors.horizontalCenter: parent.horizontalCenter

                            text: currentState
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
                            color: wrapper.PathView.isCurrentItem && !poweroff.active ? "#fff" : "#0C5E9C"
                        }
                    }

                    Text {
                        text: model.name
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.pixelSize: 22
                        color: wrapper.PathView.isCurrentItem && !poweroff.active ? "#fff" : "#0C5E9C"
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

            Image {
                id: poweroff
                source: "poweroff.png"
                width: 64
                height: 64
                smooth: true
                mipmap: true
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 10

                property bool active: false

                ColorOverlay {
                    anchors.fill: poweroff
                    source: poweroff
                    color: parent.active ? "#fff" : "#0C5E9C"
                }
            }
        }
    }
}
