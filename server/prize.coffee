Shared=
    game:require './../client/code/shared/game.coffee'
    prize:require './../client/code/shared/prize.coffee'

makePrize=->
    prizes={}
    # まず勝利回数による賞を作る
    for job,prs of wincountprize
        for num,name of prs
            prizes["wincount_#{job}_#{num}"]=name
    for job,prs of losecountprize
        for num,name of prs
            prizes["losecount_#{job}_#{num}"]=name
    for team,prs of winteamcountprize
        for num,name of prs
            prizes["winteamcount_#{team}_#{num}"]=name
    # 次に何かをカウントして合計する賞を作る
    for type,obj of counterprize
        for num,name of obj.names
            prizes["#{type}_#{num}"]=name
    # 単品の賞
    for prizeobjs in [ownprizesprize]
        for prizename,obj of prizeobjs
            prizes[prizename]=obj.name
    prizes


# 勝利回数による賞
wincountprize=
    all:
        5:"かけだし"
        10:"ポイントゲッター"
        20:"期待の新星"
        30:"到達の証"
        50:"撃墜王"
        75:"勝利の絆"
        100:"武王"
        150:"スペシャリスト"
        200:"未来を紡ぎし者"
        300:"マスター"
        400:"絶対王者"
        500:"天下無双"
        750:"天衣無縫"
        1000:"全知全能"
        1500:"月の頭脳"
    Human:
        5:"凡人"
        10:"凡骨の意地"
        20:"探偵"
        30:"アイドル"
        40:"将軍"
        50:"王者"
        100:"フリーダム"
        150:"英雄"
    Diviner:
        5:"精霊の代弁者"
        10:"精霊の紡ぎ手"
        20:"輝ける道士"
        30:"神の紡ぎ手"
        50:"亜空間が見えた者"
        100:"現人神"
    Psychic:
        5:"ツクヨミ"
        10:"魂を呼ぶ者"
        30:"時の継承者"
        50:"巫女"
        100:"シャーマンキング"
    Guard:
        5:"救命係"
        10:"キーパー"
        30:"精霊の守護者"
        50:"仁王"
        100:"守護神"
    Madman:
        5:"世間知らず"
        10:"狂戦士"
        30:"ドラマメイカー"
        50:"狂世界の王"
        100:"バーサーカーソウル"
    Couple:
        5:"キズナ"
        10:"親友"
        30:"ふたりは・・・"
        50:"阿吽の呼吸"
        100:"双魔"
    Werewolf:
        5:"狼少年"
        10:"狼男"
        20:"一騎当千"
        30:"征服王"
        50:"グラディエーター"
        75:"破壊神"
        100:"覇王"
        200:"天帝"
    Fox:
        3:"ペテン師"
        10:"潜伏者"
        30:"天狐"
        50:"策士の九尾"
        100:"神獣"
    Poisoner:
        5:"誘爆"
        10:"諸刃の剣"
    BigWolf:
        5:"狼のリーダー"
        10:"凶暴剽悍"
    TinyFox:
        5:"腰巾着"
        10:"親の心子知らず"
    Devil:
        5:"小悪魔"
        10:"デビル"
        30:"魔王"
    ToughGuy:
        5:"ラッキーマン"
        15:"不屈"
        30:"忍耐の化身"
    Cupid:
        5:"恋の立役者"
        15:"ラブメーカー"
    Stalker:
        5:"歪んだ愛"
        15:"百鬼夜行"
    Fanatic:
        5:"狼の理解者"
        15:"狡猾"
    Immoral:
        5:"狐様のためなら・・・"
        15:"インペリアル"
    Bat:
        5:"バットマン"
        15:"戦場のナンパ師"
    Noble:
        5:"成金"
        15:"セレブ"
    Slave:
        5:"下克上"
        15:"天変地異"
    Magician:
        5:"マジシャン"
        15:"暗黒の魔法使い"
    Fugitive:
        5:"逃げるが勝ち"
    WolfDiviner:
        5:"総司令"
    Spy:
        5:"諜報員"
        15:"ステルス"
    Merchant:
        5:"店長"
        10:"村の命綱"
    QueenSpectator:
        5:"雛見沢症候群"
        15:"運命を打ち破りし者"
    MadWolf:
        5:"怒れる狼"
    Liar:
        5:"二枚舌"
    Spy2:
        5:"特殊調査員"
        15:"ビッグボス"
    Copier:
        5:"モノマネ師"
    Cursed:
        5:"混血"
        15:"半人半狼"
    ApprenticeSeer:
        5:"次期注目度No.1"
        10:"永遠の二番手"
    Diseased:
        5:"O157"
    Spellcaster:
        5:"寡黙な人形"
    Lycan:
        5:"不吉な影"
    Priest:
        5:"神僕"
    Prince:
        5:"王子様"
        15:"氷帝"
        30:"凌駕"
    PI:
        5:"理科系の男"
        15:"鷹の目"
    Doppleganger:
        5:"臨機応変"
        10:"変幻自在"
        30:"無限の転生者"
    CultLeader:
        5:"教祖"
        10:"指導者"
    Vampire:
        5:"リトルウィング"
        10:"吸血鬼の末裔"
        30:"公爵"
        50:"覚醒の魔族"
    LoneWolf:
        5:"孤高の戦士"
    Light:
        3:"キラ"
        10:"新世界の神"
    Neet:
        3:"明日から本気出す"
        10:"ホームレス"
        
    
    
