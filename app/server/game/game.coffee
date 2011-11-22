class Game
	constructor:(@id)->
		@logs=[]
		@players=[]
		@rule=null
		@finished=false	#終了したかどうか
		@day=0	#何日目か(0=準備中)
		@night=false # false:昼 true:夜
		
		@winner=null	# 勝ったチーム名
		# DBには現れない
		@timerid=null
		@voting=false	# 投票猶予時間
		@timer_start=null	# 残り時間のカウント開始時間（秒）
		@timer_remain=null	# 残り時間全体（秒）
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
			winner:@winner
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
		game.winner=obj.winner
		game
	# IDからプレイヤー
	getPlayer:(id)->
		@players.filter((x)->x.id==id)[0]
	# DBにセーブ
	save:->
		M.games.update {id:@id},@serialize()
		
	setrule:(rule)->@rule=rule
	#成功:null
	setplayers:(joblist,options,players,cb)->
		jnumber=0
		players=players.concat []
		if options.poisoner
			# 埋毒者
			joblist["Poisoner"]=1
			joblist["Werewolf"]++
			joblist["Human"]-=2
		else
			joblist["Poisoner"]=0
		plsl=players.length
		if @rule.scapegoat=="on"
			plsl++
		@players=[]
		for job,num of joblist
			jnumber+=parseInt num
			if parseInt(num)<0
				cb "プレイヤー数が不正です（#{job}:#{num})"
				return
		if jnumber!=plsl
			# 数が合わない
			cb "プレイヤー数が不正です(#{jnumber}/#{players.length})"
			return
		# まず身代わりくんを決めてあげる
		if @rule.scapegoat=="on"
			# 人狼、妖狼にはならない
			while true
				jobss=Object.keys(jobs).filter (x)->!(x in ["Werewolf","Fox"])
				r=Math.floor Math.random()*jobss.length
				continue unless joblist[jobss[r]]>0
				# 役職はjobss[r]
				newpl=new jobs[jobss[r]] "身代わりくん","身代わりくん"	#身代わりくん
				newpl.scapegoat=true
				@players.push newpl
				joblist[jobss[r]]--
				break
			console.log joblist
			
		# ひとり決める
		for job,num of joblist
			i=0
			while i++<num
				console.log players.length
				r=Math.floor Math.random()*players.length
				pl=players[r]
				console.log pl
				newpl=new jobs[job] pl.userid,pl.name
				@players.push newpl
				players.splice r,1
				if pl.scapegoat
					# 身代わりくん
					newpl.scapegoat=true
				#SS.publish.user pl.userid, "getjob", makejobinfo this,newpl
		if options.decider
			r=Math.floor Math.random()*players.length
			@players[r].decider=true
		if options.authority
			r=Math.floor Math.random()*players.length
			@players[r].authority=true
		
		cb null
