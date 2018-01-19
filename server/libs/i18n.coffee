# Initialization of i18n library.

path = require 'path'
i18next = require 'i18next'

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
        ns: ["game", "roles"]
        defaultNS: "game"
        saveMissing: true
    }, (err)->
        if err?
            console.error 'i18next Error:', err

# Get a new instance of i18next with provided defaultND.
# Instances share their resources.
exports.getWithDefaultNS = (ns)->
    i18next.cloneInstance {
        defaultNS: ns
    }
            
