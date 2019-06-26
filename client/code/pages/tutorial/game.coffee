app = require '/app'
tutorial_view = null

exports.start = (roomid)->
    pi18n = app.getI18n()
    papp = JinrouFront.loadGameTutorial()

    Promise.all([pi18n, papp]).then ([i18n, japp])->
        tutorial_view = japp.place {
            i18n: i18n
            node: $("#tutorial-game-app").get 0
            teamColors: []
        }

exports.end = ->
    tutorial_view?.unmount()

