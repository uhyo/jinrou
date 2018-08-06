exports.start=->
    # 配役種類一覧
    JinrouFront.loadI18n()
        .then((i18n)-> i18n.getI18nFor())
        .then (i18n)->
            dl=$("#castings")
            jobrules = Shared.game.jobrules
            app i18n, dl, jobrules

exports.end=->

app=(i18n, dl, arr, prefixes=[])->
    # dlにarr以下のものを追加
    for obj in arr
        # full path of this casting, eg. "普通配役.普通1"
        console.log obj
        objpath = prefixes.concat obj.name
        objid = objpath.join '.'
        rule=obj.rule
        if Array.isArray rule
            # 子がある
            dt=$("<dt>").text(i18n.t "casting:castingGroupName.#{objid}._name").appendTo dl
            dd=$("<dd>").appendTo dl
            dll=$("<dl>").appendTo dd
            app i18n, dll, rule, objpath
        else
            # 詳細
            dt=$("<dt>").appendTo dl
            a=$("<a href='/manual/casting/#{objpath.join('-')}'>").text(i18n.t "casting:castingName.#{objid}").appendTo dt
            dd=$("<dd>").text(i18n.t "casting:castingTitle.#{objid}").appendTo dl
