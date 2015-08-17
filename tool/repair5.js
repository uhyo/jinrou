/*
JINROU data fixer
Changes all prizes to 'ownprize'

*/
var user="test", password="test";	//自分で密码を入れてね

var mongo=require('mongodb');
var to_db=new mongo.Db("werewolf",new mongo.Server("localhost",27017));
var from_db=new mongo.Db("binrou",new mongo.Server("localhost",27017));



from_db.open(function(err,client){
	if(err)console.log(err);
	from_db.authenticate(user,password,function(err){
		if(err)console.log(err);
		to_db.open(function(err,client){
			if(err)console.log(err);
			to_db.authenticate(user,password,function(err){
				if(err)console.log(err);
				move("rooms",function(){
					move("games",function(){
						console.log("finished.");
						from_db.close();
						to_db.close();
					});
				});

			});
		});

	});
});

function move(collname,cb){
	from_db.collection(collname,function(err,colf){
		if(err){
			console.log(err);
			throw err;
		}
		//最新のやつを取得
		colf.find({}).sort({id:-1}).limit(1).nextObject(function(err,doc){
			if(err || !doc)throw err;
			var latest=doc.id;
			console.log("the latest "+collname+" id is "+latest);
			to_db.collection(collname,function(err,colt){
				colt.update({},{$inc:{id:latest}},{safe:true,multi:true},function(err){
					if(err)throw err;
					console.log(collname+" done.");
					cb();
				});
			});
		});
	});
}
