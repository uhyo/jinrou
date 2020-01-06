# Server-side Code
Shared=
    game:require '../../client/code/shared/game.coffee'
    prize:require '../../client/code/shared/prize.coffee'
Server=
    user:module.exports
    prize:require '../prize.coffee'
    oauth:require '../oauth.coffee'
    log:require '../log.coffee'
    auth:require '../auth.coffee'
mailer=require '../mailer.coffee'
crypto=require 'crypto'
url=require 'url'

libblacklist = require '../libs/blacklist.coffee'
libuserlogs  = require '../libs/userlogs.coffee'
libi18n      = require '../libs/i18n.coffee'

i18n = libi18n.getWithDefaultNS 'user'

# 内部関数的なログイン
login= (query,req,cb,ss)->
    #req.session.authenticate './session_storage/internal.coffee', query, (response)=>
    Server.auth.authenticate query,(response)=>
        if response.success
            req.session.setUserId response.userid
            #console.log "login."
            #console.log req
            response.ip=req.clientIp
            req.session.user=response
            #req.session.room=null  # 今入っている部屋
            req.session.channel.reset()
            # BAN情報を取ってくる
            libblacklist.handleLogin response.userid, response.ip, (ban)->
                if ban?.error?
                    cb {
                        error: ban.error
                    }
                    return
                forgive = false
                if ban?.forgive
                    forgive = true
                    req.session.ban = null
                else
                    req.session.ban = ban
                req.session.save (err)->
                    # お知らせ情報をとってきてあげる
                    M.news.find().sort({time:-1}).nextObject (err,doc)->
                        cb {
                            login:true
                            lastNews:doc?.time
                            banid: ban?.id
                            forgive: forgive
                        }
                    # IPアドレスを記録してあげる
                    M.users.update {"userid":response.userid},{$set:{ip:response.ip}}

                # log
                Server.log.login req.session.user
        else
            # ログイン失敗してるじゃん
            libblacklist.handleHello req.clientIp, (ban)->
                if ban?.error?
                    cb {
                        error: ban.error
                    }
                    return
                forgive = false
                if ban?.forgive
                    forgive = true
                    req.session.ban = null
                else
                    req.session.ban = ban
                req.session.save ()->
                    cb {
                        login:false
                        banid: ban?.id
                        forgive: forgive
                    }

exports.actions =(req,res,ss)->
    req.use 'user.fire.wall'
    req.use 'session'

    # 非ログインユーザー
    hello: ->
        ip = req.clientIp
        libblacklist.handleHello ip, (ban)->
            if ban?.error?
                res {
                    error: ban.error
                }
                return
            forgive = false
            if ban?.forgive
                forgive = true
                req.session.ban = null
            else
                req.session.ban = ban
            res {
                banid: ban?.id
                forgive: forgive
            }
            req.session.save ()->
# ログイン
# cb: 失敗なら真
    login: (query)->
        login query,req,res,ss

# ログアウト
    logout: ->
        #req.session.user.logout(cb)
        req.session.setUserId null
        req.session.channel.reset()
        req.session.save (err)->
            res()

# 新規登録
# cb: エラーメッセージ（成功なら偽）
    newentry: (query)->
        unless libblacklist.checkPermission "create_account", req.session.ban
            res {
                login: false
                error: i18n.t "error.newentry.banned"
            }
            return
        unless /^\w+$/.test(query.userid)
            res {
                login:false
                error: i18n.t "error.newentry.useridInvalid"
            }
            return
        unless /^[\x20-\x7e]+$/.test(query.password)
            res {
                login:false
                error: i18n.t "error.newentry.passwordInvalid"
            }
            return
        M.users.find({"userid":query.userid}).count (err,count)->
            if count>0
                res {
                    login:false
                    error: i18n.t "error.newentry.alreadyUsed"
                }
                return
            userobj = makeuserdata(query)
            M.users.insertOne userobj,{w:1},(err,records)->
                if err?
                    res {
                        login:false
                        error: String err
                    }
                    return
                login query,req,res,ss

