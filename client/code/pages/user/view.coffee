exports.start=(userid)->
	ss.rpc "user.userData", userid,null,(user)->
		unless user?
			Index.util.message "错误","这个玩家不存在"
			return
		$("#uname").text user.name
		$("#userid").text userid
		$("#usercomment").text user.comment
exports.end=->
