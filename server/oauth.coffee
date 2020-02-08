request = require "request"
# OAuth twitter client

Twitter = require 'twitter'
twit = new Twitter({
    consumer_key:Config.twitter.oauth.consumerKey,
    consumer_secret:Config.twitter.oauth.consumerSecret,
    access_token_key:Config.twitter.oauth.accessToken,
    access_token_secret:Config.twitter.oauth.accessTokenSecret,
})

class RateLimits
    constructor:->
        # whether each api is suspended for now.
        @suspended =
            tweet: false
            icon: false
    isSuspended:(type)-> @suspended[type]
    # examine an error response from Twitter.
    examineError: (type, err, raw)->
        unless Array.isArray(err)
            return
        if @suspended[type]
            # it is already suspended; nothing to do.
            return
        # check that err includes rate limit exceeded error.
        if err.some((obj)-> obj.code == 88)
            # suspend this type of request.
            @suspended[type] = true
            console.log "RateLimits: #{type} is suspended"
            # check the remaining time of this window.
            xRateLimitReset = parseInt raw.headers['x-rate-limit-reset'], 10
            if isFinite xRateLimitReset
                # have spare 30s
                sleepTime = xRateLimitReset * 1000 - Date.now() + 30000
                if sleepTime > 0
                    setTimeout (()=> @suspended[type] = false), sleepTime
                return
            # If reset time is not available for some reason, sleep for 30 minutes.
            console.warn 'ReteLimits: not available'
            setTimeout (()=> @suspended[type] = false), 30 * 60 * 1000




rateLimits = new RateLimits

tweet=(message, pass)->
    return unless pass == Config.admin.password
    return if rateLimits.isSuspended 'tweet'
    
    if Config.twitter.enable
        twit.post 'statuses/update', {
            status: message
            trim_user: 'true'
        }, (err, data, raw)->
            if err?
                unless Array.isArray(err)
                    console.error 'tweet:', err
                rateLimits.examineError 'tweet', err, raw
            if data?
                console.log 'tweet:', data
    if Config.weibo.enable
        target = "https://api.weibo.com/2/statuses/share.json"
        if message.match(Config.application.url) == null
            message += "#{Config.application.url}"
        opt = 
            url: target
            form:
                access_token:Config.weibo.oauth.access_token
                status: message
        #console.log opt
        request.post opt,(err,httpResponse,body)->
            #console.log JSON.parse body

exports.tweet=tweet
exports.template=(roomid,message,pass)->
    tweet "#{message} \u2013 #{Config.application.url}room/#{roomid}",pass
        
exports.getTwitterIcon=(id,cb)->
    # This API is currently not available.
    if rateLimits.isSuspended 'icon'
        cb null
        return

    # twitterid調べる
    twit.get 'users/show.json',{
        screen_name: id
        include_entities: false
    },(err, result, raw)->
        if err?
            console.error 'getTwitterIcon: ', err
            rateLimits.examineError 'icon', err, raw
            cb null
            return
        cb result?.profile_image_url_https

# sanitize string for tweet.
exports.sanitizeTweet = (str)->
    # Put U+200B after specialcharacters (@, #, $) and
    # periods (they may form URL)
    str.replace /[\@\#\$\.]/g, (k)-> k + "\u200b"
