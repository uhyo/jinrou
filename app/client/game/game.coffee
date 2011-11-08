this_room_id=null

join_id=null
unjoin_id=null
exports.start=(roomid)->
	SS.server.game.rooms.enter roomid,(result)->
		if result?
			# エラー
			SS.client.util.message "ルーム",result
			return
		this_room_id=roomid
		SS.server.game.rooms.oneRoom roomid,initroom
	initroom=(room)->
		unless room?
			SS.client.util.message "ルーム","そのルームは存在しません。"
			SS.client.app.showUrl "/rooms"
			return
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
		form.addEventListener "input",(e)->
			t=e.target
			console.log t
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
					form.elements["Human"].value=room.players.length-sum
				
				
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
			SS.server.game.game
		# 誰かが参加した!!!!
		join_id=SS.client.socket.on "join","room#{roomid}",(msg,channel)->
			room.players.push msg
			
			li=document.createElement "li"
			li.title=msg.userid
			a=document.createElement "a"
			a.href="/user/#{msg.userid}"
			a.textContent=msg.name
			li.appendChild a
			$("#players").append li
		# 誰かが出て行った!!!
		unjoin_id=SS.client.socket.on "unjoin","room#{roomid}",(msg,channel)->
			room.players=room.players.filter (x)->x!=msg
			
			$("#players li").filter((idx)-> this.title==msg).remove()
		
	setplayersnumber=(form,number)->
		form.elements["number"]=number
		hu=number	# 村人
		# 人狼
		form.elements["Werewolf"].value=2
		hu-=2
		# 占い師
		form.elements["Diviner"].value=1
		hu--
		form.elements["Human"].value=hu
		
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
	SS.client.socket.off join_id
	SS.client.socket.off unjoin_id
		
