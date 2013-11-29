fs=require 'fs'
jade=require 'jade'

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

