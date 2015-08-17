/*
JINROU data fixer 7
蘇生 and 信者.
*/
var user="test", password="test";	//自分で密码を入れてね

var mongo=require('mongodb');

var prizedata=require('../server/prizedata.js');

//prizedata.makePrize(function(data){
	mongo.MongoClient.connect('mongodb://'+user+':'+password+'@localhost:27017/werewolf?w=1',function(err,db){
		db.collection("games",function(err,games){
			if(err)console.log(err);
			getdb(db,games);
		});
	});
//});

function getdb(db,games){
	var savedGames={};
	console.log("start.");
	searchRevive();
	function searchRevive(){
		games.find({"logs.comment":/は蘇生しました。$/}).each(function(err,game){
			if(game==null){
				console.log("revive searched.");
				searchCult();
				return;
			}
			savedGames[game.id]=game;
		});
	}
	function searchCult(){
		games.find({"logs.comment":/を信者にしました。$/}).each(function(err,game){
			if(game==null){
				console.log(Object.keys(savedGames).length+" game found.");
				check();
				return;
			}
			savedGames[game.id]=game;
		});
	}
	function check(){
		console.log("updating.");
		var ids=Object.keys(savedGames);
		var modified=0;
		c();
		function c(){
			if(ids.length===0){
				//おわり
				done(modified);
				return;
			}
			var id=ids.pop();
			var game=savedGames[id];
			var p=[],query={"$push":{"gamelogs":{"$each":p}}}, flag=false;
			game.logs.forEach(function(log){
				if(log.mode==="skill"){
					var result;
					result=log.comment.match(/^(.+)は蘇生しました。$/);
					if(result){
						//蘇生
						var pl = getPlayerN(game,result[1]);
						if(pl){
							p.push({
								id:log.to,
								type:getType(pl),
								target:null,
								flag:null,
								event:"revive",
								day:2	//違うけど...
							});
							flag=true;
						}
					}else{
						result=log.comment.match(/^.+が(.+)を信者にしました。$/);
						if(result){
							var pl = getPlayerN(game,result[1]);
							if(pl){
								p.push({
									id:log.to,
									type:getType(pl),
									target:pl.id,
									flag:null,
									event:"brainwash",
									day:2	//違うけど...
								});
								flag=true;
							}
						}
					}
				}
			});
			if(flag){
				//クエリがある
				games.update({
					_id:game._id
				},query,{safe:true},function(err,doc){
					if(err)console.error(err);
					modified++;
					c();
				});
			}else{
				c();
			}
		}
	}
	function done(modified){
		console.log(modified+" games modified.");
		db.close();
	}
	function getPlayerN(game,name){
		for(var i=0,l=game.players.length;i<l;i++){
			var pl=game.players[i];
			if(pl.name===name)return pl;
		}
		return null;
	}
	function getType(pl){
		if(pl.type==="Complex" && pl.Complex_main){
			return getType(pl.Complex_main);
		}
		return pl.type;
	}
}
