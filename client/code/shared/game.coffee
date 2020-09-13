Shared=
    game:exports

# 身代わりセーフティありのときの除外役職一覧
exports.SAFETY_EXCLUDED_JOBS = SAFETY_EXCLUDED_JOBS = ["QueenSpectator","Spy2","Poisoner","Cat","Cupid","BloodyMary","Noble", "Lover", "Twin","Hunter","MadHunter","Idol","SnowLover","Raven","LunaticLover","HooliganGuard","HooliganAttacker","SantaClaus"]
# ------ 役職一覧
# 基本役職
exports.jobs=["Human","Werewolf","Diviner","Psychic","Madman","Guard","Couple","Fox",
# ミラーズホロウの人狼
"Hunter","Cupid",
# 特殊役職?
"Poisoner","BigWolf","TinyFox","Cat",
# るる鯖で見つけた役職
"Fanatic","Immoral"
# 特殊役職2
"Devil","Stalker","WhisperingMad","Dog",
# 桃栗基本特殊役職
"Bat","Noble","Slave","Magician","Spy","WolfDiviner",
# 桃栗期間限定役職
"Fugitive","Merchant","QueenSpectator","MadWolf","Liar","Spy2","Copier",
# 究極の人狼の役職
"ToughGuy","Cursed","ApprenticeSeer","Diseased","Spellcaster","Lycan","Priest","Prince","PI","Sorcerer",
"Doppleganger","CultLeader","Vampire","LoneWolf","Witch","Oldman","Tanner","OccultMania","WolfCub","Thief",
"Hoodlum","TroubleMaker","FrankensteinsMonster",
"BloodyMary",
# うそつき人狼の役職
"Dictator","SeersMama","Trapper","WolfBoy","King",
# Twitter人狼の役職
"Counselor","Miko","GreedyWolf","FascinatingWolf","SolitudeWolf","ToughWolf","ThreateningWolf",
# 人狼物語
"CurseWolf",
# 人狼物語（瓜科国）
"MadCouple",
# 人狼物語（薔薇の下国）
"NightRabbit",
# 人狼物語（深海国）
"Fate","QueenOfNight","CynthiaWolf",
# 人狼物語（三日月国）
"Tarzan",
# 天国系の役職
"Lover", # 人狼天国
"ObstructiveMad", # 人狼天国
"WanderingGuard", # 錠前天国
"BadLady", # 蒼汁天国、人狼天国
# ねじれ天国
"Bomber","Blasphemy","Ushinotokimairi","DualPersonality","GachaAddicted",
"Gambler","Faker",
# 人狼式
"Emma","EyesWolf","TongueWolf","Oracle","Hitokotonushinokami",
"SealWolf",
# えけけ鯖
"MadHunter","Ascetic"
# 人狼パーティー
"TinyGhost","Ninja","Twin","Dracula","VampireClan"
# その他
"RedHood","Baker","XianFox","LunaticLover"
# 人狼放浪記
"MadDog","CraftyWolf","Pumpkin","MadScientist","SpiritPossessed","Forensic"
# 牢獄の悪夢
"PsychoKiller","Cosplayer",
# 人狼NET
"Satori",
# わんないと人狼
"Phantom",
# 月夜の人狼
"DrawGirl","CautiousWolf","SnowLover","Raven","Samurai",
# 月夜の人狼（闇夜の人狼）
"DarkClown",
# 人狼HOUSE
"Hypnotist",
# 人狼ジャッジメント
"BlackCat","Amanojaku",
# 人狼 SUPER DX（幻冬舎）
"Illusionist",
# 魔法都市の人狼
"Elementaler",
# 24時間耐久人狼
"IntuitionWolf",
# 絶対的人狼
"AbsoluteWolf",
# オリジナル
"SantaClaus","Reindeer",
"Pyrotechnist","Patissiere","Shishimai","Idol","LurkingMad",
"DecoyWolf","Hooligan","HomeComer","DragonKnight","Poet","Sacrifice",
"Synesthete","Streamer","RemoteWorker"
]
# 隠されていて自分で入れることができない役職
exports.hiddenJobs = [
    "Light", "Neet", "MinionSelector", "QuantumPlayer", "HolyMarked", "Lorelei"
]

