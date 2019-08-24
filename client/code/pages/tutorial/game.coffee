app = require '/app'
tutorial_view = null

exports.start = (roomid)->
    pi18n = app.getI18n()
    papp = JinrouFront.loadGameTutorial()

    Promise.all([pi18n, papp]).then(([i18n, japp])->
        japp.place {
            i18n: i18n
            node: $("#tutorial-game-app").get 0
            teamColors: Shared.game.makeTeamColors()
            getUserProfile:->
                new Promise (resolve)->
                    ss.rpc "user.myProfile", (res)->
                        unless res.icon
                            res.icon = null
                        resolve res
        })
    .then (v)->
        tutorial_view = v

exports.end = ->
    tutorial_view?.unmount()

