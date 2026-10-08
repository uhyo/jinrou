Shared=
    game:require '../../client/code/shared/game.coffee'


# Validate gameStart query.
# Returns null if valid.
# Otherwise returns an error object.
exports.validateGameStartQuery = (game, query)->
    rules = iterRules Shared.game.new_rules
    for rule in rules
        # TODO
        switch rule.type
            when "select"
                unless query[rule.id] in rule.values
                    return {
                        rule: rule.id
                        errorType: "invalid"
                    }
            when "checkbox"
                unless query[rule.id] in ["", rule.value]
                    return {
                        rule: rule.id
                        errorType: "invalid"
                    }
            when "time"
                # time should be parseable number.
                val = parseInt query[rule.id]
                unless Number.isInteger val
                    return {
                        rule: rule.id
                        errorType: "invalid"
                    }
                if rule.minValue? && val < rule.minValue
                    return {
                        rule: rule.id
                        errorType: "tooSmall"
                    }
            when "hidden"
                # hidden rule is for backwards compatibility.
                unless query[rule.id] == rule.value
                    return {
                        rule: rule.id
                        errorType: "invalid"
                    }
            when "integer"
                val = parseInt query[rule.id]
                unless Number.isInteger val
                    return {
                        rule: rule.id
                        errorType: "invalid"
                    }
                if rule.minValue? && val < rule.minValue
                    return {
                        rule: rule.id
                        errorType: "tooSmall"
                    }
    null

# Returns a list of jobs sorted by category.
categorySortedJobsCache = null
exports.categorySortedJobs = ()->
    if categorySortedJobsCache?
        return categorySortedJobsCache
    jobsObject = {}
    for job in Shared.game.jobs
        jobsObject[job] = true

    categorySortedJobsCache = []
    for cat, js of Shared.game.categories
        for job in js
            if jobsObject[job]
                categorySortedJobsCache.push job
    return categorySortedJobsCache


# Make a list of all rules.
iterRules = (rules)->
    result = []
    for obj in rules
        if obj.type == "group"
            result.push iterRules(obj.items)...
        else if obj.type == "item"
            result.push obj.value
    return result


# Checks whether one player is alive, specifically for judgement.
# We consider ResidualHaunting's skill.
exports.checkAliveForJudgement = (game, player)->
    if !player.dead
        return true
    hasresiduals = game.players.some (pl)->
        pl.accessByJobTypeAll("ResidualHaunting").some (p)->
            !p.dead && p.flag == player.id
    if hasresiduals
        return true
    return false

# 量子人狼(特殊规则.量子人狼)の勝敗判定.
# quantum_patterns: 生き残っている世界線の一覧.
#   世界線は { (playerid): {jobtype: String, rank: Number, dead: Boolean} }.
# players: 判定対象のプレイヤーの一覧(id と dead を見る).
# 返り値: "Werewolf" / "Human" / null(まだ決着していない).
#
# 生存者数(alives)と人狼の人数は同じ情報源(実際の生死)から数えること.
# 以前は「確実に生きている人狼」を beginturn が書いた古い @flag.dead から
# 数えていたため, 処刑された確定人狼が生存中の人狼として数えられ,
# 人狼勝利と誤判定していた(room 250799).
exports.judgeQuantumWerewolf = (quantum_patterns, players)->
    if quantum_patterns.length == 0
        # 世界が崩壊した(呼び出し側が引き分けとして扱う)
        return null

    # 人狼の人数は役職構成で決まっているので, どの世界線でも同じ.
    total_wolf = 0
    for id, value of quantum_patterns[0]
        if value.jobtype == "Werewolf"
            total_wolf++

    # どの世界線でも人狼であるプレイヤー = 確定人狼
    assured_wolf =
        alive: 0
        dead: 0
    for player in players
        is_wolf = quantum_patterns.every (world)-> world[player.id]?.jobtype == "Werewolf"
        continue unless is_wolf
        if player.dead
            assured_wolf.dead++
        else
            assured_wolf.alive++

    alives = players.filter((player)-> !player.dead).length

    if alives <= assured_wolf.alive * 2
        # 確定人狼だけで村人の半数以上を占めている
        return "Werewolf"
    else if assured_wolf.dead == total_wolf
        # 確定人狼が全滅した
        return "Human"
    # まだ確定していない
    return null


# Checks whether given player wins.
# This function should be used in `isWinner` method and propagate passed context to this method.
# Context is used for preventing infinite loops.
exports.devolveJudgement = devolveJudgement = (game, team, player, context)->
    if !context?
        context = {}
    if !context.devolveJudgement?
        context.devolveJudgement = []
    if player.id in context.devolveJudgement
        # infinite loop
        return false
    newcontext = Object.assign {}, context, {
        devolveJudgement: context.devolveJudgement.concat [player.id]
    }
    return player.isWinner(game, team, newcontext)
