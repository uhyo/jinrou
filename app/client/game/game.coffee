
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
		sentlog=(result)->
			if result.error?
				SS.client.util.message "エラー",result.error
			else
				if result.game?.day>=1
					# ゲームが始まったら消す
					$("#playersinfo").empty()
				getjobinfo result
				$("#logs").empty()
				
				result.logs.forEach getlog
				gettimer parseInt(result.timer),null if result.timer?

		SS.server.game.game.getlog roomid,sentlog
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
				###
				li=document.createElement "li"
				li.title=x.userid
				if room.blind
					li.textContent=x.name
				else
					a=document.createElement "a"
					a.href="/user/#{x.userid}"
					a.textContent=x.name
					li.appendChild a
				if x.start	# 準備完了している
					b=document.createElement "b"
					b.textContent="[ready]"
					li.appendChild b
				###
				li=makeplayerbox x,room.blind
				$("#players").append li
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
				if room.mode=="waiting"
					# 開始前
					b=makebutton "準備完了/準備中"
					$("#playersinfo").append b
					$(b).click (je)->
						SS.server.game.rooms.ready roomid,(result)->
							if result?
								SS.client.util.message "ルーム",result
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
					SS.client.util.selectprompt "追い出す","追い出す人を選択して下さい",room.players.map((x)->{name:x.name,value:x.userid}),(id)->