#======== ゲーム進行の処理
	#次のターンに進む
	nextturn:->
		clearTimeout @timerid
		if @day<=0
			# はじまる前
			@day=1
			@night=true
		else if @night==true
			@day++
			@night=false
		else
			@night=true
			
		#死体処理
		@bury()
		return if @judge()
		
		log=
			mode:"nextturn"
			day:@day
			night:@night
			userid:-1
			name:null
			comment:"#{@day}日目の#{if @night then '夜' else '昼'}になりました。"
		splashlog @id,this,log

		if @night
			@players.forEach (x)=>
				return if x.dead
				x.sunset this
			if @day==1
				# 始まったばかり
				if @rule.scapegoat=="on"
					@players.forEach (x)->
						if x.type=="Werewolf"
							x.target="身代わりくん"
				else if @rule.scapegoat=="no"
					@players.forEach (x)->
						if x.type=="Werewolf"
							x.target=""	# 誰も殺さない
		else
			@voting=false
			@players.forEach (x)=>
				x.voteto=null
				return if x.dead
				x.sunrise this
		#死体処理
		@bury()
		SS.publish.channel "room#{@id}","playersinfo",@players.map (x)->x.publicinfo()
		@players.filter((x)->x.dead).forEach (x)=>
			# 死んだ人には状況更新をしてあげる
			SS.publish.user x.id,"getjob",makejobinfo this,x
		@judge()
		if @night
			@checkjobs()
		@save()
		@timer()
	#全員寝たかチェック 寝たなら処理してtrue
	checkjobs:->
		if @players.every( (x)->x.dead || x.sleeping())
			@midnight()
			@nextturn()
			true
		else
			false

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
		@players.filter((x)->x.dead && x.found).forEach (x)=>
			situation=switch x.found
				#死因
				when "werewolf","curse","poison"
					"無惨な姿で発見されました"
				when "punish"
					"処刑されました"
				else
					"突然お亡くなりになられました"				
			log=
				mode:"system"
				comment:"#{x.name}は#{situation}"
			splashlog @id,this,log
			x.found=""	# 発見されました
			SS.publish.user x.id,"refresh",{}
			if @rule.will=="die"
				# 死んだら遺言発表
				log=
					mode:"will"
					name:x.name
					comment:x.will
				splashlog @id,this,log
				
	# 投票終わりチェック
	execute:->
		return false unless @players.every((x)->x.dead || x.voteto)
		tos={}
		@players.forEach (x)->
			return if x.dead || !x.voteto
			if tos[x.voteto]?
				tos[x.voteto]+=if x.authority then 2 else 1
			else
				tos[x.voteto]=if x.authority then 2 else 1
		max=0
		for playerid,num of tos
			if num>max then max=num	#最大値をみる
		#console.log JSON.stringify tos
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
			voteresult:@players.filter((x)->!x.dead).map (x)->
				r=x.publicinfo()
				r.voteto=x.voteto
				r
			tos:tos
		splashlog @id,this,log
		if revote
			# 同率!
			dcs=@players.filter (x)->!x.dead && x.decider	# 決定者たち
			for onedc in dcs
				if tos[onedc.voteto]==max
					# こいつだ！
					revote=false
					player=@getPlayer onedc.voteto
					break
		if revote
			# 再投票
			log=
				mode:"system"
				comment:"再投票になりました。"
			splashlog @id,this,log
			@players.forEach (player)->
				player.voteto=null
			SS.publish.channel "room#{@id}","voteform",true
		else if player
			# 結果が出た 死んだ!
			player.dead=true	# 投票で死んだ
			player.found="punish"
			if player.type=="Poisoner"
				# 埋毒者の逆襲
				r=Math.floor Math.random()*@players.filter((x)->!x.dead).length
				pl=@players[r]	# 被害者
				pl.dead=true
				pl.found="poison"
				
			@nextturn()
		return true
	# 勝敗決定
	judge:->
		humans=@players.filter((x)->!x.dead && x.isHuman()).length
		wolves=@players.filter((x)->!x.dead && x.isWerewolf()).length
		console.log "humans:#{humans}, wolves:#{wolves}"
		
		team=null
		if wolves==0
			# 村人勝利
			team="Human"
		else if humans<=wolves
			# 人狼勝利
			team="Werewolf"
			
		if team?
			# 妖狐判定
			if @players.some((x)->!x.dead && x.type=="Fox")
				team="Fox"
			
		if team?
			# 勝敗決定
			@finished=true
			@winner=team
			@players.forEach (x)->
				x.winner= x.team==team	#勝利陣営にいたか
			log=
				mode:"nextturn"
				finished:true
				comment:switch team
					when "Human"
						"村から人狼がいなくなりました。"
					when "Werewolf"
						"人狼は最後の村人を喰い殺すと次の獲物を求めて去って行った…"
					when "Fox"
						"村は妖狐のものとなりました。"
						
			splashlog @id,this,log
			
			
			# ルームを終了状態にする
			M.rooms.update {id:@id},{$set:{mode:"end"}}
			SS.publish.channel "room#{@id}","refresh",{}
			return true
		else
			return false
	timer:->
		return if @day<=0 || @finished
		func=null
		time=null
		timeout= =>
			# 残り時間を知らせるぞ!
			@timer_start=parseInt Date.now()/1000
			@timer_remain=time
			SS.publish.channel "room#{@id}","time",time
			if time>60
				@timerid=setTimeout timeout,60000
				time-=60
			else if time>0
				@timerid=setTimeout timeout,time*1000
				time=0
			else
				# 時間切れ
				func()
		if @night
			# 夜
			time=@rule.night
			return unless time
			func= =>
				# ね な い こ だ れ だ
				unless @checkjobs()
					@players.forEach (x)->
						return if x.dead || x.sleeping()
						x.dead=true
						x.found="gone"	# 突然死
					@checkjobs()
						
		else if !@voting
			# 昼
			time=@rule.day
			return unless time
			func= =>
				unless @execute()
					if @rule.remain
						# 猶予があるよ
						@voting=true
						log=
							mode:"system"
							comment:"昼の討論時間が終了しました。投票して下さい。"
						splashlog @id,this,log
						@timer()
					else
						# 突然死
						@players.forEach (x)->
							return if x.dead || x.voteto
							x.dead=true
							x.found="gone"
						@execute()
		else
			# 猶予時間も過ぎたよ!
			time=@rule.voting
			func= =>
				unless @execute()
					@players.forEach (x)->
						return if x.dead || x.voteto
						x.dead=true
						x.found="gone"
					@execute()
		timeout()
		
		
