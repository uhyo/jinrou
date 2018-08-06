app=require '/app'
util=require '/util'
exports.showWindow=showWindow=(templatename,tmpl)->
    de = document.documentElement
    bd = document.body
    sclf = bd.scrollLeft || de.scrollLeft
    sctp = bd.scrollTop || de.scrollTop
    x=Math.max 50,sclf+Math.floor(Math.random()*100-200+document.documentElement.clientWidth/2)
    y=Math.max 50,sctp+Math.floor(Math.random()*100-200+document.documentElement.clientHeight/2)

    # iconはspecialにhandleする
    unless tmpl?
        tmpl = {}
    tmpl.title ?= ""
    tmpl.icon = makeIconHTML tmpl.icon

    win=$(JT["#{templatename}"](tmpl)).hide().css({left:"#{x}px",top:"#{y}px",}).appendTo("body").fadeIn().draggable()
    $(".getfocus",win.get(0)).focus()
    win

makeIconHTML = (icon)->
    unless icon?
        return ''
    if 'string' == typeof icon
        return FontAwesome.icon({iconName: icon}).html
    if icon instanceof Array
        result = "<span class='fa-stack'>"
        for name in icon
            result += FontAwesome.icon({iconName: name}).html
        result += "</span>"
        return result
    return ''




#編集域を返す
exports.blankWindow=(options, onclose)->
    win=showWindow "util-blank", options
    div=document.createElement "div"
    div.classList.add "window-content"
    $("form[name='okform']",win).before div
    win.submit (je)-> je.preventDefault()
    win.click (je)->
        t=je.target
        while t?
            if t.name=="ok"
                closeWindow t
                onclose?()
                break
            t = t.parentNode
    $(div)
    

#要素を含むWindowを消す
exports.closeWindow=closeWindow= (node)->
    w=$(node).closest(".window")
    w.hide "normal",-> w.remove()
    w.triggerHandler "close.window"
    
exports.formQuery=(form)->
    q={}
    el=form.elements
    for e in el
        if !e.disabled && e.name
            if (tag=e.tagName.toLowerCase())=="input"
                if e.type in ["radio","checkbox"]
                    if e.checked
                        q[e.name]=e.value
                else if e.type!="submit" && e.type!="reset" && e.type!="button"
                    q[e.name]=e.value
            else if tag in["select","output","textarea"]
                q[e.name]=e.value
    q
#true,false
exports.ask=(title,message,cb)->
    win = showWindow "util-ask",{title:title,message:message}
    win.submit (je)-> je.preventDefault()
    win.click (je)->
        t=je.target
        while t?
            if t.name=="yes"
                cb true
                closeWindow t
                break
            else if t.name=="no"
                cb false
                closeWindow t
                break
            t = t.parentNode
#String / null
exports.prompt=(title,message,opt,cb)->
    win = showWindow "util-prompt",{title:title,message:message}
    inp=win.find("input.prompt").get(0)
    for opv of opt
        inp[opv]=opt[opv]
    win.submit (je)-> je.preventDefault()
    win.click (je)->
        t=je.target
        while t?
            if t.name=="ok"
                cb? inp.value
                closeWindow t
                break
            else if t.name=="cancel"
                cb? null
                closeWindow t
                break
            t = t.parentNode

#arr: [{name:"aaa",value:"foo"}, ...]
exports.selectprompt=(options,cb)->
    {
        title,
        message,
        options: arr,
        icon,
    } = options

    win = showWindow "util-selectprompt",{
        title: title
        message: message
        icon: icon
    }
    sel=win.find("select.prompt").get(0)
    for obj in arr
        opt=document.createElement "option"
        opt.textContent=obj.name
        opt.value=obj.value
        sel.add opt
    win.submit (je)-> je.preventDefault()
    win.click (je)->
        t=je.target
        while t?
            if t.name=="ok"
                cb? sel.value
                closeWindow t
                break
            else if t.name=="cancel"
                cb? null
                closeWindow t
                break
            t = t.parentNode
