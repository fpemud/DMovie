import QtQuick 2.1
import QtMultimedia 5.0
import QtGraphicalEffects 1.0
import Deepin.Widgets 1.0

DragableArea {
    id: control_bar
    // make sure the 15 pixels upon the controlbar hasn't the ability to play or pause the video
    height: program_constants.controlbarHeight + 15

    property alias timeInfoVisible: playTime.visible
    property alias volume: volume_button.volume
    property alias percentage: progressbar.percentage
    property alias videoPlaying: play_pause_button.checkFlag
    property alias muted: volume_button.muted
    property alias widthHeightScale: videoPreview.widthHeightScale
    property alias dragbarVisible: drag_point.visible
    property alias windowFullscreenState: toggle_fullscreen_button.checkFlag
    property alias status: buttonArea.state
    property bool previewHasVideo: false

    property QtObject tooltipItem

    signal mutedSet (bool muted)
    signal changeVolume (real volume)
    signal percentageSet(real percentage)
    signal configButtonClicked ()
    signal playStopButtonClicked ()
    signal playPauseButtonClicked ()
    signal openFileButtonClicked ()
    signal toggleFullscreenClicked ()

    Behavior on opacity {
        NumberAnimation { duration: 300 }
    }

    function show() {
        visible = true
    }

    function hide() {
        visible = false
    }

    function reset() {
        percentage = 0
        play_pause_button.checkFlag = false
    }

    function showPreview(mouseX, percentage, mode) {
        if (config.playerShowPreview) {
            videoPreview.state = mode
            if (control_bar.previewHasVideo && videoPreview.source != "" && movieInfo.movie_duration != 0) {
                videoPreview.visible = true
                videoPreview.x = Math.min(Math.max(mouseX - videoPreview.width / 2, 0),
                                          width - videoPreview.width)
                videoPreview.y = progressbar.y - videoPreview.height - 10

                if (mouseX <= videoPreview.cornerWidth / 2) {
                    videoPreview.cornerPos = mouseX + videoPreview.cornerWidth / 2
                    videoPreview.cornerType = "left"
                } else if (mouseX >= width - videoPreview.cornerWidth / 2) {
                    videoPreview.cornerPos = mouseX - width + videoPreview.width - videoPreview.cornerWidth / 2
                    videoPreview.cornerType = "right"
                } else if (mouseX < videoPreview.width / 2) {
                    videoPreview.cornerPos = mouseX
                    videoPreview.cornerType = "center"
                } else if (mouseX >= width - videoPreview.width / 2) {
                    videoPreview.cornerPos = mouseX - width + videoPreview.width
                    videoPreview.cornerType = "center"
                } else {
                    videoPreview.cornerPos = videoPreview.width / 2
                    videoPreview.cornerType = "center"
                }
                videoPreview.seek(percentage)
            }
        }
    }

    function flipPreviewHorizontal() { videoPreview.flipHorizontal() }
    function flipPreviewVertical() { videoPreview.flipVertical() }
    function rotatePreviewClockwise() { videoPreview.rotateClockwise() }
    function rotatePreviewAntilockwise() { videoPreview.rotateAnticlockwise() }

    function emulateVolumeButtonHover() { volume_button.emulateHover() }

    LinearGradient {
        id: bottomPanelBackround

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 100
        start: Qt.point(0, 0)
        end: Qt.point(0, height)
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#00000000"}
            GradientStop { position: 1.0; color: "#FF000000"}
        }
    }

    Column {
        width: parent.width
        height: program_constants.controlbarHeight
        anchors.bottom: parent.bottom

        ProgressBar {
            id: progressbar
            width: control_bar.width

            onWidthChanged: { progressbar.update() }

            Preview {
                id: videoPreview
                source: movieInfo.movie_file
                visible: false
            }

            onMouseOver: { control_bar.showPreview(mouseX, percentage,  "normal") }
            onMouseDrag: { control_bar.showPreview(mouseX, percentage, "minimal") }

            onMouseExit: {
                videoPreview.visible = false
            }

            onPercentageSet: control_bar.percentageSet(percentage)
        }

        Item {
            id: buttonArea
            state: width < program_constants.simplifiedModeTriggerWidth ? "minimal"
                                                                        : width < program_constants.transitionModeTriggerWidth ? "transition"
                                                                                                                            : "normal"
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: 34

            states: [
                State {
                    name: "normal"
                    PropertyChanges {
                        target: leftButtonArea
                        visible: true
                    }
                    PropertyChanges {
                        target: middleButtonArea
                        anchors.centerIn: buttonArea
                    }
                    PropertyChanges {
                        target: rightButtonArea
                        visible: true
                    }
                },
                State {
                    name: "transition"
                    PropertyChanges {
                        target: leftButtonArea
                        visible: false
                    }
                    PropertyChanges {
                        target: middleButtonArea
                        anchors.centerIn: left_and_middle_area
                    }
                    PropertyChanges {
                        target: rightButtonArea
                        visible: true
                    }
                },
                State {
                    name: "minimal"
                    PropertyChanges {
                        target: leftButtonArea
                        visible: false
                    }
                    PropertyChanges {
                        target: middleButtonArea
                        anchors.centerIn: buttonArea
                    }
                    PropertyChanges {
                        target: rightButtonArea
                        visible: false
                    }
                }
            ]

            PlaceHolder {
                id: left_and_middle_area
                height: parent.height
                anchors.left: leftButtonArea.left
                anchors.right: rightButtonArea.left
            }

            Row {
                id: leftButtonArea
                anchors.left: parent.left
                anchors.leftMargin: 27
                anchors.verticalCenter: parent.verticalCenter
                spacing: 5

                Text {
                    id: playTime
                    text: formatTime(control_bar.percentage * movieInfo.movie_duration) + " / " + formatTime(movieInfo.movie_duration)
                    color: Qt.rgba(100, 100, 100, 1)
                    font.pixelSize: 12

                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Row {
                id: middleButtonArea
                spacing: 0

                ImageButton {
                    tooltip: dsTr("Stop playing")
                    tooltipItem: control_bar.tooltipItem

                    normal_image: "image/stop_normal.svg"
                    hover_image: "image/stop_hover_press.svg"
                    press_image: "image/stop_hover_press.svg"
                    sourceSize.width: 26
                    sourceSize.height: 26

                    anchors.verticalCenter: parent.verticalCenter
                    onClicked: control_bar.playStopButtonClicked()
                }

                Space {
                    width: 32
                }

                ImageButton {
                    id: play_pause_button
                    tooltip: checkFlag ? dsTr("Pause") : dsTr("Play")
                    tooltipItem: control_bar.tooltipItem

                    normal_image: checkFlag ? "image/pause_normal.svg" : "image/play_normal.svg"
                    hover_image: checkFlag ? "image/pause_hover_press.svg" : "image/play_hover_press.svg"
                    press_image: checkFlag ? "image/pause_hover_press.svg" : "image/play_hover_press.svg"

                    property bool checkFlag: false

                    onClicked: control_bar.playPauseButtonClicked()
                }

                Space {
                    width: 32
                }

                VolumeButton {
                    id: volume_button
                    tooltipItem: control_bar.tooltipItem
                    muted: control_bar.muted
                    showBarSwitch: control_bar.width > program_constants.hideVolumeBarTriggerWidth
                    anchors.verticalCenter: parent.verticalCenter

                    onChangeVolume: {
                        control_bar.changeVolume(volume)
                    }

                    onMutedSet: {
                        control_bar.mutedSet(muted)
                    }
                }
            }

            Row {
                id: rightButtonArea
                anchors.right: parent.right
                anchors.rightMargin: 27
                anchors.verticalCenter: parent.verticalCenter
                spacing: 25

                ImageButton {
                    id: toggle_fullscreen_button
                    tooltip: checkFlag ? dsTr("Exit fullscreen") : dsTr("Fullscreen")
                    tooltipItem: control_bar.tooltipItem

                    normal_image: checkFlag ? "image/cancel_fullscreen_normal.svg"
                                            : "image/fullscreen_normal.svg"
                    hover_image: checkFlag ? "image/cancel_fullscreen_hover_press.svg"
                                            : "image/fullscreen_hover_press.svg"
                    press_image: checkFlag ? "image/cancel_fullscreen_hover_press.svg"
                                            : "image/fullscreen_hover_press.svg"

                    property bool checkFlag: false

                    anchors.verticalCenter: parent.verticalCenter
                    onClicked: control_bar.toggleFullscreenClicked()
                }

                ImageButton {
                    tooltip: dsTr("Open a file")
                    tooltipItem: control_bar.tooltipItem

                    normal_image: "image/open_file_normal.svg"
                    hover_image: "image/open_file_hover_press.svg"
                    press_image: "image/open_file_hover_press.svg"

                    anchors.verticalCenter: parent.verticalCenter
                    onClicked: control_bar.openFileButtonClicked()
                }
            }
        }
    }

    Image {
        id: drag_point
        source: "image/dragbar.png"

        anchors.rightMargin: 5
        anchors.bottomMargin: 5
        anchors.right: parent.right
        anchors.bottom: parent.bottom
    }
}