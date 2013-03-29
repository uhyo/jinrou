# Client-side Code

# Bind to socket events
app=require '/app'
util=require '/util'
ss.server.on 'disconnect', ->
	util.message "サーバー","接続が切断されました。"
ss.server.on 'reconnect', ->
	util.message "サーバー","接続が回復しました。ページの更新を行って下さい。"
	
# 全体告知
ss.server.on 'grandalert', (msg)->
	util.message msg.title,msg.message

# This method is called automatically when the websocket connection is established. Do not rename/delete

my_userid=null

exports.init = ->
  	# 固定リンク
	$("a").live "click", (je)->
		t=je.target
		return if je.isDefaultPrevented()
		return if t.target=="_blank"
		je.preventDefault()

		app.showUrl t.href
		return
		
	if localStorage.userid && localStorage.password
		login localStorage.userid, localStorage.password,(result)->
			if result
				p = location.pathname
				if p=="/" then p="/my"
			else
				#p="/"
				# 無効
				localStorage.removeItem "userid"
				localStorage.removeItem "password"
			showUrl decodeURIComponent p
	else
		showUrl decodeURIComponent location.pathname
	window.addEventListener "popstate",((e)->
		# location.pathname
		showUrl location.pathname,true
	),false
  
exports.page=page=(templatename,params=null,pageobj,startparam)->
	cdom=$("#content").get(0)
	jQuery.data(cdom,"end")?()
	jQuery.removeData cdom,"end"
	$("#content").empty()
	$(JT["#{templatename}"](params)).appendTo("#content")
	if pageobj
		pageobj.start(startparam)
		jQuery.data cdom, "end", pageobj.end
# マニュアルを表示
manualpage=(pagename)->
	resp=(tmp)->
		cdom=$("#content").get(0)
		jQuery.data(cdom,"end")?()
		jQuery.removeData cdom,"end"
		$("#content").empty()
		
		$(tmp).appendTo("#content")
		pageobj=Index.manual
		if pageobj
			pageobj.start()
			jQuery.data cdom, "end", pageobj.end

	if sessionStorage["manual_#{pagename}"]
		# すでに取得済み
		resp sessionStorage["manual_#{pagename}"]
		return
	xhr=new XMLHttpRequest()
	xhr.open "GET","/rawmanual/#{pagename}"
	xhr.responseType="text"
	xhr.onload=(e)->
		#if e.status==200
		sessionStorage["manual_#{pagename}"]=xhr.response
		resp xhr.response

	xhr.send()



exports.showUrl=showUrl=(url,nohistory=false)->
	if result=url.match /(https?:\/\/.+?)(\/.+)$/
		if result[1]=="#{location.protocol}//#{location.host}" #location.origin
			url=result[2]
		else
			location.href=url
	
	switch url
		when "/my"
			# プロフィールとか
			ss.rpc "user.myProfile", (user)->
				user[x]?="" for x in ["userid","name","comment"]
				page "user-profile",user,Index.user.profile,user
		when "/rooms"
			# 部屋一覧
			page "game-rooms",null,Index.game.rooms, null
		when "/rooms/log"
			# 終わった部屋
			page "game-rooms",null,Index.game.rooms,"log"
		when "/rooms/my"
			# ぼくの部屋
			page "game-rooms",null,Index.game.rooms,"my"
		when "/newroom"
			# 新しい部屋
			page "game-newroom",null,Index.game.newroom,null
		when "/lobby"
			# ロビー
			page "lobby",null,Index.lobby,null
		when "/manual"
			# マニュアルトップ
			#page "manual-top",null,Index.manual,null
			manualpage "top"
		when "/admin"
			# 管理者ページ
			page "admin",null,Index.admin,null
		when "/logout"
			# ログアウト
			ss.rpc "user.logout", ->
				my_userid=null
				localStorage.removeItem "userid"
				localStorage.removeItem "password"
				$("#username").empty()
				showUrl "/",nohistory
		when "/logs"
			# ログ検索
			page "logs",null,Index.logs,null
		else
			if result=url.match /^\/room\/(\d+)$/
				# ルーム
				page "game-game",null,Index.game.game,parseInt result[1]
			else if result=url.match /^\/user\/(\w+)$/
				# ユーザー
				page "user-view",null,Index.user.view,result[1]
			else if result=url.match /^\/manual\/job\/(\w+)$/
				# ジョブ情報
				win=util.blankWindow()
				$(JT["jobs-#{result[1]}"]()).appendTo win
				return
			else if result=url.match /^\/manual\/casting\/(.*)$/
				# キャスティング情報
				if result[1]=="index" || result[1]==""
					# 一覧
					page "pages-castlist",null,Index.pages.castlist
				else
					page "pages-casting",null,Index.pages.casting,result[1]
			else if result=url.match /^\/manual\/([-\w]+)$/
				#page "manual-#{result[1]}",null,Index.manual,null
				manualpage result[1]
			else if result=url.match /^\/backdoor\/(\w+)$/
				ss.rpc "app.backdoor", result[1],(url)->
					if url?
						location.replace url
			else
				page "top",null,Index.top,null
	unless nohistory
		history.pushState null,null,url
					
					
exports.refresh=->showUrl location.pathname,true

exports.login=login=(uid,ups,cb)->
	ss.rpc "user.login", {userid:uid,password:ups},(result)->
		if !result
			# OK
			my_userid=uid
			$("#username").text uid
			cb? true
		else
			cb? false
exports.userid=->my_userid
exports.setUserid=(id)->my_userid=id



