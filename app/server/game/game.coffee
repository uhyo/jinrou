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
		@revote_num=0	# 再投票を行った回数
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
			players:@players.map (x)=>
				r=x.publicinfo()
				if obj?.openjob
					r.jobname=x.jobname
					r.option=x.optionString()
					r.originalJobname=x.originalJobname
					r.winner=x.winner
				unless @rule.blind=="complete" || (@rule.blind=="yes" && !@finished)
					# 公開してもよい
					r.realid=x.realid
				r
			day:@day
			night:@night
			jobscount:@jobscount
		}
	# IDからプレイヤー
	getPlayer:(id)->
		@players.filter((x)->x.id==id)[0]
	getPlayerReal:(realid)->
		@players.filter((x)->x.realid==realid)[0]
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

		if options.yaminabe
			# 闇鍋のときはランダムに決める
			frees=plsl	# 決める
			#でも人外はもう決まってる
			for job in SS.shared.game.nonhumans
				frees-=parseInt joblist[job]
			#plslが残り自由に決めるかず
			possibility=Object.keys(jobs).filter (x)->!(x in SS.shared.game.nonhumans)
			for job in possibility
				joblist[job]=0	# 一旦初期化
			
			while frees>0
				r=Math.floor Math.random()*possibility.length
				job=possibility[r]
				joblist[job]++
				frees--	# ひとつ追加
							
		if jnumber!=plsl
			# 数が合わない
			cb "プレイヤー数が不正です(#{jnumber}/#{players.length})"
			return

		# 名前と数を出したやつ
		@jobscount={}
		unless options.yaminabe=="hide"
			for job,num of joblist
				continue unless num>0
				testpl=new jobs[job]
				@jobscount[job]=
					name:testpl.jobname
					number:num

		# まず身代わりくんを決めてあげる
		if @rule.scapegoat=="on"
			# 人狼、妖狼にはならない
			i=0	# 無限ループ防止
			while ++i<100
				jobss=Object.keys(jobs).filter (x)->!(x in SS.shared.game.nonhumans) && joblist[x]>0
				r=Math.floor Math.random()*jobss.length
				continue unless joblist[jobss[r]]>0
				# 役職はjobss[r]
				newpl=Player.factory jobss[r],"身代わりくん","身代わりくん","身代わりくん"	#身代わりくん
				newpl.scapegoat=true
				@players.push newpl
				joblist[jobss[r]]--
				break
			if @players.length==0
				# 決まっていない
				cb "配役に失敗しました"
				return
			
		# ひとり決める
		for job,num of joblist
			i=0
			while i++<num
				r=Math.floor Math.random()*players.length
				pl=players[r]
				newpl=Player.factory job, pl.realid,pl.userid,pl.name
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
		# プレイヤーシャッフル
		@players=shuffle @players
		
		
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
			# 処理
			if @rule.deathnote
				# デスノート採用
				alives=@players.filter (x)->!x.dead
				if alives.length>0
					r=Math.floor Math.random()*alives.length
					pl=alives[r]
					sub=Player.factory "Light",pl.realid,pl.id,pl.name	# 副を作る
					sub.sunset this
					newpl=Player.factory "Complex",pl.realid,pl.id,pl.name,pl,sub
					@players.forEach (x,i)=>	# 入れ替え
						if x.id==newpl.id
							@players[i]=newpl
						else
							x
				
			@players.forEach (x)=>
				return if x.dead
				x.votestart this
				x.sunrise this
			@revote_num=0	# 再投票の回数は0にリセット
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
			SS.publish.user x.realid,"getjob",makejobinfo this,x
		# プレイヤー以外にも
		SS.publish.channel "room#{@id}_audience","getjob",makejobinfo this,null
	#全員寝たかチェック 寝たなら処理してtrue
	#timeoutがtrueならば時間切れなので時間でも待たない
	checkjobs:(timeout)->
		if @players.every( (x)->x.dead || x.sleeping())
			if @voting || timeout || !@rule.night || @rule.waitingnight!="wait"	#夜に時間がある場合は待ってあげる
				@midnight()
				@nextturn()
				true
			else
				false
		else
			false

	#夜の能力を処理する
	midnight:->
		@players.forEach (player)=>
			return if player.dead
			player.midnight this
	# 死んだ人を処理する
	bury:->
		@players.forEach (x)=>
			unless x.dead
				x.beforebury this
		deads=@players.filter (x)->x.dead && x.found
		deads=shuffle deads	# 順番バラバラ
		deads.forEach (x)=>
			situation=switch x.found
				#死因
				when "werewolf","poison","hinamizawa"
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
				when "deathnote"
					"死体で発見されました"
				when "foxsuicide"
					"狐の後を追って自ら死を選びました"
				else
					"突然お亡くなりになられました"				
			log=
				mode:"system"
				comment:"#{x.name}は#{situation}"
			splashlog @id,this,log
