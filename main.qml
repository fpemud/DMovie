import QtQuick 2.1
import QtMultimedia 5.0
import QtGraphicalEffects 1.0
import QtQuick.Window 2.1
import Deepin.Locale 1.0
import Deepin.Widgets 1.0

Rectangle {
    id: root
    state: "normal"
    color: "transparent"
    // QT takes care of WORKAREA for you which is thoughtful indeed, but it cause
    // problems sometime, we should be careful in case that it changes height for
    // you suddenly.
    layer.enabled: true

    property var windowLastState: ""

    property real widthHeightScale: (movieInfo.movie_width - 2 * program_constants.windowGlowRadius) / (movieInfo.movie_height - 2 * program_constants.windowGlowRadius)
    property real actualScale: 1.0

    property bool hasResized: false

    property rect primaryRect: {
        return Qt.rect(0, 0, Screen.desktopAvailableWidth, Screen.desktopAvailableHeight)
    }

    states: [
        State {
            name: "normal"

            PropertyChanges { target: main_window; width: root.width - program_constants.windowGlowRadius * 2;
                              height: root.height - program_constants.windowGlowRadius * 2; }
            PropertyChanges { target: titlebar; width: main_window.width; anchors.top: main_window.top }
            PropertyChanges { target: controlbar; width: main_window.width; anchors.bottom: main_window.bottom}
            PropertyChanges { target: player; fillMode: VideoOutput.Stretch }
        },
        State {
            name: "no_glow"

            PropertyChanges { target: main_window; width: root.width; height: root.height }
            PropertyChanges { target: titlebar; width: root.width; anchors.top: root.top }
            PropertyChanges { target: controlbar; width: root.width; anchors.bottom: root.bottom}
            PropertyChanges { target: player; fillMode: VideoOutput.PreserveAspectFit }
        }
    ]

    onStateChanged: {
        if (state == "normal") {
            windowView.setDeepinWindowShadowHint(windowView.windowGlowRadius)
        } else if (state == "no_glow") {
            windowView.setDeepinWindowShadowHint(0)
        }
    }

    Constants { id: program_constants }

    ToolTip {
        id: tooltip

        window: windowView
        screenSize: primaryRect
    }

    OpenFolderDialog {
        id: open_file_dialog

        onAccepted: {
            database.lastOpenedPath = fileUrl
            main_controller.playPaths([fileUrl], true)
        }
    }

    DInputDialog {
        id: open_url_dialog
        message: dsTr("Please input the url of file played") + ": "
        confirmButtonLabel: dsTr("Confirm")
        cancelButtonLabel: dsTr("Cancel")

        cursorPosGetter: windowView

        property string lastInput: ""

        function open() {
            x = windowView.x + (windowView.width - width) / 2
            y = windowView.y + (windowView.height - height) / 2
            show()
        }

        onConfirmed: {
            var input = input.trim()

            if (input.search("://") == -1) {
                notifybar.show(dsTr("The parse failed"))
            } else if (input != movieInfo.movie_file) {
                movieInfo.set_element_dmovie(input)
            }

            lastInput = input
        }

        onVisibleChanged: { if(visible) forceFocus() }
    }

    PreferenceWindow {
        id: preference_window
        width: 560
        height: 480

        onVisibleChanged: {
            if (visible) {
                flags = windowView.getState() == Qt.WindowFullScreen ? Qt.BypassWindowManagerHint : Qt.FramelessWindowHint | Qt.SubWindow
                x = windowView.x + (windowView.width - width) / 2
                y = windowView.y + (windowView.height - height) / 2
            }
        }
    }

    InformationWindow {
        id: info_window

        onCopyToClipboard: _utils.copyToClipboard(text)

        onVisibleChanged: {
            if (visible) {
                flags = windowView.getState() == Qt.WindowFullScreen ? Qt.BypassWindowManagerHint : Qt.FramelessWindowHint | Qt.SubWindow
                x = windowView.x + (windowView.width - width) / 2
                y = windowView.y + (windowView.height - height) / 2
            }
        }
    }

    ShortcutsViewer {
        id: shortcuts_viewer
        x: Math.max(0, Math.min(windowView.x + (windowView.width - width) / 2, Screen.width - width))
        y: Math.max(0, Math.min(windowView.y + (windowView.height - height) / 2, Screen.height - height))
    }

    // translation tools
    property var dssLocale: DLocale {
        domain: "deepin-movie"
    }
    function dsTr(s) {
        return dssLocale.dsTr(s)
    }

    function getSystemFontFamily() {
        var text = Qt.createQmlObject('import QtQuick 2.1; Text {}', root, "");
        return text.font.family
    }

    function initWindowSize() {
        windowView.setWidth(windowView.defaultWidth)
        windowView.setHeight(windowView.defaultHeight)
    }

    function miniModeState() { return windowView.width == program_constants.miniModeWidth }

    function formatTime(millseconds) {
        if (millseconds <= 0) return "00:00:00";
        var secs = Math.ceil(millseconds / 1000)
        var hr = Math.floor(secs / 3600);
        var min = Math.floor((secs - (hr * 3600))/60);
        var sec = secs - (hr * 3600) - (min * 60);

        if (hr < 10) {hr = "0" + hr; }
        if (min < 10) {min = "0" + min;}
        if (sec < 10) {sec = "0" + sec;}
        if (!hr) {hr = "00";}
        return hr + ':' + min + ':' + sec;
    }

    function formatSize(capacity) {
        var teras = capacity / (1024 * 1024 * 1024 * 1024)
        capacity = capacity % (1024 * 1024 * 1024 * 1024)
        var gigas = capacity / (1024 * 1024 * 1024)
        capacity = capacity % (1024 * 1024 * 1024)
        var megas = capacity / (1024 * 1024)
        capacity = capacity % (1024 * 1024)
        var kilos = capacity / 1024

        return Math.floor(teras) ? teras.toFixed(1) + "TB" :
                Math.floor(gigas) ? gigas.toFixed(1) + "GB":
                Math.floor(megas) ? megas.toFixed(1) + "MB" :
                kilos + "KB"
    }

    function formatFilePath(file_path) {
        return file_path.indexOf("file://") != -1 ? file_path.substring(7) : file_path
    }

    function playPath(path) {
        path = JSON.parse(path)

        if (!_utils.fileIsValidVideo(path)) {
            notifybar.show(dsTr("Invalid file") + ": " + path)
            return
        }

        movieInfo.set_element_dmovie(path)
    }

    function showControls() {
        titlebar.show()
        controlbar.show()
        hide_controls_timer.restart()
    }

    function hideControls() {
        titlebar.hide()
        controlbar.hide()
        hide_controls_timer.stop()
    }

    function hideTransientWindows() {
        shortcuts_viewer.hide()
        resize_visual.hide()
    }

    function subtitleVisible() {
        return player.subtitleShow
    }

    function setSubtitleVisible(visible) {
        player.subtitleShow = visible;
    }

    // Utils functions
    function inRectCheck(point, rect) {
        return rect.x <= point.x && point.x <= rect.x + rect.width &&
        rect.y <= point.y && point.y <= rect.y + rect.height
    }

    function mouseInControlsArea() {
        var mousePos = windowView.getCursorPos()
        var mouseInTitleBar = inRectCheck(Qt.point(mousePos.x - windowView.x, mousePos.y - windowView.y),
                                            Qt.rect(0, 0, main_window.width, titlebar.height))
        var mouseInControlBar = inRectCheck(Qt.point(mousePos.x - windowView.x, mousePos.y - windowView.y),
                                            Qt.rect(0, main_window.height - controlbar.height,
                                                    main_window.width, controlbar.height))

        return mouseInTitleBar || mouseInControlBar
    }

    /* to perform like a newly started program  */
    function reset() {
        root.state = "normal"
        titlebar.title = ""
        movieInfo.close()
        main_controller.stop()
        controlbar.reset()
        showControls()
    }

    // To check wether the player is stopped by the app or by the user
    // if it is ther user that stopped the player, we'll not play it automatically.
    property bool videoStoppedByAppFlag: false
    function monitorWindowState(state) {
        titlebar.windowNormalState = (state == Qt.WindowNoState)
        titlebar.windowFullscreenState = (state == Qt.WindowFullScreen)
        controlbar.windowFullscreenState = (state == Qt.WindowFullScreen)
        time_indicator.visibleSwitch = (state == Qt.WindowFullScreen && player.hasMedia)
        if (windowLastState != state) {
            if (config.playerPauseOnMinimized) {
                if (state == Qt.WindowMinimized) {
                    if (player.playbackState == MediaPlayer.PlayingState) {
                        main_controller.pause()
                        videoStoppedByAppFlag = true
                    }
                } else {
                    if (videoStoppedByAppFlag == true) {
                        main_controller.play()
                        videoStoppedByAppFlag = false
                    }
                }
            }
            windowLastState = state
        }
    }

    function monitorWindowClose() {
        _utils.screenSaverUninhibit()
        config.save("Normal", "volume", player.volume)
        database.record_video_position(player.source, player.position)
        database.lastWindowWidth = windowView.width
        database.forceCommit()
    }

    Timer {
        id: hide_controls_timer
        running: true
        interval: 1500

        onTriggered: {
            if (!mouseInControlsArea() && player.source && player.hasVideo) {
                hideControls()

                if (player.playbackState == MediaPlayer.PlayingState) {
                    windowView.setCursorVisible(false)
                }
            } else {
                hide_controls_timer.restart()
            }
        }
    }

    RectangularGlow {
        id: shadow
        anchors.fill: main_window
        glowRadius: program_constants.windowGlowRadius - 5
        spread: 0
        color: Qt.rgba(0, 0, 0, 1)
        cornerRadius: 10
        visible: true
    }

    Rectangle {
        id: main_window
        width: root.width - program_constants.windowGlowRadius * 2
        height: root.height - program_constants.windowGlowRadius * 2
        clip: true
        color: "black"
        anchors.centerIn: parent

        Rectangle {
            id: bg
            color: "#050811"
            visible: !player.visible
            anchors.fill: parent
            Image { anchors.centerIn: parent; source: "image/background.png" }
        }
    }

    Player {
        id: player
        muted: config.playerMuted
        volume: config.playerVolume
        visible: hasVideo && source != ""

        subtitleShow: config.subtitleAutoLoad
        subtitleFontSize: Math.floor(config.subtitleFontSize * main_window.width / windowView.defaultWidth)
        subtitleFontFamily: config.subtitleFontFamily || getSystemFontFamily()
        subtitleFontColor: config.subtitleFontColor
        subtitleFontBorderSize: config.subtitleFontBorderSize
        subtitleFontBorderColor: config.subtitleFontBorderColor
        subtitleVerticalPosition: config.subtitleVerticalPosition

        anchors.fill: main_window

        // theses two properties are mainly used in onStopped.
        // because everytime we change the source onStopped executes, but the
        // source out there is no longer the old source, it's the new source
        // we set instead.
        property url lastSource: ""
        property int lastPosition: 0

        // onSourceChanged doesn't ensures that the file is playable, this one did.
        // 2014/9/16 add: not ensures url playable, either
        onPlaying: {
            notifybar.hide()
            main_controller.setWindowTitle(movieInfo.movie_title)

            _utils.screenSaverInhibit()

            lastSource = source
            if (config.playerFullscreenOnOpenFile) main_controller.fullscreen()
        }

        onStopped: {
            windowView.setTitle(dsTr("Deepin Movie"))
            _utils.screenSaverUninhibit()
            database.record_video_position(lastSource, lastPosition)
        }

        onPlaybackStateChanged: controlbar.videoPlaying = player.playbackState == MediaPlayer.PlayingState

        onPositionChanged: {
            position != 0 && (lastPosition = position)
            subtitleContent = movieInfo.get_subtitle_at(position + subtitleDelay)
            controlbar.percentage = position / movieInfo.movie_duration
        }

        onSourceChanged: {
        }

        onErrorChanged: {
            switch(error) {
                case MediaPlayer.NetworkError:
                case MediaPlayer.FormatError:
                case MediaPlayer.ResourceError:
                movieInfo.fileInvalid()
                break
            }

            open_url_dialog.lastInput = ""
        }
    }

    TimeIndicator {
        id: time_indicator
        visible: visibleSwitch && !titlebar.visible
        percentage: controlbar.percentage

        property bool visibleSwitch: false

        anchors.top: main_window.top
        anchors.right: main_window.right
        anchors.topMargin: 10
        anchors.rightMargin: 10
    }

    MainController {
        id: main_controller
        window: root
    }

    Notifybar {
        id: notifybar
        width: main_window.width / 2
        anchors.top: root.top
        anchors.left: root.left
        anchors.topMargin: 60
        anchors.leftMargin: 30
    }

    MainMenu {
        id: main_menu
    }

    TitleBar {
        id: titlebar
        state: root.miniModeState() ? "minimal" : "normal"
        visible: false
        window: windowView
        windowStaysOnTop: windowView.staysOnTop
        anchors.horizontalCenter: main_window.horizontalCenter
        tooltipItem: tooltip

        onMenuButtonClicked: main_menu.popup()
        onMinButtonClicked: main_controller.minimize()
        onMaxButtonClicked: windowNormalState ? main_controller.maximize() : main_controller.normalize()
        onCloseButtonClicked: main_controller.close()

        onQuickNormalSize: main_controller.setScale(1)
        onQuickOneHalfSize: main_controller.setScale(1.5)
        onQuickToggleFullscreen: main_controller.toggleFullscreen()
        onQuickToggleTop: main_controller.toggleStaysOnTop()
    }

    ControlBar {
        id: controlbar
        visible: false
        window: windowView
        volume: config.playerVolume
        percentage: player.position / movieInfo.movie_duration
        muted: config.playerMuted
        dragbarVisible: root.state == "normal"
        timeInfoVisible: player.source != "" && player.hasMedia && movieInfo.movie_duration != 0
        tooltipItem: tooltip

        anchors.horizontalCenter: main_window.horizontalCenter

        Timer {
            id: delay_seek_timer
            interval: 500
            property int destPos

            onTriggered: player.seek(destPos)
        }

        onChangeVolume: { main_controller.setVolume(volume) }
        onMutedSet: { main_controller.setMute(muted) }

        onToggleFullscreenClicked: main_controller.toggleFullscreen()

        onPlayStopButtonClicked: { root.reset() }
        onPlayPauseButtonClicked: { main_controller.togglePlay() }
        onOpenFileButtonClicked: { main_controller.openFile() }
        onPercentageSet: {
            if (movieInfo.movie_duration) {
                delay_seek_timer.destPos = movieInfo.movie_duration * percentage
                delay_seek_timer.restart()
            }
        }
    }

    ResizeEdge { id: resize_edge }
    ResizeVisual {
        id: resize_visual

        frameY: windowView.y
        frameX: windowView.x
        frameWidth: root.width
        frameHeight: root.height
        widthHeightScale: root.widthHeightScale
    }

    Component.onCompleted: showControls()
}
