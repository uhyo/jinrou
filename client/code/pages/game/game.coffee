this_room_id=null

socket_ids=[]

this_rule=null  # ルールオブジェクトがある
enter_result=null #enter
# when set, function to reload the game.
reload_room = null

# GameStartControlのインスタンス
game_start_control = null
# GameViewのインスタンス
game_view = null


exports.start=(roomid)->
    this_rule=null
    my_player_id=null
    this_room_id=null
    # it's very bad but it's temporal!
    getjobinfo = null
    newgamebutton = null

    # ゲーム用コンポーネントを生成
    Promise.all([
        JinrouFront.loadGameView(),
        JinrouFront.loadDialog(),
        Index.app.getI18n(),
        Index.app.getApplicationConfig()
    ])
        .then(([gv, dialog, i18n, appConfig])->
            getenter=(result)->
                if result.error?
                    # エラー
                    dialog.showErrorDialog {
                        modal: true
                        message: String result.error
                    }
                    return
                else if result.require?
                    if result.require=="password"
                        #パスワード入力
                        dialog.showPromptDialog({
                            modal: true
                            title: i18n.t "game_client:room.enterPasswordDialog.title"
                            message: i18n.t "game_client:room.enterPasswordDialog.message"
                            ok: i18n.t "game_client:room.enterPasswordDialog.ok"
                            cancel: i18n.t "game_client:room.enterPasswordDialog.cancel"
                            password: true
                            autocomplete: "off"
                        }).then (pass)->
                            unless pass
                                Index.app.showUrl "/rooms"
                                return
                            ss.rpc "game.rooms.enter", roomid,pass,getenter
                            sessionStorage.roompassword = pass
                    return
                enter_result=result
                this_room_id=roomid
                ss.rpc "game.rooms.oneRoom", roomid,(room)-> initroom [gv, dialog, i18n], room
            game_view = gv.place {
                i18n: i18n
                roomid: roomid
                node: $("#game-app").get(0)
                rules: Shared.game.new_rules
                categories: Shared.game.categoryList
                reportForm: appConfig.reportForm
                shareButton: appConfig.shareButton
                teamColors: Shared.game.makeTeamColors()
                onSpeak: (query)->
                    ss.rpc "game.game.speak", roomid, query, (result)->
                        if result?
                            dialog.showErrorDialog {
                                modal: true
                                message: String result
                            }
                onRefuseRevival: ()->
                    # 蘇生辞退ボタン
                    new Promise (resolve, reject)->
                        ss.rpc "game.game.norevive", roomid, (result)->
                            if result?
                                reject result
                            else
                                resolve()
                onJobQuery:(query)->
                    # Job query
                    ss.rpc "game.game.job", roomid, query, (result)->
                        if result?.error?
                            dialog.showErrorDialog {
                                modal: true
                                message: String result.error
                            }
                        else
                            getjobinfo result
                onWillChange:(will)->
                    # User's will is updated
                    ss.rpc "game.game.will", roomid, will, (result)->
                        if result?
                            dialog.showErrorDialog {
                                modal: true
                                message: String result
                            }
                        else
                            # will is successfully updated
                            # TODO: better update function?
                            game_view.store.update {
                                roleInfo: Object.assign {
                                }, game_view.store.roleInfo, {
                                    will: will
                                }
                            }
                onReportFormSubmit:(query)->
                    query.room = roomid
                    query.userAgent = navigator.userAgent
                    ss.rpc "app.reportForm", query, (result)->
                        console.log result
                roomControlHandlers:
                    join: (user)->
                        processJoin = ->
                            ss.rpc "game.rooms.join", roomid, user, (result)->
                                if result?.require == "login"
                                    # ログインが必要
                                    dialog.showLoginDialog({
                                        modal: true
                                        login: Index.app.loginPromise
                                    }).then (loggedin)->
                                        if loggedin && Index.app.userid()
                                            processJoin()
                                else if result?.error?
                                    dialog.showErrorDialog {
                                        modal: true
                                        message: String result.error
                                    }
                                else if result?.tip?
                                    # To show player who he is.
                                    dialog.showMessageDialog {
                                        modal: false
                                        title: result.title
                                        message: String result.tip
                                        ok: i18n.t 'common:messageDialog.close'
                                    }
                                    Index.app.refresh()
                                else
                                    # succeeded to login
                                    Index.app.refresh()
                        processJoin()
                    unjoin: ()->
                        # 脱退
                        ss.rpc "game.rooms.unjoin", roomid,(result)->
                            if result?
                                dialog.showErrorDialog {
                                    modal: true
                                    message: String result
                                }
                            else
                                Index.app.refresh()
                    ready: ()->
                        ss.rpc "game.rooms.ready", roomid,(result)->
                            if result?
                                dialog.showErrorDialog {
                                    modal: true
                                    message: String result
                                }
                    helper: (idornull)->
                        ss.rpc "game.rooms.helper",roomid, idornull, (result)->
                            if result?
                                dialog.showErrorDialog {
                                    modal: true
                                    message: String result
                                }
                    openGameStart: ->
                        newgamebutton()
                    kick: (obj)->
                        id = obj.id
                        noentry = obj.noentry
                        ss.rpc "game.rooms.kick", roomid, id, noentry, (result)->
                            if result?
                                dialog.showErrorDialog {
                                    modal: true
                                    message: String result
                                }
                    kickRemove: (users)->
                        ss.rpc "game.rooms.cancelban", roomid, users, (result)->
                            if result?
                                dialog.showErrorDialog {
                                    modal: true
                                    message: String result
                                }
                    resetReady: ->
                        ss.rpc "game.rooms.unreadyall",roomid,(result)->
                            if result?
                                dialog.showErrorDialog {
                                    modal: true
                                    message: String result
                                }
                    discard: ->
                        ss.rpc "game.rooms.del", roomid,(result)->
                            if result?
                                dialog.showErrorDialog {
                                    modal: true
                                    message: String result
                                }
                    newRoom: ->
                        # Make a new room with same settings button
                        unless this_rule?
                            return
                        # ルールを保存
                        localStorage.savedRule=JSON.stringify this_rule.rule
                        # savedJobs is for backward compatibility
                        localStorage.savedJobs=JSON.stringify this_rule.jobscount
                        #Index.app.showUrl "/newroom"
                        # 新しいタブで開く
                        a=document.createElement "a"
                        a.href="/newroom"
                        a.target="_blank"
                        a.style.display = "none"
                        a.hidden = true
                        document.body.appendChild a
                        a.click()
                        document.body.removeChild a


            }
            ss.rpc "game.rooms.enter", roomid,sessionStorage.roompassword ? null,getenter
            )

    initroom=([gv, dialog, i18n], room)->
        unless room?
            # show an error that such room does not exist.
            dialog.showErrorDialog({
                modal: true
                message: i18n.t "game_client:room.roomDoesNotExist"
            }).then ()-> Index.app.showUrl "/rooms"
            return
        game_view?.store.update {
            roomName: room.name
        }
        # 今までのログを送ってもらう
        this_openjob_flag=false
        # 役職情報をもらった
        getjobinfo=(obj)->
            console.log obj,this_room_id
            return unless obj.id==this_room_id
            my_player_id=obj.playerid
            # Prepare icons of players
            player_icons = {}
            if room.mode == "waiting"
                # 開始前のユーザー一覧はroomから取得する
                console.log room.players
                for pl in room.players
                    if pl.icon
                        player_icons[pl.userid] = pl.icon
            else if obj.game?.players?
                for pl in obj.game.players
                    if pl.icon
                        player_icons[pl.id] = pl.icon
            console.log player_icons, obj.game?.players

            # Give info to the GameView component.
            game_view?.store.update {
                roleInfo:
                    if obj.jobname?
                        {
                            forms: if obj.sleeping then [] else obj.forms
                            jobname: obj.jobname
                            dead: obj.dead
                            desc: obj.desc
                            speak: obj.speak
                            will: obj.will
                            win: obj.winner
                            myteam: obj.myteam
                            quantumwerewolf_number: obj.quantumwerewolf_number
                            supporting: obj.supporting
                            wolves: obj.wolves
                            peers: obj.peers
                            madpeers: obj.madpeers
                            foxes: obj.foxes
                            nobles: obj.nobles
                            queens: obj.queens
                            spy2s: obj.spy2s
                            friends: obj.friends
                            stalking: obj.stalking
                            cultmembers: obj.cultmembers
                            vampires: obj.vampires
                            supporting: obj.supporting
                            dogOwner: obj.dogOwner
                            twins: obj.twins
                            myfans: obj.myfans
                            fanof: obj.fanof
                            ravens: obj.ravens
                            hooligans: obj.hooligans
                            draculas: obj.draculas
                            draculaBitten: obj.draculaBitten
                            absolutewolves: obj.absolutewolves
                            santaclauses: obj.santaclauses
                            listenerNumber: obj.listenerNumber
                            loreleis: obj.loreleis
                            gamblerStock: obj.gamblerStock
                            bonds: obj.bonds
                            targets: obj.targets
                            enemies: obj.enemies
                            spaceWerewolfImposters: obj.spaceWerewolfImposters
                        }
                    else
                        null
                gameInfo:
                    if obj.game?
                        {
                            day: obj.game.day
                            night: obj.game.night
                            finished: obj.game.finished
                            status: if room.mode == "waiting"
                                "waiting"
                            else if room.mode == "end" || obj.game.finished
                                "finished"
                            else
                                "playing"
                            watchspeak: obj.game.watchspeak
                        }
                    else
                        undefined
                rule:
                    if obj.game?.rule?
                        {
                            casting: obj.game.rule.jobrule
                            jobNumbers: convertToJobNumbers obj.game.jobscount
                            rules: new Map Object.entries obj.game.rule
                        }
                    else
                        undefined
                roomControls:
                    if room.mode == "waiting"
                        {
                            type: 'prelude'
                            owner: room.owner.userid == Index.app.userid()
                            joined: Boolean enter_result?.joined
                            old: room.old
                            blind: !!room.blind
                            theme: room.theme? && !!room.theme
                        }
                    else if obj.game?.finished
                        {
                            type: 'postlude'
                        }
                    else if obj.game?.rule?.jobrule == "特殊ルール.エンドレス闇鍋" && !obj.jobname?
                        # join the game button can be shown when endless
                        {
                            type: 'endless'
                            joined: false
                            blind: !!room.blind
                        }
                    else
                        null
                icons: player_icons
            }

            if game=obj.game
                if game.players
                    formplayers game.players
                    this_rule=
                        jobscount:game.jobscount
                        rule:game.rule
            if obj.openjob_flag==true && this_openjob_flag==false
                # 状況がかわったのでリフレッシュすべき
                this_openjob_flag=true
                unless obj.logs?
                    # ログをもらってない場合はもらいたい
                    reload_room()
        sentlog=(result)->
            if result.error?
                dialog.showErrorDialog {
                    modal: true
                    message: String result.error
                }
            else
                getjobinfo result
                # TODO
                game_view.runInAction ()->
                    game_view.store.logs.initializeLogs result.logs
                    if result.game.finished
                        # remove timer.
                        game_view.store.update {
                            timer: {
                                enabled: false
                                name: ''
                                target: 0
                            }
                        }
                    else
                        gettimer parseInt(result.timer),result.timer_mode if result.timer?
        reload_room = ->
            ss.rpc "game.game.getlog", roomid,sentlog
        reload_room()
        # 新しいゲーム
        newgamebutton = ->
            # GameStartControlコンポーネントを設置
            target = $("#gamestart-app").get 0
            if target.dataset.open == "open"
                # it's already open!
                return
            target.dataset.open = "open"
            Promise.all([
                Index.app.getI18n()
                JinrouFront.loadGameStartControl()
            ])
                .then(([i18n, gsc])=>
                    # casting情報を用意
                    castings = getLabeledGroupsOfJobrules()
                    game_start_control = gsc.place {
                        i18n: i18n
                        node: target
                        castings: castings
                        roles: Shared.game.jobs
                        categories: Shared.game.categoryList
                        rules: Shared.game.new_rules
                        # XXX ad-hoc!
                        initialCasting: castings[0].items[0].value
                        onStart: (query)->
                            console.log 'newquery', query
                            ss.rpc "game.game.gameStart", roomid, query, (result)->
                                if result?
                                    Promise.all([
                                        JinrouFront.loadDialog()
                                        Index.app.getI18n()
                                    ])
                                        .then ([d, i18n])->
                                            errorMessage = switch result.errorType
                                                when "invalid"
                                                    ruleName = i18n.t "rules:rule.#{result.rule}.name"
                                                    i18n.t "game_client:gamestart.error.ruleInvalid", {name: ruleName}
                                                when "tooSmall"
                                                    ruleName = i18n.t "rules:rule.#{result.rule}.name"
                                                    i18n.t "game_client:gamestart.error.ruleTooSmall", {name: ruleName}
                                                else
                                                    String result

                                            d.showMessageDialog {
                                                modal: true
                                                title: i18n.t 'common:error.error'
                                                message: errorMessage
                                                ok: i18n.t 'common:messageDialog.close'
                                            }
                                else
                                    game_start_control.store.setConsumed()
                                    game_start_control.unmount()
                    }
                    game_start_control.store.setPlayersNumber room.players.filter((x)->x.mode=="player").length
                ).catch((err)->
                    console.error err)

        $("#roomname").text room.name
        roomnumber = document.createElement 'span'
        roomnumber.classList.add 'roomname-number'
        roomnumber.textContent = "##{roomid}"
        iconlist = document.createElement 'span'
        iconlist.classList.add 'roomname-icons'
        # ルーム情報
        if room.password
            icon = document.createElement 'i'
            icon.classList.add 'fa'
            icon.classList.add 'fa-fw'
            icon.classList.add 'fa-lock'
            icon.title = i18n.t "game_client:roominfo.password"
            iconlist.appendChild icon
        if room.blind
            icon = document.createElement 'i'
            icon.classList.add 'fa'
            icon.classList.add 'fa-fw'
            icon.classList.add 'fa-user-secret'
            icon.title = i18n.t(if room.blind == 'complete' then 'game_client:roominfo.blindComplete' else 'game_client:roominfo.blind')
            iconlist.appendChild icon
        if room.theme
            icon = document.createElement 'i'
            icon.classList.add 'fa'
            icon.classList.add 'fa-fw'
            icon.classList.add 'fa-theater-masks'
            if room.themeFullName
                icon.title = i18n.t("game_client:roominfo.theme",{fullname: room.themeFullName})
            else
                icon.title = i18n.t("game_client:roominfo.themeRemoved")
            iconlist.appendChild icon
        if room.comment
            icon = document.createElement 'i'
            icon.classList.add 'fa'
            icon.classList.add 'fa-fw'
            icon.classList.add 'fa-info-circle'
            icon.title = room.comment
            iconlist.appendChild icon
        $("#roomname").append roomnumber, iconlist
        if room.mode=="waiting"
            game_view.store.resetPlayers room.players.map convertRoomPlayerToPlayerInfo

        userid=Index.app.userid()
        #========================================

        # 誰かが参加した!!!!
        socket_ids.push Index.socket.on "join","room#{roomid}",(msg,channel)->
            room.players.push msg
            forminfo()
            game_view.store.addPlayer convertRoomPlayerToPlayerInfo msg
        # 誰かが出て行った!!!
        socket_ids.push Index.socket.on "unjoin","room#{roomid}",(msg,channel)->
            room.players=room.players.filter (x)->x.userid!=msg
            forminfo()
            game_view.store.removePlayer msg
        # kickされた
        socket_ids.push Index.socket.on "kicked",null,(msg,channel)->
            if msg.id==roomid
                Index.app.refresh()
        # 準備
        socket_ids.push Index.socket.on "ready","room#{roomid}",(msg,channel)->
            for pl in room.players
                if pl.userid==msg.userid
                    pl.start=msg.start
                    game_view.store.updatePlayer msg.userid, {
                        flags: getPlayerInfoFlags msg.start, pl.mode
                    }
        socket_ids.push Index.socket.on "unreadyall","room#{roomid}",(msg,channel)->
            # TODO
            game_view.runInAction ()->
                for pl in room.players
                    if pl.start
                        pl.start=false
                        game_view.store.updatePlayer pl.userid, {
                            flags: getPlayerInfoFlags false, pl.mode
                        }
        socket_ids.push Index.socket.on "mode","room#{roomid}",(msg,channel)->
            for pl in room.players
                if pl.userid==msg.userid
                    pl.mode=msg.mode
                    forminfo()
                    game_view.store.updatePlayer msg.userid, {
                        flags: getPlayerInfoFlags pl.start, msg.mode
                    }

        # ログが流れてきた!!!
        socket_ids.push Index.socket.on "log",null,(msg,channel)->
            #if channel=="room#{roomid}" || channel.indexOf("room#{roomid}_")==0 || channel==Index.app.userid()
            if msg.roomid==roomid
                # この部屋へのログ
                getlog msg
        # 職情報を教えてもらった!!!
        socket_ids.push Index.socket.on "getjob",null,(msg,channel)->
            if channel=="room#{roomid}" || channel.indexOf("room#{roomid}_")==0 || channel==Index.app.userid()
                getjobinfo msg
        # 更新したほうがいい
        socket_ids.push Index.socket.on "refresh",null,(msg,channel)->
            if msg.id==roomid
                #Index.app.refresh()
                ss.rpc "game.rooms.enter", roomid,sessionStorage.roompassword ? null,(result)->
                    reload_room()
                ss.rpc "game.rooms.oneRoom", roomid,(r)->room=r
        # 投票フォームオープン
        socket_ids.push Index.socket.on "voteform",null,(msg,channel)->
            if channel=="room#{roomid}" || channel.indexOf("room#{roomid}_")==0 || channel==Index.app.userid()
                # TODO remove this message?
                console.log "voteform", msg
        # 残り時間
        socket_ids.push Index.socket.on "time",null,(msg,channel)->
            if channel=="room#{roomid}" || channel.indexOf("room#{roomid}_")==0 || channel==Index.app.userid()
                gettimer parseInt(msg.time),msg.mode

        # show TO BAN list to players
        socket_ids.push Index.socket.on 'punishalert',null,(msg,channel)->
            if msg.id==roomid && my_player_id? && (my_player_id in msg.voters)
                dialog.showSuddenDeathPunishDialog({
                    time: msg.time
                    options: msg.userlist.map (user)-> {
                        id: user.userid
                        label: user.name
                    }
                }).then (banIDs)->
                    unless banIDs?
                        return
                    ss.rpc "game.rooms.suddenDeathPunish", roomid, banIDs, (result)->
                        if result?
                            if result.error?
                                dialog.showErrorDialog {
                                    modal: true
                                    message: String result.error
                                }
                                return
                            console.log result
                            return
        # show result. reported as disturbing, so only show result in console.
        socket_ids.push Index.socket.on 'punishresult',null,(msg,channel)->
            if msg.id==roomid
                # Index.util.message "突然死の罰",msg.name+" は突然死のために部屋に参加できなくなった。"
                console.log "room:",msg.id,msg
        # プレイヤー一覧の情報を開始フォームに反映
        forminfo=()->
            # TODO: same logic appears twice
            number = room.players.filter((x)->x.mode=="player").length
            game_start_control?.store.setPlayersNumber number

    #ログをもらった
    getlog=(log)->
        game_view?.store.addLog log

    formplayers=(players)-> #jobflg: 1:生存の人 2:死人
        game_view?.store.resetPlayers players.map convertGamePlayerToPlayerInfo

    # タイマー情報をもらった
    gettimer=(msg,mode)->
        remain_time=parseInt msg
        # for new frontend
        game_view?.store.update {
            timer: {
                enabled: true
                name: mode
                target: Date.now() + remain_time * 1000
            }
        }



