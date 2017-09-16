Shared=
    game:exports
# ------ 役職一覧
# 基本役職
exports.jobs=["Human","Werewolf","Diviner","Psychic","Madman","Guard","Couple","Fox",
# 特殊役職?
"Poisoner","BigWolf","TinyFox","Cat",
# るる鯖で見つけた役職
"Fanatic","Immoral"
# 特殊役職2
"Devil","ToughGuy","Cupid","Stalker","OccultMania","WhisperingMad","Lover","Dog",
# 桃栗基本特殊役職
"Bat","Noble","Slave","Magician","Spy","WolfDiviner",
# 桃栗期間限定役職
"Fugitive","Merchant","QueenSpectator","MadWolf","Liar","Spy2","Copier",
# 究極の人狼の役職
"Cursed","ApprenticeSeer","Diseased","Spellcaster","Lycan","Priest","Prince","PI","Sorcerer",
"Doppleganger","CultLeader","Vampire","LoneWolf","Witch","Oldman","Tanner","WolfCub","Thief",
"Hoodlum","TroubleMaker","FrankensteinsMonster",
"BloodyMary",
# うそつき人狼の役職
"Dictator","SeersMama","Trapper","WolfBoy","King",
# Twitter人狼の役職
"Counselor","Miko","GreedyWolf","FascinatingWolf","SolitudeWolf","ToughWolf","ThreateningWolf",
# 天国系の役職
"ObstructiveMad", # 人狼天国
"WanderingGuard", # 錠前天国
"BadLady", # 蒼汁天国、人狼天国
"Bomber","Blasphemy","Ushinotokimairi",  # ねじれ天国
# その他
"RedHood","Baker",
# 人狼放浪記
"MadDog","CraftyWolf","Pumpkin","MadScientist","SpiritPossessed","Forensic",
# アプリの役職
"PsychoKiller",
# わんないと人狼
"Phantom",
# 月夜の人狼
"DrawGirl","CautiousWolf",
# 人狼HOUSE
"Hypnotist",
# オリジナル
"SantaClaus","Pyrotechnist","Patissiere","Shishimai",
]
# ここには入らない役職
# Light, Neet, MinionSelector,QuantumPlayer, HolyProtected

# 人外
exports.nonhumans=["Werewolf","Fox","BigWolf","TinyFox","WolfDiviner","MadWolf","Devil","Vampire","LoneWolf","WolfCub","GreedyWolf","FascinatingWolf","SolitudeWolf","ToughWolf","ThreateningWolf","CautiousWolf","CraftyWolf"]

# 黒が出る人
exports.blacks=["Werewolf","WolfDiviner","MadWolf","Lycan","LoneWolf","WolfCub","Dog","GreedyWolf","FascinatingWolf","SolitudeWolf","ToughWolf","ThreateningWolf","MadDog","CraftyWolf"]

# チームたち
exports.teams=teams=
    Human:["Human","Diviner","Psychic","Guard","Couple","Poisoner","ToughGuy","Noble","Slave","Magician","Fugitive","Merchant","QueenSpectator","MadWolf","Liar","Light","Cursed","ApprenticeSeer","Diseased","Spellcaster","Lycan","Priest","Prince","PI","Cat","Witch","Oldman","OccultMania","Dog","Dictator","SeersMama","Trapper","RedHood","Counselor","Miko","HolyMarked","WanderingGuard","TroubleMaker","FrankensteinsMonster","BloodyMary","King","SantaClaus","Phantom","DrawGirl","Pyrotechnist","Baker","SpiritPossessed","GotChocolate","Forensic"]
    Werewolf:["Werewolf","Madman","BigWolf","Fanatic","Spy","WolfDiviner","Spy2","Sorcerer","LoneWolf","MinionSelector","WolfCub","WhisperingMad","WolfBoy","GreedyWolf","FascinatingWolf","SolitudeWolf","ToughWolf","ThreateningWolf","ObstructiveMad","PsychoKiller","CautiousWolf","Bomber","Ushinotokimairi","MadDog","Hypnotist","CraftyWolf","Pumpkin","MadScientist"]
    Fox:["Fox","TinyFox","Immoral","Blasphemy"]
    Devil:["Devil"]
    Friend:["Cupid","Lover","BadLady","Patissiere"]
    Vampire:["Vampire"]
    Others:["Bat","Stalker","Doppleganger","CultLeader","Copier","Tanner","Thief","Hoodlum","QuantumPlayer","Shishimai"],
    Neet:["Neet"]

# カテゴリ分け(一部闇鍋でつかうぞ!)
exports.categories=
    Human: teams.Human.filter((x)-> x != "GotChocolate")
    Werewolf:["Werewolf","BigWolf","WolfDiviner","LoneWolf","WolfCub","GreedyWolf","FascinatingWolf","SolitudeWolf","ToughWolf","ThreateningWolf","CautiousWolf","CraftyWolf"]
    Fox:["Fox","TinyFox"]
    Madman:["Madman","Fanatic","Spy","Spy2","Sorcerer","WhisperingMad","WolfBoy","ObstructiveMad","PsychoKiller","Bomber","Ushinotokimairi","MadDog","Hypnotist","Pumpkin","MadScientist"]
    Immoral:["Immoral","Blasphemy"]
    Switching:["Stalker","OccultMania","Copier","Cursed","Doppleganger","BloodyMary","Phantom","Thief"]
    Others:["Devil","Cupid","Bat","CultLeader","Vampire","Tanner","Lover","Hoodlum","BadLady","Patissiere","Shishimai"]

exports.categoryNames=
    Human:"村人系"
    Werewolf:"人狼系"
    Fox:"妖狐系"
    Madman:"狂人系"
    Immoral:"背徳者系"
    Switching:"役職変化系"
    Others:"第三陣営系"

