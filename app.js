const http = require('http');
const https = require('https');
const path = require('path');

const cpx = require('cpx');
const ss = require('socketstream');

/**
 * Load manifest file from builclient-side assets.
 */
let manifestMain;
try {
  const manifest = require('./client/static/front-assets/manifest.json');
  manifestMain = manifest['main.js'];

} catch (e) {
  // Failed to load the manifest file.
  console.error(`Error: failed to load the manifest file.
It is not likely that front-end assets are not built.
See build instructions in README for details.`);
  throw e;
}
// Validate manifestMain.
if ('string' !== typeof manifestMain) {
  throw new Error('Manifest data is somehow invalid');
}

ss.client.define('main', {
  view: 'app.jade',
  css: ['libs', 'app.styl'],
  code: ['app', 'libs', 'pages', 'shared'],
  tmpl: '*',
});

ss.http.router.on('/', function(req, res) {
  res.serveClient('main');
});

ss.client.formatters.add(require('ss-latest-coffee'));

// Load config file.
// pull時にはコンフィグファイルないので・・・
try {
  global.Config = require('./config/app.coffee');
} catch (e) {
  console.error('Failed to load config file.');
  console.error(
    'Copy config.default/app.coffee to config/app.coffee, edit app.coffee, and retry.',
  );
  console.error(e.trace || e);
  process.exit(1);
}

/**
 * Config object for jade formatter.
 */
const jadeConfig = {
  locals: {
    bundle: manifestMain,
    notSupportedPage: Config.front.notSupportedPage
  },
};

ss.client.formatters.add(require('ss-jade'), jadeConfig);
ss.client.formatters.add(require('ss-stylus'));

ss.client.templateEngine.use(require('ss-clientjade'));

ss.client.set({ liveReload: false });
ss.session.store.use('redis');
ss.publish.transport.use('redis');

/**
 * Whether this run is in production mode.
 */
const isProduction = ss.env === 'production';

if (isProduction) {
  ss.client.packAssets();
} else {
  // development
  ss.http.set({
    static: {
      cacheControlHeader: 'no-cache',
    },
  });
}
//---- Middleware
const middleware = require('./server/middleware.coffee');
ss.http.middleware.prepend(middleware.jsonapi);
ss.http.middleware.prepend(middleware.manualxhr);
ss.http.middleware.prepend(middleware.images);
ss.http.middleware.prepend(middleware.twitterbot);

//リッスン先設定
ss.ws.transport.use('engineio', {
  client: Config.ws.connect,
});

//---- init HTTP server
let server;
if (Config.http.secure != null) {
  server = https.createServer(Config.http.secure, ss.http.middleware);
} else {
  server = http.createServer(ss.http.middleware);
}

//---- prepare client-side assets
{
  // options for cpx.
  const copySource = path.join(__dirname, 'front/dist/**/*');
  const copyDest = path.join(__dirname, 'client/static/front-assets/');
  const copyOptions = {
    preserve: true,
    update: true,
  };
  /*
    if (isProduction){
        // Copy once and run.
        cpx.copy(
            copySource,
            copyDest,
            copyOptions,
            (err)=>{
                if (err != null){
                    console.error(err);
                    process.exit(1);
                    return;
                }
                runService(server);
            },
        );
    } else {
        // Watch changes to copySource.
        cpx.watch(
            copySource,
            copyDest,
            copyOptions,
        )
        .on('watch-ready', ()=>{
            // Initial copy is done.
            runService(server);
        })
        .on('watch-error', (err)=>{
            if (err != null){
                console.error(err);
            }
        });
    }
   */
  runService(server);
}
/**
 * Function to start the service.
 */
function runService(server) {
  // Init connection to DB
  const db = require('./server/db.coffee');
  db.dbinit(() => {
    // Start application
    server.listen(Config.http.port);
    ss.start(server);
  });
}
