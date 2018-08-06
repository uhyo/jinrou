exports.start=->
    JinrouFront.loadI18n()
        .then((i18n)-> i18n.getI18nFor())
        .then (i18n)->
            page=0
            query=null
            getroom = Index.game.rooms.getroom
            #ss.rpc "game.rooms.getRooms", mode,page,getroom

            # ルールの設定
            setjobrule = (rulearr, names, parent)->
                for obj in rulearr
                    # name,title, ruleをもつ
                    ruleid = names.concat obj.name
                    if Array.isArray obj.rule
                        # さらに子
                        optgroup = document.createElement "optgroup"
                        optgroup.label = i18n.t "casting:castinGroupgName.#{ruleid.join '.'}"
                        parent.appendChild optgroup
                        setjobrule obj.rule, ruleid, optgroup
                    else
                        # option
                        ruleidname = ruleid.join '.'
                        option=document.createElement "option"
                        option.textContent = i18n.t "casting:castingName.#{ruleidname}"
                        option.value = ruleidname
                        option.title = i18n.t "casting:castingTitle.#{ruleidname}"
                        parent.appendChild option
            # TODO definitions of these rules are duplicate.
            setjobrule Shared.game.jobrules.concat([
                name:"特殊ルール"
                rule:[
                    {
                        name:"自由配役"
                        rule:null
                    }
                    {
                        name:"闇鍋"
                        rule:null
                    }
                    {
                        name:"一部闇鍋"
                        rule:null
                    }
                    {
                        name:"量子人狼"
                        rule:null
                    }
                    {
                        name:"エンドレス闇鍋"
                        rule:null
                    }
                ]
            ]),[],$("#rulebox").get 0
            $("#pager").click (je)->
                return unless query?
                t=je.target
                if t.name=="prev"
                    page--
                    if page<0 then page=0
                    ss.rpc "game.rooms.find", query,page,(rooms)->getroom i18n, "log",rooms
                else if t.name=="next"
                    page++
                    ss.rpc "game.rooms.find", query,page,(rooms)->getroom i18n, "log",rooms

            $("#logsform").change (je)->
                # disable/able
                t=je.target
                if result=t.name.match /^(.+)_on$/
                    t.form.elements[result[1]].disabled= !t.checked
            $("#logsform").submit (je)->
                form=je.target
                je.preventDefault()
                query={}
                # 数値
                for x in ["min_number","max_number","min_day","max_day"]
                    unless form.elements[x].disabled
                        query[x]=parseInt form.elements[x].value
                for x in ["result_team","rule"]
                    unless form.elements[x].disabled
                        query[x]=form.elements[x].value


                ss.rpc "game.rooms.find", query,page,(rooms)->
                    getroom "log",rooms



exports.end=->
