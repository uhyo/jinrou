# Server-side Code
crypto=require('crypto')
child_process=require('child_process')
settings=Config.mongo

# twitter系
oauth=require './../oauth.coffee'
exports.actions =(req,res,ss)->
    req.use 'session'
    # 現在のセッションを管理者として承認する
    register:(query)->
        flag=false
        req.session.administer=false
        req.session.maintenance=false
        if query.password==Config.admin.password
            req.session.administer=true
            flag=true
        if query.password==Config.maintenance.password
            req.session.maintenance=true
            flag=true

        unless flag
            res "管理员密码错误。"
        else
            req.session.save ->res null

    # ------------- blacklist関係
    # blacklist一览を得る
    getBlacklist:(query)->
        unless req.session.administer
            res {error:"不是管理员"}
            return
        M.blacklist.find().limit(100).skip(100*(query.page ? 0)).toArray (err,docs)->
            res {docs:docs}
    addBlacklist:(query)->
        unless req.session.administer
            res {error:"不是管理员"}
            return
        M.users.findOne {userid:query.userid},(err,doc)->
            unless doc?
                res {error:"没有发现这个用户"}
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
            res {error:"不是管理员"}
            return
        M.blacklist.remove {userid:query.userid},(err)->
            res null
    
    # -------------- grandalert関係
    spreadGrandalert:(query)->
        unless req.session.administer
            res {error:"不是管理员"}
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
            res {error:"检索无效"}
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
            res {error:"检索无效"}
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
    update:->
        unless req.session.maintenance
            res {error:"不是管理员"}
            return
        script=Config.maintenance.script ? []
        result=""
        error=false
        one=(index)->
            unless script[index]?
                # もうない
                res {result:result}
                return
            result+="> #{script[index]}\n"
            child = child_process.exec script[index], (error,stdout,stderr)->
                console.log stdout
                if error?
                    result+=stderr+"\n"
                    res {error:result}
                    return
                # 成功した
                result+=stdout+"\n"
                one index+1
        one 0
    end:->
        unless req.session.maintenance
            res {error:"不是管理员"}
            return
        process.exit()
        res {}

    # ------------- news関係
    # news一览を得る
    getNews:(query)->
        unless req.session.maintenance
            res {error:"不是管理员"}
            return
        M.news.find().limit(query.num).toArray (err,docs)->
            res {docs:docs}
    addNews:(query)->
        unless req.session.maintenance
            res {error:"不是管理员"}
            return
        addquery=
            time:new Date()
            message:query.message
        M.news.insert addquery,{safe:true},(err,doc)->
            res null

pro=null    # 現在のプロセス
