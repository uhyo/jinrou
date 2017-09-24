# User raw logs database.

DataTypes =
    game: 1
    gone: 2

###
# userrawlogs:
#   userid: "userid"
#   type: DataTypes.game | DataTypes.gone
#   subtype: "win" | "lose" | "draw" | null
#   gameid: Number
#   job: String
#   timestamp: Date
###

# ユーザーのログを追加
# query:
#   userid: "userid"
#   result: "win" | "lose" | "draw"
#   gameid: Number
#   job: String

exports.addGameLog = (query, cb)->
    log =
        userid: query.userid
        type: DateTypes.game
        subtype: query.result
        gameid: query.gameid
        job: query.job
        timestamp: new Date

    M.userrawlogs.insert log, {w: 1}, (err)->
        if cb?
            if err?
                cb err
            else
                cb null

# 突然死ログを追加
# query:
#   userid: "userid"
#   gameid: Number
#   job: String

exports.addGomeLog = (query, cb)->
    log =
        userid: query.userid
        type: DateTypes.gone
        subtype: null
        gameid: query.gameid
        job: query.job
        timestamp: new Date

    M.userrawlogs.insert log, {w: 1}, (err)->
        if cb?
            if err?
                cb err
            else
                cb null