exports.kickprompt=(options,cb)->
    {
        title,
        message,
        options: arr,
        icon,
    } = options

    win = showWindow "util-kick",{
        title: title ? "追い出す"
        message: message ? "追い出す人を選択してください"
        icon: icon ? 'user-times'
    }
    sel=win.find("select.prompt").get(0)
    for obj in arr
        opt=document.createElement "option"
        opt.textContent=obj.name
        opt.value=obj.value
        sel.add opt
    win.submit (je)-> je.preventDefault()
    win.click (je)->
        t=je.target
        while t?
            if t.name=="ok"
                cb? {
                    value: sel.value
                    ban: win.find('input[name="noentry"]').get(0).checked
                }
                closeWindow t
                break
            else if t.name=="cancel"
                cb? null
                closeWindow t
                break
            else if t.name=="list"
                cb? {
                    list: true
                }
                closeWindow t
                break
            t = t.parentNode

exports.message=(title,message,cb)->
    win = showWindow "util-wmessage",{title:title,message:message}
    win.submit (je)-> je.preventDefault()
    win.click (je)->
        t=je.target
        while t?
            if t.name=="ok"
                cb? true
                closeWindow t
                break
            t = t.parentNode
exports.loginWindow=(cb=->app.refresh())->
    win = showWindow "util-login"
    win.click (je)->
        t=je.target
        while t?
            if t.name=="cancel"
                closeWindow win
                break
            t = t.parentNode
    $("#loginform").submit (je)->
        je.preventDefault()
        form=je.target
        app.login form.elements["userid"].value, form.elements["password"].value,(result)->
            if result
                if form.elements["remember_me"].checked
                    # 記憶
                    localStorage.setItem "userid",form.elements["userid"].value
                    localStorage.setItem "password", form.elements["password"].value
                cb()
                closeWindow win
            else
                $("#loginerror").text "ユーザーIDまたはパスワードが違います。"
    $("#newentryform").submit (je)->
        je.preventDefault()
        form=je.target
        q=
            userid: form.elements["userid"].value
            password: form.elements["password"].value
        ss.rpc "user.newentry",q,(result)->
            unless result.login
                $("#newentryerror").text result
            else
                localStorage.setItem "userid",q.userid
                localStorage.setItem "password", q.password
                closeWindow win
                # 初期情報を入力してもらう
                util.blindName {title:"情報入力",message:"ユーザー名を設定してください"},(obj)->
                    # 登録する感じの
                    ss.rpc "user.changeProfile", {
                        password:q.password
                        name:obj.name
                        icon:obj.icon
                    },(obj)->
                        if obj?.error?
                            #エラー
                            util.message "エラー",obj.error
                        else
                            util.message "登録","登録が完了しました。"
                            app.setUserid q.userid
                            cb()

exports.iconSelectWindow=(def,cb)->
    win = showWindow "util-iconselect"
    form=$("#iconform").get 0
    # アイコン決定
    okicon=(url)->
        setHTTPSicon $("#selecticondisp").get(0), url
        def=url # 書き換え
        
    okicon def  # さいしょ
    win.click (je)->
        t=je.target
        while t?
            if t.name=="cancel"
                closeWindow win
                cb def  # 変わっていない
                break
            else if t.name=="urliconbutton"
                util.prompt "アイコン","アイコンのURLを入力してください",null,(url)->
                    okicon url ? ""
                break
            else if t.name=="twittericonbutton"
                util.prompt "アイコン","twitterIDを入力してください",null,(id)->
                    if id
                        # It's 1.0!
                        # okicon "http://api.twitter.com/1/users/profile_image/#{id}"
                        ss.rpc "user.getTwitterIcon",id,(url)->
                            # アイコンを取得
                            unless url
                                util.message "エラー","アイコンを取得できませんでした。しばらく時間をあけてからお試しください。"
                                okicon ""
                            else
                                okicon url
                    else
                        okicon ""
                break
            t = t.parentNode
    $("#iconform").submit (je)->
        je.preventDefault()
        closeWindow win
        cb def  #結果通知
