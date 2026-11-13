// Nerd Font glyphs

pragma Singleton
import QtQuick
import Quickshell

Singleton {
    readonly property string clock:    String.fromCodePoint(0xF017)
    readonly property string tempLow:  String.fromCodePoint(0xF2CB)
    readonly property string tempMid:  String.fromCodePoint(0xF2C9)
    readonly property string tempHigh: String.fromCodePoint(0xF2C7)
    readonly property string memory:   String.fromCodePoint(0xEFC5)
    readonly property string cpu:      String.fromCodePoint(0xF4BC)
    readonly property string volume:   String.fromCodePoint(0xE638)
    readonly property string muted:    String.fromCodePoint(0xF075F)
    readonly property string mic:      String.fromCodePoint(0xF036C)
    readonly property string micOff:   String.fromCodePoint(0xF036D)
    readonly property string app:      String.fromCodePoint(0xF075A)
    readonly property string netUp:    String.fromCodePoint(0xF0200)
    readonly property string netDown:  String.fromCodePoint(0xF05AA)
    readonly property string power:    String.fromCodePoint(0xF011)
    readonly property string search:   String.fromCodePoint(0xF0349)
    readonly property string down:     String.fromCodePoint(0xF0045)
    readonly property string up:       String.fromCodePoint(0xF005D)
    readonly property string reboot:   String.fromCodePoint(0xF0709)
    readonly property string prev:     String.fromCodePoint(0xF0141)
    readonly property string next:     String.fromCodePoint(0xF0142)
    readonly property string today:    String.fromCodePoint(0xF00F6)
}
