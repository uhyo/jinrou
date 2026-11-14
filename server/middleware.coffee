path=require 'path'
fs=require 'fs'
jade=require 'jade'
pug=require 'pug'

# JSON APIs
exports.jsonapi=(request, response, next)->
  if request.url=="/json/rooms"
    M.rooms.find({mode:{$ne:"end"}}).sort({made:-1}).limit(10).toArray (err,results)->
      if err?
        response.statusCode=500
        response.end JSON.stringify {
          error:true
          code:500
          message:err
        }
        return
      response.writeHead 200,{'Content-Type':'application/json; charset=UTF-8'}
      results.forEach (x)->
        delete x.password
        delete x.quitfromtheme
        delete x.ban
        delete x.owner if x.blind
        if x.players?
          x.players.forEach (p)->
            # 公開 API に IP / 内部 ID を出さない
            delete p.ip
            delete p.realid
      response.end JSON.stringify results
  else if r=request.url.match /\/json\/room\/(\d+)$/
    M.rooms.findOne {id:parseInt r[1]}, (err,doc)->
      if err?
        response.statusCode=500
        response.end JSON.stringify {
          error:true
          code:500
          message:err
        }
        return
      unless doc?
        response.statusCode=404
        response.end JSON.stringify {
          error:true
          code:404
          message:"Not Found"
        }
        return
      response.writeHead 200,{'Content-Type':'application/json; charset=UTF-8'}
      delete doc.password
      delete doc.quitfromtheme
      delete doc.ban
      delete doc.owner if doc.blind
      if doc.players?
        doc.players.forEach (p)->
          delete p.ip
          delete p.realid
      response.end JSON.stringify doc
    
  else
    next()

# manual serving
exports.manualxhr=(request, response, next)->
  if r=request.url.match /^\/rawmanual\/([\w-]*)$/
    # マニュアルを送る
    fs.readFile "./manual/#{r[1]}.jade","utf-8",(err,data)->
      if err?
        # エラー内容（絶対パス等）は返さない
        response.writeHead 404,{'Content-Type':'text/plain; charset=UTF-8'}
        response.end "Not Found"
        return
      fn=jade.compile data,{}
      unless fn?
        response.writeHead 500,{'Content-Type':'text/plain'}
        response.end "500"
        return
      response.writeHead 200,{'Content-Type':'text/plain; charset=UTF-8'}
      response.end fn {}
  else
    next()

# セキュリティヘッダ（全レスポンス共通）
exports.securityheaders=(request, response, next)->
  response.setHeader 'X-Content-Type-Options', 'nosniff'
  response.setHeader 'X-Frame-Options', 'SAMEORIGIN'
  response.setHeader 'Referrer-Policy', 'strict-origin-when-cross-origin'
  next()

# public image serving
exports.images=(request, response, next)->
  notFound = ->
    response.writeHead 404,{'Content-Type':'text/plain; charset=UTF-8'}
    response.end "Not Found"
  if r=request.url.match /^\/images\/(.+)$/
    # パストラバーサル防止: public/images 配下の通常ファイルのみ許可
    root = path.resolve "./public/images"
    target = path.resolve root, r[1]
    unless target == root or target.indexOf(root + path.sep) == 0
      notFound()
      return
    fs.lstat target,(err,st)->
      if err? or !st.isFile()
        notFound()
        return
      fs.readFile target,(err,data)->
        if err?
          notFound()
          return
        response.writeHead 200,{'Content-Type':'image/png'}
        response.end data
  else if request.url=="/noIE.html"
    # なぜかページも
    fs.readFile "./public/noIE.html",(err,data)->
      if err?
        notFound()
        return
      response.writeHead 200,{'Content-Type':'text/html'}
      response.end data
  else
    next()

# Special handling of TwitterBot
cardsView = pug.compileFile path.join(__dirname, '../client/views/cards.pug')
exports.twitterbot=(request, response, next)->
    r = null
    if request.headers['user-agent']?.indexOf('Twitterbot') == 0 && (r=request.url.match /^\/room\/(\d+)$/)
        # This is an access from TwitterBot!
        # Render Twitter Cards.
        M.rooms.findOne({
            id: Number(r[1])
        }, {
            fields:
                name: 1
                comment: 1
        }).then((doc)->
            if doc?
                res = cardsView {
                    url: Config.application.url
                    title: doc.name
                    description: doc.comment
                }
                response.statusCode = 200
                response.setHeader 'Content-Type', 'text/html'
                response.end res
            else
                response.statusCode = 404
                response.end "Not Found")
        .catch((err)->
            console.error err
            response.statusCode = 500
            response.setHeader 'Content-Type', 'text/html'
            response.end "Internal Server Error")
    else
        next()


