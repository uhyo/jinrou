# Initialization of i18n library.

path = require 'path'
i18next = require 'i18next'

# Flag that resource is already Loaded
resourceLoadedFlag = false
# List of callbacks to run on resource loading.
resourceLoadCallbacks = []

i18next
    .use(require 'i18next-node-fs-backend')
    .init {
        backend:
            loadPath: path.join __dirname, '../../language/{{lng}}/{{ns}}.yaml'
            addPath: path.join __dirname, '../../language/{{lng}}/{{ns}}.missing.json'
            jsonIndent: 2
        interpolation:
            escapeValue: false
            # disable nesting feature by passing never-matching patterns
            nestingPrefix: undefined
            nestingSuffix: undefined
            # Actually it matches an empty string, but this is not a problem here.
            nestingPrefixEscaped: '$^'
            nestingSuffixEscaped: '$^'
        lng: Config.language.value
        fallbackLng: Config.language.fallback
        ns: ["common", "lobby", "admin", "user", "rooms", "game", "roles", "casting", "prizedata", "view"]
        defaultNS: "game"
        saveMissing: true
    }, (err)->
        if err?
            console.error 'i18next Error:', err
            return
        resourceLoadedFlag = true
        for f in resourceLoadCallbacks
            f()

# Get a new instance of i18next with provided defaultND.
# Instances share their resources.
exports.getWithDefaultNS = (ns)->
    i18next.cloneInstance {
        defaultNS: ns
    }

# Get a resource for default language.
exports.getResource = (ns, path)->
    i18next.getResource Config.language.value, ns, path

# Register a resource loaded flag
exports.addResourceLoadCallback = (fn)->
    if resourceLoadedFlag
        process.nextTick fn
    else
        resourceLoadCallbacks.push fn
