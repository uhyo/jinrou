# OAuth twitter client

Twitter = require 'twitter'
twit = new Twitter({
    consumer_key:Config.twitter.oauth.consumerKey,
    consumer_secret:Config.twitter.oauth.consumerSecret,
    access_token_key:Config.twitter.oauth.accessToken,
    access_token_secret:Config.twitter.oauth.accessTokenSecret,
})

tweet=(message, pass)->
    return unless pass == Config.admin.password
    
    twit.post 'statuses/update', {
        status: message
        trim_user: 'true'
    }, (err, data)->
        if err?
            console.error 'tweet:', err
        if data?
            console.log 'tweet:', data

exports.tweet=tweet
exports.template=(roomid,message,pass)->
        tweet "#{message} \u2013 #{Config.application.url}room/#{roomid}",pass
        
exports.getTwitterIcon=(id,cb)->
    # twitterid調べる
    twit.get 'users/show.json',{
        screen_name: id
        include_entities: false
    },(err, result)->
        if err?
            console.error 'getTwitterIcon: ', err
            cb null
            return
        cb result?.profile_image_url_https