#			if x.found=="punish"
#				# 処刑→霊能
#				@players.forEach (y)=>
#					if y.type=="Psychic"
#						# 霊能
#						y.results.push x
			x.found=""	# 発見されました
			SS.publish.user x.realid,"refresh",{id:@id}
			if @rule.will=="die" && x.will
				# 死んだら遺言発表
				log=
					mode:"will"
					name:x.name
					comment:x.will
				splashlog @id,this,log
		deads.length
				
	# 投票終わりチェック
	execute:->
		return false unless @players.every((x)->x.dead || x.voted())
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
		if max==0
			# 誰も投票していない
			@revote_num=Infinity
			@judge()
			return
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
			player.die this,"punish"
				
			@nextturn()
		return true
	# 再投票
	dorevote:->
		@revote_num++
		if @revote_num>=4	# 4回再投票
			@judge()
			return
		log=
			mode:"system"
			comment:"再投票になりました。"
		splashlog @id,this,log
		@players.forEach (player)=>
			player.votestart this
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
			if @players.some((x)->!x.dead && x.isFox())
				team="Fox"
		# 悪魔くん判定
		if @players.some((x)->x.type=="Devil" && x.flag=="winner")
			team="Devil"

		if @revote_num>=4
			# 再投票多すぎ
			team="Draw"	# 引き分け
			
		if team?
			# 勝敗決定
			@finished=true
			@winner=team
			@players.forEach (x)=>
				x.setWinner x.isWinner this,team	#勝利か
				# ユーザー情報
				if x.winner
					M.users.update {userid:x.realid},{$push: {win:@id}}
				else if team!="Draw"
					M.users.update {userid:x.realid},{$push: {lose:@id}}
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
					when "Devil"
						"村は悪魔くんのものとなりました。"
					when "Draw"
						"引き分けになりました。"
						
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
							x.die this,"gone" # 突然死
							# 突然死記録
							M.users.update {userid:x.realid},{$push:{gone:@id}}
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
					x.die this,"gone" # 突然死
					# 突然死記録
					M.users.update {userid:x.realid},{$push:{gone:@id}}
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
							return if x.dead || x.voted()
							x.die this,"gone"
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
						return if x.dead || x.voted()
						x.die this,"gone"
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
    scapegoat : "on"(身代わり君が死ぬ) "off"(参加者が死ぬ) "no"(誰も死なない)
  }
