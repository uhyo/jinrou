csv=require 'csv'
path=require 'path'
fs=require 'fs'

Shared=
    game:require '../client/code/shared/game'

# コールバック:{
#   names:{}
#   phonetics:{}
# }
makePrize=(cb)->
    # 胜利と败北を読み込む
    result={
        names: {}
        phonetics: {}
    }
    dir=path.normalize __dirname+"/../prizedata"
    fs.readFile path.join(dir,"win.csv"),{encoding:"utf8"}, (err,data)->
        if err?
            cb result
            return
        csv.parse data,(err,arr)->
            if err?
                cb result
                return
            result.wincountprize = loadTable arr
            fs.readFile path.join(dir,"lose.csv"),{encoding:"utf8"}, (err,data)->
                if err?
                    cb result
                    return
                csv.parse data,(err,arr)->
                    if err?
                        cb result
                        return
                    result.losecountprize = loadTable arr
                    # 残り
                    makeOtherPrize result
                    # 称号IDと名字の対応表を作る
                    makeNames result
                    cb result
exports.makePrize=makePrize

# win.csv,lose.csvを読み込む
loadTable=(arr)->
    result={}
    # 1行目は番号
    nums=arr.shift()
    # 1列目は見出しなのでいらない
    nums.shift()
    normals=[]  #通常役職
    specials=[] #特殊役職
    normaljobs=["all","Human","Werewolf","Diviner","Psychic","Madman","Guard","Couple","Fox"]
    # 数をパースする
    for num in nums
        res=num.match /^(\d+)(?:\(\d+\))?$/
        if res
            normals.push parseInt res[1]
            if res[2]?
                specials.push parseInt res[2]
            else
                specials.push parseInt res[1]
    # 残りをパースする
    for row in arr
        # 最初は役職名
        jobname=row.shift()
        normalflag = jobname in normaljobs
        result[jobname]=obj={}
        for name,i in row
            if name
               ns=name.split "\n"
               obj[if normalflag then normals[i] else specials[i]]=(if ns.length>1 then ns else name)
    result

# 名字つける
makeNames=(result)->
    names={}
    phonetics={}
    # ひとつ登録
    mset=(key,namevalue)->
        if Array.isArray namevalue
            for n,i in namevalue
                [name,phonetic]=n.split "/"
                if i==0
                    names[key]=name
                    phonetics[key]=phonetic
                else
                    names["#{key}:#{i}"]=name
                    phonetics["#{key}:#{i}"]=phonetic
        else
            [name,phonetic]=namevalue.split "/"
            names[key]=name
            phonetics[key]=phonetic
    for job,obj of result.wincountprize
        for num,name of obj
            mset "wincount_#{job}_#{num}",name
    for job,obj of result.losecountprize
        for num,name of obj
            mset "losecount_#{job}_#{num}",name
    for job,obj of result.winteamcountprize
        for num,name of obj
            mset "winteamcount_#{job}_#{num}",name
    for kind,obj of result.counterprize
        for num,name of obj.names
            mset "#{kind}_#{num}",name
    for kind,obj of result.ownprizesprize
        for num,name of obj.names
            mset "#{kind}_#{num}",name
    result.names=names
    result.phonetics=phonetics
    result

