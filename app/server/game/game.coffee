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
				SS.publish.user pl.userid, "getjob", makejobinfo this,player
		SS.publish.channel "room#{@id}","socketreinfo",{}
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
	mode:"day"(昼) / "system"(システムメッセージ) /  "werewolf"(狼) / "heaven"(天国) / "prepare"(開始前) / "skill"(能力ログ) / "nextturn"(ゲーム進行) / "audience"(観戦者のひとりごと) / "monologue"(夜のひとりごと)
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
	
	# 人狼かどうか
	isWerewolf:->@type=="Werewolf"
		
		
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
	# 状況に応じたチャンネルを割り当てる
	playerchannel:(roomid,session)->
		game=games[roomid]
		unless game?
			return
		player=game.players.filter((x)->x.id==session.user_id)[0]
		unless player?
			session.channel.subscribe "room#{roomid}_audience"
			return
		if player.dead
			session.channel.subscribe "room#{roomid}_heaven"
		else if player.isWerewolf()
			session.channel.subscribe "room#{roomid}_werewolf"
			
			
		
			

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
	# 情報を開示
	getlog:(roomid,cb)->
		game=games[roomid]
		unless game?
			cb {error:"そのゲームは存在しません"}
			return
		player=game.players.filter((x)=>x.id==@session.user_id)[0]
		result= 
			logs:game.logs.filter (x)-> islogOK player,x
		result=makejobinfo game,player,result
#		SS.server.game.game.playerchannel roomid,@session
		cb result
		
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
			to:null
		if game.day<=0	#準備中
			log.mode="prepare"
		else
			# ゲームしている
			player=game.players.filter((x)=>x.id==@session.user_id)[0]
			unless player?
				# 観戦者
				log.mode="audience"
			else if !game.night
				# 昼
				log.mode="day"
			else
				# 夜
				if player.isWerewolf()
					# 狼
					log.mode="werewolf"
				else
					# 村人
					log.mode="monologue"
					log.to=@session.user_id
				
		splashlog roomid,game,log
		cb null
	# プレイヤーに合わせてチャンネル設定してもらう
	socketreinfo:(roomid)->
		SS.server.game.game.playerchannel roomid,@session
		
	# 夜の仕事
	job:(roomid,query)->
		

splashlog=(roomid,game,log)->
	game.logs.push log
	unless log.to?
		switch log.mode
			when "prepare","system","nextturn"
				# 全員に送ってよい
				SS.publish.channel "room#{roomid}","log",log
			when "werewolf"
				# 狼
				SS.publish.channel ["room#{roomid}_werewolf","room#{roomid}_heaven"], "log", log
			when "audience"
				# 観客
				SS.publish.channel "room#{roomid}_audience","log",log
	else
		SS.publish.user log.to, "log", log

# プレイヤーにログを見せてもよいか			
islogOK=(player,log)->
	# player: Player / null
	unless player?
		# 観戦者
		!log.to? && (log.mode in ["day","system","prepare","nextturn","audience"])
	else if log.to? && log.to!=player.id
		# 個人宛
		false
	else
		if log.mode in ["day","system","nextturn","prepare","monologue","skill"]
			true
		else if log.mode=="werewolf"
			player.isWerewolf()
		else if log.mode=="heaven"
			player.dead
		else
			false
#job情報を
makejobinfo = (game,player,result={})->
	result.type= if player? then player.type else null
	if player
		if player.isWerewolf()
			# 人狼は仲間が分かる
			result.wolves=game.players.filter((x)->x.isWerewolf()).map (x)->
				{
					id:x.id
					name:x.name
				}
	result
		