###
class Player
	constructor:(@realid,@id,@name)->
		# realid:本当のid id:仮のidかもしれない
		@dead=false
		@found=null	# 死体の発見状況
		@winner=null	# 勝敗
		@scapegoat=false	# 身代わりくんかどうか
		@flag=null	# 役職ごとの自由なフラグ
		
		@guarded=false	# 護衛フラグ
		
		@decider=false	# 決定者
		@authority=false# 権力者
		
		@will=null	# 遺言
		# もとの役職
		@originalType=@type
		@originalJobname=@jobname
	@factory:(type,realid,id,name,main={},sub={})->
		p=null
		if type=="Complex"
			# 複合 mainとsubを使用
			myComplex=Object.create main #Complexから
			Object.getOwnPropertyNames(Complex.prototype).forEach (x)->	# 手動でComplexを継承
				myComplex[x]=Complex.prototype[x]
			# 混合役職
			p=Object.create myComplex
			Object.getOwnPropertyNames(p).forEach (x)->
				delete p[x]
			p.main=main
			p.sub=sub
		else if !jobs[type]?
			p=new Player realid,id,name
		else
			p=new jobs[type] realid,id,name
		p
	serialize:->
		r=
			type:@type
			id:@id
			realid:@realid
			name:@name
			dead:@dead
			scapegoat:@scapegoat
			decider:@decider
			authority:@authority
			will:@will
			flag:@flag
			winner:@winner
			originalType:@originalType
			originalJobname:@originalJobname
		if @isComplex()
			r.type="Complex"
			r.Complex_main=@main.serialize()
			r.Complex_sub=@sub.serialize()
		r
	@unserialize:(obj)->
		unless obj?
			return null

		p=if obj.type=="Complex"
			# 複合
			Player.factory obj.type,obj.realid,obj.id,obj.name, Player.unserialize(obj.Complex_main), Player.unserialize(obj.Complex_sub)
		else
			# 普通
			Player.factory obj.type,obj.realid,obj.id,obj.name
		p.dead=obj.dead
		p.scapegoat=obj.scapegoat
		p.decider=obj.decider
		p.authority=obj.authority
		p.will=obj.will
		p.flag=obj.flag
		p.winner=obj.winner
		p.originalType=obj.originalType
		p.originalJobname=obj.originalJobname
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
	isHuman:->!@isWerewolf()
	# 人狼かどうか
	isWerewolf:->false
	# 洋子かどうか
	isFox:->false
	# Complexかどうか
	isComplex:->false
	# jobtypeが合っているかどうか（夜）
	isJobType:(type)->type==@type
	# 昼のはじまり（死体処理よりも前）
	sunrise:(game)->
		@guarded=false
	# 昼の投票準備
	votestart:(game)->
		@voteto=null
		if @scapegoat
			# 身代わりくんは投票
			alives=game.players.filter (x)->!x.dead
			r=Math.floor Math.random()*alives.length	# 投票先
			@voteto=game.players[r].id
			if game.rule.votemyself!="ok" && @voteto==@id && alives.length>1
				# 自分投票
				@votestart game	# やり直し
		
	# 夜のはじまり（死体処理よりも前）
	sunset:(game)->
	# 夜にもう寝たか
	sleeping:->true
	# 夜に仕事を追えたか（基本sleepingと一致）
	jobdone:->@sleeping()
	# 昼に投票を終えたか
	voted:->@voteto?
	# 夜の仕事
	job:(game,playerid,query)->
		@target=playerid
		null
	# 夜の仕事を行う
	midnight:(game)->
	# 対象
	job_target:1	# ビットフラグ
	# 対象用の値
	@JOB_T_ALIVE:1	# 生きた人が対象
	@JOB_T_DEAD :2	# 死んだ人が対象
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
	# 勝敗設定
	setWinner:(winner)->@winner=winner
	# 死んだとき(found:死因))
	die:(game,found)->
		return if @dead
		@dead=true
		@found=found
		if found=="punish"
			@punished game
		else if found=="werewolf"
			@bitten game
		
	# つられたとき
	punished:(game)->

		

	# 噛まれたとき
	bitten: (game)->
		return if @dead
	# 埋葬するまえに全員呼ばれる（foundが見られる状況で）
	beforebury: (game)->
	# 役職情報を載せる
	makejobinfo:(game,obj)->
		# 開くべきフォームを配列で（生きている場合）
		obj.open ?=[]
		if !@jobdone()
			obj.open.push @type
		obj.job_target=@job_target
		# 女王観戦者が見える
		if @team=="Human"
			obj.queens=game.players.filter((x)->x.type=="QueenSpectator").map (x)->
				x.publicinfo()
	
	# Complexから抜ける
	uncomplex:(game)->
		# 自分が@subだとする
		game.players.forEach (x,i)=>
			return unless x.isComplex()
			if x.sub==this
				x.sub=null	# ただの透過Complex
	# 護衛されたことを知らせる
	youareguarded:->
		@guarded=true

		
		
		
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
		if @target?
			return "既に対象は決定しています"
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
		if t.willDieWerewolf && !t.guarded && !t.dead
			# 死んだ
			t.die game,"werewolf"
		# 逃亡者を探す
		runners=game.players.filter (x)=>!x.dead && x.type=="Fugitive" && x.target==@target
		runners.forEach (x)->
			x.die game,"werewolf"	# その家に逃げていたら逃亡者も死ぬ
				
	isWerewolf:->true
		
	willDieWerewolf:false
	fortuneResult:"人狼"
	psychicResult:"人狼"
	team: "Werewolf"
	makejobinfo:(game,result)->
		super
		# 人狼は仲間が分かる
		result.wolves=game.players.filter((x)->x.isWerewolf()).map (x)->
			x.publicinfo()
		# スパイ2も分かる
		result.spy2s=game.players.filter((x)->x.type=="Spy2").map (x)->
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
			@job game,game.players[r].id,{}
	sleeping:->@target?
	job:(game,playerid)->
		super
		log=
			mode:"skill"
			to:@id
			comment:"#{@name}が#{game.getPlayer(playerid).name}を占いました。"
		splashlog game.id,game,log
		if game.rule.divineresult=="immediate"
			@dodivine game
			@showdivineresult game
		null
	sunrise:(game)->
		super
		unless game.rule.divineresult=="immediate"
			@showdivineresult game
				
	midnight:(game)->
		super
		unless game.rule.divineresult=="immediate"
			@dodivine game
	#占い実行
	dodivine:(game)->
		p=game.getPlayer @target
		if p?
			@results.push {
				player: p.publicinfo()
				result: p.fortuneResult
			}
			if p.type=="Fox"
				# 妖狐呪殺
				p.die game,"curse"
	showdivineresult:(game)->
		r=@results[@results.length-1]
		return unless r?
		log=
			mode:"skill"
			to:@id
			comment:"#{@name}が#{r.player.name}を占ったところ、#{r.result}でした。"
		splashlog game.id,game,log		
