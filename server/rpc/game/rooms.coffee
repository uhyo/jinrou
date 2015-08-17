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
  jobrule: String   //開始後はなんの配役か（Endless黑暗火锅用）
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
                res {error:err}
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
# 帮手セット処理
sethelper=(ss,roomid,userid,id,res)->
    Server.game.rooms.oneRoomS roomid,(room)->
        if !room || room.error?
            res "这个房间不存在"
            return
        pl = room.players.filter((x)->x.realid==userid)[0]
        topl=room.players.filter((x)->x.userid==id)[0]
        if pl?.mode=="gm"
            res "GM不能成为帮手"
            return
        if userid==id
            res "不能成为自己的帮手"
            return
        unless room.mode=="waiting"
            res "游戏已经开始"
            return
        mode= if topl? then "helper_#{id}" else "player"
        room.players.forEach (x,i)=>
            if x.realid==userid
                query={$set:{}}
                query.$set["players.#{i}.mode"]=mode
                M.rooms.update {id:roomid},query, (err)=>
                    if err?
                        res "错误:#{err}"
                    else
                        res null
                        # 帮手の様子を 知らせる
                        if pl.mode!=mode
                            # 新しくなった
                            Server.game.game.helperlog room,pl,topl
                            ss.publish.channel "room#{roomid}", "mode", {userid:x.userid,mode:mode}

