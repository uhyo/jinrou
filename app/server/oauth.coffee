# OAuth twitter client
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

exports.actions=
	tweet:tweet
	template:(roomid,message,pass)->
		tweet "#{message} \u2013 #{SS.config.application.url}room/#{roomid}",pass
		