class Psychic extends Player
	type:"Psychic"
	jobname:"霊能者"
	constructor:->
		super
		@results=[]	# 処刑された人(Playerが入る）
	sunset:(game)->
		super
		if game.rule.psychicresult=="sunset"
			@showpsychicresult game
	sunrise:(game)->
		super
		unless game.rule.psychicresult=="sunset"
			@showpsychicresult game
		
	showpsychicresult:(game)->
		@results.forEach (x)=>
			log=
				mode:"skill"
				to:@id
				comment:"霊能結果：前日処刑された#{x.name}は#{x.psychicResult}でした。"
			splashlog game.id,game,log
		@results.length=0
	
	# 処刑で死んだ人を調べる
	beforebury:(game)->
		game.players.filter((x)->x.dead && x.found=="punish").forEach (x)=>
			@results.push x

class Madman extends Player
	type:"Madman"
	jobname:"狂人"
	team:"Werewolf"
	makejobinfo:(game,result)->
		super
		delete result.queens
class Guard extends Player
	type:"Guard"
	jobname:"狩人"
	sleeping:->@target?
	sunset:(game)->
		@target=null
		if @scapegoat
			# 身代わり君の自動占い
			r=Math.floor Math.random()*game.players.length
			if @job game,game.players[r].id,{}
				@sunset
	job:(game,playerid)->
		unless playerid==@id && game.rule.guardmyself!="ok"
			game.getPlayer(playerid).youareguarded()	# 護衛
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
		super
		# 共有者は仲間が分かる
		result.peers=game.players.filter((x)->x.type=="Couple").map (x)->
			x.publicinfo()

class Fox extends Player
	type:"Fox"
	jobname:"妖狐"
	team:"Fox"
	willDieWerewolf:false
	isHuman:->false
	isFox:->true
	makejobinfo:(game,result)->
		super
		# 妖狐は仲間が分かる
		result.foxes=game.players.filter((x)->x.type=="Fox").map (x)->
			x.publicinfo()

class Poisoner extends Player
	type:"Poisoner"
	jobname:"埋毒者"
	punished:(game)->
		# 埋毒者の逆襲
		super
		canbedead = game.players.filter (x)->!x.dead	# 生きている人たち
		r=Math.floor Math.random()*canbedead.length
		pl=canbedead[r]	# 被害者
		pl.die game,"poison"

	bitten:(game)->
		super
		# 埋毒者の逆襲
		canbedead = game.players.filter (x)->!x.dead && x.isWerewolf()	# 狼たち
		r=Math.floor Math.random()*canbedead.length
		pl=canbedead[r]	# 被害狼
		pl.die game,"poison"

class BigWolf extends Werewolf
	type:"BigWolf"
	jobname:"大狼"
	fortuneResult:"村人"
	psychicResult:"大狼"
class TinyFox extends Diviner
	type:"TinyFox"
	jobname:"子狐"
	fortuneResult:"村人"
	psychicResult:"子狐"
	team:"Fox"
	isHuman:->false
	isFox:->true
	sunset:(game)->
		if @scapegoat
			# 身代わり君の自動占い
			r=Math.floor Math.random()*game.players.length
			if @job game,game.players[r].id,{}
				@sunset
	makejobinfo:(game,result)->
		# 子狐は妖狐が分かる
		result.foxes=game.players.filter((x)->x.type=="Fox").map (x)->
			x.publicinfo()

	dodivine:(game)->
		p=game.getPlayer @target
		if p?
			@results.push {
				player: p.publicinfo()
				result: p.fortuneResult
			}
	showdivineresult:(game)->
		r=@results[@results.length-1]
		return unless r?
		# たまに失敗
		if Math.random() < 0.5
			r.result="なんだかとても怪しい人"
		else
			r.result+="ぽい人"
		log=
			mode:"skill"
			to:@id
			comment:"#{@name}の占いの結果、#{r.player.name}は#{r.result}かな？"
		splashlog game.id,game,log			
	
	
class Bat extends Player
	type:"Bat"
	jobname:"こうもり"
	team:""
	isWinner:(game,team)->
		!@dead	# 生きて入ればとにかく勝利
class Noble extends Player
	type:"Noble"
	jobname:"貴族"
	die:(game,found)->
		if found=="werewolf"
			return if @dead
			# 奴隷たち
			slaves = game.players.filter (x)->!x.dead && x.type=="Slave"
			unless slaves.length
				super	# 自分が死ぬ
			else
				# 奴隷が代わりに死ぬ
				slaves.forEach (x)->
					x.die game,"werewolf"
		else
			super

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
		super
		# 奴隷は貴族が分かる
		result.nobles=game.players.filter((x)->x.type=="Noble").map (x)->
			x.publicinfo()
class Magician extends Player
	type:"Magician"
	jobname:"魔術師"
	sunset:(game)->
		@target=if game.day<3 then "" else null
		if game.players.every((x)->!x.dead)
			@target=""	# 誰も死んでいないなら能力発動しない
		if !@target? && @scapegoat
			# 身代わり君の自動占い
			r=Math.floor Math.random()*game.players.length
			@job game,game.players[r].id,{}
	job:(game,playerid)->
		if game.day<3
			# まだ発動できない
			return "まだ能力を発動できません"
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
	job_target:Player.JOB_T_DEAD
	makejobinfo:(game,result)->
		super
