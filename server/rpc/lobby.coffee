# Server-side Code

players=[]	# ロビーにいる人たち
heartbeat_time=10

deleteuser=(userid,ss)->
	plobj=
		userid:userid
		name:null
		heartbeat:0
	players=players.filter (x)->x.userid!=userid	# 抜ける
	ss.publish.channel "lobby","bye",plobj
	

heartbeat=(userid,ss)->
	timer=setTimeout (->
		# heartbeatする
		ss.publish.user userid,"lobby_heartbeat",null
		time=Date.now()
		timer2=setTimeout (->
			# 3秒猶予
			pl=players.filter((x)->x.userid==userid)[0]
			if pl?
				if pl.heartbeat<time
					# いない
					deleteuser userid,ss
				else
					# いたから次のheartbeat
					heartbeat userid,ss
		),3000
	),heartbeat_time*1000

exports.actions =(req,res,ss)->
	req.use 'session'

	enter:->
		if req.session.user_id
			unless players.some((x)=>x.userid==req.session.user_id)
				plobj=
					userid:req.session.user_id
					name:req.session.attributes.user.name
					heartbeat:Date.now()	# 最終heartbeatタイム
				players.push plobj

				ss.publish.channel "lobby","enter",plobj
			heartbeat req.session.user_id

		req.session.channel.subscribe 'lobby'
		M.lobby.find().sort({time:-1}).limit(100).toArray (err,docs)->
			if err?
				console.log err
				throw err
			res {logs:docs,players:players}
	say:(comment)->
		unless req.session.user_id?
			return
		unless comment
			return
		log=
			name:req.session.attributes.user.name
			comment:comment
			time:Date.now()
		M.lobby.insert log
		ss.publish.channel "lobby","log",log
	bye:->
		req.session.channel.unsubscribe 'lobby'
		if req.session.user_id
			deleteuser req.session.user_id
		res null
	heartbeat:->
		if req.session.user_id
			pl=players.filter((x)=>x.userid==req.session.user_id)[0]
			if pl?
				pl.heartbeat=Date.now()
				console.log "heartbeat [#{req.session.user_id}]: #{new Date()}"
		res null
				
