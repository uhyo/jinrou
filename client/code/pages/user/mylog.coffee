app=require '/app'
util=require '/util'

exports.start=->
    JinrouFront.loadI18n()
        .then((i18n)-> i18n.getI18nFor())
        .then (i18n)->
            ss.rpc "user.getMyuserlog", (result)->
                if result.error?
                    Index.util.message "エラー", result.error
                    return
                userlog = result.userlog
                usersummary = result.usersummary

                showUserlog i18n, userlog
                showUserSummary usersummary

                if result.data_open_recent
                    $("#open-recent").prop "checked", true
                if result.data_open_all
                    $("#open-all").prop "checked", true

                # 戦績が少ないとアレだ
                for i in document.querySelectorAll '.mylog-desc-of-open'
                    i.title += "戦績を公開するには総対戦数#{result.dataOpenBarrier}以上が必要です。"
                unless userlog?.counter?.allgamecount >= result.dataOpenBarrier
                    # 戦績が足りない
                    for elm in document.querySelectorAll 'label.mylog-open'
                        elm.classList.add 'mylog-open-disabled'
                else
                    # 戦績足りてる
                    $("#open-recent")
                        .prop "disabled", false
                        .change (je)->
                            changeOpenSetting 'open-recent', je.target
                    $("#open-all")
                        .prop "disabled", false
                        .change (je)->
                            changeOpenSetting 'open-all', je.target

exports.end=->

# make a jobinfo object with names added
namedJobinfo = (i18n)->
    jobinfo = Shared.game.jobinfo
    result = {}
    for team, obj of jobinfo
        result[team] = {
            name: i18n.t "roles:teamName.#{team}"
            color: obj.color
        }
        for job, obj2 of obj
            continue if job == "color"
            result[team][job] = {
                name: i18n.t "roles:jobname.#{job}"
                color: obj2.color
            }
    result

showUserlog = (i18n, userlog)->
    # 全期間データを表示
    unless userlog?
        $("#alldata")
            .empty()
            .append("<p>戦績データがありません。</p>")
        return
    grapharea = document.createElement 'div'
    $("#alldata")
        .empty()
        .append("""<p>対戦数：<b>#{userlog.counter?.allgamecount ? 0}</b>
            （勝利数：<b>#{userlog.wincount?.all ? 0}</b>，
            敗北数：<b>#{userlog.losecount?.all ? 0}</b>）</p>""")
        .append(grapharea)

    # グラフも表示
    makeGraph i18n, userlog, grapharea

showUserSummary = (usersummary)->
    # 直近データを表示
    $("#recentdata")
        .empty()
        .append("""
        <p>直近<b>#{usersummary.days}</b>日の戦績です。このデータは1日1回再集計されます。</p>
        <p>対戦数：<b>#{usersummary.game_total}</b></p>
        <p>勝利数：<b>#{usersummary.win}</b> (#{(if usersummary.game_total>0 then usersummary.win/usersummary.game_total*100 else 0).toFixed(1)}%)</p>
        <p>敗北数：<b>#{usersummary.lose}</b> (#{(if usersummary.game_total>0 then usersummary.lose/usersummary.game_total*100 else 0).toFixed(1)}%)</p>
        <p>突然死数：<b>#{usersummary.gone}</b> (#{(if usersummary.game_total>0 then usersummary.gone/usersummary.game_total*100 else 0).toFixed(1)}%)</p>
        <p>GM数：<b>#{usersummary.gm}</b></p>
        <p>ヘルパー数：<b>#{usersummary.helper}</b></p>
            """)

# 戦績公開設定を変更
changeOpenSetting = (mode, input)->
    input.disabled = true
    value = input.checked
    l = new util.LoadingIcon document.getElementById "#{mode}-icon"
    l.start()
    # 変換
    m = switch mode
        when 'open-recent' then 'recent'
        when 'open-all' then 'all'
    ss.rpc 'user.changeDataOpenSetting', {
        mode: m
        value: value
    }, (result)->
        if result.error?
            util.message 'エラー', result.error
        # 演出
        setTimeout (()->
            input.disabled = false
            input.checked = result.value
            l.stop()
        ), 200


# 戦績グラフを作る
makeGraph = (i18n, userlog, grapharea)->
    wincount = userlog.wincount ? {}
    losecount = userlog.losecount ? {}
    # 陣営の色
    teamcolors = merge namedJobinfo(i18n), {}

    grp=(title,size=200)->
        # 新しいグラフ作成して追加まで
        area = document.createElement 'section'
        head=document.createElement 'h3'
        head.textContent=title
        area.appendChild head
        graph = Index.user.graph.circleGraph size
        area.appendChild graph.area
        grapharea.appendChild area
        graph

    # 勝敗別
    graph1 = grp "役職数（勝敗別）"
    graph1.hide()
    # 勝敗を陣営ごとに
    gs=
        win:{}
        lose:{}
    for x,arr of Shared.game.teams
        gs.win[x]={}
        gs.lose[x]={}
        for job in arr
            if wincount[job]?
                gs.win[x][job]=wincount[job]
            if losecount[job]?
                gs.lose[x][job]=losecount[job]
    graph1.setData gs,{
        win:merge {
            name:"勝ち"
            color:"#FF0000"
        },teamcolors
        lose:merge {
            name:"負け"
            color:"#0000FF"
        },teamcolors
    }
    graph1.openAnimate 0.6
    # 役職ごとの勝率
    graph2=grp "役職ごとの勝敗数"
    graph2.hide()
    gs={}
    names=merge teamcolors,{}   #コピー
    for team of names
        gs[team]={}

        for type of names[team]
            continue if type in ["name","color"]
            names[team][type].win=
                name:"勝ち"
                color:"#FF0000"
            names[team][type].lose=
                name:"負け"
                color:"#0000FF"
            gs[team][type]=
                win:wincount[type] ? 0
                lose:losecount[type] ? 0
    graph2.setData gs,names
    graph2.openAnimate 0.6

#Object2つをマージ（obj1ベース）
#なにこの実装
merge=(obj1,obj2)->
    r=Object.create Object.getPrototypeOf obj1
    [obj1,obj2].forEach (x)->
        Object.getOwnPropertyNames(x).forEach (p)->
            r[p]=x[p]
    r
