var http=require('http'), ss=require('socketstream');

ss.client.define('main',{
	view:'app.jade',
	css:['libs','app.styl'],
	code:['app','libs','pages','shared'],
	tmpl:'*',
});

ss.http.router.on('/',function(req,res){
	res.serveClient('main');
});

ss.client.formatters.add(require('ss-coffee'));
ss.client.formatters.add(require('ss-jade'));
ss.client.formatters.add(require('ss-stylus'));

ss.client.templateEngine.use(require('ss-clientjade'));

ss.client.set({liveReload: false});
if(ss.env=='production')ss.client.packAssets();

global.Config=require('./config/app.coffee');
//---- Middleware
var middleware=require('./server/middleware.coffee');
ss.http.middleware.prepend(middleware.jsonapi);
ss.http.middleware.prepend(middleware.manualxhr);


//----
var server=http.Server(ss.http.middleware);
server.listen(8800);

ss.start(server);

db=require('./server/db.coffee');
db.dbinit()


