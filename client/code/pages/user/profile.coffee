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
        Index.util.prompt "プロフィール","パスワードを入力して下さい",{type:"password"},(result)->
            if result
                q.password=result
                ss.rpc "user.changeProfile", q,(result)->
                    if result.error?
                        Index.util.message "エラー",result.error
                    else
                        app.page "user-profile",result,Index.user.profile,result
    .get(0).elements["changepasswordbutton"].addEventListener "click",((e)->
        $("#changepassword").get(0).hidden=false
        $("#changepassword").submit (je)->
            je.preventDefault()
            ss.rpc "user.changePassword", Index.util.formQuery(je.target),(result)->
                if result?.error?
                    Index.util.message "エラー",result.error
                else
                    $("#changepassword").get(0).hidden=true
                    app.page "user-profile",result,Index.user.profile
                    
    ),false
    $("#changeprofile").get(0).elements["twittericonbutton"].addEventListener "click",((e)->
        Index.util.iconSelectWindow $("#myicon").attr("src"),(url)->
            seticon url
    ),false
    
    ###
    $("#morescore").submit (je)->
        je.target.elements["submit"].disabled=true
        je.preventDefault()
        ss.rpc "user.analyzeScore", (obj)->
            if obj.error?
                Index.util.message "エラー",obj.error
            results=obj.results
            # 陣営色
            teamcolors=merge Shared.game.jobinfo,{}

            results.forEach (x)->   # 陣営チェック
                for team of Shared.game.teams
                    if x.type in Shared.game.teams[team]
                        x.team=team
                        break

                
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
            graph=grp "勝敗ごとの陣営"
            graph.hide()
            # 勝敗を陣営ごとに
            gs=
                win:{}
                lose:{}
            for x of Shared.game.teams
                gs.win[x]={}
                gs.lose[x]={}
            results.forEach (x)->
                console.log x.winner,x.team,gs
                if x.winner==true
                    gs.win[x.team][x.type] ?= 0
                    gs.win[x.team][x.type]++
                else if x.winner==false
                    gs.lose[x.team][x.type] ?= 0
                    gs.lose[x.team][x.type]++
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
                        win:results.filter((x)->x.type==type && x.winner==true).length
                        lose:results.filter((x)->x.type==type && x.winner==false).length
            graph.setData gs,names
            graph.openAnimate 0.2
    ###
    # 称号
    unless user.prizenames?.length>0
        # 称号がない
        $("#prizearea").html "<p>獲得称号はありません。</p>"
    else
        ull=$("#prizes")
        prizedictionary={}  # 称号のidと名前対応
        user.prizenames.forEach (obj)->
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
            console.log JSON.stringify user.nowprize
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
            util.prompt "プロフィール","パスワードを入力して下さい",{type:"password"},(result)->
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

exports.end=->

#Object2つをマージ（obj1ベース）
merge=(obj1,obj2)->
    r=Object.create Object.getPrototypeOf obj1
    [obj1,obj2].forEach (x)->
        Object.getOwnPropertyNames(x).forEach (p)->
            r[p]=x[p]
    r
