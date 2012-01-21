password=null
exports.start=->
	SS.client.util.prompt "管理ページ","管理パスワードを入力して下さい",{},(pass)->
		password=pass
		inittable()
		
	$("#newbanform").submit (je)->
		je.preventDefault()
		query=SS.client.util.formQuery je.target
		query.password=password
		SS.server.user.addBlacklist query,->
			inittable()
	$("#blacklisttable").click (je)->
		target=je.target
		if target.dataset.userid
			query=
				password:password
				userid:target.dataset.userid
			SS.server.user.removeBlacklist query,->
				inittable()
	
exports.end=->

inittable=->
	table=$("#blacklisttable").get 0
	SS.server.user.getBlacklist {password:password},(result)->
		if result.error?
			SS.client.util.message "管理ページ",result.error
			return
		$(table).empty()
		result.docs.forEach (doc)->
			row=table.insertRow -1
			cell=row.insertCell 0
			a=document.createElement "a"
			a.href="/user/#{doc.userid}"
			a.textContent=doc.userid
			cell.appendChild a
			
			cell=row.insertCell 1
			cell.textContent=doc.ip
			
			cell=row.insertCell 2
			cell.textContent=doc.expires?.toLocaleString() ? "無期限"
			
			cell=row.insertCell 3
			input=document.createElement "input"
			input.type="button"
			input.dataset.userid=doc.userid
			input.value="解除"
			cell.appendChild input
	
