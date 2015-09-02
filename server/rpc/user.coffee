# Server-side Code
Shared=
    game:require '../../client/code/shared/game.coffee'
    prize:require '../../client/code/shared/prize.coffee'
Server=
    user:module.exports
    prize:require '../prize.coffee'
    oauth:require '../oauth.coffee'
crypto=require('crypto')

# 内部関数的なログイン
login= (query,req,cb,ss)->
    auth=require('./../auth.coffee')
    #req.session.authenticate './session_storage/internal.coffee', query, (response)=>
    auth.authenticate query,(response)=>
        if response.success
            req.session.setUserId response.userid
            #console.log "login."
            #console.log req
            response.ip=req.clientIp
            req.session.user=response
            #req.session.room=null  # 今入っている部屋
            req.session.channel.reset()
            req.session.save (err)->
                # お知らせ情報をとってきてあげる
                M.news.find().sort({time:-1}).nextObject (err,doc)->
                    cb {
                        login:true
                        lastNews:doc?.time
                    }
                # IPアドレスを記録してあげる
                M.users.update {"userid":response.userid},{$set:{ip:response.ip}}
        else
            cb {
                login:false
            }

exports.actions =(req,res,ss)->
    req.use 'session'

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
# cb: 错误メッセージ（成功なら偽）
    newentry: (query)->
        unless /^\w+$/.test(query.userid)
            res {
                login:false
                error:"ユーザーIDが不正です"
            }
            return
        unless /^\w+$/.test(query.password)
            res {
                login:false
                error:"密码が不正です"
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
            #unless password && record.password==SS.server.user.crpassword(password)
            #   delete record.email
            res record
    myProfile: ->
        unless req.session.userId
            res null
            return
        u=JSON.parse JSON.stringify req.session.user
        if u
            u.wp = unless u.win? && u.lose?
                "???"
            else if u.win.length+u.lose.length==0
                "???"
            else
                "#{(u.win.length/(u.win.length+u.lose.length)*100).toPrecision(2)}%"
            # 称号の処理をしてあげる
            u.prize ?= []
            u.prizenames=u.prize.map (x)->{id:x,name:Server.prize.prizeName(x),phonetic:Server.prize.prizePhonetic(x) ? "undefined"}
            delete u.prize
            res u
        else
            res null
# お知らせをとってきてもらう
    getNews:->
        M.news.find().sort({time:-1}).limit(5).toArray (err,results)->
            if err?
                res {error:err}
                return
            res results
# twitter头像を調べてあげる
    getTwitterIcon:(id)->
        Server.oauth.getTwitterIcon id,(url)->
            res url
        
                
# 配置変更 返り値=変更後 {"error":"message"}
    changeProfile: (query)->
        M.users.findOne {"userid":req.session.userId,"password":Server.user.crpassword(query.password)},(err,record)=>
            if err?
                res {error:"DB err:#{err}"}
                return
            if !record?
                res {error:"ユーザー認証に失敗しました"}
                return
            if query.name?
                if query.name==""
                    res {error:"ニックネームを入力して下さい"}
                    return
                record.name=query.name

            #max bytes of nick name
            maxLength=30
            record.name = record.name.trim()
            if record.name == ''
                res {error:"昵称不能仅为空格"}
                return
            else if record.name.replace(/[^\x00-\xFF]/g,'**').length > maxLength
                res {error:"昵称不能超过"+maxLength+"个字节。"}
                return

            if query.email?
                record.email=query.email
            if query.comment? && query.comment.length<=200
                record.comment=query.comment
            if query.icon? && query.icon.length<=300
                record.icon=query.icon
            M.users.update {"userid":req.session.userId}, record, {safe:true},(err,count)=>
                if err?
                    res {error:"配置変更に失敗しました"}
                    return
                delete record.password
                req.session.user=record
                req.session.save ->
                res record
    changePassword:(query)->
        M.users.findOne {"userid":req.session.userId,"password":Server.user.crpassword(query.password)},(err,record)=>
            if err?
                res {error:"DB err:#{err}"}
                return
            if !record?
                res {error:"ユーザー認証に失敗しました"}
                return
            if query.newpass!=query.newpass2
                res {error:"密码が一致しません"}
                return
            M.users.update {"userid":req.session.userId}, {$set:{password:Server.user.crpassword(query.newpass)}},{safe:true},(err,count)=>
                if err?
                    res {error:"配置変更に失敗しました"}
                    return
                res null
    usePrize: (query)->
        # 表示する称号を変える query.prize
        M.users.findOne {"userid":req.session.userId,"password":Server.user.crpassword(query.password)},(err,record)=>
            if err?
                res {error:"DB err:#{err}"}
                return
            if !record?
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
            res {error:"请登陆"}
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
            


#密码ハッシュ化
#   crpassword: (raw)-> raw && hashlib.sha256(raw+hashlib.md5(raw))
exports.crpassword= (raw)->
        return "" unless raw
        sha256=crypto.createHash "sha256"
        md5=crypto.createHash "md5"
        md5.update raw  # md5でハッシュ化
        sha256.update raw+md5.digest 'hex'  # sha256でさらにハッシュ化
        sha256.digest 'hex' # 结果を返す
#ユーザーデータ作る
makeuserdata=(query)->
    {
        userid: query.userid
        password: Server.user.crpassword(query.password)
        name: query.userid
        icon:"" # iconのURL
        comment: ""
        win:[]  # 勝ち試合
        lose:[] # 負け試合
        gone:[] # 行方不明試合
        ip:""   # IPアドレス
        prize:[]# 現在持っている称号
        ownprize:[] # 何かで与えられた称号（prizeに含まれる）
        nowprize:null   # 現在設定している肩書き
                # [{type:"prize",value:(prizeid)},{type:"conjunction",value:"が"},...]
    }
