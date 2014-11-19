import QtQuick 2.1
import QtMultimedia 5.0
 
Video {
    id: video
    autoPlay: false
    visible: playbackState != MediaPlayer.StoppedState

    property bool hasMedia: hasVideo || hasAudio

    property alias subtitleContent: subtitle.text
    property alias subtitleFontSize: subtitle.fontSize
    property alias subtitleFontColor: subtitle.fontColor
    property alias subtitleFontFamily: subtitle.fontFamily
    property alias subtitleFontBorderSize: subtitle.fontBorderSize
    property alias subtitleFontBorderColor: subtitle.fontBorderColor
    property alias subtitleShow: subtitle.visible
    property real subtitleVerticalPosition: 0.2
    property int subtitleDelay: 0

    // onPlaying: { pause_notify.visible = false }
    // onPaused: { pause_notify.visible = true }

    // PauseNotify { 
    //     id: pause_notify
    //      visible: false
    //      anchors.centerIn: parent 
    // }

    Subtitle { 
        id: subtitle

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        anchors.bottomMargin: parent.subtitleVerticalPosition * (parent.height - subtitle.height)
    }
}
