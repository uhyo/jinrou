exports.start=->
    page=0
    query=null
    getroom=Index.game.rooms.getroom
    #ss.rpc "game.rooms.getRooms", mode,page,getroom

    # 规则の設定
    setjobrule=(rulearr,names,parent)->
        for obj in rulearr
            # name,title, ruleをもつ
            if obj.rule instanceof Array
                # さらに子
                optgroup=document.createElement "optgroup"
                optgroup.label=obj.name
                parent.appendChild optgroup
                setjobrule obj.rule,names.concat([obj.name]),optgroup
            else
                # option
                option=document.createElement "option"
                option.textContent=obj.name
                option.value=names.concat([obj.name]).join "."
                option.title=obj.title
                parent.appendChild option
    setjobrule Shared.game.jobrules.concat([
        name:"特殊规则"
        rule:[
            {
                name:"自由配役"
                title:"可以自由设定角色。"
                rule:null
            }
            {
                name:"黑暗火锅"
                title:"角色数量完全随机分配。"
                rule:null
            }
            {
                name:"半份黑暗火锅"
                title:"一部分角色固定，另一部分随机分配。"
                rule:null
            }
            {
                name:"量子人狼"
                title:"全员的职业以概率表现。只限村人・人狼・占卜师。"
                rule:null
            }
            {
                name:"Endless黑暗火锅"
                title:"可以途中参加・死亡后立刻转生的黑暗火锅。"
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
            ss.rpc "game.rooms.find", query,page,(rooms)->getroom "log",rooms
        else if t.name=="next"
            page++
            ss.rpc "game.rooms.find", query,page,(rooms)->getroom "log",rooms
        
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
