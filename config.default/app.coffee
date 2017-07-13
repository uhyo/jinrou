module.exports =

  name: "月下人狼"
  # HTTP server
  http:
    port: 8800
    secure: null
    # if not null, serve HTTPS.
    # Note: you may not need to config HTTPS server
    # if it is behind a reverse proxy.
    # (instead, config your proxy server to serve HTTPS.)
    ###
    #secure:
    #  key: ...
    #  cert: ...
    #  (options passed to https.createServer())
    ###
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
    # Note: content of this object will be exposed to clients.
    # url: for backward compatibility.
    url: "http://jinrou.uhyohyo.net/"
    # provided mode of application.
    modes: [
      {
        url: "http://jinrou.uhyohyo.net/"
        name: "HTTP版"
      }
      {
        url: "https://jinrou.uhyohyo.net/"
        name: "HTTPS版"
      }
    ]
    defaultMode: 0
    
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
    from: "noreply@yourserver.com" # from address
    auth:
      user: "noreply@yourserver.com"
      pass: "yourpass"
  # ルーム管理について
  rooms:
    # 古い部屋に入るまでの時間(hours)
    fresh:24*3
  # maximum length of data that mey be saved in DB
  maxlength:
    user:
      # user name
      name: 50
      # user comment
      comment: 1024
      # user icon url
      icon: 300
      # mail address
      mail: 300
    room:
      # room name
      name: 100
      # room comment
      comment: 300
    game:
      # game speak comment
      comment: 4096
  # Experimental feature: logging (boolean)
  logging: false
	
