###
room: {
  id: Number
  owner:{
    userid: Userid
    name: String
  }
  password: Hashed Password
  comment: String
  open: Boolean # 開催中ならtrue,終了ならfalse

  rule:{
    number: Number # プレイヤー数
  }
}
###
exports.actions=
	getRooms:(cb)->
		M.rooms.find({open:true}).toArray (err,results)->
			if err?
				cb {error:err}
				return
			results.forEach (x)->delete x.password
			cb results

# 成功: {id: roomid}
# 失敗: {error: ""}
	newRoom: (query,cb)->
		unless @session.user_id
			cb {error: "ログインしていません"}
			return
		M.rooms.count (err,count)->
			
			room=
				id:count	#ID連番
				name: query.name
				rule:
					number:parseInt query.number
				open:true
			room.password=query.password ? null
			room.comment=query.comment ? ""
			unless room.rule.number
				cb {error: "invalid players number"}
				return
	
			SS.server.user.myProfile (user)->
				room.owner=
					userid: user.userid
					name: user.name
				M.rooms.insert room
				cb {id: room.id}
	
		
