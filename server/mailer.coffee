nodemailer = require("nodemailer")
crypto = require('crypto')
user=require './rpc/user.coffee'
auth=require './auth.coffee'

# create reusable transporter object using the default SMTP transport
transporter = nodemailer.createTransport(Config.smtpConfig)

# setup e-mail data with unicode symbols
mailOptions =
    from: "\"月下人狼\" <#{Config.smtpConfig.from ? Config.smtpConfig.auth.user}>" # sender address

# ユーザーにメールを送る
sendMail=(userquery, makemailobj, callback)->
    M.users.findOne userquery, (err, record)->
        if err?
            callback "DB err:#{err}", null
            return
        if !record?
            callback "ユーザー情報に誤りがあります", null
            return
        if record.mail?.timestamp? && Date.now() < record.mail.timestamp + 5*60*1000
            callback "まだメールによる確認を行えません。5分以上後に再度お試しください。", null
            return

        # tokenを生成
        token = crypto.randomBytes(64).toString('hex')
        timestamp = Date.now()

        # default mail object saved in user
        mail =
            token: token
            timestamp: timestamp

        # to avoid TypeError: Cannot read property 'address' of undefined
        if !record.mail?
            record.mail =
                address : ""
                verified : false


        obj = makemailobj record, mail
        if !obj?
            callback "?", null
            return
        if obj.error?
            callback obj.error, null
            return
        mail = obj.mail
        options = obj.options
        for key, value of mailOptions
            try
                options[key] = value
            catch e
                options={}
                options[key] = value

        if !mail?
            # 送る必要がない
            callback null, {nochange: true}
            return
        if mail.error?
            # why didn't stop? what happened?
            # report bug automatically
            mailOptions.subject = "月下人狼：Bug report"
            mailOptions.to = Config.smtpConfig.from ? Config.smtpConfig.auth.user
            # mailOptions.text = "query:\n#{JSON.stringify(query)}\n\nrecord.mail:\n#{JSON.stringify(record.mail)}\n"
            mailOptions.text = String(mail.error)
            mailOptions.html = mailOptions.text
            transporter.sendMail mailOptions, (error, info) ->
                return console.error("nodemailer:",error) if error
                console.log "Message sent: " + info.response
            callback "処理に失敗しました。"
            return

        dochange = (err, count)->
            if err?
                callback "処理に失敗しました。", null
                return
            if count.length>=3 && mail.for in ["confirm", "change"]
                callback "The same mailbox could confirm up to 3 accounts.", null
                return

            console.log options
            transporter.sendMail options, (err, info)->
                if err?
                    console.error "nodemailer:", err
                    return
                console.log "Message sent: " + info.response
            # save to database
            M.users.update userquery, {
                $set: {
                    mail: mail
                }
            }, {safe: true}, (err, count)->
                if err?
                    callback "処理に失敗しました。", null
                    return
                delete record.password
                record.mail=
                    address: mail.address
                    new: mail.new
                    verified: mail.verified
                    for: mail.for

                callback null, record

        if mail.new?
            M.users.find({"mail.address": mail.new}).toArray dochange
        else
            dochange null, []

# raw API for other server systems
exports.sendRawMail = (to, subject, body, callback)->
    options =
        from: "\"月下人狼\" <#{Config.smtpConfig.from ? Config.smtpConfig.auth.user}>"
        subject: subject
        to: to
        text: body
    transporter.sendMail options, callback

sendConfirmMail=(query, req, res, ss)->
    unless /\w[-\w.+]*@([A-Za-z0-9][-A-Za-z0-9]+\.)+[A-Za-z]{2,14}/.test(query.mail) || query.mail == ""
        res {error:"有効なメールアドレスを入力してください"}
        return

    userquery =
        userid: req.session.userId
    makemailobj = (record, mail)->
        options = {}
        if record.mailconfirmsecurity
            return {
                error: "メールアドレスがロックされているため、変更できません。"
            }
        if record.mail.address == query.mail
            return {
                mail: null
                options: null
            }
        else if (!record.mail.address || !record.mail.verified) && query.mail
            mail.new = query.mail
            mail.verified = false
            mail.for = "confirm"

            options.to = mail.new
            options.subject = "月下人狼: メールアドレスの確認"
        else if !query.mail
            mail.address = record.mail.address
            mail.verified = record.mail.verified
            mail.for = "remove"

            options.to = mail.address
            options.subject = "月下人狼: メールアドレス削除の確認"
        else if record.mail.address != query.mail && record.mail.verified
            mail.address = record.mail.address
            mail.new = query.mail
            mail.verified = record.mail.verified
            mail.for="change"

            options.to = mail.new
            options.subject = "月下人狼: メールアドレス変更の確認"
        else
            # ?????
            mail.error = "query:\n#{JSON.stringify(query)}\n\nrecord.mail:\n#{JSON.stringify(record.mail)}\n"
            return {
                mail: mail
                options: {}
            }

        options.text = """#{req.session.userId} 様
このメールアドレス「#{if mail.for=='remove' then mail.address else mail.new}」は、「月下人狼」のアカウント#{if mail.for=='remove' then 'から削除' else 'に登録'}されました。
#{if mail.for=='remove' then '削除' else '登録'}を完了するには、以下のURLにアクセスしてください。URLは1時間の間有効です。
#{Config.application.url}my?token=#{mail.token}&timestamp=#{mail.timestamp}

このメールに心当たりがない場合、このメールを無視し、URLにアクセスしないでください。
このメールは送信専用アドレスから送信されているため、返信いただいても対応いたしかねます。ご了承ください。
"""
        options.html = """<p>#{req.session.userId} 様</p>
<p>このメールアドレス「#{if mail.for=='remove' then mail.address else mail.new}」は、「月下人狼」のアカウント#{if mail.for=='remove' then 'から削除' else 'に登録'}されました。</p>
<p>#{if mail.for=='remove' then '削除' else '登録'}を完了するには、以下のURLにアクセスしてください。URLは1時間の間有効です。</p>
<p><a href="#{Config.application.url}my?token=#{mail.token}&timestamp=#{mail.timestamp}">#{Config.application.url}my?token=#{mail.token}&timestamp=#{mail.timestamp}</a></p>

<p>このメールに心当たりがない場合、このメールを無視し、URLにアクセスしないでください。</p>
<hr>
<p>このメールは送信専用アドレスから送信されているため、返信いただいても対応いたしかねます。ご了承ください。</p>
"""
        return {
            mail: mail
            options: options
        }


    sendMail userquery, makemailobj, (err, record)->
        if err?
            res {error: String(err)}
            return
        if record.nochange
            res record
            return

        req.session.user = record
        req.session.save ->
            record.info="メールアドレス#{if record.mail.for == 'remove' then '削除' else '変更'}のためのメールが 「#{if record.mail.for=='remove' then record.mail.address else record.mail.new}」に送信されました。メールに記載されたURLから処理を完了してください。"
            res record

