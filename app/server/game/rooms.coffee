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

  number: Number(プレイヤー数)
  players:[PlayerObject,PlayerObject,...]
}
###
exports.actions=
	getRooms:(mode,cb)->
		if mode=="log"
			query=
				mode:"end"
		else
			query=
				mode:
					$ne:"end"
		M.rooms.find(query).toArray (err,results)->
			if err?
				cb {error:err}
				return
			results.forEach (x)->
				if x.password?
					x.needpassword=true
					delete x.password
			cb results
	oneRoom:(roomid,cb)->
		M.rooms.findOne {id:roomid},(err,result)->
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
		M.rooms.count (err,count)=>
			
			room=
				id:count	#ID連番
				name: query.name
				number:parseInt query.number
				mode:"waiting"
				players:[@session.attributes.user]
				made:Date.now()
			room.password=query.password ? null
			room.comment=query.comment ? ""
			unless room.number
				cb {error: "invalid players number"}
				return
			room.owner=@session.attributes.user
			M.rooms.insert room
			SS.server.game.game.newGame room
			cb {id: room.id}

# 部屋に入る
# 成功ならnull 失敗ならエラーメッセージ
	join: (roomid,cb)->
		unless @session.user_id
			cb "ログインして下さい"
			return
		SS.server.game.rooms.oneRoom roomid,(room)=>
		
			if !room || room.error?
				cb "その部屋はありません"
				return
			if @session.user_id in (room.players.map (x)->x.userid)
				cb "すでに参加しています"
				return
			if room.players.length >= room.number
				# 満員
				cb "これ以上入れません"
				return
			unless room.mode=="waiting"
				cb "既に参加は締めきられています"
				return
			#room.players.push @session.attributes.user
			M.rooms.update {id:roomid},{$push: {players:@session.attributes.user}},(err)=>
				if err?
					cb "エラー:#{err}"
				else
					cb null
					# 入室通知
					SS.server.game.game.inlog room,@session.attributes.user
					SS.publish.channel "room#{roomid}", "join", @session.attributes.user
# 部屋から出る
	unjoin: (roomid,cb)->
		unless @session.user_id
			cb "ログインして下さい"
			return
		SS.server.game.rooms.oneRoom roomid,(room)=>
			if !room || room.error?
				cb "その部屋はありません"
				return
			unless @session.user_id in (room.players.map (x)->x.userid)
				cb "まだ参加していません"
				return
			unless room.mode=="waiting"
				cb "もう始まっています"
				return
			#room.players=room.players.filter (x)=>x!=@session.user_id
			M.rooms.update {id:roomid},{$pull: {players:{userid:@session.user_id}}},(err)=>
				if err?
					cb "エラー:#{err}"
				else
					cb null
					# 退室通知
					SS.server.game.game.outlog room,@session.attributes.user
					SS.publish.channel "room#{roomid}", "unjoin", @session.user_id
	# 部屋から追い出す
	kick:(roomid,id,cb)->
		unless @session.user_id
			cb "ログインして下さい"
			return
		SS.server.game.rooms.oneRoom roomid,(room)=>
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
					SS.server.user.userData id,null,(user)->
						SS.server.game.game.kicklog room,user
						SS.publish.channel "room#{roomid}", "unjoin",id
					SS.publish.user id,"refresh",{id:roomid}
	
	
	# 成功ならnull 失敗ならエラーメッセージ
	# 部屋ルームに入る
	enter: (roomid,password,cb)->
		unless @session.user_id
			cb "ログインして下さい"
			return
		SS.server.game.rooms.oneRoom roomid,(room)=>
			if !room?
				cb "その部屋はありません"
				return
			if room.error?
				cb room.error
				return
			if room.password? && room.password!=password
				cb "password"
				return

			@session.channel.subscribe "room#{roomid}"
			SS.server.game.game.playerchannel roomid,@session
			cb null
	
	# 成功ならnull 失敗ならエラーメッセージ
	# 部屋ルームから出る
	exit: (roomid,cb)->
		unless @session.user_id
			cb "ログインして下さい"
			return
#		@session.channel.unsubscribe "room#{roomid}"
		@session.channel.unsubscribeAll()
		cb null
	# 部屋を削除
	del: (roomid,cb)->
		unless @session.user_id
			cb "ログインして下さい"
			return
		SS.server.game.rooms.oneRoom roomid,(room)=>
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
