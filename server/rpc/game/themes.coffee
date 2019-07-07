# example at server/themes/example.coffee
fs=require 'fs'

themes={}
getThemes=()->
    themeFiles = fs.readdirSync "server/themes/"
    # not the example
    themeFiles=themeFiles.filter (n)->n!="example.coffee"
    themes={}
    for themeFile in themeFiles
        unless themeFile.match(/\.coffee$/) == null
            name = themeFile.replace /\.coffee$/, ""
            try
                # reload this theme
                delete require.cache[require.resolve("../../themes/#{name}.coffee")]
                themes[name] = require "../../themes/#{name}.coffee"
            catch e
                console.error e
# load themes
getThemes()

# if any changes
fs.watch "server/themes/",(e)->
    getThemes()

module.exports =
    getTheme:(name)->
        if themes[name] != undefined
            return themes[name]
        themeFiles = fs.readdirSync "server/themes/"
        # not the example
        themeFiles=themeFiles.filter (n)->n!="example.coffee"

        if "#{name}.coffee" in themeFiles
            try
                theme = require "../../themes/#{name}.coffee"
            catch e
                console.log e
                theme = null
            return theme
        return null

module.exports.actions =(req,res,ss)->
    req.use 'user.fire.wall'
    req.use 'session'
    getThemeList:->
        results=[]
        try
            for t of themes
                results.push {
                    value:t
                    name:themes[t].name
                }
            res results
        catch e
            res {error:e}
