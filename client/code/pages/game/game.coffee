
this_room_id=null

socket_ids=[]
my_job=null

timerid=null	# setTimeout
remain_time=null
this_rule=null	# ルールオブジェクトがある
enter_result=null #enter

this_icons={}	#名前とアイコンの対応表
this_logdata={}	# ログデータをアレする
this_style=null	#style要素（終わったら消したい）

exports.start=(roomid)->
	this_rule=null
	timerid=null
	remain_time=null
	my_job=null
	this_room_id=null

	# CSS操作
	this_style=document.createElement "style"
	document.head.appendChild this_style
	sheet=this_style.sheet
	#現在のルール
	myrules=
		player:null	# プレイヤー・ネーム
		day:"all"	# 表示する日にち
	setcss=->
		while sheet.cssRules.length>0
			sheet.deleteRule 0
		if myrules.player?
			sheet.insertRule "#logs > div:not([data-name=\"#{myrules.player}\"]) {opacity: .5}",0
		day=null
		if myrules.day=="today"
			day=this_logdata.day	# 現在
		else if myrules.day!="all"
			day=parseInt myrules.day	# 表示したい日
		
		if day?
			# 表示する
			sheet.insertRule "#logs > div:not([data-day=\"#{day}\"]){display: none}",0

	getenter=(result)->
		if result.error?
			# エラー
			Index.util.message "ルーム",result.error
			return
		else if result.require?
			if result.require=="password"
				#パスワード入力
				Index.util.prompt "ルーム","パスワードを入力して下さい",{type:"password"},(pass)->
					unless pass?
						Index.app.showUrl "/rooms"
						return
					ss.rpc "game.rooms.enter", roomid,pass,getenter
					sessionStorage.roompassword = pass
			return
		enter_result=result
		this_room_id=roomid
		ss.rpc "game.rooms.oneRoom", roomid,initroom
	ss.rpc "game.rooms.enter", roomid,sessionStorage.roompassword ? null,getenter
	initroom=(room)->
		unless room?
			Index.util.message "ルーム","そのルームは存在しません。"
			Index.app.showUrl "/rooms"
			return
		# フォームを修正する
		forminfo=->
			setplayersnumber room,$("#gamestart").get(0), room.players.filter((x)->x.mode=="player").length
		# 今までのログを送ってもらう
		this_icons={}
		this_logdata={}
		sentlog=(result)->
			if result.error?
				Index.util.message "エラー",result.error
			else
				if result.game?.day>=1
					# ゲームが始まったら消す
					$("#playersinfo").empty()
				getjobinfo result
				$("#logs").empty()
				$("#chooseviewday").empty()	# 何日目だけ表示
				if result.game?.finished
					# 終了した・・・次のゲームボタン
					b=makebutton "同じ設定で次の部屋を建てる","建てたあとも設定の変更は可能です。"
					$("#playersinfo").append b
					$(b).click (je)->
						# ルールを保存
						sessionStorage.savedRule=JSON.stringify result.game.rule
						sessionStorage.savedJobs=JSON.stringify result.game.jobscount
						Index.app.showUrl "/newroom"

				
				result.logs.forEach getlog
				gettimer parseInt(result.timer),null if result.timer?

		ss.rpc "game.game.getlog", roomid,sentlog
		# 新しいゲーム
		newgamebutton = (je)->
			form=$("#gamestart").get 0
			# ルール設定保存を参照する
			if sessionStorage.savedRule
				rule=JSON.parse sessionStorage.savedRule
				jobs=JSON.parse sessionStorage.savedJobs
				# 時間設定
				daysec=rule.day-0
				nightsec=rule.night-0
				remainsec=rule.remain-0
				form.elements["day_minute"].value=parseInt daysec/60
				form.elements["day_second"].value=daysec%60
				form.elements["night_minute"].value=parseInt nightsec/60
				form.elements["night_second"].value=nightsec%60
				form.elements["remain_minute"].value=parseInt remainsec/60
				form.elements["remain_second"].value=remainsec%60
				# その他
				for key of rule
					e=form.elements[key]
					if e?
						if e.type=="checkbox"
							e.checked = e.value==rule[key]
						else
							e.value=rule[key]
				# 配役も再現
				for job in Shared.game.jobs
					e=form.elements[job]	# 役職
					if e?
						e.value=jobs[job]?.number ? 0
				# 役目終了
				delete sessionStorage.savedRule
				delete sessionStorage.savedJobs

			forminfo()

			$("#gamestartsec").removeAttr "hidden"
		$("#roomname").text room.name
		if room.mode=="waiting"
			# 開始前のユーザー一覧は roomから取得する
			room.players.forEach (x)->
				li=makeplayerbox x,room.blind
				$("#players").append li
			unless enter_result?.joined
				# 未参加
				b=makebutton "ゲームに参加"
				$("#playersinfo").append b
				$(b).click (je)->
					# 参加
					opt=
						name:""
						icon:null
					into=->
						ss.rpc "game.rooms.join", roomid,opt,(result)->
							if result?.require=="login"
								# ログインが必要
								Index.util.loginWindow ->
									if Index.app.userid()
										into()
							else if result?.error?
								Index.util.message "ルーム",result.error
							else
								Index.app.refresh()


					if room.blind
						# 参加者名
						###
						Index.util.prompt "ゲームに参加","名前を入力して下さい",null,(name)->
							if name
								opt.name=name
								into()
						###
						# ここ書いてないよ!
						Index.util.blindName null,(obj)->
							if obj?
								opt.name=obj.name
								opt.icon=obj.icon
								into()
					else
						into()
			else
				b=makebutton "ゲームから脱退"
				$("#playersinfo").append b
				$(b).click (je)->
					# 脱退
					ss.rpc "game.rooms.unjoin", roomid,(result)->
						if result?
							Index.util.message "ルーム",result
						else
							Index.app.refresh()
				if room.mode=="waiting"
					# 開始前
					b=makebutton "準備完了/準備中","全員が準備完了になるとゲームを開始できます。"
					$("#playersinfo").append b
					$(b).click (je)->
						ss.rpc "game.rooms.ready", roomid,(result)->
							if result?
								Index.util.message "ルーム",result
				b=makebutton "ヘルパー","ヘルパーになると、ゲームに参加せずに助言役になります。"
				# ヘルパーになる/やめるボタン
				$(b).click (je)->
					Index.util.selectprompt "ヘルパー","誰のヘルパーになりますか?",room.players.map((x)->{name:x.name,value:x.userid}),(id)->
						ss.rpc "game.rooms.helper",roomid, id,(result)->
							if result?
								Index.util.message "エラー",result
				$("#playersinfo").append b

		userid=Index.app.userid()
		if room.mode=="waiting"
			if room.owner.userid==Index.app.userid()
				# 自分
				b=makebutton "ゲーム開始画面を開く"
				$("#playersinfo").append b
				$(b).click newgamebutton
				if sessionStorage.savedRule?
					# セーブされているなら勝手に開いてあげる
					newgamebutton()
				b=makebutton "参加者を追い出す"
				$("#playersinfo").append b
				$(b).click (je)->
					Index.util.selectprompt "追い出す","追い出す人を選択して下さい",room.players.map((x)->{name:x.name,value:x.userid}),(id)->
