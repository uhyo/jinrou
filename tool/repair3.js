/*
JINROU data recoverer:
adds 'winner' to each player 2011-12-26

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
		db.collection("users",function(err,col){
			if(err)console.log(err);
			getdb2(col);
		});
	});
});

function getdb(games){
	games.find({"gamelogs":{$exists:false}}).each(function(err,game){
		if(game){
			if(!game.gamelogs){
				games.update({id:game.id},{$set:{"gamelogs":[]}},{safe:true},function(){
					console.log("id"+game.id+": done.");
				});
			}/*else if(!(game.gamelogs instanceof Array)){
				var result=[];
				for(var name in game.gamelogs){
					result=result.concat(game.gamelogs[name]);
				}
				games.update({id:game.id},{$set:{"gamelogs":result}},{safe:true},function(){
					console.log("id"+game.id+": re done.");
				});
				
			}*/
		}else{
			console.log("game - finished.");
		}
	});
		
}
function getdb2(users){
	users.find({$or:[{"prize":{$exists:false}},{"ownprize":{$exists:false}}]}).each(function(err,user){
		if(!user){
			console.log("user - finished.");
			return
		}
		query={$set:{}}
		if(!user.prize)query.$set.prize=[]
		if(!user.ownprize)query.$set.ownprize=[]
		if(!user.prize || !user.ownprize){
			users.update({userid:user.userid},query);
		}
	});
}
