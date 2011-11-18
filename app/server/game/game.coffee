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
	# IDからプレイヤー
	getPlayer:(id)->
		@players.filter((x)->x.id==id)[0]
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
		cb null
#======== ゲーム進行の処理
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

		if @night
			@players.forEach (x)->x.sunset(this)
		else
			@players.forEach (x)->
				x.voteto=null
				x.sunrise(this)
		#死体処理
		@bury()

	#夜の能力を処理する
	midnight:->
		wolf_flg=false	# 狼の処理が既に終わったか
		@players.forEach (player)=>
			return if player.dead
			return if player.isWerewolf() && wolf_flg
			player.midnight this
			if player.isWerewolf()
				wolf_flg=true
	# 死んだ人を処理する
	bury:->
		@players.filter (x)->x.dead && x.found
		.forEach (x)=>
			situation=switch x.found
				#死因
				when "werewolf"
					"無惨な姿で発見されました"
				when "punish"
					"処刑されました"
				else
					"死んでました"				
			log=
				mode:"system"
				comment:"#{x.name}は#{situation}"
			splashlog @id,this,log
			x.found=""	# 発見されました
	# 投票終わりチェック
	execute:->
		return unless @players.every((x)->x.dead || x.voteto)
		tos={}
		@players.forEach (x)->
			return unless x.dead || !x.voteto
			voteresult[x.id]=x.voteto
			if tos[x.voteto]?
				tos[x.voteto]++
			else
				tos[x.voteto]=1
		max=0
		for playerid,num of tos
			if num>max then max=num	#最大値をみる
		player=null
		revote=false	# 際投票
		for playerid,num of tos
			if num==max
				if player?
					# 斎藤票だ!
					revote=true
					break
				player=@getPlayer playerid
		# 投票結果
		log=
			mode:"voteresult"
			voteresult:@players.map (x)->
				r=x.publicinfo()
				r.voteto=x.voteto
				r
		splashlog @id,this,log
		if revote
			# 再投票
			log=
				mode:"system"
				comment:"再投票になりました。"
			splashlog @id,this,log
			@player.forEach (player)->
				player.voteto=null
		else
			# 結果が出た 死んだ!
			player.dead=true	# 投票で死んだ
			player.found="punish"
###
logs:[{
	mode:"day"(昼) / "system"(システムメッセージ) /  "werewolf"(狼) / "heaven"(天国) / "prepare"(開始前) / "skill"(能力ログ) / "nextturn"(ゲーム進行) / "audience"(観戦者のひとりごと) / "monologue"(夜のひとりごと) / "voteresult" (投票結果）
	comment: String
	userid:Userid
	name:String
	to:Userid / null (あると、その人だけ）
	(nextturnの場合)
	  day:Number
	  night:Boolean
	(skillの場合)
	  jobtype: String
	  skillresult:Object / []
	(voteresultの場合)
	  voteresult:[]
},...]
rule:{
    number: Number # プレイヤー数
    scapegoat : "on"(身代わり君が死ぬ） "off"(参加者が死ぬ) "no"(誰も死なない)
  }
###
class Player
	constructor:(@id,@name)->
		@dead=false
		@found=null	# 死体の発見状況
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
	publicinfo:->
		# 見せてもいい情報
		{
			id:@id
			name:@name
			dead:@dead
		}
	
	# 人狼かどうか
	isWerewolf:->@type=="Werewolf"
	# 昼のはじまり
	sunrise:(game)->
	# 夜のはじまり
	sunset:(game)->
	# 夜にもう寝たか
	sleeping:->true
	# 夜の仕事
	job:(game,playerid)->
		@target=playerid
		return true
	# 夜の仕事を行う
	midnight:(game)->
	
	#人狼に食われて死ぬかどうか
	willDieWerewolf:true
	#占いの結果
	fortuneResult:"Human"
		
		
		
class Human extends Player
	type:"Human"
class Werewolf extends Player
	type:"Werewolf"
	sunset:(game)->
		@target=null
	sleeping:->@target?
	job:(game,playerid)->
		game.players.forEach (x)->
			if x.isWerewolf()
				x.target=playerid
		@target=playerid
		return true
	midnight:(game)->
		t=game.players.filter((x)=>x.id==@target)[0]
		if t.willDieWerewolf
			# 死んだ
			t.dead=true
			t.found="werewolf"
		
	willDieWerewolf:false
	fortuneResult:"Werewolf"
		
		
class Diviner extends Player
	type:"Diviner"
	constructor:->
		super
		@results=[]
			# {player:Player, result:"Human"/"Werewolf"}
	sunset:(game)->
		super
		@target=null
	sleeping:->@target?
	sunrise:(game)->
		super
		if @results.length
			# 欝等ないしのログ
			log=
				mode:"skill"
				to:@id
				jobtype:"Diviner"
				skillresult:@results
			splashlog game.id,game,log
				
	midnight:(game)->
		super
		p=game.getPlayer @target
		if p?
			@results.push {
				player: p.publicinfo()
				result: p.fortuneResult
			}

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
					SS.publish.channel "room#{roomid}","refresh",{}
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
			players:game.players.filter (x)->x.publicinfo()
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
		
	# 夜の仕事・投票
	job:(roomid,query,cb)->
		game=games[roomid]
		unless game?
			cb "そのゲームは存在しません"
			return
		unless @session.user_id
			cb "ログインして下さい"
			return
		player=game.players.filter((x)=>x.id==@session.user_id)[0]
		unless player?
			cb "参加していません"
			return
		unless to=game.players.filter((x)->x.id==query.target)[0]
			cb "その対象は存在しません"
			return
		unless to.dead
			cb "対象は既に死んでいます"
			return
		if game.night
			# 夜
			if player.sleeping()
				cb "失敗しました"
				return
			unless player.job game,query.target
				cb "失敗しました"
				return
			
			# 能力をすべて発動したかどうかチェック
			if game.players.every( (x)->x.dead || x.sleeping())
				game.midnight()
				game.nextturn()
		else
			# 投票
			if player.voteto?
				cb "既に投票しています"
				return
			player.voteto=query.target
			cb null
			# 投票が終わったかチェック
			game.execute()
		cb null
		

splashlog=(roomid,game,log)->
	game.logs.push log
	unless log.to?
		switch log.mode
			when "prepare","system","nextturn","voteresult"
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
		if log.mode in ["day","system","nextturn","prepare","monologue","skill","voteresult"]
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
		
