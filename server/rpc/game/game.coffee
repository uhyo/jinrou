#,type シェアするやつ
Shared=
    game:require '../../../client/code/shared/game.coffee'
    prize:require '../../../client/code/shared/prize.coffee'

libarray     = require '../../libs/array.coffee'
libblacklist = require '../../libs/blacklist.coffee'
libuserlogs  = require '../../libs/userlogs.coffee'
libsavelogs  = require '../../libs/savelogs.coffee'
libi18n      = require '../../libs/i18n.coffee'

cron=require 'cron'
i18n = libi18n.getWithDefaultNS "game"

# 身代わりセーフティありのときの除外役職一覧
SAFETY_EXCLUDED_JOBS = Shared.game.SAFETY_EXCLUDED_JOBS
# 冒涜者によって冒涜されない役職
BLASPHEMY_DEFENCE_JOBS = ["Fugitive","QueenSpectator","Liar","Spy2","LoneWolf"]


# フェイズの一覧
Phase =
    # 開始前
    preparing: 'preparing'
    # 希望役職制
    rolerequesting: 'rolerequesting'
    # 昼の議論時間
    day: 'day'
    # 昼の猶予
    day_remain: 'day_remain'
    # 昼の投票専用時間
    day_voting: 'day_voting'
    # 夜の議論時間
    night: 'night'
    # 夜の猶予
    night_remain: 'night_remain'
    # ハンター選択中
    hunter: 'hunter'
    # フェイズ判定メソッド
    isDay: (phase)-> phase in [Phase.day, Phase.day_remain, Phase.day_voting]
    isNight: (phase)-> phase in [Phase.night, Phase.night_remain]
    isRemain: (phase)-> phase in [Phase.day_remain, Phase.night_remain]

# Code of fortune result.
FortuneResult =
    # Human
    human: "human"
    # Werewolf
    werewolf: "werewolf"
    # Vampire
    vampire: "vampire"
    # pumpkin
    pumpkin: "pumpkin"

# Code of psychic result.
# Actual result may be string of array of string.
PsychicResult =
    # Human
    human: "human"
    # Werewolf
    werewolf: "werewolf"
    # BigWolf
    BigWolf: "BigWolf"
    # TinyFox
    TinyFox: "TinyFox"
    # priority of resutls in chemical.
    _chemicalPriority:
        human: 0
        werewolf: 1
        BigWolf: 2
        TinyFox: 2
    # function to combine two results in chemical.
    # filter out low priority results.
    combineChemical: (res1, res2)->
        # convert string result into array result.
        res1 = if "string" == typeof res1
            [res1]
        else
            res1
        res2 = if "string" == typeof res2
            [res2]
        else
            res2
        both = res1.concat res2
        maxPriority = Math.max both.map((res)-> PsychicResult._chemicalPriority[res])...
        filtered = both.filter (res)-> maxPriority == PsychicResult._chemicalPriority[res]
        result = libarray.sortedUnique filtered.sort()
        # If singleton, return as string.
        if result.length == 1
            result[0]
        else
            result
    # render psychic result to string.
    renderToString: (res, i18n)->
        # string is just rendered.
        if "string" == typeof res
            return i18n.t "roles:psychic.#{res}"
        # if array, join them using delimiter.
        delimiter = i18n.t "roles:psychic._delimiter"
        return res.map((r)-> i18n.t "roles:psychic.#{r}").join delimiter

# guard_logにおける襲撃の種類
AttackKind =
    werewolf: 'werewolf'
# 襲撃失敗理由
GuardReason =
    # 耐性
    tolerance: 'tolerance'
    # 護衛
    guard: 'guard'
    # 何者かが身代わりになる
    cover: 'cover'
    # 逃亡者
    absent: 'absent'
    # 悪魔の力
    devil: 'devil'
    # 呪いの力
    cursed: 'cursed'
    # 聖職者・巫女
    holy: 'holy'
    # 罠
    trap: 'trap'
# Type of open forms.
FormType =
    # 必須
    required: 'required'
    # 任意（毎晩使用可能）
    optional: 'optional'
    # 任意（1回のみ）
    optionalOnce: 'optionalOnce'


# 浅いコピー
copyObject=(obj)->
    result=Object.create Object.getPrototypeOf obj
    for key in Object.keys(obj)
        result[key]=obj[key]
    result

# ゲームオブジェクトを読み込む
loadGame = (roomid, ss, callback)->
    if games[roomid]?
        callback null, games[roomid]
    else
        M.games.findOne {id:roomid}, (err,doc)=>
            if err?
                console.error err
                callback err,null
            else if !doc?
                callback i18n.t("error.common.noSuchGame"),null
            else
                games[roomid] = Game.unserialize doc,ss
                callback null, games[roomid]
#内部用
module.exports=
    newGame: (room,ss, cb)->
        game=new Game ss,room
        games[room.id]=game
        M.games.insertOne game.serialize(), {w: 1}, cb
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
    # Check whether a new user can enter an endless game
    # maxnum: a maximum player number of this room
    endlessCanEnter:(roomid, userid, maxnum)->
        game = games[roomid]
        if game?
            # Check the number of existing players
            num = game.players.filter((x)->!x.dead || !x.norevive).length
            if num >= maxnum
                return false
            # Check whether a player already exists
            if game.participants.some((x)-> x.realid == userid)
                return false
            return true
        return false
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

        game = games[room.id]
        unless game && !game.participants.some((p)->p.realid==player.realid)
            return

        if room.mode=="waiting"
            # 開始前（ふつう）
            log=
                comment: i18n.t "system.rooms.enter", {name: name}
                userid:-1
                name:null
                mode:"system"
            if game
                splashlog room.id, game, log
                # プレイヤーを追加
                newpl=Player.factory "Waiting", game
                newpl.setProfile {
                    id:player.userid
                    realid:player.realid
                    name:player.name
                }
                newpl.setTarget null
                game.players.push newpl
                game.participants.push newpl
        else if room.mode=="playing" && room.jobrule=="特殊ルール.エンドレス闇鍋"
            # エンドレス闇鍋に途中参加
            if game
                log=
                    comment: i18n.t "system.rooms.entering", {name: name}
                    mode:"inlog"
                    to:player.userid
                splashlog room.id,game,log
                # プレイヤーを追加（まだ参加しない系のひと）
                newpl=Player.factory "Watching", game
                newpl.setProfile {
                    id:player.userid
                    realid:player.realid
                    name:player.name
                }
                newpl.setTarget null
                # アイコン追加
                game.iconcollection[newpl.id]=player.icon
                # playersには追加しない（翌朝追加）
                game.participants.push newpl
    outlog:(room,player)->
        log=
            comment: i18n.t "system.rooms.leave", {name: player.name}
            userid:-1
            name:null
            mode:"system"
        if games[room.id]
            splashlog room.id,games[room.id], log
            games[room.id].players=games[room.id].players.filter (pl)->pl.realid!=player.realid
            games[room.id].participants=games[room.id].participants.filter (pl)->pl.realid!=player.realid
    kicklog:(room,player)->
        log=
            comment: i18n.t "system.rooms.kicked", {name: player.name}
            userid:-1
            name:null
            mode:"system"
        if games[room.id]
            splashlog room.id,games[room.id], log
            games[room.id].players=games[room.id].players.filter (pl)->pl.realid!=player.realid
            games[room.id].participants=games[room.id].participants.filter (pl)->pl.realid!=player.realid
    helperlog:(ss,room,player,topl)->
        loadGame room.id, ss, (err,game)->
            log=null
            if topl?
                log=
                    comment: i18n.t "system.rooms.helper", {helper: player.name, target: topl.name}
                    userid:-1
                    name:null
                    mode:"system"
            else
                log=
                    comment: i18n.t "system.rooms.stophelper", {name: player.name}
                    userid:-1
                    name:null
                    mode:"system"

            if game?
                splashlog room.id,game, log
    deletedlog:(ss,room)->
        loadGame room.id, ss, (err,game)->
            if game?
                log=
                    comment: i18n.t "system.rooms.abandoned"
                    userid:-1
                    name:null
                    mode:"system"
                splashlog room.id,game, log
    # 状況に応じたチャンネルを割り当てる
    playerchannel:(ss,roomid,session)->
        loadGame roomid, ss, (err,game)->
            unless game?
                return
            player=game.getPlayerReal session.userId
            unless player?
                session.channel.subscribe "room#{roomid}_audience"
                #session.channel.subscribe "room#{roomid}_notwerewolf"
                #session.channel.subscribe "room#{roomid}_notcouple"
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
                if player.isJobType "Couple"
                    session.channel.subscribe "room#{roomid}_couple"
                else
                    session.channel.subscribe "room#{roomid}_notcouple"
            if player.isJobType "Fox"
                session.channel.subscribe "room#{roomid}_fox"
            ###
    suddenDeathPunish:(ss, roomid, voter, targets)->
        # voter: realid of voter
        # targets: userids of punishment targets
        game = games[roomid]
        unless game?
            return null
        # Get the punishment data for this game
        sdp = game.suddenDeathPunishment
        console.log "suddenDeathPunish", roomid, voter, targets, sdp
        unless sdp?
            return null
        # Am I a valid voter?
        unless sdp.voters[voter] == true
            return game.i18n.t "error.suddenDeathPunish.notvoter"
        # Are all the targets valid?
        unless targets.every((id)-> sdp.targets[id]?)
            return game.i18n.t "error.suddenDeathPunish.invalid"
        # 投票を実行
        sdp.voters[voter] = false

        for id in targets
            banpl = sdp.targets[id]
            query =
                userid:banpl.realid
                types:["create_account", "play"]
                reason: game.i18n.t "common.suddenDeathPenalty"
                banMinutes:sdp.banMinutes
            libblacklist.extendBlacklist query,(result)->
                ss.publish.channel "room#{roomid}", "punishresult", {id:roomid,name:banpl.name}
                # 即時反映
                ss.publish.user banpl.realid, "forcereload"
        return null

Server=
    game:
        game:module.exports
        rooms:require './rooms.coffee'
    prize:require '../../prize.coffee'
    oauth:require '../../oauth.coffee'
    log:require '../../log.coffee'

class Game
    constructor:(@ss,room)->
        @i18n = i18n

        # @ss: ss
        if room?
            @id=room.id
            # GMがいる場合
            @gm= if room.gm then room.owner.userid else null

        @players=[]         # 村人たち
        @participants=[]    # 参加者全て(@playersと同じ内容含む）
        @rule=null
        @finished=false #終了したかどうか
        @day=0  #何日目か(0=準備中)
        @phase = Phase.preparing

        @winner=null    # 勝ったチーム名
        @quantum_patterns=[]    # 全部の場合を列挙({(id):{jobtype:"Jobname",dead:Boolean},...})

        # ----- DBには現れないプロパティ -----
        @timerid=null
        @timer_start=null   # 残り時間のカウント開始時間（秒）
        @timer_remain=null  # 残り時間全体（秒）
        @timer_mode=null    # タイマーの名前
        @revote_num=0   # 再投票を行った回数
        @last_time=Date.now()   # 最後に動きがあった時間

        @werewolf_target=[] # 人狼の襲い先
        @werewolf_target_remain=0   #襲撃先をあと何人設定できるか
        @werewolf_flag=[] # 人狼襲撃に関するフラグ

        @revive_log = [] # 蘇生した人の記録
        @guard_log = []  # 襲撃阻止の記録（for 瞳狼）
        @ninja_data =

        @slientexpires=0    # 静かにしてろ！（この時間まで）
        @heavenview=false   # 霊界表示がどうなっているか

        @gamelogs=[]
        @iconcollection={}  #(id):(url)
        # 決定配役（DBに入らないかも・・・）
        @joblist=null
        # ゲームスタートに必要な情報
        @startoptions=null
        @startplayers=null
        @startsupporters=null

        # 希望役職制の選択一覧
        @rolerequesttable={}    # 一覧{(id):(jobtype)}

        # 投票箱を用意しておく
        @votingbox=new VotingBox this

        # New Year Messageのためだけの変数
        @currentyear = null

        # 保存用の時間
        @finish_time=null

        # ログ保存用のオブジェクト
        @logsaver = new libsavelogs.LogSaver this

        # 突然死の罰用のデータ
        @suddenDeathPunishment = null

        # ハンター割り込み処理用の次の処理フラグ
        @nextScene = null

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
            #logs:@logs
            rule:@rule
            players:@players.map (x)->x.serialize()
            # 差分
            additionalParticipants: @participants?.filter((x)=>@players.indexOf(x)<0).map (x)->x.serialize()
            finished:@finished
            day:@day
            phase:@phase
            winner:@winner
            jobscount:@jobscount
            gamelogs:@gamelogs
            gm:@gm
            iconcollection:@iconcollection
            werewolf_flag:@werewolf_flag
            werewolf_target:@werewolf_target
            werewolf_target_remain:@werewolf_target_remain
            #quantum_patterns:@quantum_patterns
            finish_time:@finish_time
        }
    #DB用をもとにコンストラクト
    @unserialize:(obj,ss)->
        game=new Game ss
        game.id=obj.id
        game.gm=obj.gm
        #game.logs=obj.logs
        game.rule=obj.rule
        game.players=obj.players.map (x)=>Player.unserialize x, game
        # 追加する
        if obj.additionalParticipants
            game.participants=game.players.concat obj.additionalParticipants.map (x)->Player.unserialize x, game
        else
            game.participants=game.players.concat []

        game.finished=obj.finished
        game.day=obj.day
        game.phase=obj.phase
        game.winner=obj.winner
        game.jobscount=obj.jobscount
        game.gamelogs=obj.gamelogs ? {}
        game.gm=obj.gm
        game.iconcollection=obj.iconcollection ? {}
        game.werewolf_flag=if Array.isArray obj.werewolf_flag
            # 配列ではなく文字列/nullだった時代のあれ
            obj.werewolf_flag
        else if obj.werewolf_flag?
            [obj.werewolf_flag]
        else
            []

        game.werewolf_target=obj.werewolf_target ? []
        game.werewolf_target_remain=obj.werewolf_target_remain ? 0
        # 開始前なら準備中を用意してあげないと！
        if game.day==0
            Server.game.rooms.oneRoomS game.id,(room)->
                if room.error?
                    return
                game.players=[]
                for plobj in room.players
                    newpl=Player.factory "Waiting", game
                    newpl.setProfile {
                        id:plobj.userid
                        realid:plobj.realid
                        name:plobj.name
                    }
                    newpl.setTarget null
                    game.players.push newpl
                game.participants=game.players.concat []

        game.quantum_patterns=obj.quantum_patterns ? []
        game.finish_time=obj.finish_time ? null
        unless game.finished
            if game.rule
                game.timer()
            if game.day>0 && Phase.isDay(game.phase)
                # 昼の場合投票箱をつくる
                game.votingbox.setCandidates game.players.filter (x)->!x.dead
            if game.phase == Phase.hunter
                # XXX hunterの場合あれを捏造
                game.nextScene = "nextturn"
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
                if obj?.gm || not (@rule?.blind=="complete" || (@rule?.blind=="yes" && !@finished))
                    # 公開してもよい
                    r.realid=x.realid
                r
            day:@day
            # for backward compatibility
            night:Phase.isNight(@phase)
            phase:@phase
            jobscount:@jobscount
        }
    # IDからプレイヤー
    getPlayer:(id)->
        @players.filter((x)->x.id==id)[0]
    getPlayerReal:(realid)->
        @participants.filter((x)->x.realid==realid)[0]
    # 指定したIDのプレイヤーを設定
    setPlayer:(id, pl)->
        for x, i in @players
            if x.id == id
                @players[i] = pl
        for x, i in @participants
            if x.id == id
                @participants[i] = pl
    # DBにセーブ
    save:->
        M.games.update {id:@id},{
            $set: @serialize()
            $setOnInsert: {
                logs: []
            }
        }
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
    # ゲーム開始時にプレイヤー数が合ってるかチェック
    checkPlayerNumber:()->
        joblist = @joblist
        # number of required jobs
        jallnum = @startplayers.length
        # 身代わり君を入れる
        if @rule.scapegoat == "on"
            jallnum++
        # ケミカル人狼は1人2つ
        if @rule.chemical == "on"
            jallnum *= 2
        # sum up all numbers
        jnumber = 0
        for job, num of joblist
            n = parseInt num, 10
            if Number.isNaN(n) || n < 0
                return @i18n.t "error.gamestart.playerNumberInvalid1", {job: job, num: num}
            jnumber += n
        if jnumber != jallnum
            return @i18n.t "error.gamestart.playerNumberInvalid2", {request: jnumber, jallnum: jallnum, players: @players.length}
        return null

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

        # 必要な役職の
        jallnum = plsl
        if @rule.chemical == "on"
            jallnum *= 2
        @players=[]
        @iconcollection={}
        for job,num of joblist
            unless isNaN num
                jnumber+=parseInt num
            if parseInt(num)<0
                res @i18n.t("error.gamestart.playerNumberInvalid1", {job: job, num: num})
                return

        if jnumber!=jallnum
            # 数が合わない
            res @i18n.t("error.gamestart.playerNumberInvalid2", {request: jnumber, jallnum: jallnum, players: players.length})
            return

        # 名前と数を出したやつ
        @jobscount={}
        unless options.yaminabe_hidejobs    # 公開モード
            for job,num of joblist
                continue unless num>0
                @jobscount[job]=
                    name: @i18n.t "roles:jobname.#{job}"
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
                    res @i18n.t "error.gamestart.thiefFailed"
                    return
                thief_jobs.push keys[0]
                joblist[keys[0]]--
                # 代わりに村人1つ入れる
                joblist.Human ?= 0
                joblist.Human++
        # 1人に対していくつ役職を選出するか
        jobperpl = 1
        if @rule.chemical == "on"
            jobperpl = 2

        # まず身代わりくんを決めてあげる
        if @rule.scapegoat=="on"
            # 人狼、妖狐にはならない
            nogoat=[]   #身代わりがならない役職
            if @rule.safety!="free"
                nogoat=nogoat.concat Shared.game.nonhumans  #人外は除く
            if @rule.safety=="full"
                # 危ない
                nogoat=nogoat.concat SAFETY_EXCLUDED_JOBS
            jobss=[]
            for job in Object.keys jobs
                continue if !joblist[job] || (job in nogoat)
                j=0
                while j<joblist[job]
                    jobss.push job
                    j++
            # 獲得した役職
            gotjs = []
            i=0 # 無限ループ防止
            while ++i<100 && gotjs.length < jobperpl
                r=Math.floor Math.random()*jobss.length
                continue unless joblist[jobss[r]]>0
                # 役職はjobss[r]
                gotjs.push jobss[r]
                joblist[jobss[r]]--
                j++

            if gotjs.length < jobperpl
                # 決まっていない
                res @i18n.t "error.gamestart.castingFailed"
                return
            # 身代わりくんのプロフィール
            profile = {
                id:"身代わりくん"
                realid:"身代わりくん"
                name: @i18n.t "common.scapegoat"
            }
            if @rule.chemical == "on"
                # ケミカル人狼なので合体役職にする
                pl1 = Player.factory gotjs[0], this
                pl1.setProfile profile
                pl1.scapegoat = true
                pl2 = Player.factory gotjs[1], this
                pl2.setProfile profile
                pl2.scapegoat = true
                # ケミカル合体
                newpl = Player.factory null, this, pl1, pl2, Chemical
                newpl.setProfile profile
                newpl.scapegoat = true
                newpl.setOriginalJobname newpl.getJobname()
                @players.push newpl
            else
                # ふつーに
                newpl=Player.factory gotjs[0], this   #身代わりくん
                newpl.setProfile profile
                newpl.scapegoat = true
                @players.push newpl

        if @rule.rolerequest=="on" && @rule.chemical != "on"
            # 希望役職制ありの場合はまず希望を優先してあげる
            # （ケミカル人狼のときは面倒なのでパス）
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
                    newpl=Player.factory job, this
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


        # 各プレイヤーの獲得役職の一覧
        gotjs = []
        for i in [0...(players.length)]
            gotjs.push []
        # 人狼系と妖狐系を全て数える（やや適当）
        all_wolves = 0
        all_foxes = 0
        for job,num of joblist
            unless isNaN num
                if job in Shared.game.categories.Werewolf
                    all_wolves += num
                if job in Shared.game.categories.Fox
                    all_foxes += num
        # 無限ループ防止用カウンタ
        loop_count = 0
        for job,num of joblist
            i=0
            while i++<num
                r=Math.floor Math.random()*players.length
                if @rule.chemical == "on" && gotjs[r].length == 1
                    # ケミカル人狼の場合調整が入る
                    if all_wolves == 1
                        # 人狼が1人のときは人狼を消さない
                        if (gotjs[r][0] in Shared.game.categories.Werewolf && job in Shared.game.categories.Fox) || (gotjs[r][0] in Shared.game.categories.Fox && job in Shared.game.categories.Werewolf)
                           # 人狼×妖狐はまずい
                           i--
                           if loop_count++ >= 100
                               # 配役失敗
                               res @i18n.t "error.gamestart.castingFailed"
                               return
                           continue
                gotjs[r].push job
                if gotjs[r].length >= jobperpl
                    # 必要な役職を獲得した
                    pl=players[r]
                    profile = {
                        id:pl.userid
                        realid:pl.realid
                        name:pl.name
                    }
                    if @rule.chemical == "on"
                        # ケミカル人狼
                        pl1 = Player.factory gotjs[r][0], this
                        pl1.setProfile profile
                        pl2 = Player.factory gotjs[r][1], this
                        pl2.setProfile profile
                        newpl = Player.factory null, this, pl1, pl2, Chemical
                        newpl.setProfile profile
                        newpl.setOriginalJobname newpl.getJobname()
                        @players.push newpl
                    else
                        # ふつうの人狼
                        newpl=Player.factory gotjs[r][0], this
                        newpl.setProfile profile
                        @players.push newpl
                    players.splice r,1
                    gotjs.splice r,1
                    if pl.icon
                        @iconcollection[newpl.id]=pl.icon
                    if pl.scapegoat
                        # 身代わりくん
                        newpl.scapegoat=true
        if joblist.Thief>0
            # 盗人がいる場合
            thieves=@players.filter (x)->x.isJobType "Thief"
            for pl in thieves
                pl.setFlag JSON.stringify thief_jobs.splice 0,2

        # サブ系
        if options.decider
            # 決定者を作る
            r=Math.floor Math.random()*@players.length
            pl=@players[r]

            newpl=Player.factory null, this, pl,null,Decider   # 酔っ払い
            pl.transProfile newpl
            pl.transform @,newpl,true,true
        if options.authority
            # 権力者を作る
            r=Math.floor Math.random()*@players.length
            pl=@players[r]

            newpl=Player.factory null, this, pl,null,Authority # 酔っ払い
            pl.transProfile newpl
            pl.transform @,newpl,true,true

        if @rule.wolfminion
            # 狼の子分がいる場合、子分決定者を作る
            wolves=@players.filter((x)->x.isWerewolf())
            if wolves.length>0
                r=Math.floor Math.random()*wolves.length
                pl=wolves[r]

                sub=Player.factory "MinionSelector", this # 子分決定者
                pl.transProfile sub

                newpl=Player.factory null, this, pl, sub, Complex
                pl.transProfile newpl
                pl.transform @,newpl,true
        if @rule.drunk
            # 酔っ払いがいる場合
            nonvillagers= @players.filter (x)->!x.isJobType "Human"

            if nonvillagers.length>0

                r=Math.floor Math.random()*nonvillagers.length
                pl=nonvillagers[r]

                newpl=Player.factory null, this, pl,null,Drunk # 酔っ払い
                pl.transProfile newpl
                pl.transform @,newpl,true,true


        # プレイヤーシャッフル
        @players=shuffle @players
        @participants=@players.concat []    # コピー
        # ここでプレイヤー以外の処理をする
        for pl in supporters
            if pl.mode=="gm"
                # ゲームマスターだ
                gm=Player.factory "GameMaster", this
                gm.setProfile {
                    id:pl.userid
                    realid:pl.realid
                    name:pl.name
                }
                @participants.push gm
            else if result=pl.mode?.match /^helper_(.+)$/
                # ヘルパーだ
                ppl=@players.filter((x)->x.id==result[1])[0]
                unless ppl?
                    # This is a bug!
                    res @i18n.t "error.gamestart.helperNotExist", {name: pl.name}
                    return
                helper=Player.factory "Helper", this
                helper.setProfile {
                    id:pl.realid
                    realid:pl.realid
                    name:pl.name
                }
                helper.setFlag ppl.id  # ヘルプ先
                @participants.push helper

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
                    pl.setFlag JSON.stringify {
                        number:i+1
                    }

        res null
