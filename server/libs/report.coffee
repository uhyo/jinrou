# Library for reporting
mailer = require '../mailer.coffee'

# queue of valid report queue
reportQueue = []
# interval of mail sent by report
mailInterval = 10000
# max number of report in queue
maxMailInQueue = 10

#query: {
#  kind: name of one of category
#  content: body of report
#  room: number of room
#}
exports.addReport = (query, userId)->
    return unless validate(query)
    return if reportQueue.length >= maxMailInQueue
    console.log "report", query
    reportQueue.push({
        userId: userId
        kind: query.kind
        content: query.content
        userAgent: query.userAgent
        url: Config.application.url + "room/#{query.room}"
    })
    if reportQueue.length == 1
        runQueue()

validate = (query)->
    unless Config.reportForm.enable
        return false
    unless query?
        return false
    unless Config.reportForm.categories.some((obj)-> obj.name == query.kind)
        return false
    unless "string" == typeof query.content
        return false
    unless 0 < query.content.length <= Config.maxlength.game.comment
        return false
    unless "number" == typeof query.room
        return false
    unless "string" == typeof query.userAgent
        return false
    unless 0 < query.userAgent.length <= Config.maxlength.game.comment
        return false
    return true

runQueue = ->
    query = reportQueue.shift()
    return unless query?

    mailer.sendRawMail Config.reportForm.mail, Config.reportForm.mailSubject, """
userId: #{query.userId ? "?"}
userAgent: #{query.userAgent}
kind: #{query.kind}
url: #{query.url}

#{query.content}
""", (err, info)->
        if err?
            console.error "report form mail error:", err
        else
            console.log "report form mail sent:", info
    # send next mail
    if query.length > 0
        setTimeout runQueue, mailInterval
