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