#======== ゲーム進行の処理
    # 護衛ログを追加
    # guardedid: 守られた人のID
    # attack: 襲撃の種類
    # reason: 襲撃失敗理由
    addGuardLog:(guardedid, attack, reason)->
        @guard_log.push {
            guardedid: guardedid
            attack: attack
            reason: reason
        }
    #次のターンに進む
    nextturn:->
        clearTimeout @timerid
        if @day<=0
            # はじまる前
            @day=1
            @phase = Phase.night
            # ゲーム開始時の年を記録
            @currentyear = (new Date).getFullYear()
        else if Phase.isNight(@phase)
            @day++
            @phase = Phase.day
        else
            @phase = Phase.night

        night = Phase.isNight @phase

        if @phase == Phase.day && @currentyear+1 == (new Date).getFullYear()
            # 新年メッセージ
            @currentyear++
            log=
                mode:"nextturn"
                day:@day
                night:night
                userid:-1
                name:null
                comment: @i18n.t "system.phase.newyear", {year: @currentyear}
            splashlog @id,this,log
        else
            # 普通メッセージ
            log=
                mode:"nextturn"
                day:@day
                night:night
                userid:-1
                name:null
                comment: @i18n.t "system.phase.#{if night then 'night' else 'day'}", {day: @day}
            splashlog @id,this,log

        #死体処理
        @bury(if night then "night" else "day")

        return if @rule.hunter_lastattack == "no" && @judge()
        unless @hunterCheck "day"
            # ハンターフェイズの割り込みがなければターン開始

            @beginturn()

    beginturn:->
        night = Phase.isNight @phase

        if @rule.jobrule=="特殊ルール.量子人狼"
            # 量子人狼
            # 全員の確率を出してあげるよーーーーー
            # 確率テーブルを
            probability_table={}
            numberref_table={}
            dead_flg=true
            while dead_flg
                dead_flg=false
                for x in @players
                    if x.dead
                        continue
                    dead=0
                    for obj in @quantum_patterns
                        if obj[x.id].dead==true
                            dead++
                    if dead==@quantum_patterns.length
                        # 死んだ!!!!!!!!!!!!!!!!!
                        x.die this,"werewolf"
                        dead_flg=true
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
                    x.setFlag JSON.stringify {
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
                    }
                    if @rule.quantumwerewolf_dead=="on"
                        #死亡確率も
                        probability_table[x.id].dead=0
                    if @rule.quantumwerewolf_diviner=="on"
                        # 占い師の確率も
                        probability_table[x.id].Diviner=0
                else
                    x.setFlag JSON.stringify {
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
                        }
                    else
                        probability_table[x.id]={
                            name:x.name
                            Human:(count.Human+count.Diviner)/sum
                            Werewolf:count.Werewolf/sum
                        }
                    if @rule.quantumwerewolf_dead!="no" || count.dead==sum
                        # 死亡率も
                        probability_table[x.id].dead=count.dead/sum
                if @rule.quantumwerewolf_table=="anonymous"
                    # 番号を表示
                    numberref_table[pflag.number]=x
                    probability_table[x.id].name= @i18n.t "quantum.player", {num: pflag.number}
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
            @bury(if night then "night" else "day")

            return if @judge()

        if night
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
                @werewolf_target_remain=0
            else
                # 誰も襲わない
                @werewolf_target_remain=0

            werewolf_flag_result=[]
            for fl in @werewolf_flag
                if fl=="Diseased"
                    # 病人フラグが立っている（今日は襲撃できない
                    @werewolf_target_remain=0
                    log=
                        mode:"wolfskill"
                        comment: @i18n.t "system.werewolf.diseased"
                    splashlog @id,this,log
                else if fl=="WolfCub"
                    # 狼の子フラグが立っている（2回襲撃できる）
                    @werewolf_target_remain=2
                    log=
                        mode:"wolfskill"
                        comment: @i18n.t "system.werewolf.wolfcub"
                    splashlog @id,this,log
                else
                    werewolf_flag_result.push fl
            @werewolf_flag=werewolf_flag_result
            @checkWerewolfTarget()

            # Fireworks should be lit at just before sunset.
            x = @players.filter((pl)->pl.isJobType("Pyrotechnist") && pl.accessByJobType("Pyrotechnist")?.flag == "using")
            if x.length
                # Pyrotechnist should break the blockade of Threatened.sunset
                # Show a fireworks log.
                log=
                    mode:"system"
                    comment: @i18n.t "roles:Pyrotechnist.affect"
                splashlog @id, this, log
                # complete job of Pyrotechnist.
                for pyr in x
                    pyr.accessByJobType("Pyrotechnist").setFlag "done"
                # 全员花火の虜にしてしまう
                for pl in @players
                    newpl=Player.factory null, this, pl,null,WatchingFireworks
                    pl.transProfile newpl
                    newpl.cmplFlag=x[0].id
                    pl.transform this,newpl,true

            alives=[]
            deads=[]
            for player in @players
                if player.dead
                    deads.push player.id
                else
                    alives.push player.id
            for i in (shuffle [0...(@players.length)])
                player=@players[i]
                if player.id in alives
                    player.sunset this
                else
                    player.deadsunset this

            #sunset後の死体処理
            @bury "other"
            return if @judge()

            # 忍者のデータを作る
            @ninja_data = {}
            for player in @players
                unless player.dead
                    # 夜に行動していたらtrue
                    @ninja_data[player.id] = !player.jobdone(this)

                    if @rule.scapegoat=="on" && @day==1 && player.isWerewolf() && player.isAttacker()
                        # 身代わり襲撃は例外的にtrue
                        @ninja_data[player.id] = true
        else
            # 誤爆防止
            @werewolf_target_remain=0
            # 処理
            if @rule.deathnote
                # デスノート採用
                alives=@players.filter (x)->!x.dead
                if alives.length>0
                    r=Math.floor Math.random()*alives.length
                    pl=alives[r]
                    sub=Player.factory "Light", this  # 副を作る
                    pl.transProfile sub
                    sub.setFlag "onenight"
                    sub.sunset this
                    newpl=Player.factory null, this, pl,sub,Complex
                    pl.transProfile newpl
                    pl.transform this, newpl, true
            # エンドレス闇鍋用途中参加処理
            if @rule.jobrule=="特殊ルール.エンドレス闇鍋"
                exceptions=["MinionSelector","Thief","GameMaster","Helper","QuantumPlayer","Waiting","Watching","GotChocolate"]
                jobnames=Object.keys(jobs).filter (name)->!(name in exceptions)
                pcs=@participants.concat []
                join_count=0
                for player in pcs
                    if player.isJobType "Watching"
                        # 参加待機のひとだ
                        if !@players.some((p)->p.realid==player.realid)
                            # 本参加ではないのでOK
                            # 役職をランダムに決定
                            newjob=jobnames[Math.floor Math.random()*jobnames.length]
                            newpl=Player.factory newjob, this
                            player.transProfile newpl
                            player.transferData newpl
                            # 観戦者を除去
                            @participants=@participants.filter (x)->x!=player
                            # プレイヤーとして追加
                            @players.push newpl
                            @participants.push newpl
                            # ログをだす
                            log=
                                mode:"system"
                                comment: @i18n.t "system.rooms.join", {name: newpl.name}
                            splashlog @id,@,log
                            join_count++
                        else
                            @participants=@participants.filter (x)->x!=player
                # たまに転生
                deads=shuffle @players.filter (x)->x.dead && !x.norevive
                # 転生確率
                # 1人の転生確率をpとすると死者n人に対して転生人数の期待値はpn人。
                # 1ターンに2人しぬとしてp(n+2)=2とおくとp=2/(n+2) 。
                # 少し減らして人数を減少に持って行く
                p = 2/(deads.length+3)
                # 死者全員に対して転生判定
                for pl in deads
                    if Math.random()<p
                        # でも参加者がいたら蘇生のかわりに
                        if join_count>0 && Math.random()>p
                            join_count--
                            continue
                        newjob=jobnames[Math.floor Math.random()*jobnames.length]
                        newpl=Player.factory newjob, this
                        pl.transProfile newpl
                        pl.transferData newpl
                        # 蘇生
                        newpl.setDead false
                        pl.transform @,newpl,true
                        log=
                            mode:"system"
                            comment:@i18n.t "system.rooms.rebirth", {name: pl.name}
                        splashlog @id,@,log
                        @ss.publish.user newpl.id,"refresh",{id:@id}


            # 投票リセット処理
            # Votingbox should be initialized before sunrise()
            # because roles like TroubleMaker may modify it.
            @votingbox.init()
            alives=[]
            deads=[]
            for player in @players
                if player.dead
                    deads.push player.id
                else
                    alives.push player.id

            for i in (shuffle [0...(@players.length)])
                player=@players[i]
                if player.id in alives
                    player.sunrise this
                else
                    player.deadsunrise this

            # sunrise後の死体処理
            @bury "other"
            return if @judge()

            alives = @players.filter (x)->!x.dead

            @votingbox.setCandidates alives
            for pl in alives
                pl.votestart this
            @revote_num=0   # 再投票の回数は0にリセット

            # New year messageの処理
            end_date = new Date
            end_date.setTime(end_date.getTime() + @rule.day * 1000)
            if (new Date).getFullYear() == @currentyear && end_date.getFullYear() > @currentyear
                # 昼時間中に変わるので専用タイマー
                end_date.setMonth 0
                end_date.setDate 1
                end_date.setHours 0
                end_date.setMinutes 0
                end_date.setSeconds 0
                end_date.setMilliseconds 0
                # debug
                # end_date.setTime(end_date.getTime() - 145*60*1000)
                current_day = @day
                setTimeout (()=>
                    if !@finished && @day == current_day && @phase in [Phase.day, Phase.day_remain, Phase.day_voting]
                        @currentyear++
                        log=
                            mode:"system"
                            comment: @i18n.t "system.phase.newyear", {year: @currentyear}
                        splashlog @id,this,log
                ), end_date.getTime() - Date.now()

        @splashjobinfo()
        if night
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
        if @phase == Phase.rolerequesting
            # 開始前（希望役職制）
            if timeout || @players.every((x)=>@rolerequesttable[x.id]?)
                # 全員できたぞ
                @setplayers (result)=>
                    unless result?
                        @nextturn()
                        @ss.publish.channel "room#{@id}","refresh",{id:@id}
                true
            else
                false
        else if Phase.isNight(@phase)
            @players.forEach (pl)=>
                if pl.scapegoat && !pl.dead && !pl.sleeping(@)
                    pl.sunset(@)
            # 夜時間
            if @players.every( (x)=>x.dead || x.sleeping(@))
                # 全員寝たが……
                if Phase.isRemain(@phase) || timeout || !@rule.night || @rule.waitingnight!="wait" #夜に時間がある場合は待ってあげる
                    @midnight()
                    @nextturn()
                    true
                else
                    false
            else
                false
        else if @phase == Phase.hunter
            # ハンターの時間だ
            for pl in @players
                hunters = [
                    pl.accessByJobTypeAll("Hunter")...,
                    pl.accessByJobTypeAll("MadHunter")...,
                ]
                if hunters.some((x)-> x.flag == "hunting" && !x.target?)
                    # まだ選択していないハンターだ
                    return false
            @hunterDo()
            true
        else
            false

    #夜の能力を処理する
    midnight:->
        alives=[]
        deads=[]
        pids=[]
        mids=[]
        for player in @players
            pids.push player.id
            # gather all midnightSort
            mids = mids.concat player.gatherMidnightSort()
            if player.dead
                deads.push player.id
            else
                alives.push player.id
        # unique
        mids.sort (a, b)=>
            return a - b
        midsu=[mids[0]]
        for mid in mids
            if midsu[midsu.length-1] != mid then midsu.push mid
        # 処理順はmidnightSortでソート
        pids = shuffle pids
        for mid in midsu
            for pid in pids
                player=@getPlayer pid
                pmids = player.gatherMidnightSort()
                if player.id in alives
                    if mid in pmids
                        player.midnight this,mid
                else
                    if mid in pmids
                        player.deadnight this,mid

        # 狼の処理
        for target in @werewolf_target
            t=@getPlayer target.to
            continue unless t?
            # 噛まれた
            t.addGamelog this,"bitten"
            if @rule.noticebitten=="notice"
                log=
                    mode:"skill"
                    to:t.id
                    comment: @i18n.t "system.werewolf.attacked", {name: t.name}
                splashlog @id,this,log
            if !t.dead
                # 死んだ
                t.die this,"werewolf",target.from
            # 逃亡者を探す
            for x in @players
                if x.dead
                    continue
                runners = x.accessByJobTypeAll "Fugitive"
                for pl in runners
                    if pl.target == target.to
                        x.die this, "werewolf2", target.from

            if !t.dead
                # 死んでない
                flg_flg=false  # なにかのフラグ
                for fl in @werewolf_flag
                    res = fl.match /^ToughWolf_(.+)$/
                    if res?
                        # 一途な狼がすごい
                        tw = @getPlayer res[1]
                        t=@getPlayer target.to
                        if t?
                            t.setDead true,"werewolf2"
                            t.dying this,"werewolf2",tw.id
                            flg_flg=true
                            if tw?
                                unless tw.dead
                                    tw.die this,"werewolf2"
                                    tw.addGamelog this,"toughwolfKilled",t.type,t.id
                            break
                unless flg_flg
                    # 一途は発動しなかった
                    for fl in @werewolf_flag
                        res = fl.match /^GreedyWolf_(.+)$/
                        if res?
                            # 欲張り狼がやられた!
                            gw = @getPlayer res[1]
                            if gw?
                                gw.die this,"werewolf2"
                                gw.addGamelog this,"greedyKilled",t.type,t.id
                                # 以降は襲撃できない
                                flg_flg=true
                                break
                    if flg_flg
                        # 欲張りのあれで襲撃終了
                        break
        @werewolf_flag=@werewolf_flag.filter (fl)->
            # こいつらは1夜限り
            return !(/^(?:GreedyWolf|ToughWolf)_/.test fl)

    # 死んだ人を処理する type: タイミング
    # type:
    #   "day": 夜が明けたタイミング
    #   "punish": 処刑後
    #   "night": 夜になったタイミング
    #   "other":その他(ターン変わり時の能力で死んだやつなど）
    bury:(type)->
        # 瞳狼が生存しているフラグ
        eyes_flag = @players.some (x)-> !x.dead && x.isJobType("EyesWolf")

        if eyes_flag
            # 瞳狼用のログを表示
            for obj in @guard_log
                if obj.attack == AttackKind.werewolf
                    target = @getPlayer obj.guardedid
                    if target?
                        log =
                            mode:"eyeswolfskill"
                            comment: @i18n.t "roles:EyesWolf.result.#{obj.reason}", {name: target.name}
                        splashlog @id, this, log
        @guard_log = []


        deads=[]
        loop
            newdeads=@players.filter (x)->
                x.dead && x.found && deads.every((y)-> x.id != y.id)
            deads.push newdeads...

            alives=@players.filter (x)->!x.dead
            alives.forEach (x)=>
                x.beforebury this,type,newdeads
            newdeads=@players.filter (x)->
                x.dead && x.found && deads.every((y)-> x.id != y.id)
            if newdeads.length == 0
                # もう新しく死んだ人はいない
                break
        # 生存している閻魔の一覧
        emma_alive = @players.filter (x)-> !x.dead && x.isJobType("Emma")
        # 霊界で役職表示してよいかどうか更新
        switch @rule.heavenview
            when "view"
                @heavenview=true
            when "norevive"
                @heavenview=!@players.some((x)->x.isReviver())
            else
                @heavenview=false
        deads=shuffle deads # 順番バラバラ
        deads.forEach (x)=>
            situation=switch x.found
                #死因
                when "werewolf","werewolf2","poison","hinamizawa","vampire","vampire2","witch","dog","trap","marycurse","psycho","crafty"
                    @i18n.t "found.normal", {name: x.name}
                when "curse"    # 呪殺
                    if @rule.deadfox=="obvious"
                        @i18n.t "found.curse", {name: x.name}
                    else
                        @i18n.t "found.normal", {name: x.name}
                when "punish"
                    @i18n.t "found.punish", {name: x.name}
                when "spygone"
                    @i18n.t "found.leave", {name: x.name}
                when "deathnote"
                    @i18n.t "found.body", {name: x.name}
                when "foxsuicide", "friendsuicide", "twinsuicide"
                    @i18n.t "found.suicide", {name: x.name}
                when "infirm"
                    @i18n.t "found.infirm", {name: x.name}
                when "hunter"
                    @i18n.t "found.hunter", {name: x.name}
                when "gmpunish"
                    @i18n.t "found.gm", {name: x.name}
                when "gone-day"
                    @i18n.t "found.goneDay", {name: x.name}
                when "gone-night"
                    @i18n.t "found.goneNight", {name: x.name}
                else
                    @i18n.t "found.fallback", {name: x.name}
            log=
                mode:"system"
                comment:situation
            splashlog @id,this,log
            if emma_alive.length > 0
                # 閻魔用のログも出す
                emma_log=switch x.found
                    when "werewolf","werewolf2","crafty"
                        "werewolf"
                    when "poison","witch"
                        "poison"
                    when "hinamizawa"
                        "hinamizawa"
                    when "vampire","vampire2"
                        "vampire"
                    when "dog"
                        "dog"
                    when "trap"
                        "trap"
                    when "marycurse"
                        "curse"
                    when "psycho"
                        "psycho"
                    when "curse"
                        if @rule.deadfox=="obvious"
                            null
                        else
                            "curse"
                    when "foxsuicide"
                        "foxsuicide"
                    when "friendsuicide"
                        "friendsuicide"
                    when "twinsuicide"
                        "twinsuicide"
                    else
                        null
                if emma_log?
                    # emma log is delivered to alive emmas.
                    log=
                        mode:"emmaskill"
                        comment: @i18n.t "roles:Emma.result.#{emma_log}", {name: x.name}
                        to: emma_alive.map (pl)-> pl.id
                    splashlog @id,this,log

            @addGamelog {   # 死んだときと死因を記録
                id:x.id
                type:x.type
                event:"found"
                flag:x.found
            }
            x.setDead x.dead,"" #発見されました
            @ss.publish.user x.realid,"refresh",{id:@id}
            if @rule.will=="die" && x.will
                # 死んだら遺言発表
                log=
                    mode:"will"
                    name:x.name
                    comment:x.will
                splashlog @id,this,log
        # 蘇生のログも表示
        if type != "punish"
            for n in @revive_log
                log=
                    mode: "system"
                    comment: @i18n.t "system.revive", {name: n}
                splashlog @id, this, log
            @revive_log = []
        return deads.length

    # 投票終わりチェック
    # 返り値: 処刑が終了したらtrue
    execute:->
        return false unless @votingbox.isVoteAllFinished()
        [mode,players,tos,table]=@votingbox.check()
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

        if mode=="runoff"
            # 再投票になった
            @dorevote "runoff"
            return false
        else if mode=="revote"
            # 再投票になった
            @dorevote "revote"
            return false
        else if mode=="none"
            # 処刑しない
            log=
                mode:"system"
                comment: @i18n.t "system.voting.nopunish"
            splashlog @id,this,log
            @nextturn()
            return true
        else if mode=="punish"
            # 投票
            # 結果が出た 死んだ!
            # だれが投票したか調べる
            for player in players
                follower=table.filter((obj)-> obj.voteto==player.id).map (obj)->obj.id
                player.die this,"punish",follower

                if player.dead && @rule.GMpsychic=="on"
                    # GM霊能
                    log=
                        mode:"system"
                        comment: @i18n.t "system.gmPsychic", {name: player.name, result: PsychicResult.renderToString player.getPsychicResult(), @i18n}
                    splashlog @id,this,log

            @votingbox.remains--
            if @votingbox.remains>0
                # もっと殺したい!!!!!!!!!
                @bury "other"
                return false if @rule.hunter_lastattack == "no" && @judge()

                unless @hunterCheck("vote")
                    return false if @rule.hunter_lastattack == "yes" && @judge()
                    @dorevote "onemore"
                return false
            # ターン移る前に死体処理
            @bury "punish"
            return true if @rule.hunter_lastcheck == "no" && @judge()
            # ハンターフェイズ割り込みがあるかもしれない
            unless @hunterCheck("nextturn")
                @nextturn()
            if @rule.hunter_lastcheck == "yes"
                @judge()
        return true
    # 再投票
    dorevote:(mode)->
        # mode:
        #   "runoff" - 決選投票による再投票
        #   "revote" - 同数による再投票
        #   "gone" - 突然死による再投票
        #   "onemore" - まだ処刑するひとがいる場合
        if mode in ["revote", "gone"]
            @revote_num++
        if @revote_num>=4   # 4回再投票
            @judge()
            return
        remains=4-@revote_num
        if mode=="runoff"
            log=
                mode:"system"
                comment: @i18n.t "system.voting.runoff"
        else if mode in ["revote", "gone"]
            log=
                mode:"system"
                comment: @i18n.t "system.voting.revote", {count: remains | 0}
        else if mode == "onemore"
            log=
                mode:"system"
                comment: @i18n.t "system.voting.more", {count: @votingbox.remains}
        if log?
            splashlog @id,this,log
        # 必要がある場合は候補者を再設定
        if mode != "runoff"
            @votingbox.setCandidates @players.filter ((x)->!x.dead)

        @votingbox.start()
        for player in @players
            unless player.dead
                player.votestart this
        @ss.publish.channel "room#{@id}","voteform",true
        @splashjobinfo()
        if @phase in [Phase.day_voting, Phase.day_remain]
            # 投票猶予の場合初期化
            clearTimeout @timerid
            @timer()
    # ハンターの能力による割り込みチェック
    # 戻り値: true (ハンターフェイズあり) / false (ハンターフェイズなし)
    # nextScene:
    #   "nextturn": 次のターンへ
    #   "day": 昼のターン開始処理
    #   "vote": 次の投票へ
    hunterCheck:(nextScene)->
        # まずハンターを列挙
        hunters = []
        for pl in @players
            hunters.push (pl.accessByJobTypeAll "Hunter")..., (pl.accessByJobTypeAll "MadHunter")...
        # 能力発動中のもののみ残す
        hunters = hunters.filter (x)-> x.flag == "hunting"
        if hunters.length == 0
            # 能力は発動しない
            return false
        clearTimeout @timerid
        # ハンターフェイズ突入！！！
        @nextScene = nextScene
        @phase = Phase.hunter
        # ユーザー名を列挙（重複除く）
        userTable = {}
        userNames = []
        for pl in hunters
            unless userTable[pl.id]
                userTable[pl.id] = true
                userNames.push pl.name
                # 権限の関係でいったん生存状態に戻す
                plpl = @getPlayer pl.id
                if plpl?
                    plpl.setDead false
        log=
            mode: "system"
            comment: @i18n.t "system.hunterPrepare", {names: userNames.join ', '}
        splashlog @id, this, log

        @splashjobinfo()
        @save()
        @timer()
        return true
    # ハンターの能力実行
    hunterDo:->
        clearTimeout @timerid
        hunters = []
        for pl in @players
            hunters.push (pl.accessByJobTypeAll "Hunter")..., (pl.accessByJobTypeAll "MadHunter")...
        diers = []
        for pl in hunters
            if pl.flag == "hunting"
                pl.setFlag null
                plpl = @getPlayer pl.id
                plpl?.setDead true, ""
                t =
                    if pl.target?
                        @getPlayer pl.target
                    else
                        # 仕方ないからランダムに設定
                        targets = pl.makeJobSelection this
                        if targets.length > 0
                            r = Math.floor(Math.random() * targets.length)
                            @getPlayer targets[r].value
                        else
                            null
                if t? && !t.dead
                    # ハンターの攻撃対象
                    diers.push t
        # ハンターのターゲットになった人は死ぬ！！！！！！！
        for t in diers
            if !t.dead
                t.die this, "hunter"


        @bury "other"
        return if @rule.hunter_lastattack == "no" && @judge()
        if @hunterCheck @nextScene
            return
        return if @rule.hunter_lastattack == "yes" && @judge()
        # 次のフェイズへ
        switch @nextScene
            when "nextturn"
                @nextturn()
            when "day"
                @phase = Phase.day
                @beginturn()
            when "vote"
                @phase = Phase.day_voting
                @dorevote "onemore"
            else
                console.error "unknown nextScene: #{@nextScene}"
    # check werewolf targets to stop werewolf attack
    # when no target is alive.
    checkWerewolfTarget:->
        if @werewolf_target_remain > 0
            # list up Werewolf-attackable player.
            targets = @players.filter (pl)=> !pl.dead && (!pl.isWerewolf() || @rule.werewolfattack=="ok")
            if targets.length == 0
                # no food is remaining!!!
                @werewolf_target_remain = 0

    # 勝敗決定
    judge:->
        aliveps=@players.filter (x)->!x.dead    # 生きている人を集める
        # 数える
        alives=aliveps.length
        humans=aliveps.map((x)->x.humanCount()).reduce(((a,b)->a+b), 0)
        wolves=aliveps.map((x)->x.werewolfCount()).reduce(((a,b)->a+b), 0)
        vampires=aliveps.map((x)->x.vampireCount()).reduce(((a,b)->a+b), 0)
        friendsn=aliveps.map((x)->x.isFriend()).reduce(((a,b)->a+b), 0)

        team=null
        friends_count=null

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
                    comment: @i18n.t "system.quantum.breakdown"
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
            else if alives==friendsn
                # 恋人勝利
                team="Friend"

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
                if @players.some((x)->x.isFriend())
                    # 終了時に恋人生存
                    friends=aliveps.filter (x)->x.isFriend()
                    gid=0
                    friends_count=0
                    friends_table={}
                    for pl in friends
                        pt=pl.getPartner()
                        unless friends_table[pl.id]?
                            unless friends_table[pt]?
                                # 新しいグループを発見
                                friends_count++
                                gid++
                                friends_table[pl.id]=gid
                                friends_table[pt]=gid
                            else
                                # 既存のグループに合流
                                friends_table[pl.id]=friends_table[pt]
                        else
                            unless friends_table[pt]?
                                friends_table[pt]=friends_table[pl.id]
                            else if friends_table[pt]!=friends_table[pl.id]
                                # 食い違っている
                                c=Math.min friends_table[pt],friends_table[pl.id]
                                d=Math.max friends_table[pt],friends_table[pl.id]
                                for key,value of friends_table
                                    if value==d
                                        friends_table[key]=c
                                # グループが合併した
                                friends_count--


                    if friends_count==1
                        # 1組しかいない
                        if @rule.friendsjudge=="alive"
                            team="Friend"
                        else if friends.length==alives
                            team="Friend"
                    else if friends_count>1
                        if alives==friendsn
                            team="Friend"
                        else if @rule.friendssplit=="split"
                            # 恋人バトル
                            team=null
            # カルト判定
            if alives>0 && aliveps.every((x)->x.isCult() || x.isJobType("CultLeader") && x.getTeam()=="Cult" )
                # 全員信者
                team="Cult"
            # 悪魔くん判定
            isDevilWinner = (pl)=>
                # 悪魔くんが勝利したか判定する
                return false unless pl?
                # check whether some of devils in pl produce winning flag.
                devils = pl.accessByJobTypeAll "Devil"
                winning_devils = devils.some (d)-> d.flag == "winner"
                return false unless winning_devils
                # but, if this player is not winning with Devil for some reason
                # (e.g., by Counselor), ignore his winningness.
                return pl.isWinner this, "Devil"
            if @players.some(isDevilWinner)
                team="Devil"

        if @revote_num>=4 && !team?
            # 再投票多すぎ
            team="Draw" # 引き分け

        if team?
            # 勝敗決定
            @finished=true
            @finish_time=new Date
            @last_time=@finish_time.getTime()
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
                        [@i18n.t("judge.neet"),@i18n.t("judge.short.human")]
                    else
                        [@i18n.t("judge.human"),@i18n.t("judge.short.human")]
                when "Werewolf"
                    [@i18n.t("judge.werewolf"),@i18n.t("judge.short.werewolf")]
                when "Fox"
                    [@i18n.t("judge.fox"),@i18n.t("judge.short.fox")]
                when "Devil"
                    [@i18n.t("judge.devil"),@i18n.t("judge.short.devil")]
                when "Friend"
                    if friends_count>1
                        # みんなで勝利（珍しい）
                        [@i18n.t("judge.friendsAll"),@i18n.t("judge.short.friends")]
                    else
                        friends=@players.filter (x)->x.isFriend()
                        if friends.length==2 && friends.some((x)->x.isJobType "Noble") && friends.some((x)->x.isJobType "Slave")
                            [@i18n.t("judge.friendsSpecial", {count: 2}),@i18n.t("judge.short.friends")]
                        else
                            [@i18n.t("judge.friendsNormal", {count: @players.filter((x)->x.isFriend() && !x.dead).length}),@i18n.t("judge.short.friends")]
                when "Cult"
                    [@i18n.t("judge.cult"),@i18n.t("judge.short.cult")]
                when "Vampire"
                    [@i18n.t("judge.vampire"),@i18n.t("judge.short.vampire")]
                when "LoneWolf"
                    [@i18n.t("judge.lonewolf"),@i18n.t("judge.short.lonewolf")]
                when "Draw"
                    [@i18n.t("judge.draw"),""]
            if teamstring
                log.comment = @i18n.t "system.judge", {short: teamstring, result: resultstring}
            else
                log.comment = resultstring
            splashlog @id,this,log


            # ルームを終了状態にする
            M.rooms.update {id:@id},{$set:{mode:"end"}}
            @ss.publish.channel "room#{@id}","refresh",{id:@id}
            clearTimeout @timerid
            @save()
            @saveUserRawLogs()
            @prize_check()

            # generate the list of Sudden Dead Player
            norevivers=@gamelogs.filter((x)->x.event=="found" && x.flag in ["gone-day","gone-night"]).map((x)->x.id)
            # handle miko-gone
            miko_gone=@gamelogs.filter((x)->x.event=="miko-gone").map((x)->x.id)
            miko_gone_counter = {}
            for miko in miko_gone
                if miko_gone_counter[miko] == undefined
                    miko_gone_counter[miko] = 1
                else
                    miko_gone_counter[miko]++
            for miko of miko_gone_counter
                if miko_gone_counter[miko] >= 3 and miko not in norevivers
                    norevivers.push miko

            if norevivers.length
                @suddenDeathPunishment =
                    targets: {}
                    voters: {}
                    voterCount: 0
                message =
                    id:@id
                    userlist:[]
                    time: 0
                for x in @players
                    if x.id != "身代わりくん"
                        if x.id in norevivers
                            @suddenDeathPunishment.targets[x.id] = {
                                realid: x.realid
                                name: x.name
                            }
                            message.userlist.push {
                                userid: x.id
                                name: x.name
                            }
                        else
                            @suddenDeathPunishment.voters[x.realid] = true
                            @suddenDeathPunishment.voterCount++
                # deternime banMinutes.
                if @suddenDeathPunishment.voterCount > 0
                    @suddenDeathPunishment.banMinutes = Math.floor(Config.rooms.suddenDeathBAN / @suddenDeathPunishment.voterCount)
                    message.time = @suddenDeathPunishment.banMinutes
                    @ss.publish.channel "room#{@id}",'punishalert',message
                else
                    @suddenDeathPunishment = null

            # DBからとってきて告知ツイート
            M.rooms.findOne {id:@id},(err,doc)=>
                return unless doc?
                tweet doc.id, @i18n.t("tweet.gameend", {
                    roomname: Server.oauth.sanitizeTweet doc.name
                    result: log.comment
                })

            return true
        else
            return false
    timer:(settime)->
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
        if @phase == Phase.rolerequesting
            # 希望役職制
            time=60
            mode=@i18n.t "phase.rolerequesting"
            func= =>
                # 強制開始
                @checkjobs true
        else if @phase == Phase.night
            # 夜
            time=@rule.night
            mode=@i18n.t "phase.night"
            return unless time
            func= =>
                # ね な い こ だ れ だ
                unless @checkjobs true
                    if @rule.remain
                        # 猶予時間があるよ
                        @phase = Phase.night_remain
                        @timer()
                    else
                        @players.forEach (x)=>
                            return if x.dead || x.sleeping(@)
                            x.die this,"gone-night" # 突然死
                            x.setNorevive true
                            # 突然死記録
                            M.users.update {userid:x.realid},{$push:{gone:@id}}
                        @bury("other")
                        @checkjobs true
                else
                    return
        else if @phase == Phase.night_remain
            # 夜の猶予
            time=@rule.remain
            mode=@i18n.t "phase.additional"
            func= =>
                # ね な い こ だ れ だ
                @players.forEach (x)=>
                    return if x.dead || x.sleeping(@)
                    x.die this,"gone-night" # 突然死
                    x.setNorevive true
                    # 突然死記録
                    M.users.update {userid:x.realid},{$push:{gone:@id}}
                @bury("other")
                @checkjobs true
        else if @phase == Phase.day
            # 昼
            time=@rule.day
            mode=@i18n.t "phase.day"
            return unless time
            func= =>
                unless @execute()
                    if @rule.voting
                        # 投票専用時間がある
                        @phase = Phase.day_voting
                        log=
                            mode:"system"
                            comment:@i18n.t "system.phase.debateEnd"
                        splashlog @id, this, log
                        # 投票箱が開くので通知
                        @splashjobinfo()
                        @timer()
                    else if @rule.remain
                        # 猶予があるよ
                        @phase = Phase.day_remain
                        log=
                            mode:"system"
                            comment:@i18n.t "system.phase.debateEnd"
                        splashlog @id,this,log
                        @timer()
                    else
                        # 突然死
                        revoting=false
                        for x in @players
                            if x.dead || x.voted(this,@votingbox)
                                continue
                            x.die this,"gone-day"
                            x.setNorevive true
                            revoting=true
                        @bury("other")
                        @judge()
                        if revoting
                            @dorevote "gone"
                        else
                            @execute()
                else
                    return
        else if @phase == Phase.day_voting
            # 投票専用時間
            time=@rule.voting || @rule.remain || 120
            mode=@i18n.t "phase.voting"
            return unless time
            func= =>
                unless @execute()
                    # まだ決まらない
                    if @rule.remain
                        # 猶予時間
                        @phase = Phase.day_remain
                        @timer()
                    else
                        # 突然死
                        revoting=false
                        for x in @players
                            if x.dead || x.voted(this, @votingbox)
                                continue
                            x.die this, "gone-day"
                            x.setNorevive true
                            revoting = true
                        @bury("other")
                        @judge()
                        if revoting
                            @dorevote "gone"
                        else
                            @execute()
                else
                    return

        else if @phase == Phase.day_remain
            # 猶予時間も過ぎたよ!
            time=@rule.remain
            mode=@i18n.t "phase.additional"
            func= =>
                unless @execute()
                    revoting=false
                    for x in @players
                        if x.dead || x.voted(this,@votingbox)
                            continue
                        x.die this,"gone-day"
                        x.setNorevive true
                        revoting=true
                    @bury("other")
                    @judge()
                    if revoting
                        @dorevote "gone"
                    else
                        @execute()
                else
                    return
        else if @phase == Phase.hunter
            # ハンター選択中
            time = 45 # it's hard-coded!
            mode = @i18n.t "phase.skill"
            func = =>
                @hunterDo()
        else
            console.error "unknown phase #{@phase}"

        if settime?
            # 時間を強制設定
            time = settime
        timeout()
    # プレイヤーごとに　見せてもよいログをリストにする
    makelogs:(logs,player)->
        result = []
        for x in logs
            ls = makelogsFor this, player, x
            result.push ls...
        return result
    # 終了時の称号処理
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
                        comment:@i18n.t "system.prize", {name: pl.name, prize: pnames.join ''}
                    splashlog @id,this,log
    # ユーザーのゲームログを保存
    saveUserRawLogs:->
        libuserlogs.addGameLogs this, (err)->
            if err?
                console.error err
                return
