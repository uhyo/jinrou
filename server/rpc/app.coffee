# Server-side Code

exports.actions=(req,res,ss)->
	# 外部URLを教えてあげる
	backdoor:(name)->
		res Config.backdoor[name]

  
