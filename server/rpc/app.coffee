libreport = require '../libs/report.coffee'

exports.actions=(req,res,ss)->
    req.use 'session'
    # 外部URLを教えてあげる
    backdoor:(name)->
        res Config.backdoor[name]
    # configを教えてあげる
    applicationconfig:->
        res {
            application: Config.application
            language: Config.language
            # send reportForm but hide mail address.
            reportForm: Object.assign({}, Config.reportForm, {
                maxLength: Config.maxlength.game.comment
                mail: null
            })
            shareButton: Config.shareButton
        }
    # 報告フォーム
    reportForm:(query)->
        libreport.addReport query, req.session?.userId
        res {}


