nodemailer = require("nodemailer")
crypto = require('crypto')
user=require './rpc/user.coffee'

# create reusable transporter object using the default SMTP transport
transporter = nodemailer.createTransport(Config.smtpConfig)

# setup e-mail data with unicode symbols
mailOptions =
    from: "\"月下人狼\" <#{Config.smtpConfig.from ? Config.smtpConfig.auth.user}>" # sender address


sendConfirmMail=(query,req,res,ss)->
    M.users.findOne {"userid":req.session.userId,"password":user.crpassword(query.password)},(err,record)=>
        if err?
            res {error:"DB err:#{err}"}
            return
        if !record?
            res {error:"ユーザーIDが不正です"}
            return
        query.mail = query.mail.trim()
        if /\w[-\w.+]*@([A-Za-z0-9][-A-Za-z0-9]+\.)+[A-Za-z]{2,14}/.test(query.mail) || query.mail == ""
            mailOptions.to = query.mail
        else
            res {error:"有効なメールアドレスを入力してください"}
            return
        if record.mail?.timestamp? && Date.now() < record.mail.timestamp + 5*60*1000
            res {error:"まだメールアドレスを設定できません。5分以上後に再度お試しください。"}
            return
        # defaults
        mail=
            token:crypto.randomBytes(64).toString('hex')
            timestamp:Date.now()

        # to avoid TypeError: Cannot read property 'address' of undefined
        if !record.mail?
            record.mail =
                address : ""
                verified : false

        # mail address
        if record.mail.address == query.mail
            res {nochange: true}
            return
        # new
        # when the last mail was not confirmed, take it as new
        else if (!record.mail.address || !record.mail.verified) && query.mail
            mail.new = query.mail
            mail.verified = false
            mail.for="confirm"
            mailOptions.subject = "月下人狼：メールアドレスの確認"
        # remove
        else if !query.mail
            # mail address
            mail.address = record.mail.address
            mail.verified = record.mail.verified
            mail.for="remove"
            mailOptions.subject = "月下人狼：メールアドレス削除の確認"
        # change
        else if record.mail.address != query.mail && record.mail.verified
            # mail address
            mail.address = record.mail.address
            mail.new = query.mail
            mail.verified = record.mail.verified
            mail.for="change"
            mailOptions.subject = "月下人狼：メールアドレス変更の確認"
        # why didn't stop? what happened?
        # report bug automatically
        else
            mailOptions.subject = "月下人狼：Bug report"
            mailOptions.to = Config.smtpConfig.auth.user
            mailOptions.text = "query:\n#{JSON.stringify(query)}\n\nrecord.mail:\n#{JSON.stringify(record.mail)}\n"
            mailOptions.html = mailOptions.text
            transporter.sendMail mailOptions, (error, info) ->
                return console.error("nodemailer:",error) if error
                console.log "Message sent: " + info.response
            res {error:"メールアドレス変更に失敗しました。"}
            return
            
        dochange = (err,count)->
            if err?
                res {error:"プロフィール変更に失敗しました"}
                return
            if count.length>=3 && mail.for in ["confirm","change"]
                res {error:"The same mailbox could confirm up to 3 accounts."}
                return
            # write a mail
            if mail.for == 'remove'
                mailOptions.to = mail.address
            else
                mailOptions.to = mail.new
            console.log mail
            mailOptions.text = """#{req.session.userId} 様
このメールアドレス「#{if mail.for=='remove' then mail.address else mail.new}」は、「月下人狼」のアカウント#{if mail.for=='remove' then 'から削除' else 'に登録'}されました。
#{if mail.for=='remove' then '削除' else '登録'}を完了するには、以下のURLにアクセスしてください。URLは1時間の間有効です。
#{Config.application.url}my?token=#{mail.token}&timestamp=#{mail.timestamp}

このメールに心当たりがない場合、このメールを無視し、URLにアクセスしないでください。
このメールは送信専用アドレスから送信されているため、返信いただいても対応いたしかねます。ご了承ください。
"""
            mailOptions.html = """<p>#{req.session.userId} 様</p>
<p>このメールアドレス「#{if mail.for=='remove' then mail.address else mail.new}」は、「月下人狼」のアカウント#{if mail.for=='remove' then 'から削除' else 'に登録'}されました。</p>
<p>#{if mail.for=='remove' then '削除' else '登録'}を完了するには、以下のURLにアクセスしてください。URLは1時間の間有効です。</p>
<p><a href="#{Config.application.url}my?token=#{mail.token}&timestamp=#{mail.timestamp}">#{Config.application.url}my?token=#{mail.token}&timestamp=#{mail.timestamp}</a></p>

<p>このメールに心当たりがない場合、このメールを無視し、URLにアクセスしないでください。</p>
<hr>
<p>このメールは送信専用アドレスから送信されているため、返信いただいても対応いたしかねます。ご了承ください。</p>
"""
            
            console.log mailOptions
            transporter.sendMail mailOptions, (error, info) ->
                return console.error("nodemailer:",error) if error
                console.log "Message sent: " + info.response

            # save to database
            M.users.update {"userid":req.session.userId}, {$set:{mail:mail}},{safe:true},(err,count)=>
                if err?
                    res {error:"プロフィール変更に失敗しました"}
                    return
                delete record.password
                record.mail=
                    address:mail.address
                    new:mail.new
                    verified:mail.verified
                req.session.user = record
                req.session.save ->
                    record.info="メールアドレス#{if mail.for == 'remove' then '削除' else '変更'}のためのメールが 「#{if mail.for=='remove' then mail.address else mail.new}」に送信されました。メールに記載されたURLから処理を完了してください。"
                    res record
            return

        if mail.new?
            # 限制邮箱绑定数
            M.users.find({"mail.address": mail.new}).toArray dochange
        else
            dochange null, []
        return
    return

