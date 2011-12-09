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
			jobscount:@jobscount
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
		game.jobscount=obj.jobscount
		game.timer()
		game
	# 公開情報
	publicinfo:(obj)->	#obj:オプション
		{
			rule:@rule
			finished:@finished
			players:@players.map (x)->
				r=x.publicinfo()
				if obj?.openjob
					r.jobname=x.jobname
					r.option=x.optionString()
				r
			day:@day
			night:@night
			jobscount:@jobscount
		}
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

		# 名前と数を出したやつ
		@jobscount={}
		for job,num of joblist
			continue unless num>0
			testpl=new jobs[job]
			@jobscount[testpl.jobname]=num

		# まず身代わりくんを決めてあげる
		if @rule.scapegoat=="on"
			# 人狼、妖狼にはならない
			while true
				jobss=Object.keys(jobs).filter (x)->!(x in ["Werewolf","BigWolf","Fox"])
				r=Math.floor Math.random()*jobss.length
				continue unless joblist[jobss[r]]>0
				# 役職はjobss[r]
				newpl=new jobs[jobss[r]] "身代わりくん","身代わりくん"	#身代わりくん
				newpl.scapegoat=true
				@players.push newpl
				joblist[jobss[r]]--
				break
			
		# ひとり決める
		for job,num of joblist
			i=0
			while i++<num
				r=Math.floor Math.random()*players.length
				pl=players[r]
				newpl=new jobs[job] pl.userid,pl.name
				@players.push newpl
				players.splice r,1
				if pl.scapegoat
					# 身代わりくん
					newpl.scapegoat=true
		if options.decider
			r=Math.floor Math.random()*@players.length
			@players[r].decider=true
		if options.authority
			r=Math.floor Math.random()*@players.length
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

		@voting=false
		if @night
			@players.forEach (x)=>
				return if x.dead
				x.sunset this
			if @day==1
				# 始まったばかり
				if @rule.scapegoat=="on"
					@players.forEach (x)->
						if x.isWerewolf()
							x.target="身代わりくん"
				else if @rule.scapegoat=="no"
					@players.forEach (x)->
						if x.isWerewolf()
							x.target=""	# 誰も殺さない
				# 狩人は一日目護衛しない
				@players.forEach (x)->
					if x.type=="Guard"
						x.target=""	# 誰も守らない
		else
			@players.forEach (x)=>
				x.voteto=null
				return if x.dead
				x.sunrise this
		#死体処理
		@bury()
		@judge()
		@splashjobinfo()
		if @night
			@checkjobs()
		@save()
		@timer()
	#全員に状況更新
	splashjobinfo:->
		@players.forEach (x)=>
			SS.publish.user x.id,"getjob",makejobinfo this,x
		# プレイヤー以外にも
		SS.publish.channel "room#{@id}_audience","getjob",makejobinfo this,null
	#全員寝たかチェック 寝たなら処理してtrue
	#timeoutがtrueならば時間切れなので時間でも待たない
	checkjobs:(timeout)->
		if @players.every( (x)->x.dead || x.sleeping())
			if @voting || timeout || !@rule.night	#夜に時間がある場合は待ってあげる
				@midnight()
				@nextturn()
				true
			else
				false
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
				when "werewolf","poison"
					"無惨な姿で発見されました"
				when "curse"	# 呪殺
					if @rule.deadfox=="obvious"
						"呪殺されました"
					else
						"無惨な姿で発見されました"
				when "punish"
					"処刑されました"
				when "spygone"
					"村を去りました"
				else
					"突然お亡くなりになられました"				
			log=
				mode:"system"
				comment:"#{x.name}は#{situation}"
			splashlog @id,this,log
			if x.found=="punish"
				# 処刑→霊能
				@players.forEach (y)=>
					if y.type=="Psychic"
						# 霊能
						y.results.push x
			x.found=""	# 発見されました
			SS.publish.user x.id,"refresh",{id:@id}
			if @rule.will=="die" && x.will
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
			@dorevote()
		else if player
			# 結果が出た 死んだ!
			player.punished this
			player.dead=true	# 投票で死んだ
				
			@nextturn()
		return true
	# 再投票
	dorevote:->
		log=
			mode:"system"
			comment:"再投票になりました。"
		splashlog @id,this,log
		@players.forEach (player)->
			player.voteto=null
		SS.publish.channel "room#{@id}","voteform",true
		@splashjobinfo()
		if @voting
			# 投票猶予の場合初期化
			clearTimeout @timerid
			@timer()
	# 勝敗決定
	judge:->
		humans=@players.filter((x)->!x.dead && x.isHuman()).length
		wolves=@players.filter((x)->!x.dead && x.isWerewolf()).length
		
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
			@players.forEach (x)=>
				x.winner= x.isWinner this,team	#勝利か
				# ユーザー情報
				if x.winner
					M.users.update {userid:x.id},{$push: {win:@id}}
				else
					M.users.update {userid:x.id},{$push: {lose:@id}}
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
			SS.publish.channel "room#{@id}","refresh",{id:@id}
			@save()
			return true
		else
			return false
	timer:->
		return if @day<=0 || @finished
		func=null
		time=null
		mode=null	# なんのカウントか
		timeout= =>
			# 残り時間を知らせるぞ!
			@timer_start=parseInt Date.now()/1000
			@timer_remain=time
			SS.publish.channel "room#{@id}","time",{time:time, mode:mode}
			if time>60
				@timerid=setTimeout timeout,60000
				time-=60
			else if time>0
				@timerid=setTimeout timeout,time*1000
				time=0
			else
				# 時間切れ
				func()
		if @night && !@voting
			# 夜
			time=@rule.night
			mode="夜"
			return unless time
			func= =>
				# ね な い こ だ れ だ
				unless @checkjobs true
					if @rule.remain
						# 猶予時間があるよ
						@voting=true
						@timer()
					else
						@players.forEach (x)=>
							return if x.dead || x.sleeping()
							x.dead=true
							x.found="gone"	# 突然死
							# 突然死記録
							M.users.update {userid:x.id},{$push:{gone:@id}}
						@bury()
						@checkjobs true
				else
					return
		else if @night
			# 夜の猶予
			time=@rule.remain
			mode="猶予"
			func= =>
				# ね な い こ だ れ だ
				@players.forEach (x)=>
					return if x.dead || x.sleeping()
					x.dead=true
					x.found="gone"	# 突然死
					# 突然死記録
					M.users.update {userid:x.id},{$push:{gone:@id}}
				@bury()
				@checkjobs true				
		else if !@voting
			# 昼
			time=@rule.day
			mode="昼"
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
						revoting=false
						@players.forEach (x)->
							return if x.dead || x.voteto
							x.dead=true
							x.found="gone"
							revoting=true
						@bury()
						@judge()
						if revoting
							@dorevote()
						else
							@execute()
				else
					return
		else
			# 猶予時間も過ぎたよ!
			time=@rule.remain
			mode="猶予"
			func= =>
				unless @execute()
					revoting=false
					@players.forEach (x)->
						return if x.dead || x.voteto
						x.dead=true
						x.found="gone"
						revoting=true
					@bury()
					@judge()
					if revoting
						@dorevote()
					else
						@execute()
				else
					return
		timeout()
	# プレイヤーごとに　見せてもよいログをリストにする
	makelogs:(player)->
		@logs.map (x)=>
			if islogOK this,player,x
				x
			else
				# 見られなかったけど見たい人用
				if x.mode=="werewolf" && @rule.wolfsound=="aloud"
					{
						mode: "werewolf"
						name: "狼の遠吠え"
						comment: "アオォーーン・・・"
					}
				else if x.mode=="couple" && @rule.couplesound=="aloud"
					{
						mode: "couple"
						name: "共有者の小声"
						comment: "ヒソヒソ・・・"
					}
				else
					null
		.filter (x)->x?
		
		
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
		@spygone=false	# 村を去ったかどうか
		
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
			spygone:@spygone
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
		p.spygone=obj.spygone
		p
	publicinfo:->
		# 見せてもいい情報
		{
			id:@id
			name:@name
			dead:@dead
		}
	optionString:->
		# 付加能力を文字列化
		arr=[]
		if @decider
			arr.push "決定者"
		if @authority
			arr.push "権力者"
		arr.join "・"
	# 村人かどうか
	isHuman:->!@isWerewolf() && @type!="Fox"
	# 人狼かどうか
	isWerewolf:->false
	# 昼のはじまり（死体処理よりも前）
	sunrise:(game)->@guarded=false
	# 夜のはじまり（死体処理よりも前）
	sunset:(game)->
	# 夜にもう寝たか
	sleeping:->true
	# 夜に仕事を追えたか（基本sleepingと一致）
	jobdone:->@sleeping()
	# 夜の仕事
	job:(game,playerid)->
		@target=playerid
		null
	# 夜の仕事を行う
	midnight:(game)->
	# 夜の仕事に対象が必要かどうか
	needstarget:true
	# 死人が対象かどうか
	dead_target:false
	#人狼に食われて死ぬかどうか
	willDieWerewolf:true
	#占いの結果
	fortuneResult:"村人"
	#霊能の結果
	psychicResult:"村人"
	#チーム Human/Werewolf
	team: "Human"
	#勝利かどうか team:勝利陣営名
	isWinner:(game,team)->
		team==@team	# 自分の陣営かどうか
	# つられたとき
	punished:(game)->
		@found="punish"

	# 噛まれたとき
	bitten: (game)->
		@dead=true
		@found="werewolf"
	# 役職情報を載せる
	makejobinfo:(game,obj)->

		
		
		
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
		tp = game.getPlayer playerid
		if game.rule.wolfattack!="ok" && tp?.isWerewolf()
			# 人狼は人狼に攻撃できない
			return "人狼は人狼を殺せません"
		game.players.forEach (x)->
			if x.isWerewolf()
				x.target=playerid
		@target=playerid
		log=
			mode:"skill"
			to:@id
			comment:"#{@name}たち人狼は#{game.getPlayer(playerid).name}に狙いを定めました。"
		splashlog game.id,game,log
		null
	midnight:(game)->
		t=game.getPlayer @target
		return unless t?
		if t.willDieWerewolf && !t.guarded
			# 死んだ
			t.bitten game
		# 逃亡者を探す
		runners=game.players.filter (x)=>!x.dead && x.type=="Fugitive" && x.target==@target
		runners.forEach (x)->
			x.bitten game	# その家に逃げていたら逃亡者も死ぬ
				
	isWerewolf:->true
		
	willDieWerewolf:false
	fortuneResult:"人狼"
	psychicResult:"人狼"
	team: "Werewolf"
	makejobinfo:(game,result)->
		# 人狼は仲間が分かる
		result.wolves=game.players.filter((x)->x.isWerewolf()).map (x)->
			x.publicinfo()

		
		
