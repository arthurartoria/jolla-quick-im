import QtQuick 2.0
import Sailfish.Silica 1.0
import "quickZH"
import ".."
import QtQuick.LocalStorage 2.0

KeyboardLayout {
    type: "quickZH"
	
    InputHandler {
	id: quickHandler
    property string preedit
    property var trie
    property bool trie_built: false

    ListModel {
        id: candidateList
 
        ListElement {
            candidate: ""
        }

        signal candidatesUpdated

        function loadQK(quick) {

			var db = LocalStorage.openDatabaseSync("quickZH", "1.0", "", 100000);

			db.transaction(
				function(tx) {

					quick = '"'+ quick +'%"';
					var sql = 'SELECT character FROM quickTable WHERE quick LIKE '+ quick + ' ORDER BY frequency DESC LIMIT 0, 256';
					var rs = tx.executeSql(sql);
					candidateList.clear();
					for ( var i = 0; i < rs.rows.length; i++ ) {
						candidateList.append( { "candidate": rs.rows.item(i).character } );
				}

				candidatesUpdated()

				}
			)
		}

		function loadAW(character) {

			var db = LocalStorage.openDatabaseSync("quickZH", "1.0", "", 100000);

			db.transaction(
				function(tx) {
					character = '"' + character + '"';
					var sql = 'SELECT phrase FROM assoWord WHERE character='+ character + ' ORDER BY frequency DESC LIMIT 0, 128';
					var rs = tx.executeSql(sql);
					candidateList.clear();
					for ( var i = 0; i < rs.rows.length; i++ ) {
						candidateList.append( { "candidate": rs.rows.item(i).phrase } );
					}

					candidatesUpdated()
				}
			)
		}
		
		function pushQK(character) {
			var db = LocalStorage.openDatabaseSync("quickZH", "1.0", "", 100000);

			db.transaction(
				function(cm) {
					character = '"' + character + '"';
					var sql = 'UPDATE quickTable SET frequency=frequency+20 WHERE character='+ character;
					var rs = cm.executeSql(sql);
				}
			)
		}

		function pushAW(phrase) {
			var db = LocalStorage.openDatabaseSync("quickZH", "1.0", "", 100000);

			db.transaction(
				function(cm) {
					phrase = '"' + phrase + '"';
					var sql = 'UPDATE assoWord SET frequency=frequency+20 WHERE phrase='+ phrase;
					var rs = cm.executeSql(sql);
				}
			)
		}
    }

    topItem: Row {

        SilicaListView {
            id: listView
            orientation: ListView.Horizontal
            width: parent.width - 64
            height: 80
			clip: true
			z: 256
			
            model: candidateList

            delegate: BackgroundItem {
                id: listBack
                onClicked: {
				
					if ( preedit !== "" ) {
						commit(model.candidate)
						candidateList.pushQK(model.candidate)
						candidateList.loadAW(model.candidate)
					} else {
						commit(model.candidate)
						candidateList.pushAW(model.candidate)
						candidateList.loadAW(model.candidate)
					}
                }
                width: listText.width + Theme.paddingLarge * 2
                height: parent ? parent.height : 0

                Text {
                    id: listText
                    anchors.centerIn: parent
                    color: (listBack.down || index === 0) ? Theme.highlightColor : Theme.primaryColor
                    font { pixelSize: Theme.fontSizeSmall; family: Theme.fontFamily }
                    text: candidate
                }
            }
            Connections {
                target: candidateList
                onCandidatesUpdated: listView.positionViewAtBeginning()
            }
        }
		
		Button {
			height: 80
			width: 64
			text: "…"
			z: 512
			onClicked: {
				if ( gridView.visible == false ) {
					gridView.visible = true;
					rowI.visible = false;
				} else {
					gridView.visible = false;
				}
			}			
		}
		
    }
	
	SilicaGridView {
		id: gridView
		width: parent.width
		height: 400
		model: candidateList
		visible: false
		z: 256
		clip: true
				
		delegate: Rectangle {
			id: gridBack
			width: gridText.width + Theme.paddingLarge * 2
			height: 80
			color: "#000000"
			z: 420
			
			MouseArea {
				anchors.fill: parent
				onClicked: {
				
					if ( preedit !== "" ) {
						commit(model.candidate)
						candidateList.pushQK(model.candidate)
						candidateList.loadAW(model.candidate)
						gridView.visible = false
					} else {
						commit(model.candidate)
						candidateList.pushAW(model.candidate)
						candidateList.loadAW(model.candidate)
						gridView.visible = false
					}
				}	
			}

			Text {
				id: gridText
				anchors.centerIn: parent
				color: (gridBack.down || index === 0) ? Theme.highlightColor : Theme.primaryColor
				font { pixelSize: Theme.fontSizeSmall; family: Theme.fontFamily }
				text: candidate
				z: 480
			}
		}
	}

    function handleKeyClick() {
        var handled = false
        keyboard.expandedPaste = false

        if (pressedKey.key === Qt.Key_Space) {
            if (preedit !== "") {
                accept(0)

                if (keyboard.shiftState !== ShiftState.LockedShift) {
                    keyboard.shiftState = ShiftState.AutoShift
                }

                handled = true
            }
        } else if (pressedKey.key === Qt.Key_Return) {
            if (preedit !== "") {
                commit(preedit)
                handled = true
            }
        } else if (pressedKey.key === Qt.Key_Backspace && preedit !== "") {
            preedit = preedit.slice(0, preedit.length-1)
            MInputMethodQuick.sendPreedit(preedit)

            if (keyboard.shiftState !== ShiftState.LockedShift) {
                keyboard.shiftState = ShiftState.NoShift
            }

            handled = true
        } else if (pressedKey.text.length !== 0 && pressedKey.text !== "，" && pressedKey.text !== "。") {
            preedit = preedit + pressedKey.text


            if (keyboard.shiftState !== ShiftState.LockedShift) {
                keyboard.shiftState = ShiftState.NoShift
            }

            MInputMethodQuick.sendPreedit(preedit)
            candidateList.loadQK(preedit)

            handled = true
        } else {
            commit(pressedKey.text)
        }

        return handled
    }

    function accept(index) {
        console.log("attempting to accept", index)
    }

    function reset() {
        preedit = ""
    }

    function commit(text) {
        MInputMethodQuick.sendCommit(text)
        reset()
    }

    function empty() {
        candidateList.clear()
    }

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
		id: rowI
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
