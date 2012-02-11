socids=null
exports.start=->
	# ロビーに入る
	getlog=(log)->
		p=document.createElement "p"
		div=document.createElement "div"
		div.classList.add "name"
		if log.name?
			div.textContent="#{log.name}:"
		p.appendChild div
		
		span=document.createElement "div"
		span.classList.add "comment"
		wrdv=document.createElement "div"
		wrdv.textContent=log.comment
		SS.client.game.game.parselognode wrdv
		span.appendChild wrdv
		
		p.appendChild span
		if log.time?
			time=SS.client.util.timeFromDate new Date log.time
			time.classList.add "time"
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

		obj.logs.reverse().forEach getlog
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
