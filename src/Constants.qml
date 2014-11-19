import QtQuick 2.1

Item {
    property int videoEndsThreshold: 5 * 1000

    property int titlebarHeight: 80
    property int titlebarTriggerThreshold: 50
    property int controlbarHeight: 64
    property int controlbarTriggerThreshold: 50
    
    property int simplifiedModeTriggerWidth: 438
    property int hideVolumeBarTriggerWidth: 600
    property int transitionModeTriggerWidth: 638

    property int miniModeWidth: 400 + 2 * windowGlowRadius
    
    property int windowRadius: 3
    property int windowGlowRadius: windowView.windowGlowRadius
    
    property color normalColor: "#B4B4B4"
    property color hoverColor: "#FFFFFF"
    property color pressedColor: "#00BDFF"
    
    property color bgDarkColor: "#131414"
}