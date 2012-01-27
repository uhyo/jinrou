# Server-side Code
crypto=require('crypto');
exports.actions =

# ログイン
# cb: 失敗なら真
	login: (query,cb)->
		auth=require('./auth.coffee');
		#@session.authenticate './session_storage/internal.coffee', query, (response)=>
		auth.authenticate query,(response)=>
			if response.success
				@session.setUserId response.userid
				response.ip=SS.io.sockets.sockets[@request.socket_id]?.handshake.address.address
				@session.attributes.user=response
				#@session.attributes.room=null	# 今入っている部屋
				@session.channel.unsubscribeAll()
				cb false
				# IPアドレスを記録してあげる
				M.users.update {"userid":response.userid},{$set:{ip:response.ip}}
			else
				cb true
				
# ログアウト
	logout: (cb)->
		@session.user.logout(cb)
		@session.channel.unsubscribeAll()
			
# 新規登録
# cb: エラーメッセージ（成功なら偽）
	newentry: (query,cb)->
		unless /^\w*$/.test(query.userid)
			cb "ユーザーIDが不正です"
			return
		unless /^\w*$/.test(query.password)
			cb "パスワードが不正です"
			return
		M.users.find({"userid":query.userid}).count (err,count)->
			if count>0
				cb "そのユーザーIDは既に使用されています"
				return
			userobj = makeuserdata(query)
			M.users.insert userobj,{safe:true},(err,records)->
				if err?
					cb "DB err:#{err}"
					return
				SS.server.user.login query,cb
				
# ユーザーデータが欲しい
	userData: (userid,password,cb)->
		M.users.findOne {"userid":userid},(err,record)->
			if err?
				cb null
				return
			if !record?
				cb null
				return
			delete record.password
			delete rocord.prize
			#unless password && record.password==SS.server.user.crpassword(password)
			#	delete record.email
			cb record
	myProfile: (cb)->
		unless @session.user_id
			cb null
			return
		u=JSON.parse JSON.stringify @session.attributes.user
		if u
			u.wp = unless u.win? && u.lose?
				"???"
			else if u.win.length+u.lose.length==0
				"???"
			else
				"#{(u.win.length/(u.win.length+u.lose.length)*100).toPrecision(2)}%"
			# 称号の処理をしてあげる
			u.prize ?= []
			u.prizenames=u.prize.map (x)->{id:x,name:SS.server.prize.prizeName x}
			delete u.prize
			cb u
		else
			cb null
		
				
# プロフィール変更 返り値=変更後 {"error":"message"}
	changeProfile: (query,cb)->
		M.users.findOne {"userid":@session.user_id,"password":SS.server.user.crpassword(query.password)},(err,record)=>
			if err?
				cb {error:"DB err:#{err}"}
				return
			if !record?
				cb {error:"ユーザー認証に失敗しました"}
				return
			if query.name?
				if query.name==""
					cb {error:"ニックネームを入力して下さい"}
					return
					
				record.name=query.name
			if query.email?
				record.email=query.email
			if query.comment?
				record.comment=query.comment
			M.users.update {"userid":@session.user_id}, record, {safe:true},(err,count)=>
				if err?
					cb {error:"プロフィール変更に失敗しました"}
					return
				delete record.password
				@session.attributes.user=record
				@session.save ->
				cb record
	usePrize: (query,cb)->
		# 表示する称号を変える query.prize
		M.users.findOne {"userid":@session.user_id,"password":SS.server.user.crpassword(query.password)},(err,record)=>
			if err?
				cb {error:"DB err:#{err}"}
				return
			if !record?
				cb {error:"ユーザー認証に失敗しました"}
				return
			if query.prize=="_none"
				# なくす
				M.users.update {"userid":@session.user_id}, {$set:{nowprize:null}},{safe:true},(err)=>
					@session.attributes.user.nowprize=null
					console.log @session.attributes.user.nowprize
					cb null
			else
				unless SS.server.prize.prizeName query.prize
					cb {error:"その称号はありません"}
					return
				M.users.update {"userid":@session.user_id}, {$set:{nowprize:query.prize}},{safe:true},(err)=>
					@session.attributes.user.nowprize=query.prize
					console.log @session.attributes.user.nowprize
					cb null
		
	# 成績をくわしく見る
	analyzeScore:(cb)->
		unless @session.user_id
			cb {error:"ログインして下さい"}
			return
		myid=@session.user_id
		# DBから自分のやつを引っ張ってくる
		results=[]
		cursor=M.games.find {finished:true,players:{$elemMatch:{realid:myid}}}
		cursor.each (err,game)->
			unless game?
				# 終了
				cb {results:results}
				return
			player=game.players.filter((x)->x.realid==myid)[0] # me
			return unless player?
			plinfo=(pl)->
				unless pl.type=="Complex"
					{type:pl.type, winner:pl.winner}
				else
					plinfo pl.Complex_main
			pobj=plinfo player
			pobj.id=game.id
			results.push pobj
			
	
	######
	# blacklist一覧を得る
	getBlacklist:(query,cb)->
		unless query?.password==SS.config.admin.password
			cb {error:"パスワードが違います"}
			return
		M.blacklist.find().limit(100).skip(100*(query.page ? 0)).toArray (err,docs)->
			cb {docs:docs}
	addBlacklist:(query,cb)->
		unless query?.password==SS.config.admin.password
			cb {error:"パスワードが違います"}
			return
		M.users.findOne {userid:query.userid},(err,doc)->
			unless doc?
				cb {error:"そのユーザーは見つかりません"}
				return
			addquery=
				userid:doc.userid
				ip:doc.ip
			if query.expire=="some"
				d=new Date()
				d.setMonth d.getMonth()+parseInt query.month
				d.setDate d.getDate()+parseInt query.day
				addquery.expires=d
			M.blacklist.insert addquery,{safe:true},(err,doc)->
				cb null
	removeBlacklist:(query,cb)->
		unless query?.password==SS.config.admin.password
			cb {error:"パスワードが違います"}
			return
		M.blacklist.remove {userid:query.userid},(err)->
			cb null
			


#パスワードハッシュ化
#	crpassword: (raw)-> raw && hashlib.sha256(raw+hashlib.md5(raw))
	crpassword: (raw)->
		return "" unless raw
		sha256=crypto.createHash "sha256"
		md5=crypto.createHash "md5"
		md5.update raw	# md5でハッシュ化
		sha256.update raw+md5.digest 'hex'	# sha256でさらにハッシュ化
		sha256.digest 'hex'	# 結果を返す
#ユーザーデータ作る
makeuserdata=(query)->
	{
		userid: query.userid
		password: SS.server.user.crpassword(query.password)
		name: query.userid
		comment: ""
		win:[]	# 勝ち試合
		lose:[]	# 負け試合
		gone:[]	# 行方不明試合
		ip:""	# IPアドレス
		prize:[]# 現在持っている称号
		ownprize:[]	# 何かで与えられた称号（prizeに含まれる）
		nowprize:null	# 現在設定している称号
	}
