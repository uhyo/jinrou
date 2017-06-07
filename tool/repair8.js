/*
JINROU data fixer 8
remove duplicate documents in db.

This script will output logs to `./duplicatelogs.json`
*/
var user="test", password="test";	//自分でパスワードを入れてね
var db = "werewolf";

var fs = require('fs');
var assert = require('assert');
var mongo = require('mongodb');

const logs = {};
connect()
.then(db=>{
    return Promise.resolve()
    .then(_=> getCollection(db, 'users'))
    .then(handleUsers)
    .then(_=> getCollection(db, 'rooms'))
    .then(handleRooms)
    .then(_=> getCollection(db, 'games'))
    .then(handleGames)
    .then(_=> getCollection(db, 'userlogs'))
    .then(handleUserlogs);
})
.catch(err=>{
    console.error(err);
})
.then(()=>{
    fs.writeFileSync('./duplicatelogs.json', JSON.stringify(logs), {
        encoding: 'utf8',
    });
    process.exit(0);
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

function handleUsers(users){
    console.log('Started scanning the users collection.');
    logs.users = [];

    // pending removals.
    const removes = [];
    // pending updates.
    const updates = [];

    return new Promise((resolve, reject)=>{
        const cur = users.find({}, {
            sort: {
                userid: 1,
            },
        });
        let previd = null;
        let cnt = 0;
        let prevdocs = [];
        cur.each((err, doc)=>{
            if (err){
                reject(err);
                return;
            }
            if (doc == null){
                // end
                if (cnt > 1){
                    // previous doc was duplicate
                    handleDuplicate(prevdocs);
                }
                resolve(modify().then(index));
                return;
            }
            const userid = doc.userid;
            if (previd !== userid){
                // not duplicate.

                if (cnt > 1){
                    // previous doc was duplicate
                    handleDuplicate(prevdocs);
                }
                cnt = 1;
                prevdocs = [doc];
            }else{
                // duplicate.
                cnt++;
                prevdocs.push(doc);
            }

            previd = doc.userid;
        });
    });
    function handleDuplicate(docs){
        logs.users.push(docs);
        console.log('duplicate %s %d', docs[0].userid, docs.length);

        // determine which one is latest, based on `win`, `lose`, `gone`.
        let max = -1;
        let idx = -1;
        const winall = [];
        const loseall = [];
        const goneall = [];
        for (let i = 0; i < docs.length; i++){
            const doc = docs[i];
            doc.win.forEach(num=>{
                winall.push(num);
                if (max < num){
                    max = num;
                    idx = i;
                }
            });
            doc.lose.forEach(num=>{
                loseall.push(num);
                if (max < num){
                    max = num;
                    idx = i;
                }
            });
            doc.gone.forEach(num=>{
                goneall.push(num);
                if (max < num){
                    max = num;
                    idx = i;
                }
            });
        }
        if (idx < 0){
            idx = 0;
        }

        // determine 'main' document.
        const main = docs[idx];

        const new_winall = sortuniq(winall);
        const new_loseall = sortuniq(loseall);
        const new_goneall = sortuniq(goneall);

        // register non-main documents for removal.
        for (let i = 0; i < docs.length; i++){
            if (i === idx){
                continue;
            }
            removes.push(docs[i]._id);
        }
        // update the main document.
        // prize will be recovered after one game.
        updates.push([
            { _id: main._id },
            { $set: {
                win: new_winall,
                lose: new_loseall,
                gone: new_goneall,
            }},
        ]);
    }
    function modify(){
        console.log('removing duplicate users.');
        return new Promise((resolve, reject)=>{
            users.remove({
                _id: {$in: removes},
            }, (err, result)=>{
                if (err){
                    reject(err);
                }else{
                    console.log(result);
                    console.log('updating user documents.');
                    const l = updates.length;
                    const h = (i)=>{
                        if (i >= l){
                            console.log('updated %d documents.', i);
                            resolve();
                            return;
                        }
                        users.update(updates[i][0], updates[i][1], (err)=>{
                            if (err){
                                reject(err);
                            }else{
                                h(i+1);
                            }
                        });
                    };
                    h(0);
                }
            });
        });
    }
    function index(){
        // re-index.
        return Promise.resolve();
        /*
        return new Promise((resolve, reject)=>{
            users.listIndexes().toArray((err, docs)=>{
                if (err){
                    reject(err);
                }else{
                    console.log(docs);
                    const l = docs.length;
                    const h = i=>{
                        if (i >= l){
                            resolve();
                            return;
                        }
                        try {
                            assert.deepEqual(docs[i].key, {
                                id: 1,
                            });
                            // this index should be uniquified
                            users.dropIndex(docs[i].name, (err)=>{
                                if (err){
                                    reject(err);
                                }else{
                                    users.createIndex({
                                        id: 1,
                                    }, {
                                        unique: true,
                                        background: true,
                                        name: docs[i].name,
                                    }, err=>{
                                        if (err){
                                            reject(err);
                                        }else{
                                            console.log('created a unique index in the users collection.');
                                            h(i+1);
                                        }
                                    });
                                }
                            });
                            return;
                        } catch(_){
                        }
                        h(i+1);
                    };
                    h(0);
                }
            });
        });
       */
    }
}
function handleRooms(rooms){
    console.log('Started scanning the rooms collection.');
    // removes
    const removes = [];

    return new Promise((resolve, reject)=>{
        const cur = rooms.find({}, {
            fields: {
                _id: 1,
                id: 1,
            },
            sort: {
                id: 1,
            },
        });
        let previd = null;
        let cnt = 0;
        let prevdocs = [];
        cur.each((err, doc)=>{
            if (err){
                reject(err);
                return;
            }
            if (doc == null){
                // end
                if (cnt > 1){
                    // previous doc was duplicate
                    handleDuplicate(prevdocs);
                }
                resolve(modify());
                return;
            }
            const id = doc.id;
            if (previd !== id){
                // not duplicate.

                if (cnt > 1){
                    // previous doc was duplicate
                    handleDuplicate(prevdocs);
                }
                cnt = 1;
                prevdocs = [doc];
            }else{
                // duplicate.
                cnt++;
                prevdocs.push(doc);
            }

            previd = id;
        });
    });
    function handleDuplicate(docs){
        console.log('duplicate %d %d', docs[0].id, docs.length);

        // take first
        for (let i = 1; i < docs.length; i++){
            removes.push(docs[i]._id);
        }
    }
    function modify(){
        console.log('removing duplicate rooms.');
        return new Promise((resolve, reject)=>{
            rooms.remove({
                _id: {$in: removes},
            }, (err, result)=>{
                if (err){
                    reject(err);
                }else{
                    console.log(result);
                    resolve();
                }
            });
        });
    }
}
function handleGames(games){
    console.log('Started scanning the games collection.');
    // removes
    const removes = [];

    return new Promise((resolve, reject)=>{
        const cur = games.find({}, {
            fields: {
                _id: 1,
                id: 1,
            },
            sort: {
                id: 1,
            },
        });
        let previd = null;
        let cnt = 0;
        let prevdocs = [];
        cur.each((err, doc)=>{
            if (err){
                reject(err);
                return;
            }
            if (doc == null){
                // end
                if (cnt > 1){
                    // previous doc was duplicate
                    handleDuplicate(prevdocs);
                }
                resolve(modify());
                return;
            }
            const id = doc.id;
            if (previd !== id){
                // not duplicate.

                if (cnt > 1){
                    // previous doc was duplicate
                    handleDuplicate(prevdocs);
                }
                cnt = 1;
                prevdocs = [doc];
            }else{
                // duplicate.
                cnt++;
                prevdocs.push(doc);
            }

            previd = id;
        });
    });
    function handleDuplicate(docs){
        console.log('duplicate %d %d', docs[0].id, docs.length);

        // take first
        for (let i = 1; i < docs.length; i++){
            removes.push(docs[i]._id);
        }
    }
    function modify(){
        console.log('removing duplicate games.');
        return new Promise((resolve, reject)=>{
            games.remove({
                _id: {$in: removes},
            }, (err, result)=>{
                if (err){
                    reject(err);
                }else{
                    console.log(result);
                    resolve();
                }
            });
        });
    }
}
function handleUserlogs(userlogs){
    console.log('Started scanning the userlogs collection.');
    // removes
    const removes = [];
    // updates
    const updates = [];

    return new Promise((resolve, reject)=>{
        const cur = userlogs.find({}, {
            sort: {
                userid: 1,
            },
        });
        let previd = null;
        let cnt = 0;
        let prevdocs = [];
        cur.each((err, doc)=>{
            if (err){
                reject(err);
                return;
            }
            if (doc == null){
                // end
                if (cnt > 1){
                    // previous doc was duplicate
                    handleDuplicate(prevdocs);
                }
                resolve(modify());
                return;
            }
            const id = doc.userid;
            if (previd !== id){
                // not duplicate.

                if (cnt > 1){
                    // previous doc was duplicate
                    handleDuplicate(prevdocs);
                }
                cnt = 1;
                prevdocs = [doc];
            }else{
                // duplicate.
                cnt++;
                prevdocs.push(doc);
            }

            previd = id;
        });
    });
    function handleDuplicate(docs){
        console.log('duplicate %s %d', docs[0].userid, docs.length);
        // merge into one object
        const doc = merge(docs);
        doc._id = docs[0]._id;

        // replace first, remove others
        updates.push([
            { _id: doc._id },
            doc,
        ]);
        for (let i = 1; i < docs.length; i++){
            removes.push(docs[i]._id);
        }
    }
    function merge(docs){
        const result = {
            userid: docs[0].userid,
        };
        docs.forEach(doc=>{
            m(doc, 'wincount');
            m(doc, 'winteamcount');
            m(doc, 'counter');
            m(doc, 'losecount');
            m(doc, 'loseteamcount');
        });
        return result;
        function m(doc, field){
            const obj = doc[field];
            if (obj == null){
                return;
            }
            if (result[field] == null){
                result[field] = {};
            }
            const ro = result[field];
            for (const key in obj){
                const num = obj[key];
                if ('number' !== typeof num){
                    continue;
                }
                if ('number' !== typeof ro[key]){
                    ro[key] = num;
                }else{
                    ro[key] += num;
                }
            }
        }
    }
    function modify(){
        console.log('removing duplicate userlogs.');
        return new Promise((resolve, reject)=>{
            userlogs.remove({
                _id: {$in: removes},
            }, (err, result)=>{
                if (err){
                    reject(err);
                }else{
                    console.log('removed %d documents.', result);
                    const l = updates.length;
                    const h = (i)=>{
                        if (i >= l){
                            console.log('updated %d documents.', i);
                            resolve();
                            return;
                        }
                        userlogs.update(updates[i][0], updates[i][1], (err)=>{
                            if (err){
                                reject(err);
                            }else{
                                h(i+1);
                            }
                        });
                    };
                    h(0);
                    resolve();
                }
            });
        });
    }
}

/**
 * Return a new array which is sorted & uniqued.
 * The original array will be sorted.
 */
function sortuniq(arr){
    arr.sort();
    const result = [];
    let prev = null;
    for (let i = 0; i < arr.length; i++){
        const v = arr[i];
        if (v !== prev){
            result.push(v);
        }
        prev = v;
    }
    return result;
}

