# User raw logs database.

DataTypes =
    game: 1
    gone: 2

###
# userrawlogs:
#   userid: "userid"
#   type: DataTypes.game | DataTypes.gone
#   subtype: "win" | "lose" | "draw" | "gm" | "helper" | null
#   gameid: Number
#   job: String
#   timestamp: Date
#
# usersummary:
#   userid: "userid"
#   timestamp: Date // Date when this doc is generated
#   start_day: Date // この記録の1日目の日付
#   days: Number // 過去n日間の記録
#   game_total: Number // 期間中のゲーム数
#   win: Number // 期間中の勝利数
#   lose: Number // 期間中の敗北数
#   draw: Number // 期間中の引き分け数
#   gone: Number // 期間中の突然死数
#   gm: Number // 期間中のGM数
#   helper: Number // 期間中のヘルパー数
#   game_each: [Number] // 1日ごとの記録
#   win_each: [Number]
#   lose_each: [Number]
#   draw_each: [Number]
#   gone_each: [Number]
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
    # 参加者以外
    for pl in game.additionalParticipants
        unless pl.originalType in ["GameMaster", "Helper"]
            continue
        subtype =
            if pl.originalType == "GameMaster"
                "gm"
            else if pl.originalType == "Helper"
                "helper"
            else
                ""
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

# ユーザーのサマリーを取得
exports.getUserSummary = (userid, cb)->
    M.usersummary.findOne {
        userid: userid
    }, (err, doc)->
        if err?
            cb err, null
            return
        if doc?
            cb null, doc
            return
        # 過去30日間のデータをまとめる
        days = 30
        # 開始時刻と終了時刻を求める
        end_day = new Date
        end_day.setHours 0
        end_day.setMinutes 0
        end_day.setSeconds 0
        end_day.setMilliseconds 0
        start_day = new Date end_day
        start_day.setDate(start_day.getDate() - days)

        cur = M.userrawlogs.find {
            $and: [{
                userid: userid
            }, {
                timestamp: {$gte: start_day}
            }, {
                timestamp: {$lt: end_day}
            }]
        }, {}, {
            sort: [['timestamp', 1]]
        }
        # 集計オブジェクト
        result = {
            userid: userid
            timestamp: end_day
            start_day: start_day
            days: days
            game_total: 0
            win: 0
            lose: 0
            draw: 0
            gone: 0
            gm: 0
            helper: 0
            game_each: []
            win_each: []
            lose_each: []
            draw_each: []
            gone_each: []
        }
        sub_game = 0
        sub_win = 0
        sub_lose = 0
        sub_draw = 0
        sub_gone = 0
        sub_time = start_day.getTime()
        # 集計
        cur.each (err, doc)->
            if err?
                cb err, null
                return
            t = if doc?
                doc.timestamp.getTime()
            else
                end_day.getTime()
            # 日をすすめる
            while sub_time + 1000*60*60*24 <= t
                result.game_each.push sub_game
                result.win_each.push sub_win
                result.lose_each.push sub_lose
                result.draw_each.push sub_draw
                result.gone_each.push sub_gone
                sub_game=0
                sub_win=0
                sub_lose=0
                sub_draw=0
                sub_gone=0
                sub_time += 1000*60*60*24
            unless doc?
                # 集計終了
                M.usersummary.insert result, (err)->
                    if err?
                        cb err, null
                    else
                        cb null, result
                return

            switch doc.type
                when DataTypes.game
                    switch doc.subtype
                        when "win"
                            result.game_total += 1
                            sub_game += 1
                            result.win += 1
                            sub_win += 1
                        when "lose"
                            result.game_total += 1
                            sub_game += 1
                            result.lose += 1
                            sub_lose += 1
                        when "draw"
                            result.game_total += 1
                            sub_game += 1
                            result.draw += 1
                            sub_draw += 1
                        when "gm"
                            result.gm += 1
                        when "helper"
                            result.helper += 1
                when DataTypes.gone
                    result.gone += 1
                    sub_gone += 1


