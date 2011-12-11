socid=null
exports.start=->
	# ロビーに入る
	getlog=(log)->
		p=document.createElement "p"
		if log.name?
			span=document.createElement "span"
			span.classList.add "name"
			span.textContent="#{log.name}:"
			p.appendChild span
		span=document.createElement "span"
		span.classList.add "comment"
		span.textContent=log.comment
		p.appendChild span
		if log.time?
			time=SS.client.util.timeFromDate new Date log.time
			p.appendChild time
		$("#logs").prepend p

	SS.server.lobby.enter (obj)->
		console.log obj
		obj.logs.forEach getlog
	$("#lobbyform").submit (je)->
		je.preventDefault()
		SS.server.lobby.say je.target.elements["comment"].value,(result)->
			if result?
				SS.server.util.message "エラー",result
		je.target.reset()
	socid=SS.client.socket.on "log",null,getlog
exports.end=->
	SS.server.lobby.bye ->
	SS.client.socket.off socid
