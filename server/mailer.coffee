nodemailer = require("nodemailer")
crypto = require('crypto')
user=require './rpc/user.coffee'

# create reusable transporter object using the default SMTP transport
transporter = nodemailer.createTransport(Config.smtpConfig)

# setup e-mail data with unicode symbols
mailOptions =
    from: "\"月下人狼\" <#{Config.smtpConfig.auth.user}>" # sender address


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
            res {error:"後で5分をお試しください。"}
            return
        # defaults
        mail=
            token:crypto.randomBytes(64).toString('hex')
            timestamp:Date.now()

        # to avoid TypeError: Cannot read property 'address' of undefined
        if !record.mail?
            record.mail = 
                address = ""
                verified = false

        # mail address
        if record.mail.address == query.mail
            res {error:"メールアドレスは変更されません。"}
            return
        # new
        # when the last mail was not confirmed, take it as new
        else if (!record.mail.address || !record.mail.verified) && query.mail
            mail.address = query.mail
            mail.verified = false
            mail.for="confirm"
            mailOptions.subject = "月下人狼：Confirm Your Email Address"
        # remove
        else if !query.mail
            # mail address
            mail.address = record.mail.address
            mail.verified = record.mail.verified
            mail.for="remove"
            mailOptions.subject = "月下人狼：Remove Your Email Address"
        # change
        else if record.mail.address != query.mail && record.mail.verified
            # mail address
            mail.address = record.mail.address
            mail.new = query.mail
            mail.verified = record.mail.verified
            mail.for="change"
            mailOptions.subject = "月下人狼：Change Your Email Address"
            
        console.log mail
        # 限制邮箱绑定数
        M.users.find({"mail.address":mail.address}).toArray (err,count)->
            if err?
                res {error:"プロフィール変更に失敗しました"}
                return
            console.log count.length
            if count.length>=3 && mail.for in ["confirm","change"]
                res {error:"The same mailbox could confirm up to 3 accounts."}
                return
            # write a mail
            mailOptions.to = mail.address
            console.log mail
            mailOptions.text = "Hi #{req.session.userId}, \nYou are #{if mail.for=='remove' then 'removing' else 'confirming'} 「#{if mail.for=='change' then mail.new else mail.address}」 for your 「月下人狼」Account.\nClick the link below to confirm/remove your Email Address, this link will be available in 1 hour:\n#{Config.application.url}my?token=#{mail.token}&timestamp=#{mail.timestamp}\n\nIf you did not request this, you can ignore this email and your nothing will be changed.\nこのメールは送信専用のため返信いただいても対応いたしかねます。ご了承ください。"
            mailOptions.html = "<h1>月下人狼：Confirm Your Email Address</h1><p>Hi #{req.session.userId}, </p><p>You are #{if mail.for=='remove' then 'removing' else 'confirming'} 「#{if mail.for=='change' then mail.new else mail.address}」 for your 「月下人狼」Account.</p><p>Click the link below to confirm/remove your Email Address, this link will be available in 1 hour:</p><p><a href=\"#{Config.application.url}my?token=#{mail.token}&timestamp=#{mail.timestamp}\">#{Config.application.url}my?token=#{mail.token}&timestamp=#{mail.timestamp}</a></p><p></p><p>If you did not request this, you can ignore this email and your nothing will be changed.</p><p>このメールは送信専用のため返信いただいても対応いたしかねます。ご了承ください。</p>"
            
            transporter.sendMail mailOptions, (error, info) ->
                return console.error(error) if error
                console.log "Message sent: " + info.response

            # save to database
            M.users.update {"userid":req.session.userId}, {$set:{mail:mail}},{safe:true},(err,count)=>
                if err?
                    res {error:"プロフィール変更に失敗しました"}
                    return
                delete record.password
                record.info="The confirm mail was sent to 「#{mail.address}」, please check your mailbox."
                record.mail=
                    address:mail.address
                    verified:mail.verified
                res record
            return
        return
    return

sendResetMail=(query,req,res,ss)->
    console.log "找回密码"
    M.users.findOne {"userid":query.userid,"mail.address":query.mail,"mail.verified":true},(err,record)=>
        if err?
            res {error:"DB err:#{err}"}
            return
        if !record?
            res {error:"UserID or mailbox is incorrect, or the mailbox is not Confirmed."}
            return
        if /\w[-\w.+]*@([A-Za-z0-9][-A-Za-z0-9]+\.)+[A-Za-z]{2,14}/.test(query.mail) || query.mail == ""
            mailOptions.to = query.mail
        else
            res {error:"有効なメールアドレスを入力してください"}
            return
        if record.mail?.timestamp? && Date.now() < record.mail.timestamp + 5*60*1000
            res {error:"後で5分をお試しください。"}
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
        mailOptions.subject = "月下人狼：Reset Your Password"
        # write a mail
        mailOptions.to = mail.address
        mailOptions.text = "Hi #{query.userid}, \nYou are reseting the password of your 「月下人狼」 Account by #{query.mail}.\nClick the link below to reset the password, this link will be available in 1 hour:\n<a href=\"#{Config.application.url}my?token=#{mail.token}&timestamp=#{mail.timestamp}\">#{Config.application.url}my?token=#{mail.token}&timestamp=#{mail.timestamp}</a><\n\nIf you did not request this, you can ignore this email and your nothing will be changed.\nこのメールは送信専用のため返信いただいても対応いたしかねます。ご了承ください。\n"

        mailOptions.html = "<h1>月下人狼：Reset Your Password</h1><p>Hi #{query.userid}, </p><p>You are reseting the password of your 「月下人狼」 Account by #{query.mail}.</p><p>Click the link below to reset the password, this link will be available in 1 hour:</p><p><a href=\"#{Config.application.url}my?token=#{mail.token}&timestamp=#{mail.timestamp}\">#{Config.application.url}my?token=#{mail.token}&timestamp=#{mail.timestamp}</a></p><p></p><p>If you did not request this, you can ignore this email and your nothing will be changed.</p><p>このメールは送信専用のため返信いただいても対応いたしかねます。ご了承ください。</p>"
            
        transporter.sendMail mailOptions, (error, info) ->
            return console.error(error) if error
            console.log "Message sent: " + info.response

        # save to database
        M.users.update {"userid":query.userid}, {$set:{mail:mail}},{safe:true},(err,count)=>
            if err?
                res {error:"プロフィール変更に失敗しました"}
                return
            delete record.password
            record.info="The reset mail was sent to 「#{query.mail}」 , please check your mailbox."
            record.mail=
                address:mail.address
                verified:mail.verified
            res record
        return

    
exports.sendConfirmMail=sendConfirmMail
exports.sendResetMail=sendResetMail