# 人外
exports.nonhumans=["Werewolf","Fox","BigWolf","TinyFox","WolfDiviner","MadWolf","Devil","Vampire","LoneWolf","WolfCub","GreedyWolf","FascinatingWolf","SolitudeWolf","ToughWolf","ThreateningWolf","CautiousWolf","CraftyWolf","EyesWolf","TongueWolf","XianFox","DecoyWolf","Dracula","AbsoluteWolf","NightRabbit","CurseWolf","IntuitionWolf","Lorelei","SealWolf","CynthiaWolf"]

# 黒が出る人
exports.blacks=["Werewolf","WolfDiviner","MadWolf","Lycan","LoneWolf","WolfCub","Dog","GreedyWolf","FascinatingWolf","SolitudeWolf","ToughWolf","ThreateningWolf","MadDog","CraftyWolf","Cosplayer","EyesWolf","TongueWolf","DecoyWolf","AbsoluteWolf","CurseWolf","IntuitionWolf","SealWolf","CynthiaWolf"]

# チームたち
exports.teams=teams=
    Human:["Human","Diviner","Psychic","Guard","Couple","Poisoner","ToughGuy","Noble","Slave","Magician","Fugitive","Merchant","QueenSpectator","MadWolf","Liar","Light","Cursed","ApprenticeSeer","Diseased","Spellcaster","Lycan","Priest","Prince","PI","Cat","Witch","Oldman","OccultMania","Dog","Dictator","SeersMama","Trapper","RedHood","Counselor","Miko","HolyMarked","WanderingGuard","TroubleMaker","FrankensteinsMonster","BloodyMary","King","SantaClaus","Phantom","DrawGirl","Pyrotechnist","Baker","SpiritPossessed","GotChocolate","Forensic","Cosplayer","TinyGhost","Ninja","Twin","Hunter","Emma","Idol","HomeComer","Illusionist","DragonKnight","Samurai","Elementaler","Poet","Sacrifice","Oracle","GachaAddicted","Fate","Synesthete","Reindeer","Streamer","Tarzan","Hitokotonushinokami","RemoteWorker","Gambler"]
    Werewolf:["Werewolf","Madman","BigWolf","Fanatic","Spy","WolfDiviner","Spy2","Sorcerer","LoneWolf","MinionSelector","WolfCub","WhisperingMad","WolfBoy","GreedyWolf","FascinatingWolf","SolitudeWolf","ToughWolf","ThreateningWolf","ObstructiveMad","PsychoKiller","CautiousWolf","Bomber","Ushinotokimairi","MadDog","Hypnotist","CraftyWolf","Pumpkin","MadScientist","MadHunter","MadCouple","EyesWolf","TongueWolf","BlackCat","LurkingMad","DecoyWolf","Satori","AbsoluteWolf","QueenOfNight","CurseWolf","IntuitionWolf","Faker","SealWolf","CynthiaWolf"]
    Fox:["Fox","TinyFox","Immoral","Blasphemy","XianFox","NightRabbit"]
    Devil:["Devil"]
    Friend:["Cupid","Lover","BadLady","Patissiere","SnowLover","LunaticLover"]
    Vampire:["Vampire","Dracula","VampireClan"]
    Cult:["CultLeader"]
    Raven:["Raven","Ascetic"]
    Hooligan:["Hooligan", "HooliganAttacker"]
    Lorelei:["Lorelei"]
    Others:["Bat","Stalker","Doppleganger","Copier","Tanner","Thief","Hoodlum","QuantumPlayer","Shishimai","HooliganGuard","Amanojaku","DarkClown","DualPersonality"],
    Neet:["Neet"]

