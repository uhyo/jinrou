#ユーザー管理の何か
user=require './user.coffee'
#params: params.userid, params.password
exports.authenticate = (params) ->
	M.users.findOne {userid:params.userid, password:user.crpassword(params.password)}, (err,doc)->
		if doc?
			# ログイン成功
			delete doc.password	# パスワードは隠す
			doc.success=true
			res doc
		else
			res {success:false}