# 敗北回数による賞
losecountprize=
    all:
        150: "カモネギ"
    Human:
        20: "堕落者"
    Diviner:
        20: "占い詐欺師"
    Psychic:
        20: "小田霧響子"
    Guard:
        20: "居眠り門番"
    Madman:
        20:"指名手配犯"
    Couple:
        20:"犬猿の仲"
    Werewolf:
        20:"負け犬"
    Fox:
        10:"村の嫌われ者"
    Poisoner:
        5:"病原体"
    BigWolf:
        5:"単細胞"
    TinyFox:
        5:"青二才"
    Devil:
        15:"インプ"
    ToughGuy:
        10:"ウドの大木"
    Cupid:
        5:"届かぬ思い"
    Stalker:
        10:"逮捕"
    QueenSpectator:
        10:"繰り返される惨劇"
    Diseased:
        10:"隔離された者"
    LoneWolf:
        10:"ぼっち"

# チームでの勝利階数
winteamcountprize=
    Human:
        10:"白"
        50:"真っ白"
    Werewolf:
        10:"黒"
        50:"真っ黒"
        
###
特殊な回数カウント系称号
称号名:
    names:
        5:"5回の称号"
    func:(game)->   #gameDBデータを渡されるのでカウント数を返す falseとかnullは0
###
# 補助関数
Object.defineProperty Array.prototype,"sum",{
    value:(callback)->
        @map(callback).reduce ((a,b)->a+b),0
}
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

    