class Diviner extends Player
	type:"Diviner"
	jobname:"占い師"
	constructor:->
		super
		@results=[]
			# {player:Player, result:String}
	sunset:(game)->
		super
		@target=null
		if @scapegoat
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
		null
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
	constructor:->
		super
		@results=[]	# 処刑された人(Playerが入る）
	sunset:(game)->	#bury済みであること!
		super
		@results.forEach (x)=>
			log=
				mode:"skill"
				to:@id
				comment:"霊能結果：前日処刑された#{x.name}は#{x.psychicResult}でした。"
			splashlog game.id,game,log
		@results.length=0;

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
		unless playerid==@id && game.rule.guardmyself!="ok"
			game.getPlayer(playerid).guarded=true	# 護衛
			super
			log=
				mode:"skill"
				to:@id
				comment:"#{@name}は#{game.getPlayer(playerid).name}を護衛しました。"
			splashlog game.id,game,log
			null
		else
			"自分を護衛することはできません"
class Couple extends Player
	type:"Couple"
	jobname:"共有者"
	makejobinfo:(game,result)->
		# 共有者は仲間が分かる
		result.peers=game.players.filter((x)->x.type=="Couple").map (x)->
			x.publicinfo()

class Fox extends Player
	type:"Fox"
	jobname:"妖狐"
	team:"Fox"
	willDieWerewolf:false
	makejobinfo:(game,result)->
		# 妖狐は仲間が分かる
		result.foxes=game.players.filter((x)->x.type=="Fox").map (x)->
			x.publicinfo()

