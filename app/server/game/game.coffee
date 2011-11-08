class Game
	constructor:(@id)->
		@logs=[]
		@players=[]
		@rule=null
		@finished=false	#終了したかどうか
		@day=0	#何日目か(0=準備中)
		@night=false # false:昼 true:夜
	# JSON用object化(DB保存用）
	serialize:->
		{
			id:@id
			logs:@logs
			rule:@rule
			players:@players.map (x)->x.serialize()
			finished:@finished
			day:@day
			night:@night
		}
	#DB用をもとにコンストラクト
	@unserialize:(obj)->
		game=new Game obj.id
		game.logs=obj.logs
		game.rule=obj.rule
		game.players=obj.players.map (x)->Player.unserialize x
		game.finished=obj.finished
		game.day=obj.day
		game.night=obj.night
		game
	# DBにセーブ
	save:->
		M.games.update {id:@id},@serialize()
		
	setrule:(rule)->@rule=rule
	#成功:null
	setplayers:(joblist,players,cb)->
		jnumber=0
		players=players.concat []
		for job,num of joblist
			jnumber+=parseInt num
		if jnumber!=players.length
			# 数が合わない
			cb "プレイヤー数が不正です(#{jnumber}/#{players.length})"
			return
		if @rule.scapegoat=="on"
			players.push {
				userid:-1
				name:"身代わりくん"
			}
		@players=[]
			
		# ひとり決める
		for job,num of joblist
			i=0
			while i++<num
				r=Math.floor Math.random()*players.length
				pl=players[r]
				@players.push new jobs[job] pl.userid,pl.name
				players.splice r,1
		cb null
	#次のターンに進む
	nextturn:->
		console.log "nextturn!"
		if @day<=0
			# はじまる前
			@day=1
			@night=true
		else if @night==true
			@day++
			@night=false
		else
			@night=true
		
		log=
			mode:"nextturn"
			day:@day
			night:@night
			userid:-1
			name:null
		splashlog @id,this,log
		
		
		
		
		
###
logs:[{
	mode:"day"(昼) / "system"(システムメッセージ) /  "wolf"(狼) / "heaven"(天国) / "prepare"(開始前) / "skill"(能力ログ) / "nextturn"(ゲーム進行)
	comment: String
	userid:Userid
	name:String
	to:Userid / null (あると、その人だけ）
	(nextturnの場合)
	  day:Number
	  night:Boolean
},...]
rule:{
    number: Number # プレイヤー数
    scapegoat : "on"(身代わり君が死ぬ） "off"(参加者が死ぬ) "no"(誰も死なない)
  }
###
class Player
	constructor:(@id,@name)->
		@dead=false
	serialize:->
		{
			type:@type
			id:@id
			name:@name
			dead:@dead
		}
	@unserialize:(obj)->
		p=null
		unless jobs[obj.type]?
			p=new Player obj.id,obj.name
		else
			p=new jobs[obj.type] obj.id,obj.name
		p
		
		
class Human extends Player
	type:"Human"
class Werewolf extends Player
	type:"Werewolf"
class Diviner extends Player
	type:"Diviner"

games={}

# 仕事一覧
jobs=
	Human:Human
	Werewolf:Werewolf
	Diviner:Diviner


exports.actions=
#内部用
	newGame: (room,rule)->
		game=new Game room.id,rule
		games[room.id]=game
		M.games.insert game.serialize()
	loadDB:->
		# まだ使うもの
		M.games.find({finished:false}).each (err,doc)->
			return unless doc?
			if err?
				console.log err
				throw err
			games[doc.id]=Game.unserialize doc
			console.log games[doc.id]
	inlog:(room,player)->
		log=
			comment:"#{player.name}さんが訪れました。"
			userid:-1
			name:null
			mode:"system"
		if games[room.id]
			splashlog room.id,games[room.id], log
	outlog:(room,player)->
		log=
			comment:"#{player.name}さんが去りました。"
			userid:-1
			name:null
			mode:"system"
		if games[room.id]
			splashlog room.id,games[room.id], log
			

#ゲーム開始処理
#成功：null
	gameStart:(roomid,query,cb)->
		game=games[roomid]
		unless game?
			cb "そのゲームは存在しません"
			return
		SS.server.game.rooms.oneRoom roomid,(room)->
			if room.error? 
				cb room.error
				return
			unless room.mode=="waiting"
				# すでに開始している
				cb "そのゲームは既に開始しています"
				return
			game.setrule {
				number: room.players.length
				scapegoat : query.scapegoat
			}
			
			joblist={}
			for job of jobs
				joblist[job]=query[job]	# 仕事の数
			
			game.setplayers joblist,room.players,(result)->
				unless result?
					# プレイヤー初期化に成功
					M.rooms.update {id:roomid},{$set:{mode:"playing"}}
					game.nextturn()
					game.save()
					cb null
				else
					cb result
	getlog:(roomid,cb)->
		game=games[roomid]
		unless game?
			cb {error:"そのゲームは存在しません"}
			return
		cb {logs:game.logs}
		
	speak: (roomid,comment,cb)->
		game=games[roomid]
		unless game?
			cb "そのゲームは存在しません"
			return
		unless @session.user_id
			cb "ログインして下さい"
			return
		log =
			comment:comment
			userid:@session.user_id
			name:@session.attributes.user.name
		if game.day<=0	#準備中
			log.mode="prepare"
		else
			
		splashlog roomid,game,log
		cb null

splashlog=(roomid,game,log)->
	game.logs.push log
	unless log.to?
		switch log.mode
			when "prepare","system"
				# 全員に送ってよい
				SS.publish.channel "room#{roomid}","log",log
		
