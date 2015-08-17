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
                $("#loginerror").text "账号或密码错误。"
    $("#newentryform").submit (je)->
        je.preventDefault()
        form=je.target
        q=
            userid: form.elements["userid"].value
            password: form.elements["password"].value
        ss.rpc "user.newentry", q,(result)->
            if result?.login
                Index.app.setUserid q.userid
                Index.app.showUrl "/my"
            else if result?.error?
                $("#newentryerror").text result.error
