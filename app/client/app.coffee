# Client-side Code

# Bind to socket events
SS.socket.on 'disconnect', ->  $('#message').text('SocketStream server is down :-(')
SS.socket.on 'reconnect', ->   $('#message').text('SocketStream server is up :-)')

# This method is called automatically when the websocket connection is established. Do not rename/delete
exports.init = ->
  	# 固定リンク
	$("a").live "click", (e)->
		t=e.target
		e.preventDefault()
		SS.client.app.showUrl t.href
		return
		
	if localStorage.userid && localStorage.password
		login localStorage.userid, localStorage.password,(result)->
			if result
				p = location.pathname
				if p=="/" then p="/my"		
			else
				p="/"
				# 無効
				localStorage.removeItem "userid"
				localStorage.removeItem "password"
			showUrl p
	else
		showUrl "/"
  
exports.page=page=(templatename,params=null,pageobj,startparam)->
	cdom=$("#content").get(0)
	jQuery.data(cdom,"end")?()
	jQuery.removeData cdom,"end"
	$("#content").empty()
	$("##{templatename}").tmpl(params).appendTo("#content")
	if pageobj
		pageobj.start(startparam)
		jQuery.data cdom, "end", pageobj.end

exports.showUrl=showUrl=(url,nohistory=false)->
	unless nohistory
		history.pushState null,null,url
	if result=url.match /(https?:\/\/.+?)(\/.+)$/
		if result[1]==location.origin
			url=result[2]
		else
			location.href=url
	switch url
		when "/my"
			# プロフィールとか
			SS.server.user.myProfile (user)->
				page "templates-user-profile",user,SS.client.user.profile,null
		when "/rooms"
			# 部屋一覧
			page "templates-game-rooms",null,SS.client.game.rooms, null
		when "/newroom"
			# 新しい部屋
			page "templates-game-newroom",null,SS.client.game.newroom,null
		else
			SS.server.user.logout ->
				page "templates-top",null,SS.client.top,null

exports.login=login=(uid,ups,cb)->
	SS.server.user.login {userid:uid,password:ups},(result)->
		if !result
			# OK
			cb? true
		else
			cb? false
