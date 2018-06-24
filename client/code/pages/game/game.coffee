
this_room_id=null

socket_ids=[]
my_job=null

timerid=null    # setTimeout
remain_time=null
this_rule=null  # ルールオブジェクトがある
enter_result=null #enter

this_icons={}   #名前とアイコンの対応表
this_icons_cache = {} # cache object for urls in this_icons
this_logdata={} # ログデータをアレする
this_style=null #style要素（終わったら消したい）
# GameStartControlのインスタンス
game_start_control = null
# GameViewのインスタンス
game_view = null


exports.start=(roomid)->
    this_rule=null
    timerid=null
    remain_time=null
    my_job=null
    my_player_id=null
    this_room_id=null
    # it's very bad but it's temporal!
    getjobinfo = null


    # CSS操作
    this_style=document.createElement "style"
    document.head.appendChild this_style
    sheet=this_style.sheet
    #現在のルール
    myrules=
        player:null # プレイヤー・ネーム
        day:"all"   # 表示する日にち
    setcss=->
        while sheet.cssRules.length>0
            sheet.deleteRule 0
        if myrules.player?
            sheet.insertRule "#logs > div:not([data-name=\"#{myrules.player}\"]) {opacity: .5}",0
        day=null
        if myrules.day=="today"
            day=this_logdata.day    # 現在
        else if myrules.day!="all"
            day=parseInt myrules.day    # 表示したい日

        if day?
            # 表示する
            sheet.insertRule "#logs > div:not([data-day=\"#{day}\"]){display: none}",0

    # ゲーム用コンポーネントを生成
    Promise.all([
        JinrouFront.loadGameView(),
        Index.app.getI18n()
    ])
        .then(([gv, i18n])->
            game_view = gv.place {
                i18n: i18n
                node: $("#game-app").get(0)
                roles: Shared.game.jobs
                rules: Shared.game.new_rules
                onSpeak: (query)->
                    ss.rpc "game.game.speak", roomid, query, (result)->
                        if result?
                            # TODO
                            Index.util.message "エラー", result
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
                        # TODO
                        if result?.error?
                            Index.util.message "エラー",result.error
                        else
                            getjobinfo result
                onWillChange:(will)->
                    # User's will is updated
                    ss.rpc "game.game.will", roomid, will, (result)->
                        # TODO
                        if result?
                            Index.util.message "エラー", result
                        else
                            # will is successfully updated
                            # TODO: better update function?
                            game_view.store.update {
                                roleInfo: Object.assign {
                                }, game_view.store.roleInfo, {
                                    will: will
                                }
                            }

            }
            ss.rpc "game.rooms.enter", roomid,sessionStorage.roompassword ? null,getenter
            )

    getenter=(result)->
        if result.error?
            # エラー
            Index.util.message "ルーム",result.error
            return
        else if result.require?
            if result.require=="password"
                #パスワード入力
                Index.util.prompt "ルーム","パスワードを入力してください",{type:"password"},(pass)->
                    unless pass?
                        Index.app.showUrl "/rooms"
                        return
                    ss.rpc "game.rooms.enter", roomid,pass,getenter
                    sessionStorage.roompassword = pass
            return
        enter_result=result
        this_room_id=roomid
        ss.rpc "game.rooms.oneRoom", roomid,initroom
    initroom=(room)->
        unless room?
            Index.util.message "ルーム","そのルームは存在しません。"
            Index.app.showUrl "/rooms"
            return
        # 今までのログを送ってもらう
        this_icons={}
        this_logdata={}
        this_openjob_flag=false
        # 役職情報をもらった
        getjobinfo=(obj)->
            console.log obj,this_room_id
            return unless obj.id==this_room_id
            my_job=obj.type
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
                            forms: obj.forms
                            jobname: obj.jobname
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
                        }
                    else
                        null
                gameInfo:
                    if obj.game?
                        {
                            day: obj.game.day
                            finished: obj.game.finished
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
                icons: player_icons
            }

            $("#jobinfo").empty()
            pp=(text)->
                p=document.createElement "p"
                p.textContent=text
                p
            if obj.type
                infop=$ "<p>あなたは<b>#{obj.jobname}</b>です（</p>"
                if obj.desc
                    # 役職説明
                    for o,i in obj.desc
                        if i>0
                            infop.append "・"
                        a=$ "<a href='/manual/job/#{o.type}'>#{if obj.desc.length==1 then '詳細' else "#{o.name}の詳細"}</a>"
                        infop.append a
                    infop.append "）"


                $("#jobinfo").append infop
            if obj.myteam?
                # ケミカル人狼用の陣営情報
                if obj.myteam == ""
                    $("#jobinfo").append pp "あなたの陣営はありません"
                else
                    teamstring = Shared.game.jobinfo[obj.myteam]?.name
                    $("#jobinfo").append pp "あなたの陣営は#{teamstring}です"
            if obj.wolves?
                $("#jobinfo").append pp "仲間の人狼は#{obj.wolves.map((x)->x.name).join(",")}"
            if obj.peers?
                $("#jobinfo").append pp "共有者は#{obj.peers.map((x)->x.name).join(',')}"
            if obj.madpeers?
                $("#jobinfo").append pp "仲間の叫迷狂人は#{obj.madpeers.map((x)->x.name).join(',')}"
            if obj.foxes?
                $("#jobinfo").append pp "仲間の妖狐は#{obj.foxes.map((x)->x.name).join(',')}"
            if obj.nobles?
                $("#jobinfo").append pp "貴族は#{obj.nobles.map((x)->x.name).join(',')}"
            if obj.queens?.length>0
                $("#jobinfo").append pp "女王観戦者は#{obj.queens.map((x)->x.name).join(',')}"
            if obj.spy2s?.length>0
                $("#jobinfo").append pp "スパイⅡは#{obj.spy2s.map((x)->x.name).join(',')}"
            if obj.friends?.length>0
                $("#jobinfo").append pp "恋人は#{obj.friends.map((x)->x.name).join(',')}"
            if obj.stalking?
                $("#jobinfo").append pp "あなたは#{obj.stalking.name}のストーカーです"
            if obj.cultmembers?
                $("#jobinfo").append pp "信者は#{obj.cultmembers.map((x)->x.name).join(',')}"
            if obj.vampires?
                $("#jobinfo").append pp "ヴァンパイアは#{obj.vampires.map((x)->x.name).join(',')}"
            if obj.supporting?
                $("#jobinfo").append pp "#{obj.supporting.name}（#{obj.supportingJob}）をサポートしています"
            if obj.dogOwner?
                $("#jobinfo").append pp "あなたの飼い主は#{obj.dogOwner.name}です"
            if obj.quantumwerewolf_number?
                $("#jobinfo").append pp "あなたのプレイヤー番号は#{obj.quantumwerewolf_number}番です"
            if obj.twins?
                $("#jobinfo").append pp "双子は#{obj.twins.map((x)->x.name).join(',')}"
            if obj.myfans?
                $("#jobinfo").append pp "ファンは#{obj.myfans.map((x)->x.name).join(',')}です"
            if obj.fanof?
                $("#jobinfo").append pp "あなたは#{obj.fanof.name}のファンです"

            if obj.winner?
                # 勝敗
                $("#jobinfo").append pp "#{if obj.winner then '勝利' else '敗北'}しました"
            if obj.dead
                # 自分は既に死んでいる
                document.body.classList.add "heaven"
            else
                document.body.classList.remove "heaven"
            if obj.will
                $("#willform").get(0).elements["will"].value=obj.will

            if game=obj.game
                if game.finished
                    # 終了
                    document.body.classList.add "finished"
                    document.body.classList.remove x for x in ["day","night"]
                    $("#jobform").attr "hidden","hidden"
                    if timerid
                        clearInterval timerid
                        timerid=null
                else
                    # 昼と夜の色
                    document.body.classList.add (if game.night then "night" else "day")
                    document.body.classList.remove (if game.night then "day" else "night")

                unless $("#jobform").get(0).hidden= game.finished ||  obj.sleeping || !obj.type
                    # 代入しつつの　投票フォーム必要な場合
                    $("#jobform div.jobformarea").attr "hidden","hidden"
                    #$("#form_day").get(0).hidden= game.night || obj.sleeping || obj.type=="GameMaster"
                    $("#form_day").get(0).hidden= !obj.voteopen
                    obj.open?.forEach (x)->
                        # 開けるべきフォームが指定されている
                        $("#form_#{x}").prop "hidden",false
                    if (obj.job_selection ? []).length==0
                        # 対象選択がない・・・表示しない
                        $("#form_players").prop "hidden",true
                    else
                        $("#form_players").prop "hidden",false
                if game.players
                    formplayers game.players
                    unless this_rule?
                        $("#speakform").get(0).elements["rulebutton"].disabled=false
                        $("#speakform").get(0).elements["norevivebutton"].disabled=false
                    this_rule=
                        jobscount:game.jobscount
                        rule:game.rule
                setJobSelection obj.job_selection ? []
                select=$("#speakform").get(0).elements["mode"]
                if obj.speak && obj.speak.length>0
                    # 発言方法の選択
                    $(select).empty()
                    select.disabled=false
                    for val in obj.speak
                        option=document.createElement "option"
                        option.value=val
                        option.text=speakValueToStr game,val
                        select.add option
                    select.value=obj.speak[0]
                    select.options[0]?.selected=true
                else
                    select.disabled=true
            if obj.openjob_flag==true && this_openjob_flag==false
                # 状況がかわったのでリフレッシュすべき
                this_openjob_flag=true
                unless obj.logs?
                    # ログをもらってない場合はもらいたい
                    ss.rpc "game.game.getlog",roomid,sentlog
        sentlog=(result)->
            if result.error?
                Index.util.message "エラー",result.error
            else
                if result.game?.day>=1
                    # ゲームが始まったら消す
                    $("#playersinfo").empty()
                    #TODO: ゲームに参加ボタンが2箇所にあるぞ
                    if result.game
                        if !result.game.finished && result.game.rule.jobrule=="特殊ルール.エンドレス闇鍋" && !result.type?
                            # エンドレス闇鍋に参加可能
                            b=makebutton "ゲームに参加"
                            $("#playersinfo").append b
                            $(b).click joinbutton
                getjobinfo result
                $("#logs").empty()
                $("#chooseviewday").empty() # 何日目だけ表示
                if result.game?.finished
                    # 終了した・・・次のゲームボタン
                    b=makebutton "同じ設定で次の部屋を建てる","建てたあとも設定の変更は可能です。"
                    $("#playersinfo").append b
                    $(b).click (je)->
                        # ルールを保存
                        localStorage.savedRule=JSON.stringify result.game.rule
                        # savedJobs is for backward compatibility
                        localStorage.savedJobs=JSON.stringify result.game.jobscount
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

                # TODO
                game_view.runInAction ()->
                    game_view.store.resetLogs()
                    result.logs.forEach getlog
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

        ss.rpc "game.game.getlog", roomid,sentlog
        # 新しいゲーム
        newgamebutton = (je)->
            unless $("#gamestartsec").attr("hidden") == "hidden"
                return
            # GameStartControlコンポーネントを設置
            Promise.all([
                Index.app.getI18n()
                JinrouFront.loadGameStartControl()
            ])
                .then(([i18n, gsc])=>
                    # casting情報を用意
                    castings = getLabeledGroupsOfJobrules()
                    game_start_control = gsc.place {
                        i18n: i18n
                        node: $("#gamestart-app").get 0
                        castings: castings
                        roles: Shared.game.jobs
                        categories:
                            Object.keys(Shared.game.categories)
                                .map((key)-> {
                                    id: key
                                    roles: Shared.game.categories[key]
                                })
                        rules: Shared.game.new_rules
                        # XXX ad-hoc!
                        initialCasting: castings[0].items[0].value
                        onStart: (query)->
                            console.log 'newquery', query
                            ss.rpc "game.game.gameStart", roomid, query, (result)->
                                if result?
                                    JinrouFront
                                        .loadDialog()
                                        .then (d)->
                                            JinrouFront.loadI18n()
                                                .then((i18n)-> i18n.getI18nFor())
                                                .then (i18n)->
                                                    d.showMessageDialog {
                                                        modal: true
                                                        title: i18n.t 'common:error.error'
                                                        message: String result
                                                        ok: i18n.t 'common:messageDialog.close'
                                                    }
                                else
                                    game_start_control.unmount()
                                    $("#gamestartsec").attr "hidden", "hidden"
                    }
                    game_start_control.store.setPlayersNumber room.players.filter((x)->x.mode=="player").length
                ).catch((err)->
                    console.error err)

            $("#gamestartsec").removeAttr "hidden"

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
            icon.title = 'パスワードあり'
            iconlist.appendChild icon
        if room.blind
            icon = document.createElement 'i'
            icon.classList.add 'fa'
            icon.classList.add 'fa-fw'
            icon.classList.add 'fa-user-secret'
            icon.title = if room.blind == 'complete' then '覆面（最後まで非公開）' else '覆面（終了後に公開）'
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
            # 開始前のユーザー一覧は roomから取得する
            room.players.forEach (x)->
                li=makeplayerbox x,room.blind
                $("#players").append li

                # アイコンを取得
                if x.icon
                    this_icons[x.name] = x.icon
            # for new frontend
            game_view.store.resetPlayers room.players.map convertRoomPlayerToPlayerInfo
        # 未参加の場合は参加ボタン
        joinbutton=(je)->
            # 参加
            opt=
                name:""
                icon:null
            into=->
                ss.rpc "game.rooms.join", roomid,opt,(result)->
                    if result?.require=="login"
                        # ログインが必要
                        Index.util.loginWindow ->
                            if Index.app.userid()
                                into()
                    else if result?.error?
                        Index.util.message "ルーム",result.error
                    else
                        Index.app.refresh()


            if room.blind
                # 参加者名
                Index.util.blindName null,(obj)->
                    if obj?
                        opt.name=obj.name
                        opt.icon=obj.icon
                        into()
            else
                into()
        if (room.mode=="waiting" || room.mode=="playing" && room.jobrule=="特殊ルール.エンドレス闇鍋") && !enter_result?.joined
            # 未参加
            b=makebutton "ゲームに参加"
            $("#playersinfo").append b
            $(b).click joinbutton
        else if room.mode=="waiting" && enter_result?.joined
            # エンドレス闇鍋でも脱退はできない
            b=makebutton "ゲームから脱退"
            $("#playersinfo").append b
            $(b).click (je)->
                # 脱退
                ss.rpc "game.rooms.unjoin", roomid,(result)->
                    if result?
                        Index.util.message "ルーム",result
                    else
                        Index.app.refresh()
            if room.mode=="waiting"
                # 開始前
                b=makebutton "準備完了/準備中","全員が準備完了になるとゲームを開始できます。"
                $("#playersinfo").append b
                $(b).click (je)->
                    ss.rpc "game.rooms.ready", roomid,(result)->
                        if result?
                            Index.util.message "ルーム",result
            b=makebutton "ヘルパー","ヘルパーになると、ゲームに参加せずに助言役になります。"
            # ヘルパーになる/やめるボタン
            $(b).click (je)->
                Index.util.selectprompt {
                    title: "ヘルパー"
                    message: "誰のヘルパーになりますか?"
                    options: room.players.map((x)-> {name: x.name, value: x.userid})
                    icon: 'user'
                }, (id)->
                    ss.rpc "game.rooms.helper",roomid, id,(result)->
                        if result?
                            Index.util.message "エラー",result
            $("#playersinfo").append b


        userid=Index.app.userid()
        if room.mode=="waiting"
            if room.owner.userid==Index.app.userid()
                # オーナー用ボタン
                b=makebutton "ゲーム開始画面を開く"
                $("#playersinfo").append b
                $(b).click newgamebutton
                b=makebutton "参加者を追い出す"
                $("#playersinfo").append b
                $(b).click (je)->
                    Index.util.kickprompt {
                        options: room.players.map((x)->{name:x.name,value:x.userid})
                    }, (obj)->
                        if obj?.list
                            # list 管理
                            kicklistmanage roomid

                        else if obj?
                            id = obj.value
                            ban = obj.ban
                            console.log id, ban
                            ss.rpc "game.rooms.kick", roomid,id,ban,(result)->
                                if result?
                                    Index.util.message "エラー",result
                b=makebutton "[ready]を初期化する"
                $("#playersinfo").append b
                $(b).click (je)->
                    Index.util.ask "[ready]初期化","全員の[ready]を解除しますか?",(cb)->
                        if cb
                            ss.rpc "game.rooms.unreadyall",roomid,(result)->
                                if result?
                                    Index.util.message "エラー",result

            if room.owner.userid==Index.app.userid() || room.old
                b=makebutton "この部屋を廃村にする"
                $("#playersinfo").append b
                $(b).click (je)->
                    Index.util.ask "廃村","本当に部屋を廃村にしますか?",(cb)->
                        if cb
                            ss.rpc "game.rooms.del", roomid,(result)->
                                if result?
                                    Index.util.message "エラー",result

        speakform=$("#speakform").get 0
        speakform.elements["willbutton"].addEventListener "click", (e)->
            # 遺言フォームオープン
            wf=$("#willform").get 0
            if wf.hidden
                wf.hidden=false
                e.target.value="遺言を隠す"
            else
                wf.hidden=true
                e.target.value="遺言"
        ,false
        speakform.elements["multilinecheck"].addEventListener "click",(e)->
            # 複数行
            t=e.target
            textarea=null
            comment=t.form.elements["comment"]
            if t.checked
                # これから複数行になる
                textarea=document.createElement "textarea"
                textarea.cols=50
                textarea.rows=4
            else
                # 複数行をやめる
                textarea=document.createElement "input"
                textarea.size=50
            textarea.name="comment"
            textarea.value=comment.value
            if textarea.type=="textarea" && textarea.value
                textarea.value+="\n"
            textarea.required=true
            $(comment).replaceWith textarea
            textarea.focus()
            textarea.setSelectionRange textarea.value.length,textarea.value.length
        # 複数行ショートカット
        $(speakform).keydown (je)->
            if je.keyCode==13 && je.shiftKey && je.target.form.elements["multilinecheck"].checked==false
                # 複数行にする
                je.target.form.elements["multilinecheck"].click()

                je.preventDefault()


        # ルール表示
        $("#speakform").get(0).elements["rulebutton"].addEventListener "click", (e)->
            return unless this_rule?
            win=Index.util.blankWindow()
            win.append $ "<h1>ルール</h1>"
            p=document.createElement "p"
            jobcountobj = {}
            Object.keys(this_rule.jobscount).forEach (x)->
                a=document.createElement "a"
                a.href="/manual/job/#{x}"
                a.textContent="#{this_rule.jobscount[x].name}#{this_rule.jobscount[x].number}"
                p.appendChild a
                p.appendChild document.createTextNode " "

                jobcountobj[x] = Number this_rule.jobscount[x].number
            win.append p
            chkrule=(ruleobj,jobscount,rules)->
                for obj in rules
                    if obj.rules
                        continue unless obj.visible ruleobj,jobscount
                        chkrule ruleobj,jobscount,obj.rules
                    else
                        p=$ "<p>"
                        val=""
                        if obj.title?
                            p.attr "title",obj.title
                        if obj.type=="separator"
                            continue
                        if obj.getstr?
                            valobj=obj.getstr ruleobj[obj.name], ruleobj
                            unless valobj?
                                continue
                            val="#{valobj.label ? ''}:#{valobj.value ? ''}"
                        else
                            val="#{obj.label}:"
                            switch obj.type
                                when "checkbox"
                                    if ruleobj[obj.name]==obj.value.value
                                        unless obj.value.label?
                                            continue
                                        val+=obj.value.label
                                    else
                                        unless obj.value.nolabel?
                                            continue
                                        val+=obj.value.nolabel
                                when "select"
                                    flg=false
                                    for vobj in obj.values
                                        if ruleobj[obj.name]==vobj.value
                                            val+=vobj.label
                                            if vobj.title
                                                p.attr "title",vobj.title
                                            flg=true
                                            break
                                    unless flg
                                        continue
                                when "time"
                                    val+="#{ruleobj[obj.name.minute]}分#{ruleobj[obj.name.second]}秒"
                                when "second"
                                    val+="#{ruleobj[obj.name]}秒"
                                when "hidden"
                                    continue
                        p.text val
                        win.append p
            console.log "rule!", this_rule.rule
            chkrule this_rule.rule, jobcountobj,Shared.game.rules

        $("#willform").submit (je)->
            form=je.target
            je.preventDefault()
            ss.rpc "game.game.will", roomid,form.elements["will"].value,(result)->
                if result?
                    Index.util.message "エラー",result
                else
                    $("#willform").get(0).hidden=true
                    $("#speakform").get(0).elements["willbutton"].value="遺言"

        # 夜の仕事（あと投票）
        $("#jobform").submit (je)->
            form=je.target
            je.preventDefault()
            $("#jobform").attr "hidden","hidden"
            ss.rpc "game.game.job", roomid,Index.util.formQuery(form), (result)->
                if result?.error?
                    Index.util.message "エラー",result.error
                    $("#jobform").removeAttr "hidden"
                else if !result?.sleeping
                    # まだ仕事がある
                    $("#jobform").removeAttr "hidden"
                    getjobinfo result
                else
                    getjobinfo result
        .click (je)->
            bt=je.target
            if bt.type=="submit"
                # 送信ボタン
                bt.form.elements["commandname"].value=bt.name   # コマンド名教えてあげる
                bt.form.elements["jobtype"].value=bt.dataset.job    # 役職名も教えてあげる
        #========================================

        # 誰かが参加した!!!!
        socket_ids.push Index.socket.on "join","room#{roomid}",(msg,channel)->
            room.players.push msg
            li=makeplayerbox msg,room.blind
            $("#players").append li

            game_view.store.addPlayer convertRoomPlayerToPlayerInfo msg
            forminfo()
        # 誰かが出て行った!!!
        socket_ids.push Index.socket.on "unjoin","room#{roomid}",(msg,channel)->
            room.players=room.players.filter (x)->x.userid!=msg

            $("#players li").filter((idx)-> this.dataset.id==msg).remove()
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
                    li=$("#players li").filter((idx)-> this.dataset.id==msg.userid)
                    li.replaceWith makeplayerbox pl,room.blind
                    game_view.store.updatePlayer msg.userid, {
                        start: msg.start
                    }
        socket_ids.push Index.socket.on "unreadyall","room#{roomid}",(msg,channel)->
            # TODO
            game_view.runInAction ()->
                for pl in room.players
                    if pl.start
                        pl.start=false
                        li=$("#players li").filter((idx)-> this.dataset.id==pl.userid)
                        li.replaceWith makeplayerbox pl,room.blind
                        game_view.store.updatePlayer pl.userid, {
                            start: false
                        }
        socket_ids.push Index.socket.on "mode","room#{roomid}",(msg,channel)->
            for pl in room.players
                if pl.userid==msg.userid
                    pl.mode=msg.mode
                    li=$("#players li").filter((idx)-> this.dataset.id==msg.userid)
                    li.replaceWith makeplayerbox pl,room.blind
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
                    ss.rpc "game.game.getlog", roomid,sentlog
                ss.rpc "game.rooms.oneRoom", roomid,(r)->room=r
        # 投票フォームオープン
        socket_ids.push Index.socket.on "voteform",null,(msg,channel)->
            if channel=="room#{roomid}" || channel.indexOf("room#{roomid}_")==0 || channel==Index.app.userid()
                if msg
                    $("#jobform").removeAttr "hidden"
                else
                    $("#jobform").attr "hidden","hidden"
        # 残り時間
        socket_ids.push Index.socket.on "time",null,(msg,channel)->
            if channel=="room#{roomid}" || channel.indexOf("room#{roomid}_")==0 || channel==Index.app.userid()
                gettimer parseInt(msg.time),msg.mode

        # show TO BAN list to players
        socket_ids.push Index.socket.on 'punishalert',null,(msg,channel)->
            if msg.id==roomid && my_player_id? && msg.userlist.every((x)-> x.userid != my_player_id)
                Index.util.punish "突然死の罰",msg,(banIDs)->
                    ss.rpc "game.rooms.suddenDeathPunish", roomid,banIDs,(result)->
                        if result?
                            if result.error?
                                Index.util.message "突然死の罰",result.error
                                return
                            Index.util.message "突然死の罰",result
                            return
        # show result. reported as disturbing, so only show result in console.
        socket_ids.push Index.socket.on 'punishresult',null,(msg,channel)->
            if msg.id==roomid
                # Index.util.message "突然死の罰",msg.name+" は突然死のために部屋に参加できなくなった。"
                console.log "room:",msg.id,msg

        $(document).click (je)->
            # クリックで発言強調
            li=if je.target.tagName.toLowerCase()=="li" then je.target else $(je.target).parents("li").get 0
            myrules.player=null
            if $(li).parent("#players").length >0
                if li?
                    # 強調
                    myrules.player=li.dataset.name
            setcss()
        $("#chooseviewselect").change (je)->
            # 表示部分を選択
            v=je.target.value
            myrules.day=v
            setcss()
        .click (je)->
            je.stopPropagation()

        # プレイヤー一覧の情報を開始フォームに反映
        forminfo=()->
            number = room.players.length
            game_start_control?.store.setPlayersNumber number

    #ログをもらった
    getlog=(log)->
        game_view?.store.addLog log
        if log.mode in ["voteresult","probability_table"]
            # 表を出す
            p=document.createElement "div"
            div=document.createElement "div"
            div.classList.add "icon"
            p.appendChild div
            div=document.createElement "div"
            div.classList.add "name"
            p.appendChild div

            tb=document.createElement "table"
            if log.mode=="voteresult"
                tb.createCaption().textContent="投票結果"
                vr=log.voteresult
                tos=log.tos
                vr.forEach (player)->
                    tr=tb.insertRow(-1)
                    tr.insertCell(-1).textContent=player.name
                    tr.insertCell(-1).textContent="#{tos[player.id] ? '0'}票"
                    tr.insertCell(-1).textContent="→#{vr.filter((x)->x.id==player.voteto)[0]?.name ? ''}"
            else
                # %表示整形
                pbu=(node,num)->
                    node.textContent=(if num==1
                        "100%"
                    else
                        (num*100).toFixed(2)+"%"
                    )
                    if num==1
                        node.style.fontWeight="bold"
                    return

                tb.createCaption().textContent="確率表"
                pt=log.probability_table
                # 見出し
                tr=tb.insertRow -1
                th=document.createElement "th"
                th.textContent="名前"
                tr.appendChild th
                th=document.createElement "th"
                if this_rule?.rule.quantumwerewolf_diviner=="on"
                    th.textContent="村人"
                else
                    th.textContent="人間"
                tr.appendChild th
                if this_rule?.rule.quantumwerewolf_diviner=="on"
                    # 占い師の確率も表示:
                    th=document.createElement "th"
                    th.textContent="占い師"
                    tr.appendChild th
                th=document.createElement "th"
                th.textContent="人狼"
                tr.appendChild th
                if this_rule?.rule.quantumwerewolf_dead!="no"
                    th=document.createElement "th"
                    th.textContent="死亡"
                    tr.appendChild th
                for id,obj of pt
                    tr=tb.insertRow -1
                    tr.insertCell(-1).textContent=obj.name
                    pbu tr.insertCell(-1),obj.Human
                    if obj.Diviner?
                        pbu tr.insertCell(-1),obj.Diviner
                    pbu tr.insertCell(-1),obj.Werewolf
                    if this_rule?.rule.quantumwerewolf_dead!="no"
                        pbu tr.insertCell(-1),obj.dead
                    if obj.dead==1
                        tr.classList.add "deadoff-line"
            p.appendChild tb
        else
            p=document.createElement "div"
            div=document.createElement "div"
            div.classList.add "name"
            icondiv=document.createElement "div"
            icondiv.classList.add "icon"

            if log.name?
                div.textContent=switch log.mode
                    when "monologue", "heavenmonologue"
                        "#{log.name}の独り言:"
                    when "will"
                        "#{log.name}の遺言:"
                    else
                        "#{log.name}:"
                if this_icons[log.name]
                    # アイコンがある
                    img=document.createElement "img"
                    img.style.width="1em"
                    img.style.height="1em"
                    img.alt=""  # 飾り
                    Index.util.setHTTPSicon img, this_icons[log.name], this_icons_cache
                    icondiv.appendChild img
            p.appendChild icondiv
            p.appendChild div
            p.dataset.name=log.name

            span=document.createElement "div"
            span.classList.add "comment"
            if log.size in ["big","small"]
                # 大/小発言
                span.classList.add log.size

            wrdv=document.createElement "div"
            wrdv.textContent=log.comment ? ""
            # 改行の処理
            spp=wrdv.firstChild # Text
            wr=0
            while spp? && (wr=spp.nodeValue.indexOf("\n"))>=0
                spp=spp.splitText wr+1
                wrdv.insertBefore document.createElement("br"),spp

            parselognode wrdv
            span.appendChild wrdv

            p.appendChild span
            if log.time?
                time=Index.util.timeFromDate new Date log.time
                time.classList.add "time"
                p.appendChild time
            if log.mode=="nextturn" && log.day
                #IDづけ
                p.id="turn_#{log.day}#{if log.night then '_night' else ''}"
                this_logdata.day=log.day
                this_logdata.night=log.night

                if log.night==false || log.day==1
                    # 朝の場合optgroupに追加
                    option=document.createElement "option"
                    option.value=log.day
                    option.textContent="#{log.day}日目"
                    $("#chooseviewday").append option
                    setcss()
        # 日にちデータ
        if this_logdata.day
            p.dataset.day=this_logdata.day
            if this_logdata.night
                p.dataset.night="night"
        else
            p.dataset.day=0

        p.classList.add log.mode

        logs=$("#logs").get 0
        logs.insertBefore p,logs.firstChild

    # プレイヤーオブジェクトのプロパティを得る
    ###
    getprop=(obj,propname)->
        if obj[propname]?
            obj[propname]
        else if obj.main?
            getprop obj.main,propname
        else
            undefined
    getname=(obj)->getprop obj,"name"
    ###


    formplayers=(players)-> #jobflg: 1:生存の人 2:死人
        $("#form_players").empty()
        $("#players").empty()
        $("#playernumberinfo").text "生存者#{players.filter((x)->!x.dead).length}人 / 死亡者#{players.filter((x)->x.dead).length}人"
        players.forEach (x)->
            # 上の一覧用
            li=makeplayerbox x
            $("#players").append li

            # アイコン
            if x.icon
                this_icons[x.name]=x.icon

        game_view?.store.resetPlayers players.map convertGamePlayerToPlayerInfo

    setJobSelection=(selections)->
        $("#form_players").empty()
        valuemap={} #重複を取り除く
        for x in selections
            continue if valuemap[x.value]   # 重複チェック
            # 投票フォーム用
            li=document.createElement "li"
            #if x.dead
            #   li.classList.add "dead"
            label=document.createElement "label"
            label.textContent=x.name
            input=document.createElement "input"
            input.type="radio"
            input.name="target"
            input.value=x.value
            #input.disabled=!((x.dead && (jobflg&2))||(!x.dead && (jobflg&1)))
            label.appendChild input
            li.appendChild label
            $("#form_players").append li
            valuemap[x.value]=true


    # タイマー情報をもらった
    gettimer=(msg,mode)->
        remain_time=parseInt msg
        clearInterval timerid if timerid?
        timerid=setInterval ->
            remain_time--
            return if remain_time<0
            min=parseInt remain_time/60
            sec=remain_time%60
            $("#time").text "#{mode || ''} #{min}:#{sec}"
        ,1000
        # for new frontend
        game_view?.store.update {
            timer: {
                enabled: true
                name: mode
                target: Date.now() + remain_time * 1000
            }
        }

    makebutton=(text,title="")->
        b=document.createElement "button"
        b.type="button"
        b.textContent=text
        b.title=title
        b



