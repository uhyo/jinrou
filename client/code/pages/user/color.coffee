app=require '/app'
util=require '/util'

exports.start=->
    # 現在のカラー設定を読み込み
    cp=app.getCurrentColorProfile()
    # 現在のところに表示
    editcallback=(cp)->
        ->
            app.setCurrentColorProfile cp
            app.useColorProfile cp
    ((cp)->
        $("#currentcolorarea").empty().append makeColorSet cp,true,editcallback cp
    )(cp)
    # プリセットも表示
    $("#presetcolors").empty()
    for cp in presets
        ((cp)->
            $("#presetcolors").append makeColorSet(cp).addClass("presetbox").click (je)->
                util.ask "配色设定","使用这个预设配置吗？",(result)->
                    if result
                        app.setCurrentColorProfile cp
                        app.useColorProfile cp
                        cp=app.getCurrentColorProfile cp
                        $("#currentcolorarea").empty().append makeColorSet cp,true,editcallback cp
        )(cp)

exports.end=->

makeColorSet=(cp,editable=false,callback)->
    #editableがtrueの場合はcpを変更するかも(callbackが呼ばれる）

    $("<div>").append("昼：").append(makeColorBox cp.day,editable,callback)
    .append("夜：").append(makeColorBox cp.night,editable,callback)
    .append("灵界：").append(makeColorBox cp.heaven,editable,callback)

makeColorBox=(obj,editable,callback)->
    # color profileをもとにcolorboxを作る
    box=$("<div>").addClass("colorprofilebox")
    back=$("<div>").addClass("backbox").css("background-color",obj.bg).appendTo(box)
    color=$("<div>").addClass("colorbox").css("background-color",obj.color).appendTo(box)
    if editable
        # 編集可能
        back.click (je)->
            ci=$("<input type='color'>").css("opacity","0").prop("value",obj.bg).appendTo $("#content")
            ci.get(0).addEventListener "change",(e)->
                val=e.target.value
                back.css "background-color",val
                obj.bg=val
                ci.remove()
                callback()
            ,false
            ci.get(0).click()
        color.click (je)->
            ci=$("<input type='color'>").css("opacity","0").prop("value",obj.color).appendTo $("#content")
            ci.get(0).addEventListener "change",(e)->
                val=e.target.value
                color.css "background-color",val
                obj.color=val
                ci.remove()
                callback()
            ci.get(0).click()


    return box

presets=[
    {
        day:
            bg:"#ffd953"
            color:"#000000"
        night:
            bg:"#000044"
            color:"#ffffff"
        heaven:
            bg:"#fffff0"
            color:"#000000"
    }
    {
        day:
            bg:"#f0e68c"
            color:"#000000"
        night:
            bg:"#000044"
            color:"#ffffff"
        heaven:
            bg:"#fffff0"
            color:"#000000"
    }
    {
        day:
            bg:"#ffffff"
            color:"#000000"
        night:
            bg:"#000044"
            color:"#ffffff"
        heaven:
            bg:"#e3e3e3"
            color:"#000000"
    }
]
