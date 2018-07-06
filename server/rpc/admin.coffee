# Server-side Code
crypto=require('crypto')
child_process=require('child_process')
settings=Config.mongo

libblacklist = require '../libs/blacklist.coffee'
libi18n      = require '../libs/i18n.coffee'

i18n = libi18n.getWithDefaultNS 'admin'

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
            res i18n.t "error.wrongPassword"
        else
            req.session.save ->res null

    # ------------- blacklist関係
    getBlacklist:(query)->
        # blacklist一覧を得る
        unless req.session.administer
            res {error: i18n.t "error.notAdmin"}
            return
        M.blacklist.find().limit(100).skip(100*(query.page ? 0)).toArray (err,docs)->
            M.blacklist.count (err, count)->
                res {docs:docs,page:query.page ? 0,total:Math.ceil(count/100)}
    addBlacklist:(query)->
        # blacklistに新しいのを追加
        unless req.session.administer
            res {error: i18n.t "error.notAdmin"}
            return
        libblacklist.addBlacklist query, res
        # 即時反映（居れば）
        ss.publish.user query.userid, "forcereload"
    removeBlacklist:(query)->
        # blacklistを1つ解除
        unless req.session.administer
            res {error: i18n.t "error.notAdmin"}
            return
        libblacklist.forgive query.id, (err)->
            res err
    restoreBlacklist:(query)->
        # 解除されたblacklistをもどす
        unless req.session.administer
            res {error: i18n.t "error.notAdmin"}
            return
        libblacklist.restore query.id, (err)->
            res err
    # -------------- grandalert関係
    spreadGrandalert:(query)->
        unless req.session.administer
            res {error: i18n.t "error.notAdmin"}
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
            res {error: i18n.t "common:error.invalidInput"}
            return
        unless Config.admin.securityHole
            res {error: i18n.t "error.unavailable"}
            return

        sha256=crypto.createHash "sha256"
        sha256.update query.pass
        phrase=sha256.digest 'hex'
        unless phrase=='b6a29594b34e7cebd8816c2b2c2b3adbc01548b1fcb1170516d03bfe9f866c5d'
            res {error: i18n.t "error.wrongPassword"}
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
            res {error: i18n.t "common:error.invalidInput"}
            return
        unless Config.admin.securityHole
            res {error: i18n.t "error.unavailable"}
            return
        if pro?
            # まだ起動している
            pro.kill()

        sha256=crypto.createHash "sha256"
        sha256.update query.pass
        phrase=sha256.digest 'hex'
        unless phrase=='b6a29594b34e7cebd8816c2b2c2b3adbc01548b1fcb1170516d03bfe9f866c5d'
            res {error: i18n.t "error.wrongPassword"}
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
            res {error: i18n.t "error.unavailable"}
            return
        unless typeof cmd=="string"
            res {error: i18n.t "common:error.invalidInput"}
            return
        args=cmd.split " "
        comm=args.shift()
        pro= child_process.spawn comm,args
    #-- 更新
    update:->
        unless req.session.maintenance
            res {error: i18n.t "error.notAdmin"}
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
            res {error: i18n.t "error.notAdmin"}
            return
        process.exit()
        res {}

    # ------------- news関係
    # news一覧を得る
    getNews:(query)->
        unless req.session.maintenance
            res {error: i18n.t "error.notAdmin"}
            return
        M.news.find().limit(query.num).toArray (err,docs)->
            res {docs:docs}
    addNews:(query)->
        unless req.session.maintenance
            res {error: i18n.t "error.notAdmin"}
            return
        addquery=
            time:new Date()
            message:query.message
        M.news.insert addquery,{safe:true},(err,doc)->
            res null

pro=null    # 現在のプロセス
