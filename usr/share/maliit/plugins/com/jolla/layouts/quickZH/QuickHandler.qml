import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.keyboard 1.0
import ".."
import "../.."
import QtQuick.LocalStorage 2.0

InputHandler {
	id: inputHandler
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
			onClicked: {
				if ( gridView.visible == false ) {
					gridView.visible = true;
				} else {
					gridView.visible = false;
				}
			}			
		}
		
    }
	
	SilicaGridView {
		id: gridView
		anchors.top: parent.top
		anchors.topMargin: 80
		anchors.bottom: parent.bottom
		model: candidateList
		visible: false
		z: 256
		
		delegate: BackgroundItem {
			id: gridBack
			width: gridText.width + Theme.paddingLarge * 2
			height: parent ? parent.height : 0
			
			onClicked: {
			
		id: gridView
		width: parent.width
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

			Text {
				id: gridText
				anchors.centerIn: parent
				color: (gridBack.down || index === 0) ? Theme.highlightColor : Theme.primaryColor
				font { pixelSize: Theme.fontSizeSmall; family: Theme.fontFamily }
				text: candidate
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
