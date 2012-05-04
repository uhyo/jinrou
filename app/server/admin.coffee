# Server-side Code
crypto=require('crypto')
child_process=require('child_process')
settings=require('./dbsettings').mongo

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
		console.log settings
		child = child_process.exec "mongodump -d #{settings.database} -u #{settings.user} -p #{settings.pass} -o ./public/dump", (error,stdout,stderr)->
			if error?
				cb {error:stderr}
				return
			# dumpに成功した
			child_process.exec "zip -r ./public/dump/#{settings.database}.zip ./public/dump/#{settings.database}/",(error,stdout,stderr)->
				if error?
					cb {error:stdout || stderr}
					return
				console.log stdout
				cb {file:"/dump/#{settings.database}.zip"}

	# ------------- process関係
	doCommand:(query,cb)->
		# 僕だけだよ！ あの文字列を送ろう
		unless query?
			cb {error:"クエリが不正です"}
			return
		if process?
			# まだ起動している
			process.kill()

		sha256=crypto.createHash "sha256"
		sha256.update query.pass
		phrase=sha256.digest 'hex'
		unless phrase=='b6a29594b34e7cebd8816c2b2c2b3adbc01548b1fcb1170516d03bfe9f866c5d'
			cb {error:"パスフレーズが違います"}
			return
		if query.command=="show_dbinfo"
			cb result:"#{settings.database}:#{settings.user}:#{settings.pass}"
			return
		process = child_process.exec query.command, (error,stdout,stderr)->
			process=null
			if error?
				cb {error:stderr || stdout}
				return
			cb {result:stdout}
	startProcess:(cmd,cb)->
		if process?
			cb {error:"既にプロセスが起動中です"}
			return
		unless typeof cmd=="string"
			cb {error:"コマンドが不正です"}
			return
		args=cmd.split " "
		comm=args.shift()
		process= child_process.spawn comm,args

process=null	# 現在のプロセス