class Spy extends Player
	type:"Spy"
	jobname:"スパイ"
	team:"Werewolf"
	sleeping:->true	# 能力使わなくてもいい
	jobdone:->@flag in ["spygone","day1"]	# 能力を使ったか
	sunrise:(game)->
		if game.day<=1
			@flag="day1"	# まだ去れない
		else
			@flag=null
	job:(game,playerid)->
		return "既に能力を発動しています" if @flag=="spygone"
		@flag="spygone"
		@guarded=true	# 人狼に教われても死なない
		log=
			mode:"skill"
			to:@id
			comment:"#{@name}は村を去ることに決めました。"
		splashlog game.id,game,log
		null
	midnight:(game)->
		if !@dead && @flag=="spygone"
			# 村を去る
			@flag="spygone"
			@die game,"spygone"
	job_target:0
	isWinner:(game,team)->
		team==@team && @dead && @flag=="spygone"	# 人狼が勝った上で自分は任務完了の必要あり
	makejobinfo:(game,result)->
		super
		# スパイは人狼が分かる
		result.wolves=game.players.filter((x)->x.isWerewolf()).map (x)->
			x.publicinfo()
class WolfDiviner extends Werewolf
	type:"WolfDiviner"
	jobname:"人狼占い"
	sunset:(game)->
		@target=null
		@flag=null	# 占い対象
		@result=null	# 占い結果
	sleeping:->@target?	# 占いは必須ではない
	jobdone:->@target? && @flag?
	job:(game,playerid,query)->
		if query.commandname!="divine"
			# 人狼の仕事
			return super
		# 占い
		if @flag?
			return "既に占い対象を決定しています"
		@flag=playerid
		log=
			mode:"skill"
			to:@id
			comment:"#{@name}が#{game.getPlayer(playerid).name}を占いました。"
		splashlog game.id,game,log
		null
	sunrise:(game)->
		super
		unless game.rule.divineresult=="immediate"
			@dodivine game
	midnight:(game)->
		super
		unless game.rule.divineresult=="immediate"
			@showdivineresult game
	dodivine:(game)->
		return unless @result?
		log=
			mode:"skill"
			to:@id
			comment:"#{@name}が#{@result.player.name}を占ったところ、#{@result.result}でした。"
		splashlog game.id,game,log
	showdivineresult:(game)->
		p=game.getPlayer @flag
		if p?
			@result=
				player: p.publicinfo()
				result: p.jobname
			if p.type=="Fox"
				# 妖狐呪殺
				p.die game,"curse"
			if p.type=="Diviner"
				# 逆呪殺
				@die game,"curse"
			if p.type=="Madman"
				# 狂人変化
				jobnames=Object.keys jobs
				newjob=jobnames[Math.floor Math.random()*jobnames.length]
				plobj=p.serialize()
				plobj.type=newjob
				newpl=Player.unserialize plobj	# 新生狂人
				game.players.forEach (x,i)->	# 入れ替え
					if x.id==newpl.id
						game.players[i]=newpl
					else
						x
		
	
		

class Fugitive extends Player
	type:"Fugitive"
	jobname:"逃亡者"
	willDieWerewolf:false	# 人狼に直接噛まれても死なない
	sunset:(game)->
		@target=null
		@willDieWerewolf=false
		if game.day<=1 && game.rule.scapegoat!="off"	# 一日目は逃げない
			@target=""
			@willDieWerewolf=true	# 一日目だけは死ぬ
		else if @scapegoat
			# 身代わり君の自動占い
			r=Math.floor Math.random()*game.players.length
			if @job game,game.players[r].id,{}
				@sunset	sleeping:->@target?
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
		return unless pl?
		if !pl.dead && pl.isWerewolf()
			@die game,"werewolf"
		
	isWinner:(game,team)->
		team==@team && !@dead	# 村人勝利で生存
class Merchant extends Player
	type:"Merchant"
	jobname:"商人"
	constructor:->
		super
		@flag=null	# 発送済みかどうか
	sleeping:->true
	jobdone:->@flag?
	job:(game,playerid,query)->
		if @flag?
			return "既に商品を発送しています"
		# 即時発送
		unless query.Merchant_kit in ["Diviner","Psychic","Guard"]
			return "発送する商品が不正です"
		kit_names=
			"Diviner":"占いセット"
			"Psychic":"霊能セット"
			"Guard":"狩人セット"
		pl=game.getPlayer playerid
		unless pl?
			return "発送先が不正です"
		if pl.dead
			return "発送先は既に死んでいます"
		# 複合させる
		sub=Player.factory query.Merchant_kit,pl.realid,pl.id,pl.name	# 副を作る
		sub.sunset game
		newpl=Player.factory "Complex",pl.realid,pl.id,pl.name,pl,sub
		game.players.forEach (x,i)->	# 入れ替え
			if x.id==newpl.id
				game.players[i]=newpl
			else
				x
		log=
			mode:"skill"
			to:@id
			comment:"#{@name}は#{newpl.name}へ#{kit_names[query.Merchant_kit]}を発送しました。"
		splashlog game.id,game,log
		# 入れ替え先は気づいてもらう
		log=
			mode:"skill"
			to:newpl.id
			comment:"#{newpl.name}へ#{kit_names[query.Merchant_kit]}が到着しました。"
		splashlog game.id,game,log
		SS.publish.user newpl.id,"refresh",{id:game.id}	
		@flag=query.Merchant_kit	# 発送済み
		null
