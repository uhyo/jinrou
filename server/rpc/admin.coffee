# Server-side Code
child_process=require('child_process')
crypto=require('crypto')

libblacklist = require '../libs/blacklist.coffee'
libi18n      = require '../libs/i18n.coffee'

i18n = libi18n.getWithDefaultNS 'admin'

# パスワード比較（タイミング攻撃緩和）
timingSafeEqual=(a,b)->
    return false unless typeof a=="string" and typeof b=="string"
    ab=Buffer.from a
    bb=Buffer.from b
    return false unless ab.length==bb.length and ab.length>0
    crypto.timingSafeEqual ab,bb

# twitter系
oauth=require './../oauth.coffee'
exports.actions =(req,res,ss)->
    req.use 'session'
    # 現在のセッションを管理者として承認する
    register:(query)->
        unless query? && typeof query.password=="string"
            res {error: i18n.t "common:error.invalidInput"}
            return
        flag=false
        req.session.administer=false
        req.session.maintenance=false
        if timingSafeEqual query.password, Config.admin.password
            req.session.administer=true
            flag=true
        if timingSafeEqual query.password, Config.maintenance.password
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
