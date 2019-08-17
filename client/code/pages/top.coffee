toppage_view = null

exports.start=->
    pi18n = JinrouFront.loadDefaultI18n()
    papp = JinrouFront.loadTopPage()

    Promise.all([pi18n, papp]).then ([i18n, app])->
        toppage_view = app.place {
            i18n: i18n
            node: $("#top-app").get 0
            onLogin: (query)->
                new Promise (resolve)->
                    Index.app.login query.userId, query.password, (result)->
                        if result
                            if query.rememberMe
                                # 記憶
                                localStorage.setItem "userid", query.userId
                                localStorage.setItem "password", query.password
                            Index.app.showUrl "/my"
                            resolve {}
                        else
                            resolve {
                                error: "loginError"
                            }
                            # $("#loginerror").text "ユーザーIDまたはパスワードが違います。"
            onSignup: (query)->
                q=
                    userid: query.userId
                    password: query.password
                new Promise (resolve)->
                    ss.rpc "user.newentry", q,(result)->
                        if result?.error?
                            resolve {
                                error: result.error
                            }
                            return
                        Index.app.processLoginResult query.userId, result, (success)->
                            if success
                                localStorage.setItem "userid", query.userId
                                localStorage.setItem "password", query.password
                                Index.app.showUrl "/my"
                        resolve {}

        }