# ユーザーデータが欲しい
    userData: (userid,password)->
        getUserOpenData userid, (err, record)->
            if err?
                res null
                return
            if !record?
                res null
                return
            libuserlogs.getUserData userid, true, record.data_open_all, (err, obj)->
                if err?
                    res null
                    return
                # データを整理
                userlog = if obj.userlog? && record.data_open_all
                    {
                        game: obj.userlog.counter?.allgamecount ? 0
                        win: obj.userlog.wincount?.all ? 0
                        lose: obj.userlog.losecount?.all ? 0
                    }
                else
                    null
                usersummary = if obj.usersummary?
                    if record.data_open_recent
                        {
                            open: true
                            days: obj.usersummary.days
                            game_total: obj.usersummary.game_total
                            win: obj.usersummary.win
                            lose: obj.usersummary.lose
                            draw: obj.usersummary.draw
                            gone: obj.usersummary.gone
                            gm: obj.usersummary.gm
                            helper: obj.usersummary.helper
                        }
                    else
                        {
                            open: false
                            days: obj.usersummary.days
                            game_total: obj.usersummary.game_total
                            gone: obj.usersummary.gone
                        }
                else
                    null

                res {
                    user: record
                    userlog: userlog
                    usersummary: usersummary
                }
    myProfile: ->
        unless req.session.userId
            res null
            return
        u=JSON.parse JSON.stringify req.session.user
        if u
            res userProfile(u, req.session.ban)
        else
            res null
    # 自分の称号一覧を取得
    getMyPrizes: ->
        unless req.session.userId
            # not logged in
            res {
                error: i18n.t "common:error.needLogin"
            }
            return
        res {
            prizes: generatePrizeDataForClient req.session.user.prize
            nowprize: req.session.user.nowprize
        }
# お知らせをとってきてもらう
    getNews:->
        M.news.find().sort({time:-1}).limit(5).toArray (err,results)->
            if err?
                res {error:err}
                return
            res results
# twitterアイコンを調べてあげる
    getTwitterIcon:(id)->
        Server.oauth.getTwitterIcon id,(url)->
            res url