###
logs:[{
	mode:"day"(昼) / "system"(システムメッセージ) /  "werewolf"(狼) / "heaven"(天国) / "prepare"(開始前/終了後) / "skill"(能力ログ) / "nextturn"(ゲーム進行) / "audience"(観戦者のひとりごと) / "monologue"(夜のひとりごと) / "voteresult" (投票結果） / "couple"(共有者) / "fox"(妖狐) / "will"(遺言)
	comment: String
	userid:Userid
	name?:String
	to:Userid / null (あると、その人だけ）
	(nextturnの場合)
	  day:Number
	  night:Boolean
	  finished?:Boolean
	(voteresultの場合)
	  voteresult:[]
	  tos:Object
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
		@winner=null	# 勝敗
		@scapegoat=false	# 身代わりくんかどうか
		
		@guarded=false	# 護衛フラグ
		
		@decider=false	# 決定者
		@authority=false# 権力者
		
		@will=null	# 遺言
	serialize:->
		{
			type:@type
			id:@id
			name:@name
			dead:@dead
			scapegoat:@scapegoat
			decider:@decider
			authority:@authority
			will:@will
		}
	@unserialize:(obj)->
		p=null
		unless jobs[obj.type]?
			p=new Player obj.id,obj.name
		else
			p=new jobs[obj.type] obj.id,obj.name
		p.dead=obj.dead
		p.scapegoat=obj.scapegoat
		p.decider=obj.decider
		p.authority=obj.authority
		p.will=obj.will
		p
	publicinfo:->
		# 見せてもいい情報
		{
			id:@id
			name:@name
			dead:@dead
		}
	# 村人かどうか
	isHuman:->@type!="Werewolf" && @type!="Fox"
	# 人狼かどうか
	isWerewolf:->@type=="Werewolf"
	# 昼のはじまり（死体処理よりも前）
	sunrise:(game)->@guarded=false
	# 夜のはじまり（死体処理よりも前）
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
	fortuneResult:"村人"
	#霊能の結果
	psychicResult:"村人"
	#チーム Human/Werewolf
	team: "Human"
		
		
		
class Human extends Player
	type:"Human"
	jobname:"村人"
class Werewolf extends Player
	type:"Werewolf"
	jobname:"人狼"
	sunset:(game)->
		@target=null
	sleeping:->@target?
	job:(game,playerid)->
		game.players.forEach (x)->
			if x.isWerewolf()
				x.target=playerid
		@target=playerid
		log=
			mode:"skill"
			to:@id
			comment:"#{@name}たち人狼は#{game.getPlayer(playerid).name}に狙いを定めました。"
		splashlog game.id,game,log
		return true
	midnight:(game)->
		t=game.getPlayer @target
		return unless t?
		if t.willDieWerewolf && !t.guarded
			# 死んだ
			t.dead=true
			t.found="werewolf"
			if t.type=="Poisoner"
				# 埋毒者の逆襲
				r=Math.floor Math.random()*game.players.filter((x)->!x.dead && x.isWerewolf()).length
				pl=game.players[r]	# 被害狼
				pl.dead=true
				pl.found="poison"
		
	willDieWerewolf:false
	fortuneResult:"人狼"
	psychicResult:"人狼"
	team: "Werewolf"
		
		
class Diviner extends Player
	type:"Diviner"
	jobname:"占い師"
	constructor:->
		super
		@results=[]
			# {player:Player, result:"Human"/"Werewolf"}
	sunset:(game)->
		super
		@target=null
		if @scapegoat
			console.log "Goat!"
			# 身代わり君の自動占い
			r=Math.floor Math.random()*game.players.length
			@job game,game.players[r].id
	sleeping:->@target?
	job:(game,playerid)->
		super
		log=
			mode:"skill"
			to:@id
			comment:"#{@name}が#{game.getPlayer(playerid).name}を占いました。"
		splashlog game.id,game,log
	sunrise:(game)->
		super
		r=@results[@results.length-1]
		return unless r?
		log=
			mode:"skill"
			to:@id
			comment:"#{@name}が#{r.player.name}を占ったところ、#{r.result}でした。"
		splashlog game.id,game,log
				
	midnight:(game)->
		super
		p=game.getPlayer @target
		if p?
			@results.push {
				player: p.publicinfo()
				result: p.fortuneResult
			}
			if p.type=="Fox"
				# 妖狐呪殺
				p.dead=true
				p.found="curse"
class Psychic extends Player
	type:"Psychic"
	jobname:"霊能者"
	sunset:(game)->
		super
		game.players.forEach (x)=>
			if x.dead && x.found	# 未発見
				log=
					mode:"skill"
					to:@id
					comment:"霊能結果：前日処刑された#{x.name}は#{x.psychicResult}でした。"
				splashlog game.id,game,log
class Madman extends Player
	type:"Madman"
	jobname:"狂人"
	team:"Werewolf"
class Guard extends Player
	type:"Guard"
	jobname:"狩人"
	sleeping:->@target?
	sunset:->
		@target=null
	job:(game,playerid)->
		super
		log=
			mode:"skill"
			to:@id
			comment:"#{@id}は#{game.getPlayer(playerid).name}を護衛しました。"
		splashlog game.id,game,log
		unless playerid==@id
			game.getPlayer(playerid).guarded=true	# 護衛
class Couple extends Player
	type:"Couple"
	jobname:"共有者"
class Fox extends Player
	type:"Fox"
	jobname:"妖狐"
	team:"Fox"
	willDieWerewolf:false
class Poisoner extends Player
	type:"Poisoner"
	jobname:"埋毒者"

games={}

# 仕事一覧
jobs=
	Human:Human
	Werewolf:Werewolf
	Diviner:Diviner
	Psychic:Psychic
	Madman:Madman
	Guard:Guard
	Couple:Couple
	Fox:Fox
	Poisoner:Poisoner


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
		else if player.type=="Couple"
			session.channel.subscribe "room#{roomid}_couple"
		else if player.type=="Fox"
			session.channel.subscribe "room#{roomid}_fox"
			
			
		
			

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
				day: parseInt(query.day_minute)*60+parseInt(query.day_second)
				night: parseInt(query.night_minute)*60+parseInt(query.night_second)
				remain: parseInt(query.remain_minute)*60+parseInt(query.remain_second)
				will: query.will
			}
			
			joblist={}
			for job of jobs
				joblist[job]=parseInt query[job]	# 仕事の数
			options={}
			for opt in ["poisoner","decider","authority"]
				options[opt]=query[opt] ? null
			
			game.setplayers joblist,options,room.players,(result)->
				unless result?
					# プレイヤー初期化に成功
					M.rooms.update {id:roomid},{$set:{mode:"playing"}}
					game.nextturn()
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
		result.timer=if game.timerid?
			game.timer_remain-(Date.now()/1000-game.timer_start)	# 全体 - 経過時間
		else
			null
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
		return if game.voting	# 投票猶予時間は発言できない
		if game.day<=0 || game.finished	#準備中
			log.mode="prepare"
		else
			# ゲームしている
			player=game.players.filter((x)=>x.id==@session.user_id)[0]
			unless player?
				# 観戦者
				log.mode="audience"
			else if player.dead
				# 天国
				log.mode="heaven"
			else if !game.night
				# 昼
				log.mode="day"
			else
				# 夜
				if player.isWerewolf()
					# 狼
					log.mode="werewolf"
				else if player.type=="Couple"
					# 共有者
					log.mode="couple"
				else if player.type=="Fox"
					# 洋子
					log.mode="fox"
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
		if player.dead
			cb "お前は既に死んでいる"
			return
		unless to=game.players.filter((x)->x.id==query.target)[0]
			cb "その対象は存在しません"
			return
		if to.dead
			cb "対象は既に死んでいます"
			return
		if game.night
			# 夜
			if player.sleeping()
				cb "既に能力を行使しています"
				return
			unless player.job game,query.target
				cb "失敗しました"
				return
			
			# 能力をすべて発動したかどうかチェック
			game.checkjobs()
		else
			# 投票
			if player.voteto?
				cb "既に投票しています"
				return
			player.voteto=query.target
			log=
				mode:"system"
				to:player.id
				comment:"#{player.name}は#{to.name}に投票しました"
			splashlog game.id,game,log
			# 投票が終わったかチェック
			game.execute()
		cb null
	#遺言
	will:(roomid,will,cb)->
		game=games[roomid]
		unless game?
			cb "そのゲームは存在しません"
			return
		unless @session.user_id
			cb "ログインして下さい"
			return
		unless game.rule.will
			cb "遺言は使えません"
			return
		player=game.players.filter((x)=>x.id==@session.user_id)[0]
		unless player?
			cb "参加していません"
			return
		if player.dead
			cb "お前は既に死んでいる"
			return
		player.will=will
		cb null
		

splashlog=(roomid,game,log)->
	game.logs.push log
	unless log.to?
		switch log.mode
			when "prepare","system","nextturn","voteresult","day","will"
				# 全員に送ってよい
				SS.publish.channel "room#{roomid}","log",log
			when "werewolf"
				# 狼
				SS.publish.channel ["room#{roomid}_werewolf","room#{roomid}_heaven"], "log", log
			when "couple"
				SS.publish.channel ["room#{roomid}_couple","room#{roomid}_heaven"],"log",log
			when "fox"
				SS.publish.channel ["room#{roomid}_fox","room#{roomid}_heaven"],"log",log
			when "audience"
				# 観客
				SS.publish.channel ["room#{roomid}_audience","room#{roomid}_heaven"],"log",log
			when "heaven"
				# 天国
				SS.publish.channel "room#{roomid}_heaven","log",log
	else
		SS.publish.user log.to, "log", log
		SS.publish.channel "room#{roomid}_heaven","log",log

# プレイヤーにログを見せてもよいか			
islogOK=(player,log)->
	# player: Player / null
	unless player?
		# 観戦者
		!log.to? && (log.mode in ["day","system","prepare","nextturn","audience","voteresult","will"])
	else if player.dead || player.winner?	# nullなら未終了 true/falseなら終了済み
		true
	else if log.to? && log.to!=player.id
		# 個人宛
		false
	else
		if log.mode in ["day","system","nextturn","prepare","monologue","skill","voteresult","will"]
			true
		else if log.mode=="werewolf"
			player.isWerewolf()
		else if log.mode=="couple"
			player.type=="Couple"
		else if log.mode=="fox"
			player.type=="Fox"
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
				x.publicinfo()
		if player.type=="Couple"
			# 共有者は仲間が分かる
			result.peers=game.players.filter((x)->x.type=="Couple").map (x)->
				x.publicinfo()
		if player.type=="Fox"
			# 妖狐は仲間が分かる
			result.foxes=game.players.filter((x)->x.type=="Fox").map (x)->
				x.publicinfo()
		result.dead=player.dead
		result.sleeping=if game.night then player.sleeping() else null
		result.jobname=player.jobname
		if player.dead || game.finished
			# 情報を開示する
			result.allplayers=game.players.map (x)->
				r=x.serialize()
				r.jobname=x.jobname
				r
		result.winner=player.winner
	
	result
		