# 役職ルールたち 役職人数一覧を返す（Humanは向こうで補完）
normal1=(number)->
  ret={}
  #狼
  ret.Werewolf=1
  if number>=8
    ret.Werewolf++
    if number>=13
      ret.Werewolf++
      if number>=20
        ret.Werewolf++
        if number>=25
          ret.Werewolf++
          if number>=30
            ret.Werewolf++
  ret.Diviner=1 #占い
  if number>=22
    ret.Diviner++
  if number>=8
    ret.Psychic=1 #霊能
  if number>=6
    ret.Madman=1 #狂人
    ret.Guard=1 #狩人
    if 18 <= number <= 19 || number >= 23
      ret.Madman++
    if number>=20
      ret.Guard++
  if number>=13
    ret.Couple=2 #共有
    if number>=18
      ret.Couple++
  if number>=11
    ret.Fox=1 #狐
    if number>=19
      ret.Fox++
  ret
normal2=(number)->
  ret={}
  # 人狼
  ret.Werewolf=1
  if number>=8
    ret.Werewolf++
    if number>=16
     ret.Werewolf++
     if number>=20
       ret.Werewolf++
       if number>=25
         ret.Werewolf++
         if number>=29
           ret.Werewolf++
  ret.Diviner=1 #占い師
  if number>=8
    ret.Psychic=1   #霊能者
  if number>=10
    ret.Madman=1    #狂人
    if number>=28
      ret.Madman++
  if number>=11
    ret.Guard=1 #狩人
  if number>=13
    ret.Couple=2    #共有者
    if number>=28
      ret.Couple++
  if number>=15
    ret.Fox=1   #狐
  ret