counterprize=
    # 呪殺
    cursekill:
        names:
            5:"スナイパー"
            15:"狐の天敵"
            30:"魔弾の狙撃手"
            50:"疾風怒濤の極大射程"
        func:(game,pl)->
            # 呪殺を数える
            game.gamelogs.filter((x)->x.id==pl.id && x.event=="cursekill").length
    # 初日黒
    divineblack2:
        names:
            3:"千里眼"
            10:"心眼"
        func:(game,pl)->
            game.gamelogs.filter((x)->x.id==pl.id && x.event=="divine" && x.flag in Shared.game.blacks).length
        
    # GJ判定
    GJ:
        names:
            5:"防御の達人"
            10:"鉄壁"
            30:"村の救世主"
            50:"歴戦のガーディアン"
        func:(game,pl)->
            game.gamelogs.filter((x)->x.id==pl.id && x.event=="GJ").length
    # 恋人の勝利回数
    lovers_wincount:
        names:
            5:"両思い"
            10:"ラブラブカップル"
            20:"婚約"
            30:"結婚"
            50:"ベストカップル"
        func:(game,pl)->
            if pl.winner && chkCmplType pl,"Friend"
                1
            else
                0
    # 恋人の敗北回数
    lovers_losecount:
        names:
            10:"失恋"
            30:"離婚"
        func:(game,pl)->
            if !pl.winner && chkCmplType pl,"Friend"
                1
            else
                0
    # 商品を受け取った回数
    getkits_merchant:
        names:
            10:"お得意様"
        func:(game,pl)->
            game.gamelogs.filter((x)->x.target==pl.id && x.event=="sendkit").length
    # 商品を人狼側に送った回数
    sendkits_to_wolves:
        names:
            10:"発注ミス"
        func:(game,pl)->
            game.gamelogs.filter((x)->x.id==pl.id && x.event=="sendkit" && getTeamByType(getTypeAtTime(game,x.target,x.day))=="Werewolf").length
    # コピーせずに終了
    nocopy:
        names:
            5:"優柔不断"
        func:(game,pl)->
            if pl.type=="Copier"
                1
            else
                0
    # 2日目昼に吊られた
    day2hanged:
        names:
            20:"怪しい人"
        func:(game,pl)->
            game.gamelogs.filter((x)->
                x.id==pl.id && x.event=="found" && x.flag=="punish" && x.day==2
            ).length
        
    # 総試合数
    allgamecount:
        names:
            5:"ビギナー"
            15:"ルーキー"
            30:"経験者"
            50:"エリート"
            75:"エース"
            100:"キャプテン"
            150:"ベテラン"
            200:"歴戦の絆"
            300:"百戦錬磨"
            400:"カリスマ"
            500:"アルティメット"
            600:"超電磁砲"
            750:"不敗神話"
            1000:"永遠の旅人"
            1250:"冥王"
            1500:"終末の巨人"
            2000:"レジェンド"
        func:(game,pl)->1
    # 最終日に生存
    aliveatlast:
        names:
            30:"最終兵器"
        func:(game,pl)->
            if pl.dead
                0
            else
                1

# 称号一覧を元にして判定（数ではないので注意）
ownprizesprize=
    prizecount_100:
        name:"全てを超越せし者"
        # Booleanで返すこと
        func:(prizes)->prizes.length>=100


prizes=makePrize()  # 賞の一覧 {"prize1":"賞1","prize2","賞2"} というようにIDと名前の辞書

# 内部用
module.exports=
    checkPrize:(game,cb)->
        # 評価対象のプレイヤーをアレする
        pls=game.players.filter (x)->x.realid!="身代わりくん"
        result={}
        onecall= =>
            if pls.length==0
                # もうおわり
                # 引数きめてね!
                cb result
                return
            # 最初のやつ
            pl=pls.pop()
            query={
                $setOnInsert:{userid:pl.realid},
                $inc:{}
            }
            type=getOriginalType game,pl.id
            team=getTeamByType type
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
            for prizename,obj of counterprize
                inc=obj.func game,pl
                if inc>0
                    query.$inc["counter.#{prizename}"]=inc

            M.userlogs.findAndModify {userid:pl.realid},{},query,{
                new:true,
                upsert:true,
            },(err,doc)->
                if err?
                    throw err
                # ユーザーのいままでの戦績が得られたので称号を算出していく
                gotprizes=[]
                wincount=doc.wincount ? {}
                losecount=doc.losecount ? {}
                winteamcount=doc.winteamcount ? {}
                counter=doc.counter
                for job,prs of wincountprize
                    for numstr of prs
                        num=+numstr
                        if wincount[job]>=num
                            gotprizes.push "wincount_#{job}_#{numstr}"
                for job,prs of losecountprize
                    for numstr of prs
                        num=+numstr
                        if losecount[job]>=num
                            gotprizes.push "losecount_#{job}_#{numstr}"
                for team,prs of winteamcountprize
                    for numstr of prs
                        num=+numstr
                        if winteamcount[team]>=num
                            gotprizes.push "winteamcount_#{team}_#{numstr}"
                for type,obj of counterprize
                    for numstr of obj.names
                        num=+numstr
                        if counter[type]>=num
                            gotprizes.push "#{type}_#{num}"
                for type,obj of ownprizesprize
                    if obj.func prizes
                        gotprizes.push type
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

    
    prizeName:(prizeid)->prizes[prizeid]    # IDを名前に
    prizeQuote:(prizename)->"≪#{prizename}≫"
            
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
