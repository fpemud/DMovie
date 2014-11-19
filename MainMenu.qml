import QtQuick 2.1
import QtQuick.Controls 1.2

Menu {
    id: rightClickMenu

//    signal toggleFullscreen()
//    signal toggleMiniMode()
//    signal screenShot()
//    signal scaleChanged(float scale)
//    signal proportionChanged(float propWidth, float propHeight)
//    signal openDialog(string _x)
//    signal staysOnTop(bool onTop)
//    signal showPreference()
//    signal showMovieInformation()
//    signal openSubtitleFile()
//    signal subtitleSelected(string subtitle)
//    signal playForward()
//    signal playBackward()
//    signal volumeUp()
//    signal volumeDown()
//    signal volumeMuted()
//    signal showSubtitleSettings()

    MenuItem {
        id: _open_file
        text: "Open a file"
        shortcut: config.hotkeysFilesOpenFile
    }

    MenuItem {
        id: _open_url
        text: "Open URL"
    }

    MenuSeparator {
    }

    MenuItem {
        id: _fullscreen_quit
        text: "Fullscreen"
        shortcut: config.hotkeysPlayToggleFullscreen
    }

    MenuItem {
        id: _mini_mode
        text: "Mini mode"
        shortcut: config.hotkeysFrameSoundToggleMiniMode
    }

    MenuItem {
        id: _on_top
        text: "Always on top"
        checkable: true
    }

    MenuSeparator {
    }

    Menu {
        id: _play
        title: "Play"

        MenuItem {
            id: _play_operation_forward
            text: "Forward"
            shortcut: config.hotkeysPlayForward
        }

        MenuItem {
            id: _play_operation_backward
            text: "Rewind"
            shortcut: config.hotkeysPlayBackward
        }
    }

    Menu {
        id: _frame
        title: "Frame"

        ExclusiveGroup {
            id: _frame_p
        }

        MenuItem {
            id: _frame_p_default
            text: "Default"
            checkable: true
            exclusiveGroup: _frame_p
            checked: true
        }

        MenuItem {
            id: _frame_p_4_3
            text: "4:3"
            checkable: true
            exclusiveGroup: _frame_p
        }

        MenuItem {
            id: _frame_p_16_9
            text: "16:9"
            checkable: true
            exclusiveGroup: _frame_p
        }

        MenuItem {
            id: _frame_p_16_10
            text: "16:10"
            checkable: true
            exclusiveGroup: _frame_p
        }

        MenuItem {
            id: _frame_p_1_85_1
            text: "1.85:1"
            checkable: true
            exclusiveGroup: _frame_p
        }

        MenuItem {
            id: _frame_p_2_35_1
            text: "2.35:1"
            checkable: true
            exclusiveGroup: _frame_p
        }

        MenuSeparator {
        }

        ExclusiveGroup {
            id: _frame_s
        }

        MenuItem {
            id: _frame_s_0_5
            text: "0.5"
            checkable: true
            exclusiveGroup: _frame_s
        }

        MenuItem {
            id: _frame_s_1
            text: "1"
            checkable: true
            exclusiveGroup: _frame_s
            checked: true
        }

        MenuItem {
            id: _frame_s_1_5
            text: "1.5"
            checkable: true
            exclusiveGroup: _frame_s
        }

        MenuItem {
            id: _frame_s_2
            text: "2"
            checkable: true
            exclusiveGroup: _frame_s
        }
    }

    Menu {
        id: _sound
        title: "Sound"

        MenuItem {
            id: _sound_increase
            text: "Volume Up"
            shortcut: config.hotkeysFrameSoundIncreaseVolume
        }

        MenuItem {
            id: _sound_decrease
            text: "Volume Down"
            shortcut: config.hotkeysFrameSoundDecreaseVolume
        }

        MenuItem {
            id: _sound_muted
            text: "Muted"
            checkable: true
            shortcut: config.hotkeysFrameSoundToggleMute
        }
    }

    Menu {
        id: _subtitle
        title: "Subtitles"

        MenuItem {
            id: _subtitle_hide
            text: "Hide subtitle"
            checkable: true
        }

        MenuSeparator {
        }

        MenuItem {
            id: _subtitle_manual
            text: "Open manually"
        }

        MenuItem {
            id: _subtitle_choose
            text: "Subtitle selection"
        }

        MenuItem {
            id: _subtitle_settings
            text: "Subtitle setting"
        }
    }

    MenuSeparator {
    }

    MenuItem {
        id: _preferences
        text: "Options"
        onTriggered: { _menu_controller.showPreference() }
    }

    MenuItem {
        id: _information
        text: "Information"
        onTriggered: { _menu_controller.showMovieInformation() }
    }
}