exports.jobrules=[
  {
    name:"普通配役"
    rule:[
      {
        name:"普通1"
        title:"少人数でも楽しめる配役。"
        minNumber:4
        rule:normal1
      }
      {
        name:"普通2"
        title:"一般的な配役。"
        minNumber:4
        rule:normal2
      }
      {
        name:"普通3"
        title:"少人数でも狐が出る配役。"
        minNumber:4
        rule:(number)->
          ret=normal1 number
          ret.Fox ?= 0
          ret.Fox++
          if number<10 && ret.Werewolf>1
            ret.Werewolf--
          ret
      }
    ]
  }
  {
    name:"特殊役職配役"
    rule:[
      {
        name:"恋人"
        title:"恋人が出る配役。"
        rule:(number)->
          ret=normal1 number
          if ret.Fox>0  #NaNかも
            ret.Fox--
          ret.Cupid ?= 0
          ret.Cupid++
          ret
      }
      {
        name:"背徳者"
        title:"背徳者が出る配役。"
        rule:(number)->
          ret=normal1 number
          if ret.Fox>0
            ret.Immoral?=0
            ret.Immoral+=1
          ret
      }
      {
        name:"埋毒者あり"
        title:"埋毒者が出る配役。"
        rule:(number)->
          ret=normal1 number
          ret.Poisoner=1
          ret.Werewolf++
          ret
      }
      {
        name:"猫又あり"
        title:"猫又が出る配役。"
        rule:(number)->
          ret=normal1 number
          ret.Cat=1
          ret.Werewolf++
          ret
      }
      {
        name:"囁き狂人"
        title:"狂人の代わりに囁き狂人が出る配役。"
        rule:(number)->
          ret=normal1 number
          if ret.Madman>0
            ret.WhisperingMad=1
            ret.Madman--
          ret
      }
    ]
  }
  {
    name:"桃栗配役"
    rule:[
      {
        name:"こうもり"
        title:"こうもりが入る配役。"
        rule:(number)->
          ret=normal1 number
          ret.Bat=1
          if number>=10
            ret.Bat++
            if number>=16
              ret.Bat++
          ret
      }
      {
        name:"貴族奴隷"
        title:"貴族奴隷が入る配役。"
        rule:(number)->
          ret=normal1 number
          ret.Noble=1
          ret.Slave=1
          if ret.Couple>=2
            # 共有者ポジション
            ret.Couple=0
          if number>=14
            ret.Slave++
            if number>=20
              ret.Slave++
              if number>=23
                ret.Noble++
          ret
      }
      {
        name:"魔術師"
        title:"魔術師が入る配役。"
        rule:(number)->
          ret=normal1 number
          ret.Magician=1
          ret
      }
      {
        name:"スパイ"
        title:"スパイが入る配役。"
        rule:(number)->
          ret=normal1 number
          ret.Spy=1
          if number<10 && ret.Madman>0
            ret.Madman--
          ret
      }
      {
        name:"人狼占い"
        title:"人狼占いが入る配役。"
        rule:(number)->
          ret=normal1 number
          ret.Werewolf--
          ret.WolfDiviner=1
          if number>=7
            ret.Fox++
          ret
      }
      {
        name:"商人"
        title:"商人が入る配役。"
        rule:(number)->
          ret=normal1 number
          ret.Merchant=1
          ret
      }
    ]
  }
  {
      name:"テーマ配役"
      rule:[
        {
          name:"変化村"
          title:"役職が変化する。"
          minNumber:6
          rule:(number)->
            ret={}
            ret.Werewolf=1
            ret.Diviner=1
            ret.Guard=1
            ret.Madman=1
            ret.Copier=1
            if number>=8
              ret.OccultMania=1
            if number>=9
              ret.Werewolf++
            if number>=10
              ret.Psychic=1
            if number>=11
              ret.Doppleganger=1
            if number>=13
              ret.Counselor=1
              ret.FascinatingWolf=1
            if number>=15
              ret.ApprenticeSeer=1
            if number>=16
              ret.Cursed=1
            if number>=17
              ret.Cupid=1
            if number>=18
              ret.Sorcerer=1
            if number>=19
              ret.ThreateningWolf=1
            if number>=20
              ret.Copier++
            if number>=21
              ret.Fanatic=1
            if number>=22
              ret.Werewolf--
              ret.WolfDiviner=1
              ret.Copier++
            if number>=24
              ret.Diviner++
            if number>=26
              ret.BigWolf=1
            if number>=28
              ret.Fox=1
              ret.Immoral=1

            ret
        }
        {
          name:"黒い村"
          title:"黒い。"
          minNumber:6
          rule:(number)->
            ret={}
            # 狼憑き
            ret.Lycan=1
            if number>=10
              ret.Lycan++
              if number>=14
                ret.Lycan++
                if number==20
                  ret.Lycan--
                if number>=22
                  ret.Lycan++
            if number>=16
              ret.Cursed=1
              if number>=28
                ret.Cursed++
            ret.Diviner=1
            if number>=20
              ret.Diviner++
            if number>=12
              ret.ApprenticeSeer=1
            if number>=16
              ret.SeersMama=1
            if number>=9
              ret.Psychic=1
              if number>=18
                ret.Psychic++
            ret.Guard=1
            if number>=14
              ret.Couple=2
              if number>=24
                ret.Couple++
            if number>=13
              ret.Fugitive=1
            if number>=26
              ret.Merchant=1
            if number>=27
              ret.Dog=1
            ret.Werewolf=1
            if number>=13
              ret.Werewolf++
            if number>=9
              ret.WolfDiviner=1
              if number>=23
                ret.WolfDiviner++
            if number>=19
              ret.SolitudeWolf=1
            ret.Madman=1
            if number>=7
              ret.Madman--
              ret.WolfBoy=1
              if number>=17
                ret.WolfBoy++
                if number>=29
                  ret.WolfBoy++
            if number>=20
              ret.Stalker=1
              if number>=30
                ret.Stalker++
            if number>=25
              ret.Copier=1
            ret
        }
        {
          name:"女王村"
          title:"女王観戦者のいる村。推奨人数:14〜16人。"
          minNumber:10
          suggestedOption:
            scapegoat:"no"
          rule:(number)->
            ret={}
            ret.Diviner=1
            if number>=25
              ret.Diviner++
            if number>=11
              ret.ApprenticeSeer=1
            ret.Psychic=1
            ret.Guard=1
            ret.Trapper=1
            ret.Priest=1
            if number>=12
              ret.Merchant=1
              if number>=18
                ret.Merchant++
            ret.QueenSpectator=1
            if number>=14
              ret.Prince=1
              if number>=21
                ret.Prince++
            if number>=15
              ret.Dictator=1
              if number>=17
                ret.Dictator++
            if number>=26
              ret.Couple=2
              ret.Werewolf=1
            ret.Werewolf?=0
            ret.Werewolf++
            ret.WolfDiviner=1
            if number>=19
              ret.WolfDiviner++
            if number>=13
              ret.WolfCub=1
            if number>=16
              ret.ToughWolf=1
            ret.WhisperingMad=1
            if number>=23
              ret.Sorcerer=1
            if number>=28
              ret.Tanner=1
            ret
        }
      ]
  }
  {
    name:"その他"
    rule:[
      {
        name:"狂った世界"
        title:"狂人が多い。"
        rule:(number)->
          ret={}
          count=3
          ret.Werewolf=1
          ret.Diviner=1
          ret.Guard=1
          # 人狼
          if number>=9
            ret.Werewolf++
            count++
            if number>=14
              ret.Werewolf++
              count++
              if number>=19
                ret.Werewolf++
                count++
                if number>=24
                  ret.Werewolf++
                  count++
          # 占い師
          if number>=12
            ret.Diviner++
            count++
            if number>=20
              ret.Diviner++
              count++
          # 妖術師
          if number>=8
            ret.Sorcerer=1
            count++
            if number>=23
              ret.Sorcerer++
              count++

          # 霊能者
          if number>=16
            ret.Psychic=1
            count++
          # 狂信者
          if number>=17
            ret.Fanatic=1
            count++
          # 独裁者
          if number>=7
            ret.Dictator=1
            count++
            if number>=9
              ret.Dictator++
              count++
              if number>=14
                ret.Dictator++
                count++
          # 埋毒者
          if number>=22
            ret.Poisoner=1
            count++
          # 魔女
          if number>=18
            ret.Witch=1
            count++
          ret.Madman=number-count   #残り全部狂人
          ret
      }
      {
        name:"六つ巴人狼"
        title:"6つの勢力がひしめく。"
        rule:(number)->
          ret={}
          ret.Diviner=1
          ret.Psychic=1
          ret.Guard=1
          ret.Madman=1
          ret.Werewolf=2
          ret.Fox=1
          ret.Devil=1
          ret.Cupid=1
          ret.Copier=1
          if number>=14
            ret.Priest=1
            ret.Doppleganger=1
          if number>=16
            ret.Stalker=1
            ret.Bat=1
          if number>=18
            ret.Werewolf++
          if number>=20
            ret.ApprenticeSeer=1
            ret.Fox++
          if number>=23
            ret.Vampire=1
          if number>=25
            ret.Werewolf++
          if number>=27
            ret.WolfDiviner=1
            ret.Werewolf--
            ret.Immoral=1
          if number>=29
            ret.Noble=1
            ret.Slave=1
          if number>=30
            ret.Werewolf--
            ret.LoneWolf=1
          if number>=35
            ret.Werewolf++
          if number>=36
            ret.Fox++
          if number>=38
            ret.Vampire++
          ret
            
          
      }
    ]
  }
]
# ルールオブジェクトを得る
exports.getruleobj=(name)->
    # オブジェクトから探す
    if name=="特殊ルール.量子人狼"
        # 特殊だ!
        return {
            name:"量子人狼"
            title:"全員の役職などが確率で表現される。村人・人狼・占い師のみ。"
            rule:null
            suggestedNight:{
                max:60
            }
        }
    names= name.split "."
    obj=Shared.game.jobrules
    for branch in names #.区切りでオブジェクト名
        ruleobj=obj.filter((x)->x.name==branch)[0]
        unless ruleobj  # そんな配役は見つからない
            return
        if "function"==typeof ruleobj.rule
            # 目当てのものを見つけた
            return ruleobj
        obj=ruleobj.rule
    null