# 他のprize
makeOtherPrize=(result)->
    result.winteamcountprize=
        Human:
            10:"白/しろ"
            50:"光/ひかり"
        Werewlf:
            5:"伪/いつわり"
            10:"黑/くろ"
            50:"暗/やみ"
    result.loseteamcountprize={}
    result.counterprize=
        # 呪殺
        cursekill:
            names:
                1:"咒杀/じゅさつ"
                5:"狙杀/すないぱー"
                10:"天敌/てんてき"
                15:"猎狐犬/ふぉっくすはうんど"
                30:"猎狐人/はんたー"
                50:"奇迹/きせき"
            func:(game,pl)->
                # 呪殺を数える
                game.gamelogs.filter((x)->x.id==pl.id && x.event=="cursekill").length
        # 初日黒
        divineblack2:
            names:
                5:"千里眼/せんりがん"
                10:"心眼/しんがん"
            func:(game,pl)->
                game.gamelogs.filter((x)->x.id==pl.id && x.event=="divine" && x.flag in Shared.game.blacks).length
            
        # GJ判定
        GJ:
            names:
                1:"GJ/じーじぇー"
                3:"护卫/ごえい"
                5:"防卫/ぼうえい"
                10:"铁壁/てっぺき"
                15:"救世主/きゅうせいしゅ"
                30:"Guardian/がーでぃあん"
            func:(game,pl)->
                game.gamelogs.filter((x)->x.id==pl.id && x.event=="GJ").length
        # 恋人の胜利回数
        lovers_wincount:
            names:
                1:"相恋/りょうおもい"
                5:"亲密/いちゃいちゃ"
                10:"热恋/らぶらぶ"
                15:"结婚/けっこん"
                30:"比翼连理/ひよくれんり"
            func:(game,pl)->
                if pl.winner && chkCmplType pl,"Friend"
                    1
                else
                    0
        # 恋人の败北回数
        lovers_losecount:
            names:
                1:"倦怠期/けんたいき"
                5:"出轨/うわき"
                10:"失恋/しつれん"
                15:"离婚/りこん"
                30:"爱憎剧/あいぞうげき"
            func:(game,pl)->
                if !pl.winner && chkCmplType pl,"Friend"
                    1
                else
                    0
        # 商品を受け取った回数
        getkits_merchant:
            names:
                1:"收件人/うけとり"
                5:"顾客/とりひきさき"
                10:"老主顾/おとくいさま"
            func:(game,pl)->
                game.gamelogs.filter((x)->x.target==pl.id && x.event=="sendkit").length
        # 商品を人狼側に送った回数
        sendkits_to_wolves:
            names:
                1:"误送/ごそう"
                10:"订单错误/はっちゅうみす"
            func:(game,pl)->
                game.gamelogs.filter((x)->x.id==pl.id && x.event=="sendkit" && getTeamByType(getTypeAtTime(game,x.target,x.day))=="Werewolf").length
        # 模仿者せずに终了
        nocopy:
            names:
                1:"优柔寡断/ゆうじゅうふだん"
                5:"null/なる"
                10:"Undefined/あんでふぁいんど"
            func:(game,pl)->
                if pl.type=="Copier"
                    1
                else
                    0
        # 2日目昼に吊られた
        day2hanged:
            names:
                1:"初日/しょにち"
                5:"寡言/かもく"
                10:"联络失败/おはすて"
                15:"可疑的人/あやしいひと"
                30:"壁/かべ"
            func:(game,pl)->
                game.gamelogs.filter((x)->
                    x.id==pl.id && x.event=="found" && x.flag=="punish" && x.day==2
                ).length
            
        # 総試合数
        allgamecount:
            names:
                1:"起始/はじめて"
                5:"初学者/びぎなー"
                10:"新秀/るーきー"
                15:"前辈/せんぱい"
                30:"经验者/けいけんしゃ"
                50:"精英/えりーと"
                75:"高手/えーす"
                100:"上尉/きゃぷてん"
                150:"老将/べてらん"
                200:"帝王/いんぺりある"
                300:"绝对/ぜったい"
                400:"超凡之人/かりすま"
                500:"顶点/あるてぃめっと"
                600:"进击/しんげき"
                750:"巨人/きょじん"
                1000:"神话/しんわ"
                1250:"永远的旅人/えいえんのたびびと"
                1500:"冥王/めいおう"
                2000:"传奇/れじぇんど"
                10000:"够了停停吧/もうやめよう"
            func:(game,pl)->1
        # 最終日に生存
        aliveatlast:
            names:
                1:"生存/せいぞん"
                5:"苟活/いきのこり"
                30:"最终兵器/さいしゅうへいき"
            func:(game,pl)->
                if pl.dead
                    0
                else
                    1
        # 蘇生
        revive:
            names:
                1:"苏生/そせい"
                5:"黄泉归来/よみがえり"
                10:"不死王/ふしおう"
                15:"Undead/あんでっど"
                30:"不死鸟/ふしちょう"
            func:(game,pl)->
                game.gamelogs.filter((x)->x.id==pl.id && x.event=="revive").length
        # 信者になる
        brainwashed:
            names:
                1:"教/きょう"
                5:"信/しん"
                10:"徒/と"
            func:(game,pl)->
                game.gamelogs.filter((x)->x.target==pl.id && x.event=="brainwash").length
        # 突然死する
        gone:
            names:{}
            func:(game,pl)->
                game.gamelogs.filter((x)->x.id==pl.id && x.event=="found" && x.flag in ["gone-day","gone-night"]).length
    result.ownprizesprize=
        prizecount:
            names:
                100:"天上天下/てんじょうてんげ"
                200:"神之子/かみのこ"
                300:"至高/しこう"
                400:"究极/きゅうきょく"
                500:"超越者/ちょうえつしゃ"
            func:(prizes)->prizes.length
# 解析用ファンクション
# gameからプレイヤーオブジェクトを拾う
getpl=(game,userid)->
    game.players.filter((x)->x.id==userid)[0]
getplreal=(game,userid)->
    game.players.filter((x)->x.realid==userid)[0]

# Complexのtype一致を確かめる
chkCmplType=(obj,cmpltype)->
    # plがPlayerかただのobjか
    if obj.isCmplType?
        return obj.isCmplType cmpltype
    if obj.type=="Complex"
        obj.Complex_type==cmpltype || chkCmplType obj.Complex_main,cmpltype
    else
        false
# プレイヤー的职业を調べる
getType=(pl)->
    if pl.type=="Complex"
        getType pl.Complex_main
    else
        pl.type
# もともと的职业を調べる
getOriginalType=(game,userid)->
    getTypeAtTime game,userid,0
# あるプレイヤーのある時点で的职业を調べる
getTypeAtTime=(game,userid,day)->
    id=(pl=getpl(game,userid)).id
    ls=game.gamelogs.filter (x)->x.event=="transform" && x.id==id && x.day>day  # 変化履歴を調べる
    return ls[0]?.type ? getType pl
# チームを調べる
getTeamByType=(type)->
    for name,arr of Shared.game.teams
        if type in arr
            return name
    return ""

# repair6で使う用エクスポート
exports.getOriginalType=getOriginalType
exports.getTeamByType=getTeamByType
