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
      results.forEach (x)->delete x.password
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
      response.end JSON.stringify doc
    
  else
    next()

# manual serving
exports.manualxhr=(request, response, next)->
  if r=request.url.match /^\/rawmanual\/([\w-]*)$/
    # マニュアルを送る
    fs.readFile "./manual/#{r[1]}.jade","utf-8",(err,data)->
      if err?
        # ?
        response.writeHead 404,{'Content-Type':'text/plain; charset=UTF-8'}
        response.end err.toString()
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

# public image serving
exports.images=(request, response, next)->
  if r=request.url.match /^\/images\/(.+)$/
    fs.readFile "./public/images/#{r[1]}",(err,data)->
      if err?
        response.writeHead 404,{'Content-Type':'text/plain; charset=UTF-8'}
        response.end err.toString()
        return
      response.writeHead 200,{'Content-Type':'image/png'}	# all png!! really?
      response.end data
  else if request.url=="/noIE.html"
    # なぜかページも
    fs.readFile "./public/noIE.html",(err,data)->
      if err?
        response.writeHead 404,{'Content-Type':'text/plain; charset=UTF-8'}
        response.end err.toString()
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