# カテゴリ分け(一部闇鍋でつかうぞ!)
exports.categories=
    Human: teams.Human.filter((x)->
        not (x in ["GotChocolate", "Phantom", "OccultMania", "Cursed", "BloodyMary","Listener"]))
    Werewolf:["Werewolf","BigWolf","WolfDiviner","LoneWolf","WolfCub","GreedyWolf","FascinatingWolf","SolitudeWolf","ToughWolf","ThreateningWolf","CautiousWolf","CraftyWolf","EyesWolf","TongueWolf","DecoyWolf","AbsoluteWolf","CurseWolf","IntuitionWolf","SealWolf","CynthiaWolf"]
    Madman:["Madman","Fanatic","Spy","Spy2","Sorcerer","WhisperingMad","WolfBoy","ObstructiveMad","PsychoKiller","Bomber","Ushinotokimairi","MadDog","Hypnotist","Pumpkin","MadScientist","MadHunter","MadCouple","BlackCat","LurkingMad","Satori","QueenOfNight","Faker"]
    Fox:["Fox","TinyFox","XianFox","NightRabbit"]
    Immoral:["Immoral","Blasphemy"]
    # sort by teams （恋人陣営、単独陣営、その他、変化系その他、変化系村人陣営）
    Others:["Cupid","Lover","BadLady","Patissiere","SnowLover","LunaticLover","Devil","CultLeader","Vampire","Dracula","VampireClan","Raven","Ascetic","Hooligan","Lorelei","Bat","Tanner","Hoodlum","Shishimai","Amanojaku","DarkClown"]
    Switching:["Stalker","Copier","Doppleganger","DualPersonality","OccultMania","Cursed","BloodyMary","Phantom","Thief"]
    # Special category for "no category"
    None:["Neet"]

# 配列版のカテゴリリスト
exports.categoryList = Object.keys(exports.categories)
    .map (key)-> {
        id: key
        roles: exports.categories[key]
    }

# ガチャデータ（課金者用）
exports.gachaData =
    1: ["Human", "Couple", "Noble", "Slave", "Liar", "Lycan", "Oldman",
        "TinyGhost", "Twin"]
    2: ["Diviner", "Psychic", "Guard", "Magician", "ToughGuy", "ApprenticeSeer",
        "Diseased", "Dog", "SeersMama", "DrawGirl", "Cosplayer","Reindeer", "Tarzan",
        "RemoteWorker"
    ]
    3: ["Fugitive", "Cursed", "Spellcaster", "Prince", "PI", "OccultMania",
        "RedHood", "WanderingGuard", "Phantom", "Pyrotechnist", "Forensic",
        "Ninja", "Emma", "HomeComer", "Samurai", "Sacrifice", "Oracle", "Poet",
        "GachaAddicted","Hitokotonushinokami","Gambler"]
    4: ["Poisoner", "Merchant", "MadWolf", "Light", "Cat", "Witch", "Dictator",
        "Miko", "HolyMarked", "TroubleMaker", "FrankensteinsMonster",
        "SantaClaus", "Baker", "SpiritPossessed", "Hunter", "Idol", "Elementaler","Fate",
        "Synesthete", "Streamer"]
    5: ["QueenSpectator", "Priest", "Trapper", "Counselor", "BloodyMary", "King",
        "Illusionist", "DragonKnight"]
    6: ["Neet", "Helper", "Watching"]

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

exports.normal1 = normal1