exports.end=->
    # unmount react components.
    game_start_control?.unmount()
    game_view?.unmount()

    ss.rpc "game.rooms.exit", this_room_id,(result)->
        if result?
            # error
            console.error result
            return
    alloff socket_ids...
    document.body.classList.remove x for x in ["day","night","finished","heaven"]

exports.reconnect=->
    if reload_room?
        console.log "reloading"
        reload_room()

#ソケットを全部off
alloff= (ids...)->
    ids.forEach (x)->
        Index.socket.off x

# ノードのコメントなどをパースする
exports.parselognode=parselognode=(node)->
    if node.nodeType==Node.TEXT_NODE
        # text node
        return unless node.parentNode
        result=document.createDocumentFragment()
        while v=node.nodeValue
            if res=v.match /^(.*?)(https?:\/\/)([^\s\/]+)(\/\S*)?/
                res[4] ?= ""
                if res[1]
                    # 前の部分
                    node=node.splitText res[1].length
                    parselognode node.previousSibling
                url = res[2]+res[3]+res[4]
                a=document.createElement "a"
                a.href=url

                if res[3]==location.host && (res2=res[4].match /^\/room\/(\d+)$/)
                    a.textContent="##{res2[1]}"
                else if res[4] in ["","/"] && res[3].length<20
                    a.textContent="#{res[2]}#{res[3]}/"
                else if res[3].length+res[4].length<60
                    a.textContent=res[2]+res[3]+res[4]
                else if res[3].length<40
                    a.textContent="#{res[2]}#{res[3]}#{res[4].slice(0,10)}...#{res[4].slice(-10)}"
                else
                    a.textContent="#{res[2]}#{res[3].slice(0,30)}...#{(res[3]+res[4]).slice(-30)}"
                a.target="_blank"
                node=node.splitText url.length
                node.parentNode.replaceChild a,node.previousSibling
                continue

            if res=v.match /^(.*?)#(\d+)/
                if res[1]
                    # 前の部分
                    node=node.splitText res[1].length
                    parselognode node.previousSibling
                a=document.createElement "a"
                a.href="/room/#{res[2]}"
                a.textContent="##{res[2]}"
                node=node.splitText res[2].length+1 # その部分どける
                node.parentNode.replaceChild a,node.previousSibling
                continue
            node.nodeValue=v.replace /(\w{30})(?=\w)/g,"$1\u200b"

            break
    else if node.childNodes
        for ch in node.childNodes
            if ch.parentNode== node
                parselognode ch

