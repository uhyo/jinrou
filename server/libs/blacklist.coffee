# Blacklist Database

###
# blacklist:
#   id: "blacklist id"
#   userid: "user id"
#   ip: ["ip", ...]
#   expires: Date
#   types: [...]
#   reason: "reason"
###

# ユーザーをBANに追加
exports.addBlacklist = (query, cb)->
    id = query.id
    userid = query.userid
    types = (type for type in ["create_account", "lobby_say", "watch_say", "play"] when query[type] == "on")
    reason = query.reason ? ""

    unless id
        # 新規なのでIDを作成
        id = Math.random().toString(36).slice(2) + "_" + Date.now().toString(36)
    # 当該ユーザーを検索
    M.users.findOne {userid: userid}, (err, doc)->
        unless doc?
            cb {error: "そのユーザーは見つかりません"}
            return
        updateQuery = {
            $setOnInsert: {
                id: id
                userid: userid
            }
            $addToSet: {
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
        updateq = addIpQuery ip, doc
        if updateq?
            M.blacklist.update {
                userid: doc.userid
            }, updateq

# docにIPアドレスを追加するクエリ
addIpQuery = (ip, doc)->
    if Array.isArray doc.ip
        if ip in doc.ip
            null
        else
            {
                $push: {
                    ip: ip
                }
            }
    else
        if ip == doc.ip
            null
        else
            {
                $set: {
                    ip: [doc.ip, ip]
                }
            }

# 非ログインユーザーが登場
exports.handleHello = (data, ip, cb)->
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
        updateq = addIpQuery ip, doc
        if updateq?
            M.blacklist.update {
                userid: doc.userid
            }, updateq

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
