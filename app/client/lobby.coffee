socids=null
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
	appenduser=(user)->
		li=document.createElement "li"
		a=document.createElement "a"
		a.href="/user/#{user.userid}"
		a.textContent=user.name
		li.appendChild a
		li.dataset.userid=user.userid
		$("#users").append li
	deleteuser=(user)->
		$("#users li").each ->
			# this
			if @dataset.userid==user.userid
				$(@).remove()
				false
	heartbeat=->
		SS.server.lobby.heartbeat ->
	

	SS.server.lobby.enter (obj)->
		users=$("#users")
		obj.players.forEach appenduser

		obj.logs.forEach getlog
	$("#lobbyform").submit (je)->
		je.preventDefault()
		SS.server.lobby.say je.target.elements["comment"].value,(result)->
			if result?
				SS.server.util.message "エラー",result
		je.target.reset()
	socids=[
		SS.client.socket.on "log",null,getlog
		SS.client.socket.on "enter",null,appenduser
		SS.client.socket.on "bye",null,deleteuser
		SS.client.socket.on "lobby_heartbeat",null,heartbeat
	]
exports.end=->
	SS.server.lobby.bye ->
	SS.client.socket.off socid for socid in socids
