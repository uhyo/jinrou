libi18n = require '../libs/i18n.coffee'
i18n = libi18n.getWithDefaultNS 'user'
# Blacklist Database

###
# blacklist:
#   id: "blacklist id"
#   userid: ["userid", ...]
#   ip: ["ip", ...]
#   expires: Date
#   types: [...]
#   reason: "reason"
#   forgiveDate?: Date
###

BANTYPES = ["create_account", "lobby_say", "watch_say", "play"]

# ユーザーをBANに追加
exports.addBlacklist = (query, cb)->
    id = query.id
    userid = query.userid
    types = (type for type in BANTYPES when query[type] == "on")
    reason = query.reason ? ""

    unless id
        # 新規なのでIDを作成
        id = makeBanId()
    # 当該ユーザーを検索
    M.users.findOne {userid: userid}, (err, doc)->
        unless doc?
            cb {error: i18n.t "error.noSuchUser"}
            return
        updateQuery = {
            $setOnInsert: {
                id: id
            }
            $addToSet: {
                userid: userid
                ip: doc.ip
            }
            $set: {
                types: types
                reason: reason
            }
        }
        # 有効期限
        if query.expire == "some"
            d=new Date()
            d.setMonth d.getMonth()+parseInt query.month
            d.setDate d.getDate()+parseInt query.day
            updateQuery.$set.expires = d
        else
            updateQuery.$unset = {
                expires: ""
            }
        M.blacklist.update {
            id: id
        }, updateQuery, {w: 1, upsert: true}, (err)->
            if err?
                cb {error: err}
            else
                cb null

# BANのIDを作成
makeBanId = ()-> Math.random().toString(36).slice(2) + "_" + Date.now().toString(36)

# このBANを解除
exports.forgive = (id, cb)->
    M.blacklist.update {
        id: id
    }, {
        $set: {
            forgiveDate: new Date
        }
    }, {w: 1}, (err)->
        if err?
            cb {error: err}
        else
            cb null
# BANを再設定
exports.restore = (id, cb)->
    M.blacklist.update {
        id: id
    }, {
        $unset: {
            forgiveDate: 1
        }
    }, {w: 1}, (err)->
        if err?
            cb {error: err}
        else
            cb null

# ユーザーのログインをハンドル
exports.handleLogin = (userid, ip, cb)->
    # このユーザーはアク禁されているか?
    # non-forgiven document comes before forgiven document
    M.blacklist.find({
        $or: [
            {userid: userid},
            {ip: ip}
        ]
    })
        .sort([['forgiveDate', 1], ['expires', -1]])
        .limit(1)
        .next (err, doc)->
            if err?
                cb {
                    error: err
                }
                return
            unless doc?
                # アク禁ではない
                cb null
                return
            if doc.forgiveDate?
                cb {
                    forgive: true
                }
                return
            if doc.expires? && doc.expires.getTime() < Date.now()
                # 期限が過ぎている
                cb null
                return
            cb doc
            # IPアドレスで判定
            updateq = updateBanQuery userid, ip, doc
            if updateq?
                M.blacklist.update {
                    _id: doc._id
                }, updateq

# docに新しい情報を追加するクエリ
updateBanQuery = (userid, ip, doc)->
    result = {}
    flag = false
    # IDがなかったら付けてあげる
    unless doc.id?
        flag = true
        result.$set = {
            id: makeBanId()
        }
    # IPアドレス
    if Array.isArray doc.ip
        unless ip in doc.ip
            flag = true
            result.$push = {
                ip: ip
            }
    else
        if ip != doc.ip
            flag = true
            if result.$set?
                result.$set.ip = [doc.ip, ip]
            else
                result.$set = {
                    ip: [doc.ip, ip]
                }
    # ユーザーID
    if userid?
        if Array.isArray doc.userid
            unless userid in doc.userid
                flag = true
                if result.$push?
                    result.$push.userid = userid
                else
                    result.$push = {
                        userid: userid
                    }
        else
            if userid != doc.userid
                flag = true
                if result.$set?
                    result.$set.userid = [doc.userid, userid]
                else
                    result.$set = {
                        userid: [doc.userid, userid]
                    }

    if flag
        return result
    else
        return null

