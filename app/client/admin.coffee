tabs=
	blacklist:
		init:->
			inittable()
			$("#newbanform").submit (je)->
				je.preventDefault()
				query=SS.client.util.formQuery je.target
				SS.server.admin.addBlacklist query,->
					inittable()
			$("#blacklisttable").click (je)->
				target=je.target
				if target.dataset.userid
					query=
						userid:target.dataset.userid
					SS.server.admin.removeBlacklist query,->
						inittable()
	grandalert:
		init:->
			$("#alertform").submit (je)->
				je.preventDefault()
				query=SS.client.util.formQuery je.target
				SS.server.admin.spreadGrandalert query,(result)->
					unless result?
						# 成功
						je.target.reset()

exports.start=->
	SS.client.util.prompt "管理ページ","管理パスワードを入力して下さい",{},(pass)->
		SS.server.admin.regist {password:pass},(err)->
			if err?
				SS.client.util.message "管理ページ",err
	$("#admin").click (je)->
		t=je.target
		if t.dataset.opener && to=tabs[t.dataset.opener]
			unless to.inited	# 初回
				to.init()
				to.inied=true
			e=$("##{t.dataset.opener}").get 0
			e.hidden=!e.hidden
		

	
exports.end=->

inittable=->
	table=$("#blacklisttable").get 0
	SS.server.admin.getBlacklist {},(result)->
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
	
