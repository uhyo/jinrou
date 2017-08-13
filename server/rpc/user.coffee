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
                req.session.ban = ban
                req.session.save (err)->
                    # お知らせ情報をとってきてあげる
                    M.news.find().sort({time:-1}).nextObject (err,doc)->
                        cb {
                            login:true
                            lastNews:doc?.time
                            banid: ban?.id
                        }
                    # IPアドレスを記録してあげる
                    M.users.update {"userid":response.userid},{$set:{ip:response.ip}}

                # log
                Server.log.login req.session.user
        else
            # ログイン失敗してるじゃん
            libblacklist.handleHello null, ip, (ban)->
                if ban?.error?
                    cb {
                        error: ban.error
                    }
                    return
                req.session.ban = ban
                req.session.save ()->
                    cb {
                        login:false
                        banid: ban?.id
                    }

exports.actions =(req,res,ss)->
    req.use 'user.fire.wall'
    req.use 'session'

    # 非ログインユーザー
    hello: (data)->
        ip = req.clientIp
        libblacklist.handleHello data, ip, (ban)->
            if ban?.error?
                cb {
                    error: ban.error
                }
                return
            req.session.ban = ban
            res {
                banid: ban?.id
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
                error: "アクセス制限により、アカウントを作成できません。"
            }
            return
        unless /^\w+$/.test(query.userid)
            res {
                login:false
                error:"ユーザーIDが不正です"
            }
            return
        unless /^\w+$/.test(query.password)
            res {
                login:false
                error:"パスワードが不正です"
            }
            return
        M.users.find({"userid":query.userid}).count (err,count)->
            if count>0
                res {
                    login:false
                    error:"そのユーザーIDは既に使用されています"
                }
                return
            userobj = makeuserdata(query)
            M.users.insert userobj,{safe:true},(err,records)->
                if err?
                    res {
                        login:false
                        error:"DB err:#{err}"
                    }
                    return
                login query,req,res,ss
                
