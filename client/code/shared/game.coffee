Shared=
    game:exports
# ------ 役職一览
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
# 究极人狼的职业
"Cursed","ApprenticeSeer","Diseased","Spellcaster","Lycan","Priest","Prince","PI","Sorcerer",
"Doppleganger","CultLeader","Vampire","LoneWolf","Witch","Oldman","Tanner","WolfCub","Thief",
"Hoodlum","TroubleMaker","FrankensteinsMonster",
# うそつき人狼的职业
"Dictator","SeersMama","Trapper","WolfBoy","King",
# Twitter人狼的职业
"Counselor","Miko","GreedyWolf","FascinatingWolf","SolitudeWolf","ToughWolf","ThreateningWolf",
# 天国系的职业
"ObstructiveMad", # 人狼天国
"WanderingGuard", # 錠前天国
"BadLady", # 苍汁天国、人狼天国
"Bomber","Blasphemy","Ushinotokimairi",  # ねじれ天国
# 其他
"RedHood","Baker",
# アプリ的职业
"PsychoKiller",
# わんないと人狼
"Phantom",
# 月夜の人狼
"DrawGirl","CautiousWolf",
]
# ここには入らない役職
# Light, Neet, MinionSelector,QuantumPlayer, HolyProtected, BloodyMary

# 期間限定役職
((date)->
    month=date.getMonth()
    d=date.getDate()
    if month==11 && d>=24
        # 12/24〜12/31
        exports.jobs.push "SantaClaus"
    if month==6 && d>=26 || month==7 && d<=16
        # 7/26〜8/16
        exports.jobs.push "Pyrotechnist"
)(new Date)
# 人外
exports.nonhumans=["Werewolf","Fox","BigWolf","TinyFox","WolfDiviner","MadWolf","Devil","Vampire","LoneWolf","WolfCub","GreedyWolf","FascinatingWolf","SolitudeWolf","ToughWolf","ThreateningWolf","CautiousWolf"]

# 黒が出る人
exports.blacks=["Werewolf","WolfDiviner","MadWolf","Lycan","LoneWolf","WolfCub","Dog","GreedyWolf","FascinatingWolf","SolitudeWolf","ToughWolf","ThreateningWolf"]

# チームたち
exports.teams=teams=
    Human:["Human","Diviner","Psychic","Guard","Couple","Poisoner","ToughGuy","Noble","Slave","Magician","Fugitive","Merchant","QueenSpectator","MadWolf","Liar","Light","Cursed","ApprenticeSeer","Diseased","Spellcaster","Lycan","Priest","Prince","PI","Cat","Witch","Oldman","OccultMania","Dog","Dictator","SeersMama","Trapper","RedHood","Counselor","Miko","HolyMarked","WanderingGuard","TroubleMaker","FrankensteinsMonster","BloodyMary","King","SantaClaus","Phantom","DrawGirl","Pyrotechnist","Baker"]
    Werewolf:["Werewolf","Madman","BigWolf","Fanatic","Spy","WolfDiviner","Spy2","Sorcerer","LoneWolf","MinionSelector","WolfCub","WhisperingMad","WolfBoy","GreedyWolf","FascinatingWolf","SolitudeWolf","ToughWolf","ThreateningWolf","ObstructiveMad","PsychoKiller","CautiousWolf","Bomber","Ushinotokimairi"]
    Fox:["Fox","TinyFox","Immoral","Blasphemy"]
    Devil:["Devil"]
    Friend:["Cupid","Lover","BadLady"]
    Vampire:["Vampire"]
    Others:["Bat","Stalker","Doppleganger","CultLeader","Copier","Tanner","Thief","Hoodlum","QuantumPlayer"],
    Neet:["Neet"]

# カテゴリ分け(半份黑暗火锅でつかうぞ!)
exports.categories=
    Human:teams.Human
    Werewolf:["Werewolf","BigWolf","WolfDiviner","LoneWolf","WolfCub","GreedyWolf","FascinatingWolf","SolitudeWolf","ToughWolf","ThreateningWolf","CautiousWolf"]
    Fox:["Fox","TinyFox"]
    Madman:["Madman","Fanatic","Spy","Spy2","Sorcerer","WhisperingMad","WolfBoy","ObstructiveMad","PsychoKiller","Bomber","Ushinotokimairi"]
    Immoral:["Immoral","Blasphemy"]
    Switching:["Stalker","OccultMania","Copier","Cursed","Doppleganger","BloodyMary","Phantom"]
    Others:["Devil","Cupid","Bat","CultLeader","Vampire","Tanner","Lover","Hoodlum","BadLady"]