exports.blindName=(opt={},cb)->
    win = showWindow "util-blindname",{
        title:opt.title ? "ゲームに参加"
        message:opt.message ? "名前を入力してください"
        icon: "user-secret"
    }
    def=null
    win.click (je)->
        t=je.target
        while t?
            if t.name=="cancel"
                closeWindow win
                cb null # 変わっていない
                break
            else if t.name=="iconselectbutton"
                util.iconSelectWindow null,(url)->
                    def=url ? null
                    $("#icondisp").attr "src",def
                break
            t = t.parentNode
    $("#nameform").submit (je)->
        je.preventDefault()
        closeWindow win
        cb {name:je.target.elements["name"].value, icon:def}
    
        

# Dateをtime要素に
exports.timeFromDate=(date)->
    zero2=(num)->
        "00#{num}".slice -2 # 0埋め
    dat="#{date.getFullYear()}-#{zero2(date.getMonth()+1)}-#{zero2(date.getDate())}"
    tim="#{zero2(date.getHours())}:#{zero2(date.getMinutes())}:#{zero2(date.getSeconds())}"
    time=document.createElement "time"
    time.datetime="#{dat}T#{tim}+09:00"
    time.textContent="#{dat} #{tim}"
    time

# search文字列をdictに
exports.searchHash=(search)->
    result = {}
    arr = search.slice(1).split '&'
    for chunk in arr
        continue unless chunk
        [key, value] = chunk.split '='
        result[decodeURIComponent key] = decodeURIComponent(value ? 'on')
    return result
exports.hashSearch=(hash)->
    arr = []
    for key, value of hash
        arr.push "#{encodeURIComponent key}=#{encodeURIComponent value}"
    if arr.length == 0
        return ''
    else
        return "?#{arr.join '&'}"

# HTTPS優先iconを表示
exports.setHTTPSicon = setHTTPSicon = (img, url, cacheObject)->
    if cacheObject?[url]?
        # If this url is already cached, use it.
        img.src = cacheObject?[url]
        return
    original_url = url
    # HTTPSに直す
    if /^http:/.test url
        url = "https:" + url.slice 5
        # HTTPSがエラーだったらHTTPになる
        handler1 = (ev)->
            img.removeEventListener "error", handler1, false
            img.removeEventListener "load", handler2, false
            cacheObject?[original_url] = original_url
            img.src = original_url
        handler2 = ()->
            img.removeEventListener "error", handler1, false
            img.removeEventListener "load", handler2, false
            cacheObject?[original_url] = url
        img.addEventListener "error", handler1, false
        img.addEventListener "load", handler2, false
    # URLをset
    img.src = url

# Font Awesomeアイコンを一時的にloadingに変える
exports.LoadingIcon = class LoadingIcon
    constructor:(@icon)->
        # spinnerアイコンを作成
        @newicon = FontAwesome.icon({iconName: 'spinner'}, {
            classes: ['fa-fw', 'fa-pulse', 'fa-spinner']
        }).node[0]
    start:()->
        # 一時的に古いアイコンを隠す
        @icon.parentNode.replaceChild @newicon, @icon
    stop:()->
        # 戻す
        @newicon.parentNode.replaceChild @icon, @newicon

#突然死の罰
exports.punish=(title,message,cb)->
    win = showWindow "util-punish",{title:title,time:message.time}
    for user in message.userlist
        a = document.createElement "input"
        a.type="checkbox"
        a.name="userList"
        a.class="punish"
        a.value=user.userid
        b = document.createElement "label"
        $(b).append(a).append(user.name)
        $("#prePunishUser").append(b).append("<br>")

    ipt =->
        user=document.punish.userList;
        userChecked=[];
        if !user[0]
            a=[]
            a.push user
            user=a
        for pl in user
            if pl.checked then userChecked.push pl.value
        userChecked
    win.submit (je)-> je.preventDefault()
    win.click (je)->
        t=je.target
        if t.name=="ok"
            cb? ipt()
            closeWindow t
        else if t.name=="cancel"
            # cb? null
            closeWindow t