# ユーザーデータが欲しい
    userData: (userid,password)->
        M.users.findOne {"userid":userid},(err,record)->
            if err?
                res null
                return
            if !record?
                res null
                return
            delete record.password
            delete record.prize
            res record
    myProfile: ->
        unless req.session.userId
            res null
            return
        u=JSON.parse JSON.stringify req.session.user
        if u
            res userProfile(u)
        else
            res null
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
                res {error:"DB err:#{err}"}
                return
            if !record?
                res {error:"ユーザー認証に失敗しました"}
                return
            unless Server.auth.check query.password, record.password, record.salt
                res {error:"ユーザー認証に失敗しました"}
                return
            if query.name?
                if query.name==""
                    res {error:"ニックネームを入力して下さい"}
                    return
                if query.name.length > Config.maxlength.user.name
                    res {error:"ニックネームが長すぎます"}
                    return
                    
                record.name=query.name
            if query.comment?
                if query.comment.length > Config.maxlength.user.comment
                    res {error:"コメントが長すぎます"}
                    return

                record.comment=query.comment
            if query.icon?
                if query.icon.length > Config.maxlength.user.icon
                    res {error:"アイコンURLが長すぎます"}
                    return

                record.icon=query.icon
            M.users.update {"userid":req.session.userId}, record, {safe:true},(err,count)=>
                if err?
                    res {error:"プロフィール変更に失敗しました"}
                    return
                delete record.password
                req.session.user=record
                req.session.save ->
                res userProfile(record)
    sendConfirmMail:(query)->
        if query.mail && query.mail.length > Config.maxlength.user.mail
            res {error:"メールアドレスが長すぎます"}
            return
        mailer.sendConfirmMail(query,req,res,ss)
    confirmMail:(query)->
        token = query.token
        timestamp = Number query.timestamp
        # console.log query
        M.users.findOne {"mail.token":token,"mail.timestamp":timestamp},(err,doc)->
            # 有效时间：1小时
            if err?
                res {error:"このリンクは無効か、有効期限が切れています。"}
                return
            unless doc?.mail? && Date.now() < Number(doc.mail.timestamp) + 3600*1000
                res {error:"このリンクは無効か、有効期限が切れています。"}
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
                    res {error:"メールの認証に失敗しました。"}
                    return
                delete doc.password
                req.session.user = doc
                req.session.save ->
                    if strfor in ["confirm","change"]
                        doc.info="メールアドレス 「#{doc.mail.address}」が確認されました。"
                    else if strfor == "remove"
                        doc.mail=
                            address:""
                            verified:false
                        doc.info="メールアドレスの削除に成功しました。"
                    else if strfor == "reset"
                        doc.info="パスワードを再設定しました。新しいパスワードでログインしてください。"
                        doc.reset=true
                    else if strfor == "mailconfirmsecurity-off"
                        doc.info="設定を変更しました。"
                    res doc
    resetPassword:(query)->
        unless /\w[-\w.+]*@([A-Za-z0-9][-A-Za-z0-9]+\.)+[A-Za-z]{2,14}/.test query.mail
            res {info:"有効なメールアドレスを入力してください"}
        query.userid = query.userid.trim()
        query.mail = query.mail.trim()
        if query.newpass!=query.newpass2
            res {error:"パスワードが一致しません"}
            return
        M.users.findOne {"userid":query.userid,"mail.address":query.mail,"mail.verified":true},(err,record)=>
            if err?
                res {error:"DB err:#{err}"}
                return
            if !record?
                res {error:"ユーザーIDかメールアドレスが間違っています。"}
                return
            else
                mailer.sendResetMail(query,req,res,ss)
                return
    changePassword:(query)->
        if query.newpass!=query.newpass2
            res {error:"パスワードが一致しません"}
            return
        M.users.findOne {"userid":req.session.userId}, (err,record)=>
            if err?
                res {error:"DB err:#{err}"}
                return
            if !record?
                res {error:"ユーザー認証に失敗しました"}
                return
            unless Server.auth.check query.password, record.password, record.salt
                res {error:"ユーザー認証に失敗しました"}
                return
                
            if record.mailconfirmsecurity
                res {error:"パスワードがロックされているため、変更できません。"}
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
                    res {error:"プロフィール変更に失敗しました"}
                    return
                res userProfile(record)
    changeMailconfirmsecurity:(query)->
        M.users.findOne {"userid":req.session.userId}, (err, record)->
            if err?
                res {error:"DB err:#{err}"}
                return
            if !record?
                res {error:"ユーザー認証に失敗しました"}
                return
            if query.mailconfirmsecurity == record.mailconfirmsecurity
                record.info = "保存しました。"
                res userProfile(record)
                return
            if query.mailconfirmsecurity == true
                # 厳しい
                if record.mail?.verified == true
                    M.users.update {"userid":req.session.userId}, {
                        $set: {mailconfirmsecurity: true}
                    }, {safe: true}, (err,count)->
                        if err?
                            res {error:"DB err:#{err}"}
                            return
                        delete record.password
                        req.session.user=record
                        req.session.save ->
                        record.mailconfirmsecurity = true
                        record.info = "保存しました。"
                        res userProfile(record)
                else
                    # メールアドレスの登録が必要
                    res {error: "この設定を有効にするにはメールアドレスを登録する必要があります。"}

            else
                # メール確認が必要
                res2 = (record) -> res userProfile(record)
                mailer.sendMailconfirmsecurityMail {
                    userid: req.session.userId
                }, req, res2, ss


    usePrize: (query)->
        # 表示する称号を変える query.prize
        M.users.findOne {"userid":req.session.userId},(err,record)=>
            if err?
                res {error:"DB err:#{err}"}
                return
            if !record?
                res {error:"ユーザー認証に失敗しました"}
                return
            unless Server.auth.check query.password, record.password, record.salt
                res {error:"ユーザー認証に失敗しました"}
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
                        res {error:"肩書きが不正です"}
                else
                    console.log "invalid2",query.prize,comp
                    res {error:"肩書きが不正です"}
            else
                console.log "invalid3",query.prize
                res {error:"肩書きが不正です"}
        
# 成績をくわしく見る
    getMyuserlog:->
        unless req.session.userId
            res {error:"ログインして下さい"}
            return
        myid=req.session.userId
        # DBから自分のやつを引っ張ってくる
        results=[]
        M.userlogs.findOne {userid:myid},(err,doc)->
            if err?
                console.error err
            unless doc?
                # 戦績データがない
                res null
                return
            res doc
    
    ######
            


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
    }

# profileに表示する用のユーザーデータをdocから作る
userProfile = (doc)->
    doc.wp = unless doc.win? && doc.lose?
        "???"
    else if doc.win.length+doc.lose.length==0
        "???"
    else
        "#{(doc.win.length/(doc.win.length+doc.lose.length)*100).toPrecision(2)}%"
    # 称号の処理をしてあげる
    doc.prize ?= []
    doc.prizenames = doc.prize.map (x)->{id:x,name:Server.prize.prizeName(x),phonetic:Server.prize.prizePhonetic(x) ? null}
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
    # backward compatibility
    doc.mailconfirmsecurity = !!doc.mailconfirmsecurity
    return doc
