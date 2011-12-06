exports.start=(mode)->
	tb=$("#roomlist").get(0)
	SS.server.game.rooms.getRooms mode,(rooms)->
		if rooms.error?
			SS.client.util.message "エラー","ルーム一覧を取得できませんでした。"
			return
			
		rooms.forEach (room)->
			tr=tb.insertRow -1
			if room.needpassword
				tr.classList.add "lock"
		
			#No.
			td=tr.insertCell -1
			a=document.createElement "a"
			a.href="/room/#{room.id}"
			a.textContent="#{room.name}(#{room.players.length})"
			td.appendChild a
			
			#状態
			td=tr.insertCell -1
			td.textContent= switch room.mode
				when "waiting"
					"募集中"
				when "playing"
					"対戦中"
				when "end"
					"終了"
				else
					"不明"
			
			#owner
			td=tr.insertCell -1
			a=document.createElement "a"
			a.href="/user/#{room.owner.userid}"
			a.textContent=room.owner.name
			td.appendChild a
			
			#ルール
			td=tr.insertCell -1
			td.textContent="#{room.number}人"
			
			#コメント
			td=tr.insertCell -1
			td.textContent=room.comment
			