class Poisoner extends Player
	type:"Poisoner"
	jobname:"埋毒者"
	punished:(game)->
		# 埋毒者の逆襲
		canbedead = game.players.filter (x)->!x.dead	# 生きている人たち
		r=Math.floor Math.random()*canbedead.length
		pl=canbedead[r]	# 被害者
		pl.dead=true
		pl.found="poison"

	bitten:(game)->
		super
		# 埋毒者の逆襲
		canbedead = game.players.filter (x)->!x.dead && x.isWerewolf()	# 狼たち
		r=Math.floor Math.random()*canbedead.length
		pl=canbedead[r]	# 被害狼
		pl.dead=true
		pl.found="poison"

class BigWolf extends Werewolf
	type:"BigWolf"
	jobname:"大狼"
	fortuneResult:"村人"
	psychicResult:"大狼"
	
class Bat extends Player
	type:"Bat"
	jobname:"こうもり"
	team:""
	isWinner:(game,team)->
		!@dead	# 生きて入ればとにかく勝利
class Noble extends Player
	type:"Noble"
	jobname:"貴族"
	bitten:(game)->
		# 奴隷たち
		slaves = game.players.filter (x)->!x.dead && x.type=="Slave"
		unless slaves.length
			super	# 自分が死ぬ
		else
			# 奴隷が代わりに死ぬ
			slaves.forEach (x)->
				x.bitten game
