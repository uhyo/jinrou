
# Class that knows time of next special event.
class TimeKeeper
    # returns most resent event.
    @mostRecent:(times...)->
        min = Infinity
        result = null
        for k in times
            ktime = k.goal.getTime()
            if k.goal.getTime() < min
                min = ktime
                result = k
        return result
    constructor:(@type, callback)->
        @timerid = null
        @goal = callback()
    # returns whether current time (plus offset in seconds)
    # is beyond the goal.
    isOver:(offsetInSeconds = 0)->
        base = Date.now() + offsetInSeconds * 1000
        return @goal.getTime() <= base
    # returns a time offset in milliseconds to goal from now.
    getOffset:->
        @goal.getTime() - Date.now()
    # set a timer fired at the goal time.
    setTimer:(callback, args...)->
        @timerid = setTimeout callback.bind(null, this, args...), @getOffset()
    # clear a timer.
    clearTimer:->
        clearTimeout @timerid


exports.TimeKeeper = TimeKeeper