# ルール関数を得る
exports.getrulefunc=(name)->
    if name=="内部利用.量子人狼"
        # 量子人狼のときは
        return (number)->
            ret={}
            #狼
            ret.Werewolf=1
            if number>=8
                ret.Werewolf++
                if number>=13
                    ret.Werewolf++
                    if number>=20
                        ret.Werewolf++
                        if number>=25
                            ret.Werewolf++
                            if number>=30
                                ret.Werewolf++
            ret.Diviner=1   #占い
            ret

    # ほかはオブジェクトから探す
    ruleobj=exports.getruleobj name
    return ruleobj?.rule
# ルールの名前を書く
exports.getrulestr=(rule,jobs={})->
    text=""
    if rule=="特殊ルール.闇鍋"
        # 闇鍋の場合
        return "闇鍋"
    if rule=="特殊ルール.エンドレス闇鍋"
        return "エンドレス闇鍋"
    text="#{rule.split('.').pop()} / "

    for job in Shared.game.jobs
        continue if job=="Human" && rule=="特殊ルール.一部闇鍋" #一部闇鍋は村人部分だけ闇鍋
        num=jobs[job]
        continue unless parseInt num
        text+="#{Shared.game.getjobname job}#{num} "
    # さらにカテゴリ分も
    for type,name of Shared.game.categoryNames
        num=jobs["category_#{type}"]
        if num>0
            text+="#{name}#{num} "
    return text
# 職の名前
exports.getjobname=(job)->
    for name,team of Shared.game.jobinfo
        if team[job]?
            return team[job].name
    return null
