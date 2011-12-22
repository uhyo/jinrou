#page module?

name_length_max=20

exports.start=->
	$("section.profile p.edit").click (je)->
		t=je.target
		inp=document.createElement "input"
		inp.value=t.textContent
		inp.name=t.dataset.pname
		inp.type=t.dataset.type
		inp.maxlength=t.dataset.maxlength
		inp.required=true if t.dataset.required
		np=document.createElement "p"
		np.appendChild inp
		t.parentNode?.replaceChild np,t
		inp.focus()
		
	$("#changeprofile").submit (je)->
		je.preventDefault()
		q=SS.client.util.formQuery je.target
		q.userid=$("p.userid").get(0).textContent
		console.log q
		SS.client.util.prompt "プロフィール","パスワードを入力して下さい",{type:"password"},(result)->
			if result
				q.password=result
				console.log q
				SS.server.user.changeProfile q,(result)->
					console.log result
					if result.error?
						SS.client.util.message "エラー",result.error
					else
						SS.client.app.page "templates-user-profile",result,SS.client.user.profile
	$("#morescore").submit (je)->
		je.preventDefault()
		SS.server.user.analyzeScore (obj)->
			if obj.error?
				SS.client.util.message "エラー",obj.error
			console.log obj
		
exports.end=->
