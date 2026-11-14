const http = require('http');
const https = require('https');
const path = require('path');

const cpx = require('cpx');
const ss = require('socketstream');

// 未捕捉例外/未処理 Promise でプロセスを落とさない（DoS 緩和）。
// 状態不整合の可能性はあるため、必ずログに残す。
process.on('uncaughtException', (err) => {
  console.error('uncaughtException', err && (err.stack || err));
});
process.on('unhandledRejection', (reason) => {
  console.error('unhandledRejection', reason && (reason.stack || reason));
});

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
 * Load manifest file from builclient-side assets.
 */
let manifestMain;
let legacyManifestMain;
let manifestFeatureCheck;
try {
  const manifest = require('./client/static/front-assets/manifest.json');
  manifestMain = manifest['main.js'];
  manifestFeatureCheck = manifest['feature-check.js'];

  if (Config.front.legacyBuilds) {
    const legacyManifest = require('./client/static/front-assets/legacy/manifest.json');
    legacyManifestMain = legacyManifest['main.js'];
  }
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
const libi18n = require('./server/libs/i18n.coffee');
const i18n = libi18n.getWithDefaultNS('view');
/**
 * Config object for jade formatter.
 */
const jadeConfig = {
  locals: {
    Config,
    bundle: manifestMain,
    legacyBundle: legacyManifestMain,
    featureCheckJs: manifestFeatureCheck,
    notSupportedPage: Config.front.notSupportedPage,
    legacyBuilds: Config.front.legacyBuilds,
    i18n,
  },
};

ss.client.formatters.add(require('ss-jade'), jadeConfig);
ss.client.formatters.add(require('ss-stylus'));

ss.client.templateEngine.use(require('ss-clientjade'));

ss.client.set({ liveReload: false });
ss.session.store.use('redis', { host: Config.redis.host });
ss.publish.transport.use('redis', { host: Config.redis.host });

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
ss.http.middleware.prepend(middleware.securityheaders);
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

// X-Forwarded-For の先頭はクライアントが自由に詐称できる。
// 直近のリバースプロキシ（ループバック接続）が末尾に付けた実クライアント IP だけを使う。
const isLoopbackAddress = (addr) => {
  if (!addr) return false;
  return (
    addr === '127.0.0.1' ||
    addr === '::1' ||
    addr === '::ffff:127.0.0.1'
  );
};
const sanitizeForwardedFor = (req) => {
  const xff = req.headers['x-forwarded-for'];
  if (!xff) return;
  const peer = req.socket && req.socket.remoteAddress;
  const parts = String(xff)
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean);
  if (!isLoopbackAddress(peer) || parts.length === 0) {
    // 直接接続、または不正な値。ソケットの実アドレスを使わせる。
    delete req.headers['x-forwarded-for'];
    return;
  }
  // 末尾（直近プロキシが付与した実クライアント IP）のみ残す
  req.headers['x-forwarded-for'] = parts[parts.length - 1];
};

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
    // engine.io は attach 時に既存の request リスナーを奪ってしまうため、
    // attach 後に prepend して、engine.io のパスでも XFF を先に正規化する。
    server.prependListener('request', sanitizeForwardedFor);
    server.prependListener('upgrade', sanitizeForwardedFor);
  });
}
