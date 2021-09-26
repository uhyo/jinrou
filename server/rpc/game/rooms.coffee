libblacklist = require '../../libs/blacklist.coffee'
libuserlogs = require '../../libs/userlogs.coffee'
libi18n = require '../../libs/i18n.coffee'
libready = require '../../libs/ready.coffee'

i18n = libi18n.getWithDefaultNS 'rooms'

###
room: {
  id: Number
  name: String
  owner:{
    userid: Userid
    name: String
  }
  password: Hashed Password
  comment: String
  mode: "waiting"/"playing"/"end"
  made: Time(Number)(作成された日時）
  blind:""/"yes"/"complete"
  theme: String(theme of room)
  number: Number(プレイヤー数)
  players:[PlayerObject,PlayerObject,...]
  gm: Booelan(trueならオーナーGM)
  watchspeak: Boolean (trueなら観戦者の発言可）
  jobrule: String   //開始後はなんの配役か（エンドレス闇鍋用）
  ban: [String]  // kicked userid
}
PlayerObject.start=Boolean
PlayerObject.mode="player" / "gm" / "helper"
###
page_number=10

# Collection of jobs to reset readiness.
readyResetJobCollection = new Map

module.exports=
    # サーバー用 部屋1つ取得
    oneRoomS:(roomid,cb)->
        M.rooms.findOne {id:roomid},(err,result)=>
            if err?
                cb {error:err}
                return
            unless result?
                cb result
                return
            if result.made < Date.now()-Config.rooms.fresh*3600000
                result.old=true
            cb result

Server=
    game:
        game:require './game.coffee'
        rooms:module.exports
        themes:require './themes.coffee'
    oauth:require '../../oauth.coffee'
    log:require '../../log.coffee'
crypto=require 'crypto'
# ヘルパーセット処理
sethelper=(ss,roomid,userid,id,res)->
    Server.game.rooms.oneRoomS roomid,(room)->
        if !room || room.error?
            res i18n.t "error.noSuchRoom"
            return
        pl = room.players.filter((x)->x.realid==userid)[0]
        topl=room.players.filter((x)->x.userid==id)[0]
        if pl?.mode=="gm"
            res i18n.t "error.gmCannotBeHelper"
            return
        if pl?.userid == topl?.userid
            res i18n.t "error.noSelfHelper"
            return
        unless room.mode=="waiting"
            res i18n.t "error.alreadyStarted"
            return
        mode= if topl? then "helper_#{id}" else "player"
        room.players.forEach (x,i)=>
            if x.realid==userid
                M.rooms.update {
                    id: roomid
                    "players.realid": x.realid
                }, {
                    $set: {
                        "players.$.mode": mode
                    }
                }, (err)=>
                    if err?
                        res String err
                    else
                        res null
                        # ヘルパーの様子を 知らせる
                        if pl.mode!=mode
                            # 新しくなった
                            Server.game.game.helperlog ss,room,pl,topl
                            ss.publish.channel "room#{roomid}", "mode", {userid:x.userid,mode:mode}

module.exports.actions=(req,res,ss)->
    req.use 'user.fire.wall'
    req.use 'session'

    getRooms:(mode,page)->
        if mode=="log"
            query=
                mode:"end"
        else if mode=="my"
            query=
                mode:"end"
                "players.realid":req.session.userId
        else if mode=="old"
            # 古い部屋
            query=
                mode:
                    $ne:"end"
                made:
                    $lte:Date.now()-Config.rooms.fresh*3600000
        else
            # 新しい部屋
            query=
                mode:
                    $ne:"end"
                made:
                    $gt:Date.now()-Config.rooms.fresh*3600000

        M.rooms.find(query).sort({made:-1}).skip(page*page_number).limit(page_number).toArray (err,results)->
            if err?
                res {error:err}
                return
            results.forEach (x)->
                if x.password?
                    x.needpassword=true
                    delete x.password
                if x.blind
                    delete x.owner
                    x.players.forEach (p)->
                        delete p.realid
                unless x.watchspeak?
                    # old rooms do not have watchspeak set.
                    # watchspeak defaults to true.
                    x.watchspeak = true
                if x.theme
                    theme = Server.game.themes.getTheme x.theme
                    unless theme == null
                        x.themeFullName = theme.name
            res results
    getMyRooms:(page)->
        # extract user's play logs from userrawlogs
        M.userrawlogs.aggregate [
            {
                $match:
                    userid: req.session.userId
                    type: libuserlogs.DataTypes.game
            }, {
                $sort:
                    gameid: -1
            }, {
                $skip: page * page_number
            }, {
                $limit: page_number
            }, {
            # join with room object
                $lookup:
                    from: "rooms"
                    localField: "gameid"
                    foreignField: "id"
                    as: "room"
            }, {
                $unwind: "$room"
            },
        ], (err, results)->
            if err?
                res {error: String err}
                return
            for x in results
                if x.room?
                    if x.room.password?
                        x.room.needpassword = true
                        x.room.password = undefined
                    if x.room.blind
                        x.room.owner = undefined
                    for p in x.room.players
                        # find my player
                        if p.realid == req.session.userId
                            p.me = true
                        p.realid = undefined
            res results


    oneRoom:(roomid)->
        M.rooms.findOne {id:roomid},(err,result)=>
            if err?
                res {error:err}
                return
            # クライアントからの問い合わせの場合
            pl = result.players.filter((x)-> x.realid==req.session.userId)[0]
            result.players.forEach (p)->
                unless result.blind == "" || pl?.mode == "gm"
                    delete p.realid
                delete p.ip
            # ふるいかどうか
            if result.made < Date.now()-Config.rooms.fresh*3600000
                result.old=true
            # パスワードをアレする
            result.password = !!result.password
            if result.theme
                theme = Server.game.themes.getTheme result.theme
                unless theme == null
                    result.themeFullName = theme.name
            res result

    # 成功: {id: roomid}
    # 失敗: {error: ""}
    newRoom: (query)->
        unless req.session.userId
            res {error: i18n.t "common:error.needLogin"}
            return
        unless query.name?.trim?()
            res {error: i18n.t "error.newRoom.noName"}
            return
        if query.name.length > Config.maxlength.room.name
            res {error: i18n.t "error.newRoom.nameTooLong"}
            return
        if query.comment && query.comment.length > Config.maxlength.room.comment
            res {error: i18n.t "error.newRoom.commentTooLong"}
            return
        maxNumber = parseInt query.number, 10
        if maxNumber < 5
            res {error: i18n.t "error.newRoom.maxNumberTooSmall"}
            return
        unless query.blind in ['', 'yes', 'complete']
            res {error: i18n.t "error.newRoom.invalidParameter"}
            return
        unless libblacklist.checkPermission "play", req.session.ban
            res {error: i18n.t "error.newRoom.banned"}
            return

        M.rooms.find().sort({id:-1}).limit(1).nextObject (err,doc)=>
            id=if doc? then doc.id+1 else 1
            room=
                id:id   #ID連番
                name: query.name
                number: maxNumber
                mode:"waiting"
                players:[]
                made:Date.now()
                jobrule:null
            room.password=query.password ? null
            room.blind=query.blind
            room.theme=query.theme
            if room.theme
                theme = Server.game.themes.getTheme room.theme
                unless theme
                    res {error: i18n.t "error.theme.noTheme"}
                    return
                if !theme.isAvailable?()
                    res {error: i18n.t "error.theme.notAvailable", {name: theme.name}}
                    return
                if !theme.lockable && room.password
                    res {error: i18n.t "error.theme.notLockable", {name: theme.name}}
                    return
                if room.blind == ""
                    res {error: i18n.t "error.theme.notBlind"}
                    return

                skins = Object.keys theme.skins
                if room.number > skins.length
                    res {error: i18n.t "error.theme.playerTooMuch", {
                        name: theme.name
                        length: skins.length
                    }}
                    return
            room.comment=query.comment ? ""
            #unless room.blind
            #   room.players.push req.session.user
            unless room.number
                res {error: i18n.t "error.newRoom.invalidParameter"}
                return
            room.owner=
                userid:req.session.user.userid
                name:req.session.user.name
            room.gm = query.ownerGM=="yes"
            room.watchspeak = query.watchspeak == "on"
            if query.ownerGM=="yes"
                # GMがいる
                su=req.session.user
                room.players.push {
                    userid: req.session.user.userid
                    realid: req.session.user.userid
                    name:su.name
                    ip:su.ip
                    icon:su.icon
                    start:true
                    mode:"gm"
                    nowprize:null
                }
            M.rooms.insertOne room, {w: 1}, (err)->
                if err?
                    res {error: err}
                    return
                Server.game.game.newGame room,ss, (err)->
                    if err?
                        # TODO: revert?
                        res {error: err}
                        return
                    res {id: room.id}
                    # build options string
                    delimiter = i18n.t "tweet.newRoom.delimiter"
                    options = [
                        (if room.password then delimiter + i18n.t("tweet.newRoom.password") else ''),
                        (if room.blind then delimiter + i18n.t("tweet.newRoom.blind") else ''),
                        (if room.gm then delimiter + i18n.t("tweet.newRoom.gm") else ''),
                    ].join ''
                    tweet = i18n.t "tweet.newRoom.main", {
                        name: Server.oauth.sanitizeTweet room.name
                        id: room.id
                        options: options
                    }
                    Server.oauth.template room.id, tweet, Config.admin.password

                    Server.log.makeroom req.session.user, room

    # 部屋に入る
    # 成功ならnull 失敗ならエラーメッセージ
    join: (roomid,opt)->
        unless req.session.userId
            res {error: i18n.t("common:error.needLogin"), require:"login"}    # ログインが必要
            return
        unless libblacklist.checkPermission "play", req.session.ban
            # アクセス制限
            res {
                error: i18n.t "error.join.banned"
            }
            return

        #Function to sanitize log text.
        #Removes Unicode bidi characters.
        sanitizeName = (name)->
            return name.replace(/[\u200b-\u200f\u202a-\u202e\u2066-\u2069]/g, '')

        opt.name = sanitizeName opt.name

        Server.game.rooms.oneRoomS roomid,(room)=>
            if !room || room.error?
                res error: i18n.t "error.noSuchRoom"
                return
            if req.session.userId in (room.players.map (x)->x.realid)
                res error: i18n.t "error.join.alreadyJoined"
                return
            if Array.isArray(room.ban) && (req.session.userId in room.ban)
                res error: i18n.t "error.join.kicked"
                return
            if opt.name in (room.players.map (x)->x.name)
                res error: i18n.t "error.join.nameUsed", {name: opt.name}
                return
            if room.gm && room.owner.userid==req.session.userId
                res error: i18n.t "error.join.alreadyJoined"
                return
            unless room.mode=="waiting" || (room.mode=="playing" && room.jobrule=="特殊ルール.エンドレス闇鍋")
                res error: i18n.t "error.alreadyStarted"
                return
            if room.mode=="waiting" && room.players.length >= room.number
                # 満員
                res error: i18n.t "error.join.full"
                return
            if room.mode=="playing" && room.jobrule=="特殊ルール.エンドレス闇鍋"
                # エンドレス闇鍋の場合はゲーム内人数による人数判定を行う
                unless Server.game.game.endlessCanEnter(roomid, req.session.userId, room.number)
                    # 満員
                    res error: i18n.t "error.join.full"
                    return
            #room.players.push req.session.user
            su=req.session.user
            user=
                userid:req.session.userId
                realid:req.session.userId
                name:sanitizeName su.name
                ip:su.ip
                icon:su.icon
                start:false
                mode:"player"
                nowprize:su.nowprize

            # 同IP制限
            ###
            if room.players.some((x)->x.ip==su.ip) && su.ip!="127.0.0.1"
                res error:"重複参加はできません #{su.ip}"
                return
            ###

            # please no, link of data:image/jpeg;base64 would be a disaster
            if user.icon?.length > Config.maxlength.user.icon
                res error: i18n.t "error.join.iconTooLong"
                return

            if room.theme
                theme = Server.game.themes.getTheme room.theme
                if theme == null
                    res {error: i18n.t "error.theme.noTheme"}
                    return
                if !theme.isAvailable?()
                    res {error: i18n.t "error.theme.notAvailable", {name: theme.name}}
                    return

            if room.blind
                unless opt?.name || room.theme
                    res error: i18n.t "error.join.nameNeeded"
                    return
                if opt.name.length > Config.maxlength.user.name
                    res {error: i18n.t "error.join.nameTooLong"}
                    return
                # テーマmode
                if room.theme && theme != null
                    skins = Object.keys theme.skins
                    skins = skins.filter((x)->!room.players.some((pl)->theme.skins[x].name==pl.name))
                    skin = skins[Math.floor(Math.random() * skins.length)]

                    user.name=theme.skins[skin].name.trim()
                    loop
                        user.userid=crypto.randomBytes(10).toString('hex')
                        if user.userid? && room.players.every((pl)->user.userid!=pl.userid)
                            break

                    avatar = theme.skins[skin].avatar
                    # his icon could be Array or a link.
                    if Array.isArray avatar
                        avatar = avatar[Math.floor(Math.random() * avatar.length)]
                    user.icon= avatar ? null
                # 覆面
                else
                    makeid=->   # ID生成
                        re=""
                        while !re
                            i=0
                            while i<20
                                re+="0123456789abcdef"[Math.floor Math.random()*16]
                                i++
                            if room.players.some((x)->x.userid==re)
                                re=""
                        re
                    user.name=sanitizeName opt.name
                    user.userid=makeid()
                    user.icon= opt.icon ? null
            if user.name.trim() == ''
                res error: i18n.t "error.join.nameOnlySpaces"
                return
            M.rooms.update {id:roomid},{$push: {players:user}},(err)=>
                if err?
                    res error: String err
                else
                    if room.theme && theme != null
                        # show player who he is.
                        pr = theme.skins[skin].prize
                        # his prize could be Array
                        if Array.isArray pr
                            pr = pr[Math.floor(Math.random() * pr.length)]
                        # pass it to Server.game.game.inlog
                        if pr
                            user.tpr = pr
                            name = "「#{user.tpr}」#{user.name}"
                        else
                            name = "#{user.name}"
                        res
                            tip: "#{name}"
                            title:"#{theme.skin_tip}"
                    else
                        res null
                    # 入室通知
                    delete user.ip
                    Server.game.game.inlog room,user
                    delete user.tpr
                    if room.blind
                        delete user.realid
                    if room.mode!="playing"
                        ss.publish.channel "room#{roomid}", "join", user
    # 部屋から出る
    unjoin: (roomid)->
        unless req.session.userId
            res i18n.t "common:error.needLogin"
            return
        Server.game.rooms.oneRoomS roomid,(room)=>
            if !room || room.error?
                res i18n.t "error.noSuchRoom"
                return
            pl = room.players.filter((x)->x.realid==req.session.userId)[0]
            unless pl
                res i18n.t "error.notMember"
                return
            if pl.mode=="gm"
                res i18n.t "error.unjoin.noGMLeave"
                return
            unless room.mode=="waiting"
                res i18n.t "error.alreadyStarted"
                return
            libready.unregister roomid, pl
            # consistencyのためにplayersをまるごとアップデートする
            room.players = room.players.filter (x)=> x.realid != req.session.userId
            # ヘルパーになっている人は解除
            for p, i in room.players
                if p.mode == "helper_#{pl.userid}"
                    ss.publish.channel "room#{roomid}", "mode", {userid: p.userid, mode: "player"}
                    p.mode = "player"
                    if p.start
                        ss.publish.channel "room#{roomid}", "ready", {userid: p.userid, start: false}
                        p.start = false
            M.rooms.update {id:roomid},{$set: {players: room.players}},(err)=>
                if err?
                    res String err
                else
                    res null
                    # 退室通知
                    Server.game.game.outlog room,pl ? req.session.user
                    ss.publish.channel "room#{roomid}", "unjoin", pl?.userid


    ready:(roomid)->
        # 準備ができたか？
        unless req.session.userId
            res i18n.t "common:error.needLogin"
            return
        Server.game.rooms.oneRoomS roomid,(room)=>
            if !room || room.error?
                res i18n.t "error.noSuchRoom"
                return
            unless req.session.userId in (room.players.map (x)->x.realid)
                res i18n.t "error.notMember"
                return
            unless room.mode=="waiting"
                res i18n.t "error.alreadyStarted"
                return
            room.players.forEach (x,i)=>
                if x.realid==req.session.userId
                    libready.setReady(ss, roomid, x, !x.start)
                        .then(-> res null)
                        .catch((err)-> res String err)

    # 部屋から追い出す
    kick:(roomid,id,ban)->
        unless req.session.userId
            res i18n.t "common:error.needLogin"
            return
        Server.game.rooms.oneRoomS roomid,(room)=>
            if !room || room.error?
                res i18n.t "error.noSuchRoom"
                return
            if room.owner.userid != req.session.userId
                res i18n.t "common:error.invalidInput"
                return
            unless room.mode=="waiting"
                res i18n.t "error.alreadyStarted"
                return
            pl=room.players.filter((x)->x.userid==id)[0]
            unless pl
                res i18n.t "common:error.invalidInput"
                return
            if pl.mode=="gm"
                res i18n.t "error.kick.noKickGM"
                return
            room.players = room.players.filter (x)=> x.realid != pl.realid
            for p, i in room.players
                if p.mode == "helper_#{pl.userid}"
                    ss.publish.channel "room#{roomid}", "mode", {userid: p.userid, mode: "player"}
                    p.mode = "player"
                    if p.start
                        ss.publish.channel "room#{roomid}", "ready", {userid: p.userid, start: false}
                        p.start = false

            libready.unregister roomid, pl
            update = {
                $set: {
                    players: room.players
                }
            }
            if ban
                # add to banned list
                update.$addToSet =
                    ban: id
            M.rooms.update {id:roomid}, update, (err)=>
                if err?
                    res String err
                else
                    res null
                    if pl?
                        Server.game.game.kicklog room, pl
                        ss.publish.channel "room#{roomid}", "unjoin",id
                        ss.publish.user pl.realid, "kicked",{id:roomid}
    # ヘルパーになる
    helper:(roomid,id)->
        unless req.session.userId
            res i18n.t "common:error.needLogin"
            return
        sethelper ss,roomid,req.session.userId,id,res
    # 全員ready解除する
    unreadyall:(roomid)->
        unless req.session.userId
            res i18n.t "common:error.needLogin"
            return
        Server.game.rooms.oneRoomS roomid,(room)=>
            if !room || room.error?
                res i18n.t "error.noSuchRoom"
                return
            if room.owner.userid != req.session.userId
                res i18n.t "common:error.invalidInput"
                console.log room.owner,req.session.userId
                return
            unless room.mode=="waiting"
                res i18n.t "error.alreadyStarted"
                return
            libready.unreadyAll(ss, roomid, room.players)
                .then(()-> res null)
                .catch((err)-> res String err)
    # 追い出しリストを取得
    getbanlist:(roomid)->
        unless req.session.userId
            res {error: i18n.t "common:error.needLogin"}
            return
        Server.game.rooms.oneRoomS roomid,(room)=>
            if !room || room.error?
                res {error: i18n.t "error.noSuchRoom"}
                return
            if room.owner.userid != req.session.userId
                res {error: i18n.t "common:error.invalidInput"}
                return
            res {result: room.ban ? []}
    # 追い出しリストを編集
    cancelban:(roomid, ids)->
        unless req.session.userId
            res i18n.t "common:error.needLogin"
            return
        unless Array.isArray ids
            res i18n.t "common:error.invalidInput"
            return
        Server.game.rooms.oneRoomS roomid, (room)->
            if !room || room.error?
                res i18n.t "error.noSuchRoom"
                return
            if room.owner.userid != req.session.userId
                res i18n.t "common:error.invalidInput"
                return
            M.rooms.update {
                id: roomid
            }, {
                $pullAll: {
                    ban: ids
                }
            }, (err)->
                if err?
                    res String err
                else
                    res null



    # 成功ならjoined 失敗ならエラーメッセージ
    # 部屋ルームに入る
    enter: (roomid,password)->
        #unless req.session.userId
        #   res {error:"ログインして下さい"}
        #   return
        Server.game.rooms.oneRoomS roomid,(room)=>
            if !room?
                res {error: i18n.t "error.noSuchRoom"}
                return
            if room.error?
                res {error:room.error}
                return
            # 古い部屋ならパスワードいらない
            od=Date.now()-Config.rooms.fresh*3600000
            if room.password? && room.mode!="end" && room.made>od && room.password!=password && password!=Config.admin.password
                res {require:"password"}
                return
            req.session.channel.reset()

            req.session.channel.subscribe "room#{roomid}"
            Server.game.game.playerchannel ss,roomid,req.session
            res {joined:room.players.some((x)=>x.realid==req.session.userId)}

    # 成功ならnull 失敗ならエラーメッセージ
    # 部屋ルームから出る
    exit: (roomid)->
        req.session.channel.reset()
        res null
    # 部屋を削除
    del: (roomid)->
        unless req.session.userId
            res i18n.t "common:error.needLogin"
            return
        Server.game.rooms.oneRoomS roomid,(room)=>
            if !room || room.error?
                res i18n.t "error.noSuchRoom"
                return
            if !room.old && room.owner.userid != req.session.userId
                res i18n.t "common:error.invalidInput"
                return
            unless room.mode=="waiting"
                res i18n.t "error.alreadyStarted"
                return
            for pl in room.players
                libready.unregister roomid, pl
            M.rooms.update {id:roomid},{$set: {mode:"end"}},(err)=>
                if err?
                    res String err
                else
                    res null
                    Server.game.game.deletedlog ss,room

    # 部屋探し
    find:(query,page)->
        unless query?
            res {error: i18n.t "common:error.invalidInput"}
            return
        res {error: i18n.t "error.find.disabled"}
        return
        q=
            finished:true
        if query.result_team
            q.winner=query.result_team  # 勝利陣営
        if query.min_number? && query.max_number
            q["$where"]="#{query.min_number}<=(l=this.players.length) && l<=#{query.max_number}"
        else if query.min_number?
            q["$where"]="#{query.min_number}<=this.players.length"
        else if query.max_number?
            q["$where"]="this.players.length<=#{query.max_number}"

        if query.min_day
            q.day ?= {}
            q.day["$gte"]=query.min_day
        if query.max_day
            q.day ?= {}
            q.day["$lte"]=query.max_day
        if query.rule
            q["rule.jobrule"]=query.rule
        # 日付新しい
        M.games.find(q).sort({_id:-1}).limit(page_number).skip(page_number*page).toArray (err,results)->
            if err?
                throw err
                return
            # gameを得たのでroomsに
            M.rooms.find({id:{$in: results.map((x)->x.id)}}).sort({_id:-1}).toArray (err,docs)->
                docs.forEach (x)->
                    if x.password?
                        x.needpassword=true
                        delete x.password
                    if x.blind
                        delete x.owner
                        x.players.forEach (p)->
                            delete p.realid
                res docs
    suddenDeathPunish:(roomid,banIDs)->
        # banIDs = ["someID","someID"]
        unless banIDs.length
            res null
            return
        unless req.session.userId
            res {error: i18n.t "common:error.needLogin",require:"login"}    # ログインが必要
            return
        err = Server.game.game.suddenDeathPunish ss, roomid, req.session.userId, banIDs
        if err?
            res {error: err}
        else
            res null

#res: (err)->
setRoom=(roomid,room)->
    M.rooms.update {id:roomid},room,res