#					SS.client.util.prompt "追い出す","追い出す人のidを入力して下さい:",null,(id)->
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
			pl=room.players.length
			if t.name=="jobrule"
				# ルール変更があった
				setplayersbyjobrule form,pl
				return
			if form.elements["scapegoat"].value=="on"
				# 身代わりくん
				pl++
			sum=0
			jobs.forEach (x)->
				sum+=parseInt form.elements[x].value
			form.elements["Human"].value=pl-sum
			setjobsmonitor form
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
			console.log this_rule
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
				"decider":
					"_name":"決定者"
					"1":"あり"
				"authority":
					"_name":"権力者"
					"1":"あり"
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
				"psychicresult":
					"_name":"霊能結果"
					"_default":"翌朝分かる"
					"sunset":"すぐ分かる"
				"waitingnight":
					"_name":"夜は時間限界まで待つか"
					"_default":"待たない"
					"wait":"待つ"
				"friendsjudge":
					"_name":"恋人の勝利条件"
					"alive":"終了時に生存"
					"_default":"恋人だけ生存"
				"noticebitten":
					"_name":"噛まれたら分かるか"
					"notice":"分かる"
					"_default":"分からない"
				"voteresult":
					"_name":"投票結果"
					"hide":"隠す"
			Object.keys(this_rule.rule).forEach (x)->
				tru=rulestr[x]
				return unless tru?
				val=tru[this_rule.rule[x]] ? tru._default
				return unless val
				p=document.createElement "p"
				p.textContent="#{tru._name} : #{val}"
				win.append p
				
			
		$("#willform").submit (je)->
			form=je.target
			je.preventDefault()
			SS.server.game.game.will roomid,form.elements["will"].value,(result)->
				if result?
					SS.client.util.message "エラー",result
				else
					$("#willform").get(0).hidden=true
					$("#speakform").get(0).elements["willbutton"].value="遺言"
		
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
			###
			li=document.createElement "li"
			li.title=msg.userid
			if room.blind
				li.textContent=msg.name
			else
				a=document.createElement "a"
				a.href="/user/#{msg.userid}"
				a.textContent=msg.name
				li.appendChild a
			###
			li=makeplayerbox msg,room.blind
			$("#players").append li
		# 誰かが出て行った!!!
		socket_ids.push SS.client.socket.on "unjoin","room#{roomid}",(msg,channel)->
			room.players=room.players.filter (x)->x.userid!=msg
			
			$("#players li").filter((idx)-> this.dataset.id==msg).remove()
		# 準備
		socket_ids.push SS.client.socket.on "ready","room#{roomid}",(msg,channel)->
			for pl in room.players
				if pl.userid==msg.userid
					pl.start=msg.start
					li=$("#players li").filter((idx)-> this.dataset.id==msg.userid)
					li.replaceWith makeplayerbox pl,room.blind
			
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
				#SS.client.app.refresh()
				SS.server.game.rooms.enter roomid,sessionStorage.roompassword ? null,(result)->
					#SS.server.game.rooms.oneRoom roomid,initroom
					SS.server.game.game.getlog roomid,sentlog
				SS.server.game.rooms.oneRoom roomid,(r)->room=r
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
	
	# 役職入力フォームを作る
	for job in SS.shared.game.jobs
		# 探す
		continue if job=="Human"	# 村人だけは既に置いてある（あまり）
		for team,members of SS.shared.game.teams
			if job in members
				dt=document.createElement "dt"
				dt.textContent=SS.shared.game.jobinfo[team][job].name
				dd=document.createElement "dd"
				input=document.createElement "input"
				input.type="number"
				input.min=0; input.step=1; input.size=5; input.value=0
				input.name=job
				input.dataset.jobname=SS.shared.game.jobinfo[team][job].name
				dd.appendChild input
				$("#jobsfield").append(dt).append dd
	# 配役タイプ
	setjobrule=(rulearr,names,parent)->
		for obj in rulearr
			# name,title, ruleをもつ
			if obj.rule instanceof Array
				# さらに子
				optgroup=document.createElement "optgroup"
				optgroup.label=obj.name
				parent.appendChild optgroup
				setjobrule obj.rule,names.concat([obj.name]),optgroup
			else
				# option
				option=document.createElement "option"
				option.textContent=obj.name
				option.value=names.concat([obj.name]).join "."
				option.title=obj.title
				parent.appendChild option
				
	setjobrule SS.shared.game.jobrules.concat([
		name:"特殊ルール"
		rule:[
			{
				name:"自由配役"
				title:"配役を自由に設定できます。"
				rule:null
			}
			{
				name:"闇鍋"
				title:"配役がランダムに設定されます。"
				rule:null
			}
			{
				name:"一部闇鍋"
				title:"一部の配役を固定して残りをランダムにします。"
				rule:null
			}
		]
	]),[],$("#jobruleselect").get 0
	
		
	setplayersnumber=(form,number)->
		
		setplayersbyjobrule form,number
	# 配役一覧をアレする
	setplayersbyjobrule=(form,number)->
		jobrulename=form.elements["jobrule"].value
		if jobrulename in ["特殊ルール.自由配役","特殊ルール.一部闇鍋"]
			$("#jobsfield").get(0).hidden=false
			$("#yaminabe_opt").get(0).hidden= jobrulename!="特殊ルール.一部闇鍋"
			return
		else if jobrulename=="特殊ルール.闇鍋"
			$("#jobsfield").get(0).hidden=true
			$("#yaminabe_opt").get(0).hidden=false
			setjobsmonitor form
			return
		else
			$("#jobsfield").get(0).hidden=true
			$("#yaminabe_opt").get(0).hidden=true
		if form.elements["scapegoat"].value=="on"
			number++	# 身代わりくん
		obj= SS.shared.game.getrulefunc jobrulename
		return unless obj?

		form.elements["number"]=number
		for x in SS.shared.game.jobs
			form.elements[x].value=0
		jobs=obj number
		count=0	#村人以外
		for job,num of jobs
			form.elements[job]?.value=num
			count+=num
		form.elements["Human"].value=number-count	# 村人
		setjobsmonitor form
	# 配役をテキストで書いてあげる
	setjobsmonitor=(form)->
		text=""
		if form.elements["jobrule"].value=="特殊ルール.闇鍋"
			# 闇鍋の場合
			$("#jobsmonitor").text "闇鍋 / 人狼#{form.elements["yaminabe_Werewolf"].value} 妖狐#{form.elements["yaminabe_Fox"].value}"
			return
		if form.elements["jobrule"].value=="特殊ルール.一部闇鍋"
			text="闇鍋 / "

		for job in SS.shared.game.jobs
			continue if job=="Human" && form.elements["jobrule"].value=="特殊ルール.一部闇鍋"	#一部闇鍋は村人部分だけ闇鍋
			input=form.elements[job]
			num=input.value
			continue unless parseInt num
			text+="#{input.dataset.jobname}#{num} "
		$("#jobsmonitor").text SS.shared.game.getrulestr form.elements["jobrule"].value, SS.client.util.formQuery form
		
		
	#ログをもらった
	getlog=(log)->
		if log.mode == "voteresult"
			# 表を出す
			p=document.createElement "div"
			div=document.createElement "div"
			div.classList.add "name"
			p.appendChild div
			
			tb=document.createElement "table"
			tb.createCaption().textContent="投票結果"
			vr=log.voteresult
			tos=log.tos
			vr.forEach (player)->
				tr=tb.insertRow(-1)
				tr.insertCell(-1).textContent=player.name
				tr.insertCell(-1).textContent="#{tos[player.id] ? '0'}票"
				tr.insertCell(-1).textContent="→#{vr.filter((x)->x.id==player.voteto)[0]?.name ? ''}"
			p.appendChild tb
		else
			p=document.createElement "p"
			div=document.createElement "div"
			div.classList.add "name"
			if log.name?
				div.textContent=switch log.mode
					when "monologue"
						"#{log.name}の独り言:"
					when "will"
						"#{log.name}の遺言:"
					else
						"#{log.name}:"
			p.appendChild div
			
			span=document.createElement "div"
			span.classList.add "comment"
			wrdv=document.createElement "div"
			wrdv.textContent=log.comment
			if log.mode=="will"
				# 遺言
				spp=wrdv.firstChild	# Text
				wr=0
				while (wr=spp.nodeValue.indexOf("\n"))>=0
					spp=spp.splitText wr+1
					wrdv.insertBefore document.createElement("br"),spp
			parselognode wrdv
			span.appendChild wrdv
			
			p.appendChild span
			if log.time?
				time=SS.client.util.timeFromDate new Date log.time
				time.classList.add "time"
				p.appendChild time
		
		p.classList.add log.mode
		
		logs=$("#logs").get 0
		logs.insertBefore p,logs.firstChild
	
	# プレイヤーオブジェクトのプロパティを得る
	###
	getprop=(obj,propname)->
		if obj[propname]?
			obj[propname]
		else if obj.main?
			getprop obj.main,propname
		else
			undefined
	getname=(obj)->getprop obj,"name"
	###
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
		if obj.friends?.length>0
			$("#jobinfo").append pp "恋人は#{obj.friends.map((x)->x.name).join(',')}"
		if obj.stalking?
			console.log obj.stalking
			$("#jobinfo").append pp "あなたは#{obj.stalking.name}のストーカーです"
		if obj.cultmembers?
			$("#jobinfo").append pp "信者は#{obj.cultmembers.map((x)->x.name).join(',')}"
		if obj.vampires?
			$("#jobinfo").append pp "ヴァンパイアは#{obj.vampires.map((x)->x.name).join(',')}"
		
		if obj.winner?
			# 勝敗
			$("#jobinfo").append pp "#{if obj.winner then '勝利' else '敗北'}しました"
		if obj.dead
			# 自分は既に死んでいる
			document.body.classList.add "heaven"
		if obj.will
			$("#willform").get(0).elements["will"].value=obj.will
			
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
		$("#playernumberinfo").text "生存者#{players.filter((x)->!x.dead).length}人 / 死亡者#{players.filter((x)->x.dead).length}人"
		players.forEach (x)->
			# 上の一覧用
			li=makeplayerbox x
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
		
