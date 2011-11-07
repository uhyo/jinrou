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

  number: Number(プレイヤー数)
  players:[Userid,Userid,Userid,...]
}
###
exports.actions=
	getRooms:(cb)->
		M.rooms.find().toArray (err,results)->
			if err?
				cb {error:err}
				return
			results.forEach (x)->delete x.password
			console.log results
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
				players:[@session.user_id]
			room.password=query.password ? null
			room.comment=query.comment ? ""
			unless room.number
				cb {error: "invalid players number"}
				return
	
			SS.server.user.myProfile (user)->
				room.owner=
					userid: user.userid
					name: user.name
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
			if room.error?
				cb "その部屋はありません"
				return
			if @session.user_id in room.players
				cb "すでに参加しています"
				return
			if room.players.length+1 >= room.number
				# 満員
				cb "これ以上入れません"
				return
			#room.players.push @session.user_id
			M.rooms.update {id:roomid},{$push: {players:@session.user_id}},(err)=>
				if err?
					cb "エラー:#{err}"
				else
					cb null
					# 入室通知
					SS.publish.channel "room#{roomid}", "join", @session.user_id
# 部屋から出る
	unjoin: (roomid,cb)->
		unless @session.user_id
			cb "ログインして下さい"
			return
		SS.server.game.rooms.oneRoom roomid,(room)=>
			if room.error?
				cb "その部屋はありません"
				return
			unless @session.user_id in room.players
				cb "まだ参加していません"
				return
			#room.players=room.players.filter (x)=>x!=@session.user_id
			M.rooms.update {id:roomid},{$pull: {players:@session.user_id}},(err)=>
				if err?
					cb "エラー:#{err}"
				else
					cb null
					# 退室通知
					SS.publish.channel "room#{roomid}", "unjoin", @session.user_id
	
	
	# 成功ならnull 失敗ならエラーメッセージ
	# 部屋ルームに入る
	enter: (roomid,cb)->
		unless @session.user_id
			cb "ログインして下さい"
			return
		@session.channel.subscribe "room#{roomid}"
		cb null
	
	# 成功ならnull 失敗ならエラーメッセージ
	# 部屋ルームから出る
	exit: (roomid,cb)->
		unless @session.user_id
			cb "ログインして下さい"
			return
		@session.channel.unsubscribe "room#{roomid}"
		cb null
#cb: (err)->
setRoom=(roomid,room,cb)->
	M.rooms.update {id:roomid},room,cb
