# Server-side Code

exports.actions =
	# 外部URLを教えてあげる
	backdoor:(name,cb)->
		cb SS.config.backdoor[name]
  
dbinit= ->
    c=require('./dbsettings.coffee').mongo
    mongodb=require 'mongodb'
    global.DB= new mongodb.Db(c.database,new mongodb.Server(c.host,c.port))
    global.M={}	# collections
    
    cols_count= (->
      count=0
      return (cb)->
        if ++count>=5
          console.log "Mongodb Connected"
          # ゲームデータ読み込みをしてもらう
          SS.server.game.game.loadDB()
    )()

    DB.open (err, client)->
      if err?
        console.log err
        throw err
      DB.authenticate c.user, c.pass, (err)->
        if err?
          console.log err
          throw err
        DB.collection "users", (err,col)->
          if err?
            console.log err
            throw err
          M.users=col
          cols_count()
        DB.collection "rooms", (err,col)->
          if err?
            console.log err
            throw err
          M.rooms=col
          cols_count()
        DB.collection "games", (err,col)->
          if err?
            console.log err
            throw err
          M.games=col
          cols_count()
        DB.collection "lobby",(err,col)->	# ロビーのログ
          if err?
            console.log err
            throw err
          M.lobby=col
          cols_count()
        DB.collection "blacklist",(err,col)->
          if err?
            console.log err
            throw err
          M.blacklist=col
          cols_count()

dbinit()