# プロフィール変更 返り値=変更後 {"error":"message"}
    changeProfile: (query)->
        M.users.findOne {"userid":req.session.userId},(err,record)=>
            if err?
                res {error: String err}
                return
            if !record?
                res {error: i18n.t "error.authFail"}
                return
            unless Server.auth.check query.password, record.password, record.salt
                res {error: i18n.t "error.authFail"}
                return
            if query.name?
                if query.name==""
                    res {error: i18n.t "error.changeProfile.nameEmpty"}
                    return
                if query.name.length > Config.maxlength.user.name
                    res {error: i18n.t "error.changeProfile.nameTooLong"}
                    return

                record.name=query.name
            if query.comment?
                if query.comment.length > Config.maxlength.user.comment
                    res {error: i18n.t "error.changeProfile.commentTooLong"}
                    return

                record.comment=query.comment
            if query.icon?
                if query.icon.length > Config.maxlength.user.icon
                    res {error: i18n.t "error.changeProfile.iconTooLong"}
                    return

                record.icon=query.icon
            M.users.update {"userid":req.session.userId}, record, {safe:true},(err,count)=>
                if err?
                    res {error: String errr}
                    return
                delete record.password
                req.session.user=record
                req.session.save ->
                res userProfile(record, req.session.ban)
    sendConfirmMail:(query)->
        M.users.findOne {"userid":req.session.userId},(err,record)=>
            if err?
                res {error: String err}
                return
            if !record?
                res {error: i18n.t "error.authFail"}
                return
            unless Server.auth.check query.password, record.password, record.salt
                res {error: i18n.t "error.authFail"}
                return
            if query.mail && query.mail.length > Config.maxlength.user.mail
                res {error: i18n.t "error.confirmMail.mailAddressTooLong"}
                return
            mailer.sendConfirmMail(query,req,res,ss)
    confirmMail:(query)->
        token = query.token
        timestamp = Number query.timestamp
        # console.log query
        M.users.findOne {"mail.token":token,"mail.timestamp":timestamp},(err,doc)->
            # 有效时间：1小时
            if err?
                res {error: i18n.t "error.confirmMail.expired"}
                return
            unless doc?.mail? && Date.now() < Number(doc.mail.timestamp) + 3600*1000
                res {error: i18n.t "error.confirmMail.expired"}
                return
            strfor=doc.mail.for
            switch doc.mail.for
                when "confirm"
                    doc.mail=
                        address:doc.mail.new
                        verified:true
                when "change"
                    doc.mail=
                        address:doc.mail.new
                        verified:true
                when "remove"
                    delete doc.mail
                    # 事故をふせぐ
                    doc.mailconfirmsecurity = false
                when "reset"
                    doc.salt = doc.mail.newsalt
                    doc.password = doc.mail.newpass
                    doc.mail=
                        address:doc.mail.address
                        verified:true
                when "mailconfirmsecurity-off"
                    doc.mail=
                        address:doc.mail.address
                        verified:doc.mail.verified
                    doc.mailconfirmsecurity = false
            M.users.update {"userid":doc.userid}, doc, {safe:true},(err,count)=>
                if err?
                    res {error: String err}
                    return
                delete doc.password
                req.session.user = doc
                req.session.save ->
                    if strfor in ["confirm","change"]
                        doc.info= i18n.t "confirmMail.confirmed", {address: doc.mail.address}
                    else if strfor == "remove"
                        doc.mail=
                            address:""
                            verified:false
                        doc.info= i18n.t "confirmMail.deleted"
                    else if strfor == "reset"
                        doc.info= i18n.t "confirmMail.passwordReset"
                        doc.reset=true
                    else if strfor == "mailconfirmsecurity-off"
                        doc.info= i18n.t "confirmMail.settingChanged"
                    res doc
    resetPassword:(query)->
        unless /\w[-\w.+]*@([A-Za-z0-9][-A-Za-z0-9]+\.)+[A-Za-z]{2,14}/.test query.mail
            res {info: i18n.t "error.invalidMailAddress"}
        query.userid = query.userid.trim()
        query.mail = query.mail.trim()
        if query.newpass!=query.newpass2
            res {error: i18n.t "error.passwordInconsistent"}
            return
        M.users.findOne {"userid":query.userid,"mail.address":query.mail,"mail.verified":true},(err,record)=>
            if err?
                res {error: String err}
                return
            if !record?
                res {error: i18n.t "error.resetPassword.userNoExist"}
                return
            else
                mailer.sendResetMail(query,req,res,ss)
                return
    changePassword:(query)->
        if query.newpass!=query.newpass2
            res {error: i18n.t "error.passwordInconsistent"}
            return
        M.users.findOne {"userid":req.session.userId}, (err,record)=>
            if err?
                res {error: String err}
                return
            if !record?
                res {error: i18n.t "error.authFail"}
                return
            unless Server.auth.check query.password, record.password, record.salt
                res {error: i18n.t "error.authFail"}
                return

            if record.mailconfirmsecurity
                res {error: i18n.t "error.changePassword.locked"}
                return
            # saltを新しく生成
            newsalt = Server.auth.gensalt()
            M.users.update {"userid":req.session.userId}, {
                $set:{
                    password: Server.auth.crpassword query.newpass, newsalt
                    salt: newsalt
                }
            }, {safe:true}, (err,count)=>
                if err?
                    res {error: String err}
                    return
                res userProfile(record, req.session.ban)
    changeMailconfirmsecurity:(query)->
        M.users.findOne {"userid":req.session.userId}, (err, record)->
            if err?
                res {error: String err}
                return
            if !record?
                res {error: i18n.t "error.authFail"}
                return
            if query.mailconfirmsecurity == record.mailconfirmsecurity
                record.info = i18n.t "mailConfirmSecurity.saved"
                res userProfile(record, req.session.ban)
                return
            if query.mailconfirmsecurity == true
                # 厳しい
                if record.mail?.verified == true
                    M.users.update {"userid":req.session.userId}, {
                        $set: {mailconfirmsecurity: true}
                    }, {safe: true}, (err,count)->
                        if err?
                            res {error: String err}
                            return
                        delete record.password
                        req.session.user=record
                        req.session.save ->
                        record.mailconfirmsecurity = true
                        record.info = i18n.t "mailConfirmSecurity.saved"
                        res userProfile(record, req.session.ban)
                else
                    # メールアドレスの登録が必要
                    res {error: i18n.t "error.mailConfirmSecurity.nomail"}

            else
                # メール確認が必要
                res2 = (record) -> res userProfile(record, req.session.ban)
                mailer.sendMailconfirmsecurityMail {
                    userid: req.session.userId
                }, req, res2, ss


    usePrize: (query)->
        # 表示する称号を変える query.prize
        M.users.findOne {"userid":req.session.userId},(err,record)=>
            if err?
                res {error: String err}
                return
            if !record?
                res {error: i18n.t "error.authFail"}
                return
            if typeof query.prize?.every=="function"
                # 称号構成を得る
                comp=Shared.prize.getPrizesComposition record.prize.length
                if query.prize.every((x,i)->x.type==comp[i])
                    # 合致する
                    if query.prize.every((x)->
                        if x.type=="prize"
                            !x.value || x.value in record.prize # 持っている称号のみ
                        else
                            !x.value || x.value in Shared.prize.conjunctions
                    )
                        # 所持もOK
                        M.users.update {"userid":req.session.userId}, {$set:{nowprize:query.prize}},{safe:true},(err)=>
                            req.session.user.nowprize=query.prize
                            req.session.save ->
                                res null
                    else
                        console.log "invalid1 ",query.prize,record.prize
                        res {error: i18n.t "common:error.invalidInput"}
                else
                    console.log "invalid2",query.prize,comp
                    res {error: i18n.t "common:error.invalidInput"}
            else
                console.log "invalid3",query.prize
                res {error: i18n.t "common:error.invalidInput"}

    # 成績をくわしく見る
    getMyuserlog:->
        unless req.session.userId
            res {error: i18n.t "common:error.needLogin"}
            return
        myid=req.session.userId
        # DBから自分のやつを引っ張ってくる
        cnt = 0
        userlog = null
        usersummary = null
        next=()->
            cnt += 1
            if cnt >= 2
                res {
                    userlog: userlog
                    usersummary: usersummary
                    data_open_recent: !!req.session.user?.data_open_recent
                    data_open_all: !!req.session.user?.data_open_all
                    dataOpenBarrier: Config.user.dataOpenBarrier
                }
        M.userlogs.findOne {userid:myid},(err,doc)->
            if err?
                console.error err
                res {error: String err}
                return
            userlog = doc
            next()
        libuserlogs.getUserSummary myid, (err,doc)->
            if err?
                console.error err
                res {error: String err}
                return
            usersummary = doc
            next()
    # 戦績公開設定を変更
    changeDataOpenSetting:(query)->
        unless req.session.userId
            res {error: i18n.t "common:error.needLogin"}
            return
        mode = query.mode
        value = !!query.value

        updatequery = {}
        switch mode
            when 'recent'
                updatequery.$set = {
                    data_open_recent: value
                }
            when 'all'
                updatequery.$set = {
                    data_open_all: value
                }
            else
                res {error: i18n.t "common:error.invalidInput"}
                return
        # 対戦数をチェック
        M.userlogs.findOne {
            userid: req.session.userId
        }, {'counter.allgamecount': 1}, (err, doc)->
            if err? || !doc?
                res {error: String err}
                return
            # 30戦以上に制限
            if isNaN(doc.counter?.allgamecount) || doc.counter?.allgamecount < Config.user.dataOpenBarrier
                res {error: i18n.t "error.dataOpenSetting.history"}
                return
            M.users.update {
                userid: req.session.userId
            }, updatequery, (err, num)->
                if err?
                    res {error: String err}
                    return
                res {value: value}


    # 私をBANしてください!!!!!!!!
    requestban:(banid)->
        libblacklist.handleBanRequest banid, req.session.userId, req.clientIp, (result)->
            if result.error?
                res {error: result.error}
            else if result.forgive
                # 赦す
                res {forgive: true}
            else
                req.session.ban = result
                req.session.save ()->
                    res {banid: result.id}