class Slave extends Player
	type:"Slave"
	jobname:"奴隷"
	isWinner:(game,team)->
		nobles=game.players.filter (x)->!x.dead && x.type=="Noble"
		if team==@team && nobles.length==0
			true	# 村人陣営の勝ちで貴族は死んだ
		else
			false
	makejobinfo:(game,result)->
		# 奴隷は貴族が分かる
		result.nobles=game.players.filter((x)->x.type=="Noble").map (x)->
			x.publicinfo()
class Magician extends Player
	type:"Magician"
	jobname:"魔術師"
	sunset:(game)->
		#@target=if game.day<3 then "" else null
		@target=null
		if game.players.every((x)->!x.dead)
			@target=""	# 誰も死んでいないなら能力発動しない
	job:(game,playerid)->
#		if game.day<3
#			# まだ発動できない
#			return "まだ能力を発動できません"
		@target=playerid
		pl=game.getPlayer playerid
		
		log=
			mode:"skill"
			to:@id
			comment:"#{@name}は#{pl.name}に死者蘇生術をかけました。"
		splashlog game.id,game,log
		null
	sleeping:->@target?
	midnight:(game)->
		return unless @target?
		pl=game.getPlayer @target
		return unless pl?
		return unless pl.dead
		# 確率判定
		r=if pl.scapegoat then 0.6 else 0.3
		unless Math.random()<r
			# 失敗
			return
		pl.dead=false
		# 蘇生 目を覚まさせる
		SS.publish.user pl.id,"refresh",{id:game.id}
	dead_target:true
	makejobinfo:(game,result)->
		console.log "Magician: makeloginfo"
		result.dead_target=true	# 死人から選ぶ
class Spy extends Player
	type:"Spy"
	jobname:"スパイ"
	team:"Werewolf"
	sleeping:->true	# 能力使わなくてもいい
	jobdone:->@spygone	# 能力を使ったか
	job:(game,playerid)->
		return "既に能力を発動しています" if @spygone
		@spygone=true
		@guarded=true	# 人狼に教われても死なない
		log=
			mode:"skill"
			to:@id
			comment:"#{@name}は村を去ることに決めました。"
		splashlog game.id,game,log
		null
	midnight:(game)->
		if !@dead && @spygone
			# 村を去る
			@spygone=true
			@dead=true
			@found="spygone"
	needstarget:false
	isWinner:(game,team)->
		team==@team && @dead && @spygone	# 人狼が勝った上で自分は任務完了の必要あり
	makejobinfo:(game,result)->
		# スパイは人狼が分かる
		result.wolves=game.players.filter((x)->x.isWerewolf()).map (x)->
			x.publicinfo()

