
this_room_id=null

socket_ids=[]
my_job=null

timerid=null    # setTimeout
remain_time=null
this_rule=null  # ルールオブジェクトがある
enter_result=null #enter

this_icons={}   #名前とアイコンの対応表
this_logdata={} # ログデータをアレする
this_style=null #style要素（終わったら消したい）


exports.start=(roomid)->
    this_rule=null
    timerid=null
    remain_time=null
    my_job=null
    this_room_id=null

    # 役職名一覧
    cjobs=Shared.game.jobs.filter (x)->x!="Human"    # 村人は自動で決定する

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

    getenter=(result)->
        if result.error?
            # エラー
            Index.util.message "ルーム",result.error
            return
        else if result.require?
            if result.require=="password"
                #パスワード入力
                Index.util.prompt "ルーム","パスワードを入力して下さい",{type:"password"},(pass)->
                    unless pass?
                        Index.app.showUrl "/rooms"
                        return
                    ss.rpc "game.rooms.enter", roomid,pass,getenter
                    sessionStorage.roompassword = pass
            return
        enter_result=result
        this_room_id=roomid
        ss.rpc "game.rooms.oneRoom", roomid,initroom
    ss.rpc "game.rooms.enter", roomid,sessionStorage.roompassword ? null,getenter
    initroom=(room)->
        unless room?
            Index.util.message "ルーム","そのルームは存在しません。"
            Index.app.showUrl "/rooms"
            return
        # フォームを修正する
        forminfo=->
            setplayersnumber room,$("#gamestart").get(0), room.players.filter((x)->x.mode=="player").length
        # 今までのログを送ってもらう
        this_icons={}
        this_logdata={}
        this_openjob_flag=false
        # 役職情報をもらった
        getjobinfo=(obj)->
            console.log obj,this_room_id
            return unless obj.id==this_room_id
            my_job=obj.type
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
                        localStorage.savedJobs=JSON.stringify result.game.jobscount
                        #Index.app.showUrl "/newroom"
                        # 新しいタブで開く
                        a=document.createElement "a"
                        a.href="/newroom"
                        a.target="_blank"
                        a.click()

                
                result.logs.forEach getlog
                gettimer parseInt(result.timer),result.timer_mode if result.timer?

        ss.rpc "game.game.getlog", roomid,sentlog
        # 新しいゲーム
        newgamebutton = (je)->
            unless $("#gamestartsec").attr("hidden") == "hidden"
                return
            form=$("#gamestart").get 0
            # ルール設定保存を参照する
            # ルール画面を構築するぞーーー(idx: グループのアレ)
            buildrules=(arr,parent)->
                p=null
                for obj,idx in arr
                    if obj.rules
                        # グループだ
                        if p && !p.get(0).hasChildNodes()
                            # 空のpは要らない
                            p.remove()
                        fieldset=$ "<fieldset>"
                        
                        pn=parent.attr("name") || ""
                        fieldset.attr "name","#{pn}.#{idx}"
                        if obj.label
                            fieldset.append $ "<legend>#{obj.label}</legend>"
                        buildrules obj.rules,fieldset
                        parent.append fieldset
                        p=null
                    else
                        # ひとつの設定だ
                        if obj.type=="separator"
                            # pの区切り
                            p=$ "<p>"
                            p.appendTo parent
                            continue
                        unless p?
                            p=$ "<p>"
                            p.appendTo parent
                        label=$ "<label>"
                        if obj.title
                            label.attr "title",obj.title
                        unless obj.backlabel
                            if obj.type!="hidden"
                                label.text obj.label
                        switch obj.type
                            when "checkbox"
                                input=$ "<input>"
                                input.attr "type","checkbox"
                                input.attr "name",obj.name
                                input.attr "value",obj.value.value
                                input.prop "checked",!!obj.value.checked
                                label.append input
                            when "select"
                                select=$ "<select>"
                                select.attr "name",obj.name
                                slv=null
                                for o in obj.values
                                    op=$ "<option>"
                                    op.text o.label
                                    if o.title
                                        op.attr "title",o.title
                                    op.attr "value",o.value
                                    select.append op
                                    if o.selected
                                        slv=o.value
                                if slv?
                                    select.get(0).value=slv
                                label.append select
                            when "time"
                                input=$ "<input>"
                                input.attr "type","number"
                                input.attr "name",obj.name.minute
                                input.attr "min","0"
                                input.attr "step","1"
                                input.attr "size","5"
                                input.attr "value",String obj.defaultValue.minute
                                label.append input
                                label.append document.createTextNode "分"

                                input=$ "<input>"
                                input.attr "type","number"
                                input.attr "name",obj.name.second
                                input.attr "min","0"
                                input.attr "max","59"
                                input.attr "step","1"
                                input.attr "size","5"
                                input.attr "value",String obj.defaultValue.second
                                label.append input
                                label.append document.createTextNode "秒"
                            when "hidden"
                                input=$ "<input>"
                                input.attr "type","hidden"
                                input.attr "name",obj.name
                                input.attr "value",obj.value.value
                                label.append input
                            when "second"
                                input=$ "<input>"
                                input.attr "type","number"
                                input.attr "name",obj.name
                                input.attr "min","0"
                                input.attr "step","1"
                                input.attr "size","5"
                                input.attr "value",obj.defaultValue.value
                                label.append input
                        if obj.backlabel
                            if obj.type!="hidden"
                                label.append document.createTextNode obj.label
                        p.append label


            $("#rules").attr "name","rule"
            buildrules Shared.game.rules,$("#rules")
            if localStorage.savedRule
                rule=JSON.parse localStorage.savedRule
                jobs=JSON.parse localStorage.savedJobs
                delete localStorage.savedRule
                delete localStorage.savedJobs
                # 時間設定
                daysec=rule.day-0
                nightsec=rule.night-0
                remainsec=rule.remain-0
                form.elements["day_minute"].value=parseInt daysec/60
                form.elements["day_second"].value=daysec%60
                form.elements["night_minute"].value=parseInt nightsec/60
                form.elements["night_second"].value=nightsec%60
                form.elements["remain_minute"].value=parseInt remainsec/60
                form.elements["remain_second"].value=remainsec%60
                # その他
                delete rule.number  # 人数は違うかも
                for key of rule
                    e=form.elements[key]
                    if e?
                        if e.type=="checkbox"
                            e.checked = e.value==rule[key]
                        else
                            e.value=rule[key]
                # 配役も再現
                for job in Shared.game.jobs
                    e=form.elements[job]    # 役職
                    if e?
                        e.value=jobs[job]?.number ? 0

            $("#gamestartsec").removeAttr "hidden"

            forminfo()

        $("#roomname").text room.name
        if room.mode=="waiting"
            # 開始前のユーザー一覧は roomから取得する
            console.log room.players
            room.players.forEach (x)->
                li=makeplayerbox x,room.blind
                $("#players").append li
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
                ###
                Index.util.prompt "ゲームに参加","名前を入力して下さい",null,(name)->
                    if name
                        opt.name=name
                        into()
                ###
                # ここ書いてないよ!
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
                Index.util.selectprompt "ヘルパー","誰のヘルパーになりますか?",room.players.map((x)->{name:x.name,value:x.userid}),(id)->
                    ss.rpc "game.rooms.helper",roomid, id,(result)->
                        if result?
                            Index.util.message "エラー",result
            $("#playersinfo").append b

        userid=Index.app.userid()
        if room.mode=="waiting"
            if room.owner.userid==Index.app.userid()
                # 自分
                b=makebutton "ゲーム開始画面を開く"
                $("#playersinfo").append b
                $(b).click newgamebutton
                b=makebutton "参加者を追い出す"
                $("#playersinfo").append b
                $(b).click (je)->
                    Index.util.selectprompt "追い出す","追い出す人を選択して下さい",room.players.map((x)->{name:x.name,value:x.userid}),(id)->
                        if id
                            ss.rpc "game.rooms.kick", roomid,id,(result)->
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

                # 役職入力フォームを作る
                (()=>
                    # job -> cat と job -> team を作る
                    catTable = {}
                    teamTable = {}

                    dds = {}
                    for category,members of Shared.game.categories
                        # HTML
                        dt = document.createElement "dt"
                        dt.textContent = Shared.game.categoryNames[category]
                        dt.classList.add "jobs-cat"
                        dd = dds[category] = document.createElement "dd"
                        dd.classList.add "jobs-cat"
                        $("#jobsfield").append(dt).append(dd)
                        # table
                        for job in members
                            catTable[job] = category

                    dt = document.createElement "dt"
                    dt.classList.add "jobs-cat"
                    dt.textContent = "その他"
                    dd = dds["*"] = document.createElement "dd"
                    dd.classList.add "jobs-cat"
                    # その他は今の所ない
                    # $("#jobsfield").append(dt).append(dd)

                    # table
                    for team,members of Shared.game.teams
                        for job in members
                            teamTable[job] = team

                    for job in Shared.game.jobs
                        # 探す
                        dd = $(dds[catTable[job] ? "*"])
                        team = teamTable[job]
                        continue unless team?
                        ji = Shared.game.jobinfo[team][job]

                        div = document.createElement "div"
                        div.classList.add "jobs-job"
                        div.dataset.job = job
                        b = document.createElement "b"
                        span = document.createElement "span"
                        span.textContent = ji.name
                        b.appendChild span
                        b.insertAdjacentHTML "beforeend", "<a class='jobs-job-help' href='/manual/job/#{job}'><i class='fa fa-question-circle-o'></i></a>"
                        span = document.createElement "span"
                        span.classList.add "jobs-job-controls"

                        if job == "Human"
                            # 村人は違う処理
                            output = document.createElement "output"
                            output.name = job
                            output.dataset.jobname = ji.name
                            output.classList.add "jobs-job-controls-number"
                            span.appendChild output
                            check = document.createElement "input"
                            check.type = "hidden"
                            check.name = "job_use_#{job}"
                            check.value = "on"
                            span.appendChild check
                        else
                            # 使用チェック
                            check = document.createElement "input"
                            check.type = "checkbox"
                            check.checked = true
                            check.name = "job_use_#{job}"
                            check.value = "on"
                            check.classList.add "jobs-job-controls-check"
                            check.title = "チェックを外すと、一部闇鍋で#{ji.name}が出現しなくなります。"
                            span.appendChild check
                            # 人数
                            input = document.createElement "input"
                            input.type = "number"
                            input.min = 0
                            input.step = 1
                            input.value = 0
                            input.name = job
                            input.dataset.jobname = ji.name
                            input.classList.add "jobs-job-controls-number"
                            # plus / minus button
                            button1 = document.createElement "button"
                            button1.type = "button"
                            button1.classList.add "jobs-job-controls-button"
                            ic1 = document.createElement "i"
                            ic1.classList.add "fa"
                            ic1.classList.add "fa-plus-square"
                            button1.appendChild ic1
                            button1.addEventListener 'click', ((job)-> (e)->
                                # plus 1
                                form = e.currentTarget.form
                                num = form.elements[job]
                                v = parseInt(num.value)
                                num.value = String(v + 1)
                                jobsformvalidate room, form
                            )(job)

                            button2 = document.createElement "button"
                            button2.type = "button"
                            button2.classList.add "jobs-job-controls-button"
                            ic2 = document.createElement "i"
                            ic2.classList.add "fa"
                            ic2.classList.add "fa-minus-square"
                            button2.appendChild ic2
                            button2.addEventListener 'click', ((job)-> (e)->
                                # plus 1
                                form = e.currentTarget.form
                                num = form.elements[job]
                                v = parseInt(num.value)
                                if v > 0
                                    num.value = String(v - 1)
                                    jobsformvalidate room, form
                            )(job)

                            span.appendChild input
                            span.appendChild button1
                            span.appendChild button2
                        div.appendChild b
                        div.appendChild span
                        dd.append div
                    # カテゴリ別のも用意しておく
                    dt = document.createElement "dt"
                    dt.classList.add "jobs-cat"
                    dt.textContent = "一部闇鍋用"
                    dd = document.createElement "dd"
                    dd.classList.add "jobs-cat"
                    for type,name of Shared.game.categoryNames
                        div = document.createElement "div"
                        div.classList.add "jobs-job"
                        div.dataset.job = "category_#{type}"
                        b = document.createElement "b"
                        span = document.createElement "span"
                        span.textContent = name
                        b.appendChild span
                        span = document.createElement "span"
                        span.classList.add "jobs-job-controls"

                        input = document.createElement "input"
                        input.type = "number"
                        input.min = 0
                        input.step = 1
                        input.value = 0
                        input.name = "category_#{type}"
                        input.dataset.jobname = name
                        input.classList.add "jobs-job-controls-number"
                        # plus / minus button
                        button1 = document.createElement "button"
                        button1.type = "button"
                        button1.classList.add "jobs-job-controls-button"
                        ic1 = document.createElement "i"
                        ic1.classList.add "fa"
                        ic1.classList.add "fa-plus-square"
                        button1.appendChild ic1
                        button1.addEventListener 'click', ((type)-> (e)->
                            # plus 1
                            form = e.currentTarget.form
                            num = form.elements["category_#{type}"]
                            v = parseInt(num.value)
                            num.value = String(v + 1)
                            jobsformvalidate room, form
                        )(type)

                        button2 = document.createElement "button"
                        button2.type = "button"
                        button2.classList.add "jobs-job-controls-button"
                        ic2 = document.createElement "i"
                        ic2.classList.add "fa"
                        ic2.classList.add "fa-minus-square"
                        button2.appendChild ic2
                        button2.addEventListener 'click', ((type)-> (e)->
                            # plus 1
                            form = e.currentTarget.form
                            num = form.elements["category_#{type}"]
                            v = parseInt(num.value)
                            if v > 0
                                num.value = String(v - 1)
                                jobsformvalidate room, form
                        )(type)

                        span.appendChild input
                        span.appendChild button1
                        span.appendChild button2
                        div.appendChild b
                        div.appendChild span
                        dd.appendChild div
                    $("#catesfield").append(dt).append(dd)
                )()
            if room.owner.userid==Index.app.userid() || room.old
                b=makebutton "この部屋を廃村にする"
                $("#playersinfo").append b
                $(b).click (je)->
                    Index.util.ask "部屋削除","本当に部屋を削除しますか?",(cb)->
                        if cb
                            ss.rpc "game.rooms.del", roomid,(result)->
                                if result?
                                    Index.util.message "エラー",result


        form=$("#gamestart").get 0
        # ゲーム開始フォームが何か変更されたら呼ばれる関数
        jobsforminput=(e)->
            t=e.target
            form=t.form
            pl=room.players.filter((x)->x.mode=="player").length
            if t.name=="jobrule" || t.name=="chemical"
                # ルール変更があった
                resetplayersinput room, form
                setplayersbyjobrule room,form,pl
            jobsformvalidate room,form
        form.addEventListener "input",jobsforminput,false
        form.addEventListener "change",jobsforminput,false
                
                
        $("#gamestart").submit (je)->
            # いよいよゲーム開始だ！
            je.preventDefault()
            query=Index.util.formQuery je.target
            jobrule=query.jobrule
            ruleobj=Shared.game.getruleobj(jobrule) ? {}
            # ステップ2: 時間チェック
            step2=->
                # 夜時間をチェック
                minNight = ruleobj.suggestedNight?.min ? -Infinity
                maxNight = ruleobj.suggestedNight?.max ? Infinity
                night = parseInt(query.night_minute)*60+parseInt(query.night_second)
                #console.log ruleobj,night,minNight,maxNight
                if night<minNight || maxNight<night
                    # 範囲オーバー
                    Index.util.ask "オプション","この配役では夜の時間は#{if isFinite(minNight) then minNight+'秒以上' else ''}#{if isFinite(maxNight) then maxNight+'秒以下' else ''}が推奨されています。このまま開始してもいいですか？",(res)->
                        if res
                            #OKだってよ...
                            starting()
                else
                    starting()
            # じっさいに開始
            starting=->
                ss.rpc "game.game.gameStart", roomid,query,(result)->
                    if result?
                        Index.util.message "ルーム",result
                    else
                        $("#gamestartsec").attr "hidden","hidden"
            # 相違がないか探す
            diff=null
            for key,value of (ruleobj.suggestedOption ? {})
                if query[key]!=value
                    diff=
                        key:key
                        value:value
                    break
            if diff?
                control=je.target.elements[diff.key]
                if control?
                    sugval=null
                    if control.type=="select-one"
                        for opt in control.options
                            if opt.value==diff.value
                                sugval=opt.text
                                break
                        if sugval?
                            Index.util.ask "オプション","この配役ではオプション「#{control.dataset.name}」を「#{sugval}」にすることが推奨されています。このまま開始してもいいですか？",(res)->
                                if res
                                    # OKだってよ...
                                    step2()
                            return
            # とくに何もない
            step2()
        speakform=$("#speakform").get 0
        $("#speakform").submit (je)->
            form=je.target
            ss.rpc "game.game.speak", roomid,Index.util.formQuery(form),(result)->
                if result?
                    Index.util.message "エラー",result
            je.preventDefault()
            form.elements["comment"].value=""
            if form.elements["multilinecheck"].checked
                # 複数行は直す
                form.elements["multilinecheck"].click()
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
            Object.keys(this_rule.jobscount).forEach (x)->
                a=document.createElement "a"
                a.href="/manual/job/#{x}"
                a.textContent="#{this_rule.jobscount[x].name}#{this_rule.jobscount[x].number}"
                p.appendChild a
                p.appendChild document.createTextNode " "
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
                            valobj=obj.getstr ruleobj[obj.name]
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
            chkrule this_rule.rule, this_rule.jobscount,Shared.game.rules
            
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
        # 蘇生辞退ボタン
        $("#speakform").get(0).elements["norevivebutton"].addEventListener "click",(e)->
            Index.util.ask "蘇生辞退","一度蘇生辞退をすると解除することができません。よろしいですか？",(result)->
                if result
                    ss.rpc "game.game.norevive", roomid, (result)->
                        if result?
                            # エラー
                            Index.util.message "エラー",result
                        else
                            Index.util.message "蘇生辞退","蘇生を辞退しました。"
        ,false
        #========================================
            
        # 誰かが参加した!!!!
        socket_ids.push Index.socket.on "join","room#{roomid}",(msg,channel)->
            room.players.push msg
            ###
            li=document.createElement "li"
            li.title=msg.userid
            if room.blind
                li.textContent=msg.name
            else
                a=document.createElement "a"
                a.href="/user/#{msg.userid}"
                a.textContent=msg.name
                li.appendChild a
            ###
            li=makeplayerbox msg,room.blind
            $("#players").append li
            forminfo()
        # 誰かが出て行った!!!
        socket_ids.push Index.socket.on "unjoin","room#{roomid}",(msg,channel)->
            room.players=room.players.filter (x)->x.userid!=msg
            
            $("#players li").filter((idx)-> this.dataset.id==msg).remove()
            forminfo()
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
        socket_ids.push Index.socket.on "unreadyall","room#{roomid}",(msg,channel)->
            for pl in room.players
                if pl.start
                    pl.start=false
                    li=$("#players li").filter((idx)-> this.dataset.id==pl.userid)
                    li.replaceWith makeplayerbox pl,room.blind
        socket_ids.push Index.socket.on "mode","room#{roomid}",(msg,channel)->
            for pl in room.players
                if pl.userid==msg.userid
                    pl.mode=msg.mode
                    li=$("#players li").filter((idx)-> this.dataset.id==msg.userid)
                    li.replaceWith makeplayerbox pl,room.blind
                    forminfo()
            
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
    # 配役タイプ
    setjobrule=(rulearr,names,parent)->
        for obj in rulearr
            # name,title, ruleをもつ
            if obj.rule instanceof Array
                # さらに子
                optgroup=document.createElement "optgroup"
                optgroup.label=obj.name
                parent.appendChild optgroup
                setjobrule obj.rule,names.concat([obj.name]),optgroup
            else
                # option
                option=document.createElement "option"
                option.textContent=obj.name
                option.value=names.concat([obj.name]).join "."
                option.title=obj.title
                parent.appendChild option
                
    setjobrule Shared.game.jobrules.concat([
        name:"特殊ルール"
        rule:[
            {
                name:"自由配役"
                title:"配役を自由に設定できます。"
                rule:null
            }
            {
                name:"闇鍋"
                title:"配役がランダムに設定されます。"
                rule:null
            }
            {
                name:"一部闇鍋"
                title:"一部の配役を固定して残りをランダムにします。"
                rule:null
            }
            {
                name:"量子人狼"
                title:"全員の役職などが確率で表現される。村人・人狼・占い師のみ。"
                rule:null
                suggestedNight:{
                    max:60
                }
            }
            {
                name:"エンドレス闇鍋"
                title:"途中参加可能・死亡したらそのうち転生の闇鍋。"
                rule:null
                suggestedOption:{
                    heavenview:""
                }
            }
        ]
        
    ]),[],$("#jobruleselect").get 0
    
        
    setplayersnumber=(room,form,number)->
        form.elements["number"].value=number
        unless $("#gamestartsec").attr("hidden") == "hidden"
            setplayersbyjobrule room,form,number
            jobsformvalidate room,form
    # 配役一覧をアレする
    setplayersbyjobrule=(room,form,number)->
        jobrulename=form.elements["jobrule"].value
        if form.elements["scapegoat"]?.value=="on"
            number++    # 身代わりくん
        if jobrulename in ["特殊ルール.自由配役","特殊ルール.一部闇鍋"]
            j = $("#jobsfield").get 0
            j.hidden=false
            j.dataset.checkboxes = (if jobrulename!="特殊ルール.一部闇鍋" then "no" else "")
            $("#catesfield").get(0).hidden= jobrulename!="特殊ルール.一部闇鍋"
            #$("#yaminabe_opt_nums").get(0).hidden=true
        else if jobrulename in ["特殊ルール.闇鍋","特殊ルール.エンドレス闇鍋"]
            $("#jobsfield").get(0).hidden=true
            $("#catesfield").get(0).hidden=true
            #$("#yaminabe_opt_nums").get(0).hidden=false
        else
            $("#jobsfield").get(0).hidden=true
            $("#catesfield").get(0).hidden=true
        if jobrulename=="特殊ルール.量子人狼"
            jobrulename="内部利用.量子人狼"
        obj= Shared.game.getrulefunc jobrulename
        if obj?
            form.elements["number"].value=number
            for x in Shared.game.jobs
                form.elements[x].value=0
            jobs=obj number
            count=0 #村人以外
            for job,num of jobs
                form.elements[job]?.value=num
                count+=num
            # カテゴリ別
            for type of Shared.game.categoryNames
                count+= parseInt(form.elements["category_#{type}"].value ? 0)
            # 残りが村人の人数
            if form.elements["chemical"]?.checked
                # chemical人狼では村人を足す
                form.elements["Human"].value = number*2 - count
            else
                form.elements["Human"].value = number-count

        setjobsmonitor form,number
    jobsformvalidate=(room,form)->
        # 村人の人数を調節する
        pl=room.players.filter((x)->x.mode=="player").length
        if form.elements["scapegoat"].value=="on"
            # 身代わりくん
            pl++
        sum=0
        cjobs.forEach (x)->
            chk = form.elements["job_use_#{x}"].checked
            if chk
                sum+=Number form.elements[x].value
            else
                form.elements[x].value = 0
        # カテゴリ別
        for type of Shared.game.categoryNames
            sum+= parseInt(form.elements["category_#{type}"].value ? 0)
        if form.elements["chemical"].checked
            form.elements["Human"].value=pl*2-sum
        else
            form.elements["Human"].value=pl-sum
        form.elements["number"].value=pl
        setplayersinput room, form
        setjobsmonitor form,pl
    # ルールの表示具合をチェックする
    checkrule=(form,ruleobj,rules,fsetname)->
        for obj,idx in rules
            continue unless obj.rules
            fsetname2="#{fsetname}.#{idx}"
            form.elements[fsetname2].hidden=!(obj.visible ruleobj,ruleobj)
            checkrule form,ruleobj,obj.rules,fsetname2
    # ルールが変更されたときはチェックを元に戻す
    resetplayersinput=(room, form)->
        rule = form.elements["jobrule"].value
        if rule != "特殊ルール.一部闇鍋"
            checks = form.querySelectorAll 'input.jobs-job-controls-check[name^="job_use_"]'
            for check in checks
                check.checked = true
    # フォームに応じてプレイヤーの人数inputの表示を調整
    setplayersinput=(room, form)->
        divs = document.querySelectorAll "div.jobs-job"
        for div in divs
            job = div.dataset.job
            if job?
                e = form.elements[job]
                chk = form.elements["job_use_#{job}"]
                if e?
                    v = Number e.value
                    if chk? && chk.type=="checkbox" && !chk.checked
                        # 無効化されている
                        div.classList.remove "jobs-job-active"
                        div.classList.add "jobs-job-inactive"
                        div.classList.remove "jobs-job-error"
                    else if v > 0
                        div.classList.add "jobs-job-active"
                        div.classList.remove "jobs-job-inactive"
                        div.classList.remove "jobs-job-error"
                    else if v < 0
                        div.classList.remove "jobs-job-active"
                        div.classList.remove "jobs-job-inactive"
                        div.classList.add "jobs-job-error"
                    else
                        div.classList.remove "jobs-job-active"
                        div.classList.remove "jobs-job-inactive"
                        div.classList.remove "jobs-job-error"
            
            
    # 配役をテキストで書いてあげる
    setjobsmonitor=(form,number)->
        text=""
        rule=Index.util.formQuery form
        jobrule=rule.jobrule
        if jobrule=="特殊ルール.闇鍋"
            # 闇鍋の場合
            $("#jobsmonitor").text "闇鍋"
        else if jobrule=="特殊ルール.エンドレス闇鍋"
            $("#jobsmonitor").text "エンドレス闇鍋"
        else
            ruleobj=Shared.game.getruleobj jobrule
            if ruleobj?.minNumber>number
                $("#jobsmonitor").text "（この配役は最低#{ruleobj.minNumber}人必要です）"
            else
                $("#jobsmonitor").text Shared.game.getrulestr jobrule,rule
        ###
        jobprops=$("#jobprops")
        jobprops.children(".prop").prop "hidden",true
        for job in Shared.game.jobs
            jobpr=jobprops.children(".prop.#{job}")
            if jobrule in ["特殊ルール.闇鍋","特殊ルール.一部闇鍋"] || form.elements[job].value>0
                jobpr.prop "hidden",false
        # ルールによる設定
        ruleprops=$("#ruleprops")
        ruleprops.children(".prop").prop "hidden",true
        switch jobrule
            when "特殊ルール.量子人狼"
                ruleprops.children(".prop.rule-quantum").prop "hidden",false
                # あと身代わりくんはOFFにしたい
                form.elements["scapegoat"].value="off"
        ###
        if jobrule=="特殊ルール.量子人狼"
            # あと身代わりくんはOFFにしたい
            form.elements["scapegoat"].value="off"
            rule.scapegoat="off"
        checkrule form,rule,Shared.game.rules,$("#rules").attr("name")
        
        
    #ログをもらった
    getlog=(log)->
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
                    when "monologue"
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
                    img.src=this_icons[log.name]
                    img.alt=""  # 飾り
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
            
    makebutton=(text,title="")->
        b=document.createElement "button"
        b.type="button"
        b.textContent=text
        b.title=title
        b
        
        
            
exports.end=->
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
        img=document.createElement "img"
        img.src=obj.icon
        img.width=img.height=48
        img.alt=obj.name
        figure.appendChild img
        df.appendChild figure
        df.classList.add "icon"
    p=document.createElement "p"
    p.classList.add "name"
    
    if obj.realid
        a=document.createElement "a"
        a.href="/user/#{obj.realid}"
        a.textContent=obj.name
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
