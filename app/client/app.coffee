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
		
	showUrl location.pathname
  
exports.page=page=(templatename,params=null,pageobj,startparam,nohistory=false)->
	cdom=$("#content").get(0)
	jQuery.data(cdom,"end")?()
	jQuery.removeData cdom,"end"
	$("#content").empty()
	$("##{templatename}").tmpl(params).appendTo("#content")
	if pageobj
		pageobj.start(startparam)
		jQuery.data cdom, "end", pageobj.end
	unless nohistory
		history.pushState JSON.stringify({name:"page",templatename:templatename,params:params,pageobj:pageobj,startparam:startparam}),null

exports.showUrl=showUrl=(url)->
	switch url
		when "/my"
			# プロフィールとか
			SS.server.user.myProfile (user)->
				page "templates-user-profile",user,SS.client.user.profile,null
		when "/rooms"
		else
			page "templates-top",null,SS.client.top,null

exports.login=login=(uid,ups,cb)->
	SS.server.user.login {userid:uid,password:ups},(result)->
		if !result
			# OK
			cb? true
		else
			cb? false
