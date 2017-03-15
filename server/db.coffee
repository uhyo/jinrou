dbinit= ->
    c=Config.mongo
    mongodb=require 'mongodb'
    mongodb.MongoClient.connect "mongodb://#{c.user}:#{c.pass}@#{c.host}:#{c.port}/#{c.database}?w=0",(err,db)->
        if err?
            console.error err
            throw err
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
          col.ensureIndex {"userid":1},(err,idxname)->
            col.ensureIndex {"mail.token":1, "mail.timestamp":1}, (err)->
              col.ensureIndex {"mail.address":1}, (err)->
                cols_count()
        DB.collection "rooms", (err,col)->
          if err?
            console.log err
            throw err
          M.rooms=col
          col.ensureIndex {"id": 1},(err,idxname)->
            col.ensureIndex {"mode": 1},(err,idxname)->
              col.ensureIndex {"mode": 1, "made": -1}, (err,idxname)->
                col.ensureIndex {"players.realid": 1,"mode": 1, "made": -1}, (err,idxname)->
                  col.ensureIndex {"made": -1, "mode": 1}, (err,idxname)->
                    cols_count()
        DB.collection "games", (err,col)->
          if err?
            console.log err
            throw err
          M.games=col
          col.ensureIndex {"id":1},(err,idxname)->
            col.ensureIndex {"finished":1, "id":1}, (err,idxname)->
              cols_count()
        DB.collection "lobby",(err,col)->	# ロビーのログ
          if err?
            console.log err
            throw err
          M.lobby=col
          col.ensureIndex {"time":1},(err,idxname)->
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
          col.ensureIndex {"userid":1},(err,idxname)->
            cols_count()

exports.dbinit=dbinit

