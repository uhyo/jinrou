module.exports =

  name: "月下人狼"
  # HTTP server
  http:
    port: 8800
  ws:
    connect: null	# WebSocket接続先アドレス（nullならサーバーと同じ）
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
  
  # ルーム管理について
  rooms:
    # 古い部屋に入るまでの時間(hours)
    fresh:24*3
	