module.exports.actions=(req,res,ss)->
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
            result.players.forEach (p)->
                delete p.realid
                delete p.ip
            # ふるいかどうか
            if result.made < Date.now()-Config.rooms.fresh*3600000
                result.old=true
            res result

    # 成功: {id: roomid}
    # 失敗: {error: ""}
    newRoom: (query)->
        unless req.session.userId
            res {error: "没有登陆"}
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
            M.rooms.insert room
            Server.game.game.newGame room,ss
            res {id: room.id}
            Server.oauth.template room.id,"「#{room.name}」（房间号：#{room.id} #{if room.password then '・有密码' else ''}#{if room.blind then '・假面模式' else ''}#{if room.gm then '・有GM' else ''}）建成了。 #月下人狼",Config.admin.password

    # 部屋に入る
    # 成功ならnull 失敗なら错误メッセージ
    join: (roomid,opt)->
        unless req.session.userId
            res {error:"请登陆",require:"login"}    # ログインが必要
            return
        M.blacklist.findOne {$or:[{userid:req.session.userId},{ip:req.session.user.ip}]},(err,doc)=>
            if doc?
                if !doc.expires || doc.expires.getTime()>=Date.now()
                    res error:"被禁止参与游戏"
                    return
            
            Server.game.rooms.oneRoomS roomid,(room)=>
                if !room || room.error?
                    res error:"这个房间不存在"
                    return
                if req.session.userId in (room.players.map (x)->x.realid)
                    res error:"立刻加入"
                    return
                if opt.name in (room.players.map (x)->x.name)
                    res error:"昵称 #{opt.name} 已经存在"
                    return
                if room.gm && room.owner.userid==req.session.userId
                    res error:"GM不能加入游戏"
                    return
                unless room.mode=="waiting" || (room.mode=="playing" && room.jobrule=="特殊规则.Endless黑暗火锅")
                    res error:"放弃加入游戏"
                    return
                if room.mode=="waiting" && room.players.length >= room.number
                    # 満員
                    res error:"房间已满"
                    return
                if room.mode=="playing" && room.jobrule=="特殊规则.Endless黑暗火锅"
                    # Endless黑暗火锅の場合はゲーム内人数による人数判定を行う
                    if Server.game.game.endlessPlayersNumber(roomid) >= room.number
                        # 満員
                        res error:"房间已满"
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
                
                if room.blind
                    unless opt?.name
                        res error:"请输入昵称"
                        return
                    # 假面模式
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
                M.rooms.update {id:roomid},{$push: {players:user}},(err)=>
                    if err?
                        res error:"错误:#{err}"
                    else
                        res null
                        # 入室通知
                        delete user.ip
                        Server.game.game.inlog room,user
                        if room.mode!="playing"
                            ss.publish.channel "room#{roomid}", "join", user
    # 部屋から出る
    unjoin: (roomid)->
        unless req.session.userId
            res "请登陆"
            return
        Server.game.rooms.oneRoomS roomid,(room)=>
            if !room || room.error?
                res "这个房间不存在"
                return
            pl = room.players.filter((x)->x.realid==req.session.userId)[0]
            unless pl
                res "尚未加入游戏"
                return
            if pl.mode=="gm"
                res "GM不能退出房间"
                return
            unless room.mode=="waiting"
                res "游戏已经开始"
                return
            #room.players=room.players.filter (x)=>x!=req.session.userId
            M.rooms.update {id:roomid},{$pull: {players:{realid:req.session.userId}}},(err)=>
                if err?
                    res "错误:#{err}"
                else
                    res null
                    # 退室通知
                    user=room.players.filter((x)=>x.realid==req.session.userId)[0]
                    room.players=room.players.filter (x)->x.realid!=req.session.userId
                    Server.game.game.outlog room,user ? req.session.user
                    ss.publish.channel "room#{roomid}", "unjoin", user?.userid
                    # 帮手さがす
                    query={$set:{}}
                    for pl,i in room.players
                        if pl.mode=="helper_#{user.userid}"
                            sethelper ss,roomid,pl.realid,null,(->)

                            if pl.start
                                # unreadyクエリも投げてあげる
                                query.$set["players.#{i}.start"]=false
                                ss.publish.channel "room#{roomid}", "ready", {userid:pl.userid,start:false}
                    if Object.keys(query.$set).length>0
                        M.rooms.update {id:roomid},query


    ready:(roomid)->
        # 準備ができたか？
        console.log req.session.userId
        unless req.session.userId
            res "请登陆"
            return
        Server.game.rooms.oneRoomS roomid,(room)=>
            if !room || room.error?
                res "这个房间不存在"
                return
            unless req.session.userId in (room.players.map (x)->x.realid)
                res "尚未加入游戏"
                return
            unless room.mode=="waiting"
                res "游戏已经开始"
                return
            room.players.forEach (x,i)=>
                if x.realid==req.session.userId
                    query={$set:{}}
                    query.$set["players.#{i}.start"]=!x.start
                    M.rooms.update {id:roomid},query, (err)=>
                        if err?
                            res "错误:#{err}"
                        else
                            res null
                            # ready? 知らせる
                            ss.publish.channel "room#{roomid}", "ready", {userid:x.userid,start:!x.start}

    # 部屋から追い出す
    kick:(roomid,id)->
        unless req.session.userId
            res "请登陆"
            return
        Server.game.rooms.oneRoomS roomid,(room)=>
            if !room || room.error?
                res "这个房间不存在"
                return
            if room.owner.userid != req.session.userId
                res "不能将房主踢出游戏"
                console.log room.owner,req.session.userId
                return
            unless room.mode=="waiting"
                res "游戏已经开始"
                return
            pl=room.players.filter((x)->x.userid==id)[0]
            unless pl
                res "这个玩家没有加入游戏"
                return
            if pl.mode=="gm"
                res "GM无法被踢出游戏"
                return
            M.rooms.update {id:roomid},{$pull: {players:{userid:id}}},(err)=>
                if err?
                    res "错误:#{err}"
                else
                    res null
                    # 退室通知
                    user=room.players.filter((x)=>x.userid==id)[0]
                    if user?
                        Server.game.game.kicklog room,user
                        ss.publish.channel "room#{roomid}", "unjoin",id
                        ss.publish.user id,"refresh",{id:roomid}
                        # 帮手さがす
                        query={$set:{}}
                        for pl,i in room.players
                            if pl.mode=="helper_#{user.userid}"
                                sethelper ss,roomid,pl.realid,null,->
                                if pl.start
                                    # unreadyクエリも投げてあげる
                                    query.$set["players.#{i}.start"]=false
                                    ss.publish.channel "room#{roomid}", "ready", {userid:pl.userid,start:false}
                        if Object.keys(query.$set).length>0
                            M.rooms.update {id:roomid},query
    # 帮手になる
    helper:(roomid,id)->
        unless req.session.userId
            res "请登陆"
            return
        sethelper ss,roomid,req.session.userId,id,res
    # 全員ready解除する
    unreadyall:(roomid,id)->
        unless req.session.userId
            res "请登陆"
            return
        Server.game.rooms.oneRoomS roomid,(room)=>
            if !room || room.error?
                res "这个房间不存在"
                return
            if room.owner.userid != req.session.userId
                res "不能将房主踢出游戏"
                console.log room.owner,req.session.userId
                return
            unless room.mode=="waiting"
                res "游戏已经开始"
                return
            query={$set:{}}
            for x,i in room.players
                if x.start
                    query.$set["players.#{i}.start"]=false
            M.rooms.update {id:roomid},query,(err)=>
                if err?
                    res "错误:#{err}"
                else
                    res null
                    # readyを初期化する系
                    ss.publish.channel "room#{roomid}", "unreadyall",id
    
    
    # 成功ならjoined 失敗なら错误メッセージ
    # 部屋房间に入る
    enter: (roomid,password)->
        #unless req.session.userId
        #   res {error:"请登陆"}
        #   return
        Server.game.rooms.oneRoomS roomid,(room)=>
            if !room?
                res {error:"这个房间不存在"}
                return
            if room.error?
                res {error:room.error}
                return
            # 古い部屋なら密码いらない
            od=Date.now()-Config.rooms.fresh*3600000
            if room.password? && room.mode!="end" && room.made>od && room.password!=password && password!=Config.admin.password
                res {require:"password"}
                return
            req.session.channel.reset()

            req.session.channel.subscribe "room#{roomid}"
            Server.game.game.playerchannel roomid,req.session
            res {joined:room.players.some((x)=>x.realid==req.session.userId)}
    
    # 成功ならnull 失敗なら错误メッセージ
    # 部屋房间から出る
    exit: (roomid)->
        #unless req.session.userId
        #   res "请登陆"
        #   return
        #       req.session.channel.unsubscribe "room#{roomid}"
        req.session.channel.reset()
        res null
    # 部屋を削除
    del: (roomid)->
        unless req.session.userId
            res "请登陆"
            return
        Server.game.rooms.oneRoomS roomid,(room)=>
            if !room || room.error?
                res "这个房间不存在"
                return
            if !room.old && room.owner.userid != req.session.userId
                res "除了房主无法删除房间"
                return
            unless room.mode=="waiting"
                res "游戏已经开始"
                return
            M.rooms.update {id:roomid},{$set: {mode:"end"}},(err)=>
                if err?
                    res "错误:#{err}"
                else
                    res null
                    Server.game.game.deletedlog room
                    
    # 部屋探し
    find:(query,page)->
        unless query?
            res {error:"检索无效"}
            return
        res {error:"现在无法使用检索。"}
        return
        q=
            finished:true
        if query.result_team
            q.winner=query.result_team  # 胜利阵营
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
        console.log q
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
            

#res: (err)->
setRoom=(roomid,room)->
    M.rooms.update {id:roomid},room,res
