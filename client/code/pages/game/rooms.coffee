rooms_view = null
exports.start=(query={})->
    mode = query.mode
    page = query.page || 0
    noLinks = !!query.noLinks
    if page < 0
        page = 0

    pi18n = JinrouFront.loadI18n()
        .then((i18n)-> i18n.getI18nFor())
    papp = JinrouFront.loadRoomList()
    prooms = requestRooms mode, page

    Promise.all([pi18n, papp]).then ([i18n, app])->
        rooms_view = app.place {
            i18n: i18n
            node: $("#rooms-app").get 0
            pageNumber: 10
            indexStart: page * 10 + 1
            listMode: mode ? ''
            noLinks: noLinks
            onPageMove: (dist)->
                page += dist
                if page < 0
                    page = 0
                reqRpc()
                Index.app.pushState location.pathname, {
                    page: page
                }
            getJobColor: (job)->
                jobobj = Shared.game.getjobobj job
                jobobj?.color
        }
        prooms.then (rooms)->
            rooms_view.store.setRooms rooms, page

        reqRpc = ()->
            requestRooms(mode, page).then((rooms)->
                rooms_view.store.setRooms rooms, page
            ).catch (err)->
                console.error err
                rooms_view.store.setError()

# Request rooms and return result as Promise.
requestRooms = (mode, page)->
    new Promise (resolve, reject)->
        if mode == "my"
            ss.rpc "game.rooms.getMyRooms", page, (results)->
                if results.error?
                    reject results.error
                else
                    resolve results.map (obj)->
                        # align with other query's object structure
                        # (with additional properties)
                        room = obj.room
                        room.gameinfo = {
                            job: obj.job
                            subtype: obj.subtype
                        }
                        return room
        else
            ss.rpc "game.rooms.getRooms", mode, page, resolve

exports.end = ->
  rooms_view?.unmount()