class QueenSpectator extends Player
	type:"QueenSpectator"
	jobname:"女王観戦者"
	die:(game,found)->
		super
		# 感染
		humans = game.players.filter (x)->!x.dead && x.isHuman()	# 生きている人たち
		humans.forEach (x)->
			x.die game,"hinamizawa"

class MadWolf extends Werewolf
	type:"MadWolf"
	jobname:"狂人狼"
	team:"Human"
	sleeping:->true
class Neet extends Player
	type:"Neet"
	jobname:"ニート"
	team:""
	sleeping:->true
	voted:->true
	isWinner:->true
class Liar extends Player
	type:"Liar"
	jobname:"嘘つき"
	job_target:Player.JOB_T_ALIVE | Player.JOB_T_DEAD	# 死人も生存も
	sunset:(game)->
		@target=null
		@result=null	# 占い結果
		if @scapegoat
			# 身代わり君の自動占い
			r=Math.floor Math.random()*game.players.length
			@job game,game.players[r].id,{}
	sleeping:->@target?
	job:(game,playerid,query)->
		# 占い
		if @target?
			return "既に占い対象を決定しています"
		@target=playerid
		log=
			mode:"skill"
			to:@id
			comment:"#{@name}が#{game.getPlayer(playerid).name}を占いました。"
		splashlog game.id,game,log
		null
	sunrise:(game)->
		super
		return unless @result?
		log=
			mode:"skill"
			to:@id
			comment:"あんまり自信ないけど、霊能占いの結果、#{@result.player.name}は#{@result.result}だと思う。たぶん。"
		splashlog game.id,game,log
	midnight:(game)->
		super
		p=game.getPlayer @target
		if p?
			@result=
				player: p.publicinfo()
				result: if Math.random()<0.3
					# 成功
					if p.isWerewolf()
						"人狼"
					else
						"村人"
				else
					# 逆
					if p.isWerewolf()
						"村人"
					else
						"人狼"
	isWinner:(game,team)->team==@team && !@dead	# 村人勝利で生存
class Spy2 extends Player
	type:"Spy2"
	jobname:"スパイⅡ"
	team:"Werewolf"
	makejobinfo:(game,result)->
		super
		# スパイは人狼が分かる
		result.wolves=game.players.filter((x)->x.isWerewolf()).map (x)->
			x.publicinfo()
	
	die:(game,found)->
		super
		@publishdocument game
			
	publishdocument:(game)->
		str=game.players.map (x)->
			"#{x.name}:#{x.jobname}"
		.join " "
		log=
			mode:"system"
			comment:"#{@name}の調査報告書が発見されました。"
		splashlog game.id,game,log
		log2=
			mode:"will"
			comment:str
		splashlog game.id,game,log2
			
	isWinner:(game,team)-> team==@team && !@dead
class Copier extends Player
	type:"Copier"
	jobname:"コピー"
	team:""
	isHuman:->false
	sleeping:->true
	jobdone:->@target?
	job:(game,playerid,query)->
		# コピー先
		if @target?
			return "既にコピーしています"
		@target=playerid
		log=
			mode:"skill"
			to:@id
			comment:"#{@name}が#{game.getPlayer(playerid).name}の能力をコピーしました。"
		splashlog game.id,game,log
		p=game.getPlayer playerid
		newpl=Player.factory p.type,@realid,@id,@name
		newpl.originalType=@originalType
		newpl.originalJobname=@originalJobname
		game.players.forEach (x,i)->	# 入れ替え
			if x.id==newpl.id
				game.players[i]=newpl
			else
				x
		
		null
	isWinner:(game,team)->null
class Light extends Player
	type:"Light"
	jobname:"デスノート"
	sleeping:->true
	jobdone:->@target?
	sunset:(game)->
		@target=null
	job:(game,playerid,query)->
		# コピー先
		if @target?
			return "既に対象を選択しています"
		@target=playerid
		log=
			mode:"skill"
			to:@id
			comment:"#{@name}が#{game.getPlayer(playerid).name}の名前を死神の手帳に書きました。"
		splashlog game.id,game,log
		null		
	midnight:(game)->
		t=game.getPlayer @target
		return unless t?
		return if t.dead
		t.die game,"deathnote"
		
		# 誰かに移る処理
		@uncomplex game	# 自分からは抜ける
