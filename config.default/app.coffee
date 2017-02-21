module.exports =

  name: "月下人狼"
  # HTTP server
  http:
    port: 8800
  ws:
    ###
    connect:
      host:"some-server.org"
      port:8080
    ###
    connect: null	# WebSocket接続先アドレス（nullならサーバーと同じ）

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
    # trueにしてはいけない
    securityHole: false
  maintenance:
    # 人狼の更新などを行う際のパスワード
    password: "test"
    # 人狼の更新スクリプト
    script:[
      "git pull"
    ]
  backdoor:
    # 外部のURL
    home: "http://uhyohyo.net/"
  application:
    # アプリケーション情報
    url: "http://jinrou.uhyohyo.net/"
  twitter:
    # twitter提携用
    oauth:
      # twitterアプリケーションの何か
      consumerKey:"******"
      consumerSecret:"******"
      # botアカウントのアクセストークン
      accessToken:"******"
      accessTokenSecret:"******"
  smtpConfig:
    host: "smtp.yourserver.com"
    port: 465 # use SSL, port without SSL is often 25
    secure: true # use SSL
    auth:
      user: "noreply@yourserver.com"
      pass: "yourpass"
  # ルーム管理について
  rooms:
    # 古い部屋に入るまでの時間(hours)
    fresh:24*3
	
