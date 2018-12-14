prize_view = null
exports.start = ({prizes, nowprize})->
    papp = JinrouFront.loadPrize()
    pi18n = Index.app.getI18n()

    Promise.all([pi18n, papp]).then ([i18n, app])->
        app.place({
            i18n: i18n
            node: $("#prize-app").get 0
            initialPrizes: prizes
            nowPrize: nowprize
            prizeUtil: Shared.prize
            onUsePrize: (prize)->
                query = {
                    prize: prize
                }
                new Promise (resolve)->
                    ss.rpc "user.usePrize", query, (result)->
                        resolve result?.error ? null

        }).then (v)->
            prize_view = v
exports.end = ->
    prize_view?.unmount()