exports.end=->
    # unmount react components.
    game_start_control?.unmount()
    game_view?.unmount()

    ss.rpc "game.rooms.exit", this_room_id,(result)->
        if result?
            Index.util.message "ルーム",result
            return
    clearInterval timerid if timerid?
    alloff socket_ids...
    document.body.classList.remove x for x in ["day","night","finished","heaven"]
    if this_style?
        $(this_style).remove()

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

# #players用要素
makeplayerbox=(obj,blindflg,tagname="li")->#obj:game.playersのアレ
    #df=document.createDocumentFragment()
    df=document.createElement tagname

    df.dataset.id=obj.id ? obj.userid
    df.dataset.name=obj.name
    if obj.icon
        figure=document.createElement "figure"
        figure.classList.add "icon"
        div=document.createElement "div"
        div.classList.add "avatar"
        img=document.createElement "img"
        img.width=img.height=48
        img.alt=""
        img.style.width = "48px"
        img.style.height = "48px"
        Index.util.setHTTPSicon img, obj.icon
        div.appendChild img
        figure.appendChild div
        img2=document.createElement "img"
        img2.src="/images/dead.png"
        img2.width=img2.height=48
        img2.alt="死亡"
        img2.classList.add "dead_mark"
        figure.appendChild img2
        df.appendChild figure
        df.classList.add "icon"
    p=document.createElement "p"
    p.classList.add "name"

    if obj.realid
        a=document.createElement "a"
        a.href="/user/#{obj.realid}"
        a.textContent=obj.name
        a.classList.add "user-name"
        p.appendChild a
    else
        p.textContent=obj.name
    df.appendChild p

    if obj.jobname
        p=document.createElement "p"
        p.classList.add "job"
        if obj.originalJobname?
            ###
            if obj.originalJobname==obj.jobname || obj.originalJobname.indexOf("→")>=0
                p.textContent=obj.originalJobname
            else
                p.textContent="#{obj.originalJobname}→#{obj.jobname}"
            ###
            p.textContent=obj.originalJobname
        else
            p.textContent=obj.jobname
        if obj.option
            p.textContent+= "（#{obj.option}）"
        df.appendChild p
        if obj.winner?
            p=document.createElement "p"
            p.classList.add "outcome"
            if obj.winner
                p.classList.add "win"
                p.textContent="勝利"
            else
                p.classList.add "lose"
                p.textContent="敗北"
            df.appendChild p
    if obj.dead
        df.classList.add "dead"
        if !obj.winner? && obj.norevive==true
            # 蘇生辞退
            p=document.createElement "p"
            p.classList.add "job"
            p.textContent="[蘇生辞退]"
            df.appendChild p
    if obj.mode=="gm"
        # GM
        p=document.createElement "p"
        p.classList.add "job"
        p.classList.add "gm"
        p.textContent="[GM]"
        df.appendChild p
    else if /^helper_/.test obj.mode
        # ヘルパー
        p=document.createElement "p"
        p.classList.add "job"
        p.classList.add "helper"
        p.textContent="[helper]"
        df.appendChild p

    if obj.start
        # 準備完了
        p=document.createElement "p"
        p.classList.add "job"
        p.textContent="[ready]"
        df.appendChild p
    df

