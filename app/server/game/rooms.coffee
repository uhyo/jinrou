rooms=[]
###
room: {
  id: Number
  owner: Userid
  password: Hashed Password
  comment: String

  rule:{
    number: Number # プレイヤー数
  }
}
###
exports.getRooms=(cb)->
	cb rooms.map (room)->
		{
			id:room.id
			owner:room.owner
		}

# 成功: {id: roomid}
# 失敗: {error: ""}
exports.newRoom= (query,cb)->
	unless @session.user_id
		cb {error: "ログインしていません"}
		return
	room=
		id:rooms.length	#ID連番
		name: query.name
		rule:
			number:parseInt query.number
	room.password=query.password ? null
	room.comment=query.comment ? ""
	unless room.rule.number
		cb {error: "invalid players number"}
		return
	rooms.push room
	cb {id: room.id}
	
	
		
