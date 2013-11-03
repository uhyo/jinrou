#,type シェアするやつ
Shared=
    game:require '../../../client/code/shared/game.coffee'
    prize:require '../../../client/code/shared/prize.coffee'

#内部用
module.exports=
    newGame: (room,ss)->
        game=new Game ss,room
        games[room.id]=game
        M.games.insert game.serialize()
    # ゲームオブジェクトを読み込んで使用可能にする
    ###
    loadDB:(roomid,ss,cb)->
        if games[roomid]
            # 既に読み込んでいる
            cb games[roomid]
            return
        M.games.find({finished:false}).each (err,doc)->
            return unless doc?
            if err?
                console.log err
                throw err
            games[doc.id]=Game.unserialize doc,ss
    ###
    # プレイヤーが入室したぞ!
    inlog:(room,player)->
        name="#{player.name}"
        pr=""
        unless room.blind in ["complete","yes"]
            # 覆面のときは称号OFF
            player.nowprize?.forEach? (x)->
                if x.type=="prize"
                    prname=Server.prize.prizeName x.value
                    if prname?
                        pr+=prname
                else
                    # 接続
                    pr+=x.value
            if pr
                name="#{Server.prize.prizeQuote pr}#{name}"
        log=
            comment:"#{name}さんが訪れました。"
            userid:-1
            name:null
            mode:"system"
        if games[room.id]
            splashlog room.id,games[room.id], log
            # プレイヤーを追加
            newpl=Player.factory "Waiting"
            newpl.setProfile {
                id:player.userid
                realid:player.realid
                name:player.name
            }
            newpl.target=null
            games[room.id].players.push newpl
            games[room.id].participants.push newpl
    outlog:(room,player)->
        log=
            comment:"#{player.name}さんが去りました。"
            userid:-1
            name:null
            mode:"system"
        if games[room.id]
            splashlog room.id,games[room.id], log
            games[room.id].players=games[room.id].players.filter (pl)->pl.realid!=player.realid
            games[room.id].participants=games[room.id].participants.filter (pl)->pl.realid!=player.realid
    kicklog:(room,player)->
        log=
            comment:"#{player.name}さんが追い出されました。"
            userid:-1
            name:null
            mode:"system"
        if games[room.id]
            splashlog room.id,games[room.id], log
            games[room.id].players=games[room.id].players.filter (pl)->pl.realid!=player.realid
            games[room.id].participants=games[room.id].participants.filter (pl)->pl.playerid!=player.realid
    helperlog:(room,player,topl)->
        log=null
        if topl?
            log=
                comment:"#{player.name}さんが#{topl.name}さんのヘルパーになりました。"
                userid:-1
                name:null
                mode:"system"
        else
            log=
                comment:"#{player.name}さんがヘルパーをやめました。"
                userid:-1
                name:null
                mode:"system"

        if games[room.id]
            splashlog room.id,games[room.id], log
    deletedlog:(room)->
        log=
            comment:"この部屋は廃村になりました。"
            userid:-1
            name:null
            mode:"system"
        if games[room.id]
            splashlog room.id,games[room.id], log
    # 状況に応じたチャンネルを割り当てる
    playerchannel:(roomid,session)->
        game=games[roomid]
        unless game?
            return
        player=game.getPlayerReal session.userId
        unless player?
            session.channel.subscribe "room#{roomid}_audience"
#           session.channel.subscribe "room#{roomid}_notwerewolf"
#           session.channel.subscribe "room#{roomid}_notcouple"
            return
        if player.isJobType "GameMaster"
            session.channel.subscribe "room#{roomid}_gamemaster"
            return
        ###
        if player.dead
            session.channel.subscribe "room#{roomid}_heaven"
        if game.rule.heavenview!="view" || !player.dead
            if player.isWerewolf()
                session.channel.subscribe "room#{roomid}_werewolf"
            else
                session.channel.subscribe "room#{roomid}_notwerewolf"
        if game.rule.heavenview!="view" || !player.dead
            if player.type=="Couple"
                session.channel.subscribe "room#{roomid}_couple"
            else
                session.channel.subscribe "room#{roomid}_notcouple"
        if player.type=="Fox"
            session.channel.subscribe "room#{roomid}_fox"
        ###
Server=
    game:
        game:module.exports
        rooms:require './rooms.coffee'
    prize:require '../../prize.coffee'
    oauth:require '../../oauth.coffee'