exports.crpassword = Server.auth.crpassword
#ユーザーデータ作る
makeuserdata=(query)->
    salt = Server.auth.gensalt()
    {
        userid: query.userid
        password: Server.auth.crpassword(query.password, salt)
        salt: salt
        name: query.userid
        icon:"" # iconのURL
        comment: ""
        mailconfirmsecurity: false
        win:[]  # 勝ち試合
        lose:[] # 負け試合
        gone:[] # 行方不明試合
        ip:""   # IPアドレス
        prize:[]# 現在持っている称号
        ownprize:[] # 何かで与えられた称号（prizeに含まれる）
        nowprize:null   # 現在設定している肩書き
                # [{type:"prize",value:(prizeid)},{type:"conjunction",value:"が"},...]
        data_open_recent: false # 最近の戦績を公開するかどうか
        data_open_all: false # 全期間の戦績を公開するかどうか
    }

# profileに表示する用のユーザーデータをdocから作る
userProfile = (doc, ban)->
    doc.wp = unless doc.win? && doc.lose?
        "???"
    else if doc.win.length+doc.lose.length==0
        "???"
    else
        "#{(doc.win.length/(doc.win.length+doc.lose.length)*100).toPrecision(2)}%"
    # 称号は現在のもののみ文字列に変換して送る
    doc.nowprizeData =
        (doc.nowprize ? []).map((obj)->
            if obj.type == "prize"
                if obj.value?
                    Server.prize.prizeName(obj.value)
                else
                    ""
            else
                obj.value)
                    .join ""
    doc.prizeNumber = doc.prize?.length ? 0
    delete doc.prize
    if !doc.mail?
        doc.mail =
            address:""
            new:""
            verified:false
    else
        doc.mail =
            address:doc.mail.address
            new:doc.mail.new
            verified:doc.mail.verified
    # BAN info
    if ban?
        doc.ban =
            ban: true
            reason: ban.reason
            expires: ban.expires
    else
        doc.ban =
            ban: false
    # backward compatibility
    doc.mailconfirmsecurity = !!doc.mailconfirmsecurity
    return doc
# 称号の処理を行う
generatePrizeDataForClient = (prizeIds)->
    prizeIds.map (x)->{id:x,name:Server.prize.prizeName(x),phonetic:Server.prize.prizePhonetic(x) ? ""}


# 一般人に表示する用のデータを取得（身代わりくん対応）
getUserOpenData = (userid, cb)->
    if userid == "身代わりくん"
        cb null, {
            userid: "身代わりくん"
            name: i18n.t "game:common.scapegoat"
            icon: ""
            comment: ""
            data_open_all: true
            data_open_recent: true
        }
    else
        M.users.findOne {"userid": userid}, {
            fields: {
                userid: true
                name: true
                icon: true
                comment: true
                data_open_all: true
                data_open_recent: true
            }
        }, cb

