exports.start=(userid)->
	SS.server.user.userData userid,null,(user)->
		unless user?
			SS.client.util.message "エラー","そのユーザーは存在しません"
			return
		$("#uname").text user.name
		$("#userid").text userid
		$("#usercomment").text user.comment
exports.end=->
