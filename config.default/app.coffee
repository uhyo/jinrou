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
  redis:
    host: "127.0.0.1"

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
    # application url
    url: "http://jinrou.uhyohyo.net/"
    # provided mode of application.
    modes: [
      {
        # URL of this mode.
        url: "http://jinrou.uhyohyo.net/"
        # name of this mode.
        name: "HTTP版"
        # (optional) icon of this mode.
        icon: "unlock-alt"
      }
      {
        url: "https://jinrou.uhyohyo.net/"
        name: "HTTPS版"
        icon: "lock"
      }
    ]

  twitter:
    # twitter提携用
    enable:true
    oauth:
      # twitterアプリケーションの何か
      consumerKey:"******"
      consumerSecret:"******"
      # botアカウントのアクセストークン
      accessToken:"******"
      accessTokenSecret:"******"
  weibo:
    enable:false
    oauth:
      # this access_token expires after 5 years.
      access_token:"******"
      # followings are not used right now
      appkey:"******"
      secret:"******"
      oauth_callback_url:"your callback url"
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
    # uplimit for Sudden Death Punishment(minutes).
    suddenDeathBAN:360
  # ユーザーについて
  user:
    # The number of games required to publish a user's 戦績.
    dataOpenBarrier: 30
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
  # game-related config
  game:
    # config for Poet
    Poet:
      # style of poem (number of characters per line)
      poemStyle: [5, 7, 5]
  # Experimental feature: logging (boolean)
  # logging:
  #   enabled: true
  #   rotate: true
  logging: false
  # Language Settings
  language:
    # Language that your server use
    value: "ja"
    # Fallback language: should be fixed to "ja"
    fallback: "ja"
  # front-end scripts
  front:
    # place where front-end scripts are placed.
    # set to webpack's `output.publicPath` option.
    # full URL like `https://cdn.someserver.com/` is allowed.
    publicPath: "/front-assets/"
    # URL of not-supported-browser page.
    # This page can set localStorage "jinrou-not-supported-confirm" key to truthy value, so that automatic jump to not-supported-browser page is disabled.
    # Set null to disable this feature.
    notSupportedPage: null
    # Whether to use "legacy builds" feature.
    # If set to true, browsers other than latest ones will use fallback (legacy) build of front-end scripts.
    # If this is set to true, "notSupportedPage" feature is automatically disabled.
    legacyBuilds: process.env.NODE_ENV == 'production'
  # settings for additional emissions in head.
  # currently supported types are "script" and "inline-script".
  # see client/views/app.jade for details.
  additionalMeta: [
    # {
    #   type: "script"
    #   src: "URL"
    #   crossorigin: "anonymous"
    # },
    # {
    #   type: "inline-script"
    #   text: "script..."
    # },
  ]
  # settings for the report form.
  reportForm:
    # set this to false to use the report form.
    enable: false
    # mail address to which content of report form is sent.
    mail: "someone@example.com"
    # subject of mail
    mailSubject: "月下人狼 Report Form"
    # categories available in the report form.
    # leave this empty to not show a category selection control.
    categories: [
      {
        name: "Bug report"
        description: "select this to report a bug."
      }
      {
        name: "abuse"
        description: "select this to report a malicious user."
      }
    ]
  # settings for the share button.
  shareButton:
    # set this to true to enable share via Twitter button.
    twitter: true
