exports.start=->
	$("#newroomform").submit (je)->
		form=je.target
		# 作成
		query=SS.client.util.formQuery form
		SS.server.rooms.newRoom query,(result)->
			if result?.error?
				SS.client.util.message "エラー",result.error

	.change (je)->
		ch=je.target
		if ch.name=="usepassword"
			$("#newroomform").get(0).elements["password"].disabled = !ch.checked
	
