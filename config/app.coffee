module.exports =

  name: "月下人狼"
  # HTTP server
  http:
    port: 8800
  ws:
    connect: null	# コネクション先サーバーの情報
    ###
    connect:
		host:"some-server.org"
		port:8080
    ###
  # db setting
  mongo:
    database: "werewolf"
    host: "127.0.0.1"
    port: 27017
    user: "test"
    pass: "test"

  admin:
    # 管理者権限を行使する際のパスワード
    password: "test"
    securityHole: false
  backdoor:
    # 外部のURL
    home: "http://81.la/"
  application:
    # アプリケーション情報
    url: "http://jinrou.81.la/"
  twitter:
    # twitter提携用
    oauth:
      # twitterアプリケーションの何か
      consumerKey:"******"
      consumerSecret:"******"
      # botアカウントのアクセストークン
      accessToken:"******"
      accessTokenSecret:"******"
  
