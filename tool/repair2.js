/*
JINROU data recoverer:
adds 'winner' to each player 2011-12-26

*/
var user="test", password="test";	//自分で密码を入れてね

var mongo=require('mongodb');
var db=new mongo.Db("werewolf",new mongo.Server("localhost",27017));

//チーム分け
var wolves=["Werewolf","BigWolf","WolfDiviner","Madman"];
var foxes=["Fox","TinyFox"];


db.open(function(err,client){
	if(err)console.log(err);
	db.authenticate(user,password,function(err){
		if(err)console.log(err);
		db.collection("games",function(err,col){
			if(err)console.log(err);
			getdb(col);
		});
	});
});

function getdb(games){
	games.find({finished:true}).toArray(function(err,docs){
		if(err)console.log(err);
		docs.forEach(function(game){
			var gw=game.winner;
			console.log("GAME - "+game.id+"("+gw+")");
			game.players.forEach(function(pl){
				chk(pl);
			});
			function chk(pl){
				if(pl.winner==null){
					//pl.realid=pl.id;
					console.log(pl.id+":"+pl.winner+"("+pl.type+")");
					//winner判定
					switch(pl.type){
					case "Complex":
						chk(pl.Complex_main);
						pl.winner=pl.Complex_main.winner;
						break;
					case "Bat":
						pl.winner=!pl.dead;	//蝙蝠は死ななければOK
						break;
					case "Slave":
						pl.winner= gw=="Human" && !game.players.some(function(x){return !x.dead && x.type=="Noble"});
						break;
					case "Spy":
						pl.winner= gw=="Werewolf" && pl.dead && pl.flag=="spygone";
						break;
					case "Spy2":
						pl.winner= gw=="Werewolf" && !pl.dead;
						break;
					case "Liar":case "Fugitive":
						pl.winner= gw=="Human" && !pl.dead;
						break;
					default:
						if(wolves.some(function(x){return x==pl.type})){
							//狼側
							pl.winner= gw=="Werewolf";
						}else if(foxes.some(function(x){return x==pl.type})){
							pl.winner= gw=="Fox";
						}else{
							pl.winner= gw=="Human"
						}
					}
					console.log(" -> "+pl.winner);
				}
				
			}
			games.update({id:game.id},game);
		});
	});
}
