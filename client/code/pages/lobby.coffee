socids=null
exports.start=->
    # ロビーに入る
    getlog=(log,channel)->
        unless(channel=="lobby" || typeof(channel) == "number")
            return
        logs = $("#logs")

        namediv=document.createElement "div"
        namediv.classList.add "name"
        if log.name?
            namediv.textContent="#{log.name}:"

        commentdiv=document.createElement "div"
        commentdiv.classList.add "comment"
        wrdv=document.createElement "div"
        wrdv.textContent=log.comment
        Index.game.game.parselognode wrdv
        commentdiv.appendChild wrdv

        if log.time?
            time=Index.util.timeFromDate new Date log.time
            time.classList.add "time"
            logs.prepend time

        $("#logs").prepend namediv, commentdiv
    appenduser=(user)->
        li=document.createElement "li"
        a=document.createElement "a"
        a.href="/user/#{user.userid}"
        a.textContent=user.name
        li.appendChild a
        li.dataset.userid=user.userid
        $("#users").append li
    deleteuser=(user)->
        $("#users li").each ->
            # this
            if @dataset.userid==user.userid
                $(@).remove()
                false
    heartbeat=->
        ss.rpc "lobby.heartbeat", ->


    ss.rpc "lobby.enter", (obj)->
        if obj.error?
            return
        users=$("#users")
        users.empty()
        console.log 'PL', obj.players
        obj.players.forEach appenduser

        obj.logs.reverse().forEach getlog
    $("#lobbyform").submit (je)->
        je.preventDefault()
        ss.rpc "lobby.say", je.target.elements["comment"].value,(result)->
            if result?.error?
                Index.util.message "エラー", result.error
        je.target.reset()
    socids=[
        Index.socket.on "log",null,getlog
        Index.socket.on "enter",null,appenduser
        Index.socket.on "bye",null,deleteuser
        Index.socket.on "lobby_heartbeat",null,heartbeat
    ]
exports.end=->
    ss.rpc "lobby.bye", ->
    Index.socket.off socid for socid in socids
