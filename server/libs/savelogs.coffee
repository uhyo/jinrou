# functionality to insert logs into games.

# LogSaver should be instantiated fot each Games.
class LogSaver
    constructor:(@game)->
        @pending = []
        @running = false
    saveLog:(log)->
        @pending.push log
        @check()
    # internal apis
    check:()->
        if @pending.length > 0 && @running == false
            @running = true
            process.nextTick ()=>
                @saveIntoDb()
                .then ()=>
                    @running = false
                    @check()
                .catch (err)=>
                    console.error err
    saveIntoDb:()->
        logs = @pending
        @pending = []
        M.games.updateOne({id: @game.id}, {
            $push: {
                logs: {
                    $each: logs
                }
            }
        }, {w: 1})

exports.LogSaver = LogSaver
