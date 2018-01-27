# Server-side Code

Server=
    log:require '../log.coffee'

libblacklist = require '../libs/blacklist.coffee'
libi18n      = require '../libs/i18n.coffee'

i18n = libi18n.getWithDefaultNS 'lobby'

players=[]  # ロビーにいる人たち
heartbeat_time=10

deleteuser=(userid,ss)->
    plobj=
        userid:userid
        name:null
        heartbeat:0
    players=players.filter (x)->x.userid!=userid    # 抜ける
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
    req.use 'user.fire.wall'
    req.use 'session'

    enter:->
        if req.session.userId && libblacklist.checkPermission "lobby_say", req.session.ban
            unless players.some((x)=>x.userid==req.session.userId)
                plobj=
                    userid:req.session.userId
                    name:req.session.user.name
                    heartbeat:Date.now()    # 最終heartbeatタイム
                players.push plobj

                ss.publish.channel "lobby","enter",plobj
            heartbeat req.session.userId,ss

        req.session.channel.subscribe 'lobby'
        M.lobby.find({}).project({name:1, comment:1, time:1}).sort({time:-1}).limit(100).toArray (err,docs)->
            if err?
                console.log err
                res {error: err}
                return
            res {logs:docs,players:players}
    say:(comment)->
        unless req.session.userId?
            res {error: i18n.t "common:error.needLogin"}
            return
        unless comment
            res {error: i18n.t "error.say.needComment"}
            return
        unless libblacklist.checkPermission "lobby_say", req.session.ban
            res {error: i18n.t "error.say.banned"}
            return
        log=
            userid:req.session.userId
            name:req.session.user.name
            comment:comment
            time:Date.now()
        M.lobby.insert log
        ss.publish.channel "lobby","log",log
        res null

        Server.log.speakInLobby req.session.user, log
    bye:->
        req.session.channel.unsubscribe 'lobby'
        if req.session.userId
            deleteuser req.session.userId,ss
        res null
    heartbeat:->
        if req.session.userId
            pl=players.filter((x)=>x.userid==req.session.userId)[0]
            if pl?
                pl.heartbeat=Date.now()
                console.log "heartbeat [#{req.session.userId}]: #{new Date()}"
        res null
                
