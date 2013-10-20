/*
JINROU data fixer
Counts all userlogs.

*/
var prize=require('./repair6-prize');
var user="test", password="test";	//自分でパスワードを入れてね

var mongo=require('mongodb');
mongo.MongoClient.connect('mongodb://'+user+':'+password+'@localhost:27017/werewolf?w=1',function(err,db){
	db.collection("games",function(err,games){
		if(err)console.log(err);
		db.collection("users",function(err,users){
			if(err)console.log(err);
			db.collection("userlogs",function(err,userlogs){
				if(err)console.log(err);
				userlogs.ensureIndex({"userid":1},function(err,idxname){
					if(err)console.log(err);
					getdb(db,games,users,userlogs);
				});
			});
		});
	});
});

function getdb(db,games,users,userlogs){
	console.log("start.");
	users.find().count(function(err,number){
		console.log("user number:"+number);
		queries={};	//(userid):query
		var gamecount=0,gameare=10;
		var cp=prize.counterprize,getOriginalType=prize.getOriginalType,getTeamByType=prize.getTeamByType;
		games.find({finished:true}).each(function(err,game){
			if(err){
				throw err;
			}
			if(game==null){
				//全部終わった
				update(queries);
				return;
			}
			game.players.forEach(function(pl){
				if(pl.realid==="身代わりくん")return;
				var q=queries[pl.realid];
				if(q==null){
					queries[pl.realid]=q={
						userid:pl.realid,
						wincount:{},
						losecount:{},
						winteamcount:{},
						loseteamcount:{},
						counter:{},
					};
				}
				var type=getOriginalType(game,pl.id);
				var team=getTeamByType(type);
				if(pl.winner===true){
					q.wincount.all=(q.wincount.all||0)+1;
					q.wincount[type]=(q.wincount[type]||0)+1;
					q.winteamcount[team]=(q.winteamcount[team]||0)+1;
				}else if(pl.winner===false){
					q.losecount.all=(q.losecount.all||0)+1;
					q.losecount[type]=(q.losecount[type]||0)+1;
					q.loseteamcount[team]=(q.loseteamcount[team]||0)+1;
				}
				//counter
				for(var key in cp){
					var obj=cp[key];
					var va=obj.func(game,pl);
					if(va){
						q.counter[key]=(q.counter[key]||0)+va;
					}
				}
			});
			//ひとつOK!
			gamecount++;
			if(gamecount%gameare === 0){
				console.log(gamecount+" game done.");
			}
		});
		function update(queries){
			console.log("updating.");
			//まず全部抜く
			userlogs.remove({},function(err,num){
				if(err)throw err;
				console.log(num+" old userlogs removed.");
				//インサートする
				var ins=[];
				for(var uid in queries){
					ins.push(queries[uid]);
				}
				userlogs.insert(ins,{safe:true},function(err,docs){
					console.log(ins.length+" new userlogs inserted.");
					console.log("done.");
					db.close();
				});
			});
		}
	});
}