exports.jobinfo=
    Human:
        name:"村人陣営"
        color:"#00CC00"
        Human:
            name:"村人"
            color:"#dddddd"
        Diviner:
            name:"占い師"
            color:"#00b3ff"
        Psychic:
            name:"霊能者"
            color:"#bb00ff"
        Guard:
            name:"狩人"
            color:"#969ad4"
        Couple:
            name:"共有者"
            color:"#ffffab"
        Poisoner:
            name:"埋毒者"
            color:"#853c24"
        Noble:
            name:"貴族"
            color:"#ffff00"
        Slave:
            name:"奴隷"
            color:"#1417d9"
        Magician:
            name:"魔術師"
            color:"#f03eba"
        Fugitive:
            name:"逃亡者"
            color:"#e8b279"
        Merchant:
            name:"商人"
            color:"#e06781"
        QueenSpectator:
            name:"女王観戦者"
            color:"#faeebe"
        Liar:
            name:"嘘つき"
            color:"#a3e4e6"
        Light:
            name:"デスノート"
            color:"#2d158c"
        MadWolf:
            name:"狂人狼"
            color:"#847430"
        ToughGuy:
            name:"タフガイ"
            color:"#ff5900"
        Cursed:
            name:"呪われた者"
            color:"#bda3bf"
        ApprenticeSeer:
            name:"見習い占い師"
            color:"#bfecff"
        Diseased:
            name:"病人"
            color:"#b35b98"
        Spellcaster:
            name:"呪いをかける者"
            color:"#4b4f7d"
        Lycan:
            name:"狼憑き"
            color:"#7d5f5f"
        Priest:
            name:"聖職者"
            color:"#fff94a"
        Prince:
            name:"プリンス"
            color:"#e5ff00"
        PI:
            name:"超常現象研究者"
            color:"#573670"
        Cat:
            name:"猫又"
            color:"#9200C7"
        Witch:
            name:"魔女"
            color:"#9200C7"
        Oldman:
            name:"老人"
            color:"#ede4b9"
        OccultMania:
            name:"オカルトマニア"
            color:"#edda8c"
        Dog:
            name:"犬"
            color:"#d4a152"
        Dictator:
            name:"独裁者"
            color:"#ff0000"
        SeersMama:
            name:"予言者のママ"
            color:"#ff9500"
        Trapper:
            name:"罠師"
            color:"#b58500"
        RedHood:
            name:"赤ずきん"
            color:"#ff2200"
        Counselor:
            name:"カウンセラー"
            color:"#ff94d9"
        Miko:
            name:"巫女"
            color:"#f5b8ca"
        HolyMarked:
            name:"聖痕者"
            color:"#c4e8ff"
        WanderingGuard:
            name:"風来狩人"
            color:"#16bf0d"
        TroubleMaker:
            name:"トラブルメーカー"
            color:"#64b82c"
        FrankensteinsMonster:
            name:"フランケンシュタインの怪物"
            color:"#4d3a03"
        BloodyMary:
            name:"血まみれのメアリー"
            color:"#ee0000"
        King:
            name:"王様"
            color:"#fcdd28"
        SantaClaus:
            name:"サンタクロース"
            color:"#ff0000"
        Phantom:
            name:"怪盗"
            color:"#f3f3f3"
        DrawGirl:
            name:"看板娘"
            color:"#ffc796"
        Pyrotechnist:
            name:"花火師"
            color:"#ff6a19"
        Baker:
            name:"パン屋"
            color:"#fad587"
        SpiritPossessed:
            name:"悪霊憑き"
            color:"#a196d1"
        Forensic:
            name:"法医学者"
            color:"#d4e9fc"
        
    Werewolf:
        name:"人狼陣営"
        color:"#DD0000"
        Werewolf:
            name:"人狼"
            color:"#220000"
        Madman:
            name:"狂人"
            color:"#ffbb00"
        BigWolf:
            name:"大狼"
            color:"#660000"
        Spy:
            name:"スパイ"
            color:"#ad5d28"
        WolfDiviner:
            name:"人狼占い"
            color:"#5b0080"
        Spy2:
            name:"スパイⅡ"
            color:"#d3b959"
        Fanatic:
            name:"狂信者"
            color:"#94782b"
        Sorcerer:
            name:"妖術師"
            color:"#b91be0"
        LoneWolf:
            name:"一匹狼"
            color:"#222222"
        MinionSelector:
            name:"子分選択者"
            color:"#ffffff"
        WolfCub:
            name:"狼の子"
            color:"#662233"
        WhisperingMad:
            name:"囁き狂人"
            color:"#ccab52"
        WolfBoy:
            name:"狼少年"
            color:"#5b2266"
        GreedyWolf:
            name:"欲張りな狼"
            color:"#910052"
        FascinatingWolf:
            name:"誘惑する女狼"
            color:"#f200c2"
        SolitudeWolf:
            name:"孤独な狼"
            color:"#a13f3f"
        ToughWolf:
            name:"一途な狼"
            color:"#c47f35"
        ThreateningWolf:
            name:"威嚇する狼"
            color:"#9e6f00"
        ObstructiveMad:
            name:"邪魔狂人"
            color:"#d95e38"
        PsychoKiller:
            name:"サイコキラー"
            color:"#1ee37d"
        CautiousWolf:
            name:"慎重な狼"
            color:"#5c3716"
        Bomber:
            name:"爆弾魔"
            color:"#cda764"
        Ushinotokimairi:
            name:"丑刻参"
            color:"#c9563c"
        MadDog:
            name:"狂犬"
            color:"#c21f1f"
        Hypnotist:
            name:"催眠術師"
            color:"#e01bs9"
        CraftyWolf:
            name:"狡猾な狼"
            color:"#4a03ad"
        Pumpkin:
            name:"かぼちゃ魔"
            color:"#ffb042"
        MadScientist:
            name:"マッドサイエンティスト"
            color:"#14e051"
        
        
    Fox:
        name:"妖狐陣営"
        color:"#934293"
        Fox:
            name:"妖狐"
            color:"#934293"
        TinyFox:
            name:"子狐"
            color:"#dd81f0"
        Immoral:
            name:"背徳者"
            color:"#5c2f5c"
        Blasphemy:
            name:"冒涜者"
            color:"#802060"
            
        
    Devil:
        name:"悪魔くん"
        color:"#735f9e"
        Devil:
            name:"悪魔くん"
            color:"#735f9e"
    Friend:
        name:"恋人陣営"
        color:"#ffb5e5"
        Cupid:
            name:"キューピッド"
            color:"#ffb5e5"
        Lover:
            name:"求愛者"
            color:"#ffcfee"
        BadLady:
            name:"悪女"
            color:"#cf0085"
        Patissiere:
            name:"パティシエール"
            color:"#ab5f30"
    Vampire:
        name:"ヴァンパイア陣営"
        color:"#8f00bf"
        Vampire:
            name:"ヴァンパイア"
            color:"#8f00bf"
    Others:
        name:"その他"
        color:"#cccccc"
        Bat:
            name:"こうもり"
            color:"#000066"
        Stalker:
            name:"ストーカー"
            color:"#ad6628"
        Doppleganger:
            name:"ドッペルゲンガー"
            color:"#bbbbbb"
        CultLeader:
            name:"カルトリーダー"
            color:"#b09d87"
        Copier:
            name:"コピー"
            color:"#ffffff"
        Tanner:
            name:"皮なめし職人"
            color:"#ede4b9"
        Thief:
            name:"盗人"
            color:"#a4a4a4"
        Hoodlum:
            name:"ならず者"
            color:"#88002d"
        QuantumPlayer:
            name:"量子人間"
            color:"#eeeeee"
        Shishimai:
            name:"獅子舞"
            color:"#2c8c3e"
    Neet:
        name:"ニート"
        color:"#aaaaaa"
        Neet:
            name:"ニート"
            color:"#aaaaaa"