# ノードのコメントなどをパースする
exports.parselognode=parselognode=(node)->
	if node.nodeType==Node.TEXT_NODE
		# text node
		return unless node.parentNode
		result=document.createDocumentFragment()
		while v=node.nodeValue
			if res=v.match /^(.*?)(https?:\/\/)([^\s\/]+)(\/\S*)?/
				if res[1]
					# 前の部分
					node=node.splitText res[1].length
					parselognode node.previousSibling
				console.log res
				url = res[2]+res[3]+(res[4] ? "")
				a=document.createElement "a"
				a.href=url
				if res[4] in ["","/"] && res[3].length<10
					a.textContent=res[3]
				else if res[0].length<10
					a.textContent=res[0]
				else
					a.textContent="#{res[3].slice(0,10)}..."
				a.target="_blank"
				node=node.splitText url.length
				node.parentNode.replaceChild a,node.previousSibling
				continue
				
			if res=v.match /^(.*?)#(\d+)/
				if res[1]
					# 前の部分
					node=node.splitText res[1].length
					parselognode node.previousSibling
				a=document.createElement "a"
				a.href="/room/#{res[2]}"
				a.textContent="##{res[2]}"
				node=node.splitText res[2].length+1	# その部分どける
				node.parentNode.replaceChild a,node.previousSibling
				continue
			node.nodeValue=v.replace /(\w{30})(?=\w)/g,"$1\u200b"

			break
	else if node.childNodes
		for ch in node.childNodes
			if ch.parentNode== node
				parselognode ch
			
# #players用要素
makeplayerbox=(obj,blindflg,tagname="li")->#obj:game.playersのアレ
	#df=document.createDocumentFragment()
	df=document.createElement tagname
	
	df.dataset.id=obj.userid
	p=document.createElement "p"
	p.classList.add "name"
	
	unless blindflg
		a=document.createElement "a"
		a.href="/user/#{obj.realid ? obj.userid}"
		a.textContent=obj.name
		p.appendChild a
	else
		p.textContent=obj.name
	df.appendChild p

	if obj.jobname
		p=document.createElement "p"
		p.classList.add "job"
		if obj.originalJobname?
			if obj.originalJobname==obj.jobname || obj.originalJobname.indexOf("→")>=0
				p.textContent=obj.originalJobname
			else
				p.textContent="#{obj.originalJobname}→#{obj.jobname}"
		else
			p.textContent=obj.jobname
		if obj.option
			p.textContent+= "（#{obj.option}）"
		df.appendChild p
		if obj.winner?
			p=document.createElement "p"
			p.classList.add "outcome"
			if obj.winner
				p.classList.add "win"
				p.textContent="勝利"
			else
				p.classList.add "lose"
				p.textContent="敗北"
			df.appendChild p
	if obj.dead
		df.classList.add "dead"
	if obj.start
		# 準備完了
		p=document.createElement "p"
		p.classList.add "job"
		p.textContent="[ready]"
		df.appendChild p
	df
		
