exports.config=
  admin:
    # 管理者権限を行使する際のパスワード
    password: "test"
    securityHall: false
  backdoor:
    # 外部のURL
    home: "http://jinro.mamesoft.net/"
  application:
    # アプリケーション情報
    url: "http://jinro.mamesoft.net:8800/"
  twitter:
    # twitter提携用
    oauth:
      # twitterアプリケーションの何か
      consumerKey:"******"
      consumerSecret:"******"
      # botアカウントのアクセストークン
      accessToken:"******"
      accessTokenSecret:"******"