speakValueToStr=(game,value)->
    # 発言のモード名を文字列に
    switch value
        when "day","prepare"
            "全員に発言"
        when "audience"
            "観戦者の会話"
        when "monologue"
            "独り言"
        when "werewolf"
            "人狼の会話"
        when "couple"
            "共有者の会話"
        when "madcouple"
            "叫迷狂人の会話"
        when "fox"
            "妖狐の会話"
        when "gm"
            "全員へ"
        when "gmheaven"
            "霊界へ"
        when "gmaudience"
            "観戦者へ"
        when "gmmonologue"
            "独り言"
        when "helperwhisper"
            # ヘルパー先がいない場合（自分への助言）
            "助言"
        else
            if result=value.match /^gmreply_(.+)$/
                pl=game.players.filter((x)->x.id==result[1])[0]
                "→#{pl.name}"
            else if result=value.match /^helperwhisper_(.+)$/
                "助言"
            else
                "???"


# オーナーが追い出し管理をクリックしたときの処理
kicklistmanage = (roomid)->
    ss.rpc "game.rooms.getbanlist", roomid, (result)->
        if !result? || result.error
            Index.util.message "エラー", result.error
            return
        ban = result.result
        win = Index.util.blankWindow {
            title: "追い出し管理"
            icon: "user-times"
        }, ()->
            inputs = win.find("input[type=\"checkbox\"]")

            query = []

            for input in inputs
                if input.checked
                    query.push input.name.slice(4)

            if query.length > 0
                ss.rpc "game.rooms.cancelban", roomid, query, (result)->
                    if result?
                        Index.util.message "エラー", result
                    else
                        Index.util.message "追い出し管理", "#{query.length}人の参加禁止を解除しました"


        win.append "<p>参加禁止を解除したい人にチェックを入れて「OK」を押してください。</p>"
        # kick一覧
        for id in ban
            p = document.createElement "p"
            l = document.createElement "label"
            input = document.createElement "input"
            input.type = "checkbox"
            input.name = "ban-#{id}"
            l.appendChild input

            txt = document.createTextNode id
            l.appendChild txt
            p.appendChild l

            win.append p

