# OAuth twitter client
###
oauth=new (require('oauth').OAuth)(
	'https://api.twitter.com/oauth/request_token',
	'https://api.twitter.com/oauth/access_token',
	SS.config.twitter.oauth.consumerKey,
	SS.config.twitter.oauth.consumerSecret,
	'1.0',
	null,
	'HMAC-SHA1'
)
# passとしてアレを渡せ！
tweet=(message,pass)->
	return unless pass==SS.config.admin.password
	
	oauth.post(
		"http://api.twitter.com/1/statuses/update.json",
		SS.config.twitter.oauth.accessToken,
		SS.config.twitter.oauth.accessTokenSecret,
		{status:message},
		(err,data)->
			if err
				console.error "Tweet failed: #{message}"
				console.error err
	)
###

twitter = require('twitter')
twit = new twitter({
	consumer_key:SS.config.twitter.oauth.consumerKey,
	consumer_secret:SS.config.twitter.oauth.consumerSecret,
	access_token_key:SS.config.twitter.oauth.accessToken,
	access_token_secret:SS.config.twitter.oauth.accessTokenSecret,
})

tweet=(message,pass)->
	return unless pass==SS.config.admin.password
	
	twit.post '/statuses/update.json',{status:message},(data)->
		console.log data
		rt_names=[]


# #人狼募集 RT bot
###
rt_names = []	# RTした人（直近5人）
twit.stream 'statuses/filter',{track:'#人狼募集'}, (stream)->
	stream.on 'data',(data)->
		if data?
			# ツイートが来たのでRTする
			unless rt_names.length>=5 && rt_names.every((x)->x==data.user.screen_name)
				if data.user.screen_name!="jinroutter"	#hard coding
					setTimeout (->
						twit.post "/statuses/retweet/#{data.id_str}.json",{trim_user:true},(data2)->
					),1000
					rt_names=rt_names.concat(data.user.screen_name).slice -5
###

exports.actions=
	tweet:tweet
	template:(roomid,message,pass)->
		tweet "#{message} \u2013 #{SS.config.application.url}room/#{roomid}",pass
		