exports.categoryNames=
    Human:"村人系"
    Werewolf:"人狼系"
    Fox:"妖狐系"
    Madman:"狂人系"
    Immoral:"背德者系"
    Switching:"职业变化系"
    Others:"第三阵营系"

# 役職规则たち 役職人数一览を返す（Humanは向こうで補完）
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
    ret.Psychic=1 #灵能
  if number>=6
    ret.Madman=1 #狂人
    ret.Guard=1 #猎人
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
  ret.Diviner=1 #占卜师
  if number>=8
    ret.Psychic=1   #灵能者
  if number>=10
    ret.Madman=1    #狂人
    if number>=28
      ret.Madman++
  if number>=11
    ret.Guard=1 #猎人
  if number>=13
    ret.Couple=2    #共有者
    if number>=28
      ret.Couple++
  if number>=15
    ret.Fox=1   #狐
  ret

exports.jobrules=[
  {
    name:"普通配置"
    rule:[
      {
        name:"普通1"
        title:"较少的人数也能享受游戏的配置。"
        minNumber:4
        rule:normal1
      }
      {
        name:"普通2"
        title:"普通的配置。"
        minNumber:4
        rule:normal2
      }
      {
        name:"普通3"
        title:"较少的人数也会出现妖狐的配置。"
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
    name:"特殊职业配置"
    rule:[
      {
        name:"恋人"
        title:"恋人会出现的配置。"
        rule:(number)->
          ret=normal1 number
          if ret.Fox>0  #NaNかも
            ret.Fox--
          ret.Cupid ?= 0
          ret.Cupid++
          ret
      }
      {
        name:"背德者"
        title:"背德者会出现的配置。"
        rule:(number)->
          ret=normal1 number
          if ret.Fox>0
            ret.Immoral?=0
            ret.Immoral+=1
          ret
      }
      {
        name:"埋毒者"
        title:"埋毒者会出现的配置。"
        rule:(number)->
          ret=normal1 number
          ret.Poisoner=1
          ret.Werewolf++
          ret
      }
      {
        name:"猫又"
        title:"猫又会出现的配置。"
        rule:(number)->
          ret=normal1 number
          ret.Cat=1
          ret.Werewolf++
          ret
      }
      {
        name:"低语狂人"
        title:"低语狂人会代替普通狂人出现的配置。"
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
        name:"蝙蝠"
        title:"蝙蝠会出现的配置。"
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
        name:"贵族奴隶"
        title:"贵族奴隶会出现的配置。"
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
        name:"魔术师"
        title:"魔术师会出现的配置。"
        rule:(number)->
          ret=normal1 number
          ret.Magician=1
          ret
      }
      {
        name:"间谍"
        title:"间谍会出现的配置。"
        rule:(number)->
          ret=normal1 number
          ret.Spy=1
          if number<10 && ret.Madman>0
            ret.Madman--
          ret
      }
      {
        name:"人狼占卜师"
        title:"人狼占卜师会出现的配置。"
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
        title:"商人会出现的配置。"
        rule:(number)->
          ret=normal1 number
          ret.Merchant=1
          ret
      }
    ]
  }
  {
      name:"主题配置"
      rule:[
        {
          name:"变化村"
          title:"有很多能够变换职业的人。"
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
          name:"黑村"
          title:"黑啊，真他妈黑啊。村人几乎看不到生存希望的村子。"
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
          title:"存在女王观战者的村子。推荐人数:14-16人。"
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
    name:"其他"
    rule:[
      {
        name:"疯狂的世界"
        title:"狂人很多。"
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
          # 占卜师
          if number>=12
            ret.Diviner++
            count++
            if number>=20
              ret.Diviner++
              count++
          # 妖术师
          if number>=8
            ret.Sorcerer=1
            count++
            if number>=23
              ret.Sorcerer++
              count++

          # 灵能者
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
        name:"六方混战"
        title:"共有村人、人狼、妖狐、恶魔、恋人、吸血鬼六个势力。"
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
# 规则オブジェクトを得る
exports.getruleobj=(name)->
    # オブジェクトから探す
    if name=="特殊规则.量子人狼"
        # 特殊だ!
        return {
            name:"量子人狼"
            title:"全員的职业などが確率で表現される。只限村人・人狼・占卜师。"
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
# 规则関数を得る
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
# 规则の名字を書く
exports.getrulestr=(rule,jobs={})->
    text=""
    if rule=="特殊规则.黑暗火锅"
        # 黑暗火锅の場合
        return "黑暗火锅"
    if rule=="特殊规则.Endless黑暗火锅"
        return "Endless黑暗火锅"
    text="#{rule.split('.').pop()} / "

    for job in Shared.game.jobs
        continue if job=="Human" && rule=="特殊规则.半份黑暗火锅" #半份黑暗火锅は村人部分だけ黑暗火锅
        num=jobs[job]
        continue unless parseInt num
        text+="#{Shared.game.getjobname job}#{num} "
    # さらにカテゴリ分も
    for type,name of Shared.game.categoryNames
        num=jobs["category_#{type}"]
        if num>0
            text+="#{name}#{num} "
    return text
# 職の名字
exports.getjobname=(job)->
    for name,team of Shared.game.jobinfo
        if team[job]?
            return team[job].name
    return null
exports.jobinfo=
    Human:
        name:"村人阵营"
        color:"#00CC00"
        Human:
            name:"村人"
            color:"#dddddd"
        Diviner:
            name:"占卜师"
            color:"#00b3ff"
        Psychic:
            name:"灵能者"
            color:"#bb00ff"
        Guard:
            name:"猎人"
            color:"#969ad4"
        Couple:
            name:"共有者"
            color:"#ffffab"
        Poisoner:
            name:"埋毒者"
            color:"#853c24"
        Noble:
            name:"贵族"
            color:"#ffff00"
        Slave:
            name:"奴隶"
            color:"#1417d9"
        Magician:
            name:"魔术师"
            color:"#f03eba"
        Fugitive:
            name:"逃亡者"
            color:"#e8b279"
        Merchant:
            name:"商人"
            color:"#e06781"
        QueenSpectator:
            name:"女王观战者"
            color:"#faeebe"
        Liar:
            name:"骗子"
            color:"#a3e4e6"
        Light:
            name:"死亡笔记"
            color:"#2d158c"
        MadWolf:
            name:"狂人狼"
            color:"#847430"
        ToughGuy:
            name:"硬汉"
            color:"#ff5900"
        Cursed:
            name:"被诅咒者"
            color:"#bda3bf"
        ApprenticeSeer:
            name:"见习占卜师"
            color:"#bfecff"
        Diseased:
            name:"病人"
            color:"#b35b98"
        Spellcaster:
            name:"诅咒师"
            color:"#4b4f7d"
        Lycan:
            name:"狼憑き"
            color:"#7d5f5f"
        Priest:
            name:"圣职者"
            color:"#fff94a"
        Prince:
            name:"王子"
            color:"#e5ff00"
        PI:
            name:"超常现象研究者"
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
            name:"怪诞狂热者"
            color:"#edda8c"
        Dog:
            name:"犬"
            color:"#d4a152"
        Dictator:
            name:"独裁者"
            color:"#ff0000"
        SeersMama:
            name:"占卜师的妈妈"
            color:"#ff9500"
        Trapper:
            name:"陷阱师"
            color:"#b58500"
        RedHood:
            name:"小红帽"
            color:"#ff2200"
        Counselor:
            name:"策士"
            color:"#ff94d9"
        Miko:
            name:"巫女"
            color:"#f5b8ca"
        HolyMarked:
            name:"圣痕者"
            color:"#c4e8ff"
        WanderingGuard:
            name:"風来猎人"
            color:"#16bf0d"
        TroubleMaker:
            name:"闹事者"
            color:"#64b82c"
        FrankensteinsMonster:
            name:"弗兰肯斯坦"
            color:"#4d3a03"
        BloodyMary:
            name:"血腥玛丽"
            color:"#ee0000"
        King:
            name:"国王"
            color:"#fcdd28"
        SantaClaus:
            name:"圣诞老人"
            color:"#ff0000"
        Phantom:
            name:"怪盗"
            color:"#f3f3f3"
        DrawGirl:
            name:"看板娘"
            color:"#ffc796"
        Pyrotechnist:
            name:"烟火师"
            color:"#ff6a19"
        Baker:
            name:"面包店"
            color:"#fad587"
        
    Werewolf:
        name:"人狼阵营"
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
            name:"间谍"
            color:"#ad5d28"
        WolfDiviner:
            name:"人狼占卜师"
            color:"#5b0080"
        Spy2:
            name:"间谍Ⅱ"
            color:"#d3b959"
        Fanatic:
            name:"狂信者"
            color:"#94782b"
        Sorcerer:
            name:"妖术师"
            color:"#b91be0"
        LoneWolf:
            name:"一匹狼"
            color:"#222222"
        MinionSelector:
            name:"仆从选择者"
            color:"#ffffff"
        WolfCub:
            name:"狼之子"
            color:"#662233"
        WhisperingMad:
            name:"低语狂人"
            color:"#ccab52"
        WolfBoy:
            name:"狼少年"
            color:"#5b2266"
        GreedyWolf:
            name:"贪婪的狼"
            color:"#910052"
        FascinatingWolf:
            name:"魅惑的女狼"
            color:"#f200c2"
        SolitudeWolf:
            name:"孤独的狼"
            color:"#a13f3f"
        ToughWolf:
            name:"硬汉人狼"
            color:"#c47f35"
        ThreateningWolf:
            name:"威吓的狼"
            color:"#9e6f00"
        ObstructiveMad:
            name:"碍事的狂人"
            color:"#d95e38"
        PsychoKiller:
            name:"变态杀人狂"
            color:"#1ee37d"
        CautiousWolf:
            name:"慎重的狼"
            color:"#5c3716"
        Bomber:
            name:"炸弹魔"
            color:"#cda764"
        Ushinotokimairi:
            name:"丑刻参"
            color:"#c9563c"
        
        
    Fox:
        name:"妖狐阵营"
        color:"#934293"
        Fox:
            name:"妖狐"
            color:"#934293"
        TinyFox:
            name:"小狐"
            color:"#dd81f0"
        Immoral:
            name:"背德者"
            color:"#5c2f5c"
        Blasphemy:
            name:"冒渎者"
            color:"#802060"
            
        
    Devil:
        name:"恶魔"
        color:"#735f9e"
        Devil:
            name:"恶魔"
            color:"#735f9e"
    Friend:
        name:"恋人阵营"
        color:"#ffb5e5"
        Cupid:
            name:"丘比特"
            color:"#ffb5e5"
        Lover:
            name:"求爱者"
            color:"#ffcfee"
        BadLady:
            name:"恶女"
            color:"#cf0085"
    Vampire:
        name:"吸血鬼阵营"
        color:"#8f00bf"
        Vampire:
            name:"吸血鬼"
            color:"#8f00bf"
    Others:
        name:"其他"
        color:"#cccccc"
        Bat:
            name:"蝙蝠"
            color:"#000066"
        Stalker:
            name:"跟踪狂"
            color:"#ad6628"
        Doppleganger:
            name:"二重身"
            color:"#bbbbbb"
        CultLeader:
            name:"邪教主"
            color:"#b09d87"
        Copier:
            name:"模仿者"
            color:"#ffffff"
        Tanner:
            name:"皮革匠"
            color:"#ede4b9"
        Thief:
            name:"小偷"
            color:"#a4a4a4"
        Hoodlum:
            name:"流氓"
            color:"#88002d"
        QuantumPlayer:
            name:"量子人类"
            color:"#eeeeee"
    Neet:
        name:"NEET"
        color:"#aaaaaa"
        Neet:
            name:"NEET"
            color:"#aaaaaa"
# 設定項目
exports.rules=[
    # 黑暗火锅関係
    {
        label:"黑暗火锅选项"
        visible:(rule,jobs)->rule.jobrule in ["特殊规则.黑暗火锅","特殊规则.半份黑暗火锅","特殊规则.Endless黑暗火锅"]
        rules:[
            {
                name:"yaminabe_safety"
                label:"黑暗火锅安全性"
                title:"指定职业分配的谨慎程度"
                type:"select"
                values:[
                    {
                        value:"supersuper"
                        label:"超超（α2）"
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
                        title:"各阵营の割合を調整します。"
                    }
                    {
                        value:"low"
                        label:"低"
                        title:"人狼・妖狐の数をちょうどいい数に調整します。"
                        selected:true
                    }
                    {
                        value:"none"
                        label:"无"
                        title:"まったく気をつけません。人狼系1が保証される以外は全てランダムです。"
                    }
                    {
                        value:"reverse"
                        label:"逆（α）"
                        title:"クソゲーになりますが、人外数の調整は行われます。"
                    }
                ]
            }
            {
                name:"yaminabe_hidejobs"
                label:"配置公开"
                title:"指定配置的公开方式。"
                type:"select"
                values:[
                    {
                        # ""なのは歴史的経緯
                        value:""
                        label:"公开职业一览"
                        title:"配置结束后，公开将会出现的职业。"
                        selected:true
                    }
                    {
                        value:"team"
                        label:"只公开阵营数"
                        title:"智慧公开将有几个阵营出现。"
                    }
                    {
                        value:"1"
                        label:"不公开"
                        title:"不公开将出现的职业一览。"
                    }
                ]
            }
        ]
    }
    # 標準规则
    {
        label:null
        visible:->true
        rules:[
            {
                name:"decider"
                label:"决定者"
                title:"白天的处刑投票有人票数相同时，决定者的投票将有优先决定权。所有人不会知道谁是决定者。"
                type:"checkbox"
                value:{
                    value:"1"
                    label:"有"
                }
            }
            {
                name:"authority"
                label:"权力者"
                title:"白天的处刑投票时，权力者的投票将以两票计。所有人不会知道谁是权力者。"
                type:"checkbox"
                value:{
                    value:"1"
                    label:"有"
                }
            }
            {
                name:"deathnote"
                label:"死亡笔记"
                title:"死亡笔记每晚都会传递给另一个人。持有死亡笔记的人能够杀死一个人。"
                type:"checkbox"
                value:{
                    value:"1"
                    label:"有"
                }
            }
            {
                name:"wolfminion"
                label:"狼的仆从"
                title:"第一天夜里人狼会指定狼的仆从。变成狼的仆从后技能维持不变，但是阵营变为狼人阵营。"
                type:"checkbox"
                value:{
                    value:"1"
                    label:"有"
                }
            }
            {
                name:"drunk"
                label:"酒鬼"
                title:"会有随机一人变成酒鬼。酒鬼在第三天夜里之前会把自己当做村人。"
                type:"checkbox"
                value:{
                    value:"1"
                    label:"有"
                }
            }
            {
                type:"separator"
            }
            {
                name:"scapegoat"
                label:"替身君"
                title:"替身君是在第一天夜里被杀的NPC。"
                type:"select"
                values: [
                    {
                        value:"on"
                        label:"有"
                        selected:true
                    }
                    {
                        value:"off"
                        label:"无（玩家会被杀）"
                    }
                    {
                        value:"no"
                        label:"无（没有人会死）"
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
                label:"犹豫"
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
                label:"遗言"
                title:"遗言有效的时候各个参加者能够设置遗言，遗言将在死亡时公开。"
                type:"checkbox"
                value:{
                    value:"die"
                    label:"有"
                    nolabel:"无"
                    checked:true
                }
            }
            {
                name:"heavenview"
                label:"灵界视野"
                title:"选择有的时候，在灵界可以看到职业的一览表，夜间的发言全部可以看到。"
                type:"select"
                values:[
                    {
                        # ""なのは歴史的経緯
                        value:"view"
                        label:"常开"
                        title:"即使有能复活他人的角色，也开放灵界。"
                    }
                    {
                        value:"norevive"
                        label:"有"
                        title:"仅在所有人都不能复活的时候公开灵界。"
                        selected:true
                    }
                    {
                        value:""
                        label:"无"
                        title:"直到游戏结束都不公开灵界。"
                    }
                ]
            }
            {
                name:"votemyself"
                label:"白天向自己投票"
                type:"checkbox"
                value:{
                    value:"ok"
                    label:"有"
                    nolabel:"无"
                }
                getstr:(value)->
                    {
                        label:"自分投票"
                        value:if value=="ok" then "有" else "无"
                    }
            }
            {
                name:"waitingnight"
                label:"等待直到夜晚结束"
                type:"hidden"
                value:{
                    value:"wait"
                    label:"有"
                    nolabel:"无"
                }
            }
            {
                name:"safety"
                label:"替身安全性"
                title:"「无」和「自由」的时候替身君可以变成人狼。"
                type:"select"
                values:[
                    {
                        value:"full"
                        label:"有"
                        selected:true
                    }
                    {
                        value:"no"
                        label:"无"
                    }
                    {
                        value:"free"
                        label:"自由"
                    }
                ]
            }
            {
                type:"separator"
            }
            {
                name:"noticebitten"
                label:"被咬的时候会知道"
                title:"被人狼袭击的时候会收到通知。"
                type:"checkbox"
                value:{
                    value:"notice"
                    label:"有"
                    nolabel:"无"
                }
                getstr:(value)->
                    {
                        label:"遭受袭击警报"
                        value:if value=="notice" then "有" else "无"
                    }
            }
            {
                name:"GMpsychic"
                label:"GM灵能"
                title:"选中的时候，被处刑人的灵能结果会向所有人公开。"
                type:"checkbox"
                value:{
                    value:"on"
                    label:"有"
                    nolabel:"无"
                }
            }
            {
                name:"silentrule"
                label:"秒规则"
                backlabel:true  # 後ろに
                title:"设为1以上的时候，白天刚开始数秒内全员不能发言。"
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
                            value:"#{value}秒规则"
                        }
            }
            {
                name:"losemode"
                label:"败北村"
                title:"以败北为目的的人狼。"
                type:"checkbox"
                value:{
                    value:"on"
                    label:"有"
                }
            }
            {
                name:"rolerequest"
                label:"希望役职制"
                title:"所有参加者可以选择希望就职的角色。"
                type:"checkbox"
                value:{
                    value:"on"
                    label:"有"
                }
            }
            {
                name:"runoff"
                label:"决胜投票"
                title:"选中的时候，票数最高的人之间将进行决胜投票。"
                type:"select"
                values:[
                    {
                        value:"no"
                        label:"无"
                        selected:true
                    }
                    {
                        value:"revote"
                        label:"重新投票時"
                    }
                    {
                        value:"yes"
                        label:"一直"
                    }
                ]
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
                label:"能够听到人狼的远吠"
                type:"checkbox"
                value:{
                    value:"aloud"
                    label:"有"
                    nolabel:"无"
                    checked:true
                }
                getstr:(value)->
                    {
                        label:"人狼的远吠"
                        value:if value=="aloud" then "能听到" else "听不到"
                    }
            }
            {
                name:"wolfattack"
                label:"人狼之间可以相互袭击"
                type:"checkbox"
                value:{
                    value:"ok"
                    label:"有"
                }
                getstr:(value)->
                    if value=="ok"
                        {
                            label:null
                            value:"人狼之间可以相互袭击"
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
            for job in ["Diviner","WolfDiviner","TinyFox"]
                if jobs[job]>0
                    return true
            return false
        rules:[
            {
                name:"divineresult"
                label:"占卜结果"
                title:"晚上的占卜结果在什么时候发表。"
                type:"select"
                values:[
                    {
                        value:"immediate"
                        label:"立刻知道"
                    }
                    {
                        value:"sunrise"
                        label:"天亮才知道"
                        selected:true
                    }
                ]
            }
        ]
    }
    # 灵能
    {
        label:null
        visible:(rule,jobs)->
            return true if isYaminabe rule
            return jobs.Psychic>0
        rules:[
            {
                name:"psychicresult"
                label:"灵能结果"
                title:"晚上的灵能结果在什么时候发表。"
                type:"select"
                values:[
                    {
                        value:"sunset"
                        label:"立刻知道"
                    }
                    {
                        value:"sunrise"
                        label:"天亮才知道"
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
                label:"能听到共有者的低语声"
                type:"checkbox"
                value:{
                    value:"aloud"
                    label:"有"
                    nolabel:"无"
                }
                getstr:(value)->
                    {
                        label:"共有者的低语声"
                        value:if value=="aloud" then "能听到" else "听不到"
                    }
            }
        ]
    }
    # 护卫役職
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
                label:"猎人可以保护自己"
                type:"checkbox"
                value:{
                    value:"ok"
                    label:"有"
                }
                getstr:(value)->
                    {
                        label:"猎人保护自己"
                        value:if value=="ok" then "有" else "无"
                    }
            }
            {
                name:"gjmessage"
                label:"护卫成功能够知道"
                title:"选中后，在猎人成功保护他人时，猎人会收到通知。"
                type:"checkbox"
                value:{
                    value:"on"
                    label:"有"
                }
                getstr:(value)->
                    {
                        label:"护卫成功通知"
                        value:if value=="on" then "有" else "无"
                    }
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
                label:"区分咒杀和袭击"
                title:"选中后，妖狐被占卜师咒杀和被狼人袭击致死会有不同的通知。"
                type:"checkbox"
                value:
                    value:"obvious"
                    label:"有"
                    nolabel:"无"
                getstr:(value)->
                    {
                        label:"咒杀袭击区別"
                        value:if value=="on" then "有" else "无"
                    }
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
                label:"恋人阵营的胜利条件"
                type:"select"
                values:[
                    {
                        value:"alive"
                        label:"终了时生存"
                        title:"与妖狐相同。"
                        selected:true
                    }
                    {
                        value:"ruin"
                        label:"只有恋人生存"
                    }
                ]
            }
            {
                name:"friendssplit"
                label:"多组恋人相互独立"
                title:"选中后在有复数组恋人的场合下，恋人的胜利条件从只有恋人阵营生存，变为只有本组恋人生存。"
                type:"checkbox"
                value:{
                    value:"split"
                    label:"有"
                    checked:true
                }
                getstr:(value)->
                    {
                        label:"恋人的独立"
                        value:if value=="split" then "有" else "无"
                    }
            }
        ]
    }
    # 量子人狼
    {
        label:null
        visible:(rule,jobs)->rule.jobrule=="特殊规则.量子人狼"
        rules:[
            {
                name:"quantumwerewolf_table"
                label:"概率表"
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
                title:"概率表に死亡率を表示しない规则です。表示するのが普通です。"
                type:"checkbox"
                value:{
                    value:"no"
                    label:"有"
                    nolabel:"无"
                }
            }
            {
                name:"quantumwerewolf_diviner"
                label:"占卜师の確率も表示する"
                title:"概率表に占卜师の確率も表示します。表示しないのが普通の规则です。"
                type:"checkbox"
                value:{
                    value:"on"
                    label:"有"
                    nolabel:"无"
                }
            }
            {
                name:"quantumwerewolf_firstattack"
                label:"初日の襲撃"
                title:"有の場合初日から襲撃対象を選択します。"
                type:"checkbox"
                value:{
                    value:"on"
                    label:"有"
                    nolabel:"无"
                }
            }
        ]
    }
]
# 情報表示(makejobinfoで付加するやつ)
exports.jobinfos=[
    {
        name:"wolves"
        prefix:"同伴的人狼是"
        type:"pubinfo-array"
    }
    {
        name:"peers"
        prefix:"共有者是"
        type:"pubinfo-array"
    }
    {
        name:"foxes"
        prefix:"同伴的妖狐是"
        type:"pubinfo-array"
    }
    {
        name:"nobles"
        prefix:"贵族是"
        type:"pubinfo-array"
    }
    {
        name:"queens"
        prefix:"女王观战者是"
        type:"pubinfo-array"
    }
    {
        name:"spy2s"
        prefix:"间谍Ⅱ是"
        type:"pubinfo-array"
    }
    {
        name:"friends"
        prefix:"恋人是"
        type:"pubinfo-array"
    }
    {
        name:"stalking"
        prefix:"你是"
        suffix:"的跟踪狂"
        type:"pubinfo"
    }
    {
        name:"cultmembers"
        prefix:"信者是"
        type:"pubinfo-array"
    }
    {
        name:"supporting"
        prefix:"向"
        suffix:"提供帮助"
        type:"pubinfo+job-array"
    }
    {
        name:"dogOwner"
        prefix:"你的饲主是"
        type:"pubinfo"
    }
    {
        name:"quantumwerewolf_number"
        prefix:"你的玩家编号是第"
        suffix:"号"
        type:"raw"
    }
    {
        name:"watchingfireworks",
        type:"hidden"
    }
]

# 判定
isYaminabe=(rule)->rule.jobrule in ["特殊规则.黑暗火锅","特殊规则.半份黑暗火锅"]
