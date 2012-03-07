# ------ 役職一覧
# 基本役職
exports.jobs=["Human","Werewolf","Diviner","Psychic","Madman","Guard","Couple","Fox",
# 特殊役職?
"Poisoner","BigWolf","TinyFox","Cat",
# 特殊役職2
"Devil","ToughGuy","Cupid","Stalker","OccultMania",
# るる鯖で見つけた役職
"Fanatic","Immoral"
# 桃栗基本特殊役職
"Bat","Noble","Slave","Magician","Spy","WolfDiviner",
# 桃栗期間限定役職
"Fugitive","Merchant","QueenSpectator","MadWolf","Liar","Spy2","Copier",
# 究極の人狼の役職
"Cursed","ApprenticeSeer","Diseased","Spellcaster","Lycan","Priest","Prince","PI","Sorcerer",
"Doppleganger","CultLeader","Vampire","LoneWolf","Witch","Oldman","Tanner",
]
# ここには入らない役職
# Light, Neet

# 人外
exports.nonhumans=["Werewolf","Fox","BigWolf","TinyFox","WolfDiviner","MadWolf","Devil","Vampire","LoneWolf"]

# 黒が出る人
exports.blacks=["Werewolf","WolfDiviner","MadWolf","Lycan","LoneWolf"]

# チームたち
exports.teams=
	Human:["Human","Diviner","Psychic","Guard","Couple","Poisoner","ToughGuy","Noble","Slave","Magician","Fugitive","Merchant","QueenSpectator","MadWolf","Liar","Copier","Light","Cursed","ApprenticeSeer","Diseased","Spellcaster","Lycan","Priest","Prince","PI","Cat","Witch","Oldman","OccultMania"]
	Werewolf:["Werewolf","Madman","BigWolf","Fanatic","Spy","WolfDiviner","Spy2","Sorcerer","LoneWolf"]
	Fox:["Fox","TinyFox","Immoral"]
	Bat:["Bat"]
	Devil:["Devil"]
	Friend:["Cupid"]
	Others:["Stalker","Doppleganger","CultLeader","Vampire","Tanner"],
	Neet:["Neet"]

# 役職ルールたち 役職人数一覧を返す（Humanは向こうで補完）
normal1=(number)->
  ret={}
  #狼
  ret.Werewolf=1
  if number>=8
    ret.Werewolf++
    if number>=13
      ret.Werewolf++
      if number>=18
        ret.Werewolf++
        if number>=22
          ret.Werewolf++
          if number>=27
            ret.Werewolf++
  ret.Diviner=1	#占い
  if number>4
    ret.Psychic=1 #霊能
  if number>=6
    ret.Madman=1 #狂人
    ret.Guard=1 #狩人
    if number>=18
      ret.Madman++
    if number>=19
      ret.Guard++
  if number>=13
    ret.Couple=2 #共有
    if number>=20
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
  ret.Diviner=1	#占い師
  if number>4
    ret.Psychic=1	#霊能者
  if number>=10
    ret.Madman=1	#狂人
    if number>=28
      ret.Madman++
  if number>=11
    ret.Guard=1	#狩人
  if number>=13
    ret.Couple=2	#共有者
    if number>=28
      ret.Couple++
  if number>=15
    ret.Fox=1	#狐
  ret

exports.jobrules=[
  {
    name:"普通配役"
    rule:[
      {
        name:"普通1"
        title:"少人数でも楽しめる配役。"
        rule:normal1
      }
      {
        name:"普通2"
        title:"一般的な配役。"
        rule:normal2
      }
      {
        name:"普通3"
        title:"少人数でも狐が出る配役。"
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
          if ret.Fox>0	#NaNかも
            ret.Fox--
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
        name:"猫又あり"
        title:"猫又が出る配役。"
        rule:(number)->
          ret=normal1 number
          ret.Cat=1
          ret.Werewolf++
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
          if number>=9
            ret.Werewolf++
            count++
            if number>=15
              ret.Werewolf++
              count++
          if number>=10
            ret.Psychic++
            count++
          if number>=12
            ret.Fox++
            count++
          ret.Madman=number-count	#残り全部狂人
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
# ルール関数を得る
exports.getrulefunc=(name)->
	names= name.split "."
	obj=SS.shared.game.jobrules
	for branch in names	#.区切りでオブジェクト名
		obj=obj.filter((x)->x.name==branch)[0]?.rule
		unless obj	# そんな配役は見つからない
			return
	unless typeof obj =="function"
		#配列でない
		return
	obj
# ルールの名前を書く
exports.getrulestr=(rule,jobs={})->
	text=""
	if rule=="特殊ルール.闇鍋"
		# 闇鍋の場合
		return "闇鍋 / 人狼#{jobs.Werewolf} 妖狐#{jobs.Fox}"
	if rule=="特殊ルール.一部闇鍋"
		text="一部闇鍋 / "
	else
		text="#{rule.split('.').pop()} / "

	for job in SS.shared.game.jobs
		continue if job=="Human" && rule=="特殊ルール.一部闇鍋"	#一部闇鍋は村人部分だけ闇鍋
		num=jobs[job]
		continue unless parseInt num
		text+="#{SS.shared.game.getjobname job}#{num} "
	return text
# 職の名前
exports.getjobname=(job)->
	for name,team of SS.shared.game.jobinfo
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
		Copier:
			name:"コピー"
			color:"#ffffff"
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
			
		
	Bat:
		name:"こうもり"
		color:"#000066"
		Bat:
			name:"こうもり"
			color:"#000066"
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
	Others:
		name:"その他"
		color:"#cccccc"
		Stalker:
			name:"ストーカー"
			color:"#ad6628"
		Doppleganger:
			name:"ドッペルゲンガー"
			color:"#bbbbbb"
		CultLeader:
			name:"カルトリーダー"
			color:"#b09d87"
		Vampire:
			name:"ヴァンパイア"
			color:"#8f00bf"
		Tanner:
			name:"皮なめし職人"
			color:"#ede4b9"
		
	Neet:
		name:"ニート"
		color:"#aaaaaa"
		Neet:
			name:"ニート"
			color:"#aaaaaa"
