exports.start=->
	form=$("#newroomform")
	# sessionStorageに房间情報があったらそれを適用する
	if sessionStorage.savedRule
		# まだ消さない（部屋作成後も使用）
		f=form.get 0
		rule=JSON.parse sessionStorage.savedRule
		f.elements["blind"].value=rule.blind
		f.elements["ownerGM"].value= if rule.gm then "yes" else ""
		f.elements["number"].value=rule.maxnumber ? 30
		
	$("#newroomform").submit (je)->
		je.preventDefault()
		form=je.target
		# 作成
		query=Index.util.formQuery form
		ss.rpc "game.rooms.newRoom", query,(result)->
			if result?.error?
				Index.util.message "错误",result.error
				return
			Index.app.showUrl "/room/#{result.id}"

	.change (je)->
		ch=je.target
		if ch.name=="usepassword"
			$("#newroomform").get(0).elements["password"].disabled = !ch.checked
	