class Game
    constructor:(@ss,room)->
        # @ss: ss
        if room?
            @id=room.id
            # GMがいる場合
            @gm= if room.gm then room.owner.userid else null
        
        @logs=[]
        @players=[]         # 村人たち
        @participants=[]    # 参加者全て(@playersと同じ内容含む）
        @rule=null
        @finished=false #終了したかどうか
        @day=0  #何日目か(0=準備中)
        @night=false # false:昼 true:夜
        
        @winner=null    # 勝ったチーム名
        @quantum_patterns=[]    # 全部の場合を列挙({(id):{jobtype:"Jobname",dead:Boolean},...})
        # DBには現れない
        @timerid=null
        @voting=false   # 投票猶予時間
        @timer_start=null   # 残り時間のカウント開始時間（秒）
        @timer_remain=null  # 残り時間全体（秒）
        @timer_mode=null    # タイマーの名前
        @revote_num=0   # 再投票を行った回数
        
        @werewolf_target=[] # 人狼の襲い先
        @werewolf_target_remain=0   #襲撃先をあと何人設定できるか
        @werewolf_flag=null # 人狼襲撃に関するフラグ

        @slientexpires=0    # 静かにしてろ！（この時間まで）

        @gamelogs=[]
        @iconcollection={}  #(id):(url)
        # 決定配役（DBに入らないかも・・・）
        @joblist=null
        # ゲームスタートに必要な情報
        @startoptions=null
        @startplayers=null
        @startsupporters=null

        # 希望役職制のときに開始前に役職選択するフェーズ
        @rolerequestingphase=false
        @rolerequesttable={}    # 一覧{(id):(jobtype)}
        
        # 投票箱を用意しておく
        @votingbox=new VotingBox this
        ###
        さまざまな出来事
        id: 動作した人
        gamelogs=[
            {id:(id),type:(type/null),target:(id,null),event:(String),flag:(String),day:(Number)},
            {...},
        ###
    # JSON用object化(DB保存用）
    serialize:->
        {
            id:@id
            logs:@logs
            rule:@rule
            players:@players.map (x)->x.serialize()
            # 差分
            additionalParticipants: @participants?.filter((x)=>@players.indexOf(x)<0).map (x)->x.serialize()
            finished:@finished
            day:@day
            night:@night
            winner:@winner
            jobscount:@jobscount
            gamelogs:@gamelogs
            gm:@gm
            iconcollection:@iconcollection
            werewolf_flag:@werewolf_flag
            werewolf_target:@werewolf_target
            werewolf_target_remain:@werewolf_target_remain
            #quantum_patterns:@quantum_patterns
        }
    #DB用をもとにコンストラクト
    @unserialize:(obj,ss)->
        game=new Game ss
        game.id=obj.id
        game.gm=obj.gm
        game.logs=obj.logs
        game.rule=obj.rule
        game.players=obj.players.map (x)->Player.unserialize x
        # 追加する
        if obj.additionalParticipants
            game.participants=game.players.concat obj.additionalParticipants.map (x)->Player.unserialize x
        else
            game.participants=game.players.concat []

        game.finished=obj.finished
        game.day=obj.day
        game.night=obj.night
        game.winner=obj.winner
        game.jobscount=obj.jobscount
        game.gamelogss=obj.gamelogs ? {}
        game.gm=obj.gm
        game.iconcollection=obj.iconcollection ? {}
        game.werewolf_flag=obj.werewolf_flag ? null
        game.werewolf_target=obj.werewolf_target ? []
        game.werewolf_target_remain=obj.werewolf_target_remain ? 0
        # 開始前なら準備中を用意してあげないと！
        if game.day==0
            Server.game.rooms.oneRoomS game.id,(room)->
                if room.error?
                    return
                game.players=[]
                for plobj in room.players
                    newpl=Player.factory "Waiting"
                    newpl.setProfile {
                        id:plobj.userid
                        realid:plobj.realid
                        name:plobj.name
                    }
                    newpl.target=null
                    game.players.push newpl
                game.participants=game.players.concat []

        game.quantum_patterns=obj.quantum_patterns ? []
        if game.rule
            game.timer()
        game
    # 公開情報
    publicinfo:(obj)->  #obj:オプション
        {
            rule:@rule
            finished:@finished
            players:@players.map (x)=>
                r=x.publicinfo()
                r.icon= @iconcollection[x.id] ? null
                    
                if obj?.openjob
                    r.jobname=x.getJobname()
                    #r.option=x.optionString()
                    r.option=""
                    r.originalJobname=x.originalJobname
                    r.winner=x.winner
                unless @rule?.blind=="complete" || (@rule?.blind=="yes" && !@finished)
                    # 公開してもよい
                    r.realid=x.realid
                r
            day:@day
            night:@night
            jobscount:@jobscount
        }
    # IDからプレイヤー
    getPlayer:(id)->
        @players.filter((x)->x.id==id)[0]
    getPlayerReal:(realid)->
        #@players.filter((x)->x.realid==realid)[0] || if @gm && @gm==realid then new GameMaster realid,realid,"ゲームマスター"
        @participants.filter((x)->x.realid==realid)[0]
    # DBにセーブ
    save:->
        M.games.update {id:@id},@serialize()
    # gamelogsに追加
    addGamelog:(obj)->
        @gamelogs ?= []
        @gamelogs.push {
            id:obj.id ? null
            type:obj.type ? null
            target:obj.target ? null
            event:obj.event ? null
            flag:obj.flag ? null
            day:@day    # 何気なく日付も追加
        }
        
    setrule:(rule)->@rule=rule
    #成功:null
    #players: 参加者 supporters: その他
    setplayers:(res)->
        options=@startoptions
        players=@startplayers
        supporters=@startsupporters
        jnumber=0
        joblist=@joblist
        players=players.concat []   #コピー
        plsl=players.length #実際の参加人数（身代わり含む）
        if @rule.scapegoat=="on"
            plsl++
        @players=[]
        @iconcollection={}
        for job,num of joblist
            #console.log "#{job}:#{num}"
            unless isNaN num
                jnumber+=parseInt num
            if parseInt(num)<0
                res "プレイヤー数が不正です（#{job}:#{num})。このエラーは数回やり直せば直る場合があります。"
                return

        if jnumber!=plsl
            # 数が合わない
            res "プレイヤー数が不正です(#{jnumber}/#{plsl}/#{players.length})。このエラーは数回やり直せば直る場合があります。"
            return

        # 名前と数を出したやつ
        @jobscount={}
        unless options.yaminabe_hidejobs    # 公開モード
            for job,num of joblist
                continue unless num>0
                testpl=new jobs[job]
                @jobscount[job]=
                    name:testpl.jobname
                    number:num

        # 盗賊の処理
        thief_jobs=[]
        if joblist.Thief>0
            # 盗人一人につき2回抜く
            for i in [0...(joblist.Thief*2)]
                # 1つ抜く
                keys=[]
                # 数に比例した役職一覧を作る
                for job,num of joblist
                    unless job in Shared.game.nonhumans
                        for j in [0...num]
                            keys.push job
                keys=shuffle keys

                until keys.length==0 || joblist[keys[0]]>0
                    # 抜けない
                    keys.splice 0,1
                # これは抜ける
                if keys.length==0
                    # もう無い
                    res "盗人の処理に失敗しました"
                    return
                thief_jobs.push keys[0]
                joblist[keys[0]]--
                # 代わりに村人1つ入れる
                joblist.Human ?= 0
                joblist.Human++




        # まず身代わりくんを決めてあげる
        if @rule.scapegoat=="on"
            # 人狼、妖狼にはならない
            i=0 # 無限ループ防止
            nogoat=[]   #身代わりがならない役職
            if @rule.safety!="free"
                nogoat=nogoat.concat Shared.game.nonhumans  #人外は除く
            if @rule.safety=="full"
                # 危ない
                nogoat=nogoat.concat ["QueenSpectator","Spy2","Poisoner","Cat"]
            jobss=[]
            for job in Object.keys jobs
                continue if !joblist[job] || (job in nogoat)
                j=0
                while j<joblist[job]
                    jobss.push job
                    j++
            while ++i<100
                r=Math.floor Math.random()*jobss.length
                continue unless joblist[jobss[r]]>0
                # 役職はjobss[r]
                newpl=Player.factory jobss[r]   #身代わりくん
                newpl.setProfile {
                    id:"身代わりくん"
                    realid:"身代わりくん"
                    name:"身代わりくん"
                }
                newpl.scapegoat=true
                @players.push newpl
                joblist[jobss[r]]--
                break
            if @players.length==0
                # 決まっていない
                res "配役に失敗しました"
                return
            
        if @rule.rolerequest=="on"
            # 希望役職制ありの場合はまず希望を優先してあげる
            for job,num of joblist
                while num>0
                    # 候補を集める
                    conpls=players.filter (x)=>
                        @rolerequesttable[x.userid]==job
                    if conpls.length==0
                        # もうない
                        break
                    # 候補がいたので決めてあげる
                    r=Math.floor Math.random()*conpls.length
                    pl=conpls[r]
                    players=players.filter (x)->x!=pl
                    newpl=Player.factory job
                    newpl.setProfile {
                        id:pl.userid
                        realid:pl.realid
                        name:pl.name
                    }
                    @players.push newpl
                    if pl.icon
                        @iconcollection[newpl.id]=pl.icon
                    if pl.scapegoat
                        # 身代わりくん
                        newpl.scapegoat=true
                    num--
                # 残った分は戻す
                joblist[job]=num


        # ひとり決める
        for job,num of joblist
            i=0
            while i++<num
                r=Math.floor Math.random()*players.length
                pl=players[r]
                newpl=Player.factory job
                newpl.setProfile {
                    id:pl.userid
                    realid:pl.realid
                    name:pl.name
                }
                @players.push newpl
                players.splice r,1
                if pl.icon
                    @iconcollection[newpl.id]=pl.icon
                if pl.scapegoat
                    # 身代わりくん
                    newpl.scapegoat=true
        if joblist.Thief>0
            # 盗人がいる場合
            thieves=@players.filter (x)->x.isJobType "Thief"
            for pl in thieves
                pl.flag=JSON.stringify thief_jobs.splice 0,2

        # サブ系
        if options.decider
            # 決定者を作る
            r=Math.floor Math.random()*@players.length
            pl=@players[r]
        
            newpl=Player.factory null,pl,null,Decider   # 酔っ払い
            pl.transProfile newpl
            pl.transform @,newpl,true
        if options.authority
            # 権力者を作る
            r=Math.floor Math.random()*@players.length
            pl=@players[r]
        
            newpl=Player.factory null,pl,null,Authority # 酔っ払い
            pl.transProfile newpl
            pl.transform @,newpl,true
        
        if @rule.wolfminion
            # 狼の子分がいる場合、子分決定者を作る
            wolves=@players.filter((x)->x.isWerewolf())
            if wolves.length>0
                r=Math.floor Math.random()*wolves.length
                pl=wolves[r]
                
                sub=Player.factory "MinionSelector" # 子分決定者
                pl.transProfile sub
                
                newpl=Player.factory null,pl,sub,Complex
                pl.transProfile newpl
                pl.transform @,newpl
        if @rule.drunk
            # 酔っ払いがいる場合
            nonvillagers= @players.filter (x)->!x.isJobType "Human"
            
            if nonvillagers.length>0
            
                r=Math.floor Math.random()*nonvillagers.length
                pl=nonvillagers[r]
            
                newpl=Player.factory null,pl,null,Drunk # 酔っ払い
                pl.transProfile newpl
                pl.transform @,newpl,true

            
        # プレイヤーシャッフル
        @players=shuffle @players
        @participants=@players.concat []    # コピー
        # ここでプレイヤー以外の処理をする
        for pl in supporters
            if pl.mode=="gm"
                # ゲームマスターだ
                gm=Player.factory "GameMaster"
                gm.setProfile {
                    id:pl.userid
                    realid:pl.realid
                    name:pl.name
                }
                @participants.push gm
            else if result=pl.mode.match /^helper_(.+)$/
                # ヘルパーだ
                ppl=@players.filter((x)->x.id==result[1])[0]
                unless ppl?
                    res "#{pl.name}さんのヘルパー対象が存在しませんでした"
                    return
                helper=Player.factory "Helper"
                helper.setProfile {
                    id:pl.realid
                    realid:pl.realid
                    name:pl.name
                }
                helper.flag=ppl.id  # ヘルプ先
                @participants.push helper
            #@participants.push new GameMaster pl.userid,pl.realid,pl.name
        
        # 量子人狼の場合はここで可能性リストを作る
        if @rule.jobrule=="特殊ルール.量子人狼"
            # パターンを初期化（最初は全パターン）
            quats=[]    # のとみquantum_patterns
            pattern_no=0    # とばす
            # 役職を列挙した配列をつくる
            jobname_list=[]
            for job of jobs
                i=@rule.quantum_joblist[job]
                if i>0
                    jobname_list.push {
                        type:job,
                        number:i
                    }
            # 人狼用
            i=1
            while @rule.quantum_joblist["Werewolf#{i}"]>0
                jobname_list.push {
                    type:"Werewolf#{i}"
                    number:@rule.quantum_joblist["Werewolf#{i}"]
                }
                i++
            # プレイヤーIDを列挙した配列もつくる
            playerid_list=@players.map (pl)->pl.id
            # 0,1,...,(n-1)の中からkコ選んだ組み合わせを返す関数
            combi=(n,k)->
                `var i;`
                if k<=0
                    return [[]]
                if n<=k #n<kのときはないけど・・・
                    return [[0...n]] # 0からn-1まで
                resulty=[]
                for i in [0..(n-k)] # 0 <= i <= n-k
                    for x in combi n-i-1,k-1
                        resulty.push [i].concat x.map (y)->y+i+1
                resulty

            # 職をひとつ処理
            makeonejob=(joblist,plids)->
                cont=joblist[0]
                unless cont?
                    return [[]]
                # 決めて抜く
                coms=combi plids.length,cont.number
                # その番号のを
                resulty2=[]
                for pat in coms #pat: 1つのパターン
                    bas=[]
                    pll=plids.concat []
                    i=0
                    for num in pat
                        bas.push {
                            id:pll[num-i]
                            job:cont.type
                        }
                        pll.splice num-i,1  # 抜く
                        i+=1
                    resulty2=resulty2.concat makeonejob(joblist.slice(1),pll).map (arr)->
                        bas.concat arr
                resulty2

            jobsobj=makeonejob jobname_list,playerid_list
            # パターンを作る
            for arr in jobsobj
                obj={}
                for o in arr
                    result=o.job.match /^Werewolf(\d+)$/
                    if result
                        obj[o.id]={
                            jobtype:"Werewolf"
                            rank:+result[1] # 狼の序列
                            dead:false
                        }
                    else
                        obj[o.id]={
                            jobtype:o.job
                            dead:false
                        }
                quats.push obj
            # できた
            @quantum_patterns=quats
            if @rule.quantumwerewolf_table=="anonymous"
                # 確率表は数字で表示するので番号をつけてあげる
                for pl,i in shuffle @players.concat []
                    pl.flag=JSON.stringify {
                        number:i+1
                    }

        res null
#======== ゲーム進行の処理
    #次のターンに進む
    nextturn:->
        clearTimeout @timerid
        if @day<=0
            # はじまる前
            @day=1
            @night=true
        else if @night==true
            @day++
            @night=false
        else
            @night=true

        log=
            mode:"nextturn"
            day:@day
            night:@night
            userid:-1
            name:null
            comment:"#{@day}日目の#{if @night then '夜' else '昼'}になりました。"
        splashlog @id,this,log

        #死体処理
        @bury()

        if @rule.jobrule=="特殊ルール.量子人狼"
            # 量子人狼
            # 全員の確率を出してあげるよーーーーー
            # 確率テーブルを
            probability_table={}
            numberref_table={}
            for x in @players
                dead=0
                for obj in @quantum_patterns
                    if obj[x.id].dead==true
                        dead++
                if dead==@quantum_patterns.length
                    # 死んだ!!!!!!!!!!!!!!!!!
                    x.die this,"werewolf"
            for x in @players
                count=
                    Human:0
                    Diviner:0
                    Werewolf:0
                    dead:0
                for obj in @quantum_patterns
                    count[obj[x.id].jobtype]++
                    if obj[x.id].dead==true
                        count.dead++
                sum=count.Human+count.Diviner+count.Werewolf
                pflag=JSON.parse x.flag
                if sum==0
                    # 世界が崩壊した
                    x.flag=JSON.stringify {
                        number:pflag?.number
                        Human:0
                        Diviner:0
                        Werewolf:0
                        dead:0
                    }
                    # ログ用
                    probability_table[x.id]={
                        name:x.name
                        Human:0
                        Werewolf:0
                        dead:0
                    }
                    if @rule.quantumwerewolf_diviner=="on"
                        # 占い師の確率も
                        probability_table[x.id].Diviner=0
                else
                    x.flag=JSON.stringify {
                        number:pflag?.number
                        Human:count.Human/sum
                        Diviner:count.Diviner/sum
                        Werewolf:count.Werewolf/sum
                        dead:count.dead/sum
                    }
                    # ログ用
                    if @rule.quantumwerewolf_diviner=="on"
                        probability_table[x.id]={
                            name:x.name
                            Human:count.Human/sum
                            Diviner:count.Diviner/sum
                            Werewolf:count.Werewolf/sum
                            dead:count.dead/sum
                        }
                    else
                        probability_table[x.id]={
                            name:x.name
                            Human:(count.Human+count.Diviner)/sum
                            Werewolf:count.Werewolf/sum
                            dead:count.dead/sum
                        }
                if @rule.quantumwerewolf_table=="anonymous"
                    # 番号を表示
                    numberref_table[pflag.number]=x
                    probability_table[x.id].name="プレイヤー#{pflag.number}"
            if @rule.quantumwerewolf_table=="anonymous"
                # ソートしなおしてあげて痕跡を消す
                probability_table=((probability_table,numberref_table)->
                    result={}
                    i=1
                    x=null
                    while x=numberref_table[i]
                        result["_$_player#{i}"]=probability_table[x.id]
                        i++
                    result
                )(probability_table,numberref_table)
            # ログを出す
            log=
                mode:"probability_table"
                probability_table:probability_table
            splashlog @id,this,log
            # もう一回死体処理
            @bury()
    
        return if @judge()

        @voting=false
        if @night
            # jobデータを作る
            # 人狼の襲い先
            @werewolf_target=[]
            unless @day==1 && @rule.scapegoat!="off"
                @werewolf_target_remain=1
            else if @rule.scapegoat=="on"
                # 誰が襲ったかはランダム
                onewolf=@players.filter (x)->x.isWerewolf()
                if onewolf.length>0
                    r=Math.floor Math.random()*onewolf.length
                    @werewolf_target.push {
                        from:onewolf[r].id
                        to:"身代わりくん"    # みがわり
                    }
                    console.log "aoo!",onewolf[r].id
                @werewolf_target_remain=0
            else
                # 誰も襲わない
                @werewolf_target_remain=0
            
            if @werewolf_flag=="Diseased"
                # 病人フラグが立っている（今日は襲撃できない
                @werewolf_flag=null
                @werewolf_target_remain=0
                log=
                    mode:"wolfskill"
                    comment:"人狼たちは病気になりました。今日は襲撃できません。"
                splashlog @id,this,log
            else if @werewolf_flag=="WolfCub"
                # 狼の子フラグが立っている（2回襲撃できる）
                @werewolf_flag=null
                @werewolf_target_remain=2
                log=
                    mode:"wolfskill"
                    comment:"狼の子の力で、今日は2人襲撃できます。"
                splashlog @id,this,log
            
            for pl in @players
                if pl.dead
                    pl.deadsunset this
                else
                    pl.sunset this
        else
            # 処理
            if @rule.deathnote
                # デスノート採用
                alives=@players.filter (x)->!x.dead
                if alives.length>0
                    r=Math.floor Math.random()*alives.length
                    pl=alives[r]
                    sub=Player.factory "Light"  # 副を作る
                    pl.transProfile sub
                    sub.sunset this
                    newpl=Player.factory null,pl,sub,Complex
                    pl.transProfile newpl
                    @players.forEach (x,i)=>    # 入れ替え
                        if x.id==newpl.id
                            @players[i]=newpl
                        else
                            x
                
            # 投票リセット処理
            @votingbox.init()
            for pl in @players
                if pl.dead
                    pl.deadsunrise this
                else
                    pl.sunrise this
            for pl in @players
                if !pl.dead
                    pl.votestart this
            @revote_num=0   # 再投票の回数は0にリセット

        #死体処理
        @bury()
        return if @judge()
        @splashjobinfo()
        if @night
            @checkjobs()
        else
            # 昼は15秒ルールがあるかも
            if @rule.silentrule>0
                @silentexpires=Date.now()+@rule.silentrule*1000 # これまでは黙っていよう！
        @save()
        @timer()
    #全員に状況更新 pls:状況更新したい人を指定する場合の配列
    splashjobinfo:(pls)->
        unless pls?
            # プレイヤー以外にも
            @ss.publish.channel "room#{@id}_audience","getjob",makejobinfo this,null
            # GMにも
            if @gm?
                @ss.publish.channel "room#{@id}_gamemaster","getjob",makejobinfo this,@getPlayerReal @gm
            pls=@participants

        pls.forEach (x)=>
            @ss.publish.user x.realid,"getjob",makejobinfo this,x
    #全員寝たかチェック 寝たなら処理してtrue
    #timeoutがtrueならば時間切れなので時間でも待たない
    checkjobs:(timeout)->
        if @day==0
            # 開始前（希望役職制）
            if timeout || @players.every((x)=>@rolerequesttable[x.id]?)
                # 全員できたぞ
                @setplayers (result)=>
                    unless result?
                        @rolerequestingphase=false
                        @nextturn()
                        @ss.publish.channel "room#{@id}","refresh",{id:@id}
                true
            else
                false

        else if @players.every( (x)=>x.dead || x.sleeping(@))
            if @voting || timeout || !@rule.night || @rule.waitingnight!="wait" #夜に時間がある場合は待ってあげる
                @midnight()
                @nextturn()
                true
            else
                false
        else
            false

    #夜の能力を処理する
    midnight:->
        players=shuffle @players.concat []
        players.forEach (player)=>
            unless player.dead
                player.midnight this
            else
                player.deadnight this
            
        # 狼の処理
        for target in @werewolf_target
            t=@getPlayer target.to
            continue unless t?
            # 噛まれた
            t.addGamelog this,"bitten"
            if @rule.noticebitten=="notice" || t.isJobType "Devil"
                log=
                    mode:"skill"
                    to:t.id
                    comment:"#{t.name}は人狼に襲われました。"
                splashlog @id,this,log
            if t.willDieWerewolf && !t.dead
                # 死んだ
                t.die this,"werewolf",target.from
            # 逃亡者を探す
            runners=@players.filter (x)=>!x.dead && x.isJobType("Fugitive") && x.target==target.to
            runners.forEach (x)=>
                x.die this,"werewolf",target.from   # その家に逃げていたら逃亡者も死ぬ

            if !t.dead
                # 死んでない
                res = @werewolf_flag?.match? /^GreedyWolf_(.+)$/
                if res?
                    # 欲張り狼がやられた!
                    gw = @getPlayer res[1]
                    if gw?
                        gw.die this,"werewolf"
                        gw.addGamelog this,"greedyKilled",t.type,t.id
                        # 以降は襲撃できない
                        break
                res = @werewolf_flag?.match? /^ToughWolf_(.+)$/
                if res?
                    # 一途な狼がすごい
                    tw = @getPlayer res[1]
                    t.dead=true
                    t.found="werewolf"
                    t.dying this,"werewolf",tw.id
                    if tw?
                        tw.die this,"werewolf"
                        tw.addGamelog this,"toughwolfKilled",t.type,t.id

    # 死んだ人を処理する
    bury:->
        alives=@players.filter (x)->!x.dead
        alives.forEach (x)=>
            x.beforebury this
        deads=@players.filter (x)->x.dead && x.found
        deads=shuffle deads # 順番バラバラ
        deads.forEach (x)=>
            situation=switch x.found
                #死因
                when "werewolf","poison","hinamizawa","vampire","witch","dog","trap"
                    "無惨な姿で発見されました"
                when "curse"    # 呪殺
                    if @rule.deadfox=="obvious"
                        "呪殺されました"
                    else
                        "無惨な姿で発見されました"
                when "punish"
                    "処刑されました"
                when "spygone"
                    "村を去りました"
                when "deathnote"
                    "死体で発見されました"
                when "foxsuicide"
                    "狐の後を追って自ら死を選びました"
                when "friendsuicide"
                    "恋人の後を追って自ら死を選びました"
                when "infirm"
                    "老衰で死亡しました"
                when "gmpunish"
                    "GMによって死亡しました"
                when "gone-day"
                    "投票しなかったため突然死しました。突然死は重大な迷惑行為なので絶対にしないようにしましょう。"
                when "gone-night"
                    "夜に能力を発動しなかったため突然死しました。突然死は重大な迷惑行為なので絶対にしないようにしましょう。"
                else
                    "死にました"
            log=
                mode:"system"
                comment:"#{x.name}は#{situation}"
            splashlog @id,this,log
#           if x.found=="punish"
#               # 処刑→霊能
#               @players.forEach (y)=>
#                   if y.type=="Psychic"
#                       # 霊能
#                       y.results.push x
            @addGamelog {   # 死んだときと死因を記録
                id:x.id
                type:x.type
                event:"found"
                flag:x.found
            }
            x.found=""  # 発見されました
            @ss.publish.user x.realid,"refresh",{id:@id}
            if @rule.will=="die" && x.will
                # 死んだら遺言発表
                log=
                    mode:"will"
                    name:x.name
                    comment:x.will
                splashlog @id,this,log
        deads.length
                
    # 投票終わりチェック
    # 返り値意味ないんじゃないの?
    execute:->
        return false unless @votingbox.isVoteAllFinished()
        ###
        tos={}
        @players.forEach (x)->
            return if x.dead || !x.voteto
            if tos[x.voteto]?
                tos[x.voteto]+=if x.authority then 2 else 1
            else
                tos[x.voteto]=if x.authority then 2 else 1
        max=0
        for playerid,num of tos
            if num>max then max=num #最大値をみる
        if max==0
            # 誰も投票していない
            @revote_num=Infinity
            @judge()
            return
        player=null
        revote=false    # 際投票
        for playerid,num of tos
            if num==max
                if player?
                    # 斎藤票だ!
                    revote=true
                    break
                player=@getPlayer playerid
        # 投票結果
        log=
            mode:"voteresult"
            voteresult:@players.filter((x)->!x.dead).map (x)->
                r=x.publicinfo()
                r.voteto=x.voteto
                r
            tos:tos
        splashlog @id,this,log
        if revote
            # 同率!
            dcs=@players.filter (x)->!x.dead && x.decider   # 決定者たち
            for onedc in dcs
                if tos[onedc.voteto]==max
                    # こいつだ！
                    revote=false
                    player=@getPlayer onedc.voteto
                    break
        ###
        [mode,player,tos,table]=@votingbox.check()
        if mode=="novote"
            # 誰も投票していない・・・
            @revote_num=Infinity
            @judge()
            return false
        # 投票結果
        log=
            mode:"voteresult"
            voteresult:table
            tos:tos
        splashlog @id,this,log

        if mode=="revote"
            # 再投票になった
            @dorevote()
            return false
        else if mode=="punish"
            # 投票
            # 結果が出た 死んだ!
            player.die this,"punish"
            
            if player.dead && @rule.GMpsychic=="on"
                # GM霊能
                log=
                    mode:"system"
                    comment:"処刑された#{player.name}の霊能結果は#{player.psychicResult}でした。"
                splashlog @id,this,log
                
            @nextturn()
        return true
    # 再投票
    dorevote:->
        @revote_num++
        if @revote_num>=4   # 4回再投票
            @judge()
            return
        remains=4-@revote_num
        log=
            mode:"system"
            comment:"再投票になりました。"
        if isFinite remains
            log.comment += "あと#{remains}回の投票で結論が出なければ引き分けになります。"
        splashlog @id,this,log
        @votingbox.init()
        @players.forEach (player)=>
            return if player.dead
            player.votestart this
        @ss.publish.channel "room#{@id}","voteform",true
        @splashjobinfo()
        if @voting
            # 投票猶予の場合初期化
            clearTimeout @timerid
            @timer()
    
    # 勝敗決定
    judge:->
        aliveps=@players.filter (x)->!x.dead    # 生きている人を集める
        # 数える
        alives=aliveps.length
        humans=@players.filter((x)->!x.dead && x.isHuman()).length
        wolves=@players.filter((x)->!x.dead && x.isWerewolf()).length
        vampires=@players.filter((x)->!x.dead && x.isVampire()).length

        team=null

        # 量子人狼のときは特殊ルーチン
        if @rule.jobrule=="特殊ルール.量子人狼"
            assured_wolf=
                alive:0
                dead:0
            total_wolf=0
            obj=@quantum_patterns[0]
            if obj?
                for key,value of obj
                    if value.jobtype=="Werewolf"
                        total_wolf++
                for x in @players
                    unless x.flag
                        # まだだった・・・
                        break
                    flag=JSON.parse x.flag
                    if flag.Werewolf==1
                        # うわあああ絶対人狼だ!!!!!!!!!!
                        if flag.dead==1
                            assured_wolf.dead++
                        else if flag.dead==0
                            assured_wolf.alive++
                if alives<=assured_wolf.alive*2
                    # あーーーーーーー
                    team="Werewolf"
                else if assured_wolf.dead==total_wolf
                    # 全滅した
                    team="Human"
            else
                # もうひとつもないんだ・・・
                log=
                    mode:"system"
                    comment:"世界が崩壊し、確率が定義できなくなりました。"
                splashlog @id,this,log
                team="Draw"
        else
        
            if alives==0
                # 全滅
                team="Draw"
            else if wolves==0 && vampires==0
                # 村人勝利
                team="Human"
            else if humans<=wolves && vampires==0
                # 人狼勝利
                team="Werewolf"
            else if humans<=vampires && wolves==0
                # ヴァンパイア勝利
                team="Vampire"
                
            if team=="Werewolf" && wolves==1
                # 一匹狼判定
                lw=aliveps.filter((x)->x.isWerewolf())[0]
                if lw?.isJobType "LoneWolf"
                    team="LoneWolf"
                
            if team?
                # 妖狐判定
                if @players.some((x)->!x.dead && x.isFox())
                    team="Fox"
                # 恋人判定
                if @rule.friendsjudge=="alive" && @players.some((x)->x.isFriend())
                    # 終了時に恋人生存
                    friends=@players.filter (x)->x.isFriend()
                    if friends.every((x)->!x.dead)
                        team="Friend"
            # カルト判定
            if alives>0 && aliveps.every((x)->x.isCult() || x.isJobType("CultLeader"))
                # 全員信者
                team="Cult"
            # 悪魔くん判定
            if @players.some((x)->x.type=="Devil" && x.flag=="winner")
                team="Devil"
            if alives>0 && aliveps.every((x)->x.isFriend()) && @players.filter((x)->x.isFriend()).every((x)->!x.dead)
                # 恋人のみ生存
                team="Friend"

        if @revote_num>=4
            # 再投票多すぎ
            team="Draw" # 引き分け
            
        if team?
            # 勝敗決定
            @finished=true
            @winner=team
            if team!="Draw"
                @players.forEach (x)=>
                    iswin=x.isWinner this,team
                    if @rule.losemode
                        # 敗北村（負けたら勝ち）
                        if iswin==true
                            iswin=false
                        else if iswin==false
                            iswin=true
                            # ただし突然死したら負け
                            if @gamelogs.some((log)->
                                log.id==x.id && log.event=="found" && log.flag in ["gone-day","gone-night"]
                            )
                                iswin=false
                    x.setWinner iswin   #勝利か
                    # ユーザー情報
                    if x.winner
                        M.users.update {userid:x.realid},{$push: {win:@id}}
                    else
                        M.users.update {userid:x.realid},{$push: {lose:@id}}
            log=
                mode:"nextturn"
                finished:true
            resultstring=null#結果
            teamstring=null #陣営
            [resultstring,teamstring]=switch team
                when "Human"
                    if alives>0 && aliveps.every((x)->x.isJobType "Neet")
                        ["村はニートの楽園になりました。","村人勝利"]
                    else
                        ["村から人狼がいなくなりました。","村人勝利"]
                when "Werewolf"
                    ["人狼は最後の村人を喰い殺すと次の獲物を求めて去って行った…","人狼勝利"]
                when "Fox"
                    ["村は妖狐のものとなりました。","妖狐勝利"]
                when "Devil"
                    ["村は悪魔くんのものとなりました。","悪魔くん勝利"]
                when "Friend"
                    ["#{@players.filter((x)->x.isFriend()).length}人の愛の力には何者も敵わないのでした。","恋人勝利"]
                when "Cult"
                    ["村はカルトに支配されました。","カルトリーダー勝利"]
                when "Vampire"
                    ["ヴァンパイアは最後の村人を喰い殺すと次の獲物を求めて去って行った…","ヴァンパイア陣営勝利"]
                when "LoneWolf"
                    ["人狼は最後の村人を喰い殺すと次の獲物を求めて独り去って行くのだった…","一匹狼勝利"]
                when "Draw"
                    ["引き分けになりました。",""]
            log.comment="#{if teamstring then "【#{teamstring}】" else ""}#{resultstring}"
            splashlog @id,this,log
            
            
            # ルームを終了状態にする
            M.rooms.update {id:@id},{$set:{mode:"end"}}
            @ss.publish.channel "room#{@id}","refresh",{id:@id}
            @save()
            @prize_check()
            clearTimeout @timerid
            
            # DBからとってきて告知ツイート
            M.rooms.findOne {id:@id},(err,doc)->
                return unless doc?
                tweet doc.id,"「#{doc.name}」の結果: #{log.comment} #月下人狼"
            
            return true
        else
            return false
    timer:->
        return if @finished
        func=null
        time=null
        mode=null   # なんのカウントか
        timeout= =>
            # 残り時間を知らせるぞ!
            @timer_start=parseInt Date.now()/1000
            @timer_remain=time
            @timer_mode=mode
            @ss.publish.channel "room#{@id}","time",{time:time, mode:mode}
            if time>30
                @timerid=setTimeout timeout,30000
                time-=30
            else if time>0
                @timerid=setTimeout timeout,time*1000
                time=0
            else
                # 時間切れ
                func()
        if @rolerequestingphase
            # 希望役職制
            time=60
            mode="希望選択"
            func= =>
                # 強制開始
                @checkjobs true
        else if @night && !@voting
            # 夜
            time=@rule.night
            mode="夜"
            return unless time
            func= =>
                # ね な い こ だ れ だ
                unless @checkjobs true
                    if @rule.remain
                        # 猶予時間があるよ
                        @voting=true
                        @timer()
                    else
                        @players.forEach (x)=>
                            return if x.dead || x.sleeping(@)
                            x.die this,"gone-night" # 突然死
                            # 突然死記録
                            M.users.update {userid:x.realid},{$push:{gone:@id}}
                        @bury()
                        @checkjobs true
                else
                    return
        else if @night
            # 夜の猶予
            time=@rule.remain
            mode="猶予"
            func= =>
                # ね な い こ だ れ だ
                @players.forEach (x)=>
                    return if x.dead || x.sleeping(@)
                    x.die this,"gone-night" # 突然死
                    # 突然死記録
                    M.users.update {userid:x.realid},{$push:{gone:@id}}
                @bury()
                @checkjobs true
        else if !@voting
            # 昼
            time=@rule.day
            mode="昼"
            return unless time
            func= =>
                unless @execute()
                    if @rule.remain
                        # 猶予があるよ
                        @voting=true
                        log=
                            mode:"system"
                            comment:"昼の討論時間が終了しました。投票して下さい。"
                        splashlog @id,this,log
                        @timer()
                    else
                        # 突然死
                        revoting=false
                        @players.forEach (x)=>
                            return if x.dead || x.voted(this,@votingbox)
                            x.die this,"gone-day"
                            revoting=true
                        @bury()
                        @judge()
                        if revoting
                            @dorevote()
                        else
                            @execute()
                else
                    return
        else
            # 猶予時間も過ぎたよ!
            time=@rule.remain
            mode="猶予"
            func= =>
                unless @execute()
                    revoting=false
                    @players.forEach (x)=>
                        return if x.dead || x.voted(this,@votingbox)
                        x.die this,"gone-day"
                        revoting=true
                    @bury()
                    @judge()
                    if revoting
                        @dorevote()
                    else
                        @execute()
                else
                    return
        timeout()
    # プレイヤーごとに　見せてもよいログをリストにする
    makelogs:(player)->
        @logs.map (x)=>
            if islogOK this,player,x
                x
            else
                # 見られなかったけど見たい人用
                if x.mode=="werewolf" && @rule.wolfsound=="aloud"
                    {
                        mode: "werewolf"
                        name: "狼の遠吠え"
                        comment: "アオォーーン・・・"
                        time: x.time
                    }
                else if x.mode=="couple" && @rule.couplesound=="aloud"
                    {
                        mode: "couple"
                        name: "共有者の小声"
                        comment: "ヒソヒソ・・・"
                        time: x.time
                    }
                else
                    null
        .filter (x)->x?
    prize_check:->
        Server.prize.checkPrize @,(obj)=>
            # obj: {(userid):[prize]}
            # 賞を算出した
            pls=@players.filter (x)->x.realid!="身代わりくん"
            # 各々に対して処理
            query={userid:{$in:pls.map (x)->x.realid}}
            M.users.find(query).each (err,doc)=>
                return unless doc?
                oldprize=doc.prize  # いままでの賞の一覧
                # 差分をとる
                newprize=obj[doc.userid].filter (x)->!(x in oldprize)
                if newprize.length>0
                    M.users.update {userid:doc.userid},{$set:{prize:obj[doc.userid]}}
                    pl=@getPlayerReal doc.userid
                    pnames=newprize.map (plzid)->
                        Server.prize.prizeQuote Server.prize.prizeName plzid
                    log=
                        mode:"system"
                        comment:"#{pl.name}は称号#{pnames.join ''}を獲得しました。"
                    splashlog @id,this,log

        ###
        M.users.find(query).each (err,doc)=>
            return unless doc?
            oldprize=doc.prize  # 賞の一覧
            
            # 賞を算出しなおしてもらう
            Server.prize.checkPrize doc.userid,(prize)=>
                prize=prize.concat doc.ownprize if doc.ownprize?
                # 新規に獲得した賞を探す
                newprizes= prize.filter (x)->!(x in oldprize)
                if newprizes.length>0
                    M.users.update {userid:doc.userid},{$set:{prize:prize}}
                    pl=@getPlayerReal doc.userid
                    newprizes.forEach (x)=>
                        log=
                            mode:"system"
                            comment:"#{pl.name}は#{Server.prize.prizeQuote Server.prize.prizeName x}を獲得しました。"
                        splashlog @id,this,log
                        @addGamelog {
                            id: pl.id
                            type:pl.type
                            event:"getprize"
                            flag:x
                            target:null
                        }
        ###
###
logs:[{
    mode:"day"(昼) / "system"(システムメッセージ) /  "werewolf"(狼) / "heaven"(天国) / "prepare"(開始前/終了後) / "skill"(能力ログ) / "nextturn"(ゲーム進行) / "audience"(観戦者のひとりごと) / "monologue"(夜のひとりごと) / "voteresult" (投票結果） / "couple"(共有者) / "fox"(妖狐) / "will"(遺言)
    comment: String
    userid:Userid
    name?:String
    to:Userid / null (あると、その人だけ）
    (nextturnの場合)
      day:Number
      night:Boolean
      finished?:Boolean
    (voteresultの場合)
      voteresult:[]
      tos:Object
},...]
rule:{
    number: Number # プレイヤー数
    scapegoat : "on"(身代わり君が死ぬ) "off"(参加者が死ぬ) "no"(誰も死なない)
  }
###
# 投票箱
class VotingBox
    constructor:(@game)->
        @init()
    init:->
        # 投票箱を空にする
        @votes=[]   #{player:Player, to:Player}
    isVoteFinished:(player)->@votes.some (x)->x.player.id==player.id
    vote:(player,voteto)->
        # power: 票数
        pl=@game.getPlayer voteto
        unless pl?
            return "そのプレイヤーは存在しません"
        if pl.dead
            return "その人は既に死んでいます"
        me=@game.getPlayer player.id
        unless me?
            return "あなたは参加していません"
        if @isVoteFinished player
            return "あなたは既に投票しています"
        if pl.id==player.id && @game.rule.votemyself!="ok"
            return "自分には投票できません"
        @votes.push {
            player:@game.getPlayer player.id
            to:pl
            power:1
            priority:0
        }
        log=
            mode:"voteto"
            to:player.id
            comment:"#{player.name}は#{pl.name}に投票しました"
        splashlog @game.id,@game,log
        null
    # その人の投票オブジェクトを得る
    getHisVote:(player)->
        @votes.filter((x)->x.player.id==player.id)[0]
    # 票のパワーを変更する
    votePower:(player,value,absolute=false)->
        v=@getHisVote player
        if v?
            if absolute
                v.power=value
            else
                v.power+=value
    # 優先度つける
    votePriority:(player,value,absolute=false)->
        v=@getHisVote player
        if v?
            if absolute
                v.priority=value
            else
                v.priority+=value



    isVoteAllFinished:->
        alives=@game.players.filter (x)->!x.dead
        alives.every (x)=>
            x.voted @game,@
    check:->
        # return [mode,result,tos,table]
        # 投票が終わったのでアレする
        # 投票表を作る
        tos={}
        table=[]
        #for obj in @votes
        for pl in @game.players
            obj=@getHisVote pl
            continue unless obj?

            tos[obj.to.id] ?= 0
            tos[obj.to.id]+=obj.power
            o=obj.player.publicinfo()
            o.voteto=obj.to.id  # 投票先情報を付け加える
            table.push o
        max=0
        for playerid,num of tos
            if num>max then max=num #最大値をみる
        if max==0
            # 誰も投票していない
            return ["novote",null,tos,table]
        # もっとも票が多い人を探す
        tops=[]
        for playerid,num of tos
            if num==max
                tops.push {id:playerid}
        # 優先度で絞り込む
        prior=-Infinity
        player=null
        revote=false    # 際投票
        for obj in tops
            # 票の中でもっとも優先度が高い
            maxpr=Math.max.apply Math,@votes.filter((x)->x.to.id==obj.id).map((x)->x.priority)
            if prior==maxpr && player?
                # 同じだ
                revote=true
            else if maxpr>=prior
                # 処刑候補だ
                player=@game.getPlayer obj.id
                prior=maxpr
                revote=false

        if revote
            # 再投票になった
            return ["revote",null,tos,table]
        # 結果を教える
        return ["punish",player,tos,table]

class Player
    constructor:->
        # realid:本当のid id:仮のidかもしれない name:名前 icon:アイコンURL
        @dead=false
        @found=null # 死体の発見状況
        @winner=null    # 勝敗
        @scapegoat=false    # 身代わりくんかどうか
        @flag=null  # 役職ごとの自由なフラグ
        
        @will=null  # 遺言
        # もとの役職
        @originalType=@type
        @originalJobname=@getJobname()
        
    @factory:(type,main=null,sub=null,cmpl=null)->
        p=null
        if cmpl?
            # 複合 mainとsubを使用
            #cmpl: 複合の親として使用するオブジェクト
            myComplex=Object.create main #Complexから
            sample=new cmpl # 手動でComplexを継承したい
            Object.keys(sample).forEach (x)->
                delete sample[x]    # own propertyは全部消す
            for name of sample
                # sampleのown Propertyは一つもない
                myComplex[name]=sample[name]
            # 混合役職
            p=Object.create myComplex

            p.main=main
            p.sub=sub
            p.cmplFlag=null
        else if !jobs[type]?
            p=new Player
        else
            p=new jobs[type]
        p
    serialize:->
        r=
            type:@type
            id:@id
            realid:@realid
            name:@name
            dead:@dead
            scapegoat:@scapegoat
            will:@will
            flag:@flag
            winner:@winner
            originalType:@originalType
            originalJobname:@originalJobname
        if @isComplex()
            r.type="Complex"
            r.Complex_main=@main.serialize()
            r.Complex_sub=@sub?.serialize()
            r.Complex_type=@cmplType
            r.Complex_flag=@cmplFlag
        r
    @unserialize:(obj)->
        unless obj?
            return null

        p=if obj.type=="Complex"
            # 複合
            cmplobj=complexes[obj.Complex_type ? "Complex"]
            Player.factory null, Player.unserialize(obj.Complex_main), Player.unserialize(obj.Complex_sub),cmplobj
        else
            # 普通
            Player.factory obj.type
        p.setProfile obj    #id,realid,name...
        p.dead=obj.dead
        p.scapegoat=obj.scapegoat
        p.will=obj.will
        p.flag=obj.flag
        p.winner=obj.winner
        p.originalType=obj.originalType
        p.originalJobname=obj.originalJobname
        if p.isComplex()
            p.cmplFlag=obj.Complex_flag
        p
    publicinfo:->
        # 見せてもいい情報
        {
            id:@id
            name:@name
            dead:@dead
        }
        
    # ログが見えるかどうか（通常のゲーム中、個人宛は除外）
    isListener:(game,log)->
        if log.mode in ["day","system","nextturn","prepare","monologue","skill","will","voteto","gm","gmreply","helperwhisper","probability_table"]
            # 全員に見える
            true
        else if log.mode in ["heaven","gmheaven"]
            # 死んでたら見える
            @dead
        else if log.mode=="voteresult"
            game.rule.voteresult!="hide"    # 隠すかどうか
        else
            false
        
    # 本人に見える役職名
    getJobDisp:->@jobname
    # 本人に見える役職タイプ
    getTypeDisp:->@type
    # 役職名を得る
    getJobname:->@jobname
    # 村人かどうか
    isHuman:->!@isWerewolf()
    # 人狼かどうか
    isWerewolf:->false
    # 洋子かどうか
    isFox:->false
    # 恋人かどうか
    isFriend:->false
    # Complexかどうか
    isComplex:->false
    # カルト信者かどうか
    isCult:->false
    # ヴァンパイアかどうか
    isVampire:->false
    # 酔っ払いかどうか
    isDrunk:->false
    # jobtypeが合っているかどうか（夜）
    isJobType:(type)->type==@type
    # complexのJobTypeを調べる
    isCmplType:(type)->false
    # 投票先決定
    dovote:(game,target)->
        # 戻り値にも意味があるよ！
        game.votingbox.vote this,target,1
    # 昼のはじまり（死体処理よりも前）
    sunrise:(game)->
    deadsunrise:(game)->
    # 昼の投票準備
    votestart:(game)->
        #@voteto=null
        return if @dead
        if @scapegoat
            # 身代わりくんは投票
            alives=game.players.filter (x)=>!x.dead && x!=this
            r=Math.floor Math.random()*alives.length    # 投票先
            return unless alives[r]?
            #@voteto=alives[r].id
            game.votingbox.vote this,alives[r].id
        
    # 夜のはじまり（死体処理よりも前）
    sunset:(game)->
    deadsunset:(game)->
    # 夜にもう寝たか
    sleeping:(game)->true
    # 夜に仕事を追えたか（基本sleepingと一致）
    jobdone:(game)->@sleeping game
    # 昼に投票を終えたか
    voted:(game,votingbox)->game.votingbox.isVoteFinished this
    # 夜の仕事
    job:(game,playerid,query)->
        @target=playerid
        null
    # 夜の仕事を行う
    midnight:(game)->
    # 夜死んでいたときにmidnightの代わりに呼ばれる
    deadnight:(game)->
    # 対象
    job_target:1    # ビットフラグ
    # 対象用の値
    @JOB_T_ALIVE:1  # 生きた人が対象
    @JOB_T_DEAD :2  # 死んだ人が対象
    #人狼に食われて死ぬかどうか
    willDieWerewolf:true
    #占いの結果
    fortuneResult:"村人"
    #霊能の結果
    psychicResult:"村人"
    #チーム Human/Werewolf
    team: "Human"
    #勝利かどうか team:勝利陣営名
    isWinner:(game,team)->
        team==@team # 自分の陣営かどうか
    # 勝敗設定
    setWinner:(winner)->@winner=winner
    # 殺されたとき(found:死因))
    die:(game,found,from)->
        return if @dead
        @dead=true
        @found=found
        @dying game,found,from
    # 死んだとき
    dying:(game,found)->
    # 行きかえる
    revive:(game)->
        # logging: ログを表示するか
        @dead=false
        p=@getParent game
        unless p?.sub==this
            # サブのときはいいや・・・
            log=
                mode:"system"
                comment:"#{@name}は蘇生しました。"
            splashlog game.id,game,log
            @addGamelog game,"revive",null,null
            game.ss.publish.user @id,"refresh",{id:game.id}

    # 埋葬するまえに全員呼ばれる（foundが見られる状況で）
    beforebury: (game)->
    # 占われたとき（結果は別にとられる player:占い元）
    divined:(game,player)->
    # 選択肢を返す
    makeJobSelection:(game)->
        if game.night
            # 夜の能力
            jt=@job_target
            if jt>0
                # 参加者を選択する
                result=[]
                for pl in game.players
                    if (pl.dead && (jt&Player.JOB_T_DEAD))||(!pl.dead && (jt&Player.JOB_T_ALIVE))
                        result.push {
                            name:pl.name
                            value:pl.id
                        }
            else
                result=[]
        else
            # 昼の投票
            result=[]
            for pl in game.players
                if !pl.dead
                    result.push {
                        name:pl.name
                        value:pl.id
                    }

        result
    checkJobValidity:(game,query)->
        sl=@makeJobSelection game
        return sl.length==0 || sl.some((x)->x.value==query.target)
    # 役職情報を載せる
    makejobinfo:(game,obj)->
        # 開くべきフォームを配列で（生きている場合）
        obj.open ?=[]
        if !@jobdone(game) && (game.night || @chooseJobDay(game))
            obj.open.push @type
        # 役職解説のアレ
        obj.desc ?= []
        obj.desc.push {
            name:@getJobDisp()
            type:@getTypeDisp()
        }

        obj.job_target=@getjob_target()
        # 選択肢を教える {name:"名前",value:"値"}
        obj.job_selection ?= []
        obj.job_selection=obj.job_selection.concat @makeJobSelection game
        # 重複を取り除くのはクライアント側にやってもらおうかな…

        # 女王観戦者が見える
        if @team=="Human"
            obj.queens=game.players.filter((x)->x.type=="QueenSpectator").map (x)->
                x.publicinfo()
    # 昼でも対象選択を行えるか
    chooseJobDay:(game)->false
    # 仕事先情報を教える
    getjob_target:->@job_target
    # 昼の発言の選択肢
    getSpeakChoiceDay:(game)->
        ["day","monologue"]
    # 夜の発言の選択肢を得る
    getSpeakChoice:(game)->
        ["monologue"]
    # Complexから抜ける
    uncomplex:(game,flag=false)->
        #flag: 自分がComplexで自分が消滅するならfalse 自分がmainまたはsubで親のComplexを消すならtrue(その際subは消滅）
        
        befpl=game.getPlayer @id
        
        # parentobj[name]がPlayerであること calleeは呼び出し元のオブジェクト
        chk=(parentobj,name,callee)->
            return unless parentobj?[name]?
            if parentobj[name].isComplex()
                if flag
                    # mainまたはsubである
                    if parentobj[name].main==callee || parentobj[name].sub==callee
                        parentobj[name]=parentobj[name].main
                    else
                        chk parentobj[name],"main",callee
                        chk parentobj[name],"sub",callee
                else
                    # 自分がComplexである
                    if parentobj[name]==callee
                        parentobj[name]=parentobj[name].main    # Complexを解消
                    else
                        chk parentobj[name],"main",callee
                        chk parentobj[name],"sub",callee
        
        game.players.forEach (x,i)=>
            if x.id==@id
                chk game.players,i,this
                
        aftpl=game.getPlayer @id
        #前と後で比較
        if befpl.getJobname()!=aftpl.getJobname()
            aftpl.originalJobname="#{befpl.originalJobname}→#{aftpl.getJobname()}"
                
    # 自分自身を変える
    transform:(game,newpl,initial=false)->
        @addGamelog game,"transform",newpl.type
        # 役職変化ログ
        newpl.originalType=@originalType
        if @getJobname()!=newpl.getJobname()
            unless initial
                # ふつうの変化
                newpl.originalJobname="#{@originalJobname}→#{newpl.getJobname()}"
            else
                # 最初の変化（ログに残さない）
                newpl.originalJobname=newpl.getJobname()
        ###
        tr=(parent,name)=>
            if parent[name]?.isComplex? && parent[name].id==@id # Playerだよね
                if parent[name]==this
                    # ここを変える

                    parent[name]=newpl
                    return
                if parent[name].isComplex()
                    tr parent[name],"main"
                    tr parent[name],"sub"
                    
        game.players.forEach (x,i)=>
            if x.id==@id
                tr game.players,i,nulld
                #game.players[i]=newpl
        ###
        pa=@getParent game
        unless pa?
            # 親なんていない
            game.players.forEach (x,i)=>
                if x.id==@id
                    game.players[i]=newpl
            game.participants.forEach (x,i)=>
                if x.id==@id
                    game.participants[i]=newpl
        else
            # 親がいた
            if pa.main==this
                # 親書き換え
                newparent=Player.factory null,newpl,pa.sub,complexes[pa.cmplType]
                newpl.transProfile newparent

                pa.transform game,newparent # たのしい再帰
            else
                # サブだった
                pa.sub=newpl
    getParent:(game)->
        chk=(parent,name)=>
            if parent[name]?.isComplex?()
                if parent[name].main==this || parent[name].sub==this
                    return parent[name]
                else
                    return chk(parent[name],"main") || chk(parent[name],"sub")
            else
                return null
        for pl,i in game.players
            c=chk game.players,i
            return c if c?
        return null # 親なんていない
            
    # 自分のイベントを記述
    addGamelog:(game,event,flag,target,type=@type)->
        game.addGamelog {
            id:@id
            type:type
            target:target
            event:event
            flag:flag
        }
    # 個人情報的なことをセット
    setProfile:(obj={})->
        @id=obj.id
        @realid=obj.realid
        @name=obj.name
    # 個人情報的なことを移動
    transProfile:(newpl)->
        newpl.setProfile this
    # フラグ類を新しいPlayerオブジェクトへ移動
    transferData:(newpl)->
        return unless newpl?
        newpl.scapegoat=@scapegoat
        
            

        
        
        
class Human extends Player
    type:"Human"
    jobname:"村人"
class Werewolf extends Player
    type:"Werewolf"
    jobname:"人狼"
    sunset:(game)->
        @target=null
        unless game.day==1 && game.rule.scapegoat!="off"
            if @scapegoat && game.players.filter((x)->x.isWerewolf()).length==1
                # 自分しか人狼がいない
                r=Math.floor Math.random()*game.players.length
                if @job game,game.players[r].id,{}
                    @sunset

    sleeping:(game)->game.werewolf_target_remain<=0 || !game.night
    job:(game,playerid)->
        tp = game.getPlayer playerid
        if game.werewolf_target_remain<=0
            return "既に対象は決定しています"
        if game.rule.wolfattack!="ok" && tp?.isWerewolf()
            # 人狼は人狼に攻撃できない
            return "人狼は人狼を殺せません"
        game.werewolf_target.push {
            from:@id
            to:playerid
        }
        game.werewolf_target_remain--
        log=
            mode:"wolfskill"
            comment:"#{@name}たち人狼は#{game.getPlayer(playerid).name}に狙いを定めました。"
        splashlog game.id,game,log
        game.splashjobinfo game.players.filter (x)=>x.id!=playerid && x.isWerewolf()
        null
                
    isWerewolf:->true
    
    isListener:(game,log)->
        if log.mode in ["werewolf","wolfskill"]
            true
        else super
    isJobType:(type)->
        # 便宜的
        if type=="_Werewolf"
            return true
        super
        
    willDieWerewolf:false
    fortuneResult:"人狼"
    psychicResult:"人狼"
    team: "Werewolf"
    makejobinfo:(game,result)->
        super
        if game.werewolf_target_remain>0
            # まだ襲える
            result.open.push "_Werewolf"
        # 人狼は仲間が分かる
        result.wolves=game.players.filter((x)->x.isWerewolf()).map (x)->
            x.publicinfo()
        # スパイ2も分かる
        result.spy2s=game.players.filter((x)->x.type=="Spy2").map (x)->
            x.publicinfo()
    getSpeakChoice:(game)->
        ["werewolf"].concat super

        
        
class Diviner extends Player
    type:"Diviner"
    jobname:"占い師"
    constructor:->
        super
        @results=[]
            # {player:Player, result:String}
    sunset:(game)->
        super
        @target=null
        if @scapegoat
            # 身代わり君の自動占い
            r=Math.floor Math.random()*game.players.length
            @job game,game.players[r].id,{}
    sleeping:->@target?
    job:(game,playerid)->
        super
        log=
            mode:"skill"
            to:@id
            comment:"#{@name}が#{game.getPlayer(playerid).name}を占いました。"
        splashlog game.id,game,log
        if game.rule.divineresult=="immediate"
            @dodivine game
            @showdivineresult game
        null
    sunrise:(game)->
        super
        unless game.rule.divineresult=="immediate"
            @showdivineresult game
                
    midnight:(game)->
        super
        unless game.rule.divineresult=="immediate"
            @dodivine game
    #占い実行
    dodivine:(game)->
        p=game.getPlayer @target
        if p?
            @results.push {
                player: p.publicinfo()
                result: p.fortuneResult
            }
            p.divined game,this
            @addGamelog game,"divine",p.type,@target    # 占った
    showdivineresult:(game)->
        r=@results[@results.length-1]
        return unless r?
        log=
            mode:"skill"
            to:@id
            comment:"#{@name}が#{r.player.name}を占ったところ、#{r.result}でした。"
        splashlog game.id,game,log
class Psychic extends Player
    type:"Psychic"
    jobname:"霊能者"
    constructor:->
        super
        @flag=""    # ここにメッセージを入れよう
    sunset:(game)->
        super
        if game.rule.psychicresult=="sunset"
            @showpsychicresult game
    sunrise:(game)->
        super
        unless game.rule.psychicresult=="sunset"
            @showpsychicresult game
        
    showpsychicresult:(game)->
        return unless @flag?
        @flag.split("\n").forEach (x)=>
            return unless x
            log=
                mode:"skill"
                to:@id
                comment:x
            splashlog game.id,game,log
        @flag=""
    
    # 処刑で死んだ人を調べる
    beforebury:(game)->
        game.players.filter((x)->x.dead && x.found=="punish").forEach (x)=>
            @flag += "#{@name}の霊能の結果、前日処刑された#{x.name}は#{x.psychicResult}でした。\n"

class Madman extends Player
    type:"Madman"
    jobname:"狂人"
    team:"Werewolf"
    makejobinfo:(game,result)->
        super
        delete result.queens
class Guard extends Player
    type:"Guard"
    jobname:"狩人"
    sleeping:->@target?
    sunset:(game)->
        @target=null
        if game.day==1
            # 狩人は一日目護衛しない
            @target=""  # 誰も守らない
        else if @scapegoat
            # 身代わり君の自動占い
            r=Math.floor Math.random()*game.players.length
            if @job game,game.players[r].id,{}
                @sunset
    job:(game,playerid)->
        unless playerid==@id && game.rule.guardmyself!="ok"
            super
            pl=game.getPlayer(playerid)
            log=
                mode:"skill"
                to:@id
                comment:"#{@name}は#{pl.name}を護衛しました。"
            splashlog game.id,game,log
            # 複合させる

            newpl=Player.factory null,pl,null,Guarded   # 守られた人
            pl.transProfile newpl
            newpl.cmplFlag=@id  # 護衛元cmplFlag
            pl.transform game,newpl
            null
        else
            "自分を護衛することはできません"
class Couple extends Player
    type:"Couple"
    jobname:"共有者"
    makejobinfo:(game,result)->
        super
        # 共有者は仲間が分かる
        result.peers=game.players.filter((x)->x.type=="Couple").map (x)->
            x.publicinfo()
    isListener:(game,log)->
        if log.mode=="couple"
            true
        else super
    getSpeakChoice:(game)->
        ["couple"].concat super

class Fox extends Player
    type:"Fox"
    jobname:"妖狐"
    team:"Fox"
    willDieWerewolf:false
    isHuman:->false
    isFox:->true
    makejobinfo:(game,result)->
        super
        # 妖狐は仲間が分かる
        result.foxes=game.players.filter((x)->x.type=="Fox").map (x)->
            x.publicinfo()
    divined:(game,player)->
        super
        # 妖狐呪殺
        @die game,"curse"
        player.addGamelog game,"cursekill",null,@id # 呪殺した
    isListener:(game,log)->
        if log.mode=="fox"
            true
        else super
    getSpeakChoice:(game)->
        ["fox"].concat super


class Poisoner extends Player
    type:"Poisoner"
    jobname:"埋毒者"
    dying:(game,found)->
        super
        # 埋毒者の逆襲
        canbedead = game.players.filter (x)->!x.dead    # 生きている人たち
        if found=="werewolf"
            # 噛まれた場合は狼のみ
            canbedead=canbedead.filter (x)->x.isWerewolf()
        return if canbedead.length==0
        r=Math.floor Math.random()*canbedead.length
        pl=canbedead[r] # 被害者
        pl.die game,"poison"
        @addGamelog game,"poisonkill",null,pl.id

class BigWolf extends Werewolf
    type:"BigWolf"
    jobname:"大狼"
    fortuneResult:"村人"
    psychicResult:"大狼"
class TinyFox extends Diviner
    type:"TinyFox"
    jobname:"子狐"
    fortuneResult:"村人"
    psychicResult:"子狐"
    team:"Fox"
    isHuman:->false
    isFox:->true
    sunset:(game)->
        if @scapegoat
            # 身代わり君の自動占い
            r=Math.floor Math.random()*game.players.length
            if @job game,game.players[r].id,{}
                @sunset
    makejobinfo:(game,result)->
        super
        # 子狐は妖狐が分かる
        result.foxes=game.players.filter((x)->x.type=="Fox").map (x)->
            x.publicinfo()

    dodivine:(game)->
        p=game.getPlayer @target
        if p?
            success= Math.random()<0.5  # 成功したかどうか
            @results.push {
                player: p.publicinfo()
                result: if success then "#{p.fortuneResult}ぽい人" else "なんだかとても怪しい人"
            }
            @addGamelog game,"foxdivine",success,p.id
    showdivineresult:(game)->
        r=@results[@results.length-1]
        return unless r?
        log=
            mode:"skill"
            to:@id
            comment:"#{@name}の占いの結果、#{r.player.name}は#{r.result}かな？"
        splashlog game.id,game,log
    
    
class Bat extends Player
    type:"Bat"
    jobname:"こうもり"
    team:""
    isWinner:(game,team)->
        !@dead  # 生きて入ればとにかく勝利
class Noble extends Player
    type:"Noble"
    jobname:"貴族"
    die:(game,found)->
        if found=="werewolf"
            return if @dead
            # 奴隷たち
            slaves = game.players.filter (x)->!x.dead && x.type=="Slave"
            unless slaves.length
                super   # 自分が死ぬ
            else
                # 奴隷が代わりに死ぬ
                slaves.forEach (x)->
                    x.die game,"werewolf"
                    x.addGamelog game,"slavevictim"
                @addGamelog game,"nobleavoid"
        else
            super

class Slave extends Player
    type:"Slave"
    jobname:"奴隷"
    isWinner:(game,team)->
        nobles=game.players.filter (x)->!x.dead && x.type=="Noble"
        if team==@team && nobles.length==0
            true    # 村人陣営の勝ちで貴族は死んだ
        else
            false
    makejobinfo:(game,result)->
        super
        # 奴隷は貴族が分かる
        result.nobles=game.players.filter((x)->x.type=="Noble").map (x)->
            x.publicinfo()
class Magician extends Player
    type:"Magician"
    jobname:"魔術師"
    sunset:(game)->
        @target=if game.day<3 then "" else null
        if game.players.every((x)->!x.dead)
            @target=""  # 誰も死んでいないなら能力発動しない
        if !@target? && @scapegoat
            # 身代わり君の自動占い
            r=Math.floor Math.random()*game.players.length
            @job game,game.players[r].id,{}
    job:(game,playerid)->
        if game.day<3
            # まだ発動できない
            return "まだ能力を発動できません"
        @target=playerid
        pl=game.getPlayer playerid
        
        log=
            mode:"skill"
            to:@id
            comment:"#{@name}は#{pl.name}に死者蘇生術をかけました。"
        splashlog game.id,game,log
        null
    sleeping:(game)->game.day<3 || @target?
    midnight:(game)->
        return unless @target?
        pl=game.getPlayer @target
        return unless pl?
        return unless pl.dead
        # 確率判定
        r=if pl.scapegoat then 0.6 else 0.3
        unless Math.random()<r
            # 失敗
            @addGamelog game,"raise",false,pl.id
            return
        # 蘇生 目を覚まさせる
        @addGamelog game,"raise",true,pl.id
        pl.revive game
    job_target:Player.JOB_T_DEAD
    makejobinfo:(game,result)->
        super
class Spy extends Player
    type:"Spy"
    jobname:"スパイ"
    team:"Werewolf"
    sleeping:->true # 能力使わなくてもいい
    jobdone:->@flag in ["spygone","day1"]   # 能力を使ったか
    sunrise:(game)->
        if game.day<=1
            @flag="day1"    # まだ去れない
        else
            @flag=null
    job:(game,playerid)->
        return "既に能力を発動しています" if @flag=="spygone"
        @flag="spygone"
        log=
            mode:"skill"
            to:@id
            comment:"#{@name}は村を去ることに決めました。"
        splashlog game.id,game,log
        null
    midnight:(game)->
        if !@dead && @flag=="spygone"
            # 村を去る
            @flag="spygone"
            @die game,"spygone"
    job_target:0
    isWinner:(game,team)->
        team==@team && @dead && @flag=="spygone"    # 人狼が勝った上で自分は任務完了の必要あり
    makejobinfo:(game,result)->
        super
        # スパイは人狼が分かる
        result.wolves=game.players.filter((x)->x.isWerewolf()).map (x)->
            x.publicinfo()
    makeJobSelection:(game)->
        # 夜は投票しない
        if game.night
            []
        else super
class WolfDiviner extends Werewolf
    type:"WolfDiviner"
    jobname:"人狼占い"
    sunset:(game)->
        @target=null
        @flag=null  # 占い対象
        @result=null    # 占い結果
    sleeping:(game)->game.werewolf_target_remain<=0 # 占いは必須ではない
    jobdone:(game)->game.werewolf_target_remain<=0 && @flag?
    job:(game,playerid,query)->
        console.log query
        if query.jobtype!="WolfDiviner"
            # 人狼の仕事
            return super
        # 占い
        if @flag?
            return "既に占い対象を決定しています"
        @flag=playerid
        log=
            mode:"skill"
            to:@id
            comment:"#{@name}が#{game.getPlayer(playerid).name}を占いました。"
        splashlog game.id,game,log
        if game.rule.divineresult=="immediate"
            @dodivine game
            @showdivineresult game
        null
    sunrise:(game)->
        super
        unless game.rule.divineresult=="immediate"
            @showdivineresult game
    midnight:(game)->
        super
        unless game.rule.divineresult=="immediate"
            @dodivine game
    dodivine:(game)->
        return unless @result?
        @addGamelog game,"wolfdivine",null,@target  # 占った
        log=
            mode:"skill"
            to:@id
            comment:"#{@name}が#{@result.player.name}を占ったところ、#{@result.result}でした。"
        splashlog game.id,game,log
    showdivineresult:(game)->
        p=game.getPlayer @flag
        if p?
            @result=
                player: p.publicinfo()
                result: p.jobname
            p.divined game,this
            if p.type=="Diviner"
                # 逆呪殺
                @die game,"curse"
            if p.type=="Madman"
                # 狂人変化
                jobnames=Object.keys jobs
                newjob=jobnames[Math.floor Math.random()*jobnames.length]
                plobj=p.serialize()
                plobj.type=newjob
                newpl=Player.unserialize plobj  # 新生狂人
                p.transferData newpl
                p.transform game,newpl

        
    
        

class Fugitive extends Player
    type:"Fugitive"
    jobname:"逃亡者"
    willDieWerewolf:false   # 人狼に直接噛まれても死なない
    sunset:(game)->
        @target=null
        @willDieWerewolf=false
        if game.day<=1 && game.rule.scapegoat!="off"    # 一日目は逃げない
            @target=""
            @willDieWerewolf=true   # 一日目だけは死ぬ
        else if @scapegoat
            # 身代わり君の自動占い
            r=Math.floor Math.random()*game.players.length
            if @job game,game.players[r].id,{}
                @sunset sleeping:->@target?
    sleeping:->@target?
    job:(game,playerid)->
        # 逃亡先
        pl=game.getPlayer playerid
        if pl?.dead
            return "死者の家には逃げられません"
        if playerid==@id
            return "自分の家へは逃げられません"
        @target=playerid
        log=
            mode:"skill"
            to:@id
            comment:"#{@name}は#{pl.name}の家の近くへ逃亡しました。"
        splashlog game.id,game,log
        @addGamelog game,"runto",null,pl.id
        null
        
    midnight:(game)->
        # 人狼の家に逃げていたら即死
        pl=game.getPlayer @target
        return unless pl?
        if !pl.dead && pl.isWerewolf()
            @die game,"werewolf"
        
    isWinner:(game,team)->
        team==@team && !@dead   # 村人勝利で生存
class Merchant extends Player
    type:"Merchant"
    jobname:"商人"
    constructor:->
        super
        @flag=null  # 発送済みかどうか
    sleeping:->true
    jobdone:->@flag?
    job:(game,playerid,query)->
        if @flag?
            return "既に商品を発送しています"
        # 即時発送
        unless query.Merchant_kit in ["Diviner","Psychic","Guard"]
            return "発送する商品が不正です"
        kit_names=
            "Diviner":"占いセット"
            "Psychic":"霊能セット"
            "Guard":"狩人セット"
        pl=game.getPlayer playerid
        unless pl?
            return "発送先が不正です"
        if pl.dead
            return "発送先は既に死んでいます"
        if pl.id==@id
            return "自分には発送できません"
        # 複合させる
        sub=Player.factory query.Merchant_kit   # 副を作る
        pl.transProfile sub
        sub.sunset game
        newpl=Player.factory null,pl,sub,Complex    # Complex
        pl.transProfile newpl
        pl.transform game,newpl

        log=
            mode:"skill"
            to:@id
            comment:"#{@name}は#{newpl.name}へ#{kit_names[query.Merchant_kit]}を発送しました。"
        splashlog game.id,game,log
        # 入れ替え先は気づいてもらう
        log=
            mode:"skill"
            to:newpl.id
            comment:"#{newpl.name}へ#{kit_names[query.Merchant_kit]}が到着しました。"
        splashlog game.id,game,log
        game.ss.publish.user newpl.id,"refresh",{id:game.id}
        @flag=query.Merchant_kit    # 発送済み
        @addGamelog game,"sendkit",@flag,newpl.id
        null
class QueenSpectator extends Player
    type:"QueenSpectator"
    jobname:"女王観戦者"
    dying:(game,found)->
        super
        # 感染
        humans = game.players.filter (x)->!x.dead && x.isHuman()    # 生きている人たち
        humans.forEach (x)->
            x.die game,"hinamizawa"

class MadWolf extends Werewolf
    type:"MadWolf"
    jobname:"狂人狼"
    team:"Human"
    sleeping:->true
class Neet extends Player
    type:"Neet"
    jobname:"ニート"
    team:""
    sleeping:->true
    voted:(game,votingbox)->true
    isWinner:->true
class Liar extends Player
    type:"Liar"
    jobname:"嘘つき"
    job_target:Player.JOB_T_ALIVE | Player.JOB_T_DEAD   # 死人も生存も
    sunset:(game)->
        @target=null
        @result=null    # 占い結果
        if @scapegoat
            # 身代わり君の自動占い
            r=Math.floor Math.random()*game.players.length
            @job game,game.players[r].id,{}
    sleeping:->@target?
    job:(game,playerid,query)->
        # 占い
        if @target?
            return "既に占い対象を決定しています"
        @target=playerid
        log=
            mode:"skill"
            to:@id
            comment:"#{@name}が#{game.getPlayer(playerid).name}を占いました。"
        splashlog game.id,game,log
        null
    sunrise:(game)->
        super
        return unless @result?
        log=
            mode:"skill"
            to:@id
            comment:"あんまり自信ないけど、霊能占いの結果、#{@result.player.name}は#{@result.result}だと思う。たぶん。"
        splashlog game.id,game,log
    midnight:(game)->
        super
        p=game.getPlayer @target
        if p?
            @addGamelog game,"liardivine",null,p.id
            @result=
                player: p.publicinfo()
                result: if Math.random()<0.3
                    # 成功
                    if p.isWerewolf()
                        "人狼"
                    else
                        "村人"
                else
                    # 逆
                    if p.isWerewolf()
                        "村人"
                    else
                        "人狼"
    isWinner:(game,team)->team==@team && !@dead # 村人勝利で生存
class Spy2 extends Player
    type:"Spy2"
    jobname:"スパイⅡ"
    team:"Werewolf"
    makejobinfo:(game,result)->
        super
        # スパイは人狼が分かる
        result.wolves=game.players.filter((x)->x.isWerewolf()).map (x)->
            x.publicinfo()
    
    dying:(game,found)->
        super
        @publishdocument game
            
    publishdocument:(game)->
        str=game.players.map (x)->
            "#{x.name}:#{x.jobname}"
        .join " "
        log=
            mode:"system"
            comment:"#{@name}の調査報告書が発見されました。"
        splashlog game.id,game,log
        log2=
            mode:"will"
            comment:str
        splashlog game.id,game,log2
            
    isWinner:(game,team)-> team==@team && !@dead
class Copier extends Player
    type:"Copier"
    jobname:"コピー"
    team:""
    isHuman:->false
    sleeping:->true
    jobdone:->@target?
    sunset:(game)->
        @target=null
        if @scapegoat
            alives=game.players.filter (x)->!x.dead
            r=Math.floor Math.random()*alives.length
            pl=alives[r]
            @job game,pl.id,{}

    job:(game,playerid,query)->
        # コピー先
        if @target?
            return "既にコピーしています"
        @target=playerid
        log=
            mode:"skill"
            to:@id
            comment:"#{@name}が#{game.getPlayer(playerid).name}の能力をコピーしました。"
        splashlog game.id,game,log
        p=game.getPlayer playerid
        newpl=Player.factory p.type
        @transProfile newpl
        @transferData newpl
        newpl.sunset game   # 初期化してあげる
        @transform game,newpl

        
        #game.ss.publish.user newpl.id,"refresh",{id:game.id}
        game.splashjobinfo [game.getPlayer @id]
        null
    isWinner:(game,team)->false # コピーしないと負け
class Light extends Player
    type:"Light"
    jobname:"デスノート"
    sleeping:->true
    jobdone:->@target?
    sunset:(game)->
        @target=null
    job:(game,playerid,query)->
        # コピー先
        if @target?
            return "既に対象を選択しています"
        @target=playerid
        log=
            mode:"skill"
            to:@id
            comment:"#{@name}が#{game.getPlayer(playerid).name}の名前を死神の手帳に書きました。"
        splashlog game.id,game,log
        null
    midnight:(game)->
        t=game.getPlayer @target
        return unless t?
        return if t.dead
        t.die game,"deathnote"
        
        # 誰かに移る処理
        @uncomplex game,true    # 自分からは抜ける
class Fanatic extends Madman
    type:"Fanatic"
    jobname:"狂信者"
    makejobinfo:(game,result)->
        super
        # 狂信者は人狼が分かる
        result.wolves=game.players.filter((x)->x.isWerewolf()).map (x)->
            x.publicinfo()
class Immoral extends Player
    type:"Immoral"
    jobname:"背徳者"
    team:"Fox"
    beforebury:(game)->
        # 狐が全員死んでいたら自殺
        unless game.players.some((x)->!x.dead && x.isFox())
            @die game,"foxsuicide"
    makejobinfo:(game,result)->
        super
        # 妖狐が分かる
        result.foxes=game.players.filter((x)->x.type=="Fox").map (x)->
            x.publicinfo()
class Devil extends Player
    type:"Devil"
    jobname:"悪魔くん"
    team:"Devil"
    die:(game,found)->
        return if @dead
        if found=="werewolf"
            # 死なないぞ！
            unless @flag
                # まだ噛まれていない
                @flag="bitten"
        else if found=="punish"
            # 処刑されたぞ！
            if @flag=="bitten"
                # 噛まれたあと処刑された
                @flag="winner"
            else
                super
        else
            super
    isWinner:(game,team)->team==@team && @flag=="winner"
class ToughGuy extends Player
    type:"ToughGuy"
    jobname:"タフガイ"
    die:(game,found)->
        if found=="werewolf"
            # 狼の襲撃に耐える
            @flag="bitten"
        else
            super
    sunrise:(game)->
        super
        if @flag=="bitten"
            @flag="dying"   # 死にそう！
    sunset:(game)->
        super
        if @flag=="dying"
            # 噛まれた次の夜
            @flag=null
            @dead=true
            @found="werewolf"
            #game.bury()
class Cupid extends Player
    type:"Cupid"
    jobname:"キューピッド"
    team:"Friend"
    constructor:->
        super
        @flag=null  # 恋人1
        @target=null    # 恋人2
    sunset:(game)->
        if game.day>=2
            # 2日目以降はもう遅い
            @flag=""
            @target=""
        else
            @flag=null
            @target=null
            if @scapegoat
                # 身代わり君の自動占い
                alives=game.players.filter (x)->!x.dead
                i=0
                while i++<2
                    r=Math.floor Math.random()*alives.length
                    @job game,alives[r].id,{}
                    alives.splice r,1
    sleeping:->@flag? && @target?
    job:(game,playerid,query)->
        if @flag? && @target?
            return "既に対象は決定しています"
        if game.day>=2  #もう遅い
            return "もう恋の矢を放てません"
    
        pl=game.getPlayer playerid
        unless pl?
            return "対象が不正です"
        
        unless @flag?
            @flag=playerid
            log=
                mode:"skill"
                to:@id
                comment:"#{@name}は恋人の1人目に#{pl.name}を選びました。"
            splashlog game.id,game,log
            return null
        if @flag==playerid
            return "もう一人別の人を選んで下さい"
            
        @target=playerid
        # 恋人二人が決定した
        
        for pl in [game.getPlayer(@flag), game.getPlayer(@target)]
            # 2人ぶん処理
        
            newpl=Player.factory null,pl,null,Friend    # 恋人だ！
            pl.transProfile newpl
            pl.transform game,newpl # 入れ替え
            log=
                mode:"skill"
                to:@id
                comment:"#{@name}は#{newpl.name}へ恋の矢を放ちました。"
            splashlog game.id,game,log
            log=
                mode:"skill"
                to:newpl.id
                comment:"#{newpl.name}は恋人になりました。"
            splashlog game.id,game,log
        # 2人とも更新する
        for pl in [game.getPlayer(@flag), game.getPlayer(@target)]
            game.ss.publish.user pl.id,"refresh",{id:game.id}

        null
# ストーカー
class Stalker extends Player
    type:"Stalker"
    jobname:"ストーカー"
    team:""
    sunset:(game)->
        super
        if !@flag   # ストーキング先を決めていない
            @target=null
            if @scapegoat
                alives=game.players.filter (x)->!x.dead
                r=Math.floor Math.random()*alives.length
                pl=alives[r]
                @job game,pl.id,{}
        else
            @target=""
    sleeping:->@flag?
    job:(game,playerid,query)->
        if @target?
            return "既に対象は決定しています"
        if game.day>=2  #もう遅い
            return "もうストーキングできません"
    
        pl=game.getPlayer playerid
        unless pl?
            return "対象が不正です"
        @target=playerid
        log=
            mode:"skill"
            to:@id
            comment:"#{@name}は#{pl.name}（#{pl.jobname}）のストーカーになりました。"
        splashlog game.id,game,log
        @flag=playerid  # ストーキング対象プレイヤー
        null
    isWinner:(game,team)->
        @isWinnerStalk game,team,[]
    # ストーカー連鎖対応版
    isWinnerStalk:(game,team,ids)->
        if @id in ids
            # ループしてるので負け
            return false
        pl=game.getPlayer @flag
        return false unless pl?
        if team==pl.team
            return true
        if pl.isJobType "Stalker"
            # ストーカーを追跡
            return pl.isWinnerStalk game,team,ids.concat @id
        else
            return pl.isWinner game,team

    makejobinfo:(game,result)->
        super
        p=game.getPlayer @flag
        if p?
            result.stalking=p.publicinfo()
# 呪われた者
class Cursed extends Player
    type:"Cursed"
    jobname:"呪われた者"
    die:(game,found)->
        return if @dead
        if found=="werewolf"
            # 噛まれた場合人狼側になる
            unless @flag
                # まだ噛まれていない
                @flag="bitten"
        else
            super
    sunset:(game)->
        if @flag=="bitten"
            # この夜から人狼になる
            log=
                mode:"skill"
                to:@id
                comment:"#{@name}は呪われて人狼になりました。"
            splashlog game.id,game,log
            
            newpl=Player.factory "Werewolf"
            @transProfile newpl
            @transferData newpl
            @transform game,newpl
            newpl.sunset game
                    
            # 人狼側に知らせる
            game.ss.publish.channel "room#{game.id}_werewolf","refresh",{id:game.id}
            # 自分も知らせる
            game.ss.publish.user newpl.realid,"refresh",{id:game.id}
class ApprenticeSeer extends Player
    type:"ApprenticeSeer"
    jobname:"見習い占い師"
    beforebury:(game)->
        # 占い師が誰か死んでいたら占い師に進化
        if game.players.some((x)->x.dead && x.isJobType("Diviner")) || game.players.every((x)->!x.isJobType("Diviner"))
            newpl=Player.factory "Diviner"
            @transProfile newpl
            @transferData newpl
            log=
                mode:"skill"
                to:@id
                comment:"#{@name}は#{newpl.jobname}になりました。"
            splashlog game.id,game,log
            
            @transform game,newpl
            
            # 更新
            game.ss.publish.user newpl.realid,"refresh",{id:game.id}
class Diseased extends Player
    type:"Diseased"
    jobname:"病人"
    dying:(game,found)->
        super
        if found=="werewolf"
            # 噛まれた場合次の日人狼襲撃できない！
            game.werewolf_flag="Diseased"   # 病人フラグを立てる
class Spellcaster extends Player
    type:"Spellcaster"
    jobname:"呪いをかける者"
    sleeping:->true
    jobdone:->@target?
    sunset:(game)->
        @target=null
    job:(game,playerid,query)->
        if @target?
            return "既に対象を選択しています"
        arr=[]
        try
          arr=JSON.parse @flag
        catch error
          arr=[]
        unless arr instanceof Array
            arr=[]
        if playerid in arr
            # 既に呪いをかけたことがある
            return "その対象には既に呪いをかけています"
        @target=playerid
        log=
            mode:"skill"
            to:@id
            comment:"#{@name}が#{game.getPlayer(playerid).name}に呪いをかけました。"
        splashlog game.id,game,log
        arr.push playerid
        @flag=JSON.stringify arr
        null
    midnight:(game)->
        t=game.getPlayer @target
        return unless t?
        return if t.dead
        log=
            mode:"skill"
            to:t.id
            comment:"#{t.name}は呪いをかけられました。昼に発言できません。"
        splashlog game.id,game,log
        
        # 複合させる

        newpl=Player.factory null,t,null,Muted  # 黙る人
        t.transProfile newpl
        t.transform game,newpl
class Lycan extends Player
    type:"Lycan"
    jobname:"狼憑き"
    fortuneResult:"人狼"
class Priest extends Player
    type:"Priest"
    jobname:"聖職者"
    sleeping:->true
    jobdone:->@flag?
    sunset:(game)->
        @target=null
    job:(game,playerid,query)->
        if @flag?
            return "既に能力を使用しています"
        if @target?
            return "既に対象を選択しています"
        pl=game.getPlayer playerid
        unless pl?
            return "その対象は存在しません"
        if playerid==@id
            return "自分を対象にはできません"

        @target=playerid
        @flag="done"    # すでに能力を発動している
        log=
            mode:"skill"
            to:@id
            comment:"#{@name}が#{game.getPlayer(playerid).name}を聖なる力で守りました。"
        splashlog game.id,game,log
        
        # その場で変える
        # 複合させる

        newpl=Player.factory null,pl,null,HolyProtected # 守られた人
        pl.transProfile newpl
        newpl.cmplFlag=@id  # 護衛元
        pl.transform game,newpl

        null
class Prince extends Player
    type:"Prince"
    jobname:"プリンス"
    die:(game,found)->
        if found=="punish" && !@flag?
            # 処刑された
            @flag="used"    # 能力使用済
            log=
                mode:"system"
                comment:"#{@name}は#{@jobname}でした。処刑は行われませんでした。"
            splashlog game.id,game,log
            @addGamelog game,"princeCO"
        else
            super
# Paranormal Investigator
class PI extends Diviner
    type:"PI"
    jobname:"超常現象研究者"
    sleeping:->true
    jobdone:->@flag?
    job:(game,playerid)->
        @target=playerid
        log=
            mode:"skill"
            to:@id
            comment:"#{@name}が#{game.getPlayer(playerid).name}とその両隣を調査しました。"
        splashlog game.id,game,log
        if game.rule.divineresult=="immediate"
            @dodivine game
            @showdivineresult game
        @flag="done"    # 能力一回限り
        null
    #占い実行
    dodivine:(game)->
        pls=[]
        game.players.forEach (x,i)=>
            if x.id==@target
                pls.push x
                # 前
                if i==0
                    pls.push game.players[game.players.length-1]
                else
                    pls.push game.players[i-1]
                # 後
                if i>=game.players.length-1
                    pls.push game.players[0]
                else
                    pls.push game.players[i+1]
                
        
        if pls.length>0
            rs=pls.map((x)->x?.fortuneResult).filter((x)->x!="村人")    # 村人以外
            # 重複をとりのぞく
            nrs=[]
            rs.forEach (x,i)->
                if rs.indexOf(x,i+1)<0
                    nrs.push x
            @results.push {
                player: game.getPlayer(@target).publicinfo()
                result: nrs
            }
    showdivineresult:(game)->
        r=@results[@results.length-1]
        return unless r?
        resultstring=if r.result.length>0
            @addGamelog game,"PIdivine",true,r.player.id
            "#{r.result.join ","}が発見されました"
        else
            @addGamelog game,"PIdivine",false,r.player.id
            "全員村人でした"
        log=
            mode:"skill"
            to:@id
            comment:"#{@name}が#{r.player.name}とその両隣を調査したところ、#{resultstring}。"
        splashlog game.id,game,log
class Sorcerer extends Diviner
    type:"Sorcerer"
    jobname:"妖術師"
    team:"Werewolf"
    sleeping:->@target?
    sunset:(game)->
        super
        @target=null
        if @scapegoat
            # 身代わり君の自動占い
            r=Math.floor Math.random()*game.players.length
            @job game,game.players[r].id,{}
    job:(game,playerid)->
        @target=playerid
        log=
            mode:"skill"
            to:@id
            comment:"#{@name}が#{game.getPlayer(playerid).name}を調べました。"
        splashlog game.id,game,log
        if game.rule.divineresult=="immediate"
            @dodivine game
            @showdivineresult game
        null
    #占い実行
    dodivine:(game)->
        pl=game.getPlayer @target
        if pl?
            @results.push {
                player: game.getPlayer(@target).publicinfo()
                result: pl.isJobType "Diviner"
            }
    showdivineresult:(game)->
        r=@results[@results.length-1]
        return unless r?
        resultstring=if r.result
            "占い師でした"
        else
            "占い師ではありませんでした"
        log=
            mode:"skill"
            to:@id
            comment:"#{@name}が#{r.player.name}を調べたところ、#{resultstring}。"
        splashlog game.id,game,log
class Doppleganger extends Player
    type:"Doppleganger"
    jobname:"ドッペルゲンガー"
    sleeping:->true
    jobdone:->@flag?
    team:"" # 最初はチームに属さない!
    job:(game,playerid)->
        pl=game.getPlayer playerid
        unless pl?
            return "対象が不正です"
        if pl.id==@id
            return "自分を対象にできません"
        if pl.dead
            return "対象は既に死んでいます"
        log=
            mode:"skill"
            to:@id
            comment:"#{@name}が#{game.getPlayer(playerid).name}のドッペルゲンガーになりました。"
        splashlog game.id,game,log
        @flag=playerid  # ドッペルゲンガー先
        null
    beforebury:(game)->
        founds=game.players.filter (x)->x.dead && x.found
        # 対象が死んだら移る
        if founds.some((x)=>x.id==@flag)
            p=game.getPlayer @flag  # その人

            newplmain=Player.factory p.type
            @transProfile newplmain
            @transferData newplmain
            
            me=game.getPlayer @id
            # まだドッペルゲンガーできる
            sub=Player.factory "Doppleganger"
            @transProfile sub
            
            newpl=Player.factory null, newplmain,sub,Complex    # 合体
            @transProfile newpl
            
            pa=@getParent game  # 親を得る
            unless pa?
                # 親はいない
                @transform game,newpl
            else
                # 親がいる
                if pa.sub==this
                    # subなら親ごと置換
                    pa.transform game,newpl
                else
                    # mainなら自分だけ置換
                    @transform game,newpl
            log=
                mode:"skill"
                to:@id
                comment:"#{@name}は#{newpl.getJobDisp()}になりました。"
            splashlog game.id,game,log
            @addGamelog game,"dopplemove",newpl.type,newpl.id

        
            game.ss.publish.user newpl.realid,"refresh",{id:game.id}
class CultLeader extends Player
    type:"CultLeader"
    jobname:"カルトリーダー"
    team:"Cult"
    sleeping:->@target?
    sunset:(game)->
        super
        @target=null
        if @scapegoat
            # 身代わり君の自動占い
            r=Math.floor Math.random()*game.players.length
            @job game,game.players[r].id,{}
    job:(game,playerid)->
        @target=playerid
        log=
            mode:"skill"
            to:@id
            comment:"#{@name}が#{game.getPlayer(playerid).name}を信者にしました。"
        splashlog game.id,game,log
        @addGamelog game,"brainwash",null,playerid
        null
    midnight:(game)->
        t=game.getPlayer @target
        return unless t?
        return if t.dead
        log=
            mode:"skill"
            to:t.id
            comment:"#{t.name}はカルトの信者になりました。"

        # 信者
        splashlog game.id,game,log
        newpl=Player.factory null, t,null,CultMember    # 合体
        t.transProfile newpl
        t.transform game,newpl

    makejobinfo:(game,result)->
        super
        # 信者は分かる
        result.cultmembers=game.players.filter((x)->x.isCult()).map (x)->
            x.publicinfo()
class Vampire extends Player
    type:"Vampire"
    jobname:"ヴァンパイア"
    team:"Vampire"
    willDieWerewolf:false
    fortuneResult:"ヴァンパイア"
    sleeping:->@target?
    isHuman:->false
    isVampire:->true
    sunset:(game)->
        @target=null
        if @scapegoat
            r=Math.floor Math.random()*game.players.length
            if @job game,game.players[r].id,{}
                @sunset
    job:(game,playerid,query)->
        # 襲う先
        if @target?
            return "既に対象を選択しています"
        @target=playerid
        log=
            mode:"skill"
            to:@id
            comment:"#{@name}が#{game.getPlayer(playerid).name}を襲撃しました。"
        splashlog game.id,game,log
        null
    midnight:(game)->
        t=game.getPlayer @target
        return unless t?
        return if t.dead
        t.die game,"vampire"
    makejobinfo:(game,result)->
        super
        # ヴァンパイアが分かる
        result.vampires=game.players.filter((x)->x.isVampire()).map (x)->
            x.publicinfo()
class LoneWolf extends Werewolf
    type:"LoneWolf"
    jobname:"一匹狼"
    team:"LoneWolf"
    isWinner:(game,team)->team==@team && !@dead
class Cat extends Poisoner
    type:"Cat"
    jobname:"猫又"
    sunset:(game)->
        @target=if game.day<2 then "" else null
        if game.players.every((x)->!x.dead)
            @target=""  # 誰も死んでいないなら能力発動しない
        if !@target? && @scapegoat
            # 身代わり君の自動占い
            r=Math.floor Math.random()*game.players.length
            unless @job game,game.players[r].id,{}
                @target=""
    job:(game,playerid)->
        if game.day<2
            # まだ発動できない
            return "まだ能力を発動できません"
        @target=playerid
        pl=game.getPlayer playerid
        
        log=
            mode:"skill"
            to:@id
            comment:"#{@name}は#{pl.name}に死者蘇生術をかけました。"
        splashlog game.id,game,log
        null
    jobdone:->@target?
    sleeping:->true
    midnight:(game)->
        return unless @target?
        pl=game.getPlayer @target
        return unless pl?
        return unless pl.dead
        # 確率判定
        r=Math.random() # 0<=r<1
        unless r<=0.25
            # 失敗
            @addGamelog game,"catraise",false,pl.id
            return
        if r<=0.05
            # 5%の確率で誤爆
            deads=game.players.filter (x)->x.dead
            if deads.length==0
                # 誰もいないじゃん
                @addGamelog game,"catraise",false,pl.id
                return
            pl=deads[Math.floor(Math.random()*deads.length)]
            @addGamelog game,"catraise",pl.id,@target
        else
            @addGamelog game,"catraise",true,@target
        # 蘇生 目を覚まさせる
        pl.revive game
    deadnight:(game)->
        @target=@id
        @midnight game
        
    job_target:Player.JOB_T_DEAD
    makejobinfo:(game,result)->
        super
class Witch extends Player
    type:"Witch"
    jobname:"魔女"
    job_target:Player.JOB_T_ALIVE | Player.JOB_T_DEAD   # 死人も生存も
    sleeping:->true
    jobdone:->@target? || (@flag in [3,5,6])
    # @flag:ビットフラグ 1:殺害1使用済 2:殺害2使用済 4:蘇生使用済 8:今晩蘇生使用 16:今晩殺人使用
    constructor:->
        super
        @flag=0 # 発送済みかどうか
    sunset:(game)->
        @target=null
        unless @flag
            @flag=0
    job:(game,playerid,query)->
        # query.Witch_drug
        pl=game.getPlayer playerid
        unless pl?
            return "薬の使用先が不正です"
        if pl.id==@id
            return "自分には使用できません"

        if query.Witch_drug=="kill"
            # 毒薬
            if (@flag&3)==3
                # 蘇生薬は使い切った
                return "もう薬は使えません"
            else if (@flag&4) && (@flag&3)
                # すでに薬は2つ使っている
                return "もう薬は使えません"
            
            if pl.dead
                return "使用先は既に死んでいます"
            
            # 薬を使用
            @flag |= 16 # 今晩殺害使用
            if (@flag&1)==0
                @flag |= 1  # 1つ目
            else
                @flag |= 2  # 2つ目
            @target=playerid
            log=
                mode:"skill"
                to:@id
                comment:"#{@name}は#{pl.name}に毒薬を使いました。"
            splashlog game.id,game,log
        else
            # 蘇生薬
            if (@flag&3)==3 || (@flag&4)
                return "もう蘇生薬は使えません"
            
            if !pl.dead
                return "使用先はまだ生きています"
            
            # 薬を使用
            @flag |= 12
            @target=playerid
            log=
                mode:"skill"
                to:@id
                comment:"#{@name}は#{pl.name}に蘇生薬を使いました。"
            splashlog game.id,game,log
        null
    midnight:(game)->
        return unless @target?
        pl=game.getPlayer @target
        return unless pl?
        
        if @flag & 8
            # 蘇生
            @flag^=8
            # 蘇生 目を覚まさせる
            @addGamelog game,"witchraise",null,pl.id
            pl.revive game
        else if @flag & 16
            # 殺害
            @flag ^= 16
            @addGamelog game,"witchkill",null,pl.id
            pl.die game,"witch"
class Oldman extends Player
    type:"Oldman"
    jobname:"老人"
    midnight:(game)->
        # 夜の終わり
        wolves=game.players.filter (x)->x.isWerewolf() && !x.dead
        if wolves.length*2<=game.day
            # 寿命
            @die game,"infirm"
class Tanner extends Player
    type:"Tanner"
    jobname:"皮なめし職人"
    team:""
    die:(game,found)->
        if found in ["gone-day","gone-night"]
            # 突然死はダメ
            @flag="gone"
        super
    isWinner:(game,team)->@dead && @flag!="gone"
class OccultMania extends Player
    type:"OccultMania"
    jobname:"オカルトマニア"
    sleeping:(game)->@target? || game.day!=2
    sunset:(game)->
        @target=if game.day==2 then null else ""
        if !@target? && @scapegoat
            # 身代わり君の自動占い
            r=Math.floor Math.random()*game.players.length
            unless @job game,game.players[r].id,{}
                @target=""
    job:(game,playerid)->
        if game.day!=2
            # まだ発動できない
            return "今は能力を発動できません"
        @target=playerid
        pl=game.getPlayer playerid
        unless pl?
            return "その対象は存在しません"
        if pl.dead
            return "対象は既に死亡しています"
        
        log=
            mode:"skill"
            to:@id
            comment:"#{@name}は#{pl.name}を指定しました。"
        splashlog game.id,game,log
        null
    midnight:(game)->
        p=game.getPlayer @target
        return unless p?
        # 変化先決定
        type="Human"
        if p.isJobType "Diviner"
            type="Diviner"
        else if p.isWerewolf()
            type="Werewolf"
        
        newpl=Player.factory type
        @transProfile newpl
        @transferData newpl
        newpl.sunset game   # 初期化してあげる
        @transform game,newpl

        log=
            mode:"skill"
            to:@id
            comment:"#{@name}は#{newpl.getJobDisp()}になりました。"
        splashlog game.id,game,log

        
        game.ss.publish.user newpl.realid,"refresh",{id:game.id}
        null

# 狼の子
class WolfCub extends Werewolf
    type:"WolfCub"
    jobname:"狼の子"
    dying:(game,found)->
        super
        game.werewolf_flag="WolfCub"
# 囁き狂人
class WhisperingMad extends Fanatic
    type:"WhisperingMad"
    jobname:"囁き狂人"

    getSpeakChoice:(game)->
        ["werewolf"].concat super
    isListener:(game,log)->
        if log.mode=="werewolf"
            true
        else super
class Lover extends Player
    type:"Lover"
    jobname:"求愛者"
    team:"Friend"
    constructor:->
        super
        @target=null    # 相手
    sunset:(game)->
        if game.day>=2
            # 2日目以降はもう遅い
            @target=""
        else
            @target=null
            if @scapegoat
                # 身代わり君はかわいそうなのでやめる
                @target=""
    sleeping:(game)->game.day>=2 || @target?
    job:(game,playerid,query)->
        if @target?
            return "既に対象は決定しています"
        if game.day>=2  #もう遅い
            return "もう恋の矢を放てません"
    
        pl=game.getPlayer playerid
        unless pl?
            return "対象が不正です"
        if playerid==@id
            return "自分以外を選択して下さい"

        @target=playerid
        # 恋人二人が決定した
        
    
        for x in [this,pl]
            newpl=Player.factory null,x,null,Friend # 恋人だ！
            x.transProfile newpl
            x.transform game,newpl  # 入れ替え
        log=
            mode:"skill"
            to:@id
            comment:"#{@name}は#{pl.name}に求愛しました。"
        splashlog game.id,game,log
        log=
            mode:"skill"
            to:newpl.id
            comment:"#{pl.name}は求愛されて恋人になりました。"
        splashlog game.id,game,log
        # 2人とも更新する
        for pl in [this, pl]
            game.ss.publish.user pl.id,"refresh",{id:game.id}

        null
    

# 子分選択者
class MinionSelector extends Player
    type:"MinionSelector"
    jobname:"子分選択者"
    team:"Werewolf"
    sleeping:(game)->@target? || game.day>1 # 初日のみ
    sunset:(game)->
        @target=if game.day==1 then null else ""
        if !@target? && @scapegoat
            # 身代わり君の自動占い
            r=Math.floor Math.random()*game.players.length
            unless @job game,game.players[r].id,{}
                @target=""
    
    job:(game,playerid)->
        if game.day!=1
            # まだ発動できない
            return "今は能力を発動できません"
        @target=playerid
        pl=game.getPlayer playerid
        unless pl?
            return "その対象は存在しません"
        if pl.dead
            return "対象は既に死亡しています"
        
        # 複合させる
        newpl=Player.factory null,pl,null,WolfMinion    # WolfMinion
        pl.transProfile newpl
        pl.transform game,newpl
        log=
            mode:"wolfskill"
            comment:"#{@name}は#{pl.name}（#{pl.jobname}）を狼の子分に指定しました。"
        splashlog game.id,game,log

        log=
            mode:"skill"
            to:pl.id
            comment:"#{pl.name}は狼の子分になりました。"
        splashlog game.id,game,log

        null
# 盗人
class Thief extends Player
    type:"Thief"
    jobname:"盗人"
    team:""
    sleeping:(game)->@target? || game.day>1
    sunset:(game)->
        @target=if game.day==1 then null else ""
        # @flag:JSONの役職候補配列
        if !target?
            arr=JSON.parse(@flag ? '["Human"]')
            jobnames=arr.map (x)->
                testpl=new jobs[x]
                testpl.getJobDisp()
            log=
                mode:"skill"
                to:@id
                comment:"#{@name}が選択可能な役職は#{jobnames.join(",")}です"
            splashlog game.id,game,log
            if @scapegoat
                # 身代わり君
                arr=JSON.parse @flag
                r=Math.floor Math.random()*arr.length
                @job game,arr[r]
    job:(game,target)->
        @target=target
        unless jobs[target]?
            return "その役職にはなれません"

        newpl=Player.factory target
        @transProfile newpl
        @transferData newpl
        newpl.sunset game
        @transform game,newpl
        log=
            mode:"skill"
            to:@id
            comment:"#{@name}は#{newpl.getJobDisp()}になりました。"
        splashlog game.id,game,log
        
        game.ss.publish.user newpl.id,"refresh",{id:game.id}
        null
    makeJobSelection:(game)->
        if game.night
            # 役職から選択
            arr=JSON.parse @flag
            arr.map (x)->
                testpl=new jobs[x]
                {
                    name:testpl.getJobDisp()
                    value:x
                }
        else super
class Dog extends Player
    type:"Dog"
    jobname:"犬"
    fortuneResult:"人狼"
    psychicResult:"人狼"
    sunset:(game)->
        super
        @target=null    # 1日目:飼い主選択 選択後:かみ殺す人選択
        if !@flag   # 飼い主を決めていない
            if @scapegoat
                alives=game.players.filter (x)->!x.dead
                r=Math.floor Math.random()*alives.length
                pl=alives[r]
                @job game,pl.id,{}
        else
            # 飼い主を護衛する
            pl=game.getPlayer @flag
            if pl?
                if pl.dead
                    # もう死んでるじゃん
                    @target=""  # 洗濯済み
                else
                    newpl=Player.factory null,pl,null,Guarded   # 守られた人
                    pl.transProfile newpl
                    newpl.cmplFlag=@id  # 護衛元cmplFlag
                    pl.transform game,newpl

    sleeping:->@flag?
    jobdone:->@target?
    job:(game,playerid,query)->
        if @target?
            return "既に対象は決定しています"
    
        unless @flag?
            pl=game.getPlayer playerid
            unless pl?
                return "対象が不正です"
            # 飼い主を選択した
            log=
                mode:"skill"
                to:@id
                comment:"#{@name}は#{pl.name}を飼い主に選びました。"
            splashlog game.id,game,log
            @flag=playerid  # 飼い主
            @target=""  # 襲撃対象はなし
        else
            # 襲う
            pl=game.getPlayer @flag
            @target=@flag
            log=
                mode:"skill"
                to:@id
                comment:"#{@name}が#{pl.name}を襲撃しました。"
            splashlog game.id,game,log
        null
    midnight:(game)->
        return unless @target?
        pl=game.getPlayer @target
        return unless pl?

        # 殺害
        @addGamelog game,"dogkill",pl.type,pl.id
        pl.die game,"dog"
        null
    makejobinfo:(game,result)->
        super
        if !@jobdone() && game.night
            if @flag?
                # 飼い主いる
                pl=game.getPlayer @flag
                if pl?
                    if !pl.read
                        result.open.push "Dog1"
                    result.dogOwner=pl.publicinfo()

            else
                result.open.push "Dog2"
    makeJobSelection:(game)->
        # 噛むときは対象選択なし
        if game.night && @flag?
            []
        else super
class Dictator extends Player
    type:"Dictator"
    jobname:"独裁者"
    sleeping:->true
    jobdone:(game)->@flag? || game.night
    chooseJobDay:(game)->true
    job:(game,playerid,query)->
        if @flag?
            return "もう能力を発動できません"
        if game.night
            return "夜には発動できません"
        pl=game.getPlayer playerid
        unless pl?
            return "対象が不正です"
        @target=playerid    # 処刑する人
        log=
            mode:"system"
            comment:"独裁者の#{@name}により、#{pl.name}の処刑が宣言されました。"
        splashlog game.id,game,log
        @flag=true  # 使用済
        # その場で殺す!!!
        pl.die game,"punish"
        # 強制的に次のターンへ
        game.nextturn()
class SeersMama extends Player
    type:"SeersMama"
    jobname:"予言者のママ"
    sleeping:->true
    sunset:(game)->
        unless @flag
            # まだ能力を実行していない
            # 占い師を探す
            divs = game.players.filter (pl)->pl.isJobType "Diviner"
            divsstr=if divs.length>0
                "#{divs.map((x)->x.name).join ','}です"
            else
                "いません"
            log=
                mode:"skill"
                to:@id
                comment:"#{@name}は占い師のママです。占い師は#{divsstr}。"
            splashlog game.id,game,log
            @flag=true  #使用済
class Trapper extends Player
    type:"Trapper"
    jobname:"罠師"
    sleeping:->@target?
    sunset:(game)->
        @target=null
        if game.day==1
            # 一日目は護衛しない
            @target=""  # 誰も守らない
        else if @scapegoat
            # 身代わり君の自動占い
            r=Math.floor Math.random()*game.players.length
            if @job game,game.players[r].id,{}
                @sunset
    job:(game,playerid)->
        unless playerid==@id && game.rule.guardmyself!="ok"
            if playerid==@flag
                # 前も護衛した
                return "2日連続で同じ人は護衛できません"
            @target=playerid
            @flag=playerid
            pl=game.getPlayer(playerid)
            log=
                mode:"skill"
                to:@id
                comment:"#{@name}は#{pl.name}を罠で護衛しました。"
            splashlog game.id,game,log
            # 複合させる

            newpl=Player.factory null,pl,null,TrapGuarded   # 守られた人
            pl.transProfile newpl
            newpl.cmplFlag=@id  # 護衛元cmplFlag
            pl.transform game,newpl
            null
        else
            "自分を護衛することはできません"
class WolfBoy extends Madman
    type:"WolfBoy"
    jobname:"狼少年"
    sleeping:->true
    jobdone:->@target?
    sunset:(game)->
        @target=null
        if @scapegoat
            # 身代わり君の自動占い
            r=Math.floor Math.random()*game.players.length
            if @job game,game.players[r].id,{}
                @sunset
    job:(game,playerid)->
        @target=playerid
        pl=game.getPlayer playerid
        log=
            mode:"skill"
            to:@id
            comment:"#{@name}は#{pl.name}を人狼に仕立てました。"
        splashlog game.id,game,log
        # 複合させる

        newpl=Player.factory null,pl,null,Lycanized
        pl.transProfile newpl
        newpl.cmplFlag=@id  # 護衛元cmplFlag
        pl.transform game,newpl
        null
class Hoodlum extends Player
    type:"Hoodlum"
    jobname:"ならず者"
    team:""
    constructor:->
        super
        @flag="[]"  # 殺したい対象IDを入れておく
        @target=null
    sunset:(game)->
        if game.day>=2
            # もう何もない
            @target=""
        else
            # 2人選んでもらう
            @target=null
            if @scapegoat
                # 身代わり
                alives=game.players.filter (x)=>!x.dead && x!=this
                i=0
                while i++<2 && alives.length>0
                    r=Math.floor Math.random()*alives.length
                    @job game,alives[r].id,{}
                    alives.splice r,1
    sleeping:->@target?
    job:(game,playerid,query)->
        if @target?
            return "既に対象は決定しています"
        if game.day>=2
            return "もう対象を選択できません"
        pl=game.getPlayer playerid
        unless pl?
            return "対象が不正です"
        plids=JSON.parse(@flag)
        if pl.id in plids
            # 既にいる
            return "#{pl.name}は既に対象に選択しています"
        plids.push pl.id
        @flag=JSON.stringify plids
        log=
            mode:"skill"
            to:@id
            comment:"#{@name}は#{pl.name}を恨んでいます。"
        splashlog game.id,game,log
        if plids.length>=2
            @target=""
        else
            # 2人目を選んでほしい
            @target=null
        null

    isWinner:(game,team)->
        if @dead
            # 死んでたらだめ
            return false
        pls=JSON.parse(@flag).map (id)->game.getPlayer id
        return pls.every (pl)->pl?.dead==true
class QuantumPlayer extends Player
    type:"QuantumPlayer"
    jobname:"量子人間"
    getJobname:->
        flag=JSON.parse(@flag||"{}")
        jobname=null
        if flag.Human==1
            jobname="村人"
        else if flag.Diviner==1
            jobname="占い師"
        else if flag.Werewolf==1
            jobname="人狼"

        numstr=""
        if flag.number?
            numstr="##{flag.number}"
        ret=if jobname?
            "量子人間#{numstr}（#{jobname}）"
        else
            "量子人間#{numstr}"
        if @originalJobname != ret
            # 収束したぞ!
            @originalJobname=ret
        return ret
    sleeping:->
        tarobj=JSON.parse(@target || "{}")
        tarobj.Diviner? && tarobj.Werewolf?   # 両方指定してあるか
    sunset:(game)->
        #  @flagに{Human:(確率),Diviner:(確率),Werewolf:(確率),dead:(確率)}的なのが入っているぞ!
        obj=JSON.parse(@flag || "{}")
        tarobj=
            Diviner:null
            Werewolf:null
        if obj.Diviner==0
            tarobj.Diviner=""   # なし
        if obj.Werewolf==0
            tarobj.Werewolf=""

        @target=JSON.stringify tarobj
        if @scapegoat
            # 身代わり君の自動占い
            unless tarobj.Diviner?
                r=Math.floor Math.random()*game.players.length
                @job game,game.players[r].id,{
                    jobtype:"_Quantum_Diviner"
                }
            unless tarobj.Werewolf?
                nonme =game.players.filter (pl)=> pl!=this
                r=Math.floor Math.random()*nonme.length
                @job game,nonme[r].id,{
                    jobtype:"_Quantum_Werewolf"
                }
    isJobType:(type)->
        # 便宜的
        if type=="_Quantum_Diviner" || type=="_Quantum_Werewolf"
            return true
        super
    job:(game,playerid,query)->
        tarobj=JSON.parse(@target||"{}")
        pl=game.getPlayer playerid
        console.log query.jobtype,playerid,tarobj
        unless pl?
            return "その対象は存在しません"
        if query.jobtype=="_Quantum_Diviner" && !tarobj.Diviner?
            tarobj.Diviner=playerid
            log=
                mode:"skill"
                to:@id
                comment:"#{@name}が#{pl.name}を占いました。"
            splashlog game.id,game,log
        else if query.jobtype=="_Quantum_Werewolf" && !tarobj.Werewolf?
            if @id==playerid
                return "自分を襲うことはできません。"
            tarobj.Werewolf=playerid
            log=
                mode:"skill"
                to:@id
                comment:"#{@name}は#{pl.name}に狙いを定めました。"
            splashlog game.id,game,log
        else
            return "対象選択が不正です"
        @target=JSON.stringify tarobj

        null
    midnight:(game)->
        # ここで処理
        tarobj=JSON.parse(@target||"{}")
        if tarobj.Diviner
            pl=game.getPlayer tarobj.Diviner
            if pl?
                # 一旦自分が占い師のやつ以外排除
                pats=game.quantum_patterns.filter (obj)=>
                    obj[@id].jobtype=="Diviner" && obj[@id].dead==false
                # 1つ選んで占い結果を決定
                if pats.length>0
                    index=Math.floor Math.random()*pats.length
                    j=pats[index][tarobj.Diviner].jobtype
                    if j == "Werewolf"
                        log=
                            mode:"skill"
                            to:@id
                            comment:"#{@name}が#{pl.name}を占ったところ、人狼でした。"
                        splashlog game.id,game,log
                        # 人狼のやつ以外排除
                        game.quantum_patterns=game.quantum_patterns.filter (obj)=>
                            if obj[@id].jobtype=="Diviner"# && obj[@id].dead==false
                                obj[pl.id].jobtype == "Werewolf"
                            else
                                true
                    else
                        log=
                            mode:"skill"
                            to:@id
                            comment:"#{@name}が#{pl.name}を占ったところ、村人でした。"
                        splashlog game.id,game,log
                        # 村人のやつ以外排除
                        game.quantum_patterns=game.quantum_patterns.filter (obj)=>
                            if obj[@id].jobtype=="Diviner"# && obj[@id].dead==false
                                obj[pl.id].jobtype!="Werewolf"
                            else
                                true
                else
                    # 占えない
                    log=
                        mode:"skill"
                        to:@id
                        comment:"#{@name}が占い師である可能性が無くなったので、占えませんでした。"
                    splashlog game.id,game,log
        if tarobj.Werewolf
            pl=game.getPlayer tarobj.Werewolf
            if pl?
                game.quantum_patterns=game.quantum_patterns.filter (obj)=>
                    # 何番が筆頭かを求める
                    min=Infinity
                    for key,value of obj
                        if value.jobtype=="Werewolf" && value.dead==false && value.rank<min
                            min=value.rank
                    if obj[@id].jobtype=="Werewolf" && obj[@id].rank==min && obj[@id].dead==false
                        # 自分が筆頭人狼
                        if obj[pl.id].jobtype == "Werewolf"# || obj[pl.id].dead==true
                            # 襲えない
                            false
                        else
                            # さらに対応するやつを死亡させる
                            obj[pl.id].dead=true
                            true
                    else
                        true

    isWinner:(game,team)->
        flag=JSON.parse @flag
        unless flag?
            return false

        if flag.Werewolf==1 && team=="Werewolf"
            # 人狼がかったぞ!!!!!
            true
        else if flag.Werewolf==0 && team=="Human"
            # 人間がかったぞ!!!!!
            true
        else
            # よくわからないぞ!
            false
    makejobinfo:(game,result)->
        super
        tarobj=JSON.parse(@target||"{}")
        unless tarobj.Diviner?
            result.open.push "_Quantum_Diviner"
        unless tarobj.Werewolf?
            result.open.push "_Quantum_Werewolf"
        if game.rule.quantumwerewolf_table=="anonymous"
            # 番号がある
            flag=JSON.parse @flag
            result.quantumwerewolf_number=flag.number
    die:(game,found)->
        super
        # 可能性を排除する
        pats=[]
        if found=="punish"
            # 処刑されたときは既に死んでいた可能性を排除
            pats=game.quantum_patterns.filter (obj)=>
                obj[@id].dead==false
        else
            pats=game.quantum_patterns
        if pats.length
            # 1つ選んで役職を決定
            index=Math.floor Math.random()*pats.length
            tjt=pats[index][@id].jobtype
            trk=pats[index][@id].rank
            if trk?
                pats=pats.filter (obj)=>
                    obj[@id].jobtype==tjt && obj[@id].rank==trk
            else
                pats=pats.filter (obj)=>
                    obj[@id].jobtype==tjt

            # ワタシハシンダ
            pats.forEach (obj)=>
                obj[@id].dead=true
        game.quantum_patterns=pats

class RedHood extends Player
    type:"RedHood"
    jobname:"赤ずきん"
    sleeping:->true
    dying:(game,found,from)->
        super
        if found=="werewolf"
            # 狼に襲われた
            # 誰に襲われたか覚えておく
            @flag=from
        else
            @flag=null
    deadsunset:(game)->
        if @flag
            w=game.getPlayer @flag
            console.log w?.dead
            if w?.dead
                # 殺した狼が死んだ!復活する
                @revive game
    deadsunrise:(game)->
        # 同じ
        @deadsunset game

class Counselor extends Player
    type:"Counselor"
    jobname:"カウンセラー"
    sleeping:->true
    jobdone:->@target?
    sunset:(game)->
        @target=null
    job:(game,playerid,query)->
        if @target?
            return "既に対象を選択しています"
        @target=playerid
        log=
            mode:"skill"
            to:@id
            comment:"#{@name}が#{game.getPlayer(playerid).name}をカウンセリングしました。"
        splashlog game.id,game,log
        null
    midnight:(game)->
        t=game.getPlayer @target
        return unless t?
        return if t.dead
        if t.isWerewolf()
            # 人狼とかヴァンパイアを襲ったら殺される
            @die game,"werewolf"
            @addGamelog game,"counselKilled",t.type,@target
            return
        if t.isVampire()
            @die game,"vampire"
            @addGamelog game,"counselKilled",t.type,@target
            return
        if t.team!="Human"
            log=
                mode:"skill"
                to:t.id
                comment:"#{t.name}はカウンセリングされて更生しました。"
            splashlog game.id,game,log
            
            @addGamelog game,"counselSuccess",t.type,@target
            # 複合させる

            newpl=Player.factory null,t,null,Counseled  # カウンセリングされた
            t.transProfile newpl
            t.transform game,newpl
        else
            @addGamelog game,"counselFailure",t.type,@target
# 巫女
class Miko extends Player
    type:"Miko"
    jobname:"巫女"
    sleeping:->true
    jobdone:->!!@flag
    job:(game,playerid,query)->
        if @flag
            return "既に能力を使用しています"
        @target=playerid
        log=
            mode:"skill"
            to:@id
            comment:"#{@name}が聖なる力で自身を守りました。"
        splashlog game.id,game,log
        @flag=true
        # その場で変える
        # 複合させる
        pl = game.getPlayer @id

        newpl=Player.factory null,pl,null,MikoProtected # 守られた人
        pl.transProfile newpl
        pl.transform game,newpl
        null
    makeJobSelection:(game)->
        # 夜は投票しない
        if game.night
            []
        else super
class GreedyWolf extends Werewolf
    type:"GreedyWolf"
    jobname:"欲張りな狼"
    sleeping:(game)->game.werewolf_target_remain<=0 # 占いは必須ではない
    jobdone:(game)->game.werewolf_target_remain<=0 && (@flag || game.day>=2)
    job:(game,playerid,query)->
        if query.jobtype!="GreedyWolf"
            # 人狼の仕事
            return super
        if @flag
            return "既に能力を使用しています"
        @flag=true
        if game.werewolf_target_remain+game.werewolf_target.length ==0
            return "今夜は襲撃できません"
        log=
            mode:"wolfskill"
            comment:"#{@name}は欲張りました。人狼たちはもう1人襲撃できます。"
        splashlog game.id,game,log
        game.werewolf_target_remain++
        game.werewolf_flag="GreedyWolf_#{@id}"
        game.splashjobinfo game.players.filter (x)=>x.id!=@id && x.isWerewolf()
        null
    makejobinfo:(game,result)->
        super
        if game.night
            if @sleeping game
                # 襲撃は必要ない
                result.open = result.open?.filter (x)=>x!="_Werewolf"
            if !@flag && game.day>=2
                result.open?.push "GreedyWolf"
    makeJobSelection:(game)->
        if game.night && @sleeping(game) && !@jobdone(game)
            # 欲張る選択肢のみある
            return []
        else
            return super
    checkJobValidity:(game,query)->
        if query.jobtype=="GreedyWolf"
            # なしでOK!
            return true
        return super
class FascinatingWolf extends Werewolf
    type:"FascinatingWolf"
    jobname:"誘惑する女狼"
    sleeping:(game)->super && (game.day>=2 || @flag?)
    job:(game,playerid,query)->
        if query.jobtype!="FascinatingWolf"
            # 人狼の仕事
            return super
        if @flag
            return "既に能力を使用しています"
        if game.day>=2
            return "もう能力を使用できません"
        pl=game.getPlayer playerid
        unless pl?
            return "対象のプレイヤーは存在しません"
        log=
            mode:"skill"
            to:@id
            comment:"#{@name}は#{pl.name}を誘惑しようとしています。"
        @flag=playerid
        splashlog game.id,game,log
        null
    dying:(game,found)->
        # 死んだぞーーーーーーーーーーーーーー
        super
        # LWなら変えない
        if game.players.filter((x)->x.isWerewolf() && !x.dead).length==0
            return
        pl=game.getPlayer @flag
        unless pl?
            # あれれーーー
            return
        if pl.dead
            # 既に死んでいた
            return
        unless pl.isHuman() && pl.team!="Werewolf"
            # 誘惑できない
            return

        newpl=Player.factory null,pl,null,WolfMinion    # WolfMinion
        pl.transProfile newpl
        pl.transform game,newpl
        log=
            mode:"skill"
            to:pl.id
            comment:"#{pl.name}は狼に誘惑されました。"
        splashlog game.id,game,log
    makejobinfo:(game,result)->
        super
        if game.night
            if game.day>=2 || @flag
                # もう誘惑は必要ない
                result.open = result.open?.filter (x)=>x!="FascinatingWolf"
class SolitudeWolf extends Werewolf
    type:"SolitudeWolf"
    jobname:"孤独な狼"
    sleeping:(game)-> !@flag || super
    isListener:(game,log)->
        if log.mode in ["werewolf","wolfskill"]
            # 狼の声は聞こえない
            false
        else super
    job:(game,playerid,query)->
        if !@flag
            return "まだ襲えません"
        super
    sunset:(game)->
        wolves=game.players.filter (x)->x.isWerewolf()
        if wolves.every((x)->x.dead || x.isJobType("SolitudeWolf") && !x.flag)
            # 襲えるやつ誰もいない
            @flag=true
            log=
                mode:"skill"
                to:@id
                comment:"#{@name}は襲撃できるようになりました。"
            splashlog game.id,game,log
        super
    getSpeakChoice:(game)->
        res=super
        return res.filter (x)->x!="werewolf"
    makejobinfo:(game,result)->
        super
        delete result.wolves
        delete result.spy2s
class ToughWolf extends Werewolf
    type:"ToughWolf"
    jobname:"一途な狼"
    job:(game,playerid,query)->
        if query.jobtype!="ToughWolf"
            # 人狼の仕事
            return super
        if @flag
            return "既に能力を使用しています"
        res=super
        if res?
            return res
        @flag=true
        game.werewolf_flag="ToughWolf_#{@id}"
        tp=game.getPlayer playerid
        unless tp?
            return "その対象は存在しません"
        log=
            mode:"wolfskill"
            comment:"#{@name}は捨て身の覚悟で#{tp.name}を狙っています。"
        splashlog game.id,game,log
        null
class ThreateningWolf extends Werewolf
    type:"ThreateningWolf"
    jobname:"威嚇する狼"
    jobdone:(game)->
        if game.night
            super
        else
            @flag?
    chooseJobDay:(game)->true
    sunrise:(game)->
        super
        @target=null
    job:(game,playerid,query)->
        if query.jobtype!="ThreateningWolf"
            # 人狼の仕事
            return super
        if @flag
            return "既に能力を使用しています"
        if game.night
            return "夜には発動できません"
        pl=game.getPlayer playerid
        unless pl?
            return "対象が不正です"
        @target=playerid
        @flag=true
        log=
            mode:"skill"
            to:@id
            comment:"#{@name}は#{pl.id}を威嚇しました。"
        splashlog game.id,game,log
        null
    sunset:(game)->
        t=game.getPlayer @target
        return unless t?
        return if t.dead
            
        # 威嚇して能力無しにする
        @addGamelog game,"threaten",t.type,@target
        # 複合させる

        log=
            mode:"skill"
            to:t.id
            comment:"#{t.name}は威嚇されました。今夜は能力が無効化されます。"
        splashlog game.id,game,log

        newpl=Player.factory null,t,null,Threatened  # カウンセリングされた
        t.transProfile newpl
        t.transform game,newpl
    makejobinfo:(game,result)->
        super
        if game.night
            # 夜は威嚇しない
            result.open = result.open?.filter (x)=>x!="ThreateningWolf"
class HolyMarked extends Human
    type:"HolyMarked"
    jobname:"聖痕者"
    
# 処理上便宜的に使用
class GameMaster extends Player
    type:"GameMaster"
    jobname:"ゲームマスター"
    team:""
    jobdone:->false
    sleeping:->true
    isWinner:(game,team)->null
    # 例外的に昼でも発動する可能性がある
    job:(game,playerid,query)->
        pl=game.getPlayer playerid
        unless pl?
            return "その対象は不正です"
        pl.die game,"gmpunish"
        game.bury()
        null
    isListener:(game,log)->true # 全て見える
    getSpeakChoice:(game)->
        pls=for pl in game.players
            "gmreply_#{pl.id}"
        ["gm","gmheaven","gmaudience","gmmonologue"].concat pls
    getSpeakChoiceDay:(game)->@getSpeakChoice game
    chooseJobDay:(game)->true   # 昼でも対象選択

# ヘルパー
class Helper extends Player
    type:"Helper"
    jobname:"ヘルパー"
    team:""
    jobdone:->true
    sleeping:->true
    isWinner:(game,team)->
        pl=game.getPlayer @flag
        return pl?.isWinner game,team
    # @flag: リッスン対象のid
    # 同じものが見える
    isListener:(game,log)->
        pl=game.getPlayer @flag
        return false unless pl?
        return pl.isListener game,log
    getSpeakChoice:(game)->
        return ["helperwhisper_#{@flag}"]
    getSpeakChoiceDay:(game)->@getSpeakChoice game
    makejobinfo:(game,result)->
        super
        # ヘルプ先が分かる
        pl=game.getPlayer @flag
        result.supporting=pl?.publicinfo()
        result.supportingJob=pl?.getJobDisp()

# 開始前のやつだ!!!!!!!!
class Waiting extends Player
    type:"Waiting"
    jobname:"待機中"
    team:""
    sleeping:(game)->!game.rolerequestingphase || game.rolerequesttable[@id]?
    isListener:(game,log)->
       if log.mode=="audience"
           true
       else super
    getSpeakChoice:(game)->
        return ["prepare"]
    makejobinfo:(game,result)->
        super
        # 自分で追加する
        result.open.push "Waiting"
    makeJobSelection:(game)->
        if game.day==0 && game.rolerequestingphase
            # 開始前
            result=[{
                name:"おまかせ"
                value:""
            }]
            for job,num of game.joblist
                if num
                    result.push {
                        name:Shared.game.getjobname job
                        value:job
                    }
            return result
        else super
    job:(game,target)->
        # 希望役職
        game.rolerequesttable[@id]=target
        if target
            log=
                mode:"skill"
                to:@id
                comment:"#{@name}は#{Shared.game.getjobname target}を希望しました。"
        else
            log=
                mode:"skill"
                to:@id
                comment:"#{@name}は希望役職をおまかせにしました。"
        splashlog game.id,game,log
        null

            

# 複合役職 Player.factoryで適切に生成されることを期待
# superはメイン役職 @mainにメイン @subにサブ
# @cmplFlag も持っていい
class Complex
    cmplType:"Complex"  # 複合親そのものの名前
    isComplex:->true
    getJobname:->@main.getJobname()
    getJobDisp:->@main.getJobDisp()
    
    jobdone:(game)-> @main.jobdone(game) && (!@sub?.jobdone? || @sub.jobdone(game)) # ジョブの場合はサブも考慮
    job:(game,playerid,query)-> # どちらの
        if @main.isJobType(query.jobtype) && !@main.jobdone(game)
            @main.job game,playerid,query
        else if @sub?.isJobType?(query.jobtype) && !@sub?.jobdone?(game)
            @sub.job? game,playerid,query
        
    isJobType:(type)->
        @main.isJobType(type) || @sub?.isJobType?(type)
    sunset:(game)->
        @main.sunset game
        @sub?.sunset? game
    midnight:(game)->
        @main.midnight game
        @sub?.midnight? game
    sunrise:(game)->
        @main.sunrise game
        @sub?.sunrise? game
    votestart:(game)->
        @main.votestart game
    voted:(game,votingbox)->@main.voted game,votingbox
    dovote:(game,target)->
        @main.dovote game,target
    
    makejobinfo:(game,result)->
        @sub?.makejobinfo? game,result
        @main.makejobinfo game,result
    beforebury:(game)->
        @main.beforebury game
        @sub?.beforebury? game
    setWinner:(winner)->
        @winner=winner
        @main.setWinner winner
    getjob_target:->
        if @sub?
            @main.getjob_target() | @sub.getjob_target()    # ビットフラグ
        else
            @main.getjob_target()
    die:(game,found,from)->
        @main.die game,found,from
        @sub?.die game,found,from
    dying:(game,found,from)->
        @main.dying game,found,from
        @sub?.dying game,found,from
    revive:(game)->
        @main.revive game
        @sub?.revive game
    makeJobSelection:(game)->
        result=@main.makeJobSelection game
        if @sub?
            for obj in @sub.makeJobSelection game
                unless result.some((x)->x.value==obj.value)
                    result.push obj
        result

#superがつかえないので注意
class Friend extends Complex    # 恋人
    cmplType:"Friend"
    isFriend:->true
    team:"Friend"
    getJobname:->"恋人（#{@main.getJobname()}）"
    getJobDisp:->"恋人（#{@main.getJobDisp()}）"
    
    beforebury:(game)->
        @main.beforebury game
        @sub?.beforebury? game
        friends=game.players.filter (x)->x.isFriend()   #恋人たち
        # 恋人が誰か死んだら自殺
        if friends.length>1 && friends.some((x)->x.dead)
            @die game,"friendsuicide"
    makejobinfo:(game,result)->
        @sub?.makejobinfo? game,result
        @main.makejobinfo game,result
        # 恋人が分かる
        result.desc?.push {
            name:"恋人"
            type:"Friend"
        }
        result.friends=game.players.filter((x)->x.isFriend()).map (x)->
            x.publicinfo()
    isWinner:(game,team)->@team==team
# 聖職者にまもられた人
class HolyProtected extends Complex
    # cmplFlag: 護衛元
    cmplType:"HolyProtected"
    die:(game,found)->
        # 一回耐える 死なない代わりに元に戻る
        log=
            mode:"skill"
            to:@id
            comment:"#{@name}は聖なる力で守られました。"
        splashlog game.id,game,log
        game.getPlayer(@cmplFlag).addGamelog game,"holyGJ",found,@id
        
        @uncomplex game
# カルトの信者になった人
class CultMember extends Complex
    cmplType:"CultMember"
    isCult:->true
    getJobname:->"カルト信者（#{@main.getJobname()}）"
    getJobDisp:->"カルト信者（#{@main.getJobDisp()}）"
    makejobinfo:(game,result)->
        super
        # 信者の説明
        result.desc?.push {
            name:"カルト信者"
            type:"CultMember"
        }
# 狩人に守られた人
class Guarded extends Complex
    # cmplFlag: 護衛元ID
    cmplType:"Guarded"
    die:(game,found,from)->
        unless found=="werewolf"
            @main.die game,found,from
        else
            # 狼に噛まれた場合は耐える
            guard=game.getPlayer @cmplFlag
            if guard?
                guard.addGamelog game,"GJ",null,@id
                if game.rule.gjmessage
                    log=
                        mode:"skill"
                        to:guard.id
                        comment:"#{guard.name}は#{@name}を人狼の襲撃から護衛しました。"
                    splashlog game.id,game,log

    sunrise:(game)->
        # 一日しか守られない
        @main.sunrise game
        @sub?.sunrise? game
        @uncomplex game
# 黙らされた人
class Muted extends Complex
    cmplType:"Muted"

    sunset:(game)->
        # 一日しか効かない
        @main.sunset game
        @sub?.sunset? game
        @uncomplex game
        game.ss.publish.user @id,"refresh",{id:game.id}
    getSpeakChoiceDay:(game)->
        ["monologue"]   # 全員に喋ることができない
# 狼の子分
class WolfMinion extends Complex
    cmplType:"WolfMinion"
    team:"Werewolf"
    getJobname:->"狼の子分（#{@main.getJobname()}）"
    getJobDisp:->"狼の子分（#{@main.getJobDisp()}）"
    makejobinfo:(game,result)->
        @sub?.makejobinfo? game,result
        @main.makejobinfo game,result
        result.desc?.push {
            name:"狼の子分"
            value:"WolfMinion"
        }
    isWinner:(game,team)->@team==team
# 酔っ払い
class Drunk extends Complex
    cmplType:"Drunk"
    getJobname:->"酔っ払い（#{@main.getJobname()}）"
    getTypeDisp:->"Human"
    getJobDisp:->"村人"
    sleeping:->true
    jobdone:->true
    isListener:(game,log)->
        Human.prototype.isListener.call @,game,log

    sunset:(game)->
        @main.sunrise game
        @sub?.sunrise? game
        if game.day>=3
            # 3日目に目が覚める
            log=
                mode:"skill"
                to:@id
                comment:"#{@name}は目が覚めました。"
            splashlog game.id,game,log
            @uncomplex game
            game.ss.publish.user @realid,"refresh",{id:game.id}
    makejobinfo:(game,obj)->
        Human.prototype.makejobinfo.call @,game,obj
    isDrunk:->true
    getSpeakChoice:(game)->
        Human.prototype.getSpeakChoice.call @,game
# 罠師守られた人
class TrapGuarded extends Complex
    # cmplFlag: 護衛元ID
    cmplType:"TrapGuarded"
    midnight:(game)->
        # 狩人とかぶったら狩人が死んでしまう!!!!!
        # midnight: 狼の襲撃よりも前に行われることが保証されている処理
        wholepl=game.getPlayer @id  # 一番表から見る
        result=@checkGuard game,wholepl
        if result
            # 狩人がいた!（罠も無効）
            @uncomplex game
    # midnight処理用
    checkGuard:(game,pl)->
        return false unless pl.isComplex()
        # Complexの場合:mainとsubを確かめる
        unless pl.cmplType=="Guarded"
            # 見つからない
            result=false
            result ||= @checkGuard game,pl.main
            if pl.sub?
                # 枝を切る
                result ||=@checkGuard game,pl.sub
            return result
        else
            # あった!
            # cmplFlag: 護衛元の狩人
            gu=game.getPlayer pl.cmplFlag
            if gu?
                tr = game.getPlayer @cmplFlag   # 罠し
                if tr?
                    tr.addGamelog game,"trappedGuard",null,@id
                gu.die game,"trap"

            pl.uncomplex game   # 消滅
            # 子の調査を継続
            @checkGuard game,pl.main
            return true

    die:(game,found)->
        unless found=="werewolf"
            # 狼以外だとしぬ
            @main.die game,found
        else
            # 狼に噛まれた場合は耐える
            guard=game.getPlayer @cmplFlag
            if guard?
                guard.addGamelog game,"trapGJ",null,@id
                if game.rule.gjmessage
                    log=
                        mode:"skill"
                        to:guard.id
                        comment:"#{guard.name}の罠により#{@name}が人狼の襲撃から守られました。"
                    splashlog game.id,game,log
            # 反撃する
            canbedead=game.players.filter (x)->!x.dead && x.isWerewolf()
        return if canbedead.length==0
        r=Math.floor Math.random()*canbedead.length
        pl=canbedead[r] # 被害者
        pl.die game,"trap"
        @addGamelog game,"trapkill",null,pl.id


    sunrise:(game)->
        # 一日しか守られない
        @main.sunrise game
        @sub?.sunrise? game
        @uncomplex game
# 黙らされた人
class Lycanized extends Complex
    cmplType:"Lycanized"
    fortuneResult:"人狼"
    sunset:(game)->
        # 一日しか効かない
        @main.sunset game
        @sub?.sunset? game
        @uncomplex game
# カウンセラーによって更生させられた人
class Counseled extends Complex
    cmplType:"Counseled"
    team:"Human"
    getJobname:->"更生者（#{@main.getJobname()}）"
    getJobDisp:->"更生者（#{@main.getJobname()}）"

    isWinner:(game,team)->@team==team
    makejobinfo:(game,result)->
        @sub?.makejobinfo? game,result
        @main.makejobinfo game,result
        result.desc?.push {
            name:"更生者"
            type:"Counseled"
        }
# 巫女のガードがある状態
class MikoProtected extends Complex
    cmplType:"MikoProtected"
    die:(game,found)->
        # 耐える
        game.getPlayer(@id).addGamelog game,"mikoGJ",found
    sunset:(game)->
        # 一日しか効かない
        @main.sunset game
        @sub?.sunset? game
        @uncomplex game
# 威嚇する人狼に威嚇された
class Threatened extends Complex
    cmplType:"Threatened"
    sleeping:->true
    jobdone:->true
    isListener:(game,log)->
        Human.prototype.isListener.call @,game,log

    sunrise:(game)->
        # この昼からは戻る
        @uncomplex game
        pl=game.getPlayer @id
        if pl?
            pl.sunset game
    sunset:(game)->
    midnight:(game)->
    job:(game,playerid,query)->
        null
    die:(game,found,from)->
        Human.prototype.die.call @,game,found,from
    dying:(game,found,from)->
        Human.prototype.dying.call @,game,found,from
    divined:(game,player)->
    makejobinfo:(game,obj)->
        Human.prototype.makejobinfo.call @,game,obj
    getSpeakChoice:(game)->
        Human.prototype.getSpeakChoice.call @,game
        
# 決定者
class Decider extends Complex
    cmplType:"Decider"
    getJobname:->"#{@main.getJobname()}（決定者）"
    dovote:(game,target)->
        result=@main.dovote game,target
        return result if result?
        game.votingbox.votePriority this,1  #優先度を1上げる
        null
# 権力者
class Authority extends Complex
    cmplType:"Authority"
    getJobname:->"#{@main.getJobname()}（権力者）"
    dovote:(game,target)->
        result=@main.dovote game,target
        return result if result?
        game.votingbox.votePower this,1 #票をひとつ増やす
        null
games={}

# ゲームを得る
getGame=(id)->

# 仕事一覧
jobs=
    Human:Human
    Werewolf:Werewolf
    Diviner:Diviner
    Psychic:Psychic
    Madman:Madman
    Guard:Guard
    Couple:Couple
    Fox:Fox
    Poisoner:Poisoner
    BigWolf:BigWolf
    TinyFox:TinyFox
    Bat:Bat
    Noble:Noble
    Slave:Slave
    Magician:Magician
    Spy:Spy
    WolfDiviner:WolfDiviner
    Fugitive:Fugitive
    Merchant:Merchant
    QueenSpectator:QueenSpectator
    MadWolf:MadWolf
    Neet:Neet
    Liar:Liar
    Spy2:Spy2
    Copier:Copier
    Light:Light
    Fanatic:Fanatic
    Immoral:Immoral
    Devil:Devil
    ToughGuy:ToughGuy
    Cupid:Cupid
    Stalker:Stalker
    Cursed:Cursed
    ApprenticeSeer:ApprenticeSeer
    Diseased:Diseased
    Spellcaster:Spellcaster
    Lycan:Lycan
    Priest:Priest
    Prince:Prince
    PI:PI
    Sorcerer:Sorcerer
    Doppleganger:Doppleganger
    CultLeader:CultLeader
    Vampire:Vampire
    LoneWolf:LoneWolf
    Cat:Cat
    Witch:Witch
    Oldman:Oldman
    Tanner:Tanner
    OccultMania:OccultMania
    MinionSelector:MinionSelector
    WolfCub:WolfCub
    WhisperingMad:WhisperingMad
    Lover:Lover
    Thief:Thief
    Dog:Dog
    Dictator:Dictator
    SeersMama:SeersMama
    Trapper:Trapper
    WolfBoy:WolfBoy
    Hoodlum:Hoodlum
    QuantumPlayer:QuantumPlayer
    RedHood:RedHood
    Counselor:Counselor
    Miko:Miko
    GreedyWolf:GreedyWolf
    FascinatingWolf:FascinatingWolf
    SolitudeWolf:SolitudeWolf
    ToughWolf:ToughWolf
    ThreateningWolf:ThreateningWolf
    HolyMarked:HolyMarked
    # 特殊
    GameMaster:GameMaster
    Helper:Helper
    # 開始前
    Waiting:Waiting
    
complexes=
    Complex:Complex
    Friend:Friend
    HolyProtected:HolyProtected
    CultMember:CultMember
    Guarded:Guarded
    Muted:Muted
    WolfMinion:WolfMinion
    Drunk:Drunk
    Decider:Decider
    Authority:Authority
    TrapGuarded:TrapGuarded
    Lycanized:Lycanized
    Counseled:Counseled
    MikoProtected:MikoProtected
    Threatened:Threatened


module.exports.actions=(req,res,ss)->
    req.use 'session'

#ゲーム開始処理
#成功：null
    gameStart:(roomid,query)->
        game=games[roomid]
        unless game?
            res "そのゲームは存在しません"
            return
        Server.game.rooms.oneRoomS roomid,(room)->
            if room.error?
                res room.error
                return
            unless room.mode=="waiting"
                # すでに開始している
                res "そのゲームは既に開始しています"
                return
            if room.players.some((x)->!x.start)
                res "まだ全員の準備ができていません"
                return
            # ルールオブジェクト用意
            ruleobj={
                number: room.players.length
                maxnumber:room.number
                blind:room.blind
                gm:room.gm
                day: parseInt(query.day_minute)*60+parseInt(query.day_second)
                night: parseInt(query.night_minute)*60+parseInt(query.night_second)
                remain: parseInt(query.remain_minute)*60+parseInt(query.remain_second)
                # (n=15)秒ルール
                silentrule: parseInt(query.silentrule) ? 0
            }
            
            options={}  # オプションズ
            for opt in ["decider","authority"]
                options[opt]=query[opt] ? null

            joblist={}
            for job of jobs
                joblist[job]=0  # 一旦初期化
            #frees=room.players.length  # 参加者の数
            # プレイヤーとその他に分類
            players=[]
            supporters=[]
            for pl in room.players
                if pl.mode=="player"
                    players.push pl
                else
                    supporters.push pl
            frees=players.length
            if query.scapegoat=="on"    # 身代わりくん
                frees++
            playersnumber=frees
            # 人数の確認
            if frees<4
                res "人数が少なすぎるので開始できません"
                return
            if query.jobrule=="特殊ルール.量子人狼" && frees>=20
                # 多すぎてたえられない
                res "人数が多過ぎます。量子人狼では人数を19人以下にして下さい。"
                return
                
            ruleinfo_str="" # 開始告知

            if query.jobrule in ["特殊ルール.自由配役","特殊ルール.一部闇鍋"]   # 自由のときはクエリを参考にする
                for job in Shared.game.jobs
                    joblist[job]=parseInt query[job]    # 仕事の数
                # カテゴリも
                for type of Shared.game.categoryNames
                    joblist["category_#{type}"]=parseInt query["category_#{type}"]
                ruleinfo_str = Shared.game.getrulestr query.jobrule,joblist
            if query.jobrule in ["特殊ルール.闇鍋","特殊ルール.一部闇鍋"]
                # カテゴリ内の人数の合計がわかる関数
                countCategory=(categoryname)->
                    Shared.game.categories[categoryname].reduce(((prev,curr)->prev+(joblist[curr] ? 0)),0)+joblist["category_#{categoryname}"]

                # 闇鍋のときはランダムに決める
                pls=frees   # プレイヤーの数をとっておく
                plsh=Math.floor pls/2   # 過半数
        
                safety={
                    jingais:false   # 人外の数を調整
                    teams:false     # 陣営の数を調整
                    jobs:false      # 職どうしの数を調整
                }
                switch query.yaminabe_safety
                    when "low"
                        # 低い
                        safety.jingais=true
                    when "middle"
                        safety.jingais=true
                        safety.teams=true
                    when "high"
                        safety.jingais=true
                        safety.teams=true
                        safety.jobs=true

                # 闇鍋のときは入れないのがある
                exceptions=["MinionSelector","Thief","GameMaster","Helper","QuantumPlayer","Waiting"]
                options.yaminabe_hidejobs=query.yaminabe_hidejobs ? null
                if query.jobrule=="特殊ルール.一部闇鍋"
                    # 一部闇鍋のときは村人のみ闇鍋
                    frees=joblist.Human ? 0
                    joblist.Human=0
                unless query.jobrule=="特殊ルール.一部闇鍋" && countCategory("Werewolf")>0
                    #人外の数
                    if safety.jingais
                        # いい感じに決めてあげる
                        wolf_number=1
                        fox_number=0
                        vampire_number=0
                        devil_number=0
                        if frees>=9
                            wolf_number++
                            if frees>=12
                                if Math.random()<0.7
                                    fox_number++
                                else if Math.random()<0.7
                                    devil_number++
                                if frees>=14
                                    wolf_number++
                                    if frees>=16
                                        if Math.random()<0.5
                                            fox_number++
                                        else if Math.random()<0.3
                                            vampire_number++
                                        else
                                            devil_number++
                                        if frees>=18
                                            wolf_number++
                                            if frees>=22
                                                if Math.random()<0.2
                                                    fox_number++
                                                else if Math.random()<0.6
                                                    vampire_number++
                                                else if Math.random()<0.9
                                                    devil_number++
                                            if frees>=24
                                                wolf_number++
                                                if frees>=30
                                                    wolf_number++
                        # ランダム調整
                        if wolf_number>1 && Math.random()<0.3
                            wolf_number--
                            if wolf_number>1 && Math.random()<0.2
                                wolf_number--
                        else if frees>0 && playersnumber>=10 && Math.random()<0.4
                            wolf_number++
                        if fox_number>1 && Math.random()<0.2
                            fox_number--
                        else if frees>=8 && Math.random()<0.3
                            fox_number++
                        if frees>=11 && Math.random()<0.2
                            vampire_number++
                        if frees>=11 && Math.random()<0.2
                            devil_number++
                        # セットする
                        joblist.category_Werewolf=wolf_number
                        joblist.Fox=fox_number
                        if fox_number>1 && Math.random()<0.4
                            # 子狐
                            joblist.TinyFox=1
                            joblist.Fox--
                        joblist.Vampire=vampire_number
                        joblist.Devil=devil_number
                        frees-= wolf_number+fox_number+vampire_number+devil_number
                        # 人外は選んだのでもう選ばれなくする
                        exceptions=exceptions.concat Shared.game.nonhumans
                    else
                        # 調整しない
                        joblist.category_Werewolf=1
                        frees--
                
                ruleinfo_str = Shared.game.getrulestr query.jobrule,joblist
                if safety.jingais
                    if joblist.Fox==0
                        exceptions.push "Immoral"   # 狐がいないのに背徳は出ない
                    

                if safety.teams
                    # 陣営調整もする
                    # 恋人陣営
                    if frees>0
                        if playersnumber>=8
                            if Math.random()<0.3
                                joblist.Cupid++
                                frees--
                            else if Math.random()<0.2
                                joblist.Lover++
                                frees--
                        else if playersnumber>=8
                            if Math.random()<0.15
                                joblist.Lover++
                                frees--
                            else if Math.random()<0.1
                                joblist.Cupid++
                                frees--
                    exceptions.push "Cupid","Lover"
                    # 妖狐陣営
                    if frees>0 && joblist.Fox>0
                        if joblist.Fox==1
                            if playersnumber>=14
                                # 1人くらいは…
                                if Math.random()<0.3
                                    joblist.Immoral++
                                    frees--
                            else
                                # サプライズ的に…
                                if Math.random()<0.1
                                    joblist.Immoral++
                                    frees--
                            exceptions.push "Immoral"
                    # 人狼陣営
                    if frees>0
                        wolf_number = countCategory "Werewolf"
                        if wolf_number<=playersnumber/8
                            # 確定狂人サービス
                            joblist.category_Madman ?= 0
                            joblist.category_Madman++
                            frees--
                    # 村人陣営
                    if frees>0
                        # 占い師いてほしい
                        if Math.random()<0.5
                            joblist.Diviner++
                            frees--
                        else if Math.random()<0.4
                            joblist.ApprenticeSeer++
                            frees--
                        # できれば狩人も
                        if frees>0 && Math.random()<0.2
                            joblist.Guard++
                            frees--
                        if frees>0 && wolf_number>=3 && Math.random()<0.1
                            # めずらしい
                            joblist.MadWolf++
                            frees--
                
                possibility=Object.keys(jobs).filter (x)->!(x in exceptions)
                
                wolf_teams=countCategory "Werewolf"
            
                # 強制的に入れる関数
                init=(jobname,categoryname)->
                    unless jobname in possibility
                        return false
                    if joblist["category_#{categoryname}"]>0
                        # あった
                        joblist[jobname]++
                        joblist["category_#{categoryname}"]--
                        return true
                    if frees>0
                        # あった
                        joblist[jobname]++
                        frees--
                        return true
                    return false

                while true
                    category=null
                    job=null
                    #カテゴリ役職がまだあるか探す
                    for type,arr of Shared.game.categories
                        if joblist["category_#{type}"]>0
                            r=Math.floor Math.random()*arr.length
                            job=arr[r]
                            category="category_#{type}"
                            break
                    unless job?
                        # もうカテゴリがない
                        if frees==0
                            # もう空きがない
                            break
                        r=Math.floor Math.random()*possibility.length
                        job=possibility[r]
                    if safety.teams && !category?
                        if job in Shared.game.teams.Werewolf
                            if wolf_teams+1>=plsh
                                # 人狼が過半数を越えた（PP）
                                continue
                    if safety.jobs
                        # 職どうしの兼ね合いを考慮
                        switch job
                            when "Psychic","RedHood"
                                # 1人のとき霊能は意味ない
                                if countCategory("Werewolf")==1
                                    # 狼1人だと霊能が意味ない
                                    continue
                            when "Couple"
                                # 共有者はひとりだと寂しい
                                if joblist.Couple==0
                                    unless init "Couple","Human"
                                        #共有者が入る隙間はない
                                        continue
                            when "Noble"
                                # 貴族は奴隷がほしい
                                if joblist.Slave==0
                                    unless init "Slave","Human"
                                        continue
                            when "Slave"
                                if joblist.Noble==0
                                    unless init "Noble","Human"
                                        continue
                            when "OccultMania"
                                if joblist.Diviner==0 && Math.randoom()<0.5
                                    # 占い師いないと出現確率低い
                                    continue
                            when "QueenSpectator"
                                # 女王観戦者はガードがないと不安
                                if joblist.Guard==0 && joblist.Priest==0 && joblist.Trapper==0
                                    unless Math.random()<0.4 && init "Guard","Human"
                                        unless Math.random()<0.5 && init "Priest","Human"
                                            unless init "Trapper","Human"
                                                # 護衛がいない
                                                continue
                            when "Spy2"
                                # スパイIIは2人いるとかわいそうなので入れない
                                if joblist.Spy2>0
                                    continue
                            when "Lycan","SeersMama","Sorcerer","SeersMama","WolfBoy"
                                # 占い系がいないと入れない
                                if joblist.Diviner==0 && joblist.ApprenticeSeer==0 && joblist.PI==0
                                    continue
                            when "LoneWolf","FascinatingWolf","ToughWolf"
                                # 誘惑する女狼はほかに人狼がいないと効果発揮しない
                                # 一途な狼はほかに狼いないと微妙、一匹狼は1人だけででると狂人が絶望
                                if countCategory("Werewolf")==0
                                    continue

                    joblist[job]++
                    # ひとつ追加
                    if category?
                        joblist[category]--
                    else
                        frees--

                    if safety.teams && (job in Shared.game.teams.Werewolf)
                        wolf_teams++    # 人狼陣営が増えた
                if (joblist.Magician>0 || joblist.Cat>0 || joblist.Witch>0 || joblist.RedHood>0) && query.heavenview=="view"
                    # 魔術師いるのに
                    query.heavenview=null
                    log=
                        mode:"system"
                        comment:"蘇生役職が存在するので、天国から役職が見られなくなりました。"
                    splashlog game.id,game,log
                if query.yaminabe_hidejobs==""
                    # 役職は公開される
                    jobinfos=[]
                    for job,num of joblist
                        continue if num==0
                        jobinfos.push "#{Shared.game.getjobname job}#{num}"
                    log=
                        mode:"system"
                        comment:"出現役職: "+jobinfos.join(" ")
                    splashlog game.id,game,log
                else if query.yaminabe_hidejobs=="team"
                    # 陣営のみ公開
                    # 各陣営
                    teaminfos=[]
                    for team,obj of Shared.game.jobinfo
                        teamcount=0
                        for job,num of joblist
                            #出現役職チェック
                            continue if num==0
                            if obj[job]?
                                # この陣営だ
                                teamcount+=num
                        if teamcount>0
                            teaminfos.push "#{obj.name}#{teamcount}"    #陣営名

                    log=
                        mode:"system"
                        comment:"出現陣営情報: "+teaminfos.join(" ")
                    splashlog game.id,game,log



            else if query.jobrule=="特殊ルール.量子人狼"
                # 量子人狼のときは全員量子人間だけど役職はある
                func=Shared.game.getrulefunc "内部利用.量子人狼"
                joblist=func frees
                sum=0
                for job of jobs
                    if joblist[job]
                        sum+=joblist[job]
                joblist.Human=frees-sum # 残りは村人だ!
                list_for_rule = JSON.parse JSON.stringify joblist
                ruleobj.quantum_joblist=joblist
                # 人狼の順位を決めていく
                i=1
                while joblist.Werewolf>0
                    joblist["Werewolf#{i}"]=1
                    joblist.Werewolf-=1
                    i+=1
                delete joblist.Werewolf
                # 量子人狼用
                joblist={
                    QuantumPlayer:frees
                }
                for job of jobs
                    unless joblist[job]?
                        joblist[job]=0
                ruleinfo_str=Shared.game.getrulestr query.jobrule,list_for_rule
                

            else if query.jobrule!="特殊ルール.自由配役"
                # 配役に従ってアレする
                func=Shared.game.getrulefunc query.jobrule
                unless func
                    res "不明な配役です"
                    return
                joblist=func frees
                sum=0   # 穴を埋めつつ合計数える
                for job of jobs
                    unless joblist[job]?
                        joblist[job]=0
                    else
                        sum+=joblist[job]
                # カテゴリも
                for type of Shared.game.categoryNames
                    if joblist["category_#{type}"]>0
                        sum-=parseInt joblist["category_#{type}"]
                joblist.Human=frees-sum # 残りは村人だ!
                ruleinfo_str=Shared.game.getrulestr query.jobrule,joblist
                
            log=
                mode:"system"
                comment:"配役: #{ruleinfo_str}"
            splashlog game.id,game,log
            
            
            for x in ["jobrule",
            "decider","authority","scapegoat","will","wolfsound","couplesound","heavenview",
            "wolfattack","guardmyself","votemyself","deadfox","deathnote","divineresult","psychicresult","waitingnight",
            "safety","friendsjudge","noticebitten","voteresult","GMpsychic","wolfminion","drunk","losemode","gjmessage","rolerequest",
            "quantumwerewolf_table","quantumwerewolf_diviner","yaminabe_safety"]
            
                ruleobj[x]=query[x] ? null

            game.setrule ruleobj
            # 配役リストをセット
            game.joblist=joblist
            game.startoptions=options
            game.startplayers=players
            game.startsupporters=supporters
            
            if ruleobj.rolerequest=="on" && !(query.jobrule in ["特殊ルール.闇鍋","特殊ルール.一部闇鍋","特殊ルール.量子人狼"])
                # 希望役職制あり
                # とりあえず入れなくする
                M.rooms.update {id:roomid},{$set:{mode:"playing"}}
                # 役職選択中
                game.rolerequestingphase=true
                # ここ書いてないよ!
                game.rolerequesttable={}
                res null
                log=
                    mode:"system"
                    comment:"このゲームは希望役職制です。希望の役職を選択して下さい。"
                splashlog game.id,game,log
                game.timer()
                ss.publish.channel "room#{roomid}","refresh",{id:roomid}
            else
                game.setplayers (result)->
                    unless result?
                        # プレイヤー初期化に成功
                        M.rooms.update {id:roomid},{$set:{mode:"playing"}}
                        game.nextturn()
                        res null
                        ss.publish.channel "room#{roomid}","refresh",{id:roomid}
                    else
                        res result
    # 情報を開示
    getlog:(roomid)->
        game=games[roomid]
        ne= =>
            # ゲーム後の行動
            player=game.getPlayerReal req.session.userId
            result=
                #logs:game.logs.filter (x)-> islogOK game,player,x
                logs:game.makelogs player
            result=makejobinfo game,player,result
            result.timer=if game.timerid?
                game.timer_remain-(Date.now()/1000-game.timer_start)    # 全体 - 経過時間
            else
                null
            result.timer_mode=game.timer_mode
            if game.day==0
                # 開始前はプレイヤー情報配信しない
                delete result.game.players
            res result
        if game?
            ne()
        else
            # DBから読もうとする
            M.games.findOne {id:roomid}, (err,doc)=>
                if err?
                    console.log err
                    throw err
                unless doc?
                    res {error:"そのゲームは存在しません"}
                    return
                games[roomid]=game=Game.unserialize doc,ss
                ne()
            return
        
    speak: (roomid,query)->
        game=games[roomid]
        unless game?
            res "そのゲームは存在しません"
            return
        unless req.session.userId
            res "ログインして下さい"
            return
        unless query?
            res "不正な操作です"
            return
        comment=query.comment
        unless comment
            res "コメントがありません"
            return
        player=game.getPlayerReal req.session.userId
        #console.log query,player
        log =
            comment:comment
            userid:req.session.userId
            name:player?.name ? req.session.user.name
            to:null
        if query.size in ["big","small"]
            log.size=query.size
        # ログを流す
        dosp=->
            
            if !game.finished  && game.voting   # 投票猶予時間は発言できない
                if player && !player.dead && !player.isJobType("GameMaster")
                    return  #まだ死んでいないプレイヤーの場合は発言できないよ!
            if game.day<=0 || game.finished #準備中
                unless log.mode=="audience"
                    log.mode="prepare"
                if player?.isJobType "GameMaster"
                    log.mode="gm"
                    #log.name="ゲームマスター"
            else
                # ゲームしている
                unless player?
                    # 観戦者
                    log.mode="audience"
                        
                else if player.dead
                    # 天国
                    if player.type=="Spy" && player.flag=="spygone"
                        # スパイなら会話に参加できない
                        log.mode="monologue"
                        log.to=player.id
                    else
                        log.mode="heaven"
                else if !game.night
                    # 昼
                    unless query.mode in player.getSpeakChoiceDay game
                        return
                    log.mode=query.mode
                    if game.silentexpires && game.silentexpires>=Date.now()
                        # まだ発言できない（15秒ルール）
                        return
                    
                else
                    # 夜
                    unless query.mode in player.getSpeakChoice game
                        query.mode="monologue"
                    log.mode=query.mode

            switch log.mode
                when "monologue"
                    log.to=player.id
                when "gm"
                    log.name="ゲームマスター"
                when "gmheaven"
                    log.name="GM→霊界"
                when "gmaudience"
                    log.name="GM→観客"
                when "gmmonologue"
                    log.name="GMの独り言"
                when "prepare"
                    # ごちゃごちゃ言わない
                else
                    if result=query.mode?.match /^gmreply_(.+)$/
                        log.mode="gmreply"
                        pl=game.getPlayer result[1]
                        unless pl?
                            return
                        log.to=pl.id
                        log.name="GM→#{pl.name}"
                    else if result=query.mode?.match /^helperwhisper_(.+)$/
                        log.mode="helperwhisper"
                        log.to=result[1]

            splashlog roomid,game,log
            res null
        if player?
            log.name=player.name
            log.userid=player.id
            dosp()
        else
            # ルーム情報から探す
            Server.game.rooms.oneRoomS roomid,(room)=>
                pl=room.players.filter((x)=>x.realid==req.session.userId)[0]
                if pl?
                    log.name=pl.name
                else
                    log.mode="audience"
                dosp()
    # 夜の仕事・投票
    job:(roomid,query)->
        game=games[roomid]
        unless game?
            res {error:"そのゲームは存在しません"}
            return
        unless req.session.userId
            res {error:"ログインして下さい"}
            return
        player=game.getPlayerReal req.session.userId
        unless player?
            res {error:"参加していません"}
            return
        unless player in game.participants
            res {error:"参加していません"}
            return
        if player.dead
            res {error:"お前は既に死んでいる"}
            return
        jt=player.getjob_target()
        sl=player.makeJobSelection game
        ###
        if !(to=game.players.filter((x)->x.id==query.target)[0]) && jt!=0
            res {error:"その対象は存在しません"}
            return
        if to?.dead && (!(jt & Player.JOB_T_DEAD) || !game.night) && (jt & Player.JOB_T_ALIVE)
            res {error:"対象は既に死んでいます"}
            return
        ###
        unless player.checkJobValidity game,query
            res {error:"対象選択が不正です"}
            return
        if game.night || query.jobtype!="_day"  # 昼の投票
            # 夜
            ###
            if !to?.dead && !(player.job_target & Player.JOB_T_ALIVE) && (player.job_target & Player.JOB_T_DEAD)
                res {error:"対象はまだ生きています"}
                return
            ###
            if player.jobdone(game)
                res {error:"既に能力を行使しています"}
                return
            unless player.isJobType query.jobtype
                res {error:"役職が違います"}
                return
            # エラーメッセージ
            if ret=player.job game,query.target,query
                console.log "err!",ret
                res {error:ret}
                return
            # 能力発動を記録
            game.addGamelog {
                id:player.id
                type:query.jobtype
                target:query.target
                event:"job"
            }
            
            # 能力をすべて発動したかどうかチェック
            #res {sleeping:player.jobdone(game)}
            res makejobinfo game,player
            if game.night || game.day==0
                game.checkjobs()
        else
            # 投票
            ###
            if @votingbox.isVoteFinished player
                res {error:"既に投票しています"}
                return
            if query.target==player.id && game.rule.votemyself!="ok"
                res {error:"自分には投票できません"}
                return
            to=game.getPlayer query.target
            unless to?
                res {error:"その人には投票できません"}
                return
            ###
            err=player.dovote game,query.target
            if err?
                res {error:err}
                return
            #player.dovote query.target
            # 投票が終わったかチェック
            game.addGamelog {
                id:player.id
                type:player.type
                target:query.target
                event:"vote"
            }
            res makejobinfo game,player
            game.execute()
    #遺言
    will:(roomid,will)->
        game=games[roomid]
        unless game?
            res "そのゲームは存在しません"
            return
        unless req.session.userId
            res "ログインして下さい"
            return
        unless !game.rule || game.rule.will
            res "遺言は使えません"
            return
        player=game.getPlayerReal req.session.userId
        unless player?
            res "参加していません"
            return
        if player.dead
            res "お前は既に死んでいる"
            return
        player.will=will
        res null
        

splashlog=(roomid,game,log)->
    log.time=Date.now() # 時間を付加
    game.logs.push log
    #DBに追加
    M.games.update {id:roomid},{$push:{logs:log}}
    flash=(log,rev=false)-> #rev: 逆な感じで配信
        # まず観戦者
        log.roomid=roomid
        au=islogOK game,null,log
        if (au&&!rev) || (!au&&rev)
            game.ss.publish.channel "room#{roomid}_audience","log",log
        # GM
        #if game.gm&&!rev
        #   game.ss.publish.channel "room#{roomid}_gamemaster","log",log
        # その他
        game.participants.forEach (pl)->
            p=islogOK game,pl,log
            if (p&&!rev) || (!p&&rev)
                game.ss.publish.user pl.realid,"log",log
    flash log
    
    # 他の人へ送る
    if log.mode=="werewolf" && game.rule.wolfsound=="aloud"
        # 狼の遠吠えが聞こえる
        otherslog=
            mode:"werewolf"
            comment:"アオォーーン・・・"
            name:"狼の遠吠え"
            time:log.time
        flash otherslog,true
    else if log.mode=="couple" && game.rule.couplesound=="aloud"
        # 共有者の小声が聞こえる
        otherslog=
            mode:"couple"
            comment:"ヒソヒソ・・・"
            name:"共有者の小声"
            time:log.time
        flash otherslog,true
    
    
            
    
    

# プレイヤーにログを見せてもよいか          
islogOK=(game,player,log)->
    # player: Player / null
    return true if game.finished    # 終了ならtrue
    return true if player?.isJobType "GameMaster"
    unless player?
        # 観戦者
        if log.mode in ["day","system","prepare","nextturn","audience","will","gm","gmaudience","probability_table"]
            !log.to?    # 観戦者にも公開
        else if log.mode=="voteresult"
            game.rule.voteresult!="hide"    # 投票結果公開なら公開
        else
            false   # その他は非公開
    else if log.mode=="gmmonologue"
        # GMの独り言はGMにしか見えない
        false
    else if player.dead && game.rule.heavenview=="view"
        true
    else if log.to? && log.to!=player.id
        # 個人宛
        if player.isJobType "Helper"
            log.to==player.flag # ヘルプ先のも見える
        else
            false
    else
        player.isListener game,log
#job情報を
makejobinfo = (game,player,result={})->
    result.type= if player? then player.getTypeDisp() else null
    # job情報表示するか
    actpl=player
    if player?
        if player instanceof Helper
            actpl=game.getPlayer player.flag
            unless actpl?
                #あれっ
                actpl=player
    openjob_flag=game.finished || (actpl?.dead && game.rule?.heavenview=="view") || actpl?.isJobType("GameMaster")

    result.game=game.publicinfo({openjob:openjob_flag})  # 終了か霊界（ルール設定あり）の場合は職情報公開
    result.id=game.id

    if player
        player.makejobinfo game,result
        result.dead=player.dead
        result.voteopen=false
        # 投票が終了したかどうか（フォーム表示するかどうか判断）
        if game.night || game.day==0
            result.sleeping=player.jobdone game
        else
            # 昼
            result.sleeping=true
            unless game.votingbox.isVoteFinished player
                # 投票ボックスオープン!!!
                result.voteopen=true
                result.sleeping=false
            if player.chooseJobDay game
                # 昼でも能力発動できる人
                result.sleeping &&= player.jobdone game

        #result.sleeping=if game.night then player.jobdone(game) else game.votingbox.isVoteFinished(player)
        if player.isJobType "Helper"
            result.sleeping=true    # 投票しない
        result.jobname=player.getJobDisp()
        result.winner=player.winner
        if game.night || game.day==0
            result.speak =player.getSpeakChoice game
        else
            result.speak =player.getSpeakChoiceDay game
        if game.rule?.will=="die"
            result.will=player.will

    result
    
# 配列シャッフル（破壊的）
shuffle= (arr)->
    ret=[]
    while arr.length
        ret.push arr.splice(Math.floor(Math.random()*arr.length),1)[0]
    ret
    
# ゲーム情報ツイート
tweet=(roomid,message)->
    Server.oauth.template roomid,message,Config.admin.password
        
