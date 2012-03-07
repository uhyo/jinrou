###
room: {
  id: Number
  name: String
  owner:{
    userid: Userid
    name: String
  }
  password: Hashed Password
  comment: String
  mode: "waiting"/"playing"/"end"
  made: Time(Number)(作成された日時）
  blind:""/"hide"/"complete"
  number: Number(プレイヤー数)
  players:[PlayerObject,PlayerObject,...]
  gm: Booelan(trueならオーナーGM)
}
PlayerObject.start=Boolean
###
page_number=10

exports.actions=
	getRooms:(mode,page,cb)->
		if mode=="log"
			query=
				mode:"end"
		else
			query=
				mode:
					$ne:"end"
		M.rooms.find(query).sort({made:-1}).skip(page*page_number).limit(page_number).toArray (err,results)->
			if err?
				cb {error:err}
				return
			results.forEach (x)->
				if x.password?
					x.needpassword=true
					delete x.password
				if x.blind
					delete x.owner
					x.players.forEach (p)->
						delete p.realid
			cb results
	oneRoom:(roomid,cb)->
		M.rooms.findOne {id:roomid},(err,result)=>
			if err?
				cb {error:err}
				return
			# クライアントからの問い合わせの場合
			result.players.forEach (p)->
				delete p.realid
				delete p.ip
			cb result
	oneRoomS:(roomid,cb)->
		M.rooms.findOne {id:roomid},(err,result)=>
			if err?
				cb {error:err}
				return
			cb result

# 成功: {id: roomid}
# 失敗: {error: ""}
	newRoom: (query,cb)->
		unless @session.user_id
			cb {error: "ログインしていません"}
			return
		M.rooms.find().sort({id:-1}).limit(1).nextObject (err,doc)=>
			id=if doc? then doc.id+1 else 1
			room=
				id:id	#ID連番
				name: query.name
				number:parseInt query.number
				mode:"waiting"
				players:[]
				made:Date.now()
			room.password=query.password ? null
			room.blind=query.blind
			room.comment=query.comment ? ""
			#unless room.blind
			#	room.players.push @session.attributes.user
			unless room.number
				cb {error: "invalid players number"}
				return
			room.owner=
				userid:@session.attributes.user.userid
				name:@session.attributes.user.name
			room.gm = query.ownerGM=="yes"
			M.rooms.insert room
			SS.server.game.game.newGame room
			cb {id: room.id}
			SS.server.oauth.template room.id,"「#{room.name}」（#{room.id}番#{if room.blind then '・覆面' else ''}#{if room.gm then '・GMあり' else ''}）が建てられました。 #月下人狼",SS.config.admin.password

# 部屋に入る
# 成功ならnull 失敗ならエラーメッセージ
	join: (roomid,opt,cb)->
		unless @session.user_id
			cb {error:"ログインして下さい",require:"login"}	# ログインが必要
			return
		M.blacklist.findOne {$or:[{userid:@session.user_id},{ip:@session.attributes.user.ip}]},(err,doc)=>
			if doc?
				if !doc.expires || doc.expires.getTime()>=Date.now()
					cb error:"参加は禁止されています"
					return
			
			SS.server.game.rooms.oneRoomS roomid,(room)=>
		
				if !room || room.error?
					cb error:"その部屋はありません"
					return
				if @session.user_id in (room.players.map (x)->x.realid)
					cb error:"すでに参加しています"
					return
				if room.players.length >= room.number
					# 満員
					cb error:"これ以上入れません"
					return
				unless room.mode=="waiting"
					cb error:"既に参加は締めきられています"
					return
				if room.gm && room.owner.userid==@session.user_id
					cb error:"ゲームマスターは参加できません"
					return
				#room.players.push @session.attributes.user
				su=@session.attributes.user
				user=
					userid:@session.user_id
					realid:@session.user_id
					name:su.name
					ip:su.ip
					icon:su.icon
					start:false
					nowprize:su.nowprize
				
				user.realid = @session.user_id
				# 同IP制限
				if room.players.some((x)->x.ip==su.ip) && su.ip!="127.0.0.1"
					cb error:"重複参加はできません"
					return
				
				if room.blind
					unless opt?.name
						cb error:"名前を入力して下さい"
						return
					# 覆面
					makeid=->	# ID生成
						re=""
						while !re
							i=0
							while i<20
								re+="0123456789abcdef"[Math.floor Math.random()*16]
								i++
							if room.players.some((x)->x.userid==re)
								re=""
						re
					user.name=opt.name
					user.userid=makeid()
					user.icon=null
						
				M.rooms.update {id:roomid},{$push: {players:user}},(err)=>
					if err?
						cb error:"エラー:#{err}"
					else
						cb null
						# 入室通知
						delete user.ip
						SS.server.game.game.inlog room,user
						SS.publish.channel "room#{roomid}", "join", user
# 部屋から出る
	unjoin: (roomid,cb)->
		unless @session.user_id
			cb "ログインして下さい"
			return
		SS.server.game.rooms.oneRoomS roomid,(room)=>
			if !room || room.error?
				cb "その部屋はありません"
				return
			unless @session.user_id in (room.players.map (x)->x.realid)
				cb "まだ参加していません"
				return
			unless room.mode=="waiting"
				cb "もう始まっています"
				return
			#room.players=room.players.filter (x)=>x!=@session.user_id
			M.rooms.update {id:roomid},{$pull: {players:{realid:@session.user_id}}},(err)=>
				if err?
					cb "エラー:#{err}"
				else
					cb null
					# 退室通知
					user=room.players.filter((x)=>x.realid==@session.user_id)[0]
					SS.server.game.game.outlog room,user ? @session.attributes.user
					SS.publish.channel "room#{roomid}", "unjoin", user?.userid
	ready:(roomid,cb)->
		# 準備ができたか？
		unless @session.user_id
			cb "ログインして下さい"
			return
		SS.server.game.rooms.oneRoomS roomid,(room)=>
			if !room || room.error?
				cb "その部屋はありません"
				return
			unless @session.user_id in (room.players.map (x)->x.realid)
				cb "まだ参加していません"
				return
			unless room.mode=="waiting"
				cb "もう始まっています"
				return
			room.players.forEach (x,i)=>
				if x.realid==@session.user_id
					query={$set:{}}
					query.$set["players.#{i}.start"]=!x.start
					M.rooms.update {id:roomid},query, (err)=>
						if err?
							cb "エラー:#{err}"
						else
							cb null
							# ready? 知らせる
							SS.publish.channel "room#{roomid}", "ready", {userid:x.userid,start:!x.start}

	# 部屋から追い出す
	kick:(roomid,id,cb)->
		unless @session.user_id
			cb "ログインして下さい"
			return
		SS.server.game.rooms.oneRoomS roomid,(room)=>
			if !room || room.error?
				cb "その部屋はありません"
				return
			if room.owner.userid != @session.user_id
				cb "オーナーしかkickできません"
				return
			unless room.mode=="waiting"
				cb "もう始まっています"
				return
			unless room.players.some((x)->x.userid==id)
				cb "そのユーザーは参加していません"
				return
			M.rooms.update {id:roomid},{$pull: {players:{userid:id}}},(err)=>
				if err?
					cb "エラー:#{err}"
				else
					cb null
					# 退室通知
					user=room.players.filter((x)=>x.userid==id)[0]
					if user?
						SS.server.game.game.kicklog room,user
						SS.publish.channel "room#{roomid}", "unjoin",id
						SS.publish.user id,"refresh",{id:roomid}
	
	
	# 成功ならjoined 失敗ならエラーメッセージ
	# 部屋ルームに入る
	enter: (roomid,password,cb)->
		#unless @session.user_id
		#	cb {error:"ログインして下さい"}
		#	return
		SS.server.game.rooms.oneRoomS roomid,(room)=>
			if !room?
				cb {error:"その部屋はありません"}
				return
			if room.error?
				cb {error:room.error}
				return
			if room.password? && room.password!=password && room.password!=SS.config.admin.password
				cb {require:"password"}
				return
			@session.channel.unsubscribeAll()

			@session.channel.subscribe "room#{roomid}"
			SS.server.game.game.playerchannel roomid,@session
			cb {joined:room.players.some((x)=>x.realid==@session.user_id)}
	
	# 成功ならnull 失敗ならエラーメッセージ
	# 部屋ルームから出る
	exit: (roomid,cb)->
		#unless @session.user_id
		#	cb "ログインして下さい"
		#	return
#		@session.channel.unsubscribe "room#{roomid}"
		@session.channel.unsubscribeAll()
		cb null
	# 部屋を削除
	del: (roomid,cb)->
		unless @session.user_id
			cb "ログインして下さい"
			return
		SS.server.game.rooms.oneRoomS roomid,(room)=>
			if !room || room.error?
				cb "その部屋はありません"
				return
			if room.owner.userid != @session.user_id
				cb "オーナーしか削除できません"
				return
			unless room.mode=="waiting"
				cb "もう始まっています"
				return
			M.rooms.update {id:roomid},{$set: {mode:"end"}},(err)=>
				if err?
					cb "エラー:#{err}"
				else
					cb null
					SS.server.game.game.deletedlog room	
#cb: (err)->
setRoom=(roomid,room,cb)->
	M.rooms.update {id:roomid},room,cb
