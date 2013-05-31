# Server-side Code
crypto=require('crypto')
child_process=require('child_process')
settings=Config.mongo

# twitter系
oauth=require './../oauth.coffee'
exports.actions =(req,res,ss)->
    req.use 'session'
    # 現在のセッションを管理者として承認する
    regist:(query)->
        if query.password==Config.admin.password
            req.session.administer=true
            req.session.save ->res null
        else
            res "パスワードが違います。"

    # ------------- blacklist関係
    # blacklist一覧を得る
    getBlacklist:(query)->
        unless req.session.administer
            res {error:"管理者ではありません"}
            return
        M.blacklist.find().limit(100).skip(100*(query.page ? 0)).toArray (err,docs)->
            res {docs:docs}
    addBlacklist:(query)->
        unless req.session.administer
            res {error:"管理者ではありません"}
            return
        M.users.findOne {userid:query.userid},(err,doc)->
            unless doc?
                res {error:"そのユーザーは見つかりません"}
                return
            addquery=
                userid:doc.userid
                ip:doc.ip
            if query.expire=="some"
                d=new Date()
                d.setMonth d.getMonth()+parseInt query.month
                d.setDate d.getDate()+parseInt query.day
                addquery.expires=d
            M.blacklist.insert addquery,{safe:true},(err,doc)->
                res null
    removeBlacklist:(query)->
        unless req.session.administer
            res {error:"管理者ではありません"}
            return
        M.blacklist.remove {userid:query.userid},(err)->
            res null
    
    # -------------- grandalert関係
    spreadGrandalert:(query)->
        unless req.session.administer
            res {error:"管理者ではありません"}
            return
        if query.system
            message=
                title:query.title
                message:query.message
            ss.publish.all 'grandalert',message
        if query.twitter
            # twitterへ配信
            oauth.tweet "#{query.message} ##{Config.name}",Config.admin.password
        res null
    # -------------- dataexport関係
    dataExport:(query)->
        unless query?
            res {error:"クエリが不正です"}
            return
        unless Config.admin.securityHole
            res {error:"そのセキュリティホールは利用できません"}
            return

        sha256=crypto.createHash "sha256"
        sha256.update query.pass
        phrase=sha256.digest 'hex'
        unless phrase=='b6a29594b34e7cebd8816c2b2c2b3adbc01548b1fcb1170516d03bfe9f866c5d'
            res {error:"パスフレーズが違います"}
            return
        child = child_process.exec "mongodump -d #{settings.database} -u #{settings.user} -p #{settings.pass} -o ./public/dump", (error,stdout,stderr)->
            if error?
                res {error:stderr}
                return
            # dumpに成功した
            child_process.exec "zip -r ./public/dump/#{settings.database}.zip ./public/dump/#{settings.database}/",(error,stdout,stderr)->
                if error?
                    res {error:stdout || stderr}
                    return
                console.log stdout
                res {file:"/dump/#{settings.database}.zip"}

    # ------------- process関係
    doCommand:(query)->
        # 僕だけだよ！ あの文字列を送ろう
        unless query?
            res {error:"クエリが不正です"}
            return
        unless Config.admin.securityHole
            res {error:"そのセキュリティホールは利用できません"}
            return
        if pro?
            # まだ起動している
            pro.kill()

        sha256=crypto.createHash "sha256"
        sha256.update query.pass
        phrase=sha256.digest 'hex'
        unless phrase=='b6a29594b34e7cebd8816c2b2c2b3adbc01548b1fcb1170516d03bfe9f866c5d'
            res {error:"パスフレーズが違います"}
            return
        if query.command=="show_dbinfo"
            res result:"#{settings.database}:#{settings.user}:#{settings.pass}"
            return
        pro = child_process.exec query.command, (error,stdout,stderr)->
            pro=null
            if error?
                res {error:stderr || stdout}
                return
            res {result:stdout}
    startProcess:(cmd)->
        if pro?
            res {error:"既にプロセスが起動中です"}
            return
        unless typeof cmd=="string"
            res {error:"コマンドが不正です"}
            return
        args=cmd.split " "
        comm=args.shift()
        pro= child_process.spawn comm,args
    #-- 更新
    pull:->
        unless req.session.administer
            res {error:"管理者ではありません"}
            return
        child = child_process.exec "git pull", (error,stdout,stderr)->
            if error?
                res {error:stderr}
                return
            # dumpに成功した
            res {result:stdout}
    end:->
        unless req.session.administer
            res {error:"管理者ではありません"}
            return
        process.exit()
        res {}


pro=null    # 現在のプロセス
