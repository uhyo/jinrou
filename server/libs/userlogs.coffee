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

exports.addGameLogs = (game, cb)->
    logs = []
    timestamp = new Date
    # まずユーザーの勝敗ログ
    for pl in game.players
        subtype =
            if game.winner=="Draw"
                "draw"
            else if pl.winner
                "win"
            else
                "lose"
        log =
            userid: pl.realid
            type: DataTypes.game
            subtype: subtype
            gameid: game.id
            job: pl.originalType
            timestamp: timestamp
        logs.push log
    # 突然死ログも
    for l in game.gamelogs
        if l.event == "found" && l.flag in ["gone-day", "gone-night"]
            pl = game.getPlayer log.id
            if pl?
                log =
                    userid: pl.realid
                    type: DataTypes.gone
                    subtype: null
                    gameid: game.id
                    job: pl.originalType
                    timestamp: timestamp
                logs.push log

    M.userrawlogs.insert logs, {w: 1}, (err)->
        if cb?
            if err?
                cb err
            else
                cb null

