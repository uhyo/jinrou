/*
JINROU data recoverer:
adds 'realid'!

Contains a great deal of hard-coding...

*/
var user="test", password="test";	//自分で密码を入れてね

var mongo=require('mongodb');
var db=new mongo.Db("werewolf",new mongo.Server("localhost",27017));

db.open(function(err,client){
	if(err)console.log(err);
	db.authenticate(user,password,function(err){
		if(err)console.log(err);
		db.collection("games",function(err,col){
			if(err)console.log(err);
			getdb(col);
		});
		db.collection("rooms",function(err,col){
			if(err)console.log(err);
			getrm(col);
		});
	});
});

function getdb(games){
	games.find({}).toArray(function(err,docs){
		if(err)console.log(err);
		docs.forEach(function(game){
			console.log("GAME - "+game.id);
			game.players.forEach(function(pl){
				console.log(pl.id+":"+pl.realid);
				if(!pl.realid){
					pl.realid=pl.id;
				}
			});
			games.update({id:game.id},game);
		});
	});
}
function getrm(rooms){
	rooms.find({}).toArray(function(err,docs){
		if(err)console.log(err);
		docs.forEach(function(room){
			console.log("ROOM - "+room.id);
			room.players.forEach(function(pl){
				console.log(pl.userid+":"+pl.realid);
				if(!pl.realid){
					pl.realid=pl.userid;
				}
			});
			rooms.update({id:room.id},room);
		});
	});}
