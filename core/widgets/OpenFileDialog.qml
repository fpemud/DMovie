import QtQuick 2.1
import Deepin.Widgets 1.0

DFileDialog {
    title: dsTr("Please choose one file or more")
    folder: database.lastOpenedPath || _utils.homeDir
    nameFilters: [ dsTr("Video files") + videoFilter, allFilesFilter]
    selectMultiple: true
    selectExisting: true
    selectFolder: false
    saveMode: false

    property string videoFilter: "(*.3gp *.avi *.f4v *.flv *.mkv *.mov *.mp4
                    *.mpeg *.ogg *.ogv *.rm *.rmvb *.webm *.wmv)"
    property string allFilesFilter: dsTr("All files") + "(*)"
    property string state: "open_video_file"

    onStateChanged: {
        switch(state) {
            case "open_video_file":
            title = dsTr("Please choose one file or more")
            folder = database.lastOpenedPath || _utils.homeDir
            nameFilters = [ dsTr("Video files") + videoFilter, allFilesFilter]
            selectMultiple = true
            selectExisting = true
            defaultFileName = " "
            saveMode = false
            break

            case "open_subtitle_file":
            title = dsTr("Please choose one file")
            folder = database.lastOpenedPath || _utils.homeDir
            nameFilters = [ dsTr("Subtitle files") + "(*.srt *.ass *.ssa)", allFilesFilter]
            selectMultiple = false
            selectExisting = true
            defaultFileName = " "
            saveMode = false
            break
        }
    }
}
