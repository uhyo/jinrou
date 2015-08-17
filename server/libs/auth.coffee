#ユーザー管理の何か
#params: params.userid, params.password
exports.authenticate = (params, cb)->
	M.users.findOne {userid:params.userid, password:SS.server.user.crpassword(params.password)}, (err,doc)->
		if doc?
			# ログイン成功
			delete doc.password	# 密码は隠す
			doc.success=true
			cb doc
		else
			cb {success:false}
