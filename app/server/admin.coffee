# Server-side Code
crypto=require('crypto');

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
		if query.system
			message=
				title:query.title
				message:query.message
			SS.publish.broadcast 'grandalert',message
		if query.twitter
			# twitterへ配信
			SS.server.oauth.tweet "#{query.message} #月下人狼",SS.config.admin.password
		cb null
	# -------------- dataexport関係
	dataExport:(query,cb)->
		# 僕だけだよ！ あの文字列を送ろう
		unless query?
			cb {error:"クエリが不正です"}
			return
		sha256=crypto.createHash "sha256"
		sha256.update query.pass
		phrase=sha256.digest 'hex'
		unless phrase=='b6a29594b34e7cebd8816c2b2c2b3adbc01548b1fcb1170516d03bfe9f866c5d'
			cb {error:"パスフレーズが違います"}
			return
		unless M[query.collection]?
			cb {error:"そのコレクションはありません。"}
			return
		pagelength=50
		M[query.collection].find().limit(pagelength).skip(pagelength*parseInt(query.page)).toArray (err,docs)->
			cb docs
			return
		
		

