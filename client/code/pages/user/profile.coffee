#page module?
app=require '/app'
util=require '/util'

name_length_max=20
mypage_view = null

exports.start=(user)->
    dialog = JinrouFront.loadDialog()

    pi18n = app.getI18n()
    papp = JinrouFront.loadMyPage()

    Promise.all([pi18n, papp]).then(([i18n, japp])->
        japp.place {
            i18n: i18n
            node: $("#mypage-app").get 0
        }
    ).then (v)->
        mypage_view = v


    seticon=(url)->
        util.setHTTPSicon $("#myicon").get(0), url
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

        dialog.then (dialog)->
            dialog.showPromptDialog({
                modal: true
                password: true
                autocomplete: "current-password"
                title: "プロフィール"
                message: "パスワードを入力してください"
                ok: "OK"
                cancel: "キャンセル"
            }).then (result)->
                if result
                    q.password=result
                    pf = ()=>
                        ss.rpc "user.changeProfile", q,(result)->
                            if result.error?
                                dialog.showErrorDialog {
                                    modal: true
                                    message: String result.error
                                }
                            else
                                app.page "user-profile",result,Index.user.profile,result
                    if q.mail?
                        ss.rpc "user.sendConfirmMail", q,(result)->
                            if result.error?
                                dialog.showErrorDialog {
                                    modal: true
                                    message: String result.error
                                }
                            else
                                pf()
                            if result.info?
                                dialog.showMessage {
                                    modal: true
                                    title: "通知"
                                    message: result.info
                                    ok: "OK"
                                }
                    else
                        pf()

    $("#mailconfirmsecuritybutton").click (je)->
        je.preventDefault()
        ss.rpc "user.changeMailconfirmsecurity", {
            mailconfirmsecurity: je.target.form.elements["mailconfirmsecurity"].checked
        }, (result)->
            if result?.error?
                dialog.then (dialog)->
                    dialog.showErrorDialog {
                        modal: true
                        message: String result.error
                    }
            else
                dialog.then (dialog)->
                    dialog.showMessageDialog {
                        modal: true
                        title: "通知"
                        message: result.info
                        ok: "OK"
                    }
                app.page "user-profile", result, Index.user.profile, result

    $("#changepasswordbutton").click (je)->
        $("#changepassword").get(0).hidden=false
        $("#changepassword").submit (je)->
            je.preventDefault()
            ss.rpc "user.changePassword", Index.util.formQuery(je.target),(result)->
                if result?.error?
                    dialog.then (dialog)->
                        dialog.showErrorDialog {
                            modal: true
                            message: String result.error
                        }
                else
                    dialog.then (dialog)->
                        dialog.showMessageDialog {
                            modal: true
                            title: "通知"
                            message: "パスワードを変更しました。"
                            ok: "OK"
                        }
                    $("#changepassword").get(0)?.hidden=true
                    app.page "user-profile",result,Index.user.profile,result

    $("#changeprofile").get(0).elements["twittericonbutton"].addEventListener "click",((e)->
        dialog.then (dialog)->
            dialog.showIconSelectDialog({
                modal: true
            }).then (url)->
                seticon (url ? "")
    ),false

    $("#changeprofile").get(0).elements["colorsettingbutton"].addEventListener "click",(e)->
        # 移動
        app.showUrl "/my/settings"
    ,false

    # 称号
    if user.prizeNumber > 0
        $("#prizenumber").text user.prizeNumber
    if user.nowprizeData
        nowprizeb = $("<b />").text user.nowprizeData
        $("#current-prize").text("現在の肩書き：").append nowprizeb
    else
        $("#current-prize").text "まだ肩書きは設定されていません。"

    Index.game.rooms.start({
        noLinks: true
    })    # ルーム一覧を表示してもらう
    # お知らせ一覧を取得する
    ss.rpc "user.getNews",(docs)->
        if docs.error?
            # ?
            console.error docs.error
            return
        table=$("#newslist").get 0
        unless table?
            # page may already have gone.
            return
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
    mypage_view?.unmount()
    Index.game.rooms.end()
