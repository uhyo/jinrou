this_room_id=null
exports.start=(roomid)->
	SS.server.game.rooms.enter roomid,(result)->
		if result?
			# エラー
			SS.client.util.message "ルーム",result
			return
		this_room_id=roomid
		SS.server.game.rooms.oneRoom roomid,(room)->
			unless room?
				SS.client.util.message "ルーム","そのルームは存在しません。"
				SS.client.app.showUrl "/rooms"
				return
			$("#roomname").text room.name
			room.players.forEach (x)->
				li=document.createElement "li"
				a=document.createElement "a"
				a.href="/user/#{x}"
				a.textContent=x
				li.appendChild a
				$("#players").append li
			userid=SS.client.app.userid()
			if room.mode=="waiting"
				if room.players[0]==SS.client.app.userid()
					# 自分
					b=makebutton "ゲームを開始"
					$("#playersinfo").append b
				if room.players.filter((x)->x==userid).length==0
					# 未参加
					b=makebutton "ゲームに参加"
					$("#playersinfo").append b
					$(b).click (je)->
						# 参加
						SS.server.game.rooms.join roomid,(result)->
						
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
		