#					Index.util.prompt "追い出す","追い出す人のidを入力して下さい:",null,(id)->
						ss.rpc "game.rooms.kick", roomid,id,(result)->
							if result?
								Index.util.message "エラー",result
			if room.owner.userid==Index.app.userid() || room.old
				b=makebutton "この部屋を廃村にする"
				$("#playersinfo").append b
				$(b).click (je)->
					Index.util.ask "部屋削除","本当に部屋を削除しますか?",(cb)->
						if cb
							ss.rpc "game.rooms.del", roomid,(result)->
								if result?
									Index.util.message "エラー",result
										


			


		form=$("#gamestart").get 0
		jobs=Shared.game.jobs.filter (x)->x!="Human"	# 村人は自動で決定する
		jobsforminput=(e)->
			t=e.target
			form=t.form
			pl=room.players.filter((x)->x.mode=="player").length
			if t.name=="jobrule"
				# ルール変更があった
				setplayersbyjobrule room,form,pl
				return
			if form.elements["scapegoat"].value=="on"
				# 身代わりくん
				pl++
			sum=0
			jobs.forEach (x)->
				sum+=parseInt form.elements[x].value
			# カテゴリ別
			for type of Shared.game.categoryNames
				sum+= parseInt(form.elements["category_#{type}"].value ? 0)
			form.elements["Human"].value=pl-sum
			setjobsmonitor form
		form.addEventListener "input",jobsforminput,false
		form.addEventListener "change",jobsforminput,false
				
				
		$("#gamestart").submit (je)->
			# いよいよゲーム開始だ！
			query=Index.util.formQuery je.target
			ss.rpc "game.game.gameStart", roomid,query,(result)->
				if result?
					Index.util.message "ルーム",result
				else
					$("#gamestartsec").attr "hidden","hidden"
			je.preventDefault()
		speakform=$("#speakform").get 0
		$("#speakform").submit (je)->
			form=je.target
			ss.rpc "game.game.speak", roomid,Index.util.formQuery(form),(result)->
				if result?
					Index.util.message "エラー",result
			je.preventDefault()
			form.elements["comment"].value=""
			if form.elements["multilinecheck"].checked
				# 複数行は直す
				form.elements["multilinecheck"].click()
		speakform.elements["willbutton"].addEventListener "click", (e)->
			# 遺言フォームオープン
			wf=$("#willform").get 0
			if wf.hidden
				wf.hidden=false
				e.target.value="遺言を隠す"
			else
				wf.hidden=true
				e.target.value="遺言"
		,false
		speakform.elements["multilinecheck"].addEventListener "click",(e)->
			# 複数行
			t=e.target
			textarea=null
			comment=t.form.elements["comment"]
			if t.checked
				# これから複数行になる
				textarea=document.createElement "textarea"
				textarea.cols=50
				textarea.rows=4
			else
				# 複数行をやめる
				textarea=document.createElement "input"
				textarea.size=50
			textarea.name="comment"
			textarea.value=comment.value
			if textarea.type=="textarea" && textarea.value
				textarea.value+="\n"
			textarea.required=true
			$(comment).replaceWith textarea
			textarea.focus()
			textarea.setSelectionRange textarea.value.length,textarea.value.length
		# 複数行ショートカット
		$(speakform).keydown (je)->
			if je.keyCode==13 && je.shiftKey && je.target.form.elements["multilinecheck"].checked==false
				# 複数行にする
				je.target.form.elements["multilinecheck"].click();
				
				je.preventDefault()
				
		
		# ルール表示
		$("#speakform").get(0).elements["rulebutton"].addEventListener "click", (e)->
			return unless this_rule?
			win=Index.util.blankWindow()
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
				"GMpsychic":
					"_name":"GM霊能"
					"on":"あり"
				"losemode":
					"_name":"敗北村"
					"on":"あり"
				"gjmessage":
					"_name":"狩人の護衛結果"
					"on":"成功時分かる"
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
			ss.rpc "game.game.will", roomid,form.elements["will"].value,(result)->
				if result?
					Index.util.message "エラー",result
				else
					$("#willform").get(0).hidden=true
					$("#speakform").get(0).elements["willbutton"].value="遺言"
		
		# 夜の仕事（あと投票）
		$("#jobform").submit (je)->
			form=je.target
			je.preventDefault()
			$("#jobform").attr "hidden","hidden"
			ss.rpc "game.game.job", roomid,Index.util.formQuery(form), (result)->
				console.log result
				if result?.error?
					Index.util.message "エラー",result.error
					$("#jobform").removeAttr "hidden"
					#else if !result?.jobdone
					# まだ仕事がある
					#$("#jobform").removeAttr "hidden"
				else
					getjobinfo result
		.click (je)->
			bt=je.target
			if bt.type=="submit"
				# 送信ボタン
				bt.form.elements["commandname"].value=bt.name	# コマンド名教えてあげる
				bt.form.elements["jobtype"].value=bt.dataset.job	# 役職名も教えてあげる
		#========================================
			
		# 誰かが参加した!!!!
		socket_ids.push Index.socket.on "join","room#{roomid}",(msg,channel)->
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
			forminfo()
		# 誰かが出て行った!!!
		socket_ids.push Index.socket.on "unjoin","room#{roomid}",(msg,channel)->
			room.players=room.players.filter (x)->x.userid!=msg
			
			$("#players li").filter((idx)-> this.dataset.id==msg).remove()
			forminfo()
		# 準備
		socket_ids.push Index.socket.on "ready","room#{roomid}",(msg,channel)->
			for pl in room.players
				if pl.userid==msg.userid
					pl.start=msg.start
					li=$("#players li").filter((idx)-> this.dataset.id==msg.userid)
					li.replaceWith makeplayerbox pl,room.blind
		socket_ids.push Index.socket.on "mode","room#{roomid}",(msg,channel)->
			for pl in room.players
				if pl.userid==msg.userid
					pl.mode=msg.mode
					li=$("#players li").filter((idx)-> this.dataset.id==msg.userid)
					li.replaceWith makeplayerbox pl,room.blind
					forminfo()
			
		# ログが流れてきた!!!
		socket_ids.push Index.socket.on "log",null,(msg,channel)->
			#if channel=="room#{roomid}" || channel.indexOf("room#{roomid}_")==0 || channel==Index.app.userid()
			if msg.roomid==roomid
				# この部屋へのログ
				getlog msg
		# 職情報を教えてもらった!!!
		socket_ids.push Index.socket.on "getjob",null,(msg,channel)->
			if channel=="room#{roomid}" || channel.indexOf("room#{roomid}_")==0 || channel==Index.app.userid()
				getjobinfo msg
		# 更新したほうがいい
		socket_ids.push Index.socket.on "refresh",null,(msg,channel)->
			if msg.id==roomid
				#Index.app.refresh()
				ss.rpc "game.rooms.enter", roomid,sessionStorage.roompassword ? null,(result)->
					#ss.rpc "game.rooms.oneRoom", roomid,initroom
					ss.rpc "game.game.getlog", roomid,sentlog
				ss.rpc "game.rooms.oneRoom", roomid,(r)->room=r
		# 投票フォームオープン
		socket_ids.push Index.socket.on "voteform",null,(msg,channel)->
			if channel=="room#{roomid}" || channel.indexOf("room#{roomid}_")==0 || channel==Index.app.userid()
				if msg
					$("#jobform").removeAttr "hidden"
				else
					$("#jobform").attr "hidden","hidden"
		# 残り時間
		socket_ids.push Index.socket.on "time",null,(msg,channel)->
			if channel=="room#{roomid}" || channel.indexOf("room#{roomid}_")==0 || channel==Index.app.userid()
				gettimer parseInt(msg.time),msg.mode
	
		$(document).click (je)->
			# クリックで発言強調
			li=if je.target.tagName.toLowerCase()=="li" then je.target else $(je.target).parents("li").get 0
			myrules.player=null
			if $(li).parent("#players").length >0
				if li?
					# 強調
					myrules.player=li.dataset.name
			setcss()
		$("#chooseviewselect").change (je)->
			# 表示部分を選択
			v=je.target.value
			myrules.day=v
			setcss()
		.click (je)->
			je.stopPropagation()

	# 役職入力フォームを作る
	for job in Shared.game.jobs
		# 探す
		continue if job=="Human"	# 村人だけは既に置いてある（あまり）
		for team,members of Shared.game.teams
			if job in members
				dt=document.createElement "dt"
				dt.textContent=Shared.game.jobinfo[team][job].name
				dd=document.createElement "dd"
				input=document.createElement "input"
				input.type="number"
				input.min=0; input.step=1; input.value=0
				input.name=job
				input.dataset.jobname=Shared.game.jobinfo[team][job].name
				dd.appendChild input
				$("#jobsfield").append(dt).append dd
	# カテゴリ別のも用意しておく
	for type,name of Shared.game.categoryNames
		dt=document.createElement "dt"
		dt.textContent=name
		dd=document.createElement "dd"
		input=document.createElement "input"
		input.type="number"
		input.min=0; input.step=1; input.value=0
		input.name="category_#{type}"
		input.dataset.categoryName=name
		dd.appendChild input
		$("#catesfield").append(dt).append dd
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
				
	setjobrule Shared.game.jobrules.concat([
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
	
		
	setplayersnumber=(room,form,number)->
		
		form.elements["number"].value=number
		setplayersbyjobrule room,form,number
	# 配役一覧をアレする
	setplayersbyjobrule=(room,form,number)->
		jobrulename=form.elements["jobrule"].value
		if jobrulename in ["特殊ルール.自由配役","特殊ルール.一部闇鍋"]
			$("#jobsfield").get(0).hidden=false
			$("#catesfield").get(0).hidden= jobrulename!="特殊ルール.一部闇鍋"
			$("#yaminabe_opt").get(0).hidden= jobrulename!="特殊ルール.一部闇鍋"
			$("#yaminabe_opt_nums").get(0).hidden=true
			setjobsmonitor form
			return
		else if jobrulename=="特殊ルール.闇鍋"
			$("#jobsfield").get(0).hidden=true
			$("#catesfield").get(0).hidden=true
			$("#yaminabe_opt").get(0).hidden=false
			$("#yaminabe_opt_nums").get(0).hidden=false
			setjobsmonitor form
			return
		else
			$("#jobsfield").get(0).hidden=true
			$("#catesfield").get(0).hidden=true
			$("#yaminabe_opt").get(0).hidden=true
		if form.elements["scapegoat"].value=="on"
			number++	# 身代わりくん
		obj= Shared.game.getrulefunc jobrulename
		return unless obj?

		form.elements["number"]=number
		for x in Shared.game.jobs
			form.elements[x].value=0
		jobs=obj number
		count=0	#村人以外
		for job,num of jobs
			form.elements[job]?.value=num
			count+=num
		# カテゴリ別
		for type of Shared.game.categoryNames
			count+= parseInt(form.elements["category_#{type}"].value ? 0)
		form.elements["Human"].value=number-count	# 村人
		setjobsmonitor form
	# 配役をテキストで書いてあげる
	setjobsmonitor=(form)->
		text=""
		###
		if form.elements["jobrule"].value=="特殊ルール.一部闇鍋"
			text="闇鍋 / "

		for job in Shared.game.jobs
			continue if job=="Human" && form.elements["jobrule"].value=="特殊ルール.一部闇鍋"	#一部闇鍋は村人部分だけ闇鍋
			input=form.elements[job]
			num=input.value
			continue unless parseInt num
			text+="#{input.dataset.jobname}#{num} "
		###
		if form.elements["jobrule"].value=="特殊ルール.闇鍋"
			# 闇鍋の場合
			$("#jobsmonitor").text "闇鍋 / 人狼#{form.elements["yaminabe_Werewolf"].value} 妖狐#{form.elements["yaminabe_Fox"].value}"
		else
			$("#jobsmonitor").text Shared.game.getrulestr form.elements["jobrule"].value, Index.util.formQuery form
		jobprops=$("#jobprops")
		jobprops.children(".prop").prop "hidden",true
		for job in Shared.game.jobs
			jobpr=jobprops.children(".prop.#{job}")
			if form.elements["jobrule"].value in ["特殊ルール.闇鍋","特殊ルール.一部闇鍋"] || form.elements[job].value>0
				jobpr.prop "hidden",false
		
		
	#ログをもらった
	getlog=(log)->
		if log.mode == "voteresult"
			# 表を出す
			p=document.createElement "div"
			div=document.createElement "div"
			div.classList.add "icon"
			p.appendChild div
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
			p=document.createElement "div"
			div=document.createElement "div"
			div.classList.add "name"
			icondiv=document.createElement "div"
			icondiv.classList.add "icon"
			
			if log.name?
				div.textContent=switch log.mode
					when "monologue"
						"#{log.name}の独り言:"
					when "will"
						"#{log.name}の遺言:"
					else
						"#{log.name}:"
				if this_icons[log.name]
					# アイコンがある
					img=document.createElement "img"
					img.style.width="1em"
					img.style.height="1em"
					img.src=this_icons[log.name]
					img.alt=""	# 飾り
					icondiv.appendChild img
			p.appendChild icondiv
			p.appendChild div
			p.dataset.name=log.name
			
			span=document.createElement "div"
			span.classList.add "comment"
			if log.size in ["big","small"]
				# 大/小発言
				span.classList.add log.size
			
			wrdv=document.createElement "div"
			wrdv.textContent=log.comment
			# 改行の処理
			spp=wrdv.firstChild	# Text
			wr=0
			while (wr=spp.nodeValue.indexOf("\n"))>=0
				spp=spp.splitText wr+1
				wrdv.insertBefore document.createElement("br"),spp
			
			parselognode wrdv
			span.appendChild wrdv
			
			p.appendChild span
			if log.time?
				time=Index.util.timeFromDate new Date log.time
				time.classList.add "time"
				p.appendChild time
			if log.mode=="nextturn" && log.day
				#IDづけ
				p.id="turn_#{log.day}#{if log.night then '_night' else ''}"
				this_logdata.day=log.day
				this_logdata.night=log.night
				
				if log.night==false || log.day==1
					# 朝の場合optgroupに追加
					option=document.createElement "option"
					option.value=log.day
					option.textContent="#{log.day}日目"
					$("#chooseviewday").append option
					setcss()
		# 日にちデータ
		if this_logdata.day
			p.dataset.day=this_logdata.day
			if this_logdata.night
				p.dataset.night="night"
		else
			p.dataset.day=0
		
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
		console.log obj,this_room_id
		return unless obj.id==this_room_id
		my_job=obj.type
		$("#jobinfo").empty()
		pp=(text)->
			p=document.createElement "p"
			p.textContent=text
			p
		if obj.type
			infop=$ "<p>あなたは<b>#{obj.jobname}</b>です（</p>"
			if obj.desc
				# 役職説明
				for o,i in obj.desc
					if i>0
						infop.append "・"
					a=$ "<a href='/manual/job/#{o.type}'>#{if obj.desc.length==1 then '詳細' else "#{o.name}の詳細"}</a>"
					infop.append a
				infop.append "）"
					

			$("#jobinfo").append infop
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
			$("#jobinfo").append pp "あなたは#{obj.stalking.name}のストーカーです"
		if obj.cultmembers?
			$("#jobinfo").append pp "信者は#{obj.cultmembers.map((x)->x.name).join(',')}"
		if obj.vampires?
			$("#jobinfo").append pp "ヴァンパイアは#{obj.vampires.map((x)->x.name).join(',')}"
		if obj.supporting?
			$("#jobinfo").append pp "#{obj.supporting.name}をサポートしています"
		if obj.dogOwner?
			$("#jobinfo").append pp "あなたの飼い主は#{obj.dogOwner.name}です"
		
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
				#$("#form_day").get(0).hidden= game.night || obj.sleeping || obj.type=="GameMaster"
				$("#form_day").get(0).hidden= !obj.voteopen
				obj.open?.forEach (x)->
					# 開けるべきフォームが指定されている
					$("#form_#{x}").prop "hidden",false
			if game.day>0 && game.players
				formplayers game.players
				setJobSelection obj.job_selection ? []
				unless this_rule?
					$("#speakform").get(0).elements["rulebutton"].disabled=false
				this_rule=
					jobscount:game.jobscount
					rule:game.rule
			select=$("#speakform").get(0).elements["mode"]
			if obj.speak && obj.speak.length>0
				# 発言方法の選択
				$(select).empty()
				select.disabled=false
				for val in obj.speak
					option=document.createElement "option"
					option.value=val
					option.text=speakValueToStr game,val
					select.add option
				select.value=obj.speak[0]
			else
				select.disabled=true


	formplayers=(players)->	#jobflg: 1:生存の人 2:死人
		$("#form_players").empty()
		$("#players").empty()
		$("#playernumberinfo").text "生存者#{players.filter((x)->!x.dead).length}人 / 死亡者#{players.filter((x)->x.dead).length}人"
		players.forEach (x)->
			# 上の一覧用
			li=makeplayerbox x
			$("#players").append li
			
			# アイコン
			if x.icon
				this_icons[x.name]=x.icon

	setJobSelection=(selections)->
		$("#form_players").empty()
		valuemap={}	#重複を取り除く
		for x in selections
			continue if valuemap[x.value]	# 重複チェック
			# 投票フォーム用
			li=document.createElement "li"
			#if x.dead
			#	li.classList.add "dead"
			label=document.createElement "label"
			label.textContent=x.name
			input=document.createElement "input"
			input.type="radio"
			input.name="target"
			input.value=x.value
			#input.disabled=!((x.dead && (jobflg&2))||(!x.dead && (jobflg&1)))
			label.appendChild input
			li.appendChild label
			$("#form_players").append li
			valuemap[x.value]=true


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
			
	makebutton=(text,title="")->
		b=document.createElement "button"
		b.type="button"
		b.textContent=text
		b.title=title
		b
		
		
			
exports.end=->
	ss.rpc "game.rooms.exit", this_room_id,(result)->
		if result?
			Index.util.message "ルーム",result
			return
	clearInterval timerid if timerid?
	alloff socket_ids...
	document.body.classList.remove x for x in ["day","night","finished","heaven"]
	if this_style?
		$(this_style).remove()
	
#ソケットを全部off
alloff= (ids...)->
	ids.forEach (x)->
		Index.socket.off x
		
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
	
	df.dataset.id=obj.id ? obj.userid
	df.dataset.name=obj.name
	if obj.icon
		figure=document.createElement "figure"
		figure.classList.add "icon"
		img=document.createElement "img"
		img.src=obj.icon
		img.width=img.height=48
		img.alt=obj.name
		figure.appendChild img
		df.appendChild figure
		df.classList.add "icon"
	p=document.createElement "p"
	p.classList.add "name"
	
	if !blindflg || !obj.realid
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
	if obj.mode=="gm"
		# GM
		p=document.createElement "p"
		p.classList.add "job"
		p.classList.add "gm"
		p.textContent="[GM]"
		df.appendChild p
	else if /^helper_/.test obj.mode
		# ヘルパー
		p=document.createElement "p"
		p.classList.add "job"
		p.classList.add "helper"
		p.textContent="[helper]"
		df.appendChild p

	if obj.start
		# 準備完了
		p=document.createElement "p"
		p.classList.add "job"
		p.textContent="[ready]"
		df.appendChild p
	df

speakValueToStr=(game,value)->
	# 発言のモード名を文字列に
	switch value
		when "day"
			"全員に発言"
		when "monologue"
			"独り言"
		when "werewolf"
			"人狼の会話"
		when "couple"
			"共有者の会話"
		when "fox"
			"妖狐の会話"
		when "gm"
			"全員へ"
		when "gmheaven"
			"霊界へ"
		when "gmaudience"
			"観戦者へ"
		when "gmmonologue"
			"独り言"
		else
			if result=value.match /^gmreply_(.+)$/
				pl=game.players.filter((x)->x.id==result[1])[0]
				"→#{pl.name}"
			else if result=value.match /^helperwhisper_(.+)$/
				"助言"
