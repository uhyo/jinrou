exports.start=(userid)->
	ss.rpc "user.userData", userid,null,(user)->
		unless user?
			Index.util.message "エラー","そのユーザーは存在しません"
			return
		$("#uname").text user.name
		$("#userid").text userid
		$("#usercomment").text user.comment
exports.end=->