sendResetMail=(query,req,res,ss)->
    console.log "找回密码"
    M.users.findOne {"userid":query.userid,"mail.address":query.mail,"mail.verified":true},(err,record)=>
        if err?
            res {error:"DB err:#{err}"}
            return
        if !record?
            res {error:"ユーザーIDかメードアドレスが間違っています。"}
            return
        if /\w[-\w.+]*@([A-Za-z0-9][-A-Za-z0-9]+\.)+[A-Za-z]{2,14}/.test(query.mail) || query.mail == ""
            mailOptions.to = query.mail
        else
            res {error:"有効なメールアドレスを入力してください"}
            return
        if record.mail?.timestamp? && Date.now() < record.mail.timestamp + 5*60*1000
            res {error:"まだパスワードの再設定ができません。5分以上後に再度お試しください。"}
            return
        # defaults
        mail=
            token:crypto.randomBytes(64).toString('hex')
            timestamp:Date.now()
        # mail address
        # reset
        mail.address = record.mail.address
        mail.verified = record.mail.verified
        mail.for="reset"
        mail.newpass=user.crpassword(query.newpass)
        mailOptions.subject = "月下人狼：パスワード再設定"
        # write a mail
        mailOptions.to = mail.address
        mailOptions.text = """#{query.userid} 様

「月下人狼」のアカウントのパスワード再設定がリクエストされました。
以下のURLにアクセスして再設定を完了してください。
#{Config.application.url}my?token=#{mail.token}&timestamp=#{mail.timestamp}

このメールに心当たりがない場合、このメールは無視してください。
URLにアクセスしなければ設定は変更されません。

このメールは送信専用アドレスから送信されているため、返信いただいても対応いたしかねます。ご了承ください。
"""

        mailOptions.html = """<p>#{query.userid} 様</p>

<p>「月下人狼」のアカウントのパスワード再設定がリクエストされました。</p>
<p>以下のURLにアクセスして再設定を完了してください。</p>
<p><a href="#{Config.application.url}my?token=#{mail.token}&timestamp=#{mail.timestamp}">#{Config.application.url}my?token=#{mail.token}&timestamp=#{mail.timestamp}</a></p>

<p>このメールに心当たりがない場合、このメールは無視してください。</p>
<p>URLにアクセスしなければ設定は変更されません。</p>
<hr>
<p>このメールは送信専用アドレスから送信されているため、返信いただいても対応いたしかねます。ご了承ください。</p>
"""
            
        console.log mailOptions
        transporter.sendMail mailOptions, (error, info) ->
            return console.error(error) if error
            console.log "Message sent: " + info.response

        # save to database
        M.users.update {"userid":query.userid}, {$set:{mail:mail}},{safe:true},(err,count)=>
            if err?
                res {error:"プロフィール変更に失敗しました"}
                return
            delete record.password
            record.info="「#{query.mail}」にパスワード再設定用のメールを送信しました。メールの指示に従って再設定を完了してください。"
            record.mail=
                address:mail.address
                verified:mail.verified
            res record
        return

    
exports.sendConfirmMail=sendConfirmMail
exports.sendResetMail=sendResetMail
