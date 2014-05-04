import QtQuick 2.0
//import com.meego.maliitquick 1.0
import Sailfish.Silica 1.0
import com.jolla.keyboard 1.0
import ".."
import "../.."
import QtQuick.LocalStorage 2.0
import "quickParser.js" as Parser

InputHandler {
    
    property string preedit
    property var trie
    property bool trie_built: false 
    	
	ListModel {
		id: candidateList
		
		ListElement {
		    candidate: ""
		}
	}

    topItem: Row {
        	
		SilicaListView {
		    id: listView
		    orientation: ListView.Horizontal
		    width: parent.width
		    height: 80
		    
		    model: candidateList
		    
		    delegate: BackgroundItem {
		        id: backGround
		        onClicked: {
		        	commit(model.candidate)
		        	Parser.loadAW(model.candidate)
		        }
		        width: candidateText.width + Theme.paddingLarge * 2
		        height: parent ? parent.height : 0

		        Text {
		            id: candidateText
		            anchors.centerIn: parent
		            color: (backGround.down || index === 0) ? Theme.highlightColor : Theme.primaryColor
		            font { pixelSize: Theme.fontSizeSmall; family: Theme.fontFamily }
		            text: candidate
		        }
		    }
		/*================ ADD THESE LINES BELOW ================*/    
			Connections {
	            	target: candidateList
	            	onCandidatesUpdated: listView.positionViewAtBeginning()
			}

		}
		/*================ THE END ================*/   
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
			//loadQK(preedit)
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
            Parser.loadQK(preedit)
            
            handled = true
        } else {
            commit(pressedKey.text)
        }

        return handled
    }
    
    function accept(index) {
        console.log("attempting to accept", index)
        //loadQK(preedit)
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
