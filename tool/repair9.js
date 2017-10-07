/*
 * JINROU data fixer 9
 * Add all data into userrawlogs.
 */
var user="test", password="test";	//自分でパスワードを入れてね
var db = "werewolf";

var mongo = require('mongodb');

connect()
.then(db=>{
    return Promise.resolve()
    .then(_=> Promise.all([getCollection(db, 'games'), getCollection(db, 'userrawlogs')]))
    .then(handleColls);
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
function handleColls([games, userrawlogs]){
    console.log('Scanning the games collection.');
    let insert_count = 0;
    let game_count = 0;
    return new Promise((resolve, reject)=>{
        const cur = games.find({
            finished: true,
            winner: {$ne: null},
        }, {
            id: true,
            players: true,
            gamelogs: true,
        });

        cur.each((err, doc)=>{
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
                gamelogs,
            } = doc;

            // 各Playerのログ
            const insert_docs = [];
            for (const {
                realid,
                originalType,
                winner,
            } of players){
                // TODO
            }
        });
    });
}