# Shared.game.jobrulesをLabeledGroup<CastingDefinition>に変換
getLabeledGroupsOfJobrules = ()->
    f = (arr, prefix)->
        result =
            for obj in arr
                if Array.isArray obj.rule
                    {
                        type: 'group'
                        label: [prefix..., obj.name].join '.'
                        items: f obj.rule, [prefix..., obj.name]
                    }
                else
                    {
                        type: 'item'
                        value:
                            id: [prefix..., obj.name].join '.'
                            roleSelect: false
                            preset: obj.rule
                            suggestedOptions: convertSuggestedOption obj.suggestedOption
                            suggestedPlayersNumber:
                                if obj.minNumber?
                                    {
                                        min: obj.minNumber
                                    }
                                else
                                    undefined

                    }
        return result
    res = f Shared.game.jobrules, []
    # 特殊配役を追加
    res.push {
        type: 'group'
        label: '特殊ルール'
        items: [
            {
                type: 'item'
                value:
                    id: '特殊ルール.自由配役'
                    roleSelect: true
            }
            {
                type: 'item'
                value:
                    id: '特殊ルール.闇鍋'
                    roleSelect: false
                    noShow: true
            }
            {
                type: 'item'
                value:
                    id: '特殊ルール.一部闇鍋'
                    roleSelect: true
                    roleExclusion: true
                    noFill: true
                    category: true
            }
            {
                type: 'item'
                value:
                    id: '特殊ルール.easyYaminabe'
                    roleSelect: false
                    preset: Shared.game.normal1
            }
            {
                type: 'item'
                value:
                    id: '特殊ルール.量子人狼'
                    roleSelect: false
                    preset: Shared.game.getrulefunc "内部利用.量子人狼"
                    suggestedOptions:
                        night:
                            type: 'range'
                            max: 60
                        scapegoat:
                            type: 'string'
                            value: 'off'
                            must: true
            }
            {
                type: 'item'
                value:
                    id: '特殊ルール.エンドレス闇鍋'
                    roleSelect: false
                    noShow: true
            }
        ]
    }
    res
