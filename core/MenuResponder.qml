import QtQuick 2.1

// After some digging you will find that this file is somehow twisted with
// main.qml(where some ids are from), because the content of this file is
// mainly extracted from main.qml :)
Connections {
    target: _menu_controller

    onToggleFullscreen: {
        main_controller.toggleFullscreen()
    }
    onToggleMiniMode: {
        main_controller.toggleMiniMode()
    }
    onScreenShot: {
        windowView.screenShot()
    }
    onProportionChanged: main_controller.setProportion(propWidth, propHeight)
    onScaleChanged: main_controller.setScale(scale)
    onStaysOnTop: {
        windowView.staysOnTop = onTop
    }
    onOpenDialog: {
        if (arguments[0] == "file") {
            main_controller.openFile()
        } else {
            main_controller.openUrl()
        }
    }

    onSubtitleSelected: movieInfo.subtitle_file = subtitle

    onShowPreference: { preference_window.show() }

    onShowMovieInformation: {
        if (player.source && player.hasVideo) {
            info_window.showContent(movieInfo.getMovieInfo())
        }
    }

    onPlayForward: { main_controller.forward() }
    onPlayBackward: { main_controller.backward() }

    onVolumeUp: { main_controller.increaseVolume() }
    onVolumeDown: { main_controller.decreaseVolume() }
    onVolumeMuted: { main_controller.toggleMute() }

    onShowSubtitleSettings: { preference_window.show(); preference_window.scrollToSubtitle() }
}
