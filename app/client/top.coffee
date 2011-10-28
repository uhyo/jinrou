exports.start=->
	console.log "!!"
	$("#loginform").submit (je)->
		je.preventDefault()
		form=je.target
		SS.client.app.login form.elements["userid"].value, form.elements["password"].value,(result)->
			if result
				SS.client.app.showUrl "/my"
			else
				$("#loginerror").text "ユーザーIDまたはパスワードが違います。"
	$("#newentryform").submit (je)->
		je.preventDefault()
		form=je.target
		q=
			userid: form.elements["userid"].value
			password: form.elements["password"].value
		SS.server.user.newentry q,(result)->
			if result
				$("#newentryerror").text result
			else
				SS.client.app.showUrl "/my"
