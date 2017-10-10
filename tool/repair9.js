/*
 * JINROU data fixer 9
 * 1. Add `finish_time` field to games.
 * 2. Add all data into userrawlogs.
 */
var user="test", password="test";	//自分でパスワードを入れてね
var db = "werewolf";

var mongo = require('mongodb');

connect()
.then(db=>{
    return Promise.resolve()
    .then(_=> Promise.all([getCollection(db, 'rooms'), getCollection(db, 'games'), getCollection(db, 'userrawlogs')]))
    .then(([rooms, games, userrawlogs])=>
          Promise.resolve()
          .then(_=> handleRooms(rooms, games))
          .then(_=> handleColls(games, userrawlogs)))
    .then(_=> db.close(),
         err=>( db.close(), Promise.reject(err)));
})
.catch(err=>{
    console.error(err);
});

function connect(){
    return new Promise((resolve, reject)=>{
        mongo.MongoClient.connect('mongodb://'+user+':'+password+'@localhost:27017/'+db+'?w=1',function(err,db){
            if (err){
                reject(err);
            }else{
                resolve(db);
            }
        });
    });
}
function getCollection(db, name){
    return new Promise((resolve, reject)=>{
        db.collection(name, (err,coll)=>{
            if(err){
                reject(err);
            }else{
                resolve(coll);
            }
        });
    });
}
function handleRooms(rooms, games){
    console.log('Scanning the rooms collection.');
    return new Promise((resolve, reject)=>{
        let updated = 0;
        let count = 0;
        const cur = rooms.find({
            mode: "end",
        }, {
            id: true,
            made: true,
        });
        const step = ()=>{
            cur.nextObject((err, doc)=>{
                if (err){
                    reject(err);
                    return;
                }
                if (doc == null){
                    console.log(`Updated ${updated} game docs.`);
                    resolve();
                    return;
                }
                const {
                    id,
                    made,
                } = doc;
                games.update({
                    id,
                    winner: {$ne: null},
                    finish_time: {$exists: false},
                }, {
                    $set: {
                        finish_time: new Date(made),
                    },
                }, (err, num)=>{
                    if (err){
                        reject(err);
                        return;
                    }
                    updated += num;
                    count++;
                    if (count % 100 === 0){
                        console.log(`Scanned ${count} rooms, updated ${updated} docs`);
                    }
                    step();
                });
            });
        };
        step();
    });
}
function handleColls(games, userrawlogs){
    console.log('Scanning the games collection.');
    return new Promise((resolve, reject)=>{
        let insert_count = 0;
        let game_count = 0;
        const cur = games.find({
            finished: true,
            winner: {$ne: null},
        }, {
            id: true,
            players: true,
            additionalParticipants: true,
            gamelogs: true,
            winner: true,
            finish_time: true,
        }, {
		sort: [['id', 1]],
	});

        const step = ()=>{
            cur.nextObject((err, doc)=>{
                if (err){
                    reject(err);
                    return;
                }
                if (doc == null){
                    console.log(`Inserted ${insert_count} items.`);
                    resolve();
                    return;
                }
                // このgameに対応するuserrawlogを入れる
                const {
                    id,
                    players,
                    additionalParticipants,
                    gamelogs,
                    winner: gwinner,
                    finish_time,
                } = doc;

                // 各Playerのログ
                const insert_docs = [];
		let dups={};
                // 同時にid-realid対応表
                const realids={};
                for (const {
                    id: plid,
                    realid,
                    originalType,
                    winner,
                } of players){
                    realids[plid]=realid;
		    if (dups[realid]) continue;
			dups[realid]=true;
                    if (gwinner === 'Draw'){
                        insert_docs.push({
                            userid: realid,
                            type: 1, //DataTypes.game
                            subtype: 'draw',
                            gameid: id,
                            job: originalType,
                            timestamp: finish_time,
                        });
                    } else if ('boolean' === typeof winner){
                        insert_docs.push({
                            userid: realid,
                            type: 1, //DataTypes.game
                            subtype: winner ? 'win' : 'lose',
                            gameid: id,
                            job: originalType,
                            timestamp: finish_time,
                        });
                    }
                }
		if (additionalParticipants){
			for (const {
				id: plid,
			    realid,
			    originalType,
			} of additionalParticipants){
				realids[plid]=realid;
				if(dups[realid]) continue;
				dups[realid]=true;
			    if (originalType === 'GameMaster'){
				insert_docs.push({
				    userid: realid,
				    type: 1,
				    subtype: 'gm',
				    gameid: id,
				    job: originalType,
				    timestamp: finish_time,
				});
			    } else if (originalType === 'Helper'){
				insert_docs.push({
				    userid: realid,
				    type: 1,
				    subtype: 'helper',
				    gameid: id,
				    job: originalType,
				    timestamp: finish_time,
				});
			    }
			}
		}
                // gamelogs
		dups={};
                for (const {
                    id: plid,
                    type,
                    event,
                    flag,
                } of gamelogs){
                    if (event === 'found' && (flag === 'gone-day' || flag === 'gone-night')){
			if(dups[realids[plid]])continue;
dups[realids[plid]]=true;
                        insert_docs.push({
                            userid: realids[plid],
                            type: 2, //DataTypes.gone
                            subtype: null,
                            gameid: id,
                            job: type,
                            timestamp: finish_time,
                        });
                    }
                }
                insert_count += insert_docs.length;
                game_count++;

                userrawlogs.insert(insert_docs, (err)=>{
                    if (err){
			console.error('err!');
			console.error(insert_docs);
                        reject(err);
                        return;
                    }
                    if (game_count % 100 === 0){
                        console.log(`${game_count} games processed, ${insert_docs.length} docs inserted`);
                    }
                    step();
                });
            });
        };
        step();
    });
}