exports.jobrules=[
  {
    name:"普通配役"
    rule:[
      {
        name:"普通1"
        minNumber:4
        rule:normal1
      }
      {
        name:"普通2"
        minNumber:4
        rule:normal2
      }
      {
        name:"普通3"
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
        rule:(number)->
          ret=normal1 number
          if ret.Fox>0
            ret.Immoral?=0
            ret.Immoral+=1
          ret
      }
      {
        name:"埋毒者あり"
        rule:(number)->
          ret=normal1 number
          ret.Poisoner=1
          ret.Werewolf++
          ret
      }
      {
        name:"猫又あり"
        rule:(number)->
          ret=normal1 number
          ret.Cat=1
          ret.Werewolf++
          ret
      }
      {
        name:"囁き狂人"
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
        rule:(number)->
          ret=normal1 number
          ret.Magician=1
          ret
      }
      {
        name:"スパイ"
        rule:(number)->
          ret=normal1 number
          ret.Spy=1
          if number<10 && ret.Madman>0
            ret.Madman--
          ret
      }
      {
        name:"人狼占い"
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
getruleobj=(name)->
    # オブジェクトから探す
    if name=="特殊ルール.量子人狼"
        # 特殊だ!
        return {
            name:"量子人狼"
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
    ruleobj = getruleobj name
    return ruleobj?.rule
# 職の情報
exports.getjobobj = (job)->
    for name,team of Shared.game.jobinfo
        if team[job]?
            return team[job]
    return null

# make team color map from jobinfo
exports.makeTeamColors = ->
    result = {}
    for team, obj of Shared.game.jobinfo
        result[team] = obj.color
    result


# jobinfo.name can now be removed
exports.jobinfo=
    Human:
        color:"#00CC00"
        Human:
            color:"#dddddd"
        Diviner:
            color:"#00b3ff"
        Psychic:
            color:"#bb00ff"
        Guard:
            color:"#969ad4"
        Couple:
            color:"#ffffab"
        Poisoner:
            color:"#853c24"
        Noble:
            color:"#ffff00"
        Slave:
            color:"#1417d9"
        Magician:
            color:"#f03eba"
        Fugitive:
            color:"#e8b279"
        Merchant:
            color:"#e06781"
        QueenSpectator:
            color:"#faeebe"
        Liar:
            color:"#a3e4e6"
        Light:
            color:"#2d158c"
        MadWolf:
            color:"#847430"
        ToughGuy:
            color:"#ff5900"
        Cursed:
            color:"#bda3bf"
        ApprenticeSeer:
            color:"#bfecff"
        Diseased:
            color:"#b35b98"
        Spellcaster:
            color:"#4b4f7d"
        Lycan:
            color:"#7d5f5f"
        Priest:
            color:"#fff94a"
        Prince:
            color:"#e5ff00"
        PI:
            color:"#573670"
        Cat:
            color:"#9200C7"
        Witch:
            color:"#9200C7"
        Oldman:
            color:"#ede4b9"
        OccultMania:
            color:"#edda8c"
        Dog:
            color:"#d4a152"
        Dictator:
            color:"#ff0000"
        SeersMama:
            color:"#ff9500"
        Trapper:
            color:"#b58500"
        RedHood:
            color:"#ff2200"
        Counselor:
            color:"#ff94d9"
        Miko:
            color:"#f5b8ca"
        HolyMarked:
            color:"#c4e8ff"
        WanderingGuard:
            color:"#16bf0d"
        TroubleMaker:
            color:"#64b82c"
        FrankensteinsMonster:
            color:"#4d3a03"
        BloodyMary:
            color:"#ee0000"
        King:
            color:"#fcdd28"
        SantaClaus:
            color:"#ff0000"
        Phantom:
            color:"#f3f3f3"
        DrawGirl:
            color:"#ffc796"
        Pyrotechnist:
            color:"#ff6a19"
        Baker:
            color:"#fad587"
        SpiritPossessed:
            color:"#a196d1"
        Forensic:
            color:"#d4e9fc"
        Cosplayer:
            color:"#69652b"
        TinyGhost:
            color:"#999999"
        Ninja:
            color:"#1f136d"
        Twin:
            color:"#dbfcff"
        Hunter:
            color:"#d11f1f"
        Emma:
            color:"#dd2211"
        Idol:
            color:"#ffcc55"
        HomeComer:
            color:"#bbeeee"
        Illusionist:
            color:"#ddaaee"
        DragonKnight:
            color:"#ef8b26"
        Samurai:
            color:"#000d80"
        Elementaler:
            color:"#46f17f"
        Poet:
            color:"#f1a0a2"
        Sacrifice:
            color:"#573f2b"
        Oracle:
            color:"#77c8ed"
        GachaAddicted:
            color:"#edb232"
        Fate:
            color:"#062a66"
        Synesthete:
            color:"#ffb6c1"
        Reindeer:
            color:"#917663"
        Streamer:
            color:"#c4302b"
        Listener:
            color:"#eefeff"
        Tarzan:
            color:"#b3925a"
        Hitokotonushinokami:
            color:"#e6e397"
        RemoteWorker:
            color:"#0e71eb"
        Gambler:
            color:"#edbd80"

    Werewolf:
        color:"#DD0000"
        Werewolf:
            color:"#220000"
        Madman:
            color:"#ffbb00"
        BigWolf:
            color:"#660000"
        Spy:
            color:"#ad5d28"
        WolfDiviner:
            color:"#5b0080"
        Spy2:
            color:"#d3b959"
        Fanatic:
            color:"#94782b"
        Sorcerer:
            color:"#b91be0"
        LoneWolf:
            color:"#222222"
        MinionSelector:
            color:"#ffffff"
        WolfCub:
            color:"#662233"
        WhisperingMad:
            color:"#ccab52"
        WolfBoy:
            color:"#5b2266"
        GreedyWolf:
            color:"#910052"
        FascinatingWolf:
            color:"#f200c2"
        SolitudeWolf:
            color:"#a13f3f"
        ToughWolf:
            color:"#c47f35"
        ThreateningWolf:
            color:"#9e6f00"
        ObstructiveMad:
            color:"#d95e38"
        PsychoKiller:
            color:"#1ee37d"
        CautiousWolf:
            color:"#5c3716"
        Bomber:
            color:"#cda764"
        Ushinotokimairi:
            color:"#c9563c"
        MadDog:
            color:"#c21f1f"
        Hypnotist:
            color:"#e01bs9"
        CraftyWolf:
            color:"#4a03ad"
        Pumpkin:
            color:"#ffb042"
        MadScientist:
            color:"#14e051"
        MadHunter:
            color:"#511e0f"
        MadCouple:
            color:"#f2d5bc"
        EyesWolf:
            color:"#000a75"
        TongueWolf:
            color:"#912d5b"
        BlackCat:
            color:"#38004c"
        LurkingMad:
            color:"#937930"
        DecoyWolf:
            color:"#cc8f2e"
        Satori:
            color:"#f9cad9"
        AbsoluteWolf:
            color:"#ff7f50"
        QueenOfNight:
            color:"#f7f8f0"
        CurseWolf:
            color:"#484366"
        IntuitionWolf:
            color:"#fcac07"
        Faker:
            color:"#8a7458"
        SealWolf:
            color:"#333366"
        CynthiaWolf:
            color:"#dc143c"

    Fox:
        color:"#934293"
        Fox:
            color:"#934293"
        TinyFox:
            color:"#dd81f0"
        Immoral:
            color:"#5c2f5c"
        Blasphemy:
            color:"#802060"
        XianFox:
            color:"#edd5ed"
        NightRabbit:
            color:"#202f55"

    Friend:
        color:"#ffb5e5"
        Cupid:
            color:"#ffb5e5"
        Lover:
            color:"#ffcfee"
        BadLady:
            color:"#cf0085"
        Patissiere:
            color:"#ab5f30"
        SnowLover:
            color:"#f6ceff"
        LunaticLover:
            color:"#b30000"
    Devil:
        color:"#735f9e"
        Devil:
            color:"#735f9e"
    Vampire:
        color:"#8f00bf"
        Vampire:
            color:"#8f00bf"
        Dracula:
            color:"#2d00b7"
        VampireClan:
            color:"#c77ed0"
    Cult:
        color: "#b09d87"
        CultLeader:
            color:"#b09d87"
    Raven:
        color: "#444466"
        Raven:
            color: "#444466"
        Ascetic:
            color:"#435066"
    Hooligan:
        color: "#f39800"
        Hooligan:
            color: "#ff5900"
    Lorelei:
        color: "#b51b70"
        Lorelei:
            color: "#b51b70"
    Others:
        color:"#cccccc"
        Bat:
            color:"#000066"
        Stalker:
            color:"#ad6628"
        Doppleganger:
            color:"#bbbbbb"
        Copier:
            color:"#ffffff"
        Tanner:
            color:"#ede4b9"
        Thief:
            color:"#a4a4a4"
        Hoodlum:
            color:"#88002d"
        QuantumPlayer:
            color:"#eeeeee"
        Shishimai:
            color:"#2c8c3e"
        Amanojaku:
            color:"#b09ca8"
        DarkClown:
            color:"#444434"
        DualPersonality:
            color:"#9db699"
    Neet:
        color:"#aaaaaa"
        Neet:
            color:"#aaaaaa"

# TODO temporal new version
exports.new_rules=[
    # 闇鍋関係
    {
        type: 'group'
        label:
            id: 'yaminabe_option'
            visible: (rule)->
                # 闇鍋モードのみ
                (rule.casting ? rule.jobrule) in ["特殊ルール.闇鍋","特殊ルール.一部闇鍋","特殊ルール.エンドレス闇鍋"]
        items: [
            {
                type: 'item'
                value:
                    type: 'select'
                    id: 'yaminabe_safety'
                    defaultValue: 'low'
                    values:[
                        "supersuper"
                        "super"
                        "high"
                        "middle"
                        "lowlow"
                        "low"
                        "none"
                        "reverse"
                    ]
            }
        ]
    }
    # 配役表示
    {
        type: 'group'
        label:
            id: 'show_roles_option'
            visible: (rule, isEditor)->
                if !isEditor && rule.rules.get('yaminabe_hidejobs') != 'team'
                    # ルール表示時で配役がチームのみの設定でない場合は隠す
                    return false
                return true if isAllJobsMode(rule)
                if isEditor && rule.rules.get('yaminabe_hidejobs') != 'team'
                    return false
                for job in ["Vampire","Devil","CultLeader"]
                    if rule.jobNumbers[job]>0
                        return true
                return false
        items: [
            {
                type: 'item'
                value:
                    type: 'checkbox'
                    id: 'hide_singleton_teams'
                    defaultChecked: false
                    value: 'on'
            }
        ]
    }
    # 標準ルール
    {
        type: 'group'
        label:
            id: 'normal_rules'
            visible:->true
        items: [
            {
                type: 'item'
                value:
                    type: 'checkbox'
                    id: 'decider'
                    defaultChecked: false
                    value: '1'
            }
            {
                type: 'item'
                value:
                    type:"checkbox"
                    id:"authority"
                    defaultChecked: false
                    value:"1"
            }
            {
                type: 'item'
                value:
                    type:"checkbox"
                    id:"deathnote"
                    defaultChecked: false
                    value:"1"
            }
            {
                type: 'item'
                value:
                    type:"checkbox"
                    id:"wolfminion"
                    defaultChecked: false
                    value:"1"
            }
            {
                type: 'item'
                value:
                    type:"checkbox"
                    id:"drunk"
                    defaultChecked: false
                    value:"1"
            }
            {
                type: 'item'
                value:
                    type:"separator"
            }
            {
                type: 'item'
                value:
                    type:"select"
                    id:"scapegoat"
                    defaultValue: 'on'
                    values: [
                        "on"
                        "off"
                        "no"
                    ]
            }
            {
                type: 'item'
                value:
                    type:"separator"
            }
            {
                type: 'item'
                value:
                    type:"time"
                    id: 'day'
                    defaultValue: 330
                    disabled:(rule)->
                        rule.rules.get('dynamic_day_time') == 'on'
            }
            {
                type: 'item'
                value:
                    type:"time"
                    id: 'night'
                    defaultValue: 150
            }
            {
                type: 'item'
                value:
                    type:"time"
                    id: 'remain'
                    defaultValue: 120
                    minValue: 60
            }
            {
                type: 'item'
                value:
                    type:"time"
                    id: 'voting'
                    defaultValue: 0
            }
            {
                type: 'item'
                value:
                    type:"separator"
            }
            {
                type: 'item'
                value:
                    type:"checkbox"
                    id:"dynamic_day_time"
                    defaultChecked: false
                    value:"on"
            }
            {
                type: 'item'
                value:
                    type:"integer"
                    id:"dynamic_day_time_factor"
                    defaultValue: 30
                    minValue: 10
                    step: 5
                    value:"on"
                    disabled:(rule)->
                        rule.rules.get('dynamic_day_time') != 'on'
                    getstr:(t, value)->
                        {
                            value:
                                if !value
                                    t('rules:common.none')
                                else
                                    value + t('rules:common.seconds')
                        }
            }
            {
                type: 'item'
                value:
                    type:"separator"
            }
            {
                type: 'item'
                value:
                    type:"checkbox"
                    id:"will"
                    defaultChecked: true
                    value:"die"
            }
            {
                type: 'item'
                value:
                    type:"select"
                    id:"heavenview"
                    defaultValue: 'norevive'
                    values:[
                        "view"
                        "norevive"
                        # ""なのは歴史的経緯
                        ""
                    ]
            }
            {
                type: 'item'
                value:
                    type:"checkbox"
                    id:"votemyself"
                    value:"ok"
            }
            {
                type: 'item'
                value:
                    type:"checkbox"
                    id:"voteresult"
                    value:"hide"
            }
            {
                type: 'item'
                value:
                    type:"hidden"
                    id:"waitingnight"
                    value: "wait"
            }
            {
                type: 'item'
                value:
                    type:"select"
                    id:"safety"
                    defaultValue: 'full'
                    values:[
                        "full"
                        "no"
                        "free"
                    ]
                    getOptionStr: (t, value)->
                        {
                            label: t("rules:rule.safety.labels.#{value}")
                            description: t("rules:rule.safety.descriptions.#{value}", {
                                safety_excluded_jobs: SAFETY_EXCLUDED_JOBS.map((job)-> t("roles:jobname.#{job}")).join("、")
                            })
                        }
            }
            {
                type: 'item'
                value:
                    type:"separator"
            }
            {
                type: 'item'
                value:
                    type:"checkbox"
                    id:"noticebitten"
                    value:"notice"
            }
            {
                type: 'item'
                value:
                    type:"checkbox"
                    id:"GMpsychic"
                    value:"on"
            }
            {
                type: 'item'
                value:
                    type:"integer"
                    id:"silentrule"
                    defaultValue: 0
                    minValue: 0
                    getstr:(t, value)->
                        {
                            value:
                                if !value
                                    t('rules:common.none')
                                else
                                    value + t('rules:common.seconds')
                        }
            }
            {
                type: 'item'
                value:
                    type:"select"
                    id:"runoff"
                    defaultValue: 'no'
                    values:[
                        "no"
                        "revote"
                        "yes"
                    ]
            }
            {
                type: 'item'
                value:
                    type:"select"
                    id:"drawvote"
                    defaultValue: 'revote'
                    values:[
                        "revote"
                        "random"
                        "none"
                        "all"
                    ]
            }
            {
                type: 'item'
                value:
                    type: "separator"
            }
            {
                # 名前がyaminabeなのは歴史的経緯
                type: 'item'
                value:
                    type:"select"
                    id:"yaminabe_hidejobs"
                    defaultValue: ''
                    values:[
                        # ""なのは歴史的経緯
                        ""
                        "team"
                        "2"
                    ]
            }
            {
                type: 'item'
                value:
                    type:"checkbox"
                    id:"losemode"
                    value:"on"
            }
            {
                type: 'item'
                value:
                    type:"checkbox"
                    id:"rolerequest"
                    value:"on"
            }
            {
                type: 'item'
                value:
                    type:"checkbox"
                    id:"chemical"
                    value:"on"
            }
        ]
    }
    # 人狼系
    {
        type: 'group'
        label:
            id: "werewolf"
            visible: (rule)->
                return true if isAllJobsMode rule
                for job in exports.categories.Werewolf
                    if rule.jobNumbers[job]>0
                        return true
                return false
        items:[
            {
                type: 'item'
                value:
                    type:"checkbox"
                    id:"wolfsound"
                    defaultChecked: true
                    value:"aloud"
            }
            {
                type: 'item'
                value:
                    type:"checkbox"
                    id:"wolfattack"
                    value:"ok"
            }
        ]
    }
    # 占い系
    {
        type: 'group'
        label:
            id: 'diviner'
            visible:(rule)->
                return true if isAllJobsMode rule
                for job in ["Diviner","ApprenticeSeer","WolfDiviner","TinyFox"]
                    if rule.jobNumbers[job]>0
                        return true
                return false
        items:[
            {
                type: 'item'
                value:
                    type:"select"
                    id:"divineresult"
                    defaultValue: 'sunrise'
                    values:[
                        "immediate"
                        "sunrise"
                    ]
            }
            {
                type: 'item'
                value:
                    type:"select"
                    id:"firstnightdivine"
                    defaultValue: 'manual'
                    values:[
                        "auto"
                        "manual"
                    ]
            }
        ]
    }
    # 霊能
    {
        type: 'group'
        label:
            id: 'psychic'
            visible:(rule)->
                return true if isAllJobsMode rule
                return rule.jobNumbers.Psychic>0
        items:[
            {
                type: 'item'
                value:
                    type:"select"
                    id:"psychicresult"
                    defaultValue: 'sunrise'
                    values:[
                        "sunset"
                        "sunrise"
                    ]
            }
        ]
    }
    # 共有者
    {
        type: 'group'
        label:
            id: 'couple'
            visible:(rule)->
                return true if isAllJobsMode rule
                return rule.jobNumbers.Couple>0 || rule.jobNumbers.MadCouple>0
        items:[
            {
                type: 'item'
                value:
                    type:"checkbox"
                    id:"couplesound"
                    value:"aloud"
            }
        ]
    }
    # 護衛役職
    {
        type: 'group'
        label:
            id: 'guard'
            visible:(rule)->
                return true if isAllJobsMode rule
                for job in ["Guard","Trapper","WanderingGuard","Cosplayer"]
                    if rule.jobNumbers[job]>0
                        return true
                return false
        items:[
            {
                type: 'item'
                value:
                    type:"checkbox"
                    id:"guardmyself"
                    value:"ok"
            }
            {
                type: 'item'
                value:
                    type:"checkbox"
                    id:"gjmessage"
                    value:"on"
            }
            {
                type: 'item'
                value:
                    type:"select"
                    id:"consecutiveguard"
                    defaultValue: 'yes'
                    values:[
                        "yes"
                        "no"
                    ]
            }
        ]
    }
    # 妖狐
    {
        type: 'group'
        label:
            id: "fox"
            visible:(rule)->
                return true if isAllJobsMode rule
                return rule.jobNumbers.Fox>0
        items:[
            {
                type: 'item'
                value:
                    type:"checkbox"
                    id:"deadfox"
                    value:"obvious"
            }
        ]
    }
    # ハンター
    {
        type: 'group'
        label:
            id: 'hunter'
            visible:(rule)->
                return true if isAllJobsMode rule
                return rule.jobNumbers.Hunter > 0 || rule.jobNumbers.MadHunter > 0
        items:[
            {
                type: 'item'
                value:
                    type: "select"
                    id:"hunter_lastattack"
                    defaultValue: 'yes'
                    values:[
                        "yes"
                        "no"
                    ]
            }
        ]
    }
    # 埋毒者、猫又
    {
        type: 'group'
        label:
            id: 'poison'
            visible:(rule)->
                return true if isAllJobsMode rule
                return rule.jobNumbers.Poisoner>0 || rule.jobNumbers.Cat>0
        items:[
            {
                type: 'item'
                value:
                    type: "select"
                    id: "poisonwolf"
                    defaultValue: 'selector'
                    values:[
                        "selector"
                        ""
                    ]
            }
        ]
    }
    # 恋人
    {
        type: 'group'
        label:
            id: 'lover'
            visible:(rule)->
                return true if isAllJobsMode rule
                for job in ["Cupid","Lover","BadLady","Patissiere"]
                    if rule.jobNumbers[job]>0
                        return true
                return false
        items:[
            {
                type: 'item'
                value:
                    type:"select"
                    id:"friendsjudge"
                    defaultValue: 'alive'
                    values:[
                        "alive"
                        "ruin"
                    ]
            }
            {
                type: 'item'
                value:
                    type:"checkbox"
                    id:"friendssplit"
                    defaultChecked: true
                    value:"split"
            }
        ]
    }
    # 量子人狼
    {
        type: 'group'
        label:
            id: 'quantum'
            visible:(rule)->rule.casting=="特殊ルール.量子人狼"
        items:[
            {
                type: 'item'
                value:
                    type:"select"
                    id:"quantumwerewolf_table"
                    defaultValue: 'open'
                    values:[
                        "open"
                        "anonymous"
                    ]
            }
            {
                type: 'item'
                value:
                    type:"checkbox"
                    id:"quantumwerewolf_dead"
                    value:"no"
            }
            {
                type: 'item'
                value:
                    type:"checkbox"
                    id:"quantumwerewolf_diviner"
                    value:"on"
            }
            {
                type: 'item'
                value:
                    type:"checkbox"
                    id:"quantumwerewolf_firstattack"
                    value:"on"
            }
        ]
    }
]
# 情報表示(makejobinfoで付加するやつ)
exports.jobinfos=[
    {
        name:"supporting"
    }
    {
        name:"wolves"
    }
    {
        name:"vampires"
    }
    {
        name:"peers"
    }
    {
        name:"madpeers"
    }
    {
        name:"foxes"
    }
    {
        name:"nobles"
    }
    {
        name:"queens"
    }
    {
        name:"spy2s"
    }
    {
        name:"friends"
    }
    {
        name:"stalking"
    }
    {
        name:"cultmembers"
    }
    {
        name:"dogOwner"
    }
    {
        name:"quantumwerewolf_number"
    }
    {
        name:"watchingfireworks",
    }
    {
        name:"twins"
    }
    {
        name:"myfans"
    }
    {
        name:"fanof"
    }
    {
        name:"ravens"
    }
    {
        name:"hooligans"
    }
    {
        name:"loreleis"
    }
]

# 全ての役職が現れる可能性があるモードかどうか
isAllJobsMode=(rule)->
   if (rule.casting ? rule.jobrule) in ["特殊ルール.闇鍋","特殊ルール.一部闇鍋","特殊ルール.エンドレス闇鍋", "特殊ルール.easyYaminabe"]
       return true
   if rule.rules.get("yaminabe_hidejobs") != ""
       # 役職が隠されている場合もtrue
       return true
   return false
