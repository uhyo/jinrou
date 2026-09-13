Shared=
    game:require './../client/code/shared/game.coffee'
    prize:require './../client/code/shared/prize.coffee'

prizedata=require './prizedata'
prize={}
prizedata.makePrize (r)->
    prize=r

    # console.log prize

# 称号の静的定義から決まる部分(ID・達成条件・名称など)のスケルトン。
# 定義は実行中に変わらないので、初回の1回だけ構築して再利用する。
# 各行: {id,series,kind,team,required,name,phonetic}
#   series: "wincount" | "losecount" | "winteamcount" | "counter" | "ownprizes"
#   kind:   系列内の分類キー(職業名 / 陣営名 / カウント称号名)
#   team:   職業の所属陣営キー(wincount/losecount のみ。"all"=全職業通算、他系列はnull)
prizeStatusSkeleton=null
makePrizeStatusSkeleton=->
    unless prize.winteamcountprize?
        # 定義の読み込みがまだ済んでいない
        return null
    rows=[]
    # 一つの称号枠からスケルトン行を生成する(複数名称の称号は複数行になる)
    pushRows=(series,kind,idbase,countstr,raw,teamkey)->
        required=+countstr
        raws=if Array.isArray raw then raw else [raw]
        for name,i in raws
            [dname,dphonetic]=name.split "/"
            rows.push
                id: if i==0 then idbase else "#{idbase}:#{i}"
                series: series
                kind: kind
                team: teamkey ? null
                required: required
                name: dname
                phonetic: if dphonetic? then dphonetic else ""
    # 勝利回数
    if prize.wincountprize?
        for job,obj of prize.wincountprize
            # special_for_zhinai は特別貢献で手動付与される称号なので一覧には含めない
            continue if job=="special_for_zhinai"
            teamkey=if job=="all" then "all" else (prizedata.getTeamByType(job) || "Others")
            for countstr,name of obj
                pushRows "wincount",job,"wincount_#{job}_#{countstr}",countstr,name,teamkey
    # 敗北回数
    if prize.losecountprize?
        for job,obj of prize.losecountprize
            continue if job=="special_for_zhinai"
            teamkey=if job=="all" then "all" else (prizedata.getTeamByType(job) || "Others")
            for countstr,name of obj
                pushRows "losecount",job,"losecount_#{job}_#{countstr}",countstr,name,teamkey
    # 陣営勝利回数
    for team,obj of prize.winteamcountprize
        for countstr,name of obj
            pushRows "winteamcount",team,"winteamcount_#{team}_#{countstr}",countstr,name,null
    # カウント系
    for type,obj of prize.counterprize
        for countstr,name of obj.names
            pushRows "counter",type,"#{type}_#{countstr}",countstr,name,null
    # 所持数
    for type,obj of prize.ownprizesprize
        for countstr,name of obj.names
            pushRows "ownprizes",type,"#{type}_#{countstr}",countstr,name,null
    rows

