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
    property bool keyboardVisible: true

    ListModel {
        id: candidateList

        ListElement {
            candidate: ""
        }

        signal candidatesUpdated

        function loadQK(quick) {

            var db = LocalStorage.openDatabaseSync("quickZH", "1.0", "", 100000);

            if ( quick.length > 1 ) {

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

            } else {

                db.transaction(
                    function(tx) {

                        quick = '"'+ quick +'"';
                        var sql = 'SELECT character FROM quickTable WHERE quick = '+ quick;
                        var rs = tx.executeSql(sql);
                        candidateList.clear();
                        for ( var i = 0; i < rs.rows.length; i++ ) {
                            candidateList.append( { "candidate": rs.rows.item(i).character } );
                    }

                    candidatesUpdated()

                    }

                )
            }
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

    topItem: Column {
        width: parent.width

        Row {
            width: parent.width
            height: 80
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
                    width: listText.width + Theme.paddingLarge * 2
                    height: parent.height
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
                id: button
                height: 80
                width: 64
                text: "…"
                z: 512

                onClicked: {
                    if ( inputHandler.keyboardVisible == true ) {
                        listView.opacity = 0
                        inputHandler.keyboardVisible = false
                        gridView.visible = true
                        gridView.opacity = 1
                    } else {
                        gridView.visible = false
                        gridView.opacity = 0
                        listView.opacity = 1
                        inputHandler.keyboardVisible = true
                    }
                }
            }
        }

        Flickable {
            id: gridView
            width: parent.width
            height: 240
            contentWidth: parent.width
            contentHeight: flow.height
            anchors.top: listView.bottom
            interactive: true
            flickableDirection: Flickable.VerticalFlick
            clip: true
            visible: false
            opacity: 0

            Flow {
                id: flow
                width: parent.width

                Repeater {
                    model: candidateList

                    delegate: BackgroundItem {
                        id: gridBack
                        width: gridText.width + Theme.paddingLarge * 2
                        height: 80

                        onClicked: {

                            gridView.visible = false
                            gridView.opacity = 0
                            listView.opacity = 1
                            inputHandler.keyboardVisible = true

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
        } else if ( pressedKey.key === Qt.Key_Backspace ) {

            if ( preedit !== "" ) {
                preedit = preedit.slice(0, preedit.length-1)
                MInputMethodQuick.sendPreedit(preedit)
            } else {
                MInputMethodQuick.sendKey(Qt.Key_Backspace)
            }

            if (keyboard.shiftState !== ShiftState.LockedShift) {
                keyboard.shiftState = ShiftState.NoShift
            }

            handled = true
        } else if ( pressedKey.text.length > 0 && pressedKey.text.match(/[日月金木水火土竹戈十大中一弓人心手口尸廿山女田卜難重]/) !== null ) {

            if ( preedit.length <= 1 ) {
                preedit = preedit + pressedKey.text
            } else {
                reset()
            }

            if (keyboard.shiftState !== ShiftState.LockedShift) {
                keyboard.shiftState = ShiftState.NoShift
            }

            MInputMethodQuick.sendPreedit(preedit)
            candidateList.loadQK(preedit)

            handled = true
        } else {
            commit(pressedKey.text)
            handled = true

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
