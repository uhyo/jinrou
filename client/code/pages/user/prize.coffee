prize_view = null
exports.start = ->
    papp = JinrouFront.loadPrize()
    pi18n = Index.app.getI18n()

    Promise.all([pi18n, papp]).then ([i18n, app])->
        prize_view = app.place {
            i18n: i18n
            node: $("#prize-app").get 0
            initialPrizes: []
        }
exports.end = ->
    prize_view?.unmount()