class Fanatic extends Madman
	type:"Fanatic"
	jobname:"狂信者"
	makejobinfo:(game,result)->
		super
		# 狂信者は人狼が分かる
		result.wolves=game.players.filter((x)->x.isWerewolf()).map (x)->
			x.publicinfo()
class Immoral extends Player
	type:"Immoral"
	jobname:"背徳者"
	team:"Fox"
	beforebury:(game)->
		# 狐が全員死んでいたら自殺
		unless game.players.some((x)->!x.dead && x.isFox())
			@die game,"foxsuicide"
	makejobinfo:(game,result)->
		super
		# 妖狐が分かる
		result.foxes=game.players.filter((x)->x.type=="Fox").map (x)->
			x.publicinfo()
class Devil extends Player
	type:"Devil"
	jobname:"悪魔くん"
	team:"Devil"
	die:(game,found)->
		return if @dead
		if found=="werewolf"
			# 死なないぞ！
			unless @flag
				# まだ噛まれていない
				@flag="bitten"
		else if found=="punish"
			# 処刑されたぞ！
			if @flag=="bitten"
				# 噛まれたあと処刑された
				@flag="winner"
			else
				super
		else
			super
	isWinner:(game,team)->team==@team && @flag=="winner"
class ToughGuy extends Player
	type:"ToughGuy"
	jobname:"タフガイ"
	die:(game,found)->
		if found=="werewolf"
			# 狼の襲撃に耐える
			@flag="bitten"
		else
			super
	sunrise:(game)->
		if @flag=="bitten"
			@flag="dying"	# 死にそう！
	sunset:(game)->
		super
		if @flag=="dying"
			# 噛まれた次の夜
			@dead=true
			@found="werewolf"
			game.bury()


