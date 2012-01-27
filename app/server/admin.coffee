# Server-side Code

exports.actions =
	# 現在のセッションを管理者として承認する
	regist:(query,cb)->
		if query.password==SS.config.admin.password
			@session.attributes.administer=true
			@session.save ->cb null
		else
			cb "パスワードが違います。"

	# ------------- blacklist関係
	# blacklist一覧を得る
	getBlacklist:(query,cb)->
		unless @session.attributes.administer
			cb {error:"管理者ではありません"}
			return
		M.blacklist.find().limit(100).skip(100*(query.page ? 0)).toArray (err,docs)->
			cb {docs:docs}
	addBlacklist:(query,cb)->
		unless @session.attributes.administer
			cb {error:"管理者ではありません"}
			return
		M.users.findOne {userid:query.userid},(err,doc)->
			unless doc?
				cb {error:"そのユーザーは見つかりません"}
				return
			addquery=
				userid:doc.userid
				ip:doc.ip
			if query.expire=="some"
				d=new Date()
				d.setMonth d.getMonth()+parseInt query.month
				d.setDate d.getDate()+parseInt query.day
				addquery.expires=d
			M.blacklist.insert addquery,{safe:true},(err,doc)->
				cb null
	removeBlacklist:(query,cb)->
		unless @session.attributes.administer
			cb {error:"管理者ではありません"}
			return
		M.blacklist.remove {userid:query.userid},(err)->
			cb null
	
	# -------------- grandalert関係
	spreadGrandalert:(query,cb)->
		unless @session.attributes.administer
			cb {error:"管理者ではありません"}
			return
		message=
			title:query.title
			message:query.message
		SS.publish.broadcast 'grandalert',message
		cb null
		

