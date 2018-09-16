csv=require 'csv'
path=require 'path'
fs=require 'fs'

libi18n = require './libs/i18n.coffee'

i18n = libi18n.getWithDefaultNS 'prizedata'

Shared=
    game:require '../client/code/shared/game'

# コールバック:{
#   names:{}
#   phonetics:{}
# }
makePrize=(cb)->
    # 勝利と敗北を読み込む
    result={
        names: {}
        phonetics: {}
    }
    cb2 = (result)->
        libi18n.addResourceLoadCallback ->
            # 残り
            makeOtherPrize result
            # 称号IDと名前の対応表を作る
            makeNames result
            cb result

    dir=path.normalize __dirname+"/../prizedata"
    fs.readFile path.join(dir,"win.csv"),{encoding:"utf8"}, (err,data)->
        if err?
            cb2 result
            return
        csv.parse data, {
            relax_column_count: true,
        }, (err,arr)->
            if err?
                cb2 result
                return
            result.wincountprize = loadTable arr
            fs.readFile path.join(dir,"lose.csv"),{encoding:"utf8"}, (err,data)->
                if err?
                    cb2 result
                    return
                csv.parse data, {
                    relax_column_count: true,
                }, (err,arr)->
                    if err?
                        cb2 result
                        return
                    result.losecountprize = loadTable arr
                    cb2 result
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

# 名前つける
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
    if result.wincountprize?
        for job,obj of result.wincountprize
            for num,name of obj
                mset "wincount_#{job}_#{num}",name
    if result.losecountprize?
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
    prizedata = libi18n.getResource 'prizedata'
    result.winteamcountprize = prizedata.winteamcount
    result.loseteamcountprize = prizedata.loseteamcount
    result.counterprize=
        # 呪殺
        cursekill:
            names: prizedata.counter.cursekill
            func:(game,pl)->
                # 呪殺を数える
                game.gamelogs.filter((x)->x.id==pl.id && x.event=="cursekill").length
        # 初日黒
        divineblack2:
            names: prizedata.counter.divineblack2
            func:(game,pl)->
                game.gamelogs.filter((x)->x.id==pl.id && x.event=="divine" && x.flag in Shared.game.blacks).length

        # GJ判定
        GJ:
            names: prizedata.counter.GJ
            func:(game,pl)->
                game.gamelogs.filter((x)->x.id==pl.id && x.event=="GJ").length
        # 恋人の勝利回数
        lovers_wincount:
            names: prizedata.counter.lovers_wincount
            func:(game,pl)->
                if pl.winner && pl.isFriend()
                    1
                else
                    0
        # 恋人の敗北回数
        lovers_losecount:
            names: prizedata.counter.lovers_losecount
            func:(game,pl)->
                if !pl.winner && pl.isFriend()
                    1
                else
                    0
        # 商品を受け取った回数
        getkits_merchant:
            names: prizedata.counter.getkits_merchant
            func:(game,pl)->
                game.gamelogs.filter((x)->x.target==pl.id && x.event=="sendkit").length
        # 商品を人狼側に送った回数
        sendkits_to_wolves:
            names: prizedata.counter.sendkits_to_wolves
            func:(game,pl)->
                game.gamelogs.filter((x)->x.id==pl.id && x.event=="sendkit" && getTeamByType(getTypeAtTime(game,x.target,x.day))=="Werewolf").length
        # コピーせずに終了
        nocopy:
            names: prizedata.counter.nocopy
            func:(game,pl)->
                if pl.type=="Copier"
                    1
                else
                    0
        # 2日目昼に吊られた
        day2hanged:
            names: prizedata.counter.day2hanged
            func:(game,pl)->
                game.gamelogs.filter((x)->
                    x.id==pl.id && x.event=="found" && x.flag=="punish" && x.day==2
                ).length

        # 総試合数
        allgamecount:
            names: prizedata.counter.allgamecount
            func:(game,pl)->1
        # 最終日に生存
        aliveatlast:
            names: prizedata.counter.aliveatlast
            func:(game,pl)->
                if pl.dead
                    0
                else
                    1
        # 蘇生
        revive:
            names: prizedata.counter.revive
            func:(game,pl)->
                game.gamelogs.filter((x)->x.id==pl.id && x.event=="revive").length
        # 信者になる
        brainwashed:
            names: prizedata.counter.brainwashed
            func:(game,pl)->
                game.gamelogs.filter((x)->x.target==pl.id && x.event=="brainwash").length
        # 突然死する
        gone:
            names: {}
            func:(game,pl)->
                game.gamelogs.filter((x)->x.id==pl.id && x.event=="found" && x.flag in ["gone-day","gone-night"]).length
        # 獅子舞に噛まれる
        shishimaibit:
            names: prizedata.counter.shishimaibit
            func:(game,pl)->
                game.gamelogs.filter((x)->x.target==pl.id && x.event=="shishimaibit").length
    result.ownprizesprize=
        prizecount:
            names: prizedata.ownprizes.prizecount
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
# プレイヤーの役職を調べる
getType=(pl)->
    if pl.type=="Complex"
        getType pl.Complex_main
    else
        pl.type
# もともとの役職を調べる
getOriginalType=(game,userid)->
    # originalType情報を使用
    pl = getpl game, userid
    if pl?.originalType
        return pl.originalType
    getTypeAtTime game,userid,0
# あるプレイヤーのある時点での役職を調べる
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