sendResetMail = (query, req, res, ss)->
    userquery =
        userid: query.userid
        "mail.address": query.mail
        "mail.verified": true
    makemailobj = (record, mail)->
        mail.address = record.mail.address
        mail.verified = record.mail.verified
        mail.for = "reset"
        mail.newsalt = auth.gensalt()
        mail.newpass = auth.crpassword query.newpass, mail.newsalt
        options =
            to: mail.address
            subject: "月下人狼: パスワード再設定"

        options.text = """#{query.userid} 様

「月下人狼」のアカウントのパスワード再設定がリクエストされました。
以下のURLにアクセスして再設定を完了してください。
#{Config.application.url}my?token=#{mail.token}&timestamp=#{mail.timestamp}

このメールに心当たりがない場合、このメールは無視してください。
URLにアクセスしなければ設定は変更されません。

このメールは送信専用アドレスから送信されているため、返信いただいても対応いたしかねます。ご了承ください。
"""
        options.html = """<p>#{query.userid} 様</p>

<p>「月下人狼」のアカウントのパスワード再設定がリクエストされました。</p>
<p>以下のURLにアクセスして再設定を完了してください。</p>
<p><a href="#{Config.application.url}my?token=#{mail.token}&timestamp=#{mail.timestamp}">#{Config.application.url}my?token=#{mail.token}&timestamp=#{mail.timestamp}</a></p>

<p>このメールに心当たりがない場合、このメールは無視してください。</p>
<p>URLにアクセスしなければ設定は変更されません。</p>
<hr>
<p>このメールは送信専用アドレスから送信されているため、返信いただいても対応いたしかねます。ご了承ください。</p>
"""
        return {
            mail: mail
            options: options
        }



    sendMail userquery, makemailobj, (err, record)->
        if err?
            res {error: String(err)}
            return
        record.info="「#{query.mail}」にパスワード再設定用のメールを送信しました。メールの指示に従って再設定を完了してください。"

        res record



sendMailconfirmsecurityMail=(query,req,res,ss)->
    userquery =
        userid: query.userid
    makemailobj = (record, mail)->
        mail.address = record.mail.address
        mail.verified = record.mail.verified
        mail.for = "mailconfirmsecurity-off"
        options =
            to: mail.address
            subject: "月下人狼: 設定変更の確認"

        options.text = """#{query.userid} 様

「月下人狼」の設定「パスワード・メールアドレスをロック」の解除がリクエストされました。
この設定変更を完了するには、以下のURLにアクセスしてください。
#{Config.application.url}my?token=#{mail.token}&timestamp=#{mail.timestamp}

このメールに心当たりがない場合、このメールは無視してください。
URLにアクセスしなければ設定は変更されません。

このメールは送信専用アドレスから送信されているため、返信いただいても対応いたしかねます。ご了承ください。
"""
        options.html = """<p>#{query.userid} 様</p>

<p>「月下人狼」の設定「パスワード・メールアドレスをロック」の解除がリクエストされました。</p>
<p>この設定変更を完了するには、以下のURLにアクセスしてください。</p>
<p><a href="#{Config.application.url}my?token=#{mail.token}&timestamp=#{mail.timestamp}">#{Config.application.url}my?token=#{mail.token}&timestamp=#{mail.timestamp}</a></p>

<p>このメールに心当たりがない場合、このメールは無視してください。</p>
<p>URLにアクセスしなければ設定は変更されません。</p>
<hr>
<p>このメールは送信専用アドレスから送信されているため、返信いただいても対応いたしかねます。ご了承ください。</p>
"""
        return {
            mail: mail
            options: options
        }

    sendMail userquery, makemailobj, (err, record)->
        if err?
            res {error: String(err)}
            return
        record.info="「#{record.mail.address}」に設定変更用のメールを送信しました。メールの指示に従って設定変更を完了してください。"

        res record


exports.sendConfirmMail=sendConfirmMail
exports.sendResetMail=sendResetMail
exports.sendMailconfirmsecurityMail=sendMailconfirmsecurityMail
