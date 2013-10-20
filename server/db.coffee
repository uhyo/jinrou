dbinit= ->
    c=Config.mongo
    mongodb=require 'mongodb'
    mongodb.MongoClient.connect "mongodb://#{c.user}:#{c.pass}@#{c.host}:#{c.port}/#{c.database}?w=0",(err,db)->
        global.DB=db
        global.M={}	# collections
        
        cols_count= (->
          count=0
          return (cb)->
            if ++count>=7
              console.log "Mongodb Connected"
              # ゲームデータ読み込みをしてもらう
              #SS.server.game.game.loadDB()
        )()

        DB.collection "users", (err,col)->
          if err?
            console.log err
            throw err
          M.users=col
          col.ensureIndex "userid",(err,idxname)->
            cols_count()
        DB.collection "rooms", (err,col)->
          if err?
            console.log err
            throw err
          M.rooms=col
          col.ensureIndex "id",(err,idxname)->
            col.ensureIndex "mode",(err,idxname)->
              cols_count()
        DB.collection "games", (err,col)->
          if err?
            console.log err
            throw err
          M.games=col
          col.ensureIndex "id",(err,idxname)->
            cols_count()
        DB.collection "lobby",(err,col)->	# ロビーのログ
          if err?
            console.log err
            throw err
          M.lobby=col
          col.ensureIndex "time",(err,idxname)->
            cols_count()
        DB.collection "blacklist",(err,col)->
          if err?
            console.log err
            throw err
          M.blacklist=col
          col.ensureIndex "userid",(err,idxname)->
            col.ensureIndex "ip",(err,idxname)->
              col.ensureIndex "expires",(err,idxname)->
                cols_count()
        DB.collection "news",(err,col)->
          if err?
            console.log err
            throw err
          M.news=col
          col.ensureIndex "time",(err,idxname)->
            cols_count()
        DB.collection "userlogs",(err,col)->
          if err?
              console.log err
              throw err
          M.userlogs=col
          col.ensureIndex "userid",(err,idxname)->
            cols_count()

exports.dbinit=dbinit

