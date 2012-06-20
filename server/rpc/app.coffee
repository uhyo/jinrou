# Server-side Code

exports.actions =
	# 外部URLを教えてあげる
	backdoor:(name,cb)->
		cb Config.backdoor[name]
  