# Convert suggestedOption to OptionSuggestion.
convertSuggestedOption = (obj)->
    result = {}
    for key, value of obj
        if 'string' == typeof value
            result[key] =
                type: 'string'
                value: value
        else
            result[key] = value
    return result
# Convert jobsCount from server to jobNumbers.
# Namely remove role name info.
convertToJobNumbers = (obj) ->
    result = {}
    for key, value of obj
        result[key] = obj[key].number
    result
# Convert game.players to PlayerInfo
convertGamePlayerToPlayerInfo = (pl) ->
    {
        id: pl.id
        realid: pl.realid || null
        anonymous: !pl.realid
        name: pl.name
        dead: pl.dead
        icon: pl.icon || null
        winner: pl.winner
        jobname: pl.originalJobname
        flags: if pl.norevive then ['norevive'] else []
    }
# Convert room.players to PlayerInfo
convertRoomPlayerToPlayerInfo = (pl) ->
    {
        id: pl.userid
        realid: pl.realid || null
        anonymous: !pl.realid
        name: pl.name
        dead: false
        icon: pl.icon || null
        winner: null
        jobname: null
        flags: getPlayerInfoFlags pl.start, pl.mode
    }
# get flags from ready and mode.
getPlayerInfoFlags = (ready, mode) ->
    flags = []
    if mode == 'gm'
        flags.push 'gm'
    else if /^helper_/.test mode
        flags.push 'helper'
    if ready
        flags.push 'ready'
    flags