# 複合役職 Player.factoryで適切に生成されることを期待
# superはメイン役職 @mainにメイン @subにサブ
class Complex extends Player
	isComplex:->true
	jobdone:-> @main.jobdone() && @sub?.jobdone()	# ジョブの場合はサブも考慮
	job:(game,playerid,query)->	# どちらの
		if @main.isJobType(query.jobtype) && !@main.jobdone()
			@main.job game,playerid,query
		else if @sub?.isJobType(query.jobtype) && !@sub?.jobdone()
			@sub.job game,playerid,query
		
	isJobType:(type)->
		@main.isJobType(type) || @sub.isJobType(type)
	sunset:(game)->
		@main.sunset game
		@sub?.sunset game
	midnight:(game)->
		@main.midnight game
		@sub?.midnight game
	sunrise:(game)->
		@main.sunrise game
		@sub?.sunrise game
	makejobinfo:(game,result)->
		@sub?.makejobinfo game,result
		@main.makejobinfo game,result
	youareguarded:->
		@main.youareguarded()
		@sub?.youareguarded()
	setWinner:(winner)->
		@winner=winner
		@main.setWinner winner
		

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
	TinyFox:TinyFox
	Bat:Bat
	Noble:Noble
	Slave:Slave
	Magician:Magician
	Spy:Spy
	WolfDiviner:WolfDiviner
	Fugitive:Fugitive
	Merchant:Merchant
	QueenSpectator:QueenSpectator
	MadWolf:MadWolf
	Neet:Neet
	Liar:Liar
	Spy2:Spy2
	Copier:Copier
	Light:Light
	Fanatic:Fanatic
	Immoral:Immoral
	Devil:Devil
	ToughGuy:ToughGuy


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
	kicklog:(room,player)->
		log=
			comment:"#{player.name}さんが追い出されました。"
			userid:-1
			name:null
			mode:"system"
		if games[room.id]
			splashlog room.id,games[room.id], log
	deletedlog:(room)->
		log=
			comment:"この部屋は廃村になりました。"
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
		player=game.players.filter((x)->x.realid==session.user_id)[0]
		unless player?
			session.channel.subscribe "room#{roomid}_audience"
			session.channel.subscribe "room#{roomid}_notwerewolf"
			session.channel.subscribe "room#{roomid}_notcouple"
			return
			
		if player.dead
			session.channel.subscribe "room#{roomid}_heaven"
		if player.isWerewolf()
			session.channel.subscribe "room#{roomid}_werewolf"
		else if game.rule.heavenview!="view" || !player.dead
			session.channel.subscribe "room#{roomid}_notwerewolf"
		if player.type=="Couple"
			session.channel.subscribe "room#{roomid}_couple"
		else if !player.dead || game.rule.heavenview!="view"
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
		SS.server.game.rooms.oneRoomS roomid,(room)->
			if room.error? 
				cb room.error
				return
			unless room.mode=="waiting"
				# すでに開始している
				cb "そのゲームは既に開始しています"
				return
			game.setrule {
				number: room.players.length
				blind:room.blind
				
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
				deathnote:query.deathnote ? null	# デスノート採用
				divineresult:query.divineresult ? null
				psychicresult:query.psychicresult ? null
				waitingnight:query.waitingnight ? null
			}
			
			joblist={}
			for job in SS.shared.game.jobs
				joblist[job]=parseInt query[job]	# 仕事の数
			options={}
			for opt in ["decider","authority","yaminabe"]
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
			player=game.getPlayerReal @session.user_id
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
		player=game.getPlayerReal @session.user_id
		log =
			comment:comment
			userid:@session.user_id
			name:@session.attributes.user.name
			to:null
		# ログを流す
		dosp=->
			
			if !game.finished  && game.voting	# 投票猶予時間は発言できない
				if player && !player.dead
					return	#まだ死んでいないプレイヤーの場合は発言できないよ!
			if game.day<=0 || game.finished	#準備中
				log.mode="prepare"
			else
				# ゲームしている
				unless player?
					# 観戦者
					log.mode="audience"
				else if player.dead
					# 天国
					if player.type=="Spy" && player.flag=="spygone"
						# スパイなら会話に参加できない
						log.mode="monologue"
						log.to=player.id
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
						log.to=player.id
				
			splashlog roomid,game,log
			cb null
		if player?
			log.name=player.name
			log.userid=player.id
			dosp()
		else
			# ルーム情報から探す
			SS.server.game.rooms.oneRoomS roomid,(room)=>
				pl=room.players.filter((x)=>x.realid==@session.user_id)[0]
				if pl?
					log.name=pl.name
				dosp()
	# 夜の仕事・投票
	job:(roomid,query,cb)->
		game=games[roomid]
		unless game?
			cb {error:"そのゲームは存在しません"}
			return
		unless @session.user_id
			cb {error:"ログインして下さい"}
			return
		player=game.getPlayerReal @session.user_id
		unless player?
			cb {error:"参加していません"}
			return
		if player.dead
			cb {error:"お前は既に死んでいる"}
			return
		if !(to=game.players.filter((x)->x.id==query.target)[0]) && player.job_target!=0
			cb {error:"その対象は存在しません"}
			return
		if to?.dead && (!(player.job_target & Player.JOB_T_DEAD) || !game.night) && (player.job_target & Player.JOB_T_ALIVE)
			cb {error:"対象は既に死んでいます"}
			return
		if game.night
			# 夜
			if !to?.dead && !(player.job_target & Player.JOB_T_ALIVE) && (player.job_target & Player.JOB_T_DEAD)
				cb {error:"対象はまだ生きています"}
				return
			if player.jobdone()
				cb {error:"既に能力を行使しています"}
				return
			# エラーメッセージ
			if ret=player.job game,query.target,query
				cb {error:ret}
				return
			
			# 能力をすべて発動したかどうかチェック
			cb {jobdone:player.jobdone()}
			game.checkjobs()
		else
			# 投票
			if player.voteto?
				cb {error:"既に投票しています"}
				return
			if query.target==player.id && game.rule.votemyself!="ok"
				cb {error:"自分には投票できません"}
				return
			player.voteto=query.target
			log=
				mode:"system"
				to:player.id
				comment:"#{player.name}は#{to.name}に投票しました"
			splashlog game.id,game,log
			# 投票が終わったかチェック
			cb {jobdone:true}
			game.execute()
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
		player=game.getPlayerReal @session.user_id
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
	#DBに追加
	M.games.update {id:roomid},{$push:{logs:log}}
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
					SS.publish.channel "room#{roomid}_notwerewolf","log",log2
					
			when "couple"
				SS.publish.channel hv("room#{roomid}_couple"),"log",log
				if game.rule.couplesound=="aloud"
					# 共有者の小声が聞こえる
					log2=
						mode:"couple"
						comment:"ヒソヒソ・・・"
						name:"共有者の小声"
						time:log.time
					SS.publish.channel "room#{roomid}_notcouple","log",log2
			when "fox"
				SS.publish.channel hv("room#{roomid}_fox"),"log",log
			when "audience"
				# 観客
				SS.publish.channel hv("room#{roomid}_audience"),"log",log
			when "heaven"
				# 天国
				SS.publish.channel "room#{roomid}_heaven","log",log
	else
		pl=game.getPlayer log.to
		if pl
			SS.publish.user pl.realid, "log", log
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
		console.log "no! : #{log.to} -> #{player.id}"
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
		if game.rule.will=="die"
			result.will=player.will

	result
	
# 配列シャッフル（破壊的）
shuffle= (arr)->
	ret=[]
	while arr.length
		ret.push arr.splice(Math.floor(Math.random()*arr.length),1)[0]
	ret
		
