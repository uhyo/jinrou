# Blacklist Database

###
# blacklist:
#   id: "blacklist id"
#   userid: ["userid", ...]
#   ip: ["ip", ...]
#   expires: Date
#   types: [...]
#   reason: "reason"
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
            cb {error: "そのユーザーは見つかりません"}
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

# ユーザーのログインをハンドル
exports.handleLogin = (userid, ip, cb)->
    # このユーザーはアク禁されているか?
    M.blacklist.findOne {
        $or: [
            {userid: userid},
            {ip: ip}
        ]
    }, (err, doc)->
        if err?
            cb {
                error: err
            }
            return
        unless doc?
            # アク禁ではない
            cb null
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
    M.blacklist.findOne query, (err, doc)->
        if err?
            cb {
                error: err
            }
            return
        unless doc?
            cb null
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
            # BANがちゃんとあったので追加
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
