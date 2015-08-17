socids=null
exports.start=->
	# ロビーに入る
	getlog=(log)->
		p=document.createElement "div"
		div=document.createElement "div"
		div.classList.add "icon"
		p.appendChild div

		div=document.createElement "div"
		div.classList.add "name"
		if log.name?
			div.textContent="#{log.name}:"
		p.appendChild div
		
		span=document.createElement "div"
		span.classList.add "comment"
		wrdv=document.createElement "div"
		wrdv.textContent=log.comment
		Index.game.game.parselognode wrdv
		span.appendChild wrdv
		
		p.appendChild span
		if log.time?
			time=Index.util.timeFromDate new Date log.time
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
		ss.rpc "lobby.heartbeat", ->
	

	ss.rpc "lobby.enter", (obj)->
		users=$("#users")
		obj.players.forEach appenduser

		obj.logs.reverse().forEach getlog
	$("#lobbyform").submit (je)->
		je.preventDefault()
		ss.rpc "lobby.say", je.target.elements["comment"].value,(result)->
			if result?
				ss.rpc "util.message", "错误",result
		je.target.reset()
	socids=[
		Index.socket.on "log",null,getlog
		Index.socket.on "enter",null,appenduser
		Index.socket.on "bye",null,deleteuser
		Index.socket.on "lobby_heartbeat",null,heartbeat
	]
exports.end=->
	ss.rpc "lobby.bye", ->
	Index.socket.off socid for socid in socids
