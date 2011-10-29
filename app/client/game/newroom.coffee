exports.start=->
	$("#newroomform").submit (je)->
		je.preventDefault()
		form=je.target
		# 作成
		query=SS.client.util.formQuery form
		SS.server.game.rooms.newRoom query,(result)->
			if result?.error?
				SS.client.util.message "エラー",result.error
				return
			SS.client.app.showUrl "/room/#{result.id}"

	.change (je)->
		ch=je.target
		if ch.name=="usepassword"
			$("#newroomform").get(0).elements["password"].disabled = !ch.checked
	
