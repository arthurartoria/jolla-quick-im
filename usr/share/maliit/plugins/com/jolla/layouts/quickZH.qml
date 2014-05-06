import QtQuick 2.0
import Sailfish.Silica 1.0
import "quickZH"
import ".."

KeyboardLayout {
    type: "quickZH"
    
    QuickHandler {
        id: quickHandler
        z: 512
    }
    
    Component.onCompleted: init()
    
    Connections {
        target: keyboard
        onInputHandlerChanged: handlerChanged()
    }
    
    function init() {
        // force onInputHandlerChanged signal by
        // making sure that the input handler was not
        // previously pasteInputHandler
        if (keyboard.allowLayoutChanges) {
            var oldHandler = keyboard.inputHandler
            keyboard.inputHandler = xt9Handler.item
            oldHandler.active = false
            keyboard.inputHandler.active = true
        }
    }
    
    function handlerChanged() {
        if (keyboard.allowLayoutChanges && keyboard.inputHandler == pasteInputHandler &&
                canvas.layoutRow.layout != null && canvas.layoutRow.layout.type == type) {
            var oldHandler = keyboard.inputHandler
            keyboard.inputHandler = quickHandler
            oldHandler.active = false
            quickHandler.active = true
        }
    }
    
    KeyboardRow {
        z: 0
        CharacterKey { z: 2; caption: "手"; captionShifted: "Q"; symView: "1"; symView2: "€" }
        CharacterKey { caption: "田"; captionShifted: "W"; symView: "2"; symView2: "£" }
        CharacterKey { caption: "水"; captionShifted: "E"; symView: "3"; symView2: "$"; accents: "eèéêë€"; accentsShifted: "EÈÉÊË€" }
        CharacterKey { caption: "口"; captionShifted: "R"; symView: "4"; symView2: "¥" }
        CharacterKey { caption: "廿"; captionShifted: "T"; symView: "5"; symView2: "₹"; accents: "tþ"; accentsShifted: "TÞ" }
        CharacterKey { caption: "卜"; captionShifted: "Y"; symView: "6"; symView2: "%"; accents: "yý¥"; accentsShifted: "YÝ¥" }
        CharacterKey { caption: "山"; captionShifted: "U"; symView: "7"; symView2: "<"; accents: "uûùúü"; accentsShifted: "UÛÙÚÜ" }
        CharacterKey { caption: "戈"; captionShifted: "I"; symView: "8"; symView2: ">"; accents: "iîïìí"; accentsShifted: "IÎÏÌÍ" }
        CharacterKey { caption: "人"; captionShifted: "O"; symView: "9"; symView2: "["; accents: "oöôòó"; accentsShifted: "OÖÔÒÓ" }
        CharacterKey { caption: "心"; captionShifted: "P"; symView: "0"; symView2: "]" }
    }

    KeyboardRow {
        CharacterKey { caption: "日"; captionShifted: "A"; symView: "*"; symView2: "`"; accents: "aäàâáãå"; accentsShifted: "AÄÀÂÁÃÅ"}
        CharacterKey { caption: "尸"; captionShifted: "S"; symView: "#"; symView2: "^"; accents: "sß$"; accentsShifted: "S$" }
        CharacterKey { caption: "木"; captionShifted: "D"; symView: "+"; symView2: "|"; accents: "dð"; accentsShifted: "DÐ" }
        CharacterKey { caption: "火"; captionShifted: "F"; symView: "-"; symView2: "_" }
        CharacterKey { caption: "土"; captionShifted: "G"; symView: "="; symView2: "§" }
        CharacterKey { caption: "竹"; captionShifted: "H"; symView: "("; symView2: "{" }
        CharacterKey { caption: "十"; captionShifted: "J"; symView: ")"; symView2: "}" }
        CharacterKey { caption: "大"; captionShifted: "K"; symView: "!"; symView2: "¡" }
        CharacterKey { caption: "中"; captionShifted: "L"; symView: "?"; symView2: "¿" }
    }

    KeyboardRow {
        ShiftKey { }
        
        CharacterKey { caption: "難"; captionShifted: "Z"; symView: "@"; symView2: "«" }
        CharacterKey { caption: "重"; captionShifted: "X"; symView: "&"; symView2: "»" }
        CharacterKey { caption: "金"; captionShifted: "C"; symView: "/"; symView2: "\""; accents: "cç"; accentsShifted: "CÇ" }
        CharacterKey { caption: "女"; captionShifted: "V"; symView: "\\"; symView2: "“" }
        CharacterKey { caption: "月"; captionShifted: "B"; symView: "'"; symView2: "”" }
        CharacterKey { caption: "弓"; captionShifted: "N"; symView: ";"; symView2: "„"; accents: "nñ"; accentsShifted: "NÑ" }
        CharacterKey { caption: "一"; captionShifted: "M"; symView: ":"; symView2: "~" }

        BackspaceKey {}
    }
    
    SpacebarRow { }
}
