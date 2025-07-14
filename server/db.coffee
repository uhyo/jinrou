dbinit= (loaded)->
    c=Config.mongo
    mongodb=require 'mongodb'
    client = new mongodb.MongoClient("mongodb://#{c.user}:#{c.pass}@#{c.host}:#{c.port}/#{c.database}?w=0")
    client.connect (err)->
        if err?
            console.error err
            throw err
        global.DB=client.db(c.database)
        global.M={}	# collections

        cols_count= (->
          count=0
          return (cb)->
            if ++count>=10
              console.log "Mongodb Connected"
              # ゲームデータ読み込みをしてもらう
              #SS.server.game.game.loadDB()
              loaded()
        )()

        M.users=DB.collection "users"
        u1 = M.users.createIndex({"userid":1}, {unique: true})
        u2 = M.users.createIndex({"mail.token":1, "mail.timestamp":1})
        u3 = M.users.createIndex({"mail.address":1})
        Promise.all([u1, u2, u3]).then (results)->
          # console.log "Users collection indexes created"
          cols_count()

        M.rooms=DB.collection "rooms"
        r1 = M.rooms.createIndex({"id": 1}, {unique: true})
        r2 = M.rooms.createIndex({"mode": 1})
        r3 = M.rooms.createIndex({"mode": 1, "made": -1})
        r4 = M.rooms.createIndex({"players.realid": 1,"mode": 1, "made": -1})
        r5 = M.rooms.createIndex({"made": -1, "mode": 1})
        Promise.all([r1, r2, r3, r4, r5]).then (results)->
          # console.log "Rooms collection indexes created"
          cols_count()
        
        M.games=DB.collection "games"
        g1 = M.games.createIndex({"id":1}, {unique: true})
        g2 = M.games.createIndex({"finished":1, "id":1})
        Promise.all([g1, g2]).then (results)->
          # console.log "Games collection indexes created"
          cols_count()
        
        M.lobby=DB.collection "lobby"
        l1 = M.lobby.createIndex({"time":1})
        l1.then (result)->
          # console.log "Lobby collection indexes created"
          cols_count()

        M.blacklist=DB.collection "blacklist"
        b1 = M.blacklist.createIndex("id", {unique: true})
        b2 = M.blacklist.createIndex("userid", {unique: true})
        b3 = M.blacklist.createIndex("ip")
        b4 = M.blacklist.createIndex("expires")
        b5 = M.blacklist.createIndex("forgiveDate", {expireAfterSeconds: 365*24*60*60})
        Promise.all([b1, b2, b3, b4, b5]).then (results)->
          # console.log "Blacklist collection indexes created"
          cols_count()

        M.news=DB.collection "news"
        n1 = M.news.createIndex("time")
        n1.then (result)->
          # console.log "News collection indexes created"
          cols_count()

        M.userlogs=DB.collection "userlogs"
        userlogs1 = M.userlogs.createIndex({"userid":1}, {unique: true})
        userlogs1.then (result)->
          # console.log "Userlogs collection indexes created"
          cols_count()

        M.userrawlogs=DB.collection "userrawlogs"
        userrawlogs1 = M.userrawlogs.createIndex({"userid": 1, "type": 1, "subtype": 1, "timestamp": 1})
        userrawlogs2 = M.userrawlogs.createIndex({"userid": 1, "type": 1, "gameid": 1}, {unique: true})
        userrawlogs3 = M.userrawlogs.createIndex({"userid": 1, "timestamp": 1, "type": 1, "subtype": 1})
        Promise.all([userrawlogs1, userrawlogs2, userrawlogs3]).then (results)->
          # console.log "Userrawlogs collection indexes created"
          cols_count()

        M.usersummary=DB.collection "usersummary"
        usersummary1 = M.usersummary.createIndex({"userid": 1}, {unique: true})
        usersummary2 = M.usersummary.createIndex({"timestamp": 1}, {expireAfterSeconds: 60*60*24})
        Promise.all([usersummary1, usersummary2]).then (results)->
          # console.log "Usersummary collection indexes created"
          cols_count()

        M.gamelogs=DB.collection "gamelogs"
        gl1 = M.gamelogs.createIndex({"gameid": 1, "time": 1})
        gl1.then (result)->
          # console.log "Gamelogs collection indexes created"
          cols_count()

exports.dbinit=dbinit

exports.getLogCollection = (collName, callback)->
  col = DB.collection collName
  index1 = col.createIndex({"timestamp": 1})
  index2 = col.createIndex({"userid":1, "timestamp":1})
  index3 = col.createIndex({"ip":1, "timestamp":1})
  index4 = col.createIndex({"type":1, "timestamp":1})
  index5 = col.createIndex({"ip":1, "type":1, "timestamp":1})
  Promise.all([index1, index2, index3, index4, index5]).then (results)->
    callback null, col