# 内部用
module.exports=exports=
    checkPrize:(game,cb)->
        # 評価対象のプレイヤーをアレする
        pls=game.players.filter (x)->x.realid!="身代わりくん"
        result={}
        onecall= =>
            if pls.length==0
                # もうおわり
                cb result
                return
            # 最初のやつ
            pl=pls.pop()
            query={
                $setOnInsert:{userid:pl.realid},
                $inc:{}
            }
            type=prizedata.getOriginalType game,pl.id
            team=prizedata.getTeamByType type
            if pl.winner==true
                query.$inc["wincount.#{type}"]=1
                query.$inc["wincount.all"]=1
                if team
                    query.$inc["winteamcount.#{team}"]=1
            else if pl.winner==false
                query.$inc["losecount.#{type}"]=1
                query.$inc["losecount.all"]=1
                if team
                    query.$inc["loseteamcount.#{team}"]=1
            for prizename,obj of prize.counterprize
                inc=obj.func game,pl
                if inc>0
                    query.$inc["counter.#{prizename}"]=inc
            if Object.getOwnPropertyNames(query["$inc"]).length == 0
                delete query["$inc"]

            M.userlogs.findOneAndUpdate {userid: pl.realid}, query, {
                upsert: true
                returnDocument: "after"
            }, (err, res)->
                if err?
                    throw err
                doc = res.value
                unless doc?
                    console.error "checkPrize: doc is updefined"
                    onecall()
                    return

                # ユーザーのいままでの戦績が得られたので称号を算出していく
                gotprizes=[]
                wincount=doc.wincount ? {}
                losecount=doc.losecount ? {}
                winteamcount=doc.winteamcount ? {}
                counter=doc.counter ? {}
                for job,prs of prize.wincountprize
                    for numstr,name of prs
                        num=+numstr
                        if wincount[job]>=num
                            if Array.isArray name
                                # 複数ある
                                for _,i in name
                                    if i==0
                                        gotprizes.push "wincount_#{job}_#{numstr}"
                                    else
                                        gotprizes.push "wincount_#{job}_#{numstr}:#{i}"
                            else
                                gotprizes.push "wincount_#{job}_#{numstr}"
                for job,prs of prize.losecountprize
                    for numstr,name of prs
                        num=+numstr
                        if losecount[job]>=num
                            if Array.isArray name
                                # 複数ある
                                for _,i in name
                                    if i==0
                                        gotprizes.push "losecount_#{job}_#{numstr}"
                                    else
                                        gotprizes.push "losecount_#{job}_#{numstr}:#{i}"
                            else
                                gotprizes.push "losecount_#{job}_#{numstr}"
                for team,prs of prize.winteamcountprize
                    for numstr,name of prs
                        num=+numstr
                        if winteamcount[team]>=num
                            if Array.isArray name
                                for _,i in name
                                    if i==0
                                        gotprizes.push "winteamcount_#{team}_#{numstr}"
                                    else
                                        gotprizes.push "winteamcount_#{team}_#{numstr}:#{i}"
                            else
                                gotprizes.push "winteamcount_#{team}_#{numstr}"
                for type,obj of prize.counterprize
                    for numstr,name of obj.names
                        num=+numstr
                        if counter[type]>=num
                            if Array.isArray name
                                for _,i in name
                                    if i==0
                                        gotprizes.push "#{type}_#{numstr}"
                                    else
                                        gotprizes.push "#{type}_#{numstr}:#{i}"
                            else
                                gotprizes.push "#{type}_#{numstr}"
                for type,obj of prize.ownprizesprize
                    for numstr,name of obj.names
                        num=+numstr
                        if obj.func(gotprizes)>=num
                            if Array.isArray name
                                for _,i in name
                                    if i==0
                                        gotprizes.push "#{type}_#{num}"
                                    else
                                        gotprizes.push "#{type}_#{num}:#{i}"
                            else
                                gotprizes.push "#{type}_#{num}"
                result[doc.userid]=gotprizes
                onecall()

        onecall()
        # げーむ
        ###
        M.userlogs.find(query).each (err,doc)->
            if err?
                throw new err
            unless doc?
                # 全部おわった
            # 自分が参加したゲームを全て出す
            result=[]   # 賞の一覧
            # 勝敗数に関係する称号
            # 勝った試合のみ抜き出して自分だけにする
            mes=docs.map((x)->x.players.filter((pl)->pl.realid==userid)[0])
            wins=mes.filter((x)->x.winner)
            loses=mes.filter((x)->x.winner==false)
            for team,jobs of Shared.game.teams
                for job in jobs
                    count=wins.filter((x)->x.originalType==job).length
                    if count>0 && wincountprize[job]?
                        for num in Object.keys(wincountprize[job])
                            # 少ないほうから順に称号チェック
                            if num<=count
                                result.push "wincount_#{job}_#{num}"
                    count=loses.filter((x)->x.originalType==job).length
                    if count>0 && losecountprize[job]?
                        for num in Object.keys(losecountprize[job])
                            # 少ないほうから順に称号チェック
                            if num<=count
                                result.push "losecount_#{job}_#{num}"
            # docsに自分のIDを追加する
            docs.forEach (game)->
                game.myid=getplreal(game,userid).id
            # カウント称号
            for prizename,obj of counterprize
                count=docs.sum (game)->obj.func game,game.myid
                for num in Object.keys(obj.names)
                    # 昇順
                    if num<=count
                        result.push "#{prizename}_#{num}"
            # docごとカウント称号
            for prizename,obj of allcounterprize
                count=obj.func docs,userid
                for num in Object.keys(obj.names)
                    # 昇順
                    if num<=count
                        result.push "#{prizename}_#{num}"
            # mesでカウントする称号
            for prizename,obj of allplayersprize
                count=obj.func mes,userid
                for num in Object.keys(obj.names)
                    # 昇順
                    if num<=count
                        result.push "#{prizename}_#{num}"
            # prizesでカウントする称号
            for prizename,obj of ownprizesprize
                bool=obj.func result,userid
                if bool
                    result.push prizename
            #console.log "#{userid} : #{JSON.stringify result}"
            cb result
        ###

    
    prizeName:(prizeid)->prize.names[prizeid]    # IDを名前に
    prizePhonetic:(prizeid)->prize.phonetics[prizeid]
    prizeQuote:(prizename)->"≪#{prizename}≫"

    # 称号の状態一覧(達成条件と現在の進捗)を計算する
    # 引数の userlog は userlogs コレクションのドキュメント
    # 戻り値: [{id,series,kind,team,required,current,achieved,name,phonetic}, ...]
    # 静的部分はスケルトンを再利用し、進捗(current/achieved)だけを毎回埋める
    getPrizeStatus:(userlog)->
        prizeStatusSkeleton ?= makePrizeStatusSkeleton()
        unless prizeStatusSkeleton?
            # 定義の読み込みがまだ済んでいない
            return []
        wincount=userlog?.wincount ? {}
        losecount=userlog?.losecount ? {}
        winteamcount=userlog?.winteamcount ? {}
        counter=userlog?.counter ? {}
        result=[]
        # ownprizes系以外で達成済みの称号数(ownprizes系の判定に使う)
        achievedcount=0
        # ownprizes系は一覧の最後に来るので、そこまでの達成数で判定できる
        for row in prizeStatusSkeleton
            current=switch row.series
                when "wincount" then wincount[row.kind] ? 0
                when "losecount" then losecount[row.kind] ? 0
                when "winteamcount" then winteamcount[row.kind] ? 0
                when "counter" then counter[row.kind] ? 0
                else achievedcount
            achieved=current>=row.required
            # 毎回新しい行にする(rpc層がjobName等を後付けするため)
            result.push Object.assign {}, row,
                current: current
                achieved: achieved
            if achieved && row.series!="ownprizes"
                achievedcount+=1
        result

###
・役職ごとの勝利回数賞
"wincount_(役職名)_(回数)" というIDをつける
例） "wincount_Diviner_5"
・役職ごとの敗北回数賞
"losecount_(役職名)_(回数)" というIDをつける
例) "losecount_Human_20"

・カウント系称号
"(称号名)_(回数)" というIDをつける
例） "cursekill_5"

・単品系称号
"(称号名)" というIDをつける
###
