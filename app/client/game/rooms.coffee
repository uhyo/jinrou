exports.start=->
	tb=$("#roomlist").get(0)
	SS.server.game.rooms.getRooms (rooms)->
		if rooms.error?
			SS.client.util.message "エラー","ルーム一覧を取得できませんでした。"
			return
			
		rooms.forEach (room)->
			tr=tb.insertRow -1
		
			#No.
			td=tr.insertCell -1
			a=document.createElement "a"
			a.href="/room/#{room.id}"
			a.textContent=room.id
			td.appendChild a
			
			#owner
			td=tr.insertCell -1
			a=document.createElement "a"
			a.href="/user/#{room.owner.userid}"
			a.textContent=room.owner.name
			td.appendChild a
			
			#ルール
			td=tr.insertCell -1
			td.textContent="#{room.rule.number}人"
			
			#コメント
			td=tr.insertCell -1
			td.textContent=room.comment
			
