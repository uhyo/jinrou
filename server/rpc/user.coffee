# Server-side Code
crypto=require('crypto')
exports.actions =

# ログイン
# cb: 失敗なら真
	login: (query,cb)->
		auth=require('./auth.coffee')
		#@session.authenticate './session_storage/internal.coffee', query, (response)=>
		auth.authenticate query,(response)=>
			if response.success
				@session.setUserId response.userid
				handshake= SS.io.sockets.sockets[@request.socket_id]?.handshake
				ip=null
				if handshake?
					if handshake.headers["forwarded-for"]
						ip=handshake.headers["forwarded-for"].split(/\s*,\s*/)[0]
					else if handshake.headers["x-forwarded-for"]
						ip=handshake.headers["x-forwarded-for"].split(/\s*,\s*/)[0]
					else
						ip=handshake.address.address
					response.ip=ip
				else
					response.ip=null
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
		unless /^\w+$/.test(query.userid)
			cb "ユーザーIDが不正です"
			return
		unless /^\w+$/.test(query.password)
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
			delete record.prize
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
			u.prizenames=u.prize.map (x)->{id:x,name:SS.server.prize.prizeName(x) ? null}
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
			if query.comment? && query.comment.length<=200
				record.comment=query.comment
			if query.icon? && query.icon.length<=300
				record.icon=query.icon
			M.users.update {"userid":@session.user_id}, record, {safe:true},(err,count)=>
				if err?
					cb {error:"プロフィール変更に失敗しました"}
					return
				delete record.password
				@session.attributes.user=record
				@session.save ->
				cb record
	changePassword:(query,cb)->
		M.users.findOne {"userid":@session.user_id,"password":SS.server.user.crpassword(query.password)},(err,record)=>
			if err?
				cb {error:"DB err:#{err}"}
				return
			if !record?
				cb {error:"ユーザー認証に失敗しました"}
				return
			if query.newpass!=query.newpass2
				cb {error:"パスワードが一致しません"}
				return
			M.users.update {"userid":@session.user_id}, {$set:{password:SS.server.user.crpassword(query.newpass)}},{safe:true},(err,count)=>
				if err?
					cb {error:"プロフィール変更に失敗しました"}
					return
				cb null
	usePrize: (query,cb)->
		# 表示する称号を変える query.prize
		M.users.findOne {"userid":@session.user_id,"password":SS.server.user.crpassword(query.password)},(err,record)=>
			if err?
				cb {error:"DB err:#{err}"}
				return
			if !record?
				cb {error:"ユーザー認証に失敗しました"}
				return
			if typeof query.prize?.every=="function"
				# 称号構成を得る
				comp=SS.shared.prize.getPrizesComposition record.prize.length
				if query.prize.every((x,i)->x.type==comp[i])
					# 合致する
					if query.prize.every((x)->
						if x.type=="prize"
							!x.value || x.value in record.prize	# 持っている称号のみ
						else
							!x.value || x.value in SS.shared.prize.conjunctions
					)
						# 所持もOK
						M.users.update {"userid":@session.user_id}, {$set:{nowprize:query.prize}},{safe:true},(err)=>
								@session.attributes.user.nowprize=query.prize
							@session.save ->
							
							cb null
					else
						cb {error:"肩書きが不正です"}
				else
					cb {error:"肩書きが不正です"}
			else
				cb {error:"肩書きが不正です"}
		
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
		icon:""	# iconのURL
		comment: ""
		win:[]	# 勝ち試合
		lose:[]	# 負け試合
		gone:[]	# 行方不明試合
		ip:""	# IPアドレス
		prize:[]# 現在持っている称号
		ownprize:[]	# 何かで与えられた称号（prizeに含まれる）
		nowprize:null	# 現在設定している肩書き
				# [{type:"prize",value:(prizeid)},{type:"conjunction",value:"が"},...]
	}
