const http = require('http');
const https = require('https');
const path = require('path');

const cpx = require('cpx');
const ss = require('socketstream');

ss.client.define('main',{
	view:'app.jade',
	css:['libs','app.styl'],
	code:['app','libs','pages','shared'],
	tmpl:'*',
});

ss.http.router.on('/',function(req,res){
	res.serveClient('main');
});

ss.client.formatters.add(require('ss-latest-coffee'));
ss.client.formatters.add(require('ss-jade'));
ss.client.formatters.add(require('ss-stylus'));

ss.client.templateEngine.use(require('ss-clientjade'));

ss.client.set({liveReload: false});
ss.session.store.use('redis');
ss.publish.transport.use('redis');

if(ss.env=='production')ss.client.packAssets();

//pull時にはコンフィグファイルないので・・・
try{
	global.Config=require('./config/app.coffee');
}catch(e){
	console.error("Failed to load config file.");
	console.error("Copy config.default/app.coffee to config/app.coffee, edit app.coffee, and retry.");
	console.error(e.trace || e);
	process.exit(1);
}

//---- Middleware
const middleware=require('./server/middleware.coffee');
ss.http.middleware.prepend(middleware.jsonapi);
ss.http.middleware.prepend(middleware.manualxhr);
ss.http.middleware.prepend(middleware.images);
ss.http.middleware.prepend(middleware.twitterbot);

//リッスン先設定
ss.ws.transport.use("engineio",{
	client:Config.ws.connect,
});

//---- init HTTP server
let server;
if (Config.http.secure != null){
    server = https.createServer(Config.http.secure, ss.http.middleware);
}else{
    server = http.createServer(ss.http.middleware);
}

//---- prepare client-side assets
cpx.copy(
    /* source */
    path.join(__dirname, 'front/dist/**/*'),
    /* dest */
    path.join(__dirname, 'client/static/front-assets/'),
    {
        preserve: true,
        update: true,
    },
    (err)=>{
        if (err != null){
            console.error(err);
            process.exit(1);
            return;
        }
        // Init connection to DB
        const db=require('./server/db.coffee');
        db.dbinit(function () {
            // Start application
            server.listen(Config.http.port);
            ss.start(server);
        })
    },
);

