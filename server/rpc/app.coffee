# Server-side Code

exports.actions=(req,res,ss)->
    # 外部URLを教えてあげる
    backdoor:(name)->
        res Config.backdoor[name]
    # configを教えてあげる
    applicationconfig:->
        res Config.application

  
