function loadQK(quick) {

	var db = LocalStorage.openDatabaseSync("quickZH", "1.0", "", 100000);

	db.transaction(
	    function(tx) {

	        quick = '"'+ quick +'%"';
	        var sql = 'SELECT character FROM quickTable WHERE quick LIKE '+ quick + ' ORDER BY frequency DESC LIMIT 0, 512';
	        var rs = tx.executeSql(sql);
	        candidateList.clear();
	        for ( var i = 0; i < rs.rows.length; i++ ) {
	            candidateList.append( { "candidate": rs.rows.item(i).character } );

	        }
	    }
	)
}

function loadAW(character) {

    var db = LocalStorage.openDatabaseSync("quickZH", "1.0", "", 100000);

    db.transaction(
        function(tx) {
            character = '"' + character + '"';
            var sql = 'SELECT phrase FROM assoWord WHERE character='+ character + ' LIMIT 0, 64';
            var rs = tx.executeSql(sql);
            candidateList.clear();
            for ( var i = 0; i < rs.rows.length; i++ ) {
                candidateList.append( { "candidate": rs.rows.item(i).phrase } );
            }
        }
    )
}