# 非ログインユーザーが登場
exports.handleHello = (ip, cb)->
    query = {
        ip: ip
    }
    M.blacklist.find(query)
        .sort([['forgiveDate', 1], ['expires', -1]])
        .limit(1)
        .next (err, doc)->
            if err?
                cb {
                    error: err
                }
                return
            unless doc?
                cb null
                return
            if doc.forgiveDate?
                cb {
                    forgive: true
                }
                return
            if doc.expires? && doc.expires.getTime() < Date.now()
                # 期限が過ぎている
                cb null
                return
            # アク禁されていた
            cb doc
            updateq = updateBanQuery null, ip, doc
            if updateq?
                M.blacklist.update {
                    _id: doc._id
                }, updateq
# 自分をBANしてほしいひとがきた
exports.handleBanRequest = (banid, userid, ip, cb)->
    M.blacklist.findOne {
        id: banid
    }, (err, doc)->
        if err?
            cb {error: err}
            return
        if doc?
            # BANがちゃんとあった
            if doc.forgiveDate? || (doc.expires? && doc.expires.getTime() < Date.now())
                # 解除済なので赦す
                cb {
                    forgive: true
                }
            else
                updateq = updateBanQuery userid, ip, doc
                if updateq?
                    M.blacklist.update {
                        _id: doc._id
                    }, updateq, {w: 1}, (err)->
                        if err?
                            cb {error: err}
                            return
                        cb doc
                else
                    cb doc
            return
        # 既存のBANから探す
        fq = if userid? then {
            $or: [
                {userid: userid},
                {ip: ip}
            ]
        } else {ip: ip}
        M.blacklist.findOne fq, (err, doc)->
            if err?
                cb {error: err}
                return
            if doc?
                # これに追加
                updateq = updateBanQuery userid, ip, doc
                if updateq?
                    M.blacklist.update {
                        _id: doc._id
                    }, updateq, {w: 1}, (err)->
                        if err?
                            cb {error: err}
                            return
                        cb doc
                else
                    cb doc
                return
            # 既存のBAN履歴がない
            newid = makeBanId()
            newdoc = {
                id: newid
                userid: if userid? then [userid] else []
                ip: [ip]
                types: BANTYPES
                reason: "Ban Request"
            }
            M.blacklist.insert newdoc, {w: 1}, (err)->
                if err?
                    cb {error: err}
                else
                    cb newdoc

# アクセス制限を確認
exports.checkPermission = (action, ban)->
    unless ban?
        # BANじゃないじゃん
        return true
    unless Array.isArray ban.types
        # とりあえず不可
        return false
    if action in ban.types
        return false
    return true

# ユーザーをBANに延長
exports.extendBlacklist = (query, cb)->
    userid = query.userid
    types = query.types
    reason = query.reason
    banMinutes = query.banMinutes

    # 当該ユーザーを検索
    M.users.findOne {userid: userid}, (err, doc)->
        if err?
            cb {error: err}
            return
        unless doc?
            cb {error: i18n.t "error.noSuchUser"}
            return
        updateQuery = {
            $addToSet: {
                userid: userid
                ip: doc.ip
                types: {
                    $each:types
                }
            }
            $set: {
                reason: reason
            }
        }

        M.blacklist.findOne {
            userid: userid
            forgiveDate: {$exists: false}
        }, (err, doc)->
            if err?
                cb {error: err}
                return
            # If the Target has been banning, extend the expiry.
            if doc?
                id = doc.id
                if doc.expires? && doc.expires.getTime() > Date.now()
                    d=doc.expires
                else if doc.expires?
                    d=new Date()
                if d?
                    d.setMinutes d.getMinutes()+banMinutes
                    updateQuery.$set.expires=d
            # If not, create a new blacklist line.
            else
                id = makeBanId()
                d=new Date()
                d.setMinutes d.getMinutes()+banMinutes
                updateQuery.$set.id = id
                updateQuery.$set.expires=d

            M.blacklist.update {
                id: id
            }, updateQuery, {w: 1, upsert: true}, (err)->
                if err?
                    cb {error: err}
                else
                    cb null