###
logs:[{
    mode:"day"(昼) / "system"(システムメッセージ) /  "werewolf"(狼) / "heaven"(天国) / "prepare"(開始前/終了後) / "skill"(能力ログ) / "nextturn"(ゲーム進行) / "audience"(観戦者のひとりごと) / "monologue"(夜のひとりごと) / "voteresult" (投票結果） / "couple"(共有者) / "fox"(妖狐) / "will"(遺言) / "madcouple"(叫迷狂人)
    "wolfskill"(人狼に見える) / "emmaskill"(閻魔に見える) / "eyeswolfskill"(瞳狼に見える)
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
        @remains=1  # 残り処刑人数
        @runoffmode=false   # 再投票中か
        @candidates=[]
        @start()
    start:->
        @votes=[]   #{player:Player, to:Player}
    setCandidates:(@candidates)->
        # 候補者をセットする[Player]
    isVoteFinished:(player)->@votes.some (x)->x.player.id==player.id
    vote:(player,voteto)->
        # power: 票数
        pl=@game.getPlayer voteto
        unless pl?
            return @game.i18n.t "error.common.nonexistentPlayer"
        if pl.dead
            return @game.i18n.t "error.common.alreadyDead"
        me=@game.getPlayer player.id
        unless me?
            return @game.i18n.t "error.common.notPlayer"
        if @isVoteFinished player
            return @game.i18n.t "error.voting.voted"
        if pl.id==player.id && @game.rule.votemyself!="ok"
            return @game.i18n.t "error.voting.self"
        @votes.push {
            player:@game.getPlayer player.id
            to:pl
            power:1
            priority:0
        }
        log=
            mode:"voteto"
            to:player.id
            comment: @game.i18n.t "system.votingbox.voted", {name: player.name, target: pl.name}
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
    # 処刑人数を増やす
    addPunishedNumber:(num)->
        @remains+=num

    isVoteAllFinished:->
        alives=@game.players.filter (x)->!x.dead
        alives.every (x)=>
            x.voted @game,@
    compareGots:(a,b)->
        # aとbをsort用に(gots)
        # aのほうが小さい: -1 <
        # bのほうが小さい: 1  >
        if a.votes>b.votes
            return 1
        else if a.votes<b.votes
            return -1
        else if a.priority>b.priority
            return 1
        else if a.priority<b.priority
            return -1
        else
            return 0
    check:->
        # return [mode,results,tos,table]
        # 投票が終わったのでアレする
        # 投票表を作る
        tos={}
        table=[]
        gots={}
        #for obj in @votes
        alives = @game.players.filter (x)->!x.dead
        for pl in alives
            obj=@getHisVote pl
            o=pl.publicinfo()
            if obj?
                gots[obj.to.id] ?= {
                    votes:0
                    priority:-Infinity
                }
                go=gots[obj.to.id]
                go.votes+=obj.power
                if go.priority<obj.priority
                    go.priority=obj.priority
                tos[obj.to.id]=go.votes
                o.voteto=obj.to.id  # 投票先情報を付け加える
            table.push o
        for pl in alives
            vote = gots[pl.id]
            if vote?
                vote = pl.modifyMyVote @game, vote
                gots[pl.id] = vote
                tos[pl.id] = vote.votes

        # 獲得票数が少ない順に並べる
        cands=Object.keys(gots).sort (a,b)=>
            @compareGots gots[a],gots[b]

        # 獲得票数多い一覧
        back=null
        tops=[]
        for id in cands by -1
            if !back? || @compareGots(gots[back],gots[id])==0
                tops.push id
                back=id
            else
                break
        if tops.length==0
            # 誰も投票していない
            return ["novote",null,tos,table]
        if tops.length>1
            # 決まらない
            if @game.rule.runoff!="yes" || @runoffmode
                # 投票同数時の処理
                switch @game.rule.drawvote
                    when "random"
                        # ランダムに1人処刑
                        r = Math.floor Math.random()*tops.length
                        return ["punish", [@game.getPlayer(tops[r])], tos, table]
                    when "none"
                        # 処刑しない
                        return ["none",null,tos,table]
                    when "all"
                        # 全員処刑
                        return [
                            "punish",
                            tops.map((id)=> @game.getPlayer id),
                            tos,
                            table
                        ]
                    else
                        # デフォルト（再投票）
                        if @game.rule.runoff!="no" && !@runoffmode
                            @setCandidates @game.players.filter (x)->x.id in tops
                            @runoffmode=true
                            return ["runoff",null,tos,table]
                        else
                            return ["revote",null,tos,table]
        if @game.rule.runoff=="yes" && !@runoffmode
            # 候補は1人だけど決選投票をしないといけない
            if tops.length<=1
                # 候補がたりない
                back=null
                flag=false
                tops=[]
                for id in cands by -1
                    ok=false
                    if !back?
                        ok=true
                    else if @compareGots(gots[back],gots[id])==0
                        ok=true
                    else if flag==false
                        # 決選投票なので1回だけOK!
                        flag=true
                        ok=true
                    else
                        break
                    if ok
                        tops.push id
                        back=id
            if tops.length>1
                @setCandidates @game.players.filter (x)->x.id in tops
                @runoffmode=true
                return ["runoff",null,tos,table]
        # 結果を教える
        return ["punish",[@game.getPlayer(tops[0])],tos,table]

class Player
    # `jobname` property should be set by Player.factory
    constructor:(@game)->
        # game: a game to which this player is associated.
        # realid:本当のid id:仮のidかもしれない name:名前 icon:アイコンURL
        @dead=false
        @found=null # 死体の発見状況
        @winner=null    # 勝敗
        @scapegoat=false    # 身代わりくんかどうか
        @flag=null  # 役職ごとの自由なフラグ

        @will=null  # 遺言
        # もとの役職
        @originalType=@type
        # 蘇生辞退
        @norevive=false
        # ID unique to this object.
        # Set by Player.factory.
        @objid=null


    @factory:(type,game,main=null,sub=null,cmpl=null)->
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
            p=new Player game
            p.objid = generateObjId()
        else
            p=new jobs[type] game
            # Add `jobname` property
            p.jobname = game.i18n.t "roles:jobname.#{type}"
            p.originalJobname = p.getJobname()
            p.objid = generateObjId()
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
            norevive:@norevive
        if @isComplex()
            r.type="Complex"
            r.Complex_main=@main.serialize()
            r.Complex_sub=@sub?.serialize()
            r.Complex_type=@cmplType
            r.Complex_flag=@cmplFlag
        r
    @unserialize:(obj, game)->
        unless obj?
            return null

        p=if obj.type=="Complex"
            # 複合
            cmplobj=complexes[obj.Complex_type ? "Complex"]
            Player.factory null, game, Player.unserialize(obj.Complex_main, game), Player.unserialize(obj.Complex_sub, game),cmplobj
        else
            # 普通
            Player.factory obj.type, game
        p.setProfile obj    #id,realid,name...
        p.dead=obj.dead
        p.scapegoat=obj.scapegoat
        p.will=obj.will
        p.flag=obj.flag
        p.winner=obj.winner
        p.originalType=obj.originalType
        p.originalJobname=obj.originalJobname
        p.norevive=!!obj.norevive   # backward compatibility
        if p.isComplex()
            p.cmplFlag=obj.Complex_flag
        p
    # 汎用関数: Complexを再構築する（chain:Complexの列（上から））
    @reconstruct:(chain, base, game)->
        for cmpl,i in chain by -1
            newpl=Player.factory null, game, base,cmpl.sub,complexes[cmpl.cmplType]
            ###
            for ok in Object.keys cmpl
                # 自分のプロパティのみ
                unless ok=="main" || ok=="sub"
                    newpl[ok]=cmpl[ok]
            ###
            newpl.cmplFlag=cmpl.cmplFlag
            base=newpl
        base

    publicinfo:->
        # 見せてもいい情報
        {
            id:@id
            name:@name
            dead:@dead
            norevive:@norevive
        }
    # プロパティセット系(Complex対応)
    setDead:(@dead,@found)->
    setWinner:(@winner)->
    setTarget:(@target)->
    setFlag:(@flag)->
    setWill:(@will)->
    setOriginalType:(@originalType)->
    setOriginalJobname:(@originalJobname)->
    setNorevive:(@norevive)->

    # ログが見えるかどうか（通常のゲーム中、個人宛は除外）
    isListener:(game,log)->
        if log.mode in ["day","system","nextturn","prepare","monologue","heavenmonologue","skill","will","voteto","gm","gmreply","helperwhisper","probability_table","userinfo"]
            # 全員に見える
            true
        else if log.mode in ["heaven","gmheaven"]
            # 死んでたら見える
            @dead
        else if log.mode=="voteresult"
            game.rule.voteresult!="hide"    # 隠すかどうか
        else
            false

    # midnightの実行順（小さいほうが先）
    midnightSort: 100
    # 本人に見える役職名
    getJobDisp:->@jobname
    # 本人に見える役職タイプ
    getTypeDisp:->@type
    # 役職名を得る
    getJobname:->@jobname
    # サブ役職の情報を除いた役職名を得る
    getMainJobname:-> @getJobname()
    # getMainJobnameのjobDisp版
    getMainJobDisp:-> @getJobDisp()
    # 村人かどうか
    isHuman:->!@isWerewolf()
    # 人狼かどうか
    isWerewolf:->false
    # 妖狐かどうか
    isFox:->false
    # 人狼の仲間として見えるかどうか
    isWerewolfVisible:->@isWerewolf()
    # 妖狐の仲間としてみえるか
    isFoxVisible:->false
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
    # 蘇生可能性を秘めているか
    isReviver:->false
    # ----- 役職判定用
    hasDeadResistance:->false
    # -----

    # Am I Dead?
    isDead:->{dead:@dead,found:@found}
    # get my team
    getTeam:-> @team
    # Display of my team.
    getTeamDisp:-> @getTeam()
    # 終了時の人間カウント
    humanCount:->
        if !@isFox() && @isHuman()
            1
        else
            0
    werewolfCount:->
        if !@isFox() && @isWerewolf()
            1
        else
            0
    vampireCount:->
        if !@isFox() && @isVampire()
            1
        else
            0

    # jobtypeが合っているかどうか（夜）
    isJobType:(type)->type==@type
    # メイン役職のjobtypeを判定
    isMainJobType:(type)->@isJobType type
    #An access to @flag, etc.
    accessByJobType:(type)->
        unless type
            throw "there must be a JOBTYPE"
        if @isJobType(type)
            return this
        null
    # access all sub-jobs by jobtype.
    # Returns array.
    accessByJobTypeAll:(type, subonly)->
        unless type
            throw "there must be a JOBTYPE"
        if !subonly && @isJobType(type)
            return [this]
        else
            return []
    # access by objid.
    # If not existent, returns null.
    accessByObjid:(objid)->
        if @objid == objid
            return this
        return null
    gatherMidnightSort:->
        return [@midnightSort]
    # complexのJobTypeを調べる
    isCmplType:(type)->false
    # 投票先決定
    dovote:(game,target)->
        # 戻り値にも意味があるよ！
        err=game.votingbox.vote this,target,1
        if err?
            return err
        @voteafter game,target
        return null
    voteafter:(game,target)->
    # 昼のはじまり（死体処理よりも前）
    sunrise:(game)->
    deadsunrise:(game)->
    # 昼の投票準備
    votestart:(game)->
        #@voteto=null
        return if @dead
        if @scapegoat
            # 身代わりくんは投票
            alives=game.votingbox.candidates.filter (x)=>
                pl=game.getPlayer x.id
                return !pl.dead && pl!=this
            #alives=game.players.filter (x)=>!x.dead && x!=this
            r=Math.floor Math.random()*alives.length    # 投票先
            return unless alives[r]?
            #@voteto=alives[r].id
            @dovote game,alives[r].id

    # 夜のはじまり（死体処理よりも前）
    # Note: people should not die at sunset,
    # with FrankensteinsMonster and Pyrotechnist in mind
    sunset:(game)->
    deadsunset:(game)->
    # 夜にもう寝たか
    sleeping:(game)->true
    # 夜に仕事を追えたか（基本sleepingと一致）
    jobdone:(game)->@sleeping game
    # 死んだ後でも仕事があるとfalse
    deadJobdone:(game)->true
    # ハンターフェイズに仕事があるか?
    hunterJobdone:(game)->true
    # 昼に投票を終えたか
    voted:(game,votingbox)->
        result = game.votingbox.isVoteFinished this
        if result==false && @scapegoat
            @votestart game
            true
        else
            result
    # 夜の仕事
    job:(game,playerid,query)->
        @setTarget playerid
        null
    # 夜の仕事を行う
    midnight:(game,midnightSort)->
    # 夜死んでいたときにmidnightの代わりに呼ばれる
    deadnight:(game,midnightSort)->
    # 対象
    job_target:1    # ビットフラグ
    # 対象用の値
    @JOB_T_ALIVE:1  # 生きた人が対象
    @JOB_T_DEAD :2  # 死んだ人が対象
    # フォームの種類（null or FormType)
    formType: null
    #人狼に食われて死ぬかどうか
    willDieWerewolf:true
    #占いの結果
    fortuneResult: FortuneResult.human
    getFortuneResult:->@fortuneResult
    #霊能の結果
    psychicResult: PsychicResult.human
    getPsychicResult:->@psychicResult
    #チーム Human/Werewolf
    team: "Human"
    #勝利かどうか team:勝利陣営名
    isWinner:(game,team)->
        team==@getTeam() # 自分の陣営かどうか
    # 殺されたとき(found:死因。fromは場合によりplayerid。punishの場合は[playerid]))
    die:(game,found,from)->
        return if @dead
        if found=="werewolf" && !@willDieWerewolf
            # 襲撃耐性あり
            game.addGuardLog @id, AttackKind.werewolf, GuardReason.tolerance
            return
        pl=game.getPlayer @id
        pl.setDead true,found
        pl.dying game,found,from
    # 死んだとき
    dying:(game,found)->
    # 行きかえる
    # XXX This method must be call for top of player.
    revive:(game)->
        # logging: ログを表示するか
        if @norevive
            # 蘇生しない
            return
        @setDead false,null
        p=@getParent game
        unless p?.sub==this
            # サブのときはいいや・・・
            game.revive_log.push @name
            @addGamelog game,"revive",null,null
            game.ss.publish.user @id,"refresh",{id:game.id}
    # 埋葬するまえに全員呼ばれる（foundが見られる状況で）
    beforebury: (game,type,deads)->
    # 占われたとき（結果は別にとられる player:占い元）
    divined:(game,player)->
    # ちょっかいを出されたとき(jobのとき)
    touched:(game,from)->
    # 選択肢を返す
    makeJobSelection:(game)->
        if Phase.isNight(game.phase) || game.phase == Phase.hunter
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
            if game.votingbox
                for pl in game.votingbox.candidates
                    result.push {
                        name:pl.name
                        value:pl.id
                    }

        result
    checkJobValidity:(game,query)->
        sl=@makeJobSelection game
        return sl.length==0 || sl.some((x)->x.value==query.target)
    # 役職情報を載せる
    makejobinfo:(game,obj,jobdisp)->
        # 開くべきフォームを配列で（生きている場合）
        obj.open ?=[]
        obj.forms ?= []
        unless @dead
            if Phase.isNight(game.phase) || @chooseJobDay(game)
                unless @jobdone(game)
                    obj.open.push @type
                    obj.forms.push {
                        type: @type
                        options: @makeJobSelection game
                        formType: @formType
                        objid: @objid
                    }
            else if game.phase == Phase.hunter
                unless @hunterJobdone(game)
                    obj.open.push @type
                    obj.forms.push {
                        type: @type
                        options: @makeJobSelection game
                        formType: @formType
                        objid: @objid
                    }
        # 役職解説のアレ
        obj.desc ?= []
        type = @getTypeDisp()
        if type?
            obj.desc.push {
                name:jobdisp ? @getJobDisp()
                type:type
            }

        obj.job_target=@getjob_target()
        # 選択肢を教える {name:"名前",value:"値"}
        obj.job_selection ?= []
        obj.job_selection=obj.job_selection.concat @makeJobSelection game
        # 重複を取り除くのはクライアント側にやってもらおうかな…

        # 女王観戦者が見える
        if @getTeam()=="Human"
            obj.queens=game.players.filter((x)->x.isJobType "QueenSpectator").map (x)->
                x.publicinfo()
        else
            # セットなどによる漏洩を防止
            delete obj.queens
    # 昼でも対象選択を行えるか
    chooseJobDay:(game)->false
    # 仕事先情報を教える
    getjob_target:->@job_target
    # 昼の発言の選択肢
    getSpeakChoiceDay:(game)->
        if game.phase == Phase.day
            ["day","monologue"]
        else
            ["monologue"]
    # 夜の発言の選択肢を得る
    getSpeakChoice:(game)->
        ["monologue"]
    # 霊界発言
    getSpeakChoiceHeaven:(game)->
        ["day","monologue"]
    # 自分宛の投票を書き換えられる
    modifyMyVote:(game, vote)-> vote
    # Complexから抜ける
    uncomplex:(game, flag=false)->
        #flag: 自分がComplexで自分が消滅するならfalse 自分がmainまたはsubで親のComplexを消すならtrue(その際subは消滅）

        befpl=game.getPlayer @id
        orig_jobname = befpl.originalJobname
        jobname1 = befpl.getJobname()

        res = getSubParentAndMainChain befpl, this
        unless res?
            return
        [topParent, complexChain, main] = res

        if flag
            if complexChain.length > 0
                # Remove the most recent parent.
                complexChain.pop()
            else
                # fallback to top parent.
                if topParent?
                    topParent.uncomplex game, false
                return
        else
            # Remove myself from the chain.
            complexChain = complexChain.filter (c)=> c != this
        # reconstruct the player object.
        newpl = Player.reconstruct complexChain, main

        if topParent?
            topParent.sub = newpl
        else
            game.setPlayer @id, newpl

        aftpl=game.getPlayer @id
        jobname2 = aftpl.getJobname()
        #前と後で比較
        if jobname1 != jobname2
            aftpl.setOriginalJobname "#{orig_jobname}→#{jobname2}"

    # 自分自身を変える
    transform:(game,newpl,override,initial=false)->
        # override: trueなら全部変える falseならメイン役職のみ変える
        # jobnameを覚えておく
        pl = game.getPlayer @id
        jobname = pl.getJobname()
        orig_name = pl.originalJobname

        res = getSubParentAndMainChain pl, this
        unless res?
            # This should never happen
            return
        @addGamelog game, "transform", newpl.type
        [topParent, complexChain, main] = res
        # If override flag is set, replaced pl is just newpl.
        # otherwise, reconstruct player object structure.
        replacepl =
            if override
                newpl
            else
                Player.reconstruct complexChain, newpl, game
        # replace old object with new one.
        if topParent?
            topParent.sub = replacepl
        else
            game.setPlayer @id, replacepl

        pl = game.getPlayer @id
        jobname2 = pl.getJobname()
        if jobname != jobname2
            # jobnameが変わったので変更
            if initial
                # 最初の変化（ログに残さない）
                pl.setOriginalJobname jobname2
            else
                # ふつうの変化
                pl.setOriginalJobname "#{orig_name}→#{jobname2}"
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
        newpl.setDead @dead,@found
        newpl.setNorevive @norevive








class Human extends Player
    type:"Human"
class Werewolf extends Player
    type:"Werewolf"
    sunset:(game)->
        @setTarget null
        unless game.day==1 && game.rule.scapegoat!="off"
            if @scapegoat && @isAttacker() && game.players.filter((x)->!x.dead && x.isWerewolf() && x.isAttacker()).length==1
                # 自分しか人狼がいない
                hus=game.players.filter (x)->!x.dead && !x.isWerewolf()
                while hus.length>0 && game.werewolf_target_remain>0
                    r=Math.floor Math.random()*hus.length
                    @job game,hus[r].id,{
                        jobtype: "_Werewolf"
                    }
                    hus.splice r,1
                if game.werewolf_target_remain>0
                    # 襲撃したい人全員襲撃したけどまだ襲撃できるときは重複襲撃
                    hus=game.players.filter (x)->!x.dead && !x.isWerewolf()
                    # safety counter
                    i = 100
                    while hus.length>0 && game.werewolf_target_remain>0 && i > 0
                        r=Math.floor Math.random()*hus.length
                        @job game,hus[r].id,{
                            jobtype: "_Werewolf"
                        }
                        i--

    formType: FormType.required
    sleeping:(game)->game.werewolf_target_remain<=0 || !Phase.isNight(game.phase)
    job:(game,playerid)->
        tp = game.getPlayer playerid
        if game.werewolf_target_remain<=0
            return game.i18n.t "error.common.cannotUseSkillNow"
        if game.rule.wolfattack!="ok" && tp?.isWerewolf()
            # 人狼は人狼に攻撃できない
            return game.i18n.t "roles:Werewolf.noWolfAttack"
        game.werewolf_target.push {
            from:@id
            to:playerid
        }
        game.werewolf_target_remain--
        game.checkWerewolfTarget()
        tp.touched game,@id
        log=
            mode:"wolfskill"
            comment: game.i18n.t "roles:Werewolf.select", {name: @name, target: tp.name}
        if @isJobType "SolitudeWolf"
            # 孤独な狼なら自分だけ…
            log.to=@id
        splashlog game.id,game,log
        game.splashjobinfo game.players.filter (x)=>x.id!=playerid && x.isWerewolf()
        null

    isHuman:->false
    isWerewolf:->true
    hasDeadResistance:->true
    # おおかみ専用メソッド：襲撃できるか
    isAttacker:->!@dead

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
    fortuneResult: FortuneResult.werewolf
    psychicResult: PsychicResult.werewolf
    team: "Werewolf"
    makejobinfo:(game,result)->
        super
        if Phase.isNight(game.phase)
            if game.werewolf_target_remain>0
                # まだ襲える
                result.open.push "_Werewolf"
                result.forms.push {
                    type: "_Werewolf"
                    options: @makeJobSelection game
                    formType: FormType.required
                    objid: @objid
                }
            # 人狼の場合は役職固有のやつは一旦閉じる
            result.open = result.open.filter (x)=> x != @type
            result.forms = result.forms.filter (x)=> x.type != @type
        # 人狼は仲間が分かる
        result.wolves=game.players.filter((x)->x.isWerewolfVisible()).map (x)->
            x.publicinfo()
        # スパイ2も分かる
        result.spy2s=game.players.filter((x)->x.isJobType "Spy2").map (x)->
            x.publicinfo()
    getSpeakChoice:(game)->
        ["werewolf"].concat super



class Diviner extends Player
    type:"Diviner"
    midnightSort: 100
    formType: FormType.required
    constructor:->
        super
        @setFlag []
            # {player:Player, result:String}
    sunset:(game)->
        super
        @setTarget null
        # 占い対象
        targets = game.players.filter (x)->!x.dead

        if @type == "Diviner" && game.day == 1 && game.rule.firstnightdivine == "auto"
            # 自動白通知
            targets2 = targets.filter (x)=> x.id != @id && x.getFortuneResult() == FortuneResult.human && x.id != "身代わりくん" && !x.isJobType("Fox")
            if targets2.length > 0
                # ランダムに決定
                log=
                    mode:"skill"
                    to:@id
                    comment:game.i18n.t "roles:Diviner.auto", {name: @name}
                splashlog game.id,game,log

                r=Math.floor Math.random()*targets2.length
                @job game,targets2[r].id,{}
                return

        if @scapegoat
            # 身代わり君の自動占い
            r=Math.floor Math.random()*targets.length
            @job game,targets[r].id,{}
    sleeping:->@target?
    job:(game,playerid)->
        pl=game.getPlayer playerid
        unless pl?
            return game.i18n.t "error.common.nonexistentPlayer"

        @setTarget playerid
        pl.touched game,@id
        log=
            mode:"skill"
            to:@id
            comment: game.i18n.t "roles:Diviner.select", {name: @name, target: pl.name}
        splashlog game.id,game,log
        if game.rule.divineresult=="immediate"
            @dodivine game
            @showdivineresult game
        null
    sunrise:(game)->
        super
        unless game.rule.divineresult=="immediate"
            @showdivineresult game

    midnight:(game,midnightSort)->
        unless game.rule.divineresult=="immediate"
            @dodivine game
        @divineeffect game
    #占った影響を与える
    divineeffect:(game)->
        p=game.getPlayer @target
        if p?
            p.divined game,this
    #占い実行
    dodivine:(game)->
        p=game.getPlayer @target
        if p?
            @setFlag @flag.concat {
                player: p.publicinfo()
                result: game.i18n.t "roles:Diviner.resultlog", {name: @name, target: p.name, result: game.i18n.t "roles:fortune.#{p.getFortuneResult()}"}
            }
            @addGamelog game,"divine",p.type,@target    # 占った
    showdivineresult:(game)->
        r=@flag[@flag.length-1]
        return unless r?
        log=
            mode:"skill"
            to:@id
            comment:r.result
        splashlog game.id,game,log
class Psychic extends Player
    type:"Psychic"
    constructor:->
        super
        @setFlag ""    # ここにメッセージを入れよう
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
        @setFlag ""

    # 処刑で死んだ人を調べる
    beforebury:(game,type,deads)->
        @setFlag if @flag? then @flag else ""
        deads.filter((x)-> x.found=="punish").forEach (x)=>
            @setFlag @flag + game.i18n.t("roles:Psychic.resultlog", {
                name: @name
                target: x.name
                result: PsychicResult.renderToString x.getPsychicResult(), game.i18n
            }) + "\n"

class Madman extends Player
    type:"Madman"
    team:"Werewolf"
    makejobinfo:(game,result)->
        super
        delete result.queens
class Guard extends Player
    type:"Guard"
    midnightSort: 80
    formType: FormType.required
    hasDeadResistance:->true
    sleeping:->@target?
    sunset:(game)->
        @setTarget null

        if game.day==1 && game.rule.scapegoat != "off"
            # 狩人は一日目護衛しない
            @setTarget ""  # 誰も守らない
            return
        # 護衛可能対象
        pls = game.players.filter (pl)=>
            if game.rule.guardmyself!="ok" && pl.id == @id
                return false
            if game.rule.consecutiveguard=="no" && pl.id == @flag
                return false
            return true

        if pls.length == 0
            @setTarget ""
            return

        if @scapegoat
            # 身代わり君の自動占い
            r=Math.floor Math.random()*pls.length
            if @job game,pls[r].id,{}
                # 失敗した
                @setTarget ""
    job:(game,playerid)->
        if playerid==@id && game.rule.guardmyself!="ok"
            return game.i18n.t "error.common.noSelectSelf"
        else if playerid==@flag && game.rule.consecutiveguard=="no"
            return game.i18n.t "roles:Guard.noGuardSame"
        else
            @setTarget playerid
            @setFlag playerid

            pl=game.getPlayer(playerid)
            log=
                mode:"skill"
                to:@id
                comment: game.i18n.t "roles:Guard.select", {name: @name, target: pl.name}
            splashlog game.id,game,log
            null
    midnight:(game,midnightSort)->
        pl = game.getPlayer @target
        unless pl?
            return
        # 複合させる
        newpl=Player.factory null, game, pl,null,Guarded   # 守られた人
        pl.transProfile newpl
        newpl.cmplFlag=@id  # 護衛元cmplFlag
        pl.transform game,newpl,true
        newpl.touched game,@id
        null
class Couple extends Player
    type:"Couple"
    makejobinfo:(game,result)->
        super
        # 共有者は仲間が分かる
        result.peers=game.players.filter((x)->x.isJobType "Couple").map (x)->
            x.publicinfo()
    isListener:(game,log)->
        if log.mode=="couple"
            true
        else super
    getSpeakChoice:(game)->
        ["couple"].concat super

class Fox extends Player
    type:"Fox"
    team:"Fox"
    willDieWerewolf:false
    isHuman:->false
    isFox:->true
    isFoxVisible:->true
    hasDeadResistance:->true
    makejobinfo:(game,result)->
        super
        # 妖狐は仲間が分かる
        result.foxes=game.players.filter((x)->x.isFoxVisible()).map (x)->
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
    dying:(game,found,from)->
        super
        # 埋毒者の逆襲
        canbedead = game.players.filter (x)->!x.dead    # 生きている人たち
        if found=="werewolf"
            # 噛まれた場合は狼のみ
            if game.rule.poisonwolf == "selector"
                # 襲撃者を道連れにする
                canbedead = canbedead.filter (x)->x.id==from
            else
                canbedead=canbedead.filter (x)->x.isWerewolf()
        else if found=="vampire"
            canbedead=canbedead.filter (x)->x.id==from
        return if canbedead.length==0
        r=Math.floor Math.random()*canbedead.length
        pl=canbedead[r] # 被害者
        pl.die game,"poison"
        @addGamelog game,"poisonkill",null,pl.id

class BigWolf extends Werewolf
    type:"BigWolf"
    fortuneResult: FortuneResult.human
    psychicResult: PsychicResult.BigWolf
class TinyFox extends Diviner
    type:"TinyFox"
    fortuneResult: FortuneResult.human
    psychicResult: PsychicResult.TinyFox
    team:"Fox"
    midnightSort:100
    formType: FormType.required
    isHuman:->false
    isFox:->true
    hasDeadResistance:->true
    makejobinfo:(game,result)->
        super
        # 子狐は妖狐が分かる
        result.foxes=game.players.filter((x)->x.isFoxVisible()).map (x)->
            x.publicinfo()
    dodivine:(game)->
        p=game.getPlayer @target
        if p?
            success= Math.random()<0.5  # 成功したかどうか
            key = if success then "roles:TinyFox.resultlog_success" else "roles:TinyFox.resultlog_fail"
            re = game.i18n.t key, {name: @name, target: p.name, result: game.i18n.t "roles:fortune.#{p.getFortuneResult()}"}
            @setFlag @flag.concat {
                player: p.publicinfo()
                result: re
            }
            @addGamelog game,"foxdivine",success,p.id
    showdivineresult:(game)->
        r=@flag[@flag.length-1]
        return unless r?
        log=
            mode:"skill"
            to:@id
            comment:r.result
        splashlog game.id,game,log
    divineeffect:(game)->


class Bat extends Player
    type:"Bat"
    team:""
    isWinner:(game,team)->
        !@dead  # 生きて入ればとにかく勝利
class Noble extends Player
    type:"Noble"
    hasDeadResistance:(game)->
        slaves = game.players.filter (x)->!x.dead && x.isJobType "Slave"
        return slaves.length > 0
    die:(game,found)->
        if found=="werewolf"
            return if @dead
            # 奴隷たち
            slaves = game.players.filter (x)->!x.dead && x.isJobType "Slave"
            unless slaves.length
                super   # 自分が死ぬ
            else
                # 奴隷が代わりに死ぬ
                slaves.forEach (x)->
                    x.die game,"werewolf2"
                    x.addGamelog game,"slavevictim"
                @addGamelog game,"nobleavoid"
                game.addGuardLog @id, AttackKind.werewolf, GuardReason.cover
        else
            super

class Slave extends Player
    type:"Slave"
    isWinner:(game,team)->
        nobles=game.players.filter (x)->!x.dead && x.isJobType "Noble"
        if team==@getTeam() && nobles.length==0
            true    # 村人陣営の勝ちで貴族は死んだ
        else
            false
    makejobinfo:(game,result)->
        super
        # 奴隷は貴族が分かる
        result.nobles=game.players.filter((x)->x.isJobType "Noble").map (x)->
            x.publicinfo()
class Magician extends Player
    type:"Magician"
    midnightSort:100
    formType: FormType.required
    isReviver:->!@dead
    sunset:(game)->
        @setTarget (if game.day<3 then "" else null)
        if game.players.every((x)->!x.dead)
            @setTarget ""  # 誰も死んでいないなら能力発動しない
        if !@target? && @scapegoat
            # 身代わり君の自動占い
            r=Math.floor Math.random()*game.players.length
            @job game,game.players[r].id,{}
    job:(game,playerid)->
        if game.day<3
            # まだ発動できない
            return game.i18n.t "error.common.cannotUseSkillNow"
        pl=game.getPlayer playerid
        unless pl?
            return game.i18n.t "error.common.nonexistentPlayer"
        unless pl.dead
            return game.i18n.t "error.common.notDead"
        @setTarget playerid
        pl.touched game,@id

        log=
            mode:"skill"
            to:@id
            comment: game.i18n.t "roles:Magician.select", {name: @name, target: pl.name}
        splashlog game.id,game,log
        null
    sleeping:(game)->game.day<3 || @target?
    midnight:(game,midnightSort)->
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
    team:"Werewolf"
    midnightSort:100
    formType: FormType.optionalOnce
    sleeping:->true # 能力使わなくてもいい
    jobdone:->@flag in ["spygone","day1"]   # 能力を使ったか
    sunrise:(game)->
        if game.day<=1
            @setFlag "day1"    # まだ去れない
        else
            @setFlag null
    job:(game,playerid)->
        return game.i18n.t "error.common.alreadyUsed" if @flag=="spygone"
        @setFlag "spygone"
        log=
            mode:"skill"
            to:@id
            comment: game.i18n.t "roles:Spy.select", {name: @name}
        splashlog game.id,game,log
        null
    midnight:(game,midnightSort)->
        if !@dead && @flag=="spygone"
            # 村を去る
            @setFlag "spygone"
            @die game,"spygone"
    job_target:0
    isWinner:(game,team)->
        team==@getTeam() && @dead && @flag=="spygone"    # 人狼が勝った上で自分は任務完了の必要あり
    makejobinfo:(game,result)->
        super
        # スパイは人狼が分かる
        result.wolves=game.players.filter((x)->x.isWerewolfVisible()).map (x)->
            x.publicinfo()
    makeJobSelection:(game)->
        # 夜は投票しない
        if Phase.isNight(game.phase)
            []
        else super
class WolfDiviner extends Werewolf
    type:"WolfDiviner"
    midnightSort:100
    constructor:->
        super
        @setFlag {
            # 占い結果のリスト
            results: []
            # 占い対象
            target: null
        }
    sunset:(game)->
        @setTarget null
        @setFlag {
            results: @flag.results
            target: null
        }
        super
    sleeping:(game)->game.werewolf_target_remain<=0 # 占いは必須ではない
    jobdone:(game)->game.werewolf_target_remain<=0 && @flag.target?
    job:(game,playerid,query)->
        if query.jobtype!="WolfDiviner"
            # 人狼の仕事
            return super
        # 占い
        if @flag.target?
            return game.i18n.t "error.common.alreadyUsed"
        pl=game.getPlayer playerid
        unless pl?
            return game.i18n.t "error.common.nonexistentPlayer"
        @setFlag {
            results: @flag.results
            target: playerid
        }
        unless pl.getTeam()=="Werewolf" && pl.isHuman()
            # 狂人は変化するので
            pl.touched game,@id
        log=
            mode:"skill"
            to:@id
            comment: game.i18n.t "roles:WolfDiviner.select", {name: @name, target: pl.name}
        splashlog game.id,game,log
        if game.rule.divineresult=="immediate"
            @dodivine game
            @showdivineresult game
        null
    sunrise:(game)->
        super
        unless game.rule.divineresult=="immediate"
            @showdivineresult game
    midnight:(game,midnightSort)->
        super
        @divineeffect game
        unless game.rule.divineresult=="immediate"
            @dodivine game
    #占った影響を与える
    divineeffect:(game)->
        p=game.getPlayer @flag.target
        if p?
            p.divined game,this
            if p.isJobType "Diviner"
                # 逆呪殺
                @die game,"curse"
    showdivineresult:(game)->
        r=@flag.results[@flag.results.length-1]
        return unless r?
        log=
            mode:"skill"
            to:@id
            comment:r.result
        splashlog game.id,game,log
    dodivine:(game)->
        p=game.getPlayer @flag.target
        if p?
            @setFlag {
                results: @flag.results.concat {
                    player: p.publicinfo()
                    result: game.i18n.t "roles:WolfDiviner.resultlog", {name: @name, target: p.name, result: p.getMainJobname()}
                }
                target: @flag.target
            }
            @addGamelog game,"wolfdivine",null,@flag.target  # 占った
            if p.getTeam()=="Werewolf" && p.isHuman()
                # 狂人変化
                jobnames=Object.keys jobs
                # inspect all target roles.
                for targetpl in getAllMainRoles p
                    # check whether this target should change.
                    unless targetpl.getTeam()=="Werewolf" && targetpl.isHuman()
                        continue
                    newjob=jobnames[Math.floor Math.random()*jobnames.length]
                    # convert this to new pl.
                    newpl = Player.factory newjob, game
                    targetpl.transProfile newpl
                    targetpl.transferData newpl

                    targetpl.transform game,newpl,false
                    log=
                        mode:"skill"
                        to:p.id
                        comment: game.i18n.t "system.changeRole", {name: p.name, result: newpl.getJobDisp()}
                    splashlog game.id,game,log
                p=game.getPlayer @flag.target
                p.sunset game
                game.splashjobinfo [game.getPlayer p.id]
    makejobinfo:(game,result)->
        super
        if Phase.isNight(game.phase)
            unless @flag?.target?
                # 占いが可能
                result.open.push @type
                result.forms.push {
                    type: @type
                    options: @makeJobSelection game
                    formType: FormType.optional
                    objid: @objid
                }


class Fugitive extends Player
    type:"Fugitive"
    formType: FormType.required
    midnightSort:100
    hasDeadResistance:->true
    sunset:(game)->
        @setTarget null
        if game.day<=1 && game.rule.scapegoat!="off"    # 一日目は逃げない
            @setTarget ""
        else if @scapegoat
            # 身代わり君の自動占い
            als=game.players.filter (x)=>!x.dead && x.id!=@id
            if als.length==0
                @setTarget ""
                return
            r=Math.floor Math.random()*als.length
            if @job game,als[r].id,{}
                @setTarget ""
    sleeping:->@target?
    job:(game,playerid)->
        # 逃亡先
        pl=game.getPlayer playerid
        if pl?.dead
            return game.i18n.t "error.common.alreadyDead"
        if playerid==@id
            return game.i18n.t "roles:Fugitive.noSelf"
        @setTarget playerid
        pl?.touched game,@id
        log=
            mode:"skill"
            to:@id
            comment: game.i18n.t "roles:Fugitive.select", {name: @name, target: pl.name}
        splashlog game.id,game,log
        @addGamelog game,"runto",null,pl.id
        null
    die:(game,found)->
        # 狼の襲撃・ヴァンパイアの襲撃・魔女の毒薬は回避
        if found in ["werewolf","vampire","witch"]
            if @target!=""
                if found == "werewolf"
                    game.addGuardLog @id, AttackKind.werewolf, GuardReason.absent
                return
            else
                super
        else
            super

    midnight:(game,midnightSort)->
        # 人狼の家に逃げていたら即死
        pl=game.getPlayer @target
        return unless pl?
        if !pl.dead && pl.isWerewolf() && pl.getTeam() != "Human"
            @die game,"werewolf2"
        else if !pl.dead && pl.isVampire() && pl.getTeam() != "Human"
            @die game,"vampire2"

    isWinner:(game,team)->
        team==@getTeam() && !@dead   # 村人勝利で生存
class Merchant extends Player
    type:"Merchant"
    constructor:->
        super
        @setFlag null  # 発送済みかどうか
    formType: FormType.optionalOnce
    sleeping:->true
    jobdone:(game)->game.day<=1 || @flag?
    job:(game,playerid,query)->
        if @flag?
            return game.i18n.t "error.common.alreadyUsed"
        # 即時発送
        unless query.Merchant_kit in ["Diviner","Psychic","Guard"]
            return game.i18n.t "error.common.invalidSelection"

        kit_name = game.i18n.t "roles:Merchant.kit.#{query.Merchant_kit}"

        pl=game.getPlayer playerid
        unless pl?
            return game.i18n.t "error.common.nonexistentPlayer"
        if pl.dead
            return game.i18n.t "error.common.alreadyDead"
        if pl.id==@id
            return game.i18n.t "roles:Merchant.noSelf"
        pl.touched game,@id
        # 複合させる
        sub=Player.factory query.Merchant_kit, game   # 副を作る
        pl.transProfile sub
        sub.sunset game
        newpl=Player.factory null, game, pl,sub,Complex    # Complex
        pl.transProfile newpl
        pl.transform game,newpl,true

        log=
            mode:"skill"
            to:@id
            comment: game.i18n.t "roles:Merchant.select", {name: @name, target: newpl.name, kit: kit_name}
        splashlog game.id,game,log
        # 入れ替え先は気づいてもらう
        log=
            mode:"skill"
            to:newpl.id
            comment: game.i18n.t "roles:Merchant.delivered", {name: newpl.name, kit: kit_name}
        splashlog game.id,game,log
        game.ss.publish.user newpl.id,"refresh",{id:game.id}
        @setFlag query.Merchant_kit    # 発送済み
        @addGamelog game,"sendkit",@flag,newpl.id
        null
class QueenSpectator extends Player
    type:"QueenSpectator"
    dying:(game,found)->
        super
        # 感染
        humans = game.players.filter (x)->!x.dead && x.isHuman()    # 生きている人たち
        humans.forEach (x)->
            x.die game,"hinamizawa"

class MadWolf extends Werewolf
    type:"MadWolf"
    team:"Human"
    isAttacker:->false
    sleeping:->true
class Neet extends Player
    type:"Neet"
    team:""
    sleeping:->true
    voted:(game,votingbox)->true
    isWinner:->true
class Liar extends Player
    type:"Liar"
    midnightSort:100
    formType: FormType.required
    job_target:Player.JOB_T_ALIVE | Player.JOB_T_DEAD   # 死人も生存も
    constructor:->
        super
        @setFlag []
    sunset:(game)->
        @setTarget null
        if @scapegoat
            # 身代わり君の自動占い
            r=Math.floor Math.random()*game.players.length
            @job game,game.players[r].id,{}
    sleeping:->@target?
    job:(game,playerid,query)->
        # 占い
        if @target?
            return game.i18n.t "error.common.alreadyUsed"
        @setTarget playerid
        pl=game.getPlayer playerid
        unless pl?
            return game.i18n.t "error.common.nonexistentPlayer"
        pl.touched game,@id
        log=
            mode:"skill"
            to:@id
            comment: game.i18n.t "roles:Diviner.select", {name: @name, target: pl.name}
        splashlog game.id,game,log
        null
    sunrise:(game)->
        super
        return if !@flag? || @flag.length==0
        resultobj = @flag[@flag.length-1]
        log=
            mode:"skill"
            to:@id
            comment: game.i18n.t "roles:Liar.resultlog", {target: resultobj.player.name, result: resultobj.result}
        splashlog game.id,game,log
    midnight:(game,midnightSort)->
        p=game.getPlayer @target
        if p?
            @addGamelog game,"liardivine",null,p.id
            result = if Math.random()<0.3
                # 成功
                p.getFortuneResult()
            else
                # 逆
                fr = p.getFortuneResult()
                switch fr
                    when FortuneResult.human
                        FortuneResult.werewolf
                    when FortuneResult.werewolf
                        FortuneResult.human
                    else
                        fr
            @setFlag @flag.concat {
                player: p.publicinfo()
                result: game.i18n.t "roles:fortune.#{result}"
            }
    isWinner:(game,team)->team==@getTeam() && !@dead # 村人勝利で生存
class Spy2 extends Player
    type:"Spy2"
    team:"Werewolf"
    makejobinfo:(game,result)->
        super
        # スパイは人狼が分かる
        result.wolves=game.players.filter((x)->x.isWerewolfVisible()).map (x)->
            x.publicinfo()

    dying:(game,found)->
        super
        @publishdocument game

    publishdocument:(game)->
        str=game.players.map (x)->
            "#{x.name}:#{x.getMainJobname()}"
        .join " "
        log=
            mode:"system"
            comment: game.i18n.t "roles:Spy2.found", {name: @name}
        splashlog game.id,game,log
        log2=
            mode:"will"
            comment:str
        splashlog game.id,game,log2

    isWinner:(game,team)-> team==@getTeam() && !@dead
class Copier extends Player
    type:"Copier"
    team:""
    formType: FormType.optionalOnce
    humanCount:-> 0
    sleeping:->true
    jobdone:->@target?
    sunset:(game)->
        @setTarget null
        if @scapegoat
            # 身代わりくんはコピーを自動選択
            alives = []
            for x in game.players
                unless x.dead
                    # 除外役職は他に比べて当選確率が4分の1
                    if x.type in SAFETY_EXCLUDED_JOBS
                        alives.push x
                    else
                        alives.push x, x, x, x
            r=Math.floor Math.random()*alives.length
            pl=alives[r]
            @job game,pl.id,{}

    job:(game,playerid,query)->
        # コピー先
        if @target?
            return game.i18n.t "error.common.alreadyUsed"
        @setTarget playerid
        pl=game.getPlayer playerid
        pl.touched game,@id
        log=
            mode:"skill"
            to:@id
            comment: game.i18n.t "roles:Copier.select", {name: @name, target: pl.name}
        splashlog game.id,game,log
        p=game.getPlayer playerid
        newpl=Player.factory p.type, game
        # TODO: we want to apply sunset to only newly-craeted role,
        # ideally after it is in role tree.
        @transProfile newpl
        @transferData newpl
        newpl.sunset game   # 初期化してあげる
        @transform game,newpl,false
        pl=game.getPlayer @id


        #game.ss.publish.user newpl.id,"refresh",{id:game.id}
        game.splashjobinfo [game.getPlayer @id]
        null
    isWinner:(game,team)->false # コピーしないと負け
class Light extends Player
    type:"Light"
    formType: FormType.optional
    midnightSort:100
    sleeping:->true
    jobdone:(game)->@target? || game.day==1
    sunset:(game)->
        @setTarget null
    job:(game,playerid,query)->
        # コピー先
        if @target?
            return game.i18n.t "error.common.alreadyUsed"
        @setTarget playerid
        pl=game.getPlayer playerid
        pl.touched game,@id
        log=
            mode:"skill"
            to:@id
            comment: game.i18n.t "roles:Light.select", {name: @name, target: pl.name}
        splashlog game.id,game,log
        null
    midnight:(game,midnightSort)->
        t=game.getPlayer @target
        # デスノートで殺す
        if t? && !t.dead
            t.die game,"deathnote"

        # 誰かに移る処理
        if @flag == "onenight"
            @uncomplex game,true    # 自分からは抜ける
class Fanatic extends Madman
    type:"Fanatic"
    makejobinfo:(game,result)->
        super
        # 狂信者は人狼が分かる
        result.wolves=game.players.filter((x)->x.isWerewolfVisible()).map (x)->
            x.publicinfo()
class Immoral extends Player
    type:"Immoral"
    team:"Fox"
    beforebury:(game)->
        # 狐が全員死んでいたら自殺
        unless game.players.some((x)->!x.dead && x.isFox())
            @die game,"foxsuicide"
    makejobinfo:(game,result)->
        super
        # 妖狐が分かる
        result.foxes=game.players.filter((x)->x.isFoxVisible()).map (x)->
            x.publicinfo()
class Devil extends Player
    type:"Devil"
    team:"Devil"
    psychicResult: PsychicResult.werewolf
    hasDeadResistance:->true
    die:(game,found)->
        return if @dead
        if found=="werewolf"
            # 死なないぞ！
            unless @flag
                # まだ噛まれていない
                @setFlag "bitten"
                # 専用ログを出す
                log=
                    mode: "skill"
                    to: @id
                    comment: game.i18n.t "roles:Devil.attacked", {name: @name}
                splashlog game.id, game, log
            game.addGuardLog @id, AttackKind.werewolf, GuardReason.devil
        else if found=="punish"
            # 処刑されたぞ！
            if @flag=="bitten"
                # 噛まれたあと処刑された
                @setFlag "winner"
                super
            else
                super
        else
            super
    isWinner:(game,team)->team==@getTeam() && @flag=="winner"
class ToughGuy extends Player
    type:"ToughGuy"
    hasDeadResistance:->true
    die:(game,found)->
        if found=="werewolf"
            # 狼の襲撃に耐える
            @setFlag "bitten"
            game.addGuardLog @id, AttackKind.werewolf, GuardReason.tolerance
        else
            super
    sunrise:(game)->
        super
        if @flag=="bitten"
            @setFlag "dying"   # 死にそう！
    midnight:(game)->
        if @flag=="dying"
            # 噛まれた次の夜
            @setFlag null
            @setDead true,"werewolf"
class Cupid extends Player
    type:"Cupid"
    team:"Friend"
    formType: FormType.required
    constructor:->
        super
        @setFlag null  # 恋人1
        @setTarget null    # 恋人2
    sunset:(game)->
        if game.day>=2 && @flag?
            # 2日目以降はもう遅い
            @setFlag ""
            @setTarget ""
        else
            @setFlag null
            @setTarget null
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
            return game.i18n.t "error.common.alreadyUsed"

        pl=game.getPlayer playerid
        unless pl?
            return game.i18n.t "error.common.nonexistentPlayer"

        unless @flag?
            @setFlag playerid
            log=
                mode:"skill"
                to:@id
                comment: game.i18n.t "roles:Cupid.select1", {name: @name, target: pl.name}
            splashlog game.id,game,log
            return null
        if @flag==playerid
            return game.i18n.t "roles:Cupid.noSelectTwice"

        @setTarget playerid
        # 恋人二人が決定した

        plpls=[game.getPlayer(@flag), game.getPlayer(@target)]
        for pl,i in plpls
            # 2人ぶん処理

            pl.touched game,@id
            newpl=Player.factory null, game, pl,null,Friend    # 恋人だ！
            newpl.cmplFlag=plpls[1-i].id
            pl.transProfile newpl
            pl.transform game,newpl,true # 入れ替え
            log=
                mode:"skill"
                to:@id
                comment: game.i18n.t "roles:Cupid.select", {name: @name, target: newpl.name}
            splashlog game.id,game,log
            log=
                mode:"skill"
                to:newpl.id
                comment: game.i18n.t "roles:Cupid.become", {name: newpl.name}
            splashlog game.id,game,log
        # 2人とも更新する
        for pl in [game.getPlayer(@flag), game.getPlayer(@target)]
            game.ss.publish.user pl.id,"refresh",{id:game.id}

        null
# ストーカー
class Stalker extends Player
    type:"Stalker"
    team:""
    formType: FormType.required
    sunset:(game)->
        super
        if !@flag   # ストーキング先を決めていない
            @setTarget null
            if @scapegoat
                alives=game.players.filter (x)->!x.dead
                r=Math.floor Math.random()*alives.length
                pl=alives[r]
                @job game,pl.id,{}
        else
            @setTarget ""
    sleeping:->@flag?
    job:(game,playerid,query)->
        if @target? || @flag?
            return game.i18n.t "error.common.alreadyUsed"

        pl=game.getPlayer playerid
        unless pl?
            return game.i18n.t "error.common.nonexistentPlayer"
        pl.touched game,@id
        @setTarget playerid
        log=
            mode:"skill"
            to:@id
            comment: game.i18n.t "roles:Stalker.select", {name: @name, target: pl.name, job: pl.getMainJobname()}
        splashlog game.id,game,log
        @setFlag playerid  # ストーキング対象プレイヤー
        null
    isWinner:(game,team)->
        if @isWinnerStalk?
            @isWinnerStalk game,team,[]
        else
            false
    # ストーカー連鎖対応版
    isWinnerStalk:(game,team,ids)->
        if @id in ids
            # ループしてるので負け
            return false
        pl=game.getPlayer @flag
        return false unless pl?
        if team==pl.getTeam()
            return true
        if pl.isJobType("Stalker") && pl.isWinnerStalk?
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
    hasDeadResistance:->true
    die:(game,found)->
        return if @dead
        if found=="werewolf"
            # 噛まれた場合人狼側になる
            unless @flag
                # まだ噛まれていない
                @setFlag "bitten"
            game.addGuardLog @id, AttackKind.werewolf, GuardReason.cursed
        else if found=="vampire"
            # ヴァンパイアにもなる!!!
            unless @flag
                # まだ噛まれていない
                @setFlag "vampire"
        else
            super
    sunset:(game)->
        if @flag in ["bitten","vampire"]
            # この夜から変化する
            log=null
            newpl=null
            if @flag=="bitten"
                log=
                    mode:"skill"
                    to:@id
                    comment: game.i18n.t "roles:Cursed.becomeWerewolf", {name: @name}

                newpl=Player.factory "Werewolf", game
            else
                log=
                    mode:"skill"
                    to:@id
                    comment: game.i18n.t "roles:Cursed.becomeVampire", {name: @name}

                newpl=Player.factory "Vampire", game

            @transProfile newpl
            @transferData newpl
            @transform game,newpl,false
            newpl.sunset game

            splashlog game.id,game,log
            if @flag=="bitten"
                # 人狼側に知らせる
                #game.ss.publish.channel "room#{game.id}_werewolf","refresh",{id:game.id}
                game.splashjobinfo game.players.filter (x)=>x.id!=@id && x.isWerewolf()
            else
                # ヴァンパイアに知らせる
                game.splashjobinfo game.players.filter (x)=>x.id!=@id && x.isVampire()
            # 自分も知らせる
            #game.ss.publish.user newpl.realid,"refresh",{id:game.id}
            game.splashjobinfo [game.getPlayer @id]
class ApprenticeSeer extends Player
    type:"ApprenticeSeer"
    beforebury:(game)->
        # 占い師が誰か死んでいたら占い師に進化
        if game.players.some((x)->x.dead && x.isJobType("Diviner")) || game.players.every((x)->!x.isJobType("Diviner"))
            newpl=Player.factory "Diviner", game
            @transProfile newpl
            @transferData newpl
            log=
                mode:"skill"
                to:@id
                comment: game.i18n.t "system.changeRoleFrom", {name: @name, old: @jobname, result: newpl.jobname}
            splashlog game.id,game,log

            @transform game,newpl,false

            # 更新
            game.ss.publish.user newpl.realid,"refresh",{id:game.id}
class Diseased extends Player
    type:"Diseased"
    dying:(game,found)->
        super
        if found=="werewolf"
            # 噛まれた場合次の日人狼襲撃できない！
            game.werewolf_flag.push "Diseased"   # 病人フラグを立てる
class Spellcaster extends Player
    type:"Spellcaster"
    formType: FormType.optional
    midnightSort:100
    sleeping:->true
    jobdone:->@target?
    sunset:(game)->
        @setTarget null
        if game.day==1
            # 初日は発動できません
            @setTarget ""
    job:(game,playerid,query)->
        if @target?
            return game.i18n.t "error.common.alreadyUsed"
        arr=[]
        try
          arr=JSON.parse @flag
        catch error
          arr=[]
        unless arr instanceof Array
            arr=[]
        if playerid in arr
            # 既に呪いをかけたことがある
            return game.i18n.t "roles:Spellcaster.noSelectTwice"
        @setTarget playerid
        pl=game.getPlayer playerid
        pl.touched game,@id
        log=
            mode:"skill"
            to:@id
            comment: game.i18n.t "roles:Spellcaster.select", {name: @name, target: pl.name}
        splashlog game.id,game,log
        arr.push playerid
        @setFlag JSON.stringify arr
        null
    midnight:(game,midnightSort)->
        t=game.getPlayer @target
        return unless t?
        return if t.dead
        log=
            mode:"skill"
            to:t.id
            comment: game.i18n.t "roles:Spellcaster.cursed", {name: t.name}
        splashlog game.id,game,log

        # 複合させる

        newpl=Player.factory null, game, t,null,Muted  # 黙る人
        t.transProfile newpl
        t.transform game,newpl,true
class Lycan extends Player
    type:"Lycan"
    fortuneResult: FortuneResult.werewolf
class Priest extends Player
    type:"Priest"
    midnightSort:70
    formType: FormType.optionalOnce
    hasDeadResistance:->true
    sleeping:->true
    jobdone:->@flag?
    sunset:(game)->
        @setTarget null
    job:(game,playerid,query)->
        if @flag?
            return game.i18n.t "error.common.alreadyUsed"
        if @target?
            return game.i18n.t "error.common.alreadyUsed"
        pl=game.getPlayer playerid
        unless pl?
            return game.i18n.t "error.common.nonexistentPlayer"
        if playerid==@id
            return game.i18n.t "error.common.noSelectSelf"
        pl.touched game,@id

        @setTarget playerid
        @setFlag "done"    # すでに能力を発動している
        log=
            mode:"skill"
            to:@id
            comment: game.i18n.t "roles:Priest.select", {name: @name, target: pl.name}
        splashlog game.id,game,log
        null
    midnight:(game,midnightSort)->
        # 複合させる
        pl = game.getPlayer @target
        unless pl?
            return

        newpl=Player.factory null, game, pl,null,HolyProtected # 守られた人
        pl.transProfile newpl
        newpl.cmplFlag=@id # 護衛元
        pl.transform game,newpl,true

        null
class Prince extends Player
    type:"Prince"
    hasDeadResistance:->true
    die:(game,found)->
        if found=="punish" && !@flag?
            # 処刑された
            @setFlag "used"    # 能力使用済
            log=
                mode:"system"
                comment: game.i18n.t "roles:Prince.cancel", {name: @name, jobname: @jobname}
            splashlog game.id,game,log
            @addGamelog game,"princeCO"
        else
            super
# Paranormal Investigator
class PI extends Diviner
    type:"PI"
    formType: FormType.optionalOnce
    sleeping:->true
    jobdone:->@target? || @flag.length > 0
    job:(game,playerid)->
        @setTarget playerid
        pl=game.getPlayer playerid
        pl.touched game,@id
        log=
            mode:"skill"
            to:@id
            comment: game.i18n.t "roles:PI.select", {name: @name, target: pl.name}
        splashlog game.id,game,log
        if game.rule.divineresult=="immediate"
            @dodivine game
            @showdivineresult game
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
            rs=pls.map((x)->x?.getFortuneResult())
                .filter((x)->x != FortuneResult.human)    # 村人以外
                .map((x)-> game.i18n.t "roles:fortune.#{x}")
            # 重複をとりのぞく
            nrs=[]
            rs.forEach (x,i)->
                if rs.indexOf(x,i+1)<0
                    nrs.push x
            tpl=game.getPlayer @target

            resultstring=if nrs.length>0
                @addGamelog game,"PIdivine",true,tpl.id
                game.i18n.t "roles:PI.found", {name: @name, target: tpl.name, result: nrs.join ","}
            else
                @addGamelog game,"PIdivine",false,tpl.id
                game.i18n.t "roles:PI.notfound", {name: @name, target: tpl.name}

            @setFlag @flag.concat {
                player:game.getPlayer(@target).publicinfo()
                result:resultstring
            }
    showdivineresult:(game)->
        r=@flag[@flag.length-1]
        return unless r?
        log=
            mode:"skill"
            to:@id
            comment:r.result
        splashlog game.id,game,log
class Sorcerer extends Diviner
    type:"Sorcerer"
    team:"Werewolf"
    sleeping:->@target?
    job:(game,playerid)->
        @setTarget playerid
        pl=game.getPlayer playerid
        pl.touched game,@id
        log=
            mode:"skill"
            to:@id
            comment: game.i18n.t "roles:Sorcerer.select", {name: @name, target: pl.name}
        splashlog game.id,game,log
        if game.rule.divineresult=="immediate"
            @dodivine game
            @showdivineresult game
        null
    #占い実行
    dodivine:(game)->
        pl=game.getPlayer @target
        if pl?
            resultstring=if pl.isJobType "Diviner"
                game.i18n.t "roles:Sorcerer.found", {name: @name, target: pl.name}
            else
                game.i18n.t "roles:Sorcerer.notfound", {name: @name, target: pl.name}
            @setFlag @flag.concat {
                player: game.getPlayer(@target).publicinfo()
                result: resultstring
            }
    showdivineresult:(game)->
        r=@flag[@flag.length-1]
        return unless r?
        log=
            mode:"skill"
            to:@id
            comment:r.result
        splashlog game.id,game,log
    divineeffect:(game)->
class Doppleganger extends Player
    type:"Doppleganger"
    formType: FormType.optional
    sleeping:->true
    jobdone:-> @flag?.done
    team:"" # 最初はチームに属さない!
    job:(game,playerid)->
        pl=game.getPlayer playerid
        unless pl?
            return game.i18n.t "error.common.nonexistentPlayer"
        if pl.id==@id
            return game.i18n.t "error.common.noSelectSelf"
        if pl.dead
            return game.i18n.t "error.common.alreadyDead"
        pl.touched game,@id
        log=
            mode:"skill"
            to:@id
            comment: game.i18n.t "roles:Doppleganger.select", {name: @name, target: game.getPlayer(playerid).name}
        splashlog game.id,game,log
        # ID of player object which will transform.
        # null if this is the first transform.
        ownerid = @flag?.ownerid ? null
        @setFlag {
            done: true
            ownerid: ownerid
            target: playerid  # ドッペルゲンガー先
        }
        null
    beforebury:(game,type,deads)->
        # 対象が死んだら移る
        targetid = @flag?.target
        if deads.some((x)=> x.id == targetid)
            p=game.getPlayer targetid  # その人

            newplmain=Player.factory p.type, game
            @transProfile newplmain
            @transferData newplmain

            # まだドッペルゲンガーできる
            sub=Player.factory "Doppleganger", game
            @transProfile sub

            newpl=Player.factory null, game, newplmain,sub,Complex    # 合体
            @transProfile newpl

            # 同じところが変わる
            sub.setFlag {
                done: false
                ownerid: newpl.objid
                target: null
            }

            # 変化する
            ownerid = @flag.ownerid
            if ownerid?
                # 自分は消滅してその人を変化させる
                me=game.getPlayer @id
                transpl = me.accessByObjid ownerid
                unless transpl?
                    # ???
                    return
                transpl.transform game, newpl, false
                @uncomplex game, true
            else
                # 初めてなので自分が変化する
                @transform game, newpl, false

            log=
                mode:"skill"
                to:@id
                comment: game.i18n.t "system.changeRole", {name: @name, result: newpl.getJobDisp()}
            splashlog game.id,game,log
            @addGamelog game,"dopplemove",newpl.type,newpl.id


            game.ss.publish.user newpl.realid,"refresh",{id:game.id}
class CultLeader extends Player
    type:"CultLeader"
    team:"Cult"
    midnightSort:100
    formType: FormType.required
    sleeping:->@target?
    sunset:(game)->
        super
        @setTarget null
        if @scapegoat
            # 身代わり君の自動占い
            r=Math.floor Math.random()*game.players.length
            @job game,game.players[r].id,{}
    job:(game,playerid)->
        @setTarget playerid
        pl=game.getPlayer playerid
        pl.touched game,@id
        log=
            mode:"skill"
            to:@id
            comment: game.i18n.t "roles:CultLeader.select", {name: @name, target: pl.name}
        splashlog game.id,game,log
        @addGamelog game,"brainwash",null,playerid
        null
    midnight:(game,midnightSort)->
        t=game.getPlayer @target
        return unless t?
        return if t.dead
        log=
            mode:"skill"
            to:t.id
            comment: game.i18n.t "roles:CultLeader.become", {name: t.name}

        # 信者
        splashlog game.id,game,log
        newpl=Player.factory null, game, t,null,CultMember    # 合体
        t.transProfile newpl
        t.transform game,newpl,true

    makejobinfo:(game,result)->
        super
        # 信者は分かる
        result.cultmembers=game.players.filter((x)->x.isCult()).map (x)->
            x.publicinfo()
class Vampire extends Player
    type:"Vampire"
    team:"Vampire"
    willDieWerewolf:false
    fortuneResult: FortuneResult.vampire
    midnightSort:100
    formType: FormType.required
    sleeping:(game)->@target? || game.day==1
    isHuman:->false
    isVampire:->true
    hasDeadResistance:->true
    sunset:(game)->
        @setTarget null
        if game.day>1 && @scapegoat
            targets=game.players.filter (x)->!x.dead
            r=Math.floor Math.random()*targets.length
            if @job game,targets[r].id,{}
                @setTarget ""
    job:(game,playerid,query)->
        # 襲う先
        if @target?
            return game.i18n.t "error.common.alreadyUsed"
        if game.day==1
            return game.i18n.t "error.common.cannotUseSkillNow"
        @setTarget playerid
        pl=game.getPlayer playerid
        pl.touched game,@id
        log=
            mode:"skill"
            to:@id
            comment: game.i18n.t "roles:Vampire.select", {name: @name, target: pl.name}
        splashlog game.id,game,log
        null
    midnight:(game,midnightSort)->
        t=game.getPlayer @target
        return unless t?
        return if t.dead
        t.die game,"vampire",@id
        # 襲撃先に逃げていた逃亡者を探して殺す
        for x in game.players
            if x.dead
                continue
            runners = x.accessByJobTypeAll "Fugitive"
            for pl in runners
                if pl.target == t.id
                    x.die game, "vampire2", @id
    makejobinfo:(game,result)->
        super
        # ヴァンパイアが分かる
        result.vampires=game.players.filter((x)->x.isVampire()).map (x)->
            x.publicinfo()
class LoneWolf extends Werewolf
    type:"LoneWolf"
    team:"LoneWolf"
    isWinner:(game,team)->team==@getTeam() && !@dead
class Cat extends Poisoner
    type:"Cat"
    midnightSort:100
    formType: FormType.optional
    isReviver:->true
    sunset:(game)->
        @setTarget (if game.day<2 then "" else null)
        if game.players.every((x)->!x.dead)
            @setTarget ""  # 誰も死んでいないなら能力発動しない
        if !@target? && @scapegoat
            # 身代わり君の自動占い
            r=Math.floor Math.random()*game.players.length
            if @job game,game.players[r].id,{}
                @setTarget ""
    job:(game,playerid)->
        if game.day<2
            # まだ発動できない
            return game.i18n.t "error.common.cannotUseSkillNow"
        pl=game.getPlayer playerid
        unless pl?
            return game.i18n.t "error.common.nonexistentPlayer"
        unless pl.dead
            return game.i18n.t "error.common.notDead"
        @setTarget playerid
        pl.touched game,@id

        log=
            mode:"skill"
            to:@id
            comment: game.i18n.t "roles:Cat.select", {name: @name, target: pl.name}
        splashlog game.id,game,log
        null
    jobdone:->@target?
    sleeping:->true
    midnight:(game,midnightSort)->
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
    deadnight:(game,midnightSort)->
        @setTarget @id
        @midnight game, midnightSort

    job_target:Player.JOB_T_DEAD
    makejobinfo:(game,result)->
        super
class Witch extends Player
    type:"Witch"
    midnightSort:100
    formType: FormType.optional
    isReviver:->!@dead
    job_target:Player.JOB_T_ALIVE | Player.JOB_T_DEAD   # 死人も生存も
    sleeping:->true
    jobdone:->@target? || (@flag in [3,5,6])
    # @flag:ビットフラグ 1:殺害1使用済 2:殺害2使用済 4:蘇生使用済 8:今晩蘇生使用 16:今晩殺人使用
    constructor:->
        super
        @setFlag 0 # 発送済みかどうか
    sunset:(game)->
        @setTarget null
        unless @flag
            @setFlag 0
        else
            # jobだけ実行してmidnightがなかったときの処理
            if @flag & 8
                @setFlag @flag^8
            if @flag & 16
                @setFlag @flag^16
        if game.day == 1
            @setTarget ""
    job:(game,playerid,query)->
        # query.Witch_drug
        pl=game.getPlayer playerid
        unless pl?
            return game.i18n.t "error.common.nonexistentPlayer"
        if pl.id==@id
            return game.i18n.t "error.common.noSelectSelf"

        if query.Witch_drug=="kill"
            # 毒薬
            if game.day==1
                return game.i18n.t "error.common.cannotUseSkillNow"
            if (@flag&3)==3
                # 蘇生薬は使い切った
                return game.i18n.t "error.common.alreadyUsed"
            else if (@flag&4) && (@flag&3)
                # すでに薬は2つ使っている
                return game.i18n.t "error.common.alreadyUsed"

            if pl.dead
                return game.i18n.t "error.common.alreadyDead"

            # 薬を使用
            pl.touched game,@id
            # flagを書き換える
            fl = @flag
            fl |= 16 # 今晩殺害使用
            if (fl&1)==0
                fl |= 1  # 1つ目
            else
                fl |= 2  # 2つ目
            @setFlag fl
            @setTarget playerid
            log=
                mode:"skill"
                to:@id
                comment: game.i18n.t "roles:Witch.selectPoison", {name: @name, target: pl.name}
            splashlog game.id,game,log
        else
            # 蘇生薬
            fl = @flag
            if (fl&3)==3 || (fl&4)
                return game.i18n.t "error.common.alreadyUsed"

            if !pl.dead
                return game.i18n.t "error.common.invalidSelection"

            # 薬を使用
            pl.touched game,@id
            fl |= 12
            @setFlag fl
            @setTarget playerid
            log=
                mode:"skill"
                to:@id
                comment: game.i18n.t "roles:Witch.selectRevival", {name: @name, target: pl.name}
            splashlog game.id,game,log
        null
    midnight:(game,midnightSort)->
        return unless @target?
        pl=game.getPlayer @target
        return unless pl?

        if @flag & 8
            # 蘇生
            @setFlag @flag^8
            # 蘇生 目を覚まさせる
            @addGamelog game,"witchraise",null,pl.id
            pl.revive game
        else if @flag & 16
            # 殺害
            @setFlag @flag^16
            @addGamelog game,"witchkill",null,pl.id
            pl.die game,"witch"
class Oldman extends Player
    type:"Oldman"
    midnight:(game,midnightSort)->
        # 夜の終わり
        wolves=game.players.filter (x)->x.isWerewolf() && !x.dead
        if wolves.length*2<=game.day
            # 寿命
            @die game,"infirm"
class Tanner extends Player
    type:"Tanner"
    team:""
    die:(game,found)->
        if found in ["gone-day","gone-night"]
            # 突然死はダメ
            @setFlag "gone"
        super
    isWinner:(game,team)->@dead && @flag!="gone"
class OccultMania extends Player
    type:"OccultMania"
    midnightSort:100
    formType: FormType.required
    sleeping:(game)->@target? || game.day<2
    sunset:(game)->
        @setTarget (if game.day>=2 then null else "")
        if !@target? && @scapegoat
            # 身代わり君の自動占い
            r=Math.floor Math.random()*game.players.length
            if @job game,game.players[r].id,{}
                @setTarget ""
    job:(game,playerid)->
        if game.day<2
            # まだ発動できない
            return game.i18n.t "error.common.cannotUseSkillNow"
        @setTarget playerid
        pl=game.getPlayer playerid
        unless pl?
            return game.i18n.t "error.common.nonexistentPlayer"
        if pl.dead
            return game.i18n.t "error.common.alreadyDead"
        pl.touched game,@id

        log=
            mode:"skill"
            to:@id
            comment: game.i18n.t "roles:OccultMania.select", {name: @name, target: pl.name}
        splashlog game.id,game,log
        null
    midnight:(game,midnightSort)->
        p=game.getPlayer @target
        return unless p?
        # 変化先決定
        type="Human"
        if p.isJobType "Diviner"
            type="Diviner"
        else if p.isWerewolf()
            type="Werewolf"

        newpl=Player.factory type, game
        @transProfile newpl
        @transferData newpl
        newpl.sunset game   # 初期化してあげる
        @transform game,newpl,false

        log=
            mode:"skill"
            to:@id
            comment: game.i18n.t "system.changeRole", {name: @name, result: newpl.getJobDisp()}
        splashlog game.id,game,log

        game.ss.publish.user newpl.realid,"refresh",{id:game.id}
        null

# 狼の子
class WolfCub extends Werewolf
    type:"WolfCub"
    dying:(game,found)->
        super
        game.werewolf_flag.push "WolfCub"
# 囁き狂人
class WhisperingMad extends Fanatic
    type:"WhisperingMad"

    getSpeakChoice:(game)->
        ["werewolf"].concat super
    isListener:(game,log)->
        if log.mode=="werewolf"
            true
        else super
class Lover extends Player
    type:"Lover"
    team:"Friend"
    formType: FormType.required
    constructor:->
        super
        @setTarget null    # 相手
    sunset:(game)->
        unless @flag?
            if @scapegoat
                # 身代わりくんは求愛しない
                @setFlag true
                @setTarget ""
            else
                @setTarget null
    sleeping:(game)->@flag || @target?
    job:(game,playerid,query)->
        if @target?
            return game.i18n.t "error.common.alreadyUsed"
        if @flag
            return game.i18n.t "error.common.alreadyUsed"

        pl=game.getPlayer playerid
        unless pl?
            return game.i18n.t "error.common.nonexistentPlayer"
        if playerid==@id
            return game.i18n.t "error.common.noSelectSelf"
        pl.touched game,@id

        @setTarget playerid
        @setFlag true
        # 恋人二人が決定した

        mytop = game.getPlayer @id
        plpls = [mytop, pl]
        for x,i in plpls
            newpl=Player.factory null, game, x,null,Friend # 恋人だ！
            x.transProfile newpl
            x.transform game,newpl,true  # 入れ替え
            newpl.cmplFlag=plpls[1-i].id
        log=
            mode:"skill"
            to:@id
            comment: game.i18n.t "roles:Lover.select", {name: @name, target: pl.name}
        splashlog game.id,game,log
        log=
            mode:"skill"
            to:newpl.id
            comment: game.i18n.t "roles:Lover.become", {name: pl.name}
        splashlog game.id,game,log
        # 2人とも更新する
        for pl in [mytop, pl]
            game.ss.publish.user pl.id,"refresh",{id:game.id}

        null


# 子分選択者
class MinionSelector extends Player
    type:"MinionSelector"
    team:"Werewolf"
    formType: FormType.required
    sleeping:(game)->@target? || game.day>1 # 初日のみ
    sunset:(game)->
        @setTarget (if game.day==1 then null else "")
        if !@target? && @scapegoat
            # 身代わり君の自動占い
            r=Math.floor Math.random()*game.players.length
            if @job game,game.players[r].id,{}
                @setTarget ""

    job:(game,playerid)->
        if game.day!=1
            # まだ発動できない
            return game.i18n.t "error.common.cannotUseSkillNow"
        @setTarget playerid
        pl=game.getPlayer playerid
        unless pl?
            return game.i18n.t "error.common.nonexistentPlayer"
        if pl.dead
            return game.i18n.t "error.common.alreadyDead"

        # 複合させる
        newpl=Player.factory null, game, pl,null,WolfMinion    # WolfMinion
        pl.transProfile newpl
        pl.transform game,newpl,true
        log=
            mode:"wolfskill"
            comment: game.i18n.t "roles:MinionSelector.select", {name: @name, target: pl.name, jobname: pl.getMainJobname()}
        splashlog game.id,game,log

        log=
            mode:"skill"
            to:pl.id
            comment: game.i18n.t "roles:MinionSelector.become", {name: pl.name}
        splashlog game.id,game,log

        null
# 盗人
class Thief extends Player
    type:"Thief"
    team:""
    formType: FormType.required
    sleeping:(game)->@target? || game.day>1
    sunset:(game)->
        @setTarget (if game.day==1 then null else "")
        # @flag:JSONの役職候補配列
        if !target?
            arr=JSON.parse(@flag ? '["Human"]')
            jobnames=arr.map (x)->
                testpl = Player.factory x, game
                testpl.getJobDisp()
            log=
                mode:"skill"
                to:@id
                comment: game.i18n.t "roles:Thief.candidates", {name: @name, jobnames: jobnames.join(",")}
            splashlog game.id,game,log
            if @scapegoat
                # 身代わり君
                r=Math.floor Math.random()*arr.length
                @job game,arr[r]
    job:(game,target)->
        @setTarget target
        unless jobs[target]?
            return game.i18n.t "error.common.invalidSelection"

        newpl=Player.factory target, game
        @transProfile newpl
        @transferData newpl
        newpl.sunset game
        @transform game,newpl,false
        log=
            mode:"skill"
            to:@id
            comment: game.i18n.t "system.changeRole", {name: @name, result: newpl.getJobDisp()}
        splashlog game.id,game,log

        game.ss.publish.user newpl.id,"refresh",{id:game.id}
        null
    makeJobSelection:(game)->
        if Phase.isNight(game.phase)
            # 役職から選択
            arr=JSON.parse(@flag ? '["Human"]')
            arr.map (x)->
                testpl = Player.factory x, game
                {
                    name:testpl.getJobDisp()
                    value:x
                }
        else super
class Dog extends Player
    type:"Dog"
    fortuneResult: FortuneResult.werewolf
    psychicResult: PsychicResult.werewolf
    midnightSort:80
    formType: FormType.optionalOnce
    hasDeadResistance:->true
    sunset:(game)->
        super
        @setTarget null    # 1日目:飼い主選択 選択後:かみ殺す人選択
        if !@flag?   # 飼い主を決めていない
            if @scapegoat
                alives=game.players.filter (x)=>!x.dead && x.id!=@id
                if alives.length>0
                    r=Math.floor Math.random()*alives.length
                    pl=alives[r]
                    @job game,pl.id,{}
                else
                    @setFlag ""
                    @setTarget ""
    sleeping:->@flag?
    jobdone:->@target?
    job:(game,playerid,query)->
        if @target?
            return game.i18n.t "error.common.alreadyUsed"

        unless @flag?
            pl=game.getPlayer playerid
            unless pl?
                return game.i18n.t "error.common.invalidSelection"
            if pl.id==@id
                return game.i18n.t "error.common.noSelectSelf"
            pl.touched game,@id
            # 飼い主を選択した
            log=
                mode:"skill"
                to:@id
                comment: game.i18n.t "roles:Dog.select", {name: @name, target: pl.name}
            splashlog game.id,game,log
            @setFlag playerid  # 飼い主
            @setTarget ""  # 襲撃対象はなし
        else
            # 襲う
            pl=game.getPlayer @flag
            @setTarget @flag
            log=
                mode:"skill"
                to:@id
                comment: game.i18n.t "roles:Dog.attack", {name: @name, target: pl.name}
            splashlog game.id,game,log
        null
    midnight:(game,midnightSort)->
        if @flag? && !@target?
            # 飼い主を護衛する
            pl=game.getPlayer @flag
            if pl?
                if pl.dead
                    # もう死んでるじゃん
                    @setTarget ""  # 洗濯済み
                else
                    newpl=Player.factory null, game, pl,null,Guarded   # 守られた人
                    pl.transProfile newpl
                    newpl.cmplFlag=@id  # 護衛元cmplFlag
                    pl.transform game,newpl,true
        else if @target?
            # 殺害
            pl=game.getPlayer @target
            return unless pl?

            @addGamelog game,"dogkill",pl.type,pl.id
            pl.die game,"dog"
            pl.touched game,@id
        null
    makejobinfo:(game,result)->
        super
        result.forms = result.forms.filter (obj)-> obj.type != "Dog"
        if !@jobdone(game) && Phase.isNight(game.phase)
            if @flag?
                # 飼い主いる
                pl=game.getPlayer @flag
                if pl?
                    if !pl.read
                        result.open.push "Dog1"
                        result.forms.push {
                            type: "Dog1"
                            options: []
                            formType: FormType.optionalOnce
                            objid: @objid
                        }
                    result.dogOwner=pl.publicinfo()

            else
                result.open.push "Dog2"
                result.forms.push {
                    type: "Dog2"
                    options: @makeJobSelection game
                    formType: FormType.required
                    objid: @objid
                }
    makeJobSelection:(game)->
        # 噛むときは対象選択なし
        if Phase.isNight(game.phase) && @flag?
            []
        else super
class Dictator extends Player
    type:"Dictator"
    formType: FormType.optionalOnce
    sleeping:->true
    jobdone:(game)->@flag? || !Phase.isDay(game.phase)
    chooseJobDay:(game)->true
    job:(game,playerid,query)->
        if @flag?
            return game.i18n.t "error.common.alreadyUsed"
        unless Phase.isDay(game.phase)
            return game.i18n.t "error.common.cannotUseSkillNow"
        pl=game.getPlayer playerid
        unless pl?
            return game.i18n.t "error.common.nonexistentPlayer"
        pl.touched game,@id
        @setTarget playerid    # 処刑する人
        log=
            mode:"system"
            comment: game.i18n.t "roles:Dictator.select", {name: @name, target: pl.name}
        splashlog game.id,game,log
        @setFlag true  # 使用済
        # その場で殺す!!!
        pl.die game,"punish",[@id]
        # XXX executeの中と同じことが書いてある
        game.bury "punish"
        return if game.rule.hunter_lastcheck == "no" && game.judge()
        # 次のターンへ移行
        unless game.hunterCheck("nextturn")
            game.nextturn()
        if game.rule.hunter_lastcheck == "yes"
            game.judge()
        return null
class SeersMama extends Player
    type:"SeersMama"
    sleeping:->true
    sunset:(game)->
        unless @flag
            # まだ能力を実行していない
            # 占い師を探す
            divs = game.players.filter (pl)->pl.isJobType "Diviner"
            divsstr=if divs.length>0
                game.i18n.t "roles:SeersMama.result", {name: @name, results: divs.map((x)->x.name).join(','), count: divs.length}
            else
                game.i18n.t "roles:SeersMama.resultNone", {name: @name}
            log=
                mode:"skill"
                to:@id
                comment: divsstr
            splashlog game.id,game,log
            @setFlag true  #使用済
class Trapper extends Player
    type:"Trapper"
    midnightSort:81
    formType: FormType.required
    hasDeadResistance:->true
    sleeping:->@target?
    sunset:(game)->
        @setTarget null
        if game.day==1
            # 一日目は護衛しない
            @setTarget ""  # 誰も守らない
        else if @scapegoat
            # 身代わり君の自動占い
            targets = game.players.filter (pl)-> !pl.dead
            if targets.length == 0
                @setTarget ""
                return
            r=Math.floor Math.random()*targets.length
            if @job game,targets[r].id,{}
                @sunset game
    job:(game,playerid)->
        unless playerid==@id && game.rule.guardmyself!="ok"
            if playerid==@flag
                # 前も護衛した
                return game.i18n.t "roles:Guard.noGuardSame"
            @setTarget playerid
            @setFlag playerid
            pl=game.getPlayer(playerid)
            pl.touched game,@id
            log=
                mode:"skill"
                to:@id
                comment: game.i18n.t "roles:Trapper.select", {name: @name, target: pl.name}
            splashlog game.id,game,log
            null
        else
            return game.i18n.t "error.common.noSelectSelf"
    midnight:(game,midnightSort)->
        # 複合させる
        pl = game.getPlayer @target
        unless pl?
            return
        newpl=Player.factory null, game, pl,null,TrapGuarded   # 守られた人
        pl.transProfile newpl
        newpl.cmplFlag=@id  # 護衛元cmplFlag
        pl.transform game,newpl,true
        null
class WolfBoy extends Madman
    type:"WolfBoy"
    midnightSort:90
    formType: FormType.optional
    sleeping:->true
    jobdone:->@target?
    sunset:(game)->
        @setTarget null
    job:(game,playerid)->
        @setTarget playerid
        pl=game.getPlayer playerid
        pl.touched game,@id
        log=
            mode:"skill"
            to:@id
            comment: game.i18n.t "roles:WolfBoy.select", {name: @name, target: pl.name}
        splashlog game.id,game,log
        null
    midnight:(game,midnightSort)->
        # 複合させる
        pl = game.getPlayer @target
        unless pl?
            return
        newpl=Player.factory null, game, pl,null,Lycanized
        pl.transProfile newpl
        newpl.cmplFlag=@id  # 護衛元cmplFlag
        pl.transform game,newpl,true
        null
class Hoodlum extends Player
    type:"Hoodlum"
    team:""
    formType: FormType.required
    constructor:->
        super
        @setFlag "[]"  # 殺したい対象IDを入れておく
        @setTarget null
    sunset:(game)->
        unless @target?
            # 2人選んでもらう
            @setTarget null
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
            return game.i18n.t "error.common.alreadyUsed"
        pl=game.getPlayer playerid
        unless pl?
            return game.i18n.t "error.common.nonexistentPlayer"
        plids=JSON.parse(@flag||"[]")
        if pl.id in plids
            # 既にいる
            return game.i18n.t "roles:Hoodlum.alreadySelected", {name: pl.name}
        plids.push pl.id
        @setFlag JSON.stringify plids
        log=
            mode:"skill"
            to:@id
            comment: game.i18n.t "roles:Hoodlum.select", {name: @name, target: pl.name}
        splashlog game.id,game,log
        if plids.length>=2
            @setTarget ""
        else
            # 2人目を選んでほしい
            @setTarget null
        null

    isWinner:(game,team)->
        if @dead
            # 死んでたらだめ
            return false
        pls=JSON.parse(@flag||"[]").map (id)->game.getPlayer id
        return pls.every (pl)->pl?.dead==true
class QuantumPlayer extends Player
    type:"QuantumPlayer"
    midnightSort:100
    formType: FormType.required
    getJobname:->
        flag=JSON.parse(@flag||"{}")
        jobname=null
        if flag.Human==1
            jobname = @game.i18n.t "roles:jobname.Human"
        else if flag.Diviner==1
            jobname = @game.i18n.t "roles:jobname.Diviner"
        else if flag.Werewolf==1
            jobname = @game.i18n.t "roles:jobname.Werewolf"

        numstr=""
        if flag.number?
            numstr="##{flag.number}"
        ret=if jobname?
            "#{@game.i18n.t "roles:jobname.QuantumPlayer"}#{numstr}（#{jobname}）"
        else
            "#{@game.i18n.t "roles:jobname.QuantumPlayer"}#{numstr}"
        if @originalJobname != ret
            # 収束したぞ!
            @setOriginalJobname ret
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
        if obj.Werewolf==0 || (game.rule.quantumwerewolf_firstattack!="on" && game.day==1)
            tarobj.Werewolf=""

        @setTarget JSON.stringify tarobj
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
        unless pl?
            return game.i18n.t "error.common.nonexistentPlayer"
        if query.jobtype=="_Quantum_Diviner" && !tarobj.Diviner?
            tarobj.Diviner=playerid
            log=
                mode:"skill"
                to:@id
                comment: game.i18n.t "roles:Diviner.select", {name: @name, target: pl.name}
            splashlog game.id,game,log
        else if query.jobtype=="_Quantum_Werewolf" && !tarobj.Werewolf?
            if @id==playerid
                return game.i18n.t "error.common.noSelectSelf"
            tarobj.Werewolf=playerid
            log=
                mode:"skill"
                to:@id
                comment: game.i18n.t "roles:Werewolf.select", {name: @name, target: pl.name}
            splashlog game.id,game,log
        else
            return game.i18n.t "error.common.invalidSelection"
        @setTarget JSON.stringify tarobj

        null
    midnight:(game,midnightSort)->
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
                            comment: game.i18n.t "roles:Diviner.resultlog", {name: @name, target: pl.name, result: game.i18n.t "roles:fortune.werewolf"}
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
                            comment: game.i18n.t "roles:Diviner.resultlog", {name: @name, target: pl.name, result: game.i18n.t "roles:fortune.human"}
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
                        comment: game.i18n.t "roles:QuantumPlayer.cannotDivine", {name: @name}
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
        # QuantumPlayer has custom forms
        result.forms = result.forms.filter (obj)-> obj.type != "QuantumPlayer"
        tarobj=JSON.parse(@target||"{}")
        unless tarobj.Diviner?
            result.open.push "_Quantum_Diviner"
            result.forms.push {
                type: "_Quantum_Diviner"
                options: @makeJobSelection game
                formType: FormType.required
                objid: @objid
            }
        unless tarobj.Werewolf?
            result.open.push "_Quantum_Werewolf"
            result.forms.push {
                type: "_Quantum_Werewolf"
                options: @makeJobSelection game
                formType: FormType.required
                objid: @objid
            }
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
    sleeping:->true
    isReviver:->!@dead || @flag?
    dying:(game,found,from)->
        super
        if found=="werewolf"
            # 狼に襲われた
            # 誰に襲われたか覚えておく
            @setFlag from
        else
            @setFlag null
    deadsunset:(game)->
        if @flag
            w=game.getPlayer @flag
            if w?.dead
                # 殺した狼が死んだ!復活する
                pl = game.getPlayer @id
                pl.revive game
    deadsunrise:(game)->
        # 同じ
        @deadsunset game

class Counselor extends Player
    type:"Counselor"
    midnightSort:100
    formType: FormType.optional
    sleeping:->true
    jobdone:->@target?
    sunset:(game)->
        @setTarget null
        if game.day==1
            # 一日目はカウンセリングできない
            @setTarget ""
    job:(game,playerid,query)->
        if @target?
            return game.i18n.t "error.common.alreadyUsed"
        @setTarget playerid
        pl=game.getPlayer playerid
        pl.touched game,@id
        log=
            mode:"skill"
            to:@id
            comment: game.i18n.t "roles:Counselor.select", {name: @name, target: pl.name}
        splashlog game.id,game,log
        null
    midnight:(game,midnightSort)->
        t=game.getPlayer @target
        return unless t?
        return if t.dead
        tteam = t.getTeam()
        if t.isWerewolf() && tteam != "Human"
            # 人狼とかヴァンパイアを襲ったら殺される
            @die game,"werewolf2"
            @addGamelog game,"counselKilled",t.type,@target
            return
        if t.isVampire() && tteam != "Human"
            @die game,"vampire2"
            @addGamelog game,"counselKilled",t.type,@target
            return
        if tteam!="Human"
            log=
                mode:"skill"
                to:t.id
                comment: game.i18n.t "roles:Counselor.rehabilitate", {name: t.name}
            splashlog game.id,game,log

            @addGamelog game,"counselSuccess",t.type,@target
            # 複合させる

            newpl=Player.factory null, game, t,null,Counseled  # カウンセリングされた
            t.transProfile newpl
            t.transform game,newpl,true
        else
            @addGamelog game,"counselFailure",t.type,@target
# 巫女
class Miko extends Player
    type:"Miko"
    midnightSort:71
    formType: FormType.optionalOnce
    hasDeadResistance:->true
    sleeping:->true
    jobdone:->!!@flag
    job:(game,playerid,query)->
        if @flag
            return game.i18n.t "error.common.alreadyUsed"
        @setTarget playerid
        log=
            mode:"skill"
            to:@id
            comment: game.i18n.t "roles:Miko.select", {name: @name}
        splashlog game.id,game,log
        @setFlag "using"
        null
    midnight:(game,midnightSort)->
        # 複合させる
        if @flag=="using"
            pl = game.getPlayer @id
            newpl=Player.factory null, game, pl,null,MikoProtected # 守られた人
            pl.transProfile newpl
            pl.transform game,newpl,true
            @setFlag "done"
        null
    makeJobSelection:(game)->
        # 夜は投票しない
        if Phase.isNight(game.phase)
            []
        else super
class GreedyWolf extends Werewolf
    type:"GreedyWolf"
    sleeping:(game)->game.werewolf_target_remain<=0 # 占いは必須ではない
    jobdone:(game)->game.werewolf_target_remain<=0 && (@flag || game.day==1)
    job:(game,playerid,query)->
        if query.jobtype!="GreedyWolf"
            # 人狼の仕事
            return super
        if @flag
            return game.i18n.t "error.common.alreadyUsed"
        @setFlag true
        if game.werewolf_target_remain+game.werewolf_target.length ==0
            return game.i18n.t "error.common.cannotUseSkillNow"
        log=
            mode:"wolfskill"
            comment: game.i18n.t "roles:GreedyWolf.select", {name: @name}
        splashlog game.id,game,log
        game.werewolf_target_remain++
        game.werewolf_flag.push "GreedyWolf_#{@id}"
        game.splashjobinfo game.players.filter (x)=>x.id!=@id && x.isWerewolf()
        null
    makejobinfo:(game,result)->
        super
        if Phase.isNight(game.phase)
            if @sleeping game
                # 襲撃は必要ない
                result.open = result.open?.filter (x)=>x!="_Werewolf"
            if !@flag && game.day>=2
                result.open?.push "GreedyWolf"
                result.forms.push {
                    type: "GreedyWolf"
                    options: []
                    formType: FormType.optionalOnce
                    objid: @objid
                }
    makeJobSelection:(game)->
        if Phase.isNight(game.phase) && @sleeping(game) && !@jobdone(game)
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
    sleeping:(game)->super && @flag?
    sunset:(game)->
        super
        if @scapegoat && !@flag?
            # 誘惑する
            hus=game.players.filter (x)->!x.dead && !x.isWerewolf()
            if hus.length>0
                r=Math.floor Math.random()*hus.length
                @job game,hus[r].id,{jobtype:"FascinatingWolf"}
            else
                @setFlag ""
    job:(game,playerid,query)->
        if query.jobtype!="FascinatingWolf"
            # 人狼の仕事
            return super
        if @flag
            return game.i18n.t "error.common.alreadyUsed"
        pl=game.getPlayer playerid
        unless pl?
            return game.i18n.t "error.common.nonexistentPlayer"
        pl.touched game,@id
        log=
            mode:"skill"
            to:@id
            comment: game.i18n.t "roles:FascinatingWolf.select", {name: @name, target: pl.name}
        @setFlag playerid
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
        unless pl.isHuman() && pl.getTeam()!="Werewolf"
            # 誘惑できない
            return

        newpl=Player.factory null, game, pl,null,WolfMinion    # WolfMinion
        pl.transProfile newpl
        pl.transform game,newpl,true
        log=
            mode:"skill"
            to:pl.id
            comment: game.i18n.t "roles:FascinatingWolf.affected", {name: pl.name}
        splashlog game.id,game,log
    makejobinfo:(game,result)->
        super
        if Phase.isNight(game.phase)
            unless @flag
                # 誘惑可能
                result.open.push "FascinatingWolf"
                result.forms.push {
                    type: "FascinatingWolf"
                    options: @makeJobSelection game
                    formType: FormType.required
                    objid: @objid
                }
class SolitudeWolf extends Werewolf
    type:"SolitudeWolf"
    sleeping:(game)-> !@flag || super
    isListener:(game,log)->
        if log.mode in ["werewolf","wolfskill"]
            # 狼の声は聞こえない（自分のスキルは除く）
            log.to? && isLogTarget(log.to, this)
        else super
    job:(game,playerid,query)->
        if !@flag
            return game.i18n.t "error.common.cannotUseSkillNow"
        super
    isAttacker:->!@dead && @flag
    sunset:(game)->
        wolves=game.players.filter (x)->x.isWerewolf()
        attackers=wolves.filter (x)->!x.dead && x.isAttacker()
        if !@flag && attackers.length==0
            # 襲えるやつ誰もいない
            @setFlag true
            # check whether succeed
            p=game.getPlayer @id
            if p.isAttacker()
                log=
                    mode:"skill"
                    to:@id
                    comment: game.i18n.t "roles:SolitudeWolf.turn", {name: @name}
                splashlog game.id,game,log
            else
                # try next sunset
                @setFlag false
        else if @flag && attackers.length>1
            # 複数いるのでやめる
            @setFlag false
            log=
                mode:"skill"
                to:@id
                comment: game.i18n.t "roles:SolitudeWolf.noturn", {name: @name}
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
    job:(game,playerid,query)->
        if query.jobtype!="ToughWolf"
            # 人狼の仕事
            return super
        if @flag
            return game.i18n.t "error.common.alreadyUsed"
        res=super
        if res?
            return res
        @setFlag true
        game.werewolf_flag.push "ToughWolf_#{@id}"
        tp=game.getPlayer playerid
        unless tp?
            return game.i18n.t "error.common.nonexistentPlayer"
        log=
            mode:"wolfskill"
            comment: game.i18n.t "roles:ToughWolf.select", {name: @name, target: tp.name}
        splashlog game.id,game,log
        null
    makejobinfo:(game, result)->
        super
        unless @sleeping game
            # 襲撃可能なときは一途な狼の能力も発動可能
            result.open.push @type
            result.forms.push {
                type: @type
                options: @makeJobSelection game
                formType: FormType.optionalOnce
                objid: @objid
            }

class ThreateningWolf extends Werewolf
    type:"ThreateningWolf"
    jobdone:(game)->
        if Phase.isDay(game.phase)
            @flag?
        else
            super
    chooseJobDay:(game)->true
    sunrise:(game)->
        super
        @setTarget null
    job:(game,playerid,query)->
        if query.jobtype!="ThreateningWolf"
            # 人狼の仕事
            return super
        if @flag
            return game.i18n.t "error.common.alreadyUsed"
        unless Phase.isDay(game.phase)
            return game.i18n.t "error.common.cannotUseSkillNow"
        pl=game.getPlayer playerid
        pl.touched game,@id
        unless pl?
            return game.i18n.t "error.common.nonexistentPlayer"
        @setTarget playerid
        @setFlag true
        log=
            mode:"skill"
            to:@id
            comment: game.i18n.t "roles:ThreateningWolf.select", {name: @name, target: pl.name}
        splashlog game.id,game,log
        null
    sunset:(game)->
        t=game.getPlayer @target
        unless t?
            return super
        if t.dead
            return super

        # 威嚇して能力無しにする
        @addGamelog game,"threaten",t.type,@target
        # 複合させる

        log=
            mode:"skill"
            to:t.id
            comment: game.i18n.t "roles:ThreateningWolf.affected", {name: t.name}
        splashlog game.id,game,log

        newpl=Player.factory null, game, t,null,Threatened  # カウンセリングされた
        t.transProfile newpl
        t.transform game,newpl,true

        super
    makejobinfo:(game, result)->
        super
        # XXX adjust form type.
        result.forms.forEach (obj)->
            if obj.type == "ThreateningWolf"
                obj.formType = FormType.optionalOnce
class HolyMarked extends Human
    type:"HolyMarked"
class WanderingGuard extends Player
    type:"WanderingGuard"
    midnightSort:80
    formType: FormType.required
    hasDeadResistance:->true
    sleeping:->@target?
    sunset:(game)->
        @setTarget null
        if game.day==1
            # 狩人は一日目護衛しない
            @setTarget ""  # 誰も守らない
            return

        fl=JSON.parse(@flag ? "[null]")
        # 前回の護衛
        alives=game.players.filter (x)=>
            if x.dead
                return false
            if x.id == @id && game.rule.guardmyself!="ok"
                return false
            if x.id in fl
                return false
            return true
        if alives.length == 0
            # もう護衛対象がいない
            @setTarget ""
            return

        if @scapegoat
            # 身代わり君の自動占い
            r=Math.floor Math.random()*alives.length
            if @job game,alives[r].id,{}
                @setTarget ""
    job:(game,playerid)->
        fl=JSON.parse(@flag ? "[null]")
        if playerid==@id && game.rule.guardmyself!="ok"
            return game.i18n.t "error.common.noSelectSelf"

        if playerid in fl
            return game.i18n.t "error.common.invalidSelection"
        @setTarget playerid
        if game.rule.consecutiveguard == "no"
            fl[0] = playerid
            @setFlag JSON.stringify fl

        # OK!
        pl=game.getPlayer(playerid)
        pl.touched game,@id
        log=
            mode:"skill"
            to:@id
            comment: game.i18n.t "roles:Guard.select", {name: @name, target: pl.name}
        splashlog game.id,game,log
        null
    midnight:(game,midnightSort)->
        # 複合させる
        pl = game.getPlayer @target
        unless pl?
            return
        newpl=Player.factory null, game, pl,null,Guarded   # 守られた人
        pl.transProfile newpl
        newpl.cmplFlag=@id  # 護衛元cmplFlag
        pl.transform game,newpl,true
        null
    beforebury:(game,type)->
        if type=="day"
            # 昼になったとき
            if game.players.filter((x)->x.dead && x.found).length==0
                # 誰も死ななかった!護衛できない
                pl=game.getPlayer @target
                if pl?
                    log=
                        mode:"skill"
                        to:@id
                        comment: game.i18n.t "roles:WanderingGuard.noGuardMode", {name: @name, target: pl.name}
                    splashlog game.id,game,log
                    fl=JSON.parse(@flag ? "[null]")
                    fl.push pl.id
                    @setFlag JSON.stringify fl
    makeJobSelection:(game)->
        if Phase.isNight(game.phase)
            fl=JSON.parse(@flag ? "[null]")
            a=super
            return a.filter (obj)->!(obj.value in fl)
        else
            return super
class ObstructiveMad extends Madman
    type:"ObstructiveMad"
    midnightSort:90
    formType: FormType.required
    sleeping:->@target?
    sunset:(game)->
        super
        @setTarget null
        if @scapegoat
            alives=game.players.filter (x)->!x.dead
            if alives.length>0
                r=Math.floor Math.random()*alives.length
                @job game,alives[r].id,{}
            else
                @setTarget ""
    job:(game,playerid)->
        @setTarget playerid
        pl=game.getPlayer playerid
        unless pl?
            return game.i18n.t "error.common.nonexistentPlayer"
        pl.touched game,@id
        log=
            mode:"skill"
            to:@id
            comment: game.i18n.t "roles:ObstructiveMad.select", {name: @name, target: pl.name}
        splashlog game.id,game,log
        null
    midnight:(game,midnightSort)->
        # 複合させる
        pl = game.getPlayer @target
        unless pl?
            return
        newpl=Player.factory null, game, pl,null,DivineObstructed
        pl.transProfile newpl
        newpl.cmplFlag=@id  # 邪魔元cmplFlag
        pl.transform game,newpl,true
        null
class TroubleMaker extends Player
    type:"TroubleMaker"
    midnightSort:100
    formType: FormType.optionalOnce
    sleeping:->true
    jobdone:->!!@flag
    makeJobSelection:(game)->
        # 夜は投票しない
        if Phase.isNight(game.phase)
            []
        else super
    job:(game,playerid)->
        if @flag
            return game.i18n.t "error.common.alreadyUsed"
        @setFlag "using"
        log=
            mode:"skill"
            to:@id
            comment: game.i18n.t "roles:TroubleMaker.select", {name: @name}
        splashlog game.id,game,log
        null
    midnight:(game,midnightSort)->
        # ここが無効化されたら発動しないように
        if @flag=="using"
            @setFlag "using2"
        null
    sunrise:(game)->
        if @flag=="using2"
            game.votingbox.addPunishedNumber 1
            # トラブルがおきた
            log=
                mode:"system"
                comment: game.i18n.t "roles:TroubleMaker.announce", {count: game.votingbox.remains}
            splashlog game.id,game,log
            @setFlag "done"
        else if @flag=="using"
            # 不発だった
            @setFlag "done"

    deadsunrise:(game)->@sunrise game

class FrankensteinsMonster extends Player
    type:"FrankensteinsMonster"
    die:(game,found)->
        super
        if found=="punish"
            # 処刑で死んだらもうひとり処刑できる
            game.votingbox.addPunishedNumber 1
    beforebury:(game,type,deads)->
        # 新しく死んだひとたちで村人陣営ひとたち
        founds=deads.filter (x)->x.getTeam()=="Human" && !x.isJobType("FrankensteinsMonster")
        # 吸収する
        thispl=this
        for pl in founds
            # extract absorbable jobs.
            extracted = []
            rec = (pl)->
                if pl.isComplex()
                    # main is absorbable.
                    rec pl.main
                    # if Chemical, absorb both.
                    if pl.cmplType == "Chemical" && pl.sub?
                        rec pl.sub
                else
                    extracted.push pl.type
            rec pl
            # List up name of extracted jobs.
            jobnames = extracted.map((e)-> game.i18n.t "roles:jobname.#{e}").join(game.i18n.t "roles:FrankensteinsMonster.separator")
            log=
                mode:"skill"
                to:@id
                comment: game.i18n.t "roles:FrankensteinsMonster.drain", {name: @name, target: pl.name, jobname: jobnames}
            splashlog game.id,game,log

            # 全て合成
            for newtype in extracted
                subpl = Player.factory newtype, game
                thispl.transProfile subpl

                newpl=Player.factory null, game, thispl,subpl,Complex    # 合成する
                thispl.transProfile newpl

                # 置き換える
                thispl.transform game,newpl,true
                thispl=newpl

                thispl.addGamelog game,"frankeneat",newtype,pl.id

        if founds.length>0
            game.splashjobinfo [thispl]
class BloodyMary extends Player
    type:"BloodyMary"
    formType: FormType.optional
    isReviver:->true
    getJobname:->if @flag then @jobname else @game.i18n.t("roles:BloodyMary.mary")
    getJobDisp:->@getJobname()
    getTypeDisp:->if @flag then @type else "Mary"
    sleeping:->true
    deadJobdone:(game)->
        if @target?
            true
        else if @flag=="punish"
            !(game.players.some (x)->!x.dead && x.getTeam()=="Human")
        else if @flag=="werewolf"
            if game.players.filter((x)->!x.dead && x.isWerewolf()).length>1
                !(game.players.some (x)->!x.dead && x.getTeam() in ["Werewolf","LoneWolf"])
            else
                # 狼が残り1匹だと何もない
                true
        else
            true

    dying:(game,found,from)->
        if found in ["punish","werewolf"]
            # 能力が…
            orig_jobname=@getJobname()
            @setFlag found
            if orig_jobname != @getJobname()
                # 変わった!
                before = game.i18n.t "roles:BloodyMary.mary"
                after = game.i18n.t "roles:jobname.BloodyMary"
                @setOriginalJobname @originalJobname.replace(after,before).replace(before,after)
        super
    sunset:(game)->
        @setTarget null
    deadsunset:(game)->
        @sunset game
    job:(game,playerid)->
        unless @flag in ["punish","werewolf"]
            return game.i18n.t "error.common.cannotUseSkillNow"
        pl=game.getPlayer playerid
        unless pl?
            return game.i18n.t "error.common.nonexistentPlayer"
        log=
            mode:"skill"
            to:@id
            comment: game.i18n.t "roles:BloodyMary.select", {name: @name, target: pl.name}
        splashlog game.id,game,log
        @setTarget playerid
        null
    # 呪い殺す!!!!!!!!!
    deadnight:(game,midnightSort)->
        pl=game.getPlayer @target
        unless pl?
            return
        pl.die game,"marycurse",@id
    # 蘇生できない
    revive:->
    isWinner:(game,team)->
        if @flag=="punish"
            team in ["Werewolf","LoneWolf"]
        else
            team==@getTeam()
    makeJobSelection:(game)->
        if Phase.isNight(game.phase)
            pls=[]
            if @flag=="punish"
                # 村人を……
                pls=game.players.filter (x)->!x.dead && x.getTeam()=="Human"
            else if @flag=="werewolf"
                # 人狼を……
                pls=game.players.filter (x)->!x.dead && x.getTeam() in ["Werewolf","LoneWolf"]
            return (for pl in pls
                {
                    name:pl.name
                    value:pl.id
                }
            )
        else super
    makejobinfo:(game,obj)->
        super
        if @flag && !("BloodyMary" in obj.open)
            obj.open.push "BloodyMary"
            obj.forms.push {
                type: "BloodyMary"
                options: @makeJobSelection game
                formType: FormType.optional
                objid: @objid
            }

class King extends Player
    type:"King"
    voteafter:(game,target)->
        super
        game.votingbox.votePower this,1
class PsychoKiller extends Madman
    type:"PsychoKiller"
    midnightSort:110
    constructor:->
        super
        @flag="[]"
    touched:(game,from)->
        # 殺すリストに追加する
        fl=try
               JSON.parse @flag || "[]"
           catch e
               []
        fl.push from
        @setFlag JSON.stringify fl
    sunset:(game)->
        @setFlag "[]"
    midnight:(game,midnightSort)->
        fl=try
               JSON.parse @flag || "[]"
           catch e
               []
        for id in fl
            pl=game.getPlayer id
            if pl? && !pl.dead
                pl.die game,"psycho",@id
        @setFlag "[]"
    deadnight:(game,midnightSort)->
        @midnight game, midnightSort
class SantaClaus extends Player
    type:"SantaClaus"
    midnightSort:100
    formType: FormType.required
    sleeping:->@target?
    constructor:->
        super
        @setFlag "[]"
    isWinner:(game,team)->@flag=="gone" || super
    sunset:(game)->
        # まだ届けられる人がいるかチェック
        if @flag == "gone"
            # もう届け終わった
            @setTarget ""
            return
        fl=JSON.parse(@flag ? "[]")
        if game.players.some((x)=>!x.dead && x.id!=@id && !(x.id in fl))
            @setTarget null
            if @scapegoat
                cons=game.players.filter((x)=>!x.dead && x.id!=@id && !(x.id in fl))
                if cons.length>0
                    r=Math.floor Math.random()*cons.length
                    @job game,cons[r].id,{}
                else
                    @setTarget ""
        else
            @setTarget ""
    sunrise:(game)->
        if @flag == "gone"
            # もう届け終わったのに生存している
            return
        # 全員に配ったかチェック
        fl=JSON.parse(@flag ? "[]")
        unless game.players.some((x)=>!x.dead && x.id!=@id && !(x.id in fl))
            # 村を去る
            @setFlag "gone"
            @die game,"spygone"

    job:(game,playerid)->
        if @flag=="gone"
            return game.i18n.t "error.common.cannotUseSkillNow"
        fl=JSON.parse(@flag ? "[]")
        if playerid == @id
            return game.i18n.t "error.common.noSelectSelf"
        if playerid in fl
            return game.i18n.t "roles:SantaClaus.noSelectTwice"
        pl=game.getPlayer playerid
        pl.touched game,@id
        unless pl?
            return game.i18n.t "eerror.common.nonexistentPlayer"
        @setTarget playerid
        log=
            mode:"skill"
            to:@id
            comment: game.i18n.t "roles:SantaClaus.select", {name: @name, target: pl.name}
        splashlog game.id,game,log
        fl.push playerid
        @setFlag JSON.stringify fl
        null
    midnight:(game,midnightSort)->
        return unless @target?
        pl=game.getPlayer @target
        return unless pl?
        return if @flag=="gone"

        # プレゼントを送る
        r=Math.random()
        settype=""
        if r<0.05
            # 毒だった
            log=
                mode:"skill"
                to:pl.id
                comment: game.i18n.t "roles:SantaClaus.deliver.poison", {name: pl.name}
            splashlog game.id,game,log
            pl.die game,"poison",@id
            @addGamelog game,"sendpresent","poison",pl.id
            return
        else if r<0.1
            settype="HolyMarked"
        else if r<0.15
            settype="Oldman"
        else if r<0.225
            settype="Priest"
        else if r<0.3
            settype="Miko"
        else if r<0.55
            settype="Diviner"
        else if r<0.8
            settype="Guard"
        else
            settype="Psychic"

        # 複合させる
        thing_name = game.i18n.t "roles:SantaClaus.thing.#{settype}"
        log=
            mode:"skill"
            to:pl.id
            comment: game.i18n.t "roles:SantaClaus.deliver._log", {name: pl.name, thing:thing_name}
        splashlog game.id,game,log

        # 複合させる
        sub=Player.factory settype, game   # 副を作る
        pl.transProfile sub
        newpl=Player.factory null, game, pl,sub,Complex    # Complex
        pl.transProfile newpl
        pl.transform game,newpl,true
        @addGamelog game,"sendpresent",settype,pl.id
#怪盗
class Phantom extends Player
    type:"Phantom"
    formType: FormType.required
    sleeping:->@target?
    sunset:(game)->
        if @flag==true
            # もう交換済みだ
            @setTarget ""
        else
            @setTarget null
            if @scapegoat
                rs=@makeJobSelection game
                if rs.length>0
                    r=Math.floor Math.random()*rs.length
                    @job game,rs[r].value,{
                        jobtype:@type
                    }
    makeJobSelection:(game)->
        if Phase.isNight(game.phase)
            res=[{
                name: game.i18n.t "roles:Phantom.noStealOption"
                value:""
            }]
            sup=super
            for obj in sup
                pl=game.getPlayer obj.value
                continue unless pl?
                continue if pl.scapegoat || pl.id == @id
                res.push obj
            return res
        else
            super
    job:(game,playerid)->
        @setTarget playerid
        if playerid==""
            # 交換しない
            log=
                mode:"skill"
                to:@id
                comment: game.i18n.t "roles:Phantom.selectNoSteal", {name: @name}
            splashlog game.id,game,log
            return
        pl=game.getPlayer playerid
        # 怪盗はサイコキラーを盗むことができる
        # pl.touched game,@id
        log=
            mode:"skill"
            to:@id
            comment: game.i18n.t "roles:Phantom.select", {name: @name, target: pl.name, jobname: pl.getMainJobDisp()}
        splashlog game.id,game,log
        @addGamelog game,"phantom",pl.type,playerid
        null
    sunrise:(game)->
        @setFlag true
        pl=game.getPlayer @target
        unless pl?
            return
        savedobj={}
        pl.makejobinfo game,savedobj
        flagobj={}
        # jobinfo表示のみ抜粋
        for value in Shared.game.jobinfos
            if savedobj[value.name]?
                flagobj[value.name]=savedobj[value.name]

        # 自分はその役職に変化する
        newpl=Player.factory pl.type, game
        @transProfile newpl
        @transferData newpl
        @transform game,newpl,false
        log=
            mode:"skill"
            to:@id
            comment: game.i18n.t "system.changeRole", {name: @name, result: newpl.getJobDisp()}
        splashlog game.id,game,log

        # 盗まれた側は怪盗予備軍のフラグを立てる
        newpl2=Player.factory null, game, pl,null,PhantomStolen
        newpl2.cmplFlag=flagobj
        pl.transProfile newpl2
        pl.transform game,newpl2,true
class BadLady extends Player
    type:"BadLady"
    team:"Friend"
    formType: FormType.required
    sleeping:->@flag?.set
    sunset:(game)->
        unless @flag?.set
            # まだ恋人未設定
            if @scapegoat
                @setFlag {
                    set:true
                }
    job:(game,playerid,query)->
        fl=@flag ? {}
        if fl.set
            return game.i18n.t "error.common.alreadyUsed"
        if playerid==@id
            return game.i18n.t "error.common.noSelectSelf"

        pl=game.getPlayer playerid
        unless pl?
            return game.i18n.t "error.common.nonexistentPlayer"
        pl.touched game,@id

        unless fl.main?
            # 本命を決める
            fl.main=playerid
            log=
                mode:"skill"
                to:@id
                comment: game.i18n.t "roles:BadLady.selectMain", {name: @name, target: pl.name}
            splashlog game.id,game,log
            @setFlag fl
            @addGamelog game,"badlady_main",pl.type,playerid
            return null
        unless fl.keep?
            # キープ相手を決める
            fl.keep=playerid
            fl.set=true
            @setFlag fl
            log=
                mode:"skill"
                to:@id
                comment: game.i18n.t "roles:BadLady.selectKeep", {name: @name, target: pl.name}
            splashlog game.id,game,log

            # 2人を恋人、1人をキープに
            plm=game.getPlayer fl.main
            for pll in [plm,pl]
                if pll?
                    log=
                        mode:"skill"
                        to:pll.id
                        comment: game.i18n.t "roles:Lover.become", {name: pll.name}
                    splashlog game.id,game,log
            # 自分恋人
            mypl = game.getPlayer @id
            newpl=Player.factory null, game, mypl, null, Friend # 恋人だ！
            newpl.cmplFlag=fl.main
            mypl.transProfile newpl
            mypl.transform game,newpl,true  # 入れ替え
            # 相手恋人
            newpl=Player.factory null, game, plm,null,Friend # 恋人だ！
            newpl.cmplFlag=@id
            plm.transProfile newpl
            plm.transform game,newpl,true  # 入れ替え
            # キープ
            newpl=Player.factory null, game, pl,null,KeepedLover # 恋人か？
            newpl.cmplFlag=@id
            pl.transProfile newpl
            pl.transform game,newpl,true  # 入れ替え
            game.splashjobinfo [@id,plm.id,pl.id].map (id)->game.getPlayer id
            @addGamelog game,"badlady_keep",pl.type,playerid
        null
    makejobinfo:(game,result)->
        super
        # "BadLady" form does not exist
        result.forms = result.forms.filter (obj)-> obj.type != "BadLady"
        if !@jobdone(game) && Phase.isNight(game.phase)
            # 夜の選択肢
            fl=@flag ? {}
            unless fl.set
                unless fl.main
                    # 本命を決める
                    result.open.push "BadLady1"
                    result.forms.push {
                        type: "BadLady1"
                        options: @makeJobSelection game
                        formType: FormType.required
                        objid: @objid
                    }
                else if !fl.keep
                    # 手玉に取る
                    result.open.push "BadLady2"
                    result.forms.push {
                        type: "BadLady2"
                        options: @makeJobSelection game
                        formType: FormType.required
                        objid: @objid
                    }
# 看板娘
class DrawGirl extends Player
    type:"DrawGirl"
    sleeping:->true
    dying:(game,found)->
        if found=="werewolf"
            # 狼に噛まれた
            @setFlag "bitten"
        else
            @setFlag ""
        super
    deadsunrise:(game)->
        # 夜明けで死亡していた場合
        if @flag=="bitten"
            # 噛まれて死亡した場合
            game.votingbox.addPunishedNumber 1
            log=
                mode:"system"
                comment: game.i18n.t "roles:DrawGirl.reveal", {name: @name, count: game.votingbox.remains}
            splashlog game.id,game,log
            @setFlag ""
            @addGamelog game,"drawgirlpower",null,null
# 慎重な狼
class CautiousWolf extends Werewolf
    type:"CautiousWolf"
    makeJobSelection:(game)->
        if Phase.isNight(game.phase)
            r=super
            return r.concat {
                name: game.i18n.t "roles:CautiousWolf.noAttackOption"
                value:""
            }
        else
            return super
    job:(game,playerid)->
        if playerid!=""
            super
            return
        # 襲撃しない場合
        game.werewolf_target.push {
            from:@id
            to:""
        }
        game.werewolf_target_remain--
        log=
            mode:"wolfskill"
            comment: game.i18n.t "roles:CautiousWolf.selectNoAttack", {name: @name}
        splashlog game.id,game,log
        game.splashjobinfo game.players.filter (x)=>x.id!=playerid && x.isWerewolf()
        null
# 花火師
class Pyrotechnist extends Player
    type:"Pyrotechnist"
    formType: FormType.optionalOnce
    sleeping:->true
    jobdone:(game)->@flag? || !Phase.isDay(game.phase)
    chooseJobDay:(game)->true
    job_target: 0
    job:(game,playerid,query)->
        if @flag?
            return game.i18n.t "error.common.alreadyUsed"
        unless Phase.isDay(game.phase)
            return game.i18n.t "error.common.cannotUseSkillNow"
        log=
            mode:"skill"
            to:@id
            comment: game.i18n.t "roles:Pyrotechnist.select", {name: @name}
        splashlog game.id,game,log
        # 使用済
        @setFlag "using"
        null
    checkJobValidity:(game,query)->
        if query.jobtype=="Pyrotechnist"
            # 対象選択は不要
            return true
        return super

# パン屋
class Baker extends Player
    type:"Baker"
    sleeping:->true
    sunrise:(game)->
        # 最初の1人がパン屋ログを管理
        bakers=game.players.filter (x)->x.isJobType "Baker"
        firstBakery=bakers[0]
        if firstBakery?.id==@id
            # わ た し だ
            if bakers.some((x)->!x.dead)
                # 生存パン屋がいる
                if @flag=="done"
                    @setFlag null
                log=
                    mode:"system"
                    comment: game.i18n.t "roles:Baker.alive"
                splashlog game.id,game,log
            else if @flag!="done"
                # 全員死亡していてまたログを出していない
                log=
                    mode:"system"
                    comment: game.i18n.t "roles:Baker.dead"
                splashlog game.id,game,log
                @setFlag "done"

    deadsunrise:(game)->
        @sunrise game
class Bomber extends Madman
    type:"Bomber"
    midnightSort:81
    formType: FormType.optional
    sleeping:->true
    jobdone:->@flag?
    sunset:(game)->
        @setTarget null
    job:(game,playerid)->
        pl=game.getPlayer playerid
        unless pl?
            return game.i18n.t "error.common.nonexistentPlayer"
        pl.touched game,@id
        @setTarget playerid
        @setFlag true
        # 爆弾を仕掛ける
        log=
            mode:"skill"
            to:@id
            comment: game.i18n.t "roles:Bomber.select", {name: @name, target: pl.name}
        splashlog game.id,game,log
        null
    midnight:(game,midnightSort)->
        pl = game.getPlayer @target
        unless pl?
            return
        newpl=Player.factory null, game, pl,null,BombTrapped
        pl.transProfile newpl
        newpl.cmplFlag=@id  # 護衛元cmplFlag
        pl.transform game,newpl,true

        @addGamelog game,"bomber_set",pl.type,@target
        null

class Blasphemy extends Player
    type:"Blasphemy"
    team:"Fox"
    midnightSort:90
    formType: FormType.required
    sleeping:(game)->@target? || @flag
    constructor:->
        super
        @setFlag null
    sunset:(game)->
        if @flag
            @setTarget ""
        else
            @setTarget null
            if @scapegoat
                # 身代わりくん
                alives=game.players.filter (x)->!x.dead
                r=Math.floor Math.random()*alives.length
                if @job game,alives[r].id,{}
                    @setTarget ""
    beforebury:(game)->
        if @flag
            # まだ狐を作ってないときは耐える
            # 狐が全員死んでいたら自殺
            unless game.players.some((x)->!x.dead && x.isFox())
                @die game,"foxsuicide"
    job:(game,playerid)->
        if @flag || @target?
            return game.i18n.t "error.common.alreadyUsed"
        @setTarget playerid
        pl=game.getPlayer playerid
        unless pl?
            return game.i18n.t "error.common.nonexistentPlayer"
        if pl.dead
            return game.i18n.t "error.common.alreadyDead"
        pl.touched game,@id

        log=
            mode:"skill"
            to:@id
            comment: game.i18n.t "roles:Blasphemy.select", {name: @name, target: pl.name}
        splashlog game.id,game,log

        @addGamelog game,"blasphemy",pl.type,playerid
        return null
    midnight:(game,midnightSort)->
        pl=game.getPlayer @target
        return unless pl?

        # まずい対象だと自分が冒涜される
        for type in BLASPHEMY_DEFENCE_JOBS
            if pl.isJobType type
                pl = game.getPlayer @id
                break
        return if pl.dead
        @setFlag true

        # 狐憑きをつける
        newpl=Player.factory null, game, pl,null,FoxMinion
        pl.transProfile newpl
        pl.transform game,newpl,true

class Ushinotokimairi extends Madman
    type:"Ushinotokimairi"
    midnightSort:90
    formType: FormType.optional
    sleeping:->true
    jobdone:->@target?
    sunset:(game)->
        super
        @setTarget null

    job:(game,playerid)->
        @setTarget playerid
        pl=game.getPlayer playerid
        unless pl?
            return game.i18n.t "error.common.nonexistentPlayer"
        pl.touched game,@id
        log=
            mode:"skill"
            to:@id
            comment: game.i18n.t "roles:Ushinotokimairi.select", {name: @name, target: pl.name}
        splashlog game.id,game,log
        null
    midnight:(game,midnightSort)->
        # 複合させる
        pl = game.getPlayer @target
        unless pl?
            return

        newpl=Player.factory null, game, pl,null,DivineCursed
        pl.transProfile newpl
        newpl.cmplFlag=@id  # 邪魔元cmplFlag
        pl.transform game,newpl,true

        @addGamelog game,"ushinotokimairi_curse",pl.type,@target
        null
    divined:(game,player)->
        if @target?
            # 能力を使用していた場合は占われると死ぬ
            @die game,"curse"
            player.addGamelog game,"cursekill",null,@id
        super

class Patissiere extends Player
    type: "Patissiere"
    team:"Friend"
    formType: FormType.required
    midnightSort:100
    sunset:(game)->
        unless @flag?
            if @scapegoat
                # 身代わりくんはチョコを配らない
                @setFlag true
                @setTarget ""
            else
                @setTarget null
        else
            @setTarget ""
    sleeping:(game)->@flag || @target?
    job:(game,playerid,query)->
        if @target?
            return game.i18n.t "error.common.alreadyUsed"
        if @flag
            return game.i18n.t "error.common.alreadyUsed"
        pl=game.getPlayer playerid
        unless pl?
            return game.i18n.t "error.common.nonexistentPlayer"
        if playerid==@id
            return game.i18n.t "error.common.noSelectSelf"
        pl.touched game,@id
        @setTarget playerid
        @setFlag true
        log=
            mode: "skill"
            to: @id
            comment: game.i18n.t "roles:Patissiere.select", {name: @name, target: pl.name}
        splashlog game.id, game, log
        null
    midnight:(game,midnightSort)->
        pl = game.getPlayer @target
        unless pl?
            return

        # 全員にチョコを配る（1人本命）
        alives = game.players.filter((x)->!x.dead).map((x)-> x.id)
        for pid in alives
            p = game.getPlayer pid
            if p.id == pl.id
                # 本命
                sub = Player.factory "GotChocolate", game
                p.transProfile sub
                sub.sunset game
                newpl = Player.factory null, game, p, sub, GotChocolateTrue
                newpl.cmplFlag=@id
                p.transProfile newpl
                p.transferData newpl
                p.transform game, newpl, true
                log=
                    mode:"skill"
                    to: p.id
                    comment: game.i18n.t "roles:Patissiere.deliver", {name: p.name}
                splashlog game.id,game,log
            else if p.id != @id
                # 義理
                sub = Player.factory "GotChocolate", game
                p.transProfile sub
                sub.sunset game
                newpl = Player.factory null, game, p, sub, GotChocolateFalse
                newpl.cmplFlag=@id
                p.transProfile newpl
                p.transferData newpl
                p.transform game, newpl, true
                log=
                    mode:"skill"
                    to: p.id
                    comment: game.i18n.t "roles:Patissiere.deliver", {name: p.name}
                splashlog game.id,game,log
        # 自分は本命と恋人になる
        top = game.getPlayer @id
        newpl = Player.factory null, game, top, null, Friend
        newpl.cmplFlag=pl.id
        top.transProfile newpl
        top.transferData newpl
        top.transform game,newpl,true

        log=
            mode: "skill"
            to: @id
            comment: game.i18n.t "roles:Patissiere.become", {name: @name, target: pl.name}
        splashlog game.id, game, log
        null

# 内部処理用：チョコレートもらった
class GotChocolate extends Player
    type: "GotChocolate"
    midnightSort:90
    formType: FormType.optional
    sleeping:->true
    jobdone:(game)-> @flag!="unselected"
    job_target:0
    getTypeDisp:->if @flag=="done" then null else @type
    makeJobSelection:(game)->
        if Phase.isNight(game.phase)
            []
        else super
    sunset:(game)->
        if !@flag?
            # 最初は選択できない
            @setTarget ""
            @setFlag "waiting"
        else if @flag=="waiting"
            # 選択できるようになった
            @setFlag "unselected"
    job:(game,playerid)->
        unless @flag == "unselected"
            return game.i18n.t "error.common.cannotUseSkillNow"
        # 食べると本命か義理か判明する
        flag = false
        top = game.getPlayer @id
        unless top?
            # ?????
            return game.i18n.t "error.common.nonexistentPlayer"
        while top?.isComplex()
            if top.cmplType=="GotChocolateTrue" && top.sub==this
                # 本命だ
                t=game.getPlayer top.cmplFlag
                if t?
                    log=
                        mode:"skill"
                        to: @id
                        comment: game.i18n.t "roles:GotChocolate.main", {name: @name, target: t.name}
                    splashlog game.id, game, log
                    @setFlag "done"
                    # 本命を消す
                    top.uncomplex game, false
                    # 恋人になる
                    top = game.getPlayer @id
                    newpl = Player.factory null, game, top, null, Friend
                    newpl.cmplFlag = t.id
                    top.transProfile newpl
                    top.transform game,newpl,true
                    top = game.getPlayer @id
                    flag = true
                    game.ss.publish.user top.id,"refresh",{id:game.id}
                    break
            else if top.cmplType=="GotChocolateFalse" && top.sub==this
                # 義理だ
                @setFlag "selected:#{top.cmplFlag}"
                flag = true
                log=
                    mode:"skill"
                    to: @id
                    comment: game.i18n.t "roles:GotChocolate.sub", {name: @name}
                splashlog game.id, game, log
                break
            top = top.main
        if flag == false
            # チョコレートをもらっていなかった
            log=
                mode:"skill"
                to: @id
                comment: game.i18n.t "roles:GotChocolate.noLover", {name: @name}
            splashlog game.id, game, log
        null
    midnight:(game,midnightSort)->
        re = @flag?.match /^selected:(.+)$/
        if re?
            @setFlag "done"
            @uncomplex game, true
            # 義理チョコの効果発動
            top = game.getPlayer @id
            r = Math.random()
            if r < 0.12
                # 呪いのチョコ
                log=
                    mode:"skill"
                    to: @id
                    comment: game.i18n.t "roles:GotChocolate.result.cursed", {name: @name}
                splashlog game.id, game, log
                newpl = Player.factory null, game, top, null, Muted
                top.transProfile newpl
                top.transform game, newpl, true
            else if r < 0.30
                # ブラックチョコ
                log=
                    mode:"skill"
                    to: @id
                    comment: game.i18n.t "roles:GotChocolate.result.black", {name: @name}
                splashlog game.id, game, log
                newpl = Player.factory null, game, top, null, Blacked
                top.transProfile newpl
                top.transform game, newpl, true
            else if r < 0.45
                # ホワイトチョコ
                log=
                    mode:"skill"
                    to: @id
                    comment: game.i18n.t "roles:GotChocolate.result.white", {name: @name}
                splashlog game.id, game, log
                newpl = Player.factory null, game, top, null, Whited
                top.transProfile newpl
                top.transform game, newpl, true
            else if r < 0.50
                # 毒入りチョコ
                log=
                    mode:"skill"
                    to: @id
                    comment: game.i18n.t "roles:GotChocolate.result.poison", {name: @name}
                splashlog game.id, game, log
                @die game, "poison", @id
            else if r < 0.57
                # ストーカー化
                topl = game.getPlayer re[1]
                if topl?
                    newpl = Player.factory "Stalker", game
                    top.transProfile newpl
                    # ストーカー先
                    newpl.setFlag re[1]
                    top.transform game, newpl, true

                    log=
                        mode:"skill"
                        to: @id
                        comment: game.i18n.t "roles:GotChocolate.result.stalker", {name: @name, target: topl.name}
                    splashlog game.id, game, log
            else if r < 0.65
                # 血入りの……
                log=
                    mode:"skill"
                    to: @id
                    comment: game.i18n.t "roles:GotChocolate.result.vampire", {name: @name}
                splashlog game.id, game, log
                newpl = Player.factory null, game, top, null, VampireBlooded
                top.transProfile newpl
                top.transform game, newpl, true
            else if r < 0.75
                # 聖職
                log=
                    mode:"skill"
                    to: @id
                    comment: game.i18n.t "roles:GotChocolate.result.priest", {name: @name}
                splashlog game.id, game, log
                sub = Player.factory "Priest", game
                top.transProfile sub
                newpl = Player.factory null, game, top, sub, Complex
                top.transProfile newpl
                top.transform game, newpl, true

class MadDog extends Madman
    type:"MadDog"
    fortuneResult: FortuneResult.werewolf
    psychicResult: PsychicResult.werewolf
    midnightSort:100
    formType: FormType.optional
    jobdone:(game)->@target? || @flag
    sleeping:->true
    constructor:->
        super
        @setFlag null
    sunset:(game)->
        if @flag || game.day==1
            @setTarget ""
        else
            @setTarget null
    job:(game,playerid)->
        if @flag || @target?
            return game.i18n.t "error.common.alreadyUsed"
        @setTarget playerid
        pl=game.getPlayer playerid
        unless pl?
            return game.i18n.t "error.common.nonexistentPlayer"
        if pl.dead
            return game.i18n.t "error.common.alreadyDead"
        pl.touched game,@id

        log=
            mode:"skill"
            to:@id
            comment: game.i18n.t "roles:MadDog.select", {name: @name, target: pl.name}
        splashlog game.id,game,log
        return null
    midnight:(game,midnightSort)->
        pl=game.getPlayer @target
        return unless pl?

        # 襲撃実行
        @setFlag true
        # 殺害
        @addGamelog game,"dogkill",pl.type,pl.id
        pl.die game,"dog"
        null

class Hypnotist extends Madman
    type:"Hypnotist"
    midnightSort:50
    formType: FormType.optional
    jobdone:(game)->@target? || @flag
    sleeping:->true
    constructor:->
        super
        @setFlag null
    sunset:(game)->
        if @flag || game.day==1
            @setTarget ""
        else
            @setTarget null
    job:(game,playerid)->
        if @flag || @target?
            return game.i18n.t "error.common.alreadyUsed"
        @setTarget playerid
        pl=game.getPlayer playerid
        unless pl?
            return game.i18n.t "error.common.nonexistentPlayer"
        if pl.dead
            return game.i18n.t "error.common.alreadyDead"
        pl.touched game,@id

        log=
            mode:"skill"
            to:@id
            comment: game.i18n.t "roles:Hypnotist.select", {name: @name, target: pl.name}
        splashlog game.id,game,log

        @setFlag true
        null
    midnight:(game,midnightSort)->
        pl = game.getPlayer @target
        unless pl?
            return

        if pl.isWerewolf()
            # 人狼を襲撃した場合は人狼の襲撃を無効化する
            game.werewolf_target = []
            game.werewolf_target_remain = 0

        # 催眠術を付加する
        @addGamelog game,"hypnosis",pl.type,pl.id
        newpl=Player.factory null, game, pl,null,UnderHypnosis
        pl.transProfile newpl
        pl.transform game,newpl,true

        return null

class CraftyWolf extends Werewolf
    type:"CraftyWolf"
    jobdone:(game)->super && @flag == "going"
    deadJobdone:(game)->@flag != "revivable"
    midnightSort:100
    isReviver:->!@dead || (@flag in ["reviving","revivable"])
    sunset:(game)->
        super
        # 生存状態で昼になったら死んだふり能力初期化
        @setFlag ""
    job:(game,playerid,query)->
        if query.jobtype!="CraftyWolf"
            return super
        if @dead
            # 死亡時
            if @flag != "revivable"
                return game.i18n.t "error.common.cannotUseSkillNow"
            @setFlag "reviving"
            log=
                mode:"skill"
                to:@id
                comment: game.i18n.t "roles:CraftyWolf.cancel", {name: @name}
            splashlog game.id,game,log
            return null
        else
            # 生存時
            if @flag != ""
                return game.i18n.t "error.common.alreadyUsed"
            # 生存フラグを残しつつ死ぬ
            @setFlag "going"
            log=
                mode:"skill"
                to:@id
                comment: game.i18n.t "roles:CraftyWolf.select", {name: @name}
            splashlog game.id,game,log
            return null
    midnight:(game,midnightSort)->
        if @flag=="going"
            @die game, "crafty"
            @addGamelog game,"craftydie"
            @setFlag "revivable"
    deadnight:(game,midnightSort)->
        if @flag=="reviving"
            # 生存していた
            pl = game.getPlayer @id
            if pl?
                pl.setFlag ""
                pl.revive game
                pl.addGamelog game,"craftyrevive"
        else
            # 生存フラグが消えた
            @setFlag ""
    makejobinfo:(game,result)->
        super
        result.open ?= []
        if @dead && @flag=="revivable"
            # 死に戻り
            result.open = result.open.filter (x)->!(x in ["CraftyWolf","_Werewolf"])
            result.forms = result.forms.filter (x)-> !(x.type in ["CraftyWolf", "_Werewolf"])
            result.open.push "CraftyWolf2"
            result.forms.push {
                type: "CraftyWolf2"
                options: []
                formType: FormType.optional
                objid: @objid
            }
        else if Phase.isNight(game.phase)
            # 死んだふりボタン
            result.open.push "CraftyWolf"
            result.forms.push {
                type: "CraftyWolf"
                options: []
                formType: FormType.optional
                objid: @objid
            }
        return result
    makeJobSelection:(game)->
        if Phase.isNight(game.phase) && @dead && @flag=="revivable"
            # 死んだふりやめるときは選択肢がない
            []
        else if Phase.isNight(game.phase) && game.werewolf_target_remain==0
            # もう襲撃対象を選択しない
            []
        else super
    checkJobValidity:(game,query)->
        if query.jobtype in ["CraftyWolf","CraftyWolf2"]
            # 対象選択は不要
            return true
        return super

class Shishimai extends Player
    type:"Shishimai"
    team:""
    formType: FormType.optional
    sleeping:->true
    jobdone:(game)->@target?
    isWinner:(game,team)->
        # 生存者（自身を除く）を全員噛んだら勝利
        alives = game.players.filter (x)->!x.dead
        # 獅子舞に噛まれた人を集計
        bitten = []
        for pl in game.players
            console.log "accessbyjobtypeall", pl.id
            ps = pl.accessByJobTypeAll("Shishimai")
            console.log "accessed", ps
            if ps.length > 0
                bitten.push pl.id
            for p in ps
                b = JSON.parse(p.flag || "[]")
                bitten.push b...
        # 生存者が全員噛まれているか?
        flg = true
        for pl in alives
            if pl.id == @id
                continue
            unless pl.id in bitten
                flg = false
                break
        return flg
    sunset:(game)->
        alives = game.players.filter (x)->!x.dead
        if alives.length > 0
            @setTarget null
        else
            @setTarget ""
    job:(game,playerid)->
        pl = game.getPlayer playerid
        unless pl?
            return game.i18n.t "error.common.nonexistentPlayer"
        bitten = JSON.parse (@flag || "[]")
        if playerid in bitten
            return game.i18n.t "roles:Shishimai.noSelectTwice"
        log=
            mode:"skill"
            to:@id
            comment: game.i18n.t "roles:Shishimai.select", {name: @name, target: pl.name}
        splashlog game.id, game, log
        @setTarget playerid
        null
    midnight:(game,midnightSort)->
        pl = game.getPlayer @target
        unless pl?
            return
        # 票数が減る祝いをかける
        newpl = Player.factory null, game, pl, null, VoteGuarded
        pl.transProfile newpl
        pl.transform game, newpl, true
        newpl.touched game,@id

        # 噛んだ記録
        arr = JSON.parse (@flag || "[]")
        arr.push newpl.id
        @setFlag (JSON.stringify arr)

        # かみかみ
        @addGamelog game, "shishimaibit", newpl.type, newpl.id
        null

class Pumpkin extends Madman
    type: "Pumpkin"
    midnightSort: 90
    formType: FormType.required
    sleeping:->@target?
    sunset:(game)->
        super
        @setTarget null
        if @scapegoat
            alives = game.players.filter (x)->!x.dead
            if alives.length == 0
                @setTarget ""
            else
                r=Math.floor Math.random()*alives.length
                @job game,alives[r].id ,{}
    job:(game,playerid)->
        @setTarget playerid
        pl=game.getPlayer playerid
        return unless pl?

        pl.touched game,@id
        log=
            mode:"skill"
            to:@id
            comment: game.i18n.t "roles:Pumpkin.select", {name: @name, target: pl.name}
        splashlog game.id,game,log
        @addGamelog game,"pumpkin",null,playerid
        null
    midnight:(game,midnightSort)->
        t=game.getPlayer @target
        return unless t?
        return if t.dead

        newpl=Player.factory null, game, t,null, PumpkinCostumed
        t.transProfile newpl
        t.transform game,newpl,true
class MadScientist extends Madman
    type:"MadScientist"
    midnightSort:100
    formType: FormType.optionalOnce
    isReviver:->!@dead && @flag!="done"
    sleeping:->true
    jobdone:->@flag=="done" || @target?
    job_target: Player.JOB_T_DEAD
    sunset:(game)->
        @setTarget (if game.day<2 || @flag=="done" then "" else null)
        if game.players.every((x)->!x.dead)
            @setTarget ""  # 誰も死んでいないなら能力発動しない
    job:(game,playerid)->
        if game.day<2
            return game.i18n.t "error.common.cannotUseSkillNow"
        if @flag == "done"
            return game.i18n.t "error.common.alreadyUsed"

        pl=game.getPlayer playerid
        unless pl?
            return game.i18n.t "error.common.nonexistentPlayer"
        unless pl.dead
            return game.i18n.t "error.common.notDead"

        @setFlag "done"
        @setTarget playerid

        log=
            mode:"skill"
            to:@id
            comment: game.i18n.t "roles:MadScientist.select", {name: @name, target: pl.name}
        splashlog game.id,game,log
        null
    midnight:(game,midnightSort)->
        return unless @target?
        pl=game.getPlayer @target
        return unless pl?
        return unless pl.dead

        # 蘇生
        @addGamelog game,"raise",true,pl.id
        pl.revive game

        pl = game.getPlayer @target
        return if pl.dead
        # 蘇生に成功したら勝利条件を変える
        newpl=Player.factory null, game, pl,null,WolfMinion    # WolfMinion
        pl.transProfile newpl
        pl.transform game,newpl,true
        log=
            mode:"skill"
            to:newpl.id
            comment: game.i18n.t "roles:MinionSelector.become", {name: newpl.name}
        splashlog game.id,game,log
class SpiritPossessed extends Player
    type:"SpiritPossessed"
    isReviver:->!@dead

class Forensic extends Player
    type:"Forensic"
    mdinightSort:100
    formType: FormType.required
    sleeping:->@target?
    job_target: Player.JOB_T_DEAD
    sunset:(game)->
        if game.day == 1
            # 1日目
            @setTarget ""
            return
        targets = game.players.filter (pl)-> pl.dead
        if targets.length == 0
            @setTarget ""
            return
        @setTarget null
        if @scapegoat
            # 身代わりくん
            r = Math.floor Math.random()*targets.length
            @setTarget ""
            @job game, targets[r].id, {}
    job:(game,playerid)->
        if game.day < 2
            return game.i18n.t "error.common.cannotUseSkillNow"
        pl = game.getPlayer playerid
        unless pl?
            return game.i18n.t "error.common.nonexistentPlayer"
        unless pl.dead
            return game.i18n.t "error.common.notDead"
        pl.touched game, @id
        @setTarget playerid
        log=
            mode:"skill"
            to:@id
            comment: game.i18n.t "roles:Forensic.select", {name: @name, target: pl.name}
        splashlog game.id, game, log
        null
    midnight:(game)->
        pl = game.getPlayer @target
        return unless pl?
        # 死亡耐性を調べる
        fl = pl.hasDeadResistance game
        result = if fl then "resultYes" else "resultNo"

        @addGamelog game,"forensic", fl, pl.id
        log=
            mode:"skill"
            to:@id
            comment: game.i18n.t "roles:Forensic.#{result}", {name: @name, target: pl.name}
        splashlog game.id, game, log

class Cosplayer extends Guard
    type:"Cosplayer"
    fortuneResult: FortuneResult.werewolf

class TinyGhost extends Player
    type:"TinyGhost"
    humanCount:-> 0

class Ninja extends Player
    type:"Ninja"
    formType: FormType.required
    sleeping:->@target?
    sunset:(game)->
        @setFlag null
        targets = game.players.filter (pl)-> !pl.dead && pl.id != "身代わりくん"
        if targets.length == 0
            @setTarget ""
            return
        @setTarget null
        if @scapegoat
            # 身代わりくん
            r = Math.floor Math.random()*targets.length
            @setTarget ""
            @job game, targets[r].id, {}
    job:(game,playerid)->
        pl = game.getPlayer playerid
        unless pl?
            return game.i18n.t "error.common.nonexistentPlayer"
        if pl.dead
            return game.i18n.t "error.common.alreadyDead"
        if pl.id == "身代わりくん"
            return game.i18n.t "error.common.noScapegoat"
        pl.touched game, @id
        @setTarget playerid
        log=
            mode:"skill"
            to:@id
            comment: game.i18n.t "roles:Ninja.select", {name: @name, target: pl.name}
        splashlog game.id, game, log
        null
    midnight:(game)->
        pl = game.getPlayer @target
        return unless pl?
        result = !!game.ninja_data?[pl.id]
        # trueなら夜行動あり
        if result
            log=
                mode:"skill"
                to:@id
                comment: game.i18n.t "roles:Ninja.resultYes", {name: @name, target: pl.name}
            splashlog game.id, game, log
        else
            log=
                mode:"skill"
                to:@id
                comment: game.i18n.t "roles:Ninja.resultNo", {name: @name, target: pl.name}
            splashlog game.id, game, log
        @addGamelog game,"ninjaresult", result, pl.id

class Twin extends Player
    type:"Twin"
    beforebury:(game)->
        # 死亡状態の双子がいたら死亡
        if game.players.some((x)-> x.dead && x.isJobType "Twin")
            @die game, "twinsuicide"
    makejobinfo:(game, result)->
        super
        # 双子が分かる
        result.twins = game.players.filter((x)-> x.isJobType "Twin").map (x)-> x.publicinfo()

class Hunter extends Player
    type:"Hunter"
    formType: FormType.required
    sleeping:(game)-> true
    hunterJobdone:(game)-> @flag != "hunting" || @target? || game.phase != Phase.hunter
    dying:(game, found)->
        super
        unless found in ["gone-day", "gone-night"]
            @target = null
            @setFlag "hunting"
    job:(game, playerid)->
        pl = game.getPlayer playerid
        unless pl?
            return game.i18n.t "error.common.nonexistentPlayer"
        if pl.dead
            return game.i18n.t "error.common.alreadyDead"
        unless @flag == "hunting"
            return game.i18n.t "error.common.cannotUseSkillNow"
        pl.touched game, @id
        @setTarget playerid
        log=
            mode: "skill"
            to: @id
            comment: game.i18n.t "roles:Hunter.select", {name: @name, target: pl.name}
        splashlog game.id, game, log
        null
    makeJobSelection:(game)->
        if game.phase == Phase.hunter
            result = super
            # 選択中のハンターは除く
            result = result.filter (x)->
                pl = game.getPlayer x.value
                hunters = [
                    (pl.accessByJobTypeAll "Hunter")...,
                    (pl.accessByJobTypeAll "MadHunter")...,
                ]
                return hunters.every (y)-> y.flag != "hunting"
            return result
        else
            return super

class MadHunter extends Hunter
    type:"MadHunter"
    team:"Werewolf"

class MadCouple extends Player
    type:"MadCouple"
    team:"Werewolf"
    makejobinfo:(game,result)->
        super
        result.madpeers = game.players.filter((x)-> x.isJobType "MadCouple").map (x)-> x.publicinfo()
    isListener:(game, log)->
        if log.mode == "madcouple"
            true
        else
            super
    getSpeakChoice:(game)->
        ["madcouple"].concat super

class Emma extends Player
    type:"Emma"
    isListener:(game, log)->
        if log.mode == "emmaskill"
            true
        else
            super

class EyesWolf extends Werewolf
    type:"EyesWolf"
    isListener:(game, log)->
        if log.mode == "eyeswolfskill"
            true
        else
            super

class TongueWolf extends Werewolf
    type:"TongueWolf"
    sunset:(game)->
        unless @flag == "lost"
            # Reset the target selection.
            @setFlag {
                mode: "targets"
                targets: []
            }
        super
    job:(game, playerid)->
        res = super
        if res?
            return res
        # If target selection was successful,
        # mark the target.
        if @flag?.mode == "targets"
            @flag.targets.push playerid
        null
    midnight:(game)->
        if @flag?.mode == "targets"
            # Save the job name of target.s
            results = []
            for target in @flag.targets
                pl = game.getPlayer target
                continue unless pl?
                results.push {
                    player: pl.publicinfo()
                    jobname: pl.getMainJobname()
                    isHuman: pl.isJobType "Human"
                }
            @setFlag {
                mode: "results"
                results: results
            }
    sunrise:(game)->
        # Show the result.
        if @flag?.mode == "results"
            # Check whether the target is dead.
            results = @flag.results
            for obj in results
                pl = game.getPlayer obj.player.id
                continue unless pl?
                continue unless pl.dead

                if obj.isHuman
                    # Attacked a Human. Skill is lost.
                    log=
                        mode: "skill"
                        to: @id
                        comment: game.i18n.t "roles:TongueWolf.resultLost", {
                            name: @name
                            target: obj.player.name
                            job: obj.jobname
                        }
                    splashlog game.id, game, log
                    @addGamelog game,"tongueresult", pl.type, pl.id
                    @setFlag "lost"
                else
                    log=
                        mode: "skill"
                        to: @id
                        comment: game.i18n.t "roles:TongueWolf.result", {
                            name: @name
                            target: obj.player.name
                            job: obj.jobname
                        }
                    splashlog game.id, game, log
                    @addGamelog game,"tongueresult", pl.type, pl.id

class BlackCat extends Madman
    type:"BlackCat"
    dying:(game,found,from)->
        super
        if found == "punish"
            # If dead by punishment,
            # kill another non-Werewolf player.
            canbedead = game.players.filter (x)-> !x.dead && !x.isWerewolf()
            return if canbedead.length == 0
            r = Math.floor Math.random() * canbedead.length
            pl = canbedead[r]
            pl.die game, "poison"
            @addGamelog game, "poisonkill", null, pl.id

class Idol extends Player
    type:"Idol"
    formType: FormType.required
    sunset:(game)->
        super
        if !@flag
            # Choose a fan.
            @setTarget null
            if @scapegoat
                # 自分以外から選ぶ
                targets = game.players.filter (x)=> !x.dead && x.id != @id
                if targets.length > 0
                    r = Math.floor Math.random() * targets.length
                    @job game, targets[r].id, {}
                else
                    @setTarget ""
        else
            @setTarget ""
    sleeping:->@flag?
    job:(game, playerid, query)->
        if @target? || @flag?
            return game.i18n.t "error.common.alreadyUsed"
        if playerid == @id
            return game.i18n.t "error.common.noSelectSelf"
        pl = game.getPlayer playerid
        unless pl?
            return game.i18n.t "error.common.nonexistentPlayer"
        pl.touched game, @id

        # select a fan.
        @setTarget playerid
        @setFlag {
            # List of fans.
            fans: [playerid]
            # Whether second fan is decided.
            second: false
        }
        log=
            mode: "skill"
            to: @id
            comment: game.i18n.t "roles:Idol.select", {name: @name, target: pl.name}
        splashlog game.id, game, log
        null
    midnight:(game)->
        # apply a fan complex
        pl = game.getPlayer @target
        if pl?
            newpl = Player.factory null, game, pl, null, FanOfIdol
            pl.transProfile newpl
            #FanOfIdol.cmplFlag is set to the id of idol
            newpl.cmplFlag = @id
            pl.transform game, newpl, true

            # show a message to the fan.
            log =
                mode: "skill"
                to: pl.id
                comment: game.i18n.t "roles:Idol.become", {name: pl.name, idol: @name}
            splashlog game.id, game, log
        # at Day 4 night, a new fan appears if there still is a fan alive.
        if @flag? && game.day >= 4 && !@flag.second
            fanalive = @flag.fans.some((id)->
                pl = game.getPlayer id
                pl? && !pl.dead)
            unless fanalive
                return
            # choose a new fan.
            targets = game.players.filter((pl)=>
                !pl.dead && pl.id != @id && !(pl.id in @flag.fans))
            if targets.length == 0
                return
            r = Math.floor Math.random() * targets.length
            pl = targets[r]
            newpl = Player.factory null, game, pl, null, FanOfIdol
            pl.transProfile newpl
            newpl.cmplFlag = @id
            pl.transform game, newpl, true
            # show messages.
            log=
                mode: "skill"
                to: @id
                comment: game.i18n.t "roles:Idol.select", {name: @name, target: pl.name}
            splashlog game.id, game, log
            log =
                mode: "skill"
                to: pl.id
                comment: game.i18n.t "roles:Idol.become", {name: pl.name, idol: @name}
            splashlog game.id, game, log
            # write to flag
            @setFlag {
                fans: [@flag.fans..., pl.id]
                second: true
            }

        null
    sunrise:(game)->
        # If one of my fans is alive, Idol can know
        # the number of remaining Human team players.
        super
        unless @flag?
            return

        if @flag.fans.every((x)->game.getPlayer(x)?.dead)
            return

        humanTeams = game.players.filter (x)-> !x.dead && x.getTeam() == "Human"
        num = humanTeams.length

        log=
            mode: "skill"
            to: @id
            comment: game.i18n.t "roles:Idol.result", {name: @name, count: num}
        splashlog game.id, game, log
    makejobinfo:(game, result)->
        super
        # add list of fans.
        if @flag?
            result.myfans = @flag.fans.map((id)->
                p = game.getPlayer id
                p?.publicinfo()
            ).filter((x)-> x?)
    modifyMyVote:(game, vote)->
        # If this is Day 5 or later and fan is no alive, vote is +1ed.
        if game.day >= 5 && @flag? && @flag.fans.every((id)-> game.getPlayer(id)?.dead)
            vote.priority++
        vote

class XianFox extends Fox
    type:"XianFox"
    # moves early so that jobname is obtained before target changes its job.
    midnightSort: 75
    formType: FormType.optional
    jobdone:(game)->@target?
    sleeping:->true
    sunset:(game)->
        super
        @setTarget null
        @setFlag null
    job:(game, playerid)->
        pl=game.getPlayer playerid
        unless pl?
            return game.i18n.t "error.common.nonexistentPlayer"

        @setTarget playerid
        pl.touched game,@id
        log=
            mode:"skill"
            to:@id
            comment: game.i18n.t "roles:XianFox.select", {name: @name, target: pl.name}
        splashlog game.id,game,log
        null
    midnight:(game)->
        # obtain target's job.
        pl = game.getPlayer @target
        unless pl?
            return
        if pl.isJobType "Human"
            # if pl is Human, result is not available.
            @setFlag null
        else
            @setFlag pl.getMainJobname()
        @addGamelog game, "xianresult", pl.type, pl.id

    sunrise:(game)->
        # show result.
        if @flag?
            log=
                mode:"system"
                comment: game.i18n.t "roles:XianFox.result", {result: @flag}
            splashlog game.id, game, log
            @setFlag null

class LurkingMad extends Madman
    type: "LurkingMad"
    isWerewolfVisible:-> true

# ============================
# 処理上便宜的に使用
class GameMaster extends Player
    type:"GameMaster"
    team:""
    formType: FormType.optional
    jobdone:->false
    sleeping:->true
    job_target: Player.JOB_T_ALIVE | Player.JOB_T_DEAD
    isWinner:(game,team)->null
    # 例外的に昼でも発動する可能性がある
    job:(game,playerid,query)->
        switch query?.commandname
            when "kill"
                # 死亡させる
                pl=game.getPlayer playerid
                unless pl?
                    return game.i18n.t "error.common.nonexistentPlayer"
                if pl.dead
                    return game.i18n.t "error.common.alreadyDead"
                pl.die game,"gmpunish"
                game.bury("other")
                return null
            when "revive"
                # 蘇生させる
                pl=game.getPlayer playerid
                unless pl?
                    return game.i18n.t "error.common.nonexistentPlayer"
                if !pl.dead
                    return game.i18n.t "error.common.notDead"
                pl.revive game
                if !pl.dead
                    if Phase.isNight(game.phase)
                        # 夜のときは夜開始時の処理をしてあげる
                        pl.sunset game
                    else if Phase.isDay(game.phase)
                        # 昼のときは投票可能に
                        pl.votestart game
                else
                    return game.i18n.t "roles:GameMaster.reviveFail"
                return null
            when "longer"
                # 時間延長
                remains = game.timer_start + game.timer_remain - Date.now()/1000
                clearTimeout game.timerid
                game.timer remains+30
                return null
            when "shorter"
                # 時間短縮
                remains = game.timer_start + game.timer_remain - Date.now()/1000
                if remains <= 30
                    return game.i18n.t "roles:GameMaster.shortenFail"
                clearTimeout game.timerid
                game.timer remains-30
                return null
        return null
    isListener:(game,log)->true # 全て見える
    getSpeakChoice:(game)->
        pls=for pl in game.players
            "gmreply_#{pl.id}"
        ["gm","gmheaven","gmaudience","gmmonologue"].concat pls
    getSpeakChoiceDay:(game)->@getSpeakChoice game
    chooseJobDay:(game)->true   # 昼でも対象選択
    makeJobSelection:(game)->
        # 常に全員
        return game.players.map((pl)-> {
            name: pl.name
            value: pl.id
        })
    checkJobValidity:(game,query)->
        switch query?.commandname
            when "longer", "shorter"
                return true
            when "kill", "revive"
                return super
            else
                if query?.jobtype == "_day"
                    pl = game.getPlayer query.target
                    if pl?.dead == false
                        return true
                return false

# ヘルパー
class Helper extends Player
    type:"Helper"
    team:""
    formType: FormType.optionalOnce
    jobdone:->@flag?
    sleeping:->true
    voted:(game,votingbox)->true
    isWinner:(game,team)->
        pl=game.getPlayer @flag
        return pl?.isWinner game,team
    # @flag: リッスン対象のid
    # 同じものが見える
    isListener:(game,log)->
        pl=game.getPlayer @flag
        unless pl?
            # 自律行動ヘルパー?
            return super
        if pl.isJobType "Helper"
            # ヘルパーのヘルパーの場合は聞こえない（無限ループ防止）
            return false
        return pl.isListener game,log
    getSpeakChoice:(game)->
        if @flag?
            return ["helperwhisper_#{@flag}"]
        else
            return ["helperwhisper"]
    getSpeakChoiceDay:(game)->@getSpeakChoice game
    job:(game,playerid)->
        if @flag?
            return game.i18n.t "error.common.cannotUseSkillNow"
        pl=game.getPlayer playerid
        unless pl?
            return game.i18n.t "error.common.nonexistentPlayer"
        @flag=playerid
        log=
            mode:"skill"
            to:playerid
            comment: game.i18n.t "roles:Helper.select", {name: @name, target: pl.name}
        splashlog game.id,game,log
        # 自分の表記を改める
        game.splashjobinfo [this]
        null

    makejobinfo:(game,result)->
        super
        # ヘルプ先が分かる
        pl=game.getPlayer @flag
        if pl?
            helpedinfo={}
            pl.makejobinfo game,helpedinfo
            result.supporting=pl?.publicinfo()
            # This is for old client
            result.supportingJob=pl?.getJobDisp()
            result.supporting.supportingJob = pl?.getJobDisp()
            for value in Shared.game.jobinfos
                if helpedinfo[value.name]?
                    result[value.name]=helpedinfo[value.name]
        null

# 開始前のやつだ!!!!!!!!
class Waiting extends Player
    type:"Waiting"
    team:""
    formType: FormType.required
    sleeping:(game)->game.phase != Phase.rolerequesting || game.rolerequesttable[@id]?
    isListener:(game,log)->
       if log.mode=="audience"
           true
       else super
    getSpeakChoice:(game)->
        return ["prepare"]
    makejobinfo:(game,result)->
        super
        # 自分で追加する
        unless @sleeping game
            result.open.push "Waiting"
            result.forms.push {
                type: "Waiting"
                options: @makeJobSelection game
                formType: FormType.required
                objid: @objid
            }
    makeJobSelection:(game)->
        if game.day==0 && game.phase == Phase.rolerequesting
            # 開始前
            result=[{
                name: game.i18n.t "roles:Waiting.none"
                value:""
            }]
            for job,num of game.joblist
                if num
                    result.push {
                        name: game.i18n.t "roles:jobname.#{job}"
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
                comment: game.i18n.t "roles:Waiting.select", {name: @name, jobname: game.i18n.t "roles:jobname.#{target}"}
        else
            log=
                mode:"skill"
                to:@id
                comment: game.i18n.t "roles:Waiting.selectNone", {name: @name}
        splashlog game.id,game,log
        null
# エンドレス闇鍋でまだ入ってないやつ
class Watching extends Player
    type:"Watching"
    team:""
    sleeping:(game)->true
    isWinner:(game,team)->true
    isListener:(game,log)->
       if log.mode in ["audience","inlog"]
           # 参加前なので
           true
       else super
    getSpeakChoice:(game)->
        return ["audience"]
    getSpeakChoiceDay:(game)->
        return ["audience"]



# 複合役職 Player.factoryで適切に生成されることを期待
# superはメイン役職 @mainにメイン @subにサブ
# @cmplFlag も持っていい
class Complex
    cmplType:"Complex"  # 複合親そのものの名前
    isComplex:->true
    getJobname:->@main.getJobname()
    getMainJobname:->@main.getMainJobname()
    getJobDisp:->@main.getJobDisp()
    getMainJobDisp:->@main.getMainJobDisp()
    midnightSort: 100

    #@mainのやつを呼ぶ
    mcall:(game,method,args...)->
        if @main.isComplex()
            # そのまま
            return method.apply @main,args
        # 他は親が必要
        root = game.participants.filter((x)=>x.id==@id)[0]
        res = searchPlayerInTree root, this
        if res?
            [_, myTop] = res
            return method.apply myTop, args
        return null

    setDead:(@dead,@found)->
        @main.setDead @dead,@found
        @sub?.setDead @dead,@found
    setWinner:(@winner)->@main.setWinner @winner
    setTarget:(@target)->@main.setTarget @target
    setFlag:(@flag)->@main.setFlag @flag
    setWill:(@will)->@main.setWill @will
    setOriginalType:(@originalType)->@main.setOriginalType @originalType
    setOriginalJobname:(@originalJobname)->@main.setOriginalJobname @originalJobname
    setNorevive:(@norevive)->@main.setNorevive @norevive

    sleeping:(game)-> @mcall game, @main.sleeping, game
    jobdone:(game)-> @mcall(game,@main.jobdone,game) && (!@sub?.jobdone? || @sub.jobdone(game)) # ジョブの場合はサブも考慮
    deadJobdone:(game)-> @mcall(game,@main.deadJobdone,game) && (!@sub?.deadJobdone? || @sub.deadJobdone(game))
    hunterJobdone:(game)-> @mcall(game,@main.hunterJobdone,game) && (!@sub?.hunterJobdone? || @sub.hunterJobdone(game))
    job:(game,playerid,query)->
        # main役職が役職実行対象を選択した
        return @mcall game,@main.job,game,playerid,query
    # Am I Walking Dead?
    isDead:->
        isMainDead = @main.isDead()
        if isMainDead.dead && isMainDead.found
            # Dead!
            return isMainDead
        if @sub?
            isSubDead = @sub.isDead()
            if isSubDead.dead && isSubDead.found
                # Dead!
                return isSubDead
        # seems to be alive, who knows?
        return {dead:@dead,found:@found}
    isJobType:(type)->
        @main.isJobType(type) || @sub?.isJobType?(type)
    isMainJobType:(type)-> @main.isMainJobType type
    getTeam:-> @main.getTeam()
    getTeamDisp:-> @main.getTeamDisp()
    #An access to @main.flag, etc.
    accessByJobType:(type)->
        unless type
            throw "there must be a JOBTYPE"
        unless @isJobType(type)
            return null
        if @main.isJobType(type)
            return @main.accessByJobType(type)
        else
            unless @sub?
                return null
            return @sub.accessByJobType(type)
        null
    accessByJobTypeAll:(type, subonly)->
        unless type
            throw "there must be a JOBTYPE"
        ret = []
        if !subonly && @main.isMainJobType(type)
            ret.push this
        ret.push (@main.accessByJobTypeAll(type, true))...
        if @sub?
            ret.push (@sub.accessByJobTypeAll(type))...
        return ret
    accessByObjid:(objid, subonly=false)->
        # objid is unique per game.
        # when `subonly` is true, main objid is not checked.
        if !subonly && @objid == objid
            return this
        ret = @main.accessByObjid objid, true
        if ret?
            return ret
        if @sub?
            return @sub.accessByObjid objid
        return null
    gatherMidnightSort:->
        mids=[@midnightSort]
        mids=mids.concat @main.gatherMidnightSort()
        if @sub?
            mids=mids.concat @sub.gatherMidnightSort()
        return mids
    sunset:(game)->
        @mcall game,@main.sunset,game
        @sub?.sunset? game
    midnight:(game,midnightSort)->
        if @main.isComplex() || @main.midnightSort == midnightSort
            @mcall game,@main.midnight,game,midnightSort
        if @sub?.isComplex() || @sub?.midnightSort == midnightSort
            @sub?.midnight? game,midnightSort
    deadnight:(game,midnightSort)->
        if @main.isComplex() || @main.midnightSort == midnightSort
            @mcall game,@main.deadnight,game,midnightSort
        if @sub?.isComplex() || @sub?.midnightSort == midnightSort
            @sub?.deadnight? game,midnightSort
    deadsunset:(game)->
        @mcall game,@main.deadsunset,game
        @sub?.deadsunset? game
    deadsunrise:(game)->
        @mcall game,@main.deadsunrise,game
        @sub?.deadsunrise? game
    sunrise:(game)->
        @mcall game,@main.sunrise,game
        @sub?.sunrise? game
    votestart:(game)->
        @mcall game,@main.votestart,game
    voted:(game,votingbox)->
        # as a Neet may claim that he is already voted.
        result = @mcall game, @main.voted, game, votingbox
        if @sub?
            result = result || @sub.voted game, votingbox
        result
    dovote:(game,target)->
        @mcall game,@main.dovote,game,target
    voteafter:(game,target)->
        @mcall game,@main.voteafter,game,target
        @sub?.voteafter game,target
    modifyMyVote:(game, vote)->
        if @sub?
            vote = @sub.modifyMyVote game, vote
        @mcall game, @main.modifyMyVote, game, vote

    makejobinfo:(game,result)->
        @sub?.makejobinfo? game,result
        @main.makejobinfo game, result, @main.getJobDisp()
    beforebury:(game,type,deads)->
        @mcall game,@main.beforebury,game,type,deads
        @sub?.beforebury? game,type,deads
        # deal with Walking Dead
        unless @dead
            isPlDead = @isDead()
            if isPlDead.dead && isPlDead.found
                @setDead isPlDead.dead,isPlDead.found
    divined:(game,player)->
        @mcall game,@main.divined,game,player
        @sub?.divined? game,player
    getjob_target:->
        if @sub?
            @main.getjob_target() | @sub.getjob_target()    # ビットフラグ
        else
            @main.getjob_target()
    die:(game,found,from)->
        @mcall game,@main.die,game,found,from
    dying:(game,found,from)->
        @mcall game,@main.dying,game,found,from
        @sub?.dying game,found,from
    revive:(game)->
        # まずsubを蘇生
        if @sub?
            @sub.revive game
            if @sub.dead
                # 蘇生できない類だ
                return
        # 次にmainを蘇生
        @mcall game,@main.revive,game
        if @main.dead
            # 蘇生できなかった
            @setDead true, @main.found
        else
            # 蘇生できた
            @setDead false, null
    makeJobSelection:(game)->
        result=@mcall game,@main.makeJobSelection,game
        if @sub?
            for obj in @sub.makeJobSelection game
                unless result.some((x)->x.value==obj.value)
                    result.push obj
        result
    checkJobValidity:(game,query)->
        if query.jobtype=="_day"
            return @main.checkJobValidity game, query
        if @main.isJobType(query.jobtype) && !@main.jobdone(game)
            return @main.checkJobValidity game, query
        else if @sub?.isJobType?(query.jobtype) && !@sub?.jobdone?(game)
            return @sub.checkJobValidity game,query
        else
            return true

    getSpeakChoiceDay:(game)->
        result=@mcall game,@main.getSpeakChoiceDay,game
        if @sub?
            for obj in @sub.getSpeakChoiceDay game
                unless result.some((x)->x==obj)
                    result.push obj
        result
    getSpeakChoice:(game)->
        result=@mcall game,@main.getSpeakChoice,game
        if @sub?
            for obj in @sub.getSpeakChoice game
                unless result.some((x)->x==obj)
                    result.push obj
        result
    isListener:(game,log)->
        @mcall(game,@main.isListener,game,log) || @sub?.isListener(game,log)
    isReviver:->@main.isReviver() || @sub?.isReviver()
    isHuman:->@main.isHuman()
    isWerewolf:->@main.isWerewolf()
    isFox:->@main.isFox()
    isVampire:->@main.isVampire()
    isWerewolfVisible:->@main.isWerewolfVisible()
    isWinner:(game,team)->@main.isWinner game, team
    hasDeadResistance:(game)->
        if @mcall game, @main.hasDeadResistance, game
            return true
        if @sub?.hasDeadResistance game
            return true
        return false

#superがつかえないので注意
class Friend extends Complex    # 恋人
    # cmplFlag: 相方のid
    cmplType:"Friend"
    isFriend:->true
    getTeam:-> "Friend"
    getTeamDisp:-> "Friend"
    getJobname:-> @game.i18n.t "roles:Friend.jobname", {jobname: @main.getJobname()}
    getJobDisp:-> @game.i18n.t "roles:Friend.jobname", {jobname: @main.getJobDisp()}

    beforebury:(game,type,deads)->
        @mcall game,@main.beforebury,game,type,deads
        @sub?.beforebury? game,type,deads
        ato=false
        if game.rule.friendssplit=="split"
            # 独立
            pl=game.getPlayer @cmplFlag
            if pl? && pl.dead && pl.isFriend()
                ato=true
        else
            # みんな
            friends=game.players.filter (x)->x.isFriend()   #恋人たち
            if friends.length>1 && friends.some((x)->x.dead)
                ato=true
        # 恋人が誰か死んだら自殺
        if ato
            @die game,"friendsuicide"
    makejobinfo:(game,result)->
        @sub?.makejobinfo? game,result
        @mcall game,@main.makejobinfo,game,result
        # 恋人が分かる
        result.desc?.push {
            name: game.i18n.t "roles:Friend.name"
            type:"Friend"
        }
        if game.rule.friendssplit=="split"
            # 独立
            fr=[this,game.getPlayer(@cmplFlag)].filter((x)->x?.isFriend()).map (x)->
                x.publicinfo()
            if Array.isArray result.friends
                result.friends=result.friends.concat fr
            else
                result.friends=fr
        else
            # みんないっしょ
            result.friends=game.players.filter((x)->x.isFriend()).map (x)->
                x.publicinfo()
    isWinner:(game,team)->@getTeam()==team && !@dead
    # 相手のIDは?
    getPartner:->
        if @cmplType=="Friend"
            return @cmplFlag
        else
            return @main.getPartner()
# 聖職者にまもられた人
class HolyProtected extends Complex
    # cmplFlag: 護衛元
    cmplType:"HolyProtected"
    die:(game,found)->
        # 一回耐える 死なない代わりに元に戻る
        log=
            mode:"skill"
            to:@id
            comment: game.i18n.t "roles:HolyProtected.guarded", {name: @name}
        splashlog game.id,game,log
        game.getPlayer(@cmplFlag).addGamelog game,"holyGJ",found,@id
        if found == "werewolf"
            game.addGuardLog @id, AttackKind.werewolf, GuardReason.holy

        @uncomplex game
# カルトの信者になった人
class CultMember extends Complex
    cmplType:"CultMember"
    isCult:->true
    getJobname:-> @game.i18n.t "roles:CultMember.jobname", {jobname: @main.getJobname()}
    getJobDisp:-> @game.i18n.t "roles:CultMember.jobname", {jobname: @main.getJobDisp()}
    makejobinfo:(game,result)->
        super
        # 信者の説明
        result.desc?.push {
            name: @game.i18n.t "roles:CultMember.name"
            type:"CultMember"
        }
# 狩人に守られた人
class Guarded extends Complex
    # cmplFlag: 護衛元ID
    cmplType:"Guarded"
    die:(game,found,from)->
        unless found in ["werewolf","vampire"]
            @mcall game,@main.die,game,found,from
        else
            # 狼に噛まれた場合は耐える
            guard=game.getPlayer @cmplFlag
            if guard?
                guard.addGamelog game,"GJ",null,@id
                if game.rule.gjmessage
                    log=
                        mode:"skill"
                        to:guard.id
                        comment: game.i18n.t "roles:Guard.gj", {guard: guard.name, name: @name}
                    splashlog game.id,game,log
            # 襲撃失敗ログを追加
            if found == "werewolf"
                game.addGuardLog @id, AttackKind.werewolf, GuardReason.guard

    sunrise:(game)->
        # 一日しか守られない
        @mcall game,@main.sunrise,game
        @sub?.sunrise? game
        @uncomplex game
# 黙らされた人
class Muted extends Complex
    cmplType:"Muted"

    sunset:(game)->
        # 一日しか効かない
        @mcall game,@main.sunset,game
        @sub?.sunset? game
        @uncomplex game
        game.ss.publish.user @id,"refresh",{id:game.id}
    getSpeakChoiceDay:(game)->
        ["monologue"]   # 全員に喋ることができない
# 狼の子分
class WolfMinion extends Complex
    cmplType:"WolfMinion"
    getTeam:->"Werewolf"
    getJobname:-> @game.i18n.t "roles:WolfMinion.jobname", {jobname: @main.getJobname()}
    getJobDisp:-> @game.i18n.t "roles:WolfMinion.jobname", {jobname: @main.getJobDisp()}
    makejobinfo:(game,result)->
        @sub?.makejobinfo? game,result
        @mcall game,@main.makejobinfo,game,result
        result.desc?.push {
            name: @game.i18n.t "roles:WolfMinion.name"
            type:"WolfMinion"
        }
    isWinner:(game,team)->@getTeam()==team
# 酔っ払い
class Drunk extends Complex
    cmplType:"Drunk"
    getJobname:-> @game.i18n.t "roles:Drunk.jobname", {jobname: @main.getJobname()}
    getTypeDisp:->"Human"
    getTeamDisp:->"Human"
    getJobDisp:->
        if @game.rule.chemical == "on"
            @game.i18n.t "roles:Chemical.jobname", {
                left: @game.i18n.t "roles:jobname.Human"
                right: @game.i18n.t "roles:jobname.Human"
            }
        else
            @game.i18n.t "roles:jobname.Human"
    getMainJobDisp:-> @getJobDisp()
    sleeping:->true
    jobdone:->true
    isListener:(game,log)->
        Human.prototype.isListener.call @,game,log

    sunset:(game)->
        @mcall game,@main.sunrise,game
        @sub?.sunrise? game
        if game.day>=3
            # 3日目に目が覚める
            log=
                mode:"skill"
                to:@id
                comment: game.i18n.t "roles:Drunk.awake", {name: @name}
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
    midnight:(game,midnightSort)->
        if @main.isComplex() || @main.midnightSort == midnightSort
            @mcall game,@main.midnight,game,midnightSort
        if @sub?.isComplex() || @sub?.midnightSort == midnightSort
            @sub?.midnight? game,midnightSort

        # 狩人とかぶったら狩人が死んでしまう!!!!!
        # midnight: 狼の襲撃よりも前に行われることが保証されている処理
        return if midnightSort != @midnightSort
        wholepl=game.getPlayer @id  # 一番表から見る
        result=@checkGuard game,wholepl
        if result
            # 狩人がいた!（罠も無効）
            wholepl = game.getPlayer @id
            @checkTrap game, wholepl
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
    checkTrap:(game,pl)->
        # TrapGuardedも消す
        return unless pl.isComplex()
        if pl.cmplType=="TrapGuarded"
            pl.uncomplex game
            @checkTrap game, pl.main
        else
            @checkTrap game, pl.main
            if pl.sub?
                @checkTrap game, pl.sub

    die:(game,found,from)->
        unless found in ["werewolf","vampire"]
            # 狼以外だとしぬ
            @mcall game,@main.die,game,found
        else
            # 狼に噛まれた場合は耐える
            guard=game.getPlayer @cmplFlag
            if guard?
                guard.addGamelog game,"trapGJ",null,@id
                if game.rule.gjmessage
                    log=
                        mode:"skill"
                        to:guard.id
                        comment: game.i18n.t "roles:Trapper.gj", {guard: guard.name, name: @name}
                    splashlog game.id,game,log
            # 反撃する
            canbedead=[]
            ft=game.getPlayer from
            if ft.isWerewolf()
                canbedead=game.players.filter (x)->!x.dead && x.isWerewolf()
            else if ft.isVampire()
                canbedead=game.players.filter (x)->!x.dead && x.id==from
            return if canbedead.length==0
            r=Math.floor Math.random()*canbedead.length
            pl=canbedead[r] # 被害者
            pl.die game,"trap"
            @addGamelog game,"trapkill",null,pl.id
            # 襲撃失敗理由を保存
            if found == "werewolf"
                game.addGuardLog @id, AttackKind.werewolf, GuardReason.trap


    sunrise:(game)->
        # 一日しか守られない
        @mcall game,@main.sunrise,game
        @sub?.sunrise? game
        @uncomplex game
# 黙らされた人
class Lycanized extends Complex
    cmplType:"Lycanized"
    getFortuneResult:-> FortuneResult.werewolf
    sunset:(game)->
        # 一日しか効かない
        @mcall game,@main.sunset,game
        @sub?.sunset? game
        @uncomplex game
# カウンセラーによって更生させられた人
class Counseled extends Complex
    cmplType:"Counseled"
    getTeam:-> "Human"
    getJobname:-> @game.i18n.t "roles:Counseled.jobname", {jobname: @main.getJobname()}
    getJobDisp:-> @game.i18n.t "roles:Counseled.jobname", {jobname: @main.getJobDisp()}

    isWinner:(game,team)->@getTeam()==team
    makejobinfo:(game,result)->
        @sub?.makejobinfo? game,result
        @mcall game,@main.makejobinfo,game,result
        result.desc?.push {
            name: @game.i18n.t "roles:Counseled.name"
            type:"Counseled"
        }
# 巫女のガードがある状態
class MikoProtected extends Complex
    cmplType:"MikoProtected"
    die:(game,found)->
        # 耐える
        game.getPlayer(@id).addGamelog game,"mikoGJ",found
        # The draw caused by Miko's escape is annoying.
        if found in ["gone-day","gone-night"]
            @addGamelog game,"miko-gone",null,null
        # 襲撃失敗理由を保存
        if found == "werewolf"
            game.addGuardLog @id, AttackKind.werewolf, GuardReason.holy
    sunset:(game)->
        # 一日しか効かない
        @mcall game,@main.sunset,game
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
        @mcall game,@main.sunrise,game
        @sub?.sunrise? game
        @uncomplex game
    sunset:(game)->
    midnight:(game,midnightSort)->
    job:(game,playerid,query)->
        null
    dying:(game,found,from)->
        Human.prototype.dying.call @,game,found,from
    touched:(game,from)->
    divined:(game,player)->
    voteafter:(game,target)->
    makejobinfo:(game,obj)->
        Human.prototype.makejobinfo.call @,game,obj
    getSpeakChoice:(game)->
        Human.prototype.getSpeakChoice.call @,game
# 邪魔狂人に邪魔された(未完成)
class DivineObstructed extends Complex
    # cmplFlag: 邪魔元ID
    cmplType:"DivineObstructed"
    sunset:(game)->
        # 一日しか守られない
        @mcall game,@main.sunset,game
        @sub?.sunset? game
        @uncomplex game
    # 占いの影響なし
    divineeffect:(game)->
    showdivineresult:(game)->
        # 結果がでなかった
        pl=game.getPlayer @target
        if pl?
            log=
                mode:"skill"
                to:@id
                comment: game.i18n.t "roles:ObstructiveMad.blocked", {name: @name, target: pl.name}
            splashlog game.id,game,log
    dodivine:(game)->
        # 占おうとした。邪魔成功
        obstmad=game.getPlayer @cmplFlag
        if obstmad?
            obstmad.addGamelog game,"divineObstruct",null,@id
class PhantomStolen extends Complex
    cmplType:"PhantomStolen"
    # cmplFlag: 保存されたアレ
    sunset:(game)->
        # 夜になると怪盗になってしまう!!!!!!!!!!!!
        @sub?.sunrise? game
        newpl=Player.factory "Phantom", game
        # アレがなぜか狂ってしまうので一時的に保存
        saved=@originalJobname
        @uncomplex game
        pl=game.getPlayer @id
        pl.transProfile newpl
        pl.transferData newpl
        pl.transform game,newpl,true
        log=
            mode:"skill"
            to:@id
            comment: game.i18n.t "roles:Phantom.stolen", {name: @name, jobname: newpl.getJobDisp()}
        splashlog game.id,game,log
        # 夜の初期化
        pl=game.getPlayer @id
        pl.setOriginalJobname saved
        pl.setFlag true # もう盗めない
        pl.sunset game
    getJobname:-> @game.i18n.t "roles:jobname.Phantom" #霊界とかでは既に怪盗化
    getMainJobname:-> @getJobname()
    # 勝利条件関係は村人化（昼の間だけだし）
    isWerewolf:->false
    isFox:->false
    isVampire:->false
    #team:"Human" #女王との兼ね合いで
    isWinner:(game,team)->
        team=="Human"
    die:(game,found,from)->
        # 抵抗もなく死ぬし
        if found=="punish"
            Player::die.apply this,arguments
        else
            super
    dying:(game,found)->
    makejobinfo:(game,obj)->
        super
        for key,value of @cmplFlag
            obj[key]=value
class KeepedLover extends Complex    # 悪女に手玉にとられた（見た目は恋人）
    # cmplFlag: 相方のid
    cmplType:"KeepedLover"
    getJobname:-> @game.i18n.t "roles:KeepedLover.jobname", {jobname: @main.getJobname()}
    getJobDisp:-> @game.i18n.t "roles:KeepedLover.fakeJobname", {jobname: @main.getJobDisp()}
    getTeamDisp:->"Friend"

    makejobinfo:(game,result)->
        @sub?.makejobinfo? game,result
        @mcall game,@main.makejobinfo,game,result
        # 恋人が分かる
        result.desc?.push {
            name: game.i18n.t "roles:KeepedLover.fakeName"
            type:"Friend"
        }
        # 恋人だと思い込む
        fr=[this,game.getPlayer(@cmplFlag)].map (x)->
            x.publicinfo()
        if Array.isArray result.friends
            result.friends=result.friends.concat fr
        else
            result.friends=fr
# 花火を見ている
class WatchingFireworks extends Complex
    # cmplFlag: 花火師のid
    cmplType:"WatchingFireworks"
    sleeping:->true
    jobdone:->true
    isAttacker:->false

    sunrise:(game)->
        @mcall game,@main.sunrise,game
        @sub?.sunrise? game
        # もう終了
        @uncomplex game
    deadsunrise:(game)->
        @mcall game,@main.deadsunrise,game
        @sub?.deadsunrise? game
        @uncomplex game

    makejobinfo:(game,result)->
        super
        result.watchingfireworks=true
# 爆弾魔に爆弾を仕掛けられた人
class BombTrapped extends Complex
    # cmplFlag: 護衛元ID
    cmplType:"BombTrapped"
    midnight:(game,midnightSort)->
        if @main.isComplex() || @main.midnightSort == midnightSort
            @mcall game,@main.midnight,game,midnightSort
        if @sub?.isComplex() || @sub?.midnightSort == midnightSort
            @sub?.midnight? game,midnightSort

        # 狩人とかぶったら狩人が死んでしまう!!!!!
        # midnight: 狼の襲撃よりも前に行われることが保証されている処理
        if midnightSort != @midnightSort then return
        wholepl=game.getPlayer @id  # 一番表から見る
        result=@checkGuard game,wholepl
        if result
            # 狩人がいた!（罠も無効）
            @uncomplex game
    # bomb would explode for only once
    deadsunrise:(game)->
        super
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
                tr = game.getPlayer @cmplFlag   #爆弾魔
                if tr?
                    tr.addGamelog game,"bombTrappedGuard",null,@id
                # 護衛元が死ぬ
                gu.die game,"trap"
                # 自分も死ぬ
                @die game,"trap"


            pl.uncomplex game   # 罠は消滅
            # 子の調査を継続
            @checkGuard game,pl.main
            return true

    die:(game,found,from)->
        if found=="punish"
            # 処刑された場合は処刑者の中から選んでしぬ
            # punishのときはfromがidの配列
            if from? && from.length>0
                pls=from.map (id)->game.getPlayer id
                pls=pls.filter (x)->!x.dead
                if pls.length>0
                    r=Math.floor Math.random()*pls.length
                    pl=pls[r]
                    if pl?
                        pl.die game,"trap"
                        @addGamelog game,"bombkill",null,pl.id
        else if found in ["werewolf","vampire"]
            # 狼に噛まれた場合は襲撃者を巻き添えにする
            bomber=game.getPlayer @cmplFlag
            if bomber?
                bomber.addGamelog game,"bompGJ",null,@id
            # 反撃する
            wl=game.getPlayer from
            if wl?
                wl.die game,"trap"
                @addGamelog game,"bombkill",null,wl.id
        # 自分もちゃんと死ぬ
        @mcall game,@main.die,game,found,from

# 狐憑き
class FoxMinion extends Complex
    cmplType:"FoxMinion"
    willDieWerewolf:false
    isHuman:->false
    isFox:->true
    isFoxVisible:->true
    hasDeadResistance:->true
    getJobname:-> @game.i18n.t "roles:FoxMinion.jobname", {jobname: @main.getJobname()}
    # 占われたら死ぬ
    divined:(game,player)->
        @mcall game,@main.divined,game,player
        @die game,"curse"
        player.addGamelog game,"cursekill",null,@id # 呪殺した

# 丑刻参に呪いをかけられた
class DivineCursed extends Complex
    cmplType:"DivineCursed"
    sunset:(game)->
        # 1日で消える
        @mcall game,@main.sunset,game
        @sub?.sunset? game
        @uncomplex game
    divined:(game,player)->
        @mcall game,@main.divined,game,player
        @die game,"curse"
        player.addGamelog game,"cursekill",null,@id # 呪殺した

# パティシエールに本命チョコをもらった
class GotChocolateTrue extends Friend
    cmplType:"GotChocolateTrue"
    getJobname:-> @game.i18n.t "roles:GotChocolateTrue.jobname", {jobname: @main.getJobname()}
    getJobDisp:->@main.getJobDisp()
    getPartner:->
        if @cmplType=="GotChocolateTrue"
            return @cmplFlag
        else
            return @main.getPartner()
    makejobinfo:(game,result)->
        # 恋人情報はでない
        @sub?.makejobinfo? game,result
        @mcall game,@main.makejobinfo,game,result
# 本命ではない
class GotChocolateFalse extends Complex
    cmplType:"GotChocolateFalse"

# 黒になった
class Blacked extends Complex
    cmplType:"Blacked"
    getFortuneResult:-> FortuneResult.werewolf
    getPsychicResult:-> PsychicResult.werewolf

# 白になった
class Whited extends Complex
    cmplType:"Whited"
    getFortuneResult:-> FortuneResult.human
    getPsychicResult:-> PsychicResult.human

# 占い結果ヴァンパイア化
class VampireBlooded extends Complex
    cmplType:"VampireBlooded"
    getFortuneResult:-> FortuneResult.vampire

# 催眠術をかけられた
class UnderHypnosis extends Complex
    cmplType:"UnderHypnosis"
    sunrise:(game)->
        # 昼になったら戻る
        @mcall game,@main.sunrise,game
        @uncomplex game
    midnight:(game,midnightSort)->
    die:(game,found,from)->
        Human.prototype.die.call @,game,found,from
    dying:(game,found,from)->
        Human.prototype.dying.call @,game,found,from
    touched:(game,from)->
    divined:(game,player)->
    voteafter:(game,target)->
# 獅子舞の加護
class VoteGuarded extends Complex
    cmplType:"VoteGuarded"
    modifyMyVote:(game, vote)->
        if @sub?
            vote = @sub.modifyMyVote game, vote
        vote = @mcall game, @main.modifyMyVote, game, vote

        # 自分への投票を1票減らす
        if vote.votes > 0
            vote.votes--
        vote

# かぼちゃ魔の呪い
class PumpkinCostumed extends Complex
    cmplType:"PumpkinCostumed"
    getFortuneResult:-> FortuneResult.pumpkin
# ファンになった人
class FanOfIdol extends Complex
    cmplType:"FanOfIdol"
    sunset:(game)->
        # If the idol is dead, skill is temporally disabled.
        pl = game.getPlayer @cmplFlag
        if pl?
            if pl.dead
                # OH MY GOD MY IDOL IS DEAD
                log =
                    mode: "skill"
                    to: @id
                    comment: game.i18n.t "roles:FanOfIdol.idolDead", {name: @name}
                splashlog game.id, game, log

                # First uncomplex FanOfIdol.
                @uncomplex game
                # Then, compound with WatchingFireworks (XXX 使い回し)
                pl = game.getPlayer @id
                return unless pl?
                newpl = Player.factory null, game, pl, null, WatchingFireworks
                pl.transProfile newpl
                pl.transform game, newpl, true
                pl = game.getPlayer @id
                pl.sunset game
                return
        # If nothing happended, do normal sunset.
        super
    makejobinfo:(game, result)->
        @sub?.makejobinfo? game, result
        @mcall game, @main.makejobinfo, game, result

        # add description of fan.
        result.desc?.push {
            name: game.i18n.t "roles:FanOfIdol.name"
            type: "FanOfIdol"
        }

        # add fan-of info.
        pl = game.getPlayer @cmplFlag
        result.fanof = pl?.publicinfo()


# 決定者
class Decider extends Complex
    cmplType:"Decider"
    getJobname:-> @game.i18n.t "roles:Decider.jobname", {jobname: @main.getJobname()}
    dovote:(game,target)->
        result=@mcall game,@main.dovote,game,target
        return result if result?
        game.votingbox.votePriority this,1  #優先度を1上げる
        null
# 権力者
class Authority extends Complex
    cmplType:"Authority"
    getJobname:-> @game.i18n.t "roles:Authority.jobname", {jobname: @main.getJobname()}
    dovote:(game,target)->
        result=@mcall game,@main.dovote,game,target
        return result if result?
        game.votingbox.votePower this,1 #票をひとつ増やす
        null

# ケミカル人狼の役職
class Chemical extends Complex
    cmplType:"Chemical"
    getJobname:->
        if @sub?
            @game.i18n.t "roles:Chemical.jobname", {left: @main.getJobname(), right: @sub.getJobname()}
        else
            @main.getJobname()
    # same as above but uses getMainJobname.
    getMainJobname:->
        if @sub?
            @game.i18n.t "roles:Chemical.jobname", {left: @main.getMainJobname(), right: @sub.getMainJobname()}
        else
            @main.getMainJobname()
    getJobDisp:->
        if @sub?
            @game.i18n.t "roles:Chemical.jobname", {left: @main.getJobDisp(), right: @sub.getJobDisp()}
        else
            @main.getJobDisp()
    getMainJobDisp:->
        if @sub?
            @game.i18n.t "roles:Chemical.jobname", {left: @main.getMainJobDisp(), right: @sub.getMainJobDisp()}
        else
            @main.getMainJobDisp()
    sleeping:(game)->@main.sleeping(game) && (!@sub? || @sub.sleeping(game))
    jobdone:(game)->@main.jobdone(game) && (!@sub? || @sub.jobdone(game))
    deadJobdone:(game)->@main.deadJobdone(game) && (!@sub? || @sub.deadJobdone(game))

    isHuman:->
        if @sub?
            @main.isHuman() && @sub.isHuman()
        else
            @main.isHuman()
    isWerewolf:-> @main.isWerewolf() || @sub?.isWerewolf()
    isFox:-> @main.isFox() || @sub?.isFox()
    isWerewolfVisible:-> @main.isWerewolfVisible() || @sub?.isWerewolfVisible()
    isFoxVisible:-> @main.isFoxVisible() || @sub?.isFoxVisible()
    isVampire:-> @main.isVampire() || @sub?.isVampire()
    isAttacker:-> @main.isAttacker?() || @sub?.isAttacker?()
    humanCount:->
        if @isFox()
            0
        else if @isWerewolf()
            0
        else if @isVampire()
            0
        else if @isHuman()
            if @sub?
                Math.max @main.humanCount(), @sub.humanCount()
            else
                @main.humanCount()
        else
            0
    werewolfCount:->
        if @isFox()
            0
        else if @isVampire()
            0
        else if @isWerewolf()
            if @sub?
                @main.werewolfCount() + @sub.werewolfCount()
            else
                @main.werewolfCount()
        else
            0
    vampireCount:->
        if @isFox()
            0
        else if @isVampire()
            if @sub?
                @main.vampireCount() + @sub.vampireCount()
            else
                @main.vampireCount()
        else
            0
    getFortuneResult:->
        fsm = @main.getFortuneResult()
        fss = @sub?.getFortuneResult()
        if FortuneResult.vampire in [fsm, fss]
            FortuneResult.vampire
        else if FortuneResult.werewolf in [fsm, fss]
            FortuneResult.werewolf
        else
            FortuneResult.human
    getPsychicResult:->
        fsm = @main.getPsychicResult()
        if @sub?
            fss = @sub.getPsychicResult()
            PsychicResult.combineChemical fsm, fss
        else
            fsm
    getTeam:->
        myt = null
        maint = @main.getTeam()
        subt = @sub?.getTeam()
        if maint=="Cult" || subt=="Cult"
            myt = "Cult"
        else if maint=="Friend" || subt=="Friend"
            myt = "Friend"
        else if maint=="Fox" || subt=="Fox"
            myt = "Fox"
        else if maint=="Vampire" || subt=="Vampire"
            myt = "Vampire"
        else if maint=="Werewolf" || subt=="Werewolf"
            myt = "Werewolf"
        else if maint=="LoneWolf" || subt=="LoneWolf"
            myt = "LoneWolf"
        else if maint=="Human" || subt=="Human"
            myt = "Human"
        else
            myt = ""
        return myt
    isWinner:(game,team)->
        myt = @getTeam()
        win = false
        maint = @main.getTeam()
        subt = @sub?.getTeam()
        if maint == myt || maint == "" || maint == "Devil"
            win = win || @main.isWinner(game,team)
        if subt == myt || subt == "" || subt == "Devil"
            win = win || @sub.isWinner(game,team)
        return win
    isWinnerStalk:(game,team,ids)->
        if @id in ids
            # infinite loop of Stalkers is formed, so terminate by false.
            return false
        # same as above but stalker-aware.
        myt = @getTeam()
        win = false
        maint = @main.getTeam()
        subt = @sub?.getTeam()
        if maint == myt || maint == "" || maint == "Devil"
            if @main.isWinnerStalk?
                win = win || @main.isWinnerStalk(game, team, ids.concat @id)
            else
                win = win || @main.isWinner(game,team)
        if subt == myt || subt == "" || subt == "Devil"
            if @sub.isWinnerStalk?
                win = win || @sub.isWinnerStalk(game, team, ids.concat @id)
            else
                win = win || @sub.isWinner(game,team)
        return win

    die:(game, found, from)->
        return if @dead
        if found=="werewolf" && (!@willDieWerewolf || (@sub? && !@sub.willDieWerewolf))
            # 人狼に対する襲撃耐性
            game.addGuardLog @id, AttackKind.werewolf, GuardReason.tolerance
            return
        # main, subに対してdieをsimulateする（ただしdyingはdummyにする）
        d = Object.getOwnPropertyDescriptor(this, "dying")
        @dying = ()-> null

        # どちらかが耐えたら耐える
        @main.die game, found, from
        isdead = @dead

        pl = game.getPlayer @id
        pl.setDead false, null
        if @sub?
            @sub.die game, found, from
            isdead = isdead && @dead
        if d?
            Object.defineProperty this, "dying", d
        else
            delete @dying

        # XXX duplicate
        pl=game.getPlayer @id
        if isdead
            pl.setDead true, found
            pl.dying game, found, from
        else
            pl.setDead false, null
    touched:(game, from)->
        @mcall game, @main.touched, game, from
        @sub?.touched game, from
    makejobinfo:(game,result)->
        @main.makejobinfo game,result
        @sub?.makejobinfo? game,result
        # 女王観戦者は村人陣営×村人陣営じゃないと見えない
        if result.queens? && (@main.getTeam() != "Human" || @sub?.getTeam() != "Human")
            delete result.queens




games={}

# ゲームのGC
new cron.CronJob("0 0 * * * *", ->
    # いらないGameを消す
    tm=Date.now()-3600000   # 1時間前
    for id,game of games
        if game.finished
            # 終わっているやつが消す候補
            if (!game.last_time?) || (game.last_time<tm)
                # 十分古い
                delete games[id]
    return
, null, true, "Asia/Tokyo")


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
    WanderingGuard:WanderingGuard
    ObstructiveMad:ObstructiveMad
    TroubleMaker:TroubleMaker
    FrankensteinsMonster:FrankensteinsMonster
    BloodyMary:BloodyMary
    King:King
    PsychoKiller:PsychoKiller
    SantaClaus:SantaClaus
    Phantom:Phantom
    BadLady:BadLady
    DrawGirl:DrawGirl
    CautiousWolf:CautiousWolf
    Pyrotechnist:Pyrotechnist
    Baker:Baker
    Bomber:Bomber
    Blasphemy:Blasphemy
    Ushinotokimairi:Ushinotokimairi
    Patissiere:Patissiere
    GotChocolate:GotChocolate
    MadDog:MadDog
    Hypnotist:Hypnotist
    CraftyWolf:CraftyWolf
    Shishimai:Shishimai
    Pumpkin:Pumpkin
    MadScientist:MadScientist
    SpiritPossessed:SpiritPossessed
    Forensic:Forensic
    Cosplayer:Cosplayer
    TinyGhost:TinyGhost
    Ninja:Ninja
    Twin:Twin
    Hunter:Hunter
    MadHunter:MadHunter
    MadCouple:MadCouple
    Emma:Emma
    EyesWolf:EyesWolf
    TongueWolf:TongueWolf
    BlackCat:BlackCat
    Idol:Idol
    XianFox:XianFox
    LurkingMad:LurkingMad
    # 特殊
    GameMaster:GameMaster
    Helper:Helper
    # 開始前
    Waiting:Waiting
    Watching:Watching

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
    DivineObstructed:DivineObstructed
    PhantomStolen:PhantomStolen
    KeepedLover:KeepedLover
    WatchingFireworks:WatchingFireworks
    BombTrapped:BombTrapped
    FoxMinion:FoxMinion
    DivineCursed:DivineCursed
    GotChocolateTrue:GotChocolateTrue
    GotChocolateFalse:GotChocolateFalse
    Blacked:Blacked
    Whited:Whited
    VampireBlooded:VampireBlooded
    UnderHypnosis:UnderHypnosis
    VoteGuarded:VoteGuarded
    Chemical:Chemical
    PumpkinCostumed:PumpkinCostumed
    FanOfIdol:FanOfIdol

    # 役職ごとの強さ
jobStrength=
    Human:5
    Werewolf:40
    Diviner:25
    Psychic:15
    Madman:10
    Guard:23
    Couple:10
    Fox:25
    Poisoner:20
    BigWolf:80
    TinyFox:10
    Bat:10
    Noble:12
    Slave:5
    Magician:14
    Spy:14
    WolfDiviner:60
    Fugitive:8
    Merchant:18
    QueenSpectator:20
    MadWolf:40
    Neet:50
    Liar:8
    Spy2:5
    Copier:10
    Light:30
    Fanatic:20
    Immoral:5
    Devil:20
    ToughGuy:11
    Cupid:37
    Stalker:10
    Cursed:2
    ApprenticeSeer:23
    Diseased:16
    Spellcaster:6
    Lycan:5
    Priest:17
    Prince:17
    PI:23
    Sorcerer:14
    Doppleganger:15
    CultLeader:10
    Vampire:40
    LoneWolf:28
    Cat:22
    Witch:23
    Oldman:4
    Tanner:15
    OccultMania:10
    MinionSelector:0
    WolfCub:70
    WhisperingMad:20
    Lover:25
    Thief:0
    Dog:7
    Dictator:18
    SeersMama:15
    Trapper:13
    WolfBoy:11
    Hoodlum:5
    QuantumPlayer:0
    RedHood:16
    Counselor:25
    Miko:14
    GreedyWolf:60
    FascinatingWolf:52
    SolitudeWolf:20
    ToughWolf:55
    ThreateningWolf:50
    HolyMarked:6
    WanderingGuard:10
    ObstructiveMad:19
    TroubleMaker:15
    FrankensteinsMonster:50
    BloodyMary:5
    King:15
    PsychoKiller:25
    SantaClaus:20
    Phantom:15
    BadLady:30
    DrawGirl:10
    CautiousWolf:45
    Pyrotechnist:20
    Baker:16
    Bomber:23
    Blasphemy:10
    Ushinotokimairi:19
    Patissiere:10
    MadDog:19
    Hypnotist:17
    CraftyWolf:48
    Shishimai:10
    Pumpkin:17
    MadScientist:20
    SpiritPossessed:4
    Forensic:13
    Cosplayer:20
    TinyGhost:5
    Ninja:18
    Twin:16
    Hunter:20
    MadHunter:17
    MadCouple:19
    Emma:17
    EyesWolf:70
    TongueWolf:60
    BlackCat:19
    Idol:12
    XianFox:35
    LurkingMad:9

module.exports.actions=(req,res,ss)->
    req.use 'user.fire.wall'
    req.use 'session'

    #ゲーム開始処理
    #成功：null
    gameStart:(roomid,query)->
        game=games[roomid]
        unless game?
            res i18n.t "error.common.noSuchGame"
            return
        Server.game.rooms.oneRoomS roomid,(room)->
            if room.error?
                res room.error
                return
            unless room.mode=="waiting"
                # すでに開始している
                res game.i18n.t "error.gamestart.alreadyStarted"
                return
            if room.players.some((x)->!x.start)
                res game.i18n.t "error.gamestart.notReady"
                return
            if room.gm!=true && query.yaminabe_hidejobs!="" && !(query.jobrule in ["特殊ルール.闇鍋","特殊ルール.一部闇鍋","特殊ルール.エンドレス闇鍋"])
                res game.i18n.t "error.gamestart.noHiddenRole"
                return


            # ルールオブジェクト用意
            ruleobj={
                number: room.players.length
                maxnumber:room.number
                blind:room.blind
                gm:room.gm
                day: parseInt query.day
                night: parseInt query.night
                remain: parseInt query.remain
                voting: parseInt query.voting
                # (n=15)秒ルール
                silentrule: parseInt(query.silentrule) ? 0
            }
            # 不正なアレははじく
            unless Number.isFinite(ruleobj.day) && Number.isFinite(ruleobj.night) && Number.isFinite(ruleobj.remain) && Number.isFinite(ruleobj.voting)
                res game.i18n.t "error.gamestart.invalidTime"
                return

            options={}  # オプションズ
            for opt in ["decider","authority","yaminabe_hidejobs"]
                options[opt]=query[opt] ? null

            joblist={}
            for job of jobs
                joblist[job]=0  # 一旦初期化
            for type of Shared.game.categories
                joblist["category_#{type}"] = 0
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
            if playersnumber<6
                res game.i18n.t "error.gamestart.playerNotEnough", {count: 6}
                return
            if query.jobrule=="特殊ルール.量子人狼" && playersnumber>=20
                # 多すぎてたえられない
                res game.i18n.t "error.gamestart.tooManyQuantum", {count: 19}
                return
            # ケミカル人狼の場合
            if query.chemical=="on"
                frees *= 2
                # 闇鍋と量子人狼は無理
                if query.jobrule in ["特殊ルール.エンドレス闇鍋","特殊ルール.量子人狼"]
                    res game.i18n.t "error.gamestart.noChemical"
                    return

            ruleinfo_str="" # 開始告知

            if query.jobrule in ["特殊ルール.自由配役","特殊ルール.一部闇鍋"]   # 自由のときはクエリを参考にする
                for job in Shared.game.jobs
                    joblist[job]=parseInt(query[job]) || 0    # 仕事の数
                # カテゴリも
                for type of Shared.game.categories
                    joblist["category_#{type}"]=parseInt(query["category_#{type}"]) || 0
                ruleinfo_str = getrulestr game.i18n, query.jobrule, joblist
            if query.jobrule in ["特殊ルール.闇鍋","特殊ルール.一部闇鍋","特殊ルール.エンドレス闇鍋"]
                # カテゴリ内の人数の合計がわかる関数
                countCategory=(categoryname)->
                    Shared.game.categories[categoryname].reduce(((prev,curr)->prev+(joblist[curr] ? 0)),0)+joblist["category_#{categoryname}"]

                # 闇鍋のときはランダムに決める
                plsh=Math.floor playersnumber/2   # 過半数

                if query.jobrule=="特殊ルール.一部闇鍋"
                    # 一部闇鍋のときはこちらで配分可能な役職を数える
                    for job in Shared.game.jobs
                        frees -= joblist[job]
                    for type of Shared.game.categories
                        frees -= joblist["category_#{type}"]
                ruleinfo_str = getrulestr game.i18n, query.jobrule, joblist

                safety={
                    jingais:false   # 人外の数を調整
                    teams:false     # 陣営の数を調整
                    jobs:false      # 職どうしの数を調整
                    strength:false  # 職の強さも考慮
                    reverse:false   # 職の強さが逆
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
                    when "super"
                        safety.jingais=true
                        safety.teams=true
                        safety.jobs=true
                        safety.strength=true
                    when "supersuper"
                        safety.jobs=true
                        safety.strength=true
                    when "reverse"
                        safety.jingais=true
                        safety.strength=true
                        safety.reverse=true


                # 闇鍋のときは入れないのがある
                exceptions=[]
                # 闇鍋で出してはいけない役職
                special_exceptions=["MinionSelector","Thief","GameMaster","Helper","QuantumPlayer","Waiting","Watching","GotChocolate"]
                exceptions.push special_exceptions...
                # ユーザーが指定した入れないの
                excluded_exceptions=[]
                # カテゴリをまとめてexceptionに追加する関数
                addCategoryToExceptions = (category)->
                    for job in Shared.game.categories[category]
                        exceptions.push job

                # チェックボックスが外れてるやつは登場しない
                if query.jobrule=="特殊ルール.一部闇鍋"
                    for job in Shared.game.jobs
                        if query["job_use_#{job}"] != "on"
                            # これは出してはいけない指定になっている
                            exceptions.push job
                            excluded_exceptions.push job
                # メアリーの特殊処理（セーフティ高じゃないとでない）
                if query.yaminabe_hidejobs=="" || !safety.jobs
                    exceptions.push "BloodyMary"
                    special_exceptions.push "BloodyMary"
                # スパイ2（人気がないので出ない）
                if safety.jingais || safety.jobs
                    exceptions.push "Spy2"
                    special_exceptions.push "Spy2"
                # 悪霊憑き（人気がないので出ない）
                if safety.jingais || safety.jobs
                    exceptions.push "SpiritPossessed"
                    special_exceptions.push "SpiritPossessed"

                #人外の数
                if safety.jingais
                    # いい感じに決めてあげる
                    wolf_number=1
                    fox_number=0
                    vampire_number=0
                    devil_number=0
                    if playersnumber>=9
                        wolf_number++
                        if playersnumber>=12
                            if Math.random()<0.6
                                fox_number++
                            else if Math.random()<0.7
                                devil_number++
                            if playersnumber>=14
                                wolf_number++
                                if playersnumber>=16
                                    if Math.random()<0.5
                                        fox_number++
                                    else if Math.random()<0.3
                                        vampire_number++
                                    else
                                        devil_number++
                                    if playersnumber>=18
                                        wolf_number++
                                        if playersnumber>=22
                                            if Math.random()<0.2
                                                fox_number++
                                            else if Math.random()<0.6
                                                vampire_number++
                                            else if Math.random()<0.9
                                                devil_number++
                                        if playersnumber>=24
                                            wolf_number++
                                            if playersnumber>=30
                                                wolf_number++
                    # ランダム調整
                    if wolf_number>1 && Math.random()<0.1
                        wolf_number--
                    else if playersnumber>0 && playersnumber>=10 && Math.random()<0.2
                        wolf_number++
                    if fox_number>1 && Math.random()<0.15
                        fox_number--
                    else if playersnumber>=11 && Math.random()<0.25
                        fox_number++
                    else if playersnumber>=8 && Math.random()<0.1
                        fox_number++
                    if playersnumber>=11 && Math.random()<0.2
                        vampire_number++
                    if playersnumber>=11 && Math.random()<0.2
                        devil_number++

                    if query.jobrule == "特殊ルール.一部闇鍋"
                        # 一部闇鍋の指定との兼ね合いを調整する
                        if countCategory("Werewolf") > wolf_number
                            # 多いのでそちらに合わせる
                            wolf_number = countCategory("Werewolf")
                        if countCategory("Fox") + joblist.Blasphemy > fox_number
                            fox_number = countCategory("Fox") + joblist.Blasphemy
                    # セットする
                    diff = wolf_number - countCategory("Werewolf")
                    if diff > 0
                        joblist.category_Werewolf += diff
                        frees -= diff

                    # 除外役職を入れないように気をつける
                    nonavs = {}
                    for job in exceptions
                        nonavs[job] = true

                    # 狐を振分け
                    diff = fox_number - countCategory("Fox") - joblist.Blasphemy

                    for i in [0...diff]
                        if frees <= 0
                            break
                        r = Math.random()
                        if r<0.55 && !nonavs.Fox
                            joblist.Fox++
                            frees--
                        else if r<0.85 && !nonavs.TinyFox
                            joblist.TinyFox++
                            frees--
                        else if !nonavs.Blasphemy
                            joblist.Blasphemy++
                            frees--

                    diff = vampire_number - joblist.Vampire
                    if !nonavs.Vampire && diff > 0
                        if diff <= frees
                            joblist.Vampire += diff
                            frees -= diff
                        else
                            joblist.Vampire += frees
                            frees = 0

                    diff = devil_number - joblist.Devil
                    if !nonavs.Devil && diff > 0
                        if diff <= frees
                            joblist.Devil += diff
                            frees -= diff
                        else
                            joblist.Devil += frees
                            frees = 0
                    # 人外は選んだのでもう選ばれなくする
                    exceptions=exceptions.concat Shared.game.nonhumans
                    exceptions.push "Blasphemy"
                else
                    # 人狼0は避ける最低限の調整
                    if countCategory("Werewolf") == 0
                        joblist.category_Werewolf=1
                        frees--


                if safety.jingais || safety.jobs
                    if joblist.Fox==0 && joblist.TinyFox==0
                        exceptions.push "Immoral"   # 狐がいないのに背徳は出ない


                nonavs = {}
                for job in exceptions
                    nonavs[job] = true

                if safety.teams
                    # 陣営調整もする
                    # 人狼陣営
                    if frees>0
                        # 望ましい人狼陣営の人数は25〜350%くらい
                        wolfteam_n = Math.round (playersnumber*(0.25 + Math.random()*0.1))
                        # ただし半数を超えない
                        plsh = Math.ceil(playersnumber/2)
                        if wolfteam_n >= plsh
                            wolfteam_n = plsh-1
                        # 人狼系を数える
                        wolf_number = countCategory "Werewolf"
                        # 残りは狂人系
                        if wolf_number <= wolfteam_n
                            mad_number = Math.min(frees, wolfteam_n - wolf_number)
                            diff = mad_number - countCategory("Madman")
                            if diff > 0
                                joblist.category_Madman += diff
                            frees -= diff
                        # 狂人の処理終了
                        addCategoryToExceptions "Madman"
                    # 村人陣営
                    if frees>0
                        # 50%〜60%くらい
                        humanteam_n =
                            if query.chemical == "on"
                                # ケミカルの場合は多い
                                Math.round (playersnumber*(1.28 + Math.random()*0.12))
                            else
                                Math.round (playersnumber*(0.48 + Math.random()*0.12))
                        diff = Math.min(frees, humanteam_n) - countCategory("Human")
                        if diff > 0
                            joblist.category_Human += diff
                            frees -= diff

                        addCategoryToExceptions "Human"

                    # 妖狐陣営
                    if frees>0 && joblist.Fox>0
                        if joblist.Fox==1
                            if playersnumber>=14
                                # 1人くらいは…
                                if Math.random()<0.25 && !nonavs.Immoral
                                    joblist.Immoral++
                                    frees--
                            else
                                # サプライズ的に…
                                if Math.random()<0.06 && !nonavs.Immoral
                                    joblist.Immoral++
                                    frees--
                        # 背徳者系
                        exceptions.push "Immoral"
                    # 恋人陣営
                    if frees>0
                        if 17>=playersnumber>=12
                            if Math.random()<0.1 && !nonavs.Cupid
                                joblist.Cupid++
                                frees--
                            else if Math.random()<0.09 && !nonavs.Lover
                                joblist.Lover++
                                frees--
                            else if Math.random()<0.07 && !nonavs.BadLady
                                joblist.BadLady++
                                frees--
                        else if 12>=playersnumber>=8
                            if Math.random()<0.085 && !nonavs.Lover
                                joblist.Lover++
                                frees--
                            else if Math.random()<0.03 && !nonavs.Cupid
                                joblist.Cupid++
                                frees--
                        else if playersnumber>=17
                            rval = 1
                            while Math.random() < rval
                                if Math.random()<0.14 && !nonavs.Cupid
                                    joblist.Cupid++
                                    frees--
                                else if Math.random()<0.12 && !nonavs.Lover
                                    joblist.Lover++
                                    frees--
                                else if Math.random()<0.1 && !nonavs.BadLady
                                    joblist.BadLady++
                                    frees--
                                else
                                    break
                                rval *= 0.6
                    exceptions.push "Cupid", "Lover", "BadLady", "Patissiere"

                # 占い確定
                if safety.teams || safety.jobs
                    # 村人陣営
                    # 占い師いてほしい
                    if joblist.category_Human > 0
                        if Math.random()<0.75 && !nonavs.Diviner
                            joblist.Diviner++
                            joblist.category_Human--
                        else if !safety.jobs && Math.random()<0.2 && !nonavs.ApprenticeSeer
                            joblist.ApprenticeSeer++
                            joblist.category_Human--
                    else if frees>0
                        if Math.random()<0.75 && !nonavs.Diviner
                            joblist.Diviner++
                            frees--
                        else if !safety.jobs && Math.random()<0.2 && !nonavs.ApprenticeSeer
                            joblist.ApprenticeSeer++
                            frees--
                if safety.teams
                    # できれば狩人も
                    if joblist.category_Human > 0
                        if joblist.Diviner>0
                            if Math.random()<0.4 && !nonavs.Guard
                                joblist.Guard++
                                joblist.category_Human--
                            else if Math.random()<0.17 && !nonavs.WanderingGuard
                                joblist.WanderingGuard++
                                joblist.category_Human--
                        else if Math.random()<0.4 && !nonavs.Guard
                            joblist.Guard++
                            joblist.category_Human--
                    else if frees>0
                        if joblist.Diviner>0
                            if Math.random()<0.4 && !nonavs.Guard
                                joblist.Guard++
                                frees--
                            else if Math.random()<0.17 && !nonavs.WanderingGuard
                                joblist.WanderingGuard++
                                frees--
                        else if Math.random()<0.4 && !nonavs.Guard
                            joblist.Guard++
                            frees--
                ((date)->
                    month=date.getMonth()
                    d=date.getDate()
                    # 期間機率提升
                    if month==11 && 24<=d<=25
                        # 12/24〜12/25はサンタがよくでる
                        if Math.random()<0.5 && frees>0 && !nonavs.SantaClaus
                            joblist.SantaClaus ?= 0
                            joblist.SantaClaus++
                            frees--
                    else
                        # サンタは出にくい
                        if Math.random()<0.8
                            exceptions.push "SantaClaus"
                    unless month==6 && 26<=d || month==7 && d<=16
                        # 期間外は花火師は出にくい
                        if Math.random()<0.7
                            exceptions.push "Pyrotechnist"
                    else
                        # ちょっと出やすい
                        if Math.random()<0.11 && frees>0 && !nonavs.Pyrotechnist
                            joblist.Pyrotechnist ?= 0
                            joblist.Pyrotechnist++
                            frees--
                    if month==11 && 24<=d<=25 || month==1 && d==14
                        # 爆弾魔がでやすい
                        if Math.random()<0.5 && frees>0 && !nonavs.Bomber
                            joblist.Bomber ?= 0
                            joblist.Bomber++
                            frees--
                    if month==1 && 13<=d<=14
                        # パティシエールが出やすい
                        if Math.random()<0.4 && frees>0 && !nonavs.Patissiere
                            joblist.Patissiere ?= 0
                            joblist.Patissiere++
                            frees--
                    else
                        # 出にくい
                        if Math.random()<0.84
                            exceptions.push "Patissiere"
                    if month==0 && d<=3
                        # 正月は巫女がでやすい
                        if Math.random()<0.35 && frees>0 && !nonavs.Miko
                            joblist.Miko ?= 0
                            joblist.Miko++
                            frees--
                    if month==3 && d==1
                        # 4月1日は嘘つきがでやすい
                        if Math.random()<0.5 && !nonavs.Liar
                            while frees>0
                                joblist.Liar ?= 0
                                joblist.Liar++
                                frees--
                                if Math.random()<0.75
                                    break
                    if month==11 && d==31 || month==0 && 4<=d<=7
                        # 獅子舞の季節
                        if Math.random()<0.5 && frees>0 && !nonavs.Shishimai
                            joblist.Shishimai ?= 0
                            joblist.Shishimai++
                            frees--
                    else if month==0 && 1<=d<=3
                        # 獅子舞の季節（真）
                        if Math.random()<0.7 && frees>0 && !nonavs.Shishimai
                            joblist.Shishimai ?= 0
                            joblist.Shishimai++
                            frees--
                    else
                        # 獅子舞がでにくい季節
                        if Math.random()<0.8
                            exceptions.push "Shishimai"

                    if month==9 && 30<=d<=31
                        # ハロウィンなのでかぼちゃとおばけ
                        if Math.random()<0.2 && frees>0 && !nonavs.Pumpkin
                            joblist.Pumpkin ?= 0
                            joblist.Pumpkin++
                            frees--
                        else if Math.random()<0.25 && frees>0 && !nonavs.TinyGhost
                            joblist.TinyGhost ?= 0
                            joblist.TinyGhost++
                            frees--
                    else
                        if Math.random()<0.2
                            exceptions.push "Pumpkin"

                )(new Date)

                possibility=Object.keys(jobs).filter (x)->!(x in exceptions)
                if possibility.length == 0
                    # 0はまずい
                    possibility.push "Human"

                # 強制的に入れる関数
                init=(jobname,categoryname)->
                    unless jobname in possibility
                        return false
                    if categoryname? && joblist["category_#{categoryname}"]>0
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

                # セーフティ超用
                trial_count=0
                trial_max=if safety.strength then 40 else 1
                best_list=null
                best_points=null
                if safety.reverse
                    best_diff=-Infinity
                else
                    best_diff=Infinity
                first_list=joblist
                first_frees=frees
                # チームのやつキャッシュ
                teamCache={}
                getTeam=(job)->
                    if teamCache[job]?
                        return teamCache[job]
                    for team of Shared.game.teams
                        if job in Shared.game.teams[team]
                            teamCache[job]=team
                            return team
                    return null
                while trial_count++ < trial_max
                    joblist=copyObject first_list
                    #wolf_teams=countCategory "Werewolf"
                    wolf_teams=0
                    frees=first_frees
                    while true
                        category=null
                        job=null
                        #カテゴリ役職がまだあるか探す
                        for type,arr of Shared.game.categories
                            if joblist["category_#{type}"]>0
                                # カテゴリの中から候補をしぼる
                                arr2 = arr.filter (x)->!(x in excluded_exceptions) && !(x in special_exceptions)
                                if arr2.length > 0
                                    r=Math.floor Math.random()*arr2.length
                                    job=arr2[r]
                                    category="category_#{type}"
                                    break
                                else
                                    # これもう無理だわ
                                    joblist["category_#{type}"] = 0
                        unless job?
                            # もうカテゴリがない
                            if frees<=0
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
                                when "Twin"
                                    # 双子も
                                    if joblist.Twin==0
                                        unless init "Twin","Human"
                                            continue
                                when "MadCouple"
                                    # 叫迷も
                                    if joblist.MadCouple==0
                                        unless init "MadCouple","Madman"
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
                                    if joblist.Diviner==0 && Math.random()<0.5
                                        # 占い師いないと出現確率低い
                                        continue
                                when "QueenSpectator"
                                    # 2人いたらだめ
                                    if joblist.QueenSpectator>0 || joblist.Spy2>0 || joblist.BloodyMary>0
                                        continue
                                    if Math.random()>0.1
                                        # 90%の確率で弾く
                                        continue
                                    # 女王観戦者はガードがないと不安
                                    if joblist.Guard==0 && joblist.Priest==0 && joblist.Trapper==0
                                        unless Math.random()<0.4 && init "Guard","Human"
                                            unless Math.random()<0.5 && init "Priest","Human"
                                                unless init "Trapper","Human"
                                                    # 護衛がいない
                                                    continue
                                when "Spy2"
                                    # スパイIIは2人いるとかわいそうなので入れない
                                    if joblist.Spy2>0 || joblist.QueenSpectator>0
                                        continue
                                    else if Math.random()>0.1
                                        # 90%の確率で弾く（レア）
                                        continue
                                when "MadWolf"
                                    if Math.random()>0.1
                                        # 90%の確率で弾く（レア）
                                        continue
                                when "Lycan","SeersMama","Sorcerer","WolfBoy","ObstructiveMad"
                                    # 占い系がいないと入れない
                                    if joblist.Diviner==0 && joblist.ApprenticeSeer==0 && joblist.PI==0
                                        continue
                                when "LoneWolf","FascinatingWolf","ToughWolf","WolfCub"
                                    # 誘惑する女狼はほかに人狼がいないと効果発揮しない
                                    # 一途な狼はほかに狼いないと微妙、一匹狼は1人だけででると狂人が絶望
                                    if countCategory("Werewolf")-(if category? then 1 else 0)==0
                                        continue
                                when "BigWolf"
                                    # 強いので狼2以上
                                    if countCategory("Werewolf")-(if category? then 1 else 0)==0
                                        continue
                                    # 霊能を出す
                                    unless Math.random()<0.15 ||  init "Psychic","Human"
                                        continue
                                when "BloodyMary"
                                    # 狼が2以上必要
                                    if countCategory("Werewolf")<=1
                                        continue
                                    # 女王とは共存できない
                                    if joblist.QueenSpectator>0
                                        continue
                                when "SpiritPossessed"
                                    # 2人いるとうるさい
                                    if joblist.SpiritPossessed > 0
                                        continue

                        joblist[job]++
                        # ひとつ追加
                        if category?
                            joblist[category]--
                        else
                            frees--

                        if safety.teams && (job in Shared.game.teams.Werewolf)
                            wolf_teams++    # 人狼陣営が増えた
                    # セーフティ超の場合判定が入る
                    if safety.strength
                        # ポイントを計算する
                        points=
                            Human:0
                            Werewolf:0
                            Others:0
                        for job of jobStrength
                            if joblist[job]>0
                                switch getTeam(job)
                                    when "Human"
                                        points.Human+=jobStrength[job]*joblist[job]
                                    when "Werewolf"
                                        points.Werewolf+=jobStrength[job]*joblist[job]
                                    else
                                        points.Others+=jobStrength[job]*joblist[job]
                        # 判定する
                        if points.Others>points.Human || points.Others>points.Werewolf
                            # だめだめ
                            continue
                        # jgs=Math.sqrt(points.Werewolf*points.Werewolf+points.Others*points.Others)
                        jgs = points.Werewolf+points.Others
                        diff=Math.abs(points.Human-jgs)
                        if safety.reverse
                            # 逆
                            diff+=points.Others
                            if diff>best_diff
                                best_list=copyObject joblist
                                best_diff=diff
                                best_points=points
                        else
                            if diff<best_diff
                                best_list=copyObject joblist
                                best_diff=diff
                                best_points=points
                                #console.log "diff:#{diff}"
                                #console.log best_list

                if safety.strength && best_list?
                    # セーフティ超
                    joblist=best_list

                if query.divineresult=="immediate" && ["WolfBoy", "ObstructiveMad", "Pumpkin", "Patissiere", "Hypnotist"].some((job)-> joblist[job] > 0)
                    query.divineresult="sunrise"
                    log=
                        mode:"system"
                        comment: game.i18n.t "system.gamestart.divinerModeChanged"
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
                ruleinfo_str = getrulestr game.i18n, query.jobrule, list_for_rule


            else if query.jobrule!="特殊ルール.自由配役"
                # 配役に従ってアレする
                func=Shared.game.getrulefunc query.jobrule
                unless func
                    res game.i18n.t "error.gamestart.unknownCasting"
                    return
                joblist=func playersnumber
                sum=0   # 穴を埋めつつ合計数える
                for job of jobs
                    unless joblist[job]?
                        joblist[job]=0
                    else
                        sum+=joblist[job]
                # カテゴリも
                for type of Shared.game.categories
                    if joblist["category_#{type}"]>0
                        sum-=parseInt joblist["category_#{type}"]
                # 残りは村人だ！
                joblist.Human = frees - sum
                ruleinfo_str = getrulestr game.i18n, query.jobrule, joblist
            if query.yaminabe_hidejobs!="" && query.jobrule!="特殊ルール.闇鍋" && query.jobrule!="特殊ルール.一部闇鍋" && query.jobrule!="特殊ルール.エンドレス闇鍋"
                # 闇鍋以外で配役情報を公開しないときはアレする
                ruleinfo_str = ""
            if query.chemical == "on"
                # ケミカル人狼の場合は表示
                ruleinfo_str = "#{game.i18n.t "common.chemicalWerewolf"}　" + (ruleinfo_str ? "")

            if ruleinfo_str != ""
                # 表示すべき情報がない場合は表示しない
                log=
                    mode:"system"
                    comment: game.i18n.t "system.gamestart.casting", {casting: ruleinfo_str}
                splashlog game.id,game,log
            if query.jobrule == "特殊ルール.一部闇鍋" && excluded_exceptions.length > 0
                # 除外役職の情報を表示する
                exclude_str = excluded_exceptions.map((job)-> game.i18n.t "roles:jobname.#{job}").join ", "
                log=
                    mode:"system"
                    comment: game.i18n.t "system.gamestart.excluded", {jobnames: exclude_str}
                splashlog game.id,game,log


            if query.yaminabe_hidejobs=="team"
                # 陣営のみ公開モード
                # 各陣営
                teaminfos=[]
                teamcount={}
                for team of Shared.game.jobinfo
                    teamcount[team] = 0
                for team,obj of Shared.game.jobinfo
                    for job,num of joblist
                        #出現役職チェック
                        continue if num==0
                        if obj[job]?
                            # この陣営だ
                            if query.hide_singleton_teams == "on" && team in ["Devil", "Vampire", "Cult"]
                                # count as その他
                                teamcount["Others"] += num
                            else
                                teamcount[team] += num
                for team of Shared.game.jobinfo
                    if teamcount[team]>0
                        teaminfos.push "#{i18n.t "roles:teamName.#{team}"}#{teamcount[team]}"    #陣営名

                log=
                    mode:"system"
                    comment: game.i18n.t "system.gamestart.teams", {info: teaminfos.join(" ")}
                splashlog game.id,game,log
            if query.jobrule in ["特殊ルール.闇鍋","特殊ルール.一部闇鍋","特殊ルール.エンドレス闇鍋"]
                if query.yaminabe_hidejobs==""
                    # 闇鍋用の役職公開ログ
                    jobinfos=[]
                    for job,num of joblist
                        continue if num==0
                        jobinfos.push "#{game.i18n.t "roles:jobname.#{job}"}#{num}"
                    log=
                        mode:"system"
                        comment: game.i18n.t "system.gamestart.roles", {info: jobinfos.join(" ")}
                    splashlog game.id,game,log


            for x in ["jobrule",
            "decider","authority","scapegoat","will","wolfsound","couplesound","heavenview",
            "wolfattack","guardmyself","votemyself","deadfox","deathnote","divineresult","psychicresult","waitingnight",
            "safety","friendsjudge","noticebitten","voteresult","GMpsychic","wolfminion","drunk","losemode","gjmessage","rolerequest","runoff","drawvote","chemical",
            "firstnightdivine","consecutiveguard",
            "hunter_lastattack",
            "poisonwolf",
            "friendssplit",
            "quantumwerewolf_table","quantumwerewolf_dead","quantumwerewolf_diviner","quantumwerewolf_firstattack","yaminabe_hidejobs","yaminabe_safety",
            "hide_singleton_teams"
            ]

                ruleobj[x]=query[x] ? null
            # add query job info to rule obj
            ruleobj._jobquery = {}
            for job in Shared.game.jobs
                ruleobj._jobquery["job_use_#{job}"] = query["job_use_#{job}"]
                ruleobj._jobquery[job] = query[job]
            for type of Shared.game.categories
                ruleobj._jobquery["category_#{type}"] = query["category_#{type}"]

            game.setrule ruleobj
            # 配役リストをセット
            game.joblist=joblist
            game.startoptions=options
            game.startplayers=players
            game.startsupporters=supporters
            # プレイヤー人数をチェック
            err = game.checkPlayerNumber()
            if err?
                res err
                return

            if ruleobj.rolerequest=="on" && !(query.jobrule in ["特殊ルール.闇鍋","特殊ルール.一部闇鍋","特殊ルール.量子人狼","特殊ルール.エンドレス闇鍋"])
                # 希望役職制あり
                # とりあえず入れなくする
                M.rooms.update {id:roomid},{$set:{mode:"playing"}}
                # 役職選択中
                game.phase = Phase.rolerequesting
                game.rolerequesttable={}
                res null
                log=
                    mode:"system"
                    comment: game.i18n.t "system.gamestart.roleRequesting"
                splashlog game.id,game,log
                game.timer()
                ss.publish.channel "room#{roomid}","refresh",{id:roomid}
            else
                game.setplayers (result)->
                    unless result?
                        # プレイヤー初期化に成功
                        M.rooms.update {id:roomid},{
                            $set:{
                                mode:"playing",
                                jobrule:query.jobrule
                            }
                        }
                        game.nextturn()
                        res null
                        ss.publish.channel "room#{roomid}","refresh",{id:roomid}
                    else
                        res result
    # 情報を開示
    getlog:(roomid)->
        M.games.findOne {id:roomid}, (err,doc)=>
            if err?
                console.error err
                res {error: err}
            else if !doc?
                res {error: i18n.t "error.common.noSuchGame"}
            else
                unless games[roomid]?
                    games[roomid] = Game.unserialize doc,ss
                game = games[roomid]
                # ゲーム後の行動
                player=game.getPlayerReal req.session.userId
                result=
                    #logs:game.logs.filter (x)-> islogOK game,player,x
                    logs:game.makelogs (doc.logs ? []), player
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

    speak: (roomid,query)->
        game=games[roomid]
        unless game?
            res i18n.t "error.common.noSuchGame"
            return
        unless req.session.userId
            res game.i18n.t "error.common.needLogin"
            return
        unless query?
            res game.i18n.t "error.common.invalidQuery"
            return
        comment=query.comment
        unless comment
            res game.i18n.t "error.common.invalidQuery"
            return
        if comment.length > Config.maxlength.game.comment
            res game.i18n.t "error.speak.tooLong"
            return
        player=game.getPlayerReal req.session.userId

        unless player?
            # 観戦発言に対するチェック
            unless libblacklist.checkPermission "watch_say", req.session.ban
                res game.i18n.t "error.speak.ban"
                return
        # 発言できない時間帯
        if !game.finished  && Phase.isRemain(game.phase)   # 投票猶予時間は発言できない
            if player && !player.dead && !player.isJobType("GameMaster")
                res null
                return  #まだ死んでいないプレイヤーの場合は発言できないよ!

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
                    if player.isJobType "Spy" && player.flag=="spygone"
                        # スパイなら会話に参加できない
                        log.mode="monologue"
                        log.to=player.id
                    else if query.mode=="monologue"
                        # 霊界の独り言
                        log.mode="heavenmonologue"
                    else
                        log.mode="heaven"
                else if Phase.isDay(game.phase)
                    # 昼
                    unless query.mode in player.getSpeakChoiceDay game
                        res null
                        return
                    log.mode=query.mode
                    if game.silentexpires && game.silentexpires>=Date.now()
                        # まだ発言できない（15秒ルール）
                        res null
                        return
                else if Phase.isNight(game.phase) || player.isJobType("GameMaster") || player.isJobType("Helper")
                    # 夜
                    unless query.mode in player.getSpeakChoice game
                        query.mode="monologue"
                    log.mode=query.mode
                else
                    # ハンター時間
                    log.mode = "monologue"


            switch log.mode
                when "monologue","heavenmonologue","helperwhisper"
                    # helperwhisper:守り先が決まっていないヘルパー
                    log.to=player.id
                when "heaven"
                    # 霊界の発言は悪霊憑きの発言になるかも
                    if game.phase == Phase.day && !(game.silentexpires && game.silentexpires >= Date.now())
                        possessions = game.players.filter (x)-> !x.dead && x.isJobType "SpiritPossessed"
                        if possessions.length > 0
                            # 悪魔憑き
                            r = Math.floor (Math.random()*possessions.length)
                            pl = possessions[r]
                            # 悪魔憑きのプロパティ
                            log.possess_name = pl.name
                            log.possess_id = pl.id
                when "gm"
                    log.name= game.i18n.t "roles:jobname.GameMaster"
                when "gmheaven"
                    log.name= game.i18n.t "roles:GameMaster.heavenLog"
                when "gmaudience"
                    log.name= game.i18n.t "roles:GameMaster.audienceLog"
                when "gmmonologue"
                    log.name= game.i18n.t "roles:GameMaster.monologueLog"
                when "prepare"
                    # ごちゃごちゃ言わない
                else
                    if result=query.mode?.match /^gmreply_(.+)$/
                        log.mode="gmreply"
                        pl=game.getPlayer result[1]
                        unless pl?
                            res null
                            return
                        log.to=pl.id
                        log.name="GM→#{pl.name}"
                    else if result=query.mode?.match /^helperwhisper_(.+)$/
                        log.mode="helperwhisper"
                        log.to=result[1]

            splashlog roomid,game,log

            # log
            Server.log.speakInRoom roomid, log, req.session.user

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
            res {error: i18n.t "error.common.noSuchGame"}
            return
        unless req.session.userId
            res {error: game.i18n.t "error.common.needLogin"}
            return
        player=game.getPlayerReal req.session.userId
        unless player?
            res {error: game.i18n.t "error.common.notPlayer"}
            return
        unless player in game.participants
            res {error: game.i18n.t "error.common.notPlayer"}
            return
        if game.finished
            res {error: game.i18n.t "error.common.alreadyFinished"}
            return

        plobj = player.accessByObjid query.objid
        unless plobj?
            res {error: game.i18n.t "common:error.invalidInput"}
            return
        # check whether this query is valid.
        if game.phase == Phase.rolerequesting || Phase.isNight(game.phase) || game.phase == Phase.hunter || query.jobtype!="_day"  # 昼の投票
            # 夜
            unless plobj.checkJobValidity game,query
                res {error: game.i18n.t "error.job.invalid"}
                return
            # Error-check whether his job is already done.
            jdone =
                if game.phase == Phase.hunter
                    plobj.hunterJobdone(game)
                else if player.dead
                    plobj.deadJobdone(game)
                else
                    plobj.jobdone(game)
            if jdone
                res {error: game.i18n.t "error.job.done"}
                return
            # Error-check for jobtype
            unless plobj.isMainJobType query.jobtype
                res {error: game.i18n.t "error.job.invalid"}
                return
            # Other error message caused by the job
            if ret=plobj.job game,query.target,query
                console.log "job err!",ret
                res {error:ret}
                return
            # 能力発動を記録
            game.addGamelog {
                id:player.id
                type:query.jobtype
                target:query.target
                event:"job"
            }

            res makejobinfo game,player
            if game.phase == Phase.rolerequesting || Phase.isNight(game.phase) || game.phase == Phase.hunter
                # 能力をすべて発動したかどうかチェック
                game.checkjobs()
        else
            # 投票
            # voting is done against main player.
            unless player.checkJobValidity game,query
                res {error: game.i18n.t "error.voting.noTarget"}
                return
            if game.rule.voting > 0 && game.phase == Phase.day
                # 投票専用時間ではない
                res {error: game.i18n.t "error.voting.notNow"}
                return
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
            res i18n.t "error.common.noSuchGame"
            return
        unless req.session.userId
            res game.i18n.t "error.common.needLogin"
            return
        unless !game.rule || game.rule.will
            res game.i18n.t "error.will.noWill"
            return
        player=game.getPlayerReal req.session.userId
        unless player?
            res game.i18n.t "error.common.notPlayer"
            return
        if player.dead
            res game.i18n.t "error.will.alreadyDead"
            return
        player.setWill will
        res null
    #蘇生辞退
    norevive:(roomid)->
        game=games[roomid]
        unless game?
            res i18n.t "error.common.noSuchGame"
            return
        unless req.session.userId
            res game.i18n.t "error.common.needLogin"
            return
        player=game.getPlayerReal req.session.userId
        unless player?
            res game.i18n.t "error.common.notPlayer"
        player.setNorevive true
        log=
            mode:"userinfo"
            comment: game.i18n.t "system.declineRevival", {name: player.name}
            to:player.id
        splashlog roomid,game,log
        # 全員に通知
        game.splashjobinfo()
        res null



splashlog=(roomid,game,log)->
    log.time=Date.now() # 時間を付加
    #DBに追加
    game.logsaver.saveLog log
    #みんなに送信
    flash=(log)->
        # まず観戦者
        aulogs = makelogsFor game, null, log
        for x in aulogs
            x.roomid = roomid
            game.ss.publish.channel "room#{roomid}_audience","log",x
        # GM
        #if game.gm&&!rev
        #   game.ss.publish.channel "room#{roomid}_gamemaster","log",log
        # その他
        game.participants.forEach (pl)->
            ls = makelogsFor game, pl, log
            for x in ls
                x.roomid = roomid
                game.ss.publish.user pl.realid,"log",x
    flash log

# ある人に見せたいログ
makelogsFor=(game,player,log)->
    if islogOK game, player, log
        if log.mode=="heaven" && log.possess_name?
            # 両方見える感じで
            otherslog=
                mode:"half-day"
                comment: log.comment
                name: log.possess_name
                time: log.time
                size: log.size
            return [log, otherslog]

        return [log]

    if log.mode=="werewolf" && game.rule.wolfsound=="aloud"
        # 狼の遠吠えが聞こえる
        otherslog=
            mode:"werewolf"
            comment: game.i18n.t "logs.werewolf.comment"
            name: game.i18n.t "logs.werewolf.name"
            time:log.time
        return [otherslog]
    if log.mode in ["couple", "madcouple"] && game.rule.couplesound=="aloud"
        # 共有者の小声が聞こえる
        otherslog=
            mode:"couple"
            comment: game.i18n.t "logs.couple.comment"
            name: game.i18n.t "logs.couple.name"
            time:log.time
        return [otherslog]
    if log.mode=="heaven" && log.possess_name?
        # 昼の霊界発言 with 悪魔憑き
        otherslog =
            mode:"day"
            comment: log.comment
            name:log.possess_name
            time:log.time
            size:log.size
        return [otherslog]

    return []

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
    else if player.dead && game.heavenview
        true
    else if log.mode=="heaven" && log.possess_name?
        # 悪霊憑きについている霊界発言
        false
    else if log.to? && !isLogTarget(log.to, player)
        # I'm not the target of this log
        false
    else
        player.isListener game,log
# check whether player is a target of log.
isLogTarget = (to, player)->
    # targettable ids.
    # his own id and ids of helper targets.
    ids = [player.id].concat player.accessByJobTypeAll("Helper").map((pl)-> pl.flag)
    if Array.isArray to
        # to is an array of user ids!
        ids.some (id)-> id in to
    else
        # otherwise to is a string.
        to in ids
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
    is_gm = actpl?.isJobType("GameMaster")
    openjob_flag=game.finished || (actpl?.dead && game.heavenview) || is_gm
    result.openjob_flag = openjob_flag

    result.game=game.publicinfo({
        openjob: openjob_flag
        gm: is_gm
    })  # 終了か霊界（ルール設定あり）の場合は職情報公開
    result.id=game.id
    # List of forms for new client.
    result.forms = []

    if player
        # 参加者としての（perticipantsは除く）
        plpl=game.getPlayer player.id
        player.makejobinfo game,result
        result.playerid = player.id
        result.dead=player.dead
        # voteopen is for old forms
        result.voteopen=false
        result.sleeping=true
        # 投票が終了したかどうか（フォーム表示するかどうか判断）
        if plpl?
            # 参加者として

            # If Chemical, tell player's team.
            if game.rule?.chemical == "on"
                result.myteam = plpl.getTeamDisp()

            if Phase.isNight(game.phase) || game.phase == Phase.rolerequesting
                if player.dead
                    result.sleeping=player.deadJobdone game
                else
                    result.sleeping=player.jobdone game
            else if game.phase == Phase.hunter
                result.sleeping = player.hunterJobdone game
            else if Phase.isDay(game.phase)
                # 昼
                result.sleeping=true
                unless player.dead || (game.rule.voting > 0 && game.phase == Phase.day) || game.votingbox.isVoteFinished player
                    # 投票ボックスオープン!!!
                    result.voteopen=true
                    result.forms.push {
                        type: "_day"
                        options: player.makeJobSelection game
                        formType: FormType.required
                        objid: player.objid
                    }
                    result.sleeping=false
                if player.chooseJobDay game
                    # 昼でも能力発動できる人
                    result.sleeping &&= player.jobdone game
        else
            # それ以外（participants）
            if Phase.isNight(game.phase) || Phase.isDay(game.phase) && player.chooseJobDay(game)
                result.sleeping = player.jobdone(game)
            else if game.phase == Phase.hunter
                result.sleeping = player.hunterJobdone(game)
            else
                result.sleeping = true
        result.jobname=player.getJobDisp()
        result.winner=player.winner
        if player.dead
            result.speak =player.getSpeakChoiceHeaven game
        else if is_gm
            result.speak =player.getSpeakChoice game
        else if Phase.isNight(game.phase) || game.phase == Phase.rolerequesting
            result.speak =player.getSpeakChoice game
        else if Phase.isDay(game.phase)
            result.speak =player.getSpeakChoiceDay game
        else if game.phase == Phase.hunter
            result.speak = ["monologue"]
        else
            # 開始前
            result.speak = ["day"]
        if game.rule?.will=="die"
            result.will=player.will

    result

# ログ用の配役文字列を生成
getrulestr = (i18n, rule, jobs={})->
    ruleName = i18n.t "casting:castingName.#{rule}"
    if rule in ["特殊ルール.闇鍋", "特殊ルール.エンドレス闇鍋"]
        # just show rule name for these rules.
        return ruleName

    # make initial part of text.
    text = "#{ruleName} / "

    # write numbers of each role.
    for job in Shared.game.jobs
        num = jobs[job]
        continue unless parseInt num
        jobName = i18n.t "roles:jobname.#{job}"
        text+="#{jobName}#{num} "

    # write number of categories.
    for type of Shared.game.categories
        num = jobs["category_#{type}"]
        if num > 0
            catName = i18n.t "roles:categoryName.#{type}"
            text+="#{catName}#{num} "
    return text

# Generate an ID for use as Player objid.
generateObjId = ->
    "pl" + Math.random().toString(36).slice(2)

# Search a specific object in Player structure.
# Returns its parent, its top of main chain, and parent of the top.
searchPlayerInTree = (root, target)->
    # perform depth-first search.
    stack = [[root, null, root, null]]
    while stack.length > 0
        [pl, plParent, plTop, topParent] = stack.pop()
        if pl == target
            # Target is found.
            return [plParent, plTop, topParent]
        # otherwise, search its child,
        if pl.isComplex()
            if pl.sub?
                stack.push [pl.sub, pl, pl.sub, pl]
            stack.push [pl.main, pl, plTop, topParent]
    # Player was not found.
    return null
# Dig Player structure to find main-chain and its parent.
# If the main job is the target, parent would be null.
getSubParentAndMainChain = (top, target)->
    # construct a chain of Complexes from mainTop to target.
    constructChain = (topParent)->
        result = []
        while topParent.isComplex()
            result.push topParent
            topParent = topParent.main
        return [result, topParent]

    res = searchPlayerInTree top, target
    unless res?
        return null
    [_, chainTop, topParent] = res
    # construct a chain of Complexes.
    [complexChain, main] = constructChain chainTop
    return [topParent, complexChain, main]
# List up all main roles in given player.
getAllMainRoles = (top)->
    results = []
    stack = [top]
    while stack.length > 0
        pl = stack.pop()
        if pl.isComplex()
            if pl.sub?
                stack.push pl.sub
            stack.push pl.main
        else
            results.push pl
    return results

# 配列シャッフル（破壊的）
shuffle= (arr)->
    ret=[]
    while arr.length
        ret.push arr.splice(Math.floor(Math.random()*arr.length),1)[0]
    ret

# ゲーム情報ツイート
tweet=(roomid,message)->
    Server.oauth.template roomid,message,Config.admin.password

