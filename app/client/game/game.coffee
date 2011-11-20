
this_room_id=null

socket_ids=[]

job_names=
	"Human":"村人"
	"Werewolf":"人狼"
	"Diviner":"占い師"
my_job=null
exports.start=(roomid)->
	getenter=(result)->
		if result?
			# エラー
			if result=="password"
				#パスワード入力
				SS.client.util.prompt "ルーム","パスワードを入力して下さい",{type:"password"},(pass)->
					unless pass?
						SS.client.app.showUrl "/rooms"
						return
					SS.server.game.rooms.enter roomid,pass,getenter
					sessionStorage.roompassword = pass
			else
				SS.client.util.message "ルーム",result
			return
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
				formplayers result.players
						
				
			
		# 新しいゲーム
		newgamebutton = (je)->
			form=$("#gamestart").get 0
			form.elements["number"].value=room.players.length
			setplayersnumber form,room.players.length

			$("#gamestartsec").removeAttr "hidden"
		$("#roomname").text room.name
		room.players.forEach (x)->
			li=document.createElement "li"
			li.title=x.userid
			a=document.createElement "a"
			a.href="/user/#{x.userid}"
			a.textContent=x.name
			li.appendChild a
			$("#players").append li
		userid=SS.client.app.userid()
		if room.mode=="waiting"
			if room.owner.userid==SS.client.app.userid()
				# 自分
				b=makebutton "ゲームを開始"
				$("#playersinfo").append b
				$(b).click newgamebutton
			if room.players.filter((x)->x.userid==userid).length==0
				# 未参加
				b=makebutton "ゲームに参加"
				$("#playersinfo").append b
				$(b).click (je)->
					# 参加
					SS.server.game.rooms.join roomid,(result)->
						if result?
							SS.client.util.message "ルーム",result
						else
							SS.client.app.refresh()
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

		form=$("#gamestart").get 0
		jobs=["Diviner","Werewolf"]
		jobsforminput=(e)->
			t=e.target
			if t.name in jobs
				sum=0
				jobs.forEach (x)->
					sum+=parseInt form.elements[x].value
				if room.players.length<sum
					# 多すぎる！
					#jobs.forEach (x)->
					t.setCustomValidity "役職の数が多すぎます。"
				else
					jobs.forEach (x)->
						form.elements[x].setCustomValidity ""
					pl=room.players.length	#人数
					if form.elements["scapegoat"].value=="on"
						# 身代わりくん
						pl++
					form.elements["Human"].value=pl-sum
		form.addEventListener "input",jobsforminput,false
		form.addEventListener "change",jobsforminput,false
				
				
		$("#gamestart").submit (je)->
			# いよいよゲーム開始だ！
			query=SS.client.util.formQuery je.target
			console.log query
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
		
		# 夜の仕事（あと投票）
		$("#jobform").submit (je)->
			form=je.target
			je.preventDefault()
			$("#jobform").attr "hidden","hidden"
			SS.server.game.game.job roomid,SS.client.util.formQuery(form), (result)->
				if result?
					console.log SS.client.util.message, result
					SS.client.util.message "エラー",result
					$("#jobform").removeAttr "hidden"
			
		# 誰かが参加した!!!!
		socket_ids.push SS.client.socket.on "join","room#{roomid}",(msg,channel)->
			room.players.push msg
			
			li=document.createElement "li"
			li.title=msg.userid
			a=document.createElement "a"
			a.href="/user/#{msg.userid}"
			a.textContent=msg.name
			li.appendChild a
			$("#players").append li
		# 誰かが出て行った!!!
		socket_ids.push SS.client.socket.on "unjoin","room#{roomid}",(msg,channel)->
			room.players=room.players.filter (x)->x!=msg
			
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
			SS.client.app.refresh()
		# 投票フォームオープン
		socket_ids.push SS.client.socket.on "voteform",null,(msg,channel)->
			if channel=="room#{roomid}" || channel.indexOf("room#{roomid}_")==0 || channel==SS.client.app.userid()
				if msg
					$("#jobform").removeAttr "hidden"
				else
					$("#jobform").attr "hidden","hidden"
		# プレイヤー情報更新
		socket_ids.push SS.client.socket.on "playersinfo",null,(msg,channel)->
			if channel=="room#{roomid}" || channel.indexOf("room#{roomid}_")==0 || channel==SS.client.app.userid()
				formplayers msg
			
		
	setplayersnumber=(form,number)->
		form.elements["number"]=number
		hu=number	# 村人
		if form.elements["scapegoat"].value=="on"
			hu++
		# 人狼
		form.elements["Werewolf"].value=2
		hu-=2
		# 占い師
		form.elements["Diviner"].value=1
		hu--
		form.elements["Human"].value=hu
		
	#ログをもらった
	getlog=(log)->
		if log.mode == "voteresult"
			# 表を出す
			p=document.createElement "table"
			p.createCaption().textContent="投票結果"
			vr=log.voteresult
			tos={}
			vr.forEach (player)->
				if tos[player.voteto]?
					tos[player.voteto]++
				else
					tos[player.voteto]=1
			vr.forEach (player)->
				tr=p.insertRow(-1)
				tr.insertCell(-1).textContent=player.name
				tr.insertCell(-1).textContent="#{tos[player.id] ? '0'}票"
				tr.insertCell(-1).textContent="→#{vr.filter((x)->x.id==player.voteto)[0]?.name}"
		else
			p=document.createElement "p"
			if log.name?
				span=document.createElement "span"
				span.classList.add "name"
				span.textContent=switch log.mode
					when "monologue"
						"#{log.name}の独り言:"
					else
						"#{log.name}:"
				p.appendChild span
			span=document.createElement "span"
			span.classList.add "comment"
			span.textContent=log.comment
			if log.mode=="nextturn"
				if log.finished
					# 終了
					document.body.classList.add "finished"
					document.body.classList.remove x for x in ["day","night"]
					$("#jobform").attr "hidden","hidden"
				else
					document.body.classList.add (if log.night then "night" else "day")
					document.body.classList.remove (if log.night then "day" else "night")
				unless document.body.classList.contains("heaven") || document.body.classList.contains "finished"
					$("#jobform").removeAttr "hidden"
					$("#jobform div.jobformarea").attr "hidden","hidden"
					if log.night
						$("#form_#{my_job}").removeAttr "hidden"
					else
						$("#form_day").removeAttr "hidden"
		

			
			p.appendChild span
		
		p.classList.add log.mode
		
		logs=$("#logs").get 0
		logs.insertBefore p,logs.firstChild
	# 役職情報をもらった
	getjobinfo=(obj)->
		my_job=obj.type
		if obj.type
			$("#myjob").text job_names[obj.type]
		if obj.wolves?
			$("#jobinfo").text "仲間の人狼は#{obj.wolves.map((x)->x.name).join(",")}"	
		if obj.winner?
			# 勝敗
			$("#jobinfo").text "#{if obj.winner then '勝利' else '敗北'}しました"
		if obj.dead
			# 自分は既に死んでいる
			document.body.classList.add "heaven"
			
		if obj.allplayers
			$("#players").empty()
			obj.allplayers.forEach (x)->
				li=document.createElement "li"
				li.title=x.userid
				a=document.createElement "a"
				a.href="/user/#{x.id}"
				a.textContent=x.name+" "
				li.appendChild a
				if x.type
					b=document.createElement "b"
					b.textContent=job_names[x.type]
					li.appendChild b
				if x.dead
					li.classList.add "dead"
				$("#players").append li
	# 参加者一覧をもらった（夜の仕事用）
	formplayers=(players)->
		$("#form_players").empty()
		players.forEach (x)->
			li=document.createElement "li"
			if x.dead
				li.classList.add "dead"
			label=document.createElement "label"
			label.textContent=x.name
			input=document.createElement "input"
			input.type="radio"
			input.name="target"
			input.value=x.id
			input.disabled=x.dead
			label.appendChild input
			li.appendChild label
			$("#form_players").append li
			
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
	alloff socket_ids...
	document.body.classList.remove "day"
	document.body.classList.remove "night"
	
#ソケットを全部off
alloff= (ids...)->
	ids.forEach (x)->
		SS.client.socket.off x
		
	
		
