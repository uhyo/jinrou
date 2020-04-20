# logging feature
db = require './db'

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

# both accept "logging: true" and "logging: { enabled: true }"
isLogEnabled = Config.logging == true || !!Config.logging?.enabled
logCollection = undefined

saveInLogs = (log)->
    time = new Date log.timestamp
    # for easier log rotation, log collection name changes every month
    collName = if Config.logging?.rotate
        "logs_#{time.getFullYear()}_#{time.getMonth()+1}"
    else
        "logs"

    if !logCollection || logCollection.name != collName
        logCollection = {
            name: collName
            coll: new Promise (resolve, reject)->
                db.getLogCollection collName, (err, col)->
                    if err?
                        reject err
                        return
                    resolve col
        }

    logCollection.coll.then((col) -> col.insert log)


# speak in room log
exports.speakInRoom = (roomid, log, user)->
    return unless isLogEnabled
    return unless log?
    return unless user?
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
    return unless isLogEnabled
    return unless user?
    return unless log?
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
    return unless isLogEnabled
    return unless user?
    log =
        type: "login"
        userid: user.userid
        ip: user.ip
        timestamp: Date.now()

    saveInLogs log

# make room
exports.makeroom = (user, room)->
    return unless isLogEnabled
    return unless user?
    return unless room?
    log =
        type: "makeroom"
        userid: user.userid
        ip: user.ip
        roomid: room.id
        name: room.name
        comment: room.comment
        timestamp: room.made

    saveInLogs log

