# Server-side Code

exports.actions =
	enter:(cb)->
		@session.channel.subscribe 'lobby'
		M.lobby.find().sort({time:1}).limit(100).toArray (err,docs)->
			if err?
				console.log err
				throw err
			cb {logs:docs}
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
		cb null
