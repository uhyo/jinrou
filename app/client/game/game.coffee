
this_room_id=null

socket_ids=[]
my_job=null

timerid=null	# setTimeout
remain_time=null
this_rule=null	# ルールオブジェクトがある
enter_result=null #enter

exports.start=(roomid)->
	this_rule=null
	timerid=null
	remain_time=null
	my_job=null
	this_room_id=null
	
	getenter=(result)->
		if result.error?
			# エラー
			SS.client.util.message "ルーム",result.error
			return
		else if result.require?
			if result.require=="password"
				#パスワード入力
				SS.client.util.prompt "ルーム","パスワードを入力して下さい",{type:"password"},(pass)->
					unless pass?
						SS.client.app.showUrl "/rooms"
						return
					SS.server.game.rooms.enter roomid,pass,getenter
					sessionStorage.roompassword = pass
			return
		enter_result=result
		this_room_id=roomid
		SS.server.game.rooms.oneRoom roomid,initroom
	SS.server.game.rooms.enter roomid,sessionStorage.roompassword ? null,getenter
	initroom=(room)->
		unless room?
			SS.client.util.message "ルーム","そのルームは存在しません。"
			SS.client.app.showUrl "/rooms"
			return
		# 今までのログを送ってもらう
		SS.server.game.game.getlog roomid,(result)->
			if result.error?
				SS.client.util.message "エラー",result.error
			else
				getjobinfo result
				result.logs.forEach getlog
				gettimer parseInt(result.timer),null if result.timer?
				console.log result
										


			
		# 新しいゲーム
		newgamebutton = (je)->
			form=$("#gamestart").get 0
			form.elements["number"].value=room.players.length
			setplayersnumber form,room.players.length

			$("#gamestartsec").removeAttr "hidden"
		$("#roomname").text room.name
		if room.mode=="waiting"
			# 開始前のユーザー一覧は roomから取得する
			room.players.forEach (x)->
				li=document.createElement "li"
				li.title=x.userid
				if room.blind
					li.textContent=x.name
				else
					a=document.createElement "a"
					a.href="/user/#{x.userid}"
					a.textContent=x.name
					li.appendChild a
				$("#players").append li
			console.log enter_result
			unless enter_result?.joined
				# 未参加
				b=makebutton "ゲームに参加"
				$("#playersinfo").append b
				$(b).click (je)->
					# 参加
					opt={}
					into=->
						SS.server.game.rooms.join roomid,opt,(result)->
							if result?
								SS.client.util.message "ルーム",result
							else
								SS.client.app.refresh()
					if room.blind
						# 参加者名
						SS.client.util.prompt "ゲームに参加","名前を入力して下さい",null,(name)->
							if name
								opt.name=name
								into()
					else
						into()
			else
				b=makebutton "ゲームから脱退"
				$("#playersinfo").append b
				$(b).click (je)->
					# 脱退
					SS.server.game.rooms.unjoin roomid,(result)->
						if result?
							SS.client.util.message "ルーム",result
						else
							SS.client.app.refresh()
		userid=SS.client.app.userid()
		if room.mode=="waiting"
			if room.owner.userid==SS.client.app.userid()
				# 自分
				b=makebutton "ゲームを開始"
				$("#playersinfo").append b
				$(b).click newgamebutton
				b=makebutton "参加者を追い出す"
				$("#playersinfo").append b
				$(b).click (je)->
					SS.client.util.prompt "追い出す","追い出す人のidを入力して下さい:",null,(id)->
						SS.server.game.rooms.kick roomid,id,(result)->
							if result?
								SS.client.util.message "エラー",result
				b=makebutton "部屋を削除"
				$("#playersinfo").append b
				$(b).click (je)->
					SS.client.util.ask "部屋削除","本当に部屋を削除しますか?",(cb)->
						if cb
							SS.server.game.rooms.del roomid,(result)->
								if result?
									SS.client.util.message "エラー",result


		form=$("#gamestart").get 0
		jobs=SS.shared.game.jobs.filter (x)->x!="Human"	# 村人は自動で決定する
		jobsforminput=(e)->
			t=e.target
			form=t.form
			sum=0
			jobs.forEach (x)->
				sum+=parseInt form.elements[x].value
			pl=room.players.length
			if form.elements["scapegoat"].value=="on"
				# 身代わりくん
				pl++
			form.elements["Human"].value=pl-sum
		form.addEventListener "input",jobsforminput,false
		form.addEventListener "change",jobsforminput,false
				
				
		$("#gamestart").submit (je)->
			# いよいよゲーム開始だ！
			query=SS.client.util.formQuery je.target
			SS.server.game.game.gameStart roomid,query,(result)->
				if result?
					SS.client.util.message "ルーム",result
				else
					$("#gamestartsec").attr "hidden","hidden"
			je.preventDefault()
		$("#speakform").submit (je)->
			form=je.target
			SS.server.game.game.speak roomid,form.elements["comment"].value,(result)->
				if result?
					SS.client.util.message "エラー",result
			je.preventDefault()
			form.elements["comment"].value=""
		.get(0).elements["willbutton"].addEventListener "click", (e)->
			# 遺言フォームオープン
			wf=$("#willform").get 0
			console.log wf
			if wf.hidden
				wf.hidden=false
				e.target.value="遺言を隠す"
			else
				wf.hidden=true
				e.target.value="遺言"
		,false
		# ルール表示
		$("#speakform").get(0).elements["rulebutton"].addEventListener "click", (e)->
			return unless this_rule?
			win=SS.client.util.blankWindow()
			p=document.createElement "p"
			Object.keys(this_rule.jobscount).forEach (x)->
				a=document.createElement "a"
				a.href="/manual/job/#{x}"
				a.textContent="#{this_rule.jobscount[x].name}#{this_rule.jobscount[x].number}"
				p.appendChild a
				p.appendChild document.createTextNode " "
			win.append p
			rulestr=
				"scapegoat":
					"_name":"一日目"
					"_default":""
					"on":"身代わり君が死ぬ"
					"off":"参加者が死ぬ"
					"no":"誰も死なない"
				"will":
					"_name":"遺言"
					"_default":"なし"
					"die":"あり"
				"wolfsound":
					"_name":"人狼の遠吠え"
					"_default":"聞こえない"
					"aloud":"聞こえる"
				"couplesound":
					"_name":"共有者の声"
					"_default":"聞こえない"
					"aloud":"聞こえる"
				"heavenview":
					"_name":"死んだ後"
					"_default":"役職は分からない"
					"view":"役職や全員の発言が見える"
				"wolfattack":
					"_name":"人狼が人狼を襲う"
					"_default":"不可"
					"ok":"可能"
				"guardmyself":
					"_name":"狩人の自分守り"
					"_default":"不可"
					"ok":"可能"
				"votemyself":
					"_name":"昼に自分へ投票"
					"_default":"不可"
					"ok":"可能"
				"deadfox":
					"_name":"妖狐の呪殺死体"
					"_default":"人狼によるのと区別がつかない"
					"ok":"人狼によるのと区別が付く"
				"divineresult":
					"_name":"占い結果"
					"_default":"翌朝分かる"
					"immediate":"すぐ分かる"
				"waitingnight":
					"_name":"夜は時間限界まで待つか"
					"_default":"待たない"
					"wait":"待つ"
			Object.keys(this_rule.rule).forEach (x)->
				tru=rulestr[x]
				return unless tru?
				p=document.createElement "p"
				p.textContent="#{tru._name} : #{tru[this_rule.rule[x]] ? tru._default}"
				win.append p
				
			
		$("#willform").submit (je)->
			form=je.target
			je.preventDefault()
			SS.server.game.game.will roomid,form.elements["will"].value,(result)->
				if result?
					SS.client.util.message "エラー",result
				else
					$("#willform").attr "hidden","hidden"
		
		# 夜の仕事（あと投票）
		$("#jobform").submit (je)->
			form=je.target
			je.preventDefault()
			$("#jobform").attr "hidden","hidden"
			SS.server.game.game.job roomid,SS.client.util.formQuery(form), (result)->
				if result?.error?
					SS.client.util.message "エラー",result.error
					$("#jobform").removeAttr "hidden"
				else if !result?.jobdone
					# まだ仕事がある
					$("#jobform").removeAttr "hidden"
		.click (je)->
			bt=je.target
			if bt.type=="submit"
				# 送信ボタン
				bt.form.elements["commandname"].value=bt.name	# コマンド名教えてあげる
				bt.form.elements["jobtype"].value=bt.dataset.job	# 役職名も教えてあげる
		#========================================
			
		# 誰かが参加した!!!!
		socket_ids.push SS.client.socket.on "join","room#{roomid}",(msg,channel)->
			room.players.push msg
			
			li=document.createElement "li"
			li.title=msg.userid
			if room.blind
				li.textContent=msg.name
			else
				a=document.createElement "a"
				a.href="/user/#{msg.userid}"
				a.textContent=msg.name
				li.appendChild a
			$("#players").append li
		# 誰かが出て行った!!!
		socket_ids.push SS.client.socket.on "unjoin","room#{roomid}",(msg,channel)->
			console.log msg
			room.players=room.players.filter (x)->x.userid!=msg
			
			$("#players li").filter((idx)-> this.title==msg).remove()
		# ログが流れてきた!!!
		socket_ids.push SS.client.socket.on "log",null,(msg,channel)->
			if channel=="room#{roomid}" || channel.indexOf("room#{roomid}_")==0 || channel==SS.client.app.userid()
				# この部屋へのログ
				getlog msg
		# 職情報を教えてもらった!!!
		socket_ids.push SS.client.socket.on "getjob",null,(msg,channel)->
			if channel=="room#{roomid}" || channel.indexOf("room#{roomid}_")==0 || channel==SS.client.app.userid()
				getjobinfo msg
		# 更新したほうがいい
		socket_ids.push SS.client.socket.on "refresh",null,(msg,channel)->
			if msg.id==roomid
				SS.client.app.refresh()
		# 投票フォームオープン
		socket_ids.push SS.client.socket.on "voteform",null,(msg,channel)->
			if channel=="room#{roomid}" || channel.indexOf("room#{roomid}_")==0 || channel==SS.client.app.userid()
				if msg
					$("#jobform").removeAttr "hidden"
				else
					$("#jobform").attr "hidden","hidden"
		# 残り時間
		socket_ids.push SS.client.socket.on "time",null,(msg,channel)->
			if channel=="room#{roomid}" || channel.indexOf("room#{roomid}_")==0 || channel==SS.client.app.userid()
				gettimer parseInt(msg.time),msg.mode
				
		
	setplayersnumber=(form,number)->
		form.elements["number"]=number
		form.elements[x].value=0 for x in SS.shared.game.jobs

		hu=number	# 村人
		huall=hu
		if form.elements["scapegoat"].value=="on"
			hu++
		# 人狼
		form.elements["Werewolf"].value=2
		hu-=2
		# 占い師
		form.elements["Diviner"].value=1
		hu--
		#9人異常：霊能者
		form.elements["Psychic"].value=if huall>=9
			hu--
			1
		else
			0
		#10人異常：狂人
		form.elements["Madman"].value=if huall>=10
			hu--
			1
		else
			0
		#11人以上：狩人
		form.elements["Guard"].value=if huall>=11
			hu--
			1
		else
			0
		#13人以上：共有者
		form.elements["Couple"].value=if huall>=13
			hu-=2
			2
		else
			0
		# 15人以上：妖狐
		form.elements["Fox"].value=if huall>=15
			hu--
			1
		else
			0
			
			
		form.elements["decider"].checked= huall>=16
		form.elements["authority"].checked= huall>=16
		
		form.elements["will"].checked=true
		form.elements["wolfsound"].checked=true
		form.elements["heavenview"].checked=true
	
		
		form.elements["Human"].value=hu
		
	#ログをもらった
	getlog=(log)->
		if log.mode == "voteresult"
			# 表を出す
			p=document.createElement "table"
			p.createCaption().textContent="投票結果"
			vr=log.voteresult
			tos=log.tos
			vr.forEach (player)->
				tr=p.insertRow(-1)
				tr.insertCell(-1).textContent=player.name
				tr.insertCell(-1).textContent="#{tos[player.id] ? '0'}票"
				tr.insertCell(-1).textContent="→#{vr.filter((x)->x.id==player.voteto)[0]?.name ? ''}"
		else
			p=document.createElement "p"
			if log.name?
				span=document.createElement "span"
				span.classList.add "name"
				span.textContent=switch log.mode
					when "monologue"
						"#{log.name}の独り言:"
					when "will"
						"#{log.name}の遺言:"
					else
						"#{log.name}:"
				p.appendChild span
			span=document.createElement "span"
			span.classList.add "comment"
			span.textContent=log.comment
			if log.mode=="will"
				# 遺言
				spp=span.firstChild	# Text
				wr=0
				while (wr=spp.nodeValue.indexOf("\n"))>=0
					spp=spp.splitText wr+1
					span.insertBefore document.createElement("br"),spp
			
			p.appendChild span
			if log.time?
				time=SS.client.util.timeFromDate new Date log.time
				p.appendChild time
		
		p.classList.add log.mode
		
		logs=$("#logs").get 0
		logs.insertBefore p,logs.firstChild
	# 役職情報をもらった
	getjobinfo=(obj)->
		return unless obj.id==this_room_id
		my_job=obj.type
		$("#jobinfo").empty()
		pp=(text)->
			p=document.createElement "p"
			p.textContent=text
			p
		if obj.type
			$("#jobinfo").append $ "<p>あなたは<b>#{obj.jobname}</b>です（<a href='/manual/job/#{obj.type}'>詳細</a>)</p>"
		if obj.wolves?
			$("#jobinfo").append pp "仲間の人狼は#{obj.wolves.map((x)->x.name).join(",")}"
		if obj.peers?
			$("#jobinfo").append pp "共有者は#{obj.peers.map((x)->x.name).join(',')}"
		if obj.foxes?
			$("#jobinfo").append pp "仲間の妖狐は#{obj.foxes.map((x)->x.name).join(',')}"
		if obj.nobles?
			$("#jobinfo").append pp "貴族は#{obj.nobles.map((x)->x.name).join(',')}"
		if obj.queens?.length>0
			$("#jobinfo").append pp "女王観戦者は#{obj.queens.map((x)->x.name).join(',')}"
		if obj.spy2s?.length>0
			$("#jobinfo").append pp "スパイⅡは#{obj.spy2s.map((x)->x.name).join(',')}"
		if obj.winner?
			# 勝敗
			$("#jobinfo").append pp "#{if obj.winner then '勝利' else '敗北'}しました"
		if obj.dead
			# 自分は既に死んでいる
			document.body.classList.add "heaven"
			
		if game=obj.game
			if game.finished
				# 終了
				document.body.classList.add "finished"
				document.body.classList.remove x for x in ["day","night"]
				$("#jobform").attr "hidden","hidden"
				if timerid
					clearInterval timerid
					timerid=null
			else
				document.body.classList.add (if game.night then "night" else "day")
				document.body.classList.remove (if game.night then "day" else "night")
			unless $("#jobform").get(0).hidden= obj.dead || game.finished ||  obj.sleeping || !obj.type
				# 代入しつつの　投票フォーム必要な場合
				$("#jobform div.jobformarea").attr "hidden","hidden"
				$("#form_day").get(0).hidden= game.night || obj.sleeping
				if game.night
					obj.open?.forEach (x)->
						# 開けるべきフォームが指定されている
						$("#form_#{x}").get(0).hidden=false
			if game.day>0 && game.players
				formplayers game.players,if game.night then obj.job_target else 1
				unless this_rule?
					$("#speakform").get(0).elements["rulebutton"].disabled=false
				this_rule=
					jobscount:game.jobscount
					rule:game.rule
	formplayers=(players,jobflg)->	#jobflg: 1:生存の人 2:死人
		$("#form_players").empty()
		$("#players").empty()
		players.forEach (x)->
			# 上の一覧用
			li=document.createElement "li"
			li.title=x.id
			if x.realid
				a=document.createElement "a"
				a.href="/user/#{x.realid}"
				a.textContent=x.name+" "
				li.appendChild a
			else
				li.textContent=x.name+" "
			if x.jobname
				b=document.createElement "b"
				b.textContent=x.jobname
				if x.option
					b.textContent+= "（#{x.option}）"
				li.appendChild b
			if x.dead
				li.classList.add "dead"
			$("#players").append li

			# 投票フォーム用
			li=document.createElement "li"
			if x.dead
				li.classList.add "dead"
			label=document.createElement "label"
			label.textContent=x.name
			input=document.createElement "input"
			input.type="radio"
			input.name="target"
			input.value=x.id
			input.disabled=!((x.dead && (jobflg&2))||(!x.dead && (jobflg&1)))
			label.appendChild input
			li.appendChild label
			$("#form_players").append li
	# タイマー情報をもらった
	gettimer=(msg,mode)->
		remain_time=parseInt msg
		clearInterval timerid if timerid?
		timerid=setInterval ->
			remain_time--
			return if remain_time<0
			min=parseInt remain_time/60
			sec=remain_time%60
			$("#time").text "#{mode || ''} #{min}:#{sec}"
		,1000
			
	makebutton=(text)->
		b=document.createElement "button"
		b.type="button"
		b.textContent=text
		b
		
		
			
exports.end=->
	SS.server.game.rooms.exit this_room_id,(result)->
		if result?
			SS.client.util.message "ルーム",result
			return
	clearInterval timerid if timerid?
	alloff socket_ids...
	document.body.classList.remove x for x in ["day","night","finished","heaven"]
	
#ソケットを全部off
alloff= (ids...)->
	ids.forEach (x)->
		SS.client.socket.off x
		
	
		