class Fugitive extends Player
	type:"Fugitive"
	jobname:"逃亡者"
	willDieWerewolf:false	# 人狼に直接噛まれても死なない
	sunset:(game)->
		@target=null
	sleeping:->@target?
	job:(game,playerid)->
		# 逃亡先
		pl=game.getPlayer playerid
		if pl?.dead
			return "死者の家には逃げられません"
		if playerid==@id
			return "自分の家へは逃げられません"
			return
		@target=playerid
		log=
			mode:"skill"
			to:@id
			comment:"#{@name}は#{pl.name}の家の近くへ逃亡しました。"
		splashlog game.id,game,log
		null
		
	midnight:(game)->
		# 人狼の家に逃げていたら即死
		pl=game.getPlayer @target
		if !pl.dead && pl.isWerewolf()
			@bitten game
		
	isWinner:(game,team)->
		team==@team && !@dead	# 村人勝利で生存
	
	

games={}

# ゲームを得る
getGame=(id)->

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
	BigWolf:BigWolf
	Bat:Bat
	Noble:Noble
	Slave:Slave
	Magician:Magician
	Spy:Spy
	Fugitive:Fugitive


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
			session.channel.subscribe "room#{roomid}_notwerewolf"
			session.channel.subscribe "room#{roomid}_notcouple"
			return
			
		if player.dead
			session.channel.subscribe "room#{roomid}_heaven"
		else if player.isWerewolf()
			session.channel.subscribe "room#{roomid}_werewolf"
		else
			session.channel.subscribe "room#{roomid}_notwerewolf"
		if player.type=="Couple"
			session.channel.subscribe "room#{roomid}_couple"
		else if !player.dead
			session.channel.subscribe "room#{roomid}_notcouple"
		if player.type=="Fox"
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
				wolfsound:query.wolfsound ? null	# 狼の声が聞こえるか
				couplesound:query.couplesound ? null	# 共有者の声が聞こえるか
				heavenview:query.heavenview ? null	# 死んだ後役職が見られるか
				wolfattack:query.wolfattack ? null	# 人狼が人狼を殺しに行けるか
				guardmyself:query.guardmyself ? null	# 狩人が自分を守れるか
				votemyself:query.votemyself ? null	# 自分に吊り投票できるか
				deadfox:query.deadfox ? null
			}
			
			joblist={}
			for job of jobs
				joblist[job]=parseInt query[job]	# 仕事の数
			options={}
			for opt in ["decider","authority"]
				options[opt]=query[opt] ? null
			
			game.setplayers joblist,options,room.players,(result)->
				unless result?
					# プレイヤー初期化に成功
					M.rooms.update {id:roomid},{$set:{mode:"playing"}}
					game.nextturn()
					cb null
					SS.publish.channel "room#{roomid}","refresh",{id:roomid}
				else
					cb result
	# 情報を開示
	getlog:(roomid,cb)->
		game=games[roomid]
		ne= =>
			# ゲーム後の行動
			player=game.players.filter((x)=>x.id==@session.user_id)[0]
			result= 
				#logs:game.logs.filter (x)-> islogOK game,player,x
				logs:game.makelogs player
			result=makejobinfo game,player,result
			result.timer=if game.timerid?
				game.timer_remain-(Date.now()/1000-game.timer_start)	# 全体 - 経過時間
			else
				null
			cb result
		if game?
			ne()
		else
			# DBから読もうとする
			M.games.findOne {id:roomid}, (err,doc)=>
				if err?
					console.log err
					throw err
				unless doc?
					cb {error:"そのゲームは存在しません"}
					return
				games[roomid]=game=Game.unserialize doc
				ne()
			return
		
	speak: (roomid,comment,cb)->
		game=games[roomid]
		unless game?
			cb "そのゲームは存在しません"
			return
		unless @session.user_id
			cb "ログインして下さい"
			return
		unless comment
			cb "コメントがありません"
			return
		log =
			comment:comment
			userid:@session.user_id
			name:@session.attributes.user.name
			to:null
		if !game.finished  && game.voting	# 投票猶予時間は発言できない
			player=game.getPlayer @session.user_id
			if player && !player.dead
				return	#まだ死んでいないプレイヤーの場合は発言できないよ!
		if game.day<=0 || game.finished	#準備中
			log.mode="prepare"
		else
			# ゲームしている
			player=game.getPlayer @session.user_id
			unless player?
				# 観戦者
				log.mode="audience"
			else if player.dead
				# 天国
				if player.spygone
					# スパイなら会話に参加できない
					log.mode="monologue"
					log.to=@session.user_id
				else
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
		if !(to=game.players.filter((x)->x.id==query.target)[0]) && player.needstarget
			cb "その対象は存在しません"
			return
		if to?.dead && (!player.dead_target || !game.night)
			cb "対象は既に死んでいます"
			return
		if game.night
			# 夜
			if !to?.dead && player.dead_target
				cb "対象はまだ生きています"
				return
			if player.jobdone()
				cb "既に能力を行使しています"
				return
			# エラーメッセージ
			if ret=player.job game,query.target
				cb ret
				return
			
			# 能力をすべて発動したかどうかチェック
			game.checkjobs()
		else
			# 投票
			if player.voteto?
				cb "既に投票しています"
				return
			if query.target==player.id && game.rule.votemyself!="ok"
				cb "自分には投票できません"
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
		unless !game.rule || game.rule.will
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
	log.time=Date.now()	# 時間を付加
	game.logs.push log
	hv=(ch)->
		# チャンネルにheavenを加える
		if game.rule.heavenview=="view"
			if ch instanceof Array
				ch.concat ["room#{roomid}_heaven"]
			else
				[ch,"room#{roomid}_heaven"]
		else
			ch
	hvn=(ch)->
		# チャンネルにheavenを加える viewでないとき
		if game.rule.heavenview!="view"
			if ch.concat?
				ch.concat ["room#{roomid}_heaven"]
			else
				[ch,"room#{roomid}_heaven"]
		else
			ch
	unless log.to?
		switch log.mode
			when "prepare","system","nextturn","voteresult","day","will"
				# 全員に送ってよい
				SS.publish.channel "room#{roomid}","log",log
			when "werewolf"
				# 狼
				SS.publish.channel hv("room#{roomid}_werewolf"), "log", log
				if game.rule.wolfsound=="aloud"
					# 狼の遠吠えが聞こえる
					log2=
						mode:"werewolf"
						comment:"アオォーーン・・・"
						name:"狼の遠吠え"
						time:log.time
					SS.publish.channel hvn("room#{roomid}_notwerewolf"),"log",log2
					
			when "couple"
				SS.publish.channel hv("room#{roomid}_couple"),"log",log
				if game.rule.couplesound=="aloud"
					# 共有者の小声が聞こえる
					log2=
						mode:"couple"
						comment:"ヒソヒソ・・・"
						name:"共有者の小声"
						time:log.time
					SS.publish.channel hvn("room#{roomid}_notcouple"),"log",log2
			when "fox"
				SS.publish.channel hv("room#{roomid}_fox"),"log",log
			when "audience"
				# 観客
				SS.publish.channel hv("room#{roomid}_audience"),"log",log
			when "heaven"
				# 天国
				SS.publish.channel "room#{roomid}_heaven","log",log
	else
		SS.publish.user log.to, "log", log
		if game.rule.heavenview=="view"
			SS.publish.channel "room#{roomid}_heaven","log",log

# プレイヤーにログを見せてもよいか			
islogOK=(game,player,log)->
	# player: Player / null
	return true if game.finished	# 終了ならtrue
	unless player?
		# 観戦者
		!log.to? && (log.mode in ["day","system","prepare","nextturn","audience","voteresult","will"])
	else if player.dead && game.rule.heavenview=="view"
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
	result.game=game.publicinfo({openjob:game.finished || (player?.dead && game.rule.heavenview=="view")})	# 終了か霊界（ルール設定あり）の場合は職情報公開
	result.id=game.id
	if player
		player.makejobinfo game,result
		result.dead=player.dead
		# 投票が終了したかどうか（フォーム表示するかどうか判断）
		result.sleeping=if game.night then player.jobdone() else if player.voteto? then true else false
		result.jobname=player.jobname
		result.winner=player.winner

	result
		
