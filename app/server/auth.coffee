#ユーザー管理の何か
#params: params.userid, params.password
exports.authenticate = (params, cb) ->
	console.log "auth?"
	console.log SS.server.user
	M.users.findOne {userid:params.userid, password:SS.server.user.crpassword(params.password)}, (err,doc)->
		if doc?
			# ログイン成功
			delete doc.password	# パスワードは隠す
			doc.success=true
			cb doc
		else
			cb {success:false}
