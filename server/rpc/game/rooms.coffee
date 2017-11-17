libblacklist = require '../../libs/blacklist.coffee'
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
  blind:""/"hide"/"complete"
  number: Number(プレイヤー数)
  players:[PlayerObject,PlayerObject,...]
  gm: Booelan(trueならオーナーGM)
  jobrule: String   //開始後はなんの配役か（エンドレス闇鍋用）
  ban: [String]  // kicked userid
}
PlayerObject.start=Boolean
PlayerObject.mode="player" / "gm" / "helper"
###
page_number=10

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
    oauth:require '../../oauth.coffee'
    log:require '../../log.coffee'
# ヘルパーセット処理
sethelper=(ss,roomid,userid,id,res)->
    Server.game.rooms.oneRoomS roomid,(room)->
        if !room || room.error?
            res "その部屋はありません"
            return
        pl = room.players.filter((x)->x.realid==userid)[0]
        topl=room.players.filter((x)->x.userid==id)[0]
        if pl?.mode=="gm"
            res "GMはヘルパーになれません"
            return
        if userid==id
            res "自分のヘルパーにはなれません"
            return
        unless room.mode=="waiting"
            res "もう始まっています"
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
                        res "エラー:#{err}"
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
            res result

    # 成功: {id: roomid}
    # 失敗: {error: ""}
    newRoom: (query)->
        unless req.session.userId
            res {error: "ログインしていません"}
            return
        unless query.name?.trim?()
            res {error: "部屋名を入力してください"}
            return
        if query.name.length > Config.maxlength.room.name
            res {error: "部屋名が長すぎます"}
            return
        if query.comment && query.comment.length > Config.maxlength.room.comment
            res {error: "コメントが長すぎます"}
            return
        unless query.blind in ['', 'yes', 'complete']
            res {error: "パラメータが不正です"}
            return
        unless libblacklist.checkPermission "play", req.session.ban
            res {error: "アクセス制限により、部屋を作成できません。"}
            return

        M.rooms.find().sort({id:-1}).limit(1).nextObject (err,doc)=>
            id=if doc? then doc.id+1 else 1
            room=
                id:id   #ID連番
                name: query.name
                number:parseInt query.number
                mode:"waiting"
                players:[]
                made:Date.now()
                jobrule:null
            room.password=query.password ? null
            room.blind=query.blind
            room.comment=query.comment ? ""
            #unless room.blind
            #   room.players.push req.session.user
            unless room.number
                res {error: "invalid players number"}
                return
            room.owner=
                userid:req.session.user.userid
                name:req.session.user.name
            room.gm = query.ownerGM=="yes"
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
                    Server.oauth.template room.id,"「#{room.name}」（#{room.id}番#{if room.password then '・🔒パスワードあり' else ''}#{if room.blind then '・👤覆面' else ''}#{if room.gm then '・GMあり' else ''}）が建てられました。 #月下人狼",Config.admin.password

                    Server.log.makeroom req.session.user, room

    # 部屋に入る
    # 成功ならnull 失敗ならエラーメッセージ
    join: (roomid,opt)->
        unless req.session.userId
            res {error:"ログインして下さい",require:"login"}    # ログインが必要
            return
        unless libblacklist.checkPermission "play", req.session.ban
            # アクセス制限
            res {
                error: "アクセス制限により、部屋に参加できません。"
            }
            return
        Server.game.rooms.oneRoomS roomid,(room)=>
            if !room || room.error?
                res error:"その部屋はありません"
                return
            if req.session.userId in (room.players.map (x)->x.realid)
                res error:"すでに参加しています"
                return
            if Array.isArray(room.ban) && (req.session.userId in room.ban)
                res error:"この部屋への参加は禁止されています"
                return
            if opt.name in (room.players.map (x)->x.name)
                res error:"名前 #{opt.name} は既に存在します"
                return
            if room.gm && room.owner.userid==req.session.userId
                res error:"ゲームマスターは参加できません"
                return
            unless room.mode=="waiting" || (room.mode=="playing" && room.jobrule=="特殊ルール.エンドレス闇鍋")
                res error:"既に参加は締めきられています"
                return
            if room.mode=="waiting" && room.players.length >= room.number
                # 満員
                res error:"これ以上入れません"
                return
            if room.mode=="playing" && room.jobrule=="特殊ルール.エンドレス闇鍋"
                # エンドレス闇鍋の場合はゲーム内人数による人数判定を行う
                if Server.game.game.endlessPlayersNumber(roomid) >= room.number
                    # 満員
                    res error:"これ以上入れません"
                    return
            #room.players.push req.session.user
            su=req.session.user
            user=
                userid:req.session.userId
                realid:req.session.userId
                name:su.name
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
                res error:"Link for Icon is too long.（#{user.icon.length}）"
                return
            if room.blind
                unless opt?.name
                    res error:"名前を入力して下さい"
                    return
                if opt.name.length > Config.maxlength.user.name
                    res {error: "名前が長すぎます"}
                    return
                # 覆面
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
                user.name=opt.name
                user.userid=makeid()
                user.icon= opt.icon ? null
            if user.name.trim() == ''
                res error:"名前は空白のみにすることはできません"
                return
            M.rooms.update {id:roomid},{$push: {players:user}},(err)=>
                if err?
                    res error:"エラー:#{err}"
                else
                    res null
                    # 入室通知
                    delete user.ip
                    Server.game.game.inlog room,user
                    if room.blind
                        delete user.realid
                    if room.mode!="playing"
                        ss.publish.channel "room#{roomid}", "join", user
    # 部屋から出る
    unjoin: (roomid)->
        unless req.session.userId
            res "ログインして下さい"
            return
        Server.game.rooms.oneRoomS roomid,(room)=>
            if !room || room.error?
                res "その部屋はありません"
                return
            pl = room.players.filter((x)->x.realid==req.session.userId)[0]
            unless pl
                res "まだ参加していません"
                return
            if pl.mode=="gm"
                res "GMは退室できません"
                return
            unless room.mode=="waiting"
                res "もう始まっています"
                return
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
                    res "エラー:#{err}"
                else
                    res null
                    # 退室通知
                    Server.game.game.outlog room,pl ? req.session.user
                    ss.publish.channel "room#{roomid}", "unjoin", pl?.userid


    ready:(roomid)->
        # 準備ができたか？
        unless req.session.userId
            res "ログインして下さい"
            return
        Server.game.rooms.oneRoomS roomid,(room)=>
            if !room || room.error?
                res "その部屋はありません"
                return
            unless req.session.userId in (room.players.map (x)->x.realid)
                res "まだ参加していません"
                return
            unless room.mode=="waiting"
                res "もう始まっています"
                return
            room.players.forEach (x,i)=>
                if x.realid==req.session.userId
                    M.rooms.update {
                        id: roomid
                        "players.realid": x.realid
                    }, {
                        $set: {
                            "players.$.start": !x.start
                        }
                    }, (err)=>
                        if err?
                            res "エラー:#{err}"
                        else
                            res null
                            # ready? 知らせる
                            ss.publish.channel "room#{roomid}", "ready", {userid:x.userid,start:!x.start}

    # 部屋から追い出す
    kick:(roomid,id,ban)->
        unless req.session.userId
            res "ログインして下さい"
            return
        Server.game.rooms.oneRoomS roomid,(room)=>
            if !room || room.error?
                res "その部屋はありません"
                return
            if room.owner.userid != req.session.userId
                res "オーナーしかkickできません"
                console.log room.owner,req.session.userId
                return
            unless room.mode=="waiting"
                res "もう始まっています"
                return
            pl=room.players.filter((x)->x.userid==id)[0]
            unless pl
                res "そのユーザーは参加していません"
                return
            if pl.mode=="gm"
                res "GMはkickできません"
                return
            room.players = room.players.filter (x)=> x.realid != pl.realid
            for p, i in room.players
                if p.mode == "helper_#{pl.userid}"
                    ss.publish.channel "room#{roomid}", "mode", {userid: p.userid, mode: "player"}
                    p.mode = "player"
                    if p.start
                        ss.publish.channel "room#{roomid}", "ready", {userid: p.userid, start: false}
                        p.start = false
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
                    res "エラー:#{err}"
                else
                    res null
                    if pl?
                        Server.game.game.kicklog room, pl
                        ss.publish.channel "room#{roomid}", "unjoin",id
                        ss.publish.user pl.realid, "kicked",{id:roomid}
    # ヘルパーになる
    helper:(roomid,id)->
        unless req.session.userId
            res "ログインして下さい"
            return
        sethelper ss,roomid,req.session.userId,id,res
    # 全員ready解除する
    unreadyall:(roomid,id)->
        unless req.session.userId
            res "ログインして下さい"
            return
        Server.game.rooms.oneRoomS roomid,(room)=>
            if !room || room.error?
                res "その部屋はありません"
                return
            if room.owner.userid != req.session.userId
                res "オーナーしかkickできません"
                console.log room.owner,req.session.userId
                return
            unless room.mode=="waiting"
                res "もう始まっています"
                return
            for p,i in room.players
                p.start = false
            M.rooms.update {id:roomid},{
                $set: {
                    players: room.players
                }
            },(err)=>
                if err?
                    res "エラー:#{err}"
                else
                    res null
                    # readyを初期化する系
                    ss.publish.channel "room#{roomid}", "unreadyall",id
    # 追い出しリストを取得
    getbanlist:(roomid)->
        unless req.session.userId
            res {error: "ログインしてください"}
            return
        Server.game.rooms.oneRoomS roomid,(room)=>
            if !room || room.error?
                res {error: "その部屋はありません"}
                return
            if room.owner.userid != req.session.userId
                res {error:"オーナーしかできません"}
                return
            res {result: room.ban}
    # 追い出しリストを編集
    cancelban:(roomid, ids)->
        unless req.session.userId
            res "ログインしてください"
            return
        unless Array.isArray ids
            res "不正な入力です"
            return
        Server.game.rooms.oneRoomS roomid, (room)->
            if !room || room.error?
                res "その部屋はありません"
                return
            if room.owner.userid != req.session.userId
                res "オーナーしかできません"
                return
            M.rooms.update {
                id: roomid
            }, {
                $pullAll: {
                    ban: ids
                }
            }, (err)->
                if err?
                    res "エラー:#{err}"
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
                res {error:"その部屋はありません"}
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
        #unless req.session.userId
        #   res "ログインして下さい"
        #   return
        #       req.session.channel.unsubscribe "room#{roomid}"
        req.session.channel.reset()
        res null
    # 部屋を削除
    del: (roomid)->
        unless req.session.userId
            res "ログインして下さい"
            return
        Server.game.rooms.oneRoomS roomid,(room)=>
            if !room || room.error?
                res "その部屋はありません"
                return
            if !room.old && room.owner.userid != req.session.userId
                res "オーナーしか削除できません"
                return
            unless room.mode=="waiting"
                res "もう始まっています"
                return
            M.rooms.update {id:roomid},{$set: {mode:"end"}},(err)=>
                if err?
                    res "エラー:#{err}"
                else
                    res null
                    Server.game.game.deletedlog ss,room
                    
    # 部屋探し
    find:(query,page)->
        unless query?
            res {error:"クエリが不正です"}
            return
        res {error:"現在ログ検索は利用できません。"}
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
            res {error:"ログインして下さい",require:"login"}    # ログインが必要
            return
        err = Server.game.game.suddenDeathPunish ss, roomid, req.session.userId, banIDs
        if err?
            res {error: err}
        else
            res null

#res: (err)->
setRoom=(roomid,room)->
    M.rooms.update {id:roomid},room,res
