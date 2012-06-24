exports.start=->
	$("#newroomform").submit (je)->
		je.preventDefault()
		form=je.target
		# 作成
		query=Index.util.formQuery form
		ss.rpc "game.rooms.newRoom", query,(result)->
			if result?.error?
				Index.util.message "エラー",result.error
				return
			Index.app.showUrl "/room/#{result.id}"

	.change (je)->
		ch=je.target
		if ch.name=="usepassword"
			$("#newroomform").get(0).elements["password"].disabled = !ch.checked
	