# 設定項目
exports.rules=[
    # 闇鍋関係
    {
        label:"闇鍋オプション"
        visible:(rule,jobs)->rule.jobrule in ["特殊ルール.闇鍋","特殊ルール.一部闇鍋","特殊ルール.エンドレス闇鍋"]
        rules:[
            {
                name:"yaminabe_safety"
                label:"闇鍋セーフティ"
                title:"配役にどれくらい気をつけるか指定します。"
                type:"select"
                values:[
                    {
                        value:"supersuper"
                        label:"走召（α2）"
                        title:"強さのバランスを調整するかもしれません。"
                    }
                    {
                        value:"super"
                        label:"超(β2)"
                        title:"強さのバランスを調整します。"
                    }
                    {
                        value:"high"
                        label:"高"
                        title:"出現役職どうしの兼ね合いも考慮します。"
                    }
                    {
                        value:"middle"
                        label:"中"
                        title:"各陣営の割合を調整します。"
                    }
                    {
                        value:"low"
                        label:"低"
                        title:"人狼・妖狐の数をちょうどいい数に調整します。"
                        selected:true
                    }
                    {
                        value:"none"
                        label:"なし"
                        title:"まったく気をつけません。人狼系1が保証される以外は全てランダムです。"
                    }
                    {
                        value:"reverse"
                        label:"逆（α）"
                        title:"クソゲーになりますが、人外数の調整は行われます。"
                    }
                ]
            }
        ]
    }
    # 標準ルール
    {
        label:null
        visible:->true
        rules:[
            {
                name:"decider"
                label:"決定者"
                title:"昼の処刑投票のときに、同数の場合決定者が投票した人が優先されます。誰が決定者かは分かりません。"
                type:"checkbox"
                value:{
                    value:"1"
                    label:"あり"
                }
            }
            {
                name:"authority"
                label:"権力者"
                title:"昼の処刑投票のときに投票が2票分になります。誰が権力者かは分かりません。"
                type:"checkbox"
                value:{
                    value:"1"
                    label:"あり"
                }
            }
            {
                name:"deathnote"
                label:"死神の手帳"
                title:"毎晩死神の手帳が移動します。死神の手帳を持った人は一人殺すことができます。"
                type:"checkbox"
                value:{
                    value:"1"
                    label:"あり"
                }
            }
            {
                name:"wolfminion"
                label:"狼の子分"
                title:"初日の夜に人狼が狼の子分を指定します。狼の子分になった場合能力はそのままで人狼陣営になります。"
                type:"checkbox"
                value:{
                    value:"1"
                    label:"あり"
                }
            }
            {
                name:"drunk"
                label:"酔っ払い"
                title:"誰かが酔っ払いになります。酔っ払いは3日目の夜まで自分が村人だと思い込んでいます。"
                type:"checkbox"
                value:{
                    value:"1"
                    label:"あり"
                }
            }
            {
                type:"separator"
            }
            {
                name:"scapegoat"
                label:"身代わりくん"
                title:"身代わりくんは1日目の夜に殺されるためのNPCです。"
                type:"select"
                values: [
                    {
                        value:"on"
                        label:"あり"
                        selected:true
                    }
                    {
                        value:"off"
                        label:"なし（参加者が死ぬ）"
                    }
                    {
                        value:"no"
                        label:"なし（誰も死なない）"
                    }
                ]
            }
            {
                type:"separator"
            }
            {
                type:"time"
                name:
                    minute:"day_minute"
                    second:"day_second"
                label:"昼"
                defaultValue:
                    minute:5
                    second:30
                getstr:->null
            }
            {
                type:"time"
                name:
                    minute:"night_minute"
                    second:"night_second"
                label:"夜"
                defaultValue:
                    minute:2
                    second:30
                getstr:->null
            }
            {
                type:"time"
                name:
                    minute:"remain_minute"
                    second:"remain_second"
                label:"猶予"
                defaultValue:
                    minute:2
                    second:0
                getstr:->null
            }
            {
                type:"separator"
            }
            {
                name:"will"
                label:"遺言"
                title:"遺言が有効な場合各参加者は遺言を設定することができ、死んだ際に公開されます。"
                type:"checkbox"
                value:{
                    value:"die"
                    label:"あり"
                    nolabel:"なし"
                    checked:true
                }
            }
            {
                name:"heavenview"
                label:"霊界表示"
                title:"ありの場合、霊界で役職一覧が見られ、夜の発言なども全て見ることができます。"
                type:"select"
                values:[
                    {
                        # ""なのは歴史的経緯
                        value:"view"
                        label:"常にあり"
                        title:"蘇生役職が存在する場合でも常に公開します。"
                    }
                    {
                        value:"norevive"
                        label:"あり"
                        title:"表示しますが、誰かが蘇生する可能性がある場合は表示しません。"
                        selected:true
                    }
                    {
                        value:""
                        label:"なし"
                        title:"ゲーム終了まで非公開にします。"
                    }
                ]
            }
            {
                name:"votemyself"
                label:"昼は自分に投票できる"
                type:"checkbox"
                value:{
                    value:"ok"
                    label:"あり"
                    nolabel:"なし"
                }
                getstr:(value)->
                    {
                        label:"自分投票"
                        value:if value=="ok" then "あり" else "なし"
                    }
            }
            {
                name:"voteresult"
                label:"投票結果を隠す"
                type:"checkbox"
                value:{
                    value:"hide"
                    label:"隠す"
                    nolabel:"隠さない"
                }
                getstr:(value)->
                    {
                        label:"投票結果"
                        value:if value=="hide" then "隠す" else "隠さない"
                    }
            }
            {
                name:"waitingnight"
                label:"夜は時間切れまで待つ"
                type:"hidden"
                value:{
                    value:"wait"
                    label:"あり"
                    nolabel:"なし"
                }
            }
            {
                name:"safety"
                label:"身代わりセーフティ"
                title:"「なし」や「なんでもあり」にすると身代わりくんが人狼になったりします。"
                type:"select"
                values:[
                    {
                        value:"full"
                        label:"あり"
                        selected:true
                    }
                    {
                        value:"no"
                        label:"なし"
                    }
                    {
                        value:"free"
                        label:"なんでもあり"
                    }
                ]
            }
            {
                type:"separator"
            }
            {
                name:"noticebitten"
                label:"噛まれたら分かる"
                title:"人狼に襲われたときに襲われた側に知らせます。"
                type:"checkbox"
                value:{
                    value:"notice"
                    label:"あり"
                    nolabel:"なし"
                }
                getstr:(value)->
                    {
                        label:"襲撃された通知"
                        value:if value=="notice" then "あり" else "なし"
                    }
            }
            {
                name:"GMpsychic"
                label:"GM霊能"
                title:"ありにすると、処刑された人の霊能結果が全員に公開されます。"
                type:"checkbox"
                value:{
                    value:"on"
                    label:"あり"
                    nolabel:"なし"
                }
            }
            {
                name:"silentrule"
                label:"秒ルール"
                backlabel:true  # 後ろに
                title:"1以上にすると、朝になってからその時間の間は発言できません。"
                type:"second"
                defaultValue:{
                    value:0
                }
                getstr:(value)->
                    if value==0
                        return null
                    else
                        return {
                            label:null
                            value:"#{value}秒ルール"
                        }
            }
            {
                name:"runoff"
                label:"決選投票"
                title:"ありの場合、上位候補で決選投票を行います。"
                type:"select"
                values:[
                    {
                        value:"no"
                        label:"なし"
                        selected:true
                    }
                    {
                        value:"revote"
                        label:"再投票時"
                    }
                    {
                        value:"yes"
                        label:"常に行う"
                    }
                ]
            }
            {
                name:"drawvote"
                label:"投票同数時の処理"
                title:"投票で同数になった場合の処理を設定します。"
                type:"select"
                values:[
                    {
                        value:"revote"
                        label:"再投票"
                        selected:true
                    }
                    {
                        value:"random"
                        label:"ランダムに処刑"
                    }
                    {
                        value:"none"
                        label:"誰も処刑しない"
                    }
                    {
                        value:"all"
                        label:"全員処刑"
                    }
                ]
            }
            {
                type: "separator"
            }
            {
                # 名前がyaminabeなのは歴史的経緯
                name:"yaminabe_hidejobs"
                label:"配役公開"
                title:"配役の公開方法を指定します。"
                type:"select"
                values:[
                    {
                        # ""なのは歴史的経緯
                        value:""
                        label:"役職一覧を公開"
                        title:"ゲーム開始時、出現役職の一覧が公開されます。"
                        selected:true
                    }
                    {
                        value:"team"
                        label:"陣営ごとの数のみ公開"
                        title:"各陣営の数のみ公開されます。"
                    }
                    {
                        value:"2"
                        label:"非公開"
                        title:"出現役職の一覧は分からなくなります。"
                    }
                ]
            }
            {
                name:"losemode"
                label:"敗北村"
                title:"負けることを目指す人狼です。"
                type:"checkbox"
                value:{
                    value:"on"
                    label:"あり"
                }
            }
            {
                name:"rolerequest"
                label:"希望役職制"
                title:"各参加者はなりたい役職を選択できます。"
                type:"checkbox"
                value:{
                    value:"on"
                    label:"あり"
                }
            }
            {
                name:"chemical"
                label:"ケミカル人狼"
                title:"1人につき役職が2つ割り当てられる特殊ルールです。"
                type:"checkbox"
                value:{
                    value:"on"
                    label:"あり"
                }
            }
        ]
    }
    # 人狼系
    {
        label:null
        visible:(rule,jobs)->
            return true if isYaminabe rule
            for job in exports.categories.Werewolf
                if jobs[job]>0
                    return true
            return false
        rules:[
            {
                name:"wolfsound"
                label:"人狼の遠吠えが聞こえる"
                type:"checkbox"
                value:{
                    value:"aloud"
                    label:"あり"
                    nolabel:"なし"
                    checked:true
                }
                getstr:(value)->
                    {
                        label:"人狼の遠吠え"
                        value:if value=="aloud" then "聞こえる" else "聞こえない"
                    }
            }
            {
                name:"wolfattack"
                label:"人狼は人狼を襲撃対象に選択できる"
                type:"checkbox"
                value:{
                    value:"ok"
                    label:"あり"
                }
                getstr:(value)->
                    if value=="ok"
                        {
                            label:null
                            value:"人狼は人狼を襲撃対象に選択できる"
                        }
                    else
                        null
            }
        ]
    }
    # 占い系
    {
        label:null
        visible:(rule,jobs)->
            return true if isYaminabe rule
            for job in ["Diviner","ApprenticeSeer","WolfDiviner","TinyFox"]
                if jobs[job]>0
                    return true
            return false
        rules:[
            {
                name:"divineresult"
                label:"占い結果"
                title:"夜に行った占いの結果が表示されるタイミングを調整できます。"
                type:"select"
                values:[
                    {
                        value:"immediate"
                        label:"すぐ分かる"
                    }
                    {
                        value:"sunrise"
                        label:"翌朝分かる"
                        selected:true
                    }
                ]
            }
            {
                name:"firstnightdivine"
                label:"占いの初日白通知"
                title:"ありにすると、初日の占い先は占い結果が「村人」の人の中からランダムに選択されます。"
                type:"select"
                values:[
                    {
                        value:"auto"
                        label:"あり"
                    }
                    {
                        value:"manual"
                        label:"なし"
                        selected:true
                    }
                ]
            }
        ]
    }
    # 霊能
    {
        label:null
        visible:(rule,jobs)->
            return true if isYaminabe rule
            return jobs.Psychic>0
        rules:[
            {
                name:"psychicresult"
                label:"霊能結果"
                title:"夜に行った霊能の結果が表示されるタイミングを調整できます。"
                type:"select"
                values:[
                    {
                        value:"sunset"
                        label:"すぐ分かる"
                    }
                    {
                        value:"sunrise"
                        label:"翌朝分かる"
                        selected:true
                    }
                ]
            }
        ]
    }
    # 共有者
    {
        label:null
        visible:(rule,jobs)->
            return true if isYaminabe rule
            return jobs.Couple>0
        rules:[
            {
                name:"couplesound"
                label:"共有者の小声が聞こえる"
                type:"checkbox"
                value:{
                    value:"aloud"
                    label:"あり"
                    nolabel:"なし"
                }
                getstr:(value)->
                    {
                        label:"共有者の小声"
                        value:if value=="aloud" then "聞こえる" else "聞こえない"
                    }
            }
        ]
    }
    # 護衛役職
    {
        label:null
        visible:(rule,jobs)->
            return true if isYaminabe rule
            for job in ["Guard","Trapper","WanderingGuard"]
                if jobs[job]>0
                    return true
            return false
        rules:[
            {
                name:"guardmyself"
                label:"狩人は自分を守れる"
                type:"checkbox"
                value:{
                    value:"ok"
                    label:"あり"
                }
                getstr:(value)->
                    {
                        label:"狩人の自分護衛"
                        value:if value=="ok" then "あり" else "なし"
                    }
            }
            {
                name:"gjmessage"
                label:"護衛成功が分かる"
                title:"ありにすると、狩人・風来狩人が護衛成功したときに狩人にメッセージが表示されます。"
                type:"checkbox"
                value:{
                    value:"on"
                    label:"あり"
                }
                getstr:(value)->
                    {
                        label:"護衛成功通知"
                        value:if value=="on" then "あり" else "なし"
                    }
            }
            {
                name:"consecutiveguard"
                label:"連続護衛"
                title:"狩人・風来狩人が連続して同じ人を守れるかどうか設定します。"
                type:"select"
                values:[
                    {
                        value:"yes"
                        label:"あり"
                        selected:true
                    }
                    {
                        value:"no"
                        label:"なし"
                    }
                ]
            }
        ]
    }
    # 妖狐
    {
        label:null
        visible:(rule,jobs)->
            return true if isYaminabe rule
            return jobs.Fox>0
        rules:[
            {
                name:"deadfox"
                label:"呪殺は襲撃と区別がつく"
                title:"有効な場合、妖狐が呪殺されたときのログが狼の襲撃と異なるようになります。"
                type:"checkbox"
                value:
                    value:"obvious"
                    label:"あり"
                    nolabel:"なし"
                getstr:(value)->
                    {
                        label:"呪殺ログと襲撃ログの区別"
                        value:if value=="on" then "あり" else "なし"
                    }
            }
        ]
    }
    # 埋毒者、猫又
    {
        label:null
        visible:(rule,jobs)->
            return true if isYaminabe rule
            return jobs.Poisoner>0 || jobs.Cat>0
        rules:[
            {
                name: "poisonwolf"
                label: "人狼の毒持ち襲撃"
                title: "人狼が埋毒者・猫又を襲撃した場合の動作を設定します。"
                type: "select"
                values:[
                    {
                        value: "selector"
                        label: "襲撃者を道連れ"
                        selected: true
                    }
                    {
                        value: ""
                        label: "ランダムに道連れ"
                    }
                ]
            }
        ]
    }
    # 恋人
    {
        label:null
        visible:(rule,jobs)->
            return true if isYaminabe rule
            return jobs.Lover>0 || jobs.Cupid>0
        rules:[
            {
                name:"friendsjudge"
                label:"恋人陣営の勝利条件"
                type:"select"
                values:[
                    {
                        value:"alive"
                        label:"終了時に生存"
                        title:"妖狐と同じです。"
                        selected:true
                    }
                    {
                        value:"ruin"
                        label:"恋人だけ生存"
                    }
                ]
            }
            {
                name:"friendssplit"
                label:"恋人はそれぞれ独立する"
                title:"恋人が複数組できた場合、勝利条件と後追いが恋人全体ではなく組ごとになります。"
                type:"checkbox"
                value:{
                    value:"split"
                    label:"あり"
                    checked:true
                }
                getstr:(value)->
                    {
                        label:"恋人の独立"
                        value:if value=="split" then "あり" else "なし"
                    }
            }
        ]
    }
    # 量子人狼
    {
        label:null
        visible:(rule,jobs)->rule.jobrule=="特殊ルール.量子人狼"
        rules:[
            {
                name:"quantumwerewolf_table"
                label:"確率表"
                type:"select"
                values:[
                    {
                        value:"open"
                        label:"プレイヤー名を表示"
                        selected:true
                    }
                    {
                        value:"anonymous"
                        label:"プレイヤー番号を表示"
                        title:"自分以外のプレイヤー番号は分かりません。"
                    }
                ]
            }
            {
                name:"quantumwerewolf_dead"
                label:"死亡率を表示しない"
                title:"確率表に死亡率を表示しないルールです。表示するのが普通です。"
                type:"checkbox"
                value:{
                    value:"no"
                    label:"あり"
                    nolabel:"なし"
                }
            }
            {
                name:"quantumwerewolf_diviner"
                label:"占い師の確率も表示する"
                title:"確率表に占い師の確率も表示します。表示しないのが普通のルールです。"
                type:"checkbox"
                value:{
                    value:"on"
                    label:"あり"
                    nolabel:"なし"
                }
            }
            {
                name:"quantumwerewolf_firstattack"
                label:"初日の襲撃"
                title:"ありの場合初日から襲撃対象を選択します。"
                type:"checkbox"
                value:{
                    value:"on"
                    label:"あり"
                    nolabel:"なし"
                }
            }
        ]
    }
]
# 情報表示(makejobinfoで付加するやつ)
exports.jobinfos=[
    {
        name:"wolves"
        prefix:"仲間の人狼は"
        type:"pubinfo-array"
    }
    {
        name:"peers"
        prefix:"共有者は"
        type:"pubinfo-array"
    }
    {
        name:"foxes"
        prefix:"仲間の妖狐は"
        type:"pubinfo-array"
    }
    {
        name:"nobles"
        prefix:"貴族は"
        type:"pubinfo-array"
    }
    {
        name:"queens"
        prefix:"女王観戦者は"
        type:"pubinfo-array"
    }
    {
        name:"spy2s"
        prefix:"スパイⅡは"
        type:"pubinfo-array"
    }
    {
        name:"friends"
        prefix:"恋人は"
        type:"pubinfo-array"
    }
    {
        name:"stalking"
        prefix:"あなたは"
        suffix:"のストーカーです"
        type:"pubinfo"
    }
    {
        name:"cultmembers"
        prefix:"信者は"
        type:"pubinfo-array"
    }
    {
        name:"supporting"
        suffix:"をサポートしています"
        type:"pubinfo+job-array"
    }
    {
        name:"dogOwner"
        prefix:"あなたの飼い主は"
        suffix:"です"
        type:"pubinfo"
    }
    {
        name:"quantumwerewolf_number"
        prefix:"あなたのプレイヤー番号は"
        suffix:"番です"
        type:"raw"
    }
    {
        name:"watchingfireworks",
        type:"hidden"
    }
]

# 判定
isYaminabe=(rule)->rule.jobrule in ["特殊ルール.闇鍋","特殊ルール.一部闇鍋","特殊ルール.エンドレス闇鍋"]