# Shared.game.jobrulesをLabeledGroup<CastingDefinition>に変換
getLabeledGroupsOfJobrules = ()->
    f = (arr, prefix)->
        result =
            for obj in arr
                if Array.isArray obj.rule
                    {
                        type: 'group'
                        label: obj.name
                        items: f obj.rule, [prefix..., obj.name]
                    }
                else
                    {
                        type: 'item'
                        value:
                            id: [prefix..., obj.name].join '.'
                            name: obj.name
                            label: obj.title
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
                    name: '自由配役'
                    label: '配役を自由に設定できます。'
                    roleSelect: true
            }
            {
                type: 'item'
                value:
                    id: '特殊ルール.闇鍋'
                    name: '闇鍋'
                    label: '配役がランダムに設定されます。'
                    roleSelect: false
            }
            {
                type: 'item'
                value:
                    id: '特殊ルール.一部闇鍋'
                    name: '一部闇鍋'
                    label: '一部の配役を固定して残りをランダムにします。'
                    roleSelect: true
                    roleExclusion: true
                    noFill: true
                    category: true
            }
            {
                type: 'item'
                value:
                    id: '特殊ルール.量子人狼'
                    name: '量子人狼'
                    label: '全員の役職などが確率で表現される人狼です。村人・人狼・占い師のみ。'
                    roleSelect: false
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
                    name: 'エンドレス闇鍋'
                    label: '途中参加可能で、死亡したらそのうち転生する闇鍋です。'

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
