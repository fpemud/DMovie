import QtQuick 2.1
import QtMultimedia 5.0

MouseArea {
    id: mouse_area
    focus: true
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    anchors.fill: window

    property var window
    property int resizeEdge
    property int triggerThreshold: 10  // threshold for resizing the window
    property int cornerTriggerThreshold: 20

    property int dragStartX
    property int dragStartY
    property int windowLastX
    property int windowLastY

    property bool shouldPerformClick: true

    property int movieDuration: movieInfo.movie_duration

    MenuResponder { id: menu_responder }
    KeysResponder { id: keys_responder }

    Connections {
        target: movieInfo

        onMovieWidthChanged: {
            if (root.miniModeState()) {
                backupWidth = movieInfo.movie_width
                _setSizeForRootWindowWithWidth(windowView.width)
                backupCenter = Qt.point(windowView.x + windowView.width / 2,
                                        windowView.y + windowView.height / 2)
                return
            }
            if (movieInfo.movie_width == 856) {// first start
                if (config.playerApplyLastClosedSize) {
                    hasResized = true
                    _setSizeForRootWindowWithWidth(database.lastWindowWidth)
                } else {
                    windowView.setWidth(windowView.defaultWidth)
                    windowView.setHeight(windowView.defaultHeight)
                }
            } else {
                var destWidth = hasResized ? windowView.width : movieInfo.movie_width
                _setSizeForRootWindowWithWidth(destWidth)
            }
            windowView.centerRequestCount-- >= 0 && windowView.moveToCenter()
        }

        onMovieSourceChanged: {
            // NOTE
            // a work around here, the player source should be bound to
            // movieInfo.movie_file as I used to, but we should force the
            // sourceChanged signal to be emitted.
            player.stop()
            player.source = ""
            player.source = movieInfo.movie_file
            // NOTE END

            var last_watched_pos = database.fetch_video_position(player.source)
            if (config.playerAutoPlayFromLast
                && _utils.urlIsNativeFile(player.source)
                && Math.abs(last_watched_pos - movieInfo.movie_duration) > program_constants.videoEndsThreshold) {
                seek_to_last_watched_timer.schedule(last_watched_pos)
            } else {
                play()
            }

            showControls()
        }

        onFileInvalid: {
            var invalidFile = movieInfo.movie_file
            if (_utils.urlIsNativeFile(invalidFile)) {
                notifybar.show(dsTr("Invalid file") + ": " + movieInfo.movie_title)
            } else {
                notifybar.show(dsTr("The parse failed"))
            }
            root.reset()
        }

        onInfoGotten: info_window.showContent(movie_info)
    }

    property bool shouldPlayThefirst: true
    Connections {
        target: _findVideoThreadManager

        onFindVideoDone: {
            main_controller.shouldPlayThefirst && (movieInfo.movie_file = path)

            invalidCount > 0 && notifybar.show(dsTr("%1 files unable to be parsed have been excluded").arg(invalidCount))
        }
    }

    Timer {
        id: seek_to_last_watched_timer
        interval: 500

        property int last_watched_pos

        function schedule(pos) {
            start()
            last_watched_pos = pos
        }

        onTriggered: {
            player.seek(last_watched_pos)
            play()
        }
    }

    Timer {
        id: double_click_check_timer
        interval: 200

        onTriggered: {
            doSingleClick()
        }
    }

    function _getActualWidthWithWidth(destWidth) {
        var widthHeightScale = root.widthHeightScale
        var destHeight = (destWidth - program_constants.windowGlowRadius * 2) / widthHeightScale + program_constants.windowGlowRadius * 2
        if (destHeight > primaryRect.height) {
            return (primaryRect.height - 2 * program_constants.windowGlowRadius) * widthHeightScale + 2 * program_constants.windowGlowRadius
        } else {
            return destWidth
        }
    }

    function _setSizeForRootWindowWithWidth(destWidth) {
        var destWidth = Math.min(destWidth, primaryRect.width)
        var widthHeightScale = root.widthHeightScale
        var destHeight = (destWidth - program_constants.windowGlowRadius * 2) / widthHeightScale + program_constants.windowGlowRadius * 2
        if (destHeight > primaryRect.height) {
            windowView.setWidth((primaryRect.height - 2 * program_constants.windowGlowRadius) * widthHeightScale + 2 * program_constants.windowGlowRadius)
            windowView.setHeight(primaryRect.height)
        } else {
            windowView.setWidth(destWidth)
            windowView.setHeight(destHeight)
        }
    }

    function setWindowTitle(title) {
        titlebar.title = title
        windowView.setTitle(title)
    }

    // resize operation related
    function getEdge(mouse) {
        if (windowView.getState() == Qt.WindowFullScreen) return resize_edge.resizeNone
        // four corners
        if (0 < mouse.x && mouse.x < cornerTriggerThreshold) {
            if (0 < mouse.y && mouse.y < cornerTriggerThreshold)
                return resize_edge.resizeTopLeft
            if (window.height - cornerTriggerThreshold < mouse.y && mouse.y < window.height)
                return resize_edge.resizeBottomLeft
        } else if (window.width - cornerTriggerThreshold < mouse.x && mouse.x < window.width) {
            if (0 < mouse.y && mouse.y < cornerTriggerThreshold)
                return resize_edge.resizeTopRight
            if (window.height - cornerTriggerThreshold < mouse.y && mouse.y < window.height)
                return resize_edge.resizeBottomRight
        }
        // four sides
        if (0 < mouse.x && mouse.x < triggerThreshold) {
            return resize_edge.resizeLeft
        } else if (window.width - triggerThreshold < mouse.x && mouse.x < window.width) {
            return resize_edge.resizeRight
        } else if (0 < mouse.y && mouse.y < triggerThreshold){
            return resize_edge.resizeTop
        } else if (window.height - triggerThreshold < mouse.y && mouse.y < window.height) {
            return resize_edge.resizeBottom
        }

        return resize_edge.resizeNone
    }

    function changeCursor(resizeEdge) {
        if (resizeEdge == resize_edge.resizeLeft || resizeEdge == resize_edge.resizeRight) {
            cursorShape = Qt.SizeHorCursor
        } else if (resizeEdge == resize_edge.resizeTop || resizeEdge == resize_edge.resizeBottom) {
            cursorShape = Qt.SizeVerCursor
        } else if (resizeEdge == resize_edge.resizeTopLeft || resizeEdge == resize_edge.resizeBottomRight) {
            cursorShape = Qt.SizeFDiagCursor
        } else if (resizeEdge == resize_edge.resizeBottomLeft || resizeEdge == resize_edge.resizeTopRight){
            cursorShape = Qt.SizeBDiagCursor
        } else {
            cursorShape = Qt.ArrowCursor
        }
    }

    function doSingleClick() {
        if (config.othersLeftClick) {
            if (player.playbackState == MediaPlayer.PausedState) {
                play()
            } else if (player.playbackState == MediaPlayer.PlayingState) {
                pause()
            }
        }
    }

    function doDoubleClick(mouse) {
        if (player.playbackState != MediaPlayer.StoppedState) {
            if (config.othersDoubleClick) {
                toggleFullscreen()
            }
        } else {
            openFile()
        }
    }

    function close() {
        windowView.close()
    }

    function normalize() {
        root.state = "normal"
        windowView.showNormal()
    }

    property bool fullscreenFromMaximum: false
    function fullscreen() {
        fullscreenFromMaximum = (windowView.getState() == Qt.WindowMaximized)
        root.state = "no_glow"
        windowView.showFullScreen()

        quitMiniMode()
    }

    function quitFullscreen() { fullscreenFromMaximum ? maximize() : normalize() }

    function maximize() {
        root.state = "no_glow"
        windowView.showMaximized()

        quitMiniMode()
    }

    function minimize() {
        root.state = "normal"
        windowView.doMinimized()
    }

    property int backupWidth: 0
    property point backupCenter: Qt.point(0, 0)
    function quitMiniMode() {
        if (!player.hasVideo) return

        windowView.staysOnTop = false
        if (windowView.getState() != Qt.WindowMaximized
            && windowView.getState() != Qt.WindowFullScreen)
        {
            _setSizeForRootWindowWithWidth(backupWidth)
            windowView.setX(backupCenter.x - windowView.width / 2)
            windowView.setY(backupCenter.y - windowView.height / 2)
        }
        windowView.requestActivate()
    }
    function miniMode() {
        if (!player.hasVideo) return

        if (windowView.getState() != Qt.WindowMaximized
            && windowView.getState() != Qt.WindowFullScreen)
        {
            backupWidth = windowView.width
            backupCenter = Qt.point(windowView.x + windowView.width / 2,
                windowView.y + windowView.height / 2)
        }
        normalize()
        windowView.staysOnTop = true
        _setSizeForRootWindowWithWidth(program_constants.miniModeWidth)

        windowView.setX(backupCenter.x - windowView.width / 2)
        windowView.setY(backupCenter.y - windowView.height / 2)
        windowView.requestActivate()
    }
    function toggleMiniMode() {
        root.miniModeState() ? quitMiniMode() : miniMode()
    }

    function setProportion(propWidth, propHeight) {
        if (propWidth == 1 && propHeight == 1) { // indicates we should reset the proportion, see menu_controller.py for more details
            root.widthHeightScale = (movieInfo.movie_width - program_constants.windowGlowRadius * 2) / (movieInfo.movie_height - program_constants.windowGlowRadius * 2)
        } else {
            root.widthHeightScale = propWidth / propHeight
        }

        var destWidth = (movieInfo.movie_width - program_constants.windowGlowRadius * 2) * root.actualScale + program_constants.windowGlowRadius * 2
        player.fillMode = VideoOutput.Stretch

        _setSizeForRootWindowWithWidth(destWidth)
    }

    function setScale(scale) {
        root.actualScale = scale
        var destWidth = (movieInfo.movie_width - program_constants.windowGlowRadius * 2) * root.actualScale + program_constants.windowGlowRadius * 2

        _setSizeForRootWindowWithWidth(destWidth)
    }

    function toggleFullscreen() {
        windowView.getState() == Qt.WindowFullScreen ? quitFullscreen() : fullscreen()
    }

    function toggleMaximized() {
        windowView.getState() == Qt.WindowMaximized ? normalize() : maximize()
    }

    function toggleStaysOnTop() {
        windowView.staysOnTop = !windowView.staysOnTop
    }

    function flipHorizontal() { player.flipHorizontal() }
    function flipVertical() { player.flipVertical() }
    function rotateClockwise() {
        player.rotateClockwise()
        movieInfo.rotate()
        database.record_video_rotation(player.source, player.orientation)
    }
    function rotateAnticlockwise() {
        player.rotateAnticlockwise()
        movieInfo.rotate()
        database.record_video_rotation(player.source, player.orientation)
    }

    // player control operation related
    function play() { player.play() }
    function pause() { player.pause() }
    function stop() { player.stop() }

    function togglePlay() {
        if (player.hasMedia && player.source != "") {
            player.playbackState == MediaPlayer.PlayingState ? pause() : play()
        } else {
            openFile()
        }
    }

    function forwardByDelta(delta) {
        var tempRate = player.playbackRate
        player.playbackRate = 1.0
        player.seek(player.position + delta)
        var percentage = Math.floor(player.position / (movieInfo.movie_duration + 1) * 100)
        var percentageInfo = movieInfo.movie_duration != 0 ? " (%1%)".arg(percentage) : ""
        notifybar.show(dsTr("Forward") + ": " + formatTime(player.position) + percentageInfo)
        player.playbackRate = tempRate
    }

    function backwardByDelta(delta) {
        var tempRate = player.playbackRate
        player.playbackRate = 1.0
        player.seek(player.position - delta)
        var percentage = Math.floor(player.position / (movieInfo.movie_duration + 1) * 100)
        var percentageInfo = movieInfo.movie_duration != 0 ? " (%1%)".arg(percentage) : ""
        notifybar.show(dsTr("Rewind") + ": " + formatTime(player.position) + percentageInfo)
        player.playbackRate = tempRate
    }

    function forward() { forwardByDelta(Math.floor(config.playerForwardRewindStep * 1000)) }
    function backward() { backwardByDelta(Math.floor(config.playerForwardRewindStep * 1000)) }

    function speedUp() {
        if (player.source.toString().search("file://") != 0) return

        var restoreInfo = config.hotkeysPlayRestoreSpeed+"" ? dsTr("(Press %1 to restore)").arg(config.hotkeysPlayRestoreSpeed) : ""
        player.playbackRate = Math.min(2.0, (player.playbackRate + 0.1).toFixed(1))
        notifybar.show(dsTr("Playback rate: ") + player.playbackRate + restoreInfo)
    }

    function slowDown() {
        if (player.source.toString().search("file://") != 0) return

        var restoreInfo = config.hotkeysPlayRestoreSpeed+"" ? dsTr("(Press %1 to restore)").arg(config.hotkeysPlayRestoreSpeed) : ""
        player.playbackRate = Math.max(0.1, (player.playbackRate - 0.1).toFixed(1))
        notifybar.show(dsTr("Playback rate: ") + player.playbackRate + restoreInfo)
    }

    function restoreSpeed() {
        if (player.source.toString().search("file://") != 0) return

        player.playbackRate = 1
        notifybar.show(dsTr("Playback rate: ") + player.playbackRate)
    }

    function increaseVolumeByDelta(delta) { setVolume(Math.min(player.volume + delta, 1.0)) }
    function decreaseVolumeByDelta(delta) { setVolume(Math.max(player.volume - delta, 0.0)) }

    function increaseVolume() { increaseVolumeByDelta(0.05) }
    function decreaseVolume() { decreaseVolumeByDelta(0.05) }

    function setVolume(volume) {
        config.playerVolume = volume
        config.playerMuted = false
        notifybar.show(dsTr("Volume: ") + Math.round(player.volume * 100) + "%")
    }

    function setMute(muted) {
        config.playerMuted = muted

        if (player.muted) {
            notifybar.show(dsTr("Muted"))
        } else {
            notifybar.show(dsTr("Volume: ") + Math.round(player.volume * 100) + "%")
        }
    }

    function toggleMute() {
        setMute(!player.muted)
    }

    function openFile() { open_file_dialog.state = "open_video_file"; open_file_dialog.open() }
    function openUrl() { open_url_dialog.open() }
    function openFileForSubtitle() { open_file_dialog.state = "open_subtitle_file"; open_file_dialog.open() }

    // playPaths is not quit perfect here, whether the play operation will
    // be performed is decided by the playFirst parameter.
    function playPaths(pathList, playFirst) {
        var paths = []
        for (var i = 0; i < pathList.length; i++) {
            var file_path = pathList[i].toString().replace("file://", "")
            file_path = decodeURIComponent(file_path)
            paths.push(file_path)
        }

        if (paths.length == 1 && !_utils.pathIsDir(paths[0])) {
            if (!_utils.fileIsValidVideo(paths[0])) {
                notifybar.show(dsTr("Invalid file") + ": " + paths[0])
            }
            if (playFirst) {
                movieInfo.movie_file = paths[0]
            }
        } else {
            main_controller.shouldPlayThefirst = playFirst
            _findVideoThreadManager.getAllVideoFilesInPathList(paths)
        }
    }

    function setSubtitleVerticalPosition(percentage) {
        config.subtitleVerticalPosition = Math.max(0, Math.min(1, percentage))
        player.subtitleVerticalPosition = config.subtitleVerticalPosition
    }

    function subtitleMoveUp() { setSubtitleVerticalPosition(config.subtitleVerticalPosition + 0.05)}
    function subtitleMoveDown() { setSubtitleVerticalPosition(config.subtitleVerticalPosition - 0.05)}
    function subtitleForward() { player.subtitleDelay += 500 }
    function subtitleBackward() { player.subtitleDelay -= 500 }

    Keys.onPressed: keys_responder.respondKey(event)
    Keys.onReleased: if(!event.isAutoRepeat) shortcuts_viewer.hide()

    onWheel: {
        if (config.othersWheel) {
            wheel.angleDelta.y > 0 ? increaseVolumeByDelta(wheel.angleDelta.y / 120 * 0.05)
                                    :decreaseVolumeByDelta(-wheel.angleDelta.y / 120 * 0.05)
            controlbar.emulateVolumeButtonHover()
        }
    }

    onPressed: {
        resizeEdge = getEdge(mouse)
        if (resizeEdge != resize_edge.resizeNone) {
            resize_visual.resizeEdge = resizeEdge
        } else {
            var pos = windowView.getCursorPos()

            windowLastX = windowView.x
            windowLastY = windowView.y
            dragStartX = pos.x
            dragStartY = pos.y
        }
    }

    onPositionChanged: {
        windowView.setCursorVisible(true)
        mouse_area.cursorShape = Qt.ArrowCursor
        hide_controls_timer.restart()

        if (!pressed) {
            changeCursor(getEdge(mouse))

            if (mouseInControlsArea()) {
                showControls()
            }
        }
        else {
            // prevent play or pause event from happening if we intend to move or resize the window
            shouldPerformClick = false
            if (resizeEdge != resize_edge.resizeNone) {
                resize_visual.show()
                resize_visual.intelligentlyResize(windowView, mouse.x, mouse.y)
            }
            else if (windowView.getState() != Qt.WindowFullScreen){
                var pos = windowView.getCursorPos()
                windowView.setX(windowLastX + pos.x - dragStartX)
                windowView.setY(windowLastY + pos.y - dragStartY)
                windowLastX = windowView.x
                windowLastY = windowView.y
                dragStartX = pos.x
                dragStartY = pos.y
            }
        }
    }

    onReleased: {
        resizeEdge = resize_edge.resizeNone

        if (resize_visual.visible) {
            hasResized = true
            resize_visual.hide()
            // do the actual resize action
            windowView.setX(resize_visual.frameX)
            windowView.setY(resize_visual.frameY)
            _setSizeForRootWindowWithWidth(resize_visual.frameWidth)
        }
    }

    onClicked: {
        if (!shouldPerformClick) {
            shouldPerformClick = true
            return
        }

        if (mouse.button == Qt.RightButton) {
            _menu_controller.show_menu()
        } else {
            if (!double_click_check_timer.running) {
                double_click_check_timer.restart()
            }
        }
    }

    onDoubleClicked: {
        if (mouse.button == Qt.RightButton) return

        if (double_click_check_timer.running) {
            double_click_check_timer.stop()
        } else {
            doSingleClick()
        }
        doDoubleClick()
    }

    DropArea {
        anchors.fill: parent

        onDropped: {
            if (drop.urls.length == 1) {
                var file_path = decodeURIComponent(drop.urls[0].toString().replace("file://", ""))
                if (_utils.pathIsDir(file_path)) {
                    main_controller.playPaths([file_path], true)
                } else if (_utils.fileIsValidVideo(file_path)) {
                    main_controller.playPaths([file_path], true)
                } else if (_utils.fileIsSubtitle(file_path)) {
                    movieInfo.subtitle_file = file_path
                } else {
                    notifybar.show(dsTr("Invalid file") + ": " + file_path)
                }
            } else {
                main_controller.playPaths(drop.urls, true)
            }
        }
    }
}
