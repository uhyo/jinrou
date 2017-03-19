# logging feature

###
# speaklog =
#     type: "speak"
#     roomid: number
#     logtype: "..."
#     userid: "..."
#     ip: "..."
#     name: "..."
#     comment: "..."
#     timestamp: number
#
# lobbylog =
#     type: "lobby"
#     userid: "..."
#     ip: "..."
#     name: "..."
#     comment: "..."
#     timestamp: number
#
# loginlog =
#     type: "login"
#     userid: "..."
#     ip: "..."
#     timestamp: number
#
# makeroomlog =
#     type: "makeroom"
#     userid: "..."
#     ip: "..."
#     roomid: number
#     name: "..."
#     comment: "..."
#     timestamp: number
###

saveInLogs = (log)->
    M.logs.insert log


# speak in room log
exports.speakInRoom = (roomid, log, user)->
    return unless Config.logging
    log =
        type: "speak"
        roomid: roomid
        logtype: log.mode
        userid: user.userid
        ip: user.ip
        name: user.name
        comment: log.comment
        timestamp: log.time

    saveInLogs log

# speak in lobby
exports.speakInLobby = (user, log)->
    return unless Config.logging
    log =
        type: "lobby"
        userid: user.userid
        ip: user.ip
        name: user.name
        comment: log.comment
        timestamp: log.time

    saveInLogs log

# login
exports.login = (user)->
    return unless Config.logging
    log =
        type: "login"
        userid: user.userid
        ip: user.ip
        timestamp: Date.now()

    saveInLogs log

# make room
exports.makeroom = (user, room)->
    return unless Config.logging
    log =
        type: "makeroom"
        userid: user.userid
        ip: user.ip
        roomid: room.id
        name: room.name
        comment: room.comment
        timestamp: room.made

    saveInLogs log

