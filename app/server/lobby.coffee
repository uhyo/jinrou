# Server-side Code

players=[]	# ロビーにいる人たち
heartbeat_time=10

deleteuser=(userid)->
	plobj=
		userid:userid
		name:null
		heartbeat:0
	players=players.filter (x)->x.userid!=userid	# 抜ける
	SS.publish.channel "lobby","bye",plobj
	

heartbeat=(userid)->
	timer=setTimeout (->
		# heartbeatする
		SS.publish.user userid,"lobby_heartbeat",null
		console.log "heartbeat sent:#{new Date()}"
		time=Date.now()
		timer2=setTimeout (->
			# 3秒猶予
			pl=players.filter((x)->x.userid==userid)[0]
			if pl?
				if pl.heartbeat<time
					# いない
					deleteuser userid
				else
					# いたから次のheartbeat
					heartbeat userid
		),3000
	),heartbeat_time*1000

exports.actions =
	enter:(cb)->
		if @session.user_id
			plobj=
				userid:@session.user_id
				name:@session.attributes.user.name
				heartbeat:Date.now()	# 最終heartbeatタイム
			players.push plobj

			SS.publish.channel "lobby","enter",plobj
			heartbeat @session.user_id

		@session.channel.subscribe 'lobby'
		M.lobby.find().sort({time:1}).limit(100).toArray (err,docs)->
			if err?
				console.log err
				throw err
			cb {logs:docs,players:players}
	say:(comment,cb)->
		unless @session.user_id?
			return
		unless comment
			return
		log=
			name:@session.attributes.user.name
			comment:comment
			time:Date.now()
		M.lobby.insert log
		SS.publish.channel "lobby","log",log
	bye:(cb)->
		@session.channel.unsubscribe 'lobby'
		if @session.user_id
			deleteuser @session.user_id
		cb null
	heartbeat:(cb)->
		if @session.user_id
			pl=players.filter((x)=>x.userid==@session.user_id)[0]
			if pl?
				pl.heartbeat=Date.now()
				console.log "heartbeat [#{@session.user_id}]: #{new Date()}"
				
