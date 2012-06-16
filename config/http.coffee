# HTTP Middleware Config
# ----------------------

# Version 2.0

# This file defines how incoming HTTP requests are handled

# CUSTOM MIDDLEWARE

# Hook-in your own custom HTTP middleware to modify or respond to requests before they're passed to the SocketStream HTTP stack

fs=require 'fs'
jade=require 'jade'

custom = ->

  (request, response, next) ->
    if request.url=="/"
      console.log 'This is my custom middleware. The URL requested is', request.url
      console.log request.connection.address().address
    # Unless you're serving a response you'll need to call next() here 
    next()
    
referrerstop=(request, response, next)->
  unless /^http:\/\/masao\.kuronowish\.com/.test request.headers.referer
    next()
    return
  response.statusCode=403
  response.end """
<!doctype html>
<html><head><meta charset="UTF-8"><title>403 Forbidden</title></head>
<body><h1>403 Forbidden</h1><p>Bad referrer</p><footer><p><small>&copy; 2011-2012 うひょ</small></p></footer></body></html>"""

# JSON APIs
jsonapi=(request, response, next)->
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
manualxhr=(request, response, next)->
  if r=request.url.match /^\/rawmanual\/(\w*)$/
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



# CONNECT MIDDLEWARE

# connect = require('connect')

# Stack for Primary Server
exports.primary =
  [
    #connect.logger()            # example of calling in-built connect middleware. be sure to install connect in THIS project and uncomment out the line above
    #require('connect-i18n')()   # example of using 3rd-party middleware from https://github.com/senchalabs/connect/wiki
    #custom()                      # example of using your own custom middleware (using the example above)
	#referrerstop
    jsonapi
    manualxhr
  ]

# Stack for Secondary Server
exports.secondary = []
