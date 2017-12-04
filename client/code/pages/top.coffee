exports.start=->
    $("#loginform").submit (je)->
        je.preventDefault()
        form=je.target
        Index.app.login form.elements["userid"].value, form.elements["password"].value,(result)->
            if result
                if form.elements["remember_me"].checked
                    # 記憶
                    localStorage.setItem "userid",form.elements["userid"].value
                    localStorage.setItem "password", form.elements["password"].value
                Index.app.showUrl "/my"
            else
                $("#loginerror").text "ユーザーIDまたはパスワードが違います。"
    $("#newentryform").submit (je)->
        je.preventDefault()
        form=je.target
        uid = form.elements["userid"].value
        pass = form.elements["password"].value
        q=
            userid: uid
            password: pass
        ss.rpc "user.newentry", q,(result)->
            if result?.error?
                $("#newentryerror").text result.error
                return
            Index.app.processLoginResult uid, result, (success)->
                if success
                    localStorage.setItem "userid", uid
                    localStorage.setItem "password", pass
                    Index.app.showUrl "/my"
