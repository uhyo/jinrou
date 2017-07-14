#page module?
app=require '/app'
util=require '/util'

name_length_max=20

exports.start=(user)->
    seticon=(url)->
        $("#myicon").attr "src",url
        $("#changeprofile").get(0).elements["icon"].value=url
    if user?.icon?
        seticon user.icon
    
    $("section.profile p.edit").click (je)->
        transforminput je.target
    transforminput=(t)->
        return unless t?
        inp=document.createElement "input"
        inp.value=t.textContent
        inp.name=t.dataset.pname
        inp.type=t.dataset.type
        inp.maxlength=t.dataset.maxlength
        inp.required=true if t.dataset.required
        np=document.createElement "p"
        np.appendChild inp
        t.parentNode?.replaceChild np,t
        inp.focus()
        
    $("#changeprofile").submit (je)->
        je.preventDefault()
        q=Index.util.formQuery je.target
        q.userid=$("p.userid").get(0).textContent

        Index.util.prompt "プロフィール","パスワードを入力してください",{type:"password"},(result)->
            if result
                q.password=result
                pf = ()=>
                    ss.rpc "user.changeProfile", q,(result)->
                        if result.error?
                            Index.util.message "エラー",result.error
                        else
                            app.page "user-profile",result,Index.user.profile,result
                if q.mail?
                    ss.rpc "user.sendConfirmMail", q,(result)->
                        if result.error?
                            Index.util.message "エラー",result.error
                        else
                            pf()
                        if result.info?
                            Index.util.message "通知",result.info
                else
                    pf()
                    
    $("#mailconfirmsecuritybutton").click (je)->
        je.preventDefault()
        ss.rpc "user.changeMailconfirmsecurity", {
            mailconfirmsecurity: je.target.form.elements["mailconfirmsecurity"].checked
        }, (result)->
            if result?.error?
                Index.util.message "エラー",result.error
            else
                Index.util.message "通知", result.info
                app.page "user-profile", result, Index.user.profile, result

    $("#changepasswordbutton").click (je)->
        $("#changepassword").get(0).hidden=false
        $("#changepassword").submit (je)->
            je.preventDefault()
            ss.rpc "user.changePassword", Index.util.formQuery(je.target),(result)->
                if result?.error?
                    Index.util.message "エラー",result.error
                else
                    Index.util.message "通知", "パスワードを変更しました。"
                    $("#changepassword").get(0).hidden=true
                    app.page "user-profile",result,Index.user.profile,result
                    
    $("#changeprofile").get(0).elements["twittericonbutton"].addEventListener "click",((e)->
        Index.util.iconSelectWindow $("#myicon").attr("src"),(url)->
            seticon url
    ),false
    
    $("#changeprofile").get(0).elements["colorsettingbutton"].addEventListener "click",(e)->
        # 移動
        app.page "user-color",null,Index.user.color,null
    ,false
    
    $("#morescore").submit (je)->
        je.preventDefault()
        op=je.target.elements["open"].value
        if op=="true"
            # 隠す
            je.target.elements["submit"].value="詳細情報を開く"
            je.target.elements["open"].value="false"
            $("#grapharea").empty()
            return
        je.target.elements["open"].value="true"
        je.target.elements["submit"].value="詳細情報を隠す"
        ss.rpc "user.getMyuserlog", (obj)->
            unless obj?
                Index.util.message "戦績表示","戦績が存在しないので表示できません。"
                return
            wincount=obj.wincount ? {}
            losecount=obj.losecount ? {}
            # 陣営色
            teamcolors=merge Shared.game.jobinfo,{}
                
            grp=(title,size=200)->
                # 新しいグラフ作成して追加まで
                h2=document.createElement "h2"
                h2.textContent=title
                $("#grapharea").append h2
                graph=Index.user.graph.circleGraph size
                p=document.createElement "p"
                p.appendChild graph.canvas
                $("#grapharea").append p
                graph
            
            # 勝率グラフ
            graph=grp "勝敗ごとの役職"
            graph.hide()
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
            graph.setData gs,{
                win:merge {
                    name:"勝ち"
                    color:"#FF0000"
                },teamcolors
                lose:merge {
                    name:"負け"
                    color:"#0000FF"
                },teamcolors
            }
            graph.openAnimate 0.2
            # 役職ごとの勝率
            graph=grp "役職ごとの勝敗"
            graph.hide()
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
            graph.setData gs,names
            graph.openAnimate 0.2

    # 称号
    unless user.prizenames?.length>0
        # 称号がない
        $("#prizearea").html "<p>獲得称号はありません。</p>"
    else
        $("#prizenumber").text user.prizenames.length
        prizesdiv=$("#prizes")
        phs=["あいうえお","かきくけこがぎぐげご","さしすせそざじずぜぞ","たちつてとだぢづでど","なにぬねの","はひふへほばびぶべぼぱぴぷぺぽ","まみむめも","やゆよ","らりるれろ","わをん"]
        prizedictionary={}  # 称号のidと名前対応
        user.prizenames.sort (a,b)->
            if a.phonetic>b.phonetic
                1
            else
                -1
        # 同じグループは横ならびで
        pindex=-1
        ull=null
        user.prizenames.forEach (obj)->
            # どのグループに属するか
            thisgarr=phs[pindex] ? ""
            if !ull || thisgarr.indexOf(obj.phonetic.charAt 0)<0
                # これには属していない
                ull=$(document.createElement "ul")
                prizesdiv.append ull
                # 属す奴を探す
                pindex=-1
                for ph,i in phs
                    if ph.indexOf(obj.phonetic.charAt 0)>=0
                        # これに属している
                        pindex=i
                        break

            li=document.createElement "li"
            li.textContent=obj.name
            li.dataset.id=obj.id
            li.classList.add "prizetip"
            li.draggable=true
            ull.append li
            prizedictionary[obj.id]=obj.name
        ull=$("#conjunctions")
        for te in Shared.prize.conjunctions
            li=document.createElement "li"
            li.textContent=te
            li.classList.add "conjtip"
            li.draggable=true
            ull.append li
        # 消すやつを追加
        li=document.createElement "li"
        li.textContent="消す"
        li.classList.add "deleter"
        li.draggable=true
        ull.append li
        
        # 編集部分
        ull=$("#prizeedit")
        unless user.nowprize?   # 無い場合はデフォルト
            for te in Shared.prize.getPrizesComposition user.prizenames.length
                li=document.createElement "li"
                li.classList.add (if te=="prize" then "prizetip" else "conjtip")
                ull.append li
        else
            coms=Shared.prize.getPrizesComposition user.prizenames.length
            for type in coms
                li=document.createElement "li"
                if type=="prize"
                    li.classList.add "prizetip"
                else
                    li.classList.add "conjtip"
                
                obj=user.nowprize[0]
                if obj?.type==type
                    # 一致するので入れる
                    if type=="prize"
                        if obj.value?
                            li.dataset.id=obj.value
                        li.textContent=prizedictionary[obj.value] ? ""
                    else
                        li.textContent=obj.value
                    user.nowprize.shift()
                ull.append li
        $("#prizeedit li").each ->
            @dropzone="copy"
            
        # dragstart
        dragstart=(e)->
            e.dataTransfer.setData 'Text',JSON.stringify {id:e.target.dataset.id, value:e.target.textContent,deleter:e.target.classList.contains "deleter"}
        $("#pdragzone").get(0).addEventListener "dragstart",dragstart,false
        ull.get(0).addEventListener "dragover",((e)->
            if e.target.tagName=="LI"
                e.preventDefault()  # ドロップできる
        ),false
        ull.get(0).addEventListener "drop",((e)->
            t=e.target
            if t.tagName=="LI"
                e.preventDefault()
                obj=JSON.parse e.dataTransfer.getData("Text")
                if obj.deleter  #消す
                    delete t.dataset.id
                    t.textContent=""
                    return
                if obj.id   # prizeだ
                    if t.classList.contains "prizetip"
                        t.dataset.id=obj.id
                        t.textContent=obj.value
                else
                    if t.classList.contains "conjtip"
                        t.textContent=obj.value
        ),false
        
            
        $("#prizearea").submit (je)->
            je.preventDefault()
            que=util.formQuery je.target
            util.prompt "プロフィール","パスワードを入力してください",{type:"password"},(result)->
                if result
                    query=
                        password:result
                    prize=[]
                    $("#prizeedit li").each ->
                        if @classList.contains "prizetip"
                            # prizeだ
                            prize.push {
                                type:"prize"
                                value:@dataset.id ? null
                            }
                        else
                            prize.push {
                                type:"conjunction"
                                value:@textContent
                            }
                        null
                    query.prize=prize
                    
                    ss.rpc "user.usePrize", query,(result)->
                        if result?.error?
                            util.message "エラー",result.error
    
    Index.game.rooms.start()    # ルーム一覧を表示してもらう    
    # お知らせ一覧を取得する
    ss.rpc "user.getNews",(docs)->
        if docs.error?
            # ?
            console.error docs.error
            return
        table=$("#newslist").get 0
        docs.forEach (doc)->
            r=table.insertRow -1
            cell=r.insertCell 0
            d=new Date doc.time
            cell.textContent="#{d.getFullYear()}-#{d.getMonth()+1}-#{d.getDate()}"
            cell=r.insertCell 1
            cell.textContent=doc.message
        if docs[0]
            # ひとつでもあればここまで見たことにする
            localStorage.latestNews=docs[0].time
            # みたのでお知らせを除去
            $("#newNewsNotice").remove()

    # HTTP/HTTPS切り替えのための
    # ツールバーを設定
    application_config = Index.app.getApplicationConfig()
    if application_config?
        modes = application_config.modes
        for m in modes
            span = document.createElement "span"
            span.classList.add "tool-button"
            if m.icon
                icon = document.createElement "i"
                icon.classList.add "fa"
                icon.classList.add "fa-#{m.icon}"
                span.appendChild icon
            if location.href.indexOf(m.url) == 0
                # 今はこれなのであれしない
                span.classList.add "tool-disabled"
                span.appendChild(document.createTextNode "現在#{m.name}です")
            else
                a = document.createElement "a"
                a.href = m.url
                a.appendChild(document.createTextNode "#{m.name}へ移動")
                span.appendChild a
            $("#toolbar").append span

exports.end=->

#Object2つをマージ（obj1ベース）
merge=(obj1,obj2)->
    r=Object.create Object.getPrototypeOf obj1
    [obj1,obj2].forEach (x)->
        Object.getOwnPropertyNames(x).forEach (p)->
            r[p]=x[p]
    r
